const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
for(const filename of ['library','order_list'])for(const lang of ['',' .en'.trim()]){
 const file=`elfis_bastille_podmien_front/${filename}${lang}.html`;const html=fs.readFileSync(file,'utf8');new vm.Script(html.split('<script>')[1].split('</script>')[0],{filename:file});
}
// Run the existing behavioural suites on the English scripts as well.
for(const test of ['test_library_28.cjs','test_order_multiselect.cjs']){
 let code=fs.readFileSync(test,'utf8').replace(/(library|order_list)\.html/g,'$1.en.html');
 // Only expectation text changes; the mocked DOM API and test data stay intact.
 for(const [pl,en] of [['Zmień profil (','Change profile ('],[' szt.)',' pcs)'],['Fronty: ','Fronts: '],[' szt. · ',' pcs · '],[' pozycji',' items'],[' szt. w projekcie)',' pcs in project)'],[' (z ',' (of ']])code=code.split(pl).join(en);
 code=code.replaceAll('1 items','1 item');
 vm.runInNewContext(code,{require,console,__dirname:process.cwd(),setTimeout}, {filename:test+' [English]'});
}
console.log('PASS: English and Polish scripts compile; English behavioural suites pass');
