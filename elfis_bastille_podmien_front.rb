# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require File.join(__dir__,'elfis_bastille_podmien_front','i18n.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','engine.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','library.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','order_stock.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','order_list.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','slab_materials.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','order_pdf.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','feedback.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','shelf_pins.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','carcass_joinery.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','studio_settings.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','drilling_editor.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','drilling_refresh.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','hanger_cutouts.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','hinge_drilling.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','drawer_drilling.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','shelf_spacing.rb')

module Elfis
  module BastillePodmienFront
    extend self
    LABEL='Bastille — Zamień kliknięty front' unless const_defined?(:LABEL)

    def profile
      active_profile
    end

    def instance?(object)
      object.is_a?(Sketchup::Group) || object.is_a?(Sketchup::ComponentInstance)
    end

    # All lengths are measured in world space, including the open edit context.
    # New geometry remains in the same active context as the clicked instance.
    def measure(instance,model,front_normal=nil,path=nil,p=profile,bounds_override=nil)
      raise Elfis::BastillePodmienFront.l('Wskaż komponent frontu.','Point to a front component.') unless instance?(instance) && instance.valid?
      raise Elfis::BastillePodmienFront.l('Front jest zablokowany.','The front is locked.') if instance.locked?
      path ||= [instance]
      raise Elfis::BastillePodmienFront.l('Nieprawidłowa ścieżka komponentu.','Invalid component path.') unless path.last==instance && model.active_entities.include?(path.first)
      path.each_with_index do |parent,i|
        raise Elfis::BastillePodmienFront.l('Szafka lub front jest zablokowany.','The cabinet or front is locked.') if parent.locked?
        raise Elfis::BastillePodmienFront.l('Nieprawidłowa ścieżka komponentu.','Invalid component path.') if i>0 && !path[i-1].definition.entities.include?(parent)
      end
      raise Elfis::BastillePodmienFront.l('Otwarta szafka ma wiele kopii. Najpierw wybierz Utwórz unikatowy / Make Unique dla szafki.','The open cabinet has multiple instances. Make the cabinet unique first.') if model.active_path && model.active_path.any? { |parent| parent.definition.instances.length>1 }
      bounds=bounds_override || door_bounds(instance)
      local_lengths=[bounds.width,bounds.height,bounds.depth]
      parent_world=path[0...-1].inject(model.edit_transform) { |tr,parent| tr*parent.transformation }
      world=parent_world * instance.transformation
      world_origin=ORIGIN.transform(world)
      axes=[[1,0,0],[0,1,0],[0,0,1]].map { |p| Geom::Point3d.new(p).transform(world)-world_origin }
      scales=axes.map(&:length)
      raise Elfis::BastillePodmienFront.l('Obiekt ma zerową skalę.','The object has zero scale.') unless scales.all? { |s| s>0.000001 }
      directions=axes.map(&:normalize)
      raise Elfis::BastillePodmienFront.l('Front jest ukośnie zdeformowany. Użyj prostokątnego komponentu.','The front is sheared. Use a rectangular component.') unless [directions[0].dot(directions[1]),directions[0].dot(directions[2]),directions[1].dot(directions[2])].all? { |v| v.abs<0.0001 }
      physical=local_lengths.each_with_index.map { |length,i| (length*scales[i]).to_mm }
      depth_axis=(0..2).min_by { |i| physical[i] }
      face_axes=(0..2).to_a-[depth_axis]
      height_axis=face_axes.max_by { |i| directions[i].dot(Z_AXIS).abs }
      height_axis=face_axes.max_by { |i| physical[i] } if directions[height_axis].dot(Z_AXIS).abs<0.7
      width_axis=(face_axes-[height_axis]).first
      width,height=physical[width_axis],physical[height_axis]
      p=resolve_family_profile(p,width,height)
      raise Elfis::BastillePodmienFront.l('Wskaż płaski front, nie całą szafkę. W razie potrzeby wejdź w jej edycję.','Point to a flat front, not the whole cabinet. Enter its editing context if needed.') unless physical[depth_axis]>0.1 && physical[depth_axis]<=80.0
      if p[:kind]=='jpull'
        span=%w[top bottom].include?(p[:handle_edge]) ? height : width
        raise Elfis::BastillePodmienFront.l('Front jest za krótki dla wnęki J-pull.','The front is too short for the J-pull recess.') unless span>2*p[:cavity]
        raise Elfis::BastillePodmienFront.l('Front jest za mały dla tej grubości.','The front is too small for this thickness.') unless [width,height].min>p[:thickness]
      elsif %w[slab drawer_section].include?(p[:kind])
        raise Elfis::BastillePodmienFront.l('Front jest za mały dla tej grubości slab.','The front is too small for this slab thickness.') unless [width,height].min>p[:thickness]
      elsif p[:kind]=='onepiece'
        validate_onepiece_dimensions(p,width,height)
      else
        raise Elfis::BastillePodmienFront.l("Front jest za mały dla profilu #{p[:name]} (#{p[:width]} mm).","The front is too small for profile #{p[:name]} (#{p[:width]} mm).") unless width>2*p[:width] && height>2*p[:width]
      end
      sign_h=directions[height_axis].dot(Z_AXIS)<-0.001 ? -1.0 : 1.0
      sign_d=1.0
      if !instance.get_attribute('ElfisBastillePodmien','generated',false) && front_normal && front_normal.valid?
        dot=front_normal.normalize.dot(directions[depth_axis])
        sign_d=dot<0 ? -1.0 : 1.0 if dot.abs>0.7
      end
      low,high=bounds.min.to_a,bounds.max.to_a
      origin=low.dup
      origin[height_axis]=sign_h>0 ? low[height_axis] : high[height_axis]
      # Anchor the cabinet-facing back plane. Extra thickness grows outward,
      # keeping the original rear machining vectors on the back surface.
      origin[depth_axis]=sign_d>0 ? low[depth_axis] : high[depth_axis]
      unit=[X_AXIS,Y_AXIS,Z_AXIS]
      vector=->(axis,sign) { v=unit[axis].clone; v.length=1.0/scales[axis]; sign<0 ? v.reverse : v }
      u=vector.call(width_axis,1.0).to_a
      v=vector.call(depth_axis,sign_d).to_a
      h=vector.call(height_axis,sign_h).to_a
      mapping=Geom::Transformation.new([*u,0.0,*v,0.0,*h,0.0,*origin,1.0])
      {width:width,height:height,profile:p,source_thickness:physical[depth_axis],placement:instance.transformation*mapping,axes:[width_axis,depth_axis,height_axis],front_sign:sign_d,world:world,world_placement:world*mapping}
    end

    def own_geometry?(entity,source)
      return true if entity.get_attribute('ElfisBastillePodmien','geometry',false)
      # Compatibility with doors made by versions 1.x and 2.0.
      return false unless source.get_attribute('ElfisBastillePodmien','generated',false)
      entity.is_a?(Sketchup::Group) && solid?(entity) &&
        (['Ramiak lewy','Ramiak prawy','Poprzeczka dolna','Poprzeczka górna'].include?(entity.name) || entity.name.start_with?('Płycina '))
    end

    def door_bounds(source)
      generated=source.definition.entities.select { |e| (instance?(e) || e.is_a?(Sketchup::Face)) && own_geometry?(e,source) }
      return source.definition.bounds if generated.empty?
      bb=Geom::BoundingBox.new
      generated.each { |g| bb.add(g.bounds) }
      bb
    end

    def machining_containers(source,entities=source.definition.entities,transform=IDENTITY)
      entities.flat_map do |child|
        next [] unless instance?(child)
        tr=transform*child.transformation
        own_geometry?(child,source) ? machining_containers(source,child.definition.entities,tr) : [[child,tr]]
      end
    end

    # Isolate copied cabinets along the clicked path before editing their contents.
    def unique_path(path)
      tokens=path.each_with_index.map do |child,i|
        token="#{object_id}-#{Time.now.to_f}-#{i}"
        child.set_attribute('ElfisBastilleTemp','path',token) if i>0
        token
      end
      result=[path.first]
      (1...path.length).each do |i|
        parent=result.last
        parent.make_unique if parent.definition.instances.length>1
        child=parent.definition.entities.find { |e| e.get_attribute('ElfisBastilleTemp','path')==tokens[i] }
        raise Elfis::BastillePodmienFront.l('Nie udało się odszukać frontu po utworzeniu kopii szafki.','Could not locate the front after making the cabinet unique.') unless child
        result << child
      end
      result
    ensure
      (path+Array(result)).uniq.each { |e| e.delete_attribute('ElfisBastilleTemp','path') if e.valid? }
    end

    # Retain nested machining containers in the source coordinate system.
    # No depth offset is guessed when replacing an 18 mm panel with 22 mm doors.
    def copy_instance_properties(source,target)
      target.name=source.name
      target.layer=source.layer
      target.material=source.material
      target.hidden=source.hidden?
      target.casts_shadows=source.casts_shadows?
      target.receives_shadows=source.receives_shadows?
      if source.attribute_dictionaries
        source.attribute_dictionaries.each do |dictionary|
          dictionary.each_pair { |key,value| target.set_attribute(dictionary.name,key,value) }
        end
      end
      target.locked=source.locked?
    end

    def preserve_nested_entities(source,replacement)
      # source-local -> parent -> replacement-local, including scale and mirroring.
      mapping=replacement.transformation.inverse*source.transformation
      children=machining_containers(source)
      children.each do |child,relative_transform|
        transform=mapping*relative_transform
        if child.is_a?(Sketchup::Group)
          copy=replacement.definition.entities.add_group
          copy.entities.add_instance(child.definition,IDENTITY).explode
          copy.transformation=transform
        else
          copy=replacement.definition.entities.add_instance(child.definition,transform)
        end
        copy_instance_properties(child,copy)
      end
      replacement.set_attribute('ElfisBastillePodmien','preserved_containers',children.length)
      children.length
    end

    def replace(instance,model=Sketchup.active_model,front_normal=nil,path=nil,p=profile,operation:true,select:true,bounds_override:nil)
      path ||= [instance]
      p=validate_profile(p.dup)
      info=measure(instance,model,front_normal,path,p,bounds_override)
      p=info[:profile]
      session=performance_session(model)
      change_name=rename_doors?
      session.internal_depth+=1
      model.start_operation('Bastille — zamień front',true) if operation
      begin
        path=unique_path(path)
        instance=path.last
        owner=path.length>1 ? path[-2].definition.entities : model.active_entities
        original_name=instance.name
        original_definition=instance.definition
        original_definition_name=original_definition.name
        name=next_door_name(model,p,info[:height],info[:width],instance) if change_name
        definition=build_door_definition(model,p,info[:width],info[:height])
        replacement=owner.add_instance(definition,info[:placement])
        replacement.layer=instance.layer
        replacement.material=instance.material
        replacement.hidden=instance.hidden?
        replacement.casts_shadows=instance.casts_shadows?
        replacement.receives_shadows=instance.receives_shadows?
        stamp_door(replacement,p,info[:width],info[:height])
        preserve_slab_materials(instance,replacement,info) if p[:kind]=='slab'
        replacement.set_attribute('ElfisBastillePodmien','source_name',instance.name)
        replacement.set_attribute('ElfisBastillePodmien','width_mm',info[:width])
        replacement.set_attribute('ElfisBastillePodmien','height_mm',info[:height])
        replacement.set_attribute('ElfisBastillePodmien','profile_id',p[:id])
        preserve_nested_entities(instance,replacement)
        adopt_native_door_axes(replacement)
        # Do not change the source definition: other instances remain intact.
        instance.erase!
        if change_name
          if original_definition.valid? && original_definition.instances.empty?
            original_definition.name="#{original_definition_name} [unused #{SecureRandom.uuid}]"
          end
          assign_door_name(model,replacement,name)
        else
          preserve_door_name(replacement,original_name,original_definition,original_definition_name)
        end
        if select
          model.selection.clear
          model.selection.add(path.length>1 ? path.first : replacement)
        end
        model.commit_operation if operation
        replacement
      rescue => error
        model.abort_operation if operation
        session.changed(true)
        raise error
      ensure
        session.internal_depth-=1
      end
    end

    class ClickTool
      def modifier_keys
        {CONSTRAIN_MODIFIER_KEY=>CONSTRAIN_MODIFIER_MASK,COPY_MODIFIER_KEY=>COPY_MODIFIER_MASK,ALT_MODIFIER_KEY=>ALT_MODIFIER_MASK}
      end

      def effective_profile(flags=0)
        p=BastillePodmienFront.profile.dup
        return p unless p[:kind]=='jpull'
        edge=if (flags & CONSTRAIN_MODIFIER_MASK)!=0 then 'bottom'
        elsif (flags & COPY_MODIFIER_MASK)!=0 then 'left'
        elsif (flags & ALT_MODIFIER_MASK)!=0 then 'right'
        else p[:handle_edge]
        end
        p.merge(handle_edge:edge)
      end

      def edge_label(p)
        return '' unless p[:kind]=='jpull'
        Elfis::BastillePodmienFront.l(" · uchwyt: #{ {'top'=>'góra','bottom'=>'dół','left'=>'lewa','right'=>'prawa'}[p[:handle_edge]] }"," · handle: #{ {'top'=>'top','bottom'=>'bottom','left'=>'left','right'=>'right'}[p[:handle_edge]] }")
      end

      def onKeyDown(key,repeat,flags,view)
        return false unless BastillePodmienFront.profile[:kind]=='jpull' && modifier_keys.key?(key)
        (@held_modifiers||={})[key]=true
        refresh_modifier_preview(view)
        true # Prevent Alt from focusing the Windows menu.
      end

      def onKeyUp(key,repeat,flags,view)
        return false unless BastillePodmienFront.profile[:kind]=='jpull' && modifier_keys.key?(key)
        (@held_modifiers||={}).delete(key)
        refresh_modifier_preview(view)
        true
      end

      def refresh_modifier_preview(view)
        # SketchUp 2026 keyboard-event flags are unreliable. Track the key itself.
        flags=(@held_modifiers||{}).keys.inject(0) { |mask,key| mask|modifier_keys.fetch(key) }
        onMouseMove(flags,@x,@y,view) if @x && @y
      end

      def activate
        @held_modifiers={}
        p=BastillePodmienFront.profile
        hint=p[:kind]=='jpull' ? Elfis::BastillePodmienFront.l(' Shift: dół · Ctrl: lewa · Alt: prawa.',' Shift: bottom · Ctrl: left · Alt: right.') : ''
        Sketchup.set_status_text(Elfis::BastillePodmienFront.l("#{p[:name]} — #{p[:thickness]} mm: kliknij front, aby zmienić styl.#{hint} Ctrl+Z cofa. Esc kończy.","#{p[:name]} — #{p[:thickness]} mm: click a front to change its style.#{hint} Ctrl+Z undoes. Esc exits."))
      end

      def pick(x,y,view,p=BastillePodmienFront.profile)
        helper=view.pick_helper
        helper.do_pick(x,y)
        raise Elfis::BastillePodmienFront.l('Wskaż komponent frontu.','Point to a front component.') unless helper.count>0
        picked_path=helper.path_at(0)
        instances=picked_path.select { |e| BastillePodmienFront.instance?(e) }
        target=instances.find { |e| e.is_a?(Sketchup::ComponentInstance) && e.get_attribute('ElfisBastillePodmien','generated',false) }
        target ||= instances.reverse.find { |e| e.is_a?(Sketchup::ComponentInstance) }
        raise Elfis::BastillePodmienFront.l('Wskaż komponent frontu, nie grupę.','Point to a front component, not a group.') unless target
        path=instances.take(instances.index(target)+1)
        normal=nil
        if helper.count>0 && helper.leaf_at(0).is_a?(Sketchup::Face)
          n=helper.leaf_at(0).normal.transform(helper.transformation_at(0))
          normal=n.transform(Sketchup.active_model.edit_transform)
        end
        model=Sketchup.active_model
        signature=[BastillePodmienFront.performance_session(model).revision,path,normal&.to_a,p]
        if @hover_pick && signature==@hover_signature && @hover_info
          info=@hover_info
        else
          info=BastillePodmienFront.measure(target,model,normal,path,p)
          @hover_signature=signature
          @hover_info=info
        end
        [target,info,normal,path]
      end

      def onMouseMove(flags,x,y,view)
        @x,@y=x,y
        previous=[@target,@info,@preview_profile&.dig(:handle_edge)]
        @preview_profile=effective_profile(flags)
        @hover_pick=true
        @target,@info,@normal=pick(x,y,view,@preview_profile)
        @preview_profile=@info[:profile]
        message=Elfis::BastillePodmienFront.l("#{@preview_profile[:name]}#{edge_label(@preview_profile)}: #{@info[:height].round(1)} × #{@info[:width].round(1)} mm — kliknij, aby zamienić","#{@preview_profile[:name]}#{edge_label(@preview_profile)}: #{@info[:height].round(1)} × #{@info[:width].round(1)} mm — click to replace")
        if message!=@hover_message
          view.tooltip=message
          Sketchup.set_status_text(message)
          @hover_message=message
        end
        view.invalidate if previous!=[@target,@info,@preview_profile[:handle_edge]]
      rescue => error
        had_preview=!!@target
        @target=nil
        @info=nil
        if @hover_message!=error.message
          view.tooltip=error.message
          Sketchup.set_status_text(error.message)
          @hover_message=error.message
        end
        view.invalidate if had_preview
      ensure
        @hover_pick=false
      end

      def draw(view)
        return unless @target && @target.valid? && @info
        lines=@info[:outline_world] ||= begin
          bounds=BastillePodmienFront.door_bounds(@target)
          points=(0..7).map { |i| bounds.corner(i).transform(@info[:world]) }
          [[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]].flat_map { |a,b| [points[a],points[b]] }
        end
        view.drawing_color=Sketchup::Color.new(25,145,200)
        view.line_width=3
        draw_overlay_lines(view,lines)
        if @preview_profile && @preview_profile[:kind]=='jpull'
          w,h,t=@info[:width],@info[:height],@preview_profile[:thickness]
          ends=case @preview_profile[:handle_edge]
          when 'top' then [[0,t,h],[w,t,h]]
          when 'bottom' then [[0,t,0],[w,t,0]]
          when 'left' then [[0,t,0],[0,t,h]]
          when 'right' then [[w,t,0],[w,t,h]]
          end
          view.drawing_color=Sketchup::Color.new(40,190,90)
          view.line_width=6
          draw_overlay_lines(view,ends.map { |xyz| Geom::Point3d.new(xyz.map(&:mm)).transform(@info[:world_placement]) })
        end
      end

      def draw_overlay_lines(view,world_points)
        # View projection applies the active edit transform itself. Our cached
        # coordinates are global, so remove that transform exactly once first.
        inverse=Sketchup.active_model.edit_transform.inverse
        screen_lines=world_points.each_slice(2).flat_map do |pair|
          projected=pair.map { |point| view.screen_coords(point.transform(inverse)) }
          next [] if projected.any?(&:nil?)
          projected.map { |point| Geom::Point3d.new(point.x,point.y,0) }
        end
        view.draw2d(GL_LINES,screen_lines) unless screen_lines.empty?
      end

      def onLButtonDown(flags,x,y,view)
        p=effective_profile(flags)
        target,info,normal,path=pick(x,y,view,p)
        BastillePodmienFront.replace(target,Sketchup.active_model,normal,path,p)
        Sketchup.set_status_text(Elfis::BastillePodmienFront.l("Gotowe: #{p[:name]}#{edge_label(p)} #{info[:height].round(1)} × #{info[:width].round(1)} mm. Kliknij kolejny front lub Esc.","Done: #{p[:name]}#{edge_label(p)} #{info[:height].round(1)} × #{info[:width].round(1)} mm. Click another front or press Esc."))
        @target=nil
        @info=nil
        @hover_signature=nil
        @hover_info=nil
        @hover_message=nil
        view.invalidate
      rescue => error
        UI.messagebox(Elfis::BastillePodmienFront.l("Nie zamieniono frontu.\n#{error.message}","Front not replaced.\n#{error.message}"))
      end

      def onCancel(reason,view)
        @target=nil
        @info=nil
        Sketchup.active_model.select_tool(nil) if reason==0
        view.invalidate
      end

      def deactivate(view)
        @held_modifiers={}
        @hover_signature=nil
        @hover_info=nil
        @hover_message=nil
        view.invalidate
      end
    end

    def activate
      Sketchup.active_model.select_tool(ClickTool.new)
    end

    @command ||= UI::Command.new(LABEL) { activate }
    @command.tooltip=Elfis::BastillePodmienFront.l('Zamień kliknięty front na drzwi Bastille','Replace the clicked front using the active door profile')
    @command.status_bar_text=Elfis::BastillePodmienFront.l('Odczytuje wymiary wskazanego frontu i zastępuje tylko tę instancję drzwiami Bastille 22 mm.','Read the clicked front dimensions and replace that occurrence using the active profile.')
    icon=File.join(__dir__,'elfis_bastille_podmien_front','podmien.svg')
    if File.file?(icon)
      @command.small_icon=icon
      @command.large_icon=icon
    end
    unless file_loaded?(__FILE__)
      UI.menu('Extensions').add_item(@command)
      file_loaded(__FILE__)
    end
    unless @toolbar
      @toolbar=UI::Toolbar.new('ELFIS — Doors')
      @toolbar.add_item(@command)
      @toolbar.get_last_state==-1 ? @toolbar.show : @toolbar.restore
    end
    unless @library_command
      @library_command=UI::Command.new('ELFIS — Biblioteka profili drzwi') { show_library }
      @library_command.tooltip=Elfis::BastillePodmienFront.l('Wybierz profil, dodaj przekrój lub utwórz drzwi','Choose a profile, add a cross-section or create a door')
      @library_command.small_icon=File.join(__dir__,'elfis_bastille_podmien_front','library.svg')
      @library_command.large_icon=@library_command.small_icon
      UI.menu('Extensions').add_item(@library_command)
      @toolbar.add_item(@library_command)
    end
    install_naming_menu
    install_order_list_command
    update_profile_command
    update_language_commands
    install_public_help
    unless @drilling_separator_added
      @toolbar.add_separator
      @drilling_separator_added=true
    end
    Elfis::HingeDrilling.install
    Elfis::DrawerDrilling.install
    Elfis::ShelfPins.install
    Elfis::ShelfSpacing.install
    Elfis::CarcassJoinery.install
    Elfis::HangerCutouts.install
    Elfis::DrillingRefresh.install
    unless @settings_separator_added
      @toolbar.add_separator
      @settings_separator_added=true
    end
    Elfis::StudioSettings.install
  end
end
