local Mortis=require "Mortis/init"

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.AlphaEcologyState=ProjectNightfall.AlphaEcologyState or {}
local Ecology=ProjectNightfall.AlphaEcologyState
local KEY="ProjectNightfall.AlphaEcology"
local fallback={schemaVersion=1,deadAlphas={},powerVacuums={},powerVacuumOrder={}}

local function authoritative()
    return Mortis.Authority and Mortis.Authority.canWriteCanonicalState(nil)==true
end

local function root()
    local value=fallback
    if rawget(_G,"ModData") and type(ModData.getOrCreate)=="function" then
        local ok,result=pcall(ModData.getOrCreate,KEY)
        if ok and type(result)=="table" then value=result end
    end
    value.schemaVersion=1
    if type(value.deadAlphas)~="table" then value.deadAlphas={} end
    if type(value.powerVacuums)~="table" then value.powerVacuums={} end
    if type(value.powerVacuumOrder)~="table" then value.powerVacuumOrder={} end
    return value
end

local function transmit()
    if rawget(_G,"ModData") and type(ModData.transmit)=="function" then pcall(ModData.transmit,KEY) end
end

function Ecology.recordAlphaDeath(alphaId,payload,maxRecords)
    if not authoritative() or type(alphaId)~="string" or alphaId=="" then return false,"server authority required" end
    local data=root()
    data.deadAlphas[alphaId]=true
    if not data.powerVacuums[alphaId] then data.powerVacuumOrder[#data.powerVacuumOrder+1]=alphaId end
    data.powerVacuums[alphaId]=payload
    local cap=math.max(16,math.min(2048,math.floor(tonumber(maxRecords) or 256)))
    while #data.powerVacuumOrder>cap do
        local expired=table.remove(data.powerVacuumOrder,1)
        data.powerVacuums[expired]=nil
        -- Death knowledge is intentionally retained; only the heavier vacuum
        -- payload is capped. A deserter must never regain an undead debt.
    end
    transmit()
    return true
end

function Ecology.isAlphaDead(alphaId)
    return type(alphaId)=="string" and root().deadAlphas[alphaId]==true
end

function Ecology.getPowerVacuum(alphaId)
    return type(alphaId)=="string" and root().powerVacuums[alphaId] or nil
end

function Ecology.listPowerVacuums(limit)
    local data=root();local result={}
    limit=math.max(1,math.floor(tonumber(limit) or 64))
    for index=#data.powerVacuumOrder,1,-1 do
        local id=data.powerVacuumOrder[index];local payload=data.powerVacuums[id]
        if payload then result[#result+1]=payload;if #result>=limit then break end end
    end
    return result
end

function Ecology.resetForTests() fallback={schemaVersion=1,deadAlphas={},powerVacuums={},powerVacuumOrder={}} end
Ecology.KEY=KEY
return Ecology
