# encoding: UTF-8
module Elfis
  module ShelfSpacingLayout
    extend self
    # All distances are clear openings in mm; 1..9 are relative weights unless
    # explicitly suffixed mm. Colon, comma and semicolon separate openings.
    def openings(height,thicknesses,expression)
      height=Float(height);ts=thicknesses.map { |v|Float(v) }
      raise 'Invalid cabinet or shelf thickness.' unless height.finite? && height>0 && ts.all? { |t|t.finite? && t>0 }
      tokens=expression.to_s.split(/[,;:]/).map(&:strip)
      raise "Enter #{ts.length+1} clear openings, from bottom to top." unless tokens.length==ts.length+1
      specs=tokens.map do |token|
        match=token.match(/\A(\d+(?:\.\d+)?)\s*(mm|%)?\z/i)
        raise 'Use positive mm distances or relative weights, e.g. 300,200,1,1.' unless match
        value=Float(match[1]);raise 'Opening values must be finite and positive.' unless value.finite? && value>0
        weight=match[2]=='%' || (!match[2] && value<10)
        [weight ? :weight : :mm,value]
      end
      free=height-ts.sum;fixed=specs.sum { |kind,v|kind==:mm ? v : 0 };weight=specs.sum { |kind,v|kind==:weight ? v : 0 }
      raise 'Fixed openings and shelf thicknesses exceed the cabinet clear height.' if fixed>free+0.001
      raise 'Fixed openings must fill the clear height; add a relative weight for the remainder.' if weight==0 && (free-fixed).abs>0.01
      values=specs.map { |kind,v|kind==:mm ? v : (free-fixed)*v/weight }
      raise 'Each clear opening must be at least 1 mm.' unless values.all? { |v|v>=1.0-0.001 }
      values
    end
    def positions(bottom,thicknesses,gaps)
      z=Float(bottom);thicknesses.each_with_index.map { |t,i|z+=gaps.fetch(i);v=z;z+=t;v }
    end
  end
end
