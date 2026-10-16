local now=0
getGameTime=function() return {getWorldAgeHours=function() return now/60 end} end
local tick
Events={OnTick={Add=function(fn) tick=fn end}}
local complete=true
PNTestUVInspect=function() return {complete=complete,occlusionChecked=true,
    regions={head={incidentNatural=2,incidentArtificial=1,tissueIrradiance=.5}}} end
dofile("src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVExposureMeter.lua")
assert(PNTestUVDayStart({}))
assert(not PNTestUVDayStart({}))
now=1;tick()
local report=PNTestUVDayReport()
assert(report.covered==1 and report.regions.head.tissue==.5)
complete=false;now=2;tick()
assert(report.skipped==1 and report.regions.head.tissue==.5)
complete=true;now=20;tick()
assert(report.skipped==19,"long unsampled gaps cannot be fabricated as continuous exposure")
now=21;tick()
assert(report.covered==2 and report.regions.head.incident==6)
now=1441;tick()
assert(not report.running and not report.zombie)
isClient=function() return true end
assert(not PNTestUVDayStart({}))
print("Nightfall read-only daily UV meter interval/gap/stop guards passed")
