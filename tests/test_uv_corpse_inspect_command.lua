local marked={data={PN_UVCorpse={schemaVersion=1,infected=true,deathMinute=5,lastProcessMinute=10,speciesId="test"}}}
local ordinary={data={}}
local playerSquare={getX=function() return 10 end,getY=function() return 20 end,getZ=function() return 0 end}
local corpseSquare={}
getPlayer=function() return {getCurrentSquare=function() return playerSquare end} end
getCell=function() return {getGridSquare=function(_,x,y,z) return x==11 and y==20 and z==0 and corpseSquare or nil end} end
getGameTime=function() return {getWorldAgeHours=function() return 1 end} end
package.loaded["Mortis/Runtime/Adapters/CorpseAdapter"]={isCorpse=function(value) return value==marked or value==ordinary end,
    onSquare=function(square) return square==corpseSquare and {ordinary,marked} or {} end}
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function(value) return value.data end}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={get=function(value) assert(value==marked);return {speciesId="test",regions={head={}}} end}
local compiled={regions={head={}}}
package.loaded["ProjectNightfall/PN_UVTissuePolicy"]={compile=function(_,source) assert(source.marker);return compiled end}
ProjectNightfall={Config={POC={RegionalUVTissuePolicy={marker=true}}},ArtificialUV={getCurrentEmitters=function(value)
    assert(value==marked);return {{owner={}}}
end}}
package.loaded["ProjectNightfall/PN_Config"]=true
package.loaded["lightWorks/lightWorks_UV"]={getVerifiedExposure=function(value,emitters,context)
    assert(value==marked and #emitters==1 and context.cell);return {uv={complete=true,occlusionChecked=true,natural=0,artificial=1}}
end}
local inspected=0
package.loaded["ProjectNightfall/PN_UVDiagnostics"]={inspect=function(value,exposure,policy,now,lifecycle)
    inspected=inspected+1;assert(value==marked and exposure.uv.artificial==1 and policy==compiled and now==60 and lifecycle=="corpse")
    return {regions={},layers={}}
end,lines=function() return {"corpse"} end}
package.loaded["ProjectNightfall/PN_UVRemainsState"]={inspect=function(value) assert(value==marked);return {stage="SCORCHED"} end}
dofile("src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVInspect.lua")
local report=assert(PNTestUVCorpseInspect(nil,12,true))
assert(inspected==1 and report.remains.stage=="SCORCHED" and report.marker.deathMinute==5)
assert(not PNTestUVCorpseInspect(ordinary,12,true))
isClient=function() return true end
assert(not PNTestUVCorpseInspect(marked,12,true) and inspected==1)
print("Nightfall bounded read-only marked-corpse inspection command checks passed")
