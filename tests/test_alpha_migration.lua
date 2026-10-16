local ids=setmetatable({},{__mode="k"});local hierarchy=setmetatable({},{__mode="k"})
local tracked={}
local handlers={};local Events={}
function Events:on(name,fn)handlers[name]=handlers[name]or{};handlers[name][#handlers[name]+1]=fn end
function Events:emit(name,...)for _,fn in ipairs(handlers[name]or{})do fn(...)end end
local Mortis={
    Authority={canWriteCanonicalState=function()return true end},
    Identity={getStableId=function(e)return ids[e]end,ensureStableId=function(e)return ids[e]end},
    CommandHierarchy={
        get=function(e)return hierarchy[e]end,
        setObjective=function(e,kind,point,_,target)hierarchy[e]=hierarchy[e]or{};hierarchy[e].objective={kind=kind,point=point,targetStableId=target};return true end,
    },
    Engine={listTracked=function()return tracked end},
    Events=Events,
}
package.loaded["Mortis/init"]=Mortis
local types=setmetatable({},{__mode="k"})
package.loaded["ProjectNightfall/PN_MortisIntegration"]={TYPE_SMART_FERAL="Smart",TYPE_ALPHA_FERAL="Alpha",getTypeId=function(e)return types[e]end}
ProjectNightfall={Config={POC={EnableAlphaMigration=true,AlphaMigrationPressureMaximum=100,
    AlphaMigrationSpringPressureThreshold=55,AlphaMigrationSummerPressureThreshold=60,AlphaMigrationFallPressureThreshold=90}}}
getGameTime=function()return{getWorldAgeHours=function()return 200 end,getMonth=function()return 3 end}end

local Dens=require "ProjectNightfall/PN_DenState";Dens.resetForTests()
local Migration=require "ProjectNightfall/PN_AlphaMigration"
local function zombie(id,kind)
    local z={path=nil};ids[z]=id;types[z]=kind
    function z:pathToLocationF(x,y,level)self.path={x=x,y=y,z=level}end
    return z
end
local alpha=zombie("ALPHA","Alpha");local smart=zombie("SMART","Smart");tracked={alpha,smart}
hierarchy[smart]={superiorId="ALPHA"}
local territory=assert(Dens.claim(alpha,3,{x=10,y=10,z=-1,safe=true,kind="basement"},{radius=60}))
assert(Dens.establishSmartDen(alpha,smart,{x=11,y=10,z=0,safe=true,kind="house"}))
Events:emit("LivingEntityWeaponTrauma",smart,{structuralDamage=12})
assert(territory.migrationPressure.value==3 and territory.migrationPressure.evidence["successful-weapon-trauma"]==3)
assert(Migration.seasonForMonth(0)=="winter" and Migration.seasonForMonth(3)=="spring")
assert(Migration.seasonForMonth(6)=="summer" and Migration.seasonForMonth(9)=="fall")
assert(Dens.addMigrationPressure(alpha,"hierarchy-loss",57,199,100).value==60)
assert(Migration.evaluate(alpha,"spring")==true)
assert(Migration.evaluate(alpha,"summer")==true)
assert(Migration.evaluate(alpha,"fall")==false)
local winter,winterReason=Migration.evaluate(alpha,"winter");assert(not winter and winterReason=="winter-lock")
local unknown,unknownReason=Migration.begin(alpha,{x=50,y=50,z=0},"spring")
assert(not unknown and unknownReason=="known physical destination required")
hierarchy[alpha]={objective={kind="destroy-rival-alpha"}}
local rivalry,rivalryReason=Migration.begin(alpha,{x=50,y=50,z=0,known=true},"spring")
assert(not rivalry and rivalryReason=="rivalry takes priority")
hierarchy[alpha]=nil
assert(Migration.rememberDestination(alpha,{x=50,y=50,z=0,safe=true,kind="observed-region"},"alpha-local-observation"))
local begun,migration=Migration.beginKnown(alpha,"spring")
assert(begun and migration.status=="active" and territory.status=="abandoned")
assert(territory.alphaDen.status=="disbanded")
for _,den in pairs(territory.smartDens)do assert(den.status=="disbanded")end
assert(alpha.path.x==50 and smart.path.x==50)
assert(hierarchy[smart].objective.kind=="migrate-with-alpha")
local temporary=assert(Dens.setMigrationTemporaryShelter(alpha,"SMART",{x=25,y=25,z=0,safe=true,kind="house"},201))
assert(temporary.status=="active" and territory.alphaState=="temporary-day-shelter")
assert(Dens.clearMigrationTemporaryShelter(alpha,"SMART",202) and temporary.status=="departed")
assert(Dens.claim(alpha,3,{x=50,y=50,z=-1,safe=true,kind="basement"},{radius=60,worldAgeHours=203}))
assert(territory.status=="claimed" and territory.alphaState=="established" and territory.migration==nil)
assert(territory.lastMigration.status=="completed")
print("Project Nightfall seasonal Alpha migration policy checks passed")
