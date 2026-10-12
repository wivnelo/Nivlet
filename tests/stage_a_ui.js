// Isolated settings WebView only: no backend saves or user data.
window.runStageARegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send;
 try{
  let request;send=value=>request=value;
  window.showSection('launcherSection');
  window.addLauncherRule({bundleID:'com.example.stagea.first',name:'First',shortcut:{key:'K',mods:['ctrl','cmd']}});
  window.addLauncherRule({bundleID:'com.example.stagea.second',name:'Second',shortcut:{key:'J',mods:['alt']}});
  const host=document.getElementById('launcherRules'),row=host.querySelector('[data-bundle="com.example.stagea.first"]'),next=row.nextElementSibling;
  row.querySelector('.replace-launcher-app').click();check(request.action==='chooseLauncherApp'&&request.replaceBundleID===row.dataset.bundle,'Replace picker request missing');
  window.replaceLauncherApp({bundleID:'com.example.stagea.third',name:'Third'},row.dataset.bundle);
  check(row.nextElementSibling===next&&row.querySelector('.launcher-key').value==='K','Replacement lost position/key');
  check([...row.querySelectorAll('[data-mod]:checked')].map(f=>f.dataset.mod).join('+')==='ctrl+cmd','Replacement lost modifiers');
  check(document.getElementById('draftHint').dataset.dirty==='true','Replacement did not mark draft');
  window.replaceLauncherApp({bundleID:'COM.EXAMPLE.STAGEA.SECOND',name:'Second'},row.dataset.bundle);
  check(row.dataset.bundle==='com.example.stagea.third'&&!document.getElementById('launcherRules-notice').hidden,'Duplicate replacement overwrote row');
  request=null;document.getElementById('saveSettings').click();check(request.action==='saveLauncher'&&request.config.rules.some(r=>r.bundleID===row.dataset.bundle),'Footer did not submit replacement');
  window.receive({...data,ok:false,action:'saveLauncher',message:'Fixture save failure'});check(row.isConnected&&row.dataset.bundle==='com.example.stagea.third','Failed save erased replacement draft');
  check(document.querySelectorAll('.permission-state').length===1&&document.querySelector('#generalSection .permission-state'),'Repeated permission status');
  request=null;window.showSection('clipSection');check(!request,'Clipboard tab rechecks permissions unnecessarily');
  const icon=document.querySelector('.clip-menu-icon');check(icon&&getComputedStyle(icon).maskImage.includes('data:image/png'),'Clipboard hint icon missing');
  window.receive({...data,action:'refreshPermissionsSilent',language:'en'});window.showSection('launcherSection');check(row.querySelector('.replace-launcher-app').textContent==='Replace App…','Replace label not translated');
  window.receive({...data,action:'refreshPermissionsSilent',language:'zh-Hans'});check(row.querySelector('.replace-launcher-app').textContent==='更换应用…','Replace label did not restore Chinese');
  return 'Replacement request, shortcut/order preservation, duplicate rejection, footer save/failure draft, General-only permission and monochrome hint passed';
 }finally{send=original;window.receive({...data,ok:true,action:'load'})}
};
