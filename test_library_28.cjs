const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
class Element{constructor(){this.children=[];this.value='';this.dataset={};this.style={};this.classList={toggle(){}};}append(...v){this.children.push(...v)}replaceChildren(...v){this.children=v}setAttribute(){}}
const items=new Map(),messages=[];
const ctx=vm.createContext({document:{getElementById(id){if(!items.has(id))items.set(id,new Element());return items.get(id)},createElement(){return new Element()},createElementNS(){return new Element()},querySelectorAll(){return []}},Option:function(text,value){this.text=text;this.value=value},window:{sketchup:true},sketchup:{library_action(json){messages.push(JSON.parse(json))}},confirm(){return true}});
const html=fs.readFileSync('elfis_bastille_podmien_front/library.html','utf8');vm.runInContext(html.split('<script>')[1].split('</script>')[0],ctx);
const family={id:'test',name:'Family',kind:'shaker',supplier:'OS Doors',width:84,thickness:22,shoulder:75.5,panel:0,clearance:1,points:[[0,0],[84,0],[84,22],[0,22]],drawer_variant:{mode:'slab',min_height:100,max_height:215,min_width:240,thickness:22,edge_depth:20,frame_min:283,frame_max:2400,frame_width:240}};
ctx.data={profiles:[family],favorites:[],active:'test',suppliers:['ELFIS','Facade','OS Doors','BA','Tade Moldings'],variant_mode:'auto'};vm.runInContext('renderLibrary(data)',ctx);
assert.equal(items.get('supplier').value,'OS Doors');assert.equal(items.get('drawerEnabled').checked,true);assert.equal(items.get('drawerSectionSettings').hidden,true);assert.equal(items.get('drawerMin').value,100);
items.get('supplier').value='BA';items.get('supplier').oninput();assert.equal(items.get('create').disabled,true);
items.get('save').onclick();let msg=messages.at(-1);assert.equal(msg.action,'save');assert.equal(msg.supplier,'BA');assert.equal(msg.drawer_variant.min_height,100);
items.get('drawerMode').value='section';items.get('drawerMode').oninput();assert.equal(items.get('drawerSectionSettings').hidden,false);
items.get('importDrawer').onclick();msg=messages.at(-1);assert.equal(msg.action,'import_drawer');assert.equal(msg.drawer_variant.mode,'section');
items.get('drawerEnabled').checked=false;items.get('drawerEnabled').oninput();items.get('save').onclick();assert.equal(messages.at(-1).drawer_variant,null);
vm.runInContext('renderLibrary(data)',ctx);items.get('variantMode').value='drawer';items.get('create').onclick();assert.equal(messages.at(-1).variant_mode,'drawer');
const section=[[0,0],[140,0],[140,22],[0,22]];family.drawer_variant={...family.drawer_variant,mode:'section',section,reference_height:140};vm.runInContext('renderLibrary(data)',ctx);assert.equal(items.get('drawerSectionPreview').children.length,1);
console.log('PASS: family editor, supplier save, drawer configuration, section import payload/preview, disabling family, manual variant creation');
