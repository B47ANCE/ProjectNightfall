local registered={}
lightWorks={registerBulb=function(def) registered[def.item]=def return def end}
lightWorks.UV_VISIBLE_COLOR={r=0.00,g=0.00,b=1.00}
ProjectNightfall={Config={POC={}}}

local realRequire=require
require=function(name)
    if name=="ProjectNightfall/PN_Config" then return ProjectNightfall.Config end
    return realRequire(name)
end

dofile(arg[1])

local standard=assert(registered["ProjectNightfall.LightBulbUV"])
local high=assert(registered["ProjectNightfall.LightBulbUVHighOutput"])
assert(standard.tags.UV and standard.emissions.UV.intensity==1.0 and standard.emissions.UV.range==9.0)
assert(high.tags.UV and high.emissions.UV.intensity==2.0 and high.emissions.UV.range==14.0)
assert(high.visible.strength < standard.visible.strength,"high-output UV should remain visibly dimmer")
assert(high.emissions.UV.intensity > standard.emissions.UV.intensity,"high-output UV must be mechanically stronger")
assert(standard.visible.color.r==high.visible.color.r
    and standard.visible.color.g==high.visible.color.g
    and standard.visible.color.b==high.visible.color.b,
    "all UV bulbs must use the same canonical visible blue")
assert(standard.visible.color.r==0 and standard.visible.color.g==0 and standard.visible.color.b==1,
    "standard UV visible spill must be pure blue")
assert(high.visible.color.r==0 and high.visible.color.g==0 and high.visible.color.b==1,
    "high-output UV visible spill must be pure blue")

print("Project Nightfall lightWorks UV contract checks passed")
