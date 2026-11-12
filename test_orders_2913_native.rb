# encoding: UTF-8
require 'json'
require 'fileutils'
root=File.expand_path(__dir__)
FileUtils.mkdir_p(File.join(root,'output','pdf'))
a=Elfis::BastillePodmienFront
%w[i18n order_stock order_list order_pdf].each { |f| load File.join(root,'elfis_bastille_podmien_front',f+'.rb') }
checks=[];check=->(v,label){raise label unless v;checks<<label}
begin
  Dir[File.join(root,'elfis_bastille_podmien_front','**','*.rb')].each { |f| RubyVM::InstructionSequence.compile_file(f) }
  check.call(true,'All shipped Ruby files compile')
  parts=->(lengths){lengths.each_with_index.map { |v,i| {length:v,row_id:i,index:0,target_id:-i-1} }}
  [[ [1000,1000,1000,1000],2],[[1400,1400,900,900],2],[[1500,1500,1500],3],[[1198.5,1198.5],1],[[1200,1200],2],[[2400],1],[[2399],1]].each do |ls,n|
    plan=a.pack_order_stock(parts.call(ls),2400,3)
    check.call(plan[:bars].length==n && plan[:oversize].empty?,"Stock layout #{ls.inspect}")
    check.call(plan[:bars].all? { |b| (b[:parts].sum { |p| p[:length] }+b[:cutting_loss]+b[:waste]-2400).abs<0.011 },'Stock material balance')
  end
  check.call(a.pack_order_stock(parts.call([2401,500]),2400,3)[:oversize].length==1,'Oversize parts remain explicit')
  # Independent exhaustive oracle: small integer orders, no kerf, no model writes.
  oracle=->(ls,cap) do
    best=ls.length;bins=[];visit=nil
    visit=->(i) do
      if i==ls.length;best=[best,bins.length].min;return;end
      bins.length.times { |j| if bins[j]+ls[i]<=cap;bins[j]+=ls[i];visit.call(i+1);bins[j]-=ls[i];end }
      if bins.length+1<best;bins<<ls[i];visit.call(i+1);bins.pop;end
    end
    visit.call(0);best
  end
  rng=Random.new(2913)
  60.times do
    ls=Array.new(8){rng.rand(1..10)*100}
    plan=a.pack_order_stock(parts.call(ls),2400,0)
    raise 'Oracle mismatch' unless plan[:bars].length==oracle.call(ls,2400)
  end
  check.call(true,'60 random small layouts match independent exhaustive solver')
  started=Process.clock_gettime(Process::CLOCK_MONOTONIC)
  large=a.pack_order_stock(parts.call(Array.new(1000){rng.rand(100..2300)}),2400,3)
  elapsed=Process.clock_gettime(Process::CLOCK_MONOTONIC)-started
  check.call(large[:bars].sum { |b| b[:parts].length }==1000 && elapsed<5,'1000 parts conserve quantity within bounded runtime')

  model=Sketchup.active_model
  saved=%i[@order_dialog @order_snapshot @order_include_endpanels @order_include_handles @order_include_facade].to_h { |v| [v,a.instance_variable_get(v)] }
  dialog=Object.new;def dialog.execute_script(code);end
  a.instance_variable_set(:@order_dialog,dialog);a.instance_variable_set(:@order_include_endpanels,true)
  selection=model.selection.to_a
  model.start_operation('ELFIS 2.9.13 order test fixtures',true)
  begin
    folder=model.layers.add_folder('ELFIS 2913 fixtures');finish=folder.add_folder('Finishing')
    material=model.materials.to_a.find { |m| m.valid? }
    settings={id:'order-test',name:'ELFIS 2913 Slab',kind:'slab',thickness:18.0}
    fixtures=[]
    [['Plinths',1000,150,4],['End Panels',580,900,2],['Pelmets',1300,90,1],['Crowns',1400,110,1]].each_with_index do |(tag,w,h,qty),j|
      layer=model.layers.add('ELFIS 2913 '+tag);finish.add_layer(layer)
      d=a.build_door_definition(model,settings,w,h)
      qty.times do |i|
        e=model.entities.add_instance(d,Geom::Transformation.translation([(50000+j*3000).mm,0,(i*1200).mm]));e.layer=layer;e.name='ELFIS 2913 '+tag;e.material=material;fixtures<<e
      end
    end
    snapshot=a.refresh_order_list
    rows=snapshot[:rows].select { |r| r[:profile].start_with?('ELFIS 2913') }
    check.call(rows.length==4,'Finishing fixtures consolidated by dimensions')
    check.call(rows.map { |r| r[:product_group] }.sort==%w[crowns endpanels pelmets plinths],'Four finishing product types classified')
    data=snapshot.merge(model:'ELFIS sample order',rows:rows,handles:[],warnings:[],review_count:0,total:rows.sum { |r| r[:quantity] })
    data[:stock]=a.order_stock_plan(rows)
    check.call(data[:stock][:groups].first[:quantity]==2,'Four 1000 mm plinths require two whole lengths')
    separated=a.order_stock_plan(rows+[rows.find { |r| r[:product_group]=='plinths' }.merge(source:'Other supplier')])
    check.call(separated[:groups].length==2,'Different suppliers are not combined')
    original=rows.find { |r| r[:product_group]=='plinths' }
    mixed=a.order_stock_plan([original.merge(quantity:1,width:1400),original.merge(id:999,profile:'Different instance name',quantity:1,width:900)])
    check.call(mixed[:groups].length==1 && mixed[:groups].first[:quantity]==1,'Different named parts of one tag/product share stock')
    different=a.order_stock_plan([original,original.merge(thickness:22),original.merge(colours:[{key:'different',name:'Different colour'}])])
    check.call(different[:groups].length==3,'Different colours and thicknesses stay separate')
    nominal=a.order_stock_plan([original.merge(quantity:1,width:1400),original.merge(id:999,quantity:1,height:150.01,width:900)])
    check.call(nominal[:groups].length==1 && nominal[:groups].first[:quantity]==1,'Nominal 0.1 mm sections ignore tiny import noise')
    g=data[:stock][:groups].first;ref=g[:bars].first[:parts].first[:target_id]
    check.call(a.highlight_order_row([ref],snapshot[:revision])==1,'A stock-tree part highlights only one occurrence')
    check.call(model.tools.active_tool.is_a?(a::OrderHighlightTool),'Preview tool receives viewport Escape')
    model.tools.active_tool.onCancel(0,model.active_view)
    check.call(a.instance_variable_get(:@order_overlay).boxes.empty?,'Escape clears overlay')
    check.call(!model.tools.active_tool.is_a?(a::OrderHighlightTool),'Escape restores previous tool')
    text=a.order_list_text(data)
    check.call(text.include?('1000') && text.include?('2400') && text.include?(a.order_group_label('plinths')),'Clipboard includes stock layouts and product groups')
    %w[en pl].each do |lang|
      File.binwrite(File.join(root,'output','pdf',"order-2913-#{lang}.pdf"),a::OrderPDF.new(data,lang).build)
    end
    File.write(File.join(root,'order_2913_fixture.json'),JSON.pretty_generate(data))
  ensure
    a.clear_order_highlight
    model.abort_operation
    model.selection.clear;model.selection.add(selection.select(&:valid?))
    saved.each { |v,value| a.instance_variable_set(v,value) }
  end
  File.write(File.join(root,'order_2913_native_results.json'),JSON.pretty_generate({passed:true,checks:checks,large_order_seconds:elapsed,version:a::VERSION}))
  puts "PASS: #{checks.length} order checks"
rescue Exception=>error
  File.write(File.join(root,'order_2913_native_results.json'),JSON.pretty_generate({passed:false,error:error.message,backtrace:error.backtrace.first(8),checks:checks}))
  raise
end
