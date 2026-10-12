// Run only in an isolated WebView; never saves user settings.
window.runConflictsRegression=function(data){
    const oldSend=send,check=(value,message)=>{if(!value)throw new Error(message)};
    let captured;
    try{
        send=body=>captured=body;
        for(const [hostID,add] of [['launcherRules',window.addLauncherRule],['inputRows',window.addInputRule],['browserAppRules',window.addBrowserAppRule]]){
            const host=document.getElementById(hostID),id='com.example.duplicate-'+hostID.toLowerCase();
            const rule={bundleID:id,name:'Duplicate fixture',sourceID:data.sources[0].id,browser:data.browsers[0].id,shortcut:{key:'',mods:[]}};
            add(rule);const row=[...host.children].find(row=>row.dataset.bundle===id),count=host.children.length;
            const select=row.querySelector('select'),input=row.querySelector('.launcher-key');if(select)select.value=rule.sourceID||rule.browser;if(input)input.value='Q';
            const original=row.innerHTML,values=JSON.stringify([...row.querySelectorAll('input,select')].map(field=>[field.value,field.checked]));add({...rule,bundleID:id.toUpperCase(),shortcut:{key:'X',mods:['ctrl']}});
            check(host.children.length===count,'Duplicate application inserted in '+hostID);check(row.innerHTML===original&&JSON.stringify([...row.querySelectorAll('input,select')].map(field=>[field.value,field.checked]))===values,'Duplicate overwrote original rule');
            check(!document.getElementById(hostID+'-notice').hidden,'Duplicate app notice missing');row.remove();
        }
        // The same application can be used by different modules.
        const shared={bundleID:'com.example.shared',name:'Shared fixture',sourceID:data.sources[0].id,shortcut:{key:'',mods:[]}};
        window.addInputRule(shared);window.addLauncherRule(shared);
        check(document.querySelector('#inputRows [data-bundle="com.example.shared"]')&&document.querySelector('#launcherRules [data-bundle="com.example.shared"]'),'Different modules wrongly exclude each other');
        for(const input of document.querySelectorAll('[data-shortcut-key]'))input.value='';
        const left=document.getElementById('left-key'),popup=document.getElementById('popup-key'),row=document.querySelector('#launcherRules [data-bundle="com.example.shared"]'),appKey=row.querySelector('.launcher-key');
        for(const prefix of ['left','popup'])for(const mod of Object.keys(mods))document.getElementById(prefix+'-'+mod).checked=['ctrl','cmd'].includes(mod);
        for(const flag of row.querySelectorAll('[data-mod]'))flag.checked=['ctrl','cmd'].includes(flag.dataset.mod);
        left.value='q';appKey.value='Q';
        check(refreshConflictHints().some(problem=>problem.entries.length===2),'Cross-module shortcut conflict missed');
        check(left.getAttribute('aria-invalid')==='true'&&appKey.getAttribute('aria-invalid')==='true','Conflict fields not marked');
        captured=null;document.getElementById('saveLauncher').click();check(captured===null,'Conflicting launcher save reached backend');
        appKey.value='W';popup.value='Q';check(!canSaveShortcuts('clipSection'),'Clipboard/window conflict missed');
        popup.value='';appKey.value='';left.value='ArrowLeft';const right=document.getElementById('right-key');right.value='←';for(const mod of Object.keys(mods))document.getElementById('right-'+mod).checked=['ctrl','cmd'].includes(mod);
        check(!canSaveShortcuts('windowSection'),'Arrow aliases not normalized');right.value='';left.value='';check(refreshConflictHints().length===0,'Cleared bindings still conflict');
        appKey.value='Z';for(const flag of row.querySelectorAll('[data-mod]'))flag.checked=flag.dataset.mod==='shift';check(!canSaveShortcuts('launcherSection'),'Modifier-only invalid shortcut accepted');
        appKey.value='F12';row.querySelector('[data-mod=ctrl]').checked=true;check(refreshConflictHints().some(problem=>problem.message.includes(t('快捷键支持字母、数字、方向键、Return、= 或 -'))),'Unsupported key message missing');check(!canSaveShortcuts('launcherSection'),'Unsupported key accepted');appKey.value='';
        addBrowserRule({domain:'duplicate.example',browser:data.browsers[0].id,subdomains:true});addBrowserRule({domain:'DUPLICATE.EXAMPLE.',browser:data.browsers[0].id,subdomains:false});
        check(browserDomainConflicts()?.name==='duplicate.example','Normalized duplicate domain missed');captured=null;document.getElementById('saveBrowser').click();check(captured===null,'Duplicate domains submitted');
        const rows=[...document.querySelectorAll('.browser-rule')];rows.at(-1).remove();check(!browserDomainConflicts(),'Resolved domain conflict still reported');
        return 'Duplicate apps preserve original rules; cross-module shortcuts, aliases, invalid modifiers and domain duplicates are blocked';
    }finally{send=oldSend;window.receive({...data,ok:true,action:'load'});refreshConflictHints();browserDomainConflicts()}
};
