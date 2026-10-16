-- Real anatomy persistence, trauma promotion and dose coordinator; only native
-- entity/game services and the test species/channel are provided by this harness.
local species={id="UV.Integration",version=1,defaultRegion="leftArm",regions={
    leftArm={integrity=100},rightArm={integrity=100}}}
package.loaded["Mortis/API/Species"]={get=function() return species end,has=function() return true end,
    resolveRegion=function(_,id) return species.regions[id] and id end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function() return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function(id)
    if id=="burn" then return {structuralMultiplier=.25,bleedMultiplier=0} end
end}
local data={}
local entity={getModData=function() return data end}
local effects=0
local provenance={}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function(name,_,result)
    if name=="onTrauma" then effects=effects+1;provenance[#provenance+1]=result.flags end
end}
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local originalFlush=Anatomy.flush
local flushes=0
Anatomy.flush=function(...)
    flushes=flushes+1
    if flushes==2 then return false,"injected native persistence failure" end
    return originalFlush(...)
end
local profiles={}
for id in pairs(species.regions) do
    profiles[id]={transmission=1,exposureFactor=1,capacity=100,naturalCapFraction=.64,
        thresholds={.10,.20},woundMagnitudes={40,80}}
end
assert(not Tissue.advance(entity,{unknown=profiles.leftArm},{natural=2,artificial=0},0,5))
assert(data[Tissue.KEY]==nil,"invalid anatomy must not create an unrecoverable journal")
assert(not Tissue.advance(entity,profiles,{natural=2,artificial=0},0,5))
assert(effects==1 and data[Tissue.KEY].pending)
assert(Anatomy.get(entity).regions.leftArm.integrity==90)
assert(Anatomy.get(entity).regions.rightArm.integrity==100,"failed region must roll back")
-- Discard both runtime caches. Recovery reads the actual saved anatomy and dose journal.
Anatomy.detach(entity)
package.loaded["ProjectNightfall/PN_UVTissueState"]=nil
Tissue=require "ProjectNightfall/PN_UVTissueState"
Anatomy.flush=originalFlush
assert(Tissue.recover(entity))
assert(effects==2,"recovery must not publish the first region's trauma again")
assert(data[Tissue.KEY].lastExposure.natural and not data[Tissue.KEY].lastExposure.artificial)
assert(provenance[1].uvNaturalIncrement==10 and provenance[2].uvNaturalIncrement==10)
assert(provenance[2].uvArtificialIncrement==0 and provenance[2].uvIntervalEndMinute==5,
    "recovered wound provenance must describe the original interval")
for id in pairs(species.regions) do
    assert(Anatomy.get(entity).regions[id].integrity==90)
    assert(data[Tissue.KEY].regions[id].naturalScore==10)
end
assert(Tissue.advance(entity,profiles,{natural=2,artificial=0},0,5) and effects==2)
assert(Tissue.advance(entity,profiles,{natural=0,artificial=2},5,10))
for id in pairs(species.regions) do
    assert(Anatomy.get(entity).regions[id].integrity==80)
    assert(data[Tissue.KEY].regions[id].naturalScore==10)
    assert(data[Tissue.KEY].regions[id].artificialScore==10)
    assert(Anatomy.get(entity).regions[id].wounds["ProjectNightfall.UVBurn"].stage==2)
end
assert(effects==4)
assert(not data[Tissue.KEY].lastExposure.natural and data[Tissue.KEY].lastExposure.artificial)
assert(provenance[3].uvNaturalIncrement==0 and provenance[3].uvArtificialIncrement==10)
assert(provenance[3].uvNaturalScore==10 and provenance[3].uvArtificialScore==10,
    "shared wounds retain cumulative source history without granting solar eligibility")
isClient=function() return true end
assert(not Tissue.advance(entity,profiles,{natural=2,artificial=0},10,15))
assert(effects==4)
isClient=function() return false end
local Trauma=require "Mortis/Runtime/TraumaRuntime"
assert(Trauma.repair(entity,{region="leftArm",woundId="ProjectNightfall.UVBurn",channel="burn",
    magnitude=40,stage=1,transactionId="integration-repair"}))
assert(Tissue.repairWoundStage(entity,"leftArm",1,"integration-stage"))
assert(Anatomy.get(entity).regions.leftArm.integrity==90)
Anatomy.detach(entity)
assert(Tissue.advance(entity,profiles,{natural=0,artificial=0},10,15))
assert(Anatomy.get(entity).regions.leftArm.integrity==90 and effects==4,
    "darkness after reload must preserve real repaired anatomy despite stored score")
assert(Tissue.snapshot(entity).regions.leftArm.woundStage==1)
assert(Tissue.advance(entity,profiles,{natural=0,artificial=1},15,16))
assert(Anatomy.get(entity).regions.leftArm.integrity==80 and effects==5,
    "renewed artificial exposure must apply only the repaired wound delta")
print("Nightfall real MORTIS UV dose/wound integration and partial-save recovery checks passed")
