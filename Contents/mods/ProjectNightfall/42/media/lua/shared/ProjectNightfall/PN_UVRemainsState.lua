-- Persistent semantic remains progression. Presentation adapters may consume
-- this state later; this module never replaces corpses, clears loot or invokes fire.
local Authority=require "Mortis/Runtime/Authority"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
local State={KEY="PN_UVRemainsState",SCHEMA=1}
local names={"INTACT","SCORCHED","DESICCATED","CRITICAL","RESIDUAL"}

local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function thresholds(values)
    if type(values)~="table" or #values~=4 then return nil,"four destruction thresholds required" end
    local result,previous={},0
    for i,value in ipairs(values) do
        value=tonumber(value)
        if not finite(value) or value<=previous or value>=1 then return nil,"invalid destruction thresholds" end
        result[i],previous=value,value
    end
    return result
end

local function dedicated()
    return type(Authority.isDedicatedServerRuntime)=="function" and Authority.isDedicatedServerRuntime()==true
end

local function synchronize(corpse,record)
    if not dedicated() or record.syncPending~=true then return true,false end
    local ok,err=Entity.transmitModData(corpse)
    if ok~=true then return false,err or "remains-state transmission failed" end
    -- The transmitted snapshot contains the authority-local retry marker. It is
    -- inert on clients and cleared locally after the successful native call.
    record.syncPending=nil
    return true,true
end

function State.evaluate(tissue,values)
    if type(tissue)~="table" or not finite(tissue.capacity) or tissue.capacity<0
        or not finite(tissue.remaining) or tissue.remaining<0 or tissue.remaining>tissue.capacity then
        return nil,"canonical tissue aggregate required"
    end
    local limits,err=thresholds(values);if not limits then return nil,err end
    local fraction=tissue.capacity>0 and 1-tissue.remaining/tissue.capacity or 1
    local index=1
    for i,limit in ipairs(limits) do if fraction>=limit then index=i+1 end end
    return {stage=names[index],stageIndex=index,destructionFraction=fraction,
        tissueCapacity=tissue.capacity,remainingTissue=tissue.remaining}
end

function State.update(corpse,values,minute)
    if not Authority.canWriteCanonicalState(corpse) then return false,"non-authority" end
    if minute~=nil and (not finite(minute) or minute<0) then return false,"invalid remains minute" end
    local tissue,err=Anatomy.tissueSnapshot(corpse);if not tissue then return false,err end
    local proposed
    proposed,err=State.evaluate(tissue,values);if not proposed then return false,err end
    local data=Entity.getModData(corpse);if not data then return false,"corpse modData unavailable" end
    local previous=data[State.KEY]
    if previous~=nil and (type(previous)~="table" or previous.schemaVersion~=State.SCHEMA
        or type(previous.stageIndex)~="number" or previous.stageIndex<1 or previous.stageIndex>#names) then
        return false,"unsupported remains state"
    end
    if previous and proposed.stageIndex<previous.stageIndex then return false,"remains stage regression" end
    local changed=not previous or proposed.stageIndex>previous.stageIndex
    local record={schemaVersion=State.SCHEMA,stage=proposed.stage,stageIndex=proposed.stageIndex,
        destructionFraction=proposed.destructionFraction,tissueCapacity=proposed.tissueCapacity,
        remainingTissue=proposed.remainingTissue,updatedMinute=minute}
    if previous and not changed then record.enteredMinute=previous.enteredMinute
    else record.enteredMinute=minute end
    if dedicated() and (changed or previous and previous.syncPending==true) then record.syncPending=true end
    data[State.KEY]=record
    local synced,transmitted=synchronize(corpse,record)
    return true,{changed=changed,state=record,synchronized=synced and transmitted or false,
        syncPending=record.syncPending==true,transmissionError=synced and nil or transmitted}
end

function State.synchronize(corpse)
    if not Authority.canWriteCanonicalState(corpse) then return false,"non-authority" end
    local data=Entity.getModData(corpse);local record=data and data[State.KEY]
    if type(record)~="table" or record.schemaVersion~=State.SCHEMA then return false,"no remains state" end
    local ok,sent=synchronize(corpse,record)
    if not ok then return false,sent end
    return ok,{synchronized=sent==true,syncPending=record.syncPending==true}
end

function State.inspect(corpse)
    local data=Entity.getModData(corpse);local record=data and data[State.KEY]
    if type(record)~="table" or record.schemaVersion~=State.SCHEMA then return nil,"no remains state" end
    local copy={};for k,v in pairs(record) do copy[k]=v end;return copy
end
return State
