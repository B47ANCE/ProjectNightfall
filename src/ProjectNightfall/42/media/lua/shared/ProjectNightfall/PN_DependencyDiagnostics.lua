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

-- Structural API evidence only: no backend installation/readiness probe, player
-- resolution or ledger query. Host Lua's package.loaded is not a native contract.
-- Knowledge 0.17 private documents are independent of its broader guards.
local function capabilities(mortis,guard,knowledge)
    local result={status="UNKNOWN",issues={},foodTransactions="UNAVAILABLE",knowledgeStorage="UNKNOWN"}
    if type(mortis)=="table" and type(mortis.FoodSources)=="table" and mortis.FoodSources.TRANSACTION_VERSION==1 then
        result.foodTransactions="v1"
    else result.issues[#result.issues+1]="MORTIS food transaction v1 unavailable" end
    if guard==nil then
        local loaded,value=pcall(require,"B47ANCEDKnowledgeAndWisdom/AuthorityGuard")
        if loaded then guard=value end
    end
    if method(guard,"realm") and method(guard,"write") and method(guard,"characterRead") then
        local called,realm=pcall(guard.realm)
        result.realm=called and realm or "unknown"
        if called and (realm=="server" or realm=="client") then
            if method(knowledge,"_installKnowledgeBackend") then
                -- Presence supports the pinned 0.17 document contract, not an
                -- initialized backend or any particular character's permission.
                result.knowledgeStorage=realm=="server" and "PRIVATE_DOCUMENT_BACKEND_SUPPORTED" or "CLIENT_PROJECTION_SUPPORTED"
                result.issues[#result.issues+1]="Knowledge document readiness/identity not inspected"
            else
                result.knowledgeStorage="BLOCKED"
                result.issues[#result.issues+1]="MULTIPLAYER_STORAGE_UNAVAILABLE"
            end
        elseif called and realm=="sp" then
            local writeCalled,writable=pcall(guard.write)
            local readCalled,readable=pcall(guard.characterRead)
            if writeCalled and writable==true and readCalled and readable==true then
                result.knowledgeStorage="SP_SOURCE_PERMITTED"
            else result.issues[#result.issues+1]="Knowledge SP authority unavailable" end
        else result.issues[#result.issues+1]="Knowledge authority/capability requires review" end
    else result.issues[#result.issues+1]="Knowledge authority guard unavailable" end
    if result.knowledgeStorage=="BLOCKED" or result.foodTransactions=="UNAVAILABLE" then result.status="BLOCKED"
    elseif result.knowledgeStorage=="SP_SOURCE_PERMITTED" then
        result.status="SOURCE_CAPABILITIES_AVAILABLE"
    elseif result.knowledgeStorage=="CLIENT_PROJECTION_SUPPORTED" then result.status="PRESENTATION_ONLY" end
    return result
end

function Diagnostics.inspect(lightworks, powerworks, mortis, medworks, experienceworks, guard)
    local missing = {}
    local function need(ok, label) if not ok then missing[#missing + 1] = label end end
    need(type(lightworks)=="table", "lightWorks")
    need(method(lightworks,"registerBulb"), "lightWorks.registerBulb")
    need(method(lightworks,"UV","getSunlightExposure"), "lightWorks.UV.getSunlightExposure")
    need(method(lightworks,"UV","getArtificialExposure"), "lightWorks.UV.getArtificialExposure")
    need(type(powerworks)=="table", "B47ANCEDPower")
    need(method(powerworks,"registerLoad"), "B47ANCEDPower.registerLoad")
    need(type(mortis)=="table", "Project M.O.R.T.I.S.")
    need(method(mortis,"getTypeId"), "M.O.R.T.I.S. getTypeId")
    need(method(mortis,"Authority","canWriteCanonicalState"), "M.O.R.T.I.S. authority API")
    need(method(mortis,"ZombieHunger","getStarvationHours"), "M.O.R.T.I.S. hunger API")
    need(method(mortis,"ZombieHunger","getDrive"), "M.O.R.T.I.S. hunger-drive API")
    need(method(mortis,"negotiateAPI"), "M.O.R.T.I.S. compatibility API")
    if method(mortis,"negotiateAPI") then
        local called,compatible=pcall(mortis.negotiateAPI,{
            consumer="ProjectNightfall", minimum="1.6.0", maximumExclusive="2.0.0",
            required={
                ["Engine.takeTrackedBatch"]="function",
                ["ZombieHunger.getStarvationHours"]="function",
                ["ZombieHunger.getDrive"]="function",
                ["Groups.create"]="function",
                ["assign"]="function", ["clearAssignment"]="function",
                ["Anatomy.applyNutritionProfile"]="function",
                ["LocomotionOverrides.release"]="function",
                ["LocomotionOverrides.releaseCeiling"]="function",
                ["FoodSources.TRANSACTION_VERSION"]="number",
                ["registerFoodSourceProvider"]="function",
            },
        })
        need(called and compatible==true,"M.O.R.T.I.S. API version/surface incompatible")
    end
    need(type(mortis)=="table" and type(mortis.FoodSources)=="table"
        and mortis.FoodSources.TRANSACTION_VERSION==1,"M.O.R.T.I.S. food transaction v1")
    need(type(medworks)=="table", "medWorks")
    need(method(medworks,"getDetachedPartProvenance"), "medWorks detached-part API")
    need(method(medworks,"performProcedure"), "medWorks procedure API")
    need(type(experienceworks)=="table", "B47ANCEDKnowledgeAndWisdom")
    need(method(experienceworks,"registerDocument"), "B47ANCEDKnowledgeAndWisdom.registerDocument")
    need(method(experienceworks,"registerKnowledge"), "B47ANCEDKnowledgeAndWisdom.registerKnowledge")
    need(method(experienceworks,"hasKnowledgeDefinition"), "B47ANCEDKnowledgeAndWisdom.hasKnowledgeDefinition")
    need(method(experienceworks,"hasKnowledge"), "B47ANCEDKnowledgeAndWisdom.hasKnowledge")
    local readiness=capabilities(mortis,guard,experienceworks)
    if #missing>0 then
        readiness.status="BLOCKED"
        readiness.issues[#readiness.issues+1]="Required family API surface incomplete"
    end
    return #missing == 0, missing, {
        ProjectNightfall=version(ProjectNightfall),
        B47ANCEDKnowledgeAndWisdom=version(experienceworks),
        ProjectMORTIS=version(mortis),
        MortisAPI=version(mortis,"API_VERSION"),
        medWorks=version(medworks),
        B47ANCEDPower=version(powerworks),
        lightWorks=version(lightworks),
    }, readiness
end

function Diagnostics.report(lightworks, powerworks, mortis, medworks, experienceworks)
    local ok, missing, versions, readiness = Diagnostics.inspect(lightworks, powerworks, mortis, medworks, experienceworks)
    if ok then
        print(string.format("[ProjectNightfall][Dependencies] required family source API surface present (native NOT TESTED): ProjectNightfall=%s B47ANCEDKnowledgeAndWisdom=%s ProjectMORTIS=%s MORTIS_API=%s medWorks=%s B47ANCEDPower=%s lightWorks=%s",
            versions.ProjectNightfall,versions.B47ANCEDKnowledgeAndWisdom,versions.ProjectMORTIS,
            versions.MortisAPI,versions.medWorks,versions.B47ANCEDPower,versions.lightWorks))
    else
        print("[ProjectNightfall][Dependencies] ERROR incomplete required installation: " .. table.concat(missing, ", "))
    end
    print("[ProjectNightfall][Dependencies] source capability readiness="..readiness.status
        .." food="..readiness.foodTransactions.." knowledge="..readiness.knowledgeStorage
        .."; "..table.concat(readiness.issues,", ").."; native/dedicated NOT TESTED")
    return ok, missing, versions, readiness
end

return Diagnostics
