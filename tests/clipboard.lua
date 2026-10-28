package.path="Toolkit/?.lua;"..package.path
local now,count,text,types,bundle,saved=1000,0,"before",{},"org.test.editor",nil
local reads,starts,stops=0,0,0
hs={settings={clear=function() end,get=function() return saved end,set=function(_,v) saved=v end},
 timer={secondsSinceEpoch=function() return now end,doEvery=function(_,fn) starts=starts+1;return {stop=function() stops=stops+1 end} end},
 application={frontmostApplication=function() return {bundleID=function() return bundle end} end},
 pasteboard={readImage=function() return nil end,changeCount=function() return count end,contentTypes=function() return types end,
 getContents=function() reads=reads+1;return text end,setContents=function(v) text=v;count=count+1;return true end}}
hs.canvas={new=function() return {imageFromCanvas=function() return {} end,delete=function() end} end}
local m=require('modules.clipboard');m.start();assert(starts==0 and reads==0)
local config=m.defaults();config.enabled=true;config.limit=10;config.minutes=1;config.excluded={'org.test.passwords'}
assert(m.save(config));m.poll();assert(#m.entries==0 and reads==0)
local function copy(v,t) text=v;types=t or {};count=count+1;m.poll() end
copy('one');copy('two');copy('one');assert(#m.entries==2 and m.entries[1].text=='one')
local id=m.entries[1].id;assert(m.copy(id));m.poll();assert(#m.entries==2)
assert(m.pause());copy('paused');assert(#m.entries==2);assert(m.pause());m.poll();assert(#m.entries==2)
bundle='org.test.passwords';local prior=reads;copy('secret');assert(reads==prior)
bundle='org.test.editor';copy('concealed',{'org.nspasteboard.ConcealedType'});copy('transient',{'org.nspasteboard.TransientType'});copy('file',{'public.file-url'});assert(reads==prior)
copy('');copy(string.rep('x',65537));assert(#m.entries==2)
for i=1,12 do copy('item'..i) end;assert(#m.entries==10 and m.entries[1].text=='item12')
now=now+60;assert(#m.snapshot().entries==0 and not m.copy(id))
copy('<script>test</script>');assert(#m.entries==1)
local bad=m.defaults();bad.limit=101;assert(not m.save(bad) and m.config.enabled)
-- 排除列表同样要接受没有点号的 Bundle ID，例如 FinalShell 的 "st"。
local dotless=m.defaults();dotless.excluded={'st'};assert(m.validate(dotless).excluded[1]=='st')
dotless.excluded={'not a bundle id'};assert(not m.validate(dotless))
dotless.excluded={''};assert(not m.validate(dotless))
config.enabled=false;assert(m.save(config));assert(#m.entries==1 and not m.timer and stops>0);local disabledReads=reads;copy("disabled-copy");assert(reads==disabledReads and #m.entries==1);assert(m.copy(m.entries[1].id));assert(not m.pause())
m.entries={};m.start();assert(not m.config.enabled and #m.entries==0)
assert(saved.entries==nil)
print('Clipboard bounds, deduplication, expiry, exclusion, privacy markers, pause, copy and memory-only lifecycle passed')

config.enabled=true;assert(m.save(config));copy(string.rep('测试',30));local menu=m.menuItems();assert(utf8.len(menu[3].title)==41);menu[3].fn();assert(text==string.rep('测试',30));config.enabled=false;assert(m.save(config))
print('Menu Unicode labels and selection callback passed')

local clears=0
hs.pasteboard.clearContents=function() clears=clears+1;text=nil;types={};count=count+1 end
hs.dialog={blockAlert=function() return "取消" end}
m.clear();config.enabled=true;assert(m.save(config));copy('clear-menu-fixture')
menu=m.menuItems();menu[1].fn();assert(#m.entries==1 and clears==0 and text=='clear-menu-fixture')
hs.dialog.blockAlert=function() return "清空" end
menu[1].fn();assert(#m.entries==0 and clears==1 and text==nil and m.lastCount==count)
m.poll();assert(#m.entries==0)
copy("internal-clear-fixture");m.clear();assert(text=="internal-clear-fixture" and clears==1)
print('Menu clear cancellation and confirmed history and system clipboard removal passed')

m.entries={{id=999,kind='image',time=now+0.25}}
menu=m.menuItems();assert(menu[3].title:match('^图片 %d%d:%d%d:%d%d$'))
m.entries={}
print('Fractional image timestamps render in the clipboard menu')

local icon={size=function(self,value) assert(value.w==18 and value.h==18);return self end}
local iconCalls=0
hs.processInfo={bundlePath="/test/Nivlet.app"}
hs.image={imageFromPath=function(path) assert(path=="/test/Nivlet.app/Contents/Resources/Toolkit/assets/document.on.clipboard.png");return icon end}
hs.menubar={new=function(visible) return {
    setTitle=function(self,title) assert(title=="");return self end,
    setIcon=function(self,image,template) assert(image==icon and template==true);iconCalls=iconCalls+1;return self end,
    setTooltip=function(self) return self end,setMenu=function(self) return self end,
} end}
m.startMenu(function() end);assert(iconCalls==1)
print('Clipboard menu uses the document.on.clipboard template icon at 18 points')

-- Permanent retention bypasses age expiry, not capacity or user actions.
config.enabled=true;config.minutes=0;config.limit=10;assert(m.save(config))
for i=1,12 do copy('permanent-'..i) end
now=now+60*60*48;m.prune();assert(#m.entries==10)
config.minutes=1440;assert(m.save(config));assert(#m.entries==0)
copy('one-day');now=now+1440*60-1;m.prune();assert(#m.entries==1)
now=now+1;m.prune();assert(#m.entries==0)
for _,minutes in ipairs({0,30,60,120,240,480,720,1440,113}) do config.minutes=minutes;assert(m.validate(config)) end
for _,minutes in ipairs({-1,1441,1.5,math.huge,0/0}) do config.minutes=minutes;assert(not m.validate(config)) end
config.minutes=0;config.enabled=false;assert(m.save(config));assert(#m.entries==0)
print('Permanent and 24-hour expiry, capacity, legacy values and numeric boundaries passed')
