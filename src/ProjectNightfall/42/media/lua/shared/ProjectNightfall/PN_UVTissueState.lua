-- Authority-owned dose/wound coordinator. Inactive until exposure and source
-- consequence policies are wired. The journal survives partial wound commits.
local Dose=require "ProjectNightfall/PN_RegionalUVDose"
local Authority=require "Mortis/Runtime/Authority"
local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
local Trauma=require "Mortis/Runtime/TraumaRuntime"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Util=require "Mortis/Core/Util"
local Tissue={KEY="PN_UVTissue",MAX_REGIONS=32}
local busy=setmetatable({},{__mode="k"})
local function finite(v)
    return type(v)=="number" and v==v and v>=0 and v<math.huge
end
local function validRegions(regions)
    if type(regions)~="table" then return false end
    local count=0
    for id,r in pairs(regions) do
        count=count+1
        if count>Tissue.MAX_REGIONS or type(id)~="string" or type(r)~="table"
            or not finite(r.naturalScore) or not finite(r.artificialScore)
            or not finite(r.naturalScore+r.artificialScore)
            or not finite(r.woundStage) or r.woundStage%1~=0 then return false end
    end
    return true
end

local function read(entity)
    local data=Entity.getModData(entity)
    if not data then return nil,"entity modData unavailable" end
    local state=data[Tissue.KEY]
    if state==nil then state={schemaVersion=2,regions={}} end
    if type(state)~="table" or state.schemaVersion~=2 or not validRegions(state.regions)
        or (state.lastMinute~=nil and not finite(state.lastMinute)) then
        return nil,"unsupported or malformed tissue state"
    end
    return state,data
end

local function serverRuntime()
    return type(Authority.isDedicatedServerRuntime)=="function" and Authority.isDedicatedServerRuntime()==true
end
local function synchronize(entity,state)
    if not serverRuntime() then return true,false end
    if state.syncPending~=true then return true,false end
    local ok,err=Entity.transmitModData(entity)
    if ok~=true then return false,err or "UV tissue modData transmission failed" end
    -- The transmitted snapshot intentionally contains syncPending=true. It is
    -- an authority-local retry marker; clients never write or act on it.
    state.syncPending=nil
    return true,true
end

local function finish(entity,state,data)
    local pending=state.pending
    if type(pending)~="table" or not validRegions(pending.regions) or type(pending.wounds)~="table"
        or not finite(pending.toMinute) or #pending.wounds>Tissue.MAX_REGIONS then
        return false,"invalid pending UV transaction"
    end
    if pending.exposure~=nil and (type(pending.exposure)~="table"
        or type(pending.exposure.natural)~="boolean" or type(pending.exposure.artificial)~="boolean") then
        return false,"invalid pending exposure attribution"
    end
    local count=0
    for key in pairs(pending.wounds) do
        count=count+1
        if type(key)~="number" or key<1 or key%1~=0 then return false,"invalid wound journal key" end
    end
    if count~=#pending.wounds then return false,"sparse wound journal" end
    if state.lastMinute and pending.toMinute<=state.lastMinute then return false,"stale pending interval" end
    for id in pairs(state.regions) do
        if not pending.regions[id] then return false,"pending transaction drops dose history" end
    end
    for id in pairs(pending.regions) do
        local region,_,canonical=Anatomy.getRegion(entity,id)
        if not region or canonical~=id then return false,"pending region is not canonical anatomy" end
    end
    -- Validate the complete journal before applying any wound, including retries.
    local byRegion={}
    for _,wound in ipairs(pending.wounds) do
        if type(wound)~="table" or type(wound.region)~="string" or not finite(wound.stage)
            or wound.stage<1 or wound.stage%1~=0 or not finite(wound.magnitude)
            or not pending.regions[wound.region] or pending.regions[wound.region].woundStage~=wound.stage then
            return false,"invalid pending wound"
        end
        if byRegion[wound.region] then return false,"duplicate pending wound" end
        byRegion[wound.region]=wound
    end
    for id,proposed in pairs(pending.regions) do
        local prior=state.regions[id] or {naturalScore=0,artificialScore=0,woundStage=0}
        if proposed.naturalScore<prior.naturalScore or proposed.artificialScore<prior.artificialScore
            or proposed.woundStage<prior.woundStage then return false,"pending transaction regresses tissue state" end
        local promoted=proposed.woundStage>prior.woundStage
        if promoted~=(byRegion[id]~=nil) then return false,"dose stage and wound journal disagree" end
    end
    -- Optional loss journal shares the dose interval: never derive a retry from
    -- today's light, clothing, settings, or already-reduced tissue quantity.
    local losses=pending.losses
    if losses==nil then losses={} end
    if type(losses)~="table" then return false,"invalid tissue loss journal" end
    local lossIds={}
    for id,loss in pairs(losses) do
        if type(id)~="string" or not pending.regions[id] or type(loss)~="table"
            or not finite(loss.before) or loss.before<=0 or not finite(loss.amount)
            or loss.amount<=0 or loss.amount>loss.before then return false,"invalid tissue loss entry" end
        lossIds[#lossIds+1]=id
        if #lossIds>Tissue.MAX_REGIONS then return false,"tissue loss budget exceeded" end
    end
    table.sort(lossIds)
    if pending.fromMinute~=nil and (not finite(pending.fromMinute) or pending.fromMinute>pending.toMinute
        or (#lossIds>0 and pending.fromMinute==pending.toMinute)) then return false,"invalid destruction interval" end
    for _,wound in ipairs(pending.wounds) do
        local proposed=pending.regions[wound.region]
        local prior=state.regions[wound.region] or {naturalScore=0,artificialScore=0}
        -- Derive attribution from the frozen journal, not current lighting at
        -- retry time. No duplicated provenance fields can drift out of sync.
        local provenance={uvNaturalScore=proposed.naturalScore,uvArtificialScore=proposed.artificialScore,
            uvNaturalIncrement=proposed.naturalScore-prior.naturalScore,
            uvArtificialIncrement=proposed.artificialScore-prior.artificialScore,
            uvIntervalEndMinute=pending.toMinute}
        local ok,err=Trauma.promote(entity,{region=wound.region,woundId="ProjectNightfall.UVBurn",
            channel="burn",stage=wound.stage,magnitude=wound.magnitude,source="ProjectNightfall.UVTissue",flags=provenance})
        if not ok then return false,err end
    end
    local appliedLosses={}
    for _,id in ipairs(lossIds) do
        local region=Anatomy.getRegion(entity,id)
        -- A severed region belongs to its detached item now; do not burn that
        -- item using an obsolete parent-body exposure sample.
        if region.attached~=false then
            local loss=losses[id]
            local receipt,err=Anatomy.consumeTissue(entity,id,loss.amount,
                {transactionId="PN.UVTissue:"..tostring(pending.toMinute),expectedRemaining=loss.before,
                    mechanism="ultraviolet"})
            if not receipt then return false,err end
            appliedLosses[id]=receipt.amount
        end
    end
    -- Promotions are idempotent. A failed earlier attempt can be retried without
    -- replaying its injury or accruing this interval's dose again.
    local natural,artificial=false,false
    for id,region in pairs(pending.regions) do
        local prior=state.regions[id] or {naturalScore=0,artificialScore=0}
        natural=natural or region.naturalScore>prior.naturalScore
        artificial=artificial or region.artificialScore>prior.artificialScore
    end
    -- New journals freeze actual tissue exposure independently of capacity.
    -- Retain increment-derived attribution only for older pending journals.
    if pending.exposure then
        natural=pending.exposure.natural
        artificial=pending.exposure.artificial
    end
    local committed={schemaVersion=2,regions=Util.deepCopy(pending.regions),lastMinute=pending.toMinute,
        lastExposure={endMinute=pending.toMinute,natural=natural,artificial=artificial}}
    if pending.fromMinute~=nil and pending.toMinute>pending.fromMinute then
        committed.lastDestruction={fromMinute=pending.fromMinute,toMinute=pending.toMinute,amounts=appliedLosses}
    end
    if serverRuntime() then committed.syncPending=true end
    data[Tissue.KEY]=committed
    local synced=select(1,synchronize(entity,committed))
    return true,{completed=true,lastMinute=pending.toMinute,synchronized=synced==true,
        syncPending=committed.syncPending==true}
end

local function locked(entity,fn)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if not entity then return false,"entity required" end
    if busy[entity] then return false,"tissue update already active" end
    busy[entity]=true
    local ok,a,b=pcall(fn)
    busy[entity]=nil
    if not ok then return false,tostring(a) end
    return a,b
end

function Tissue.recover(entity)
    return locked(entity,function()
        local state,data=read(entity)
        if not state then return false,data end
        if not state.pending then
            local ok,synced=synchronize(entity,state)
            return ok,{unchanged=true,synchronized=synced==true,syncPending=state.syncPending==true}
        end
        return finish(entity,state,data)
    end)
end

-- Caller supplies a non-overlapping interval in elapsed game minutes, resolved
-- profiles and aggregated irradiance. woundMagnitudes are cumulative channel
-- trauma targets by stage, independent of dose threshold values.
function Tissue.advance(entity,profiles,incident,fromMinute,toMinute)
    return locked(entity,function()
        local state,data=read(entity)
        if not state then return false,data end
        if state.pending then return finish(entity,state,data) end
        -- A previous network failure never replays trauma. Retry the committed
        -- snapshot before considering the next interval.
        synchronize(entity,state)
        if not finite(fromMinute) or not finite(toMinute) or toMinute<fromMinute then
            return false,"invalid exposure interval"
        end
        if state.lastMinute and toMinute<=state.lastMinute then return true,{unchanged=true} end
        if state.lastMinute and fromMinute<state.lastMinute then return false,"overlapping exposure interval" end
        if type(profiles)~="table" then return false,"region profiles required" end
        local count=0
        for id in pairs(profiles) do
            count=count+1
            if count>Tissue.MAX_REGIONS then return false,"anatomy region budget exceeded" end
            local region,_,canonical=Anatomy.getRegion(entity,id)
            if not region or canonical~=id then return false,"profile region is not canonical anatomy" end
        end
        if count<1 or count>Tissue.MAX_REGIONS then return false,"anatomy region budget exceeded" end
        local proposed,promotions,diagnostics=Dose.propose(state.regions,profiles,incident,toMinute-fromMinute)
        if not proposed then return false,promotions end
        for _,profile in pairs(profiles) do
            local previous=0
            if type(profile.woundMagnitudes)~="table" then return false,"missing wound magnitude policy" end
            for index in ipairs(profile.thresholds) do
                local value=profile.woundMagnitudes[index]
                if not finite(value) or value<previous then return false,"invalid cumulative wound policy" end
                previous=value
            end
        end
        local wounds={}
        for _,promotion in ipairs(promotions) do
            local values=profiles[promotion.region].woundMagnitudes
            local magnitude=type(values)=="table" and values[promotion.toStage]
            if not finite(magnitude) then return false,"missing wound magnitude policy" end
            wounds[#wounds+1]={region=promotion.region,stage=promotion.toStage,magnitude=magnitude}
        end
        local losses={}
        for id,profile in pairs(profiles) do
            local rate=profile.artificialTissueLossPerDose
            if rate==nil then rate=0 end
            if not finite(rate) then return false,"invalid artificial tissue loss rate" end
            local dose=incident.artificial*profile.transmission*profile.exposureFactor*(toMinute-fromMinute)
            if not finite(dose) then return false,"artificial tissue exposure overflow" end
            if rate>0 and dose>0 then
                local region=Anatomy.getRegion(entity,id)
                if region.attached~=false then
                    local capacity,remaining=region.tissueCapacity,region.remainingTissue
                    if not finite(capacity) or capacity<=0 or not finite(remaining) or remaining>capacity then
                        return false,"regional tissue unavailable: "..id
                    end
                    local requested=capacity*rate*dose
                    if not finite(requested) then return false,"artificial tissue loss overflow" end
                    local amount=math.min(remaining,requested)
                    if amount>0 and remaining-amount<remaining then losses[id]={before=remaining,amount=amount} end
                end
            end
        end
        local journal=Util.deepCopy(state)
        local exposure={natural=false,artificial=false}
        if toMinute>fromMinute then
            for _,profile in pairs(profiles) do
                if profile.transmission>0 and profile.exposureFactor>0 then
                    exposure.natural=exposure.natural or incident.natural>0
                    exposure.artificial=exposure.artificial or incident.artificial>0
                end
            end
        end
        journal.pending={regions=proposed,wounds=wounds,fromMinute=fromMinute,toMinute=toMinute,exposure=exposure,losses=losses}
        data[Tissue.KEY]=journal
        local ok,result=finish(entity,journal,data)
        if ok then result.diagnostics=diagnostics end
        return ok,result
    end)
end

-- Spend the same persistent per-region UV score created by exposure. Source
-- attribution is retained only to enforce sunlight's storage ceiling, so a
-- spend drains natural and artificial score proportionally. Wounds are a
-- separate consequence record and are deliberately never healed here.
-- By default the transaction is all-or-nothing. allowPartial is intended for
-- reflexive Feral healing that may exhaust the selected local region.
function Tissue.consume(entity,requests,allowPartial,transactionId)
    return locked(entity,function()
        local state,data=read(entity)
        if not state then return false,data end
        if state.pending then
            local ok,err=finish(entity,state,data)
            if not ok then return false,err end
            state,data=read(entity)
            if not state then return false,data end
        end
        synchronize(entity,state)
        if transactionId~=nil and (type(transactionId)~="string" or transactionId=="" or #transactionId>128) then
            return false,"invalid UV consumption transaction id"
        end
        if transactionId and state.lastConsumptionId==transactionId then
            return true,{unchanged=true,replayed=true,consumed=state.lastConsumptionAmount or 0,regions={}}
        end
        if type(requests)~="table" then return false,"regional UV requests required" end
        local normalized,count,total={},0,0
        for id,amount in pairs(requests) do
            count=count+1
            if count>Tissue.MAX_REGIONS or type(id)~="string" or not finite(amount) then
                return false,"invalid regional UV request"
            end
            local region,_,canonical=Anatomy.getRegion(entity,id)
            if not region or canonical~=id then return false,"request region is not canonical anatomy" end
            if region.attached==false or region.destroyed==true then return false,"region has no usable UV storage" end
            local stored=state.regions[id] or {naturalScore=0,artificialScore=0,woundStage=0}
            local available=stored.naturalScore+stored.artificialScore
            if allowPartial~=true and amount>available then return false,"insufficient regional UV score" end
            normalized[id]=math.min(amount,available)
            total=total+normalized[id]
        end
        if count<1 then return false,"regional UV requests required" end
        if total<=0 then return true,{unchanged=true,consumed=0,regions={}} end
        local committed=Util.deepCopy(state)
        committed.pending=nil
        local consumed={}
        for id,amount in pairs(normalized) do
            if amount>0 then
                local prior=state.regions[id]
                local available=prior.naturalScore+prior.artificialScore
                local natural=amount*(prior.naturalScore/available)
                local artificial=amount-natural
                local nextRegion=committed.regions[id]
                nextRegion.naturalScore=math.max(0,prior.naturalScore-natural)
                nextRegion.artificialScore=math.max(0,prior.artificialScore-artificial)
                consumed[id]={total=amount,natural=natural,artificial=artificial,
                    remaining=nextRegion.naturalScore+nextRegion.artificialScore}
            end
        end
        committed.lastConsumptionId=transactionId
        committed.lastConsumptionAmount=total
        if serverRuntime() then committed.syncPending=true end
        data[Tissue.KEY]=committed
        local synced=select(1,synchronize(entity,committed))
        return true,{consumed=total,regions=consumed,synchronized=synced==true,
            syncPending=committed.syncPending==true}
    end)
end

-- Explicit wound repair synchronization. Score consumption alone never calls
-- this; only a successful healing owner may lower the persistent stage.
function Tissue.repairWoundStage(entity,regionId,resultingStage,transactionId)
    return locked(entity,function()
        local state,data=read(entity)
        if not state then return false,data end
        if state.pending then return false,"exposure transaction pending" end
        if type(transactionId)~="string" or transactionId=="" or #transactionId>128
            or not finite(resultingStage) or resultingStage%1~=0 then return false,"invalid wound repair commit" end
        if state.lastRepairId==transactionId then return true,{unchanged=true,replayed=true} end
        local _,_,canonical=Anatomy.getRegion(entity,regionId)
        local current=canonical and state.regions[canonical]
        if not current then return false,"regional UV state unavailable" end
        if resultingStage>current.woundStage then return false,"repair cannot promote wound stage" end
        local committed=Util.deepCopy(state)
        committed.regions[canonical].woundStage=resultingStage
        committed.lastRepairId=transactionId
        if serverRuntime() then committed.syncPending=true end
        data[Tissue.KEY]=committed
        local synced=select(1,synchronize(entity,committed))
        return true,{region=canonical,fromStage=current.woundStage,toStage=resultingStage,
            synchronized=synced==true,syncPending=committed.syncPending==true}
    end)
end

-- Move stored score between two anatomical regions. `amount` is removed from
-- the source and efficiency determines delivery; lost score represents the
-- biological cost of transfer. This does not change either wound.
function Tissue.transfer(entity,fromRegion,toRegion,amount,efficiency,capacities,transactionId)
    return locked(entity,function()
        local state,data=read(entity)
        if not state then return false,data end
        if state.pending then return false,"exposure transaction pending" end
        if type(transactionId)~="string" or transactionId=="" or #transactionId>128
            or not finite(amount) or not finite(efficiency) or efficiency<=0 or efficiency>1
            or type(capacities)~="table" then return false,"invalid UV transfer" end
        if state.lastTransferId==transactionId then
            return true,{unchanged=true,replayed=true,removed=state.lastTransferRemoved or 0,
                delivered=state.lastTransferDelivered or 0}
        end
        local fromAnatomy,_,fromId=Anatomy.getRegion(entity,fromRegion)
        local toAnatomy,_,toId=Anatomy.getRegion(entity,toRegion)
        if not fromId or not toId or fromId==toId then return false,"invalid UV transfer regions" end
        if not fromAnatomy or not toAnatomy or fromAnatomy.attached==false or toAnatomy.attached==false
            or fromAnatomy.destroyed==true or toAnatomy.destroyed==true then
            return false,"transfer requires surviving attached anatomy"
        end
        local source,target=state.regions[fromId],state.regions[toId]
        local targetCapacity=tonumber(capacities[toId])
        if not source or not target or not finite(targetCapacity) or targetCapacity<=0 then
            return false,"regional UV transfer state unavailable"
        end
        local sourceTotal=source.naturalScore+source.artificialScore
        local targetTotal=target.naturalScore+target.artificialScore
        if targetTotal>targetCapacity+0.000001 then return false,"target UV score exceeds capacity" end
        local removed=math.min(amount,sourceTotal,math.max(0,targetCapacity-targetTotal)/efficiency)
        if removed<=0 then return true,{unchanged=true,removed=0,delivered=0} end
        local naturalRemoved=removed*(source.naturalScore/sourceTotal)
        local artificialRemoved=removed-naturalRemoved
        local committed=Util.deepCopy(state)
        local from,to=committed.regions[fromId],committed.regions[toId]
        from.naturalScore=math.max(0,source.naturalScore-naturalRemoved)
        from.artificialScore=math.max(0,source.artificialScore-artificialRemoved)
        to.naturalScore=target.naturalScore+naturalRemoved*efficiency
        to.artificialScore=target.artificialScore+artificialRemoved*efficiency
        committed.lastTransferId=transactionId
        committed.lastTransferRemoved=removed
        committed.lastTransferDelivered=removed*efficiency
        if serverRuntime() then committed.syncPending=true end
        data[Tissue.KEY]=committed
        local synced=select(1,synchronize(entity,committed))
        return true,{fromRegion=fromId,toRegion=toId,removed=removed,delivered=removed*efficiency,
            lost=removed*(1-efficiency),synchronized=synced==true,syncPending=committed.syncPending==true}
    end)
end

function Tissue.snapshot(entity)
    local state,err=read(entity)
    if not state then return nil,err end
    return Util.deepCopy(state)
end
return Tissue
