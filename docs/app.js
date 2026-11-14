(()=>{
  const nodes=[...document.querySelectorAll('[data-zh]')];
  const english=nodes.map(el=>el.innerHTML);
  const media=[...document.querySelectorAll('[data-zh-src]')].map(el=>({el,src:el.getAttribute('src'),alt:el.getAttribute('alt')}));
  const button=document.getElementById('language');
  const guide=document.getElementById('installGuide');
  const ui={
    en:{lang:'en',label:'中文',aria:'切换为简体中文',guide:'.en'},
    zh:{lang:'zh-CN',label:'English',aria:'Switch to English',guide:''}
  };
  let language='en';
  const apply=next=>{
    language=next;
    const t=ui[language];
    document.documentElement.lang=t.lang;
    nodes.forEach((el,i)=>{el.innerHTML=language==='zh'?el.dataset.zh:english[i];});
    media.forEach(m=>{m.el.src=language==='zh'?m.el.dataset.zhSrc:m.src;m.el.alt=language==='zh'?(m.el.dataset.zhAlt||m.alt):m.alt;});
    if(guide)guide.href=`https://github.com/wivnelo/Nivlet/blob/main/documentation/INSTALLATION${t.guide}.md`;
    button.textContent=t.label;
    button.setAttribute('aria-label',t.aria);
  };
  let saved=null;
  try{saved=localStorage.getItem('nivlet-language');}catch(e){}
  const preferred=saved||((navigator.language||'').toLowerCase().startsWith('zh')?'zh':'en');
  if(preferred==='zh')apply('zh');
  button.addEventListener('click',()=>{
    apply(language==='zh'?'en':'zh');
    try{localStorage.setItem('nivlet-language',language);}catch(e){}
  });
})();
