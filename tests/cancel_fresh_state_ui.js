// Uses only synthetic backend replies in the isolated settings document.
window.runCancelFreshStateUIRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send;
 let requests=[];
 try{
  send=value=>requests.push(value);window.receive({...data,ok:true,action:'load'});
  const nextLanguage=data.language==='en'?'zh-Hans':'en';
  document.getElementById('language').value=nextLanguage;updateSaveState();
  saveAllCoordinator.start();const request=requests.find(value=>value.action==='saveAllSettings');
  check(request,'Expected language save request');
  let current={...data,language:nextLanguage,translations:data.testTranslations?.[nextLanguage]||data.translations,general:request.pages.generalSection.config};
  window.receive({...current,ok:true,action:'saveAllSettings',requestID:request.requestID,saveBatch:{ok:true,results:[{page:'generalSection',status:'saved'}]}});
  // A newer runtime snapshot has no history. Cancel elsewhere must not revive
  // the initial history or language from that page's old saved response.
  current={...current,clipboard:{...current.clipboard,entries:[]}};
  window.receive({...current,ok:true,action:'clearClipboard'});
  const extraBrowser={id:'com.example.syntheticbrowser',name:'Synthetic Browser'};
  current={...current,browsers:[...current.browsers,extraBrowser]};
  window.receive({...current,ok:true,action:'refreshApplications'});
  document.getElementById('browserDefault').value=extraBrowser.id;
  document.getElementById('system-cpu').checked=!data.system.cpu;updateSaveState();
  window.showSection('systemSection');document.getElementById('cancelSettings').click();
  check(uiLanguage===nextLanguage&&document.documentElement.lang===nextLanguage,'Cancel reverted the current UI language');
  check(document.getElementById('language').value===nextLanguage,'Cancel changed another page configuration');
  check(clipEntries.length===0,'Cancel replayed stale clipboard history');
  check(document.getElementById('browserDefault').value===extraBrowser.id,'Cancel replayed old browser inventory and lost another page draft');
  check(dirtyPages().join(',')==='browserSection','Cancel must clear only its own draft');
  // General cancel must also preserve separately persisted sidebar ordering.
  const order=[...currentTabOrder()].reverse();
  current={...current,general:{...current.general,tabOrder:order}};
  window.receive({...current,ok:true,action:'saveTabOrder'});
  const persistedOrder=JSON.stringify(currentTabOrder());
  document.getElementById('showMenu').checked=!current.general.showMenu;updateSaveState();
  window.showSection('generalSection');document.getElementById('cancelSettings').click();
  check(JSON.stringify(currentTabOrder())===persistedOrder,'General cancel reverted immediately saved sidebar ordering');
  check(document.getElementById('showMenu').checked===current.general.showMenu,'General cancel did not restore its saved configuration');
  check(uiLanguage===nextLanguage&&clipEntries.length===0,'General cancel replayed old runtime metadata');
  // Discard on close uses the same per-page restore behavior.
  document.getElementById('system-cpu').checked=!data.system.cpu;updateSaveState();
  window.requestLeave('close');document.getElementById('leaveDiscard').click();
  check(!dirtyPages().length&&uiLanguage===nextLanguage&&clipEntries.length===0,'Discard replayed old metadata or retained drafts');
  check(requests.at(-1).action==='confirmLeave','Discard did not finish the pending close');
  return 'Cancel/discard restore only page configuration, retaining current language, clipboard history, browser inventory, other-page drafts and immediately persisted sidebar order';
 }finally{
  leaveGuard.cancel();send=original;window.receive({...data,ok:true,action:'load'});
 }
};
