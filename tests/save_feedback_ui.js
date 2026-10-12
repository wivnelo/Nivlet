// Isolated settings WebView only: synthetic backend responses, no user configuration.
window.runSaveFeedbackRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send,oldTimeout=window.setTimeout,oldClear=window.clearTimeout;
 const timers=new Map();let serial=0,requests=[];
 const status=document.getElementById('status');
 try{
  send=value=>requests.push(value);
  window.setTimeout=(fn,ms)=>{const id=++serial;timers.set(id,{fn,ms});return id};window.clearTimeout=id=>timers.delete(id);
  window.receive({...data,ok:true,action:'load',message:''});window.showSection('generalSection');
  const field=document.getElementById('showMenu');field.checked=!field.checked;updateSaveState();
  document.getElementById('saveSettings').click();check(requests.at(-1).action==='saveGeneral','Footer no longer submits');
  const general=requests.at(-1).config;
  window.receive({...data,ok:true,action:'saveGeneral',general,message:'Synthetic success'});
  check(status.textContent==='Synthetic success'&&status.dataset.result==='success','Success missing');
  const timer=[...timers.values()].find(timer=>timer.ms===3000);check(timer,'Success does not expire after 3 seconds');
  window.receive({...data,ok:true,action:'refreshPermissionsSilent',message:''});check(status.textContent==='Synthetic success','Silent refresh cleared feedback');
  timer.fn();check(!status.textContent,'Success did not expire');
  window.receive({...data,ok:true,action:'saveGeneral',general,message:'Synthetic success'});window.showSection('systemSection');
  check(!status.textContent&&![...timers.values()].some(timer=>timer.ms===3000),'Navigation retained success/timer');
  window.showSection('generalSection');field.checked=!general.showMenu;updateSaveState();
  window.receive({...data,ok:true,action:'saveSystem',message:'Other page saved'});check(!status.textContent,'Background page save leaked success');
  window.receive({...data,ok:false,action:'saveGeneral',message:t('无法修改启动设置，请在系统设置中检查登录项')});
  const note=document.querySelector('#generalSection .save-error');
  check(note?.previousElementSibling.contains(document.getElementById('autoLaunch')),'Login error not near its control');
  check(note.textContent.includes(t('打开登录项设置检查后，再重新保存。')),'Login recovery missing');
  check(field.checked!==general.showMenu&&dirtyPages().includes('generalSection'),'Error lost draft');
  window.receive({...data,ok:true,action:'refreshPermissionsSilent',message:''});check(note.isConnected,'Silent refresh erased error');
  window.showSection('systemSection');window.showSection('generalSection');check(note.isConnected&&!status.textContent,'Page error should remain when footer is cleared');
  field.dispatchEvent(new Event('change',{bubbles:true}));check(!note.isConnected,'Editing retained stale backend error');
  window.receive({...data,ok:false,action:'saveGeneral',message:''});check(document.querySelector('.save-error').textContent.includes(t('保存失败，修改尚未保存。')),'Empty backend failure lacks fallback');
  document.getElementById('cancelSettings').click();check(!document.querySelector('#generalSection .save-error'),'Discard retained backend error');
  window.showSection('windowSection');const key=document.getElementById('left-key');key.value='Q';
  for(const mod of Object.keys(mods))document.getElementById('left-'+mod).checked=false;
  refreshConflictHints();let hint=document.getElementById(key.dataset.errorNote);
  check(!hint.hidden&&hint.closest('tr')===key.closest('tr')&&key.getAttribute('aria-describedby')===hint.id,'Shortcut explanation not attached to row/control');
  key.value='';refreshConflictHints();check(hint.hidden&&!key.hasAttribute('aria-describedby'),'Fixed shortcut retained error');
  window.showSection('browserSection');addBrowserRule({domain:'same.example',browser:data.browsers[0].id});addBrowserRule({domain:'SAME.EXAMPLE.',browser:data.browsers[0].id});browserDomainConflicts();
  const domain=document.querySelector('#browserRules [aria-invalid=true]');hint=document.getElementById(domain.dataset.errorNote);
  check(!hint.hidden&&hint.closest('.browser-rule')===domain.closest('.browser-rule')&&hint.textContent.includes(t('删除重复规则，或改为不同域名。')),'Domain correction not near row');
  window.showSection('clipSection');
  window.receive({...data,ok:false,action:'saveClipboard',message:t('排除应用须填写有效 Bundle ID')});
  check(document.getElementById('clipExcluded').closest('details').open&&document.querySelector('#clipSection .save-error').textContent.includes(t('移除无效排除项，再通过添加应用重新选择。')),'Excluded Bundle ID error is hidden or not actionable');
  const rows=[...document.querySelectorAll('.browser-rule')];rows[0].remove();addBrowserRule({domain:'another.example',browser:data.browsers[0].id});browserDomainConflicts();
  const ids=[...document.querySelectorAll('.field-error')].map(note=>note.id);check(new Set(ids).size===ids.length,'Removing/readding rows duplicated error IDs');
  return 'Success timeout/navigation, silent refresh, page-local actionable errors, draft preservation and inline validation passed';
 }finally{clearStatus();window.setTimeout=oldTimeout;window.clearTimeout=oldClear;send=oldSend;window.receive({...data,ok:true,action:'load',message:''})}
};
