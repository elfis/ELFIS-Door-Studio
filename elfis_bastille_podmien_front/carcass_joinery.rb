# encoding: UTF-8
require 'json'
require 'securerandom'
require_relative 'drilling_tool_modifiers'
require_relative 'carcass_joinery_layout'
module Elfis
  module CarcassJoinery
    extend self
    DICT='ElfisCarcassJoinery' unless const_defined?(:DICT)
    PREF='ELFIS Carcass Joinery' unless const_defined?(:PREF)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def instance?(e);ShelfPins.instance?(e);end
    def defaults;CarcassJoineryLayout.defaults;end
    def settings;defaults.to_h { |k,v| [k,Sketchup.read_default(PREF,k.to_s,v)] };end
    def validate(c);CarcassJoineryLayout.validate(c);end
    def tag(diameter,depth);"D#{diameter.to_f}_DEPTH#{depth.to_f}";end

    def board(path,model=Sketchup.active_model)
      e=path.last;return nil unless instance?(e) && e.valid? && (defined?(StudioSettings) ? StudioSettings.panel?(e) : %w[body back\ wall].include?(e.layer.name.downcase))
      faces=e.definition.entities.grep(Sketchup::Face);return nil if faces.length<6
      bb=Geom::BoundingBox.new;faces.each { |f| f.vertices.each { |v| bb.add(v.position) } }
      tr=path.inject(model.edit_transform) { |t,i| t*i.transformation }
      vectors=[X_AXIS,Y_AXIS,Z_AXIS].map { |v| v.transform(tr) };return nil if vectors.any? { |v| v.length<1e-8 }
      axes=vectors.map(&:normalize);return nil unless [[0,1],[0,2],[1,2]].all? { |a,b| axes[a].dot(axes[b]).abs<1e-5 }
      lengths=[bb.width,bb.height,bb.depth].each_with_index.map { |n,i| n*vectors[i].length };thin=(0..2).min_by { |i| lengths[i] }
      return nil unless lengths[thin]>0.1.mm && lengths[thin]<=80.mm
      {path:path,entity:e,world:tr,bb:bb,faces:faces,axes:axes,lengths:lengths,thin:thin,points:(0..7).map { |i| bb.corner(i).transform(tr) }}
    end
    def back?(b);b && (defined?(StudioSettings) ? StudioSettings.role?(b[:entity],:backs) : b[:entity].layer.name.downcase=='back wall');end
    def horizontal?(b);b && !back?(b) && (!defined?(StudioSettings)||StudioSettings.role?(b[:entity],:joints)) && b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999;end
    def eligible?(b);horizontal?(b) || (back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001);end
    def fixed?(b)
      horizontal?(b) && [b[:entity].name,b[:entity].definition.name].join(' ').match?(/fixed\s*shelf|p[oó]łka\s*stała|cabinet\s*(base|top)|cross\s*member|wieniec|trawers/i)
    end
    def panels(root,model=Sketchup.active_model)
      out=[];walk=nil
      walk=->(path,stack) do
        e=path.last;next if !e.valid? || e.hidden? || !e.layer.visible? || stack.include?(e.definition)
        b=board(path,model);out<<b if b;next if b
        e.definition.entities.each { |child| walk.call(path+[child],stack+[e.definition]) if instance?(child) }
      end
      walk.call([root],[]);out
    end
    def surroundings(path,model)
      path.length==1 ? model.active_entities.select { |e| instance?(e) }.flat_map { |e| panels(e,model) } : panels(path.first,model)
    end
    def frame_for(b,all)
      attempts=[]
      wi_candidates=(0..2).select { |i| i!=b[:thin] && b[:axes][i].dot(Z_AXIS).abs<0.001 }
      wi_candidates.each do |wi|
        width=b[:axes][wi];depth=Z_AXIS.cross(width).normalize
        frame=Geom::Transformation.axes(ORIGIN,width,depth,Z_AXIS);inv=frame.inverse;sb=ShelfPins.projected(b[:points],inv)
        eligible=all.reject { |p| p[:entity]==b[:entity] || back?(p) }.select { |p| (!defined?(StudioSettings)||StudioSettings.role?(p[:entity],:sides)) && p[:axes][p[:thin]].dot(width).abs>0.999 }
        sides=[-1,1].map do |sign|
          edge=sign<0 ? sb.min.x : sb.max.x
          matches=eligible.filter_map do |p|
            pb=ShelfPins.projected(p[:points],inv);inner=sign<0 ? pb.max.x : pb.min.x
            delta=(inner-edge).abs
            next unless delta<=2.mm && pb.min.y<=sb.min.y+0.05.mm && pb.max.y>=sb.max.y-0.05.mm && pb.min.z<=sb.min.z+0.05.mm && pb.max.z>=sb.max.z-0.05.mm
            [delta,p,pb,inner]
          end.sort_by(&:first)
          raise l('Niejednoznaczny bok szafki.','More than one side panel matches.') if matches.length>1 && (matches[0][0]-matches[1][0]).abs<0.01.mm
          matches.first
        end
        attempts<<{shelf:b,frame:frame,inverse:inv,bounds:sb,sides:sides,width:width,depth_axis:depth} if sides.all?
      end
      raise l('Nie znaleziono dwóch przylegających boków z ustawionymi tagami boków.','Could not find two adjacent side panels with configured side tags.') unless attempts.length==1
      attempts.first
    end
    def front_high?(p,all)
      sb=p[:bounds]
      backs=all.select { |b| back?(b) && b[:axes][b[:thin]].dot(p[:depth_axis]).abs>0.999 }
      unless backs.empty?
        ys=backs.map { |b| ShelfPins.projected(b[:points],p[:inverse]).center.y }
        # A back centred on the panel cannot establish a usable front datum.
        raise l('Nie można ustalić przodu szafki z pleców.','Cannot establish the cabinet front from its back.') if (ys.sum/ys.length-sb.center.y).abs<0.1.mm && !back?(p[:shelf])
        return ys.sum/ys.length < p[:sides].map { |_,_,pb,_| pb.center.y }.sum/2
      end
      raise l('Dodaj plecy z tagiem ustawionym dla pleców, aby ustalić przód szafki.','A back panel with a configured back tag is required to establish the cabinet front.')
    end
    def check_circle(h)
      b=h[:panel];inv=b[:world].inverse;local=h[:point].transform(inv)
      faces=b[:faces].select { |f| local.distance_to_plane(f.plane)<0.02.mm }
      good=[Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex]
      r=h[:diameter].mm/2;other=h[:normal].cross(h[:tangent]).normalize
      valid=faces.any? do |f|
        good.include?(f.classify_point(local)) && (0...24).all? do |i|
          a=2*Math::PI*i/24
          q=h[:point].offset(h[:tangent],r*Math.cos(a)).offset(other,r*Math.sin(a)).transform(inv)
          good.include?(f.classify_point(q))
        end
      end
      raise l('Otwór wypada poza powierzchnią boku lub przecina wycięcie.','A drilling circle lies outside the side surface or crosses a cutout.') unless valid
      raise l('Głębokość wiercenia przekracza grubość boku.','Drilling depth exceeds side thickness.') if h[:depth].mm>b[:lengths][b[:thin]]+0.01.mm
    end
    # Use the actual cut end of the back, rather than its rectangular bounds.
    # Hanger notches can leave no material at the old top screw position.
    def back_specs(b,p,i,c)
      sb=p[:bounds];x=i==0 ? sb.min.x : sb.max.x;y=sb.center.y
      local=Geom::Point3d.new(x,y,sb.center.z).transform(p[:frame]).transform(b[:world].inverse)
      faces=b[:faces].select { |f| local.distance_to_plane(f.plane)<0.02.mm }
      good=[Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex]
      contains=->(z) do
        q=Geom::Point3d.new(x,y,z).transform(p[:frame]).transform(b[:world].inverse)
        faces.any? { |f| good.include?(f.classify_point(q)) }
      end
      zs=[sb.min.z,sb.max.z]
      faces.each do |f|
        f.edges.each do |edge|
          a,d=edge.vertices.map { |v| v.position.transform(b[:world]).transform(p[:inverse]) }
          zs.concat([a.z,d.z])
          if (d.y-a.y).abs>1e-9
            t=(y-a.y)/(d.y-a.y)
            zs<<a.z+t*(d.z-a.z) if t>=0 && t<=1
          end
        end
      end
      zs=zs.map(&:to_f).sort.each_with_object([]) { |z,out| out<<z if out.empty? || z-out.last>0.001.mm }
      ranges=[]
      zs.each_cons(2) do |lo,hi|
        next unless hi-lo>0.001.mm && contains.call((lo+hi)/2)
        if !ranges.empty? && (ranges.last[1]-lo).abs<0.001.mm;ranges.last[1]=hi
        else;ranges<<[lo,hi];end
      end
      specs=ranges.flat_map do |lo,hi|
        next [] if (hi-lo).to_mm<2*c[:back_margin]
        CarcassJoineryLayout.back_row(c,(hi-lo).to_mm).map { |z| {y:y,z:lo+z.mm,diameter:c[:screw_diameter],depth:c[:screw_depth],kind: :back_screw} }
      end
      # Check the full screw cross-section against real end-face edges, including
      # inner loops. Work in world units so scaled/reflected cabinets stay safe.
      radius=c[:screw_diameter].mm/2
      specs.select! do |h|
        point=Geom::Point3d.new(x,y,h[:z]).transform(p[:frame]);q=point.transform(b[:world].inverse)
        faces.any? do |f|
          good.include?(f.classify_point(q)) && f.edges.all? do |edge|
            a,d=edge.vertices.map { |v| v.position.transform(b[:world]) };v=d-a
            t=[[((point-a).dot(v)/v.dot(v)),0.0].max,1.0].min
            nearest=Geom::Point3d.new(a.x+v.x*t,a.y+v.y*t,a.z+v.z*t)
            point.distance(nearest).to_f>=radius.to_f-0.001.mm
          end
        end
      end
      raise l('Na krawędzi pleców nie ma miejsca na śruby z ustawionymi marginesami. Sprawdź wycięcia i marginesy.','No room for back screws with the configured end margins. Check the cutouts and margins.') if specs.empty?
      raise l('Za dużo śrub pleców; zwiększ rozstaw.','Too many back screws; increase the spacing.') if specs.length>500
      specs
    end
    def plan(path,c=settings,model=Sketchup.active_model)
      c=validate(c);b=board(path,model)
      raise l('Kliknij wieniec, półkę stałą lub plecy z odpowiednim tagiem z ustawień.','Click a rail, fixed shelf or back with the corresponding configured tag.') unless eligible?(b)
      raise l('Element lub jego rodzic są zablokowane.','A panel or its parent is locked.') if path.any?(&:locked?)
      all=surroundings(path,model)
      return CornerCabinet.joint_plan(path,c,model,b,all) if CornerCabinet.corner?(all,b)
      p=frame_for(b,all);front_high=front_high?(p,all);sb=p[:bounds]
      holes=[]
      p[:sides].each_with_index do |(_,side,pb,x),i|
        raise l('Bok lub jego rodzic są zablokowane.','A side panel or its parent is locked.') if side[:path].any?(&:locked?)
        direction=front_high ? -1 : 1
        if back?(b)
          # Recessed backs need their own physical thickness centre, rather
          # than a fixed distance measured from the side panel's rear edge.
          y=sb.center.y
          raise l('Oś śrub nie mieści się w grubości pleców.','The screw axis does not fit within the back thickness.') unless y-c[:screw_diameter].mm/2>sb.min.y && y+c[:screw_diameter].mm/2<sb.max.y
          specs=back_specs(b,p,i,c)
        else
          # The drill fence references the source rail/fixed shelf, not the
          # receiving cabinet side. Keep the 32 mm pattern attached to that
          # panel when it is recessed or moved relative to the side front.
          front=front_high ? sb.max.y : sb.min.y
          dist=[0.0,(sb.max.y-sb.min.y).to_mm]
          z=sb.center.z
          # The optional signed correction is inward for the bottom/top rail.
          cabinet_top=p[:sides].map { |_,_,box,_| box.max.z }.min
          upper_rail=(sb.max.z-cabinet_top).abs.to_mm<2.0
          z+=(upper_rail ? -1 : 1)*c[:centre_offset].mm
          specs=CarcassJoineryLayout.row(c,*dist).map { |h| h.merge(y:front+direction*h[:position].mm,z:z) }
          raise l('Na elemencie nie mieści się żadne aktywne wrzeciono.','No active spindle fits on this panel.') if specs.empty?
          radius=specs.map { |h| h[:diameter] }.max.mm/2
          raise l('Oś i średnica otworu nie mieszczą się w grubości elementu.','The drilling axis and diameter do not fit within the source thickness.') unless z-radius>sb.min.z && z+radius<sb.max.z
        end
        specs.each do |h|
          hole=h.merge(panel:side,point:Geom::Point3d.new(x,h[:y],h[:z]).transform(p[:frame]),normal:i==0 ? p[:width].reverse : p[:width],tangent:p[:depth_axis])
          check_circle(hole);holes<<hole
        end
      end
      holes.concat(back_rail_holes(b,p,all,c,front_high)) if back?(b)
      p.merge(holes:holes,settings:c)
    end

    # Additional screws enter the back from outside and meet only real bottom /
    # top rails. A front stretcher does not count as a top rail behind the back.
    def back_rail_holes(back,p,all,c,front_high)
      sb=p[:bounds];inner=front_high ? sb.max.y : sb.min.y
      outer=front_high ? sb.min.y : sb.max.y
      normal=front_high ? p[:depth_axis] : p[:depth_axis].reverse
      bottom=p[:sides].map { |_,_,box,_|box.min.z }.max
      top=p[:sides].map { |_,_,box,_|box.max.z }.min
      holes=[]
      all.select { |b| horizontal?(b) }.each do |rail|
        rb=ShelfPins.projected(rail[:points],p[:inverse])
        low=(rb.min.z-bottom).abs<2.mm;high=(rb.max.z-top).abs<2.mm
        next unless low || high
        rear=front_high ? rb.min.y : rb.max.y
        next unless (rear-inner).abs<=2.mm
        lo=[rb.min.x,sb.min.x].max;hi=[rb.max.x,sb.max.x].min
        next if (hi-lo).to_mm<2*c[:back_margin]
        raise l('Wieniec lub jego rodzic są zablokowane.','A rail or its parent is locked.') if rail[:path].any?(&:locked?)
        z=rb.center.z+(high ? -1 : 1)*c[:centre_offset].mm
        CarcassJoineryLayout.back_row(c,(hi-lo).to_mm).each do |offset|
          x=lo+offset.mm
          # Check real rail geometry too, so notches do not receive screws.
          target={panel:rail,point:Geom::Point3d.new(x,rear,z).transform(p[:frame]),normal:normal,tangent:p[:width],diameter:c[:screw_diameter],depth:0}
          begin;check_circle(target);rescue RuntimeError;next;end
          h={panel:back,point:Geom::Point3d.new(x,outer,z).transform(p[:frame]),normal:normal,tangent:p[:width],diameter:c[:screw_diameter],depth:c[:screw_depth],kind:high ? :back_top_screw : :back_bottom_screw}
          check_circle(h)
          holes<<h unless holes.any? { |v|v[:point].distance(h[:point])<0.01.mm }
        end
      end
      holes
    end

    # Plan first, then isolate paths by temporary tokens. The source and receiving
    # side panels may be shared through several cabinet definitions.
    def apply(paths,c=settings,model=Sketchup.active_model,operation:true)
      c=validate(c);paths=paths.uniq { |p| p.map(&:persistent_id) }
      raise l('Nie wybrano paneli.','No panels selected.') if paths.empty?
      raise l('Najpierw utwórz unikatową otwartą szafkę.','Make the open cabinet unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      plans=paths.map { |p| plan(p,c,model) }
      token=SecureRandom.uuid;marked=[];specs=[];created=0;existing_count=0
      model.start_operation(l('ELFIS — Kołki i śruby','ELFIS — Carcass dowels and screws'),true) if operation
      begin
        encode=->(path) do
          path.each { |e| e.set_attribute('ElfisJoineryTemp',token,e.persistent_id.to_s);marked<<e }
          [path.first,path.map { |e| e.get_attribute('ElfisJoineryTemp',token) }]
        end
        plans.each do |p|
          receivers=p[:holes].group_by { |h| h[:panel][:path] }
          # Keep an empty back receiver to clear old exterior rows if a top /
          # bottom rail has been removed since the previous application.
          receivers[p[:shelf][:path]] ||= [] if back?(p[:shelf])
          specs<<[encode.call(p[:shelf][:path]),receivers.map { |path,hs| [encode.call(path),hs] }]
        end
        resolve=->(spec) do
          root,ids=spec;path=[root]
          ids.drop(1).each do |id|
            child=path.last.definition.entities.find { |e| instance?(e) && e.get_attribute('ElfisJoineryTemp',token)==id }
            raise 'Panel path changed.' unless child;path<<child
          end
          path
        end
        specs.each do |source_spec,receivers|
          source_path=BastillePodmienFront.unique_path(resolve.call(source_spec));source=source_path.last
          source.make_unique if source.definition.instances.length>1
          owner=source.get_attribute(DICT,'owner_key') || SecureRandom.uuid
          siblings=source_path.length>1 ? source_path[-2].definition.entities : model.active_entities
          owner=SecureRandom.uuid if siblings.any? { |e| instance?(e) && e!=source && e.get_attribute(DICT,'owner_key')==owner }
          source.set_attribute(DICT,'owner_key',owner)
          receivers.each do |side_spec,holes|
            side_path=BastillePodmienFront.unique_path(resolve.call(side_spec));side=side_path.last
            side.make_unique if side.definition.instances.length>1
            b=board(side_path,model)
            # Update only our own vectors; imported holes and shelf supports stay.
            side.definition.entities.grep(Sketchup::Group).select { |g| g.get_attribute(DICT,'owner_key')==owner }.each(&:erase!)
            old=ShelfPins.circular_holes(b)
            holes.each do |h|
              if old.any? { |v| v[:center].distance(h[:point])<0.05.mm && (v[:diameter]-h[:diameter]).abs<0.01 && (v[:depth]-h[:depth]).abs<0.01 }
                existing_count+=1;next
              end
              name=tag(h[:diameter],h[:depth]);depth_tag=model.layers[name]||model.layers.add(name)
              group=side.definition.entities.add_group;group.name=name
              operation_tag=defined?(StudioSettings) ? StudioSettings.operation_tag : 'Blum Operations'
              group.layer=model.layers[operation_tag]||model.layers.add(operation_tag)
              group.entities.add_circle(ORIGIN,Z_AXIS,h[:diameter].mm/2,24).each { |edge| edge.layer=depth_tag }
              normal=h[:normal];tangent=h[:tangent]
              group.transformation=b[:world].inverse*Geom::Transformation.axes(h[:point],tangent,normal.cross(tangent).normalize,normal)
              group.set_attribute(DICT,'owner_key',owner);group.set_attribute(DICT,'kind',h[:kind].to_s)
              group.set_attribute(DICT,'diameter',h[:diameter]);group.set_attribute(DICT,'depth',h[:depth]);created+=1
              old<<{center:h[:point],diameter:h[:diameter],depth:h[:depth]}
            end
          end
        end
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisJoineryTemp',token) if instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisJoineryTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation;raise
      end
      model.active_view.invalidate;{created:created,existing:existing_count,panels:paths.length}
    end
    # Search the nearest containing assembly. UUID ownership survives moving a
    # source panel and Make Unique; duplicate owners are never guessed between.
    def removal_groups(path,model=Sketchup.active_model)
      owner=path.last.get_attribute(DICT,'owner_key');return [] unless owner
      (path.length-1).downto(0) do |n|
        parent=path.take(n);entities=parent.empty? ? model.active_entities : parent.last.definition.entities
        world=parent.inject(model.edit_transform) { |tr,e| tr*e.transformation }
        targets=[];sources=[];receiving_sides=0;walk=nil
        walk=->(nodes,tr,stack) do
          e=nodes.last;next if !e.valid? || stack.include?(e.definition)
          tw=tr*e.transformation
          b=board(nodes,model)
          receiving_sides+=1 if b && !back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001
          if e.get_attribute(DICT,'owner_key')==owner
            if e.is_a?(Sketchup::Group) && e.get_attribute(DICT,'kind')
              targets<<{path:nodes,point:e.definition.bounds.center.transform(tw)};next
            else;sources<<nodes
            end
          end
          e.definition.entities.each { |child| walk.call(nodes+[child],tw,stack+[e.definition]) if instance?(child) }
        end
        entities.each { |e| walk.call(parent+[e],world,[]) if instance?(e) }
        if targets.empty?
          return [] if sources.length==1 && sources.first==path && receiving_sides>=2
          next
        end
        raise l('Kilka paneli ma to samo powiązanie wierceń. Nie usunięto żadnych grup.','Several panels share this drilling association. No groups were removed.') unless sources.length==1 && sources.first==path
        return targets
      end
      []
    end

    def remove(paths,model=Sketchup.active_model,operation:true)
      paths=paths.uniq { |p| p.map(&:persistent_id) }
      raise l('Nie wybrano paneli.','No panels selected.') if paths.empty?
      raise l('Najpierw utwórz unikatową otwartą szafkę.','Make the open cabinet unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      paths.each do |path|
        raise l('Kliknij wieniec, półkę stałą lub plecy.','Click a rail, fixed shelf or back.') unless eligible?(board(path,model))
        raise l('Element lub jego rodzic są zablokowane.','A panel or its parent is locked.') if path.any?(&:locked?)
      end
      targets=paths.flat_map { |p| removal_groups(p,model) }.uniq { |h| h[:path].map(&:persistent_id) }
      raise l('Wiercenie lub jego rodzic są zablokowane.','A drilling group or its parent is locked.') if targets.any? { |h| h[:path].any?(&:locked?) }
      return {removed:0,panels:paths.length} if targets.empty?
      token=SecureRandom.uuid;marked=[];removed=0
      model.start_operation(l('ELFIS — Usuń kołki i śruby','ELFIS — Remove dowels and screws'),true) if operation
      begin
        targets.each { |h| h[:path].each { |e| e.set_attribute('ElfisJoineryTemp',token,e.persistent_id.to_s);marked<<e } }
        specs=targets.map { |h| [h[:path].first,h[:path].map { |e| e.get_attribute('ElfisJoineryTemp',token) }] }
        specs.each do |root,ids|
          path=[root]
          ids.drop(1).each do |id|
            child=path.last.definition.entities.find { |e| instance?(e) && e.get_attribute('ElfisJoineryTemp',token)==id }
            raise 'Drilling path changed.' unless child;path<<child
          end
          path=BastillePodmienFront.unique_path(path);path.last.erase!;removed+=1
        end
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisJoineryTemp',token) if instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisJoineryTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation;raise
      end
      model.active_view.invalidate;{removed:removed,panels:paths.length}
    end

    def show_settings(tool=nil)
      if @dialog && @dialog.visible?;@dialog.bring_to_front;return;end
      @dialog=UI::HtmlDialog.new(dialog_title:l('ELFIS — Kołki i śruby','ELFIS — Dowels and screws'),preferences_key:'ElfisCarcassJoinerySettings',width:680,height:830,min_width:600,min_height:620,resizable:true)
      dialog=@dialog;dialog.set_file(File.join(__dir__,'carcass_joinery_settings.html'))
      dialog.add_action_callback('joinery') do |_,json|
        begin
          data=JSON.parse(json,symbolize_names:true)
          case data[:action]
          when 'ready';dialog.execute_script("setSettings(#{JSON.generate(settings.merge(language:BastillePodmienFront.language))})")
          when 'save'
            c=validate(data.select { |k,v| defaults.key?(k) });c.each { |k,v| Sketchup.write_default(PREF,k.to_s,v) }
            tool.update_settings(c) if tool;dialog.close
          when 'cancel';dialog.close
          end
        rescue => error;dialog.execute_script("showError(#{JSON.generate(error.message)})")
        end
      end
      dialog.set_on_closed { @dialog=nil if @dialog.equal?(dialog) };dialog.show
    end
    def selected_paths(model)
      model.selection.select { |e| instance?(e) }.flat_map do |e|
        b=board([e],model)
        b ? (eligible?(b) ? [[e]] : []) : panels(e,model).select { |p| fixed?(p)||back?(p) }.map { |p| p[:path] }
      end
    end
    def status(r)
      return l("Panele: #{r[:panels]}. Usunięto grup ELFIS: #{r[:removed]}. Importowane wiercenia zachowano.","Panels: #{r[:panels]}. ELFIS groups removed: #{r[:removed]}. Imported drilling preserved.") if r.key?(:removed)
      l("Panele: #{r[:panels]}. Dodano: #{r[:created]}, istniejące: #{r[:existing]}.","Panels: #{r[:panels]}. Added: #{r[:created]}, existing: #{r[:existing]}.")
    end
    def activate(remove:false)
      m=Sketchup.active_model;paths=selected_paths(m)
      result=remove ? self.remove(paths,m) : apply(paths,settings,m) unless paths.empty?
      # Keep click mode available after a batch operation. A selected assembly
      # must not mask the nested panel under the cursor.
      m.selection.clear
      m.select_tool(Tool.new(remove ? nil : validate(settings),remove:remove))
      Sketchup.set_status_text(status(result)) if result
    rescue => e;UI.messagebox(e.message)
    end
    class Tool
      include DrillingToolModifiers
      def initialize(c,remove:false);@settings=c;init_drilling_modifiers(:joint,remove);end
      def update_settings(c);@settings=c;@path=nil;@plan=nil;@signature=nil;Sketchup.active_model.active_view.invalidate;end
      def activate
        show_drilling_mode
      end
      def onMouseMove(flags,x,y,view)
        @drilling_x=x;@drilling_y=y;set_drilling_mode(flags)
        signature=[x,y,Sketchup.active_model.active_path,@drilling_mode];return if @signature==signature;@signature=signature
        found=nil;ph=view.pick_helper;ph.do_pick(x,y)
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e| CarcassJoinery.instance?(e) }
          raw.length.downto(1) { |n| candidate=raw.take(n);if CarcassJoinery.eligible?(CarcassJoinery.board(candidate));found=candidate;break;end }
          break if found
        end
        if found
          unless @path==found && @plan && @plan_mode==@drilling_mode
            @plan=build_drilling_plan(found);@plan_mode=@drilling_mode
          end
          @path=found
        else;@path=nil;@plan=nil
        end
        view.invalidate
      rescue => e;@path=nil;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def draw(view)
        return unless @plan
        inverse=Sketchup.active_model.edit_transform.inverse;b=@plan[:shelf]
        pairs=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
        points=pairs.flat_map { |a,b2| [a,b2].map { |i| q=view.screen_coords(b[:bb].corner(i).transform(b[:world]).transform(inverse));Geom::Point3d.new(q.x,q.y,0) } }
        view.drawing_color=@remove ? 'Red' : (@refresh ? 'MediumSeaGreen' : 'DodgerBlue');view.line_width=3;view.draw2d(GL_LINES,points)
        @plan[:holes].each do |h|
          view.drawing_color=@remove ? 'Red' : (@refresh ? 'MediumSeaGreen' : (h[:kind]==:dowel ? 'LimeGreen' : 'OrangeRed'));q=view.screen_coords(h[:point].transform(inverse))
          view.draw2d(GL_LINE_LOOP,(0...16).map { |i| a=2*Math::PI*i/16;Geom::Point3d.new(q.x+4*Math.cos(a),q.y+4*Math.sin(a),0) })
        end
      end
      def onLButtonDown(flags,x,y,view)
        @signature=nil;onMouseMove(flags,x,y,view);return unless @path
        perform_drilling_action(@path);@path=nil;@plan=nil;@signature=nil;view.invalidate
      rescue => e;UI.messagebox(e.message)
      end
      def getMenu(menu);return if @remove;menu.add_item(CarcassJoinery.l('Ustawienia kołków i śrub…','Dowel and screw settings…')) { CarcassJoinery.show_settings(self) };end
      def onCancel(reason,view);@plan=nil;@path=nil;Sketchup.active_model.select_tool(nil) if reason==0;view.invalidate;end
      def deactivate(view);clear_drilling_modifiers;view.invalidate;end
    end
    def install
      unless @command
      @command=UI::Command.new('ELFIS — Dowels and Screws / Kołki i śruby') { activate }
      @command.tooltip=l('Wiercenia w bokach: wieńce, półki stałe i plecy','Side-panel drilling: rails, fixed shelves and backs')
      @command.small_icon=File.join(__dir__,'carcass_joinery.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command)
      toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
      end
      unless @remove_command
        @remove_command=UI::Command.new('ELFIS — Remove Dowels and Screws / Usuń kołki i śruby') { activate(remove:true) }
        @remove_command.tooltip=l('Usuń wiercenia kołków i śrub z klikniętego lub zaznaczonych paneli','Remove dowel and screw drilling from clicked or selected panels')
        @remove_command.small_icon=File.join(__dir__,'carcass_joinery_remove.svg');@remove_command.large_icon=@remove_command.small_icon
        UI.menu('Extensions').add_item(@remove_command)
      end
      @command.tooltip=l('Kołki i śruby: klik dodaje · Alt usuwa · Ctrl aktualizuje po przesunięciu panelu','Dowels and screws: click adds · Alt removes · Ctrl updates after moving a panel')
    end
  end
end
