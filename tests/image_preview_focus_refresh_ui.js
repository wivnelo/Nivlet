
window.runImagePreviewFocusRefreshRegression=async function(data){
 const check=(value,message)=>{if(!value)throw Error(message)},tick=()=>new Promise(resolve=>setTimeout(resolve,0));
 const oldSend=send,now=Date.now()/1000,canvas=document.createElement('canvas');canvas.width=320;canvas.height=120;
 const context=canvas.getContext('2d');context.fillStyle='#dbe8f4';context.fillRect(0,0,320,120);context.fillStyle='#34506b';context.font='18px sans-serif';context.fillText('Synthetic preview',24,66);
 const url=canvas.toDataURL(),entry={id:600001,time:now,kind:'image',text:'Synthetic retained image',preview:url};
 const fixture={...data,clipboard:{...data.clipboard,config:{...data.clipboard.config,enabled:true,minutes:0},entries:[entry]}};
 const dialog=document.getElementById('imageDialog'),image=document.getElementById('fullImage'),search=document.getElementById('clipSearch');
 let requests=[];
 const preview=()=>document.querySelector('#clipHistory img[data-clip-action=preview]');
 const receive=(action,clipboard=fixture.clipboard)=>window.receive({...fixture,action,clipboard:structuredClone(clipboard)});
 async function open(){
  receive('load');window.showSection('clipSection');search.value='';renderHistory();
  const opener=preview();opener.scrollIntoView({block:'center'});opener.focus();
  window.showImage({...entry,url});await image.decode();await tick();requests=[];
  check(document.activeElement===dialog,'Preview lacks modal focus');return opener;
 }
 async function closeTo(expected){
  dialog.dispatchEvent(new Event('cancel',{cancelable:true}));await tick();
  check(!dialog.open&&!image.hasAttribute('src'),'Preview did not close and clear its image');
  check(document.activeElement===expected,'Focus was not restored to the current visible control');
  check(!requests.some(x=>x.action==='copyClipboard'||x.action==='saveAllSettings'),'Closing preview invoked an underlying action');
 }
 try{
  send=body=>requests.push(body);
  receive('load');window.showSection('clipSection');
  const thumbnail=preview();thumbnail.scrollIntoView({block:'center'});
  if(window.capturePreviewState)await window.capturePreviewState('thumbnail');
  check(thumbnail?.tagName==='IMG'&&thumbnail.tabIndex===0&&thumbnail.getAttribute('role')==='button'&&thumbnail.getAttribute('aria-label')===t('放大预览'),'Thumbnail lacks accessible preview activation');
  check(document.querySelectorAll('#clipHistory .clip-card-actions button').length===1,'Visible preview button remains beside Copy');
  let bubbled=0;const countBubble=()=>bubbled++;thumbnail.parentElement.addEventListener('click',countBubble);
  requests=[];thumbnail.click();
  check(requests.length===1&&requests[0].action==='previewClipboard'&&requests[0].id===entry.id&&bubbled===0,'Thumbnail click copied, bubbled or targeted the wrong entry');
  for(const key of ['Enter',' ']){
   requests=[];const event=new KeyboardEvent('keydown',{key,bubbles:true,cancelable:true});thumbnail.dispatchEvent(event);
   check(event.defaultPrevented&&requests.length===1&&requests[0].action==='previewClipboard'&&requests[0].id===entry.id,'Keyboard thumbnail activation missing or duplicated');
   requests=[];thumbnail.dispatchEvent(new KeyboardEvent('keydown',{key,bubbles:true,cancelable:true,repeat:true}));check(requests.length===0,'Held preview key sent repeated requests');
  }
  thumbnail.parentElement.removeEventListener('click',countBubble);
  for(const action of ['refreshPermissionsSilent','refreshApplications','refreshClipboard']){
   await open();receive(action);check(dialog.open,'Background receipt closed the preview');
   const current=preview();
   if(action==='refreshPermissionsSilent'&&window.capturePreviewState)await window.capturePreviewState('modal');
   await closeTo(current);
   if(action==='refreshPermissionsSilent'&&window.capturePreviewState)await window.capturePreviewState('restored-focus');
   requests=[];current.click();check(requests.at(-1)?.action==='previewClipboard'&&requests.at(-1).id===entry.id,'Restored focus identifies the wrong action or entry');
  }
  await open();receive('refreshClipboard',{...fixture.clipboard,entries:[{id:600002,time:now,text:'New synthetic text'},entry]});
  const current=preview();
  await closeTo(current);

  await open();clipMinutes=1;clipEntries.push({id:600003,time:now-120,text:'Expired synthetic text'});
  if(clipEntries.some(clipboardExpired))renderHistory();check(dialog.open,'Other entry expiry closed the retained preview');await closeTo(preview());

  await open();search.value='no matching entry';search.dispatchEvent(new Event('input',{bubbles:true}));
  await closeTo(search);check(search.value==='no matching entry','Focus restoration changed the search query');

  await open();receive('refreshClipboard',{...fixture.clipboard,entries:[]});await tick();
  check(!dialog.open&&!image.hasAttribute('src')&&document.activeElement===search,'Removed preview restored focus to a row about to be destroyed');

  await open();clipMinutes=1;previewEntry.time=now-120;clipEntries[0].time=now-120;
  if(previewEntry&&clipboardExpired(previewEntry))closeImagePreview();if(clipEntries.some(clipboardExpired))renderHistory();await tick();
  check(!dialog.open&&document.activeElement===search,'Expired preview left focus on its removed row');

  for(let i=0;i<3;i++){await open();receive('refreshApplications');await closeTo(preview())}

  await open();await closeTo(preview());search.focus();window.showImage({...entry,url});await image.decode();receive('refreshPermissionsSilent');await closeTo(search);
  return 'Background receipts, changed history, other-entry TTL, filtering, removal/expiry before rerender, repeated cycles, stable focus and correct preview action passed';
 }finally{if(dialog.open)closeImagePreview();await tick();send=oldSend;search.value='';window.receive({...data,action:'load'})}
};
