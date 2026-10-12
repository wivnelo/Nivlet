const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const html=fs.readFileSync('Toolkit/settings.html','utf8'),start=html.indexOf('function createLeaveGuard(');
const source=html.slice(start,html.indexOf('\n}\n',start)+3);const context={};vm.createContext(context);vm.runInContext(source,context);const create=context.createLeaveGuard;
function setup(pages=['general','browser']){
 let dirty=[...pages],events=[],invalid=null;
 const guard=create({dirty:()=>dirty,prompt:()=>events.push('prompt'),dismiss:()=>events.push('dismiss'),busy:v=>events.push(['busy',v]),approve:i=>events.push(['approve',i]),focus:p=>events.push(['focus',p]),validate:p=>p!==invalid,save:p=>events.push(['save',p]),discard:()=>{dirty=[];events.push('discard')}});
 return {guard,events,invalid:p=>invalid=p,ack:(p,ok=true)=>{if(ok)dirty=dirty.filter(x=>x!==p);guard.receive(p,ok)}};
}
let x=setup([]);x.guard.request('close');assert(x.events.some(e=>e[0]==='approve'&&e[1]==='close'));
x=setup();x.guard.request('close');x.guard.cancel();assert(!x.events.some(e=>e[0]==='approve'));
x=setup();x.guard.request('close');x.guard.request('quit');x.guard.discard();assert(x.events.some(e=>e[0]==='approve'&&e[1]==='quit'));assert.equal(x.events.filter(e=>e==='prompt').length,1);
x=setup();x.guard.request('quit');x.guard.save();assert.deepEqual(x.events.filter(e=>e[0]==='save'),[['save','general']]);x.guard.cancel();x.guard.discard();assert(!x.events.some(e=>e[0]==='approve'));x.ack('other');assert(x.guard.saving);x.ack('general');assert.deepEqual(x.events.filter(e=>e[0]==='save'),[['save','general'],['save','browser']]);x.ack('browser');assert(x.events.some(e=>e[0]==='approve'));
x=setup();x.guard.request('quit');x.guard.save();x.ack('general');x.ack('browser',false);assert(!x.events.some(e=>e[0]==='approve'));assert(x.events.some(e=>e[0]==='focus'&&e[1]==='browser'));x.guard.request('quit');x.guard.save();x.ack('browser');assert(x.events.some(e=>e[0]==='approve'));
x=setup();x.invalid('browser');x.guard.request('close');x.guard.save();assert(!x.events.some(e=>e[0]==='save'||e[0]==='approve'));
console.log('Leave guard: clean close, cancel, discard, repeated quit, ordered acknowledgements, failure/retry and validation passed');
