# encoding: UTF-8
require 'securerandom'
require 'json'
module Elfis
  module HangerCutouts
    extend self
    DICT='ElfisHangerCutouts' unless const_defined?(:DICT)
    PRESETS={kamar:{name:'Kamar',width:20.0,height:55.0,lip_side:11.0,lip_bottom:8.0,depth:8.0,vector_tag:'Kamar D6.0_DEPTH_8.0'}}.freeze unless const_defined?(:PRESETS)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def preset;PRESETS.fetch(:kamar);end
    def instance?(e);CarcassJoinery.instance?(e);end
    def selected_sides(c)
      value=c[:sides]
      return %i[left right] if value.nil? || value.to_s=='both'
      sides=Array(value).map(&:to_sym).uniq
      raise 'Choose left, right or both hanger cutouts.' unless !sides.empty? && (sides-%i[left right]).empty?
      sides
    end
    # Establish this back's own frame. Corner cabinets do not have two parallel
    # side panels; the actual neighbouring boards determine its interior.
    def back_frame(b,all)
      wi=(0..2).find { |i|i!=b[:thin] && b[:axes][i].dot(Z_AXIS).abs<0.001 }
      raise 'The back must be upright.' unless wi
      width=b[:axes][wi];depth=Z_AXIS.cross(width).normalize
      frame=Geom::Transformation.axes(ORIGIN,width,depth,Z_AXIS);inv=frame.inverse
      sb=ShelfPins.projected(b[:points],inv)
      neighbours=all.reject { |q|q[:entity]==b[:entity] || CarcassJoinery.back?(q) }.filter_map do |q|
        pb=ShelfPins.projected(q[:points],inv)
        overlap=[pb.max.x,sb.max.x].min-[pb.min.x,sb.min.x].max
        next if overlap.to_f < -2.mm.to_f || pb.max.z<sb.min.z || pb.min.z>sb.max.z
        next if pb.min.y>sb.max.y+2.mm || pb.max.y<sb.min.y-2.mm
        delta=(pb.center.y-sb.center.y).to_f
        next if delta.abs<1.mm.to_f
        [CarcassJoinery.horizontal?(q),delta,[overlap.to_f,1.mm.to_f].max]
      end
      horizontal=neighbours.select(&:first);neighbours=horizontal unless horizontal.empty?
      raise l('Nie można ustalić zewnętrznej strony pleców.','Cannot establish the exterior of this back.') if neighbours.empty?
      score=neighbours.sum { |_,delta,weight|delta*weight }
      raise 'Ambiguous back exterior.' if score.abs<0.001
      # Width always points right when viewing the back from its exterior.
      if score<0
        width=width.reverse;depth=depth.reverse
        frame=Geom::Transformation.axes(ORIGIN,width,depth,Z_AXIS);inv=frame.inverse
        sb=ShelfPins.projected(b[:points],inv)
      end
      {shelf:b,frame:frame,inverse:inv,bounds:sb,width:width,depth_axis:depth,outside:sb.min.y,inward:depth}
    end
    def layout_settings(path,c=preset,model=Sketchup.active_model)
      raw=path.last.get_attribute(DICT,'sides')
      return c.merge(sides:JSON.parse(raw).map(&:to_sym)) if raw
      # Legacy panels retain their actual one- or two-corner arrangement.
      p=plan(path,c.merge(sides: :both),model)
      existing=p[:corners].select { |v|!v[:cut] || v[:existing] }.map { |v|v[:side] }
      existing.empty? ? c : c.merge(sides:existing)
    end
    def existing_layout?(path,model=Sketchup.active_model)
      plan(path,preset,model)[:corners].any? { |v|!v[:cut] || v[:existing] }
    rescue StandardError
      false
    end
    def world_point(p,x,z)
      Geom::Point3d.new(x,p[:outside],z).transform(p[:frame])
    end
    def on_face?(b,world)
      q=world.transform(b[:world].inverse)
      good=[Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex]
      b[:faces].any? { |f|f.valid? && q.distance_to_plane(f.plane)<0.01.mm && good.include?(f.classify_point(q)) }
    end
    def matching_vectors(b,points,c)
      expected=points.map { |q|q.transform(b[:world].inverse) }
      b[:entity].definition.entities.select do |g|
        next false unless instance?(g)
        entities=g.definition.entities;edges=entities.grep(Sketchup::Edge)
        next false unless entities.length==6 && edges.length==6 && edges.all? { |e|e.layer.name==c[:vector_tag] }
        pairs=edges.map { |e|e.vertices.map { |v|v.position.transform(g.transformation) } }
        expected.each_with_index.all? do |a,i|
          d=expected[(i+1)%expected.length]
          pairs.any? { |u,v|(a.distance(u).to_f<0.01.mm.to_f && d.distance(v).to_f<0.01.mm.to_f)||(a.distance(v).to_f<0.01.mm.to_f && d.distance(u).to_f<0.01.mm.to_f) }
        end
      end
    end
    def cut_corner(back,b,p,corner)
      ents=back.definition.entities;inverse=b[:world].inverse
      rect=corner[:rect].map { |q|q.transform(p[:inverse]) }
      x0=rect.map(&:x).min.to_f;x1=rect.map(&:x).max.to_f
      z0=rect.map(&:z).min.to_f;z1=rect.map(&:z).max.to_f
      y0=p[:bounds].min.y.to_f;y1=p[:bounds].max.y.to_f
      # Split the four existing outer surfaces, remove only material inside the
      # notch and close its floor/inner wall. Avoid overlapping push/pull solids.
      edge=corner[:side]==:left ? x0 : x1
      inside=corner[:side]==:left ? x1 : x0
      local=->(points) { points.map { |q|Geom::Point3d.new(q).transform(p[:frame]).transform(inverse) } }
      patches=[[[x0,y0,z0],[x1,y0,z0],[x1,y0,z1],[x0,y0,z1]],
               [[x0,y1,z0],[x1,y1,z0],[x1,y1,z1],[x0,y1,z1]],
               [[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]],
               [[edge,y0,z0],[edge,y1,z0],[edge,y1,z1],[edge,y0,z1]]]
      patches.each { |points|raise 'Could not split a notch boundary.' unless ents.add_face(local.call(points)) }
      within=->(v) do
        q=v.position.transform(b[:world]).transform(p[:inverse]);t=0.001.mm.to_f
        q.x.to_f>=x0-t && q.x.to_f<=x1+t && q.y.to_f>=y0-t && q.y.to_f<=y1+t && q.z.to_f>=z0-t && q.z.to_f<=z1+t
      end
      faces=ents.grep(Sketchup::Face).select { |f|f.vertices.all? { |v|within.call(v) } }
      raise 'Could not isolate the notch surfaces.' if faces.length<4
      ents.erase_entities(faces)
      loose=ents.grep(Sketchup::Edge).select { |e|e.faces.empty? && e.vertices.all? { |v|within.call(v) } }
      ents.erase_entities(loose) unless loose.empty?
      floor=ents.add_face(local.call([[x0,y0,z0],[x1,y0,z0],[x1,y1,z0],[x0,y1,z0]]))
      wall=ents.add_face(local.call([[inside,y0,z0],[inside,y1,z0],[inside,y1,z1],[inside,y0,z1]]))
      raise 'Could not close the notch floor and wall.' unless floor && wall
      floor.reverse! if floor.normal.transform(b[:world]).dot(Z_AXIS)<0
      desired=corner[:side]==:left ? p[:width].reverse : p[:width]
      wall.reverse! if wall.normal.transform(b[:world]).dot(desired)<0
    end
    def fill_corner(back,b,p,corner)
      ents=back.definition.entities;inverse=b[:world].inverse
      rect=corner[:rect].map { |q|q.transform(p[:inverse]) }
      x0=rect.map(&:x).min.to_f;x1=rect.map(&:x).max.to_f
      z0=rect.map(&:z).min.to_f;z1=rect.map(&:z).max.to_f
      y0=p[:bounds].min.y.to_f;y1=p[:bounds].max.y.to_f
      edge=corner[:side]==:left ? x0 : x1
      within=->(v) do
        q=v.position.transform(b[:world]).transform(p[:inverse]);t=0.001.mm.to_f
        q.x.to_f>=x0-t && q.x.to_f<=x1+t && q.y.to_f>=y0-t && q.y.to_f<=y1+t && q.z.to_f>=z0-t && q.z.to_f<=z1+t
      end
      patches=[[[[x0,y0,z0],[x1,y0,z0],[x1,y0,z1],[x0,y0,z1]],p[:depth_axis].reverse],
               [[[x0,y1,z0],[x1,y1,z0],[x1,y1,z1],[x0,y1,z1]],p[:depth_axis]],
               [[[x0,y0,z1],[x1,y0,z1],[x1,y1,z1],[x0,y1,z1]],Z_AXIS],
               [[[edge,y0,z0],[edge,y1,z0],[edge,y1,z1],[edge,y0,z1]],corner[:side]==:left ? p[:width].reverse : p[:width]]]
      # Extend the neighbouring surface's materials onto the filled corner.
      surfaces=ents.grep(Sketchup::Face)
      patches=patches.map do |points,normal|
        local=points.map { |q|Geom::Point3d.new(q).transform(p[:frame]).transform(inverse) }
        source=surfaces.find { |f|local.first.distance_to_plane(f.plane).to_f<0.001.mm.to_f && f.normal.transform(b[:world]).normalize.dot(normal).abs>0.999 }
        front=source && source.material;rear=source && source.back_material
        front,rear=rear,front if source && source.normal.transform(b[:world]).dot(normal)<0
        [local,normal,front,rear]
      end
      internal=surfaces.select { |f|f.vertices.all? { |v|within.call(v) } }
      raise l('Nie rozpoznano ścian wycięcia.','Could not identify the notch walls.') if internal.length<2
      ents.erase_entities(internal)
      patches.each do |local,normal,front,rear|
        f=ents.add_face(local);raise l('Nie udało się zamknąć wycięcia.','Could not close the notch.') unless f
        f.reverse! if f.normal.transform(b[:world]).dot(normal)<0
        f.material=front;f.back_material=rear
      end
      # Remove only redundant seams in the repaired corner, preserving material
      # boundaries and unrelated edges elsewhere on the panel.
      ents.grep(Sketchup::Edge).each do |e|
        next unless e.valid? && e.vertices.all? { |v|within.call(v) }
        faces=e.faces
        if faces.empty?
          e.erase!
        elsif faces.length==2 && faces[0].normal.dot(faces[1].normal)>0.999 && faces[0].material==faces[1].material && faces[0].back_material==faces[1].back_material
          e.erase!
        end
      end
    end
    def plan(path,c=preset,model=Sketchup.active_model)
      b=CarcassJoinery.board(path,model)
      raise l('Kliknij plecy szafki z tagiem ustawionym dla pleców.','Click a cabinet back with the configured back tag.') unless CarcassJoinery.back?(b) && CarcassJoinery.eligible?(b)
      raise l('Plecy lub ich rodzic są zablokowane.','The back or its parent is locked.') if path.any?(&:locked?)
      all=CarcassJoinery.surroundings(path,model);p=back_frame(b,all);sb=p[:bounds]
      raise l('Plecy są za małe dla wycięć Kamar.','The back is too small for Kamar cutouts.') unless (sb.max.x-sb.min.x).to_mm>2*(c[:width]+c[:lip_side]) && (sb.max.z-sb.min.z).to_mm>c[:height]+c[:lip_bottom]
      raise l('Plecy są za cienkie dla frezowania 8 mm.','The back is too thin for 8 mm routing.') unless b[:lengths][b[:thin]].to_mm>c[:depth]+0.01
      sides=selected_sides(c)
      corners=[[:left,sb.min.x,1],[:right,sb.max.x,-1]].select { |side,_,_|sides.include?(side) }.map do |side,edge,sign|
        inner=edge+sign*c[:width].mm;lip=edge+sign*(c[:width]+c[:lip_side]).mm
        z=sb.max.z;bottom=z-c[:height].mm;low=bottom-c[:lip_bottom].mm
        rect=[[edge,bottom],[inner,bottom],[inner,z],[edge,z]].map { |x,zz|world_point(p,x,zz) }
        contour=[[inner,bottom],[inner,z],[lip,z],[lip,low],[edge,low],[edge,bottom]].map { |x,zz|world_point(p,x,zz) }
        # A partly different notch needs review rather than an extra blind cut.
        probes=[0.01,0.5,0.99].product([0.01,0.5,0.99]).map { |a,d|world_point(p,edge+sign*c[:width].mm*a,bottom+c[:height].mm*d) }
        present=probes.map { |q|on_face?(b,q) }
        inside=probes.map { |q|on_face?(b,q.offset(p[:inward],b[:lengths][b[:thin]])) }
        cut=present.all?
        unless (cut && inside.all?) || (present.none? && inside.none?)
          raise l('Istniejące wycięcie ma inny kształt lub rozmiar. Nie zmieniono pleców.','An existing notch has a different shape or size. The back was not changed.')
        end
        if !cut && ![world_point(p,inner+sign*0.5.mm,z-c[:height].mm/2),world_point(p,edge+sign*c[:width].mm/2,bottom-0.5.mm)].all? { |q|on_face?(b,q) }
          raise l('Istniejące wycięcie jest większe niż wzorzec Kamar.','An existing notch is larger than the Kamar template.')
        end
        # All of the L pocket must have material behind it.
        samples=[world_point(p,inner+sign*c[:lip_side].mm/2,z-c[:height].mm/2),world_point(p,edge+sign*(c[:width]+c[:lip_side]).mm/2,bottom-c[:lip_bottom].mm/2)]
        raise l('Brak materiału pod obrysem frezowania L.','No material beneath the L routing contour.') unless samples.all? { |q|on_face?(b,q) }
        matches=matching_vectors(b,contour,c)
        raise l('Znaleziono kilka jednakowych obrysów frezowania. Sprawdź plecy.','Several matching routing contours found. Review the back.') if matches.length>1
        raise l('Grupa frezowania jest zablokowana.','The routing group is locked.') if matches.any?(&:locked?)
        {side:side,rect:rect,contour:contour,cut:cut,existing:matches.first}
      end
      p.merge(shelf:b,holes:[],corners:corners,preset:c)
    end
    def apply(paths,c=preset,model=Sketchup.active_model,operation:true,remove:false)
      paths=paths.uniq { |path|path.map(&:persistent_id) }
      raise l('Nie wybrano pleców.','No back panels selected.') if paths.empty?
      raise l('Najpierw utwórz unikatową otwartą szafkę.','Make the open cabinet unique first.') if Array(model.active_path).any? { |e|e.definition.instances.length>1 }
      paths.each { |path|plan(path,c,model) }
      token=SecureRandom.uuid;marked=[];cuts=0;created=0;reused=0;filled=0;removed=0
      label=remove ? l('ELFIS — Usuń wycięcia pod zawieszki','ELFIS — Remove hanger cutouts') : l('ELFIS — Wycięcia pod zawieszki','ELFIS — Hanger cutouts')
      model.start_operation(label,true) if operation
      begin
        refs=paths.map do |path|
          path.each { |e|e.set_attribute('ElfisHangerTemp',token,e.persistent_id.to_s);marked<<e }
          [path.first,path.map { |e|e.get_attribute('ElfisHangerTemp',token) }]
        end
        refs.each do |root,ids|
          path=[root]
          ids.drop(1).each do |id|
            child=path.last.definition.entities.find { |e|instance?(e) && e.get_attribute('ElfisHangerTemp',token)==id }
            raise 'Back panel path changed.' unless child;path<<child
          end
          path=BastillePodmienFront.unique_path(path);back=path.last
          back.make_unique if back.definition.instances.length>1
          p=plan(path,c,model);b=p[:shelf];inverse=b[:world].inverse
          if remove
            p[:corners].each do |corner|
              if corner[:existing];corner[:existing].erase!;removed+=1;end
              unless corner[:cut];fill_corner(back,b,p,corner);filled+=1;end
            end
            check=plan(path,c,model)
            raise l('Nie udało się przywrócić pełnych narożników.','Could not restore solid corners.') unless check[:corners].all? { |v|v[:cut] && !v[:existing] }
            remaining=plan(path,preset,model)[:corners].select { |v|!v[:cut] || v[:existing] }.map { |v|v[:side] }
            if remaining.empty?
              back.delete_attribute(DICT)
            else
              back.set_attribute(DICT,'preset','kamar');back.set_attribute(DICT,'sides',JSON.generate(remaining))
            end
            next
          end
          p[:corners].each do |corner|
            next unless corner[:cut]
            cut_corner(back,b,p,corner);cuts+=1
          end
          # Verify both through-notches before adding machining vectors.
          p=plan(path,c,model)
          raise l('Wycięcie nie przeszło przez plecy. Cofnięto operację.','A notch did not pass through the back. Operation rolled back.') if p[:corners].any? { |v|v[:cut] }
          edge_tag=model.layers[c[:vector_tag]]||model.layers.add(c[:vector_tag])
          group_tag=StudioSettings.operation_tag;operation_tag=model.layers[group_tag]||model.layers.add(group_tag)
          p[:corners].each do |corner|
            g=corner[:existing]
            if g;reused+=1
            else
              g=back.definition.entities.add_group
              points=corner[:contour].map { |q|q.transform(inverse) }
              g.entities.add_curve(points+[points.first]).each { |edge|edge.layer=edge_tag };created+=1
            end
            g.name='Blum Operations';g.layer=operation_tag
            g.set_attribute(DICT,'preset','kamar');g.set_attribute(DICT,'side',corner[:side].to_s)
            g.set_attribute(DICT,'depth',c[:depth]);g.set_attribute(DICT,'width',c[:width]);g.set_attribute(DICT,'height',c[:height])
          end
          back.set_attribute(DICT,'preset','kamar')
          present=plan(path,preset,model)[:corners].select { |v|!v[:cut] || v[:existing] }.map { |v|v[:side] }
          back.set_attribute(DICT,'sides',JSON.generate(present))
        end
        model.definitions.each { |d|d.entities.each { |e|e.delete_attribute('ElfisHangerTemp',token) if instance?(e) } }
        marked.each { |e|e.delete_attribute('ElfisHangerTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation;raise
      end
      model.active_view.invalidate;{panels:paths.length,cuts:cuts,created:created,reused:reused,filled:filled,removed:removed}
    end
    def remove(paths,c=preset,model=Sketchup.active_model,operation:true)
      apply(paths,c,model,operation:operation,remove:true)
    end
    def selected_paths(model)
      model.selection.select { |e|instance?(e) }.flat_map do |e|
        b=CarcassJoinery.board([e],model)
        if CarcassJoinery.back?(b);[[e]]
        else;CarcassJoinery.panels(e,model).select { |v|CarcassJoinery.back?(v) }.map { |v|v[:path] };end
      end
    end
    def activate
      Sketchup.active_model.select_tool(Tool.new)
    rescue=>e;UI.messagebox(e.message)
    end
    class Tool < CarcassJoinery::Tool
      def initialize;super(nil);@alt=false;@sides=nil;end
      def activate;show_mode;end
      def configuration(path=@path)
        return HangerCutouts.preset.merge(sides:@sides) if @sides
        return @plan[:preset] if path && path==@path && @plan
        path ? HangerCutouts.layout_settings(path) : HangerCutouts.preset
      end
      def panel_hit(x,y)
        return nil unless x>=20 && x<=352 && y>=20 && y<=160
        return :left if x>=32 && x<=128 && y>=64 && y<=96
        return :right if x>=136 && x<=232 && y>=64 && y<=96
        return :both if x>=240 && x<=336 && y>=64 && y<=96
        :panel
      end
      def choose_side(side,view)
        @sides=side
        @plan=HangerCutouts.plan(@path,configuration) if @path
        show_mode;view.invalidate
      rescue=>e;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def draw_panel(view)
        text=->(x,y,value,opts={}) { view.draw_text(Geom::Point3d.new(x,y,0),value,{size:11,color:'#263c40'}.merge(opts)) }
        rect=->(x,y,w,h,fill) do
          pts=[[x,y,0],[x+w,y,0],[x+w,y+h,0],[x,y+h,0]].map { |q|Geom::Point3d.new(q) }
          view.drawing_color=fill;view.draw2d(GL_QUADS,pts)
          view.drawing_color='#bfd2d1';view.line_width=1;view.draw2d(GL_LINE_LOOP,pts)
        end
        view.line_stipple='';rect.call(20,20,332,140,'#f5f8f8')
        text.call(32,30,HangerCutouts.l('Kamar · Wycięcia w plecach','Kamar · Back cutouts'),{bold:true,size:13})
        sides=HangerCutouts.selected_sides(configuration)
        mode=sides.length==2 ? :both : sides.first
        %i[left right both].each_with_index do |side,i|
          x=32+104*i;active=mode==side
          rect.call(x,64,96,32,active ? '#217b76' : '#ffffff')
          label=HangerCutouts.l({left:'Lewe',right:'Prawe',both:'Oba'}[side],side.to_s.capitalize)
          text.call(x+48,70,label,{align:TextAlignCenter,color:active ? '#ffffff' : '#263c40',bold:true})
        end
        text.call(32,107,HangerCutouts.l('Widok od zewnątrz wskazanych pleców.','Viewed from the exterior of the hovered back.'),{size:10})
        text.call(32,128,HangerCutouts.l('Ctrl: zmień wybór · Alt: usuń · klik: zastosuj','Ctrl: cycle · Alt: remove · click: apply'),{size:10})
      end
      def show_mode
        text=@remove ? HangerCutouts.l('Kamar — USUŃ: Alt + klik zamyka wycięcia i usuwa obrysy L. Puść Alt: dodawanie.','Kamar — REMOVE: Alt + click fills notches and removes L contours. Release Alt: add mode.') : HangerCutouts.l('Kamar: klik dodaje wycięcia i obrysy L. Przytrzymaj Alt: usuń i zamknij wycięcia. Esc: koniec.','Kamar: click adds notches and L contours. Hold Alt: remove and fill notches. Esc: finish.')
        Sketchup.set_status_text(text)
      end
      def removing?(flags=0);@alt || (flags & ALT_MODIFIER_MASK)!=0;end
      def onKeyDown(key,repeat,flags,view)
        if key==COPY_MODIFIER_KEY
          if repeat<=1
            sides=HangerCutouts.selected_sides(configuration)
            mode=sides.length==2 ? :both : sides.first
            choose_side({both: :left,left: :right,right: :both}.fetch(mode),view)
          end
          return true
        end
        return unless key==ALT_MODIFIER_KEY
        @alt=true;@remove=true;show_mode;view.invalidate;true
      end
      def onKeyUp(key,repeat,flags,view)
        return true if key==COPY_MODIFIER_KEY
        return unless key==ALT_MODIFIER_KEY
        @alt=false;@remove=false;show_mode;view.invalidate;true
      end
      def onMouseMove(flags,x,y,view)
        @remove=removing?(flags)
        return view.invalidate if panel_hit(x,y)
        found=nil;ph=view.pick_helper;ph.do_pick(x,y)
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e|HangerCutouts.instance?(e) }
          raw.length.downto(1) do |n|
            path=raw.take(n)
            if CarcassJoinery.back?(CarcassJoinery.board(path));found=path;break;end
          end
          break if found
        end
        if found;@plan=HangerCutouts.plan(found,configuration(found)) unless @path==found && @plan;@path=found
        else;@path=nil;@plan=nil;end
        view.invalidate
      rescue=>e;@path=nil;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def draw(view)
        super;draw_panel(view);return unless @plan
        inverse=Sketchup.active_model.edit_transform.inverse
        @plan[:corners].each do |corner|
          next if @remove && corner[:cut] && !corner[:existing]
          view.drawing_color=@remove ? 'Red' : 'OrangeRed';view.line_width=3
          points=@remove ? corner[:rect] : corner[:contour]
          view.draw2d(GL_LINE_LOOP,points.map { |p|v=view.screen_coords(p.transform(inverse));Geom::Point3d.new(v.x,v.y,0) })
        end
      end
      def onLButtonDown(flags,x,y,view)
        hit=panel_hit(x,y)
        if hit
          choose_side(hit,view) unless hit==:panel
          return
        end
        @path=nil;onMouseMove(flags,x,y,view);return unless @path
        if @remove
          r=HangerCutouts.remove([@path],configuration);Sketchup.set_status_text(HangerCutouts.l("Kamar: zamknięte wycięcia #{r[:filled]}, usunięte obrysy #{r[:removed]}.","Kamar: #{r[:filled]} notches filled; #{r[:removed]} routing contours removed."))
        else
          r=HangerCutouts.apply([@path],configuration);Sketchup.set_status_text(HangerCutouts.l("Kamar: wycięcia #{r[:cuts]}; obrysy nowe #{r[:created]} / zachowane #{r[:reused]}.","Kamar: #{r[:cuts]} notches; #{r[:created]} new / #{r[:reused]} reused contours."))
        end
        @path=nil;@plan=nil;view.invalidate
      rescue=>e;UI.messagebox(e.message)
      end
      def deactivate(view);@alt=false;@remove=false;super;end
      def getMenu(menu)
        menu.add_item('Kamar · 55 × 20 mm · L 31 × 63 mm · D6 / 8 mm') { UI.messagebox(HangerCutouts.l('Wycięcia na wylot. Obrysy L od zewnątrz pleców. Grupa: Blum Operations. Tag linii: Kamar D6.0_DEPTH_8.0.','Through-notches. Exterior L contours. Group: Blum Operations. Edge tag: Kamar D6.0_DEPTH_8.0.')) }
      end
    end
    def install
      if @command
        @command.tooltip=l('Kamar: klik dodaje; Alt + klik usuwa i zamyka wycięcia','Kamar: click to add; Alt + click to remove and fill notches')
        return
      end
      @command=UI::Command.new('ELFIS — Hanger Cutouts / Wycięcia pod zawieszki') { activate }
      @command.tooltip=l('Kamar: klik dodaje; Alt + klik usuwa i zamyka wycięcia','Kamar: click to add; Alt + click to remove and fill notches')
      @command.small_icon=File.join(__dir__,'hanger_cutouts.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command)
      toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
    end
  end
end

