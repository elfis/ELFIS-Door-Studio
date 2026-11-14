require 'json'
# Older native fixtures restored apply as a singleton snapshot. Drop those test
# wrappers so reloading the module actually exercises the current implementation.
[Elfis::HingeDrilling,Elfis::DrillingRefresh].each { |mod|mod.singleton_class.send(:remove_method,:apply) if mod.singleton_class.instance_methods(false).include?(:apply) }
load File.join(__dir__,'elfis_bastille_podmien_front','hinge_tool_panel.rb')
load File.join(__dir__,'elfis_bastille_podmien_front','hinge_drilling.rb')
load File.join(__dir__,'elfis_bastille_podmien_front','drilling_refresh.rb')
module ElfisHingePanel2936Tests
 extend self
 def check(v,s);raise s unless v;@checks<<s;end
 def box(ents,name,values,tag)
  x,y,z,w,d,h=values.map(&:mm);g=ents.add_group;f=g.entities.add_face([[x,y,z],[x+w,y,z],[x+w,y+d,z],[x,y+d,z]]);f.reverse! if f.normal.z<0;f.pushpull(h);e=g.to_component;e.name=name;e.layer=tag;e
 end
 class Picker
  attr_accessor :path
  def initialize(path);@path=path;end
  def do_pick(*args);end
  def count;@path ? 1 : 0;end
  def path_at(i);@path;end
 end
 class View
  attr_accessor :drawing_color,:line_width,:line_stipple
  attr_reader :texts,:picker
  def initialize(path);@picker=Picker.new(path);@texts=[];end
  def pick_helper;@picker;end
  def invalidate;end
  def screen_coords(q);q;end
  def draw2d(*args);end
  def draw_text(point,text,*args);@texts<<text;end
 end
 def run
  @checks=[];m=Sketchup.active_model;s=Elfis::StudioSettings;h=Elfis::HingeDrilling;r=Elfis::DrillingRefresh;context=m.active_path;selection=m.selection.to_a;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
  begin
   m.select_tool(nil);m.active_path=nil;s.save(s.defaults);m.start_operation('Hinge panel tests (rolled back)',true);opened=true
   root=m.entities.add_group;root.name='Hinge panel fixture';root.transformation=Geom::Transformation.translation([10000.mm,0,0]);body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall');facade=m.layers['Facade']||m.layers.add('Facade')
   box(root.entities,'Left side',[0,0,0,18,530,720],body);box(root.entities,'Right side',[432,0,0,18,530,720],body);box(root.entities,'Back',[18,510,0,414,18,720],rear);front=box(root.entities,'Front',[2,-20,1,446,18,715],facade)
   tool=h::Tool.new(h.defaults);view=View.new([root,front]);tool.onMouseMove(0,500,500,view)
   check(tool.instance_variable_get(:@plan)[:holes].length==10,'Hover starts with two hinges and ten CNC circles')
   tool.onMouseMove(0,320,78,view)
   check(tool.instance_variable_get(:@path)==[root,front],'Moving into panel retains the preview front')
   tool.onLButtonDown(0,320,78,view)
   check(tool.panel_settings[:count]==3 && tool.instance_variable_get(:@plan)[:holes].length==15,'Plus button updates count and preview without applying')
   check(h.associated([root,front],m).empty?,'Panel controls do not create model drilling')
   tool.draw(view)
   check(view.texts.include?('100  ·  357.5  ·  615'),'Panel shows all three axes measured from front bottom')
   check(view.texts.any? { |t|t=='2: 357.5 mm' },'Preview labels intermediate cup position in model')
   tool.onMouseWheel(0,1,500,500,view)
   check(tool.panel_settings[:count]==4,'Wheel over hovered front adds one hinge')
   tool.onMouseWheel(0,-1,240,78,view)
   check(tool.panel_settings[:count]==3,'Wheel over count control removes one hinge')
   tool.onMouseWheel(0,1,240,118,view)
   check(tool.panel_settings[:top]==101,'Wheel over top offset adjusts its distance by 1 mm')
   tool.onLButtonDown(0,320,158,view)
   check(tool.panel_settings[:bottom]==101,'Bottom offset plus adjusts preview distance')
   tool.onLButtonDown(0,300,198,view)
   check(tool.panel_settings[:side]=='Right' && tool.instance_variable_get(:@plan)[:side]==:right,'Side controls change the receiving side in preview')
   original=h.method(:apply);click_result=nil
   begin
    h.define_singleton_method(:apply) { |ps,cs=settings,ms=Sketchup.active_model,**opts|click_result=original.call(ps,cs,ms,**opts.merge(operation:false));click_result }
    status_method=Sketchup.method(:set_status_text);box_method=UI.method(:messagebox);messages=[]
    begin
     Sketchup.define_singleton_method(:set_status_text) { |*args|messages<<args;status_method.call(*args) }
     UI.define_singleton_method(:messagebox) { |*args|messages<<args;IDOK }
     tool.onLButtonDown(0,500,500,view)
     raise "Click did not apply: #{messages.inspect}; hit=#{tool.panel_hit(500,500).inspect}; path=#{tool.instance_variable_get(:@path).inspect}; method=#{tool.method(:onLButtonDown).source_location.inspect}" unless click_result
    ensure;Sketchup.define_singleton_method(:set_status_text,status_method);UI.define_singleton_method(:messagebox,box_method);end
    check(click_result[:created]==15 && h.associated([root,front],m).length==15,'Clicking front applies the preview layout')
    check(h.layout_settings([root,front])[:count]==3 && h.layout_settings([root,front])[:top]==101,'Quick layout is stored on source front')
    tool.onMouseMove(0,500,500,view);tool.onLButtonDown(0,180,78,view);tool.onLButtonDown(0,500,500,view)
    check(click_result[:removed]==15 && click_result[:created]==10 && h.associated([root,front],m).length==10,'Reducing count replaces old owned drilling instead of leaving a third hinge')
   ensure;h.define_singleton_method(:apply,original);end
   tool.onMouseMove(0,500,500,view);tool.onLButtonDown(0,180,78,view)
   check(tool.panel_settings[:count]==2,'Minus button cannot go below two hinges')
   12.times { tool.onMouseWheel(0,1,240,78,view) }
   check(tool.panel_settings[:count]==10,'Wheel count stops at supported maximum ten')
   check(!tool.panel_change({top:400,bottom:400},view) && tool.panel_settings[:top]==101,'Invalid offsets keep the last valid preview/settings')
   fresh=h::Tool.new(h.defaults);fresh.onMouseMove(0,500,500,view)
   check(fresh.panel_settings[:count]==2 && fresh.panel_settings[:top]==101,'Reopening tool reads stored per-front layout')
   fresh.panel_change({side:'Auto'},view)
   # The existing right-hand cups must establish Auto before they are removed.
   h.apply([[root,front]],fresh.panel_settings,m,operation:false,mode: :update,store_layout:true)
   check(h.layout_settings([root,front])[:side]=='Right' && h.plan([root,front],h.defaults,m)[:side]==:right,'Auto update preserves the right-hand side established by existing cups')
   front.transformation=Geom::Transformation.translation([0,0,1.mm])*front.transformation
   result=r.apply([[root,front]],m,operation:false)
   check(result[:created]==10 && h.associated([root,front],m).length==10 && r.plan([root,front],m)[:settings][:top]==101,'Refresh preserves the saved front layout after movement')
   check(h.settings[:count]==2 && h.settings[:top]==100,'Quick adjustments do not overwrite global defaults')
   view.picker.path=nil
   check(fresh.onMouseWheel(0,1,500,500,view)==false,'Wheel away from a front/panel falls through to normal zoom')
   view.picker.path=[root,front];fresh.onMouseMove(ALT_MODIFIER_MASK,500,500,view);fresh.onLButtonDown(ALT_MODIFIER_MASK,320,78,view)
   check(fresh.panel_settings[:count]==2,'Removal modifier cannot change count through panel')
   {passed:true,checks:@checks}
  rescue Exception=>e;{passed:false,checks:@checks,error:e.full_message}
  ensure
   m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
  end
 end
end
report=ElfisHingePanel2936Tests.run;File.write(File.join(__dir__,'hinge_panel_2936_native_results.json'),JSON.pretty_generate(report));puts "Hinge panel 2.9.36: #{report[:passed] ? 'PASS' : 'FAIL'} #{report[:checks].length} checks";puts report[:error] unless report[:passed]
