window.runClipboardToggleRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const previousLanguage=uiLanguage,oldSend=send;let captured;
 try{
  send=body=>captured=body;
  const disabled={...data.clipboard,config:{...data.clipboard.config,enabled:false,minutes:0}};
  receiveClipboard(disabled,true);
  check(!document.getElementById('clipEnabled').checked&&!document.getElementById('pauseClip'),'Only the persisted recording switch may control capture');
  check(document.querySelectorAll('#clipHistory .clip-card').length===disabled.entries.length,'Disabled recording lost history cards');
  document.querySelector('#clipHistory .clip-card-actions button').click();
  check(captured.action==='copyClipboard','Disabled recording blocked history copy');
  receiveClipboard({...disabled,config:{...disabled.config,enabled:true}},true);
  check(document.getElementById('clipEnabled').checked,'Enabled recording switch missing');
  for(const language of ['en','zh-Hans']){
   uiLanguage=language;translations=data.testTranslations[language];translateUI();
   check(document.body.textContent.includes(language==='en'?'Turning off recording keeps existing history':'关闭仅停止记录，已有历史仍按保留策略清理。'),'Recording explanation translation missing');
  }
  return 'Disabled history cards/copy, single recording control and bilingual recording explanation passed';
 }finally{send=oldSend;uiLanguage=previousLanguage;translations=data.translations;receiveClipboard(data.clipboard,true);translateUI()}
};
