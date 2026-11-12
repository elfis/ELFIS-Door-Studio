# encoding: UTF-8
module Elfis
  module BastillePodmienFront
    FINISHING_GROUPS = %w[plinths endpanels pelmets crowns other].freeze unless const_defined?(:FINISHING_GROUPS)

    def order_product_group(layer)
      names=[layer.name];folder=layer.respond_to?(:folder) ? layer.folder : nil
      while folder
        names<<folder.name;folder=folder.respond_to?(:folder) ? folder.folder : nil
      end
      names.each do |name|
        key=order_tag_key(name)
        return 'plinths' if key.match?(/plinth|toe.?kick|cokol/)
        return 'endpanels' if key.match?(/endpanel/)
        return 'pelmets' if key.match?(/pelmet/)
        return 'crowns' if key.match?(/crown|cornice|gzyms/)
      end
      'other'
    end

    def order_group_label(group)
      {'fronts'=>l('Fronty','Fronts'),'plinths'=>l('Cokoły','Plinths'),
       'endpanels'=>l('Panele kończące','End Panels'),'pelmets'=>l('Pelmety','Pelmets'),
       'crowns'=>l('Gzymsy','Crowns'),'other'=>l('Pozostałe Finishing','Other Finishing')}[group] || group
    end

    def order_group(row)
      row[:section]=='endpanels' ? (row[:product_group] || 'other') : 'fronts'
    end

    def order_sort_settings
      field=Sketchup.read_default('ELFIS Door Profile Library','order_sort_field','height')
      direction=Sketchup.read_default('ELFIS Door Profile Library','order_sort_direction','asc')
      {field:%w[height width thickness].include?(field) ? field : 'height',direction:direction=='desc' ? 'desc' : 'asc'}
    end

    def sorted_order_rows(rows)
      settings=order_sort_settings;field=settings[:field].to_sym;sign=settings[:direction]=='desc' ? -1 : 1
      rows.sort_by { |r| [(['fronts']+FINISHING_GROUPS).index(order_group(r)) || 99,sign*r[field].to_f,r[:height].to_f,r[:width].to_f,r[:profile].to_s] }
    end

    def order_stock_settings
      {length:Sketchup.read_default('ELFIS Door Profile Library','stock_length',2400.0).to_f,
       kerf:Sketchup.read_default('ELFIS Door Profile Library','stock_kerf',3.0).to_f,
       split_sections:Sketchup.read_default('ELFIS Door Profile Library','stock_split_sections',false)==true}
    end

    def save_order_stock_settings(length,kerf,split_sections=false)
      length=Float(length);kerf=Float(kerf)
      raise l('Nieprawidłowa długość listwy lub rzaz.','Invalid stock length or saw kerf.') unless length.finite? && kerf.finite? && length>0 && length<=100_000 && kerf>=0 && kerf<length
      Sketchup.write_default('ELFIS Door Profile Library','stock_length',length)
      Sketchup.write_default('ELFIS Door Profile Library','stock_kerf',kerf)
      Sketchup.write_default('ELFIS Door Profile Library','stock_split_sections',split_sections==true)
    end

    # One-dimensional cutting only. Kerf between parts is mandatory; a final
    # separating cut is needed only if stock remains. Work in hundredths of mm.
    def pack_order_stock(parts,length,kerf)
      capacity=(length*100).round;saw=(kerf*100).round
      items=parts.sort_by { |p| [-p[:length],p[:row_id],p[:index]] }
      fits=->(bin,item) do
        used=bin.sum { |p| (p[:length]*100).round }+(item[:length]*100).round+saw*bin.length
        used<=capacity
      end
      bins=[];oversize=[]
      items.each do |item|
        unless fits.call([],item);oversize<<item;next;end
        bin=bins.select { |b| fits.call(b,item) }.max_by { |b| b.sum { |p| p[:length] }+kerf*b.length }
        bin ? bin<<item : bins<<[item]
      end
      # Bounded branch-and-bound improves greedy layouts without factorial UI
      # stalls. Larger orders keep the fast best-fit-decreasing result.
      valid=items-oversize;optimal=false
      lower=((valid.sum { |p| (p[:length]*100).round }+saw*valid.length).to_f/(capacity+saw)).ceil
      if bins.length==lower
        optimal=true
      elsif valid.length<=32
        nodes=0;limit=25_000;best=bins.map(&:dup);work=[];exhausted=false
        search=nil
        search=->(i) do
          nodes+=1
          if nodes>limit;exhausted=true;return;end
          return if best.length==lower
          if i==valid.length;best=work.map(&:dup) if work.length<best.length;return;end
          item=valid[i];seen={}
          work.each do |bin|
            key=[bin.sum { |p| (p[:length]*100).round },bin.length]
            next if seen[key] || !fits.call(bin,item)
            seen[key]=true;bin<<item;search.call(i+1);bin.pop
            return if exhausted || best.length==lower
          end
          if work.length+1<best.length
            work<<[item];search.call(i+1);work.pop
          end
        end
        search.call(0);bins=best;optimal=!exhausted || bins.length==lower
      end
      {bars:bins.map do |bin|
        part_length=bin.sum { |p| p[:length] };between=kerf*[bin.length-1,0].max
        remainder=(length-part_length-between).round(2)
        # At the end of the stock the blade may extend past its edge.
        cutting_loss=between+[remainder,kerf].min
        {parts:bin,cutting_loss:cutting_loss.round(2),waste:[length-part_length-cutting_loss,0].max.round(2)}
      end,oversize:oversize,optimal:optimal}
    end

    def order_stock_plan(rows,settings=order_stock_settings)
      grouped={}
      rows.select { |r| order_group(r)=='plinths' }.each do |row|
        # Preserve product, material and board thickness. By default narrower
        # plinths can use the same stock's lengthwise offcuts as wider parts.
        product=row[:stock_product] || row[:profile].to_s
        # Imported/scaled geometry commonly measures 150.01 rather than 150.
        # Group nominal cross-sections at 0.1 mm; retain actual cutting lengths.
        section=[row[:height],row[:width]].min.round(1);thickness=row[:thickness].round(1)
        key=JSON.generate([product,row[:type],row[:source],row[:colours],settings[:split_sections] ? section : nil,thickness])
        group=grouped[key] ||= {product:product,source:row[:source],colours:row[:colours],section:section,thickness:thickness,parts:[]}
        group[:section]=[group[:section],section].max
        row[:quantity].times { |i| group[:parts]<<{row_id:row[:id],index:i,target_id:Array(row[:occurrence_ids])[i],length:[row[:height],row[:width]].max,section:section} }
      end
      {settings:settings,groups:grouped.values.map do |group|
        plan=pack_order_stock(group.delete(:parts),settings[:length],settings[:kerf])
        group.merge(plan).merge(quantity:plan[:bars].length)
      end}
    end
  end
end
