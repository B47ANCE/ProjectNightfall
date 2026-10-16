local path=assert(arg[1],"PN_ZombieUV.lua path required")
local file=assert(io.open(path,"rb"))
local source=file:read("*a"); file:close()
local start=assert(source:find("local function riseAtNight",1,true))
local finish=assert(source:find("local function maintainTransformingState",start,true))
local body=source:sub(start,finish-1)
local completion={
    "s.hibernationDisturbed=false",
    "stats.rises=stats.rises+1",
    "maybePromoteSmartFeral",
    "NIGHT RISE",
}
local identityGate=assert(body:find("commitRiseIdentity",1,true))
local standGate=assert(body:find("requestRise",identityGate,true))
assert(not body:find("setCrawler(false)",1,true),"rise must preserve anatomy-selected crawler mode")
assert(not body:find("setCanWalk(true)",1,true),"rise must not overwrite anatomy walking restriction")
local phaseCommit=assert(body:find('s.phase=feralsEnabled and "FERAL" or "NORMAL"',standGate,true))
assert(identityGate<standGate and standGate<phaseCommit,
    "identity and stand gates must precede Nightfall phase commit")
assert(body:find("rollbackRiseIdentity",standGate,true)<phaseCommit,
    "stand failure must attempt identity rollback before phase commit")
local last=0
for _,token in ipairs(completion) do
    local at=assert(body:find(token,last+1,true),"missing/out-of-order rise completion token: "..token)
    assert(at>last,"rise completion ordering changed")
    last=at
end
local finalReturn=assert(body:find("return true",last+1,true),"successful rise must return only after completion work")
local dayCleared=assert(body:find("s.dayDormant=false",1,true))
assert(body:find("return true",dayCleared,true)==finalReturn,
    "rise completion tail must remain reachable")
-- Run the production shelter functions with injected boundaries. This catches
-- lifecycle behavior that source-token assertions alone cannot establish.
local shelterStart=assert(source:find("local function releaseShelterWalking",1,true))
local shelterEnd=assert(source:find("local function applyWeightAction",shelterStart,true))
local shelterSource=source:sub(shelterStart,shelterEnd-1).."\nreturn releaseShelterWalking,updateShelterHold"
local failRestore=true
local needsCrawler=false
local writes={}
local now=10
local env=setmetatable({
    MortisIntegration={
        requiresCrawler=function() return needsCrawler end,
        enforceActiveAnatomy=function(_,state)
            state.anatomyWalkingBeforeRestriction=state.walkingBeforeLifecycleHold
            state.anatomyCrawlerRestricted=true
            return true
        end,
        restoreWalkingPermission=function(_,value)
            if failRestore then return false end
            writes[#writes+1]=value;return true
        end,
    },
    worldAgeHours=function() return now end,
    stats={shelterHoldEnds=0},Config={},tick=0,
    safe=function(_,fn,...) local ok,value=pcall(fn,...);if ok then return value end;return false end,
}, {__index=_G})
local compiled
if setfenv then compiled=assert(loadstring(shelterSource));setfenv(compiled,env)
else compiled=assert(load(shelterSource,"shelter-runtime","t",env)) end
local release,update=compiled()
local zombie={isTargetVisible=function() return false end,getTarget=function() return nil end,
    setCanWalk=function(_,value) writes[#writes+1]=value end}
local state={shelterHoldActive=true,shelterHoldUntilHours=9,walkingBeforeLifecycleHold=true}
now=nil
assert(update(zombie,state)==true and state.shelterHoldActive and #writes==0)
assert(state.shelterHoldUntilHours==9 and state.walkingBeforeLifecycleHold==true)
now=10
assert(update(zombie,state)==false)
assert(not state.shelterHoldActive and state.walkingBeforeLifecycleHold==true and #writes==0)
failRestore=false
assert(update(zombie,state)==false and writes[1]==true and state.walkingBeforeLifecycleHold==nil)
assert(env.stats.shelterHoldEnds==1,"retry must not count another hold ending")
state={shelterHoldActive=true,shelterHoldUntilHours=20,walkingBeforeLifecycleHold=false}
assert(release(zombie,state) and writes[#writes]==false)
assert(state.walkingBeforeLifecycleHold==false,"temporary prey release must retain baseline")
needsCrawler=true
state.shelterHoldActive=false;state.walkingBeforeLifecycleHold=true
local before=#writes
assert(release(zombie,state) and #writes==before)
assert(state.anatomyWalkingBeforeRestriction==true and state.walkingBeforeLifecycleHold==nil)
needsCrawler=nil
assert(not release(zombie,{walkingBeforeLifecycleHold=true}) and #writes==before)
print("Project Nightfall rise contract and executable shelter-release checks passed")
