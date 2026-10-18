ProjectNightfall=nil
dofile(arg[1])
package.loaded["ProjectNightfall/PN_Config"]=ProjectNightfall.Config

local exposureMode="ok"
lightWorks={UV={}}
function lightWorks.UV.getDayLightStrength() return 0.5 end
function lightWorks.UV.getSunlightExposure(square)
    if exposureMode=="throw" then error("bad exposure provider") end
    if exposureMode=="malformed" then return {context={modifier=0/0}} end
    return {uv={natural=square and square.natural or 0},context={modifier=0.75}}
end
package.loaded["lightWorks/lightWorks_UV"]=lightWorks.UV

require "ProjectNightfall/PN_SolarUV"
local SolarUV=ProjectNightfall.SolarUV
assert(SolarUV.getTier(nil)=="Recovery")
assert(SolarUV.getMultiplier(0/0)==1)
assert(SolarUV.getMultiplier(math.huge)==1)
assert(SolarUV.getPointRatePerMinute(nil)==ProjectNightfall.Config.POC.RecoveryPointsPerMinute)
local sunlight,detail=SolarUV.getExposureAtSquare({natural=0.4})
assert(sunlight==0.4 and detail.modifier==0.75)
exposureMode="malformed"
sunlight,detail=SolarUV.getExposureAtSquare({})
assert(sunlight==0 and detail.modifier==1)
exposureMode="throw"
sunlight,detail=SolarUV.getExposureAtSquare({})
assert(sunlight==0 and detail.error=="sunlight exposure failed")
exposureMode="ok"

local squares={}
local function square(x,y,outside,room,natural)
    local value={x=x,y=y,z=0,outside=outside,room=room,natural=natural or 0}
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getZ() return self.z end
    function value:isOutside() return self.outside end
    function value:isInARoom() return self.room end
    squares[x..":"..y]=value
    return value
end
local interior=square(1,0,false,true,0)
square(2,0,true,false,0.6)
local cell={}
function cell:getGridSquare(x,y) return squares[x..":"..y] end
function getCell() return cell end

local zombie={x=0,y=0,z=0,dead=false}
function zombie:getX() return self.x end
function zombie:getY() return self.y end
function zombie:getZ() return self.z end
function zombie:isDead() return self.dead end
function zombie:getSquare() return squares["0:0"] end
function zombie:isTargetVisible() return false end
function zombie:getTarget() return nil end
function zombie:pathToLocationF(x,y,z) self.path={x,y,z} end
square(0,0,true,false,0.6)
local target={x=4,y=0}
function target:getX() return self.x end
function target:getY() return self.y end

require "ProjectNightfall/PN_Observation"
local Observation=ProjectNightfall.Observation
assert(Observation.findObservationPoint(zombie,target)==interior)
assert(Observation.findObservationPoint({},target)==nil)
assert(Observation.emitSignal(zombie,interior,nil)==nil)
local signal=assert(Observation.emitSignal(zombie,interior,10))
local other={x=1,y=1,z=0}
function other:getX() return self.x end
function other:getY() return self.y end
function other:getZ() return self.z end
assert(Observation.findNearbySignal(other,11)==signal)
assert(Observation.pathToSignal(zombie,signal)==true and zombie.path[1]==1.5)
assert(Observation.pathToSignal({pathToLocationF=function() error("stale") end},signal)==false)
assert(Observation.pathToSignal(zombie,{x="bad"})==false)

require "ProjectNightfall/PN_Shelter"
local Shelter=ProjectNightfall.Shelter
assert(getCell()==cell)
assert(cell:getGridSquare(1,0,0)==interior)
local interiorExposure=SolarUV.getExposureAtSquare(interior)
assert(interiorExposure==0)
local selectedShelter=Shelter.findNearby(zombie)
assert(selectedShelter==interior,"expected interior shelter; got "..tostring(selectedShelter))
zombie.z=-1
local closestShelter=Shelter.findClosestNearby(zombie)
assert(closestShelter==interior,"emergency shelter search must include the loaded floor above a basement")
zombie.z=0
assert(Shelter.findNearby({isDead=function() error("stale") end})==nil)

local hungerReads=0
ProjectNightfall.MortisIntegration={getHungerDrive=function()
    hungerReads=hungerReads+1;return 0.25,0.5
end}
package.loaded["ProjectNightfall/PN_MortisIntegration"]=ProjectNightfall.MortisIntegration
ProjectNightfall.Effigies={
    findNearbyReaction=function() return nil end,
}
package.loaded["ProjectNightfall/PN_Effigies"]=ProjectNightfall.Effigies
require "ProjectNightfall/PN_UVAI"
local UVAI=ProjectNightfall.UVAI
local result,err=UVAI.buildWeightMap(nil,{},0,0,0)
assert(result==nil and err=="zombie required")
local impairment=UVAI.computeImpairment(nil,nil)
assert(impairment.combined==0)
assert(UVAI.getProximityBonus(nil)==0)
result=assert(UVAI.buildWeightMap(zombie,nil,nil,nil,nil))
assert(result.action and result.hungerLevel==nil and not result.hungerQueried)
for _=1,10000 do UVAI.buildWeightMap(zombie,{},0,0,0) end
assert(hungerReads==0,'idle populations must not poll hunger for an impossible chase')
zombie.isTargetVisible=function()return true end;zombie.getTarget=function()return other end
local pursuit=UVAI.buildWeightMap(zombie,{},0,0,1)
assert(pursuit.hungerQueried and pursuit.hungerLevel==0.5 and pursuit.hungerBonus>0 and hungerReads==1)
local continued=UVAI.buildWeightMap(zombie,{currentAction='CHASE'},0,0,2)
assert(continued.hungerBonus>pursuit.hungerBonus and hungerReads==2,'active chase persistence bonus retained')
zombie.isTargetVisible=function()return false end;zombie.getTarget=function()end
assert(UVAI.buildWeightMap(zombie,{},0,0,3).actual.CHASE==0 and hungerReads==2)

local bleeding={getBodyDamage=function() error("unavailable") end}
require "ProjectNightfall/PN_TargetStimulus"
local TargetStimulus=ProjectNightfall.TargetStimulus
local label,level=TargetStimulus.getBleedingSeverity(bleeding)
assert(label=="None" and level==0)

print("Project Nightfall nil-safe local AI boundary checks passed")

ProjectNightfall.Effigies.findNearbyReaction=function()
    return {id="regular-effigy"},{actor="intelligentRegular",action="destroy"},1
end
local destruction=assert(UVAI.buildWeightMap(zombie,{},0,0,1,0))
assert(destruction.actual.DESTROY_EFFIGY>0 and destruction.action=="DESTROY_EFFIGY",
    "intelligent regular destroy reaction must enter the destruction action")
