# encoding: UTF-8
require 'json'
require 'securerandom'
require 'fileutils'
require File.join(__dir__,'outline.rb')
require File.join(__dir__,'jpull.rb')
require File.join(__dir__,'performance.rb')
require File.join(__dir__,'onepiece.rb')
require File.join(__dir__,'families.rb')
module Elfis
  module BastillePodmienFront
    def library_path
      @library_path_override || File.join(ENV.fetch('APPDATA'), 'ELFIS','DoorProfileLibrary','profiles.json')
    end

    def library
      return @library if @library
      saved=File.file?(library_path) ? JSON.parse(File.read(library_path),symbolize_names:true) : {}
      bastille=JSON.parse(File.read(File.join(__dir__,'bastille.json')),symbolize_names:true)
      bastille.merge!(id:'bastille',name:'Bastille',kind:'shaker',panel:6.0,clearance:1.0,builtin:true)
      bastille.merge!(supplier:'OS Doors',catalogue_rules:'osdoors-bastille-2025',drawer_variant:{mode:'slab',min_height:100.0,max_height:215.0,min_width:240.0,thickness:22.0,edge_depth:20.0,frame_min:283.0,frame_max:2400.0,frame_width:240.0})
      slab={id:'slab-18',name:'Slab 18 mm',kind:'slab',thickness:18.0,builtin:true}
      jpull=default_jpull
      custom=Array(saved[:profiles]).reject { |p| ['bastille','slab-18','jpull-22','onepiece-demo'].include?(p[:id]) }
      custom.each { |p| p[:kind]||='shaker' }
      @library={profiles:[bastille,slab,jpull,default_onepiece]+custom,active:saved[:active]||'bastille',favorites:Array(saved[:favorites]),hidden_builtins:Array(saved[:hidden_builtins]),rename_doors:saved[:rename_doors]==true,variant_mode:saved[:variant_mode] || 'auto'}
      @library[:hidden_builtins].clear if visible_profiles.empty?
      @library[:active]=visible_profiles.first[:id] unless visible_profiles.any? { |p| p[:id]==@library[:active] }
      @library
    end

    def active_profile
      visible_profiles.find { |p| p[:id]==library[:active] } || visible_profiles.first
    end

    def visible_profiles
      data=@library || library
      data[:profiles].reject { |p| p[:builtin] && Array(data[:hidden_builtins]).include?(p[:id]) }
    end

    def remove_library_profile(id)
      p=visible_profiles.find { |v| v[:id]==id }
      raise Elfis::BastillePodmienFront.l('Nie znaleziono profilu.','Profile not found.') unless p
      raise Elfis::BastillePodmienFront.l('Pozostaw co najmniej jeden profil w bibliotece.','Keep at least one profile in the library.') if visible_profiles.length<=1
      previous=Marshal.load(Marshal.dump(library))
      if p[:builtin]
        (library[:hidden_builtins]||=[])<<id
      else
        library[:profiles].reject! { |v| v[:id]==id }
      end
      library[:favorites].delete(id)
      library[:active]=visible_profiles.first[:id] if library[:active]==id
      persist_library
      true
    rescue
      @library=previous if previous
      raise
    end

    def confirm_remove_library_profile(id)
      p=visible_profiles.find { |v| v[:id]==id }
      raise Elfis::BastillePodmienFront.l('Nie znaleziono profilu.','Profile not found.') unless p
      verb=p[:builtin] ? Elfis::BastillePodmienFront.l('Ukryć profil wbudowany','Hide built-in profile') : Elfis::BastillePodmienFront.l('Usunąć profil','Delete profile')
      detail=p[:builtin] ? Elfis::BastillePodmienFront.l('Możesz go przywrócić przyciskiem „Przywróć wbudowane”.','You can restore it using Restore built-in profiles.') : Elfis::BastillePodmienFront.l('Profil zostanie usunięty z biblioteki.','The profile will be removed from the library.')
      answer=UI.messagebox(Elfis::BastillePodmienFront.l("#{verb} „#{p[:name]}”?\n\n#{detail}\nDrzwi już utworzone w projekcie pozostaną bez zmian.","#{verb} „#{p[:name]}”?\n\n#{detail}\nDoors already created in the project will remain unchanged."),MB_YESNO)
      answer==IDYES ? remove_library_profile(id) : false
    end

    def restore_builtin_profiles
      previous=Array(library[:hidden_builtins]).dup
      library[:hidden_builtins]=[]
      persist_library
    rescue
      library[:hidden_builtins]=previous if previous
      raise
    end

    def persist_library
      FileUtils.mkdir_p(File.dirname(library_path))
      temporary="#{library_path}.#{SecureRandom.hex(4)}.tmp"
      File.write(temporary,JSON.pretty_generate(library))
      File.rename(temporary,library_path)
      update_profile_command
    end

    def update_profile_command
      p=active_profile
      dimensions=p[:kind]=='shaker' || !p[:kind] ? "#{p[:width]} × #{p[:thickness]} mm" : "#{p[:thickness]} mm"
      @command.tooltip=Elfis::BastillePodmienFront.l("#{p[:name]} — #{dimensions}: kliknij front","#{p[:name]} — #{dimensions}: click a front") if @command
    end

    def select_profile(id)
      raise Elfis::BastillePodmienFront.l('Nie znaleziono profilu.','Profile not found.') unless visible_profiles.any? { |p| p[:id]==id }
      library[:active]=id
      persist_library
    end

    def rename_doors?
      library[:rename_doors]==true
    end

    def set_naming_mode(rename)
      library[:rename_doors]=rename==true
      persist_library
      Sketchup.set_status_text(rename_doors? ? Elfis::BastillePodmienFront.l('ELFIS: zmieniaj nazwy drzwi na profil i rozmiar.','ELFIS: rename doors using profile and size.') : Elfis::BastillePodmienFront.l('ELFIS: zachowuj oryginalne nazwy drzwi.','ELFIS: keep original door names.'))
    end

    def install_naming_menu
      return if @naming_menu
      @naming_menu=UI.menu('Extensions').add_submenu('ELFIS — Door Naming / Nazwy drzwi')
      @rename_command=UI::Command.new(l('Zmień nazwy drzwi','Rename doors')) { set_naming_mode(true) }
      @keep_names_command=UI::Command.new(l('Pozostaw nazwy drzwi','Keep original door names')) { set_naming_mode(false) }
      @rename_command.set_validation_proc { rename_doors? ? MF_CHECKED : MF_UNCHECKED }
      @keep_names_command.set_validation_proc { rename_doors? ? MF_UNCHECKED : MF_CHECKED }
      @naming_menu.add_item(@rename_command)
      @naming_menu.add_item(@keep_names_command)
    end

    def validate_profile(p)
      p[:kind]||='shaker'
      return p if p[:kind]=='drawer_section' && p[:family_resolved] && p[:drawer_section]
      p=validate_family(p)
      raise Elfis::BastillePodmienFront.l('Nieznany typ drzwi.','Unknown door type.') unless ['shaker','onepiece','slab','jpull'].include?(p[:kind])
      return validate_onepiece(p) if p[:kind]=='onepiece'
      return validate_jpull(p) if p[:kind]=='jpull'
      if p[:kind]=='slab'
        p[:thickness]=Float(p.fetch(:thickness))
        p[:front_chamfer]=Float(p.fetch(:front_chamfer,0))
        raise Elfis::BastillePodmienFront.l('Grubość slab musi wynosić od 0.1 do 80 mm.','Slab thickness must be greater than 0.1 mm and at most 80 mm.') unless p[:thickness].finite? && p[:thickness]>0.1 && p[:thickness]<=80
        raise l('Faza musi wynosić 0 albo co najmniej 0.1 mm i być mniejsza od grubości.','Chamfer must be 0 or at least 0.1 mm and smaller than the thickness.') unless p[:front_chamfer].finite? && (p[:front_chamfer]==0 || p[:front_chamfer]>=0.1) && p[:front_chamfer]<p[:thickness]
        return p
      end
      [:width,:thickness,:shoulder,:panel,:clearance].each do |key|
        value=Float(p.fetch(key))
        raise Elfis::BastillePodmienFront.l('Wpisz prawidłowe wymiary.','Enter valid dimensions.') unless value.finite?
        p[key]=value
      end
      raise Elfis::BastillePodmienFront.l('Nieprawidłowy przekrój.','Invalid cross-section.') unless p[:width]>p[:thickness] && p[:thickness]>0 && p[:shoulder]>0 && p[:shoulder]<=p[:width]
      raise Elfis::BastillePodmienFront.l('Nieprawidłowy luz lub grubość płyciny.','Invalid panel clearance or thickness.') unless p[:clearance]>=0 && p[:panel]>=0
      if p[:panel]>0
        g=p[:groove]
        raise Elfis::BastillePodmienFront.l('Brak prostokątnego rowka. Ustaw płycinę na 0 mm.','No rectangular groove. Set panel thickness to 0 mm.') unless g
        raise Elfis::BastillePodmienFront.l('Płycina jest za gruba do rowka.','The panel is too thick for the groove.') unless p[:panel]<g[:high]-g[:low]
        raise Elfis::BastillePodmienFront.l('Luz wysuwa płycinę z rowka.','The clearance moves the panel out of the groove.') unless g[:floor]+p[:clearance]<p[:width]
      end
      p
    end

    def add_selected_profile
      raw=ProfileOutline.normalize(ProfileOutline.selected_outline(Sketchup.active_model))
      raw.merge!(id:SecureRandom.uuid,name:'Nowy profil',panel:raw[:groove] ? [6.0,(raw[:groove][:high]-raw[:groove][:low])*0.8].min : 0.0,clearance:raw[:groove] ? [1.0,(raw[:width]-raw[:groove][:floor])*0.25].min : 1.0,builtin:false)
      raw[:draft]=true
      raw[:kind]='shaker'
      @draft_profile=raw
      raw
    end

    def add_slab_profile
      @draft_profile={id:SecureRandom.uuid,name:'Nowy slab',kind:'slab',thickness:18.0,builtin:false,draft:true}
    end

    def save_profile_settings(data)
      candidate=data[:id]==@draft_profile&.dig(:id) ? @draft_profile.dup : library[:profiles].find { |p| p[:id]==data[:id] }&.dup
      raise Elfis::BastillePodmienFront.l('Nie znaleziono profilu.','Profile not found.') unless candidate
      candidate[:name]=data.fetch(:name)
      candidate[:supplier]=supplier_name(data[:supplier] || candidate[:supplier])
      if data.key?(:drawer_variant)
        candidate[:drawer_variant]=data[:drawer_variant]
        candidate.delete(:catalogue_rules)
      end
      if ['shaker','onepiece'].include?(candidate[:kind]) && data[:kind]
        raise Elfis::BastillePodmienFront.l('Wybierz Five-Piece Door albo One-Piece Door.','Choose Five-Piece Door or One-Piece Door.') unless ['shaker','onepiece'].include?(data[:kind])
        candidate[:kind]=data[:kind]
      end
      if candidate[:kind]=='jpull'
        candidate[:thickness]=data.fetch(:thickness) unless candidate[:source]=='custom'
        [:handle_edge,:cavity,:lip,:radius].each { |k| candidate[k]=data.fetch(k) }
        candidate[:flip_front]=data[:flip_front]==true
        candidate[:flip_end]=data[:flip_end]==true
      elsif candidate[:kind]=='slab'
        candidate[:thickness]=data.fetch(:thickness)
        candidate[:front_chamfer]=data.fetch(:front_chamfer,candidate.fetch(:front_chamfer,0))
      elsif candidate[:kind]=='shaker'
        [:shoulder,:panel,:clearance].each { |k| candidate[k]=data.fetch(k) }
      end
      candidate[:name]=candidate[:name].to_s.strip[0,80]
      raise Elfis::BastillePodmienFront.l('Podaj nazwę profilu.','Enter a profile name.') if candidate[:name].empty?
      candidate.delete(:draft)
      candidate=validate_profile(candidate)
      # Keep the bundled Bastille immutable; edits become a custom profile.
      if candidate[:builtin]
        candidate[:id]=SecureRandom.uuid
        candidate[:builtin]=false
      end
      library[:profiles].reject! { |p| p[:id]==candidate[:id] }
      library[:profiles]<<candidate
      library[:active]=candidate[:id]
      @draft_profile=nil
      persist_library
      candidate
    end

    def build_door_definition(model,p,width,height)
      p=resolve_family_profile(p,width,height)
      definition=cached_door_definition(model,p,width,height) { build_door_definition_uncached(model,p,width,height) }
      # Keep visible door geometry in the front component's own coordinates.
      # OpenCutList can then rotate inherited grain using its native axes tool.
      # Store original part names on faces/edges for identification; user CNC
      # and handle groups are added later and are never exploded here.
      definition.entities.grep(Sketchup::Group).each do |part|
        name=part.name
        part.entities.each { |entity| entity.set_attribute('ElfisDoorPart','name',name) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }
        part.explode
      end
      definition.entities.each { |entity| entity.set_attribute('ElfisBastillePodmien','geometry',true) if entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }
      definition
    end

    def build_door_definition_uncached(model,p,width,height)
      raise Elfis::BastillePodmienFront.l('Wymiary muszą być dodatnie.','Dimensions must be positive.') unless [width,height].all? { |n| n.finite? && n>0 }
      if p[:kind]=='drawer_section'
        d=build_drawer_section(model,p,width,height)
      elsif p[:kind]=='jpull'
        d=build_jpull(model,p,width,height)
      elsif p[:kind]=='onepiece'
        d=build_onepiece(model,p,width,height)
      elsif p[:kind]=='slab'
        raise Elfis::BastillePodmienFront.l('Szerokość i wysokość slab muszą być większe niż jego grubość.','Slab width and height must exceed its thickness.') unless [width,height].min>p[:thickness]
        d=model.definitions.add("Slab #{height}x#{width}")
        body=d.entities.add_group
        body.name='Płyta slab'
        chamfer=p.fetch(:front_chamfer,0).to_f
        raise l('Front jest za mały dla wybranej fazy.','The front is too small for this chamfer.') unless [width,height].min>2*chamfer
        if chamfer>0
          build_chamfered_slab(body,width,height,p[:thickness],chamfer)
        else
          f=body.entities.add_face([[0,0,0],[width.mm,0,0],[width.mm,0,height.mm],[0,0,height.mm]])
          f.reverse! if f.normal.y<0
          f.pushpull(p[:thickness].mm)
        end
        raise Elfis::BastillePodmienFront.l('Nie udało się utworzyć bryły slab.','Could not create a solid slab.') unless solid?(body)
      else
        d=build(model,p,width,height,p[:shoulder],p[:panel],p[:clearance])
      end
      d.entities.each { |g| g.set_attribute('ElfisBastillePodmien','geometry',true) if instance?(g) }
      d
    end

    def adopt_native_door_axes(door)
      # Native board convention: X/Y span the face, Z is the thickness.
      # Start with X along physical height; OCL owns all later axis changes.
      axes=Geom::Transformation.axes(ORIGIN,Z_AXIS,X_AXIS,Y_AXIS)
      door.definition.entities.transform_entities(axes.inverse,door.definition.entities.to_a)
      door.transformation=door.transformation*axes
      door.definition.invalidate_bounds
    end

    def stamp_door(door,p,width,height)
      door.set_attribute('ElfisBastillePodmien','generated',true)
      door.set_attribute('ElfisBastillePodmien','profile_id',p[:id])
      door.set_attribute('ElfisBastillePodmien','profile_name',p[:name]) if p[:name]
      door.set_attribute('ElfisBastillePodmien','profile_geometry',geometry_cache_key(p,0,0))
      door.set_attribute('ElfisBastillePodmien','kind',p[:kind]||'shaker')
      door.set_attribute('ElfisBastillePodmien','supplier',supplier_name(p[:supplier]))
      door.set_attribute('ElfisBastillePodmien','family_name',p[:family_name] || p[:name])
      door.set_attribute('ElfisBastillePodmien','variant',p[:variant] || 'standard')
      door.set_attribute('ElfisBastillePodmien','width_mm',width)
      door.set_attribute('ElfisBastillePodmien','height_mm',height)
      door.set_attribute('ElfisBastillePodmien','thickness_mm',p[:thickness])
      door.set_attribute('ElfisBastillePodmien','handle_edge',p[:handle_edge]) if p[:kind]=='jpull'
      door.set_attribute('ElfisBastillePodmien','front_chamfer_mm',p.fetch(:front_chamfer,0)) if p[:kind]=='slab'
    end

    def door_dimension_label(value)
      format('%.2f',value).sub(/\.?0+\z/,'')
    end

    # Return the requested base; SketchUp assigns any necessary unique suffix.
    def next_door_name(model,p,height,width,exclude=nil)
      "#{p[:name]} #{door_dimension_label(height)}x#{door_dimension_label(width)}"
    end

    def assign_door_name(model,door,name)
      # One direct lookup handles an unused definition left by an older version.
      # Live conflicts are resolved by SketchUp's native name setter.
      definition=model.definitions[name]
      if definition && definition!=door.definition && definition.instances.empty?
        definition.name="#{name} [unused #{SecureRandom.uuid}]"
      end
      door.definition.name=name
      actual=door.definition.name
      unless actual==name || actual.start_with?("#{name} #")
        # SU 2026 may treat the trailing dimension digits as a name counter:
        # "715x596" becomes "715x#1". Preserve the base with direct lookups.
        number=actual[/#(\d+)\z/,1].to_i
        number=1 if number<1
        loop do
          candidate="#{name} ##{number}"
          occupied=model.definitions[candidate]
          if !occupied || occupied==door.definition || occupied.instances.empty?
            occupied.name="#{candidate} [unused #{SecureRandom.uuid}]" if occupied && occupied!=door.definition
            door.definition.name=candidate
            break
          end
          number+=1
        end
      end
      door.name=door.definition.name
    end

    def preserve_door_name(door,instance_name,original_definition,definition_name)
      # Only touch the replaced definition. No model-wide name lookup here.
      if original_definition.valid? && original_definition.instances.empty?
        original_definition.name="#{definition_name} [unused #{SecureRandom.uuid}]"
      end
      # Shared definitions require a unique definition name in SketchUp, while
      # each replacement instance can retain its exact original instance name.
      door.definition.name=definition_name
      door.name=instance_name
    end

    def create_with_dimensions(height,width)
      p=validate_profile(active_profile.dup)
      height,width=Float(height),Float(width)
      raise Elfis::BastillePodmienFront.l('Podaj dodatnie, skończone wymiary w mm.','Enter positive, finite dimensions in mm.') unless [height,width].all? { |n| n.finite? && n>0 }
      p=resolve_family_profile(p,width,height)
      m=Sketchup.active_model
      session=performance_session(m)
      session.internal_depth+=1
      m.start_operation('ELFIS — drzwi z biblioteki',true)
      begin
        name=next_door_name(m,p,height,width)
        d=build_door_definition(m,p,width,height)
        door=m.active_entities.add_instance(d,IDENTITY)
        assign_door_name(m,door,name)
        stamp_door(door,p,width,height)
        adopt_native_door_axes(door)
        m.selection.clear
        m.selection.add(door)
        m.commit_operation
        door
      rescue
        m.abort_operation
        session.changed(true)
        raise
      ensure
        session.internal_depth-=1
      end
    end

    def library_state
      {profiles:visible_profiles,active:library[:active],favorites:library[:favorites],draft:@draft_profile,hidden_builtin_count:Array(library[:hidden_builtins]).length,suppliers:supplier_options,variant_mode:library[:variant_mode] || 'auto'}
    end

    def push_library
      @library_dialog.execute_script("renderLibrary(#{JSON.generate(library_state)})") if @library_dialog
    end

    def show_library
      if @library_dialog && @library_dialog.visible?
        @library_dialog.bring_to_front
        push_library
        return
      end
      @library_dialog=UI::HtmlDialog.new(dialog_title:Elfis::BastillePodmienFront.l('ELFIS — Biblioteka profili drzwi','ELFIS — Door Profile Library'),preferences_key:'ElfisDoorProfilePicker',width:930,height:900,min_width:740,min_height:560,resizable:true)
      @library_dialog.set_file(localized_html('library'))
      @library_dialog.add_action_callback('library_action') do |_,json|
        begin
          data=JSON.parse(json,symbolize_names:true)
          case data[:action]
          when 'language' then change_language(data[:language],:library)
          when 'ready' then push_library
          when 'select' then select_profile(data[:id]); push_library
          when 'delete' then confirm_remove_library_profile(data[:id]); push_library
          when 'restore_builtins' then restore_builtin_profiles; push_library
          when 'favorite'
            id=data[:id]
            raise Elfis::BastillePodmienFront.l('Nie znaleziono profilu.','Profile not found.') unless library[:profiles].any? { |p| p[:id]==id }
            library[:favorites].include?(id) ? library[:favorites].delete(id) : library[:favorites]<<id
            persist_library
            push_library
          when 'add' then add_selected_profile; push_library
          when 'add_onepiece' then add_selected_onepiece; push_library
          when 'add_slab' then add_slab_profile; push_library
          when 'add_jpull' then add_jpull_profile; push_library
          when 'import_jpull' then import_jpull_section(data); push_library
          when 'import_drawer' then import_drawer_section(data); push_library
          when 'cancel_draft' then @draft_profile=nil; push_library
          when 'save' then save_profile_settings(data); push_library
          when 'replace'
            library[:variant_mode]=%w[auto frame drawer].include?(data[:variant_mode]) ? data[:variant_mode] : 'auto'
            select_profile(data[:id])
            @library_dialog.close
            activate
          when 'create'
            library[:variant_mode]=%w[auto frame drawer].include?(data[:variant_mode]) ? data[:variant_mode] : 'auto'
            select_profile(data[:id])
            create_with_dimensions(data[:height],data[:width])
            @library_dialog.close
          else raise Elfis::BastillePodmienFront.l('Nieznane polecenie.','Unknown command.')
          end
        rescue => e
          @library_dialog.execute_script("showError(#{JSON.generate(e.message)})") if @library_dialog
        end
      end
      dialog=@library_dialog
      dialog.set_on_closed { @library_dialog=nil if @library_dialog.equal?(dialog) }
      @library_dialog.center
      @library_dialog.show
    end
  end
end
