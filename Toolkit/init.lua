assert(hs.processInfo.bundleID == "dev.local.DesktopToolkit", "Unexpected runtime Bundle ID")
assert(hs.settings.bundleID == "dev.local.DesktopToolkit", "Unexpected settings domain")
assert(not hs.configdir:find(".hammerspoon", 1, true), "Personal configuration detected")
local root = hs.processInfo.bundlePath .. "/Contents/Resources/Toolkit/"
package.path = root .. "?.lua;" .. package.path
local i18n = require("modules.i18n")
local bundleIDs = require("modules.bundle_id")
local preferences = require("modules.preferences")
local windows = require("modules.windows")
local input = require("modules.input_method")
input.start()
local clipboard = require("modules.clipboard")
local system = require("modules.sys_info")
local browser = require("modules.browser")
local browserData=require("modules.browser_data")
browser.start()
clipboard.start()
local launcher=require("modules.launcher")
local permissions=require("modules.permissions")
local about=require("modules.about")
local sleep=require("modules.sleep")
local app = {bindings={}}
local generalKey = "desktoptoolkit.general.v1"
local tabIDs={windowSection=true,inputSection=true,clipSection=true,systemSection=true,browserSection=true,launcherSection=true,aboutSection=true}
local function validateGeneral(value)
    if type(value) ~= "table" or type(value.showMenu) ~= "boolean" or
        (value.appearance ~= "system" and value.appearance ~= "light" and value.appearance ~= "dark") then
        return nil, i18n.t("通用设置格式无效")
    end
    if value.sleepShortcut~=nil and type(value.sleepShortcut)~="boolean" then return nil,i18n.t("通用设置格式无效") end
    local language=value.language or "system"
    if language~="system" and language~="zh-Hans" and language~="en" then return nil,i18n.t("语言设置无效") end
    local order,seen={},{}
    if value.tabOrder~=nil then
        if type(value.tabOrder)~="table" then return nil,i18n.t("通用设置格式无效") end
        for k,id in pairs(value.tabOrder) do
            if type(k)~="number" or k%1~=0 or k<1 or k>#value.tabOrder or not tabIDs[id] or seen[id] then return nil,i18n.t("通用设置格式无效") end
            seen[id]=true
        end
        for _,id in ipairs(value.tabOrder) do if id~="aboutSection" then order[#order+1]=id end end
    end
    return {showMenu=value.showMenu, appearance=value.appearance,language=language,tabOrder=order,sleepShortcut=value.sleepShortcut==true}
end
app.general = validateGeneral(hs.settings.get(generalKey)) or {showMenu=true,appearance="system",language="system"}
-- The upstream hammer menu duplicates our own settings entry.
hs.menuIcon(false)
hs.openConsoleOnDockClick(false)
hs.nivletAppearance(app.general.appearance)
function app.saveGeneral(value)
    local config, message = validateGeneral(value)
    if not config then return false, message end
    if config.sleepShortcut then
        for _,shortcut in pairs(app.config and app.config.shortcuts or {}) do if sleep.matches(shortcut) then return false,i18n.t("Command + L 与已有快捷键冲突") end end
        if sleep.matches(app.popupShortcut) then return false,i18n.t("Command + L 与已有快捷键冲突") end
        for _,rule in ipairs(launcher.config.rules) do if sleep.matches(rule.shortcut) then return false,i18n.t("Command + L 与已有快捷键冲突") end end
    end
    local installed,result=sleep.configure(config.sleepShortcut)
    if not installed then return false,result end
    hs.nivletAppearance(config.appearance)
    if config.showMenu then
        local wasVisible=app.menu:isInMenuBar()
        app.menu:returnToMenuBar()
        if app.mainIcon then app.menu:setIcon(app.mainIcon,true) end
        if not wasVisible and app.arrangeMenus then app.arrangeMenus() end
    else app.menu:removeFromMenuBar() end
    app.general=config
    i18n.configure(config.language)
    if app.updateMenu then app.updateMenu() end
    if app.settings then app.settings:windowTitle("Nivlet for Mac") end
    clipboard.menu:setTooltip(i18n.t("Nivlet 剪贴板历史"))
    system.menu:setTooltip(i18n.t("Nivlet 系统信息")):setMenu(nil):setMenu(system.menuItems)
    hs.settings.set(generalKey,config)
    return true, i18n.t("通用设置已保存")
end
function app.setShowMenu(enabled)
    if type(enabled)~="boolean" then return false,i18n.t("通用设置格式无效") end
    local value={showMenu=enabled,appearance=app.general.appearance,language=app.general.language,sleepShortcut=app.general.sleepShortcut,tabOrder=app.general.tabOrder}
    return app.saveGeneral(value)
end
_G.desktopToolkit = app
local key = "desktoptoolkit.preferences.v1"
app.config = preferences.validate(hs.settings.get(key)) or preferences.defaults()
local popupKey = "desktoptoolkit.clipboard.shortcut.v1"
local function normalizePopup(value)
    local config, message = preferences.validate({enabled=false,shortcuts={left=value}})
    if not config then return nil, message end
    return config.shortcuts.left
end
local function sameShortcut(a, b)
    return a and b and a.key==b.key and table.concat(a.mods,"+")==table.concat(b.mods,"+")
end
local function popupConflicts(shortcut, config)
    for _, action in ipairs(windows.actions) do
        if sameShortcut(shortcut, config.shortcuts[action]) then return true end
    end
    return false
end
app.popupShortcut = normalizePopup(hs.settings.get(popupKey))
local function installPopup(shortcut)
    if app.popupBinding then app.popupBinding:delete();app.popupBinding=nil end
    if not shortcut then return true end
    if preferences.systemAssigned(shortcut.mods,shortcut.key) or not hs.hotkey.assignable(shortcut.mods,shortcut.key) then return false,i18n.t("剪贴板快捷键被系统占用或无法注册") end
    app.popupBinding = hs.hotkey.bind(shortcut.mods,shortcut.key,clipboard.showPopup)
    if not app.popupBinding then return false,i18n.t("剪贴板快捷键注册失败") end
    return true
end
function app.savePopup(value)
    local shortcut, message = normalizePopup(value)
    if message then return false,message end
    if sleep.conflicts(shortcut) then return false,i18n.t("Command + L 与已有快捷键冲突") end
    if launcher.conflicts(shortcut) then return false,i18n.t("快捷键与应用启动配置重复") end
    if popupConflicts(shortcut, app.config) then return false,i18n.t("剪贴板快捷键与窗口管理配置重复") end
    if not (sameShortcut(shortcut, app.popupShortcut) and app.popupBinding) then
        local success, result = installPopup(shortcut)
        if not success then
            local restored = installPopup(app.popupShortcut)
            return false, restored and result or result..i18n.t("；旧快捷键也无法恢复，请重新配置")
        end
    end
    app.popupShortcut=shortcut
    if shortcut then hs.settings.set(popupKey,shortcut) else hs.settings.clear(popupKey) end
    return true, shortcut and i18n.t("剪贴板菜单快捷键已保存") or i18n.t("剪贴板菜单快捷键已解除")
end
function app.saveGeneralPage(value,autoLaunch)
    local config,message=validateGeneral(value)
    if not config or type(autoLaunch)~="boolean" then return false,message or i18n.t("通用设置格式无效") end
    local oldLogin=hs.autoLaunch()
    local success,result
    if oldLogin==autoLaunch or hs.autoLaunch(autoLaunch)==autoLaunch then
        success,result=app.saveGeneral(config)
    else success,result=false,i18n.t("无法修改启动设置，请在系统设置中检查登录项") end
    if not success and hs.autoLaunch()~=oldLogin and hs.autoLaunch(oldLogin)~=oldLogin then result=result..i18n.t("；登录项恢复失败，请检查系统设置") end
    return success,result
end
function app.saveClipboardPage(value,popupShortcut)
    local config,message=clipboard.validate(value)
    if not config then return false,message end
    local oldPopup=app.popupShortcut
    local success,result=app.savePopup(popupShortcut)
    if not success then return false,result end
    success,result=clipboard.save(config)
    if not success then
        local restored,restoreMessage=app.savePopup(oldPopup)
        if not restored then result=result.."; "..restoreMessage end
    end
    return success,result
end
local function clearBindings()
    for _, binding in ipairs(app.bindings) do binding:delete() end
    app.bindings = {}
end
local function install(config)
    if not config.enabled then return true end
    for _, action in ipairs(windows.actions) do
        local item = config.shortcuts[action]
        if item then
            if not hs.hotkey.assignable(item.mods, item.key) or preferences.systemAssigned(item.mods, item.key) then clearBindings(); return false, i18n.t("快捷键被系统占用：") .. item.key end
            local binding = hs.hotkey.bind(item.mods, item.key, function()
                local ok, message = windows.run(action)
                if not ok then hs.alert.show(message) end
            end)
            if not binding then clearBindings(); return false, i18n.t("无法注册快捷键：") .. item.key end
            table.insert(app.bindings, binding)
        end
    end
    return true
end
function app.save(value)
    local config, message = preferences.validate(value)
    if not config then return false, message end
    for _,shortcut in pairs(config.shortcuts) do if sleep.conflicts(shortcut) then return false,i18n.t("Command + L 与已有快捷键冲突") end;if launcher.conflicts(shortcut) then return false,i18n.t("快捷键与应用启动配置重复") end end
    if popupConflicts(app.popupShortcut, config) then return false,i18n.t("窗口快捷键与剪贴板菜单配置重复") end
    if config.enabled and not permissions.isGranted() then return false, i18n.t("请在通用设置中检查并开启辅助功能权限") end
    clearBindings()
    local ok, errorMessage = install(config)
    if not ok then install(app.config); return false, errorMessage end
    app.config = config
    hs.settings.set(key, config)
    return true, i18n.t("已保存")
end
local ok, message = install(app.config)
if not ok then hs.alert.show(message) end
local configuration=require("modules.configuration")
local adapters={
    general={get=function() return app.general end,defaults=function() return {showMenu=true,appearance="system",language="system"} end,validate=validateGeneral,save=app.saveGeneral},
    windows={get=function() return app.config end,defaults=preferences.defaults,validate=preferences.validate,save=app.save},
    popupShortcut={get=function() return app.popupShortcut or false end,defaults=function() return false end,validate=function(v) local item,message;if v~=false then item,message=normalizePopup(v) end;if message then return nil,message end;return item or false end,save=function(v) if v==false then return app.savePopup(nil) end;return app.savePopup(v) end},
}
for name,module in pairs({input=input,clipboard=clipboard,system=system,browser=browser,launcher=launcher}) do
    adapters[name]={get=function() return module.config end,defaults=module.defaults or function() return {enabled=false,rules={}} end,validate=module.validate,save=module.save}
end
local configKeys={general=generalKey,windows=key,popupShortcut=popupKey,input="desktoptoolkit.input.v1",clipboard="desktoptoolkit.clipboard.v1",system="desktoptoolkit.system.v1",browser="desktoptoolkit.browser.v1",launcher="desktoptoolkit.launcher.v1"}
app.configuration=configuration.new(adapters,{
    systemAssigned=function(item) return preferences.systemAssigned(item.mods,item.key) end,
    accessibility=permissions.isGranted,
    hasHistory=function() return #clipboard.entries>0 end,
    capture=function() local result={};for name,k in pairs(configKeys) do result[name]={value=hs.settings.get(k)} end;return result end,
    restore=function(saved) for name,k in pairs(configKeys) do if saved[name].value==nil then hs.settings.clear(k) else hs.settings.set(k,saved[name].value) end end end,
    available=function(config,selected)
        local function installed(id) return hs.application.pathForBundleID(id)~=nil end
        for _,name in ipairs({"launcher","input"}) do
            if selected[name] then for _,rule in ipairs(config[name].rules) do if not installed(rule.bundleID) then return false,i18n.t("应用不可用，请重新选择：")..rule.bundleID end end end
        end
        if selected.input then
            local available={};for _,source in ipairs(input.sources()) do available[source.id]=true end
            for _,rule in ipairs(config.input.rules) do if not available[rule.sourceID] then return false,i18n.t("输入法不可用，请重新选择：")..rule.sourceID end end
        end
        if selected.browser then
            if not installed(config.browser.defaultBrowser) then return false,i18n.t("默认打开浏览器未安装") end
            for _,rule in ipairs(config.browser.rules) do if not installed(rule.browser) then return false,i18n.t("规则中的浏览器未安装") end end
            for _,rule in ipairs(config.browser.appRules) do if not installed(rule.bundleID) or not installed(rule.browser) then return false,i18n.t("来源应用或浏览器未安装") end end
        end
        return true
    end,
})
local function selectedPath(paths) return type(paths)=="table" and (paths[1] or paths["1"]) or paths end
local function exportConfiguration(defaults)
    local path=selectedPath(hs.dialog.chooseFileOrFolder(i18n.t("选择配置导出文件夹"),os.getenv("HOME"),false,true,false,{},true))
    if type(path)~="string" or path=="" then return nil end
    local filename=path.."/Nivlet-"..(defaults and "defaults-" or "config-")..os.date("%Y%m%d-%H%M%S")..".json"
    if hs.fs.attributes(filename) then return false,i18n.t("目标文件已存在，请稍后重试") end
    local file,message=io.open(filename,"w")
    if not file then return false,i18n.t("无法写入配置文件：")..tostring(message) end
    local ok,result=file:write(hs.json.encode(app.configuration.export(defaults),true))
    local closed,closeMessage=file:close()
    if not ok or not closed then return false,i18n.t("无法写入配置文件：")..tostring(result or closeMessage) end
    return true,i18n.t("配置已导出：")..filename
end
local function permissionState() return permissions.snapshot() end
local appIcons=require("modules.app_icons")
local appNames=require("modules.app_names")
local requestedApps={}
local function configuredAppIcons()
    local icons={}
    for _,config in ipairs({input.config,browser.config,launcher.config}) do
        for _,rule in ipairs(config.rules or {}) do if rule.bundleID then icons[rule.bundleID]=appIcons.get(rule.bundleID) or false end end
    end
    for _,rule in ipairs(browser.config.appRules or {}) do icons[rule.bundleID]=appIcons.get(rule.bundleID) or false end
    for _,id in ipairs(clipboard.config.excluded) do icons[id]=appIcons.get(id) or false end
    for _,id in ipairs({"com.apple.Safari","com.google.Chrome"}) do icons[id]=appIcons.get(id) or false end
    for _,id in ipairs(requestedApps) do icons[id]=appIcons.get(id) or false end
    return icons
end
local function applicationStates()
    local states={}
    for id in pairs(configuredAppIcons()) do
        local path=hs.application.pathForBundleID(id)
        states[id]={installed=path and hs.fs.attributes(path,"mode")=="directory" or false,name=appNames.get(id)}
    end
    return states
end
local function excludedAppNames()
    local names={}
    for _,id in ipairs(clipboard.config.excluded) do
        names[id]=appNames.get(id)
    end
    return names
end
local function reply(ok, message, action, requestID)
    if action=="refreshApplications" or action=="refreshBrowserStatus" or action=="refreshPermissionsSilent" or action=="prepareBrowserData" or action==nil then appIcons.clear() end
    local permission=permissionState()
    if app.settings then app.settings:evaluateJavaScript("window.receive(" .. hs.json.encode({ok=ok,message=message,action=action,requestID=requestID,language=i18n.language(),translations=i18n.dictionary,general=app.general,launcher=appNames.snapshot(launcher.config),config=app.config,input=appNames.snapshot(input.config),sources=input.sources(),clipboard=clipboard.snapshot(),excludedAppNames=excludedAppNames(),appIcons=configuredAppIcons(),applicationStates=applicationStates(),popupShortcut=app.popupShortcut or false,system=system.config,browser=appNames.snapshot(browser.config),browserStatus=browser.status(),browsers=browser.installed(),accessibility=permission.accessibility=="granted",permissions=permission,autoLaunch=hs.autoLaunch(),about=about.snapshot()}) .. ")") end
end
local function showSettingsWindow(view)
    hs.dockicon.show()
    view:level(hs.drawing.windowLevels.normal):show()
    local window=view:hswindow()
    if window then
        local owner=window:application()
        if owner then owner:activate() end
        window:focus()
    end
end
function app.requestLeave(intent)
    if not app.settings then
        if intent=="quit" and hs.nivletQuit then hs.nivletQuit() end
        return
    end
    showSettingsWindow(app.settings)
    local keyEvent=hs.nivletCurrentKeyEvent and hs.nivletCurrentKeyEvent()
    app.settings:evaluateJavaScript("window.requestLeave("..hs.json.encode({intent}).."[0]"..(keyEvent and ","..hs.json.encode(keyEvent) or "")..")")
end
hs.nivletShouldTerminate=function()
    if app.exitApproved or not app.settings then return true end
    app.requestLeave("quit")
    return false
end
function app.openSettings(section, focus)
    section=type(section)=="string" and section or nil
    focus=type(focus)=="string" and focus or nil
    app.settingsSection=section
    app.settingsFocus=focus
    if app.settings then showSettingsWindow(app.settings); reply(true, ""); if section then app.settings:evaluateJavaScript("window.showSection(" .. hs.json.encode({section}) .. "[0])") end; if focus then app.settings:evaluateJavaScript("document.getElementById("..hs.json.encode({focus}).."[0]).focus()") end; return end
    app.controller = hs.webview.usercontent.new("toolkit")
    app.controller:setCallback(function(event)
        local body = event.body
        if type(body) ~= "table" then return end
        if body.action=="confirmLeave" then
            if body.intent=="quit" then
                if hs.nivletQuit then app.exitApproved=true;hs.nivletQuit() end
            elseif body.intent=="close" then app.settings:hide();hs.dockicon.hide() end
            return
        end
        if body.action=="setAutoLaunch" then
            local ok=type(body.enabled)=="boolean" and hs.autoLaunch(body.enabled)==body.enabled
            reply(ok,ok and i18n.t("启动设置已更新") or i18n.t("无法修改启动设置，请在系统设置中检查登录项"),body.action)
        end
        if body.action=="openProjectLink" then
            local links={website="https://wivnelo.github.io/Nivlet/",project="https://github.com/wivnelo/Nivlet",issues="https://github.com/wivnelo/Nivlet/issues",releases="https://github.com/wivnelo/Nivlet/releases",license="https://github.com/wivnelo/Nivlet/blob/main/LICENSE"}
            if links[body.link] then hs.urlevent.openURL(links[body.link]) end
        end
        if body.action=="checkUpdates" then
            local ok=hs.nivletCheckForUpdates and hs.nivletCheckForUpdates()
            if not ok then reply(false,i18n.t("暂时无法检查更新，请稍后重试或查看版本记录。"),body.action) end
            return
        end
        if body.action=="prepareBrowserData" then
            local ok=permissions.snapshot().accessibility=="granted"
            reply(ok,ok and "" or i18n.t("请在通用设置中检查并开启辅助功能权限"),body.action,body.requestID)
            return
        end
        if body.action=="openBrowserData" then
            browserData.open(body.bundleID,function(ok,message) reply(ok,message,"openBrowserData") end)
            return
        end
        if body.action=="setDefaultBrowser" then
            browser.requestDefault()
            reply(true,i18n.t("请完成系统确认，再点击重新检测；若未出现确认，请打开系统设置。"),body.action)
            return
        end
        if body.action=="refreshApplications" then
            requestedApps={}
            if type(body.bundleIDs)=="table" then for _,id in ipairs(body.bundleIDs) do
                if #requestedApps<500 and bundleIDs.valid(id) then table.insert(requestedApps,id) end
            end end
            reply(true,"",body.action);return
        end
        if body.action=="refreshBrowserStatus" then reply(true,"",body.action);return end
        if body.action=="openDefaultBrowserSettings" then
            local ok=browser.openDefaultSettings()
            reply(ok,ok and "" or i18n.t("无法打开系统设置，请手动打开桌面与程序坞。"),body.action)
            return
        end
        if body.action=="openLoginSettings" then
            local ok=permissions.openLoginSettings()
            reply(ok,ok and "" or i18n.t("无法打开登录项设置，请手动打开系统设置"),body.action)
            return
        end
        if body.action=="refreshPermissions" then
            local permission=permissionState()
            local state=permission.accessibility
            local message=state=="granted" and i18n.t("检测完成：辅助功能权限已开启") or state=="denied" and i18n.t("检测完成：辅助功能权限未开启") or i18n.t("权限检测失败，请重新检测")
            reply(state~="error",body.silent and "" or message,body.silent and "refreshPermissionsSilent" or body.action)
        end
        if body.action=="openAccessibility" then
            local opened=permissions.openSettings()
            reply(opened,opened and i18n.t("已打开系统设置，请选择 Nivlet 并开启辅助功能权限") or i18n.t("无法打开系统设置，请手动前往隐私与安全性 → 辅助功能"),body.action)
        end
        if body.action=="refreshSystemValues" then
            local ok,values=pcall(system.snapshot)
            app.settings:evaluateJavaScript("window.receiveSystemValues("..hs.json.encode({ok=ok,values=ok and values or {}})..")")
        end
        if body.action=="saveTabOrder" then
            local config={showMenu=app.general.showMenu,appearance=app.general.appearance,language=app.general.language,sleepShortcut=app.general.sleepShortcut,tabOrder=body.order or false}
            local validated,message=validateGeneral(config)
            if validated then hs.settings.set(generalKey,validated);app.general=validated end
            reply(validated~=nil,message or "",body.action)
        end
        if body.action == "load" then
            reply(true, "", "load")
            if app.settingsSection then app.settings:evaluateJavaScript("window.showSection(" .. hs.json.encode({app.settingsSection}) .. "[0])") end
            if app.settingsFocus then app.settings:evaluateJavaScript("document.getElementById("..hs.json.encode({app.settingsFocus}).."[0]).focus()") end
        end
        if body.action=="exportConfiguration" or body.action=="exportDefaults" then
            local success,result=exportConfiguration(body.action=="exportDefaults")
            if success~=nil then reply(success,result,body.action) end
        end
        if body.action=="chooseConfiguration" then
            app.pendingConfiguration=nil
            app.settings:evaluateJavaScript("window.previewConfiguration(null)")
            local path=selectedPath(hs.dialog.chooseFileOrFolder(i18n.t("选择 JSON 配置文件"),os.getenv("HOME"),true,false,false,{"json"},true))
            if type(path)=="string" and path~="" then
                local file=io.open(path,"r")
                if not file then reply(false,i18n.t("无法读取配置文件"),body.action);return end
                local text=file:read(1048577);file:close()
                if not text or #text>1048576 then reply(false,i18n.t("配置文件不得超过 1 MB"),body.action);return end
                local decoded,document=pcall(hs.json.decode,text)
                if not decoded or type(document)~="table" then reply(false,i18n.t("JSON 格式无效"),body.action);return end
                local plan,result=app.configuration.prepare(document)
                if not plan then reply(false,result,body.action);return end
                app.pendingConfiguration=document
                app.settings:evaluateJavaScript("window.previewConfiguration("..hs.json.encode(document)..")")
                reply(true,i18n.t("请核对将替换的模块，再确认导入"),body.action)
            end
        end
        if body.action=="cancelConfiguration" then app.pendingConfiguration=nil;app.settings:evaluateJavaScript("window.previewConfiguration(null)") end
        if body.action=="applyConfiguration" and app.pendingConfiguration then
            local success,result,selected=app.configuration.apply(app.pendingConfiguration)
            if success then
                app.pendingConfiguration=nil
                app.settings:evaluateJavaScript("window.importedModules="..hs.json.encode(selected)..";window.previewConfiguration(null)")
            end
            reply(success,result,body.action)
        end
        if body.action == "saveLauncher" then local success,result=launcher.save(body.config);reply(success,result,body.action) end
        if body.action == "setShowMenu" then local success,result=app.setShowMenu(body.enabled); reply(success,result,body.action) end
        if body.action == "saveGeneral" then local success,result=app.saveGeneralPage(body.config,body.autoLaunch);reply(success,result,body.action) end
        if body.action == "save" then local success, result = app.save(body.config); reply(success, result, body.action) end
        if body.action == "savePopup" then local success, result = app.savePopup(body.config); reply(success, result, body.action) end
        if body.action == "saveBrowser" then local success, result = browser.save(body.config); reply(success, result, body.action) end
        if body.action == "saveSystem" then local success, result = system.save(body.config); reply(success, result, body.action) end
        if body.action == "saveInput" then local success, result = input.save(body.config); reply(success, result, body.action) end
        if body.action == "saveClipboard" then local success,result=app.saveClipboardPage(body.config,body.popupShortcut);reply(success,result,body.action) end
        if body.action == "pauseClipboard" then local success, result = clipboard.pause(); reply(success, result, body.action) end
        if body.action == "refreshClipboard" then reply(true, "", body.action) end
        if body.action == "previewClipboard" then
            local value, result = clipboard.preview(body.id)
            if value then app.settings:evaluateJavaScript("window.showImage("..hs.json.encode(value)..")") else reply(false,result,body.action) end
        end
        if body.action == "copyClipboard" then local success, result = clipboard.copy(body.id); reply(success, result, body.action) end
        if body.action == "clearClipboard" then local success, result = clipboard.confirmClear(); reply(success~=false, result or "", body.action) end
        if body.action == "chooseApp" or body.action == "chooseBrowserApp" or body.action == "chooseLauncherApp" or body.action == "chooseExcludedApp" then
            local prompt=body.action=="chooseExcludedApp" and i18n.t("选择不记录剪贴板的应用") or body.action=="chooseLauncherApp" and i18n.t("选择要启动的应用") or body.action=="chooseBrowserApp" and i18n.t("选择链接来源应用") or i18n.t("选择要配置输入法的应用")
            local paths = hs.dialog.chooseFileOrFolder(prompt, "/Applications", true, false, false, {"app"}, true)
            local path = paths
            if type(paths)=="table" then path=paths[1] or paths["1"] end
            if type(path)=="string" and path ~= "" then
                local info = hs.application.infoForBundlePath(path)
                if info and info.CFBundleIdentifier then
                    local value = {icon=appIcons.get(info.CFBundleIdentifier,true),bundleID=info.CFBundleIdentifier,name=appNames.get(info.CFBundleIdentifier,nil,path,info)}
                    local callback=body.action=="chooseExcludedApp" and "window.addExcludedApp(" or body.action=="chooseLauncherApp" and "window.addLauncherRule(" or body.action=="chooseBrowserApp" and "window.addBrowserAppRule(" or "window.addInputRule("
                    if body.action=="chooseLauncherApp" and type(body.replaceBundleID)=="string" then
                        app.settings:evaluateJavaScript("window.replaceLauncherApp("..hs.json.encode(value)..","..hs.json.encode({body.replaceBundleID}).."[0])")
                    else app.settings:evaluateJavaScript(callback .. hs.json.encode(value) .. ",true)") end
                    reply(true,"","refreshApplications")
                else reply(false, i18n.t("无法识别所选应用")) end
            end
        end
    end)
    local file = assert(io.open(root .. "settings.html", "r"))
    local html = file:read("*a"); file:close()
    app.settings = hs.webview.new({x=180,y=160,w=980,h=720}, {}, app.controller)
        :windowStyle({"titled","closable","resizable"}):windowTitle("Nivlet for Mac")
        :transparent(false):allowTextEntry(true):html(html)
        :windowCallback(function(event)
            if event=="shouldClose" then app.requestLeave("close");return false end
            if event=="closing" then hs.dockicon.hide() end
        end)
    showSettingsWindow(app.settings)
end
app.menu = hs.menubar.new(true,"NivletMain"):setTitle(""):setTooltip(i18n.t("Nivlet 设置"))
if hs.image then
    app.mainIcon=assert(hs.image.imageFromPath(root.."assets/nivlet-menu.png")):size({w=18,h=18})
    app.menu:setIcon(app.mainIcon,true)
end
function app.updateMenu()
    app.menu:setTooltip(i18n.t("Nivlet 设置")):setMenu(nil)
    app.menu:setMenu({{title=i18n.t("设置…"),fn=app.openSettings},{title=i18n.t("退出 Nivlet"),fn=function() app.requestLeave("quit") end}})
end
app.updateMenu()
if not app.general.showMenu then app.menu:removeFromMenuBar() end
clipboard.startMenu(function(mode)
    local id=mode=="settings" and "clipEnabled" or "clipSearch"
    app.openSettings("clipSection",id)
end)
if popupConflicts(app.popupShortcut, app.config) then
    hs.alert.show(i18n.t("剪贴板菜单快捷键与窗口配置冲突，未启用菜单绑定"))
else
    local installed, errorMessage = installPopup(app.popupShortcut)
    if not installed then hs.alert.show(errorMessage) end
end
launcher.start(function(shortcut) return sleep.conflicts(shortcut) or sameShortcut(shortcut,app.popupShortcut) or (shortcut and popupConflicts(shortcut,app.config)) end)
system.start(function() app.openSettings("systemSection") end)
-- New status items are placed to the left: create/restore Main, Clipboard, then System Info.
function app.arrangeMenus()
    clipboard.menu:removeFromMenuBar():returnToMenuBar():setTitle("")
        :setIcon(assert(hs.image.imageFromPath(root.."assets/document.on.clipboard.png")):size({w=18,h=18}),true)
        :setTooltip(i18n.t("Nivlet 剪贴板历史"))
    system.menu:removeFromMenuBar():returnToMenuBar()
    if system.draw then system.draw() end
end
if app.general.showMenu then app.arrangeMenus() end
hs.dockIconClickCallback = function()
    if app.settings then app.openSettings() else app.openSettings("generalSection") end
end
print("Nivlet ready", hs.configdir, hs.settings.bundleID, "bindings", #app.bindings)

-- Route the embedded runtime API to the same settings page.
hs.openPreferences=function() app.openSettings("generalSection") end

if app.general.sleepShortcut then local success,result=app.saveGeneral(app.general);if not success then hs.alert.show(result) end end

-- The installer can fail after the previous application process has exited.
function app.showUpdateRecovery()
    if hs.nivletTakeUpdateRecovery and hs.nivletTakeUpdateRecovery() then
        hs.timer.doAfter(0,function()
            local choice=hs.dialog.blockAlert(i18n.t("上次更新未完成"),i18n.t("当前仍在运行原版本。可以重新检查更新，或从官网下载新版。"),i18n.t("检查更新…"),i18n.t("稍后"),"warning")
            if choice==i18n.t("检查更新…") then app.openSettings("aboutSection") end
        end)
    end
end
app.showUpdateRecovery()
permissions.watch(function() reply(true,"","refreshPermissionsSilent") end)
