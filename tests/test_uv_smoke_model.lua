local Smoke=require "ProjectNightfall/PN_UVSmokeModel"
local function evaluate(severity,rate,remaining,lifecycle)
    return assert(Smoke.evaluate({arm={attached=true,severity=severity,activeDestructionRate=rate,
        remainingFraction=remaining,weight=1}},lifecycle or "living"))
end
assert(evaluate(.19,1,.81).generationRate==0)
assert(evaluate(.8,0,.2).generationRate==0,"old burns in darkness do not generate smoke")
assert(evaluate(.8,2,.2).generationRate>evaluate(.8,1,.2).generationRate)
assert(evaluate(.8,1,.2).generationRate>evaluate(.98,1,.02).generationRate,"depletion tapers output")
assert(evaluate(1,1,0).generationRate==0)
assert(evaluate(.15,1,.85,"corpse").generationRate>0)
local regions={torso={attached=true,severity=.8,activeDestructionRate=1,remainingFraction=.2,weight=8},
    hand={attached=true,severity=.2,activeDestructionRate=0,remainingFraction=1,weight=1},
    missing={attached=false}}
local result=assert(Smoke.evaluate(regions,"corpse"))
assert(math.abs(result.remainingFraction-2.6/9)<1e-12)
assert(result.regions.hand.generationRate==0 and result.regions.missing.generationRate==0)
result.regions.torso.remainingFraction=0
assert(regions.torso.remainingFraction==.2,"derived view cannot mutate anatomy input")
assert(Smoke.evaluate(regions,"corpse",{multiplier=0}).generationRate==0)
regions.torso.weight=nil;assert(not Smoke.evaluate(regions,"corpse"),"do not invent canonical weights")
regions.torso.weight=8;regions.torso.activeDestructionRate=0/0
assert(not Smoke.evaluate(regions,"corpse"))
assert(not Smoke.evaluate({},"unknown"))
assert(not Smoke.evaluate({},"living",{curve={{0,0},{0,.2},{1,1}}}))
local many={};for i=1,33 do many[tostring(i)]={attached=false} end
assert(not Smoke.evaluate(many,"living"))
print("Nightfall shared UV smoke rate, tissue taper, weights and bounds checks passed")
