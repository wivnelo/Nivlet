package.path = "Toolkit/?.lua;" .. package.path
local bundleIDs = require("modules.bundle_id")
-- CFBundleIdentifier 不强制反向域名；FinalShell 用的就是 "st"。
for _,id in ipairs({"st","com.apple.Safari","dev.local.DesktopToolkit","Chrome","a-b_c","app.2","x"}) do
    assert(bundleIDs.valid(id),id)
end
for _,id in ipairs({"","not a bundle id",".leading","com/apple","com:apple","中文","app\n","com.apple.Safari\0"}) do
    assert(not bundleIDs.valid(id),id)
end
for _,value in ipairs({{},42,true}) do assert(not bundleIDs.valid(value)) end
assert(not bundleIDs.valid(nil))
assert(bundleIDs.valid(string.rep("a",255)) and not bundleIDs.valid(string.rep("a",256)))
print("Bundle ID validation accepts dotless and rejects malformed, oversized or non-string values")
