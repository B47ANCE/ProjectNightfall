-- In-memory native boundary only. The actual pinned Knowledge backend/API run.
local F={files={},players={},world='nightfall-dedicated-research',mode='normal'}
local serial=0
function F.install()
    isServer=function()return true end;isClient=function()return false end
    getCurrentSaveName=function()return F.world end
    getRandomUUID=function()
        serial=serial+1;return string.format('00000000-0000-0000-0000-%012d',serial)
    end
    getOnlinePlayers=function()
        return {size=function()return #F.players end,get=function(_,i)return F.players[i+1]end}
    end
    getFileReader=function(path)
        local bytes=F.files[path];if bytes==nil then return nil end
        local lines=bytes:gmatch('([^\n]*)\n')
        return {readLine=function()return lines()end,close=function()end}
    end
    getFileWriter=function(path,create,append)
        assert(create and append,'append-only private journal')
        return {write=function(_,bytes)
            if F.mode=='drop' then return end
            F.files[path]=(F.files[path]or'')..bytes
        end,close=function()end}
    end
    sendServerCommand=sendServerCommand or function()end
end
function F.bindActor(player,name,slot)
    function player:getUsername()return name end
    function player:getPlayerNum()return slot end
    function player:getOnlineID()return slot+10 end
end
function F.reload()
    package.loaded['B47ANCEDKnowledgeAndWisdom/API']=nil
    package.loaded['B47ANCEDKnowledgeAndWisdom/PrivateKnowledge']=nil
    package.loaded['ProjectNightfall/PN_ResearchArchive']=nil
    B47ANCEDKnowledgeAndWisdom=nil
    return require('ProjectNightfall/PN_ResearchArchive'),require('B47ANCEDKnowledgeAndWisdom/PrivateKnowledge')
end
return F
