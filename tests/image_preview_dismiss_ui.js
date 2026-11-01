// Synthetic image and inert bridge only. Hit-testing is exercised in the real DOM;
// the cancel event below represents Escape semantics, not an OS keyboard test.
window.runImagePreviewDismissRegression=async function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)};
 const settle=()=>new Promise(resolve=>setTimeout(resolve,0));
 const dialog=document.getElementById('imageDialog'),image=document.getElementById('fullImage');
 const originalStyle=image.getAttribute('style'),oldSend=send;
 const originalSection=document.querySelector('.panel:not([hidden])').id;
 const now=Date.now()/1000,canvas=document.createElement('canvas');canvas.width=2;canvas.height=2;
 const png=canvas.toDataURL('image/png');
 let requests=[],bubbled=0,underlyingClicks=0,copy,save=document.getElementById('saveSettings');
 const onBubble=()=>bubbled++,onUnderlying=()=>underlyingClicks++;
 const outside=(point,rect)=>point[0]<rect.left||point[0]>rect.right||point[1]<rect.top||point[1]>rect.bottom;
 function clickAt(point,expectedInside){
  const target=document.elementFromPoint(point[0],point[1]);
  check(target===dialog||dialog.contains(target),'Modal hit test exposed an underlying control');
  if(expectedInside)check(target===image,'Transparent pixels or image padding did not retain the image hit box');
  const event=new MouseEvent('click',{bubbles:true,cancelable:true,composed:true,clientX:point[0],clientY:point[1]});
  target.dispatchEvent(event);
  if(!expectedInside)check(event.defaultPrevented,'Dismissal click did not prevent its default action');
  check(bubbled===0&&underlyingClicks===0&&requests.length===0,'Preview click escaped to document or an underlying action');
 }
 async function open(width=180,height=120){
  image.style.width=width+'px';image.style.height=height+'px';
  copy.focus();check(document.activeElement===copy,'Synthetic preview trigger could not receive focus');
  window.showImage({id:901234,time:now,url:png});
  await image.decode();await settle();
  check(dialog.open,'Preview did not open');
  check(document.activeElement===dialog,'Preview dialog did not receive focus');
  check(dialog.hasAttribute('tabindex'),'Preview dialog is not programmatically focusable');
  check(dialog.getAttribute('aria-label')||dialog.getAttribute('aria-labelledby'),'Preview dialog lacks an accessible name');
  const rect=image.getBoundingClientRect();
  check(rect.width>0&&rect.height>0,'Preview image has an empty hit box');
  return rect;
 }
 async function checkClosed(){
  await settle();
  check(!dialog.open,'Outside click or cancel did not close preview');
  check(!image.hasAttribute('src'),'Closed preview retained its image resource');
  check(document.activeElement===copy,'Closing preview did not restore the original trigger focus');
  check(bubbled===0&&underlyingClicks===0&&requests.length===0,'Closing preview activated an underlying action');
 }
 try{
  send=value=>requests.push(value);
  window.showSection('clipSection');
  receiveClipboard({...data.clipboard,config:{...data.clipboard.config,minutes:0},entries:[{id:901234,kind:'image',time:now,text:'Synthetic transparent image',preview:png}]},false);
  copy=document.querySelector('#clipHistory .clip-card-actions button');
  check(copy,'Synthetic image preview trigger is missing');
  copy.scrollIntoView({block:'center'});requests=[];
  check(!document.getElementById('closeImage')&&!dialog.querySelector('button'),'Removed preview-close button remains');
  check(canvas.getContext('2d').getImageData(0,0,1,1).data[3]===0,'Transparent fixture is not transparent');
  document.addEventListener('click',onBubble);
  copy.addEventListener('click',onUnderlying);save.addEventListener('click',onUnderlying);

  let rect=await open();
  // The full element rectangle counts as the image, including transparent pixels
  // and the letterboxed portion of an object-fit:contain image.
  for(const point of [[rect.left+rect.width/2,rect.top+rect.height/2],[rect.left+2,rect.top+2],[rect.right-2,rect.bottom-2]]){
   clickAt(point,true);check(dialog.open,'An image-interior click dismissed the preview');
  }
  const padding=[rect.left-2,rect.top+rect.height/2];
  check(outside(padding,rect),'Padding fixture lies inside image');
  clickAt(padding,false);await checkClosed();

  // A point over the underlying Save control must still hit the modal backdrop.
  rect=await open();
  const saveRect=save.getBoundingClientRect();
  let backdrop=[saveRect.left+saveRect.width/2,saveRect.top+saveRect.height/2];
  if(!outside(backdrop,rect))backdrop=[2,2];
  clickAt(backdrop,false);await checkClosed();

  // Geometry is read at click time, not cached when the preview first opened.
  rect=await open();
  const oldLeft=rect.left;
  image.style.width='260px';image.style.height='96px';
  window.dispatchEvent(new Event('resize'));await settle();
  rect=image.getBoundingClientRect();
  check(rect.width>180&&rect.left<oldLeft,'Resize fixture did not change the image bounds');
  clickAt([rect.left+2,rect.top+2],true);check(dialog.open,'Resized image bounds were stale');
  clickAt([rect.right+2,rect.top+rect.height/2],false);await checkClosed();

  // Exercise repeated landscape/portrait cycles to catch stale handlers/focus.
  for(const [width,height] of [[120,220],[240,100],[180,120]]){
   rect=await open(width,height);
   clickAt([rect.left+rect.width/2,rect.top+rect.height/2],true);
   clickAt([rect.left+rect.width/2,rect.bottom+2],false);await checkClosed();
  }

  // Closing queues a native close event. Reopening in the same turn must not let
  // that old event clear the new image or move focus out of the new dialog.
  rect=await open();
  clickAt([rect.right+2,rect.top+rect.height/2],false);
  check(!image.hasAttribute('src'),'Close did not release image synchronously');
  copy.focus();window.showImage({id:901234,time:now,url:png});
  await image.decode();await settle();
  check(dialog.open&&image.hasAttribute('src')&&document.activeElement===dialog,'A queued close event damaged a freshly reopened preview');
  rect=image.getBoundingClientRect();clickAt([rect.right+2,rect.top+rect.height/2],false);await checkClosed();

  await open();
  const cancel=new Event('cancel',{cancelable:true});
  dialog.dispatchEvent(cancel);
  // HTML dialog's user-agent Escape action closes it unless cancel is prevented.
  // Synthetic dispatch does not run that UA default, so model that default only.
  if(!cancel.defaultPrevented&&dialog.open)dialog.close();
  await checkClosed();
  return 'Transparent image hit box, inside/outside edges, dialog padding/backdrop, current resize geometry, repeated cycles, cancel semantics, focus restoration and event containment passed';
 }finally{
  document.removeEventListener('click',onBubble);copy?.removeEventListener('click',onUnderlying);save.removeEventListener('click',onUnderlying);
  if(dialog.open)dialog.close();await settle();
  if(originalStyle===null)image.removeAttribute('style');else image.setAttribute('style',originalStyle);
  send=oldSend;receiveClipboard(data.clipboard,false);window.showSection(originalSection);
 }
};
