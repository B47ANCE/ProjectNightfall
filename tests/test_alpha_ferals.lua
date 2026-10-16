local assigned, played, emitted, hierarchy, signal, priorHierarchy, formerCleared = nil, nil, nil, nil, nil, nil, false
local alphaHierarchy={objective={kind="destroy-rival-alpha"}}
local alpha, smart, rival = {}, {}, {}
function alpha:getX() return 10 end; function alpha:getY() return 20 end; function alpha:getZ() return 0 end
ProjectNightfall = { Config={ POC={ EnableAlphaFerals=true, AlphaReplacementChance=0.001, AlphaCallSound="AlphaCall" } } }
package.loaded["Mortis/init"] = {
    Authority={canWriteCanonicalState=function() return true end},
    Sound={play=function(_, sound) played=sound; return true end},
    Events={emit=function(_, name, _, payload) emitted={name=name,payload=payload} end,on=function() end},
    CommandHierarchy={
        assign=function(_, _, role) hierarchy=role; return true,{role=role} end,
        setObjective=function(_,kind) hierarchy=kind; return true end,
        get=function(entity) return entity==alpha and alphaHierarchy or priorHierarchy end,
        desertedFrom=function() return false end,
        clearFormerSuperior=function() priorHierarchy=nil;formerCleared=true;return true end,
        setMemory=function() return true end,
        getMemory=function() return 10 end,
    },
    Signals={emit=function(def) signal=def;return def end},
    Groups={getFor=function() return {size=11} end},
    getStableId=function() return "ALPHA-1" end,
}
package.loaded["ProjectNightfall/PN_MortisIntegration"] = {
    TYPE_ALPHA_FERAL="ProjectNightfall.AlphaFeral",
    TYPE_SMART_FERAL="ProjectNightfall.SmartFeral",
    assign=function(_, typeId) assigned=typeId; return true end,
    getTypeId=function(entity) return entity==smart and "ProjectNightfall.SmartFeral" or "ProjectNightfall.AlphaFeral" end,
}
local Alpha = require "ProjectNightfall/PN_AlphaFerals"
local state={smartFeral=true}
assert(not Alpha.rollAfterSmartPromotion(alpha,state,function() return 0.001 end), "boundary roll must fail")
assert(Alpha.rollAfterSmartPromotion(alpha,state,function() return 0.0009 end))
assert(state.alphaFeral and state.alphaState=="CALLING")
assert(assigned=="ProjectNightfall.AlphaFeral" and played=="AlphaCall")
assert(emitted.name=="ProjectNightfall.AlphaCall" and emitted.payload.x==10)
assert(signal.type=="ProjectNightfall.AlphaCall")
assert(Alpha.assignSmartLeader(alpha,smart,{x=10,y=20,z=0}))
assert(hierarchy=="rally-to-alpha")
function smart:getX() return 30 end;function smart:getY() return 40 end;function smart:getZ() return 0 end
function rival:getX() return 50 end;function rival:getY() return 60 end;function rival:getZ() return 0 end
assert(Alpha.lockRivalry(alpha,rival));assert(hierarchy=="destroy-rival-alpha")
assert(Alpha.emitDeathCry(alpha,"ALPHA-1"));assert(signal.type=="ProjectNightfall.AlphaDeathCry" and signal.payload.powerVacuum)
assert(Alpha.smartWarTargetPriority(smart,alpha,false)==100)
priorHierarchy={formerSuperiorId="FORMER"}
assert(not Alpha.assignSmartLeader(alpha,smart,{x=10,y=20,z=0}),"living/unresolved former Alpha must block defection")
assert(Alpha.emitDeathCry(alpha,"FORMER"))
assert(Alpha.assignSmartLeader(alpha,smart,{x=10,y=20,z=0}) and formerCleared,"authoritative former-Alpha death must reopen recruitment")
priorHierarchy={superiorId="ALPHA-1"}
local deserts,score,chance=Alpha.shouldDesert(smart,alpha,{health=0,currentFollowers=0,assignedFollowers=10,isolation=true,isolated=true,overwhelmed=true},function()return 0 end)
assert(deserts and score>=0.78 and chance>0)
print("Project Nightfall Alpha Feral qualification/hierarchy checks passed")
