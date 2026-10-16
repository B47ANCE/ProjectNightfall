-- Nightfall biological remains policy. No corpse replacement, inventory
-- mutation, fire simulation, or native skeleton conversion occurs here.
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
local Authority=require "Mortis/Runtime/Authority"
local Util=require "Mortis/Core/Util"
local Corpse=require "Mortis/Runtime/Adapters/CorpseAdapter"
local Remains={KEY="PN_UVRemains",MAX_REGIONS=32}
local function tissueEvidence(part)
    local capacity,remaining=part.tissueCapacity,part.remainingTissue
    if type(capacity)=="number" and capacity==capacity and capacity>0 and capacity<math.huge
        and type(remaining)=="number" and remaining==remaining and remaining>=0 and remaining<=capacity then
        return {capacity=capacity,remaining=remaining,remainingFraction=remaining/capacity}
    end
    return nil
end

function Remains.prepare(entity,tissue)
    if not Authority.canWriteCanonicalState(entity) then return nil,"non-authority" end
    if type(tissue)~="table" or type(tissue.regions)~="table" then return nil,"UV tissue state required" end
    local anatomy,err=Anatomy.get(entity);if not anatomy then return nil,err end
    local data=Entity.getModData(entity);if not data then return nil,"entity modData unavailable" end
    local previous=data[Remains.KEY]
    if previous~=nil then
        if type(previous)~="table" or previous.schemaVersion~=1
            or (previous.status~="pending" and previous.status~="confirmed") then
            return nil,"unsupported UV remains record"
        end
        -- Repeated callbacks must retain the evidence frozen before death.
        return previous
    end
    local regions,count={},0
    local critical=false
    for id,part in pairs(anatomy.regions) do
        count=count+1;if count>Remains.MAX_REGIONS then return nil,"remains anatomy budget exceeded" end
        local _,definition=Anatomy.getRegion(entity,id)
        if definition and definition.critical and part.destroyed then critical=true end
        local score=tissue.regions[id]
        regions[id]={attached=part.attached~=false,destroyed=part.destroyed==true,
            integrity=part.integrity,woundStage=score and score.woundStage or 0,
            naturalScore=score and score.naturalScore or 0,artificialScore=score and score.artificialScore or 0,
            tissue=tissueEvidence(part)}
    end
    if not critical then return nil,"no critical anatomical failure" end
    local record={schemaVersion=1,status="pending",cause="artificial-uv",speciesId=anatomy.speciesId,
        exposureMinute=tissue.lastMinute,regions=regions,visualStatus="native-corpse-preserved"}
    data[Remains.KEY]=record
    return record
end

function Remains.finish(entity,record,committed)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    local data=Entity.getModData(entity)
    if not data or data[Remains.KEY]~=record then return false,"remains transaction mismatch" end
    if record.status=="confirmed" then return true end
    if committed==true then record.status="confirmed" else data[Remains.KEY]=nil end
    return true
end

function Remains.inspect(entity)
    local data=Entity.getModData(entity)
    local record=data and data[Remains.KEY]
    if type(record)~="table" or record.schemaVersion~=1 then return nil,"no UV remains record" end
    return Util.deepCopy(record)
end

-- IsoDeadBody copies modData before its spawn event. Finalize the corpse's
-- own copy, never a retained reference to the removed living entity. This
-- confirms biological provenance only; native loot and presentation stay intact.
local function confirmRecord(entity)
    local data=Entity.getModData(entity)
    local record=data and data[Remains.KEY]
    if record==nil then return true,{unchanged=true} end
    if type(record)~="table" or record.schemaVersion~=1 or record.cause~="artificial-uv"
        or type(record.regions)~="table" or (record.status~="pending" and record.status~="confirmed") then
        return false,"unsupported UV remains record"
    end
    if record.status=="confirmed" then return true,{unchanged=true} end
    record.status="confirmed"
    return true,{confirmed=true}
end

function Remains.finalizeCorpse(corpse)
    if not Authority.canWriteCanonicalState(corpse) then return false,"non-authority" end
    if not Corpse.isCorpse(corpse) then return false,"corpse required" end
    return confirmRecord(corpse)
end

-- Server/SP death notification precedes IsoDeadBody's modData copy. Requiring
-- native death avoids confusing Nightfall's living fake-dead state with death.
function Remains.confirmDeath(entity)
    if not Authority.canWriteCanonicalState(entity) then return false,"non-authority" end
    if Entity.kind(entity)~="infected" or not Entity.isDead(entity) then
        return false,"dead infected required"
    end
    return confirmRecord(entity)
end

local function guardedConfirmation(fn,entity)
    local ok,result,err=pcall(fn,entity)
    if not ok or (result==false and err~="non-authority") then
        pcall(function()
            require("Mortis/Core/Logger").rateLimited("uv-remains-finalize",5,"WARN",
                "UV death/corpse record confirmation deferred: "..tostring(ok and err or result),"Nightfall")
        end)
    end
end

if Events and Events.OnZombieDead then
    Events.OnZombieDead.Add(function(entity) guardedConfirmation(Remains.confirmDeath,entity) end)
end

-- Verified native event is emitted off-server. Authority rejects MP clients;
-- this automatic path therefore covers single-player, not server certification.
if Events and Events.OnDeadBodySpawn then
    Events.OnDeadBodySpawn.Add(function(corpse)
        guardedConfirmation(Remains.finalizeCorpse,corpse)
    end)
end
return Remains
