// User-requested compact rules and exclusion migration; synthetic settings only.
window.runCompactRulesRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send;let requests=[];
 try{
  send=value=>requests.push(value);
  const fixture=structuredClone(data);fixture.ok=true;fixture.action='load';fixture.clipboard.config.excluded=['com.example.legacy','com.example.uninstalled'];fixture.excludedAppNames={'com.example.legacy':'Legacy App'};
  fixture.launcher.rules=[{bundleID:'com.example.compact',name:'Compact App',shortcut:{key:'K',mods:['alt']}}];window.receive(fixture);
  check(!document.querySelector('.shortcut-display,.rule-count,#clipHistoryCount,#updateHint'),'Removed duplicate/count/help still rendered');
  window.showSection('launcherSection');const row=document.querySelector('#launcherRules .launcher-rule'),input=row.querySelector('.launcher-key');
  check(input.value==='K'&&row.querySelector('[data-mod=alt]').checked&&input.title==='⌥ K','Compact shortcut lost configuration');
  check(row.offsetHeight<=80,'Launcher row is not compact');
  window.showSection('clipSection');document.getElementById('clipExcluded').closest('details').open=true;
  const host=document.getElementById('clipExcludedRows'),saved=pageSnapshot('clipSection');
  check(host.children.length===2&&host.children[0].textContent.includes('Legacy App')&&host.children[1].textContent.includes('com.example.uninstalled'),'Existing/uninstalled exclusions were lost');
  check(!document.getElementById('clipExcluded').getClientRects().length,'Raw Bundle ID editor still visible');
  requests=[];document.getElementById('chooseExcludedApp').click();check(requests.at(-1)?.action==='chooseExcludedApp'&&pageSnapshot('clipSection')===saved,'Picker request altered configuration');
  window.addExcludedApp({bundleID:'com.example.new',name:'New App'});window.addExcludedApp({bundleID:'com.example.new',name:'New App'});
  check(host.children.length===3&&document.getElementById('tab-clipSection').dataset.dirty==='true','Add/duplicate/draft failed');
  receiveClipboard(fixture.clipboard,false);check(host.children.length===3,'History refresh erased exclusion draft');
  [...host.children].find(row=>row.dataset.bundle==='com.example.legacy').querySelector('button:not(.rule-drag)').click();document.getElementById('saveClip').click();
  check(JSON.stringify(requests.at(-1).config.excluded)===JSON.stringify(['com.example.new','com.example.uninstalled']),'Exclusion save payload wrong');
  document.getElementById('cancelSettings').click();check(pageSnapshot('clipSection')===saved&&host.children.length===2,'Exclusion cancel did not restore legacy data');
  window.showSection('browserSection');const panel=document.getElementById('browserSection'),test=panel.querySelector('.browser-test'),apps=document.getElementById('browserAppGroup'),domains=document.getElementById('browserDomainGroup');
  check(!test&&!document.getElementById('browserURL')&&!document.getElementById('testBrowserSource'),'Test is not open at top');
  check(apps.compareDocumentPosition(domains)&Node.DOCUMENT_POSITION_FOLLOWING,'App and domain order wrong');
  check(domains.getBoundingClientRect().top>=apps.getBoundingClientRect().bottom,'Rule groups are not stacked');
  const snapshot=pageSnapshot('browserSection');document.querySelector('[data-rule-jump=browserDomainGroup]').click();check(document.activeElement.id==='browserRules-search'&&pageSnapshot('browserSection')===snapshot,'Rule jump changed draft or focus wrong');
  check(document.documentElement.scrollWidth<=innerWidth+1,'Compact UI overflows');
  return 'Compact rows, removed duplicates/counts, exclusion migration/picker/add/remove/save/cancel, vertical browser groups and top test passed';
 }finally{send=oldSend;window.receive({...data,ok:true,action:'load'})}
};
