-- Real MORTIS provenance/material models, native item/container boundaries only.
next=nil -- Kahlua does not expose next; policy must not require it.
local Detached=require "Mortis/API/DetachedParts"
local Tissue=require "Mortis/Runtime/TissueModel"
local Material=require "Mortis/Runtime/DetachedMaterialModel"
local Util=require "Mortis/Core/Util"
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function item(foodType,bag)
    local data={}
    return {data=data,foodType=foodType,bag=bag==true,
        IsInventoryContainer=function(self) return self.bag end,
        getModData=function(self) return self.data end,
        getFoodType=function(self) return self.foodType end,
        getContainer=function() error("policy must not transfer") end,
        transmitModData=function() error("policy must not synchronize") end}
end
instanceof=function(object,class) return class=="Food" and object.foodType~=nil end
local function part(signature,source)
    local result=item(nil)
    assert(Detached.write(result,{schemaVersion=1,regionId="leftArm",speciesId="Mortis.Humanoid",
        sourceStableId=source or "source-a",classifications={
            ["ProjectNightfall.sourceSignature"]={schemaVersion=1,signature=signature}},
        subtree={schemaVersion=1,rootRegionId="leftArm",regions={leftArm={regionId="leftArm",
            material=assert(Tissue.new(10,{nutritionDensity={calories=20}}))}}}}))
    return result
end
local function container(items)
    local object={items=items or {},reads=0}
    function object:getItems()
        self.reads=self.reads+1
        return {size=function() return #self.items end,get=function(_,i) return self.items[i+1] end}
    end
    function object:AddItem() error("policy must not insert") end
    function object:Remove() error("policy must not remove") end
    return object
end
local signatures={"meat","human","regular","feral","smartFeral"}
local function candidate(category,source)
    return category=="meat" and item("Meat") or part(category,source)
end
local empty=container()
local state=assert(Policy.inspect(empty))
assert(state.visualState=="EMPTY" and state.category==nil and state.itemCount==0)
for _,category in ipairs(signatures) do
    local first=candidate(category,"one")
    local c=container({first})
    local before=Util.deepCopy(first.data)
    local view=assert(Policy.inspect(c))
    assert(view.category==category and view.itemCount==1)
    assert(view.visualState==(category=="meat" and "MEAT_LOADED" or "BODY_PART_LOADED"))
    assert(Policy.validateInsertion(c,{candidate(category,"another individual")}))
    for _,other in ipairs(signatures) do
        if category~=other then
            local valid,reason=Policy.validateInsertion(c,{candidate(other)})
            assert(not valid and reason=="mixed_categories",category.." mixed with "..other)
            assert(not Policy.validateInsertion(empty,{candidate(category),candidate(other)}),"batch order must not choose a category")
        end
    end
    assert(same(before,first.data),"inspection must preserve all metadata/material state")
    assert(#c.items==1 and c.items[1]==first)
    c.items={}
    assert(Policy.inspect(c).visualState=="EMPTY")
    assert(Policy.validateInsertion(c,{candidate(signatures[1])}),"last physical removal unlocks category")
end
-- Edible depletion does not make physical remains empty or change provenance.
local depleted=part("feral")
local record=assert(Detached.read(depleted))
record.subtree.regions.leftArm.material=assert(Tissue.new(10))
local nextRecord=assert(Material.applyLoss(record,"leftArm",{transactionId="deplete",expectedRevision=0,
    remainingLoss=10,viableLoss=10,edibleLoss=10,mechanism="feeding"}))
assert(Detached.write(depleted,nextRecord))
local bones=container({depleted})
assert(Policy.inspect(bones).visualState=="BODY_PART_LOADED")
assert(not Policy.validateInsertion(bones,{item("Meat")}))
-- Provenance takes priority even if an item also advertises meat metadata.
local spoof=part("regular");spoof.foodType="Meat"
assert(Policy.classify(spoof)=="regular")
for _,bad in ipairs({false,"unknown",{schemaVersion=2},
    {schemaVersion=1,classifications={}}, {schemaVersion=1,regionId="x",speciesId="s",sourceStableId="id",
    classifications={["ProjectNightfall.sourceSignature"]={schemaVersion=2,signature="human"}}}}) do
    local value=item("Meat");value.data[Detached.KEY]=bad
    assert(not Policy.classify(value),"invalid provenance must not downgrade to ordinary meat")
end
local broken=part("human");broken.data[Detached.KEY].subtree.regions.leftArm.material.remaining=-1
assert(not Policy.classify(broken))
local mismatch=part("human");mismatch.data[Detached.KEY].regionId="anotherRegion"
assert(not Policy.classify(mismatch))
local legacy=part("human");legacy.data[Detached.KEY].subtree=nil
assert(Policy.classify(legacy)=="human","supported legacy provenance need not invent tissue")
legacy.data[Detached.KEY].classifications["ProjectNightfall.sourceSignature"]="human"
assert(Policy.classify(legacy)=="human","supported historical string classification is preserved")
assert(not Policy.classify(item("Meat",true)),"bags cannot bypass admission")
assert(not Policy.classify(item("Fish")))
assert(not Policy.classify(item("Vegetables")))
assert(not Policy.classify(item(nil)))
local plain=item("Meat");local duplicate=container({plain})
assert(not Policy.validateInsertion(duplicate,{plain}))
assert(not Policy.validateInsertion(empty,{plain,plain}))
assert(not Policy.validateInsertion(empty,{}))
assert(not Policy.validateInsertion(empty,{[2]=plain}))
assert(not Policy.validateInsertion(empty,{plain,extra=plain}))
assert(not Policy.validateInsertion(empty,{0/0}))
assert(not Policy.inspect(container({item("Meat"),part("human")})))
assert(not Policy.inspect({getItems=function() error("unloaded container") end}))
assert(not Policy.inspect({getItems=function() return {size=function() return 1000000 end} end}))
assert(not Policy.inspect({getItems=function() return {size=function() return -1 end} end}))
local failing=item("Meat");failing.getModData=function() error("unavailable metadata") end
assert(not Policy.classify(failing))
local readFailure=container({plain});readFailure.getItems=function() return {size=function() return 1 end,get=function() return nil end} end
assert(not Policy.inspect(readFailure),"missing native element cannot look empty")
local changed=container({plain});local sizes=0
changed.getItems=function() return {size=function() sizes=sizes+1;return sizes end,get=function() return plain end} end
assert(not Policy.inspect(changed),"changing native collection must not yield a partial valid observation")
local provider=Detached.read;Detached.read=function() error("provider unavailable") end
assert(not Policy.classify(part("human")));Detached.read=provider
local key=Detached.KEY;Detached.KEY=nil
assert(not Policy.classify(item("Meat")),"unknown marker contract must fail closed")
Detached.KEY=key
-- Demonstrate the native queue hazard: per-item preflight against the same
-- empty state accepts both, while atomic batch validation correctly rejects it.
local human,feral=part("human"),part("feral")
assert(Policy.validateInsertion(empty,{human}) and Policy.validateInsertion(empty,{feral}))
assert(not Policy.validateInsertion(empty,{human,feral}))
empty.items={human} -- Simulated first commit; second must be checked again.
assert(not Policy.validateInsertion(empty,{feral}))
-- Inspection is available on clients but never authorizes any gameplay write.
isClient=function() return true end
assert(Policy.inspect(empty).category=="human")
assert(Policy.commit==nil and Policy.bind==nil and Policy.create==nil)
print("Effigy category restrictions, three states, corrupt/legacy data and queued-transfer boundary passed")
