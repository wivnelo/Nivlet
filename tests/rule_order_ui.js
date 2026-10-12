window.runRuleOrderRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)},original=send;let request;
 try{
 send=value=>request=value;
 const fixture=structuredClone(data);fixture.action='load';fixture.input.rules=[{bundleID:'com.example.one',name:'One',sourceID:fixture.sources[0].id},{bundleID:'com.example.two',name:'Two',sourceID:fixture.sources[0].id}];fixture.launcher.rules=[{bundleID:'com.example.first',name:'First',shortcut:{key:'K',mods:['cmd']}},{bundleID:'com.example.second',name:'Second',shortcut:{key:'J',mods:['alt']}}];window.receive(fixture);
 window.showSection('launcherSection');check(document.getElementById('cancelSettings').disabled&&document.getElementById('saveSettings').disabled,'Clean page buttons enabled');
 const host=document.getElementById('launcherRules'),first=host.firstElementChild;
 const drag=(row,target)=>{const from=row.getBoundingClientRect(),to=target.getBoundingClientRect();row.querySelector('.rule-drag').dispatchEvent(new PointerEvent('pointerdown',{button:0,clientX:from.left+15,clientY:from.top+from.height/2,bubbles:true}));document.dispatchEvent(new PointerEvent('pointermove',{clientX:to.left+15,clientY:to.bottom-1,bubbles:true}));document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}))};
 const target=host.lastElementChild;drag(first,target);check(!host.querySelector('.rule-arrows'),'Arrow controls remain');check(host.lastElementChild===first&&first.querySelector('.launcher-key').value==='K','Drag reorder changed shortcut');
 check(document.getElementById('tab-launcherSection').dataset.dirty==='true','Missing launcher dirty dot');
 document.getElementById('saveSettings').click();check(request.config.rules[1].bundleID==='com.example.first','Save lost order');
 window.showSection('systemSection');check(document.getElementById('saveSettings').disabled&&document.getElementById('tab-launcherSection').dataset.dirty==='true','Navigation lost dot or enabled clean page save');const cpu=document.getElementById('system-cpu');cpu.checked=!cpu.checked;updateSaveState();
 window.showSection('launcherSection');document.getElementById('cancelSettings').click();check(host.firstElementChild.dataset.bundle==='com.example.first','Cancel failed to restore order');check(cpu.checked!==fixture.system.cpu,'Cancel erased another page');check(document.getElementById('tab-launcherSection').dataset.dirty==='false'&&document.getElementById('tab-systemSection').dataset.dirty==='true','Cancel cleared wrong dot');
 window.showSection('inputSection');const input=document.getElementById('inputRows'),row=input.firstElementChild,last=input.lastElementChild;drag(row,last);check(input.lastElementChild===row,'Drag reorder failed');check(row.querySelector('select').value===fixture.sources[0].id,'Drag changed input source');
 document.getElementById('cancelSettings').click();check(input.firstElementChild.dataset.bundle==='com.example.one','Input cancel failed');
 window.showSection('systemSection');document.getElementById('cancelSettings').click();check(cpu.checked===fixture.system.cpu,'System cancel failed');
 window.showSection('launcherSection');window.replaceLauncherApp({bundleID:'com.example.third',name:'Third'},'com.example.first');document.getElementById('cancelSettings').click();check(host.firstElementChild.dataset.bundle==='com.example.first','Cancel failed to undo app replacement');
 return 'Drag-only ordering, saved order, retained bindings, clean buttons and page-scoped cancel passed';
 }finally{send=original;window.receive({...data,action:'load'})}
};
