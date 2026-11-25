# encoding: UTF-8
module Elfis
  module ProfileOutline
    extend self
    EPS=0.0001
    def collect(entities, transform, faces, edges)
      entities.each do |entity|
        case entity
        when Sketchup::Face
          raise 'Przekrój nie może zawierać otworów.' unless entity.loops.length == 1
          faces << entity.outer_loop.vertices.map { |v| v.position.transform(transform) }
        when Sketchup::Edge
          edges << entity.vertices.map { |v| v.position.transform(transform) }
        when Sketchup::Group, Sketchup::ComponentInstance
          collect(entity.definition.entities, transform * entity.transformation, faces, edges)
        end
      end
    end

    def selected_outline(model)
      raise 'Zaznacz płaski przekrój: powierzchnię, zamknięty obrys albo grupę z przekrojem.' if model.selection.empty?
      faces, edges = [], []
      collect(model.selection.to_a, Geom::Transformation.new, faces, edges)
      raise 'Zaznacz jeden płaski przekrój, nie gotową bryłę.' if faces.length > 1
      return faces.first if faces.length == 1
      raise 'Zaznaczenie nie zawiera krawędzi przekroju.' if edges.empty?
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
      raise 'Obrys musi być jedną zamkniętą pętlą bez rozgałęzień.' unless graph.values.all? { |neighbours| neighbours.length == 2 }
      start = graph.keys.first
      current, previous, outline, visited = start, nil, [], {}
      loop do
        raise 'Nieprawidłowy obrys.' if visited[current]
        visited[current] = true
        outline << points.fetch(current)
        following = graph[current].find { |k| k != previous }
        previous, current = current, following
        break if current == start
      end
      raise 'Zaznaczenie zawiera więcej niż jeden obrys.' unless visited.length == graph.length
      outline
    end

    def normalize(points)
      raise 'Za mało punktów przekroju.' if points.length < 3
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
      raise 'Punkty przekroju leżą na jednej linii.' unless normal
      axis_v = normal.cross(axis_u).normalize
      raise 'Przekrój musi być płaski.' unless points.all? { |p| (p-origin).dot(normal).abs < 0.01.mm }
      raw = points.map { |p| v=p-origin; [v.dot(axis_u).to_mm,v.dot(axis_v).to_mm] }
      min_u, max_u = raw.map(&:first).minmax
      min_v, max_v = raw.map(&:last).minmax
      width, thickness = max_u-min_u, max_v-min_v
      raise 'Nie rozpoznano szerokości i grubości. Przekrój powinien mieć długą prostą krawędź.' unless width > thickness && thickness > EPS
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
