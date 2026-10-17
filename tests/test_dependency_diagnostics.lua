ProjectNightfall=nil
local diagnostics=dofile(assert(arg[1]))
ProjectNightfall.VERSION="0.30.0"
local lightworks={VERSION="0.20.0",registerBulb=function() end,UV={getSunlightExposure=function() end,getArtificialExposure=function() end}}
local powerworks={VERSION="0.9.1",registerLoad=function() end}
local mortis={VERSION="0.21.1",API_VERSION="1.4.0",getTypeId=function() end,Authority={canWriteCanonicalState=function() end},ZombieHunger={getStarvationHours=function() end,getDrive=function() end}}
mortis.negotiateAPI=function(request)
    assert(request.consumer=="ProjectNightfall" and request.minimum=="1.3.0" and request.maximumExclusive=="2.0.0")
    return true,{compatible=true}
end
local medworks={VERSION="0.7.0",getDetachedPartProvenance=function() end,performProcedure=function() end}
local experienceworks={VERSION="0.5.0",registerDocument=function() end,registerKnowledge=function() end,
    hasKnowledgeDefinition=function() end,hasKnowledge=function() end}
local ok,missing,versions=diagnostics.inspect(lightworks,powerworks,mortis,medworks,experienceworks)
assert(ok and #missing==0)
assert(versions.ProjectNightfall=="0.30.0" and versions.ProjectMORTIS=="0.21.1")
assert(versions.MortisAPI=="1.4.0" and versions.lightWorks=="0.20.0")
local reportOk,reportMissing,reported=diagnostics.report(lightworks,powerworks,mortis,medworks,experienceworks)
assert(reportOk and #reportMissing==0 and reported.medWorks=="0.7.0")
ok,missing=diagnostics.inspect({UV={}},powerworks,mortis,medworks,experienceworks)
assert(not ok and #missing==3)
assert(table.concat(missing,","):find("lightWorks.registerBulb",1,true))
local incompatible={getTypeId=mortis.getTypeId,Authority=mortis.Authority,ZombieHunger=mortis.ZombieHunger,
    negotiateAPI=function() return false,{compatible=false} end}
ok,missing=diagnostics.inspect(lightworks,powerworks,incompatible,medworks,experienceworks)
assert(not ok and table.concat(missing,","):find("API version/surface incompatible",1,true))
print("Project Nightfall dependency diagnostic checks passed")
