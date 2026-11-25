# encoding: UTF-8
module ElfisCabinetStudio
  module Geometry
    extend self
    AXES = [X_AXIS, Y_AXIS, Z_AXIS].freeze
    def instance?(e)
      e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
    end
    def key(path); path.map(&:persistent_id).join('/'); end
    def transform(path); path.inject(Geom::Transformation.new) { |t, e| t * e.transformation }; end
    def visible?(e); e.valid? && !e.hidden? && e.layer.visible?; end
    def require_edit_context(model = Sketchup.active_model)
      path = Array(model.active_path)
      raise 'Otwórz grupę lub komponent szafki, aby widzieć jej osobne panele.' if path.empty?
      entities = model.active_entities
      raise 'Jesteś wewnątrz panelu. Wyjdź o poziom wyżej, do wnętrza szafki.' if entities.any? { |e| e.is_a?(Sketchup::Face) }
      raise 'W tym poziomie nie ma osobnych paneli. Otwórz właściwą grupę szafki.' unless entities.any? { |e| instance?(e) }
      path
    end
    def require_direct_panel(path, model = Sketchup.active_model)
      parent = require_edit_context(model)
      raise 'Wybierz bezpośredni panel w otwartej szafce.' unless path.length == parent.length + 1 && path[0...-1] == parent && model.active_entities.include?(path.last)
      true
    end
    def board(path)
      return nil if path.empty? || !path.all? { |e| instance?(e) && visible?(e) }
      faces = path.last.definition.entities.grep(Sketchup::Face)
      return nil if faces.length < 6
      bb = Geom::BoundingBox.new
      faces.each { |face| face.vertices.each { |v| bb.add(v.position) } }
      tr = transform(path)
      vectors = AXES.map { |a| a.transform(tr) }
      return nil if vectors.any? { |a| a.length < 1e-8 }
      axes = vectors.map(&:normalize)
      return nil unless [[0, 1], [0, 2], [1, 2]].all? { |i, j| axes[i].dot(axes[j]).abs < 1e-6 }
      sizes = [bb.width, bb.height, bb.depth].each_with_index.map { |v, i| v * vectors[i].length }
      thin = (0..2).min_by { |i| sizes[i] }
      return nil unless sizes[thin].between?(2.mm, 60.mm) && sizes.all? { |s| s > 1.mm }
      # Initial release supports rectangular panels with axis-aligned outer faces.
      return nil unless faces.all? { |f| AXES.any? { |a| f.normal.dot(a).abs > 0.99999 } }
      { path: path, key: key(path), entity: path.last, faces: faces, bb: bb, tr: tr,
        origin: bb.min.transform(tr), axes: axes, sizes: sizes, thin: thin,
        points: (0..7).map { |i| bb.corner(i).transform(tr) } }
    rescue ArgumentError
      nil
    end
    def point(b, coords)
      p = b[:origin]
      coords.each_with_index { |v, i| p = p.offset(b[:axes][i], v) }
      p
    end
    def local_coords(b, p)
      vector = p - b[:origin]
      b[:axes].map { |a| vector.dot(a) }
    end
    def panels(entities, prefix = [], stack = [], budget = [0])
      entities.flat_map do |e|
        next [] unless instance?(e) && visible?(e)
        budget[0] += 1
        raise 'Za dużo elementów. Wejdź do konkretnej szafki lub zaznacz ją przed uruchomieniem.' if budget[0] > 5000
        next [] if stack.include?(e.definition)
        path = prefix + [e]; b = board(path)
        b ? [b] : panels(e.definition.entities, path, stack + [e.definition], budget)
      end
    end
    def disk_inside?(b, p, normal, tangent, diameter)
      inv = b[:tr].inverse
      q = p.transform(inv)
      faces = b[:faces].select { |f| q.distance_to_plane(f.plane).abs < 0.02.mm }
      good = [Sketchup::Face::PointInside, Sketchup::Face::PointOnEdge, Sketchup::Face::PointOnVertex]
      other = normal.cross(tangent).normalize
      radius = diameter.mm / 2.0
      samples = [p] + Array.new(24) do |i|
        angle = Math::PI * 2 * i / 24
        p.offset(tangent, radius * Math.cos(angle)).offset(other, radius * Math.sin(angle))
      end
      faces.any? { |f| samples.all? { |v| good.include?(f.classify_point(v.transform(inv))) } }
    end
    # Intersect an axis line with actual planar faces, including inner loops and
    # hanger notches. Bounding boxes establish candidates, never material.
    def line_ranges(b, origin, tangent, length)
      inv = b[:tr].inverse
      q = origin.transform(inv); direction = tangent.transform(inv)
      good = [Sketchup::Face::PointInside, Sketchup::Face::PointOnEdge, Sketchup::Face::PointOnVertex]
      faces = b[:faces].select { |f| q.distance_to_plane(f.plane).abs < 0.02.mm && f.normal.dot(direction).abs < 1e-7 }
      breaks = [0.0, length.to_f]
      faces.each do |f|
        lateral = f.normal.transform(b[:tr]).cross(tangent).normalize
        f.edges.each do |edge|
          a, z = edge.vertices.map { |v| v.position.transform(b[:tr]) }
          va = a - origin; vz = z - origin
          ya = va.dot(lateral); yz = vz.dot(lateral)
          breaks.concat([va.dot(tangent), vz.dot(tangent)])
          if (yz - ya).abs > 1e-9
            fraction = -ya / (yz - ya)
            breaks << va.dot(tangent) + fraction * (vz.dot(tangent) - va.dot(tangent)) if fraction.between?(0, 1)
          end
        end
      end
      breaks = breaks.select { |t| t >= -1e-8 && t <= length + 1e-8 }.sort.each_with_object([]) { |t, out| out << t if out.empty? || t - out.last > 0.001.mm }
      ranges = []
      breaks.each_cons(2) do |lo, hi|
        p = origin.offset(tangent, (lo + hi) / 2).transform(inv)
        next unless hi - lo > 0.001.mm && faces.any? { |f| good.include?(f.classify_point(p)) }
        if !ranges.empty? && (ranges.last[1] - lo).abs < 0.001.mm
          ranges.last[1] = hi
        else
          ranges << [lo, hi]
        end
      end
      ranges
    end
    def inside_volume?(b, world_point)
      p = world_point.transform(b[:tr].inverse)
      direction = Geom::Vector3d.new(1, 0.371, 0.173).normalize
      hits = b[:faces].filter_map do |f|
        next if f.normal.dot(direction).abs < 1e-9
        q = Geom.intersect_line_plane([p, direction], f.plane)
        t = (q - p).dot(direction)
        next unless t > 1e-7 && [Sketchup::Face::PointInside, Sketchup::Face::PointOnEdge, Sketchup::Face::PointOnVertex].include?(f.classify_point(q))
        t
      end.sort.each_with_object([]) { |t, out| out << t if out.empty? || t - out.last > 0.001.mm }
      hits.length.odd?
    end
    def bore_inside?(b, p, normal, tangent, diameter, depth)
      return false unless disk_inside?(b, p, normal, tangent, diameter)
      return true if depth <= 0
      other = normal.cross(tangent).normalize; radius = diameter.mm / 2
      # Confirm material throughout the bore, including cavities behind the entry.
      boundaries = [0.0, depth.mm.to_f]
      b[:faces].each { |f| f.vertices.each { |v| t = (v.position.transform(b[:tr]) - p).dot(normal); boundaries << t if t > 0.02.mm.to_f && t < depth.mm.to_f - 0.02.mm.to_f } }
      levels = boundaries.uniq.sort.each_cons(2).map { |a, z| (a + z) / 2 }
      levels.all? do |d|
        centre = p.offset(normal, d)
        samples = [centre] + Array.new(12) { |i| a = Math::PI * 2 * i / 12; centre.offset(tangent, radius * Math.cos(a)).offset(other, radius * Math.sin(a)) }
        samples.all? { |q| inside_volume?(b, q) }
      end
    end
    def plan(source, all, settings, mode: :dowels, reverse: true, only_panel: nil)
      c = Settings.validate(settings)
      raise 'Panel lub jego rodzic jest zablokowany.' if (!only_panel || only_panel == source[:key]) && source[:path].any?(&:locked?)
      raise 'Nieznany tryb wiercenia.' unless [:dowels, :screws].include?(mode)
      contacts = []; skipped = 0
      (0..2).reject { |i| i == source[:thin] }.each do |axis|
        tangent_axis = ([0, 1, 2] - [axis, source[:thin]]).first
        [-1, 1].each do |sign|
          edge = sign == 1 ? source[:sizes][axis] : 0.0
          candidates = all.filter_map do |target|
            next if target[:key] == source[:key]
            next unless source[:axes][axis].dot(target[:axes][target[:thin]]).abs > 0.99999
            projected = target[:points].map { |p| local_coords(source, p) }
            lo = (0..2).map { |i| projected.map { |p| p[i] }.min }
            hi = (0..2).map { |i| projected.map { |p| p[i] }.max }
            inner = sign == 1 ? lo[axis] : hi[axis]
            next unless (inner - edge).abs <= c[:tolerance].mm + 1e-8 && sign * ((lo[axis] + hi[axis]) / 2 - edge) > 0
            thin = source[:thin]
            next unless lo[thin] <= 0.02.mm && hi[thin] >= source[:sizes][thin] - 0.02.mm
            source_normal = sign == 1 ? source[:axes][axis].reverse : source[:axes][axis].clone
            target_normal = sign == 1 ? source[:axes][axis].clone : source[:axes][axis].reverse
            tangent = source[:axes][tangent_axis]
            base = [0.0, 0.0, 0.0]; base[thin] = source[:sizes][thin] / 2; base[axis] = edge
            edge_origin = point(source, base); base[axis] = inner; face_origin = point(source, base)
            positions = if mode == :screws
                          sr = line_ranges(source, edge_origin, tangent, source[:sizes][tangent_axis])
                          tr = line_ranges(target, face_origin, tangent, source[:sizes][tangent_axis])
                          sr.product(tr).flat_map do |a, b|
                            low = [a[0], b[0]].max; high = [a[1], b[1]].min
                            high > low ? Settings.screws(low.to_mm, high.to_mm, c).map { |v| { position: v, type: :screw } } : []
                          end
                        else
                          Settings.row(source[:sizes][tangent_axis].to_mm, c)
                        end
            next if positions.empty?
            raise 'Sąsiedni panel lub jego rodzic jest zablokowany.' if (!only_panel || only_panel == target[:key]) && target[:path].any?(&:locked?)
            holes = positions.flat_map do |spec|
              v = spec[:position]; dowel = spec[:type] == :dowel
              diameter = dowel ? c[:diameter] : c[:screw_diameter]
              depth = dowel ? c[:target_depth] : c[:screw_depth]
              source_depth = dowel ? c[:source_depth] : c[:screw_depth]
              write_source = only_panel ? only_panel == source[:key] : dowel
              write_target = !only_panel || only_panel == target[:key]
              raise 'Głębokość otworu przekracza grubość wierconego panelu.' if write_target && depth.mm > target[:sizes][target[:thin]] + 1e-8
              raise 'Głębokość otworu przekracza długość wierconego panelu.' if write_source && source_depth.mm > source[:sizes][axis] + 1e-8
              coords = [0.0, 0.0, 0.0]; coords[thin] = source[:sizes][thin] / 2; coords[tangent_axis] = v.mm; coords[axis] = edge
              p_source = point(source, coords); coords[axis] = inner; p_target = point(source, coords)
              unless bore_inside?(source, p_source, source_normal, tangent, diameter, write_source ? source_depth : 0) && bore_inside?(target, p_target, target_normal, tangent, diameter, write_target ? depth : 0)
                skipped += 1; next []
              end
              entries = write_target ? [[target, p_target, target_normal, depth, :face]] : []
              entries.unshift([source, p_source, source_normal, source_depth, :edge]) if write_source
              entries.map do |b, p, n, d, kind|
                { panel: b, point: p, normal: n, tangent: tangent, diameter: diameter, depth: d, kind: kind, type: spec[:type] }
              end
            end
            next if holes.empty?
            { target: target, axis: axis, sign: sign, holes: holes }
          end
          # Partial side contacts can be disjoint, but no drilling may have two receivers.
          candidates.combination(2) do |a, b|
            pa = a[:holes].map { |h| h[:point] }
            pb = b[:holes].map { |h| h[:point] }
            raise 'Niejednoznaczne połączenie: dwa panele w tej samej pozycji.' if pa.any? { |p| pb.any? { |q| p.distance(q) < 0.05.mm } }
          end
          contacts.concat(candidates)
        end
      end
      if mode == :screws && reverse
        # Also support a face of the selected panel against an edge of another
        # panel, e.g. a back against a top/bottom rail. Drill from its outer face.
        all.each do |target|
          next if target[:key] == source[:key]
          begin
            swapped = plan(target, [target, source], c, mode: :screws, reverse: false)
          rescue RuntimeError => e
            raise unless e.message.start_with?('Brak styku')
            next
          end
          holes = swapped[:holes].filter_map do |h|
            next unless h[:panel][:key] == source[:key]
            outer = h[:point].offset(h[:normal], source[:sizes][source[:thin]])
            inward = h[:normal].reverse
            next unless bore_inside?(source, outer, inward, h[:tangent], h[:diameter], h[:depth])
            h.merge(point: outer, normal: inward)
          end
          contacts << { target: target, holes: holes, face_to_edge: true } unless holes.empty?
        end
      end
      contacts.combination(2) do |a, b|
        next if a[:target][:key] == b[:target][:key]
        overlap = a[:holes].any? do |h|
          b[:holes].any? { |j| h[:panel][:key] == j[:panel][:key] && h[:point].distance(j[:point]).to_f < 0.02.mm.to_f }
        end
        raise 'Niejednoznaczne połączenie: kilka paneli pod tym samym otworem.' if overlap
      end
      raise 'Brak styku krawędzi z powierzchnią sąsiedniego panelu.' if contacts.empty?
      { source: source, contacts: contacts, holes: contacts.flat_map { |j| j[:holes] }, settings: c, mode: mode, skipped: skipped, scope_paths: all.map { |b| b[:path] } }
    end
    # Explicit two-stage selection. No other cabinet parts are searched or
    # modified. References supply positions; only destination receives circles.
    def directed_plan(destination, references, settings, mode: :dowels)
      raise 'Wybierz panel do wiercenia.' unless destination
      raise 'Wybierz przynajmniej jeden panel odniesienia.' if references.empty?
      refs = references.uniq { |b| b[:key] }
      raise 'Panel odniesienia musi być innym elementem.' if refs.any? { |b| b[:key] == destination[:key] }
      plans = refs.map do |ref|
        begin
          plan(ref, [ref, destination], settings, mode: mode, reverse: false, only_panel: destination[:key])
        rescue RuntimeError => e
          raise unless e.message.start_with?('Brak styku')
          begin
            plan(destination, [destination, ref], settings, mode: mode, reverse: false, only_panel: destination[:key])
          rescue RuntimeError => other
            raise unless other.message.start_with?('Brak styku')
            name = ref[:entity].name.empty? ? ref[:entity].definition.name : ref[:entity].name
            raise "Panel odniesienia „#{name}” nie ma pasującego styku lub nie mieści ustawionych wierceń."
          end
        end
      end
      { source: destination, destination: destination, reference_paths: refs.map { |b| b[:path] },
        contacts: plans.flat_map { |p| p[:contacts] }, holes: plans.flat_map { |p| p[:holes] },
        settings: Settings.validate(settings), mode: mode, directed: true,
        skipped: plans.sum { |p| p[:skipped] } }
    end
  end
end
