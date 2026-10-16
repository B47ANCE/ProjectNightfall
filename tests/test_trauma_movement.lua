local authority=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
local value=1
package.loaded["Mortis/API/AnatomyCapabilities"]={functionalSnapshot=function()
    return {baseline={locomotion=1},total={locomotion=value}}
end}
local ceiling,calls=nil,0
package.loaded["Mortis/Runtime/LocomotionOverrides"]={
    setCeiling=function(_,owner,tier) assert(owner=="ProjectNightfall.TissueInjury");ceiling=tier;calls=calls+1;return true end,
    releaseCeiling=function() ceiling=nil;calls=calls+1;return true end}
local Movement=require "ProjectNightfall/PN_TraumaMovement"
local policy={enabled=true,slowBelow=.5,noSprintBelow=.9}
assert(Movement.update({},policy) and ceiling==nil)
value=.8
assert(Movement.update({},policy) and ceiling=="fastShambler")
value=.4
assert(Movement.update({},policy) and ceiling=="shambler")
value=0
assert(Movement.update({},policy) and ceiling=="shambler","zero function must not guess a native immobilization API")
assert(Movement.update({},{enabled=false}) and ceiling==nil)
value=0/0
local before=calls
assert(not Movement.update({},policy) and calls==before)
assert(not Movement.update({},{enabled=true,slowBelow=.9,noSprintBelow=.2}))
authority=false
assert(not Movement.update({},policy) and calls==before)
print("Nightfall injury-driven movement ceiling policy checks passed")
