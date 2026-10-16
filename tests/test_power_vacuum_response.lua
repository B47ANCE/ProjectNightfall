local types=setmetatable({},{__mode="k"});local states=setmetatable({},{__mode="k"})
local Ecology={isAlphaDead=function(id)return id=="DEAD"end,recordAlphaDeath=function()return true end}
package.loaded["ProjectNightfall/PN_AlphaEcologyState"]=Ecology
local Mortis={Authority={canWriteCanonicalState=function()return true end},
    CommandHierarchy={get=function(e)return states[e]end,setObjective=function(e,kind,point,now,target)states[e]=states[e]or{};states[e].objective={kind=kind,point=point,targetStableId=target};return true end,
        clear=function(e)states[e]=nil;return true end},
    getStableId=function()return "ID"end,Groups={},Events={on=function()end}}
package.loaded["Mortis/init"]=Mortis
local Integration={TYPE_ALPHA_FERAL="Alpha",TYPE_SMART_FERAL="Smart",getTypeId=function(e)return types[e]end}
package.loaded["ProjectNightfall/PN_MortisIntegration"]=Integration
ProjectNightfall={Config={POC={}}}
local Alpha=require "ProjectNightfall/PN_AlphaFerals"
local alpha={pathToLocationF=function(self)x=true end};types[alpha]="Alpha"
assert(Alpha.respondToPowerVacuum(alpha,{alphaId="DEAD",x=1,y=2,z=0}))
assert(states[alpha].objective.kind=="investigate-power-vacuum")
states[alpha].objective={kind="destroy-rival-alpha"}
assert(not Alpha.respondToPowerVacuum(alpha,{alphaId="DEAD",x=1,y=2,z=0}),"rivalry must take priority")
local smart={pathToLocationF=function()end};types[smart]="Smart";states[smart]={superiorId="LIVE"}
assert(not Alpha.respondToPowerVacuum(smart,{alphaId="DEAD",x=1,y=2,z=0}),"loyal Smart must not desert")
states[smart]={superiorId="DEAD"}
assert(Alpha.respondToPowerVacuum(smart,{alphaId="DEAD",x=1,y=2,z=0}))
assert(states[smart].objective.kind=="investigate-power-vacuum")
local regular={};types[regular]="Regular"
assert(not Alpha.respondToPowerVacuum(regular,{alphaId="DEAD",x=1,y=2,z=0}))
print("Project Nightfall power-vacuum response policy checks passed")
