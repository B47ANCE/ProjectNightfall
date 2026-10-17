-- Production client presentation: no authority calls, mutation, scan or debug gate.
isDebugEnabled=function() return false end
local callback,probeCalls= nil,0
Events={OnFillWorldObjectContextMenu={Add=function(fn) callback=fn end}}
SandboxVars={ProjectNightfall={Enabled=true}}
local tooltipCount=0
ISWorldObjectContextMenu={fetchVars={},setTest=function() probeCalls=probeCalls+1;return true end,
    addToolTip=function() tooltipCount=tooltipCount+1;return {} end}
local Menu=require "ProjectNightfall/PN_UVRemainsMenu"
assert(type(callback)=="function")
local function readonly(data) return setmetatable({}, {__index=data,__newindex=function() error("canonical write from presentation") end}) end
local record={schemaVersion=1,stage="SCORCHED",stageIndex=2,remainingTissue=80,tissueCapacity=100,destructionFraction=.2}
local marker={schemaVersion=1,infected=true}
local data=readonly({PN_UVCorpse=readonly(marker),PN_UVRemainsState=readonly(record)})
local reads=0
local corpse={getModData=function() reads=reads+1;return data end,
    transmitModData=function() error("presentation must not transmit") end,
    removeFromWorld=function() error("presentation must not remove corpses") end}
ISWorldObjectContextMenu.fetchVars.body=corpse
local function context()
    local c={options={}}
    function c:addOption(title,target,action)
        local option={name=title,target=target,action=action};self.options[#self.options+1]=option;return option
    end
    return c
end
getText=function(key,value)
    if value then return "translated: "..value end
    return "translated:"..key
end
local c=context()
callback(0,c,setmetatable({},{__index=function() error("world scan forbidden") end}),true)
assert(probeCalls==1 and #c.options==0 and tooltipCount==0,"controller probe must not allocate menu UI")
local before=reads;callback(0,c,{},false)
assert(reads-before==1 and #c.options==1)
assert(c.options[1].notAvailable and c.options[1].action==nil,"read-only information cannot queue gameplay")
assert(c.options[1].name:find("translated",1,true) and c.options[1].toolTip.description:find("translated",1,true))
callback(0,c,{},false);assert(#c.options==1,"duplicate fill events must not duplicate information")
-- Vanilla pools context panels; the next opening replaces options on the same panel.
c.options={};callback(0,c,{},false);assert(#c.options==1,"pooled panels must show remains on later openings")
for i,stage in ipairs({"INTACT","SCORCHED","DESICCATED","CRITICAL","RESIDUAL"}) do
    record.stage=stage;record.stageIndex=i
    assert(Menu.getView(corpse).stage==stage)
end
record.stage="<LINE> forged stage";assert(Menu.getView(corpse)==nil)
record.stage="RESIDUAL";record.stageIndex=1;assert(Menu.getView(corpse)==nil)
record.stageIndex=5;record.schemaVersion=99;assert(Menu.getView(corpse)==nil)
record.schemaVersion=1;marker.infected=false;assert(Menu.getView(corpse)==nil)
marker.infected=true;marker.schemaVersion=99;assert(Menu.getView(corpse)==nil)
marker.schemaVersion=1
SandboxVars.ProjectNightfall.Enabled=false;c=context();callback(0,c,{},false);assert(#c.options==0)
SandboxVars.ProjectNightfall.Enabled=true
getText=nil;c=context();callback(0,c,{},false);assert(c.options[1].name=="UV remains: Residual tissue")
ISWorldObjectContextMenu.fetchVars.body=nil;c=context();callback(0,c,{},false);assert(#c.options==0)
ISWorldObjectContextMenu.fetchVars.body={getModData=function() return {} end};callback(0,c,{},false);assert(#c.options==0)
assert(Menu.getView({getModData=function() error("unloaded object") end})==nil)
assert(Menu.getView(nil)==nil)
assert(record.remainingTissue==80 and record.destructionFraction==.2)
print("Nightfall localized selected-corpse remains presentation boundaries passed")
