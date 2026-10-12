local i18n=require("modules.i18n")
local preferences=require("modules.preferences")
local M={enabled=false}
function M.matches(shortcut)
    return shortcut and shortcut.key=="L" and #shortcut.mods==1 and shortcut.mods[1]=="cmd"
end
function M.conflicts(shortcut) return M.enabled and M.matches(shortcut) end
function M.configure(enabled)
    if enabled==M.enabled then return true end
    if not enabled then
        if M.binding then M.binding:delete();M.binding=nil end
        M.enabled=false;return true
    end
    if preferences.systemAssigned({"cmd"},"L") or not hs.hotkey.assignable({"cmd"},"L") then return false,i18n.t("Command + L 无法注册，请检查系统快捷键") end
    local binding=hs.hotkey.bind({"cmd"},"L",function() hs.caffeinate.systemSleep() end)
    if not binding then return false,i18n.t("Command + L 无法注册，请检查系统快捷键") end
    M.binding=binding;M.enabled=true;return true
end
return M
