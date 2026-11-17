-- Screenshot and annotation. The overlay runs in a separate helper (Native/capture) that stays alive
-- while the module is enabled; this module owns the shortcut, settings and output feedback.
local i18n=require('modules.i18n')
local preferences=require('modules.preferences')
local M={bindings={},buffer=''}
local settingsKey='desktoptoolkit.capture.v1'
local formats={png=true,jpg=true}

function M.defaults()
    return {enabled=false,shortcut={key='F1',mods={}},saveDirectory='~/Pictures/Nivlet',format='png',snapWindows=true,loupe=true}
end

-- F1–F19 may be used without modifiers here only; other keys follow the shared rules.
function M.normalizeShortcut(value)
    if value==nil or value==false then return nil end
    if type(value)~='table' or type(value.key)~='string' or type(value.mods)~='table' then return nil,i18n.t('快捷键格式无效') end
    local key=value.key:upper()
    if key:match('^F%d%d?$') and tonumber(key:sub(2))>=1 and tonumber(key:sub(2))<=19 then
        local flags={}
        for _,mod in ipairs(value.mods) do
            if mod~='ctrl' and mod~='alt' and mod~='cmd' and mod~='shift' then return nil,i18n.t('未知修饰键') end
            flags[mod]=true
        end
        local mods={}
        for _,mod in ipairs({'ctrl','alt','cmd','shift'}) do if flags[mod] then table.insert(mods,mod) end end
        return {key=key,mods=mods}
    end
    return preferences.normalize(value)
end

function M.validate(value)
    if type(value)~='table' or type(value.enabled)~='boolean' then return nil,i18n.t('截图设置格式无效') end
    local shortcut,message=M.normalizeShortcut(value.shortcut)
    if message then return nil,message end
    local dir=value.saveDirectory
    if type(dir)~='string' or dir=='' or #dir>1024 or not (dir:sub(1,1)=='/' or dir:sub(1,2)=='~/') then return nil,i18n.t('保存位置无效') end
    if not formats[value.format] then return nil,i18n.t('截图格式无效') end
    for _,field in ipairs({'snapWindows','loupe'}) do
        if value[field]~=nil and type(value[field])~='boolean' then return nil,i18n.t('截图设置格式无效') end
    end
    return {enabled=value.enabled,shortcut=shortcut or false,saveDirectory=dir,format=value.format,snapWindows=value.snapWindows~=false,loupe=value.loupe~=false}
end

function M.conflicts(shortcut)
    return shortcut and M.config and M.config.enabled and M.config.shortcut and preferences.same(shortcut,M.config.shortcut) or false
end

local function helperPath() return hs.processInfo.bundlePath..'/Contents/Resources/Toolkit/capture-helper' end

local function send(command)
    if M.task and M.task:isRunning() then M.task:setInput(hs.json.encode(command)..'\n');return true end
    return false
end

local feedback
local function notify(message)
    if feedback then hs.alert.closeSpecific(feedback,0) end
    feedback=hs.alert.show(message,{textSize=16,radius=10,padding=12,fadeInDuration=0.1,fadeOutDuration=0.15},1.6)
end

local function strings()
    local keys={rect='矩形',arrow='箭头',pen='画笔',text='文字',mosaic='马赛克',undo='撤销',redo='重做',save='保存',cancel='取消',copy='复制',pixelate='像素化',blackout='涂黑',copyColorHint='C 复制颜色'}
    local result={}
    for k,v in pairs(keys) do result[k]=i18n.t(v) end
    return result
end

local function sendConfig()
    local c=M.config
    send({cmd='config',saveDirectory=c.saveDirectory,format=c.format,snapWindows=c.snapWindows,loupe=c.loupe,strings=strings(),appearance=M.appearance and M.appearance() or 'system'})
end

local function handleEvent(event)
    local kind=event.event
    if kind=='ready' then
        M.ready=true
        if type(event.permission)=='boolean' then M.permission=event.permission end
        sendConfig()
        if M.pending then M.pending=false;send({cmd='capture'}) end
    elseif kind=='copied' then
        if M.onCopied then M.onCopied() end
    elseif kind=='saved' then
        notify(i18n.t('截图已保存：')..(event.path or ''):match('[^/]*$'))
    elseif kind=='color' then
        if M.onCopied then M.onCopied() end
        notify(i18n.t('已复制颜色 ')..tostring(event.value))
    elseif kind=='permission' then
        M.permission=false
        notify(i18n.t('截图需要屏幕录制权限。请在系统设置中允许 Nivlet，然后再按一次快捷键。'))
        if M.onPermission then M.onPermission() end
    elseif kind=='error' then
        local messages={save=i18n.t('截图保存失败，请检查保存位置'),copy=i18n.t('截图复制失败，请重试'),capture=i18n.t('截屏失败，请重试')}
        notify(messages[event.message] or i18n.t('截图失败，请重试'))
    end
end

local function onOutput(_,stdout)
    M.buffer=M.buffer..(stdout or '')
    while true do
        local line,rest=M.buffer:match('^([^\n]*)\n(.*)$')
        if not line then break end
        M.buffer=rest
        local ok,event=pcall(hs.json.decode,line)
        if ok and type(event)=='table' then handleEvent(event) end
    end
    return true
end

function M.startHelper()
    if M.task and M.task:isRunning() then return true end
    local path=helperPath()
    if not hs.fs.attributes(path) then return false,i18n.t('截图组件缺失，请重新安装 Nivlet') end
    M.ready=false;M.buffer=''
    M.task=hs.task.new(path,function() M.task=nil;M.ready=false end,onOutput,{})
    if not M.task or not M.task:start() then M.task=nil;return false,i18n.t('无法启动截图组件') end
    return true
end

function M.stopHelper()
    local task=M.task
    M.task=nil;M.ready=false;M.pending=false
    if task and task:isRunning() then task:setInput(hs.json.encode({cmd='quit'})..'\n');task:closeInput() end
end

function M.trigger()
    if M.task and M.task:isRunning() and M.ready then sendConfig();send({cmd='capture'});return end
    M.pending=true
    local ok,message=M.startHelper()
    if not ok then M.pending=false;notify(message) end
end

local function clearBindings()
    for _,binding in ipairs(M.bindings) do binding:delete() end
    M.bindings={}
end
M.releaseBindings=clearBindings

local function install(config)
    if not config.enabled then return true end
    local shortcut=config.shortcut
    if shortcut then
        if M.externalConflict and M.externalConflict(shortcut) then return false,i18n.t('截图快捷键与其他快捷键重复') end
        if not preferences.bindable(shortcut.mods,shortcut.key:lower()) then return false,i18n.t('截图快捷键被系统占用或无法注册') end
        local binding=hs.hotkey.bind(shortcut.mods,shortcut.key:lower(),M.trigger)
        if not binding then return false,i18n.t('截图快捷键注册失败') end
        table.insert(M.bindings,binding)
    end
    return true
end

local function apply(config)
    clearBindings()
    local ok,message=install(config)
    if not ok then clearBindings();return false,message end
    if config.enabled then
        M.startHelper()
        if M.ready then sendConfig() end
    else
        M.stopHelper()
    end
    return true
end

function M.save(value)
    local config,message=M.validate(value)
    if not config then return false,message end
    local previous=M.config
    M.config=config
    local ok,errorMessage=apply(config)
    if not ok then
        M.config=previous
        local restored=apply(previous)
        return false,restored and errorMessage or errorMessage..i18n.t('；旧快捷键也无法恢复，请重新配置')
    end
    hs.settings.set(settingsKey,config)
    return true,i18n.t('截图设置已保存')
end

-- The runtime's hs.screenRecordingState guesses from readable window titles and reports "granted"
-- on recent macOS even when access is off, so ask the helper for the system's own answer instead.
-- nil means not checked yet.
function M.permissionGranted() return M.permission end

function M.checkPermission(callback)
    if M.permissionTask and M.permissionTask:isRunning() then return end
    local path=helperPath()
    if not hs.fs.attributes(path) then return end
    M.permissionTask=hs.task.new(path,function(_,stdout)
        M.permissionTask=nil
        local answer=stdout and stdout:match('(%a+)')
        if answer=='granted' then M.permission=true elseif answer=='denied' then M.permission=false end
        if callback then callback(M.permission) end
    end,{'--permission'})
    if not M.permissionTask or not M.permissionTask:start() then M.permissionTask=nil end
end

-- Shows the system prompt the first time (it lists Nivlet); afterwards macOS only allows changes in System Settings.
function M.requestPermission(callback)
    if hs.screenRecordingState then hs.screenRecordingState(true) end
    M.checkPermission(callback)
end

function M.start(externalConflict,callbacks)
    M.externalConflict=externalConflict
    callbacks=callbacks or {}
    M.onCopied=callbacks.copied
    M.onPermission=callbacks.permission
    M.appearance=callbacks.appearance
    M.config=M.validate(hs.settings.get(settingsKey)) or M.defaults()
    local ok,message=apply(M.config)
    if not ok then hs.alert.show(message) end
end

function M.stop()
    clearBindings()
    M.stopHelper()
end

return M
