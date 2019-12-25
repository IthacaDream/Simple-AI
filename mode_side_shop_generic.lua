----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 2018.11.21
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Refactor: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------
if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or GetBot():IsIllusion() then
	return;
end

local bot = GetBot()
local X = {}
local targetWatchTower = nil
local activeWatchTowerCD = 12.0
local lastActiveWatchTowerTime = 0
local nWatchTower_1 = nil
local nWatchTower_2 = nil

function GetDesire()

	if DotaTime() < 9 * 60 + 55 
		or bot:HasModifier("modifier_arc_warden_tempest_double") 
		or bot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE 
	then
		return BOT_MODE_DESIRE_NONE
	end

	if targetWatchTower ~= nil
		and GetUnitToUnitDistance(bot,targetWatchTower) <= 3300
		and targetWatchTower:GetTeam() ~= bot:GetTeam()
		and lastActiveWatchTowerTime + activeWatchTowerCD < DotaTime()
		and X.IsSuitableToActiveWatchTower()
	then
		local nBonusDesire = -0.05
		
		if DotaTime() % 600 > 540 then nBonusDesire = 0.03 end
		
		if GetUnitToUnitDistance(bot,targetWatchTower) <= 600 
		then nBonusDesire = nBonusDesire + 0.02 end
		
		if bot:IsChanneling() and bot:GetActiveMode() == BOT_MODE_SIDE_SHOP 
		then nBonusDesire = nBonusDesire + 0.1 end
	
		return BOT_MODE_DESIRE_HIGH + nBonusDesire
	end
	
	targetWatchTower = X.GetNearestWatchTower(bot)	
	if	targetWatchTower ~= nil
		and targetWatchTower:GetTeam() == bot:GetTeam()
	then
		lastActiveWatchTowerTime = DotaTime()
	end
			
	return BOT_MODE_DESIRE_NONE

end

function Think()

	if  bot:IsChanneling() 
		or bot:NumQueuedActions() > 0
		or bot:IsCastingAbility()
		or bot:IsUsingAbility()
	then 
		return
	end
	
	if GetUnitToUnitDistance(bot,targetWatchTower) > 600
	then
		bot:Action_MoveToLocation(targetWatchTower:GetLocation())
	else
		bot:Action_AttackUnit(targetWatchTower,false)
	end
		
end

function OnStart()

end


function OnEnd()

	targetWatchTower = nil

end

function X.GetNearestWatchTower(bot)	
	
	if nWatchTower_1 == nil 
	then
		local allUnitList = GetUnitList(UNIT_LIST_ALL)
		for _,v in pairs(allUnitList)
		do
			if v:GetUnitName() == 'npc_dota_watch_tower'
			then
				if nWatchTower_1 == nil
				then
					nWatchTower_1 = v
				else
					nWatchTower_2 = v
				end
			end
		end	
	end

	if  nWatchTower_1 ~= nil and nWatchTower_2 ~= nil
		and GetUnitToUnitDistance(bot,nWatchTower_1) < GetUnitToUnitDistance(bot,nWatchTower_2)
	then
		return nWatchTower_1
	else
		return nWatchTower_2		
	end
	
	return nil
end

function X.IsSuitableToActiveWatchTower()

	local mode = bot:GetActiveMode()
	local nEnemies = bot:GetNearbyHeroes(1400, true, BOT_MODE_NONE)
	local nAttackAllies = bot:GetNearbyHeroes(1200,false,BOT_MODE_ATTACK)
	local nRetreatAllies = bot:GetNearbyHeroes(1200,false,BOT_MODE_RETREAT)
	
	if ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH )
		or ( mode == BOT_MODE_RETREAT and bot:WasRecentlyDamagedByAnyHero(2.0) )
		or ( #nAttackAllies >= 1 )
		or ( #nEnemies >= 1 and ( X.IsEnemyTargetBot(nEnemies) or #nEnemies >= 2 ) )	
		or ( #nRetreatAllies >= 2 and nRetreatAllies[2]:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH )
	then
		return false
	end

	return true
	
end

function X.IsEnemyTargetBot(units)
	for _,u in pairs(units) 
	do
		if u:GetAttackTarget() == bot 
		   or u:IsFacingLocation(bot:GetLocation(),16)
		then
			return true
		end
	end
	return false
end
-- dota2jmz@163.com QQ:2462331592..