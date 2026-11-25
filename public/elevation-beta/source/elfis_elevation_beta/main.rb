# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require 'tmpdir'
require 'uri'
module Elfis
  module ElevationBeta
    extend self
    VERSION = '0.1.44'.freeze unless const_defined?(:VERSION)
    PART_TAG = /\A(?:body|facade|fronts?|back wall|end\s*panels?|plinths?|finishing)\z/i
    CNC = /blum operations|machining|elfis.*drill|wiercen|nawiert|kamar\s*d|\bD\d+(?:\.\d+)?[_ ]*DEPTH/i
    HARDWARE = /hardware|okucia|hinges|zawias|drawer runners/i
    APPLIANCE = /appliances|dishwasher|oven|microwave|fridge|agd|piekarnik|lod[oó]wk/i
    FRONT = /\A(?:facade|fronts?|drzwi)\z/i
    def instance?(entity)
      entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
    end
    def label(entity)
      entity.name.to_s.empty? ? entity.definition.name.to_s : entity.name.to_s
    end
    def tags(entity)
      layer = entity.layer
      names = [layer.name]
      folder = layer.respond_to?(:folder) ? layer.folder : nil
      while folder
        names << folder.name
        folder = folder.respond_to?(:folder) ? folder.folder : nil
      end
      names.join(' / ')
    end
    def visible?(entity, include_hidden)
      return true if include_hidden
      return false if entity.hidden? || !entity.layer.visible?
      folder = entity.layer.respond_to?(:folder) ? entity.layer.folder : nil
      while folder
        return false unless folder.visible?
        folder = folder.respond_to?(:folder) ? folder.folder : nil
      end
      true
    end
    def finishing?(entity)
      folder = entity.layer.respond_to?(:folder) ? entity.layer.folder : nil
      while folder
        return true if folder.name.match?(/\A(?:\d+\s+)?Finishing Parts\z/i)
        folder = folder.folder
      end
      false
    end
    def corners(bounds, transform)
      (0...8).map { |i| bounds.corner(i).transform(transform) }
    end
    def xyz(point)
      point.to_a.map { |v| (v * 25.4).round(4) }
    end
    def colour(material, fallback = '#e8e5df')
      return fallback unless material
      c = material.color
      format('#%02x%02x%02x', c.red, c.green, c.blue)
    end
    def roots_from_selection(model)
      roots = model.selection.select { |e| instance?(e) }
      raise 'Zaznacz szafki lub grupę zawierającą szafki.' if roots.empty?
      expand = lambda do |root, depth|
        children = root.definition.entities.select { |e| instance?(e) }
        parts = children.any? { |e| e.layer.name.match?(PART_TAG) }
        if depth < 4 && !root.layer.name.match?(PART_TAG) && !parts && children.length > 1 && !root.definition.entities.any? { |e| e.is_a?(Sketchup::Face) }
          children.flat_map { |c| expand.call(c, depth + 1).map { |p| [root] + p } }
        else
          [[root]]
        end
      end
      roots.flat_map { |root| expand.call(root, 0) }
    end
    def reference_panels(entities, transform, stack = [])
      entities.flat_map do |entity|
        next [] unless instance?(entity)
        next [] if tags(entity).match?(CNC) || tags(entity).match?(HARDWARE) || tags(entity).match?(APPLIANCE)
        tr = transform * entity.transformation
        if entity.layer.name.match?(/\A(?:body|back wall)\z/i)
          [corners(entity.definition.bounds, tr)]
        elsif stack.length < 12 && !stack.include?(entity.definition) && !entity.layer.name.match?(FRONT)
          reference_panels(entity.definition.entities, tr, stack + [entity.definition])
        else
          []
        end
      end
    end
    def side_panel_dimensions(entities, transform, include_hidden, stack = [])
      panels = entities.flat_map do |item|
        next [] unless instance?(item) && visible?(item, include_hidden)
        next [] if "#{tags(item)} #{label(item)}".match?(/drawer|szuflad/i)
        next [] if tags(item).match?(CNC) || tags(item).match?(HARDWARE) || tags(item).match?(APPLIANCE)
        next [] if stack.length > 16 || stack.include?(item.definition)
        tr = transform * item.transformation
        if item.layer.name.match?(/\Abody\z/i)
          pts = corners(item.definition.bounds, tr).map { |p| xyz(p) }
          lo = (0..2).map { |i| pts.map { |p| p[i] }.min }
          hi = (0..2).map { |i| pts.map { |p| p[i] }.max }
          sizes = (0..2).map { |i| hi[i] - lo[i] }
          sizes[2] > 150 && sizes[0,2].min <= 60 && sizes[0,2].max > 100 ? [{lo: lo, hi: hi}] : []
        else
          side_panel_dimensions(item.definition.entities, tr, include_hidden, stack + [item.definition])[:panels]
        end
      end
      groups = []
      panels.each do |panel|
        height = panel[:hi][2] - panel[:lo][2]
        group = groups.find do |g|
          (g[:height] - height).abs <= 1.0 &&
            (g[:from] - panel[:lo][2]).abs <= 1.0 &&
            (g[:to] - panel[:hi][2]).abs <= 1.0
        end
        group ? group[:panels] << panel : groups << {height: height, from: panel[:lo][2], to: panel[:hi][2], panels: [panel]}
      end
      paired_groups = groups.select { |g| g[:panels].length >= 2 }
      paired = paired_groups.map do |group|
        representative = group[:panels].min_by { |p| p[:lo][2] }
        {from: representative[:lo][2], to: representative[:hi][2], value: group[:height].round(4), count: group[:panels].length}
      end.uniq { |height| height[:value].round(1) }
      matched_panels = paired_groups.flat_map { |g| g[:panels] }
      total = if matched_panels.empty?
        nil
      else
        from = matched_panels.map { |p| p[:lo][2] }.min
        to = matched_panels.map { |p| p[:hi][2] }.max
        {from: from, to: to, value: (to - from).round(4)}
      end
      {panels: panels, heights: paired.sort_by { |h| h[:from] }, panel_count: matched_panels.length, total: total}
    end
    def shelf_panel_points(entities, transform, include_hidden, stack = [])
      entities.flat_map do |item|
        next [] unless visible?(item, include_hidden)
        next [] if tags(item).match?(CNC) || tags(item).match?(HARDWARE) || tags(item).match?(APPLIANCE)
        if item.is_a?(Sketchup::Face)
          item.outer_loop.vertices.map { |v| xyz(v.position.transform(transform)) }
        elsif instance?(item) && stack.length < 8 && !stack.include?(item.definition)
          next [] if "#{tags(item)} #{label(item)}".match?(CNC)
          shelf_panel_points(item.definition.entities, transform * item.transformation, include_hidden, stack + [item.definition])
        else
          []
        end
      end
    end
    def shelf_panels(entities, transform, include_hidden, stack = [])
      entities.flat_map do |item|
        next [] unless instance?(item) && visible?(item, include_hidden)
        names = "#{tags(item)} #{label(item)}"
        next [] if names.match?(CNC) || tags(item).match?(HARDWARE) || tags(item).match?(APPLIANCE) || item.layer.name.match?(FRONT) || label(item).match?(/drawer|szuflad/i)
        next [] if stack.length > 16 || stack.include?(item.definition)
        tr = transform * item.transformation
        if item.layer.name.match?(/\Abody\z/i)
          points = shelf_panel_points(item.definition.entities, tr, include_hidden, [item.definition])
          next [] if points.empty?
          inverse = tr.inverse
          local = points.map { |p| Geom::Point3d.new(p.map { |v|v.mm }).transform(inverse) }
          sizes = (0..2).map { |i| values=local.map { |p|p.to_a[i] }; values.max-values.min }
          thin = (0..2).min_by { |i| sizes[i] }
          axis = [X_AXIS,Y_AXIS,Z_AXIS][thin].transform(tr)
          next [] if axis.length < 1e-9 || axis.z.abs / axis.length < 0.999
          lo = (0..2).map { |i| points.map { |p| p[i] }.min }
          hi = (0..2).map { |i| points.map { |p| p[i] }.max }
          next [] unless hi[2]-lo[2] > 0.1 && hi[2]-lo[2] < 100 && hi[0]-lo[0] > hi[2]-lo[2] && hi[1]-lo[1] > hi[2]-lo[2]
          [{lo:lo,hi:hi,shelf:label(item).match?(/\A(?:Shelf\b|P[oó]łk)/i)}]
        else
          shelf_panels(item.definition.entities, tr, include_hidden, stack + [item.definition])
        end
      end
    end
    def shelf_clearances(entities, transform, include_hidden)
      panels = shelf_panels(entities, transform, include_hidden)
      shelves = panels.select { |p|p[:shelf] }
      overlap = lambda { |a,b,i| [[a[:hi][i],b[:hi][i]].min-[a[:lo][i],b[:lo][i]].max,0].max }
      groups = []
      shelves.each do |shelf|
        group = groups.find do |g|
          (0..1).all? { |i| overlap.call(g.first,shelf,i) / [g.first[:hi][i]-g.first[:lo][i],shelf[:hi][i]-shelf[:lo][i]].max > 0.9 }
        end
        group ? group << shelf : groups << [shelf]
      end
      groups.flat_map do |group|
        reference = group.first
        # Match shelves, full-depth tops/bottoms and narrow traverses in this bay.
        spanning = panels.select do |p|
          ratios = (0..1).map { |i| overlap.call(reference,p,i) / (reference[:hi][i]-reference[:lo][i]) }
          ratios.max > 0.65 && ratios.min > 0.08
        end.sort_by { |p|p[:lo][2] }
        unique = []
        spanning.each do |p|
          if unique.last && p[:lo][2] < unique.last[:hi][2] + 0.05
            unique.last[:hi][2] = [unique.last[:hi][2],p[:hi][2]].max
            unique.last[:shelf] ||= p[:shelf]
          else
            unique << {lo:p[:lo].dup,hi:p[:hi].dup,shelf:p[:shelf]}
          end
        end
        x = (reference[:lo][0]+reference[:hi][0])/2
        y = (reference[:lo][1]+reference[:hi][1])/2
        unique.each_cons(2).filter_map do |lower,upper|
          gap = upper[:lo][2]-lower[:hi][2]
          next unless gap > 0.1
          {from:[x,y,lower[:hi][2]],to:[x,y,upper[:lo][2]],value:gap.round(4)}
        end
      end.uniq { |g|[g[:from],g[:to]] }
    end
    def front_drillings(front)
      bounds = front.definition.bounds
      dimensions = [bounds.width.to_mm, bounds.height.to_mm, bounds.depth.to_mm]
      plane_axes = (0..2).sort_by { |i| dimensions[i] }[1, 2].sort_by { |i| dimensions[i] }
      height_axis, width_axis = plane_axes
      minimum = [bounds.min.x, bounds.min.y, bounds.min.z]
      maximum = [bounds.max.x, bounds.max.y, bounds.max.z]
      result = []
      scan = nil
      scan = lambda do |entities, transform, stack|
        entities.each do |item|
          next unless instance?(item)
          next if stack.include?(item.definition) || stack.length > 12
          item_transform = transform * item.transformation
          name = label(item)
          match = name.match(/\AD(\d+(?:\.\d+)?)_DEPTH_?(\d+(?:\.\d+)?)\z/i)
          if match
            centre = item.definition.bounds.center.transform(item_transform)
            values = [centre.x, centre.y, centre.z]
            result << {
              diameter: match[1].to_f,
              depth: match[2].to_f,
              left: ((values[width_axis] - minimum[width_axis]) * 25.4).round(3),
              right: ((maximum[width_axis] - values[width_axis]) * 25.4).round(3),
              bottom: ((values[height_axis] - minimum[height_axis]) * 25.4).round(3),
              top: ((maximum[height_axis] - values[height_axis]) * 25.4).round(3)
            }
          else
            scan.call(item.definition.entities, item_transform, stack + [item.definition])
          end
        end
      end
      scan.call(front.definition.entities, Geom::Transformation.new, [front.definition])
      drawer = label(front).match?(/drawer|szuflad/i) ||
        (result.any? { |hole| hole[:diameter] <= 3.5 } && result.none? { |hole| hole[:diameter] >= 30.0 })
      {
        width: dimensions[width_axis].round(3),
        height: dimensions[height_axis].round(3),
        kind: drawer ? 'drawer' : 'front',
        holes: result.sort_by { |hole| [hole[:bottom], hole[:left], hole[:diameter], hole[:depth]] }
      }
    end
    def facing(entity, transform, centre, camera, panels = [])
      bounds = entity.definition.bounds
      axes = [X_AXIS, Y_AXIS, Z_AXIS]
      lengths = [bounds.width, bounds.height, bounds.depth]
      index = (0..2).min_by { |i| lengths[i] }
      n = axes[index].transform(transform)
      return nil if n.length < 1.0e-9 || n.z.abs / n.length > 0.25
      n.z = 0
      n.normalize!
      # An L-shaped cabinet's centre can lie on the wrong side of its narrow
      # return front. Prefer a nearby carcass panel behind the front instead.
      front_points = corners(bounds, transform)
      u = Z_AXIS.cross(n).normalize
      range = lambda { |points,axis| points.map { |p|p.to_a.zip(axis.to_a).sum { |a,b|a*b } }.minmax }
      fn = range.call(front_points,n);fu = range.call(front_points,u);fz = front_points.map(&:z).minmax
      candidates = panels.filter_map do |points|
        pu = range.call(points,u);pz = points.map(&:z).minmax
        overlap_u = [fu[1],pu[1]].min - [fu[0],pu[0]].max
        overlap_z = [fz[1],pz[1]].min - [fz[0],pz[0]].max
        next unless overlap_u > [2.mm,(fu[1]-fu[0])*0.1].max && overlap_z > 2.mm
        pn = range.call(points,n)
        if pn[1] <= fn[0]+0.5.mm
          side=-1;gap=[fn[0]-pn[1],0].max
        elsif pn[0] >= fn[1]-0.5.mm
          side=1;gap=[pn[0]-fn[1],0].max
        else
          next
        end
        next if gap>80.mm
        {side:side,score:overlap_u*overlap_z/(gap+2.mm)}
      end
      unless candidates.empty?
        support=candidates.max_by { |candidate|candidate[:score] }
        n.reverse! if support[:side]>0
        return n.to_a.map { |v|v.round(6) }
      end
      fc = bounds.center.transform(transform)
      outward = centre.vector_to(fc)
      dot = outward.dot(n)
      n.reverse! if dot < -0.001 || (dot.abs <= 0.001 && camera.dot(n) > 0)
      n.to_a.map { |v| v.round(6) }
    end
    def snapshot(paths, model, include_hidden: false, absolute: false)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      faces = []
      roots = []
      fronts = []
      skipped = Hash.new(0)
      budget = lambda do
        raise 'Zbyt dużo geometrii do podglądu beta. Zaznacz mniejszy ciąg szafek.' if faces.length > 30_000
        raise 'Skanowanie trwa zbyt długo. Zaznacz mniej szafek.' if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started > 10
      end
      paths.each_with_index do |path, number|
        next unless path.all?(&:valid?)
        entity = path.last
        transform = path.inject(absolute ? Geom::Transformation.new : model.edit_transform) { |tr, item| tr * item.transformation }
        root_id = path.map(&:persistent_id).join('/')
        horizontal_axes = [transform.xaxis, transform.yaxis, transform.zaxis].filter_map do |axis|
          length = Math.sqrt(axis.x**2 + axis.y**2)
          length > 1e-6 ? [axis.x / length, axis.y / length] : nil
        end
        first_axis = horizontal_axes.max_by { |axis| axis[0].abs + axis[1].abs } || [1.0, 0.0]
        second_axis = horizontal_axes.reject { |axis| (axis[0] * first_axis[0] + axis[1] * first_axis[1]).abs > 0.95 }.max_by { |axis| axis[0].abs + axis[1].abs } || [-first_axis[1], first_axis[0]]
        plan_axes = [first_axis, second_axis]
        root = { id: root_id, name: label(entity), tags: tags(entity), finishing: (path.any? { |item| finishing?(item) } || finishing?(entity)), plan_axes: plan_axes, points: [], body_points: [], fronts: [], hinges: [] }
        centre = entity.definition.bounds.center.transform(transform)
        panels = reference_panels(entity.definition.entities, transform)
        side_dimensions = side_panel_dimensions(entity.definition.entities, transform, include_hidden)
        root[:unit_heights] = side_dimensions[:heights]
        root[:side_panel_count] = side_dimensions[:panel_count]
        root[:unit_total] = side_dimensions[:total]
        root[:shelf_gaps] = shelf_clearances(entity.definition.entities, transform, include_hidden)
        visit = nil
        visit = lambda do |entities, tr, inherited_material, front_id, stack, hardware = false, finishing = false|
          budget.call
          entities.each do |item|
            next unless visible?(item, include_hidden)
            if instance?(item)
              names = "#{tags(item)} #{label(item)}"
              if names.match?(CNC)
                if names.match?(/\bD35(?:[._]\d+)?_DEPTH_?[\d.]+\b/i)
                  root[:hinges] << xyz(item.definition.bounds.center.transform(tr * item.transformation))
                end
                skipped[:cnc] += 1
                next
              end
              child_hardware = hardware || tags(item).match?(HARDWARE)
              child_finishing = finishing || finishing?(item)
              child_tr = tr * item.transformation
              if child_hardware
                start_index = faces.length
                hardware_surfaces(item, child_tr, root_id, front_id, include_hidden, faces)
                faces[start_index..].each { |f| f[:finishing] = child_finishing }
                next
              end
              if tags(item).match?(APPLIANCE)
                pts = corners(item.definition.bounds, child_tr).map { |p| xyz(p) }
                # Dimensioned, neutral appliance envelopes avoid exporting hundreds of thousands of mesh faces.
                [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]].each do |indices|
                  loop_points = indices.map { |i| pts[i] }
                  faces << {root: root_id, front: nil, loops: [loop_points], edges: loop_points.each_with_index.map { |p,i| [p, loop_points[(i+1)%4]] }, colour: '#cbd0d4', proxy: true, finishing: child_finishing}
                end
                root[:points].concat(pts)
                root[:body_points].concat(pts) unless child_finishing
                skipped[:appliances] += 1
                next
              end
              next if stack.include?(item.definition) || stack.length > 24
              child_front = front_id
              if !child_hardware && !front_id && item.layer.name.match?(FRONT)
                child_front = "#{root_id}/front-#{fronts.length}"
                record = {id: child_front, root: root_id, name: label(item), points: [], normal: facing(item, child_tr, centre, model.active_view.camera.direction, panels), drilling: front_drillings(item)}
                fronts << record
                root[:fronts] << child_front
              end
              visit.call(item.definition.entities, child_tr, item.material || inherited_material, child_front, stack + [item.definition], child_hardware, child_finishing)
            elsif item.is_a?(Sketchup::Face)
              next if tags(item).match?(CNC)
              loops = item.loops.map { |loop| loop.vertices.map { |v| xyz(v.position.transform(tr)) } }
              edges = item.edges.reject { |edge| edge.hidden? || edge.soft? || edge.smooth? }.map { |edge| edge.vertices.map { |v| xyz(v.position.transform(tr)) } }
              material = item.material || item.back_material || inherited_material
              is_finishing = finishing || finishing?(item)
              faces << {root: root_id, front: front_id, loops: loops, edges: edges, colour: colour(material), hardware: hardware, finishing: is_finishing}
              points = loops.flatten(1)
              root[:points].concat(points) unless hardware
              root[:body_points].concat(points) unless hardware || is_finishing
              fronts.find { |f| f[:id] == front_id }[:points].concat(points) if front_id && !hardware
              budget.call if (faces.length % 128).zero?
            end
          end
        end
        root_front = nil
        if entity.layer.name.match?(FRONT)
          root_front = "#{root_id}/front-#{fronts.length}"
          fronts << {id: root_front, root: root_id, name: label(entity), points: [], normal: facing(entity, transform, centre, model.active_view.camera.direction, panels), drilling: front_drillings(entity)}
          root[:fronts] << root_front
        end
        visit.call(entity.definition.entities, transform, entity.material, root_front, [entity.definition], false, path.any? { |item| finishing?(item) })
        root[:points] = root[:points].uniq
        root[:body_points] = root[:body_points].uniq
        root[:hinges] = root[:hinges].uniq
        roots << root unless root[:points].empty?
      end
      raise 'Brak widocznej geometrii. Sprawdź zaznaczenie lub włącz uwzględnianie ukrytych elementów.' if roots.empty?
      normals = fronts.filter_map { |f| f[:normal] }.uniq { |n| (Math.atan2(n[1],n[0]) * 180 / Math::PI).round % 360 }
      normals.sort_by! { |n| Math.atan2(n[1],n[0]) % (2 * Math::PI) }
      # Explicitly selected items without a front have no wall-facing normal.
      # Keep them in the selected set rather than dropping them when a cabinet
      # introduces automatic wall views (end panels, fillers, open shelving).
      non_front_roots = roots.select { |r| r[:fronts].empty? }.map { |r| r[:id] }
      views = normals.each_with_index.map do |normal, i|
        ids = fronts.select { |f| f[:normal] && f[:normal].zip(normal).sum { |a,b| a*b } > 0.99 }.map { |f| f[:root] }.uniq
        ids = (ids + non_front_roots).uniq
        {id: "wall-#{i}", name: "Ściana #{(65+i).chr} · #{ids.length} elementów", normal: normal, roots: ids}
      end
      camera = model.active_view.camera.direction
      n = [-camera.x, -camera.y, 0.0]
      size = Math.sqrt(n[0]**2+n[1]**2)
      n = size < 0.0001 ? [0,-1,0] : n.map { |v| v / size }
      views << {id: 'camera', name: 'Wszystkie · kierunek kamery', normal: n, roots: roots.map { |r| r[:id] }}
      [[0,-1,0],[1,0,0],[0,1,0],[-1,0,0]].each_with_index { |normal,i| views << {id: "axis-#{i}", name: ["Wszystkie · od −Y","Wszystkie · od +X","Wszystkie · od +Y","Wszystkie · od −X"][i],normal:normal,roots:roots.map { |r|r[:id] }} }
      fronts.each { |f| f[:points] = f[:points].uniq }
      title = model.title.to_s.empty? ? 'Projekt bez nazwy' : model.title
      {version: VERSION, project: title, date: Time.now.strftime('%d.%m.%Y'), roots: roots, fronts: fronts, faces: faces, views: views, skipped: skipped, elapsed: (Process.clock_gettime(Process::CLOCK_MONOTONIC)-started).round(3), warnings: ['Beta: uproszczone AGD; bez okuć i wektorów CNC. Kolory bazowe materiałów, bez tekstur.', 'Widoczność powierzchni jest przybliżona dla przecinających się elementów. Sprawdź rysunek przed produkcją.']}
    end
    def assert_context!
      m = Sketchup.active_model
      raise 'Zmieniono model lub kontekst edycji. Zamknij podgląd i otwórz go ponownie.' unless m == @model && Array(m.active_path).map(&:persistent_id) == @context
      m
    end
    def hardware_surfaces(item, transform, root_id, front_id, include_hidden, faces, depth = 0)
      return if depth > 16 || !visible?(item, include_hidden) || tags(item).match?(CNC)
      entities = item.definition.entities
      children = entities.select { |e| instance?(e) }
      # Use individual fitting envelopes instead of dense screw/runner meshes.
      # These do not contribute to cabinet or front dimensions.
      if children.empty? || entities.any? { |e| e.is_a?(Sketchup::Face) }
        bounds = item.definition.bounds
        return if bounds.empty?
        pts = corners(bounds, transform).map { |p| xyz(p) }
        [[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]].each do |indices|
          loop_points = indices.map { |i| pts[i] }
          faces << {root: root_id, front: front_id, loops: [loop_points], edges: loop_points.each_with_index.map { |p,i| [p,loop_points[(i+1)%4]] }, colour: colour(item.material, '#aeb6bb'), hardware: true}
        end
      else
        children.each { |child| hardware_surfaces(child, transform * child.transformation, root_id, front_id, include_hidden, faces, depth + 1) }
      end
    end
    def refresh(options = {})
      m = Sketchup.active_model
      if options['selection']
        raise 'Zmieniono model. Otwórz podgląd w odpowiednim projekcie.' unless m == @model
        paths = roots_from_selection(m)
        data = snapshot(paths, m, include_hidden: options.fetch('hidden', true) == true)
        @paths = paths
        @context = Array(m.active_path).map(&:persistent_id)
        @paths_absolute = false
        @saved_view = nil
        data[:new_selection] = true
      else
        m = assert_context!
        data = snapshot(@paths, m, include_hidden: options.fetch('hidden', true) == true, absolute: @paths_absolute == true)
      end
      if @saved_view
        data[:views].unshift({id: 'saved', name: @saved_view['name'], normal: @saved_view['normal'], roots: data[:roots].map { |r| r[:id] }})
        data[:restore] = @saved_view if options['restore']
        data[:current_saved_id] = @saved_view['id']
      end
      data[:saved_views] = saved_views(m).map { |v| {id: v['id'], name: v['name']} }
      @dialog.execute_script("window.ElevationBeta.receive(#{JSON.generate(data)});") if @dialog
      data
    rescue StandardError => error
      @dialog.execute_script("window.ElevationBeta.fail(#{JSON.generate(error.message)});") if @dialog
      nil
    end
    def saved_views(model)
      value = JSON.parse(model.get_attribute('ELFIS_ElevationBeta', 'views', '[]'))
      raise 'Niepoprawne dane zapisanych widoków.' unless value.is_a?(Array)
      value
    end
    def resolve_path(model, ids)
      entities = model.entities
      ids.map do |id|
        item = entities.find { |e| instance?(e) && e.persistent_id == id.to_i }
        return nil unless item
        entities = item.definition.entities
        item
      end
    end
    def write_views(model, views)
      model.start_operation('ELFIS — zapisane widoki', true)
      begin
        model.set_attribute('ELFIS_ElevationBeta', 'views', JSON.generate(views))
        model.commit_operation
      rescue Exception
        model.abort_operation
        raise
      end
    end
    def named_action(raw)
      m = assert_context!
      request = JSON.parse(raw)
      views = saved_views(m)
      index = views.index { |v| v['id'] == request['id'] }
      if request['action'] == 'load'
        raise 'Nie znaleziono zapisanego widoku.' unless index
        record = views[index]
        resolved = record['paths'].filter_map { |ids| resolve_path(m, ids) }
        raise 'Elementy tego widoku zostały usunięte z modelu.' if resolved.empty?
        @paths = resolved
        @paths_absolute = true
        @saved_view = record
        refresh('hidden' => record.fetch('settings', {}).fetch('hidden', true), 'restore' => true)
        if resolved.length < record['paths'].length
          @dialog.execute_script("window.ElevationBeta.fail('Część zapisanych szafek już nie istnieje. Wczytano pozostałe.');") if @dialog
        end
        return
      elsif request['action'] == 'delete'
        raise 'Wybierz zapisany widok.' unless index
        views.delete_at(index)
        write_views(m, views)
        @saved_view = nil
        refresh
        return
      end
      raise 'Nieznana operacja widoku.' unless %w[new update replace].include?(request['action'])
      raise 'Wybierz zapisany widok.' if request['action'] != 'new' && !index
      name = request['action'] == 'new' ? request['name'].to_s.strip[0,90] : views[index]['name']
      raise 'Wpisz nazwę widoku, np. Ściana A.' if name.empty?
      raise 'Taka nazwa już istnieje. Użyj aktualizacji zapisanego widoku.' if request['action'] == 'new' && views.any? { |v| v['name'].casecmp?(name) }
      prefix = @paths_absolute ? [] : Array(m.active_path)
      if request['action'] == 'replace'
        paths = roots_from_selection(m).map { |p| Array(m.active_path) + p }
      else
        ids = Array(request['roots'])
        paths = @paths.select { |p| ids.include?(p.map(&:persistent_id).join('/')) }.map { |p| prefix + p }
      end
      raise 'Widok musi zawierać przynajmniej jedną szafkę.' if paths.empty?
      normal = request['normal']
      raise 'Niepoprawny kierunek widoku.' unless normal.is_a?(Array) && normal.length == 3 && normal.all? { |v| v.is_a?(Numeric) && v.finite? } && Math.hypot(normal[0],normal[1]) > 0.99
      # Scan first, so an invalid selection never replaces a working saved view.
      snapshot(paths, m, include_hidden: request.fetch('settings', {}).fetch('hidden', true), absolute: true)
      record = {'id' => index ? views[index]['id'] : "#{Time.now.to_f}-#{rand(1_000_000)}", 'name' => name, 'paths' => paths.map { |p| p.map(&:persistent_id) }, 'normal' => normal, 'settings' => request.fetch('settings', {})}
      index ? views[index] = record : views << record
      write_views(m, views)
      @paths = paths
      @paths_absolute = true
      @saved_view = record
      refresh('hidden' => record['settings'].fetch('hidden', true), 'restore' => true)
    rescue StandardError => error
      @dialog.execute_script("window.ElevationBeta.fail(#{JSON.generate(error.message)});") if @dialog
    end
    def export_svg(svg)
      assert_context!
      raise 'Niepoprawny rysunek.' unless svg.is_a?(String) && svg.bytesize < 24_000_000 && svg.start_with?('<svg') && !svg.match?(/<script|<foreignObject|\son\w+\s*=/i)
      name = @model.title.to_s.gsub(/[<>:"\/\\|?*]/, '_')
      path = UI.savepanel('Zapisz widok zabudowy SVG', nil, "#{name}_widok_zabudowy.svg")
      return unless path
      path += '.svg' unless File.extname(path).downcase == '.svg'
      File.write(path, svg, mode: 'w:UTF-8')
    rescue StandardError => error
      UI.messagebox(error.message)
    end
    def print_document(svg, paper)
      raise 'Niepoprawny rysunek.' unless svg.is_a?(String) && svg.bytesize < 24_000_000 && svg.start_with?('<svg') && !svg.match?(/<script|<foreignObject|\son\w+\s*=/i)
      size = paper == 'A3' ? 'A3' : 'A4'
      "<!doctype html><html lang='pl'><meta charset='utf-8'><title>ELFIS — Widok zabudowy</title><style>@page{size:#{size} landscape;margin:8mm}body{margin:0;font-family:Arial}svg{display:block;max-width:100%;height:auto;margin:0 auto}button{margin:15px;padding:12px}@media print{button{display:none}}</style><button onclick='window.print()'>Drukuj / Zapisz jako PDF</button>#{svg}</html>"
    end
    def print_drawing(svg, paper)
      assert_context!
      html = print_document(svg, paper)
      dir = File.join(Dir.tmpdir, 'elfis-elevation-beta')
      Dir.mkdir(dir) unless Dir.exist?(dir)
      path = File.join(dir, "widok-#{Process.pid}-#{Time.now.to_i}.html")
      File.write(path, html, mode: 'w:UTF-8')
      UI.openURL(URI::DEFAULT_PARSER.escape('file:///' + path.tr('\\','/')))
    rescue StandardError => error
      UI.messagebox(error.message)
    end
    def show(paths = nil)
      if @dialog
        @dialog.bring_to_front
        refresh('selection' => true) unless Sketchup.active_model.selection.empty?
        return
      end
      @model = Sketchup.active_model
      @context = Array(@model.active_path).map(&:persistent_id)
      @paths_absolute = false
      @saved_view = nil
      @paths = paths || (roots_from_selection(@model) rescue [])
      if @paths.empty? && (record = saved_views(@model).first)
        @paths = record['paths'].filter_map { |ids| resolve_path(@model, ids) }
        @paths_absolute = true
        @saved_view = record
      end
      raise 'Zaznacz szafki lub otwórz model z zapisanym widokiem.' if @paths.empty?
      @dialog = UI::HtmlDialog.new(dialog_title: 'ELFIS — Widok zabudowy BETA', preferences_key: 'ELFIS_Elevation_Beta_010', scrollable: true, resizable: true, width: 1250, height: 860, style: UI::HtmlDialog::STYLE_DIALOG)
      @dialog.set_file(File.join(__dir__, 'view.html'))
      @dialog.add_action_callback('elevation_ready') { |_ctx| refresh('restore' => true, 'hidden' => @saved_view ? @saved_view.fetch('settings', {}).fetch('hidden', true) : true) }
      @dialog.add_action_callback('elevation_refresh') { |_ctx, raw| refresh(JSON.parse(raw)) }
      @dialog.add_action_callback('elevation_named') { |_ctx, raw| named_action(raw) }
      @dialog.add_action_callback('elevation_export') { |_ctx, svg| export_svg(svg) }
      @dialog.add_action_callback('elevation_print') { |_ctx, svg, paper| print_drawing(svg, paper) }
      current_dialog = @dialog
      @dialog.set_on_closed do
        if @dialog.equal?(current_dialog)
          @dialog = nil
          @paths = nil
          @model = nil
        end
      end
      @dialog.show
    rescue StandardError => error
      UI.messagebox(error.message)
    end
    unless @registered
      command = UI::Command.new('Widok zabudowy — BETA') { show }
      command.tooltip = 'Zwymiarowany widok zaznaczonych szafek — beta'
      command.status_bar_text = 'Zaznacz szafki. Osobne elewacje ścian, fronty, wnętrze, SVG i druk/PDF.'
      command.small_icon = command.large_icon = File.join(__dir__, 'elevation.svg')
      if defined?(ElfisMenu)
        ElfisMenu.category('Cabinet tools').add_item(command)
      else
        menu_file = File.join(File.dirname(__dir__), 'elfis_menu.rb')
        require menu_file if File.exist?(menu_file)
        (defined?(ElfisMenu) ? ElfisMenu.category('Cabinet tools') : UI.menu('Extensions').add_submenu('ELFIS')).add_item(command)
      end
      @toolbar = UI::Toolbar.new('ELFIS — Widok zabudowy BETA')
      @toolbar.add_item(command)
      @toolbar.get_last_state == TB_NEVER_SHOWN ? @toolbar.show : @toolbar.restore
      @registered = true
    end
  end
end
