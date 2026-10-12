// Run in an isolated WebView at wide and compact sizes, with synthetic data.
window.runLayoutRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw new Error(message)},main=document.querySelector('main'),footer=document.querySelector('footer');
 const visible=e=>{const r=e.getBoundingClientRect();return r.top>=main.getBoundingClientRect().top-1&&r.bottom<=footer.getBoundingClientRect().top+1};
 const pageFits=()=>{check(document.documentElement.scrollWidth<=innerWidth+1,'Document overflows horizontally');check(main.scrollWidth<=main.clientWidth+1,'Page overflows horizontally');const r=footer.getBoundingClientRect();check(r.bottom<=innerHeight+1,'Footer below viewport');for(const id of ['saveSettings','cancelSettings']){const b=document.getElementById(id);if(!b.hidden){const x=b.getBoundingClientRect();check(x.left>=0&&x.right<=innerWidth+1&&x.top>=r.top&&x.bottom<=r.bottom,'Footer action clipped: '+id)}}};
 try{
  for(const tab of document.querySelectorAll('[role=tab]')){window.showSection(tab.getAttribute('aria-controls'));pageFits()}
  window.showSection('inputSection');
  for(let i=0;i<30;i++)addInputRule({bundleID:'com.example.layout'+i,name:'LongApplicationName'.repeat(8)+i,sourceID:data.sources[0].id});
  pageFits();const last=document.querySelector('#inputRows .input-rule:last-child');last.scrollIntoView({block:'end'});check(visible(last),'Last long rule not reachable');check(visible(document.getElementById('chooseApp'))===false||main.scrollHeight>main.clientHeight,'Long list did not scroll');
  window.showSection('clipSection');document.querySelectorAll('.clip-config details').forEach(e=>e.open=true);
  receiveClipboard({...data.clipboard,config:{...data.clipboard.config,minutes:0},entries:Array.from({length:30},(_,i)=>({id:1000+i,kind:'text',time:Date.now()/1000,text:'LongClipboardText'.repeat(15)}))},false);
  pageFits();const config=document.querySelector('.clip-config'),history=document.querySelector('.clip-history');
  if(innerWidth<=900){check(getComputedStyle(config).overflowY==='visible'&&getComputedStyle(history).overflowY==='visible','Compact clipboard retains nested scrolling');const card=document.querySelector('#clipHistory .clip-card:last-child');card.scrollIntoView({block:'end'});check(visible(card),'Last clipboard card not reachable');}
  else{check(main.scrollHeight<=main.clientHeight+1,'Wide clipboard has outer page scroll');check(history.scrollHeight>history.clientHeight,'Long clipboard history not scrollable');history.scrollTop=history.scrollHeight;const card=document.querySelector('#clipHistory .clip-card:last-child').getBoundingClientRect();check(card.bottom<=history.getBoundingClientRect().bottom+1,'Last card clipped in history pane');}
  window.showSection('generalSection');const preview=document.getElementById('configurationPreview'),json=document.getElementById('configurationJSON');preview.hidden=false;json.textContent=Array(100).fill('SyntheticConfigurationValue'.repeat(8)).join('\n');check(getComputedStyle(json).overflowY==='visible','Import preview has nested scroll');pageFits();document.getElementById('cancelConfiguration').scrollIntoView({block:'end'});check(visible(document.getElementById('cancelConfiguration')),'Import actions not reachable');
  return 'Long rules, clipboard overflow ownership, import actions and fixed footer fit at '+innerWidth+'x'+innerHeight;
 }finally{document.querySelectorAll('.clip-config details').forEach(e=>e.open=false);document.getElementById('configurationPreview').hidden=true;window.receive({...data,ok:true,action:'load'})}
};
