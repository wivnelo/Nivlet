package.path='Toolkit/?.lua;'..package.path
local M=require('modules.sys_info')
assert(M.speed(0)=='0 B/s' and M.speed(1024)=='1.0 KB/s' and M.speed(1048576)=='1.0 MB/s')
M.accept({interfaces={en0={rx=100,tx=200}},lunar='test'},'en0',10);assert(M.rx==0)
M.accept({interfaces={en0={rx=3100,tx=6200}}},'en0',13);assert(M.rx==1000 and M.tx==2000)
M.accept({interfaces={en1={rx=9000,tx=9000}}},'en1',15);assert(M.rx==0)
M.accept({interfaces={en1={rx=10,tx=10}}},'en1',17);assert(M.rx==0 and M.tx==0)
M.accept({interfaces={}},'en1',19);assert(M.previous==nil)
print('Network elapsed sampling, interface changes, counter resets and speed units passed')
local title,icon,deleted,width,frame
M.menu={setTitle=function(self,v) title=v;return self end,setIcon=function(self,v) icon=v;return self end}
hs={canvas={new=function() return {appendElements=function() end,minimumTextSize=function() return {w=41.2,h=22} end,size=function(_,v) width=v.w end,elementAttribute=function(_,i,k,v) assert(i==1 and k=='frame');frame=v end,imageFromCanvas=function() return 'icon' end,delete=function() deleted=true end} end}}
M.draw();assert(title=='' and icon=='icon' and deleted and width==44 and frame.w==44)
print('Menu icon replaces placeholder title and releases canvas passed')
