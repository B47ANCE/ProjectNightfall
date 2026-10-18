local F=dofile('tests/helpers/effigy_container_fixture.lua');F.install()
local Recipe=require 'ProjectNightfall/PN_EffigyFrameRecipe'
local config=ProjectNightfall.Config.POC
config.RequireEffigyKnowledge=false
local p,o,frame,root=F.world();frame.world=nil;root:AddItem(frame)
local selected
for _,pair in ipairs({{'Base.Log',4},{'Base.Rope',2},{'Base.Nails',8}}) do
    for _=1,pair[2] do
        local item=F.item('meat');item.foodType=nil;item.kind=pair[1]
        function item:getFullType() return self.kind end
        root:AddItem(item);selected=selected or item
    end
end
getSpecificPlayer=function(index) assert(index==0);return p end
getText=function(key,...) return key end
ISInventoryPane={getActualItems=function(items) return items end}
ISInventoryPaneContextMenu={addToolTip=function() return {} end}
local probes=0;ISWorldObjectContextMenu={setTest=function()probes=probes+1;return true end}
local function context()
    local ctx={options={}}
    function ctx:addOption(label,target,callback,...)
        local option={name=label,target=target,callback=callback,args={...}}
        self.options[#self.options+1]=option;return option
    end
    function ctx:addSubMenu(row,sub) row.submenu=sub end
    return ctx
end
ISContextMenu={getNew=function()return context()end}
local hooks={}
for _,key in ipairs({'OnFillInventoryObjectContextMenu','OnFillWorldObjectContextMenu','OnServerCommand'}) do
    local name=key;Events[name]={Add=function(fn)hooks[name]=fn end}
end
local Menu=require 'ProjectNightfall/PN_EffigyFrameMenu'
assert(hooks.OnFillInventoryObjectContextMenu==Menu.inventory and hooks.OnFillWorldObjectContextMenu==Menu.world)
local sends={};sendClientCommand=function(actor,module,command,args)
    sends[#sends+1]={actor=actor,module=module,command=command,args=args}
end
isClient=function()return true end
local ctx=context();Menu.inventory(0,ctx,{selected})
assert(#ctx.options==1 and not ctx.options[1].notAvailable)
assert(ctx.options[1].toolTip.description)
Menu.inventory(0,ctx,{selected});assert(#ctx.options==1)
local row=ctx.options[1];row.callback(row.target,unpack(row.args))
assert(#sends==1 and sends[1].module==Menu.MODULE and sends[1].command=='craft')
assert(#sends[1].args.items==14 and #root.items==15 and not frame.world)
-- Click selection is refreshed after a queued native move/cost change.
config.EffigyFrameLogs=5;row.callback(row.target,unpack(row.args));assert(#sends==1)
config.EffigyFrameLogs=4
ctx=context();assert(Menu.world(0,ctx,{o},true));assert(probes==1 and #ctx.options==0 and #sends==1)
Menu.world(0,ctx,{o},false);Menu.world(0,ctx,{o},false);assert(#ctx.options==1)
row=ctx.options[1].submenu.options[1];row.callback(row.target,unpack(row.args))
assert(#sends==2 and sends[2].command=='place' and sends[2].args.frameId==frame.id)
assert(sends[2].args.x==10 and sends[2].args.y==10 and sends[2].args.z==0)
assert(frame.world==nil and frame.container==root)
-- Research is presented as disabled; the server still checks it independently.
config.RequireEffigyKnowledge=true;B47ANCEDKnowledgeAndWisdom=nil
ctx=context();Menu.inventory(0,ctx,{selected});assert(ctx.options[1].notAvailable)
ctx=context();Menu.world(0,ctx,{o},false);assert(ctx.options[1].submenu.options[1].notAvailable)
config.RequireEffigyKnowledge=false
-- Unrelated selections, disabled feature and empty world context add nothing.
ctx=context();Menu.inventory(0,ctx,{frame});assert(#ctx.options==0)
Menu.world(0,ctx,{},false);assert(#ctx.options==0)
config.Enabled=false;Menu.inventory(0,ctx,{selected});Menu.world(0,ctx,{o},false);assert(#ctx.options==0)
config.Enabled=true
-- SP invokes the same server command endpoint. No alternate inventory mutation.
isClient=function()return false end
local calls=0
ProjectNightfall.EffigyFrameConstruction={onCommand=function(module,command,actor,args)
    assert(module==Menu.MODULE and command=='place' and actor==p and args.frameId==frame.id)
    calls=calls+1;return true
end}
Menu.request(p,'place',{frameId=frame.id});assert(calls==1 and Menu.lastResult.ok)
Menu.result('unrelated','result',{ok=false});assert(Menu.lastResult.ok)
Menu.result(Menu.MODULE,'result',{ok=false,reason='inaccessible'});assert(not Menu.lastResult.ok)
assert(#root.items==15 and frame.container==root and not frame.world)
print('Effigy frame menu intent/knowledge/SP routing checks passed')
