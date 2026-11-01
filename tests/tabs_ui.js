window.runTabsRegression=function(data){
 const nav=document.querySelector('nav'),original=[...nav.children],oldSend=send,key=document.getElementById('left-key'),draft=key.value;
 const check=(value,message)=>{if(!value)throw new Error(message)};
 try{
  check(nav.getAttribute('aria-orientation')==='vertical','Sidebar must expose vertical navigation');
  const sidebar=document.querySelector('.settings-sidebar').getBoundingClientRect(),main=document.querySelector('main').getBoundingClientRect();
  check(sidebar.right<=main.left+1,'Sidebar overlaps content');
  for(const tab of nav.children){
   const label=tab.querySelector('.sidebar-label'),icon=tab.querySelector('.sidebar-icon');
   check(label&&icon&&icon.getAttribute('aria-hidden')==='true','Sidebar label/icon missing or decorative icon exposed');
   const text=label.getBoundingClientRect(),box=tab.getBoundingClientRect(),image=icon.getBoundingClientRect();
   check(text.left>=image.right+5&&text.right<=box.right-10,'Sidebar label overlaps icon or dirty marker');
   check(box.width<=sidebar.width&&box.left>=sidebar.left,'Sidebar row exceeds sidebar');
   const clean=getComputedStyle(tab),color=clean.color,weight=clean.fontWeight,background=clean.backgroundColor,width=box.width,height=box.height;
   const cleanDot=getComputedStyle(tab,'::after');check(cleanDot.backgroundColor==='rgba(0, 0, 0, 0)','Clean tab dot visible');
   tab.dataset.dirty='true';const dirty=getComputedStyle(tab),dot=getComputedStyle(tab,'::after');
   check(dirty.color===color,'Dirty tab must retain original text color');
   check(dot.position==='absolute'&&parseFloat(dot.right)>=5&&dot.width==='5px'&&dot.height==='5px','Trailing draft marker missing');
   check(dot.backgroundColor==='rgb(198, 146, 82)','Dirty tab dot must be soft orange');
   check(dirty.fontWeight===weight&&dirty.backgroundColor===background,'Dirty tab changes weight/background');
   check(tab.getBoundingClientRect().width===width&&tab.getBoundingClientRect().height===height,'Dirty state changes tab size');tab.dataset.dirty='false';check(getComputedStyle(tab,'::after').backgroundColor==='rgba(0, 0, 0, 0)','Clean tab dot not cleared');delete tab.dataset.dirty;
  }
  const first=nav.firstElementChild;first.click();first.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowDown',bubbles:true,cancelable:true}));
  check(nav.querySelector('[aria-selected=true]')===nav.children[1]&&document.activeElement===nav.children[1],'ArrowDown did not select and focus next sidebar item');
  nav.children[1].dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowUp',bubbles:true,cancelable:true}));
  check(nav.querySelector('[aria-selected=true]')===first,'ArrowUp did not return to previous sidebar item');
  applyTabOrder(['windowSection','inputSection','clipSection','systemSection','browserSection','launcherSection']);
  key.value='Z';let captured;send=body=>captured=body;
  const launcher=document.getElementById('tab-launcherSection'),target=document.getElementById('tab-windowSection');
  check(!document.getElementById('tab-generalSection').onpointerdown,'General must be fixed');
  check(!document.getElementById('tab-aboutSection').onpointerdown,'About must be fixed');
  const selected=nav.querySelector('[aria-selected=true]');
  launcher.dispatchEvent(new PointerEvent('pointerdown',{button:0,clientY:launcher.getBoundingClientRect().top,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointermove',{clientY:target.getBoundingClientRect().top+1,bubbles:true}));
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
  launcher.dispatchEvent(new PointerEvent('pointerdown',{button:0,clientY:launcher.getBoundingClientRect().top,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointermove',{clientY:nav.getBoundingClientRect().bottom+100,bubbles:true}));
  document.dispatchEvent(new PointerEvent('pointerup',{bubbles:true}));
  check(nav.lastElementChild.id==='tab-aboutSection'&&nav.lastElementChild.previousElementSibling===launcher,'Drag crossed fixed About');
  check(nav.children.length===original.length&&nav.children[0].id==='tab-generalSection','Future or duplicate IDs corrupted tabs');
  return 'Sidebar vertical keys, visible labels/draft markers, bounded drag, fixed endpoints, persistence and draft preservation passed';
 }finally{send=oldSend;for(const tab of original)nav.append(tab);key.value=draft;window.receive({...data,action:'load'});key.value=draft}
};
