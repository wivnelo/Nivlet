local file=assert(io.open('tests/runtime.lua'));local source=file:read('a');file:close()
local prefix=assert(source:match('^(.-)dofile%("Toolkit/init.lua"%)'))
for _,case in ipairs({'default','legacy','system','display','failure','residual'}) do
 for name in pairs(package.loaded) do if name:match('^modules%.') then package.loaded[name]=nil end end
 assert(load(prefix))()
 local saved={showMenu=true,appearance='system',keepAwake=case~='legacy',keepDisplayOn=case=='display' or case=='failure' or case=='residual'}
 if case=='default' then saved=nil end
 if case=='legacy' then saved.keepAwake=nil;saved.keepDisplayOn=nil end
 hs.settings.set('desktoptoolkit.general.v1',saved)
 local calls,alerts=0,0
 hs.alert.show=function()alerts=alerts+1 end
 hs.caffeinate={nivletKeepAwake=function(a,d)
  calls=calls+1
  if case=='failure' then return false,true,false,false end
  if case=='residual' then return false,false,true,false end
  return true,true,a,a and d
 end,nivletStopKeepAwake=function()return true end}
 dofile('Toolkit/init.lua')
 local app=desktopToolkit
 if case=='default' or case=='legacy' then assert(calls==0 and not app.general.keepAwake and not app.general.keepDisplayOn)
 elseif case=='failure' then assert(calls==1 and alerts==1 and not app.general.keepAwake and saved.keepAwake)
 elseif case=='residual' then assert(calls==1 and alerts==1 and app.general.keepAwake and not app.general.keepDisplayOn and saved.keepDisplayOn)
 else assert(calls==1 and app.general.keepAwake and app.general.keepDisplayOn==(case=='display')) end
 hs.shutdownCallback()
end
print('Default/legacy/saved power settings, startup failure and residual assertion state passed with mock-only startup/shutdown')
