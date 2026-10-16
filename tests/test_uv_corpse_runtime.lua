local now=10
getGameTime=function() return {getWorldAgeHours=function() return now/60 end} end
local authority=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
local sourceData,corpseData={},{}
local source={getModData=function() return sourceData end}
local corpse={getModData=function() return corpseData end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function(entity) return entity:getModData() end}
local tissueAvailable=true
local flushAvailable=true
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return {speciesId="Mortis.Humanoid"} end,
    tissueSnapshot=function() return tissueAvailable and {capacity=100,remaining=100,regions={}} or nil,"regional tissue unavailable" end,
    flush=function() return flushAvailable,flushAvailable and nil or "persistence unavailable" end}
package.loaded["ProjectNightfall/PN_UVTissueState"]={snapshot=function() return {schemaVersion=2,regions={}} end}
local square={}
package.loaded["Mortis/Runtime/Adapters/CorpseAdapter"]={onSquare=function(got)
    return got==square and {corpse} or {}
end}
local schedulerCalls={}
package.loaded["ProjectNightfall/PN_UVTissueScheduler"]={process=function(target,emitters,elapsed,finish,configuration,context)
    schedulerCalls[#schedulerCalls+1]={target=target,elapsed=elapsed,finish=finish,configuration=configuration,context=context}
    return true,{completed=true}
end}
ProjectNightfall={Config={POC={ArtificialUVZombieBudgetPerUpdate=8,
    ArtificialUVCorpseSquareBudgetPerUpdate=8,ArtificialUVCorpseProcessBudgetPerUpdate=1,
    ArtificialUVCorpseCandidateLimit=16,ArtificialUVCorpseMaximumScanSquares=64,
    RegionalUVTissueMaximumElapsedMinutes=5,RegionalUVTissuePolicyRevision=2,
    RegionalUVTissuePolicy={default={artificialTissueLossPerDose=.0005},regions={}},
    UVCorpseDestructionStageThresholds={.1,.35,.65,.9}}}}
package.loaded["ProjectNightfall/PN_Config"]=true
local emitter={owner={getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end},range=0}
ProjectNightfall.ArtificialUV={getCurrentEmitters=function(entity)
    if entity==nil or entity==corpse then return {emitter} end
    return {}
end}
local cell={getGridSquare=function(_,x,y,z) return x==0 and y==0 and z==0 and square or nil end}
local Runtime=require "ProjectNightfall/PN_UVCorpseRuntime"
assert(Runtime.markDeath(source))
for k,v in pairs(sourceData) do corpseData[k]=v end -- native corpse modData copy
assert(corpseData[Runtime.KEY].infected and corpseData[Runtime.KEY].speciesId=="Mortis.Humanoid")
assert(Runtime.update({cell=cell}))
assert(#schedulerCalls==0,"first discovery establishes time; it cannot backfill unknown corpse exposure")
local first=Runtime.getDiagnostics()
assert(first.lastEmitters==1 and first.lastSquaresScanned==1 and first.lastCandidatesAdded==1)
first.lastEmitters=999
assert(Runtime.getDiagnostics().lastEmitters==1,"diagnostic snapshots must not expose mutable runtime state")
now=12
assert(Runtime.update({cell=cell}))
assert(#schedulerCalls==1 and schedulerCalls[1].target==corpse and schedulerCalls[1].elapsed==2)
assert(schedulerCalls[1].configuration.policy.artificialDeath==false
    and schedulerCalls[1].configuration.policy.traumaMovement==nil,
    "postmortem processing cannot trigger living death or movement consequences")
assert(corpseData[Runtime.KEY].lastProcessMinute==12)
local active=Runtime.getDiagnostics()
assert(active.totalCorpsesProcessed==2 and active.lastProcessed==1 and active.totalSquaresScanned==2)
ProjectNightfall.ArtificialUV.getCurrentEmitters=function(entity) return {} end
now=13
local ok,idle=Runtime.update({cell=cell})
assert(ok and idle.emitters==0 and #schedulerCalls==1,"no emitters means no corpse-square scan or processing")
local idleStats=Runtime.getDiagnostics()
assert(idleStats.idleUpdates==1 and idleStats.lastCandidates==0 and idleStats.lastSquaresScanned==0)
ProjectNightfall.ArtificialUV.getCurrentEmitters=function(entity)
    if entity==nil or entity==corpse then return {emitter} end return {}
end
now=100
assert(Runtime.update({cell=cell}) and #schedulerCalls==1,"re-entry establishes now; darkness is not backfilled")
now=101
assert(Runtime.update({cell=cell}) and #schedulerCalls==2 and schedulerCalls[2].elapsed==1)
authority=false
assert(not Runtime.update({cell=cell}) and not Runtime.markDeath(source))
assert(Runtime.getDiagnostics().failures==1)
authority=true;tissueAvailable=false
assert(not Runtime.markDeath({getModData=function() return {} end}),"unquantified legacy anatomy is not repeatedly scheduled")
tissueAvailable=true;flushAvailable=false
local unpersisted={};assert(not Runtime.markDeath({getModData=function() return unpersisted end}))
assert(unpersisted[Runtime.KEY]==nil,"marker cannot commit without corpse-copyable anatomy")
print("Nightfall emitter-bounded marked-infected corpse runtime checks passed")
