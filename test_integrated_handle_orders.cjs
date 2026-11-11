const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
class Element {
 constructor(){this.children=[];this.value='';this.checked=false;this.dataset={};this.style={};this.classList={toggle(){}};}
 append(...v){this.children.push(...v)} replaceChildren(...v){this.children=v} setAttribute(){}
}
for(const file of ['order_list.html','order_list.en.html']){
 const elements=new Map(),messages=[];
 const context=vm.createContext({document:{getElementById(id){if(!elements.has(id))elements.set(id,new Element());return elements.get(id)},createElement(){return new Element()}},Option:function(text,value){this.text=text;this.value=value},window:{sketchup:true},sketchup:{order_action(raw){messages.push(JSON.parse(raw))}}});
 const html=fs.readFileSync('elfis_bastille_podmien_front/'+file,'utf8');
 vm.runInContext(html.split('<script>')[1].split('</script>')[0],context);
 context.data={model:'Test',rows:[],handles:[{name:'Bar <test>',kind:'standard',pitch:128,length:160,finish:'Black',supplier:'Supplier',code:'B128',quantity:4}],include_handles:true,warnings:[],review_count:0,total:0,revision:1};
 vm.runInContext('renderOrderList(data)',context);
 assert.equal(elements.get('handles-rows').children.length,1);
 assert.equal(elements.get('handles-rows').children[0].children[0].textContent,'Bar <test>');
 assert.equal(elements.get('copy').disabled,false,'A handles-only order can be copied');
 elements.get('copy').onclick();assert.equal(messages.at(-1).include_handles,true);assert.deepEqual(messages.at(-1).ids,[]);
 vm.runInContext("setOrderStatus('OK')",context);
 elements.get('copy-handles').onclick();assert.equal(messages.at(-1).include_handles,true);assert.deepEqual(messages.at(-1).ids,[]);
 vm.runInContext("setOrderStatus('OK')",context);
 elements.get('filter-profile').value='Different front profile';vm.runInContext('filtersChanged()',context);
 assert.equal(elements.get('handles-rows').children.length,1,'Front filters leave handles visible');
 vm.runInContext("setOrderStatus('OK')",context);
 elements.get('copy-endpanels').onclick();assert.equal(messages.at(-1).include_handles,false,'Panel-only copy excludes handles');
 vm.runInContext("setOrderStatus('OK')",context);
 elements.get('handles').checked=false;elements.get('handles').onchange();assert.equal(messages.at(-1).include_handles,false);
 context.data.include_handles=false;context.data.handles=[];vm.runInContext('renderOrderList(data)',context);
 assert.equal(elements.get('handles-section').hidden,true);assert.equal(elements.get('copy').disabled,true);
 console.log('PASS '+file+': handles-only order, consolidated table, safe text, common/section copy, front filters, toggle');
}
