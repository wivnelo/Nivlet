package.path='Toolkit/?.lua;'..package.path
local settings,callback,front,allowed,installed,launch,menuOK,stops,keys={ },nil,true,true,true,true,true,0,0
local paths,expectedMenu={},nil
local app={isFrontmost=function() return front end,selectMenuItem=function(_,path)
    paths[#paths+1]=path
    return menuOK and (not expectedMenu or (path[1]==expectedMenu[1] and path[2]==expectedMenu[2]))
end}
hs={fs={attributes=function()return 'directory' end},settings={get=function(k)return settings[k]end,set=function(k,v)settings[k]=v end},accessibilityState=function()return allowed end,application={pathForBundleID=function()return installed and '/Applications/Browser.app' or nil end,launchOrFocusByBundleID=function()return launch end,get=function()return app end},timer={doEvery=function(_,fn)callback=fn;return {stop=function()stops=stops+1 end}end},eventtap={keyStroke=function(mods,key,delay,target)assert(key=='delete' and target==app and mods[1]=='cmd' and mods[2]=='shift');keys=keys+1 end}}
local m=require('modules.browser_data')
local result
local function done(ok,message)result={ok,message}end
m.open('org.mozilla.firefox',done);assert(result[1]==false and callback==nil)
allowed=false;m.open('com.apple.Safari',done);assert(result[1]==false and callback==nil);allowed=true
installed=false;m.open('com.apple.Safari',done);assert(result[1]==false and callback==nil);installed=true
launch=false;m.open('com.apple.Safari',done);assert(result[1]==false and callback==nil);launch=true
m.open('com.apple.Safari',done);m.open('com.apple.Safari',done);assert(result[1]==false)
callback();assert(result[1]==true and stops==1 and #paths==1 and keys==0)
front=false;m.open('com.google.Chrome',done);for i=1,25 do callback() end;assert(result[1]==false and keys==0)
front=true;m.open('com.google.Chrome',done);callback();assert(result[1]==true and keys==1)
menuOK=false;m.open('com.apple.Safari',done);for i=1,25 do callback() end;assert(result[1]==false and stops==4)
menuOK=true
for _,language in ipairs({{"瀏覽記錄","清除瀏覽記錄"},{"履歴","履歴を消去"}}) do
    for _,suffix in ipairs({"…","...",""}) do
        expectedMenu={language[1],language[2]..suffix};paths={}
        m.open('com.apple.Safari',done);callback()
        assert(result[1]==true and paths[#paths][1]==expectedMenu[1] and paths[#paths][2]==expectedMenu[2])
        assert(keys==1,'Safari language support must not send a confirmation keystroke')
    end
end
print('Browser data: allowlist, permissions, missing app, launch failure, busy, focus, timeout and dispatch passed')
-- Brave must use only its documented opener, including all existing safety gates.
expectedMenu=nil;paths={}
local priorKeys=keys
allowed=false;m.open('com.brave.Browser',done);assert(not result[1] and keys==priorKeys);allowed=true
installed=false;m.open('com.brave.Browser',done);assert(not result[1] and keys==priorKeys);installed=true
hs.fs.attributes=function()return nil end
m.open('com.brave.Browser',done);assert(not result[1] and keys==priorKeys)
hs.fs.attributes=function()return 'directory' end
launch=false;m.open('com.brave.Browser',done);assert(not result[1] and keys==priorKeys);launch=true
front=false;m.open('com.brave.Browser',done)
m.open('com.apple.Safari',done);assert(not result[1])
for i=1,25 do callback() end
assert(not result[1] and keys==priorKeys and #paths==0)
front=true;m.open('com.brave.Browser',done);callback()
assert(result[1] and keys==priorKeys+1 and #paths==0)
for _,id in ipairs({'com.microsoft.edgemac','org.mozilla.firefox','com.unknown.Browser'}) do
    m.open(id,done);assert(not result[1] and keys==priorKeys+1)
end
print('Brave: permission, installed directory, launch, busy, focus, timeout, exact opener and unsupported browsers passed')
