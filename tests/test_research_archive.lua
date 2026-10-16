package.loaded["experienceWorks/API"]=nil; package.loaded["ProjectNightfall/PN_ResearchArchive"]=nil; _G.experienceWorks=nil
local Archive=require "ProjectNightfall/PN_ResearchArchive"
assert(Archive.getDocument("NF-UV-003").project=="Project Nightfall")
assert(#Archive.getDocument("NF-BEHAV-044").spawnCategories==0)
local character={modData={}}; function character:getModData() return self.modData end
assert(Archive.learn(character,"NF-SOLAR-019")==false)
assert(Archive.learn(character,"NF-UV-003",{worldAgeHours=1})==true)
assert(Archive.learn(character,"NF-SOLAR-019",{worldAgeHours=2})==true)
assert(Archive.learn(character,"NF-ANAT-014",{worldAgeHours=3})==true)
assert(Archive.learn(character,"NF-BEHAV-007",{worldAgeHours=4})==true)
assert(Archive.learn(character,"NF-BEHAV-044",{worldAgeHours=5})==false)
assert(Archive.learn(character,"NF-INCIDENT-052",{worldAgeHours=5})==true)
assert(Archive.learn(character,"NF-BEHAV-044",{worldAgeHours=6})==true)
assert(Archive.learn(character,"NF-FIELD-026",{worldAgeHours=7})==true)
assert(Archive.hasKnowledge(character,"ProjectNightfall.EffigyConstruction"))
assert(Archive.hasKnowledge(character,"ProjectNightfall.PersistentPredation"))
print("Project Nightfall experienceWorks research vertical-slice checks passed")
