// Isolated DOM tests with synthetic rules and no backend writes.
window.runRuleSearchRegression=async function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)},oldSend=send;let request;
 const search=(id,value)=>{const input=document.getElementById(id+'-search');input.focus();input.value=value;input.dispatchEvent(new Event('input',{bubbles:true}));return input};
 const shown=host=>[...host.children].filter(row=>!row.classList.contains('rule-filtered'));
 try{
  send=value=>request=value;
  const fixture=structuredClone(data);fixture.ok=true;fixture.action='load';
  fixture.input.rules=Array.from({length:30},(_,i)=>({bundleID:'com.example.search'+i,name:'Synthetic App '+i,sourceID:fixture.sources[0].id}));
  fixture.launcher.rules=[{bundleID:'com.example.alpha',name:'Alpha',shortcut:{key:'K',mods:['ctrl']}},{bundleID:'com.example.beta',name:'Beta',shortcut:{key:'J',mods:['alt']}}];
  fixture.browser.rules=[{domain:'alpha.example',browser:'com.apple.Safari',subdomains:true},{domain:'beta.example',browser:'com.apple.Safari',subdomains:false}];
  fixture.browser.appRules=[{bundleID:'com.example.alpha',name:'Alpha',browser:'com.apple.Safari'},{bundleID:'com.example.beta',name:'Beta',browser:'com.apple.Safari'}];
  window.receive(fixture);
  for(const [id,section] of Object.entries({inputRows:'inputSection',launcherRules:'launcherSection',browserRules:'browserSection',browserAppRules:'browserSection'})){
   window.showSection(section);const host=document.getElementById(id),snapshot=pageSnapshot(section),order=[...host.children];
   search(id,'NO-SUCH-RULE');await Promise.resolve();
   check(shown(host).length===0&&!host.parentElement.querySelector('.rule-empty').hidden,'Missing no-match state '+id);
   check(pageSnapshot(section)===snapshot&&document.getElementById('saveSettings').disabled,'Search marks settings dirty '+id);
   search(id,id==='inputRows'?'COM.EXAMPLE.SEARCH29':id==='browserRules'?'BETA.EXAMPLE':'COM.EXAMPLE.BETA');await Promise.resolve();
   check(shown(host).length===1,'Case-insensitive matching failed '+id);
   check([...host.children].every((row,i)=>row===order[i]),'Search reordered rules '+id);
   for(const handle of host.querySelectorAll('.rule-drag'))check(handle.disabled&&!handle.draggable,'Filtered drag is enabled');
   for(const button of host.querySelectorAll('[data-move]'))check(button.disabled,'Filtered domain reorder enabled');
   const saveID={inputRows:'saveInput',launcherRules:'saveLauncher',browserRules:'saveBrowser',browserAppRules:'saveBrowser'}[id];
   document.getElementById(saveID).click();check((id==='browserAppRules'?request.config.appRules:request.config.rules).length===order.length,'Filtered save omitted hidden rules '+id);
   search(id,'');await Promise.resolve();check(shown(host).length===order.length,'Clear failed '+id);
  }
  window.showSection('browserSection');search('browserRules','alpha.example');
  const domain=document.getElementById('browserRules').firstElementChild.querySelector('input[type=text]');domain.focus();domain.value='edited.example';domain.dispatchEvent(new Event('input',{bubbles:true}));await Promise.resolve();
  check(!domain.closest('.browser-rule').classList.contains('rule-filtered'),'Editing a filtered rule hid the focused control');
  document.getElementById('browserRules-search').focus();await Promise.resolve();check(domain.closest('.browser-rule').classList.contains('rule-filtered'),'Filter not reapplied on blur');
  search('browserRules','');document.getElementById('cancelSettings').click();await Promise.resolve();
  window.showSection('inputSection');const host=document.getElementById('inputRows');search('inputRows','search29');
  window.addInputRule(fixture.input.rules[0]);await Promise.resolve();check(document.getElementById('inputRows-search').value===''&&shown(host).length===30,'Duplicate remains hidden');
  search('inputRows','search29');document.getElementById('chooseApp').click();check(document.getElementById('inputRows-search').value===''&&request.action==='chooseApp','Add entry did not reset filter/send');
  window.addInputRule({bundleID:'com.example.new',name:'New Synthetic App',sourceID:fixture.sources[0].id});await Promise.resolve();check(shown(host).length===31,'Added rule hidden');
  search('inputRows','new');document.getElementById('cancelSettings').click();await Promise.resolve();check(host.children.length===30&&shown(host).length===0,'Cancel did not restore all original rules with current filter');
  search('inputRows','');const main=document.querySelector('main'),toolbar=host.parentElement.querySelector('.rule-toolbar');host.children[20].scrollIntoView({block:'center'});
  const box=toolbar.getBoundingClientRect(),bounds=main.getBoundingClientRect();check(box.top>=bounds.top-1&&box.bottom<=bounds.bottom,'Sticky search/add not reachable');
  check(document.documentElement.scrollWidth<=innerWidth+1&&main.scrollWidth<=main.clientWidth+1,'Long list toolbar overflows');
  return 'Four-list filtering, clean drafts, complete saves, stable order, safe sorting, duplicate/add/cancel and sticky toolbar passed';
 }finally{for(const id of Object.keys(ruleLists))document.getElementById(id+'-search').value='';send=oldSend;window.receive({...data,ok:true,action:'load'})}
};
