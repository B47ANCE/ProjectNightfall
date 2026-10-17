local F=dofile('tests/helpers/effigy_container_fixture.lua');F.install()
local Server=require 'ProjectNightfall/PN_EffigyContainerServer'
ProjectNightfall.Config.POC.EffigyContainerCapacity=20
local p,o,f,s,c=F.world()
local human=F.item('human');local feral=F.item('feral');s:AddItem(human);s:AddItem(feral)
local sends={};isClient=function() return true end
sendClientCommand=function(player,module,command,args) sends[#sends+1]={player,module,command,args} end
getSpecificPlayer=function(index) assert(index==0);return p end
local testCalls=0
ISWorldObjectContextMenu={setTest=function() testCalls=testCalls+1;return true end}
local function context()
    local ctx={options={}}
    function ctx:addOption(name,target,callback,...)
        local option={name=name,target=target,callback=callback,args={...}}
        self.options[#self.options+1]=option;return option
    end
    function ctx:addSubMenu(option,sub) option.submenu=sub end
    return ctx
end
ISContextMenu={getNew=function() return context() end}
Events.OnFillWorldObjectContextMenu={Add=function() end};Events.OnServerCommand={Add=function() end}
local Menu=require 'ProjectNightfall/PN_EffigyContainerMenu'
local ctx=context();assert(Menu.fill(0,ctx,{o},true));assert(testCalls==1 and #ctx.options==0 and #sends==0)
Menu.fill(0,ctx,{o},false);assert(#ctx.options==1 and #sends==1)
local sub=ctx.options[1].submenu
assert(#sub.options==4) -- refresh plus both valid empty-container categories
local pick=sub.options[3];pick.callback(p,unpack(pick.args))
local request=sends[#sends][4]
assert(request.items[1]==human.id and request.revision==0 and #c.items==0)
assert(request.x==10 and request.index==0 and request.frameId==f.id)
Menu.fill(0,ctx,{o},false);assert(#ctx.options==1) -- pooled panel dedup
-- Only the server event actually commits; the returned view advances the UI's
-- expected revision. Other source classes disappear once a physical part exists.
isClient=function() return false end
assert(Server.onCommand(sends[#sends][2],sends[#sends][3],p,request))
Menu.result('ProjectNightfallEffigyContainer','result',F.replies[#F.replies])
assert(Menu.views[f.id].revision==1 and human.container==c)
isClient=function() return true end
ctx=context();Menu.fill(0,ctx,{o},false)
assert(#ctx.options[1].submenu.options==3) -- refresh plus no-matching row
assert(ctx.options[1].submenu.options[3].notAvailable)
assert(sends[#sends][4].revision==1)
-- Actual emptiness restores choice; meat cannot be offered beside a body part.
s:AddItem(human);local meat=F.item('meat');s:AddItem(meat)
ctx=context();Menu.fill(0,ctx,{o},false);assert(#ctx.options[1].submenu.options==5)
-- Controller/test probe, disabled setting, unrelated objects and stale world
-- identity cannot send gameplay intent. No fallback mutates client inventories.
ProjectNightfall.Config.POC.Enabled=false
local before=#sends;Menu.fill(0,context(),{o},false);assert(#sends==before)
ProjectNightfall.Config.POC.Enabled=true
f.world=nil;Menu.fill(0,context(),{o},false);assert(#sends==before)
f.world=o
Menu.result('other','result',{frameId=f.id,view={frameId=f.id,revision=99}})
assert(Menu.views[f.id].revision==1)
-- SP routes to the same authority handler; it does not implement another mover.
isClient=function() return false end
Menu.request(p,o,{meat.id});assert(meat.container==c and Menu.views[f.id].revision==2)
assert(human.container==s and feral.container==s)
print('Effigy menu intent regressions passed (offline UI/native facades)')
