// Real DOM events; synthetic settings only. No production bridge writes.
window.runShortcutCaptureRegression=async function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send;
 const press=async(input,key,flags={})=>{input.dispatchEvent(new KeyboardEvent('keydown',{key,bubbles:true,cancelable:true,...flags}));await Promise.resolve()};
 try{
  send=()=>{};window.receive({...data,ok:true,action:'load'});window.showSection('windowSection');
  const input=document.getElementById('left-key');
  await press(input,'k',{code:'KeyK',ctrlKey:true,altKey:true});
  check(input.value==='K','Physical key not recorded');
  check(document.getElementById('tab-windowSection').dataset.dirty==='true','Recording did not immediately mark draft');
  check(!document.getElementById('saveSettings').disabled&&!document.getElementById('cancelSettings').disabled,'Footer did not immediately enable');
  check(input.title==='⌃ ⌥ K'&&!document.querySelector('.shortcut-display'),'Full combination missing');
  const other=document.getElementById('right-key');await press(other,'k',{ctrlKey:true,altKey:true});
  check(input.getAttribute('aria-invalid')==='true'&&other.getAttribute('aria-invalid')==='true','Conflict not immediate');
  await press(other,'Delete');check(other.value===''&&!input.hasAttribute('aria-invalid'),'Clear did not immediately remove conflict');
  document.getElementById('cancelSettings').click();await Promise.resolve();
  check(document.getElementById('tab-windowSection').dataset.dirty==='false','Cancel did not restore draft');
  window.showSection('clipSection');const popup=document.getElementById('popup-key');await press(popup,'ArrowLeft',{metaKey:true,shiftKey:true});
  check(popup.title==='⌘ ⇧ ←','Special key combination display missing');
  check(!document.getElementById('saveSettings').disabled,'Popup capture did not mark draft');
  document.getElementById('cancelSettings').click();await Promise.resolve();
  window.showSection('launcherSection');addLauncherRule({bundleID:'com.example.a07',name:'A07 Synthetic App',shortcut:{key:'',mods:[]}});await Promise.resolve();
  const launcher=document.querySelector('#launcherRules .launcher-rule:last-child .launcher-key');await press(launcher,'Enter',{ctrlKey:true});
  check(launcher.value==='↩'&&launcher.title==='⌃ ↩','Launcher capture/display failed');
  await press(launcher,'Backspace');check(launcher.value===''&&launcher.title==='—','Launcher clear failed');
  check(document.documentElement.scrollWidth<=innerWidth+1,'Shortcut display overflows viewport');
  return 'Immediate drafts, footer, combination display, conflicts, clearing, cancel and launcher capture passed';
 }finally{send=oldSend;window.receive({...data,ok:true,action:'load'})}
};
