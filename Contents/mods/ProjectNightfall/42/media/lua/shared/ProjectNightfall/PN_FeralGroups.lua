local MortisModule = require "Mortis/init"
local ConfigModule = require "ProjectNightfall/PN_Config"
local IntegrationModule = require "ProjectNightfall/PN_MortisIntegration"
local DenState = require "ProjectNightfall/PN_DenState"
require "ProjectNightfall/PN_AlphaMigration"

local Mortis = MortisModule or rawget(_G,"Mortis")
local NightfallNamespace = rawget(_G,"ProjectNightfall")
local Config = (ConfigModule or (NightfallNamespace and NightfallNamespace.Config)).POC
local Integration = IntegrationModule or (NightfallNamespace and NightfallNamespace.MortisIntegration)

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.FeralGroups = ProjectNightfall.FeralGroups or {}
local FeralGroups = ProjectNightfall.FeralGroups
local OWNER = "ProjectNightfall"
local knownGroups = {}
local knownGroupOrder = {}
local knownGroupCursor = 0
local nextUpdateTick = 0
local nextMove = setmetatable({}, { __mode = "k" })
local groupCalls = {}
local groupIntent = {}
local pendingResponses = {}
local pendingResponseHead = 1
local pendingResponseTail = 0
local pendingResponseCount = 0
local responseStats = { queued = 0, processed = 0, dropped = 0, peak = 0 }
local pathStats = {
    updates = 0,
    groupsInspected = 0,
    attempts = 0,
    succeeded = 0,
    failed = 0,
    lastGroupsInspected = 0,
    lastAttempts = 0,
    lastSucceeded = 0,
    lastFailed = 0,
}
local runtimeTick = 0
local spatialBuckets = {}
local spatialEntry = setmetatable({}, { __mode = "k" })
local smartOrder = setmetatable({}, { __mode = "v" })
local smartKnown = setmetatable({}, { __mode = "k" })
local smartHighWater = 0
local smartCursor = 0
local alphaMoveNext=setmetatable({},{__mode="k"})
local denSearchNext=setmetatable({},{__mode="k"})
local nextDenValidationTick=0
local nextDenDefenseTick=0
local nextSmartDenFormationTick=0
local hordeCallNext=setmetatable({},{__mode="k"})
local pendingPowerVacuums={}

local function rememberGroup(id)
    if not id or knownGroups[id] then return end
    knownGroups[id]=true
    knownGroupOrder[#knownGroupOrder+1]=id
end

local function value(entity, method)
    local ok, result = pcall(function() return entity and entity[method] and entity[method](entity) end)
    return ok and tonumber(result) or nil
end

local function position(entity)
    local x, y, z = value(entity, "getX"), value(entity, "getY"), value(entity, "getZ")
    if not x or not y then return nil end
    return x, y, z or 0
end

local function worldAgeHours()
    local gameTime=rawget(_G,"getGameTime") and getGameTime() or nil
    local ok,value=pcall(function()return gameTime and gameTime:getWorldAgeHours()end)
    return ok and tonumber(value) or nil
end

local function alive(entity)
    if not entity then return false end
    local ok, dead = pcall(function() return entity:isDead() end)
    -- Engine objects can become stale between group updates. A failed liveness
    -- query must remove the object from consideration, not keep it active.
    return ok and dead ~= true
end

local function typeOf(entity)
    local ok,result=pcall(Integration.getTypeId,entity)
    return ok and result or nil
end

local function isSmart(entity)
    local typeId=typeOf(entity)
    return typeId == Integration.TYPE_SMART_FERAL or typeId == Integration.TYPE_ALPHA_FERAL
end

local function isRegularFeral(entity)
    return typeOf(entity) == Integration.TYPE_FERAL
end

local function isLowerTier(entity)
    local typeId=typeOf(entity)
    return typeId==Integration.TYPE_FERAL or (typeId~=Integration.TYPE_SMART_FERAL and typeId~=Integration.TYPE_ALPHA_FERAL)
end

local function distanceSquared(a, b)
    local ax, ay, az = position(a)
    local bx, by, bz = position(b)
    if not ax or not bx or math.abs(az - bz) > 0.5 then return math.huge end
    local dx, dy = ax - bx, ay - by
    return dx * dx + dy * dy
end

local function populationMultiplier()
    local root = rawget(_G, "SandboxVars")
    local multiplier = root and root.ZombieConfig and tonumber(root.ZombieConfig.PopulationMultiplier)
    return math.max(0.05, multiplier or 1.0)
end

function FeralGroups.regularFollowerCapacity(group)
    if not group then return 0 end
    local smartCount = 0
    for _, member in ipairs(group.members or {}) do
        if isSmart(member.entity) then smartCount = smartCount + 1 end
    end
    local base = math.max(0, tonumber(Config.SmartFeralBaseFollowerCap) or 8) * populationMultiplier()
    local bonus = math.max(0, tonumber(Config.SmartFeralCapacityPerSmartBonus) or 0.1)
    return math.max(0, math.floor(base * (1 + bonus * smartCount) + 0.5))
end

local function ensureGroup(smart)
    local group = Mortis.Groups.getFor(smart)
    if group and group.owner == OWNER then rememberGroup(group.id); return group end
    if group then return nil end
    local created = Mortis.Groups.create(OWNER, smart)
    if created then rememberGroup(created.id) end
    return created
end

local function ensureAlphaDirectPool(alpha)
    local group=Mortis.Groups.getFor(alpha)
    if group and group.owner=="ProjectNightfall.AlphaDirect" then return group end
    if group then return nil end
    return Mortis.Groups.create("ProjectNightfall.AlphaDirect",alpha)
end

local function emitCommunication(caller, responder, group, kind)
    if not Config.EnableSmartFeralCommunication then return end
    local cooldown = math.max(60, tonumber(Config.SmartFeralScreechCooldownTicks) or 1800)
    if runtimeTick < (groupCalls[group.id] or 0) then return end
    groupCalls[group.id] = runtimeTick + cooldown
    local x, y, z = position(caller)
    local rx, ry, rz = position(responder)
    if not x or not rx then return end
    local event = {
        id = string.format("PN-SCREECH:%s:%d", group.id, runtimeTick),
        groupId = group.id,
        callerId = Mortis.Identity.getStableId(caller),
        responderId = Mortis.Identity.getStableId(responder),
        x = x, y = y, z = z,
        responseX = rx, responseY = ry, responseZ = rz,
        kind = kind or "group-merge",
        tick = runtimeTick,
        expiresTick = runtimeTick + cooldown,
    }
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.SmartFeralCommunication", event) end
    if Mortis.Sound then pcall(Mortis.Sound.play, caller, Config.SmartFeralScreechSound or "MetaScream") end
    local maximum = math.max(1, math.floor(tonumber(Config.SmartFeralMaxPendingResponses) or 256))
    if pendingResponseCount >= maximum then
        responseStats.dropped = responseStats.dropped + 1
        return
    end
    pendingResponseTail = pendingResponseTail + 1
    pendingResponses[pendingResponseTail] = {
        at = runtimeTick + math.max(1, tonumber(Config.SmartFeralScreechResponseDelayTicks) or 45),
        entity = responder,
        event = event,
    }
    pendingResponseCount = pendingResponseCount + 1
    responseStats.queued = responseStats.queued + 1
    responseStats.peak = math.max(responseStats.peak, pendingResponseCount)
end

local function mergeSmart(a, b)
    local ga, gb = ensureGroup(a), ensureGroup(b)
    if not ga or not gb or ga.id == gb.id then return ga or gb end
    local primary, secondary = ga, gb
    if tostring(gb.id) < tostring(ga.id) then primary, secondary = gb, ga end
    local merged = Mortis.Groups.merge(primary.id, secondary.id)
    if merged then
        knownGroups[secondary.id] = nil
        rememberGroup(merged.id)
        emitCommunication(a, b, merged, "group-merge")
    end
    return merged
end

local function processResponses(tick)
    local budget = math.max(1, math.floor(tonumber(Config.SmartFeralResponseBudgetPerTick) or 8))
    local processed = 0
    while pendingResponseCount > 0 and processed < budget do
        local response = pendingResponses[pendingResponseHead]
        if not response then
            pendingResponseHead = pendingResponseHead + 1
            pendingResponseCount = math.max(0, pendingResponseCount - 1)
        elseif tick < response.at then
            break
        else
            pendingResponses[pendingResponseHead] = nil
            pendingResponseHead = pendingResponseHead + 1
            pendingResponseCount = pendingResponseCount - 1
            processed = processed + 1
            responseStats.processed = responseStats.processed + 1
            if alive(response.entity) and Mortis.Sound then
                pcall(Mortis.Sound.play, response.entity, Config.SmartFeralScreechSound or "MetaScream")
            end
            if Mortis.Events then Mortis.Events:emit("ProjectNightfall.SmartFeralCommunicationResponse", response.event) end
        end
    end
    if pendingResponseCount == 0 and pendingResponseHead > 1024 then
        pendingResponses = {}
        pendingResponseHead, pendingResponseTail = 1, 0
    end
    return processed
end

local function bucketKey(x, y, size)
    return tostring(math.floor(x / size)) .. ":" .. tostring(math.floor(y / size))
end

local function spatialSize()
    return math.max(1, tonumber(Config.SmartFeralRecruitmentRadius) or 10,
        tonumber(Config.SmartFeralMergeRadius) or 12)
end

function FeralGroups.observe(entity)
    if not entity or not alive(entity) then return false end
    local x,y=position(entity)
    if not x then return false end
    local key=bucketKey(x,y,spatialSize())
    local prior=spatialEntry[entity]
    if not prior or prior.key~=key then
        local bucket=spatialBuckets[key]
        if not bucket then bucket=setmetatable({}, {__mode="v"}); spatialBuckets[key]=bucket end
        bucket[#bucket+1]=entity
    end
    spatialEntry[entity]={key=key,tick=runtimeTick}
    if isSmart(entity) and not smartKnown[entity] then
        smartHighWater=smartHighWater+1
        smartOrder[smartHighWater]=entity
        smartKnown[entity]=true
    end
    return true
end

local function nearby(entity, size, limit)
    local x, y = position(entity)
    if not x then return {} end
    local bx, by = math.floor(x / size), math.floor(y / size)
    local result = {}
    for ox = -1, 1 do
        for oy = -1, 1 do
            local key=tostring(bx + ox) .. ":" .. tostring(by + oy)
            for _, candidate in pairs(spatialBuckets[key] or {}) do
                local entry=spatialEntry[candidate]
                if candidate ~= entity and entry and entry.key==key and alive(candidate) then
                    result[#result + 1] = candidate
                    if #result >= limit then return result end
                end
            end
        end
    end
    return result
end

function FeralGroups.nearbyEntities(entity,radius,limit)
    FeralGroups.observe(entity)
    radius=math.max(1,tonumber(radius) or spatialSize())
    limit=math.max(1,math.floor(tonumber(limit) or 128))
    local x,y=position(entity);if not x then return {} end
    local size=spatialSize();local bx,by=math.floor(x/size),math.floor(y/size)
    local reach=math.max(1,math.ceil(radius/size));local candidates={}
    for ox=-reach,reach do
        for oy=-reach,reach do
            local key=tostring(bx+ox)..":"..tostring(by+oy)
            for _,candidate in pairs(spatialBuckets[key] or {}) do
                local entry=spatialEntry[candidate]
                if candidate~=entity and entry and entry.key==key and alive(candidate) then
                    candidates[#candidates+1]=candidate
                    if #candidates>=limit then break end
                end
            end
            if #candidates>=limit then break end
        end
        if #candidates>=limit then break end
    end
    local radiusSquared=radius^2
    local result={}
    for _,candidate in ipairs(candidates) do
        if distanceSquared(entity,candidate)<=radiusSquared then result[#result+1]=candidate end
    end
    return result
end

local function nextSmartBatch(limit)
    local result={}
    limit=math.max(1,math.floor(tonumber(limit) or 16))
    if smartHighWater==0 then return result end
    local inspected=0
    while inspected<smartHighWater and #result<limit do
        smartCursor=smartCursor+1
        if smartCursor>smartHighWater then smartCursor=1 end
        inspected=inspected+1
        local entity=smartOrder[smartCursor]
        if entity and alive(entity) and isSmart(entity) then
            FeralGroups.observe(entity)
            result[#result+1]=entity
        elseif entity then
            smartKnown[entity]=nil
            smartOrder[smartCursor]=nil
        end
    end
    return result
end

local function recruit(smart, candidates)
    local group = ensureGroup(smart)
    if not group then return end
    local recruitRadius = math.max(1, tonumber(Config.SmartFeralRecruitmentRadius) or 10)
    local mergeRadius = math.max(1, tonumber(Config.SmartFeralMergeRadius) or recruitRadius)
    for _, candidate in ipairs(candidates) do
        local d2 = distanceSquared(smart, candidate)
        if typeOf(candidate)==Integration.TYPE_ALPHA_FERAL then
            -- An Alpha is a superior command node, never a co-leader/member of
            -- the Smart Feral's own subordinate logical group.
        elseif isSmart(candidate) and d2 <= mergeRadius * mergeRadius then
            group = mergeSmart(smart, candidate) or group
        elseif isRegularFeral(candidate) and d2 <= recruitRadius * recruitRadius then
            group = Mortis.Groups.getFor(smart) or group
            if not Mortis.Groups.getIdFor(candidate)
                and Mortis.Groups.count(group.id, "member") < FeralGroups.regularFollowerCapacity(group) then
                group = Mortis.Groups.join(group.id, candidate) or group
            end
        end
    end
    group = Mortis.Groups.getFor(smart) or group
    local cap = FeralGroups.regularFollowerCapacity(group)
    local followers = {}
    for _, member in ipairs(group.members or {}) do
        if member.role == "member" and isRegularFeral(member.entity) then followers[#followers + 1] = member.entity end
    end
    table.sort(followers, function(a, b)
        return tostring(Mortis.Identity.getStableId(a) or a) < tostring(Mortis.Identity.getStableId(b) or b)
    end)
    for index = cap + 1, #followers do Mortis.Groups.leave(followers[index]) end
end

function FeralGroups.answerAlphaCall(alpha,payload)
    if not alpha or type(payload)~="table" or type(payload.alphaId)~="string" then return 0 end
    local radius=math.max(1,tonumber(Config.AlphaCallSemanticRadius) or 100)
    local candidates=FeralGroups.nearbyEntities(alpha,radius,
        math.max(1,tonumber(Config.AlphaCallSmartResponseLimit) or 32))
    local answered=0
    for _,smart in ipairs(candidates) do
        if typeOf(smart)==Integration.TYPE_SMART_FERAL then
            local ok=ProjectNightfall.AlphaFerals.assignSmartLeader(alpha,smart,payload)
            if ok then
                answered=answered+1
                local localCandidates=FeralGroups.nearbyEntities(smart,
                    tonumber(Config.SmartFeralRecruitmentRadius) or 10,
                    tonumber(Config.SmartFeralMaxCandidatesPerLeader) or 64)
                recruit(smart,localCandidates)
                if Mortis.Sound then pcall(Mortis.Sound.play,smart,Config.SmartFeralScreechSound or "MetaScream") end
            end
        end
    end
    return answered
end

local function activeTarget(entity)
    local ok,target=pcall(function() return entity:getTarget() end)
    return ok and target~=nil
end

function FeralGroups.desertAlphaWar(smart,alpha,options)
    options=type(options)=="table" and options or {}
    if typeOf(smart)~=Integration.TYPE_SMART_FERAL or typeOf(alpha)~=Integration.TYPE_ALPHA_FERAL then
        return nil,"desertion requires Smart Feral and Alpha"
    end
    local alphaId=Mortis.Identity.getStableId(alpha)
    local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
    if not relationship or relationship.superiorId~=alphaId then return nil,"Smart Feral does not serve this Alpha" end
    if type(Mortis.CommandHierarchy.canDesert)=="function" then
        local allowed,reason=Mortis.CommandHierarchy.canDesert(smart,alphaId)
        if not allowed then return nil,reason end
    end
    local group=Mortis.Groups.getFor(smart)
    if not group or group.owner~=OWNER or group.leader~=smart then return nil,"Smart Feral subordinate group unavailable" end
    local radius=math.max(1,tonumber(options.followRadius) or tonumber(Config.SmartFeralDesertionFollowerRadius) or 6)
    local radius2=radius*radius
    local transfer,release={},{}
    for _,member in ipairs(group.members or {}) do
        local entity=member.entity
        if entity~=smart and isLowerTier(entity) then
            if activeTarget(entity) then transfer[#transfer+1]=entity
            elseif distanceSquared(smart,entity)>radius2 then release[#release+1]=entity end
        end
    end
    local direct=ensureAlphaDirectPool(alpha)
    if #transfer>0 and not direct then return nil,"Alpha direct pool unavailable" end
    for _,entity in ipairs(transfer) do
        Mortis.Groups.leave(entity)
        direct=Mortis.Groups.join(direct.id,entity,"member") or direct
    end
    for _,entity in ipairs(release) do Mortis.Groups.leave(entity) end
    local deserted,reason=Mortis.CommandHierarchy.desert(smart,alphaId,options.worldAgeHours)
    if not deserted then return nil,reason end
    local escape=options.escapePoint
    if type(escape)=="table" and tonumber(escape.x) and tonumber(escape.y) then
        pcall(function() smart:pathToLocationF(escape.x,escape.y,tonumber(escape.z) or 0) end)
    end
    return {retained=math.max(0,Mortis.Groups.count(group.id,"member")),transferred=#transfer,released=#release,
        alphaId=alphaId,directGroupId=direct and direct.id or nil}
end

local function moveAssignedSmartToAlpha(tick)
    if not Mortis.CommandHierarchy or not Mortis.Engine or type(Mortis.Engine.findTrackedByStableId)~="function" then return 0 end
    local budget=math.max(1,math.floor(tonumber(Config.AlphaRallyPathBudgetPerUpdate) or 8))
    local moved=0
    for _,smart in ipairs(nextSmartBatch(math.max(budget,tonumber(Config.SmartFeralLeaderBudgetPerUpdate) or 16))) do
        if typeOf(smart)==Integration.TYPE_SMART_FERAL and moved<budget then
            local relationship=Mortis.CommandHierarchy.get(smart)
            local objective=relationship and relationship.objective
            if relationship and objective and (objective.kind=="rally-to-alpha" or objective.kind=="converge-reported-prey")
                and (alphaMoveNext[smart] or 0)<=tick then
                if objective.kind=="converge-reported-prey" then
                    local expires=tonumber(Mortis.CommandHierarchy.getMemory(smart,"reportedPreyExpiresHours"))
                    local now=worldAgeHours()
                    if expires and now and now>expires then
                        Mortis.CommandHierarchy.clearObjective(smart)
                    elseif objective.point then
                        pcall(function()smart:pathToLocationF(objective.point.x,objective.point.y,objective.point.z or 0)end)
                        moved=moved+1
                    end
                    alphaMoveNext[smart]=tick+math.max(30,tonumber(Config.AlphaRallyRepathTicks) or 120)
                else
                local alpha=Mortis.Engine.findTrackedByStableId(relationship.superiorId)
                if alpha and alive(alpha) and typeOf(alpha)==Integration.TYPE_ALPHA_FERAL then
                    local x,y,z=position(alpha)
                    local group=Mortis.Groups.getFor(smart)
                    local current=group and math.max(0,(group.size or 1)-1) or 0
                    local assigned=tonumber(Mortis.CommandHierarchy.getMemory(smart,"alphaAssignedFollowers")) or math.max(1,current)
                    local health=1
                    pcall(function() health=tonumber(smart:getHealth()) or 1 end)
                    local function randomUnit()
                        if type(ZombRand)=="function" then return ZombRand(1000000)/1000000 end
                        return math.random()
                    end
                    local desert=ProjectNightfall.AlphaFerals.shouldDesert(smart,alpha,{
                        health=health,assignedFollowers=assigned,currentFollowers=current,
                        isolated=current==0,overwhelmed=activeTarget(smart) and health<0.35,
                    },randomUnit)
                    if desert and x then
                        local sx,sy,sz=position(smart)
                        local dx,dy=sx-x,sy-y;local length=math.sqrt(dx*dx+dy*dy)
                        if length<0.01 then dx,dy,length=1,0,1 end
                        FeralGroups.desertAlphaWar(smart,alpha,{worldAgeHours=nil,
                            escapePoint={x=sx+dx/length*12,y=sy+dy/length*12,z=sz}})
                    elseif x then
                        pcall(function() smart:pathToLocationF(x,y,z) end);moved=moved+1
                    end
                end
                alphaMoveNext[smart]=tick+math.max(30,tonumber(Config.AlphaRallyRepathTicks) or 120)
                end
            end
        end
    end
    return moved
end

local function updateAlphaRivalries()
    if not Mortis.CommandHierarchy then return 0 end
    local budget=math.max(1,math.floor(tonumber(Config.AlphaRivalryBudgetPerUpdate) or 4))
    local radius=math.max(1,tonumber(Config.AlphaMutualRecognitionRadius) or 20)
    local processed=0
    for _,alpha in ipairs(nextSmartBatch(math.max(budget,tonumber(Config.SmartFeralLeaderBudgetPerUpdate) or 16))) do
        if processed>=budget then break end
        if typeOf(alpha)==Integration.TYPE_ALPHA_FERAL then
            processed=processed+1
            local relationship=Mortis.CommandHierarchy.get(alpha)
            local objective=relationship and relationship.objective
            if not objective or objective.kind~="destroy-rival-alpha" then
                for _,candidate in ipairs(FeralGroups.nearbyEntities(alpha,radius,32)) do
                    if typeOf(candidate)==Integration.TYPE_ALPHA_FERAL then
                        ProjectNightfall.AlphaFerals.lockRivalry(alpha,candidate)
                        break
                    end
                end
            end
            ProjectNightfall.AlphaFerals.refreshRivalObjective(alpha)
            if objective and objective.kind=="investigate-reported-prey" then
                local expires=tonumber(Mortis.CommandHierarchy.getMemory(alpha,"reportedPreyExpiresHours"))
                local now=worldAgeHours()
                if expires and now and now>expires then
                    Mortis.CommandHierarchy.clearObjective(alpha)
                elseif objective.point and (alphaMoveNext[alpha] or 0)<=runtimeTick then
                    pcall(function()alpha:pathToLocationF(objective.point.x,objective.point.y,objective.point.z or 0)end)
                    alphaMoveNext[alpha]=runtimeTick+math.max(30,tonumber(Config.AlphaRallyRepathTicks) or 120)
                end
            end
            relationship=Mortis.CommandHierarchy.get(alpha);objective=relationship and relationship.objective
            if (not objective or objective.kind=="investigate-probable-base") and Mortis.LocationMemory
                and Config.EnableProbableBaseMemory~=false then
                local now=worldAgeHours();local maxAge=math.max(24,tonumber(Config.ProbableBaseMaximumAgeDays)or 30)*24
                local record
                if objective and objective.kind=="investigate-probable-base" then
                    local key=Mortis.CommandHierarchy.getMemory(alpha,"probableBaseKey")
                    record=Mortis.LocationMemory.get(alpha,key,{worldAgeHours=now,maxAgeHours=maxAge})
                    if not record then Mortis.CommandHierarchy.clearObjective(alpha) end
                else
                    record=Mortis.LocationMemory.best(alpha,tonumber(Config.ProbableBaseEvidenceThreshold)or 3,
                        {worldAgeHours=now,maxAgeHours=maxAge})
                    if record then
                        Mortis.CommandHierarchy.setMemory(alpha,"probableBaseKey",record.key)
                        Mortis.CommandHierarchy.setObjective(alpha,"investigate-probable-base",
                            {x=record.x,y=record.y,z=record.z},record.lastObservedWorldAgeHours)
                    end
                end
                if record and (alphaMoveNext[alpha]or 0)<=runtimeTick then
                    pcall(function()alpha:pathToLocationF(record.x,record.y,record.z or 0)end)
                    alphaMoveNext[alpha]=runtimeTick+math.max(30,tonumber(Config.AlphaRallyRepathTicks)or 120)
                end
            end
            -- Betrayal is personal and local. A surviving Alpha recognizes only
            -- loaded deserters it can physically encounter; no global scan or
            -- direct defection is introduced here.
            if not objective or objective.kind~="destroy-rival-alpha" then
                for _,candidate in ipairs(FeralGroups.nearbyEntities(alpha,radius,32)) do
                    if typeOf(candidate)==Integration.TYPE_SMART_FERAL
                        and ProjectNightfall.AlphaFerals.isTraitor(alpha,candidate) then
                        local x,y,z=position(candidate)
                        Mortis.CommandHierarchy.setObjective(alpha,"punish-deserter",{x=x,y=y,z=z},nil,
                            Mortis.Identity.getStableId(candidate))
                        pcall(function() alpha:setTarget(candidate) end)
                        pcall(function() alpha:pathToLocationF(x,y,z) end)
                        break
                    end
                end
            end
        end
    end
    return processed
end

local function processPowerVacuums()
    if Config.EnablePowerVacuumResponses==false or #pendingPowerVacuums==0 then return 0 end
    local pending=pendingPowerVacuums;pendingPowerVacuums={};local responded=0
    local radius=math.max(1,tonumber(Config.AlphaPowerVacuumResponseRadius) or 120)
    local limit=math.max(1,math.floor(tonumber(Config.AlphaPowerVacuumResponseLimit) or 32))
    for _,entry in ipairs(pending) do
        local payload=entry.payload
        for _,candidate in ipairs(FeralGroups.nearbyEntities(entry.source,radius,limit)) do
            local typeId=typeOf(candidate)
            if typeId==Integration.TYPE_ALPHA_FERAL or typeId==Integration.TYPE_SMART_FERAL then
                local ok=ProjectNightfall.AlphaFerals.respondToPowerVacuum(candidate,payload)
                if ok then responded=responded+1 end
            end
        end
    end
    return responded
end

local function linkedSmartCount(alpha,radius)
    local id=Mortis.Identity.getStableId(alpha);if not id then return 0 end
    local count=0
    for _,candidate in ipairs(FeralGroups.nearbyEntities(alpha,radius,128)) do
        if typeOf(candidate)==Integration.TYPE_SMART_FERAL then
            local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(candidate)
            if relationship and relationship.superiorId==id then count=count+1 end
        end
    end
    return count
end

local function safeDenSquare(square)
    if not square then return false end
    local okRoom,inRoom=pcall(function() return square:isInARoom() end)
    if not okRoom or inRoom~=true then return false end
    local solar=ProjectNightfall and ProjectNightfall.SolarUV
    if not solar or type(solar.getExposureAtSquare)~="function" then return false end
    local ok,exposure=pcall(solar.getExposureAtSquare,square)
    return ok and (tonumber(exposure) or 1)<=(tonumber(Config.DenUnsafeNaturalUVThreshold) or 0.01)
end

-- A bounded spoke search deliberately inspects only loaded squares. Negative Z
-- is the engine-visible basement representation; unsupported bunker metadata is
-- not guessed from room names.
local function findLoadedUndergroundCandidate(alpha)
    local cell=rawget(_G,"getCell") and getCell() or nil
    local ax,ay=position(alpha);if not cell or not ax then return nil end
    ax,ay=math.floor(ax),math.floor(ay)
    local radius=math.max(1,math.floor(tonumber(Config.AlphaDenSearchRadius) or 24))
    local minimumZ=math.min(-1,math.floor(tonumber(Config.AlphaDenSearchMinimumZ) or -8))
    local directions={{0,0},{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}
    for distance=0,radius do
        for _,direction in ipairs(directions) do
            if distance==0 and direction~=(directions[1]) then break end
            for z=-1,minimumZ,-1 do
                local ok,square=pcall(function()
                    return cell:getGridSquare(ax+direction[1]*distance,ay+direction[2]*distance,z)
                end)
                if ok and square and safeDenSquare(square) then
                    local x,y=position(square)
                    return {x=x,y=y,z=z,safe=true,underground=true,kind="basement"}
                end
            end
        end
    end
    return nil
end

local function updateAlphaTerritories(tick)
    if Config.EnableAlphaTerritories==false then return 0 end
    local budget=math.max(1,math.floor(tonumber(Config.AlphaDenSearchBudgetPerUpdate) or 2));local processed=0
    for _,alpha in ipairs(nextSmartBatch(math.max(budget,tonumber(Config.SmartFeralLeaderBudgetPerUpdate) or 16))) do
        if processed>=budget then break end
        local territory=typeOf(alpha)==Integration.TYPE_ALPHA_FERAL and DenState.getTerritory(alpha)or nil
        if typeOf(alpha)==Integration.TYPE_ALPHA_FERAL and (denSearchNext[alpha] or 0)<=tick then
            processed=processed+1
            local radius=math.max(8,tonumber(Config.AlphaTerritoryRadius) or 60)
            local count=linkedSmartCount(alpha,radius)
            local minimum=math.max(3,math.floor(tonumber(Config.AlphaTerritoryMinimumSmartFerals) or 3))
            if not territory and count>=minimum then
                local candidate=findLoadedUndergroundCandidate(alpha)
                if candidate then DenState.claim(alpha,count,candidate,{radius=radius}) end
            elseif territory and territory.status=="claimed" then
                local ax,ay=position(alpha);local center=territory.center or{}
                local dx,dy=(ax or center.x or 0)-(center.x or ax or 0),(ay or center.y or 0)-(center.y or ay or 0)
                local migration=ProjectNightfall and ProjectNightfall.AlphaMigration
                -- A destination becomes known only when the loaded Alpha has
                -- physically explored beyond its current territory and found a
                -- valid underground candidate there.
                if migration and dx*dx+dy*dy>radius*radius then
                    local candidate=findLoadedUndergroundCandidate(alpha)
                    if candidate then migration.rememberDestination(alpha,candidate,"alpha-local-observation") end
                end
                local eligible=migration and migration.evaluate(alpha)
                if eligible and territory.knownMigrationDestination then migration.beginKnown(alpha) end
            elseif territory and territory.status=="abandoned" and territory.migration and territory.migration.status=="active" then
                local destination=territory.migration.destination;local ax,ay=position(alpha)
                local dx,dy=(ax or destination.x)-destination.x,(ay or destination.y)-destination.y
                if dx*dx+dy*dy<=radius*radius and count>=minimum then
                    local candidate=findLoadedUndergroundCandidate(alpha)
                    if candidate then DenState.claim(alpha,count,candidate,{radius=radius,worldAgeHours=worldAgeHours()}) end
                end
            end
            denSearchNext[alpha]=tick+math.max(300,tonumber(Config.DenValidationIntervalTicks) or 300)
        end
    end
    return processed
end

local function smartDenCandidate(smart,territory)
    local cell=rawget(_G,"getCell") and getCell() or nil
    local alphaDen=territory and territory.alphaDen
    local alphaLocation=alphaDen and alphaDen.location
    if cell and alphaLocation and not DenState.hasActiveSmartDenAt(territory,alphaLocation.x,alphaLocation.y,0) then
        local ok,square=pcall(function()return cell:getGridSquare(alphaLocation.x,alphaLocation.y,0)end)
        if ok and square and safeDenSquare(square) then
            return {x=alphaLocation.x,y=alphaLocation.y,z=0,safe=true,kind="alpha_guard"},"alpha_guard"
        end
    end
    local shelter=ProjectNightfall and ProjectNightfall.Shelter
    local square=shelter and type(shelter.findNearby)=="function" and shelter.findNearby(smart) or nil
    if not square or not safeDenSquare(square) then return nil end
    local x,y,z=position(square)
    if not x then return nil end
    local center=territory.center or {};local dx,dy=x-(center.x or x),y-(center.y or y)
    if dx*dx+dy*dy>(tonumber(territory.radius) or 60)^2 then return nil end
    return {x=x,y=y,z=z,safe=true,underground=z<0,kind=z<0 and "underground" or "shelter"},"territory"
end

local function establishLoadedSmartDens(tick)
    if Config.EnableAlphaTerritories==false or tick<nextSmartDenFormationTick then return 0 end
    nextSmartDenFormationTick=tick+math.max(60,tonumber(Config.DenValidationIntervalTicks) or 300)
    local budget=math.max(1,math.floor(tonumber(Config.DenValidationBudgetPerUpdate) or 8));local processed=0
    for _,smart in ipairs(nextSmartBatch(budget*2)) do
        if processed>=budget then break end
        if typeOf(smart)==Integration.TYPE_SMART_FERAL and alive(smart) then
            local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
            local territory=relationship and relationship.superiorId and DenState.getTerritory(relationship.superiorId) or nil
            local smartId=Mortis.Identity.getStableId(smart)
            local current=territory and smartId and territory.smartDens and territory.smartDens[smartId]
            if territory and territory.status=="claimed" and (not current or current.status~="active") then
                processed=processed+1
                local candidate,role=smartDenCandidate(smart,territory)
                local alpha=Mortis.Engine and Mortis.Engine.findTrackedByStableId(territory.alphaId)
                if candidate and alpha then DenState.establishSmartDen(alpha,smart,candidate,{role=role}) end
            end
        end
    end
    return processed
end

local function validateLoadedDens(tick)
    if tick<nextDenValidationTick then return 0 end
    nextDenValidationTick=tick+math.max(60,tonumber(Config.DenValidationIntervalTicks) or 300)
    local cell=rawget(_G,"getCell") and getCell() or nil;if not cell then return 0 end
    local budget=math.max(1,math.floor(tonumber(Config.DenValidationBudgetPerUpdate) or 8));local checked=0
    for _,territory in ipairs(DenState.listTerritories(budget)) do
        local alphaDen=territory.status=="claimed" and territory.alphaDen or nil
        if checked>=budget then return checked end
        if alphaDen and alphaDen.status=="active" and alphaDen.location then
            local l=alphaDen.location;local ok,square=pcall(function()return cell:getGridSquare(l.x,l.y,l.z)end)
            if ok and square then
                checked=checked+1
                -- Underground Alpha dens are categorically safe from natural
                -- sunlight. Only actual active artificial UV at the den can
                -- force emergency displacement.
                local uv=rawget(_G,"lightWorks") and lightWorks.UV
                local emitters=uv and type(uv.collectWorldEmitters)=="function" and uv.collectWorldEmitters(square,32) or {}
                local exposure=uv and type(uv.getArtificialExposure)=="function" and uv.getArtificialExposure(square,emitters) or nil
                local artificial=exposure and exposure.uv and tonumber(exposure.uv.artificial) or 0
                if artificial>=(tonumber(Config.AlphaDenArtificialUVUnsafeThreshold)or 0.10) then
                    local alpha=Mortis.Engine and Mortis.Engine.findTrackedByStableId(territory.alphaId)
                    local shelter=ProjectNightfall and ProjectNightfall.Shelter
                    local target=alpha and shelter and type(shelter.findClosestNearby)=="function" and shelter.findClosestNearby(alpha) or nil
                    if target then
                        local candidate={x=target:getX()+0.5,y=target:getY()+0.5,z=target:getZ(),safe=true,kind="emergency-shelter"}
                        DenState.emergencyDisplace(territory.alphaId,candidate,"active artificial UV",worldAgeHours())
                        local migration=ProjectNightfall and ProjectNightfall.AlphaMigration
                        if migration then migration.recordPressure(territory.alphaId,"alpha-den-uv-compromise",
                            tonumber(Config.AlphaMigrationDenUVPressure)or 35) end
                        pcall(function()alpha:pathToLocationF(candidate.x,candidate.y,candidate.z)end)
                    end
                end
            end
        end
        if territory.status=="claimed" then
        for smartId,den in pairs(territory.smartDens or {}) do
            if checked>=budget then return checked end
            if den.status=="active" and den.location then
                local l=den.location;local ok,square=pcall(function()return cell:getGridSquare(l.x,l.y,l.z)end)
                if ok and square then
                    checked=checked+1
                    if not safeDenSquare(square) then
                        DenState.disband(territory.alphaId,smartId,"current shelter exposure unsafe")
                        local migration=ProjectNightfall and ProjectNightfall.AlphaMigration
                        if migration then migration.recordPressure(territory.alphaId,"smart-den-loss",
                            tonumber(Config.AlphaMigrationSmartDenLossPressure)or 5) end
                        local smart=Mortis.Engine and Mortis.Engine.findTrackedByStableId(smartId)
                        local shelter=ProjectNightfall and ProjectNightfall.Shelter
                        local target=smart and shelter and type(shelter.findNearby)=="function" and shelter.findNearby(smart) or nil
                        if target then pcall(function()smart:pathToLocationF(target:getX()+0.5,target:getY()+0.5,target:getZ())end) end
                    end
                end
            end
        end
        end
    end
    return checked
end

local function resumeEmergencyShelters(tick)
    local budget=math.max(1,math.floor(tonumber(Config.AlphaDenSearchBudgetPerUpdate)or 2));local processed=0
    local repath=math.max(30,tonumber(Config.SmartFeralFollowerRepathTicks)or 90)
    for _,territory in ipairs(DenState.listTerritories(budget*2)) do
        if processed>=budget then break end
        local shelter=territory.status=="claimed" and territory.emergencyShelter or nil
        local location=shelter and shelter.location
        if shelter and shelter.status=="active" and location then
            local alpha=Mortis.Engine and Mortis.Engine.findTrackedByStableId(territory.alphaId)
            if alpha and alive(alpha) then
                processed=processed+1
                local ax,ay,az=position(alpha)
                local dx,dy,dz=(ax or location.x)-location.x,(ay or location.y)-location.y,(az or location.z)-location.z
                if dx*dx+dy*dy+dz*dz<=2.25 then
                    DenState.markEmergencySheltered(territory.alphaId,worldAgeHours())
                elseif (alphaMoveNext[alpha]or 0)<=tick then
                    pcall(function()alpha:pathToLocationF(location.x,location.y,location.z)end)
                    alphaMoveNext[alpha]=tick+repath
                end
            end
        end
    end
    return processed
end

local function nightStrength()
    local manager=rawget(_G,"getClimateManager")and getClimateManager()or nil
    local ok,value=pcall(function()return manager and manager:getNightStrength()end)
    return ok and tonumber(value)or nil
end

local function updateActiveMigrations(tick)
    if Config.EnableAlphaMigrationTemporaryShelters==false then return 0 end
    local night=nightStrength();if not night then return 0 end
    local isNight=night>=(tonumber(Config.RiseAtOrAboveNightStrength)or 0.60)
    local isDay=night<=(tonumber(Config.FeralDayDormancyMaxNightStrength)or 0.10)
    if not isNight and not isDay then return 0 end
    local budget=math.max(1,math.floor(tonumber(Config.AlphaDenSearchBudgetPerUpdate)or 2));local processed=0
    for _,territory in ipairs(DenState.listTerritories(budget*2))do
        local migration=territory.status=="abandoned" and territory.migration or nil
        if migration and migration.status=="active" and processed<budget then
            local alpha=Mortis.Engine and Mortis.Engine.findTrackedByStableId(territory.alphaId)
            if alpha and alive(alpha)and(alphaMoveNext[alpha]or 0)<=tick then
                processed=processed+1
                if isDay then
                    local candidate=findLoadedUndergroundCandidate(alpha)
                    if not candidate then
                        local shelter=ProjectNightfall and ProjectNightfall.Shelter
                        local square=shelter and shelter.findClosestNearby and shelter.findClosestNearby(alpha)or nil
                        if square then candidate={x=square:getX()+0.5,y=square:getY()+0.5,z=square:getZ(),safe=true,kind="temporary-shelter"}end
                    end
                    if candidate then
                        DenState.setMigrationTemporaryShelter(territory.alphaId,nil,candidate,worldAgeHours())
                        pcall(function()alpha:pathToLocationF(candidate.x,candidate.y,candidate.z)end)
                    end
                else
                    DenState.clearMigrationTemporaryShelter(territory.alphaId,nil,worldAgeHours())
                    local destination=migration.destination
                    if destination then
                        Mortis.CommandHierarchy.setObjective(alpha,"migrate-territory",destination,worldAgeHours())
                        pcall(function()alpha:pathToLocationF(destination.x,destination.y,destination.z)end)
                    end
                end
                alphaMoveNext[alpha]=tick+math.max(30,tonumber(Config.SmartFeralFollowerRepathTicks)or 90)
            end
            local alphaId=territory.alphaId
            for _,smart in ipairs(nextSmartBatch(math.max(1,tonumber(Config.AlphaMigrationSmartShelterBudgetPerUpdate)or 4)))do
                if typeOf(smart)==Integration.TYPE_SMART_FERAL then
                    local link=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
                    if link and link.superiorId==alphaId and(alphaMoveNext[smart]or 0)<=tick then
                        local smartId=Mortis.Identity.getStableId(smart)
                        if isDay then
                            local shelter=ProjectNightfall and ProjectNightfall.Shelter
                            local square=shelter and shelter.findNearby and shelter.findNearby(smart)or nil
                            if square then
                                local candidate={x=square:getX()+0.5,y=square:getY()+0.5,z=square:getZ(),safe=true,kind="temporary-shelter"}
                                DenState.setMigrationTemporaryShelter(alphaId,smartId,candidate,worldAgeHours())
                                Mortis.CommandHierarchy.setObjective(smart,"migration-day-shelter",candidate,worldAgeHours(),alphaId)
                                pcall(function()smart:pathToLocationF(candidate.x,candidate.y,candidate.z)end)
                            end
                        elseif migration.destination then
                            DenState.clearMigrationTemporaryShelter(alphaId,smartId,worldAgeHours())
                            Mortis.CommandHierarchy.setObjective(smart,"migrate-with-alpha",migration.destination,worldAgeHours(),alphaId)
                            pcall(function()smart:pathToLocationF(migration.destination.x,migration.destination.y,migration.destination.z)end)
                        end
                        alphaMoveNext[smart]=tick+math.max(30,tonumber(Config.SmartFeralFollowerRepathTicks)or 90)
                    end
                end
            end
        end
    end
    return processed
end

local function updateDenDefenses(tick)
    local defense=ProjectNightfall and ProjectNightfall.DenDefense
    local sourceAPI=rawget(_G,"lightWorks") and lightWorks.EmissionSources
    if Config.EnableDenLightSuppression==false or not defense or not sourceAPI then return 0 end
    if tick<nextDenDefenseTick then return 0 end
    nextDenDefenseTick=tick+math.max(60,tonumber(Config.DenLightDefenseIntervalTicks) or 300)
    local budget=math.max(1,math.floor(tonumber(Config.DenLightDefenseSmartBudgetPerUpdate) or 4));local processed=0
    local settings={radius=tonumber(Config.DenLightDefenseRadius) or 20,
        visiblePriority=tonumber(Config.DenLightDefenseVisiblePriority) or 1,
        uvPriority=tonumber(Config.DenLightDefenseUVPriority) or 4}
    for _,territory in ipairs(DenState.listTerritories(budget)) do
        for smartId,den in pairs(territory.smartDens or {}) do
            if processed>=budget then return processed end
            if den.status=="active" and den.location then
                local smart=Mortis.Engine and Mortis.Engine.findTrackedByStableId(smartId)
                if smart and alive(smart) then
                    processed=processed+1
                    local group=Mortis.Groups.getFor(smart)
                    for _,member in ipairs(group and group.members or {}) do
                        if defense.getTask(member.entity) then defense.updateTask(member.entity,Config.DenLightAttackReach) end
                    end
                    local ok,sources=pcall(sourceAPI.collectWorld,den.location,settings.radius,64)
                    if ok and type(sources)=="table" then defense.assign(smart,den,sources,settings) end
                end
            end
        end
    end
    return processed
end

local function formationOffset(entity, distance)
    local id = tostring(Mortis.Identity.getStableId(entity) or entity)
    local hash = 0
    for i = 1, #id do hash = (hash * 33 + string.byte(id, i)) % 360 end
    local angle = math.rad(hash)
    return math.cos(angle) * distance, math.sin(angle) * distance
end

local function moveFollowers(tick)
    local followDistance = math.max(1, tonumber(Config.SmartFeralFollowerDistance) or 3)
    local repathTicks = math.max(15, tonumber(Config.SmartFeralFollowerRepathTicks) or 90)
    local budget=math.max(1,math.floor(tonumber(Config.SmartFeralFollowerPathBudgetPerUpdate) or 16))
    local attempts,successes,failures,inspected=0,0,0,0
    local highWater=#knownGroupOrder
    while inspected<highWater and attempts<budget do
        knownGroupCursor=knownGroupCursor+1
        if knownGroupCursor>highWater then knownGroupCursor=1 end
        inspected=inspected+1
        local id=knownGroupOrder[knownGroupCursor]
        if id and knownGroups[id] then
        local group = Mortis.Groups.get(id)
        if not group then
            knownGroups[id] = nil
            knownGroupOrder[knownGroupCursor]=false
        else
            Mortis.Groups.prune(id, alive)
            group = Mortis.Groups.get(id)
            if group and alive(group.leader) then
                local lx, ly, lz = position(group.leader)
                for _, member in ipairs(group.members) do
                    local entity = member.entity
                    if member.role == "member" and isRegularFeral(entity)
                        and (nextMove[entity] or 0) <= tick
                        and distanceSquared(entity, group.leader) > followDistance * followDistance then
                        local ox, oy = formationOffset(entity, math.max(1, followDistance * 0.65))
                        attempts=attempts+1
                        local ok=pcall(function() entity:pathToLocationF(lx + ox, ly + oy, lz) end)
                        if ok then successes=successes+1 else failures=failures+1 end
                        -- Failed path requests are throttled too. A stale or temporarily
                        -- invalid entity must not consume the full budget every update.
                        nextMove[entity] = tick + repathTicks
                        if attempts>=budget then break end
                    end
                end
            end
        end
        end
    end
    pathStats.updates=pathStats.updates+1
    pathStats.groupsInspected=pathStats.groupsInspected+inspected
    pathStats.attempts=pathStats.attempts+attempts
    pathStats.succeeded=pathStats.succeeded+successes
    pathStats.failed=pathStats.failed+failures
    pathStats.lastGroupsInspected=inspected
    pathStats.lastAttempts=attempts
    pathStats.lastSucceeded=successes
    pathStats.lastFailed=failures
    return attempts
end

function FeralGroups.update(_, tick)
    if not Config.EnableSmartFeralHordes then
        for id in pairs(knownGroups) do Mortis.Groups.disband(id); knownGroups[id] = nil end
        knownGroupOrder={}; knownGroupCursor=0
        pendingResponses={}; pendingResponseHead,pendingResponseTail,pendingResponseCount=1,0,0
        return false
    end
    tick = tonumber(tick) or 0
    runtimeTick = tick
    processResponses(tick)
    processPowerVacuums()
    moveAssignedSmartToAlpha(tick)
    if tick < nextUpdateTick then return false end
    nextUpdateTick = tick + math.max(30, tonumber(Config.SmartFeralGroupUpdateTicks) or 180)
    updateAlphaRivalries()
    updateAlphaTerritories(tick)
    resumeEmergencyShelters(tick)
    updateActiveMigrations(tick)
    establishLoadedSmartDens(tick)
    validateLoadedDens(tick)
    updateDenDefenses(tick)
    local radius = spatialSize()
    local smart = nextSmartBatch(tonumber(Config.SmartFeralLeaderBudgetPerUpdate) or 16)
    local limit = math.max(8, tonumber(Config.SmartFeralMaxCandidatesPerLeader) or 64)
    for _, leader in ipairs(smart) do
        if typeOf(leader)==Integration.TYPE_SMART_FERAL then recruit(leader, nearby(leader, radius, limit)) end
    end
    moveFollowers(tick)
    return true
end

if Mortis.Events and type(Mortis.Events.on)=="function" then
    Mortis.Events:on("ProjectNightfall.AlphaCall",function(alpha,payload)
        FeralGroups.answerAlphaCall(alpha,payload)
    end)
    Mortis.Events:on("ProjectNightfall.AlphaDeathCry",function(source,payload)
        if source and type(payload)=="table" then
            local cap=math.max(1,math.floor(tonumber(Config.AlphaPowerVacuumResponseLimit) or 32))
            if #pendingPowerVacuums<cap then pendingPowerVacuums[#pendingPowerVacuums+1]={source=source,payload=payload} end
        end
    end)
end

function FeralGroups.getDiagnostics()
    return {
        pendingResponses = pendingResponseCount,
        responsesQueued = responseStats.queued,
        responsesProcessed = responseStats.processed,
        responsesDropped = responseStats.dropped,
        responseQueuePeak = responseStats.peak,
        followerPathUpdates = pathStats.updates,
        followerGroupsInspected = pathStats.groupsInspected,
        followerPathAttempts = pathStats.attempts,
        followerPathSucceeded = pathStats.succeeded,
        followerPathFailed = pathStats.failed,
        followerLastGroupsInspected = pathStats.lastGroupsInspected,
        followerLastPathAttempts = pathStats.lastAttempts,
        followerLastPathSucceeded = pathStats.lastSucceeded,
        followerLastPathFailed = pathStats.lastFailed,
    }
end

function FeralGroups.shareIntent(entity, kind, x, y, z, tick)
    local group = Mortis.Groups.getFor(entity)
    if not group or group.owner ~= OWNER or not isSmart(entity) then return false end
    tick = tonumber(tick) or runtimeTick
    groupIntent[group.id] = {
        kind = tostring(kind or "investigate"), x = tonumber(x), y = tonumber(y), z = tonumber(z) or 0,
        observerId = Mortis.Identity.getStableId(entity), observedTick = tick,
        expiresTick = tick + math.max(30, tonumber(Config.SmartFeralSharedIntentLifetimeTicks) or 600),
    }
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.SmartFeralSharedIntent", group.id, groupIntent[group.id]) end
    return true
end

-- Reports a real, currently visible prey location upward through the Alpha
-- hierarchy. The report is a last-known point with a short lifetime; it never
-- tracks the player after sight is lost and never scans beyond loaded spatial
-- buckets around the Alpha.
function FeralGroups.reportPrey(smart,target,tick)
    local x,y,z=position(target)
    if not x or typeOf(smart)~=Integration.TYPE_SMART_FERAL then return false,"invalid prey report" end
    tick=tonumber(tick) or runtimeTick
    FeralGroups.shareIntent(smart,"player-sighting",x,y,z,tick)
    if Config.EnableAlphaHordeCalls==false or tick<(hordeCallNext[smart] or 0) then return false,"Horde Call cooling down" end
    local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
    local alphaId=relationship and relationship.superiorId
    local alpha=alphaId and Mortis.Engine and Mortis.Engine.findTrackedByStableId(alphaId) or nil
    if not alpha or not alive(alpha) or typeOf(alpha)~=Integration.TYPE_ALPHA_FERAL then return false,"no loaded living Alpha" end
    local now=worldAgeHours();local lifetime=math.max(0.01,tonumber(Config.AlphaReportedPreyLifetimeHours) or 0.5)
    local point={x=x,y=y,z=z};local expires=now and now+lifetime or nil
    local alphaRelationship=Mortis.CommandHierarchy.get(alpha)
    local strategic=alphaRelationship and alphaRelationship.objective
    if strategic and (strategic.kind=="destroy-rival-alpha" or strategic.kind=="punish-deserter") then
        return false,"Alpha strategic conflict takes priority"
    end
    if Config.EnableProbableBaseMemory~=false and Mortis.LocationMemory then
        local record=Mortis.LocationMemory.observe(alpha,"player-sighting",point,
            tonumber(Config.ProbableBasePlayerSightingWeight)or 1,now,
            {mergeRadius=tonumber(Config.ProbableBaseMergeRadius)or 8,
             maxRecords=tonumber(Config.ProbableBaseMaximumRecords)or 32})
        local threshold=math.max(1,tonumber(Config.ProbableBaseEvidenceThreshold)or 3)
        if record and record.score>=threshold and record.observations>=2 then
            local prior=Mortis.CommandHierarchy.getMemory(alpha,"probableBaseKey")
            Mortis.CommandHierarchy.setMemory(alpha,"probableBaseKey",record.key)
            Mortis.CommandHierarchy.setMemory(alpha,"probableBaseX",record.x)
            Mortis.CommandHierarchy.setMemory(alpha,"probableBaseY",record.y)
            Mortis.CommandHierarchy.setMemory(alpha,"probableBaseZ",record.z)
            if prior~=record.key and Mortis.Events then
                Mortis.Events:emit("ProjectNightfall.ProbableBaseIdentified",alpha,record)
            end
        end
    end
    hordeCallNext[smart]=tick+math.max(60,tonumber(Config.AlphaHordeCallCooldownTicks) or 1800)
    if Mortis.Sound then
        pcall(Mortis.Sound.play,smart,Config.SmartFeralScreechSound or "MetaScream")
        pcall(Mortis.Sound.emitWorldSound,smart,Config.AlphaHordeCallWorldSoundRadius or 45,
            Config.AlphaHordeCallWorldSoundVolume or 45)
    end
    Mortis.CommandHierarchy.setObjective(alpha,"investigate-reported-prey",point,now,Mortis.Identity.getStableId(target))
    if expires then Mortis.CommandHierarchy.setMemory(alpha,"reportedPreyExpiresHours",expires) end
    pcall(function()alpha:pathToLocationF(x,y,z)end)
    local radius=math.max(1,tonumber(Config.AlphaHordeCallSemanticRadius) or 120)
    local limit=math.max(1,math.floor(tonumber(Config.AlphaHordeCallResponseLimit) or 32));local mobilized=0
    for _,candidate in ipairs(FeralGroups.nearbyEntities(alpha,radius,limit)) do
        if typeOf(candidate)==Integration.TYPE_SMART_FERAL then
            local link=Mortis.CommandHierarchy.get(candidate)
            if link and link.superiorId==alphaId then
                Mortis.CommandHierarchy.setObjective(candidate,"converge-reported-prey",point,now,Mortis.Identity.getStableId(target))
                if expires then Mortis.CommandHierarchy.setMemory(candidate,"reportedPreyExpiresHours",expires) end
                mobilized=mobilized+1
            end
        end
    end
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.AlphaHordeCall",smart,
        {alphaId=alphaId,x=x,y=y,z=z,observedWorldAgeHours=now,expiresWorldAgeHours=expires,mobilized=mobilized}) end
    return true,mobilized
end


-- Extension point for evidence gathered through actual local observation
-- (barricades, repeated activity, generator noise, combat). It accepts evidence
-- only from a Smart Feral already linked to a loaded living Alpha.
function FeralGroups.recordAlphaLocationEvidence(smart,kind,point,strength)
    if Config.EnableProbableBaseMemory==false or not Mortis.LocationMemory then return nil,"location memory disabled" end
    local relationship=Mortis.CommandHierarchy and Mortis.CommandHierarchy.get(smart)
    local alphaId=relationship and relationship.superiorId
    local alpha=alphaId and Mortis.Engine and Mortis.Engine.findTrackedByStableId(alphaId) or nil
    if typeOf(smart)~=Integration.TYPE_SMART_FERAL or not alpha or not alive(alpha)
        or typeOf(alpha)~=Integration.TYPE_ALPHA_FERAL then return nil,"observer is not linked to a loaded Alpha" end
    return Mortis.LocationMemory.observe(alpha,kind,point,strength,worldAgeHours(),
        {mergeRadius=tonumber(Config.ProbableBaseMergeRadius)or 8,
         maxRecords=tonumber(Config.ProbableBaseMaximumRecords)or 32})
end

function FeralGroups.shareEffigyHunt(entity,details,tick)
    local group=Mortis.Groups.getFor(entity)
    if not group or group.owner~=OWNER or not isSmart(entity) or type(details)~="table" then return false end
    local x,y,z=tonumber(details.x),tonumber(details.y),tonumber(details.z) or 0
    local untilHours=tonumber(details.huntUntilHours)
    local id=details.effigyId
    if not x or x~=x or not y or y~=y or not untilHours or untilHours~=untilHours
        or type(id)~="string" or id=="" or #id>256 then return false end
    tick=tonumber(tick) or runtimeTick
    local ownerKey=type(details.ownerPlayerKey)=="string" and details.ownerPlayerKey or nil
    if ownerKey and #ownerKey>256 then ownerKey=nil end
    groupIntent[group.id]={
        kind="effigy-hunt",x=x,y=y,z=z,effigyId=id,huntUntilHours=untilHours,
        enraged=details.enraged==true,ownerPlayerKey=ownerKey,
        observerId=Mortis.Identity.getStableId(entity),observedTick=tick,
        expiresTick=tick+math.max(30,tonumber(Config.SmartFeralSharedIntentLifetimeTicks)or 600),
    }
    if Mortis.Events then Mortis.Events:emit("ProjectNightfall.SmartFeralSharedIntent",group.id,groupIntent[group.id])end
    return true
end

function FeralGroups.applySharedEffigyHunt(entity,state,nowHours,tick)
    if type(state)~="table" then return false end
    local intent=FeralGroups.getSharedIntent(entity,tick)
    nowHours=tonumber(nowHours)
    if not intent or intent.kind~="effigy-hunt" or not nowHours
        or not intent.huntUntilHours or intent.huntUntilHours<=nowHours then return false end
    if state.effigyHuntUntilHours and state.effigyHuntUntilHours>=intent.huntUntilHours then return false end
    state.effigyHuntId=intent.effigyId;state.effigyHuntUntilHours=intent.huntUntilHours
    state.effigyHuntOriginX=intent.x;state.effigyHuntOriginY=intent.y;state.effigyHuntOriginZ=intent.z
    state.effigyHuntEnraged=intent.enraged==true
    return true,intent.ownerPlayerKey
end

function FeralGroups.getSharedIntent(entity, tick)
    local id = Mortis.Groups.getIdFor(entity)
    local intent = id and groupIntent[id] or nil
    if intent and (tonumber(tick) or runtimeTick) <= intent.expiresTick then return intent end
    if id then groupIntent[id] = nil end
    return nil
end

return FeralGroups
