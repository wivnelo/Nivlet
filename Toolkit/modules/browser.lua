local i18n = require("modules.i18n")
local bundleIDs = require("modules.bundle_id")
local M={}
local settingsKey="desktoptoolkit.browser.v1"
M.browsers={{id="com.apple.Safari",name="Safari"},{id="com.google.Chrome",name="Chrome"},{id="org.mozilla.firefox",name="Firefox"},{id="com.microsoft.edgemac",name="Edge"},{id="com.brave.Browser",name="Brave"}}
function M.defaults() return {enabled=false,defaultBrowser="com.apple.Safari",rules={},appRules={}} end
local function known(id)
    for _,browser in ipairs(M.browsers) do if browser.id==id then return true end end
    return false
end
local function labels(value)
    if type(value)~="string" then return nil end
    value=value:lower():gsub("%.$","")
    if #value==0 or #value>253 then return nil end
    for label in (value.."."):gmatch("(.-)%.") do
        if #label==0 or #label>63 or not label:match("^[%w%-]+$") or label:sub(1,1)=="-" or label:sub(-1)=="-" then return nil end
    end
    return value
end
local function domain(value)
    local host=labels(value)
    if not host or not host:find(".",1,true) then return nil end
    return host
end
local function ipv4(value)
    local a,b,c,d=value:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if not a then return false end
    for _,octet in ipairs({a,b,c,d}) do
        if #octet>3 or tonumber(octet)>255 then return false end
    end
    return true
end
local function hextet(value)
    return #value>=1 and #value<=4 and value:match("^[0-9A-Fa-f]+$")~=nil
end
local function colonParts(value)
    local parts={}
    if value=="" then return parts end
    for part in (value..":"):gmatch("([^:]*):") do table.insert(parts,part) end
    return parts
end
local function partsOk(parts,allowV4)
    for i,part in ipairs(parts) do
        if part=="" then return false end
        if i==#parts and part:find(".",1,true) then
            if not allowV4 or not ipv4(part) then return false end
        elseif not hextet(part) then return false end
    end
    return true
end
local function ipv6(value)
    if type(value)~="string" or value=="" or #value>80 then return nil end
    local addr=value
    if value:find("%",1,true) then
        local head=value:match("^([^%%]+)%%[%w%.%-~_]+$")
        if not head then return nil end
        addr=head
    end
    if addr=="" or addr:find(":::",1,true) or select(2,addr:gsub("::","::"))>1 then return nil end
    if addr:find("::",1,true) then
        local left,right=addr:match("^(.-)::(.*)$")
        if not left then return nil end
        local leftParts,rightParts=colonParts(left),colonParts(right)
        if not partsOk(leftParts,false) or not partsOk(rightParts,true) then return nil end
        local count=#leftParts+#rightParts
        if #rightParts>0 and rightParts[#rightParts]:find(".",1,true) then count=count+1 end
        if count>=8 then return nil end
        return addr:lower()
    end
    local parts=colonParts(addr)
    local mapped=#parts>0 and parts[#parts]:find(".",1,true)
    if mapped then
        if #parts~=7 then return nil end
    elseif #parts~=8 then return nil end
    if not partsOk(parts,true) then return nil end
    return addr:lower()
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
        if type(rule)~="table" or not bundleIDs.valid(rule.bundleID) or type(rule.name)~="string" or #rule.name>256 or not known(rule.browser) or seen[rule.bundleID:lower()] then return nil,i18n.t("来源应用规则无效或重复") end
        seen[rule.bundleID:lower()]=true;table.insert(config.appRules,{bundleID=rule.bundleID,name=rule.name,browser=rule.browser})
    end
    return config
end
M.config=M.defaults()
function M.installed()
    local result={}
    for _,browser in ipairs(M.browsers) do
        local path=hs.application.pathForBundleID(browser.id)
        if path and hs.fs.attributes(path,"mode")=="directory" then table.insert(result,browser) end
    end
    return result
end
function M.resolve(url,sourceBundle)
    if type(url)~="string" or #url>16384 or url:find("[%s%c]") then return nil,i18n.t("请输入有效的 HTTP / HTTPS 链接") end
    local scheme,authority=url:match("^([%a]+)://([^/?#]+)")
    if not scheme or scheme:lower()~="http" and scheme:lower()~="https" or authority:find("@",1,true) then return nil,i18n.t("仅支持不含登录信息的 HTTP / HTTPS 链接") end
    local host,port
    if authority:sub(1,1)=="[" then
        host,port=authority:match("^%[([^%]]+)%]:(%d+)$")
        if host then host=ipv6(host) else
            local only=authority:match("^%[([^%]]+)%]$")
            host=only and ipv6(only) or nil
        end
    else
        host,port=authority:match("^([^:]+):(%d+)$")
        if port or not authority:find(":",1,true) then host=labels(host or authority) else host=nil end
    end
    if port and (tonumber(port)<1 or tonumber(port)>65535) then return nil,i18n.t("端口无效") end
    if not host then return nil,i18n.t("域名无效；国际化域名请使用 punycode") end
    if M.config.enabled then
        for _,rule in ipairs(M.config.rules) do
            if host==rule.domain or rule.subdomains and not host:find(":",1,true) and host:sub(-#rule.domain-1)=="."..rule.domain then return rule.browser end
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
