require 'json'
%w[drawer_drilling.rb studio_settings.rb drilling_editor.rb drilling_refresh.rb].each { |f|load File.join(__dir__,'elfis_bastille_podmien_front',f) }
module ElfisDrawer2933Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;d=Elfis::DrillingEditor;t=Elfis::DrawerDrilling;r=Elfis::DrillingRefresh;h=Elfis::HingeDrilling
  context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults)
   real=m.entities.find { |e|t.instance?(e)&&e.name=='szuflady' }
   if real && ENV['ELFIS_TEST_REFERENCE_DRAWERS']=='1'
    fs=d.fronts(real,m).sort_by { |f|f[:points].map(&:z).min }
    check(fs.length==3,'Reference szuflady has three fronts')
    fs.each_with_index do |f,i|
     p=t.plan(f[:path],t.defaults,m)
     check(p[:variant]==(i<2 ? 'D' : 'M'),'Reference variants resolve to D, D, M')
     check((p[:overlay]-(i==0 ? 17 : 0)).abs<0.01,'Automatic overlay matches actual front overlap')
     p[:holes].each do |hole|
      check(d.panel_holes(hole[:panel],m).any? { |v|v[:point].distance(hole[:point]).to_mm<0.01 && (v[:diameter]-hole[:diameter]).abs<0.01 && (v[:depth]-hole[:depth]).abs<0.01 },'Planned front/side circle exactly matches imported 500 mm reference')
     end
    end
   end
   m.start_operation('Drawer drilling tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Drawer test';root.transformation=Geom::Transformation.translation([10000.mm,0,0])
   body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall');facade=m.layers['Facade']||m.layers.add('Facade')
   box(root.entities,'Left cabinet side',[0,18,0,18,560,720],body);box(root.entities,'Right cabinet side',[782,18,0,18,560,720],body)
   box(root.entities,'Cabinet base',[18,18,0,764,540,18],body);box(root.entities,'Cabinet back',[18,558,0,764,18,720],rear)
   fs=[[1,283,'D'],[288.5,283,'D'],[576,140,'M']].map do |z,height,type|
    front=box(root.entities,'Drawer front',[2,0,z,796,18,height],facade)
    p=t.plan([root,front],t.defaults.merge(variant:type),m)
    check(p[:holes].length==(type=='D' ? 12 : 10),'Each M/D plan has the correct number of front and side holes')
    t.apply([[root,front]],t.defaults.merge(variant:type),m,operation:false)
    front
   end
   check(d.scan(roots:[root],model:m)[:rows].count { |v|v[:kind].to_s.start_with?('drawer_') }==34,'Existing drilling recognizes all 34 owned drawer circles')
   # Simulate an import: discard ownership while preserving the CNC groups.
   fs.each { |v|v.delete_attribute(t::DICT) }
   walk=nil;walk=->(ents) { ents.each { |v|if t.instance?(v);v.delete_attribute(t::DICT) if v.get_attribute(t::DICT,'kind');walk.call(v.definition.entities);end } };walk.call(root.entities)
   scan=d.scan(roots:[root],model:m);rows=scan[:rows].select { |v|v[:kind].to_s.start_with?('drawer_') }
   check(rows.length==34 && rows.none? { |v|v[:owned] },'Unowned reference-like drilling is recognized with front association')
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([13000.mm,0,0]))
   result=t.apply(fs.map { |v|[root,v] },t.defaults,m,operation:false)
   check(result[:created]==0 && result[:existing]==34,'Insertion adopts matching imported holes without duplicates')
   check(d.scan(roots:[twin],model:m)[:rows].none? { |v|v[:owned] },'Adoption leaves other cabinet copies unowned and unchanged')
   fs=root.definition.entities.select { |v|t.front?(v) }.sort_by { |v|t.front_board([root,v],m)[:points].map(&:z).min }
   check(fs.map { |v|v.get_attribute(t::DICT,'variant') }==%w[D D M],'Stored per-front variants survive Auto selection')
   check(t.associated([root,fs[0]],m).length==12,'A drawer front owns its front and both runner drilling sets')
   fs[1].transformation=Geom::Transformation.translation([0,0,20.mm])*fs[1].transformation
   result=r.apply([[root,fs[1]]],m,operation:false)
   check(result[:created]==12 && result[:removed]==12,'Refresh drilling regenerates a moved D drawer')
   updated=d.scan(roots:[root],model:m)[:rows].select { |v|v[:source]&&v[:source][:entity]==fs[1] }
   check(updated.select { |v|v[:kind]==:drawer_slide }.all? { |v|(v[:point].z.to_mm-343.5).abs<0.01 },'Runner rows follow the front after movement')
   p=t.plan([root,fs[0]],t.defaults.merge(overlay_mode:'Manual',overlay:20),m)
   check((p[:overlay]-20).abs<0.01,'Manual overlay overrides automatic cabinet-base detection')
   root.transformation=Geom::Transformation.translation([10000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,28.degrees)*Geom::Transformation.scaling(-1,1,1)
   result=t.apply([[root,fs[2]]],t.defaults,m,operation:false,mode: :update)
   check(result[:created]==10 && result[:removed]==10,'Updates M drawer under rotated/reflected cabinet')
   result=t.apply([[root,fs[2]]],t.defaults,m,operation:false,mode: :remove)
   check(result[:removed]==10 && t.associated([root,fs[2]],m).empty?,'Alt removes only the selected drawer front/side groups')
   check(t.associated([root,fs[0]],m).length==12,'Removing M preserves neighbouring D drawer drilling')
   small_rejected=false;begin;t.plan([root,fs[2]],t.defaults.merge(variant:'D'),m);rescue RuntimeError;small_rejected=true;end
   check(small_rejected,'D gallery drilling is rejected on a 140 mm front before mutation')
   fs[0].transformation=Geom::Transformation.translation([0,0,1000.mm])*fs[0].transformation
   before=t.associated([root,fs[0]],m).length
   failed=false;begin;r.apply([[root,fs[0]]],m,operation:false);rescue RuntimeError;failed=true;end
   check(failed && t.associated([root,fs[0]],m).length==before,'Invalid moved front keeps all old drawer drilling intact')
   begin;t.plan([root,fs[2]],t.defaults.merge(length:450),m);raise 'Unsupported runner accepted';rescue=>e;check(e.message.include?('500'),'Unverified runner lengths are rejected');end
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisDrawer2933Tests.run;File.write(File.join(__dir__,'drawers_2933_native_results.json'),JSON.pretty_generate(report));puts "Drawer drilling 2.9.33: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
