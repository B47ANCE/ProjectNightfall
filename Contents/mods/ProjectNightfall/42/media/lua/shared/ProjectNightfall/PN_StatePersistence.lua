ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.StatePersistence = ProjectNightfall.StatePersistence or {}

local Persistence = ProjectNightfall.StatePersistence
local SCHEMA_VERSION = 1
local FIELDS = {
    "anatomyCrawlerRestricted", "anatomyWalkingBeforeRestriction",
    "walkingBeforeLifecycleHold", "uvSlowed",
    "phase", "smartFeral", "alphaFeral", "alphaState", "alphaCallWorldAgeHours", "playDeadEngaged",
    "hibernationDisturbed", "hibernationWakeDistance", "hibernationGiveUpDistance",
    "wasOutside", "shelterHoldUntilHours", "shelterHoldActive",
    "riseCandidateSinceHours", "riseScheduledAtHours", "feralGearProcessed",
    "smartGearProcessed", "feralEligibleAtKnockdown", "starvationHoursAtKnockdown",
    "lockedVisualKind", "lockedVisualId", "lockedVisualAppliedName", "dayDormant",
    "grudgeKey", "smartMode", "smartHideUntilHours",
    "effigyHuntId", "effigyHuntUntilHours", "effigyHuntOriginX",
    "effigyHuntOriginY", "effigyHuntOriginZ", "effigyHuntEnraged",
}
local BOOLEAN_FIELDS = {
    anatomyCrawlerRestricted=true, anatomyWalkingBeforeRestriction=true,
    walkingBeforeLifecycleHold=true, uvSlowed=true,
    smartFeral=true, alphaFeral=true, playDeadEngaged=true, hibernationDisturbed=true,
    wasOutside=true, shelterHoldActive=true, feralGearProcessed=true,
    smartGearProcessed=true, feralEligibleAtKnockdown=true, dayDormant=true,
    effigyHuntEnraged=true,
}
local NUMBER_FIELDS = {
    alphaCallWorldAgeHours=true, hibernationWakeDistance=true, hibernationGiveUpDistance=true,
    shelterHoldUntilHours=true, riseCandidateSinceHours=true, riseScheduledAtHours=true,
    starvationHoursAtKnockdown=true, smartHideUntilHours=true,
    effigyHuntUntilHours=true,effigyHuntOriginX=true,effigyHuntOriginY=true,effigyHuntOriginZ=true,
}
local STRING_FIELDS = {
    phase=true, alphaState=true, lockedVisualKind=true, lockedVisualId=true,effigyHuntId=true,
    lockedVisualAppliedName=true, grudgeKey=true, smartMode=true,
}
local PHASES = { NORMAL=true, TRANSFORMING=true, FERAL=true }
local SMART_MODES = {
    IDLE=true, STALK=true, AMBUSH=true, FLANK=true, EVADE=true,
    HIDE_HORDE=true, INVESTIGATE_GROUP_INTENT=true,
    EFFIGY_HUNT=true, EFFIGY_REST=true,
}
local NUMBER_RANGES = {
    hibernationWakeDistance={0,256}, hibernationGiveUpDistance={0,256},
    shelterHoldUntilHours={0,1000000000}, riseCandidateSinceHours={0,1000000000},
    riseScheduledAtHours={0,1000000000}, starvationHoursAtKnockdown={0,1000000000},
    smartHideUntilHours={0,1000000000}, effigyHuntUntilHours={0,1000000000},
    effigyHuntOriginX={-10000000,10000000}, effigyHuntOriginY={-10000000,10000000},
    effigyHuntOriginZ={-128,128},
}

local function valid(key, value)
    if BOOLEAN_FIELDS[key] then return type(value) == "boolean" end
    if NUMBER_FIELDS[key] then
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return false end
        local range=NUMBER_RANGES[key]
        return not range or (value>=range[1] and value<=range[2])
    end
    if STRING_FIELDS[key] then
        if type(value) ~= "string" or #value > 256 then return false end
        if key == "phase" then return PHASES[value] == true end
        if key == "smartMode" then return SMART_MODES[value] == true end
        return true
    end
    return false
end

local function namespace(root, create)
    if type(root) ~= "table" then return nil end
    if create and type(root.ProjectNightfall) ~= "table" then root.ProjectNightfall = {} end
    if type(root.ProjectNightfall)=="table" then return root.ProjectNightfall end
    return nil
end

function Persistence.save(root, state)
    if type(state) ~= "table" then return false end
    local data = namespace(root, true)
    if not data then return false end
    data.stateSchema = SCHEMA_VERSION
    if type(data.state)~="table" then data.state = {} end
    for _, key in ipairs(FIELDS) do
        local value = state[key]
        -- Lua's and/or idiom discards legitimate false values. A cleared flag
        -- must survive reload even if the receiving runtime default is true.
        if valid(key, value) then data.state[key] = value
        else data.state[key] = nil end
    end
    return true
end

function Persistence.restore(root, state)
    if type(state) ~= "table" then return false end
    local data = namespace(root, false)
    local rawSchema
    if data then rawSchema=data.stateSchema end
    local schema=tonumber(rawSchema)
    if rawSchema~=nil and (not schema or schema~=schema or schema==math.huge or schema==-math.huge
        or schema<0 or schema%1~=0) then return false end
    if schema and schema > SCHEMA_VERSION then return false end
    local saved = data and data.state or nil
    if type(saved) ~= "table" then return false end
    for _, key in ipairs(FIELDS) do
        if valid(key, saved[key]) then state[key] = saved[key] end
    end
    -- Version 0.15.12 stored only the grudge at the namespace root.
    if not state.grudgeKey and valid("grudgeKey", data.grudgeKey) then state.grudgeKey = data.grudgeKey end
    return true
end

function Persistence.schemaVersion() return SCHEMA_VERSION end

return Persistence
