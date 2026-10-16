local authority=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
local anatomy={regions={head={}}}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return anatomy end}
local compiled={compiled=true}
local compiles=0
package.loaded["ProjectNightfall/PN_UVTissuePolicy"]={compile=function(got,policy)
    compiles=compiles+1;assert(got==anatomy and policy.marker==1);return compiled
end}
local calls=0
package.loaded["ProjectNightfall/PN_UVTissuePipeline"]={sampleAndProcess=function(entity,emitters,policy,from,to,context)
    calls=calls+1;assert(policy==compiled and from==97 and to==100 and context.cell=="cell")
    assert(#emitters==1);return true,{committed=true}
end}
local Scheduler=require "ProjectNightfall/PN_UVTissueScheduler"
local config={enabled=true,maximumElapsedMinutes=3,policyRevision=1,policy={marker=1}}
assert(Scheduler.process({},{{}},10,100,config,{cell="cell"}) and calls==1 and compiles==1,"elapsed time must be capped")
assert(Scheduler.process({},{{}},10,100,config,{cell="cell"}) and calls==2 and compiles==1,
    "same species and revision must reuse compiled policy")
assert(Scheduler.process({},{{}},0,100,config,{cell="cell"}) and calls==2)
assert(Scheduler.process({},{{}},1,101,{enabled=false},{}) and calls==2)
config.policyRevision=2
assert(Scheduler.process({},{{}},10,100,config,{cell="cell"}) and calls==3 and compiles==2,
    "revision change must invalidate compiled policy")
assert(not Scheduler.process({},{{}},0/0,101,config,{}) and calls==3)
authority=false
assert(not Scheduler.process({},{{}},1,101,config,{}) and calls==3)
print("Nightfall bounded-queue regional UV scheduler adapter checks passed")
