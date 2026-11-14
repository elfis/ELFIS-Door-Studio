# encoding: UTF-8
# Millimetre-only layout, independent of SketchUp. Spindle 0 is the front datum.
module Elfis
  module CarcassJoineryLayout
    extend self
    def defaults
      # Only positions demonstrated by the inspected production example are active.
      {front:30.0,pitch:32.0,pattern:'S D S - D - S D S - D - S D - - - - - - -',
       dowel_diameter:8.0,dowel_depth:14.0,screw_diameter:3.0,screw_depth:18.0,
       centre_offset:0.2,back_axis:12.5,back_margin:55.0,back_spacing:220.0}
    end
    def validate(input)
      c=defaults.merge(input)
      (defaults.keys-[:pattern]).each do |key|
        c[key]=Float(c[key]);raise 'Dimensions must be finite.' unless c[key].finite?
      end
      raise 'Offsets cannot be negative.' if %i[front back_axis back_margin].any? { |k| c[k]<0 }
      raise 'Pitch, diameters, depths and spacing must be positive.' unless %i[pitch dowel_diameter dowel_depth screw_diameter screw_depth back_spacing].all? { |k| c[k]>0 }
      raise 'The spindle pitch must be 32 mm.' unless (c[:pitch]-32.0).abs<0.0001
      cells=c[:pattern].to_s.upcase.split(/[\s,;]+/).reject(&:empty?)
      raise 'Enter exactly 21 spindle positions: D, S or -.' unless cells.length==21 && cells.all? { |v| %w[D S -].include?(v) }
      raise 'Enable at least one spindle.' if cells.all? { |v| v=='-' }
      c[:pattern]=cells.join(' ');c
    end
    def row(c,front_to_min,front_to_max)
      c=validate(c)
      c[:pattern].split.each_with_index.filter_map do |kind,i|
        next if kind=='-'
        type=kind=='D' ? :dowel : :screw
        diameter=c["#{type}_diameter".to_sym];position=c[:front]+i*c[:pitch]
        # A short rail only loses positions; its datum never moves.
        next unless position-diameter/2>front_to_min+0.01 && position+diameter/2<front_to_max-0.01
        {spindle:i+1,kind:type,position:position,diameter:diameter,depth:c["#{type}_depth".to_sym]}
      end
    end
    def back_row(c,height)
      c=validate(c);height=Float(height);span=height-2*c[:back_margin]
      raise 'Back panel is too short for the end margins.' unless span>=0 && c[:back_margin]>c[:screw_diameter]/2
      n=span<0.01 ? 1 : (span/c[:back_spacing]).ceil+1
      raise 'Too many back screws; increase the spacing.' if n>500
      Array.new(n) { |i| c[:back_margin]+(n==1 ? 0 : span*i/(n-1)) }
    end
  end
end
