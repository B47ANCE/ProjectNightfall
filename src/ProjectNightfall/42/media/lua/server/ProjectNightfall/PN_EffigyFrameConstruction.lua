-- Synchronous server commands consume/position actual items, never client copies.
local Recipe=require "ProjectNightfall/PN_EffigyFrameRecipe"
local Frame=require "ProjectNightfall/PN_EffigyContainer"
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local State=require "ProjectNightfall/PN_EffigyContainerState"
local Knowledge=require "ProjectNightfall/PN_EffigyKnowledge"
local Build={MODULE="ProjectNightfallEffigyFrame",JOURNAL="ProjectNightfallFrameConstruction"}
local function ready(player)
    if not State.enabled() or not player or player:isDead() then return nil,"unavailable" end
    -- Player ModData is client-replaceable in this build. Keep non-secret
    -- recovery guards in server GlobalModData; never ingest receive-event data.
    local username=player:getUsername()
    if type(username)~="string" or username=="" or #username>128
        or not ModData or type(ModData.getOrCreate)~="function" then return nil,"persistence_unavailable" end
    local store=ModData.getOrCreate(Build.JOURNAL)
    if type(store)~="table" then return nil,"persistence_unavailable" end
    local empty=true;for _ in pairs(store) do empty=false;break end
    if empty then store.schemaVersion=1;store.entries={};store.count=0 end
    if store.schemaVersion~=1 or type(store.entries)~="table" or type(store.count)~="number"
        or store.count~=store.count or store.count%1~=0 or store.count<0 or store.count>=2048 then return nil,"construction_recovery_required" end
    local count=0
    for key in pairs(store.entries) do
        count=count+1
        if count>2048 or type(key)~="string" or key=="" or #key>128 then return nil,"construction_recovery_required" end
    end
    if count~=store.count then return nil,"construction_recovery_required" end
    local data={store=store,key=username}
    if store.entries[username]~=nil then return nil,"construction_recovery_required" end
    if isServer() and (type(sendAddItemToContainer)~="function" or type(sendRemoveItemFromContainer)~="function") then return nil,"sync_unavailable" end
    return data
end
local function publish(root,item,add)
    if not isServer() then return true end
    return pcall(add and sendAddItemToContainer or sendRemoveItemFromContainer,root,item)
end
function Build.craft(player,ids)
    if not State.authority() then return nil,"non_authority" end
    local data,reason=ready(player);if not data then return nil,reason end
    local actual;actual,reason=Recipe.validate(player,ids);if not actual then return nil,reason end
    if type(instanceItem)~="function" then return nil,"creation_failed" end
    local root=player:getInventory();local lease={container=root};local owner={}
    if not State.acquire(lease,owner) then return nil,"busy" end
    local ok,output=pcall(instanceItem,Frame.FULL_TYPE)
    if not ok or not Recipe.frame(output) or output:getContainer() or output:getWorldItem()
        or output:getItemContainer():getItems():size()~=0 or root:getItemWithID(output:getID()) then
        State.release(lease,owner);return nil,"creation_failed"
    end
    output:getModData()[Frame.KEY]={schemaVersion=1,revision=0}
    -- A retained/unknown journal blocks subsequent construction. It is never
    -- interpreted as permission to recreate an output or refund saved inputs.
    local journal={schemaVersion=1,operation="craft",outputId=output:getID(),items={}}
    for i,item in ipairs(actual) do journal.items[i]=item:getID() end
    data.store.entries[data.key]=journal;data.store.count=data.store.count+1
    local attempted=0
    local committed=pcall(function()
        for i,item in ipairs(actual) do
            attempted=i
            if not Recipe.available(player,item) then error("input_changed") end
            root:Remove(item)
            if root:getItemWithID(item:getID())~=nil or item:getContainer()~=nil then error("remove_failed") end
        end
        if not Recipe.tools(player) then error("tools_unavailable") end
        root:AddItem(output)
        if root:getItemWithID(output:getID())~=output or output:getContainer()~=root then error("add_failed") end
    end)
    if not committed then
        local restored=pcall(function()
            if output:getWorldItem() or (output:getContainer() and output:getContainer()~=root) then error("foreign_output") end
            if root:getItemWithID(output:getID())==output then root:Remove(output) end
            if root:getItemWithID(output:getID()) or output:getContainer() then error("output_remains") end
            for i=attempted,1,-1 do
                local item=actual[i]
                if item:getWorldItem() or (item:getContainer() and item:getContainer()~=root) then error("foreign_input") end
                if item:getContainer()~=root then root:AddItem(item) end
                if root:getItemWithID(item:getID())~=item or item:getContainer()~=root then error("restore_failed") end
            end
        end)
        if restored and data.store.entries[data.key]==journal then data.store.entries[data.key]=nil;data.store.count=data.store.count-1 end
        State.release(lease,owner)
        return nil,restored and "craft_failed" or "construction_recovery_required"
    end
    local synced=true
    for _,item in ipairs(actual) do synced=publish(root,item,false) and synced end
    synced=publish(root,output,true) and synced
    if synced and data.store.entries[data.key]==journal then data.store.entries[data.key]=nil;data.store.count=data.store.count-1 end
    if not synced then output:getModData()[Frame.KEY].quarantined="craft_sync_uncertain" end
    State.release(lease,owner)
    -- A committed output is never refunded because publication failed.
    return output,not synced and "construction_recovery_required" or nil
end
local function coordinate(n,low,high) return type(n)=="number" and n==n and n%1==0 and n>=low and n<=high end
local function destination(player,x,y,z)
    if not coordinate(x,-1000000,1000000) or not coordinate(y,-1000000,1000000)
        or not coordinate(z,-32,32) then return nil,"invalid_request" end
    local cell=type(getCell)=="function" and getCell()
    local square=cell and cell:getGridSquare(x,y,z);local here=player:getCurrentSquare()
    if not square or not here or here:getZ()~=z or math.abs(here:getX()-x)>1 or math.abs(here:getY()-y)>1
        or here:isBlockedTo(square) or here:isWindowTo(square) or not square:TreatAsSolidFloor()
        or not square:isFree(false) then return nil,"inaccessible" end
    if not SafeHouse or type(SafeHouse.isSafehouseAllowLoot)~="function"
        or SafeHouse.isSafehouseAllowLoot(square,player)~=true then return nil,"inaccessible" end
    -- Do not permit construction in anyone else's claim, even if loot is
    -- globally allowed. The verified SafeHouse method accepts the player object.
    if type(SafeHouse.getSafeHouse)~="function" then return nil,"inaccessible" end
    local claim=SafeHouse.getSafeHouse(square)
    if claim and not claim:playerAllowed(player) then return nil,"inaccessible" end
    local objects=square:getWorldObjects()
    if objects:size()>1024 then return nil,"inspection_limit" end
    for i=0,objects:size()-1 do if Frame.getFrame(objects:get(i)) then return nil,"occupied" end end
    local weight=square:getTotalWeightOfItemsOnFloor()
    if type(weight)~="number" or weight~=weight or weight<0 or weight>50 then return nil,"capacity" end
    return square,weight
end
function Build.place(player,id,x,y,z)
    if not State.authority() then return nil,"non_authority" end
    local data,reason=ready(player);if not data then return nil,reason end
    if not coordinate(id,-2147483648,2147483647) or id== -1 then return nil,"invalid_request" end
    if not Knowledge.check(player) then return nil,"research_required" end
    local root=player:getInventory();local item=root and root:getItemWithID(id)
    local container=Recipe.frame(item)
    if not container or not Recipe.available(player,item) then return nil,"item_unavailable" end
    local view=Policy.inspect(container);if not view then return nil,"invalid_contents" end
    local square,weight=destination(player,x,y,z);if not square then return nil,weight end
    local w=item:getUnequippedWeight()
    if type(w)~="number" or w~=w or w<0 or w+weight>50 then return nil,"capacity" end
    local before={};local objects=square:getWorldObjects()
    for i=0,objects:size()-1 do before[objects:get(i)]=true end
    local t={container=container,frame=item};local owner={}
    if not State.acquire(t,owner) then return nil,"busy" end
    local record=item:getModData()[Frame.KEY]
    if record==nil then record={schemaVersion=1,revision=0};item:getModData()[Frame.KEY]=record end
    t.record=record
    local journal={schemaVersion=1,operation="place",outputId=id,x=x,y=y,z=z}
    data.store.entries[data.key]=journal;data.store.count=data.store.count+1;record.pendingPlacement=true
    local object
    local committed=pcall(function()
        -- false suppresses automatic transmission until authoritative readback.
        local result=square:AddWorldInventoryItem(item,.5,.5,0,false)
        object=item:getWorldItem();t.object=object
        if result~=item or not object or Frame.getFrame(object)~=item or object:getSquare()~=square then error("world_readback") end
        local found=false;local list=square:getWorldObjects()
        for i=0,list:size()-1 do if list:get(i)==object then found=true end end
        if not found or not State.canCheckpoint(t) or type(object.transmitCompleteItemToClients)~="function" then error("world_capability") end
        object:setIgnoreRemoveSandbox(true)
        root:Remove(item)
        if item:getContainer()~=nil or root:getItemWithID(id)~=nil then error("inventory_readback") end
        record.pendingPlacement=nil
        if not State.checkpoint(t) then error("save_request") end
    end)
    if not committed then
        local restored=pcall(function()
            object=item:getWorldItem()
            -- Native registration precedes setWorldItem. Find an object that
            -- was registered and then threw before installing the back-link.
            local list=square:getWorldObjects()
            if list:size()>1024 then error("uncertain_world_list") end
            for i=0,list:size()-1 do
                local candidate=list:get(i)
                if not before[candidate] and type(candidate.getItem)=="function" and candidate:getItem()==item then
                    if object and candidate~=object then error("duplicate_world_identity") end
                    object=candidate
                end
            end
            if object then
                if before[object] or object:getSquare()~=square or object:getItem()~=item then error("foreign_world") end
                -- This object was never published; remove it synchronously.
                square:RemoveTileObject(object,false)
                local list=square:getWorldObjects()
                for i=0,list:size()-1 do if list:get(i)==object then error("world_remains") end end
                item:setWorldItem(nil)
            end
            if item:getContainer() and item:getContainer()~=root then error("foreign_inventory") end
            if root:getItemWithID(id)==item and item:getContainer()==nil then item:setContainer(root)
            elseif item:getContainer()~=root then root:AddItem(item) end
            if root:getItemWithID(id)~=item or item:getContainer()~=root or item:getWorldItem() then error("restore_failed") end
        end)
        if restored then record.pendingPlacement=nil;if data.store.entries[data.key]==journal then data.store.entries[data.key]=nil;data.store.count=data.store.count-1 end
        else record.quarantined="placement_rollback_uncertain" end
        State.release(t,owner)
        return nil,restored and "placement_failed" or "construction_recovery_required"
    end
    local synced=publish(root,item,false)
    synced=pcall(object.transmitCompleteItemToClients,object) and synced
    if synced and data.store.entries[data.key]==journal then data.store.entries[data.key]=nil;data.store.count=data.store.count-1
    else record.quarantined="placement_sync_uncertain";State.checkpoint(t) end
    State.release(t,owner);State.changed(object)
    return object,not synced and "construction_recovery_required" or nil
end
function Build.onCommand(module,command,player,args)
    if module~=Build.MODULE or (command~="craft" and command~="place") or not State.authority() then return end
    local ok,result,reason=pcall(function()
        if type(args)~="table" then return nil,"invalid_request" end
        if command=="craft" then return Build.craft(player,args.items) end
        return Build.place(player,args.frameId,args.x,args.y,args.z)
    end)
    if not ok then result=nil;reason="unavailable" end
    if isServer() and type(sendServerCommand)=="function" then
        pcall(sendServerCommand,player,Build.MODULE,"result",{ok=result~=nil,reason=reason})
    end
    return result,reason
end
if Events and Events.OnClientCommand then Events.OnClientCommand.Add(Build.onCommand) end
ProjectNightfall=ProjectNightfall or {};ProjectNightfall.EffigyFrameConstruction=Build
return Build
