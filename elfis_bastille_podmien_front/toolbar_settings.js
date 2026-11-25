'use strict';
// Preference editor only: changes take effect at the next SketchUp startup.
window.ElfisToolbarUI = (() => {
  let config={}, defaults={}, catalog={}, language='en', selected='doors';
  const host=()=>document.getElementById('ed-toolbar-editor');
  const L=(pl,en)=>language==='pl'?pl:en;
  const clone=value=>JSON.parse(JSON.stringify(value));
  const separator=id=>/^separator:[1-9]\d{0,3}$/.test(id);
  const element=(tag,text,cls)=>{const e=document.createElement(tag);if(text)e.textContent=text;if(cls)e.className=cls;return e;};
  function button(text,label,action){const b=element('button',text);b.type='button';b.title=label;b.setAttribute('aria-label',label);b.onclick=action;return b;}
  function label(id){if(separator(id))return L('Separator','Separator');const row=(catalog[selected]||[]).find(r=>r.id===id);return row ? row[language==='pl'?'pl':'en'] : id;}
  function move(id,to){const items=config[selected].items,from=items.findIndex(r=>r.id===id);if(from<0||to<0||to>=items.length||to===from)return;items.splice(to,0,items.splice(from,1)[0]);render();}
  function render(){
    const container=host();if(!container||!config[selected])return;container.replaceChildren();
    const top=element('div',null,'ed-inline');const select=element('select');select.id='ed-toolbar-select';select.setAttribute('aria-label',L('Wybierz pasek','Choose toolbar'));
    for(const [key,pl,en] of [['doors','Drzwi i wiercenia','Doors and drilling'],['handles','Uchwyty','Handles'],['visibility','Widoczność','Visibility']])select.add(new Option(L(pl,en),key));
    select.value=selected;select.onchange=()=>{selected=select.value;render();};top.append(select);container.append(top);
    const bar=config[selected],enabled=element('label',null,'ed-check');enabled.style.marginTop='14px';const check=element('input');check.type='checkbox';check.id='ed-toolbar-enabled';check.checked=bar.enabled;check.onchange=()=>{bar.enabled=check.checked;render();};enabled.append(check,document.createTextNode(L('Włącz pasek po restarcie','Enable toolbar after restart')));container.append(enabled);
    const hint=element('p',L('Przeciągnij wiersze lub użyj strzałek. Odznacz ikonę, aby ją ukryć. Zapisz ustawienia i uruchom SketchUp ponownie.','Drag rows or use the arrows. Uncheck an icon to hide it. Save settings and restart SketchUp.'),'ed-hint');hint.style.marginTop='10px';container.append(hint);
    if(selected==='handles')container.append(element('p',L('Pasek uchwytów wymaga zainstalowanego dodatku ELFIS Handles.','The handle toolbar requires the separate ELFIS Handles extension.'),'ed-hint'));
    const list=element('div',null,'ed-toolbar-list');list.setAttribute('aria-label',L('Kolejność ikon','Icon order'));
    bar.items.forEach((item,index)=>{
      const row=element('div',null,'ed-toolbar-row');row.dataset.toolbarItem=item.id;row.draggable=true;row.classList.toggle('ed-toolbar-muted',!item.visible);
      row.ondragstart=e=>{if(e.target.closest('button,input')){e.preventDefault();return;}e.dataTransfer.setData('text/plain',item.id);e.dataTransfer.effectAllowed='move';};
      row.ondragover=e=>{e.preventDefault();e.dataTransfer.dropEffect='move';};row.ondrop=e=>{e.preventDefault();const id=e.dataTransfer.getData('text/plain');move(id,index);};
      row.append(element('span','⠿','ed-toolbar-grip'));
      const visible=element('input');visible.type='checkbox';visible.checked=item.visible;visible.setAttribute('aria-label',L('Pokaż: ','Show: ')+label(item.id));visible.onchange=()=>{item.visible=visible.checked;row.classList.toggle('ed-toolbar-muted',!item.visible);preview();};row.append(visible);
      row.append(element('span',label(item.id),'ed-toolbar-label'));
      const up=button('↑',L('Przesuń w górę','Move up'),()=>move(item.id,index-1)),down=button('↓',L('Przesuń w dół','Move down'),()=>move(item.id,index+1));up.disabled=index===0;down.disabled=index===bar.items.length-1;row.append(up,down);
      if(separator(item.id))row.append(button('×',L('Usuń separator','Remove separator'),()=>{bar.items.splice(index,1);render();}));
      list.append(row);
    });container.append(list);
    const actions=element('div',null,'ed-inline');actions.style.marginTop='12px';actions.append(button(L('+ Separator','+ Separator'),L('Dodaj separator','Add separator'),()=>{if(bar.items.length>=80)return;let n=1;while(bar.items.some(i=>i.id==='separator:'+n))n++;bar.items.push({id:'separator:'+n,visible:true});render();}),button(L('Przywróć ten pasek','Restore this toolbar'),L('Przywróć domyślny układ tego paska','Restore the default layout for this toolbar'),()=>{config[selected]=clone(defaults[selected]);render();}));container.append(actions);
    const output=element('div',null,'ed-toolbar-preview');output.id='ed-toolbar-preview';output.setAttribute('aria-label',L('Podgląd kolejności','Order preview'));container.append(output);preview();
    container.append(element('p',L('Ustawienia pozostają dostępne w menu Rozszerzenia, nawet gdy ukryjesz ich ikonę lub cały pasek.','Default settings remains available in Extensions even if its icon or an entire toolbar is hidden.'),'ed-hint'));
  }
  function preview(){const output=document.getElementById('ed-toolbar-preview');if(!output)return;output.replaceChildren();const bar=config[selected];if(!bar.enabled){output.textContent=L('Pasek wyłączony po restarcie','Toolbar disabled after restart');return;}const visible=bar.items.filter(i=>i.visible&&!separator(i.id));if(!visible.length){output.textContent=L('Wszystkie ikony ukryte','All icons hidden');return;}let pending=false,added=false;for(const item of bar.items){if(!item.visible)continue;if(separator(item.id)){if(added)pending=true;continue;}if(pending)output.append(element('span','│'));output.append(element('span',label(item.id),'ed-toolbar-chip'));pending=false;added=true;}}
  return {set(data){language=data.language||language;config=clone(data.toolbars||{});defaults=clone(data.toolbar_defaults||data.toolbars||{});catalog=clone(data.toolbar_catalog||{});render();},collect(){return clone(config);}};
})();
