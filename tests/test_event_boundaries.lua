local path=assert(arg[1])
local handle=assert(io.open(path,"r"))
local source=handle:read("*a")
handle:close()

local required={
    'safe("OnTick callback",runTick)',
    'safe("OnZombieCreate callback"',
    'safe("OnZombieUpdate callback"',
    'safe("OnZombieDead callback"',
    'safe("OnHitZombie callback",runHitZombie',
    'safe("OnGameStart callback",runGameStart)',
    'Events.OnZombieCreate.Add(onZombieCreate)',
    'Events.OnZombieUpdate.Add(onZombieUpdate)',
    'Events.OnZombieDead.Add(onZombieDead)',
    'Events.OnTick.Add(onTick)',
    'Events.OnGameStart.Add(onGameStart)',
}
for _,needle in ipairs(required) do
    assert(source:find(needle,1,true),"missing protected event boundary: "..needle)
end
assert(not source:find("Events.OnTick.Add(runTick)",1,true),"unprotected tick body must not be registered")
print("Project Nightfall event-callback containment contract passed")
