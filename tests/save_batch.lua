-- Isolated save-coordinator tests: no App, preferences, files, hotkeys or OS APIs.
package.path="Toolkit/?.lua;"..package.path
local batch=require("modules.save_batch")
local function copy(value)
    if type(value)~="table" then return value end
    local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
end
local function equal(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for key,item in pairs(a) do if not equal(item,b[key]) then return false end end
    for key in pairs(b) do if a[key]==nil then return false end end
    return true
end
local order={"generalSection","windowSection","inputSection","clipSection","systemSection","browserSection","launcherSection"}
local function setup(options)
    options=options or {}
    local state,events,saved,adapters={},{},{},{}
    for _,page in ipairs(order) do
        state[page]={value="old:"..page}
        adapters[page]={
            get=function()
                if options.getThrows==page then error("Injected read failure") end
                return state[page]
            end,
            validate=function(value)
                events[#events+1]={"validate",page}
                if options.validateThrows==page then error("Injected validation failure") end
                if type(value)~="table" or type(value.value)~="string" then return nil,"Invalid page value" end
                if options.invalid==page then return nil,"Invalid draft" end
                return copy(value)
            end,
            save=function(value)
                local restoring=value.value=="old:"..page
                events[#events+1]={"save",page,copy(value),restoring}
                saved[#saved+1]=page
                if options.restoreFails==page and restoring then return false,"Injected restore failure" end
                if options.restoreThrows==page and restoring then error("Injected restore exception") end
                if options.saveThrows==page and not restoring then error("Injected save exception") end
                if options.saveFails==page and not restoring then return false,"Injected save failure" end
                state[page]=copy(value)
                return true,"Saved "..page
            end,
        }
    end
    local environment={
        validate=function(plan)
            events[#events+1]={"preflight",copy(plan)}
            if options.preflightThrows then error("Injected preflight exception") end
            if options.preflightFails then return false,"Final candidate conflict",options.preflightFails end
            return true
        end,
        groupPages=function(plan)
            local selected={}
            for _,page in ipairs(options.group or {}) do if plan.selected[page] then selected[#selected+1]=page end end
            return selected
        end,
        beginGroup=function(plan,group)
            events[#events+1]={"begin",copy(group)}
            if options.beginThrows then error("Injected begin exception") end
            return true
        end,
        restoreGroup=function(plan,group,before)
            events[#events+1]={"restore",copy(group),copy(before)}
            if options.restoreGroupThrows then error("Injected restore-context exception") end
            return true
        end,
        endGroup=function()
            events[#events+1]={"end"}
            if options.endThrows then error("Injected cleanup exception") end
            return true
        end,
    }
    return {manager=batch.new(adapters,environment),state=state,events=events,saved=saved,adapters=adapters,environment=environment}
end
local function drafts(...)
    local result={};for _,page in ipairs({...}) do result[page]={value="new:"..page} end;return result
end
local function byPage(result)
    assert(type(result)=="table" and type(result.ok)=="boolean","apply must return an explicit result")
    local pages={}
    for _,item in ipairs(result.results or {}) do
        assert(not pages[item.page],"Each requested page needs exactly one final status")
        assert(item.status=="saved" or item.status=="failed" or item.status=="pending","Unexpected page status")
        pages[item.page]=item
    end
    return pages
end
local function count(events,kind)
    local n=0;for _,event in ipairs(events) do if event[1]==kind then n=n+1 end end;return n
end
local function noWrites(x)
    assert(#x.saved==0,"Validation failure must not mutate any module")
end

-- A clean current page cannot cause other selected pages to be omitted; only dirty
-- payload entries may be written and order is deterministic, not Lua table order.
local x=setup()
local payload=drafts("browserSection","inputSection","generalSection")
local original=copy(payload)
local result=x.manager.apply(payload)
assert(result.ok)
assert(equal(x.saved,{"generalSection","inputSection","browserSection"}))
assert(equal(payload,original),"Saving must not mutate the submitted snapshot")
local statuses=byPage(result)
for page in pairs(payload) do assert(statuses[page] and statuses[page].status=="saved") end
for _,page in ipairs({"windowSection","clipSection","systemSection","launcherSection"}) do
    assert(x.state[page].value=="old:"..page and not statuses[page],"Untouched page was written or reported")
end
local preflight,firstSave
for i,event in ipairs(x.events) do
    if event[1]=="preflight" then preflight=i end
    if event[1]=="save" and not firstSave then firstSave=i end
    if event[1]=="validate" then assert(not firstSave,"Validation occurred after a write") end
end
assert(preflight and firstSave and preflight<firstSave)

-- A prepared plan is detached from both caller input and live getter values.
x=setup();payload=drafts("browserSection")
local plan=x.manager.prepare(payload)
assert(plan and plan.selected.browserSection and not plan.selected.generalSection)
assert(equal(plan.order,{"browserSection"}))
plan.pages.browserSection.value="edited candidate"
plan.pages.generalSection.value="edited stored candidate"
assert(payload.browserSection.value=="new:browserSection")
assert(x.state.generalSection.value=="old:generalSection")
noWrites(x)

-- Reject malformed/unknown requests and any page validation before writing.
for _,bad in ipairs({false,"bad",17,{}, {unknownPage={value="x"}}, {browserSection=false}}) do
    x=setup();result=x.manager.apply(bad);assert(not result.ok);noWrites(x)
end
for _,options in ipairs({{invalid="browserSection"},{validateThrows="browserSection"},{preflightFails="browserSection"},{preflightThrows=true},{getThrows="browserSection"}}) do
    x=setup(options);result=x.manager.apply(drafts("generalSection","browserSection"))
    assert(not result.ok);noWrites(x)
    assert(type(result.message)=="string" and result.message~="","Failures need visible feedback")
end

-- An independent page failure stops subsequent writes without claiming rollback
-- of an earlier successful page. Retry can submit only still-dirty pages.
for _,failure in ipairs({"saveFails","saveThrows"}) do
    x=setup({[failure]="inputSection"})
    result=x.manager.apply(drafts("generalSection","inputSection","browserSection"))
    statuses=byPage(result)
    assert(not result.ok and result.failedPage=="inputSection")
    assert(statuses.generalSection.status=="saved")
    assert(statuses.inputSection.status=="failed")
    assert(statuses.browserSection.status=="pending")
    assert(equal(x.saved,{"generalSection","inputSection","inputSection"}))
    assert(result.recoveryAttempted and result.recoveryIncomplete==false)
    assert(equal(statuses.inputSection.current,x.state.inputSection))
    assert(x.state.generalSection.value=="new:generalSection")
    assert(x.state.browserSection.value=="old:browserSection")
end
x=setup();assert(x.manager.apply(drafts("generalSection")).ok)
x.saved[1]=nil
assert(x.manager.apply(drafts("inputSection","browserSection")).ok)
assert(equal(x.saved,{"inputSection","browserSection"}),"Retry rewrote a prior successful page")

-- Group failure must recover every released member, including members whose new
-- value was not reached. None may be acknowledged as saved afterwards.
x=setup({group={"windowSection","launcherSection"},saveFails="windowSection"})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
statuses=byPage(result)
assert(not result.ok and result.failedPage=="windowSection")
assert(statuses.windowSection.status~="saved" and statuses.launcherSection.status~="saved")
assert(statuses.browserSection.status=="pending")
assert(x.state.windowSection.value=="old:windowSection" and x.state.launcherSection.value=="old:launcherSection")
assert(count(x.events,"restore")==1 and count(x.events,"end")==1)
assert(equal(x.saved,{"windowSection","windowSection","launcherSection"}))

x=setup({group={"windowSection","launcherSection"},saveFails="launcherSection"})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
statuses=byPage(result)
assert(not result.ok and statuses.windowSection.status~="saved" and statuses.launcherSection.status~="saved")
assert(x.state.windowSection.value=="old:windowSection" and x.state.launcherSection.value=="old:launcherSection")
assert(count(x.events,"begin")==1 and count(x.events,"restore")==1 and count(x.events,"end")==1)

-- A page with released bindings but no attempted save can restore only those
-- bindings, avoiding unrelated persistence/history side effects.
x=setup({group={"windowSection","clipSection"},saveFails="windowSection"})
local restoreAttempt
x.adapters.clipSection.restore=function(value,attempted)
    restoreAttempt=attempted
    assert(value.value=="old:clipSection")
    return true
end
result=x.manager.apply(drafts("windowSection","clipSection"))
statuses=byPage(result)
assert(restoreAttempt==false and statuses.windowSection.attempted==true and not statuses.clipSection.attempted)
assert(equal(x.saved,{"windowSection","windowSection"}))
assert(equal(statuses.clipSection.current,x.state.clipSection))

-- Failed recovery still reports the actual module snapshot for draft/baseline
-- reconciliation; it does not claim the snapshot proves native state recovered.
x=setup({saveFails="inputSection",restoreFails="inputSection"})
result=x.manager.apply(drafts("inputSection"))
assert(not result.ok and result.recoveryIncomplete and result.results[1].current.value=="old:inputSection")

-- If the key group completed, a later independent failure must not undo it.
x=setup({group={"windowSection","launcherSection"},saveFails="browserSection"})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
statuses=byPage(result)
assert(not result.ok and statuses.windowSection.status=="saved" and statuses.launcherSection.status=="saved")
assert(statuses.browserSection.status=="failed" and count(x.events,"restore")==0)
assert(x.state.windowSection.value=="new:windowSection" and x.state.launcherSection.value=="new:launcherSection")

for _,failure in ipairs({"restoreFails","restoreThrows"}) do
    x=setup({group={"windowSection","launcherSection"},saveFails="launcherSection",[failure]="windowSection"})
    result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
    assert(not result.ok and result.recoveryIncomplete==true,"Failed compensation must be surfaced")
    assert(type(result.message)=="string" and result.message~="")
    assert(count(x.events,"end")==1,"Failure must not leak the coordinated conflict context")
    assert(x.state.browserSection.value=="old:browserSection")
end

-- Hooks can fail after partially releasing or finishing runtime changes; cleanup
-- must be attempted and already-applied pages cannot be called unexecuted.
x=setup({group={"windowSection","launcherSection"},beginThrows=true})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
assert(not result.ok and result.recoveryAttempted==true)
assert(count(x.events,"restore")==1 and count(x.events,"end")==1)
assert(x.state.windowSection.value=="old:windowSection" and x.state.launcherSection.value=="old:launcherSection")
assert(x.state.browserSection.value=="old:browserSection")
x=setup({group={"windowSection","launcherSection"},saveFails="launcherSection",restoreGroupThrows=true})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
assert(not result.ok and result.recoveryIncomplete==true and count(x.events,"end")==1)
x=setup({group={"windowSection","launcherSection"},endThrows=true})
result=x.manager.apply(drafts("windowSection","launcherSection","browserSection"))
statuses=byPage(result)
assert(not result.ok and result.recoveryIncomplete==true)
assert(statuses.windowSection.status~="pending" and statuses.launcherSection.status~="pending",
    "An already-applied group cannot be reported as unexecuted when cleanup fails")
assert(statuses.browserSection.status=="pending")

-- A model with occupied keys demonstrates why applying final-valid swapped values
-- one page at a time is insufficient, and why beginGroup must precede both saves.
local occupied={A="windowSection",B="launcherSection"}
local keyState={windowSection={value="A"},launcherSection={value="B"}}
local keyWrites={}
local keyAdapters={}
for _,page in ipairs(order) do
    keyState[page]=keyState[page] or {value="none:"..page}
    keyAdapters[page]={get=function()return keyState[page]end,
        validate=function(v)if type(v)~="table" or type(v.value)~="string" then return nil,"Invalid" end;return copy(v)end,
        save=function(v)
            keyWrites[#keyWrites+1]=page
            if occupied[v.value] and occupied[v.value]~=page then return false,"Key is still occupied" end
            occupied[v.value]=page;keyState[page]=copy(v);return true
        end}
end
local coordination={validate=function(plan)
    if plan.pages.windowSection.value==plan.pages.launcherSection.value then return false,"Duplicate final key","windowSection" end
    return true
end,groupPages=function(plan)
    local group={};for _,p in ipairs({"windowSection","launcherSection"}) do if plan.selected[p] then group[#group+1]=p end end;return group
end,beginGroup=function(_,group)
    for _,p in ipairs(group) do occupied[keyState[p].value]=nil end
    return true
end,restoreGroup=function(_,group)
    for key,p in pairs(occupied) do for _,selected in ipairs(group) do if p==selected then occupied[key]=nil end end end
    return true
end,endGroup=function()return true end}
local manager=batch.new(keyAdapters,coordination)
result=manager.apply({windowSection={value="B"},launcherSection={value="A"}})
assert(result.ok and occupied.A=="launcherSection" and occupied.B=="windowSection")
assert(equal(keyWrites,{"windowSection","launcherSection"}))
keyWrites={}
result=manager.apply({windowSection={value="A"}})
assert(not result.ok and #keyWrites==0,"Final conflicts must fail before releasing bindings or saving")

print("Global save batch: selected-only writes, preflight, draft isolation, ordered partial failure, group recovery and shortcut exchange passed")
