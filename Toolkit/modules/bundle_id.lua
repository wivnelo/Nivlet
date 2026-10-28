local M={}
-- CFBundleIdentifier 不强制反向域名，FinalShell 等应用的 Bundle ID 没有点号。
function M.valid(id)
    return type(id)=="string" and #id<=255 and id:match("^[%w_%-][%w_.%-]*$")~=nil
end
return M
