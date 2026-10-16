local config = {
    EnableSmartFeralHordes = true,
    SmartFeralBaseFollowerCap = 2,
    SmartFeralCapacityPerSmartBonus = 0.10,
    SmartFeralRecruitmentRadius = 10,
    SmartFeralMergeRadius = 10,
    SmartFeralFollowerDistance = 2,
    SmartFeralGroupUpdateTicks = 30,
    SmartFeralFollowerRepathTicks = 15,
    SmartFeralFollowerPathBudgetPerUpdate = 5,
    SmartFeralMaxCandidatesPerLeader = 64,
    EnableSmartFeralCommunication = true,
    SmartFeralScreechCooldownTicks = 1800,
    SmartFeralScreechResponseDelayTicks = 45,
    SmartFeralResponseBudgetPerTick = 1,
    SmartFeralMaxPendingResponses = 8,
    SmartFeralSharedIntentLifetimeTicks = 600,
    EnableAlphaHordeCalls = true,
    AlphaHordeCallCooldownTicks = 1800,
    AlphaHordeCallSemanticRadius = 120,
    AlphaHordeCallResponseLimit = 32,
    AlphaReportedPreyLifetimeHours = 0.5,
    EnableProbableBaseMemory = true,
    ProbableBaseMergeRadius = 8,
    ProbableBaseEvidenceThreshold = 3,
    ProbableBasePlayerSightingWeight = 1,
    ProbableBaseMaximumRecords = 32,
}
package.loaded["ProjectNightfall/PN_Config"] = { POC = config }
ProjectNightfall={AlphaFerals={lockRivalry=function()return false end,refreshRivalObjective=function()return false end,
    isTraitor=function()return false end,shouldDesert=function()return false end}}

local types = setmetatable({}, { __mode = "k" })
local ids = setmetatable({}, { __mode = "k" })
local nextGroup = 0
local groups, memberships = {}, setmetatable({}, { __mode = "k" })
local function snap(group)
    if not group then return nil end
    local members = {}
    for entity, role in pairs(group.members) do members[#members + 1] = { entity = entity, role = role } end
    return { id = group.id, owner = group.owner, leader = group.leader, members = members, size = #members }
end
local Groups = {}
function Groups.create(owner, leader)
    nextGroup = nextGroup + 1
    local group = { id = "G" .. nextGroup, owner = owner, leader = leader, members = { [leader] = "leader" } }
    groups[group.id], memberships[leader] = group, group.id
    return snap(group)
end
function Groups.get(id) return snap(groups[type(id) == "table" and id.id or id]) end
function Groups.getFor(entity) return snap(groups[memberships[entity]]) end
function Groups.getIdFor(entity) return memberships[entity] end
function Groups.count(id, role)
    local count = 0
    for _, value in pairs(groups[type(id) == "table" and id.id or id].members) do
        if not role or value == role then count = count + 1 end
    end
    return count
end
function Groups.join(id, entity)
    local group = groups[type(id) == "table" and id.id or id]
    group.members[entity], memberships[entity] = "member", group.id
    return snap(group)
end
function Groups.merge(primaryId, secondaryId)
    local primary, secondary = groups[primaryId], groups[secondaryId]
    for entity, role in pairs(secondary.members) do
        primary.members[entity] = role == "leader" and "co-leader" or role
        memberships[entity] = primary.id
    end
    groups[secondaryId] = nil
    return snap(primary)
end
function Groups.prune(id, predicate)
    local group = groups[id]
    for entity in pairs(group.members) do
        if not predicate(entity) then group.members[entity], memberships[entity] = nil, nil end
    end
    return snap(group), 0
end
function Groups.leave(entity)
    local id, group = memberships[entity], groups[memberships[entity]]
    if not group then return false end
    group.members[entity], memberships[entity] = nil, nil
    return true
end
function Groups.disband(id)
    local group = groups[id]
    if not group then return false end
    for entity in pairs(group.members) do memberships[entity] = nil end
    groups[id] = nil
    return true
end

local sounds, events = 0, {}
local hierarchy=setmetatable({},{__mode="k"})
local locationRecords=setmetatable({},{__mode="k"})
local Mortis = {
    Groups = Groups,
    Identity = { getStableId = function(entity) return ids[entity] end },
    Sound = { play = function() sounds = sounds + 1; return true end,emitWorldSound=function()return true end },
    Events = { emit = function(_, name, ...) events[#events + 1] = { name, ... } end },
    CommandHierarchy={
        get=function(entity)return hierarchy[entity]end,
        setObjective=function(entity,kind,point,now,target)
            hierarchy[entity]=hierarchy[entity]or{};hierarchy[entity].objective={kind=kind,point=point,targetStableId=target};return true
        end,
        setMemory=function(entity,key,value)hierarchy[entity]=hierarchy[entity]or{};hierarchy[entity].memory=hierarchy[entity].memory or{};hierarchy[entity].memory[key]=value;return true end,
        getMemory=function(entity,key)return hierarchy[entity]and hierarchy[entity].memory and hierarchy[entity].memory[key]end,
        clearObjective=function(entity)if hierarchy[entity]then hierarchy[entity].objective=nil end;return true end,
    },
    LocationMemory={observe=function(entity,kind,point,strength)
        local record=locationRecords[entity]or{key="2:2:0",score=0,observations=0,evidence={}}
        record.score=record.score+strength;record.observations=record.observations+1
        record.x,record.y,record.z=point.x,point.y,point.z;record.evidence[kind]=(record.evidence[kind]or 0)+strength
        locationRecords[entity]=record;return record
    end,best=function(entity,threshold)local record=locationRecords[entity];return record and record.score>=threshold and record or nil end,
    get=function(entity,key)local record=locationRecords[entity];return record and record.key==key and record or nil end},
}
package.loaded["Mortis/init"] = Mortis

local Integration = {
    TYPE_FERAL = "Feral",
    TYPE_SMART_FERAL = "Smart",
    TYPE_ALPHA_FERAL = "Alpha",
    getTypeId = function(entity) return types[entity] end,
}
package.loaded["ProjectNightfall/PN_MortisIntegration"] = Integration
SandboxVars = { ZombieConfig = { PopulationMultiplier = 2.0 } }

local function zombie(id, kind, x, y)
    local entity = { x = x, y = y, z = 0, paths = 0 }
    ids[entity], types[entity] = id, kind
    function entity:getX() return self.x end
    function entity:getY() return self.y end
    function entity:getZ() return self.z end
    function entity:isDead() return false end
    function entity:pathToLocationF(px, py, pz)
        if self.failPath then error("stale path target") end
        self.paths = self.paths + 1
        self.lastPath = { px, py, pz }
    end
    return entity
end

local smartA = zombie("A", "Smart", 0, 0)
local smartB = zombie("B", "Smart", 1, 0)
local alpha=zombie("ALPHA","Alpha",5,0)
local tracked = { [smartA] = true, [smartB] = true, [alpha]=true }
Mortis.Engine={findTrackedByStableId=function(id)return id=="ALPHA" and alpha or nil end}
hierarchy[smartA]={superiorId="ALPHA"};hierarchy[smartB]={superiorId="ALPHA"}
getGameTime=function()return{getWorldAgeHours=function()return 24 end}end
local ferals={}
for i = 1, 8 do
    ferals[i]=zombie("F" .. i, "Feral", 3 + i * 0.1, 0)
    tracked[ferals[i]]=true
    ferals[i].failPath=true
end

local FeralGroups = require "ProjectNightfall/PN_FeralGroups"
assert(not FeralGroups.observe({isDead=function() error("stale") end}),
    "throwing liveness checks must fail closed")
for entity in pairs(tracked) do assert(FeralGroups.observe(entity)) end
assert(FeralGroups.update(tracked, 30))
local group = assert(Groups.getFor(smartA))
assert(Groups.getIdFor(smartB) == group.id, "nearby Smart Ferals should merge deterministically")
assert(FeralGroups.regularFollowerCapacity(group) == 5, "population and Smart Feral capacity scaling should apply")
assert(Groups.count(group.id, "member") <= 5, "regular Feral follower cap must be enforced")
assert(group.size >= 3, "local regular Ferals should be recruited")
assert(sounds == 1, "group merge should emit a positional caller screech")
assert(events[1][1] == "ProjectNightfall.SmartFeralCommunication")
local communication = FeralGroups.getDiagnostics()
assert(communication.pendingResponses == 1 and communication.responsesQueued == 1)
assert(communication.followerPathAttempts == config.SmartFeralFollowerPathBudgetPerUpdate)
assert(communication.followerPathSucceeded == 0)
assert(communication.followerPathFailed == config.SmartFeralFollowerPathBudgetPerUpdate)
assert(communication.followerLastPathAttempts == communication.followerPathAttempts)
assert(communication.followerLastGroupsInspected <= 1)

assert(FeralGroups.shareIntent(smartA, "player-sighting", 8, 9, 0, 30))
local intent = assert(FeralGroups.getSharedIntent(smartB, 31))
assert(intent.x == 8 and intent.y == 9 and intent.observerId == "A")

assert(FeralGroups.shareEffigyHunt(smartA,{effigyId="effigy-9",x=12,y=13,z=0,
    huntUntilHours=48,enraged=true,ownerPlayerKey="username:builder"},32))
local huntState={}
local adopted,ownerKey=FeralGroups.applySharedEffigyHunt(smartB,huntState,24,33)
assert(adopted and ownerKey=="username:builder" and huntState.effigyHuntId=="effigy-9")
assert(huntState.effigyHuntUntilHours==48 and huntState.effigyHuntEnraged)
assert(not FeralGroups.applySharedEffigyHunt(smartB,huntState,24,34),"same/older hunt must not overwrite state")

local moved = 0
for entity in pairs(tracked) do moved = moved + entity.paths end
assert(moved == 0, "failed follower path commands must be contained")
assert(not FeralGroups.update(tracked, 31), "group work should be throttled")
for _,feral in ipairs(ferals) do feral.failPath=false end
FeralGroups.update(tracked, 75)
assert(sounds == 2, "cooperating Smart Feral should answer after the configured delay")
communication = FeralGroups.getDiagnostics()
assert(communication.pendingResponses == 0 and communication.responsesProcessed == 1)
assert(communication.responsesDropped == 0 and communication.responseQueuePeak == 1)
assert(communication.followerPathAttempts == config.SmartFeralFollowerPathBudgetPerUpdate * 2)
assert(communication.followerPathSucceeded + communication.followerPathFailed == communication.followerPathAttempts)
assert(communication.followerPathFailed == config.SmartFeralFollowerPathBudgetPerUpdate)
assert(communication.followerPathSucceeded == config.SmartFeralFollowerPathBudgetPerUpdate)

local player=zombie("PLAYER","Player",20,21)
local reported,mobilized=FeralGroups.reportPrey(smartA,player,100)
assert(reported and mobilized==2,"Horde Call must mobilize only the two linked loaded Smart Ferals")
assert(hierarchy[alpha].objective.kind=="investigate-reported-prey")
assert(hierarchy[smartA].objective.kind=="converge-reported-prey" and hierarchy[smartB].objective.kind=="converge-reported-prey")
assert(hierarchy[smartA].objective.point.x==20 and hierarchy[smartA].memory.reportedPreyExpiresHours==24.5)
assert(not FeralGroups.reportPrey(smartA,player,101),"Horde Call cooldown must suppress repeated visible-target reports")
assert(FeralGroups.reportPrey(smartA,player,1900))
assert(FeralGroups.reportPrey(smartA,player,3700))
assert(hierarchy[alpha].memory.probableBaseKey=="2:2:0","repeated local observations must promote persistent probable-location memory")

print("Project Nightfall Smart Feral group checks passed")
