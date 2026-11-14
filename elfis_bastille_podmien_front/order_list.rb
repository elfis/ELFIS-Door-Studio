# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    # A viewport overlay can identify nested occurrences without entering their
    # edit contexts, changing the current tool or selecting sibling copies.
    class OrderFrontOverlay < Sketchup::Overlay
      BOX_EDGES=[[0,1],[1,3],[3,2],[2,0],[4,5],[5,7],[7,6],[6,4],[0,4],[1,5],[2,6],[3,7]].freeze unless const_defined?(:BOX_EDGES)

      def initialize
        super('elfis.door_order_highlight','ELFIS — Podgląd frontów z listy')
        @targets=[]
        @show_dimensions=true
      end

      attr_accessor :show_dimensions

      def targets=(targets)
        @targets=targets
      end

      def valid_target?(target)
        path=target[:path]
        path.all?(&:valid?) && target[:model].valid? &&
          target[:model].entities.include?(path.first) &&
          path.each_cons(2).all? { |parent,child| parent.definition.entities.include?(child) }
      end

      def boxes
        @targets.filter_map do |target|
          next unless valid_target?(target)
          world=target[:path].inject(IDENTITY) { |tr,entity| tr*entity.transformation }
          (0..7).map { |i| target[:bounds].corner(i).transform(world) }
        end
      end

      def dimension_labels(view)
        return [] unless @show_dimensions
        labels=[]
        options={font:'Segoe UI',pixel_size:14,bold:true,align:TextAlignCenter,vertical_align:TextVerticalAlignCenter,color:Sketchup::Color.new(20,64,76)}
        @targets.each do |target|
          next unless target[:label] && valid_target?(target)
          bounds=target[:bounds]
          lengths=[bounds.width,bounds.height,bounds.depth]
          depth=lengths.each_index.min_by { |i| lengths[i] }
          center=bounds.center.to_a;center[depth]=bounds.max.to_a[depth]
          world=target[:path].inject(IDENTITY) { |tr,entity| tr*entity.transformation }
          point=Geom::Point3d.new(center).transform(world)
          next unless (point-view.camera.eye).dot(view.camera.direction)>0
          screen=view.screen_coords(point)
          next unless screen.x.between?(0,view.vpwidth) && screen.y.between?(0,view.vpheight)
          anchor=Geom::Point3d.new(screen.x,screen.y,0)
          text_bounds=view.text_bounds(anchor,target[:label],options)
          left,top=text_bounds.upper_left.to_a;right,bottom=text_bounds.lower_right.to_a
          rectangle=[left-7,top-4,right+7,bottom+4]
          next if labels.any? { |label| a=label[:rect];rectangle[0]<a[2] && rectangle[2]>a[0] && rectangle[1]<a[3] && rectangle[3]>a[1] }
          labels<<{point:anchor,text:target[:label],rect:rectangle,options:options}
          break if labels.length>=200
        end
        labels
      end

      def getExtents
        bounds=Geom::BoundingBox.new
        boxes.each { |points| bounds.add(points) }
        bounds
      end

      def draw(view)
        lines=[]
        boxes.each do |points|
          # Overlay callbacks project model coordinates, unlike a Tool drawing
          # in the active edit context. The instance path already includes all
          # ancestor transforms; applying edit_transform again offsets boxes.
          screen=points.map { |point| view.screen_coords(point) }
          BOX_EDGES.each do |a,b|
            next unless screen[a] && screen[b]
            lines<<Geom::Point3d.new(screen[a].x,screen[a].y,0)<<Geom::Point3d.new(screen[b].x,screen[b].y,0)
          end
        end
        return if lines.empty?
        view.drawing_color=Sketchup::Color.new(0,155,235)
        view.line_width=4
        view.line_stipple=''
        view.draw2d(GL_LINES,lines)
        if view.respond_to?(:draw_text)
          dimension_labels(view).each do |label|
            left,top,right,bottom=label[:rect]
            rectangle=[[left,top,0],[right,top,0],[right,bottom,0],[left,bottom,0]].map { |point| Geom::Point3d.new(point) }
            view.drawing_color=Sketchup::Color.new(255,255,255,240)
            view.draw2d(GL_QUADS,rectangle)
            view.drawing_color=Sketchup::Color.new(0,130,170)
            view.line_width=1
            view.draw2d(GL_LINE_LOOP,rectangle)
            view.draw_text(label[:point],label[:text],label[:options])
          end
        end
      end
    end

    # A temporary preview tool receives Escape in the viewport. Orbit remains
    # available; switching to a different tool also clears this preview.
    class OrderHighlightTool
      def onCancel(reason,view)
        Elfis::BastillePodmienFront.clear_order_highlight if reason==0 || reason==2
      end
      def deactivate(view)
        Elfis::BastillePodmienFront.clear_order_highlight(false)
      end
    end

    def order_door?(entity)
      entity.get_attribute('ElfisBastillePodmien','generated',false) ||
        (entity.definition.get_attribute('ElfisDrzwi','width_mm') && entity.definition.get_attribute('ElfisDrzwi','height_mm'))
    end

    def order_profile_info(door)
      id=door.get_attribute('ElfisBastillePodmien','profile_id')
      stored=library[:profiles].find { |p| p[:id]==id }
      kind=door.get_attribute('ElfisBastillePodmien','kind') || stored&.dig(:kind) || 'shaker'
      type={'shaker'=>'Five-Piece Door','onepiece'=>'One-Piece Door','slab'=>'Slab Door','jpull'=>'J-Pull Door','drawer_section'=>'Profil szuflady'}[kind] || 'Nieznany typ'
      name=door.get_attribute('ElfisBastillePodmien','profile_name') || stored&.dig(:name)
      variant=door.get_attribute('ElfisBastillePodmien','variant','standard')
      type="Drawer · #{type}" if variant=='drawer'
      chamfer=door.get_attribute('ElfisBastillePodmien','front_chamfer_mm',0).to_f
      type+=l(" · Faza #{door_dimension_label(chamfer)} mm"," · Chamfer #{door_dimension_label(chamfer)} mm") if kind=='slab' && chamfer>0
      name=door.get_attribute('ElfisBastillePodmien','family_name') || name
      edge=kind=='jpull' ? door.get_attribute('ElfisBastillePodmien','handle_edge','top') : nil
      {id:id || "legacy:#{door.definition.get_attribute('ElfisDrzwi','profile_width_mm')}",name:name || 'Profil nierozpoznany',type:type,
       supplier:supplier_name(stored&.dig(:supplier) || door.get_attribute('ElfisBastillePodmien','supplier')),variant:variant,signature:door.get_attribute('ElfisBastillePodmien','profile_geometry'),edge:edge,
       edge_label:{'top'=>'Góra','bottom'=>'Dół','left'=>'Lewa','right'=>'Prawa'}[edge] || '—',unknown:name.nil?}
    end

    # Ordinary fronts commonly contain drilling vectors. Measure only their
    # panel faces, never the bounds of those auxiliary containers.
    def order_external_bounds(door)
      bounds=Geom::BoundingBox.new
      door.definition.entities.grep(Sketchup::Face).each { |face| face.vertices.each { |v| bounds.add(v.position) } }
      bounds.valid? && [bounds.width,bounds.height,bounds.depth].all? { |n| n>0.000001 } ? bounds : nil
    end

    def order_tag_key(name)
      name.to_s.downcase.gsub(/[\s_-]+/,'').sub(/\A\d+/,'')
    end

    def order_endpanel_tag?(name)
      order_tag_key(name)=='endpanels'
    end

    def order_finishing_tag?(layer)
      return true if order_endpanel_tag?(layer.name) || %w[finishing finishingparts].include?(order_tag_key(layer.name))
      folder=layer.respond_to?(:folder) ? layer.folder : nil
      while folder
        return true if %w[finishing finishingparts].include?(order_tag_key(folder.name))
        folder=folder.folder
      end
      false
    end

    def order_dimensions?
      @order_show_dimensions=Sketchup.read_default('ELFIS Door Profile Library','order_dimensions',true) if @order_show_dimensions.nil?
      @order_show_dimensions
    end

    def order_panel_bounds(door,stack={})
      direct=order_external_bounds(door)
      return direct if direct
      return nil if stack[door.definition] || stack.length>32
      bounds=Geom::BoundingBox.new
      door.definition.entities.each do |child|
        next unless instance?(child)
        child_bounds=order_panel_bounds(child,stack.merge(door.definition=>true))
        next unless child_bounds
        8.times { |i| bounds.add(child_bounds.corner(i).transform(child.transformation)) }
      end
      bounds.valid? && [bounds.width,bounds.height,bounds.depth].all? { |n| n>0.000001 } ? bounds : nil
    end

    def order_colours(door,inherited,external=false,panel=false)
      counts={}
      bounds=door_bounds(door)
      depth_axis=[bounds.width,bounds.height,bounds.depth].each_with_index.min_by { |length,index| length }[1]
      front_axis=[X_AXIS,Y_AXIS,Z_AXIS][depth_axis]
      walk=nil
      walk=->(entities,tr,material,stack) do
        entities.each do |e|
          if e.is_a?(Sketchup::Face)
            # Generated doors use local +Y as the front. Rear CNC geometry is
            # excluded by entering only the door's own geometry containers.
            next unless external || e.normal.transform(tr).dot(front_axis)>0.000001
            mat=e.material || material
            counts[mat]=true
          elsif (!external || panel) && instance?(e) && !stack[e.definition]
            next if !external && entities==door.definition.entities && door.get_attribute('ElfisBastillePodmien','generated',false) && !own_geometry?(e,door)
            next if panel && !order_panel_bounds(e)
            walk.call(e.definition.entities,tr*e.transformation,e.material || material,stack.merge(e.definition=>true))
          end
        end
      end
      material=door.material || inherited
      geometry=door.definition.entities.select { |e| instance?(e) && own_geometry?(e,door) }
      if external || geometry.empty?
        walk.call(door.definition.entities,IDENTITY,material,{door.definition=>true})
      else
        geometry.each { |g| walk.call(g.definition.entities,g.transformation,g.material || material,{g.definition=>true}) }
      end
      counts[material]=true if counts.empty?
      counts.keys.map do |mat|
        if mat
          c=mat.color
          {key:mat.name,name:mat.display_name,hex:format('#%02x%02x%02x',c.red,c.green,c.blue),alpha:mat.alpha}
        else
          {key:nil,name:'Brak przypisanego materiału',hex:nil,alpha:1.0}
        end
      end.sort_by { |c| [c[:name].downcase,c[:key].to_s] }
    end

    # Read mounted records, not the handle library: orders also work on another
    # computer without ELFIS Handles installed, and retain the fitted product.
    def collect_order_handles(model,include_hidden=false,warnings=[])
      rows={};visited=0
      walk=nil
      walk=->(entities,path,stack) do
        entities.each do |entity|
          next unless instance?(entity)
          visited+=1
          raise l('Zbyt wiele elementów w zestawieniu uchwytów.','Too many elements in the handle order.') if visited>1_000_000 || path.length>256
          current=path+[entity]
          next if !include_hidden && (entity.hidden? || !entity.layer.visible? || !model.drawing_element_visible?(current))
          if entity.get_attribute('ElfisHandles','handle',false)
            begin
              raw=JSON.parse(entity.get_attribute('ElfisHandles','record'),symbolize_names:true)
              raise l('Niepełny opis uchwytu.','Incomplete handle record.') unless raw.is_a?(Hash) && !raw[:name].to_s.strip.empty?
              record=raw.slice(:id,:name,:kind,:pitch,:length,:finish,:supplier,:code)
              key=JSON.generate(record.sort_by { |k,_| k.to_s })
              row=rows[key] ||= record.merge(quantity:0)
              row[:quantity]+=1
            rescue => error
              warnings<<l("Uchwyt #{entity.name}: #{error.message}","Handle #{entity.name}: #{error.message}")
            end
            # A handle SKP can contain nested components. Count the fitted
            # assembly once, regardless of how its geometry was authored.
            next
          end
          next if stack[entity.definition]
          walk.call(entity.definition.entities,current,stack.merge(entity.definition=>true))
        end
      end
      walk.call(model.entities,[],{})
      rows.values.sort_by { |r| [r[:name].to_s.downcase,r[:finish].to_s.downcase,r[:code].to_s] }
    end

    def collect_order_list(model=Sketchup.active_model,include_hidden=false,include_facade=false,include_endpanels=false,include_handles=true)
      rows={};warnings=[];children={};colours={};measures={};profiles={};visited=0
      walk=nil
      walk=->(entities,tr,inherited,path,stack) do
        nodes=children[entities] ||= entities.select { |e| instance?(e) }
        nodes.each do |entity|
          visited+=1
          raise Elfis::BastillePodmienFront.l('Model zawiera zbyt wiele zagnieżdżeń do zestawienia.','The model contains too many nested elements to list.') if path.length>256 || visited>1_000_000
          unless include_hidden
            next if entity.hidden? || !entity.layer.visible?
          end
          world=tr*entity.transformation
          node_path=path+[entity]
          panel=order_finishing_tag?(entity.layer)
          next if panel && !include_endpanels
          generated=!panel && order_door?(entity)
          external=panel || (!generated && include_facade && entity.layer.name.casecmp('Facade').zero?)
          external_bounds=external ? (measures[[entity.definition,panel ? :panel : :external]] ||= (panel ? order_panel_bounds(entity) : order_external_bounds(entity))) : nil
          if generated || (external && external_bounds)
            begin
              next if !include_hidden && !model.drawing_element_visible?(node_path)
              bounds=external ? external_bounds : (measures[entity.definition] ||= door_bounds(entity))
              origin=ORIGIN.transform(world)
              scales=[[1,0,0],[0,1,0],[0,0,1]].map { |axis| Geom::Point3d.new(axis).transform(world)-origin }
              raise Elfis::BastillePodmienFront.l('Zerowa skala frontu.','The front has zero scale.') unless scales.all? { |v| v.length>0.000001 }
              raise Elfis::BastillePodmienFront.l('Front jest ukośnie zdeformowany.','The front is sheared.') unless [[0,1],[0,2],[1,2]].all? { |a,b| scales[a].normalize.dot(scales[b].normalize).abs<0.0001 }
              w,t,h=[bounds.width,bounds.height,bounds.depth].zip(scales).map { |length,axis| (length*axis.length).to_mm.round(2) }
              # Native OCL axes can place height/width/thickness on any axis.
              lengths=[w,t,h]
              thickness_axis=lengths.each_index.min_by { |i| lengths[i] }
              face_axes=[0,1,2]-[thickness_axis]
              height_axis=face_axes.max_by { |i| scales[i].normalize.z.abs }
              width_axis=(face_axes-[height_axis]).first
              w,t,h=lengths[width_axis],lengths[thickness_axis],lengths[height_axis]
              raise Elfis::BastillePodmienFront.l('Nieprawidłowe wymiary frontu.','Invalid front dimensions.') unless [w,t,h].all? { |n| n.finite? && n>0 }
              info=profiles[entity] ||= if external
                label=entity.name.empty? ? entity.definition.name : entity.name
                {id:"external:#{entity.definition.guid}",name:label.empty? ? (panel ? 'Finishing' : 'Front z tagu Facade') : label,type:panel ? entity.layer.name : 'Typ nieokreślony',edge_label:'—',unknown:!panel}
              else
                order_profile_info(entity)
              end
              material=entity.material || inherited
              paint=colours[[entity.definition,material,external,panel]] ||= order_colours(entity,inherited,external,panel)
              supplier=external ? supplier_name(entity.get_attribute('ElfisBastillePodmien','supplier'),panel ? 'ELFIS' : 'Facade') : info[:supplier]
              key=JSON.generate([info[:id],info[:name],info[:type],info[:signature],info[:edge],w,t,h,paint,supplier,external,panel,panel ? order_product_group(entity.layer) : nil,panel ? (entity.get_attribute('ElfisBastillePodmien','stock_product') || entity.layer.name) : nil])
              row=rows[key] ||= {stock_product:panel ? (entity.get_attribute('ElfisBastillePodmien','stock_product') || entity.layer.name) : nil,product_group:panel ? order_product_group(entity.layer) : 'fronts',section:panel ? 'endpanels' : 'fronts',profile:info[:name],type:info[:type],height:h,width:w,thickness:t,quantity:0,colours:paint,handle:info[:edge_label],external:external,source:supplier,supplier:supplier,review:info[:unknown] || paint.length>1 || paint.any? { |c| c[:key].nil? }}
              row[:quantity]+=1
              yield(row,node_path,bounds) if block_given?
            rescue => error
              label=entity.name.empty? ? entity.definition.name : entity.name
              warnings<<"#{label}: #{error.message}"
            end
          elsif !stack[entity.definition]
            if external
              label=entity.name.empty? ? entity.definition.name : entity.name
                warnings<<l("#{label}: tag #{panel ? 'Finishing' : 'Facade'}, ale nie rozpoznano bryły płyty. Sprawdź element osobno; przeszukano elementy wewnątrz.","#{label}: tag #{panel ? 'Finishing' : 'Facade'}, but no panel solid was recognised. Review separately; nested elements were searched.")
            end
            walk.call(entity.definition.entities,world,entity.material || inherited,node_path,stack.merge(entity.definition=>true))
          end
        end
      end
      walk.call(model.entities,IDENTITY,nil,[],{})
      list=rows.values.sort_by { |r| [r[:profile].downcase,r[:colours].map { |c| c[:name] }.join.downcase,r[:height],r[:width],r[:thickness],r[:handle]] }
      list.each_with_index { |row,index| row[:id]=index }
      handles=include_handles ? collect_order_handles(model,include_hidden,warnings) : []
      {sort:order_sort_settings,model:model.title.empty? ? 'Bez nazwy' : model.title,rows:list,total:list.sum { |r| r[:quantity] },handles:handles,include_handles:include_handles,include_hidden:include_hidden,include_facade:include_facade,include_endpanels:include_endpanels,endpanels_present:model.layers.any? { |layer| order_finishing_tag?(layer) },show_dimensions:order_dimensions?,facade_present:model.layers.any? { |layer| layer.name.casecmp('Facade').zero? },warnings:warnings,review_count:list.count { |r| r[:review] }}
    end

    def order_text_cell(value)
      text=value.to_s.gsub(/[\t\r\n]+/,' ')
      text="'#{text}" if text.lstrip.match?(/\A[=+\-@]/)
      text
    end

    def order_list_text(data)
      heading=[l('Profil / element','Profile / item'),l('Typ','Type'),l('Ilość','Qty'),l('Wysokość [mm]','Height [mm]'),l('Szerokość [mm]','Width [mm]'),l('Grubość [mm]','Thickness [mm]'),l('Kolor / materiał','Colour / material'),l('Uchwyt','Handle'),l('Źródło','Source')].join("\t")
      lines=[]
      (['fronts']+FINISHING_GROUPS).each do |group|
        subset=sorted_order_rows(data[:rows].select { |r| order_group(r)==group })
        next if subset.empty?
        lines<<'' unless lines.empty?
        lines<<order_group_label(group)
        if group=='plinths'
          stock=order_stock_plan(subset)
          lines<<l('Pełne listwy','Whole stock lengths')+" (#{stock[:settings][:length]} mm; "+l('rzaz','kerf')+" #{stock[:settings][:kerf]} mm)"
          stock[:groups].each do |g|
            lines<<[g[:product],g[:quantity],stock[:settings][:length],g[:colours].map { |c| c[:name] }.join(' / '),g[:source]].map { |v| order_text_cell(v) }.join("\t")
            g[:bars].each_with_index do |bar,i|
              lines<<"  #{i+1}: "+bar[:parts].map { |p| "#{p[:length]} × #{p[:section]}" }.join(' + ')+" mm; "+l('odpad','waste')+" #{bar[:waste]} mm; "+l('rzaz','cutting loss')+" #{bar[:cutting_loss]} mm"
            end
            g[:oversize].each { |p| lines<<l('ZA DŁUGI ODCINEK: ','OVERSIZE PART: ')+p[:length].to_s+' mm' }
          end
        else
          lines<<heading
          subset.each do |r|
            values=[r[:profile],ui_label(r[:type]),r[:quantity],door_dimension_label(r[:height]),door_dimension_label(r[:width]),door_dimension_label(r[:thickness]),r[:colours].map { |c| c[:key].nil? ? ui_label(c[:name]) : c[:name] }.join(' / '),ui_label(r[:handle]),r[:source]]
            lines<<values.map { |v| order_text_cell(v) }.join("\t")
          end
        end
      end
      unless Array(data[:handles]).empty?
        lines<<'' unless lines.empty?
        lines<<l('UCHWYTY','HANDLES')
        lines<<[l('Model','Model'),l('Rodzaj','Type'),l('Ilość','Quantity'),l('Rozstaw [mm]','Pitch [mm]'),l('Długość [mm]','Length [mm]'),l('Wykończenie','Finish'),l('Producent / dostawca','Manufacturer / supplier'),l('Kod produktu','Product code')].join("\t")
        data[:handles].each do |row|
          kind={'standard'=>l('Standardowy','Standard'),'edge'=>l('Krawędziowy','Edge pull'),'knob'=>l('Gałka','Knob')}.fetch(row[:kind],row[:kind])
          lines<<[row[:name],kind,row[:quantity],row[:pitch],row[:length],row[:finish],row[:supplier],row[:code]].map { |v| order_text_cell(v) }.join("\t")
        end
      end
      if data[:review_count]>0
        lines<<''<<ui_label('UWAGA: sprawdź fronty spoza ELFIS oraz pozycje z nierozpoznanym profilem, brakiem materiału lub wieloma materiałami.')
      end
      unless data[:warnings].empty?
        lines<<''<<ui_label('POMINIĘTE FRONTY — wymagają sprawdzenia:')
        data[:warnings].each { |message| lines<<order_text_cell(message) }
      end
      lines.join("\r\n")
    end

    def refresh_order_list
      clear_order_highlight
      model=Sketchup.active_model
      targets={}
      data=collect_order_list(model,@order_include_hidden==true,@order_include_facade==true,@order_include_endpanels!=false,@order_include_handles!=false) do |row,path,bounds|
        (targets[row.object_id] ||= [])<<{model:model,path:path,bounds:bounds,label:"#{door_dimension_label(row[:height])} × #{door_dimension_label(row[:width])} mm"}
      end
      @order_revision=(@order_revision || 0)+1
      data[:revision]=@order_revision
      data[:sort]=order_sort_settings
      data[:profiles]=visible_profiles.map { |p| {id:p[:id],name:p[:name],kind:p[:kind],supplier:supplier_name(p[:supplier])} }
      by_id=data[:rows].to_h { |row| [row[:id],targets[row.object_id] || []] }
      occurrence_id=-1
      data[:rows].each do |row|
        row[:occurrence_ids]=by_id[row[:id]].map do |target|
          id=occurrence_id;occurrence_id-=1;by_id[id]=[target];id
        end
      end
      data[:stock]=order_stock_plan(data[:rows])
      @order_snapshot={model:model,data:data,targets:by_id}
      @order_dialog.execute_script("renderOrderList(#{JSON.generate(data)})") if @order_dialog
      data
    end

    def clear_order_highlight(release_tool=true)
      if @order_overlay
        @order_overlay.targets=[]
        @order_overlay_model.active_view.invalidate if @order_overlay_model&.valid?
      end
      if release_tool && @order_highlight_tool
        tool=@order_highlight_tool;@order_highlight_tool=nil
        @order_highlight_model.tools.pop_tool if @order_highlight_model&.valid? && @order_highlight_model.tools.active_tool.equal?(tool)
      end
      @order_dialog.execute_script('setOrderHighlighted(null,0)') if @order_dialog
    end

    def highlight_order_row(id,revision)
      snapshot=@order_snapshot
      raise Elfis::BastillePodmienFront.l('Lista jest nieaktualna. Kliknij „Odśwież listę”.','The list is out of date. Click Refresh list.') unless snapshot && snapshot[:model]==Sketchup.active_model && snapshot[:data][:revision]==revision
      ids=Array(id).uniq
      raise Elfis::BastillePodmienFront.l('Nie znaleziono pozycji. Odśwież listę.','Item not found. Refresh the list.') unless ids.all? { |key| snapshot[:targets]&.key?(key) }
      if ids.empty?
        clear_order_highlight
        return 0
      end
      targets=ids.flat_map { |key| snapshot[:targets][key] }
      model=snapshot[:model]
      # Native overlays are permanently invalid after removal (including
      # undoing their registration). A Ruby reference alone is insufficient.
      registered=@order_overlay_model==model && @order_overlay && @order_overlay.valid? && model.overlays.any? { |item| item.equal?(@order_overlay) }
      unless registered
        clear_order_highlight
        @order_overlay=model.overlays.find { |item| item.valid? && item.overlay_id=='elfis.door_order_highlight' }
        unless @order_overlay
          @order_overlay=OrderFrontOverlay.new
          model.overlays.add(@order_overlay)
        end
        @order_overlay_model=model
      end
      unless targets.all? { |target| @order_overlay.valid_target?(target) }
        clear_order_highlight
        raise Elfis::BastillePodmienFront.l('Fronty zmieniły się w modelu. Odśwież listę przed podglądem.','The fronts have changed. Refresh the list before highlighting.')
      end
      @order_overlay.show_dimensions=order_dimensions?
      @order_overlay.targets=targets
      unless @order_highlight_tool && @order_highlight_model==model && model.tools.active_tool.equal?(@order_highlight_tool)
        @order_highlight_tool=OrderHighlightTool.new;@order_highlight_model=model
        model.tools.push_tool(@order_highlight_tool)
      end
      @order_overlay.enabled=true
      model.active_view.invalidate
      @order_dialog.execute_script("setOrderHighlighted(#{JSON.generate(ids)},#{targets.length})") if @order_dialog
      targets.length
    end

    def zoom_order_rows(ids,revision)
      count=highlight_order_row(ids,revision)
      raise Elfis::BastillePodmienFront.l('Wybierz fronty do przybliżenia.','Select fronts to zoom to.') if count==0
      bounds=@order_overlay.getExtents
      raise Elfis::BastillePodmienFront.l('Brak geometrii do przybliżenia.','No geometry to zoom to.') unless bounds.valid?
      view=@order_snapshot[:model].active_view
      old=view.camera
      forward=old.direction.normalize
      right=forward.cross(old.up).normalize
      up=right.cross(forward).normalize
      center=bounds.center
      points=@order_overlay.boxes.flatten(1)
      aspect=old.aspect_ratio>0 ? old.aspect_ratio : view.vpwidth.to_f/view.vpheight
      vectors=points.map { |point| point-center }
      if old.perspective?
        tangent=Math.tan(old.fov.degrees/2.0)
        tan_y=old.fov_is_height? ? tangent : tangent/aspect
        tan_x=tan_y*aspect
        distance=vectors.map { |v| [v.dot(right).abs*1.15/tan_x-v.dot(forward),v.dot(up).abs*1.15/tan_y-v.dot(forward)].max }.max
        distance=[distance,bounds.diagonal*0.05,1.mm].max
      else
        distance=[old.eye.distance(old.target),bounds.diagonal,1.mm].max
      end
      offset=forward.reverse;offset.length=distance
      camera=Sketchup::Camera.new(center+offset,center,up,old.perspective?)
      camera.aspect_ratio=old.aspect_ratio
      if old.perspective?
        camera.fov=(2*Math.atan(camera.fov_is_height? ? tan_y : tan_x)).radians
      else
        camera.height=[vectors.map { |v| v.dot(up).abs }.max*2,vectors.map { |v| v.dot(right).abs }.max*2/aspect,1.mm].max*1.15
      end
      view.camera=camera
      count
    end

    def copy_order_list(ids=nil,revision=nil,include_handles=true)
      refresh_order_list unless @order_snapshot && @order_snapshot[:model]==Sketchup.active_model
      data=@order_snapshot[:data]
      if ids
        raise Elfis::BastillePodmienFront.l('Lista jest nieaktualna. Odśwież ją przed kopiowaniem.','The list is out of date. Refresh before copying.') unless data[:revision]==revision
        keys=Array(ids).uniq
        raise Elfis::BastillePodmienFront.l('Nie znaleziono pozycji do skopiowania.','No items found to copy.') unless keys.all? { |key| @order_snapshot[:targets].key?(key) }
        chosen_rows=data[:rows].select { |row| keys.include?(row[:id]) }
        data=data.merge(rows:chosen_rows,review_count:chosen_rows.count { |row| row[:review] })
      end
      data=data.merge(handles:[]) unless include_handles
      raise Elfis::BastillePodmienFront.l('Lista jest pusta. Nie skopiowano danych.','The list is empty. Nothing was copied.') if data[:rows].empty? && Array(data[:handles]).empty?
      raise Elfis::BastillePodmienFront.l('Nie udało się zapisać tekstu w schowku.','Could not write text to the clipboard.') unless UI.set_clipboard_data(order_list_text(data))
      @order_dialog.execute_script("setOrderStatus(#{JSON.generate(ui_label('Skopiowano tabelę do schowka. Możesz wkleić ją do Excela lub wiadomości.'))})") if @order_dialog
      true
    end

    def replace_order_row(id,revision,profile_id,handle_edge='preserve',variant_mode='auto',supplier_only:nil)
      snapshot=@order_snapshot
      raise Elfis::BastillePodmienFront.l('Lista jest nieaktualna. Odśwież ją przed podmianą.','The list is out of date. Refresh before replacement.') unless snapshot && snapshot[:model]==Sketchup.active_model && snapshot[:data][:revision]==revision
      ids=Array(id).uniq
      rows=ids.map { |key| snapshot[:data][:rows].find { |item| item[:id]==key } }
      raise Elfis::BastillePodmienFront.l('Wybierz pozycje z listy.','Select list items.') if rows.empty? || rows.any?(&:nil?)
      raise Elfis::BastillePodmienFront.l('Finishing to oddzielne produkty do zamówienia. Wybierz wyłącznie fronty do podmiany profilu.','Finishing items are separate order products. Select only fronts for door-profile replacement.') if !supplier_only && rows.any? { |row| row[:section]=='endpanels' }
      targets=rows.flat_map do |row|
        items=snapshot[:targets]&.fetch(row[:id],nil)
        raise Elfis::BastillePodmienFront.l('Nie znaleziono pozycji. Odśwież listę.','Item not found. Refresh the list.') unless items && !items.empty?
        items.map { |target| target.merge(order_row:row) }
      end
      p=supplier_only ? {name:supplier_only} : visible_profiles.find { |item| item[:id]==profile_id }
      raise Elfis::BastillePodmienFront.l('Wybierz profil docelowy z biblioteki.','Choose a target profile from the library.') unless p
      p=p.dup
      if p[:kind]=='jpull'
        raise Elfis::BastillePodmienFront.l('Nieprawidłowa strona uchwytu.','Invalid handle edge.') unless %w[preserve top bottom left right].include?(handle_edge)
        p[:handle_edge]=handle_edge unless handle_edge=='preserve'
      end
      p=validate_profile(p) unless supplier_only
      target_profile=->(target) do
        next p if supplier_only
        resolved=resolve_family_profile(p,target[:order_row][:width],target[:order_row][:height],variant_mode)
        next resolved unless resolved[:kind]=='jpull' && handle_edge=='preserve'
        old_edge={'Góra'=>'top','Dół'=>'bottom','Lewa'=>'left','Prawa'=>'right'}[target[:order_row][:handle]]
        resolved.merge(handle_edge:old_edge || p[:handle_edge] || 'top')
      end
      model=snapshot[:model]
      checker=OrderFrontOverlay.new
      raise Elfis::BastillePodmienFront.l('Fronty zmieniły się w modelu. Odśwież listę.','The fronts have changed. Refresh the list.') unless targets.all? { |target| checker.valid_target?(target) }
      raise Elfis::BastillePodmienFront.l('Front lub jego szafka są zablokowane.','The front or its cabinet is locked.') if targets.any? { |target| target[:path].any?(&:locked?) }
      old_path=model.active_path
      old_selection=model.selection.to_a
      clear_order_highlight
      session=performance_session(model)
      batch_key=SecureRandom.uuid
      roots=(targets.map { |target| target[:path].first }+Array(old_path).first(1)).uniq
      tokens={};opened=false;done=[]
      # Measure in the model context before opening the single transaction.
      # Native context changes otherwise split transactions transparently.
      model.active_path=nil if old_path
      targets.each { |target| measure(target[:path].last,model,nil,target[:path],target_profile.call(target),target[:order_row][:external] ? target[:bounds] : nil) } unless supplier_only
      session.internal_depth+=1
      begin
        model.start_operation('ELFIS — zmień profil pozycji z listy',true);opened=true
        (targets.map { |target| target[:path] }+[Array(old_path)]).each do |path|
          path.each do |entity|
            tokens[entity] ||= SecureRandom.uuid
            entity.set_attribute('ElfisOrderBatch',batch_key,tokens[entity])
          end
        end
        specs=targets.map { |target| {root:target[:path].first,tokens:target[:path].map { |entity| tokens[entity] },bounds:target[:order_row][:external] ? target[:bounds] : nil,profile:target_profile.call(target)} }
        resolve=->(root,ids) do
          path=[root]
          ids.drop(1).each do |token|
            child=path.last.definition.entities.find { |entity| instance?(entity) && entity.get_attribute('ElfisOrderBatch',batch_key)==token }
            break unless child
            path<<child
          end
          path
        end
        specs.each do |spec|
          path=resolve.call(spec[:root],spec[:tokens])
          raise Elfis::BastillePodmienFront.l('Nie odnaleziono frontu po odseparowaniu kopii szafki.','Could not find the front after isolating the cabinet instance.') unless path.length==spec[:tokens].length
          if supplier_only
            path=unique_path(path)
            path.last.set_attribute('ElfisBastillePodmien','supplier',supplier_only)
            done<<path.last
          else
            done<<replace(path.last,model,nil,path,spec[:profile],operation:false,select:false,bounds_override:spec[:bounds])
          end
        end
        restore=old_path ? resolve.call(old_path.first,old_path.map { |entity| tokens[entity] }) : nil
        # Markers copied by Make Unique are removed only in affected subtrees.
        seen={};clean=nil
        clean=->(entity) do
          next unless entity.valid?
          entity.delete_attribute('ElfisOrderBatch',batch_key)
          if instance?(entity) && !seen[entity.definition]
            seen[entity.definition]=true
            entity.definition.entities.each { |child| clean.call(child) if instance?(child) }
          end
        end
        roots.each { |root| clean.call(root) }
        tokens.each_key { |entity| clean.call(entity) }
        # Restore edit mode inside the operation so SketchUp folds its native
        # context transaction into the same visible Undo step.
        model.active_path=restore if restore && !restore.empty?
        model.commit_operation;opened=false
      rescue
        model.abort_operation if opened
        session.changed(true)
        raise
      ensure
        session.internal_depth-=1
        context=(defined?(restore) && restore) || old_path
        if context
          context=context.take_while(&:valid?)
          model.active_path=context unless context.empty? || model.active_path==context
        end
        model.selection.clear
        model.selection.add(old_selection.select { |entity| entity.valid? && model.active_entities.include?(entity) })
      end
      refresh_order_list
      message=supplier_only ? Elfis::BastillePodmienFront.l("Przypisano #{done.length} frontów do „#{supplier_only}”. Ctrl+Z cofa zmianę.","Assigned #{done.length} fronts to “#{supplier_only}”. Ctrl+Z undoes the change.") : Elfis::BastillePodmienFront.l("Zmieniono #{done.length} frontów na profil „#{p[:name]}”. Ctrl+Z cofa całą podmianę.","Changed #{done.length} fronts to profile “#{p[:name]}”. Ctrl+Z undoes the entire replacement.")
      @order_dialog.execute_script("setOrderStatus(#{JSON.generate(message)})") if @order_dialog
      done
    rescue
      model.active_path=old_path if defined?(model) && model && defined?(old_path) && old_path && old_path.all?(&:valid?) && model.active_path.nil?
      raise
    end

    def show_order_list
      if @order_dialog && @order_dialog.visible?
        @order_dialog.bring_to_front
        refresh_order_list
        return
      end
      dialog=UI::HtmlDialog.new(dialog_title:Elfis::BastillePodmienFront.l('ELFIS — Lista frontów do zamówienia','ELFIS — Door Order List'),preferences_key:'ElfisDoorOrderList',width:1100,height:680,min_width:800,min_height:450,resizable:true)
      @order_dialog=dialog
      dialog.set_file(localized_html('order_list'))
      dialog.add_action_callback('order_action') do |_,json|
        begin
          data=JSON.parse(json,symbolize_names:true)
          case data[:action]
          when 'language' then change_language(data[:language],:orders)
          when 'ready'
            refresh_order_list
          when 'refresh'
            @order_include_hidden=data[:include_hidden]==true
            @order_include_facade=data[:include_facade]==true
            @order_include_endpanels=data[:include_endpanels]==true
            @order_include_handles=data[:include_handles]!=false
            refresh_order_list
          when 'sort'
            raise 'Invalid sort' unless %w[height width thickness].include?(data[:field]) && %w[asc desc].include?(data[:direction])
            Sketchup.write_default('ELFIS Door Profile Library','order_sort_field',data[:field])
            Sketchup.write_default('ELFIS Door Profile Library','order_sort_direction',data[:direction])
            @order_snapshot[:data][:sort]=order_sort_settings if @order_snapshot
            dialog.execute_script('setOrderStatus('+JSON.generate(l('Zmieniono sortowanie.','Sort updated.'))+')')
          when 'filter_stock'
            raise 'Refresh the order list first.' unless @order_snapshot && @order_snapshot[:model]==Sketchup.active_model && @order_snapshot[:data][:revision]==data[:revision]
            clear_order_highlight
            rows=@order_snapshot[:data][:rows].select { |row| Array(data[:ids]).include?(row[:id]) }
            dialog.execute_script('setOrderStock('+JSON.generate(order_stock_plan(rows))+')')
          when 'stock_settings'
            save_order_stock_settings(data[:length],data[:kerf],data[:split_sections])
            refresh_order_list
          when 'dimensions'
            @order_show_dimensions=data[:enabled]==true
            Sketchup.write_default('ELFIS Door Profile Library','order_dimensions',@order_show_dimensions)
            @order_overlay.show_dimensions=@order_show_dimensions if @order_overlay
            Sketchup.active_model.active_view.invalidate
            dialog.execute_script("setOrderStatus(#{JSON.generate(l('Zmieniono widoczność wymiarów w modelu.','Dimension labels updated.'))})")
          when 'copy' then copy_order_list(data[:ids],data[:revision],data[:include_handles]!=false)
          when 'pdf'
            unless export_order_pdf
              dialog.execute_script("setOrderStatus(#{JSON.generate(l('Eksport anulowany.','Export cancelled.'))})")
            end
          when 'highlight' then highlight_order_row(data[:ids] || data[:id],data[:revision])
          when 'zoom' then zoom_order_rows(data[:ids] || data[:id],data[:revision])
          when 'clear_highlight' then clear_order_highlight
          when 'replace_row' then replace_order_row(data[:ids] || data[:id],data[:revision],data[:profile_id],data[:handle_edge] || 'preserve',data[:variant_mode] || 'auto')
          else raise Elfis::BastillePodmienFront.l('Nieznane polecenie listy frontów.','Unknown order-list command.')
          end
        rescue => error
          dialog.execute_script("setOrderError(#{JSON.generate(error.message)})")
        end
      end
      dialog.set_on_closed do
        if @order_dialog.equal?(dialog)
          clear_order_highlight
          @order_dialog=nil;@order_snapshot=nil
        end
      end
      dialog.center;dialog.show
    end

    def install_order_list_command
      return if @order_command
      @order_command=UI::Command.new('ELFIS — Lista frontów do zamówienia') { show_order_list }
      @order_command.tooltip=Elfis::BastillePodmienFront.l('Lista frontów: wymiary, rodzaj, ilość i kolor','Order list: dimensions, type, quantity and colour')
      @order_command.status_bar_text=Elfis::BastillePodmienFront.l('Otwórz i odśwież zestawienie frontów z projektu. Kopiowanie tabeli do schowka.','Open and refresh the project order list. Copy the table to the clipboard.')
      @order_command.small_icon=File.join(__dir__,'order_list.svg')
      @order_command.large_icon=@order_command.small_icon
      UI.menu('Extensions').add_item(@order_command)
      @toolbar.add_item(@order_command)
    end
  end
end
