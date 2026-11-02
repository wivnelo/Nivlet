package.path='Toolkit/?.lua;'..package.path
local configKey='desktoptoolkit.clipboard.v1'
local historyKey='desktoptoolkit.clipboard.history.v1'
local function clone(value)
    if type(value)~='table' then return value end
    local result={};for key,item in pairs(value) do result[key]=clone(item) end;return result
end
local function config(enabled,paused)
    return {enabled=enabled,paused=paused,limit=50,minutes=0,images=false,persistent=true,excluded={'org.test.secret'}}
end
local function fixture(saved,failSettings)
    local state={stored={[configKey]=clone(saved),[historyKey]={{id=1,kind='text',time=1000,text='kept history'}}},
        now=1000,count=1,text='before enable',bundle='org.test.editor',reads=0,counts=0,active=0,started=0,stopped=0,writes=0,alerts=0,
        allowDirectory=true,failSettings=failSettings}
    local function makeTimer(delay,callback,once)
        state.active=state.active+1;state.started=state.started+1
        local timer={delay=delay,stopped=false}
        function timer:stop() if not self.stopped then self.stopped=true;state.active=state.active-1;state.stopped=state.stopped+1 end end
        timer.callback=function()
            if once then timer:stop() end

            local ok,message=pcall(callback)
            if not ok then timer:stop();error(message) end
        end
        return timer
    end
    hs={configdir='/isolated-fixture',settings={
        get=function(key) return clone(state.stored[key]) end,
        set=function(key,value)
            if state.failSettings=='return-false' then return false end
            if state.failSettings then error('Fixture settings permission failure') end
            state.writes=state.writes+1;state.stored[key]=clone(value)
        end,
        clear=function(key) state.stored[key]=nil end,
    },timer={secondsSinceEpoch=function() return state.now end,
        doEvery=function(interval,callback) assert(interval==0.5);return makeTimer(interval,callback,false) end,
        doAfter=function(delay,callback) assert(delay>0);return makeTimer(delay,callback,true) end,
    },pasteboard={
        changeCount=function() state.counts=state.counts+1;return state.count end,
        contentTypes=function() return {} end,
        getContents=function() state.reads=state.reads+1;return state.text end,
    },application={frontmostApplication=function() return {bundleID=function() return state.bundle end} end},
    fs={symlinkAttributes=function() return state.allowDirectory and {mode='directory'} or nil end,mkdir=function() return false end},
    alert={show=function() state.alerts=state.alerts+1 end},
    canvas={new=function() return {imageFromCanvas=function() return {} end,delete=function() end} end}}
    package.loaded['modules.clipboard']=nil
    local module=require('modules.clipboard');module.start()
    return module,state
end


for _,enabled in ipairs({true,false}) do
    local module,state=fixture(config(enabled,true))
    assert(not module.config.enabled and state.active==0 and state.reads==0)
    assert(state.stored[configKey].enabled==false and state.stored[configKey].paused==nil)
    assert(#module.entries==1 and module.entries[1].text=='kept history')
    assert(#state.stored[historyKey]==1 and state.stored[historyKey][1].text=='kept history')
    assert(module.pause==nil and module.paused==nil and module.snapshot().paused==nil)
    for _,item in ipairs(module.menuItems()) do
        assert(item.title~='暂停记录' and item.title~='恢复记录')
    end
    module.start();assert(not module.config.enabled and state.active==0 and #module.entries==1)
end
local migrated,failed=fixture(config(true,true),true)
assert(not migrated.config.enabled and failed.active==0 and failed.reads==0 and failed.alerts==1)
assert(failed.stored[configKey].paused==true,'Failed migration must retain the original stop intent')
migrated.start();assert(not migrated.config.enabled and failed.active==0)

for _,enabled in ipairs({true,false}) do
    local module,state=fixture(config(enabled,false))
    assert(module.config.enabled==enabled and state.active==(enabled and 1 or 0))
    assert(state.stored[configKey].paused==nil and state.stored[configKey].enabled==enabled)
    local current,currentState=fixture(config(enabled))
    assert(current.config.enabled==enabled and currentState.writes==0,'Unpaused current settings must not be migrated')
end
local fresh,freshState=fixture(nil)
assert(not fresh.config.enabled and freshState.active==0,'History collection default must remain off')
local invalid,invalidState=fixture(config(true,'invalid'))
assert(not invalid.config.enabled and invalidState.active==0,'Malformed retired state must not start collection')


local module,state=fixture(config(true))
assert(state.active==1 and state.reads==0)
for _=1,4 do assert(module.save(module.config));assert(state.active==1) end
local previousTimer=module.timer
local disabled=clone(module.config);disabled.enabled=false
assert(module.save(disabled));assert(state.active==0 and not module.timer and previousTimer.stopped)
assert(#module.entries==1 and #state.stored[historyKey]==1)
state.count=state.count+1;state.text='copied while disabled'
local beforeReads,beforeCounts=state.reads,state.counts
previousTimer.callback()
assert(state.reads==beforeReads and state.counts==beforeCounts and #module.entries==1,'Stopped callbacks must not inspect the clipboard')
module.start();assert(state.active==0 and #module.entries==1,'Disabled state and history must survive restart')
local enabled=clone(module.config);enabled.enabled=true
assert(module.save(enabled));module.poll()
assert(state.active==1 and state.reads==beforeReads and #module.entries==1,'Enable must not import existing clipboard content')
state.count=state.count+1;state.text='new allowed text';module.poll()
assert(#module.entries==2 and module.entries[1].text=='new allowed text')
state.bundle='org.test.secret';state.count=state.count+1;state.text='excluded'
beforeReads=state.reads;module.poll()
assert(state.reads==beforeReads and #module.entries==2,'Application privacy exclusions remain active')
state.bundle='org.test.editor'


local memory=clone(module.config);memory.persistent=false
assert(module.save(memory));local liveTimer=module.timer
state.allowDirectory=false
local persistent=clone(module.config);persistent.persistent=true
local ok=module.save(persistent)
assert(not ok and module.config.enabled and module.config.persistent==false and module.timer==liveTimer and state.active==1)


state.allowDirectory=true
local legacy=clone(module.config);legacy.paused=true
assert(module.save(legacy));assert(not module.config.enabled and not module.timer and state.active==0)
assert(state.stored[configKey].enabled==false and state.stored[configKey].paused==nil)
assert(module.pause==nil and module.paused==nil and module.snapshot().paused==nil)
assert(state.started-state.stopped==0)


local expiring=config(false);expiring.minutes=1
local stopped,expiryState=fixture(expiring)
assert(not stopped.timer and stopped.expiryTimer and expiryState.active==1)
local expiryTimer=stopped.expiryTimer
assert(expiryTimer.delay==60,'Disabled recording should sleep until the nearest expiry')
local counts,reads=expiryState.counts,expiryState.reads
expiryState.count=expiryState.count+1;expiryState.text='must never be read'
expiryState.now=1059;expiryTimer.callback()
assert(#stopped.entries==1 and expiryState.counts==counts and expiryState.reads==reads)
assert(stopped.expiryTimer~=expiryTimer and stopped.expiryTimer.delay==1 and expiryState.active==1)
local finalExpiry=stopped.expiryTimer
expiryState.now=1060;finalExpiry.callback()
assert(#stopped.entries==0 and #expiryState.stored[historyKey]==0 and expiryState.active==0)
assert(not stopped.timer and not stopped.expiryTimer and finalExpiry.stopped)
assert(expiryState.counts==counts and expiryState.reads==reads)


local timed=config(true);timed.minutes=1
local switching,switchState=fixture(timed)
for _=1,3 do
    local off=clone(switching.config);off.enabled=false
    assert(switching.save(off));assert(not switching.timer and switching.expiryTimer and switchState.active==1)
    local on=clone(switching.config);on.enabled=true
    assert(switching.save(on));assert(switching.timer and not switching.expiryTimer and switchState.active==1)
end
local off=clone(switching.config);off.enabled=false;assert(switching.save(off))
switching.clear();assert(switchState.active==0 and not switching.expiryTimer)


local shutdown,shutdownState=fixture(expiring)
local stale=shutdown.expiryTimer
shutdown.stop();assert(shutdownState.active==0 and not shutdown.timer and not shutdown.expiryTimer)
shutdownState.now=1060;local before=#shutdown.entries
stale.callback();assert(#shutdown.entries==before and shutdownState.active==0 and shutdownState.reads==0)
shutdown.start();assert(#shutdown.entries==0 and shutdownState.active==0)
local running,runningState=fixture(config(true))
local stalePoll=running.timer
running.stop();runningState.count=runningState.count+1
stalePoll.callback();assert(runningState.active==0 and runningState.reads==0)
assert(running.config.enabled and runningState.stored[configKey].enabled,'Shutdown must not overwrite the user preference')
local durable,durableState=fixture(config(true))
durableState.count=durableState.count+1;durableState.text='last record before shutdown';durable.poll()
assert(durableState.stored[historyKey][1].text=='last record before shutdown','Each record must be persisted synchronously')
durable.stop();assert(durableState.active==0 and durableState.stored[historyKey][1].text=='last record before shutdown')
durable.entries={};durable.start()
assert(durable.entries[1].text=='last record before shutdown' and durableState.active==1)
durable.stop()


for _,mode in ipairs({'throw','return-false','persist-false'}) do
    local retry,retryState=fixture(expiring)
    retry.entries={{id=1,kind='text',time=1000,text='first'},{id=2,kind='text',time=1030,text='second'}}
    retry.persist();retry.prune()
    local persist,attempts=retry.persist,0
    retry.persist=function()
        attempts=attempts+1
        if retryState.failPersist then return false,'Injected history write failure' end
        return persist()
    end
    local function fail(on)
        retryState.failPersist=on and mode=='persist-false'
        retryState.failSettings=on and mode~='persist-false' and (mode=='return-false' and 'return-false' or true) or false
    end
    fail(true);retryState.now=1060
    assert(pcall(retry.expiryTimer.callback),'Background expiry must contain storage exceptions')
    assert(#retry.entries==1 and retry.pendingHistoryWrite and attempts==1)
    assert(#retryState.stored[historyKey]==2 and retryState.active==1 and retry.expiryTimer.delay==5)
    local queued=retry.expiryTimer
    for tick=1061,1064 do retryState.now=tick;retry.prune() end
    assert(attempts==1 and retry.expiryTimer==queued and retryState.active==1,'Retries must be gated, without duplicate timers')
    fail(false);retryState.now=1065;retry.expiryTimer.callback()
    assert(attempts==2 and not retry.pendingHistoryWrite and #retryState.stored[historyKey]==1)
    assert(retry.expiryTimer.delay==25 and retryState.active==1,'Successful retry must schedule the next actual expiry')
    fail(true);retryState.now=1090;retry.expiryTimer.callback()
    assert(#retry.entries==0 and retry.pendingHistoryWrite and #retryState.stored[historyKey]==1)
    assert(retry.expiryTimer and retry.expiryTimer.delay==5 and retryState.active==1,'An empty history still needs its failed disk write retried')
    fail(false);retryState.now=1095;retry.expiryTimer.callback()
    assert(attempts==4 and #retryState.stored[historyKey]==0 and not retry.pendingHistoryWrite)
    assert(not retry.expiryTimer and retryState.active==0 and retryState.reads==0 and retryState.counts==0)
end


local coalesced,coalescedState=fixture(expiring)
coalesced.entries={{id=1,kind='text',time=1000,text='first'},{id=2,kind='text',time=1001,text='second'}}
coalesced.persist();coalesced.prune()
coalescedState.failSettings=true;coalescedState.now=1060;coalesced.expiryTimer.callback()
assert(coalesced.expiryTimer.delay==1 and coalesced.historyRetryAt==1065)
coalescedState.now=1061;coalesced.expiryTimer.callback()
assert(#coalesced.entries==0 and coalesced.historyRetryAt==1065 and coalesced.expiryTimer.delay==4)
local pending=coalesced.expiryTimer
coalesced.stop();assert(coalesced.pendingHistoryWrite and coalescedState.active==0)
coalescedState.failSettings=false;coalescedState.now=1100;pending.callback()
assert(#coalescedState.stored[historyKey]==2 and coalesced.pendingHistoryWrite and coalescedState.active==0,'A stale callback must not restart or commit after stop')
coalesced.start()
assert(#coalesced.entries==0 and #coalescedState.stored[historyKey]==0 and not coalesced.pendingHistoryWrite and coalescedState.active==0)
assert(coalescedState.reads==0 and coalescedState.counts==0)


local activeRetry,activeState=fixture(timed)
activeState.failSettings=true;activeState.now=1060;activeRetry.timer.callback()
assert(activeRetry.pendingHistoryWrite and not activeRetry.expiryTimer and activeState.active==1)
activeState.failSettings=false;activeState.now=1064;activeRetry.timer.callback()
assert(activeRetry.pendingHistoryWrite and #activeState.stored[historyKey]==1)
activeState.now=1065;activeRetry.timer.callback()
assert(not activeRetry.pendingHistoryWrite and #activeState.stored[historyKey]==0 and not activeRetry.expiryTimer and activeState.active==1)
activeRetry.stop()


for _,mode in ipairs({'throw','return-false','persist-false'}) do
    local recorder,recordState=fixture(config(true))
    local timer=recorder.timer
    local persist,attempts=recorder.persist,0
    recorder.persist=function()
        attempts=attempts+1
        if recordState.failPersist then return false,'Injected history write failure' end
        return persist()
    end
    local function fail(on)
        recordState.failPersist=on and mode=='persist-false'
        recordState.failSettings=on and mode~='persist-false' and (mode=='return-false' and 'return-false' or true) or false
    end
    local function capture(text)
        recordState.count=recordState.count+1;recordState.text=text
        assert(pcall(timer.callback),'Storage failures must not escape a repeating timer')
        assert(not timer.stopped and recorder.timer==timer and recordState.active==1 and not recorder.expiryTimer)
    end
    fail(true);capture('first pending record')
    assert(recorder.pendingHistoryWrite and attempts==1 and recordState.alerts==1)
    assert(recorder.entries[1].text=='first pending record' and #recordState.stored[historyKey]==1)
    for tick=1001,1004 do recordState.now=tick;capture('pending record '..tick) end
    assert(attempts==1 and recordState.alerts==1,'New captures must neither bypass retry spacing nor repeat the alert')
    recordState.now=1005;timer.callback()
    assert(attempts==2 and recordState.alerts==1 and not timer.stopped)
    fail(false);recordState.now=1009;timer.callback()
    assert(recorder.pendingHistoryWrite and attempts==2)
    recordState.now=1010;timer.callback()
    assert(attempts==3 and not recorder.pendingHistoryWrite and recordState.stored[historyKey][1].text=='pending record 1004')
    local priorWrites=recordState.writes
    capture('last durable record')
    assert(attempts==4 and recordState.writes==priorWrites+1,'A normal captured record should require one synchronous index write')
    assert(recordState.stored[historyKey][1].text=='last durable record')
    recorder.stop();assert(recordState.active==0 and recordState.stored[historyKey][1].text=='last durable record')
    recorder.start();timer=recorder.timer
    assert(recorder.entries[1].text=='last durable record' and recordState.active==1)
    fail(true);capture('a later failure')
    assert(recordState.alerts==2,'A later failure after recovery may notify once again')

    local ran,ok,message=pcall(recorder.save,clone(recorder.config))
    assert(not ran or ok==false and type(message)=='string','A direct settings save must not silently succeed')
    recorder.stop()
end


local previous,repairState=fixture(expiring)
previous.stop()
repairState.stored[historyKey]={{id=1,kind='image',time=1000,path='/isolated-fixture/clipboard-history/clip_1000000_1.png'}}
repairState.failSettings=true;repairState.now=1100
package.loaded['modules.clipboard']=nil
local repaired=require('modules.clipboard');repaired.start()
assert(#repaired.entries==0 and repaired.pendingHistoryWrite and repairState.active==1 and repaired.expiryTimer.delay==5)
repairState.failSettings=false;repairState.now=1105;repaired.expiryTimer.callback()
assert(#repairState.stored[historyKey]==0 and not repaired.pendingHistoryWrite and repairState.active==0)
assert(repairState.reads==0 and repairState.counts==0)



for _,mixed in ipairs({false,true}) do
    local previous,unknownState=fixture(expiring)
    previous.stop();unknownState.now=1100
    local imagePath='/isolated-fixture/clipboard-history/clip_1100000_2.png'
    unknownState.stored[historyKey]={{id=2,kind='image',time=1100,path=imagePath}}
    if mixed then table.insert(unknownState.stored[historyKey],{id=1,kind='image',time=1000,path='/isolated-fixture/clipboard-history/clip_1000000_1.png'}) end
    local image={size=function() return {w=20,h=10} end,encodeAsURLString=function() return 'fixture' end}
    image.setSize=function(self) return self end
    hs.fs.symlinkAttributes=function(path)
        if path==imagePath then return {mode='file',size=20} end
        if path=='/isolated-fixture/clipboard-history' then return {mode='directory'} end
    end
    hs.image={imageFromPath=function() return unknownState.readable and image or nil end}
    hs.hash={SHA256=function(value) return value end}
    package.loaded['modules.clipboard']=nil
    local unknown=require('modules.clipboard');local priorWrites=unknownState.writes
    unknown.start()
    assert(#unknown.entries==0 and not unknown.pendingHistoryWrite and unknownState.active==0)
    assert(unknownState.writes==priorWrites and #unknownState.stored[historyKey]==(mixed and 2 or 1),'Unresolved images must preserve the original index')
    unknownState.readable=true;unknown.load()
    assert(#unknown.entries==1 and unknown.entries[1].path==imagePath,'A temporarily unreadable image must remain recoverable on reload')
    assert(#unknownState.stored[historyKey]==1 and unknownState.stored[historyKey][1].path==imagePath)
    assert(unknownState.reads==0 and unknownState.counts==0)
    unknown.stop()
end
print('Single recording switch: legacy stop migration, write failure safety, history retention, durable off, no duplicate timers, no reads while off, exclusions and permission failure passed')
print('Expiry persistence retries: throws and false results, last entry, bounded coalescing, successful recovery, shutdown and enabled polling passed')
print('Capture persistence retries: native stop-on-error simulation, continued recording, one alert per failure, bounded retries, one normal write and durable shutdown passed')
print('Cache reload: confirmed expired metadata repair, unresolved image index preservation and recovery passed')
