
window.runStageARegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send;
 try{
  let request;const requests=[];send=value=>{request=value;requests.push(value)};
  const applicationReply=()=>window.receive({...data,ok:true,action:'refreshApplications'});
  window.showSection('launcherSection');
  window.addLauncherRule({bundleID:'com.example.stagea.first',name:'First',shortcut:{key:'K',mods:['ctrl','cmd']}});applicationReply();
  window.addLauncherRule({bundleID:'com.example.stagea.second',name:'Second',shortcut:{key:'J',mods:['alt']}});applicationReply();
  const host=document.getElementById('launcherRules'),row=host.querySelector('[data-bundle="com.example.stagea.first"]'),next=row.nextElementSibling;
  row.querySelector('.replace-launcher-app').click();check(request.action==='chooseLauncherApp'&&request.replaceBundleID===row.dataset.bundle,'Replace picker request missing');
  window.replaceLauncherApp({bundleID:'com.example.stagea.third',name:'Third'},row.dataset.bundle);applicationReply();
  check(row.nextElementSibling===next&&row.querySelector('.launcher-key').value==='K','Replacement lost position/key');
  check([...row.querySelectorAll('[data-mod]:checked')].map(f=>f.dataset.mod).join('+')==='ctrl+cmd','Replacement lost modifiers');
  check(document.getElementById('draftHint').dataset.dirty==='true','Replacement did not mark draft');
  window.replaceLauncherApp({bundleID:'COM.EXAMPLE.STAGEA.SECOND',name:'Second'},row.dataset.bundle);applicationReply();
  check(row.dataset.bundle==='com.example.stagea.third'&&next.classList.contains('duplicate-highlight')&&document.getElementById('status').textContent.includes(t('此应用已添加，已定位到原配置。')),'Duplicate replacement overwrote row or failed to locate the existing rule');
  request=null;document.getElementById('saveSettings').click();const batch=request;check(batch.action==='saveAllSettings'&&Object.keys(batch.pages).join(',')==='launcherSection'&&batch.pages.launcherSection.config.rules.some(r=>r.bundleID===row.dataset.bundle),'Footer did not submit replacement in the dirty settings batch');
  window.receive({...data,ok:false,action:'saveAllSettings',requestID:batch.requestID,saveBatch:{ok:false,failedPage:'launcherSection',message:'Fixture save failure',results:[{page:'launcherSection',status:'failed'}]}});check(!saveAllCoordinator.saving&&row.isConnected&&row.dataset.bundle==='com.example.stagea.third','Failed save erased replacement draft or left settings locked');
  check(document.querySelectorAll('.permission-state').length===1&&document.querySelector('#generalSection .permission-state'),'Repeated permission status');
  requests.length=0;window.showSection('clipSection');check(!requests.some(value=>value.action==='refreshPermissions'),'Clipboard tab rechecks permissions unnecessarily');
  check(!document.querySelector('.clipboard-usage,.clip-menu-icon'),'Retired clipboard menu help remains');
  window.receive({...data,action:'refreshPermissionsSilent',language:'en',translations:data.testTranslations.en});window.showSection('launcherSection');check(row.querySelector('.replace-launcher-app').textContent==='Replace App…','Replace label not translated');
  window.receive({...data,action:'refreshPermissionsSilent',language:'zh-Hans'});check(row.querySelector('.replace-launcher-app').textContent==='更换应用…','Replace label did not restore Chinese');
  return 'Replacement request, shortcut/order preservation, duplicate rejection, footer save/failure draft, General-only permission and compact clipboard settings passed';
 }finally{send=original;window.receive({...data,ok:true,action:'load'})}
};
