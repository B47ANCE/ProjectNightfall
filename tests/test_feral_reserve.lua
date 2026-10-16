ProjectNightfall={Config={POC={
    FeralizationThreshold=100.0,
    FeralSprintMinimumReserve=10.0,
    FeralSprintUVPerGameMinute=18.0,
    FeralReserveChargeScale=1.0,
}}}

local realRequire=require
require=function(name)
    if name=="ProjectNightfall/PN_Config" then return ProjectNightfall.Config end
    return realRequire(name)
end

local Reserve=dofile(arg[1])
assert(math.abs(Reserve.maximumSprintSeconds()-300.0)<0.000001,"full reserve must provide exactly five in-game minutes")
assert(math.abs(Reserve.drainSprint(100.0,5.0)-10.0)<0.000001,"five minutes must drain to sprint cutoff")
assert(not Reserve.canSprint(10.0),"the cutoff must stop sprinting at exactly five minutes")
assert(Reserve.canSprint(10.001),"reserve above the cutoff remains sprint-capable")
assert(Reserve.charge(95.0,10.0,1.0)==100.0,"sun charge must clamp at maximum")
local regions={
    leftLeg={naturalScore=50,artificialScore=50},rightLeg={naturalScore=50,artificialScore=50},
    leftFoot={naturalScore=50,artificialScore=50},rightFoot={naturalScore=50,artificialScore=50},
}
local spent
local anatomy={regions={leftLeg={},rightLeg={},leftFoot={},rightFoot={}}}
local locomotion=1
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return anatomy end}
package.loaded["Mortis/API/AnatomyCapabilities"]={functionalSnapshot=function()
    return {baseline={locomotion=1},total={locomotion=locomotion}}
end}
package.loaded["ProjectNightfall/PN_UVTissueState"]={
    snapshot=function() return {schemaVersion=2,regions=regions} end,
    consume=function(_,requests)
        spent=0
        for _,amount in pairs(requests) do spent=spent+amount end
        return true,{consumed=spent}
    end,
}
local can,pool=Reserve.canSprintEntity({})
assert(can and pool.stored==400 and pool.capacity==400)
local ok,result=Reserve.drainSprintEntity({},5)
assert(ok and math.abs(spent-360)<0.000001 and result.poolBefore.stored==400,
    "five minutes must spend the locomotion pool down to its ten-percent cutoff")
print("Project Nightfall Feral reserve economy checks passed")
anatomy.regions.leftLeg.attached=false
assert(Reserve.pool({}).stored==300,"detached limbs cannot contribute usable UV")
anatomy.regions.rightLeg.destroyed=true
assert(Reserve.pool({}).stored==200,"destroyed limbs cannot contribute usable UV")
locomotion=.7
assert(not Reserve.canSprintEntity({}),"full remaining storage cannot override locomotion impairment")
