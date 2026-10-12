local f=assert(io.open('Toolkit/init.lua'));local source=f:read('*a');f:close()
local branch=assert(source:match('(if body%.action=="chooseLauncherApp" and type%(body%.replaceBundleID%).-\n                    else.- end)'))
local run=assert(load('return function(body,value,app,hs,callback) '..branch..' end'))()
local calls={}
local hs={json={encode=function(value)
    assert(type(value)=='table','hs.json.encode accepts tables only')
    if value[1] then return '["'..value[1]..'"]' end
    return '{"bundleID":"com.example.new","name":"New"}'
end}}
local app={settings={evaluateJavaScript=function(_,js) calls[#calls+1]=js end}}
run({action='chooseLauncherApp',replaceBundleID='com.example.old'},{bundleID='com.example.new',name='New'},app,hs,'window.addLauncherRule(')
assert(calls[1]=='window.replaceLauncherApp({"bundleID":"com.example.new","name":"New"},["com.example.old"][0])')
run({action='chooseLauncherApp'},{},app,hs,'window.addLauncherRule(')
assert(calls[2]=='window.addLauncherRule({"bundleID":"com.example.new","name":"New"},true)')
print('Native app replacement bridge uses table-only JSON encoding; add-app path preserved')
