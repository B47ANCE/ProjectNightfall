-- Audit reproducers: assert the intended behavior, not the observed defect.
-- Kept at the original audit path as live regressions for the 0.27.4 fixes.
local failures={}
local function scenario(name,fn)
    local ok,reason=pcall(fn)
    print((ok and "PASS " or "FAIL ")..name..(ok and "" or ": "..tostring(reason)))
    if not ok then failures[#failures+1]=name end
end

local function fixture(emitters,budget,maximum)
    local now=10
    getGameTime=function() return {getWorldAgeHours=function() return now/60 end} end
    Events=nil
    package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return true end}
    package.loaded["Mortis/Runtime/AnatomyRuntime"]={}
    package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function(e) return e.data end}
    package.loaded["ProjectNightfall/PN_UVTissueState"]={}
    package.loaded["ProjectNightfall/PN_UVRemainsState"]={update=function() return true,{} end}
    local corpse={data={PN_UVCorpse={schemaVersion=1,infected=true}}}
    local square={getStaticMovingObjects=function() return {corpse} end}
    package.loaded["Mortis/Runtime/Adapters/CorpseAdapter"]={isCorpse=function() return true end,onSquare=function(s)
        return s==square and {corpse} or {}
    end}
    local calls=0
    local fail=false
    package.loaded["ProjectNightfall/PN_UVTissueScheduler"]={process=function()
        calls=calls+1
        return not fail,fail and "injected pipeline failure" or {}
    end}
    local config={Enabled=true,EnableRegionalUVTissue=true,
        ArtificialUVCorpseSquareBudgetPerUpdate=budget,
        ArtificialUVCorpseProcessBudgetPerUpdate=8,ArtificialUVCorpseCandidateLimit=256,
        ArtificialUVCorpseMaximumScanSquares=maximum,RegionalUVTissueMaximumElapsedMinutes=5,
        RegionalUVTissuePolicyRevision=2,RegionalUVTissuePolicy={default={},regions={}},
        UVCorpseDestructionStageThresholds={.1,.35,.65,.9}}
    ProjectNightfall={Config={POC=config},ArtificialUV={getCurrentEmitters=function() return emitters end}}
    package.loaded["ProjectNightfall/PN_Config"]=true
    package.loaded["ProjectNightfall/PN_CorpseDiscovery"]=nil
    package.loaded["ProjectNightfall/PN_UVCorpseRuntime"]=nil
    local runtime=require "ProjectNightfall/PN_UVCorpseRuntime"
    return {runtime=runtime,config=config,square=square,
        advance=function() now=now+1 end,calls=function() return calls end,
        fail=function() fail=true end}
end

local function emitter(x,range)
    return {x=x,y=0,z=0,range=range,owner={getX=function() return x end,
        getY=function() return 0 end,getZ=function() return 0 end}}
end

scenario("60-update reset must not starve later scan tiles",function()
    local f=fixture({emitter(0,14),emitter(100,14)},16,4096)
    local reached=false
    local cell={getGridSquare=function(_,x,y) if x==114 and y==0 then reached=true end end}
    for _=1,300 do assert(f.runtime.update({cell=cell}));f.advance() end
    assert(reached,"second emitter's last tile was never visited in 300 updates")
end)

scenario("scan cap must rotate fairly across emitters",function()
    local emitters={};for i=0,7 do emitters[#emitters+1]=emitter(i*100,14) end
    local f=fixture(emitters,256,4096)
    local reached=false
    local cell={getGridSquare=function(_,x,y) if x==714 and y==0 then reached=true end end}
    for _=1,300 do assert(f.runtime.update({cell=cell}));f.advance() end
    assert(reached,"last emitter's tile was never visited in 300 updates")
end)

for _,flag in ipairs({"Enabled","EnableRegionalUVTissue"}) do
    scenario(flag.."=false must suppress corpse tissue processing",function()
        local f=fixture({emitter(0,0)},16,4096)
        f.config[flag]=false
        local cell={getGridSquare=function() return f.square end}
        assert(f.runtime.update({cell=cell}));f.advance()
        assert(f.runtime.update({cell=cell}))
        assert(f.calls()==0,"corpse tissue scheduler was called while disabled")
    end)
end

scenario("pipeline failure must be observable as a failure",function()
    local f=fixture({emitter(0,0)},16,4096)
    local cell={getGridSquare=function() return f.square end}
    assert(f.runtime.update({cell=cell}));f.advance();f.fail()
    local ok=f.runtime.update({cell=cell})
    assert(not ok and f.runtime.getDiagnostics().failures>0,
        "update returned success and diagnostics did not count the rejected pipeline call")
end)

assert(#failures==0,tostring(#failures).." corpse-runtime audit cases failed")
