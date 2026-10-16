ProjectNightfall={Config={POC={}}}
package.loaded["ProjectNightfall/PN_Config"]=true
package.loaded["ProjectNightfall/PN_SolarUV"]={}
package.loaded["ProjectNightfall/PN_FeralGroups"]={}
local localPlayer={name="local",isDead=function() return false end,getUsername=function(self) return self.name end}
local remotePlayer={name="remote",isDead=function() return false end,getUsername=function(self) return self.name end}
getSpecificPlayer=function(index) return index==0 and localPlayer or nil end
local list={remotePlayer}
getOnlinePlayers=function() return {size=function() return #list end,get=function(_,index) return list[index+1] end} end
local AI=require "ProjectNightfall/PN_FeralAI"
assert(AI.playerKey(remotePlayer)=="username:remote")
assert(AI.findPlayerByKey("username:remote")==remotePlayer,"remote lookup must use getOnlinePlayers")
assert(AI.findPlayerByKey("username:local")==localPlayer,"local fallback must remain available")
remotePlayer.isDead=function() return true end
assert(AI.findPlayerByKey("username:remote")==nil,"dead targets must not be returned")
print("Project Nightfall multiplayer-aware persistent player-key lookup checks passed")
