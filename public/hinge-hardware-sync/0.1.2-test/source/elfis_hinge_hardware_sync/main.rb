# encoding: UTF-8
require 'json'
require 'securerandom'
require 'fileutils'
require 'digest'
module Elfis
  module HingeHardwareSync
    extend self
    DICT='ElfisHingeHardwareSync' unless const_defined?(:DICT)
    def instance?(e);e.is_a?(Sketchup::Group)||e.is_a?(Sketchup::ComponentInstance);end
    def dependencies!;raise 'Włącz najpierw ELFIS Door Studio.' unless defined?(Elfis::HingeDrilling)&&defined?(Elfis::DrillingEditor);end
    def walk(path,stack=[],&block)
      e=path.last;return unless e.valid?;raise 'Recursive component.' if stack.include?(e.definition)
      return if block.call(path)==:stop
      e.definition.entities.each { |v|walk(path+[v],stack+[e.definition],&block) if instance?(v) }
    end
    # A bound cabinet can be edited from inside its groups. Read geometry in
    # the original binding context, without changing the user's active_path.
    class GeometryContext
      def initialize(model,path);@model=model;@path=path;end
      def edit_transform;@path.inject(IDENTITY) { |t,e|t*e.transformation };end
      def active_path;@path.empty? ? nil : @path;end
      def active_entities;@path.empty? ? @model.entities : @path.last.definition.entities;end
      def method_missing(name,*args,**kwargs,&block);@model.public_send(name,*args,**kwargs,&block);end
      def respond_to_missing?(name,all=false);@model.respond_to?(name,all);end
    end
    def geometry_model(root,m)
      return m if m.is_a?(GeometryContext)
      record=@tracked&&@tracked[m]&&@tracked[m][root]
      record ? GeometryContext.new(m,record[:context]) : m
    end
    def world(path,m);path.inject(geometry_model(path.first,m).edit_transform) { |t,e|t*e.transformation };end
    def indices(path);path.each_cons(2).map { |a,b|a.definition.entities.to_a.index(b) };end
    def resolve(root,ids)
      ids.inject([root]) { |p,i|e=p.last.definition.entities.to_a[i];raise 'Hardware path changed.' unless instance?(e)&&e.valid?;p+[e] }
    end
    # Attribute references survive Make Unique, profile replacement and changes
    # to the order of entities. Never store entity-list offsets as addresses.
    def stable_ref(path)
      path.drop(1).map do |e|
        key=e.get_attribute(DICT,'path_key')||SecureRandom.uuid
        e.set_attribute(DICT,'path_key',key);key
      end
    end
    def resolve_ref(root,keys)
      keys.inject([root]) do |p,key|
        matches=p.last.definition.entities.select { |e|instance?(e)&&e.get_attribute(DICT,'path_key')==key }
        raise 'Nie można jednoznacznie odnaleźć elementu zawiasów.' unless matches.length==1
        p+[matches.first]
      end
    end
    def cache_dir;@cache_dir||File.join(__dir__,'templates');end
    # Definition GUIDs and copied attribute IDs do not identify geometry. In
    # particular, Make Unique copies model_key while nested geometry can move.
    def geometry_hash(definition,memo={})
      return memo[definition] if memo.key?(definition)
      memo[definition]='recursive'
      rows=definition.entities.map do |e|
        if instance?(e)
          ['instance',e.transformation.to_a.map { |v|v.round(9) },geometry_hash(e.definition,memo)]
        elsif e.is_a?(Sketchup::Edge)
          ['edge',e.vertices.map { |v|v.position.to_a.map { |n|n.round(9) } }.sort]
        elsif e.is_a?(Sketchup::Face)
          ['face',e.vertices.map { |v|v.position.to_a.map { |n|n.round(9) } }.sort]
        else
          [e.typename]
        end
      end
      memo[definition]=Digest::SHA256.hexdigest(JSON.generate(rows.sort_by { |v|JSON.generate(v) }))
    end
    # A single-child wrapper is an arbitrary user coordinate system, not a
    # mounting datum. Anchor calibration to the enclosed physical component.
    def payload(definition)
      transform=IDENTITY;seen=[]
      loop do
        raise 'Recursive hardware definition.' if seen.include?(definition)
        seen<<definition
        entities=definition.entities.to_a
        children=entities.select { |e|instance?(e) }
        break unless children.length==1 && entities.all? { |e|instance?(e)||e.is_a?(Sketchup::ConstructionPoint)||e.is_a?(Sketchup::ConstructionLine) }
        child=children.first;transform=transform*child.transformation;definition=child.definition
      end
      [definition,transform]
    end
    def supported_midplane?(t)
      attrs=t.fetch(:properties,{}).fetch(:attributes,{})
      abf=attrs[:ABF]||attrs['ABF']||{}
      %w[71B3580 71B358E 174H7100E].include?((abf[:article]||abf['article']).to_s)
    end
    def calibrate_template(t,definition)
      base,inside=payload(definition);shape=geometry_hash(base)
      physical_centre=base.bounds.center.transform(inside)
      if t[:mount_relative]
        raise 'Zmieniono kształt wzorca zawiasu. Przywróć właściwy model lub powiąż go ponownie.' unless t[:payload_hash]==shape
        relative=Geom::Transformation.new(t[:mount_relative])*inside.inverse
      else
        relative=Geom::Transformation.new(t[:relative])
        if supported_midplane?(t)
          # These Blum hinges/plates are symmetric about the actual mounting
          # height. Migrate stale legacy offsets from the physical geometry,
          # including the user's translation inside the imported group.
          error=physical_centre.transform(relative).z
          relative=Geom::Transformation.translation([0,0,-error])*relative
        end
      end
      if supported_midplane?(t)
        error=physical_centre.transform(relative).z
        raise 'Nie można potwierdzić osi modelu zawiasu względem wiercenia.' if error.abs>0.05.mm
      end
      t.merge(calibration_version:2,payload_hash:shape,mount_relative:(relative*inside).to_a,relative:relative.to_a)
    end
    def definition_for(t,m)
      key=t[:model_key]
      candidates=m.definitions.select { |d|d.guid==t[:definition] || (key&&d.get_attribute(DICT,'model_key')==key) }
      if t[:geometry_hash]
        found=candidates.find { |d|geometry_hash(d)==t[:geometry_hash] }
      else
        found=candidates.find { |d|d.guid==t[:definition] }
        found||=candidates.first if candidates.length==1
      end
      return found if found
      if key && key.match?(/\A[0-9a-f-]{36}\z/)
        file=File.join(cache_dir,key+'.skp')
        if File.file?(file)
          raise 'Uszkodzony plik SKP wzorca zawiasu.' if t[:skp_sha256]&&Digest::SHA256.file(file).hexdigest!=t[:skp_sha256]
          loaded=m.definitions.load(file)
          raise 'Geometria SKP nie odpowiada zapisanej kalibracji zawiasu.' if t[:geometry_hash]&&geometry_hash(loaded)!=t[:geometry_hash]
          return loaded
        end
      end
      nil
    end
    def cache_definition(t,definition)
      digest=geometry_hash(definition)
      key=[digest[0,8],digest[8,4],digest[12,4],digest[16,4],digest[20,12]].join('-')
      definition.set_attribute(DICT,'model_key',key)
      FileUtils.mkdir_p(cache_dir)
      file=File.join(cache_dir,key+'.skp')
      raise 'Nie udało się zapisać wzorca zawiasu SKP.' unless File.file?(file)||definition.save_as(file)
      t.merge(model_key:key,geometry_hash:digest,skp_sha256:Digest::SHA256.file(file).hexdigest,definition:definition.guid,parent:[])
    end
    def prepare_templates(source,root,m)
      owner=source.get_attribute(DICT,'owner');saved=templates_for(source)
      live=hardware(root).select { |p|p.last.get_attribute(DICT,'owner')==owner }
      prepared=saved.map do |t|
        hw=live.find { |p|p.last.get_attribute(DICT,'kind')==t[:kind]&&p.last.get_attribute(DICT,'slot')==t[:slot] }
        definition=hw ? hw.last.definition : definition_for(t,m)
        if !definition
          # A legacy GUID may change after editing a definition. Reuse an
          # intact calibration together with its own model, never mix origins.
          alternative=saved.select { |v|v[:kind]==t[:kind] }.sort_by { |v|(v[:slot]-t[:slot]).abs }.find { |v|definition_for(v,m) }
          raise 'Brak zapisanego modelu wzorcowego zawiasu. Powiąż istniejący komplet 3D.' unless alternative
          definition=definition_for(alternative,m);t=alternative.merge(slot:t[:slot])
        end
        cache_definition(calibrate_template(t,definition),definition)
      end
      source.set_attribute(DICT,'templates',JSON.generate(prepared))
      prepared
    end
    def kind(e)
      return nil unless e.layer.name.match?(/hardware|beschl[aä]ge|furnitura|фурнітур/i)
      text=[e.name,e.definition.name,e.get_attribute('ABF','statistical-name')].join(' ')
      return 'plate' if text.match?(/mounting plate|prowadnik|montageplatte/i)
      return 'hinge' if text.match?(/\bhinge\b|zawias|scharnier/i)
      nil
    end
    def fronts(root)
      out=[];walk([root]) { |p|if HingeDrilling.front?(p.last);out<<p;:stop;elsif kind(p.last);:stop;end };out
    end
    def hardware(root)
      out=[];walk([root]) { |p|if kind(p.last)||p.last.get_attribute(DICT,'kind');out<<p;:stop;elsif HingeDrilling.front?(p.last);:stop;end };out
    end
    def anchor(point,normal)
      n=normal.normalize;up=Z_AXIS.clone
      raise 'Unsupported tilted hinge axis.' if n.dot(up).abs>0.001
      up.normalize!;Geom::Transformation.axes(point,n.cross(up).normalize,n,up)
    end
    def patterns(path,m)
      m=geometry_model(path.first,m)
      b=HingeDrilling.front_board(path,m)
      cups=DrillingEditor.panel_holes(b,m).select { |h|(h[:diameter]-35).abs<0.01 }.sort_by { |h|[h[:point].z,h[:point].x,h[:point].y] }
      return [] if cups.empty?
      planned=HingeDrilling.plan(path,HingeDrilling.layout_settings(path),m)
      plate_spec=planned[:holes].find { |h|h[:kind]==:hinge_plate }
      receiver=plate_spec[:panel]
      plate_holes=DrillingEditor.panel_holes(receiver,m).select do |h|
        (h[:diameter]-plate_spec[:diameter]).abs<0.01 && (h[:depth]-plate_spec[:depth]).abs<0.01
      end
      pairs=plate_holes.combination(2).filter_map do |a,z|
        next unless (a[:point].distance(z[:point]).to_mm-32).abs<0.05
        next unless a[:point].vector_to(z[:point]).normalize.dot(Z_AXIS).abs>0.999
        centre=Geom::Point3d.new((0..2).map { |i|(a[:point][i]+z[:point][i])/2 })
        {point:centre,normal:a[:normal],ids:[a[:curve_id],z[:curve_id]]}
      end
      # Pair each cup with the nearest complete plate pattern, one-to-one.
      # If only the cup is moved, the hinge follows that cup while the plate
      # stays on its own actual holes. Never invent a missing plate reference.
      matches={};used=[]
      choices=cups.each_with_index.flat_map { |cup,i|pairs.each_with_index.map { |pair,j|[i,j,cup[:point].distance(pair[:point])] } }.sort_by(&:last)
      choices.each do |i,j,distance|
        next if matches.key?(i)||used.include?(j)||distance>150.mm
        matches[i]=pairs[j];used<<j
      end
      cups.each_with_index.map do |cup,i|
        pair=matches[i]
        {point:cup[:point],hinge:anchor(cup[:point],cup[:normal]),plate:pair && anchor(pair[:point],pair[:normal])}
      end
    end

    def props(e)
      {name:e.name,layer:e.layer.name,hidden:e.hidden?,material:e.material&.name,
       attributes:(e.attribute_dictionaries||[]).reject { |d|d.name==DICT }.to_h { |d|[d.name,d.to_h] }}
    end
    def ensure_unique_tree(root)
      root.make_unique if root.definition.instances.length>1
      visit=nil;visit=->(e,stack) do
        return if kind(e)||HingeDrilling.front?(e)
        raise 'Recursive container.' if stack.include?(e.definition)
        e.make_unique if e.definition.instances.length>1
        e.definition.entities.each { |v|visit.call(v,stack+[e.definition]) if instance?(v) }
      end
      visit.call(root,[])
    end
    # Bind only uniquely matched existing hinges/plates. Geometry is never guessed
    # or replaced: each imported model retains its complete calibrated transform.
    def binding_plan(root,m)
      sources=fronts(root).reject { |p|p.last.get_attribute(DICT,'templates') }.map do |p|
        {path:p,patterns:patterns(p,m)}
      end.reject { |f|f[:patterns].empty? }
      available=hardware(root).reject { |p|p.last.get_attribute(DICT,'owner') }
      assignments={}
      available.each do |p|
        k=kind(p.last);next unless k
        centre=p.last.definition.bounds.center.transform(world(p,m))
        choices=sources.flat_map { |f|f[:patterns].each_with_index.map { |a,i|[f,i,centre.distance(a[:point])] } }.sort_by(&:last)
        next if choices.empty? || choices.first.last>120.mm
        raise 'Ambiguous hinge/front association.' if choices[1] && (choices[1].last-choices.first.last).abs<1.mm
        f,i,_=choices.first;key=[indices(f[:path]),i,k]
        raise 'More than one hardware model matches a drilling. Review the cabinet.' if assignments[key]
        raise 'A hinge, front or its parent is locked.' if (p+f[:path]+Array(m.active_path)).any?(&:locked?)
        assignments[key]={hardware:indices(p),front:indices(f[:path]),slot:i,kind:k}
      end
      result=assignments.values.group_by { |v|v[:front] }
      result.each do |ref,items|
        source=sources.find { |f|indices(f[:path])==ref }
        expected=source[:patterns].length
        raise 'Missing complete mounting-plate drilling pair. Bind after restoring the plate holes.' unless source[:patterns].all? { |a|a[:plate] }
        raise 'Each existing cup must have one hinge and one mounting plate before binding.' unless items.count { |v|v[:kind]=='hinge' }==expected && items.count { |v|v[:kind]=='plate' }==expected
      end
      result
    end
    def bind(root,m=Sketchup.active_model,operation:true)
      dependencies!;raise 'Select a cabinet in the current editing context.' unless instance?(root)&&m.active_entities.include?(root)
      raise 'Make the open assembly unique first.' if Array(m.active_path).any? { |e|e.definition.instances.length>1 }
      plan=binding_plan(root,m);return {fronts:0,models:0} if plan.empty?
      m.start_operation('ELFIS — Powiąż zawiasy 3D',true) if operation
      begin
        stable_plan=plan.map { |ref,items|[stable_ref(resolve(root,ref)),items.map { |v|v.merge(hardware_ref:stable_ref(resolve(root,v[:hardware]))) }] }
        ensure_unique_tree(root)
        stable_plan.each do |ref,items|
          path=resolve_ref(root,ref);e=path.last;owner=e.get_attribute(HingeDrilling::DICT,'owner')||SecureRandom.uuid
          templates=[];anchors=patterns(path,m)
          items.each do |v|
            hp=resolve_ref(root,v[:hardware_ref]);hw=hp.last;k=v[:kind]
            relative=anchors.fetch(v[:slot]).fetch(k.to_sym).inverse*world(hp,m)
            template={kind:k,slot:v[:slot],relative:relative.to_a,definition:hw.definition.guid,parent:indices(hp.take(hp.length-1)),properties:props(hw)}
            template=cache_definition(calibrate_template(template,hw.definition),hw.definition)
            templates<<template
            hw.set_attribute(DICT,'owner',owner);hw.set_attribute(DICT,'kind',k);hw.set_attribute(DICT,'slot',v[:slot]);hw.set_attribute(DICT,'template',JSON.generate(template))
          end
          e.set_attribute(DICT,'owner',owner);e.set_attribute(DICT,'templates',JSON.generate(templates))
        end
        root.set_attribute(DICT,'enabled',true)
        m.commit_operation if operation
      rescue Exception
        m.abort_operation if operation;raise
      end
      track(root,m);{fronts:plan.length,models:plan.values.sum(&:length)}
    end
    def templates_for(e);JSON.parse(e.get_attribute(DICT,'templates','[]'),symbolize_names:true);end
    def restore_properties(e,p,m)
      e.name=p[:name];e.layer=m.layers[p[:layer]]||m.layers.add(p[:layer]);e.hidden=p[:hidden]
      e.material=m.materials[p[:material]] if p[:material]
      p.fetch(:attributes,{}).each { |dict,attrs|attrs.each { |key,value|e.set_attribute(dict.to_s,key.to_s,value) } }
    end
    def sync(root,m=Sketchup.active_model,operation:true,transparent:false)
      return {moved:0,added:0,removed:0} unless root.valid?&&root.get_attribute(DICT,'enabled')
      sources=fronts(root).select { |p|p.last.get_attribute(DICT,'templates') }
      specs=sources.map { |p|[p,patterns(p,m)] }
      raise 'Bound front or parent is locked.' if sources.any? { |p|(p+Array(m.active_path)).any?(&:locked?) }
      raise 'Bound hardware or parent is locked.' if hardware(root).any? { |p|p.last.get_attribute(DICT,'owner')&&(p+Array(m.active_path)).any?(&:locked?) }
      result={moved:0,added:0,removed:0};prior=@busy;@busy=true
      m.start_operation('ELFIS — Synchronizuj zawiasy 3D',true,false,transparent) if operation
      begin
        specs=specs.map { |p,anchors|[stable_ref(p),anchors] }
        ensure_unique_tree(root)
        specs.each do |ref,anchors|
          path=resolve_ref(root,ref);source=path.last;owner=source.get_attribute(DICT,'owner');templates=prepare_templates(source,root,m)
          bound=hardware(root).select { |p|p.last.get_attribute(DICT,'owner')==owner }
          %w[hinge plate].each do |k|
            targets=anchors.select { |a|a[k.to_sym] }
            items=bound.select { |p|p.last.valid? && p.last.get_attribute(DICT,'kind')==k }.sort_by { |p|p.last.get_attribute(DICT,'slot',0) }
            targets.each_with_index do |a,i|
              hp=items[i]
              template=templates.select { |t|t[:kind]==k }.min_by { |t|(t[:slot]-i).abs }
              raise 'Missing calibrated hinge template.' unless template
              # Every instance can have its own wrapper (Make Unique/manual
              # edit). Transfer the physical datum, never another slot's origin.
              template=cache_definition(calibrate_template(template,hp.last.definition),hp.last.definition) if hp
              # Legacy parent offsets can now point at a front or a deleted
              # group. New instances belong directly to this cabinet.
              parent=hp ? hp.take(hp.length-1) : [root]
              parent_world=world(parent,m)
              target=parent_world.inverse*a.fetch(k.to_sym)*Geom::Transformation.new(template[:relative])
              if hp
                hw=hp.last
                if hw.transformation.to_a.zip(target.to_a).any? { |x,y|(x-y).abs>1e-7 }
                  hw.transformation=target;result[:moved]+=1
                end
              else
                definition=definition_for(template,m)
                raise 'The hinge template definition is no longer in this model.' unless definition
                hw=parent.last.definition.entities.add_instance(definition,target)
                restore_properties(hw,template[:properties],m);result[:added]+=1
              end
              hw.set_attribute(DICT,'owner',owner);hw.set_attribute(DICT,'kind',k);hw.set_attribute(DICT,'slot',i);hw.set_attribute(DICT,'template',JSON.generate(template))
            end
            items.drop(targets.length).each { |p|p.last.erase!;result[:removed]+=1 }
          end
        end
        m.commit_operation if operation
      rescue Exception
        m.abort_operation if operation;raise
      ensure
        @busy=prior
      end
      track(root,m);m.active_view.invalidate;result
    end
    def fingerprint(root,m)
      fronts(root).select { |p|p.last.get_attribute(DICT,'templates') }.map do |p|
        [indices(p),patterns(p,m).map { |v|[v[:hinge].to_a,v[:plate]&.to_a] }]
      end.to_json
    end
    def track(root,m,context:Array(m.active_path))
      @tracked||={};@tracked[m]||={}
      @tracked[m][root]||={context:context}
      @tracked[m][root][:signature]=fingerprint(root,m)
    end
    def observer_update(m)
      return if @busy || !@tracked || !@tracked[m]
      m.active_entities.each { |e|track(e,m) if instance?(e)&&e.get_attribute(DICT,'enabled')&&!@tracked[m].key?(e) }
      @tracked[m].dup.each do |root,record|
        unless root.valid?;@tracked[m].delete(root);next;end
        signature=fingerprint(root,m);next if signature==record[:signature]
        sync(root,m,transparent:true)
      end
    rescue StandardError=>e
      Sketchup.set_status_text("ELFIS — zawiasy 3D: #{e.message}")
      puts "ELFIS HingeHardwareSync: #{e.message}"
    end
    def reset_signatures(m)
      (@tracked&&@tracked[m]||{}).each { |root,r|r[:signature]=fingerprint(root,m) if root.valid? }
    rescue StandardError;nil;end
    class ModelWatch < Sketchup::ModelObserver
      def onTransactionCommit(m)
        return if HingeHardwareSync.instance_variable_get(:@busy)
        UI.start_timer(0.05,false) { HingeHardwareSync.observer_update(m) }
      end
      def onTransactionUndo(m);HingeHardwareSync.reset_signatures(m);end
      def onTransactionRedo(m);HingeHardwareSync.reset_signatures(m);end
    end
    module ApplyHook
      def apply(paths,c=settings,m=Sketchup.active_model,operation:true,**options)
        sync=Elfis::HingeHardwareSync
        return super unless paths.any? { |p|p.first.get_attribute(sync::DICT,'enabled') || !sync.hardware(p.first).empty? }
        roots=paths.map(&:first).uniq
        prior=sync.instance_variable_get(:@busy);sync.instance_variable_set(:@busy,true)
        m.start_operation('ELFIS — Wiercenia i zawiasy 3D',true) if operation
        begin
          refs=paths.map { |p|[p.first,sync.stable_ref(p)] }
          roots.each { |root|sync.bind(root,m,operation:false) }
          resolved=refs.map { |root,ids|sync.resolve_ref(root,ids) }
          result=super(resolved,c,m,operation:false,**options)
          total={moved:0,added:0,removed:0}
          roots.each { |root|r=sync.sync(root,m,operation:false);r.each { |k,v|total[k]+=v } }
          m.commit_operation if operation
          result.merge(hardware:total)
        rescue Exception
          m.abort_operation if operation;raise
        ensure
          sync.instance_variable_set(:@busy,prior)
        end
      end
    end
    def attach(m)
      @watches||={};return if @watches[m]
      @watches[m]=ModelWatch.new;m.add_observer(@watches[m])
      visit=nil;visit=->(entities,path,stack) do
        entities.each do |e|
          next unless instance?(e)&&!stack.include?(e.definition)
          if e.get_attribute(DICT,'enabled');track(e,m,context:path)
          elsif !kind(e)&&!HingeDrilling.front?(e);visit.call(e.definition.entities,path+[e],stack+[e.definition]);end
        end
      end
      visit.call(m.entities,[],[])
    end
    class AppWatch < Sketchup::AppObserver
      def onNewModel(m);HingeHardwareSync.attach(m);end
      def onOpenModel(m);HingeHardwareSync.attach(m);end
    end
    module LayoutHook
      def layout_settings(path,c=settings)
        saved=super
        return saved unless path.last.get_attribute(Elfis::HingeDrilling::DICT,'layout')
        m=Elfis::HingeHardwareSync.geometry_model(path.first,Sketchup.active_model)
        begin
          plan(path,saved,m)
          saved
        rescue RuntimeError=>error
          raise unless error.message=='No cabinet side on the chosen hinge side.'
          # Old profiles changed local axes without converting the saved side
          # vector. Recover from actual cups, or the adjacent cabinet side.
          recovered=plan(path,saved.merge(side:'Auto'),m)
          saved.merge(side:recovered[:side].to_s.capitalize)
        end
      end
    end
    def install
      dependencies!
      HingeDrilling.singleton_class.prepend(LayoutHook) unless HingeDrilling.singleton_class.ancestors.include?(LayoutHook)
      return if @installed
      HingeDrilling.singleton_class.prepend(ApplyHook)
      UI.menu('Extensions').add_item('ELFIS — Powiąż zawiasy 3D z wierceniami') do
        begin
          m=Sketchup.active_model;roots=m.selection.select { |e|instance?(e) };raise 'Zaznacz szafkę.' if roots.empty?
          roots.each { |root|bind(root,m) };Sketchup.set_status_text('ELFIS — Zawiasy 3D powiązane z wierceniami.')
        rescue StandardError=>e;UI.messagebox(e.message);end
      end
      @app_watch=AppWatch.new;Sketchup.add_observer(@app_watch);attach(Sketchup.active_model);@installed=true
    end
  end
end
if defined?(Elfis::HingeDrilling)
  Elfis::HingeHardwareSync.install
else
  Elfis::HingeHardwareSync.instance_variable_set(:@load_timer,UI.start_timer(1,true) do
    if defined?(Elfis::HingeDrilling)
      UI.stop_timer(Elfis::HingeHardwareSync.instance_variable_get(:@load_timer));Elfis::HingeHardwareSync.install
    end
  end)
end


