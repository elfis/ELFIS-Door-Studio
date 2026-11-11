# Run in SketchUp's Ruby Console: load '<workspace>/test_elfis_handles.rb'
require 'json'
load File.join(__dir__,'elfis_handles','main.rb')
module ElfisHandlesNativeTest
  extend self
  def assert(value,message)
    raise message unless value
    @checks<<message
  end
  def near(a,b)
    (a-b).abs<0.00001
  end
  def run
    a=Elfis::Handles;b=a.api;m=Sketchup.active_model
    raise 'Exit the current edit context before testing.' if m.active_path
    @checks=[];saved=a.instance_variable_get(:@database);selection=m.selection.to_a
    m.start_operation('ELFIS handle regression fixtures',true)
    begin
      bar={id:'test-bar',name:'Test bar',kind:'standard',pitch:160.0,length:180.0,finish:'Black',supplier:'Test',code:'160'}
      edge=bar.merge(id:'test-edge',name:'Test edge',kind:'edge',length:200.0)
      bar2=bar.merge(id:'test-bar2',pitch:96.0,name:'Test 96')
      [bar,edge,bar2].each do |r|
        d=m.definitions.add(r[:name]);d.set_attribute(a::DICT,'library_id',r[:id])
        d.entities.add_face([[0,0,0],[r[:length].mm,0,0],[r[:length].mm,8.mm,0],[0,8.mm,0]]).pushpull(20.mm)
      end
      s=a::DEFAULTS.merge(model_id:bar[:id],preserve:false)
      a.instance_variable_set(:@database,{models:[bar,edge,bar2],settings:s.dup})
      tr=a.placement(596,715,18,bar,s)
      assert(near(tr.origin.x.to_mm,551)&&near(tr.origin.z.to_mm,670)&&near(tr.origin.y.to_mm,18),'Top screw stays 45 mm from top and side')
      tr2=a.placement(596,715,18,bar2,s)
      assert(tr.origin==tr2.origin,'Changing pitch preserves nearest screw position')
      centre=a.placement(596,140,18,bar,s.merge(position:'tc',orientation:'horizontal'))
      mid=Geom::Point3d.new(80.mm,0,0).transform(centre)
      assert(near(mid.x.to_mm,298),'Horizontal handle centres by half its pitch')
      tr=a.placement(596,715,22,bar,s,42)
      assert(near(tr.origin.x.to_mm,554),'Auto offset follows half frame width')
      arbitrary=Geom::Transformation.translation([75.mm,16.mm,42.mm])*Geom::Transformation.rotation(ORIGIN,Y_AXIS,37.degrees)
      p1=ORIGIN.transform(arbitrary);p2=Geom::Point3d.new(160.mm,0,0).transform(arbitrary)
      normal=Z_AXIS.transform(arbitrary)
      calibration=a.calibration_frame(p1.to_a,p2.to_a,p1.to_a,normal)
      calibrated=bar.merge(calibration)
      assembled=a.placement(596,715,18,calibrated,s)*a.mount_inverse(calibrated)
      screw1=p1.transform(assembled);screw2=p2.transform(assembled)
      assert(near(screw1.x.to_mm,551)&&near(screw1.y.to_mm,18)&&near(screw1.z.to_mm,670),'Calibration places an off-origin rotated model at the first screw')
      assert(near(screw2.z.to_mm,510),'Calibration points the second screw down by the measured pitch')
      assert(near(calibration[:pitch],160),'Calibration measures pitch from selected fixing points')
      a.settings.replace(s)
      tool=a::ClickTool.new;tool.instance_variable_set(:@held,{})
      fake=Struct.new(:definition).new(Struct.new(:entities).new([]))
      view=m.active_view
      press=lambda do |key|
        tool.onKeyDown(key,1,0,view)
        tool.onKeyUp(key,1,0,view)
        a.resolved_settings(fake,tool.chosen)
      end
      horizontal=press.call(COPY_MODIFIER_KEY)
      assert(horizontal[:position]=='tc'&&horizontal[:orientation]=='horizontal','Ctrl tap selects horizontal top centre and persists after release')
      bottom=press.call(CONSTRAIN_MODIFIER_KEY)
      assert(bottom[:position]=='bc'&&bottom[:orientation]=='horizontal','Shift tap selects horizontal bottom centre')
      assert(press.call(CONSTRAIN_MODIFIER_KEY)[:position]=='tc','Second Shift tap returns horizontal top centre')
      vertical=press.call(COPY_MODIFIER_KEY)
      assert(vertical[:position]=='tr'&&vertical[:orientation]=='vertical','Ctrl tap selects vertical top right')
      left=press.call(CONSTRAIN_MODIFIER_KEY)
      assert(left[:position]=='tl'&&left[:orientation]=='vertical','Shift tap selects vertical top left')
      assert(press.call(CONSTRAIN_MODIFIER_KEY)[:position]=='tr','Second Shift tap returns vertical top right')
      tool.onKeyDown(COPY_MODIFIER_KEY,1,0,view)
      tool.onKeyDown(COPY_MODIFIER_KEY,2,0,view)
      assert(tool.chosen[:orientation]=='horizontal','Holding Ctrl does not repeat the toggle')
      tool.onKeyUp(COPY_MODIFIER_KEY,1,0,view)
      assert(a.settings[:position]=='tr'&&a.settings[:orientation]=='vertical','Keyboard toggles leave library defaults unchanged')
      assert(tool.chosen[:preserve]==false,'Explicit keyboard position overrides an old front placement')
      tool.settings_changed
      assert(tool.chosen[:position]=='tr'&&tool.chosen[:orientation]=='vertical','Editing dialog settings resets the keyboard position')
      a.settings.replace(s.merge(model_id:edge[:id],position:'tc'))
      tool.onKeyDown(COPY_MODIFIER_KEY,1,0,view)
      assert(tool.chosen[:position]=='mr','Edge-pull Ctrl still selects the right edge while held')
      tool.onKeyUp(COPY_MODIFIER_KEY,1,0,view)
      assert(tool.chosen[:position]=='tc','Edge-pull Ctrl release restores the selected edge')
      tool.onKeyDown(CONSTRAIN_MODIFIER_KEY,1,0,view)
      assert(tool.chosen[:position]=='bc','Edge-pull Shift still selects bottom while held')
      tool.onKeyUp(CONSTRAIN_MODIFIER_KEY,1,0,view)
      a.settings.replace(s)
      independent=a.placement(596,715,18,bar,s.merge(offset_x:30,offset_y:60))
      assert(near(independent.origin.x.to_mm,566)&&near(independent.origin.z.to_mm,655),'Side and top offsets are independent')
      %w[tc bc ml mr].each do |pos|
        tr=a.placement(596,715,22,edge,s.merge(position:pos))
        assert(near(tr.origin.y.to_mm,0),"#{pos}: edge pull anchors to rear plane")
        assert(tr.xaxis.cross(tr.yaxis).samedirection?(tr.zaxis),"#{pos}: rigid right-handed rotation")
      end
      a.settings.replace(s)
      begin
        a.placement(100,140,18,bar,s);raise 'Guard failed'
      rescue RuntimeError=>e
        assert(e.message.include?('do not fit'),'Small-front fixing points rejected')
      end
      fd=m.definitions.add('Test plain front')
      fd.entities.add_face([[0,0,0],[596.mm,0,0],[596.mm,0,715.mm],[0,0,715.mm]]).pushpull(18.mm)
      front=m.entities.add_instance(fd,IDENTITY)
      # Ensure the slab occupies positive depth independent of face winding.
      if fd.bounds.min.y<0
        fd.entities.transform_entities(Geom::Transformation.translation([0,18.mm,0]),fd.entities.to_a)
      end
      front.material='red';front.name='Original front'
      original=b.door_bounds(front)
      handle=a.apply([front],s,Y_AXIS,operation:false)
      assert(a.children(front).length==1,'Click placement adds one handle')
      assert(front.name=='Original front'&&front.material.display_name=='red','Front name and material preserved')
      assert(near(b.door_bounds(front).depth,original.depth),'Handle excluded from original front dimensions')
      previous=JSON.parse(handle.get_attribute(a::DICT,'settings'))
      preview=a.preview_payload(front,a.measure(front,[front],Y_AXIS),bar,s)
      assert(near(preview[:placement][:a][0],551)&&near(preview[:placement][:a][1],670),'Dialog preview uses the actual fixing origin')
      assert(near(preview[:placement][:b][1],510),'Dialog preview uses the actual fixing pitch and orientation')
      a.apply([front],s.merge(model_id:bar2[:id],position:'bl',offset:20,preserve:true),Y_AXIS,operation:false)
      current=JSON.parse(a.children(front).first.get_attribute(a::DICT,'settings'))
      assert(current['position']==previous['position']&&current['offset']==previous['offset'],'Replacement keeps saved position and offsets')
      cabinet=m.definitions.add('Test cabinet');nested=cabinet.entities.add_instance(fd,IDENTITY)
      c1=m.entities.add_instance(cabinet,IDENTITY);c2=m.entities.add_instance(cabinet,Geom::Transformation.translation([800.mm,0,0]))
      a.apply([c1,nested],s,Y_AXIS,operation:false)
      assert(c1.definition!=c2.definition,'Nested placement isolates copied cabinets')
      untouched=c2.definition.entities.grep(Sketchup::ComponentInstance).first
      assert(JSON.parse(a.children(untouched).first.get_attribute(a::DICT,'record'))['id']==bar2[:id],'Other cabinet remains unchanged')
      # New generated geometry from raw 18 mm to 22 mm must re-seat handles.
      replaced=b.replace(front,m,Y_AXIS,[front],{id:'test-slab',kind:'slab',name:'Test slab',thickness:22.0},operation:false,select:false)
      mounted=a.children(replaced).first
      assert(mounted&&near(mounted.transformation.origin.y.to_mm,22),'Door style replacement re-seats handle on new front surface')
      assert(JSON.parse(mounted.get_attribute(a::DICT,'settings'))['position']=='tr','Door style replacement keeps handle settings')
      # Rotated, nonuniformly scaled and mirrored fronts must not scale handles.
      t=Geom::Transformation.rotation(ORIGIN,Z_AXIS,31.degrees)*Geom::Transformation.scaling(-1.3,1.1,0.8)
      scaled=m.entities.add_instance(fd,t)
      mounted=a.apply([scaled],s,Y_AXIS.transform(t),operation:false)
      world=scaled.transformation*mounted.transformation
      assert([world.xaxis,world.yaxis,world.zaxis].all? { |axis| near(axis.length,1) },'Handles retain physical dimensions on scaled mirrored fronts')
      # Batch two occurrences inside one shared cabinet definition.
      batchdef=m.definitions.add('Test multi cabinet')
      first=batchdef.entities.add_instance(fd,IDENTITY);second=batchdef.entities.add_instance(fd,Geom::Transformation.translation([650.mm,0,0]))
      batchroot=m.entities.add_instance(batchdef,IDENTITY)
      a.apply([batchroot,first],s,Y_AXIS,operation:false);a.apply([batchroot,second],s,Y_AXIS,operation:false)
      assert(a.order_rows.any? { |row| row[:id]=='test-bar'&&row[:quantity]>=3 },'Order list counts nested occurrences')
      m.selection.clear;m.selection.add(batchroot)
      a.settings.replace(s.merge(model_id:bar2[:id],preserve:true))
      count=a.batch('selected',operation:false)
      assert(count==2,'Batch selection finds both nested fronts')
      nested_handles=batchroot.definition.entities.grep(Sketchup::ComponentInstance).flat_map { |f| a.children(f) }
      assert(nested_handles.length==2 && nested_handles.all? { |c| JSON.parse(c.get_attribute(a::DICT,'record'))['id']==bar2[:id] },'Batch replacement changes both models without duplicate handles')
      locked=front.valid? ? front : replaced
      locked.locked=true
      begin
        a.apply([locked],s,Y_AXIS,operation:false);raise 'Guard failed'
      rescue RuntimeError=>e
        assert(e.message.downcase.include?('locked'),'Locked front rejected')
      ensure
        locked.locked=false
      end
      # Exercise persistence of model axes through the real SKP load API.
      modelpath=File.join(__dir__,'tmp','handle-import-test.skp')
      a.definition(m,bar).save_as(modelpath)
      loaded=m.definitions.load(modelpath)
      assert(loaded&&loaded.bounds.width>0,'SKP export and model loading work')
      result={passed:true,checks:@checks,sketchup:Sketchup.version}
    rescue Exception=>error
      result={passed:false,checks:@checks,error:error.full_message}
    ensure
      m.abort_operation
      m.selection.clear;m.selection.add(selection.select(&:valid?))
      a.instance_variable_set(:@database,saved)
      File.write(File.join(__dir__,'elfis_handles_test_results.json'),JSON.pretty_generate(result))
    end
    puts JSON.pretty_generate(result)
  end
end
ElfisHandlesNativeTest.run
