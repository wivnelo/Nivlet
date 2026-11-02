// Verify public media references and play the actual encoded GIFs in isolation.
const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {pathToFileURL}=require('node:url');
const {chromium}=require('playwright');
const {root,verifySource}=require('./render-readme-screenshots.cjs');
(async()=>{
 const output=path.join(root,'build/media-final/playback');fs.mkdirSync(output,{recursive:true});
 const source=verifySource();
 const files=['README.md','README.zh-CN.md','docs/screenshots.html'];
 const references=[];
 for(const file of files){
  const text=fs.readFileSync(path.join(root,file),'utf8');
  const refs=[...text.matchAll(/(?:src|href)="([^"#]+\.(?:jpg|gif|png|mp4|webm|mov))"/g)].map(match=>match[1]);
  for(const ref of refs){if(/^https?:/.test(ref))continue;const target=path.resolve(root,path.dirname(file),ref);if(!fs.existsSync(target))throw Error('Missing '+file+': '+ref);references.push({file,ref});}
 }
 const wrapper=path.join(output,'preview.html');
 fs.writeFileSync(wrapper,'<!doctype html><html><meta charset="utf-8"><style>html,body{margin:0;background:#19191b}img{display:block;width:1120px;height:850px}</style><img alt="Nivlet sample UI demo">');
 const browser=await chromium.launch({headless:true,chromiumSandbox:true,executablePath:process.env.NIVLET_SCREENSHOT_BROWSER||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',args:['--disable-background-networking','--disable-component-update','--disable-default-apps','--disable-sync','--no-first-run','--no-default-browser-check']});
 const playback=[];
 try{
  for(const language of ['en','zh']){
   const context=await browser.newContext({viewport:{width:1120,height:850},deviceScaleFactor:1});
   const page=await context.newPage();await page.route('**/*',r=>r.request().url().startsWith('file:')?r.continue():r.abort());
   await page.goto(pathToFileURL(wrapper).href);
   const gif=path.join(root,'docs/assets/demos',`overview-${language}.gif`);
   await page.locator('img').evaluate((img,src)=>{img.src=src;},pathToFileURL(gif).href);
   await page.waitForFunction(()=>document.querySelector('img').complete&&document.querySelector('img').naturalWidth===1120);
   let elapsed=0;const captures=[];
   for(const ms of [0,9000,15000,26000]){
    if(ms>elapsed)await page.waitForTimeout(ms-elapsed);elapsed=ms;
    const file=path.join(output,`${language}-${String(ms).padStart(5,'0')}.png`);await page.screenshot({path:file});
    captures.push({ms,path:path.relative(root,file),sha256:crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex')});
   }
   if(new Set(captures.map(c=>c.sha256)).size!==captures.length)throw Error('GIF playback did not advance for '+language);
   playback.push({language,gif:path.relative(root,gif),captures,animated:true});await context.close();
  }
  verifySource();fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({source,references,playback},null,2));console.log(JSON.stringify({references:references.length,languages:playback.length,report:path.join(output,'report.json')}));
 }finally{await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
