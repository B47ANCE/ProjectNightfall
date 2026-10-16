local authority=true
local server=true
package.loaded["Mortis/Runtime/Authority"]={canWriteCanonicalState=function() return authority end,
    isDedicatedServerRuntime=function() return server end}
local data={PN_UVTissue={schemaVersion=2,regions={head={naturalScore=2,artificialScore=0,woundStage=0}},
    lastMinute=2,syncPending=true}}
local sends,fail=0,true
package.loaded["Mortis/Runtime/Adapters/EntityAdapter"]={getModData=function() return data end,
    transmitModData=function() sends=sends+1;if fail then return false,"network unavailable" end;return true end}
package.loaded["Mortis/Runtime/TraumaRuntime"]={promote=function() error("no wound expected") end}
package.loaded["Mortis/Runtime/AnatomyRuntime"]={getRegion=function(_,id) return {},{},id end}
package.loaded["Mortis/Core/Util"]={deepCopy=function(value)
    if type(value)~="table" then return value end local result={} for k,v in pairs(value) do result[k]=package.loaded["Mortis/Core/Util"].deepCopy(v) end return result
end}
package.loaded["ProjectNightfall/PN_RegionalUVDose"]={propose=function() error("no dose expected") end}
local Tissue=require "ProjectNightfall/PN_UVTissueState"
local ok,result=Tissue.recover({})
assert(not ok and sends==1 and data.PN_UVTissue.syncPending,"failed send must retain durable retry marker")
fail=false
ok,result=Tissue.recover({})
assert(ok and sends==2 and result.synchronized and not data.PN_UVTissue.syncPending)
assert(Tissue.recover({}) and sends==2,"completed synchronization must not resend every update")
server=false;data.PN_UVTissue.syncPending=true
assert(Tissue.recover({}) and sends==2,"single-player/client read path must not transmit")
print("Nightfall authoritative UV tissue synchronization retry checks passed")
