// Run in the actual settings WebView with its current backend payload.
window.runWindowsRegression=function(data){
    const check=(ok,message)=>{if(!ok)throw new Error(message)};
    const group=document.getElementById('windowGroup'),oldGroup=group.value,originalSend=send;
    const left=document.getElementById('left-key'),grid=document.getElementById('grid9-key');
    const oldLeft=left.value,oldGrid=grid.value;
    try{
        check(Object.keys(actions).length===29,'Missing window actions');
        check(document.querySelectorAll('#rows .layout-preview').length===24,'Missing layout previews');
        for(const id of ['left','right','topLeft','bottomRight','center','maximize','grid9']){
            const icon=document.querySelector('[data-action="'+id+'"] .layout-preview');
            check(icon?.getAttribute('aria-hidden')==='true','Preview must be decorative: '+id);
            check(icon.querySelector('.layout-region'),'Missing position region: '+id);
        }
        for(const [name,expected] of Object.entries({basic:6,corners:5,thirds:5,grid:9,adjust:4})){
            group.value=name;group.dispatchEvent(new Event('change'));
            check([...document.querySelectorAll('#rows tr')].filter(row=>!row.hidden).length===expected,'Wrong visible group: '+name);
        }
        // Isolate the capture fixture from existing user shortcuts (e.g. Ctrl+Option+Down).
        for(const input of document.querySelectorAll('[data-shortcut-key]'))input.value='';
        left.value='Z';group.value='grid';group.dispatchEvent(new Event('change'));
        grid.dispatchEvent(new KeyboardEvent('keydown',{key:'ArrowDown',ctrlKey:true,altKey:true,bubbles:true,cancelable:true}));
        check(grid.value==='↓','Grid shortcut did not capture arrow');
        let captured;send=value=>{captured=value};document.getElementById('save').click();
        check(Object.keys(captured.config.shortcuts).length===29,'Save omitted hidden groups');
        check(captured.config.shortcuts.left.key==='Z'&&captured.config.shortcuts.grid9.key==='↓','Draft lost across groups');
        check(captured.config.shortcuts.grid9.mods.join('+')==='ctrl+alt','Grid modifiers not captured');
        window.receive({...data,ok:true,action:'refreshClipboard',language:'en'});
        check(group.options[0].textContent==='Basic Layouts'&&group.options[3].textContent==='Nine-cell Grid','Group options not translated');
        check(grid.getAttribute('aria-label')==='Grid 9 key','Grid accessibility label not translated');
        check(left.value==='Z','Translation discarded window draft');
        return 'All 29 actions, grouped layout, hidden-group save, grid arrow capture, English options and draft preservation passed';
    }finally{
        send=originalSend;group.value=oldGroup;showWindowGroup();left.value=oldLeft;grid.value=oldGrid;
        window.receive({...data,ok:true,action:'load',message:''});
    }
};
