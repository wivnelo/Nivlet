window.runBrowserChoicesRegression=function(data){
 const check=(ok,message)=>{if(!ok)throw Error(message)};
 const requests=[];send=body=>requests.push(body);
 const svg=color=>'data:image/svg+xml,'+encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><rect width="24" height="24" fill="${color}"/></svg>`);
 const safari={id:'com.apple.Safari',name:'Safari',capabilities:{clearBrowsingData:true}};
 const brave={id:'com.brave.Browser',name:'Brave Browser',capabilities:{clearBrowsingData:true}};
 const firefox={id:'org.mozilla.firefox',name:'Firefox',capabilities:{clearBrowsingData:false}};
 data.browsers=[safari,brave,firefox];data.appIcons={[safari.id]:svg('blue'),[brave.id]:svg('orange')};
 data.browser={enabled:true,defaultBrowser:brave.id,rules:[{domain:'example.com',browser:brave.id,subdomains:true}],appRules:[{bundleID:'com.example.telegram',name:'Telegram',browser:brave.id}]};
 window.receive({...data,action:'load'});window.showSection('browserSection');
 const selects=[...document.querySelectorAll('#browserDefault,#browserRules select,#browserAppRules select')];
 for(const select of selects){check(select.value===brave.id,'Saved Brave selection');const icon=select.parentElement.querySelector('.browser-icon');check(icon&&icon.src===data.appIcons[brave.id]&&icon.alt==='','Selected real icon');check(select.options.length===3,'Shared browser list')}
 check(browserDataMenu.children.length===2,'Unsupported installed Firefox must not offer clearing');
 const domain=document.querySelector('#browserRules input');domain.value='draft.example';
 const snapshot=pageSnapshot('browserSection');selects[2].focus();
 window.receive({...data,action:'refreshApplications',browsers:[safari,{...brave,name:'Brave'},firefox],appIcons:{[brave.id]:svg('red')}});
 check(document.activeElement===selects[2]&&pageSnapshot('browserSection')===snapshot,'Refresh changed focus or draft');
 for(const select of selects)check(select.selectedOptions[0].textContent==='Brave'&&select.parentElement.querySelector('img').src===svg('red'),'Name/icon refresh');
 selects[0].value=safari.id;selects[0].dispatchEvent(new Event('change',{bubbles:true}));check(selects[0].parentElement.querySelector('img').src===data.appIcons[safari.id],'Native selection icon');
 check(document.querySelector('#browserAppRules .browser-icon').src===svg('red'),'Source app icon replaced browser icon');
 browserDataButton.click();window.receive({...data,action:'prepareBrowserData',requestID:requests.at(-1).requestID,ok:true});
 const beforeClear=pageSnapshot('browserSection');browserDataMenu.lastElementChild.click();check(requests.at(-1).bundleID===brave.id&&requests.at(-1).action==='openBrowserData','Brave clear dispatch');
 window.receive({...data,action:'openBrowserData',ok:false});check(pageSnapshot('browserSection')===beforeClear,'Clear failure erased draft');
 for(const language of ['zh-Hans','zh-Hant','en','ja']){window.receive({...data,action:'refreshApplications',language,translations:data.testTranslations[language]});check(browserDataButton.textContent===t('清除浏览数据…'),'Localized clear label')}
 window.receive({...data,action:'refreshApplications',browsers:[firefox]});check(browserDataButton.disabled,'No supported capability');
 check(domain.value==='draft.example','Removal erased domain draft');
 return 'PASS: shared names/capabilities, selected icons, native selectors, focus, four locales, Brave dispatch and draft preservation';
};
