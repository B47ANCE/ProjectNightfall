local Tools={}
function Tools.add(F,root)
    ItemTag={HAMMER="hammer",SHARP_KNIFE="knife"}
    local result={}
    for _,kind in ipairs({"Base.Hammer","Base.KitchenKnife","Base.HandDrill"}) do
        local item=F.item('meat');item.foodType=nil;item.kind=kind
        function item:getFullType() return self.kind end
        function item:hasTag(tag) return tag==self.tag end
        item.tag=kind=="Base.Hammer" and ItemTag.HAMMER or kind=="Base.KitchenKnife" and ItemTag.SHARP_KNIFE or nil
        root:AddItem(item);result[#result+1]=item
    end
    return result
end
return Tools
