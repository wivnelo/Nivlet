local i18n=require("modules.i18n")
local permissions=require("modules.permissions")
local M={}
local supported={["com.apple.Safari"]=true,["com.google.Chrome"]=true}
local pending
function M.open(id,done)
    if pending then done(false,i18n.t("正在打开浏览器，请稍候"));return end
    if not supported[id] or not hs.application.pathForBundleID(id) then done(false,i18n.t("浏览器未安装或暂不支持"));return end
    if permissions.snapshot().accessibility~="granted" then done(false,i18n.t("请在通用设置中检查并开启辅助功能权限"));return end
    if not hs.application.launchOrFocusByBundleID(id) then done(false,i18n.t("无法启动浏览器"));return end
    local attempts=0
    pending=hs.timer.doEvery(0.2,function()
        attempts=attempts+1
        local app=hs.application.get(id)
        if app and app:isFrontmost() then
            if id=="com.google.Chrome" then
                pending:stop();pending=nil
                hs.eventtap.keyStroke({"cmd","shift"},"delete",0,app)
                done(true,i18n.t("已请求打开清除窗口，请在浏览器中确认"))
                return
            end
            for _,path in ipairs({{"历史记录","清除历史记录…"},{"历史记录","清除历史记录..."},{"History","Clear History…"},{"History","Clear History..."}}) do
                if app:selectMenuItem(path) then
                    pending:stop();pending=nil
                    done(true,i18n.t("已请求打开清除窗口，请在浏览器中确认"))
                    return
                end
            end
        end
        if attempts>=25 then
            pending:stop();pending=nil
            done(false,i18n.t("无法打开清除窗口，请在浏览器菜单中手动打开"))
        end
    end)
end
return M
