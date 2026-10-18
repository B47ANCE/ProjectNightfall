-- Bounded reads over vanilla square collections, without materializing all corpses.
-- Cursors are authority-local, weakly keyed by the currently loaded square.
local Corpse=require "Mortis/Runtime/Adapters/CorpseAdapter"
local Discovery={}
local methods={"getStaticMovingObjects","getMovingObjects","getObjects"}
local cursors=setmetatable({},{__mode="k"})
local function collection(square,method)
    local ok,value=pcall(function() return square[method](square) end)
    return ok and value or nil
end
local function size(list)
    if not list then return 0 end
    local ok,value=pcall(function() return list:size() end)
    if ok and type(value)=="number" and value>=0 then return math.floor(value) end
    return type(list)=="table" and #list or 0
end
local function get(list,index)
    local ok,value=pcall(function() return list:get(index) end)
    if ok then return value end
    return type(list)=="table" and list[index+1] or nil
end
function Discovery.visit(square,budget,visitor)
    if not square then return {},0 end
    local cursor=cursors[square] or {method=1,index=0};cursors[square]=cursor
    local result,read,switches={},0,0
    while read<budget and switches<#methods do
        local list=collection(square,methods[cursor.method])
        local count=size(list)
        if cursor.index>=count then
            cursor.index=0;cursor.method=cursor.method%#methods+1;switches=switches+1
        else
            local object=get(list,cursor.index);cursor.index=cursor.index+1;read=read+1
            if object and Corpse.isCorpse(object) then
                if visitor and visitor(object)==false then
                    -- Admission backpressure keeps the first waiting corpse at
                    -- this cursor instead of dropping it behind a full queue.
                    cursor.index=cursor.index-1
                    return result,read
                end
                result[#result+1]=object
            end
        end
    end
    return result,read
end
function Discovery.clear() cursors=setmetatable({},{__mode="k"}) end
return Discovery
