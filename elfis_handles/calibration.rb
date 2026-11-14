# encoding: UTF-8
module Elfis
  module Handles
    def calibration_frame(first,second,plane_point,normal,kind='standard')
      n=Geom::Vector3d.new(normal)
      raise 'Choose a valid contact surface.' unless n.valid?
      n.normalize!
      p1=Geom::Point3d.new(first)
      p2=Geom::Point3d.new(second)
      axis=p2-p1
      # Screw centres may be picked at different depths in their bores.
      axis=axis-n.clone.tap { |v| v.length=axis.dot(n).abs }.tap { |v| v.reverse! if axis.dot(n)<0 } if axis.dot(n).abs>0.0000001
      raise 'Pick two different points along the handle.' if axis.length<0.1.mm
      pitch=axis.length.to_mm
      x=axis.normalize
      y=n.cross(x).normalize
      plane=Geom::Point3d.new(plane_point)
      amount=(plane-p1).dot(n)
      origin=p1.offset(n,amount)
      {mount_frame:Geom::Transformation.axes(origin,x,y,n).to_a,pitch:(kind=='knob' ? 0.0 : pitch),calibrated:true}
    end

    def calibrate(id)
      record=model_record(id)
      raise l('Pochwyty krawędziowe zachowują swoje osie montażowe.','Edge pulls keep their existing mounting axes.') if record[:kind]=='edge'
      raise l('Wyjdź z edycji grupy przed kalibracją.','Exit group editing before calibration.') if Sketchup.active_model.active_path
      Sketchup.active_model.select_tool(CalibrationTool.new(record))
    end

    class CalibrationTool
      def initialize(record)
        @record=record;@points=[];@flip=false;@done=false
      end
      def activate
        Handles.instance_variable_set(:@calibrating,true)
        @model=Sketchup.active_model;@view=@model.active_view
        original=@view.camera
        @camera=Sketchup::Camera.new(original.eye,original.target,original.up,original.perspective?)
        @camera.fov=original.fov if original.perspective?
        @camera.height=original.height unless original.perspective?
        @selection=@model.selection.to_a
        @definition=Handles.definition(@model,@record)
        @model.start_operation('ELFIS — Mounting calibration',true)
        @operation=true
        Handles.instance_variable_get(:@dialog)&.execute_script('calibrationState(true)')
        # Only this temporary occurrence is touched. Abort removes it on exit.
        bounds=@model.bounds
        distance=bounds.valid? ? bounds.diagonal+1000.mm : 1000.mm
        centre=bounds.valid? ? bounds.center : ORIGIN
        target=centre.offset(@camera.direction.reverse,distance)
        offset=target-@definition.bounds.center
        @sample=@model.entities.add_instance(@definition,Geom::Transformation.translation(offset))
        @sample.name='ELFIS — mounting calibration preview'
        @view.zoom(@sample)
        @ip=Sketchup::InputPoint.new
        hint
      rescue => error
        finish
        UI.messagebox(error.message)
      end
      def hint
        text=case @points.length
        when 0 then Handles.l('Kalibracja: wskaż środek pierwszej śruby. Esc anuluje.','Calibration: pick the first screw centre. Esc cancels.')
        when 1 then @record[:kind]=='knob' ? Handles.l('Wskaż drugi punkt wyznaczający kierunek czerwonej osi.','Pick a second point defining the red-axis direction.') : Handles.l('Wskaż środek drugiej śruby.','Pick the second screw centre.')
        else Handles.l('Kliknij powierzchnię styku z frontem. Tab odwraca niebieską oś.','Click the surface touching the door. Tab reverses the blue axis.')
        end
        Sketchup.set_status_text(text);Handles.refresh(text)
      end
      def own_pick?(view,x,y)
        helper=view.pick_helper;helper.do_pick(x,y)
        (0...helper.count).any? { |i| helper.path_at(i).include?(@sample) }
      end
      def onMouseMove(flags,x,y,view)
        @ip.pick(view,x,y)
        view.tooltip=@ip.tooltip if @ip.valid?
        view.invalidate
      end
      def draw(view)
        @ip.draw(view) if @ip && @ip.valid? && @ip.display?
        return if @points.empty?
        view.drawing_color=Sketchup::Color.new(240,145,20)
        world=@points.map { |p| p.transform(@sample.transformation) }
        view.draw_points(world,10,2,Sketchup::Color.new(240,145,20))
        view.draw(GL_LINES,world) if world.length==2
        if @points.length==2 && @ip && @ip.valid? && @ip.face
          n=@ip.face.normal.transform(@ip.transformation).reverse
          n.reverse! if @flip
          view.drawing_color=Sketchup::Color.new(40,100,230);view.line_width=3
          view.draw(GL_LINES,[@ip.position,@ip.position.offset(n,25.mm)])
        end
      end
      def onLButtonDown(flags,x,y,view)
        raise 'Pick a point on the temporary handle model.' unless own_pick?(view,x,y)
        @ip.pick(view,x,y)
        raise 'Choose a snapping point or a contact face.' unless @ip.valid?
        inverse=@sample.transformation.inverse
        point=@ip.position.transform(inverse)
        if @points.length<2
          raise 'The points must be different.' if @points.first && @points.first.distance(point)<0.1.mm
          @points<<point;hint;view.invalidate;return
        end
        face=@ip.face
        raise 'Click a flat face touching the door.' unless face
        # The exterior normal of a correctly oriented contact face points
        # towards the door; mounting blue points from the door into the handle.
        normal=face.normal.transform(@ip.transformation).transform(inverse).reverse
        normal.reverse! if @flip
        update=Handles.calibration_frame(@points[0],@points[1],point,normal,@record[:kind])
        candidate=@record.merge(update)
        candidate[:length]=Handles.geometry_length(@definition,candidate) unless @record[:length_auto]==false
        finish
        @record.replace(candidate);Handles.persist
        Handles.refresh(Handles.l("Kalibracja zapisana. Rozstaw: #{update[:pitch].round(2)} mm.","Calibration saved. Pitch: #{update[:pitch].round(2)} mm."))
        Sketchup.active_model.select_tool(nil)
      rescue => error
        UI.messagebox(error.message)
      end
      def onKeyDown(key,repeat,flags,view)
        if key==9
          @flip=!@flip
          Sketchup.set_status_text(@flip ? 'Blue axis reversed. Click the contact face.' : 'Default blue axis. Click the contact face.')
          view.invalidate
          return true
        end
      end
      def onCancel(reason,view)
        finish;Sketchup.active_model.select_tool(nil)
        Handles.refresh(Handles.l('Kalibracja anulowana.','Calibration cancelled.'))
      end
      def finish
        return if @done
        @done=true
        Handles.instance_variable_set(:@calibrating,false)
        Handles.instance_variable_get(:@dialog)&.execute_script('calibrationState(false)')
        @model.abort_operation if @operation
        @view.camera=@camera if @view && @camera
        if @model && @selection
          @model.selection.clear;@model.selection.add(@selection.select(&:valid?))
        end
      end
      def deactivate(view)
        finish;view.invalidate
      end
    end
  end
end
