local data={unrelated="preserved"}
local authority=true
local anatomy={speciesId="test",regions={head={attached=true,destroyed=true,integrity=0,tissueCapacity=7,remainingTissue=1},
    leftArm={attached=true,destroyed=false,integrity=70,tissueCapacity=8,remainingTissue=6}}}
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function(entity) return entity.data or data end,
    kind=function(entity) return entity.kind or "infected" end,isDead=function(entity) return entity.dead==true end}
local spawnCallback,deathCallback
Events={OnDeadBodySpawn={Add=function(fn) spawnCallback=fn end},
    OnZombieDead={Add=function(fn) deathCallback=fn end}}
package.loaded["Mortis/Runtime/Adapters/CorpseAdapter"]={isCorpse=function(entity) return entity.corpse==true end}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return anatomy end,
    getRegion=function(_,id) return anatomy.regions[id],{critical=id=="head"} end}
local R=require "ProjectNightfall/PN_UVRemains"
local entity={}
local tissue={lastMinute=20,regions={head={naturalScore=40,artificialScore=60,woundStage=7},
    leftArm={naturalScore=10,artificialScore=0,woundStage=1}}}
local record=assert(R.prepare(entity,tissue))
assert(record.status=="pending" and data.unrelated=="preserved")
assert(record.regions.head.tissue.capacity==7 and record.regions.head.tissue.remaining==1)
assert(record.regions.leftArm.tissue.remainingFraction==.75)
anatomy.regions.head.remainingTissue=0
tissue.regions.head.artificialScore=0
assert(R.prepare(entity,tissue)==record and record.regions.head.artificialScore==60,
    "repeated callbacks must not replace frozen death evidence")
assert(record.regions.head.tissue.remaining==1,"death-time tissue evidence must stay frozen")
assert(not R.finish(entity,{},true))
assert(R.finish(entity,record,false) and data[R.KEY]==nil,"failed transition must remove its pending label")
record=assert(R.prepare(entity,tissue))
assert(R.finish(entity,record,true) and record.status=="confirmed")
assert(R.finish(entity,record,false) and data[R.KEY]==record,"a late failure cannot erase confirmed evidence")
local view=R.inspect(entity);view.regions.leftArm.integrity=0
assert(record.regions.leftArm.integrity==70)
authority=false
assert(not R.prepare(entity,tissue) and not R.finish(entity,record,true))
authority=true;data[R.KEY]={schemaVersion=99}
assert(not R.prepare(entity,tissue) and data[R.KEY].schemaVersion==99)
data[R.KEY]=nil
record=assert(R.prepare(entity,tissue))
local copy=require("Mortis/Core/Util").deepCopy
local corpse={corpse=true,data=copy(data),inventory={"clothes","loot"}}
assert(not R.finalizeCorpse(entity),"living entities cannot use corpse confirmation")
assert(record.status=="pending")
spawnCallback(corpse)
assert(corpse.data[R.KEY].status=="confirmed" and record.status=="pending",
    "spawn confirmation must affect the native copied record only")
assert(corpse.inventory[1]=="clothes" and corpse.inventory[2]=="loot")
assert(corpse.data[R.KEY].regions.leftArm.integrity==70 and corpse.data.unrelated=="preserved")
assert(R.finalizeCorpse(corpse) and corpse.data[R.KEY].status=="confirmed")
authority=false;corpse.data[R.KEY].status="pending"
spawnCallback(corpse)
assert(corpse.data[R.KEY].status=="pending","clients must not finalize biological state")
authority=true;corpse.data[R.KEY]={schemaVersion=99}
assert(not R.finalizeCorpse(corpse) and corpse.data[R.KEY].schemaVersion==99)
corpse.data[R.KEY]=nil
assert(R.finalizeCorpse(corpse) and corpse.data[R.KEY]==nil,"ordinary corpses remain untouched")
data[R.KEY]=nil
record=assert(R.prepare(entity,tissue))
assert(not R.confirmDeath(entity) and record.status=="pending","living hibernators are not deaths")
entity.dead=true
authority=false;deathCallback(entity)
assert(record.status=="pending","client death events cannot confirm state")
authority=true;deathCallback(entity)
assert(record.status=="confirmed")
local serverCorpseData=copy(data)
assert(serverCorpseData[R.KEY].status=="confirmed","server corpse must inherit confirmation without a spawn event")
assert(R.finish(entity,record,false) and record.status=="confirmed","late failure cannot erase native confirmed death")
entity.kind="player";assert(not R.confirmDeath(entity))
print("Nightfall UV remains frozen evidence, rollback and authority checks passed")
