local Dose=require "ProjectNightfall/PN_RegionalUVDose"
local function profile(transmission)
    return {transmission=transmission,exposureFactor=1,capacity=100,naturalCapFraction=.64,
        thresholds={.10,.20,.35,.50,.65,.80,.95}}
end
local regions={leftArm=profile(1),rightArm=profile(.03),torso=profile(.01)}
local state,promotions,debug=Dose.propose({},regions,{natural=2,artificial=3},10)
assert(state.leftArm.naturalScore==20 and state.leftArm.artificialScore==30)
assert(state.leftArm.woundStage==4 and #promotions==1 and debug.leftArm.scoreFraction==.5)
local sun=Dose.propose({}, {head=profile(1)}, {natural=100,artificial=0},10)
assert(sun.head.naturalScore==64 and sun.head.woundStage==4,
    "sunlight must stop below the 65% Deep Burn threshold")
local combined=Dose.propose({head={naturalScore=0,artificialScore=78,woundStage=5}},
    {head=profile(1)},{natural=100,artificial=0},1)
assert(combined.head.artificialScore==78 and combined.head.naturalScore==22 and combined.head.woundStage==5,
    "sunlight preserves existing deep injury and storage but cannot promote it further")
local resumed=Dose.propose(combined,{head=profile(1)},{natural=0,artificial=1},1)
assert(resumed.head.woundStage==7,"current artificial exposure may progress even when storage is full")
local dark,events=Dose.propose(state,regions,{natural=0,artificial=0},1000)
assert(dark.leftArm.naturalScore==20 and dark.leftArm.woundStage==4 and #events==0)
local uncapped=profile(1);uncapped.naturalCapFraction=1
local full=Dose.propose({}, {head=uncapped}, {natural=10,artificial=10},10)
assert(math.abs(full.head.naturalScore-50)<1e-9 and math.abs(full.head.artificialScore-50)<1e-9,
    "simultaneous sources must share capacity without order bias")
local protected=Dose.propose({}, {head=profile(0)}, {natural=1000,artificial=1000},1000)
assert(protected.head.naturalScore==0 and protected.head.woundStage==0)
local wounded={head={naturalScore=0,artificialScore=0,woundStage=7}}
local healed={head={naturalScore=30,artificialScore=40,woundStage=1}}
assert(Dose.propose(healed,{head=profile(1)},{natural=100,artificial=0},1).head.woundStage==4,
    "historical artificial fuel must not let sunlight exceed its severe-burn ceiling")
local retained,repromoted=Dose.propose(healed,{head=profile(1)},{natural=0,artificial=0},10)
assert(retained.head.woundStage==1 and #repromoted==0,
    "stored UV must not recreate explicitly repaired wounds without new exposure")
assert(Dose.propose(healed,{head=profile(1)},{natural=0,artificial=10},0).head.woundStage==1,
    "zero-duration sampling must not inflict trauma")
assert(Dose.propose(healed,{head=profile(1)},{natural=0,artificial=1},1).head.woundStage==5,
    "renewed artificial exposure may promote injury again")
assert(Dose.propose(wounded,{head=profile(1)},{natural=0,artificial=0},1).head.woundStage==7,
    "storage changes must not implicitly heal wounds")
assert(not Dose.propose({},regions,{natural=0/0,artificial=1},1))
assert(not Dose.propose({},regions,{natural=1,artificial=1},math.huge))
assert(not Dose.propose({head={naturalScore=101,artificialScore=0,woundStage=0}},
    {head=profile(1)},{natural=0,artificial=0},1))
local invalid=profile(1);invalid.thresholds={.2,.1};assert(not Dose.propose({},{head=invalid},{natural=1,artificial=1},1))
invalid=profile(1);invalid.naturalCapFraction=1.1;assert(not Dose.propose({},{head=invalid},{natural=1,artificial=1},1))
print("Nightfall per-region capped UV score and source-ceiling proposal checks passed")
