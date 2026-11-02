
package.path='Toolkit/?.lua;'..package.path
local opened, alerts, checks, reads = {}, {}, {}, {}
local files={
    ['/previews/A.html']='file', ['/previews/B.HTM']='file',
    ['/previews/中文 空格 #?%25.html']='file', ['/previews/literal%2F.html']='file',
    ['/previews/link.html']='file', ['/previews/folder.html']='directory',
    ['/previews/pipe.html']='named pipe', ['/previews/unreadable.html']='file',
    ['/Applications/Safari.app']='directory', ['/Applications/Chrome.app']='directory',
}
local installed={['com.apple.Safari']='/Applications/Safari.app',['com.google.Chrome']='/Applications/Chrome.app'}
hs={
    fs={attributes=function(path,attribute)
        assert(attribute=='mode');checks[#checks+1]=path;return files[path]
    end},
    settings={get=function() return nil end,set=function() error('Opening HTML must not save settings') end},
    application={pathForBundleID=function(id) return installed[id] end,applicationForPID=function()
        return {bundleID=function() return 'com.apple.mail' end}
    end},
    urlevent={openURLWithBundle=function(url,bundle) opened[#opened+1]={url,bundle};return true end,
        processStartupEvents=function() end,
        setDefaultHandler=function() error('Must not change defaults') end},
    alert={show=function(message) alerts[#alerts+1]=message end},
}
local originalOpen=io.open
io.open=function(path,mode)
    assert(mode=='rb');reads[#reads+1]=path
    if path=='/previews/unreadable.html' then return nil,'permission denied' end
    assert(files[path]=='file','Only verified regular files can be read')
    return {close=function() end}
end
local localHTML=require('modules.local_html')
local b=require('modules.browser');b.start()
b.config={enabled=true,defaultBrowser='com.google.Chrome',
    rules={{domain='example.com',browser='com.apple.Safari',subdomains=true}},
    appRules={{bundleID='com.apple.mail',name='Mail',browser='com.apple.Safari'}}}

local valid={
    {'file:///previews/A.html','file:///previews/A.html'},
    {'FILE://LOCALHOST/previews/B.HTM','file:///previews/B.HTM'},
    {'file:///previews/中文 空格 %23%3f%2525.html','file:///previews/%E4%B8%AD%E6%96%87%20%E7%A9%BA%E6%A0%BC%20%23%3F%2525.html'},
    {'file:///previews/literal%252F.html','file:///previews/literal%252F.html'},
    {'file:///previews/A.html?mode=preview&value=a%26b%3Dc#中文 章节','file:///previews/A.html?mode=preview&value=a%26b%3Dc#%E4%B8%AD%E6%96%87%20%E7%AB%A0%E8%8A%82'},
    {'file:///previews/A.html#chapter?part=1','file:///previews/A.html#chapter?part=1'},
    {'file:///previews/A.html?#','file:///previews/A.html?#'},
    {'file:///previews/link.html','file:///previews/link.html'},
}
for _,pair in ipairs(valid) do
    assert(localHTML.normalize(pair[1])==pair[2],pair[1])
    local target,err,url=b.resolve(pair[1],'com.apple.mail')
    assert(target=='com.google.Chrome' and err==nil and url==pair[2])
    assert(b.open(pair[1],'com.apple.mail'))
    assert(opened[#opened][1]==pair[2] and opened[#opened][2]=='com.google.Chrome')
end
b.config.enabled=false
assert(b.open('file:///previews/A.html','com.apple.mail') and opened[#opened][2]=='com.google.Chrome')
b.config.enabled=true

local invalid={
    'file://remote.example/previews/A.html','file://user@localhost/previews/A.html',
    'file://localhost:80/previews/A.html','file://127.0.0.1/previews/A.html',
    'file://[::1]/previews/A.html','file://localhost./previews/A.html',
    'file:/previews/A.html','file://previews/A.html','file:previews/A.html',
    'file:////remote/previews/A.html','file:///%2Fremote/A.html',
    'file:///previews/A.txt','file:///previews/A.html.lua','file:///previews/A',
    'file:///previews/missing.html','file:///previews/folder.html','file:///previews/pipe.html',
    'file:///previews/unreadable.html','file:///previews/A.html/',
    'file:///previews/A%00.html','file:///previews/A%0a.html','file:///previews/A\n.html',
    'file:///previews/A%7f.html','file:///previews/A%FF.html',
    'file:///previews/A%.html','file:///previews/A%0.html','file:///previews/A%GG.html',
    'file:///previews/A.html?bad=%','file:///previews/A.html#bad=%0D',
    'file:///previews/A.html?bad=%00','file:///previews/A.html#bad=%FF',
    'file:///previews/'..string.rep('a',16384)..'.html',
    'javascript:alert(1)','data:text/html,hello','ftp://localhost/A.html',
    'x-apple.systempreferences:com.apple.Desktop-Settings.extension',
}
for _,url in ipairs(invalid) do
    local count=#opened
    assert(not b.open(url),url)
    assert(#opened==count,'Invalid URL reached a browser: '..url)
end
for _,url in ipairs({
    'file:///previews/./A.html', 'file:///previews/sub/../A.html',
    'file:///previews/%2e/A.html', 'file:///previews/sub/%2E%2e/A.html',
    'file:///previews/%2E%2E/A.html',
}) do
    local count=#checks
    assert(not localHTML.normalize(url))
    assert(#checks==count,'Dot-segment URL must be rejected before filesystem access')
end

assert(b.resolve('https://example.com/example','com.apple.mail')=='com.apple.Safari')
assert(b.resolve('https://other.example/example','com.apple.mail')=='com.apple.Safari')
assert(b.resolve('https://other.example/example','com.other.app')=='com.google.Chrome')
assert(not b.resolve('https://user@example.com/'))
assert(not b.resolve('https://example.com/a b'))
local count=#opened
installed['com.google.Chrome']=nil
assert(not b.open('file:///previews/A.html') and #opened==count)
installed['com.google.Chrome']='/Applications/Removed.app'
assert(not b.open('file:///previews/A.html') and #opened==count)
installed['com.google.Chrome']='/Applications/Chrome.app'
b.config.defaultBrowser='dev.local.DesktopToolkit'
assert(not b.open('file:///previews/A.html') and #opened==count)
b.config.defaultBrowser='com.google.Chrome'
hs.urlevent.openURLWithBundle=function() return false end
assert(not b.open('file:///previews/A.html'))
hs.urlevent.openURLWithBundle=function(url,bundle) opened[#opened+1]={url,bundle};return true end


hs.settings.get=function(key)
    if key=='desktoptoolkit.browser.v1' then return b.config end
end
hs.urlevent.processStartupEvents=function()
    assert(type(hs.urlevent.httpCallback)=='function')
    hs.urlevent.httpCallback('file',nil,{},'file:///previews/A.html',-1)
end
b.start()
assert(opened[#opened][1]=='file:///previews/A.html' and opened[#opened][2]=='com.google.Chrome')
hs.urlevent.httpCallback('file',nil,{},'file:///previews/A.txt',-1)
assert(#alerts==1)
require('modules.i18n').configure('en')
local _,message=localHTML.normalize('file:///previews/A.txt')
assert(message=='Local files must use .html or .htm')
io.open=originalOpen
print('Local HTML dispatch: encoding, query/fragment, fallback, unsafe URLs, file types, missing browsers, cold start and English errors passed')
