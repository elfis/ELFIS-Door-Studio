# encoding: UTF-8
module Elfis
  # Viewport controls use tool drawing and hit testing, with no model geometry,
  # timers, native windows or dependency on another extension's UI framework.
  module HingeToolPanel
    def panel_settings(path=@path)
      path && !@quick_settings_changed ? HingeDrilling.layout_settings(path,@settings) : @settings
    end
    def panel_controls
      c=panel_settings
      rows={}
      %i[count top bottom].each_with_index do |key,i|
        y=64+i*40
        rows["#{key}_minus".to_sym]=[174,y,30,30,'−',key!=:count || c[:count]>2]
        value=key==:count ? c[key].to_s : "#{format('%.1f',c[key]).sub(/\.0$/,'')} mm"
        rows[key]=[210,y,94,30,value,true]
        rows["#{key}_plus".to_sym]=[310,y,30,30,'+',key!=:count || c[:count]<10]
      end
      %w[Auto Left Right].each_with_index { |side,i|rows[side.downcase.to_sym]=[152+i*64,184,60,30,HingeDrilling.l({'Auto'=>'Auto','Left'=>'Lewa','Right'=>'Prawa'}[side],side),true] }
      rows
    end
    def panel_hit(x,y)
      return nil unless x>=20 && x<=352 && y>=20 && y<=352
      panel_controls.each { |key,(a,b,w,h,_,_)|return key if x>=a && x<=a+w && y>=b && y<=b+h }
      :panel
    end
    def panel_change(values,view)
      candidate=HingeDrilling.validate(panel_settings.merge(values))
      planned=HingeDrilling.plan(@path,candidate) if @path && !@remove
      @settings=candidate;@quick_settings_changed=true;@panel_error=nil
      @plan=planned if planned
      view.invalidate;true
    rescue=>e
      @panel_error=HingeDrilling.l('Ten układ nie mieści się we froncie.','This layout does not fit the front.')
      Sketchup.set_status_text(e.message);view.invalidate;false
    end
    def panel_step(key,delta,view)
      c=panel_settings;value=c[key]+delta
      value=[[value,2].max,10].min if key==:count
      return true if value==c[key]
      panel_change({key=>value},view)
    end
    def panel_click(x,y,view)
      key=panel_hit(x,y);return true if key==:panel || @remove
      if %i[auto left right].include?(key)
        panel_change({side:key.to_s.capitalize},view)
      elsif key.to_s.end_with?('_minus','_plus')
        name,step=key.to_s.split('_');panel_step(name.to_sym,step=='plus' ? 1 : -1,view)
      else
        prompt=case key;when :count;HingeDrilling.l('Liczba zawiasów (2–10)','Hinge count (2–10)');when :top;HingeDrilling.l('Oś od góry frontu [mm]','Axis from front top [mm]');else;HingeDrilling.l('Oś od dołu frontu [mm]','Axis from front bottom [mm]');end
        values=UI.inputbox([prompt],[panel_settings[key]],'ELFIS — Hinges')
        panel_change({key=>values.first},view) if values
      end
      true
    end
    def onMouseWheel(flags,delta,x,y,view)
      hit=panel_hit(x,y)
      if hit
        return true if @remove
        key=case hit.to_s;when /\Atop/;:top;when /\Abottom/;:bottom;else;:count;end
      else
        onMouseMove(flags,x,y,view)
        return false unless @path && !@remove
        key=:count
      end
      panel_step(key,delta>0 ? 1 : -1,view) unless delta==0
      true
    end
    def panel_rect(view,rect,fill,border)
      x,y,w,h=rect;points=[[x,y,0],[x+w,y,0],[x+w,y+h,0],[x,y+h,0]].map { |q|Geom::Point3d.new(q) }
      view.drawing_color=fill;view.draw2d(GL_QUADS,points)
      view.drawing_color=border;view.line_width=1;view.draw2d(GL_LINE_LOOP,points)
    end
    def draw_hinge_panel(view)
      return unless view.respond_to?(:draw_text)
      text=->(x,y,value,opts={}) { view.draw_text(Geom::Point3d.new(x,y,0),value,{size:11,color:'#263c40'}.merge(opts)) }
      view.line_stipple='' if view.respond_to?(:line_stipple=)
      panel_rect(view,[20,20,332,332],'#f5f8f8','#b7cdcc')
      text.call(32,29,HingeDrilling.l('ELFIS · Wiercenia zawiasów','ELFIS · Hinge drilling'),{size:13,bold:true})
      %w[count top bottom].zip([69,109,149]).each do |name,y|
        label={'count'=>HingeDrilling.l('Zawiasy','Hinges'),'top'=>HingeDrilling.l('Oś od góry','Top axis'),'bottom'=>HingeDrilling.l('Oś od dołu','Bottom axis')}[name]
        text.call(32,y,label)
      end
      text.call(32,190,HingeDrilling.l('Strona','Side'))
      panel_controls.each do |key,(x,y,w,h,label,enabled)|
        active=%i[auto left right].include?(key) && panel_settings[:side].downcase==key.to_s
        fill=active ? '#217b76' : (@panel_hover==key && enabled ? '#d9eeec' : '#ffffff')
        panel_rect(view,[x,y,w,h],fill,'#bfd2d1')
        text.call(x+w/2,y+5,label,{align:TextAlignCenter,color:active ? '#ffffff' : (enabled && !@remove ? '#263c40' : '#9caaaa'),bold:true})
      end
      text.call(32,225,HingeDrilling.l('Osie od dołu frontu · mm','Axes from front bottom · mm'),{bold:true})
      if @plan && !@remove
        bottom=@plan[:shelf][:points].map(&:z).min
        cups=@plan[:holes].select { |h|h[:kind]==:cup }.sort_by { |h|h[:point].z }
        cups.each_slice(4).with_index do |items,i|
          text.call(32,246+i*19,items.map { |h|format('%.1f',(h[:point].z-bottom).to_mm).sub(/\.0$/,'') }.join('  ·  '))
        end
        inverse=Sketchup.active_model.edit_transform.inverse
        cups.each_with_index do |h,i|
          q=view.screen_coords(h[:point].transform(inverse))
          text.call(q.x+10,q.y-9,"#{i+1}: #{format('%.1f',(h[:point].z-bottom).to_mm).sub(/\.0$/,'')} mm",{color:'#176b66',bold:true})
        end
      else
        text.call(32,247,HingeDrilling.l('Najedź na front, aby zobaczyć osie.','Hover a front to preview positions.'))
      end
      text.call(32,306,@panel_error || HingeDrilling.l('Kółko / + / −: podgląd · klik frontu: zastosuj','Wheel / + / −: preview · click front: apply'),{size:10,color:@panel_error ? '#b02727' : '#526d70'})
      text.call(32,328,HingeDrilling.l('Alt: usuń · Ctrl: odśwież · Esc: koniec','Alt: remove · Ctrl: refresh · Esc: finish'),{size:10})
    end
  end
end
