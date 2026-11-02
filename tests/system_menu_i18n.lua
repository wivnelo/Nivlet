package.path='Toolkit/?.lua;'..package.path
local tick,copied=0,nil
hs={settings={get=function()return nil end},
 host={cpuUsageTicks=function()tick=tick+10;return {[1]={},[2]={},overall={user=tick,nice=0,system=0,idle=tick}}end,vmStat=function()return {memSize=1073741824,pageSize=1,pagesFree=536870912}end},
 fs={volume={allVolumes=function()return {['/']={NSURLVolumeTotalCapacityKey=1073741824,NSURLVolumeAvailableCapacityKey=536870912}}end}},
 network={primaryInterfaces=function()return 'en0'end,interfaceDetails=function()return {IPv4={Addresses={'192.0.2.42'}},IPv6={Addresses={'2001:db8::42'}}}end},
 timer={secondsSinceEpoch=function()return 10 end},pasteboard={setContents=function(value)copied=value end},
}
local i18n=require('modules.i18n')
local sys=require('modules.sys_info')
sys.lunar='fixture-lunar';sys.openSettings=function()end
local labels={'CPU 使用率','内存使用率','磁盘使用率','局域网 IPv4','IPv6 地址','公历与星期','农历'}
sys.snapshot()
for _,language in ipairs({'zh-Hans','en','zh-Hant','ja'}) do
 i18n.configure(language)
 local menu=sys.menuItems()
 for index,key in ipairs(labels) do assert(menu[index].title:sub(1,#i18n.t(key)+2)==i18n.t(key)..': ','Menu field '..key..' / '..language) end
 assert(menu[1].title:find('2 '..i18n.t('核心'),1,true),'Localized CPU unit')
 assert(menu[#menu].title==i18n.t('系统信息设置…'))
 for index,value in pairs({[4]='192.0.2.42',[5]='2001:db8::42',[7]='fixture-lunar'}) do
  menu[index].fn();assert(copied==value,'Copy must preserve the original machine value')
 end
 local snapshot=sys.snapshot()
 assert(snapshot.cpu=='50% / 2 Core','Internal CPU format changed')
 assert(snapshot.memory=='50% / 1 GB' and snapshot.disk=='50% / 1 GB')
 assert(snapshot.ipv4=='192.0.2.42' and snapshot.ipv6=='2001:db8::42' and snapshot.mac==nil and snapshot.lunar=='fixture-lunar')
end
print('System menu labels and core unit localized in four languages; snapshots, parsing and copied values unchanged')
