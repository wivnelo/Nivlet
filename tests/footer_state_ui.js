// Synthetic saves only. Optional screenshot hook is supplied by the test harness.
window.runFooterStateUIRegression=async function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send,states=[];
 let requests=[];
 const rect=element=>{const r=element.getBoundingClientRect();return {left:r.left,top:r.top,right:r.right,bottom:r.bottom,width:r.width,height:r.height}};
 const record=async name=>{
  await new Promise(requestAnimationFrame);
  const status=document.getElementById('status'),feedback=document.querySelector('.footer-feedback')||status;
  const value={name,footer:rect(document.querySelector('footer')),save:rect(document.getElementById('saveSettings')),cancel:rect(document.getElementById('cancelSettings')),feedback:rect(feedback),status:rect(status),text:status.textContent,scrollHeight:feedback.scrollHeight,clientHeight:feedback.clientHeight};
  states.push(value);if(window.captureFooterState)await window.captureFooterState(name);return value;
 };
 const reset=()=>{window.receive({...data,ok:true,action:'load',message:''});window.showSection('generalSection');requests=[]};
 const draft=()=>{document.getElementById('showMenu').checked=!data.general.showMenu;updateSaveState()};
 const reply=(request,ok,results,extra={})=>window.receive({...data,...extra,ok,action:'saveAllSettings',requestID:request.requestID,message:'',saveBatch:{ok,results,...(extra.saveBatch||{})}});
 try{
  send=body=>requests.push(body);reset();await record('clean');
  draft();await record('dirty');
  document.getElementById('system-cpu').checked=!data.system.cpu;updateSaveState();await record('multi-page-dirty');
  saveAllCoordinator.start();const saved=requests.find(item=>item.action==='saveAllSettings');await record('saving');
  reply(saved,true,[{page:'generalSection',status:'saved'},{page:'systemSection',status:'saved'}],{general:saved.pages.generalSection.config,system:saved.pages.systemSection.config});await record('success');
  reset();draft();document.getElementById('left-key').value='INVALID';updateSaveState();saveAllCoordinator.start();
  check(!requests.some(item=>item.action==='saveAllSettings'),'Validation failure must not write');await record('validation-failure');
  reset();draft();document.getElementById('system-cpu').checked=!data.system.cpu;updateSaveState();saveAllCoordinator.start();
  const partial=requests.find(item=>item.action==='saveAllSettings');
  reply(partial,false,[{page:'generalSection',status:'saved'},{page:'systemSection',status:'failed'}],{general:partial.pages.generalSection.config,saveBatch:{failedPage:'systemSection',message:t('保存失败，请检查设置')}});await record('partial-failure');
  const longMessage=t('保存失败，请检查设置')+' '+Array(22).fill(t('部分状态无法恢复，请检查设置。')).join(' ');
  saveError('systemSection',{message:longMessage});updateSaveState();const long=await record('long-error');
  const feedback=document.querySelector('.footer-feedback'),status=document.getElementById('status');
  if(feedback){feedback.scrollTop=feedback.scrollHeight;await record('long-error-end')}
  // Normal save feedback occupies one stable left-hand slot; both buttons retain
  // their positions and width even while the Save label changes to Saving.
  const normal=states.filter(item=>['clean','dirty','multi-page-dirty','saving','success'].includes(item.name)),base=normal[0];
  for(const state of normal){
   check(Math.abs(state.footer.height-base.footer.height)<1,'Footer height changed for '+state.name+': '+base.footer.height+' -> '+state.footer.height);
   for(const button of ['save','cancel'])for(const edge of ['left','right','top','bottom'])check(Math.abs(state[button][edge]-base[button][edge])<1,'Footer button moved: '+state.name+' / '+button+' / '+edge);
  }
  check(feedback,'A shared feedback slot is required');
  for(const state of states){
   check(state.footer.bottom<=innerHeight+1&&state.footer.height<=140,'Footer exceeds available space: '+state.name);
   check(state.feedback.right<=state.cancel.left-5,'Feedback overlaps actions: '+state.name);
   for(const button of ['save','cancel'])check(Math.abs(state[button].bottom-base[button].bottom)<1&&Math.abs(state[button].right-base[button].right)<1,'Error feedback moved the actions: '+state.name);
   if(state.text)check(state.status.left>=state.feedback.left-1&&state.status.right<=state.feedback.right+1,'Status escaped its feedback column: '+state.name);
  }
  check(status.textContent===longMessage&&getComputedStyle(status).textOverflow!=='ellipsis','Long error must remain complete');
  check(long.scrollHeight>long.clientHeight&&getComputedStyle(feedback).overflowY==='auto'&&feedback.tabIndex===0,'Long errors must be scrollable and keyboard-focusable');
  const tail=document.createRange();tail.setStart(status.firstChild,status.firstChild.length-1);tail.setEnd(status.firstChild,status.firstChild.length);
  const tailBounds=tail.getBoundingClientRect(),bounds=feedback.getBoundingClientRect();
  check(tailBounds.top>=bounds.top-1&&tailBounds.bottom<=bounds.bottom+1,'End of long error cannot be reached');
  return {message:'Stable feedback/actions for clean, dirty, multi-page, saving, success, validation, partial failure and long scrollable errors',states};
 }finally{leaveGuard.cancel();send=original;window.receive({...data,ok:true,action:'load',message:''})}
};
