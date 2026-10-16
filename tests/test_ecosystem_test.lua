local order={}
PNTestKit=function(force) order[#order+1]="nightfall-kit:"..tostring(force) end
PNTestStatus=function() order[#order+1]="nightfall-status" end
MORTISInspect=function() order[#order+1]="mortis-inspect" end
itjustWorksTestStart=function(grant,reset) order[#order+1]="ijw:"..tostring(grant)..":"..tostring(reset); return true end
itjustWorksOnTestComplete=function(callback) order[#order+1]="ijw-hook"; _G.finishIJW=callback; return true end
PNTestStart=function(reset) order[#order+1]="nightfall-guided:"..tostring(reset); return true end
LWOnTestTourComplete=function(callback) order[#order+1]="lightworks-hook"; _G.finishTour=callback; return true end
LWStartReleaseSuite=function() order[#order+1]="lightworks-suite"; return true end

dofile(arg[1])
assert(theWorksMassTest(true)==true)
assert(order[1]=="nightfall-kit:true" and order[2]=="nightfall-status" and order[3]=="mortis-inspect")
assert(order[4]=="lightworks-hook" and order[5]=="lightworks-suite")
assert(not order[6],"itjustWorks must wait for the visual tour")
finishTour()
assert(order[6]=="ijw-hook" and order[7]=="ijw:true:true","itjustWorks should start after lightWorks completes")
assert(not order[8],"Nightfall must wait for itjustWorks completion")
finishIJW()
assert(order[8]=="nightfall-guided:true","Nightfall should start after itjustWorks completes")

order={}
assert(PNReleaseTest(false)==true)
assert(order[1]=="nightfall-kit:false" and order[2]=="nightfall-status" and order[3]=="mortis-inspect")
assert(order[4]=="lightworks-hook" and order[5]=="lightworks-suite")
assert(not order[6],"Nightfall release runner must wait for the lightWorks visual tour")
finishTour()
assert(order[6]=="nightfall-guided:false","Nightfall must follow lightWorks directly")
for _,entry in ipairs(order) do assert(not entry:match("^ijw:"),"Nightfall release runner must exclude optional itjustWorks") end
print("Project Nightfall ecosystem test-orchestrator checks passed")
