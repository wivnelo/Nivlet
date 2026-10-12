local i18n=require("modules.i18n")
local M={version=1,names={"general","windows","input","clipboard","popupShortcut","system","browser","launcher"}}
local function copy(value)
    if type(value)~="table" then return value end
    local result={};for k,v in pairs(value) do result[k]=copy(v) end;return result
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not equal(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function fields(value,allowed)
    if type(value)~="table" then return false end
    for k in pairs(value) do if not allowed[k] then return false end end
    return true
end
local function array(value)
    if type(value)~="table" or #value>1000 then return false end
    for k in pairs(value) do if type(k)~="number" or k%1~=0 or k<1 or k>#value then return false end end
    return true
end
local schemas={
 general={sleepShortcut=true,showMenu=true,appearance=true,language=true,tabOrder=true},windows={enabled=true,shortcuts=true},
 input={enabled=true,rules=true},clipboard={enabled=true,limit=true,minutes=true,images=true,persistent=true,excluded=true},
 system={network=true,cpu=true,memory=true,disk=true,ipv4=true,ipv6=true,mac=true,date=true,lunar=true},
 browser={enabled=true,defaultBrowser=true,rules=true,appRules=true},launcher={enabled=true,rules=true},
}
local ruleSchemas={input={bundleID=true,name=true,sourceID=true},browser={domain=true,browser=true,subdomains=true},launcher={bundleID=true,name=true,shortcut=true}}
local function shortcut(value)
    return value==false or fields(value,{key=true,mods=true}) and array(value.mods)
end
local windowFields={};for _,action in ipairs(require("modules.windows").actions) do windowFields[action]=true end
local function shape(name,value)
    if name=="popupShortcut" then return shortcut(value) end
    if not fields(value,schemas[name]) then return false end
    if name=="general" and value.language~=nil and type(value.language)~="string" then return false end
    if name=="windows" then
        if not fields(value.shortcuts,windowFields) then return false end
        for _,v in pairs(value.shortcuts) do if not shortcut(v) or v==false then return false end end
    end
    if value.rules then
        if not array(value.rules) then return false end
        for _,rule in ipairs(value.rules) do
            if not fields(rule,ruleSchemas[name]) or rule.name~=nil and type(rule.name)~="string" then return false end
            if name=="launcher" and rule.shortcut~=nil and not shortcut(rule.shortcut) then return false end
        end
    end
    if name=="browser" and value.appRules~=nil then
        if not array(value.appRules) then return false end
        for _,rule in ipairs(value.appRules) do if not fields(rule,{bundleID=true,name=true,browser=true}) then return false end end
    end
    if name=="clipboard" and not array(value.excluded) then return false end
    return true
end
function M.new(adapters,environment)
    local manager={}
    function manager.export(defaults)
        local modules={}
        for _,name in ipairs(M.names) do
            local value
            if defaults then value=adapters[name].defaults() else value=adapters[name].get() end
            modules[name]=copy(value)
        end
        return {format="Nivlet",version=M.version,modules=modules}
    end
    function manager.prepare(document)
        if not fields(document,{format=true,version=true,modules=true}) or document.format~="Nivlet" or document.version~=M.version or type(document.modules)~="table" then return nil,i18n.t("配置文件格式或版本不支持") end
        local candidate,selected=manager.export().modules,{}
        for name,value in pairs(document.modules) do
            if not adapters[name] or not shape(name,value) then return nil,i18n.t("配置字段无效：")..tostring(name) end
            local ok,config,message=pcall(adapters[name].validate,value)
            if not ok or config==nil then return nil,name..": "..(message or i18n.t("配置字段无效")) end
            candidate[name]=copy(config);selected[name]=true
        end
        if not next(selected) then return nil,i18n.t("配置文件未包含任何模块") end
        local signatures={}
        local function check(item,active)
            if not item or item==false then return true end
            local signature=table.concat(item.mods,"+").."+"..item.key
            if signatures[signature] then return false,i18n.t("配置中存在跨模块快捷键冲突：")..signature end
            signatures[signature]=true
            if active and environment.systemAssigned(item) then return false,i18n.t("快捷键被系统占用：")..signature end
            return true
        end
        local checks={}
        if candidate.general.sleepShortcut then table.insert(checks,{{key="L",mods={"cmd"}},true}) end
        for _,item in pairs(candidate.windows.shortcuts) do table.insert(checks,{item,candidate.windows.enabled}) end
        for _,rule in ipairs(candidate.launcher.rules) do if rule.shortcut then table.insert(checks,{rule.shortcut,candidate.launcher.enabled}) end end
        if candidate.popupShortcut~=false then table.insert(checks,{candidate.popupShortcut,true}) end
        for _,item in ipairs(checks) do local ok,message=check(item[1],item[2]);if not ok then return nil,message end end
        if (selected.windows or selected.launcher or selected.popupShortcut) and candidate.windows.enabled and not environment.accessibility() then return nil,i18n.t("请先在系统设置开启 Nivlet 的辅助功能权限") end
        local ok,message=environment.available(candidate,selected)
        if not ok then return nil,message end
        if selected.clipboard and not equal(candidate.clipboard,adapters.clipboard.get()) and environment.hasHistory() then
            local old,new=adapters.clipboard.get(),candidate.clipboard
            if (old.persistent and not new.persistent) or (new.minutes>0 and (old.minutes==0 or new.minutes<old.minutes)) or new.limit<old.limit or (old.images and not new.images) then
                return nil,i18n.t("导入会清理剪贴板历史，请先在剪贴板设置中单独处理")
            end
        end
        return {modules=candidate,selected=selected}
    end
    function manager.apply(document)
        local plan,message=manager.prepare(document)
        if not plan then return false,message end
        local before=manager.export().modules
        local stored=environment.capture()
        local function release()
            local general=copy(adapters.general.get())
            if general.sleepShortcut then general.sleepShortcut=false;local ok,result=adapters.general.save(general);if not ok then error(result) end end
            for _,name in ipairs({"launcher","windows","popupShortcut"}) do
                local ok,result=adapters[name].save(adapters[name].defaults())
                if not ok then error(result) end
            end
        end
        local function apply(config,selected)
            if selected.windows or selected.launcher or selected.popupShortcut then release() end
            for _,name in ipairs({"windows","popupShortcut","launcher","input","browser","system","general","clipboard"}) do
                if (selected[name] or (selected.windows or selected.launcher or selected.popupShortcut) and (name=="windows" or name=="popupShortcut" or name=="launcher" or name=="general")) and not (name=="clipboard" and equal(config[name],adapters[name].get())) then
                    local ok,result=adapters[name].save(config[name]);if not ok then error(result) end
                end
            end
        end
        local ok,result=pcall(apply,plan.modules,plan.selected)
        if ok then return true,i18n.t("配置已导入"),plan.selected end
        local restored,restoreMessage=pcall(apply,before,plan.selected)
        local persisted,persistMessage=pcall(environment.restore,stored)
        if not restored or not persisted then return false,i18n.t("导入失败，部分状态无法恢复，请检查设置：")..tostring(restoreMessage or persistMessage) end
        return false,i18n.t("导入失败，已恢复原配置：")..tostring(result)
    end
    return manager
end
return M
