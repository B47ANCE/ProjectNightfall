local Mortis=require "Mortis/init"
local Integration=require "ProjectNightfall/PN_MortisIntegration"
local Dens=require "ProjectNightfall/PN_DenState"

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.AlphaMigration=ProjectNightfall.AlphaMigration or {}
local Migration=ProjectNightfall.AlphaMigration
local listenerInstalled=false

local function now()
    local game=rawget(_G,"getGameTime")and getGameTime()or nil
    local ok,value=pcall(function()return game and game:getWorldAgeHours()end)
    return ok and tonumber(value)or nil
end

function Migration.seasonForMonth(month)
    month=math.floor(tonumber(month)or-1)
    if month==11 or month<=1 then return "winter" end
    if month<=4 then return "spring" end
    if month<=7 then return "summer" end
    if month<=10 then return "fall" end
    return nil
end

function Migration.currentSeason()
    local game=rawget(_G,"getGameTime")and getGameTime()or nil
    local ok,month=pcall(function()return game and game:getMonth()end)
    return ok and Migration.seasonForMonth(month)or nil
end

function Migration.thresholdForSeason(season,config)
    config=config or(ProjectNightfall.Config and ProjectNightfall.Config.POC)or{}
    if season=="winter" then return nil end
    if season=="spring" then return tonumber(config.AlphaMigrationSpringPressureThreshold)or 55 end
    if season=="summer" then return tonumber(config.AlphaMigrationSummerPressureThreshold)or 60 end
    if season=="fall" then return tonumber(config.AlphaMigrationFallPressureThreshold)or 90 end
    return nil
end

function Migration.evaluate(alphaOrId,season)
    local config=(ProjectNightfall.Config and ProjectNightfall.Config.POC)or{}
    if config.EnableAlphaMigration==false then return false,"disabled" end
    local territory=Dens.getTerritory(alphaOrId)
    if not territory or territory.status~="claimed" then return false,"not-established" end
    season=season or Migration.currentSeason()
    local threshold=Migration.thresholdForSeason(season,config)
    if not threshold then return false,season=="winter" and "winter-lock" or "season-unavailable" end
    local pressure=tonumber(territory.migrationPressure and territory.migrationPressure.value)or 0
    return pressure>=threshold,pressure,threshold,season
end

function Migration.recordPressure(alphaOrId,kind,amount)
    local config=(ProjectNightfall.Config and ProjectNightfall.Config.POC)or{}
    return Dens.addMigrationPressure(alphaOrId,kind,amount,now(),config.AlphaMigrationPressureMaximum)
end

function Migration.rememberDestination(alphaOrId,candidate,source)
    return Dens.rememberMigrationDestination(alphaOrId,candidate,source,now())
end

function Migration.beginKnown(alpha,season)
    local territory=Dens.getTerritory(alpha)
    local known=territory and territory.knownMigrationDestination
    local destination=known and known.location
    if not destination then return false,"known physical destination required" end
    return Migration.begin(alpha,{x=destination.x,y=destination.y,z=destination.z,
        kind=destination.kind,known=true},season)
end

-- This is deliberately destination-gated. Nightfall may only begin physical
-- migration toward a location learned through simulation; it never invents a
-- remote destination or moves an unloaded hierarchy between cells.
function Migration.begin(alpha,destination,season)
    if not alpha or not(Mortis.Authority and Mortis.Authority.canWriteCanonicalState(alpha)==true)then
        return false,"server authority required"
    end
    local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(alpha)
    local objective=relationship and relationship.objective
    if objective and objective.kind=="destroy-rival-alpha" then return false,"rivalry takes priority" end
    local eligible,reason=Migration.evaluate(alpha,season)
    if not eligible then return false,reason end
    local x,y,z=tonumber(destination and destination.x),tonumber(destination and destination.y),tonumber(destination and destination.z)
    if not x or not y or not z or destination.known~=true then return false,"known physical destination required" end
    local migration,err=Dens.beginMigration(alpha,{x=x,y=y,z=z,kind=destination.kind or"known-region"},season or Migration.currentSeason(),now())
    if not migration then return false,err end
    pcall(function()alpha:pathToLocationF(x,y,z)end)
    if Mortis.CommandHierarchy then
        Mortis.CommandHierarchy.setObjective(alpha,"migrate-territory",{x=x,y=y,z=z},now())
        if Mortis.Engine and type(Mortis.Engine.listTracked)=="function" then
            local alphaId=Mortis.Identity.getStableId(alpha)
            for _,entity in ipairs(Mortis.Engine.listTracked())do
                local link=Mortis.CommandHierarchy.get(entity)
                if link and link.superiorId==alphaId and Integration.getTypeId(entity)==Integration.TYPE_SMART_FERAL then
                    Mortis.CommandHierarchy.setObjective(entity,"migrate-with-alpha",{x=x,y=y,z=z},now(),alphaId)
                    pcall(function()entity:pathToLocationF(x,y,z)end)
                end
            end
        end
    end
    return true,migration
end

if Mortis.Events and type(Mortis.Events.on)=="function" and not listenerInstalled then
    Mortis.Events:on("ThreatKilled",function(zombie,typeId)
        if typeId~=Integration.TYPE_SMART_FERAL then return end
        local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(zombie)
        if relationship and relationship.superiorId then
            local config=(ProjectNightfall.Config and ProjectNightfall.Config.POC)or{}
            Migration.recordPressure(relationship.superiorId,"smart-feral-loss",
                tonumber(config.AlphaMigrationSmartLossPressure)or 20)
        end
    end)
    Mortis.Events:on("LivingEntityWeaponTrauma",function(zombie,result)
        local typeId=Integration.getTypeId(zombie);local alphaId
        if typeId==Integration.TYPE_ALPHA_FERAL then
            alphaId=Mortis.Identity.getStableId(zombie)
        elseif typeId==Integration.TYPE_SMART_FERAL then
            local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(zombie)
            alphaId=relationship and relationship.superiorId
        end
        if alphaId then
            local config=(ProjectNightfall.Config and ProjectNightfall.Config.POC)or{}
            local scale=math.max(0,tonumber(config.AlphaMigrationTraumaPressurePerDamage)or 0.25)
            local cap=math.max(0,tonumber(config.AlphaMigrationTraumaPressurePerHitMaximum)or 5)
            local damage=math.max(0,tonumber(result and(result.structuralDamage or result.magnitude))or 0)
            local pressure=math.min(cap,damage*scale)
            if pressure>0 then Migration.recordPressure(alphaId,"successful-weapon-trauma",pressure)end
        end
    end)
    listenerInstalled=true
end

return Migration
