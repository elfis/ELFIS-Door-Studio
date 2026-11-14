require 'json'
%w[hinge_drilling.rb studio_settings.rb drilling_editor.rb].each { |f|load File.join(__dir__,'elfis_bastille_podmien_front',f) }
module ElfisExisting2929Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;d=Elfis::DrillingEditor;h=Elfis::HingeDrilling;j=Elfis::CarcassJoinery;k=Elfis::HangerCutouts
  context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults)
   c=s.data;c[:hinges]=c[:hinges].merge(count:3,bottom:110,side:'Right');s.save(c)
   check(h.settings[:count]==3 && h.settings[:bottom]==110 && h.settings[:side]=='Right','Central panel saves the same hinge preferences used by the tool')
   legacy=s.data;legacy.delete(:hinges);s.save(legacy);check(h.settings[:count]==3,'Older settings callers preserve hinge preferences')
   invalid=s.data;invalid[:hinges][:count]=1
   begin;s.save(invalid);raise 'Invalid hinge count accepted';rescue=>err;check(err.message.include?('count'),'Invalid hinge defaults rejected before saving');end
   s.save(s.defaults);m.start_operation('Existing operations tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Existing operations fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0])
   body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall');facade=m.layers['Facade']||m.layers.add('Facade')
   box(root.entities,'Left side',[0,0,0,18,530,720],body);box(root.entities,'Right side',[432,0,0,18,530,720],body)
   box(root.entities,'Cabinet base',[18,0,0,414,530,18],body);box(root.entities,'Cabinet top',[18,0,702,414,530,18],body)
   back=box(root.entities,'Cabinet back',[18,500,0,414,18,720],rear)
   front=box(root.entities,'Front',[2,-20,1,446,18,715],facade)
   # Imported hinge locations differ from the 100 mm defaults.
   h.apply([[root,front]],h.defaults.merge(side:'Left',bottom:120,top:90),m,operation:false)
   k.apply([[root,back]],k.preset,m,operation:false)
   [front].each { |e|e.delete_attribute(h::DICT) };back.delete_attribute(k::DICT)
   # Each receiving panel gets an imported bundle containing several circles.
   (j.panels(root,m)+d.fronts(root,m)).each do |panel|
    groups=panel[:entity].definition.entities.select { |g|h.instance?(g)&&g.get_attribute(h::DICT,'kind') }
    next if groups.empty?
    bundle=panel[:entity].definition.entities.add_group;bundle.name='Imported multiple circles'
    groups.each do |g|
     curve=g.definition.entities.grep(Sketchup::Edge).first.curve
     edges=bundle.entities.add_circle(curve.center.transform(g.transformation),curve.normal.transform(g.transformation),curve.radius,48)
     edges.each { |v|v.layer=g.definition.entities.grep(Sketchup::Edge).first.layer };g.erase!
    end
   end
   back.definition.entities.each { |g|g.delete_attribute(k::DICT) if h.instance?(g) }
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([13000.mm,0,0]))
   scan=d.scan(roots:[root],model:m);hinges=scan[:rows].select { |v|%i[cup hinge_dowel hinge_plate].include?(v[:kind]) };kamars=scan[:rows].select { |v|v[:kind]==:kamar }
   check(hinges.length==10 && hinges.all? { |v|v[:source]&&!v[:owned] },'Recognizes imported front/side hinge circles at actual 120/90 mm offsets')
   check(hinges.count { |v|v[:kind]==:cup }==2 && hinges.count { |v|v[:kind]==:hinge_dowel }==4 && hinges.count { |v|v[:kind]==:hinge_plate }==4,'Cup, front fixing and side plate roles stay separate')
   check(kamars.length==2 && kamars.all? { |v|v[:source]&&!v[:owned] },'Recognizes both imported Kamar L contours as routing operations')
   original=scan[:rows].to_h { |v|[v[:id],v[:point]] }
   result=d.apply(scan,(hinges+kamars).map { |v|v[:id] },{},operation:false)
   check(result[:changed]==12,'Adopts hinge circles and Kamar contours in the same conversion')
   scan=d.scan(roots:[root],model:m);check(scan[:rows].count { |v|v[:owned] }==12,'Adopted drilling and routing rescan with ELFIS ownership')
   check(d.scan(roots:[twin],model:m)[:rows].none? { |v|v[:owned] },'Other cabinet copy keeps imported unowned operations')
   front=root.definition.entities.find { |v|h.front?(v) };path=[root,front]
   check(h.associated(path,m).length==10,'Adopted front and side circles are associated with one front')
   before=scan[:rows].select { |v|v[:kind]!=:kamar }.map { |v|v[:point] }
   params={cup:{diameter:35,depth:12},hinge_dowel:{diameter:8,depth:12},hinge_plate:{diameter:5,depth:10},kamar:{diameter:6,depth:8}}
   result=d.apply(scan,scan[:rows].select { |v|v[:owned] }.map { |v|v[:id] },params,update:true,operation:false)
   updated=d.scan(roots:[root],model:m)
   check(updated[:rows].select { |v|%i[cup hinge_dowel].include?(v[:kind]) }.all? { |v|v[:depth]==12 },'Changes front cup/fixing depths independently of side plates')
   check(updated[:rows].select { |v|v[:kind]==:hinge_plate }.all? { |v|v[:depth]==10 },'Changes side plate depths and machining tags')
   check(updated[:rows].select { |v|v[:kind]!=:kamar }.all? { |v|before.any? { |q|q.distance(v[:point]).to_mm<0.01 } },'Parameter conversion preserves all actual circle centres')
   check(updated[:rows].count { |v|v[:kind]==:kamar }==2,'Parameter conversion retains Kamar L geometry')
   ks=updated[:rows].select { |v|v[:kind]==:kamar }
   begin;d.apply(updated,ks.map { |v|v[:id] },{kamar:{diameter:6,depth:9}},update:true,operation:false);raise 'Changed Kamar template accepted';rescue=>err;check(err.message.include?('Kamar'),'Kamar template changes are rejected before mutation');end
   r=h.apply([path],h.defaults.merge(side:'Left'),m,operation:false,mode: :remove)
   check(r[:removed]==10,'Alt removal can remove adopted front and side hinge drilling')
   back=root.definition.entities.find { |v|j.instance?(v)&&v.name=='Cabinet back' }
   r=k.remove([[root,back]],k.preset,m,operation:false)
   check(r[:removed]==2 && r[:filled]==2,'Kamar Alt removal clears adopted contours and fills both notches')
   check(d.scan(roots:[twin],model:m)[:rows].length==12,'Other cabinet copy retains all ten circles and both contours')
   # Real reference cabinet scan remains read-only.
   top=m.entities.find { |v|h.instance?(v)&&v.name.casecmp?('top') }
   if top
    ref=d.scan(roots:[top],model:m);rs=ref[:rows].select { |v|%i[cup hinge_dowel hinge_plate].include?(v[:kind]) }
    check(rs.length==20,'Real TOP cabinet resolves both left/right hinge sets')
   end
   {passed:true,checks:@checks}
  rescue Exception=>e
   {passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisExisting2929Tests.run;File.write(File.join(__dir__,'existing_2929_native_results.json'),JSON.pretty_generate(report));puts "Existing operations 2.9.29: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
