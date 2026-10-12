const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync('Toolkit/settings.html','utf8');
const start=html.indexOf('const currentTabOrder='),end=html.indexOf("for(const action of ['setDefaultBrowser'",start);
assert(start>=0&&end>start,'Tab handler source boundaries missing');
const source=html.slice(start,end);
const ids=['generalSection','windowSection','inputSection','clipSection','systemSection','browserSection','launcherSection','aboutSection'];
let handlers={},saved;
const nav={children:[],querySelectorAll(){return this.children},append(tab){this.insertBefore(tab,null)},insertBefore(tab,before){this.children=this.children.filter(x=>x!==tab);const index=before?this.children.indexOf(before):this.children.length;this.children.splice(index,0,tab)}};
const tabs=ids.map(id=>({id:'tab-'+id,section:id,style:{},dataset:{},classList:{add(){},remove(){}},getAttribute(){return id},getBoundingClientRect(){return {left:nav.children.indexOf(this)*100,width:100}}}));nav.children=[...tabs];
const document={getElementById:id=>tabs.find(t=>t.id===id),addEventListener:(type,fn)=>handlers[type]=fn,removeEventListener:type=>delete handlers[type]};
const context=vm.createContext({tabs,tabNav:nav,document,send:body=>saved=body});vm.runInContext(source,context);
vm.runInContext("applyTabOrder(['aboutSection','launcherSection','windowSection'])",context);
assert.equal(nav.children[0],tabs[0]);assert.equal(nav.children.at(-1),tabs.at(-1));assert.equal(nav.children[1],tabs[6]);
assert(!tabs[0].onpointerdown&&!tabs[7].onpointerdown);
function drag(tab,x,cancel=false){tab.onpointerdown({button:0,clientX:tab.getBoundingClientRect().left});handlers.pointermove({clientX:x});handlers[cancel?'pointercancel':'pointerup']({preventDefault(){}})}
drag(tabs[6],9999);assert.equal(nav.children.at(-2),tabs[6]);assert.equal(nav.children.at(-1),tabs[7]);assert(!saved.order.includes('aboutSection'));
drag(tabs[6],-9999);assert.equal(nav.children[0],tabs[0]);assert.equal(nav.children[1],tabs[6]);
const before=nav.children.map(t=>t.id);drag(tabs[6],9999,true);assert.deepEqual(nav.children.map(t=>t.id),before);
console.log('Actual tab handlers: fixed endpoints, legacy order, both drag boundaries and cancel passed');
