-- Saving the Screenshot page through the real settings runtime ("Save All Settings").
dofile('tests/runtime.lua')
local app=desktopToolkit
local capture=require('modules.capture')
local started,inputs=0,{}
hs.fs=hs.fs or {}
local attributes=hs.fs.attributes
hs.fs.attributes=function(path,...) if tostring(path):match('capture%-helper$') then return {mode='file'} end;return attributes and attributes(path,...) end
hs.json=hs.json or {}
hs.json.encode=hs.json.encode or function(v) return tostring(v.cmd) end
hs.task={new=function()
    local t={running=false}
    function t:start() self.running=true;started=started+1;return self end
    function t:isRunning() return self.running end
    function t:setInput(s) inputs[#inputs+1]=s end
    function t:closeInput() self.running=false end
    return t
end}

local function page(overrides)
    local config=capture.defaults()
    for k,v in pairs(overrides) do config[k]=v end
    return {captureSection={config=config}}
end

local result=app.saveAllSettings(page({enabled=true,shortcut={key='4',mods={'cmd','shift'}}}))
assert(result.ok, 'Screenshot page saves through the global save: '..tostring(result.message))
assert(capture.config.enabled and capture.config.shortcut.key=='4' and started==1)
assert(hs.settings.get('desktoptoolkit.capture.v1').shortcut.mods[2]=='shift')

-- A plain function key works through the same path.
result=app.saveAllSettings(page({enabled=true,shortcut={key='F13',mods={}}}))
assert(result.ok and capture.config.shortcut.key=='F13', tostring(result.message))

-- The same shortcut on another page is rejected and the saved screenshot key stays.
assert(app.save({enabled=true,shortcuts={left={key='F',mods={'ctrl','cmd'}}}}))
result=app.saveAllSettings(page({enabled=true,shortcut={key='F',mods={'ctrl','cmd'}}}))
assert(not result.ok and capture.config.shortcut.key=='F13', 'Cross-page conflict must be refused')
assert(app.save({enabled=false,shortcuts={}}))

-- Invalid values report the page instead of a generic invalid-page error.
result=app.saveAllSettings(page({format='gif'}))
assert(not result.ok and result.failedPage=='captureSection', tostring(result.message))

result=app.saveAllSettings(page({enabled=false}))
assert(result.ok and not capture.config.enabled)
print('Screenshot page: global save, function keys, conflicts and validation passed')
