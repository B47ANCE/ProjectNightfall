local state={regions={head={naturalScore=49,artificialScore=51},torso={naturalScore=50,artificialScore=0}}}
package.loaded["ProjectNightfall/PN_UVTissueState"]={snapshot=function() return state end}
local Hibernation=require "ProjectNightfall/PN_SunHibernation"
local policy={enabled=true,minimumNaturalDose=50,minimumAffectedRegions=1}
local ok,result=Hibernation.evaluate({},policy)
assert(ok and result.eligible and result.affectedRegions==1 and result.maximumNaturalDose==50)
policy.minimumAffectedRegions=2
assert(Hibernation.evaluate({},policy) and not select(2,Hibernation.evaluate({},policy)).eligible,
    "artificial dose must never satisfy sunlight hibernation")
state.regions.head.naturalScore=50
assert(select(2,Hibernation.evaluate({},policy)).eligible)
state.pending={}
assert(not Hibernation.evaluate({},policy))
state.pending=nil
assert(Hibernation.evaluate({},{enabled=false}))
assert(not Hibernation.evaluate({},{enabled=true,minimumNaturalDose=0,minimumAffectedRegions=1}))
print("Nightfall committed natural-only regional hibernation eligibility checks passed")
