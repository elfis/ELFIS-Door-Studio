# encoding: UTF-8
module ElfisCabinetStudio
  module Writer
    extend self
    TAG = 'ELFIS CS Drilling'.freeze
    def signature(h)
      [h[:panel][:key], h[:point].to_a.map { |v| (v / 0.001.mm).round }, h[:diameter], h[:depth]]
    end
    def existing(board)
      out = []; visit = nil
      visit = lambda do |entities, tr, label, stack|
        curves = entities.grep(Sketchup::Edge).map(&:curve).compact.uniq
        curves.grep(Sketchup::ArcCurve).each do |curve|
          next unless curve.edges.all? { |e| e.faces.empty? } && (curve.end_angle - curve.start_angle).abs >= Math::PI * 2 - 0.001
          marker = ([label] + curve.edges.map { |e| e.layer.name }).filter_map { |s| /D([\d.]+)_DEPTH([\d.]+)/i.match(s) }.first
          next unless marker
          centre = curve.center.transform(tr)
          points = curve.vertices.map { |v| v.position.transform(tr) }
          next unless points.all? { |p| (p.distance(centre).to_mm - marker[1].to_f / 2).abs < 0.02 }
          out << { point: centre, diameter: marker[1].to_f, depth: marker[2].to_f }
        end
        entities.each do |e|
          next unless Geometry.instance?(e) && !stack.include?(e.definition)
          visit.call(e.definition.entities, tr * e.transformation, e.name, stack + [e.definition])
        end
      end
      visit.call(board[:entity].definition.entities, board[:tr], board[:entity].name, [])
      out
    end
    def duplicate?(hole, old)
      old.any? { |v| v[:point].distance(hole[:point]).to_f < 0.02.mm.to_f && (v[:diameter] - hole[:diameter]).abs < 0.01 && (v[:depth] - hole[:depth]).abs < 0.01 }
    end
    def encode(path, model)
      entities = model.entities
      path.map do |e|
        index = entities.to_a.index(e)
        raise 'Zmieniła się ścieżka panelu. Wskaż panel ponownie.' unless index
        entities = e.definition.entities
        index
      end
    end
    def resolve(indices, model, unique: false)
      entities = model.entities; path = []
      indices.each do |index|
        e = entities.to_a.fetch(index)
        raise 'Nieprawidłowa ścieżka panelu.' unless Geometry.instance?(e)
        e.make_unique if unique && e.definition.instances.length > 1
        path << e; entities = e.definition.entities
      end
      path
    end
    def apply(plan, model = Sketchup.active_model, operation: true)
      if plan[:directed]
        Geometry.require_direct_panel(plan[:source][:path], model)
        plan[:reference_paths].each { |p| Geometry.require_direct_panel(p, model) }
      end
      # Editing a shared ancestor would change every occurrence. Do not close or
      # switch the user's edit context behind their back.
      if Array(model.active_path).any? { |e| e.definition.instances.length > 1 }
        raise 'Otwarty komponent ma kopie. Wyjdź z niego i użyj „Utwórz unikatowy”, albo dodaj wiercenia z zewnątrz szafki.'
      end
      source = Geometry.board(plan[:source][:path])
      raise 'Panel nie jest już dostępny. Wskaż go ponownie.' unless source
      fresh = if plan[:directed]
                references = plan[:reference_paths].map do |p|
                  Geometry.board(p) || (raise 'Panel odniesienia nie jest już dostępny. Wybierz go ponownie.')
                end
                Geometry.directed_plan(source, references, plan[:settings], mode: plan.fetch(:mode, :dowels))
              else
                all = plan[:scope_paths].filter_map { |p| Geometry.board(p) }
                Geometry.plan(source, all, plan[:settings], mode: plan.fetch(:mode, :dowels))
              end
      holes = fresh[:holes].uniq { |h| signature(h) }
      existing_by_panel = holes.map { |h| h[:panel] }.uniq { |b| b[:key] }.to_h { |b| [b[:key], existing(b)] }
      missing = holes.reject { |h| duplicate?(h, existing_by_panel.fetch(h[:panel][:key])) }
      return { created: 0, existing: holes.length, panels: 0 } if missing.empty?
      groups = missing.group_by { |h| h[:panel][:key] }.map do |_, hs|
        [encode(hs.first[:panel][:path], model), hs]
      end
      model.start_operation('ELFIS CABINET STUDIO — Kołki', true) if operation
      begin
        operation_tag = model.layers[TAG] || model.layers.add(TAG)
        groups.each do |indices, hs|
          path = resolve(indices, model, unique: true)
          panel = path.last
          inv = Geometry.transform(path).inverse
          hs.each do |h|
            marker = format('D%.1f_DEPTH%.1f', h[:diameter], h[:depth])
            depth_tag = model.layers[marker] || model.layers.add(marker)
            group = panel.definition.entities.add_group
            group.name = marker; group.layer = operation_tag
            group.entities.add_circle(ORIGIN, Z_AXIS, h[:diameter].mm / 2, 24).each { |e| e.layer = depth_tag }
            group.transformation = inv * Geom::Transformation.axes(h[:point], h[:tangent], h[:normal].cross(h[:tangent]).normalize, h[:normal])
          end
        end
        model.commit_operation if operation
      rescue Exception
        model.abort_operation if operation
        raise
      end
      model.active_view.invalidate
      { created: missing.length, existing: holes.length - missing.length, panels: groups.length }
    end
    def apply_many(plans,model=Sketchup.active_model)
      raise 'Brak przygotowanych połączeń.' if plans.empty?
      total={created:0,existing:0,panels:0};model.start_operation('ELFIS CABINET STUDIO — Połączenia',true)
      begin
        plans.each do |plan|
          result=apply(plan,model,operation:false)
          total.keys.each { |key|total[key]+=result[key] }
        end
        model.commit_operation
      rescue Exception
        model.abort_operation;raise
      end
      total
    end
  end
end
