local Authority=require "Mortis/Runtime/Authority"
local Capabilities=require "Mortis/API/AnatomyCapabilities"
local Overrides=require "Mortis/Runtime/LocomotionOverrides"
local Movement={OWNER="ProjectNightfall.TissueInjury"}
local function unit(v) return type(v)=="number" and v==v and v>=0 and v<=1 end

function Movement.update(entity,policy)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if type(policy)~="table" then return false,"trauma movement policy required" end
    if policy.enabled==false then return Overrides.releaseCeiling(entity,Movement.OWNER) end
    if policy.enabled~=true or not unit(policy.slowBelow) or not unit(policy.noSprintBelow)
        or policy.slowBelow>policy.noSprintBelow then return false,"invalid trauma movement thresholds" end
    local snapshot,err=Capabilities.functionalSnapshot(entity)
    if not snapshot then return false,err end
    local baseline=snapshot.baseline.locomotion
    local actual=snapshot.total.locomotion or 0
    if type(baseline)~="number" or baseline~=baseline or baseline<=0 or baseline==math.huge
        or type(actual)~="number" or actual~=actual or actual<0 or actual==math.huge then
        return false,"valid locomotion baseline required"
    end
    local ratio=math.min(1,actual/baseline)
    local tier
    if ratio<policy.slowBelow then tier="shambler"
    elseif ratio<policy.noSprintBelow then tier="fastShambler" end
    local ok,reason
    if tier then ok,reason=Overrides.setCeiling(entity,Movement.OWNER,tier)
    else ok,reason=Overrides.releaseCeiling(entity,Movement.OWNER) end
    return ok,{ratio=ratio,ceiling=tier,reason=reason}
end
return Movement
