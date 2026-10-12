window.runTabsRegression=function(data){
 const nav=document.querySelector('nav'),original=[...nav.children],oldSend=send,key=document.getElementById('left-key'),draft=key.value;
 const check=(value,message)=>{if(!value)throw new Error(message)};
 try{
  for(const tab of nav.children){
   const range=document.createRange();range.selectNodeContents(tab);const text=range.getBoundingClientRect(),box=tab.getBoundingClientRect();
   check(Math.abs((text.left+text.right-box.left-box.right)/2)<1,'Tab text is not centered: '+tab.id);
   check(Math.abs((text.top+text.bottom-box.top-box.bottom)/2)<2,'Tab text is not vertically centered: '+tab.id);
   const clean=getComputedStyle(tab),color=clean.color,weight=clean.fontWeight,background=clean.backgroundColor,width=box.width,height=box.height;
   const cleanDot=getComputedStyle(tab,'::after');check(cleanDot.backgroundColor==='rgba(0, 0, 0, 0)','Clean tab dot visible');
   tab.dataset.dirty='true';const dirty=getComputedStyle(tab),dot=getComputedStyle(tab,'::after');
   check(dirty.color===color,'Dirty tab must retain original text color');
   check(dot.position==='absolute'&&dot.bottom==='-7px'&&dot.width==='4px'&&dot.height==='4px'&&dot.borderRadius==='50%','Bottom dot geometry incorrect');
   check(Math.abs(parseFloat(dot.left)-width/2)<1,'Dot must be horizontally centered');
   check(dot.backgroundColor==='rgb(198, 146, 82)','Dirty tab dot must be soft orange');
   check(dirty.fontWeight===weight&&dirty.backgroundColor===background,'Dirty tab changes weight/background');
   check(tab.getBoundingClientRect().width===width&&tab.getBoundingClientRect().height===height,'Dirty state changes tab size');tab.dataset.dirty='false';check(getComputedStyle(tab,'::after').backgroundColor==='rgba(0, 0, 0, 0)','Clean tab dot not cleared');delete tab.dataset.dirty;
  }
  applyTabOrder(['windowSection','inputSection','clipSection','systemSection','browserSection','launcherSection']);
  key.value='Z';let captured;send=body=>captured=body;
  const launcher=document.getElementById('tab-launcherSection'),target=document.getElementById('tab-windowSection');
  check(!document.getElementById('tab-generalSection').onpointerdown,'General must be fixed');
  check(!document.getElementById('tab-aboutSection').onpointerdown,'About must be fixed');
  const selected=nav.querySelector('[aria-selected=true]');
  launcher.dispatchEvent(new PointerEvent('pointerdown',{button:0,clientX:launcher.getBoundingClientRect().left,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointermove',{clientX:target.getBoundingClientRect().left+1,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
  launcher.click();check(nav.querySelector('[aria-selected=true]')===selected,'Drag click switched page');
  check(nav.children[0].id==='tab-generalSection'&&nav.children[1]===launcher,'Drag order incorrect');
  check(captured.action==='saveTabOrder'&&captured.order[0]==='launcherSection','Order not sent');
  window.receive({...data,action:'saveTabOrder',general:{...data.general,tabOrder:captured.order}});
  check(key.value==='Z','Sorting erased draft');
  window.receive({...data,action:'load',general:{...data.general,tabOrder:captured.order}});
  check(nav.children[1]===launcher,'Reload lost order');
  applyTabOrder(['aboutSection','missingSection','launcherSection','launcherSection']);
  check(nav.lastElementChild.id==='tab-aboutSection','Legacy About position must normalize to last');
  launcher.dispatchEvent(new PointerEvent('pointerdown',{button:0,clientX:launcher.getBoundingClientRect().left,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointermove',{clientX:nav.getBoundingClientRect().right+100,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
  check(nav.lastElementChild.id==='tab-aboutSection'&&nav.lastElementChild.previousElementSibling===launcher,'Drag crossed fixed About');
  check(nav.children.length===original.length&&nav.children[0].id==='tab-generalSection','Future or duplicate IDs corrupted tabs');
  return 'Tab drag, fixed General/About, bounded drag, persistence reload and draft preservation passed';
 }finally{send=oldSend;for(const tab of original)nav.append(tab);key.value=draft;window.receive({...data,action:'load'});key.value=draft}
};
