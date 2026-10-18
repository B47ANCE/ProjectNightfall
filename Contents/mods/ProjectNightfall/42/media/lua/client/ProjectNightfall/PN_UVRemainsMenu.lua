-- Local presentation of an already synchronized stage; no anatomy/world scans.
local Menu={}
local stages={"INTACT","SCORCHED","DESICCATED","CRITICAL","RESIDUAL"}
local labels={"Intact","Scorched","Desiccated","Severe breakdown","Residual tissue"}
local descriptions={
    "Little UV tissue breakdown is recorded.",
    "Early UV tissue breakdown is recorded.",
    "Substantial UV tissue breakdown is recorded.",
    "Most UV-affected tissue has broken down.",
    "Only residual tissue remains.",
}
local function enabled()
    local root=rawget(_G,"SandboxVars")
    local sandbox=type(root)=="table" and root.ProjectNightfall
    if type(sandbox)=="table" and sandbox.Enabled~=nil then return sandbox.Enabled~=false end
    local pn=rawget(_G,"ProjectNightfall")
    local config=pn and pn.Config and pn.Config.POC
    return not config or config.Enabled~=false
end
function Menu.getView(corpse)
    if not corpse then return nil end
    local ok,view=pcall(function()
        local data=corpse:getModData()
        if type(data)~="table" then return nil end
        local marker,record=data.PN_UVCorpse,data.PN_UVRemainsState
        if type(marker)~="table" or marker.schemaVersion~=1 or marker.infected~=true
            or type(record)~="table" or record.schemaVersion~=1 then return nil end
        local index=record.stageIndex
        if type(index)~="number" or index~=index or index%1~=0 or index<1 or index>#stages
            or stages[index]~=record.stage then return nil end
        return {stage=stages[index],index=index}
    end)
    return ok and view or nil
end
local function tr(key,fallback,value)
    if type(getText)=="function" then
        local ok,text
        if value==nil then ok,text=pcall(getText,key) else ok,text=pcall(getText,key,value) end
        if ok and type(text)=="string" and text~="" and text~=key then return text end
    end
    return value and fallback:gsub("%%1",function() return value end) or fallback
end
function Menu.fill(player,context,worldobjects,test)
    if not enabled() then return end
    local native=rawget(_G,"ISWorldObjectContextMenu")
    local corpse=native and native.fetchVars and native.fetchVars.body
    local view=Menu.getView(corpse)
    if not view or not context then return end
    if test then
        if type(native.setTest)=="function" then return native.setTest() end
        return
    end
    -- Context panels are pooled: inspect this opening's options, not a sticky panel flag.
    for _,option in ipairs(context.options or {}) do
        if option.ProjectNightfallRemainsInfo then return end
    end
    local stageLabel=tr("ContextMenu_ProjectNightfall_Remains_"..view.stage,labels[view.index])
    local title=tr("ContextMenu_ProjectNightfall_RemainsCondition","UV remains: %1",stageLabel)
    local option=context:addOption(title,nil,nil)
    if not option then return end
    option.ProjectNightfallRemainsInfo=true;option.notAvailable=true
    if type(native.addToolTip)=="function" then
        local tooltip=native.addToolTip()
        if tooltip then
            if type(tooltip.setVisible)=="function" then tooltip:setVisible(false) end
            if type(tooltip.setName)=="function" then tooltip:setName(title) end
            tooltip.description=tr("ContextMenu_ProjectNightfall_Remains_"..view.stage.."_Description",descriptions[view.index])
            option.toolTip=tooltip
        end
    end
end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Menu.fill) end
ProjectNightfall=ProjectNightfall or {};ProjectNightfall.UVRemainsMenu=Menu
return Menu
