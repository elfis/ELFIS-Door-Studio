# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    def default_jpull
      {id:'jpull-22',name:'J-pull 22 mm',kind:'jpull',thickness:22.0,handle_edge:'top',cavity:40.0,lip:4.2,radius:5.0,source:'parametric',builtin:true}
    end

    def validate_jpull(p)
      [:thickness,:cavity,:lip,:radius].each do |key|
        p[key]=Float(p.fetch(key))
        raise Elfis::BastillePodmienFront.l('Nieprawidłowe parametry J-pull.','Invalid J-pull parameters.') unless p[key].finite?
      end
      raise Elfis::BastillePodmienFront.l('Wybierz krawędź uchwytu.','Choose a handle edge.') unless %w[top bottom left right].include?(p[:handle_edge])
      raise Elfis::BastillePodmienFront.l('Grubość musi wynosić od 0.1 do 80 mm.','Thickness must be greater than 0.1 mm and at most 80 mm.') unless p[:thickness]>0.1 && p[:thickness]<=80
      raise Elfis::BastillePodmienFront.l('Nieprawidłowa głębokość wnęki.','Invalid recess depth.') unless p[:cavity]>0 && p[:cavity]<=500
      if p[:source]=='custom'
        points=p[:section]
        raise Elfis::BastillePodmienFront.l('Brak przekroju J-pull.','No J-pull cross-section.') unless points.is_a?(Array) && points.length>=4
        raise Elfis::BastillePodmienFront.l('Przekrój jest zbyt krótki: narysuj pełny przekrój z prostym odcinkiem płyty.','The cross-section is too short: draw a complete section including a straight panel segment.') unless p[:reference_length]>2*p[:cavity]
        # The adjustable middle must be straight: any vertices there would distort features.
        raise Elfis::BastillePodmienFront.l('Środkowa część przekroju musi być prostą płytą.','The middle of the cross-section must be a plain panel.') if points.any? { |u,v| u>p[:cavity]+0.01 && u<p[:reference_length]-p[:cavity]-0.01 }
      else
        raise Elfis::BastillePodmienFront.l('Warga i promień muszą być dodatnie.','Lip thickness and radius must be positive.') unless p[:lip]>0 && p[:radius]>0
        raise Elfis::BastillePodmienFront.l('Za duży promień lub warga dla tej grubości.','Radius or lip is too large for this thickness.') unless p[:lip]+2*p[:radius]<p[:thickness]
        raise Elfis::BastillePodmienFront.l('Wnęka jest zbyt płytka dla promienia.','The recess is too shallow for this radius.') unless p[:cavity]>2*p[:radius]
      end
      p
    end

    def add_jpull_profile
      @draft_profile=default_jpull.merge(id:SecureRandom.uuid,name:'Nowy J-pull',builtin:false,draft:true)
    end

    def import_jpull_section(data)
      raw=ProfileOutline.normalize(ProfileOutline.selected_outline(Sketchup.active_model))
      candidate=@draft_profile && @draft_profile[:id]==data[:id] ? @draft_profile.dup : library[:profiles].find { |p| p[:id]==data[:id] }&.dup
      raise Elfis::BastillePodmienFront.l('Najpierw wybierz profil J-pull.','Select a J-pull profile first.') unless candidate && candidate[:kind]=='jpull'
      candidate.merge!(id:SecureRandom.uuid,builtin:false,draft:true,source:'custom',thickness:raw[:thickness],reference_length:raw[:width],cavity:Float(data[:cavity]),section:raw[:points].map { |u,v| [raw[:width]-u,v] })
      validate_jpull(candidate)
      @draft_profile=candidate
    end

    def jpull_section(p,span)
      raise Elfis::BastillePodmienFront.l('Front jest za krótki dla wnęki uchwytu.','The front is too short for the handle recess.') unless span>2*p[:cavity]
      if p[:source]=='custom'
        delta=span-p[:reference_length]
        points=p[:section].map { |u,v| [u>p[:reference_length]/2.0 ? u+delta : u,v] }
        points=points.map { |u,v| [u,p[:thickness]-v] } if p[:flip_front]
        # u=0 is the handle end; reversing is useful for imported outlines.
        points=points.map { |u,v| [span-u,v] } if p[:flip_end]
        return points
      end
      t,d,l,r=p.values_at(:thickness,:cavity,:lip,:radius)
      points=[[0,t],[0,t-l],[d-r,t-l]]
      (1..24).each do |i|
        angle=Math::PI*i/24.0
        points<<[d-r+r*Math.sin(angle),t-l-r+r*Math.cos(angle)]
      end
      # Canonical y=0 is the cabinet-facing back; y=t is the exterior.
      # The handle recess must open toward the exterior, leaving the rear skin intact.
      (points+[[d-2*r,0],[span,0],[span,t]]).map { |u,v| [u,t-v] }
    end

    def build_jpull(model,p,width,height)
      edge=p[:handle_edge]
      span=%w[top bottom].include?(edge) ? height : width
      length=%w[top bottom].include?(edge) ? width : height
      raise Elfis::BastillePodmienFront.l('Front jest za wąski dla tej grubości.','The front is too narrow for this thickness.') unless length>p[:thickness]
      section=jpull_section(p,span)
      definition=model.definitions.add("J-pull #{height}x#{width}")
      body=definition.entities.add_group
      body.name="Płyta J-pull — #{edge}"
      points=section.map do |u,v|
        xyz=case edge
        when 'top' then [0,v,height-u]
        when 'bottom' then [0,v,u]
        when 'left' then [u,v,0]
        when 'right' then [width-u,v,0]
        end
        xyz.map { |value| value.mm*SCALE }
      end
      face=body.entities.add_face(points)
      raise Elfis::BastillePodmienFront.l('Przekrój J-pull nie tworzy powierzchni.','The J-pull cross-section does not form a face.') unless face
      extrusion_axis=%w[top bottom].include?(edge) ? X_AXIS : Z_AXIS
      face.reverse! if face.normal.dot(extrusion_axis)<0
      face.pushpull(length.mm*SCALE)
      orient(body)
      raise Elfis::BastillePodmienFront.l('Nie udało się utworzyć bryły J-pull.','Could not create a solid J-pull door.') unless solid?(body)
      body.entities.grep(Sketchup::Edge).each do |e|
        if e.faces.length==2 && e.faces[0].normal.dot(e.faces[1].normal)>Math.cos(20.degrees)
          e.soft=true; e.smooth=true
        end
      end
      body.transform!(Geom::Transformation.scaling(1.0/SCALE))
      actual=[definition.bounds.width,definition.bounds.height,definition.bounds.depth].map(&:to_mm)
      raise Elfis::BastillePodmienFront.l('Wymiary J-pull nie zgadzają się z frontem.','J-pull dimensions do not match the front.') unless actual.zip([width,p[:thickness],height]).all? { |a,b| (a-b).abs<0.001 }
      definition
    end
  end
end
