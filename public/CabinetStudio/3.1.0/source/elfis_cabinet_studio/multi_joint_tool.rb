# encoding: UTF-8
module ElfisCabinetStudio
  class MultiJointTool
    def initialize
      @settings=Settings.read;@profile=:mixed;@phase=:destinations
      @destinations=[];@references=[];@plans=[];@hover=nil;@shift=false;@error=nil
    end
    def model;Sketchup.active_model;end
    def context;Array(model.active_path);end
    def activate;@context=Geometry.require_edit_context(model);status;model.active_view.invalidate;end
    def same?(a,b);a[:key]==b[:key];end
    def picked(x,y,view)
      ph=view.pick_helper;ph.do_pick(x,y)
      (0...ph.count).each do |i|
        e=ph.path_at(i).reverse.find { |v|Geometry.instance?(v)&&model.active_entities.include?(v) }
        next unless e
        b=Geometry.board(context+[e]);return b if b
      end;nil
    end
    def toggle(list,board,add)
      return list unless board
      add ? (list.any? { |b|same?(b,board) } ? list.reject { |b|same?(b,board) } : list+[board]) : [board]
    end
    def profile_settings
      return @settings unless @profile==:dowels
      @settings.merge(pattern:@settings[:pattern].split.map { |v|v=='-' ? '-' : 'D' }.join(' '))
    end
    def rebuild
      @plans=[];@error=nil;return status if @destinations.empty?||@references.empty?
      mode=@profile==:screws ? :screws : :dowels
      @destinations.each do |destination|
        refs=@references.reject { |r|same?(r,destination) };next if refs.empty?
        refs.each do |reference|
          begin
            @plans<<Geometry.directed_plan(destination,[reference],profile_settings,mode:mode)
          rescue RuntimeError=>e
            next if e.message.include?('nie ma pasującego styku')||e.message.start_with?('Brak styku')
            raise
          end
        end
      end
      raise 'Wybrane panele nie tworzą rzeczywistego styku.' if @plans.empty?
      status
    rescue RuntimeError,ArgumentError=>e;@plans=[];@error=e.message;status;end
    def buttons
      {mixed:[18,48,145,78],dowels:[153,48,280,78],screws:[288,48,415,78],
       phase:[18,88,280,122],confirm:[288,88,415,122],clear:[18,132,415,164]}
    end
    def hit(x,y);buttons.find { |_,r|x.between?(r[0],r[2])&&y.between?(r[1],r[3]) }&.first;end
    def onMouseMove(_flags,x,y,view);@hover=hit(x,y) ? nil : picked(x,y,view);view.invalidate;end
    def onLButtonDown(flags,x,y,view)
      case (button=hit(x,y))
      when :mixed,:dowels,:screws then @profile=button;rebuild
      when :phase then next_phase
      when :confirm then confirm
      when :clear then reset
      else
        board=picked(x,y,view);return unless board
        add=@shift||(flags&CONSTRAIN_MODIFIER_MASK)!=0
        if @phase==:destinations
          raise 'Panel jest już odniesieniem.' if @references.any? { |b|same?(b,board) }
          @destinations=toggle(@destinations,board,add)
        else
          raise 'Panel jest już panelem wierconym.' if @destinations.any? { |b|same?(b,board) }
          @references=toggle(@references,board,add)
        end
        rebuild
      end
      view.invalidate
    rescue RuntimeError=>e;@error=e.message;status;view.invalidate;end
    def next_phase
      raise 'Najpierw wybierz panel wiercony.' if @phase==:destinations&&@destinations.empty?
      @phase=@phase==:destinations ? :references : :destinations;status
    end
    def reset;@destinations=[];@references=[];@plans=[];@phase=:destinations;@error=nil;status;end
    def confirm
      raise 'Brak poprawnego podglądu do zatwierdzenia.' if @plans.empty?
      result=Writer.apply_many(@plans,model);reset
      Sketchup.set_status_text("Dodano #{result[:created]}, istniejące #{result[:existing]}.")
      model.active_view.invalidate
    rescue RuntimeError,ArgumentError=>e;@error=e.message;UI.messagebox(e.message);status;end
    def onKeyDown(key,repeat,_flags,view)
      return false if repeat>1
      if key==CONSTRAIN_MODIFIER_KEY;@shift=true
      elsif key==13;@phase==:destinations ? next_phase : confirm
      else;return false;end
      view.invalidate;true
    end
    def onKeyUp(key,*);return false unless key==CONSTRAIN_MODIFIER_KEY;@shift=false;true;end
    def status
      phase=@phase==:destinations ? 'PANELE WIERCONE' : 'ODNIESIENIA'
      Sketchup.set_status_text(@error||"#{phase} · wiercone #{@destinations.length} · odniesienia #{@references.length} · Shift: dodaj")
    end
    def outline(view,b,color,width)
      return unless b;pairs=[[0,1],[0,2],[1,3],[2,3],[4,5],[4,6],[5,7],[6,7],[0,4],[1,5],[2,6],[3,7]]
      view.drawing_color=color;view.line_width=width;view.draw(GL_LINES,pairs.flat_map { |a,z|[b[:points][a],b[:points][z]] })
    end
    def rect(view,r,color);view.drawing_color=color;view.draw2d(GL_QUADS,[[r[0],r[1],0],[r[2],r[1],0],[r[2],r[3],0],[r[0],r[3],0]]);end
    def draw(view)
      @destinations.each { |b|outline(view,b,'#16a6c9',4) };@references.each { |b|outline(view,b,'#67bd76',3) };outline(view,@hover,'#e5a43c',2)
      @plans.flat_map { |p|p[:holes] }.each do |h|
        n=h[:normal];u=h[:tangent];v=n.cross(u).normalize;r=h[:diameter].mm/2
        pts=Array.new(20) { |i|a=Math::PI*2*i/20;h[:point].offset(u,r*Math.cos(a)).offset(v,r*Math.sin(a)) }
        view.drawing_color=h[:type]==:screw ? '#d84a3a' : '#168fbd';view.line_width=2;view.draw(GL_LINE_LOOP,pts)
      end
      rect(view,[10,10,423,174],'#18232f');view.draw_text([18,18],'ELFIS CABINET STUDIO 3.1',color:'#fff',size:11,bold:true)
      labels={mixed:'Kołki + śruby',dowels:'Kołki',screws:'Śruby',phase:(@phase==:destinations ? 'Dalej: odniesienia' : 'Wróć: wiercone'),confirm:'✓ Zatwierdź',clear:'Wyczyść wybór'}
      buttons.each do |id,r|
        active=(@profile==id)|| (id==:confirm&&!@plans.empty?)
        rect(view,r,active ? '#167c67' : '#314457');view.draw_text([r[0]+8,r[1]+7],labels[id],color:'#fff',size:9)
      end
    end
    def onCancel(reason,view);ElfisCabinetStudio.active_tool=nil;model.select_tool(nil) if reason==0;view.invalidate;end
    def deactivate(view);ElfisCabinetStudio.active_tool=nil;view.invalidate;end
  end
end
