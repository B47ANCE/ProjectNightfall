local Mortis=require "Mortis/init"
local Util=require "Mortis/Core/Util"
require "ProjectNightfall/PN_MortisIntegration"

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.Effigies=ProjectNightfall.Effigies or {}
local Effigies=ProjectNightfall.Effigies
local Integration=ProjectNightfall.MortisIntegration
local FeralAI=require "ProjectNightfall/PN_FeralAI"
local CLASSIFIER="ProjectNightfall.sourceSignature"
local DATA_KEY="ProjectNightfallEffigy"
local BUCKET_SIZE=16
local MAX_PARTS=16
local entries,buckets={},{}
local sequence=0
local constructing=setmetatable({},{__mode="k"})
local eventErrorReported=false

local function hasEntries(value)
    for _ in pairs(value or {}) do return true end
    return false
end

local function finite(value)
    value=tonumber(value)
    if not value or value~=value or value==math.huge or value==-math.huge then return nil end
    return value
end

local function caloriesPerFullFeed()
    local config=ProjectNightfall.Config and ProjectNightfall.Config.POC
    return math.max(100,math.min(10000,finite(config and config.EffigyCaloriesPerFullFeed) or 2000))
end

local function canWrite(subject)
    local fn=Mortis.Authority and Mortis.Authority.canWriteCanonicalState
    if type(fn)~="function" then return false end
    local ok,allowed=pcall(fn,subject)
    return ok and allowed==true
end

local function safeCall(object,method,...)
    if not object then return nil end
    local ok,fn=pcall(function() return object[method] end)
    if not ok or type(fn)~="function" then return nil end
    local called,value=pcall(fn,object,...)
    if called then return value end
    return nil
end

local function position(object)
    if not object then return nil end
    local ok,x,y,z=pcall(function() return object:getX(),object:getY(),object:getZ() end)
    if not ok then return nil end
    x,y,z=finite(x),finite(y),finite(z) or 0
    if not x or not y then return nil end
    return x,y,z
end

local function bucketKey(x,y,z)
    return table.concat({math.floor(x/BUCKET_SIZE),math.floor(y/BUCKET_SIZE),math.floor(z)},":")
end

local function persist(entry)
    local object=entry.object
    if not object or not object.getModData then return false,"object has no modData" end
    local ok,data=pcall(function() return object:getModData() end)
    if not ok or type(data)~="table" then return false,"object modData unavailable" end
    data[DATA_KEY]={
        schemaVersion=1,id=entry.id,x=entry.x,y=entry.y,z=entry.z,
        composition=entry.composition,status=entry.status,claim=entry.claim,
        ownerStableId=entry.ownerStableId,ownerPlayerKey=entry.ownerPlayerKey,
        createdWorldAgeHours=entry.createdWorldAgeHours,
    }
    if object.transmitModData then pcall(function() object:transmitModData() end) end
    return true
end

local function index(entry)
    local key=bucketKey(entry.x,entry.y,entry.z)
    buckets[key]=buckets[key] or {}
    buckets[key][entry.id]=entry
    entry.bucketKey=key
    entries[entry.id]=entry
end

local function unindex(entry)
    if entry and entry.bucketKey and buckets[entry.bucketKey] then
        buckets[entry.bucketKey][entry.id]=nil
        if not hasEntries(buckets[entry.bucketKey]) then buckets[entry.bucketKey]=nil end
    end
    if entry then entries[entry.id]=nil end
end

local function ageHours()
    if type(getGameTime)~="function" then return 0 end
    local ok,value=pcall(function() return getGameTime():getWorldAgeHours() end)
    value=ok and finite(value) or nil
    return value and math.max(0,value) or 0
end

local VALID_SIGNATURE={human=true,regular=true,feral=true,smartFeral=true}
local function validateComposition(composition,minimumParts)
    if type(composition)~="table" or tonumber(composition.schemaVersion)~=1
        or not VALID_SIGNATURE[composition.signature] or type(composition.parts)~="table" then
        return nil,"invalid composition"
    end
    local count=finite(composition.partCount)
    if not count or count~=math.floor(count) or count<(minimumParts or 1) or count~=#composition.parts then
        return nil,"invalid composition part count"
    end
    if count>MAX_PARTS then return nil,"effigy part budget exceeded" end
    for _,part in ipairs(composition.parts) do
        if type(part)~="table" or type(part.regionId)~="string" or part.regionId==""
            or type(part.sourceStableId)~="string" or part.sourceStableId==""
            or part.signature~=composition.signature then return nil,"invalid composition part" end
        if part.materialRecord~=nil then
            local model=Mortis.DetachedMaterialModel
            local ok,valid=pcall(function() return model and model.validate(part.materialRecord) end)
            if not ok or valid~=true then return nil,"invalid detached material record" end
        end
    end
    return composition
end

local function signatureFromPart(item)
    local ok,record=pcall(function() return Mortis.DetachedParts and Mortis.DetachedParts.read(item) end)
    if not ok or type(record)~="table" or type(record.classifications)~="table" then return nil end
    local value=record and record.classifications and record.classifications[CLASSIFIER] or nil
    local signature=type(value)=="table" and value.signature or value
    if signature=="human" or signature=="regular" or signature=="feral" or signature=="smartFeral" then
        return signature,record
    end
    return nil
end

function Effigies.snapshotComposition(items)
    if type(items)~="table" or #items==0 then return nil,"at least one detached part required" end
    local signature,parts,seen=nil,{},{}
    for _,item in ipairs(items) do
        if seen[item] then return nil,"duplicate detached part" end
        seen[item]=true
        local current,record=signatureFromPart(item)
        if not current then return nil,"part has no recognized Nightfall provenance" end
        if signature and current~=signature then return nil,"mixed-source effigies are not supported" end
        signature=current
        parts[#parts+1]={
            schemaVersion=record.schemaVersion,regionId=record.regionId,
            speciesId=record.speciesId,sourceStableId=record.sourceStableId,
            sourceTypeId=record.sourceTypeId,signature=current,
            materialRecord=type(record.subtree)=="table" and Util.deepCopy(record) or nil,
        }
    end
    return {schemaVersion=1,signature=signature,partCount=#parts,parts=parts}
end

function Effigies.nutritionSnapshot(composition)
    local valid,err=validateComposition(composition,1);if not valid then return nil,err end
    local result={calories=0,carbohydrates=0,lipids=0,proteins=0,
        capacity=0,remaining=0,viable=0,edible=0,canonicalParts=0,legacyParts=0}
    for _,part in ipairs(valid.parts) do
        local record=part.materialRecord
        if record then
            local ok,totals=Mortis.DetachedMaterialModel.validate(record)
            if not ok then return nil,totals end
            result.canonicalParts=result.canonicalParts+1
            for _,key in ipairs({"capacity","remaining","viable","edible"}) do result[key]=result[key]+totals[key] end
            for _,key in ipairs({"calories","carbohydrates","lipids","proteins"}) do
                result[key]=result[key]+(totals.nutrition[key] or 0)
            end
        else result.legacyParts=result.legacyParts+1 end
    end
    return result
end

local function transactionToken(entry,index,regionIndex)
    local id=tostring(entry.id or "unknown"):gsub("[^%w_.-]","")
    if #id>64 then id=id:sub(#id-63) end
    return string.format("PN.EffigyFeed:%s:%d:%d",id,index,regionIndex)
end

function Effigies.consumeMaterial(entry)
    if type(entry)~="table" or entry.status~="claimed" or not entry.claim
        or entry.claim.action~="consume" then return nil,"effigy is not claimed for consumption" end
    local before,err=Effigies.nutritionSnapshot(entry.composition);if not before then return nil,err end
    if before.canonicalParts==0 then return {legacy=true,foodValue=.50,nutrition=before} end
    if before.edible<=0 then return nil,"effigy has no edible material" end
    local nextComposition=Util.deepCopy(entry.composition)
    for partIndex,part in ipairs(nextComposition.parts) do
        if part.materialRecord then
            local ids={};for id in pairs(part.materialRecord.subtree.regions) do ids[#ids+1]=id end;table.sort(ids)
            for regionIndex,id in ipairs(ids) do
                local material=part.materialRecord.subtree.regions[id].material
                if material.remaining>0 then
                    local nextRecord,receipt=Mortis.DetachedMaterialModel.applyLoss(part.materialRecord,id,{
                        transactionId=transactionToken(entry,partIndex,regionIndex),expectedRevision=material.revision,
                        remainingLoss=material.remaining,viableLoss=material.viable,edibleLoss=material.edible,
                        mechanism="feeding"})
                    if not nextRecord then return nil,receipt end
                    part.materialRecord=nextRecord
                end
            end
        end
    end
    local prior=entry.composition;entry.composition=nextComposition
    local saved,saveErr=persist(entry)
    if not saved then entry.composition=prior;return nil,saveErr end
    local value=before.calories>0 and before.calories/caloriesPerFullFeed() or before.edible/100
    return {legacy=false,foodValue=math.max(.01,math.min(1,value)),nutrition=before}
end

-- Shared read-only checks used by menus, queued actions and canonical execution.
-- getOutermostContainer is also used by vanilla ISWriteSomething for nested items.
function Effigies.checkConstructionKnowledge(character)
    local sandbox=rawget(_G,"SandboxVars")
    local values=type(sandbox)=="table" and sandbox.ProjectNightfall or nil
    local configured
    if type(values)=="table" then configured=values.RequireEffigyKnowledge end
    if configured==nil then
        local config=ProjectNightfall.Config and ProjectNightfall.Config.POC
        configured=config and config.RequireEffigyKnowledge
    end
    if configured==false then return true end
    local knowledge=rawget(_G,"B47ANCEDKnowledgeAndWisdom")
    if type(knowledge)~="table" or type(knowledge.hasKnowledge)~="function" then
        return false,"effigy knowledge API unavailable"
    end
    local ok,known=pcall(knowledge.hasKnowledge,character,"ProjectNightfall.EffigyConstruction")
    if not ok or known~=true then return false,"research NF-FIELD-026 is required to construct effigies" end
    return true
end

function Effigies.validateConstruction(character,items)
    local composition,err=Effigies.snapshotComposition(items)
    if not composition then return nil,err end
    if composition.partCount<3 then return nil,"three detached parts required" end
    local knowledgeable,knowledgeError=Effigies.checkConstructionKnowledge(character)
    if not knowledgeable then return nil,knowledgeError end
    local inventory=safeCall(character,"getInventory")
    if not inventory then return nil,"character inventory required" end
    local supported,methods=pcall(function() return type(inventory.AddItem)=="function" and type(inventory.Remove)=="function" and type(inventory.contains)=="function" end)
    if not supported or not methods then return nil,"inventory cannot support construction recovery" end
    for _,item in ipairs(items) do
        if constructing[item] then return nil,"detached part is already being used" end
        local container=safeCall(item,"getContainer")
        if not container or safeCall(container,"contains",item)~=true then
            return nil,"detached part is no longer available"
        end
        if container~=inventory and safeCall(item,"getOutermostContainer")~=inventory then
            return nil,"detached part must be in character inventory"
        end
        local ok,removable=pcall(function() return type(container.Remove)=="function" and type(container.AddItem)=="function" end)
        if not ok or not removable then return nil,"detached part container cannot support recovery" end
    end
    return composition
end

function Effigies.construct(character,items)
    if not canWrite(character) then return nil,"non-authority" end
    local composition,err=Effigies.validateConstruction(character,items)
    if not composition then return nil,err end
    local inventory=safeCall(character,"getInventory")
    if not inventory or not inventory.AddItem then return nil,"character inventory required" end
    -- Build off-inventory first. UseAndSync may irreversibly alter an item's
    -- state; Remove/AddItem retains the original objects for local rollback.
    local sources={}
    for _,item in ipairs(items) do sources[#sources+1]={item=item,container=safeCall(item,"getContainer")}; constructing[item]=true end
    local function release() for _,source in ipairs(sources) do constructing[source.item]=nil end end
    local ok,result=pcall(function() return instanceItem("ProjectNightfall.Effigy") end)
    local data=ok and safeCall(result,"getModData") or nil
    if not result or type(data)~="table" then release(); return nil,"could not create effigy" end
    data.ProjectNightfallEffigyComposition=composition
    data.ProjectNightfallEffigyOwnerPlayerKey=FeralAI.playerKey(character)
    local function rollback(reason)
        -- Remove any output before restoring inputs, including AddItem that
        -- inserted then threw. Never interpret a void return as success.
        local present=safeCall(inventory,"contains",result)
        if present==true then safeCall(inventory,"Remove",result) end
        if safeCall(inventory,"contains",result)~=false then
            release(); return nil,reason.."; output rollback could not be verified"
        end
        local recovered=true
        for _,source in ipairs(sources) do
            local remains=safeCall(source.container,"contains",source.item)
            if remains==false then safeCall(source.container,"AddItem",source.item) end
            if safeCall(source.container,"contains",source.item)~=true then recovered=false end
        end
        release()
        return nil,reason..(recovered and " (original parts restored)" or "; part recovery incomplete")
    end
    for _,source in ipairs(sources) do
        local removed=pcall(function() source.container:Remove(source.item) end)
        if not removed or safeCall(source.container,"contains",source.item)~=false then
            return rollback("could not remove detached part")
        end
    end
    local added=pcall(function() inventory:AddItem(result) end)
    if not added or safeCall(inventory,"contains",result)~=true then return rollback("could not insert effigy") end
    -- Only committed inventory changes are sent to clients. Replication failure
    -- must not return a retryable construction failure after parts were consumed.
    for _,source in ipairs(sources) do
        safeCall(character,"removeFromHands",source.item)
        if type(sendRemoveItemFromContainer)=="function" then pcall(sendRemoveItemFromContainer,source.container,source.item) end
    end
    if type(sendAddItemToContainer)=="function" then pcall(sendAddItemToContainer,inventory,result) end
    safeCall(result,"transmitModData")
    release()
    return result,composition
end


function Effigies.registerPlaced(object,composition,metadata)
    metadata=metadata or {}
    if not canWrite(object) then return nil,"non-authority" end
    local valid,compositionError=validateComposition(composition,3)
    if not valid then return nil,compositionError end
    local x,y,z=position(object)
    if not x then return nil,"effigy has no world position" end
    local existingData=safeCall(object,"getModData")
    local existing=type(existingData)=="table" and existingData[DATA_KEY] or nil
    local id=existing and existing.id or metadata.id
    if not id then
        sequence=sequence+1
        id=string.format("PN-E-%d-%d-%d-%d-%d",math.floor(x),math.floor(y),math.floor(z),math.floor(ageHours()*60),sequence)
    end
    if type(id)~="string" or id=="" or #id>256 then return nil,"invalid effigy id" end
    if entries[id] then return entries[id] end
    local entry={id=id,object=object,x=x,y=y,z=z,composition=composition,
        status="active",claim=nil,ownerStableId=metadata.ownerStableId,
        ownerPlayerKey=metadata.ownerPlayerKey,
        createdWorldAgeHours=ageHours()}
    index(entry)
    local ok,err=persist(entry)
    if not ok then unindex(entry); return nil,err end
    return entry
end

function Effigies.restorePlaced(object)
    if not object or not object.getModData then return nil,"object has no modData" end
    local data=safeCall(object,"getModData")
    local stored=type(data)=="table" and data[DATA_KEY] or nil
    if type(stored)~="table" or tonumber(stored.schemaVersion)~=1
        or type(stored.id)~="string" or stored.id=="" or #stored.id>256 then return nil,"no supported effigy state" end
    local composition,compositionError=validateComposition(stored.composition,3)
    if not composition then return nil,compositionError end
    if stored.status~="active" and stored.status~="claimed" then return nil,"effigy is not active" end
    if entries[stored.id] then return entries[stored.id] end
    local x,y,z=position(object)
    if not x then return nil,"effigy has no world position" end
    local entry={id=stored.id,object=object,x=x,y=y,z=z,composition=composition,
        status=stored.status or "active",claim=stored.claim,
        ownerStableId=stored.ownerStableId,ownerPlayerKey=stored.ownerPlayerKey,
        createdWorldAgeHours=stored.createdWorldAgeHours}
    index(entry)
    return entry
end

function Effigies.nearby(zombie,radius)
    local x,y,z=position(zombie)
    if not x then return {} end
    radius=math.max(1,math.min(256,finite(radius) or 20))
    local result,seen={},{}
    local bx1,bx2=math.floor((x-radius)/BUCKET_SIZE),math.floor((x+radius)/BUCKET_SIZE)
    local by1,by2=math.floor((y-radius)/BUCKET_SIZE),math.floor((y+radius)/BUCKET_SIZE)
    for bx=bx1,bx2 do for by=by1,by2 do
        local bucket=buckets[table.concat({bx,by,math.floor(z)},":")]
        if bucket then for id,entry in pairs(bucket) do
            if not seen[id] and entry.status=="active" then
                seen[id]=true
                local dx,dy=entry.x-x,entry.y-y
                local distanceSq=dx*dx+dy*dy
                if distanceSq<=radius*radius then result[#result+1]={entry=entry,distanceSq=distanceSq} end
            end
        end end
    end end
    table.sort(result,function(a,b) return a.distanceSq==b.distanceSq and a.entry.id<b.entry.id or a.distanceSq<b.distanceSq end)
    return result
end

function Effigies.claim(id,zombie,action)
    if not canWrite(zombie) then return false,"non-authority" end
    if type(action)~="string" or action=="" or #action>64 then return false,"invalid-action" end
    local entry=entries[id]
    if not entry or entry.status~="active" then return false,"not-active" end
    entry.status="claimed"
    entry.claim={action=action,claimantStableId=Mortis.getStableId(zombie),worldAgeHours=ageHours()}
    local persisted,reason=persist(entry)
    if not persisted then entry.status="active"; entry.claim=nil; return false,reason end
    return true,entry
end

function Effigies.completeClaim(id,outcome)
    local entry=entries[id]
    if not entry or entry.status~="claimed" then return false,"not-claimed" end
    if outcome~="consumed" and outcome~="destroyed" then return false,"invalid-outcome" end
    local previousStatus,previousClaim=entry.status,entry.claim
    entry.status=outcome
    local persisted,reason=persist(entry)
    if not persisted then entry.status=previousStatus; entry.claim=previousClaim; return false,reason end
    local object=entry.object
    if object then
        if object.removeFromWorld then pcall(function() object:removeFromWorld() end) end
        if object.removeFromSquare then pcall(function() object:removeFromSquare() end) end
    end
    unindex(entry)
    return true
end

function Effigies.findNearbyReaction(zombie,radius,config)
    for _,candidate in ipairs(Effigies.nearby(zombie,radius)) do
        local reaction=Effigies.reactionFor(zombie,candidate.entry.composition.signature,config)
        if reaction.action~="ignore" then return candidate.entry,reaction,candidate.distanceSq end
    end
    return nil
end

local function actorClass(zombie)
    local typeId=Integration.getTypeId(zombie)
    if typeId==Integration.TYPE_SMART_FERAL then return "smartFeral" end
    if typeId==Integration.TYPE_FERAL or typeId==Integration.TYPE_TRANSFORMING then return "feral" end
    local cognition=3
    if SandboxVars and SandboxVars.ZombieLore then cognition=tonumber(SandboxVars.ZombieLore.Cognition) or 3 end
    return cognition<=1 and "intelligentRegular" or "regular"
end

function Effigies.reactionFor(zombie,sourceSignature,config)
    config=config or (ProjectNightfall.Config and ProjectNightfall.Config.POC) or {}
    local actor=actorClass(zombie)
    if sourceSignature=="human" then
        local hungry=Mortis.ZombieHunger and Mortis.ZombieHunger.isHungry(zombie,
            tonumber(config.EffigyHumanEatHungerThreshold) or 0.25) or false
        return {actor=actor,action=hungry and "consume" or "attract",feeds=hungry}
    end
    if sourceSignature=="regular" then
        if actor=="feral" then return {actor=actor,action="consume",feeds=true} end
        if actor=="smartFeral" then return {actor=actor,action="destroy_search",searchHours=tonumber(config.EffigyRegularSearchHours) or 1} end
        if actor=="intelligentRegular" then return {actor=actor,action="destroy"} end
        return {actor=actor,action="ignore"}
    end
    if sourceSignature=="feral" then
        if actor=="smartFeral" then return {actor=actor,action="destroy_search",searchHours=tonumber(config.EffigyFeralSearchHours) or 24} end
        if actor=="feral" or actor=="intelligentRegular" then return {actor=actor,action="avoid"} end
        return {actor=actor,action="ignore"}
    end
    if sourceSignature=="smartFeral" then
        if actor=="smartFeral" then return {actor=actor,action="destroy_search",searchHours=tonumber(config.EffigySmartFeralSearchHours) or 72,enraged=true} end
        return {actor=actor,action="avoid"}
    end
    return {actor=actor,action="ignore",reason="unknown-source"}
end

if Mortis.FoodSources and not Mortis.FoodSources.has("ProjectNightfall.effigies") then
    Mortis.registerFoodSourceProvider({
        id="ProjectNightfall.effigies",priority=40,sourceClass="ProjectNightfall.effigy",
        findNearby=function(zombie,radius)
            local entry,reaction=Effigies.findNearbyReaction(zombie,radius)
            if not entry or (reaction.action~="consume" and reaction.action~="attract") then return nil end
            local nutrition=Effigies.nutritionSnapshot(entry.composition)
            local foodValue=nutrition and nutrition.canonicalParts>0
                and math.max(.01,math.min(1,nutrition.calories>0 and nutrition.calories/caloriesPerFullFeed() or nutrition.edible/100)) or .50
            return {x=entry.x,y=entry.y,z=entry.z,source=entry.object,sourceId=entry.id,
                sourceClass="ProjectNightfall.effigy",consumeDistance=1.25,foodValue=foodValue,
                reaction=reaction,signature=entry.composition.signature}
        end,
        consume=function(zombie,candidate)
            local reaction=Effigies.reactionFor(zombie,candidate.signature)
            if reaction.action~="consume" then return {consumed=false} end
            local claimed=Effigies.claim(candidate.sourceId,zombie,"consume")
            if not claimed then return {consumed=false} end
            local entry=entries[candidate.sourceId]
            local material,materialError=Effigies.consumeMaterial(entry)
            if not material then
                entry.status="active";entry.claim=nil;persist(entry)
                return {consumed=false,reason=materialError}
            end
            local completed=Effigies.completeClaim(candidate.sourceId,"consumed")
            return {consumed=completed==true,foodValue=material.foodValue,nutrition=material.nutrition}
        end,
    })
end

local function onObjectAdded(object)
    if not object then return end
    local data=safeCall(object,"getModData")
    if type(data)=="table" and type(data[DATA_KEY])=="table" then
        Effigies.restorePlaced(object)
        return
    end
    if not object.getItem then return end
    local ok,item=pcall(function() return object:getItem() end)
    if not ok or not item or not item.getFullType or item:getFullType()~="ProjectNightfall.Effigy" then return end
    local composition=item:getModData().ProjectNightfallEffigyComposition
    if composition then Effigies.registerPlaced(object,composition,{
        ownerPlayerKey=item:getModData().ProjectNightfallEffigyOwnerPlayerKey}) end
end
local function onObjectAddedSafe(object)
    local ok,reason=pcall(onObjectAdded,object)
    if not ok and not eventErrorReported then
        eventErrorReported=true
        pcall(print,"[ProjectNightfall][Effigies] incompatible world object skipped safely: "..tostring(reason))
    end
end
if Events and Events.OnObjectAdded then Events.OnObjectAdded.Add(onObjectAddedSafe) end

Effigies.CLASSIFIER_ID=CLASSIFIER
Effigies.DATA_KEY=DATA_KEY
return Effigies
