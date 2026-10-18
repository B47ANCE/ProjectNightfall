local F=dofile('tests/helpers/effigy_container_fixture.lua');F.install()
local Frame=require 'ProjectNightfall/PN_EffigyContainer'
local Server=require 'ProjectNightfall/PN_EffigyContainerServer'
ProjectNightfall.Config.POC.EffigyContainerCapacity=20
local function setup() F.install();return F.world() end
local function insert(source,category) local item=F.item(category);source:AddItem(item);return item end
local function revision(frame) return frame.md[Frame.KEY] and frame.md[Frame.KEY].revision or 0 end
local function load(player,object,frame,items) local ids={};for i,v in ipairs(items) do ids[i]=v.id end;return Server.load(player,object,ids,revision(frame)) end
local function rejected(reason,...)
    local view,why=Server.load(...);assert(not view and why==reason,tostring(why)..' expected '..reason)
end
assert(PN_EffigyRejectNativeInsertion()==false and #F.handlers==1)
-- Every pair of source classes, both orderings, uses real pinned provenance.
local categories={'meat','human','regular','feral','smartFeral'}
for _,a in ipairs(categories) do for _,b in ipairs(categories) do
    local p,o,f,s,c=setup();local one=insert(s,a);local two=insert(s,b)
    assert(not c:isItemAllowed(one) and not c:isItemAllowed(two))
    local view=assert(load(p,o,f,{one}));assert(view.category==a and view.itemCount==1)
    if a==b then assert(load(p,o,f,{two}))
    else rejected('mixed_categories',p,o,{two.id},1);assert(two.container==s) end
    assert(Frame.isClosed(c) and PN_EffigyRejectNativeInsertion()==false)
end end
-- Even absent named-callback lookup cannot admit the supported native item
-- categories through the factory's second guard. The callback also rejects an
-- unrelated item whose category happens to match the internal sentinel.
do
    local p,o,f,s,c=setup();local item=insert(s,'meat')
    local deny=PN_EffigyRejectNativeInsertion;PN_EffigyRejectNativeInsertion=nil
    assert(not c:isItemAllowed(item));PN_EffigyRejectNativeInsertion=deny
    item.category=Frame.NATIVE_CATEGORY;assert(not c:isItemAllowed(item))
end
-- Mixed first batch is rejected before a single mutation or packet.
local p,o,f,s,c=setup();local human=insert(s,'human');local feral=insert(s,'feral')
assert(not load(p,o,f,{human,feral}));assert(#s.items==2 and #c.items==0 and #F.packets==0)
-- Simultaneous empty-container requests serialize. Replay cannot duplicate or
-- reapply after unloading: the frame's durable revision is independent of UI.
assert(load(p,o,f,{human}));rejected('stale_revision',p,o,{feral.id},0)
rejected('mixed_categories',p,o,{feral.id},1)
s:AddItem(human);rejected('stale_revision',p,o,{human.id},0)
assert(load(p,o,f,{feral}));assert(#c.items==1 and #s.items==1 and revision(f)==2)
-- Queued vanilla transfers re-resolve source IDs at commit. If this command
-- wins, the queued transfer cannot find/move another copy; if it wins first,
-- the command has no item. Native *insertion* stays closed in either order.
p,o,f,s,c=setup();human=insert(s,'human');local other=F.container()
local function nativeCommit(source,destination,id)
    local item=source:getItemWithID(id);if not item then return false end
    source:Remove(item);destination:AddItem(item);return true
end
assert(load(p,o,f,{human}));assert(not nativeCommit(s,other,human.id))
assert(nativeCommit(c,other,human.id));assert(#c.items==0 and other:getItemWithID(human.id)==human)
p,o,f,s,c=setup();human=insert(s,'human');nativeCommit(s,other,human.id)
rejected('item_unavailable',p,o,{human.id},0)
-- Two same-category sources keep their actual identities, tissue/spoilage and
-- modData. Empty means physical emptiness, not depleted nutrition.
p,o,f,s,c=setup();human=insert(s,'human');local second=insert(s,'human')
local original=human.md;human.condition=17;human.age=123
assert(load(p,o,f,{human,second}));assert(human.md==original and human.condition==17 and human.age==123)
assert(#F.packets==4 and F.packets[1][2]==s and F.packets[2][2]==c)
assert(Server.inspect(p,o).visualState=='BODY_PART_LOADED')
s:AddItem(human);assert(Server.inspect(p,o).category=='human')
s:AddItem(second);assert(Server.inspect(p,o).visualState=='EMPTY')
local meat=insert(s,'meat');assert(load(p,o,f,{meat}).visualState=='MEAT_LOADED')
-- Capacity counts a whole batch; malformed settings fail closed.
p,o,f,s,c=setup();human=insert(s,'human');second=insert(s,'human');human.weight=11;second.weight=10
assert(not load(p,o,f,{human,second}));assert(#s.items==2 and #c.items==0)
ProjectNightfall.Config.POC.EffigyContainerCapacity=0/0
rejected('invalid_configuration',p,o,{human.id},0)
ProjectNightfall.Config.POC.EffigyContainerCapacity=20
-- Batch/malformed IDs, ownership, equipment, disabled config, guards, access.
for _,batch in ipairs({{}, {human.id,human.id}, {[2]=human.id}, {bad=human.id}, {0/0}, {math.huge}, {-1}}) do
    rejected('invalid_batch',p,o,batch,0)
end
human.equipped=true;rejected('item_unavailable',p,o,{human.id},0);human.equipped=false
s.noRemove=true;rejected('item_unavailable',p,o,{human.id},0);s.noRemove=nil
c.filter=nil;rejected('native_guard_missing',p,o,{human.id},0);c.filter=Frame.NATIVE_FILTER
SafeHouse=nil;rejected('inaccessible',p,o,{human.id},0)
F.install();p.square.blocked=true;rejected('inaccessible',p,o,{human.id},0);p.square.blocked=false
p.square.window=true;rejected('inaccessible',p,o,{human.id},0);p.square.window=false
p.dead=true;rejected('inaccessible',p,o,{human.id},0);p.dead=false
p.square={getX=function() return 12 end,getY=function() return 10 end,getZ=function() return 0 end}
rejected('inaccessible',p,o,{human.id},0)
ProjectNightfall.Config.POC.Enabled=false;rejected('unavailable',p,o,{human.id},0);ProjectNightfall.Config.POC.Enabled=true
-- Client execution is never a canonical-write fallback, even with valid IDs.
p,o,f,s,c=setup();human=insert(s,'human');isClient=function() return true end
rejected('unavailable',p,o,{human.id},0);assert(#c.items==0);isClient=function() return false end
-- Failed second move restores the original objects before publication.
second=insert(s,'human');local add=c.AddItem;local calls=0
c.AddItem=function(self,item) calls=calls+1;if calls==2 then error('injected second move') end;return add(self,item) end
rejected('move_failed',p,o,{human.id,second.id},0)
assert(#s.items==2 and #c.items==0 and #F.packets==0 and revision(f)==0)
c.AddItem=add
-- Reentrant callbacks see busy, never a half-moved authoritative snapshot.
c.onAdd=function() rejected('busy',p,o,{second.id},0);assert(not Server.inspect(p,o)) end
assert(load(p,o,f,{human}));c.onAdd=nil
-- A failed rollback retains actual objects and a quarantine marker. No cloning,
-- source-category reset or subsequent load can paper over uncertain state.
p,o,f,s,c=setup();human=insert(s,'human');second=insert(s,'human');s.failAdd=true
local nativeAdd=c.AddItem;local adds=0
c.AddItem=function(self,item) adds=adds+1;if adds==2 then error('second move refused') end;return nativeAdd(self,item) end
rejected('quarantined',p,o,{human.id,second.id},0);assert(f.md[Frame.KEY].quarantined=='rollback_uncertain')
assert(human.container==c and second.container==s);assert(not Server.inspect(p,o))
-- A published move is never rolled back on transport failure/retry.
p,o,f,s,c=setup();human=insert(s,'human');sendAddItemToContainer=function() error('transport failure') end
local view,why=load(p,o,f,{human});assert(view and why=='committed_sync_failed' and human.container==c)
rejected('quarantined',p,o,{human.id},0)
-- Unexpected native adapter errors are surfaced and quarantine the frame rather
-- than silently leaving an unknown operation retryable.
p,o,f,s,c=setup();human=insert(s,'human');c.hasRoomFor=function() error('broken native adapter') end
rejected('operation_failed',p,o,{human.id},0)
assert(human.container==s and f.md[Frame.KEY].quarantined=='operation_failed')
-- Native save reload is not simulated: only the same serialized metadata/actual
-- contents are reused here. No runtime queue or nutrition stockpile is saved.
p,o,f,s,c=setup();human=insert(s,'human');assert(load(p,o,f,{human}))
package.loaded['ProjectNightfall/PN_EffigyContainerServer']=nil
Server=require 'ProjectNightfall/PN_EffigyContainerServer'
assert(Server.inspect(p,o).revision==1 and human.container==c)
f.md[Frame.KEY].schemaVersion=2;rejected('unsupported_record',p,o,{human.id},1)
-- Untrusted coordinates/index/ID are re-resolved on the server; wrong object,
-- malformed data, client-supplied items/provenance and foreign modules do nothing.
p,o,f,s,c=setup();human=insert(s,'human')
local args={x=10,y=10,z=0,index=0,frameId=f.id,items={human.id},revision=0}
assert(Server.onCommand('other','load',p,args)==nil and #c.items==0)
args.frameId=f.id+1;Server.onCommand('ProjectNightfallEffigyContainer','load',p,args);assert(#c.items==0)
args.frameId=f.id;args.x=0/0;Server.onCommand('ProjectNightfallEffigyContainer','load',p,args);assert(#c.items==0)
args.x=10;assert(Server.onCommand('ProjectNightfallEffigyContainer','load',p,args));assert(#c.items==1)
Server.onCommand('ProjectNightfallEffigyContainer','load',p,args)
assert(#c.items==1 and F.replies[#F.replies].view.revision==1 and not F.replies[#F.replies].ok)
print('Effigy server transfer regressions passed (offline native facades)')
