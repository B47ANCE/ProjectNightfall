local store={}
ModData={getOrCreate=function(key)store[key]=store[key]or{};return store[key]end,transmit=function(key)store.transmitted=key end}
package.loaded["Mortis/init"]={Authority={canWriteCanonicalState=function()return true end}}
local Ecology=require "ProjectNightfall/PN_AlphaEcologyState"
assert(Ecology.recordAlphaDeath("A",{x=1,y=2},16))
assert(Ecology.isAlphaDead("A") and Ecology.getPowerVacuum("A").x==1)
assert(store.transmitted==Ecology.KEY)
for i=1,20 do assert(Ecology.recordAlphaDeath("D"..i,{x=i},16)) end
assert(Ecology.isAlphaDead("D1"),"death knowledge must outlive capped vacuum payload")
assert(Ecology.getPowerVacuum("D1")==nil and Ecology.getPowerVacuum("D20").x==20)
print("Project Nightfall persistent Alpha ecology-state checks passed")
