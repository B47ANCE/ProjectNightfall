-- Actual MORTIS coordinator/model/event bus plus Nightfall provider; native boundaries mocked.
local authority=true
isClient=function()return not authority end
isServer=function()return authority end
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
local Util=require 'Mortis/Core/Util'
local Tissue=require 'Mortis/Runtime/TissueModel'
local Material=require 'Mortis/Runtime/DetachedMaterialModel'
local Mortis={FoodSources=Sources,ZombieHunger=Hunger,Events=Bus.new(),DetachedMaterialModel=Material,
 Authority={canWriteCanonicalState=function()return authority end},getStableId=function(z)return z.id end,
 DetachedParts={read=function(item)return {schemaVersion=1,regionId='arm',speciesId='Mortis.Humanoid',sourceStableId=item.id,
  classifications={['ProjectNightfall.sourceSignature']={signature='regular'}},subtree=item.subtree}end}}
_G.Mortis=Mortis
Mortis.registerFoodSourceProvider=Sources.register
ProjectNightfall={Config={POC={EffigyCaloriesPerFullFeed=2000}},MortisIntegration={TYPE_FERAL='Feral',getTypeId=function(z)return z.typeId end}}
local realRequire=require
require=function(name)
 if name=='Mortis/init' then return Mortis end
 if name=='ProjectNightfall/PN_MortisIntegration' then return ProjectNightfall.MortisIntegration end
 if name=='ProjectNightfall/PN_FeralAI' then return {} end
 return realRequire(name)
end
local Effigies=require 'ProjectNightfall/PN_Effigies'
local provider=Sources.registry.entries['ProjectNightfall.effigies']
assert(provider and provider.transactionVersion==1 and provider.reserve and provider.commit and provider.rollback,
 'effigies must implement the transactional food contract')
local counter=0
local function actor()
 counter=counter+1
 local z={id='actor-'..counter,typeId='Feral',level=.8,x=10,y=10,z=0}
 function z:getX()return self.x end;function z:getY()return self.y end;function z:getZ()return self.z end
 function z:getTarget()return nil end
 function z:getStats()return {get=function()return self.level end,set=function(_,_,v)if not self.ignore then self.level=v end end}end
 states[z]={hunger=.8,hungerBackend=Hunger.BACKEND,lastWorldAgeHours=100,desiccation=0}
 return z
end
local function fixture(legacy)
 local z=actor();local data={};local object={x=10,y=10,z=0,removed=0,live=true}
 function object:getX()return self.x end;function object:getY()return self.y end;function object:getZ()return self.z end
 function object:getSquare()return self.live and self or nil end
 function object:getModData()
  if self.failPersist and self.entry and self.entry.status=='consumed' then self.failPersist=false;error('persist failed')end
  return data
 end
 function object:transmitModData()self.transmissions=(self.transmissions or 0)+1 end
 function object:removeFromWorld()self.removed=self.removed+1 end
 function object:removeFromSquare()self.removed=self.removed+1;self.live=false end
 local parts={}
 for i=1,3 do
  parts[i]={id='source-'..counter..'-'..i,subtree=not legacy and {schemaVersion=1,rootRegionId='arm',
   regions={arm={regionId='arm',material=assert(Tissue.new(10,{nutritionDensity={calories=20}}))}}}or nil}
 end
 local composition=assert(Effigies.snapshotComposition(parts))
 object.entry=assert(Effigies.registerPlaced(object,composition,{id='food-'..counter}))
 -- Keep each fixture isolated from previous nearby active sources.
 for _,nearby in ipairs(Effigies.nearby(z,1))do if nearby.entry~=object.entry then nearby.entry.status='test-inactive' end end
 return z,object,data,object.entry
end
local function unchanged(z,object,data,entry)
 assert(z.level==.8 and states[z].hunger==.8 and object.removed==0)
 assert(entry.status=='active' and entry.claim==nil and data[Effigies.DATA_KEY].status=='active')
 assert(Effigies.nutritionSnapshot(entry.composition).calories==600)
end
local z,object,data,entry=fixture()
local candidate=assert(provider.findNearby(z,2));local before=Util.deepCopy(entry.composition)
local tx={};local quote=provider.reserve(z,candidate,tx)
assert(quote.reserved and math.abs(quote.foodValue-.3)<1e-6 and entry.status=='active' and object.removed==0)
assert(not Effigies.claim(entry.id,actor(),'destroy'),'food lease excludes destruction')
assert(provider.reserve(actor(),candidate,{}).reserved==false,'one actor holds the source lease')
assert(provider.rollback(z,candidate,tx)==true and provider.rollback(z,candidate,tx)==true)
unchanged(z,object,data,entry)

z,object,data,entry=fixture();z.ignore=true
assert(not Hunger.updateFoodSeeking(z));unchanged(z,object,data,entry)
z.ignore=false;object.failPersist=true
assert(not Hunger.updateFoodSeeking(z));unchanged(z,object,data,entry)

-- Force an abort after provider commit; world cleanup must still be reversible.
local Faults=require 'Mortis/Core/FaultIsolation';local dispatch=Faults.call
Faults.call=function(owner,callback,...)
 local ok,value=dispatch(owner,callback,...)
 if callback=='commit' and ok then return false,'abort after source commit' end
 return ok,value
end
assert(not Hunger.updateFoodSeeking(z));unchanged(z,object,data,entry)
Faults.call=dispatch
local feeds=0
Mortis.Events:on('ZombieFed',function(_,_,_,metadata)if metadata.sourceId==entry.id then feeds=feeds+1 end end)
assert(Hunger.updateFoodSeeking(z) and math.abs(z.level-.5)<1e-6)
assert(entry.status=='consumed' and Effigies.nutritionSnapshot(entry.composition).edible==0)
assert(object.removed==2 and feeds==1 and data[Effigies.DATA_KEY].status=='consumed')
Mortis.Events:emit('ZombieFed',z,.8,.5,{providerId=provider.id,sourceId=entry.id,source=object})
assert(object.removed==2,'duplicate events must not repeat native cleanup')
assert(not Effigies.restorePlaced(object),'consumed tombstone must not re-enroll after reload')
assert(not Effigies.registerPlaced(object,before),'registration must not revive a consumed tombstone')

-- Reserve exceptions must release a lease even before a complete plan exists.
z,object,data,entry=fixture()
local apply=Material.applyLoss
Material.applyLoss=function()error('planning fault')end
assert(not Hunger.updateFoodSeeking(z));unchanged(z,object,data,entry)
Material.applyLoss=apply
assert(Effigies.claim(entry.id,z,'destroy'),'aborted reservation releases its lease')
assert(Effigies.completeClaim(entry.id,'destroyed'))

-- Commit rechecks the actual source and revision, not candidate-supplied hints.
z,object,data,entry=fixture()
candidate=assert(provider.findNearby(z,2));tx={}
assert(provider.reserve(z,candidate,tx).reserved)
entry.revision=entry.revision+1
assert(not provider.commit(z,candidate,tx))
assert(provider.rollback(z,candidate,tx))
assert(entry.revision==1 and object.removed==0,'a foreign revision is not rewound')

-- A rollback cannot overwrite a new foreign source revision after commit.
z,object,data,entry=fixture()
candidate=assert(provider.findNearby(z,2));tx={}
assert(provider.reserve(z,candidate,tx).reserved and provider.commit(z,candidate,tx))
entry.revision=entry.revision+1
assert(not provider.rollback(z,candidate,tx))
assert(entry.status=='consumed' and entry.revision==2 and object.removed==0)

-- Failed post-success native cleanup leaves an inert consumed tombstone.
z,object,data,entry=fixture()
object.removeFromWorld=function()error('native cleanup unavailable')end
assert(Hunger.updateFoodSeeking(z))
assert(entry.status=='consumed' and data[Effigies.DATA_KEY].status=='consumed' and object.removed==1)
assert(not provider.findNearby(z,2) and not Effigies.restorePlaced(object))

z,object,data,entry=fixture(true)
assert(Hunger.updateFoodSeeking(z) and math.abs(z.level-.3)<1e-6,'legacy material-less source retains its .5 value')
z,object,data,entry=fixture()
assert(Effigies.claim(entry.id,z,'consume'))
authority=false
assert(not Hunger.updateFoodSeeking(z) and not Effigies.completeClaim(entry.id,'destroyed'))
assert(not Effigies.consumeMaterial(entry) and entry.status=='claimed' and object.removed==0)
authority=true
assert(Effigies.completeClaim(entry.id,'destroyed'))
z,object,data,entry=fixture();z.z=1
candidate={sourceId=entry.id,source=object,signature='regular'}
assert(provider.reserve(z,candidate,{}).reserved==false,'cross-floor/stale candidate rejected')
z.z=0;object.live=false
assert(provider.reserve(z,candidate,{}).reserved==false,'unloaded object rejected')
print('Nightfall effigy/MORTIS transactions preserve tissue, claims, hunger and world objects on failure')
