package.path = "Toolkit/?.lua;" .. package.path
local stored, callbacks = {}, {}
local function menu() return setmetatable({}, {__index=function() return function(self) return self end end}) end
hs = {
    image={imageFromName=function() return menu() end,imageFromPath=function() return menu() end},autoLaunch=function() return false end,
    processInfo={bundleID="dev.local.DesktopToolkit",bundlePath="."}, configdir="/isolated/toolkit",
    settings={bundleID="dev.local.DesktopToolkit",clear=function(k) stored[k]=nil end,get=function(k) return stored[k] end,set=function(k,v) stored[k]=v end},
    accessibilityState=function() return true end,
    menuIcon=function(value) assert(value==false) end,openConsoleOnDockClick=function(value) assert(value==false) end,nivletAppearance=function() end,menubar={new=menu}, alert={show=function() end},
    hotkey={assignable=function(_,k) return k ~= "9" end,systemAssigned=function() return false end,
        bind=function(_,k,fn) callbacks[k]=fn; return {delete=function() callbacks[k]=nil end} end},
}
package.loaded["modules.sys_info"]={start=function() end,menu=menu(),menuItems=function() return {} end}
dofile("Toolkit/init.lua")
assert(#desktopToolkit.bindings==0)
local old={enabled=true,shortcuts={left={key="1",mods={"ctrl","alt","cmd","shift"}}}}
assert(desktopToolkit.save(old)); assert(#desktopToolkit.bindings==1 and callbacks["1"])
local failure={enabled=true,shortcuts={left={key="2",mods={"ctrl"}},right={key="9",mods={"ctrl"}}}}
assert(not desktopToolkit.save(failure))
assert(callbacks["1"] and not callbacks["2"] and desktopToolkit.config.shortcuts.left.key=="1")
assert(stored["desktoptoolkit.preferences.v1"].shortcuts.left.key=="1")
local w={id=function() return 123 end,isStandard=function() return true end,isFullScreen=function() return false end,
    screen=function() return {frame=function() return {x=-1000,y=0,w=1000,h=800} end} end}
local actual={x=10,y=30,w=600,h=400}
w.frame=function() return actual end; w.setFrame=function(_,f) actual=f end
hs.window={focusedWindow=function() return w end}
callbacks["1"](); assert(actual.x==-1000 and actual.w==500)
assert(require("modules.windows").run("restore",w)); assert(actual.x==10 and actual.w==600)
assert(not require("modules.windows").run("restore",w))
assert(desktopToolkit.save({enabled=false,shortcuts={}})); assert(#desktopToolkit.bindings==0 and not callbacks["1"])
print("Runtime binding rollback, dispatch, restore and disable passed")

assert(desktopToolkit.general.showMenu and desktopToolkit.general.appearance=="system")
assert(not desktopToolkit.saveGeneral({showMenu=true,appearance="invalid"}))
assert(not stored["desktoptoolkit.general.v1"])
assert(desktopToolkit.saveGeneral({showMenu=false,appearance="dark"}))
assert(stored["desktoptoolkit.general.v1"].appearance=="dark")
assert(desktopToolkit.saveGeneral({showMenu=true,appearance="light"}))
assert(desktopToolkit.saveGeneral({showMenu=true,appearance="system"}))
local opened
local original=desktopToolkit.openSettings
desktopToolkit.openSettings=function(section) opened=section end
hs.dockIconClickCallback()
assert(opened=="generalSection")
desktopToolkit.openSettings=original
print("General settings validation, persistence and reopen dispatch passed")

assert(desktopToolkit.general.language=="system")
assert(not desktopToolkit.saveGeneral({showMenu=true,appearance="system",language="fr"}))
assert(desktopToolkit.saveGeneral({showMenu=true,appearance="system",language="en"}))
assert(require("modules.i18n").t("设置…")=="Settings…")
assert(stored["desktoptoolkit.general.v1"].language=="en")
assert(desktopToolkit.saveGeneral({showMenu=true,appearance="system",language="zh-Hans"}))
assert(require("modules.i18n").t("设置…")=="设置…")
print("Language validation, persistence and immediate switching passed")

local launcher=require("modules.launcher")
assert(launcher.save({enabled=true,rules={{bundleID="com.example.probe",name="Probe",shortcut={key="J",mods={"ctrl"}}}}}))
assert(not desktopToolkit.savePopup({key="j",mods={"ctrl"}}))
assert(not desktopToolkit.save({enabled=true,shortcuts={left={key="J",mods={"ctrl"}}}}))
assert(desktopToolkit.savePopup({key="K",mods={"ctrl"}}))
assert(not launcher.save({enabled=true,rules={{bundleID="com.example.probe",shortcut={key="K",mods={"ctrl"}}}}}))
assert(desktopToolkit.save({enabled=false,shortcuts={right={key="L",mods={"ctrl"}}}}))
assert(not launcher.save({enabled=true,rules={{bundleID="com.example.probe",shortcut={key="L",mods={"ctrl"}}}}}))
assert(callbacks["J"] and launcher.config.rules[1].shortcut.key=="J")
print("Bidirectional launcher, window and clipboard shortcut conflicts passed")

-- Import must release all three shortcut owners before moving a binding.
hs.application={pathForBundleID=function() return "/Applications/Test.app" end}
local manager=desktopToolkit.configuration
local function document(modules) return {format="Nivlet",version=1,modules=modules} end
assert(manager.apply(document({windows={enabled=true,shortcuts={left={key="J",mods={"ctrl"}}}},launcher={enabled=false,rules={}},popupShortcut=false})))
assert(callbacks["J"] and not callbacks["K"] and #launcher.bindings==0)
local before=stored["desktoptoolkit.preferences.v1"]
local imported,message=manager.apply(document({windows={enabled=true,shortcuts={left={key="9",mods={"ctrl"}}}},popupShortcut=false,launcher={enabled=false,rules={}}}))
assert(not imported and message:find("已恢复原配置",1,true))
assert(callbacks["J"] and not callbacks["9"] and desktopToolkit.config.shortcuts.left.key=="J")
assert(stored["desktoptoolkit.preferences.v1"]==before)
assert(manager.apply(document({windows={enabled=false,shortcuts={}},popupShortcut={key="J",mods={"ctrl"}}})))
assert(desktopToolkit.popupBinding and callbacks["J"] and #desktopToolkit.bindings==0)
print("Actual runtime import swaps shortcut owners and restores bindings plus saved configuration after registration failure")

assert(desktopToolkit.savePopup(nil))
assert(desktopToolkit.save({enabled=false,shortcuts={grid9={key="up",mods={"ctrl"}}}}))
assert(not launcher.save({enabled=true,rules={{bundleID="com.example.probe",shortcut={key="up",mods={"ctrl"}}}}}))
assert(not desktopToolkit.savePopup({key="up",mods={"ctrl"}}))
print("New window actions participate in runtime launcher and clipboard conflict checks")

local general=desktopToolkit.general
assert(desktopToolkit.saveGeneral({showMenu=general.showMenu,appearance=general.appearance,language=general.language,tabOrder={"launcherSection","windowSection"}}))
assert(stored["desktoptoolkit.general.v1"].tabOrder[1]=="launcherSection")
for _,order in ipairs({{"generalSection"},{"windowSection","windowSection"},{"unknownSection"},false,{[2]="windowSection"}}) do
 assert(not desktopToolkit.saveGeneral({showMenu=true,appearance="system",tabOrder=order}))
end
assert(desktopToolkit.general.tabOrder[1]=="launcherSection")
print("Tab order persistence and invalid order rejection passed")
local exported=manager.export()
assert(exported.modules.general.tabOrder[1]=="launcherSection")
assert(manager.apply(document({general={showMenu=true,appearance="system",language="system",tabOrder={"browserSection","windowSection"}}})))
assert(desktopToolkit.general.tabOrder[1]=="browserSection")
assert(not manager.prepare(document({general={showMenu=true,appearance="system",tabOrder={"generalSection"}}})))
assert(manager.apply(document({general={showMenu=true,appearance="system",language="system"}})))
assert(#desktopToolkit.general.tabOrder==0)
print("Tab order JSON round-trip and legacy configuration compatibility passed")

local savedOpenSettings=desktopToolkit.openSettings
local openedSection
desktopToolkit.openSettings=function(section) openedSection=section end
hs.openPreferences();assert(openedSection=="generalSection")
desktopToolkit.openSettings=savedOpenSettings
print("Embedded runtime preferences API opens Nivlet General settings")

local previous=desktopToolkit.general
assert(desktopToolkit.setShowMenu(false));assert(not desktopToolkit.general.showMenu)
assert(desktopToolkit.general.appearance==previous.appearance and desktopToolkit.general.language==previous.language)
assert(desktopToolkit.setShowMenu(true));assert(desktopToolkit.general.showMenu)
assert(not desktopToolkit.setShowMenu("true"));assert(desktopToolkit.general.showMenu)
print("Immediate main menu toggle persists only visibility, preserving other General settings")

local iconCalls=0
local setIcon=desktopToolkit.menu.setIcon
desktopToolkit.menu.setIcon=function(self,image,template) assert(image==desktopToolkit.mainIcon and template==true);iconCalls=iconCalls+1;return self end
assert(desktopToolkit.setShowMenu(false));assert(iconCalls==0)
assert(desktopToolkit.setShowMenu(true));assert(iconCalls==1)
desktopToolkit.menu.setIcon=setIcon
print("Showing a previously hidden status item reapplies its N template icon")

local order={}
local c=require("modules.clipboard").menu
local s=require("modules.sys_info").menu
c.removeFromMenuBar=function(self) order[#order+1]="clip-hide";return self end
c.returnToMenuBar=function(self) order[#order+1]="clip-show";return self end
s.removeFromMenuBar=function(self) order[#order+1]="system-hide";return self end
s.returnToMenuBar=function(self) order[#order+1]="system-show";return self end
desktopToolkit.arrangeMenus()
assert(table.concat(order,",")=="clip-hide,clip-show,system-hide,system-show")
print("Grouping restores Clipboard then System to the left of Main")

assert(desktopToolkit.saveGeneral({showMenu=true,appearance="system",tabOrder={"aboutSection","browserSection","windowSection"}}))
assert(table.concat(desktopToolkit.general.tabOrder,",")=="browserSection,windowSection")
assert(manager.prepare(document({general={showMenu=true,appearance="system",tabOrder={"windowSection","aboutSection","browserSection"}}})))
print("Legacy About position normalizes without changing movable module order")

-- Sleep reservation participates in all shortcuts and JSON owner transfers.
hs.caffeinate={systemSleep=function() error("Tests must not sleep the machine") end}
assert(desktopToolkit.save({enabled=false,shortcuts={}}))
assert(launcher.save({enabled=false,rules={}}))
local sleepGeneral={showMenu=true,appearance="system",sleepShortcut=true}
assert(desktopToolkit.saveGeneral(sleepGeneral) and callbacks.L)
assert(not desktopToolkit.savePopup({key="L",mods={"cmd"}}))
assert(not desktopToolkit.save({enabled=false,shortcuts={left={key="L",mods={"cmd"}}}}))
assert(not launcher.save({enabled=false,rules={{bundleID="com.example.probe",shortcut={key="L",mods={"cmd"}}}}}))
assert(not manager.prepare(document({popupShortcut={key="L",mods={"cmd"}}})))
assert(manager.apply(document({general={showMenu=true,appearance="system",sleepShortcut=false},popupShortcut={key="L",mods={"cmd"}}})))
assert(not require('modules.sleep').enabled and callbacks.L)
assert(not desktopToolkit.saveGeneral(sleepGeneral))
assert(desktopToolkit.savePopup(nil))
local login=false
hs.autoLaunch=function(value) if value~=nil then login=value end;return login end
assert(desktopToolkit.saveGeneralPage({showMenu=true,appearance="light"},true) and login)
assert(desktopToolkit.save({enabled=false,shortcuts={left={key="L",mods={"cmd"}}}}))
assert(not desktopToolkit.saveGeneralPage(sleepGeneral,false) and login)
assert(desktopToolkit.general.appearance=="light" and not require('modules.sleep').enabled)
local clip=require('modules.clipboard');local oldSave,oldValidate=clip.save,clip.validate
clip.validate=function(v) return v end
clip.save=function() return false,"Injected cache failure" end
assert(desktopToolkit.savePopup({key="Q",mods={"ctrl"}}))
assert(not desktopToolkit.saveClipboardPage({}, {key="W",mods={"ctrl"}}))
assert(desktopToolkit.popupShortcut.key=="Q" and callbacks.Q and not callbacks.W)
clip.save,clip.validate=oldSave,oldValidate
print("Sleep cross-module and import conflicts, owner transfer, General login rollback and combined clipboard save rollback passed")
