# encoding: UTF-8
# Shelf support vectors. No solid cutting and no automatic geometry observers.
require 'securerandom'
require_relative 'corner_cabinet'
require_relative 'drilling_tool_modifiers'
module Elfis
  module ShelfPins
    extend self
    PREF='ELFIS Shelf Pins' unless const_defined?(:PREF)
    DICT='ElfisShelfPins' unless const_defined?(:DICT)

    def l(pl,en)
      BastillePodmienFront.l(pl,en)
    end

    def instance?(e)
      e.is_a?(Sketchup::Group)||e.is_a?(Sketchup::ComponentInstance)
    end

    def defaults
      {diameter:5.0,depth:12.0,front:57.0,back:37.0,below:2.5,pitch:32.0,above:1,under:1,reuse:true}
    end

    def settings
      defaults.each_with_object({}) { |(k,v),h| h[k]=Sketchup.read_default(PREF,k.to_s,v) }
    end

    def validate(c)
      c=defaults.merge(c)
      %i[diameter depth front back below pitch].each { |k| c[k]=Float(c[k]); raise l('Nieprawidłowy wymiar.','Invalid dimension.') unless c[k].finite? }
      raise l('Średnica i głębokość muszą być dodatnie.','Diameter and depth must be positive.') unless c[:diameter]>0 && c[:depth]>0
      raise l('Odsunięcia nie mogą być ujemne; rozstaw musi być dodatni.','Offsets cannot be negative; spacing must be positive.') unless c[:front]>=0 && c[:back]>=0 && c[:below]>=0 && c[:pitch]>0
      %i[above under].each do |k|
        number=Float(c[k]);raise l('Liczba otworów musi być całkowita od 0 do 10.','Additional hole counts must be whole numbers from 0 to 10.') unless number.finite? && number==number.to_i && number>=0 && number<=10
        c[k]=number.to_i
      end
      c
    end

    def tag_name(c)
      "D#{c[:diameter].to_f}_DEPTH#{c[:depth].to_f}"
    end

    def show_settings(tool=nil)
      @settings_tool=tool
      if @settings_dialog && @settings_dialog.visible?
        @settings_dialog.bring_to_front;return
      end
      dialog=UI::HtmlDialog.new(dialog_title:l('ELFIS — Ustawienia podpórek','ELFIS — Shelf pin settings'),preferences_key:'ElfisShelfPinSettings',width:540,height:740,min_width:480,min_height:590,resizable:true)
      @settings_dialog=dialog
      dialog.set_file(File.join(__dir__,'shelf_pins_settings.html'))
      dialog.add_action_callback('shelf_pin_settings') do |_,json|
        begin
          data=JSON.parse(json,symbolize_names:true)
          case data[:action]
          when 'ready'
            dialog.execute_script("setSettings(#{JSON.generate(settings.merge(language:BastillePodmienFront.language))})")
          when 'save'
            keys=%i[diameter depth front back below pitch above under reuse]
            c=validate(data.select { |k,v| keys.include?(k) })
            c.each { |k,v| Sketchup.write_default(PREF,k.to_s,v) }
            @settings_tool.update_settings(c) if @settings_tool
            dialog.close
          when 'cancel' then dialog.close
          end
        rescue => error
          dialog.execute_script("showError(#{JSON.generate(error.message)})")
        end
      end
      dialog.set_on_closed { @settings_dialog=nil if @settings_dialog.equal?(dialog);@settings_tool=nil }
      dialog.show
    end

    def board(path,model=Sketchup.active_model)
      e=path.last
      return nil unless instance?(e) && e.valid? && (defined?(StudioSettings) ? StudioSettings.panel?(e) : e.layer.name.downcase=='body')
      faces=e.definition.entities.grep(Sketchup::Face)
      return nil if faces.length<6
      bb=Geom::BoundingBox.new
      faces.each { |f| f.vertices.each { |v| bb.add(v.position) } }
      world=path.inject(model.edit_transform) { |tr,i| tr*i.transformation }
      vectors=[X_AXIS,Y_AXIS,Z_AXIS].map { |v| v.transform(world) }
      return nil if vectors.any? { |v| v.length<1e-8 }
      axes=vectors.map(&:normalize)
      return nil unless [[0,1],[0,2],[1,2]].all? { |a,b| axes[a].dot(axes[b]).abs<1e-5 }
      lengths=[bb.width,bb.height,bb.depth].each_with_index.map { |v,i| v*vectors[i].length }
      thin=(0..2).min_by { |i| lengths[i] }
      return nil unless lengths[thin]>0.1.mm && lengths[thin]<=80.mm
      {path:path,entity:e,world:world,bb:bb,faces:faces,axes:axes,thin:thin,lengths:lengths,points:(0..7).map { |i| bb.corner(i).transform(world) }}
    end

    def shelf?(b)
      b && (!defined?(StudioSettings)||StudioSettings.role?(b[:entity],:shelves)) && b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999 && b[:lengths].sort[1]>80.mm && ![b[:entity].name,b[:entity].definition.name].join(' ').match?(/fixed\s*shelf|p[oó]łka\s*stała|cabinet\s*(base|top)|cross\s*member|trawers|wieniec/i)
    end

    def panels(root,model=Sketchup.active_model)
      out=[];visit=nil
      visit=->(path,stack) do
        e=path.last;next if !e.valid? || e.hidden? || !e.layer.visible? || stack.include?(e.definition)
        b=board(path,model);out<<b if b
        # A board's nested geometry is machining or hardware, not another panel.
        next if b
        e.definition.entities.each { |child| visit.call(path+[child],stack+[e.definition]) if instance?(child) }
      end
      visit.call([root],[]);out
    end

    def projected(points,inverse)
      bb=Geom::BoundingBox.new;points.each { |p| bb.add(p.transform(inverse)) };bb
    end

    def circular_holes(b)
      result=[];visit=nil
      visit=->(entities,tr,stack,tag) do
        entities.grep(Sketchup::Edge).map(&:curve).compact.uniq.grep(Sketchup::ArcCurve).each do |curve|
          next unless curve.edges.length>=8 && (curve.end_angle-curve.start_angle-2*Math::PI).abs<1e-4
          edge_tag=curve.edges.map { |e| e.layer.name }.find { |n| n.match?(/D[\d.]+_DEPTH/i) }
          name=edge_tag || tag
          match=name.to_s.match(/D([\d.]+)_DEPTH_?([\d.]+)/i);next unless match
          result<<{center:curve.center.transform(tr),diameter:match[1].to_f,depth:match[2].to_f}
        end
        entities.each do |child|
          next unless instance?(child) && !stack.include?(child.definition)
          visit.call(child.definition.entities,tr*child.transformation,stack+[child.definition],child.name)
        end
      end
      visit.call(b[:entity].definition.entities,b[:world],[],nil);result
    end

    def plan(path,c=settings,model=Sketchup.active_model)
      c=validate(c);s=board(path,model)
      raise l('Wskaż poziomą półkę regulowaną z tagiem ustawionym dla półek.','Point to a horizontal adjustable shelf with a configured shelf tag.') unless shelf?(s)
      raise l('Element lub szafka są zablokowane.','A panel or cabinet is locked.') if path.any?(&:locked?)
      all=panels(path.first,model)
      # Loose parts at model root can also form a cabinet.
      all=model.active_entities.select { |e| instance?(e) }.flat_map { |e| panels(e,model) } if path.length==1
      return CornerCabinet.pin_plan(path,c,model,s,all) if CornerCabinet.corner?(all,s)
      up=s[:axes][s[:thin]].clone;up.reverse! if up.dot(Z_AXIS)<0
      attempts=[]
      ((0..2).to_a-[s[:thin]]).each do |wi|
        width=s[:axes][wi];depth=up.cross(width).normalize
        frame=Geom::Transformation.axes(ORIGIN,width,depth,up);inv=frame.inverse
        sb=projected(s[:points],inv)
        eligible=all.reject { |b| b[:entity]==s[:entity] }.select { |b| (!defined?(StudioSettings)||StudioSettings.role?(b[:entity],:sides)) && b[:axes][b[:thin]].dot(width).abs>0.999 }
        sides=[-1,1].map do |sign|
          edge=sign<0 ? sb.min.x : sb.max.x
          fits=eligible.filter_map do |b|
            pb=projected(b[:points],inv);inner=sign<0 ? pb.max.x : pb.min.x
            delta=(inner-edge).abs
            next unless delta<=2.mm && pb.min.y<=sb.min.y+0.1.mm && pb.max.y>=sb.max.y-0.1.mm && pb.min.z<sb.min.z && pb.max.z>sb.max.z
            [delta,b,pb,inner]
          end.sort_by(&:first)
          next nil if fits.empty?
          raise l('Niejednoznaczny bok przy półce.','More than one side panel matches this shelf.') if fits.length>1 && (fits[0][0]-fits[1][0]).abs<0.01.mm
          fits.first
        end
        attempts<<{shelf:s,frame:frame,inverse:inv,bounds:sb,sides:sides,width:width,depth_axis:depth,up:up} if sides.all?
      end
      raise l('Nie znaleziono dwóch przylegających boków.','Could not find two adjacent side panels.') unless attempts.length==1
      p=attempts.first;sb=p[:bounds];z=sb.min.z-c[:below].mm
      # Orient front using Facade geometry in the same cabinet, where available.
      facade_centres=[];scan=nil
      scan=->(entities,tr,stack) do
        entities.each do |e|
          next unless instance?(e) && !stack.include?(e.definition)
          tw=tr*e.transformation
          if defined?(StudioSettings) ? StudioSettings.role?(e,:facades) : e.layer.name.downcase=='facade'
            facade_centres<<e.definition.bounds.center.transform(tw).transform(p[:inverse]).y
          elsif e.definition.entities.grep(Sketchup::Face).empty?
            scan.call(e.definition.entities,tw,stack+[e.definition])
          end
        end
      end
      parent_world=model.edit_transform
      scan.call([path.first],parent_world,[])
      front_high=facade_centres.empty? || facade_centres.sum/facade_centres.length>sb.center.y
      ys=front_high ? [sb.max.y-c[:front].mm,sb.min.y+c[:back].mm] : [sb.min.y+c[:front].mm,sb.max.y-c[:back].mm]
      if c[:reuse]
        rowsets=p[:sides].map do |_,b,_,_|
          circular_holes(b).select { |h| (h[:diameter]-c[:diameter]).abs<0.01 && (h[:depth]-c[:depth]).abs<0.01 }.filter_map do |h|
            q=h[:center].transform(p[:inverse]);q.y if (q.z-z).abs<0.05.mm && q.y>sb.min.y && q.y<sb.max.y
          end.sort.uniq { |y| (y.to_mm*100).round }
        end
        ys=rowsets.first if rowsets.all? { |r| r.length==2 } && rowsets[0].zip(rowsets[1]).all? { |a,b| (a-b).abs<0.05.mm }
      end
      r=c[:diameter].mm/2
      raise l('Półka jest za płytka dla ustawionych odsunięć.','The shelf is too shallow for these offsets.') unless (ys[0]-ys[1]).abs>2*r && ys.all? { |y| y-r>sb.min.y && y+r<sb.max.y }
      holes=[]
      p[:sides].each_with_index do |(_,b,pb,x),side|
        raise l('Głębokość wiercenia przekracza grubość boku.','Drill depth must be less than side thickness.') unless c[:depth].mm<b[:lengths][b[:thin]]-0.01.mm
        raise l('Bok lub jego grupa są zablokowane.','A side panel or its container is locked.') if b[:path].any?(&:locked?)
        ys.each do |y|
          (-c[:under]..c[:above]).each do |step|
            zz=z+step*c[:pitch].mm
            raise l('Otwór wypada poza bokiem szafki.','A hole would lie outside the side panel.') unless zz-r>pb.min.z && zz+r<pb.max.z
            point=Geom::Point3d.new(x,y,zz).transform(p[:frame])
            local=point.transform(b[:world].inverse)
            face=b[:faces].find { |f| local.distance_to_plane(f.plane)<0.02.mm && [Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex].include?(f.classify_point(local)) }
            raise l('Nie znaleziono powierzchni boku pod otworem.','No side-panel surface at a hole position.') unless face
            fits=(0...16).all? do |i|
              angle=2*Math::PI*i/16
              q=Geom::Point3d.new(x,y+r*Math.cos(angle),zz+r*Math.sin(angle)).transform(p[:frame]).transform(b[:world].inverse)
              [Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex].include?(face.classify_point(q))
            end
            raise l('Okrąg przecina krawędź lub wycięcie boku.','A circle crosses a panel edge or cutout.') unless fits
            holes<<{panel:b,point:point,normal:side==0 ? p[:width].reverse : p[:width],tangent:p[:depth_axis]}
          end
        end
      end
      p.merge(holes:holes,settings:c)
    end

    def apply(paths,c=settings,model=Sketchup.active_model,operation:true)
      c=validate(c)
      raise l('Otwarta szafka ma wiele kopii. Najpierw Utwórz unikatowy.','The open cabinet has multiple copies. Make it unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      paths=paths.uniq { |p| p.map(&:persistent_id) }
      raise l('Nie wybrano półek.','No shelves selected.') if paths.empty?
      paths.each { |p| plan(p,c,model) }
      model.start_operation(l('ELFIS — Podpórki półek','ELFIS — Shelf pin rows'),true) if operation
      count=0;skipped=0;token_key="shelves-#{Time.now.to_f}";marked=[]
      begin
        paths.map(&:first).uniq.each { |root| upgrade_owners(root) }
        paths.each { |path| path.each { |e| e.set_attribute('ElfisShelfTemp',token_key,e.persistent_id.to_s);marked<<e } }
        specs=paths.map { |p| [p.first,p.map { |e| e.get_attribute('ElfisShelfTemp',token_key) }] }
        specs.each do |root,tokens|
          path=[root]
          tokens.drop(1).each { |token| path<<path.last.definition.entities.find { |e| instance?(e) && e.get_attribute('ElfisShelfTemp',token_key)==token } }
          raise 'Shelf path changed.' if path.any?(&:nil?)
          path=BastillePodmienFront.unique_path(path)
          p=plan(path,c,model)
          if p[:corner] && !path.last.get_attribute(DICT,'owner_key') && defined?(DrillingEditor)
            scan=DrillingEditor.scan(roots:[path.first],model:model)
            ids=scan[:rows].select { |h|h[:kind]==:pin && !h[:owned] && h[:source] && h[:source][:path]==path }.map { |h|h[:id] }
            unless ids.empty?
              DrillingEditor.apply(scan,ids,{},update:false,operation:false)
              p=plan(path,c,model)
            end
          end
          path.last.set_attribute(DICT,'corner_pattern',JSON.generate(p[:corner_pattern])) if p[:corner_pattern]
          source=path.map(&:persistent_id).join('/')
          owned_sources=removal_groups(path,model).map { |g| g[:path].last.get_attribute(DICT,'source') }.uniq
          owner_key=path.last.get_attribute(DICT,'owner_key') || SecureRandom.uuid
          siblings=path.length>1 ? path[-2].definition.entities : model.active_entities
          owner_key=SecureRandom.uuid if siblings.any? { |e| instance?(e) && e!=path.last && e.get_attribute(DICT,'owner_key')==owner_key }
          path.last.set_attribute(DICT,'owner_key',owner_key)
          p[:holes].group_by { |h| h[:panel][:entity] }.each_value do |holes|
            side_path=BastillePodmienFront.unique_path(holes.first[:panel][:path])
            panel=side_path.last;panel.make_unique if panel.definition.instances.length>1
            pb=board(side_path,model)
            panel.definition.entities.grep(Sketchup::Group).select { |g| owned_sources.include?(g.get_attribute(DICT,'source')) }.each(&:erase!)
            existing=circular_holes(pb)
            operation_tag=defined?(StudioSettings) ? StudioSettings.operation_tag : 'Blum Operations'
            group_tag=model.layers[operation_tag]||model.layers.add(operation_tag)
            holes.each do |h|
              depth=h.fetch(:depth,c[:depth]);hole_tag=tag_name(c.merge(depth:depth));depth_tag=model.layers[hole_tag]||model.layers.add(hole_tag)
              if existing.any? { |old| old[:center].distance(h[:point])<0.05.mm && (old[:diameter]-c[:diameter]).abs<0.01 && (old[:depth]-depth).abs<0.01 }
                skipped+=1;next
              end
              group=panel.definition.entities.add_group
              group.name=hole_tag;group.layer=group_tag
              edges=group.entities.add_circle(ORIGIN,Z_AXIS,c[:diameter].mm/2,24)
              edges.each { |e| e.layer=depth_tag }
              tangent=h[:tangent];normal=h[:normal];other=normal.cross(tangent).normalize
              placement=Geom::Transformation.axes(h[:point],tangent,other,normal)
              group.transformation=pb[:world].inverse*placement
              group.set_attribute(DICT,'source',source)
              group.set_attribute(DICT,'owner_key',owner_key)
              group.set_attribute(DICT,'diameter',c[:diameter]);group.set_attribute(DICT,'depth',depth)
              count+=1
            end
          end
        end
        # Remove temporary markers copied by Make Unique, including old definitions.
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisShelfTemp',token_key) if instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisShelfTemp',token_key) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation
        raise
      end
      model.active_view.invalidate
      {created:count,existing:skipped,shelves:paths.length}
    end

    # Ownership is read before Make Unique. Its temporary path markers follow
    # copied entities, so deleting one cabinet occurrence cannot alter its twin.
    # The final persistent ID also matches when entering/leaving edit contexts.
    def removal_groups(path,model=Sketchup.active_model)
      source_id=path.last.persistent_id.to_s
      parent=path[0...-1]
      entities=parent.empty? ? model.active_entities : parent.last.definition.entities
      parent_world=parent.inject(model.edit_transform) { |tr,e| tr*e.transformation }
      owner_key=path.last.get_attribute(DICT,'owner_key')
      sibling_ids=entities.select { |e| instance?(e) }.map { |e| e.persistent_id.to_s }
      roots=entities.select { |e| instance?(e) }
      result=[];visit=nil
      visit=->(nodes,tr,stack) do
        entity=nodes.last;next if stack.include?(entity.definition)
        world=tr*entity.transformation
        source=entity.get_attribute(DICT,'source')
        stored_id=source.to_s.split('/').last
        matches=stored_id==source_id || (owner_key && entity.get_attribute(DICT,'owner_key')==owner_key && !sibling_ids.include?(stored_id))
        if entity.is_a?(Sketchup::Group) && source && matches
          result<<{path:nodes,point:entity.definition.bounds.center.transform(world)}
          next
        end
        entity.definition.entities.each { |child| visit.call(nodes+[child],world,stack+[entity.definition]) if instance?(child) }
      end
      roots.each { |root| visit.call(parent+[root],parent_world,[]) }
      result
    end

    # Migrate older PID-only associations before a shared cabinet is copied.
    def upgrade_owners(root)
      owners={};groups=[];walk=nil
      walk=->(entity,stack) do
        next if stack.include?(entity.definition)
        b=entity.definition.entities
        source=entity.get_attribute(DICT,'source')
        groups<<entity if entity.is_a?(Sketchup::Group) && source
        if (defined?(StudioSettings) ? StudioSettings.role?(entity,:shelves) : entity.layer.name.downcase=='body') && b.grep(Sketchup::Face).length>=6
          owners[entity.persistent_id.to_s]=entity
        end
        b.each { |child| walk.call(child,stack+[entity.definition]) if instance?(child) }
      end
      walk.call(root,[])
      groups.each do |g|
        owner=owners[g.get_attribute(DICT,'source').split('/').last];next unless owner
        key=owner.get_attribute(DICT,'owner_key') || SecureRandom.uuid
        owner.set_attribute(DICT,'owner_key',key);g.set_attribute(DICT,'owner_key',key)
      end
    end

    def remove(paths,model=Sketchup.active_model,operation:true)
      raise l('Otwarta szafka ma wiele kopii. Najpierw Utwórz unikatowy.','The open cabinet has multiple copies. Make it unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      paths=paths.uniq { |path| path.map(&:persistent_id) }
      raise l('Nie wybrano półek.','No shelves selected.') if paths.empty?
      paths.each do |path|
        raise l('Wskaż półkę z tagiem ustawionym dla półek.','Point to a shelf with a configured shelf tag.') unless shelf?(board(path,model))
        raise l('Półka lub jej szafka są zablokowane.','A shelf or its cabinet is locked.') if path.any?(&:locked?)
      end
      targets=paths.flat_map { |path| removal_groups(path,model) }.uniq { |g| g[:path].map(&:persistent_id) }
      raise l('Grupa wierceń lub jej rodzic są zablokowane.','A drilling group or its parent is locked.') if targets.any? { |g| g[:path].any?(&:locked?) }
      return {removed:0,shelves:paths.length} if targets.empty?
      model.start_operation(l('ELFIS — Usuń podpórki półek','ELFIS — Remove shelf pin rows'),true) if operation
      token="remove-#{Time.now.to_f}";marked=[];removed=0
      begin
        targets.map { |g| g[:path].first }.uniq.each { |root| upgrade_owners(root) }
        targets.each { |g| g[:path].each { |e| e.set_attribute('ElfisShelfTemp',token,e.persistent_id.to_s);marked<<e } }
        specs=targets.map { |g| [g[:path].first,g[:path].map { |e| e.get_attribute('ElfisShelfTemp',token) }] }
        specs.each do |root,tokens|
          path=[root]
          tokens.drop(1).each { |key| path<<path.last.definition.entities.find { |e| instance?(e) && e.get_attribute('ElfisShelfTemp',token)==key } }
          raise 'Drilling path changed.' if path.any?(&:nil?)
          path=BastillePodmienFront.unique_path(path)
          path.last.erase!;removed+=1
        end
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisShelfTemp',token) if instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisShelfTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation
        raise
      end
      model.active_view.invalidate
      {removed:removed,shelves:paths.length}
    end

    def activate(remove:false)
      c=validate(settings)
      m=Sketchup.active_model
      paths=m.selection.select { |e| instance?(e) }.map { |e| [e] }.select { |path| shelf?(board(path,m)) }
      result=remove ? self.remove(paths,m) : apply(paths,c,m) unless paths.empty?
      m.selection.clear;m.select_tool(Tool.new(c,remove:remove))
      Sketchup.set_status_text(status(result)) if result
    rescue => e
      UI.messagebox(e.message)
    end

    def status(r)
      return l("Półki: #{r[:shelves]}. Usunięto grup ELFIS: #{r[:removed]}. Importowane wiercenia zachowano.","Shelves: #{r[:shelves]}. ELFIS groups removed: #{r[:removed]}. Imported drilling preserved.") if r.key?(:removed)
      l("Półki: #{r[:shelves]}. Dodano: #{r[:created]}, istniejące: #{r[:existing]}.","Shelves: #{r[:shelves]}. Added: #{r[:created]}, existing: #{r[:existing]}.")
    end

    class Tool
      include DrillingToolModifiers
      def initialize(c,remove:false);@settings=c;init_drilling_modifiers(:pin,remove);end
      def update_settings(c)
        @settings=c;@signature=nil;@plan=nil;@path=nil
        Sketchup.active_model.active_view.invalidate
      end
      def activate
        show_drilling_mode
      end
      def onMouseMove(flags,x,y,view)
        @drilling_x=x;@drilling_y=y;set_drilling_mode(flags)
        signature=[x,y,Sketchup.active_model.active_path,@drilling_mode]
        return if signature==@signature
        @signature=signature;found=nil
        ph=view.pick_helper;ph.do_pick(x,y)
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e| ShelfPins.instance?(e) }
          raw.length.downto(1) do |n|
            candidate=raw.take(n)
            next unless ShelfPins.shelf?(ShelfPins.board(candidate))
            found=candidate;break
          end
          break if found
        end
        if found
          unless @path==found && @plan && @plan_mode==@drilling_mode
            @plan=build_drilling_plan(found);@plan_mode=@drilling_mode
          end
          @path=found
        else
          @path=nil;@plan=nil
        end
        view.invalidate
      rescue => e
        @plan=nil;@path=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def draw(view)
        return unless @plan
        inverse=Sketchup.active_model.edit_transform.inverse
        bb=@plan[:shelf][:bb];tr=@plan[:shelf][:world]
        pairs=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
        points=pairs.flat_map { |a,b| [a,b].map { |i| q=view.screen_coords(bb.corner(i).transform(tr).transform(inverse));Geom::Point3d.new(q.x,q.y,0) } }
        view.drawing_color=@remove ? 'Red' : (@refresh ? 'MediumSeaGreen' : 'DodgerBlue');view.line_width=3;view.draw2d(GL_LINES,points)
        view.drawing_color=@remove ? 'Red' : (@refresh ? 'MediumSeaGreen' : 'LimeGreen')
        @plan[:holes].each do |h|
          q=view.screen_coords(h[:point].transform(inverse));points=(0...16).map { |i| a=2*Math::PI*i/16;Geom::Point3d.new(q.x+4*Math.cos(a),q.y+4*Math.sin(a),0) }
          view.draw2d(GL_LINE_LOOP,points)
        end
      end
      def onLButtonDown(flags,x,y,view)
        @signature=nil;onMouseMove(flags,x,y,view)
        return unless @path
        perform_drilling_action(@path);@plan=nil;@path=nil;@signature=nil;view.invalidate
      rescue => e
        UI.messagebox(e.message)
      end
      def getMenu(menu)
        return if @remove
        menu.add_item(ShelfPins.l('Ustawienia podpórek…','Shelf pin settings…')) { ShelfPins.show_settings(self) }
      end
      def onCancel(reason,view);@plan=nil;@path=nil;Sketchup.active_model.select_tool(nil) if reason==0;view.invalidate;end
      def deactivate(view);clear_drilling_modifiers;view.invalidate;end
    end

    def install
      unless @command
      @command=UI::Command.new('ELFIS — Shelf Pin Rows / Podpórki półek') { activate }
      @command.tooltip=l('Wiercenia pod podpórki półek — kliknij lub zaznacz półki','Shelf pin rows — click or select shelves')
      @command.small_icon=File.join(__dir__,'shelf_pins.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command)
      toolbar=BastillePodmienFront.instance_variable_get(:@toolbar)
      toolbar.add_item(@command) if toolbar
      end
      unless @remove_command
        @remove_command=UI::Command.new('ELFIS — Remove Shelf Pins / Usuń podpórki półek') { activate(remove:true) }
        @remove_command.tooltip=l('Usuń wiercenia ELFIS z klikniętej lub zaznaczonych półek','Remove ELFIS drilling from clicked or selected shelves')
        @remove_command.small_icon=File.join(__dir__,'shelf_pins_remove.svg');@remove_command.large_icon=@remove_command.small_icon
        UI.menu('Extensions').add_item(@remove_command)
      end
      @command.tooltip=l('Podpórki: klik dodaje · Alt usuwa · Ctrl aktualizuje po przesunięciu półki','Shelf pins: click adds · Alt removes · Ctrl updates after moving a shelf')
    end
  end
end
