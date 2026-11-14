# encoding: UTF-8
require 'securerandom'
module Elfis
  module DrawerDrilling
    extend self
    DICT='ElfisDrawerDrilling' unless const_defined?(:DICT)
    PREF='ELFIS Drawer Drilling' unless const_defined?(:PREF)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def instance?(e);CarcassJoinery.instance?(e);end
    def front?(e);HingeDrilling.front?(e);end
    def front_board(path,m);HingeDrilling.front_board(path,m);end
    def defaults;{variant:'Auto',length:500,overlay_mode:'Auto',overlay:0.0,pilot_depth:3.0,gallery_depth:12.0,slide_depth:12.0};end
    def settings;defaults.to_h { |k,v|[k,Sketchup.read_default(PREF,k.to_s,v)] };end
    def validate(c)
      c=defaults.merge(c);raise 'Choose Auto, M or D.' unless %w[Auto M D].include?(c[:variant])
      raise 'Only the verified TANDEMBOX 500 mm runner is supported.' unless Float(c[:length])==500
      raise 'Choose Auto or Manual overlay.' unless %w[Auto Manual].include?(c[:overlay_mode])
      c[:overlay]=Float(c[:overlay]);raise 'Invalid bottom overlay.' unless c[:overlay].finite? && c[:overlay]>=0 && c[:overlay]<=150
      %i[pilot_depth gallery_depth slide_depth].each { |k|c[k]=Float(c[k]);raise "Invalid #{k}." unless c[k].finite? && c[k]>0 && c[k]<=30 };c
    end
    def variant(path,c,m)
      return c[:variant] unless c[:variant]=='Auto'
      saved=path.last.get_attribute(DICT,'variant');return saved if %w[M D].include?(saved)
      b=front_board(path,m);hs=DrillingEditor.panel_holes(b,m)
      return 'D' if hs.count { |v|(v[:diameter]-10).abs<0.01 }==2 && hs.count { |v|(v[:diameter]-2.5).abs<0.01 }==4
      return 'M' if hs.count { |v|(v[:diameter]-2.5).abs<0.01 }==4 && hs.none? { |v|(v[:diameter]-10).abs<0.01 }
      raise l('Wybierz wariant M lub D w ustawieniach szuflad. Auto rozpoznaje zapisany wariant lub istniejące wiercenia.','Choose M or D in drawer settings. Auto recognizes a saved variant or existing drilling.')
    end
    def plan(path,c=settings,m=Sketchup.active_model)
      c=validate(c);raise 'A front or its parent is locked.' if path.any?(&:locked?)
      b=front_board(path,m);all=CarcassJoinery.surroundings(path,m);normal=b[:axes][b[:thin]]
      sides=all.select { |s|StudioSettings.role?(s[:entity],:sides) && !CarcassJoinery.back?(s) && s[:axes][s[:thin]].dot(Z_AXIS).abs<0.001 && s[:axes][s[:thin]].dot(normal).abs<0.001 }
      raise 'No cabinet sides found.' if sides.empty?
      center=ShelfPins.projected(b[:points],IDENTITY).center
      sc=Geom::Point3d.new((0..2).map { |i|sides.sum { |s|s[:points].sum { |q|q[i] }/8.0 }/sides.length })
      inward=center.vector_to(sc).dot(normal)>0 ? normal : normal.reverse;width=inward.cross(Z_AXIS).normalize
      frame=Geom::Transformation.axes(ORIGIN,width,inward,Z_AXIS);inv=frame.inverse;fb=ShelfPins.projected(b[:points],inv)
      targets=[:left,:right].map do |side|
        edge=side==:left ? fb.min.x : fb.max.x
        found=sides.filter_map do |s|
          sb=ShelfPins.projected(s[:points],inv);delta=(sb.center.x-edge).abs
          next unless delta<40.mm && sb.min.y>=fb.max.y-5.mm && sb.min.y<=fb.max.y+30.mm
          [delta,s,sb]
        end.sort_by(&:first)
        raise 'No unambiguous adjacent cabinet side.' if found.empty? || (found.length>1 && (found[0][0]-found[1][0]).abs<0.01.mm)
        found.first
      end
      raise 'The same cabinet side was matched twice.' if targets[0][1][:path]==targets[1][1][:path]
      left=targets[0][2].max.x;right=targets[1][2].min.x
      raise 'Front does not cover both runner fixing lines.' unless left+15.5.mm>fb.min.x && right-15.5.mm<fb.max.x && right-left>40.mm
      overlay=c[:overlay].mm
      if c[:overlay_mode]=='Auto'
        rails=all.select { |p|CarcassJoinery.horizontal?(p) && ![p[:entity].name,p[:entity].definition.name].join(' ').match?(/drawer|szuflad/i) }.filter_map do |p|
          pb=ShelfPins.projected(p[:points],inv)
          next unless pb.min.x<=left+1.mm && pb.max.x>=right-1.mm && pb.min.y<=fb.max.y+2.mm && pb.max.y>fb.max.y+30.mm
          delta=pb.max.z-fb.min.z
          delta if delta>0.01.mm && delta<=80.mm
        end
        overlay=rails.empty? ? 0.mm : rails.min
      end
      type=variant(path,c,m);datum=fb.min.z+overlay;holes=[]
      [[left+15.5.mm,targets[0]], [right-15.5.mm,targets[1]]].each_with_index do |(x,target),i|
        _,side,sb=target
        raise 'A cabinet side or its parent is locked.' if side[:path].any?(&:locked?)
        backs=all.select { |p|CarcassJoinery.back?(p) }.map { |p|ShelfPins.projected(p[:points],inv) }.select { |p|p.max.x>left && p.min.x<right && p.min.y>sb.min.y }
        rear=([sb.max.y]+backs.map(&:min).map(&:y)).min
        raise 'The cabinet has insufficient clear depth for a 500 mm runner (503 mm required).' if rear-sb.min.y<503.mm-0.01.mm
        [[49.5,2.5,c[:pilot_depth],:drawer_front],[81.5,2.5,c[:pilot_depth],:drawer_front],*(type=='D' ? [[209.5,10,c[:gallery_depth],:drawer_gallery]] : [])].each do |z,d,depth,kind|
          h={panel:b,point:Geom::Point3d.new(x,fb.max.y,datum+z.mm).transform(frame),normal:inward.reverse,tangent:Z_AXIS,diameter:d,depth:depth,kind:kind};HingeDrilling.check_front(h);holes<<h
        end
        [19,37,261].each do |y|
          xx=i==0 ? sb.max.x : sb.min.x
          h={panel:side,point:Geom::Point3d.new(xx,sb.min.y+y.mm,datum+35.mm).transform(frame),normal:i==0 ? width.reverse : width,tangent:Z_AXIS,diameter:5,depth:c[:slide_depth],kind: :drawer_slide}
          CarcassJoinery.check_circle(h);holes<<h
        end
      end
      {shelf:b,holes:holes,variant:type,overlay:overlay.to_mm,settings:c}
    end
    def show_settings(tool=nil);StudioSettings.show('drawers');end
    def activate
      m=Sketchup.active_model;m.selection.clear;m.select_tool(Tool.new(validate(settings)))
    rescue=>e;UI.messagebox(e.message)
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
    def apply(paths,c=settings,m=Sketchup.active_model,operation:true,mode: :add)
      paths=paths.uniq { |p|p.map(&:persistent_id) };raise 'No fronts selected.' if paths.empty?
      raise 'Make the open cabinet unique first.' if Array(m.active_path).any? { |e|e.definition.instances.length>1 }
      paths.each { |p|front_board(p,m);raise 'A front or its parent is locked.' if p.any?(&:locked?);associated(p,m);plan(p,c,m) unless mode==:remove }
      token=SecureRandom.uuid;temp='ElfisDrawerTemp';marked=[];created=0;existing=0;removed=0
      m.start_operation(l('ELFIS — Wiercenia szuflad','ELFIS — Drawer drilling'),true) if operation
      begin
        mark=->(p) { p.each { |e|e.set_attribute(temp,token,e.persistent_id.to_s);marked<<e };[p.first,p.map { |e|e.get_attribute(temp,token) }] }
        resolve=->(ref) do
          p=[ref[0]];ref[1].drop(1).each { |id|v=p.last.definition.entities.find { |e|instance?(e)&&e.get_attribute(temp,token)==id };raise 'Drilling path changed.' unless v;p<<v };p
        end
        refs=paths.map { |p|mark.call(p) }
        refs.each do |ref|
          p=BastillePodmienFront.unique_path(resolve.call(ref));e=p.last;e.make_unique if e.definition.instances.length>1
          if mode!=:add
            targets=associated(p,m).map { |q|mark.call(q) }
            targets.each { |t|q=BastillePodmienFront.unique_path(resolve.call(t));q.last.erase!;removed+=1 }
          end
          next if mode==:remove
          planned=plan(p,c,m);e.set_attribute(DICT,'variant',planned[:variant]);e.set_attribute(DICT,'length',500);owner=e.get_attribute(DICT,'owner')||SecureRandom.uuid;e.set_attribute(DICT,'owner',owner)
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
              match=old.find { |o|o[:point].distance(h[:point]).to_f<0.02.mm.to_f && (o[:diameter]-h[:diameter]).abs<0.01 && (o[:depth]-h[:depth]).abs<0.01 }
              if match
                raise 'Adopt multi-circle containers in Existing drilling first.' if match[:virtual]
                group=match[:path].last
                raise 'An existing drilling group is locked.' if match[:path].any?(&:locked?)
                foreign=[[ShelfPins::DICT,'owner_key'],[CarcassJoinery::DICT,'owner_key'],[HingeDrilling::DICT,'owner']].any? { |dict,key|group.get_attribute(dict,key) }
                raise 'A matching circle belongs to a different tool; review the drilling association.' if foreign
                group.set_attribute(DICT,'owner',owner);group.set_attribute(DICT,'kind',h[:kind].to_s)
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
    class Tool < CarcassJoinery::Tool
      def initialize(c);@settings=c;@held={};@mode=:add;end
      def activate;show_mode;end
      def show_mode;Sketchup.set_status_text(DrawerDrilling.l('Szuflady: klik dodaje · Alt usuwa powiązane · Ctrl aktualizuje · prawy klik: ustawienia · Esc kończy','Drawers: click adds · Alt removes associated drilling · Ctrl updates · right-click: settings · Esc finishes'));end
      def mode(flags=0);@held[:alt] || flags&ALT_MODIFIER_MASK!=0 ? :remove : (@held[:ctrl] || flags&COPY_MODIFIER_MASK!=0 ? :update : :add);end
      def onKeyDown(key,repeat,flags,view);change_key(key,true,view);end
      def onKeyUp(key,repeat,flags,view);change_key(key,false,view);end
      def change_key(key,down,view)
        name=key==ALT_MODIFIER_KEY ? :alt : (key==COPY_MODIFIER_KEY ? :ctrl : nil);return unless name
        @held[name]=down;@mode=mode;@remove=@mode==:remove;@refresh=@mode==:update;@plan=nil;view.invalidate;true
      end
      def onMouseMove(flags,x,y,view)
        current=mode(flags);@plan=nil if current!=@mode;@mode=current;@remove=@mode==:remove;@refresh=@mode==:update
        ph=view.pick_helper;ph.do_pick(x,y);found=nil
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e|DrawerDrilling.instance?(e) }
          raw.length.downto(1) { |n|if DrawerDrilling.front?(raw[n-1]);found=raw.take(n);break;end };break if found
        end
        if found
          if @path!=found || !@plan
            b=DrawerDrilling.front_board(found,Sketchup.active_model)
            @plan=@remove ? {shelf:b,holes:[]} : DrawerDrilling.plan(found,@settings)
          end
          @path=found
        else;@path=nil;@plan=nil;end
        view.invalidate
      rescue=>e;@path=nil;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def onLButtonDown(flags,x,y,view)
        @path=nil;@plan=nil;onMouseMove(flags,x,y,view);return unless @path
        r=DrawerDrilling.apply([@path],@settings,Sketchup.active_model,mode:@mode)
        Sketchup.set_status_text("Drawers: #{r[:created]} new / #{r[:existing]} existing / #{r[:removed]} removed.")
        @path=nil;@plan=nil;view.invalidate
      rescue=>e;UI.messagebox(e.message)
      end
      def getMenu(menu);menu.add_item(DrawerDrilling.l('Ustawienia wierceń szuflad…','Drawer drilling settings…')) { DrawerDrilling.show_settings(self) };end
      def deactivate(view);@held={};view.invalidate;end
    end
    def install
      return if @command
      @command=UI::Command.new('ELFIS — TANDEMBOX Drilling / Wiercenia szuflad') { activate }
      @command.tooltip=l('TANDEMBOX M/D 500: klik dodaje lub przejmuje; Alt usuwa; Ctrl aktualizuje; prawy klik: ustawienia','TANDEMBOX M/D 500: click adds or adopts; Alt removes; Ctrl updates; right-click: settings')
      @command.small_icon=File.join(__dir__,'drawer_drilling.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command);toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
    end
  end
end
