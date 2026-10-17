package.preload["powerWorks/Definitions"]=function() error("obsolete Power import") end
package.preload["experienceWorks/API"]=function() error("obsolete Knowledge import") end
powerWorks=nil;experienceWorks=nil
local Power=require "B47ANCEDPower/Definitions"
local Knowledge=require "B47ANCEDKnowledgeAndWisdom/API"
local registered={}
lightWorks={registerBulb=function(def) registered[def.item]=def end}
require "ProjectNightfall/PN_FlashlightBulbs"
assert(B47ANCEDPower.Loads["ProjectNightfall.LightBulbUV"].consumptionMultiplier==1.25)
assert(B47ANCEDPower.Loads["ProjectNightfall.LightBulbUVHighOutput"].consumptionMultiplier==2)
local archive=require "ProjectNightfall/PN_ResearchArchive"
assert(archive==Knowledge and archive.hasKnowledgeDefinition("ProjectNightfall.EffigyConstruction"))
local character={data={},getModData=function(self) return self.data end}
assert(archive.learn(character,"NF-UV-003"))
assert(archive.learn(character,"NF-FIELD-026"))
assert(archive.hasKnowledge(character,"ProjectNightfall.EffigyConstruction"))
assert(powerWorks==nil and experienceWorks==nil,"do not install aliases for migrated dependencies")
print("Nightfall current dependency registration and persisted knowledge passed")
