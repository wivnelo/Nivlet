-- Saves selected settings pages. This is a coordinated batch, not a transaction:
-- independent pages already saved remain saved after a later failure.
local i18n=require('modules.i18n')
local M={order={'generalSection','windowSection','inputSection','clipSection','systemSection','browserSection','launcherSection'}}
local function copy(value)
    if type(value)~='table' then return value end
    local result={};for key,item in pairs(value) do result[key]=copy(item) end;return result
end
local function failure() return i18n.t('保存失败，请检查设置') end
local function call(fn,...)
    local invoked,ok,message=pcall(fn,...)
    if not invoked then return false,failure() end
    if ok~=true then return false,message or failure() end
    return true,message
end
function M.new(adapters,environment)
    environment=environment or {}
    local manager={}
    function manager.prepare(pages)
        if type(pages)~='table' or not next(pages) then return nil,i18n.t('没有需要保存的修改') end
        for page in pairs(pages) do if not adapters[page] then return nil,i18n.t('保存页面无效') end end
        local plan={pages={},selected={},order={},before={}}
        for _,page in ipairs(M.order) do
            local adapter=adapters[page]
            if adapter then
                local ok,current=pcall(adapter.get)
                if not ok then return nil,failure(),page end
                plan.pages[page]=copy(current)
                if pages[page]~=nil then
                    local valid,normalized,message=pcall(adapter.validate,copy(pages[page]))
                    if not valid or normalized==nil then return nil,valid and message or failure(),page end
                    plan.before[page]=copy(current)
                    plan.pages[page]=normalized
                    plan.selected[page]=true
                    table.insert(plan.order,page)
                end
            end
        end
        if #plan.order==0 then return nil,i18n.t('保存页面无效') end
        if environment.validate then
            local ran,ok,message,page=pcall(environment.validate,plan)
            if not ran or not ok then return nil,ran and message or failure(),page end
        end
        return plan
    end
    function manager.apply(pages)
        local plan,message,failedPage=manager.prepare(pages)
        if not plan then return {ok=false,message=message or failure(),failedPage=failedPage,results={}} end
        local result,entries={ok=false,results={}},{}
        for _,page in ipairs(plan.order) do
            local entry={page=page,status='pending'}
            entries[page]=entry;table.insert(result.results,entry)
        end
        local group,groupSet={},{}
        if environment.groupPages then
            local ok,value=pcall(environment.groupPages,plan)
            if not ok or type(value)~='table' then result.message=failure();return result end
            for _,page in ipairs(value) do
                if plan.selected[page] and not groupSet[page] then table.insert(group,page);groupSet[page]=true end
            end
        end
        local function save(page,value) return call(adapters[page].save,copy(value)) end
        local function restore(page)
            return call(adapters[page].restore or adapters[page].save,copy(plan.before[page]),entries[page].attempted==true)
        end
        local function current(page)
            local ok,value=pcall(adapters[page].get)
            if ok then entries[page].current=copy(value) else result.recoveryIncomplete=true end
        end
        local function fail(page,errorMessage)
            result.failedPage=page;result.message=errorMessage or failure()
            if entries[page] then entries[page].status='failed';entries[page].message=result.message end
        end
        if #group>0 then
            local ok,errorMessage=true,nil
            if environment.beginGroup then ok,errorMessage=call(environment.beginGroup,plan,group) end
            local failed=group[1]
            if ok then
                for _,page in ipairs(group) do
                    entries[page].attempted=true
                    ok,errorMessage=save(page,plan.pages[page]);failed=page
                    if not ok then break end
                end
            end
            if not ok then
                result.recoveryAttempted=true
                local recovered=true
                if environment.restoreGroup then recovered=call(environment.restoreGroup,plan,group,plan.before) end
                for _,page in ipairs(group) do
                    local restored=restore(page);if not restored then recovered=false end
                    entries[page].status='failed'
                end
                if environment.endGroup then local ended=call(environment.endGroup);if not ended then recovered=false end end
                result.recoveryIncomplete=not recovered
                for _,page in ipairs(group) do current(page) end
                fail(failed,errorMessage)
                return result
            end
            if environment.endGroup then
                local ended=call(environment.endGroup)
                if not ended then
                    for _,page in ipairs(group) do entries[page].status='failed';current(page) end
                    result.recoveryIncomplete=true;fail(group[1],failure());return result
                end
            end
            for _,page in ipairs(group) do entries[page].status='saved' end
        end
        for _,page in ipairs(plan.order) do
            if not groupSet[page] then
                entries[page].attempted=true
                local ok,errorMessage=save(page,plan.pages[page])
                if not ok then
                    -- A module may throw after persistence or runtime application.
                    -- Restore only this failed page; earlier successful pages stand.
                    result.recoveryAttempted=true
                    result.recoveryIncomplete=not restore(page)
                    current(page);fail(page,errorMessage);return result
                end
                entries[page].status='saved'
            end
        end
        result.ok=true;return result
    end
    return manager
end
return M
