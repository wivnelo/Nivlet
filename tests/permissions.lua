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
local role,message="AXApplication",nil
hs.axuielement={applicationElement=function() return {attributeValue=function(_,attribute) assert(attribute=="AXRole");return role,message end} end}
assert(p.snapshot().accessibility=="granted")
role=nil;message="The accessibility API is disabled";assert(p.snapshot().accessibility=="denied")
message="Cannot complete";assert(p.snapshot().accessibility=="error")
print("Cross-process AX probe detects stale trusted status after signing and distinguishes transient errors")

hs.urlevent.openURLWithBundle=function(url,bundle) assert(url=="x-apple.systempreferences:com.apple.LoginItems-Settings.extension" and bundle=="com.apple.systempreferences");return true end
assert(p.openLoginSettings());hs.urlevent.openURLWithBundle=function() return false end;assert(not p.openLoginSettings())
print("Login Items opener preserves system launch success/failure")
