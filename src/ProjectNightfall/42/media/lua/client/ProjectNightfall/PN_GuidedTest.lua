-- Development-only guided validation harness.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

ProjectNightfall = ProjectNightfall or {}
ProjectNightfall.GuidedTest = ProjectNightfall.GuidedTest or {}

local Guided = ProjectNightfall.GuidedTest
local DATA_KEY = "ProjectNightfall.GuidedTest.v2"
local RESULT_FILE = "theWorks Test Results - ProjectNightfall.txt"
local steps = {
    {id="startup", text="Confirm all six required family mods load and the dependency diagnostic reports verified APIs."},
    {id="sandbox", text="Confirm both Nightfall presets appear; speed is Project: Nightfall, rally size is zero, canopy UV reduction defaults on, and cognition 0 disables Smart Ferals."},
    {id="natural_uv", text="Expose regular zombies to direct sun. Confirm slowing, a 50% health floor, knockdown, true fake-dead hibernation, clothing retention, and no mass deaths."},
    {id="hibernation", text="Approach hibernators. Confirm wake/crawl is very rare within 2-3 tiles and they give up and hibernate again at 5-7 tiles."},
    {id="rise", text="Reach nightfall. Confirm staggered rise, rapid full-health recovery, and no zombies remain stuck prone or crawling."},
    {id="no_ferals", text="Using No Ferals, confirm hibernators rise as regular zombies. Using the main preset, confirm only starvation-qualified zombies become Ferals."},
    {id="artificial_uv", text="Use standard and high-output UV in handheld, attached, weapon, and placed lights. Confirm pure-blue rendering, lethal tissue damage, wall/floor occlusion, and stronger overlapping exposure."},
    {id="regional_uv", text="Illuminate zombies wearing different coverage, damage clothing, and run PNTestUVInspect(zombie). Confirm per-region protection, exposed-hole transmission, localized tissue loss, wound progression, movement consequences, and no sunlight lethality."},
    {id="corpse_uv", text="Kill an infected by any cause, illuminate the corpse with artificial UV, then run PNTestUVCorpseInspect(nil,12). Confirm it is marked, protected regions degrade more slowly, tissue/remains stage and smoke semantics advance, sunlight does not destroy tissue, darkness does not backfill damage, and loot/cause remain intact."},
    {id="effigies", text="Run PNTestGiveResearch() and PNTestGiveEffigyParts('feral'). On an unlearned character, select all three parts: construction must show a research requirement. Read NF-UV-003 then NF-FIELD-026; check PNTestResearchStatus(), then build. Confirm cancellation consumes nothing, mixed sources are rejected, placement persists, and reactions match the source matrix."},
    {id="ferals", text="Confirm Ferals are bald/clean-shaven, seek shelter, sprint rarely, drain reserve while sprinting, and stop after at most five game minutes from full reserve."},
    {id="smart_ferals", text="Confirm Smart Ferals sprint only for ambush/flank/evasion and exercise stalking, hiding, grudges, communication, and personal-horde behavior."},
    {id="crowd_flow", text="Pack zombies through a house entrance during UV hours and confirm early entrants continue deeper to make room."},
    {id="save_reload", text="Save/reload during hibernation and after Feral creation. Confirm phase, health, reserve, appearance, starvation eligibility, rise schedule, and bulb state persist."},
    {id="stress", text="Run at very-high population, shove and trip near a pile, then check PNTestStatus() and console.txt for errors, repeated failures, or stalls."},
}

local function player()
    return (getSpecificPlayer and getSpecificPlayer(0)) or (getPlayer and getPlayer()) or nil
end

local function session(create)
    local p=player(); if not p or not p.getModData then return nil end
    local root=p:getModData()
    if create and type(root[DATA_KEY])~="table" then root[DATA_KEY]={index=1,results={},commands={},startedAt=tostring(os and os.date and os.date("!%Y-%m-%dT%H:%M:%SZ") or "unavailable")} end
    return root[DATA_KEY]
end

local function reportLines(s)
    local counts={PASS=0,FAIL=0,SKIP=0,PENDING=0}
    local output={"theWorks in-game test results","Mod: Project Nightfall","Mod ID: ProjectNightfall",
        "Mod version: "..tostring(ProjectNightfall.VERSION or "0.28.0"),"Started: "..tostring(s.startedAt or "unavailable"),
        "Dependencies enabled for this stage: B47ANCEDKnowledgeAndWisdom, ProjectMORTIS, medWorks, B47ANCEDPower, lightWorks","","FEATURE RESULTS"}
    for index,step in ipairs(steps) do
        local result=s.results[step.id] or {status="PENDING",note=""}; counts[result.status]=(counts[result.status] or 0)+1
        output[#output+1]=string.format("%02d. [%s] %s | %s",index,result.status,step.id,tostring(result.note or ""):gsub("[\r\n]+"," "))
    end
    output[#output+1]=""; output[#output+1]=string.format("SUMMARY pass=%d fail=%d blocked/skipped=%d pending=%d",counts.PASS,counts.FAIL,counts.SKIP,counts.PENDING)
    output[#output+1]="SKIP means BLOCKED/PENDING evidence, never PASS."
    return output,counts
end

local function writeReport(s)
    if type(getFileWriter)~="function" then return false,"getFileWriter unavailable" end
    local ok,err=pcall(function()
        local writer=getFileWriter(RESULT_FILE,true,false); if not writer then error("writer unavailable") end
        local output=reportLines(s)
        for _,line in ipairs(output) do if type(writer.writeln)=="function" then writer:writeln(line) else writer:write(line.."\n") end end
        if type(writer.close)=="function" then writer:close() end
    end)
    return ok,err
end

local function show(s)
    local step=steps[s.index]
    if not step then return Guided.report() end
    print(string.format("[ProjectNightfall][GuidedTest] STEP %d/%d [%s] %s",s.index,#steps,step.id,step.text))
    print('[ProjectNightfall][GuidedTest] Record with PNTestPass(), PNTestFail("issue"), or PNTestSkip("reason").')
    return step
end

local function record(status,note)
    local s=session(false); if not s then return false,"no active session" end
    local step=steps[s.index]; if not step then return false,"session complete" end
    s.results[step.id]={status=status,note=tostring(note or "")}
    print(string.format("[ProjectNightfall][GuidedTest] RESULT %s=%s %s",step.id,status,tostring(note or "")))
    s.index=s.index+1
    writeReport(s)
    show(s)
    return true
end

function Guided.start(reset)
    local p=player(); if not p then return false,"player unavailable" end
    if reset then p:getModData()[DATA_KEY]=nil end
    local s=session(true)
    print("[ProjectNightfall][GuidedTest] Session started; results persist on this character.")
    writeReport(s)
    show(s)
    return true
end

function Guided.report()
    local s=session(false); if not s then return false,"no active session" end
    local counts={PASS=0,FAIL=0,SKIP=0,PENDING=0}
    print("[ProjectNightfall][GuidedTest] REPORT BEGIN")
    for _,step in ipairs(steps) do
        local result=s.results[step.id] or {status="PENDING",note=""}
        counts[result.status]=(counts[result.status] or 0)+1
        print(string.format("[ProjectNightfall][GuidedTest] %s=%s %s",step.id,result.status,result.note or ""))
    end
    print(string.format("[ProjectNightfall][GuidedTest] SUMMARY pass=%d fail=%d skip=%d pending=%d",counts.PASS,counts.FAIL,counts.SKIP,counts.PENDING))
    print("[ProjectNightfall][GuidedTest] REPORT END")
    local saved,err=writeReport(s)
    if saved then print("[ProjectNightfall][GuidedTest] Results saved to Zomboid/Lua/"..RESULT_FILE)
    else print("[ProjectNightfall][GuidedTest] Result export unavailable: "..tostring(err)) end
    return true,counts
end

function Guided.where()
    print("[ProjectNightfall][GuidedTest] Windows result file: %USERPROFILE%\\Zomboid\\Lua\\"..RESULT_FILE)
    return RESULT_FILE
end

function PNTestStart(reset) return Guided.start(reset==true) end
function PNTestPass(note) return record("PASS",note) end
function PNTestFail(note) return record("FAIL",note) end
function PNTestSkip(note) return record("SKIP",note) end
function PNTestReport() return Guided.report() end
function PNTestWhere() return Guided.where() end

print("[ProjectNightfall][GuidedTest] Ready: PNTestStart(true)")
return Guided
