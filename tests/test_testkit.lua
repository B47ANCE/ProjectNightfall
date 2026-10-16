local items={}
local marker={}
local inventory={AddItem=function(_,fullType) items[#items+1]=fullType return {type=fullType} end}
local player={getInventory=function() return inventory end,getModData=function() return marker end}
getPlayer=function() return player end
ProjectNightfall={
    ZombieUV={getDiagnosticStats=function() return {tracked=12,processed=34,rises=2,errors=0} end},
    FeralGroups={getDiagnostics=function() return {
        pendingResponses=3,responsesDropped=1,followerPathAttempts=7,
        followerPathSucceeded=6,followerPathFailed=1,followerLastPathAttempts=2,
        followerLastGroupsInspected=1,
    } end},
    UVCorpseRuntime={getDiagnostics=function() return {lastEmitters=2,lastCandidates=4,
        lastProcessed=3,lastSquaresScanned=8,lastScanRemaining=24,failures=1} end},
}
Mortis={Scheduler={getDiagnostics=function() return {
    classes={fast={considered=10,ran=4,deferred=6},slow={considered=5,ran=1,deferred=4}},
    budgets={paths={requests=8,accepted=3,deferred=5}},
} end}}

dofile(arg[1])
assert(type(PNTestKit)=="function")
assert(type(PNPerformanceStatus)=="function")
local perfOk,performance=PNPerformanceStatus()
assert(perfOk and performance.lifecycle.tracked==12)
assert(performance.communication.responsesDropped==1)
assert(performance.communication.followerPathAttempts==7)
assert(performance.corpseUV.lastCandidates==4 and performance.corpseUV.lastProcessed==3)
local ok,result=PNTestKit()
assert(ok and result.granted==#items and #items>30)
local firstCount=#items
local duplicate,reason=PNTestKit()
assert(duplicate==false and reason=="already granted" and #items==firstCount)
local forced=PNTestKit(true)
assert(forced==true and #items==firstCount*2)
assert(PNTestGiveResearch()==false)
local Archive=require "ProjectNightfall/PN_ResearchArchive"
local granted,report=PNTestGiveResearch()
assert(granted and #report.granted==3 and #report.missing==0)
assert(not Archive.hasKnowledge(player,"ProjectNightfall.EffigyConstruction"))
assert(marker[Archive.ROOT_KEY]==nil,"test fixture must not create a knowledge ledger")
local status,rows=PNTestResearchStatus()
assert(status and rows["NF-UV-003"].canLearn and not rows["NF-FIELD-026"].canLearn)
assert(marker[Archive.ROOT_KEY]==nil)
assert(Archive.learn(player,"NF-UV-003"))
assert(Archive.learn(player,"NF-FIELD-026"))
local _,learned=PNTestResearchStatus()
assert(learned["NF-FIELD-026"].read)
isClient=function() return true end
assert(PNTestGiveResearch()==false)

print("Project Nightfall test-kit checks passed")

assert(PNTestCombatKit()==false,"multiplayer grant must be refused")
isClient=function()return false end
local floor={};local granted={}
local function fixture(id)
    return {id=id,ReadFromWorldSprite=function(self,s)self.sprite=s;return true end,
        getMaxAmmo=function()return 30 end,setCurrentAmmoCount=function(self,n)self.ammo=n end,
        setContainsClip=function()end,setRoundChambered=function()end,
        attachWeaponPart=function(self,p)self.part=p end}
end
instanceItem=fixture
inventory.AddItem=function(_,id)local item=fixture(id);granted[#granted+1]=item;return item end
player.getCurrentSquare=function()return {AddWorldInventoryItem=function(_,item,x,y,z)
    assert(item.sprite=="lighting_outdoor_01_48" and z==0);floor[#floor+1]=item;return item end}end
lightWorks={installBulb=function(part,bulb)part.bulb=bulb;return true end}
local combatOK,combat=PNTestCombatKit()
assert(combatOK and #floor==10 and combat.bulbs==10 and combat.magazines==6 and combat.gear==13)
local guns=0;for _,item in ipairs(granted)do
    if item.id=="Base.AssaultRifle"then guns=guns+1;assert(item.ammo==30 and item.part.bulb=="ProjectNightfall.LightBulbUVHighOutput")end
    if item.id=="Base.556Clip"then assert(item.ammo==30)end
end
assert(guns==1)
print("Project Nightfall combat-kit floor, weapon, magazine, armour and authority checks passed")

local loaded=false;local teleports={};local tick
local sq={TreatAsSolidFloor=function()return true end,isSolid=function()return false end,isSolidTrans=function()return false end}
getCell=function()return {getGridSquare=function(_,x,y,z)assert(x==10643 and y==10408 and z==1);return loaded and sq or nil end}end
player.teleportTo=function(_,x,y,z)teleports[#teleports+1]={x,y,z}end
player.getX=function()return 10643.5 end;player.getY=function()return 10408.5 end;player.isDead=function()return false end
Events={OnTick={Add=function(fn)tick=fn end,Remove=function(fn)assert(fn==tick);tick=nil end}}
assert(PNTestPoliceRoof());assert(teleports[1][3]==0 and tick)
assert(PNTestPoliceRoof()==false)
loaded=true;tick();assert(teleports[2][3]==1 and tick==nil)
assert(PNTestPoliceRoof() and teleports[3][3]==1)
isClient=function()return true end;assert(PNTestPoliceRoof()==false)
print("Project Nightfall roof teleport loaded-floor and streaming checks passed")
