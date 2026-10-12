local f=assert(io.open('Toolkit/init.lua'));local source=f:read('*a');f:close()
local snippet=assert(source:match('(function app.showUpdateRecovery%(%).-)\napp.showUpdateRecovery%(%)'))
local pending,alerts,opened,choice=false,0,0,'Later'
local app={openSettings=function(section) assert(section=='aboutSection');opened=opened+1 end}
local hs={nivletTakeUpdateRecovery=function() local value=pending;pending=false;return value end,timer={doAfter=function(delay,fn) assert(delay==0);fn() end},dialog={blockAlert=function() alerts=alerts+1;return choice end}}
local i18n={t=function(value) return value=='稍后' and 'Later' or value end}
assert(load(snippet,nil,'t',{app=app,hs=hs,i18n=i18n}))()
app.showUpdateRecovery();assert(alerts==0)
pending=true;app.showUpdateRecovery();assert(alerts==1 and opened==0)
app.showUpdateRecovery();assert(alerts==1)
pending=true;choice='检查更新…';app.showUpdateRecovery();assert(alerts==2 and opened==1)
hs.nivletTakeUpdateRecovery=nil;app.showUpdateRecovery();assert(alerts==2)
print('Update recovery: no marker, one-time notice, Later, review updates and legacy runtime passed')
