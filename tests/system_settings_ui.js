window.runSystemSettingsRegression=function(data){
 const check=(condition,message)=>{if(!condition)throw new Error(message)};
 const previousSend=send;let request;
 try{
  // A 2.0.0 payload must not recreate the retired control or reset other selections.
  const legacy={...data.system,mac:true,ipv4:false,network:false};
  window.receive({...data,action:'load',system:legacy});
  window.showSection('systemSection');
  check(!document.getElementById('system-mac')&&!document.getElementById('system-value-mac'),'Retired MAC row reappeared');
  check(document.querySelectorAll('#systemFields input').length===8,'Other system fields changed');
  check(!document.getElementById('system-ipv4').checked&&!document.getElementById('system-network').checked&&document.getElementById('system-ipv6').checked,'Legacy settings reset network selections');
  window.receiveSystemValues({ok:true,values:{mac:'系统已隐藏',ipv4:'192.0.2.42',ipv6:'2001:db8::42',network:'fixture-rate'}});
  check(!document.getElementById('systemFields').textContent.includes('系统已隐藏'),'Retired placeholder leaked');
  check(document.getElementById('system-value-ipv4').textContent==='192.0.2.42'&&document.getElementById('system-value-ipv6').textContent==='2001:db8::42','IP readings changed');
  document.getElementById('system-cpu').checked=!legacy.cpu;updateSaveState();
  document.getElementById('cancelSettings').click();
  check(document.getElementById('system-cpu').checked===legacy.cpu&&!document.getElementById('system-ipv4').checked,'Cancel did not preserve legacy baseline');
  document.getElementById('system-cpu').checked=!legacy.cpu;updateSaveState();
  send=body=>{request=body};document.getElementById('saveSettings').click();
  const config=request?.pages?.systemSection?.config;
  check(config&&Object.keys(config).length===8&&!('mac' in config)&&!config.ipv4&&!config.network&&config.ipv6,'Global save changed remaining settings or retained retired key');
  return 'MAC removed; legacy selections, IP readings, cancel and global save preserved';
 }finally{send=previousSend;window.receive({...data,action:'load'});}
};
