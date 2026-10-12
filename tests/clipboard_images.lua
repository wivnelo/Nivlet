package.path='Toolkit/?.lua;'..package.path
local now,count,image,writes,keys,stored=1000,0,nil,0,0,{}
local directory='/private/tmp/Nivlet-test-images'
os.execute('mkdir -p '..directory)
local variant=0
local imageMock={size=function() return {w=20,h=10} end,encodeAsURLString=function() return 'data:image/png;base64,fixture'..variant end}
imageMock.setSize=function(self) return self end
imageMock.saveToFile=function(_,path) local f=assert(io.open(path,'wb'));f:write('fixture');f:close();return true end
hs={hash={SHA256=function(value) return value end},configdir=directory,settings={get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end,clear=function(k) stored[k]=nil end},
 fs={mkdir=function(path) os.execute('mkdir -p '..path);return true end,symlinkAttributes=function(path) local f=io.open(path,'rb');if f then local size=f:seek('end');f:close();return {mode=path:match('%.png$') and 'file' or 'directory',size=size or 0} end end},
 image={imageFromPath=function() return imageMock end},accessibilityState=function() return true end,alert={show=function(m) error(m) end},
 application={frontmostApplication=function() return {bundleID=function() return 'org.test.app' end,isRunning=function() return true end} end},
 eventtap={keyStroke=function() keys=keys+1 end},timer={secondsSinceEpoch=function() return now end,doEvery=function() return {stop=function() end} end,doAfter=function(_,fn) fn() end},
 pasteboard={changeCount=function() return count end,contentTypes=function() return {'public.png'} end,readImage=function() return image end,getContents=function() return nil end,writeObjects=function(v) assert(v==imageMock);writes=writes+1;count=count+1;return true end}}
hs.canvas={new=function() return {imageFromCanvas=function() return {} end,delete=function() end} end}
local c=require('modules.clipboard');c.start();local cfg=c.defaults();cfg.enabled=true;cfg.persistent=true;assert(c.save(cfg))
image=imageMock;for i=1,12 do variant=i;count=count+1;c.poll() end
assert(#c.entries==10 and #stored['desktoptoolkit.clipboard.history.v1']==10)
local previous=c.entries[1].path;count=count+1;c.poll();assert(#c.entries==10 and not io.open(previous,'rb'))
local path=c.entries[1].path;assert(path and io.open(path,'rb'))
assert(c.preview(c.entries[1].id).url:find('data:image/png',1,true));assert(not c.preview(-1))
local snap=c.snapshot();assert(snap.entries[1].preview and not snap.entries[1].image)
c.entries={};c.load();assert(#c.entries==10 and c.entries[1].kind=='image')
count=count+1;c.poll();assert(#c.entries==1,'Restored images must match the same encoded image')
assert(c.copy(c.entries[1].id));assert(writes==1)
local menu=c.menuItems();menu[3].fn({alt=true});assert(writes==2 and keys==1)
hs.accessibilityState=function() return false end;assert(not c.copy(c.entries[1].id,hs.application.frontmostApplication()) and writes==2)
now=now+cfg.minutes*60;c.prune();assert(#c.entries==0 and not io.open(path,'rb'))
assert(#stored['desktoptoolkit.clipboard.history.v1']==0 and not c.preview(1))
image=imageMock;count=count+1;c.poll();local kept=c.entries[1].path
cfg.enabled=false;assert(c.save(cfg));assert(#c.entries==1 and not c.timer and io.open(kept,'rb'))
table.insert(c.entries,{id=999,time=now,kind='text',text='retained while disabled'});assert(c.persist())
c.entries={};c.start();assert(not c.config.enabled and not c.timer and #c.entries==2 and c.preview(c.entries[1].id));assert(c.entries[2].text=='retained while disabled')
assert(c.copy(c.entries[1].id));assert(not c.pause())
c.clear();assert(#stored['desktoptoolkit.clipboard.history.v1']==0 and not io.open(kept,'rb'))
print('Image cap, thumbnail snapshot, cache reload/expiry and Option paste permission guard passed')
