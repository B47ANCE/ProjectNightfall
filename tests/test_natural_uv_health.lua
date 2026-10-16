ProjectNightfall=nil
dofile(arg[1])
local rules=ProjectNightfall.NaturalUVHealth
local config={NaturalUVHealthFloor=0.50}
assert(rules.floor(config)==0.50)
assert(rules.floor({NaturalUVHealthFloor=0})==0.01)
assert(rules.floor({NaturalUVHealthFloor=math.huge})==0.50)
assert(rules.floor({NaturalUVHealthFloor=2})==1.0)
assert(rules.target==nil,"sunlight must not expose a direct-health damage calculation")
print("Project Nightfall fake-dead health-safety floor checks passed")
