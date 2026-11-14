require 'json'
load File.join(__dir__,'elfis_bastille_podmien_front','drilling_refresh.rb')
module ElfisRefresh2930Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;r=Elfis::DrillingRefresh;h=Elfis::HingeDrilling;j=Elfis::CarcassJoinery;k=Elfis::HangerCutouts;d=Elfis::DrillingEditor;pins=Elfis::ShelfPins
  context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults);m.start_operation('Refresh all tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Refresh all fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0])
   body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall');facade=m.layers['Facade']||m.layers.add('Facade')
   left=box(root.entities,'Left side',[0,0,0,18,530,720],body);box(root.entities,'Right side',[432,0,0,18,530,720],body)
   base=box(root.entities,'Cabinet base',[18,0,0,414,530,18],body)
   box(root.entities,'Cabinet top',[18,0,702,414,530,18],body)
   shelf=box(root.entities,'Shelf',[18,0,350,414,480,18],body)
   back=box(root.entities,'Cabinet back',[18,500,0,414,18,720],rear)
   front=box(root.entities,'Front',[2,-20,1,446,18,715],facade)
   j.apply([[root,base],[root,back]],j.defaults,m,operation:false)
   pins.apply([[root,shelf]],pins.defaults,m,operation:false)
   h.apply([[root,front]],h.defaults.merge(side:'Left'),m,operation:false)
   k.apply([[root,back]],k.preset,m,operation:false)
   paths=r.source_paths(root,m)
   check(paths.length==4,'Cabinet selection discovers joint sources, shelf, front and back')
   check(r.plan([root,back],m)[:refresh_kinds].sort==[:joint,:kamar],'One back can refresh screw rows and Kamar routing together')
   circles=d.scan(roots:[root],model:m)[:rows].count { |v|v[:kind]!=:kamar }
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([13000.mm,0,0]))
   front.transformation=Geom::Transformation.translation([0,0,5.mm])*front.transformation
   shelf.transformation=Geom::Transformation.translation([0,0,50.mm])*shelf.transformation
   # Remove one contour to verify that refresh repairs missing routing.
   target=k.plan([root,back],k.preset,m)[:corners].first[:existing];target.erase!
   result=r.apply(paths,m,operation:false)
   check(result[:removed]==circles && result[:created]==circles+1,'One batch regenerates all circular drilling and repairs a missing Kamar contour')
   updated=d.scan(roots:[root],model:m)
   check(updated[:rows].count { |v|v[:kind]==:kamar }==2 && updated[:rows].length==circles+2,'Refresh leaves exactly one complete set of circles and routing')
   newfront=root.definition.entities.find { |v|h.front?(v) }
   cp=updated[:rows].select { |v|v[:kind]==:cup }.map { |v|v[:point].z.to_mm.round(3) }.sort
   check(cp==[106.0,621.0],'Front cup heights update after moving the front')
   plates=updated[:rows].select { |v|v[:kind]==:hinge_plate }.map { |v|v[:point].z.to_mm.round(3) }.sort
   check(plates==[90.0,122.0,605.0,637.0],'Side mounting plates follow the moved front cup axes')
   check(d.scan(roots:[twin],model:m)[:rows].length==circles+1,'Other cabinet instance retains its original drilling and its missing contour state')
   result=r.apply(r.source_paths(root,m),m,operation:false)
   check(result[:created]==circles && d.scan(roots:[root],model:m)[:rows].length==circles+2,'Repeated complete refresh does not multiply operations')
   newfront.transformation=Geom::Transformation.translation([0,0,900.mm])*newfront.transformation
   before=d.scan(roots:[root],model:m)[:rows].length
   rejected=false;begin;r.apply(r.source_paths(root,m),m,operation:false);rescue RuntimeError;rejected=true;end
   check(rejected && d.scan(roots:[root],model:m)[:rows].length==before,'Invalid hinge destination prevents every removal in the batch')
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisRefresh2930Tests.run;File.write(File.join(__dir__,'refresh_2930_native_results.json'),JSON.pretty_generate(report));puts "Refresh drilling 2.9.30: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
