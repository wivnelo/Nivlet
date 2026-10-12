window.runClipboardToggleRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const previousLanguage=uiLanguage,oldSend=send;let captured;
 try{
  send=body=>captured=body;
  const disabled={...data.clipboard,config:{...data.clipboard.config,enabled:false,minutes:0}};
  receiveClipboard(disabled,true);
  check(document.getElementById('pauseClip').disabled,'Disabled recording must disable pause');
  check(document.querySelectorAll('#clipHistory .clip-card').length===disabled.entries.length,'Disabled recording lost history cards');
  document.querySelector('#clipHistory .clip-card-actions button').click();
  check(captured.action==='copyClipboard','Disabled recording blocked history copy');
  receiveClipboard({...disabled,config:{...disabled.config,enabled:true}},true);
  check(!document.getElementById('pauseClip').disabled,'Enabled recording must allow pause');
  for(const language of ['en','zh-Hans']){
   uiLanguage=language;translateUI();
   check(document.body.textContent.includes(language==='en'?'Turning off recording keeps existing history':'关闭仅停止记录，已有历史仍按保留策略清理。'),'Recording explanation translation missing');
  }
  return 'Disabled history cards/copy, pause state and bilingual recording explanation passed';
 }finally{send=oldSend;uiLanguage=previousLanguage;receiveClipboard(data.clipboard,true);translateUI()}
};
