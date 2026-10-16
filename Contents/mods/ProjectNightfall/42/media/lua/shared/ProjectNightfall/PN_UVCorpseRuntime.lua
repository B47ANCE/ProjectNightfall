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
local tick=0
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
local function marked(corpse)
    local data=Entity.getModData(corpse);local state=data and data[Runtime.KEY]
    return type(state)=="table" and state.schemaVersion==Runtime.SCHEMA and state.infected==true
end
local function markDeath(zombie)
    if not Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
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

local function rebuildScan(emitters,maximum)
    scanQueue,scanIndex={},1
    local seen={}
    for _,emitter in ipairs(emitters) do
        local x,y,z,r=emitterPosition(emitter)
        if x then
            for dx=-r,r do for dy=-r,r do
                if dx*dx+dy*dy<=r*r then
                    local key=(x+dx)..":"..(y+dy)..":"..z
                    if not seen[key] then
                        seen[key]=true;scanQueue[#scanQueue+1]={x+dx,y+dy,z}
                        if #scanQueue>=maximum then return end
                    end
                end
            end end
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
        if cell then
            local ok,value=pcall(function() return cell:getGridSquare(at[1],at[2],at[3]) end)
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

local function process(emitters,now,budget,cell)
    local processed,stageChanges=0,0
    local visited=0
    while processed<budget and #candidateQueue>0 and visited<#candidateQueue do
        if candidateCursor>#candidateQueue then candidateCursor=1 end
        local corpse=candidateQueue[candidateCursor]
        visited=visited+1
        local nearby=ProjectNightfall.ArtificialUV.getCurrentEmitters(corpse)
        if not marked(corpse) or #nearby==0 then
            candidates[corpse]=nil;table.remove(candidateQueue,candidateCursor)
            if candidateCursor>#candidateQueue then candidateCursor=1 end
        else
            local data=Entity.getModData(corpse);local state=data and data[Runtime.KEY]
            local previous=state and tonumber(state.lastProcessMinute) or now
            local elapsed=math.max(0,now-previous)
            if elapsed>0 then
                local ok=Scheduler.process(corpse,nearby,elapsed,now,{enabled=true,
                    maximumElapsedMinutes=Config.RegionalUVTissueMaximumElapsedMinutes,
                    policyRevision=Config.RegionalUVTissuePolicyRevision,policy=corpsePolicy()},{cell=cell})
                if ok and state then
                    state.lastProcessMinute=now
                    local staged,stageReport=RemainsState.update(corpse,Config.UVCorpseDestructionStageThresholds,now)
                    if not staged then return processed,false,stageReport,stageChanges end
                    if type(stageReport)=="table" and stageReport.changed==true then stageChanges=stageChanges+1 end
                end
            end
            processed=processed+1
            candidateCursor=candidateCursor+1
        end
    end
    return processed,true,nil,stageChanges
end

function Runtime.getDiagnostics()
    local copy={};for key,value in pairs(diagnostics) do copy[key]=value end;return copy
end

function Runtime.update(context)
    diagnostics.updates=diagnostics.updates+1
    if not Authority.canWriteCanonicalState() then diagnostics.failures=diagnostics.failures+1;return false,"non-authority" end
    local now=minute();if not now then diagnostics.failures=diagnostics.failures+1;return false,"world time unavailable" end
    local artificial=ProjectNightfall and ProjectNightfall.ArtificialUV
    if not artificial or type(artificial.getCurrentEmitters)~="function" then
        diagnostics.failures=diagnostics.failures+1;return false,"emitter provider unavailable"
    end
    local emitters=artificial.getCurrentEmitters(nil)
    tick=tick+1
    if #emitters==0 then scanQueue={};scanIndex=1;candidateQueue={};candidates=setmetatable({},{__mode="k"});candidateCursor=1
        diagnostics.idleUpdates=diagnostics.idleUpdates+1;diagnostics.lastEmitters=0
        diagnostics.lastSquaresScanned=0;diagnostics.lastCandidatesAdded=0;diagnostics.lastCandidates=0
        diagnostics.lastProcessed=0;diagnostics.lastStageChanges=0;diagnostics.lastScanQueued=0;diagnostics.lastScanRemaining=0
        return true,{processed=0,emitters=0,candidates=0} end
    local squareBudget=math.max(1,math.min(256,tonumber(Config.ArtificialUVCorpseSquareBudgetPerUpdate) or 16))
    local processBudget=math.max(1,math.min(128,tonumber(Config.ArtificialUVCorpseProcessBudgetPerUpdate) or 8))
    local candidateLimit=math.max(16,math.min(2048,tonumber(Config.ArtificialUVCorpseCandidateLimit) or 256))
    local maximumSquares=math.max(64,math.min(16384,tonumber(Config.ArtificialUVCorpseMaximumScanSquares) or 4096))
    if tick%60==1 or scanIndex>#scanQueue then rebuildScan(emitters,maximumSquares) end
    local cell=context and context.cell or (getCell and getCell() or nil)
    local scanned,added=discover(cell,squareBudget,now,candidateLimit)
    local processed,processedOK,processError,stageChanges=process(emitters,now,processBudget,cell)
    if processedOK==false then diagnostics.failures=diagnostics.failures+1;return false,processError end
    local remaining=math.max(0,#scanQueue-scanIndex+1)
    diagnostics.totalSquaresScanned=diagnostics.totalSquaresScanned+scanned
    diagnostics.totalCandidatesAdded=diagnostics.totalCandidatesAdded+added
    diagnostics.totalCorpsesProcessed=diagnostics.totalCorpsesProcessed+processed
    diagnostics.totalStageChanges=diagnostics.totalStageChanges+stageChanges
    diagnostics.lastEmitters=#emitters;diagnostics.lastSquaresScanned=scanned
    diagnostics.lastCandidatesAdded=added;diagnostics.lastCandidates=#candidateQueue
    diagnostics.lastProcessed=processed;diagnostics.lastStageChanges=stageChanges
    diagnostics.lastScanQueued=#scanQueue;diagnostics.lastScanRemaining=remaining
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
