ProjectNightfall=nil
dofile(arg[1])
local rules=ProjectNightfall.LifecycleRules
local config={FeralDayDormancyMinDLS=0.05}
assert(rules.canBeginSunHibernation(0.8,0.4,1.2,config)==true)
assert(rules.canBeginSunHibernation(0.0,0.0,-0.25,config)==false,"night must never initiate solar hibernation")
assert(rules.canBeginSunHibernation(0.0,0.4,1.0,config)==false,"stale local exposure must not override astronomical night")
assert(rules.canBeginSunHibernation(0.8,0.0,0,config)==false,"complete local cover must not initiate hibernation")
assert(rules.canBeginSunHibernation(0.02,0.02,0.1,config)==false,"astronomical darkness must win over trace exposure")
assert(rules.risesAsFeral(true,true)==true)
assert(rules.risesAsFeral(false,true)==false,"No Ferals must always produce a regular rise")
assert(rules.risesAsFeral(true,false)==false,"unqualified starvation must produce a regular rise")
print("Project Nightfall lifecycle-rule checks passed")
