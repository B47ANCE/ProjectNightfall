-- Pure sunlight-specific hibernation eligibility over committed regional dose.
-- Artificial dose and global health are intentionally absent from this decision.
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Hibernation={}
ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.SunHibernation=Hibernation

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or math.abs(value)==math.huge then return nil end
    return value
end

function Hibernation.evaluate(entity,policy)
    if type(policy)~="table" or policy.enabled~=true then return true,{eligible=false,reason="disabled"} end
    local threshold=finite(policy.minimumNaturalDose)
    local required=finite(policy.minimumAffectedRegions)
    if not threshold or threshold<=0 then return false,"positive natural-dose threshold required" end
    if not required or required<1 or required%1~=0 then return false,"positive affected-region count required" end
    local state,err=Tissue.snapshot(entity)
    if not state then return false,err end
    if state.pending then return false,"UV tissue transaction pending" end
    local affected,maximum,total=0,0,0
    for _,region in pairs(state.regions or {}) do
        local natural=finite(region.naturalScore)
        if not natural or natural<0 then return false,"invalid committed natural UV dose" end
        total=total+natural
        maximum=math.max(maximum,natural)
        if natural>=threshold then affected=affected+1 end
    end
    return true,{eligible=affected>=required,affectedRegions=affected,requiredRegions=required,
        minimumNaturalDose=threshold,maximumNaturalDose=maximum,totalNaturalDose=total}
end

return Hibernation
