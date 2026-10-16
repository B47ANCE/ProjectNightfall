ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.TestKit = ProjectNightfall.TestKit or {}

local TestKit = ProjectNightfall.TestKit
local KIT_VERSION = "0.27.1"
local MARKER = "ProjectNightfall.TestKitVersion"
local TEST_STARVATION_HOURS = 1.0

local contents = {
    { "Base.HandTorch", 1 },
    { "Base.Torch", 1 },
    { "Base.FlashLight_AngleHead", 1 },
    { "Base.FlashLight_AngleHead_Army", 1 },
    { "Base.PenLight", 1 },
    { "Base.Lantern_CraftedElectric", 1 },
    { "Base.Flashlight_Crafted", 1 },
    { "Base.GunLight", 2 },
    { "Base.Pistol", 1 },
    { "Base.Shotgun", 1 },
    { "Base.Battery", 8 },
    { "powerWorks.BatteryAA", 8 },
    { "powerWorks.BatteryD", 4 },
    { "powerWorks.BatteryCoin", 4 },
    { "powerWorks.BatteryPackSmall", 1 },
    { "powerWorks.BatteryPackLarge", 1 },
    { "powerWorks.SolarMilitaryWatch_Left", 1 },
    { "Base.WristWatch_Left_DigitalBlack", 1 },
    { "Base.WristWatch_Left_ClassicBlack", 1 },
    { "Base.DuctTape", 2 },
    { "Base.Screwdriver", 1 },
    { "Base.Pliers", 1 },
    { "Base.ViseGrips", 1 },
    { "Base.Multitool", 1 },
    { "Base.Bag_Schoolbag", 1 },
    { "Base.LightBulb", 3 },
    { "Base.LightBulbRed", 3 },
    { "Base.LightBulbGreen", 1 },
    { "Base.LightBulbBlue", 1 },
    { "Base.LightBulbCyan", 1 },
    { "Base.LightBulbMagenta", 1 },
    { "Base.LightBulbOrange", 1 },
    { "Base.LightBulbPink", 1 },
    { "Base.LightBulbPurple", 1 },
    { "Base.LightBulbYellow", 1 },
    { "ProjectNightfall.LightBulbUV", 3 },
    { "ProjectNightfall.LightBulbUVHighOutput", 3 },
}

function TestKit.give(player, force)
    player = player or (getPlayer and getPlayer()) or nil
    if not player then return false, "player unavailable" end
    local inventory = player:getInventory()
    if not inventory then return false, "inventory unavailable" end

    local md = player:getModData()
    if not force and md[MARKER] == KIT_VERSION then
        print("[ProjectNightfall][TestKit] Kit already granted; use PNTestKit(true) to force another")
        return false, "already granted"
    end

    local granted, missing = 0, {}
    for _, entry in ipairs(contents) do
        for _=1,entry[2] do
            local ok,item = pcall(function() return inventory:AddItem(entry[1]) end)
            if ok and item then granted=granted+1 else missing[#missing+1]=entry[1] end
        end
    end
    md[MARKER] = KIT_VERSION
    print(string.format("[ProjectNightfall][TestKit] Granted %d items; unavailable=%d",granted,#missing))
    if #missing>0 then print("[ProjectNightfall][TestKit] Unavailable types: "..table.concat(missing,", ")) end
    return true, {granted=granted,missing=missing,version=KIT_VERSION}
end

function PNTestKit(force)
    return TestKit.give(nil,force==true)
end

local roofTeleportPending=false
function PNTestPoliceRoof()
    if type(isClient)=="function" and isClient() then return false,"single-player only" end
    if roofTeleportPending then return false,"teleport already pending" end
    local player=getPlayer and getPlayer()
    local cell=getCell and getCell()
    if not player or not cell then return false,"player/world unavailable" end
    -- User-specified Muldraugh garage location. Never manufacture a roof tile.
    local x,y,z=10643,10408,1
    local function roof()
        local sq=cell:getGridSquare(x,y,z)
        return sq and sq:TreatAsSolidFloor() and not sq:isSolid() and not sq:isSolidTrans() and sq
    end
    if roof() then player:teleportTo(x+0.5,y+0.5,z);return true end
    if not Events or not Events.OnTick then return false,"world-load callback unavailable" end
    -- Native debug teleport streams the destination. Stage at ground level,
    -- then move up only after the actual roof floor has been verified.
    player:teleportTo(x+0.5,y+0.5,0)
    roofTeleportPending=true
    local ticks=0
    local callback
    local function finish(message)
        roofTeleportPending=false;Events.OnTick.Remove(callback)
        print("[ProjectNightfall][PoliceRoof] "..message)
    end
    callback=function()
        ticks=ticks+1
        local ok,err=pcall(function()
            if player:isDead() then finish("Cancelled: character died");return end
            if math.abs(player:getX()-x-0.5)>3 or math.abs(player:getY()-y-0.5)>3 then
                if ticks>=600 then finish("Cancelled: destination not reached") end
                return
            end
            if roof() then player:teleportTo(x+0.5,y+0.5,z);finish("Arrived on verified roof at 10643,10408,1")
            elseif ticks>=600 then finish("No walkable roof at target; left at ground level. Check map/build compatibility.") end
        end)
        if not ok then finish("Cancelled safely: "..tostring(err)) end
    end
    Events.OnTick.Add(callback)
    print("[ProjectNightfall][PoliceRoof] Loading destination at ground level; roof check pending")
    return true,"loading destination"
end

-- Explicit repeatable single-player fixture; never replaces existing equipment.
function PNTestCombatKit()
    if type(isClient)=="function" and isClient() then return false,"single-player test kit only" end
    local player=getPlayer and getPlayer()
    local inventory=player and player:getInventory()
    local square=player and player:getCurrentSquare()
    if not inventory or not square or type(instanceItem)~="function" then return false,"player/world unavailable" end
    local failures={};local report={floodlights=0,bulbs=0,magazines=0,gear=0,failures=failures}
    local function attempt(label,fn)
        local ok,value=pcall(fn)
        if not ok or not value then failures[#failures+1]=label..": "..tostring(value);return nil end
        return value
    end
    local function add(id)return attempt(id,function()return inventory:AddItem(id)end)end
    for i=1,10 do
        if attempt("floodlight "..i,function()
            local item=instanceItem("Moveables.Moveable")
            if not item or not item:ReadFromWorldSprite("lighting_outdoor_01_48") then return false end
            return square:AddWorldInventoryItem(item,0.2+((i-1)%5)*0.15,0.35+math.floor((i-1)/5)*0.3,0)
        end) then report.floodlights=report.floodlights+1 end
        if add("ProjectNightfall.LightBulbUVHighOutput") then report.bulbs=report.bulbs+1 end
    end
    local rifle=add("Base.AssaultRifle")
    if rifle then attempt("load M16",function()
        rifle:setCurrentAmmoCount(rifle:getMaxAmmo());rifle:setContainsClip(true);rifle:setRoundChambered(true);return true
    end) end
    for _=1,6 do
        local mag=add("Base.556Clip")
        if mag and attempt("load magazine",function()mag:setCurrentAmmoCount(mag:getMaxAmmo());return true end) then
            report.magazines=report.magazines+1
        end
    end
    if rifle then attempt("mounted high-output UV gunlight",function()
        local part=instanceItem("Base.GunLight")
        local lw=rawget(_G,"lightWorks")
        if not part or not lw or not lw.installBulb(part,"ProjectNightfall.LightBulbUVHighOutput") then return false end
        rifle:attachWeaponPart(part,true)
        return true
    end) end
    for _,id in ipairs({"Hat_RiotHelmet","Vest_BulletPolice","Jacket_Police","Shirt_PoliceBlue",
        "Trousers_Police","Gloves_LeatherGlovesBlack","Shoes_ArmyBoots",
        "GreaveBodyArmour_Right_Police","GreaveBodyArmour_Left_Police",
        "ThighBodyArmour_R_Police","ThighBodyArmour_L_Police",
        "Vambrace_BodyArmour_Right_Police","Vambrace_BodyArmour_Left_Police"}) do
        if add("Base."..id) then report.gear=report.gear+1 end
    end
    for _,id in ipairs({"Base.Screwdriver","Base.Pliers","Base.Bag_Schoolbag",
        "powerWorks.BatteryAA","powerWorks.BatteryAA","powerWorks.BatteryAAA","powerWorks.BatteryAAA",
        "powerWorks.BatteryD","powerWorks.BatteryD"}) do add(id) end
    print(string.format("[ProjectNightfall][CombatKit] floodlights=%d/10 looseUV=%d/10 loadedSpareMags=%d/6 gear=%d/13 failures=%d",
        report.floodlights,report.bulbs,report.magazines,report.gear,#failures))
    print("[ProjectNightfall][CombatKit] Equip gear and rifle; service gunlight battery if needed. Place floodlights and supply electricity before testing bulbs.")
    for _,reason in ipairs(failures) do print("[ProjectNightfall][CombatKit] FAILED "..reason) end
    return #failures==0,report
end

local researchIds={"NF-UV-003","NF-SOLAR-019","NF-FIELD-026"}

-- Physical documents only: deliberately does not call learn/completeRead.
function PNTestGiveResearch()
    if type(isClient)=="function" and isClient() then return false,"use this inventory fixture in single-player" end
    local player=type(getPlayer)=="function" and getPlayer() or nil
    local inventory=player and player:getInventory()
    local Archive=rawget(_G,"experienceWorks")
    if not inventory or not Archive or type(Archive.getDocument)~="function" then return false,"research runtime unavailable" end
    local granted,missing={},{}
    for _,id in ipairs(researchIds) do
        local document=Archive.getDocument(id)
        local ok,item=pcall(function() return document and document.itemType and inventory:AddItem(document.itemType) end)
        if ok and item then granted[#granted+1]=id else missing[#missing+1]=id end
    end
    print("[ProjectNightfall][ResearchTest] Physical files granted="..#granted.." missing="..#missing.."; no knowledge granted. Read NF-UV-003, then NF-FIELD-026. Use PNTestResearchStatus().")
    return #missing==0,{granted=granted,missing=missing}
end

function PNTestResearchStatus()
    local player=type(getPlayer)=="function" and getPlayer() or nil
    local Archive=rawget(_G,"experienceWorks")
    if not player or not Archive then return false,"research runtime unavailable" end
    local results={}
    for _,id in ipairs(researchIds) do
        local ok,read,allowed,reason=pcall(function()
            local known=Archive.hasRead(player,id)
            local eligible,detail=Archive.canLearn(player,id)
            return known,eligible,eligible and "prerequisites satisfied" or detail
        end)
        results[id]={read=ok and read==true,canLearn=ok and allowed==true,reason=ok and reason or "knowledge query failed"}
        print("[ProjectNightfall][ResearchTest] "..id.." read="..tostring(results[id].read).." eligible="..tostring(results[id].canLearn).." "..tostring(results[id].reason))
    end
    return true,results
end

local function nearbyZombies(radius)
    local player=(getPlayer and getPlayer()) or nil
    local cell=getCell and getCell() or nil
    local list=cell and cell:getZombieList() or nil
    local result={}
    if not player or not list then return result end
    local radiusSq=(tonumber(radius) or 20)^2
    for i=0,list:size()-1 do
        local zombie=list:get(i)
        if zombie then
            local dx=zombie:getX()-player:getX()
            local dy=zombie:getY()-player:getY()
            if dx*dx+dy*dy<=radiusSq then result[#result+1]=zombie end
        end
    end
    return result
end

function TestKit.prepareStarvationTest(radius)
    local Mortis=rawget(_G,"Mortis")
    local Config=ProjectNightfall.Config and ProjectNightfall.Config.POC or nil
    if not Mortis or not Mortis.ZombieHunger or not Mortis.ZombieHunger.setTestState then
        return false,"M.O.R.T.I.S. hunger test API unavailable"
    end
    if not Config then return false,"Nightfall config unavailable" end
    Config.RequireStarvationForFerals=true
    Config.FeralRequiredStarvationDays=TEST_STARVATION_HOURS/24
    local prepared=0
    for _,zombie in ipairs(nearbyZombies(radius)) do
        local ok=Mortis.ZombieHunger.setTestState(zombie,1.0,0)
        if ok then prepared=prepared+1 end
    end
    print(string.format(
        "[ProjectNightfall][TestKit] Prepared %d nearby zombies at full hunger. "..
        "Run one in-game hour, expose them to sun until knockdown, then reach nightfall. "..
        "Production remains seven days after restart/sandbox reload.",prepared))
    return true,{prepared=prepared,requiredStarvationHours=TEST_STARVATION_HOURS}
end

function PNTestPrepareStarvation(radius)
    return TestKit.prepareStarvationTest(radius)
end

function TestKit.giveEffigyParts(signature)
    signature=signature or "feral"
    if signature~="human" and signature~="regular" and signature~="feral" and signature~="smartFeral" then
        return false,"signature must be human, regular, feral, or smartFeral"
    end
    local player=(getPlayer and getPlayer()) or nil
    local inventory=player and player:getInventory() or nil
    local Mortis=rawget(_G,"Mortis")
    if not inventory or not Mortis or not Mortis.DetachedParts then return false,"detached-part test runtime unavailable" end
    local types={{"medWorks.DetachedArm","leftArm"},{"medWorks.DetachedLeg","leftLeg"},{"medWorks.DetachedHead","neck"}}
    local created={}
    for index,definition in ipairs(types) do
        local item=inventory:AddItem(definition[1])
        if not item then return false,"could not create "..definition[1] end
        local record={schemaVersion=1,speciesId="Mortis.Humanoid",speciesVersion=1,
            regionId=definition[2],sourceStableId="PN-test-"..signature,
            sourceTypeId="ProjectNightfall.Test",classifications={
                ["ProjectNightfall.sourceSignature"]={signature=signature},
            },metadata={testKit=true,index=index}}
        local ok,err=Mortis.DetachedParts.write(item,record)
        if not ok then return false,err end
        created[#created+1]=item
    end
    print(string.format("[ProjectNightfall][TestKit] Granted three %s-source parts; select all three and right-click Build Macabre Effigy",signature))
    return true,created
end

function PNTestGiveEffigyParts(signature) return TestKit.giveEffigyParts(signature) end

function TestKit.placeEffigy(signature)
    signature=signature or "human"
    if signature~="human" and signature~="regular" and signature~="feral" and signature~="smartFeral" then
        return false,"signature must be human, regular, feral, or smartFeral"
    end
    local player=(getPlayer and getPlayer()) or nil
    local square=player and player:getSquare() or nil
    local Effigies=ProjectNightfall.Effigies
    if not square or not Effigies or not instanceItem then return false,"effigy test runtime unavailable" end
    local item=instanceItem("ProjectNightfall.Effigy")
    if not item then return false,"effigy item unavailable" end
    local composition={schemaVersion=1,signature=signature,partCount=3,parts={
        {schemaVersion=1,regionId="leftArm",speciesId="Mortis.Humanoid",sourceStableId="test-source",signature=signature},
        {schemaVersion=1,regionId="rightArm",speciesId="Mortis.Humanoid",sourceStableId="test-source",signature=signature},
        {schemaVersion=1,regionId="neck",speciesId="Mortis.Humanoid",sourceStableId="test-source",signature=signature},
    }}
    item:getModData().ProjectNightfallEffigyComposition=composition
    local worldItem=square:AddWorldInventoryItem(item,0.5,0.5,0,false)
    if not worldItem then return false,"could not place world item" end
    local entry,reason=Effigies.registerPlaced(worldItem,composition,{ownerStableId="test-player"})
    if not entry then return false,reason end
    print(string.format("[ProjectNightfall][TestKit] Placed %s effigy id=%s @ %d,%d",
        signature,entry.id,math.floor(entry.x),math.floor(entry.y)))
    return true,entry
end

function PNTestPlaceEffigy(signature) return TestKit.placeEffigy(signature) end

local function totalMetrics(entries)
    local total={considered=0,ran=0,deferred=0,requests=0,accepted=0}
    for _,entry in pairs(entries or {}) do
        for key in pairs(total) do total[key]=total[key]+(tonumber(entry[key]) or 0) end
    end
    return total
end

function TestKit.performanceStatus()
    local zombieUV=ProjectNightfall.ZombieUV
    local groups=ProjectNightfall.FeralGroups
    local Mortis=rawget(_G,"Mortis")
    local lifecycle=(zombieUV and zombieUV.getDiagnosticStats and zombieUV.getDiagnosticStats()) or {}
    local communication=(groups and groups.getDiagnostics and groups.getDiagnostics()) or {}
    local corpseRuntime=ProjectNightfall.UVCorpseRuntime
    local corpse=(corpseRuntime and corpseRuntime.getDiagnostics and corpseRuntime.getDiagnostics()) or {}
    local scheduler=(Mortis and Mortis.Scheduler and Mortis.Scheduler.getDiagnostics
        and Mortis.Scheduler.getDiagnostics()) or {classes={},budgets={}}
    local classes=totalMetrics(scheduler.classes)
    local budgets=totalMetrics(scheduler.budgets)
    local report={lifecycle=lifecycle,communication=communication,scheduler=scheduler,corpseUV=corpse}
    print(string.format("[ProjectNightfall][Performance] tracked=%d processed=%d rises=%d errors=%d responsePending=%d responseDropped=%d",
        tonumber(lifecycle.tracked) or 0,tonumber(lifecycle.processed) or 0,
        tonumber(lifecycle.rises) or 0,tonumber(lifecycle.errors) or 0,
        tonumber(communication.pendingResponses) or 0,tonumber(communication.responsesDropped) or 0))
    print(string.format("[ProjectNightfall][Performance] scheduler considered=%d ran=%d deferred=%d budgetRequests=%d accepted=%d deferred=%d",
        classes.considered,classes.ran,classes.deferred,budgets.requests,budgets.accepted,budgets.deferred))
    print(string.format("[ProjectNightfall][Performance] followerPaths attempts=%d succeeded=%d failed=%d lastAttempts=%d lastGroups=%d",
        tonumber(communication.followerPathAttempts) or 0,
        tonumber(communication.followerPathSucceeded) or 0,
        tonumber(communication.followerPathFailed) or 0,
        tonumber(communication.followerLastPathAttempts) or 0,
        tonumber(communication.followerLastGroupsInspected) or 0))
    print(string.format("[ProjectNightfall][Performance] corpseUV emitters=%d candidates=%d processed=%d scanned=%d remaining=%d failures=%d",
        tonumber(corpse.lastEmitters) or 0,tonumber(corpse.lastCandidates) or 0,
        tonumber(corpse.lastProcessed) or 0,tonumber(corpse.lastSquaresScanned) or 0,
        tonumber(corpse.lastScanRemaining) or 0,tonumber(corpse.failures) or 0))
    return true,report
end

function PNPerformanceStatus() return TestKit.performanceStatus() end

local function nearestAlpha(radius)
    local integration=ProjectNightfall.MortisIntegration
    local expected=integration and integration.TYPE_ALPHA_FERAL
    local player=(getPlayer and getPlayer())or nil;local best,bestDistance=nil,math.huge
    if not player or not expected then return nil end
    for _,zombie in ipairs(nearbyZombies(radius or 80))do
        local ok,typeId=pcall(integration.getTypeId,zombie)
        if ok and typeId==expected then
            local dx,dy=zombie:getX()-player:getX(),zombie:getY()-player:getY();local distance=dx*dx+dy*dy
            if distance<bestDistance then best,bestDistance=zombie,distance end
        end
    end
    return best
end

function PNTestAlphaMigrationStatus()
    local dens=ProjectNightfall.DenState
    if not dens then return false,"Alpha den state unavailable" end
    local territories=dens.listTerritories(64)
    for _,territory in ipairs(territories)do
        local pressure=territory.migrationPressure and territory.migrationPressure.value or 0
        local migration=territory.migration
        print(string.format("[ProjectNightfall][AlphaMigrationTest] alpha=%s territory=%s state=%s pressure=%.2f migration=%s season=%s",
            tostring(territory.alphaId),tostring(territory.status),tostring(territory.alphaState),tonumber(pressure)or 0,
            tostring(migration and migration.status),tostring(migration and migration.season)))
    end
    return true,territories
end

function PNTestAlphaMigrationPressure(amount)
    if type(isClient)=="function" and isClient()then return false,"single-player test command only" end
    local alpha=nearestAlpha(80);local migration=ProjectNightfall.AlphaMigration
    if not alpha or not migration then return false,"no nearby loaded Alpha with migration runtime" end
    local pressure,err=migration.recordPressure(alpha,"manual-test",math.max(0,tonumber(amount)or 60))
    if not pressure then return false,err end
    print(string.format("[ProjectNightfall][AlphaMigrationTest] pressure=%.2f season=%s eligible=%s",
        tonumber(pressure.value)or 0,tostring(migration.currentSeason()),tostring(migration.evaluate(alpha))))
    return true,pressure
end

function PNTestAlphaMigrationDestination()
    if type(isClient)=="function" and isClient()then return false,"single-player test command only" end
    local player=(getPlayer and getPlayer())or nil;local square=player and player:getSquare()or nil
    local alpha=nearestAlpha(80);local migration=ProjectNightfall.AlphaMigration
    if not square or not alpha or not migration then return false,"player, nearby Alpha, or migration runtime unavailable" end
    local exposure=ProjectNightfall.SolarUV and ProjectNightfall.SolarUV.getExposureAtSquare(square)or 1
    if square:isInARoom()~=true or(tonumber(exposure)or 1)>0 then
        return false,"stand in a currently safe interior at the intended destination"
    end
    local candidate={x=square:getX()+0.5,y=square:getY()+0.5,z=square:getZ(),safe=true,
        underground=square:getZ()<0,kind=square:getZ()<0 and"test-basement"or"test-region"}
    local known,err=migration.rememberDestination(alpha,candidate,"manual-test-observation")
    if not known then return false,err end
    print("[ProjectNightfall][AlphaMigrationTest] remembered destination at player location; add pressure to test seasonal initiation")
    return true,known
end

print("[ProjectNightfall][TestKit] Ready: PNTestKit(); PNTestPrepareStarvation(20); PNTestGiveEffigyParts('feral'); PNTestPlaceEffigy('human'); PNPerformanceStatus(); PNTestAlphaMigrationStatus()")

return TestKit
