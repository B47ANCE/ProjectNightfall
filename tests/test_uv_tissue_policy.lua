package.loaded["ProjectNightfall/PN_UVProtection"]={
    defaults=function() return {fallback=.5} end,
    compile=function(value) return function() return value.fallback end,value end,
}
local Policy=require "ProjectNightfall/PN_UVTissuePolicy"
local anatomy={regions={head={},torso={},leftArm={}}}
local config={default={thresholds={.10,.20},woundMagnitudes={5,12},exposureFactor=1,capacity=100,naturalCapFraction=.64},
    regions={head={thresholds={.08,.16},woundMagnitudes={4,10},exposureFactor=1.25,capacity=80,naturalCapFraction=.64}},
    artificialDeath=true,traumaMovement={enabled=true}}
local compiled=assert(Policy.compile(anatomy,config))
assert(compiled.regions.head.thresholds[1]==.08 and compiled.regions.torso.thresholds[1]==.10)
assert(compiled.regions.head.exposureFactor==1.25 and compiled.regions.head.capacity==80 and compiled.artificialDeath)
assert(compiled.traumaMovement.enabled and compiled.resolveTransmission("x","y","z")==.5)
compiled.regions.torso.thresholds[1]=999
assert(compiled.regions.leftArm.thresholds[1]==.10,"regional arrays must not alias")
assert(not Policy.compile(anatomy,{default={thresholds={.1,.1},woundMagnitudes={5,6},exposureFactor=1,capacity=100,naturalCapFraction=.64}}))
assert(not Policy.compile(anatomy,{default={thresholds={.1},woundMagnitudes={5,6},exposureFactor=1,capacity=100,naturalCapFraction=.64}}))
assert(not Policy.compile(anatomy,{default=config.default,regions={unknown=config.default}}))
assert(not Policy.compile(anatomy,{default={thresholds={.1},woundMagnitudes={5},exposureFactor=0/0,capacity=100,naturalCapFraction=.64}}))
print("Nightfall canonical regional UV tissue policy compilation checks passed")
assert(compiled.regions.head.artificialTissueLossPerDose==0)
config.default.artificialTissueLossPerDose=.001
assert(Policy.compile(anatomy,config).regions.torso.artificialTissueLossPerDose==.001)
config.default.artificialTissueLossPerDose=math.huge
assert(not Policy.compile(anatomy,config))
