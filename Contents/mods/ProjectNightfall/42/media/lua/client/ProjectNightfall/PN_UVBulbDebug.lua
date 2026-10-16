require "ProjectNightfall/PN_FlashlightBulbs"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.Debug = ProjectNightfall.Debug or {}

function ProjectNightfall.Debug.giveUVTestKit(playerNum)
    local player = getSpecificPlayer(playerNum or 0)
    if not player then return false end
    local inv = player:getInventory()
    inv:AddItem("Base.HandTorch")
    inv:AddItem("Base.GunLight")
    inv:AddItem("ProjectNightfall.LightBulbUV")
    inv:AddItem("ProjectNightfall.LightBulbUVHighOutput")
    inv:AddItem("Base.LightBulb")
    print("[ProjectNightfall][Debug] UV test kit added")
    return true
end
