
window.runI18nRegression=function(data){
    const check=(value,message)=>{if(!value)throw new Error(message)};
    const key=document.getElementById('left-key'),originalKey=key.value,control=document.getElementById('left-ctrl'),originalControl=control.checked;
    const inputID='com.example.nivlet-i18n';
    try{
        key.value='Z';control.checked=true;
        window.addInputRule({bundleID:inputID,name:'通用',sourceID:data.sources[0].id});
        window.showSection('clipSection');
        const catalog=data.testTranslations;
        check(catalog&&catalog.en&&catalog.ja&&catalog['zh-Hant'],'Four synthetic language catalogues required');
        const when=1793325600;
        const update=(language,message)=>window.receive({...data,ok:true,language,translations:catalog[language],message,action:'refreshClipboard',clipboard:{...data.clipboard,entries:[{id:999999,time:when,text:'复制'}]}});
        const locales={'zh-Hans':'zh-CN','zh-Hant':'zh-TW',en:'en-US',ja:'ja-JP'};
        for(const language of ['en','zh-Hant','ja','zh-Hans','ja','en','zh-Hans']){
            const expected=key=>catalog[language][key]||key;
            update(language,'已保存');
            window.receiveSystemValues({ok:true,values:{cpu:'12% / 8 Core',ipv4:'192.0.2.42'}});
            check(document.getElementById('system-value-cpu').textContent==='12% / 8 '+expected('核心'),'CPU display unit '+language);
            check(document.getElementById('system-value-ipv4').textContent==='192.0.2.42','System address must not be translated');
            check(document.documentElement.lang===language,'Document language '+language);
            check(document.getElementById('tab-generalSection').textContent===expected('通用'),'Translated tab '+language);
            check(document.querySelector('#popupShortcut .popup-shortcut-row>span').textContent===expected('启用菜单快捷键'),'Fixed shortcut toggle label '+language);
            check(document.getElementById('status').textContent===expected('已保存'),'Status '+language);
            check(document.querySelector('#clipHistory .clip-card-text').textContent==='复制','User clipboard content changed');
            check(document.querySelector('#inputRows [data-bundle="'+inputID+'"] span').textContent.trim()==='通用','App name translated');
            check(document.querySelector('#clipHistory time').textContent===new Date(when*1000).toLocaleString(locales[language],{month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit'}),'Date locale '+language);
            update(language,'通用设置已保存');
            check(document.getElementById('status').textContent===expected('通用设置已保存'),'Status reused stale translation '+language);
            check(!document.getElementById('pauseClip'),'Retired pause control returned '+language);
            check(key.value==='Z'&&control.checked,'Language switch discarded shortcut draft');
            check(document.querySelector('#inputRows [data-bundle="'+inputID+'"] select').value===data.sources[0].id,'Language switch altered input-source rule');
            check(document.querySelector('#inputRows [data-bundle="'+inputID+'"] select').getAttribute('aria-label')==='通用 · '+expected('输入法'),'Input-source accessible label translated user data or retained old language');
            const browserRule=document.querySelector('#browserAppRules [data-bundle]');
            check(browserRule.querySelector('select').getAttribute('aria-label')===browserRule.dataset.name+' · '+expected('打开浏览器'),'Browser accessible label retained old language');
        }
        check([...document.getElementById('language').options].map(option=>option.value).join(',')==='system,zh-Hans,en,zh-Hant,ja','Language choices changed or missing');
        return 'Four-language round trips, current dictionary selection, status, date locale, drafts, user text and app/input identifiers preserved';
    }finally{
        document.querySelector('#inputRows [data-bundle="'+inputID+'"]')?.remove();key.value=originalKey;control.checked=originalControl;
        window.receive({...data,ok:true,message:'',action:'refreshClipboard'});
    }
};
