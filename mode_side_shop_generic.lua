----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 2018.11.21
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Refactor: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------
if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or  GetBot():IsIllusion() then
	return;
end

local bot = GetBot()
local X = {}
local J = require( GetScriptDirectory()..'/FunLib/jmz_func')

local cause = nil;
local outpostsTarget = nil;
local outpostcooldown = 0;

function GetDesire()
	if DotaTime() < 10 then return 0.0 end
		
	outpostsTarget = X.GetTargetOutpost();
	
	if outpostsTarget ~= nil 
	   and DotaTime() > 600
	   and outpostcooldown + 180 < DotaTime() --3分钟占领冷却
	then
		local outpostTarget = nil

		for _,target in pairs(outpostsTarget)
		do
			if outpostTarget == nil 
			   and target:GetTeam() ~= bot:GetTeam() 
			then outpostTarget = target end
			
			if target:GetTeam() ~= bot:GetTeam()
			   and GetUnitToUnitDistance(bot, outpostTarget) > GetUnitToUnitDistance(bot, target)
			then
				outpostTarget = target
			end
		end

		if outpostTarget ~= nil then

			local tableNearbyEnemyHeroes = outpostTarget:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local tableBotNearbyEnemyHeroes = bot:GetNearbyHeroes( 1200, true, BOT_MODE_NONE );

			--在安全的情况下进行前哨占领
			if (tableNearbyEnemyHeroes == nil
			   or (tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes < 3)) --确保占领目标旁边不超过2个敌人
			   and (tableBotNearbyEnemyHeroes == nil
			   or (tableBotNearbyEnemyHeroes ~= nil and #tableBotNearbyEnemyHeroes < 3)) --确保自己身边不超过2个敌人
			   and J.GetHPR(bot) > 0.6
			   and not bot:WasRecentlyDamagedByAnyHero(3.0)
			then
				cause = outpostTarget;
				return BOT_MODE_DESIRE_HIGH;
			end
		else
			--没有可以占领的前哨时设置冷却，防止双方无限制争夺前哨
			outpostcooldown = DotaTime()
		end
	end
			
	return BOT_MODE_DESIRE_NONE

end

function Think()
	if cause ~= nil then

		if cause:IsNull()
		then
			cause = nil;
			return;
		end

		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1200, true, BOT_MODE_NONE );

			if GetUnitToUnitDistance(bot, cause) > 800 then
				bot:Action_MoveToLocation(cause:GetLocation() + RandomVector(20))
				return
			else
				--下方前哨有概率出现傻站着不占领的问题，不确定原因
				bot:Action_AttackUnit(cause, true)
				return
			end
	end
	
	return;
end

function OnStart()

end

function OnEnd()
	cause = nil;
	outpostsTarget = nil;
end

function X.GetTargetOutpost()
	local unitlist = GetUnitList(UNIT_LIST_ALL)
	local Outposts = {}
	if #unitlist > 0 then
		for _,t in pairs(unitlist) do
			if t:GetUnitName() == 'npc_dota_watch_tower' then
				table.insert(Outposts, t)
			end
		end
	end
	return Outposts;
end
-- dota2jmz@163.com QQ:2462331592。