ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.LifecycleRules=ProjectNightfall.LifecycleRules or {}
local Rules=ProjectNightfall.LifecycleRules

function Rules.canBeginSunHibernation(globalDLS,exposedDLS,pointRate,config)
    config=config or {}
    globalDLS=tonumber(globalDLS) or 0
    exposedDLS=tonumber(exposedDLS) or 0
    pointRate=tonumber(pointRate) or 0
    local minimumGlobal=tonumber(config.FeralDayDormancyMinDLS) or 0.05
    -- A positive local rate is the authoritative indication that this square
    -- is currently accumulating solar UV. Health left at the daytime floor is
    -- never sufficient by itself to start hibernation after nightfall.
    return globalDLS>=minimumGlobal and exposedDLS>0 and pointRate>0
end

function Rules.risesAsFeral(feralsEnabled, eligibleAtKnockdown)
    return feralsEnabled ~= false and eligibleAtKnockdown == true
end

return Rules
