# encoding: UTF-8
require 'securerandom'
module Elfis
  module DrillingEditor
    extend self
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def instance?(e);CarcassJoinery.instance?(e);end
    def signature(path);path.map(&:persistent_id).join('/');end
    # Reset does not require source associations: legacy/imported machining is
    # recognized by its circular vector geometry and D..._DEPTH... tag/name.
    # Edges bounding a face are never drilling vectors.
    def reset_curves(path,model)
      path.last.definition.entities.grep(Sketchup::Edge).map(&:curve).compact.uniq.select do |curve|
        curve.is_a?(Sketchup::ArcCurve) && curve.edges.all? { |edge| edge.faces.empty? } && circle(path,model,curve:curve)
      end
    end
    def reset_roots(model)
      roots=model.selection.select { |e| instance?(e) }
      raise l('Zaznacz szafkę do usunięcia wierceń.','Select a cabinet to clear its drilling.') if roots.empty?
      raise l('Otwarta szafka ma wiele kopii. Najpierw Utwórz unikatowy.','The open cabinet has multiple copies. Make it unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      roots
    end
    def reset_plan(roots,model)
      nodes=[];walk=nil
      walk=->(path,stack) do
        entity=path.last
        raise 'Invalid cabinet selection.' unless entity.valid?
        raise 'Recursive component definition.' if stack.include?(entity.definition)
        curves=reset_curves(path,model)
        owned=[[CarcassJoinery::DICT,'owner_key'],[ShelfPins::DICT,'owner_key'],[HingeDrilling::DICT,'owner'],[DrawerDrilling::DICT,'owner']].any? { |dict,key| entity.get_attribute(dict,key) }
        raise l('Szafka zawiera zablokowane powiązanie wierceń.','Cabinet contains a locked drilling association.') if owned && (path+Array(model.active_path)).any?(&:locked?)
        unless curves.empty?
          raise l('Wiercenia lub ich szafka są zablokowane.','Drilling or its cabinet is locked.') if path.any?(&:locked?) || Array(model.active_path).any?(&:locked?)
          nodes<<{path:path,count:curves.length}
        end
        entity.definition.entities.each { |child| walk.call(path+[child],stack+[entity.definition]) if instance?(child) }
      end
      roots.each do |root|
        raise 'Cabinet is outside the active editing context.' unless model.active_entities.include?(root)
        walk.call([root],[])
      end
      nodes
    end
    def remove_all(roots:nil,model:Sketchup.active_model,confirm:true)
      roots ||= reset_roots(model)
      # Validate explicit roots too, before cloning or modifying any geometry.
      raise 'No cabinets selected.' if roots.empty?
      raise 'Make the open cabinet unique first.' if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      nodes=reset_plan(roots,model);count=nodes.sum { |node| node[:count] }
      return {removed:0,cancelled:false} if count.zero?
      if confirm
        question=l("Usunąć wszystkie wiercenia (#{count}) z zaznaczonych szafek?\nTakże importowane i bez powiązań ELFIS. Wycięcia i frezowania pozostaną.\nCałość można cofnąć jednym Ctrl+Z.","Remove all drilling (#{count}) from the selected cabinets?\nIncludes imported and unassociated drilling. Cutouts and routing will remain.\nUndo the entire operation with Ctrl+Z.")
        return {removed:0,cancelled:true} unless UI.messagebox(question,MB_YESNO)==IDYES
      end
      # Build an index tree before make_unique changes descendant identities.
      trees={}
      nodes.each do |node|
        branch=(trees[node[:path].first]||={})
        node[:path].each_cons(2) { |parent,child| branch=(branch[parent.definition.entities.to_a.index(child)]||={}) }
        branch[:clear]=true
      end
      removed=0
      model.start_operation(l('ELFIS — Usuń wszystkie wiercenia','ELFIS — Clear cabinet drilling'),true)
      begin
        clear=nil
        clear=->(entity,branch,path) do
          entity.make_unique if entity.definition.instances.length>1
          children=entity.definition.entities.to_a
          branch.each { |index,sub| clear.call(children.fetch(index),sub,path+[children.fetch(index)]) if index.is_a?(Integer) }
          if branch[:clear]
            curves=reset_curves(path,model);removed+=curves.length
            entity.definition.entities.erase_entities(curves.flat_map(&:edges).uniq)
            entity.erase! if path.length>1 && entity.definition.entities.length.zero?
          end
        end
        trees.each { |root,branch| clear.call(root,branch,[root]) }
        # Source ownership must also be cleared, otherwise Refresh would
        # silently recreate the deleted pattern. Preserve Kamar ownership.
        forget=nil
        forget=->(entity) do
          dicts=[[CarcassJoinery::DICT,'owner_key'],[ShelfPins::DICT,'owner_key'],[HingeDrilling::DICT,'owner'],[DrawerDrilling::DICT,'owner']]
          children=entity.definition.entities.select { |child| instance?(child) }
          has_owner=dicts.any? { |dict,key| entity.get_attribute(dict,key) }
          has_descendant=children.any? { |child| reset_owner_tree?(child,[]) }
          if has_owner || has_descendant
            entity.make_unique if entity.definition.instances.length>1
            dicts.each { |dict,key| entity.delete_attribute(dict,key) }
            entity.definition.entities.each { |child| forget.call(child) if instance?(child) }
          end
        end
        roots.each { |root| forget.call(root) }
        model.commit_operation
      rescue Exception
        model.abort_operation
        raise
      end
      model.active_view.invalidate
      {removed:removed,cancelled:false}
    end
    def reset_owner_tree?(entity,stack)
      return false if stack.include?(entity.definition)
      [[CarcassJoinery::DICT,'owner_key'],[ShelfPins::DICT,'owner_key'],[HingeDrilling::DICT,'owner'],[DrawerDrilling::DICT,'owner']].any? { |dict,key| entity.get_attribute(dict,key) } || entity.definition.entities.any? { |child| instance?(child) && reset_owner_tree?(child,stack+[entity.definition]) }
    end
    def circle(path,model,curve:nil)
      group=path.last;entities=group.definition.entities
      unless curve
        return nil unless entities.length>=8 && entities.all? { |e| e.is_a?(Sketchup::Edge) }
        curves=entities.map(&:curve).compact.uniq
        return nil unless curves.length==1 && curves.first.is_a?(Sketchup::ArcCurve)
        curve=curves.first
        return nil unless curve.edges.length==entities.length
      end
      return nil unless curve.is_a?(Sketchup::ArcCurve) && curve.edges.length>=8 && (curve.end_angle-curve.start_angle-2*Math::PI).abs<1e-4
      names=curve.edges.map { |e| e.layer.name }+[group.name,group.layer.name]
      match=names.filter_map { |n| n.to_s.match(/\AD([\d.]+)_DEPTH_?([\d.]+)\z/i) }.first
      return nil unless match
      depth=Float(match[2]);return nil unless depth.finite? && depth>0
      tr=path.inject(model.edit_transform) { |t,e| t*e.transformation }
      x=curve.xaxis.normalize.transform(tr);y=curve.yaxis.normalize.transform(tr)
      return nil if x.length<1e-8 || y.length<1e-8 || (x.length-y.length).abs>1e-5 || x.normalize.dot(y.normalize).abs>1e-5
      {path:path,point:curve.center.transform(tr),diameter:(2*curve.radius.to_mm*x.length).round(6),depth:depth,normal:x.cross(y).normalize,tangent:x.normalize,local_center:curve.center.to_a,local_radius:curve.radius.to_f,curve_id:curve.edges.map(&:persistent_id).min}
    rescue ArgumentError;nil
    end
    def panel_holes(panel,model)
      out=[];walk=nil
      walk=->(path,stack) do
        e=path.last;next if !e.valid? || stack.include?(e.definition)
        h=circle(path,model)
        if h;out<<h.merge(panel:panel);next;end
        # Imported machining may store several complete circles in one group.
        # Expose individual circles without modifying geometry during scanning.
        if e.definition.entities.all? { |v| v.is_a?(Sketchup::Edge)||instance?(v) }
          curves=e.definition.entities.grep(Sketchup::Edge).map(&:curve).compact.uniq
          curves.each do |curve|
            h=circle(path,model,curve:curve)
            out<<h.merge(panel:panel,virtual:true) if h
          end
        end
        e.definition.entities.each { |child| walk.call(path+[child],stack+[e.definition]) if instance?(child) }
      end
      panel[:entity].definition.entities.each { |e| walk.call(panel[:path]+[e],[]) if instance?(e) };out
    end
    def source_candidates(boards,model)
      joints=[];pins=[]
      boards.each do |source|
        if CarcassJoinery.eligible?(source)
          begin
            # Imported corner joints have perpendicular receivers, not the two
            # parallel sides required by the rectangular frame classifier.
            joints << if CornerCabinet.corner?(boards,source)
              CornerCabinet.joint_plan(source[:path],CarcassJoinery.settings,model,source,boards)
            else
              CarcassJoinery.frame_for(source,boards)
            end
          rescue RuntimeError
            # Keep unsupported sources visible as unassociated, never guess.
          end
        end
        if ShelfPins.shelf?(source)
          begin;pins<<ShelfPins.plan(source[:path],ShelfPins.settings,model);rescue RuntimeError;end
        end
      end
      {joints:joints,pins:pins}
    end
    def fronts(root,model)
      out=[];walk=nil
      walk=->(path,stack) do
        e=path.last;next if !e.valid? || stack.include?(e.definition)
        if HingeDrilling.front?(e)
          begin;out<<HingeDrilling.front_board(path,model);rescue RuntimeError;end
          next
        end
        e.definition.entities.each { |v|walk.call(path+[v],stack+[e.definition]) if instance?(v) }
      end
      walk.call([root],[]);out
    end
    # Infer imported hinge positions from actual cups, not from the current
    # 100 mm defaults. A plate can only be adopted when its cup front is present.
    def hinge_candidates(fronts,model)
      fronts.flat_map do |front|
        cups=panel_holes(front,model).select { |h|(h[:diameter]-35).abs<0.01 }.sort_by { |h|h[:point].z }
        next [] unless (2..10).include?(cups.length)
        zs=front[:points].map(&:z);bottom=(cups.first[:point].z-zs.min).to_mm;top=(zs.max-cups.last[:point].z).to_mm
        begin
          p=HingeDrilling.plan(front[:path],HingeDrilling.defaults.merge(count:cups.length,bottom:bottom,top:top),model)
          p[:holes].each_slice(5).with_index.flat_map do |holes,i|
            delta=cups[i][:point].z-holes.first[:point].z
            holes.map { |h|h.merge(point:h[:point].offset(Z_AXIS,delta),source:front) }
          end
        rescue RuntimeError
          []
        end
      end
    end
    def kamar_rows(boards,model)
      boards.select { |b|CarcassJoinery.back?(b) }.flat_map do |b|
        begin
          p=HangerCutouts.plan(b[:path],HangerCutouts.preset,model)
          p[:corners].filter_map do |corner|
            g=corner[:existing];next unless g
            path=b[:path]+[g];locked=path.any?(&:locked?)
            {path:path,panel:b,source:locked ? nil : b,kind: :kamar,owned:g.get_attribute(HangerCutouts::DICT,'preset')=='kamar',
             point:corner[:contour].first,contour:corner[:contour],corner:corner[:side],diameter:6.0,depth:8.0,id:signature(path),
             reason:locked ? l('Element zablokowany','Locked element') : nil}
          end
        rescue RuntimeError
          []
        end
      end
    end
    def drawer_candidates(fronts,model)
      fronts.flat_map do |front|
        begin
          DrawerDrilling.plan(front[:path],DrawerDrilling.defaults,model)[:holes].map { |h|h.merge(source:front) }
        rescue RuntimeError
          []
        end
      end
    end
    def association(h,boards,candidates)
      group=h[:path].last
      key=group.get_attribute(DrawerDrilling::DICT,'owner')
      if key
        matches=boards.select { |b|DrawerDrilling.front?(b[:entity]) && b[:entity].get_attribute(DrawerDrilling::DICT,'owner')==key }
        return {reason:l('Niejednoznaczne powiązanie ELFIS','Ambiguous ELFIS association')} unless matches.length==1
        kind=group.get_attribute(DrawerDrilling::DICT,'kind').to_s.to_sym
        return {source:matches.first,kind:kind,owned:true} if %i[drawer_front drawer_gallery drawer_slide].include?(kind)
        return {reason:'Unknown drawer drilling type'}
      end
      key=group.get_attribute(HingeDrilling::DICT,'owner')
      if key
        matches=boards.select { |b|HingeDrilling.front?(b[:entity]) && b[:entity].get_attribute(HingeDrilling::DICT,'owner')==key }
        return {reason:l('Niejednoznaczne powiązanie ELFIS','Ambiguous ELFIS association')} unless matches.length==1
        kind=group.get_attribute(HingeDrilling::DICT,'kind').to_s.to_sym
        return {source:matches.first,kind:kind,owned:true} if %i[cup hinge_dowel hinge_plate].include?(kind)
        return {reason:l('Nieznany rodzaj wiercenia zawiasu','Unknown hinge drilling type')}
      end
      [[CarcassJoinery::DICT,:joint],[ShelfPins::DICT,:pin]].each do |dict,type|
        key=group.get_attribute(dict,'owner_key');next unless key
        matches=boards.select { |b| b[:entity].get_attribute(dict,'owner_key')==key }
        return {reason:l('Niejednoznaczne powiązanie ELFIS','Ambiguous ELFIS association')} unless matches.length==1
        kind=type==:pin ? :pin : group.get_attribute(dict,'kind').to_s.to_sym
        kind=:screw unless %i[dowel screw back_screw back_top_screw back_bottom_screw pin].include?(kind)
        return {source:matches.first,kind:kind,owned:true}
      end
      found=[];r=h[:diameter].mm/2
      candidates[:joints].select { |p|p[:corner] }.each do |p|
        p[:holes].each do |v|
          next unless v[:panel][:path]==h[:panel][:path] && v[:point].distance(h[:point]).to_mm<0.75 && (v[:diameter]-h[:diameter]).abs<0.3 && v[:normal].dot(h[:normal]).abs>0.999
          found<<{source:p[:shelf],kind:v[:kind],owned:false}
        end
        # Legacy back screws may have different margins/spacing (and a slight
        # off-centre axis) from today's defaults. Associate by the actual back
        # cut-end contact, not by matching a newly generated screw grid.
        next unless CarcassJoinery.back?(p[:shelf]) && (h[:diameter]-CarcassJoinery.settings[:screw_diameter]).abs<0.3
        next unless p[:sides].any? { |_,side,_,_|side[:path]==h[:panel][:path] }
        next unless h[:normal].dot(p[:width]).abs>0.999
        q=h[:point].transform(p[:inverse]);sb=p[:bounds]
        next unless q.y-r>=sb.min.y && q.y+r<=sb.max.y && q.z-r>=sb.min.z && q.z+r<=sb.max.z
        x=[sb.min.x,sb.max.x].min_by { |edge|(q.x-edge).abs }
        source_point=Geom::Point3d.new(x,q.y,q.z).transform(p[:frame])
        begin
          CarcassJoinery.check_circle(h.merge(panel:p[:shelf],point:source_point,normal:p[:width],tangent:Z_AXIS,depth:0))
          found<<{source:p[:shelf],kind: :back_screw,owned:false}
        rescue RuntimeError
          # A circle inside a back notch must remain unassociated.
        end
      end
      (Array(candidates[:hinges])+Array(candidates[:drawers])).each do |hole|
        next unless hole[:panel][:path]==h[:panel][:path] && hole[:point].distance(h[:point]).to_mm<0.75 && (hole[:diameter]-h[:diameter]).abs<0.01 && hole[:normal].dot(h[:normal]).abs>0.999
        found<<{source:hole[:source],kind:hole[:kind],owned:false}
      end
      if CarcassJoinery.back?(h[:panel])
        candidates[:joints].select { |p|!p[:corner] && p[:shelf][:path]==h[:panel][:path] }.each do |p|
          begin
            front=CarcassJoinery.front_high?(p,boards)
            expected=CarcassJoinery.back_rail_holes(p[:shelf],p,boards,CarcassJoinery.settings,front)
            expected.each do |hole|
              next unless hole[:point].distance(h[:point]).to_mm<0.75 && (hole[:diameter]-h[:diameter]).abs<0.3 && hole[:normal].dot(h[:normal]).abs>0.999
              found<<{source:p[:shelf],kind:hole[:kind],owned:false}
            end
          rescue RuntimeError
            # Unsupported imported rear geometry remains unassociated.
          end
        end
      end
      candidates[:joints].each do |p|
        next if p[:corner]
        next unless p[:sides].any? { |_,side,_,_| side[:path]==h[:panel][:path] }
        q=h[:point].transform(p[:inverse]);sb=p[:bounds]
        next unless q.z>=sb.min.z+r-0.05.mm && q.z<=sb.max.z-r+0.05.mm
        if CarcassJoinery.back?(p[:shelf])
          next unless (h[:diameter]-CarcassJoinery.settings[:screw_diameter]).abs<0.3 && q.y-r>=sb.min.y && q.y+r<=sb.max.y
          kind=:back_screw
        else
          next unless (q.z-sb.center.z).abs.to_mm<=0.75 && q.y-r>sb.min.y && q.y+r<sb.max.y
          kind=(h[:diameter]-CarcassJoinery.settings[:screw_diameter]).abs<0.3 ? :screw : :dowel
        end
        found<<{source:p[:shelf],kind:kind,owned:false}
      end
      candidates[:pins].each do |p|
        next unless p[:holes].any? { |v| v[:panel][:path]==h[:panel][:path] && v[:point].distance(h[:point]).to_mm<0.75 }
        found<<{source:p[:shelf],kind: :pin,owned:false}
      end
      found.uniq! { |v| [signature(v[:source][:path]),v[:kind]] }
      return found.first if found.length==1
      {reason:found.empty? ? l('Nie znaleziono powiązanego panelu','No associated source panel') : l('Kilka możliwych paneli','Several possible source panels')}
    end
    def scan(roots:nil,model:Sketchup.active_model)
      roots ||= model.selection.select { |e| instance?(e) }
      raise l('Zaznacz szafkę lub grupę zawierającą panele.','Select a cabinet or a group containing panels.') if roots.empty?
      raise l('Najpierw zakończ edycję współdzielonej szafki lub utwórz unikatową.','Leave shared cabinet editing or make it unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      rows=[]
      roots.each do |root|
        raise l('Zaznaczenie zmieniło się. Rozpoznaj ponownie.','Selection changed. Scan again.') unless root.valid? && model.active_entities.include?(root)
        boards=CarcassJoinery.panels(root,model);fs=fronts(root,model);boards+=fs
        candidates=source_candidates(boards,model);candidates[:hinges]=hinge_candidates(fs,model)
        candidates[:drawers]=drawer_candidates(fs,model)
        sides=boards.select { |b| (StudioSettings.role?(b[:entity],:sides)||StudioSettings.role?(b[:entity],:backs)) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }
        (sides+fs).uniq { |b|signature(b[:path]) }.each do |side|
          panel_holes(side,model).each do |h|
            info=association(h,boards,candidates)
            if h[:path].any?(&:locked?) || (info[:source] && info[:source][:path].any?(&:locked?))
              info={reason:l('Element zablokowany','Locked element')}
            end
            id=signature(h[:path]);id+="/curve-#{h[:curve_id]}" if h[:virtual]
            rows<<h.merge(info).merge(id:id)
          end
        end
        rows.concat(kamar_rows(boards,model))
      end
      {roots:roots,rows:rows.uniq { |h| h[:id] },model:model,context:Array(model.active_path).map(&:persistent_id)}
    end
    def public_rows(scan)
      scan[:rows].group_by do |h|
        [h[:diameter].round(3),h[:depth].round(3),h[:kind],h[:source] && signature(h[:source][:path]),h[:reason],h[:owned]]
      end.map do |_,items|
        h=items.first
        {ids:items.map { |v| v[:id] },diameter:h[:diameter].round(3),depth:h[:depth],kind:h[:kind],count:items.length,source:h[:source] && (h[:source][:entity].name.empty? ? h[:source][:entity].definition.name : h[:source][:entity].name),reason:h[:reason],owned:h[:owned]==true,selectable:!!h[:source]}
      end
    end
    def apply(snapshot,ids,parameters={},update:false,operation:true)
      model=Sketchup.active_model
      raise l('Model lub kontekst zmienił się. Rozpoznaj ponownie.','Model or editing context changed. Scan again.') unless snapshot[:model]==model && snapshot[:context]==Array(model.active_path).map(&:persistent_id)
      ids=Array(ids).uniq;raise l('Zaznacz rozpoznane grupy wierceń.','Select recognized drilling groups.') if ids.empty?
      fresh=scan(roots:snapshot[:roots],model:model)
      pin_patterns={}
      selected=ids.map do |id|
        old=snapshot[:rows].find { |h| h[:id]==id };h=fresh[:rows].find { |v| v[:id]==id }
        raise l('Wiercenia zmieniły się. Odśwież rozpoznanie.','Drilling changed. Refresh the scan.') unless old && h && h[:source] && old[:source] && signature(old[:source][:path])==signature(h[:source][:path]) && old[:kind]==h[:kind] && old[:point].distance(h[:point]).to_mm<0.01 && (old[:diameter]-h[:diameter]).abs<0.001 && (old[:depth]-h[:depth]).abs<0.001
        p=parameters[%i[back_screw back_top_screw back_bottom_screw].include?(h[:kind]) ? :screw : h[:kind]] || {}
        diameter=update ? Float(p.fetch(:diameter)) : h[:diameter]
        depth=update ? Float(p.fetch(:depth)) : h[:depth]
        raise l('Średnica i głębokość muszą być dodatnie.','Diameter and depth must be positive.') unless diameter.finite? && depth.finite? && diameter>0 && depth>0
        result=h.merge(diameter:diameter,depth:depth)
        if h[:kind]==:pin
          source_id=signature(h[:source][:path])
          unless pin_patterns.key?(source_id)
            pin_patterns[source_id]=ShelfPins.plan(h[:source][:path],ShelfPins.settings,model)[:corner_pattern]
          end
          result[:corner_pattern]=pin_patterns[source_id]
        end
        if h[:kind]==:kamar
          raise l('Obrys Kamar zachowuje wzorzec D6 / 8 mm. Zmianę kształtu wykonaj narzędziem zawieszek.','Kamar contours keep the D6 / 8 mm template. Use the hanger tool to change the cutout.') unless diameter==6.0 && depth==8.0
        elsif HingeDrilling.front?(h[:panel][:entity]);HingeDrilling.check_front(result)
        else;CarcassJoinery.check_circle(result)
        end
        if h[:kind]!=:pin
          # Check the source in its own axes; world Z is the thickness for rails.
          if CarcassJoinery.horizontal?(h[:source])
            zs=h[:source][:points].map(&:z);raise l('Średnica nie mieści się w grubości panelu.','Diameter does not fit the source thickness.') unless result[:point].z-diameter.mm/2>zs.min && result[:point].z+diameter.mm/2<zs.max
          end
        end
        result
      end
      token=SecureRandom.uuid;marked=[];changed=0
      model.start_operation(l('ELFIS — Zmień istniejące wiercenia','ELFIS — Convert existing drilling'),true) if operation
      begin
        encode=->(path) do
          path.each { |e| e.set_attribute('ElfisDrillingEditorTemp',token,e.persistent_id.to_s);marked<<e }
          [path.first,path.map { |e| e.get_attribute('ElfisDrillingEditorTemp',token) }]
        end
        specs=selected.map { |h| [h,encode.call(h[:source][:path]),encode.call(h[:panel][:path]),encode.call(h[:path])] }
        resolve=->(spec) do
          root,keys=spec;path=[root]
          keys.drop(1).each do |key|
            e=path.last.definition.entities.find { |child| instance?(child) && child.get_attribute('ElfisDrillingEditorTemp',token)==key };raise 'Drilling path changed.' unless e;path<<e
          end
          BastillePodmienFront.unique_path(path)
        end
        specs.each do |h,source_spec,side_spec,hole_spec|
          source_path=resolve.call(source_spec);source=source_path.last
          source.make_unique if source.definition.instances.length>1
          hinge=%i[cup hinge_dowel hinge_plate].include?(h[:kind]);kamar=h[:kind]==:kamar
          drawer=%i[drawer_front drawer_gallery drawer_slide].include?(h[:kind])
          dict=kamar ? HangerCutouts::DICT : (drawer ? DrawerDrilling::DICT : (hinge ? HingeDrilling::DICT : (h[:kind]==:pin ? ShelfPins::DICT : CarcassJoinery::DICT)))
          owner_field=(hinge||drawer) ? 'owner' : 'owner_key'
          key=source.get_attribute(dict,owner_field) || SecureRandom.uuid
          siblings=source_path.length>1 ? source_path[-2].definition.entities : model.active_entities
          key=SecureRandom.uuid if siblings.any? { |e| instance?(e) && e!=source && e.get_attribute(dict,owner_field)==key }
          source.set_attribute(dict,owner_field,key) unless kamar
          source.set_attribute(ShelfPins::DICT,'corner_pattern',JSON.generate(h[:corner_pattern])) if h[:corner_pattern]
          if drawer
            source.set_attribute(dict,'variant',DrawerDrilling.variant(source_path,DrawerDrilling.defaults,model))
            source.set_attribute(dict,'length',500)
          end
          side_path=resolve.call(side_spec);side=side_path.last;side.make_unique if side.definition.instances.length>1
          hole_path=resolve.call(hole_spec);group=hole_path.last;group.make_unique if group.definition.instances.length>1
          if kamar
            group.name='Blum Operations';group.layer=model.layers[StudioSettings.operation_tag]||model.layers.add(StudioSettings.operation_tag)
            group.set_attribute(dict,'preset','kamar');group.set_attribute(dict,'side',h[:corner].to_s)
            {depth:8.0,width:20.0,height:55.0}.each { |k,v|group.set_attribute(dict,k.to_s,v) }
            source.set_attribute(dict,'preset','kamar');changed+=1;next
          end
          if h[:virtual]
            curve=group.definition.entities.grep(Sketchup::Edge).map(&:curve).compact.uniq.find do |v|
              v.is_a?(Sketchup::ArcCurve) && v.center.distance(Geom::Point3d.new(h[:local_center])).to_f<1e-6 && (v.radius.to_f-h[:local_radius]).abs<1e-6
            end
            raise 'Imported circle changed. Scan again.' unless curve
            container=group.definition.entities
            centre=curve.center;normal=curve.normal;tangent=curve.xaxis.normalize
            radius=curve.radius;segments=curve.edges.length;old_edges=curve.edges
            child=container.add_group
            child.entities.add_circle(ORIGIN,Z_AXIS,radius,segments)
            child.transformation=Geom::Transformation.axes(centre,tangent,normal.cross(tangent).normalize,normal)
            container.erase_entities(old_edges)
            group=child
            hole_path=hole_path+[group]
          end
          if update
            group.definition.entities.erase_entities(group.definition.entities.to_a)
            panel=HingeDrilling.front?(side) ? HingeDrilling.front_board(side_path,model) : CarcassJoinery.board(side_path,model)
            group.definition.entities.add_circle(ORIGIN,Z_AXIS,h[:diameter].mm/2,24)
            group.transformation=panel[:world].inverse*Geom::Transformation.axes(h[:point],h[:tangent],h[:normal].cross(h[:tangent]).normalize,h[:normal]) if hole_path.length==side_path.length+1
            if hole_path.length>side_path.length+1
              parent_world=hole_path[0...-1].inject(model.edit_transform) { |tr,e| tr*e.transformation }
              group.transformation=parent_world.inverse*Geom::Transformation.axes(h[:point],h[:tangent],h[:normal].cross(h[:tangent]).normalize,h[:normal])
            end
          end
          name=CarcassJoinery.tag(h[:diameter],h[:depth]);group.name=name
          group.layer=model.layers[StudioSettings.operation_tag]||model.layers.add(StudioSettings.operation_tag)
          tag=model.layers[name]||model.layers.add(name);group.definition.entities.grep(Sketchup::Edge).each { |edge| edge.layer=tag }
          group.set_attribute(dict,owner_field,key);group.set_attribute(dict,'diameter',h[:diameter]);group.set_attribute(dict,'depth',h[:depth])
          if h[:kind]==:pin;group.set_attribute(dict,'source',signature(source_path))
          else;group.set_attribute(dict,'kind',h[:kind].to_s)
          end
          changed+=1
        end
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisDrillingEditorTemp',token) if instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisDrillingEditorTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation;raise
      end
      model.active_view.invalidate;{changed:changed,updated:update}
    end
  end
end
