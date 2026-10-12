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
