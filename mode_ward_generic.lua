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

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local bot = GetBot();
local X = {}
local AvailableSpots = {};
local nWardCastRange = 500;
local itemWard = nil;
local targetLoc = nil;
local wardCastTime = -90;
local blockBreep = nil;
local firstCreep = true;


bot.lastSwapWardTime = -90;
bot.ward = false;


local vNonStuck = Vector(-2610.000000, 538.000000, 0.000000);


local walkMode = false;
local walkLocation = Vector(0,0);

local nStartTime = RandomInt(1,10);

function GetDesire()
	
	if bot:GetUnitName() == "npc_dota_hero_necrolyte" 
	   and bot:GetLevel() > 10
	   and bot:IsAlive()
	   and not bot:IsChanneling()
	   and not bot:IsCastingAbility()
	   and bot:NumQueuedActions() <= 0
	then
		local cAbilty = bot:GetAbilityByName( "necrolyte_death_pulse" );
		local nEnemys = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE); 
		if cAbilty ~= nil and #nEnemys == 0
		   and ( cAbilty:IsFullyCastable() or (cAbilty:GetCooldownTimeRemaining() < 3 and bot:GetMana() > 180) )
		then
			local nAoe = bot:FindAoELocation( true, false, bot:GetLocation(),700, 475, 0.5, 0);
			local nLaneCreeps = bot:GetNearbyLaneCreeps(1000,true);
			if nAoe.count >= 3 
				and #nLaneCreeps >= 3
			then
				walkMode = true;
				walkLocation = nAoe.targetloc;
				return BOT_MODE_DESIRE_VERYHIGH;
			end
		end
	end
	
	itemWard = J.Site.GetItemWard(bot);

	if bot:IsChanneling() 
	   or bot:IsIllusion() 
	   or bot:IsInvulnerable() 
	   or not X.IsSuitableToWard()
	   or not bot:IsAlive()
	then
		return BOT_MODE_DESIRE_NONE;
	end

	--由于抢符进程太长，导致卡兵没有时间，如果恰巧没有遇上敌人且抢完符，可以尝试赶着去卡一下试试
	if DotaTime() > 0
	   and firstCreep
	   and bot:IsAlive()
	then
		local nEnemys = J.GetAroundTargetEnemyUnitCount(bot, 1000)
		if nEnemys > 0 then
			firstCreep = false;
			return BOT_MODE_DESIRE_NONE;
		end
		--计算出当前分路小兵位置并执行卡兵
		local fLaneCreepAmount = GetLaneFrontAmount(GetTeam(), bot:GetAssignedLane(), true)
		local fLaneCreepLocation = GetLocationAlongLane(bot:GetAssignedLane(), fLaneCreepAmount)

		local botLoc = bot:GetLocation()
		--劣势路卡
		if ((GetTeam() == TEAM_RADIANT and bot:GetAssignedLane() == LANE_TOP and fLaneCreepLocation.y < botLoc.y)
		   or (GetTeam() == TEAM_DIRE and bot:GetAssignedLane() == LANE_BOT and fLaneCreepLocation.y > botLoc.y))
		then
			blockBreep = fLaneCreepLocation;
			return BOT_MODE_DESIRE_ABSOLUTE;
		else
			firstCreep = false;
		end
	end

	if DotaTime() < 25 + nStartTime
	then
		return BOT_MODE_DESIRE_NONE;
	end	
	
	if itemWard ~= nil  then
		
		AvailableSpots = J.Site.GetAvailableSpot(bot);
		targetLoc, targetDist = J.Site.GetClosestSpot(bot, AvailableSpots);
		if targetLoc ~= nil and DotaTime() > wardCastTime + 1.0 then
			bot.ward = true;
			return math.floor((RemapValClamped(targetDist, 6000, 0, BOT_MODE_DESIRE_MODERATE, BOT_MODE_DESIRE_VERYHIGH))*20)/20;
		end
	end
	
	return BOT_MODE_DESIRE_NONE;
end

function OnStart()
	if itemWard ~= nil and not walkMode then
		local wardSlot = bot:FindItemSlot(itemWard:GetName());
		if bot:GetItemSlotType(wardSlot) == ITEM_SLOT_TYPE_BACKPACK then
			local leastCostItem = X.FindLeastItemSlot();
			if leastCostItem ~= -1 then
				bot.lastSwapWardTime = DotaTime();
				bot:ActionImmediate_SwapItems( wardSlot, leastCostItem );
				return
			end
			local active = bot:GetItemInSlot(leastCostItem);
			print(active:GetName()..'IsCastable:'..tostring(active:IsFullyCastable()));
		end
	end
end

function OnEnd()
	AvailableSpots = {};
	itemWard = nil;
	walkMode = false;
	blockBreep = nil;
end

function Think()

	if GetGameState()~=GAME_STATE_PRE_GAME and GetGameState()~= GAME_STATE_GAME_IN_PROGRESS then
		return;
	end
	
	if blockBreep ~= nil then

		--外塔位置
		local teamLocation = X.GetLaningTeamLocation(bot:GetAssignedLane())

		if GetUnitToLocationDistance(bot,blockBreep) <= 1200
		then
			--接近目标位置
			local nCreep = bot:GetNearbyLaneCreeps(1200,false);
			--如果附近有小兵
			if nCreep[1] ~= nil and nCreep[1]:IsAlive()
			then
				local botToCreepDistance = GetUnitToLocationDistance(bot, nCreep[1]:GetLocation())
				if botToCreepDistance <= 25
				   and ((bot:GetAssignedLane() == LANE_TOP and nCreep[1]:GetLocation().y < bot:GetLocation().y)
				   or (bot:GetAssignedLane() == LANE_BOT and nCreep[1]:GetLocation().y > bot:GetLocation().y))
				then
					--距离小兵小于25的时候，卡一下兵
					if botToCreepDistance > 3 then
						bot:Action_ClearActions(true);
					else
						--如果太近了，预测一个稍远点的地方前进（防止小兵面向影响预测）
						bot:Action_MoveToLocation(nCreep[1]:GetExtrapolatedLocation(1.5));
					end
					return;
				else
					--如果离小兵还太远或太近了，则预判小兵位置，跟着走
					if botToCreepDistance < 200 then
						bot:Action_MoveToLocation(nCreep[1]:GetExtrapolatedLocation(0.8));
					else
						bot:Action_MoveToLocation(nCreep[1]:GetExtrapolatedLocation(2));
					end
					return;
				end
			end
			--如果没有小兵，停止卡兵（理论上不应存在这个情况）
			if #nCreep == 0 then blockBreep = nil; end
			return;
		else
			--没有接近目标位置

			--拦截位置计算
			local angle = math.deg(math.asin(J.GetLocationToLocationDistance(blockBreep, teamLocation) / GetUnitToLocationDistance(bot, blockBreep)))

			if angle > 1 and angle < 70 then
				--移动到拦截位置
				local intercept = blockBreep
				if bot:GetAssignedLane() == LANE_BOT then
					intercept = Vector(blockBreep.x + (teamLocation.x - blockBreep.x) * (angle / 100), blockBreep.Y)
				else
					intercept = Vector(blockBreep.x, blockBreep.y + (teamLocation.y - blockBreep.y) * (angle / 100))
				end
				bot:Action_MoveToLocation(intercept);
			else
				--移动到兵线位置
				bot:Action_MoveToLocation(blockBreep);
			end
			return;
		end
	end

	if walkMode then
		local nCreep = bot:GetNearbyLaneCreeps(1000,true);
		if GetUnitToLocationDistance(bot,walkLocation) <= 20
		then
			if nCreep[1] ~= nil and nCreep[1]:IsAlive()
			then
				bot:Action_AttackUnit(nCreep[1], true);
			end
			if #nCreep == 0 then walkMode = false; end
			return;
		else
			bot:Action_MoveToLocation(walkLocation);
			if #nCreep == 0 then walkMode = false; end
			return;
		end
	end

	
	if bot.ward then
		if targetDist <= nWardCastRange then
			if  DotaTime() > bot.lastSwapWardTime + 6.1 then
				bot:Action_UseAbilityOnLocation(itemWard, targetLoc);
				wardCastTime = DotaTime();	
				return
			else
				if targetLoc == Vector(-2948.000000, 769.000000, 0.000000) then
					bot:Action_MoveToLocation(vNonStuck +RandomVector(300));
					return
				else	
					bot:Action_MoveToLocation(targetLoc +RandomVector(300));
					return
				end
			end
		else
			if targetLoc == Vector(-2948.000000, 769.000000, 0.000000) then
				bot:Action_MoveToLocation(vNonStuck +RandomVector(100));
				return
			else	
				bot:Action_MoveToLocation(targetLoc +RandomVector(100));
				return
			end
		end
	end
	
	

end


function X.FindLeastItemSlot()
	local minCost = 100000;
	local idx = -1;
	for i=0,5 do
		if  bot:GetItemInSlot(i) ~= nil and bot:GetItemInSlot(i):GetName() ~= "item_aegis"  then
			local _item = bot:GetItemInSlot(i):GetName()
			if( GetItemCost(_item) < minCost ) then
				minCost = GetItemCost(_item);
				idx = i;
			end
		end
	end
	return idx;
end


--check if the condition is suitable for warding
function X.IsSuitableToWard()
	local Enemies = bot:GetNearbyHeroes(1300, true, BOT_MODE_NONE);
	local mode = bot:GetActiveMode();
	if ( ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_MODERATE )
		or mode == BOT_MODE_ATTACK
		or mode == BOT_MODE_RUNE 
		or mode == BOT_MODE_DEFEND_ALLY
		or mode == BOT_MODE_DEFEND_TOWER_TOP
		or mode == BOT_MODE_DEFEND_TOWER_MID
		or mode == BOT_MODE_DEFEND_TOWER_BOT
		or #Enemies >= 2
		or ( #Enemies >= 1 and X.IsIBecameTheTarget(Enemies) )
		or bot:WasRecentlyDamagedByAnyHero(5.0)
		) 
	then
		return false;
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

function X.GetLaningTeamLocation(nLane)
	local myTeam = GetTeam()

	local teamT1Top = nil; 
	if GetTower(myTeam,TOWER_TOP_1) ~= nil then teamT1Top = GetTower(myTeam,TOWER_TOP_1):GetLocation(); end

	local teamT1Mid = nil;
	if GetTower(myTeam,TOWER_MID_1) ~= nil then teamT1Mid = GetTower(myTeam,TOWER_MID_1):GetLocation(); end

	local teamT1Bot = nil;
	if GetTower(myTeam,TOWER_BOT_1) ~= nil then teamT1Bot = GetTower(myTeam,TOWER_BOT_1):GetLocation(); end


	if nLane == LANE_TOP then
		return teamT1Top
	elseif nLane == LANE_MID then
		return teamT1Mid
	elseif nLane == LANE_BOT then
		return teamT1Bot			
	end	
	return teamT1Mid
end	
-- dota2jmz@163.com QQ:2462331592。
