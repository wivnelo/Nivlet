local i18n=require("modules.i18n")
local M={awake=false,display=false}
function M.configure(awake,display)
    display=awake and display
    if not awake and not M.awake and not M.display then return true end
    local api=hs.caffeinate and hs.caffeinate.nivletKeepAwake
    if type(api)~="function" then return false,i18n.t("无法更新保持唤醒设置，请重试") end
    local ran,ok,restored,actualAwake,actualDisplay=pcall(api,awake,display)
    if ran then M.awake=actualAwake==true;M.display=actualDisplay==true end
    if ran and ok then return true end
    local message=i18n.t("无法更新保持唤醒设置，请重试")
    if not ran or not restored then message=message..i18n.t("；部分状态无法恢复，请关闭保持唤醒后重试") end
    return false,message
end
function M.stop()
    if not M.awake and not M.display then return true end
    local api=hs.caffeinate and hs.caffeinate.nivletStopKeepAwake
    if type(api)~="function" then return false end
    local ran,ok=pcall(api)
    if ran and ok then M.awake=false;M.display=false end
    return ran and ok
end
return M
