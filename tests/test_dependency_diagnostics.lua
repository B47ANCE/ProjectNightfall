ProjectNightfall=nil
local diagnostics=dofile(assert(arg[1]))
ProjectNightfall.VERSION="0.31.0-dev.4"
local lightworks={VERSION="0.20.0",registerBulb=function() end,UV={getSunlightExposure=function() end,getArtificialExposure=function() end}}
local powerworks={VERSION="0.9.1",registerLoad=function() end}
local mortis={VERSION="0.21.1",API_VERSION="1.6.0",FoodSources={TRANSACTION_VERSION=1},getTypeId=function() end,Authority={canWriteCanonicalState=function() end},ZombieHunger={getStarvationHours=function() end,getDrive=function() end}}
mortis.negotiateAPI=function(request)
    assert(request.consumer=="ProjectNightfall" and request.minimum=="1.6.0" and request.maximumExclusive=="2.0.0")
    assert(request.required["FoodSources.TRANSACTION_VERSION"]=="number")
    assert(request.required["Anatomy.applyNutritionProfile"]=="function")
    assert(request.required["LocomotionOverrides.releaseCeiling"]=="function")
    return true,{compatible=true}
end
local medworks={VERSION="0.7.0",getDetachedPartProvenance=function() end,performProcedure=function() end}
local experienceworks={VERSION="0.5.0",registerDocument=function() end,registerKnowledge=function() end,
    hasKnowledgeDefinition=function() end,hasKnowledge=function() end}
local ok,missing,versions=diagnostics.inspect(lightworks,powerworks,mortis,medworks,experienceworks)
assert(ok and #missing==0)
assert(versions.ProjectNightfall=="0.31.0-dev.4" and versions.ProjectMORTIS=="0.21.1")
assert(versions.MortisAPI=="1.6.0" and versions.lightWorks=="0.20.0")
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

-- Real guarded dependency; inspect never calls research/storage mutation APIs.
local Guard=require 'B47ANCEDKnowledgeAndWisdom/AuthorityGuard'
local function inspect()return diagnostics.inspect(lightworks,powerworks,mortis,medworks,experienceworks,Guard)end
isServer=function()return true end;isClient=function()return false end
local present,_,_,readiness=inspect()
assert(present and readiness.status=='BLOCKED' and readiness.knowledgeStorage=='BLOCKED')
assert(readiness.issues[1]=='MULTIPLAYER_STORAGE_UNAVAILABLE')
local originalPrint=print;local lines={}
print=function(line)lines[#lines+1]=line end
local reportedSurface,_,_,reportedScope=diagnostics.report(lightworks,powerworks,mortis,medworks,experienceworks)
print=originalPrint
assert(reportedSurface and reportedScope.status=='BLOCKED')
assert(table.concat(lines,'\n'):find('MULTIPLAYER_STORAGE_UNAVAILABLE',1,true))
assert(table.concat(lines,'\n'):find('native/dedicated NOT TESTED',1,true))
isServer=function()return false end;isClient=function()return true end
local _,_,_,client=inspect();assert(client.status=='BLOCKED')
isClient=function()return false end
local _,_,_,sp=inspect();assert(sp.status=='SOURCE_CAPABILITIES_AVAILABLE' and sp.foodTransactions=='v1')
isServer=nil
local _,_,_,unknown=inspect();assert(unknown.status=='UNKNOWN')
mortis.FoodSources.TRANSACTION_VERSION=2
local surface,missingFood,_,badFood=inspect()
assert(not surface and badFood.status=='BLOCKED' and table.concat(missingFood,','):find('transaction v1',1,true))
mortis.FoodSources.TRANSACTION_VERSION=1
local _,_,_,missingGuard=diagnostics.inspect(lightworks,powerworks,mortis,medworks,experienceworks,{})
assert(missingGuard.status=='UNKNOWN')
