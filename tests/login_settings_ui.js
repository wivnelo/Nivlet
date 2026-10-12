window.runLoginSettingsRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},original=send;
 try{
  window.receive({...data,action:'load'});window.showSection('generalSection');
  const button=document.getElementById('openLoginSettings'),login=document.getElementById('autoLaunch');check(button.hidden,'Login settings link should start hidden');
  login.checked=!login.checked;updateSaveState();const draft=login.checked;
  window.receive({...data,ok:false,action:'saveGeneral',message:t('无法修改启动设置，请在系统设置中检查登录项')});
  check(!button.hidden&&login.checked===draft,'Login failure lost draft or settings link');
  let request;send=value=>request=value;button.click();check(request.action==='openLoginSettings','Login link sent wrong action');
  window.receive({...data,ok:true,action:'saveGeneral'});check(button.hidden,'Successful save retained login error action');
  return 'Login save failure preserves draft and reveals actionable system link; success clears it';
 }finally{send=original;window.receive({...data,action:'load'})}
};
