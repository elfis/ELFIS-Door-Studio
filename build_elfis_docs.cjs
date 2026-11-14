const fs=require('node:fs'),path=require('node:path');
(async()=>{
 const {marked}=await import('marked');const dir='elfis_bastille_podmien_front/docs';
 const style='body{max-width:1080px;margin:28px auto;padding:0 26px;color:#213b3d;background:#f4f5f2;font:15px/1.6 Segoe UI,sans-serif}h1,h2,h3{line-height:1.25}h2{margin-top:36px}table{border-collapse:collapse;width:100%;background:#fff}td,th{border:1px solid #cbd7d0;padding:9px 12px;text-align:left;vertical-align:top}th{background:#e7eee9}code{background:#e5e9e5;padding:2px 4px;overflow-wrap:anywhere}a{color:#185c76}nav{position:sticky;top:0;background:#fff;padding:12px;border-bottom:2px solid #285b59;z-index:1}nav a{margin-right:18px}@media print{nav{position:static}body{max-width:none;background:white}tr{break-inside:avoid}thead{display:table-header-group}}';
 const docs={'USER_GUIDE.en.md':'guide.en.html','USER_GUIDE.pl.md':'guide.pl.html','CHANGELOG.md':'changelog.html','ROADMAP.md':'roadmap.html'};
 for(const [source,target] of Object.entries(docs)){
  const body=marked.parse(fs.readFileSync(path.join(dir,source),'utf8'));
  const title=source.startsWith('USER_GUIDE')?'ELFIS — User Guide':'ELFIS — '+source.split('.')[0];
  fs.writeFileSync(path.join(dir,target),'<!doctype html><html lang="'+(source.includes('.pl.')?'pl':'en')+'"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+title+'</title><style>'+style+'</style></head><body><nav><strong>ELFIS 2.9.39</strong> · <a href="guide.en.html">English</a><a href="guide.pl.html">Polski</a><a href="changelog.html">Changelog</a><a href="roadmap.html">Roadmap / Plany</a></nav>'+body+'</body></html>');
 }
 console.log('Built four offline documentation pages');
})();
