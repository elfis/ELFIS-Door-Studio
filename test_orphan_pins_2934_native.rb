require 'json'
load File.join(__dir__,'elfis_bastille_podmien_front','drilling_refresh.rb')
module ElfisOrphanPins2934Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;r=Elfis::DrillingRefresh;p=Elfis::ShelfPins;context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults);m.start_operation('Orphan pin tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Orphan fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0])
   body=m.layers['Body']||m.layers.add('Body')
   left=box(root.entities,'Left side',[0,0,0,18,530,720],body);right=box(root.entities,'Right side',[432,0,0,18,530,720],body)
   a=box(root.entities,'Shelf A',[18,0,250,414,500,18],body);b=box(root.entities,'Shelf B',[18,0,450,414,500,18],body)
   p.apply([[root,a],[root,b]],p.defaults,m,operation:false)
   ca=p.removal_groups([root,a],m).length;cb=p.removal_groups([root,b],m).length
   check(ca>0 && cb>0 && r.orphan_pins([[root]],m).empty?,'Live source shelves keep all associated pin circles')
   b.hidden=true;check(r.orphan_pins([[root]],m).empty?,'Hidden source is still a live shelf');b.hidden=false
   twin=m.entities.add_instance(root.definition,Geom::Transformation.translation([13000.mm,0,0]))
   path=Elfis::BastillePodmienFront.unique_path([root,a]);path.last.erase!
   check(r.orphan_pins([[root]],m).length==ca,'Deleted shelf creates orphan pin rows only in its cabinet')
   check(r.orphan_pins([[twin]],m).empty?,'Other cabinet copy with a live matching owner is preserved')
   side=root.definition.entities.find { |e|e.name=='Left side' }
   check(r.orphan_pins([[root,side]],m).empty?,'Selecting a side alone is not treated as proof that its shelf was deleted')
   # A nested wrapper must not merge ownership across distinct cabinet copies.
   wrapper=m.entities.add_group;copy=wrapper.entities.add_instance(root.definition,Geom::Transformation.new);live=wrapper.entities.add_instance(twin.definition,Geom::Transformation.translation([1000.mm,0,0]))
   check(r.orphan_pins([[wrapper]],m).length==ca,'Nearest cabinet scope prevents a neighbouring copy from hiding orphan rows')
   current_b=root.definition.entities.find { |e|e.name=='Shelf B' }
   result=r.apply([[root,current_b]],m,operation:false)
   current_b=root.definition.entities.find { |e|e.name=='Shelf B' }
   check(result[:orphans]==ca && result[:removed]==ca+cb,'Refresh removes orphan rows and regenerates surviving shelf rows in one batch')
   check(r.orphan_pins([[root]],m).empty? && p.removal_groups([root,current_b],m).length==cb,'No orphan rows remain and live shelf count is unchanged')
   check(r.orphan_pins([[wrapper]],m).length==ca,'Refreshing original occurrence isolates its shared nested copy')
   # Last shelf deleted: there are no source paths left to drive refresh.
   current_b.erase!;check(r.source_paths(root,m).empty?,'Deleted final shelf leaves no source paths')
   holes=r.orphan_pins([[root]],m);check(holes.length==cb,'Final shelf drilling is recognized without a live source')
   holes.first[:path].last.locked=true
   rejected=false;begin;r.apply([],m,operation:false,cleanup_roots:[[root]]);rescue RuntimeError;rejected=true;end
   check(rejected && r.orphan_pins([[root]],m).length==cb,'Locked orphan group prevents any deletion')
   holes.first[:path].last.locked=false
   side=root.definition.entities.find { |e|e.name=='Left side' }
   unmarked=side.definition.entities.add_group;unmarked.name='Manual CNC';unmarked.entities.add_circle(ORIGIN,Z_AXIS,2.5.mm,24)
   picker=Object.new;picker.define_singleton_method(:do_pick) { |*args| };picker.define_singleton_method(:count) { 1 };picker.define_singleton_method(:path_at) { |i|[root,side] }
   view=Object.new;view.define_singleton_method(:pick_helper) { picker };view.define_singleton_method(:invalidate) {}
   tool=r::Tool.new;tool.onMouseMove(0,10,10,view)
   check(tool.instance_variable_get(:@assembly) && tool.instance_variable_get(:@plan)[:holes].length==cb,'Refresh hover finds and previews an orphan-only cabinet through its side')
   original=r.method(:apply);r0=nil
   begin
    r.define_singleton_method(:apply) { |ps,ms=Sketchup.active_model,**opts|r0=original.call(ps,ms,**opts.merge(operation:false));r0 }
    tool.onLButtonDown(0,10,10,view)
   ensure;r.define_singleton_method(:apply,original)
   end
   check(r0[:removed]==cb && r0[:orphans]==cb && r0[:created]==0,'Refresh cleans an orphan-only cabinet without recreating deleted shelves')
   check(unmarked.valid?,'Unmarked imported/manual geometry is untouched')
   r0=r.apply([],m,operation:false,cleanup_roots:[[root]])
   check(r0[:removed]==0,'Repeated orphan cleanup is harmless')
   # Still-live source whose tag/name changed must not be mistaken for deletion.
   bb=twin.definition.entities.find { |e|e.name=='Shelf B' };bb.layer=m.layers[0];bb.name='Renamed live part'
   check(r.orphan_pins([[twin]],m).empty?,'Renamed or retagged live source is retained by ownership')
   m.active_path=[root]
   check(r.orphan_pins(root.definition.entities.select { |e|p.instance?(e) }.map { |e|[e] },m).empty?,'Open editing context never deletes unknown outside-scope drilling')
   m.active_path=nil
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisOrphanPins2934Tests.run;File.write(File.join(__dir__,'orphan_pins_2934_native_results.json'),JSON.pretty_generate(report));puts "Orphan pins 2.9.34: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
