----------------------------------------------------------------------------------------------------
--- The Creation Come From: A Beginner AI 
--- Author: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------
if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or GetBot():IsIllusion() then
	return;
end

dofile( GetScriptDirectory().."/bot_test")

local BotBuild = dofile(GetScriptDirectory() .. "/BotLib/" .. string.gsub(GetBot():GetUnitName(), "npc_dota_", ""));
if BotBuild == nil then return end

function MinionThink(hMinionUnit)

	BotBuild.MinionThink(hMinionUnit)
	
end
-- dota2jmz@163.com QQ:2462331592