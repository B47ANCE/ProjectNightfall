-- Real anatomy, trauma, UV journals and metabolism; only native facade and
-- species/channel registration are substituted. Fail between score and repair.
local species={id="UV.Healing",version=1,defaultRegion="leftLeg",regions={
    leftLeg={integrity=1000},rightLeg={integrity=1000},reserve={integrity=1000}}}
package.loaded["Mortis/API/Species"]={get=function(id)return id==species.id and species or nil end,
    has=function(id)return id==species.id end,resolveRegion=function(_,id)return species.regions[id] and id end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function()return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function(id)
    return id=="burn" and {structuralMultiplier=1,bleedMultiplier=0} or nil end}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function()end}
local data={}
local entity={getModData=function()return data end,isZombie=function()return true end}
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Trauma=require "Mortis/Runtime/TraumaRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Metabolism=require "ProjectNightfall/PN_UVMetabolism"
local profiles={}
for id in pairs(species.regions) do profiles[id]={transmission=1,exposureFactor=1,
    capacity=100,naturalCapFraction=.64,thresholds={.1,.2},woundMagnitudes={8,20}} end
assert(Tissue.advance(entity,profiles,{natural=20,artificial=0},0,1))
assert(Anatomy.get(entity).regions.leftLeg.integrity==980)
assert(Metabolism.traits(entity,"FERAL"))
data[Metabolism.KEY].utilizationRoll=.5;data[Metabolism.KEY].healingRoll=.5
local realRepair=Trauma.repair
Trauma.repair=function()return false,"injected interruption after UV spend"end
local ok=Metabolism.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=0}},1)
assert(not ok and data[Metabolism.KEY].pending)
local spent=Tissue.snapshot(entity).regions.leftLeg.naturalScore
assert(math.abs(spent-19)<1e-9,"exactly one UV point should commit before the interruption")
assert(Anatomy.get(entity).regions.leftLeg.integrity==980)
Trauma.repair=realRepair
Anatomy.detach(entity)
assert(Metabolism.recover(entity))
assert(math.abs(Tissue.snapshot(entity).regions.leftLeg.naturalScore-spent)<1e-9,
    "recovery must replay score consumption rather than spend twice")
assert(math.abs(Anatomy.get(entity).regions.leftLeg.integrity-980.45)<1e-9)
assert(Anatomy.get(entity).regions.rightLeg.integrity==980,"repair remains local")
assert(Tissue.snapshot(entity).regions.leftLeg.woundStage==1)
assert(data[Metabolism.KEY].pending==nil)
Anatomy.detach(entity)
assert(Metabolism.recover(entity))
assert(math.abs(Anatomy.get(entity).regions.leftLeg.wounds["ProjectNightfall.UVBurn"].magnitude-19.55)<1e-9)
assert(math.abs(Tissue.snapshot(entity).regions.leftLeg.naturalScore-19)<1e-9)
local realStageRepair=Tissue.repairWoundStage
Tissue.repairWoundStage=function()return false,"injected interruption after trauma repair"end
assert(not Metabolism.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=0}},1))
local repairedIntegrity=Anatomy.get(entity).regions.leftLeg.integrity
assert(math.abs(repairedIntegrity-980.9)<1e-9 and data[Metabolism.KEY].pending)
assert(math.abs(Tissue.snapshot(entity).regions.leftLeg.naturalScore-18)<1e-9)
Tissue.repairWoundStage=realStageRepair
Anatomy.detach(entity)
assert(Metabolism.recover(entity))
assert(math.abs(Anatomy.get(entity).regions.leftLeg.integrity-repairedIntegrity)<1e-9,
    "trauma receipt must survive anatomy reload without duplicate restoration")
assert(math.abs(Tissue.snapshot(entity).regions.leftLeg.naturalScore-18)<1e-9)
assert(data[Metabolism.KEY].pending==nil)
local multiOK,multi=Metabolism.regenerate(entity,"FERAL",{
    leftLeg={tissueIrradiance=0},rightLeg={tissueIrradiance=0}},1)
assert(multiOK and multi.regionsProcessed==2 and #multi.repairs==2)
assert(math.abs(multi.totalWork-.9)<1e-9 and math.abs(multi.totalUVConsumed-2)<1e-9)
assert(math.abs(Tissue.snapshot(entity).regions.leftLeg.naturalScore-17)<1e-9)
assert(math.abs(Tissue.snapshot(entity).regions.rightLeg.naturalScore-19)<1e-9)
assert(multi.repairs[1]~=multi,"multi-region summary must not contain itself")
-- Isolate donor economics with real transfer and consumption implementations.
data[Tissue.KEY].regions.leftLeg.naturalScore=0
data[Tissue.KEY].regions.rightLeg.naturalScore=0
data[Tissue.KEY].regions.reserve.naturalScore=10
ProjectNightfall.Config.POC.UVSmartHealingTransferPerGameMinute=2
local transferOK,transfers=Metabolism.regenerate(entity,"SMART_FERAL",{
    leftLeg={tissueIrradiance=0},rightLeg={tissueIrradiance=0}},1)
assert(transferOK and transfers.regionsProcessed==2)
assert(math.abs(Tissue.snapshot(entity).regions.reserve.naturalScore-8)<1e-9,
    "two wounded recipients must share the single two-point transfer budget")
assert(math.abs(transfers.totalUVConsumed-1.7)<1e-9)
assert(math.abs(transfers.totalWork-1.7*.675)<1e-9)
print("Nightfall real-module UV spending, multi-region healing, shared transfer budget and reload integration passed")
