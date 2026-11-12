# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    def build_chamfered_slab(body,width,height,thickness,chamfer)
      w,h,t,c=[width,height,thickness,chamfer].map(&:mm)
      rear=[[0,0,0],[w,0,0],[w,0,h],[0,0,h]]
      shoulder=[[0,t-c,0],[w,t-c,0],[w,t-c,h],[0,t-c,h]]
      front=[[c,t,c],[w-c,t,c],[w-c,t,h-c],[c,t,h-c]]
      center=Geom::Point3d.new(w/2,t/2,h/2)
      polygons=[rear,front]
      4.times do |i|
        j=(i+1)%4
        polygons<<[rear[i],rear[j],shoulder[j],shoulder[i]]
        polygons<<[shoulder[i],shoulder[j],front[j],front[i]]
      end
      polygons.each do |points|
        face=body.entities.add_face(points)
        raise l('Nie udało się utworzyć fazy Slab.','Could not create the Slab chamfer.') unless face
        face.reverse! if face.normal.dot(face.vertices.first.position-center)<0
      end
    end
  end
end
