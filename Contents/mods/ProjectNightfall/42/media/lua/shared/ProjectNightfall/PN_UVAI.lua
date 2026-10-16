require "ProjectNightfall/PN_Config"
require "ProjectNightfall/PN_SolarUV"
require "ProjectNightfall/PN_Observation"
require "ProjectNightfall/PN_TargetStimulus"
require "ProjectNightfall/PN_MortisIntegration"
require "ProjectNightfall/PN_Effigies"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.UVAI = ProjectNightfall.UVAI or {}

local UVAI = ProjectNightfall.UVAI
local SolarUV = ProjectNightfall.SolarUV
local Observation = ProjectNightfall.Observation
local TargetStimulus = ProjectNightfall.TargetStimulus
local MortisIntegration = ProjectNightfall.MortisIntegration
local Effigies = ProjectNightfall.Effigies
local Config = ProjectNightfall.Config.POC

local function clamp(v,lo,hi) if v<lo then return lo elseif v>hi then return hi else return v end end
local function rand01() if ZombRand then return ZombRand(0,10001)/10000.0 end return 0.5 end
local function distance(a,b)
    if not a or not b then return math.huge end
    local dx=a:getX()-b:getX(); local dy=a:getY()-b:getY()
    return math.sqrt(dx*dx+dy*dy)
end

function UVAI.getBaseCognition01()
    local raw=3
    if SandboxVars and SandboxVars.ZombieLore and SandboxVars.ZombieLore.Cognition then
        raw=tonumber(SandboxVars.ZombieLore.Cognition) or 3
    end
    if raw<=1 then return 1.00,raw end
    if raw==2 then return 0.62,raw end
    return 0.28,raw
end

function UVAI.computeImpairment(dls,storedUVEquivalent)
    dls=tonumber(dls) or 0
    storedUVEquivalent=tonumber(storedUVEquivalent) or 0
    local mult=SolarUV.getMultiplier(dls)
    local currentSeverity=clamp((dls*mult)/4.0,0.0,1.0)
    local burden=clamp(storedUVEquivalent/Config.FeralizationThreshold,0.0,1.0)
    local combined=clamp(currentSeverity*Config.CurrentExposureImpairmentShare+
        burden*Config.AccumulatedBurdenImpairmentShare,0.0,1.0)
    return {
        currentSeverity=currentSeverity, burden=burden, combined=combined,
        cognition=combined*Config.MaxCognitionImpairment,
        memory=combined*Config.MaxMemoryImpairment,
        strength=combined*Config.MaxStrengthImpairment,
    }
end

function UVAI.getEffectiveCognition01(dls,storedUVEquivalent)
    local base,raw=UVAI.getBaseCognition01()
    local imp=UVAI.computeImpairment(dls,storedUVEquivalent)
    return clamp(base*(1.0-imp.cognition),0.02,1.0),base,raw,imp
end

local function perceivedWeight(actual,cognition)
    local errorScale=(1.0-cognition)*Config.WeightNoiseMax
    local noise=(rand01()*2.0-1.0)*errorScale
    return math.max(0.0,actual+noise)
end

local proximityCurve={{20,0},{15,5},{10,10},{7,15},{5,25},{3,40},{2,55},{1,75}}
function UVAI.getProximityBonus(d)
    d=tonumber(d) or math.huge
    if d>=20 then return 0 end
    if d<=1 then return 75 end
    for i=1,#proximityCurve-1 do
        local d1,w1=proximityCurve[i][1],proximityCurve[i][2]
        local d2,w2=proximityCurve[i+1][1],proximityCurve[i+1][2]
        if d<=d1 and d>=d2 then
            local t=(d1-d)/(d1-d2)
            return w1+(w2-w1)*t
        end
    end
    return 0
end

function UVAI.buildWeightMap(zombie,state,globalDLS,exposedDLS,tick,storedUVEquivalent)
    if not zombie then return nil,"zombie required" end
    state=type(state)=="table" and state or {}
    -- uvPoints is accepted only as a transitional third-party caller alias.
    -- Canonical Nightfall runtime passes an anatomy-derived equivalent.
    storedUVEquivalent=tonumber(storedUVEquivalent) or tonumber(state.uvPoints) or 0
    globalDLS=tonumber(globalDLS) or 0
    exposedDLS=tonumber(exposedDLS) or 0
    tick=tonumber(tick) or 0
    local cognition,baseCognition,rawCognition,imp=UVAI.getEffectiveCognition01(exposedDLS,storedUVEquivalent)
    local burden,severity=imp.burden,imp.currentSeverity
    local square=zombie:getSquare()
    local outside=square and square:isOutside() or false

    local visible=false; local target=nil
    pcall(function() visible=zombie:isTargetVisible() end)
    pcall(function() target=zombie:getTarget() end)
    local hasVisibleTarget=visible and target~=nil
    local targetOutside=false
    if target then pcall(function() targetOutside=target:getSquare() and target:getSquare():isOutside() or false end) end
    local targetDistance=hasVisibleTarget and distance(zombie,target) or math.huge
    local proximityBonus=hasVisibleTarget and UVAI.getProximityBonus(targetDistance) or 0.0
    local isFeral=state.phase=="FERAL"
    local chaseAlreadyActive=state.currentAction=="CHASE"
    local hungerThreshold=chaseAlreadyActive and Config.HungerChaseKeepThreshold
        or Config.HungerChaseStartThreshold
    local hungerDrive,hungerLevel=MortisIntegration.getHungerDrive(zombie,hungerThreshold)
    local hungerBonus=hungerDrive*(chaseAlreadyActive and Config.HungerChaseKeepBonus
        or Config.HungerChaseStartBonus)
    local bleedingBonus,bleedingSeverity,bleedingLevel=0.0,"None",0
    if hasVisibleTarget then
        bleedingBonus,bleedingSeverity,bleedingLevel=
            TargetStimulus.getBleedingChaseBonus(target,isFeral)
    end

    local nearbySignal,signalDistanceSq=Observation.findNearbySignal(zombie,tick)
    local signalDistance=signalDistanceSq and math.sqrt(signalDistanceSq) or math.huge
    local effigy,effigyReaction,effigyDistanceSq=Effigies.findNearbyReaction(
        zombie,Config.EffigyInfluenceRadius,Config)
    local effigyDistance=effigyDistanceSq and math.sqrt(effigyDistanceSq) or math.huge
    local effigyFactor=effigy and clamp(1-effigyDistance/math.max(1,Config.EffigyInfluenceRadius),0,1) or 0

    local actual={}
    actual.NORMAL=35.0+(1.0-burden)*25.0+(1.0-severity)*15.0
    actual.CHASE=hasVisibleTarget and (82.0+(1.0-burden)*12.0+proximityBonus+bleedingBonus+hungerBonus) or 0.0
    actual.SEEK_SHELTER=outside and (severity*55.0+burden*65.0+cognition*18.0) or 0.0
    actual.RETREAT=(outside and hasVisibleTarget) and (severity*42.0+burden*72.0+cognition*24.0) or 0.0
    actual.STAY_SHELTERED=(not outside) and (globalDLS*42.0+burden*74.0+cognition*24.0) or 0.0

    local tooFar=targetDistance>=10.0
    actual.OBSERVE_FROM_SHELTER=(not outside and hasVisibleTarget and targetOutside) and
        (Config.ObserveBaseWeight+Config.ObserveVisibleTargetBonus+
         (tooFar and Config.ObserveTooFarBonus or 0.0)+Config.ObserveShelterSafetyBonus+
         cognition*18.0) or 0.0

    actual.INVESTIGATE_INTEREST=0.0
    if not outside and nearbySignal and not hasVisibleTarget then
        local distanceFactor=clamp(1.0-signalDistance/Config.InterestSignalRadius,0.0,1.0)
        actual.INVESTIGATE_INTEREST=Config.InterestBaseWeight+
            cognition*Config.InterestCognitionWeight+
            distanceFactor*Config.InterestDistanceWeight
    end
    actual.AVOID_EFFIGY=(effigyReaction and effigyReaction.action=="avoid") and
        (Config.EffigyAvoidWeight+effigyFactor*35) or 0
    actual.DESTROY_EFFIGY=(effigyReaction and effigyReaction.action=="destroy_search") and
        (Config.EffigyDestroyWeight+effigyFactor*35) or 0

    local perceived={}
    for k,v in pairs(actual) do perceived[k]=perceivedWeight(v,cognition) end

    local winner,winnerWeight="NORMAL",perceived.NORMAL
    for k,v in pairs(perceived) do if v>winnerWeight then winner,winnerWeight=k,v end end
    if winner=="RETREAT" then winner="SEEK_SHELTER" end
    if winnerWeight<Config.MinimumOverrideWeight then winner="NORMAL" end

    return {
        action=winner,winnerWeight=winnerWeight,actual=actual,perceived=perceived,
        cognition=cognition,baseCognition=baseCognition,rawCognition=rawCognition,
        impairment=imp,hasVisibleTarget=hasVisibleTarget,target=target,targetOutside=targetOutside,
        targetDistance=targetDistance,proximityBonus=proximityBonus,
        nearbySignal=nearbySignal,signalDistance=signalDistance,
        bleedingBonus=bleedingBonus,bleedingSeverity=bleedingSeverity,
        bleedingLevel=bleedingLevel,
        hungerLevel=hungerLevel,hungerDrive=hungerDrive,hungerBonus=hungerBonus,
        hungerChasePhase=chaseAlreadyActive and "keep" or "start",
        effigy=effigy,effigyReaction=effigyReaction,effigyDistance=effigyDistance,
    }
end
