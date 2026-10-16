require "ProjectNightfall/PN_Config"
require "ProjectNightfall/PN_SolarUV"
local FeralGroups = require "ProjectNightfall/PN_FeralGroups"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.FeralAI = ProjectNightfall.FeralAI or {}

local FeralAI = ProjectNightfall.FeralAI
local SolarUV = ProjectNightfall.SolarUV
local Config = ProjectNightfall.Config.POC

local function distanceSq(z,sq)
    local dx=(sq:getX()+0.5)-z:getX()
    local dy=(sq:getY()+0.5)-z:getY()
    return dx*dx+dy*dy
end

-- Local knowledge only. Smart Ferals do not get omniscient map information;
-- they evaluate nearby loaded squares and move toward measurably stronger sun.
function FeralAI.findBetterSunSquare(zombie)
    if not zombie then return nil,nil,nil end
    local cell=getCell and getCell() or nil
    local current=zombie:getSquare()
    if not cell or not current then return nil,nil,nil end

    local currentExposure=SolarUV.getExposureAtSquare(current) or 0.0
    local radius=tonumber(Config.SmartFeralSunSearchRadius) or 14
    local minGain=tonumber(Config.SmartFeralMinimumSunGain) or 0.08

    local zx,zy,zz=math.floor(zombie:getX()),math.floor(zombie:getY()),math.floor(zombie:getZ())
    local best=nil
    local bestExposure=currentExposure
    local bestScore=-math.huge

    for dy=-radius,radius do
        for dx=-radius,radius do
            if dx*dx+dy*dy<=radius*radius then
                local sq=cell:getGridSquare(zx+dx,zy+dy,zz)
                if sq then
                    local exposure=SolarUV.getExposureAtSquare(sq) or 0.0
                    if exposure>=currentExposure+minGain then
                        -- Exposure dominates. Distance only breaks near-ties.
                        local score=(exposure*1000.0)-distanceSq(zombie,sq)
                        if score>bestScore then
                            best=sq
                            bestExposure=exposure
                            bestScore=score
                        end
                    end
                end
            end
        end
    end

    return best,bestExposure,currentExposure
end

function FeralAI.seekSun(zombie)
    local square,best,current=FeralAI.findBetterSunSquare(zombie)
    if not square then return false,current,current end
    zombie:pathToLocationF(square:getX()+0.5,square:getY()+0.5,square:getZ())
    return true,best,current
end


local function safeCall(label,fn,...)
    local ok,a,b,c=pcall(fn,...)
    if not ok then return nil,nil,nil end
    return a,b,c
end

local function playerAlive(p)
    if not p then return false end
    local dead=safeCall("player isDead",function() return p:isDead() end)
    return dead~=true
end

function FeralAI.isPlayerAlive(player)
    return playerAlive(player)
end

function FeralAI.playerKey(player)
    if not player then return nil end
    local username=safeCall("player username",function() return player:getUsername() end)
    if username and tostring(username)~="" then return "username:"..tostring(username) end
    local online=safeCall("player online id",function() return player:getOnlineID() end)
    if online~=nil and tonumber(online) and tonumber(online)>=0 then return "online:"..tostring(online) end
    local number=safeCall("player number",function() return player:getPlayerNum() end)
    return number~=nil and "local:"..tostring(number) or nil
end

function FeralAI.findPlayerByKey(key)
    if not key then return nil end
    local seen=setmetatable({}, {__mode="k"})
    if type(rawget(_G,"getOnlinePlayers"))=="function" then
        local players=safeCall("getOnlinePlayers",getOnlinePlayers)
        local size=players and safeCall("online players size",function() return players:size() end) or 0
        for index=0,(tonumber(size) or 0)-1 do
            local player=safeCall("online player",function() return players:get(index) end)
            if player then seen[player]=true; if playerAlive(player) and FeralAI.playerKey(player)==key then return player end end
        end
    end
    for i=0,3 do
        local player=getSpecificPlayer and safeCall("getSpecificPlayer",getSpecificPlayer,i) or nil
        if player and not seen[player] and playerAlive(player) and FeralAI.playerKey(player)==key then return player end
    end
    return nil
end

function FeralAI.findNearestPlayer(zombie,maxRadius)
    if not zombie then return nil,nil end
    local radius=tonumber(maxRadius) or 30
    local best=nil
    local bestDist=radius+0.001

    -- Works in single player and local split-screen without depending on MP APIs.
    for i=0,3 do
        local p=nil
        if getSpecificPlayer then
            p=safeCall("getSpecificPlayer",getSpecificPlayer,i)
        end
        if playerAlive(p) then
            local dx=p:getX()-zombie:getX()
            local dy=p:getY()-zombie:getY()
            local d=math.sqrt(dx*dx+dy*dy)
            if d<bestDist then
                best=p
                bestDist=d
            end
        end
    end
    return best,best and bestDist or nil
end

function FeralAI.canSeeTarget(zombie,target)
    if not zombie or not target then return false end
    local seen=safeCall("CanSee",function()
        if zombie.CanSee then return zombie:CanSee(target) end
        return nil
    end)
    if seen~=nil then return seen==true end

    local los=safeCall("lineClearCollide",function()
        local cell=getCell()
        return LosUtil.lineClearCollide(
            math.floor(zombie:getX()),math.floor(zombie:getY()),math.floor(zombie:getZ()),
            math.floor(target:getX()),math.floor(target:getY()),math.floor(target:getZ()),
            false
        )
    end)
    -- lineClearCollide=true means blocked.
    if los~=nil then return los~=true end
    return false
end

local function walkableSquare(cell,x,y,z)
    local sq=cell and cell:getGridSquare(x,y,z) or nil
    if not sq then return nil end
    local solid=safeCall("isSolid",function() return sq:isSolid() end)
    if solid==true then return nil end
    return sq
end

function FeralAI.chooseFlankSquare(zombie,target)
    if not zombie or not target then return nil end
    local cell=getCell and getCell() or nil
    if not cell then return nil end

    local tx,ty,tz=target:getX(),target:getY(),math.floor(target:getZ())
    local zx,zy=zombie:getX(),zombie:getY()
    local vx=zx-tx
    local vy=zy-ty
    local len=math.sqrt(vx*vx+vy*vy)
    if len<0.001 then return nil end
    vx=vx/len
    vy=vy/len

    -- Perpendicular vectors give us left/right flank candidates.
    local px=-vy
    local py=vx
    local minD=tonumber(Config.SmartFeralFlankDistanceMin) or 5
    local maxD=tonumber(Config.SmartFeralFlankDistanceMax) or 10
    if maxD<minD then minD,maxD=maxD,minD end
    local span=math.max(1,math.floor(maxD-minD+1))
    local dist=minD
    if ZombRand then dist=minD+ZombRand(span) end

    local candidates={
        {tx+(px*dist)-(vx*2),ty+(py*dist)-(vy*2)},
        {tx-(px*dist)-(vx*2),ty-(py*dist)-(vy*2)},
        {tx+(px*dist)+(vx*2),ty+(py*dist)+(vy*2)},
        {tx-(px*dist)+(vx*2),ty-(py*dist)+(vy*2)},
    }

    local best=nil
    local bestScore=-math.huge
    for _,c in ipairs(candidates) do
        local sq=walkableSquare(cell,math.floor(c[1]),math.floor(c[2]),tz)
        if sq then
            local dx=sq:getX()-zx
            local dy=sq:getY()-zy
            local travel=math.sqrt(dx*dx+dy*dy)
            -- Prefer flank points that break current LOS to the player.
            local blocked=safeCall("flank LOS blocked",function()
                if LosUtil and LosUtil.lineClearCollide then
                    return LosUtil.lineClearCollide(
                        sq:getX(),sq:getY(),sq:getZ(),
                        math.floor(tx),math.floor(ty),tz,false
                    )
                end
                return false
            end)
            local score=(blocked==true and 30 or 0)-travel
            if score>bestScore then
                best=sq
                bestScore=score
            end
        end
    end
    return best
end

local function squareBuilding(sq)
    if not sq then return nil end
    return safeCall("getBuilding",function() return sq:getBuilding() end)
end

local function estimateBuildingTiles(building)
    if not building then return 0 end
    local total=0

    -- Build 42 building defs expose rooms in normal gameplay. Keep every call
    -- defensive so unusual/modded buildings simply fall back to horde count.
    local def=safeCall("building getDef",function()
        if building.getDef then return building:getDef() end
        return nil
    end)
    local rooms=def and safeCall("building rooms",function()
        if def.getRooms then return def:getRooms() end
        return nil
    end) or nil
    if not rooms then return 0 end

    local size=safeCall("rooms size",function() return rooms:size() end)
    if not size then return 0 end
    for i=0,size-1 do
        local room=safeCall("rooms get",function() return rooms:get(i) end)
        if room then
            local area=safeCall("room area",function()
                if room.getArea then return room:getArea() end
                return nil
            end)
            if area and tonumber(area) then total=total+tonumber(area) end
        end
    end
    return total
end

local function countZombiesInBuilding(building,candidates)
    if not building then return 0,nil end
    local count=0
    local sampleSquare=nil
    for _,z in ipairs(type(candidates)=="table" and candidates or {}) do
        local sq=safeCall("zombie square",function() return z:getSquare() end)
        if sq and squareBuilding(sq)==building then count=count+1; sampleSquare=sampleSquare or sq end
    end
    return count,sampleSquare
end


function FeralAI.getSandboxPopulationMultiplier()
    -- Primary path: Build 42's SandboxVars Lua mirror.
    local mult=nil
    if SandboxVars and SandboxVars.ZombieConfig then
        mult=tonumber(SandboxVars.ZombieConfig.PopulationMultiplier)
    end

    -- Defensive fallback to the Java SandboxOptions API.
    if mult==nil and SandboxOptions and SandboxOptions.getInstance then
        local opts=SandboxOptions.getInstance()
        if opts and opts.zombieConfig and opts.zombieConfig.PopulationMultiplier then
            local option=opts.zombieConfig.PopulationMultiplier
            if option.getValue then
                local ok,value=pcall(function() return option:getValue() end)
                if ok then mult=tonumber(value) end
            end
        end
    end

    if mult==nil or mult<0 then mult=1.0 end
    return mult
end

function FeralAI.getScaledHideMinHorde()
    local base=tonumber(Config.SmartFeralHideMinHorde) or 8
    local floor=tonumber(Config.SmartFeralHideMinHordeFloor) or 3
    local pop=FeralAI.getSandboxPopulationMultiplier()

    -- Scale linearly with the user's population setting. Nearest integer keeps
    -- 1.0x exactly at 8 while 0.35x becomes 3 and 4.0x becomes 32.
    local scaled=math.floor((base*pop)+0.5)
    if scaled<floor then scaled=floor end
    return scaled,pop
end

function FeralAI.evaluateHordeBuilding(building,candidates)
    if not building then return false,0,0,0,nil end
    local count,sample=countZombiesInBuilding(building,candidates)
    local tiles=estimateBuildingTiles(building)
    local density=(tiles>0) and (count/tiles) or 0

    local minHorde,popMult=FeralAI.getScaledHideMinHorde()
    local enough=count>=minHorde
    local dense=(tiles<=0) or density>=(tonumber(Config.SmartFeralHideDensityThreshold) or 0.08)
    return enough and dense,count,tiles,density,sample,minHorde,popMult
end

function FeralAI.findHordeHideBuilding(zombie,target)
    if not zombie then return nil,nil,nil,nil,nil end
    local radius=tonumber(Config.SmartFeralHideSearchRadius) or 20
    local candidates=FeralGroups and FeralGroups.nearbyEntities
        and FeralGroups.nearbyEntities(zombie,radius,
            math.max(64,tonumber(Config.SmartFeralMaxCandidatesPerLeader) or 64)) or {}
    local seen={}
    local best=nil
    local bestSquare=nil
    local bestCount=0
    local bestTiles=0
    local bestDensity=0
    local bestMinHorde=tonumber(Config.SmartFeralHideMinHorde) or 8
    local bestPopMult=1.0
    local bestScore=-math.huge
    for _,other in ipairs(candidates) do
        if other and other~=zombie then
            local sq=safeCall("other square",function() return other:getSquare() end)
            if sq then
                local dx=sq:getX()-zombie:getX()
                local dy=sq:getY()-zombie:getY()
                if dx*dx+dy*dy<=radius*radius then
                    local b=squareBuilding(sq)
                    if b and not seen[b] then
                        seen[b]=true
                        local ok,count,tiles,density,sample,minHorde,popMult=FeralAI.evaluateHordeBuilding(b,candidates)
                        if ok then
                            -- Horde size matters most; density breaks ties.
                            local score=count+(density*20)
                            if score>bestScore then
                                best=b
                                bestSquare=sample or sq
                                bestCount=count
                                bestTiles=tiles
                                bestDensity=density
                                bestMinHorde=minHorde or bestMinHorde
                                bestPopMult=popMult or bestPopMult
                                bestScore=score
                            end
                        end
                    end
                end
            end
        end
    end
    return best,bestSquare,bestCount,bestTiles,bestDensity,bestMinHorde,bestPopMult
end

function FeralAI.targetInsideBuilding(target,building)
    if not target or not building then return false end
    local sq=safeCall("target square",function() return target:getSquare() end)
    return sq and squareBuilding(sq)==building or false
end

function FeralAI.randomHideHours()
    local minH=tonumber(Config.SmartFeralHideMinHours) or 2.0
    local maxH=tonumber(Config.SmartFeralHideMaxHours) or 8.0
    if maxH<minH then minH,maxH=maxH,minH end
    local r=math.random()
    if ZombRandFloat then
        local v=safeCall("hide rand",function() return ZombRandFloat(0.0,1.0) end)
        if v~=nil then r=tonumber(v) or r end
    end
    return minH+((maxH-minH)*r)
end

return FeralAI
