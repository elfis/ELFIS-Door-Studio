# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    extend self
    EPS=0.0001
    SCALE=100.0
    VERSION='2.9.1' unless const_defined?(:VERSION)
    def orient(group)
      faces = group.entities.grep(Sketchup::Face)
      signed = faces.sum { |f| f.area*f.normal.dot(Geom::Vector3d.new(f.vertices.first.position.to_a))/3.0 }
      faces.each(&:reverse!) if signed < 0
    end

    def solid?(group)
      group.valid? && group.manifold?
    end

    # Returns a new definition. Caller owns the SketchUp undo operation.
    def build(model,profile,width,height,shoulder,panel_thickness=0.0,clearance=1.0)
      a, t = profile.values_at(:width,:thickness)
      raise Elfis::BastillePodmienFront.l('Wysokość i szerokość drzwi muszą być większe niż dwukrotna szerokość profilu.','Door height and width must exceed twice the profile width.') unless width>2*a && height>2*a
      raise Elfis::BastillePodmienFront.l('Szerokość płaskiej części ramy musi być dodatnia i nie większa od szerokości profilu.','The flat frame shoulder must be positive and no wider than the profile.') unless shoulder>0 && shoulder<=a+EPS
      raise Elfis::BastillePodmienFront.l('Luz płyciny nie może być ujemny.','Panel clearance cannot be negative.') if clearance<0
      groove = profile[:groove]
      if panel_thickness>0
        raise Elfis::BastillePodmienFront.l('Nie rozpoznano prostokątnego rowka. Wybierz wariant bez płyciny.','No rectangular groove recognised. Choose a frame without a panel.') unless groove
        raise Elfis::BastillePodmienFront.l('Płycina jest za gruba do rowka.','The panel is too thick for the groove.') unless panel_thickness < groove[:high]-groove[:low]
        raise Elfis::BastillePodmienFront.l('Luz jest za duży: płycina wysunęłaby się z rowka.','Clearance is too large: the panel would leave the groove.') unless groove[:floor]+clearance < a
      end
      definition=model.definitions.add("Drzwi z profilu #{height.round(2)}x#{width.round(2)} mm")
      definition.description='Szeroka rama łączona na 90 stopni. Profilowanie wewnętrzne tylko wokół płyciny. Model bez czopów i okuć.'
      e=definition.entities
      point=->(x,y,z) { Geom::Point3d.new(x.mm*SCALE,y.mm*SCALE,z.mm*SCALE) }
      ring=e.add_group
      loops=profile[:points].map { |u,v| [[u,v,u],[width-u,v,u],[width-u,v,height-u],[u,v,height-u]].map { |p| point.call(*p) } }
      loops.each_index do |i|
        j=(i+1)%loops.length
        4.times { |k| l=(k+1)%4; ring.entities.add_face(loops[i][k],loops[i][l],loops[j][l],loops[j][k]) }
      end
      orient(ring)
      raise Elfis::BastillePodmienFront.l('Nie udało się utworzyć zamkniętej ramy z tego przekroju.','Could not create a closed solid frame from this cross-section.') unless solid?(ring)
      volume=ring.volume
      b=shoulder
      regions=[
        [[0,0],[b,0],[b,b],[a,a],[a,height-a],[b,height-b],[b,height],[0,height]],
        [[width,0],[width-b,0],[width-b,b],[width-a,a],[width-a,height-a],[width-b,height-b],[width-b,height],[width,height]],
        [[b,0],[width-b,0],[width-b,b],[width-a,a],[a,a],[b,b]],
        [[b,height],[width-b,height],[width-b,height-b],[width-a,height-a],[a,height-a],[b,height-b]]
      ]
      names=['Ramiak lewy','Ramiak prawy','Poprzeczka dolna','Poprzeczka górna']
      parts=[]
      regions.each_with_index do |poly,i|
        poly=poly.each_with_object([]) { |p,list| list << p unless p==list.last }
        mask=e.add_group
        face=mask.entities.add_face(poly.map { |x,z| point.call(x,-1,z) })
        face.reverse! if face.normal.y<0
        face.pushpull((t+2).mm*SCALE)
        part=ring.copy.intersect(mask)
        raise Elfis::BastillePodmienFront.l("Nie udało się dopasować elementu: #{names[i]}.","Could not fit part: #{names[i]}.") unless part && solid?(part)
        part.name=names[i]
        parts << part
      end
      raise Elfis::BastillePodmienFront.l('Kontrola objętości ramy nie powiodła się.','Frame volume check failed.') if (parts.sum(&:volume)-volume).abs/volume>0.00001
      e.to_a.each { |entity| entity.erase! unless parts.include?(entity) }
      parts.each do |part|
        part.entities.grep(Sketchup::Edge).each do |edge|
          if edge.faces.length==2 && edge.faces[0].normal.dot(edge.faces[1].normal)>Math.cos(20.degrees)
            edge.soft=true
            edge.smooth=true
          end
        end
        part.transform!(Geom::Transformation.scaling(1.0/SCALE))
      end
      if panel_thickness>0
        inset=groove[:floor]+clearance
        y=(groove[:low]+groove[:high]-panel_thickness)/2.0
        panel=e.add_group
        panel.name="Płycina #{(width-2*inset).round(2)}x#{(height-2*inset).round(2)}x#{panel_thickness.round(2)} mm"
        face=panel.entities.add_face([[inset,y,inset],[width-inset,y,inset],[width-inset,y,height-inset],[inset,y,height-inset]].map { |p| p.map(&:mm) })
        face.reverse! if face.normal.y<0
        face.pushpull(panel_thickness.mm)
        raise Elfis::BastillePodmienFront.l('Nie udało się utworzyć płyciny.','Could not create the panel.') unless solid?(panel)
        parts << panel
      end
      bounds=definition.bounds
      actual=[bounds.width.to_mm,bounds.height.to_mm,bounds.depth.to_mm]
      expected=[width,t,height]
      raise Elfis::BastillePodmienFront.l('Kontrola wymiarów drzwi nie powiodła się.','Door dimension check failed.') unless actual.zip(expected).all? { |x,y| (x-y).abs<0.001 }
      definition.set_attribute('ElfisDrzwi','width_mm',width)
      definition.set_attribute('ElfisDrzwi','height_mm',height)
      definition.set_attribute('ElfisDrzwi','profile_width_mm',a)
      definition.set_attribute('ElfisDrzwi','shoulder_mm',shoulder)
      definition.set_attribute('ElfisDrzwi','version',VERSION)
      definition
    end

  end
end
