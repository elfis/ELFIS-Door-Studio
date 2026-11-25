# encoding: UTF-8
# Load in SketchUp's Ruby Console:
# load File.join(Sketchup.find_support_file('Plugins'), 'elfis_drilling_highlight.rb')
# Extensions > Drilling highlight ON/OFF follows the current selection until OFF.
# Recognizes complete, loose drilling circles tagged D<number>_DEPTH_<number>.
require 'sketchup.rb'
require_relative 'elfis_menu'

module ElfisDrillingHighlight
  extend self
  ID = 'elfis.selected_drilling_highlight' unless const_defined?(:ID)
  TAG = /\AD[\d.]+_DEPTH_?[\d.]+\z/i unless const_defined?(:TAG)
  remove_const(:VERSION) if const_defined?(:VERSION, false)
  VERSION = '1.3.1'
  EDGE_ID = 'elfis.selected_edge_highlight' unless const_defined?(:EDGE_ID)

  def instance?(entity)
    entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
  end

  # Convert geometry from the current edit context to model coordinates.
  # Composing the complete active path keeps nested cabinet vectors aligned.
  def active_context_transform(model)
    Array(model.active_path).inject(Geom::Transformation.new) do |transform, instance|
      transform * instance.transformation
    end
  end

  # Keep instance transformations separate: shared copies outside the selection
  # are never highlighted. No make_unique or model changes are required.
  def segments(roots, base = Geom::Transformation.new)
    points = []
    circles = 0
    walk = lambda do |entities, transform, names, stack|
      entities.grep(Sketchup::Edge).map(&:curve).compact.uniq.each do |curve|
        next unless curve.is_a?(Sketchup::ArcCurve)
        next unless (curve.end_angle - curve.start_angle - 2 * Math::PI).abs < 0.0001
        next unless curve.edges.all? { |edge| edge.faces.empty? }
        next unless (names + curve.edges.map { |edge| edge.layer.name }).any? { |name| TAG.match?(name.to_s) }
        circles += 1
        curve.edges.each do |edge|
          points << edge.start.position.transform(transform)
          points << edge.end.position.transform(transform)
        end
      end
      entities.each do |entity|
        next unless instance?(entity)
        next if stack.include?(entity.definition)
        walk.call(entity.definition.entities, transform * entity.transformation,
                  names + [entity.name, entity.layer.name, entity.definition.name],
                  stack + [entity.definition])
      end
    end
    roots.each do |root|
      next unless instance?(root) && root.valid?
      walk.call(root.definition.entities, base * root.transformation,
                [root.name, root.layer.name, root.definition.name], [root.definition])
    end
    { points: points, circles: circles }
  end

  # OCL 7 and 8 use the same public model data: front-face material,
  # ladb_opencutlist/type == 4. Never infer banding from a material name.
  def edge_segments(roots, base = Geom::Transformation.new)
    points = []; faces = 0; material_types = {}
    model = Sketchup.active_model
    walk = lambda do |entities, transform, path, stack|
      banded = entities.grep(Sketchup::Face).select do |face|
        material = face.material
        next false unless material
        type = material_types.fetch(material) do
          material_types[material] = material.get_attribute('ladb_opencutlist', 'type', 0).to_i
        end
        type == 4 && model.drawing_element_visible?(path + [face])
      end
      faces += banded.length
      # Shared boundaries appear once; do not draw soft triangulation seams.
      banded.flat_map(&:edges).uniq.each do |edge|
        next if edge.soft? && edge.faces.length == 2 && edge.faces.all? { |face| banded.include?(face) }
        points << edge.start.position.transform(transform)
        points << edge.end.position.transform(transform)
      end
      entities.each do |entity|
        next unless instance?(entity) && !stack.include?(entity.definition)
        next unless model.drawing_element_visible?(path + [entity])
        walk.call(entity.definition.entities, transform * entity.transformation,
                  path + [entity], stack + [entity.definition])
      end
    end
    roots.each do |root|
      next unless instance?(root) && root.valid?
      path = Array(model.active_path) + [root]
      next unless model.drawing_element_visible?(path)
      walk.call(root.definition.entities, base * root.transformation, path, [root.definition])
    end
    { points: points, circles: faces }
  end

  class MaterialWatcher < Sketchup::ModelObserver
    def initialize(highlight); @highlight = highlight; end
    def onTransactionCommit(model); @highlight.request_refresh; end
    def onTransactionUndo(model); @highlight.request_refresh; end
    def onTransactionRedo(model); @highlight.request_refresh; end
    def onActivePathChanged(model); @highlight.request_refresh; end
  end

  class SelectionWatcher < Sketchup::SelectionObserver
    def initialize(highlight)
      @highlight = highlight
    end

    def onSelectionBulkChange(selection)
      @highlight.request_refresh
    end

    def onSelectionCleared(selection)
      @highlight.request_refresh
    end

    def onSelectionAdded(selection, entity)
      @highlight.request_refresh
    end

    def onSelectionRemoved(selection, entity)
      @highlight.request_refresh
    end
    alias_method :onSelectedRemoved, :onSelectionRemoved
  end

  class MotionWatcher < Sketchup::ToolsObserver
    def initialize(highlight); @highlight = highlight; end
    def onActiveToolChanged(tools, name, id)
      @highlight.tool_changed(name, id)
    end
  end

  class Highlight < Sketchup::Overlay
    attr_accessor :points
    attr_reader :circles

    def initialize(id = ID, label = 'Selected drilling', description = 'Automatically highlights drilling in the current selection while ON')
      super(id, label, description: description)
      @points = []
      @circles = 0
    end

    def bind(model)
      unbind if @model && @model != model
      @model = model
      unless @watcher
        @watcher = SelectionWatcher.new(self)
        model.selection.add_observer(@watcher)
      end
      unless @motion_watcher
        @motion_watcher = MotionWatcher.new(self)
        model.tools.add_observer(@motion_watcher)
      end
      @moving = motion_tool?(model.tools.active_tool_name, model.tools.active_tool_id)
    end

    def unbind
      @model.selection.remove_observer(@watcher) if @model && @watcher
      @model.tools.remove_observer(@motion_watcher) if @model && @motion_watcher
      @model.remove_observer(@material_watcher) if @model && @material_watcher
      @material_watcher = nil
      @watcher = @motion_watcher = nil
    end

    def motion_tool?(name, id = nil)
      id == 21048 || name == 'MoveTool'
    end

    def hide_for_motion
      return if @moving
      @moving = true
      @points = []; @circles = 0
      update_icon(false)
      @model.active_view.invalidate if @model
    end

    def tool_changed(name, id)
      return unless enabled?
      if motion_tool?(name, id)
        hide_for_motion
      elsif @moving
        @moving = false
        request_refresh
      end
    end

    def request_refresh
      return unless @model && enabled? && !@moving
      refresh
    end

    def refresh
      return unless @model && !@moving
      result = if enabled?
        roots = @model.selection.select { |entity| ElfisDrillingHighlight.instance?(entity) }
        collect_segments(roots, ElfisDrillingHighlight.active_context_transform(@model))
      else
        { points: [], circles: 0 }
      end
      @points = result[:points]
      @circles = result[:circles]
      update_icon(enabled? && !@moving)
      @model.active_view.invalidate
    end

    def start
      bind(@model) if @model
      @moving = @model && motion_tool?(@model.tools.active_tool_name)
      update_icon(false) if @moving
      refresh
    end

    def stop
      unbind
      @moving = false
      @points = []
      @circles = 0
      update_icon(false)
      @model.active_view.invalidate if @model
    end

    def draw(view)
      return if @moving
      return if @points.empty?
      view.drawing_color = highlight_color
      view.line_width = 3
      view.line_stipple = ''
      # Screen-space drawing makes drilling visible through panel faces.
      # Cached points are in world coordinates, including the current edit path.
      view.draw2d(GL_LINES, @points.map { |point| view.screen_coords(point) })
    end

    def collect_segments(roots, base); ElfisDrillingHighlight.segments(roots, base); end
    def update_icon(active); ElfisDrillingHighlight.set_icon(active); end
    def highlight_color; Sketchup::Color.new(255, 40, 0); end
  end

  class EdgeHighlight < Highlight
    def initialize
      super(EDGE_ID, 'Selected edge banding', 'OpenCutList edge-band materials on selected parts')
    end
    def bind(model)
      super
      unless @material_watcher
        @material_watcher = MaterialWatcher.new(self)
        model.add_observer(@material_watcher)
      end
    end
    def collect_segments(roots, base); ElfisDrillingHighlight.edge_segments(roots, base); end
    def update_icon(active); ElfisDrillingHighlight.set_edge_icon(active); end
    def highlight_color; Sketchup::Color.new(102, 142, 238); end
  end

  def edge_overlay(model = Sketchup.active_model)
    model.overlays.find { |item| item.overlay_id == EDGE_ID }
  end

  def set_edge_icon(active)
    return unless @edge_command
    path = File.join(__dir__, active ? 'elfis_edge_highlight.svg' : 'elfis_edge_highlight_inactive.svg')
    return if @edge_icon_path == path
    @edge_command.small_icon = @edge_command.large_icon = path
    @edge_icon_path = path
  end

  def toggle_edges
    model = Sketchup.active_model
    item = edge_overlay(model)
    if item && item.enabled?
      item.enabled = false
      item.unbind
      set_edge_icon(false)
      return { enabled: false, faces: 0 }
    end
    unless item
      item = EdgeHighlight.new
      model.overlays.add(item)
    end
    item.bind(model)
    item.enabled = true
    item.tool_changed(model.tools.active_tool_name, model.tools.active_tool_id)
    item.refresh
    { enabled: true, faces: item.circles }
  end

  def overlay(model)
    model.overlays.find { |item| item.overlay_id == ID }
  end

  def set_icon(active)
    return unless @command
    file = active ? 'elfis_drilling_highlight.svg' : 'elfis_drilling_highlight_inactive.svg'
    path = File.join(__dir__, file)
    return if @icon_path == path
    @command.small_icon = path
    @command.large_icon = path
    @icon_path = path
  end

  def sync_icon(item = overlay(Sketchup.active_model))
    set_icon(item && item.enabled? && !item.instance_variable_get(:@moving))
  end

  def toggle(notify: true)
    model = Sketchup.active_model
    item = overlay(model)
    if item && item.enabled?
      item.enabled = false
      item.unbind
      set_icon(false)
      return { enabled: false, circles: 0 }
    end
    unless item
      item = Highlight.new
      model.overlays.add(item)
    end
    item.bind(model)
    item.enabled = true
    item.tool_changed(model.tools.active_tool_name, model.tools.active_tool_id)
    item.refresh
    sync_icon(item)
    { enabled: true, circles: item.circles }
  end

  unless @command
    @command = UI::Command.new('Drilling highlight ON/OFF') { toggle }
    @command.tooltip = 'Highlight drilling in selected groups/components'
    @command.set_validation_proc do
      item = overlay(Sketchup.active_model)
      item && item.enabled? ? MF_CHECKED : MF_UNCHECKED
    end
    ElfisMenu.category('Display & visibility').add_item(@command)
  end

  sync_icon
  @command.status_bar_text = 'Toggle selection-following drilling highlights. Empty selection shows no highlights.'
  unless @toolbar
    @toolbar = UI::Toolbar.new('ELFIS Drilling Highlight')
    @toolbar.add_item(@command)
    if @toolbar.get_last_state == TB_NEVER_SHOWN
      @toolbar.show
    else
      @toolbar.restore
    end
  end

  unless @edge_command
    @edge_command = UI::Command.new('Edge banding highlight ON/OFF') { toggle_edges }
    @edge_command.tooltip = 'Highlight OpenCutList edge banding in selected groups/components'
    @edge_command.status_bar_text = 'Blue: OpenCutList edge-band materials. Follows selection; independent of drilling.'
    @edge_command.set_validation_proc do
      item = edge_overlay
      item && item.enabled? ? MF_CHECKED : MF_UNCHECKED
    end
    ElfisMenu.category('Display & visibility').add_item(@edge_command)
  end
  unless @edge_toolbar_added
    @toolbar.add_item(@edge_command)
    @edge_toolbar_added = true
  end
  edge_item = edge_overlay
  if edge_item
    edge_item.bind(Sketchup.active_model)
    edge_item.refresh
  end
  set_edge_icon(edge_item && edge_item.enabled? && !edge_item.instance_variable_get(:@moving))

  # Upgrade the already loaded overlay when this standalone script is reloaded.
  existing = overlay(Sketchup.active_model)
  if existing
    existing.description = 'Automatically highlights drilling in the current selection while ON'
    existing.bind(Sketchup.active_model)
    existing.refresh
  end
  sync_icon(existing)
end

load File.join(__dir__, 'elfis_drilling_highlight', 'tag_highlight.rb')
