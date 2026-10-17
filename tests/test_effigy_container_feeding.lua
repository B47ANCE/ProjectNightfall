-- Real pinned MORTIS hunger coordinator, event bus, material and provenance;
-- native stats, world objects and transport boundaries are offline facades.
local F=dofile('tests/helpers/effigy_container_fixture.lua');F.install()
CharacterStat={HUNGER='HUNGER'}
getGameTime=function()return {getWorldAgeHours=function()return 100 end}end
package.loaded['Mortis/Core/Logger']={rateLimited=function()end,once=function()end}
package.loaded['Mortis/Core/Profiler']={measure=function(_,fn)return fn()end}
local states=setmetatable({},{__mode='k'})
package.loaded['Mortis/Runtime/Components']={get=function(z)return states[z]end,
 allFor=function(z)return {['Mortis.ZombieHunger']=states[z]}end,
 set=function(z,_,v)states[z]=v;return v end}
local Sources=require 'Mortis/API/FoodSources'
local Hunger=require 'Mortis/Runtime/ZombieHungerRuntime'
local Bus=require 'Mortis/Core/EventBus'
local Detached=require 'Mortis/API/DetachedParts'
local Material=require 'Mortis/Runtime/DetachedMaterialModel'
local Util=require 'Mortis/Core/Util'
local Mortis={FoodSources=Sources,ZombieHunger=Hunger,Events=Bus.new(),DetachedParts=Detached,
 DetachedMaterialModel=Material,Authority=require 'Mortis/Runtime/Authority',
 getStableId=function(z)return z.id end,registerFoodSourceProvider=Sources.register}
_G.Mortis=Mortis;package.loaded['Mortis/init']=Mortis
ProjectNightfall={MortisIntegration={TYPE_FERAL='Feral',TYPE_SMART_FERAL='Smart',
 getTypeId=function(z)return z.typeId end}}
package.loaded['ProjectNightfall/PN_MortisIntegration']=ProjectNightfall.MortisIntegration
package.loaded['ProjectNightfall/PN_FeralAI']={}
local hooks={}
for _,name in ipairs({'OnObjectAdded','OnObjectAboutToBeRemoved','LoadGridsquare'}) do
 local event=name;Events[event]={Add=function(fn)hooks[event]=fn end}
end
local State=require 'ProjectNightfall/PN_EffigyContainerState'
local Frame=require 'ProjectNightfall/PN_EffigyContainer'
local Server=require 'ProjectNightfall/PN_EffigyContainerServer'
local Food=require 'ProjectNightfall/PN_EffigyContainerFeeding'
local provider=assert(Sources.get(Food.PROVIDER_ID))
assert(provider.transactionVersion==1 and hooks.LoadGridsquare and hooks.OnObjectAdded)
local packets={}
sendReplaceItemInContainer=function(c,a,b)assert(a==b);packets[#packets+1]={'replace',c,a}end
sendRemoveItemFromContainer=function(c,item)packets[#packets+1]={'remove',c,item}end
local function meat(calories)
 local item=F.item('meat');item.calories=calories or 200;item.age=17;item.condition=41
 function item:getCalories()return self.calories end
 function item:getCarbohydrates()return 2 end
 function item:getLipids()return 3 end
 function item:getProteins()return 4 end
 return item
end
local count=0
local function fixture(category)
 count=count+1
 local player,object,frame,root,contents,objects=F.world()
 function object:getX()return self.square:getX()end
 function object:getY()return self.square:getY()end
 function object:getZ()return self.square:getZ()end
 function object:removeFromWorld()error('reusable frame must survive')end
 function object:removeFromSquare()error('reusable frame must survive')end
 local z={id='feeder-'..count,typeId='Feral',level=.8,x=10,y=10,z=0}
 function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return self.z end
 function z:getSquare()return player.square end;function z:getTarget()return nil end
 function z:isDead()return self.dead==true end
 function z:getStats()return {get=function()return self.level end,set=function(_,_,v)if not self.ignore then self.level=v end end}end
 states[z]={hunger=.8,hungerBackend=Hunger.BACKEND,lastWorldAgeHours=100,desiccation=0}
 local item=category=='meat' and meat() or F.item(category or 'regular');root:AddItem(item)
 assert(Server.load(player,object,{item.id},0));assert(Food.track(object))
 packets={}
 return z,player,object,frame,root,contents,item,objects
end
local function calories(item) return select(2,Material.validate(Detached.read(item))).nutrition.calories end
local z,p,o,f,s,c,item,objects=fixture('regular')
local before=Util.deepCopy(item.md);local record=f.md[Frame.KEY]
local candidate=assert(provider.findNearby(z,12));local context={}
local quote=provider.reserve(z,candidate,context)
assert(quote.reserved and quote.foodValue==.1 and State.isBusy(c))
assert(not Server.load(p,o,{F.item('regular').id},record.revision))
assert(provider.reserve(z,candidate,{}).reserved==false)
assert(provider.rollback(z,candidate,context) and provider.rollback(z,candidate,context))
assert(not State.isBusy(c) and Util.deepCopy(item.md).MortisDetachedPart.sourceStableId==before.MortisDetachedPart.sourceStableId)
assert(#packets==0 and record.pendingFeed==nil and z.level==.8)
assert(require('ProjectNightfall/PN_EffigyFoodPlan').same(item.md,before))
-- Actual coordinator commits one part, retains it and the reusable frame, and
-- does not expose food again when all canonical edible tissue has gone.
assert(Hunger.updateFoodSeeking(z,12));assert(math.abs(z.level-.7)<1e-6)
assert(item.container==c and #c.items==1 and calories(item)==0 and record.revision==2)
assert(#packets==1 and packets[1][1]=='replace' and record.pendingFeed==nil)
assert(o.saveRequests>=4)
assert(Frame.inspect(o).visualState=='BODY_PART_LOADED' and not provider.findNearby(z,12))
local other=meat();s:AddItem(other);assert(not Server.load(p,o,{other.id},2))
-- Add real stock of the same category, even from another individual, and feed
-- again through the same frame. A prior ZombieFed replay cannot affect it.
local more=F.item('regular');s:AddItem(more);assert(Server.load(p,o,{more.id},2))
Mortis.Events:emit('ZombieFed',z,.8,.7,{providerId=Food.PROVIDER_ID,sourceId=candidate.sourceId,source=o})
assert(calories(more)==200 and record.revision==3)
assert(Hunger.updateFoodSeeking(z,12));assert(math.abs(z.level-.6)<1e-6 and record.revision==4)
assert(#c.items==2 and calories(more)==0)
-- Native unloading physically empties the frame and permits the next category.
s:AddItem(item);s:AddItem(more);assert(Server.load(p,o,{other.id},4))
assert(Hunger.updateFoodSeeking(z,12));assert(other.container==nil and #c.items==0)
assert(Frame.inspect(o).visualState=='EMPTY')
-- Meat works for ordinary, Feral and Smart infected without legacy reaction /
-- search / owner claims, and rollback keeps exact native condition and age.
for _,typeId in ipairs({'Regular','Feral','Smart'})do
 z,p,o,f,s,c,item=fixture('meat');z.typeId=typeId
 local md=item.md;assert(Hunger.updateFoodSeeking(z,12))
 assert(item.container==nil and #c.items==0 and item.md==md and item.age==17 and item.condition==41)
 assert(f.md[Frame.KEY].claim==nil and f.md.ProjectNightfallEffigy==nil)
end
-- Existing body-part reactions remain authoritative; no hungry Feral or Smart
-- may consume the source categories their old policy avoids/destroys.
for _,case in ipairs({{'human','Regular',true},{'regular','Regular',false},
 {'regular','Feral',true},{'regular','Smart',false},{'feral','Feral',false},
 {'feral','Smart',false},{'smartFeral','Smart',false}})do
 z,p,o,f,s,c,item=fixture(case[1]);z.typeId=case[2]
 assert((provider.findNearby(z,12)~=nil)==case[3])
end
-- Failure after provider commit compensates both hunger and actual resource.
local Faults=require 'Mortis/Core/FaultIsolation';local dispatch=Faults.call
for _,category in ipairs({'regular','meat'})do
 z,p,o,f,s,c,item=fixture(category);local original=Util.deepCopy(item.md)
 Faults.call=function(owner,callback,...)
  local ok,value=dispatch(owner,callback,...)
  if owner=='food-source:'..Food.PROVIDER_ID and callback=='commit' and ok then return false,'abort after commit' end
  return ok,value
 end
 assert(not Hunger.updateFoodSeeking(z,12));Faults.call=dispatch
 assert(z.level==.8 and states[z].hunger==.8 and item.container==c and #c.items==1)
 assert(require('ProjectNightfall/PN_EffigyFoodPlan').same(item.md,original))
 assert(f.md[Frame.KEY].revision==1 and f.md[Frame.KEY].pendingFeed==nil and #packets==0)
 assert(not State.isBusy(c));assert(Hunger.updateFoodSeeking(z,12))
end
-- Failure before source commit restores hunger without ever consuming stock.
z,p,o,f,s,c,item=fixture('meat')
Faults.call=function(owner,callback,...)
 local ok,value=dispatch(owner,callback,...)
 if owner=='food-source:'..Food.PROVIDER_ID and callback=='commit' and ok then
  ProjectNightfall.Config.POC.Enabled=false;return false,'disabled after commit'
 end
 return ok,value
end
assert(not Hunger.updateFoodSeeking(z,12));Faults.call=dispatch
assert(item.container==c and z.level==.8 and f.md[Frame.KEY].pendingFeed==nil)
ProjectNightfall.Config.POC.Enabled=true
z,p,o,f,s,c,item=fixture('regular');z.ignore=true
assert(not Hunger.updateFoodSeeking(z,12));assert(calories(item)==200 and not State.isBusy(c))
z.ignore=false
local apply=Detached.applyMaterialLoss
Detached.applyMaterialLoss=function()error('injected owner-write failure')end
assert(not Hunger.updateFoodSeeking(z,12));Detached.applyMaterialLoss=apply
assert(z.level==.8 and calories(item)==200 and f.md[Frame.KEY].pendingFeed==nil)
-- Missing/failed native save capability refuses or compensates before exposing
-- a retryable successful feed; no client-authoritative persistence fallback.
z,p,o,f,s,c,item=fixture('regular');local save=o.flagForHotSave;o.flagForHotSave=nil
assert(not Hunger.updateFoodSeeking(z,12) and z.level==.8 and calories(item)==200 and not State.isBusy(c))
local calls=0;o.flagForHotSave=function(self)
 calls=calls+1;if calls==2 then error('save request fault after resource write') end;return save(self)
end
assert(not Hunger.updateFoodSeeking(z,12));assert(z.level==.8 and calories(item)==200)
assert(f.md[Frame.KEY].pendingFeed==nil and not State.isBusy(c) and #packets==0)
-- Partial owner writes across multiple canonical regions are also reversible;
-- inedible tissue remains on the actual part and never unlocks its category.
z,p,o,f,s,c,item=fixture('regular')
local Tissue=require 'Mortis/Runtime/TissueModel'
item.md.MortisDetachedPart.subtree.regions.hand={regionId='hand',parent='leftArm',
 material=assert(Tissue.new(8,{edible=4,nutritionDensity={calories=10}}))}
local original=Util.deepCopy(item.md);local applied=0
Detached.applyMaterialLoss=function(...)
 applied=applied+1;if applied==2 then error('second region write failed') end
 return apply(...)
end
assert(not Hunger.updateFoodSeeking(z,12));Detached.applyMaterialLoss=apply
assert(require('ProjectNightfall/PN_EffigyFoodPlan').same(item.md,original) and z.level==.8)
assert(Hunger.updateFoodSeeking(z,12));assert(math.abs(z.level-.68)<1e-6)
assert(item.md.MortisDetachedPart.subtree.regions.hand.material.remaining==4 and #c.items==1)
-- Commit rechecks current native membership, provenance, frame revision and
-- source position; a transfer winning first is never repaired with stale stock.
for _,change in ipairs({'move','revision','provenance','position','wall','dead','age'})do
 z,p,o,f,s,c,item=fixture('regular');candidate=assert(provider.findNearby(z,12));context={}
 assert(provider.reserve(z,candidate,context).reserved)
 if change=='move'then s:AddItem(item)
 elseif change=='revision'then f.md[Frame.KEY].revision=9
 elseif change=='provenance'then item.md.MortisDetachedPart.classifications['ProjectNightfall.sourceSignature'].signature='feral'
 elseif change=='position'then z.z=1
 elseif change=='wall'then p.square.blocked=true
 elseif change=='dead'then z.dead=true
 elseif change=='age'then item.age=99 end
 assert(not provider.commit(z,candidate,context));assert(provider.rollback(z,candidate,context))
 assert(not State.isBusy(c) and calories(item)==200 and #packets==0)
end
-- Fully noncanonical legacy parts can be stored, never yield invented calories.
z,p,o,f,s,c,item=fixture('human');item.md.MortisDetachedPart.subtree=nil
assert(not provider.findNearby(z,12))
-- Native success followed by a failed publication stays consumed/quarantined;
-- duplicate events cannot remove/recreate items or change hunger again.
z,p,o,f,s,c,item=fixture('regular')
local send=sendReplaceItemInContainer;sendReplaceItemInContainer=function()error('offline transport fault')end
assert(Hunger.updateFoodSeeking(z,12));sendReplaceItemInContainer=send
assert(calories(item)==0 and f.md[Frame.KEY].quarantined=='feed_committed_sync_failed')
assert(not State.isBusy(c) and not provider.findNearby(z,12))
-- Discovery from native load hooks, empty/refill, stale square and identity.
z,p,o,f,s,c,item,objects=fixture('meat');Food.untrack(o);assert(not provider.findNearby(z,12))
hooks.LoadGridsquare(o.square);assert(provider.findNearby(z,12))
hooks.OnObjectAboutToBeRemoved(o);assert(not provider.findNearby(z,12))
hooks.OnObjectAdded(o);assert(provider.findNearby(z,12))
objects[1]=nil;assert(not provider.findNearby(z,12));objects[1]=o;assert(Food.track(o))
-- Save/reload fixture of a retained uncertain intent refuses both loading and
-- feeding; there is no automatic clearing or material reconstruction.
f.md[Frame.KEY].pendingFeed={schemaVersion=1,sourceId='old',itemId=item.id}
assert(not Server.inspect(p,o) and not provider.findNearby(z,12))
assert(not Server.load(p,o,{item.id},1));f.md[Frame.KEY].pendingFeed=nil
-- A detached item subsequently placed into the world by a foreign operation
-- must not be pulled back into the frame by compensation.
z,p,o,f,s,c,item=fixture('meat');candidate=assert(provider.findNearby(z,12));context={}
assert(provider.reserve(z,candidate,context).reserved and provider.commit(z,candidate,context))
item.world={foreign=true}
assert(not provider.rollback(z,candidate,context))
assert(item.container==nil and item.world.foreign and #c.items==0 and not State.isBusy(c))
assert(f.md[Frame.KEY].quarantined=='feed_rollback_uncertain')
z,p,o,f,s,c,item=fixture('meat')
-- Client and disabled feature paths cannot provide a candidate or mutate stock.
isClient=function()return true end;assert(not provider.findNearby(z,12))
assert(provider.reserve(z,{source=o},{}).reserved==false);assert(item.container==c)
isClient=function()return false end;ProjectNightfall.Config.POC.Enabled=false
assert(not provider.findNearby(z,12));ProjectNightfall.Config.POC.Enabled=true
-- A foreign canonical write after a failed commit is not overwritten by
-- compensation. The actual MORTIS coordinator quarantines this provider too.
z,p,o,f,s,c,item=fixture('regular')
Faults.call=function(owner,callback,...)
 local ok,value=dispatch(owner,callback,...)
 if owner=='food-source:'..Food.PROVIDER_ID and callback=='commit' and ok then
  item.md.MortisDetachedPart.metadata={foreign='preserve'}
  return false,'abort with foreign canonical state'
 end
 return ok,value
end
local fed,reason=Hunger.updateFoodSeeking(z,12);Faults.call=dispatch
assert(not fed and reason=='food-transaction-rollback-failed')
assert(item.md.MortisDetachedPart.metadata.foreign=='preserve' and calories(item)==0)
assert(f.md[Frame.KEY].quarantined=='feed_rollback_uncertain' and f.md[Frame.KEY].pendingFeed)
assert(not State.isBusy(c) and not Server.inspect(p,o))
print('Reusable effigy feeding preserves actual stock, categories, hunger and frame (offline facades)')
