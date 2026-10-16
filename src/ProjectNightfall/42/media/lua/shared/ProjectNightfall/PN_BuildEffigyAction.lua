require "TimedActions/ISBaseTimedAction"
local Effigies=require "ProjectNightfall/PN_Effigies"

PN_BuildEffigyAction=ISBaseTimedAction:derive("PN_BuildEffigyAction")

function PN_BuildEffigyAction:isValid()
    return Effigies.validateConstruction(self.character,self.parts)~=nil
end

function PN_BuildEffigyAction:start()
    self:setActionAnim(CharacterActionAnims.Craft)
    self:setOverrideHandModels(nil,nil)
end

function PN_BuildEffigyAction:complete()
    local result=Effigies.construct(self.character,self.parts)
    return result~=nil
end

function PN_BuildEffigyAction:perform()
    ISBaseTimedAction.perform(self)
end

function PN_BuildEffigyAction:getDuration()
    if self.character and self.character.isTimedActionInstant and self.character:isTimedActionInstant() then return 1 end
    return 600
end

function PN_BuildEffigyAction:new(character,parts)
    local object=ISBaseTimedAction.new(self,character)
    object.character=character
    object.parts={}
    for index,item in ipairs(parts or {}) do object.parts[index]=item end
    object.maxTime=object:getDuration()
    object.caloriesModifier=4
    return object
end

return PN_BuildEffigyAction
