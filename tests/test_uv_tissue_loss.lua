local species={id="UV.Loss",version=1,defaultRegion="leftArm",regions={
    leftArm={integrity=100,tissueCapacity=10},rightArm={integrity=100,tissueCapacity=10}}}
package.loaded["Mortis/API/Species"]={get=function() return species end,has=function() return true end,
    resolveRegion=function(_,id) return species.regions[id] and id end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function() return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function() return {structuralMultiplier=0,bleedMultiplier=0} end}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function() end}
local data={}
local entity={getModData=function() return data end}
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local profiles={}
for id in pairs(species.regions) do profiles[id]={transmission=id=="leftArm" and 1 or .5,
    exposureFactor=1,capacity=100,naturalCapFraction=.64,thresholds={.1,.2},woundMagnitudes={1,2},
    artificialTissueLossPerDose=.01} end
local consume=Anatomy.consumeTissue
local failed=true
Anatomy.consumeTissue=function(target,id,...)
    if id=="rightArm" and failed then return nil,"injected partial save failure" end
    return consume(target,id,...)
end
assert(not Tissue.advance(entity,profiles,{natural=0,artificial=1},0,10))
assert(Anatomy.get(entity).regions.leftArm.remainingTissue==9)
assert(Anatomy.get(entity).regions.rightArm.remainingTissue==10)
assert(data[Tissue.KEY].pending and not data[Tissue.KEY].lastMinute)
failed=false
package.loaded["ProjectNightfall/PN_UVTissueState"]=nil
Tissue=require "ProjectNightfall/PN_UVTissueState"
assert(Tissue.recover(entity))
assert(Anatomy.get(entity).regions.leftArm.remainingTissue==9,"retry must not repeat committed loss")
assert(Anatomy.get(entity).regions.rightArm.remainingTissue==9.5)
local observation=Tissue.snapshot(entity).lastDestruction
assert(observation.fromMinute==0 and observation.toMinute==10 and observation.amounts.leftArm==1
    and observation.amounts.rightArm==.5,"recovery retains original interval and applied amounts")
assert(Tissue.advance(entity,profiles,{natural=0,artificial=1},0,10))
assert(Anatomy.get(entity).regions.leftArm.remainingTissue==9,"duplicate interval must not burn again")
assert(Tissue.advance(entity,profiles,{natural=10,artificial=0},10,20))
assert(Tissue.advance(entity,profiles,{natural=0,artificial=0},20,30))
assert(next(Tissue.snapshot(entity).lastDestruction.amounts)==nil,"dark interval clears active loss record")
assert(Anatomy.get(entity).regions.leftArm.remainingTissue==9,"sunlight and darkness cannot consume tissue")
assert(Tissue.advance(entity,profiles,{natural=0,artificial=100},30,40))
assert(Anatomy.get(entity).regions.leftArm.remainingTissue==0)
assert(Anatomy.get(entity).regions.rightArm.remainingTissue==0)
assert(Tissue.advance(entity,profiles,{natural=0,artificial=100},40,50),"depleted tissue must not block exposure")
profiles.leftArm.artificialTissueLossPerDose=-1
assert(not Tissue.advance(entity,profiles,{natural=0,artificial=1},50,60))
assert(Tissue.snapshot(entity).lastMinute==50)
profiles.leftArm.artificialTissueLossPerDose=.01
Anatomy.get(entity).regions.leftArm.tissueCapacity=nil
assert(not Tissue.advance(entity,profiles,{natural=0,artificial=1},50,60),"unknown legacy tissue cannot be invented")
assert(Tissue.snapshot(entity).lastMinute==50)
profiles.leftArm.artificialTissueLossPerDose=0
assert(Tissue.advance(entity,profiles,{natural=0,artificial=1},50,60),"disabled loss preserves legacy dose behavior")
print("Nightfall journaled artificial tissue loss checks passed")
