local Discovery=require "ProjectNightfall/PN_CorpseDiscovery"
local reads=0
local bodies={}
for i=1,10000 do bodies[i]={getObjectName=function() return "DeadBody" end} end
local list={size=function() return #bodies end,get=function(_,i) reads=reads+1;return bodies[i+1] end}
local square={getStaticMovingObjects=function() return list end}
local seen={}
for update=1,1300 do
    local before=reads
    local found,count=Discovery.visit(square,8)
    assert(count<=8 and reads-before<=8)
    for _,body in ipairs(found) do seen[body]=true end
end
for _,body in ipairs(bodies) do assert(seen[body],"later crowded-square entries must be reached") end
-- Shrinking/reordered native collections and absent collection methods stay bounded.
bodies={bodies[1]}
for _=1,4 do local _,count=Discovery.visit(square,8);assert(count<=8) end
Discovery.clear()
local found=Discovery.visit(square,8,function() return false end)
assert(#found==0)
found=Discovery.visit(square,8,function() return true end)
assert(found[1]==bodies[1],"backpressure must retry the exact waiting corpse")
print("Nightfall bounded native corpse collection discovery passed")
