local Protection=require "ProjectNightfall/PN_UVProtection"
local config=Protection.defaults()
local resolve=assert(Protection.compile(config))
assert(resolve("Base.Hat_RiotHelmet","Head",nil)==.01)
assert(resolve("Base.Jacket_Police","ForeArm_L","Cotton")==.1)
assert(resolve("Mod.Unknown","Head",nil)==.5)
assert(resolve("Mod.RiotHelmetDefinitelyArmor","Head",nil)==.5,"names must not guess protection")
config.items["Base.Hat_RiotHelmet"]=1
assert(resolve("Base.Hat_RiotHelmet","Head",nil)==.01,"compiled policies must be stable")
config.parts["Mod.Mask"]={Head=0}
local custom=assert(Protection.compile(config))
assert(custom("Mod.Mask","Head","Cotton")==0)
assert(custom("Mod.Mask","Neck","Cotton")==.1)
config.materials.Cotton=0/0
assert(not Protection.compile(config))
assert(Protection.defaults().items["Base.Hat_RiotHelmet"]==.01)
print("Nightfall configurable UV protection precedence and provisional defaults checks passed")
