ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.DependencyDiagnostics = ProjectNightfall.DependencyDiagnostics or {}

local Diagnostics = ProjectNightfall.DependencyDiagnostics

local function version(root,field)
    local value=type(root)=="table" and root[field or "VERSION"] or nil
    return type(value)=="string" and value~="" and value or "unknown"
end

local function method(root, ...)
    local value = root
    for index = 1, select("#", ...) do
        value = type(value) == "table" and value[select(index, ...)] or nil
    end
    return type(value) == "function"
end

function Diagnostics.inspect(lightworks, powerworks, mortis, medworks, experienceworks)
    local missing = {}
    local function need(ok, label) if not ok then missing[#missing + 1] = label end end
    need(type(lightworks)=="table", "lightWorks")
    need(method(lightworks,"registerBulb"), "lightWorks.registerBulb")
    need(method(lightworks,"UV","getSunlightExposure"), "lightWorks.UV.getSunlightExposure")
    need(method(lightworks,"UV","getArtificialExposure"), "lightWorks.UV.getArtificialExposure")
    need(type(powerworks)=="table", "powerWorks")
    need(method(powerworks,"registerLoad"), "powerWorks.registerLoad")
    need(type(mortis)=="table", "Project M.O.R.T.I.S.")
    need(method(mortis,"getTypeId"), "M.O.R.T.I.S. getTypeId")
    need(method(mortis,"Authority","canWriteCanonicalState"), "M.O.R.T.I.S. authority API")
    need(method(mortis,"ZombieHunger","getStarvationHours"), "M.O.R.T.I.S. hunger API")
    need(method(mortis,"ZombieHunger","getDrive"), "M.O.R.T.I.S. hunger-drive API")
    need(method(mortis,"negotiateAPI"), "M.O.R.T.I.S. compatibility API")
    if method(mortis,"negotiateAPI") then
        local called,compatible=pcall(mortis.negotiateAPI,{
            consumer="ProjectNightfall", minimum="1.3.0", maximumExclusive="2.0.0",
            required={
                ["Engine.takeTrackedBatch"]="function",
                ["ZombieHunger.getStarvationHours"]="function",
                ["ZombieHunger.getDrive"]="function",
                ["Groups.create"]="function",
            },
        })
        need(called and compatible==true,"M.O.R.T.I.S. API version/surface incompatible")
    end
    need(type(medworks)=="table", "medWorks")
    need(method(medworks,"getDetachedPartProvenance"), "medWorks detached-part API")
    need(method(medworks,"performProcedure"), "medWorks procedure API")
    need(type(experienceworks)=="table", "experienceWorks")
    need(method(experienceworks,"registerDocument"), "experienceWorks.registerDocument")
    need(method(experienceworks,"registerKnowledge"), "experienceWorks.registerKnowledge")
    need(method(experienceworks,"hasKnowledgeDefinition"), "experienceWorks.hasKnowledgeDefinition")
    need(method(experienceworks,"hasKnowledge"), "experienceWorks.hasKnowledge")
    return #missing == 0, missing, {
        ProjectNightfall=version(ProjectNightfall),
        experienceWorks=version(experienceworks),
        ProjectMORTIS=version(mortis),
        MortisAPI=version(mortis,"API_VERSION"),
        medWorks=version(medworks),
        powerWorks=version(powerworks),
        lightWorks=version(lightworks),
    }
end

function Diagnostics.report(lightworks, powerworks, mortis, medworks, experienceworks)
    local ok, missing, versions = Diagnostics.inspect(lightworks, powerworks, mortis, medworks, experienceworks)
    if ok then
        print(string.format("[ProjectNightfall][Dependencies] required family APIs verified: ProjectNightfall=%s experienceWorks=%s ProjectMORTIS=%s MORTIS_API=%s medWorks=%s powerWorks=%s lightWorks=%s",
            versions.ProjectNightfall,versions.experienceWorks,versions.ProjectMORTIS,
            versions.MortisAPI,versions.medWorks,versions.powerWorks,versions.lightWorks))
    else
        print("[ProjectNightfall][Dependencies] ERROR incomplete required installation: " .. table.concat(missing, ", "))
    end
    return ok, missing, versions
end

return Diagnostics
