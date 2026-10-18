-- Read-only recipe selection; canonical mutation lives in the server module.
require "ProjectNightfall/PN_Config"
local Knowledge=require "ProjectNightfall/PN_EffigyKnowledge"
local Frame=require "ProjectNightfall/PN_EffigyContainer"
local Recipe={MAX_ITEMS=256}
local ingredients={{type="Base.Log",key="EffigyFrameLogs",default=4,max=10},
    {type="Base.Rope",key="EffigyFrameRopes",default=2,max=10},
    {type="Base.Nails",key="EffigyFrameNails",default=8,max=40}}
function Recipe.costs()
    local c=ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC
    if not c or c.Enabled==false then return nil,"unavailable" end
    local result={}
    for _,ingredient in ipairs(ingredients) do
        local n=c[ingredient.key]
        if type(n)~="number" or n~=n or n%1~=0 or n<1 or n>ingredient.max then return nil,"invalid_configuration" end
        result[ingredient.type]=n
    end
    return result
end
function Recipe.available(player,item)
    local root=player and player:getInventory()
    return root and item and item:getContainer()==root and item:getWorldItem()==nil
        and root:getItemWithID(item:getID())==item and not player:isEquipped(item)
        and root:isRemoveItemAllowed(item)==true
end
function Recipe.select(player)
    local costs,reason=Recipe.costs();if not costs then return nil,reason end
    if not player or player:isDead() then return nil,"inaccessible" end
    local known=Knowledge.check(player)
    if not known then return nil,"research_required" end
    local root=player:getInventory();local list=root and root:getItems()
    if not list or list:size()>Recipe.MAX_ITEMS then return nil,"inspection_limit" end
    local result={}
    for i=0,list:size()-1 do
        local item=list:get(i);local kind=item:getFullType()
        if costs[kind] and costs[kind]>0 and Recipe.available(player,item) then
            result[#result+1]=item:getID();costs[kind]=costs[kind]-1
        end
    end
    for _,remaining in pairs(costs) do if remaining~=0 then return nil,"ingredients_required" end end
    return result
end
function Recipe.validate(player,ids)
    local costs,reason=Recipe.costs();if not costs then return nil,reason end
    if not player or player:isDead() then return nil,"inaccessible" end
    if not Knowledge.check(player) then return nil,"research_required" end
    if type(ids)~="table" then return nil,"invalid_request" end
    local count=0
    for k in pairs(ids) do
        count=count+1
        if count>Recipe.MAX_ITEMS or type(k)~="number" or k%1~=0 or k<1 or k>#ids then return nil,"invalid_request" end
    end
    if count==0 or count~=#ids then return nil,"invalid_request" end
    local root=player:getInventory();local actual,seen={},{}
    if not root or root:getItems():size()>Recipe.MAX_ITEMS then return nil,"inspection_limit" end
    for i,id in ipairs(ids) do
        if type(id)~="number" or id~=id or id%1~=0 or id< -2147483648 or id>2147483647 or id== -1 or seen[id] then return nil,"invalid_request" end
        seen[id]=true
        local item=root:getItemWithID(id)
        if not Recipe.available(player,item) then return nil,"item_unavailable" end
        local kind=item:getFullType()
        if not costs[kind] or costs[kind]<=0 then return nil,"ingredients_required" end
        costs[kind]=costs[kind]-1;actual[i]=item
    end
    for _,remaining in pairs(costs) do if remaining~=0 then return nil,"ingredients_required" end end
    return actual
end
function Recipe.frame(item)
    if not item or item:getFullType()~=Frame.FULL_TYPE or not item:IsInventoryContainer() then return nil end
    local container=item:getItemContainer()
    if not Frame.isClosed(container) then return nil end
    local record=item:getModData()[Frame.KEY]
    if record~=nil and (type(record)~="table" or record.schemaVersion~=1
        or type(record.revision)~="number" or record.revision~=record.revision
        or record.revision%1~=0 or record.revision<0 or record.revision>9007199254740990
        or record.quarantined~=nil or record.pendingFeed~=nil or record.pendingPlacement~=nil) then return nil end
    return container
end
return Recipe
