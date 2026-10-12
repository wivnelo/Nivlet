window.runAppRulesFeedbackRegression=async function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},oldSend=send;let request;
 const drag=(first,target)=>{const box=first.getBoundingClientRect(),to=target.getBoundingClientRect();first.querySelector('.rule-drag').dispatchEvent(new PointerEvent('pointerdown',{button:0,clientX:box.left+15,clientY:box.top+box.height/2,bubbles:true}));document.dispatchEvent(new PointerEvent('pointermove',{clientX:to.left+15,clientY:to.top+1,bubbles:true}));document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}))};
 try{
  send=value=>request=value;const fixture=structuredClone(data);fixture.ok=true;fixture.action='load';
  const rules=[{bundleID:'com.example.first',name:'First'},{bundleID:'com.example.second',name:'Second'}];
  fixture.input.rules=rules.map(rule=>({...rule,sourceID:fixture.sources[0].id}));fixture.browser.appRules=rules.map(rule=>({...rule,browser:fixture.browsers[0].id}));fixture.launcher.rules=rules.map(rule=>({...rule,shortcut:{key:'',mods:[]}}));fixture.clipboard.config.excluded=rules.map(rule=>rule.bundleID);
  window.receive(fixture);check(!document.querySelector('.browser-test,#browserURL,#testBrowserSource,#testBrowserURL,#openBrowserURL'),'Browser test controls remain');
  for(const [id,fn,section]of [['inputRows','addInputRule','inputSection'],['browserAppRules','addBrowserAppRule','browserSection'],['launcherRules','addLauncherRule','launcherSection']]){
   window.showSection(section);const host=document.getElementById(id);check(host.firstElementChild.dataset.bundle===rules[0].bundleID,'Loading reversed saved order');
   window[fn]({bundleID:'com.example.new',name:'New',sourceID:fixture.sources[0].id},true);await Promise.resolve();check(host.firstElementChild.dataset.bundle==='com.example.new','New app not on top '+id);
   window[fn](rules[1],true);await Promise.resolve();check(host.lastElementChild.dataset.bundle===rules[1].bundleID&&host.children.length===3,'Duplicate reordered '+id);
   check([...host.children].every(row=>row.querySelector('.rule-drag .app-icon')?.src.startsWith('data:image/')),'Icon missing '+id);
   drag(host.lastElementChild,host.firstElementChild);check(host.firstElementChild.dataset.bundle===rules[1].bundleID,'Icon did not move whole row '+id);
   document.getElementById('cancelSettings').click();await Promise.resolve();check(host.firstElementChild.dataset.bundle===rules[0].bundleID&&host.children.length===2,'Cancel did not restore order '+id);
  }
  window.showSection('clipSection');document.getElementById('clipExcluded').closest('details').open=true;window.addExcludedApp({bundleID:'com.example.new',name:'New'});const host=document.getElementById('clipExcludedRows');
  check(host.firstElementChild.dataset.bundle==='com.example.new','New exclusion not first');drag(host.lastElementChild,host.firstElementChild);document.getElementById('saveClip').click();check(request.config.excluded[0]===rules[1].bundleID,'Excluded drag not serialized');
  host.children[1].querySelector('button:not(.rule-drag)').click();document.getElementById('saveClip').click();check(JSON.stringify(request.config.excluded)===JSON.stringify([rules[1].bundleID,rules[0].bundleID]),'Remove after reorder used stale order');
  document.getElementById('cancelSettings').click();await Promise.resolve();check(document.getElementById('clipExcluded').value===fixture.clipboard.config.excluded.join('\n'),'Excluded cancel changed saved IDs');
  check(document.querySelectorAll('.clipboard-usage p').length===3,'Usage is not three separate rows');
  document.getElementById('popupShortcut').closest('details').open=true;const popup=document.getElementById('popup-key');check(getComputedStyle(popup).width==='52px'&&getComputedStyle(popup).height==='30px','Popup shortcut geometry differs');
  check(document.documentElement.scrollWidth<=innerWidth+1,'Feedback UI overflows');
  return 'Four icon handles, saved-order preservation/new-on-top/duplicate/no reorder, drag serialization/cancel/remove, test removal, usage and shortcut style passed';
 }finally{send=oldSend;window.receive({...data,ok:true,action:'load'})}
};
