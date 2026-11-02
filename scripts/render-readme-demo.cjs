

const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require('playwright');
const {makeFixture,root,source,verifySource,version,build}=require('./render-readme-screenshots.cjs');
const output=path.join(root,'build/readme-demo');
const fps=8,seconds=28,width=1120,height=850,scale=.875,headerHeight=90;
const scenes=[
 {section:'windowSection',en:['Window layouts','Browse layout groups in the new sidebar interface.'],zh:['窗口布局','在统一侧边栏中切换布局分组。']},
 {section:'clipSection',en:['Clipboard history','Click an image to preview it, then search saved text.'],zh:['剪贴板历史','点击图片放大预览，再搜索已记录的文字。']},
 {section:'browserSection',en:['Browser routing','Change the fallback browser; keep the draft when navigating.'],zh:['浏览器分流','修改未匹配时使用的浏览器，切换页面仍保留草稿。']},
 {section:'launcherSection',en:['Save changes across pages','Edit an app shortcut, then save both pages together.'],zh:['跨页面一起保存','再修改应用快捷键，一次保存两个页面的修改。']}
];
(async()=>{
 fs.mkdirSync(output,{recursive:true});
 const wrapper=path.join(output,'preview.html');
 fs.writeFileSync(wrapper,`<!doctype html><html><meta charset="utf-8"><style>
 *{box-sizing:border-box}body{margin:0;background:#1f1e20;color:#dedede;font-family:-apple-system,BlinkMacSystemFont,sans-serif;overflow:hidden}
 header{height:90px;padding:15px 23px;display:flex;align-items:center;gap:14px;border-bottom:1px solid #302f31;background:#19191b}
 header img{width:44px;height:44px;border-radius:10px}h1{font-size:21px;margin:0 0 6px;font-weight:650}p{font-size:13px;color:#bdbdbf;margin:0}
 #label{margin-left:auto;color:#a9a9ad;font-size:11px;text-align:right;line-height:1.8;max-width:200px;flex-shrink:0}
 iframe{border:0;width:1280px;height:${(height-headerHeight)/scale}px;transform:scale(${scale});transform-origin:top left;display:block}
 #pointer{position:absolute;z-index:5;width:18px;height:18px;border:2px solid #92c7ff;border-radius:50%;background:#007aff33;box-shadow:0 0 0 4px #007aff16;pointer-events:none;transform:translate(-50%,-50%)}
 #progress{position:absolute;bottom:0;left:0;height:3px;background:#007aff}
 </style><header><img src="${makeFixture('en').about.icon}"><div><h1 id="title"></h1><p id="caption"></p></div><div id="label"></div></header><iframe title="Nivlet sample UI interaction demo" src="${pathToFileURL(path.join(root,'Toolkit/settings.html')).href}"></iframe><div id="pointer"></div><div id="progress"></div></html>`);
 const browser=await chromium.launch({headless:true,chromiumSandbox:true,executablePath:process.env.NIVLET_SCREENSHOT_BROWSER||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',args:['--disable-background-networking','--disable-component-update','--disable-default-apps','--disable-sync','--no-first-run','--no-default-browser-check']});
 const reports=[];
 try{
  for(const language of ['en','zh']){
   const dir=path.join(output,language);fs.mkdirSync(dir,{recursive:true});
   const context=await browser.newContext({viewport:{width,height},deviceScaleFactor:1,locale:language==='en'?'en-US':'zh-CN',timezoneId:'UTC',colorScheme:'dark'});
   const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.route('**/*',route=>route.request().url().startsWith('file:')?route.continue():route.abort());
   await page.addInitScript(()=>{window.webkit={messageHandlers:{toolkit:{postMessage(){}}}};});
   await page.goto(pathToFileURL(wrapper).href);
   const frame=page.frames().find(f=>f.url().endsWith('/Toolkit/settings.html'));
   await frame.waitForFunction(()=>typeof window.receive==='function');
   await frame.evaluate(fixture=>{
    window.mediaFixture=fixture;window.mediaRequests=[];window.mediaPendingSave=null;
    window.webkit.messageHandlers.toolkit.postMessage=body=>{
     const request=structuredClone(body);window.mediaRequests.push(request);
     if(request.action==='previewClipboard'){
      const entry=window.mediaFixture.clipboard.entries.find(item=>item.id===request.id);
      if(!entry?.preview)throw Error('Missing synthetic preview');
      window.showImage({...entry,url:entry.preview});
     }
     if(request.action==='saveAllSettings')window.mediaPendingSave=request;
    };
    window.receive(fixture);
   },makeFixture(language==='en'?'en':'zh-Hans'));
   await page.evaluate(({language,version,build})=>document.getElementById('label').innerHTML=(language==='en'?'SAMPLE DATA · UI DEMO<br>Simulated native replies':'示例数据 · 界面演示<br>原生回执为隔离模拟')+'<br>Nivlet '+version+' · Build '+build,{language,version,build});
   let pointer={x:80,y:145};
   const events=[];
   async function moveTo(selector,click=false){
    const control=frame.locator(selector).first();await control.scrollIntoViewIfNeeded();
    const box=await control.boundingBox();if(!box)throw Error('Invisible '+selector);
    pointer={x:box.x+box.width/2,y:box.y+box.height/2};
    await page.mouse.move(pointer.x,pointer.y);if(click)await control.click();
   }
   for(let sceneIndex=0;sceneIndex<scenes.length;sceneIndex++){
    const scene=scenes[sceneIndex],copy=scene[language];
    await moveTo('#tab-'+scene.section,true);
    await page.evaluate(copy=>{document.getElementById('title').textContent=copy[0];document.getElementById('caption').textContent=copy[1]},copy);
    events.push({frame:sceneIndex*56,action:'navigate',section:scene.section});
    for(let tick=0;tick<56;tick++){
     let click=false;
     if(sceneIndex===0){
      if(tick===8)await moveTo('#windowGroup');
      if(tick===16){await frame.locator('#windowGroup').selectOption('thirds');events.push({frame:tick,action:'layout-group',value:'thirds'});click=true;}
      if(tick===36){await frame.locator('#windowGroup').selectOption('grid');events.push({frame:tick,action:'layout-group',value:'grid'});click=true;}
     }
     if(sceneIndex===1){
      if(tick===6)await moveTo('#clipHistory [data-clip-action="preview"]');
      if(tick===10){await moveTo('#clipHistory [data-clip-action="preview"]',true);click=true;events.push({frame:56+tick,action:'thumbnail-preview'});}
      if(tick===24){pointer={x:width-30,y:height-60};await page.mouse.click(pointer.x,pointer.y);click=true;if(await frame.locator('#imageDialog').evaluate(el=>el.open))throw Error('Preview did not close');events.push({frame:56+tick,action:'outside-dismiss'});}
      if(tick===30)await moveTo('#clipSearch',true);
      const query=language==='en'?'design':'设计';
      if(tick>=34&&tick<34+query.length*2&&tick%2===0){await frame.locator('#clipSearch').pressSequentially(query[(tick-34)/2]);events.push({frame:56+tick,action:'search-input'});}
      if(tick===50){const count=await frame.locator('#clipHistory .clip-card').count();if(count!==1)throw Error('Search should show exactly one synthetic text result');}
     }
     if(sceneIndex===2){
      if(tick===10)await moveTo('#browserDefault');
      if(tick===20){await frame.locator('#browserDefault').selectOption('com.google.Chrome');click=true;events.push({frame:112+tick,action:'browser-draft'});}
      if(tick===42){const dirty=await frame.evaluate(()=>dirtyPages());if(dirty.join(',')!=='browserSection')throw Error('Expected only browser draft: '+dirty);}
     }
     if(sceneIndex===3){
      if(tick===6)await moveTo('.launcher-key',true);
      if(tick===12){await frame.locator('.launcher-key').first().fill('N');events.push({frame:168+tick,action:'launcher-draft'});}
      if(tick===22){const dirty=await frame.evaluate(()=>dirtyPages());if(dirty.join(',')!=='browserSection,launcherSection')throw Error('Missing cross-page drafts: '+dirty);await moveTo('#saveSettings');}
      if(tick===28){await moveTo('#saveSettings',true);click=true;const request=await frame.evaluate(()=>window.mediaPendingSave);if(!request||Object.keys(request.pages).join(',')!=='browserSection,launcherSection')throw Error('Save All did not collect both pages');events.push({frame:168+tick,action:'save-all-request',pages:Object.keys(request.pages)});}
      if(tick===34){
       await frame.evaluate(()=>{
        const request=window.mediaPendingSave;if(!request)throw Error('No simulated save pending');
        const fixture=window.mediaFixture;fixture.browser=request.pages.browserSection.config;fixture.launcher=request.pages.launcherSection.config;
        window.receive({...fixture,action:'saveAllSettings',requestID:request.requestID,ok:true,message:'',saveBatch:{ok:true,results:Object.keys(request.pages).map(page=>({page,status:'saved'}))}});
        window.mediaPendingSave=null;
       });events.push({frame:168+tick,action:'simulated-save-ack'});
      }
      if(tick===48){const state=await frame.evaluate(()=>({dirty:dirtyPages(),disabled:document.getElementById('saveSettings').disabled,status:document.getElementById('status').textContent}));if(state.dirty.length||!state.disabled)throw Error('Save acknowledgement did not clear drafts');events.push({frame:168+tick,action:'saved-state',status:state.status});}
     }
     await page.evaluate(({x,y,progress,click})=>{const p=document.getElementById('pointer');p.style.left=x+'px';p.style.top=y+'px';p.style.background=click?'#92c7ffbb':'#007aff33';document.getElementById('progress').style.width=progress+'%'},{...pointer,progress:(sceneIndex*56+tick+1)/(fps*seconds)*100,click});
     await page.screenshot({path:path.join(dir,String(sceneIndex*56+tick).padStart(4,'0')+'.png'),animations:'disabled'});
    }
    console.log(language,scene.section,'captured');
   }
   if(errors.length)throw new Error(errors.join('\n'));
   reports.push({language,events,errors,requests:await frame.evaluate(()=>window.mediaRequests.map(({action,requestID,pages})=>({action,requestID,pages:pages?Object.keys(pages):undefined})))});
   await context.close();
  }
  verifySource();
  const manifest={width,height,fps,frames:fps*seconds,seconds,source,languages:['en','zh'],durationsMs:Array(fps*seconds).fill(1000/fps),syntheticData:true,nativeReplies:'simulated',reports};
  fs.writeFileSync(path.join(output,'manifest.json'),JSON.stringify(manifest,null,2));
  console.log(JSON.stringify({frames:manifest.frames,languages:manifest.languages,manifest:path.join(output,'manifest.json')}));
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
