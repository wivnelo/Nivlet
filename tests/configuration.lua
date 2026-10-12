package.path="Toolkit/?.lua;"..package.path
local configuration=require("modules.configuration")
local preferences=require("modules.preferences")
local function clone(v) if type(v)~="table" then return v end;local r={};for k,x in pairs(v) do r[k]=clone(x) end;return r end
local defaults={general={showMenu=true,appearance="system",language="system"},windows=preferences.defaults(),input={enabled=false,rules={}},clipboard=require("modules.clipboard").defaults(),popupShortcut=false,system=require("modules.sys_info").defaults(),browser=require("modules.browser").defaults(),launcher={enabled=false,rules={}}}
local validators={windows=preferences.validate,input=require("modules.input_method").validate,clipboard=require("modules.clipboard").validate,system=require("modules.sys_info").validate,browser=require("modules.browser").validate,launcher=require("modules.launcher").validate,
 general=function(v) if type(v.showMenu)~="boolean" or not ({system=true,light=true,dark=true})[v.appearance] or not ({system=true,en=true,["zh-Hans"]=true})[v.language] then return nil,"Invalid general" end;return clone(v) end,
 popupShortcut=function(v) if v==false then return false end;local c,e=preferences.validate({enabled=false,shortcuts={left=v}});if not c then return nil,e end;return c.shortcuts.left or false end}
local state,stored,adapters=clone(defaults),{},{}
local fail,history,available,ax,systemKey=false,false,true,true,nil
local saves=0
for _,name in ipairs(configuration.names) do
 adapters[name]={get=function() return state[name] end,defaults=function() return clone(defaults[name]) end,validate=validators[name],save=function(v)
  saves=saves+1;state[name]=clone(v);stored[name]=clone(v)
  if fail==name then fail=false;return false,"Injected save failure" end
  return true
 end}
end
local manager=configuration.new(adapters,{capture=function() return clone(stored) end,restore=function(v) stored=clone(v) end,systemAssigned=function(item) return item.key==systemKey end,accessibility=function() return ax end,hasHistory=function() return history end,available=function() return available,"Unavailable target" end})
local function doc(modules) return {format="Nivlet",version=1,modules=modules} end
local exported=manager.export();assert(exported.modules.popupShortcut==false and exported.modules.clipboard.minutes==30)
exported.modules.clipboard.minutes=1;assert(state.clipboard.minutes==30)
assert(manager.prepare(manager.export(true)))
for _,bad in ipairs({{format="Other",version=1,modules={}}, {format="Nivlet",version=2,modules={}},doc({}),doc({unknown={}}),doc({general={showMenu=true,appearance="system",language=false}}),doc({launcher={enabled=false,rules={{bundleID="com.example.app",name=false}}}}),doc({windows={enabled=false,shortcuts={other={}}}}),doc({input={enabled=false,rules={bad={}}}}),doc({launcher={enabled=false,rules={{bundleID="com.example.app",shortcut={key="A",mods={bad="cmd"}}}}}})}) do assert(not manager.prepare(bad)) end
assert(not manager.prepare(doc({clipboard={enabled=true,limit=1,minutes=30,excluded={}}})))
local key={key="left",mods={"ctrl"}}
state.windows={enabled=false,shortcuts={left=key}}
assert(not manager.prepare(doc({popupShortcut=key})))
assert(not manager.prepare(doc({launcher={enabled=false,rules={{bundleID="com.example.app",shortcut=key}}}})))
state.windows=clone(defaults.windows)
systemKey="left";assert(not manager.prepare(doc({popupShortcut=key})));systemKey=nil
available=false;assert(not manager.prepare(doc({general=defaults.general})));available=true
ax=false;assert(not manager.prepare(doc({windows={enabled=true,shortcuts={left=key}}})));ax=true
history=true;state.clipboard.enabled=true
assert(manager.prepare(doc({clipboard=defaults.clipboard})))
assert(manager.prepare(doc({clipboard=state.clipboard})));history=false
state=clone(defaults);stored={}
local ok,message,selected=manager.apply(doc({general={showMenu=false,appearance="dark",language="en"}}))
assert(ok and selected.general and not selected.windows and state.general.appearance=="dark" and state.clipboard.minutes==30 and saves==1)
local original=clone(state)
fail="browser"
assert(not manager.apply(doc({general=defaults.general,browser=defaults.browser,windows={enabled=false,shortcuts={left=key}},popupShortcut=false})))
assert(state.general.appearance==original.general.appearance and not state.windows.enabled and next(state.windows.shortcuts)==nil)
assert(stored.windows==nil and stored.browser==nil and stored.general.appearance=="dark")
assert(manager.apply(doc({windows={enabled=false,shortcuts={left=key}},popupShortcut=false,launcher={enabled=false,rules={}}})))
assert(state.windows.shortcuts.left.key=="left")
local roundtrip=manager.export();assert(manager.apply(roundtrip));assert(state.windows.shortcuts.left.key=="left")
print("Configuration defaults, strict schema, partial imports, target/permission/conflict checks, rollback and round-trip passed")

state=clone(defaults)
assert(manager.prepare(doc({windows={enabled=false,shortcuts={grid9={key="up",mods={"ctrl"}}}}})))
state.launcher={enabled=false,rules={{bundleID="com.example.app",shortcut={key="up",mods={"ctrl"}}}}}
assert(not manager.prepare(doc({windows={enabled=false,shortcuts={grid9={key="up",mods={"ctrl"}}}}})))
assert(not manager.prepare(doc({windows={enabled=false,shortcuts={grid10={key="up",mods={"ctrl"}}}}})))
print("Import accepts new window actions and detects cross-module conflicts and unknown layouts")

state=clone(defaults);state.popupShortcut={key="K",mods={"ctrl"}}
assert(manager.export().modules.popupShortcut.key=="K")
assert(manager.export(true).modules.popupShortcut==false,"Default example leaked a saved popup shortcut")
print("Default export preserves false instead of falling back to a saved personal shortcut")

state=clone(defaults);state.clipboard.enabled=true;history=true
local function retention(minutes) local config=clone(state.clipboard);config.minutes=minutes;return doc({clipboard=config}) end
assert(manager.prepare(retention(0)), 'Finite to forever must not clear history')
assert(manager.prepare(retention(1440)), 'Extending retention must preserve history')
state.clipboard.minutes=0
assert(not manager.prepare(retention(1440)), 'Forever to finite can expire history and needs explicit handling')
assert(manager.prepare(retention(0)))
history=false
assert(manager.apply(retention(0)));assert(manager.export().modules.clipboard.minutes==0)
assert(manager.apply(retention(1440)));assert(manager.export().modules.clipboard.minutes==1440)
print('JSON retention protects history when leaving permanent mode and round-trips both modes')
