// Execute in the actual settings WebView with its current backend payload.
window.runConfigurationRegression=function(data){
    const check=(ok,message)=>{if(!ok)throw new Error(message)};
    const originalSend=send,originalModules=window.importedModules;
    const key=document.getElementById('left-key'),originalKey=key.value;
    try{
        let captured;
        send=value=>{captured=value};
        for(const action of ['exportConfiguration','exportDefaults','chooseConfiguration','applyConfiguration','cancelConfiguration']){
            document.getElementById(action).click();check(captured.action===action,'Wrong configuration action: '+action);
        }
        const value={format:'Nivlet',version:1,modules:{launcher:{enabled:false,rules:[{name:'<img src=x onerror=alert(1)>',bundleID:'com.example.app'}]}}};
        window.previewConfiguration(value);
        check(!document.getElementById('configurationPreview').hidden,'Preview hidden');
        check(document.getElementById('configurationJSON').textContent.includes('<img src=x'),'Preview altered source content');
        check(!document.getElementById('configurationJSON').querySelector('img'),'Preview injected HTML');
        key.value='Z';window.importedModules={general:true};
        window.receive({...data,ok:true,action:'applyConfiguration',general:{...data.general,appearance:'dark'}});
        check(key.value==='Z','Partial import discarded unrelated draft');
        check(document.getElementById('appearance').value==='dark','Imported general settings not rendered');
        window.previewConfiguration(null);check(document.getElementById('configurationPreview').hidden,'Cancel left preview visible');
        window.receive({...data,ok:true,language:'en',action:'refreshClipboard'});
        check(document.getElementById('exportConfiguration').textContent==='Export configuration…','Export label untranslated');
        return 'Configuration actions, safe JSON preview, cancel, selective refresh and English labels passed';
    }finally{
        send=originalSend;window.importedModules=originalModules;key.value=originalKey;
        window.receive({...data,ok:true,action:'load',message:''});
    }
};
