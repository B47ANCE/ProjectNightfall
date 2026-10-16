local data={}
local written={}
getFileWriter=function(name,create,append)
    assert(name=="theWorks Test Results - ProjectNightfall.txt" and create==true and append==false)
    written={}; return {writeln=function(_,line) written[#written+1]=line end,close=function() end}
end
local p={getModData=function() return data end}
getSpecificPlayer=function() return p end
local guided=dofile(assert(arg[1]))
assert(PNTestStart(true)==true)
assert(PNTestPass("ok")==true)
assert(PNTestFail("issue")==true)
assert(PNTestSkip("not available")==true)
local ok,counts=PNTestReport()
assert(ok and counts.PASS==1 and counts.FAIL==1 and counts.SKIP==1 and counts.PENDING==12)
assert(PNTestStart(false)==true,"session must resume")
assert(PNTestStart(true)==true,"session must reset")
local _,reset=PNTestReport()
assert(reset.PENDING==15)
assert(PNTestWhere()=="theWorks Test Results - ProjectNightfall.txt")
assert(table.concat(written,"\n"):find("Mod ID: ProjectNightfall",1,true))
print("Project Nightfall guided test checks passed")
