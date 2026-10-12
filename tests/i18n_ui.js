// Run inside the real settings WebView with the current backend payload.
window.runI18nRegression=function(data){
    const check=(value,message)=>{if(!value)throw new Error(message)};
    const key=document.getElementById('left-key'),originalKey=key.value;
    const inputID='com.example.nivlet-i18n';
    try{
        key.value='Z';
        window.addInputRule({bundleID:inputID,name:'通用',sourceID:data.sources[0].id});
        const update=(language,message,paused)=>window.receive({...data,ok:true,language,message,action:'refreshClipboard',clipboard:{...data.clipboard,paused,entries:[{id:999999,time:Date.now()/1000,text:'复制'}]}});
        update('en','已保存',false);
        check(document.documentElement.lang==='en','English document language');
        check(document.getElementById('tab-generalSection').textContent==='General','English tab');
        check(document.getElementById('pauseClip').textContent==='Pause Recording','Pause text');
        check(document.getElementById('status').textContent==='Saved','English status');
        check(document.querySelector('#clipHistory .clip-card-text').textContent==='复制','User clipboard content changed');
        check(document.querySelector('#inputRows [data-bundle="'+inputID+'"] span').textContent.trim()==='通用','App name translated');
        update('en','通用设置已保存',true);
        check(document.getElementById('status').textContent==='General settings saved','Status reused stale translation');
        check(document.getElementById('pauseClip').textContent==='Resume Recording','Resume text');
        update('zh-Hans','已保存',false);
        check(document.getElementById('tab-generalSection').textContent==='通用','Chinese tab restoration');
        check(document.getElementById('pauseClip').textContent==='暂停记录','Chinese pause restoration');
        check(key.value==='Z','Language switch discarded draft');
        return 'English/Chinese switching, changing status, pause/resume, draft and user content preservation passed';
    }finally{
        document.querySelector('#inputRows [data-bundle="'+inputID+'"]')?.remove();key.value=originalKey;
        window.receive({...data,ok:true,message:'',action:'refreshClipboard'});
    }
};
