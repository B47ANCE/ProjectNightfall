local surfaces={
    {"../experienceWorks/src/experienceWorks/42/media/lua/client/experienceWorks/TestHarness.lua","experienceWorksTestStart"},
    {"../experienceWorks/src/experienceWorks/42/media/lua/shared/experienceWorks/TestFixtures.lua",nil},
    {"../Project MORTIS/src/ProjectMORTIS/42/media/lua/client/Mortis/TestHarness.lua","mortisTestStart"},
    {"../medWorks/src/medWorks/42/media/lua/client/medWorks/TestHarness.lua","medWorksTestStart"},
    {"../powerWorks/src/powerWorks/42/media/lua/client/powerWorks/TestHarness.lua","powerWorksTestStart"},
    {"../lightWorks/src/lightWorks/42/media/lua/client/lightWorks/lightWorks_TestHarness.lua","LWTestKit"},
    {"../lightWorks/src/lightWorks/42/media/lua/client/lightWorks/lightWorks_StageHarness.lua","lightWorksTestStart"},
    {"../lightWorks/src/lightWorks/42/media/lua/client/lightWorks/lightWorks_UVReactionPrototype.lua","LWUVBloodTest"},
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
