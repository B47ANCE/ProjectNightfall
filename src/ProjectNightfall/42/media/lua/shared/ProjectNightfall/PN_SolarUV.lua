require "ProjectNightfall/PN_Config"
require "lightWorks/lightWorks_UV"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.SolarUV = ProjectNightfall.SolarUV or {}

local SolarUV = ProjectNightfall.SolarUV
local Config = ProjectNightfall.Config.POC
local LightUV = lightWorks.UV

local function finite(value, fallback)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return fallback or 0 end
    return value
end

local function normalizedDLS(value)
    value=finite(value,0)
    if value<0 then return 0 elseif value>1 then return 1 end
    return value
end

function SolarUV.getDayLightStrength()
    return LightUV.getDayLightStrength()
end

function SolarUV.getTier(dls)
    dls=normalizedDLS(dls)
    if dls <= Config.RecoveryMaxDLS then return "Recovery" end
    if dls <= Config.NegligibleMaxDLS then return "Negligible" end
    if dls <= Config.LowMaxDLS then return "Low" end
    if dls <= Config.ModerateMaxDLS then return "Moderate" end
    if dls <= Config.HighMaxDLS then return "High" end
    if dls <= Config.VeryHighMaxDLS then return "Very High" end
    return "Extreme"
end

-- Continuous multiplier inside the three upper tiers:
-- High      (>0.50-0.70): 1.1x -> 2.0x
-- Very High (>0.70-0.90): 2.1x -> 3.0x
-- Extreme   (>0.90-1.00): 3.1x -> 4.0x
local function lerp(a, b, t)
    if t < 0 then t = 0 elseif t > 1 then t = 1 end
    return a + (b - a) * t
end

function SolarUV.getMultiplier(dls)
    dls=normalizedDLS(dls)
    if dls <= Config.ModerateMaxDLS then
        return 1.0
    elseif dls <= Config.HighMaxDLS then
        local t = (dls - Config.ModerateMaxDLS) / (Config.HighMaxDLS - Config.ModerateMaxDLS)
        return lerp(1.1, 2.0, t)
    elseif dls <= Config.VeryHighMaxDLS then
        local t = (dls - Config.HighMaxDLS) / (Config.VeryHighMaxDLS - Config.HighMaxDLS)
        return lerp(2.1, 3.0, t)
    else
        local t = (dls - Config.VeryHighMaxDLS) / (1.0 - Config.VeryHighMaxDLS)
        return lerp(3.1, 4.0, t)
    end
end

function SolarUV.getPointRatePerMinute(dls)
    dls=normalizedDLS(dls)
    if dls <= Config.RecoveryMaxDLS then
        return Config.RecoveryPointsPerMinute
    end
    if dls <= Config.NegligibleMaxDLS then
        return 0.0
    end
    return dls * SolarUV.getMultiplier(dls)
end

-- POC spatial rule: outside squares receive the climate DLS signal;
-- indoor squares receive no solar accumulation and instead recover.
-- More nuanced sky/window/overhang occlusion comes after lifecycle proof.
function SolarUV.getExposureAtSquare(square)
    if not square or type(LightUV.getSunlightExposure)~="function" then
        return 0,{score=0,modifier=0,trees=0,error="sunlight exposure unavailable"}
    end
    local ok,exposure=pcall(LightUV.getSunlightExposure,square)
    if not ok or type(exposure)~="table" then
        return 0,{score=0,modifier=0,trees=0,error="sunlight exposure failed"}
    end
    local context=type(exposure.context)=="table" and exposure.context or {}
    local uv=type(exposure.uv)=="table" and exposure.uv or {}
    local natural=math.max(0,finite(uv.natural,0))
    local modifier=finite(context.modifier,1)
    if modifier<0 then modifier=0 elseif modifier>1 then modifier=1 end
    return natural, {
        score=1-modifier,
        modifier=modifier,
        trees=0,
        lightworks=exposure,
    }
end
