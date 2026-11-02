window.runKeepAwakeUIRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw Error(message)},original=send;
 const awake=document.getElementById('keepAwake'),display=document.getElementById('keepDisplayOn');
 const change=(element,value)=>{element.checked=value;element.dispatchEvent(new Event('change',{bubbles:true}));updateSaveState()};
 let requests=[];
 try{
  send=value=>requests.push(value);window.receive({...data,ok:true,action:'load'});window.showSection('generalSection');requests=[];
  check(!awake.checked&&!display.checked&&display.disabled,'Old configuration must default both switches off');
  change(awake,true);check(!display.disabled&&!display.checked,'Main switch enables child without turning it on');
  change(display,true);check(!requests.length,'Draft must not call the native bridge');
  change(awake,false);check(!display.checked&&display.disabled,'Turning off main clears child');
  change(awake,true);change(display,true);
  document.getElementById('system-cpu').checked=!data.system.cpu;updateSaveState();
  document.getElementById('cancelSettings').click();
  check(!awake.checked&&!display.checked&&display.disabled,'Cancel restores both power controls');
  check(dirtyPages().join(',')==='systemSection','Cancel must preserve another page draft');
  change(awake,true);change(display,true);saveAllCoordinator.start();
  const request=requests.find(r=>r.action==='saveAllSettings');
  check(request&&request.pages.generalSection.config.keepAwake&&request.pages.generalSection.config.keepDisplayOn&&request.pages.systemSection,'Global save must collect power fields and other page');
  const current={...data,general:{...data.general,keepAwake:true,keepDisplayOn:true},system:request.pages.systemSection.config};
  window.receive({...current,ok:true,action:'saveAllSettings',requestID:request.requestID,saveBatch:{ok:true,results:[{page:'generalSection',status:'saved'},{page:'systemSection',status:'saved'}]}});
  check(awake.checked&&display.checked&&!display.disabled&&!dirtyPages().length,'Successful save updates baseline');
  const count=requests.length;saveAllCoordinator.start();check(requests.length===count,'No-op repeat save must not send requests');
  change(awake,false);saveAllCoordinator.start();const failed=requests.at(-1);
  window.receive({...current,ok:false,action:'saveAllSettings',requestID:failed.requestID,saveBatch:{ok:false,results:[{page:'generalSection',status:'failed',message:'Injected failure',current:{config:current.general,autoLaunch:false}}]}});
  check(!awake.checked&&!display.checked&&display.disabled&&dirtyPages().includes('generalSection'),'Failure preserves off draft for retry');
  document.getElementById('cancelSettings').click();check(awake.checked&&display.checked&&!display.disabled,'Cancel after failure restores actual saved state');
  for(const element of [awake,display])check(element.closest('label').textContent.includes(t(element===awake?'保持唤醒':'保持屏幕长亮')),'Translated switch label missing');
  const contentHeight=row=>{const style=getComputedStyle(row);return row.getBoundingClientRect().height-parseFloat(style.borderTopWidth)-parseFloat(style.borderBottomWidth)};
  const referenceHeight=contentHeight(document.getElementById('sleepShortcut').closest('p'));
  for(const element of [awake,display]){const row=element.closest('p');check(!row.querySelector('.help-text'),'Removed help text returned');check(Math.abs(contentHeight(row)-referenceHeight)<1,'Power row spacing differs from adjacent setting');}
  check(document.querySelectorAll('[role=tab]').length===8,'Eight existing settings pages preserved');
  return 'Default migration, dependency, deferred application, cancel isolation, global save, retry, repeated save and localization passed';
 }finally{send=original;window.receive({...data,ok:true,action:'load'})}
};
