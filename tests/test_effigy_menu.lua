local actualParts={{},{},{}}
local valid=false
local queued=0
local reason="research NF-FIELD-026 is required"
local api={snapshotComposition=function(parts) return #parts==3 and {partCount=3} or nil end,
    validateConstruction=function() return valid and {} or nil,reason end}
ProjectNightfall={Effigies=api}
ISMenuElement={new=function() return {} end}
local context={options={}}
function context:addOption(name,target,callback,parts)
    local option={name=name,target=target,callback=callback,parts=parts}
    self.options[#self.options+1]=option
    return option
end
local menu={context=context,player={},items={{items={actualParts[1],actualParts[1],actualParts[2],actualParts[3]}}}}
ISContextManager={getInstance=function() return {getInventoryMenu=function() return menu end} end}
ISInventoryPane={getActualItems=function(items)
    assert(items==menu.items)
    return actualParts
end}
ISInventoryPaneContextMenu={addToolTip=function() return {} end}
ISTimedActionQueue={add=function() queued=queued+1 end}
PN_BuildEffigyAction={new=function(_,player,parts) assert(player==menu.player and parts==actualParts); return {} end}
local originalRequire=require
require=function(name) if name=="ProjectNightfall/PN_BuildEffigyAction" then return PN_BuildEffigyAction end return originalRequire(name) end
getText=function(key)
    if key=="ContextMenu_ProjectNightfall_BuildMacabreEffigy" then return "Localized Effigy" end
    return key
end
dofile(assert(arg[1]))
local element=ISInventoryMenuElements.ProjectNightfallEffigies()
element.createMenu(actualParts[1])
assert(#context.options==1 and context.options[1].notAvailable and context.options[1].name=="Localized Effigy")
assert(context.options[1].toolTip.description==reason)
element.createMenu(actualParts[2])
assert(#context.options==1)
element.queue(nil,actualParts)
assert(queued==0)
context.options={}; valid=true
element.createMenu(actualParts[1])
assert(#context.options==1 and not context.options[1].notAvailable)
element.queue(nil,actualParts)
assert(queued==1)
valid=false
element.queue(nil,actualParts)
assert(queued==1)
context.options={}
ISInventoryPane.getActualItems=function() error("malformed inventory entry") end
element.createMenu(actualParts[1])
assert(#context.options==0)
print("Nightfall effigy menu hint/deduplication/queue revalidation checks passed")
