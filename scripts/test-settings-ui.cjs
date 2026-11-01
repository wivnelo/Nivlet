// Isolated document tests only. Never connects to a Nivlet backend or user profile.
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const args = process.argv.slice(2), opts = {};
for (let i=0; i<args.length; i++) { if(!args[i].startsWith('--'))throw Error('Unknown argument '+args[i]); opts[args[i].slice(2)] = args[i+1] && !args[i+1].startsWith('--') ? args[++i] : true; }
const root = path.resolve(opts.root || path.join(__dirname,'..'));
const output = path.resolve(opts.out || path.join(root,'build','ui-regression'));
const width = Number(opts.width || 980), height = Number(opts.height || 720);
const language = opts.language || 'zh-Hans', theme = opts.theme || 'light';
const locales={'zh-Hans':'zh-CN','zh-Hant':'zh-TW',en:'en-US',ja:'ja-JP'};
if(!locales[language])throw Error('Unsupported test language '+language);
const browserPath = opts.browser || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
fs.mkdirSync(output,{recursive:true});
function loadFixture() {
 const readDictionary=file=>{
  const pairs=execFileSync('lua',['-e',`for k,v in pairs(dofile(${JSON.stringify('Toolkit/modules/'+file)})) do io.write(k,"\\0",v,"\\0") end`],{cwd:root}).toString().split('\0');
  const dictionary={};for(let i=0;i<pairs.length-1;i+=2)dictionary[pairs[i]]=pairs[i+1];return dictionary;
 };
 // Synthetic test metadata only. The production bridge sends one active dictionary.
 const testTranslations={'zh-Hans':{},en:readDictionary('translations.lua'),'zh-Hant':readDictionary('translations_zh_hant.lua'),ja:readDictionary('translations_ja.lua')};
 const translations=testTranslations[language];
 const names=({'zh-Hans':['灵感笔记','项目看板','阅读清单'],'zh-Hant':['靈感筆記','專案看板','閱讀清單'],en:['Studio Notes','Project Board','Reading List'],ja:['アイデアノート','プロジェクトボード','読書リスト']})[language];
 const ids=names.map((_,i)=>`com.example.demo${i+1}`);
 const icon='data:image/png;base64,'+fs.readFileSync(path.join(root,'assets/nivlet-icon.png')).toString('base64');
 return {
  ok:true,action:'load',message:'',language,translations,testTranslations,
  general:{sleepShortcut:false,showMenu:true,appearance:theme,language,tabOrder:[]},autoLaunch:false,
  permissions:{accessibility:'granted'},
  config:{enabled:true,shortcuts:Object.fromEntries([['left','LEFT'],['right','RIGHT'],['top','UP'],['bottom','DOWN'],['maximize','RETURN']].map(([id,key])=>[id,{key,mods:['ctrl','alt']}]))},
  sources:[{id:'demo.us',name:'ABC'},{id:'demo.pinyin',name:language==='en'?'Pinyin – Simplified':'简体拼音'}],
  input:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],sourceID:i===1?'demo.pinyin':'demo.us'}))},
  launcher:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],shortcut:{key:String(i+1),mods:['ctrl','alt']}}))},
  clipboard:{config:{enabled:true,images:true,persistent:false,limit:50,minutes:0,excluded:[]},entries:[
   {id:1,time:1793325600,text:language==='en'?'A little less switching. A little more focus.':'少一点切换，多一点专注。'},
   {id:2,time:1793325540,text:'https://example.com/design-notes'},
   {id:3,time:1793325480,text:language==='en'?'Release checklist\nReview the changes · Run tests · Update documentation':'发布清单\n审阅变更 · 运行测试 · 更新文档'}]},
  excludedAppNames:{},appIcons:{},applicationStates:Object.fromEntries(ids.map((id,i)=>[id,{installed:true,name:names[i]}])),
  popupShortcut:{key:'V',mods:['cmd','shift']},popupShortcutDefault:{key:'V',mods:['cmd','shift']},
  system:Object.fromEntries(['network','cpu','memory','disk','ipv4','ipv6','mac','date','lunar'].map(id=>[id,true])),
  browser:{enabled:true,defaultBrowser:'com.apple.Safari',rules:[{domain:'example.com',browser:'com.google.Chrome',subdomains:true}],appRules:[{bundleID:ids[0],name:names[0],browser:'com.apple.Safari'}]},
  browserStatus:{active:true},browsers:[{id:'com.apple.Safari',name:'Safari'},{id:'com.google.Chrome',name:'Google Chrome'}],
  about:{version:fs.readFileSync(path.join(root,'VERSION'),'utf8').trim(),build:'56',icon,license:fs.readFileSync(path.join(root,'LICENSE'),'utf8'),notices:fs.readFileSync(path.join(root,'THIRD-PARTY-NOTICES.md'),'utf8')}
 };
}
const data=loadFixture();
const pages={general:'generalSection',windows:'windowSection',input:'inputSection',clipboard:'clipSection',system:'systemSection',browser:'browserSection',launcher:'launcherSection',about:'aboutSection'};
const results=[];
async function fresh(browser){
 const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:1,locale:locales[language],timezoneId:'UTC',colorScheme:theme==='dark'?'dark':'light'});
 const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(e.message));
 await page.route('**/*',route=>route.request().url().startsWith('file:') ? route.continue() : route.abort());
 await page.addInitScript(()=>{window.webkit={messageHandlers:{toolkit:{postMessage(){}}}};});
 await page.goto(pathToFileURL(opts.html?path.resolve(opts.html):path.join(root,'Toolkit/settings.html')).href,{waitUntil:'load'});
 await page.evaluate(data=>window.receive(data),data);
 await page.evaluate(()=>window.receiveSystemValues({ok:true,values:{network:'↓ 24 KB/s  ↑ 8 KB/s',cpu:'12% / 8 Core',memory:'6.2 / 16 GB',disk:'128 / 512 GB',ipv4:'192.0.2.10',ipv6:'2001:db8::10',mac:'02:00:00:00:00:01',date:'2026-11-01',lunar:'—'}}));
 await page.evaluate(()=>document.fonts.ready);
 return {context,page,errors};
}
(async()=>{
 const browser=await chromium.launch({headless:true,executablePath:browserPath,chromiumSandbox:true,args:['--disable-background-networking','--disable-component-update','--disable-default-apps','--disable-sync','--no-first-run','--no-default-browser-check']});
 try{
  let tests=fs.readdirSync(path.join(root,'tests')).filter(x=>/_ui\.js$/.test(x)).sort();
  if(opts.suite && opts.suite!=='all')tests=String(opts.suite).split(',');
  if(opts.suite==='none')tests=[];
  for(const file of tests){
   const code=fs.readFileSync(path.join(root,'tests',file),'utf8');
   const functions=[...code.matchAll(/window\.(run\w+)\s*=\s*(?:async\s+)?function/g)].map(x=>x[1]);
   if(functions.length!==1){results.push({file,status:'skipped',reason:'Expected one window regression function'});continue;}
   const {context,page,errors}=await fresh(browser);
   try{
    if(opts['popup-states'])await page.exposeFunction('capturePopupState',async state=>{
     if(!/^[a-z-]+$/.test(state))throw Error('Invalid popup state name');
     await page.evaluate(()=>document.getElementById('popupShortcut').scrollIntoView({block:'center'}));
     await page.screenshot({path:path.join(output,`popup-${state}-${language}-${width}x${height}.png`),animations:'disabled'});
    });
    if(opts['footer-states'])await page.exposeFunction('captureFooterState',async state=>{
     if(!/^[a-z-]+$/.test(state))throw Error('Invalid state name');
     await page.screenshot({path:path.join(output,`footer-${state}-${language}-${width}x${height}.png`),animations:'disabled'});
    });
    await page.addScriptTag({content:code});
    const message=await page.evaluate(async({fn,data})=>await window[fn](data),{fn:functions[0],data});
    if(errors.length)throw Error(errors.join('\n'));
    results.push({file,status:'passed',message});console.log('PASS',file);
   }catch(error){
    const screenshot=path.join(output,file.replace(/\.js$/,'.failure.png'));
    await page.screenshot({path:screenshot,animations:'disabled'});
    results.push({file,status:'failed',error:String(error.message||error),errors,screenshot});console.log('FAIL',file,String(error.message||error).split('\n')[0]);
   }finally{await context.close();}
  }
  if(opts.screenshots){
   const {context,page,errors}=await fresh(browser);
   try{
    for(const [name,section] of Object.entries(pages)){
     await page.evaluate(section=>{window.showSection(section);document.querySelector('main').scrollTop=0;window.scrollTo(0,0)},section);
     await page.evaluate(()=>document.fonts.ready);
     const screenshot=path.join(output,`${name}-${language}-${theme}-${width}x${height}.png`);
     await page.screenshot({path:screenshot,animations:'disabled'});
     const layout=await page.evaluate(()=>{const main=document.querySelector('main'),footer=document.querySelector('footer');const visible=element=>element.getClientRects().length>0;const rect=element=>{const r=element.getBoundingClientRect();return {left:r.left,top:r.top,right:r.right,bottom:r.bottom,width:r.width,height:r.height}};const clippedInteractive=[...document.querySelectorAll('.panel:not([hidden]) button,.panel:not([hidden]) input,.panel:not([hidden]) select,.panel:not([hidden]) textarea')].filter(visible).flatMap(element=>{const r=element.getBoundingClientRect();for(let ancestor=element.parentElement;ancestor;ancestor=ancestor.parentElement){if(!/^(hidden|clip|auto|scroll)$/.test(getComputedStyle(ancestor).overflowX))continue;const a=ancestor.getBoundingClientRect(),left=a.left+ancestor.clientLeft,right=left+ancestor.clientWidth;if(r.left<left-1||r.right>right+1)return [{control:element.id||element.textContent.slice(0,60),ancestor:ancestor.id||ancestor.className||ancestor.tagName}]}return []});return {horizontalOverflow:document.documentElement.scrollWidth>innerWidth+1,mainOverflow:main.scrollWidth>main.clientWidth+1,footer:rect(footer),tab:document.querySelector('[role=tab][aria-selected=true]').textContent,clippedInteractive,clippedFooterButtons:[...footer.querySelectorAll('button')].filter(visible).filter(e=>{const r=e.getBoundingClientRect();return r.left<0||r.right>innerWidth+1||r.bottom>innerHeight+1}).map(e=>e.id)}});
     const failed=layout.horizontalOverflow||layout.mainOverflow||layout.footer.bottom>height+1||layout.clippedFooterButtons.length>0||layout.clippedInteractive.length>0;
     results.push({page:name,status:failed?'failed':'passed',kind:'screenshot-layout',layout,screenshot});console.log(failed?'LAYOUT FAIL':'LAYOUT PASS',name);
     if(String(opts['scroll-pages']||'').split(',').includes(name)){
      await page.evaluate(()=>{const main=document.querySelector('main');main.scrollTop=main.scrollHeight});
      const lower=path.join(output,`${name}-lower-${language}-${theme}-${width}x${height}.png`);await page.screenshot({path:lower,animations:'disabled'});
      results.push({page:name,status:failed?'failed':'passed',kind:'screenshot-lower',screenshot:lower});
     }
    }
    if(errors.length)results.push({kind:'screenshot-errors',status:'failed',errors});
   }finally{await context.close();}
  }
 }finally{await browser.close();}
 const report={root,browserPath,playwrightVersion:require('playwright/package.json').version,viewport:{width,height},language,theme,generatedAt:new Date().toISOString(),noNivletBackend:true,results};
 fs.writeFileSync(path.join(output,'results.json'),JSON.stringify(report,null,2));
 console.log(JSON.stringify({passed:results.filter(x=>x.status==='passed').length,failed:results.filter(x=>x.status==='failed').length,skipped:results.filter(x=>x.status==='skipped').length,report:path.join(output,'results.json')}));
 if(results.some(x=>x.status==='failed'))process.exitCode=1;
})().catch(error=>{console.error(error);process.exitCode=2});
