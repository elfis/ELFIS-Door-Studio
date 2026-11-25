require_relative '../elfis_menu'
# encoding: UTF-8
require 'json'
require 'securerandom'
require_relative 'shelf_spacing_layout'
require_relative 'shelf_spacing_v2_tool'
module Elfis
  module ShelfSpacingV2
    extend self
    DICT='ElfisShelfSpacingV2' unless const_defined?(:DICT)
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def boards(path,m)
      out=[];walk=nil
      walk=->(p,stack) do
        e=p.last;next if !e.valid? || stack.include?(e.definition)
        b=ShelfPins.board(p,m);if b;out<<b;next;end
        e.definition.entities.each { |v|walk.call(p+[v],stack+[e.definition]) if ShelfPins.instance?(v) }
      end
      walk.call(path,[]);out
    end
    def world(path,m);path.inject(m.edit_transform) { |t,e|t*e.transformation };end
    def adjustable?(board)
      ShelfPins.shelf?(board) && !board[:entity].get_attribute(CarcassJoinery::DICT,'owner_key')
    end
    def template(b,path,m)
      e=b[:entity]
      {definition:e.definition,tr:world(path,m).inverse*b[:world],tag:e.layer.name,material:e.material && e.material.name,name:e.name,bb:b[:bb],thickness:b[:points].map(&:z).max-b[:points].map(&:z).min}
    end
    def cache_key(path,m); [m.object_id,path.map(&:persistent_id)]; end
    def saved_template(path,m)
      value=(@templates||={})[cache_key(path,m)]
      value if value && value[:definition].valid?
    end
    def inspect_cabinet(path,m=Sketchup.active_model)
      raise l('Szafka lub rodzic są zablokowane.','Cabinet or parent is locked.') if path.any?(&:locked?)
      all=boards(path,m)
      return corner_spacing_info(path,m,all) if CornerCabinet.corner?(all)
      sides=all.select { |b|StudioSettings.role?(b[:entity],:sides) && !CarcassJoinery.back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }
      raise l('Wybierz pojedynczy korpus z dwoma bokami.','Choose one cabinet bay with two sides.') unless sides.length==2 && sides[0][:axes][sides[0][:thin]].dot(sides[1][:axes][sides[1][:thin]]).abs>0.999
      width=sides.first[:axes][sides.first[:thin]];frame=Geom::Transformation.axes(ORIGIN,width,Z_AXIS.cross(width).normalize,Z_AXIS);inv=frame.inverse
      side_boxes=sides.map { |b|ShelfPins.projected(b[:points],inv) }.sort_by { |bb|bb.center.x }
      left=side_boxes[0].max.x;right=side_boxes[1].min.x;low=side_boxes.map { |bb|bb.min.z }.max;high=side_boxes.map { |bb|bb.max.z }.min
      raise 'No usable cabinet interior.' unless right-left>50.mm && high-low>20.mm
      horizontal=all.select { |b|!CarcassJoinery.back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999 }.map { |b|[b,ShelfPins.projected(b[:points],inv)] }
      spanning=horizontal.select { |_,bb|(bb.min.x-left).abs<2.mm && (bb.max.x-right).abs<2.mm }
      bottom=spanning.select { |_,bb|(bb.min.z-low).abs<2.mm }.map { |_,bb|bb.max.z }.max
      top=spanning.select { |_,bb|(bb.max.z-high).abs<2.mm }.map { |_,bb|bb.min.z }.min
      low=bottom if bottom;high=top if top
      inner=spanning.select { |_,bb|bb.min.z>=low-0.01.mm && bb.max.z<=high+0.01.mm }
      raise l('Półki mają różne szerokości lub korpus ma kilka komór. Wybierz jedną komorę.','Shelves have different widths or multiple bays. Choose one compartment.') if horizontal.any? { |b,bb|adjustable?(b) && bb.min.z>=low-0.01.mm && bb.max.z<=high+0.01.mm && !inner.any? { |v,_|v==b } }
      raise l('W środku jest półka stała. Wybierz osobną komorę.','A fixed shelf divides this bay. Choose a separate compartment.') if inner.any? { |b,_|!adjustable?(b) }
      shelves=inner.select { |b,_|adjustable?(b) }.sort_by { |_,bb|bb.min.z }.map(&:first)
      raise l('Półka lub jej rodzic są zablokowane.','A shelf or parent is locked.') if shelves.any? { |b|b[:path].any?(&:locked?) }
      t=shelves.empty? ? saved_template(path,m) : template(shelves.first,path,m)
      raise l('Dodaj jedną półkę wzorcową, aby ustalić głębokość i grubość.','Add one template shelf first to establish depth and thickness.') unless t
      gaps=[];z=low
      shelves.each { |b|bb=ShelfPins.projected(b[:points],inv);gaps<<(bb.min.z-z).to_mm;z=bb.max.z }
      gaps<<(high-z).to_mm
      raise 'Shelves overlap or extend outside the cabinet interior.' if gaps.any? { |g|g< -0.01 }
      {path:path,shelves:shelves,template:t,low:low.to_mm,high:high.to_mm,gaps:gaps,frame:frame,inverse:inv,left:left,right:right}
    end
    def plan(info,count,expression=nil)
      value=Float(count);raise 'Shelf count must be a whole number from 0 to 20.' unless value.finite? && value==value.to_i
      count=value.to_i;raise 'Shelf count must be between 0 and 20.' unless (0..20).include?(count)
      ts=info[:shelves].take(count).map { |b|(b[:points].map(&:z).max-b[:points].map(&:z).min).to_mm }
      ts+=Array.new(count-ts.length,info[:template][:thickness].to_mm)
      gaps=expression ? ShelfSpacingLayout.openings(info[:high]-info[:low],ts,expression) : info[:gaps]
      raise 'Choose a gap pattern after changing the shelf count.' unless gaps.length==count+1
      {count:count,thicknesses:ts,gaps:gaps,positions:ShelfSpacingLayout.positions(info[:low],ts,gaps),expression:expression,signature:signature(info)}
    end
    def signature(info)
      [info[:path].map(&:persistent_id),info[:low].round(4),info[:high].round(4),info[:shelves].map { |b|[b[:path].map(&:persistent_id),b[:points].map { |p|p.to_a.map { |v|v.to_mm.round(4) } }] }]
    end
    def corner_spacing_info(path,m,all)
      vertical=all.select { |b|b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }
      low=vertical.map { |b|b[:points].map(&:z).min }.max
      high=vertical.map { |b|b[:points].map(&:z).max }.min
      horizontal=all.select { |b|!CarcassJoinery.back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999 }
      shelves=horizontal.select { |b|ShelfSpacingV2.adjustable?(b) }.sort_by { |b|b[:points].map(&:z).min }
      reference=shelves.first || horizontal.first
      raise 'Add one corner shelf template first.' unless reference
      shape=CornerCabinet.footprint(reference)
      # Rails can extend farther toward the opening than adjustable shelves.
      # Their outside footprint still spans the same corner bay.
      ref_xy=CornerCabinet.source_xy_bounds(reference)
      same=horizontal.select { |b|CornerCabinet.source_xy_bounds(b).zip(ref_xy).all? { |a,d|(a-d).abs<0.1 } }
      bottom=same.select { |b|(b[:points].map(&:z).min-low).to_f.abs<2.mm.to_f }.map { |b|b[:points].map(&:z).max }.max
      top=same.select { |b|(b[:points].map(&:z).max-high).to_f.abs<2.mm.to_f }.map { |b|b[:points].map(&:z).min }.min
      low=bottom if bottom;high=top if top
      inner=horizontal.select { |b|b[:points].map(&:z).min>=low-0.01.mm && b[:points].map(&:z).max<=high+0.01.mm }
      raise 'A fixed shelf divides this corner bay; select a separate compartment.' if inner.any? { |b|!ShelfSpacingV2.adjustable?(b) }
      raise 'Corner shelves have different outlines; select one compartment.' unless inner.all? { |b|CornerCabinet.footprint(b)==shape }
      shelves=inner.sort_by { |b|b[:points].map(&:z).min }
      raise 'A corner shelf or parent is locked.' if shelves.any? { |b|b[:path].any?(&:locked?) }
      template=shelves.empty? ? ShelfSpacingV2.saved_template(path,m) : ShelfSpacingV2.template(shelves.first,path,m)
      raise 'No saved corner shelf template.' unless template
      gaps=[];z=low
      shelves.each { |b|min,max=b[:points].map(&:z).minmax;gaps<<(min-z).to_mm;z=max }
      gaps<<(high-z).to_mm
      raise 'Corner shelves overlap or extend outside the cabinet.' if gaps.any? { |v|v< -0.01 }
      width=reference[:axes].find { |v|v.dot(Z_AXIS).abs<0.001 }
      frame=Geom::Transformation.axes(ORIGIN,width,Z_AXIS.cross(width).normalize,Z_AXIS);inv=frame.inverse;bb=ShelfPins.projected(reference[:points],inv)
      {path:path,shelves:shelves,template:template,low:low.to_mm,high:high.to_mm,gaps:gaps,frame:frame,inverse:inv,left:bb.min.x,right:bb.max.x,corner:true}
    end
    # Locators survive Make Unique by using entity order, without writing
    # temporary attributes into the original shared definition.
    def locator(path)
      [path.first, path.each_cons(2).map { |parent,child| parent.definition.entities.to_a.index(child) || raise('Panel path changed.') }]
    end
    def resolve(spec,unique:false)
      root,indices=spec
      raise 'Cabinet was deleted.' unless root.valid?
      result=[root]
      indices.each do |index|
        parent=result.last
        parent.make_unique if unique && parent.definition.instances.length>1
        child=parent.definition.entities.to_a[index]
        raise 'Cabinet geometry changed; select it again.' unless ShelfPins.instance?(child)
        result<<child
      end
      result.last.make_unique if unique && result.last.definition.instances.length>1
      result
    end
    def related_rows(info,m)
      scan=DrillingEditor.scan(roots:[info[:path].first],model:m)
      sources=info[:shelves].map { |b|b[:path] }
      fixed=scan[:rows].any? { |h|%i[dowel screw].include?(h[:kind]) && h[:source] && sources.include?(h[:source][:path]) }
      raise l('Półka ma kołki lub śruby i jest traktowana jako stała.','A shelf has dowel/screw drilling and is treated as fixed.') if fixed
      settings=ShelfPins.settings
      recovered={}
      # A manual shelf move can leave the complete imported grid a few mm
      # behind. Match the entire pattern, not a single nearby circle, and
      # re-anchor it to the configured below-shelf datum on Apply.
      info[:shelves].each do |shelf|
        planned=ShelfPins.plan(shelf[:path],settings,m)[:holes]
        candidates=planned.map do |expected|
          diameter=expected.fetch(:diameter,settings[:diameter])
          depth=expected.fetch(:depth,settings[:depth])
          scan[:rows].select do |h|
            next false if h[:source] && (h[:kind]!=:pin || h[:source][:path]!=shelf[:path])
            next false unless h[:panel][:path]==expected[:panel][:path] && (h[:diameter]-diameter).abs<0.01 && (h[:depth]-depth).abs<0.01
            difference=h[:point]-expected[:point]
            Math.hypot(difference.x.to_mm,difference.y.to_mm)<0.05 && h[:normal].dot(expected[:normal]).abs>0.999
          end
        end
        shifts=candidates.each_with_index.flat_map do |items,index|
          items.map { |h|(h[:point].z-planned[index][:point].z).to_mm }
        end.select { |delta|delta.abs<=settings[:pitch]/2.0+0.01 }.uniq { |delta|delta.round(3) }
        fits=shifts.filter_map do |delta|
          matches=candidates.each_with_index.map do |items,index|
            items.select { |h|((h[:point].z-planned[index][:point].z).to_mm-delta).abs<0.05 }
          end
          [delta,matches.map(&:first)] if matches.all? { |items|items.length==1 }
        end
        next if fits.empty?
        raise 'More than one complete shelf-pin pattern matches a shelf. Check its drilling geometry.' if fits.length>1
        delta,matched=fits.first
        matched.each do |h|
          previous=recovered[h[:id]]
          raise 'One drilling pattern matches more than one shelf. Check shelf spacing.' if previous && previous[:source][:path]!=shelf[:path]
          raise 'A matched shelf-pin drilling group or its parent is locked.' if h[:path].any?(&:locked?)
          recovered[h[:id]]=h.merge(source:shelf,kind: :pin,owned:false,datum_shift:delta)
        end
      end
      panels=boards(info[:path],m).map { |b|b[:path] }
      unresolved=scan[:rows].any? do |h|
        next false if recovered.key?(h[:id])
        next false if h[:source] || !panels.include?(h[:panel][:path])
        next false unless (h[:diameter]-settings[:diameter]).abs<0.01
        expected=CarcassJoinery.back?(h[:panel]) ? h[:panel][:lengths][h[:panel][:thin]].to_mm : settings[:depth]
        next false unless (h[:depth]-expected).abs<0.01
        info[:shelves].any? do |b|
          z=(b[:points].map(&:z).min-settings[:below].mm).to_mm
          (h[:point].z.to_mm-z).abs<=settings[:pitch]*[settings[:above],settings[:under]].max+0.1
        end
      end
      raise 'Some shelf-pin drilling is ambiguous or locked. Check the geometry and drilling settings before rearranging.' if unresolved
      normal=scan[:rows].select { |h|h[:kind]==:pin && h[:source] && sources.include?(h[:source][:path]) }
      normal.map { |h|recovered.delete(h[:id]) || h } + recovered.values
    end
    def curve_for(row,path,m)
      curves=path.last.definition.entities.grep(Sketchup::Edge).map(&:curve).compact.uniq
      curves.find do |curve|
        h=DrillingEditor.circle(path,m,curve:curve)
        h && h[:point].distance(row[:point]).to_mm<0.01 && (h[:diameter]-row[:diameter]).abs<0.01
      end || raise('Existing drilling changed; select the cabinet again.')
    end
    def write_hole(h,m)
      board=ShelfPins.board(h[:panel_path],m)
      raise 'Receiving panel no longer exists.' unless board
      existing=ShelfPins.circular_holes(board)
      return 0 if existing.any? { |v|v[:center].distance(h[:point]).to_mm<0.01 && (v[:diameter]-h[:diameter]).abs<0.01 && (v[:depth]-h[:depth]).abs<0.01 }
      tag=ShelfPins.tag_name(diameter:h[:diameter],depth:h[:depth])
      group=board[:entity].definition.entities.add_group
      group.name=tag
      group.layer=m.layers[h[:operation_tag]] || m.layers.add(h[:operation_tag])
      edges=group.entities.add_circle(ORIGIN,Z_AXIS,h[:diameter].mm/2,24)
      edges.each { |edge|edge.layer=m.layers[tag] || m.layers.add(tag) }
      normal=h[:normal];tangent=h[:tangent]
      group.transformation=board[:world].inverse*Geom::Transformation.axes(h[:point],tangent,normal.cross(tangent).normalize,normal)
      1
    end
    def apply(path,layout,m=Sketchup.active_model,operation:true)
      raise 'Make the open shared cabinet unique first.' if Array(m.active_path).any? { |e|e.definition.instances.length>1 }
      info=inspect_cabinet(path,m)
      raise 'Cabinet changed; reset the preview.' unless layout[:signature]==signature(info)
      count=layout.fetch(:count);current=plan(info,count,layout[:expression])
      raise 'Cabinet changed; reset the preview.' unless current[:positions].zip(layout[:positions]).all? { |a,b|b && (a-b).abs<0.01 }
      rows=related_rows(info,m)
      raise 'A drilling group or its parent is locked.' if rows.any? { |h|h[:path].any?(&:locked?) }
      # Only complete machining circles can be removed. Physical panel geometry
      # and mixed groups are preserved, including unrelated circles in a group.
      rows.each do |h|
        curve=curve_for(h,h[:path],m)
        raise 'Drilling has attached faces; review it before moving shelves.' if curve.edges.any? { |e|!e.faces.empty? }
      end
      specs=info[:shelves].map { |b|locator(b[:path]) }
      holes=rows.map { |h|[h,locator(h[:path]),locator(h[:panel][:path]),info[:shelves].index { |b|b[:path]==h[:source][:path] }] }
      cabinet=locator(path);removed=0;added=0;created=0
      m.start_operation(l('ELFIS — Półki 2.0 bez adaptacji','ELFIS — Arrange shelves 2.0 without adoption'),true) if operation
      begin
        path=resolve(cabinet,unique:true)
        old_paths=specs.map { |spec|resolve(spec,unique:true) }
        source_patterns=Array.new(specs.length) { [] }
        drilling=holes.map do |h,hole_spec,panel_spec,index|
          panel_path=resolve(panel_spec,unique:true)
          hole_path=resolve(hole_spec,unique:true)
          source_patterns[index]<<h.merge(panel_path:panel_path,operation_tag:hole_path.last.layer.name,
            source_z:info[:shelves][index][:points].map(&:z).min+h.fetch(:datum_shift,0).mm)
          [curve_for(h,hole_path,m),hole_path.last]
        end
        drilling.each do |curve,group|
          edges=curve.edges.select(&:valid?)
          group.definition.entities.erase_entities(edges) unless edges.empty?
        end
        drilling.map(&:last).uniq.each { |g|g.erase! if g.valid? && g.definition.entities.length==0 }
        t=info[:template]
        (count...old_paths.length).to_a.reverse_each { |i|old_paths[i].last.erase!;removed+=1 }
        paths=[]
        count.times do |i|
          if i<old_paths.length
            p=old_paths[i];entity=p.last
          else
            entity=path.last.definition.entities.add_instance(t[:definition],t[:tr])
            entity.layer=m.layers[t[:tag]] || m.layers.add(t[:tag])
            entity.material=m.materials[t[:material]] if t[:material]
            entity.name=t[:name].to_s
            p=path+[entity];added+=1
          end
          # Legacy ownership must not regenerate duplicate holes later.
          entity.delete_attribute(ShelfPins::DICT)
          board=ShelfPins.board(p,m)
          raise 'Shelf template is no longer a horizontal panel.' unless ShelfPins.shelf?(board)
          delta=current[:positions][i].mm-board[:points].map(&:z).min
          vector=Geom::Vector3d.new(0,0,delta).transform(world(p[0...-1],m).inverse)
          entity.transformation=Geom::Transformation.translation(vector)*entity.transformation
          paths<<p
        end
        output=[]
        paths.each_with_index do |p,i|
          pattern=source_patterns[i] || source_patterns.first || t[:pin_pattern] || []
          if !pattern.empty?
            pattern.each do |h|
              point=h[:point].offset(Z_AXIS,current[:positions][i].mm-h[:source_z])
              board=ShelfPins.board(h[:panel_path],m)
              check=h.merge(point:point,panel:board)
              CarcassJoinery.check_circle(check)
              output<<check
            end
          else
            config=ShelfPins.settings.merge(reuse:false)
            ShelfPins.plan(p,config,m)[:holes].each do |h|
              panel_path=resolve(locator(h[:panel][:path]),unique:true)
              output<<h.merge(panel_path:panel_path,diameter:config[:diameter],depth:h.fetch(:depth,config[:depth]),operation_tag:StudioSettings.operation_tag)
            end
          end
        end
        output.each { |h|created+=write_hole(h,m) }
        m.commit_operation if operation
        # Session memory retains opt-in through-back rows after count zero.
        # No cabinet attributes or adopted-drilling ownership are written.
        (@templates||={})[cache_key(path,m)]=t.merge(pin_pattern:source_patterns.first || t[:pin_pattern])
      rescue
        m.abort_operation if operation
        raise
      end
      m.active_view.invalidate
      {path:path,added:added,removed:removed,holes:created}
    end
    def activate;Sketchup.active_model.select_tool(Tool.new);end
    def install
      return if @command
      @command=UI::Command.new('ELFIS — Arrange Shelves 2.0 / Półki bez adaptacji') { activate }
      @command.tooltip=l('Półki 2.0 — bez przejmowania wierceń i bez nowych atrybutów ELFIS','Arrange Shelves 2.0 — no drilling adoption or new ELFIS attributes')
      @command.small_icon=@command.large_icon=File.join(__dir__,'shelf_spacing_v2.svg')
      ElfisMenu.category('Cabinet tools').add_item(@command)
      toolbar=BastillePodmienFront.instance_variable_get(:@toolbar)
      toolbar.add_item(@command) if toolbar
    end
  end
end

