package.path='Toolkit/?.lua;'..package.path
local saved,drawn
local menuChanges={}
local nativeMenu={setMenu=function(self,value) menuChanges[#menuChanges+1]={value=value};return self end}
hs={settings={set=function(_,v) saved=v end},host={cpuUsageTicks=function() return {overall={user=1,nice=0,system=1,idle=8}} end,vmStat=function() return {memSize=100,pageSize=1} end},fs={volume={allVolumes=function() return {} end}},network={primaryInterfaces=function() return 'en0' end,interfaceDetails=function() return {IPv4={Addresses={'192.0.2.1'}},IPv6={Addresses={'::1'}}} end}}
local s=require('modules.sys_info');s.menu=nativeMenu;s.draw=function() drawn=true end;s.mac='fixture';s.openSettings=function() end
local cfg=s.defaults();for _,field in ipairs(s.fields) do cfg[field]=false end
assert(s.save(cfg) and drawn and saved.network==false);local menu=s.menuItems();assert(#menu==3 and menu[1].disabled and menu[3].fn)
cfg.cpu=true;cfg.date=true;assert(s.save(cfg));menu=s.menuItems();assert(menu[1].title:match('^CPU:') and menu[2].title:match('^Date:') and #menu==4)
local invalid=s.defaults();invalid.disk='yes';assert(not s.save(invalid));assert(s.config.disk==false)
print('System display selection, all-hidden settings access and validation passed')

local before=#menuChanges
assert(s.save(s.defaults()))
assert(#menuChanges==before+2)
assert(menuChanges[before+1].value==nil and menuChanges[before+2].value==s.menuItems)
menu=s.menuItems()
assert(#menu>4 and menu[#menu].title=="系统信息设置…")
local calls=#menuChanges
assert(not s.save(invalid) and #menuChanges==calls)
print('Restoring hidden fields recreates native menu before dynamic binding; invalid save leaves menu intact')

hs.timer={secondsSinceEpoch=function() return 20 end}
s.config={};local snapshot=s.snapshot()
assert(snapshot.ipv4=="192.0.2.1" and snapshot.ipv6=="::1" and snapshot.mac=="fixture")
assert(snapshot.network=="N/A" and snapshot.disk=="N/A")
s.accept({interfaces={en0={rx=100,tx=100}}},"en0",17)
s.accept({interfaces={en0={rx=2100,tx=4100}}},"en0",19)
assert(s.snapshot().network:find("KB/s",1,true))
hs.timer.secondsSinceEpoch=function() return 30 end
assert(s.snapshot().network=="N/A")
assert(s.config.cpu==nil,"Snapshot must not alter display settings")
print("Live values include hidden fields, missing values and stale network samples without changing configuration")

s.accept({interfaces={en0={rx=5000,tx=6000,mac="02:00:00:00:00:00"}}},"en0",31)
assert(s.mac==nil and s.macRestricted)
assert(s.snapshot().mac=="系统已隐藏")
s.config=s.defaults();local restricted
for _,item in ipairs(s.menuItems()) do if item.title:match("^MAC:") then restricted=item end end
assert(restricted and restricted.disabled and not restricted.fn,"Placeholder must not be copyable")
s.accept({interfaces={en0={rx=6000,tx=7000,mac="02:12:34:56:78:9a"}}},"en0",33)
assert(s.mac=="02:12:34:56:78:9a" and not s.macRestricted,"Legitimate private addresses must remain visible")
s.accept({interfaces={}},"en0",35);assert(s.mac==nil and not s.macRestricted)
print("Redacted MAC placeholder is labelled and cannot be copied; valid private MAC remains supported")
