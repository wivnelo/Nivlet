-- Copying an image: fingerprint and size come from the clipboard's PNG bytes, the history file is
-- those bytes as is, and nothing is re-encoded (the old path pushed memory past 2 GB).
package.path='Toolkit/?.lua;'..package.path
local now,count,stored,encodes=1000,0,{},0
local directory=os.getenv('TMPDIR')..'/nivlet-clip-png-'..tostring(os.time())
os.execute('mkdir -p '..directory)
local imageMock={size=function() return {w=5120,h=2820} end,encodeAsURLString=function() encodes=encodes+1;return 'data:image/png;base64,x' end,
  setSize=function(self) return self end,saveToFile=function() error('must not re-encode when PNG bytes exist') end}
local png='\137PNG\r\n\26\nraw-bytes-'
hs={hash={SHA256=function(v) return 'sha('..#v..')' end},configdir=directory,
 settings={get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end,clear=function(k) stored[k]=nil end},
 fs={mkdir=function(p) os.execute('mkdir -p "'..p..'"');return true end,symlinkAttributes=function(p) local f=io.open(p,'rb');if f then local n=f:seek('end');f:close();return {mode=p:match('%.png$') and 'file' or 'directory',size=n} end end},
 image={imageFromPath=function() return imageMock end},alert={show=function(m) error(m) end},
 application={frontmostApplication=function() return {bundleID=function() return 'org.test' end} end},
 timer={secondsSinceEpoch=function() return now end,doEvery=function() return {stop=function() end} end,doAfter=function() return {stop=function() end} end},
 pasteboard={changeCount=function() return count end,contentTypes=function() return {'public.png'} end,readImage=function() return imageMock end,
  readDataForUTI=function(_,uti) return png..count end,getContents=function() return nil end}}
hs.canvas={new=function() return {imageFromCanvas=function() return {size=function() return {w=10,h=5} end,encodeAsURLString=function() return 'data:image/png;base64,small' end,saveToFile=function(_,path) local f=io.open(path,'wb');if not f then return false end;f:write('small');f:close();return true end} end,delete=function() end} end}
local c=require('modules.clipboard');c.start();local cfg=c.defaults();cfg.enabled=true;cfg.persistent=true;assert(c.save(cfg))
-- readDataForUTI is called as hs.pasteboard.readDataForUTI("public.png"): first argument is the UTI.
hs.pasteboard.readDataForUTI=function(uti) assert(uti=='public.png');return png..count end
count=count+1;c.poll()
local e=c.entries[1]
assert(e and e.kind=='image' and e.fingerprint=='png:sha('..#(png..count)..')' and e.menuBytes==#(png..count),'Fingerprint and size from PNG bytes')
assert(encodes==0,'No PNG/base64 re-encode on copy')
assert(c.persist())
local f=io.open(e.path,'rb');local written=f:read('a');f:close()
assert(written==png..count and e.png==nil,'History file is the clipboard PNG, and the bytes are released after writing')
-- Same image again replaces it; a different one is added.
local same=count;count=count+1;hs.pasteboard.readDataForUTI=function() return png..same end;c.poll()
assert(#c.entries==1,'Same PNG de-duplicates')
count=count+1;hs.pasteboard.readDataForUTI=function() return png..'other' end;c.poll()
assert(#c.entries==2 and encodes==0)
os.execute('rm -rf "'..directory..'"')
print('clipboard images use PNG bytes: no re-encode on copy or save')
