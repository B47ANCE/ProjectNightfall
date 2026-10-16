ProjectNightfall = ProjectNightfall or {}

local NaturalUVHealth = {}

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function clamp(value,minimum,maximum)
    return math.max(minimum,math.min(maximum,value))
end

function NaturalUVHealth.floor(config)
    return clamp(finite(config and config.NaturalUVHealthFloor) or 0.50,0.01,1.0)
end

ProjectNightfall.NaturalUVHealth=NaturalUVHealth
return NaturalUVHealth
