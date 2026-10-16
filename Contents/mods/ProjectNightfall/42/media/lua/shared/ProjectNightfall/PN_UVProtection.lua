-- Provisional GAMEPLAY transmission values, not measured fabric UV properties.
-- Item overrides are verified vanilla IDs; never infer armor from name substrings.
local Protection={}
local defaults={fallback=.5,materials={Cotton=.10,Denim=.05,Leather=.02},items={
    ["Base.Hat_RiotHelmet"]=.01,["Base.Vest_BulletPolice"]=.01,
    ["Base.GreaveBodyArmour_Right_Police"]=.01,["Base.GreaveBodyArmour_Left_Police"]=.01,
    ["Base.ThighBodyArmour_R_Police"]=.01,["Base.ThighBodyArmour_L_Police"]=.01,
    ["Base.Vambrace_BodyArmour_Right_Police"]=.01,["Base.Vambrace_BodyArmour_Left_Police"]=.01,
},parts={}}
local function unit(v) return type(v)=="number" and v==v and v>=0 and v<=1 end
local function copy(t)
    local result={}
    for k,v in pairs(t) do result[k]=type(v)=="table" and copy(v) or v end
    return result
end
function Protection.defaults() return copy(defaults) end

-- Compile once per policy change, not once per zombie. Caller owns registration
-- and sandbox configuration. Capturing a copy prevents later accidental mutation.
function Protection.compile(config)
    if type(config)~="table" or not unit(config.fallback) then return nil,"fallback transmission required" end
    for _,field in ipairs({"materials","items"}) do
        if type(config[field])~="table" then return nil,"missing transmission map: "..field end
        for id,value in pairs(config[field]) do
            if type(id)~="string" or id=="" or not unit(value) then return nil,"invalid "..field.." transmission" end
        end
    end
    if type(config.parts)~="table" then return nil,"part override map required" end
    for id,parts in pairs(config.parts) do
        if type(id)~="string" or type(parts)~="table" then return nil,"invalid item-part override" end
        for part,value in pairs(parts) do
            if type(part)~="string" or not unit(value) then return nil,"invalid part transmission" end
        end
    end
    local policy=copy(config)
    return function(itemType,part,fabric)
        local parts=policy.parts[itemType]
        if parts and parts[part]~=nil then return parts[part],"item-part" end
        if policy.items[itemType]~=nil then return policy.items[itemType],"item" end
        if fabric and policy.materials[fabric]~=nil then return policy.materials[fabric],"material" end
        return policy.fallback,"fallback"
    end
end
return Protection
