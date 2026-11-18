-- Network sampling stops while the screen is locked or asleep and resumes afterwards.
package.path='Toolkit/?.lua;'..package.path
local timers,scans,watcherFn=0,0,nil
local events={screensDidLock=1,screensDidUnlock=2,screensDidSleep=3,screensDidWake=4,systemWillSleep=5,systemDidWake=6}
local function menu() return setmetatable({},{__index=function() return function(self) return self end end}) end
hs={settings={get=function() return nil end,set=function() end},host={cpuUsageTicks=function() return nil end},
 menubar={new=menu},canvas={new=function() return {appendElements=function() end,minimumTextSize=function() return {w=10} end,size=function() end,elementAttribute=function() end,imageFromCanvas=function() return {} end,delete=function() end} end},
 network={primaryInterfaces=function() return 'en0' end},processInfo={bundlePath='/x'},
 task={new=function() scans=scans+1;return {start=function() end,isRunning=function() return false end} end},
 timer={doEvery=function() timers=timers+1;local t={running=true};t.stop=function() t.running=false end;return t end,secondsSinceEpoch=function() return 0 end},
 caffeinate={watcher=setmetatable({new=function(fn) watcherFn=fn;return {start=function() end} end},{__index=events})}}
local sys=require('modules.sys_info')
sys.start(function() end)
assert(sys.timer and sys.timer.running and watcherFn,'Sampling and the power watcher start')
local timer=sys.timer
watcherFn(events.screensDidLock)
assert(sys.paused and not timer.running and sys.timer==nil,'Lock stops sampling')
local before=scans
watcherFn(events.screensDidWake)
assert(sys.paused and scans==before,'Waking the display while locked keeps it paused')
watcherFn(events.screensDidUnlock)
assert(not sys.paused and sys.timer and sys.timer.running and scans==before+1,'Unlock resumes with an immediate sample')
watcherFn(events.screensDidSleep);assert(sys.paused)
watcherFn(events.screensDidWake);assert(not sys.paused and sys.timer.running,'Display wake (unlocked) resumes')
print('system info: sampling pauses while locked or asleep')
