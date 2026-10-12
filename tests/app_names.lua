package.path='Toolkit/?.lua;'..package.path
hs={application={pathForBundleID=function(id)return id~='missing' and '/Applications/Test.app' or nil end,infoForBundlePath=function()return {CFBundleName='Raw'}end},fs={displayName=function()return 'Visual Studio Code.app' end}}
local names=require('modules.app_names')
assert(names.get('installed','Code')=='Visual Studio Code')
assert(names.get('missing','Old')=='Old');assert(names.get('missing')=='missing')
hs.fs.displayName=function()return '备忘录.app' end;assert(names.get('installed')=='备忘录')
hs.fs.displayName=function()return '' end;assert(names.get('installed')=='Raw')
local config={enabled=true,rules={{bundleID='installed',name='Old',sourceID='unchanged'}},appRules={{bundleID='installed',name='Other',browser='Safari'}}}
local snapshot=names.snapshot(config)
assert(snapshot.rules[1].name=='Raw' and snapshot.appRules[1].name=='Raw')
assert(config.rules[1].name=='Old' and config.appRules[1].name=='Other')
assert(snapshot.rules[1].sourceID=='unchanged' and snapshot.appRules[1].browser=='Safari')
print('Unified system display names, missing app fallback and nonmutating rule snapshots passed')
