require "ProjectNightfall/PN_Config"
local Frame=require "ProjectNightfall/PN_EffigyContainer"
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local Server={}
-- A reentrant call may not observe a partially moved batch. Native packet
-- processing and this non-yielding Lua handler run on the server main loop.
local busy=setmetatable({},{__mode="k"})
local reported=setmetatable({},{__mode="k"})
local MAX_ITEMS=256 -- matches policy's technical inspection bound, not capacity
local MAX_REVISION=9007199254740990 -- exact Lua-number integer safety limit
local function report(t,reason)
    if reported[t.container] then return end
    reported[t.container]=true
    if type(print)=="function" then
        print("[ProjectNightfall] Effigy frame "..tostring(t.frame:getID()).." load failure: "..tostring(reason))
    end
end

local function integer(value,minimum,maximum)
    return type(value)=="number" and value==value and value%1==0 and value>=minimum and value<=maximum
end
local function itemId(value) return integer(value,-2147483648,2147483647) and value~=-1 end
local function authority()
    return type(isClient)=="function" and not isClient()
        and type(isServer)=="function" -- both false is vanilla single player
end
local function config()
    local c=ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC
    if not c or c.Enabled==false then return nil end
    return c
end
local function capacity()
    local c=config();if not c then return nil end
    local value=c.EffigyContainerCapacity
    if not integer(value,1,40) then return nil end
    return value
end
local function accessible(player,object)
    if not player or player:isDead() then return false end
    local square=object and object:getSquare()
    local here=player:getCurrentSquare()
    if not square or not here or square:getZ()~=here:getZ()
        or math.abs(square:getX()-here:getX())>1 or math.abs(square:getY()-here:getY())>1
        or here:isBlockedTo(square) or here:isWindowTo(square) then return false end
    -- Absence of the vanilla permission surface is a blocker, never an allow.
    return SafeHouse and type(SafeHouse.isSafehouseAllowLoot)=="function"
        and SafeHouse.isSafehouseAllowLoot(square,player)==true
end
local function target(player,object)
    if not accessible(player,object) then return nil,"inaccessible" end
    local frame=Frame.getFrame(object)
    if not frame then return nil,"not_frame" end
    local contents=frame:getItemContainer()
    if not Frame.isClosed(contents) then return nil,"native_guard_missing" end
    local data=frame:getModData()
    local record=data[Frame.KEY]
    if record==nil then
        record={schemaVersion=1,revision=0};data[Frame.KEY]=record
    end
    if type(record)~="table" or record.schemaVersion~=1
        or not integer(record.revision,0,MAX_REVISION) then return nil,"unsupported_record" end
    if record.quarantined~=nil then return nil,"quarantined" end
    return {frame=frame,container=contents,record=record}
end
local function ids(items)
    if type(items)~="table" then return nil end
    local count,largest,seen=0,0,{}
    for k,v in pairs(items) do
        count=count+1
        if count>MAX_ITEMS or not integer(k,1,MAX_ITEMS) or not itemId(v) or seen[v] then return nil end
        seen[v]=true;largest=math.max(largest,k)
    end
    if count==0 or largest~=count then return nil end
    return count
end
local function snapshot(t)
    local view,reason=Policy.inspect(t.container)
    if not view then return nil,reason end
    view.frameId=t.frame:getID();view.revision=t.record.revision
    return view
end

function Server.inspect(player,object)
    if not authority() or not config() then return nil,"unavailable" end
    local t,reason=target(player,object)
    if not t then return nil,reason end
    if busy[t.container] then return nil,"busy" end
    return snapshot(t)
end

local function transfer(player,t,items,count,revision)
    if not integer(revision,0,MAX_REVISION-1) or revision~=t.record.revision then return nil,"stale_revision" end
    local source=player:getInventory()
    if not source or source==t.container then return nil,"invalid_source" end
    if source:getItems():size()>MAX_ITEMS then return nil,"inspection_limit" end
    local actual,weight={},0
    for i=1,count do
        local item=source:getItemWithID(items[i])
        -- Root inventory only. No client container references, nested searches,
        -- equipped-item removal, item deserialization or client provenance.
        if not item or item:getContainer()~=source or player:isEquipped(item)
            or not source:isRemoveItemAllowed(item) then return nil,"item_unavailable" end
        local w=item:getUnequippedWeight()
        if type(w)~="number" or w~=w or w<0 or w==math.huge then return nil,"invalid_weight" end
        actual[i]=item;weight=weight+w
    end
    local proposal,reason=Policy.validateInsertion(t.container,actual)
    if not proposal then return nil,reason end
    local limit=capacity();if not limit then return nil,"invalid_configuration" end
    -- Never use hasRoomFor(player,item): it intentionally hits the closed guard.
    -- The native weight overload retains floor/container weight constraints.
    t.container:setCapacity(limit)
    if not t.container:hasRoomFor(player,weight) then return nil,"capacity" end
    if isServer() and (type(sendRemoveItemFromContainer)~="function"
        or type(sendAddItemToContainer)~="function") then return nil,"sync_unavailable" end

    local attempted=0
    local moved,problem=pcall(function()
        for i=1,count do
            attempted=i
            -- Native AddItem checks duplicate IDs before removing the previous
            -- container link. Do not detach first and risk an orphan on refusal.
            t.container:AddItem(actual[i])
            if actual[i]:getContainer()~=t.container or t.container:getItemWithID(items[i])~=actual[i]
                or source:getItemWithID(items[i])~=nil then error("move_readback") end
        end
        local after=assert(Policy.inspect(t.container))
        if after.category~=proposal.category or after.itemCount~=proposal.itemCount then error("contents_readback") end
    end)
    if not moved then
        local restored=true
        for i=attempted,1,-1 do
            local item=actual[i]
            local ok=pcall(function()
                local current=item:getContainer()
                if current~=t.container and current~=source then error("foreign_container") end
                if item:getContainer()~=source then source:AddItem(item) end
                if source:getItemWithID(items[i])~=item or t.container:getItemWithID(items[i])~=nil then error("rollback_readback") end
            end)
            restored=restored and ok
        end
        if not restored then t.record.quarantined="rollback_uncertain" end
        report(t,problem)
        return nil,restored and "move_failed" or "quarantined"
    end
    t.record.revision=t.record.revision+1
    -- Commit precedes publication. Never reverse a published/partly published
    -- move, and never recreate items to acknowledge an uncertain delivery.
    if isServer() then
        local synced=pcall(function()
            for i=1,count do
                sendRemoveItemFromContainer(source,actual[i])
                sendAddItemToContainer(t.container,actual[i])
            end
        end)
        if not synced then t.record.quarantined="sync_failed";report(t,"committed transmission failed") end
    end
    local view=snapshot(t)
    return view,t.record.quarantined and "committed_sync_failed" or nil
end

function Server.load(player,object,items,revision)
    if not authority() or not config() then return nil,"unavailable" end
    local count=ids(items);if not count then return nil,"invalid_batch" end
    local t,reason=target(player,object);if not t then return nil,reason end
    if busy[t.container] then return nil,"busy" end
    busy[t.container]=true
    local ok,view,result=pcall(transfer,player,t,items,count,revision)
    busy[t.container]=nil
    if not ok then
        t.record.quarantined="operation_failed";report(t,view)
        return nil,"operation_failed"
    end
    return view,result
end

local function resolve(args)
    if type(args)~="table" or not integer(args.x,-1000000,1000000)
        or not integer(args.y,-1000000,1000000) or not integer(args.z,-32,32)
        or not integer(args.index,0,1023) or not itemId(args.frameId) then return nil end
    local cell=type(getCell)=="function" and getCell()
    local square=cell and cell:getGridSquare(args.x,args.y,args.z)
    local objects=square and square:getWorldObjects()
    if not objects or args.index>=objects:size() then return nil end
    local object=objects:get(args.index)
    local frame=Frame.getFrame(object)
    if frame and frame:getID()==args.frameId then return object end
end
function Server.onCommand(module,command,player,args)
    if module~="ProjectNightfallEffigyContainer" or (command~="inspect" and command~="load") then return end
    if not authority() then return end
    -- Packet input is never allowed to escape into the server event dispatcher.
    local ok,view,reason=pcall(function()
        local object=resolve(args)
        if not object then return nil,"stale_target" end
        if command=="inspect" then return Server.inspect(player,object) end
        return Server.load(player,object,args.items,args.revision)
    end)
    if not ok then view=nil;reason="invalid_request" end
    local current=view
    if not current then
        local read,fresh=pcall(function()
            local object=resolve(args)
            return object and Server.inspect(player,object)
        end)
        if read then current=fresh end
    end
    if isServer() and type(sendServerCommand)=="function" then
        local id=type(args)=="table" and itemId(args.frameId) and args.frameId or nil
        pcall(sendServerCommand,player,module,"result",{frameId=id,ok=view~=nil,view=current,reason=reason})
    end
    return view,reason,current
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(Server.onCommand) end
ProjectNightfall.EffigyContainerServer=Server
return Server
