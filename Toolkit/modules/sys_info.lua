local i18n = require("modules.i18n")
local M={rx=0,tx=0,lunar="N/A",mac=nil}
local settingsKey="desktoptoolkit.system.v1"
M.fields={"network","cpu","memory","disk","ipv4","ipv6","mac","date","lunar"}
function M.defaults()
    local config={};for _,field in ipairs(M.fields) do config[field]=true end;return config
end
function M.validate(value)
    if type(value)~="table" then return nil,i18n.t("系统信息设置格式无效") end
    local config={}
    for _,field in ipairs(M.fields) do
        if type(value[field])~="boolean" then return nil,i18n.t("系统信息开关格式无效") end
        config[field]=value[field]
    end
    return config
end
M.config=M.defaults()
function M.save(value)
    local config,message=M.validate(value);if not config then return false,message end
    M.config=config;hs.settings.set(settingsKey,config)
    -- A reused NSMenu can retain the smaller layout after fields are restored.
    -- Clear it first so AppKit measures a fresh menu on the next opening.
    M.menu:setMenu(nil):setMenu(M.menuItems)
    M.draw()
    return true,i18n.t("系统信息设置已保存")
end
function M.speed(bytes)
    if bytes<1024 then return string.format("%.0f B/s",bytes) end
    if bytes<1048576 then return string.format("%.1f KB/s",bytes/1024) end
    return string.format("%.1f MB/s",bytes/1048576)
end
function M.accept(data,interface,now)
    M.lastSample=now
    local sample=data.interfaces and data.interfaces[interface]
    M.networkReady=sample and M.previous and M.previous.interface==interface and now>M.previous.time and sample.rx>=M.previous.rx and sample.tx>=M.previous.tx or false
    M.rx,M.tx=0,0
    if sample and M.previous and M.previous.interface==interface and now>M.previous.time then
        local elapsed=now-M.previous.time
        M.rx=math.max(0,sample.rx-M.previous.rx)/elapsed
        M.tx=math.max(0,sample.tx-M.previous.tx)/elapsed
    end
    M.previous=sample and {interface=interface,rx=sample.rx,tx=sample.tx,time=now} or nil
    local mac=sample and sample.mac or nil
    M.macRestricted=type(mac)=="string" and mac:lower()=="02:00:00:00:00:00"
    M.mac=not M.macRestricted and mac or nil
    M.lunar=data.lunar or "N/A"
end
local function copyItem(title,value)
    return {title=title..": "..value,fn=function() hs.pasteboard.setContents(value) end}
end
local function readings()
    local menu={}
    local cpu=hs.host.cpuUsageTicks()
    if cpu and cpu.overall then
        local overall=cpu.overall
        local total=overall.user+overall.nice+overall.system+overall.idle
        local active=total-overall.idle
        local percentage
        if M.cpuPrevious and total>M.cpuPrevious.total then percentage=100*(active-M.cpuPrevious.active)/(total-M.cpuPrevious.total) end
        M.cpuPrevious={active=active,total=total}
        table.insert(menu,{title=(percentage and string.format("CPU: %.0f%% / %d Core",percentage,#cpu) or "CPU: N/A"),disabled=true})
    end
    local vm=hs.host.vmStat()
    if vm and vm.memSize and vm.memSize>0 then
        local used=vm.memSize-((vm.fileBackedPages or 0)+(vm.pagesFree or 0))*vm.pageSize
        table.insert(menu,{title=string.format("MEM: %.0f%% / %.0f GB",math.max(0,used)/vm.memSize*100,vm.memSize/1073741824),disabled=true})
    end
    local volumes=hs.fs.volume.allVolumes()
    local disk=volumes and (volumes["/System/Volumes/Data"] or volumes["/"])
    if disk and disk.NSURLVolumeTotalCapacityKey and disk.NSURLVolumeTotalCapacityKey>0 and disk.NSURLVolumeAvailableCapacityKey then
        table.insert(menu,{title=string.format("Disk: %.0f%% / %.0f GB",100*(1-disk.NSURLVolumeAvailableCapacityKey/disk.NSURLVolumeTotalCapacityKey),disk.NSURLVolumeTotalCapacityKey/1073741824),disabled=true})
    else table.insert(menu,{title="Disk: N/A",disabled=true}) end
    table.insert(menu,{title="-"})
    local interface=hs.network.primaryInterfaces()
    local details=interface and hs.network.interfaceDetails(interface)
    for _,kind in ipairs({"IPv4","IPv6"}) do
        for _,address in ipairs(details and details[kind] and details[kind].Addresses or {}) do table.insert(menu,copyItem(kind=="IPv4" and "LAN" or "IPv6",address)) end
    end
    if M.macRestricted then table.insert(menu,{title="MAC: "..i18n.t("系统已隐藏"),disabled=true})
    elseif M.mac then table.insert(menu,copyItem("MAC",M.mac)) end
    table.insert(menu,{title=i18n.t("WAN / Loc: 未开启外部查询"),disabled=true})
    table.insert(menu,{title="-"})
    local weekdays={i18n.t("周日"),i18n.t("周一"),i18n.t("周二"),i18n.t("周三"),i18n.t("周四"),i18n.t("周五"),i18n.t("周六")}
    table.insert(menu,{title="Date: "..os.date("%Y-%m-%d").." "..weekdays[os.date("*t").wday],fn=function() hs.pasteboard.setContents(os.date("%Y-%m-%d %H:%M:%S")) end})
    table.insert(menu,copyItem("Lunar",M.lunar))
    return menu
end
function M.snapshot()
    local values={}
    local prefixes={CPU="cpu",MEM="memory",Disk="disk",LAN="ipv4",IPv6="ipv6",MAC="mac",Date="date",Lunar="lunar"}
    for _,item in ipairs(readings()) do
        local prefix,value=item.title:match("^(%w+): (.*)$")
        local field=prefixes[prefix]
        if field then values[field]=values[field] and (values[field].."\n"..value) or value end
    end
    local now=hs.timer.secondsSinceEpoch()
    values.network=M.networkReady and M.lastSample and now-M.lastSample<6 and ("↑ "..M.speed(M.tx).."  ↓ "..M.speed(M.rx)) or "N/A"
    for _,field in ipairs(M.fields) do values[field]=values[field] or "N/A" end
    return values
end
function M.menuItems()
    local menu=readings()
    local prefixes={CPU="cpu",MEM="memory",Disk="disk",LAN="ipv4",IPv6="ipv6",MAC="mac",Date="date",Lunar="lunar"}
    local filtered={}
    for _,item in ipairs(menu) do
        local field=prefixes[item.title:match("^(%w+):")]
        if field and M.config[field] then table.insert(filtered,item) end
    end
    if #filtered==0 then table.insert(filtered,{title=i18n.t("未选择显示信息"),disabled=true}) end
    table.insert(filtered,{title="-"})
    table.insert(filtered,{title=i18n.t("系统信息设置…"),fn=M.openSettings})
    return filtered
end
function M.draw()
    if not M.config.network then M.menu:setIcon(nil):setTitle("ⓘ");return end
    local text="▲ "..M.speed(M.tx).."\n▼ "..M.speed(M.rx)
    local canvas=hs.canvas.new({x=0,y=0,w=90,h=22})
    canvas:appendElements({type="text",text=text,textSize=9,textColor={white=0},frame={x=0,y=0,w=90,h=22}})
    local width=math.ceil(canvas:minimumTextSize(1,text).w)+2
    canvas:size({w=width,h=22})
    canvas:elementAttribute(1,"frame",{x=0,y=0,w=width,h=22})
    M.menu:setTitle(""):setIcon(canvas:imageFromCanvas(),true)
    canvas:delete()
end
function M.scan()
    if M.task and M.task:isRunning() then return end
    local interface=hs.network.primaryInterfaces()
    local path=hs.processInfo.bundlePath.."/Contents/Resources/Toolkit/system-probe"
    M.task=hs.task.new(path,function(code,output)
        if code~=0 then return end
        local data=hs.json.decode(output)
        if type(data)~="table" then return end
        M.accept(data,interface,hs.timer.secondsSinceEpoch());M.draw()
    end)
    if M.task then M.task:start() end
end
function M.start(openSettings)
    M.openSettings=openSettings
    M.config=M.validate(hs.settings.get(settingsKey)) or M.defaults()
    local cpu=hs.host.cpuUsageTicks()
    if cpu and cpu.overall then
        local c=cpu.overall
        M.cpuPrevious={active=c.user+c.nice+c.system,total=c.user+c.nice+c.system+c.idle}
    end
    M.menu=hs.menubar.new(true,"NivletSystemInfo"):setTitle("▲ — / ▼ —"):setTooltip(i18n.t("Nivlet 系统信息"))
    M.menu:setMenu(M.menuItems)
    M.draw();M.scan();M.timer=hs.timer.doEvery(2,M.scan)
end
return M
