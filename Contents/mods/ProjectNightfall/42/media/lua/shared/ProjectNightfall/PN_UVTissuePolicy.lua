-- Compiles configuration into the regional policy consumed by the authoritative
-- UV tissue pipeline. It deliberately owns validation, not balance decisions.
local Protection=require "ProjectNightfall/PN_UVProtection"
local Policy={}
ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.UVTissuePolicy=Policy

local function finite(value)
    return type(value)=="number" and value==value and math.abs(value)<math.huge
end

local function ordered(values,label,allowZero)
    if type(values)~="table" or #values==0 then return nil,label.." must be a non-empty array" end
    local result,previous={},nil
    for index,value in ipairs(values) do
        value=tonumber(value)
        if not finite(value) or (allowZero and value<0 or not allowZero and value<=0)
            or (previous and value<=previous) then return nil,label.." must be finite and strictly increasing" end
        result[index],previous=value,value
    end
    return result
end

local function profile(source,label)
    if type(source)~="table" then return nil,label.." must be a table" end
    local thresholds,err=ordered(source.thresholds,label.." thresholds",false)
    if not thresholds then return nil,err end
    local magnitudes
    magnitudes,err=ordered(source.woundMagnitudes,label.." wound magnitudes",true)
    if not magnitudes then return nil,err end
    if #magnitudes~=#thresholds then return nil,label.." thresholds and wound magnitudes must match" end
    local exposure=tonumber(source.exposureFactor)
    if not finite(exposure) or exposure<0 then return nil,label.." exposure factor must be finite and >= 0" end
    local capacity=tonumber(source.capacity)
    local loss=source.artificialTissueLossPerDose
    if loss==nil then loss=0 end
    if not finite(loss) or loss<0 then return nil,label.." artificial tissue loss rate must be finite and >= 0" end
    local naturalCap=tonumber(source.naturalCapFraction)
    if not finite(capacity) or capacity<=0 then return nil,label.." capacity must be finite and > 0" end
    if not finite(naturalCap) or naturalCap<0 or naturalCap>1 then return nil,label.." natural cap must be within [0,1]" end
    for _,threshold in ipairs(thresholds) do
        if threshold>1 then return nil,label.." thresholds must be capacity fractions within (0,1]" end
    end
    return {thresholds=thresholds,woundMagnitudes=magnitudes,exposureFactor=exposure,
        capacity=capacity,naturalCapFraction=naturalCap,artificialTissueLossPerDose=loss}
end

local function copyArray(source)
    local result={}
    for index,value in ipairs(source) do result[index]=value end
    return result
end

-- anatomy uses canonical M.O.R.T.I.S. region identifiers. Exact overrides are
-- accepted; aliases/fuzzy identifiers are rejected so policy cannot silently
-- protect or injure the wrong body part.
function Policy.compile(anatomy,configuration)
    if type(anatomy)~="table" or type(anatomy.regions)~="table" then return nil,"anatomy required" end
    if type(configuration)~="table" then return nil,"UV tissue configuration required" end
    local fallback,err=profile(configuration.default,"default UV tissue profile")
    if not fallback then return nil,err end
    local overrides=configuration.regions or {}
    if type(overrides)~="table" then return nil,"regional UV tissue profiles must be a table" end
    for id in pairs(overrides) do
        if anatomy.regions[id]==nil then return nil,"unknown UV tissue region override: "..tostring(id) end
    end
    local regions={}
    for id in pairs(anatomy.regions) do
        local selected=fallback
        if overrides[id]~=nil then
            selected,err=profile(overrides[id],"UV tissue region "..id)
            if not selected then return nil,err end
        end
        regions[id]={exposureFactor=selected.exposureFactor,capacity=selected.capacity,
            artificialTissueLossPerDose=selected.artificialTissueLossPerDose,
            naturalCapFraction=selected.naturalCapFraction,thresholds=copyArray(selected.thresholds),
            woundMagnitudes=copyArray(selected.woundMagnitudes)}
    end
    local resolve,protection=Protection.compile(configuration.protection or Protection.defaults())
    if not resolve then return nil,protection end
    return {regions=regions,resolveTransmission=resolve,weights=configuration.weights,
        traumaMovement=configuration.traumaMovement,artificialDeath=configuration.artificialDeath==true,
        protection=protection}
end

return Policy
