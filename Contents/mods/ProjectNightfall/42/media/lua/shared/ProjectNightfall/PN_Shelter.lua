require "ProjectNightfall/PN_Config"
require "ProjectNightfall/PN_SolarUV"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.Shelter = ProjectNightfall.Shelter or {}

local Shelter = ProjectNightfall.Shelter
local Config = ProjectNightfall.Config.POC

local function call(object,method,...)
    if not object then return nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return nil end
    local called,value=pcall(fn,object,...)
    if not called then return nil end
    return value
end

local function isCandidateSafe(square)
    if not square then return false end
    local ok,exposure=pcall(ProjectNightfall.SolarUV.getExposureAtSquare,square)
    if not ok or (tonumber(exposure) or 0)>0 then return false end
    return call(square,"isInARoom")==true or call(square,"isOutside")==false
end

local function candidateScore(zombie, square)
    local sx,sy,zx,zy=tonumber(call(square,"getX")),tonumber(call(square,"getY")),tonumber(call(zombie,"getX")),tonumber(call(zombie,"getY"))
    if not sx or not sy or not zx or not zy then return -math.huge end
    local dx = sx + 0.5 - zx
    local dy = sy + 0.5 - zy
    local distanceSq = dx * dx + dy * dy
    local roomBonus = call(square,"isInARoom")==true and 12 or 0
    return roomBonus - distanceSq
end

-- Local search only: no global building knowledge, no distant shelter cache.
function Shelter.findNearby(zombie)
    if not zombie or call(zombie,"isDead")~=false then return nil end
    local cell = getCell and getCell() or nil
    if not cell then return nil end

    local radius = Config.ShelterSearchRadius
    local zx,zy,zz=tonumber(call(zombie,"getX")),tonumber(call(zombie,"getY")),tonumber(call(zombie,"getZ"))
    if not zx or not zy or not zz then return nil end
    zx,zy,zz=math.floor(zx),math.floor(zy),math.floor(zz)
    local best, bestScore = nil, -math.huge

    for dy = -radius, radius do
        for dx = -radius, radius do
            if (dx * dx + dy * dy) <= radius * radius then
                local square = call(cell,"getGridSquare",zx + dx, zy + dy, zz)
                if isCandidateSafe(square) then
                    local score = candidateScore(zombie, square)
                    if score > bestScore then
                        best, bestScore = square, score
                    end
                end
            end
        end
    end
    return best
end

-- Emergency survival requires the literal closest currently safe loaded
-- square, without den-quality or room-type bonuses.
function Shelter.findClosestNearby(zombie)
    if not zombie or call(zombie,"isDead")~=false then return nil end
    local cell=getCell and getCell() or nil;if not cell then return nil end
    local zx,zy,zz=tonumber(call(zombie,"getX")),tonumber(call(zombie,"getY")),tonumber(call(zombie,"getZ"))
    if not zx or not zy or not zz then return nil end
    zx,zy,zz=math.floor(zx),math.floor(zy),math.floor(zz)
    local radius=math.max(1,math.floor(tonumber(Config.ShelterSearchRadius)or 12))
    -- Loaded basements and the room immediately above/below them must both be
    -- eligible. Keep the vertical probe deliberately small so this remains a
    -- bounded local observation rather than knowledge of an entire building.
    local verticalRadius=2
    for distance=0,radius do
        local best,bestDistance=nil,math.huge
        for dz=-verticalRadius,verticalRadius do
            for dy=-distance,distance do
                for dx=-distance,distance do
                    if math.max(math.abs(dx),math.abs(dy))==distance then
                        local square=call(cell,"getGridSquare",zx+dx,zy+dy,zz+dz)
                        if isCandidateSafe(square) then
                            local distanceSq=dx*dx+dy*dy+dz*dz
                            if distanceSq<bestDistance then best,bestDistance=square,distanceSq end
                        end
                    end
                end
            end
        end
        if best then return best end
    end
    return nil
end
