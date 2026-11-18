-- Selected-text translation with macOS system translation only (on device).
-- Double-tapping a modifier reads the selection and asks the native helper (shared with screenshots)
-- to show a translation card. The key watcher runs only while this module is on and only reacts to
-- modifier changes, so typing elsewhere costs next to nothing.
local i18n=require('modules.i18n')
local M={memory={}}
local settingsKey='desktoptoolkit.translate.v1'
local memoryKey='desktoptoolkit.translate.memory.v1'
-- Trigger → modifier and side. Key codes tell left from right: ⌘ 55/54, ⌥ 58/61, ⌃ 59/62.
local triggers={off=false}
local keyCodes={cmd={left=55,right=54},alt={left=58,right=61},ctrl={left=59,right=62}}
for _,mod in ipairs({'Alt','Cmd','Ctrl'}) do
    local m=mod:lower()
    triggers['double'..mod]={mod=m}
    triggers['doubleLeft'..mod]={mod=m,side='left'}
    triggers['doubleRight'..mod]={mod=m,side='right'}
end
-- Two triggers clash when they use the same modifier and either accepts that side.
function M.triggersOverlap(a,b)
    local x,y=triggers[a],triggers[b]
    if not x or not y or x.mod~=y.mod then return false end
    return not x.side or not y.side or x.side==y.side
end
local modes={auto=true,['zh-Hans']=true,['zh-Hant']=true,en=true,ja=true,ko=true}
local tapWindow,pressWindow=0.4,0.35

function M.defaults()
    return {enabled=false,selectionTrigger='doubleAlt',screenshotTrigger='doubleCtrl',mode='auto',remember=true,showSource=true,autoCopy=false}
end

function M.validate(value)
    if type(value)~='table' or type(value.enabled)~='boolean' then return nil,i18n.t('翻译设置格式无效') end
    local trigger=value.selectionTrigger or 'doubleAlt'
    if triggers[trigger]==nil then return nil,i18n.t('翻译设置格式无效') end
    local shot=value.screenshotTrigger or 'doubleCtrl'
    if triggers[shot]==nil then return nil,i18n.t('翻译设置格式无效') end
    if M.triggersOverlap(trigger,shot) then return nil,i18n.t('选词翻译和截图翻译不能使用同一个按键') end
    local mode=value.mode or 'auto'
    if not modes[mode] then return nil,i18n.t('翻译设置格式无效') end
    for _,field in ipairs({'remember','showSource','autoCopy'}) do
        if value[field]~=nil and type(value[field])~='boolean' then return nil,i18n.t('翻译设置格式无效') end
    end
    return {enabled=value.enabled,selectionTrigger=trigger,screenshotTrigger=shot,mode=mode,remember=value.remember~=false,showSource=value.showSource~=false,autoCopy=value.autoCopy==true}
end

-- System translation needs macOS 15.
function M.supported()
    if not (hs.host and hs.host.operatingSystemVersion) then return false end
    local ok,version=pcall(hs.host.operatingSystemVersion)
    return ok and type(version)=='table' and (version.major or 0)>=15
end

local feedback
local function notify(message)
    if feedback then hs.alert.closeSpecific(feedback,0) end
    feedback=hs.alert.show(message,{textSize=16,radius=10,padding=12,fadeInDuration=0.1,fadeOutDuration=0.15},1.6)
end

local function primaryHeight()
    local screen=hs.screen.primaryScreen()
    return screen and screen:fullFrame().h or 0
end

-- Selection and an anchor point (Cocoa coordinates, just below the selection) via Accessibility.
local function selectionFromAccessibility()
    if not hs.axuielement then return nil end
    local ok,element=pcall(function() return hs.axuielement.systemWideElement():attributeValue('AXFocusedUIElement') end)
    if not ok or not element then return nil end
    local text=element:attributeValue('AXSelectedText')
    if type(text)~='string' or text:match('^%s*$') then return nil end
    local editable=false
    pcall(function() editable=element:isAttributeSettable('AXSelectedText')==true end)
    local anchor
    pcall(function()
        local range=element:attributeValue('AXSelectedTextRange')
        local bounds=range and element:parameterizedAttributeValue('AXBoundsForRange',range)
        if type(bounds)=='table' and bounds.h and bounds.h>0 then
            anchor={x=bounds.x,y=primaryHeight()-(bounds.y+bounds.h)}
        end
    end)
    return text,anchor,editable
end

local function mouseAnchor()
    local p=hs.mouse.absolutePosition()
    return {x=p.x,y=primaryHeight()-p.y-12}
end

-- Fallback for apps without Accessibility text: copy the selection, read it, then put the
-- previous clipboard back. Clipboard history is suspended so neither change is recorded.
local function selectionFromCopy(done)
    local clipboard=M.clipboard
    local saved=hs.pasteboard.readAllData()
    local before=hs.pasteboard.changeCount()
    if clipboard then clipboard.suspend(2) end
    hs.eventtap.keyStroke({'cmd'},'c',0)
    local attempts=0
    local function finish(text)
        if saved and next(saved) then hs.pasteboard.writeAllData(saved) else hs.pasteboard.clearContents() end
        if clipboard then hs.timer.doAfter(0.6,clipboard.resume) end
        done(text)
    end
    local function check()
        attempts=attempts+1
        if hs.pasteboard.changeCount()~=before then
            local text=hs.pasteboard.getContents()
            finish(type(text)=='string' and not text:match('^%s*$') and text or nil)
        elseif attempts<8 then hs.timer.doAfter(0.04,check)
        else finish(nil) end
    end
    hs.timer.doAfter(0.04,check)
end

local function send(text,anchor,editable)
    local c=M.config
    M.capture.dispatch({cmd='translate',text=text,x=anchor.x,y=anchor.y,mode=c.mode,remembered=c.remember and M.memory or {},showSource=c.showSource,autoCopy=c.autoCopy,editable=editable==true})
end

function M.translateSelection()
    local text,anchor,editable=selectionFromAccessibility()
    if text then send(text,anchor or mouseAnchor(),editable);return end
    selectionFromCopy(function(copied)
        if copied then send(copied,mouseAnchor(),false) else notify(i18n.t('没有读取到选中的文字')) end
    end)
end

-- Double tap: the modifier alone, pressed and released twice within tapWindow, with no other key
-- or modifier in between. Holding it, or using it in a shortcut, never triggers.
-- `side` limits the trigger to the left or right key (nil: either).
function M.newTapDetector(modifier,onDoubleTap,clock,side)
    local wanted=side and keyCodes[modifier] and keyCodes[modifier][side]
    local state={down=false,clean=false,downAt=0,lastTap=nil}
    local detector={}
    function detector.flags(flags,keyCode)
        local now=clock()
        local count,only=0,false
        for name,on in pairs(flags) do if on and name~='fn' then count=count+1 end end
        only=count==1 and flags[modifier]==true and (not wanted or keyCode==wanted)
        if only and not state.down then
            state.down=true;state.clean=true;state.downAt=now
        elseif count==0 and state.down then
            state.down=false
            if state.clean and now-state.downAt<=pressWindow then
                if state.lastTap and now-state.lastTap<=tapWindow then state.lastTap=nil;onDoubleTap()
                else state.lastTap=now end
            else state.lastTap=nil end
        elseif not only then
            state.down=count>0 and state.down;state.clean=false;state.lastTap=nil
        end
    end
    function detector.key() state.clean=false;state.lastTap=nil end
    return detector
end

local function stopWatcher()
    if M.watcher then M.watcher:stop();M.watcher=nil end
end

function M.translateScreenshot() M.capture.dispatch({cmd='captureTranslate'}) end

local function startWatcher(config)
    stopWatcher()
    local detectors={}
    for _,item in ipairs({{config.selectionTrigger,M.translateSelection},{config.screenshotTrigger,M.translateScreenshot}}) do
        local trigger=triggers[item[1]]
        local action=item[2]
        if trigger then table.insert(detectors,M.newTapDetector(trigger.mod,function() hs.timer.doAfter(0,action) end,hs.timer.secondsSinceEpoch,trigger.side)) end
    end
    if #detectors==0 then return end
    local types=hs.eventtap.event.types
    M.watcher=hs.eventtap.new({types.flagsChanged,types.keyDown},function(event)
        if event:getType()==types.keyDown then for _,d in ipairs(detectors) do d.key() end
        else local flags,code=event:getFlags(),event:getKeyCode();for _,d in ipairs(detectors) do d.flags(flags,code) end end
        return false
    end)
    M.watcher:start()
end

local function apply(config)
    if config.enabled and M.supported() then
        startWatcher(config)
        M.capture.setUser('translate',true)
        -- Start the helper and load the common models once, so the first translation is quick.
        if not M.prewarmed then M.prewarmed=true;hs.timer.doAfter(3,function() M.capture.dispatch({cmd='prewarmTranslation'}) end) end
    else
        stopWatcher()
        M.capture.setUser('translate',false)
    end
end

function M.save(value)
    local config,message=M.validate(value)
    if not config then return false,message end
    if config.enabled and not M.supported() then return false,i18n.t('翻译需要 macOS 15 或更高版本') end
    M.config=config
    apply(config)
    hs.settings.set(settingsKey,config)
    if M.capture.refreshConfig then M.capture.refreshConfig() end
    return true,i18n.t('翻译设置已保存')
end

function M.clearMemory()
    M.memory={}
    hs.settings.set(memoryKey,{})
    if M.capture and M.capture.refreshConfig then M.capture.refreshConfig() end
    return true,i18n.t('已清除记住的翻译方向')
end

local function remember(event)
    if not (M.config and M.config.remember) then return end
    if type(event.source)~='string' or type(event.target)~='string' or #event.source>16 or #event.target>16 then return end
    M.memory[event.source]=event.target
    hs.settings.set(memoryKey,M.memory)
    if M.capture.refreshConfig then M.capture.refreshConfig() end
end

-- Preferences the helper needs for screenshot translation and the toolbar's Translate button.
local function prefs()
    local c=M.config
    if not (c and c.enabled and M.supported()) then return {enabled=false} end
    return {enabled=true,mode=c.mode,remembered=c.remember and M.memory or {},showSource=c.showSource,autoCopy=c.autoCopy}
end

-- Put the translation in place of the selection: paste it, then restore the clipboard.
local function replace(event)
    if type(event.text)~='string' or event.text=='' then return end
    local saved=hs.pasteboard.readAllData()
    if M.clipboard then M.clipboard.suspend(2) end
    hs.pasteboard.setContents(event.text)
    hs.eventtap.keyStroke({'cmd'},'v',0)
    hs.timer.doAfter(0.3,function()
        if saved and next(saved) then hs.pasteboard.writeAllData(saved) else hs.pasteboard.clearContents() end
        if M.clipboard then hs.timer.doAfter(0.6,M.clipboard.resume) end
    end)
end

function M.snapshot()
    return {config=M.config,supported=M.supported(),remembered=M.memory}
end

function M.start(capture,clipboard)
    M.capture=capture;M.clipboard=clipboard
    capture.handlers.directionChosen=remember
    capture.handlers.replaceSelection=replace
    capture.translatePrefs=prefs
    M.config=M.validate(hs.settings.get(settingsKey)) or M.defaults()
    local stored=hs.settings.get(memoryKey)
    M.memory=type(stored)=='table' and stored or {}
    apply(M.config)
end

function M.stop() stopWatcher() end

return M
