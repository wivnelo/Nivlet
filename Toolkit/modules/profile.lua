-- Opt-in timing for performance work. Off unless Nivlet is launched with NIVLET_PROFILE set to an
-- output file (e.g. `open --env NIVLET_PROFILE=/tmp/nivlet-profile.txt -a Nivlet`); then it records
-- startup phases, settings-window and clipboard-menu timings and writes them to that file.
-- When off, every call is a no-op.
local M={path=os.getenv("NIVLET_PROFILE"),lines={}}
M.enabled=type(M.path)=="string" and M.path~=""
if not M.enabled then
    function M.mark() end
    function M.time(_,fn,...) return fn(...) end
    function M.flush() end
    return M
end
local function now() return hs.timer.absoluteTime() end
local start=now()
local last=start
function M.mark(label,extra)
    local t=now()
    table.insert(M.lines,string.format("%9.1f ms  (+%7.1f)  %s%s",(t-start)/1e6,(t-last)/1e6,label,extra and ("  "..tostring(extra)) or ""))
    last=t
end
function M.time(label,fn,...)
    local t=now()
    local results=table.pack(fn(...))
    table.insert(M.lines,string.format("%9s     %7.1f ms   %s","",(now()-t)/1e6,label))
    return table.unpack(results,1,results.n)
end
function M.flush()
    local file=io.open(M.path,"w")
    if file then file:write(table.concat(M.lines,"\n"),"\n");file:close() end
end
M.mark("init.lua start",string.format("epoch %.3f",hs.timer.secondsSinceEpoch()))
return M
