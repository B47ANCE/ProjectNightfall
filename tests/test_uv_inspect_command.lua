local sampled=0
local sharedItem={}
local emitter={item=sharedItem,owner={}}
package.loaded["lightWorks/lightWorks_UV"]={collectPlayerEmitters=function() return {emitter} end,
    collectWorldEmitters=function() return {emitter} end,
    getVerifiedExposure=function(_,emitters,ctx)
        sampled=sampled+1
        assert(#emitters==1,"same source must not count twice")
        assert(ctx.windowTransmission==.25)
        return {uv={complete=true}}
    end}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function() return {regions={head={}}} end}
package.loaded["ProjectNightfall/PN_UVProtection"]={defaults=function() return {} end,compile=function() return function() return .1 end end}
package.loaded["ProjectNightfall/PN_UVDiagnostics"]={inspect=function() return {layers={}} end,lines=function() return {"test"} end}
getPlayer=function() return {} end
dofile("src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVInspect.lua")
assert(PNTestUVInspect({},.25))
assert(sampled==1)
assert(not PNTestUVInspect(nil))
isClient=function() return true end
assert(not PNTestUVInspect({},.25) and sampled==1)
isClient=function() return false end
package.loaded["ProjectNightfall/PN_UVDiagnostics"].inspect=function() error("incompatible native object") end
assert(not PNTestUVInspect({},.25))
print("Nightfall read-only UV inspection command guards and source deduplication passed")
local reads=0
package.loaded["Mortis/Runtime/Adapters/StateAdapter"]={
    snapshot=function()return {nativeState="AttackState",crawling=false}end,
    getCanWalk=function()return true end,
    getVariable=function(_,name)reads=reads+1;return name=="AttackType" and "bite" or nil end,
}
local combat=assert(PNTestCombatInspect({},true))
assert(combat.state.nativeState=="AttackState" and combat.canWalk==true)
assert(combat.variables.AttackType.value=="bite" and reads==4)
assert(not PNTestCombatInspect(nil,true))
isClient=function()return true end
assert(not PNTestCombatInspect({},true) and reads==4)
isClient=function()return false end
package.loaded["Mortis/Runtime/Adapters/StateAdapter"].snapshot=function()error("binding unavailable")end
assert(not PNTestCombatInspect({},true))
