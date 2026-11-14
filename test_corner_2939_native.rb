require 'json'
root_dir=__dir__;base=File.join(root_dir,'elfis_bastille_podmien_front')
[Elfis::CarcassJoinery,Elfis::HingeDrilling,Elfis::DrillingRefresh].each { |mod|mod.singleton_class.send(:remove_method,:apply) if mod.singleton_class.instance_methods(false).include?(:apply) }
%w[corner_cabinet.rb shelf_pins.rb carcass_joinery.rb drilling_editor.rb drilling_refresh.rb hinge_drilling.rb shelf_spacing_tool.rb shelf_spacing.rb].each { |f|load File.join(base,f) }
module ElfisCornerTests
  extend self
  def check(value,label);raise label unless value;@checks<<label;end
  def run
    @checks=[];m=Sketchup.active_model;c=Elfis::CornerCabinet;s=Elfis::ShelfPins;j=Elfis::CarcassJoinery;spacing=Elfis::ShelfSpacing;h=Elfis::HingeDrilling;r=Elfis::DrillingRefresh;d=Elfis::DrillingEditor
    context=m.active_path;selection=m.selection.to_a;opened=false
    begin
      m.active_path=nil
      actual=m.entities.find { |e|s.instance?(e) && e.name=='narozna' };raise 'The narozna reference cabinet is required.' unless actual
      signature=->(root) { nodes=[];walk=nil;walk=->(e,stack) { next if stack.include?(e.definition);nodes<<[e.persistent_id,e.definition.guid,e.transformation.to_a,e.attribute_dictionaries && e.attribute_dictionaries.map { |a|[a.name,a.to_a] }];e.definition.entities.each { |v|walk.call(v,stack+[e.definition]) if s.instance?(v) } };walk.call(root,[]);JSON.generate(nodes) }
      original=signature.call(actual)
      info=spacing.inspect_cabinet([actual],m)
      check(info[:corner] && info[:shelves].length==3 && info[:gaps].all? { |v|(v-216).abs<0.01 },'Actual L cabinet has three shelves and four clear 216 mm openings after deducting rails')
      imported=info[:shelves].map { |b|s.plan(b[:path],s.settings,m) }
      check(imported.all? { |p|p[:holes].length==15 && p[:holes].count { |v|j.back?(v[:panel]) }==3 },'Each actual shelf has 12 side supports and three through-back supports')
      imported.each do |p|
        p[:holes].each do |v|
          old=s.circular_holes(v[:panel])
          check(old.any? { |o|o[:center].distance(v[:point]).to_mm<0.01 && (o[:diameter]-v[:diameter]).abs<0.01 && (o[:depth]-v[:depth]).abs<0.01 },'Planned corner support matches an existing reference circle and depth')
        end
      end
      m.start_operation('ELFIS full corner tests (rolled back)',true);opened=true
      copy=m.entities.add_instance(actual.definition,actual.transformation);copy.make_unique
      info=spacing.inspect_cabinet([copy],m)
      linked=s.apply([info[:shelves].first[:path]],s.settings,m,operation:false)
      check(linked[:created]==15 && s.removal_groups(info[:shelves].first[:path],m).length==15,'Clicking imported corner shelf adopts its existing side and through-back vectors')
      layout=spacing.plan(info,3,'300,200,1,1')
      result=spacing.apply([copy],layout,m,operation:false)
      check(result[:holes]==45 && result[:added]==0,'Moving imported L shelves adopts and replaces all 45 old supports in one operation')
      moved=spacing.inspect_cabinet([copy],m)
      check(moved[:gaps].zip([300,200,182,182]).all? { |a,b|(a-b).abs<0.01 },'Mixed mm and ratios produce the expected clear openings in the L cabinet')
      plans=moved[:shelves].map { |b|s.plan(b[:path],s.settings.merge(reuse:false),m) }
      plans.each do |p|
        owned=s.removal_groups(p[:shelf][:path],m).map { |v|d.circle(v[:path],m) }
        check(owned.length==15 && owned.all? { |v|p[:holes].any? { |q|q[:point].distance(v[:point]).to_mm<0.01 && (q[:depth]-v[:depth]).abs<0.01 } },'Owned supports follow the moved shelf, retaining through-back depth and original rows')
      end
      all=j.panels(copy,m)
      back_pins=all.select { |v|j.back?(v) }.flat_map { |v|d.panel_holes(v,m) }.select { |v|(v[:diameter]-5).abs<0.01 && (v[:depth]-18).abs<0.01 }
      check(back_pins.length==9,'Old through-back circles do not remain at previous shelf heights')
      result=spacing.apply([copy],spacing.plan(moved,4,'1,1,1,1,1'),m,operation:false)
      check(result[:added]==1 && result[:holes]==60,'Increasing count clones the complete L shelf and its through-back support pattern')
      info=spacing.inspect_cabinet([copy],m)
      check(info[:shelves].all? { |b|c.footprint(b)==c.footprint(info[:shelves].first) },'All cloned shelves retain the rounded L outline')
      count_before=s.circular_holes(j.panels(actual,m).find { |v|j.back?(v) }).length
      check(signature.call(actual)==original,'Original corner geometry and metadata remain unchanged after editing its copy')
      # Refresh after a manual move uses ownership rather than old world points.
      shelf=info[:shelves][1];tw=shelf[:path][0...-1].inject(m.edit_transform) { |t,e|t*e.transformation }
      shelf[:entity].transformation=Geom::Transformation.translation(Geom::Vector3d.new(0,0,10.mm).transform(tw.inverse))*shelf[:entity].transformation
      rr=r.apply([shelf[:path]],m,operation:false,kind: :pin)
      check(rr[:created]==15 && rr[:removed]==15,'Refresh updates side and through-back supports together after a manual shelf move')
      # Both actual perpendicular fronts already use the supported Blum pattern.
      fronts=d.fronts(copy,m)
      check(fronts.length==2,'Two perpendicular front components are found independently')
      fronts.each do |front|
        plan=h.plan(front[:path],h.settings,m)
        plates=plan[:holes].select { |v|v[:kind]==:hinge_plate }
        check(plan[:holes].count { |v|v[:kind]==:cup }==2 && plates.length==4 && plates.map { |v|v[:panel][:entity] }.uniq.length==1,'Each corner front plans its cups and a single correct receiving side')
        applied=h.apply([front[:path]],h.settings,m,operation:false,store_layout:true)
        updated=h.apply([front[:path]],h.settings.merge(count:3),m,operation:false,mode: :update,store_layout:true)
        check(updated[:created]+updated[:existing]==15,'Corner hinge count can increase to three using the real receiving panel')
        refreshed=r.apply([front[:path]],m,operation:false,kind: :hinge)
        fresh_plan=h.plan(front[:path],h.layout_settings(front[:path]),m)
        check(fresh_plan[:holes].length==15 && fresh_plan[:holes].all? { |v|d.panel_holes(v[:panel],m).any? { |o|o[:point].distance(v[:point]).to_mm<0.02 && (o[:diameter]-v[:diameter]).abs<0.01 && (o[:depth]-v[:depth]).abs<0.01 } },'Refresh retains three complete hinge patterns on the corner front and side')
      end
      # Plan and apply source-edge spindle patterns on both L rails and backs.
      all=j.panels(copy,m);rails=all.select { |b|j.fixed?(b) };backs=all.select { |b|j.back?(b) }
      check(rails.length==2 && backs.length==2,'Corner rails and the two independent back panels are resolved')
      (rails+backs).each do |b|
        plan=j.plan(b[:path],j.settings,m)
        check(plan[:corner] && !plan[:holes].empty?,'Corner joinery plans actual receiving surfaces')
        plan[:holes].each { |v|j.check_circle(v) }
        result=j.apply([b[:path]],j.settings,m,operation:false)
        check(result[:created]+result[:existing]==plan[:holes].length,'Corner dowels and screws are written on the planned panel surfaces')
        refreshed=r.apply([b[:path]],m,operation:false,kind: :joint)
        check(refreshed[:created]>0,'Corner joinery Refresh regenerates its owned drilling')
      end
      check(signature.call(actual)==original,'All corner machining leaves the production cabinet unchanged')
      # Deleted shelves must not leave owned holes in either sides or backs.
      info=spacing.inspect_cabinet([copy],m);gone=info[:shelves].last
      owned=s.removal_groups(gone[:path],m)
      check(owned.length==15,'Deleted-shelf fixture owns both side and back support vectors')
      gone[:entity].erase!
      cleaned=r.apply([],m,operation:false,cleanup_roots:[[copy]])
      check(cleaned[:orphans]==15 && cleaned[:removed]==15,'Refresh removes orphan support circles from sides and through-back rows')
      info=spacing.inspect_cabinet([copy],m)
      zero=spacing.apply([copy],spacing.plan(info,0,'1'),m,operation:false)
      check(spacing.inspect_cabinet([copy],m)[:shelves].empty?,'Corner shelf count can reach zero while retaining its template')
      info=spacing.inspect_cabinet([copy],m)
      restored=spacing.apply([copy],spacing.plan(info,2,'1,1,1'),m,operation:false)
      check(restored[:added]==2 && restored[:holes]==30,'Restoring after zero retains the through-back drilling pattern')
      copy.transformation=Geom::Transformation.translation([10000.mm,20000.mm,0])*Geom::Transformation.rotation(ORIGIN,Z_AXIS,31.degrees)*Geom::Transformation.scaling(-1.2,1,0.9)*actual.transformation
      info=spacing.inspect_cabinet([copy],m)
      scaled=spacing.apply([copy],spacing.plan(info,3,'1,1,1,1'),m,operation:false)
      check(scaled[:holes]==45 && scaled[:added]==1,'Rotated reflected nonuniformly scaled corner arranges its L shelves')
      plans=spacing.inspect_cabinet([copy],m)[:shelves].map { |v|s.plan(v[:path],s.settings.merge(reuse:false),m) }
      check(plans.all? { |p|p[:holes].count { |v|j.back?(v[:panel]) && (v[:depth]-v[:panel][:lengths][v[:panel][:thin]].to_mm).abs<0.01 }==3 },'Through-back drilling tracks actual panel thickness after scaling')
      d.fronts(copy,m).each do |front|
        config=h.layout_settings(front[:path]);plan=h.plan(front[:path],config,m)
        refreshed=r.apply([front[:path]],m,operation:false,kind: :hinge)
        check(plan[:holes].length==15 && h.associated(front[:path],m).length>=5,'Mirroring the corner cabinet preserves each front hinge side and three-hinge Refresh')
      end
      check(signature.call(actual)==original,'All scaled and deletion fixtures preserve the original cabinet')
      report={passed:true,checks:@checks}
    rescue Exception=>e
      report={passed:false,checks:@checks,error:e.full_message}
    ensure
      m.abort_operation if opened;m.active_path=context if context && context.all?(&:valid?);m.selection.clear;m.selection.add(selection.select(&:valid?))
      File.write(File.join(__dir__,'corner_2939_native_results.json'),JSON.pretty_generate(report));puts "Corner cabinet: #{report[:passed] ? 'PASS' : 'FAIL'} #{@checks.length} checks; model restored."
      puts report[:error] unless report[:passed]
    end
  end
end
ElfisCornerTests.run
