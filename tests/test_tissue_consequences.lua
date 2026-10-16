local authority=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
local state={lastMinute=10,lastExposure={endMinute=10,natural=true,artificial=false}}
package.loaded["ProjectNightfall/PN_UVTissueState"]={snapshot=function() return state end}
local calls=0
package.loaded["Mortis/Runtime/SystemicTrauma"]={resolveCriticalFailure=function(_,policy)
    assert(policy.allowDeath);calls=calls+1;return true,{healthZero=true}
end}
local Consequences=require "ProjectNightfall/PN_TissueConsequences"
local policy={artificialDeath=true}
assert(Consequences.resolve({},policy) and calls==0,"sun-only dose must never request lethal trauma")
state.lastExposure.artificial=true
assert(Consequences.resolve({},policy) and calls==1)
assert(Consequences.resolve({},{artificialDeath=false}) and calls==1)
state.pending={}
assert(not Consequences.resolve({},policy) and calls==1)
state.pending=nil;state.lastExposure.endMinute=9
assert(Consequences.resolve({},policy) and calls==1,"stale source stamp cannot authorize new consequence")
authority=false;state.lastExposure.endMinute=10
assert(not Consequences.resolve({},policy) and calls==1)
print("Nightfall committed artificial-only systemic consequence gate checks passed")
