-- Project Nightfall's UV-survival rules without Feral or Smart Feral outcomes.
-- Clone the main preset so loading either packaged preset cannot mutate the
-- other's cached Lua table.
local function copy(value)
    if type(value)~="table" then return value end
    local result={}
    for key,entry in pairs(value) do result[key]=copy(entry) end
    return result
end

local preset=copy(require "Sandbox/Nightfall")
preset.ProjectNightfall.EnableFerals=false
preset.ProjectNightfall.EnableAutomaticSmartFeralPromotion=false
preset.ProjectNightfall.EnableAlphaFerals=false
preset.ProjectNightfall.EnableAlphaTerritories=false
preset.ProjectNightfall.EnableSmartFeralHordes=false
preset.ProjectNightfall.EnableSmartFeralCommunication=false
preset.ProjectNightfall.SmartFeralRawCognitionMax=0
return preset
