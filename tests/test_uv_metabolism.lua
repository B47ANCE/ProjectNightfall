ProjectNightfall={Config={POC={
    UVRegenerationExposureReference=1,UVRegenerationHardBlockFraction=.6,
    UVRegenerationExposureBands={{maximum=.2,multiplier=1},{maximum=.4,multiplier=.7},
        {maximum=.5,multiplier=.4},{maximum=.6,multiplier=.15}},
    UVUtilizationRanges={FERAL={minimum=.35,maximum=.55},SMART_FERAL={minimum=.55,maximum=.8},ALPHA_FERAL={minimum=.8,maximum=1}},
    UVHealingWorkPerGameMinuteRanges={FERAL={minimum=.3,maximum=.6},SMART_FERAL={minimum=.65,maximum=1.1},ALPHA_FERAL={minimum=1.2,maximum=2}},
    RegionalUVTissuePolicy={default={woundMagnitudes={8,20,45,80,160,360,700}}},
}}}
local data={}
local authority=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end,isDedicatedServerRuntime=function() return false end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function() return data end,transmitModData=function() return true end}
local anatomy={regions={leftLeg={attached=true,destroyed=false,wounds={
    ["ProjectNightfall.UVBurn"]={stage=2,magnitude=20,channel="burn"}}},
    rightArm={attached=true,destroyed=false,wounds={}}}}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return anatomy end}
package.loaded["Mortis/Runtime/AnatomyRuntime"].getRegion=function(_,id)
    return anatomy.regions[id],{critical=id=="rightArm"},id
end
local repaired,stageCommit,consumed
package.loaded["Mortis/Runtime/TraumaRuntime"]={repair=function(_,ctx) repaired=ctx;return true,{repaired=ctx.magnitude} end}
local tissueRegions={leftLeg={naturalScore=10,artificialScore=10,woundStage=2},
    rightArm={naturalScore=20,artificialScore=20,woundStage=0}}
local transferred
package.loaded["ProjectNightfall/PN_UVTissueState"]={
    snapshot=function() return {regions=tissueRegions} end,
    consume=function(_,requests,_,id) consumed={requests=requests,id=id};return true,{consumed=requests.leftLeg} end,
    repairWoundStage=function(_,region,stage,id) stageCommit={region=region,stage=stage,id=id};return true,{} end,
    transfer=function(_,from,to,amount,efficiency)
        transferred={from=from,to=to,amount=amount,efficiency=efficiency}
        tissueRegions[to].naturalScore=tissueRegions[to].naturalScore+amount*efficiency
        return true,{removed=amount,delivered=amount*efficiency}
    end,
}
local realRequire=require
require=function(name) if name=="ProjectNightfall/PN_Config" then return ProjectNightfall.Config end return realRequire(name) end
local M=dofile(arg[1])
local entity={}
assert(M.inspect(entity,"FERAL").initialized==false and data[M.KEY]==nil,
    "inspection must not generate traits")
local traits=assert(M.traits(entity,"FERAL"))
assert(math.abs(traits.utilization-.45)<1e-9 and math.abs(traits.healingWorkPerGameMinute-.45)<1e-9)
local smart=assert(M.traits(entity,"SMART_FERAL"))
assert(math.abs(smart.utilization-.675)<1e-9 and math.abs(smart.healingWorkPerGameMinute-.875)<1e-9,
    "persistent individual rolls must map into the current class range")
assert(select(1,M.exposureModifier(.59))==.15)
assert(select(1,M.exposureModifier(.60))==0)
assert(M.exposureModifier(nil)==nil and M.exposureModifier(0/0)==nil
    and M.exposureModifier(-1)==nil and M.exposureModifier(math.huge)==nil,
    "unknown or invalid exposure cannot be treated as safe darkness")
assert(M.regenerate(entity,"REGULAR",{leftLeg={tissueIrradiance=0}},1))
local ok,result=M.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=.1}},10)
assert(ok and result.region=="leftLeg" and math.abs(result.work-4.5)<1e-9)
assert(math.abs(consumed.requests.leftLeg-10)<1e-9 and repaired.magnitude==4.5)
assert(stageCommit.stage==1 and not data[M.KEY].pending)
anatomy.regions.leftLeg.wounds["ProjectNightfall.UVBurn"]={stage=2,magnitude=20,channel="burn"}
consumed=nil
assert(M.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=.6}},10))
assert(consumed==nil,"60% local exposure must hard-block that region")
data[M.KEY]=nil;tissueRegions.leftLeg.naturalScore=0;tissueRegions.leftLeg.artificialScore=0
local smartOk,smartResult=M.regenerate(entity,"SMART_FERAL",{leftLeg={tissueIrradiance=0}},10)
assert(smartOk and transferred.from=="rightArm" and transferred.to=="leftLeg"
    and smartResult.transfer.delivered>0,"Smart Feral healing may transfer from another region")
anatomy.regions.leftLeg.wounds["ProjectNightfall.UVBurn"].magnitude=.1
tissueRegions.leftLeg.naturalScore=1;tissueRegions.leftLeg.artificialScore=0
transferred=nil
local tinyOK,tinyResult=M.regenerate(entity,"SMART_FERAL",{leftLeg={tissueIrradiance=0}},10)
assert(tinyOK and math.abs(tinyResult.work-.1)<1e-9 and transferred==nil,
    "sufficient local energy for a tiny wound must not trigger donor transfer")
tissueRegions.leftLeg.naturalScore=0
assert(M.regenerate(entity,"SMART_FERAL",{leftLeg={tissueIrradiance=0}},10))
assert(transferred and math.abs(transferred.amount-(.1/.675/.85))<1e-9,
    "donor withdrawal must match actual healing demand including efficiency")
anatomy.regions.leftLeg.wounds["ProjectNightfall.UVBurn"].magnitude=20
authority=false
assert(not M.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=0}},1))
assert(not M.redistribute(entity,"ALPHA_FERAL",{},1,{allowRedistribution=true}))
authority=true
consumed=nil
assert(M.regenerate(entity,"ALPHA_FERAL",{leftLeg={tissueIrradiance=0}},1,{preserveForMovement=true}))
assert(consumed==nil and data[M.KEY].lastDecision.action=="preserve")
tissueRegions.leftLeg.naturalScore=0;tissueRegions.leftLeg.artificialScore=0
tissueRegions.rightArm.naturalScore=80;tissueRegions.rightArm.artificialScore=0
local exposure={leftLeg={transmission=.1,tissueIrradiance=.1},rightArm={transmission=1,tissueIrradiance=1}}
transferred=nil
assert(M.redistribute(entity,"SMART_FERAL",exposure,1,{allowRedistribution=true}))
assert(transferred==nil,"Smart Ferals cannot proactively optimize storage")
assert(M.redistribute(entity,"ALPHA_FERAL",exposure,1,{allowRedistribution=false}))
assert(transferred==nil,"tactical priority blocks proactive redistribution")
local allocated,allocation=M.redistribute(entity,"ALPHA_FERAL",exposure,1,{allowRedistribution=true})
assert(allocated and transferred.from=="rightArm" and transferred.to=="leftLeg"
    and transferred.amount<=4 and allocation.delivered>0)
assert(data[M.KEY].lastDecision.reason=="protected storage")
transferred=nil
ProjectNightfall.Config.POC.UVAlphaTransferEfficiency=0
local disabled,disabledResult=M.redistribute(entity,"ALPHA_FERAL",exposure,1,{allowRedistribution=true})
assert(disabled and disabledResult.unchanged and transferred==nil)
ProjectNightfall.Config.POC.UVAlphaTransferEfficiency=.95
ProjectNightfall.Config.POC.UVAlphaTransferPerGameMinute=0
assert(M.redistribute(entity,"ALPHA_FERAL",exposure,1,{allowRedistribution=true}))
assert(transferred==nil,"zero transfer rate disables redistribution")
authority=false
local inspection=assert(M.inspect(entity,"ALPHA_FERAL"))
assert(inspection.initialized and inspection.tier=="ALPHA_FERAL")
inspection.lastDecision.reason="modified report"
assert(data[M.KEY].lastDecision.reason=="protected storage","reports must not alias saved decisions")
authority=true
local pending={id="regen:detachment",region="leftLeg",uvCost=2,work=1,resultingStage=1}
data[M.KEY].pending=pending
anatomy.regions.leftLeg.attached=false
consumed=nil;repaired=nil;stageCommit=nil
local recovered,recovery=M.recover(entity)
assert(recovered and recovery.cancelled and data[M.KEY].pending==nil)
assert(consumed==nil and repaired==nil and stageCommit==nil,"detached target must not spend, heal or refund")
assert(data[M.KEY].lastDecision.action=="cancel-healing")
anatomy.regions.leftLeg.attached=true;anatomy.regions.leftLeg.destroyed=true
data[M.KEY].pending=pending
assert(M.recover(entity) and data[M.KEY].pending==nil)
anatomy.regions.leftLeg.destroyed=false
data[M.KEY].pending={id="regen:unknown",region="unknown",uvCost=2,work=1,resultingStage=1}
assert(not M.recover(entity) and data[M.KEY].pending~=nil,"missing anatomy must not be mistaken for confirmed removal")
data[M.KEY].pending=nil
anatomy.regions.rightArm.wounds["ProjectNightfall.UVBurn"]={stage=1,magnitude=8,channel="burn"}
anatomy.regions.leftLeg.wounds["ProjectNightfall.UVBurn"]={stage=2,magnitude=20,channel="burn"}
tissueRegions.leftLeg.naturalScore=10;tissueRegions.rightArm.naturalScore=10
local priorityOK,priorityResult=M.regenerate(entity,"ALPHA_FERAL",{
    leftLeg={tissueIrradiance=0},rightArm={tissueIrradiance=0}},1)
assert(priorityOK and priorityResult.region=="rightArm","critical region must outrank alphabetical minor limb order")
assert(data[M.KEY].lastDecision.action=="heal")
local fallbackOK,fallbackResult=M.regenerate(entity,"ALPHA_FERAL",{
    leftLeg={tissueIrradiance=0},rightArm={tissueIrradiance=.6}},1)
assert(fallbackOK and fallbackResult.region=="leftLeg","blocked critical tissue must not starve eligible local healing")
consumed=nil
for index=1,M.MAX_REGIONS do anatomy.regions["extra"..index]={attached=true,wounds={}} end
assert(not M.regenerate(entity,"FERAL",{leftLeg={tissueIrradiance=0}},1))
assert(consumed==nil,"over-budget anatomy must be rejected before repairing the first region")
print("Nightfall variable UV traits, local regeneration and exposure lockout checks passed")
