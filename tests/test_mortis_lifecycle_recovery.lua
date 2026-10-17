-- Execute identified production lifecycle functions; native boundaries modeled.
local file=assert(io.open('src/ProjectNightfall/42/media/lua/shared/ProjectNightfall/PN_ZombieUV.lua','r'))
local source=file:read('*a');file:close()
local function slice(first,last)
 local a=assert(source:find(first,1,true));local b=assert(source:find(last,a+1,true));return source:sub(a,b-1)
end
local releaseOK,clearOK=false,false
local state={phase='FERAL',smartFeral=true,alphaFeral=true,uvSlowed=true,sprintActive=true}
local captures,mutations,recoveryCalls=0,0,0
local env=setmetatable({
 log=function()end,recoveryLog=function()end,Config={EnableFerals=false,Diagnostic=false},
 MortisIntegration={
  setUVSlowed=function()return releaseOK,'busy' end,
  clear=function()return clearOK,'owned' end,
  captureWalkingBeforeHold=function()captures=captures+1;return true end,
  canWriteCanonicalState=function()return true end,
  recoverAssignment=function()recoveryCalls=recoveryCalls+1;return true,nil,false end,
 },getState=function()return state end,
}, {__index=_G})
local function compile(body)
 local fn=assert(loadstring(body));setfenv(fn,env);return fn()
end
local release,disable=compile(slice('local function releaseUVSlow','local function updateUVSlow')..'\nreturn releaseUVSlow,disableFerals')
env.releaseUVSlow=release;env.disableFerals=disable
assert(not release({},state) and state.uvSlowed,'NF-M02 keeps refused release tracked')
local Persistence=require 'ProjectNightfall/PN_StatePersistence'
local data={};assert(Persistence.save(data,state));local restored={uvSlowed=false}
assert(Persistence.restore(data,restored) and restored.uvSlowed,'pending cleanup survives state serialization')
local begin=compile(slice('local function beginFeralization','local function rawCognitionFor')..'\nreturn beginFeralization')
state.phase='NORMAL';assert(begin({},state,1)==false)
assert(state.phase=='NORMAL' and state.uvSlowed and captures==0,'busy release defers knockdown before lifecycle writes')
releaseOK=true;assert(release({},state) and not state.uvSlowed)
assert(Persistence.save(data,state));assert(Persistence.restore(data,restored) and restored.uvSlowed==false)
env.Config.EnableFerals=true;env.Config.RequireStarvationForFerals=false
env.MortisIntegration.assign=function()return false,'nutrition failure' end
assert(begin({},state,1)==false and state.phase=='NORMAL','failed assignment must not begin hibernation')
env.hibernating={}
local dormant=compile(slice('local function enterRegularFeralDayDormancy','local function riseAtNight')..'\nreturn enterRegularFeralDayDormancy')
state.phase='FERAL';assert(not dormant({},state,1) and state.phase=='FERAL' and next(env.hibernating)==nil)
env.ZombieUV={};env.isActuallyDead=function()return false end;state.smartFeral=false
local promote=compile(slice('function ZombieUV.promoteToSmartFeral','function ZombieUV.isSmartFeral')..'\nreturn ZombieUV.promoteToSmartFeral')
assert(not promote({}) and state.smartFeral==false,'failed promotion must not commit visual/gear flags')
env.Config.EnableFerals=false
state.phase='FERAL';state.smartFeral=true;state.alphaFeral=true
assert(not disable({},state) and state.phase=='FERAL' and state.smartFeral and state.alphaFeral)
clearOK=true;assert(disable({},state))
assert(state.phase=='NORMAL' and not state.smartFeral and not state.alphaFeral and not state.sprintActive)
-- Execute the early update gate, before biological work or base-owner reacquisition.
env.FeralGroups=nil
local update=compile(slice('local function updateZombie','    -- Finish the durable healing transaction').."\n mutations()\nend\nreturn updateZombie")
env.mutations=function()mutations=mutations+1 end
state.phase='FERAL';clearOK=false
update({});assert(state.phase=='FERAL' and mutations==0 and recoveryCalls==1)
clearOK=true;update({});assert(state.phase=='NORMAL' and mutations==0)
local recovering={}
state.phase='FERAL';state.uvSlowed=true;state.sprintActive=true
env.MortisIntegration.recoverAssignment=function()return true,nil,true,false end
env.MortisIntegration.applyIdentityToState=function()end
update(recovering)
assert(state.phase=='NORMAL' and not state.uvSlowed and not state.sprintActive and not env.hibernating[recovering])
env.MortisIntegration.recoverAssignment=function()return true,nil,true,'Transforming' end
env.MortisIntegration.applyIdentityToState=function(_,s)s.phase='TRANSFORMING'end
update(recovering);assert(env.hibernating[recovering] and state.phase=='TRANSFORMING')
mutations=0
env.MortisIntegration.recoverAssignment=function()return false,'pending' end
update({});assert(mutations==0,'pending compensation blocks lifecycle work')
env.MortisIntegration.canWriteCanonicalState=function()return false end
env.MortisIntegration.recoverAssignment=function()error('client recovery forbidden')end
update({});assert(mutations==0)
print('Production lifecycle fragments retain failed cleanup and gate native work offline')
