-- Read-only quotes over actual items. These plans are ephemeral, never another
-- saved nutrient store. A meal uses one meat item or one part's edible tissue.
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local Detached=require "Mortis/API/DetachedParts"
local Material=require "Mortis/Runtime/DetachedMaterialModel"
local Plan={}
local nutrients={"calories","carbohydrates","lipids","proteins"}
function Plan.finite(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end
function Plan.same(a,b,seen)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    seen=seen or {};if seen[a] then return seen[a]==b end;seen[a]=b
    for k,v in pairs(a) do if not Plan.same(v,b[k],seen) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
function Plan.foodSnapshot(item)
    local values={}
    for _,key in ipairs(nutrients) do
        local value=item["get"..key:sub(1,1):upper()..key:sub(2)](item)
        if not Plan.finite(value) or value<0 then return nil end
        values[key]=value
    end
    return values
end
function Plan.create(t,calibration,preview)
    if not Plan.finite(calibration) or calibration<100 or calibration>10000 then return nil end
    local state=Policy.inspect(t.container)
    if not state or state.itemCount==0 then return nil end
    local list=t.container:getItems();local items,seen={},{}
    for i=0,list:size()-1 do
        local item=list:get(i);local id=item:getID()
        if not Plan.finite(id) or id%1~=0 or id==-1 or seen[id]
            or item:getContainer()~=t.container or item:getWorldItem()~=nil then return nil end
        seen[id]=true;items[#items+1]=item
    end
    table.sort(items,function(a,b) return a:getID()<b:getID() end)
    for _,item in ipairs(items) do
        local p={item=item,itemId=item:getID(),category=state.category,
            beforeAge=item:getAge(),beforeCondition=item:getCondition()}
        if state.category=="meat" then
            p.kind="meat";p.nutrition=Plan.foodSnapshot(item)
        else
            p.kind="part";p.before=Detached.read(item)
            local valid,totals=Material.validate(p.before)
            if valid then
                p.nutrition=totals.nutrition
                -- Discovery quotes nutrition only; stage region transitions
                -- once a real reservation exists, outside the hot search path.
                if not preview then
                    p.after=p.before;p.stages={};p.requests={}
                    local regions={};for id in pairs(p.before.subtree.regions) do regions[#regions+1]=id end
                    table.sort(regions)
                    for index,id in ipairs(regions) do
                        local tissue=p.after.subtree.regions[id].material
                        if tissue.edible>0 then
                            local request={transactionId=table.concat({"PN.FrameFeed",t.frame:getID(),
                                string.format("%.0f",t.record.revision),p.itemId,index},":"),
                                expectedRevision=tissue.revision,remainingLoss=tissue.edible,
                                viableLoss=tissue.edible,edibleLoss=tissue.edible,mechanism="feeding"}
                            local nextRecord=Material.applyLoss(p.after,id,request)
                            if not nextRecord then return nil end
                            p.after=nextRecord;p.stages[#p.stages+1]=nextRecord
                            p.requests[#p.requests+1]={region=id,request=request}
                        end
                    end
                end
            end
        end
        local valid=p.nutrition~=nil
        for _,key in ipairs(nutrients) do
            local value=p.nutrition and p.nutrition[key]
            if not Plan.finite(value) or value<0 then valid=false end
        end
        if valid and p.nutrition.calories>0
            and Plan.finite(p.beforeAge) and Plan.finite(p.beforeCondition) then
            p.foodValue=p.nutrition.calories/calibration
            if Plan.finite(p.foodValue) and p.foodValue>0 then return p end
        end
    end
end
function Plan.matches(p,container,after)
    if p.item:getID()~=p.itemId or p.item:getContainer()~=container or p.item:getWorldItem()~=nil
        or container:getItemWithID(p.itemId)~=p.item or Policy.classify(p.item)~=p.category
        or p.item:getAge()~=p.beforeAge or p.item:getCondition()~=p.beforeCondition then return false end
    if p.kind=="meat" then return Plan.same(Plan.foodSnapshot(p.item),p.nutrition) end
    return Plan.same(Detached.read(p.item),after and p.after or p.before)
end
return Plan
