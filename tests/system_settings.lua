package.path='Toolkit/?.lua;'..package.path
local saved,drawn
local menuChanges={}
local nativeMenu={setMenu=function(self,value) menuChanges[#menuChanges+1]={value=value};return self end}
hs={settings={set=function(_,v) saved=v end},host={cpuUsageTicks=function() return {overall={user=1,nice=0,system=1,idle=8}} end,vmStat=function() return {memSize=100,pageSize=1} end},fs={volume={allVolumes=function() return {} end}},network={primaryInterfaces=function() return 'en0' end,interfaceDetails=function() return {IPv4={Addresses={'192.0.2.1'}},IPv6={Addresses={'::1'}}} end}}
local s=require('modules.sys_info');s.menu=nativeMenu;s.draw=function() drawn=true end;s.openSettings=function() end
local cfg=s.defaults();for _,field in ipairs(s.fields) do cfg[field]=false end
assert(s.save(cfg) and drawn and saved.network==false);local menu=s.menuItems();assert(#menu==3 and menu[1].disabled and menu[3].fn)
cfg.cpu=true;cfg.date=true;assert(s.save(cfg));menu=s.menuItems();assert(menu[1].title:match('^CPU 使用率:') and menu[2].title:match('^公历与星期:') and #menu==4)
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
assert(snapshot.ipv4=="192.0.2.1" and snapshot.ipv6=="::1" and snapshot.mac==nil)
assert(snapshot.network=="N/A" and snapshot.disk=="N/A")
s.accept({interfaces={en0={rx=100,tx=100}}},"en0",17)
s.accept({interfaces={en0={rx=2100,tx=4100}}},"en0",19)
assert(s.snapshot().network:find("KB/s",1,true))
hs.timer.secondsSinceEpoch=function() return 30 end
assert(s.snapshot().network=="N/A")
assert(s.config.cpu==nil,"Snapshot must not alter display settings")
print("Live values include hidden fields, missing values and stale network samples without changing configuration")

-- Older persisted/exported selections remain valid without resetting other fields.
for _,legacy in ipairs({true,false,"ignored legacy value"}) do
 local old=s.defaults();old.mac=legacy;old.ipv4=false;old.network=false
 local config=assert(s.validate(old));assert(config.mac==nil and config.ipv4==false and config.network==false and config.ipv6==true)
 assert(old.mac==legacy,"Validation must not mutate stored input")
end
for _,address in ipairs({"02:00:00:00:00:00","02:12:34:56:78:9a"}) do
 s.accept({interfaces={en0={rx=5000,tx=6000,mac=address}}},"en0",31)
 assert(s.snapshot().mac==nil and s.mac==nil and s.macRestricted==nil)
 for _,item in ipairs(s.menuItems()) do assert(not item.title:find("MAC",1,true) and not item.title:find("系统已隐藏",1,true)) end
end
assert(#s.fields==8 and s.defaults().mac==nil)
print("Retired MAC values are ignored; old selections remain valid and other network fields survive")
