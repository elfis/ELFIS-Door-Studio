# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require 'fileutils'
require 'securerandom'

module Elfis
  module Handles
    extend self
    remove_const(:VERSION) if const_defined?(:VERSION,false)
    VERSION = '1.1.9-beta'
    DICT = 'ElfisHandles'
    POSITIONS = %w[tl tc tr ml mr bl bc br].freeze
    remove_const(:DEFAULTS) if const_defined?(:DEFAULTS,false)
    DEFAULTS = {model_id:nil, position:'tr', orientation:'vertical', mode:'auto', offset:45.0, offset_x:nil, offset_y:nil, along:45.0, edge_shift:0.0, side_shift:0.0, preserve:true}.freeze

    def api
      unless defined?(Elfis::BastillePodmienFront) && Elfis::BastillePodmienFront.respond_to?(:measure)
        entry=Sketchup.find_support_file('elfis_bastille_podmien_front.rb','Plugins')
        require entry if entry
      end
      raise 'Install ELFIS Door Studio 2.9.1 first.' unless defined?(Elfis::BastillePodmienFront) && Elfis::BastillePodmienFront.respond_to?(:measure)
      install_hooks
      Elfis::BastillePodmienFront
    end

    def l(pl,en)
      defined?(Elfis::BastillePodmienFront) && Elfis::BastillePodmienFront.respond_to?(:l) ? Elfis::BastillePodmienFront.l(pl,en) : en
    end

    def root
      @root_override || File.join(ENV.fetch('APPDATA'), 'ELFIS', 'HandleLibrary')
    end

    def database
      @database ||= begin
        path=File.join(root,'handles.json')
        data=File.file?(path) ? JSON.parse(File.read(path),symbolize_names:true) : {}
        {models:Array(data[:models]),settings:DEFAULTS.merge(data[:settings] || {})}
      end
    end

    def persist
      FileUtils.mkdir_p(root)
      path=File.join(root,'handles.json'); tmp="#{path}.#{SecureRandom.hex(4)}.tmp"
      File.write(tmp,JSON.pretty_generate(database)); File.rename(tmp,path)
    end

    def settings
      database[:settings]
    end

    def handle?(e)
      e.respond_to?(:get_attribute) && e.get_attribute(DICT,'handle',false)
    end

    def children(front)
      front.definition.entities.select { |e| handle?(e) }
    end

    def model_record(id)
      database[:models].find { |m| m[:id]==id } || (raise 'Choose a handle from the library.')
    end

    def config(raw)
      s=DEFAULTS.merge(raw.transform_keys(&:to_sym))
      raise 'Invalid handle position.' unless POSITIONS.include?(s[:position])
      raise 'Invalid orientation.' unless %w[horizontal vertical].include?(s[:orientation])
      raise 'Invalid offset mode.' unless %w[auto custom].include?(s[:mode])
      %i[offset along edge_shift].each do |key|
        s[key]=Float(s[key]); raise 'Offsets must be finite and nonnegative.' unless s[key].finite? && s[key]>=0 && s[key]<=3000
      end
      %i[offset_x offset_y].each do |key|
        next if s[key].nil?
        s[key]=Float(s[key]);raise 'Invalid fixing offset.' unless s[key].finite? && s[key]>=0 && s[key]<=3000
      end
      s[:preserve]=s[:preserve]==true
      s[:side_shift]=Float(s[:side_shift] || 0)
      raise 'Side-centre offset must be finite and between -3000 and 3000 mm.' unless s[:side_shift].finite? && s[:side_shift].abs<=3000
      s
    end

    def geometry_length(definition,record={})
      bounds=Geom::BoundingBox.new
      visit=lambda do |entities,transform,stack|
        entities.each do |entity|
          if entity.is_a?(Sketchup::Edge)
            entity.vertices.each { |vertex| bounds.add(vertex.position.transform(transform)) }
          elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            child=entity.definition
            next if stack.include?(child)
            visit.call(child.entities,transform*entity.transformation,stack+[child])
          end
        end
      end
      visit.call(definition.entities,mount_inverse(record),[definition])
      raise l('Model uchwytu nie zawiera geometrii.','The handle model contains no geometry.') unless bounds.valid?
      spans=[bounds.width,bounds.height,bounds.depth].map(&:to_mm)
      # After calibration X follows the fixing screws. Before calibration the
      # longest file-axis span is a provisional import suggestion only.
      length=if record[:kind]=='knob' then spans.take(2).max
      elsif record[:mount_frame] || record[:kind]=='edge' then spans[0]
      else spans.max
      end
      raise 'Invalid measured handle length.' unless length.finite? && length>0
      length.round(3)
    end

    def import_length(path)
      model=Sketchup.active_model
      model.start_operation('ELFIS — Read handle dimensions',true)
      begin
        loaded=model.definitions.load(path)
        raise 'Unable to load the handle model.' unless loaded
        geometry_length(loaded)
      ensure
        model.abort_operation
      end
    end

    def record_import
      path=UI.openpanel(l('Wybierz model uchwytu','Choose a handle model'),nil,'SketchUp models|*.skp||')
      return unless path
      raise 'Choose a .skp file.' unless File.extname(path).downcase=='.skp'
      measured=import_length(path)
      values=UI.inputbox(['Name / Nazwa','Type / Rodzaj','Pitch / Rozstaw mm','Length / Długość mm (Auto)','Finish / Wykończenie','Supplier / Producent','Product code / Kod'],[File.basename(path,'.skp'),'standard',160,measured,'','',''],['','standard|knob|edge','','','','',''],'ELFIS — Import handle')
      return unless values
      name,kind,pitch,length,finish,supplier,code=values
      raise 'Enter a name and a valid handle type.' if name.to_s.strip.empty? || !%w[standard knob edge].include?(kind)
      pitch=Float(pitch); length=Float(length)
      raise 'Invalid pitch or length.' unless pitch.finite? && pitch>=0 && length.finite? && length>0 && (kind!='standard' || pitch>0)
      id=SecureRandom.uuid
      FileUtils.mkdir_p(File.join(root,'models'))
      destination=File.join(root,'models',"#{id}.skp")
      FileUtils.copy_file(path,destination)
      database[:models]<<{id:id,name:name.strip,kind:kind,pitch:pitch,length:length,length_auto:(length-measured).abs<0.001,finish:finish.to_s,supplier:supplier.to_s,code:code.to_s,file:"#{id}.skp"}
      settings[:model_id]=id
      persist
      calibrate(id) unless kind=='edge'
    end

    def edit_record(id)
      m=model_record(id)
      measured=geometry_length(definition(Sketchup.active_model,m),m)
      defaults=m.values_at(:name,:pitch,:length,:finish,:supplier,:code)
      defaults[2]=measured unless m[:length_auto]==false
      values=UI.inputbox(['Name / Nazwa','Pitch / Rozstaw mm',"Length / Długość mm (Auto: #{measured})",'Finish / Wykończenie','Supplier / Producent','Product code / Kod'],defaults,'ELFIS — Edit handle')
      return unless values
      candidate=m.merge(%i[name pitch length finish supplier code].zip(values).to_h)
      candidate[:pitch]=Float(candidate[:pitch]);candidate[:length]=Float(candidate[:length])
      raise 'Invalid name or dimensions.' unless !candidate[:name].to_s.strip.empty? && candidate[:pitch].finite? && candidate[:pitch]>=0 && candidate[:length].finite? && candidate[:length]>0 && (candidate[:kind]!='standard' || candidate[:pitch]>0)
      candidate[:length_auto]=(candidate[:length]-measured).abs<0.001
      m.replace(candidate);persist
    end

    def definition(model,record)
      # The copied SKP contains its axes. No exploding, rescaling or recentering.
      model.definitions.find { |d| d.get_attribute(DICT,'library_id')==record[:id] } || begin
        path=File.join(root,'models',File.basename(record.fetch(:file)))
        raise "Missing handle model: #{record[:name]}" unless File.file?(path)
        d=model.definitions.load(path)
        raise 'Unable to load the handle model.' unless d
        d.set_attribute(DICT,'library_id',record[:id]);d
      end
    end

    def mount_inverse(record)
      raw=record[:mount_frame]
      return IDENTITY unless raw
      raise 'Invalid mounting calibration.' unless raw.is_a?(Array) && raw.length==16 && raw.all? { |v| v.is_a?(Numeric) && v.finite? }
      Geom::Transformation.new(raw).inverse
    end

    def resolved_settings(front,chosen)
      s=chosen.dup
      previous=children(front).first
      if s[:preserve] && previous
        saved=JSON.parse(previous.get_attribute(DICT,'settings'),symbolize_names:true)
        s=saved.merge(model_id:s[:model_id],preserve:s[:preserve])
      end
      record=model_record(s[:model_id])
      s[:position]={'tl'=>'ml','tr'=>'mr','bl'=>'ml','br'=>'mr'}.fetch(s[:position],s[:position]) if record[:kind]=='edge' && s[:edge_layout]!='perimeter'
      config(s)
    end

    def mount_transform(front,info,record,s)
      placement(info[:width],info[:height],info[:source_thickness],record,s,frame_offset(front))*mount_inverse(record)
    end

    def update_settings(raw)
      next_settings=config(raw)
      settings.replace(next_settings)
      UI.stop_timer(@save_timer) if @save_timer
      @save_timer=UI.start_timer(0.5,false) { @save_timer=nil;persist }
      @click_tool.settings_changed if @click_tool
    end

    def frame_offset(front)
      return nil unless %w[shaker onepiece].include?(front.get_attribute('ElfisBastillePodmien','kind',''))
      return nil if front.get_attribute('ElfisBastillePodmien','variant')=='drawer'
      geometry=front.get_attribute('ElfisBastillePodmien','profile_geometry')
      width=geometry && JSON.parse(geometry)[2][1]
      return width.to_f/2 if width && width.to_f>0
      p=api.library[:profiles].find { |r| r[:id]==front.get_attribute('ElfisBastillePodmien','profile_id') }
      p && p[:width] ? p[:width].to_f/2 : nil
    end

    def measure(front,path,normal=nil)
      sign=children(front).first&.get_attribute(DICT,'front_sign')
      bounds=api.door_bounds(front)
      # Use the existing front's actual thickness; avoid any drawer-family rules.
      info=api.measure(front,Sketchup.active_model,normal,path,{kind:'slab',thickness:18.0,name:'Handle target'})
      if sign && !front.get_attribute('ElfisBastillePodmien','generated',false)
        depth=info[:axes][1]
        tr=info[:world]; origin=ORIGIN.transform(tr)
        v=Geom::Point3d.new([0,0,0].tap { |a| a[depth]=sign }).transform(tr)-origin
        info=api.measure(front,Sketchup.active_model,v,path,{kind:'slab',thickness:18.0,name:'Handle target'},bounds)
      end
      info
    end

    # Canonical door coordinates: width X, outward depth Y, height Z, all in mm.
    # Return an actual rigid handle rotation: local X cross local Y = local Z.
    def placement(w,h,t,record,s,auto_offset=nil)
      w,h,t=[w,h,t].map(&:to_f)
      p=s[:position]; edge=record[:kind]=='edge'
      d=s[:mode]=='auto' ? (auto_offset || s[:offset]) : s[:offset]
      dx=s[:mode]=='auto' && auto_offset ? auto_offset : (s[:offset_x] || d)
      dy=s[:mode]=='auto' && auto_offset ? auto_offset : (s[:offset_y] || d)
      pitch=record[:kind]=='knob' ? 0.0 : record[:pitch].to_f
      if edge
        horizontal=%w[tc bc].include?(p) || (!%w[ml mr].include?(p) && s[:orientation]=='horizontal')
        span=horizontal ? w : h
        raise 'The edge pull does not fit this front.' if record[:length]>span+0.001
        if horizontal
          x=p.end_with?('l') ? s[:along]+record[:length]/2 : p.end_with?('r') ? w-s[:along]-record[:length]/2 : w/2+s[:edge_shift]
          z=p.start_with?('b') ? 0 : h;ax=z==h ? [-1,0,0] : [1,0,0]
          raise 'The edge pull extends beyond the front.' unless x-record[:length]/2>=-0.001 && x+record[:length]/2<=w+0.001
        else
          x=p.end_with?('l') ? 0 : w
          z=if p.start_with?('b') then s[:along]+record[:length]/2
          elsif p.start_with?('m') && s[:edge_layout]=='perimeter' then h/2+s[:side_shift].to_f
          else h-s[:along]-record[:length]/2
          end
          ax=x==0 ? [0,0,-1] : [0,0,1]
          raise 'The edge pull extends beyond the front.' unless z-record[:length]/2>=-0.001 && z+record[:length]/2<=h+0.001
        end
        depth=0 # Rear fixing: handle origin is the rear edge, never the front.
      else
        x=p.end_with?('l') ? dx : p.end_with?('r') ? w-dx : w/2
        z=p.start_with?('t') ? h-dy : p.start_with?('b') ? dy : h/2
        if s[:orientation]=='vertical'
          ax=p.start_with?('b') ? [0,0,1] : [0,0,-1]
          z-=ax[2]*pitch/2 if p.start_with?('m')
        else
          ax=p.end_with?('l') ? [1,0,0] : [-1,0,0]
          x-=ax[0]*pitch/2 unless p.end_with?('l') || p.end_with?('r')
        end
        end_x=x+ax[0]*pitch;end_z=z+ax[2]*pitch
        raise 'The fixing points do not fit this front. Reduce the offset or pitch.' unless [x,end_x].all? { |v| v>=-0.001 && v<=w+0.001 } && [z,end_z].all? { |v| v>=-0.001 && v<=h+0.001 }
        depth=t
      end
      ay=[ax[2],0,-ax[0]]
      Geom::Transformation.axes(Geom::Point3d.new(x.mm,depth.mm,z.mm),Geom::Vector3d.new(ax),Geom::Vector3d.new(ay),Geom::Vector3d.new(0,1,0))
    end

    def apply(path,chosen=settings,normal=nil,operation:true)
      model=Sketchup.active_model
      raise 'The front no longer exists.' unless path && path.all?(&:valid?)
      front=path.last
      info=measure(front,path,normal)
      s=resolved_settings(front,chosen)
      record=model_record(s[:model_id])
      transform=mount_transform(front,info,record,s)
      definition=definition(model,record)
      model.start_operation('ELFIS — Handle',true) if operation
      begin
        path=api.unique_path(path);front=path.last
        front.make_unique if front.definition.instances.length>1
        # Real-world dimensions survive scaled and mirrored cabinet instances.
        parent_world=path[0...-1].inject(model.edit_transform) { |tr,e| tr*e.transformation }
        local=(parent_world*front.transformation).inverse*info[:world_placement]*transform
        mounted=front.definition.entities.add_instance(definition,local)
        mounted.name="#{record[:name]} — #{record[:finish]}"
        mounted.set_attribute(DICT,'handle',true)
        mounted.set_attribute(DICT,'settings',JSON.generate(s))
        mounted.set_attribute(DICT,'record',JSON.generate(record.reject { |k,_| k==:file }))
        mounted.set_attribute(DICT,'front_sign',info[:front_sign])
        children(front).each { |e| e.erase! unless e==mounted }
        model.commit_operation if operation
        mounted
      rescue
        model.abort_operation if operation
        raise
      end
    end

    def remove_from_front(path,operation:true)
      model=Sketchup.active_model
      raise l('Front już nie istnieje.','The front no longer exists.') unless path && path.all?(&:valid?)
      raise l('Front lub szafka są zablokowane.','The front or cabinet is locked.') if path.any?(&:locked?)
      return 0 if children(path.last).empty?
      raise l('Uchwyt jest zablokowany.','A handle is locked.') if children(path.last).any?(&:locked?)
      model.start_operation('ELFIS — Remove handles',true) if operation
      begin
        front=api.unique_path(path).last
        front.make_unique if front.definition.instances.length>1
        handles=children(front);count=handles.length
        front.definition.entities.erase_entities(handles)
        model.commit_operation if operation
        count
      rescue
        model.abort_operation if operation
        raise
      end
    end

    def reflow(front)
      return if children(front).empty?
      front.make_unique if front.definition.instances.length>1
      w=front.get_attribute('ElfisBastillePodmien','width_mm')
      h=front.get_attribute('ElfisBastillePodmien','height_mm')
      t=front.get_attribute('ElfisBastillePodmien','thickness_mm')
      raise 'Cannot resolve replacement door dimensions.' unless w && h && t
      children(front).each do |child|
        s=JSON.parse(child.get_attribute(DICT,'settings'),symbolize_names:true)
        record=JSON.parse(child.get_attribute(DICT,'record'),symbolize_names:true)
        child.transformation=placement(w,h,t,record,s,frame_offset(front))*mount_inverse(record)
        child.set_attribute(DICT,'front_sign',1.0)
      end
    end

    module DoorHooks
      def door_bounds(source)
        result=super
        return result if source.get_attribute('ElfisBastillePodmien','generated',false) || Elfis::Handles.children(source).empty?
        bb=Geom::BoundingBox.new
        source.definition.entities.each { |e| bb.add(e.bounds) if e.respond_to?(:bounds) && !Elfis::Handles.handle?(e) }
        bb.valid? ? bb : result
      end

      def preserve_nested_entities(source,replacement)
        result=super
        Elfis::Handles.reflow(replacement)
        result
      end
    end

    def install_hooks
      base=Elfis::BastillePodmienFront.singleton_class
      base.prepend(DoorHooks) unless base.ancestors.include?(DoorHooks)
    end

    def scan(entities,path=[],&block)
      entities.each do |e|
        next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
        next if handle?(e)
        current=path+[e]
        yield(current) unless children(e).empty?
        scan(e.definition.entities,current,&block)
      end
    end

    def batch_paths(mode)
      model=Sketchup.active_model;paths=[]
      if mode=='all'
        raise 'Exit the current group before replacing all handles.' if model.active_path
        scan(model.entities) { |p| paths<<p }
      else
        model.selection.each do |e|
          next unless e.is_a?(Sketchup::ComponentInstance)
          nested=[]
          if children(e).empty? && !e.get_attribute('ElfisBastillePodmien','generated',false)
            scan(e.definition.entities,[e]) { |p| nested<<p }
          end
          unless nested.empty?
            paths.concat(nested)
            next
          end
          begin
            measure(e,[e]);paths<<[e]
          rescue
            scan(e.definition.entities,[e]) { |p| paths<<p }
          end
        end
      end
      paths
    end

    def batch(mode,operation:true)
      paths=batch_paths(mode)
      raise 'Select front components, or choose all existing handles.' if paths.empty?
      raise 'A locked cabinet is included.' if paths.flatten.any?(&:locked?)
      model=Sketchup.active_model
      model.start_operation('ELFIS — Replace handles',true) if operation
      begin
        # Resolve each path by entity-index route after cabinet copies are isolated.
        routes=paths.map { |path| [path.first,path.each_cons(2).map { |a,b| a.definition.entities.to_a.index(b) }] }
        routes.each do |root,indices|
          path=[root]
          indices.each { |index| path<<path.last.definition.entities.to_a.fetch(index) }
          apply(path,settings,nil,operation:false)
        end
        model.commit_operation if operation
      rescue
        model.abort_operation if operation
        raise
      end
      paths.length
    end

    def order_rows
      rows={}
      scan(Sketchup.active_model.entities) do |path|
        children(path.last).each do |handle|
          r=JSON.parse(handle.get_attribute(DICT,'record'),symbolize_names:true)
          key=r.values_at(:id,:name,:finish,:supplier,:code)
          row=rows[key]||=r.merge(quantity:0);row[:quantity]+=1
        end
      end
      rows.values
    end

    def payload
      {version:VERSION,language:(defined?(Elfis::BastillePodmienFront) ? Elfis::BastillePodmienFront.language : 'en'),models:database[:models],settings:settings,rows:order_rows}
    end

    def refresh(message=nil)
      @dialog.execute_script("receive(#{JSON.generate(payload)})") if @dialog
      @dialog.execute_script("notice(#{JSON.generate(message.to_s)})") if @dialog && message
    end

    def preview_payload(front,info,record,s)
      tr=placement(info[:width],info[:height],info[:source_thickness],record,s,frame_offset(front))
      if record[:kind]=='edge'
        half=record[:length].mm/2
        a=Geom::Point3d.new(-half,0,0).transform(tr)
        b=Geom::Point3d.new(half,0,0).transform(tr)
      else
        a=ORIGIN.transform(tr)
        b=Geom::Point3d.new((record[:kind]=='knob' ? 0 : record[:pitch]).mm,0,0).transform(tr)
      end
      {width:info[:width],height:info[:height],frame_offset:frame_offset(front),position:s[:position],placement:{a:[a.x.to_mm,a.z.to_mm],b:[b.x.to_mm,b.z.to_mm],edge:record[:kind]=='edge'}}
    end

    def publish_preview(value)
      return unless @dialog
      encoded=JSON.generate(value)
      return if encoded==@last_preview
      @last_preview=encoded
      @dialog.execute_script("hoverPlacement(#{encoded})")
    end

    def prepare_quick_placement
      return if settings[:quick_placement_defaults]==1
      # Apply the requested starting setup once; subsequent library choices stay.
      preferred=database[:models].find { |r| r[:name].to_s.strip.casecmp('Block Key Bar Handle').zero? }
      preferred ||= database[:models].find { |r| r[:id]==settings[:model_id] }
      preferred ||= database[:models].find { |r| r[:kind]=='standard' } || database[:models].first
      settings.merge!(model_id:preferred&.dig(:id),position:'tr',orientation:'vertical',preserve:false,quick_placement_defaults:1)
      persist
    end

    def start_placement
      api
      prepare_quick_placement
      unless settings[:model_id] && database[:models].any? { |r| r[:id]==settings[:model_id] }
        show
        refresh(l('Dodaj lub wybierz uchwyt w bibliotece.','Add or select a handle in the library.'))
        return false
      end
      @click_tool=ClickTool.new
      Sketchup.active_model.select_tool(@click_tool)
      refresh(l('Kliknij front w modelu.','Click a front in the model.'))
      true
    rescue => error
      UI.messagebox(error.message)
      false
    end

    def start_removal
      api
      @click_tool=RemoveTool.new
      Sketchup.active_model.select_tool(@click_tool)
      refresh(l('Klikaj fronty, aby usunąć uchwyty ELFIS. Esc kończy.','Click fronts to remove their ELFIS handles. Esc exits.'))
      true
    rescue => error
      UI.messagebox(error.message)
      false
    end

    def show
      api
      return @dialog.bring_to_front if @dialog && @dialog.visible?
      @dialog=UI::HtmlDialog.new(dialog_title:'ELFIS — Handles Library',preferences_key:'ELFISHandles',scrollable:true,resizable:true,width:830,height:780,style:UI::HtmlDialog::STYLE_DIALOG)
      @dialog.set_file(File.join(__dir__,'library.html'))
      @dialog.add_action_callback('action') do |_,raw|
        begin
          request=JSON.parse(raw,symbolize_names:true)
          raise l('Dokończ kalibrację lub naciśnij Esc.','Complete calibration or press Esc first.') if @calibrating && !%w[ready refresh cancel_calibration].include?(request[:action])
          if request[:action]=='update'
            update_settings(request.fetch(:settings))
            next
          end
          settings.replace(config(request[:settings])) if request[:settings]
          persist if request[:settings]
          case request[:action]
          when 'ready','refresh' then refresh
          when 'import' then record_import;refresh
          when 'edit' then edit_record(settings[:model_id]);refresh
          when 'calibrate' then calibrate(settings[:model_id])
          when 'cancel_calibration' then Sketchup.active_model.select_tool(nil);refresh(l('Kalibracja anulowana.','Calibration cancelled.'))
          when 'delete'
            r=model_record(settings[:model_id])
            if UI.messagebox("Remove #{r[:name]} from the library? Existing handles will remain in the model.",MB_YESNO)==IDYES
              database[:models].delete(r);settings[:model_id]=database[:models].first&.dig(:id);persist
            end
        refresh
          when 'click' then model_record(settings[:model_id]);@click_tool=ClickTool.new;Sketchup.active_model.select_tool(@click_tool);refresh(l('Kliknij front w modelu.','Click a front in the model.'))
          when 'remove_click' then start_removal
          when 'selected','all' then n=batch(request[:action]);refresh("#{n} — OK")
          when 'copy'
            rows=order_rows
            text=([['Model','Type','Pitch mm','Length mm','Finish','Supplier','Code','Quantity']]+rows.map { |r| r.values_at(:name,:kind,:pitch,:length,:finish,:supplier,:code,:quantity) }).map { |r| r.map { |v| v.to_s.gsub(/[\t\r\n]/,' ') }.join("\t") }.join("\n")
            UI.set_clipboard_data(text);refresh(l('Skopiowano listę.','Order list copied.'))
          end
        rescue => error
          @dialog.execute_script("notice(#{JSON.generate(error.message)})") if @dialog
          warn "ELFIS Handles: #{error.full_message}"
        end
      end
      @dialog.set_on_closed { @dialog=nil }
      @dialog.show
    rescue => error
      UI.messagebox(error.message)
    end

    class ClickTool
      def activate
        @held={}
        @placement_override=nil
        @last_corner='tr'
        @side_cycle_distance=nil
        Handles.instance_variable_set(:@click_tool,self)
        Sketchup.set_status_text(Handles.l('Uchwyty: Ctrl — pion/poziom; Shift — lewo/prawo; Alt — góra/dół; Tab — narożnik/środek krawędzi. Pochwyty obracają się do krawędzi. Esc — zakończ.','Handles: Ctrl — vertical/horizontal; Shift — left/right; Alt — top/bottom; Tab — corner/edge centre. Edge pulls rotate to the edge. Esc — exit.'))
      end
      def chosen
        s=Handles.settings.dup;r=Handles.model_record(s[:model_id])
        s.merge!(@placement_override).merge!(preserve:false) if @placement_override
        s
      end
      def settings_changed
        @placement_override=nil
        @last_corner='tr'
        @side_cycle_distance=nil
        onMouseMove(0,*@xy,Sketchup.active_model.active_view) if @xy
      end
      def pick(x,y,view)
        ph=view.pick_helper;ph.do_pick(x,y)
        raise 'Point to a front component.' unless ph.count>0
        chain=ph.path_at(0)
        instances=chain.select { |e| Handles.api.instance?(e) }
        handle_index=instances.index { |e| Handles.handle?(e) }
        instances=instances.take(handle_index) if handle_index
        target=instances.find { |e| e.is_a?(Sketchup::ComponentInstance) && e.get_attribute('ElfisBastillePodmien','generated',false) }
        target||=instances.reverse.find { |e| e.is_a?(Sketchup::ComponentInstance) }
        raise 'Point to a front component, not a group.' unless target
        path=instances.take(instances.index(target)+1)
        normal=if !handle_index && ph.leaf_at(0).is_a?(Sketchup::Face)
          ph.leaf_at(0).normal.transform(ph.transformation_at(0)).transform(Sketchup.active_model.edit_transform)
        end
        [path,normal]
      end
      def onMouseMove(flags,x,y,view)
        @xy=[x,y];@path,@normal=pick(x,y,view)
        info=Handles.measure(@path.last,@path,@normal);s=Handles.resolved_settings(@path.last,chosen);r=Handles.model_record(s[:model_id])
        tr=info[:world_placement]*Handles.mount_transform(@path.last,info,r,s)
        definition=Handles.definition(Sketchup.active_model,r)
        @points=(0..7).map { |i| definition.bounds.corner(i).transform(tr) }
        @box=(0..7).map { |i| Handles.api.door_bounds(@path.last).corner(i).transform(info[:world]) }
        Handles.publish_preview(Handles.preview_payload(@path.last,info,r,s))
        position_names={'tl'=>'top left','tc'=>'top centre','tr'=>'top right','ml'=>'left centre','mr'=>'right centre','bl'=>'bottom left','bc'=>'bottom centre','br'=>'bottom right'}
        distance=r[:kind]=='edge' && %w[ml mr].include?(s[:position]) && s[:edge_layout]=='perimeter' ? "#{s[:side_shift].to_f} mm from centre" : "#{r[:kind]=='edge' ? s[:along] : (s[:offset_x] || s[:offset])} mm"
        Sketchup.set_status_text("ELFIS Handles — #{position_names[s[:position]]} · #{s[:orientation]} · #{distance} | Ctrl / Shift / Alt / Tab")
        view.tooltip=r[:name];view.invalidate
      rescue => error
        @points=@box=nil;Handles.publish_preview(nil);view.tooltip=error.message;view.invalidate
      end
      def draw(view)
        inverse=Sketchup.active_model.edit_transform.inverse
        [[@box,Sketchup::Color.new(25,145,220)],[@points,Sketchup::Color.new(40,190,90)]].each do |points,color|
          next unless points
          edges=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
          screen=points.map { |p| view.screen_coords(p.transform(inverse)) }
          view.drawing_color=color;view.line_width=3
          view.draw2d(GL_LINES,edges.flat_map { |a,b| [screen[a],screen[b]] })
        end
      end
      def onLButtonDown(flags,x,y,view)
        path,normal=pick(x,y,view);Handles.apply(path,chosen,normal)
        @points=@box=nil;view.invalidate
        Handles.refresh('OK — click another front.')
      rescue => error
        UI.messagebox(error.message)
      end
      def onKeyDown(key,repeat,flags,view)
        keys=[CONSTRAIN_MODIFIER_KEY,COPY_MODIFIER_KEY,ALT_MODIFIER_KEY,9]
        return unless keys.include?(key)
        unless @held[key]
          s=chosen
          edge=Handles.model_record(s[:model_id])[:kind]=='edge'
          p=s[:position];orientation=s[:orientation]
          # Retain old saved side-pull placement until the first explicit shortcut.
          p={'ml'=>'tl','mr'=>'tr'}.fetch(p,p) if edge && s[:edge_layout]!='perimeter'
          orientation='horizontal' if edge && %w[tc bc].include?(p)
          orientation='vertical' if edge && %w[ml mr].include?(p)
          @last_corner=p if %w[tl tr bl br].include?(p)
          if key==COPY_MODIFIER_KEY
            orientation=orientation=='horizontal' ? 'vertical' : 'horizontal'
            if edge
              p=orientation=='horizontal' ? "#{@last_corner[0]}c" : "m#{@last_corner[1]}" if %w[tc bc ml mr].include?(p)
            end
          elsif key==CONSTRAIN_MODIFIER_KEY
            if edge && orientation=='vertical'
              current=p.start_with?('m') ? s[:side_shift].to_f : 0.0
              @side_cycle_distance ||= current.abs>0.001 ? current.abs : 45.0
              side_shift=current.abs<0.001 ? @side_cycle_distance : current>0 ? -@side_cycle_distance : 0.0
              p="m#{p[-1]}"
            else
              p={'tl'=>'tr','tr'=>'tl','ml'=>'mr','mr'=>'ml','bl'=>'br','br'=>'bl'}.fetch(p,p)
            end
          elsif key==ALT_MODIFIER_KEY
            p=if edge && orientation=='vertical'
              {'tl'=>'tr','tr'=>'tl','ml'=>'mr','mr'=>'ml','bl'=>'br','br'=>'bl'}.fetch(p,p)
            else
              {'tl'=>'bl','bl'=>'tl','tc'=>'bc','bc'=>'tc','tr'=>'br','br'=>'tr'}.fetch(p,p)
            end
          elsif key==9
            p=if %w[tl tr bl br].include?(p)
              orientation=='horizontal' ? "#{p[0]}c" : "m#{p[1]}"
            else
              p.start_with?('m') ? "#{@last_corner[0]}#{p[1]}" : "#{p[0]}#{@last_corner[1]}"
            end
          end
          @last_corner=p if %w[tl tr bl br].include?(p)
          @last_corner="#{p[0]}#{@last_corner[1]}" if %w[tc bc].include?(p)
          @last_corner="#{@last_corner[0]}#{p[1]}" if %w[ml mr].include?(p)
          @placement_override=(@placement_override || {}).merge(position:p,orientation:orientation)
          @placement_override[:side_shift]=side_shift unless side_shift.nil?
          @placement_override[:edge_layout]='perimeter' if edge
        end
        @held[key]=true
        onMouseMove(flags,*@xy,view) if @xy
        true
      end
      def onKeyUp(key,repeat,flags,view)
        @held.delete(key)
        onMouseMove(flags,*@xy,view) if @xy
        true if [CONSTRAIN_MODIFIER_KEY,COPY_MODIFIER_KEY,ALT_MODIFIER_KEY,9].include?(key)
      end
      def onCancel(reason,view)
        @points=@box=nil;view.invalidate;Sketchup.active_model.select_tool(nil)
      end
      def deactivate(view)
        Handles.instance_variable_set(:@click_tool,nil)
        view.invalidate
      end
    end

    class RemoveTool < ClickTool
      def activate
        @held={}
        Handles.instance_variable_set(:@click_tool,self)
        Sketchup.set_status_text(Handles.l('ELFIS — kliknij front, aby usunąć uchwyt. Ctrl+Z: cofnij. Esc: zakończ.','ELFIS — click a front to remove its handle. Ctrl+Z: undo. Esc: exit.'))
      end
      def onMouseMove(flags,x,y,view)
        @xy=[x,y];@path,_=pick(x,y,view)
        info=Handles.measure(@path.last,@path)
        @box=nil
        @points=(0..7).map { |i| Handles.api.door_bounds(@path.last).corner(i).transform(info[:world]) }
        view.tooltip=Handles.l('Usuń uchwyty ELFIS','Remove ELFIS handles')+" (#{Handles.children(@path.last).length})"
        view.invalidate
      rescue => error
        @points=@box=nil;view.tooltip=error.message;view.invalidate
      end
      def draw(view)
        return unless @points
        inverse=Sketchup.active_model.edit_transform.inverse
        edges=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
        screen=@points.map { |p| view.screen_coords(p.transform(inverse)) }
        view.drawing_color=Sketchup::Color.new(205,70,60);view.line_width=3
        view.draw2d(GL_LINES,edges.flat_map { |a,b| [screen[a],screen[b]] })
      end
      def onLButtonDown(flags,x,y,view)
        path,_=pick(x,y,view)
        count=Handles.remove_from_front(path)
        Handles.refresh(Handles.l("Usunięto: #{count}. Kliknij kolejny front.","Removed: #{count}. Click another front."))
        onMouseMove(flags,x,y,view)
      rescue => error
        UI.messagebox(error.message)
      end
      def onKeyDown(key,repeat,flags,view);end
      def onKeyUp(key,repeat,flags,view);end
    end

    require File.join(__dir__,'calibration.rb')

    def install_toolbar
      return if @toolbar_layout=='quick-tools-1'
      @toolbar.hide if @toolbar
      # A distinct native name avoids merging with the legacy one-button bar
      # when updating code inside an already running SketchUp session.
      @toolbar=UI::Toolbar.new('ELFIS — Handle Tools')
      @toolbar_commands=[
        ['ELFIS — Add Handle','Dodaj uchwyt','Add handle','handle_add.svg',proc { start_placement }],
        ['ELFIS — Remove Handle','Usuń uchwyt','Remove handle','handle_remove.svg',proc { start_removal }],
        ['ELFIS — Handles Library','Biblioteka uchwytów','Handles Library','handle.svg',proc { show }]
      ].map do |name,pl,en,icon,action|
        command=UI::Command.new(name,&action)
        command.tooltip=l(pl,en)
        command.status_bar_text=l(pl,en)
        command.small_icon=command.large_icon=File.join(__dir__,icon)
        @toolbar.add_item(command)
        command
      end
      @toolbar_layout='quick-tools-1'
      @toolbar.restore
    end

    install_toolbar
    unless file_loaded?(__FILE__)
      @toolbar_commands.each { |command| UI.menu('Extensions').add_item(command) }
      UI.start_timer(0,false) { install_hooks if defined?(Elfis::BastillePodmienFront) }
      file_loaded(__FILE__)
    end
  end
end
