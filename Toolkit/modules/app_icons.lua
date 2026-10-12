-- Display-only metadata; never persisted in user configuration.
local M,cache={},{}
function M.get(bundleID,refresh)
    if type(bundleID)~="string" then return nil end
    if refresh then cache[bundleID]=nil end
    if cache[bundleID]==nil then
        local installed=not (hs.application and hs.application.pathForBundleID) or hs.application.pathForBundleID(bundleID)~=nil
        local image=installed and hs.image.imageFromAppBundle and hs.image.imageFromAppBundle(bundleID)
        cache[bundleID]=image and image:setSize({w=48,h=48}):encodeAsURLString(false,"PNG") or false
    end
    return cache[bundleID] or nil
end
return M
