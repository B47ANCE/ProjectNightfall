-- Pure per-region UV-score proposal. Stored score is both exposure burden and
-- Feral biological resource; persistent wound stage remains independent.
local Dose={}
local function nonnegative(value) return type(value)=="number" and value==value and value>=0 and value<math.huge end
local function fractionsValid(values)
    if type(values)~="table" then return false end
    local previous,count=0,0
    for key,value in pairs(values) do
        if type(key)~="number" or key<1 or key%1~=0 or not nonnegative(value) then return false end
        count=count+1
    end
    for index=1,count do
        local value=values[index]
        if not value or value<=previous or value>1 then return false end
        previous=value
    end
    return count>0
end
local function validProfile(profile)
    return type(profile)=="table" and nonnegative(profile.transmission) and profile.transmission<=1
        and nonnegative(profile.exposureFactor) and nonnegative(profile.capacity) and profile.capacity>0
        and nonnegative(profile.naturalCapFraction) and profile.naturalCapFraction<=1
        and fractionsValid(profile.thresholds)
end

-- Simultaneous source requests share remaining local capacity proportionally.
-- Natural storage is independently limited, so sunlight alone cannot cross the
-- configured destructive-stage ceiling. Existing higher artificial storage is
-- never clamped downward.
function Dose.propose(state,regions,incident,elapsedGameMinutes)
    if type(state)~="table" or type(regions)~="table" or type(incident)~="table"
        or not nonnegative(elapsedGameMinutes) then return nil,"invalid input" end
    if not nonnegative(incident.natural) or not nonnegative(incident.artificial) then return nil,"invalid irradiance" end
    for id in pairs(state) do if regions[id]==nil then return nil,"unmapped persisted region" end end
    local nextState,promotions,diagnostics={},{},{}
    local ids={};for id in pairs(regions) do
        if type(id)~="string" or id=="" then return nil,"invalid region identifier" end
        ids[#ids+1]=id
    end;table.sort(ids)
    for _,id in ipairs(ids) do
        local profile=regions[id]
        if not validProfile(profile) then return nil,"invalid region profile: "..id end
        local prior=state[id] or {naturalScore=0,artificialScore=0,woundStage=0}
        if type(prior)~="table" or not nonnegative(prior.naturalScore)
            or not nonnegative(prior.artificialScore) or not nonnegative(prior.woundStage)
            or prior.woundStage%1~=0 then return nil,"invalid regional state: "..id end
        local capacity=profile.capacity
        local priorTotal=prior.naturalScore+prior.artificialScore
        if not nonnegative(priorTotal) or priorTotal>capacity+0.000001 then return nil,"regional score exceeds capacity: "..id end
        local factor=profile.transmission*profile.exposureFactor
        local tissueNatural=incident.natural*factor
        local tissueArtificial=incident.artificial*factor
        local requestedNatural=math.min(tissueNatural*elapsedGameMinutes,
            math.max(0,capacity*profile.naturalCapFraction-prior.naturalScore))
        local requestedArtificial=tissueArtificial*elapsedGameMinutes
        if not nonnegative(requestedNatural+requestedArtificial) then return nil,"regional score overflow: "..id end
        local available=math.max(0,capacity-priorTotal)
        local requested=requestedNatural+requestedArtificial
        local scale=requested>available and available/requested or 1
        local naturalAdded=requestedNatural*scale
        local artificialAdded=requestedArtificial*scale
        local naturalScore=prior.naturalScore+naturalAdded
        local artificialScore=prior.artificialScore+artificialAdded
        local total=naturalScore+artificialScore
        local stage=prior.woundStage
        -- Stored biological fuel alone is not a fresh exposure event. Explicit
        -- repair or redistribution may leave score above the current wound
        -- threshold; darkness must not undo that repair on the next update.
        if elapsedGameMinutes>0 and tissueNatural+tissueArtificial>0 then
            local progressionFraction=total/capacity
            -- Historical artificial storage is fuel, not a currently active
            -- artificial source. Sun alone may not newly promote deep injury.
            if tissueArtificial<=0 then progressionFraction=math.min(progressionFraction,profile.naturalCapFraction) end
            for index,fraction in ipairs(profile.thresholds) do
                if progressionFraction>=fraction then stage=math.max(stage,index) end
            end
        end
        nextState[id]={naturalScore=naturalScore,artificialScore=artificialScore,woundStage=stage}
        diagnostics[id]={incidentNatural=incident.natural,incidentArtificial=incident.artificial,
            transmission=profile.transmission,exposureFactor=profile.exposureFactor,
            tissueIrradiance=tissueNatural+tissueArtificial,naturalAdded=naturalAdded,
            artificialAdded=artificialAdded,storedScore=total,capacity=capacity,
            scoreFraction=total/capacity,woundStage=stage}
        if stage>prior.woundStage then promotions[#promotions+1]={region=id,fromStage=prior.woundStage,toStage=stage} end
    end
    return nextState,promotions,diagnostics
end
return Dose
