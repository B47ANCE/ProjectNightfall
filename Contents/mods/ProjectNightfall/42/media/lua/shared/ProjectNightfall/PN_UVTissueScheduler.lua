-- Adapter between Nightfall's existing bounded lifecycle queue and the regional
-- UV pipeline. It installs no events and performs no zombie discovery of its own.
local Authority=require "Mortis/Runtime/Authority"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Policy=require "ProjectNightfall/PN_UVTissuePolicy"
local Pipeline=require "ProjectNightfall/PN_UVTissuePipeline"
local Scheduler={}
ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.UVTissueScheduler=Scheduler
local policyCache=setmetatable({},{__mode="k"})

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or math.abs(value)==math.huge then return nil end
    return value
end

function Scheduler.process(entity,emitters,elapsedMinutes,toMinute,configuration,context)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if type(configuration)~="table" or configuration.enabled~=true then
        return true,{unchanged=true,reason="regional UV tissue disabled"}
    end
    local elapsed,finish=finite(elapsedMinutes),finite(toMinute)
    if not elapsed or elapsed<0 or not finish then return false,"finite UV tissue interval required" end
    if elapsed==0 then return true,{unchanged=true,reason="zero elapsed interval"} end
    local maximum=finite(configuration.maximumElapsedMinutes)
    if not maximum or maximum<=0 then return false,"positive UV tissue elapsed cap required" end
    elapsed=math.min(elapsed,maximum)
    local anatomy,err=Anatomy.get(entity)
    if not anatomy then return false,err end
    local policySource=configuration.policy
    if type(policySource)~="table" then return false,"UV tissue policy required" end
    local revision=finite(configuration.policyRevision)
    if not revision or revision<0 or revision%1~=0 then return false,"nonnegative UV tissue policy revision required" end
    local speciesKey=tostring(anatomy.speciesId or "").."@"..tostring(revision)
    local bySpecies=policyCache[policySource]
    if not bySpecies then bySpecies={};policyCache[policySource]=bySpecies end
    local policy=bySpecies[speciesKey]
    if not policy then
        policy,err=Policy.compile(anatomy,policySource)
        if not policy then return false,err end
        bySpecies[speciesKey]=policy
    end
    context=type(context)=="table" and context or {}
    return Pipeline.sampleAndProcess(entity,emitters or {},policy,finish-elapsed,finish,context)
end

function Scheduler.clearPolicyCache(policySource)
    if policySource~=nil then policyCache[policySource]=nil else policyCache=setmetatable({},{__mode="k"}) end
    return true
end

return Scheduler
