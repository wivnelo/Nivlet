const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const html=fs.readFileSync('Toolkit/settings.html','utf8'),start=html.indexOf('function createSaveAllCoordinator(');
const source=html.slice(start,html.indexOf('\n}\n',start)+3),context={};vm.createContext(context);vm.runInContext(source,context);
function setup(){
 const events=[];let dirty=['generalSection','windowSection'],invalid=null;
 const io={dirty:()=>dirty,validate:p=>(events.push(['validate',p]),p!==invalid),focus:p=>events.push(['focus',p]),capture:p=>(events.push(['capture',p]),{config:{page:p}}),busy:v=>events.push(['busy',v]),send:value=>events.push(['send',value]),apply:(data,submitted)=>{events.push(['apply',data,submitted]);dirty=[]},complete:data=>events.push(['complete',data])};
 return {c:context.createSaveAllCoordinator(io),events,invalid:p=>invalid=p,dirty:v=>dirty=v};
}
let x=setup();x.dirty([]);assert(!x.c.start());assert.equal(x.events.length,0);
x=setup();x.invalid('windowSection');assert(!x.c.start());assert(!x.events.some(e=>e[0]==='capture'||e[0]==='send'));assert.deepEqual(x.events.at(-1),['focus','windowSection']);
x=setup();assert(x.c.start());assert(x.c.saving);assert(!x.c.start());const request=x.events.find(e=>e[0]==='send')[1];assert.deepEqual(Object.keys(request.pages),['generalSection','windowSection']);
assert.equal(request.action,'saveAllSettings');assert(x.events.findIndex(e=>e[0]==='capture')>x.events.map(e=>e[0]).lastIndexOf('validate'));
assert(!x.c.receive({action:'saveGeneral',requestID:request.requestID}));assert(!x.c.receive({action:'saveAllSettings',requestID:'stale'}));assert(x.c.saving);
const reply={action:'saveAllSettings',requestID:request.requestID,ok:false,saveBatch:{results:[{page:'generalSection',status:'saved'},{page:'windowSection',status:'failed'}]}};
assert(x.c.receive(reply));assert(!x.c.saving);assert.equal(x.events.filter(e=>e[0]==='apply').length,1);assert(!x.c.receive(reply));
assert.deepEqual(x.events.slice(-3).map(e=>e[0]),['apply','busy','complete']);assert.equal(x.events.at(-2)[1],false);
x.dirty(['windowSection']);assert(x.c.start());const retry=x.events.filter(e=>e[0]==='send').at(-1)[1];assert.notEqual(retry.requestID,request.requestID);assert.deepEqual(Object.keys(retry.pages),['windowSection']);
console.log('Global-save coordinator preflight, selected snapshots, matching acknowledgements, duplicate/stale suppression and retry passed');
