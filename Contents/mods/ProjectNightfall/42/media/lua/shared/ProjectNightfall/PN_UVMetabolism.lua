require "ProjectNightfall/PN_Config"
local Authority=require "Mortis/Runtime/Authority"
local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Trauma=require "Mortis/Runtime/TraumaRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Config=ProjectNightfall.Config.POC
local Metabolism={KEY="PN_UVMetabolism",SCHEMA_VERSION=1,MAX_REGIONS=32}

local function finite(v) return type(v)=="number" and v==v and v>=0 and v<math.huge end
local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function randomUnit()
    if type(ZombRand)=="function" then return ZombRand(0,1000001)/1000000 end
    return .5
end
local function tierName(tier)
    if tier=="ALPHA_FERAL" then return tier end
    if tier=="SMART_FERAL" then return tier end
    return tier=="FERAL" and tier or nil
end
local function rangeValue(group,tier,roll)
    local range=type(group)=="table" and group[tier]
    if type(range)~="table" or not finite(range.minimum) or not finite(range.maximum)
        or range.maximum<range.minimum then return nil end
    return range.minimum+(range.maximum-range.minimum)*roll
end
local function read(entity)
    local data=Entity.getModData(entity)
    if not data then return nil,"entity modData unavailable" end
    local state=data[Metabolism.KEY]
    if state==nil then
        state={schemaVersion=Metabolism.SCHEMA_VERSION,utilizationRoll=randomUnit(),healingRoll=randomUnit(),sequence=0}
        data[Metabolism.KEY]=state
    end
    if type(state)~="table" or state.schemaVersion~=Metabolism.SCHEMA_VERSION
        or not finite(state.utilizationRoll) or state.utilizationRoll>1
        or not finite(state.healingRoll) or state.healingRoll>1
        or not finite(state.sequence) or state.sequence%1~=0 then return nil,"malformed UV metabolism state" end
    return state,data
end

function Metabolism.traits(entity,tier)
    if not Authority.canWriteCanonicalState(entity) then return nil,"non-authority" end
    tier=tierName(tier);if not tier then return nil,"ineligible infected type" end
    local state,err=read(entity);if not state then return nil,err end
    local utilization=rangeValue(Config.UVUtilizationRanges,tier,state.utilizationRoll)
    local throughput=rangeValue(Config.UVHealingWorkPerGameMinuteRanges,tier,state.healingRoll)
    if not utilization or utilization<=0 or not throughput then return nil,"invalid metabolism policy" end
    return {tier=tier,utilization=utilization,healingWorkPerGameMinute=throughput,
        utilizationRoll=state.utilizationRoll,healingRoll=state.healingRoll}
end

-- Inspection never initializes individual rolls, journals, or network writes.
function Metabolism.inspect(entity,tier)
    local data=Entity.getModData(entity)
    if not data then return nil,"entity modData unavailable" end
    local state=data[Metabolism.KEY]
    if state==nil then return {initialized=false,tier=tierName(tier)} end
    if type(state)~="table" or state.schemaVersion~=Metabolism.SCHEMA_VERSION
        or not finite(state.utilizationRoll) or state.utilizationRoll>1
        or not finite(state.healingRoll) or state.healingRoll>1 then return nil,"malformed UV metabolism state" end
    local tier=tierName(tier)
    local result={initialized=true,tier=tier,pending=state.pending~=nil}
    if tier then
        result.utilization=rangeValue(Config.UVUtilizationRanges,tier,state.utilizationRoll)
        result.healingWorkPerGameMinute=rangeValue(Config.UVHealingWorkPerGameMinuteRanges,tier,state.healingRoll)
    end
    local Util=require "Mortis/Core/Util"
    result.lastRepair=type(state.last)=="table" and Util.deepCopy(state.last) or nil
    result.lastDecision=type(state.lastDecision)=="table" and Util.deepCopy(state.lastDecision) or nil
    return result
end

function Metabolism.exposureModifier(currentExposure)
    if not finite(currentExposure) then return nil,"invalid current tissue exposure" end
    local reference=tonumber(Config.UVRegenerationExposureReference) or 1
    if not finite(reference) or reference<=0 then return nil,"invalid exposure reference" end
    local fraction=clamp(currentExposure/reference,0,math.huge)
    local hard=tonumber(Config.UVRegenerationHardBlockFraction) or .6
    if fraction>=hard then return 0,fraction,"local-exposure-lockout" end
    for _,band in ipairs(Config.UVRegenerationExposureBands or {}) do
        local maximum,multiplier=tonumber(band.maximum),tonumber(band.multiplier)
        if maximum and multiplier and fraction<maximum then return math.max(0,multiplier),fraction end
    end
    return 0,fraction,"uncovered-exposure-band"
end

local function resultingStage(remaining,magnitudes)
    if remaining<=0 then return 0 end
    local stage=1
    for index,value in ipairs(magnitudes or {}) do if remaining>=value then stage=index end end
    return stage
end
local function capacitiesFor(tissue)
    local result={}
    local policy=Config.RegionalUVTissuePolicy or {}
    for id in pairs(tissue.regions or {}) do
        local specific=type(policy.regions)=="table" and policy.regions[id]
        result[id]=tonumber(type(specific)=="table" and specific.capacity)
            or tonumber(type(policy.default)=="table" and policy.default.capacity) or 100
    end
    return result
end
local function transferPolicy(tier)
    if tier=="ALPHA_FERAL" then
        return tonumber(Config.UVAlphaTransferEfficiency) or .95,
            tonumber(Config.UVAlphaTransferPerGameMinute) or 4
    end
    if tier=="SMART_FERAL" then
        return tonumber(Config.UVSmartHealingTransferEfficiency) or .85,
            tonumber(Config.UVSmartHealingTransferPerGameMinute) or 2
    end
end
local function sync(entity)
    if type(Authority.isDedicatedServerRuntime)=="function" and Authority.isDedicatedServerRuntime()==true then
        return Entity.transmitModData(entity)
    end
    return true
end
local function finishPending(entity,state,data)
    local p=state.pending
    if type(p)~="table" or type(p.id)~="string" or type(p.region)~="string"
        or not finite(p.uvCost) or not finite(p.work) or not finite(p.resultingStage) then
        return false,"invalid pending UV regeneration"
    end
    local anatomy,anatomyErr=Anatomy.get(entity)
    if not anatomy then return false,anatomyErr end
    local region=type(anatomy.regions)=="table" and anatomy.regions[p.region]
    if type(region)~="table" then return false,"pending healing region unavailable" end
    if region.attached==false or region.destroyed==true then
        -- A detached/destroyed region is a terminal biological target, not a
        -- retryable native-write failure. Do not resurrect it, spend again, or
        -- refund energy that might already have committed before interruption.
        state.pending=nil
        state.lastDecision={action="cancel-healing",reason="region no longer viable",
            region=p.region,transactionId=p.id}
        sync(entity)
        return true,{cancelled=true,reason="region no longer viable",region=p.region,id=p.id}
    end
    local ok,result=Tissue.consume(entity,{[p.region]=p.uvCost},false,p.id..":score")
    if not ok then return false,result end
    ok,result=Trauma.repair(entity,{region=p.region,woundId="ProjectNightfall.UVBurn",channel="burn",
        magnitude=p.work,stage=p.resultingStage,transactionId=p.id..":trauma"})
    if not ok then return false,result end
    ok,result=Tissue.repairWoundStage(entity,p.region,p.resultingStage,p.id..":stage")
    if not ok then return false,result end
    state.pending=nil
    state.last={id=p.id,region=p.region,uvConsumed=p.uvCost,work=p.work,
        resultingStage=p.resultingStage,exposureFraction=p.exposureFraction}
    sync(entity)
    return true,state.last
end

function Metabolism.recover(entity)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    local data=Entity.getModData(entity)
    if not data then return false,"entity modData unavailable" end
    -- A recovery probe must not initialize traits on regular zombies.
    if data[Metabolism.KEY]==nil then return true,{unchanged=true} end
    local state,data=read(entity);if not state then return false,data end
    if not state.pending then return true,{unchanged=true} end
    return finishPending(entity,state,data)
end

-- Each eligible local region receives this interval's healing opportunity.
-- Region count is bounded; cross-region transfers share one interval budget.
function Metabolism.regenerate(entity,tier,diagnostics,elapsedMinutes,intent)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    tier=tierName(tier);if not tier then return true,{unchanged=true,reason="ineligible infected type"} end
    if not finite(elapsedMinutes) then return false,"invalid regeneration interval" end
    local state,data=read(entity);if not state then return false,data end
    if state.pending then return finishPending(entity,state,data) end
    if tier=="ALPHA_FERAL" and type(intent)=="table" and intent.preserveForMovement==true then
        state.lastDecision={action="preserve",reason="tactical movement",tier=tier}
        sync(entity)
        return true,{unchanged=true,reason="Alpha preserving UV for tactical movement"}
    end
    local traits,err=Metabolism.traits(entity,tier);if not traits then return false,err end
    local anatomy,anatomyErr=Anatomy.get(entity);if not anatomy then return false,anatomyErr end
    local tissue,tissueErr=Tissue.snapshot(entity);if not tissue then return false,tissueErr end
    local ids={}
    for id in pairs(anatomy.regions) do
        ids[#ids+1]=id
        if #ids>Metabolism.MAX_REGIONS then return false,"anatomy region budget exceeded" end
    end
    local priorities={}
    if tier=="ALPHA_FERAL" then
        for _,id in ipairs(ids) do
            local region,definition=Anatomy.getRegion(entity,id)
            if not region or type(definition)~="table" then return false,"anatomical priority unavailable" end
            local wound=region.wounds and region.wounds["ProjectNightfall.UVBurn"]
            local stage=type(wound)=="table" and tonumber(wound.stage) or 0
            priorities[id]={critical=definition.critical==true and 1 or 0,stage=finite(stage) and stage or 0}
        end
    end
    table.sort(ids,function(a,b)
        local x,y=priorities[a],priorities[b]
        if x and y then
            if x.critical~=y.critical then return x.critical>y.critical end
            if x.stage~=y.stage then return x.stage>y.stage end
        end
        return a<b
    end)
    local considered=0
    local repairs={}
    local _,transferRate=transferPolicy(tier)
    local transferRemaining=finite(transferRate) and transferRate*elapsedMinutes or 0
    for _,id in ipairs(ids) do
        considered=considered+1;if considered>Metabolism.MAX_REGIONS then return false,"anatomy region budget exceeded" end
        local region=anatomy.regions[id]
        local wound=region.wounds and region.wounds["ProjectNightfall.UVBurn"]
        -- Earlier repairs/transfers may have changed any donor. Never use the
        -- original snapshot again after spending within this update.
        tissue,tissueErr=Tissue.snapshot(entity)
        if not tissue then return false,tissueErr end
        local stored=tissue.regions[id]
        local diagnostic=type(diagnostics)=="table" and diagnostics[id]
        if region.attached~=false and region.destroyed~=true and wound and stored and diagnostic then
            local modifier,fraction,reason=Metabolism.exposureModifier(diagnostic.tissueIrradiance)
            local available=(stored.naturalScore or 0)+(stored.artificialScore or 0)
            if modifier and modifier>0 and (available>0 or tier~="FERAL") then
                local magnitude=tonumber(wound.magnitude)
                if not finite(magnitude) then return false,"invalid wound magnitude" end
                -- Transfer demand is the actual remaining repair, not unused
                -- throughput. Otherwise a tiny wound drains a donor needlessly.
                local desiredWork=math.min(magnitude,traits.healingWorkPerGameMinute*elapsedMinutes*modifier)
                local transfer
                if available*traits.utilization<desiredWork and tier~="FERAL" then
                    local efficiency,rate=transferPolicy(tier)
                    local donor,donorStored
                    for donorId,value in pairs(tissue.regions) do
                        local donorAnatomy=anatomy.regions[donorId]
                        local amount=(value.naturalScore or 0)+(value.artificialScore or 0)
                        if donorId~=id and donorAnatomy and donorAnatomy.attached~=false
                            and donorAnatomy.destroyed~=true and amount>0 and (not donorStored or amount>donorStored) then
                            donor,donorStored=donorId,amount
                        end
                    end
                    if donor and efficiency and efficiency>0 and rate and rate>0 then
                        local requiredDelivery=(desiredWork/traits.utilization)-available
                        local removal=math.min(donorStored,transferRemaining,requiredDelivery/efficiency)
                        if removal>0 then
                            state.sequence=state.sequence+1
                            local transferId="heal-transfer:"..tostring(state.sequence)..":"..donor..":"..id
                            sync(entity)
                            local moved,moveResult=Tissue.transfer(entity,donor,id,removal,efficiency,
                                capacitiesFor(tissue),transferId)
                            if not moved then return false,moveResult end
                            transferRemaining=math.max(0,transferRemaining-(tonumber(moveResult.removed) or removal))
                            transfer=moveResult
                            available=available+(tonumber(moveResult.delivered) or 0)
                        end
                    end
                end
                local work=math.min(desiredWork,available*traits.utilization)
                if work>0 then
                    local cost=work/traits.utilization
                    state.sequence=state.sequence+1
                    local transactionId="regen:"..tostring(state.sequence)..":"..id
                    state.pending={id=transactionId,region=id,uvCost=cost,work=work,
                        resultingStage=resultingStage(wound.magnitude-work,
                            Config.RegionalUVTissuePolicy.default.woundMagnitudes),exposureFraction=fraction}
                    sync(entity)
                    local ok,result=finishPending(entity,state,data)
                    if ok then
                        result.traits=traits;result.exposureModifier=modifier;result.transfer=transfer
                        if tier=="ALPHA_FERAL" and not result.cancelled then
                            state.lastDecision={action="heal",reason="critical region then wound severity",region=id}
                            sync(entity)
                        end
                    end
                    if not ok then return false,result end
                    repairs[#repairs+1]=result
                end
            elseif reason=="local-exposure-lockout" then
                -- Continue: another region may be able to heal this interval.
            end
        end
    end
    if #repairs>0 then
        -- Preserve the first repair's fields for existing callers; the complete
        -- list is separate so the result never becomes self-referential.
        local summary={repairs=repairs,regionsProcessed=#repairs,totalWork=0,totalUVConsumed=0}
        for key,value in pairs(repairs[1]) do summary[key]=value end
        for _,repair in ipairs(repairs) do
            summary.totalWork=summary.totalWork+(repair.work or 0)
            summary.totalUVConsumed=summary.totalUVConsumed+(repair.uvConsumed or 0)
        end
        return true,summary
    end
    return true,{unchanged=true,reason="no eligible local repair",traits=traits}
end

-- Alpha-only proactive storage allocation. One deterministic transfer per
-- biological interval, from the fullest donor into the least-filled protected
-- recipient. Equalization accounts for transfer loss and cannot oscillate by
-- overfilling the recipient above its donor's resulting fractional storage.
function Metabolism.redistribute(entity,tier,diagnostics,elapsedMinutes,intent)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if tier~="ALPHA_FERAL" then return true,{unchanged=true,reason="proactive allocation is Alpha-only"} end
    if not finite(elapsedMinutes) then return false,"invalid allocation interval" end
    if type(intent)~="table" or intent.allowRedistribution~=true then
        return true,{unchanged=true,reason="tactical allocation deferred"}
    end
    local state,data=read(entity);if not state then return false,data end
    if state.pending then return false,"healing transaction pending" end
    local anatomy,err=Anatomy.get(entity);if not anatomy then return false,err end
    local tissue,tissueErr=Tissue.snapshot(entity);if not tissue then return false,tissueErr end
    local capacities=capacitiesFor(tissue)
    local ids={};for id in pairs(tissue.regions) do ids[#ids+1]=id end
    if #ids>Metabolism.MAX_REGIONS then return false,"anatomy region budget exceeded" end
    table.sort(ids)
    local donor,target,highest,lowest=nil,nil,-1,math.huge
    local protectedLimit=tonumber(Config.UVAlphaProtectedTransmissionMaximum) or .25
    for _,id in ipairs(ids) do
        local region=anatomy.regions[id]
        local score=tissue.regions[id]
        local capacity=capacities[id]
        if region and region.attached~=false and region.destroyed~=true and finite(capacity) and capacity>0 then
            local fraction=(score.naturalScore+score.artificialScore)/capacity
            if fraction>highest then donor,highest=id,fraction end
            local d=type(diagnostics)=="table" and diagnostics[id]
            if d and finite(d.transmission) and d.transmission<=protectedLimit
                and finite(d.tissueIrradiance) and fraction<lowest then target,lowest=id,fraction end
        end
    end
    local gap=tonumber(Config.UVAlphaRedistributionMinimumGap) or .20
    if not donor or not target or donor==target or highest-lowest<gap then
        return true,{unchanged=true,reason="no useful protected storage transfer"}
    end
    local efficiency,rate=transferPolicy(tier)
    if not finite(efficiency) or efficiency>1 or not finite(rate) then
        return false,"invalid Alpha transfer policy"
    end
    if efficiency==0 or rate==0 then return true,{unchanged=true,reason="Alpha transfer disabled"} end
    local equalizing=(highest-lowest)/(1/capacities[donor]+efficiency/capacities[target])
    local amount=math.min(equalizing,rate*elapsedMinutes)
    if amount<=0 then return true,{unchanged=true} end
    state.sequence=state.sequence+1
    local transactionId="alpha-storage:"..tostring(state.sequence)
    local ok,result=Tissue.transfer(entity,donor,target,amount,efficiency,capacities,transactionId)
    if not ok then return false,result end
    state.lastDecision={action="redistribute",reason="protected storage",fromRegion=donor,toRegion=target,
        removed=result.removed,delivered=result.delivered}
    sync(entity)
    result.reason="Alpha protected storage optimization"
    return true,result
end

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.UVMetabolism=Metabolism
return Metabolism
