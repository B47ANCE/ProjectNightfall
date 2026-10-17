-- Real MORTIS and Nightfall modules; modeled native methods, no game process.
local M=require 'Mortis/init'
local I=require 'ProjectNightfall/PN_MortisIntegration'
require('Mortis/API/Species').register{id='Test.Recovery',defaultRegion='torso',regions={torso={integrity=100,tissueCapacity=100}}}
getGameTime=function()return {getWorldAgeHours=function()return 100 end}end
local classes={slowModded=3,slow1=3,['1']=2,sprint1=1}
IsoZombie={getSpeedTypeFromWalkType=function(walk)return classes[walk]end}
local function zombie()
 local z={data={},walk='slowModded',category=3,scalar=1.4,crawler=false,variant=7}
 function z:getModData()return self.data end
 function z:isZombie()return true end
 function z:getWalkType()return self.walk end
 function z:getSpeedType()return self.category end
 function z:getSpeedMod()return self.scalar end
 function z:isCrawling()return self.crawler end
 function z:getCrawlerType()return self.variant end
 function z:isOnFloor()return self.onFloor==true end
 function z:isGettingUp()return false end
 function z:getCurrentState()return 'ZombieWalkTowardState' end
 function z:setWalkType(v)self.walk=v end
 function z:setSpeedTypeFromWalkType()self.category=classes[self.walk]end
 function z:setSpeedMod(v)self.scalar=v end
 function z:setCrawler(v)self.crawler=v end
 function z:setCrawlerType(v)self.variant=v end
 function z:doShambler()self.walk='slow1';self.category=3;self.scalar=.75 end
 function z:doFastShambler()self.walk='1';self.category=2;self.scalar=.75 end
 function z:doSprinter()self.walk='sprint1';self.category=1;self.scalar=.75 end
 M.Capabilities.observeZombie(z)
 assert(M.Anatomy.attach(z,'Test.Recovery'))
 return z
end
local z=zombie();assert(I.assign(z,I.TYPE_FERAL))
assert(I.setNightfallBaseSpeed(z,'fastShambler'));assert(I.setUVSlowed(z,true));assert(I.setFeralSprint(z,true))
assert(M.LocomotionOverrides.setCeiling(z,'ProjectNightfall.TissueInjury','fastShambler'))
assert(I.clear(z),'NF-M01 must release only own requests and ceiling before clear')
assert(M.getTypeId(z)==nil and z.walk=='slowModded' and z.scalar==1.4)
assert(I.clear(z),'duplicate cleanup must be safe')
assert(I.assign(z,I.TYPE_FERAL));assert(I.setNightfallBaseSpeed(z,'fastShambler'))
assert(M.LocomotionOverrides.acquire(z,'Other.Owner',{tier='sprinter',priority=90}))
assert(not I.clear(z),'another owner must not be stolen')
assert(M.getTypeId(z)==I.TYPE_FERAL and z.category==1)
assert(M.LocomotionOverrides.release(z,'Other.Owner'));assert(I.clear(z))
local busy=zombie();assert(I.assign(busy,I.TYPE_FERAL));assert(I.setUVSlowed(busy,true))
busy.onFloor=true
assert(not I.setUVSlowed(busy,false) and not I.clear(busy))
assert(M.getTypeId(busy)==I.TYPE_FERAL and M.Components.allFor(busy)['Mortis.LocomotionOverrideBaseline'])
busy.onFloor=false;assert(I.clear(busy))

local nutrition=M.Anatomy.applyNutritionProfile
M.Anatomy.applyNutritionProfile=function()return nil,'injected nutrition refusal'end
local owned=zombie();assert(I.setNightfallBaseSpeed(owned,'fastShambler'))
assert(not I.assign(owned,I.TYPE_SMART_FERAL))
assert(M.getTypeId(owned)==nil and owned.data.ProjectNightfallAssignmentRecovery==nil and owned.scalar==1.4,
 'NF-M03 own lease must permit verified compensation to the untyped baseline')
local failed=zombie();assert(I.setNightfallBaseSpeed(failed,'fastShambler'))
assert(M.LocomotionOverrides.acquire(failed,'Other.Owner',{tier='sprinter',priority=90}))
local ok,reason=I.assign(failed,I.TYPE_SMART_FERAL)
assert(not ok and reason:find('recovery pending',1,true),'NF-M03 must expose incomplete compensation')
local journal=assert(failed.data.ProjectNightfallAssignmentRecovery)
assert(journal.version==1 and journal.prior==false and journal.target==I.TYPE_SMART_FERAL)
local priorPhase={phase='NORMAL',smartFeral=false}
I.applyIdentityToState(failed,priorPhase)
assert(priorPhase.phase=='NORMAL' and priorPhase.smartFeral==false,'pending target must not become a restored lifecycle phase')
assert(not I.recoverAssignment(failed),'held owner must retain quarantine')
assert(not I.assign(failed,I.TYPE_FERAL),'pending transaction must block replacement')
-- Reload consumer module and retain serialized data: no weak-table-only recovery.
package.loaded['ProjectNightfall/PN_MortisIntegration']=nil
I=require 'ProjectNightfall/PN_MortisIntegration'
assert(not I.recoverAssignment(failed) and failed.data.ProjectNightfallAssignmentRecovery==journal)
assert(M.LocomotionOverrides.release(failed,'Other.Owner'))
assert(I.recoverAssignment(failed))
assert(M.getTypeId(failed)==nil and failed.data.ProjectNightfallAssignmentRecovery==nil)
assert(I.recoverAssignment(failed),'repeated recovery must not assign again')
local clean=zombie();assert(not I.assign(clean,I.TYPE_FERAL));assert(M.getTypeId(clean)==nil)
assert(clean.data.ProjectNightfallAssignmentRecovery==nil,'successful compensation clears journal')
M.Anatomy.applyNutritionProfile=nutrition
assert(I.assign(clean,I.TYPE_FERAL))
M.Anatomy.applyNutritionProfile=function()return nil,'injected nutrition refusal'end
assert(not I.assign(clean,I.TYPE_SMART_FERAL));assert(M.getTypeId(clean)==I.TYPE_FERAL)
M.Anatomy.applyNutritionProfile=nutrition
local future=zombie();future.data.ProjectNightfallAssignmentRecovery={version=2,prior=false,target=I.TYPE_FERAL}
assert(not I.recoverAssignment(future) and not I.assign(future,I.TYPE_FERAL))
assert(future.data.ProjectNightfallAssignmentRecovery.version==2,'future state must be preserved')
future.data.ProjectNightfallAssignmentRecovery={version=1,prior=false,target=I.TYPE_FERAL,status='rollback',unknown=true}
assert(not I.recoverAssignment(future),'malformed journal must refuse')
local uncertain=zombie()
M.Anatomy.applyNutritionProfile=function()error('injected uncertain provider')end
assert(not I.assign(uncertain,I.TYPE_FERAL))
assert(uncertain.data.ProjectNightfallAssignmentRecovery.status=='uncertain')
assert(not I.recoverAssignment(uncertain),'uncertain biology must not be guessed away')
M.Anatomy.applyNutritionProfile=nutrition
local changed=zombie();assert(I.assign(changed,I.TYPE_FERAL))
changed.data.ProjectNightfallAssignmentRecovery={version=1,prior=false,target=I.TYPE_SMART_FERAL,status='rollback'}
assert(not I.recoverAssignment(changed) and M.getTypeId(changed)==I.TYPE_FERAL,'unexpected identity must not be cleared')
local unreadable=zombie();assert(I.assign(unreadable,I.TYPE_FERAL))
unreadable.data.ProjectNightfallAssignmentRecovery={version=1,prior=false,target=I.TYPE_FERAL,status='rollback'}
local clear=M.clearAssignment;M.clearAssignment=function()return true end
assert(not I.recoverAssignment(unreadable) and unreadable.data.ProjectNightfallAssignmentRecovery,'a lying clear needs failed readback retained')
M.clearAssignment=clear;assert(I.recoverAssignment(unreadable))
local Diagnostics=require 'ProjectNightfall/PN_DependencyDiagnostics'
local Knowledge=require 'B47ANCEDKnowledgeAndWisdom/API'
local present,missing,_,scope=Diagnostics.inspect(
 {registerBulb=function()end,UV={getSunlightExposure=function()end,getArtificialExposure=function()end}},
 {registerLoad=function()end},M,{getDetachedPartProvenance=function()end,performProcedure=function()end},Knowledge)
assert(present and #missing==0 and scope.foodTransactions=='v1' and scope.status=='SOURCE_CAPABILITIES_AVAILABLE')
local client=zombie()
isClient=function()return true end
assert(not I.assign(client,I.TYPE_FERAL));assert(client.data.ProjectNightfallAssignmentRecovery==nil)
assert(not I.clear(clean) and not I.recoverAssignment(clean))
isClient=function()return false end
print('Real MORTIS cleanup, cross-owner refusal and durable assignment recovery pass offline')
