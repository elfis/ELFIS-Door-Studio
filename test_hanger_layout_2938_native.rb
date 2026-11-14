require 'json'
Elfis::DrillingRefresh.singleton_class.send(:remove_method,:apply) if Elfis::DrillingRefresh.singleton_class.instance_methods(false).include?(:apply)
load File.join(__dir__,'elfis_bastille_podmien_front/hanger_cutouts.rb')
load File.join(__dir__,'elfis_bastille_podmien_front/drilling_refresh.rb')
load File.join(__dir__,'test_hanger_removal_2925_native.rb')
module ElfisHangerLayoutTests
  extend self
  def check(value,label);raise label unless value;@checks<<label;end
  def run
    @checks=[];m=Sketchup.active_model;h=Elfis::HangerCutouts;j=Elfis::CarcassJoinery;s=Elfis::StudioSettings
    selection=m.selection.to_a;context=m.active_path;old=JSON.parse(JSON.generate(s.data),symbolize_names:true);opened=false
    begin
      m.active_path=nil;s.save(s.defaults)
      actual=m.entities.find { |e|h.instance?(e) && e.name=='narozna' }
      if actual
        backs=j.panels(actual,m).select { |b|j.back?(b) }
        original_layouts=backs.map { |b|[b[:entity].persistent_id,b[:entity].get_attribute(h::DICT,'sides')] }.sort
        layouts=backs.map { |b|h.layout_settings(b[:path],h.preset,m) }
        check(layouts.map { |c|h.selected_sides(c).length }.sort==[1,2],'Actual corner cabinet: existing one/two notch arrangement recognized read-only')
        backs.each_with_index do |b,i|
          p=h.plan(b[:path],layouts[i],m)
          check(p[:corners].all? { |v|!v[:cut] && v[:existing] },'Actual corner back routing contours and notches recognized')
        end
      end
      m.start_operation('ELFIS asymmetric hanger tests (rolled back)',true);opened=true
      body=m.layers['Body']||m.layers.add('Body');rear=m.layers['Back Wall']||m.layers.add('Back Wall')
      root=m.entities.add_group;root.transformation=Geom::Transformation.translation([20000.mm,0,0])
      box=ElfisHangerRemovalTests.method(:box)
      # Two perpendicular backs, supported by horizontal boards; no pair of parallel sides.
      a=box.call(root.entities,'Back A',[18,0,0,582,18,954],rear)
      b=box.call(root.entities,'Back B',[600,0,0,18,600,954],rear)
      box.call(root.entities,'Cabinet base',[18,18,0,582,582,18],body)
      box.call(root.entities,'Cabinet top',[18,18,936,582,582,18],body)
      paths=[[root,a],[root,b]]
      h.apply([paths[0]],h.preset.merge(sides: :both),m,operation:false)
      r=h.apply([paths[1]],h.preset.merge(sides: :left),m,operation:false)
      check(r[:cuts]==1 && r[:created]==1,'Perpendicular back receives a single selected through-notch')
      check(h.selected_sides(h.layout_settings(paths[1]))==[:left],'Single selected corner stored on its own back')
      check(h.plan(paths[1])[:corners].count { |v|!v[:cut] }==1,'Other corner stays solid')
      check(h.selected_sides(h.layout_settings(paths[0])).length==2,'Other back retains both corners')
      r=Elfis::DrillingRefresh.apply(paths,m,operation:false,kind: :kamar)
      check(r[:created]==0 && h.plan(paths[1])[:corners].count { |v|!v[:cut] }==1,'Refresh preserves two-plus-one without creating missing corner')
      paths.each do |path|
        path.last.delete_attribute(h::DICT)
        h.plan(path)[:corners].each { |v|v[:existing].delete_attribute(h::DICT) if v[:existing] }
      end
      check(Elfis::DrillingRefresh.kinds(paths[1],m).include?(:kamar),'Attribute-free legacy single notch recognized by Refresh')
      Elfis::DrillingRefresh.apply(paths,m,operation:false,kind: :kamar)
      check(h.selected_sides(h.layout_settings(paths[1]))==[:left],'Legacy adoption saves existing single-corner layout')
      h.remove([paths[0]],h.preset.merge(sides: :right),m,operation:false)
      check(h.selected_sides(h.layout_settings(paths[0]))==[:left],'Removing right corner preserves left corner and its metadata')
      paths[1].last.delete_attribute(h::DICT)
      r=h.remove([paths[1]],h.preset.merge(sides: :left),m,operation:false)
      check(r[:filled]==1 && r[:removed]==1 && !h.existing_layout?(paths[1]),'Legacy single notch removed and closed without requiring attributes')
      root.transformation=Geom::Transformation.translation([20000.mm,0,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,28.degrees)*Geom::Transformation.scaling(-1.2,1,0.8)
      r=h.apply([paths[1]],h.preset.merge(sides: :right),m,operation:false)
      check(r[:cuts]==1 && r[:created]==1,'Rotated mirrored scaled corner accepts selected side')
      p=h.plan(paths[1],h.layout_settings(paths[1]))
      check(p[:corners].length==1 && !p[:corners].first[:cut],'Scaled corner refresh layout remains single')
      # Destructive live-cabinet testing is confined to a deep-isolated copy.
      if actual
        copy=m.entities.add_instance(actual.definition,Geom::Transformation.translation([30000.mm,0,0])*actual.transformation)
        copy.make_unique
        copied=j.panels(copy,m).select { |v|j.back?(v) }.map { |v|v[:path] }
        before=copied.map { |path|h.selected_sides(h.layout_settings(path)).length }.sort
        rr=Elfis::DrillingRefresh.apply(copied,m,operation:false,kind: :kamar)
        check(rr[:created]==0 && copied.map { |path|h.selected_sides(h.layout_settings(path)).length }.sort==before,'Actual cabinet disposable copy: Refresh preserves original three cutouts')
        check(j.panels(actual,m).select { |v|j.back?(v) }.map { |v|[v[:entity].persistent_id,v[:entity].get_attribute(h::DICT,'sides')] }.sort==original_layouts,'Production corner cabinet metadata untouched by copy Refresh')
      end
      tool=h::Tool.new;view=m.active_view
      tool.onKeyDown(COPY_MODIFIER_KEY,1,0,view)
      check(tool.instance_variable_get(:@sides)==:left,'Ctrl cycles both to left')
      tool.onKeyDown(COPY_MODIFIER_KEY,2,0,view)
      check(tool.instance_variable_get(:@sides)==:left,'Held Ctrl repeat does not skip positions')
      tool.onKeyDown(COPY_MODIFIER_KEY,1,0,view)
      check(tool.instance_variable_get(:@sides)==:right,'Next Ctrl selects right')
      tool.onLButtonDown(0,280,80,view)
      check(tool.instance_variable_get(:@sides)==:both,'Viewport Both button updates selection without editing geometry')
      tool.draw(view)
      check(true,'Viewport panel draws without errors')
      report={passed:true,checks:@checks}
    rescue Exception=>e
      report={passed:false,checks:@checks,error:e.full_message}
    ensure
      m.abort_operation if opened;s.save(old);m.active_path=context if context && context.all?(&:valid?)
      m.selection.clear;m.selection.add(selection.select(&:valid?))
      File.write(File.join(__dir__,'hanger_layout_2938_native_results.json'),JSON.pretty_generate(report))
      puts "Hanger layouts: #{report[:passed] ? 'PASS' : 'FAIL'} #{@checks.length} checks; model restored."
      puts report[:error] unless report[:passed]
    end
  end
end
ElfisHangerLayoutTests.run
