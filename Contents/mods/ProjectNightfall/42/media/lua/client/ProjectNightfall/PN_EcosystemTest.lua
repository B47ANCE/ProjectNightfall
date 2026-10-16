-- Development-only cross-mod test coordinator.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

ProjectNightfall=ProjectNightfall or {}
ProjectNightfall.EcosystemTest=ProjectNightfall.EcosystemTest or {}
local Test=ProjectNightfall.EcosystemTest

local function log(message) print("[theWorks][Test] "..tostring(message)) end

local function beginNightfall(reset)
    if type(PNTestStart)=="function" then
        log("Starting Project Nightfall guided session")
        return PNTestStart(reset==true)
    end
    log("Project Nightfall guided runner unavailable")
    return false
end

local function prepare(reset)
    if type(PNTestKit)=="function" then PNTestKit(reset==true) else log("Nightfall test kit unavailable") end
    if type(PNTestStatus)=="function" then PNTestStatus() end
    if type(MORTISInspect)=="function" then MORTISInspect() else log("M.O.R.T.I.S. inspection unavailable") end
end

local function beginitjustWorks(reset)
    if type(itjustWorksTestStart)=="function" then
        if type(itjustWorksOnTestComplete)=="function" then
            itjustWorksOnTestComplete(function()
                log("itjustWorks guided session complete")
                beginNightfall(reset)
            end)
        end
        log("Starting itjustWorks guided session")
        return itjustWorksTestStart(true,reset==true)
    end
    log("itjustWorks guided runner unavailable")
    return false
end

function Test.start(reset)
    log("MASS TEST BEGIN")
    prepare(reset)

    local lightworksReady=type(LWStartReleaseSuite)=="function"
    if lightworksReady and type(LWOnTestTourComplete)=="function" then
        LWOnTestTourComplete(function()
            log("lightWorks visual tour complete")
            beginitjustWorks(reset)
        end)
        local started=LWStartReleaseSuite()
        if started then
            log("lightWorks release suite started; remaining guided suites will follow in order")
            return true
        end
        log("lightWorks suite did not start; continuing to itjustWorks")
    elseif lightworksReady then
        LWRunIntegrationTests()
        log("lightWorks completion hook unavailable; continuing to itjustWorks")
    else
        log("lightWorks release suite unavailable; continuing to itjustWorks")
    end
    return beginitjustWorks(reset)
end

-- Nightfall's release closure deliberately excludes optional QoL/UI modules.
-- This runner sequences only the required lightWorks visual suite and the
-- Nightfall guided suite after preparing dependency diagnostics and fixtures.
function Test.startNightfallRelease(reset)
    log("NIGHTFALL RELEASE TEST BEGIN")
    prepare(reset)
    local lightworksReady=type(LWStartReleaseSuite)=="function"
    if lightworksReady and type(LWOnTestTourComplete)=="function" then
        LWOnTestTourComplete(function()
            log("lightWorks visual tour complete")
            beginNightfall(reset)
        end)
        local started=LWStartReleaseSuite()
        if started then
            log("lightWorks release suite started; Nightfall guided validation will follow")
            return true
        end
        log("lightWorks suite did not start; continuing to Nightfall")
    elseif lightworksReady and type(LWRunIntegrationTests)=="function" then
        LWRunIntegrationTests()
        log("lightWorks completion hook unavailable; continuing to Nightfall")
    else
        log("lightWorks release suite unavailable; continuing to Nightfall")
    end
    return beginNightfall(reset)
end

theWorksMassTest=function(reset) return Test.start(reset==true) end
PNReleaseTest=function(reset) return Test.startNightfallRelease(reset==true) end
print("[theWorks][Test] Ready: PNReleaseTest(true); theWorksMassTest(true)")
return Test
