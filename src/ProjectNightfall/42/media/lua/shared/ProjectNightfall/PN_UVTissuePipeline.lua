-- Shared implementation, server-owned execution. No tick hook is installed until
-- sunlight consequence rules and calibrated protection policies are ready.
local Authority=require "Mortis/Runtime/Authority"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Coverage=require "Mortis/Runtime/ClothingCoverage"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Pipeline={}

local function finish(entity,policy,success,result)
    if success and type(policy)=="table" and policy.artificialDeath==true then
        local ok,applied,detail=pcall(function()
            return require("ProjectNightfall/PN_TissueConsequences").resolve(entity,policy)
        end)
        result.systemic={applied=ok and applied==true,detail=ok and detail or tostring(applied)}
    end
    if success and type(policy)=="table" and policy.traumaMovement~=nil then
        local ok,applied,detail=pcall(function()
            return require("ProjectNightfall/PN_TraumaMovement").update(entity,policy.traumaMovement)
        end)
        -- Dose is already committed. Native movement failure is diagnostic and
        -- retryable on the next successful/duplicate interval, never a dose retry.
        result.movement={applied=ok and applied==true,detail=ok and detail or tostring(applied)}
    end
    return success,result
end

-- exposure is an authoritative, complete sample of both source classes. The
-- collector must require obstruction-checked artificial UV, never a legacy sum.
function Pipeline.process(entity,exposure,policy,fromMinute,toMinute)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    local ok,a,b=pcall(function()
        local stored,err=Tissue.snapshot(entity)
        if not stored then return false,err end
        if stored.pending then return finish(entity,policy,Tissue.recover(entity)) end
        local uv=type(exposure)=="table" and exposure.uv
        if type(uv)~="table" or uv.complete~=true or uv.occlusionChecked~=true then
            return false,"complete obstruction-checked exposure required"
        end
        if type(policy)~="table" or type(policy.regions)~="table"
            or type(policy.resolveTransmission)~="function" then return false,"regional UV policy required" end
        local anatomy,reason=Anatomy.get(entity)
        if not anatomy then return false,reason end
        local clothing,coverageErr=Coverage.snapshot(entity,anatomy.speciesId)
        if not clothing then return false,coverageErr end
        local protection,protectionErr=Coverage.transmission(clothing,policy.resolveTransmission,policy.weights)
        if not protection then return false,protectionErr end
        local profiles={}
        for id,region in pairs(anatomy.regions) do
            local p=policy.regions[id]
            if type(p)~="table" then return false,"missing region policy: "..id end
            local transmission=protection.regions[id]
            if transmission==nil then return false,"missing region coverage: "..id end
            profiles[id]={transmission=region.attached==false and 0 or transmission,
                exposureFactor=p.exposureFactor,capacity=p.capacity,
                naturalCapFraction=p.naturalCapFraction,
                artificialTissueLossPerDose=p.artificialTissueLossPerDose,
                thresholds=p.thresholds,woundMagnitudes=p.woundMagnitudes}
        end
        local success,result=Tissue.advance(entity,profiles,{natural=uv.natural,artificial=uv.artificial},fromMinute,toMinute)
        if success then
            result.clothing=clothing
            result.protection=protection
            result.exposure={natural=tonumber(uv.natural) or 0,artificial=tonumber(uv.artificial) or 0,
                total=tonumber(uv.total) or ((tonumber(uv.natural) or 0)+(tonumber(uv.artificial) or 0)),
                sources=uv.sources}
        end
        return finish(entity,policy,success,result)
    end)
    if not ok then return false,tostring(a) end
    return a,b
end

function Pipeline.sampleAndProcess(entity,emitters,policy,fromMinute,toMinute,context)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    local ok,a,b=pcall(function()
        local UV=require "lightWorks/lightWorks_UV"
        local exposure=UV.getVerifiedExposure(entity,emitters,context)
        return Pipeline.process(entity,exposure,policy,fromMinute,toMinute)
    end)
    if not ok then return false,tostring(a) end
    return a,b
end
return Pipeline
