window.runClipboardToggleRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const previousLanguage=uiLanguage,oldSend=send;let captured;
 try{
  send=body=>captured=body;
  const toggle=document.getElementById('clipEnabled'),summary=toggle.closest('.module-summary');
  check(summary?.classList.contains('settings-group')&&toggle.parentElement.classList.contains('toggle-row')&&!toggle.closest('.clip-config'),'Recording master switch is not in the shared summary card');
  check(summary.querySelector('p')?.textContent===t('关闭仅停止记录，已有历史仍按保留策略清理。'),'Recording stop/history explanation changed');
  for(const key of ['未开启跨重启保留时，退出后历史不再保留。复制敏感内容前，请先关闭记录并保存。','应用排除不能覆盖所有敏感内容。'])check(![...document.querySelectorAll('#clipSection p')].some(p=>p.textContent===t(key)),'Removed clipboard hint remains visible');
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
