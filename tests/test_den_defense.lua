local objectives=setmetatable({},{__mode="k"});local group
local authority=true
local rejectCleanup=false
local arms={leftArm=1,leftHand=1,rightArm=1,rightHand=1}
package.loaded["Mortis/init"]={Authority={canWriteCanonicalState=function()return authority end},
    AnatomyCapabilities={functionalSnapshot=function()return {regionFunction=arms}end},Groups={getFor=function()return group end},
    CommandHierarchy={setObjective=function(entity,kind,point)objectives[entity]={kind=kind,point=point};return true end,
        get=function(entity)return {objective=objectives[entity]} end,
        clearObjective=function(entity)
            if rejectCleanup then return false,"injected persistence failure" end
            objectives[entity]=nil;return true
        end}}
local Sources={inspect=function(object)return object.source end,requestPhysicalAttack=function(source,pawn)return source.destroy.requestAttack(pawn,source.object,source)end}
package.loaded["lightWorks/lightWorks_EmissionSources"]=Sources
local Defense=require "ProjectNightfall/PN_DenDefense"
local smart={};local pawn={getX=function()return 0 end,getY=function()return 0 end,getZ=function()return 0 end,
    pathToLocationF=function(self,x,y,z)self.path={x=x,y=y,z=z}end}
group={leader=smart,members={{entity=smart,role="leader"},{entity=pawn,role="member"}}}
local attacked=false
local visible={x=2,y=0,z=0,emitting=true,on=true,powered=true,intensity=1,channels={visible=true},object={}}
local uv={x=3,y=0,z=0,emitting=true,on=true,powered=true,intensity=1,channels={visible=true,UV=true},object={}}
local function destruction(source)source.destroy={supported=true,requestAttack=function()attacked=true;return true end};source.object.source=source end
destruction(visible);destruction(uv)
local den={location={x=0,y=0,z=0}}
assert(Defense.selectSource(den,{visible,uv},{radius=10})==uv,"active UV should outrank ordinary visible light")
local selectedPawn,selected=assert(Defense.assign(smart,den,{visible,uv},{radius=10}))
assert(selectedPawn==pawn and selected==uv and objectives[pawn].kind=="destroy-den-emitter")
pawn.getX=function()return 3 end
assert(Defense.updateTask(pawn,1.5) and attacked,"arrival must delegate to physical-attack provider")
assert(Defense.getTask(pawn),"a physical attack attempt is not proof that emission stopped")
authority=false;attacked=false
assert(not Defense.updateTask(pawn,1.5) and not attacked)
assert(Defense.getTask(pawn),"read-only client must not mutate task state")
authority=true;arms={leftArm=0,leftHand=1,rightArm=0,rightHand=1}
assert(not Defense.updateTask(pawn,1.5) and not attacked)
assert(not Defense.getTask(pawn),"arm loss after assignment must cancel the attack")
assert(objectives[pawn]==nil,"cancellation must release the matching persisted objective")
assert(not Defense.assign(smart,den,{uv},{radius=10}),"incapable pawns must not be recruited")
arms={leftArm=1,leftHand=0,rightArm=0,rightHand=1}
assert(not Defense.canAttackEmitter(pawn),"arm and hand must belong to the same side")
arms={leftArm=1,leftHand=1,rightArm=0,rightHand=0}
assert(Defense.canAttackEmitter(pawn),"one functional arm/hand can attack a fixture")
assert(Defense.assign(smart,den,{uv},{radius=10}))
objectives[pawn]={kind="new-command",point={x=99,y=99,z=0}}
uv.object.source=nil
assert(not Defense.updateTask(pawn,1.5) and not Defense.getTask(pawn))
assert(objectives[pawn].kind=="new-command","cleanup must preserve replacement objectives")
uv.object.source=uv
local inactive={x=1,y=0,z=0,emitting=false,on=false,powered=true,channels={UV=true},destroy=uv.destroy}
assert(Defense.selectSource(den,{inactive},{radius=10})==nil,"inactive fixtures are not targets")
assert(Defense.selectSource(den,{false,42,"invalid",{emitting=true,on=true,powered=true,x=0,y=0,z=0,destroy=true},uv},{radius=10})==uv)
assert(Defense.selectSource(den,false,{radius=10})==nil)
local regular={pathToLocationF=function(self,x,y,z)self.path=true end}
for _,bad in ipairs({true,42,"invalid",{channels=true},{channels={UV=true},emitting=true,on=true,powered=true,destroy=true}}) do
    assert(not Defense.considerIndependentUVAttack(regular,bad,1,function()return 0 end))
end
uv.powered=false
assert(not Defense.considerIndependentUVAttack(regular,uv,1,function()return 0 end))
uv.powered=true
assert(not Defense.considerIndependentUVAttack(regular,uv,.01,function()return .5 end))
assert(Defense.considerIndependentUVAttack(regular,uv,.01,function()return 0 end),"independent UV attack is rare and roll-gated")
local originalPath=pawn.pathToLocationF
pawn.pathToLocationF=function()return false end
rejectCleanup=true
assert(not Defense.assign(smart,den,{uv},{radius=10}))
assert(Defense.getTask(pawn).cancelReason=="pawn path request failed" and objectives[pawn])
attacked=false
assert(not Defense.updateTask(pawn,1.5) and not attacked and Defense.getTask(pawn),
    "pending cleanup must never resume attacking")
rejectCleanup=false
assert(not Defense.updateTask(pawn,1.5))
assert(Defense.getTask(pawn)==nil and objectives[pawn]==nil,"successful retry must clear task and objective")
pawn.pathToLocationF=function()error("injected native path failure")end
assert(not Defense.assign(smart,den,{uv},{radius=10}) and not Defense.getTask(pawn))
assert(objectives[pawn]==nil)
pawn.pathToLocationF=originalPath
local refusing={pathToLocationF=function()return false end}
assert(not Defense.considerIndependentUVAttack(refusing,uv,1,function()return 0 end))
assert(not Defense.getTask(refusing))
print("Project Nightfall den-defense targeting contract checks passed")
