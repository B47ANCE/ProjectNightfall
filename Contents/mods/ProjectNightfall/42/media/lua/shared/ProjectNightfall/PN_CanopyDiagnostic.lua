require "ProjectNightfall/PN_Config"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.CanopyDiagnostic = ProjectNightfall.CanopyDiagnostic or {}

local Diagnostic = ProjectNightfall.CanopyDiagnostic
local Config = ProjectNightfall.Config.POC

local tick = 0
local lastZoneKey = nil
local seenObjectNames = {}
local seenTreeKeys = {}

local function log(msg)
    print("[ProjectNightfall]["..tostring(ProjectNightfall.VERSION or "unknown").."][CanopyDiag] " .. tostring(msg))
end

local function getPlayer0()
    if getSpecificPlayer then
        return getSpecificPlayer(0)
    end
    if getPlayer then
        return getPlayer()
    end
    return nil
end

local function zoneInfo(square)
    if not square then
        return "zoneType=nil zone.type=nil zone.name=nil"
    end

    local zoneType = nil
    local zone = nil
    local zType = nil
    local zName = nil

    -- These are direct Lua-facing world APIs; no reflection or property probing.
    if square.getZoneType then
        zoneType = square:getZoneType()
    end
    if square.getZone then
        zone = square:getZone()
    end
    if zone then
        if zone.getType then zType = zone:getType() end
        if zone.getName then zName = zone:getName() end
    end

    return string.format(
        "zoneType=%s zone.type=%s zone.name=%s",
        tostring(zoneType), tostring(zType), tostring(zName)
    )
end

local function inspectObject(obj, square)
    if not obj then return end

    -- Intentionally minimal: only documented IsoObject-facing identifiers.
    local objectName = nil
    local spriteName = nil

    if obj.getObjectName then
        objectName = obj:getObjectName()
    end
    if obj.getSpriteName then
        spriteName = obj:getSpriteName()
    end

    -- Record newly observed object-name values once. This helps confirm the
    -- literal returned for trees without flooding the log.
    local nameKey = tostring(objectName)
    if not seenObjectNames[nameKey] then
        seenObjectNames[nameKey] = true
        log(string.format(
            "OBJECT-NAME-SEEN objectName=%s sampleSprite=%s @ %d,%d,%d",
            tostring(objectName), tostring(spriteName),
            square:getX(), square:getY(), square:getZ()
        ))
    end

    -- Only after the runtime tells us the object calls itself "Tree" do we
    -- make the tree-specific getSize() call.
    if objectName ~= "Tree" then return end

    local size = nil
    if obj.getSize then
        size = obj:getSize()
    end

    local key = tostring(spriteName) .. "|" .. tostring(size)
    if seenTreeKeys[key] then return end
    seenTreeKeys[key] = true

    log(string.format(
        "TREE-METADATA @ %d,%d,%d objectName=Tree sprite=%s size=%s",
        square:getX(), square:getY(), square:getZ(),
        tostring(spriteName), tostring(size)
    ))
end

local function scanAroundPlayer()
    if not Config.EnableCanopyRuntimeDiagnostic then return end

    local player = getPlayer0()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local zoneKey = zoneInfo(square)
    if zoneKey ~= lastZoneKey then
        lastZoneKey = zoneKey
        log(string.format(
            "PLAYER-ZONE @ %d,%d,%d %s",
            square:getX(), square:getY(), square:getZ(), zoneKey
        ))
    end

    local cell = getCell and getCell() or nil
    if not cell then return end

    local radius = Config.CanopyDiagnosticRadius
    local px, py, pz = square:getX(), square:getY(), square:getZ()

    for dy = -radius, radius do
        for dx = -radius, radius do
            if dx*dx + dy*dy <= radius*radius then
                local sq = cell:getGridSquare(px+dx, py+dy, pz)
                if sq then
                    local objects = sq:getObjects()
                    if objects then
                        for i = 0, objects:size() - 1 do
                            local obj = objects:get(i)
                            if obj then
                                inspectObject(obj, sq)
                            end
                        end
                    end
                end
            end
        end
    end
end

local function onTick()
    tick = tick + 1
    if tick % Config.CanopyDiagnosticEveryTicks == 0 then
        scanAroundPlayer()
    end
end

Events.OnTick.Add(onTick)
log("Safe canopy runtime diagnostic loaded; active bounded canopy attenuation enabled")
