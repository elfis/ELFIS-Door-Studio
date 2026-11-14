# ELFIS Tag Toggle Toolbar for SketchUp
# Save this file as: elfis_tag_toolbar.rb
#
# Each button toggles one or more SketchUp tags.

module ELFIS_TagToolbar

  remove_const(:VERSION) if const_defined?(:VERSION,false)
  VERSION = "1.05"

  BUTTONS = [
    {
      id: :room,
      label: "Room",
      tags: ["Windows", "Walls", "Skirting Boards", "Room Doors", "Floor Plan", "Floor", "Ceiling"]
    },
    { id: :facade, label: "Facade", tags: ["Facade"] },
    { id: :body, label: "Body", tags: ["Body"] },
    { id: :back_wall, label: "Back Wall", tags: ["Back Wall"] },
    { id: :worktops, label: "Worktops", tags: ["Worktops"] },
    {
      id: :finishing,
      label: "Finishing Parts",
      tags: [
        "End Panels", "Plinths", "Fillers", "Decorative Panels",
        "Cover Panels", "Cornices", "Light Pelmets"
      ]
    },
    { id: :handles, label: "Handles", tags: ["Handles"] },
    {
      id: :hardware,
      label: "Hardware",
      tags: ["Hardware", "Blum Hardware", "Extra Blum Hardware"]
    },
    { id: :appliances, label: "Appliances", tags: ["Appliances"] },
    {
      id: :operations,
      label: "Blum Operations",
      tags: ["Blum Operations", "Blum Operations (unbound)"]
    },
    { id: :dimensions, label: "Dimensions", tags: ["Dimensions"] }
  ]

  TAG_FOLDERS = {
    "00 Room" => ["Walls", "Ceiling", "Floor", "Windows", "Room Doors", "Skirting Boards"],
    "01 Cabinet Parts" => ["Facade", "Body", "Back Wall", "Worktops"],
    "02 Finishing Parts" => [
      "End Panels", "Plinths", "Fillers", "Decorative Panels",
      "Cover Panels", "Cornices", "Light Pelmets"
    ],
    "03 Hardware" => ["Handles", "Hardware", "Blum Hardware", "Extra Blum Hardware"],
    "04 Appliances" => ["Appliances"],
    "05 Machining" => ["Blum Operations", "Blum Operations (unbound)"],
    "06 Documentation" => ["Dimensions"]
  }

  LEGACY_FOLDER_NAMES = {
    "03 Hardware" => "02 Hardware",
    "04 Appliances" => "03 Appliances",
    "05 Machining" => "04 Machining",
    "06 Documentation" => "05 Documentation"
  }

  @toolbar ||= nil
  @commands ||= {}
  @app_observer ||= nil
  @layers_observers ||= {}

  def self.ensure_tags(model = Sketchup.active_model)
    return unless model

    layers = model.layers

    TAG_FOLDERS.each do |folder_name, tag_names|
      folder = layers.folders.find { |item| item.name == folder_name }
      unless folder
        legacy_name = LEGACY_FOLDER_NAMES[folder_name]
        folder = layers.folders.find { |item| item.name == legacy_name } if legacy_name
        folder.name = folder_name if folder
      end
      folder ||= layers.add_folder(folder_name)

      tag_names.each do |tag_name|
        tag = layers[tag_name] || layers.add(tag_name)
        folder.add_layer(tag) unless tag.folder == folder
      end
    end

    machining_folder = layers.folders.find { |item| item.name == "05 Machining" }
    layers.each do |tag|
      next unless drilling_tag?(tag.name)

      machining_folder.add_layer(tag) unless tag.folder == machining_folder
    end

    attach_layers_observer(model)
  end

  def self.drilling_tag?(tag_name)
    tag_name.match?(/\AD\d+(?:[._]\d+)?_DEPTH\d+(?:[._]\d+)?\z/i)
  end

  def self.organize_new_tag(layers, tag)
    return unless tag.valid?
    return unless drilling_tag?(tag.name)

    folder = layers.folders.find { |item| item.name == "05 Machining" }
    folder ||= layers.add_folder("05 Machining")
    folder.add_layer(tag) unless tag.folder == folder
  end

  def self.attach_layers_observer(model)
    key = model.object_id
    return if @layers_observers[key]

    observer = LayersObserver.new
    model.layers.add_observer(observer)
    @layers_observers[key] = observer
  end

  class LayersObserver < Sketchup::LayersObserver
    def onLayerAdded(layers, layer)
      ELFIS_TagToolbar.organize_new_tag(layers, layer)
    end
  end

  class AppObserver < Sketchup::AppObserver
    def onNewModel(model)
      ELFIS_TagToolbar.ensure_tags(model)
      ELFIS_TagToolbar.refresh
    end

    def onOpenModel(model)
      ELFIS_TagToolbar.ensure_tags(model)
      ELFIS_TagToolbar.refresh
    end
  end

  def self.icon_folder
    folder = File.join(Sketchup.temp_dir, "ELFIS_TagToolbar")
    Dir.mkdir(folder) unless Dir.exist?(folder)
    folder
  end

  def self.icon_markup(icon_id)
    blue = "#075d99"
    red = "#43bde3"
    grey = "#174562"

    case icon_id
    when :room
      <<~SVG
        <path d="M10 17 L32 8 L54 17 V50 H10 Z" fill="none" stroke="#{blue}" stroke-width="3" stroke-linejoin="round"/>
        <path d="M17 23 H47 V48 H17 Z" fill="none" stroke="#{red}" stroke-width="2.5"/>
        <path d="M27 48 V32 H38 V48" fill="none" stroke="#{grey}" stroke-width="3" stroke-linejoin="round"/>
        <circle cx="35" cy="40" r="1.8" fill="#{red}"/>
      SVG
    when :facade
      <<~SVG
        <rect x="16" y="8" width="32" height="48" rx="2" fill="none" stroke="#{blue}" stroke-width="3"/>
        <rect x="21" y="13" width="22" height="38" rx="1" fill="none" stroke="#{red}" stroke-width="2"/>
        <rect x="38" y="26" width="3.5" height="13" rx="1.75" fill="#{grey}"/>
        <circle cx="39.75" cy="25" r="1.5" fill="#{blue}"/>
        <circle cx="39.75" cy="40" r="1.5" fill="#{blue}"/>
      SVG
    when :body
      <<~SVG
        <path d="M14 20 L31 11 L50 19 L50 45 L31 54 L14 45 Z" fill="none" stroke="#{blue}" stroke-width="3"/>
        <path d="M31 11 V38 M14 20 L31 28 L50 19 M31 38 L50 45" fill="none" stroke="#{blue}" stroke-width="2"/>
        <line x1="18" y1="23" x2="18" y2="42" stroke="#{red}" stroke-width="4" stroke-linecap="round"/>
        <circle cx="31" cy="38" r="2.5" fill="#{grey}"/>
      SVG
    when :back_wall
      <<~SVG
        <rect x="15" y="10" width="34" height="44" rx="2" fill="none" stroke="#{blue}" stroke-width="3"/>
        <path d="M19 49 L45 15 M19 15 L45 49" fill="none" stroke="#{blue}" stroke-width="2"/>
        <line x1="17" y1="12" x2="47" y2="12" stroke="#{red}" stroke-width="4" stroke-linecap="round"/>
        <circle cx="32" cy="32" r="2.5" fill="#{grey}"/>
      SVG
    when :worktops
      <<~SVG
        <path d="M9 23 L50 17 L56 24 L15 31 Z" fill="none" stroke="#{blue}" stroke-width="3" stroke-linejoin="round"/>
        <path d="M15 31 V39 M50 26 V34" fill="none" stroke="#{blue}" stroke-width="3"/>
        <line x1="10" y1="23" x2="15" y2="31" stroke="#{red}" stroke-width="4" stroke-linecap="round"/>
        <circle cx="50" cy="17" r="2.5" fill="#{grey}"/>
      SVG
    when :finishing
      <<~SVG
        <rect x="12" y="17" width="27" height="38" rx="2" fill="none" stroke="#{grey}" stroke-width="3"/>
        <rect x="20" y="11" width="27" height="38" rx="2" fill="none" stroke="#{blue}" stroke-width="3"/>
        <path d="M27 18 H40 V42 H27 Z" fill="none" stroke="#{red}" stroke-width="2.5"/>
        <line x1="47" y1="16" x2="52" y2="11" stroke="#{blue}" stroke-width="3" stroke-linecap="round"/>
        <line x1="47" y1="44" x2="52" y2="49" stroke="#{red}" stroke-width="3" stroke-linecap="round"/>
      SVG
    when :handles
      <<~SVG
        <circle cx="17" cy="39" r="4" fill="none" stroke="#{grey}" stroke-width="3"/>
        <circle cx="47" cy="39" r="4" fill="none" stroke="#{grey}" stroke-width="3"/>
        <path d="M17 39 C18 18 46 18 47 39" fill="none" stroke="#{blue}" stroke-width="5" stroke-linecap="round"/>
        <path d="M21 35 C24 24 40 24 43 35" fill="none" stroke="#{red}" stroke-width="2.5" stroke-linecap="round"/>
      SVG
    when :hardware
      <<~SVG
        <rect x="7" y="17" width="19" height="30" rx="3" fill="none" stroke="#{grey}" stroke-width="4"/>
        <circle cx="16.5" cy="32" r="5" fill="none" stroke="#{red}" stroke-width="3"/>
        <path d="M26 26 H37 C41 26 42 21 47 18 H56 V46 H47 C42 43 41 38 37 38 H26" fill="none" stroke="#{blue}" stroke-width="4" stroke-linejoin="round"/>
        <circle cx="51" cy="24" r="2.7" fill="#{grey}"/>
        <circle cx="51" cy="40" r="2.7" fill="#{grey}"/>
      SVG
    when :appliances
      <<~SVG
        <rect x="14" y="7" width="36" height="50" rx="3" fill="none" stroke="#{blue}" stroke-width="3"/>
        <line x1="15" y1="21" x2="49" y2="21" stroke="#{red}" stroke-width="3"/>
        <circle cx="21" cy="14" r="2.5" fill="#{grey}"/>
        <circle cx="29" cy="14" r="2.5" fill="#{grey}"/>
        <circle cx="43" cy="14" r="2.5" fill="#{red}"/>
        <rect x="19" y="27" width="26" height="22" rx="2" fill="none" stroke="#{grey}" stroke-width="3"/>
        <line x1="21" y1="25" x2="43" y2="25" stroke="#{blue}" stroke-width="4" stroke-linecap="round"/>
        <path d="M23 43 C27 38 37 38 41 43" fill="none" stroke="#{red}" stroke-width="2.5" stroke-linecap="round"/>
      SVG
    when :operations
      <<~SVG
        <path d="M21 10 H43 L40 18 H24 Z" fill="none" stroke="#{blue}" stroke-width="3" stroke-linejoin="round"/>
        <path d="M27 18 L39 18 L26 50 L35 45 L31 55" fill="none" stroke="#{blue}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
        <line x1="24" y1="18" x2="40" y2="18" stroke="#{red}" stroke-width="3"/>
        <circle cx="31" cy="55" r="2.5" fill="#{grey}"/>
      SVG
    when :dimensions
      <<~SVG
        <path d="M12 17 H52 M12 47 H52 M18 11 V53 M46 11 V53" fill="none" stroke="#{blue}" stroke-width="2.5"/>
        <path d="M22 32 H42 M22 32 L28 27 M22 32 L28 37 M42 32 L36 27 M42 32 L36 37" fill="none" stroke="#{red}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        <circle cx="18" cy="17" r="2.5" fill="#{grey}"/><circle cx="46" cy="47" r="2.5" fill="#{grey}"/>
      SVG
    when :remove_abf_blocked
      <<~SVG
        <path d="M19 20 H45 L42 54 H22 Z" fill="none" stroke="#{blue}" stroke-width="3" stroke-linejoin="round"/>
        <path d="M16 17 H48 M25 17 V11 H39 V17" fill="none" stroke="#{grey}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
        <path d="M27 29 L37 43 M37 29 L27 43" fill="none" stroke="#{red}" stroke-width="4" stroke-linecap="round"/>
      SVG
    else
      '<circle cx="32" cy="32" r="14" fill="none" stroke="#1479c9" stroke-width="3"/>'
    end
  end

  def self.create_svg(path, icon_id, on)
    symbol_opacity = on ? "1.0" : "0.78"
    symbol = icon_markup(icon_id)
    status = if on
               '<circle cx="55" cy="9" r="4" fill="#43bde3" stroke="#075d99" stroke-width="1.5"/>'
             else
               '<circle cx="55" cy="9" r="4" fill="none" stroke="#174562" stroke-width="1.5"/>'
             end

    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
        <g opacity="#{symbol_opacity}">
          #{symbol}
        </g>
        #{status}
      </svg>
    SVG

    File.write(path, svg)
  end

  def self.create_action_svg(path, icon_id)
    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
        #{icon_markup(icon_id)}
      </svg>
    SVG

    File.write(path, svg)
  end

  def self.abf_blocked_group?(group)
    names = [group.name.to_s]
    names << group.definition.name.to_s if group.respond_to?(:definition) && group.definition
    names.any? { |name| name.match?(/\AABFBlocked(?:\z|[\s_-])/i) }
  end

  def self.collect_abf_blocked_groups(entities, groups = [], visited_definitions = {})
    entities.each do |entity|
      next unless entity.valid?

      if entity.is_a?(Sketchup::Group)
        if abf_blocked_group?(entity)
          groups << entity
        else
          collect_abf_blocked_groups(entity.entities, groups, visited_definitions)
        end
      elsif entity.is_a?(Sketchup::ComponentInstance)
        definition = entity.definition
        next unless definition

        key = definition.respond_to?(:persistent_id) ? definition.persistent_id : definition.object_id
        next if visited_definitions[key]

        visited_definitions[key] = true
        collect_abf_blocked_groups(definition.entities, groups, visited_definitions)
      end
    end

    groups
  end

  def self.remove_abf_blocked_groups
    model = Sketchup.active_model
    operation_started = false
    groups = collect_abf_blocked_groups(model.entities).select(&:valid?)

    if groups.empty?
      UI.messagebox("No ABFBlocked groups were found in this model.")
      return
    end

    answer = UI.messagebox(
      "Found #{groups.length} ABFBlocked group(s). Remove them from the entire model?\n\nYou can undo this operation with Ctrl+Z.",
      MB_YESNO
    )
    return unless answer == IDYES

    model.start_operation("Remove ABFBlocked groups", true)
    operation_started = true
    removed = 0
    groups.each do |group|
      next unless group.valid?

      group.erase!
      removed += 1
    end
    model.commit_operation
    operation_started = false

    UI.messagebox("Removed #{removed} ABFBlocked group(s).")
  rescue => error
    model.abort_operation if model && operation_started
    UI.messagebox("Could not remove ABFBlocked groups:\n#{error.message}")
  end

  def self.existing_tags(button)
    model = Sketchup.active_model
    config=button_config(button)
    return [] unless config[:mode]=='tag'
    model.layers.select { |tag| config[:names].any? { |name| tag.name.casecmp?(name) } }
  end

  def self.button_config(button)
    if defined?(Elfis::StudioSettings)
      Elfis::StudioSettings.visibility_button(button[:id])
    else
      {id:button[:id],label:button[:label],mode:'tag',names:button[:tags]}
    end
  end

  def self.matching_groups(button,model=Sketchup.active_model)
    config=button_config(button);return [] unless config[:mode]=='group'
    @group_cache ||= {}
    @model_observers ||= {}
    unless @model_observers[model]
      observer=GroupCacheObserver.new
      model.add_observer(observer)
      @model_observers[model]=observer
    end
    key=[model,config[:names].map(&:downcase).sort]
    cached=@group_cache[key]
    return cached.select(&:valid?) if cached
    @group_cache[key]=scan_groups(config[:names],model)
  end

  def self.invalidate_groups(model=nil)
    return unless @group_cache
    model ? @group_cache.delete_if { |key,_| key.first==model } : @group_cache.clear
  end

  class GroupCacheObserver < Sketchup::ModelObserver
    def onTransactionCommit(model);ELFIS_TagToolbar.invalidate_groups(model);end
    def onTransactionUndo(model);ELFIS_TagToolbar.invalidate_groups(model);end
    def onTransactionRedo(model);ELFIS_TagToolbar.invalidate_groups(model);end
    def onTransactionAbort(model);ELFIS_TagToolbar.invalidate_groups(model);end
    def onDeleteModel(model)
      ELFIS_TagToolbar.invalidate_groups(model)
    end
  end

  # Toolbar validation runs repeatedly during camera movement. Traverse each
  # reachable definition only once, and never repeat the traversal on a cache hit.
  def self.scan_groups(names,model)
    out=[];walk=nil
    visited={}
    walk=->(entities) do
      entities.each do |entity|
        next unless entity.valid? && (entity.is_a?(Sketchup::Group)||entity.is_a?(Sketchup::ComponentInstance))
        if entity.is_a?(Sketchup::Group) && names.any? { |name| entity.name.casecmp?(name) }
          out<<entity
        end
        next if visited[entity.definition]
        visited[entity.definition]=true
        walk.call(entity.definition.entities)
      end
    end
    walk.call(model.entities);out.uniq
  end

  def self.button_on?(button)
    config=button_config(button)
    if config[:mode]=='group'
      groups=matching_groups(button);!groups.empty? && groups.all? { |g| !g.hidden? }
    else
      tags=existing_tags(button);!tags.empty? && tags.all?(&:visible?)
    end
  end

  def self.update_icon(button)
    cmd = @commands[button[:id]]
    return unless cmd

    state = button_on?(button)
    filename = File.join(icon_folder, "#{button[:id]}_#{state ? 'on' : 'off'}.svg")

    create_svg(filename, button[:id], state)

    cmd.small_icon = filename
    cmd.large_icon = filename
    cmd.tooltip = "#{button[:label]}: #{state ? 'ON' : 'OFF'}"
    config=button_config(button)
    cmd.status_bar_text = "Toggle #{config[:mode]}: #{config[:names].join(', ')} (currently #{state ? 'ON' : 'OFF'})"
  end

  def self.toggle(button)
    model = Sketchup.active_model
    config=button_config(button)
    groups=config[:mode]=='group' ? matching_groups(button,model) : []
    tags=config[:mode]=='tag' ? existing_tags(button) : []
    if groups.empty? && tags.empty?
      Sketchup.set_status_text("#{button[:label]}: no matching #{config[:mode]} — #{config[:names].join(', ')}");return
    end
    new_state = !button_on?(button)
    model.start_operation("Toggle #{button[:label]}", true)
    groups.each { |group| group.hidden=!new_state }
    tags.each { |tag| tag.visible = new_state }
    model.commit_operation

    update_icon(button)
    UI.refresh_toolbars
  end

  def self.start
    return if @toolbar && @toolbar.visible?
    ensure_tags

    unless @app_observer
      @app_observer = AppObserver.new
      Sketchup.add_observer(@app_observer)
    end

    return if @toolbar && @toolbar.visible?

    @toolbar = UI::Toolbar.new("ELFIS Tags")
    @commands = {}

    BUTTONS.each do |button|
      cmd = UI::Command.new("Toggle #{button[:label]}") {
        toggle(button)
      }

      cmd.set_validation_proc do
        button_on?(button) ? MF_CHECKED : MF_UNCHECKED
      end

      @commands[button[:id]] = cmd
      update_icon(button)
      @toolbar.add_item(cmd)
      @toolbar.add_separator if [:room, :finishing, :appliances, :operations].include?(button[:id])
    end

    @toolbar.add_separator
    cleanup_cmd = UI::Command.new("Remove ABFBlocked") {
      remove_abf_blocked_groups
    }
    cleanup_icon = File.join(icon_folder, "remove_abf_blocked.svg")
    create_action_svg(cleanup_icon, :remove_abf_blocked)
    cleanup_cmd.small_icon = cleanup_icon
    cleanup_cmd.large_icon = cleanup_icon
    cleanup_cmd.tooltip = "Remove ABFBlocked groups"
    cleanup_cmd.status_bar_text = "Find and remove all ABFBlocked groups from the model."
    @cleanup_command = cleanup_cmd
    @toolbar.add_item(cleanup_cmd)

    @toolbar.show
  end

  def self.refresh
    invalidate_groups
    BUTTONS.each { |button| update_icon(button) }
    UI.refresh_toolbars
  end
end

ELFIS_TagToolbar.start
