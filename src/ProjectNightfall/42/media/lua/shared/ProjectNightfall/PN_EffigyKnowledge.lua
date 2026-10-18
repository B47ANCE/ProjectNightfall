-- One read-only research gate for legacy effigies and reusable frames.
require "ProjectNightfall/PN_Config"
local Knowledge={}
function Knowledge.check(character)
    local sandbox=rawget(_G,"SandboxVars")
    local values=type(sandbox)=="table" and sandbox.ProjectNightfall or nil
    local configured
    if type(values)=="table" then configured=values.RequireEffigyKnowledge end
    if configured==nil then
        local config=ProjectNightfall.Config and ProjectNightfall.Config.POC
        configured=config and config.RequireEffigyKnowledge
    end
    if configured==false then return true end
    local knowledge=rawget(_G,"B47ANCEDKnowledgeAndWisdom")
    if type(knowledge)~="table" or type(knowledge.hasKnowledge)~="function" then
        return false,"effigy knowledge API unavailable"
    end
    local ok,known=pcall(knowledge.hasKnowledge,character,"ProjectNightfall.EffigyConstruction")
    if not ok or known~=true then return false,"research NF-FIELD-026 is required to construct effigies" end
    return true
end

return Knowledge
