local M = {dictionary=require("modules.translations"),mode="system"}
function M.configure(mode)
    M.mode = mode == "en" and "en" or mode == "zh-Hans" and "zh-Hans" or "system"
end
function M.language()
    if M.mode ~= "system" then return M.mode end
    local locale=hs and hs.host and hs.host.locale
    -- Preserve the original Chinese interface if the locale API is unavailable.
    if not locale or not locale.preferredLanguages then return "zh-Hans" end
    local languages=locale.preferredLanguages()
    local first=type(languages)=="table" and languages[1] or ""
    return type(first)=="string" and first:lower():match("^zh") and "zh-Hans" or "en"
end
function M.t(text)
    return M.language()=="en" and (M.dictionary[text] or text) or text
end
local stored=hs and hs.settings and hs.settings.get and hs.settings.get("desktoptoolkit.general.v1")
M.configure(type(stored)=="table" and stored.language or "system")
return M
