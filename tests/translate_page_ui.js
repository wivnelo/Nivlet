window.runTranslatePageRegression=function(data){
 const check=(value,message)=>{if(!value)throw new Error(message)};
 window.showSection('translateSection');
 for(const id of ['translateTrigger','translateShotTrigger']){
  const options=[...document.getElementById(id).options];
  check(options.length===10,id+': ten choices (either, left, right for three keys, plus off)');
  check(new Set(options.map(o=>o.value)).size===10,id+': unique values');
  if(data.language==='en'||data.language==='ja'){
   for(const o of options)check(!/[一-鿿]/.test(o.textContent)||/[぀-ヿ]/.test(o.textContent),id+': untranslated option '+o.textContent);
  }
 }
 check(document.getElementById('translateTrigger').value==='doubleAlt'&&document.getElementById('translateShotTrigger').value==='doubleCtrl','Saved triggers are selected');
 return 'Translation triggers: ten choices each, translated';
};
