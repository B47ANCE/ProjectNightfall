local F=dofile('tests/helpers/effigy_container_fixture.lua');F.install()
local Frame=require 'ProjectNightfall/PN_EffigyContainer'
local Build=require 'ProjectNightfall/PN_EffigyFrameConstruction'
local Recipe=require 'ProjectNightfall/PN_EffigyFrameRecipe'
local State=require 'ProjectNightfall/PN_EffigyContainerState'
local Server=require 'ProjectNightfall/PN_EffigyContainerServer'
local Knowledge=require 'ProjectNightfall/PN_ResearchArchive'
local config=ProjectNightfall.Config.POC
local function factory()
    local cell=getCell
    local _,_,frame=F.world();getCell=cell
    frame.world=nil;frame.weight=8
    function frame:setWorldItem(object) self.world=object end
    return frame
end
instanceItem=function(kind) assert(kind==Frame.FULL_TYPE);return factory() end
local function setup()
    F.install();config.Enabled=true;config.RequireEffigyKnowledge=false
    config.EffigyFrameLogs=1;config.EffigyFrameLargeBranches=3;config.EffigyFrameRopes=1;config.EffigyFrameNails=8
    local p,o,frame,root,c,objects=F.world()
    p.md={};function p:getModData() return self.md end
    function p:getUsername() return 'fixture-player' end
    local global={}
    ModData={getOrCreate=function(key) assert(key==Build.JOURNAL);return global end}
    p.journal=global
    local square=p.square;table.remove(objects,1);frame.world=nil;frame.weight=8
    function frame:setWorldItem(v) self.world=v end
    function frame:setContainer(v) self.container=v end
    function square:TreatAsSolidFloor() return not self.noFloor end
    function square:isFree() return not self.occupied end
    function square:getTotalWeightOfItemsOnFloor() return self.floorWeight or 0 end
    function square:AddWorldInventoryItem(item,x,y,z,transmit)
        assert(x==.5 and y==.5 and z==0 and transmit==false)
        if self.failBefore then return nil end
        -- Native constructor clears the item.container link before returning;
        -- the root list still needs explicit Remove after AddWorldInventoryItem.
        item.container=nil
        local world={square=self}
        function world:getItem() return item end
        function world:getSquare() return self.square end
        function world:setIgnoreRemoveSandbox(v) self.ignoreRemoval=v end
        function world:flagForHotSave() if square.failSave then error('save failure') end end
        function world:transmitCompleteItemToClients()
            assert(item:getContainer()==nil and root:getItemWithID(item.id)==nil)
            if square.failPublish then error('sync failure') end
            self.published=true
        end
        objects[#objects+1]=world
        if self.failBeforeLink then error("before native back-link") end
        item.world=world
        if self.failAfter then error('after world creation') end
        return item
    end
    function square:RemoveTileObject(world,safely)
        assert(safely==false)
        if self.failRollback then error('world rollback failure') end
        for i,v in ipairs(objects) do if v==world then table.remove(objects,i);world.square=nil;return end end
    end
    SafeHouse.getSafeHouse=function() return square.claim end
    return p,frame,root,c,objects,square
end
local function ingredients(root)
    local ids,actual={},{}
    for _,pair in ipairs({{'Base.Log',1},{'Base.LargeBranch',3},{'Base.Rope',1},{'Base.Nails',8}}) do
        for _=1,pair[2] do
            local item=F.item('meat');item.foodType=nil;item.kind=pair[1]
            function item:getFullType() return self.kind end
            root:AddItem(item);ids[#ids+1]=item.id;actual[#actual+1]=item
        end
    end
    local tools=dofile("tests/helpers/effigy_frame_tools.lua").add(F,root)
    return ids,actual,tools
end
local function reject(reason,fn,...)
    local value,why=fn(...);assert(not value and why==reason,tostring(why)..' expected '..reason)
end
-- Real pinned knowledge reads: missing research, missing provider and blocked
-- dedicated storage never become implicit authorization. SP learns through API.
local p,frame,root,c,objects,square=setup();local ids,actual=ingredients(root)
config.RequireEffigyKnowledge=true
reject('research_required',Build.craft,p,ids);assert(#root.items==16 and #F.packets==0)
assert(not Knowledge.hasKnowledge(p,'ProjectNightfall.EffigyConstruction'))
local api=B47ANCEDKnowledgeAndWisdom;B47ANCEDKnowledgeAndWisdom=nil
reject('research_required',Build.craft,p,ids);B47ANCEDKnowledgeAndWisdom=api
isServer=function() return false end
assert(Knowledge.learn(p,'NF-UV-003'));assert(Knowledge.learn(p,'NF-FIELD-026'))
assert(Knowledge.hasKnowledge(p,'ProjectNightfall.EffigyConstruction'))
local crafted=assert(Build.craft(p,ids));assert(crafted:getFullType()==Frame.FULL_TYPE)
assert(#root.items==4 and root:getItemWithID(crafted.id)==crafted and #F.packets==0)
isServer=function() return true end
-- Dedicated provider refuses even the known SP ledger.
reject('research_required',Build.place,p,crafted.id,10,10,0)
config.RequireEffigyKnowledge=false
assert(Build.place(p,crafted.id,10,10,0));assert(#objects==1)
reject('item_unavailable',Build.place,p,crafted.id,10,10,0)
-- Normal server craft keeps actual output ID and emits only committed changes.
p,frame,root,c,objects,square=setup();ids,actual=ingredients(root)
assert(#Recipe.select(p)==13)
local successReason;crafted,successReason=Build.craft(p,ids);assert(crafted and successReason==nil and p.journal.count==0);assert(#root.items==4 and #F.packets==14)
assert(crafted.md[Frame.KEY].revision==0 and Frame.isClosed(crafted.contents))
for _,item in ipairs(actual) do assert(item.container==nil and not root:getItemWithID(item.id)) end
reject('item_unavailable',Build.craft,p,ids);assert(#root.items==4)
-- Exact recipe: sparse/duplicate/fractional IDs, extra materials, equipped,
-- nested/moved items, changing costs and disabled feature reject before mutation.
for _,case in ipairs({'sparse','duplicate','fractional','extra','equipped','moved','cost','disabled','dead'}) do
    p,frame,root,c,objects,square=setup();ids,actual=ingredients(root)
    if case=='sparse' then ids[2]=nil
    elseif case=='duplicate' then ids[2]=ids[1]
    elseif case=='fractional' then ids[1]=.5
    elseif case=='extra' then ids[#ids+1]=frame.id
    elseif case=='equipped' then actual[1].equipped=true
    elseif case=='moved' then F.container():AddItem(actual[1])
    elseif case=='cost' then config.EffigyFrameLogs=5
    elseif case=='disabled' then config.Enabled=false
    else p.dead=true end
    assert(not Build.craft(p,ids),case);assert(#F.packets==0 and (p.journal.entries and p.journal.entries[p:getUsername()])==nil)
end
p,frame,root=setup();ids=ingredients(root);config.EffigyFrameLogs=1.5
reject('invalid_configuration',Build.craft,p,ids)
-- Late removal/output-add failure restores originals before offering retry.
for _,failure in ipairs({'remove','output'}) do
    p,frame,root=setup();ids,actual=ingredients(root)
    if failure=='remove' then
        local remove=root.Remove
        function root:Remove(item) if item==actual[3] then error('remove failure') end;return remove(self,item) end
    else
        local add=root.AddItem
        function root:AddItem(item)
            local value=add(self,item)
            if item:getFullType()==Frame.FULL_TYPE then error('insert then throw') end
            return value
        end
    end
    reject('craft_failed',Build.craft,p,ids)
    assert(#root.items==16 and (p.journal.entries and p.journal.entries[p:getUsername()])==nil and #F.packets==0 and not State.isBusy(root))
    for _,item in ipairs(actual) do assert(item.container==root) end
end
-- Do not steal a foreign/moved input back during compensation.
p,frame,root=setup();ids,actual=ingredients(root)
local remove=root.Remove
function root:Remove(item)
    remove(self,item)
    if item==actual[2] then F.container():AddItem(item);error('foreign mutation') end
end
reject('construction_recovery_required',Build.craft,p,ids)
assert((p.journal.entries and p.journal.entries[p:getUsername()]) and actual[2].container~=root and not State.isBusy(root))
-- A committed resource is not refunded after failed publication; retained
-- journal survives module reload and is never reset by a new request.
p,frame,root=setup();ids=ingredients(root)
sendAddItemToContainer=function() error('publish failure') end
local output,reason=Build.craft(p,ids)
assert(output and reason=='construction_recovery_required' and #root.items==4 and output.md[Frame.KEY].quarantined)
package.loaded['ProjectNightfall/PN_EffigyFrameConstruction']=nil
Build=require 'ProjectNightfall/PN_EffigyFrameConstruction'
reject('construction_recovery_required',Build.craft,p,ids)
-- Actual loaded frame is moved, never cloned or emptied. Native insertion
-- remains denied. Its content/provenance/age/condition and revision survive.
p,frame,root,c,objects,square=setup();root:AddItem(frame)
local meat=F.item('meat');meat.age=17;meat.condition=43;c:AddItem(meat)
frame.md[Frame.KEY]={schemaVersion=1,revision=7}
local placed=assert(Build.place(p,frame.id,10,10,0))
assert(frame.world==placed and placed.ignoreRemoval and placed.published and #root.items==0)
assert(meat.container==c and meat.age==17 and meat.condition==43 and frame.md[Frame.KEY].revision==7)
assert(Frame.isClosed(c) and Server.inspect(p,placed).category=='meat')
-- Shared lease blocks placement while loading/feeding owns the frame.
p,frame,root,c=setup();root:AddItem(frame)
local lease={container=c};local owner={};assert(State.acquire(lease,owner))
reject('busy',Build.place,p,frame.id,10,10,0);State.release(lease,owner)
-- Reach, walls/windows, z, floor, occupancy, claim, weight and missing APIs.
for _,case in ipairs({'far','wall','window','z','floor','occupied','claim','permission','capacity','weight','equipped','future','pending','mixed'}) do
    p,frame,root,c,objects,square=setup();root:AddItem(frame)
    local x,y,z=10,10,0
    if case=='far' then x=12 elseif case=='wall' then square.blocked=true
    elseif case=='window' then square.window=true elseif case=='z' then z=1
    elseif case=='floor' then square.noFloor=true elseif case=='occupied' then square.occupied=true
    elseif case=='claim' then square.claim={playerAllowed=function(_,actor) assert(actor==p);return false end}
    elseif case=='permission' then SafeHouse.getSafeHouse=nil
    elseif case=='capacity' then square.floorWeight=49 elseif case=='weight' then frame.weight=0/0
    elseif case=='equipped' then frame.equipped=true
    elseif case=='future' then frame.md[Frame.KEY]={schemaVersion=2,revision=0}
    elseif case=='pending' then frame.md[Frame.KEY]={schemaVersion=1,revision=0,pendingFeed={}}
    else c:AddItem(F.item('meat'));c:AddItem(F.item('human')) end
    assert(not Build.place(p,frame.id,x,y,z),case)
    assert(root:getItemWithID(frame.id)==frame and not frame.world and #objects==0 and #F.packets==0)
end
-- Newly created world object rollback is synchronous and unpublished, including
-- a native AddWorldInventoryItem that mutated and then threw.
for _,failure in ipairs({'failBefore','failBeforeLink','failAfter','failSave'}) do
    p,frame,root,c,objects,square=setup();root:AddItem(frame);square[failure]=true
    reject('placement_failed',Build.place,p,frame.id,10,10,0)
    assert(#objects==0 and frame.world==nil and frame.container==root and #root.items==1)
    assert((p.journal.entries and p.journal.entries[p:getUsername()])==nil and frame.md[Frame.KEY].pendingPlacement==nil and #F.packets==0)
end
p,frame,root,c,objects,square=setup();root:AddItem(frame);square.failAfter=true;square.failRollback=true
reject('construction_recovery_required',Build.place,p,frame.id,10,10,0)
assert(frame.md[Frame.KEY].quarantined and (p.journal.entries and p.journal.entries[p:getUsername()]) and not State.isBusy(c))
p,frame,root,c,objects,square=setup();root:AddItem(frame);square.failPublish=true
local object,why=Build.place(p,frame.id,10,10,0)
assert(object and why=='construction_recovery_required' and #objects==1 and #root.items==0)
assert(not Server.inspect(p,object) and (p.journal.entries and p.journal.entries[p:getUsername()]) and frame.md[Frame.KEY].quarantined)
-- Server journal is not replaceable by player ModData or a module reload;
-- future/malformed globals are preserved. Missing native factory fails closed.
p,frame,root=setup();ids=ingredients(root)
p.journal.schemaVersion=2
reject('construction_recovery_required',Build.craft,p,ids);assert(p.journal.schemaVersion==2)
p,frame,root=setup();ids=ingredients(root);p.journal.schemaVersion=1;p.journal.count=2;p.journal.entries={}
reject('construction_recovery_required',Build.craft,p,ids)
p,frame,root=setup();ids=ingredients(root);local savedFactory=instanceItem;instanceItem=nil
reject('creation_failed',Build.craft,p,ids);assert(not State.isBusy(root));instanceItem=savedFactory
p,frame,root=setup();ids=ingredients(root)
p.journal.schemaVersion=1;p.journal.count=1;p.journal.entries={[p:getUsername()]={schemaVersion=99}}
p.md={} -- a client-replaced player table cannot erase the server marker
reject('construction_recovery_required',Build.craft,p,ids)
-- Tool requirements are authoritative and tools are retained unchanged, even
-- when equipped. Large branches are distinct from the smaller TreeBranch2.
for _,case in ipairs({'hammer','knife','drill','broken','nested','smallBranch','badTag'}) do
    p,frame,root=setup();local tools;ids,actual,tools=ingredients(root)
    if case=='hammer' then root:Remove(tools[1])
    elseif case=='knife' then root:Remove(tools[2])
    elseif case=='drill' then root:Remove(tools[3])
    elseif case=='broken' then tools[3].condition=0
    elseif case=='nested' then F.container():AddItem(tools[2])
    elseif case=='smallBranch' then actual[2].kind='Base.TreeBranch2'
    else tools[1].tag='sledgehammer' end
    assert(not Build.craft(p,ids),case)
    for _,item in ipairs(actual) do assert(item.container==root) end
    assert(#F.packets==0 and not State.isBusy(root))
end
p,frame,root=setup();local tools;ids,actual,tools=ingredients(root)
for _,tool in ipairs(tools) do tool.equipped=true;tool.condition=17 end
crafted=assert(Build.craft(p,ids))
for _,tool in ipairs(tools) do
    assert(root:getItemWithID(tool.id)==tool and tool.condition==17 and tool.equipped)
    for _,packet in ipairs(F.packets) do assert(packet[3]~=tool) end
end
-- Tools disappearing after validation must compensate consumed materials.
p,frame,root=setup();ids,actual,tools=ingredients(root)
local previousRemove=root.Remove;local foreign=F.container()
function root:Remove(item)
    previousRemove(self,item)
    if item==actual[1] then foreign:AddItem(tools[2]) end
end
reject('craft_failed',Build.craft,p,ids)
for _,item in ipairs(actual) do assert(item.container==root) end
assert(tools[2].container==foreign and #F.packets==0)
-- Existing explicit server costs remain accepted; only defaults change.
p,frame,root=setup();ids=ingredients(root);config.EffigyFrameLargeBranches=2
reject('ingredients_required',Build.craft,p,ids)
-- Untrusted packet payloads and pure-client execution cannot mutate inventory.
p,frame,root=setup();ids=ingredients(root)
for _,args in ipairs({false,3,{items='bad'},{items={}}, {items={[1]=ids[1],[400]=ids[2]}}}) do
    assert(not Build.onCommand(Build.MODULE,'craft',p,args));assert(#root.items==16)
end
isClient=function() return true end
reject('non_authority',Build.craft,p,ids)
assert(not Build.onCommand(Build.MODULE,'place',p,{}))
assert(#root.items==16 and #F.packets==0)
print('Effigy frame construction/placement authority and compensation checks passed')
