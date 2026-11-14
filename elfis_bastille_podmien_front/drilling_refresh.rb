# encoding: UTF-8
require 'securerandom'
module Elfis
  module DrillingRefresh
    extend self
    def l(pl,en);BastillePodmienFront.l(pl,en);end
    def kinds(path,model=Sketchup.active_model)
      entity=path.last
      joint=entity.get_attribute(CarcassJoinery::DICT,'owner_key')
      pin=entity.get_attribute(ShelfPins::DICT,'owner_key')
      types=[]
      types<<:joint if joint && CarcassJoinery.eligible?(CarcassJoinery.board(path,model))
      types<<:pin if pin && ShelfPins.shelf?(ShelfPins.board(path,model))
      types<<:hinge if entity.get_attribute(HingeDrilling::DICT,'owner') && HingeDrilling.front?(entity)
      types<<:drawer if entity.get_attribute(DrawerDrilling::DICT,'owner') && DrawerDrilling.front?(entity)
      if CarcassJoinery.back?(CarcassJoinery.board(path,model))
        types<<:kamar if entity.get_attribute(HangerCutouts::DICT,'preset')=='kamar' || HangerCutouts.existing_layout?(path,model)
      end
      types
    end
    def kind(path,model=Sketchup.active_model);types=kinds(path,model);types.length>1 ? :mixed : types.first;end
    def tool_for(type);{pin:ShelfPins,joint:CarcassJoinery,hinge:HingeDrilling,drawer:DrawerDrilling,kamar:HangerCutouts}.fetch(type);end
    def settings_for(type,path=nil)
      return path ? HangerCutouts.layout_settings(path) : HangerCutouts.preset if type==:kamar
      return HingeDrilling.layout_settings(path) if type==:hinge && path
      tool_for(type).settings
    end
    def old_groups(path,type,model)
      case type
      when :hinge,:drawer;tool_for(type).associated(path,model).map { |q|{path:q} }
      when :kamar
        HangerCutouts.plan(path,HangerCutouts.preset,model)[:corners].filter_map { |c|{path:path+[c[:existing]]} if c[:existing] }
      else;tool_for(type).removal_groups(path,model)
      end
    end
    def plan(path,model=Sketchup.active_model,kind:nil)
      raise 'Unsupported drilling type.' if kind && !%i[pin joint hinge drawer kamar].include?(kind)
      types=kinds(path,model);types&=[kind] if kind
      raise l('Najpierw przejmij istniejące wiercenia w ustawieniach ELFIS lub utwórz je narzędziem ELFIS.','First adopt existing drilling in ELFIS settings or create it with an ELFIS tool.') if types.empty?
      plans=types.map { |type|tool_for(type).plan(path,settings_for(type,path),model) }
      plans.first.merge(holes:plans.flat_map { |p|p[:holes] },refresh_kind:types.length==1 ? types.first : :mixed,refresh_kinds:types)
    end
    # Only positively owned single-circle shelf-pin groups are candidates. A
    # missing source in a selected side alone is not evidence of deletion.
    # Resolve owners within the nearest assembly containing two parallel sides,
    # so an identical UUID in a different cabinet copy cannot hide an orphan.
    def orphan_pins(scope_paths,model=Sketchup.active_model)
      result=[]
      scope_paths.each do |scope|
        records=[];walk=nil
        walk=->(path,stack) do
          e=path.last;next if !e.valid? || stack.include?(e.definition)
          source=e.get_attribute(ShelfPins::DICT,'source');key=e.get_attribute(ShelfPins::DICT,'owner_key')
          b=CarcassJoinery.board(path,model)
          side=b && (StudioSettings.role?(e,:sides) || CarcassJoinery.back?(b)) && b[:axes][b[:thin]].dot(Z_AXIS).abs<0.001
          records<<{path:path,entity:e,source:source,key:key,side:side ? b : nil}
          e.definition.entities.each { |child|walk.call(path+[child],stack+[e.definition]) if ShelfPins.instance?(child) }
        end
        walk.call(scope,[])
        prefix=->(path,parent) { path.length>=parent.length && path.take(parent.length)==parent }
        groups=records.select { |v|v[:entity].is_a?(Sketchup::Group) && v[:key] && v[:source].to_s.match?(/\A\d+(?:\/\d+)*\z/) }
        sides=records.select { |v|v[:side] }
        groups.each do |g|
          receiver=sides.select { |v|prefix.call(g[:path],v[:path]) }.max_by { |v|v[:path].length };next unless receiver
          assembly=nil
          (receiver[:path].length-1).downto(scope.length) do |n|
            parent=receiver[:path].take(n);b=receiver[:side]
            peers=sides.select { |v|prefix.call(v[:path],parent) && v[:side][:axes][v[:side][:thin]].dot(b[:axes][b[:thin]]).abs>0.999 }
            center=b[:bb].center.transform(b[:world]);axis=b[:axes][b[:thin]]
            next unless peers.any? { |v|(center.vector_to(v[:side][:bb].center.transform(v[:side][:world])).dot(axis)).abs>20.mm }
            assembly=parent;break
          end
          next unless assembly
          live=records.select { |v|!v[:source] && prefix.call(v[:path],assembly) }
          next if live.any? { |v|v[:key]==g[:key] || v[:entity].persistent_id.to_s==g[:source].split('/').last }
          circle=DrillingEditor.circle(g[:path],model);next unless circle
          result<<{path:g[:path],point:circle[:point]}
        end
      end
      result.uniq { |g|g[:path].map(&:persistent_id) }
    end
    def apply(paths,model=Sketchup.active_model,operation:true,kind:nil,cleanup_roots:nil)
      raise l('Najpierw utwórz unikatową otwartą szafkę.','Make the open cabinet unique first.') if Array(model.active_path).any? { |e| e.definition.instances.length>1 }
      paths=paths.uniq { |p| p.map(&:persistent_id) }
      scopes=cleanup_roots || paths.map { |p|[p.first] }.uniq
      orphans=kind.nil? ? orphan_pins(scopes,model) : []
      raise l('Grupa osieroconych wierceń lub jej rodzic są zablokowane.','An orphaned drilling group or its parent is locked.') if orphans.any? { |g|g[:path].any?(&:locked?) }
      return {removed:0,created:0,panels:0,orphans:0} if paths.empty? && orphans.empty? && cleanup_roots
      raise l('Nie wybrano paneli.','No panels selected.') if paths.empty? && orphans.empty?
      # Validate the complete new layout and old drilling before erasing anything.
      specs=paths.flat_map do |path|
        p=plan(path,model,kind:kind)
        p[:refresh_kinds].map do |type|
          old=old_groups(path,type,model)
          raise l('Stare wiercenia lub ich rodzic są zablokowane.','Old drilling or its parent is locked.') if old.any? { |h| h[:path].any?(&:locked?) }
          [path,type]
        end
      end
      token=SecureRandom.uuid;marked=[];removed=0;created=0
      model.start_operation(l('ELFIS — Odśwież wiercenia','ELFIS — Refresh drilling'),true) if operation
      begin
        mark=->(path) do
          path.each { |e|e.set_attribute('ElfisRefreshTemp',token,e.persistent_id.to_s);marked<<e }
          [path.first,path.map { |e|e.get_attribute('ElfisRefreshTemp',token) }]
        end
        orphan_specs=orphans.map { |g|mark.call(g[:path]) }
        specs=specs.map do |path,type|
          path.each { |e| e.set_attribute('ElfisRefreshTemp',token,e.persistent_id.to_s);marked<<e }
          [path.first,path.map { |e| e.get_attribute('ElfisRefreshTemp',token) },type]
        end
        resolve=->(root,ids) do
          path=[root]
          ids.drop(1).each do |id|
            e=path.last.definition.entities.find { |v| ShelfPins.instance?(v) && v.get_attribute('ElfisRefreshTemp',token)==id }
            raise 'Panel path changed.' unless e
            path<<e
          end
          path
        end
        orphan_specs.each do |root,ids|
          target=BastillePodmienFront.unique_path(resolve.call(root,ids));target.last.erase!;removed+=1
        end
        specs.each do |root,ids,type|
          tool=tool_for(type)
          if type==:hinge || type==:drawer
            source=resolve.call(root,ids)
            result=tool.apply([source],settings_for(type,source),model,operation:false,mode: :update)
            removed+=result[:removed];created+=result[:created]
          elsif type==:kamar
            # Reuse valid notches instead of filling and cutting them again.
            source=resolve.call(root,ids)
            result=tool.apply([source],settings_for(type,source),model,operation:false)
            created+=result[:created]
          else
            removed+=tool.remove([resolve.call(root,ids)],model,operation:false)[:removed]
            created+=tool.apply([resolve.call(root,ids)],settings_for(type),model,operation:false)[:created]
          end
        end
        model.definitions.each { |d| d.entities.each { |e| e.delete_attribute('ElfisRefreshTemp',token) if ShelfPins.instance?(e) } }
        marked.each { |e| e.delete_attribute('ElfisRefreshTemp',token) if e.valid? }
        model.commit_operation if operation
      rescue
        model.abort_operation if operation
        raise
      end
      model.active_view.invalidate
      {removed:removed,created:created,panels:paths.length,orphans:orphans.length}
    end
    def status(r)
      l("Panele: #{r[:panels]}. Usunięto stare: #{r[:removed]} (po usuniętych półkach: #{r[:orphans]||0}), dodano nowe: #{r[:created]}.","Panels: #{r[:panels]}. Old groups removed: #{r[:removed]} (deleted shelves: #{r[:orphans]||0}), new groups added: #{r[:created]}.")
    end
    def activate
      model=Sketchup.active_model
      roots=model.selection.select { |e| ShelfPins.instance?(e) }
      paths=roots.flat_map do |e|
        source_paths(e,model)
      end
      if roots.empty?;model.select_tool(Tool.new)
      else;Sketchup.set_status_text(status(apply(paths,model,cleanup_roots:roots.map { |e|[e] })))
      end
    rescue=>e;UI.messagebox(e.message)
    end
    def source_paths(root,model,prefix:[])
      out=[];walk=nil
      walk=->(path,stack) do
        e=path.last;next if !e.valid? || stack.include?(e.definition)
        out<<path if kind(path,model)
        e.definition.entities.each { |child|walk.call(path+[child],stack+[e.definition]) if ShelfPins.instance?(child) }
      end
      walk.call(prefix+[root],[]);out
    end
    class Tool < CarcassJoinery::Tool
      def initialize;super(nil);@refresh=true;end
      def activate;Sketchup.set_status_text(DrillingRefresh.l('Odśwież wiercenia: kliknij półkę, wieniec, plecy lub front. Zaznacz szafkę, aby odświeżyć jej powiązane operacje. Esc: koniec.','Refresh drilling: click a shelf, rail, back or front. Select a cabinet to refresh its associated operations. Esc: finish.'));end
      def onMouseMove(flags,x,y,view)
        signature=[x,y,Sketchup.active_model.active_path];return if @signature==signature;@signature=signature
        found=nil;assembly=false;ph=view.pick_helper;ph.do_pick(x,y)
        (0...ph.count).each do |i|
          raw=ph.path_at(i).take_while { |e| ShelfPins.instance?(e) }
          raw.length.downto(1) { |n| candidate=raw.take(n);if DrillingRefresh.kind(candidate);found=candidate;break;end }
          break if found
        end
        unless found
          (0...ph.count).each do |i|
            raw=ph.path_at(i).take_while { |e|ShelfPins.instance?(e) }
            raw.length.downto(1) do |n|
              candidate=raw.take(n)
              @orphan_hover_cache||={};@orphan_hover_cache.clear if @orphan_hover_cache.length>64
              key=candidate.map(&:persistent_id).join('/')
              @orphan_hover_groups=@orphan_hover_cache[key] ||= DrillingRefresh.orphan_pins([candidate])
              next if @orphan_hover_groups.empty?
              found=candidate;assembly=true;break
            end
            break if found
          end
        end
        if found
          unless @path==found && @plan
            if assembly
              e=found.last;tr=found.inject(Sketchup.active_model.edit_transform) { |t,v|t*v.transformation }
              @plan={shelf:{bb:e.definition.bounds,world:tr},holes:@orphan_hover_groups}
            else;@plan=DrillingRefresh.plan(found)
            end
          end
          @path=found;@assembly=assembly
        else;@path=nil;@plan=nil
        end
        view.invalidate
      rescue=>e;@path=nil;@plan=nil;Sketchup.set_status_text(e.message);view.invalidate
      end
      def onLButtonDown(flags,x,y,view)
        @signature=nil;onMouseMove(flags,x,y,view);return unless @path
        if @assembly
          sources=DrillingRefresh.source_paths(@path.last,Sketchup.active_model,prefix:@path[0...-1])
          result=DrillingRefresh.apply(sources,Sketchup.active_model,cleanup_roots:[@path])
        else;result=DrillingRefresh.apply([@path])
        end
        Sketchup.set_status_text(DrillingRefresh.status(result));@path=nil;@plan=nil;@signature=nil;@orphan_hover_cache={};view.invalidate
      rescue=>e;UI.messagebox(e.message)
      end
      def getMenu(menu);menu.add_item(DrillingRefresh.l('Ustawienia domyślne…','Default settings…')) { StudioSettings.show };end
    end
    def install
      new_command=!@command
      @command ||= UI::Command.new('ELFIS — Refresh drilling') { activate }
      @command.menu_text='ELFIS — Refresh drilling'
      @command.tooltip=l('Odśwież wiercenia: podpórki, kołki i śruby, zawiasy, szuflady oraz Kamar','Refresh drilling: shelf pins, dowels and screws, hinges, drawers and Kamar')
      @command.small_icon=File.join(__dir__,'drilling_refresh.svg');@command.large_icon=@command.small_icon
      # SketchUp snapshots the command icon when adding a toolbar button.
      # Set both sizes first, including on the very first extension load.
      if new_command
        UI.menu('Extensions').add_item(@command)
        toolbar=BastillePodmienFront.instance_variable_get(:@toolbar);toolbar.add_item(@command) if toolbar
      end
    end
  end
end
