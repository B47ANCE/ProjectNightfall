require "ProjectNightfall/PN_Config"
require "lightWorks/lightWorks_UV"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.Canopy = ProjectNightfall.Canopy or {}

local Canopy = ProjectNightfall.Canopy
local Config = ProjectNightfall.Config.POC
local cache = setmetatable({}, { __mode = "k" })
local CACHE_TICKS = 300
local fallbackTick = 0

local function call(object, method, ...)
    if not object then return nil end
    local ok, fn = pcall(function() return object[method] end)
    if not ok or type(fn) ~= "function" then return nil end
    local called, value = pcall(fn, object, ...)
    if not called then return nil end
    return value
end

local function nowTick()
    local manager = rawget(_G, "getGameTime") and getGameTime() or nil
    local age = call(manager, "getWorldAgeHours")
    if age then return math.floor(age * 3600) end
    fallbackTick = fallbackTick + 1
    return fallbackTick
end

local function treeSize(tree)
    return math.max(1, tonumber(call(tree, "getSize")) or 1)
end

function Canopy.getLocalCanopy(square)
    if not square or Config.EnableCanopyAttenuation == false then
        return { score = 0, modifier = 1, trees = 0 }
    end
    local tick = nowTick()
    local cached = cache[square]
    if cached and tick - cached.tick < CACHE_TICKS then return cached.value end

    local cell = rawget(_G, "getCell") and getCell() or nil
    local sx, sy, sz = call(square, "getX"), call(square, "getY"), call(square, "getZ")
    if not cell or sx == nil or sy == nil then return { score = 0, modifier = 1, trees = 0 } end

    local radius = math.max(0, math.floor(tonumber(Config.CanopyScanRadius) or 4))
    local sizeWeight = math.max(0, tonumber(Config.CanopyTreeSizeWeight) or 1)
    local falloff = math.max(0, tonumber(Config.CanopyDistanceFalloff) or 0.7)
    local score, trees = 0, 0
    for dy = -radius, radius do
        for dx = -radius, radius do
            local distanceSquared = dx * dx + dy * dy
            if distanceSquared <= radius * radius then
                local candidate = call(cell, "getGridSquare", sx + dx, sy + dy, sz or 0)
                local tree = call(candidate, "getTree")
                if tree then
                    trees = trees + 1
                    local distance = math.sqrt(distanceSquared)
                    score = score + treeSize(tree) * sizeWeight * (falloff ^ distance)
                end
            end
        end
    end

    local threshold = math.max(0.01, tonumber(Config.CanopyScoreForMaxAttenuation) or 28)
    local maximum = math.max(0, math.min(1, tonumber(Config.CanopyMaxAttenuation) or 0.8))
    local modifier = 1 - maximum * math.min(1, score / threshold)
    local result = { score = score, modifier = modifier, trees = trees }
    cache[square] = { tick = tick, value = result }
    return result
end

function Canopy.getLocalCanopySafe(square)
    return Canopy.getLocalCanopy(square)
end

function Canopy.clearCache()
    cache = setmetatable({}, { __mode = "k" })
end

lightWorks.UV.registerExposureModifier("ProjectNightfall.Canopy", function(_entity, square, raw)
    if raw <= 0 or not square then return 1 end
    return Canopy.getLocalCanopySafe(square).modifier
end)

return Canopy
