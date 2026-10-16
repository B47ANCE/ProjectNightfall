local modulePath = assert(arg[1])
ProjectNightfall = nil
local Persistence = dofile(modulePath)

local root = { unrelated = "preserved", ProjectNightfall = { grudgeKey = "legacy" } }
local original = {
    phase = "TRANSFORMING",
    smartFeral = false,
    playDeadEngaged = true,
    hibernationDisturbed = true,
    riseScheduledAtHours = 123.75,
    feralEligibleAtKnockdown = true,
    starvationHoursAtKnockdown = 190,
    lockedVisualKind = "FERAL",
    lockedVisualId = "visual-id",
    dayDormant = true,
    grudgeKey = "player-1",
    effigyHuntId = "effigy-42",
    effigyHuntUntilHours = 150,
    effigyHuntOriginX = 100,
    effigyHuntOriginY = 200,
    effigyHuntOriginZ = 0,
    effigyHuntEnraged = true,
}
assert(Persistence.save(root, original))
assert(root.unrelated == "preserved" and root.ProjectNightfall.grudgeKey == "legacy")
assert(root.ProjectNightfall.stateSchema == 1)

local restored = { phase = "NORMAL", transientTick = 99 }
assert(Persistence.restore(root, restored))
assert(restored.phase == "TRANSFORMING" and restored.uvPoints==nil)
assert(restored.playDeadEngaged == true and restored.hibernationDisturbed == true)
assert(restored.riseScheduledAtHours == 123.75 and restored.feralEligibleAtKnockdown == true)
assert(restored.starvationHoursAtKnockdown == 190)
assert(restored.lockedVisualKind == "FERAL" and restored.lockedVisualId == "visual-id")
assert(restored.dayDormant == true and restored.grudgeKey == "player-1")
assert(restored.effigyHuntId == "effigy-42" and restored.effigyHuntUntilHours == 150)
assert(restored.effigyHuntOriginX == 100 and restored.effigyHuntOriginY == 200)
assert(restored.effigyHuntOriginZ == 0 and restored.effigyHuntEnraged == true)
assert(restored.transientTick == 99, "restore must not overwrite transient runtime state")

-- Exercise explicit false against true defaults, not coincidentally matching
-- defaults. Saved cleared flags must also replace a previously saved true.
local cleared={phase="NORMAL",walkingBeforeLifecycleHold=false,
    anatomyCrawlerRestricted=false,anatomyWalkingBeforeRestriction=false,
    smartFeral=false,alphaFeral=false,playDeadEngaged=false,
    hibernationDisturbed=false,wasOutside=false,shelterHoldActive=false,
    feralGearProcessed=false,smartGearProcessed=false,feralEligibleAtKnockdown=false,
    dayDormant=false,effigyHuntEnraged=false}
local prior,defaults={},{}
for key,value in pairs(cleared) do
    if type(value)=="boolean" then prior[key]=true;defaults[key]=true end
end
assert(Persistence.save(root,prior))
assert(Persistence.save(root,cleared))
assert(Persistence.restore(root,defaults))
for key,value in pairs(cleared) do
    assert(root.ProjectNightfall.state[key]==value,"save lost cleared flag: "..key)
    assert(defaults[key]==value,"reload resurrected cleared flag: "..key)
end
assert(Persistence.save(root,{phase="NORMAL",smartFeral="invalid"}))
assert(root.ProjectNightfall.state.smartFeral==nil,"invalid data must still be removed")
assert(Persistence.save(root,{phase="FERAL",anatomyCrawlerRestricted=true,anatomyWalkingBeforeRestriction=false}))
local restricted={}
assert(Persistence.restore(root,restricted))
assert(restricted.anatomyCrawlerRestricted==true and restricted.anatomyWalkingBeforeRestriction==false)

assert(Persistence.restore({}, {}) == false)
assert(Persistence.save({}, nil) == false)
for _,bad in ipairs({true,false,42,"damaged"}) do
    assert(not Persistence.restore({ProjectNightfall=bad},{}),"invalid namespace must be rejected safely")
    assert(not Persistence.restore({ProjectNightfall={stateSchema=bad,state={}}},{}),
        "invalid schema must not be treated as legacy")
    local damaged={ProjectNightfall={state=bad}}
    assert(Persistence.save(damaged,{phase="NORMAL",smartFeral=false}))
    assert(damaged.ProjectNightfall.state.smartFeral==false)
end

local corrupt = {
    ProjectNightfall = {
        stateSchema = 1,
        grudgeKey = "legacy-player",
        state = { phase="BROKEN", smartFeral="yes", lockedVisualId=string.rep("x",300) },
    },
}
local safe = { phase="NORMAL", smartFeral=false }
assert(Persistence.restore(corrupt,safe))
assert(safe.phase=="NORMAL" and safe.smartFeral==false)
assert(safe.lockedVisualId==nil and safe.grudgeKey=="legacy-player")
assert(Persistence.restore({ProjectNightfall={stateSchema=999,state={phase="FERAL"}}},safe)==false)
assert(Persistence.restore({ProjectNightfall={stateSchema=0/0,state={phase="FERAL"}}},safe)==false)

local poisoned={phase="NORMAL",smartMode="IDLE",hibernationWakeDistance=3}
assert(Persistence.restore({ProjectNightfall={stateSchema=1,state={
    phase="FERAL",uvPoints=100,smartMode="EXECUTE_CODE",hibernationWakeDistance=10000,
    effigyHuntOriginZ=1000,riseScheduledAtHours=-20,
}}},poisoned))
assert(poisoned.phase=="FERAL","valid fields must still restore beside rejected fields")
assert(poisoned.uvPoints==nil and poisoned.smartMode=="IDLE","obsolete scalar UV must be ignored")
assert(poisoned.hibernationWakeDistance==3 and poisoned.effigyHuntOriginZ==nil)
assert(poisoned.riseScheduledAtHours==nil,"invalid saved deadlines must not enter lifecycle state")
print("Project Nightfall lifecycle persistence checks passed")
