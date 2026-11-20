package.path='Toolkit/?.lua;'..package.path
local stored,bindings,tasks,alerts={},{},{},{}
local blocked=false
local function signature(mods,key) return table.concat(mods,'+')..'+'..key end
local function newTask(path,exit,stream)
    local t={path=path,exit=exit,stream=stream,running=false,input={},closed=false}
    function t:start() self.running=true;return self end
    function t:isRunning() return self.running end
    function t:setInput(s) table.insert(self.input,s) end
    function t:closeInput() self.closed=true;self.running=false end
    table.insert(tasks,t)
    return t
end
hs={settings={get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end},
 processInfo={bundlePath='/Applications/Nivlet.app'},
 fs={attributes=function(path) return path:match('capture%-helper$') and {mode='file'} or nil end},
 task={new=newTask},
 json={encode=function(v) local parts={} for k,x in pairs(v) do if type(x)~='table' then parts[#parts+1]=k..'='..tostring(x) end end;table.sort(parts);return table.concat(parts,',') end,
       decode=function(s) local t={};for k,v in s:gmatch('"(%w+)":"?([^",}]*)"?') do t[k]=v=='true' and true or v=='false' and false or v end;return t end},
 alert={show=function(m) table.insert(alerts,m);return #alerts end,closeSpecific=function() end},
 screenRecordingState=function() return true end,
 hotkey={systemAssigned=function(_,key) return blocked and key=='f2' end,assignable=function(mods,key) return not bindings[signature(mods,key)] end,
  bind=function(mods,key,fn) local sig=signature(mods,key);bindings[sig]=fn;return {delete=function() bindings[sig]=nil end} end}}

local capture=require('modules.capture')
local defaults=capture.defaults()
assert(defaults.enabled==false and defaults.shortcut.key=='F1' and #defaults.shortcut.mods==0, 'Default shortcut is plain F1 and the module starts off')

-- Function keys may be bound without modifiers; letters still need Control, Option or Command.
assert(capture.normalizeShortcut({key='f3',mods={}}).key=='F3')
assert(select(2,capture.normalizeShortcut({key='A',mods={}})), 'Plain letters stay rejected')
assert(capture.normalizeShortcut({key='A',mods={'shift','ctrl'}}).mods[1]=='ctrl')
assert(capture.normalizeShortcut({key='F13',mods={}}).key=='F13', 'F13 (PrintScreen on PC keyboards) binds without modifiers')
assert(not capture.normalizeShortcut({key='F20',mods={}}) and select(2,capture.normalizeShortcut({key='F20',mods={}})), 'Only F1–F19 are accepted')
assert(select(2,capture.normalizeShortcut({key='F1',mods={'hyper'}})))

local function config(overrides)
    local c=capture.defaults()
    for k,v in pairs(overrides or {}) do c[k]=v end
    return c
end
assert(not capture.validate(config({format='gif'})))
assert(not capture.validate(config({saveDirectory='relative/path'})))
assert(not capture.validate(config({saveDirectory=''})))
assert(capture.validate(config({saveDirectory='/Volumes/Shots'})))
assert(capture.validate(config({shortcut=false})).shortcut==false)

local external=false
capture.start(function(shortcut) return external and shortcut.key=='F2' end,{})
assert(next(bindings)==nil and #tasks==0, 'Disabled module binds nothing and starts no helper')

assert(capture.save(config({enabled=true})))
assert(bindings['+f1'], 'F1 is bound in lowercase without modifiers')
assert(#tasks==1 and tasks[1].running and tasks[1].path:match('Toolkit/capture%-helper$'))
assert(capture.conflicts({key='F1',mods={}}) and not capture.conflicts({key='F2',mods={}}))

-- Pressing before the helper reports ready queues one capture until it does.
bindings['+f1']()
assert(#tasks[1].input==0)
tasks[1].stream(nil,'{"event":"ready","permission":true}\n')
assert(#tasks[1].input==2 and tasks[1].input[1]:match('cmd=config') and tasks[1].input[2]:match('cmd=capture'))
bindings['+f1']()
assert(tasks[1].input[3]:match('cmd=config') and tasks[1].input[4]:match('cmd=capture'), 'Each press refreshes config (appearance) before capturing')

-- Split lines are buffered; copy events reach the clipboard callback.
local copied=0
capture.onCopied=function() copied=copied+1 end
tasks[1].stream(nil,'{"event":"cop')
assert(copied==0)
tasks[1].stream(nil,'ied","width":"10"}\n')
assert(copied==1)
tasks[1].stream(nil,'{"event":"saved","path":"/Volumes/Shots/Nivlet 1.png"}\n')
assert(alerts[#alerts]:find('Nivlet 1.png',1,true))

local alertCount,logged,originalPrint=#alerts,{},print
print=function(...) logged[#logged+1]=table.concat({...},' ') end
tasks[1].stream(nil,'{"event":"recognitionError","detail":"VNError 9"}\n')
print=originalPrint
assert(#alerts==alertCount and logged[1] and logged[1]:find('VNError 9',1,true), 'Recognition errors are logged without alerting the user')

-- Conflicts reject the save and keep the working binding.
external=true
local ok,message=capture.save(config({enabled=true,shortcut={key='F2',mods={}}}))
assert(not ok and message and bindings['+f1'] and not bindings['+f2'])
external=false
blocked=true
assert(not capture.save(config({enabled=true,shortcut={key='F2',mods={}}})) and bindings['+f1'])
blocked=false

-- Turning the module off unbinds the key and asks the helper to quit.
assert(capture.save(config({enabled=false})))
assert(next(bindings)==nil and tasks[1].closed and tasks[1].input[#tasks[1].input]:match('cmd=quit'))
assert(stored['desktoptoolkit.capture.v1'].enabled==false)
-- Permission comes from the helper's system check, never from hs.screenRecordingState's guess.
hs.screenRecordingState=function() error('heuristic must not be used for the status') end
assert(capture.permissionGranted()==true, 'Ready event recorded the helper answer')
capture.permission=nil
assert(capture.permissionGranted()==nil, 'Unknown until checked')
local answered
capture.checkPermission(function(value) answered=value end)
local probe=tasks[#tasks]
assert(probe.stream[1]=='--permission' and probe.running)
probe.exit(0,'denied\n','')
assert(answered==false and capture.permissionGranted()==false)
capture.checkPermission(function(value) answered=value end)
tasks[#tasks].exit(0,'granted\n','')
assert(answered==true and capture.permissionGranted()==true)
-- Overlapping checks share one answer; every caller is called back once.
local calls=0
capture.checkPermission(function() calls=calls+1 end)
capture.checkPermission(function() calls=calls+1 end)
local before=#tasks
tasks[#tasks].exit(0,'granted\n','')
assert(calls==2 and #tasks==before, 'Two overlapping checks run one process and answer both')
-- A running helper answers without starting a process; "granted" is trusted directly.
assert(capture.startHelper())
local helperTask=tasks[#tasks]
helperTask.stream(nil,'{"event":"ready","permission":true}\n')
local count=#tasks;local result
capture.checkPermission(function(v) result=v end)
assert(#tasks==count and helperTask.input[#helperTask.input]:match('cmd=permissionStatus'), 'Asks the running helper')
helperTask.stream(nil,'{"event":"permissionStatus","granted":"true"}\n')
assert(result==true and #tasks==count, 'Granted from the helper needs no new process')
-- "denied" from the helper is confirmed by a fresh process.
capture.checkPermission(function(v) result=v end)
helperTask.stream(nil,'{"event":"permissionStatus","granted":"false"}\n')
assert(#tasks==count+1 and tasks[#tasks].stream[1]=='--permission', 'Denied is re-checked in a fresh process')
tasks[#tasks].exit(0,'denied\n','')
assert(result==false)
capture.stopHelper()
print('capture module: F-key validation, binding, helper lifecycle and events')
