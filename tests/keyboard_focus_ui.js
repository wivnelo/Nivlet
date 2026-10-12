window.runKeyboardFocusRegression=async function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send;let requests=[];
 const key=async(target,name,flags={})=>{const event=new KeyboardEvent('keydown',{key:name,bubbles:true,cancelable:true,...flags});target.dispatchEvent(event);await Promise.resolve();return event};
 try{
  send=value=>requests.push(value);window.receive({...data,ok:true,action:'load'});window.showSection('windowSection');
  const input=document.getElementById('left-key');input.focus();await key(input,'s',{metaKey:true});
  check(input.value==='S'&&document.getElementById('left-cmd').checked&&!requests.length,'Command-S saved while recording');
  window.requestLeave('close',{key:'w',metaKey:true});await Promise.resolve();
  check(input.value==='W'&&!leaveDialog.open&&!requests.length,'Native Command-W did not remain a recorded shortcut');
  window.requestLeave('quit',{key:'q',metaKey:true});await Promise.resolve();
  check(input.value==='Q'&&!leaveDialog.open&&!requests.length,'Native Command-Q quit while recording');
  document.getElementById('cancelSettings').click();await Promise.resolve();
  window.showSection('generalSection');const field=document.getElementById('showMenu');field.checked=!field.checked;updateSaveState();field.focus();requests=[];
  await key(field,'s',{metaKey:true});check(requests.length===1&&requests[0].action==='saveGeneral','Command-S does not use page save');
  requests=[];window.requestLeave('close');check(leaveDialog.open&&document.activeElement.id==='leaveCancel','Safe dialog focus missing');
  await key(document.activeElement,'Tab');check(document.activeElement.id==='leaveSave','Dialog Tab order wrong');
  await key(document.activeElement,'Tab');check(document.activeElement.id==='leaveDiscard','Dialog Tab escapes');
  await key(document.activeElement,'Tab',{shiftKey:true});check(document.activeElement.id==='leaveSave','Dialog Shift-Tab wrong');
  await key(document.activeElement,'s',{metaKey:true});check(!requests.length,'Command-S saved underneath dialog');
  leaveDialog.dispatchEvent(new Event('cancel',{cancelable:true}));check(!leaveDialog.open&&document.activeElement===field,'Cancel did not restore focus');
  document.getElementById('cancelSettings').click();await Promise.resolve();
  document.getElementById('tab-generalSection').focus();await key(document.activeElement,'Tab');check(document.activeElement.id==='autoLaunch','Tab did not enter current panel');
  await key(document.activeElement,'Tab',{shiftKey:true});check(document.activeElement.id==='tab-generalSection','Shift-Tab did not return to active tab');
  window.showSection('clipSection');const search=document.getElementById('clipSearch');search.focus();window.showImage({id:1,time:Date.now()/1000,url:'data:image/png;base64,iVBORw0KGgo='});
  check(document.activeElement.id==='closeImage','Preview focus missing');imageDialog.close();await new Promise(resolve=>setTimeout(resolve,0));check(document.activeElement===search,'Preview close did not restore focus');
  window.showSection('generalSection');window.previewConfiguration({modules:{}});requests=[];await key(document.getElementById('applyConfiguration'),'Escape');check(requests.at(-1)?.action==='cancelConfiguration','Esc did not cancel import preview');
  requests=[];await key(document.getElementById('applyConfiguration'),'s',{metaKey:true});check(!requests.length,'Command-S bypassed import confirmation');window.previewConfiguration(null);
  return 'Command-S priority, native W/Q routing, dialog Tab trap/return focus, panel traversal, preview focus and import Escape passed';
 }finally{leaveGuard.cancel();imageDialog.close();window.previewConfiguration(null);send=oldSend;window.receive({...data,ok:true,action:'load'})}
};
