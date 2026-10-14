window.runDuplicateNoticeRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw Error(message)},oldSend=send,oldTimeout=window.setTimeout,oldClear=window.clearTimeout;
 let serial=0;const timers=new Map();
 try{
  send=()=>{};window.setTimeout=(fn,ms)=>{const id=++serial;timers.set(id,{fn,ms});return id};window.clearTimeout=id=>timers.delete(id);
  window.receive({...data,action:'load'});
  for(const [hostID,add] of [['launcherRules',window.addLauncherRule],['inputRows',window.addInputRule],['browserAppRules',window.addBrowserAppRule]]){
   const host=document.getElementById(hostID),section=host.closest('.panel').id;
   window.showSection(section);
   const rule={bundleID:'com.example.notice'+hostID,name:'Notice fixture',shortcut:{key:'',mods:[]},sourceID:data.sources[0].id,browser:data.browsers[0].id};
   add(rule);const row=host.lastElementChild,before=pageSnapshot(section),count=host.children.length;
   add(rule);updateSaveState();
   const status=document.getElementById('status');
   check(host.children.length===count&&pageSnapshot(section)===before,'Duplicate changed draft');
   check(row.classList.contains('duplicate-highlight'),'Original row not highlighted');
   check(status.textContent.includes(t('此应用已添加，已定位到原配置。'))&&status.dataset.result==='success','Duplicate must be informational');
   check(!footerErrors.has(section),'Duplicate must not persist as backend error');
   const expiry=[...timers.values()].find(timer=>timer.ms===3000);check(expiry,'Missing notice expiry');expiry.fn();updateSaveState();check(!status.textContent,'Expired notice resurrected');
   add(rule);updateSaveState();window.showSection('aboutSection');window.showSection(section);check(!status.textContent,'Navigation resurrected notice');
   saveError(section,{message:'Actual backend error'});add(rule);updateSaveState();check(status.textContent==='Actual backend error'&&status.dataset.result==='error','Duplicate erased real error');clearSaveError(section);row.remove();updateSaveState();
  }
  return 'PASS: three app pickers, locate/highlight, unchanged drafts, expiry, navigation and actual error precedence';
 }finally{window.setTimeout=oldTimeout;window.clearTimeout=oldClear;send=oldSend;clearStatus()}
};
