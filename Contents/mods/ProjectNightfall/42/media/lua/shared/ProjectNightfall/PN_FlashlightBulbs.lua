require "ProjectNightfall/PN_Config"

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.FlashlightBulbs = ProjectNightfall.FlashlightBulbs or {}

local PNFB = ProjectNightfall.FlashlightBulbs

local function uvVisibleColor()
    local color=lightWorks and lightWorks.UV_VISIBLE_COLOR or {r=0.00,g=0.00,b=1.00}
    return {r=color.r,g=color.g,b=color.b}
end

local function registerB47ANCEDPowerLoads()
    require "B47ANCEDPower/Definitions"
    local power=rawget(_G,"B47ANCEDPower")
    if not power or not power.registerLoad then return false end
    power.registerLoad({item="ProjectNightfall.LightBulbUV",provider="ProjectNightfall",consumptionMultiplier=1.25})
    power.registerLoad({item="ProjectNightfall.LightBulbUVHighOutput",provider="ProjectNightfall",consumptionMultiplier=2.0})
    return true
end

function PNFB.register()
    local lightWorks = lightWorks
    if not lightWorks or not lightWorks.registerBulb then
        print("[ProjectNightfall][UVBulbs] lightWorks unavailable; handheld UV bulb registration skipped")
        return false
    end

    -- UV output is mechanically independent of this visible violet spill.
    lightWorks.registerBulb({
        item = "ProjectNightfall.LightBulbUV",
        displayName = "UV Bulb",
        translationKey = "ItemName_ProjectNightfall.LightBulbUV",
        tags = {
            UV = true,
            PROJECT_NIGHTFALL = true,
        },
        visible = {
            strength = 0.70,
            distance = 9,
            torchCone = true,
            color = uvVisibleColor(),
        },
        burnout = {
            lifetimeMultiplier = 1.0,
        },
        emissions = {
            UV = { intensity = 1.0, range = 9.0, class = "STANDARD" },
        },
        custom = {
            uvClass = "STANDARD",
            uvStrength = 1.0,
            uvRange = 9.0,
            uvPowerMultiplier = 1.25,
            visibleDescription = "noticeable violet glow",
        },
    })

    -- High-output UV is mechanically stronger/farther but intentionally DIMMER
    -- to visible human vision.
    lightWorks.registerBulb({
        item = "ProjectNightfall.LightBulbUVHighOutput",
        displayName = "High-Output UV Bulb",
        translationKey = "ItemName_ProjectNightfall.LightBulbUVHighOutput",
        tags = {
            UV = true,
            PROJECT_NIGHTFALL = true,
            HIGH_OUTPUT = true,
        },
        visible = {
            strength = 0.30,
            distance = 6,
            torchCone = true,
            color = uvVisibleColor(),
        },
        burnout = {
            -- High-output hardware runs hotter / harder and is intentionally shorter-lived.
            lifetimeMultiplier = 0.70,
        },
        emissions = {
            UV = { intensity = 2.0, range = 14.0, class = "HIGH_OUTPUT" },
        },
        custom = {
            uvClass = "HIGH_OUTPUT",
            uvStrength = 2.0,
            uvRange = 14.0,
            uvPowerMultiplier = 2.0,
            visibleDescription = "faint violet glow",
        },
    })

    print("[ProjectNightfall][UVBulbs] Registered standard + high-output UV bulbs with lightWorks")
    if registerB47ANCEDPowerLoads() then
        print("[ProjectNightfall][UVBulbs] Registered B47ANCEDPower UV consumption loads")
    end
    return true
end

PNFB.register()
if Events and Events.OnGameStart then Events.OnGameStart.Add(registerB47ANCEDPowerLoads) end
if Events and Events.OnServerStarted then Events.OnServerStarted.Add(registerB47ANCEDPowerLoads) end
