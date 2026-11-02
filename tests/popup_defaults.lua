
dofile('tests/runtime.lua')
local popupKey='desktoptoolkit.clipboard.shortcut.v1'
local windowKey='desktoptoolkit.preferences.v1'
local launcherKey='desktoptoolkit.launcher.v1'
local default={key='V',mods={'cmd','shift'}}
local function signature(item)return table.concat(item.mods,'+')..'+'..item.key end
local occupied,alerts,options
local function boot(value,extra)
    options=extra or {};occupied={};alerts={}
    if value==nil then hs.settings.clear(popupKey) else hs.settings.set(popupKey,value) end
    hs.settings.set(windowKey,options.windows or {enabled=false,shortcuts={}})
    hs.settings.set(launcherKey,options.launcher or {enabled=false,rules={}})
    hs.settings.set('desktoptoolkit.general.v1',{showMenu=true,appearance='system',language='zh-Hans',sleepShortcut=false})
    if options.external then occupied['cmd+shift+V']=options.external end
    hs.alert.show=function(message)alerts[#alerts+1]=message end
    hs.hotkey.systemAssigned=function(mods,key)return options.systemDefault and table.concat(mods,'+')..'+'..key=='cmd+shift+V' end
    hs.hotkey.assignable=function(mods,key)return occupied[table.concat(mods,'+')..'+'..key]==nil end
    hs.hotkey.bind=function(mods,key,callback)
        local sig=table.concat(mods,'+')..'+'..key
        if options.failDefault and sig=='cmd+shift+V' then return nil end
        assert(not occupied[sig],'A startup default stole an existing binding')
        local token={callback=callback}
        function token:delete()if occupied[sig]==self then occupied[sig]=nil end end
        occupied[sig]=token;return token
    end

    package.loaded['modules.launcher']=nil
    dofile('Toolkit/init.lua')
    return desktopToolkit
end
local app=boot(nil)
assert(signature(app.popupShortcut)=='cmd+shift+V' and app.popupBinding==occupied['cmd+shift+V'])
assert(hs.settings.get(popupKey)==nil,'Default startup must not write a new preference')
assert(signature(app.configuration.export(true).modules.popupShortcut)=='cmd+shift+V')
assert(app.savePopup(false));assert(app.popupShortcut==nil and occupied['cmd+shift+V']==nil and hs.settings.get(popupKey)==false)
app=boot(hs.settings.get(popupKey));assert(not app.popupShortcut and not app.popupBinding and next(occupied)==nil)
app=boot(hs.settings.get(popupKey));assert(hs.settings.get(popupKey)==false and next(occupied)==nil,'Explicit off reset on another restart')

local legacy={key='K',mods={'ctrl'}}
app=boot(legacy);assert(signature(app.popupShortcut)=='ctrl+K' and occupied['ctrl+K']==app.popupBinding)
assert(app.saveGeneral({showMenu=true,appearance='light',language='zh-Hans'}))
assert(signature(hs.settings.get(popupKey))=='ctrl+K','Other page migrated a legacy key')
local clipboard=require('modules.clipboard')
assert(app.saveClipboardPage(clipboard.config,app.popupShortcut))
assert(signature(hs.settings.get(popupKey))=='ctrl+K','Other clipboard settings migrated a legacy key')
assert(app.savePopup(default));assert(occupied['ctrl+K']==nil and occupied['cmd+shift+V']==app.popupBinding)
assert(signature(hs.settings.get(popupKey))=='cmd+shift+V')

local windows={enabled=true,shortcuts={left=default}}
app=boot(nil,{windows=windows})
assert(not app.popupShortcut and not app.popupBinding and app.popupShortcutError)
assert(occupied['cmd+shift+V']==app.bindings[1] and #app.bindings==1)
assert(hs.settings.get(popupKey)==nil,'A failed default must not persist an off choice')
assert(not app.savePopup(default));assert(occupied['cmd+shift+V']==app.bindings[1])
local launch={enabled=true,rules={{bundleID='com.example.existing',name='Existing',shortcut=default}}}
app=boot(nil,{launcher=launch})
local launcher=require('modules.launcher')
assert(not app.popupShortcut and app.popupShortcutError and #launcher.bindings==1)
assert(occupied['cmd+shift+V']==launcher.bindings[1])
assert(not app.savePopup(default));assert(occupied['cmd+shift+V']==launcher.bindings[1])
for _,extra in ipairs({{systemDefault=true},{external={}},{failDefault=true}}) do
    app=boot(nil,extra)
    assert(not app.popupShortcut and not app.popupBinding and app.popupShortcutError and #alerts>0)
    assert(hs.settings.get(popupKey)==nil)
    if extra.external then assert(occupied['cmd+shift+V']==extra.external) else assert(next(occupied)==nil) end
end
app=boot('invalid')
assert(not app.popupShortcut and app.popupShortcutError and next(occupied)==nil and hs.settings.get(popupKey)=='invalid')


app=boot(false,{systemDefault=true})
local function document(modules)return {format='Nivlet',version=1,modules=modules} end
assert(app.configuration.apply(document({popupShortcut=false})))
assert(hs.settings.get(popupKey)==false and next(occupied)==nil)
assert(app.configuration.apply(document({popupShortcut=legacy})))
assert(occupied['ctrl+K']==app.popupBinding and signature(hs.settings.get(popupKey))=='ctrl+K')
assert(not app.configuration.apply(document({popupShortcut=default})))
assert(occupied['ctrl+K']==app.popupBinding and signature(hs.settings.get(popupKey))=='ctrl+K')

local save=clipboard.save
clipboard.save=function()return false,'Simulated clipboard failure' end
assert(not app.saveClipboardPage(clipboard.config,false))
clipboard.save=save
assert(occupied['ctrl+K']==app.popupBinding and signature(hs.settings.get(popupKey))=='ctrl+K')
print('Popup default-on/off persistence, legacy preservation, startup conflicts, fixed enable, import release and failure recovery passed')


local function copy(v)
    if type(v)~='table' then return v end
    local result={};for k,item in pairs(v) do result[k]=copy(item) end;return result
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local scenarios={
    {name='unset active default'},
    {name='unset default blocked by window',extra={windows=windows}},
    {name='explicit off',value=false},
    {name='legacy raw spelling',value={key='k',mods={'cmd','ctrl'}}},
}
local function untouched(snapshot,reason)
    assert(equal(hs.settings.get(popupKey),snapshot.value),reason..' changed raw popup preference')
    assert(desktopToolkit.popupShortcutError==snapshot.error,reason..' changed original popup error')
    assert(equal(desktopToolkit.popupShortcut,snapshot.shortcut),reason..' changed actual popup combination')
    if snapshot.shortcut then assert(occupied[signature(snapshot.shortcut)]==desktopToolkit.popupBinding,reason..' lost active binding') end
end
for _,scenario in ipairs(scenarios) do
    app=boot(scenario.value,scenario.extra)
    local before={value=copy(hs.settings.get(popupKey)),error=app.popupShortcutError,shortcut=copy(app.popupShortcut)}
    local config=copy(clipboard.config)

    assert(app.saveClipboardPage(config,false,false))
    untouched(before,scenario.name..' unrelated direct save')
    local result=app.saveAllSettings({clipSection={config=config,popupShortcut={key='Z',mods={'ctrl'}},popupShortcutChanged=false}})
    assert(result.ok,result.message)
    untouched(before,scenario.name..' unrelated global save')
    for _,kind in ipairs({'return','throw'}) do
        local originalSave=clipboard.save
        clipboard.save=function()if kind=='throw' then error('Simulated clipboard exception') end;return false,'Simulated clipboard failure' end
        assert(not app.saveClipboardPage(config,false,false))
        clipboard.save=originalSave
        untouched(before,scenario.name..' failed direct save ('..kind..')')
        local calls=0
        clipboard.save=function(value)
            calls=calls+1
            if calls==1 then if kind=='throw' then error('Simulated clipboard exception') end;return false,'Simulated clipboard failure' end
            return originalSave(value)
        end
        result=app.saveAllSettings({clipSection={config=config,popupShortcut=false,popupShortcutChanged=false}})
        clipboard.save=originalSave
        assert(not result.ok and result.recoveryAttempted and not result.recoveryIncomplete)
        untouched(before,scenario.name..' failed global save ('..kind..')')
    end
end

app=boot(nil,{windows=windows})
local failedDefault={value=nil,error=app.popupShortcutError,shortcut=nil}
local originalSave=clipboard.save
clipboard.save=function()return false,'Simulated clipboard failure' end

assert(not app.saveClipboardPage(clipboard.config,false,true))
clipboard.save=originalSave
untouched(failedDefault,'Failed explicit off')
local calls=0
clipboard.save=function(value)
    calls=calls+1;if calls==1 then return false,'Simulated clipboard failure' end
    return originalSave(value)
end
local result=app.saveAllSettings({clipSection={config=copy(clipboard.config),popupShortcut=false,popupShortcutChanged=true}})
clipboard.save=originalSave
assert(not result.ok and not result.recoveryIncomplete)
untouched(failedDefault,'Failed global explicit off')

assert(app.saveClipboardPage(clipboard.config,false,true))
assert(hs.settings.get(popupKey)==false and app.popupShortcutError==nil)

app=boot(nil)
local before={value=nil,error=nil,shortcut=copy(app.popupShortcut)}
result=app.saveAllSettings({windowSection={config=windows},clipSection={config=copy(clipboard.config),popupShortcut=false,popupShortcutChanged=false}})
assert(not result.ok and not result.recoveryAttempted,'Preflight trusted the stale payload instead of the actual unchanged binding')
untouched(before,'Preflight with unchanged popup')
assert(not app.saveClipboardPage(clipboard.config,false,'false'))
result=app.saveAllSettings({clipSection={config=copy(clipboard.config),popupShortcut=false,popupShortcutChanged='false'}})
assert(not result.ok and not result.recoveryAttempted)
untouched(before,'Invalid intent type')



calls=0
clipboard.save=function(value)
    calls=calls+1;if calls==1 then return false,'Simulated import failure' end
    return originalSave(value)
end
app=boot(nil,{windows=windows})
failedDefault={value=nil,error=app.popupShortcutError,shortcut=nil}
local importedClip=copy(clipboard.config);importedClip.images=not importedClip.images
assert(not app.configuration.apply(document({popupShortcut=false,clipboard=importedClip})))
clipboard.save=originalSave
untouched(failedDefault,'Failed import')
assert(app.configuration.apply(document({windows={enabled=false,shortcuts={}}})))
untouched(failedDefault,'Import of another hotkey module')
print('Popup raw nil/false/table and startup diagnostics survive unrelated success, direct/global failure, and import rollback; explicit off alone persists off')
