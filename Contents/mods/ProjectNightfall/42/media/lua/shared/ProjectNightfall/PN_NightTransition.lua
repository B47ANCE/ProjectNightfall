ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.NightTransition=ProjectNightfall.NightTransition or {}

local Transition=ProjectNightfall.NightTransition

function Transition.epoch(worldHours)
    worldHours=tonumber(worldHours)
    if not worldHours or worldHours~=worldHours then return nil end
    -- Noon-to-noon keeps one key across an evening, midnight, and following dawn.
    return math.floor((worldHours-12)/24)
end

function Transition.isNight(nightStrength,threshold)
    return (tonumber(nightStrength) or -1)>=(tonumber(threshold) or 0.60)
end

local function usableOutside(square)
    if not square then return false end
    local okOutside,outside=pcall(function() return square:isOutside() end)
    if not okOutside or outside~=true then return false end
    local okSolid,solid=pcall(function() return square:isSolid() end)
    return not okSolid or solid~=true
end

-- Eight radial probes per distance keep this lookup O(radius), rather than
-- examining every square in an expanding area for every relevant zombie.
function Transition.findOutdoorSquare(cell,zombie,radius)
    if not cell or not zombie then return nil end
    local ok,x,y,z=pcall(function()
        return math.floor(zombie:getX()),math.floor(zombie:getY()),math.floor(zombie:getZ())
    end)
    if not ok then return nil end
    radius=math.max(1,math.floor(tonumber(radius) or 12))
    local directions={{1,0},{-1,0},{0,1},{0,-1},{1,1},{1,-1},{-1,1},{-1,-1}}
    for distance=1,radius do
        for _,direction in ipairs(directions) do
            local got,square=pcall(function()
                return cell:getGridSquare(x+direction[1]*distance,y+direction[2]*distance,z)
            end)
            if got and usableOutside(square) then return square end
        end
    end
    return nil
end

function Transition.requestIndoorExit(zombie,state,context)
    context=context or {}
    if not zombie or type(state)~="table" or context.enabled==false then return false,"disabled" end
    if not Transition.isNight(context.nightStrength,context.threshold) then return false,"not-night" end
    local epoch=Transition.epoch(context.worldHours)
    if epoch==nil then return false,"time-unavailable" end
    if state.nightExitEpoch==epoch then return false,"already-requested" end
    if (tonumber(state.nightExitNextTick) or -1)>(tonumber(context.tick) or 0) then return false,"cooldown" end
    local okSquare,current=pcall(function() return zombie:getSquare() end)
    if not okSquare or not current then return false,"square-unavailable" end
    local okOutside,outside=pcall(function() return current:isOutside() end)
    if not okOutside then return false,"outside-state-unavailable" end
    if outside==true then state.nightExitEpoch=epoch; return false,"already-outside" end
    local target=Transition.findOutdoorSquare(context.cell,zombie,context.radius)
    if not target then
        state.nightExitNextTick=(tonumber(context.tick) or 0)+math.max(30,tonumber(context.retryTicks) or 300)
        return false,"no-loaded-outdoor-square"
    end
    local moved=pcall(function()
        zombie:pathToLocationF(target:getX()+0.5,target:getY()+0.5,target:getZ())
    end)
    if not moved then
        state.nightExitNextTick=(tonumber(context.tick) or 0)+math.max(30,tonumber(context.retryTicks) or 300)
        return false,"path-request-failed"
    end
    state.nightExitEpoch=epoch
    state.nightExitNextTick=nil
    return true,target
end

return Transition
