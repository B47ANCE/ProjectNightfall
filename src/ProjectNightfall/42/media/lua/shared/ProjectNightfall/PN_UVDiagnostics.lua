-- Read-only inspection: never advances dose, promotes wounds or changes health.
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Coverage=require "Mortis/Runtime/ClothingCoverage"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Diagnostics={}

local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end

-- Observed interval rate, not a prediction or a particle renderer. Current
-- verified local exposure can suppress it immediately; old records expire.
local function inspectDestruction(entity,stored,report,policy,nowMinute,lifecycle)
    local tissue,err=Anatomy.tissueSnapshot(entity)
    if not tissue then return nil,err end
    if nowMinute==nil then
        local ok,value=pcall(function() return getGameTime():getWorldAgeHours()*60 end)
        if ok then nowMinute=value end
    end
    local maxAge=policy.smokeMaxAgeMinutes
    if maxAge==nil then maxAge=1 end
    if not finite(maxAge) or maxAge<0 then return nil,"invalid smoke diagnostic age" end
    local record=stored.lastDestruction
    local fresh=finite(nowMinute) and type(record)=="table" and finite(record.fromMinute)
        and finite(record.toMinute) and record.toMinute>record.fromMinute
        and record.toMinute==stored.lastMinute and type(record.amounts)=="table"
        and nowMinute>=record.toMinute and nowMinute-record.toMinute<=maxAge
        and not report.pending and report.complete and report.occlusionChecked
    local facts={}
    for id,part in pairs(tissue.regions) do
        if part.attached then
            local r=report.regions[id]
            local rate=0
            if fresh then
                local amount=record.amounts[id]
                if amount==nil then amount=0 end
                if not finite(amount) or amount<0 or amount>part.capacity then return nil,"invalid destruction amount" end
                local config=policy.regions[id]
                local coefficient=config.artificialTissueLossPerDose
                if coefficient==nil then coefficient=0 end
                if not finite(coefficient) or coefficient<0 then return nil,"invalid tissue loss policy" end
                local current=r.incidentArtificial*r.transmission*config.exposureFactor*coefficient
                if not finite(current) then return nil,"destruction rate overflow" end
                rate=math.min(amount/part.capacity/(record.toMinute-record.fromMinute),current)
            end
            facts[id]={attached=true,remainingFraction=part.remainingFraction,weight=part.weight,
                severity=1-part.remainingFraction,activeDestructionRate=rate}
        else facts[id]={attached=false} end
    end
    local smoke,smokeErr=require("ProjectNightfall/PN_UVSmokeModel").evaluate(facts,lifecycle or "living")
    if not smoke then return nil,smokeErr end
    smoke.fresh=fresh==true
    smoke.source="committed artificial UV tissue loss"
    smoke.sampleEndMinute=type(record)=="table" and record.toMinute or nil
    return {tissue=tissue,smoke=smoke,regions=facts}
end

function Diagnostics.inspect(entity,exposure,policy,nowMinute,lifecycle)
    local ok,a,b=pcall(function()
        if type(exposure)~="table" or type(exposure.uv)~="table" or type(policy)~="table" then
            return nil,"exposure and policy required"
        end
        local anatomy,err=Anatomy.get(entity)
        if not anatomy then return nil,err end
        local stored,storageErr=Tissue.snapshot(entity)
        if not stored then return nil,storageErr end
        local clothing,coverageErr=Coverage.snapshot(entity,anatomy.speciesId)
        if not clothing then return nil,coverageErr end
        local protection,policyErr=Coverage.transmission(clothing,policy.resolveTransmission,policy.weights)
        if not protection then return nil,policyErr end
        local uv=exposure.uv
        local report={speciesId=anatomy.speciesId,complete=uv.complete==true,
            occlusionChecked=uv.occlusionChecked==true,pending=stored.pending~=nil,
            lastMinute=stored.lastMinute,regions={},layers=clothing.layers}
        for id,region in pairs(anatomy.regions) do
            local config=policy.regions and policy.regions[id]
            local factor=config and config.exposureFactor
            local transmission=protection.regions[id]
            if type(factor)~="number" or factor~=factor or factor<0 or factor==math.huge
                or transmission==nil then return nil,"missing or invalid regional policy: "..id end
            if region.attached==false then factor=0 end
            local natural,artificial=uv.natural,uv.artificial
            if type(natural)~="number" or type(artificial)~="number" or natural<0 or artificial<0
                or natural~=natural or artificial~=artificial or natural+artificial==math.huge then
                return nil,"invalid exposure values"
            end
            local dose=stored.regions[id]
            local wound=region.wounds and region.wounds["ProjectNightfall.UVBurn"]
            local capacity=config and tonumber(config.capacity)
            if not capacity or capacity<=0 then return nil,"missing regional UV capacity: "..id end
            local storedScore=(dose and dose.naturalScore or 0)+(dose and dose.artificialScore or 0)
            report.regions[id]={incidentNatural=natural,incidentArtificial=artificial,
                transmission=transmission,tissueIrradiance=(natural+artificial)*factor*transmission,
                naturalScore=dose and dose.naturalScore or 0,artificialScore=dose and dose.artificialScore or 0,
                storedScore=storedScore,capacity=capacity,scoreFraction=storedScore/capacity,
                scoreRecorded=dose~=nil,woundStage=wound and wound.stage or 0,
                committedScoreStage=dose and dose.woundStage or 0,attached=region.attached~=false,
                integrity=region.integrity}
        end
        local destructionOK,destruction,destructionErr=pcall(inspectDestruction,entity,stored,report,policy,nowMinute,lifecycle)
        if destructionOK and destruction then report.destruction=destruction
        else report.destructionUnavailable=destructionOK and destructionErr or tostring(destruction) end
        -- Optional diagnostic enrichment must not break the base exposure view.
        local metabolismOK,metabolism=pcall(function()
            local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
            local data=Entity.getModData(entity)
            local lifecycle=data and data.ProjectNightfall and data.ProjectNightfall.state
            local tier=lifecycle and lifecycle.phase=="FERAL" and
                (lifecycle.alphaFeral and "ALPHA_FERAL" or (lifecycle.smartFeral and "SMART_FERAL" or "FERAL")) or nil
            return require("ProjectNightfall/PN_UVMetabolism").inspect(entity,tier)
        end)
        if metabolismOK then report.metabolism=metabolism end
        return report
    end)
    if not ok then return nil,tostring(a) end
    return a,b
end

function Diagnostics.lines(report)
    if type(report)~="table" or type(report.regions)~="table" then return {"UV inspection unavailable"} end
    local ok,lines=pcall(function()
        local output={"Nightfall UV: complete="..tostring(report.complete).." occlusionChecked="..
            tostring(report.occlusionChecked).." pending="..tostring(report.pending)}
        local ids={}
        for id in pairs(report.regions) do ids[#ids+1]=id end
        table.sort(ids)
        for _,id in ipairs(ids) do
            local r=report.regions[id]
            output[#output+1]=string.format("%s: sun=%.3f lamp=%.3f protection=%.1f%% tissue=%.3f score=%.3f/%.3f (%.1f%%; sun=%.3f lamp=%.3f) wound=%d recorded=%s",
                id,r.incidentNatural,r.incidentArtificial,(1-r.transmission)*100,r.tissueIrradiance,
                r.storedScore,r.capacity,r.scoreFraction*100,r.naturalScore,r.artificialScore,r.woundStage,tostring(r.scoreRecorded))
        end
        if report.destruction then
            local d=report.destruction
            output[#output+1]=string.format("Tissue remaining=%.3f/%.3f; destruction=%.1f%% smoke generation=%.6f fresh=%s (diagnostic; no particles)",
                d.tissue.remaining,d.tissue.capacity,d.smoke.destructionFraction*100,
                d.smoke.generationRate,tostring(d.smoke.fresh))
        end
        local m=report.metabolism
        if m and m.initialized then
            output[#output+1]=string.format("Metabolism: tier=%s utilization=%s healingWork/min=%s pending=%s",
                tostring(m.tier or "not eligible"),tostring(m.utilization or "unavailable"),
                tostring(m.healingWorkPerGameMinute or "unavailable"),tostring(m.pending))
            local decision=m.lastDecision
            if decision then
                output[#output+1]="UV decision: "..tostring(decision.action).." reason="..tostring(decision.reason)
                    .." from="..tostring(decision.fromRegion).." to="..tostring(decision.toRegion)
                    .." delivered="..tostring(decision.delivered)
            end
            local repair=m.lastRepair
            if repair then
                output[#output+1]="Last UV repair: region="..tostring(repair.region)
                    .." work="..tostring(repair.work).." UV consumed="..tostring(repair.uvConsumed)
                    .." resultingStage="..tostring(repair.resultingStage)
            end
        end
        return output
    end)
    return ok and lines or {"UV inspection formatting failed"}
end
return Diagnostics
