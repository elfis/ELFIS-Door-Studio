const {chromium}=require('playwright'),fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict');
const {pathToFileURL}=require('node:url');
(async()=>{
 const browser=await chromium.launch({headless:true,channel:'chrome'}),page=await browser.newPage({viewport:{width:1150,height:950}}),errors=[],checks=[];
 page.on('pageerror',e=>errors.push(e.message));await page.addInitScript(()=>{window.messages=[];window.sketchup={order_action:j=>messages.push(JSON.parse(j))}});
 const data=JSON.parse(fs.readFileSync('order_2914_fixture.json','utf8'));
 for(const lang of ['en','pl']){
  await page.goto(pathToFileURL(path.resolve('elfis_bastille_podmien_front/order_list'+(lang==='en'?'.en':'')+'.html')).href);
  await page.evaluate(d=>renderOrderList(d),data);
  assert.equal(await page.locator('#stock-split').isChecked(),false);
  assert.equal(await page.locator('.stock-product').count(),1);assert.equal(await page.locator('#stock-tree details').count(),6);
  const details=page.locator('#stock-tree details').filter({has:page.locator('button.stock-part',{hasText:'1672.01'})}).first();
  await details.locator('summary span').click();assert.match(await details.innerText(),/1672\.01 × 150/);assert.match(await details.innerText(),/616 × 79/);
  await page.locator('#stock-split').check();
  assert.deepEqual(await page.evaluate(()=>{const m=messages.at(-1);return {action:m.action,length:m.length,kerf:m.kerf,split_sections:m.split_sections}}),{action:'stock_settings',length:2400,kerf:3,split_sections:true});
  assert.equal(await page.locator('#stock-split').isDisabled(),true);
  await page.evaluate(d=>renderOrderList({...d,stock:d.split_stock,revision:2}),data);
  assert.equal(await page.locator('#stock-split').isChecked(),true);assert.equal(await page.locator('.stock-product').count(),2);assert.equal(await page.locator('#stock-tree details').count(),7);
  await page.locator('#stock-split').uncheck();assert.equal(await page.evaluate(()=>messages.at(-1).split_sections),false);
  await page.evaluate(d=>renderOrderList({...d,revision:3}),data);
  assert.equal(await page.locator('#stock-tree details').count(),6);
  await page.screenshot({path:`output/order-2914-${lang}.png`,fullPage:true});
  checks.push(`${lang}: shared offcuts, true part widths, checkbox immediate save, busy state, persisted separate mode, return to mixed mode`);
 }
 assert.deepEqual(errors,[]);await browser.close();fs.writeFileSync('order_2914_ui_results.json',JSON.stringify({passed:true,checks},null,2));console.log('PASS: '+checks.join('\n'));
})().catch(e=>{console.error(e);process.exit(1)});
