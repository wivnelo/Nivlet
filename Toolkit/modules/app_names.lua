-- Resolve display names consistently without changing application identity.
local M={}
function M.get(bundleID,fallback,path,info)
    path=path or hs.application.pathForBundleID(bundleID)
    if path then
        local name=hs.fs.displayName(path)
        if type(name)=='string' and name~='' then return (name:gsub('%.app$','')) end
        info=info or hs.application.infoForBundlePath(path)
        if info then return info.CFBundleDisplayName or info.CFBundleName or fallback or bundleID end
    end
    return fallback or bundleID
end
function M.snapshot(config)
    local result={}
    for key,value in pairs(config) do result[key]=value end
    for _,key in ipairs({'rules','appRules'}) do
        if config[key] then
            result[key]={}
            for i,rule in ipairs(config[key]) do
                local copy={};for k,v in pairs(rule) do copy[k]=v end
                if copy.bundleID then copy.name=M.get(copy.bundleID,copy.name) end
                result[key][i]=copy
            end
        end
    end
    return result
end
return M
