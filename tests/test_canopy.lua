ProjectNightfall = { Config = {
    POC = {
        EnableCanopyAttenuation = true,
        CanopyScanRadius = 2,
        CanopyTreeSizeWeight = 1,
        CanopyDistanceFalloff = 0.5,
        CanopyMaxAttenuation = 0.8,
        CanopyScoreForMaxAttenuation = 10,
    },
} }
package.loaded["ProjectNightfall/PN_Config"] = ProjectNightfall.Config

local modifier
lightWorks = { UV = {} }
function lightWorks.UV.registerExposureModifier(id, callback)
    assert(id == "ProjectNightfall.Canopy")
    modifier = callback
end
package.loaded["lightWorks/lightWorks_UV"] = lightWorks.UV

local squares = {}
local function square(x, y, treeSize)
    local sq = { x = x, y = y, z = 0 }
    function sq:getX() return self.x end
    function sq:getY() return self.y end
    function sq:getZ() return self.z end
    if treeSize then
        local tree = { size = treeSize }
        function tree:getSize() return self.size end
        function sq:getTree() return tree end
    end
    squares[x .. ":" .. y] = sq
    return sq
end

local origin = square(0, 0, 4)
square(1, 0, 2)
local cell = {}
function cell:getGridSquare(x, y) return squares[x .. ":" .. y] end
function getCell() return cell end

local Canopy = require "ProjectNightfall/PN_Canopy"
local result = Canopy.getLocalCanopy(origin)
assert(result.trees == 2)
assert(math.abs(result.score - 5) < 0.0001)
assert(math.abs(result.modifier - 0.6) < 0.0001)
assert(math.abs(modifier(nil, origin, 1) - 0.6) < 0.0001)
assert(modifier(nil, origin, 0) == 1)

print("Project Nightfall canopy attenuation checks passed")
