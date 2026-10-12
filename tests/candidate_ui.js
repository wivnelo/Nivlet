window.runCandidateRegression=function(data){
 const original=send,section=document.querySelector('[role=tab][aria-selected=true]').getAttribute('aria-controls');
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const sleep=document.getElementById('sleepShortcut'),before=sleep.checked;
 try{
  let captured;send=body=>captured=body;
  for(const id of Object.keys(pageSaves)){
   window.showSection(id);const button=document.getElementById('saveSettings');
   check(!button.hidden&&button.closest('footer'),'Save is missing from footer: '+id);
   check(document.getElementById(pageSaves[id]).getBoundingClientRect().width===0,'Old inline Save visible: '+id);
  }
  window.showSection('aboutSection');check(document.getElementById('saveSettings').hidden,'About has a redundant Save');
  window.showSection('clipSection');const clipEnabled=document.getElementById('clipEnabled');clipEnabled.checked=!clipEnabled.checked;updateSaveState();document.getElementById('saveSettings').click();
  check(captured.action==='saveClipboard'&&captured.popupShortcut&&captured.config,'Clipboard settings and hotkey are not saved together');
  const search=document.getElementById('clipSearch'),query=search.value;search.value='NIVLET-SEARCH-PROBE';search.dispatchEvent(new Event('input',{bubbles:true}));
  window.receive({...data,action:'refreshPermissionsSilent'});check(search.value==='NIVLET-SEARCH-PROBE','Permission refresh erased search');search.value=query;search.dispatchEvent(new Event('input',{bubbles:true}));
  window.showSection('generalSection');sleep.checked=!before;updateSaveState();check(document.getElementById('draftHint').dataset.dirty==='true','Dirty state missing');
  window.showSection('browserSection');check(sleep.checked===!before,'Tab switch lost draft');
  window.receive({...data,action:'refreshPermissionsSilent',browserStatus:{active:false}});check(document.getElementById('browserRoutingStatus').textContent.includes('Nivlet'),'Missing browser setup warning');
  window.receive({...data,action:'refreshPermissionsSilent',browserStatus:{active:true}});check(document.getElementById('browserRoutingStatus').textContent===t('已接管系统网页链接'),'Active handler status incorrect');
  check(document.getElementById('browserRoutingStatus').dataset.state==='granted','Active browser status not successful');
  check(document.getElementById('openDefaultBrowserSettings').hidden&&document.querySelector('.routing-actions').hidden,'Active browser still shows setup actions');
  window.receive({...data,action:'refreshPermissionsSilent',permissions:{accessibility:'denied'},browserStatus:{active:true}});
  check(document.getElementById('browserRoutingStatus').textContent===t('已接管系统网页链接'),'Accessibility refresh overwrote browser status');
  window.receive({...data,action:'refreshPermissionsSilent',browserStatus:{active:false}});
  check(document.getElementById('browserRoutingStatus').dataset.state!=='granted','Inactive browser retained successful status');
  check(!document.getElementById('openDefaultBrowserSettings').hidden&&!document.querySelector('.routing-actions').hidden&&!document.getElementById('setDefaultBrowser').hidden,'Setup actions did not return after losing default browser status');
  return 'Unified footer saves, combined clipboard save, draft indicators, search persistence and browser setup status passed';
 }finally{send=original;sleep.checked=before;window.receive({...data,action:'load'});window.showSection(section)}
};
