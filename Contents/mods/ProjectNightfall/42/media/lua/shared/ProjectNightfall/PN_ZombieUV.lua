require "ProjectNightfall/PN_Config"
local NaturalUVHealth = require "ProjectNightfall/PN_NaturalUVHealth"
require "ProjectNightfall/PN_SolarUV"
require "ProjectNightfall/PN_Shelter"
require "ProjectNightfall/PN_UVAI"
require "ProjectNightfall/PN_Observation"
require "ProjectNightfall/PN_Canopy"
require "ProjectNightfall/PN_CanopyDiagnostic"
require "ProjectNightfall/PN_FlashlightBulbs"
require "ProjectNightfall/PN_ArtificialUV"
require "ProjectNightfall/PN_UVCorpseRuntime"
require "ProjectNightfall/PN_UVTissueScheduler"
require "ProjectNightfall/PN_UVMetabolism"
require "ProjectNightfall/PN_SunHibernation"
require "ProjectNightfall/PN_MortisIntegration"
require "ProjectNightfall/PN_FeralAI"
require "ProjectNightfall/PN_FeralReserve"
require "ProjectNightfall/PN_LifecycleRules"
require "ProjectNightfall/PN_StatePersistence"
require "ProjectNightfall/PN_DependencyDiagnostics"
require "ProjectNightfall/PN_Effigies"
require "ProjectNightfall/PN_NightTransition"
require "ProjectNightfall/PN_AlphaFerals"
require "ProjectNightfall/PN_DenState"
require "ProjectNightfall/PN_DenDefense"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.ZombieUV = ProjectNightfall.ZombieUV or {}

local ZombieUV = ProjectNightfall.ZombieUV
local SolarUV = ProjectNightfall.SolarUV
local Shelter = ProjectNightfall.Shelter
local UVAI = ProjectNightfall.UVAI
local Observation = ProjectNightfall.Observation
local FeralAI = ProjectNightfall.FeralAI
local FeralReserve = ProjectNightfall.FeralReserve
local LifecycleRules = ProjectNightfall.LifecycleRules
local MortisIntegration = ProjectNightfall.MortisIntegration
local StatePersistence = ProjectNightfall.StatePersistence
local Config = ProjectNightfall.Config.POC
local Effigies = ProjectNightfall.Effigies
local NightTransition = ProjectNightfall.NightTransition
local AlphaFerals = ProjectNightfall.AlphaFerals
local UVTissueScheduler = ProjectNightfall.UVTissueScheduler
local SunHibernation = ProjectNightfall.SunHibernation
local UVMetabolism = ProjectNightfall.UVMetabolism

local tracked = setmetatable({}, { __mode = "k" })
local hibernating = setmetatable({}, { __mode = "k" })
local relevantQueue,relevantHead,relevantTail={},1,0
local relevantQueued=setmetatable({},{__mode="k"})
local hibernationCursor=nil

-- Build 42's Kahlua release environment does not expose Lua's global next().
-- Preserve the bounded, incremental weak-table walk without relying on it. If
-- the cursor is collected between frames, restart at the first live entry.
local function nextHibernator(cursor)
    local returnNext=cursor==nil
    local first
    for zombie in pairs(hibernating) do
        first=first or zombie
        if returnNext then return zombie end
        if zombie==cursor then returnNext=true end
    end
    if cursor~=nil and not returnNext then return first end
    return nil
end
local initialScanIndex=0
local initialScanComplete=false
-- Bind the module return directly. During B42's shared-Lua load sequence the
-- global namespace can still be nil at the point immediately following a
-- require, which left every group-update tick indexing a captured nil value.
require "ProjectNightfall/PN_FeralGroups"
-- B42's require() executes shared modules but does not reliably return their
-- Lua value. PN_FeralGroups publishes its canonical table on the namespace.
local FeralGroups = ProjectNightfall.FeralGroups
local applyLockedTransformationVisual
local tick = 0
local detailLogsThisUpdate = 0
local reportedShelterSkipReasons = {}
local stats = {
    created=0, updateEvents=0, processed=0, feralizations=0, rises=0,
    deadWhileDown=0, artificialUVDeaths=0, naturalFloorRestores=0,
    errors=0, shelterPaths=0, staySheltered=0,
    chaseWins=0, normalWins=0, seekWins=0, transformCrawlAllows=0,
    transformCrawlBlocks=0, observeWins=0, interestWins=0,
    observationPaths=0, interestPaths=0, signalsEmitted=0,
    smartPromotions=0, feralDayDormancies=0, smartSunPaths=0,
    smartStalkPaths=0, smartFlankPaths=0, smartHideEntries=0, smartAmbushes=0,
    shelterHoldBegins=0, shelterHoldEnds=0,
    effigyAvoids=0,effigyDestroys=0,effigyHunts=0,
    nightExitPaths=0,
}

local function log(msg)
    if Config.Debug then print("[ProjectNightfall]["..tostring(ProjectNightfall.VERSION).."] " .. tostring(msg)) end
end
local function safe(label, fn, ...)
    local ok,a,b,c = pcall(fn,...)
    if not ok then stats.errors=stats.errors+1; log("ERROR in "..tostring(label)..": "..tostring(a)); return nil end
    return a,b,c
end
local function clamp(v,lo,hi) if v<lo then return lo elseif v>hi then return hi else return v end end
local function countTracked() local n=0; for _ in pairs(tracked) do n=n+1 end; return n end
local function worldAgeHours() local gt=getGameTime and getGameTime() or nil; return gt and gt:getWorldAgeHours() or nil end

local function getNightStrength()
    local cm = getClimateManager and getClimateManager() or nil
    if not cm and ClimateManager and ClimateManager.getInstance then
        cm = ClimateManager.getInstance()
    end
    if not cm then return nil end
    local value=nil
    safe("getNightStrength",function() value=cm:getNightStrength() end)
    return tonumber(value)
end


-- Fake-dead state is not authoritative permanent death. Prefer health.
local function getHealthSafe(z)
    local health=nil
    safe("getHealth",function() health=z:getHealth() end)
    return tonumber(health)
end

local function isActuallyDead(z)
    if not z then return true end
    local health=getHealthSafe(z)
    if health~=nil then return health<=0.0 end
    local dead=false
    safe("isDead fallback",function() dead=z:isDead() end)
    return dead==true
end

local function processRegionalUVTissue(z,dt)
    if Config.EnableRegionalUVTissue~=true then return true,{unchanged=true} end
    if not UVTissueScheduler or type(UVTissueScheduler.process)~="function" then
        return false,"regional UV scheduler unavailable"
    end
    local finish=tonumber(worldAgeHours())
    if not finish then return false,"world time unavailable" end
    finish=finish*60
    local artificial=ProjectNightfall.ArtificialUV
    local emitters=artificial and type(artificial.getCurrentEmitters)=="function"
        and artificial.getCurrentEmitters(z) or {}
    local success,result=UVTissueScheduler.process(z,emitters,dt,finish,{
        enabled=true,
        maximumElapsedMinutes=Config.RegionalUVTissueMaximumElapsedMinutes,
        policyRevision=Config.RegionalUVTissuePolicyRevision,
        policy=Config.RegionalUVTissuePolicy,
    },{cell=getCell and getCell() or nil})
    if success and type(result)=="table" and type(result.exposure)=="table"
        and (tonumber(result.exposure.artificial) or 0)>0 then
        ZombieUV.markArtificialUVExposure(z,Config.ArtificialUVSlowHoldTicks or 60)
        local artificial=ProjectNightfall.ArtificialUV
        if artificial and type(artificial.considerIndependentAttack)=="function" then
            artificial.considerIndependentAttack(z,result.exposure)
        end
    end
    return success,result
end

local function regionalSunHibernationReady(z)
    if Config.EnableRegionalUVTissue~=true then return nil end
    if not SunHibernation or type(SunHibernation.evaluate)~="function" then return false end
    local ok,result=SunHibernation.evaluate(z,{
        enabled=Config.EnableSunKnockdown~=false,
        minimumNaturalDose=Config.RegionalUVHibernateMinimumNaturalDose,
        minimumAffectedRegions=Config.RegionalUVHibernateMinimumAffectedRegions,
    })
    return ok==true and type(result)=="table" and result.eligible==true
end


local function getState(z)
    local s=tracked[z]
    if not s then
        s={phase="NORMAL", lastWorldAgeHours=worldAgeHours(), lastDetailTick=-999999,
           countedDeadWhileDown=false, currentAction="NORMAL", holdUntilTick=0,
           lastShelterPathTick=-999999, lastObservationPathTick=-999999,
           lastInterestPathTick=-999999, lastSignalTick=-999999,
           playDeadAtTick=nil, playDeadEngaged=false,
           hibernationDisturbed=false, hibernationWakeDistance=nil,
           hibernationGiveUpDistance=nil, hibernationNextWakeCheck=-999999,
           wasOutside=nil, shelterHoldUntilHours=nil, shelterHoldActive=false,
           riseCandidateSinceHours=nil, riseScheduledAtHours=nil,
           feralGearProcessed=false, smartFeral=false, smartGearProcessed=false,
           feralEligibleAtKnockdown=false, starvationHoursAtKnockdown=0,
           lockedVisualKind=nil, lockedVisualId=nil, lockedVisualAppliedName=nil,
           lastSmartSunPathTick=-999999, dayDormant=false,
           smartMode="IDLE", smartTarget=nil, smartLastPathTick=-999999,
           lastSharedIntentPathTick=-999999,
           artificialUVUntilTick=-999999, uvSlowed=false,
           sprintActive=false, sprintReason=nil, sprintUntilTick=-999999,
           nextSprintDecisionTick=-999999, lastFeralShelterPathTick=-999999,
           grudgeTarget=nil, grudgeKey=nil,
           shelterEntrySquare=nil, crowdFlowTarget=nil, crowdFlowUntilTick=-999999,
           lastCrowdFlowPathTick=-999999,
           effigyHuntId=nil,effigyHuntUntilHours=nil,effigyHuntOriginX=nil,
           effigyHuntOriginY=nil,effigyHuntOriginZ=nil,effigyHuntEnraged=false,
           lastEffigyPathTick=-999999,
           smartHideBuilding=nil, smartHideUntilHours=nil, smartHideSquare=nil,
           lastLifecycleUpdateTick=-999999, nightExitEpoch=nil,
           nightExitNextTick=-999999}
        safe("restore lifecycle state",function()
            if z.getModData then StatePersistence.restore(z:getModData(),s) end
        end)
        tracked[z]=s
        MortisIntegration.applyIdentityToState(z,s)
        if s.phase=="TRANSFORMING" then hibernating[z]=true end
    end
    return s
end

local function persistGrudge(z,s)
    safe("persist Smart Feral grudge",function()
        local data=z:getModData()
        data.ProjectNightfall=data.ProjectNightfall or {}
        data.ProjectNightfall.grudgeKey=s.grudgeKey
        if z.transmitModData then z:transmitModData() end
    end)
end

local function restoreGrudge(z,s)
    if s.grudgeKey then return end
    safe("restore Smart Feral grudge",function()
        local data=z:getModData()
        s.grudgeKey=data and data.ProjectNightfall and data.ProjectNightfall.grudgeKey or nil
    end)
end

local function artificialUVIsActive(s)
    return (tonumber(s and s.artificialUVUntilTick) or -999999)>=tick
end

-- Fake-dead transitions and other engine state changes must never push a
-- naturally hibernating zombie below Nightfall's configured floor. Artificial
-- UV remains deliberately lethal and bypasses this repair.
local function enforceHibernationHealthFloor(z,s)
    if artificialUVIsActive(s) then return false end
    local floor=NaturalUVHealth.floor(Config)
    local health=getHealthSafe(z)
    if health~=nil and health<floor then
        local written=safe("restore hibernation health floor",function() z:setHealth(floor) return true end)
        local verified=getHealthSafe(z)
        if written==true and verified and math.abs(verified-floor)<=0.000001 then
            stats.naturalFloorRestores=stats.naturalFloorRestores+1
            return true
        end
    end
    return false
end

function ZombieUV.markArtificialUVExposure(z,durationTicks)
    if not z then return false end
    local s=getState(z)
    local duration=math.max(1,math.floor(tonumber(durationTicks) or Config.ArtificialUVSlowHoldTicks or 60))
    s.artificialUVUntilTick=math.max(tonumber(s.artificialUVUntilTick) or -999999,tick+duration)
    return true
end

local function setSprint(z,s,enabled,reason)
    enabled=enabled==true
    if s.sprintActive==enabled and (not enabled or s.sprintReason==reason) then return true end
    local ok,why=MortisIntegration.setFeralSprint(z,enabled)
    if ok then
        s.sprintActive=enabled
        s.sprintReason=enabled and reason or nil
        return true
    end
    log("MORTIS Feral sprint transition deferred: "..tostring(why))
    return false
end

local recoveryMessages=setmetatable({},{__mode="k"})
local function recoveryLog(z,kind,reason)
    local messages=recoveryMessages[z] or {};recoveryMessages[z]=messages
    local text=tostring(reason):sub(1,256)
    if messages[kind]~=text then
        messages[kind]=text
        log("MORTIS "..kind.." deferred: "..text)
    end
end

local function releaseUVSlow(z,s)
    if not s.uvSlowed then return true end
    local released,reason=MortisIntegration.setUVSlowed(z,false)
    if released~=true then
        recoveryLog(z,"UV slow release",reason)
        return false
    end
    s.uvSlowed=false
    return true
end

local function disableFerals(z,s)
    local cleared,reason=MortisIntegration.clear(z)
    if cleared~=true then
        recoveryLog(z,"disabled-feral cleanup",reason)
        return false
    end
    s.phase="NORMAL"
    s.smartFeral=false
    s.alphaFeral=false
    s.sprintActive=false
    s.sprintReason=nil
    s.uvSlowed=false
    return true
end

local function updateUVSlow(z,s,exposedDLS)
    local artificial=(tonumber(s.artificialUVUntilTick) or -999999)>=tick
    local natural=(tonumber(exposedDLS) or 0)>=(tonumber(Config.UVSlowMinimumExposure) or 0.10)
    local shouldSlow=s.phase=="NORMAL" and (natural or artificial)
    if s.uvSlowed==shouldSlow then return end
    local ok,reason=MortisIntegration.setUVSlowed(z,shouldSlow)
    if ok then s.uvSlowed=shouldSlow
    else log("MORTIS UV slow transition deferred: "..tostring(reason)) end
end

local function reserveEquivalent(z)
    local pool=FeralReserve.pool(z)
    return pool and pool.fraction*Config.FeralizationThreshold or 0
end

local function drainSprintReserve(z,s,dt)
    if not s.sprintActive then return end
    local ok,reason=FeralReserve.drainSprintEntity(z,dt)
    if not ok then
        setSprint(z,s,false,"reserve-error")
        if Config.Diagnostic then log("Regional sprint reserve drain failed: "..tostring(reason)) end
        return
    end
    if not FeralReserve.canSprintEntity(z) then
        setSprint(z,s,false,"reserve-depleted")
    end
end


function ZombieUV.setLockedVisual(kind,sex,visualId)
    if kind~="FERAL" and kind~="SMART_FERAL" then return false end
    if sex~="Male" and sex~="Female" then return false end
    local target=(kind=="SMART_FERAL") and Config.LockedSmartFeralVisuals or Config.LockedFeralVisuals
    if not target then return false end
    target[sex]=visualId
    return true
end

function ZombieUV.track(z,source)
    if not z or tracked[z] then return false end
    getState(z)
    if Config.Diagnostic then log("Tracking zombie from "..tostring(source or "unknown").." @ "..math.floor(z:getX())..","..math.floor(z:getY())..","..math.floor(z:getZ())) end
    return true
end

local function enqueueRelevant(z)
    if not z or relevantQueued[z] then return false end
    relevantTail=relevantTail+1
    relevantQueue[relevantTail]=z
    relevantQueued[z]=true
    return true
end

local function popRelevant()
    while relevantHead<=relevantTail do
        local z=relevantQueue[relevantHead]
        relevantQueue[relevantHead]=nil
        relevantHead=relevantHead+1
        if z then relevantQueued[z]=nil; return z end
    end
    relevantQueue,relevantHead,relevantTail={},1,0
    return nil
end

local function elapsedGameMinutes(s)
    local now=worldAgeHours(); if not now then return 0.0 end
    if not s.lastWorldAgeHours then s.lastWorldAgeHours=now; return 0.0 end
    local m=(now-s.lastWorldAgeHours)*60.0; s.lastWorldAgeHours=now
    if m<0 then return 0.0 end
    return math.min(m,Config.MaxElapsedGameMinutesPerUpdate)
end


local function randomUnit()
    if ZombRandFloat then
        local v=safe("ZombRandFloat",function() return ZombRandFloat(0.0,1.0) end)
        if v~=nil then return tonumber(v) or 0.5 end
    end
    return math.random()
end

local function distance2D(a,b)
    if not a or not b then return math.huge end
    local ax,ay,bx,by
    safe("hibernation distance",function()
        ax,ay,bx,by=a:getX(),a:getY(),b:getX(),b:getY()
    end)
    if not ax or not bx then return math.huge end
    local dx,dy=ax-bx,ay-by
    return math.sqrt(dx*dx+dy*dy)
end

local function damageWornGear(z)
    local worn=safe("getWornItems",function() return z:getWornItems() end)
    if not worn then return 0 end
    local count=safe("worn:size",function() return worn:size() end)
    if count==nil then return 0 end

    local minFrac=tonumber(Config.FeralWornGearDamageMin) or 0.20
    local maxFrac=tonumber(Config.FeralWornGearDamageMax) or 0.40
    if maxFrac<minFrac then minFrac,maxFrac=maxFrac,minFrac end

    local damaged=0
    for i=0,count-1 do
        local item=safe("worn:getItemByIndex",function() return worn:getItemByIndex(i) end)
        if item then
            local cond=tonumber(safe("worn item getCondition",function() return item:getCondition() end))
            local maxCond=tonumber(safe("worn item getConditionMax",function() return item:getConditionMax() end))
            if cond and maxCond and maxCond>0 and cond>0 then
                local frac=minFrac+((maxFrac-minFrac)*randomUnit())
                local loss=math.max(1,math.floor((maxCond*frac)+0.5))
                local newCond=math.max(1,cond-loss)
                safe("worn item setCondition",function() item:setCondition(newCond) end)
                damaged=damaged+1
            end
        end
    end
    safe("worn gear model refresh",function() z:onWornItemsChanged() end)
    return damaged
end

local function refreshWornModel(z,label)
    safe((label or "worn").." onWornItemsChanged",function() z:onWornItemsChanged() end)
    safe((label or "worn").." resetModelNextFrame",function()
        if z.resetModelNextFrame then z:resetModelNextFrame() else z:resetModel() end
    end)
end

local function dropHeldGear(z)
    local primary=safe("getPrimaryHandItem",function() return z:getPrimaryHandItem() end)
    local secondary=safe("getSecondaryHandItem",function() return z:getSecondaryHandItem() end)
    if not primary and not secondary then return 0 end

    -- Vanilla owns the hand->ground transfer and correctly handles a two-handed
    -- item that occupies both slots.
    safe("dropHandItems",function() z:dropHandItems() end)

    local count=0
    if primary then count=count+1 end
    if secondary and secondary~=primary then count=count+1 end
    return count
end


local function lowerSafe(v)
    if v==nil then return "" end
    return string.lower(tostring(v))
end

local function containsAny(text,hints)
    text=lowerSafe(text)
    if text=="" or not hints then return false end
    for _,hint in ipairs(hints) do
        if string.find(text,lowerSafe(hint),1,true) then return true end
    end
    return false
end

local function itemDescriptor(item)
    if not item then return "" end
    local parts={}
    local function add(v) if v~=nil then parts[#parts+1]=tostring(v) end end
    safe("item getType",function() add(item:getType()) end)
    safe("item getFullType",function() add(item:getFullType()) end)
    safe("item getDisplayName",function() add(item:getDisplayName()) end)
    safe("item getName",function() add(item:getName()) end)
    safe("item getCategory",function() add(item:getCategory()) end)
    return string.lower(table.concat(parts," "))
end

local function hasTagSafe(item,tag)
    local result=false
    safe("item hasTag "..tostring(tag),function()
        if item.hasTag then result=item:hasTag(tag)==true end
    end)
    return result
end

local function isFirearmLike(item,desc)
    if not item then return false end
    if containsAny(desc,{"gun","rifle","pistol","revolver","shotgun","firearm"}) then return true end
    local ranged=false
    safe("item isRanged",function()
        if item.isRanged then ranged=item:isRanged()==true end
    end)
    return ranged
end

local function isSunResistantGear(item)
    if not item then return false end
    local desc=itemDescriptor(item)

    -- Explicit durable gear categories first.
    if isFirearmLike(item,desc) then return true end
    if hasTagSafe(item,"Belt") or hasTagSafe(item,"Holster") then return true end
    if hasTagSafe(item,"Leather") or hasTagSafe(item,"Denim") then return true end
    if hasTagSafe(item,"Metal") or hasTagSafe(item,"Plastic") then return true end

    return containsAny(desc,Config.SmartFeralSunResistantTypeHints)
end

local function isFabricGear(item)
    if not item then return false end
    local desc=itemDescriptor(item)

    -- Durable/sun-resistant classification always wins.  This prevents a
    -- "leather jacket" from being destroyed just because "jacket" is clothing.
    if isSunResistantGear(item) then return false end

    if hasTagSafe(item,"Fabric") or hasTagSafe(item,"Clothing") then
        return true
    end
    return containsAny(desc,Config.SmartFeralFabricTypeHints)
end

local function removeItemFromZombie(z,inv,item)
    safe("remove attached item",function()
        if z.isAttachedItem and z:isAttachedItem(item) then z:removeAttachedItem(item) end
    end)
    safe("remove carried item",function() inv:Remove(item) end)
end

local function destroyFabricGear(z,inv,item)
    removeItemFromZombie(z,inv,item)
    safe("destroy fabric item",function()
        if item.setCondition then item:setCondition(0) end
    end)
end

local function dropItemAtZombie(z,square,inv,item)
    removeItemFromZombie(z,inv,item)
    safe("drop carried item",function()
        local ox=0.15+(randomUnit()*0.70)
        local oy=0.15+(randomUnit()*0.70)
        square:AddWorldInventoryItem(item,ox,oy,0.0,true)
    end)
end

local function processSmartFeralGear(z)
    local inv=safe("getInventory",function() return z:getInventory() end)
    local square=safe("getCurrentSquare",function() return z:getCurrentSquare() end)
    local worn=safe("getWornItems",function() return z:getWornItems() end)
    if not inv or not square then return 0,0,0 end

    local items=safe("inventory getItems",function() return inv:getItems() end)
    local size=items and safe("inventory items size",function() return items:size() end) or nil
    if size==nil then return 0,0,0 end

    local destroyList={}
    local dropList={}
    local preserveCount=0

    -- Snapshot before mutating the container.
    for i=0,size-1 do
        local item=safe("inventory item get",function() return items:get(i) end)
        if item then
            local isWorn=false
            if worn then
                isWorn=(safe("worn contains",function() return worn:contains(item) end)==true)
            end

            if isSunResistantGear(item) then
                -- Preserve durable gear whether worn, attached, holstered, or carried.
                preserveCount=preserveCount+1
            elseif isFabricGear(item) then
                -- Fabric does not survive Smart Feral solar exposure.
                destroyList[#destroyList+1]=item
            elseif not isWorn then
                -- Everything else carried is discarded normally.
                dropList[#dropList+1]=item
            else
                -- Non-fabric worn gear that is not explicitly durable is retained.
                -- This avoids stripping unknown modded protective gear by accident.
                preserveCount=preserveCount+1
            end
        end
    end

    for _,item in ipairs(destroyList) do
        destroyFabricGear(z,inv,item)
    end
    for _,item in ipairs(dropList) do
        dropItemAtZombie(z,square,inv,item)
    end

    safe("smart feral worn model refresh",function() z:onWornItemsChanged() end)
    return #destroyList,#dropList,preserveCount
end

local function processFeralGearTransition(z,s)
    if s.feralGearProcessed then return end
    s.feralGearProcessed=true
    local dropped=dropHeldGear(z)
    local damaged=damageWornGear(z)
    log(string.format(
        "FERAL GEAR TRANSITION @ %d,%d droppedHeld=%d damagedWorn=%d",
        math.floor(z:getX()),math.floor(z:getY()),dropped,damaged
    ))
end


function ZombieUV.promoteToSmartFeral(z,source)
    if (tonumber(Config.SmartFeralRawCognitionMax) or 1) <= 0 then return false end
    if not z or isActuallyDead(z) then return false end
    local s=getState(z)
    if s.smartFeral then return false end
    if s.phase~="FERAL" then
        log("SMART FERAL promotion rejected: zombie is not in FERAL phase")
        return false
    end

    local assigned,assignReason=MortisIntegration.assign(z,MortisIntegration.TYPE_SMART_FERAL)
    if not assigned then recoveryLog(z,"Smart Feral assignment",assignReason);return false end
    s.smartFeral=true
    applyLockedTransformationVisual(z,s,"SMART_FERAL")
    local destroyed,dropped,preserved=0,0,0
    if not s.smartGearProcessed then
        s.smartGearProcessed=true
        destroyed,dropped,preserved=processSmartFeralGear(z)
    end

    log(string.format(
        "SMART FERAL PROMOTION @ %d,%d source=%s destroyedFabric=%d dropped=%d preservedSunResistant=%d",
        math.floor(z:getX()),math.floor(z:getY()),tostring(source or "unknown"),
        destroyed,dropped,preserved
    ))
    return true
end

function ZombieUV.isSmartFeral(z)
    local s=z and tracked[z] or nil
    return s and s.smartFeral==true or false
end

function ZombieUV.getPhase(z)
    local s=z and tracked[z] or nil
    return s and s.phase or nil
end


-- Feral transformation appearance is body-bound visual state, never lootable
-- inventory.  This avoids the player stripping/equipping the transformation
-- "outfit" and keeps surviving real gear independent from the skin layer.
local function zombieSexKey(z)
    local female=false
    safe("isFemale",function()
        if z.isFemale then female=z:isFemale()==true end
    end)
    return female and "Female" or "Male"
end

local function configuredLockedVisual(kind,z)
    local sex=zombieSexKey(z)
    local tableRef=(kind=="SMART_FERAL") and Config.LockedSmartFeralVisuals or Config.LockedFeralVisuals
    if not tableRef then return nil end
    return tableRef[sex]
end

applyLockedTransformationVisual=function(z,s,kind)
    if not z or not s then return false end
    local visualId=configuredLockedVisual(kind,z)
    s.lockedVisualKind=kind
    s.lockedVisualId=visualId

    -- Feralization permanently removes scalp and facial hair. "Bald" is the
    -- stock zero-mesh hairstyle for both sexes; an empty beard model is the
    -- vanilla clean-shaven representation and also removes moustaches.
    safe("apply feral baldness",function()
        local hv=z:getHumanVisual()
        if not hv then return end
        hv:setHairModel("Bald")
        hv:setNonAttachedHair("")
        hv:setBeardModel("")
    end)

    if not visualId then
        log("VISUAL APPLY skipped: no configured texture for "..tostring(kind).." "..zombieSexKey(z))
        return false
    end

    local applied=false
    safe("apply locked body visual",function()
        local hv=z:getHumanVisual()
        if not hv or not hv.setSkinTextureName then return end

        hv:setSkinTextureName(visualId)
        local current=nil
        if hv.getSkinTexture then current=hv:getSkinTexture() end
        s.lockedVisualAppliedName=current or visualId
        applied=true
    end)

    if applied then
        safe("resetModel",function() z:resetModel() end)
        safe("resetModelNextFrame",function()
            if z.resetModelNextFrame then z:resetModelNextFrame() end
        end)
        log(string.format(
            "VISUAL APPLY @ %d,%d kind=%s sex=%s requested=%s active=%s",
            math.floor(z:getX()),math.floor(z:getY()),tostring(kind),zombieSexKey(z),
            tostring(visualId),tostring(s.lockedVisualAppliedName or "unknown")
        ))
    end
    return applied
end

local function maintainLockedTransformationVisual(z,s)
    if not z or not s or not s.lockedVisualKind then return end

    safe("maintain locked body visual",function()
        local hv=z:getHumanVisual()
        if not hv then return end

        -- Outfit/model rebuilds may restore the zombie's generated hair. Keep
        -- both Feral variants visibly bald and clean-shaven after every refresh.
        hv:setHairModel("Bald")
        hv:setNonAttachedHair("")
        hv:setBeardModel("")

        if not s.lockedVisualId or not hv.setSkinTextureName then return end

        local current=nil
        if hv.getSkinTexture then current=hv:getSkinTexture() end
        if current~=s.lockedVisualId then
            hv:setSkinTextureName(s.lockedVisualId)
            s.lockedVisualAppliedName=s.lockedVisualId
            if z.resetModelNextFrame then z:resetModelNextFrame() else z:resetModel() end
        end
    end)
end

local function beginFeralization(z,s,dls)
    if s.phase~="NORMAL" then return false end
    -- Release while still standing; a refused owner stays tracked for retry.
    if not releaseUVSlow(z,s) then return false end
    if not MortisIntegration.captureWalkingBeforeHold(z,s) then return false end
    local eligible=Config.EnableFerals~=false
    local starvationHours=0
    if eligible and Config.RequireStarvationForFerals~=false then
        eligible,starvationHours=MortisIntegration.hasStarvedFor(z,Config.FeralRequiredStarvationDays or 7)
    end
    if eligible then
        local assigned,assignReason=MortisIntegration.assign(z,MortisIntegration.TYPE_TRANSFORMING)
        if not assigned then recoveryLog(z,"transforming assignment",assignReason);return false end
    end
    s.phase="TRANSFORMING"
    hibernating[z]=true
    s.feralEligibleAtKnockdown=eligible==true
    s.starvationHoursAtKnockdown=tonumber(starvationHours) or 0
    if eligible then stats.feralizations=stats.feralizations+1 end
    if eligible then
        processFeralGearTransition(z,s)
        applyLockedTransformationVisual(z,s,"FERAL")
    end
    -- Stage 1: normal living knockdown/fall.
    safe("setFakeDead(false)",function() z:setFakeDead(false) end)
    safe("setForceFakeDead(false)",function() z:setForceFakeDead(false) end)
    safe("setAlwaysKnockedDown(true)",function() z:setAlwaysKnockedDown(true) end)
    safe("setKnockedDown(true)",function() z:setKnockedDown(true) end)
    safe("setCanWalk(false)",function() z:setCanWalk(false) end)
    safe("setCrawler(false)",function() z:setCrawler(false) end)
    safe("knockDown(false)",function() z:knockDown(false) end)
    -- Applying the locked body skin resets the model immediately before this
    -- knockdown. Rebuild worn layers on the following frame so a prone zombie
    -- does not render naked until its wake transition refreshes the outfit.
    refreshWornModel(z,"feral knockdown")

    s.playDeadAtTick=tick+(Config.TransformPlayDeadDelayTicks or 30)
    s.playDeadEngaged=false
    s.riseCandidateSinceHours=nil
    s.riseScheduledAtHours=nil
    s.hibernationDisturbed=false
    s.hibernationWakeDistance=(tonumber(Config.HibernationWakeDistanceMin) or 2.0)
        + randomUnit()*((tonumber(Config.HibernationWakeDistanceMax) or 3.0)-(tonumber(Config.HibernationWakeDistanceMin) or 2.0))
    s.hibernationGiveUpDistance=(tonumber(Config.HibernationGiveUpDistanceMin) or 5.0)
        + randomUnit()*((tonumber(Config.HibernationGiveUpDistanceMax) or 7.0)-(tonumber(Config.HibernationGiveUpDistanceMin) or 5.0))

    log(string.format("HIBERNATION BEGIN @ %d,%d DLS=%.3f storedUV=%.2f feralEligible=%s starvationHours=%.1f -- falling; play-dead scheduled",
        math.floor(z:getX()),math.floor(z:getY()),dls,reserveEquivalent(z),tostring(eligible),s.starvationHoursAtKnockdown))
end


local function rawCognitionFor(z,s,dls)
    local _,_,raw=UVAI.getEffectiveCognition01(dls or 0.0,reserveEquivalent(z))
    return tonumber(raw) or 3
end

local function maybePromoteSmartFeral(z,s,dls,source)
    if not Config.EnableAutomaticSmartFeralPromotion or s.smartFeral then return false end
    local raw=rawCognitionFor(z,s,dls)
    local cognitionMax = tonumber(Config.SmartFeralRawCognitionMax) or 1
    if cognitionMax <= 0 or raw > cognitionMax then return false end

    local promoted=ZombieUV.promoteToSmartFeral(z,source or "automatic-cognition")
    if promoted then
        stats.smartPromotions=stats.smartPromotions+1
        AlphaFerals.rollAfterSmartPromotion(z,s,randomUnit)
        log(string.format(
            "SMART FERAL AUTO-PROMOTION @ %d,%d rawCognition=%d",
            math.floor(z:getX()),math.floor(z:getY()),raw
        ))
    end
    return promoted
end

local function requestHibernationFakeDead(z,s,label)
    local entered,reason=MortisIntegration.requestFakeDead(z)
    if not entered then
        s.playDeadEngaged=false
        s.playDeadAtTick=tick+math.max(1,tonumber(Config.TransformPlayDeadDelayTicks)or 30)
        log("HIBERNATION FAKE-DEAD DEFERRED: "..tostring(reason))
        return false
    end
    safe(label.." setAlwaysKnockedDown",function() z:setAlwaysKnockedDown(true) end)
    safe(label.." setCanWalk",function() z:setCanWalk(false) end)
    safe(label.." setCrawler",function() z:setCrawler(false) end)
    safe(label.." clear target",function() z:setTarget(nil) end)
    s.playDeadEngaged=true
    return true
end

local function enterRegularFeralDayDormancy(z,s,dls)
    if s.phase~="FERAL" then return false end
    if not MortisIntegration.captureWalkingBeforeHold(z,s) then return false end
    local assigned,assignReason=MortisIntegration.assign(z,MortisIntegration.TYPE_TRANSFORMING)
    if not assigned then recoveryLog(z,"dormant Feral assignment",assignReason);return false end
    s.phase="TRANSFORMING"
    hibernating[z]=true
    s.dayDormant=true
    s.playDeadAtTick=tick+(Config.TransformPlayDeadDelayTicks or 30)
    s.playDeadEngaged=false
    s.riseCandidateSinceHours=nil
    s.riseScheduledAtHours=nil

    safe("feral dawn setFakeDead(false)",function() z:setFakeDead(false) end)
    safe("feral dawn setForceFakeDead(false)",function() z:setForceFakeDead(false) end)
    safe("feral dawn setAlwaysKnockedDown(true)",function() z:setAlwaysKnockedDown(true) end)
    safe("feral dawn setKnockedDown(true)",function() z:setKnockedDown(true) end)
    safe("feral dawn setCanWalk(false)",function() z:setCanWalk(false) end)
    safe("feral dawn setCrawler(false)",function() z:setCrawler(false) end)
    safe("feral dawn knockDown",function() z:knockDown(false) end)

    stats.feralDayDormancies=stats.feralDayDormancies+1
    log(string.format(
        "FERAL DAY DORMANCY @ %d,%d DLS=%.3f",
        math.floor(z:getX()),math.floor(z:getY()),tonumber(dls) or -1
    ))
    return true
end

local function riseAtNight(z,s,dls)
    if s.phase~="TRANSFORMING" or isActuallyDead(z) then return end
    local feralsEnabled=LifecycleRules.risesAsFeral(Config.EnableFerals,s.feralEligibleAtKnockdown)
    local committed,identityOrReason=MortisIntegration.commitRiseIdentity(z,feralsEnabled,s.smartFeral)
    if not committed then
        -- Keep all hibernation locks and phase intact. The scheduler will retry
        -- once canonical identity authority/state becomes available.
        s.riseScheduledAtHours=nil
        s.riseCandidateSinceHours=nil
        log("MORTIS rise identity deferred; zombie remains hibernating: "..tostring(identityOrReason))
        return false
    end
    -- M.O.R.T.I.S. owns the verified transition surface. Do not announce or
    -- count a rise merely because identity committed: the body must also be
    -- releasable to a stand/get-up path.
    local stood,standReason=MortisIntegration.requestRise(z,s)
    if not stood then
        local rolledBack,rollbackReason=MortisIntegration.rollbackRiseIdentity(z)
        requestHibernationFakeDead(z,s,"stand failure")
        s.riseScheduledAtHours=nil
        s.riseCandidateSinceHours=nil
        log("MORTIS stand deferred; hibernation restored: "..tostring(standReason)
            ..(rolledBack and "" or "; identity rollback failed: "..tostring(rollbackReason)))
        return false
    end
    s.phase=feralsEnabled and "FERAL" or "NORMAL"
    hibernating[z]=nil
    if not feralsEnabled then
        s.smartFeral=false
        s.feralEligibleAtKnockdown=false
    end
    -- Release every lock flag only on an authorized Nightfall rise.
    safe("setForceFakeDead(false)",function() z:setForceFakeDead(false) end)
    safe("setFakeDead(false)",function() z:setFakeDead(false) end)
    safe("setWasFakeDead(false)",function() z:setWasFakeDead(false) end)
    safe("rise clear target",function() z:setTarget(nil) end)
    safe("setAlwaysKnockedDown(false)",function() z:setAlwaysKnockedDown(false) end)
    safe("night rise restore health",function()
        z:setHealth(clamp(tonumber(Config.NightRiseHealth) or 1.0,0.01,1.0))
    end)

    -- requestRise above selected stand or crawler from canonical anatomy.
    -- These idempotent releases cover Nightfall-specific fake-dead locks.
    s.playDeadAtTick=nil
    s.playDeadEngaged=false
    s.riseCandidateSinceHours=nil
    s.riseScheduledAtHours=nil
    s.dayDormant=false
    s.hibernationDisturbed=false
    stats.rises=stats.rises+1
    if feralsEnabled then maybePromoteSmartFeral(z,s,dls,"rise") end
    log(string.format("NIGHT RISE @ %d,%d DLS=%.3f result=%s smart=%s health=%.2f",
        math.floor(z:getX()),math.floor(z:getY()),dls,s.phase,tostring(s.smartFeral==true),getHealthSafe(z) or -1))
    return true
end

local function maintainTransformingState(z,s,globalDLS)
    -- Weather can make daylight strength collapse during the day. Use the
    -- engine's dedicated night-strength signal and require it to remain over
    -- threshold for several in-game minutes before committing to a rise.
    local nightStrength = getNightStrength()
    local threshold = Config.RiseAtOrAboveNightStrength or 0.60
    local confirmMinutes = Config.RiseConfirmMinutes or 5.0
    local nowHours = worldAgeHours()

    if nightStrength and nightStrength>=threshold and nowHours then
        if not s.riseCandidateSinceHours then
            s.riseCandidateSinceHours=nowHours
        end
        local heldMinutes=(nowHours-s.riseCandidateSinceHours)*60.0
        if heldMinutes>=confirmMinutes then
            if not s.riseScheduledAtHours then
                local spreadMinutes=Config.RiseSpreadMinutes or 10.0
                local delayMinutes=0.0
                if spreadMinutes>0 then
                    if ZombRand then
                        delayMinutes=ZombRand(math.floor(spreadMinutes*60)+1)/60.0
                    else
                        delayMinutes=math.random()*spreadMinutes
                    end
                end
                s.riseScheduledAtHours=nowHours+(delayMinutes/60.0)
                log(string.format(
                    "FERAL RISE SCHEDULED @ %d,%d in %.2f game-minutes",
                    math.floor(z:getX()),math.floor(z:getY()),delayMinutes
                ))
            end
            if nowHours>=s.riseScheduledAtHours then
                riseAtNight(z,s,globalDLS)
                return
            end
        end
    else
        s.riseCandidateSinceHours=nil
        s.riseScheduledAtHours=nil
    end

    -- Hibernation uses the engine's true fake-dead state. A close player may
    -- trigger a very rare surprise crawl; once disturbed, the zombie abandons
    -- pursuit at its per-instance 5-7 tile limit and re-enters fake-dead state.
    local _,_,rawCognition = UVAI.getEffectiveCognition01(globalDLS,reserveEquivalent(z))
    local target,dist=FeralAI.findNearestPlayer(z,tonumber(s.hibernationGiveUpDistance) or 7.0)
    local stupidest = rawCognition >= (Config.TransformCrawlerRawCognitionThreshold or 3)
    local fakeDeadNow=false
    safe("transform read fake-dead",function() fakeDeadNow=z:isFakeDead()==true end)
    local engineWoke=s.playDeadEngaged and not fakeDeadNow
    if not s.hibernationDisturbed and stupidest and target
        and dist<=(tonumber(s.hibernationWakeDistance) or 3.0)
        and tick>=(tonumber(s.hibernationNextWakeCheck) or -999999) then
        s.hibernationNextWakeCheck=tick+(tonumber(Config.HibernationWakeCheckTicks) or 300)
        local chance=tonumber(Config.HibernationCloseWakeChance) or 0.03
        if engineWoke or randomUnit()<chance then s.hibernationDisturbed=true end
    end
    if s.hibernationDisturbed and (not target or dist>=(tonumber(s.hibernationGiveUpDistance) or 6.0)) then
        s.hibernationDisturbed=false
        s.playDeadEngaged=false
        s.playDeadAtTick=tick
    end

    if engineWoke and not s.hibernationDisturbed then
        -- A non-authorized engine wake must re-enter through the real state,
        -- never by setting the lethal flag while still in OnGroundState.
        s.playDeadEngaged=false
        s.playDeadAtTick=tick
    end

    if s.hibernationDisturbed and target then
        safe("transform crawl ForceFakeDead(false)",function() z:setForceFakeDead(false) end)
        safe("transform crawl FakeDead(false)",function() z:setFakeDead(false) end)
        safe("transform crawl AlwaysKnockedDown(false)",function() z:setAlwaysKnockedDown(false) end)
        safe("transform crawl setCanWalk(true)",function() z:setCanWalk(true) end)
        safe("transform allow crawler",function() z:setCrawler(true) end)
        safe("transform crawl setKnockedDown(true)",function() z:setKnockedDown(true) end)
        safe("transform crawl target",function() z:setTarget(target) end)
        s.playDeadEngaged=false
        stats.transformCrawlAllows=stats.transformCrawlAllows+1
    else
        safe("transform block crawler",function() z:setCrawler(false) end)
        stats.transformCrawlBlocks=stats.transformCrawlBlocks+1

        if not s.playDeadEngaged and s.playDeadAtTick and tick>=s.playDeadAtTick then
            if requestHibernationFakeDead(z,s,"transform enter fake-dead") then
                log(string.format(
                    "SUN HIBERNATION FAKE-DEAD @ %d,%d rawCognition=%s",
                    math.floor(z:getX()),math.floor(z:getY()),tostring(rawCognition)
                ))
            end
        elseif s.playDeadEngaged then
            safe("transform maintain AlwaysKnockedDown(true)",function() z:setAlwaysKnockedDown(true) end)
            safe("transform maintain KnockedDown(true)",function() z:setKnockedDown(true) end)
            safe("transform maintain clear target",function() z:setTarget(nil) end)
            safe("transform maintain setCanWalk(false)",function() z:setCanWalk(false) end)
            safe("transform maintain setCrawler(false)",function() z:setCrawler(false) end)
        else
            safe("transform pre-play-dead ForceFakeDead(false)",function() z:setForceFakeDead(false) end)
            safe("transform pre-play-dead FakeDead(false)",function() z:setFakeDead(false) end)
        end
    end
end


local function shelterHoldMultiplier(rawCognition)
    if rawCognition<=1 then return Config.ShelterHoldSmartMultiplier or 0.25 end
    if rawCognition==2 then return Config.ShelterHoldMediumMultiplier or 0.55 end
    return Config.ShelterHoldDumbMultiplier or 1.0
end

local function beginShelterHold(z,s,globalDLS)
    local entry=safe("capture shelter entry square",function() return z:getSquare() end)
    s.shelterEntrySquare=entry
    local moved,reason,target=safe("MORTIS deeper shelter flow",MortisIntegration.pathDeeperIntoShelter,z,entry)
    if moved then
        s.crowdFlowTarget=target
        s.crowdFlowUntilTick=tick+(tonumber(Config.ShelterCrowdFlowTicks) or 240)
        s.lastCrowdFlowPathTick=tick
    elseif Config.Diagnostic and reason and not reportedShelterSkipReasons[tostring(reason)] then
        reportedShelterSkipReasons[tostring(reason)]=true
        log("MORTIS deeper shelter flow skipped: "..tostring(reason))
    end

    local equivalent=reserveEquivalent(z)
    local cognition,_,rawCognition,imp = UVAI.getEffectiveCognition01(globalDLS,equivalent)
    local burden = imp and imp.burden or clamp(equivalent/Config.FeralizationThreshold,0.0,1.0)
    if burden < (Config.ShelterHoldBurdenThreshold or 0.10) then return end

    local minM = Config.ShelterHoldMinMinutes or 10.0
    local maxM = Config.ShelterHoldMaxMinutes or 60.0
    local duration = minM + (maxM-minM)*burden
    duration = duration * shelterHoldMultiplier(rawCognition)

    local now = worldAgeHours()
    if not now then return end
    if not MortisIntegration.captureWalkingBeforeHold(z,s) then return false end
    s.shelterHoldUntilHours = now + duration/60.0
    s.shelterHoldActive = true
    stats.shelterHoldBegins=stats.shelterHoldBegins+1
    if Config.VerboseShelterLogs then
        log(string.format(
            "SHELTER HOLD BEGIN @ %d,%d rawCog=%s burden=%.2f duration=%.1fmin",
            math.floor(z:getX()),math.floor(z:getY()),tostring(rawCognition),burden,duration
        ))
    end
end

local function releaseShelterWalking(z,s)
    local crawler=MortisIntegration.requiresCrawler(z)
    if crawler==nil then return false end
    if crawler then
        local applied=MortisIntegration.enforceActiveAnatomy(z,s)
        if applied and not s.shelterHoldActive then s.walkingBeforeLifecycleHold=nil end
        return applied
    end
    local prior=s.walkingBeforeLifecycleHold
    if type(prior)~="boolean" then return false end
    local restored=MortisIntegration.restoreWalkingPermission(z,prior)
    if not restored then return false end
    if not s.shelterHoldActive then s.walkingBeforeLifecycleHold=nil end
    return true
end

local function updateShelterHold(z,s)
    if not s.shelterHoldActive then
        if type(s.walkingBeforeLifecycleHold)=="boolean" then
            safe("retry shelter walking release",releaseShelterWalking,z,s)
        end
        return false
    end

    local now = worldAgeHours()
    -- Missing time is not elapsed time. Preserve the pending hold/baseline
    -- rather than releasing native movement during a transient clock failure.
    if not now then return true end
    if not s.shelterHoldUntilHours or now>=s.shelterHoldUntilHours then
        s.shelterHoldActive=false
        s.shelterHoldUntilHours=nil
        safe("shelter hold release",releaseShelterWalking,z,s)
        stats.shelterHoldEnds=stats.shelterHoldEnds+1
        if Config.VerboseShelterLogs then
            log(string.format("SHELTER HOLD END @ %d,%d",math.floor(z:getX()),math.floor(z:getY())))
        end
        return false
    end

    -- A visible prey target is a meaningful override; the timer exists to stop
    -- vanilla wander/migration churn, not to make the zombie oblivious to prey.
    local visible=false
    local target=nil
    safe("shelter hold visible",function() visible=z:isTargetVisible() end)
    safe("shelter hold target",function() target=z:getTarget() end)
    if visible and target~=nil then
        safe("shelter hold prey release",releaseShelterWalking,z,s)
        return false
    end

    if s.crowdFlowTarget and tick<=(tonumber(s.crowdFlowUntilTick) or -999999) then
        local tx,ty=safe("crowd flow target position",function()
            return s.crowdFlowTarget:getX()+0.5,s.crowdFlowTarget:getY()+0.5
        end)
        local distance=math.huge
        if tx and ty then
            local dx,dy=tx-z:getX(),ty-z:getY()
            distance=math.sqrt(dx*dx+dy*dy)
        end
        if distance>(tonumber(Config.ShelterCrowdFlowArrivalDistance) or 1.25) then
            safe("crowd flow release",releaseShelterWalking,z,s)
            if tick-(s.lastCrowdFlowPathTick or -999999)>=(tonumber(Config.ShelterCrowdFlowRepathTicks) or 45) then
                local moved,_,newTarget=safe("MORTIS deeper shelter repath",MortisIntegration.pathDeeperIntoShelter,z,s.shelterEntrySquare)
                if moved and newTarget then s.crowdFlowTarget=newTarget end
                s.lastCrowdFlowPathTick=tick
            end
            s.currentAction="SHELTER_CROWD_FLOW"
            return true
        end
        s.crowdFlowTarget=nil
    end

    safe("shelter hold setCanWalk(false)",function() z:setCanWalk(false) end)
    s.currentAction="SHELTER_HOLD"
    return true
end

local function applyWeightAction(z,s,map,globalDLS)
    local action=map.action
    if tick < s.holdUntilTick then action=s.currentAction else s.currentAction=action; s.holdUntilTick=tick+Config.DecisionHoldTicks end

    if action=="SEEK_SHELTER" then
        stats.seekWins=stats.seekWins+1
        if tick-s.lastShelterPathTick>=Config.ShelterRepathTicks then
            local square=safe("findNearby shelter",Shelter.findNearby,z)
            if square then
                safe("pathToLocationF shelter",function() z:pathToLocationF(square:getX()+0.5,square:getY()+0.5,square:getZ()) end)
                s.lastShelterPathTick=tick; stats.shelterPaths=stats.shelterPaths+1
            end
        end
    elseif action=="STAY_SHELTERED" then
        stats.staySheltered=stats.staySheltered+1
        -- Don't invent a new idle state in the POC. We suppress UV-driven path
        -- overrides and rely on the high repeated stay weight to resist our own exits.
    elseif action=="OBSERVE_FROM_SHELTER" then
        stats.observeWins=stats.observeWins+1
        if map.target and tick-s.lastObservationPathTick>=Config.ObservationRepathTicks then
            local point=safe("find observation point",Observation.findObservationPoint,z,map.target)
            if point then
                safe("pathToLocationF observation",function()
                    z:pathToLocationF(point:getX()+0.5,point:getY()+0.5,point:getZ())
                end)
                s.lastObservationPathTick=tick
                stats.observationPaths=stats.observationPaths+1
                if tick-s.lastSignalTick>=Config.InterestSignalCooldownTicks then
                    local sig=safe("emit interest signal",Observation.emitSignal,z,point,tick)
                    if sig then
                        s.lastSignalTick=tick
                        stats.signalsEmitted=stats.signalsEmitted+1
                        log(string.format("INTEREST SIGNAL id=%d @ %.1f,%.1f from observing zombie @ %d,%d",
                            sig.id,sig.x,sig.y,math.floor(z:getX()),math.floor(z:getY())))
                    end
                end
            end
        end
    elseif action=="INVESTIGATE_INTEREST" then
        stats.interestWins=stats.interestWins+1
        if map.nearbySignal and tick-s.lastInterestPathTick>=Config.ObservationRepathTicks then
            local ok=safe("path to interest signal",Observation.pathToSignal,z,map.nearbySignal)
            if ok then
                s.lastInterestPathTick=tick
                stats.interestPaths=stats.interestPaths+1
            end
        end
    elseif action=="CHASE" then
        stats.chaseWins=stats.chaseWins+1
        -- Vanilla chase remains authoritative; PN deliberately does nothing here.
    elseif action=="AVOID_EFFIGY" and map.effigy then
        stats.effigyAvoids=stats.effigyAvoids+1
        if tick-(s.lastEffigyPathTick or -999999)>=(Config.EffigyRepathTicks or 180) then
            local dx=z:getX()-map.effigy.x; local dy=z:getY()-map.effigy.y
            local length=math.max(0.001,math.sqrt(dx*dx+dy*dy))
            local retreat=math.min(8,math.max(3,(Config.EffigyInfluenceRadius or 24)-map.effigyDistance))
            safe("path away from effigy",function()
                z:pathToLocationF(z:getX()+dx/length*retreat,z:getY()+dy/length*retreat,z:getZ())
            end)
            s.lastEffigyPathTick=tick
        end
    elseif action=="DESTROY_EFFIGY" and map.effigy then
        if map.effigyDistance<=1.5 then
            local claimed,claimedEntry=safe("claim effigy",Effigies.claim,map.effigy.id,z,"destroy")
            if claimed then
                local completed=safe("complete effigy destruction",Effigies.completeClaim,map.effigy.id,"destroyed")
                if completed then
                    stats.effigyDestroys=stats.effigyDestroys+1
                    local reaction=map.effigyReaction or {}
                    if reaction.action=="destroy_search" then
                        s.effigyHuntId=map.effigy.id
                        s.effigyHuntUntilHours=(worldAgeHours() or 0)+(tonumber(reaction.searchHours) or 0)
                        s.effigyHuntOriginX=map.effigy.x; s.effigyHuntOriginY=map.effigy.y; s.effigyHuntOriginZ=map.effigy.z
                        s.effigyHuntEnraged=reaction.enraged==true
                        FeralGroups.shareEffigyHunt(z,{
                            effigyId=map.effigy.id,x=map.effigy.x,y=map.effigy.y,z=map.effigy.z,
                            huntUntilHours=s.effigyHuntUntilHours,enraged=s.effigyHuntEnraged,
                            ownerPlayerKey=claimedEntry and claimedEntry.ownerPlayerKey or nil,
                        },tick)
                        if claimedEntry and claimedEntry.ownerPlayerKey then
                            s.grudgeKey=claimedEntry.ownerPlayerKey
                            s.grudgeTarget=FeralAI.findPlayerByKey(s.grudgeKey)
                            if s.grudgeTarget then s.smartTarget=s.grudgeTarget; s.smartMode="STALK" end
                            persistGrudge(z,s)
                        end
                        stats.effigyHunts=stats.effigyHunts+1
                    end
                end
            end
        elseif tick-(s.lastEffigyPathTick or -999999)>=(Config.EffigyRepathTicks or 180) then
            safe("path to effigy",function() z:pathToLocationF(map.effigy.x+0.5,map.effigy.y+0.5,map.effigy.z) end)
            s.lastEffigyPathTick=tick
        end
    else
        stats.normalWins=stats.normalWins+1
    end
end


local function isDaytimeForFeralLifecycle(globalDLS)
    local night=getNightStrength()
    if night==nil then return false end
    return night<=(Config.FeralDayDormancyMaxNightStrength or 0.10)
       and globalDLS>=(Config.FeralDayDormancyMinDLS or 0.05)
end


local function clearSmartPredatorState(s)
    s.smartMode="IDLE"
    s.smartTarget=nil
    s.smartHideBuilding=nil
    s.smartHideUntilHours=nil
    s.smartHideSquare=nil
end

local function updateSmartFeralNight(z,s,globalDLS)
    local reserveReady=FeralReserve.canSprintEntity(z)
    setSprint(z,s,reserveReady and (s.smartMode=="AMBUSH" or s.smartMode=="FLANK"),s.smartMode)
    restoreGrudge(z,s)
    local target=s.grudgeTarget
    if target and not FeralAI.isPlayerAlive(target) then
        s.grudgeTarget=nil
        s.grudgeKey=nil
        persistGrudge(z,s)
        target=nil
    end
    if not target and s.grudgeKey then
        target=FeralAI.findPlayerByKey(s.grudgeKey)
        s.grudgeTarget=target
    end
    local grudgeActive=target~=nil
    target=target or s.smartTarget
    if not target then
        target=select(1,FeralAI.findNearestPlayer(z,Config.SmartFeralStalkAcquireRadius))
        s.smartTarget=target
        if target then
            s.smartMode="STALK"
            log(string.format("SMART FERAL STALK ACQUIRE @ %d,%d",math.floor(z:getX()),math.floor(z:getY())))
        end
    end
    if not target then
        local now=worldAgeHours()
        local adopted,ownerKey=FeralGroups.applySharedEffigyHunt(z,s,now,tick)
        if adopted and ownerKey then
            s.grudgeKey=ownerKey;s.grudgeTarget=FeralAI.findPlayerByKey(ownerKey)
            if s.grudgeTarget then s.smartTarget=s.grudgeTarget;s.smartMode="STALK" end
            persistGrudge(z,s)
            target=s.grudgeTarget
        end
        if target then return updateSmartFeralNight(z,s,globalDLS) end
        if s.effigyHuntUntilHours and now and now>=s.effigyHuntUntilHours then
            s.effigyHuntId=nil; s.effigyHuntUntilHours=nil
            s.effigyHuntOriginX=nil; s.effigyHuntOriginY=nil; s.effigyHuntOriginZ=nil
            s.effigyHuntEnraged=false
            if s.smartMode=="EFFIGY_HUNT" or s.smartMode=="EFFIGY_REST" then s.smartMode="IDLE" end
        elseif s.effigyHuntUntilHours and now and s.effigyHuntOriginX and
               tick-(s.lastEffigyPathTick or -999999)>=(Config.EffigyRepathTicks or 180) then
            local cycle=s.effigyHuntEnraged and 12 or 6
            local restWindow=s.effigyHuntEnraged and 0.35 or 0.75
            local phase=now%cycle
            if phase>=cycle-restWindow then
                s.smartMode="EFFIGY_REST"
                local square=safe("find effigy hunt rest shelter",Shelter.findNearby,z)
                if square then safe("path to effigy hunt rest",function()
                    z:pathToLocationF(square:getX()+0.5,square:getY()+0.5,square:getZ())
                end) end
            else
                s.smartMode="EFFIGY_HUNT"
                local step=math.floor(now*2)+(tonumber(string.match(s.effigyHuntId or "","(%d+)$")) or 0)
                local angle=(step%16)*(math.pi*2/16)
                local ring=0.35+((step%3)*0.25)
                local radius=(Config.EffigySearchRadius or 40)*ring
                local tx=s.effigyHuntOriginX+math.cos(angle)*radius
                local ty=s.effigyHuntOriginY+math.sin(angle)*radius
                safe("path effigy hunt sector",function() z:pathToLocationF(tx,ty,s.effigyHuntOriginZ or z:getZ()) end)
            end
            s.lastEffigyPathTick=tick
            setSprint(z,s,false,"effigy-investigation")
            return
        end
        local intent=FeralGroups.getSharedIntent(z,tick)
        if intent and intent.x and tick-(s.lastSharedIntentPathTick or -999999)>=Config.SmartFeralStalkRepathTicks then
            s.smartMode="INVESTIGATE_GROUP_INTENT"
            s.lastSharedIntentPathTick=tick
            safe("smart shared-intent path",function() z:pathToLocationF(intent.x,intent.y,intent.z or 0) end)
        end
        setSprint(z,s,false,"no-local-target")
        return
    end

    if FeralAI.canSeeTarget(z,target) then
        FeralGroups.reportPrey(z,target,tick)
    end

    local dx=target:getX()-z:getX()
    local dy=target:getY()-z:getY()
    local dist=math.sqrt(dx*dx+dy*dy)
    if dist>(Config.SmartFeralStalkGiveUpRadius or 55) and not grudgeActive then
        clearSmartPredatorState(s)
        setSprint(z,s,false,"target-lost")
        safe("smart clear far target",function() z:setTarget(nil) end)
        return
    end

    local now=worldAgeHours()

    if s.smartMode=="HIDE_HORDE" then
        setSprint(z,s,false,"hiding")
        if not s.smartHideBuilding or not s.smartHideUntilHours or not now or now>=s.smartHideUntilHours then
            log(string.format("SMART FERAL HIDE END @ %d,%d reason=timeout",math.floor(z:getX()),math.floor(z:getY())))
            s.smartMode="STALK"
            s.smartHideBuilding=nil
            s.smartHideUntilHours=nil
            s.smartHideSquare=nil
            return
        end

        -- Once the survivor commits to entering the horde building, the Smart
        -- Feral considers itself cornered and attacks instead of remaining hidden.
        if FeralAI.targetInsideBuilding(target,s.smartHideBuilding) then
            s.smartMode="AMBUSH"
            if reserveReady then setSprint(z,s,true,"AMBUSH") end
            stats.smartAmbushes=stats.smartAmbushes+1
            safe("smart ambush target",function() z:setTarget(target) end)
            safe("smart ambush path",function() z:pathToCharacter(target) end)
            log(string.format("SMART FERAL AMBUSH FROM HORDE @ %d,%d",math.floor(z:getX()),math.floor(z:getY())))
            return
        end

        -- Stay embedded with the horde rather than vanilla-chasing out of cover.
        safe("smart hide clear target",function() z:setTarget(nil) end)
        if s.smartHideSquare and tick-(s.smartLastPathTick or -999999)>=(Config.SmartFeralHideRepathTicks or 120) then
            safe("smart hide path",function()
                z:pathToLocationF(
                    s.smartHideSquare:getX()+0.5,
                    s.smartHideSquare:getY()+0.5,
                    s.smartHideSquare:getZ()
                )
            end)
            s.smartLastPathTick=tick
        end
        return
    end

    if s.smartMode=="AMBUSH" then
        if reserveReady then setSprint(z,s,true,"AMBUSH") end
        safe("smart ambush target maintain",function() z:setTarget(target) end)
        -- Once committed, vanilla chase/attack behavior owns combat.
        return
    end

    -- Close enough: stop theatrics and commit to the attack.
    if dist<=(Config.SmartFeralAmbushDistance or 5.0) then
        s.smartMode="AMBUSH"
        if reserveReady then setSprint(z,s,true,"AMBUSH") end
        stats.smartAmbushes=stats.smartAmbushes+1
        safe("smart close ambush target",function() z:setTarget(target) end)
        return
    end

    if tick-(s.smartLastPathTick or -999999)<(Config.SmartFeralStalkRepathTicks or 45) then
        return
    end
    s.smartLastPathTick=tick

    -- Prefer a sufficiently dense zombie-filled building when available.
    local building,hideSq,hordeCount,tileCount,density,minHorde,popMult=FeralAI.findHordeHideBuilding(z,target)
    if building and hideSq then
        setSprint(z,s,false,"hiding")
        local hours=FeralAI.randomHideHours()
        s.smartMode="HIDE_HORDE"
        s.smartHideBuilding=building
        s.smartHideSquare=hideSq
        s.smartHideUntilHours=(now or 0)+hours
        stats.smartHideEntries=stats.smartHideEntries+1
        safe("smart horde hide clear target",function() z:setTarget(nil) end)
        safe("smart horde hide path",function()
            z:pathToLocationF(hideSq:getX()+0.5,hideSq:getY()+0.5,hideSq:getZ())
        end)
        log(string.format(
            "SMART FERAL HIDE HORDE @ %d,%d horde=%d minHorde=%d popMult=%.2f tiles=%d density=%.3f duration=%.2fh",
            math.floor(z:getX()),math.floor(z:getY()),tonumber(hordeCount) or 0,
            tonumber(minHorde) or 0,tonumber(popMult) or 1.0,
            tonumber(tileCount) or 0,tonumber(density) or 0,hours
        ))
        return
    end

    -- Otherwise flank around the player. Prefer positions with broken LOS so
    -- the Smart Feral behaves like a stalker rather than a straight-line sprinter.
    local flank=FeralAI.chooseFlankSquare(z,target)
    if flank then
        s.smartMode="FLANK"
        if reserveReady then setSprint(z,s,true,"FLANK") end
        safe("smart stalk clear direct target",function() z:setTarget(nil) end)
        safe("smart flank path",function()
            z:pathToLocationF(flank:getX()+0.5,flank:getY()+0.5,flank:getZ())
        end)
        stats.smartFlankPaths=stats.smartFlankPaths+1
        stats.smartStalkPaths=stats.smartStalkPaths+1
    else
        s.smartMode="STALK"
        setSprint(z,s,false,"stalking")
    end
end

local function updateRegularFeral(z,s,daytime,exposedDLS)
    local reserveReady=FeralReserve.canSprintEntity(z)
    if daytime then
        local square=z:getSquare()
        local sheltered=square and (not square:isOutside()) and (tonumber(exposedDLS) or 0)<(Config.UVSlowMinimumExposure or 0.10)
        if sheltered then
            setSprint(z,s,false,"sheltered")
            return
        end
        if tick-(s.lastFeralShelterPathTick or -999999)>=(Config.RegularFeralShelterRepathTicks or 90) then
            local shelter=Shelter.findNearby(z)
            if shelter then
                safe("regular Feral seek shelter",function()
                    z:pathToLocationF(shelter:getX()+0.5,shelter:getY()+0.5,shelter:getZ())
                end)
                s.lastFeralShelterPathTick=tick
                if reserveReady then setSprint(z,s,true,"EVADE_TO_SHELTER") end
            else
                setSprint(z,s,false,"no-shelter")
            end
        end
        return
    end

    if tick<(tonumber(s.sprintUntilTick) or -999999) and reserveReady then
        setSprint(z,s,true,"AMBUSH")
        return
    end
    setSprint(z,s,false,"ordinary-pursuit")
    if tick<(tonumber(s.nextSprintDecisionTick) or -999999) or not reserveReady then return end
    s.nextSprintDecisionTick=tick+(Config.RegularFeralSprintCooldownTicks or 600)
    local target,dist=FeralAI.findNearestPlayer(z,Config.RegularFeralAmbushRadius or 8.0)
    if not target or not dist then return end
    local chance=tonumber(Config.RegularFeralAmbushSprintChance) or 0.12
    local roll=ZombRand and (ZombRand(10000)/10000.0) or math.random()
    if roll<=chance then
        s.sprintUntilTick=tick+(Config.RegularFeralSprintDurationTicks or 90)
        setSprint(z,s,true,"AMBUSH")
    end
end

local function updateFeralState(z,s,globalDLS,exposedDLS)
    -- Migration/safety: a high-cognition Feral from an older save promotes on
    -- its first active update even if it did not pass through the new rise code.
    maybePromoteSmartFeral(z,s,globalDLS,"active-feral")

    local daytime=isDaytimeForFeralLifecycle(globalDLS)
    if not s.smartFeral then
        updateRegularFeral(z,s,daytime,exposedDLS)
        return
    end

    -- Smart Ferals deliberately expose themselves to the strongest local
    -- natural sunlight during the day, then become tactical predators at night.
    if daytime then
        setSprint(z,s,false,"day-idle")
        if s.smartMode~="IDLE" then
            clearSmartPredatorState(s)
            safe("smart daytime clear target",function() z:setTarget(nil) end)
        end
        if tick-(s.lastSmartSunPathTick or -999999)>=(Config.SmartFeralSunRepathTicks or 90) then
            local moved,best,current=safe("smart feral seek sun",FeralAI.seekSun,z)
            s.lastSmartSunPathTick=tick
            if moved then
                local threat=select(1,FeralAI.findNearestPlayer(z,Config.SmartFeralEvasionThreatRadius or 12.0))
                s.smartMode=threat and "EVADE" or "IDLE"
                setSprint(z,s,threat~=nil and FeralReserve.canSprintEntity(z),"EVADE")
                stats.smartSunPaths=stats.smartSunPaths+1
                log(string.format(
                    "SMART FERAL SEEK SUN @ %d,%d exposure %.3f -> %.3f",
                    math.floor(z:getX()),math.floor(z:getY()),tonumber(current) or -1,tonumber(best) or -1
                ))
            end
        end
    else
        updateSmartFeralNight(z,s,globalDLS)
    end
end

local function updateZombie(z)
    if not z then return end
    if not MortisIntegration.canWriteCanonicalState(z) then return end
    local ready,recoveryReason,recovered,restoredType=MortisIntegration.recoverAssignment(z)
    if not ready then
        if Config.Diagnostic then recoveryLog(z,"assignment recovery",recoveryReason) end
        return
    end
    if FeralGroups and type(FeralGroups.observe)=="function" then
        safe("observe Feral group spatial index",FeralGroups.observe,z)
    end
    local s=getState(z)
    if recovered then
        -- Do not retain a phase inferred from an assignment that was compensated.
        s.phase="NORMAL";s.smartFeral=false;s.alphaFeral=false
        if restoredType==false then s.uvSlowed=false;s.sprintActive=false;s.sprintReason=nil end
        MortisIntegration.applyIdentityToState(z,s)
        if s.phase=="TRANSFORMING" then hibernating[z]=true else hibernating[z]=nil end
    end
    if s.phase=="FERAL" and Config.EnableFerals==false then
        disableFerals(z,s)
        return
    end
    -- Finish the durable healing transaction before exposure or sprint can
    -- replace its consumption receipt. A failed recovery must defer this
    -- entity's biological work, not spend or heal it a second time.
    local recovered,recoveryReason=safe("UV metabolism recovery",UVMetabolism.recover,z)
    if recovered~=true then
        setSprint(z,s,false,"metabolism-recovery")
        if Config.Diagnostic then log("UV metabolism recovery deferred: "..tostring(recoveryReason)) end
        return
    end
    local dt=elapsedGameMinutes(s)
    if dt>0 and Config.EnableRegionalUVTissue==true then
        local applied,result=safe("regional UV tissue",processRegionalUVTissue,z,dt)
        if applied==false and Config.Diagnostic then log("Regional UV tissue skipped: "..tostring(result)) end
        if applied and s.phase=="FERAL" and type(result)=="table" and type(result.diagnostics)=="table" then
            local tier=s.alphaFeral and "ALPHA_FERAL" or (s.smartFeral and "SMART_FERAL" or "FERAL")
            local tactical=s.sprintActive==true or s.smartMode=="AMBUSH" or s.smartMode=="FLANK"
                or s.smartMode=="EVADE" or s.currentAction=="CHASE"
            local intent={preserveForMovement=tactical,allowRedistribution=not tactical}
            local biologicalMinutes=math.min(dt,Config.RegionalUVTissueMaximumElapsedMinutes or dt)
            local healed,healResult=safe("regional UV regeneration",UVMetabolism.regenerate,
                z,tier,result.diagnostics,biologicalMinutes,intent)
            if healed~=true then
                setSprint(z,s,false,"metabolism-recovery")
                if Config.Diagnostic then log("Regional UV regeneration deferred: "..tostring(healResult)) end
                return
            end
            if s.alphaFeral and healResult and healResult.unchanged then
                local allocated,allocation=safe("Alpha UV allocation",UVMetabolism.redistribute,
                    z,tier,result.diagnostics,biologicalMinutes,intent)
                if allocated==false and Config.Diagnostic then
                    log("Alpha UV allocation deferred: "..tostring(allocation))
                end
            end
        end
    end
    maintainLockedTransformationVisual(z,s)
    local baseTier=(s.phase=="FERAL") and "fastShambler" or "shambler"
    safe("MORTIS Nightfall base speed",MortisIntegration.setNightfallBaseSpeed,z,baseTier)
    if s.phase=="TRANSFORMING" then enforceHibernationHealthFloor(z,s) end
    if isActuallyDead(z) then
        if s.phase=="TRANSFORMING" and not s.countedDeadWhileDown then
            s.countedDeadWhileDown=true
            if artificialUVIsActive(s) then
                stats.artificialUVDeaths=stats.artificialUVDeaths+1
                log("HIBERNATING ZOMBIE KILLED BY ARTIFICIAL UV")
            else
                stats.deadWhileDown=stats.deadWhileDown+1
                log("UNEXPECTED HIBERNATION DEATH -- natural health floor failed")
            end
        end
        return
    end
    if s.phase~="TRANSFORMING" then
        local anatomyOK=safe("active anatomy posture",MortisIntegration.enforceActiveAnatomy,z,s)
        if anatomyOK~=true then
            setSprint(z,s,false,"anatomy-unavailable")
            return
        end
    end
    local square=z:getSquare(); if not square then return end; stats.processed=stats.processed+1
    local globalDLS=safe("getDayLightStrength",SolarUV.getDayLightStrength); if globalDLS==nil then return end
    local exposedDLS,canopy=safe("getExposureAtSquare",SolarUV.getExposureAtSquare,square)
    if exposedDLS==nil then return end
    canopy=canopy or {score=0.0,modifier=1.0,trees=0}
    updateUVSlow(z,s,exposedDLS)

    local outside=square:isOutside()
    if s.wasOutside==nil then s.wasOutside=outside end

    if s.phase=="NORMAL" then
        -- A zombie that was outside and has now reached interior shelter gets a
        -- temporary hold before vanilla wandering is allowed to take over.
        if s.wasOutside and not outside then
            beginShelterHold(z,s,globalDLS)
        end
        s.wasOutside=outside

        if updateShelterHold(z,s) then
            return
        end
        if dt>0 then
            local rate=SolarUV.getPointRatePerMinute(exposedDLS)
            local regionalReady=regionalSunHibernationReady(z)
            if Config.EnableSunKnockdown~=false and regionalReady
                and LifecycleRules.canBeginSunHibernation(globalDLS,exposedDLS,rate,Config) then
                beginFeralization(z,s,globalDLS)
            end
        end
        if s.phase=="NORMAL" then
            local map=safe("buildWeightMap",UVAI.buildWeightMap,z,s,globalDLS,exposedDLS,tick,reserveEquivalent(z))
            if map then applyWeightAction(z,s,map,globalDLS); s.lastWeightMap=map end
        end
    elseif s.phase=="TRANSFORMING" then
        if Config.Diagnostic and s.playDeadEngaged and tick-s.lastDetailTick>=Config.DetailLogEveryTicks then
            local vanillaDead=false
            safe("diagnostic vanilla isDead",function() vanillaDead=z:isDead() end)
            local hp=getHealthSafe(z)
            if vanillaDead and hp and hp>0 then
                log(string.format(
                    "FAKE-DEAD STATUS @ %d,%d vanillaIsDead=true health=%.3f -- retained in lifecycle",
                    math.floor(z:getX()),math.floor(z:getY()),hp
                ))
            end
        end
        maintainTransformingState(z,s,globalDLS)
    elseif s.phase=="FERAL" then
        local feralRate=SolarUV.getPointRatePerMinute(exposedDLS)
        local regionalReady=regionalSunHibernationReady(z)
        if Config.EnableSunKnockdown~=false and regionalReady
            and LifecycleRules.canBeginSunHibernation(globalDLS,exposedDLS,feralRate,Config) then
            enterRegularFeralDayDormancy(z,s,exposedDLS)
            return
        end
        updateFeralState(z,s,globalDLS,exposedDLS)
        drainSprintReserve(z,s,dt)
    end

    -- Vanilla owns ordinary nocturnal activity. Nightfall's only generic
    -- nighttime navigation intervention is one bounded request per night for
    -- a relevant indoor zombie to roam toward a loaded outdoor square.
    if s.phase~="TRANSFORMING" and Config.EnableNightIndoorExit~=false then
        local nightStrength=getNightStrength()
        local moved=safe("night indoor exit",NightTransition.requestIndoorExit,z,s,{
            enabled=true,nightStrength=nightStrength,threshold=Config.RiseAtOrAboveNightStrength,
            worldHours=worldAgeHours(),tick=tick,
            cell=getCell and getCell() or nil,
            radius=Config.NightIndoorExitSearchRadius,
            retryTicks=Config.NightIndoorExitRetryTicks,
        })
        if moved==true then stats.nightExitPaths=stats.nightExitPaths+1 end
    end

    if Config.Diagnostic
        and detailLogsThisUpdate < (tonumber(Config.DetailLogSamplesPerUpdate) or 3)
        and tick-s.lastDetailTick>=Config.DetailLogEveryTicks then
        detailLogsThisUpdate=detailLogsThisUpdate+1
        s.lastDetailTick=tick
        local tier=SolarUV.getTier(globalDLS); local mult=SolarUV.getMultiplier(globalDLS); local rate=SolarUV.getPointRatePerMinute(exposedDLS)
        local map=s.lastWeightMap
        if map then
            log(string.format("Zombie sample @ %d,%d outside=%s phase=%s action=%s globalDLS=%.3f exposedDLS=%.3f tier=%s mult=%.2f rate=%.3f/min points=%.2f cogRaw=%d cogEff=%.2f impair=%.2f strengthImp=%.2f memoryImp=%.2f weights[N=%.1f C=%.1f S=%.1f R=%.1f Stay=%.1f Obs=%.1f Int=%.1f] dist=%.1f prox=%.1f bleed=%s/+%.1f canopy=%.2fx trees=%d",
                math.floor(z:getX()),math.floor(z:getY()),tostring(square:isOutside()),s.phase,tostring(s.currentAction),globalDLS,exposedDLS,tier,mult,rate,reserveEquivalent(z),
                map.rawCognition,map.cognition,map.impairment.combined,map.impairment.strength,map.impairment.memory,
                map.perceived.NORMAL,map.perceived.CHASE,map.perceived.SEEK_SHELTER,map.perceived.RETREAT,map.perceived.STAY_SHELTERED,
                map.perceived.OBSERVE_FROM_SHELTER or 0,map.perceived.INVESTIGATE_INTEREST or 0,
                map.targetDistance or -1,map.proximityBonus or 0,
                tostring(map.bleedingSeverity or "None"),map.bleedingBonus or 0,
                canopy.modifier or 1.0,canopy.trees or 0))
        else
            log(string.format("Zombie sample @ %d,%d outside=%s phase=%s globalDLS=%.3f exposedDLS=%.3f tier=%s mult=%.2f rate=%.3f/min points=%.2f",
                math.floor(z:getX()),math.floor(z:getY()),tostring(square:isOutside()),s.phase,globalDLS,exposedDLS,tier,mult,rate,reserveEquivalent(z)))
        end
    end
end

local function scanCellBudget(limit)
    if initialScanComplete then return 0 end
    local cell=getCell and getCell() or nil; if not cell then return end
    local list=safe("cell:getZombieList",function() return cell:getZombieList() end); if not list then return end
    local size=safe("zombieList:size",function() return list:size() end); if size==nil then return end
    size=math.max(0,math.floor(tonumber(size) or 0))
    local added,processed=0,0
    limit=math.max(1,math.floor(tonumber(limit) or 32))
    while initialScanIndex<size and processed<limit do
        local index=initialScanIndex
        initialScanIndex=initialScanIndex+1
        processed=processed+1
        local z=safe("zombieList:get",function() return list:get(index) end)
        if z then
            if ZombieUV.track(z,"bounded-initial-scan") then added=added+1 end
            enqueueRelevant(z)
        end
    end
    if initialScanIndex>=size then initialScanComplete=true end
    if Config.Diagnostic and added>0 then
        log("Bounded cell discovery: processed="..processed.." list="..size.." newlyTracked="..added.." totalTracked="..countTracked())
    end
    return processed
end

local function persistState(z)
    local s=tracked[z]
    if not s or not z or not z.getModData then return end
    if not MortisIntegration.canWriteCanonicalState(z) then return end
    StatePersistence.save(z:getModData(),s)
end

local function runTick()
    if not Config.Enabled then return end; tick=tick+1
    -- One bounded discovery pass catches zombies that were already loaded when
    -- Lua initialized. Ongoing relevance comes from engine create/update hooks.
    if MortisIntegration.canWriteCanonicalState() then
        safe("bounded initial cell discovery",scanCellBudget,tonumber(Config.InitialDiscoveryBudgetPerTick) or 32)
        detailLogsThisUpdate=0
        local budget=math.max(1,math.floor(tonumber(Config.RelevantZombieBudgetPerTick) or 32))
        local processed=0
        while processed<budget do
            local z=popRelevant(); if not z then break end
            local s=getState(z)
            if tick-(tonumber(s.lastLifecycleUpdateTick) or -999999)>=math.max(1,tonumber(Config.UpdateEveryTicks) or 20) then
                s.lastLifecycleUpdateTick=tick
                safe("update relevant zombie",updateZombie,z)
                safe("persist relevant lifecycle state",persistState,z)
            end
            processed=processed+1
        end

        -- Fake-dead zombies may stop producing normal update events. At night,
        -- walk only the dedicated hibernator set and cap work every frame.
        local nightStrength=getNightStrength()
        if nightStrength and nightStrength>=(tonumber(Config.RiseAtOrAboveNightStrength) or 0.60) then
            local riseBudget=math.max(1,math.floor(tonumber(Config.NightRiseBudgetPerTick) or 8))
            local visited=0
            while visited<riseBudget do
                local z=nextHibernator(hibernationCursor)
                if not z then hibernationCursor=nil; break end
                hibernationCursor=z
                visited=visited+1
                local s=tracked[z]
                if s and s.phase=="TRANSFORMING" then
                    s.lastLifecycleUpdateTick=tick
                    safe("update night hibernator",updateZombie,z)
                    safe("persist night hibernator",persistState,z)
                    if hibernating[z]==nil then hibernationCursor=nil end
                else
                    hibernating[z]=nil
                    hibernationCursor=nil
                end
            end
        else
            hibernationCursor=nil
        end

        if FeralGroups and type(FeralGroups.update)=="function" then
            safe("updateFeralGroups",FeralGroups.update,tracked,tick)
        end
    end
    Observation.prune(tick)
    if Config.Diagnostic and tick%Config.HeartbeatEveryTicks==0 then
        -- Diagnostics are observational only and must never break gameplay.
        local function n(v, fallback)
            v=tonumber(v)
            if v==nil then return fallback or 0 end
            return v
        end

        local dls=n(safe("heartbeat DLS",SolarUV.getDayLightStrength),-1)
        local night=n(getNightStrength(),-1)
        local gt=getGameTime and getGameTime() or nil
        local tod=-1
        if gt then
            tod=n(safe("heartbeat time",function() return gt:getTimeOfDay() end),-1)
        end

        local tier=safe("heartbeat tier",function() return SolarUV.getTier(dls) end)
        tier=tier==nil and "Unknown" or tostring(tier)
        local rate=n(safe("heartbeat rate",function() return SolarUV.getPointRatePerMinute(dls) end),0)

        log(string.format("HEARTBEAT tick=%d tracked=%d created=%d zombieUpdateEvents=%d processed=%d feralizations=%d rises=%d unexpectedDownDeaths=%d artificialUVDeaths=%d floorRestores=%d errors=%d shelterPaths=%d shelterHoldBegin=%d shelterHoldEnd=%d seek=%d stay=%d chase=%d normal=%d observe=%d interest=%d obsPaths=%d intPaths=%d signals=%d crawlAllow=%d crawlBlock=%d smartPromotions=%d dayDormancies=%d smartSunPaths=%d smartStalk=%d smartFlank=%d smartHide=%d smartAmbush=%d time=%.2f DLS=%.3f night=%.3f tier=%s rate=%.3f/min",
            n(tick),n(countTracked()),n(stats.created),n(stats.updateEvents),n(stats.processed),
            n(stats.feralizations),n(stats.rises),n(stats.deadWhileDown),n(stats.artificialUVDeaths),n(stats.naturalFloorRestores),n(stats.errors),
            n(stats.shelterPaths),n(stats.shelterHoldBegins),n(stats.shelterHoldEnds),n(stats.seekWins),n(stats.staySheltered),n(stats.chaseWins),n(stats.normalWins),
            n(stats.observeWins),n(stats.interestWins),n(stats.observationPaths),n(stats.interestPaths),
            n(stats.signalsEmitted),n(stats.transformCrawlAllows),n(stats.transformCrawlBlocks),
            n(stats.smartPromotions),n(stats.feralDayDormancies),n(stats.smartSunPaths),
            n(stats.smartStalkPaths),n(stats.smartFlankPaths),n(stats.smartHideEntries),n(stats.smartAmbushes),
            tod,dls,night,tier,rate))
    end
end
local function onTick() safe("OnTick callback",runTick) end
local function onZombieCreate(z)
    safe("OnZombieCreate callback",function()
        stats.created=stats.created+1
        ZombieUV.track(z,"OnZombieCreate")
        if MortisIntegration.canWriteCanonicalState(z) then enqueueRelevant(z) end
    end)
end
local function onZombieUpdate(z)
    safe("OnZombieUpdate callback",function()
        stats.updateEvents=stats.updateEvents+1
        ZombieUV.track(z,"OnZombieUpdate")
        if MortisIntegration.canWriteCanonicalState(z) then enqueueRelevant(z) end
    end)
end

local function onZombieDead(z)
    safe("OnZombieDead callback",function()
        local s=z and tracked[z]or nil
        if not s or s.phase~="TRANSFORMING"or s.countedDeadWhileDown then return end
        s.countedDeadWhileDown=true
        if artificialUVIsActive(s)then
            stats.artificialUVDeaths=stats.artificialUVDeaths+1
            log("HIBERNATING ZOMBIE KILLED BY ARTIFICIAL UV")
        else
            stats.deadWhileDown=stats.deadWhileDown+1
            local x=safe("hibernation death x",function()return math.floor(z:getX())end)or-1
            local y=safe("hibernation death y",function()return math.floor(z:getY())end)or-1
            log(string.format("UNEXPECTED HIBERNATION DEATH EVENT @ %d,%d",x,y))
        end
        hibernating[z]=nil
        if hibernationCursor==z then hibernationCursor=nil end
    end)
end

function ZombieUV.getDiagnosticStats()
    local result={tracked=countTracked(),tick=tick}
    for key,value in pairs(stats) do result[key]=value end
    return result
end

if type(isDebugEnabled)~="function" or isDebugEnabled()==true then
    function PNTestStatus()
        local s=ZombieUV.getDiagnosticStats()
        print(string.format(
            "[ProjectNightfall][Test] tick=%d tracked=%d created=%d processed=%d feralizations=%d rises=%d artificialUVDeaths=%d unexpectedDownDeaths=%d errors=%d",
            tonumber(s.tick) or 0,tonumber(s.tracked) or 0,tonumber(s.created) or 0,tonumber(s.processed) or 0,
            tonumber(s.feralizations) or 0,tonumber(s.rises) or 0,tonumber(s.artificialUVDeaths) or 0,
            tonumber(s.deadWhileDown) or 0,tonumber(s.errors) or 0
        ))
        return s
    end
end
local function runHitZombie(z,wielder,bodyPart,weapon)
    if not z or not wielder then return end
    if not MortisIntegration.canWriteCanonicalState(z) then return end
    local s=getState(z)
    MortisIntegration.applyIdentityToState(z,s)
    if not s.smartFeral then return end

    local key=nil
    for i=0,3 do
        local player=getSpecificPlayer and safe("getSpecificPlayer for grudge",getSpecificPlayer,i) or nil
        if player==wielder then
            key=FeralAI.playerKey(player)
            break
        end
    end
    if not key then return end

    s.grudgeTarget=wielder
    s.grudgeKey=key
    s.smartTarget=wielder
    s.smartMode="AMBUSH"
    persistGrudge(z,s)
    safe("Smart Feral grudge aggro",function()
        if z.addAggro then z:addAggro(wielder,tonumber(Config.SmartFeralGrudgeAcquireAggro) or 100) end
    end)
    log("SMART FERAL GRUDGE ACQUIRED target="..tostring(key))
end
local function onHitZombie(z,wielder,bodyPart,weapon)
    safe("OnHitZombie callback",runHitZombie,z,wielder,bodyPart,weapon)
end
local function runGameStart()
    log("OnGameStart fired; UV Weight AI + Feralization diagnostics active")
    safe("dependency diagnostics",ProjectNightfall.DependencyDiagnostics.report,
        rawget(_G,"lightWorks"),rawget(_G,"B47ANCEDPower"),rawget(_G,"Mortis"),rawget(_G,"medWorks"),rawget(_G,"B47ANCEDKnowledgeAndWisdom"))
    initialScanIndex=0
    initialScanComplete=false
    if MortisIntegration.canWriteCanonicalState() then
        safe("initial bounded cell discovery",scanCellBudget,tonumber(Config.InitialDiscoveryBudgetPerTick) or 32)
    end
    local activeOnly=SandboxVars and SandboxVars.ZombieLore and tonumber(SandboxVars.ZombieLore.ActiveOnly) or nil
    if activeOnly==3 then
        local message="Nightfall detected day-active zombies. Project Daybreak is the intended inverted experience; Nightfall UV rules remain unchanged."
        print("[ProjectNightfall] WARNING: "..message)
        safe("day-active sandbox player notice",function()
            local player=getSpecificPlayer and getSpecificPlayer(0) or nil
            if player and HaloTextHelper and HaloTextHelper.addBadText then
                HaloTextHelper.addBadText(player,message)
            end
        end)
    end
end
local function onGameStart() safe("OnGameStart callback",runGameStart) end
Events.OnZombieCreate.Add(onZombieCreate); Events.OnZombieUpdate.Add(onZombieUpdate); Events.OnTick.Add(onTick); Events.OnGameStart.Add(onGameStart)
if Events.OnZombieDead then Events.OnZombieDead.Add(onZombieDead) end
if Events.OnHitZombie then Events.OnHitZombie.Add(onHitZombie) end
log(tostring(ProjectNightfall.VERSION).." loaded: Alpha hierarchy development runtime")
