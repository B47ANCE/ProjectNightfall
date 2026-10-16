local path=assert(arg[1],"PN_ZombieUV.lua path required")
local file=assert(io.open(path,"rb"))
local source=file:read("*a");file:close()

assert(source:find("MortisIntegration.requestFakeDead",1,true),
    "hibernation must enter through the M.O.R.T.I.S. state adapter")
assert(not source:find("setFakeDead(true)",1,true),
    "setting fake-dead while in ZombieOnGroundState is lethal in Build 42")
assert(not source:find("setForceFakeDead(true)",1,true),
    "loose force-fake-dead flags must not replace the native state transition")
print("Project Nightfall atomic living fake-dead transition contract passed")
