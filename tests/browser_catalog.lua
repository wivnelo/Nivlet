package.path='Toolkit/?.lua;'..package.path
local catalog=require('modules.browser_catalog')
local installed={['com.apple.Safari']=true,['com.google.Chrome']=true,['com.brave.Browser']=true,['org.mozilla.firefox']=true,['com.microsoft.edgemac']=true}
hs={application={pathForBundleID=function(id)return installed[id] and '/Applications/'..id..'.app' or nil end},fs={attributes=function()return 'directory' end,displayName=function(path)return path:match('([^/]+)$') end}}
local browser=require('modules.browser')
local first=browser.installed()
assert(#first==5 and #catalog.browsers==5)
for _,item in ipairs(first) do
    assert(item.name==item.id)
    assert(item.capabilities.clearBrowsingData==(item.id=='com.apple.Safari' or item.id=='com.google.Chrome' or item.id=='com.brave.Browser'))
end
first[1].name='mutated';first[1].capabilities.clearBrowsingData=false
assert(browser.installed()[1].capabilities.clearBrowsingData and catalog.browsers[1].name=='Safari')
installed['com.brave.Browser']=nil
assert(#browser.installed()==4 and not catalog.get('com.unknown.Browser'))
print('Browser catalog: fixed allowlist, installed names, capabilities, fresh snapshots and removal passed')
