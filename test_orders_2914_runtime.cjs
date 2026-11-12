const fs=require('node:fs'),path=require('node:path');
const {WASI}=require('node:wasi');
const {RubyVM}=require('./tmp/ruby-order-tests/node_modules/@ruby/wasm-wasi/dist/cjs/vm.js');
(async()=>{
 const module=await WebAssembly.compile(fs.readFileSync('tmp/ruby-order-tests/node_modules/@ruby/3.2-wasm-wasi/dist/ruby+stdlib.wasm'));
 const wasi=new WASI({version:'preview1',returnOnExit:true,env:{WINDIR:'/win'}});
 const {vm}=await RubyVM.instantiateModule({module,wasip1:wasi});
 const sources={};
 for(const file of fs.readdirSync('elfis_bastille_podmien_front').filter(f=>f.endsWith('.rb')))sources['/workspace/elfis_bastille_podmien_front/'+file]=fs.readFileSync('elfis_bastille_podmien_front/'+file,'utf8');
 const fonts={};for(const name of ['arial.ttf','arialbd.ttf'])fonts['/win/Fonts/'+name]=fs.readFileSync('C:/Windows/Fonts/'+name).toString('base64');
 const encoded=Buffer.from(JSON.stringify({sources,fonts})).toString('base64');
 vm.eval(`require 'json';require 'base64'
 SOURCE_DATA=JSON.parse(Base64.decode64('${encoded}'))
 $test_outputs={}
 class << File
   alias_method :test_original_read,:read
   alias_method :test_original_binread,:binread
   alias_method :test_original_file?,:file?
   def read(path,*args);SOURCE_DATA['sources'].fetch(path){test_original_read(path,*args)};end
   def binread(path,*args);SOURCE_DATA['fonts'].key?(path) ? Base64.decode64(SOURCE_DATA['fonts'][path]) : test_original_binread(path,*args);end
   def file?(path);SOURCE_DATA['fonts'].key?(path) || test_original_file?(path);end
   def write(path,bytes);$test_outputs[path]=bytes;bytes.bytesize;end
   def binwrite(path,bytes);$test_outputs[path]=bytes;bytes.bytesize;end
 end
 def load(path,wrap=false)
   if SOURCE_DATA['sources'].key?(path);eval(SOURCE_DATA['sources'][path],TOPLEVEL_BINDING,path);else;super;end
 end
 class << Dir
   alias_method :test_original_glob_brackets,:[]
   def [](pattern);pattern.start_with?('/workspace/') ? SOURCE_DATA['sources'].keys : test_original_glob_brackets(pattern);end
 end`);
 vm.eval(fs.readFileSync('test_orders_2914.rb','utf8').replaceAll('RubyVM::InstructionSequence.compile_file(file)','RubyVM::InstructionSequence.compile(File.read(file))'));
 const outputs=JSON.parse(vm.eval("JSON.generate($test_outputs.transform_values { |v| Base64.strict_encode64(v) })").toString());
 for(const [file,encoded]of Object.entries(outputs)){const dest=file.replace('/workspace/',process.cwd()+'/');fs.mkdirSync(path.dirname(dest),{recursive:true});fs.writeFileSync(dest,Buffer.from(encoded,'base64'))}
})().catch(e=>{console.error(e);process.exit(1)});
