local file=assert(io.open("Toolkit/init.lua"));local source=file:read("*a");file:close()
local helper=assert(source:match("(local function showSettingsWindow%(view%).-)\nfunction app.requestLeave"))
local calls={}
local view={level=function(self,value) assert(value==0);table.insert(calls,"normal");return self end,show=function(self) table.insert(calls,"show");return self end,
 hswindow=function() error("must not search every window") end}
local env={hs={drawing={windowLevels={normal=0}},dockicon={show=function() table.insert(calls,"dock") end},processInfo={processID=7},
 application={applicationForPID=function(pid) assert(pid==7);return {activate=function() table.insert(calls,"activate") end,allWindows=function() error("must not query windows") end} end}},table=table}
local show=assert(load(helper.."\nreturn showSettingsWindow",nil,"t",env))()
show(view);assert(table.concat(calls,",")=="dock,normal,show,activate")
env.hs.application.applicationForPID=function() return nil end;calls={};show(view);assert(table.concat(calls,",")=="dock,normal,show")
assert(not source:find("bringToFront",1,true))
local _,count=source:gsub("showSettingsWindow%(app.settings%)","");assert(count==3)
print("Settings window opens at normal level and activates Nivlet without any window lookup passed")

local callback=assert(source:match(':windowCallback%((function%(event%).-)%)\n    showSettingsWindow'))
local hidden,requested=0,0
local close=assert(load("return "..callback,nil,"t",{app={requestLeave=function(intent) assert(intent=="close");requested=requested+1 end},hs={dockicon={hide=function() hidden=hidden+1 end}}}))()
close("focusChange");assert(hidden==0 and requested==0)
assert(close("shouldClose")==false);assert(hidden==0 and requested==1)
close("closing");assert(hidden==1)
print("Settings close can be cancelled before Dock is hidden; actual close still hides Dock")

local lifecycle=assert(source:match('(function app.requestLeave%(intent%).-)\nfunction app.openSettings'))
local quitCount,showCount,script=0,0,nil
local fixture={}
local runtime={json={encode=function(value) return '["'..value[1]..'"]' end},nivletQuit=function() quitCount=quitCount+1 end}
assert(load(lifecycle,nil,"t",{app=fixture,hs=runtime,showSettingsWindow=function() showCount=showCount+1 end}))()
assert(runtime.nivletShouldTerminate()==true)
fixture.requestLeave("close");assert(quitCount==0)
fixture.requestLeave("quit");assert(quitCount==1)
fixture.settings={evaluateJavaScript=function(_,value) script=value end}
assert(runtime.nivletShouldTerminate()==false)
assert(showCount==1 and script=='window.requestLeave(["quit"][0])')
fixture.exitApproved=true;assert(runtime.nivletShouldTerminate()==true)
assert(showCount==1)
print("Production Lua quit routing: no window, pending drafts and approved termination passed")
