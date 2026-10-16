require "ProjectNightfall/PN_Config"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.Observation = ProjectNightfall.Observation or {}

local Observation = ProjectNightfall.Observation
local Config = ProjectNightfall.Config.POC

local signals = {}
local nextSignalId = 1

local function call(object,method,...)
    if not object then return nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return nil end
    local called,value=pcall(fn,object,...)
    if not called then return nil end
    return value
end

local function distSq(x1,y1,x2,y2)
    local dx,dy=x1-x2,y1-y2
    return dx*dx+dy*dy
end

local function isSheltered(square)
    if not square then return false end
    local inRoom,outside=call(square,"isInARoom"),call(square,"isOutside")
    return inRoom==true or outside==false
end

local function isBoundaryObservationSquare(cell, square)
    if not isSheltered(square) then return false end
    local x,y,z=tonumber(call(square,"getX")),tonumber(call(square,"getY")),tonumber(call(square,"getZ"))
    if not x or not y or not z then return false end
    local dirs={{1,0},{-1,0},{0,1},{0,-1}}
    for _,d in ipairs(dirs) do
        local n=call(cell,"getGridSquare",x+d[1],y+d[2],z)
        if call(n,"isOutside")==true then return true end
    end
    return false
end

function Observation.findObservationPoint(zombie, target)
    if not zombie or not target then return nil end
    local cell=getCell and getCell() or nil
    if not cell then return nil end
    local zx,zy,zz=tonumber(call(zombie,"getX")),tonumber(call(zombie,"getY")),tonumber(call(zombie,"getZ"))
    local tx,ty=tonumber(call(target,"getX")),tonumber(call(target,"getY"))
    if not zx or not zy or not zz or not tx or not ty then return nil end
    zx,zy,zz=math.floor(zx),math.floor(zy),math.floor(zz)
    local radius=Config.ObservationSearchRadius
    local best,bestScore=nil,math.huge

    for dy=-radius,radius do
        for dx=-radius,radius do
            if dx*dx+dy*dy <= radius*radius then
                local sq=call(cell,"getGridSquare",zx+dx,zy+dy,zz)
                if sq and isBoundaryObservationSquare(cell,sq) then
                    local sx,sy=tonumber(call(sq,"getX")),tonumber(call(sq,"getY"))
                    local targetD=distSq(sx+0.5,sy+0.5,tx,ty)
                    local zombieD=distSq(sx+0.5,sy+0.5,zx,zy)
                    local score=targetD + zombieD*0.20
                    if score<bestScore then best,bestScore=sq,score end
                end
            end
        end
    end
    return best
end

function Observation.emitSignal(zombie, square, tick)
    if not zombie or not square then return nil end
    local x,y,z=tonumber(call(square,"getX")),tonumber(call(square,"getY")),tonumber(call(square,"getZ"))
    tick=tonumber(tick)
    if not x or not y or not z or not tick then return nil end
    local id=nextSignalId
    nextSignalId=nextSignalId+1
    local signal={
        id=id,
        x=x+0.5,
        y=y+0.5,
        z=z,
        createdTick=tick,
        expiresTick=tick+Config.InterestSignalLifetimeTicks,
        source=zombie,
    }
    signals[#signals+1]=signal
    return signal
end

function Observation.prune(tick)
    tick=tonumber(tick) or 0
    for i=#signals,1,-1 do
        if signals[i].expiresTick<=tick then table.remove(signals,i) end
    end
end

function Observation.findNearbySignal(zombie,tick)
    if not zombie then return nil end
    local x,y,z=tonumber(call(zombie,"getX")),tonumber(call(zombie,"getY")),tonumber(call(zombie,"getZ"))
    tick=tonumber(tick) or 0
    if not x or not y or not z then return nil end
    local best,bestD=nil,math.huge
    local r2=Config.InterestSignalRadius*Config.InterestSignalRadius
    for _,s in ipairs(signals) do
        if s.expiresTick>tick and s.source~=zombie and math.floor(z)==math.floor(s.z) then
            local d=distSq(x,y,s.x,s.y)
            if d<=r2 and d<bestD then best,bestD=s,d end
        end
    end
    return best,bestD
end

function Observation.pathToSignal(zombie,signal)
    if not zombie or not signal then return false end
    local x,y,z=tonumber(signal.x),tonumber(signal.y),tonumber(signal.z)
    if not x or not y or not z then return false end
    local ok=pcall(function() zombie:pathToLocationF(x,y,z) end)
    return ok
end
