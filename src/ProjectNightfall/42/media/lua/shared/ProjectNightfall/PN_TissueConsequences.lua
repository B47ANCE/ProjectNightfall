local Authority=require "Mortis/Runtime/Authority"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Systemic=require "Mortis/Runtime/SystemicTrauma"
local Consequences={}

function Consequences.resolve(entity,policy)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if type(policy)~="table" or policy.artificialDeath~=true then return true,{unchanged=true} end
    local state,err=Tissue.snapshot(entity)
    if not state then return false,err end
    if state.pending then return false,"wound transaction pending" end
    local exposure=state.lastExposure
    if type(exposure)~="table" or exposure.endMinute~=state.lastMinute or exposure.artificial~=true then
        return true,{unchanged=true,reason="no committed artificial tissue exposure"}
    end
    -- No transformation or hibernation mutation here. Critical anatomical
    -- destruction and native death transition remain MORTIS-owned.
    local Remains=require "ProjectNightfall/PN_UVRemains"
    -- Freeze the regional evidence before native health/death callbacks can
    -- create a corpse. Remains failure must not invent an alternate death path.
    local prepared,record=pcall(Remains.prepare,entity,state)
    local ok,result=Systemic.resolveCriticalFailure(entity,{allowDeath=true})
    if prepared and record then
        pcall(Remains.finish,entity,record,ok and type(result)=="table" and result.healthZero==true)
    end
    return ok,result
end
return Consequences
