local root=assert(arg[1],"Project Nightfall shared Lua root required")
local function read(name)
    local file=assert(io.open(root.."/ProjectNightfall/"..name,"rb"))
    local text=file:read("*a");file:close();return text
end
local lifecycle=read("PN_ZombieUV.lua")
local artificial=read("PN_ArtificialUV.lua")
local updateStart=assert(lifecycle:find("local function updateZombie(z)",1,true))
local recovery=assert(lifecycle:find('UVMetabolism.recover,z',updateStart,true))
local exposure=assert(lifecycle:find('processRegionalUVTissue,z,dt',updateStart,true))
assert(recovery<exposure,"pending healing must recover before new exposure overwrites receipts")
assert(lifecycle:find('require "ProjectNightfall/PN_UVTissueScheduler"',1,true))
assert(lifecycle:find('require "ProjectNightfall/PN_SunHibernation"',1,true))
assert(not lifecycle:find("applyNaturalUVHealthFloor",1,true)
    and not lifecycle:find("NaturalUVHealth.target",1,true),
    "natural UV direct-health damage must be removed")
assert(lifecycle:find('regionalSunHibernationReady',1,true),
    "regional mode must use committed natural dose for hibernation")
assert(not lifecycle:find("s.uvPoints",1,true),
    "lifecycle must not recreate the obsolete scalar UV reserve")
assert(not artificial:find("setHealth",1,true) and not artificial:find("applyCustomDamage",1,true),
    "artificial emitter provider must not retain a direct damage path")
assert(not artificial:find("observeZombie",1,true) and not artificial:find("OnZombieUpdate",1,true),
    "artificial emitter provider must not own a second zombie queue")
assert(artificial:find("considerIndependentAttack",1,true),
    "UV-light attack behavior must survive legacy damage removal")
print("Nightfall regional UV legacy-removal and single-scheduler contract passed")
