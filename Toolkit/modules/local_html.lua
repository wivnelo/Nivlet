-- Narrow file-URL support for HTML documents handed to Nivlet by macOS.
-- Do not pass a file URL through hostname rules or the system default opener.
local i18n = require("modules.i18n")
local M = {}

local function decoded(value)
    if value:gsub("%%(%x%x)", ""):find("%", 1, true) then return nil end
    value = value:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
    if value:find("%c") or not utf8.len(value) then return nil end
    return value
end

local function pathEncoded(value)
    return (value:gsub("[^A-Za-z0-9%-%._~/]", function(byte) return string.format("%%%02X", byte:byte()) end))
end

-- Preserve percent-escaped delimiters in query/fragment components: decoding
-- %26 into & would change query semantics. Encode only raw non-URI bytes.
local function suffixEncoded(value)
    if not decoded(value) then return nil end
    local parts, at = {}, 1
    while at <= #value do
        local byte = value:sub(at, at)
        if byte == "%" then
            parts[#parts + 1] = value:sub(at, at + 2):upper()
            at = at + 3
        else
            parts[#parts + 1] = byte:match("[A-Za-z0-9%-%._~!$&'()*+,;=:@/?]") and byte or string.format("%%%02X", byte:byte())
            at = at + 1
        end
    end
    return table.concat(parts)
end

function M.normalize(url)
    local invalid = i18n.t("本地 HTML 链接无效")
    if type(url) ~= "string" or #url > 16384 or url:find("%c") then return nil, invalid end
    local scheme, authority, rest = url:match("^([%a]+)://([^/]*)(/.*)$")
    if not scheme or scheme:lower() ~= "file" or (authority ~= "" and authority:lower() ~= "localhost") then
        return nil, i18n.t("仅支持本机 file 链接，不支持远程主机或登录信息")
    end

    local pathPart, suffix = rest:match("^([^?#]*)(.*)$")
    local path = decoded(pathPart)
    if not path or path:sub(1, 1) ~= "/" or path:sub(1, 2) == "//" then return nil, invalid end
    -- Browser URL normalization and filesystem symlink traversal can disagree
    -- on dot segments. Refuse them before checking or opening any path.
    for segment in path:gmatch("[^/]+") do
        if segment == "." or segment == ".." then return nil, invalid end
    end
    local extension = path:match("%.([^/%.]+)$")
    if not extension or (extension:lower() ~= "html" and extension:lower() ~= "htm") then
        return nil, i18n.t("本地文件仅支持 .html 和 .htm")
    end

    local query, fragment
    if suffix:sub(1, 1) == "?" then
        query, fragment = suffix:sub(2):match("^([^#]*)(.*)$")
    else
        fragment = suffix
    end
    local normalizedSuffix = ""
    if query ~= nil then
        query = suffixEncoded(query)
        if not query then return nil, invalid end
        normalizedSuffix = "?" .. query
    end
    if fragment ~= "" then
        if fragment:sub(1, 1) ~= "#" then return nil, invalid end
        fragment = suffixEncoded(fragment:sub(2))
        if not fragment then return nil, invalid end
        normalizedSuffix = normalizedSuffix .. "#" .. fragment
    end

    -- stat follows ordinary symlinks, but directories/devices/FIFOs are refused.
    -- Preserve the selected path so relative HTML assets keep their base URL.
    if not hs.fs or hs.fs.attributes(path, "mode") ~= "file" then
        return nil, i18n.t("本地 HTML 文件不存在或不是普通文件")
    end
    local file = io.open(path, "rb")
    if not file then return nil, i18n.t("无法读取本地 HTML 文件") end
    file:close()
    return "file://" .. pathEncoded(path) .. normalizedSuffix
end

return M
