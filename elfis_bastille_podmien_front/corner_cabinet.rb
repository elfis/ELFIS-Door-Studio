# encoding: UTF-8
require 'json'
module Elfis
  # Geometry shared by corner machining and shelf arrangement. All distances
  # are physical world distances; model axes need not match cabinet axes.
  module CornerCabinet
    extend self
    def corner?(all,source=nil)
      sides=all.select { |b|!CarcassJoinery.back?(b) && StudioSettings.role?(b[:entity],:sides) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }
      return false unless sides.combination(2).any? { |a,b|a[:axes][a[:thin]].dot(b[:axes][b[:thin]]).abs<0.001 }
      return true unless source
      return nonrectangular?(source) if source[:axes][source[:thin]].dot(Z_AXIS).abs>0.999
      all.select { |b|b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999 && nonrectangular?(b) }.any? { |b|contacts(b,all).any? { |e|e[:panel][:path]==source[:path] } }
    end
    def nonrectangular?(b)
      f=top_face(b);return false unless f
      dims=[b[:bb].width,b[:bb].height,b[:bb].depth];dims.delete_at(b[:thin])
      f.area.to_f < dims[0].to_f*dims[1].to_f*0.98
    end
    def good;[Sketchup::Face::PointInside,Sketchup::Face::PointOnEdge,Sketchup::Face::PointOnVertex];end
    def top_face(b)
      b[:faces].select { |f|f.normal.transform(b[:world]).normalize.dot(Z_AXIS).abs>0.999 }.max_by(&:area)
    end
    def point_on?(b,p)
      q=p.transform(b[:world].inverse)
      b[:faces].any? { |f|q.distance_to_plane(f.plane).to_f<0.02.mm.to_f && good.include?(f.classify_point(q)) }
    end
    def outline(b)
      top_face(b).outer_loop.vertices.map { |v|v.position.transform(b[:world]) }
    end
    def edge_key(a,b,source)
      [a,b].map { |p|q=p.transform(source[:world].inverse);q[source[:thin]]=0;q.to_a.map { |v|v.to_f.round(5) } }.sort.flatten.join(',')
    end
    # Each contact is a straight boundary segment of the real source outline,
    # clipped by the receiving board. Curves around the L opening do not count.
    def contacts(source,all)
      f=top_face(source);raise 'No horizontal source face.' unless f
      out=[]
      f.outer_loop.edges.each do |edge|
        a,b=edge.vertices.map { |v|v.position.transform(source[:world]) }
        vector=b-a;next if vector.length.to_mm<20 || vector.normalize.dot(Z_AXIS).abs>0.001
        tangent=vector.normalize;normal=tangent.cross(Z_AXIS).normalize
        mid=Geom::Point3d.linear_combination(0.5,a,0.5,b)
        # A face test fixes outward irrespective of reflected component axes.
        inside=mid.offset(normal,0.5.mm).transform(source[:world].inverse)
        normal.reverse! if good.include?(f.classify_point(inside))
        frame=Geom::Transformation.axes(a,tangent,normal,Z_AXIS);inv=frame.inverse
        all.each do |receiver|
          next if receiver[:entity]==source[:entity] || receiver[:axes][receiver[:thin]].dot(Z_AXIS).abs>0.001
          next unless StudioSettings.role?(receiver[:entity],:sides) || CarcassJoinery.back?(receiver)
          next unless receiver[:axes][receiver[:thin]].dot(normal).abs>0.999
          rb=ShelfPins.projected(receiver[:points],inv)
          next unless rb.min.y.to_f.abs<=2.mm.to_f && rb.max.y.to_f>0
          lo=[0.0,rb.min.x.to_f].max;hi=[vector.length.to_f,rb.max.x.to_f].min
          next unless hi-lo>20.mm.to_f
          z=source[:points].map(&:z).sum/8.0
          next unless receiver[:points].map(&:z).min<=z && receiver[:points].map(&:z).max>=z
          # Real receiver surface must meet the centre of the source edge.
          sample=Geom::Point3d.new((lo+hi)/2,rb.min.y,0).transform(frame)
          sample.z=z
          next unless point_on?(receiver,sample)
          out<<{panel:receiver,a:a,b:b,tangent:tangent,normal:normal,frame:frame,inverse:inv,box:rb,lo:lo,hi:hi,length:vector.length.to_f,key:edge_key(a,b,source),back:CarcassJoinery.back?(receiver)}
        end
      end
      # Two receivers on the same edge segment are ambiguous, never choose one
      # based on traversal order.
      out.combination(2).each do |a,b|
        next unless a[:key]==b[:key]
        raise 'Overlapping receiving panels on a corner edge.' if [a[:hi],b[:hi]].min-[a[:lo],b[:lo]].max>1.mm.to_f
      end
      out
    end
    def pattern(source)
      raw=source[:entity].get_attribute(ShelfPins::DICT,'corner_pattern');raw ? JSON.parse(raw,symbolize_names:true) : nil
    end
    def rows_for(contact,source,c,saved)
      matching=saved && saved.find { |v|v[:key]==contact[:key] && v[:back]==contact[:back] }
      if matching
        return matching[:rows].map do |v|
          if v.is_a?(Hash)
            distance=v[:offset].mm.to_f
            v[:end]=='b' ? contact[:length]-distance : distance
          else;v.mm.to_f;end
        end
      end
      return [] if saved # Explicitly absent support edges stay absent on Refresh.
      z=source[:points].map(&:z).min-c[:below].mm
      imported=ShelfPins.circular_holes(contact[:panel]).select do |h|
        q=h[:center].transform(contact[:inverse])
        expected_depth=contact[:back] ? contact[:panel][:lengths][contact[:panel][:thin]].to_mm : c[:depth]
        (h[:diameter]-c[:diameter]).abs<0.01 && (h[:depth]-expected_depth).abs<0.01 && (h[:center].z-z).to_f.abs<0.1.mm.to_f && q.x>contact[:lo] && q.x<contact[:hi] && (q.y-contact[:box].min.y).to_f.abs<contact[:panel][:lengths][contact[:panel][:thin]].to_f+0.1.mm.to_f
      end
      unless imported.empty?
        return imported.map { |h|h[:center].transform(contact[:inverse]).x.to_f }.sort.uniq { |x|x.to_mm.round(2) }
      end
      return [] if contact[:back] # Through-back supports are opt-in via an existing pattern.
      [contact[:lo]+c[:back].mm.to_f,contact[:hi]-c[:front].mm.to_f]
    end
    def pin_plan(path,c,m,source,all)
      cs=contacts(source,all);saved=pattern(source);holes=[];saved_rows=[]
      cs.each do |edge|
        rows=rows_for(edge,source,c,saved)
        next if rows.empty?
        anchors=rows.map { |x|x<=edge[:length]/2 ? {end:'a',offset:x.to_mm} : {end:'b',offset:(edge[:length]-x).to_mm} }
        saved_rows<<{key:edge[:key],back:edge[:back],rows:anchors}
        panel=edge[:panel];raise 'A support panel is locked.' if panel[:path].any?(&:locked?)
        through=edge[:back];depth=through ? panel[:lengths][panel[:thin]].to_mm : c[:depth]
        raise 'Shelf pin drilling exceeds the receiving thickness.' if !through && depth.mm>=panel[:lengths][panel[:thin]]-0.01.mm
        rows.each do |x|
          raise 'Shelf pin row lies beyond its actual contact edge.' unless x>edge[:lo] && x<edge[:hi]
          (-c[:under]..c[:above]).each do |step|
            z=source[:points].map(&:z).min-c[:below].mm+step*c[:pitch].mm
            q=Geom::Point3d.new(x,through ? edge[:box].max.y : edge[:box].min.y,0).transform(edge[:frame]);q.z=z
            h={panel:panel,point:q,normal:through ? edge[:normal].reverse : edge[:normal],tangent:edge[:tangent],diameter:c[:diameter],depth:depth,kind: :pin}
            CarcassJoinery.check_circle(h);holes<<h
          end
        end
      end
      raise 'No supported shelf edges found in this corner cabinet.' if holes.empty?
      {shelf:source,holes:holes,settings:c,corner:true,corner_pattern:saved_rows}
    end
    def footprint(b)
      outline(b).map { |p|[p.x.to_mm.round(2),p.y.to_mm.round(2)] }.sort
    end
    def spacing_info(path,m,all)
      vertical=all.select { |b|b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }
      low=vertical.map { |b|b[:points].map(&:z).min }.max
      high=vertical.map { |b|b[:points].map(&:z).max }.min
      horizontal=all.select { |b|!CarcassJoinery.back?(b) && b[:axes][b[:thin]].dot(Z_AXIS).abs>0.999 }
      shelves=horizontal.select { |b|ShelfSpacing.adjustable?(b) }.sort_by { |b|b[:points].map(&:z).min }
      reference=shelves.first || horizontal.first
      raise 'Add one corner shelf template first.' unless reference
      shape=footprint(reference)
      # Rails can extend farther toward the opening than adjustable shelves.
      # Their outside footprint still spans the same corner bay.
      ref_xy=source_xy_bounds(reference)
      same=horizontal.select { |b|source_xy_bounds(b).zip(ref_xy).all? { |a,d|(a-d).abs<0.1 } }
      bottom=same.select { |b|(b[:points].map(&:z).min-low).to_f.abs<2.mm.to_f }.map { |b|b[:points].map(&:z).max }.max
      top=same.select { |b|(b[:points].map(&:z).max-high).to_f.abs<2.mm.to_f }.map { |b|b[:points].map(&:z).min }.min
      low=bottom if bottom;high=top if top
      inner=horizontal.select { |b|b[:points].map(&:z).min>=low-0.01.mm && b[:points].map(&:z).max<=high+0.01.mm }
      raise 'A fixed shelf divides this corner bay; select a separate compartment.' if inner.any? { |b|!ShelfSpacing.adjustable?(b) }
      raise 'Corner shelves have different outlines; select one compartment.' unless inner.all? { |b|footprint(b)==shape }
      shelves=inner.sort_by { |b|b[:points].map(&:z).min }
      raise 'A corner shelf or parent is locked.' if shelves.any? { |b|b[:path].any?(&:locked?) }
      template=shelves.empty? ? ShelfSpacing.saved_template(path,m) : ShelfSpacing.template(shelves.first,path,m)
      raise 'No saved corner shelf template.' unless template
      gaps=[];z=low
      shelves.each { |b|min,max=b[:points].map(&:z).minmax;gaps<<(min-z).to_mm;z=max }
      gaps<<(high-z).to_mm
      raise 'Corner shelves overlap or extend outside the cabinet.' if gaps.any? { |v|v< -0.01 }
      width=reference[:axes].find { |v|v.dot(Z_AXIS).abs<0.001 }
      frame=Geom::Transformation.axes(ORIGIN,width,Z_AXIS.cross(width).normalize,Z_AXIS);inv=frame.inverse;bb=ShelfPins.projected(reference[:points],inv)
      {path:path,shelves:shelves,template:template,low:low.to_mm,high:high.to_mm,gaps:gaps,frame:frame,inverse:inv,left:bb.min.x,right:bb.max.x,corner:true}
    end
    def source_xy_bounds(b)
      ps=b[:points];[ps.map(&:x).min,ps.map(&:x).max,ps.map(&:y).min,ps.map(&:y).max].map(&:to_mm)
    end
    def front_at_end?(edge,all)
      backs=all.select { |b|CarcassJoinery.back?(b) }
      score=->(point) do
        backs.map do |b|
          axis=b[:axes][b[:thin]]
          values=b[:points].map { |q|q.to_a.zip(axis.to_a).sum { |x,n|x*n } }
          v=point.to_a.zip(axis.to_a).sum { |x,n|x*n }
          [(v-values.min).abs,(v-values.max).abs].min
        end.min || 0
      end
      score.call(edge[:b])>score.call(edge[:a])
    end
    def joint_plan(path,c,m,source,all)
      return back_joint_plan(path,c,m,source,all) if CarcassJoinery.back?(source)
      edges=contacts(source,all).reject { |e|e[:back] }
      raise 'No side panels meet this corner rail or fixed shelf.' if edges.empty?
      minz,maxz=source[:points].map(&:z).minmax
      cabinet_top=all.select { |b|b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001 }.map { |b|b[:points].map(&:z).max }.min
      upper=(maxz-cabinet_top).to_f.abs<2.mm.to_f
      z=(minz+maxz)/2+(upper ? -1 : 1)*c[:centre_offset].mm
      holes=[]
      edges.each do |edge|
        raise 'Receiving panel or parent is locked.' if edge[:panel][:path].any?(&:locked?)
        from_end=front_at_end?(edge,all)
        # Datum is the full actual source edge, even if the side overhangs it.
        CarcassJoineryLayout.row(c,0,edge[:length].to_mm).each do |spec|
          x=from_end ? edge[:length]-spec[:position].mm.to_f : spec[:position].mm.to_f
          next unless x>edge[:lo] && x<edge[:hi]
          point=Geom::Point3d.new(x,edge[:box].min.y,0).transform(edge[:frame]);point.z=z
          source_end=point.offset(edge[:normal],-edge[:box].min.y)
          # Validate the actual narrow source face as well as the side surface.
          target=spec.merge(panel:source,point:source_end,normal:edge[:normal],tangent:edge[:tangent],depth:0)
          CarcassJoinery.check_circle(target)
          h=spec.merge(panel:edge[:panel],point:point,normal:edge[:normal],tangent:edge[:tangent])
          CarcassJoinery.check_circle(h);holes<<h
        end
      end
      raise 'No active spindles fit the corner source edges.' if holes.empty?
      {shelf:source,holes:holes,settings:c,corner:true,sides:edges.map { |e|[0,e[:panel],e[:box],e[:box].min.y] }}
    end
    def back_joint_plan(path,c,m,source,all)
      p=HangerCutouts.back_frame(source,all);sb=p[:bounds];receivers=[];holes=[]
      [-1,1].each_with_index do |sign,i|
        x=sign<0 ? sb.min.x : sb.max.x
        matches=all.reject { |b|b[:entity]==source[:entity] }.filter_map do |b|
          next unless b[:axes][b[:thin]].dot(p[:width]).abs>0.999
          next unless StudioSettings.role?(b[:entity],:sides) || CarcassJoinery.back?(b)
          rb=ShelfPins.projected(b[:points],p[:inverse]);inner=sign<0 ? rb.max.x : rb.min.x
          next unless (inner-x).to_f.abs<=2.mm.to_f && rb.min.y<=sb.center.y && rb.max.y>=sb.center.y
          next unless rb.min.z<=sb.min.z+0.1.mm && rb.max.z>=sb.max.z-0.1.mm
          [b,rb,inner]
        end
        raise 'Ambiguous side meeting a corner back.' if matches.length>1
        next if matches.empty?
        panel,rb,inner=matches.first
        raise 'Receiving back/side is locked.' if panel[:path].any?(&:locked?)
        receivers<<[0,panel,rb,inner]
        CarcassJoinery.back_specs(source,p,i,c).each do |spec|
          h=spec.merge(panel:panel,point:Geom::Point3d.new(inner,spec[:y],spec[:z]).transform(p[:frame]),normal:sign<0 ? p[:width].reverse : p[:width],tangent:Z_AXIS)
          CarcassJoinery.check_circle(h);holes<<h
        end
      end
      raise 'No adjoining vertical panel for this corner back.' if receivers.empty?
      p=p.merge(sides:receivers)
      holes.concat(CarcassJoinery.back_rail_holes(source,p,all,c,true))
      p.merge(holes:holes,settings:c,corner:true)
    end
  end
end
