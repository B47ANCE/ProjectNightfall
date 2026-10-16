local ids=setmetatable({},{__mode="k"});local nextId=0
local hierarchy=setmetatable({},{__mode="k"})
package.loaded["Mortis/init"]={
    Authority={canWriteCanonicalState=function() return true end},
    Identity={getStableId=function(e)return ids[e]end,ensureStableId=function(e)nextId=nextId+1;ids[e]=ids[e]or("Z"..nextId);return ids[e]end},
    CommandHierarchy={get=function(e)return hierarchy[e]end},
}
local Dens=require "ProjectNightfall/PN_DenState"
Dens.resetForTests()
local alpha,smart={},{}
local alphaId=package.loaded["Mortis/init"].Identity.ensureStableId(alpha)
package.loaded["Mortis/init"].Identity.ensureStableId(smart)
assert(not Dens.claim(alpha,2,{x=1,y=2,z=-1,safe=true}))
assert(not Dens.claim(alpha,3,{x=1,y=2,z=0,safe=true}))
assert(not Dens.claim(alpha,3,{x=1,y=2,z=-1,safe=false}))
local territory=assert(Dens.claim(alpha,3,{x=1,y=2,z=-1,safe=true,kind="basement"},{radius=70}))
assert(territory.status=="claimed" and territory.radius==70 and territory.alphaDen.location.z==-1)
assert(not Dens.establishSmartDen(alpha,smart,{x=1,y=2,z=0,safe=true}))
hierarchy[smart]={superiorId=alphaId}
assert(not Dens.establishSmartDen(alpha,smart,{x=500,y=500,z=0,safe=true,kind="house"}))
local smartDen=assert(Dens.establishSmartDen(alpha,smart,{x=1,y=2,z=0,safe=true,kind="house"},{role="alpha_guard"}))
assert(smartDen.status=="active" and smartDen.role=="alpha_guard")
assert(Dens.hasActiveSmartDenAt(territory,1,2,0)==true)
assert(Dens.disband(alpha,package.loaded["Mortis/init"].Identity.getStableId(smart),"sunrise unsafe",12))
assert(smartDen.status=="disbanded" and smartDen.disbandReason=="sunrise unsafe")
local smartDen2=assert(Dens.establishSmartDen(alpha,smart,{x=2,y=2,z=0,safe=true,kind="house"}))
local emergency=assert(Dens.emergencyDisplace(alpha,{x=3,y=2,z=0,safe=true,kind="emergency-shelter"},"active artificial UV",13))
assert(territory.status=="claimed" and territory.alphaDen.status=="uv-compromised")
assert(territory.alphaState=="emergency-displaced" and emergency.location.z==0 and smartDen2.status=="active")
assert(Dens.markEmergencySheltered(alpha,13.25))
assert(territory.alphaState=="emergency-sheltered" and emergency.status=="occupied")
assert(Dens.disbandTerritory(alpha,"migration",14))
assert(territory.status=="disbanded" and smartDen2.status=="disbanded")
print("Project Nightfall hierarchy-gated den-state checks passed")
