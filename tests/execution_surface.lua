-- Packaged Info.plist / sdef must not advertise arbitrary Lua execution.
local handle=assert(io.open('patches/runtime-isolation.patch','r'))
local text=assert(handle:read('a'))
handle:close()

local function section(path)
    local marker='diff --git a/'..path..' b/'..path..'\n'
    local start=assert(text:find(marker,1,true),path)
    local nextStart=text:find('\ndiff --git ',start,true)
    return nextStart and text:sub(start,nextStart) or text:sub(start)
end

local function sides(body)
    local removed,kept={},{}
    for line in (body..'\n'):gmatch('(.-)\n') do
        local prefix=line:sub(1,1)
        local rest=line:sub(2)
        if line:sub(1,4)=='--- ' or line:sub(1,4)=='+++ ' or line:sub(1,6)=='index ' or line:sub(1,10)=='diff --git' or line:sub(1,2)=='@@' or line=='' then
        elseif prefix=='-' then table.insert(removed,rest)
        elseif prefix=='+' or prefix==' ' then table.insert(kept,rest) end
    end
    return table.concat(removed,'\n'), table.concat(kept,'\n')
end

local function absent(removed,kept,needle)
    assert(removed:find(needle,1,true), 'patch must delete '..needle)
    assert(not kept:find(needle,1,true), 'packaged result still contains '..needle)
end

local plistRemoved,plistKept=sides(section('Hammerspoon/Hammerspoon-Info.plist'))
absent(plistRemoved,plistKept,'HSExecuteLuaIntent')
absent(plistRemoved,plistKept,'INIntentsSupported')
absent(plistRemoved,plistKept,'NSAppleScriptEnabled')
absent(plistRemoved,plistKept,'OSAScriptingDefinition')
absent(plistRemoved,plistKept,'Hammerspoon.sdef')
assert(plistKept:find('NSUserActivityTypeBrowsingWeb',1,true))
assert(not plistKept:find('<key>NSAppleScriptEnabled</key>',1,true))

local sdefRemoved,sdefKept=sides(section('Hammerspoon/Hammerspoon.sdef'))
absent(sdefRemoved,sdefKept,'execute lua code')
absent(sdefRemoved,sdefKept,'HmSpEXEC')

local projectRemoved,projectKept=sides(section('Hammerspoon.xcodeproj/project.pbxproj'))
absent(projectRemoved,projectKept,'Intents.intentdefinition in Sources')
absent(projectRemoved,projectKept,'HSExecuteLuaIntentHandler.m in Sources')

local delegateRemoved,delegateKept=sides(section('Hammerspoon/MJAppDelegate.m'))
absent(delegateRemoved,delegateKept,'HSExecuteLuaIntent')
absent(delegateRemoved,delegateKept,'handlerForIntent')

print('Packaged Info.plist and sdef do not expose Shortcuts Lua or AppleScript Lua execution')
