local f=assert(io.open('Toolkit/init.lua'));local source=f:read('*a');f:close()
local refresh=assert(source:match('(if body.action == "refreshClipboard" then.- end)'))
local preview=assert(source:match('(if body.action == "previewClipboard" then.-)\n        if body.action == "copyClipboard"'))
local response,script,value,message
local environment={reply=function(ok,msg,action) response={ok=ok,message=msg,action=action} end,
 clipboard={preview=function(id) assert(id==17);return value,message end},
 app={settings={evaluateJavaScript=function(_,js) script=js end}},hs={json={encode=function(v) assert(v==value);return 'PREVIEW' end}}}
local handler=assert(load('return function(body) '..refresh..'\n'..preview..' end','clipboard feedback','t',environment))()
handler({action='refreshClipboard'});assert(response.ok and response.action=='refreshClipboard')
message='Synthetic preview failure';handler({action='previewClipboard',id=17});assert(response.ok==false and response.message==message and response.action=='previewClipboard')
response=nil;value={url='synthetic'};handler({action='previewClipboard',id=17});assert(response==nil and script=='window.showImage(PREVIEW)')
print('Production clipboard bridge tags refresh and preview failure; successful preview still opens image')
