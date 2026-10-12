package.path="Toolkit/?.lua;"..package.path
local windows=require("modules.windows")
local bounds={x=-1800,y=-900,w=1800,h=900}
local function frame(action,expected,b,current)
    local actual=assert(windows.frame(action,b or bounds,current),action)
    for key,value in pairs(expected) do assert(math.abs(actual[key]-value)<.001,action.." "..key.." "..actual[key]) end
end
frame("top",{x=-1800,y=-900,w=1800,h=450})
frame("bottom",{x=-1800,y=-450,w=1800,h=450})
for action,position in pairs({topLeft={-1800,-900},topRight={-900,-900},bottomLeft={-1800,-450},bottomRight={-900,-450}}) do frame(action,{x=position[1],y=position[2],w=900,h=450}) end
frame("center",{x=-1350,y=-675,w=900,h=450})
for action,value in pairs({leftThird={0,1},middleThird={1,1},rightThird={2,1},leftTwoThirds={0,2},rightTwoThirds={1,2}}) do
    frame(action,{x=-1800+600*value[1],y=-900,w=600*value[2],h=900})
    frame(action,{x=-900,y=-1800+600*value[1],w=900,h=600*value[2]},{x=-900,y=-1800,w=900,h=1800})
end
for cell=1,9 do frame("grid"..cell,{x=-1800+((cell-1)%3)*600,y=-900+math.floor((cell-1)/3)*300,w=600,h=300}) end
frame("grow",{x=-1520,y=-720,w=440,h=340},nil,{x=-1500,y=-700,w=400,h=300})
frame("shrink",{x=-1480,y=-680,w=360,h=260},nil,{x=-1500,y=-700,w=400,h=300})
frame("grow",{x=-1800,y=-900,w=1800,h=900},nil,bounds)
local tiny=windows.frame("shrink",bounds,{x=-1800,y=-900,w=20,h=20});assert(tiny.w>0 and tiny.h>0)
assert(not windows.frame("grid10",bounds) and not windows.frame("unknown",bounds))
local current={x=-1600,y=-700,w=600,h=500}
local original=current
local screens={}
local screenA={id=function() return 1 end,frame=function() return bounds end}
local screenB={id=function() return 2 end,frame=function() return {x=0,y=0,w=1200,h=800} end}
screenA.toEast=function() return screenB end;screenA.toWest=function() return nil end
screenB.toWest=function() return screenA end;screenB.toEast=function() return nil end
screens[1]=screenA;screens[2]=screenB
local active,allowed,normal,full=screenA,true,true,false
local window={id=function() return 42 end,isStandard=function() return normal end,isFullScreen=function() return full end,screen=function() return active end,frame=function() return current end,setFrame=function(_,v) current=v end,moveToScreen=function(_,s) active=s end}
hs={accessibilityState=function() return allowed end,window={focusedWindow=function() return window end},screen={find=function(id) return screens[id] end}}
assert(not windows.run("screenLeft"));assert(not windows.run("restore"))
assert(windows.run("grid9"));assert(windows.run("top"));assert(windows.run("restore"));assert(current==original)
assert(windows.run("screenRight"));assert(active==screenB)
assert(windows.run("center"));assert(windows.run("restore"));assert(active==screenA and current==original)
assert(not windows.run("restore"))
assert(windows.run("screenRight"));screens[1]=nil
assert(windows.run("restore"));assert(active==screenB and current.x>=0 and current.y>=0 and current.x+current.w<=1200 and current.y+current.h<=800)
assert(not windows.run("screenRight"))
allowed=false;assert(not windows.run("top"));allowed=true
normal=false;assert(not windows.run("top"));normal=true
full=true;assert(not windows.run("top"));full=false
active=nil;assert(not windows.run("top"))
print("Window halves, corners, portrait thirds, nine cells, resize bounds, directional screens, restore and disconnected-screen recovery passed")
