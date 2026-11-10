# encoding: UTF-8
module Elfis
  module ProfileOutline
    extend self
    EPS=0.0001
    def collect(entities, transform, faces, edges)
      entities.each do |entity|
        case entity
        when Sketchup::Face
          raise Elfis::BastillePodmienFront.l('Przekrój nie może zawierać otworów.','The cross-section cannot contain holes.') unless entity.loops.length == 1
          faces << entity.outer_loop.vertices.map { |v| v.position.transform(transform) }
        when Sketchup::Edge
          edges << entity.vertices.map { |v| v.position.transform(transform) }
        when Sketchup::Group, Sketchup::ComponentInstance
          collect(entity.definition.entities, transform * entity.transformation, faces, edges)
        end
      end
    end

    def selected_outline(model)
      raise Elfis::BastillePodmienFront.l('Zaznacz płaski przekrój: powierzchnię, zamknięty obrys albo grupę z przekrojem.','Select a planar cross-section: a face, closed outline or group containing one cross-section.') if model.selection.empty?
      faces, edges = [], []
      collect(model.selection.to_a, Geom::Transformation.new, faces, edges)
      raise Elfis::BastillePodmienFront.l('Zaznacz jeden płaski przekrój, nie gotową bryłę.','Select one planar cross-section, not an extruded solid.') if faces.length > 1
      return faces.first if faces.length == 1
      raise Elfis::BastillePodmienFront.l('Zaznaczenie nie zawiera krawędzi przekroju.','The selection contains no cross-section edges.') if edges.empty?
      key = ->(p) { p.to_a.map { |x| (x / 0.001.mm).round }.join(':') }
      points, graph, unique = {}, Hash.new { |h,k| h[k] = [] }, {}
      edges.each do |a,b|
        ka, kb = key.call(a), key.call(b)
        next if ka == kb
        signature = [ka,kb].sort.join('|')
        next if unique[signature]
        unique[signature] = true
        points[ka], points[kb] = a,b
        graph[ka] << kb
        graph[kb] << ka
      end
      raise Elfis::BastillePodmienFront.l('Obrys musi być jedną zamkniętą pętlą bez rozgałęzień.','The outline must be one closed loop without branches.') unless graph.values.all? { |neighbours| neighbours.length == 2 }
      start = graph.keys.first
      current, previous, outline, visited = start, nil, [], {}
      loop do
        raise Elfis::BastillePodmienFront.l('Nieprawidłowy obrys.','Invalid outline.') if visited[current]
        visited[current] = true
        outline << points.fetch(current)
        following = graph[current].find { |k| k != previous }
        previous, current = current, following
        break if current == start
      end
      raise Elfis::BastillePodmienFront.l('Zaznaczenie zawiera więcej niż jeden obrys.','The selection contains more than one outline.') unless visited.length == graph.length
      outline
    end

    def normalize(points)
      raise Elfis::BastillePodmienFront.l('Za mało punktów przekroju.','Not enough cross-section points.') if points.length < 3
      origin = points.first
      segments = points.each_index.map { |i| points[(i+1)%points.length] - points[i] }
      axis_u = segments.max_by(&:length).normalize
      normal = nil
      segments.each do |v|
        cross = axis_u.cross(v)
        if cross.length > 0.000001
          normal = cross.normalize
          break
        end
      end
      raise Elfis::BastillePodmienFront.l('Punkty przekroju leżą na jednej linii.','The cross-section points are collinear.') unless normal
      axis_v = normal.cross(axis_u).normalize
      raise Elfis::BastillePodmienFront.l('Przekrój musi być płaski.','The cross-section must be planar.') unless points.all? { |p| (p-origin).dot(normal).abs < 0.01.mm }
      raw = points.map { |p| v=p-origin; [v.dot(axis_u).to_mm,v.dot(axis_v).to_mm] }
      min_u, max_u = raw.map(&:first).minmax
      min_v, max_v = raw.map(&:last).minmax
      width, thickness = max_u-min_u, max_v-min_v
      raise Elfis::BastillePodmienFront.l('Nie rozpoznano szerokości i grubości. Przekrój powinien mieć długą prostą krawędź.','Could not identify width and thickness. The cross-section needs a long straight edge.') unless width > thickness && thickness > EPS
      uv = raw.map { |u,v| [u-min_u,v-min_v] }
      # The decorative inner end has more vertices than the plain outer end.
      left = uv.count { |u,v| u < width*0.35 }
      right = uv.count { |u,v| u > width*0.65 }
      uv = uv.map { |u,v| [width-u,v] } if left > right
      # The shorter flat face is the front, next to the inner moulding.
      at_back = uv.select { |u,v| v.abs < EPS }.map(&:first).max
      at_front = uv.select { |u,v| (v-thickness).abs < EPS }.map(&:first).max
      uv = uv.map { |u,v| [u,thickness-v] } if at_back && at_front && at_back < at_front-EPS
      front = uv.select { |u,v| (v-thickness).abs < EPS }.map(&:first)
      shoulder = front.empty? ? width : front.max
      {points:uv,width:width,thickness:thickness,shoulder:shoulder,groove:detect_groove(uv,width)}
    end

    def detect_groove(uv,width)
      candidates = []
      uv.each_index do |i|
        a,b = uv[i],uv[(i+1)%uv.length]
        previous,following = uv[(i-1)%uv.length],uv[(i+2)%uv.length]
        next unless (a[0]-b[0]).abs < EPS && (a[1]-b[1]).abs > EPS
        next unless a[0] > width*0.4 && a[0] < width-EPS
        next unless previous[0] > a[0]+EPS && following[0] > a[0]+EPS
        candidates << {floor:a[0],low:[a[1],b[1]].min,high:[a[1],b[1]].max}
      end
      candidates.max_by { |g| g[:high]-g[:low] }
    end


  end
end
