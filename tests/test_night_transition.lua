local Transition=dofile(arg[1])

assert(Transition.epoch(21)==Transition.epoch(27),"one night must retain one transition epoch across midnight")
assert(Transition.epoch(35)~=Transition.epoch(37),"the next noon boundary must advance the epoch")
assert(Transition.isNight(0.6,0.6) and not Transition.isNight(0.59,0.6))

local squares={}
local function square(x,y,outside,solid)
    local value={x=x,y=y,outside=outside,solid=solid}
    function value:isOutside() return self.outside end
    function value:isSolid() return self.solid end
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getZ() return 0 end
    squares[x..":"..y]=value
    return value
end
local inside=square(0,0,false,false)
local outside=square(3,0,true,false)
local cell={getGridSquare=function(_,x,y) return squares[x..":"..y] end}
local paths=0
local zombie={
    getX=function() return 0 end,getY=function() return 0 end,getZ=function() return 0 end,
    getSquare=function() return inside end,
    pathToLocationF=function(_,x,y,z)
        paths=paths+1
        assert(x==outside:getX()+0.5 and y==outside:getY()+0.5 and z==0)
    end,
}
local state={}
local context={enabled=true,nightStrength=0.8,threshold=0.6,worldHours=22,tick=100,
    cell=cell,radius=6,retryTicks=300}
local moved,target=Transition.requestIndoorExit(zombie,state,context)
assert(moved and target==outside and paths==1,"an indoor relevant zombie must receive one outdoor path request")
assert(not Transition.requestIndoorExit(zombie,state,context) and paths==1,"the same night must not issue repeated paths")
context.worldHours=46
assert(Transition.requestIndoorExit(zombie,state,context) and paths==2,"a later night may issue a new path request")

local noTargetState={}
context.cell={getGridSquare=function() return nil end}
context.worldHours=70
context.tick=200
local ok,reason=Transition.requestIndoorExit(zombie,noTargetState,context)
assert(not ok and reason=="no-loaded-outdoor-square" and noTargetState.nightExitNextTick==500)
context.tick=300
local retry,retryReason=Transition.requestIndoorExit(zombie,noTargetState,context)
assert(not retry and retryReason=="cooldown")

print("Project Nightfall bounded night-transition checks passed")
