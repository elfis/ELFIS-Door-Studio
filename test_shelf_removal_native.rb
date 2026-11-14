# encoding: UTF-8
require 'json'
load File.join(__dir__,'elfis_bastille_podmien_front','shelf_pins.rb')
module ElfisShelfPinTests
 extend self
 def check(value,message);raise message unless value;@checks<<message;end
 def box(entities,name,x,y,z,w,d,h,tag)
  g=entities.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]].map { |p| p.map(&:mm) });f.reverse! if f.normal.z<0;f.pushpull(h.mm)
  e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;a=Elfis::ShelfPins;opened=false
  begin
   cfg=a.defaults
   m.start_operation('ELFIS isolated removal verification (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='ELFIS Shelf Test'
   body=m.layers['Body']||m.layers.add('Body')
   box(root.entities,'Left side',0,0,0,18,500,720,body)
   box(root.entities,'Right side',582,0,0,18,500,720,body)
   shelf=box(root.entities,'Shelf',18,20,350,564,460,18,body)
   root.transformation=Geom::Transformation.translation([4000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,0.37)*Geom::Transformation.scaling(-1.2,1.1,1.3)
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([6000.mm,0,0]));twin.name='Untouched twin'
   r=a.apply([[root,shelf]],cfg.merge(reuse:false),m,operation:false)
   check(r[:created]==12,'Rotated, mirrored and nonuniformly scaled cabinet creates twelve holes')
   boards=a.panels(root,m);groups=boards.flat_map { |b| b[:entity].definition.entities.grep(Sketchup::Group).select { |g| g.get_attribute(a::DICT,'source') } }
   check(groups.length==12,'Every hole has its own nested group')
   check(groups.all? { |g| g.layer.name=='Blum Operations'&&g.name=='D5.0_DEPTH12.0'&&g.entities.grep(Sketchup::Face).empty?&&g.entities.grep(Sketchup::Edge).all? { |e| e.layer.name=='D5.0_DEPTH12.0' } },'Group tags, circle tags, names and vector-only geometry match the inspected convention')
   check(boards.all? { |b| b[:entity].definition.entities.grep(Sketchup::Group).all? { |g| next true unless g.get_attribute(a::DICT,'source');tr=b[:world]*g.transformation;((X_AXIS.transform(tr).length-1).abs<1e-5)&&((Y_AXIS.transform(tr).length-1).abs<1e-5) } },'Hole diameter stays physical under nonuniform cabinet scale')
   check(a.panels(twin,m).all? { |b| b[:entity].definition.entities.grep(Sketchup::Group).none? { |g| g.get_attribute(a::DICT,'source') } },'Shared cabinet copy remains untouched')
   path=a.panels(root,m).find { |b| a.shelf?(b) }[:path]
   a.apply([path],cfg.merge(reuse:false),m,operation:false)
   check(a.panels(root,m).sum { |b| b[:entity].definition.entities.grep(Sketchup::Group).count { |g| g.get_attribute(a::DICT,'source') } }==12,'Reapplying updates owned holes without multiplying groups')
   asymmetric=a.plan(path,cfg.merge(reuse:false,above:2,under:0),m)
   zs=asymmetric[:holes].map { |h| h[:point].transform(asymmetric[:inverse]).z }
   check((zs.min-(asymmetric[:bounds].min.z-cfg[:below].mm)).abs<0.01.mm && (zs.max-zs.min-64.mm).abs<0.01.mm,'Independent top/bottom counts place additional rows only on the requested side')
   r=a.apply([path],cfg.merge(reuse:false,above:0,under:0),m,operation:false)
   check(r[:created]==4 && a.panels(root,m).sum { |b| b[:entity].definition.entities.grep(Sketchup::Group).count { |g| g.get_attribute(a::DICT,'source') } }==4,'Zero additional rows gives four centre holes and refreshes previous groups')
   check(a.tag_name(cfg.merge(diameter:6.25,depth:11.5))=='D6.25_DEPTH11.5','Drilling tag preserves selected diameter and depth precision')
   bad=false;begin;a.plan(path,cfg.merge(depth:100),m);rescue;bad=true;end
   check(bad,'Through drilling is rejected for blind shelf supports')
   shelf1=a.panels(root,m).find { |b| a.shelf?(b) }[:entity]
   shelf2=box(root.definition.entities,'Shelf upper',18,20,550,564,460,18,body)
   a.apply([[root,shelf2]],cfg.merge(reuse:false),m,operation:false)
   side=a.panels(root,m).find { |b| b[:entity].name=='Left side' }[:entity]
   foreign=side.definition.entities.add_group;foreign.name='D5.0_DEPTH12.0';foreign.entities.add_circle([0,100.mm,100.mm],X_AXIS,2.5.mm,24)
   # A manually moved shelf can still remove its old associated vectors.
   shelf1.transformation=Geom::Transformation.translation([0,0,10.mm])*shelf1.transformation
   a.panels(root,m).each do |b|
    b[:entity].delete_attribute(a::DICT,'owner_key')
    b[:entity].definition.entities.grep(Sketchup::Group).each { |g| g.delete_attribute(a::DICT,'owner_key') }
   end
   second_copy=m.entities.add_instance(root.definition,Geom::Transformation.translation([8000.mm,0,0]))
   r=a.remove([[root,shelf1]],m,operation:false)
   check(r[:removed]==4,'Click removal finds owned vectors even after moving the shelf')
   remaining=a.panels(root,m).flat_map { |b| b[:entity].definition.entities.grep(Sketchup::Group) }
   check(remaining.count { |g| g.get_attribute(a::DICT,'source') }==12,'Removing one shelf preserves the other shelf drilling')
   shelf2_new=a.panels(root,m).find { |b| b[:entity].name=='Shelf upper' }[:entity]
   r=a.remove([[root,shelf2_new]],m,operation:false)
   check(r[:removed]==12,'Other shelf association survives cabinet Make Unique after the first removal')
   remaining=a.panels(root,m).flat_map { |b| b[:entity].definition.entities.grep(Sketchup::Group) }
   check(remaining.any? { |g| g.name=='D5.0_DEPTH12.0'&&!g.get_attribute(a::DICT,'source') },'Imported or unmarked drilling is preserved')
   check(a.panels(second_copy,m).sum { |b| b[:entity].definition.entities.grep(Sketchup::Group).count { |g| g.get_attribute(a::DICT,'source') } }==16,'Removing drilling from one shared cabinet preserves all vectors in the other copy')
   check(a.remove([[root,shelf2_new]],m,operation:false)[:removed]==0,'Repeated removal reports zero without deleting unrelated geometry')
   paths=a.panels(root,m).select { |b| a.shelf?(b) }.map { |b| b[:path] }
   a.apply(paths,cfg.merge(reuse:false),m,operation:false)
   r=a.remove(paths,m,operation:false)
   check(r[:removed]==24,'Selected-shelf batch removes only the two selected shelves in one operation')
   report={passed:true,checks:@checks}
  rescue Exception=>e
   report={passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened
   File.write(File.join(__dir__,'shelf_removal_native_results.json'),JSON.pretty_generate(report))
  end
  puts JSON.pretty_generate(report)
 end
end
ElfisShelfPinTests.run
