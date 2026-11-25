# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require File.join(__dir__,'elfis_bastille_podmien_front','engine.rb')
require File.join(__dir__,'elfis_bastille_podmien_front','library.rb')

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
    def measure(instance,model,front_normal=nil,path=nil)
      raise 'Wskaż komponent frontu.' unless instance.is_a?(Sketchup::ComponentInstance) && instance.valid?
      raise 'Front jest zablokowany.' if instance.locked?
      raise 'Ten front jest już utworzony tym narzędziem.' if instance.get_attribute('ElfisBastillePodmien','generated',false)
      path ||= [instance]
      raise 'Nieprawidłowa ścieżka komponentu.' unless path.last==instance && model.active_entities.to_a.include?(path.first)
      path.each_with_index do |parent,i|
        raise 'Szafka lub front jest zablokowany.' if parent.locked?
        raise 'Nieprawidłowa ścieżka komponentu.' if i>0 && !path[i-1].definition.entities.to_a.include?(parent)
      end
      raise 'Otwarta szafka ma wiele kopii. Najpierw wybierz Utwórz unikatowy / Make Unique dla szafki.' if model.active_path && model.active_path.any? { |parent| parent.definition.instances.length>1 }
      bounds=instance.definition.bounds
      local_lengths=[bounds.width,bounds.height,bounds.depth]
      parent_world=path[0...-1].inject(model.edit_transform) { |tr,parent| tr*parent.transformation }
      world=parent_world * instance.transformation
      world_origin=ORIGIN.transform(world)
      axes=[[1,0,0],[0,1,0],[0,0,1]].map { |p| Geom::Point3d.new(p).transform(world)-world_origin }
      scales=axes.map(&:length)
      raise 'Obiekt ma zerową skalę.' unless scales.all? { |s| s>0.000001 }
      directions=axes.map(&:normalize)
      raise 'Front jest ukośnie zdeformowany. Użyj prostokątnego komponentu.' unless [directions[0].dot(directions[1]),directions[0].dot(directions[2]),directions[1].dot(directions[2])].all? { |v| v.abs<0.0001 }
      physical=local_lengths.each_with_index.map { |length,i| (length*scales[i]).to_mm }
      depth_axis=(0..2).min_by { |i| physical[i] }
      face_axes=(0..2).to_a-[depth_axis]
      height_axis=face_axes.max_by { |i| directions[i].dot(Z_AXIS).abs }
      height_axis=face_axes.max_by { |i| physical[i] } if directions[height_axis].dot(Z_AXIS).abs<0.7
      width_axis=(face_axes-[height_axis]).first
      width,height=physical[width_axis],physical[height_axis]
      raise 'Wskaż płaski front, nie całą szafkę. W razie potrzeby wejdź w jej edycję.' unless physical[depth_axis]>0.1 && physical[depth_axis]<=80.0
      raise "Front jest za mały dla profilu #{profile[:name]} (#{profile[:width]} mm)." unless width>2*profile[:width] && height>2*profile[:width]
      sign_h=directions[height_axis].dot(Z_AXIS)<-0.001 ? -1.0 : 1.0
      sign_d=1.0
      if front_normal && front_normal.valid?
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
      {width:width,height:height,source_thickness:physical[depth_axis],placement:instance.transformation*mapping,axes:[width_axis,depth_axis,height_axis],front_sign:sign_d,world:world}
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
        raise 'Nie udało się odszukać frontu po utworzeniu kopii szafki.' unless child
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
      children=source.definition.entities.select { |e| instance?(e) }
      children.each do |child|
        transform=mapping*child.transformation
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

    def replace(instance,model=Sketchup.active_model,front_normal=nil,path=nil)
      path ||= [instance]
      info=measure(instance,model,front_normal,path)
      model.start_operation('Bastille — zamień front',true)
      begin
        path=unique_path(path)
        instance=path.last
        owner=path.length>1 ? path[-2].definition.entities : model.active_entities
        p=validate_profile(profile.dup)
        definition=build(model,p,info[:width],info[:height],p[:shoulder],p[:panel],p[:clearance])
        definition.name="#{p[:name]} #{info[:height].round(2)}x#{info[:width].round(2)} mm"
        replacement=owner.add_instance(definition,info[:placement])
        replacement.name=instance.name.empty? ? definition.name : "#{instance.name} — #{p[:name]}"
        replacement.layer=instance.layer
        replacement.material=instance.material
        replacement.casts_shadows=instance.casts_shadows?
        replacement.receives_shadows=instance.receives_shadows?
        replacement.set_attribute('ElfisBastillePodmien','generated',true)
        replacement.set_attribute('ElfisBastillePodmien','source_name',instance.name)
        replacement.set_attribute('ElfisBastillePodmien','width_mm',info[:width])
        replacement.set_attribute('ElfisBastillePodmien','height_mm',info[:height])
        replacement.set_attribute('ElfisBastillePodmien','profile_id',p[:id])
        preserve_nested_entities(instance,replacement)
        # Do not change the source definition: other instances remain intact.
        instance.erase!
        model.selection.clear
        model.selection.add(path.length>1 ? path.first : replacement)
        model.commit_operation
        replacement
      rescue => error
        model.abort_operation
        raise error
      end
    end

    class ClickTool
      def activate
        p=BastillePodmienFront.profile
        Sketchup.set_status_text("#{p[:name]} — #{p[:width]} × #{p[:thickness]} mm: kliknij front od zewnątrz. Ctrl+Z cofa. Esc kończy.")
      end

      def pick(x,y,view)
        helper=view.pick_helper
        helper.do_pick(x,y)
        raise 'Wskaż komponent frontu.' unless helper.count>0
        picked_path=helper.path_at(0)
        instances=picked_path.select { |e| BastillePodmienFront.instance?(e) }
        raise 'Ten front jest już utworzony tym narzędziem.' if instances.any? { |e| e.get_attribute('ElfisBastillePodmien','generated',false) }
        target=instances.reverse.find { |e| e.is_a?(Sketchup::ComponentInstance) }
        raise 'Wskaż komponent frontu, nie grupę.' unless target
        path=instances.take(instances.index(target)+1)
        normal=nil
        if helper.count>0 && helper.leaf_at(0).is_a?(Sketchup::Face)
          n=helper.leaf_at(0).normal.transform(helper.transformation_at(0))
          normal=n.transform(Sketchup.active_model.edit_transform)
        end
        info=BastillePodmienFront.measure(target,Sketchup.active_model,normal,path)
        [target,info,normal,path]
      end

      def onMouseMove(flags,x,y,view)
        @x,@y=x,y
        @target,@info,@normal=pick(x,y,view)
        message="#{BastillePodmienFront.profile[:name]}: #{@info[:height].round(1)} × #{@info[:width].round(1)} mm — kliknij, aby zamienić"
        view.tooltip=message
        Sketchup.set_status_text(message)
        view.invalidate
      rescue => error
        @target=nil
        @info=nil
        view.tooltip=error.message
        Sketchup.set_status_text(error.message)
        view.invalidate
      end

      def draw(view)
        return unless @target && @target.valid? && @info
        bounds=@target.definition.bounds
        points=(0..7).map { |i| bounds.corner(i).transform(@info[:world]) }
        lines=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]].flat_map { |a,b| [points[a],points[b]] }
        view.drawing_color=Sketchup::Color.new(25,145,200)
        view.line_width=3
        view.draw(GL_LINES,lines)
      end

      def onLButtonDown(flags,x,y,view)
        target,info,normal,path=pick(x,y,view)
        BastillePodmienFront.replace(target,Sketchup.active_model,normal,path)
        Sketchup.set_status_text("Gotowe: #{BastillePodmienFront.profile[:name]} #{info[:height].round(1)} × #{info[:width].round(1)} mm. Kliknij kolejny front lub Esc.")
        @target=nil
        @info=nil
        view.invalidate
      rescue => error
        UI.messagebox("Nie zamieniono frontu.\n#{error.message}")
      end

      def onCancel(reason,view)
        @target=nil
        @info=nil
        Sketchup.active_model.select_tool(nil) if reason==0
        view.invalidate
      end

      def deactivate(view)
        view.invalidate
      end
    end

    def activate
      Sketchup.active_model.select_tool(ClickTool.new)
    end

    @command ||= UI::Command.new(LABEL) { activate }
    @command.tooltip='Zamień kliknięty front na drzwi Bastille'
    @command.status_bar_text='Odczytuje wymiary wskazanego frontu i zastępuje tylko tę instancję drzwiami Bastille 22 mm.'
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
      @toolbar=UI::Toolbar.new('ELFIS — Bastille zamiana frontu')
      @toolbar.add_item(@command)
      @toolbar.get_last_state==-1 ? @toolbar.show : @toolbar.restore
    end
    unless @library_command
      @library_command=UI::Command.new('ELFIS — Biblioteka profili drzwi') { show_library }
      @library_command.tooltip='Wybierz profil, dodaj przekrój lub utwórz drzwi'
      @library_command.small_icon=File.join(__dir__,'elfis_bastille_podmien_front','library.svg')
      @library_command.large_icon=@library_command.small_icon
      UI.menu('Extensions').add_item(@library_command)
      @toolbar.add_item(@library_command)
    end
    update_profile_command
  end
end
