local i18n = require("modules.i18n")
local M={}
local settingsKey="desktoptoolkit.browser.v1"
M.browsers={{id="com.apple.Safari",name="Safari"},{id="com.google.Chrome",name="Chrome"},{id="org.mozilla.firefox",name="Firefox"},{id="com.microsoft.edgemac",name="Edge"},{id="com.brave.Browser",name="Brave"}}
function M.defaults() return {enabled=false,defaultBrowser="com.apple.Safari",rules={},appRules={}} end
local function known(id)
    for _,browser in ipairs(M.browsers) do if browser.id==id then return true end end
    return false
end
local function domain(value)
    if type(value)~="string" then return nil end
    value=value:lower():gsub("%.$","")
    if #value>253 or not value:find(".",1,true) then return nil end
    for label in (value.."."):gmatch("(.-)%.") do
        if #label==0 or #label>63 or not label:match("^[%w%-]+$") or label:sub(1,1)=="-" or label:sub(-1)=="-" then return nil end
    end
    return value
end
function M.validate(value)
    if type(value)~="table" or type(value.enabled)~="boolean" or not known(value.defaultBrowser) or type(value.rules)~="table" or #value.rules>100 then return nil,i18n.t("浏览器设置格式无效") end
    local config={enabled=value.enabled,defaultBrowser=value.defaultBrowser,rules={}}
    local appRules=value.appRules or {}
    if type(appRules)~="table" or #appRules>100 then return nil,i18n.t("来源应用规则格式无效") end
    local seen={}
    for _,rule in ipairs(value.rules) do
        if type(rule)~="table" then return nil,i18n.t("域名规则格式无效") end
        local host=domain(rule.domain)
        if not host or not known(rule.browser) or type(rule.subdomains)~="boolean" or seen[host] then return nil,i18n.t("填写有效且不重复的域名，并选择浏览器") end
        seen[host]=true;table.insert(config.rules,{domain=host,browser=rule.browser,subdomains=rule.subdomains})
    end
    config.appRules={};seen={}
    for _,rule in ipairs(appRules) do
        if type(rule)~="table" or type(rule.bundleID)~="string" or not rule.bundleID:match("^[%w_%-]+%.[%w_.%-]+$") or type(rule.name)~="string" or #rule.name>256 or not known(rule.browser) or seen[rule.bundleID:lower()] then return nil,i18n.t("来源应用规则无效或重复") end
        seen[rule.bundleID:lower()]=true;table.insert(config.appRules,{bundleID=rule.bundleID,name=rule.name,browser=rule.browser})
    end
    return config
end
M.config=M.defaults()
function M.installed()
    local result={}
    for _,browser in ipairs(M.browsers) do if hs.application.pathForBundleID(browser.id) then table.insert(result,browser) end end
    return result
end
function M.resolve(url,sourceBundle)
    if type(url)~="string" or #url>16384 or url:find("[%s%c]") then return nil,i18n.t("请输入有效的 HTTP / HTTPS 链接") end
    local scheme,authority=url:match("^([%a]+)://([^/?#]+)")
    if not scheme or scheme:lower()~="http" and scheme:lower()~="https" or authority:find("@",1,true) then return nil,i18n.t("仅支持不含登录信息的 HTTP / HTTPS 链接") end
    local host,port=authority:match("^([^:]+):(%d+)$")
    if port and (tonumber(port)<1 or tonumber(port)>65535) then return nil,i18n.t("端口无效") end
    host=domain(host or authority)
    if not host then return nil,i18n.t("域名无效；国际化域名请使用 punycode") end
    if M.config.enabled then
        for _,rule in ipairs(M.config.rules) do
            if host==rule.domain or rule.subdomains and host:sub(-#rule.domain-1)=="."..rule.domain then return rule.browser end
        end
        for _,rule in ipairs(M.config.appRules or {}) do if type(sourceBundle)=="string" and sourceBundle:lower()==rule.bundleID:lower() then return rule.browser end end
    end
    return M.config.defaultBrowser
end
function M.open(url,sourceBundle)
    local browser,message=M.resolve(url,sourceBundle);if not browser then return false,message end
    if not hs.application.pathForBundleID(browser) then return false,i18n.t("目标浏览器未安装，请调整规则") end
    if not hs.urlevent.openURLWithBundle(url,browser) then return false,i18n.t("无法打开目标浏览器") end
    return true,i18n.t("链接已交给指定浏览器")
end
function M.save(value)
    local config,message=M.validate(value);if not config then return false,message end
    if not hs.application.pathForBundleID(config.defaultBrowser) then return false,i18n.t("默认打开浏览器未安装") end
    for _,rule in ipairs(config.rules) do if not hs.application.pathForBundleID(rule.browser) then return false,i18n.t("规则中的浏览器未安装") end end
    for _,rule in ipairs(config.appRules) do if not hs.application.pathForBundleID(rule.browser) then return false,i18n.t("来源应用规则中的浏览器未安装") end end
    M.config=config;hs.settings.set(settingsKey,config);return true,i18n.t("浏览器规则已保存")
end
function M.requestDefault()
    hs.urlevent.setDefaultHandler("https", "dev.local.DesktopToolkit", true)
end
function M.openDefaultSettings()
    return hs.urlevent.openURLWithBundle("x-apple.systempreferences:com.apple.Desktop-Settings.extension", "com.apple.systempreferences")
end
function M.status()
    local http=hs.urlevent.getDefaultHandler("http")
    local https=hs.urlevent.getDefaultHandler("https")
    return {active=http=="dev.local.DesktopToolkit" and https=="dev.local.DesktopToolkit"}
end
function M.start()
    M.config=M.validate(hs.settings.get(settingsKey)) or M.defaults()
    if hs.urlevent then hs.urlevent.httpCallback=function(_,_,_,url,senderPID)
        local source=type(senderPID)=="number" and senderPID>0 and hs.application.applicationForPID(senderPID) or nil
        local ok,message=M.open(url,source and source:bundleID());if not ok then hs.alert.show(message) end
    end
        hs.urlevent.processStartupEvents()
    end
end
return M
