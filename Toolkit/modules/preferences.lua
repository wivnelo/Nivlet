local i18n = require("modules.i18n")
local M = {}
function M.systemAssigned(mods,key)
    local assigned=hs.hotkey.systemAssigned(mods,key)
    return assigned==true or type(assigned)=="table" and assigned.enabled==true
end
local actions = require("modules.windows").actions
function M.defaults() return {enabled=false, shortcuts={}} end
function M.validate(value)
    if type(value) ~= "table" or type(value.enabled) ~= "boolean" or type(value.shortcuts) ~= "table" then return nil, i18n.t("设置格式无效") end
    local result = {enabled=value.enabled, shortcuts={}}
    local used = {}
    for _, action in ipairs(actions) do
        local item = value.shortcuts[action]
        if item then
            if type(item) ~= "table" or type(item.key) ~= "string" or type(item.mods) ~= "table" then return nil, i18n.t("快捷键格式无效") end
            local arrows={LEFT="left",RIGHT="right",UP="up",DOWN="down",ARROWLEFT="left",ARROWRIGHT="right",ARROWUP="up",ARROWDOWN="down",["←"]="left",["→"]="right",["↑"]="up",["↓"]="down"}
            local special={ENTER="return",RETURN="return",["↩"]="return",["="]="=",["-"]="-"}
            local key = arrows[item.key:upper()] or special[item.key:upper()] or item.key:upper()
            if key ~= "" then
                if not key:match("^[A-Z0-9]$") and key~="left" and key~="right" and key~="up" and key~="down" and key~="return" and key~="=" and key~="-" then return nil, i18n.t("快捷键支持字母、数字、方向键、Return、= 或 -") end
                local flags = {}
                for _, mod in ipairs(item.mods) do
                    if mod ~= "ctrl" and mod ~= "alt" and mod ~= "cmd" and mod ~= "shift" then return nil, i18n.t("未知修饰键") end
                    flags[mod] = true
                end
                if not flags.ctrl and not flags.alt and not flags.cmd then return nil, i18n.t("至少选择 Control、Option 或 Command") end
                local mods = {}
                for _, mod in ipairs({"ctrl", "alt", "cmd", "shift"}) do if flags[mod] then table.insert(mods, mod) end end
                local signature = table.concat(mods, "+") .. "+" .. key
                if used[signature] then return nil, i18n.t("不同操作不能使用相同快捷键") end
                used[signature] = true
                result.shortcuts[action] = {key=key, mods=mods}
            end
        end
    end
    return result
end
return M
