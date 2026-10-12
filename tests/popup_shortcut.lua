package.path="Toolkit/?.lua;"..package.path
local stored, bindings, blocked, fail={}, {}, false, false
local popped=0
local function signature(mods,key) return table.concat(mods,'+')..'+'..key end
local function menu() return {removeFromMenuBar=function(self) return self end,returnToMenuBar=function(self) return self end,isInMenuBar=function() return false end,size=function(self) return self end,setIcon=function(self) return self end,setTitle=function(self) return self end,setTooltip=function(self) return self end,setMenu=function(self,fn) self.items=fn;return self end,popupMenu=function(_,point) assert(point.x==-100 and point.y==20);popped=popped+1 end} end
hs={application={pathForBundleID=function()return nil end,nameForBundleID=function()return nil end},autoLaunch=function() return false end,image={imageFromPath=function(path) if path:match('document.on.clipboard.png$') or path:match('nivlet%-menu.png$') then return menu() end end,imageFromName=menu},processInfo={bundleID='dev.local.DesktopToolkit',bundlePath='.'},configdir='/isolated/toolkit',
 settings={bundleID='dev.local.DesktopToolkit',get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end,clear=function(k) stored[k]=nil end},
 menuIcon=function(value) assert(value==false) end,openConsoleOnDockClick=function(value) assert(value==false) end,nivletAppearance=function() end,menubar={new=menu},mouse={absolutePosition=function() return {x=-100,y=20} end},alert={show=function() end},accessibilityState=function() return true end,
 hotkey={systemAssigned=function(_,key) return blocked and key=='9' end,assignable=function(mods,key) return not bindings[signature(mods,key)] end,
 bind=function(mods,key,callback) if fail and key=='8' then return nil end;local sig=signature(mods,key);bindings[sig]=callback;return {delete=function() bindings[sig]=nil end} end}}
package.loaded['modules.sys_info']={start=function() end,menu=menu()}
dofile('Toolkit/init.lua');assert(not desktopToolkit.popupShortcut and not desktopToolkit.popupBinding and next(bindings)==nil)
local ctrl={key='k',mods={'cmd','ctrl'}}
assert(desktopToolkit.savePopup(ctrl));assert(desktopToolkit.popupShortcut.key=='K')
assert(stored['desktoptoolkit.clipboard.shortcut.v1'].mods[1]=='ctrl')
bindings['ctrl+cmd+K']();assert(popped==1)
assert(desktopToolkit.savePopup(ctrl));assert(bindings['ctrl+cmd+K'])
assert(not desktopToolkit.save({enabled=false,shortcuts={left={key='k',mods={'ctrl','cmd'}}}}));assert(bindings['ctrl+cmd+K'])
assert(not desktopToolkit.savePopup({key='K',mods={'shift'}}));assert(bindings['ctrl+cmd+K'])
blocked=true;assert(not desktopToolkit.savePopup({key='9',mods={'ctrl'}}));assert(bindings['ctrl+cmd+K'])
fail=true;assert(not desktopToolkit.savePopup({key='8',mods={'ctrl'}}));assert(bindings['ctrl+cmd+K'])
assert(stored['desktoptoolkit.clipboard.shortcut.v1'].key=='K')
assert(desktopToolkit.savePopup({key='',mods={}}));assert(next(bindings)==nil and not stored['desktoptoolkit.clipboard.shortcut.v1'])
assert(desktopToolkit.save({enabled=true,shortcuts={left={key='1',mods={'ctrl'}}}}))
assert(not desktopToolkit.savePopup({key='1',mods={'ctrl'}}));assert(bindings['ctrl+1'])
assert(desktopToolkit.savePopup(ctrl));assert(stored['desktoptoolkit.clipboard.shortcut.v1'].key=='K')
-- A fresh process has no runtime bindings, while settings persist.
bindings={};dofile('Toolkit/init.lua');assert(bindings['ctrl+cmd+K'])
assert(desktopToolkit.savePopup({key='',mods={}}));assert(bindings['ctrl+1'])
print('Popup defaults, normalization, cross-module conflicts, rollback, dispatch, removal and cold-start restoration passed')

-- Native menu callbacks supply metadata as their second argument, not a focus ID.
require('modules.input_method').sources=function() return {} end
require('modules.browser').status=function() return {active=true} end
require('modules.browser').installed=function() return {} end
require('modules.clipboard').snapshot=function() return {} end
hs.json={encode=function(value)
    local function check(v)
        assert(type(v)~='function','Menu callback leaked into settings JSON')
        if type(v)=='table' then for _,item in pairs(v) do check(item) end end
    end
    check(value);return '{}'
end}
hs.drawing={windowLevels={normal=0}}
hs.dockicon={show=function() end,hide=function() end}
desktopToolkit.settings={level=function(self,value) assert(value==0);return self end,hswindow=function() return {application=function() return {activate=function() end} end,focus=function() end} end,show=function(self) return self end,bringToFront=function(self) return self end,evaluateJavaScript=function() end}
desktopToolkit.menu.items[1].fn(nil,{fn=function() end})
assert(desktopToolkit.settingsFocus==nil and desktopToolkit.settingsSection==nil)
print('Native menu metadata is not treated as a settings focus ID')
