-- Development-only UV inspection commands.
if type(isDebugEnabled)=="function" and isDebugEnabled()~=true then return {} end

-- Explicit SP debug inspection, not an automatic zombie scan or damage hook.
function PNTestCombatInspect(zombie,quiet)
    local ok,result=pcall(function()
        if (type(isClient)=="function" and isClient()) or (type(isServer)=="function" and isServer()) then
            error("combat inspection is currently single-player only")
        end
        if not zombie then error("pass a zombie object") end
        local State=require "Mortis/Runtime/Adapters/StateAdapter"
        local report={state=State.snapshot(zombie),canWalk=State.getCanWalk(zombie),variables={}}
        for _,name in ipairs({"AttackType","AttackOutcome","ZombieBiteDone","PlayerHitReaction"}) do
            local value,reason=State.getVariable(zombie,name)
            report.variables[name]={value=value,unavailable=reason}
        end
        if not quiet then
            print("[ProjectNightfall][CombatInspect] Native snapshot only; no attack/animation changes")
            print("[ProjectNightfall][CombatInspect] state="..tostring(report.state.nativeState)
                .." crawler="..tostring(report.state.crawling).." canWalk="..tostring(report.canWalk))
            for _,name in ipairs({"AttackType","AttackOutcome","ZombieBiteDone","PlayerHitReaction"}) do
                local entry=report.variables[name]
                print("[ProjectNightfall][CombatInspect] "..name.."="..tostring(entry.value)
                    ..(entry.unavailable and " (unavailable)" or ""))
            end
        end
        return report
    end)
    if not ok then
        if not quiet then print("[ProjectNightfall][CombatInspect] Unavailable: "..tostring(result)) end
        return nil,tostring(result)
    end
    return result
end

function PNTestUVInspect(zombie,windowTransmission,quiet)
    local ok,result=pcall(function()
        if (type(isClient)=="function" and isClient()) or (type(isServer)=="function" and isServer()) then
            error("UV inspection command is currently single-player only")
        end
        if not zombie then error("pass a zombie object, e.g. getCell():getZombieList():get(0)") end
        local UV=require "lightWorks/lightWorks_UV"
        local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
        local Protection=require "ProjectNightfall/PN_UVProtection"
        local Diagnostics=require "ProjectNightfall/PN_UVDiagnostics"
        local anatomy,reason=Anatomy.get(zombie)
        if not anatomy then error(reason) end
        local policy={regions={},resolveTransmission=assert(Protection.compile(Protection.defaults()))}
        for id in pairs(anatomy.regions) do policy.regions[id]={exposureFactor=1} end
        local emitters,seen={},{}
        local truncated=false
        local function add(list)
            if type(list)~="table" then error("emitter collector unavailable") end
            for index,emitter in ipairs(list) do
                if index>128 then truncated=true; break end
                if type(emitter)~="table" then error("invalid emitter record") end
                local key=emitter.item or emitter.owner or emitter
                if not seen[key] then
                    if #emitters>=64 then truncated=true; break end
                    seen[key]=true; emitters[#emitters+1]=emitter
                end
            end
        end
        local player=type(getPlayer)=="function" and getPlayer()
        if player then add(UV.collectPlayerEmitters(player)) end
        add(UV.collectWorldEmitters(zombie,16))
        local exposure=UV.getVerifiedExposure(zombie,emitters,{windowTransmission=windowTransmission})
        if truncated then exposure.uv.complete=false end
        local report,err=Diagnostics.inspect(zombie,exposure,policy)
        if not report then error(err) end
        if not quiet then
        print("[ProjectNightfall][UVInspect] READ ONLY; provisional protection; local-player + world lights within 16 tiles")
        print("[ProjectNightfall][UVInspect] Collector limits may omit distant/other-player lights; this is not a full-world measurement")
        for _,line in ipairs(Diagnostics.lines(report)) do print("[ProjectNightfall][UVInspect] "..line) end
        for _,layer in ipairs(report.layers) do
            local parts={}
            for part,coverage in pairs(layer.parts) do
                parts[#parts+1]=part.." hole="..tostring(coverage.hole)
            end
            table.sort(parts)
            print("[ProjectNightfall][UVInspect] "..layer.itemType.." fabric="..tostring(layer.fabricType).." "..table.concat(parts,", "))
        end
        end
        return report
    end)
    if not ok then
        if not quiet then print("[ProjectNightfall][UVInspect] Unavailable: "..tostring(result)) end
        return nil,tostring(result)
    end
    return result
end

-- Explicit bounded SP inspection. Passing nil selects the nearest marked
-- infected corpse; it never discovers or enrolls an ordinary corpse.
function PNTestUVCorpseInspect(corpse,radius,quiet)
    local ok,result=pcall(function()
        if (type(isClient)=="function" and isClient()) or (type(isServer)=="function" and isServer()) then
            error("UV corpse inspection is currently single-player only")
        end
        local Corpse=require "Mortis/Runtime/Adapters/CorpseAdapter"
        local Entity=require "Mortis/Runtime/Adapters/EntityAdapter"
        local player=type(getPlayer)=="function" and getPlayer() or nil
        radius=math.max(0,math.min(25,tonumber(radius) or 12))
        if not corpse then
            local square=player and player:getCurrentSquare()
            local cell=type(getCell)=="function" and getCell() or nil
            if not square or not cell then error("player/world unavailable") end
            local best,bestDistance=nil,nil
            for dx=-radius,radius do for dy=-radius,radius do
                if dx*dx+dy*dy<=radius*radius then
                    local candidateSquare=cell:getGridSquare(square:getX()+dx,square:getY()+dy,square:getZ())
                    for _,candidate in ipairs(Corpse.onSquare(candidateSquare)) do
                        local md=Entity.getModData(candidate);local marker=md and md.PN_UVCorpse
                        if type(marker)=="table" and marker.schemaVersion==1 and marker.infected==true then
                            local distance=dx*dx+dy*dy
                            if bestDistance==nil or distance<bestDistance then best,bestDistance=candidate,distance end
                        end
                    end
                end
            end end
            corpse=best
        end
        if not corpse or not Corpse.isCorpse(corpse) then error("no marked infected corpse in inspection radius") end
        local data=Entity.getModData(corpse);local marker=data and data.PN_UVCorpse
        if type(marker)~="table" or marker.schemaVersion~=1 or marker.infected~=true then error("corpse is not Nightfall-marked infected") end
        local Anatomy=require "Mortis/Runtime/AnatomyRuntime"
        local Policy=require "ProjectNightfall/PN_UVTissuePolicy"
        local Diagnostics=require "ProjectNightfall/PN_UVDiagnostics"
        require "ProjectNightfall/PN_Config"
        local anatomy,anatomyError=Anatomy.get(corpse);if not anatomy then error(anatomyError) end
        local policy,policyError=Policy.compile(anatomy,ProjectNightfall.Config.POC.RegionalUVTissuePolicy)
        if not policy then error(policyError) end
        local artificial=ProjectNightfall.ArtificialUV
        local emitters=artificial and artificial.getCurrentEmitters(corpse) or {}
        local UV=require "lightWorks/lightWorks_UV"
        local exposure=UV.getVerifiedExposure(corpse,emitters,{cell=getCell and getCell() or nil})
        local now=nil;pcall(function() now=getGameTime():getWorldAgeHours()*60 end)
        local report,reportError=Diagnostics.inspect(corpse,exposure,policy,now,"corpse")
        if not report then error(reportError) end
        report.marker={deathMinute=marker.deathMinute,lastProcessMinute=marker.lastProcessMinute,speciesId=marker.speciesId}
        report.remains=select(1,require("ProjectNightfall/PN_UVRemainsState").inspect(corpse))
        if not quiet then
            print("[ProjectNightfall][UVCorpseInspect] READ ONLY; nearest search radius="..tostring(radius))
            for _,line in ipairs(Diagnostics.lines(report)) do print("[ProjectNightfall][UVCorpseInspect] "..line) end
            local remains=report.remains
            print("[ProjectNightfall][UVCorpseInspect] stage="..tostring(remains and remains.stage or "not initialized")
                .." deathMinute="..tostring(marker.deathMinute).." lastProcess="..tostring(marker.lastProcessMinute))
        end
        return report
    end)
    if not ok then
        if not quiet then print("[ProjectNightfall][UVCorpseInspect] Unavailable: "..tostring(result)) end
        return nil,tostring(result)
    end
    return result
end
