# encoding: UTF-8
require 'json'
require 'securerandom'
require_relative 'shelf_spacing_layout'
require_relative 'shelf_spacing_tool'
module Elfis
  module ShelfSpacing
    extend self
    DICT='ElfisShelfSpacing' unless const_defined?(:DICT)
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
    def saved_template(path,m)
      raw=path.last.get_attribute(DICT,'template');return nil unless raw
      data=JSON.parse(raw,symbolize_names:true);definition=m.definitions.find { |d|d.guid==data[:guid] };return nil unless definition
      tr=Geom::Transformation.new(data[:tr]);bb=Geom::BoundingBox.new;data[:corners].each { |q|bb.add(Geom::Point3d.new(q)) }
      points=(0..7).map { |i|bb.corner(i).transform(world(path,m)*tr) }
      {definition:definition,tr:tr,tag:data[:tag],material:data[:material],name:data[:name],bb:bb,thickness:points.map(&:z).max-points.map(&:z).min,corner_pattern:data[:corner_pattern]}
    rescue JSON::ParserError,TypeError,ArgumentError;nil
    end
    def inspect_cabinet(path,m=Sketchup.active_model)
      raise l('Szafka lub rodzic są zablokowane.','Cabinet or parent is locked.') if path.any?(&:locked?)
      all=boards(path,m)
      return CornerCabinet.spacing_info(path,m,all) if CornerCabinet.corner?(all)
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
    def find_mark(path,token,index)
      result=nil;walk=nil
      walk=->(p,stack) do
        e=p.last;next if stack.include?(e.definition)
        if e.get_attribute('ElfisShelfSpacingTemp',token)==index;result=p;next;end
        e.definition.entities.each { |v|walk.call(p+[v],stack+[e.definition]) if ShelfPins.instance?(v) }
      end
      walk.call(path,[]);raise 'Shelf path changed; select the cabinet again.' unless result;result
    end
    def apply(path,layout,m=Sketchup.active_model,operation:true)
      raise l('Najpierw utwórz unikatową otwartą szafkę.','Make the open cabinet unique first.') if Array(m.active_path).any? { |e|e.definition.instances.length>1 }
      info=inspect_cabinet(path,m);count=layout.fetch(:count)
      raise l('Szafka zmieniła się. Przywróć podgląd lub wybierz ją ponownie.','Cabinet changed. Reset the preview or select it again.') unless layout[:signature]==signature(info)
      # Always read geometry again. A stale preview must never drive an edited model.
      current=plan(info,count,layout[:expression]);raise 'Cabinet changed; select it again.' unless current[:positions].zip(layout[:positions]).all? { |a,b|b && (a-b).abs<0.01 } && current[:gaps].length==layout[:gaps].length
      sources=info[:shelves].map { |b|b[:path] }
      patterns=info[:corner] ? sources.map { |p|ShelfPins.plan(p,ShelfPins.settings,m)[:corner_pattern] } : []
      # Imported, recognizable support circles need adoption before rearrangement.
      unless sources.empty?
        scan=DrillingEditor.scan(roots:[path.first],model:m)
        fixed_drilling=scan[:rows].any? { |h|%i[dowel screw].include?(h[:kind]) && h[:source] && sources.include?(h[:source][:path]) }
        raise l('Półka ma wiercenia kołków lub śrub i jest traktowana jako stała.','A shelf has dowel/screw drilling and is treated as fixed.') if fixed_drilling
        unowned=scan[:rows].any? { |h|h[:kind]==:pin && !h[:owned] && h[:source] && sources.include?(h[:source][:path]) }
        raise l('Najpierw przejmij istniejące podpórki w Ustawienia → Istniejące wiercenia.','First adopt existing shelf-pin drilling in Settings → Existing drilling.') if unowned && !info[:corner]
      end
      token=SecureRandom.uuid;removed=0;added=0;holes=0
      m.start_operation(l('ELFIS — Rozmieszczenie półek','ELFIS — Arrange shelves'),true) if operation
      begin
        info[:shelves].each_with_index { |b,i|b[:entity].set_attribute('ElfisShelfSpacingTemp',token,i) }
        path=BastillePodmienFront.unique_path(path)
        path.last.make_unique if path.last.definition.instances.length>1
        old_paths=(0...sources.length).map { |i|find_mark(path,token,i) }
        old_paths.each_with_index { |p,i|p.last.set_attribute(ShelfPins::DICT,'corner_pattern',JSON.generate(patterns[i])) } if info[:corner]
        if info[:corner] && !old_paths.empty?
          # Adopt only positively associated imported supports, atomically with
          # the move, so the old through-back circles cannot be left behind.
          fresh=DrillingEditor.scan(roots:[path.first],model:m)
          ids=fresh[:rows].select { |h|h[:kind]==:pin && !h[:owned] && h[:source] && old_paths.include?(h[:source][:path]) }.map { |h|h[:id] }
          DrillingEditor.apply(fresh,ids,{},update:false,operation:false) unless ids.empty?
        end
        ShelfPins.remove(old_paths,m,operation:false) unless old_paths.empty?
        t=info[:template];root_world=world(path,m)
        saved={guid:t[:definition].guid,tr:t[:tr].to_a,tag:t[:tag],material:t[:material],name:t[:name],corners:[t[:bb].min.to_a,t[:bb].max.to_a],corner_pattern:patterns.first || t[:corner_pattern]}
        path.last.set_attribute(DICT,'template',JSON.generate(saved))
        # Remove topmost adjustable shelves first; fixed rails never enter this set.
        (count...sources.length).to_a.reverse_each do |i|
          p=BastillePodmienFront.unique_path(find_mark(path,token,i));p.last.erase!;removed+=1
        end
        count.times do |i|
          if i<sources.length
            p=BastillePodmienFront.unique_path(find_mark(path,token,i));e=p.last
          else
            e=path.last.definition.entities.add_instance(t[:definition],t[:tr]);e.layer=m.layers[t[:tag]]||m.layers.add(t[:tag]);e.material=m.materials[t[:material]] if t[:material];e.name=t[:name].to_s
            e.delete_attribute(ShelfPins::DICT);e.set_attribute('ElfisShelfSpacingTemp',token,i);p=path+[e];added+=1
            e.set_attribute(ShelfPins::DICT,'corner_pattern',JSON.generate(saved[:corner_pattern])) if saved[:corner_pattern]
          end
          b=ShelfPins.board(p,m);raise 'Shelf template is no longer a valid panel.' unless ShelfPins.shelf?(b)
          z=b[:points].map(&:z).min;delta=current[:positions][i].mm-z
          parent_world=world(p[0...-1],m);translation=Geom::Vector3d.new(0,0,delta).transform(parent_world.inverse)
          e.transformation=Geom::Transformation.translation(translation)*e.transformation
        end
        paths=(0...count).map { |i|find_mark(path,token,i) }
        config=ShelfPins.settings.merge(reuse:false)
        paths.each { |p|ShelfPins.plan(p,config,m) }
        holes=ShelfPins.apply(paths,config,m,operation:false)[:created] unless paths.empty?
        m.definitions.each { |d|d.entities.each { |e|e.delete_attribute('ElfisShelfSpacingTemp',token) if ShelfPins.instance?(e) } }
        m.commit_operation if operation
      rescue
        m.abort_operation if operation;raise
      end
      m.active_view.invalidate;{path:path,added:added,removed:removed,holes:holes}
    end
    def activate;Sketchup.active_model.select_tool(Tool.new);end
    def install
      return if @command
      @command=UI::Command.new('ELFIS — Arrange Shelves / Rozmieszczenie półek') { activate }
      @command.tooltip=l('Rozmieść półki według prześwitów i proporcji; odśwież podpórki','Arrange shelves using clear openings and ratios; refresh shelf pins')
      @command.small_icon=File.join(__dir__,'shelf_spacing.svg');@command.large_icon=@command.small_icon
      UI.menu('Extensions').add_item(@command);toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
    end
  end
end
