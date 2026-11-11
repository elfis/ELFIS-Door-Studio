# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    # Preserve the six surface roles, including individual edge-band materials.
    # Classify in the replacement's axes so rotated/mirrored source axes work.
    def slab_surface_materials(source,info)
      palette={};areas={};mapping=info[:placement].inverse*source.transformation
      limits=[info[:width].mm,info[:source_thickness].mm,info[:height].mm]
      walk=nil
      walk=->(entities,tr,inherited,stack) do
        entities.each do |e|
          if e.is_a?(Sketchup::Face)
            points=e.vertices.map { |v| v.position.transform(tr) }
            role=nil
            3.times do |axis|
              [0,1].each do |side|
                plane=side*limits[axis]
                role=[axis,side] if points.all? { |p| (p.to_a[axis]-plane).abs<0.01.mm }
              end
            end
            next unless role
            area=e.area(tr)
            if area>areas.fetch(role,-1)
              palette[role]=[e.material || inherited,e.back_material || inherited]
              areas[role]=area
            end
          elsif instance?(e) && !stack[e.definition]
            next if e.get_attribute('ElfisHandles','handle',false)
            # Generated doors expose only their own body, not CNC containers.
            next if tr==mapping && source.get_attribute('ElfisBastillePodmien','generated',false) && !own_geometry?(e,source)
            walk.call(e.definition.entities,tr*e.transformation,e.material || inherited,stack.merge(e.definition=>true))
          end
        end
      end
      walk.call(source.definition.entities,mapping,source.material,{})
      palette
    end

    def preserve_slab_materials(source,replacement,info)
      palette=slab_surface_materials(source,info)
      return if palette.empty? || palette.values.flatten.compact.empty?
      # Never paint a cached definition or a body used by another door.
      replacement.make_unique
      limits=[info[:width].mm,info[:profile][:thickness].mm,info[:height].mm]
      replacement.definition.entities.each do |body|
        next unless instance?(body) && own_geometry?(body,replacement)
        body.make_unique
        body.definition.entities.grep(Sketchup::Face).each do |face|
          points=face.vertices.map { |v| v.position.transform(body.transformation) }
          palette.each do |(axis,side),materials|
            next unless points.all? { |point| (point.to_a[axis]-side*limits[axis]).abs<0.01.mm }
            face.material,face.back_material=materials
            break
          end
        end
      end
    end
  end
end
