-- Real Knowledge owner projection and Nightfall's shared research query.
-- Presentation may enable a menu; construction still rechecks on the server.
isServer=function()return false end;isClient=function()return true end
local API=require 'ProjectNightfall/PN_ResearchArchive'
local Gate=require 'ProjectNightfall/PN_EffigyKnowledge'
SandboxVars={ProjectNightfall={RequireEffigyKnowledge=true}}
local player={getOnlineID=function()return 12 end,getModData=function()return {}end}
getSpecificPlayer=function(slot)if slot==0 then return player end end
getRandomUUID=function()return '00000000-0000-0000-0000-000000000001' end
local request
sendClientCommand=function(actor,module,command,args)
    assert(actor==player and module=='B47ANCEDKnowledgeAndWisdom.Knowledge' and command=='request')
    request=args.requestId
    for key in pairs(args)do assert(key=='requestId','only own projection intent is sent')end
end
local Projection=require 'B47ANCEDKnowledgeAndWisdom/KnowledgeProjection'
assert(not Gate.check(player),'pending projection cannot unlock the menu')
assert(Projection.request(0,player))
local args={slot=0,onlineId=999,revision=0,life='00000000-0000-0000-0000-000000000002',
    requestId=request,ledger={schemaVersion=1,documents={},knowledge={}}}
local function receive()return Projection.receive('B47ANCEDKnowledgeAndWisdom.Knowledge','snapshot',args)end
assert(not receive() and not Gate.check(player),'another native actor is rejected')
args.onlineId=12;assert(receive() and not Gate.check(player))
args.revision=1
args.ledger={schemaVersion=1,documents={['NF-FIELD-026']={}},knowledge={
    ['ProjectNightfall.EffigyConstruction']={sourceDocument='NF-FIELD-026',owner='ProjectNightfall'}}}
assert(receive() and Gate.check(player),'own researched projection enables the shared menu gate')
args.revision=0;args.ledger={schemaVersion=1,documents={},knowledge={}}
assert(not receive() and Gate.check(player),'stale projection cannot replace newer state')
local copy=API.snapshot(player);copy.knowledge={}
assert(Gate.check(player),'presentation queries return detached data')
player={getOnlineID=function()return 13 end,getModData=function()return {}end}
assert(not Gate.check(player),'new local actor waits for its own projection')
print('Effigy research menu follows the real owning projection, not stale or foreign replies')
