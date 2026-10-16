local authority=true
local data={}
local detached=false
package.loaded["Mortis/Runtime/AnatomyRuntime"]={getRegion=function(_,id)
    if id=="leftArm" or id=="rightArm" then return {attached=not detached},{},id end
end}
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function() return data end}
local applied,calls={},0
local failArm=true
package.loaded["Mortis/Runtime/TraumaRuntime"]={promote=function(_,ctx)
    if ctx.region=="rightArm" and failArm then return false,"injected save failure" end
    local old=applied[ctx.region] or 0
    if ctx.stage>old then applied[ctx.region]=ctx.stage; calls=calls+1 end
    return true
end}
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local entity={}
local profiles={}
for _,region in ipairs({"leftArm","rightArm"}) do
    profiles[region]={transmission=1,exposureFactor=1,capacity=100,naturalCapFraction=.64,
        thresholds={.10,.20},woundMagnitudes={5,15}}
end
local incident={natural=1,artificial=1}
assert(not Tissue.advance(entity,profiles,incident,0,5))
assert(calls==1 and data[Tissue.KEY].pending)
assert(not data[Tissue.KEY].regions.leftArm,"failed batch must not report a committed wound stage")
failArm=false
-- Simulated module reload: durable journal, not runtime locals, drives recovery.
package.loaded["ProjectNightfall/PN_UVTissueState"]=nil
Tissue=require "ProjectNightfall/PN_UVTissueState"
assert(Tissue.recover(entity))
assert(calls==2 and not data[Tissue.KEY].pending)
assert(data[Tissue.KEY].regions.leftArm.naturalScore==5)
assert(Tissue.advance(entity,profiles,incident,0,5) and calls==2)
assert(not Tissue.advance(entity,profiles,incident,4,6))
assert(Tissue.advance(entity,profiles,incident,5,10) and calls==4)
assert(data[Tissue.KEY].regions.leftArm.woundStage==2)
authority=false
assert(not Tissue.advance(entity,profiles,incident,10,15))
assert(not Tissue.consume(entity,{leftArm=1}))
authority=true
assert(Tissue.advance(entity,profiles,{natural=0,artificial=0},10,20))
assert(data[Tissue.KEY].regions.leftArm.woundStage==2)
local snapshot=Tissue.snapshot(entity)
snapshot.regions.leftArm.naturalScore=999
assert(Tissue.snapshot(entity).regions.leftArm.naturalScore==10)
local ok,spent=Tissue.consume(entity,{leftArm=5})
assert(ok and spent.consumed==5 and spent.regions.leftArm.natural==2.5
    and spent.regions.leftArm.artificial==2.5)
local afterSpend=Tissue.snapshot(entity)
assert(afterSpend.regions.leftArm.naturalScore==7.5 and afterSpend.regions.leftArm.artificialScore==7.5
    and afterSpend.regions.leftArm.woundStage==2,"spending score must not heal its wound")
assert(not Tissue.consume(entity,{leftArm=16}),"default spend must be atomic when score is insufficient")
assert(Tissue.snapshot(entity).regions.leftArm.naturalScore==7.5)
local partialOk,partial=Tissue.consume(entity,{leftArm=20},true)
assert(partialOk and partial.consumed==15 and partial.regions.leftArm.remaining==0)
assert(Tissue.snapshot(entity).regions.leftArm.woundStage==2)
local moved,transfer=Tissue.transfer(entity,"rightArm","leftArm",10,.8,
    {leftArm=100,rightArm=100},"transfer-1")
assert(moved and math.abs(transfer.removed-10)<1e-9 and math.abs(transfer.delivered-8)<1e-9
    and math.abs(transfer.lost-2)<1e-9)
local transferred=Tissue.snapshot(entity)
assert(transferred.regions.rightArm.naturalScore==5 and transferred.regions.rightArm.artificialScore==5)
assert(transferred.regions.leftArm.naturalScore==4 and transferred.regions.leftArm.artificialScore==4)
assert(select(2,Tissue.transfer(entity,"rightArm","leftArm",10,.8,
    {leftArm=100,rightArm=100},"transfer-1")).replayed==true)
assert(Tissue.repairWoundStage(entity,"leftArm",1,"repair-stage-1"))
assert(Tissue.snapshot(entity).regions.leftArm.woundStage==1)
detached=true
assert(not Tissue.consume(entity,{leftArm=1}),"detached storage cannot fuel biology")
assert(not Tissue.transfer(entity,"rightArm","leftArm",1,1,{leftArm=100},"detached-transfer"))
detached=false
assert(Tissue.repairWoundStage(entity,"leftArm",1,"repair-stage-1"))
assert(not Tissue.advance(entity,profiles,incident,20,math.huge))
data[Tissue.KEY]={schemaVersion=99,regions={}}
assert(not Tissue.recover(entity))
print("Nightfall UV tissue journal, interval deduplication, recovery and authority checks passed")

local function journal()
    return {schemaVersion=2,lastMinute=20,
        regions={leftArm={naturalScore=10,artificialScore=10,woundStage=2}},
        pending={toMinute=25,regions={leftArm={naturalScore=20,artificialScore=20,woundStage=3}},
            wounds={{region="leftArm",stage=3,magnitude=30}}}}
end
local mutations={
    function(s) s.pending.wounds={} end,
    function(s) s.pending.wounds[2]=s.pending.wounds[1] end,
    function(s) s.pending.regions.leftArm.naturalScore=9 end,
    function(s) s.pending.toMinute=20 end,
    function(s) s.pending.regions={} end,
    function(s) s.pending.regions.leftArm.woundStage=2; s.pending.wounds[1].stage=2 end,
}
for _,mutate in ipairs(mutations) do
    local s=journal(); mutate(s); data[Tissue.KEY]=s
    local before=calls
    assert(not Tissue.recover(entity),"inconsistent journal must reject before trauma")
    assert(calls==before and data[Tissue.KEY]==s,"failed validation must preserve forensic state")
end
print("Nightfall UV recovery journal consistency checks passed")
