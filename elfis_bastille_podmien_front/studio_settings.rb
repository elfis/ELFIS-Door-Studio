# encoding: UTF-8
require 'json'
require 'base64'
module Elfis
  module StudioSettings
    extend self
    PREF='ELFIS Studio Defaults' unless const_defined?(:PREF)
    TAG_DEFAULTS={sides:['Body'],joints:['Body'],shelves:['Body'],backs:['Back Wall'],facades:['Facade'],operations:['Blum Operations']}.freeze unless const_defined?(:TAG_DEFAULTS)
    VISIBILITY_DEFAULTS=[
      {id:'room',label:'Room',mode:'tag',names:['Windows','Walls','Skirting Boards','Room Doors','Floor Plan','Floor','Ceiling']},
      {id:'facade',label:'Facade',mode:'tag',names:['Facade']},
      {id:'body',label:'Body',mode:'tag',names:['Body']},
      {id:'back_wall',label:'Back Wall',mode:'tag',names:['Back Wall']},
      {id:'worktops',label:'Worktops',mode:'tag',names:['Worktops']},
      {id:'finishing',label:'Finishing Parts',mode:'tag',names:['End Panels','Plinths','Fillers','Decorative Panels','Cover Panels','Cornices','Light Pelmets']},
      {id:'handles',label:'Handles',mode:'tag',names:['Handles']},
      {id:'hardware',label:'Hardware',mode:'tag',names:['Hardware','Blum Hardware','Extra Blum Hardware']},
      {id:'appliances',label:'Appliances',mode:'tag',names:['Appliances']},
      {id:'operations',label:'Blum Operations',mode:'tag',names:['Blum Operations','Blum Operations (unbound)']},
      {id:'dimensions',label:'Dimensions',mode:'tag',names:['Dimensions']}
    ].freeze unless const_defined?(:VISIBILITY_DEFAULTS)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def names(value)
      (value.is_a?(Array) ? value : value.to_s.split(',')).map { |s| s.to_s.strip }.reject(&:empty?).uniq { |s| s.downcase }
    end
    def tag_config
      @tags ||= begin
        data=read_json_setting('tags',{})
        data={} unless data.is_a?(Hash)
        TAG_DEFAULTS.to_h { |k,v| [k,names(data.fetch(k,v))] }
      end
    end
    def role?(entity,role);tag_config.fetch(role).any? { |s| entity.layer.name.casecmp?(s) };end
    def panel?(entity);%i[sides joints shelves backs].any? { |role| role?(entity,role) };end
    def operation_tag;tag_config[:operations].first;end
    def visibility
      @visibility ||= begin
        saved=read_json_setting('visibility',[])
        saved=[] unless saved.is_a?(Array)
        saved=saved.select { |row| row.is_a?(Hash) }
        VISIBILITY_DEFAULTS.map do |v|
          row=saved.find { |x| x[:id]==v[:id] };row && %w[tag group].include?(row[:mode]) && !names(row[:names]).empty? ? v.merge(mode:row[:mode],names:names(row[:names])) : v.dup
        end
      end
    end
    # SketchUp's preference reader evaluates its stored string literal. Raw JSON
    # quotes can survive the session but fail after restart. Base64 contains no
    # quotes or escapes; keep old keys intact for recovery and older versions.
    def write_json_setting(key,value)
      Sketchup.write_default(PREF,"#{key}_base64",Base64.strict_encode64(JSON.generate(value)))
    end
    def legacy_json_setting(key)
      # Read only this extension's existing value, never evaluate preference text.
      # Native read_default may print an eval error and return nil instead of
      # raising it. Prefer the persisted legacy text on Windows during migration.
      root=ENV['LOCALAPPDATA']
      if root && Sketchup.respond_to?(:version)
        file=File.join(root,'SketchUp',"SketchUp 20#{Sketchup.version.to_s.split('.').first}",'SketchUp','PrivatePreferences.json')
        begin
          raw=JSON.parse(File.read(file)).dig('This Computer Only',PREF,key)
          if raw.is_a?(String)
            raw=raw[1...-1] if raw.start_with?('"') && raw.end_with?('"')
            return JSON.parse(raw,symbolize_names:true)
          end
        rescue StandardError
          # A fresh installation may not have a preferences file yet.
        end
      end
      raw=Sketchup.read_default(PREF,key,'null')
      raw.is_a?(String) ? JSON.parse(raw,symbolize_names:true) : nil
    end
    def read_json_setting(key,fallback)
      encoded=Sketchup.read_default(PREF,"#{key}_base64",'')
      unless encoded.to_s.empty?
        begin
          return JSON.parse(Base64.strict_decode64(encoded),symbolize_names:true)
        rescue ArgumentError,JSON::ParserError
          # A damaged new value may still have a recoverable legacy value.
        end
      end
      value=legacy_json_setting(key)
      return fallback if value.nil?
      write_json_setting(key,value);value
    rescue StandardError,SyntaxError
      fallback
    end
    def visibility_button(id);visibility.find { |b| b[:id]==id.to_s };end
    def defaults;{pins:ShelfPins.defaults,joints:CarcassJoinery.defaults,hinges:HingeDrilling.defaults,drawers:DrawerDrilling.defaults,tags:TAG_DEFAULTS,visibility:VISIBILITY_DEFAULTS};end
    def data
      {pins:ShelfPins.settings,joints:CarcassJoinery.settings,hinges:HingeDrilling.settings,drawers:DrawerDrilling.settings,tags:tag_config,visibility:visibility,language:BastillePodmienFront.language}
    end
    def validate(input)
      pins=ShelfPins.validate(input.fetch(:pins));pins[:reuse]=input[:pins][:reuse]==true
      joints=CarcassJoinery.validate(input.fetch(:joints))
      hinges=HingeDrilling.validate(input.fetch(:hinges,HingeDrilling.settings))
      drawers=DrawerDrilling.validate(input.fetch(:drawers,DrawerDrilling.settings))
      tags=TAG_DEFAULTS.to_h do |key,_|
        list=names(input.fetch(:tags).fetch(key));raise l('Lista tagów nie może być pusta.','Tag lists cannot be empty.') if list.empty?
        raise l('Tag grup operacji musi być pojedynczą nazwą.','The operation group tag must be a single name.') if key==:operations && list.length!=1
        raise l('Nieprawidłowa nazwa tagu.','Invalid tag name.') if list.any? { |s| s.length>200 || s.match?(/[\x00-\x1f]/) }
        [key,list]
      end
      raise l('Plecy i pozostałe panele muszą mieć różne tagi.','Back and other panel tags must be distinct.') unless (tags[:backs].map(&:downcase) & tags.values_at(:sides,:joints,:shelves).flatten.map(&:downcase)).empty?
      vis=VISIBILITY_DEFAULTS.map do |v|
        row=input.fetch(:visibility).find { |x| x[:id]==v[:id] };raise 'Missing visibility button.' unless row
        list=names(row[:names]);raise l('Podaj nazwy dla każdego przycisku.','Provide names for every visibility button.') if list.empty? || list.any? { |s| s.length>200 || s.match?(/[\x00-\x1f]/) }
        raise 'Invalid visibility mode.' unless %w[tag group].include?(row[:mode])
        v.merge(mode:row[:mode],names:list)
      end
      {pins:pins,joints:joints,hinges:hinges,drawers:drawers,tags:tags,visibility:vis}
    end
    def save(input)
      c=validate(input)
      # Validate every section before writing any preference. Keep old tool keys
      # so the existing right-click settings and central panel stay synchronized.
      c[:pins].each { |k,v| Sketchup.write_default(ShelfPins::PREF,k.to_s,v) }
      c[:joints].each { |k,v| Sketchup.write_default(CarcassJoinery::PREF,k.to_s,v) }
      c[:hinges].each { |k,v| Sketchup.write_default(HingeDrilling::PREF,k.to_s,v) }
      c[:drawers].each { |k,v| Sketchup.write_default(DrawerDrilling::PREF,k.to_s,v) }
      write_json_setting('tags',c[:tags]);write_json_setting('visibility',c[:visibility])
      @tags=c[:tags];@visibility=c[:visibility]
      ELFIS_TagToolbar.refresh if defined?(ELFIS_TagToolbar)
      model=Sketchup.active_model;tool=model.tools.active_tool if model.tools.respond_to?(:active_tool)
      if tool.is_a?(DrawerDrilling::Tool);tool.update_settings(c[:drawers])
      elsif tool.is_a?(HingeDrilling::Tool);tool.update_settings(c[:hinges])
      elsif tool.instance_of?(ShelfPins::Tool);tool.update_settings(c[:pins])
      elsif tool.instance_of?(CarcassJoinery::Tool);tool.update_settings(c[:joints]);end
      data
    end
    def show(tab='joints')
      if @dialog && @dialog.visible?
        @dialog.bring_to_front;@dialog.execute_script("choose(#{JSON.generate(tab)})");return
      end
      @dialog=UI::HtmlDialog.new(dialog_title:l('ELFIS — Ustawienia domyślne','ELFIS — Default settings'),preferences_key:'ElfisStudioDefaults',width:780,height:850,min_width:540,min_height:600,resizable:true)
      dialog=@dialog;dialog.set_file(File.join(__dir__,'studio_settings.html'))
      dialog.add_action_callback('studio_settings') do |_,json|
        begin
          request=JSON.parse(json,symbolize_names:true)
          case request[:action]
          when 'ready';dialog.execute_script("setSettings(#{JSON.generate(data.merge(tab:tab))})")
          when 'defaults';dialog.execute_script("setSettings(#{JSON.generate(defaults.merge(language:BastillePodmienFront.language,tab:request[:tab]))})")
          when 'save';dialog.execute_script("savedSettings(#{JSON.generate(save(request[:data]))})")
          when 'scan'
            @scan=DrillingEditor.scan;dialog.execute_script("setDrillings(#{JSON.generate(DrillingEditor.public_rows(@scan))})")
          when 'convert'
            raise l('Najpierw rozpoznaj wiercenia.','Scan drilling first.') unless @scan
            result=DrillingEditor.apply(@scan,request[:ids],request[:parameters],update:request[:update]==true)
            @scan=DrillingEditor.scan(roots:@scan[:roots]);dialog.execute_script("conversionFinished(#{JSON.generate(result)},#{JSON.generate(DrillingEditor.public_rows(@scan))})")
          end
        rescue => error;dialog.execute_script("showError(#{JSON.generate(error.message)})")
        end
      end
      dialog.set_on_closed { @dialog=nil if @dialog.equal?(dialog);@scan=nil };dialog.show
    end
    def install
      return if @command
      @command=UI::Command.new('ELFIS — Default settings / Ustawienia domyślne') { show }
      @command.tooltip=l('Domyślne wiercenia, tagi, widoczność i istniejące otwory','Default drilling, tags, visibility and existing holes')
      @command.small_icon=File.join(__dir__,'studio_settings.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command)
      toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
    end
  end
end
