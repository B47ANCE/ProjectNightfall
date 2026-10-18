local Recipe=require "ProjectNightfall/PN_EffigyFrameRecipe"
local Knowledge=require "ProjectNightfall/PN_EffigyKnowledge"
local Menu={MODULE="ProjectNightfallEffigyFrame"}
local function tr(key,...)
    return getText("ContextMenu_ProjectNightfall_Frame"..key,...)
end
function Menu.result(module,command,args)
    if module~=Menu.MODULE or command~="result" or type(args)~="table" then return end
    Menu.lastResult={ok=args.ok==true,reason=args.reason}
end
function Menu.request(player,command,args)
    if isClient() then
        if type(sendClientCommand)=="function" then sendClientCommand(player,Menu.MODULE,command,args) end
    else
        local build=ProjectNightfall and ProjectNightfall.EffigyFrameConstruction
        if not build then return end
        local result,reason=build.onCommand(Menu.MODULE,command,player,args)
        Menu.result(Menu.MODULE,"result",{ok=result~=nil,reason=reason})
    end
end
local function craft(player)
    -- Refresh the read-only selection at click time. The server resolves every
    -- ID and compares the full batch with its own current sandbox costs.
    local ids=Recipe.select(player)
    if ids then Menu.request(player,"craft",{items=ids}) end
end
local function place(player,item,square)
    Menu.request(player,"place",{frameId=item:getID(),x=square:getX(),y=square:getY(),z=square:getZ()})
end
function Menu.inventory(playerIndex,context,items)
    local player=getSpecificPlayer(playerIndex)
    local costs=Recipe.costs()
    if not player or not costs or not context or not ISInventoryPane then return end
    local selected=ISInventoryPane.getActualItems(items or {})
    local relevant=false
    for _,item in ipairs(selected or {}) do if costs[item:getFullType()] or Recipe.isTool(item) then relevant=true;break end end
    if not relevant then return end
    for _,option in ipairs(context.options or {}) do if option.PNFrameCraft then return end end
    local ids,reason=Recipe.select(player)
    local option=context:addOption(tr("Craft"),player,craft)
    if not option then return end
    option.PNFrameCraft=true;option.notAvailable=not ids
    if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
        local tip=ISInventoryPaneContextMenu.addToolTip()
        if tip then
            tip.description=tr("Cost",costs["Base.Log"],costs["Base.LargeBranch"],costs["Base.Rope"],costs["Base.Nails"])
            if not ids then tip.description=tip.description.." <LINE> "..tr(reason=="research_required" and "Research" or reason=="tools_required" and "Tools" or "Requirements") end
            option.toolTip=tip
        end
    end
end
function Menu.world(playerIndex,context,worldobjects,test)
    if not context or type(worldobjects)~="table" then return end
    local player=getSpecificPlayer(playerIndex)
    local config=ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC
    if not player or not config or config.Enabled==false then return end
    local square
    for i=1,math.min(#worldobjects,64) do
        if worldobjects[i] and worldobjects[i].getSquare then square=worldobjects[i]:getSquare();if square then break end end
    end
    if not square then return end
    local list=player:getInventory():getItems();if list:size()>Recipe.MAX_ITEMS then return end
    local frames={}
    for i=0,list:size()-1 do
        local item=list:get(i)
        if Recipe.frame(item) and Recipe.available(player,item) then frames[#frames+1]=item end
    end
    if #frames==0 then return end
    if test then
        if ISWorldObjectContextMenu and ISWorldObjectContextMenu.setTest then return ISWorldObjectContextMenu.setTest() end
        return
    end
    for _,option in ipairs(context.options or {}) do if option.PNFramePlace then return end end
    local root=context:addOption(tr("Place"),nil,nil);if not root then return end
    root.PNFramePlace=true
    local submenu=ISContextMenu:getNew(context);context:addSubMenu(root,submenu)
    local known=Knowledge.check(player)
    for _,item in ipairs(frames) do
        local row=submenu:addOption(item:getName(),player,place,item,square)
        if row then row.notAvailable=not known end
    end
    if not known then
        local row=submenu:addOption(tr("Research"),nil,nil);if row then row.notAvailable=true end
    end
    if Menu.lastResult and (not Menu.lastResult.ok or Menu.lastResult.reason~=nil) then
        local row=submenu:addOption(tr("Declined"),nil,nil);if row then row.notAvailable=true end
    end
end
if Events and Events.OnFillInventoryObjectContextMenu then Events.OnFillInventoryObjectContextMenu.Add(Menu.inventory) end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Menu.world) end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(Menu.result) end
return Menu
