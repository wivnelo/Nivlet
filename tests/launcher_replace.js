// Exercise the actual replacement and duplicate handlers without writing user configuration.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('Toolkit/settings.html','utf8');
const source=html.slice(html.indexOf('window.replaceLauncherApp=function'),html.indexOf("document.getElementById('chooseLauncherApp').onclick"));
const duplicate=html.slice(html.indexOf('function existingApp('),html.indexOf('function normalizedShortcutKey('));
const bundleIDs=html.slice(html.indexOf('function validBundleID('),html.indexOf('function refreshApplications('));
const row=(bundle,name)=>({dataset:{bundle,name},label:{textContent:name,title:bundle},key:'K',mods:['ctrl','cmd'],querySelector(){return this.label}});
const first=row('com.example.first','First'),second=row('com.example.second','Second');
const host={children:[first,second]};let notice,highlight,dirty=0,conflicts=0;
const context=vm.createContext({window:{},appIcons:{},setRuleIcon:()=>{},document:{getElementById:()=>host},t:x=>x,ruleNotice:(_,message,r)=>{notice=message;highlight=r},refreshConflictHints:()=>conflicts++,updateSaveState:()=>dirty++});
vm.runInContext(bundleIDs+duplicate+source,context);const replace=context.window.replaceLauncherApp;
replace({bundleID:'com.example.third',name:'Third'},first.dataset.bundle);
assert.equal(host.children[0],first);assert.equal(first.dataset.bundle,'com.example.third');assert.equal(first.label.textContent,'Third');assert.equal(first.key,'K');assert.deepEqual(first.mods,['ctrl','cmd']);assert.equal(dirty,1);assert.equal(conflicts,1);
replace({bundleID:'COM.EXAMPLE.SECOND',name:'Duplicate'},first.dataset.bundle);
assert.equal(first.dataset.bundle,'com.example.third');assert.equal(highlight,second);assert(notice.includes('此应用已添加'));assert.equal(dirty,1);
for(const rule of [null,{bundleID:'not a bundle id',name:'Invalid'},{bundleID:'',name:'Empty'},{bundleID:'com.example.third',name:'Same'},{bundleID:'com.example.fourth'}])replace(rule,first.dataset.bundle);
assert.equal(first.dataset.name,'Third');assert.equal(dirty,1);
// FinalShell 的 Bundle ID 是 "st"，没有点号；更换应用不能因此被丢弃。
replace({bundleID:'st',name:'FinalShell'},first.dataset.bundle);
assert.equal(first.dataset.bundle,'st');assert.equal(first.label.textContent,'FinalShell');assert.equal(dirty,2);
host.children.shift();replace({bundleID:'com.example.fourth',name:'Fourth'},first.dataset.bundle);assert.equal(second.dataset.bundle,'com.example.second');
assert(html.includes("replace.onclick=()=>send({action:'chooseLauncherApp',replaceBundleID:row.dataset.bundle})"));
console.log('App replacement preserves shortcut/order, marks draft, rejects duplicate/invalid/same/cancelled or removed targets');
