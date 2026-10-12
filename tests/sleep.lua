package.path="Toolkit/?.lua;"..package.path
local callback,deleted,asleep,assigned,bindFails=nil,false,false,false,false
hs={hotkey={systemAssigned=function() return assigned end,assignable=function() return true end,bind=function(mods,key,fn) assert(mods[1]=="cmd" and key=="L");if bindFails then return nil end;callback=fn;return {delete=function() deleted=true end} end},caffeinate={systemSleep=function() asleep=true end}}
local s=require("modules.sleep")
assert(not s.enabled and not s.conflicts({key="L",mods={"cmd"}}))
assert(s.configure(true) and callback and not asleep)
assert(s.conflicts({key="L",mods={"cmd"}}) and not s.conflicts({key="L",mods={"cmd","shift"}}))
callback();assert(asleep) -- Mock only: this test never sleeps the machine.
assert(s.configure(false) and deleted and not s.enabled)
assigned=true;assert(not s.configure(true) and not s.enabled)
assigned=false;bindFails=true;assert(not s.configure(true) and not s.enabled)
print("Optional sleep binding, no execution on enable, exact modifier conflict, removal and registration failures passed")
