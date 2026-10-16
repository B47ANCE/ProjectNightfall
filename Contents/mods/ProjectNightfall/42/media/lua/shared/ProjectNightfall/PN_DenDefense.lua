local Mortis=require "Mortis/init"
local Sources=require "lightWorks/lightWorks_EmissionSources"

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.DenDefense=ProjectNightfall.DenDefense or {}
local Defense=ProjectNightfall.DenDefense
local tasks=setmetatable({},{__mode="k"})

local function finite(value)value=tonumber(value);return value and value==value and value~=math.huge and value~=-math.huge and value or nil end
local function position(entity)
    if type(entity)=="table" and finite(entity.x) and finite(entity.y) then return finite(entity.x),finite(entity.y),finite(entity.z) or 0 end
    local ok,x,y,z=pcall(function()return entity:getX(),entity:getY(),entity:getZ()end)
    return ok and finite(x),ok and finite(y),ok and (finite(z) or 0)
end
local function distance2(a,b)
    local ax,ay,az=position(a);local bx,by,bz=position(b)
    if not ax or not bx or math.abs(az-bz)>0.5 then return math.huge end
    return (ax-bx)^2+(ay-by)^2
end

function Defense.selectSource(den,sources,config)
    local location=type(den)=="table" and den.location or nil;if not location then return nil end
    config=type(config)=="table" and config or {}
    local radius=math.max(1,finite(config.radius) or 20);local best,bestScore
    for _,source in ipairs(type(sources)=="table" and sources or {}) do
        local destruction=type(source)=="table" and source.destroy or nil
        local d2=distance2(location,source)
        if type(source)=="table" and source.emitting==true and source.on==true and source.powered==true and d2<=radius^2
            and type(destruction)=="table" and destruction.supported==true and type(destruction.requestAttack)=="function" then
            local uv=type(source.channels)=="table" and source.channels.UV==true
            local priority=uv and (finite(config.uvPriority) or 4) or (finite(config.visiblePriority) or 1)
            local score=priority*1000-d2+(finite(source.intensity) or 0)*10
            if not bestScore or score>bestScore then best,bestScore=source,score end
        end
    end
    return best,bestScore
end

-- Nightfall owns the action requirement; M.O.R.T.I.S. supplies canonical
-- regional function. An arm without its functional hand is not a striking limb.
function Defense.canAttackEmitter(entity)
    if not Mortis.Authority or Mortis.Authority.canWriteCanonicalState(entity)~=true then
        return false,"server authority required"
    end
    local api=Mortis.AnatomyCapabilities
    if not api or type(api.functionalSnapshot)~="function" then return false,"anatomy API unavailable" end
    local ok,snapshot=pcall(api.functionalSnapshot,entity)
    local regions=ok and type(snapshot)=="table" and snapshot.regionFunction
    if type(regions)~="table" then return false,"anatomy unavailable" end
    local function functioning(id)
        local value=regions[id]
        return type(value)=="number" and value==value and value>0 and value<=1
    end
    if (functioning("leftArm") and functioning("leftHand"))
        or (functioning("rightArm") and functioning("rightHand")) then return true end
    return false,"functional arm and hand required"
end

local function cancelTask(pawn,reason)
    local task=tasks[pawn]
    if task and task.objectivePoint and Mortis.CommandHierarchy then
        local hierarchy=Mortis.CommandHierarchy.get(pawn)
        local objective=hierarchy and hierarchy.objective
        local point=objective and objective.point
        local expected=task.objectivePoint
        if objective and objective.kind=="destroy-den-emitter" and point
            and point.x==expected.x and point.y==expected.y and point.z==expected.z then
            local cleared,err=Mortis.CommandHierarchy.clearObjective(pawn)
            if not cleared then return false,err end
        end
    end
    tasks[pawn]=nil
    return false,reason
end

local function availablePawn(group)
    for _,member in ipairs(group and group.members or {}) do
        if member.role=="member" and member.entity and not tasks[member.entity]
            and Defense.canAttackEmitter(member.entity) then return member.entity end
    end
end

function Defense.assign(smart,den,sources,config)
    if not Mortis.Authority or Mortis.Authority.canWriteCanonicalState(smart)~=true then return nil,"server authority required" end
    local group=Mortis.Groups and Mortis.Groups.getFor(smart)
    if not group or group.leader~=smart then return nil,"Smart Feral subordinate group unavailable" end
    local source=Defense.selectSource(den,sources,config);if not source then return nil,"no supported active emitter" end
    local pawn=availablePawn(group);if not pawn then return nil,"no available subordinate pawn" end
    local point={x=source.x,y=source.y,z=source.z}
    if not Mortis.CommandHierarchy then return nil,"command hierarchy unavailable" end
    local assigned,reason=Mortis.CommandHierarchy.setObjective(pawn,"destroy-den-emitter",point,nil)
    if not assigned then return nil,reason end
    tasks[pawn]={source=source,den=den,objectivePoint=point}
    local moved,pathResult=pcall(function()return pawn:pathToLocationF(point.x,point.y,point.z)end)
    if not moved or pathResult==false then
        tasks[pawn].cancelReason="pawn path request failed"
        cancelTask(pawn,tasks[pawn].cancelReason)
        return nil,"pawn path request failed"
    end
    return pawn,source
end

function Defense.updateTask(pawn,reach)
    local task=tasks[pawn];if not task then return false,"no den-defense task" end
    if not Mortis.Authority or Mortis.Authority.canWriteCanonicalState(pawn)~=true then return false,"server authority required" end
    if task.cancelReason then return cancelTask(pawn,task.cancelReason) end
    local capable,reason=Defense.canAttackEmitter(pawn)
    if not capable then
        task.cancelReason=reason
        return cancelTask(pawn,reason)
    end
    local current=Sources.inspect(task.source.object)
    if not current then task.cancelReason="source stopped emitting";return cancelTask(pawn,task.cancelReason) end
    if distance2(pawn,current)>(math.max(0.5,finite(reach) or 1.5)^2) then return false,"approaching source" end
    local ok,reason=Sources.requestPhysicalAttack(current,pawn)
    -- Keep the assignment until the provider reports that emission has really
    -- stopped. One thump is an attack attempt, not proof of destruction.
    return ok,reason
end

function Defense.considerIndependentUVAttack(infected,source,chance,randomUnit)
    if tasks[infected] then return false end
    if not Defense.canAttackEmitter(infected) then return false end
    if type(source)~="table" or type(source.channels)~="table" or source.channels.UV~=true
        or source.emitting~=true or source.on~=true or source.powered~=true then return false end
    local destruction=source.destroy
    if type(destruction)~="table" or destruction.supported~=true or type(destruction.requestAttack)~="function" then return false end
    chance=math.max(0,math.min(1,finite(chance) or 0))
    local roll=type(randomUnit)=="function" and finite(randomUnit()) or math.random()
    if not roll or roll>=chance then return false end
    local x,y,z=position(source);if not x then return false end
    local moved,pathResult=pcall(function()return infected:pathToLocationF(x,y,z)end)
    if moved and pathResult~=false then tasks[infected]={source=source,independentUV=true};return true end
    return false
end

function Defense.getTask(entity)return tasks[entity]end
return Defense
