'use strict';
const orderPL=document.documentElement.lang==='pl';
const ol=(pl,en)=>orderPL?pl:en;
const productOrder=['fronts','plinths','endpanels','pelmets','crowns','other'];
const groupNames={fronts:ol('Fronty','Fronts'),plinths:ol('Cokoły','Plinths'),endpanels:ol('Panele kończące','End Panels'),pelmets:ol('Pelmety','Pelmets'),crowns:ol('Gzymsy','Crowns'),other:ol('Pozostałe Finishing','Other Finishing')};
let stockSelection=[],escapePending=false;
const baseBusy=setBusy;
setBusy=function(value){baseBusy(value);for(const id of ['sort-size','sort-direction','stock-length','stock-kerf','stock-split','stock-apply'])$(id).disabled=value;$('clear').disabled=value||(!selectedIds.size&&!stockSelection.length)};
function rowGroup(row){return row.section==='endpanels'?(row.product_group||'other'):'fronts'}
function orderedRows(){
 const field=$('sort-size').value||'height',sign=$('sort-direction').value==='desc'?-1:1;
 return filteredOrderRows().sort((a,b)=>productOrder.indexOf(rowGroup(a))-productOrder.indexOf(rowGroup(b))||sign*((Number(a[field])||0)-(Number(b[field])||0))||a.height-b.height||a.width-b.width||a.profile.localeCompare(b.profile)||a.id-b.id);
}
const baseRenderRows=renderOrderRows;
renderOrderRows=function(){
 baseRenderRows();
 const rows=orderedRows(),visible=new Map([...$('rows').children,...$('endpanels-rows').children].filter(r=>r.dataset.id!==undefined).map(r=>[Number(r.dataset.id),r]));
 $('rows').replaceChildren();$('endpanels-rows').replaceChildren();
 let group='';
 for(const item of rows){
  const tr=visible.get(item.id);if(!tr)continue;
  if(item.section==='endpanels'){
   if(rowGroup(item)==='plinths')continue;
   if(group!==rowGroup(item)){group=rowGroup(item);const heading=document.createElement('tr');heading.className='product-heading';const td=cell(heading,groupNames[group]);td.colSpan=9;$('endpanels-rows').append(heading)}
   $('endpanels-rows').append(tr);
  }else $('rows').append(tr);
  // Quantity precedes the three dimensions in every product table.
  tr.insertBefore(tr.children[5],tr.children[2]);tr.children[2].classList.add('quantity');
 }
 const panels=rows.filter(r=>r.section==='endpanels'&&rowGroup(r)!=='plinths');
 $('endpanels-table').hidden=!panels.length;
 $('endpanels-empty').hidden=rows.some(r=>r.section==='endpanels');
 renderStockTree();
};
const baseRenderList=renderOrderList;
renderOrderList=function(data){
 if(data.sort){$('sort-size').value=data.sort.field;$('sort-direction').value=data.sort.direction}
 if(data.stock){$('stock-length').value=data.stock.settings.length;$('stock-kerf').value=data.stock.settings.kerf;$('stock-split').checked=data.stock.settings.split_sections===true}
 stockSelection=[];baseRenderList(data);
 if(['filter-profile','filter-colour','filter-source'].some(id=>$(id).value))send('filter_stock',{ids:filteredOrderRows().map(r=>r.id),revision:lastData.revision});
};
selectOrderRow=function(id,event={}){
 if(busy||!lastData)return;
 const ids=nextOrderSelection(orderedRows().filter(r=>rowGroup(r)!=='plinths').map(r=>r.id),selectedIds,anchorId,id,event);
 if(!event.shiftKey||anchorId===null)anchorId=id;
 send('highlight',{ids,revision:lastData.revision});
};
const baseHighlighted=setOrderHighlighted;
setOrderHighlighted=function(ids,count){
 const list=ids===null?[]:Array.isArray(ids)?ids:[ids];stockSelection=list.filter(id=>id<0);
 baseHighlighted(list.filter(id=>id>=0),count);
 for(const node of document.querySelectorAll('[data-targets]')){const targets=JSON.parse(node.dataset.targets);node.classList.toggle('selected',targets.length>0&&targets.every(id=>stockSelection.includes(id)))}
 $('clear').disabled=busy||(!selectedIds.size&&!stockSelection.length);
};
const baseStatus=setOrderStatus;
setOrderStatus=function(message){baseStatus(message);$('clear').disabled=busy||(!selectedIds.size&&!stockSelection.length);if(escapePending){escapePending=false;send('clear_highlight')}};
function stockHighlight(parts){const ids=parts.map(p=>p.target_id).filter(Number.isInteger);if(ids.length)send('highlight',{ids,revision:lastData.revision})}
function renderStockTree(){
 const tree=$('stock-tree');tree.replaceChildren();
 const visible=new Set(filteredOrderRows().map(r=>r.id));
 const groups=(lastData?.stockVisible?.groups||lastData?.stock?.groups||[]).filter(g=>[...g.bars.flatMap(b=>b.parts),...g.oversize].some(p=>visible.has(p.row_id)));
 tree.hidden=!groups.length;
 const settings=lastData?.stock?.settings;if(!settings)return;
 for(const g of groups){
  const section=document.createElement('div');section.className='stock-product';
  const title=document.createElement('h3');title.textContent=`${groupNames.plinths} · ${g.product} · ${g.colours.map(c=>c.name).join(' / ')} · ${g.source} · ${g.section} × ${g.thickness} mm`;section.append(title);
  const summary=document.createElement('p'),qty=document.createElement('strong');qty.textContent=`${g.quantity} ${ol('szt.','pcs')}`;summary.append(qty,document.createTextNode(` × ${settings.length} mm · ${ol('rzaz','kerf')} ${settings.kerf} mm`));section.append(summary);
  if(!g.optimal){const note=document.createElement('p');note.className='muted';note.textContent=ol('Układ przybliżony — minimalna liczba listew nie została potwierdzona.','Approximate layout — minimum stock count not proven.');section.append(note)}
  g.bars.forEach((bar,i)=>{
   const details=document.createElement('details'),head=document.createElement('summary');
   const label=document.createElement('span');label.textContent=`${ol('Listwa','Stock')} ${i+1} — ${settings.length} mm`;
   const show=document.createElement('button');show.type='button';show.textContent=ol('Podświetl części','Highlight parts');show.dataset.targets=JSON.stringify(bar.parts.map(p=>p.target_id).filter(Number.isInteger));
   show.onclick=e=>{e.preventDefault();e.stopPropagation();stockHighlight(bar.parts)};head.append(label,show);details.append(head);
   for(const part of bar.parts){const button=document.createElement('button');button.className='stock-part';button.textContent=`1 × ${part.length}${part.section!==undefined?' × '+part.section:''} mm`;button.dataset.targets=JSON.stringify(Number.isInteger(part.target_id)?[part.target_id]:[]);button.onclick=()=>stockHighlight([part]);details.append(button)}
   const waste=document.createElement('p');waste.className='muted';waste.textContent=`${ol('Odpad','Waste')}: ${bar.waste} mm · ${ol('Strata na cięciu','Cutting loss')}: ${bar.cutting_loss} mm`;details.append(waste);section.append(details);
  });
  for(const part of g.oversize){const warn=document.createElement('p');warn.className='stock-error';warn.textContent=`⚠ ${ol('Odcinek nie mieści się w listwie','Part does not fit stock')}: ${part.length} mm`;section.append(warn)}
  tree.append(section);
 }
}
function setOrderStock(stock){lastData.stockVisible=stock;renderStockTree();setOrderStatus(ol('Zaktualizowano filtry i listwy.','Filters and stock updated.'))}
filtersChanged=function(){selectedIds.clear();stockSelection=[];anchorId=null;pendingZoom=null;renderOrderRows();send('filter_stock',{ids:filteredOrderRows().map(r=>r.id),revision:lastData.revision})};
for(const id of ['filter-profile','filter-colour','filter-source'])$(id).onchange=filtersChanged;
for(const id of ['sort-size','sort-direction'])$(id).onchange=()=>{if(busy)return;renderOrderRows();renderHandleRows();send('sort',{field:$('sort-size').value,direction:$('sort-direction').value})};
const baseHandleRows=renderHandleRows;
renderHandleRows=function(){
 baseHandleRows();
 const field=$('sort-size').value==='width'?'length':'pitch',sign=$('sort-direction').value==='desc'?-1:1;
 const ordered=visibleHandleRows().map((item,index)=>({item,node:$('handles-rows').children[index]})).sort((a,b)=>sign*((Number(a.item[field])||0)-(Number(b.item[field])||0))||a.item.name.localeCompare(b.item.name));
 $('handles-rows').replaceChildren();
 for(const {node} of ordered){node.insertBefore(node.children[7],node.children[2]);node.children[2].classList.add('quantity');$('handles-rows').append(node)}
};
function saveStockSettings(){send('stock_settings',{length:Number($('stock-length').value),kerf:Number($('stock-kerf').value),split_sections:$('stock-split').checked})}
$('stock-apply').onclick=saveStockSettings;
$('stock-split').onchange=saveStockSettings;
document.addEventListener('keydown',event=>{if(event.key!=='Escape')return;event.preventDefault();if(busy)escapePending=true;else send('clear_highlight')});
// Reorder existing headers to match quantity-before-dimensions cells.
for(const id of ['table','endpanels-table']){const row=$(id).tHead.rows[0];row.insertBefore(row.children[5],row.children[2])}
{const row=$('handles-table').tHead.rows[0];row.insertBefore(row.children[7],row.children[2])}
