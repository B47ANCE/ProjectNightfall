-- Real anatomy, clothing, dose, journal and pipeline over a native-like copied corpse.
local species={id="UV.Corpse",version=1,defaultRegion="leftArm",regions={
    leftArm={integrity=100,tissueCapacity=10},rightArm={integrity=100,tissueCapacity=10}}}
package.loaded["Mortis/API/Species"]={get=function() return species end,has=function() return true end,
    resolveRegion=function(_,id) return species.regions[id] and id or ({ForeArm_L="leftArm",ForeArm_R="rightArm"})[id] end}
package.loaded["Mortis/API/EntityResolvers"]={resolve=function() return species.id end}
package.loaded["Mortis/API/TraumaChannels"]={get=function() return {structuralMultiplier=0,bleedMultiplier=0} end}
package.loaded["Mortis/Runtime/AnatomyConsequenceRuntime"]={dispatch=function() end}
local function copy(v,seen)
    if type(v)~="table" then return v end seen=seen or {};if seen[v] then return seen[v] end
    local r={};seen[v]=r;for k,x in pairs(v) do r[copy(k,seen)]=copy(x,seen) end return r
end
local function list(values) return {size=function() return #values end,get=function(_,i) return values[i+1] end} end
BloodBodyPartType={MAX={index=function() return 2 end},FromIndex=function(i) return i==0 and "ForeArm_L" or "ForeArm_R" end}
BloodClothingType={getCoveredParts=function(parts) return list(parts) end}
local garment={getItemType=function() return "Test.CorpseCoat" end,
    getScriptItem=function() return {getFabricType=function() return "Denim" end,
        getBloodClothingType=function() return {"ForeArm_R"} end} end,
    getHole=function() return 0 end}
local liveData={}
local live={getModData=function() return liveData end,getObjectName=function() return "Zombie" end,
    getItemVisuals=function() return list({garment}) end}
local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
local Tissue=require "ProjectNightfall/PN_UVTissueState"
assert(Anatomy.get(live))
local baseProfiles={}
for id in pairs(species.regions) do baseProfiles[id]={transmission=1,exposureFactor=1,capacity=100,
    naturalCapFraction=.64,thresholds={.9},woundMagnitudes={1},artificialTissueLossPerDose=0} end
assert(Tissue.advance(live,baseProfiles,{natural=0,artificial=0},0,1))
assert(Anatomy.flush(live,false),"death boundary must persist cache-only anatomy before corpse copy")
local corpseData=copy(liveData)
local corpse={getModData=function() return corpseData end,getObjectName=function() return "DeadBody" end,
    getItemVisuals=function() return list({garment}) end}
local Pipeline=require "ProjectNightfall/PN_UVTissuePipeline"
local restored,restoreError=Anatomy.get(corpse);assert(restored,tostring(restoreError))
local persisted,persistError=Tissue.snapshot(corpse);assert(persisted,tostring(persistError))
local Coverage=require "Mortis/Runtime/ClothingCoverage"
local corpseClothing,clothingError=Coverage.snapshot(corpse,species.id);assert(corpseClothing,tostring(clothingError))
local policy={regions={},resolveTransmission=function(_,_,fabric) return fabric=="Denim" and .1 or 1 end,
    artificialDeath=false}
for id in pairs(species.regions) do policy.regions[id]={exposureFactor=1,capacity=100,
    naturalCapFraction=.64,thresholds={.9},woundMagnitudes={1},artificialTissueLossPerDose=.01} end
local artificial={uv={complete=true,occlusionChecked=true,natural=0,artificial=1}}
local ok,result=Pipeline.process(corpse,artificial,policy,1,11)
if not ok then error("corpse pipeline failed: "..tostring(result)) end
assert(ok,result)
assert(result.protection.regions.leftArm==1 and result.protection.regions.rightArm==.1)
assert(Anatomy.get(corpse).regions.leftArm.remainingTissue==9)
assert(math.abs(Anatomy.get(corpse).regions.rightArm.remainingTissue-9.9)<1e-9)
assert(not corpseData.PN_UVRemains,"postmortem loss preserves original cause")
local natural={uv={complete=true,occlusionChecked=true,natural=10,artificial=0}}
assert(Pipeline.process(corpse,natural,policy,11,21))
assert(Anatomy.get(corpse).regions.leftArm.remainingTissue==9,"sun cannot consume corpse tissue")
Anatomy.detach(corpse)
local reloaded={getModData=function() return copy(corpseData) end,getObjectName=function() return "DeadBody" end,
    getItemVisuals=function() return list({garment}) end}
assert(Anatomy.get(reloaded).regions.leftArm.remainingTissue==9)
assert(math.abs(Anatomy.get(reloaded).regions.rightArm.remainingTissue-9.9)<1e-9)
print("Nightfall copied-corpse clothing-to-persistent-artificial-tissue pipeline passed")
