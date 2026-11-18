local i18n = require("modules.i18n")
local bundleIDs = require("modules.bundle_id")
local M = {entries={},nextID=0}
local settingsKey = "desktoptoolkit.clipboard.v1"
function M.defaults()
    return {enabled=false,limit=50,minutes=30,images=true,persistent=false,excluded={"com.apple.Passwords","com.1password.1password","com.agilebits.onepassword7","com.bitwarden.desktop"}}
end
function M.validate(value)
    if type(value)~="table" or type(value.enabled)~="boolean" or type(value.limit)~="number" or value.limit%1~=0 or value.limit<10 or value.limit>100 or type(value.minutes)~="number" or value.minutes%1~=0 or value.minutes<0 or value.minutes>1440 or type(value.excluded)~="table" then return nil,i18n.t("容量须为 10–100 条，保留时间须为 1–1440 分钟或 0（永久）") end
    if value.images~=nil and type(value.images)~="boolean" or value.persistent~=nil and type(value.persistent)~="boolean" or value.paused~=nil and type(value.paused)~="boolean" then return nil,i18n.t("图片和缓存设置格式无效") end


    local config,seen={enabled=value.enabled and value.paused~=true,limit=value.limit,minutes=value.minutes,images=value.images~=false,persistent=value.persistent==true,excluded={}},{}
    for _,id in ipairs(value.excluded) do
        if not bundleIDs.valid(id) then return nil,i18n.t("排除应用须填写有效 Bundle ID") end
        if not seen[id] then table.insert(config.excluded,id);seen[id]=true end
    end
    return config
end
local historyKey="desktoptoolkit.clipboard.history.v1"
local function directory() return hs.configdir.."/clipboard-history/" end
local function managed(path)
    local name=type(path)=="string" and path:sub(1,#directory())==directory() and path:sub(#directory()+1)
    return name and (name:match("^clip_%d+_%d+%.png$") or name:match("^clip_%d+_%d+%.preview%.png$")) and true or false
end
local function remove(entry)
    if managed(entry.path) then os.remove(entry.path);entry.path=nil end
    if managed(entry.previewPath) then os.remove(entry.previewPath);entry.previewPath=nil end
end
-- Small copies of an image, drawn once. Image objects only carry a display size, so the menu and the
-- settings page used to decode full screenshots (820 ms for the first ⌘⇧V menu with ten captures,
-- 1.6 MB per settings refresh). Now the full image is read only to copy, pin or open it.
local function shrink(image,maxW,maxH)
    local size=image and image:size()
    if not size or size.w<=0 or size.h<=0 then return nil end
    local scale=math.min(1,maxW/size.w,maxH/size.h)
    local w,h=math.max(1,math.floor(size.w*scale+.5)),math.max(1,math.floor(size.h*scale+.5))
    local canvas=hs.canvas.new({x=0,y=0,w=w,h=h})
    canvas[1]={type="image",image=image,imageScaling="scaleToFit",frame={x=0,y=0,w=w,h=h}}
    local small=canvas:imageFromCanvas();canvas:delete()
    return small
end
-- Full image: kept in memory for new copies, read from the history file for restored ones.
function M.imageOf(entry)
    if not entry.image and entry.kind=="image" and managed(entry.path) then entry.image=hs.image.imageFromPath(entry.path) end
    return entry.image
end
-- Menu-sized preview (≤360×260), stored next to the history file. Older records get one on first use.
local function previewOf(entry)
    if not entry.preview and entry.kind=="image" then
        local image=M.imageOf(entry)
        entry.preview=image and shrink(image,360,260)
        if image and not entry.width then local size=image:size();entry.width,entry.height=size.w,size.h end
        if entry.preview and entry.path and not entry.previewPath then M.pendingHistoryWrite=true end
    end
    return entry.preview
end
local function thumbOf(entry)
    if not entry.thumb and entry.kind=="image" then
        local preview=previewOf(entry)
        entry.thumb=preview and shrink(preview,120,120)
    end
    return entry.thumb
end
local function sizeOf(entry)
    if not entry.width then
        local size=M.imageOf(entry) and entry.image:size()
        if size then
            entry.width,entry.height=size.w,size.h
            if entry.path then M.pendingHistoryWrite=true end
        end
    end
    return entry.width,entry.height
end
local function ensureDirectory()
    local path=directory():sub(1,-2)
    local attr=hs.fs.symlinkAttributes(path)
    if attr then return attr.mode=="directory" end
    return hs.fs.mkdir(path)
end
local function historyPersisted()
    M.pendingHistoryWrite=nil;M.historyRetryAt=nil;M.historyPersistError=nil;M.historyErrorNotified=nil
end
function M.persist()
    if not M.config.persistent then
        hs.settings.clear(historyKey)
        for _,entry in ipairs(M.entries) do remove(entry) end
        historyPersisted()
        return true
    end
    local saved={}
    for _,entry in ipairs(M.entries) do
        if entry.kind=="image" then
            if not entry.path then
                local path=directory()..string.format("clip_%.0f_%d.png",entry.time*1000,entry.id)
                -- The clipboard's own PNG is written as is; re-encoding only for images that had none.
                if entry.png then
                    local file=io.open(path,"wb")
                    local written=file and file:write(entry.png)
                    if file then file:close() end
                    if not written then return false,i18n.t("图片缓存写入失败") end
                elseif not entry.image:saveToFile(path,true,"PNG") then return false,i18n.t("图片缓存写入失败") end
                entry.path=path
            end
            entry.png=nil
            local preview=entry.preview or entry.previewPath==nil and previewOf(entry)
            if preview and not entry.previewPath then
                local previewPath=entry.path:gsub("%.png$",".preview.png")
                if preview.saveToFile and preview:saveToFile(previewPath,true,"PNG") then entry.previewPath=previewPath end
            end
            -- Fingerprint and size are stored so startup never has to decode and re-encode images.
            table.insert(saved,{id=entry.id,kind="image",time=entry.time,path=entry.path,previewPath=entry.previewPath,width=entry.width,height=entry.height,source=entry.source,fingerprint=entry.fingerprint,bytes=entry.menuBytes})
        else table.insert(saved,{id=entry.id,kind="text",time=entry.time,text=entry.text}) end
    end
    if hs.settings.set(historyKey,saved)==false then return false,i18n.t("保存失败，请检查设置") end
    historyPersisted()
    return true
end
local function stopExpiryTimer()
    M.expiryGeneration=(M.expiryGeneration or 0)+1
    if M.expiryTimer then M.expiryTimer:stop();M.expiryTimer=nil end
    M.expiryAt=nil
end
local function maintainExpiryTimer()
    if M.stopped or not M.config or M.config.enabled then stopExpiryTimer();return end
    local nextExpiry
    if M.config.minutes>0 then
        for _,entry in ipairs(M.entries) do
            local expiry=entry.time+M.config.minutes*60
            nextExpiry=not nextExpiry and expiry or math.min(nextExpiry,expiry)
        end
    end
    if M.pendingHistoryWrite then
        local retry=M.historyRetryAt or hs.timer.secondsSinceEpoch()+5
        nextExpiry=not nextExpiry and retry or math.min(nextExpiry,retry)
    end
    if not nextExpiry then stopExpiryTimer();return end
    if M.expiryTimer and M.expiryAt==nextExpiry then return end
    stopExpiryTimer()
    local generation=M.expiryGeneration
    M.expiryAt=nextExpiry


    M.expiryTimer=hs.timer.doAfter(math.max(0.01,nextExpiry-hs.timer.secondsSinceEpoch()),function()
        if M.stopped or generation~=M.expiryGeneration then return end
        M.expiryTimer=nil;M.expiryAt=nil
        M.prune()
    end)
end
function M.prune()
    local changed=false
    local now=hs.timer.secondsSinceEpoch()
    local cutoff=now-M.config.minutes*60
    local imageCount,textCount=0,0
    for i=#M.entries,1,-1 do
        if M.config.minutes>0 and M.entries[i].time<=cutoff then remove(M.entries[i]);table.remove(M.entries,i);changed=true end
    end
    for _,entry in ipairs(M.entries) do
        if entry.kind=="image" then imageCount=imageCount+1 else textCount=textCount+1 end
    end
    if imageCount>10 or textCount>M.config.limit then
        local keep={}
        imageCount,textCount=0,0
        for _,entry in ipairs(M.entries) do
            if entry.kind=="image" then imageCount=imageCount+1 else textCount=textCount+1 end
            if entry.kind=="image" and imageCount>10 or entry.kind~="image" and textCount>M.config.limit then remove(entry);changed=true else table.insert(keep,entry) end
        end
        M.entries=keep
    end
    if changed then M.pendingHistoryWrite=true end
    if M.pendingHistoryWrite and (not M.historyRetryAt or now>=M.historyRetryAt) then
        local ran,ok,message=pcall(M.persist)
        if ran and ok then historyPersisted()
        else


            M.pendingHistoryWrite=true;M.historyRetryAt=now+5
            M.historyPersistError=ran and message or i18n.t("保存失败，请检查设置")
            if not M.historyErrorNotified and hs.alert and type(hs.alert.show)=="function" then
                M.historyErrorNotified=true
                pcall(hs.alert.show,M.historyPersistError)
            end
        end
    end
    maintainExpiryTimer()
    return not M.pendingHistoryWrite,M.historyPersistError
end
local function pngBytes(encoded)
    local base64=encoded and encoded:match("base64,(.*)")
    return base64 and math.floor(#base64*3/4)-(base64:match("==$") and 2 or base64:match("=$") and 1 or 0) or 0
end
function M.load()
    if not M.config.persistent then return end
    local saved=hs.settings.get(historyKey)
    if type(saved)~="table" then return end
    M.entries={}
    local expiredMissing,unresolved=false,false
    local cutoff=hs.timer.secondsSinceEpoch()-M.config.minutes*60
    for _,entry in ipairs(saved) do
        local item
        local validTime=type(entry)=="table" and type(entry.time)=="number" and entry.time>-math.huge and entry.time<math.huge
        if validTime and type(entry.id)=="number" and entry.id>0 and entry.id%1==0 then
            if entry.kind=="text" and type(entry.text)=="string" and #entry.text<=65536 then item={id=entry.id,time=entry.time,kind="text",text=entry.text} end
            if entry.kind=="image" and managed(entry.path) then
                local attr=hs.fs.symlinkAttributes(entry.path)
                if attr and attr.mode=="file" and attr.size<=10485760 then
                    -- Restoring used to re-encode every image to PNG/base64 for a fingerprint, which
                    -- pushed startup past 2 GB with full-screen captures. Saved records now carry the
                    -- fingerprint; older ones simply are not de-duplicated against new copies.
                    -- The full image stays on disk until it is copied, pinned or opened; the menu and the
                    -- settings page use the small stored preview.
                    local fingerprint=type(entry.fingerprint)=="string" and entry.fingerprint or nil
                    local bytes=type(entry.bytes)=="number" and entry.bytes or attr.size
                    local previewPath=managed(entry.previewPath) and entry.previewPath or nil
                    local preview=previewPath and hs.fs.symlinkAttributes(previewPath) and hs.image.imageFromPath(previewPath) or nil
                    local width=type(entry.width)=="number" and entry.width>0 and entry.width or nil
                    local height=width and type(entry.height)=="number" and entry.height>0 and entry.height or nil
                    item={id=entry.id,time=entry.time,kind="image",path=entry.path,previewPath=preview and previewPath or nil,preview=preview,width=height and width,height=height,source=entry.source=="capture" and "capture" or nil,fingerprint=fingerprint,menuBytes=bytes}
                    if not preview and not M.imageOf(item) then item=nil end
                end
            end
        end
        if item then M.nextID=math.max(M.nextID,item.id);table.insert(M.entries,item)
        elseif validTime and M.config.minutes>0 and entry.time<=cutoff then expiredMissing=true
        else unresolved=true end
    end



    if expiredMissing and not unresolved then M.pendingHistoryWrite=true end
    M.prune()
end
-- Written by the capture helper next to its PNG so history can label screenshots.
local captureMarker="dev.nivlet.capture"
local ignored={['org.nspasteboard.ConcealedType']=true,['org.nspasteboard.TransientType']=true,['org.nspasteboard.AutoGeneratedType']=true,['public.file-url']=true}
-- Translation reads the selection with a temporary ⌘C and restores the clipboard afterwards;
-- changes made during that window are skipped so they never enter history.
function M.suspend(seconds)
    M.suspendedUntil=hs.timer.secondsSinceEpoch()+(seconds or 1)
end
function M.resume()
    M.suspendedUntil=nil
    M.lastCount=hs.pasteboard.changeCount()
end
function M.poll()
    if M.stopped then return end
    M.prune()
    if not M.config.enabled then return end
    local count=hs.pasteboard.changeCount()
    if M.suspendedUntil then
        if hs.timer.secondsSinceEpoch()<M.suspendedUntil then M.lastCount=count;return end
        M.suspendedUntil=nil;M.lastCount=count;return
    end
    if count==M.lastCount then return end
    M.lastCount=count
    local application=hs.application.frontmostApplication()
    local bundle=application and application:bundleID()
    for _,id in ipairs(M.config.excluded) do if bundle==id then return end end
    local source
    for _,kind in ipairs(hs.pasteboard.contentTypes() or {}) do
        if ignored[kind] then return end
        if kind==captureMarker then source="capture" end
    end
    local image=M.config.images and hs.pasteboard.readImage() or nil
    local value,fingerprint,bytes,png,width,height
    if image then
        local size=image:size()
        if size.w<=0 or size.h<=0 or size.w*size.h>25000000 then return end
        -- Fingerprint and size come from the clipboard's own PNG bytes. Re-encoding the image to
        -- PNG/base64 for this pushed memory past 2 GB for a single full-screen capture.
        png=hs.pasteboard.readDataForUTI and hs.pasteboard.readDataForUTI("public.png") or nil
        if type(png)=="string" and #png>0 then
            if #png>10485760 then return end
            fingerprint="png:"..hs.hash.SHA256(png)
            bytes=#png
        else
            png=nil
            local encoded=image:encodeAsURLString(true,"PNG")
            if not encoded or #encoded>13981070 then return end
            fingerprint=hs.hash.SHA256(encoded)
            bytes=pngBytes(encoded)
        end
        width,height=size.w,size.h
    else
        value=hs.pasteboard.getContents()
        if type(value)~="string" or value=="" or #value>65536 then return end
    end
    if hs.pasteboard.changeCount()~=count then return end
    for i=#M.entries,1,-1 do
        local entry=M.entries[i]
        if value and entry.text==value or fingerprint and entry.fingerprint==fingerprint then remove(entry);table.remove(M.entries,i) end
    end
    M.nextID=M.nextID+1
    -- PNG bytes are kept only until the history file is written (persistent history only).
    table.insert(M.entries,1,{id=M.nextID,kind=image and "image" or "text",source=image and source or nil,text=value,image=image,width=width,height=height,fingerprint=fingerprint,menuBytes=bytes,png=M.config.persistent and png or nil,time=hs.timer.secondsSinceEpoch()})


    M.pendingHistoryWrite=true
    M.prune()
end
function M.stop()
    M.stopped=true
    if M.timer then M.timer:stop();M.timer=nil end
    stopExpiryTimer()
end
function M.configure(config)
    M.stop();M.stopped=false
    M.config=config
    if config.enabled then
        M.lastCount=hs.pasteboard.changeCount()
        M.prune()
        M.timer=hs.timer.doEvery(0.5,M.poll)
    else
        if #M.entries>0 then M.prune() else maintainExpiryTimer() end
    end
end
function M.save(value)
    local config,message=M.validate(value)
    if not config then return false,message end
    if config.persistent and not ensureDirectory() then return false,i18n.t("无法创建独立剪贴板缓存目录") end
    local old=M.config
    M.config=config
    local ok,errorMessage=M.persist()
    if not ok then M.config=old;return false,errorMessage end
    M.configure(config);hs.settings.set(settingsKey,config)
    return true,i18n.t("剪贴板设置已保存")
end
function M.copy(id,target)
    M.prune()
    for _,entry in ipairs(M.entries) do
        if entry.id==id then
            if target and not require("modules.permissions").isGranted() then return false,i18n.t("直接粘贴需要辅助功能权限，请前往通用设置检查") end
            local ok
            if entry.kind=="image" then local image=M.imageOf(entry);ok=image and hs.pasteboard.writeObjects(image) else ok=hs.pasteboard.setContents(entry.text) end
            if not ok then return false,i18n.t("复制失败") end
            M.lastCount=hs.pasteboard.changeCount()
            if target then hs.timer.doAfter(0.15,function() if target:isRunning() then hs.eventtap.keyStroke({"cmd"},"v",0,target) end end) end
            return true,target and i18n.t("已复制并请求粘贴") or i18n.t("已复制，请在目标应用手动粘贴")
        end
    end
    return false,i18n.t("记录已过期或被清除")
end
function M.clear() for _,entry in ipairs(M.entries) do remove(entry) end;M.entries={};M.persist();maintainExpiryTimer();return true,i18n.t("历史已清空") end
function M.confirmClear()
    if hs.dialog.blockAlert(i18n.t("清空剪贴板历史？"),i18n.t("将删除 Nivlet 的全部剪贴板历史和缓存，并清空系统当前剪贴板。此操作无法撤销。"),i18n.t("清空"),i18n.t("取消"),"warning")==i18n.t("清空") then
        hs.pasteboard.clearContents()
        M.lastCount=hs.pasteboard.changeCount()
        M.clear()
        return true,i18n.t("历史和系统剪贴板已清空")
    end
end
function M.preview(id)
    M.prune()
    for _,entry in ipairs(M.entries) do
        if entry.id==id and entry.kind=="image" then
            local image=M.imageOf(entry)
            local url=image and image:encodeAsURLString(true,"PNG")
            if not url or #url>13981070 then return nil,i18n.t("图片无法预览或超出容量限制") end
            return {id=entry.id,time=entry.time,url=url}
        end
    end
    return nil,i18n.t("图片已过期或被清除")
end
function M.thumbURL(entry)
    local thumb=not entry.thumbURL and thumbOf(entry)
    if thumb then entry.thumbURL=thumb:encodeAsURLString(false,"PNG") end
    return entry.thumbURL
end
function M.snapshot()
    M.prune()
    local entries={}
    for _,entry in ipairs(M.entries) do
        table.insert(entries,{id=entry.id,kind=entry.kind,source=entry.source,time=entry.time,text=entry.text or i18n.t("图片"),preview=M.thumbURL(entry)})
    end
    return {config=M.config,entries=entries}
end
local textMenuIcon
local function menuThumbnail(image,kind)
    local canvas=hs.canvas.new({x=0,y=0,w=24,h=24})
    canvas[1]={type="rectangle",action="strokeAndFill",fillColor={white=.5,alpha=.12},strokeColor={white=.5,alpha=.3},strokeWidth=1,roundedRectRadii={xRadius=5,yRadius=5},frame={x=.5,y=.5,w=23,h=23}}
    canvas[2]=image and {type="image",image=image,imageAlignment="center",imageScaling="scaleToFit",frame={x=2,y=2,w=20,h=20}} or {type="text",text=kind=="image" and "▧" or "T",textAlignment="center",textColor={white=.6},textSize=14,frame={x=0,y=3,w="100%",h=18}}
    local result=canvas:imageFromCanvas();canvas:delete();return result
end
-- At most ~70 characters fit in 240 pt, so only the first 100 are measured; measuring whole entries
-- (up to 64 KB) made every ⌘⇧V menu slower as history grew.
local function menuLabel(text)
    if #text>1200 then text=text:sub(1,1200):gsub("[\192-\255][\128-\191]*$","") end
    text=text:gsub("%s+"," "):gsub("^%s+",""):gsub("%s+$","")
    local length=utf8.len(text)
    if length and length>100 then text=text:sub(1,utf8.offset(text,101)-1);length=100 end
    if not length then return text:sub(1,40)..(#text>40 and "…" or "") end
    if hs.drawing and hs.drawing.getTextDrawingSize then
        local function fits(value) return hs.drawing.getTextDrawingSize(value,{size=14}).w<=240 end
        if fits(text) then return text end
        local low,high,best=1,length,""
        while low<=high do
            local middle=math.floor((low+high)/2)
            local candidate=text:sub(1,utf8.offset(text,middle+1)-1)
            if fits(candidate.."…") then best=candidate;low=middle+1 else high=middle-1 end
        end
        return best.."…"
    end
    return length>40 and text:sub(1,utf8.offset(text,41)-1).."…" or text
end
-- Prepares an entry's menu label and small copies ahead of time (called a few at a time while Nivlet is idle).
function M.prepare(entry)
    if entry.kind~="image" then if entry.text and not entry.menuLabel then entry.menuLabel=menuLabel(entry.text) end;return end
    sizeOf(entry)
    entry.menuThumb=entry.menuThumb or menuThumbnail(thumbOf(entry),"image")
    M.thumbURL(entry)
end
function M.menuItems()
    M.prune()
    local target=hs.application.frontmostApplication()
    local menu={
        {title=i18n.t("清空历史…"),disabled=#M.entries==0,fn=function() M.confirmClear() end},
        {title="-"},
    }
    local ordered={}
    for _,entry in ipairs(M.entries) do if entry.kind=="image" then table.insert(ordered,entry) end end
    local imageCount=#ordered
    for _,entry in ipairs(M.entries) do if entry.kind~="image" then table.insert(ordered,entry) end end
    for index,entry in ipairs(ordered) do
        if imageCount>0 and index==imageCount+1 then table.insert(menu,{title="-"}) end
        local isImage=entry.kind=="image"
        if entry.text and not entry.menuLabel then entry.menuLabel=menuLabel(entry.text) end
        local text=entry.menuLabel or i18n.t("图片 ")..os.date("%H:%M:%S",math.floor(entry.time))
        local width,height
        if isImage then width,height=sizeOf(entry) end
        if width then
            entry.menuBytes=entry.menuBytes or pngBytes(M.imageOf(entry):encodeAsURLString(true,"PNG"))
            local bytes=entry.menuBytes
            local amount=bytes<1048576 and string.format("%.0f KB",bytes/1024) or string.format("%.1f MB",bytes/1048576)
            text=string.format("%s %.0f×%.0f · %s · %s",i18n.t("图片"),width,height,amount,os.date("%m-%d %H:%M",math.floor(entry.time)))
        end
        local icon
        if isImage then entry.menuThumb=entry.menuThumb or menuThumbnail(thumbOf(entry),"image");icon=entry.menuThumb
        else textMenuIcon=textMenuIcon or menuThumbnail(nil,"text");icon=textMenuIcon end
        local function select(mods) local ok,message=M.copy(entry.id,mods and mods.alt and target or nil);if not ok then hs.alert.show(message) end end
        local submenu
        local preview=isImage and previewOf(entry)
        if preview then
            submenu={{title="",image=preview,tooltip=text,fn=select}}
        end
        table.insert(menu,{title=text,image=icon,tooltip=entry.text or text,menu=submenu,fn=select})
    end
    if #M.entries==0 then table.insert(menu,{title=i18n.t("暂无历史"),disabled=true}) end
    table.insert(menu,{title="-"})
    table.insert(menu,{title=i18n.t("剪贴板设置…"),fn=function() M.openSettings("settings") end})
    table.insert(menu,{title=i18n.t("搜索历史…"),fn=function() M.openSettings("history") end})
    return menu
end
function M.start()
    local saved=hs.settings.get(settingsKey)
    local config=M.validate(saved)
    if config and saved.paused~=nil then


        local ok,result=pcall(hs.settings.set,settingsKey,config)
        if not ok or result==false then
            if hs.alert then hs.alert.show(i18n.t("保存失败，请检查设置")) end
        end
    end
    config=config or M.defaults()
    if config.persistent and not ensureDirectory() then config.persistent=false end
    M.configure(config);M.load()
end
function M.showPopup()
    if M.popup then M.popup:popupMenu(hs.mouse.absolutePosition()) end
end
function M.startMenu(openSettings)
    M.openSettings=openSettings
    local icon=assert(hs.image.imageFromPath(hs.processInfo.bundlePath.."/Contents/Resources/Toolkit/assets/document.on.clipboard.png")):size({w=18,h=18})
    M.menu=hs.menubar.new(true,"NivletClipboard"):setTitle(""):setIcon(icon,true):setTooltip(i18n.t("Nivlet 剪贴板历史"))
    M.menu:setMenu(M.menuItems)
    M.popup=hs.menubar.new(false):setMenu(M.menuItems)
end
return M
