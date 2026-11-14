# encoding: UTF-8
require 'securerandom'
require 'json'
require_relative 'hinge_tool_panel'
module Elfis
  # CNC circles only. No hardware insertion and no background observers.
  module HingeDrilling
    extend self
    DICT='ElfisHingeDrilling' unless const_defined?(:DICT)
    PREF='ELFIS Hinge Drilling' unless const_defined?(:PREF)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def instance?(e);CarcassJoinery.instance?(e);end
    def defaults;{count:2,bottom:100.0,top:100.0,side:'Auto',cup_edge:5.0,cup_depth:13.0,dowel_depth:13.0,plate_depth:11.5,plate_setback:37.0};end
    def settings;defaults.to_h { |k,v|[k,Sketchup.read_default(PREF,k.to_s,v)] };end
    # Quick tool layouts belong to each front; drilling depths still use defaults.
    def layout_settings(path,c=settings)
      raw=path.last.get_attribute(DICT,'layout');return c unless raw
      data=JSON.parse(raw).transform_keys(&:to_sym)
      values=data.select { |k,_| %i[count top bottom side].include?(k) }
      if [data[:side_axis],data[:inward_axis]].all? { |v|v.is_a?(Array) && v.length==3 && v.all? { |n|n.is_a?(Numeric) && n.finite? } }
        tw=path.inject(Sketchup.active_model.edit_transform) { |t,e|t*e.transformation }
        toward=Geom::Vector3d.new(data[:side_axis]).transform(tw)
        inward=Geom::Vector3d.new(data[:inward_axis]).transform(tw).normalize
        values[:side]=toward.dot(inward.cross(Z_AXIS))<0 ? 'Left' : 'Right'
      end
      validate(c.merge(values))
    rescue JSON::ParserError,TypeError,ArgumentError
      c
    end
    def validate(c)
      c=defaults.merge(c);c[:count]=Integer(c[:count])
      raise 'Hinge count must be between 2 and 10.' unless (2..10).include?(c[:count])
      (defaults.keys-[:count,:side]).each { |k|c[k]=Float(c[k]);raise "Invalid #{k}." unless c[k].finite? && c[k]>0 && c[k]<500 }
      raise 'Choose Auto, Left or Right.' unless %w[Auto Left Right].include?(c[:side]);c
    end
    def front?(e);instance?(e) && StudioSettings.role?(e,:facades);end
    def front_board(path,m)
      e=path.last;raise l('Kliknij front z ustawionym tagiem fasady.','Click a front with the configured facade tag.') unless front?(e)
      bb=BastillePodmienFront.door_bounds(e);tr=path.inject(m.edit_transform) { |t,v|t*v.transformation }
      vs=[X_AXIS,Y_AXIS,Z_AXIS].map { |v|v.transform(tr) };axes=vs.map(&:normalize)
      raise 'Skewed front axes are not supported.' unless [[0,1],[0,2],[1,2]].all? { |a,b|axes[a].dot(axes[b]).abs<1e-5 }
      lengths=[bb.width,bb.height,bb.depth].each_with_index.map { |v,i|v*vs[i].length };thin=(0..2).min_by { |i|lengths[i] }
      raise 'Select an upright front, between 3 and 80 mm thick.' unless lengths[thin]>3.mm && lengths[thin]<80.mm && axes[thin].dot(Z_AXIS).abs<0.001 && axes.any? { |v|v.dot(Z_AXIS).abs>0.999 }
      surfaces=[];walk=nil
      walk=->(ents,t,stack) do
        ents.grep(Sketchup::Face).each { |f|surfaces<<[f,t] }
        ents.each do |v|
          next unless instance?(v) && !stack.include?(v.definition)
          # Generated frames contain their geometry in marked groups; exclude
          # handles/hardware and drilling containers from the receiving surface.
          next if e.get_attribute('ElfisBastillePodmien','generated',false) && !BastillePodmienFront.own_geometry?(v,e)
          walk.call(v.definition.entities,t*v.transformation,stack+[v.definition])
        end
      end
      walk.call(e.definition.entities,tr,[e.definition])
      {path:path,entity:e,world:tr,bb:bb,axes:axes,lengths:lengths,thin:thin,points:(0..7).map { |i|bb.corner(i).transform(tr) },surfaces:surfaces}
    end
    def check_front(h)
      b=h[:panel];r=h[:diameter].mm/2;u=h[:tangent];v=h[:normal].cross(u).normalize
      samples=[h[:point]]+(0...24).map { |i|a=2*Math::PI*i/24;h[:point].offset(u,r*Math.cos(a)).offset(v,r*Math.sin(a)) }
      good=[Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex]
      valid=b[:surfaces].any? do |f,t|
        inv=t.inverse;qs=samples.map { |q|q.transform(inv) }
        qs.all? { |q|q.distance_to_plane(f.plane).to_f<0.02.mm.to_f && good.include?(f.classify_point(q)) }
      end
      raise l('Brak pełnej powierzchni frontu pod wierceniem.','No complete front surface beneath a drilling circle.') unless valid
      raise 'Drilling depth exceeds front thickness.' if h[:depth].mm>b[:lengths][b[:thin]]+0.01.mm
    end
    def plan(path,c=settings,m=Sketchup.active_model)
      c=validate(c);raise 'A front or its parent is locked.' if path.any?(&:locked?)
      b=front_board(path,m);all=CarcassJoinery.surroundings(path,m)
      normal=b[:axes][b[:thin]];centre=ShelfPins.projected(b[:points],Geom::Transformation.new).center
      sides=all.select { |s|StudioSettings.role?(s[:entity],:sides) && !CarcassJoinery.back?(s) && s[:axes][s[:thin]].dot(Z_AXIS).abs<0.001 && s[:axes][s[:thin]].dot(normal).abs<0.001 }
      raise 'No cabinet side panels found.' if sides.empty?
      sidecentre=Geom::Point3d.new((0..2).map { |i|sides.sum { |s|s[:points].sum { |q|q[i] }/8.0 }/sides.length })
      inward=centre.vector_to(sidecentre).dot(normal)>0 ? normal : normal.reverse
      width=inward.cross(Z_AXIS).normalize;frame=Geom::Transformation.axes(ORIGIN,width,inward,Z_AXIS);inv=frame.inverse;fb=ShelfPins.projected(b[:points],inv)
      back=fb.max.y;lo=fb.min.z+c[:bottom].mm;hi=fb.max.z-c[:top].mm
      raise 'Front too short for the hinge offsets and 45 mm fixing pattern.' unless hi-lo>45.mm && c[:bottom]>22.5+4 && c[:top]>22.5+4
      raise 'Not enough space between hinges for the fixing pattern.' unless (hi-lo)/(c[:count]-1)>53.mm
      candidates=sides.filter_map do |s|
        sb=ShelfPins.projected(s[:points],inv)
        next if sb.min.y<back-5.mm || sb.min.y-back>30.mm
        which=(sb.center.x-fb.min.x).abs<(sb.center.x-fb.max.x).abs ? :left : :right
        edge=which==:left ? fb.min.x : fb.max.x
        next if (sb.center.x-edge).abs>40.mm
        [s,sb,which,(sb.center.x-edge).abs]
      end
      raise 'No adjacent cabinet side behind this front.' if candidates.empty?
      holes=DrillingEditor.panel_holes(b,m)
      cups=holes.select { |h|(h[:diameter]-35).abs<0.01 }
      side=c[:side].downcase.to_sym
      if side==:auto && !cups.empty?
        xs=cups.map { |h|h[:point].transform(inv).x };x=xs.sum/xs.length
        side=(x-fb.min.x).abs<(x-fb.max.x).abs ? :left : :right
      end
      candidates.select! { |v|v[2]==side } unless side==:auto
      chosen=candidates.sort_by { |v|[v[3],v[2]==:left ? 0 : 1] }.first
      raise 'No cabinet side on the chosen hinge side.' unless chosen
      receiver,sb,side=chosen;raise 'A cabinet side or its parent is locked.' if receiver[:path].any?(&:locked?)
      sign=side==:left ? 1 : -1;edge=side==:left ? fb.min.x : fb.max.x
      inside=side==:left ? sb.max.x : sb.min.x;axis=side==:left ? width.reverse : width
      zs=(0...c[:count]).map { |i|lo+(hi-lo)*i/(c[:count]-1) }
      result=[]
      zs.each do |z|
        [[edge+sign*(17.5+c[:cup_edge]).mm,z,35,c[:cup_depth],:cup],
         [edge+sign*(27+c[:cup_edge]).mm,z-22.5.mm,8,c[:dowel_depth],:hinge_dowel],
         [edge+sign*(27+c[:cup_edge]).mm,z+22.5.mm,8,c[:dowel_depth],:hinge_dowel]].each do |x,zz,d,depth,kind|
          h={panel:b,point:Geom::Point3d.new(x,back,zz).transform(frame),normal:inward.reverse,tangent:Z_AXIS,diameter:d,depth:depth,kind:kind};check_front(h);result<<h
        end
        [-16,16].each do |offset|
          h={panel:receiver,point:Geom::Point3d.new(inside,sb.min.y+c[:plate_setback].mm,z+offset.mm).transform(frame),normal:axis,tangent:Z_AXIS,diameter:5,depth:c[:plate_depth],kind: :hinge_plate}
          CarcassJoinery.check_circle(h);result<<h
        end
      end
      {shelf:b,holes:result,side:side,settings:c,width:width,inward:inward}
    end
    def associated(path,m)
      owner=path.last.get_attribute(DICT,'owner');return [] unless owner
      roots=path.length>1 ? [[path.first]] : m.active_entities.select { |e|instance?(e) }.map { |e|[e] }
      groups=[];sources=[];walk=nil
      walk=->(p,stack) do
        e=p.last;next if stack.include?(e.definition)
        if e.get_attribute(DICT,'owner')==owner
          if e.get_attribute(DICT,'kind');groups<<p;next
          else;sources<<p;end
        end
        e.definition.entities.each { |v|walk.call(p+[v],stack+[e.definition]) if instance?(v) }
      end
      roots.each { |p|walk.call(p,[]) }
      raise 'Multiple fronts share the drilling association; make the assembly unique.' unless sources.length==1 && sources.first==path
      raise 'A drilling group or its parent is locked.' if groups.any? { |p|p.any?(&:locked?) };groups
    end
    def apply(paths,c=settings,m=Sketchup.active_model,operation:true,mode: :add,store_layout:false)
      c=validate(c)
      paths=paths.uniq { |p|p.map(&:persistent_id) };raise 'No fronts selected.' if paths.empty?
      raise 'Make the open cabinet unique first.' if Array(m.active_path).any? { |e|e.definition.instances.length>1 }
      paths.each { |p|front_board(p,m);raise 'A front or its parent is locked.' if p.any?(&:locked?);associated(p,m);plan(p,c,m) unless mode==:remove }
      token=SecureRandom.uuid;temp='ElfisHingeTemp';marked=[];created=0;existing=0;removed=0
      m.start_operation(l('ELFIS — Wiercenia zawiasów','ELFIS — Hinge drilling'),true) if operation
      begin
        mark=->(p) { p.each { |e|e.set_attribute(temp,token,e.persistent_id.to_s);marked<<e };[p.first,p.map { |e|e.get_attribute(temp,token) }] }
        resolve=->(ref) do
          p=[ref[0]];ref[1].drop(1).each { |id|v=p.last.definition.entities.find { |e|instance?(e)&&e.get_attribute(temp,token)==id };raise 'Drilling path changed.' unless v;p<<v };p
        end
        refs=paths.map { |p|mark.call(p) }
        refs.each do |ref|
          p=BastillePodmienFront.unique_path(resolve.call(ref));e=p.last;e.make_unique if e.definition.instances.length>1
          # Resolve Auto from the existing cups before update removes them.
          # Replanning after removal must not silently switch a right-hand door.
          effective=c
          effective=c.merge(side:plan(p,c,m)[:side].to_s.capitalize) if mode!=:remove && c[:side]=='Auto'
          if mode!=:add
            targets=associated(p,m).map { |q|mark.call(q) }
            targets.each { |t|q=BastillePodmienFront.unique_path(resolve.call(t));q.last.erase!;removed+=1 }
          end
          next if mode==:remove
          planned=plan(p,effective,m);owner=e.get_attribute(DICT,'owner')||SecureRandom.uuid;e.set_attribute(DICT,'owner',owner)
          if store_layout
            inverse=planned[:shelf][:world].inverse
            toward=planned[:side]==:left ? planned[:width].reverse : planned[:width]
            layout=planned[:settings].select { |k,_|%i[count top bottom side].include?(k) }
            layout=layout.merge(side_axis:toward.transform(inverse).normalize.to_a,inward_axis:planned[:inward].transform(inverse).normalize.to_a)
            e.set_attribute(DICT,'layout',JSON.generate(layout))
          end
          # Isolate each receiving panel once, resolving child references after
          # parent Make Unique so other copies of the cabinet stay untouched.
          grouped=planned[:holes].group_by { |h|h[:panel][:path].map(&:persistent_id) }
          specs=grouped.values.map { |hs|[mark.call(hs.first[:panel][:path]),hs] }
          specs.each do |target,hs|
            q=BastillePodmienFront.unique_path(resolve.call(target));panel=q.last;panel.make_unique if panel.definition.instances.length>1
            tw=q.inject(m.edit_transform) { |tr,v|tr*v.transformation };old=DrillingEditor.panel_holes({path:q,world:tw,entity:panel},m)
            hs.each do |h|
              conflict=old.any? { |o|o[:point].distance(h[:point]).to_f<0.02.mm.to_f && (o[:diameter]-h[:diameter]).abs<0.01 && (o[:depth]-h[:depth]).abs>=0.01 }
              raise 'An existing hole has a different depth. Review the imported drilling before adding another circle.' if conflict
              if old.any? { |o|o[:point].distance(h[:point]).to_f<0.02.mm.to_f && (o[:diameter]-h[:diameter]).abs<0.01 && (o[:depth]-h[:depth]).abs<0.01 }
                existing+=1;next
              end
              g=panel.definition.entities.add_group;name=CarcassJoinery.tag(h[:diameter],h[:depth]);g.name=name
              g.layer=m.layers[StudioSettings.operation_tag]||m.layers.add(StudioSettings.operation_tag)
              tag=m.layers[name]||m.layers.add(name)
              g.entities.add_circle(ORIGIN,Z_AXIS,h[:diameter].mm/2,48).each { |v|v.layer=tag }
              g.transformation=tw.inverse*Geom::Transformation.axes(h[:point],h[:tangent],h[:normal].cross(h[:tangent]).normalize,h[:normal])
              g.set_attribute(DICT,'owner',owner);g.set_attribute(DICT,'kind',h[:kind].to_s);created+=1
              old<<{point:h[:point],diameter:h[:diameter],depth:h[:depth]}
            end
          end
        end
        m.definitions.each { |d|d.entities.each { |e|e.delete_attribute(temp,token) if instance?(e) } };marked.each { |e|e.delete_attribute(temp,token) if e.valid? }
        m.commit_operation if operation
      rescue
        m.abort_operation if operation;raise
      end
      m.active_view.invalidate;{created:created,existing:existing,removed:removed,fronts:paths.length}
    end
    def show_settings(tool=nil)
      if defined?(StudioSettings)
        StudioSettings.show('hinges');return
      end
      c=settings;keys=defaults.keys
      labels=['Hinges / Zawiasy','Bottom axis / Oś od dołu [mm]','Top axis / Oś od góry [mm]','Side / Strona','Cup edge / Od krawędzi puszki [mm]','Cup depth Ø35 [mm]','Fixing depth Ø8 [mm]','Plate depth Ø5 [mm]','Plate from side front / Prowadnik od przodu boku [mm]']
      lists=keys.map { |k|k==:side ? 'Auto|Left|Right' : '' };values=UI.inputbox(labels,keys.map { |k|c[k] },lists,'ELFIS — Hinge drilling / Wiercenia zawiasów');return unless values
      c=validate(keys.zip(values).to_h);c.each { |k,v|Sketchup.write_default(PREF,k.to_s,v) };tool.update_settings(c) if tool
    rescue=>e;UI.messagebox(e.message)
    end
    def activate
      m=Sketchup.active_model;m.selection.clear;m.select_tool(Tool.new(validate(settings)))
    rescue=>e;UI.messagebox(e.message)
    end
    class Tool < CarcassJoinery::Tool
      include HingeToolPanel
      def initialize(c);@settings=c;@held={};@mode=:add;end
      def activate;show_mode;end
      def show_mode;Sketchup.set_status_text(HingeDrilling.l('Zawiasy: +/− lub kółko zmienia liczbę · klik frontu stosuje · Alt usuwa · Ctrl aktualizuje · Esc kończy','Hinges: +/− or wheel changes count · click front to apply · Alt removes · Ctrl updates · Esc finishes'));end
      def mode(flags=0);@held[:alt] || flags&ALT_MODIFIER_MASK!=0 ? :remove : (@held[:ctrl] || flags&COPY_MODIFIER_MASK!=0 ? :update : :add);end
      def onKeyDown(key,repeat,flags,view);change_key(key,true,view);end
      def onKeyUp(key,repeat,flags,view);change_key(key,false,view);end
      def change_key(key,down,view)
        name=key==ALT_MODIFIER_KEY ? :alt : (key==COPY_MODIFIER_KEY ? :ctrl : nil);return unless name
        @held[name]=down;@mode=mode;@remove=@mode==:remove;@refresh=@mode==:update;@plan=nil;view.invalidate;true
      end
      def onMouseMove(flags,x,y,view)
        current=mode(flags);@plan=nil if current!=@mode;@mode=current;@remove=@mode==:remove;@refresh=@mode==:update
        @panel_hover=panel_hit(x,y)
        if @panel_hover;view.invalidate;return;end
        ph=view.pick_helper;ph.do_pick(x,y);found=nil
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e|HingeDrilling.instance?(e) }
          raw.length.downto(1) { |n|if HingeDrilling.front?(raw[n-1]);found=raw.take(n);break;end };break if found
        end
        if found
          if @path!=found || !@plan
            b=HingeDrilling.front_board(found,Sketchup.active_model)
            @plan=@remove ? {shelf:b,holes:[]} : HingeDrilling.plan(found,panel_settings(found))
          end
          @path=found
        else;@path=nil;@plan=nil;end
        view.invalidate
      rescue=>e;@path=nil;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def onLButtonDown(flags,x,y,view)
        return panel_click(x,y,view) if panel_hit(x,y)
        @path=nil;@plan=nil;onMouseMove(flags,x,y,view);return unless @path
        effective_mode=@mode
        effective_mode=:update if effective_mode==:add && @quick_settings_changed && @path.last.get_attribute(DICT,'owner')
        r=HingeDrilling.apply([@path],panel_settings,Sketchup.active_model,mode:effective_mode,store_layout:!!@quick_settings_changed)
        Sketchup.set_status_text("Hinges: #{r[:created]} new / #{r[:existing]} existing / #{r[:removed]} removed.")
        @path=nil;@plan=nil;view.invalidate
      rescue=>e;UI.messagebox(e.message)
      end
      def getMenu(menu);menu.add_item(HingeDrilling.l('Ustawienia wierceń zawiasów…','Hinge drilling settings…')) { HingeDrilling.show_settings(self) };end
      def update_settings(c);@quick_settings_changed=true;super;end
      def draw(view);super;draw_hinge_panel(view);end
      def deactivate(view);@held={};view.invalidate;end
    end
    def install
      return if @command
      @command=UI::Command.new('ELFIS — Hinge Drilling / Wiercenia zawiasów') { activate }
      @command.tooltip=l('Zawiasy Ø35 + 2 × Ø8 we froncie, Ø5 w boku. Prawy klik: ustawienia.','Hinges: Ø35 + 2 × Ø8 in the front, Ø5 in the side. Right-click: settings.')
      @command.small_icon=File.join(__dir__,'hinge_drilling.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command);toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
    end
  end
end
