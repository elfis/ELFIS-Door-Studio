# encoding: UTF-8
require 'json'

module ElfisDrillingHighlight
  TAG_ID = 'elfis.tag_highlight' unless const_defined?(:TAG_ID)

  # Match the tag on an entity or one of its enclosing instances. This includes
  # raw Untagged geometry belonging to a tagged cabinet/panel, per occurrence.
  def tag_segments(model, tag_ids)
    ids = tag_ids.map(&:to_i)
    return {points: [], circles: 0} if ids.empty?
    points = []; parts = 0
    walk = lambda do |entities, transform, path, inherited, stack|
      entities.grep(Sketchup::Edge).each do |edge|
        next unless inherited || ids.include?(edge.layer.persistent_id) || edge.faces.any? { |face| ids.include?(face.layer.persistent_id) }
        next unless model.drawing_element_visible?(path + [edge])
        next if edge.soft? && edge.smooth?
        points << edge.start.position.transform(transform)
        points << edge.end.position.transform(transform)
      end
      entities.each do |entity|
        next unless instance?(entity) && entity.valid? && !stack.include?(entity.definition)
        child_path = path + [entity]
        next unless model.drawing_element_visible?(child_path)
        matched = ids.include?(entity.layer.persistent_id)
        parts += 1 if matched && !inherited
        walk.call(entity.definition.entities, transform * entity.transformation,
                  child_path, inherited || matched, stack + [entity.definition])
      end
    end
    walk.call(model.entities, Geom::Transformation.new, [], false, [])
    {points: points, circles: parts}
  end

  class TagHighlight < Highlight
    attr_accessor :tag_ids
    def initialize
      super(TAG_ID, 'Selected tags', 'Temporary outlines for tags selected in the ELFIS tag list')
      @tag_ids = []
    end
    def bind(model)
      unbind if @model && @model != model
      @model = model
      unless @motion_watcher
        @motion_watcher = MotionWatcher.new(self)
        model.tools.add_observer(@motion_watcher)
      end
      unless @material_watcher
        @material_watcher = MaterialWatcher.new(self)
        model.add_observer(@material_watcher)
      end
      @moving = motion_tool?(model.tools.active_tool_name, model.tools.active_tool_id)
    end
    def collect_segments(roots, base); ElfisDrillingHighlight.tag_segments(@model, @tag_ids); end
    def update_icon(active); end
    def highlight_color; Sketchup::Color.new(245, 175, 25); end
  end

  def tag_overlay(model = Sketchup.active_model)
    model.overlays.find { |item| item.overlay_id == TAG_ID }
  end

  def clear_tag_highlight(model = @tag_model)
    item = model && tag_overlay(model)
    if item
      item.tag_ids = []
      item.enabled = false if item.enabled?
      item.unbind
      item.points = []
      model.active_view.invalidate
    end
  end

  def set_highlight_tags(ids, model = Sketchup.active_model)
    available = model.layers.map(&:persistent_id)
    ids = ids.map(&:to_i).uniq & available
    if ids.empty?
      clear_tag_highlight(model)
      return {tags: 0, parts: 0, lines: 0}
    end
    item = tag_overlay(model)
    unless item
      item = TagHighlight.new
      model.overlays.add(item)
    end
    item.tag_ids = ids
    item.bind(model)
    item.enabled = true
    item.refresh
    {tags: ids.length, parts: item.circles, lines: item.points.length / 2}
  end

  def tag_list_data(model)
    selected = tag_overlay(model)&.tag_ids || []
    model.layers.map do |tag|
      folders = []; folder = tag.folder
      while folder
        folders.unshift(folder.name)
        folder = folder.folder
      end
      {id: tag.persistent_id, name: tag.display_name, folder: folders.join(' / '),
       visible: tag.visible?, selected: selected.include?(tag.persistent_id)}
    end.sort_by { |row| [row[:folder].downcase, row[:name].downcase] }
  end

  def send_tag_list
    model = Sketchup.active_model
    if @tag_model && @tag_model != model
      clear_tag_highlight(@tag_model)
    end
    @tag_model = model
    @tag_dialog.execute_script("window.setTags(#{JSON.generate(tag_list_data(model))})")
  end

  def show_tag_list
    if @tag_dialog && @tag_dialog.visible?
      send_tag_list
      @tag_dialog.bring_to_front
      return
    end
    @tag_model = Sketchup.active_model
    dialog = UI::HtmlDialog.new(dialog_title: 'ELFIS — Podświetlanie tagów',
      preferences_key: 'ElfisTagHighlightWindow', width: 420, height: 560,
      min_width: 320, min_height: 350, resizable: true, style: UI::HtmlDialog::STYLE_DIALOG)
    @tag_dialog = dialog
    dialog.add_action_callback('ready') { send_tag_list }
    dialog.add_action_callback('refresh') do
      send_tag_list
      item = tag_overlay
      item.request_refresh if item
    end
    dialog.add_action_callback('highlight') do |_context, encoded|
      if @tag_model != Sketchup.active_model
        send_tag_list
        next
      end
      ids = JSON.parse(encoded.to_s)
      next unless ids.is_a?(Array)
      result = set_highlight_tags(ids, @tag_model)
      dialog.execute_script("window.setStatus(#{JSON.generate(result)})")
    end
    dialog.set_on_closed do
      clear_tag_highlight
      @tag_dialog = nil
    end
    dialog.set_file(File.join(__dir__, 'tag_highlight.html'))
    dialog.show
  end

  unless @tag_command
    @tag_command = UI::Command.new('Tag highlight list') { show_tag_list }
    @tag_command.tooltip = 'Podświetlanie elementów według tagów'
    @tag_command.status_bar_text = 'Open the ELFIS tag list. Closing it clears temporary highlights.'
    @tag_command.small_icon = @tag_command.large_icon = File.join(__dir__, 'tag_highlight.svg')
    ElfisMenu.category('Display & visibility').add_item(@tag_command)
  end
  unless @tag_toolbar_added
    @toolbar.add_item(@tag_command)
    @tag_toolbar_added = true
  end
end
