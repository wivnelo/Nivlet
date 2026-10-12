// Exercise the actual settings keyboard handler without a native UI session.
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('Toolkit/settings.html','utf8');
const script=html.slice(html.indexOf("document.addEventListener('keydown',event=>{"),html.indexOf("// Settings status controls"));
assert(script.startsWith('document.addEventListener'));
const flags=Object.fromEntries(['ctrl','alt','cmd','shift'].map(mod=>['left-'+mod,{checked:false}]));
let handler,inputs=0;
vm.runInNewContext(script,{document:{addEventListener:(name,callback)=>{assert.equal(name,'keydown');handler=callback},getElementById:id=>flags[id]},Event:class{constructor(type,options){this.type=type;this.bubbles=options.bubbles}}});
const key={id:'left-key',value:'',matches:()=>true,classList:{contains:()=>false},blur(){this.blurred=true},dispatchEvent(event){assert.equal(event.type,'input');assert(event.bubbles);inputs++}};
function press(name,extra={}){const event={key:name,target:key,preventDefault(){this.prevented=true},...extra};handler(event);return event}
assert(press('ArrowLeft').prevented);assert.equal(key.value,'←');assert.equal(inputs,1,'Captured keys must emit input immediately');
press('ArrowUp',{ctrlKey:true,altKey:true});assert.equal(key.value,'↑');assert(flags['left-ctrl'].checked&&flags['left-alt'].checked&&!flags['left-cmd'].checked);
press('j');assert.equal(key.value,'J');assert(flags['left-ctrl'].checked,'Typing a plain key preserves selected modifiers');
press('˚',{code:'KeyK',altKey:true});assert.equal(key.value,'K');assert(flags['left-alt'].checked&&!flags['left-ctrl'].checked);
const beforeClear=inputs;press('Backspace');assert.equal(key.value,'');assert.equal(inputs,beforeClear+1,'Clearing must emit input');
press('ArrowDown');press('Delete');assert.equal(key.value,'');
assert(!press('Tab').prevented);press('Escape');assert(key.blurred);
press('F12');assert.equal(key.value,'');
press('ArrowRight',{isComposing:true});assert.equal(key.value,'');
key.matches=()=>false;assert(!press('ArrowLeft').prevented);key.matches=()=>true;
const launcherFlags=['ctrl','alt','cmd','shift'].map(mod=>({dataset:{mod},checked:false}));
key.classList.contains=()=>true;key.closest=()=>({querySelectorAll:()=>launcherFlags});
press('ArrowRight',{metaKey:true,shiftKey:true});assert.equal(key.value,'→');assert(launcherFlags[2].checked&&launcherFlags[3].checked&&!launcherFlags[0].checked);
console.log('Actual keyboard handler: arrow capture, modifiers, Option letter, clear, navigation and launcher rows passed');

press('Enter',{ctrlKey:true});assert.equal(key.value,'↩');
press('+',{code:'Equal',ctrlKey:true,shiftKey:true});assert.equal(key.value,'=');
press('–',{code:'Minus',altKey:true});assert.equal(key.value,'-');
console.log('Actual keyboard handler captures Return, shifted equals and Option minus');
