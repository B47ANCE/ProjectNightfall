-- Development-only exposure measurement commands.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

-- One explicit, session-only SP experiment; no gameplay state writes.
local session
local function minute()
    local ok,value=pcall(function() return getGameTime():getWorldAgeHours()*60 end)
    if ok and type(value)=="number" and value==value and value<math.huge then return value end
end
function PNTestUVDayReport()
    if not session then print("[ProjectNightfall][UVDay] No measurement session"); return nil end
    print(string.format("[ProjectNightfall][UVDay] running=%s sampledMinutes=%.2f skippedMinutes=%.2f samples=%d (session-only, provisional protection)",
        tostring(session.running),session.covered,session.skipped,session.samples))
    local ids={}
    for id in pairs(session.regions) do ids[#ids+1]=id end
    table.sort(ids)
    for _,id in ipairs(ids) do
        local r=session.regions[id]
        print(string.format("[ProjectNightfall][UVDay] %s incidentDose=%.3f tissueDose=%.3f peakTissue=%.3f",id,r.incident,r.tissue,r.peak))
    end
    return session
end
function PNTestUVDayStop()
    if session then session.running=false; session.zombie=nil end
    return PNTestUVDayReport()
end
function PNTestUVDayStart(zombie,windowTransmission)
    if session and session.running then return false,"stop the current measurement first" end
    if (type(isClient)=="function" and isClient()) or (type(isServer)=="function" and isServer()) then return false,"single-player only" end
    local now=minute()
    if not zombie or not now then return false,"zombie and game clock required" end
    local report,err=PNTestUVInspect(zombie,windowTransmission,true)
    if not report or not report.complete or not report.occlusionChecked then return false,err or "initial sample incomplete" end
    session={running=true,zombie=zombie,windowTransmission=windowTransmission,start=now,last=now,
        covered=0,skipped=0,samples=0,regions={}}
    print("[ProjectNightfall][UVDay] Started 1440-game-minute read-only measurement; keep target loaded. PNTestUVDayReport(); PNTestUVDayStop()")
    return true
end
local function tick()
    if not session or not session.running then return end
    local now=minute()
    if not now or now-session.last<1 then return end
    local endMinute=math.min(now,session.start+1440)
    local dt=endMinute-session.last
    local report=PNTestUVInspect(session.zombie,session.windowTransmission,true)
    if dt>5 or not report or not report.complete or not report.occlusionChecked then
        session.skipped=session.skipped+math.max(0,dt)
    else
        session.covered=session.covered+dt; session.samples=session.samples+1
        for id,r in pairs(report.regions) do
            local total=session.regions[id] or {incident=0,tissue=0,peak=0}
            total.incident=total.incident+(r.incidentNatural+r.incidentArtificial)*dt
            total.tissue=total.tissue+r.tissueIrradiance*dt
            total.peak=math.max(total.peak,r.tissueIrradiance)
            session.regions[id]=total
        end
    end
    session.last=endMinute
    if now>=session.start+1440 then PNTestUVDayStop() end
end
if Events and Events.OnTick then
    Events.OnTick.Add(function()
        local ok,err=pcall(tick)
        if not ok and session then
            session.running=false;session.zombie=nil
            print("[ProjectNightfall][UVDay] Stopped on diagnostic error: "..tostring(err))
        end
    end)
end
