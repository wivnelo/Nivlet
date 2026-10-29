package.path='Toolkit/?.lua;'..package.path
local saved,opened
hs={settings={get=function() return saved end,set=function(_,v) saved=v end},application={pathForBundleID=function(id) if id~='org.mozilla.firefox' then return '/installed.app' end end},urlevent={processStartupEvents=function() end,openURLWithBundle=function(url,id) opened={url,id};return true end},alert={show=function() end}}
local b=require('modules.browser');b.start();assert(not b.config.enabled)
local cfg=b.defaults();cfg.enabled=true;cfg.rules={{domain='Example.COM',browser='com.google.Chrome',subdomains=true}}
assert(b.save(cfg));assert(saved.rules[1].domain=='example.com')
assert(b.resolve('https://example.com/a?x=1')=='com.google.Chrome')
assert(b.resolve('https://a.example.com:443/x')=='com.google.Chrome')
assert(b.resolve('https://notexample.com')=='com.apple.Safari')
assert(b.resolve('https://example.com.evil.test')=='com.apple.Safari')
for _,url in ipairs({'file:///x','javascript:alert(1)','https://user@example.com','https://example.com:99999','https://example.com/a b','https://example.com\n'}) do assert(not b.resolve(url)) end
assert(b.open('https://example.com/x') and opened[2]=='com.google.Chrome')
cfg.rules[1].subdomains=false;assert(b.save(cfg));assert(b.resolve('https://a.example.com')=='com.apple.Safari')
cfg.rules[1].browser='org.mozilla.firefox';assert(not b.save(cfg));assert(b.config.rules[1].browser=='com.google.Chrome')
cfg.rules[1].browser='com.google.Chrome';cfg.enabled=false;assert(b.save(cfg));assert(b.resolve('https://example.com')=='com.apple.Safari')
b.start();assert(b.config.enabled==false and hs.urlevent.httpCallback)
print('Browser domain boundaries, URL rejection, missing app, dispatch and persistence passed')
cfg.enabled=true;cfg.rules={{domain='example.com',browser='com.google.Chrome',subdomains=true}};cfg.appRules={{bundleID='com.apple.mail',name='Mail',browser='com.microsoft.edgemac'}}
assert(b.save(cfg));assert(b.resolve('https://other.test','com.apple.mail')=='com.microsoft.edgemac');assert(b.resolve('https://example.com','com.apple.mail')=='com.google.Chrome');assert(b.resolve('https://other.test','com.other.app')=='com.apple.Safari')
hs.application.applicationForPID=function(pid) if pid==42 then return {bundleID=function() return 'com.apple.mail' end} end end
b.start();hs.urlevent.httpCallback('https','other.test',{},'https://other.test',42);assert(opened[2]=='com.microsoft.edgemac')
cfg.appRules[2]=cfg.appRules[1];assert(not b.save(cfg));assert(#b.config.appRules==1)
print('Source application rules, domain priority, sender PID and duplicate rejection passed')

local startupCount=0
hs.urlevent.processStartupEvents=function()
    startupCount=startupCount+1
    assert(type(hs.urlevent.httpCallback)=='function')
    hs.urlevent.httpCallback('https','other.test',{},'https://other.test',42)
end
b.start()
assert(startupCount==1 and opened[2]=='com.microsoft.edgemac')
print('Startup URLs drain only after HTTP callback is installed')

local caseDuplicate=b.defaults();caseDuplicate.appRules={{bundleID='com.example.app',name='App',browser='com.apple.Safari'},{bundleID='COM.EXAMPLE.APP',name='App',browser='com.apple.Safari'}};assert(not b.validate(caseDuplicate))

-- FinalShell 等应用的 Bundle ID 没有点号，来源应用规则必须接受。
local dotless=b.defaults();dotless.appRules={{bundleID='st',name='FinalShell',browser='com.apple.Safari'}}
assert(b.validate(dotless).appRules[1].bundleID=='st')
dotless.appRules[1].bundleID='not a bundle id';assert(not b.validate(dotless))
dotless.appRules[1].bundleID='';assert(not b.validate(dotless))
print('Browser app rules accept dotless bundle IDs and reject malformed ones')

assert(b.resolve('https://other.test','COM.APPLE.MAIL')=='com.microsoft.edgemac')
hs.urlevent.getDefaultHandler=function() return 'org.hammerspoon.Hammerspoon' end
assert(not b.status().active)
hs.urlevent.getDefaultHandler=function() return 'dev.local.DesktopToolkit' end
assert(b.status().active)
hs.urlevent.getDefaultHandler=function(scheme) return scheme=='https' and 'com.apple.Safari' or 'dev.local.DesktopToolkit' end
assert(not b.status().active)
print('Source bundle matching is case-insensitive; both HTTP and HTTPS must be handled by Nivlet')

local requested
hs.urlevent.setDefaultHandler=function(scheme,bundle,urlOnly) requested={scheme,bundle,urlOnly} end
b.requestDefault();assert(requested[1]=='https' and requested[2]=='dev.local.DesktopToolkit' and requested[3]==true)
assert(b.openDefaultSettings());assert(opened[1]=='x-apple.systempreferences:com.apple.Desktop-Settings.extension' and opened[2]=='com.apple.systempreferences')
print('Explicit default browser request and system settings fallback passed')

-- Launch Services may retain an application path after the app is removed.
hs.fs={attributes=function(path,field) assert(field=='mode');return path=='/installed.app' and 'directory' or nil end}
hs.application.pathForBundleID=function(id)
    if id=='com.apple.Safari' then return '/installed.app' end
    if id=='com.google.Chrome' then return '/removed/Google Chrome.app' end
end
local installed=b.installed()
assert(#installed==1 and installed[1].id=='com.apple.Safari','Removed Chrome must not appear in installed browsers')
print('Installed browser list excludes stale application paths')

-- Localhost, single-label LAN names and IPv6 literals are real navigation targets.
for _,url in ipairs({
    'http://localhost:3000/',
    'http://localhost./',
    'http://wiki/page',
    'http://wiki:8080/page',
    'https://[::1]/',
    'https://[::1]:8443/x',
    'https://[0:0:0:0:0:0:0:1]/',
    'https://[2001:db8::1]/',
    'https://[::ffff:127.0.0.1]/',
    'http://127.0.0.1:8080/x',
}) do
    assert(b.resolve(url)=='com.apple.Safari', url)
end
assert(b.resolve('https://example.com/a')=='com.google.Chrome')
assert(b.resolve('https://example.com.evil.test')=='com.apple.Safari')
for _,url in ipairs({
    'file:///x','javascript:alert(1)','https://user@example.com','https://example.com:99999',
    'https://example.com/a b','https://example.com\n','https://user@[::1]/','https://[::1]:99999/',
    'https://[gggg::1]/','https://[::1::2]/','https://[:::1]/','http://[::1','http://-bad/','http://./',
    'http://localhost:0/','https://[::ffff:999.1.1.1]/',
}) do
    assert(not b.resolve(url), url)
end
local previous=b.config
local loopback=b.defaults(); loopback.enabled=true
loopback.rules={{domain='127.0.0.1',browser='com.google.Chrome',subdomains=true}}
b.config=assert(b.validate(loopback))
assert(b.resolve('http://127.0.0.1:8080/x')=='com.google.Chrome')
assert(b.resolve('https://[::ffff:127.0.0.1]/')=='com.apple.Safari')
assert(b.resolve('http://localhost:3000/')=='com.apple.Safari')
b.config=previous
print('Localhost, single-label and IPv6 hosts resolve; malicious URLs stay rejected')
