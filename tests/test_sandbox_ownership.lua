local presetPath, configPath = assert(arg[1]), assert(arg[2])

local apocalypse = {
    ZombieLore = { Speed=4, ActiveOnly=2 },
    ZombieConfig = { RallyGroupSize=20, RallyGroupSizeVariance=50 },
}
local realRequire=require
require=function(name)
    if name=="Sandbox/Apocalypse" then return apocalypse end
    return realRequire(name)
end

local preset=dofile(presetPath)
assert(preset.ZombieLore.Speed==3 and preset.ZombieLore.ActiveOnly==1,
    "Nightfall preset must own the engine-safe zombie speed base")
assert(preset.ZombieConfig.RallyGroupSize==0 and preset.ZombieConfig.RallyGroupSizeVariance==0,
    "Nightfall preset must disable vanilla rally groups")
assert(preset.ZombieLore.SprinterPercentage==0 and preset.ZombieLore.DisableFakeDead==3,
    "Nightfall preset must disable vanilla random sprinters and fake-dead ownership")
assert(preset.MORTISSystems.EnableZombieDesiccation==true
    and preset.MORTISSystems.DesiccationYearsToTerminal==5.0
    and preset.MORTISSystems.EnableTerminalWithering==true,
    "Nightfall preset must explicitly carry the reviewed M.O.R.T.I.S. hunger lifecycle")
assert(apocalypse.ZombieLore.Speed==4 and apocalypse.ZombieConfig.RallyGroupSize==20,
    "Nightfall preset must not mutate cached Apocalypse data")

SandboxVars={
    ZombieLore={Speed=1,ActiveOnly=3},
    ZombieConfig={RallyGroupSize=99,RallyGroupSizeVariance=90},
    ProjectNightfall={Enabled=true},
}
ProjectNightfall=nil
Events=nil
dofile(configPath)
assert(SandboxVars.ZombieLore.Speed==3 and SandboxVars.ZombieLore.ActiveOnly==1)
assert(SandboxVars.ZombieLore.SprinterPercentage==0 and SandboxVars.ZombieLore.DisableFakeDead==3)
assert(SandboxVars.ZombieConfig.RallyGroupSize==0)
assert(SandboxVars.ZombieConfig.RallyGroupSizeVariance==0)

print("Project Nightfall sandbox ownership checks passed")
