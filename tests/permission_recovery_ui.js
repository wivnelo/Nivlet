// Run only in an isolated real settings WebView with synthetic backend data.
window.runPermissionRecoveryRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw Error(message)},original=send;
 const dialog=document.getElementById('leaveDialog'),field=document.getElementById('showMenu');
 let requests=[];
 const receive=(accessibility,restartRequired=false)=>window.receive({...data,ok:true,action:'refreshPermissionsSilent',message:'',permissions:{accessibility,restartRequired}});
 try{
  send=value=>requests.push(value);
  window.receive({...data,ok:true,action:'load',message:''});window.showSection('generalSection');
  field.checked=!field.checked;updateSaveState();const draft=field.checked;requests=[];
  receive('denied');check(!document.querySelector('.permission-details').hidden,'Denied recovery guide hidden');
  receive('denied',true);check(!document.querySelector('.permission-state').hidden,'Stale trust recovery state hidden');
  check(document.querySelector('.permission-state').textContent===t('权限状态尚未同步，请退出并重新打开 Nivlet'),'Recovery message missing');
  check(field.checked===draft&&dirtyPages().includes('generalSection'),'Permission notification overwrites draft');
  check(!document.getElementById('quitForPermissions'),'Unwanted quit button remains');
  window.requestLeave('quit');check(dialog.open&&!requests.some(r=>r.action==='confirmLeave'),'Standard quit bypasses dirty guard');
  document.getElementById('leaveCancel').click();check(!dialog.open&&field.checked===draft,'Cancel loses draft');
  receive('granted');check(document.querySelector('.permission-details').hidden,'Granted state retains recovery guide');
  check(document.querySelector('.permission-state').textContent===t('辅助功能权限已开启'),'Granted state not refreshed');
  return 'Permission transitions preserve drafts; recovery quit uses real leave guard and cancellation';
 }finally{leaveGuard.cancel();send=original;window.receive({...data,ok:true,action:'load',message:''})}
};
