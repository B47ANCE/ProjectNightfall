local authority=true
local server=false
local sends,sendFails=0,false
local tissue={capacity=100,remaining=100,remainingFraction=1,regions={}}
local data={loot={"clothes","watch"},cause="gunshot"}
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end,
    isDedicatedServerRuntime=function() return server end}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={tissueSnapshot=function() return tissue end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function() return data end,
    transmitModData=function() sends=sends+1;if sendFails then return false,"network unavailable" end return true end}
local State=require "ProjectNightfall/PN_UVRemainsState"
local corpse={}
local limits={.1,.35,.65,.9}
local ok,result=State.update(corpse,limits,10)
assert(ok and result.changed and result.state.stage=="INTACT")
tissue.remaining=80
ok,result=State.update(corpse,limits,20)
assert(ok and result.changed and result.state.stage=="SCORCHED" and result.state.enteredMinute==20)
tissue.remaining=40
assert(State.update(corpse,limits,30))
assert(State.inspect(corpse).stage=="DESICCATED")
tissue.remaining=5
assert(State.update(corpse,limits,40))
local final=assert(State.inspect(corpse))
assert(final.stage=="RESIDUAL" and final.destructionFraction==.95)
assert(data.cause=="gunshot" and data.loot[1]=="clothes" and data.loot[2]=="watch",
    "semantic progression must preserve cause and loot")
local view=State.inspect(corpse);view.stage="INTACT";assert(State.inspect(corpse).stage=="RESIDUAL")
tissue.remaining=90
assert(not State.update(corpse,limits,50),"corpse stages cannot regress through unowned restoration")
assert(not State.evaluate(tissue,{.1,.1,.5,.9}))
data[State.KEY]={schemaVersion=99};assert(not State.update(corpse,limits,60))
data[State.KEY]=nil;tissue.remaining=80;server=true;sendFails=true
ok,result=State.update(corpse,limits,60)
assert(ok and result.changed and result.syncPending and result.transmissionError=="network unavailable" and sends==1)
sendFails=false
ok,result=State.update(corpse,limits,61)
assert(ok and not result.changed and result.synchronized and not result.syncPending and sends==2,
    "unchanged stage must retry one durable failed transmission")
assert(State.update(corpse,limits,62) and sends==2,"synchronized unchanged stage must not transmit every interval")
authority=false;assert(not State.update(corpse,limits,60))
print("Nightfall canonical-tissue remains-stage monotonicity and preservation checks passed")
