local optionsPath, translationsPath, presetPath, noFeralsPath, configPath =
    assert(arg[1]), assert(arg[2]), assert(arg[3]), assert(arg[4]), assert(arg[5])

local function read(path)
    local handle = assert(io.open(path, "r"))
    local value = handle:read("*a")
    handle:close()
    return value
end

local function scalar(value)
    value = value:match("^%s*(.-)%s*$")
    if value == "true" then return true end
    if value == "false" then return false end
    return tonumber(value)
end

local optionsText = read(optionsPath)
local translationsText = read(translationsPath)
local configText = read(configPath)
local definitions = {}

for fullName, body in optionsText:gmatch("option%s+([%w_%.]+)%s*{(.-)}") do
    local namespace, name = fullName:match("^([%w_]+)%.([%w_]+)$")
    assert(namespace == "ProjectNightfall", "unexpected Nightfall sandbox namespace: " .. fullName)
    local definition = {
        default = scalar(assert(body:match("default%s*=%s*([^,]+)"), "missing default: " .. name)),
        minimum = scalar(body:match("min%s*=%s*([^,]+)") or ""),
        maximum = scalar(body:match("max%s*=%s*([^,]+)") or ""),
        translation = assert(body:match("translation%s*=%s*([%w_]+)"), "missing translation: " .. name),
    }
    assert(definition.default ~= nil, "unsupported sandbox default: " .. name)
    if type(definition.default) == "number" then
        assert(definition.minimum ~= nil and definition.maximum ~= nil, "numeric option lacks bounds: " .. name)
        assert(definition.default >= definition.minimum and definition.default <= definition.maximum,
            "default outside bounds: " .. name)
    end
    definitions[name] = definition
end

local count = 0
for name, definition in pairs(definitions) do
    count = count + 1
    local translationKey = '"Sandbox_' .. definition.translation .. '"'
    assert(translationsText:find(translationKey, 1, true), "missing English translation: " .. name)
    local mapped = configText:match("[%s,{]" .. name .. "%s*=") ~= nil
    if name == "EnableDiagnosticLogging" then
        mapped = configText:find("EnableDiagnosticLogging", 1, true) ~= nil
    end
    assert(mapped, "sandbox option is not consumed by PN_Config: " .. name)
end
assert(count > 0, "no Project Nightfall sandbox options parsed")

local apocalypse = { ZombieLore = {}, ZombieConfig = {} }
local realRequire = require
require = function(name)
    if name == "Sandbox/Apocalypse" then return apocalypse end
    return realRequire(name)
end
local preset = dofile(presetPath)
local noFerals = dofile(noFeralsPath)

for name, definition in pairs(definitions) do
    assert(preset.ProjectNightfall[name] ~= nil, "main preset omits option: " .. name)
    assert(preset.ProjectNightfall[name] == definition.default,
        "main preset differs from declared default: " .. name)
    assert(noFerals.ProjectNightfall[name] ~= nil, "No Ferals preset omits option: " .. name)
end

local allowedOverrides = {
    EnableFerals = true,
    EnableAutomaticSmartFeralPromotion = true,
    EnableAlphaFerals = true,
    EnableAlphaTerritories = true,
    EnableSmartFeralHordes = true,
    EnableSmartFeralCommunication = true,
    SmartFeralRawCognitionMax = true,
}
for name, value in pairs(noFerals.ProjectNightfall) do
    if value ~= preset.ProjectNightfall[name] then
        assert(allowedOverrides[name], "No Ferals preset unexpectedly changes: " .. name)
    end
end
assert(noFerals.ProjectNightfall.EnableFerals == false)
assert(noFerals.ProjectNightfall.EnableAlphaFerals == false)
assert(noFerals.ProjectNightfall.EnableAlphaTerritories == false)
assert(noFerals.ProjectNightfall.SmartFeralRawCognitionMax == 0)

-- Execute the real mapping, rather than merely finding option names in source.
SandboxVars = {ProjectNightfall = preset.ProjectNightfall}
Events = nil
ProjectNightfall = nil
dofile(configPath)
local config = ProjectNightfall.Config.POC
assert(config.UVUtilizationRanges.FERAL.minimum == .35)
assert(config.UVHealingWorkPerGameMinuteRanges.ALPHA_FERAL.maximum == 2)
assert(config.ArtificialUVTissueLossPerDose==.0005)
assert(config.RegionalUVTissuePolicy.default.artificialTissueLossPerDose==.0005)
SandboxVars.ProjectNightfall = {
    UVFeralUtilizationMin=.9, UVFeralUtilizationMax=.2,
    UVSmartFeralHealingMin=0, UVSmartFeralHealingMax=5,
    UVAlphaTransferEfficiency=2, UVSmartHealingTransferPerGameMinute=-1,
    UVAlphaTransferPerGameMinute=0/0,
    ArtificialUVTissueLossPerDose=.02,
}
ProjectNightfall.Config.applySandbox()
assert(config.UVUtilizationRanges.FERAL.minimum == .2)
assert(config.UVUtilizationRanges.FERAL.maximum == .9)
assert(config.UVHealingWorkPerGameMinuteRanges.SMART_FERAL.minimum == 0)
assert(config.UVHealingWorkPerGameMinuteRanges.SMART_FERAL.maximum == 5)
assert(config.UVAlphaTransferEfficiency == 1)
assert(config.UVSmartHealingTransferPerGameMinute == 0)
assert(config.UVAlphaTransferPerGameMinute == 4)
assert(config.ArtificialUVTissueLossPerDose==.01)
assert(config.RegionalUVTissuePolicy.default.artificialTissueLossPerDose==.01)
assert(config.UVRegenerationHardBlockFraction == .6)
print(("Project Nightfall sandbox contract checks passed (%d options)"):format(count))
