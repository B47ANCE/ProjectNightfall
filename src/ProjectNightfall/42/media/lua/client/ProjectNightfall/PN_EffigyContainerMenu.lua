local Frame=require "ProjectNightfall/PN_EffigyContainer"
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local Menu={views={}}
local categories={meat="Ordinary meat",human="Human",regular="Regular zombie",feral="Feral",smartFeral="Smart Feral"}
local function tr(key,fallback,...)
    local args={...}
    if type(getText)=="function" then
        local ok,value=pcall(getText,key,unpack(args))
        if ok and value and value~=key then return value end
    end
    for i,value in ipairs(args) do fallback=fallback:gsub("%%"..i,function() return tostring(value) end) end
    return fallback
end
local function locate(object)
    local square=object and object:getSquare()
    local objects=square and square:getWorldObjects()
    if not objects or objects:size()>1024 then return nil end
    for index=0,objects:size()-1 do if objects:get(index)==object then return index end end
end
local function selected(worldobjects)
    if type(worldobjects)~="table" then return nil end
    for i=1,math.min(#worldobjects,64) do
        local object=worldobjects[i]
        if Frame.getFrame(object) then return object end
        -- The supplied context may contain the tile/floor rather than its item.
        -- Inspect only that selected tile, bounded; never search the world.
        local square=object and object:getSquare()
        local objects=square and square:getWorldObjects()
        if objects and objects:size()<=1024 then
            for j=0,objects:size()-1 do
                if Frame.getFrame(objects:get(j)) then return objects:get(j) end
            end
        end
    end
end
function Menu.result(module,command,args)
    if module~="ProjectNightfallEffigyContainer" or command~="result" or type(args)~="table" then return end
    if type(args.frameId)~="number" then return end
    -- One currently viewed frame avoids an unbounded world-item cache.
    -- The server response is presentation/expected-revision input, not authority.
    if type(args.view)=="table" and args.view.frameId==args.frameId then
        Menu.views={ [args.frameId]=args.view }
    end
    Menu.lastResult={frameId=args.frameId,ok=args.ok}
end
function Menu.request(player,object,items)
    local frame=Frame.getFrame(object)
    local index=locate(object)
    if not frame or index==nil then return end
    local square=object:getSquare()
    local view=Menu.views[frame:getID()]
    local args={x=square:getX(),y=square:getY(),z=square:getZ(),index=index,
        frameId=frame:getID(),items=items,revision=view and view.revision or 0}
    local command=items and "load" or "inspect"
    if type(isClient)=="function" and isClient() then
        if type(sendClientCommand)=="function" then sendClientCommand(player,"ProjectNightfallEffigyContainer",command,args) end
    else
        local server=ProjectNightfall and ProjectNightfall.EffigyContainerServer
        if not server then return end
        local result,reason,current=server.onCommand("ProjectNightfallEffigyContainer",command,player,args)
        Menu.result("ProjectNightfallEffigyContainer","result",{frameId=frame:getID(),ok=result~=nil,view=current or result})
    end
end
function Menu.fill(playerIndex,context,worldobjects,test)
    local config=ProjectNightfall and ProjectNightfall.Config and ProjectNightfall.Config.POC
    if not config or config.Enabled==false or not context then return end
    local object=selected(worldobjects)
    local view=object and Frame.inspect(object)
    if not view then return end
    local player=type(getSpecificPlayer)=="function" and getSpecificPlayer(playerIndex)
    if not player then return end
    if test then
        if ISWorldObjectContextMenu and ISWorldObjectContextMenu.setTest then return ISWorldObjectContextMenu.setTest() end
        return
    end
    for _,option in ipairs(context.options or {}) do if option.PNEffigyContainer then return end end
    local root=context:addOption(tr("ContextMenu_ProjectNightfall_LoadEffigy","Load effigy"),nil,nil)
    if not root then return end
    root.PNEffigyContainer=true
    local submenu=ISContextMenu:getNew(context)
    context:addSubMenu(root,submenu)
    local status=submenu:addOption(tr("ContextMenu_ProjectNightfall_EffigyState_"..view.visualState,view.visualState),nil,nil)
    if status then status.notAvailable=true end
    if Menu.lastResult and Menu.lastResult.frameId==Frame.getFrame(object):getID() and Menu.lastResult.ok==false then
        local declined=submenu:addOption(tr("ContextMenu_ProjectNightfall_EffigyDeclined","Load declined; check contents and try again"),nil,nil)
        if declined then declined.notAvailable=true end
    end
    submenu:addOption(tr("ContextMenu_ProjectNightfall_EffigyRefresh","Refresh contents"),player,Menu.request,object)
    local list=player:getInventory():getItems()
    local added=0
    if list:size()<=256 then
        for i=0,list:size()-1 do
            local item=list:get(i)
            local category=Policy.classify(item)
            if category and (not view.category or view.category==category) and not player:isEquipped(item) then
                local label=tr("ContextMenu_ProjectNightfall_EffigyCategory_"..category,categories[category])
                submenu:addOption(tr("ContextMenu_ProjectNightfall_EffigyLoadItem","%1 (%2)",item:getName(),label),player,Menu.request,object,{item:getID()})
                added=added+1
            end
        end
    end
    if added==0 then
        local empty=submenu:addOption(tr("ContextMenu_ProjectNightfall_EffigyNoMatchingItems","No matching items in your main inventory"),nil,nil)
        if empty then empty.notAvailable=true end
    end
    -- First/rejoined observer may have a stale revision; the server rejects it
    -- without moving anything and replies with a fresh view. Never auto-retry.
    Menu.request(player,object)
end
if Events and Events.OnFillWorldObjectContextMenu then Events.OnFillWorldObjectContextMenu.Add(Menu.fill) end
if Events and Events.OnServerCommand then Events.OnServerCommand.Add(Menu.result) end
ProjectNightfall=ProjectNightfall or {};ProjectNightfall.EffigyContainerMenu=Menu
return Menu
