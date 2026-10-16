-- Native boundaries are mocked; the real corpse runtime owns all scheduling.
local function emitter(x,range)
    return {x=x,y=0,z=0,range=range or 0,owner={}}
end
local function body()
    return {data={PN_UVCorpse={schemaVersion=1,infected=true,deathMinute=1}}}
end
local function fixture()
    local f={now=10,emitters={emitter(0)},bodies={body()},calls={},stageCalls=0,reads=0,
        authority=true,positions={}}
    f.config={Enabled=true,EnableRegionalUVTissue=true,
        ArtificialUVCorpseSquareBudgetPerUpdate=16,ArtificialUVCorpseProcessBudgetPerUpdate=1,
        ArtificialUVCorpseCandidateLimit=16,ArtificialUVCorpseMaximumScanSquares=64,
        RegionalUVTissueMaximumElapsedMinutes=5,RegionalUVTissuePolicyRevision=2,
        RegionalUVTissuePolicy={default={},regions={}},UVCorpseDestructionStageThresholds={.1,.35,.65,.9}}
    getGameTime=function() return {getWorldAgeHours=function() return f.now/60 end} end
    Events=nil
    package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return f.authority end}
    package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function(e) return e.data end}
    package.loaded["Mortis/Runtime/AnatomyRuntime"]={
        get=function() f.reads=f.reads+1;return {speciesId="test"} end,
        tissueSnapshot=function() return {} end,flush=function() return true end}
    package.loaded["ProjectNightfall/PN_UVTissueState"]={snapshot=function() return {} end}
    package.loaded["ProjectNightfall/PN_UVRemainsState"]={update=function()
        f.stageCalls=f.stageCalls+1
        if f.stageFailure then return false,"stage rejected" end
        return true,{changed=false}
    end}
    package.loaded["Mortis/Runtime/Adapters/CorpseAdapter"]={onSquare=function(square)
        return square and f.bodies or {}
    end}
    package.loaded["ProjectNightfall/PN_UVTissueScheduler"]={process=function(target,_,elapsed,finish)
        f.calls[#f.calls+1]={target=target,elapsed=elapsed,finish=finish}
        if f.pipeline then return f.pipeline(target,elapsed,finish) end
        return true,{lastMinute=finish}
    end}
    ProjectNightfall={Config={POC=f.config},ArtificialUV={getCurrentEmitters=function(target)
        if target and target.dark then return {} end
        return f.emitters
    end}}
    package.loaded["ProjectNightfall/PN_Config"]=true
    package.loaded["ProjectNightfall/PN_UVCorpseRuntime"]=nil
    f.runtime=require "ProjectNightfall/PN_UVCorpseRuntime"
    f.cell={getGridSquare=function(_,x,y,z)
        f.positions[#f.positions+1]={x=x,y=y,z=z}
        return {}
    end}
    function f:update() return self.runtime.update({cell=self.cell}) end
    return f
end

for _,flag in ipairs({"Enabled","EnableRegionalUVTissue"}) do
    local f=fixture()
    assert(f:update());f.now=11;assert(f:update())
    assert(#f.calls==1 and f.bodies[1].data.PN_UVCorpse.lastProcessMinute==11)
    f.config[flag]=false
    getGameTime=function() error("disabled runtime must not query world time") end
    assert(f:update())
    local unmarked={data={}}
    assert(f.runtime.markDeath(unmarked))
    assert(f.reads==0 and unmarked.data.PN_UVCorpse==nil,"disabled death must neither read anatomy nor create a marker")
    assert(#f.calls==1 and f.runtime.getDiagnostics().lastCandidates==0)
    f.now=100
    getGameTime=function() return {getWorldAgeHours=function() return f.now/60 end} end
    f.config[flag]=true
    assert(f:update() and #f.calls==1,"reenabling must discover at now without disabled-time backfill")
    f.now=101;assert(f:update())
    assert(#f.calls==2 and f.calls[2].elapsed==1)
end

do
    local f=fixture()
    f.bodies={}
    f.config.ArtificialUVCorpseSquareBudgetPerUpdate=1
    f.emitters={emitter(0,14),emitter(100,14)}
    assert(f:update())
    -- The provider returns fresh descriptor copies with the same stable owners.
    local owner=f.emitters[1].owner
    f.emitters={{x=200,y=0,z=1,range=14,owner=owner},f.emitters[2]}
    local initial=#f.positions
    for _=1,20 do assert(f:update()) end
    for index=initial+1,#f.positions do
        local point=f.positions[index]
        assert(point.x>50,"queued offsets must follow a moved source instead of scanning its old location")
    end
    f.emitters={f.emitters[2]}
    initial=#f.positions
    for _=1,20 do assert(f:update()) end
    for index=initial+1,#f.positions do
        assert(f.positions[index].x<150,"removed source must not keep scanning queued positions")
    end
end

do
    local f=fixture()
    f.bodies={};f.emitters={}
    f.config.ArtificialUVCorpseSquareBudgetPerUpdate=8
    for index=1,100 do f.emitters[index]=emitter(index*10) end
    local reached=false
    for _=1,40 do
        local before=#f.positions
        assert(f:update())
        assert(#f.positions-before<=8 and f.runtime.getDiagnostics().lastScanQueued<=64)
        for index=before+1,#f.positions do if f.positions[index].x==1000 then reached=true end end
        -- Reorder a stable emitter set while chunks are still being drained.
        local first=table.remove(f.emitters,1);f.emitters[#f.emitters+1]=first
    end
    assert(reached,"source-list reordering and a full scan chunk must not starve later emitters")
end

do
    local f=fixture()
    f.bodies={};f.emitters={emitter(0,14)}
    assert(f:update())
    f.emitters[1].x=500;f.emitters[1].range=0
    local before=#f.positions
    for _=1,80 do assert(f:update()) end
    assert(#f.positions>before,"changed ranges must eventually discover their new footprint")
    for index=before+1,#f.positions do
        assert(f.positions[index].x==500 and f.positions[index].y==0,
            "queued offsets outside a shrunken source range must be skipped")
    end
end

do
    local f=fixture()
    f.bodies={}
    for index=1,50 do f.bodies[index]=body() end
    f.config.ArtificialUVCorpseProcessBudgetPerUpdate=2
    for tick=1,20 do
        f.now=10+tick
        local before=#f.calls
        assert(f:update())
        assert(#f.calls-before<=2 and f.runtime.getDiagnostics().lastCandidates<=16,
            "candidate saturation must preserve process and storage bounds")
    end
    local processed={}
    for _,call in ipairs(f.calls) do processed[call.target]=true end
    for index=1,16 do assert(processed[f.bodies[index]],"admitted candidates require fair process rotation") end
end

do
    local f=fixture()
    f.bodies={body(),body()}
    assert(f:update());f.now=11
    local failing=f.bodies[2]
    f.pipeline=function(target,_,finish)
        if target==failing then return false,"injected failure" end
        return true,{lastMinute=finish}
    end
    local ok,reason=f:update()
    assert(not ok and reason=="injected failure")
    assert(failing.data.PN_UVCorpse.lastProcessMinute==10,"rejection cannot advance the corpse clock")
    assert(f.runtime.getDiagnostics().lastProcessed==0 and f.runtime.getDiagnostics().failures==1)
    assert(f:update(),"one rejected candidate must not block the next one")
    f.pipeline=nil;f.now=12;assert(f:update())
    assert(f.calls[#f.calls].target==failing and f.calls[#f.calls].elapsed==2)
end

do
    local f=fixture()
    assert(f:update());f.now=11
    f.pipeline=function() error("pipeline exception") end
    local ok,reason=f:update()
    assert(not ok and tostring(reason):find("pipeline exception",1,true))
    assert(f.runtime.getDiagnostics().failures==1 and f.runtime.getDiagnostics().lastProcessed==0)
end

do
    local f=fixture()
    f.config.ArtificialUVCorpseProcessBudgetPerUpdate=2
    f.bodies={body(),body()}
    assert(f:update());f.now=11
    f.pipeline=function(target,_,finish)
        if target==f.bodies[2] then return false,"second corpse rejected" end
        return true,{lastMinute=finish}
    end
    assert(not f:update())
    local report=f.runtime.getDiagnostics()
    assert(report.lastProcessed==1 and report.totalCorpsesProcessed==3,
        "diagnostics must retain successful work preceding a rejection and exclude the rejection itself")
end

do
    local f=fixture()
    assert(f:update());f.now=12
    f.pipeline=function() return true,{lastMinute=11} end -- completes an older journal
    assert(f:update())
    assert(f.bodies[1].data.PN_UVCorpse.lastProcessMinute==11,"journal recovery must not skip uncommitted time")
    f.pipeline=nil;assert(f:update())
    assert(f.calls[2].elapsed==1 and f.calls[2].finish==12)
end

do
    local f=fixture()
    assert(f:update());f.now=11;f.stageFailure=true
    assert(not f:update())
    assert(f.bodies[1].data.PN_UVCorpse.lastProcessMinute==11 and #f.calls==1)
    f.stageFailure=false
    assert(f:update() and #f.calls==1,"retry a failed remains stage at the same minute without replaying dose")
    assert(f.stageCalls==2)
end

do
    local f=fixture()
    f.authority=false
    assert(not f:update() and not f.runtime.markDeath({data={}}))
    assert(#f.positions==0 and #f.calls==0 and f.reads==0,"clients must not discover, mark, or apply corpse dose")
end
print("Nightfall corpse disable/re-enable, moving emitters, budgets and retry regressions passed")
