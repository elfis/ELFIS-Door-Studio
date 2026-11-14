require 'json'
%w[shelf_spacing_layout.rb shelf_spacing_tool.rb shelf_spacing.rb].each { |f|load File.join(__dir__,'elfis_bastille_podmien_front',f) }
module ElfisShelfSpacing2937Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;settings=Elfis::StudioSettings;a=Elfis::ShelfSpacing;pins=Elfis::ShelfPins;context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(settings.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;settings.save(settings.defaults);m.start_operation('Shelf arrangement tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Shelf arrangement fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0]);body=m.layers['Body']||m.layers.add('Body');back=m.layers['Back Wall']||m.layers.add('Back Wall')
   left=box(root.entities,'Left side',[0,0,0,18,530,720],body);right=box(root.entities,'Right side',[432,0,0,18,530,720],body)
   base=box(root.entities,'Cabinet base',[18,0.5,0,414,511.5,18],body);top=box(root.entities,'Cabinet top',[18,0.5,702,414,511.5,18],body);box(root.entities,'Cabinet back',[18,512,0,414,18,720],back)
   shelves=[150,350,550].map { |z|box(root.entities,'Shelf',[18,10,z,414,480,18],body) }
   oak=m.materials['Spacing test oak']||m.materials.add('Spacing test oak');shelves.first.material=oak
   pins.apply(shelves.map { |e|[root,e] },pins.defaults.merge(reuse:false),m,operation:false)
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([14000.mm,0,0]))
   info=a.inspect_cabinet([root],m);check(info[:shelves].length==3 && (info[:high]-info[:low]-684).abs<0.001,'Finds three shelves within the 684 mm clear cabinet height')
   layout=a.plan(info,3,'300,200,1,1');check(layout[:gaps].zip([300,200,65,65]).all? { |x,y|(x-y).abs<0.001 },'Mixed mm/weights subtract 54 mm of shelves')
   result=a.apply([root],layout,m,operation:false);info=a.inspect_cabinet([root],m)
   check(info[:gaps].zip([300,200,65,65]).all? { |x,y|(x-y).abs<0.001 },'Applied geometry matches all four requested clear openings')
   check(result[:added]==0 && result[:removed]==0 && result[:holes]>0,'Moving shelves regenerates their shelf-pin circles')
   check(a.inspect_cabinet([twin],m)[:gaps].zip([132,182,182,134]).all? { |x,y|(x-y).abs<0.001 },'Other shared cabinet occurrence retains its original shelf positions')
   info[:shelves].each do |b|
    groups=pins.removal_groups(b[:path],m);plan=pins.plan(b[:path],pins.defaults.merge(reuse:false),m)
    check(groups.length==plan[:holes].length && groups.all? { |g|q=Elfis::DrillingEditor.circle(g[:path],m);plan[:holes].any? { |h|h[:point].distance(q[:point]).to_mm<0.001 } },'Every owned support circle matches the new shelf position')
   end
   result=a.apply([root],a.plan(info,4,'1,1,1,1,1'),m,operation:false);info=a.inspect_cabinet([root],m)
   check(result[:added]==1 && info[:shelves].length==4 && info[:gaps].all? { |g|(g-122.4).abs<0.001 },'Increasing count clones a shelf and distributes equal clear openings')
   check(info[:shelves].last[:entity].material==oak,'New shelf retains template component material')
   owners=info[:shelves].map { |b|b[:entity].get_attribute(pins::DICT,'owner_key') };check(owners.uniq.length==4,'Each shelf receives independent drilling ownership')
   result=a.apply([root],a.plan(info,1,'3:1'),m,operation:false);info=a.inspect_cabinet([root],m)
   check(result[:removed]==3 && info[:gaps].zip([499.5,166.5]).all? { |x,y|(x-y).abs<0.001 },'Reducing count removes topmost shelves and their old support rows')
   check(Elfis::DrillingRefresh.orphan_pins([[root]],m).empty?,'No orphan shelf-pin rows remain after deletion')
   result=a.apply([root],a.plan(info,0,'1'),m,operation:false);info=a.inspect_cabinet([root],m)
   check(info[:shelves].empty? && (info[:gaps].first-684).abs<0.001,'Can remove the final shelf while preserving rails')
   result=a.apply([root],a.plan(info,2,'1,1,1'),m,operation:false);info=a.inspect_cabinet([root],m)
   check(info[:shelves].length==2 && info[:gaps].all? { |g|(g-216).abs<0.001 },'Restores shelves from the saved template after count zero')
   root.transformation=Geom::Transformation.translation([10000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,25.degrees)*Geom::Transformation.scaling(-1.1,1.0,1.2)
   info=a.inspect_cabinet([root],m);layout=a.plan(info,2,'1,1,1');a.apply([root],layout,m,operation:false);info=a.inspect_cabinet([root],m)
   check(info[:gaps].all? { |g|(g-259.2).abs<0.001 },'Rotated mirrored scaled cabinet preserves physical clear-opening calculations')
   shelf=info[:shelves].first[:entity];shelf.locked=true;rejected=false;begin;a.apply([root],a.plan(info,3,'1,1,1,1'),m,operation:false);rescue;rejected=true;end
   check(rejected,'Locked shelf is rejected before rearrangement');shelf.locked=false
   current=a.inspect_cabinet([root],m);before=current[:gaps];source=current[:shelves].first[:entity];source.transformation=Geom::Transformation.translation([0,0,1.mm])*source.transformation
   rejected=false;begin;a.apply([root],a.plan(current,2),m,operation:false);rescue;rejected=true;end
   check(rejected,'Stale preview after manual shelf movement is rejected')
   source.transformation=Geom::Transformation.translation([0,0,-1.mm])*source.transformation
   source.set_attribute(Elfis::CarcassJoinery::DICT,'owner_key','fixed-fixture')
   rejected=false;begin;a.inspect_cabinet([root],m);rescue;rejected=true;end
   check(rejected,'A generically named shelf with dowel/screw ownership is treated as fixed')
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;settings.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisShelfSpacing2937Tests.run;File.write(File.join(__dir__,'shelf_spacing_2937_native_results.json'),JSON.pretty_generate(report));puts "Shelf spacing 2.9.37: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
