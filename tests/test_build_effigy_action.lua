CharacterActionAnims={Craft="Craft"}
ISBaseTimedAction={}
function ISBaseTimedAction:derive() local child={}; setmetatable(child,{__index=self}); return child end
function ISBaseTimedAction.new(class,character)
    return setmetatable({character=character,setActionAnim=function()end,setOverrideHandModels=function()end},{__index=class})
end
function ISBaseTimedAction.perform() end
local constructed=false
local Effigies={
    validateConstruction=function(_,parts)
        if #parts<3 then return nil end
        for _,item in ipairs(parts) do if not item:getContainer() then return nil end end
        return {partCount=#parts}
    end,
    construct=function(_,parts) constructed=#parts==3 return constructed and {} or nil end,
}
local realRequire=require
require=function(name)
    if name=="TimedActions/ISBaseTimedAction" then return ISBaseTimedAction end
    if name=="ProjectNightfall/PN_Effigies" then return Effigies end
    return realRequire(name)
end
local Action=dofile(assert(arg[1]))
local parts={{getContainer=function()return {} end},{getContainer=function()return {} end},{getContainer=function()return {} end}}
local action=Action:new({isTimedActionInstant=function()return false end},parts)
assert(action:isValid() and action:getDuration()==600)
assert(action.parts~=parts and action.parts[1]==parts[1])
assert(action:complete()==true and constructed)
parts[1].getContainer=function() return nil end
assert(action:isValid()==false)
print("Project Nightfall effigy timed-action checks passed")
