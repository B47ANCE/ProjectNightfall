require "ProjectNightfall/PN_Config"
local State=require "ProjectNightfall/PN_EffigyContainerState"
local Food={PROVIDER_ID="ProjectNightfall.effigyFrames"}
if not State.authority() then return Food end
local Mortis=require "Mortis/init"
local Effigies=require "ProjectNightfall/PN_Effigies"
local Frame=require "ProjectNightfall/PN_EffigyContainer"
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local Detached=require "Mortis/API/DetachedParts"
local Plan=require "ProjectNightfall/PN_EffigyFoodPlan"
local entries,buckets,commits={},{},{}
-- Technical bounds on loaded discovery metadata/query work, not storage or
-- nutrition balance. Never scan the world each tick or return partial stock.
local BUCKET,MAX_TRACKED,MAX_QUERY=16,2048,128
local tracked=0
local function position(object)
    if not object then return end
    local x,y,z=object:getX(),object:getY(),object:getZ()
    if Plan.finite(x) and Plan.finite(y) and Plan.finite(z) then return x,y,z end
end
local function key(x,y,z) return math.floor(x/BUCKET)..":"..math.floor(y/BUCKET)..":"..math.floor(z) end
local function live(object)
    local square=object:getSquare();local x,y,z=position(object)
    if not square or not x or getCell():getGridSquare(math.floor(x),math.floor(y),math.floor(z))~=square then return false end
    local objects=square:getWorldObjects()
    if not objects or objects:size()>1024 then return false end
    for i=0,objects:size()-1 do if objects:get(i)==object then return true end end
    return false
end
local function canonical(subject)
    local fn=Mortis.Authority and Mortis.Authority.canWriteCanonicalState
    return State.authority() and type(fn)=="function" and fn(subject)==true
end
local function canWrite(subject) return State.enabled() and canonical(subject) end
local function warn(t,reason)
    State.quarantine(t,reason)
    print("[ProjectNightfall] Effigy frame feeding quarantined: "..tostring(reason))
end
local function untrack(entry)
    if entries[entry.id]~=entry then return end
    entries[entry.id]=nil;tracked=tracked-1
    local bucket=buckets[entry.bucket];bucket[entry.id]=nil
    local any=false;for _ in pairs(bucket) do any=true;break end
    if not any then buckets[entry.bucket]=nil end
end
function Food.track(object)
    if not State.authority() then return false end
    local frame=Frame.getFrame(object)
    if not frame or not Frame.isClosed(frame:getItemContainer()) or not live(object) then return false end
    local x,y,z=position(object);if not x then return false end
    local id=frame:getID();local old=entries[id]
    if old then
        if old.object==object and old.x==x and old.y==y and old.z==z then return true end
        if old.object~=object and Frame.getFrame(old.object) and live(old.object) then return false end
        untrack(old)
    end
    if tracked>=MAX_TRACKED then
        for _,entry in pairs(entries) do if not Frame.getFrame(entry.object) or not live(entry.object) then untrack(entry) end end
        if tracked>=MAX_TRACKED then return false end
    end
    local entry={id=id,object=object,x=x,y=y,z=z,bucket=key(x,y,z)}
    entries[id]=entry;tracked=tracked+1
    buckets[entry.bucket]=buckets[entry.bucket] or {};buckets[entry.bucket][id]=entry
    return true
end
function Food.untrack(object)
    local frame=Frame.getFrame(object)
    local entry=frame and entries[frame:getID()]
    if entry and entry.object==object then untrack(entry) end
end
function Food.loadSquare(square)
    if not State.authority() or not square then return end
    local objects=square:getWorldObjects()
    if not objects or objects:size()>1024 then return end
    for i=0,objects:size()-1 do Food.track(objects:get(i)) end
end
local function sourceId(t)
    return "PN.EffigyFrame:"..t.frame:getID()..":"..string.format("%.0f",t.record.revision)
end
local function reaction(zombie,category)
    -- Ordinary meat has no human-part attribution, search or grudge behavior.
    if category=="meat" then return Mortis.ZombieHunger.getLevel(zombie)>0 end
    return Effigies.reactionFor(zombie,category).action=="consume"
end
local function syncAvailable(kind)
    return not isServer() or (kind=="meat" and type(sendRemoveItemFromContainer)=="function")
        or (kind=="part" and type(sendReplaceItemInContainer)=="function")
end
local function readCandidate(zombie,candidate)
    if not canWrite(zombie) or zombie:isDead() or type(candidate)~="table" then return end
    local object=candidate.source
    local t=State.get(object);if not t or not canWrite(object) then return end
    local entry=entries[t.frame:getID()]
    if not entry or entry.object~=object or candidate.sourceId~=sourceId(t) then return end
    local x,y,z=position(zombie);local ox,oy,oz=position(object)
    if not x or not ox or not live(object) or entry.x~=ox or entry.y~=oy or entry.z~=oz
        or candidate.x~=ox or candidate.y~=oy or candidate.z~=oz
        or math.floor(z)~=math.floor(oz) or (x-ox)^2+(y-oy)^2>1.25^2 then return end
    local here=zombie:getSquare();local there=object:getSquare()
    if not here or here:isBlockedTo(there) or here:isWindowTo(there) then return end
    local view=Policy.inspect(t.container)
    if not view or not reaction(zombie,view.category) then return end
    return t,view
end
local function findNearby(zombie,radius)
    if not canWrite(zombie) or zombie:isDead() then return end
    local x,y,z=position(zombie)
    if not x or not Plan.finite(radius) or radius<=0 then return end
    radius=math.min(radius,100)
    local options={};local examined=0
    for bx=math.floor((x-radius)/BUCKET),math.floor((x+radius)/BUCKET) do
        for by=math.floor((y-radius)/BUCKET),math.floor((y+radius)/BUCKET) do
            for _,entry in pairs(buckets[bx..":"..by..":"..math.floor(z)] or {}) do
                examined=examined+1;if examined>MAX_QUERY then return end
                if not Frame.getFrame(entry.object) or not live(entry.object) then untrack(entry)
                else
                    local distance=(entry.x-x)^2+(entry.y-y)^2
                    if distance<=radius*radius then options[#options+1]={entry=entry,distance=distance} end
                end
            end
        end
    end
    table.sort(options,function(a,b) return a.distance==b.distance and a.entry.id<b.entry.id or a.distance<b.distance end)
    local calibration=ProjectNightfall.Config.POC.EffigyCaloriesPerFullFeed
    for _,option in ipairs(options) do
        local entry=option.entry;local t=State.get(entry.object)
        if t and not State.isBusy(t.container) then
            local plan=Plan.create(t,calibration,true)
            if plan and syncAvailable(plan.kind) and reaction(zombie,plan.category) then
                return {source=entry.object,sourceId=sourceId(t),sourceClass="ProjectNightfall.effigyFrame",
                    x=entry.x,y=entry.y,z=entry.z,consumeDistance=1.25,foodValue=plan.foodValue}
            end
        end
    end
end
local function reserve(zombie,candidate,context)
    if type(context)~="table" or context.effigyFrame or not Mortis.Events
        or type(Mortis.Events.on)~="function" then return {reserved=false} end
    local t=readCandidate(zombie,candidate)
    if not t then return {reserved=false} end
    local tx={t=t,actor=zombie,sourceId=candidate.sourceId,revision=t.record.revision}
    context.effigyFrame=tx
    if not State.acquire(t,tx) then return {reserved=false} end
    local p=Plan.create(t,ProjectNightfall.Config.POC.EffigyCaloriesPerFullFeed)
    if not p or not syncAvailable(p.kind) or not canWrite(p.item) or not State.canCheckpoint(t) then return {reserved=false} end
    tx.plan=p;tx.marker={schemaVersion=1,sourceId=tx.sourceId,itemId=p.itemId}
    return {reserved=true,foodValue=p.foodValue,nutrition=p.nutrition}
end
local function commit(zombie,candidate,context)
    local tx=context and context.effigyFrame
    if not tx or tx.actor~=zombie or tx.wrote or not tx.plan or not State.owns(tx.t,tx) then return false end
    local t=readCandidate(zombie,candidate)
    if not t or t.frame~=tx.t.frame or t.record~=tx.t.record or t.record.revision~=tx.revision
        or not Plan.matches(tx.plan,t.container) or not canWrite(tx.plan.item)
        or t.record.revision>=State.MAX_REVISION then return false end
    tx.wrote=true;t.record.pendingFeed=tx.marker
    if not State.checkpoint(t) then return false end
    local p=tx.plan
    if p.kind=="meat" then
        t.container:Remove(p.item)
        if p.item:getContainer()~=nil or p.item:getWorldItem()~=nil or t.container:getItemWithID(p.itemId)~=nil then return false end
    else
        for _,step in ipairs(p.requests) do
            if not Detached.applyMaterialLoss(p.item,step.region,step.request) then return false end
        end
        if not Plan.matches(p,t.container,true) then return false end
    end
    t.record.revision=tx.revision+1
    if not State.checkpoint(t) then return false end
    tx.committed=true;commits[tx.sourceId]=tx
    return true
end
local function rollback(zombie,candidate,context)
    local tx=context and context.effigyFrame
    if not tx then return true end
    if tx.rolledBack then return true end
    if tx.actor~=zombie or candidate.source~=tx.t.object or candidate.sourceId~=tx.sourceId then return false end
    if not State.owns(tx.t,tx) then return not tx.wrote end
    local t,p=tx.t,tx.plan
    if tx.wrote then
        local restored,ok=pcall(function()
            if not canonical(zombie) or not canonical(t.object) or not canonical(p.item)
                or Frame.getFrame(t.object)~=t.frame or t.frame:getModData()[Frame.KEY]~=t.record
                or t.record.pendingFeed~=tx.marker
                or (t.record.revision~=tx.revision and t.record.revision~=tx.revision+1) then return false end
            if p.kind=="meat" then
                if p.item:getWorldItem()~=nil or not Plan.same(Plan.foodSnapshot(p.item),p.nutrition)
                    or p.item:getAge()~=p.beforeAge or p.item:getCondition()~=p.beforeCondition then return false end
                if p.item:getContainer()==nil then
                    if t.container:getItemWithID(p.itemId)~=nil then return false end
                    t.container:AddItem(p.item)
                end
                if not Plan.matches(p,t.container) then return false end
            else
                if p.item:getContainer()~=t.container or p.item:getWorldItem()~=nil
                    or t.container:getItemWithID(p.itemId)~=p.item then return false end
                local record=Detached.read(p.item);local owned=Plan.same(record,p.before)
                for _,stage in ipairs(p.stages) do owned=owned or Plan.same(record,stage) end
                if not owned or not Detached.write(p.item,p.before) or not Plan.matches(p,t.container) then return false end
            end
            t.record.revision=tx.revision;t.record.pendingFeed=nil
            return State.checkpoint(t)
        end)
        if not restored or not ok then
            commits[tx.sourceId]=nil;State.release(t,tx);tx.failed=true
            warn(t,"feed_rollback_uncertain");return false
        end
    end
    commits[tx.sourceId]=nil;State.release(t,tx);tx.rolledBack=true;return true
end
local function finish(zombie,_,__,metadata)
    if type(metadata)~="table" or metadata.providerId~=Food.PROVIDER_ID then return end
    local tx=commits[metadata.sourceId]
    if not tx or tx.actor~=zombie or metadata.source~=tx.t.object then return end
    commits[tx.sourceId]=nil
    local t,p=tx.t,tx.plan
    local worked=pcall(function()
        if not tx.committed or not State.owns(t,tx) or not canonical(t.object)
            or t.frame:getModData()[Frame.KEY]~=t.record or t.record.pendingFeed~=tx.marker
            or t.record.revision~=tx.revision+1 or Frame.getFrame(t.object)~=t.frame then error("feed_identity_changed") end
        if p.kind=="meat" then
            if p.item:getContainer()~=nil or p.item:getWorldItem()~=nil
                or t.container:getItemWithID(p.itemId)~=nil then error("feed_item_changed") end
            if isServer() then sendRemoveItemFromContainer(t.container,p.item) end
        else
            if not Plan.matches(p,t.container,true) then error("feed_material_changed") end
            if isServer() then sendReplaceItemInContainer(t.container,p.item,p.item) end
        end
        t.record.pendingFeed=nil
        if not State.checkpoint(t) then error("feed_checkpoint_failed") end
    end)
    State.release(t,tx)
    if not worked then warn(t,"feed_committed_sync_failed") end
    State.changed(t.object)
end
if Mortis.FoodSources and not Mortis.FoodSources.has(Food.PROVIDER_ID) then
    Mortis.registerFoodSourceProvider({id=Food.PROVIDER_ID,priority=40,transactionVersion=1,
        sourceClass="ProjectNightfall.effigyFrame",findNearby=findNearby,reserve=reserve,commit=commit,rollback=rollback})
end
if Mortis.Events and type(Mortis.Events.on)=="function" then Mortis.Events:on("ZombieFed",finish) end
local eventError=false
local function protected(fn)
    return function(value)
        local ok,reason=pcall(fn,value)
        if not ok and not eventError then eventError=true;print("[ProjectNightfall] Effigy frame discovery failed: "..tostring(reason)) end
    end
end
State.onChanged(protected(Food.track))
if Events then
    if Events.OnObjectAdded then Events.OnObjectAdded.Add(protected(Food.track)) end
    if Events.OnObjectAboutToBeRemoved then Events.OnObjectAboutToBeRemoved.Add(protected(Food.untrack)) end
    if Events.LoadGridsquare then Events.LoadGridsquare.Add(protected(Food.loadSquare)) end
end
ProjectNightfall.EffigyContainerFeeding=Food
return Food
