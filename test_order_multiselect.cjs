const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
class Element{
 constructor(){this.children=[];this.value='';this.dataset={};this.style={};this.classList={toggle(){}};}
 append(...items){this.children.push(...items)}
 replaceChildren(...items){this.children=items}
 setAttribute(){}
}
const elements=new Map(),messages=[];
const context=vm.createContext({document:{getElementById(id){if(!elements.has(id))elements.set(id,new Element());return elements.get(id)},createElement(){return new Element()}},Option:function(text,value){this.text=text;this.value=value},window:{sketchup:true},sketchup:{order_action(json){messages.push(JSON.parse(json))}}});
const html=fs.readFileSync('elfis_bastille_podmien_front/order_list.html','utf8');
vm.runInContext(html.split('<script>')[1].split('</script>')[0],context);
const rows=Array.from({length:6},(_,id)=>({id,profile:'Profile '+id,height:715,width:296+id,thickness:18,quantity:id+1,colours:[],type:'Slab',handle:'—'}));
context.data={model:'Test',rows,profiles:[{id:'slab',name:'Slab',kind:'slab'}],warnings:[],review_count:0,total:21,revision:3};
vm.runInContext('renderOrderList(data)',context);
function click(index,event,expected){elements.get('rows').children[index].onclick(event);const message=messages.at(-1);assert.equal(message.action,'highlight');assert.deepEqual(message.ids,expected);context.response=message.ids;vm.runInContext('setOrderHighlighted(response,7)',context);}
click(1,{},[1]);click(4,{shiftKey:true},[1,2,3,4]);click(2,{ctrlKey:true},[1,3,4]);click(5,{ctrlKey:true},[1,3,4,5]);
click(3,{shiftKey:true},[3,4,5]);click(0,{ctrlKey:true,shiftKey:true},[0,1,2,3,4,5]);
click(5,{},[5]);click(5,{ctrlKey:true},[]);
assert.equal(elements.get('replace-row').disabled,true);
click(0,{},[0]);click(2,{shiftKey:true},[0,1,2]);
elements.get('target-profile').value='slab';elements.get('target-profile').onchange();
assert.equal(elements.get('replace-row').textContent,'Zmień profil (6 szt.)');assert.equal(elements.get('replace-row').disabled,false);
elements.get('replace-row').onclick();assert.deepEqual(messages.at(-1).ids,[0,1,2]);assert.equal(messages.at(-1).action,'replace_row');
vm.runInContext('renderOrderList(data)',context);assert.equal(elements.get('replace-row').disabled,true);
console.log('PASS: click, Shift range, Ctrl toggle, reverse range, Ctrl+Shift union, empty selection, quantity, batch request and refresh reset');
for(const row of rows){row.source=row.id%2?'OS Doors':'ELFIS';row.colours=[{key:row.id<3?'white':'blue',name:row.id<3?'White':'Blue'}]}
vm.runInContext('renderOrderList(data)',context);
elements.get('filter-colour').value=JSON.stringify('white');elements.get('filter-colour').onchange();
vm.runInContext('setOrderHighlighted(null,0)',context);
assert.equal(elements.get('rows').children.length,3);
elements.get('filter-source').value='OS Doors';elements.get('filter-source').onchange();vm.runInContext('setOrderHighlighted(null,0)',context);
assert.equal(elements.get('rows').children.length,1);
assert.equal(elements.get('count').textContent,'Fronty: 2 szt. · 1 pozycji (z 21 szt. w projekcie)');
elements.get('copy').onclick();assert.deepEqual(messages.at(-1).ids,[1]);assert.equal(messages.at(-1).action,'copy');vm.runInContext("setOrderStatus('copied')",context);
elements.get('rows').children[0].onclick({});context.response=[1];vm.runInContext('setOrderHighlighted(response,2)',context);
elements.get('rows').children[0].ondblclick({preventDefault(){}});assert.equal(messages.at(-1).action,'zoom');assert.deepEqual(messages.at(-1).ids,[1]);vm.runInContext('setOrderHighlighted(response,2)',context);
elements.get('supplier-value').value='BA';elements.get('supplier-value').oninput();elements.get('assign-supplier').onclick();assert.equal(messages.at(-1).action,'assign_supplier');assert.equal(messages.at(-1).supplier,'BA');vm.runInContext("setOrderStatus('assigned')",context);
elements.get('reset-filters').onclick();vm.runInContext('setOrderHighlighted(null,0)',context);assert.equal(elements.get('rows').children.length,6);
console.log('PASS: combined colour/source filters, visible count, filtered clipboard IDs, double-click zoom and supplier assignment');
rows.push({id:6,section:'endpanels',profile:'End panel T&G',height:900,width:580,thickness:18,quantity:2,colours:[],type:'Panel kończący',handle:'—',source:'ELFIS'});
context.data.include_endpanels=true;context.data.endpanels_present=true;context.data.total=23;
vm.runInContext('renderOrderList(data)',context);
assert.equal(elements.get('rows').children.length,6);assert.equal(elements.get('endpanels-rows').children.length,1);
assert.equal(elements.get('endpanels-section').hidden,false);assert.equal(elements.get('endpanels-count').textContent,'2 szt. · 1 pozycji');
elements.get('endpanels-rows').children[0].onclick({});context.response=[6];vm.runInContext('setOrderHighlighted(response,2)',context);
elements.get('target-profile').value='slab';elements.get('target-profile').onchange();assert.equal(elements.get('replace-row').disabled,true);
elements.get('copy-endpanels').onclick();assert.deepEqual(messages.at(-1).ids,[6]);assert.equal(messages.at(-1).action,'copy');
console.log('PASS: separate Endpanels sublist, quantity, own copy action and blocked door-profile replacement');
