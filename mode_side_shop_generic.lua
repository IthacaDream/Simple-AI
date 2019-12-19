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
	
	local botMode = bot:GetActiveMode();
	if outpostsTarget ~= nil 
	   and DotaTime() > 60 * 10
	   and outpostcooldown + 60 * 4 < DotaTime() --4分钟占领冷却
	   and not X.IsThereT3Detroyed() --没被破高
	   and X.IsTowerSecurity() --没有塔被攻击
	then
		local outpostTarget = nil

		for _,target in pairs(outpostsTarget)
		do

			if outpostTarget == nil 
			   and target:GetTeam() ~= bot:GetTeam() 
			then
				outpostTarget = target
			end
			
			if target:GetTeam() ~= bot:GetTeam()
			   and GetUnitToUnitDistance(bot, outpostTarget) > GetUnitToUnitDistance(bot, target)
			then
				outpostTarget = target
			end
		end

		if outpostTarget ~= nil then
			--在安全的情况下进行前哨占领
			if J.GetHPR(bot) > 0.6
			   and X.SuitableToOutposts(outpostTarget)
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
		if GetUnitToUnitDistance(bot, cause) > 800 then
			bot:Action_MoveToLocation(cause:GetLocation() + RandomVector(20))
			return;
		else
			bot:Action_AttackUnit(cause, true)
			return;
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

function X.IsThereT3Detroyed()
	
	local T3s = {
		TOWER_TOP_3,
		TOWER_MID_3,
		TOWER_BOT_3
	}
	
	for _,t in pairs(T3s) do
		local tower = GetTower(GetOpposingTeam(), t);
		if tower == nil or not tower:IsAlive() then
			return true;
		end
	end	
	return false;
end

function X.IsTowerSecurity()
	local towersList = {
		TOWER_BASE_1,
		TOWER_BASE_2,
		TOWER_MID_3,
		TOWER_BOT_3,
		TOWER_TOP_3,
		TOWER_MID_2,
		TOWER_BOT_2,
		TOWER_TOP_2,
		TOWER_MID_1,
		TOWER_BOT_1,
		TOWER_TOP_1
	}
	for i = 1, #towersList do
		local tower = GetTower(GetTeam(), i)
		if tower ~= nil and tower:WasRecentlyDamagedByAnyHero(3.0) then
			return false
		end
	end
	return true
end

function X.SuitableToOutposts(outpost)
	local Enemies = J.GetAroundTargetEnemyUnitCount(bot, 800);
	local OutpostsEnemies = J.GetAroundTargetEnemyUnitCount(outpost, 800);
	local Allys =  J.GetUnitAllyCountAroundEnemyTarget(bot, 800);
	local OutpostsAllys = J.GetUnitAllyCountAroundEnemyTarget(outpost, 800);
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes(1300, true, BOT_MODE_NONE);

	local mode = bot:GetActiveMode();

	--如果前哨尚未被任何阵营占领，则降低一些安全条件
	if GetTeam() ~= TEAM_RADIANT and GetTeam() ~= TEAM_DIRE then
		if ( ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_MODERATE )
			or mode == BOT_MODE_ATTACK
			or mode == BOT_MODE_RUNE
			or mode == BOT_MODE_DEFEND_ALLY
			or mode == BOT_MODE_DEFEND_TOWER_TOP
			or mode == BOT_MODE_DEFEND_TOWER_MID
			or mode == BOT_MODE_DEFEND_TOWER_BOT
			or #tableNearbyEnemyHeroes >= 3
			or not bot:WasRecentlyDamagedByAnyHero(2.0)
			) 
		then
			return false;
		end
	else
		if ( ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_MODERATE )
			or mode == BOT_MODE_ATTACK
			or mode == BOT_MODE_RUNE 
			or mode == BOT_MODE_DEFEND_ALLY
			or mode == BOT_MODE_DEFEND_TOWER_TOP
			or mode == BOT_MODE_DEFEND_TOWER_MID
			or mode == BOT_MODE_DEFEND_TOWER_BOT
			or Enemies > Allys + 2
			or OutpostsEnemies > OutpostsAllys + 2
			or #tableNearbyEnemyHeroes >= 2
			or ( #tableNearbyEnemyHeroes >= 1 and X.IsIBecameTheTarget(tableNearbyEnemyHeroes) )
			or bot:WasRecentlyDamagedByAnyHero(5.0)
			) 
		then
			return false;
		end
	end

	return true;
end

function X.IsIBecameTheTarget(units)
	for _,u in pairs(units) do
		if u:GetAttackTarget() == bot then
			return true;
		end
	end
	return false;
end
-- dota2jmz@163.com QQ:2462331592。