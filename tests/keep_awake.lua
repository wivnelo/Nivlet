dofile('tests/runtime.lua')
local app=desktopToolkit
local power=require('modules.keep_awake')
local function copy(t)local out={};for k,v in pairs(t) do out[k]=v end;return out end
local state={awake=false,display=false};local calls=0;local fail=false;local stopCalls=0
hs.caffeinate.nivletKeepAwake=function(awake,display)
 calls=calls+1
 if fail then fail=false;return false,true,state.awake,state.display end
 state.awake=awake;state.display=awake and display
 return true,true,state.awake,state.display
end
hs.caffeinate.nivletStopKeepAwake=function()stopCalls=stopCalls+1;state.awake=false;state.display=false;return true end
local function general(a,d)local g=copy(app.general);g.sleepShortcut=false;g.keepAwake=a;g.keepDisplayOn=d;return g end
local defaults=app.configuration.export(true).modules.general
assert(defaults.keepAwake==false and defaults.keepDisplayOn==false)
assert(app.saveGeneral({showMenu=true,appearance='system'}))
assert(app.general.keepAwake==false and app.general.keepDisplayOn==false and calls==0)
assert(not app.saveGeneral(general('true',false)))
assert(not app.saveGeneral(general(false,1)))
assert(app.saveGeneral(general(false,true)))
assert(not app.general.keepDisplayOn and calls==0)
assert(app.saveGeneral(general(true,false)))
assert(state.awake and not state.display)
assert(app.saveGeneral(general(true,true)))
assert(state.awake and state.display)
assert(app.setShowMenu(false));assert(state.awake and state.display)
local exported=app.configuration.export()
assert(exported.modules.general.keepAwake and exported.modules.general.keepDisplayOn)
assert(app.configuration.prepare({format='Nivlet',version=1,modules={general=exported.modules.general}}))
assert(app.saveGeneral(general(false,false)))
assert(app.configuration.apply({format='Nivlet',version=1,modules={general=exported.modules.general}}))
assert(state.awake and state.display)
assert(app.saveGeneral(general(false,false)))
local old=app.general;local persisted=hs.settings.get('desktoptoolkit.general.v1')
fail=true
local login=hs.autoLaunch()
assert(not app.saveGeneralPage(general(true,true),not login))
assert(hs.autoLaunch()==login and app.general==old and not state.awake and not state.display)
assert(hs.settings.get('desktoptoolkit.general.v1')==persisted)
local set=hs.settings.set;local failWrite=true
hs.settings.set=function(key,value)
 if key=='desktoptoolkit.general.v1' and failWrite then failWrite=false;error('Injected persistence failure') end
 return set(key,value)
end
assert(not app.saveGeneral(general(true,true)))
assert(app.general==old and not state.awake and not state.display)
assert(hs.settings.get('desktoptoolkit.general.v1')==persisted)
hs.settings.set=set
local appearance=hs.nivletAppearance;local failAppearance=true
hs.nivletAppearance=function(value)if failAppearance then failAppearance=false;error('Injected metadata failure') end;return appearance(value)end
assert(not app.saveGeneral(general(true,true)))
assert(app.general==old and not state.awake and not state.display)
hs.nivletAppearance=appearance
local result=app.saveAllSettings({generalSection={config=general(true,true),autoLaunch=login}})
assert(result.ok and state.awake and state.display)
result=app.saveAllSettings({generalSection={config=general(true,true),autoLaunch=login}})
assert(result.ok and state.awake and state.display)
fail=true
result=app.saveAllSettings({generalSection={config=general(false,false),autoLaunch=login}})
assert(not result.ok and app.general.keepAwake and state.awake and state.display)
hs.shutdownCallback();assert(stopCalls==1 and not state.awake and not state.display)
hs.shutdownCallback();assert(stopCalls==1)
assert(app.general.keepAwake and hs.settings.get('desktoptoolkit.general.v1').keepAwake,'Quit releases runtime power without erasing saved preference')
print('Keep-awake defaults, dependency, legacy migration, export/import, menu preservation, login/metadata/persistence rollback, global save, repeated save and shutdown passed (mock bridge only)')

-- A failed native rollback must be visible and remain switchable off.
local bridge=hs.caffeinate.nivletKeepAwake
assert(app.saveGeneral(general(false,false)))
local savedOff=hs.settings.get('desktoptoolkit.general.v1')
hs.caffeinate.nivletKeepAwake=function()state.awake=true;state.display=false;return false,false,true,false end
assert(not app.saveGeneral(general(true,true)))
assert(app.general.keepAwake and not app.general.keepDisplayOn and power.awake)
assert(hs.settings.get('desktoptoolkit.general.v1')==savedOff and not savedOff.keepAwake)
hs.caffeinate.nivletKeepAwake=bridge
assert(app.saveGeneral(general(false,false)));assert(not state.awake)
-- Persistence fails after enabling power; releasing power during recovery fails too.
savedOff=hs.settings.get('desktoptoolkit.general.v1')
local writeFails=true
hs.settings.set=function(key,value)
 if key=='desktoptoolkit.general.v1' and writeFails then writeFails=false;error('Injected disk failure') end
 return set(key,value)
end
hs.caffeinate.nivletKeepAwake=function(a,d)
 if not a then return false,false,state.awake,state.display end
 return bridge(a,d)
end
assert(not app.saveGeneral(general(true,true)))
assert(app.general.keepAwake and app.general.keepDisplayOn and power.awake and power.display)
assert(hs.settings.get('desktoptoolkit.general.v1')==savedOff and not savedOff.keepAwake)
hs.settings.set=set;hs.caffeinate.nivletKeepAwake=bridge
assert(app.saveGeneral(general(false,false)));assert(not state.awake and not state.display)
print('Failed native rollback and failed persistence+power recovery expose actual runtime state, preserve saved value, and permit off retry')
