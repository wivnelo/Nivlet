local M={}
function M.snapshot()
    if M.cached then return M.cached end
    local root=hs.processInfo.bundlePath.."/Contents/Resources/Toolkit/"
    local function read(name)
        local file=io.open(root..name,"r")
        if not file then return nil end
        local value=file:read("*a");file:close();return value
    end
    local icon
    if hs.image and hs.image.imageFromPath then
        local image=hs.image.imageFromPath(root.."nivlet-icon.png")
        if image then icon=image:setSize({w=80,h=80}):encodeAsURLString() end
    end
    M.cached={version=hs.processInfo.version or "—",build=hs.processInfo.build or "—",license=read("LICENSE"),notices=read("THIRD-PARTY-NOTICES.md"),icon=icon}
    return M.cached
end
return M
