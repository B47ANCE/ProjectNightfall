require "ProjectNightfall/PN_Config"
require "ProjectNightfall/PN_FlashlightBulbs"
require "lightWorks/lightWorks_UV"
local Mortis = require "Mortis/init"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.ArtificialUV = ProjectNightfall.ArtificialUV or {}

local tick = 0
local worldEmitters={}
local currentEmitters={}
local nextSuicidalDecision=setmetatable({},{__mode="k"})
local UPDATE_EVERY_TICKS = 10
local WORLD_SCAN_EVERY_TICKS = 60
local WORLD_SCAN_RADIUS = 16
local integrationErrorReported=false
local unpackArguments=unpack or table.unpack

local function log(message)
    print("[ProjectNightfall]["..tostring(ProjectNightfall.VERSION or "unknown").."][ArtificialUV] " .. tostring(message))
end

local function reportIntegrationError(message)
    if integrationErrorReported then return end
    integrationErrorReported=true
    log(message)
end

-- Read-only snapshot for Nightfall's primary bounded lifecycle scheduler. The
-- regional tissue path reuses emitter discovery without adopting this module's
-- legacy zombie queue.
function ProjectNightfall.ArtificialUV.getCurrentEmitters(entity)
    local result={}
    for _,emitter in ipairs(currentEmitters) do
        if not entity or ProjectNightfall.ArtificialUV.isNearEmitter(entity,{emitter}) then
            local copy={}
            for key,value in pairs(emitter) do
                if key=="spectrum" and type(value)=="table" then
                    local spectrum={};for band,intensity in pairs(value) do spectrum[band]=intensity end
                    copy[key]=spectrum
                else copy[key]=value end
            end
            result[#result+1]=copy
        end
    end
    return result
end

local function call(object,method,...)
    if not object then return nil end
    local arguments={...}
    local ok,value=pcall(function() return object[method](object,unpackArguments(arguments)) end)
    if not ok then return nil end
    return value
end

function ProjectNightfall.ArtificialUV.isNearEmitter(entity,emitters)
    local ex,ey,ez=tonumber(call(entity,"getX")),tonumber(call(entity,"getY")),tonumber(call(entity,"getZ"))
    if not ex or not ey or not ez then return false end
    for _,emitter in ipairs(emitters or {}) do
        local owner=emitter.owner
        local ox,oy,oz=tonumber(call(owner,"getX")),tonumber(call(owner,"getY")),tonumber(call(owner,"getZ"))
        local range=math.max(0,tonumber(emitter.range) or 0)
        if ox and oy and oz and math.floor(ez)==math.floor(oz) then
            local dx,dy=ex-ox,ey-oy
            if dx*dx+dy*dy<=range*range then return true end
        end
    end
    return false
end

local function collectPlayers()
    local players,seen={},{}
    local function add(player)
        if player and not seen[player] then seen[player]=true; players[#players+1]=player end
    end
    local online=getOnlinePlayers and getOnlinePlayers() or nil
    local onlineCount=online and call(online,"size") or 0
    for index=0,(tonumber(onlineCount) or 0)-1 do
        local ok,player=pcall(online.get,online,index); if ok then add(player) end
    end
    local activeCount=getNumActivePlayers and tonumber(getNumActivePlayers()) or 0
    for index=0,(activeCount or 0)-1 do add(getSpecificPlayer and getSpecificPlayer(index) or nil) end
    add(getPlayer and getPlayer() or nil)
    return players
end

local function dedupeEmitters(target,seen,source)
    if type(source)~="table" then return end
    for _,emitter in ipairs(source or {}) do
        if type(emitter)=="table" then
            local key=emitter.item or emitter.owner or emitter
            if not seen[key] then seen[key]=true; target[#target+1]=emitter end
        end
    end
end

local function collectEmitters(method,...)
    local collector=lightWorks and lightWorks.UV and lightWorks.UV[method]
    if type(collector)~="function" then return {} end
    local ok,result=pcall(collector,...)
    if not ok then
        reportIntegrationError("Artificial UV "..method.." failed safely: "..tostring(result))
        return {}
    end
    return type(result)=="table" and result or {}
end

-- Tactical behavior retained from the legacy damage loop. The primary
-- Nightfall lifecycle scheduler calls this with the same verified exposure that
-- fed regional tissue; this function never applies damage or gathers zombies.
function ProjectNightfall.ArtificialUV.considerIndependentAttack(zombie,exposure)
    local config=ProjectNightfall.Config.POC
    if config.EnableIndependentSuicidalUVAttacks==false or tick<(nextSuicidalDecision[zombie] or 0) then return false end
    local sources=type(exposure)=="table" and exposure.sources or nil
    if type(sources)~="table" then return false end
    local typeId=Mortis.getTypeId and Mortis.getTypeId(zombie) or nil
    local smart=typeId=="ProjectNightfall.SmartFeral" or typeId=="ProjectNightfall.AlphaFeral"
    local defense=ProjectNightfall.DenDefense
    local sourceAPI=lightWorks and lightWorks.EmissionSources
    if smart or not defense or not sourceAPI or type(sourceAPI.inspect)~="function" then return false end
    for _,contribution in ipairs(sources) do
        local object=contribution.item or (contribution.source and contribution.source.item)
        local source=object and sourceAPI.inspect(object) or nil
        if source and source.channels and source.channels.UV==true
            and source.destroy and source.destroy.supported==true then
            local randomUnit=function()
                if Mortis.Random and type(Mortis.Random.next)=="function" then return Mortis.Random.next(zombie) end
                return math.random()
            end
            defense.considerIndependentUVAttack(zombie,source,
                tonumber(config.IndependentSuicidalUVAttackChance) or 0.005,randomUnit)
            nextSuicidalDecision[zombie]=tick+math.max(60,
                tonumber(config.IndependentSuicidalUVDecisionCooldownTicks) or 1800)
            return true
        end
    end
    return false
end

local function runTick()
    tick=tick+1; if tick%UPDATE_EVERY_TICKS~=0 then return end
    local authorityOk,authorized=pcall(function() return Mortis.Authority.canWriteCanonicalState() end)
    if not authorityOk or authorized~=true then
        if not authorityOk then reportIntegrationError("Artificial UV authority check failed safely: "..tostring(authorized)) end
        return
    end
    local playersOk,players=pcall(collectPlayers)
    if not playersOk then reportIntegrationError("Artificial UV player collection failed safely: "..tostring(players)); return end
    if #players==0 then currentEmitters={};return end
    if tick%WORLD_SCAN_EVERY_TICKS==0 and lightWorks.UV.collectWorldEmitters then
        local refreshed,seen={},{}
        for _,player in ipairs(players) do
            dedupeEmitters(refreshed,seen,collectEmitters("collectWorldEmitters",player,WORLD_SCAN_RADIUS))
        end
        worldEmitters=refreshed
    end
    local emitters,seen={},{}
    for _,player in ipairs(players) do
        dedupeEmitters(emitters,seen,collectEmitters("collectPlayerEmitters",player))
    end
    dedupeEmitters(emitters,seen,worldEmitters)
    currentEmitters=emitters
end

local function onTick()
    local ok,reason=pcall(runTick)
    if not ok then reportIntegrationError("Artificial UV update failed safely: "..tostring(reason)) end
end

Events.OnTick.Add(onTick)
log("lightWorks UV emitter provider loaded; PN_ZombieUV owns regional tissue processing")
