package.path='Toolkit/?.lua;'..package.path
local stored={}
hs={settings={get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end},host={operatingSystemVersion=function() return {major=27} end}}
local translate=require('modules.translate')

-- Settings validation.
local d=translate.defaults()
assert(d.enabled==false and d.selectionTrigger=='doubleAlt' and d.mode=='auto' and d.remember and d.showSource and not d.autoCopy)
assert(not translate.validate({enabled=true,selectionTrigger='tripleAlt'}))
assert(not translate.validate({enabled=true,mode='xx'}))
assert(translate.validate({enabled=true,selectionTrigger='off'}).selectionTrigger=='off')
assert(translate.supported())
hs.host.operatingSystemVersion=function() return {major=14} end
assert(not translate.supported(), 'macOS 14 is not supported')

-- Double-tap detection: alone, twice, quickly; anything else cancels.
local now,fired=0,0
local function detector() return translate.newTapDetector('alt',function() fired=fired+1 end,function() return now end) end
local function tap(d,mod,gap) now=now+(gap or 0.05);d.flags({[mod]=true});now=now+0.05;d.flags({}) end
local d1=detector();tap(d1,'alt');tap(d1,'alt',0.1);assert(fired==1,'double tap fires')
fired=0;local d2=detector();tap(d2,'alt');tap(d2,'alt',0.6);assert(fired==0,'too slow does not fire')
fired=0;local d3=detector();tap(d3,'alt');d3.key();tap(d3,'alt',0.1);assert(fired==0,'a key between taps cancels')
fired=0;local d4=detector();tap(d4,'alt');now=now+0.05;d4.flags({alt=true,cmd=true});d4.flags({});tap(d4,'alt',0.1);assert(fired==0,'a shortcut with Option cancels')
fired=0;local d5=detector();now=now+1;d5.flags({alt=true});now=now+0.8;d5.flags({});tap(d5,'alt',0.1);assert(fired==0,'holding Option is not a tap')
fired=0;local d6=detector();tap(d6,'cmd');tap(d6,'cmd',0.1);assert(fired==0,'other modifiers do not fire')
fired=0;local d7=detector();tap(d7,'alt');tap(d7,'alt',0.1);tap(d7,'alt',0.1);assert(fired==1,'a third tap starts over')
fired=0;local d8=detector();now=now+0.05;d8.flags({alt=true,fn=true});now=now+0.05;d8.flags({});tap(d8,'alt',0.1);assert(fired==1,'fn is ignored')
assert(translate.validate({enabled=true}).screenshotTrigger=='doubleCtrl','Screenshot translation defaults to double Control')
assert(not translate.validate({enabled=true,selectionTrigger='doubleCtrl',screenshotTrigger='doubleCtrl'}),'Both triggers cannot share a key')
assert(translate.validate({enabled=true,selectionTrigger='off',screenshotTrigger='off'}))
print('translate module: settings validation and double-tap detection')
