local registeredTraits = {}
local registeredTypes = {}
local assigned = setmetatable({}, { __mode = "k" })
local rejectAssignment=false
local rejectClear=false
local walkingAllowed=true
local rejectWalking=false
local rejectPosture=false
local nutritionProfiles=setmetatable({}, { __mode = "k" })

local Mortis = {
    Traits = { has = function(id) return registeredTraits[id] ~= nil end },
    Types = { has = function(id) return registeredTypes[id] ~= nil end },
    LocomotionOverrides = {
        acquire=function(_,owner,definition) return true,owner,definition end,
        release=function(_,owner) return true,owner end,
    },
    CrowdFlow = {
        pathDeeperInterior=function(_,options) return true,nil,options.entrySquare end,
    },
    State={
        requestStand=function() return true,"get-up-state" end,
        requestCrawlerWake=function() return true,"crawler-idle-state" end,
        maintainCrawler=function() walkingAllowed=false;return not rejectPosture,"crawler-posture" end,
        getCanWalk=function() return walkingAllowed end,
        setWalkingAllowed=function(_,value)
            if rejectWalking then return false,"injected walking failure" end
            walkingAllowed=value;return true
        end,
        requestFakeDead=function() return true,"fake-dead-state" end,
    },
    Authority = {canWriteCanonicalState=function() return true end},
    Anatomy = {
        applyNutritionProfile=function(zombie,profileId,multiplier,options)
            nutritionProfiles[zombie]={id=profileId,multiplier=multiplier,transmit=options and options.transmit}
            return nutritionProfiles[zombie]
        end,
    },
    ZombieHunger = {
        advance=function() return true end,
        getStarvationHours=function() return 168 end,
        getDrive=function(_,threshold) return 0.5,threshold end,
    },
    DetachedParts={registry={has=function() return false end}},
    Entity={kind=function() return "infected" end},
}

function Mortis.registerTrait(definition) registeredTraits[definition.id] = definition end
function Mortis.registerType(definition) registeredTypes[definition.id] = definition end
function Mortis.registerDetachedPartClassifier(definition) Mortis.detachedClassifier=definition end
function Mortis.getTypeId(zombie) return assigned[zombie] end
function Mortis.assign(zombie, typeId)
    if rejectAssignment then return nil,"simulated assignment rejection" end
    assert(registeredTypes[typeId], "assigned an unregistered Nightfall type")
    assigned[zombie] = typeId
    return zombie
end
function Mortis.clearAssignment(zombie)
    if rejectClear then return false,"simulated clear rejection" end
    assigned[zombie] = nil
    return true
end

local realRequire = require
require = function(name)
    if name == "Mortis/init" then return Mortis end
    return realRequire(name)
end

ProjectNightfall = nil
dofile(arg[1])

local legFunction={leftLeg=1,rightLeg=1}
Mortis.AnatomyCapabilities={functionalSnapshot=function() return {regionFunction=legFunction} end}
local riseOK,riseMode=ProjectNightfall.MortisIntegration.requestRise({})
assert(riseOK and riseMode=="get-up-state")
legFunction={leftLeg=0,rightLeg=0}
riseOK,riseMode=ProjectNightfall.MortisIntegration.requestRise({})
assert(riseOK and riseMode=="crawler-idle-state","bilateral leg failure must not request standing")
local activeOK,activeMode=ProjectNightfall.MortisIntegration.enforceActiveAnatomy({})
assert(activeOK and activeMode=="crawler-posture")
legFunction={leftLeg=0,rightLeg=1}
riseOK,riseMode=ProjectNightfall.MortisIntegration.requestRise({})
assert(riseOK and riseMode=="get-up-state","one-leg threshold remains a separate policy")
legFunction={leftLeg=0/0,rightLeg=0}
assert(not ProjectNightfall.MortisIntegration.requestRise({}))
assert(not ProjectNightfall.MortisIntegration.enforceActiveAnatomy({}))

local movementState={phase="FERAL"}
legFunction={leftLeg=0,rightLeg=0}
walkingAllowed=true;rejectPosture=true
assert(not ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(movementState.anatomyWalkingBeforeRestriction==true and not walkingAllowed)
rejectPosture=false
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(movementState.anatomyWalkingBeforeRestriction==true,"retry must preserve pre-injury permission")
legFunction={leftLeg=1,rightLeg=1}
movementState.shelterHoldActive=true
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(not walkingAllowed and movementState.anatomyCrawlerRestricted)
movementState.shelterHoldActive=false;rejectWalking=true
assert(not ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(movementState.anatomyCrawlerRestricted,"failed restoration must remain retryable")
rejectWalking=false
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(walkingAllowed and movementState.anatomyCrawlerRestricted==false)
assert(movementState.anatomyWalkingBeforeRestriction==nil)
walkingAllowed=false;legFunction={leftLeg=0,rightLeg=0}
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
legFunction={leftLeg=1,rightLeg=1}
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},movementState))
assert(not walkingAllowed,"pre-existing nonwalking zombies must not gain walking permission")
local dormant={phase="NORMAL"}
walkingAllowed=true
assert(ProjectNightfall.MortisIntegration.captureWalkingBeforeHold({},dormant))
walkingAllowed=false;dormant.phase="TRANSFORMING"
assert(ProjectNightfall.MortisIntegration.captureWalkingBeforeHold({},dormant))
assert(dormant.walkingBeforeLifecycleHold==true,"nested holds must preserve original walking permission")
legFunction={leftLeg=0,rightLeg=0}
assert(ProjectNightfall.MortisIntegration.requestRise({},dormant))
assert(dormant.anatomyWalkingBeforeRestriction==true and dormant.anatomyCrawlerRestricted)
assert(dormant.walkingBeforeLifecycleHold==nil)
dormant.phase="FERAL";legFunction={leftLeg=1,rightLeg=1}
assert(ProjectNightfall.MortisIntegration.enforceActiveAnatomy({},dormant))
assert(walkingAllowed,"injury acquired during hibernation must retain the pre-hibernation baseline")
walkingAllowed=false
local nativeCrawler={phase="NORMAL"}
assert(ProjectNightfall.MortisIntegration.captureWalkingBeforeHold({},nativeCrawler))
local nativeOK,nativeMode=ProjectNightfall.MortisIntegration.requestRise({},nativeCrawler)
assert(nativeOK and nativeMode=="crawler-idle-state","healthy native nonwalkers must not be forced to stand")

local Integration = assert(ProjectNightfall.MortisIntegration)
assert(registeredTraits["ProjectNightfall.UVVulnerable"])
assert(registeredTypes[Integration.TYPE_TRANSFORMING])
assert(registeredTypes[Integration.TYPE_FERAL].extends == Integration.TYPE_TRANSFORMING)
assert(registeredTypes[Integration.TYPE_SMART_FERAL].extends == Integration.TYPE_FERAL)
assert(Mortis.detachedClassifier and Mortis.detachedClassifier.id=="ProjectNightfall.sourceSignature")
assert(Mortis.detachedClassifier.classify({}, {sourceTypeId=Integration.TYPE_SMART_FERAL}).signature=="smartFeral")
assert(Mortis.detachedClassifier.classify({}, {sourceTypeId=nil}).signature=="regular")

local zombie = {}
local ok, reason = Integration.assign(zombie, Integration.TYPE_FERAL)
assert(ok, tostring(reason))
assert(Mortis.getTypeId(zombie) == "ProjectNightfall.Feral")
assert(nutritionProfiles[zombie].id=="ProjectNightfall:"..Integration.TYPE_FERAL)
assert(nutritionProfiles[zombie].multiplier==0.25 and nutritionProfiles[zombie].transmit==true)
assert(Integration.clear(zombie))
assert(Mortis.getTypeId(zombie) == nil)
rejectAssignment=true
local committed=Integration.commitRiseIdentity(zombie,true,false)
assert(committed==false and Mortis.getTypeId(zombie)==nil)
rejectAssignment=false
local committedFeral,target=Integration.commitRiseIdentity(zombie,true,true)
assert(committedFeral and target==Integration.TYPE_SMART_FERAL and Mortis.getTypeId(zombie)==target)
rejectClear=true
assert(Integration.commitRiseIdentity(zombie,false,false)==false)
assert(Mortis.getTypeId(zombie)==Integration.TYPE_SMART_FERAL,"failed clear must preserve identity")
rejectClear=false
assert(Integration.commitRiseIdentity(zombie,false,false))
assert(Mortis.getTypeId(zombie)==nil)
assert(Integration.rollbackRiseIdentity(zombie))
assert(Mortis.getTypeId(zombie)==Integration.TYPE_TRANSFORMING)
assert(Integration.requestFakeDead(zombie)==true)

local restored = { phase = "NORMAL", smartFeral = false }
assigned[zombie] = Integration.TYPE_SMART_FERAL
Integration.applyIdentityToState(zombie, restored)
assert(restored.phase == "FERAL")
assert(restored.smartFeral == true)

local invalid, invalidReason = Integration.assign(zombie, "SomeOtherMod.Zombie")
assert(invalid == false and invalidReason)
assert(Integration.canWriteCanonicalState(zombie)==true)
local drive,level=Integration.getHungerDrive(zombie,0.25)
assert(drive==0.5 and level==0.25)
local eligible,hours=Integration.hasStarvedFor(zombie,7)
assert(eligible and hours==168)
Mortis.ZombieHunger.advance=function() error("simulated non-authority/provider error") end
assert(Integration.hasStarvedFor(zombie,7)==false,"authoritative eligibility must fail closed when hunger cannot advance")
Mortis.Authority.canWriteCanonicalState=function() return false end
assert(Integration.hasStarvedFor(zombie,7)==true,"read-only consumers may inspect the last confirmed starvation state")
Mortis.Authority.canWriteCanonicalState=function() return true end
Mortis.ZombieHunger.getStarvationHours=function() return 0/0 end
assert(Integration.hasStarvedFor(zombie,0)==false,"invalid starvation fails closed even at zero days")
Mortis.ZombieHunger.getStarvationHours=function() error("malformed modded zombie") end
assert(Integration.hasStarvedFor(zombie,7)==false)
Mortis.ZombieHunger.advance=function() return true end
Mortis.ZombieHunger.getDrive=function() return 2,-1 end
drive,level=Integration.getHungerDrive(zombie,0.25)
assert(drive==1 and level==0,"hunger drive must stay normalized")
Mortis.ZombieHunger.getDrive=function() return math.huge,0/0 end
drive,level=Integration.getHungerDrive(zombie,0.25)
assert(drive==0 and level==0,"invalid hunger values fail safely")

assert(Integration.setUVSlowed(zombie,true))
assert(Integration.setNightfallBaseSpeed(zombie,"shambler"))
assert(Integration.setNightfallBaseSpeed(zombie,"fastShambler"))
local badTier,badTierReason=Integration.setNightfallBaseSpeed(zombie,"random")
assert(badTier==false and badTierReason)
assert(Integration.setFeralSprint(zombie,true))
local entry={}
local flowed,_,target=Integration.pathDeeperIntoShelter(zombie,entry)
assert(flowed and target==entry,"Nightfall must call the MORTIS crowd-flow API")

print("Project Nightfall MORTIS integration checks passed")
