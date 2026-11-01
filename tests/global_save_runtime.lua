-- Runs real Toolkit/module code solely against the existing in-memory hs mock.
-- Never launches an App, registers an OS hotkey, or reads/writes user settings.
dofile('tests/runtime.lua')
local app=desktopToolkit
local launcher=require('modules.launcher')
local browser=require('modules.browser')
local sleep=require('modules.sleep')
assert(type(app.saveAllSettings)=='function','Global-save internal runtime entry point is required')
local function copy(value)
    if type(value)~='table' then return value end
    local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for key,item in pairs(a) do if not equal(item,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local function general(enabled)
    local config=copy(app.general);config.sleepShortcut=enabled;return config
end
local function window(key,mods)
    return {enabled=key~=nil,shortcuts=key and {left={key=key,mods=mods or {'ctrl'}}} or {}}
end
local function launch(key,mods)
    return {enabled=key~=nil,rules=key and {{bundleID='com.example.probe',name='Probe',shortcut={key=key,mods=mods or {'ctrl'}}}} or {}}
end
local function clearKeys()
    assert(app.saveGeneral(general(false)))
    assert(app.savePopup(nil))
    assert(launcher.save(launch(nil)))
    assert(app.save(window(nil)))
end
clearKeys()

-- Realistic assignability: a key already held by one mock binding cannot be
-- registered a second time. Token-aware deletion avoids deleting a newer owner.
local occupied,operations={},{}
local bindFailure
local function signature(mods,key)return table.concat(mods,'+')..'+'..key end
hs.hotkey.systemAssigned=function()return false end
hs.hotkey.assignable=function(mods,key)return occupied[signature(mods,key)]==nil end
hs.hotkey.bind=function(mods,key,callback)
    local sig=signature(mods,key)
    operations[#operations+1]={'bind',sig}
    if bindFailure==sig then bindFailure=nil;return nil end
    if occupied[sig] then return nil end
    local binding={signature=sig,callback=callback}
    binding.delete=function()
        operations[#operations+1]={'delete',sig}
        if occupied[sig]==binding then occupied[sig]=nil end
    end
    occupied[sig]=binding;return binding
end
local writes={}
local originalSet,originalClear=hs.settings.set,hs.settings.clear
hs.settings.set=function(key,value)
    writes[#writes+1]={key=key,value=copy(value)}
    return originalSet(key,value)
end
hs.settings.clear=function(key)
    writes[#writes+1]={key=key,clear=true}
    return originalClear(key)
end
local windowKey='desktoptoolkit.preferences.v1'
local launcherKey='desktoptoolkit.launcher.v1'
local generalKey='desktoptoolkit.general.v1'
local browserKey='desktoptoolkit.browser.v1'
local function resetLog()writes={};operations={}end
local function onlyWrites(allowed)
    for _,write in ipairs(writes) do
        assert(allowed[write.key],'Global save touched a clean settings module: '..write.key)
    end
end
local function statuses(result)
    local values={};for _,entry in ipairs(result.results or {}) do values[entry.page]=entry.status end;return values
end
local function page(config)return {config=config}end

-- Window + launcher exchange must succeed against actual occupied bindings,
-- without temporary default preference writes to unrelated shortcut owners.
assert(app.save(window('A')))
assert(launcher.save(launch('B')))
resetLog()
local draft={windowSection=page(window('B')),launcherSection=page(launch('A'))}
local originalDraft=copy(draft)
local result=app.saveAllSettings(draft)
assert(result.ok,result.message)
assert(equal(draft,originalDraft),'Runtime save mutated the caller snapshot')
assert(app.config.shortcuts.left.key=='B' and launcher.config.rules[1].shortcut.key=='A')
assert(occupied['ctrl+B']==app.bindings[1] and occupied['ctrl+A']==launcher.bindings[1])
assert(#writes==2,'A two-page exchange should write just its two final page values')
onlyWrites({[windowKey]=true,[launcherKey]=true})
for _,write in ipairs(writes) do assert(write.value.enabled,'No temporary disabled config may be persisted during an exchange') end

-- Move a key from launcher to windows while clearing the former owner.
resetLog()
result=app.saveAllSettings({windowSection=page(window('A')),launcherSection=page(launch(nil))})
assert(result.ok,result.message)
assert(occupied['ctrl+A']==app.bindings[1] and not occupied['ctrl+B'] and #launcher.bindings==0)
assert(#writes==2);onlyWrites({[windowKey]=true,[launcherKey]=true})

-- Full preflight must reject an unavailable browser before even releasing or
-- saving the otherwise valid dirty window page.
local originalPath=hs.application.pathForBundleID
hs.application.pathForBundleID=function(id)if id=='com.google.Chrome' then return nil end;return originalPath(id)end
local beforeWindow=copy(app.config)
local browserDraft=browser.defaults();browserDraft.defaultBrowser='com.google.Chrome'
resetLog()
result=app.saveAllSettings({windowSection=page(window('C')),browserSection=page(browserDraft)})
assert(not result.ok and result.failedPage=='browserSection')
assert(#writes==0 and #operations==0,'Preflight failure changed runtime or persisted settings')
assert(equal(app.config,beforeWindow) and occupied['ctrl+A']==app.bindings[1])
hs.application.pathForBundleID=originalPath

-- A final conflicting assignment also fails without unbinding clean owners.
resetLog()
assert(launcher.save(launch('B')))
resetLog()
result=app.saveAllSettings({windowSection=page(window('B'))})
assert(not result.ok and #writes==0 and #operations==0)
assert(occupied['ctrl+A']==app.bindings[1] and occupied['ctrl+B']==launcher.bindings[1])

-- Registration can fail after preflight. The group's earlier window save must
-- be recovered together with the launcher state, not advertised as committed.
resetLog();bindFailure='ctrl+C'
local priorWindow,priorLauncher=copy(app.config),copy(launcher.config)
result=app.saveAllSettings({windowSection=page(window('B')),launcherSection=page(launch('C')),browserSection=page(browserDraft)})
local state=statuses(result)
assert(not result.ok and result.failedPage=='launcherSection' and result.recoveryAttempted)
assert(not result.recoveryIncomplete,'Old available bindings should recover in this mock')
assert(state.windowSection=='failed' and state.launcherSection=='failed' and state.browserSection=='pending')
assert(equal(app.config,priorWindow) and equal(launcher.config,priorLauncher))
assert(occupied['ctrl+A']==app.bindings[1] and occupied['ctrl+B']==launcher.bindings[1] and not occupied['ctrl+C'])
assert(equal(hs.settings.get(windowKey),priorWindow) and equal(hs.settings.get(launcherKey),priorLauncher))
onlyWrites({[windowKey]=true,[launcherKey]=true})

-- The conflict context must be cleared even after group recovery.
assert(not app.savePopup({key='A',mods={'ctrl'}}))

-- After a successful key group, an independent runtime failure preserves the
-- truthful partial result; no hidden all-or-nothing promise is introduced.
local originalBrowserSave=browser.save
local priorBrowser=copy(browser.config)
browser.save=function()return false,'Injected browser runtime failure'end
resetLog()
result=app.saveAllSettings({windowSection=page(window('D')),browserSection=page(browserDraft)})
state=statuses(result)
assert(not result.ok and result.failedPage=='browserSection')
assert(state.windowSection=='saved' and state.browserSection=='failed')
assert(occupied['ctrl+D']==app.bindings[1] and not occupied['ctrl+A'])
assert(app.config.shortcuts.left.key=='D' and equal(browser.config,priorBrowser))
assert(#writes==1);onlyWrites({[windowKey]=true})
browser.save=originalBrowserSave

-- Transfer Command-L from windows to General sleep, including the login flag,
-- then back. No real sleep callback is invoked.
clearKeys()
local login=false
local loginWrites={}
hs.autoLaunch=function(value)
    if value~=nil then login=value;loginWrites[#loginWrites+1]=value end
    return login
end
assert(app.save(window('L',{'cmd'})))
resetLog()
result=app.saveAllSettings({windowSection=page(window(nil)),generalSection={config=general(true),autoLaunch=true}})
assert(result.ok,result.message)
assert(login and #loginWrites==1 and loginWrites[1]==true)
assert(sleep.enabled and occupied['cmd+L']==sleep.binding and #app.bindings==0)
assert(app.general.sleepShortcut and hs.settings.get(generalKey).sleepShortcut)
assert(#writes==2);onlyWrites({[windowKey]=true,[generalKey]=true})
resetLog()
result=app.saveAllSettings({windowSection=page(window('L',{'cmd'})),generalSection={config=general(false),autoLaunch=false}})
assert(result.ok,result.message)
assert(not login and not sleep.enabled and occupied['cmd+L']==app.bindings[1])
assert(not app.general.sleepShortcut and not hs.settings.get(generalKey).sleepShortcut)
assert(#writes==2);onlyWrites({[windowKey]=true,[generalKey]=true})

-- A failed login change is a selected-page failure and recovers the group's
-- previous key owner; no other preference domain is written as a workaround.
local priorGeneral,priorWindow=copy(app.general),copy(app.config)
hs.autoLaunch=function()return false end
resetLog()
result=app.saveAllSettings({windowSection=page(window(nil)),generalSection={config=general(true),autoLaunch=true}})
state=statuses(result)
assert(not result.ok and result.failedPage=='generalSection')
assert(state.windowSection=='failed' and state.generalSection=='failed')
assert(equal(app.general,priorGeneral) and equal(app.config,priorWindow))
assert(not sleep.enabled and occupied['cmd+L']==app.bindings[1])
onlyWrites({[windowKey]=true,[generalKey]=true})

-- The combined clipboard page must transfer the popup key with the same final
-- candidate as windows. Default disabled/nonpersistent configuration plus empty
-- mock history exercises the real save path without any filesystem operation.
clearKeys()
local clip=require('modules.clipboard')
assert(#clip.entries==0 and not clip.config.enabled and not clip.config.persistent)
assert(app.save(window('M')))
local clipSettingsKey='desktoptoolkit.clipboard.v1'
local popupSettingsKey='desktoptoolkit.clipboard.shortcut.v1'
local historySettingsKey='desktoptoolkit.clipboard.history.v1'
resetLog()
result=app.saveAllSettings({windowSection=page(window(nil)),clipSection={config=copy(clip.config),popupShortcut={key='M',mods={'ctrl'}}}})
assert(result.ok,result.message)
assert(app.popupShortcut.key=='M' and occupied['ctrl+M']==app.popupBinding and #app.bindings==0)
onlyWrites({[windowKey]=true,[clipSettingsKey]=true,[popupSettingsKey]=true,[historySettingsKey]=true})
resetLog()
result=app.saveAllSettings({windowSection=page(window('M')),clipSection={config=copy(clip.config),popupShortcut=false}})
assert(result.ok,result.message)
assert(app.popupShortcut==nil and app.popupBinding==nil and occupied['ctrl+M']==app.bindings[1])
assert(hs.settings.get(popupSettingsKey)==nil)
onlyWrites({[windowKey]=true,[clipSettingsKey]=true,[popupSettingsKey]=true,[historySettingsKey]=true})

-- Exercise the real system module's write-before-menu-update path. The runtime
-- fixture's captured module table is a stub, so forward its dynamic adapter to
-- the real module and synchronize config even when its save raises. Drawing is
-- an in-memory boundary; neither test creates an AppKit menu.
local system=require('modules.sys_info')
local realSystem=dofile('Toolkit/modules/sys_info.lua')
local systemKey='desktoptoolkit.system.v1'
local drawCalls=0
realSystem.draw=function()drawCalls=drawCalls+1 end
system.validate=realSystem.validate
system.config=realSystem.config
system.save=function(value)
    local ran,saved,message=pcall(realSystem.save,value)
    system.config=realSystem.config
    if not ran then error(saved,0) end
    return saved,message
end
local priorSystem=copy(realSystem.config)
local systemDraft=copy(priorSystem);systemDraft.cpu=false
hs.settings.set(systemKey,copy(priorSystem))
local menuCalls=0
realSystem.menu={setMenu=function(self)
    menuCalls=menuCalls+1
    if menuCalls==1 then error('Injected one-time setMenu failure') end
    return self
end}
resetLog()
result=app.saveAllSettings({systemSection=page(systemDraft)})
local failedSystem=result.results[1]
assert(not result.ok and result.failedPage=='systemSection' and result.recoveryAttempted)
assert(not result.recoveryIncomplete,'One-time menu failure should recover the previous settings and menu')
assert(failedSystem.page=='systemSection' and failedSystem.status=='failed' and failedSystem.attempted)
assert(equal(realSystem.config,priorSystem) and equal(system.config,priorSystem))
assert(equal(hs.settings.get(systemKey),priorSystem) and equal(failedSystem.current.config,priorSystem))
assert(#writes==2 and equal(writes[1].value,systemDraft) and equal(writes[2].value,priorSystem))
assert(menuCalls==3 and drawCalls==1,'Restoration must rebuild the menu and redraw after the failed update')
onlyWrites({[systemKey]=true})

-- With a persistent menu exception, persistence can already have returned to
-- the prior value while runtime recovery remains incomplete. Report both facts
-- truthfully instead of treating a restored settings value as full recovery.
menuCalls=0;drawCalls=0
realSystem.menu.setMenu=function()
    menuCalls=menuCalls+1
    error('Injected persistent setMenu failure')
end
resetLog()
result=app.saveAllSettings({systemSection=page(systemDraft)})
failedSystem=result.results[1]
assert(not result.ok and result.failedPage=='systemSection' and result.recoveryAttempted and result.recoveryIncomplete)
assert(failedSystem.status=='failed' and failedSystem.attempted and type(failedSystem.message)=='string' and #failedSystem.message>0)
assert(equal(realSystem.config,priorSystem) and equal(system.config,priorSystem))
assert(equal(hs.settings.get(systemKey),priorSystem) and equal(failedSystem.current.config,priorSystem))
assert(#writes==2 and equal(writes[1].value,systemDraft) and equal(writes[2].value,priorSystem))
assert(menuCalls==2 and drawCalls==0,'Failed restoration must not claim the menu redraw completed')
onlyWrites({[systemKey]=true})
failedSystem.current.config.cpu=false
assert(realSystem.config.cpu and hs.settings.get(systemKey).cpu,'Failure snapshots must not alias actual configuration')

print('Global save actual runtime: shortcut swap/transfer including Clipboard, final-candidate preflight, selected-only persistence, group recovery, partial save, General login/sleep and system menu exception recovery passed')
