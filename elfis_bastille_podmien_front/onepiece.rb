# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    def validate_onepiece(p)
      points=Array(p[:points]).map do |pt|
        raise Elfis::BastillePodmienFront.l('Nieprawidłowy punkt przekroju One-Piece.','Invalid One-Piece cross-section point.') unless pt.is_a?(Array) && pt.length==2
        pt.map { |n| Float(n) }
      end
      raise Elfis::BastillePodmienFront.l('Przekrój One-Piece musi mieć od 4 do 2048 punktów.','A One-Piece cross-section must have 4 to 2048 points.') unless (4..2048).include?(points.length)
      raise Elfis::BastillePodmienFront.l('Współrzędne przekroju muszą być skończone.','Cross-section coordinates must be finite.') unless points.flatten.all?(&:finite?)
      # Remove redundant collinear vertices, including the cut across the centre.
      loop do
        i=points.each_index.find do |j|
          a,b,c=points[(j-1)%points.length],points[j],points[(j+1)%points.length]
          cross=(b[0]-a[0])*(c[1]-b[1])-(b[1]-a[1])*(c[0]-b[0])
          cross.abs<1e-9 && (b[0]-a[0])*(c[0]-b[0])+(b[1]-a[1])*(c[1]-b[1])>=0
        end
        break unless i && points.length>3
        points.delete_at(i)
      end
      a,t=Float(p.fetch(:width)),Float(p.fetch(:thickness))
      raise Elfis::BastillePodmienFront.l('Nieprawidłowe wymiary przekroju One-Piece.','Invalid One-Piece cross-section dimensions.') unless a.finite? && t.finite? && a>t && t>0.1 && t<=80
      raise Elfis::BastillePodmienFront.l('Przekrój nie mieści się w podanych wymiarach.','The cross-section does not fit the specified dimensions.') unless points.all? { |u,v| u>=-EPS && u<=a+EPS && v>=-EPS && v<=t+EPS }
      inner=points.each_index.select { |i| points[i][0]>a-EPS && points[(i+1)%points.length][0]>a-EPS }
      raise Elfis::BastillePodmienFront.l('One-Piece: wewnętrzny koniec profilu musi być jedną pionową krawędzią od tyłu do powierzchni środka; bez rowka na osobną płycinę.','One-Piece: the inner end must be one vertical edge from the back to the centre surface, without a separate-panel groove.') unless inner.length==1
      levels=[points[inner.first][1],points[(inner.first+1)%points.length][1]].sort
      raise Elfis::BastillePodmienFront.l('One-Piece: wewnętrzna krawędź musi zaczynać się na płaskim tyle (0 mm), a środek musi mieć dodatnią grubość.','One-Piece: the inner edge must start on the flat back (0 mm), and centre thickness must be positive.') unless levels.first.abs<EPS && levels.last>0.1
      raise Elfis::BastillePodmienFront.l('Przekrój nie obejmuje pełnej szerokości i grubości.','The cross-section does not span the full width and thickness.') unless points.any? { |u,v| u.abs<EPS } && points.any? { |u,v| (v-t).abs<EPS }
      p.merge(points:points,width:a,thickness:t,centre_thickness:levels.last,inner_edge:inner.first)
    end

    def default_onepiece
      {id:'onepiece-demo',name:'One-Piece — przykład',kind:'onepiece',builtin:true,width:70.0,thickness:18.0,
       points:[[0,0],[70,0],[70,6],[64,6],[60,18],[0,18]],shoulder:60.0,panel:0.0,clearance:0.0}
    end

    # Measurements after instance transforms can be 140.00000000000009 mm
    # for a nominal 140 mm panel. Compare the remaining centre span using
    # SketchUp's point tolerance at the same scale used to construct faces.
    def validate_onepiece_dimensions(p,width,height)
      a=p[:width]
      spans=[width-2*a,height-2*a]
      valid=[width,height].all? { |n| n.finite? && n>0 } && spans.all? do |span|
        span>0 && Geom::Point3d.new(span.mm*SCALE,0,0)!=ORIGIN
      end
      unless valid
        limit=door_dimension_label(2*a)
        size="#{door_dimension_label(height)} × #{door_dimension_label(width)}"
        raise l("One-Piece „#{p[:name]}”: wysokość i szerokość muszą być większe niż #{limit} mm i pozostawiać miejsce na środek. Otrzymano #{size} mm. Wybierz węższy przekrój albo wariant niskiej szuflady.","One-Piece “#{p[:name]}”: height and width must exceed #{limit} mm and leave room for the centre. Received #{size} mm. Choose a narrower cross-section or a low-drawer variant.")
      end
      true
    end

    def add_selected_onepiece
      raw=ProfileOutline.normalize(ProfileOutline.selected_outline(Sketchup.active_model))
      # A plain outside edge and a thinner centre make the orientation explicit.
      candidates=[[false,false],[true,false],[false,true],[true,true]].map do |flip_u,flip_v|
        raw.merge(points:raw[:points].map { |u,v| [flip_u ? raw[:width]-u : u,flip_v ? raw[:thickness]-v : v] })
      end
      validated=nil
      candidates.each do |candidate|
        begin
          validated=validate_onepiece(candidate);break
        rescue ArgumentError,RuntimeError
          next
        end
      end
      raise Elfis::BastillePodmienFront.l('Narysuj pełny zamknięty przekrój One-Piece: tył, zewnętrzne obramowanie i przejście do środka. Wewnętrzny koniec musi łączyć tył z powierzchnią środka, bez rowka na osobną płycinę.','Draw a complete closed One-Piece cross-section: back, outer border and transition to the centre. The inner end must connect the back to the centre surface, without a separate-panel groove.') unless validated
      @draft_profile=validated.merge(id:SecureRandom.uuid,name:'Nowy One-Piece',kind:'onepiece',builtin:false,draft:true,panel:0.0,clearance:0.0)
    end

    def build_onepiece(model,p,width,height)
      p=validate_onepiece(p)
      a,t=p.values_at(:width,:thickness)
      validate_onepiece_dimensions(p,width,height)
      d=model.definitions.add('One-Piece Door')
      d.description='Jednoczęściowy front z przekroju. Ciągła bryła z zamkniętym środkiem; ostre narożniki wewnętrzne jak Follow Me.'
      body=d.entities.add_group;body.name='One-Piece Door'
      point=->(x,y,z) { Geom::Point3d.new(x.mm*SCALE,y.mm*SCALE,z.mm*SCALE) }
      loops=p[:points].map { |u,v| [[u,v,u],[width-u,v,u],[width-u,v,height-u],[u,v,height-u]].map { |xyz| point.call(*xyz) } }
      loops.each_index do |i|
        next if i==p[:inner_edge]
        j=(i+1)%loops.length
        4.times do |k|
          l=(k+1)%4
          raise Elfis::BastillePodmienFront.l('Nie udało się zbudować powierzchni One-Piece.','Could not build a One-Piece face.') unless body.entities.add_face(loops[i][k],loops[i][l],loops[j][l],loops[j][k])
        end
      end
      [0,p[:centre_thickness]].each do |v|
        body.entities.add_face([[a,v,a],[width-a,v,a],[width-a,v,height-a],[a,v,height-a]].map { |xyz| point.call(*xyz) })
      end
      orient(body)
      # Remove coplanar construction seams, leaving an uninterrupted back/panel.
      seams=body.entities.grep(Sketchup::Edge).select { |e| e.faces.length==2 && e.faces[0].normal.dot(e.faces[1].normal)>1-1e-9 }
      body.entities.erase_entities(seams) unless seams.empty?
      raise Elfis::BastillePodmienFront.l('Przekrój One-Piece nie utworzył jednej zamkniętej bryły.','The One-Piece cross-section did not create a single closed solid.') unless solid?(body) && body.volume>0
      body.entities.grep(Sketchup::Edge).each do |edge|
        if edge.faces.length==2 && edge.faces[0].normal.dot(edge.faces[1].normal)>Math.cos(20.degrees)
          edge.soft=true;edge.smooth=true
        end
      end
      body.transform!(Geom::Transformation.scaling(1.0/SCALE))
      actual=[d.bounds.width.to_mm,d.bounds.height.to_mm,d.bounds.depth.to_mm]
      raise Elfis::BastillePodmienFront.l('Nieprawidłowe wymiary frontu One-Piece.','Invalid One-Piece front dimensions.') unless actual.zip([width,t,height]).all? { |x,y| (x-y).abs<0.001 }
      d.set_attribute('ElfisDrzwi','width_mm',width);d.set_attribute('ElfisDrzwi','height_mm',height)
      d.set_attribute('ElfisDrzwi','construction','onepiece')
      d
    end
  end
end
