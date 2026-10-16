require "ProjectNightfall/PN_BuildEffigyAction"

ISInventoryMenuElements=ISInventoryMenuElements or {}

function ISInventoryMenuElements.ProjectNightfallEffigies()
    local self=ISMenuElement.new()
    self.invMenu=ISContextManager.getInstance().getInventoryMenu()

    function self.init() end

    function self.queue(_,parts)
        local api=ProjectNightfall and ProjectNightfall.Effigies
        local ok,valid=pcall(function() return api.validateConstruction(self.invMenu.player,parts) end)
        if not ok or not valid then return end
        ISTimedActionQueue.add(PN_BuildEffigyAction:new(self.invMenu.player,parts))
    end

    function self.createMenu(item)
        local api=ProjectNightfall and ProjectNightfall.Effigies
        if not api or not item or not ISInventoryPane or not ISInventoryPane.getActualItems then return end
        local context=self.invMenu.context
        if not context then return end
        for _,option in ipairs(context.options or {}) do
            if option.ProjectNightfallEffigyOption then return end
        end
        -- Vanilla skips the dummy first entry of stacks and deduplicates a
        -- selected stack whose individual children were also selected.
        local ok,selected=pcall(ISInventoryPane.getActualItems,self.invMenu.items or {})
        if not ok or type(selected)~="table" then return end
        local inspected,composition=pcall(api.snapshotComposition,selected)
        if not inspected or not composition or composition.partCount<3 then return end
        local checked,valid,reason=pcall(api.validateConstruction,self.invMenu.player,selected)
        if not checked then reason="Effigy validation unavailable"; valid=nil end
        local option=context:addOption("Build Macabre Effigy",self,self.queue,selected)
        if not option then return end
        option.ProjectNightfallEffigyOption=true
        if not valid then
            option.notAvailable=true
            if ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.addToolTip then
                local made,tooltip=pcall(ISInventoryPaneContextMenu.addToolTip)
                if made and tooltip then
                    tooltip.description=tostring(reason or "Effigy construction unavailable")
                    option.toolTip=tooltip
                end
            end
        end
    end
    return self
end
