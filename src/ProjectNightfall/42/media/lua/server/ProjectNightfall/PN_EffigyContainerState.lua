-- Shared server mutation boundary for loading and MORTIS feeding. No network
-- request can supply a lock owner. Callers must not yield while holding a lease.
local Frame=require "ProjectNightfall/PN_EffigyContainer"
local State={MAX_REVISION=9007199254740990}
local locks=setmetatable({},{__mode="k"})
local changed={}
function State.authority()
    return type(isClient)=="function" and not isClient() and type(isServer)=="function"
end
function State.enabled()
    local c=ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC
    return State.authority() and c and c.Enabled~=false
end
function State.get(object)
    if not State.authority() then return nil,"non_authority" end
    local frame=Frame.getFrame(object)
    if not frame then return nil,"not_frame" end
    local container=frame:getItemContainer()
    if not Frame.isClosed(container) then return nil,"native_guard_missing" end
    local data=frame:getModData()
    local record=data[Frame.KEY]
    if record==nil then record={schemaVersion=1,revision=0};data[Frame.KEY]=record end
    if type(record)~="table" or record.schemaVersion~=1 or type(record.revision)~="number"
        or record.revision~=record.revision or record.revision%1~=0
        or record.revision<0 or record.revision>State.MAX_REVISION then return nil,"unsupported_record" end
    if record.quarantined~=nil then return nil,"quarantined" end
    -- A retained intent is never automatically retried after reload/restart.
    if record.pendingFeed~=nil then return nil,"feed_recovery_required" end
    return {object=object,frame=frame,container=container,record=record}
end
function State.isBusy(container) return locks[container]~=nil end
function State.acquire(t,owner)
    if not State.enabled() or owner==nil or locks[t.container] then return false end
    locks[t.container]=owner;return true
end
function State.owns(t,owner) return locks[t.container]==owner end
function State.canCheckpoint(t) return type(t.object.flagForHotSave)=="function" end
function State.checkpoint(t)
    if not State.authority() or not State.canCheckpoint(t) then return false end
    -- Native exposed IsoObject method requests a chunk save; this is not an
    -- immediate flush or an atomic save spanning zombie and world inventories.
    return pcall(t.object.flagForHotSave,t.object)
end
function State.release(t,owner)
    if not State.owns(t,owner) then return false end
    locks[t.container]=nil;return true
end
function State.quarantine(t,reason)
    if not State.authority() then return false end
    -- Do not overwrite a newer/future foreign record to install our marker.
    if t.frame:getModData()[Frame.KEY]~=t.record then return false end
    t.record.quarantined=reason;State.checkpoint(t);return true
end
function State.onChanged(fn) changed[#changed+1]=fn end
function State.changed(object)
    for _,fn in ipairs(changed) do pcall(fn,object) end
end
return State
