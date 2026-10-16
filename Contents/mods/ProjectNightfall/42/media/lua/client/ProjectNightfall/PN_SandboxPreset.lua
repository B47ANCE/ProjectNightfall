require "OptionScreens/SandboxOptions"

-- The vanilla screen hardcodes built-in presets and otherwise lists only files
-- from the user's Sandbox Presets directory. Register the packaged game-file
-- preset explicitly so enabling Nightfall adds it to the same selector.
if SandboxOptionsScreen and not SandboxOptionsScreen._ProjectNightfallPresetWrapped then
    SandboxOptionsScreen._ProjectNightfallPresetWrapped = true
    local originalLoadPresets = SandboxOptionsScreen.loadPresets

    function SandboxOptionsScreen:loadPresets()
        originalLoadPresets(self)
        local found={}
        for _, preset in ipairs(self.presets or {}) do
            found[preset.name]=true
        end
        if not found.Nightfall then self:addPresetToList("Nightfall", "Project: Nightfall", false) end
        if not found.NightfallNoFerals then
            self:addPresetToList("NightfallNoFerals", "Project: Nightfall — No Ferals", false)
        end
    end
end
