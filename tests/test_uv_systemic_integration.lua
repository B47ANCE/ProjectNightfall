-- Real Nightfall dose/journal + real M.O.R.T.I.S. anatomy, trauma and systemic
-- failure. Only the native entity facade and one test species/channel are mocked.
local species={id="UV.Critical",version=1,defaultRegion="head",regions={head={integrity=10,critical=true}}}
package.loaded["Mortis/API/Species"]={get=function(id) return id==species.id and species or nil end,
    has=function(id) return id==species.id end,resolveRegion=function(_,id) return species.regions[id] and id end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function() return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function(id)
    return id=="burn" and {structuralMultiplier=1,bleedMultiplier=0} or nil
end}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function() end}
package.loaded["Mortis/API/Capabilities"]={has=function(id)
    return id=="zombie.getHealth" or id=="zombie.setHealth"
end}
local data={}
local health=1
local entity={getModData=function() return data end,isZombie=function() return true end,
    getHealth=function() return health end,setHealth=function(_,value) health=value end}
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local Consequences=require "ProjectNightfall/PN_TissueConsequences"
local profile={head={transmission=1,exposureFactor=1,capacity=100,naturalCapFraction=.64,
    thresholds={.10,.20},woundMagnitudes={10,20}}}
assert(Tissue.advance(entity,profile,{natural=10,artificial=0},0,1))
assert(data.MORTIS_LIVING.anatomy.regions.head.destroyed and health==1,
    "natural UV may commit critical trauma but cannot directly kill")
local ok,result=Consequences.resolve(entity,{artificialDeath=true})
assert(ok and result.unchanged and health==1)
-- Saturate score while preserving the nonlethal natural-only interval. An
-- active lamp must still be recognized after no further score can fit.
data[Tissue.KEY].regions.head.naturalScore=64
data[Tissue.KEY].regions.head.artificialScore=36
assert(Tissue.advance(entity,profile,{natural=0,artificial=10},1,2))
assert(data[Tissue.KEY].regions.head.naturalScore==64 and data[Tissue.KEY].regions.head.artificialScore==36)
assert(data[Tissue.KEY].lastExposure.artificial==true,"saturation cannot hide current artificial exposure")
ok,result=Consequences.resolve(entity,{artificialDeath=true})
assert(ok and result.healthZero and health==0,
    "committed artificial tissue exposure may authorize generalized critical failure")
local Remains=require "ProjectNightfall/PN_UVRemains"
local remains=assert(Remains.inspect(entity))
assert(remains.status=="confirmed" and remains.cause=="artificial-uv")
assert(remains.regions.head.destroyed and remains.regions.head.artificialScore==36)
remains.regions.head.artificialScore=999
assert(Remains.inspect(entity).regions.head.artificialScore==36,"remains inspection must return a copy")
print("Nightfall natural-nonlethal/artificial-lethal critical tissue integration checks passed")
