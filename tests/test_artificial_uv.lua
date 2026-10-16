ProjectNightfall={Config={POC={}}}
package.preload["ProjectNightfall/PN_Config"]=function() return ProjectNightfall.Config end
package.preload["ProjectNightfall/PN_FlashlightBulbs"]=function() return {} end
lightWorks={UV={collectPlayerEmitters=function() return {} end}}
package.preload["lightWorks/lightWorks_UV"]=function() return lightWorks.UV end
local Mortis={Authority={canWriteCanonicalState=function() return false end}}
package.preload["Mortis/init"]=function() return Mortis end
local tickCallback
Events={OnTick={Add=function(callback) tickCallback=callback end}}

dofile(assert(arg[1]))
local uv=ProjectNightfall.ArtificialUV

local function point(x,y,z) return {getX=function() return x end,getY=function() return y end,getZ=function() return z end} end
assert(uv.isNearEmitter(point(3,4,0),{{owner=point(0,0,0),range=5}})==true)
assert(uv.isNearEmitter(point(3,4,1),{{owner=point(0,0,0),range=5}})==false)
assert(uv.isNearEmitter(point(6,0,0),{{owner=point(0,0,0),range=5}})==false)
assert(uv.calculateDamage==nil and uv.applyDamage==nil and uv.processZombie==nil,
    "emitter provider must not retain legacy direct-damage entry points")

Mortis.Authority.canWriteCanonicalState=function() return true end
local player=point(0,0,0)
local zombie=point(0,0,0)
getPlayer=function() return player end
getNumActivePlayers=function() return 0 end
lightWorks.UV.collectPlayerEmitters=function() error("modded emitter collector failed") end
assert(type(tickCallback)=="function")
for _=1,10 do assert(pcall(tickCallback),"scheduled UV update must contain emitter integration failures") end

lightWorks.UV.collectPlayerEmitters=function() return {{owner=player,range=5}} end
for _=1,10 do assert(pcall(tickCallback),"scheduled UV update must contain Java-list bridge failures") end
local emitters=uv.getCurrentEmitters(zombie)
assert(#emitters==1 and emitters[1].owner==player,"primary scheduler must receive a copied relevant-emitter snapshot")
emitters[1].range=0;emitters[1]=nil
assert(#uv.getCurrentEmitters(zombie)==1 and uv.getCurrentEmitters(zombie)[1].range==5,
    "callers cannot mutate the emitter snapshot or definitions")
local attacks=0
ProjectNightfall.DenDefense={considerIndependentUVAttack=function(_,source) attacks=attacks+1;assert(source.id=="lamp") end}
lightWorks.EmissionSources={inspect=function(item) return item and {id="lamp",channels={UV=true},destroy={supported=true}} end}
assert(uv.considerIndependentAttack(zombie,{sources={{item={}}}}) and attacks==1)
assert(not uv.considerIndependentAttack(zombie,{sources={{item={}}}}) and attacks==1,"cooldown must prevent repeated decisions")
assert(not tostring(assert(io.open(arg[1],"rb")):read("*a")):find("setHealth",1,true),
    "artificial emitter provider must never write zombie health")
print("Project Nightfall artificial-UV emitter-provider and tactical handoff checks passed")
