window.runClipboardPolishRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 const oldSend=send,language=uiLanguage,limit=document.getElementById('clipLimit').value,minutes=document.getElementById('clipMinutes').value;
 try{
  const originalSection=document.querySelector('section.panel:not([hidden])').id;
  for(const summary of document.querySelectorAll('summary')){
   showSection(summary.closest('section').id);
   const details=summary.parentElement,wasOpen=details.open;
   details.open=false;
   const closed=getComputedStyle(summary,'::before');
   check(closed.width==='8px'&&closed.height==='10px'&&closed.content==='""','Disclosure arrow dimensions differ');
   check(getComputedStyle(summary).gap==='8px'&&getComputedStyle(summary).listStyleType==='none','Disclosure spacing or native marker differs');
   details.open=true;
   check(getComputedStyle(summary,'::before').transform==='matrix(0, 1, -1, 0, 0, 0)','Expanded disclosure arrow direction wrong');
   details.open=wasOpen;
  }
  showSection(originalSection);
  check(document.getElementById('clipLimit').tagName==='SELECT','Limit is not a select');
  fillClipboardChoices('clipLimit',limitChoices,77);fillClipboardChoices('clipMinutes',retentionChoices,113);
  check(document.getElementById('clipLimit').value==='77'&&document.getElementById('clipMinutes').value==='113','Legacy values lost');
  uiLanguage='en';translateUI();check(document.getElementById('clipMinutes').selectedOptions[0].textContent==='113 minutes (custom)','Custom translation missing');
  uiLanguage='zh-Hans';translateUI();check(document.getElementById('clipMinutes').selectedOptions[0].textContent==='113 分钟（自定义）','Custom translation did not restore');
  check(retentionChoices.map(pair=>pair[0]).join(',')==='30,60,120,240,480,720,1440,0','Retention choices wrong');
  let captured;send=body=>captured=body;
  fillClipboardChoices('clipMinutes',retentionChoices,0);document.getElementById('saveClip').onclick();check(captured.config.minutes===0&&captured.config.limit===77,'Permanent save payload wrong');
  const now=Date.now()/1000;
  receiveClipboard({...data.clipboard,config:{...data.clipboard.config,minutes:0},entries:[{id:91,kind:'text',time:now-172800,text:'<script>unchanged</script>'},{id:92,kind:'image',time:now-172800,text:'图片',preview:'data:image/png;base64,iVBORw0KGgo='}]},false);
  const cards=[...document.querySelectorAll('#clipHistory .clip-card')];check(cards.length===2,'Permanent entries expired in UI');
  check(cards[0].querySelector('.clip-card-text').textContent==='<script>unchanged</script>'&&!cards[0].querySelector('script'),'Text not safely rendered');
  check(cards[0].querySelectorAll('.clip-card-actions button').length===1,'Text copy missing');
  check(cards[1].querySelectorAll('.clip-card-actions button').length===2&&cards[1].querySelector('img')&&!cards[1].querySelector('.clip-card-text'),'Image actions/label incorrect');
  cards[1].querySelector('.clip-card-actions button').click();check(captured.action==='previewClipboard'&&captured.id===92,'Preview target wrong');
  cards[1].querySelector('.clip-card-actions button:last-child').click();check(captured.action==='copyClipboard'&&captured.id===92,'Copy target wrong');
  clipMinutes=1440;renderHistory();check(!document.querySelector('#clipHistory .clip-card'),'Finite expiry not restored');
  return 'Clipboard dropdowns, custom values, i18n, permanent UI expiry, card actions and safe text rendering passed';
 }finally{send=oldSend;uiLanguage=language;receiveClipboard(data.clipboard,false);fillClipboardChoices('clipLimit',limitChoices,Number(limit));fillClipboardChoices('clipMinutes',retentionChoices,Number(minutes));translateUI()}
};
