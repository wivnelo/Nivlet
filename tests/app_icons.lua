package.path='Toolkit/?.lua;'..package.path
local calls=0
hs={image={imageFromAppBundle=function(id)calls=calls+1;if id=='missing' then return nil end;return {setSize=function(self,size)assert(size.w==48 and size.h==48);return self end,encodeAsURLString=function(_,original,format)assert(original==false and format=='PNG');return 'data:image/png;base64,test' end}end}}
local icons=require('modules.app_icons')
assert(icons.get('test')=='data:image/png;base64,test');icons.get('test');assert(calls==1)
assert(not icons.get('missing'));assert(not icons.get('missing'));assert(calls==2)
icons.get('test',true);assert(calls==3);assert(not icons.get(nil))
hs.application={pathForBundleID=function(id)return id~='uninstalled' and '/Applications/Test.app' or nil end}
local before=calls;assert(not icons.get('uninstalled'));assert(calls==before)
print('App icons: display metadata, bounded size, success/miss caching and refresh passed')

local present=false
hs.fs={attributes=function()return present and 'directory' or nil end}
icons.clear();assert(not icons.get('test'))
present=true;icons.clear();assert(icons.get('test'))
present=false;icons.clear();assert(not icons.get('test'))
print('Icon refresh recovers missing apps and clears removed apps')

-- The icon is redrawn at 48 pt so the data URL holds a small bitmap, not the 1024 px original.
local drawn
hs.canvas={new=function(frame) assert(frame.w==48 and frame.h==48);local c={delete=function() end};function c.imageFromCanvas(self) drawn=self[1];return {encodeAsURLString=function() return 'data:image/png;base64,small' end} end;return c end}
icons.clear();present=true;assert(icons.get('test')=='data:image/png;base64,small' and drawn.frame.w==48 and drawn.imageScaling=='scaleToFit')
print('Icons are redrawn at 48 pt before encoding')
