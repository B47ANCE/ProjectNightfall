-- The script installs both guards at instance construction, before an item can
-- enter the world/network. No code ever opens native insertion, even temporarily.
local Policy=require "ProjectNightfall/PN_EffigyContainerPolicy"
local Container={FULL_TYPE="ProjectNightfall.EffigyFrame",KEY="ProjectNightfallEffigyContainer",
    NATIVE_CATEGORY="ProjectNightfall_ServerLoadOnly",NATIVE_FILTER="PN_EffigyRejectNativeInsertion"}

function PN_EffigyRejectNativeInsertion() return false end

function Container.getFrame(object)
    if not object then return nil end
    local ok,item=pcall(function()
        local frame=object:getItem()
        if frame and frame:getFullType()==Container.FULL_TYPE and frame:IsInventoryContainer()
            and frame:getWorldItem()==object then return frame end
    end)
    return ok and item or nil
end

function Container.isClosed(container)
    local ok,closed=pcall(function()
        return container:getOnlyAcceptCategory()==Container.NATIVE_CATEGORY
            and container:getAcceptItemFunction()==Container.NATIVE_FILTER
    end)
    return ok and closed==true
end

function Container.inspect(object)
    local frame=Container.getFrame(object)
    if not frame then return nil,"not_frame" end
    local container=frame:getItemContainer()
    if not Container.isClosed(container) then return nil,"native_guard_missing" end
    return Policy.inspect(container)
end

return Container
