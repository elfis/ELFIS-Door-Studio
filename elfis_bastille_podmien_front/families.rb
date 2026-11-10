# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    def supplier_name(value,fallback='ELFIS')
      value=value.to_s.strip[0,80]
      value.empty? ? fallback : value
    end

    def supplier_options
      (%w[ELFIS Facade]+['OS Doors','BA','Tade Moldings']+library[:profiles].map { |p| supplier_name(p[:supplier]) }).uniq
    end

    def validate_family(p)
      p[:supplier]=supplier_name(p[:supplier])
      return p unless p[:drawer_variant]
      raise Elfis::BastillePodmienFront.l('Wariant szuflady wymaga profilu Five-Piece lub One-Piece.','A drawer variant requires a Five-Piece or One-Piece profile.') unless %w[shaker onepiece].include?(p[:kind])
      v=p[:drawer_variant].dup
      %i[min_height max_height min_width thickness edge_depth frame_min frame_max frame_width].each do |key|
        v[key]=Float(v.fetch(key))
        raise Elfis::BastillePodmienFront.l('Wymiary wariantu muszą być dodatnie i skończone.','Variant dimensions must be positive and finite.') unless v[key].finite? && v[key]>0
      end
      raise Elfis::BastillePodmienFront.l('Nieprawidłowy zakres wysokości szuflady lub ramy.','Invalid drawer or frame height range.') unless v[:min_height]<=v[:max_height] && v[:frame_min]<=v[:frame_max] && v[:max_height]<v[:frame_min]
      raise Elfis::BastillePodmienFront.l('Grubość wariantu musi wynosić od 0.1 do 80 mm.','Variant thickness must be greater than 0.1 mm and at most 80 mm.') unless v[:thickness]>0.1 && v[:thickness]<=80
      raise Elfis::BastillePodmienFront.l('Wybierz płaski front lub własny przekrój szuflady.','Choose a plain slab or a custom drawer cross-section.') unless %w[slab section].include?(v[:mode])
      if v[:mode]=='section'
        points=Array(v[:section]).map { |pt| Array(pt).map { |n| Float(n) } }
        raise Elfis::BastillePodmienFront.l('Wczytaj pełny przekrój szuflady.','Load a complete drawer cross-section.') unless (4..2048).include?(points.length) && points.all? { |pt| pt.length==2 && pt.all?(&:finite?) }
        v[:reference_height]=Float(v.fetch(:reference_height))
        raise Elfis::BastillePodmienFront.l('Przekrój musi mieć prosty środek między frezami obu krawędzi.','The cross-section must have a plain middle between the moulded edges.') unless v[:reference_height]>2*v[:edge_depth] && points.none? { |u,y| u>v[:edge_depth]+0.01 && u<v[:reference_height]-v[:edge_depth]-0.01 }
        raise Elfis::BastillePodmienFront.l('Punkty przekroju wykraczają poza wysokość lub grubość.','Cross-section points exceed the height or thickness.') unless points.all? { |u,y| u>=-EPS && u<=v[:reference_height]+EPS && y>=-EPS && y<=v[:thickness]+EPS }
        v[:section]=points
      end
      p.merge(drawer_variant:v)
    end

    def resolve_family_profile(p,width,height,mode=nil)
      return p if p[:family_resolved] || !p[:drawer_variant]
      p=validate_family(p.dup)
      v=p[:drawer_variant]
      mode ||= library[:variant_mode] || 'auto'
      raise Elfis::BastillePodmienFront.l('Wybierz wariant: automatyczny, ramkowy lub szuflada.','Choose a variant: automatic, framed or drawer.') unless %w[auto frame drawer].include?(mode)
      drawer=mode=='drawer' || (mode=='auto' && height>=v[:min_height]-0.001 && height<=v[:max_height]+0.001)
      min_h,max_h,min_w=drawer ? v.values_at(:min_height,:max_height,:min_width) : v.values_at(:frame_min,:frame_max,:frame_width)
      # OS Doors specifies a wider minimum for the Bastille pan drawer.
      min_w=[min_w,246.0].max if !drawer && p[:catalogue_rules]=='osdoors-bastille-2025' && height<=355.001
      raise Elfis::BastillePodmienFront.l("#{p[:name]}: #{drawer ? 'szuflada' : 'rama'} wymaga wysokości #{min_h}–#{max_h} mm i szerokości min. #{min_w} mm (otrzymano #{height.round(2)} × #{width.round(2)}).","#{p[:name]}: #{drawer ? 'drawer' : 'frame'} requires height #{min_h}–#{max_h} mm and minimum width #{min_w} mm (received #{height.round(2)} × #{width.round(2)}).") unless height>=min_h-0.001 && height<=max_h+0.001 && width>=min_w-0.001
      result=p.reject { |key,_| key==:drawer_variant }.merge(family_resolved:true,family_name:p[:name],variant:drawer ? 'drawer' : 'frame')
      if drawer
        result=result.merge(name:"#{p[:name]} — Drawer",kind:v[:mode]=='section' ? 'drawer_section' : 'slab',thickness:v[:thickness],drawer_section:v)
      end
      result
    end

    def import_drawer_section(data)
      original=data[:id]==@draft_profile&.dig(:id) ? @draft_profile : library[:profiles].find { |p| p[:id]==data[:id] }
      raise Elfis::BastillePodmienFront.l('Wybierz rodzinę Five-Piece lub One-Piece.','Choose a Five-Piece or One-Piece family.') unless original && %w[shaker onepiece].include?(original[:kind])
      raw=ProfileOutline.normalize(ProfileOutline.selected_outline(Sketchup.active_model))
      config=(data[:drawer_variant] || original[:drawer_variant] || {}).merge(mode:'section',section:raw[:points],reference_height:raw[:width],thickness:raw[:thickness])
      candidate=original.merge(drawer_variant:config,supplier:data[:supplier] || original[:supplier])
      %i[name shoulder panel clearance].each { |key| candidate[key]=data[key] if data.key?(key) }
      candidate=validate_family(candidate)
      @draft_profile=candidate.merge(draft:true)
    end

    def build_drawer_section(model,p,width,height)
      v=p[:drawer_section];span=v[:reference_height];depth=v[:edge_depth]
      raise Elfis::BastillePodmienFront.l('Szuflada jest za niska dla obu frezowanych krawędzi.','The drawer is too small for both moulded edges.') unless height>2*depth && width>p[:thickness]
      points=v[:section].map do |u,y|
        u+=height-span if u>span/2.0
        y=p[:thickness]-y if v[:flip_front]
        u=height-u if v[:flip_end]
        [0,y.mm*SCALE,u.mm*SCALE]
      end
      d=model.definitions.add('ELFIS Drawer')
      body=d.entities.add_group;body.name='Profil szuflady'
      face=body.entities.add_face(points)
      raise Elfis::BastillePodmienFront.l('Przekrój szuflady nie tworzy powierzchni.','The drawer cross-section does not form a face.') unless face
      face.reverse! if face.normal.dot(X_AXIS)<0
      face.pushpull(width.mm*SCALE)
      orient(body)
      raise Elfis::BastillePodmienFront.l('Przekrój szuflady nie utworzył bryły.','The drawer cross-section did not create a solid.') unless solid?(body)
      body.transform!(Geom::Transformation.scaling(1.0/SCALE))
      actual=[d.bounds.width,d.bounds.height,d.bounds.depth].map(&:to_mm)
      raise Elfis::BastillePodmienFront.l('Nieprawidłowe wymiary szuflady.','Invalid drawer dimensions.') unless actual.zip([width,p[:thickness],height]).all? { |a,b| (a-b).abs<0.001 }
      d
    end
  end
end
