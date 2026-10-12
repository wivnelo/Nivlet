local i18n = require("modules.i18n")
local M = {}
local originals = {}
M.actions = {"left", "right", "top", "bottom", "maximize", "restore", "topLeft", "topRight", "bottomLeft", "bottomRight", "center", "leftThird", "middleThird", "rightThird", "leftTwoThirds", "rightTwoThirds", "grid1", "grid2", "grid3", "grid4", "grid5", "grid6", "grid7", "grid8", "grid9", "grow", "shrink", "screenLeft", "screenRight"}
local units={
    left={0,0,.5,1},right={.5,0,.5,1},top={0,0,1,.5},bottom={0,.5,1,.5},maximize={0,0,1,1},
    topLeft={0,0,.5,.5},topRight={.5,0,.5,.5},bottomLeft={0,.5,.5,.5},bottomRight={.5,.5,.5,.5},center={.25,.25,.5,.5},
}
local thirds={leftThird={0,1},middleThird={1,1},rightThird={2,1},leftTwoThirds={0,2},rightTwoThirds={1,2}}
local function fit(frame,bounds)
    local w,h=math.min(math.max(frame.w,1),bounds.w),math.min(math.max(frame.h,1),bounds.h)
    return {x=math.max(bounds.x,math.min(frame.x,bounds.x+bounds.w-w)),y=math.max(bounds.y,math.min(frame.y,bounds.y+bounds.h-h)),w=w,h=h}
end
function M.frame(action, bounds, current)
    local unit=units[action]
    if unit then return {x=bounds.x+bounds.w*unit[1],y=bounds.y+bounds.h*unit[2],w=bounds.w*unit[3],h=bounds.h*unit[4]} end
    local third=thirds[action]
    if third then
        if bounds.h>bounds.w then return {x=bounds.x,y=bounds.y+bounds.h*third[1]/3,w=bounds.w,h=bounds.h*third[2]/3} end
        return {x=bounds.x+bounds.w*third[1]/3,y=bounds.y,w=bounds.w*third[2]/3,h=bounds.h}
    end
    local cell=type(action)=="string" and tonumber(action:match("^grid([1-9])$"))
    if cell then return {x=bounds.x+bounds.w*((cell-1)%3)/3,y=bounds.y+bounds.h*math.floor((cell-1)/3)/3,w=bounds.w/3,h=bounds.h/3} end
    if (action=="grow" or action=="shrink") and current then
        local delta=action=="grow" and 40 or -40
        local w,h=math.max(1,current.w+delta),math.max(1,current.h+delta)
        return fit({x=current.x+(current.w-w)/2,y=current.y+(current.h-h)/2,w=w,h=h},bounds)
    end
end
local function remember(window,screen)
    local id=window:id()
    if not originals[id] then
        originals[id]={frame=window:frame(),screenID=screen.id and screen:id() or nil}
    end
end
function M.run(action, window)
    if require("modules.permissions").snapshot().accessibility~="granted" then return false, i18n.t("请在通用设置中检查并开启辅助功能权限") end
    local w = window or hs.window.focusedWindow()
    if not w or not w:isStandard() or w:isFullScreen() then return false, i18n.t("请选择可调整的普通窗口") end
    local screen=w:screen()
    if not screen then return false,i18n.t("无法确定窗口所在屏幕") end
    local id = w:id()
    if action == "restore" then
        local original=originals[id]
        if not original then return false, i18n.t("此窗口没有可恢复的位置") end
        local target=original.screenID and hs.screen and hs.screen.find(original.screenID) or nil
        if target then w:moveToScreen(target,false,true,0) end
        local frame=original.frame
        if original.screenID and not target then frame=fit(frame,screen:frame()) end
        w:setFrame(frame,0);originals[id]=nil
    elseif action=="screenLeft" or action=="screenRight" then
        local target=action=="screenLeft" and screen:toWest() or nil
        if action=="screenRight" then target=screen:toEast() end
        if not target then return false,i18n.t("该方向没有相邻屏幕") end
        remember(w,screen)
        w:moveToScreen(target,false,true,0)
    else
        local target = M.frame(action, screen:frame(), w:frame())
        if not target then return false, i18n.t("未知窗口操作") end
        remember(w,screen)
        w:setFrame(target, 0)
    end
    return true
end
return M
