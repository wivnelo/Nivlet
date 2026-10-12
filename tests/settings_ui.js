// Run in the real settings WebView with its current reply payload.
window.runSettingsRegression=function(data){
    const key=document.getElementById('left-key');
    const limit=document.getElementById('clipLimit');
    const browser=document.getElementById('browserEnabled');
    const original={key:key.value,limit:limit.value,browser:browser.checked,send};
    const inputID='com.example.toolkit-ui-input';
    const browserID='com.example.toolkit-ui-browser';
    const check=(condition,message)=>{if(!condition)throw new Error(message)};
    try{
        key.value='Z';fillClipboardChoices('clipLimit',limitChoices,77);browser.checked=!original.browser;
        window.addInputRule({bundleID:inputID,name:'UI test input',sourceID:data.sources[0].id});
        window.addBrowserAppRule({bundleID:browserID,name:'UI test browser',browser:data.browsers[0].id});
        let captured;
        send=body=>{captured=body};
        document.getElementById('saveInput').click();
        check(captured.action==='saveInput','Wrong action');
        check(captured.config.rules.some(rule=>rule.bundleID===inputID),'Input rule missing');
        check(!captured.config.rules.some(rule=>rule.bundleID===browserID),'Browser rule leaked into input settings');
        send=original.send;
        window.receive({...data,ok:true,action:'refreshClipboard',message:''});
        check(key.value==='Z'&&limit.value==='77'&&browser.checked!==original.browser,'Refresh erased settings drafts');
        window.receive({...data,ok:true,action:'saveSystem',message:''});
        check(key.value==='Z'&&limit.value==='77'&&browser.checked!==original.browser,'Saving system erased another module draft');
        check(document.querySelector('#inputRows [data-bundle="'+inputID+'"]'),'Refresh erased unsaved rule');
        const clear=document.getElementById('clearClip');check(clear.previousElementSibling.id==='refreshClip','Clear action not beside refresh');
        const history=data.clipboard;receiveClipboard({...history,entries:[]},false);check(clear.disabled,'Empty history clear enabled');
        receiveClipboard({...history,entries:[{id:987,time:Date.now()/1000,text:'UI fixture'}]},false);check(!clear.disabled,'Clear disabled with history');
        send=body=>{captured=body};clear.click();check(captured.action==='clearClipboard','Clear action missing');send=original.send;receiveClipboard(history,false);
        addBrowserRule({domain:'ui-first.example',browser:data.browsers[0].id,subdomains:true});
        addBrowserRule({domain:'ui-second.example',browser:data.browsers[0].id,subdomains:true});
        const added=[...document.querySelectorAll('.browser-rule')].slice(-2);
        try{
            added[1].querySelector('[data-move=up]').click();
            check(added[1].nextElementSibling===added[0],'Move up failed');
            added[1].querySelector('[data-move=down]').click();
            check(added[0].nextElementSibling===added[1],'Move down failed');
        }finally{for(const row of added)row.remove();updateBrowserOrder()}
        return 'Input isolation, draft preservation, cross-module save and rule ordering passed';
    }finally{
        send=original.send;key.value=original.key;limit.value=original.limit;browser.checked=original.browser;
        document.querySelector('#inputRows [data-bundle="'+inputID+'"]')?.remove();
        document.querySelector('#browserAppRules [data-bundle="'+browserID+'"]')?.remove();
    }
};
