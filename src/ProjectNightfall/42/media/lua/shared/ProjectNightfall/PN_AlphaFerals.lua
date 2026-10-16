local Mortis = require "Mortis/init"
local Integration = require "ProjectNightfall/PN_MortisIntegration"
local Ecology = require "ProjectNightfall/PN_AlphaEcologyState"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.AlphaFerals = ProjectNightfall.AlphaFerals or {}
local Alpha = ProjectNightfall.AlphaFerals
local deathListenerInstalled=false

local function worldAgeHours()
    if type(getGameTime) ~= "function" then return nil end
    local ok, gameTime = pcall(getGameTime)
    if not ok or not gameTime or type(gameTime.getWorldAgeHours) ~= "function" then return nil end
    local read, value = pcall(gameTime.getWorldAgeHours, gameTime)
    return read and tonumber(value) or nil
end

local function canonical(zombie)
    return Mortis.Authority and Mortis.Authority.canWriteCanonicalState(zombie) == true
end

function Alpha.rollAfterSmartPromotion(zombie, state, randomUnit)
    local config = ProjectNightfall.Config and ProjectNightfall.Config.POC or {}
    if config.EnableAlphaFerals == false or not zombie or type(state) ~= "table" then return false end
    if state.smartFeral ~= true or state.alphaFeral == true or not canonical(zombie) then return false end
    local chance = math.max(0, math.min(1, tonumber(config.AlphaReplacementChance) or 0.001))
    local roll = type(randomUnit) == "function" and tonumber(randomUnit()) or math.random()
    if not roll or roll >= chance then return false end
    local assigned = Integration.assign(zombie, Integration.TYPE_ALPHA_FERAL)
    if not assigned then return false end
    state.alphaFeral = true
    state.alphaState = "CALLING"
    state.alphaCallWorldAgeHours = worldAgeHours()
    if Mortis.Sound then pcall(Mortis.Sound.play, zombie, config.AlphaCallSound or "MetaScream") end
    if Mortis.Sound and Mortis.Sound.emitWorldSound then
        pcall(Mortis.Sound.emitWorldSound,zombie,config.AlphaCallWorldSoundRadius or 60,config.AlphaCallWorldSoundVolume or 60)
    end
    local payload={
        alphaId = Mortis.getStableId(zombie), x = zombie:getX(), y = zombie:getY(), z = zombie:getZ(),
        worldAgeHours = state.alphaCallWorldAgeHours,
    }
    if Mortis.Signals then Mortis.Signals.emit({source=zombie,type="ProjectNightfall.AlphaCall",position=payload,
        radius=tonumber(config.AlphaCallSemanticRadius) or 100,worldAgeHours=payload.worldAgeHours,
        expiresWorldAgeHours=payload.worldAgeHours and payload.worldAgeHours+6 or nil,persistOnSource=true,payload=payload}) end
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.AlphaCall", zombie, payload) end
    return true
end

function Alpha.lockRivalry(alphaA,alphaB)
    if not canonical(alphaA) or not canonical(alphaB) or alphaA==alphaB then return false,"invalid authoritative rivals" end
    if Integration.getTypeId(alphaA)~=Integration.TYPE_ALPHA_FERAL or Integration.getTypeId(alphaB)~=Integration.TYPE_ALPHA_FERAL then
        return false,"both rivals must be Alpha Ferals"
    end
    local idA,idB=Mortis.getStableId(alphaA),Mortis.getStableId(alphaB)
    if not idA or not idB then return false,"rivals require stable identities" end
    Mortis.CommandHierarchy.setObjective(alphaA,"destroy-rival-alpha",{x=alphaB:getX(),y=alphaB:getY(),z=alphaB:getZ()},worldAgeHours(),idB)
    Mortis.CommandHierarchy.setObjective(alphaB,"destroy-rival-alpha",{x=alphaA:getX(),y=alphaA:getY(),z=alphaA:getZ()},worldAgeHours(),idA)
    return true,idA,idB
end

function Alpha.emitDeathCry(zombie,stableId)
    if not canonical(zombie) then return false,"server authority required" end
    local config=ProjectNightfall.Config and ProjectNightfall.Config.POC or {}
    local now=worldAgeHours()
    local payload={alphaId=stableId,x=zombie:getX(),y=zombie:getY(),z=zombie:getZ(),worldAgeHours=now,powerVacuum=true}
    if type(stableId)=="string" then Ecology.recordAlphaDeath(stableId,payload,config.AlphaPowerVacuumRecordCap) end
    if Mortis.Sound then pcall(Mortis.Sound.play,zombie,config.AlphaDeathCrySound or "MetaScream") end
    if Mortis.Sound and Mortis.Sound.emitWorldSound then
        pcall(Mortis.Sound.emitWorldSound,zombie,config.AlphaDeathCryWorldSoundRadius or 75,config.AlphaDeathCryWorldSoundVolume or 75)
    end
    if Mortis.Signals then Mortis.Signals.emit({source=zombie,type="ProjectNightfall.AlphaDeathCry",position=payload,
        radius=tonumber(config.AlphaDeathCrySemanticRadius) or 120,worldAgeHours=now,
        expiresWorldAgeHours=now and now+24 or nil,persistOnSource=true,payload=payload}) end
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.AlphaDeathCry",zombie,payload) end
    return true,payload
end


function Alpha.releaseLoadedHierarchy(deadAlphaId)
    if type(deadAlphaId)~="string" or not Mortis.Engine or type(Mortis.Engine.listTracked)~="function" then return 0 end
    local cleared=0
    for _,entity in ipairs(Mortis.Engine.listTracked()) do
        local relationship=Mortis.CommandHierarchy.get(entity)
        if relationship and relationship.superiorId==deadAlphaId then
            if Mortis.CommandHierarchy.clear(entity,deadAlphaId) then cleared=cleared+1 end
        elseif Mortis.CommandHierarchy.desertedFrom(entity,deadAlphaId) then
            if Mortis.CommandHierarchy.clearFormerSuperior(entity,deadAlphaId) then cleared=cleared+1 end
        end
    end
    return cleared
end

if Mortis.Events and type(Mortis.Events.on)=="function" and not deathListenerInstalled then
    Mortis.Events:on("ThreatKilled",function(zombie,typeId,stableId)
        if typeId==Integration.TYPE_ALPHA_FERAL then
            local direct=Mortis.Groups and Mortis.Groups.getFor(zombie) or nil
            if direct and direct.owner=="ProjectNightfall.AlphaDirect" then Mortis.Groups.disband(direct.id) end
            Alpha.emitDeathCry(zombie,stableId)
            Alpha.releaseLoadedHierarchy(stableId)
        end
    end)
    deathListenerInstalled=true
end


function Alpha.refreshRivalObjective(alpha)
    local relationship=Mortis.CommandHierarchy.get(alpha)
    local objective=relationship and relationship.objective
    if not objective or objective.kind~="destroy-rival-alpha" or type(objective.targetStableId)~="string" then return false end
    local rival=Mortis.Engine and Mortis.Engine.findTrackedByStableId(objective.targetStableId) or nil
    if not rival then return false,"rival-unloaded" end
    local dead=false;pcall(function() dead=rival:isDead()==true end)
    if dead then return false,"rival-dead" end
    Mortis.CommandHierarchy.setObjective(alpha,"destroy-rival-alpha",
        {x=rival:getX(),y=rival:getY(),z=rival:getZ()},worldAgeHours(),objective.targetStableId)
    pcall(function() alpha:setTarget(rival) end)
    pcall(function() alpha:pathToLocationF(rival:getX(),rival:getY(),rival:getZ()) end)
    return true,rival
end

function Alpha.respondToPowerVacuum(entity,payload)
    if not canonical(entity) or type(payload)~="table" or type(payload.alphaId)~="string" then
        return false,"invalid authoritative power vacuum"
    end
    local x,y,z=tonumber(payload.x),tonumber(payload.y),tonumber(payload.z) or 0
    if not x or not y then return false,"power-vacuum position unavailable" end
    local typeId=Integration.getTypeId(entity)
    local relationship=Mortis.CommandHierarchy.get(entity)
    if typeId==Integration.TYPE_ALPHA_FERAL then
        local objective=relationship and relationship.objective
        if objective and objective.kind=="destroy-rival-alpha" then return false,"rivalry takes priority" end
        Mortis.CommandHierarchy.setObjective(entity,"investigate-power-vacuum",{x=x,y=y,z=z},worldAgeHours(),payload.alphaId)
        pcall(function()entity:pathToLocationF(x,y,z)end)
        return true,"alpha-investigate"
    end
    if typeId~=Integration.TYPE_SMART_FERAL then return false,"lower tiers do not understand succession" end
    if relationship and relationship.superiorId and not Ecology.isAlphaDead(relationship.superiorId) then
        return false,"Smart Feral still serves a living Alpha"
    end
    if relationship and relationship.superiorId and Ecology.isAlphaDead(relationship.superiorId) then
        Mortis.CommandHierarchy.clear(entity,relationship.superiorId)
    end
    Mortis.CommandHierarchy.setObjective(entity,"investigate-power-vacuum",{x=x,y=y,z=z},worldAgeHours(),payload.alphaId)
    pcall(function()entity:pathToLocationF(x,y,z)end)
    return true,"independent-smart-investigate"
end

function Alpha.assignSmartLeader(alpha, smart, point)
    if not canonical(alpha) or not canonical(smart) then return false, "server authority required" end
    local prior=Mortis.CommandHierarchy.get(smart)
    if prior and prior.formerSuperiorId then
        if Ecology.isAlphaDead(prior.formerSuperiorId) then
            Mortis.CommandHierarchy.clearFormerSuperior(smart,prior.formerSuperiorId)
        else
            return false,"deserter cannot join another Alpha while former Alpha survival is unresolved"
        end
    end
    local ok, relationship = Mortis.CommandHierarchy.assign(alpha, smart, "smart-feral-commander")
    if not ok then return false, relationship end
    if point then Mortis.CommandHierarchy.setObjective(smart, "rally-to-alpha", point, worldAgeHours()) end
    local group=Mortis.Groups and Mortis.Groups.getFor(smart) or nil
    if group then Mortis.CommandHierarchy.setMemory(smart,"alphaAssignedFollowers",math.max(0,(group.size or 1)-1)) end
    return true, relationship
end


function Alpha.isTraitor(alpha,smart)
    local alphaId=alpha and Mortis.getStableId(alpha) or nil
    return alphaId and Mortis.CommandHierarchy.desertedFrom(smart,alphaId) or false
end

function Alpha.smartWarTargetPriority(observer,target,provoked)
    if Integration.getTypeId(observer)~=Integration.TYPE_SMART_FERAL then return nil end
    local targetType=Integration.getTypeId(target)
    if targetType==Integration.TYPE_ALPHA_FERAL then return 100 end
    if targetType==Integration.TYPE_SMART_FERAL then return 80 end
    return provoked==true and 20 or 0
end


function Alpha.shouldDesert(smart,alpha,metrics,randomUnit)
    local config=ProjectNightfall.Config and ProjectNightfall.Config.POC or {}
    if config.EnableSmartFeralDesertion==false or not canonical(smart) or not canonical(alpha) then return false,0 end
    local relationship=Mortis.CommandHierarchy.get(smart)
    local alphaId=Mortis.getStableId(alpha)
    if not relationship or relationship.superiorId~=alphaId then return false,0 end
    local alphaObjective=Mortis.CommandHierarchy.get(alpha)
    if not alphaObjective or not alphaObjective.objective or alphaObjective.objective.kind~="destroy-rival-alpha" then return false,0 end
    metrics=type(metrics)=="table" and metrics or {}
    local health=math.max(0,math.min(1,tonumber(metrics.health) or 1))
    local assigned=math.max(1,tonumber(metrics.assignedFollowers) or 1)
    local current=math.max(0,tonumber(metrics.currentFollowers) or assigned)
    local loss=math.max(0,math.min(1,1-current/assigned))
    local score=(1-health)*0.55+loss*0.35
    if metrics.isolated==true then score=score+0.15 end
    if metrics.overwhelmed==true then score=score+0.20 end
    -- The known risk of future retribution makes desertion exceptional.
    score=math.max(0,math.min(1,score-(tonumber(config.SmartFeralDesertionRetributionDeterrent) or 0.12)))
    local threshold=math.max(0,math.min(1,tonumber(config.SmartFeralDesertionScoreThreshold) or 0.78))
    if score<threshold then return false,score end
    local chance=math.max(0,math.min(tonumber(config.SmartFeralDesertionMaximumChance) or 0.20,
        (score-threshold)/math.max(0.01,1-threshold)))
    local roll=type(randomUnit)=="function" and tonumber(randomUnit()) or math.random()
    return roll and roll<chance or false,score,chance
end

return Alpha
