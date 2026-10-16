-- Derived semantics only. Callers supply canonical regional tissue facts;
-- this module neither samples exposure nor persists anatomy nor emits particles.
local Smoke={MAX_REGIONS=32}
local curves={
    living={{0,0},{.20,.10},{.35,.20},{.50,.40},{.65,.70},{.80,1},{.95,1.2},{1,1.2}},
    corpse={{0,0},{.10,.05},{.25,.15},{.45,.35},{.65,.70},{.80,1},{.95,1.2},{1,1.2}},
}
local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end
local function fraction(value) return finite(value) and value>=0 and value<=1 end
local function severityFactor(value,curve)
    -- No wisps below the first nonzero band. Interpolate subsequent bands.
    if value<curve[2][1] then return 0 end
    for i=2,#curve do
        local current,previous=curve[i],curve[i-1]
        if value<=current[1] then
            return previous[2]+(current[2]-previous[2])*(value-previous[1])/(current[1]-previous[1])
        end
    end
    return curve[#curve][2]
end

function Smoke.evaluate(regions,lifecycle,options)
    if type(regions)~="table" then return nil,"regional tissue facts required" end
    if not curves[lifecycle] then return nil,"living or corpse lifecycle required" end
    options=options or {}
    if type(options)~="table" then return nil,"invalid smoke options" end
    local multiplier=options.multiplier
    if multiplier==nil then multiplier=1 end
    if not finite(multiplier) or multiplier<0 then return nil,"invalid smoke multiplier" end
    local curve=options.curve or curves[lifecycle]
    if type(curve)~="table" or #curve<2 or #curve>16 then return nil,"invalid smoke curve" end
    local last=-1
    for _,point in ipairs(curve) do
        if type(point)~="table" or not fraction(point[1]) or point[1]<=last
            or not finite(point[2]) or point[2]<0 then return nil,"invalid smoke curve point" end
        last=point[1]
    end
    if curve[1][1]~=0 or curve[1][2]~=0 or last~=1 then return nil,"smoke curve must span zero to one" end
    local result={lifecycle=lifecycle,regions={},generationRate=0,remainingFraction=0,destructionFraction=0}
    local count,totalWeight=0,0
    for id,region in pairs(regions) do
        count=count+1
        if count>Smoke.MAX_REGIONS then return nil,"smoke region budget exceeded" end
        if type(id)~="string" or type(region)~="table" or type(region.attached)~="boolean" then
            return nil,"invalid smoke region"
        end
        if region.attached then
            if not fraction(region.severity) or not fraction(region.remainingFraction)
                or not finite(region.activeDestructionRate) or region.activeDestructionRate<0
                or not finite(region.weight) or region.weight<=0 then return nil,"incomplete regional tissue facts: "..id end
            local generation=severityFactor(region.severity,curve)*region.activeDestructionRate
                *math.sqrt(region.remainingFraction)*multiplier
            local weighted=generation*region.weight
            totalWeight=totalWeight+region.weight
            result.generationRate=result.generationRate+weighted
            result.remainingFraction=result.remainingFraction+region.remainingFraction*region.weight
            if not finite(generation) or not finite(result.generationRate) or not finite(totalWeight)
                or not finite(result.remainingFraction) then return nil,"smoke aggregate overflow" end
            result.regions[id]={generationRate=generation,remainingFraction=region.remainingFraction,attached=true}
        else
            result.regions[id]={generationRate=0,attached=false}
        end
    end
    if totalWeight>0 then
        result.generationRate=result.generationRate/totalWeight
        result.remainingFraction=result.remainingFraction/totalWeight
        result.destructionFraction=1-result.remainingFraction
    end
    result.tissueWeight=totalWeight
    return result
end
return Smoke
