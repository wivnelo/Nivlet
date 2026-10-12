package.path = "Toolkit/?.lua;" .. package.path
local current, writes, callback, starts, stops, saved = "source.a", 0, nil, 0, 0, nil
hs={settings={get=function() return saved end,set=function(_,v) saved=v end},keycodes={
    layouts=function(ids) return ids and {"source.a"} or {"A"} end,
    methods=function(ids) return ids and {"source.b"} or {"B"} end,
    currentSourceID=function(id) if id then current=id;writes=writes+1;return true end;return current end},
    application={watcher={activated=5,new=function(fn) callback=fn;return {
        start=function(self) starts=starts+1;return self end,
        stop=function() stops=stops+1 end} end}}}
local m=require("modules.input_method")
m.start();assert(starts==0 and writes==0)
assert(not m.save({enabled=true,rules={{bundleID="org.test.editor",sourceID="gone"}}}))
assert(starts==0)
local rule={bundleID="org.test.editor",sourceID="source.b",name="Editor"}
assert(not m.save({enabled=true,rules={rule,rule}}))
assert(m.save({enabled=true,rules={rule}}));assert(starts==1 and writes==0)
callback(nil,2,{bundleID=function() return "org.test.editor" end});assert(writes==0)
callback(nil,5,{bundleID=function() return "org.test.other" end});assert(writes==0)
callback(nil,5,{bundleID=function() return "org.test.editor" end});assert(writes==1 and current=="source.b")
callback(nil,5,{bundleID=function() return "org.test.editor" end});assert(writes==1)
assert(m.save({enabled=false,rules={rule}}));assert(stops==1 and not m.watcher)
assert(m.apply({bundleID=function() return "org.test.editor" end})==false)
current="source.a";m.start();assert(not m.config.enabled and starts==1)
assert(m.save({enabled=true,rules={rule}}));assert(starts==2)
m.configure({enabled=false,rules={}})
print("Input rules validation, activation matching, no-op, lifecycle and persistence passed")

assert(not m.validate({enabled=false,rules={rule,{bundleID='ORG.TEST.EDITOR',sourceID='source.a'}}}))
local i18n=require('modules.i18n')
hs.keycodes.layouts=function(ids)return ids and {'com.apple.keylayout.ABC'} or {'ABC'}end
hs.keycodes.methods=function(ids)return ids and {'com.apple.inputmethod.SCIM.ITABC','third.party.input'} or {'Pinyin – Simplified','Third Party'}end
i18n.configure('zh-Hans');local sources=m.sources();assert(sources[1].name=='ABC' and sources[2].name=='简体拼音' and sources[3].name=='Third Party')
i18n.configure('en');assert(m.sources()[2].name=='Pinyin – Simplified')
assert(m.sources()[2].id=='com.apple.inputmethod.SCIM.ITABC')
print('Known system source Chinese label, English/ABC/third-party names and stable ID passed')
