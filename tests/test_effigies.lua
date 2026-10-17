next=nil -- Build 42 Kahlua release compatibility.
local signature="human"
local TissueModel=require "Mortis/Runtime/TissueModel"
local DetachedMaterialModel=require "Mortis/Runtime/DetachedMaterialModel"
local Mortis={
    DetachedParts={read=function(item) return {schemaVersion=1,regionId=item.region,speciesId="Mortis.Humanoid",sourceStableId=item.source,sourceTypeId=item.typeId,classifications={
        ["ProjectNightfall.sourceSignature"]={signature=item.signature or signature}
    },subtree=item.subtree} end},
    Events=require("Mortis/Core/EventBus").new(),
    DetachedMaterialModel=DetachedMaterialModel,
    ZombieHunger={isHungry=function(zombie) return zombie.hungry==true end},
    Authority={canWriteCanonicalState=function() return true end},
    getStableId=function() return "zombie-1" end,
    FoodSources={has=function() return false end},
}
function Mortis.registerFoodSourceProvider(definition) Mortis.foodProvider=definition end
local Integration={TYPE_TRANSFORMING="Transforming",TYPE_FERAL="Feral",TYPE_SMART_FERAL="Smart",getTypeId=function(z) return z.typeId end}
local realRequire=require
require=function(name)
    if name=="Mortis/init" then return Mortis end
    if name=="ProjectNightfall/PN_MortisIntegration" then
        ProjectNightfall=ProjectNightfall or {}; ProjectNightfall.MortisIntegration=Integration; return Integration
    end
    if name=="ProjectNightfall/PN_FeralAI" then return {playerKey=function(player) return player and player.ownerKey end} end
    return realRequire(name)
end
local api=dofile(arg[1])
local composition=assert(api.snapshotComposition({{region="leftArm",source="z1",signature="feral"},{region="leftHand",source="z1",signature="feral"},{region="rightArm",source="z1",signature="feral"}}))
assert(composition.signature=="feral" and composition.partCount==3)
local mixed,reason=api.snapshotComposition({{signature="human"},{signature="feral"}})
assert(not mixed and reason:find("mixed",1,true))
assert(api.reactionFor({hungry=false},"human").action=="attract")
assert(api.reactionFor({hungry=true},"human").action=="consume")
assert(api.reactionFor({typeId="Feral"},"regular").action=="consume")
assert(api.reactionFor({typeId="Smart"},"feral").searchHours==24)
assert(api.reactionFor({typeId="Smart"},"smartFeral").enraged==true)
assert(api.reactionFor({},"smartFeral").action=="avoid")
local consumed=0
local function contains(self,item) return item.container==self end
local function remove(self,item) if item.container==self then item.container=nil; consumed=consumed+1 end end
local function add(self,item) item.container=self; return item end
local partContainer={contains=contains,Remove=remove,AddItem=add}
local buildParts={}
for index=1,3 do
    buildParts[index]={region="leftArm",source="z-build",signature="feral",
        subtree={schemaVersion=1,rootRegionId="leftArm",regions={leftArm={regionId="leftArm",
            material=assert(TissueModel.new(10,{nutritionDensity={calories=20,proteins=2}}))}}},
        container=partContainer,getContainer=function(self) return self.container end,
        getOutermostContainer=function() return partContainer.owner end,
        UseAndSync=function() consumed=consumed+1 end}
end
local inventory={AddItem=add,Remove=remove,contains=contains}
instanceItem=function(fullType)
    assert(fullType=="ProjectNightfall.Effigy")
    local data={}; return {getModData=function() return data end,data=data}
end
partContainer.owner=inventory
local builder={getInventory=function() return inventory end,ownerKey="username:builder"}
-- An absent setting uses the enabled default; missing knowledge fails closed.
assert(not api.validateConstruction(builder,buildParts))
SandboxVars={ProjectNightfall={RequireEffigyKnowledge=false}}
assert(api.validateConstruction(builder,buildParts))
SandboxVars={ProjectNightfall={RequireEffigyKnowledge=true}}
assert(not api.validateConstruction(builder,buildParts))
local Archive=require "ProjectNightfall/PN_ResearchArchive"
local knowledgeData={}
builder.getModData=function() return knowledgeData end
assert(not api.validateConstruction(builder,buildParts))
assert(not Archive.learn(builder,"NF-FIELD-026"))
assert(Archive.learn(builder,"NF-UV-003"))
assert(Archive.learn(builder,"NF-FIELD-026"))
assert(api.validateConstruction(builder,buildParts))
local originalQuery=Archive.hasKnowledge
Archive.hasKnowledge=function() error("knowledge provider failed") end
assert(not api.validateConstruction(builder,buildParts))
Archive.hasKnowledge=originalQuery
SandboxVars.ProjectNightfall.RequireEffigyKnowledge=false
assert(api.validateConstruction(builder,buildParts))
assert(not api.validateConstruction(builder,{buildParts[1],buildParts[1],buildParts[2]}))
partContainer.owner={}
assert(not api.validateConstruction(builder,buildParts))
partContainer.owner=inventory
partContainer.contains=function() return false end
assert(not api.validateConstruction(builder,buildParts))
partContainer.contains=function() error("broken container provider") end
assert(not api.validateConstruction(builder,buildParts))
partContainer.contains=contains
local originalRemove=partContainer.Remove
partContainer.Remove=function(self,item)
    if item==buildParts[2] then error("second removal failure") end
    originalRemove(self,item)
end
assert(not api.construct(builder,buildParts))
for _,part in ipairs(buildParts) do assert(part.container==partContainer) end
partContainer.Remove=function() end
assert(not api.construct(builder,buildParts))
partContainer.Remove=originalRemove
inventory.AddItem=function(self,item) add(self,item); error("insert then throw") end
assert(not api.construct(builder,buildParts))
for _,part in ipairs(buildParts) do assert(part.container==partContainer) end
inventory.AddItem=add
local factory=instanceItem
instanceItem=function(fullType)
    assert(not api.construct(builder,buildParts),"reentrant construction must fail")
    return factory(fullType)
end
consumed=0
local built,builtComposition=api.construct(builder,buildParts)
assert(built and builtComposition.signature=="feral" and consumed==3)
assert(built.data.ProjectNightfallEffigyComposition.partCount==3)
assert(built.data.ProjectNightfallEffigyOwnerPlayerKey=="username:builder")
local tooSmall,buildError=api.construct({getInventory=function() return inventory end},{buildParts[1],buildParts[2]})
assert(not tooSmall and buildError=="three detached parts required")
local objectData={}
local object={x=10,y=10,z=0,getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function(s)return s.z end,getModData=function()return objectData end}
local placed=assert(api.registerPlaced(object,composition,{id="effigy-1",ownerPlayerKey="username:builder"}))
assert(placed.id=="effigy-1" and objectData[api.DATA_KEY].status=="active")
assert(objectData[api.DATA_KEY].ownerPlayerKey=="username:builder")
local zombie={x=11,y=10,z=0,typeId="Smart",getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function(s)return s.z end}
local found,reaction=api.findNearbyReaction(zombie,5)
assert(found==placed and reaction.action=="destroy_search")
local claimed,claimedEntry=api.claim("effigy-1",zombie,"destroy")
assert(claimed and claimedEntry.ownerPlayerKey=="username:builder")
assert(not api.claim("effigy-1",zombie,"destroy"),"claims must be atomic")
assert(api.completeClaim("effigy-1","destroyed"))
assert(#api.nearby(zombie,5)==0)
local malformedData={[api.DATA_KEY]={schemaVersion=1,id="bad",status="active",composition={schemaVersion=1,signature="feral",partCount=3,parts={}}}}
local malformed={getModData=function() return malformedData end,getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end}
assert(not api.restorePlaced(malformed),"malformed persisted composition must fail closed")
local failingData={}
local failingObject={getX=function()return 20 end,getY=function()return 20 end,getZ=function()return 0 end,
    getModData=function() error("modData unavailable") end}
assert(not api.registerPlaced(failingObject,composition,{id="effigy-fail"}))
assert(Mortis.foodProvider and Mortis.foodProvider.sourceClass=="ProjectNightfall.effigy")
local edibleData={}
local foodComposition={schemaVersion=1,signature="regular",partCount=builtComposition.partCount,parts={}}
for index,part in ipairs(builtComposition.parts) do
    foodComposition.parts[index]={schemaVersion=part.schemaVersion,regionId=part.regionId,speciesId=part.speciesId,
        sourceStableId=part.sourceStableId,sourceTypeId=part.sourceTypeId,signature="regular",materialRecord=part.materialRecord}
end
local edibleObject={x=30,y=30,z=0,getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function(s)return s.z end,
    getSquare=function(self)return self end,getModData=function()return edibleData end,removeFromWorld=function()end,removeFromSquare=function()end}
assert(api.registerPlaced(edibleObject,foodComposition,{id="effigy-food"}))
local eater={x=30,y=30,z=0,typeId="Feral",getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function(s)return s.z end}
local candidate=assert(Mortis.foodProvider.findNearby(eater,5))
assert(math.abs(candidate.foodValue-.3)<.000001,"effigy food value must derive from canonical calories")
local tx={}
local result=Mortis.foodProvider.reserve(eater,candidate,tx)
assert(result.reserved and math.abs(result.foodValue-.3)<.000001)
assert(Mortis.foodProvider.commit(eater,candidate,tx))
Mortis.Events:emit("ZombieFed",eater,.8,.5,{providerId=Mortis.foodProvider.id,sourceId=candidate.sourceId,source=candidate.source})
assert(result.nutrition.calories==600 and #api.nearby(eater,5)==0)
local legacyData={}
local legacyComposition={schemaVersion=1,signature="regular",partCount=3,parts={}}
for index=1,3 do legacyComposition.parts[index]={schemaVersion=1,regionId="leftArm",speciesId="Mortis.Humanoid",
    sourceStableId="legacy-"..index,signature="regular"} end
local legacyObject={x=40,y=40,z=0,getX=function(s)return s.x end,getY=function(s)return s.y end,getZ=function(s)return s.z end,
    getSquare=function(self)return self end,getModData=function()return legacyData end,removeFromWorld=function()end,removeFromSquare=function()end}
assert(api.registerPlaced(legacyObject,legacyComposition,{id="effigy-legacy"}))
eater.x,eater.y=40,40
local legacyCandidate=assert(Mortis.foodProvider.findNearby(eater,5))
local legacyTx={}
assert(legacyCandidate.foodValue==.5 and Mortis.foodProvider.reserve(eater,legacyCandidate,legacyTx).reserved,
    "material-less legacy effigies retain their migration fallback")
assert(Mortis.foodProvider.commit(eater,legacyCandidate,legacyTx))
Mortis.Events:emit("ZombieFed",eater,.8,.3,{providerId=Mortis.foodProvider.id,sourceId=legacyCandidate.sourceId,source=legacyCandidate.source})
print("Project Nightfall effigy composition/reaction checks passed")
