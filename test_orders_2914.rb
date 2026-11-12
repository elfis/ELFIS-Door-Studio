# encoding: UTF-8
# Standalone calculation tests; Sketchup defaults are replaced by an in-memory
# adapter. No model, UI, installed plugin or user settings are touched.
require 'json'
module Sketchup
  @defaults={}
  def self.read_default(section,key,fallback);@defaults.fetch([section,key],fallback);end
  def self.write_default(section,key,value);@defaults[[section,key]]=value;end
end
module Elfis
  module BastillePodmienFront
    extend self
    def l(pl,en);en;end
    def ui_label(value);value;end
  end
end
load '/workspace/elfis_bastille_podmien_front/order_stock.rb'
a=Elfis::BastillePodmienFront
checks=[];check=->(v,label){raise label unless v;checks<<label}
colour=[{key:'cashmere',name:'Cashmere'}]
rows=[]
[[79,[2400,1650,616,388]],[150,[1672.01,1549.99,1500,1202]]].each do |section,lengths|
  lengths.each do |length|
    id=rows.length
    rows<<{id:id,section:'endpanels',product_group:'plinths',stock_product:'Plinths',profile:"Part #{id}",type:'Plinths',source:'ELFIS',colours:colour,height:section,width:length,thickness:18,quantity:1,occurrence_ids:[-id-1],handle:'—'}
  end
end
check.call(a.order_stock_settings[:split_sections]==false,'Mixed widths are the default')
mixed=a.order_stock_plan(rows)
check.call(mixed[:groups].length==1,'79 and 150 mm use one product group')
check.call(mixed[:groups].first[:quantity]==6,'User example needs six whole stock lengths')
check.call(mixed[:groups].first[:section]==150,'Purchasing width is the widest required part')
check.call(mixed[:groups].first[:bars].any? { |b| b[:parts].map { |p| p[:section] }.uniq.length==2 },'Short narrow parts use wider-stock offcuts')
check.call(mixed[:groups].first[:bars].any? { |b| b[:parts].map { |p| p[:length] }.sort==[616,1672.01] },'616 mm narrow part fits the 1672.01 mm wider-part offcut')
refs=mixed[:groups].flat_map { |g| g[:bars].flat_map { |b| b[:parts].map { |p| p[:target_id] } } }
check.call(refs.sort==rows.flat_map { |r| r[:occurrence_ids] }.sort,'Every occurrence retained exactly once')
mixed[:groups].each do |g|
  g[:bars].each do |bar|
    check.call((bar[:parts].sum { |p| p[:length] }+bar[:waste]+bar[:cutting_loss]-2400).abs<0.02,'Cut lengths plus kerf and waste conserve stock')
  end
end
split=a.order_stock_plan(rows,{length:2400,kerf:3,split_sections:true})
check.call(split[:groups].length==2,'Split-width option restores two groups')
check.call(split[:groups].sum { |g| g[:quantity] }==7,'Split example needs three plus four lengths')
a.save_order_stock_settings(3000,4,true)
check.call(a.order_stock_settings=={length:3000.0,kerf:4.0,split_sections:true},'Length kerf and split option persist together')
a.save_order_stock_settings(2400,3,false)
check.call(a.order_stock_settings[:split_sections]==false,'Mixed mode can be restored')
%i[source thickness colours stock_product].each do |field|
  other=rows.first.dup;other[field]={source:'Other supplier',thickness:22,colours:[{key:'white',name:'White'}],stock_product:'Different product'}[field]
  check.call(a.order_stock_plan([rows.first,other])[:groups].length==2,"Different #{field} remain separate")
end
oversize=a.order_stock_plan([rows.first.merge(width:2500)])
check.call(oversize[:groups].first[:oversize].length==1,'Oversize part remains explicit')
fake_source=File.read('/workspace/elfis_bastille_podmien_front/order_list.rb')
check.call(fake_source.include?('save_order_stock_settings(data[:length],data[:kerf],data[:split_sections])'),'Ruby dialog callback forwards the checkbox')
Dir['/workspace/elfis_bastille_podmien_front/**/*.rb'].each { |file| RubyVM::InstructionSequence.compile_file(file) }
check.call(true,'All shipped Ruby compiles in Ruby 3.2')
load '/workspace/elfis_bastille_podmien_front/order_pdf.rb'
data={model:'Mixed-width plinth sample',rows:rows,handles:[],warnings:[],review_count:0}
File.binwrite('/workspace/output/pdf/order-2914-mixed.pdf',a::OrderPDF.new(data,'en').build)
a.save_order_stock_settings(2400,3,true)
File.binwrite('/workspace/output/pdf/order-2914-split.pdf',a::OrderPDF.new(data,'en').build)
File.write('/workspace/order_2914_fixture.json',JSON.pretty_generate(data.merge(stock:mixed,split_stock:split,total:8,profiles:[],suppliers:['ELFIS'],revision:1,include_endpanels:true,endpanels_present:true,include_handles:false,show_dimensions:true)))
File.write('/workspace/order_2914_calculation_results.json',JSON.pretty_generate({passed:true,ruby:RUBY_VERSION,checks:checks,mixed_lengths:6,separate_lengths:7,native_sketchup_test:'Not run; user requested no UI control.'}))
puts "PASS: #{checks.length} standalone Ruby calculation checks"
