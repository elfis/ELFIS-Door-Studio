# encoding: UTF-8
module Elfis
  module ShelfSpacing
    class Tool
      def initialize;@cache={};end
      def l(pl,en);ShelfSpacing.l(pl,en);end
      def activate
        Sketchup.set_status_text(l('Półki: kliknij szafkę · prześwity od dołu · Zastosuj odświeża podpórki · Esc: koniec','Shelves: click a cabinet · openings from bottom · Apply refreshes shelf pins · Esc: finish'))
        selected=Sketchup.active_model.selection.select { |e|ShelfPins.instance?(e) }
        choose([selected.first]) if selected.length==1
      rescue=>e;@error=e.message
      end
      def choose(path)
        @info=nil;@layout=nil
        @info=ShelfSpacing.inspect_cabinet(path);@layout=ShelfSpacing.plan(@info,@info[:shelves].length);@error=nil;@hover=nil
      end
      def controls
        {minus:[172,64,32,30,'−'],count:[210,64,94,30,@layout ? @layout[:count].to_s : '—'],plus:[310,64,32,30,'+'],pattern:[32,112,310,32,l('Wpisz prześwity / proporcje…','Enter openings / ratios…')],equal:[32,160,310,30,l('Rozłóż równo w świetle','Distribute equal clear openings')],apply:[32,386,150,34,l('Zastosuj + nawierty','Apply + drilling')],reset:[192,386,150,34,l('Przywróć podgląd','Reset preview')]}
      end
      def hit(x,y)
        return nil unless x.between?(20,354) && y.between?(20,452)
        controls.each { |key,(a,b,w,h,_)|return key if x.between?(a,a+w) && y.between?(b,b+h) };:panel
      end
      def set_layout(count,expression,view)
        @layout=ShelfSpacing.plan(@info,count,expression);@error=nil;view.invalidate
      rescue=>e;@error=e.message;Sketchup.set_status_text(e.message);view.invalidate
      end
      def change_count(count,view)
        return unless @info
        value=Float(count);raise 'Shelf count must be a whole number.' unless value.finite? && value==value.to_i
        count=[[value.to_i,0].max,20].min
        set_layout(count,Array.new(count+1,'1').join(','),view)
      end
      def onMouseMove(flags,x,y,view)
        @hot=hit(x,y);if @hot;view.invalidate;return;end
        ph=view.pick_helper;ph.do_pick(x,y);@hover=nil;@hover_error=nil
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e|ShelfPins.instance?(e) }
          raw.length.downto(1) do |n|
            path=raw.take(n);next if ShelfPins.board(path)
            key=path.map(&:persistent_id).join('/')
            @cache.clear if @cache.length>40
            candidate=@cache[key]
            unless candidate
              begin;candidate=ShelfSpacing.inspect_cabinet(path);rescue=>e;candidate=e.message;end
              @cache[key]=candidate
            end
            if candidate.is_a?(Hash);@hover=path;break;else;@hover_error=candidate;end
          end
          break if @hover
        end
        Sketchup.set_status_text(@hover_error) if !@hover && @hover_error
        view.invalidate
      end
      def onLButtonDown(flags,x,y,view)
        key=hit(x,y)
        if key
          return unless @info
          case key
          when :minus;change_count(@layout[:count]-1,view)
          when :plus;change_count(@layout[:count]+1,view)
          when :count
            values=UI.inputbox([l('Liczba półek (0–20)','Shelf count (0–20)')],[@layout[:count]],'ELFIS — Shelves');change_count(values.first,view) if values
          when :equal;change_count(@layout[:count],view)
          when :pattern
            current=@layout[:expression] || @layout[:gaps].map { |v|"#{v.round(4)}mm" }.join(',')
            values=UI.inputbox([l('Od dołu: 300,200,1,1 · mm lub proporcje','From bottom: 300,200,1,1 · mm or weights')],[current],l('Prześwity: 1–9 = proporcje, 10+ = mm','Openings: 1–9 = weights, 10+ = mm'))
            set_layout(@layout[:count],values.first,view) if values
          when :reset;choose(@info[:path]);view.invalidate
          when :apply
            result=ShelfSpacing.apply(@info[:path],@layout);choose(result[:path]);@cache={}
            Sketchup.set_status_text(l("Półki: dodano #{result[:added]}, usunięto #{result[:removed]}; nowe nawierty: #{result[:holes]}.","Shelves: #{result[:added]} added, #{result[:removed]} removed; new drilling: #{result[:holes]}."));view.invalidate
          end
        else
          onMouseMove(flags,x,y,view);choose(@hover) if @hover;view.invalidate
        end
      rescue=>e;@error=e.message;Sketchup.set_status_text(e.message);view.invalidate
      end
      def onMouseWheel(flags,delta,x,y,view)
        return false unless @info && %i[count minus plus].include?(hit(x,y))
        change_count(@layout[:count]+(delta>0 ? 1 : -1),view) unless delta==0;true
      end
      def rect(view,r,fill,border)
        x,y,w,h=r;points=[[x,y,0],[x+w,y,0],[x+w,y+h,0],[x,y+h,0]].map { |q|Geom::Point3d.new(q) }
        view.drawing_color=fill;view.draw2d(GL_QUADS,points);view.drawing_color=border;view.line_width=1;view.draw2d(GL_LINE_LOOP,points)
      end
      def draw(view)
        return unless view.respond_to?(:draw_text)
        text=->(x,y,str,opts={}) { view.draw_text(Geom::Point3d.new(x,y,0),str,{size:11,color:'#264344'}.merge(opts)) }
        inverse=Sketchup.active_model.edit_transform.inverse
        if @info && @layout
          t=@info[:template];world=ShelfSpacing.world(@info[:path],Sketchup.active_model)*t[:tr]
          points=(0..7).map { |i|t[:bb].corner(i).transform(world) };z=points.map(&:z).min
          pairs=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
          @layout[:positions].each_with_index do |position,index|
            shape=@info[:shelves][index];shelf_points=shape ? shape[:points] : points;source_z=shelf_points.map(&:z).min
            view.drawing_color='DodgerBlue';view.line_width=2
            if @info[:corner]
              definition=shape ? shape[:entity].definition : t[:definition]
              tr=shape ? shape[:world] : world
              face=definition.entities.grep(Sketchup::Face).select { |f|f.normal.transform(tr).normalize.dot(Z_AXIS).abs>0.999 }.max_by(&:area)
              contour=face.outer_loop.vertices.map { |v|v.position.transform(tr) }
              # Draw both real L contours, including their rounded inside corner.
              thickness=@layout[:thicknesses][index].mm
              screen=[0,thickness].flat_map do |dz|
                ring=contour.map { |p|q=p.offset(Z_AXIS,position.mm-p.z+dz);v=view.screen_coords(q.transform(inverse));Geom::Point3d.new(v.x,v.y,0) }
                ring.each_with_index.flat_map { |p,i|[p,ring[(i+1)%ring.length]] }
              end
            else
              screen=pairs.flat_map { |a,b|[a,b].map { |i|p=shelf_points[i].offset(Z_AXIS,position.mm-source_z);q=view.screen_coords(p.transform(inverse));Geom::Point3d.new(q.x,q.y,0) } }
            end
            view.draw2d(GL_LINES,screen)
          end
          # Label every clear opening at its actual preview location, even while
          # the pointer is over the panel rather than over a shelf.
          pb=ShelfPins.projected(points,@info[:inverse]);base=@info[:low]
          @layout[:gaps].each_with_index do |gap,i|
            p=Geom::Point3d.new((@info[:left]+@info[:right])/2,pb.min.y,(base+gap/2).mm).transform(@info[:frame]);q=view.screen_coords(p.transform(inverse))
            text.call(q.x,q.y,"#{i+1}: #{gap.round(1)} mm",{bold:true,color:'#176b66',align:TextAlignCenter})
            base+=gap+(@layout[:thicknesses][i]||0)
          end
        end
        view.line_stipple='' if view.respond_to?(:line_stipple=)
        rect(view,[20,20,334,432],'#f5f8f8','#b7cdcc')
        text.call(32,29,l('ELFIS · Rozmieszczenie półek','ELFIS · Arrange shelves'),{size:13,bold:true})
        text.call(32,70,l('Liczba półek','Shelf count'))
        controls.each do |key,(x,y,w,h,label)|
          fill=key==:apply ? '#217b76' : (@hot==key ? '#d9eeec' : '#ffffff')
          rect(view,[x,y,w,h],fill,'#bfd2d1');text.call(x+w/2,y+6,label,{align:TextAlignCenter,bold:true,color:key==:apply ? '#ffffff' : '#264344'})
        end
        text.call(32,207,l('Prześwity od dołu · mm','Clear openings from bottom · mm'),{bold:true})
        if @layout
          @layout[:gaps].each_slice(3).with_index { |items,i|text.call(32,229+i*20,items.each_with_index.map { |v,j|"#{i*3+j+1}: #{v.round(1)}" }.join('   ·   ')) }
          text.call(32,365,l('Odliczono grubość półek i wieńców.','Shelf and rail thicknesses deducted.'),{size:10})
        else;text.call(32,235,l('Kliknij szafkę z półką wzorcową.','Click a cabinet with a template shelf.'));end
        message=@error || l('300,200,1,1 = mm + podział reszty po połowie','300,200,1,1 = mm + equal remaining shares')
        text.call(32,429,message.to_s[0,54],{size:9,color:@error ? '#b02727' : '#526d70'})
      rescue=>e;Sketchup.set_status_text(e.message)
      end
      def onCancel(reason,view);Sketchup.active_model.select_tool(nil) if reason==0;view.invalidate;end
      def deactivate(view);view.invalidate;end
    end
  end
end
