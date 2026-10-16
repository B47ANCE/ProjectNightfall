require "ProjectNightfall/PN_Config"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.TargetStimulus = ProjectNightfall.TargetStimulus or {}

local TargetStimulus = ProjectNightfall.TargetStimulus
local Config = ProjectNightfall.Config.POC

local function getBleedingCount(target)
    if not target then return 0 end
    local ok,body=pcall(function() return target:getBodyDamage() end)
    if not ok or not body then return 0 end
    local ok2,count=pcall(function() return body:getNumPartsBleeding() end)
    if not ok2 or count==nil then return 0 end
    return tonumber(count) or 0
end

function TargetStimulus.getBleedingSeverity(target)
    local count=getBleedingCount(target)
    if count<=0 then return "None",0 end
    if count==1 then return "Light",1 end
    if count==2 then return "Moderate",2 end
    if count<=4 then return "Heavy",3 end
    return "Severe",4
end

local function baseBonus(level)
    if level==1 then return Config.TargetBleedingLightBonus end
    if level==2 then return Config.TargetBleedingModerateBonus end
    if level==3 then return Config.TargetBleedingHeavyBonus end
    if level>=4 then return Config.TargetBleedingSevereBonus end
    return 0.0
end

function TargetStimulus.getBleedingChaseBonus(target,isFeral)
    if not Config.EnableTargetBleedingModifier then return 0.0,"None",0 end
    local label,level=TargetStimulus.getBleedingSeverity(target)
    local sensitivity=isFeral and Config.TargetBleedingFeralSensitivity
        or Config.TargetBleedingRegularSensitivity
    return baseBonus(level)*sensitivity,label,level
end
