-- Read-only foundation. No native transfer binding, world object, persistence,
-- renderer or food source is enabled: queued native transfers do not revalidate
-- category at commit in the inspected build. A successful preview is NOT a lease.
local Detached=require "Mortis/API/DetachedParts"
local Material=require "Mortis/Runtime/DetachedMaterialModel"
local Policy={}
local CLASSIFIER="ProjectNightfall.sourceSignature"
local SIGNATURES={human=true,regular=true,feral=true,smartFeral=true}
-- Technical work ceiling, not storage capacity or gameplay balance. Refuse an
-- oversized inventory rather than truncate it and accidentally report EMPTY.
local MAX_INSPECTION_ITEMS=256

local function read(object,name)
    local ok,method=pcall(function() return object[name] end)
    if not ok or type(method)~="function" then return nil,false end
    local called,value=pcall(method,object)
    return value,called
end

local function nonempty(value)
    return type(value)=="string" and value~=""
end

function Policy.classify(item)
    if type(item)~="table" and type(item)~="userdata" then return nil,"item_unreadable" end
    if not nonempty(Detached.KEY) then return nil,"provenance_provider_unavailable" end
    local bag,readable=read(item,"IsInventoryContainer")
    if not readable or type(bag)~="boolean" then return nil,"item_unreadable" end
    if bag then return nil,"nested_container" end
    local data,available=read(item,"getModData")
    if not available or type(data)~="table" then return nil,"item_unreadable" end
    if data[Detached.KEY]~=nil then
        -- Never fall back to a meat tag when detached provenance is malformed,
        -- unknown, from a future schema or cannot be read by its owning API.
        local ok,record=pcall(Detached.read,item)
        if not ok or type(record)~="table" or record.schemaVersion~=1
            or not nonempty(record.regionId) or not nonempty(record.sourceStableId)
            or not nonempty(record.speciesId) or type(record.classifications)~="table" then
            return nil,"unsupported_provenance"
        end
        local classification=record.classifications[CLASSIFIER]
        local signature=classification
        if type(classification)=="table" then
            if classification.schemaVersion~=1 then return nil,"unsupported_provenance" end
            signature=classification.signature
        end
        if type(signature)~="string" or not SIGNATURES[signature] then return nil,"unsupported_provenance" end
        if record.subtree~=nil then
            if type(record.subtree)~="table" or record.subtree.rootRegionId~=record.regionId then
                return nil,"invalid_material"
            end
            local validated,valid=pcall(Material.validate,record)
            if not validated or valid~=true then return nil,"invalid_material" end
        end
        return signature
    end
    -- This deliberately recognizes only native FoodType Meat. It does not
    -- guess from names, accept Fish/other foods, or invent ordinary-meat effects.
    local ok,food=pcall(function() return type(instanceof)=="function" and instanceof(item,"Food") end)
    if not ok or food~=true then return nil,"unsupported_item" end
    local foodType,known=read(item,"getFoodType")
    if not known then return nil,"item_unreadable" end
    if foodType~="Meat" then return nil,"unsupported_item" end
    return "meat"
end

local function state(category,count)
    return {category=category,itemCount=count,
        visualState=count==0 and "EMPTY" or category=="meat" and "MEAT_LOADED" or "BODY_PART_LOADED"}
end

local function fold(items,count,category,seen)
    for index=1,count do
        local item=items[index]
        if type(item)~="table" and type(item)~="userdata" then return nil,"item_unreadable" end
        if seen[item] then return nil,"duplicate_item" end
        seen[item]=true
        local current,reason=Policy.classify(item)
        if not current then return nil,reason end
        if category and category~=current then return nil,"mixed_categories" end
        category=current
    end
    return state(category,count)
end

local function contents(container)
    local list,readable=read(container,"getItems")
    if not readable or not list then return nil,"container_unreadable" end
    local count,known=read(list,"size")
    if not known or type(count)~="number" or count~=count or count<0 or count%1~=0 then
        return nil,"container_unreadable"
    end
    if count>MAX_INSPECTION_ITEMS then return nil,"inspection_limit" end
    local items={}
    for index=1,count do
        local ok,item=pcall(function() return list:get(index-1) end)
        if not ok or item==nil then return nil,"container_unreadable" end
        items[index]=item
    end
    -- Providers may become unloaded/change during a read. Never return a
    -- partial inventory as a valid category or empty-container observation.
    local after,stable=read(list,"size")
    if not stable or after~=count then return nil,"container_changed" end
    return items,count
end

function Policy.inspect(container)
    local items,count=contents(container)
    if not items then return nil,count end
    return fold(items,count,nil,{})
end

local function batchSize(items)
    if type(items)~="table" then return nil,"invalid_batch" end
    local count,largest=0,0
    for key in pairs(items) do
        count=count+1
        if count>MAX_INSPECTION_ITEMS then return nil,"inspection_limit" end
        if type(key)~="number" or key~=key or key<1 or key%1~=0 then return nil,"invalid_batch" end
        largest=math.max(largest,key)
    end
    if count==0 or largest~=count then return nil,"invalid_batch" end
    return count
end

function Policy.validateInsertion(container,candidates)
    local added,reason=batchSize(candidates)
    if not added then return nil,reason end
    local items,count=contents(container)
    if not items then return nil,count end
    if count+added>MAX_INSPECTION_ITEMS then return nil,"inspection_limit" end
    local seen={}
    local before,errorCode=fold(items,count,nil,seen)
    if not before then return nil,errorCode end
    local proposed
    proposed,errorCode=fold(candidates,added,before.category,seen)
    if not proposed then return nil,errorCode end
    proposed.itemCount=count+added
    proposed.addedCount=added
    proposed.beforeCategory=before.category
    proposed.beforeCount=count
    -- Caller must repeat validation within a proven authoritative transfer
    -- transaction. This preview proves no ownership, reach, capacity or commit.
    return proposed
end

return Policy
