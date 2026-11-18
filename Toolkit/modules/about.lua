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
        -- Drawn at 80 pt; resizing the image object alone still encoded the 1024 px original.
        if image and hs.canvas and hs.canvas.new then
            local canvas=hs.canvas.new({x=0,y=0,w=80,h=80})
            canvas[1]={type="image",image=image,imageScaling="scaleToFit",frame={x=0,y=0,w=80,h=80}}
            image=canvas:imageFromCanvas();canvas:delete()
        elseif image then image=image:setSize({w=80,h=80}) end
        if image then icon=image:encodeAsURLString() end
    end
    M.cached={version=hs.processInfo.version or "—",build=hs.processInfo.build or "—",license=read("LICENSE"),notices=read("THIRD-PARTY-NOTICES.md"),icon=icon}
    return M.cached
end
return M
