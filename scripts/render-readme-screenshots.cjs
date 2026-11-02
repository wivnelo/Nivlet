

const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const {pathToFileURL} = require('node:url');
const {chromium} = require('playwright');
const root = path.resolve(__dirname, '..');
const sourceCommit = '9ddcbf9dd6ac951463a9c0c8ed929357c44996c9';
const version = '2.0.1';
const build = process.env.NIVLET_SCREENSHOT_BUILD || '61';
if (build !== '61') throw Error('This media set illustrates 2.0.1 / Build 61');
const viewport = {width:1280,height:900};
const pages = {windows:'windowSection',clipboard:'clipSection',general:'generalSection',input:'inputSection',browser:'browserSection',launcher:'launcherSection',system:'systemSection',about:'aboutSection'};
const sha256 = value => crypto.createHash('sha256').update(value).digest('hex');
function verifySource() {

    const files = ['Toolkit/settings.html','Toolkit/modules/translations.lua'];
    const hashes = {};
    for (const file of files) {
        const expected = execFileSync('git',['show',`${sourceCommit}:${file}`],{cwd:root});
        const actual = fs.readFileSync(path.join(root,file));
        if (!expected.equals(actual)) throw Error(`Media source differs from ${sourceCommit}: ${file}`);
        hashes[file] = sha256(actual);
    }
    const versionFile = fs.readFileSync(path.join(root,'VERSION'));
    if (versionFile.toString().trim() !== version) throw Error('Unexpected media version');
    hashes.VERSION = sha256(versionFile);
    return {commit:sourceCommit,version,build,metadataSource:'working-tree VERSION',hashes};
}
const source = verifySource();
const pairs = execFileSync('lua',['-e','for k,v in pairs(dofile("Toolkit/modules/translations.lua")) do io.write(k,"\\0",v,"\\0") end'],{cwd:root}).toString().split('\0');
const english = {};
for(let i=0;i<pairs.length-1;i+=2) english[pairs[i]]=pairs[i+1];
const icon = 'data:image/png;base64,'+fs.readFileSync(path.join(root,'assets/nivlet-icon.png')).toString('base64');
function makeFixture(language='en') {
    if (!['en','zh-Hans'].includes(language)) throw Error('Media fixture supports en and zh-Hans');
    const en = language==='en';
    const names = en ? ['Studio Notes','Project Board','Reading List'] : ['灵感笔记','项目看板','阅读清单'];
    const ids = names.map((_,i)=>`com.example.demo${i+1}`);
    return {
        ok:true,action:'load',message:'',language,translations:en?{...english}:{},
        general:{keepAwake:false,keepDisplayOn:false,sleepShortcut:false,showMenu:true,appearance:'dark',language,tabOrder:[]},autoLaunch:false,
        permissions:{accessibility:'granted'},
        config:{enabled:true,shortcuts:Object.fromEntries([['left','LEFT'],['right','RIGHT'],['top','UP'],['bottom','DOWN'],['maximize','RETURN']].map(([id,key])=>[id,{key,mods:['ctrl','alt']}]))},
        sources:[{id:'demo.us',name:'ABC'},{id:'demo.pinyin',name:en?'Pinyin – Simplified':'简体拼音'}],
        input:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],sourceID:i===1?'demo.pinyin':'demo.us'}))},
        launcher:{enabled:true,rules:ids.map((bundleID,i)=>({bundleID,name:names[i],shortcut:{key:String(i+1),mods:['ctrl','alt']}}))},
        clipboard:{config:{enabled:true,images:true,persistent:false,limit:50,minutes:0,excluded:[]},entries:[
            {id:4,kind:'image',time:1793530800,text:en?'Sample image · Nivlet icon':'示例图片 · Nivlet 图标',preview:icon},
            {id:1,kind:'text',time:1793530740,text:en?'A little less switching. A little more focus.':'少一点切换，多一点专注。'},
            {id:2,kind:'text',time:1793530680,text:en?'Design reference: https://example.com/design-notes':'设计参考：https://example.com/design-notes'}
        ]},
        excludedAppNames:{},appIcons:Object.fromEntries([['com.apple.Safari','safari'],['com.google.Chrome','chrome']].map(([id,name])=>[id,'data:image/png;base64,'+fs.readFileSync(path.join(root,'docs/assets/browser-icons',name+'.png')).toString('base64')])),applicationStates:Object.fromEntries(ids.map((id,i)=>[id,{installed:true,name:names[i]}])),
        popupShortcut:{key:'V',mods:['cmd','shift']},popupShortcutDefault:{key:'V',mods:['cmd','shift']},
        system:Object.fromEntries(['network','cpu','memory','disk','ipv4','ipv6','date','lunar'].map(id=>[id,true])),
        browser:{enabled:true,defaultBrowser:'com.apple.Safari',rules:[{domain:'example.com',browser:'com.google.Chrome',subdomains:true}],appRules:[{bundleID:ids[0],name:names[0],browser:'com.apple.Safari'}]},
        browserStatus:{active:true},browsers:[{id:'com.apple.Safari',name:'Safari',capabilities:{clearBrowsingData:true}},{id:'com.google.Chrome',name:'Google Chrome',capabilities:{clearBrowsingData:true}}],
        about:{version,build,icon,license:fs.readFileSync(path.join(root,'LICENSE'),'utf8'),notices:fs.readFileSync(path.join(root,'THIRD-PARTY-NOTICES.md'),'utf8')}
    };
}
const data = makeFixture('en');
module.exports = {data,makeFixture,root,pages,verifySource,source,viewport,version,build};
if (require.main === module) (async()=>{
    const stage = path.join(root,'build/media-final/screenshots');
    fs.mkdirSync(stage,{recursive:true});
    const wrapper = path.join(stage,'preview.html');
    fs.writeFileSync(wrapper,`<!doctype html><html><meta charset="utf-8"><style>*{box-sizing:border-box}html,body{margin:0;height:100%;background:#1f1e20;color:#c4c4c8;font:12px -apple-system,BlinkMacSystemFont,sans-serif}#media-label{height:28px;display:flex;align-items:center;justify-content:center;background:#19191b;border-bottom:1px solid #363538;letter-spacing:.1px}iframe{display:block;width:100%;height:calc(100% - 28px);border:0}</style><div id="media-label"></div><iframe title="Nivlet settings UI preview" src="${pathToFileURL(path.join(root,'Toolkit/settings.html')).href}"></iframe></html>`);
    const browser = await chromium.launch({headless:true,chromiumSandbox:true,executablePath:process.env.NIVLET_SCREENSHOT_BROWSER||'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',args:['--disable-background-networking','--disable-component-update','--disable-default-apps','--disable-sync','--no-first-run','--no-default-browser-check']});
    const report = {source,version,build,viewport,deviceScaleFactor:2,contentViewport:{width:1280,height:872},theme:'dark',syntheticData:true,noNativeBackend:true,images:[]};
    try {
        for (const language of ['en','zh-Hans']) {
            const output = path.join(stage,language);fs.mkdirSync(output,{recursive:true});
            const context = await browser.newContext({viewport,deviceScaleFactor:2,locale:language==='en'?'en-US':'zh-CN',timezoneId:'UTC',colorScheme:'dark'});
            const page = await context.newPage(), errors=[];
            page.on('pageerror',error=>errors.push(error.message));
            await page.route('**/*',route=>route.request().url().startsWith('file:')?route.continue():route.abort());
            await page.addInitScript(()=>{window.webkit={messageHandlers:{toolkit:{postMessage(){}}}};});
            await page.goto(pathToFileURL(wrapper).href);
            const frame = page.frames().find(item=>item.url().endsWith('/Toolkit/settings.html'));
            await frame.waitForFunction(()=>typeof window.receive==='function');
            await page.evaluate(({language,version,build})=>document.getElementById('media-label').textContent=(language==='en'?'Sample data · UI preview':'示例数据 · 界面演示')+'  |  Nivlet '+version+' · Build '+build,{language,version,build});
            await frame.evaluate(data=>window.receive(data),makeFixture(language));
            await frame.evaluate(()=>window.receiveSystemValues({ok:true,values:{network:'↓ 24 KB/s  ↑ 8 KB/s',cpu:'12% / 8 Core',memory:'6.2 / 16 GB',disk:'128 / 512 GB',ipv4:'192.0.2.10',ipv6:'2001:db8::10',date:'2026-11-02',lunar:'—'}}));
            for (const [name,section] of Object.entries(pages)) {
                await frame.evaluate(section=>{window.showSection(section);document.querySelector('main').scrollTop=0;window.scrollTo(0,0)},section);
                await frame.evaluate(async()=>{await document.fonts.ready;await Promise.all([...document.images].map(img=>img.complete?Promise.resolve():new Promise(resolve=>{img.onload=resolve;img.onerror=resolve})))});
                const check = await frame.evaluate(()=>{
                    const visible=el=>el.getClientRects().length>0;
                    const panel=document.querySelector('.panel:not([hidden])'),footer=document.querySelector('footer'),main=document.querySelector('main');
                    const clipped=[];
                    for(const el of panel.querySelectorAll('button,input,select,textarea')){
                        if(!visible(el))continue;const r=el.getBoundingClientRect();
                        for(let p=el.parentElement;p;p=p.parentElement){if(!/^(hidden|clip|auto|scroll)$/.test(getComputedStyle(p).overflowX))continue;const b=p.getBoundingClientRect();if(r.left<b.left-1||r.right>b.right+1){clipped.push(el.id||el.textContent);break;}}
                    }
                    const image=document.querySelector('#clipHistory img'),rect=image?.getBoundingClientRect();
                    return {language:document.documentElement.lang,section:panel.id,invalid:panel.querySelectorAll('[aria-invalid=true]').length,overflow:document.documentElement.scrollWidth>innerWidth||main.scrollWidth>main.clientWidth+1,clipped,footerVisible:footer.getBoundingClientRect().bottom<=innerHeight+1,brokenImages:[...document.images].filter(visible).filter(img=>!img.naturalWidth).map(img=>img.id||img.alt),thumbnailVisible:panel.id==='clipSection'?!!image&&rect.top>=0&&rect.bottom<footer.getBoundingClientRect().top:null,popupLegacyVisible:panel.id==='clipSection'?!document.getElementById('popupLegacyHint').hidden:null};
                });
                if(check.language!==language||check.section!==section||check.invalid||check.overflow||check.clipped.length||!check.footerVisible||check.brokenImages.length||check.thumbnailVisible===false||check.popupLegacyVisible===true)throw Error(JSON.stringify({name,...check}));
                const file = path.join(output,`${name}.jpg`);
                await page.screenshot({path:file,type:'jpeg',quality:88,animations:'disabled'});
                report.images.push({language,page:name,file:path.relative(root,file),width:2560,height:1800,bytes:fs.statSync(file).size,sha256:sha256(fs.readFileSync(file)),check});
                console.log('CAPTURE',language,name);
            }
            if(errors.length)throw Error(errors.join('\n'));
            await context.close();
        }
        verifySource();
        fs.writeFileSync(path.join(stage,'report.json'),JSON.stringify(report,null,2));

        for(const image of report.images){const target=path.join(root,'docs/assets/screenshots',image.language==='en'?'en':'',`${image.page}.jpg`);fs.mkdirSync(path.dirname(target),{recursive:true});fs.copyFileSync(path.join(root,image.file),target);}
        console.log(JSON.stringify({count:report.images.length,dimensions:'2560x1800',report:path.join(stage,'report.json')}));
    } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1});
