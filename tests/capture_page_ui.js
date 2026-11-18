window.runCapturePageRegression=function(){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const oldSend=send;const sent=[];
 try{
  window.showSection('captureSection');
  const section=document.getElementById('captureSection');
  check(!section.hidden,'Screenshot page opens');
  // Rows follow the General page: inner padding, dividers, switches on the right.
  const rows=[...section.querySelectorAll('.capture-rows>.capture-item')];
  check(rows.length===5,'Five setting rows');
  for(const row of rows){
   const style=getComputedStyle(row),box=row.getBoundingClientRect(),group=row.parentElement.getBoundingClientRect();
   check(parseFloat(style.paddingLeft)>=16&&parseFloat(style.paddingRight)>=16,'Row padding: '+row.textContent.trim().slice(0,8));
   check(box.left>=group.left&&box.right<=group.right+0.5,'Row stays inside its card');
   for(const control of row.querySelectorAll('input:not([type=hidden]),select,button')){const r=control.getBoundingClientRect();check(r.right<=group.right-8,'Control touches card edge: '+(control.id||control.tagName))}
  }
  for(const row of section.querySelectorAll('.capture-toggle')){
   const toggle=row.querySelector('.switch-control').getBoundingClientRect(),text=row.getBoundingClientRect();
   check(toggle.right>text.right-60,'Switch sits on the right');
  }
  for(const help of section.querySelectorAll('.capture-help'))check(!help.closest('.settings-group'),'Help text sits below the card');

  const key=document.getElementById('capture-key');
  const press=(init)=>{key.focus();key.dispatchEvent(new KeyboardEvent('keydown',{bubbles:true,cancelable:true,...init}))};
  for(const mod of ['ctrl','alt','cmd','shift'])document.getElementById('capture-'+mod).checked=false;
  press({key:'F1',code:'F1'});
  check(key.value==='F1','F1 is recorded in the screenshot key field');
  refreshConflictHints();
  check(key.getAttribute('aria-invalid')!=='true','Plain F1 is valid for screenshots');
  press({key:'F13',code:'F13'});check(key.value==='F13','F13 is recorded');

  // A function key is still rejected on other pages.
  const left=document.getElementById('left-key'),before=left.value;
  left.focus();left.dispatchEvent(new KeyboardEvent('keydown',{bubbles:true,cancelable:true,key:'F1',code:'F1'}));
  check(left.value===before,'Window shortcuts do not take function keys');

  press({key:'5',code:'Digit5',metaKey:true,shiftKey:true});
  check(key.value==='5'&&document.getElementById('capture-cmd').checked&&document.getElementById('capture-shift').checked,'⌘⇧5 recorded with modifiers');

  send=body=>sent.push(structuredClone(body));
  document.getElementById('saveCapture').click();
  const body=sent.at(-1);
  check(body&&body.action==='saveCapture','Page save sends saveCapture');
  check(body.config.shortcut.key==='5'&&body.config.shortcut.mods.join('+')==='cmd+shift','Shortcut payload');
  check(body.config.saveDirectory==='~/Pictures/Nivlet'&&body.config.format==='png','Output payload');

  // Save All includes the Screenshot page once it is dirty.
  updateSaveState();
  check(dirtyPages().includes('captureSection'),'Screenshot page is marked dirty');
  check(document.querySelector('[aria-controls=captureSection]').dataset.dirty==='true','Sidebar marks unsaved Screenshot changes');
  sent.length=0;
  document.getElementById('saveSettings').click();
  const batch=sent.find(item=>item.action==='saveAllSettings');
  check(batch&&batch.pages.captureSection&&batch.pages.captureSection.config.shortcut.key==='5','Save All sends the Screenshot page');
  // Window focus sends one request (it used to send two, each answered with full state).
  sent.length=0;window.dispatchEvent(new Event('focus'));
  check(sent.length===1&&sent[0].action==='focusRefresh'&&Array.isArray(sent[0].bundleIDs),'Focus sends a single refresh request');
  return 'Screenshot page layout, F-key and ⌘⇧5 capture, page and global save payloads';
 }finally{send=oldSend}
};
