package.path='Toolkit/?.lua;'..package.path
local stored,bindings,blocked,fail,launched,alert={}, {},false,false,nil,nil
local notices,closed,running={}, {},false
local function signature(mods,key) return table.concat(mods,'+')..'+'..key end
hs={settings={get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end},alert={show=function(message,style,duration) alert=message;table.insert(notices,{message=message,beforeLaunch=launched,style=style,duration=duration});return #notices end,closeSpecific=function(id,duration) table.insert(closed,id);assert(duration==0) end},
application={applicationsForBundleID=function() return running and {{}} or {} end,pathForBundleID=function(id) return id~='com.example.missing' and '/Applications/Probe.app' or nil end,launchOrFocusByBundleID=function(id) launched=id;return id~='com.example.failed' end},
hotkey={systemAssigned=function(_,key) return blocked and key=='9' end,assignable=function(mods,key) return not bindings[signature(mods,key)] end,
bind=function(mods,key,callback) if fail and key=='8' then return nil end;local sig=signature(mods,key);bindings[sig]=callback;return {delete=function() bindings[sig]=nil end} end}}
local m=require('modules.launcher')
local external=false
m.start(function(shortcut) return external and shortcut and shortcut.key=='K' end)
assert(not m.config.enabled and next(bindings)==nil)
local function config(key,id,enabled) return {enabled=enabled~=false,rules={{bundleID=id or 'com.example.probe',name='Probe',shortcut={key=key,mods={'cmd','ctrl'}}}}} end
assert(m.save(config('k')));assert(bindings['ctrl+cmd+K'])
bindings['ctrl+cmd+K']();assert(launched=='com.example.probe')
assert(alert=='⌃⌘K · 正在启动：Probe' and notices[1].beforeLaunch==nil)
assert(notices[1].duration==1.5 and notices[1].style.textSize==18)
running=true;bindings['ctrl+cmd+K']();assert(alert=='⌃⌘K · 正在切换到：Probe' and #closed==1);running=false
local i18n=require('modules.i18n');i18n.configure('en');bindings['ctrl+cmd+K']();assert(alert=='⌃⌘K · Starting: Probe');i18n.configure('zh-Hans')
assert(m.conflicts({key='K',mods={'ctrl','cmd'}}))
assert(not m.conflicts({key='J',mods={'ctrl','cmd'}}))
assert(m.save(config('K')),'Saving existing binding should succeed')
external=true;assert(not m.save(config('K')));assert(bindings['ctrl+cmd+K']);external=false
blocked=true;assert(not m.save(config('9')));assert(bindings['ctrl+cmd+K']);blocked=false
fail=true;assert(not m.save(config('8','com.example.replacement')));assert(bindings['ctrl+cmd+K']);assert(m.config.rules[1].bundleID=='com.example.probe');fail=false
assert(stored['desktoptoolkit.launcher.v1'].rules[1].shortcut.key=='K')
local duplicate=config('J');duplicate.rules[2]={bundleID='com.example.other',shortcut={key='j',mods={'ctrl','cmd'}}};assert(not m.save(duplicate))
duplicate.rules[2].shortcut.key='L';duplicate.rules[2].bundleID='com.example.probe';assert(not m.save(duplicate))
assert(not m.save({enabled=true,rules={{bundleID='invalid',shortcut={key='K',mods={'ctrl'}}}}}))
assert(m.save(config('','com.example.probe')) and next(bindings)==nil)
assert(m.save(config('J','com.example.probe',false)) and next(bindings)==nil)
assert(m.save(config('K','com.example.probe')))
-- Simulate a fresh process with persisted config.
bindings={};m.bindings={};m.start(function() return false end);assert(bindings['ctrl+cmd+K'])
assert(m.save(config('K','com.example.missing')));bindings['ctrl+cmd+K']();assert(alert:find('应用不可用',1,true))
assert(not m.open('com.example.failed'))
assert(m.save(config('left','com.example.failed')));bindings['ctrl+cmd+left']();assert(alert:find('⌃⌘← · 无法启动应用：',1,true))
assert(#closed==#notices-1,'Launcher feedback should replace only the previous launcher alert')
assert(m.save({enabled=false,rules={}}) and next(bindings)==nil)
print('App launch dispatch, validation, conflicts, registration rollback, unbind, disable and restart restoration passed')

local caseDuplicate=config('J');caseDuplicate.rules[2]={bundleID='COM.EXAMPLE.PROBE',shortcut={key='L',mods={'ctrl','cmd'}}};assert(not m.validate(caseDuplicate))
