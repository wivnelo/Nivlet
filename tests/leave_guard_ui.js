
window.runLeaveGuardUIRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send;
 const dialog=document.getElementById('leaveDialog'),general=document.getElementById('showMenu'),system=document.getElementById('system-cpu');
 let requests=[];
 const reset=()=>{window.receive({...data,ok:true,action:'load',message:''});requests=[]};
 const draft=()=>{general.checked=!general.checked;system.checked=!system.checked;updateSaveState()};
 try{
  send=value=>requests.push(value);reset();
  window.requestLeave('close');check(requests[0]?.action==='confirmLeave'&&!dialog.open,'Clean close blocked');
  reset();draft();window.requestLeave('close');check(dialog.open,'Dirty close did not show dialog');
  check(document.activeElement.id==='leaveCancel','Safe return button not focused');
  document.getElementById('leaveCancel').click();check(!dialog.open&&dirtyPages().length===2&&!requests.length,'Return lost drafts or approved close');
  window.requestLeave('quit');dialog.dispatchEvent(new Event('cancel',{cancelable:true}));check(!dialog.open&&dirtyPages().length===2,'Esc cancel lost drafts');
  window.requestLeave('close');document.getElementById('leaveSave').click();
  check(requests.length===1&&requests[0].action==='saveAllSettings','Save all did not submit a coordinated batch');
  check(['leaveSave','leaveDiscard','leaveCancel'].every(id=>document.getElementById(id).disabled),'Pending save allows duplicate action');
  const first=requests[0],savedGeneral=first.pages.generalSection.config;
  window.receive({...data,general:savedGeneral,ok:false,action:'saveAllSettings',requestID:first.requestID,message:'',saveBatch:{ok:false,failedPage:'systemSection',message:'Synthetic save failure',results:[{page:'generalSection',status:'saved'},{page:'systemSection',status:'failed'}]}});
  check(!dialog.open&&dirtyPages().join(',')==='systemSection'&&system.checked!==data.system.cpu,'Failed save erased draft');
  check(!requests.some(value=>value.action==='confirmLeave'),'Failed save approved exit');
  window.requestLeave('quit');document.getElementById('leaveSave').click();
  const retry=requests.at(-1),savedSystem=retry.pages.systemSection.config;
  check(retry.action==='saveAllSettings'&&Object.keys(retry.pages).join(',')==='systemSection','Retry saved an already saved page');
  window.receive({...data,general:savedGeneral,system:savedSystem,ok:true,action:'saveAllSettings',requestID:retry.requestID,message:'',saveBatch:{ok:true,results:[{page:'systemSection',status:'saved'}]}});
  check(requests.at(-1).action==='confirmLeave'&&requests.at(-1).intent==='quit'&&!dirtyPages().length,'Successful retry did not approve quit');
  reset();draft();window.requestLeave('close');document.getElementById('leaveDiscard').click();
  check(!dialog.open&&!dirtyPages().length&&requests.at(-1).action==='confirmLeave','Discard did not restore saved pages');
  return 'Real dialog focus/cancel, coordinated saves, pending controls, failure drafts, retry and discard passed';
 }finally{leaveGuard.cancel();send=original;window.receive({...data,ok:true,action:'load',message:''})}
};
