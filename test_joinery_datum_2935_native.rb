require 'json'
%w[carcass_joinery_layout.rb carcass_joinery.rb].each { |f|load File.join(__dir__,'elfis_bastille_podmien_front',f) }
module ElfisJoineryDatum2935Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def grid(a,path,c,m,label)
  p=a.plan(path,c,m);high=a.front_high?(p,a.surroundings(path,m));sb=p[:bounds];front=high ? sb.max.y : sb.min.y;direction=high ? -1 : 1
  wanted=c[:pattern].split.each_with_index.filter_map { |k,i|next if k=='-';pos=31+i*32;dia=k=='D' ? 8 : 3;pos if pos-dia/2.0>0.01 && pos+dia/2.0<(sb.max.y-sb.min.y).to_mm-0.01 }
  p[:holes].group_by { |h|h[:panel][:path] }.each_value do |holes|
   actual=holes.map { |h|(h[:point].transform(p[:inverse]).y-front).to_mm*direction }.sort
   check(actual.length==wanted.length && actual.zip(wanted).all? { |x,y|(x-y).abs<0.001 },label+' — every spindle is measured from source front')
  end
  p
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;a=Elfis::CarcassJoinery;r=Elfis::DrillingRefresh;context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults);m.start_operation('Joinery datum tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Source front datum fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0]);body=m.layers['Body']||m.layers.add('Body');back=m.layers['Back Wall']||m.layers.add('Back Wall')
   box(root.entities,'Left side',[0,0,0,18,560,720],body);box(root.entities,'Right side',[432,0,0,18,560,720],body);rear=box(root.entities,'Cabinet back',[18,540,0,414,18,720],back)
   base=box(root.entities,'Cabinet base',[18,0.5,0,414,539.5,18],body);top=box(root.entities,'Top cross member',[18,10,702,414,100,18],body);fixed=box(root.entities,'Fixed shelf',[18,10,350,414,530,18],body)
   c=a.defaults.merge(front:31.0)
   p=grid(a,[root,base],c,m,'Bottom recessed 0.5 mm')
   check(p[:holes].map { |h|h[:point].transform(root.transformation.inverse).y.to_mm }.min.round(4)==31.5,'31 mm from base front is 31.5 mm from side front')
   check((p[:holes].first[:point].transform(root.transformation.inverse).z.to_mm-9.2).abs<0.001,'Bottom inward correction remains 0.2 mm')
   grid(a,[root,top],c,m,'Short top rail recessed 10 mm');grid(a,[root,fixed],c,m,'Fixed shelf recessed 10 mm')
   a.apply([[root,base]],c,m,operation:false);before=a.removal_groups([root,base],m).length
   base.transformation=Geom::Transformation.translation([0,9.5.mm,0])*base.transformation
   config=s.data;config[:joints]=config[:joints].merge(front:31.0);s.save(config)
   result=r.apply([[root,base]],m,operation:false)
   q=a.removal_groups([root,base],m)
   centers=q.map { |h|Elfis::DrillingEditor.circle(h[:path],m)[:point].transform(root.transformation.inverse).y.to_mm }
   check(result[:removed]==before && result[:created]==before && q.length==before,'Refresh replaces the entire old owned pattern without duplicates')
   check((centers.min-41.0).abs<0.001 && centers.none? { |y|(y-31.5).abs<0.001 },'After moving base to 10 mm, Refresh moves first side axis to 41 mm')
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([14000.mm,0,0]))
   root.transformation=Geom::Transformation.translation([10000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,27.degrees)*Geom::Transformation.scaling(-1.1,1.2,1.0)
   grid(a,[root,base],c,m,'Rotated, reflected and scaled base')
   a.apply([[root,base]],c,m,operation:false)
   check(a.removal_groups([twin,base],m).length==before,'Updating a cabinet copy preserves its twin drilling')
   # Reversed cabinet: front is the high end of depth, not local min Y.
   reverse=m.entities.add_group;reverse.transformation=Geom::Transformation.translation([17000.mm,0,0])
   box(reverse.entities,'Left side',[0,0,0,18,560,720],body);box(reverse.entities,'Right side',[432,0,0,18,560,720],body);box(reverse.entities,'Cabinet back',[18,2,0,414,18,720],back)
   rb=box(reverse.entities,'Cabinet base',[18,20,0,414,539.5,18],body)
   p=grid(a,[reverse,rb],c,m,'Reversed front recessed 0.5 mm')
   check((560-p[:holes].map { |h|h[:point].transform(reverse.transformation.inverse).y.to_mm }.max-31.5).abs<0.001,'Reversed front gives 31.5 mm from actual side front')
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisJoineryDatum2935Tests.run;File.write(File.join(__dir__,'joinery_datum_2935_native_results.json'),JSON.pretty_generate(report));puts "Joinery source datum 2.9.35: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
