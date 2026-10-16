local species={id="UV.Pipeline",version=1,defaultRegion="leftArm",regions={leftArm={integrity=100},rightArm={integrity=100}}}
package.loaded["Mortis/API/Species"]={get=function() return species end,has=function() return true end,
    resolveRegion=function(_,id)
        return species.regions[id] and id or ({ForeArm_L="leftArm",ForeArm_R="rightArm"})[id]
    end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function() return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function() return {structuralMultiplier=.25,bleedMultiplier=0} end}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function() end}
local function list(values) return {size=function() return #values end,get=function(_,i) return values[i+1] end} end
BloodBodyPartType={MAX={index=function() return 2 end},FromIndex=function(i) return i==0 and "ForeArm_L" or "ForeArm_R" end}
BloodClothingType={getCoveredParts=function(parts) return list(parts) end}
local data={}
local torn=true
local garment={getItemType=function() return "Test.Jacket" end,
    getScriptItem=function() return {getFabricType=function() return "Denim" end,
        getBloodClothingType=function() return {"ForeArm_L","ForeArm_R"} end} end,
    getHole=function(_,part) return part=="ForeArm_L" and torn and 1 or 0 end}
local entity={getModData=function() return data end,getItemVisuals=function() return list({garment}) end}
local Pipeline=require "ProjectNightfall/PN_UVTissuePipeline"
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local policy={regions={},resolveTransmission=function() return .1 end}
for id in pairs(species.regions) do
    policy.regions[id]={exposureFactor=1,capacity=100,naturalCapFraction=.64,
        thresholds={.10,.20},woundMagnitudes={40,80}}
end
local sample={uv={complete=true,occlusionChecked=true,natural=1,artificial=1}}
local ok,result=Pipeline.process(entity,sample,policy,0,5)
assert(ok,result)
assert(Anatomy.get(entity).regions.leftArm.integrity==90)
assert(Anatomy.get(entity).regions.rightArm.integrity==100)
assert(result.protection.regions.leftArm==1 and result.protection.regions.rightArm==.1)
assert(Tissue.snapshot(entity).regions.leftArm.naturalScore==5)
sample.uv.complete=false
assert(not Pipeline.process(entity,sample,policy,5,10))
assert(Tissue.snapshot(entity).lastMinute==5,"unknown geometry must not commit a dose interval")
sample.uv.complete=true; sample.uv.occlusionChecked=false
assert(not Pipeline.process(entity,sample,policy,5,10))
sample.uv.occlusionChecked=true; sample.uv.natural=0; sample.uv.artificial=0
assert(Pipeline.process(entity,sample,policy,5,10))
assert(Anatomy.get(entity).regions.leftArm.integrity==90,"darkness must not heal committed wounds")
policy.resolveTransmission=function() error("invalid mod policy") end
assert(not Pipeline.process(entity,sample,policy,10,15))
assert(Tissue.snapshot(entity).lastMinute==10)
policy.resolveTransmission=function() return .1 end
local Diagnostics=require "ProjectNightfall/PN_UVDiagnostics"
local before=Tissue.snapshot(entity)
local report=assert(Diagnostics.inspect(entity,sample,policy))
assert(report.regions.leftArm.woundStage==1 and report.regions.rightArm.woundStage==0)
assert(report.regions.leftArm.naturalScore==5 and report.regions.leftArm.artificialScore==5)
assert(#Diagnostics.lines(report)==3)
report.metabolism={initialized=true,tier="ALPHA_FERAL",utilization=.9,healingWorkPerGameMinute=1.5,
    pending=false,lastDecision={action="redistribute",reason="protected storage",fromRegion="leftArm",
    toRegion="rightArm",delivered=3.8},lastRepair={region="leftArm",work=1,uvConsumed=1/.9,resultingStage=1}}
local enriched=Diagnostics.lines(report)
assert(#enriched==6 and enriched[4]:find("ALPHA_FERAL",1,true)
    and enriched[5]:find("protected storage",1,true) and enriched[6]:find("UV consumed",1,true))
report.metabolism=nil
assert(Tissue.snapshot(entity).lastMinute==before.lastMinute)
assert(Anatomy.get(entity).regions.leftArm.integrity==90,"inspection must not change tissue")
assert(Diagnostics.lines({regions={head={}}})[1]=="UV inspection formatting failed")
isClient=function() return true end
assert(not Pipeline.process(entity,sample,policy,10,15))
print("Nightfall native-facade clothing to real regional dose/trauma pipeline checks passed")

-- Exercise the actual lightWorks sampler/obstruction path, not a prebuilt UV
-- sample, together with the real provisional clothing policy and wound modules.
isClient=function() return false end
lightWorks={}
package.loaded["lightWorks/lightWorks_API"]=lightWorks
local Protection=require "ProjectNightfall/PN_UVProtection"
policy.resolveTransmission=assert(Protection.compile(Protection.defaults()))
entity.getX=function() return 4.5 end
entity.getY=function() return .5 end
entity.getZ=function() return 0 end
local outside=false
entity.getSquare=function() return {isOutside=function() return outside end} end
getClimateManager=function() return {getDayLightStrength=function() return 1 end} end
local boundary="Blocked"
local cell={getGridSquare=function(_,x)
    return {testVisionAdjacent=function() return x==1 and boundary or "Clear" end}
end}
local emitter={owner={getX=function() return .5 end,getY=function() return .5 end,getZ=function() return 0 end},
    intensity=2,range=10,spectrum={uva=1},directional=false}
assert(Pipeline.sampleAndProcess(entity,{emitter},policy,10,15,{cell=cell}))
assert(Tissue.snapshot(entity).regions.leftArm.artificialScore==5,"blocked lamp must not accrue score")
assert(Anatomy.get(entity).regions.leftArm.integrity==90)
boundary="Clear"
assert(Pipeline.sampleAndProcess(entity,{emitter},policy,15,25,{cell=cell}))
local lit=Tissue.snapshot(entity)
assert(math.abs(lit.regions.leftArm.artificialScore-19.8)<1e-9)
assert(Anatomy.get(entity).regions.leftArm.integrity==80,"unblocked lamp must promote the actual wound")
assert(Anatomy.get(entity).regions.rightArm.integrity==100,"intact Denim must protect the other arm")
boundary="ClearThroughWindow"
assert(not Pipeline.sampleAndProcess(entity,{emitter},policy,25,30,{cell=cell}))
assert(Tissue.snapshot(entity).lastMinute==25,"unknown glass policy must not commit exposure")
assert(Pipeline.sampleAndProcess(entity,{emitter},policy,25,30,{cell=cell,windowTransmission=0}))
assert(Tissue.snapshot(entity).regions.leftArm.artificialScore==lit.regions.leftArm.artificialScore)
outside=true
assert(Pipeline.sampleAndProcess(entity,{},policy,30,35,{cell=cell}))
assert(Tissue.snapshot(entity).regions.leftArm.naturalScore==10,"sunlight keeps distinct score attribution")
assert(Tissue.snapshot(entity).regions.leftArm.artificialScore==lit.regions.leftArm.artificialScore)
isClient=function() return true end
assert(not Pipeline.sampleAndProcess(entity,{emitter},policy,35,40,{cell=cell}))
assert(Tissue.snapshot(entity).lastMinute==35)
print("Nightfall full lightWorks ray-to-clothing-to-persistent-wound integration checks passed")

isClient=function() return false end
policy.traumaMovement={enabled=true}
package.loaded["ProjectNightfall/PN_TraumaMovement"]={update=function() error("native movement unavailable") end}
local moved,movementReport=Pipeline.process(entity,sample,policy,35,40)
assert(moved and movementReport.movement.applied==false)
assert(Tissue.snapshot(entity).lastMinute==40,"native movement failure must not undo committed dose")
package.loaded["ProjectNightfall/PN_TraumaMovement"]={update=function() return true,"restored" end}
local retried,retryReport=Pipeline.process(entity,sample,policy,35,40)
assert(retried and retryReport.movement.applied and Tissue.snapshot(entity).lastMinute==40)
print("Nightfall movement consequence failure/retry preserves dose commit checks passed")

-- Full pipeline uses the same real clothing transmission for structural UV
-- injury and optional canonical tissue loss; no unprotected second scan.
for id in pairs(species.regions) do
    species.regions[id].tissueCapacity=10
    policy.regions[id].artificialTissueLossPerDose=.01
end
local lossData={}
local lossTarget={getModData=function() return lossData end,getItemVisuals=entity.getItemVisuals}
policy.resolveTransmission=function() return .1 end
local lossSample={uv={complete=true,occlusionChecked=true,natural=0,artificial=1}}
assert(Pipeline.process(lossTarget,lossSample,policy,0,10))
assert(Anatomy.get(lossTarget).regions.leftArm.remainingTissue==9)
assert(math.abs(Anatomy.get(lossTarget).regions.rightArm.remainingTissue-9.9)<1e-9)
assert(Pipeline.process(lossTarget,lossSample,policy,0,10))
assert(Anatomy.get(lossTarget).regions.leftArm.remainingTissue==9)
print("Nightfall protected exposure-to-persistent-tissue-loss integration passed")
assert(Pipeline.process(lossTarget,lossSample,policy,10,30))
local destructionReport=assert(Diagnostics.inspect(lossTarget,lossSample,policy,30))
assert(destructionReport.destruction.smoke.generationRate>0)
assert(destructionReport.destruction.regions.leftArm.activeDestructionRate==.01)
assert(destructionReport.destruction.smoke.fresh)
assert(Diagnostics.lines(destructionReport)[4]:find("no particles",1,true))
assert(Diagnostics.inspect(lossTarget,lossSample,policy,32).destruction.smoke.generationRate==0,"stale sample expires")
assert(Diagnostics.inspect(lossTarget,lossSample,policy,29).destruction.smoke.generationRate==0,"future sample is not active")
lossSample.uv.artificial=0
assert(Diagnostics.inspect(lossTarget,lossSample,policy,30).destruction.smoke.generationRate==0,"light off suppresses immediately")
lossSample.uv.artificial=1; lossSample.uv.occlusionChecked=false
assert(Diagnostics.inspect(lossTarget,lossSample,policy,30).destruction.smoke.generationRate==0,"unverified geometry never drives smoke")
lossSample.uv.occlusionChecked=true
local committed=Tissue.snapshot(lossTarget)
lossData[Tissue.KEY].pending={}
assert(Diagnostics.inspect(lossTarget,lossSample,policy,30).destruction.smoke.generationRate==0,"partial transaction is not active output")
lossData[Tissue.KEY]=committed
local beforeInspection=Anatomy.get(lossTarget).regions.leftArm.remainingTissue
destructionReport.destruction.tissue.regions.leftArm.remaining=999
assert(Anatomy.get(lossTarget).regions.leftArm.remainingTissue==beforeInspection,"inspection never changes anatomy")
print("Nightfall committed destruction/smoke inspection freshness and exposure gates passed")
