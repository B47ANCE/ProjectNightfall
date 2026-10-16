require "ProjectNightfall/PN_Config"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.FeralReserve = ProjectNightfall.FeralReserve or {}

local Reserve = ProjectNightfall.FeralReserve
local Config = ProjectNightfall.Config.POC
local LOCOMOTION_REGIONS={"leftLeg","rightLeg","leftFoot","rightFoot"}

local function clamp(value,minimum,maximum)
    return math.max(minimum,math.min(maximum,value))
end

function Reserve.maximum()
    return math.max(0,tonumber(Config.FeralizationThreshold) or 100.0)
end

function Reserve.minimumForSprint()
    return clamp(tonumber(Config.FeralSprintMinimumReserve) or 10.0,0,Reserve.maximum())
end

function Reserve.canSprint(points)
    return (tonumber(points) or 0)>Reserve.minimumForSprint()
end

function Reserve.charge(points,exposureRatePerGameMinute,elapsedGameMinutes)
    local scale=math.max(0,tonumber(Config.FeralReserveChargeScale) or 1.0)
    local gain=math.max(0,tonumber(exposureRatePerGameMinute) or 0)*scale*math.max(0,tonumber(elapsedGameMinutes) or 0)
    return clamp((tonumber(points) or 0)+gain,0,Reserve.maximum())
end

function Reserve.drainSprint(points,elapsedGameMinutes)
    local drain=math.max(0,tonumber(Config.FeralSprintUVPerGameMinute) or 18.0)*math.max(0,tonumber(elapsedGameMinutes) or 0)
    return clamp((tonumber(points) or 0)-drain,0,Reserve.maximum())
end

function Reserve.maximumSprintSeconds()
    local rate=math.max(0,tonumber(Config.FeralSprintUVPerGameMinute) or 18.0)
    if rate<=0 then return math.huge end
    return ((Reserve.maximum()-Reserve.minimumForSprint())/rate)*60.0
end

local function regionCapacity(id)
    local policy=Config.RegionalUVTissuePolicy or {}
    local specific=type(policy.regions)=="table" and policy.regions[id]
    local fallback=type(policy.default)=="table" and policy.default or {}
    return math.max(0,tonumber(type(specific)=="table" and specific.capacity) or tonumber(fallback.capacity) or 100)
end

-- Entity-aware reserve queries are canonical. The scalar helpers above remain
-- temporarily as compatibility aliases for integrations migrating from the
-- pre-anatomical prototype; Nightfall runtime must use these methods.
function Reserve.pool(entity,regionIds)
    local state,err=require("ProjectNightfall/PN_UVTissueState").snapshot(entity)
    if not state then return nil,err end
    local anatomy,anatomyErr=require("Mortis/Runtime/AnatomyRuntime").get(entity)
    if not anatomy then return nil,anatomyErr end
    local result={stored=0,capacity=0,regions={}}
    for _,id in ipairs(regionIds or LOCOMOTION_REGIONS) do
        local value=state.regions[id]
        local region=anatomy.regions[id]
        if value and region and region.attached~=false and region.destroyed~=true then
            local stored=(tonumber(value.naturalScore) or 0)+(tonumber(value.artificialScore) or 0)
            result.regions[id]=stored
            result.stored=result.stored+stored
            result.capacity=result.capacity+regionCapacity(id)
        end
    end
    result.fraction=result.capacity>0 and clamp(result.stored/result.capacity,0,1) or 0
    return result
end

function Reserve.canSprintEntity(entity)
    local capabilities,capabilityErr=require("Mortis/API/AnatomyCapabilities").functionalSnapshot(entity)
    if not capabilities then return false,capabilityErr end
    local baseline=tonumber(capabilities.baseline.locomotion) or 0
    local actual=tonumber(capabilities.total.locomotion) or 0
    local policy=Config.RegionalUVTissuePolicy or {}
    local movement=policy.traumaMovement or {}
    if baseline<=0 or actual/baseline<(tonumber(movement.noSprintBelow) or .75) then
        return false,"insufficient anatomical locomotion"
    end
    local pool,err=Reserve.pool(entity)
    if not pool then return false,err end
    return pool.fraction>(Reserve.minimumForSprint()/math.max(1,Reserve.maximum())),pool
end

function Reserve.drainSprintEntity(entity,elapsedGameMinutes)
    local pool,err=Reserve.pool(entity)
    if not pool then return false,err end
    local minimumFraction=Reserve.minimumForSprint()/math.max(1,Reserve.maximum())
    local spendable=math.max(0,pool.stored-pool.capacity*minimumFraction)
    local rateFraction=math.max(0,tonumber(Config.FeralSprintUVPerGameMinute) or 18)/math.max(1,Reserve.maximum())
    local amount=math.min(spendable,pool.capacity*rateFraction*math.max(0,tonumber(elapsedGameMinutes) or 0))
    if amount<=0 then return true,{unchanged=true,consumed=0,pool=pool} end
    local requests={}
    for id,stored in pairs(pool.regions) do requests[id]=amount*(stored/pool.stored) end
    local ok,result=require("ProjectNightfall/PN_UVTissueState").consume(entity,requests,false)
    if ok then result.poolBefore=pool end
    return ok,result
end

return Reserve
