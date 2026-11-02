local M={}

function M.valid(id)
    return type(id)=="string" and #id<=255 and id:match("^[%w_%-][%w_.%-]*$")~=nil
end
return M
