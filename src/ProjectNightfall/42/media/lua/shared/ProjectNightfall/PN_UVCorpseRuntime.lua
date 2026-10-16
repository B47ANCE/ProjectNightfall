-- Artificial-UV corpse processing. Discovery is bounded around active emitters;
-- this module never scans every corpse or every loaded square.
local Authority=require "Mortis/Runtime/Authority"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
local Corpse=require "Mortis/Runtime/Adapters/CorpseAdapter"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Scheduler=require "ProjectNightfall/PN_UVTissueScheduler"
local RemainsState=require "ProjectNightfall/PN_UVRemainsState"
require "ProjectNightfall/PN_Config"
local Config=assert(ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC,
    "Project Nightfall configuration unavailable")
local Runtime={KEY="PN_UVCorpse",SCHEMA=1}
local candidates=setmetatable({},{__mode="k"})
local candidateQueue={}
local candidateCursor=1
local scanQueue,scanIndex={},1
local scanSources,sourceByKey,sourceCursor={},{},1
local pendingStages=setmetatable({},{__mode="k"})
local corpsePolicySource=nil
local diagnostics={updates=0,idleUpdates=0,failures=0,totalSquaresScanned=0,totalCandidatesAdded=0,
    totalCorpsesProcessed=0,totalStageChanges=0,lastEmitters=0,lastSquaresScanned=0,
    lastCandidatesAdded=0,lastCandidates=0,lastProcessed=0,lastStageChanges=0,
    lastScanQueued=0,lastScanRemaining=0}

local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function call(o,m)
    if not o then return nil end
    local ok,v=pcall(function() return o[m](o) end);return ok and v or nil
end
local function minute()
    local ok,v=pcall(function() return getGameTime():getWorldAgeHours()*60 end)
    return ok and finite(v) and v or nil
end
local function enabled()
    return Config.Enabled~=false and Config.EnableRegionalUVTissue~=false
end
local function marked(corpse)
    local data=Entity.getModData(corpse);local state=data and data[Runtime.KEY]
    return type(state)=="table" and state.schemaVersion==Runtime.SCHEMA and state.infected==true
end
local function markDeath(zombie)
    if not Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
    if not enabled() then return true,{unchanged=true,reason="corpse UV disabled"} end
    local anatomy,err=Anatomy.get(zombie);if not anatomy then return false,err end
    local canonicalTissue,tissueQuantityErr=Anatomy.tissueSnapshot(zombie)
    if not canonicalTissue then return false,tissueQuantityErr end
    local tissue,tissueErr=Tissue.snapshot(zombie);if not tissue then return false,tissueErr end
    -- Anatomy.ensure may be cache-only until its first mutation. Persist before
    -- native IsoDeadBody copies modData or a clean corpse loses all regions.
    local flushed,flushError=Anatomy.flush(zombie,false)
    if not flushed then return false,flushError end
    local data=Entity.getModData(zombie);if not data then return false,"entity modData unavailable" end
    local state=data[Runtime.KEY]
    if state~=nil and (type(state)~="table" or state.schemaVersion~=Runtime.SCHEMA) then
        return false,"unsupported corpse marker"
    end
    data[Runtime.KEY]={schemaVersion=Runtime.SCHEMA,infected=true,deathMinute=minute(),speciesId=anatomy.speciesId}
    return true
end
Runtime.markDeath=markDeath

local function emitterPosition(emitter)
    local owner=type(emitter)=="table" and emitter.owner
    local x=tonumber(type(emitter)=="table" and emitter.x) or tonumber(call(owner,"getX"))
    local y=tonumber(type(emitter)=="table" and emitter.y) or tonumber(call(owner,"getY"))
    local z=tonumber(type(emitter)=="table" and emitter.z) or tonumber(call(owner,"getZ"))
    local range=tonumber(type(emitter)=="table" and emitter.range)
    if not finite(x) or not finite(y) or not finite(z) or not finite(range) or range<0 then return nil end
    return math.floor(x),math.floor(y),math.floor(z),math.min(32,math.ceil(range))
end

-- Reconcile descriptor copies by their stable provider owner/item. Queued
-- offsets retain this source object, so movement updates their world position
-- without discarding unvisited work belonging to other emitters.
local function refreshSources(emitters)
    local nextKey=scanSources[sourceCursor] and scanSources[sourceCursor].key
    local previous=sourceByKey
    for _,source in ipairs(scanSources) do source.active=false end
    scanSources,sourceByKey={},{}
    sourceCursor=1
    for _,emitter in ipairs(emitters) do
        local x,y,z,r=emitterPosition(emitter)
        if x then
            local key=emitter.item or emitter.owner or table.concat({x,y,z,r},":")
            if not sourceByKey[key] then
                local source=previous[key] or {key=key,offset=0}
                if source.r~=r then source.offset=0 end
                source.x,source.y,source.z,source.r,source.active=x,y,z,r,true
                scanSources[#scanSources+1]=source;sourceByKey[key]=source
                if key==nextKey then sourceCursor=#scanSources end
            end
        end
    end
end

local function rebuildScan(maximum)
    scanQueue,scanIndex={},1
    local seen,remaining={},{}
    local unfinished=#scanSources
    for _,source in ipairs(scanSources) do remaining[source]=(source.r*2+1)^2 end
    -- The existing queue ceiling also bounds generation work (including
    -- duplicate/out-of-circle offsets). Cursors survive every bounded chunk.
    for _=1,maximum do
        if unfinished==0 then break end
        if sourceCursor>#scanSources then sourceCursor=1 end
        local source=scanSources[sourceCursor]
        sourceCursor=sourceCursor+1
        if remaining[source]>0 then
            local width=source.r*2+1
            local dx=math.floor(source.offset/width)-source.r
            local dy=source.offset%width-source.r
            source.offset=(source.offset+1)%(width*width)
            remaining[source]=remaining[source]-1
            if remaining[source]==0 then unfinished=unfinished-1 end
            if dx*dx+dy*dy<=source.r*source.r then
                local key=(source.x+dx)..":"..(source.y+dy)..":"..source.z
                if not seen[key] then
                    seen[key]=true;scanQueue[#scanQueue+1]={source=source,dx=dx,dy=dy}
                end
            end
        end
    end
end

local function addCandidate(corpse,limit,now)
    if candidates[corpse] then return false end
    if #candidateQueue>=limit then return false end
    local data=Entity.getModData(corpse);local state=data and data[Runtime.KEY]
    -- Exposure before this bounded discovery is unknowable. Re-entering range
    -- after darkness also starts now rather than charging the entire absence.
    if state then state.lastProcessMinute=now end
    candidates[corpse]=true;candidateQueue[#candidateQueue+1]=corpse
    return true
end

local function discover(cell,budget,now,limit)
    local scanned,added=0,0
    for _=1,budget do
        local at=scanQueue[scanIndex];if not at then return scanned,added end
        scanIndex=scanIndex+1
        scanned=scanned+1
        local square=nil
        local source=at.source
        if cell and source.active and at.dx*at.dx+at.dy*at.dy<=source.r*source.r then
            local ok,value=pcall(function() return cell:getGridSquare(source.x+at.dx,source.y+at.dy,source.z) end)
            square=ok and value or nil
        end
        for _,corpse in ipairs(Corpse.onSquare(square)) do
            if marked(corpse) then
                if addCandidate(corpse,limit,now) then added=added+1 end
            end
        end
    end
    return scanned,added
end

local function corpsePolicy()
    if corpsePolicySource then return corpsePolicySource end
    local source=Config.RegionalUVTissuePolicy
    corpsePolicySource={default=source.default,regions=source.regions,protection=source.protection,weights=source.weights,
        artificialDeath=false,traumaMovement=nil}
    return corpsePolicySource
end

local function updateStage(corpse,now)
    local called,ok,result=pcall(RemainsState.update,corpse,Config.UVCorpseDestructionStageThresholds,now)
    if not called or ok~=true then
        pendingStages[corpse]=true
        return false,(called and result or ok) or "corpse remains stage rejected"
    end
    pendingStages[corpse]=nil
    return true,result
end

local function process(now,budget,cell)
    local processed,stageChanges=0,0
    local visited=0
    local visitLimit=math.min(budget,#candidateQueue)
    while #candidateQueue>0 and visited<visitLimit do
        if candidateCursor>#candidateQueue then candidateCursor=1 end
        local corpse=candidateQueue[candidateCursor]
        visited=visited+1
        local nearby=ProjectNightfall.ArtificialUV.getCurrentEmitters(corpse)
        if not marked(corpse) or #nearby==0 then
            candidates[corpse]=nil;table.remove(candidateQueue,candidateCursor)
            if candidateCursor>#candidateQueue then candidateCursor=1 end
        else
            -- Advance even on rejection: one bad corpse must not monopolize
            -- the process budget and starve the rest of the admitted queue.
            candidateCursor=candidateCursor+1
            local data=Entity.getModData(corpse);local state=data and data[Runtime.KEY]
            local previous=state and tonumber(state.lastProcessMinute) or now
            local elapsed=math.max(0,now-previous)
            if pendingStages[corpse] then
                local staged,stageReport=updateStage(corpse,previous)
                if not staged then return processed,false,stageReport,stageChanges end
                if stageReport.changed==true then stageChanges=stageChanges+1 end
            end
            if elapsed>0 then
                local called,ok,result=pcall(Scheduler.process,corpse,nearby,elapsed,now,{enabled=true,
                    maximumElapsedMinutes=Config.RegionalUVTissueMaximumElapsedMinutes,
                    policyRevision=Config.RegionalUVTissuePolicyRevision,policy=corpsePolicy()},{cell=cell})
                if not called or ok~=true then
                    return processed,false,(called and result or ok) or "corpse UV pipeline rejected",stageChanges
                end
                if state then
                    -- A pending tissue journal can finish an older interval.
                    -- Do not advance the corpse clock past that actual commit.
                    local committed=type(result)=="table" and result.lastMinute or now
                    state.lastProcessMinute=finite(committed) and math.max(previous,math.min(now,committed)) or now
                    local staged,stageReport=updateStage(corpse,state.lastProcessMinute)
                    if not staged then return processed,false,stageReport,stageChanges end
                    if type(stageReport)=="table" and stageReport.changed==true then stageChanges=stageChanges+1 end
                end
            end
            processed=processed+1
        end
    end
    return processed,true,nil,stageChanges
end

local function idle(reason)
    scanQueue,scanIndex={},1
    scanSources,sourceByKey,sourceCursor={},{},1
    candidateQueue={};candidates=setmetatable({},{__mode="k"});candidateCursor=1
    pendingStages=setmetatable({},{__mode="k"})
    diagnostics.idleUpdates=diagnostics.idleUpdates+1;diagnostics.lastEmitters=0
    diagnostics.lastSquaresScanned=0;diagnostics.lastCandidatesAdded=0;diagnostics.lastCandidates=0
    diagnostics.lastProcessed=0;diagnostics.lastStageChanges=0;diagnostics.lastScanQueued=0;diagnostics.lastScanRemaining=0
    return true,{processed=0,emitters=0,candidates=0,reason=reason}
end

function Runtime.getDiagnostics()
    local copy={};for key,value in pairs(diagnostics) do copy[key]=value end;return copy
end

function Runtime.update(context)
    diagnostics.updates=diagnostics.updates+1
    if not Authority.canWriteCanonicalState() then diagnostics.failures=diagnostics.failures+1;return false,"non-authority" end
    if not enabled() then return idle("corpse UV disabled") end
    local now=minute();if not now then diagnostics.failures=diagnostics.failures+1;return false,"world time unavailable" end
    local artificial=ProjectNightfall and ProjectNightfall.ArtificialUV
    if not artificial or type(artificial.getCurrentEmitters)~="function" then
        diagnostics.failures=diagnostics.failures+1;return false,"emitter provider unavailable"
    end
    local emitters=artificial.getCurrentEmitters(nil)
    if #emitters==0 then return idle("no emitters") end
    local squareBudget=math.max(1,math.min(256,tonumber(Config.ArtificialUVCorpseSquareBudgetPerUpdate) or 16))
    local processBudget=math.max(1,math.min(128,tonumber(Config.ArtificialUVCorpseProcessBudgetPerUpdate) or 8))
    local candidateLimit=math.max(16,math.min(2048,tonumber(Config.ArtificialUVCorpseCandidateLimit) or 256))
    local maximumSquares=math.max(64,math.min(16384,tonumber(Config.ArtificialUVCorpseMaximumScanSquares) or 4096))
    refreshSources(emitters)
    if scanIndex>#scanQueue then rebuildScan(maximumSquares) end
    local cell=context and context.cell or (getCell and getCell() or nil)
    local scanned,added=discover(cell,squareBudget,now,candidateLimit)
    local processed,processedOK,processError,stageChanges=process(now,processBudget,cell)
    local remaining=math.max(0,#scanQueue-scanIndex+1)
    diagnostics.totalSquaresScanned=diagnostics.totalSquaresScanned+scanned
    diagnostics.totalCandidatesAdded=diagnostics.totalCandidatesAdded+added
    diagnostics.totalCorpsesProcessed=diagnostics.totalCorpsesProcessed+processed
    diagnostics.totalStageChanges=diagnostics.totalStageChanges+stageChanges
    diagnostics.lastEmitters=#emitters;diagnostics.lastSquaresScanned=scanned
    diagnostics.lastCandidatesAdded=added;diagnostics.lastCandidates=#candidateQueue
    diagnostics.lastProcessed=processed;diagnostics.lastStageChanges=stageChanges
    diagnostics.lastScanQueued=#scanQueue;diagnostics.lastScanRemaining=remaining
    if processedOK==false then diagnostics.failures=diagnostics.failures+1;return false,processError end
    return true,{processed=processed,emitters=#emitters,candidates=#candidateQueue,
        scanQueued=#scanQueue,scanRemaining=remaining,squaresScanned=scanned,
        candidatesAdded=added,stageChanges=stageChanges}
end

local function guarded(label,fn,...)
    local ok,a,b=pcall(fn,...)
    if not ok or a==false then pcall(function()
        require("Mortis/Core/Logger").rateLimited("uv-corpse-"..label,5,"WARN",tostring(ok and b or a),"Nightfall")
    end) end
end
if Events and Events.OnZombieDead then Events.OnZombieDead.Add(function(z) guarded("death",markDeath,z) end) end
if Events and Events.OnTick then Events.OnTick.Add(function() guarded("tick",Runtime.update) end) end
ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.UVCorpseRuntime=Runtime
return Runtime
