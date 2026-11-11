const {chromium}=require('playwright');
const {pathToFileURL}=require('node:url');
const path=require('node:path'),fs=require('node:fs'),assert=require('node:assert/strict');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'});
 try{
 const page=await browser.newPage({viewport:{width:830,height:900}}),errors=[];
 page.on('pageerror',e=>errors.push(e.message));
 await page.addInitScript(()=>{window.messages=[];window.sketchup={action:j=>messages.push(JSON.parse(j))};});
 await page.goto(pathToFileURL(path.resolve('elfis_handles/library.html')).href);
 assert.deepEqual(await page.evaluate(()=>messages[0]),{action:'ready'});
 const sample={version:'1.1.0-beta',language:'en',models:[{id:'bar',name:'Bar 160',kind:'standard',pitch:160,length:180,calibrated:true},{id:'edge',name:'Edge 200',kind:'edge',pitch:160,length:200}],settings:{model_id:'bar',position:'tr',orientation:'vertical',mode:'custom',offset:45,offset_x:45,offset_y:45,along:45,edge_shift:0,preserve:true},rows:[]};
 await page.evaluate(d=>receive(d),sample);
 assert.equal(await page.locator('#remove-handles').innerText(),'X');
 assert.equal(await page.locator('#remove-handles').getAttribute('title'),'Remove handles by clicking fronts');
 assert.equal(await page.locator('#remove-handles').evaluate(e=>getComputedStyle(e).backgroundColor),'rgb(197, 49, 49)');
 await page.locator('#remove-handles').click();
 assert.equal((await page.evaluate(()=>messages.at(-1))).action,'remove_click');
 assert.equal(await page.locator('#calibrate').isEnabled(),true);
 await page.selectOption('#orientation','horizontal');
 await page.waitForFunction(()=>messages.at(-1)?.action==='update');
 assert.equal((await page.evaluate(()=>messages.at(-1))).settings.orientation,'horizontal');
 assert.equal(await page.locator('#preserve').isChecked(),false);
 await page.getByRole('button',{name:'Top left',exact:true}).click();
 await page.waitForFunction(()=>messages.at(-1)?.settings?.position==='tl');
 assert.equal((await page.evaluate(()=>messages.at(-1))).settings.orientation,'horizontal');
 await page.locator('#offset_x').fill('30');await page.locator('#offset_y').fill('60');
 await page.waitForFunction(()=>messages.at(-1)?.settings?.offset_y===60);
 assert.equal((await page.evaluate(()=>messages.at(-1))).settings.offset_x,30);
 const points=await page.evaluate(()=>handlePosition(596,715,{kind:'standard',pitch:160},{position:'tr',mode:'custom',offset:45,offset_x:30,offset_y:60,orientation:'vertical'},null));
 assert.deepEqual(points,{a:[566,655],b:[566,495],edge:false});
 await page.evaluate(()=>hoverPlacement({width:450,height:715,frame_offset:null,placement:{a:[405,670],b:[405,510],edge:false}}));
 assert((await page.locator('#preview-size').innerText()).includes('715 × 450'));
 await page.selectOption('#model','edge');
 await page.waitForFunction(()=>messages.at(-1)?.settings?.model_id==='edge');
 assert.equal(await page.locator('#calibrate').isEnabled(),false);
 assert.equal(await page.locator('#orientation').isDisabled(),true);
 assert.equal(await page.locator('#edge-settings').isVisible(),true);
 await page.getByRole('button',{name:'Right centre',exact:true}).click();
 await page.waitForFunction(()=>messages.at(-1)?.settings?.position==='mr',{},{timeout:3000}).catch(async e=>{console.log(await page.evaluate(()=>({position,messages:messages.slice(-3)})));throw e;});
 await page.selectOption('#model','bar');
 await page.waitForFunction(()=>messages.at(-1)?.settings?.model_id==='bar');
 assert.equal(await page.locator('#orientation').inputValue(),'horizontal');
 sample.language='pl';await page.evaluate(d=>receive(d),sample);
 assert.equal(await page.locator('#remove-handles').innerText(),'X');
 assert.equal(await page.locator('#remove-handles').getAttribute('aria-label'),'Usuń uchwyty kliknięciem frontu');
 assert.equal(await page.getByRole('button',{name:'Ustaw punkty mocowania',exact:true}).count(),1);
 for(const width of [830,360]){
   await page.setViewportSize({width,height:1000});
   assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth>innerWidth),false);
   await page.screenshot({path:'output/elfis_handles_110_'+width+'.png',fullPage:true});
 }
 assert.deepEqual(errors,[]);
 console.log('PASS: immediate model/orientation/position/offset updates, no second activation click, preserve override, real-size preview, edge controls, PL labels and responsive layout');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
