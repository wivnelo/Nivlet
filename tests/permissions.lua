package.path="Toolkit/?.lua;"..package.path
local p=require("modules.permissions")
hs={accessibilityState=function() return true end};assert(p.snapshot().accessibility=="granted")
hs.accessibilityState=function() return false end;assert(p.snapshot().accessibility=="denied")
hs.accessibilityState=function() error("Unavailable") end;assert(p.snapshot().accessibility=="error")
hs.accessibilityState=function() return nil end;assert(p.snapshot().accessibility=="error")
print("Accessibility allowed, denied and failed detection remain distinct")

local called=false
hs.urlevent={openURL=function() error("Generic URL opener rejects system preference links") end,openURLWithBundle=function(url,bundle)
 assert(url=="x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
 assert(bundle=="com.apple.systempreferences");called=true;return true
end}
assert(p.openSettings() and called)
hs.urlevent.openURLWithBundle=function() return false end
assert(p.openSettings()==false)
print("Accessibility settings uses explicit application opener and preserves failure result")

hs.accessibilityState=function() return true end
hs.application={get=function(id) assert(id=="com.apple.finder");return {} end}
local windows,message={},nil
hs.axuielement={applicationElement=function() return {attributeValue=function(_,attribute) assert(attribute=="AXWindows");return windows,message end} end}
assert(p.snapshot().accessibility=="granted")
windows=nil;message="The accessibility API is disabled";assert(p.snapshot().accessibility=="denied")
message="Cannot complete";assert(p.snapshot().accessibility=="error")
print("Cross-process AX probe detects stale trusted status after signing and distinguishes transient errors")

hs.urlevent.openURLWithBundle=function(url,bundle) assert(url=="x-apple.systempreferences:com.apple.LoginItems-Settings.extension" and bundle=="com.apple.systempreferences");return true end
assert(p.openLoginSettings());hs.urlevent.openURLWithBundle=function() return false end;assert(not p.openLoginSettings())
print("Login Items opener preserves system launch success/failure")

-- Reauthorization: a successful live AXWindows request must override a stale
-- false trust Boolean. An empty window list is a successful response too.
hs.accessibilityState=function() return false end
windows={};message=nil
local state=p.snapshot()
assert(state.accessibility=="granted" and p.isGranted())
windows="AXApplication";assert(p.snapshot().accessibility=="denied")
windows={};assert(p.snapshot().accessibility=="granted")
local updates=0
p.watch(function(value) updates=updates+1;assert(value.accessibility=="granted") end)
hs.accessibilityState=function() return true end
hs.accessibilityStateCallback();assert(updates==1 and p.isGranted())
windows=nil;message="The accessibility API is disabled"
assert(not p.isGranted())
hs.accessibilityState=function() return false end
message="Cannot complete";assert(p.snapshot().accessibility=="denied")
print("Reauthorization probes stale false, recovers on live AX access, refreshes on notification and detects revocation")
