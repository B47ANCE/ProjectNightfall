local types,ids=setmetatable({},{__mode="k"}),setmetatable({},{__mode="k"})
local groups,membership={},setmetatable({},{__mode="k"});local seq=0
local function snap(g)local m={};for e,r in pairs(g.members)do m[#m+1]={entity=e,role=r}end;return{id=g.id,owner=g.owner,leader=g.leader,members=m,size=#m}end
local Groups={}
function Groups.create(owner,leader)seq=seq+1;local g={id="G"..seq,owner=owner,leader=leader,members={[leader]="leader"}};groups[g.id]=g;membership[leader]=g.id;return snap(g)end
function Groups.getFor(e)local g=groups[membership[e]];return g and snap(g)end
function Groups.get(id)local g=groups[id];return g and snap(g)end
function Groups.join(id,e,role)local g=groups[id];g.members[e]=role or"member";membership[e]=id;return snap(g)end
function Groups.leave(e)local g=groups[membership[e]];if not g then return false end;g.members[e]=nil;membership[e]=nil;return true end
function Groups.count(id,role)local n=0;for _,r in pairs(groups[id].members)do if not role or r==role then n=n+1 end end;return n end
function Groups.prune(id)return snap(groups[id]),0 end;function Groups.disband()return true end;function Groups.merge(a)return snap(groups[a])end
local hierarchy=setmetatable({},{__mode="k"})
local Mortis={Groups=Groups,Identity={getStableId=function(e)return ids[e]end},CommandHierarchy={
 get=function(e)return hierarchy[e]end,desert=function(e,id)hierarchy[e]={formerSuperiorId=id,role="independent-deserter"};return true end},
 Engine={findTrackedByStableId=function()end}}
package.loaded["Mortis/init"]=Mortis
package.loaded["ProjectNightfall/PN_Config"]={POC={EnableSmartFeralHordes=true,SmartFeralDesertionFollowerRadius=6,SmartFeralRecruitmentRadius=10,SmartFeralMergeRadius=10}}
local Integration={TYPE_FERAL="Feral",TYPE_SMART_FERAL="Smart",TYPE_ALPHA_FERAL="Alpha",getTypeId=function(e)return types[e]end}
package.loaded["ProjectNightfall/PN_MortisIntegration"]=Integration
local function z(id,t,x,target)local e={x=x,target=target};ids[e]=id;types[e]=t;function e:getX()return self.x end;function e:getY()return 0 end;function e:getZ()return 0 end;function e:isDead()return false end;function e:getTarget()return self.target end;function e:pathToLocationF()end;return e end
local alpha,smart,engaged,near,far=z("A","Alpha",0),z("S","Smart",1),z("E","Feral",2,{}),z("N","Feral",3),z("F","Feral",20)
local sg=Groups.create("ProjectNightfall",smart);Groups.join(sg.id,engaged);Groups.join(sg.id,near);Groups.join(sg.id,far)
hierarchy[smart]={superiorId="A"}
local FG=require "ProjectNightfall/PN_FeralGroups"
local result=assert(FG.desertAlphaWar(smart,alpha,{worldAgeHours=10,escapePoint={x=-10,y=0,z=0}}))
assert(result.transferred==1 and result.released==1 and result.retained==1)
assert(Groups.getFor(engaged).owner=="ProjectNightfall.AlphaDirect")
assert(Groups.getFor(near).id==sg.id and Groups.getFor(far)==nil)
assert(hierarchy[smart].formerSuperiorId=="A" and hierarchy[smart].superiorId==nil)
print("Project Nightfall Smart Feral combat-desertion split checks passed")
