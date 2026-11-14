require 'json'
load File.join(__dir__,'elfis_bastille_podmien_front/hanger_cutouts.rb')
module ElfisHangerRemovalTests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def volume(back)
  back.definition.entities.grep(Sketchup::Face).sum { |f|f.area*f.vertices.first.position.to_a.zip(f.normal.to_a).sum { |a,n|a*n }/3 }.abs*(25.4**3)
 end
 def run
  @checks=[];m=Sketchup.active_model;h=Elfis::HangerCutouts;s=Elfis::StudioSettings
  context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.active_path=nil;s.save(s.defaults)
   m.start_operation('ELFIS hanger removal tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.transformation=Geom::Transformation.translation([10000.mm,0,0])
   body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall')
   box(root.entities,'Left side',[0,0,0,18,530,720],body);box(root.entities,'Right side',[432,0,0,18,530,720],body)
   back=box(root.entities,'Cabinet back',[18,0,0,414,18,720],rear)
   component=m.materials.add('ELFIS removal component');back.material=component
   outside=m.materials.add('ELFIS removal exterior');inside=m.materials.add('ELFIS removal interior');edge=m.materials.add('ELFIS removal edge')
   back.definition.entities.grep(Sketchup::Face).each do |face|
    face.material=outside if face.normal.y< -0.9
    face.material=inside if face.normal.y>0.9
    face.material=edge if face.normal.z>0.9
   end
   foreign=back.definition.entities.add_group;foreign.name='Unrelated drilling';foreign.entities.add_circle([40.mm,0,100.mm],Y_AXIS,1.5.mm,24)
   h.apply([[root,back]],h.preset,m,operation:false)
   r=h.remove([[root,back]],h.preset,m,operation:false)
   check(r[:filled]==2 && r[:removed]==2,'Removal fills both notches and removes exactly two L routing groups')
   p=h.plan([root,back],h.preset,m)
   check(p[:corners].all? { |c|c[:cut] && !c[:existing] },'Both corners are solid again with no matching routing vectors')
   check(back.definition.entities.grep(Sketchup::Edge).all? { |e|e.faces.length==2 },'Repaired back has a closed shell with no loose internal edges')
   check((volume(back)-414*18*720).abs<0.1,'Repaired volume equals the original rectangular panel')
   check(back.definition.entities.grep(Sketchup::Face).length==6,'Coplanar repair seams are merged back into six panel faces')
   faces=back.definition.entities.grep(Sketchup::Face)
   check(faces.select { |f|f.normal.y< -0.9 }.all? { |f|f.material==outside } && faces.select { |f|f.normal.y>0.9 }.all? { |f|f.material==inside } && faces.select { |f|f.normal.z>0.9 }.all? { |f|f.material==edge },'Exterior, interior and edge materials extend over the filled corners')
   check(back.material==component && foreign.valid? && foreign.entities.grep(Sketchup::Edge).length==24,'Component material and unrelated drilling remain unchanged')
   check(back.get_attribute(h::DICT,'preset').nil?,'Removed hanger metadata is cleared from the repaired back')
   r=h.remove([[root,back]],h.preset,m,operation:false)
   check(r[:filled]==0 && r[:removed]==0 && (volume(back)-414*18*720).abs<0.1,'Repeated removal is harmless on a rectangular back')
   h.apply([[root,back]],h.preset,m,operation:false)
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([12000.mm,0,0]))
   r=h.remove([[root,back]],h.preset,m,operation:false)
   back=root.definition.entities.find { |e|h.instance?(e) && e.name=='Cabinet back' }
   tb=twin.definition.entities.find { |e|h.instance?(e) && e.name=='Cabinet back' }
   check(h.plan([root,back],h.preset,m)[:corners].all? { |v|v[:cut] } && h.plan([twin,tb],h.preset,m)[:corners].all? { |v|!v[:cut] && v[:existing] },'Removing from a cabinet copy preserves the other copy and its CNC contours')
   check(m.layers['Kamar D6.0_DEPTH_8.0'] && h.plan([twin,tb],h.preset,m)[:corners].all? { |v|v[:existing].definition.entities.all? { |e|e.layer.name=='Kamar D6.0_DEPTH_8.0' } },'Shared vector tag remains available for other cabinets')
   # Restore a mirrored/scaled copy and verify full local volume/topology.
   twin.transformation=Geom::Transformation.translation([12000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,30.degrees)*Geom::Transformation.scaling(-1,1,1)
   r=h.remove([[twin,tb]],h.preset,m,operation:false)
   check(r[:filled]==2 && r[:removed]==2 && (volume(tb)-414*18*720).abs<0.1,'Rotated mirrored cabinet is restored without changing the other panel')
   twin.transformation=Geom::Transformation.translation([12000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,30.degrees)*Geom::Transformation.scaling(-1.2,1,0.8)
   h.apply([[twin,tb]],h.preset,m,operation:false)
   r=h.remove([[twin,tb]],h.preset,m,operation:false)
   check(r[:filled]==2 && r[:removed]==2 && (volume(tb)-414*18*720).abs<0.1 && tb.definition.entities.grep(Sketchup::Edge).all? { |e|e.faces.length==2 },'Scaled mirrored cabinet repairs its physical cutouts into the original closed panel')
   h.apply([[root,back]],h.preset,m,operation:false)
   p=h.plan([root,back],h.preset,m);p[:corners].first[:existing].locked=true
   rejected=false;begin;h.remove([[root,back]],h.preset,m,operation:false);rescue RuntimeError;rejected=true;end
   check(rejected && (volume(back)-(414*18*720-2*20*55*18)).abs<0.1,'Locked routing stops removal before filling any corner')
   p[:corners].first[:existing].locked=false
   legacy=m.layers['Kamar D6.0_DEPTH_18.5']||m.layers.add('Kamar D6.0_DEPTH_18.5')
   p[:corners].each { |c|g=c[:existing];g.name='';g.layer=legacy;g.delete_attribute(h::DICT) }
   r=h.remove([[root,back]],h.preset,m,operation:false)
   check(r[:filled]==2 && r[:removed]==2,'Matching legacy Kamar loops can be removed and their cutouts filled')
   tool=h::Tool.new;view=m.active_view
   check(tool.onKeyDown(ALT_MODIFIER_KEY,1,0,view)==true && tool.removing? && tool.instance_variable_get(:@remove),'Holding Alt enters removal mode and consumes the menu accelerator')
   tool.onKeyDown(ALT_MODIFIER_KEY,2,0,view)
   check(tool.removing?,'Alt key repeat does not toggle back to adding')
   check(tool.onKeyUp(ALT_MODIFIER_KEY,1,0,view)==true && !tool.removing? && !tool.instance_variable_get(:@remove),'Releasing Alt immediately restores adding mode')
   check(tool.removing?(ALT_MODIFIER_MASK),'Mouse-event Alt flags also select removal mode')
   report={passed:true,checks:@checks}
  rescue Exception=>e;report={passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old)
   m.active_path=context if context && context.all?(&:valid?)
   m.selection.clear;m.selection.add(selection.select(&:valid?))
   File.write(File.join(__dir__,'hanger_removal_2925_native_results.json'),JSON.pretty_generate(report));puts "Hanger removal 2.9.25: #{report[:passed] ? 'PASS' : 'FAIL'} #{@checks.length} checks; model restored."
   puts report[:error] unless report[:passed]
  end
 end
end
ElfisHangerRemovalTests.run
