local Mortis=require "Mortis/init"

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.DenState=ProjectNightfall.DenState or {}
local Dens=ProjectNightfall.DenState
local KEY="ProjectNightfall.AlphaTerritories"
local fallback={schemaVersion=1,territories={}}

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end

local function authoritative(entity)
    return Mortis.Authority and Mortis.Authority.canWriteCanonicalState(entity)==true
end

local function root()
    local value=fallback
    if rawget(_G,"ModData") and type(ModData.getOrCreate)=="function" then
        local ok,result=pcall(ModData.getOrCreate,KEY)
        if ok and type(result)=="table" then value=result end
    end
    value.schemaVersion=1
    value.territories=type(value.territories)=="table" and value.territories or {}
    return value
end

local function transmit()
    if rawget(_G,"ModData") and type(ModData.transmit)=="function" then pcall(ModData.transmit,KEY) end
end

local function point(candidate)
    if type(candidate)~="table" then return nil end
    local x,y,z=finite(candidate.x),finite(candidate.y),finite(candidate.z)
    if not x or not y or not z then return nil end
    return {x=x,y=y,z=z,kind=type(candidate.kind)=="string" and candidate.kind:sub(1,32) or "underground",
        buildingId=type(candidate.buildingId)=="string" and candidate.buildingId:sub(1,128) or nil}
end

function Dens.isUndergroundCandidate(candidate)
    local location=point(candidate)
    if not location then return false end
    -- Negative-Z is the verified engine representation available to Lua for
    -- generated basements. A future registered provider may explicitly mark a
    -- verified bunker/underground structure without weakening this fallback.
    return location.z<0 or candidate.underground==true
end

function Dens.claim(alpha,linkedSmartCount,candidate,options)
    if not authoritative(alpha) then return nil,"server authority required" end
    local alphaId=Mortis.Identity.getStableId(alpha) or Mortis.Identity.ensureStableId(alpha)
    if type(alphaId)~="string" then return nil,"Alpha stable identity unavailable" end
    if math.floor(tonumber(linkedSmartCount) or 0)<3 then return nil,"three linked Smart Ferals required" end
    if not Dens.isUndergroundCandidate(candidate) then return nil,"Alpha Den must be underground" end
    if candidate.safe~=true then return nil,"Alpha Den candidate has not passed current shelter validation" end
    local location=point(candidate);options=type(options)=="table" and options or {}
    local data=root()
    local territory=data.territories[alphaId] or {alphaId=alphaId,smartDens={}}
    if territory.migration and territory.migration.status=="active" then
        territory.migration.status="completed"
        territory.migration.completedWorldAgeHours=finite(options.worldAgeHours)
        territory.lastMigration=territory.migration
        territory.migration=nil
    end
    territory.status="claimed";territory.center={x=location.x,y=location.y,z=location.z}
    territory.alphaState="established";territory.emergencyShelter=nil;territory.knownMigrationDestination=nil
    territory.radius=math.max(8,math.min(300,finite(options.radius) or 60))
    territory.alphaDen={status="active",location=location,lastValidatedWorldAgeHours=finite(options.worldAgeHours)}
    territory.smartDens=type(territory.smartDens)=="table" and territory.smartDens or {}
    data.territories[alphaId]=territory;transmit()
    return territory
end

function Dens.getTerritory(alphaOrId)
    local id=type(alphaOrId)=="string" and alphaOrId or (alphaOrId and Mortis.Identity.getStableId(alphaOrId))
    return id and root().territories[id] or nil
end

function Dens.listTerritories(limit)
    local result={}
    limit=math.max(1,math.floor(tonumber(limit) or 64))
    for _,territory in pairs(root().territories) do
        result[#result+1]=territory
        if #result>=limit then break end
    end
    table.sort(result,function(a,b)return tostring(a.alphaId)<tostring(b.alphaId)end)
    return result
end

function Dens.establishSmartDen(alpha,smart,candidate,options)
    if not authoritative(smart) then return nil,"server authority required" end
    local alphaId=Mortis.Identity.getStableId(alpha);local smartId=Mortis.Identity.getStableId(smart) or Mortis.Identity.ensureStableId(smart)
    local territory=alphaId and Dens.getTerritory(alphaId) or nil
    if not territory or territory.status~="claimed" then return nil,"linked Alpha has no claimed territory" end
    local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
    if not relationship or relationship.superiorId~=alphaId then return nil,"Smart Feral is not linked to this Alpha" end
    local location=point(candidate)
    if not location or candidate.safe~=true then return nil,"Smart Feral Den candidate is not currently safe" end
    local center=territory.center
    local dx,dy=location.x-(center and center.x or location.x),location.y-(center and center.y or location.y)
    if dx*dx+dy*dy>(tonumber(territory.radius) or 60)^2 then
        return nil,"Smart Feral Den candidate lies outside claimed territory"
    end
    options=type(options)=="table" and options or {}
    territory.smartDens[smartId]={status="active",smartId=smartId,location=location,
        role=options.role=="alpha_guard" and "alpha_guard" or "territory",
        lastValidatedWorldAgeHours=finite(options.worldAgeHours)}
    transmit();return territory.smartDens[smartId]
end

function Dens.hasActiveSmartDenAt(territory,x,y,z)
    if type(territory)~="table" then return false end
    for _,den in pairs(territory.smartDens or {}) do
        local location=den.location
        if den.status=="active" and location and location.x==x and location.y==y and location.z==z then return true end
    end
    return false
end

function Dens.disband(alphaOrId,smartId,reason,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId)
    if not territory then return false,"territory unavailable" end
    local den=smartId and territory.smartDens[smartId] or territory.alphaDen
    if not den then return false,"den unavailable" end
    den.status="disbanded";den.disbandReason=tostring(reason or "unsafe"):sub(1,128)
    den.disbandedWorldAgeHours=finite(worldAgeHours);transmit();return true
end

function Dens.disbandTerritory(alphaOrId,reason,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId)
    if not territory then return false,"territory unavailable" end
    local message=tostring(reason or "Alpha Den unsafe"):sub(1,128)
    territory.status="disbanded"
    territory.disbandReason=message
    territory.disbandedWorldAgeHours=finite(worldAgeHours)
    if territory.alphaDen then
        territory.alphaDen.status="disbanded"
        territory.alphaDen.disbandReason=message
    end
    for _,den in pairs(territory.smartDens or {}) do
        if den.status=="active" then den.status="disbanded";den.disbandReason=message end
    end
    transmit();return true
end

-- Artificial-UV compromise displaces the Alpha without abandoning territory.
-- The original canonical den remains recorded but unusable until a credible
-- later observation explicitly restores it.
function Dens.emergencyDisplace(alphaOrId,candidate,reason,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId);local location=point(candidate)
    if not territory or territory.status~="claimed" then return nil,"claimed territory unavailable" end
    if not location or candidate.safe~=true then return nil,"emergency shelter is not currently suitable" end
    if territory.alphaDen then
        territory.alphaDen.status="uv-compromised"
        territory.alphaDen.compromisedReason=tostring(reason or "active artificial UV"):sub(1,128)
        territory.alphaDen.compromisedWorldAgeHours=finite(worldAgeHours)
    end
    territory.alphaState="emergency-displaced"
    territory.emergencyShelter={status="active",location=location,
        establishedWorldAgeHours=finite(worldAgeHours)}
    transmit();return territory.emergencyShelter
end

function Dens.markEmergencySheltered(alphaOrId,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId)
    local shelter=territory and territory.emergencyShelter
    if not shelter or shelter.status~="active" then return false,"active emergency shelter unavailable" end
    shelter.status="occupied"
    shelter.reachedWorldAgeHours=finite(worldAgeHours)
    territory.alphaState="emergency-sheltered"
    transmit();return true
end

function Dens.addMigrationPressure(alphaOrId,kind,amount,worldAgeHours,maximum)
    local territory=Dens.getTerritory(alphaOrId)
    if not territory or territory.status~="claimed" then return nil,"claimed territory unavailable" end
    kind=type(kind)=="string" and kind:sub(1,48) or "unspecified"
    amount=math.max(0,finite(amount)or 0);maximum=math.max(1,finite(maximum)or 100)
    local pressure=type(territory.migrationPressure)=="table" and territory.migrationPressure or {value=0,evidence={}}
    pressure.evidence=type(pressure.evidence)=="table" and pressure.evidence or {}
    pressure.value=math.min(maximum,math.max(0,(finite(pressure.value)or 0)+amount))
    pressure.evidence[kind]=math.min(maximum,(finite(pressure.evidence[kind])or 0)+amount)
    pressure.updatedWorldAgeHours=finite(worldAgeHours)
    territory.migrationPressure=pressure;transmit();return pressure
end

function Dens.rememberMigrationDestination(alphaOrId,candidate,source,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId);local location=point(candidate)
    if not territory or territory.status~="claimed" then return nil,"claimed territory unavailable" end
    if not location or candidate.safe~=true then return nil,"migration destination unavailable" end
    territory.knownMigrationDestination={location=location,source=tostring(source or"local-observation"):sub(1,48),
        observedWorldAgeHours=finite(worldAgeHours)}
    transmit();return territory.knownMigrationDestination
end

function Dens.beginMigration(alphaOrId,destination,season,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId);local target=point(destination)
    if not territory or territory.status~="claimed" then return nil,"claimed territory unavailable" end
    if not target then return nil,"known physical destination required" end
    local origin=territory.center and {x=territory.center.x,y=territory.center.y,z=territory.center.z} or nil
    territory.status="abandoned"
    territory.alphaState="migrating"
    territory.emergencyShelter=nil
    territory.migration={status="active",origin=origin,destination=target,season=season,
        startedWorldAgeHours=finite(worldAgeHours)}
    if territory.alphaDen then territory.alphaDen.status="disbanded";territory.alphaDen.disbandReason="normal migration" end
    for _,den in pairs(territory.smartDens or {}) do
        if den.status=="active" then den.status="disbanded";den.disbandReason="normal migration" end
    end
    transmit();return territory.migration
end

function Dens.setMigrationTemporaryShelter(alphaOrId,memberId,candidate,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId);local location=point(candidate)
    local migration=territory and territory.migration
    if not migration or migration.status~="active" then return nil,"active migration unavailable" end
    if not location or candidate.safe~=true then return nil,"temporary shelter unavailable" end
    migration.temporaryShelters=type(migration.temporaryShelters)=="table" and migration.temporaryShelters or{}
    local key=type(memberId)=="string" and memberId or"alpha"
    migration.temporaryShelters[key]={status="active",location=location,establishedWorldAgeHours=finite(worldAgeHours)}
    territory.alphaState="temporary-day-shelter"
    transmit();return migration.temporaryShelters[key]
end

function Dens.clearMigrationTemporaryShelter(alphaOrId,memberId,worldAgeHours)
    local territory=Dens.getTerritory(alphaOrId);local migration=territory and territory.migration
    if not migration or type(migration.temporaryShelters)~="table" then return false end
    local key=type(memberId)=="string" and memberId or"alpha"
    local shelter=migration.temporaryShelters[key];if not shelter then return false end
    shelter.status="departed";shelter.departedWorldAgeHours=finite(worldAgeHours)
    if key=="alpha" then territory.alphaState="migrating" end
    transmit();return true
end

function Dens.resetForTests() fallback={schemaVersion=1,territories={}} end
Dens.KEY=KEY
return Dens
