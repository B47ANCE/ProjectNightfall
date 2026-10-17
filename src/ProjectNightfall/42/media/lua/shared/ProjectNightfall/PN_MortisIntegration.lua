local Mortis = require "Mortis/init"
local loadedConfig = require "ProjectNightfall/PN_Config"
local Config = type(loadedConfig)=="table" and loadedConfig
    or (rawget(_G,"ProjectNightfall") and ProjectNightfall.Config) or {}

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.MortisIntegration = ProjectNightfall.MortisIntegration or {}

local Integration = ProjectNightfall.MortisIntegration

local function finite(value)
    value=tonumber(value)
    return value and value==value and value~=math.huge and value~=-math.huge and value or nil
end

local function safeCall(fn,...)
    if type(fn)~="function" then return false,nil,nil end
    local ok,a,b=pcall(fn,...)
    return ok,a,b
end

Integration.TYPE_TRANSFORMING = "ProjectNightfall.Transforming"
Integration.TYPE_FERAL = "ProjectNightfall.Feral"
Integration.TYPE_SMART_FERAL = "ProjectNightfall.SmartFeral"
Integration.TYPE_ALPHA_FERAL = "ProjectNightfall.AlphaFeral"

local DEFAULT_NUTRITION_MULTIPLIERS={
    [Integration.TYPE_TRANSFORMING]=0.50,
    [Integration.TYPE_FERAL]=0.25,
    [Integration.TYPE_SMART_FERAL]=0.15,
    [Integration.TYPE_ALPHA_FERAL]=0.10,
}

local function registerTrait()
    if Mortis.Traits.has("ProjectNightfall.UVVulnerable") then return end
    Mortis.registerTrait({
        id = "ProjectNightfall.UVVulnerable",
        defaults = { damageMultiplier = 1.0 },
        -- Nightfall deliberately owns UV exposure, damage, and reactions.
        -- This trait is the public semantic marker for other MORTIS consumers.
    })
end

local function registerType(definition)
    if not Mortis.Types.has(definition.id) then Mortis.registerType(definition) end
end

registerTrait()
registerType({
    id = Integration.TYPE_TRANSFORMING,
    displayName = "Transforming Feral",
    stats = { intelligence = 0.20, aggression = 0.65 },
    traits = { { id = "ProjectNightfall.UVVulnerable", config = { damageMultiplier = 1.0 } } },
})
registerType({
    id = Integration.TYPE_ALPHA_FERAL,
    displayName = "Alpha Feral",
    extends = Integration.TYPE_SMART_FERAL,
    -- Command intelligence is the distinction; no boss-stat inflation.
    stats = { intelligence = 1.00, aggression = 0.85 },
})

if Mortis.registerDetachedPartClassifier and
   not Mortis.DetachedParts.registry:has("ProjectNightfall.sourceSignature") then
    Mortis.registerDetachedPartClassifier({
        id="ProjectNightfall.sourceSignature",
        classify=function(source,record)
            local typeId=record and record.sourceTypeId or Mortis.getTypeId(source)
            local signature
            if typeId==Integration.TYPE_SMART_FERAL or typeId==Integration.TYPE_ALPHA_FERAL then signature="smartFeral"
            elseif typeId==Integration.TYPE_FERAL or typeId==Integration.TYPE_TRANSFORMING then signature="feral"
            else
                local kind=Mortis.Entity and Mortis.Entity.kind(source) or "unknown"
                if kind=="infected" then signature="regular"
                elseif kind=="player" or kind=="living" then signature="human" end
            end
            if not signature then return nil end
            return {schemaVersion=1,signature=signature,sourceTypeId=typeId}
        end,
    })
end
registerType({
    id = Integration.TYPE_FERAL,
    displayName = "Feral",
    extends = Integration.TYPE_TRANSFORMING,
    stats = { intelligence = 0.20, aggression = 1.00 },
})
registerType({
    id = Integration.TYPE_SMART_FERAL,
    displayName = "Smart Feral",
    extends = Integration.TYPE_FERAL,
    stats = { intelligence = 0.90, aggression = 0.85 },
})

function Integration.getTypeId(zombie)
    if not zombie then return nil end
    return Mortis.getTypeId(zombie)
end

function Integration.canWriteCanonicalState(zombie)
    return Mortis.Authority.canWriteCanonicalState(zombie)
end

function Integration.isNightfallType(typeId)
    return typeId == Integration.TYPE_TRANSFORMING
        or typeId == Integration.TYPE_FERAL
        or typeId == Integration.TYPE_SMART_FERAL
        or typeId == Integration.TYPE_ALPHA_FERAL
end

function Integration.applyIdentityToState(zombie, state)
    if Integration.canWriteCanonicalState(zombie) and Integration.assignmentPending(zombie) then
        return nil,"assignment recovery pending"
    end
    local typeId = Integration.getTypeId(zombie)
    if typeId == Integration.TYPE_ALPHA_FERAL then
        state.phase = "FERAL"
        state.smartFeral = true
        state.alphaFeral = true
    elseif typeId == Integration.TYPE_SMART_FERAL then
        state.phase = "FERAL"
        state.smartFeral = true
        state.alphaFeral = false
    elseif typeId == Integration.TYPE_FERAL then
        state.phase = "FERAL"
        state.smartFeral = false
        state.alphaFeral = false
    elseif typeId == Integration.TYPE_TRANSFORMING then
        state.phase = "TRANSFORMING"
        state.smartFeral = false
        state.alphaFeral = false
    end
    return typeId
end

-- Server-owned recovery metadata is independent of the assignment being cleared.
-- It survives consumer reloads; native disk/transport durability remains a human gate.
local RECOVERY_KEY="ProjectNightfallAssignmentRecovery"
local function recoveryData(zombie)
    local ok,data=safeCall(zombie and zombie.getModData,zombie)
    if not ok or type(data)~="table" then return nil,"assignment recovery storage unavailable" end
    return data
end
local function journal(data)
    local value=data[RECOVERY_KEY]
    if value==nil then return nil end
    if type(value)~="table" or getmetatable(value)~=nil or value.version~=1
        or not Integration.isNightfallType(value.target)
        or (value.prior~=false and (type(value.prior)~="string" or #value.prior==0 or #value.prior>160))
        or (value.status~="rollback" and value.status~="uncertain" and value.status~="committed") then
        return nil,"invalid assignment recovery journal"
    end
    for key in pairs(value) do
        if key~="version" and key~="target" and key~="prior" and key~="status" then
            return nil,"invalid assignment recovery journal"
        end
    end
    return value
end
local function clearCanonical(zombie)
    if not Mortis.clearAssignment then return false,"M.O.R.T.I.S. clear API unavailable" end
    local overrides=Mortis.LocomotionOverrides
    if not overrides or type(overrides.release)~="function" or type(overrides.releaseCeiling)~="function" then
        return false,"M.O.R.T.I.S. ownership cleanup API unavailable"
    end
    -- Never call Overrides.clear(): it would steal other consumers' requests.
    for _,owner in ipairs({"ProjectNightfall.UVSlow","ProjectNightfall.FeralSprint","ProjectNightfall.BaseSpeed"}) do
        local called,ok,reason=safeCall(overrides.release,zombie,owner)
        if not called or ok~=true then return false,reason or "Nightfall owner release failed" end
    end
    local called,ok,reason=safeCall(overrides.releaseCeiling,zombie,"ProjectNightfall.TissueInjury")
    if not called or ok~=true then return false,reason or "Nightfall ceiling release failed" end
    called,ok,reason=safeCall(Mortis.clearAssignment,zombie)
    if not called or ok~=true or Mortis.getTypeId(zombie)~=nil then
        return false,reason or "canonical clear readback failed"
    end
    return true
end
function Integration.assignmentPending(zombie)
    local data,err=recoveryData(zombie);if not data then return true,err end
    local pending;pending,err=journal(data)
    return pending~=nil or err~=nil,err
end
function Integration.recoverAssignment(zombie)
    if not zombie or not Integration.canWriteCanonicalState(zombie) then return false,"non-authority" end
    local data,err=recoveryData(zombie);if not data then return false,err end
    local pending;pending,err=journal(data);if err then return false,err end
    if not pending then return true,nil,false end
    if pending.status=="uncertain" then return false,"assignment biology outcome uncertain; recovery pending" end
    local current=Mortis.getTypeId(zombie)
    local prior=pending.prior~=false and pending.prior or nil
    local restored=prior
    if pending.status=="committed" then
        if current~=pending.target then return false,"committed assignment identity changed; recovery pending" end
        restored=pending.target
    elseif current~=prior then
        if current~=pending.target then return false,"assignment identity changed; recovery pending" end
        local called,ok,reason
        if prior then called,ok,reason=safeCall(Mortis.assign,zombie,prior)
        else called,ok,reason=safeCall(clearCanonical,zombie) end
        if not called or not ok or Mortis.getTypeId(zombie)~=prior then
            return false,"assignment recovery pending: "..tostring(reason or "identity readback failed")
        end
    end
    data[RECOVERY_KEY]=nil
    if data[RECOVERY_KEY]~=nil then return false,"assignment journal cleanup failed" end
    return true,"assignment recovered",true,restored or false
end

function Integration.assign(zombie, typeId)
    if not zombie or not Integration.isNightfallType(typeId) then
        return false, "invalid Nightfall MORTIS assignment"
    end
    if not Integration.canWriteCanonicalState(zombie) then return false,"non-authority" end
    local data,storageReason=recoveryData(zombie);if not data then return false,storageReason end
    local existing,journalError=journal(data)
    if journalError or existing then return false,journalError or "assignment recovery pending" end
    local multipliers={
        [Integration.TYPE_TRANSFORMING]=finite(Config.TransformingNutritionMultiplier) or DEFAULT_NUTRITION_MULTIPLIERS[Integration.TYPE_TRANSFORMING],
        [Integration.TYPE_FERAL]=finite(Config.FeralNutritionMultiplier) or DEFAULT_NUTRITION_MULTIPLIERS[Integration.TYPE_FERAL],
        [Integration.TYPE_SMART_FERAL]=finite(Config.SmartFeralNutritionMultiplier) or DEFAULT_NUTRITION_MULTIPLIERS[Integration.TYPE_SMART_FERAL],
        [Integration.TYPE_ALPHA_FERAL]=finite(Config.AlphaFeralNutritionMultiplier) or DEFAULT_NUTRITION_MULTIPLIERS[Integration.TYPE_ALPHA_FERAL],
    }
    local function applyBiology()
        if not Mortis.Anatomy or type(Mortis.Anatomy.applyNutritionProfile)~="function" then
            return false,"M.O.R.T.I.S. nutrition-profile API unavailable"
        end
        local multiplier=finite(multipliers[typeId]);if not multiplier or multiplier<0 then return false,"invalid Nightfall nutrition profile" end
        local receipt,reason=Mortis.Anatomy.applyNutritionProfile(zombie,"ProjectNightfall:"..typeId,multiplier,{transmit=true})
        return type(receipt)=="table",reason
    end
    local prior=Mortis.getTypeId(zombie)
    local pending={version=1,prior=prior or false,target=typeId,status="rollback"}
    data[RECOVERY_KEY]=pending
    if data[RECOVERY_KEY]~=pending then return false,"assignment journal checkpoint failed" end
    local called,assigned,reason=true,zombie,nil
    if prior~=typeId then called,assigned,reason=safeCall(Mortis.assign,zombie,typeId) end
    local biological,biologyReason=false,reason
    if called and assigned and Mortis.getTypeId(zombie)==typeId then
        -- A crash/exception during biology cannot be assumed to have rolled back.
        pending.status="uncertain"
        local biologyCalled
        biologyCalled,biological,biologyReason=safeCall(applyBiology)
        if not biologyCalled then return false,"assignment biology outcome uncertain; recovery pending" end
        pending.status=biological and "committed" or "rollback"
    end
    local recovered,recoveryReason=Integration.recoverAssignment(zombie)
    if not recovered then return false,tostring(biologyReason or reason or "assignment failed").."; "..tostring(recoveryReason) end
    if biological then return true end
    return false,biologyReason or reason or "assignment failed"
end

function Integration.clear(zombie)
    if not zombie then return false,"missing zombie" end
    if not Integration.canWriteCanonicalState(zombie) then return false,"non-authority" end
    local data,err=recoveryData(zombie);if not data then return false,err end
    local pending;pending,err=journal(data)
    if err or pending then return false,err or "assignment recovery pending" end
    return clearCanonical(zombie)
end

-- Commit M.O.R.T.I.S. identity before Nightfall releases a hibernating zombie.
-- Callers must not change phase/locomotion when this returns false.
function Integration.commitRiseIdentity(zombie,asFeral,smartFeral)
    if not zombie then return false,"missing zombie" end
    if asFeral==true then
        local target=smartFeral==true and Integration.TYPE_SMART_FERAL or Integration.TYPE_FERAL
        local ok,reason=Integration.assign(zombie,target)
        if not ok then return false,reason end
        return true,target
    end
    local ok,reason=Integration.clear(zombie)
    if not ok then return false,reason end
    return true,nil
end

function Integration.rollbackRiseIdentity(zombie)
    return Integration.assign(zombie,Integration.TYPE_TRANSFORMING)
end

function Integration.requestStand(zombie)
    return Mortis.State.requestStand(zombie, { forceTransition = true })
end

function Integration.requiresCrawler(zombie)
    local snapshot,err=Mortis.AnatomyCapabilities.functionalSnapshot(zombie)
    if not snapshot then return nil,err end
    local regions=snapshot.regionFunction or {}
    local left,right=regions.leftLeg,regions.rightLeg
    if type(left)~="number" or type(right)~="number" or left~=left or right~=right
        or left<0 or right<0 or left>1 or right>1 then return nil,"leg function unavailable" end
    return left==0 and right==0
end

function Integration.captureWalkingBeforeHold(zombie,state)
    if not Mortis.Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
    if type(state)~="table" then return false,"lifecycle state required" end
    if type(state.walkingBeforeLifecycleHold)=="boolean" then return true end
    local prior=state.anatomyWalkingBeforeRestriction
    if state.anatomyCrawlerRestricted~=true or type(prior)~="boolean" then
        prior=Mortis.State.getCanWalk(zombie)
    end
    if type(prior)~="boolean" then return false,"walking baseline unavailable" end
    state.walkingBeforeLifecycleHold=prior
    return true
end

function Integration.restoreWalkingPermission(zombie,allowed)
    if not Mortis.Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
    return Mortis.State.setWalkingAllowed(zombie,allowed)
end

function Integration.enforceActiveAnatomy(zombie,state)
    if not Mortis.Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
    local crawler,err=Integration.requiresCrawler(zombie)
    if crawler==nil then return false,err end
    if crawler then
        if type(state)=="table" and state.anatomyCrawlerRestricted~=true then
            local prior=state.walkingBeforeLifecycleHold
            local reason
            if type(prior)~="boolean" then prior,reason=Mortis.State.getCanWalk(zombie) end
            if type(prior)~="boolean" then return false,reason end
            -- Record before the first native write so a partial failure cannot
            -- replace the original permission with our own disabled flag.
            state.anatomyWalkingBeforeRestriction=prior
            state.anatomyCrawlerRestricted=true
        end
        return Mortis.State.maintainCrawler(zombie)
    end
    if type(state)=="table" and state.anatomyCrawlerRestricted==true then
        if state.phase=="TRANSFORMING" or state.shelterHoldActive==true then
            return true,"recovery deferred by lifecycle hold"
        end
        local prior=state.anatomyWalkingBeforeRestriction
        if type(prior)~="boolean" then return false,"prior walking permission unavailable" end
        local restored,reason=Mortis.State.setWalkingAllowed(zombie,prior)
        if not restored then return false,reason end
        state.anatomyCrawlerRestricted=false
        state.anatomyWalkingBeforeRestriction=nil
        return true,"walking permission restored; vanilla owns get-up"
    end
    return true,"no crawler requirement"
end

function Integration.requestRise(zombie,state)
    if not Mortis.Authority.canWriteCanonicalState(zombie) then return false,"non-authority" end
    local crawler,err=Integration.requiresCrawler(zombie)
    if crawler==nil then return false,err end
    local prior
    if type(state)=="table" then prior=state.walkingBeforeLifecycleHold end
    if crawler or prior==false then
        local woke,reason=Mortis.State.requestCrawlerWake(zombie)
        if woke and type(state)=="table" then
            if crawler and type(prior)=="boolean" and state.anatomyCrawlerRestricted~=true then
                state.anatomyWalkingBeforeRestriction=prior
                state.anatomyCrawlerRestricted=true
            end
            state.walkingBeforeLifecycleHold=nil
        end
        return woke,reason
    end
    local woke,reason=Integration.requestStand(zombie)
    if woke and type(state)=="table" then state.walkingBeforeLifecycleHold=nil end
    return woke,reason
end

function Integration.requestFakeDead(zombie)
    if not Mortis.State or type(Mortis.State.requestFakeDead)~="function" then
        return false,"M.O.R.T.I.S. fake-dead transition unavailable"
    end
    return Mortis.State.requestFakeDead(zombie)
end

function Integration.hasStarvedFor(zombie, days)
    if not zombie or not Mortis.ZombieHunger then return false, 0 end
    local authorityRead,authoritative=safeCall(Mortis.Authority.canWriteCanonicalState,zombie)
    if not authorityRead then return false,0 end
    local advanceRead,advanced=safeCall(Mortis.ZombieHunger.advance,zombie)
    -- Canonical decisions must include all elapsed time. A server/SP write
    -- rejection therefore fails closed; read-only callers may inspect their
    -- last confirmed snapshot without attempting to manufacture new time.
    if authoritative==true and (not advanceRead or advanced~=true) then return false,0 end
    local read,hours=safeCall(Mortis.ZombieHunger.getStarvationHours,zombie)
    hours=read and finite(hours) or nil
    if not hours or hours<0 then return false,0 end
    local required=finite(days) or 0
    required=math.max(0,required)*24
    return hours>=required,hours
end

function Integration.getHungerDrive(zombie, threshold)
    if not zombie or not Mortis.ZombieHunger or not Mortis.ZombieHunger.getDrive then return 0, 0 end
    local authorityRead,authoritative=safeCall(Mortis.Authority.canWriteCanonicalState,zombie)
    if not authorityRead then return 0,0 end
    local advanceRead,advanced=safeCall(Mortis.ZombieHunger.advance,zombie)
    if authoritative==true and (not advanceRead or advanced~=true) then return 0,0 end
    local read,drive,level=safeCall(Mortis.ZombieHunger.getDrive,zombie,threshold)
    drive=read and finite(drive) or nil
    level=read and finite(level) or nil
    if not drive or not level then return 0,0 end
    return math.max(0,math.min(1,drive)),math.max(0,math.min(1,level))
end

function Integration.setUVSlowed(zombie, enabled)
    if enabled then
        return Mortis.LocomotionOverrides.acquire(zombie,"ProjectNightfall.UVSlow",{tier="shambler",priority=20})
    end
    return Mortis.LocomotionOverrides.release(zombie,"ProjectNightfall.UVSlow")
end

function Integration.setNightfallBaseSpeed(zombie, tier)
    if tier == nil then
        return Mortis.LocomotionOverrides.release(zombie,"ProjectNightfall.BaseSpeed")
    end
    if tier ~= "shambler" and tier ~= "fastShambler" then
        return false,"unsupported Nightfall base-speed tier"
    end
    return Mortis.LocomotionOverrides.acquire(zombie,"ProjectNightfall.BaseSpeed",{
        tier=tier,
        priority=10,
    })
end

function Integration.setFeralSprint(zombie, enabled)
    if enabled then
        return Mortis.LocomotionOverrides.acquire(zombie,"ProjectNightfall.FeralSprint",{tier="sprinter",priority=40})
    end
    return Mortis.LocomotionOverrides.release(zombie,"ProjectNightfall.FeralSprint")
end

function Integration.pathDeeperIntoShelter(zombie,entrySquare)
    if not zombie or not Mortis.CrowdFlow then return false,"MORTIS crowd flow unavailable" end
    return Mortis.CrowdFlow.pathDeeperInterior(zombie,{
        entrySquare=entrySquare,
        radius=6,
        minimumDepthGain=1.5,
        maximumOccupancy=1,
    })
end

return Integration
