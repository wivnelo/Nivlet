local i18n=require('modules.i18n')
local preferences=require('modules.preferences')
local M={config={enabled=false,rules={}},bindings={}}
local settingsKey='desktoptoolkit.launcher.v1'
function M.validate(value)
    if type(value)~='table' or type(value.enabled)~='boolean' or type(value.rules)~='table' then return nil,i18n.t('应用启动设置格式无效') end
    local result,apps,shortcuts={enabled=value.enabled,rules={}}, {}, {}
    for _,rule in ipairs(value.rules) do
        if type(rule)~='table' or type(rule.bundleID)~='string' or not rule.bundleID:match('^[%w_%-]+%.[%w_.%-]+$') then return nil,i18n.t('请选择要启动的应用') end
        if apps[rule.bundleID:lower()] then return nil,i18n.t('同一应用只能配置一个启动快捷键') end
        local config,message=preferences.validate({enabled=false,shortcuts={left=rule.shortcut}})
        if not config then return nil,message end
        local shortcut=config.shortcuts.left
        if shortcut then
            local signature=table.concat(shortcut.mods,'+')..'+'..shortcut.key
            if shortcuts[signature] then return nil,i18n.t('不同应用不能使用相同快捷键') end
            shortcuts[signature]=true
        end
        apps[rule.bundleID:lower()]=true
        table.insert(result.rules,{bundleID=rule.bundleID,name=type(rule.name)=='string' and rule.name or rule.bundleID,shortcut=shortcut})
    end
    return result
end
function M.conflicts(shortcut)
    if not shortcut then return false end
    for _,rule in ipairs(M.config.rules) do
        local other=rule.shortcut
        if other and shortcut.key==other.key and table.concat(shortcut.mods,'+')==table.concat(other.mods,'+') then return true end
    end
    return false
end
function M.open(bundleID)
    if not hs.application.pathForBundleID(bundleID) then return false,i18n.t('应用不可用，请重新选择：')..bundleID end
    if not hs.application.launchOrFocusByBundleID(bundleID) then return false,i18n.t('无法启动应用：')..bundleID end
    return true
end
local function clearBindings()
    for _,binding in ipairs(M.bindings) do binding:delete() end
    M.bindings={}
end
local feedback
local function notify(message)
    if feedback then hs.alert.closeSpecific(feedback,0) end
    feedback=hs.alert.show(message,{textSize=18,radius=10,padding=14,fadeInDuration=0.1,fadeOutDuration=0.15},1.5)
end
local function shortcutLabel(shortcut)
    local symbols={ctrl='⌃',alt='⌥',cmd='⌘',shift='⇧',left='←',right='→',up='↑',down='↓',['return']='↩'}
    local parts={}
    for _,mod in ipairs(shortcut.mods) do table.insert(parts,symbols[mod]) end
    table.insert(parts,symbols[shortcut.key] or shortcut.key:upper())
    return table.concat(parts)
end
local function install(config)
    if not config.enabled then return true end
    for _,rule in ipairs(config.rules) do
        local shortcut=rule.shortcut
        if shortcut then
            if M.externalConflict(shortcut) then clearBindings();return false,i18n.t('应用快捷键与窗口管理或剪贴板菜单重复') end
            if preferences.systemAssigned(shortcut.mods,shortcut.key) or not hs.hotkey.assignable(shortcut.mods,shortcut.key) then clearBindings();return false,i18n.t('快捷键被系统占用或无法注册：')..shortcut.key end
            local bundleID=rule.bundleID
            local binding=hs.hotkey.bind(shortcut.mods,shortcut.key,function()
                local running=#hs.application.applicationsForBundleID(bundleID)>0
                local prefix=shortcutLabel(shortcut)..' · '
                notify(prefix..i18n.t(running and '正在切换到：' or '正在启动：')..rule.name)
                local ok,message=M.open(bundleID)
                if not ok then notify(prefix..message) end
            end)
            if not binding then clearBindings();return false,i18n.t('应用快捷键注册失败') end
            table.insert(M.bindings,binding)
        end
    end
    return true
end
function M.save(value)
    local config,message=M.validate(value)
    if not config then return false,message end
    for _,rule in ipairs(config.rules) do
        if M.externalConflict(rule.shortcut) then return false,i18n.t('应用快捷键与窗口管理或剪贴板菜单重复') end
    end
    clearBindings()
    local ok,errorMessage=install(config)
    if not ok then
        local restored=install(M.config)
        return false,restored and errorMessage or errorMessage..i18n.t('；旧快捷键也无法恢复，请重新配置')
    end
    M.config=config
    hs.settings.set(settingsKey,config)
    return true,i18n.t('应用启动设置已保存')
end
function M.start(externalConflict)
    M.externalConflict=externalConflict
    M.config=M.validate(hs.settings.get(settingsKey)) or {enabled=false,rules={}}
    clearBindings()
    local ok,message=install(M.config)
    if not ok then hs.alert.show(message) end
end
return M
