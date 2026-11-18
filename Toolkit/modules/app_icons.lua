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
-- Drawn at the 24 pt the settings page shows (48 px on Retina), about 4 KB per app instead of 15 KB.
local function small(image)
    if not (hs.canvas and hs.canvas.new) then return image:setSize({w=24,h=24}) end
    local canvas=hs.canvas.new({x=0,y=0,w=24,h=24})
    canvas[1]={type="image",image=image,imageScaling="scaleToFit",frame={x=0,y=0,w=24,h=24}}
    local result=canvas:imageFromCanvas();canvas:delete()
    return result
end
function M.get(bundleID,refresh)
    if type(bundleID)~="string" then return nil end
    local installed=not (hs.application and hs.application.pathForBundleID) or installedPath(bundleID)~=nil
    local entry=cache[bundleID]
    if refresh or not entry or entry.installed~=installed then
        local image=installed and hs.image.imageFromAppBundle and hs.image.imageFromAppBundle(bundleID)
        entry={installed=installed,url=image and small(image):encodeAsURLString(false,"PNG") or false}
        cache[bundleID]=entry
    end
    return entry.url or nil
end
return M
