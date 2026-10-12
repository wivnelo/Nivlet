local i18n = require("modules.i18n")
local M = {config={enabled=false,rules={}}}
local settingsKey = "desktoptoolkit.input.v1"
function M.sources()
    local result, seen = {}, {}
    for _, method in ipairs({"layouts", "methods"}) do
        local ids, names = hs.keycodes[method](true), hs.keycodes[method]()
        for i, id in ipairs(ids) do
            if not seen[id] then
                seen[id] = true
                local chineseNames={
                    ["com.apple.inputmethod.SCIM.ITABC"]="简体拼音",
                }
                local name=i18n.language()=="zh-Hans" and chineseNames[id] or nil
                table.insert(result, {id=id,name=name or names[i] or id})
            end
        end
    end
    return result
end
function M.validate(value, available)
    if type(value) ~= "table" or type(value.enabled) ~= "boolean" or type(value.rules) ~= "table" then return nil, i18n.t("输入法设置格式无效") end
    local result, used = {enabled=value.enabled,rules={}}, {}
    for _, rule in ipairs(value.rules) do
        if type(rule) ~= "table" or type(rule.bundleID) ~= "string" or not rule.bundleID:match("^[%w_%-]+%.[%w_.%-]+$") or type(rule.sourceID) ~= "string" or rule.sourceID == "" then return nil, i18n.t("请选择应用和输入法") end
        if used[rule.bundleID:lower()] then return nil, i18n.t("同一应用只能配置一条输入法规则") end
        if value.enabled and available and not available[rule.sourceID] then return nil, i18n.t("输入法不可用，请重新选择：") .. rule.sourceID end
        used[rule.bundleID:lower()] = true
        table.insert(result.rules, {bundleID=rule.bundleID,sourceID=rule.sourceID,name=type(rule.name)=="string" and rule.name or rule.bundleID})
    end
    return result
end
function M.apply(application)
    if not M.config.enabled or not application then return false end
    local id = application:bundleID()
    for _, rule in ipairs(M.config.rules) do
        if rule.bundleID == id then
            if hs.keycodes.currentSourceID() == rule.sourceID then return true end
            local ok = hs.keycodes.currentSourceID(rule.sourceID)
            if not ok then print("Nivlet input source unavailable", rule.sourceID) end
            return ok
        end
    end
    return false
end
function M.configure(config)
    if M.watcher then M.watcher:stop(); M.watcher=nil end
    M.config = config
    if config.enabled then
        M.watcher = hs.application.watcher.new(function(_, event, application)
            if event == hs.application.watcher.activated then M.apply(application) end
        end):start()
    end
end
function M.save(value)
    local available = {}
    if type(value)=="table" and value.enabled then for _, source in ipairs(M.sources()) do available[source.id]=true end end
    local config, message = M.validate(value, available)
    if not config then return false, message end
    M.configure(config)
    hs.settings.set(settingsKey, config)
    return true, i18n.t("输入法规则已保存")
end
function M.start()
    local config = M.validate(hs.settings.get(settingsKey)) or {enabled=false,rules={}}
    M.configure(config)
end
return M
