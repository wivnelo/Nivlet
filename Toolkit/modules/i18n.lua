local M = {dictionary=require("modules.translations"),mode="system"}
local supported={system=true,["zh-Hans"]=true,en=true,["zh-Hant"]=true,ja=true}
local dictionaries={["zh-Hans"]={}}
local dictionaryModules={["zh-Hant"]="modules.translations_zh_hant",ja="modules.translations_ja"}
local function dictionary(language)
    if language=="en" then return M.dictionary end
    if not dictionaries[language] then dictionaries[language]=require(dictionaryModules[language]) end
    return dictionaries[language]
end
function M.configure(mode)
    M.mode = supported[mode] and mode or "system"
end
function M.language()
    if M.mode ~= "system" then return M.mode end
    local locale=hs and hs.host and hs.host.locale
    -- Preserve the original Chinese interface if the locale API is unavailable.
    if not locale or type(locale.preferredLanguages)~="function" then return "zh-Hans" end
    local ok,languages=pcall(locale.preferredLanguages)
    if not ok then return "zh-Hans" end
    local first=type(languages)=="table" and languages[1] or ""
    local language=type(first)=="string" and first:lower():gsub("_","-") or ""
    if language:match("^zh") then
        -- Explicit script wins over region. HK/MO use the Traditional Chinese
        -- interface; this is not a separate Hong Kong terminology catalogue.
        local tags={};for tag in language:gmatch("[^%-]+") do tags[tag]=true end
        if tags.hans then return "zh-Hans" end
        if tags.hant or tags.tw or tags.hk or tags.mo then return "zh-Hant" end
        return "zh-Hans"
    end
    if language:match("^ja") then return "ja" end
    return "en"
end
function M.translations()
    return dictionary(M.language())
end
function M.t(text)
    local language=M.language()
    return language~="zh-Hans" and (dictionary(language)[text] or text) or text
end
local stored=hs and hs.settings and hs.settings.get and hs.settings.get("desktoptoolkit.general.v1")
M.configure(type(stored)=="table" and stored.language or "system")
return M
