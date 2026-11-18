-- App icons as data URLs for the settings page. Each icon is read and encoded once and kept until the
-- app's install state changes, so refreshing the page (e.g. on window focus) does not re-encode every icon.
local M,cache={},{}
function M.clear() cache={} end
local function installedPath(bundleID)
    local path=hs.application and hs.application.pathForBundleID and hs.application.pathForBundleID(bundleID)
    if not path then return nil end
    if hs.fs and hs.fs.attributes and hs.fs.attributes(path,"mode")~="directory" then return nil end
    return path
end
function M.get(bundleID,refresh)
    if type(bundleID)~="string" then return nil end
    local installed=not (hs.application and hs.application.pathForBundleID) or installedPath(bundleID)~=nil
    local entry=cache[bundleID]
    if refresh or not entry or entry.installed~=installed then
        local image=installed and hs.image.imageFromAppBundle and hs.image.imageFromAppBundle(bundleID)
        entry={installed=installed,url=image and image:setSize({w=48,h=48}):encodeAsURLString(false,"PNG") or false}
        cache[bundleID]=entry
    end
    return entry.url or nil
end
return M
