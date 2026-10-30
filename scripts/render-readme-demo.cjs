// Capture bilingual, read-only UI interactions. Requires Playwright and the screenshot fixture.
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const {chromium}=require('playwright');
const {data,root}=require('./render-readme-screenshots.cjs');
const output=path.join(root,'build/readme-demo');
const fps=8, seconds=16;
const scenes=[
    {section:'windowSection',target:'#windowGroup',en:['Window layouts','Choose halves, thirds or a grid.'],zh:['窗口布局','半屏、三分区、九宫格，按需选择。']},
    {section:'clipSection',target:'#clipSearch',en:['Clipboard history','Find a saved snippet as you type.'],zh:['剪贴板历史','输入关键词，快速找到保存的内容。']},
    {section:'browserSection',target:'#browserDefault',en:['Browser routing','Choose a browser for unmatched links.'],zh:['浏览器分流','为未匹配规则的链接选择浏览器。']},
    {section:'launcherSection',target:'.launcher-key',en:['App shortcuts','Give your favorite apps a shortcut.'],zh:['应用快捷启动','为常用应用设置顺手的快捷键。']}
];
(async()=>{
 fs.mkdirSync(output,{recursive:true});
 const wrapper=path.join(output,'preview.html');
 fs.writeFileSync(wrapper,`<!doctype html><html><meta charset="utf-8"><style>
 *{box-sizing:border-box}body{margin:0;background:#202023;color:#f5f5f7;font-family:-apple-system,BlinkMacSystemFont,sans-serif;overflow:hidden}
 header{height:86px;padding:16px 25px;display:flex;align-items:center;gap:14px;border-bottom:1px solid #45454b}
 header img{width:44px;height:44px;border-radius:10px}h1{font-size:21px;margin:0 0 5px;font-weight:650}p{font-size:14px;color:#b8bbc3;margin:0}
 #label{margin-left:auto;color:#9299a7;font-size:12px;text-align:right;line-height:1.7}
 iframe{border:0;width:1080px;height:800px;transform:scale(.888888889);transform-origin:top left;display:block}
 #pointer{position:absolute;z-index:4;width:22px;height:22px;border:2px solid #86c8ff;border-radius:50%;background:#469af044;box-shadow:0 0 0 5px #469af019;pointer-events:none;transform:translate(-50%,-50%)}
 #progress{position:absolute;bottom:0;left:0;height:3px;background:#68b7f7}
 </style><header><img src="${data.about.icon}"><div><h1 id="title"></h1><p id="caption"></p></div><div id="label"></div></header><iframe src="${pathToFileURL(path.join(root,'Toolkit/settings.html')).href}"></iframe><div id="pointer"></div><div id="progress"></div></html>`);
 const browser=await chromium.launch({headless:true,...(process.env.NIVLET_SCREENSHOT_BROWSER?{executablePath:process.env.NIVLET_SCREENSHOT_BROWSER}:{})});
 try{
  for(const language of ['en','zh']){
   const dir=path.join(output,language);fs.mkdirSync(dir,{recursive:true});
   const context=await browser.newContext({viewport:{width:960,height:800},deviceScaleFactor:1,locale:language==='en'?'en-US':'zh-CN',timezoneId:'UTC',colorScheme:'dark'});
   const page=await context.newPage(),errors=[];page.on('pageerror',e=>errors.push(e.message));
   await page.route('**/*',route=>route.request().url().startsWith('file:')?route.continue():route.abort());
   await page.addInitScript(()=>{window.webkit={messageHandlers:{toolkit:{postMessage(){}}}};});
   await page.goto(pathToFileURL(wrapper).href);
   const frame=page.frames().find(f=>f.url().endsWith('/Toolkit/settings.html'));
   await frame.waitForFunction(()=>typeof window.receive==='function');
   const fixture=structuredClone(data);
   if(language==='zh'){
    fixture.language='zh-Hans';fixture.general.language='zh-Hans';
    const names=['灵感笔记','项目看板','阅读清单'];
    for(const config of [fixture.input,fixture.launcher])config.rules.forEach((rule,i)=>rule.name=names[i]);
    fixture.browser.appRules[0].name=names[0];
    Object.values(fixture.applicationStates).forEach((state,i)=>state.name=names[i]);
    fixture.sources[1].name='简体拼音';
    fixture.clipboard.entries[0].text='少一点切换，多一点专注。';
    fixture.clipboard.entries[1].text='设计参考：https://example.com/design-notes';
    fixture.clipboard.entries[2].text='发布清单\n审阅变更 · 运行测试 · 更新文档';
   }
   await frame.evaluate(data=>window.receive(data),fixture);
   await page.evaluate(language=>document.getElementById('label').textContent=language==='en'?'NIVLET FOR MAC · UI DEMO':'NIVLET FOR MAC · 界面演示',language);
   for(let sceneIndex=0;sceneIndex<scenes.length;sceneIndex++){
    const scene=scenes[sceneIndex],copy=scene[language];
    await frame.evaluate(section=>{window.showSection(section);document.querySelector('main').scrollTop=0;window.scrollTo(0,0)},scene.section);
    await page.evaluate(copy=>{document.getElementById('title').textContent=copy[0];document.getElementById('caption').textContent=copy[1]},copy);
    const rect=await frame.locator(scene.target).first().evaluate(el=>{const r=el.getBoundingClientRect();return {x:r.x+r.width/2,y:r.y+r.height/2}});
    for(let tick=0;tick<4*fps;tick++){
     if(tick===14){
      if(sceneIndex===0)await frame.locator('#windowGroup').selectOption('thirds');
      if(sceneIndex===2)await frame.locator('#browserDefault').selectOption('com.google.Chrome');
      if(sceneIndex===3){await frame.locator('.launcher-key').first().fill('N');}
     }
     if(sceneIndex===1&&tick>=12&&tick<=22&&tick%2===0){const query=language==='en'?'design':'设计';await frame.locator('#clipSearch').fill(query.slice(0,(tick-10)/2));}
     const t=Math.min(1,tick/12),ease=t*t*(3-2*t);
     await page.evaluate(({x,y,progress,click})=>{const p=document.getElementById('pointer');p.style.left=x+'px';p.style.top=y+'px';p.style.background=click?'#91d0ff99':'#469af044';document.getElementById('progress').style.width=progress+'%'},{x:70+(rect.x*8/9-70)*ease,y:155+(rect.y*8/9+86-155)*ease,progress:(sceneIndex*32+tick+1)/(fps*seconds)*100,click:tick===14||tick===15});
     await page.screenshot({path:path.join(dir,String(sceneIndex*32+tick).padStart(4,'0')+'.png'),animations:'disabled'});
    }
    console.log(language,scene.section,'captured');
   }
   if(errors.length)throw new Error(errors.join('\n'));
   await context.close();
  }
 }finally{await browser.close()}
})().catch(error=>{console.error(error);process.exitCode=1});
