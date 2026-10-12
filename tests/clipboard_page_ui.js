// Synthetic clipboard only; assertions exercise the production DOM/receive path.
window.runClipboardPageRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send,oldTimeout=window.setTimeout,oldClear=window.clearTimeout;
 let request,timer;const state=document.getElementById('clipRecordingState'),search=document.getElementById('clipSearch'),note=document.getElementById('clipActionStatus');
 const now=Date.now()/1000,entries=[{id:701,kind:'text',time:now,text:'Synthetic Alpha'},{id:702,kind:'image',time:now,text:'Synthetic Image',preview:'data:image/png;base64,iVBORw0KGgo='}];
 const payload=(enabled,paused,items=entries)=>({...data,ok:true,action:'load',message:'',clipboard:{...data.clipboard,paused,config:{...data.clipboard.config,enabled,minutes:0},entries:items}});
 try{
  send=value=>request=value;window.showSection('clipSection');search.value='';window.receive(payload(false,false));
  check(state.dataset.state==='disabled'&&document.getElementById('pauseClip').disabled,'Off state wrong');
  check(!document.getElementById('clipHistoryCount')&&document.querySelectorAll('#clipHistory .clip-card').length===2,'Total count wrong');
  const saved=pageSnapshot('clipSection');document.getElementById('clipEnabled').checked=true;document.getElementById('clipEnabled').dispatchEvent(new Event('change',{bubbles:true}));updateSaveState();
  check(state.dataset.state==='disabled','Draft incorrectly presented as recording');
  window.receive({...payload(false,false),action:'refreshClipboard'});check(document.getElementById('clipEnabled').checked&&pageSnapshot('clipSection')!==saved,'Refresh discarded draft');
  document.getElementById('cancelSettings').click();check(!document.getElementById('clipEnabled').checked,'Cancel failed');
  window.receive(payload(true,false));check(state.dataset.state==='recording'&&!document.getElementById('pauseClip').disabled,'Recording state wrong');
  document.getElementById('pauseClip').click();check(request.action==='pauseClipboard','Pause routing wrong');
  window.receive({...payload(true,true),action:'pauseClipboard',message:t('已暂停记录')});check(state.dataset.state==='paused'&&document.getElementById('pauseClip').textContent===t('恢复记录'),'Paused state wrong');
  search.value='ALPHA';search.dispatchEvent(new Event('input',{bubbles:true}));updateSaveState();
  check(document.querySelectorAll('#clipHistory .clip-card').length===1&&document.getElementById('saveSettings').disabled,'Search count/draft wrong');
  document.querySelector('#clipHistory .clip-card-actions button').click();check(request.action==='copyClipboard'&&request.id===701,'Copy routed incorrectly');
  window.setTimeout=(fn,ms)=>{timer={fn,ms};return 700};window.clearTimeout=()=>{};
  window.receive({...payload(true,true),action:'copyClipboard',message:t('已复制，请在目标应用手动粘贴')});check(!note.hidden&&note.dataset.result==='success'&&timer.ms===3000,'Copy success feedback missing');timer.fn();check(note.hidden,'Copy success did not expire');
  window.receive({...payload(true,true),ok:false,action:'copyClipboard',message:t('复制失败')});check(!note.hidden&&note.dataset.result==='error'&&note.textContent===t('复制失败'),'Copy failure feedback missing');
  search.value='NO MATCH';renderHistory();check(document.querySelector('#clipHistory [data-ui-empty]').textContent===t('没有匹配的历史'),'Search empty confused with no history');
  search.value='';receiveClipboard(payload(false,false,[]).clipboard,false);check(document.querySelector('#clipHistory [data-ui-empty]').textContent===t('暂无历史；启用并保存后开始记录'),'Off empty wrong');
  receiveClipboard(payload(true,true,[]).clipboard,false);check(document.querySelector('#clipHistory [data-ui-empty]').textContent===t('暂无历史；恢复记录后复制新内容'),'Paused empty wrong');
  receiveClipboard(payload(true,false,[]).clipboard,false);check(document.querySelector('#clipHistory [data-ui-empty]').textContent===t('暂无历史；复制新内容即可记录'),'Recording empty wrong');
  receiveClipboard({...payload(true,false).clipboard,config:{...data.clipboard.config,enabled:true,minutes:1},entries:[{id:703,kind:'text',time:now-120,text:'Expired'}]},false);check(!document.querySelector('#clipHistory .clip-card')&&document.getElementById('clearClip').disabled,'Expiry count/clear state stale');
  receiveClipboard(payload(true,false).clipboard,false);const image=document.querySelectorAll('#clipHistory .clip-card')[1];image.querySelector('button').click();check(request.action==='previewClipboard'&&request.id===702,'Preview routed incorrectly');
  window.receive({...payload(true,false),ok:false,action:'previewClipboard',message:'Synthetic preview failure'});check(note.textContent==='Synthetic preview failure'&&note.dataset.result==='error','Preview failure feedback missing');
  window.showImage({id:702,time:now,url:'data:image/png;base64,iVBORw0KGgo='});check(imageDialog.open&&note.textContent===t('已打开图片预览'),'Preview success feedback missing');imageDialog.close();
  window.receive({...payload(true,false),action:'refreshClipboard',message:''});check(note.textContent===t('历史已刷新'),'Refresh feedback missing');
  check(document.querySelector('.clip-recording').contains(document.getElementById('pauseClip')),'Pause not near running state');
  check(document.documentElement.scrollWidth<=innerWidth+1,'Clipboard page overflows horizontally');
  return 'Live/draft separation, state transitions, counts/expiry, empty states, pause/copy/preview/refresh feedback and layout passed';
 }finally{imageDialog.close();window.setTimeout=oldTimeout;window.clearTimeout=oldClear;search.value='';send=oldSend;clipboardFeedback('',true);window.receive({...data,ok:true,action:'load'})}
};
