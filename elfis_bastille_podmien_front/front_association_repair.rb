# encoding: UTF-8
require 'json'
module Elfis
  # Restore source identifiers lost by older profile replacement scripts.
  # Read identifiers from preserved machining; never guess from proximity.
  module FrontAssociationRepair
    extend self
    def nested_owners(entity,dict,stack=[])
      return [] if stack.include?(entity.definition)
      entity.definition.entities.select { |v|BastillePodmienFront.instance?(v) }.flat_map do |v|
        owner=v.get_attribute(dict,'owner')
        (owner ? [owner] : [])+nested_owners(v,dict,stack+[entity.definition])
      end.uniq
    end
    def plan(roots,m=Sketchup.active_model)
      changes=[];skipped=[]
      roots.each do |root|
        fronts=DrillingEditor.fronts(root,m)
        [HingeDrilling::DICT,DrawerDrilling::DICT].each do |dict|
          hints=fronts.to_h do |f|
            e=f[:entity];owner=e.get_attribute(dict,'owner');[e,owner ? [owner] : nested_owners(e,dict)]
          end
          fronts.each do |f|
            e=f[:entity];next if e.get_attribute(dict,'owner') || hints[e].empty?
            if hints[e].length!=1 || hints.count { |_,owners|owners.include?(hints[e].first) }!=1 || (Array(m.active_path)+f[:path]).any?(&:locked?)
              skipped<<e.name;next
            end
            indices=f[:path].each_cons(2).map { |a,b|a.definition.entities.to_a.index(b) }
            changes<<{front:f,indices:indices,dict:dict,owner:hints[e].first,root:root}
          end
        end
      end
      {changes:changes,skipped:skipped}
    end
    def repair(roots,m=Sketchup.active_model,operation:true)
      result=plan(roots,m);return {repaired:0,skipped:result[:skipped]} if result[:changes].empty?
      m.start_operation('ELFIS — Przywróć powiązania frontów',true) if operation
      begin
        result[:changes].each do |item|
          path=item[:indices].inject([item[:root]]) { |p,i|p+[p.last.definition.entities.to_a.fetch(i)] }
          path=BastillePodmienFront.unique_path(path);e=path.last
          e.set_attribute(item[:dict],'owner',item[:owner])
          if item[:dict]==HingeDrilling::DICT
            board=HingeDrilling.front_board(path,m)
            cups=DrillingEditor.panel_holes(board,m).select { |h|(h[:diameter]-35).abs<0.01 }.sort_by { |h|h[:point].z }
            if !e.get_attribute(HingeDrilling::DICT,'layout') && cups.length.between?(2,10)
              low,high=board[:points].map(&:z).minmax
              layout={count:cups.length,bottom:(cups.first[:point].z-low).to_mm,top:(high-cups.last[:point].z).to_mm,side:'Auto'}
              e.set_attribute(HingeDrilling::DICT,'layout',JSON.generate(layout))
            end
            if defined?(HingeHardwareSync) && !e.get_attribute(HingeHardwareSync::DICT,'templates')
              templates=HingeHardwareSync.hardware(item[:root]).filter_map do |p|
                h=p.last;next unless h.get_attribute(HingeHardwareSync::DICT,'owner')==item[:owner]
                raw=h.get_attribute(HingeHardwareSync::DICT,'template');JSON.parse(raw) if raw
              end
              unless templates.empty?
                e.set_attribute(HingeHardwareSync::DICT,'owner',item[:owner])
                e.set_attribute(HingeHardwareSync::DICT,'templates',JSON.generate(templates))
              end
            end
          end
        end
        m.commit_operation if operation
      rescue Exception
        m.abort_operation if operation;raise
      end
      {repaired:result[:changes].length,skipped:result[:skipped]}
    end
  end
end
