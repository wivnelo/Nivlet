// Render the real settings UI with synthetic, read-only data. No app is launched.
// Requires Node.js, Lua and Playwright; optionally set NIVLET_SCREENSHOT_BROWSER.
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const root = path.resolve(__dirname, '..');
const output = path.join(root, 'docs/assets/screenshots/en');
const build = process.env.NIVLET_SCREENSHOT_BUILD;
if (!/^\d+$/.test(build || '')) throw new Error('Set NIVLET_SCREENSHOT_BUILD to the build being illustrated');
const pairs = execFileSync('lua', ['-e', 'for k,v in pairs(dofile("Toolkit/modules/translations.lua")) do io.write(k,"\\0",v,"\\0") end'], {cwd:root}).toString().split('\0');
const translations = {};
for(let i=0;i<pairs.length-1;i+=2) translations[pairs[i]]=pairs[i+1];
const icon = 'data:image/png;base64,'+fs.readFileSync(path.join(root,'assets/nivlet-icon.png')).toString('base64');
const names = ['Studio Notes','Project Board','Reading List'];
const ids = names.map((_,i)=>`com.example.demo${i+1}`);
const data = {
    ok:true, action:'load', message:'', language:'en', translations,
    general:{sleepShortcut:false,showMenu:true,appearance:'dark',language:'en',tabOrder:[]},
    autoLaunch:false, permissions:{accessibility:'granted'},
    config:{enabled:true,shortcuts:Object.fromEntries([['left','LEFT'],['right','RIGHT'],['top','UP'],['bottom','DOWN'],['maximize','RETURN']].map(([id,key])=>[id,{key,mods:['ctrl','alt']}]))},
    sources:[{id:'demo.us',name:'ABC'},{id:'demo.pinyin',name:'Pinyin – Simplified'}],
    input:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],sourceID:i===1?'demo.pinyin':'demo.us'}))},
    launcher:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],shortcut:{key:String(i+1),mods:['ctrl','alt']}}))},
    clipboard:{paused:false,config:{enabled:true,images:true,persistent:false,limit:50,minutes:0,excluded:[]},entries:[
        {id:1,time:1793325600,text:'A little less switching. A little more focus.'},
        {id:2,time:1793325540,text:'https://example.com/design-notes'},
        {id:3,time:1793325480,text:'Release checklist\nReview the changes · Run tests · Update documentation'}
    ]},
    excludedAppNames:{},appIcons:{},applicationStates:Object.fromEntries(ids.map((id,i)=>[id,{installed:true,name:names[i]}])),
    popupShortcut:{key:'V',mods:['ctrl','alt']},
    system:Object.fromEntries(['network','cpu','memory','disk','ipv4','ipv6','mac','date','lunar'].map(id=>[id,true])),
    browser:{enabled:true,defaultBrowser:'com.apple.Safari',rules:[{domain:'example.com',browser:'com.google.Chrome',subdomains:true}],appRules:[{bundleID:ids[0],name:names[0],browser:'com.apple.Safari'}]},
    browserStatus:{active:true},browsers:[{id:'com.apple.Safari',name:'Safari'},{id:'com.google.Chrome',name:'Google Chrome'}],
    about:{version:fs.readFileSync(path.join(root,'VERSION'),'utf8').trim(),build,icon,license:fs.readFileSync(path.join(root,'LICENSE'),'utf8'),notices:fs.readFileSync(path.join(root,'THIRD-PARTY-NOTICES.md'),'utf8')}
};
const pages={windows:'windowSection',clipboard:'clipSection',general:'generalSection',input:'inputSection',browser:'browserSection',launcher:'launcherSection',system:'systemSection',about:'aboutSection'};
module.exports = {data, root};
if (require.main === module) (async()=>{
    fs.mkdirSync(output,{recursive:true});
    const browser=await chromium.launch({headless:true,...(process.env.NIVLET_SCREENSHOT_BROWSER?{executablePath:process.env.NIVLET_SCREENSHOT_BROWSER}:{})});
    try {
        const context=await browser.newContext({viewport:{width:1080,height:980},deviceScaleFactor:2,locale:'en-US',timezoneId:'UTC',colorScheme:'dark'});
        const page=await context.newPage();
        const errors=[];page.on('pageerror',e=>errors.push(e.message));
        await page.route('**/*',route=>route.request().url().startsWith('file:')?route.continue():route.abort());
        await page.addInitScript(()=>{window.webkit={messageHandlers:{toolkit:{postMessage(){}}}};});
        await page.goto(pathToFileURL(path.join(root,'Toolkit/settings.html')).href);
        await page.evaluate(data=>window.receive(data),data);
        await page.evaluate(()=>window.receiveSystemValues({ok:true,values:{network:'↓ 24 KB/s  ↑ 8 KB/s',cpu:'12%',memory:'6.2 / 16 GB',disk:'128 / 512 GB',ipv4:'192.0.2.10',ipv6:'2001:db8::10',mac:'02:00:00:00:00:01',date:'2026-10-30',lunar:'—'}}));
        for(const [name,section] of Object.entries(pages)){
            await page.evaluate(section=>{window.showSection(section);document.querySelector('main').scrollTop=0;window.scrollTo(0,0)},section);
            await page.evaluate(()=>document.fonts.ready);
            await page.screenshot({path:path.join(output,name+'.jpg'),type:'jpeg',quality:88,animations:'disabled'});
            const check=await page.evaluate(()=>({language:document.documentElement.lang,tab:document.querySelector('[role=tab][aria-selected=true]').textContent,overflow:document.documentElement.scrollWidth>innerWidth,invalid:document.querySelectorAll('.panel:not([hidden]) [aria-invalid=true]').length}));
            if(check.language!=='en'||check.overflow||check.invalid)throw new Error(JSON.stringify({name,...check}));
            console.log(name,JSON.stringify(check));
        }
        if(errors.length)throw new Error(errors.join('\n'));
        await context.close();
    } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1});
