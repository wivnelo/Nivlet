-- Execute the production picker dispatch branch with controlled native dependencies.
local f=assert(io.open('Toolkit/init.lua'));local source=f:read('*a');f:close()
local first=assert(source:find('        if body.action == "chooseApp"',1,true))
local last=assert(source:find('\n    end)\n    local file',first,true))
local branch=source:sub(first,last-1)
local result,encoded,errors,selection,info
local env={appNames={get=function(id,_,path,info)assert(path=='/Applications/Synthetic.app');return info.CFBundleDisplayName or id end},appIcons={get=function()return nil end},body={action='chooseExcludedApp'},i18n={t=function(s)return s end},reply=function(ok,message)assert(not ok);errors=message end,
 app={settings={evaluateJavaScript=function(_,js)result=js end}},hs={
 dialog={chooseFileOrFolder=function(prompt,path,files,folders,multiple,types)assert(prompt=='选择不记录剪贴板的应用' and path=='/Applications' and files and not folders and not multiple and types[1]=='app');return selection end},
 application={infoForBundlePath=function(path)assert(path=='/Applications/Synthetic.app');return info end},
 json={encode=function(value)encoded=value;return '{synthetic}' end}}}
setmetatable(env,{__index=_G});local execute=assert(load(branch,'production picker','t',env))
for _,value in ipairs({false,{},''})do selection=value;execute();assert(not result and not encoded and not errors)end
selection={'/Applications/Synthetic.app'};info={CFBundleIdentifier='com.example.synthetic',CFBundleDisplayName='Synthetic'};execute()
assert(result=='window.addExcludedApp({synthetic},true)' and encoded.bundleID=='com.example.synthetic' and encoded.name=='Synthetic')
result=nil;info=nil;execute();assert(not result and errors=='无法识别所选应用')
print('Production exclusion app picker: cancel, native options, valid identity/name and invalid app passed')
