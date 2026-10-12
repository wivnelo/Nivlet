local M={}
function M.snapshot()
    local ok,value=pcall(hs.accessibilityState)
    local state=ok and type(value)=="boolean" and (value and "granted" or "denied") or "error"
    if state=="granted" and hs.axuielement and hs.application then
        -- AXIsProcessTrusted can remain true after a development build is re-signed.
        -- Probe another process: accessing our own windows does not prove permission.
        local checked,role,message=pcall(function()
            local application=hs.application.get("com.apple.finder")
            if not application then return "unavailable" end
            return hs.axuielement.applicationElement(application):attributeValue("AXRole")
        end)
        if checked and message=="The accessibility API is disabled" then state="denied"
        elseif not checked or role==nil then state="error" end
    end
    return {accessibility=state}
end
function M.openSettings()
    return hs.urlevent.openURLWithBundle("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility","com.apple.systempreferences")
end
function M.openLoginSettings()
    return hs.urlevent.openURLWithBundle("x-apple.systempreferences:com.apple.LoginItems-Settings.extension","com.apple.systempreferences")
end
return M
