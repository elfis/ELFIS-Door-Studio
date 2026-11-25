(() => {
 'use strict';
 const $=id=>document.getElementById(id),NS='http://www.w3.org/2000/svg';
 let data=null,excluded=new Set(),reversed=false,svg=null,timer=null;
 const settingIds=['drawingMode','title','note','paper','scale','fronts','hardware','finishing','backEdges','dimensions','unitHeights','levelHeights','shelfGaps','frontDimensions','hingeDimensions','names','xray','colours','technical','hidden'];
 const fmt=n=>Math.abs(n-Math.round(n))<.06?String(Math.round(n)):n.toFixed(1).replace('.',',');
 function el(tag,attrs={},parent=svg){const node=document.createElementNS(NS,tag);for(const [k,v]of Object.entries(attrs))node.setAttribute(k,String(v));if(parent)parent.appendChild(node);return node;}
 function text(x,y,value,size=12,attrs={}){const node=el('text',{x,y,'font-size':size,...attrs});node.textContent=value;return node;}
 function line(x1,y1,x2,y2,attrs={}){return el('line',{x1,y1,x2,y2,stroke:'#444','stroke-width':.7,...attrs});}
 function printFont(points){return points*25.4/72*1200/parseFloat(svg.getAttribute('width'));}
 function bounds(points){return points.reduce((b,p)=>[Math.min(b[0],p[0]),Math.min(b[1],p[1]),Math.max(b[2],p[0]),Math.max(b[3],p[1])],[Infinity,Infinity,-Infinity,-Infinity]);}
 function area(loop){return Math.abs(loop.reduce((sum,p,i)=>{const q=loop[(i+1)%loop.length];return sum+p[0]*q[1]-q[0]*p[1]},0))*.5;}
 function busy(){ $('status').textContent='Wczytywanie geometrii…';$('status').className=''; }
 function fail(message){$('status').textContent=message;$('status').className='error';}
 function schedule(){clearTimeout(timer);timer=setTimeout(render,50);}
 function rows(){
  const view=data.views.find(v=>v.id===$('direction').value);$('cabinets').replaceChildren();
  const roots=$('drawingMode').value==='elevation'?data.roots.filter(r=>view.roots.includes(r.id)):data.roots;$('count').textContent=`(${roots.length})`;
  for(const r of roots){const label=document.createElement('label');label.className='check cabinet-row';const cb=document.createElement('input');cb.type='checkbox';cb.checked=!excluded.has(r.id);cb.addEventListener('change',()=>{cb.checked?excluded.delete(r.id):excluded.add(r.id);schedule()});const name=document.createElement('span');name.textContent=r.name||r.id;label.append(cb,name);$('cabinets').append(label);}
 }
 function drillingPanel(fronts){
  const host=$('drillingRows');if(!host)return;host.replaceChildren();
  if(!fronts.length){const empty=document.createElement('p');empty.className='drilling-empty';empty.textContent='Brak wierceń w wybranych frontach.';host.append(empty);return;}
  const groups=[];fronts.forEach(front=>{let group=groups.find(g=>g.root===front.root);if(!group){group={root:front.root,fronts:[]};groups.push(group)}group.fronts.push(front)});
  groups.forEach(group=>{
   const root=data.roots.find(r=>r.id===group.root),name=root?.name||group.root,unit=document.createElement('h3');unit.className='drilling-unit';unit.textContent=/^szafka\b/i.test(name)?name:`Szafka ${name}`;host.append(unit);
   group.fronts.forEach(front=>{
   const card=document.createElement('section');card.className='drilling-card';
   const heading=document.createElement('h3');heading.textContent=front.name||'Front';
   const size=document.createElement('span');size.textContent=`${fmt(front.drilling.height)} × ${fmt(front.drilling.width)} mm`;heading.append(size);card.append(heading);
   front.drilling.holes.forEach(hole=>{
    const row=document.createElement('div');row.className='drilling-hole';
    const title=document.createElement('strong');title.textContent=`Ø${fmt(hole.diameter)} × ${fmt(hole.depth)}`;
    const horizontal=document.createElement('span');horizontal.textContent=`L ${fmt(hole.left)} · P ${fmt(hole.right)}`;
    const vertical=document.createElement('span');vertical.textContent=`D ${fmt(hole.bottom)} · G ${fmt(hole.top)}`;
    row.append(title,horizontal,vertical);card.append(row);
   });host.append(card);
   });
  });
 }
 function drillingTable(fronts,x,y,width,accent,muted){
  const stroke='#8f999d',rowH=8;
  const items=fronts.filter(front=>front.drilling?.holes?.length).sort((a,b)=>{
   const az=Math.min(...(a.points||[]).map(p=>p[2])),bz=Math.min(...(b.points||[]).map(p=>p[2]));return az-bz;
  });
  if(!items.length)return;
  const groups=[];items.forEach(front=>{let group=groups.find(g=>g.root===front.root);if(!group){group={root:front.root,fronts:[]};groups.push(group)}group.fronts.push(front)});
  groups.forEach(group=>{
  const root=data.roots.find(r=>r.id===group.root),name=root?.name||group.root,label=/^szafka\b/i.test(name)?name:`SZAFKA ${name}`;text(x,y,label.toUpperCase(),7.2,{'font-weight':'700',fill:accent});y+=11;
   el('rect',{x,y,width,height:20,fill:'#ececea',stroke:'none'});
   text(x+3,y+13,'Poz.',5.2,{'font-weight':'700'});
   text(x+31,y+8,'Wys.',5.2,{'font-weight':'700'});text(x+31,y+15,'frontu',5.2,{'font-weight':'700'});
   text(x+73,y+8,'Od',5.2,{'font-weight':'700'});text(x+73,y+15,'dolu',5.2,{'font-weight':'700'});
   text(x+116,y+13,'Lewa',5.2,{'font-weight':'700'});text(x+166,y+13,'Prawa',5.2,{'font-weight':'700'});
   y+=20;line(x,y,x+width,y,{stroke,'stroke-width':.7});
  group.fronts.forEach((front,index)=>{
   const position=index+1;
   const holes=front.drilling.holes.filter(h=>h.bottom<=h.top+.05);
   const rows=[];
   holes.sort((a,b)=>a.bottom-b.bottom||a.left-b.left).forEach(h=>{
    const side=h.left<=h.right?'left':'right';
    const key=h.bottom.toFixed(2);let row=rows.find(r=>r.key===key);
    if(!row){row={key,below:h.bottom,left:null,right:null};rows.push(row)}
    row[side]=Math.min(h.left,h.right);
   });
   const blockRows=Math.max(1,rows.length),blockH=blockRows*rowH+2;
   text(x+5,y+7,String(position),5.8,{fill:'#111'});
   text(x+31,y+7,fmt(front.drilling.height),5.8,{'font-weight':'700',fill:'#111'});
   rows.forEach((r,i)=>{
    const yy=y+7+i*rowH;
    text(x+73,yy,fmt(r.below),5.8,{fill:'#111'});
    text(x+116,yy,r.left==null?'-':fmt(r.left),5.8,{fill:'#111'});
    text(x+166,yy,r.right==null?'-':fmt(r.right),5.8,{fill:'#111'});
   });
   y+=blockH;line(x,y,x+width,y,{stroke:'#8f999d','stroke-width':.55});
  });y+=12;
  });
 }
 function dimH(x1,x2,y,ref1,ref2,value,bold=false){if(x2-x1<5)return;line(x1,ref1,x1,y+5,{stroke:'#aaa','stroke-width':.45});line(x2,ref2,x2,y+5,{stroke:'#aaa','stroke-width':.45});line(x1,y,x2,y);for(const x of [x1,x2])line(x-3,y+4,x+3,y-4);text((x1+x2)/2,y-6,value,printFont(bold?10:8),{'text-anchor':'middle','font-weight':bold?'700':'400',fill:'#111','data-dimension-font':bold?'total':'width'});}
 function dimV(x,y1,y2,ref,value,unit=null){
  line(ref,y1,x+4,y1,{stroke:'#888','stroke-width':.45});line(ref,y2,x+4,y2,{stroke:'#888','stroke-width':.45});line(x,y1,x,y2,{stroke:'#555','stroke-width':.6});
  for(const y of [y1,y2])line(x-3,y+3,x+3,y-3);
  const tx=unit?x+9:x-9,cy=(y1+y2)/2;
  text(tx,cy,value,printFont(unit?6:10),{'text-anchor':'middle','dominant-baseline':'middle',transform:`rotate(-90 ${tx} ${cy})`,'font-weight':unit?'400':'700','paint-order':'stroke',stroke:'white','stroke-width':3,'stroke-opacity':.9,fill:'#111',...(unit?{'data-unit-height':unit}:{'data-total-height':'true'})});
 }
 function hull(points){
  const pts=[...new Map(points.map(p=>[`${p[0].toFixed(4)},${p[1].toFixed(4)}`,p])).values()].sort((a,b)=>a[0]-b[0]||a[1]-b[1]);
  if(pts.length<3)return pts;
  const cross=(o,a,b)=>(a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0]),lower=[],upper=[];
  for(const p of pts){while(lower.length>1&&cross(lower.at(-2),lower.at(-1),p)<=0)lower.pop();lower.push(p)}
  for(let i=pts.length-1;i>=0;i--){const p=pts[i];while(upper.length>1&&cross(upper.at(-2),upper.at(-1),p)<=0)upper.pop();upper.push(p)}
  return lower.slice(0,-1).concat(upper.slice(0,-1));
 }
 function renderPlan(){
  const roots=data.roots.filter(r=>!excluded.has(r.id)).map(r=>{
   const source=(r.body_points?.length?r.body_points:r.points)||[],plan=hull(source.map(p=>[p[0],p[1]])),axes=r.plan_axes||[[1,0],[0,1]];
   const dimension=axis=>{const values=source.map(p=>p[0]*axis[0]+p[1]*axis[1]);return values.length?Math.max(...values)-Math.min(...values):0};
   return {...r,plan,planWidth:dimension(axes[0]),planDepth:dimension(axes[1])};
  }).filter(r=>r.plan.length>2);
  if(!roots.length){$('drawing').replaceChildren();$('save').disabled=$('print').disabled=true;fail('Brak szafek do rzutu. Wczytaj zaznaczenie ze SketchUpa.');return;}
  const base=bounds(roots.flatMap(r=>r.plan)),rotate=base[3]-base[1]>base[2]-base[0],turn=p=>rotate?[-p[1],p[0]]:p;
  const turned=roots.map(r=>({...r,plan:r.plan.map(turn)})),bb=bounds(turned.flatMap(r=>r.plan)),mw=bb[2]-bb[0],mh=bb[3]-bb[1];
  if(mw<.1||mh<.1){fail('Zaznaczenie nie tworzy czytelnego rzutu z góry.');return;}
  const pageW=$('paper').value==='A3'?420:297,pageH=$('paper').value==='A3'?297:210,sheetW=Math.min(pageW-4,(pageH-4)*1200/848);
  const left=45,top=75,width=1110,height=610,auto=Math.min(width/mw,height/mh),requested=$('scale').value==='auto'?null:Number($('scale').value),factor=requested?1200/sheetW/requested:auto,over=factor*mw>width||factor*mh>height;
  const ox=left+(width-mw*factor)/2,oy=top+(height-mh*factor)/2,point=p=>[ox+(p[0]-bb[0])*factor,oy+(bb[3]-p[1])*factor];
  const technical=$('technical').checked,xray=$('xray').checked,accent=technical?'#30383b':'#16736d',muted=technical?'#60696c':'#667780';
  svg=el('svg',{xmlns:NS,viewBox:'0 0 1200 848',width:sheetW+'mm',height:(sheetW*848/1200)+'mm',role:'img','font-family':'Arial, sans-serif','aria-label':'Rzut szafek z góry'},null);
  el('rect',{width:1200,height:848,fill:'#fcfdfd'});el('rect',{x:.5,y:.5,width:1199,height:847,fill:'none',stroke:technical?'#777':'#9aa9ad','stroke-width':.8});el('rect',{x:8,y:8,width:5,height:45,fill:accent});
  text(22,29,$('title').value||`${data.project} — Rzut szafek`,13,{'font-weight':'700',fill:'#202b31'});text(22,45,`Rzut z góry · ${roots.length} elementów · oznaczenia z modelu`,7.5,{fill:muted});
  const layer=el('g',{'stroke-linejoin':'round'});
  for(const root of turned){
   const polygon=root.plan.map(point),d=polygon.map((p,i)=>(i?'L':'M')+p.map(v=>v.toFixed(3)).join(',')).join(' ')+'Z';
   el('path',{d,fill:technical?'#fff':'#f2f6f5',stroke:'#26363c','stroke-width':1.15,'data-plan-root':root.id},layer);
   const centre=polygon.reduce((s,p)=>[s[0]+p[0]/polygon.length,s[1]+p[1]/polygon.length],[0,0]),name=root.name||'',font=Math.min(18,Math.max(9,Math.sqrt(Math.abs(area(polygon)))/9));
   if(name)text(centre[0],centre[1]-2,name,font,{'text-anchor':'middle','font-weight':'700',fill:'#202b31','paint-order':'stroke',stroke:'white','stroke-width':4,'stroke-opacity':.95,'data-plan-label':root.id});
   text(centre[0],centre[1]+font+3,`${fmt(root.planWidth)} × ${fmt(root.planDepth)}`,Math.max(7,font*.62),{'text-anchor':'middle',fill:'#43545a','paint-order':'stroke',stroke:'white','stroke-width':3,'stroke-opacity':.95,'data-plan-size':root.id});
  }
  line(.5,715,1199,715,{stroke:technical?'#777':'#9aa9ad','stroke-width':.8});text(22,738,'ELFIS · Rzut szafek',11,{'font-weight':'700',fill:accent});text(22,756,`Projekt: ${data.project}`,8.5);text(22,772,'Układ według rzeczywistych współrzędnych modelu',7.5,{fill:muted});
  const denom=1200/sheetW/factor;text(930,738,`Skala 1:${fmt(denom)}${requested?'':' dop.'}`,8);text(930,754,`${$('paper').value} poziomo · ${data.date} · v${data.version}`,7.5);
  $('drawing').replaceChildren(svg);$('save').disabled=$('print').disabled=over;$('status').textContent=over?'Wybrana skala nie mieści się na arkuszu.':`${roots.length} elementów · rzut z góry · skan ${data.elapsed} s.`;$('status').className=over?'error':'';drillingPanel([]);
 }
 function renderCabinet3d(){
  const roots=data.roots.filter(r=>!excluded.has(r.id));
  if(roots.length!==1){$('drawing').replaceChildren();$('save').disabled=$('print').disabled=true;fail(`Widok 3D wymaga jednej szafki. Na liście pozostaw zaznaczoną jedną pozycję (obecnie ${roots.length}).`);drillingPanel([]);return;}
  const root=roots[0],axes=root.plan_axes||[[1,0],[0,1]],local=p=>[p[0]*axes[0][0]+p[1]*axes[0][1],p[0]*axes[1][0]+p[1]*axes[1][1],p[2]];
  const project=p=>{const q=local(p);return[(q[0]-q[1])*.866,(q[0]+q[1])*.5-q[2],q[0]+q[1]+q[2]*.35]};
  const surfaces=data.faces.filter(f=>f.root===root.id&&($('finishing').checked||!f.finishing)&&($('hardware').checked||!f.hardware)&&($('fronts').checked||!f.front)).map(f=>{
   const loops=f.loops.map(loop=>loop.map(project)),flat=loops.flat();return{f,loops,depth:flat.reduce((sum,p)=>sum+p[2],0)/Math.max(1,flat.length)};
  }).filter(s=>s.loops.length&&area(s.loops[0])>.05).sort((a,b)=>a.depth-b.depth);
  const projected=surfaces.flatMap(s=>s.loops.flat()),bb=bounds(projected),mw=bb[2]-bb[0],mh=bb[3]-bb[1];
  if(!projected.length||mw<.1||mh<.1){fail('Brak geometrii szafki do widoku 3D.');return;}
  const pageW=$('paper').value==='A3'?420:297,pageH=$('paper').value==='A3'?297:210,sheetW=Math.min(pageW-4,(pageH-4)*1200/848),left=45,top=70,width=825,height=610,factor=Math.min(width/mw,height/mh),ox=left+(width-mw*factor)/2,oy=top+(height-mh*factor)/2,point=p=>[ox+(p[0]-bb[0])*factor,oy+(p[1]-bb[1])*factor];
  const technical=$('technical').checked,accent=technical?'#30383b':'#16736d',muted=technical?'#60696c':'#667780';
  svg=el('svg',{xmlns:NS,viewBox:'0 0 1200 848',width:sheetW+'mm',height:(sheetW*848/1200)+'mm',role:'img','font-family':'Arial, sans-serif','aria-label':'Widok 3D pojedynczej szafki'},null);
  el('rect',{width:1200,height:848,fill:'#fcfdfd'});el('rect',{x:.5,y:.5,width:1199,height:847,fill:'none',stroke:technical?'#777':'#9aa9ad','stroke-width':.8});el('rect',{x:8,y:8,width:5,height:45,fill:accent});
  const body=root.body_points?.length?root.body_points:root.points,values=(axis,index)=>body.map(p=>axis?p[0]*axis[0]+p[1]*axis[1]:p[index]),extent=(axis,index)=>{const v=values(axis,index);return Math.max(...v)-Math.min(...v)},cabinetWidth=extent(axes[0]),cabinetDepth=extent(axes[1]),cabinetHeight=extent(null,2);
  text(22,29,$('title').value||`${root.name||data.project} — Widok 3D`,13,{'font-weight':'700',fill:'#202b31'});text(22,45,`${root.name||'Szafka'} · ${fmt(cabinetWidth)} × ${fmt(cabinetDepth)} × ${fmt(cabinetHeight)} mm · aksonometria${xray?' · X-ray':''}`,7.5,{fill:muted});
  const layer=el('g',{'stroke-linejoin':'round'});
  for(const {f,loops}of surfaces){const d=loops.map(loop=>loop.map((p,i)=>{const q=point(p);return(i?'L':'M')+q.map(v=>v.toFixed(3)).join(',')}).join(' ')+'Z').join(' ');el('path',{d,fill:technical?'#fff':$('colours').checked?f.colour:(f.hardware?'#d7dcde':'#f6f8f7'),'fill-opacity':xray ? (f.hardware ? .42 : .16) : 1,'fill-rule':'evenodd',stroke:f.hardware?'#566268':'#343b3e','stroke-width':f.hardware ? .62 : .78,'stroke-opacity':xray ? .82 : 1,'data-3d-surface':root.id},layer);}
  line(895,.5,895,715,{stroke:technical?'#777':'#9aa9ad','stroke-width':.8});
  let infoY=24;const infoX=912,infoW=270,section=label=>{text(infoX,infoY,label.toUpperCase(),7.2,{'font-weight':'700',fill:accent});infoY+=9;line(infoX,infoY,infoX+infoW,infoY,{stroke:'#aeb8bb','stroke-width':.55});infoY+=11};
  section('Gabaryt');text(infoX,infoY,`Szerokość  ${fmt(cabinetWidth)} mm`,7);infoY+=11;text(infoX,infoY,`Głębokość  ${fmt(cabinetDepth)} mm`,7);infoY+=11;text(infoX,infoY,`Wysokość  ${fmt(cabinetHeight)} mm`,7);infoY+=17;
  if($('frontDimensions').checked){
   const cabinetFronts=data.fronts.filter(front=>front.root===root.id&&front.points?.length);section('Fronty');
   cabinetFronts.sort((a,b)=>Math.min(...a.points.map(p=>p[2]))-Math.min(...b.points.map(p=>p[2]))).forEach((front,index)=>{const length=front.normal?Math.hypot(front.normal[0],front.normal[1]):0,tangent=length>1e-6?[-front.normal[1]/length,front.normal[0]/length,0]:[1,0,0],us=front.points.map(p=>p[0]*tangent[0]+p[1]*tangent[1]),zs=front.points.map(p=>p[2]),fw=Math.max(...us)-Math.min(...us),fh=Math.max(...zs)-Math.min(...zs),fromBottom=Math.min(...zs)-Math.min(...body.map(p=>p[2]));text(infoX,infoY,`${index+1}. ${fmt(fh)} × ${fmt(fw)} · od dołu ${fmt(fromBottom)} mm`,6.5);infoY+=10;});infoY+=7;
  }
  if($('shelfGaps').checked&&(root.shelf_gaps||[]).length){section('Rozstawienie półek');const bottom=Math.min(...body.map(p=>p[2])),gaps=root.shelf_gaps.slice().sort((a,b)=>Math.min(a.from[2],a.to[2])-Math.min(b.from[2],b.to[2]));gaps.forEach((gap,index)=>{const level=Math.min(gap.from[2],gap.to[2])-bottom;text(infoX,infoY,`${index+1}. prześwit ${fmt(gap.value)} · od dołu ${fmt(level)} mm`,6.4);infoY+=9;});infoY+=7;}
  if($('unitHeights').checked&&(root.unit_heights||[]).length){section('Podziały wysokości');root.unit_heights.slice().sort((a,b)=>a.from-b.from).forEach((part,index)=>{text(infoX,infoY,`${index+1}. ${fmt(part.value)} mm`,6.6);infoY+=9;});infoY+=7;}
  if($('hingeDimensions').checked&&(root.hinges||[]).length){section('Zawiasy');const bottom=Math.min(...body.map(p=>p[2])),offsets=[...new Set(root.hinges.map(h=>fmt(h[2]-bottom)))];text(infoX,infoY,'Od dołu: '+offsets.join(' · ')+' mm',6.8);infoY+=17;}
  const scheduleFronts=data.fronts.filter(front=>{const holes=front.drilling?.holes||[],hasHingeCup=holes.some(h=>h.diameter>=30&&h.diameter<=40);return front.root===root.id&&holes.length&&!hasHingeCup;});
  if(scheduleFronts.length){section('Pozostałe wiercenia frontów');drillingTable(scheduleFronts,infoX,infoY,infoW,accent,muted);}
  line(.5,715,1199,715,{stroke:technical?'#777':'#9aa9ad','stroke-width':.8});text(22,738,'ELFIS · Widok 3D szafki',11,{'font-weight':'700',fill:accent});text(22,756,`Projekt: ${data.project}`,8.5);text(22,773,`Szafka: ${root.name||root.id}`,8.5);text(760,738,`S × G × W: ${fmt(cabinetWidth)} × ${fmt(cabinetDepth)} × ${fmt(cabinetHeight)} mm`,8);text(760,756,`${$('paper').value} poziomo · ${data.date} · v${data.version}`,7.5);
  $('drawing').replaceChildren(svg);$('save').disabled=$('print').disabled=false;$('status').textContent=`${root.name||'Szafka'} · ${surfaces.length} powierzchni · widok 3D · skan ${data.elapsed} s.`;$('status').className='';drillingPanel(scheduleFronts);
 }
 function render(){
  if(!data)return;
  if($('drawingMode').value==='plan'){renderPlan();return;}
  if($('drawingMode').value==='cabinet3d'){renderCabinet3d();return;}
  const view=data.views.find(v=>v.id===$('direction').value);if(!view)return;
  const normal=view.normal.map(v=>v*(reversed?-1:1)),u=[-normal[1],normal[0],0];
  const project=p=>[p[0]*u[0]+p[1]*u[1],-p[2],p[0]*normal[0]+p[1]*normal[1]];
  const roots=data.roots.filter(r=>view.roots.includes(r.id)&&!excluded.has(r.id)).map(r=>({...r,points:$('finishing').checked?r.points:(r.body_points||r.points)})).filter(r=>r.points.length);
  const ids=new Set(roots.map(r=>r.id));
  if(!roots.length){$('drawing').replaceChildren();$('save').disabled=$('print').disabled=true;fail('Brak szafek w widoku. Zaznacz przynajmniej jedną pozycję.');return;}
  const bb=bounds(roots.flatMap(r=>r.points.map(project))),mw=bb[2]-bb[0],mh=bb[3]-bb[1];
  if(mw<.1||mh<.1){fail('Wybrana geometria nie ma wystarczającej szerokości lub wysokości.');return;}
  const scheduleFronts=data.fronts.filter(front=>{
   const holes=front.drilling?.holes||[],hasHingeCup=holes.some(hole=>hole.diameter>=30&&hole.diameter<=40);
   return ids.has(front.root)&&holes.length&&!hasHingeCup;
  });
  const scheduleHoleCount=scheduleFronts.reduce((sum,front)=>sum+(front.drilling?.holes?.length||0),0),compactSchedule=scheduleFronts.length<=6&&scheduleHoleCount<=24;
  const pageW=$('paper').value==='A3'?420:297,pageH=$('paper').value==='A3'?297:210;
  const sheetW=Math.min(pageW-4,(pageH-4)*1200/848),drawingLeft=34,drawingWidth=compactSchedule?1120:870,drawingTop=compactSchedule?145:55,drawingHeight=compactSchedule?525:570,auto=Math.min(drawingWidth/mw,drawingHeight/mh);
  const requested=$('scale').value==='auto'?null:Number($('scale').value);
  const factor=requested?1200/sheetW/requested:auto;
  const over=factor*mw>drawingWidth||factor*mh>drawingHeight;
  const ox=drawingLeft+(drawingWidth-mw*factor)/2,oy=drawingTop+(drawingHeight-mh*factor)/2;
  const point=p=>[ox+(p[0]-bb[0])*factor,oy+(p[1]-bb[1])*factor];
  const technical=$('technical').checked,accent=technical?'#30383b':'#16736d',accentText=technical?'#202b31':'#124f4c',muted=technical?'#60696c':'#667780';
  svg=el('svg',{xmlns:NS,viewBox:'0 0 1200 848',width:sheetW+'mm',height:(sheetW*848/1200)+'mm',role:'img','font-family':'Arial, sans-serif','aria-label':'Zwymiarowany widok zabudowy'},null);
  el('rect',{width:1200,height:848,fill:'#fcfdfd'});el('rect',{x:.5,y:.5,width:1199,height:847,fill:'none',stroke:technical?'#777':'#9aa9ad','stroke-width':.8});
  el('rect',{x:8,y:8,width:5,height:45,fill:accent});
  text(22,29,$('title').value||`${data.project} — Widok zabudowy`,13,{'font-weight':'700',fill:'#202b31'});
  text(22,45,`${view.name}${reversed?' · kierunek odwrócony':''} · ${$('fronts').checked?'z frontami':'bez frontów'} · wymiary w mm`,7.5,{fill:muted});
  if(!compactSchedule)line(930,.5,930,847,{stroke:technical?'#777':'#9aa9ad','stroke-width':.8});
  drillingPanel(scheduleFronts);
  drillingTable(scheduleFronts,940,18,250,accent,muted);
  const layer=el('g',{'stroke-linejoin':'round'});
  const surfaces=data.faces.filter(f=>ids.has(f.root)&&($('finishing').checked||!f.finishing)&&($('hardware').checked||!f.hardware)&&($('fronts').checked||!f.front)).map(f=>{
   const loops=f.loops.map(l=>l.map(project));return {f,loops,depth:loops.flat().reduce((s,p)=>s+p[2],0)/loops.flat().length};
  }).filter(s=>s.loops.length&&area(s.loops[0])>.05).sort((a,b)=>a.depth-b.depth);
  const finishingRootIds=new Set(roots.filter(root=>root.finishing).map(root=>root.id));
  // Appliance envelopes can protrude beyond the real appliance. An opaque front
  // must cover that approximation; leave the interior and dashed back edges intact.
  const proxyMasks=new Map();
  if($('fronts').checked){
   const facingFronts=new Set(data.fronts.filter(f=>ids.has(f.root)&&f.normal&&f.normal.reduce((s,n,i)=>s+n*normal[i],0)>.7).map(f=>f.id));
   const proxyRoots=new Set(surfaces.filter(s=>s.f.proxy).map(s=>s.f.root));
   const defs=el('defs');
   for(const root of proxyRoots){
    const cover=surfaces.filter(s=>s.f.root===root&&facingFronts.has(s.f.front));if(!cover.length)continue;
    const id='appliance-cover-'+proxyMasks.size,mask=el('mask',{id,maskUnits:'userSpaceOnUse',maskContentUnits:'userSpaceOnUse',x:0,y:0,width:1200,height:848,'mask-type':'luminance'},defs);
    el('rect',{width:1200,height:848,fill:'white'},mask);
    for(const surface of cover){const d=surface.loops.map(loop=>loop.map((p,i)=>{const q=point(p);return(i?'L':'M')+q.map(v=>v.toFixed(3)).join(',')}).join(' ')+'Z').join(' ');el('path',{d,fill:'black','fill-rule':'evenodd'},mask);}
    proxyMasks.set(root,id);
   }
  }
  for(const {f,loops}of surfaces){
   const target=f.proxy&&proxyMasks.has(f.root)?el('g',{mask:'url(#'+proxyMasks.get(f.root)+')','data-appliance-masked':'true'},layer):layer;
   const d=loops.map(loop=>loop.map((p,i)=>{const q=point(p);return(i?'L':'M')+q.map(v=>v.toFixed(3)).join(',')}).join(' ')+'Z').join(' ');
   const presentationPart=f.front||finishingRootIds.has(f.root);
   el('path',{d,fill:technical?'#fff':$('colours').checked?f.colour:(f.proxy?'#dfe4e5':presentationPart?'#f0f3f2':'#fafbfb'),'fill-rule':'evenodd','data-surface':'true'},target);
   const edges=f.edges.map(edge=>edge.map((p,i)=>{const q=point(project(p));return(i?'L':'M')+q.map(v=>v.toFixed(3)).join(',')}).join(' ')).join(' ');
   if(edges)el('path',{d:edges,fill:'none',stroke:'#3e4243','stroke-width':.48},target);
  }
  if($('backEdges').checked){
   const ghost=el('g',{'data-back-edges':'true',fill:'none',stroke:'#526b7b','stroke-width':.55,'stroke-dasharray':'2.5 2','stroke-opacity':.72});
   const seen=new Set(),segments=[];
   for(const face of data.faces){if(!ids.has(face.root)||(!$('fronts').checked&&face.front)||(!$('hardware').checked&&face.hardware)||(!$('finishing').checked&&face.finishing))continue;
    for(const edge of face.edges){const ends=edge.map(p=>point(project(p)));if(Math.hypot(ends[1][0]-ends[0][0],ends[1][1]-ends[0][1])<.05)continue;
     const key=ends.map(p=>p.map(v=>v.toFixed(2)).join(',')).sort().join('|');if(seen.has(key))continue;seen.add(key);
     segments.push('M'+ends[0].map(v=>v.toFixed(3)).join(',')+'L'+ends[1].map(v=>v.toFixed(3)).join(','));
    }
   }
   el('path',{d:segments.join(' ')},ghost);
  }
  const bottom=oy+mh*factor;
  for(const root of roots){
   const rb=bounds(root.points.map(project)),a=point([rb[0],rb[1]]),z=point([rb[2],rb[3]]);
   const showName=$('names').checked&&!`${root.name||''} ${root.tags||''}`.match(/end\s*panels?|fillers?|panel\s*końcow|blenda/i);
   if(showName){const name=root.name||root.id;const w=Math.min(150,name.length*6+12);el('rect',{x:(a[0]+z[0]-w)/2,y:z[1]+7,width:w,height:18,rx:2,fill:'#ffffff','fill-opacity':.94,stroke:'#8fa2a7','stroke-width':.55});text((a[0]+z[0])/2,z[1]+20,name,10,{'text-anchor':'middle','font-weight':'700',fill:'#26363c'});}
   if($('dimensions').checked)dimH(a[0],z[0],z[1]+(showName?43:24),z[1],z[1],fmt(rb[2]-rb[0]));
   if($('unitHeights').checked&&z[1]-a[1]>24){
    const heights=(root.unit_heights||[]).filter(h=>h.value>1);
    if(heights.length){
     heights.forEach((h,i)=>{const y1=point(project([0,0,h.to]))[1],y2=point(project([0,0,h.from]))[1];dimV(z[0]-8-i*17,y1,y2,z[0],fmt(h.value),root.id);});
     const total=root.unit_total;
     if((root.side_panel_count||0)>2&&total&&!heights.some(h=>Math.abs(h.value-total.value)<.1)){
      dimV(z[0]-8-heights.length*17,point(project([0,0,total.to]))[1],point(project([0,0,total.from]))[1],z[0],fmt(total.value),root.id+'-total');
     }
    }else dimV(z[0]-8,a[1],z[1],z[0],fmt(rb[3]-rb[1]),root.id);
   }
  }
  if($('shelfGaps').checked){
   for(const root of roots){for(const gap of root.shelf_gaps||[]){
    const a=point(project(gap.to)),b=point(project(gap.from)),rb=bounds(root.points.map(project)),left=point([rb[0],rb[1]])[0],right=point([rb[2],rb[3]])[0],centre=(left+right)/2,gapMidZ=(gap.to[2]+gap.from[2])/2;
    const activeFronts=data.fronts.filter(f=>f.root===root.id&&f.points.length&&(!f.normal||f.normal.reduce((s,n,i)=>s+n*normal[i],0)>=.7)&&gapMidZ>=Math.min(...f.points.map(p=>p[2]))-1&&gapMidZ<=Math.max(...f.points.map(p=>p[2]))+1);
    const rawFrontRanges=activeFronts.map(f=>{const r=bounds(f.points.map(project));return[point([r[0],r[1]])[0],point([r[2],r[3]])[0]]}).sort((p,q)=>p[0]-q[0]);
    const frontRanges=[];for(const range of rawFrontRanges){const previous=frontRanges.at(-1);if(previous&&range[0]<previous[1]-5)previous[1]=Math.max(previous[1],range[1]);else frontRanges.push(range.slice());}
    const activeHinges=(root.hinges||[]).filter(h=>activeFronts.some(f=>h[2]>=Math.min(...f.points.map(p=>p[2]))-20&&h[2]<=Math.max(...f.points.map(p=>p[2]))+20));
    const hingeXs=(activeHinges.length?activeHinges:(root.hinges||[])).map(h=>point(project(h))[0]);
    const x=frontRanges.length>=2?Math.min(right-12,(frontRanges[0][1]+frontRanges[frontRanges.length-1][0])/2+8):hingeXs.length?(hingeXs.reduce((s,v)=>s+v,0)/hingeXs.length<centre?left+(right-left)*.72:left+(right-left)*.28):left+(right-left)*.28;
    if(b[1]-a[1]<printFont(6)+5)continue;
    line(x,a[1],x,b[1],{stroke:accent,'stroke-width':.75});
    for(const y of [a[1],b[1]])line(x-3,y+3,x+3,y-3,{stroke:accent,'stroke-width':.75});
    const tx=x+9,cy=(a[1]+b[1])/2;
    const t=text(tx,cy,fmt(gap.value),printFont(6),{'text-anchor':'middle','dominant-baseline':'middle',transform:`rotate(-90 ${tx} ${cy})`,'font-weight':'700','paint-order':'stroke',stroke:'white','stroke-width':4,'stroke-opacity':.9,fill:accentText,'data-shelf-gap':gap.value,'data-shelf-root':root.id});
    t.appendChild(document.createElementNS(NS,'title')).textContent='Prześwit między powierzchniami: '+fmt(gap.value)+' mm';
   }}
  }
  if($('fronts').checked&&$('frontDimensions').checked){
   for(const f of data.fronts){if(!ids.has(f.root)||!f.points.length)continue;if(f.normal&&f.normal.reduce((s,n,i)=>s+n*normal[i],0)<.7)continue;
    const fb=bounds(f.points.map(project)),a=point([fb[0],fb[1]]),z=point([fb[2],fb[3]]);if(z[0]-a[0]<24||z[1]-a[1]<17)continue;
    // Front labels are physical dimensions in the front's own plane, not its shortened screen projection.
    const length=f.normal?Math.hypot(f.normal[0],f.normal[1]):0;
    const tangent=length>1e-6?[-f.normal[1]/length,f.normal[0]/length,0]:u;
    const widths=f.points.map(p=>p[0]*tangent[0]+p[1]*tangent[1]);
    const zs=f.points.map(p=>p[2]);
    const width=Math.max(...widths)-Math.min(...widths),height=Math.max(...zs)-Math.min(...zs);
    const value=fmt(height)+' × '+fmt(width);const font=Math.min(11,Math.max(6,(z[0]-a[0]-5)/value.length*1.7));
    const txt=text((a[0]+z[0])/2,(a[1]+z[1])/2+font/3,value,font,{'text-anchor':'middle',fill:'#222','paint-order':'stroke',stroke:'#fff','stroke-width':2,'stroke-opacity':.7,'data-front-size':f.id,'data-front-width':width.toFixed(3)});txt.appendChild(document.createElementNS(NS,'title')).textContent=f.name+' · rzeczywisty wymiar frontu: '+value+' mm';
   }
   for(const root of roots){if(!root.finishing||!root.points.length)continue;
    const rb=bounds(root.points.map(project)),a=point([rb[0],rb[1]]),z=point([rb[2],rb[3]]),width=rb[2]-rb[0],height=rb[3]-rb[1];
    if(z[0]-a[0]<18||z[1]-a[1]<18)continue;
    const value=fmt(height)+' × '+fmt(width),font=Math.min(10,Math.max(6,(z[0]-a[0]-5)/value.length*1.7));
    text((a[0]+z[0])/2,(a[1]+z[1])/2+font/3,value,font,{'text-anchor':'middle',fill:'#202b31','paint-order':'stroke',stroke:'white','stroke-width':3,'stroke-opacity':.9,'data-finishing-size':root.id});
   }
  }
  if($('fronts').checked&&$('hingeDimensions').checked){
   for(const root of roots){for(const hinge of root.hinges||[]){
    const candidates=data.fronts.filter(f=>f.root===root.id&&f.points.length&&(!f.normal||f.normal.reduce((s,n,i)=>s+n*normal[i],0)>=.7)).map(f=>{
     const length=f.normal?Math.hypot(f.normal[0],f.normal[1]):0,tangent=length>1e-6?[-f.normal[1]/length,f.normal[0]/length,0]:u;
     const us=f.points.map(p=>p[0]*tangent[0]+p[1]*tangent[1]),zs=f.points.map(p=>p[2]),hu=hinge[0]*tangent[0]+hinge[1]*tangent[1];
     const inside=hu>=Math.min(...us)-20&&hu<=Math.max(...us)+20&&hinge[2]>=Math.min(...zs)-20&&hinge[2]<=Math.max(...zs)+20;
     const bottom=Math.min(...zs),top=Math.max(...zs);
     return inside?{bottom,top,height:top-bottom,distance:Math.abs(hu-(Math.min(...us)+Math.max(...us))/2)}:null;
    }).filter(Boolean).sort((a,b)=>a.distance-b.distance||b.height-a.height);
    if(!candidates.length)continue;
    const fromBottom=hinge[2]-candidates[0].bottom,fromTop=candidates[0].top-hinge[2],useTop=fromBottom>=1450;
    const value=Math.round(useTop?fromTop:fromBottom),q=point(project(hinge)),label=String(value),cupR=Math.max(4,17.5*factor);
    el('circle',{cx:q[0],cy:q[1],r:cupR,fill:technical?'none':'#ffffff','fill-opacity':.86,stroke:accent,'stroke-width':1.1,'data-hinge-cup':'true'});
    el('circle',{cx:q[0],cy:q[1],r:1.15,fill:accent,'data-hinge-axis':'true'});
    const frontCentre=point(project([(root.points.reduce((s,p)=>s+p[0],0)/root.points.length),(root.points.reduce((s,p)=>s+p[1],0)/root.points.length),hinge[2]]));
    const inward=frontCentre[0]>=q[0]?1:-1,tx=q[0]+inward*(cupR+4),ty=q[1],anchor=inward>0?'start':'end';
    const t=text(tx,ty,label,printFont(6),{'text-anchor':anchor,'dominant-baseline':'middle',fill:useTop?accent:'#202b31','font-weight':'700','paint-order':'stroke',stroke:'white','stroke-width':3.5,'stroke-opacity':.92,'data-hinge-offset':value,'data-hinge-reference':useTop?'top':'bottom'});
    if(/[69]/.test(label)){const dotX=tx+(inward>0?label.length*3.5:-label.length*3.5);el('circle',{cx:dotX,cy:ty+3.2,r:1.05,fill:useTop?'#176e6a':'#111','data-digit-marker':'true'},t.parentNode);}
    t.appendChild(document.createElementNS(NS,'title')).textContent='Oś zawiasu od '+(useTop?'góry':'dołu')+' frontu: '+value+' mm';
   }}
  }
  dimH(ox,ox+mw*factor,bottom+72,bottom,bottom,fmt(mw),true);dimV(drawingLeft-15,oy,bottom,ox,fmt(mh));
  if($('levelHeights').checked){
   // The level chain is based only on paired cabinet sides. Finishing parts and
   // end panels must not introduce competing levels such as 522 or 524 mm.
   const levels=roots.flatMap(r=>(r.unit_heights||[]).flatMap(h=>[-h.to,-h.from])).sort((a,b)=>a-b).filter((v,i,a)=>!i||v-a[i-1]>.1);
   const right=ox+mw*factor,x=Math.min(918,right+24);
   if(levels.length<=2){/* The total height is already dimensioned at the left. */}
   else {
   for(const v of levels){const y=point([bb[2],v])[1];line(right,y,x+4,y,{stroke:'#aaa','stroke-width':.45});line(x-3,y+3,x+3,y-3);}
   for(let i=1;i<levels.length;i++){
    const a=point([bb[2],levels[i-1]])[1],b=point([bb[2],levels[i]])[1];line(x,a,x,b);
    const value=levels[i]-levels[i-1];
    const label=text(x+7,(a+b)/2,fmt(value),10,{'dominant-baseline':'middle','data-level-dimension':value.toFixed(4),fill:'#111','paint-order':'stroke',stroke:'white','stroke-width':2});
    label.appendChild(document.createElementNS(NS,'title')).textContent='Wysokość / prześwit: '+fmt(value)+' mm';
   }}
  }
  const denom=1200/sheetW/factor;
  line(.5,715,930,715,{stroke:technical?'#777':'#9aa9ad','stroke-width':.8});
  text(22,738,'ELFIS · Widok zabudowy',11,{'font-weight':'700',fill:accent});
  text(22,756,`Projekt: ${data.project}`,8.5);text(22,772,($('technical').checked?'Rysunek techniczny · bez kolorów, cieni i tekstur':'Kolory bazowe materiałów')+' · AGD uproszczone',7.5,{fill:muted});
  const noteLines=[];
  for(const paragraph of [$('note').value.replace(/\s+/g,' ').trim()]){let rest=paragraph;while(rest.length>110){let cut=rest.lastIndexOf(' ',110);if(cut<1)cut=110;noteLines.push(rest.slice(0,cut));rest=rest.slice(cut).trimStart();}noteLines.push(rest);}
  noteLines.slice(0,3).forEach((value,i)=>text(22,790+i*11,value,7.5,{'data-note':'true'}));
  line(730,715,730,830,{stroke:'#777','stroke-width':.6});text(744,738,`Skala 1:${fmt(denom)}${requested?'':' dop.'}`,8);
  text(744,753,`${$('paper').value} poziomo · ${roots.length} szafek`,7.5);text(744,768,`${data.date} · v${data.version}`,7.5);
  $('drawing').replaceChildren(svg);$('save').disabled=$('print').disabled=false;
  const status=`${roots.length} szafek · ${surfaces.length} powierzchni · skan ${data.elapsed} s. `;
  $('status').textContent=over?'Wybrana skala nie mieści się na arkuszu. Wybierz większy arkusz lub mniejszą skalę.':status;
  $('status').className=over?'error':'';
  if(over){$('save').disabled=$('print').disabled=true;}
 }
 function receive(value){
  const previous=data?.views.find(v=>v.id===$('direction').value);
  data=value;excluded=new Set();
  $('direction').replaceChildren();for(const view of data.views){const option=document.createElement('option');option.value=view.id;option.textContent=view.name;$('direction').append(option);}
  const dot=(a,b)=>a.reduce((sum,n,i)=>sum+n*b[i],0);
  const same=!data.new_selection&&previous&&data.views.find(v=>previous.id.startsWith('wall-')?v.id.startsWith('wall-')&&dot(v.normal,previous.normal)>.999999:v.id===previous.id);
  const camera=data.views.find(v=>v.id==='camera');
  const walls=data.views.filter(v=>v.id.startsWith('wall-'));
  const dominant=walls.sort((a,b)=>b.roots.length-a.roots.length||(camera?dot(b.normal,camera.normal)-dot(a.normal,camera.normal):0))[0];
  $('direction').value=(same||dominant||camera||data.views[0]).id;
  if(data.new_selection||!previous)reversed=false;
  if(data.restore){
   for(const id of settingIds){if(!(id in data.restore.settings))continue;const node=$(id);if(node.type==='checkbox')node.checked=data.restore.settings[id]===true;else node.value=data.restore.settings[id];}
   $('direction').value='saved';reversed=false;
  }
  if(!$('title').value)$('title').value=data.project+' — Widok zabudowy';
  $('savedViews').replaceChildren(new Option('— wybierz widok —',''));
  for(const v of data.saved_views||[])$('savedViews').append(new Option(v.name,v.id));
  $('savedViews').value=data.current_saved_id||'';
  for(const id of ['namedUpdate','namedReplace','namedDelete'])$(id).disabled=!$('savedViews').value;
  if(data.restore)$('viewName').value=data.restore.name;
  rows();render();
 }
 function named(action){
  if(!data)return;
  const view=data.views.find(v=>v.id===$('direction').value);
  const settings=Object.fromEntries(settingIds.map(id=>[id,$(id).type==='checkbox'?$(id).checked:$(id).value]));
  const roots=view.roots.filter(id=>!excluded.has(id));
  busy();ruby('elevation_named',JSON.stringify({action,id:$('savedViews').value,name:$('viewName').value,normal:view.normal.map(n=>n*(reversed?-1:1)),roots,settings}));
 }
 function ruby(name,...args){if(window.sketchup?.[name])window.sketchup[name](...args);else fail('Ten przycisk działa w oknie SketchUpa.');}
 const modeLabel=document.createElement('label'),modeSelect=document.createElement('select');
 modeLabel.append('Rodzaj rysunku',modeSelect);modeSelect.id='drawingMode';modeSelect.append(new Option('Elewacja','elevation'),new Option('Rzut szafek z góry','plan'),new Option('Widok 3D pojedynczej szafki','cabinet3d'));
 $('direction').parentElement.before(modeLabel);
 const xrayLabel=document.createElement('label'),xrayInput=document.createElement('input');xrayLabel.className='check';xrayInput.type='checkbox';xrayInput.id='xray';xrayInput.checked=true;xrayLabel.append(xrayInput,' X-ray widoku 3D');$('technical').parentElement.before(xrayLabel);
 const badge=document.querySelector('.badge');if(badge)badge.textContent='BETA 0.1.44';
 const headerDescription=document.querySelector('header p');if(headerDescription)headerDescription.textContent='Elewacja i rzut zaznaczonych szafek · wymiary w mm';
 $('shelfGaps').parentElement.lastChild.textContent=' Prześwity: wieńce, półki, trawersy';
 $('drawingMode').addEventListener('change',()=>{const elevation=$('drawingMode').value==='elevation';$('direction').disabled=!elevation;$('reverse').disabled=!elevation;rows();schedule()});
 $('direction').addEventListener('change',()=>{reversed=false;rows();schedule()});$('reverse').addEventListener('click',()=>{reversed=!reversed;schedule()});
 for(const id of settingIds.filter(id=>id!=='hidden'))$(id).addEventListener('input',schedule);
 $('savedViews').addEventListener('change',()=>{if($('savedViews').value)named('load')});
 $('namedNew').addEventListener('click',()=>named('new'));
 $('namedUpdate').addEventListener('click',()=>named('update'));
 $('namedReplace').addEventListener('click',()=>named('replace'));
 $('namedDelete').addEventListener('click',()=>{if(confirm('Usunąć zapisany widok? Szafki pozostaną w modelu.'))named('delete')});
 $('reload').addEventListener('click',()=>{busy();ruby('elevation_refresh',JSON.stringify({hidden:$('hidden').checked}))});
 $('refresh').addEventListener('click',()=>{busy();ruby('elevation_refresh',JSON.stringify({selection:true,hidden:$('hidden').checked}))});
 $('hidden').addEventListener('change',()=>{busy();ruby('elevation_refresh',JSON.stringify({hidden:$('hidden').checked}))});
 $('save').addEventListener('click',()=>{if(svg)ruby('elevation_export',new XMLSerializer().serializeToString(svg))});
 $('print').addEventListener('click',()=>{if(svg)ruby('elevation_print',new XMLSerializer().serializeToString(svg),$('paper').value)});
 window.ElevationBeta={receive,fail,render,get data(){return data;}};
 if(window.sketchup?.elevation_ready)window.sketchup.elevation_ready();
})();
