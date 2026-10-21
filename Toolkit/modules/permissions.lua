local M={}
function M.snapshot()
    local ok,value=pcall(hs.accessibilityState)
    local state=ok and type(value)=="boolean" and (value and "granted" or "denied") or "error"
    local restartRequired=false
    if hs.axuielement and hs.application then
        -- Probe even when the trust API is false: reauthorization can leave stale state.
        -- Probe another process: accessing our own windows does not prove permission.
        local checked,role,message=pcall(function()
            local application=hs.application.get("com.apple.finder")
            if not application then return "unavailable" end
            return hs.axuielement.applicationElement(application):attributeValue("AXRole")
        end)
        if checked and message=="The accessibility API is disabled" then state="denied"
        elseif checked and role=="AXApplication" then
            -- AX access alone does not prove keyboard event posting has recovered.
            restartRequired=state=="denied"
        elseif state=="granted" and (not checked or role==nil) then state="error" end
    end
    return {accessibility=state,restartRequired=restartRequired}
end
function M.isGranted()
    return M.snapshot().accessibility=="granted"
end
function M.watch(callback)
    hs.accessibilityStateCallback=function() callback(M.snapshot()) end
end
function M.openSettings()
    return hs.urlevent.openURLWithBundle("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility","com.apple.systempreferences")
end
function M.openLoginSettings()
    return hs.urlevent.openURLWithBundle("x-apple.systempreferences:com.apple.LoginItems-Settings.extension","com.apple.systempreferences")
end
return M
