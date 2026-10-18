local Fixture=dofile('tests/helpers/private_knowledge_fixture.lua');Fixture.install()
local API=require 'ProjectNightfall/PN_ResearchArchive'
local Store=require 'B47ANCEDKnowledgeAndWisdom/PrivateKnowledge'
local Guard=require 'B47ANCEDKnowledgeAndWisdom/AuthorityGuard'
local Diagnostics=require 'ProjectNightfall/PN_DependencyDiagnostics'
local M={VERSION='fixture',FoodSources={TRANSACTION_VERSION=1},getTypeId=function()end,
    Authority={canWriteCanonicalState=function()end},ZombieHunger={getStarvationHours=function()end,getDrive=function()end},
    negotiateAPI=function()return true end}
local L={registerBulb=function()end,UV={getSunlightExposure=function()end,getArtificialExposure=function()end}}
local P={registerLoad=function()end};local H={getDetachedPartProvenance=function()end,performProcedure=function()end}
local function inspect()local _,_,_,r=Diagnostics.inspect(L,P,M,H,API,Guard);return r end
assert(inspect().knowledgeStorage=='PRIVATE_DOCUMENT_BACKEND_SUPPORTED')
assert(Store.initialize(true))
local bytes={};for name,value in pairs(Fixture.files)do bytes[name]=value end
-- A ready private document backend does not open the broader character/write guard.
assert(not Guard.write() and not Guard.characterRead())
local result=inspect()
assert(result.knowledgeStorage=='PRIVATE_DOCUMENT_BACKEND_SUPPORTED',result.knowledgeStorage)
assert(result.status=='UNKNOWN','structural support is not readiness')
for name,value in pairs(Fixture.files)do assert(bytes[name]==value,'diagnostics must not write')end
-- Diagnostics use only public table structure. In particular they cannot rely
-- on the host's module cache, initialize a store or call per-character APIs.
local originalPackage=package;package=nil
local ready=Store.ready;Store.ready=function()error('must not probe storage')end
assert(inspect().knowledgeStorage=='PRIVATE_DOCUMENT_BACKEND_SUPPORTED')
Store.ready=ready;package=originalPackage
isServer=function()return false end;isClient=function()return true end
assert(inspect().knowledgeStorage=='CLIENT_PROJECTION_SUPPORTED')
assert(inspect().status=='PRESENTATION_ONLY')
local install=API._installKnowledgeBackend;API._installKnowledgeBackend=nil
assert(inspect().knowledgeStorage=='BLOCKED');API._installKnowledgeBackend=install
print('Private document API support is distinct from storage/identity readiness and broader guards')
