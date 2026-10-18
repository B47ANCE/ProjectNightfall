local Detached=require "Mortis/API/DetachedParts"
local Tissue=require "Mortis/Runtime/TissueModel"
local F={}
local serial=0
function F.item(category)
    serial=serial+1
    local item={id=serial,md={},weight=1,foodType=category=="meat" and "Meat" or nil}
    function item:getModData() return self.md end
    function item:getID() return self.id end
    function item:getContainer() return self.container end
    function item:getWorldItem() return self.world end
    function item:IsInventoryContainer() return false end
    function item:getFoodType() return self.foodType end
    function item:getUnequippedWeight() return self.weight end
    function item:getName() return 'item '..self.id end
    function item:getAge() return self.age or 0 end
    function item:getCondition() return self.condition or 100 end
    if category~="meat" then
        assert(Detached.write(item,{schemaVersion=1,regionId="leftArm",speciesId="Mortis.Humanoid",
            sourceStableId="source"..serial,classifications={
                ["ProjectNightfall.sourceSignature"]={schemaVersion=1,signature=category}},
            subtree={schemaVersion=1,rootRegionId="leftArm",regions={leftArm={regionId="leftArm",
                material=assert(Tissue.new(10,{nutritionDensity={calories=20}}))}}}}))
    end
    return item
end
function F.container()
    local c={items={},capacity=20}
    function c:getItems() return {size=function() return #self.items end,get=function(_,i) return self.items[i+1] end} end
    function c:getItemWithID(id) for _,item in ipairs(self.items) do if item.id==id then return item end end end
    function c:isRemoveItemAllowed() return not self.noRemove end
    function c:getOnlyAcceptCategory() return self.category end
    function c:getAcceptItemFunction() return self.filter end
    function c:setCapacity(n) self.capacity=n end
    function c:hasRoomFor(_,weight)
        local total=weight
        for _,item in ipairs(self.items) do total=total+item.weight end
        return total<=self.capacity
    end
    function c:AddItem(item)
        if self.failAdd then error('injected add failure') end
        if self:getItemWithID(item.id) then return nil end
        -- Native AddItem calls the previous container's Remove only after its
        -- duplicate-ID check. Calling Remove separately before Add is unsafe.
        if item.container then item.container:Remove(item) end
        self.items[#self.items+1]=item;item.container=self
        if self.onAdd then self.onAdd(item) end
        return item
    end
    function c:Remove(item)
        if self.failRemove then error('injected remove failure') end
        for i,other in ipairs(self.items) do if other==item then table.remove(self.items,i);item.container=nil;return end end
    end
    return c
end
function F.world()
    local Frame=require "ProjectNightfall/PN_EffigyContainer"
    local square={x=10,y=10,z=0}
    function square:getX() return self.x end
    function square:getY() return self.y end
    function square:getZ() return self.z end
    function square:isBlockedTo() return self.blocked==true end
    function square:isWindowTo() return self.window==true end
    local object={square=square}
    local frame=F.item('meat');frame.foodType=nil;frame.contents=F.container()
    local script=assert(io.open('src/ProjectNightfall/42/media/scripts/ProjectNightfall_Effigies.txt','r'))
    local definition=script:read('*a'):match('item%s+EffigyFrame%s*{(.-)}');script:close()
    assert(definition:match('ItemType%s*=%s*base:container'))
    frame.contents.category=assert(definition:match('OnlyAcceptCategory%s*=%s*([^,%s]+)'))
    frame.contents.filter=assert(definition:match('AcceptItemFunction%s*=%s*([^,%s]+)'))
    function frame.contents:isItemAllowed(item)
        if self.category and self.category~=(item.category or (item.foodType and 'Food' or 'Item')) then return false end
        local callback=_G[self.filter]
        if callback then return callback(self,item)==true end
        return true
    end
    function frame:getFullType() return Frame.FULL_TYPE end
    function frame:IsInventoryContainer() return true end
    function frame:getWorldItem() return self.world end
    function frame:getItemContainer() return self.contents end
    frame.world=object
    function object:getItem() return frame end
    function object:getSquare() return self.square end
    function object:flagForHotSave() self.saveRequests=(self.saveRequests or 0)+1 end
    local objects={object}
    function square:getWorldObjects() return {size=function() return #objects end,get=function(_,i) return objects[i+1] end} end
    local source=F.container()
    local player={square=square,inventory=source}
    function player:getCurrentSquare() return self.square end
    function player:getInventory() return self.inventory end
    function player:isDead() return self.dead==true end
    function player:isEquipped(item) return item.equipped==true end
    getCell=function() return {getGridSquare=function(_,x,y,z) if x==10 and y==10 and z==0 then return square end end} end
    return player,object,frame,source,frame.contents,objects
end
function F.install()
    isClient=function() return false end;isServer=function() return true end
    instanceof=function(item,class) return class=='Food' and item.foodType~=nil end
    SafeHouse={isSafehouseAllowLoot=function() return true end}
    F.packets={};F.replies={};F.handlers={}
    sendRemoveItemFromContainer=function(container,item) F.packets[#F.packets+1]={'remove',container,item} end
    sendAddItemToContainer=function(container,item) F.packets[#F.packets+1]={'add',container,item} end
    sendServerCommand=function(_,_,_,reply) F.replies[#F.replies+1]=reply end
    Events={OnClientCommand={Add=function(fn) F.handlers[#F.handlers+1]=fn end}}
end
return F
