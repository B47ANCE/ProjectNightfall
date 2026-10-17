local surfaces={
    {"../B47ANCEDKnowledgeAndWisdom/src/B47ANCEDKnowledgeAndWisdom/42/media/lua/client/B47ANCEDKnowledgeAndWisdom/TestHarness.lua","B47ANCEDKnowledgeAndWisdomTestStart"},
    {"../B47ANCEDKnowledgeAndWisdom/src/B47ANCEDKnowledgeAndWisdom/42/media/lua/shared/B47ANCEDKnowledgeAndWisdom/TestFixtures.lua",nil},
    {"../Project MORTIS/src/ProjectMORTIS/42/media/lua/client/Mortis/TestHarness.lua","mortisTestStart"},
    {"../B47ANCEDHealthCare/src/B47ANCEDHealthCare/42/media/lua/client/medWorks/TestHarness.lua","medWorksTestStart"},
    {"../B47ANCEDPower/src/B47ANCEDPower/42/media/lua/client/B47ANCEDPower/TestHarness.lua","B47ANCEDPowerTestStart"},
    {"../B47ANCEDSPXTRM/src/B47ANCEDSPXTRM/42/media/lua/client/lightWorks/lightWorks_TestHarness.lua","LWTestKit"},
    {"../B47ANCEDSPXTRM/src/B47ANCEDSPXTRM/42/media/lua/client/lightWorks/lightWorks_StageHarness.lua","lightWorksTestStart"},
    {"../B47ANCEDSPXTRM/src/B47ANCEDSPXTRM/42/media/lua/client/lightWorks/lightWorks_UVReactionPrototype.lua","LWUVBloodTest"},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_EcosystemTest.lua","PNReleaseTest"},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_GuidedTest.lua","PNTestStart"},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_TestKit.lua","PNTestKit"},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVBulbDebug.lua",nil},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVExposureMeter.lua","PNTestUVDayStart"},
    {"src/ProjectNightfall/42/media/lua/client/ProjectNightfall/PN_UVInspect.lua","PNTestUVInspect"},
}

isDebugEnabled=function() return false end
for _,surface in ipairs(surfaces) do
    local chunk,loadError=loadfile(surface[1])
    assert(chunk,loadError)
    local ok,result=pcall(chunk)
    assert(ok,surface[1]..": "..tostring(result))
    assert(type(result)=="table",surface[1].." did not return an inert table")
    if surface[2] then assert(rawget(_G,surface[2])==nil,surface[2].." leaked outside debug mode") end
end
print("release debug gates tests: OK")
