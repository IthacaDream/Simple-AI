----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 2018.11.21
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Refactoring: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------


local X = {}
local bot = GetBot()
local bDebugMode = ( 1 == 10 )

if bot:IsInvulnerable() or not bot:IsHero() or bot:IsIllusion() or bot:GetUnitName() == "npc_dota_hero_techies"
then
	return;
end

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local C  = require(GetScriptDirectory()..'/AuxiliaryScript/BotChat')
local H  = require(GetScriptDirectory()..'/AuxiliaryScript/HttpServer')
local BotBuild = dofile(GetScriptDirectory().."/BotLib/"..string.gsub(bot:GetUnitName(), "npc_dota_", ""))

if BotBuild == nil then return end

if GetTeam() ~= TEAM_DIRE
then
	print(J.Chat.GetNormName(bot)..': Hello, Dota2 World!')
end

C.GetScenario()
local bDeafaultAbilityHero = BotBuild['bDeafaultAbility'];
local bDeafaultItemHero = BotBuild['bDeafaultItem'];
local sAbilityLevelUpList = BotBuild['sSkillList'];


local function AbilityLevelUpComplement()  

	if GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS 
	then
		return;
	end

	if not bot:IsAlive() and bot:NumQueuedActions() > 0 then
		 bot:Action_ClearActions( false ) 
		 return
	end	

	if DotaTime() < 15 then
		bot.theRole = J.Role.GetCurrentSuitableRole(bot, bot:GetUnitName());	
	end	
		
	local botLoc = bot:GetLocation();
	if bot:IsAlive() and DotaTime() > 20
	   and bot:GetCurrentActionType() == BOT_ACTION_TYPE_MOVE_TO 
	   and not IsLocationPassable(botLoc) 
	then
		if bot.stuckLoc == nil then
			bot.stuckLoc = botLoc
			bot.stuckTime = DotaTime();
		elseif bot.stuckLoc ~= botLoc then
			bot.stuckLoc = botLoc
			bot.stuckTime = DotaTime();
		end
	else	
		bot.stuckTime = nil;
		bot.stuckLoc = nil;
	end	
	
	if bot:GetAbilityPoints() > 0 
	   --and bot:GetLevel() <= 25
	   and sAbilityLevelUpList[1] ~= nil
	then
		local ability = bot:GetAbilityByName(sAbilityLevelUpList[1]);
		if ability ~= nil 
		   and not ability:IsHidden()  --fix kunkka bug
		   and ability:CanAbilityBeUpgraded() 
		   and ability:GetLevel() < ability:GetMaxLevel() 
		then
			bot:ActionImmediate_LevelAbility(sAbilityLevelUpList[1]);
			table.remove(sAbilityLevelUpList,1);
			return;
		end
	end
	
	
end

function X.GetNumEnemyNearby(building)
	local nearbynum = 0;
	for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id);
			if info ~= nil then
				local dInfo = info[1]; 
				if dInfo ~= nil 
				   and GetUnitToLocationDistance(building, dInfo.location) <= 2999 
				   and dInfo.time_since_seen < 1.0 
				then
					nearbynum = nearbynum + 1;
				end
			end
		end
	end
	return nearbynum;
end


local fDeathTime = 0;
function X.GetRemainingRespawnTime()
	
	if fDeathTime == 0 then
		return 0;
	else
		return bot:GetRespawnTime() - ( DotaTime() - fDeathTime ) ;
	end
	
end

local nJiDiCount = RandomInt(14,20);
local nLastGold = 9999
local nLastKillCount = 999
function X.SetTalkMessage()

	local nBotID = bot:GetPlayerID()
	local nCurrentGold = bot:GetGold()	
	if bot:IsAlive()
		and nCurrentGold > nLastGold + 600
		and GetHeroKills(nBotID) > nLastKillCount
	then
		local sTauntMark = "?"
		if nCurrentGold > nLastGold + 750 then sTauntMark = "??" end
		if nCurrentGold > nLastGold + 900 then sTauntMark = "???" end
		bot:ActionImmediate_Chat( sTauntMark, true );
	end
	nLastKillCount = GetHeroKills(nBotID)
	nLastGold = nCurrentGold

	
	if GetHeroKills(nBotID) == 0 
		and GetHeroDeaths(nBotID) >= nJiDiCount
		and J.Role.NotSayJiDi()
	then
		local sJiDi = RandomInt(1,9) >= 3 and "jidi,xiayiba" or "jidi,gkd"
		bot:ActionImmediate_Chat( sJiDi, true );
		J.Role['sayJiDi'] = true
	end

end


local bArcWardenClone = false;
local function BuybackUsageComplement() 
	
	X.SetTalkMessage()	
	
	if bot:GetLevel() <=  15
	   or bArcWardenClone
	   or not J.Role.ShouldBuyBack()
	then
		return;
	end
	
	if bot:HasModifier('modifier_arc_warden_tempest_double') then
		bArcWardenClone = true 
		return;
	end
	
	if bot:IsAlive() and fDeathTime ~= 0 then
		fDeathTime = 0;
	end
	
	if not bot:IsAlive() then	
		if fDeathTime == 0 then fDeathTime = DotaTime() end
	end

	if not bot:HasBuyback() then return end

	if bot:GetRespawnTime() < 60 then
		return;
	end
	
	local nRespawnTime = X.GetRemainingRespawnTime();
	
	if bot:GetLevel() > 24
	   and nRespawnTime > 80
	then
		local nTeamFightLocation = J.GetTeamFightLocation(bot);
		if nTeamFightLocation ~= nil 
		then
			J.Role['lastbbtime'] = DotaTime();
			bot:ActionImmediate_Buyback();
			return;
		end
	end

	
	if nRespawnTime < 50 then
		return;
	end
	
	
	local ancient = GetAncient(GetTeam());
	
	if ancient ~= nil 
	then
		local nEnemyCount = X.GetNumEnemyNearby(ancient);
		local nAllyCount = J.GetNumOfAliveHeroes(false);
		if  nEnemyCount > 0 and nEnemyCount >= nAllyCount 
		then
			J.Role['lastbbtime'] = DotaTime();
			bot:ActionImmediate_Buyback();
			return;
		end	
	end

end


local courierTime = -90;
local cState = -1;
bot.SShopUser = false;
local nReturnTime = -90; 

local function CourierUsageComplement()

	if GetGameMode() == 23 
	   or DotaTime() < -56
	   or bot:HasModifier("modifier_arc_warden_tempest_double") 
	   or nReturnTime + 5.0 > DotaTime()
	then
		return;
	end
	
	if bot.theCourier == nil 
	then 
		bot.theCourier = X.GetBotCourier(bot)
		return 
	end
	
	--------*******----------------*******----------------*******--------
	local bDebugCourier = ( 1 == 10 )
	local npcCourier = bot.theCourier
	local cState = GetCourierState( npcCourier );
	local courierHP = npcCourier:GetHealth() / npcCourier:GetMaxHealth(); 
	local currentTime = DotaTime();
	local botIsAlive = bot:IsAlive();
	local botLV = bot:GetLevel();
	local useCourierCD = 1.2;
	local protectCourierCD = 5.0;
	--------*******----------------*******----------------*******--------
	
		
	if cState == COURIER_STATE_DEAD then return	end	
	
	if X.IsCourierTargetedByUnit(npcCourier) 
	then
		if currentTime > nReturnTime + protectCourierCD then
			nReturnTime = currentTime;
			
			J.SetReportMotive(bDebugCourier,"IsCourierTargetedByUnit");
			
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN_STASH_ITEMS );
			
			local abilityBurst = npcCourier:GetAbilityByName('courier_burst');
			if botLV >= 10 and abilityBurst:IsFullyCastable() 
			then bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_BURST ) end
			
			return;
		end
	end
		
	if bot.SShopUser and ( not botIsAlive or bot:GetActiveMode() == BOT_MODE_SECRET_SHOP or not bot.SecretShop  ) 
	then
		bot.SShopUser = false;
		J.SetReportMotive(bDebugCourier,"Releasing the courier to anticipate secret shop stuck");
		bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN_STASH_ITEMS );
		return
	end
	
	if (cState == COURIER_STATE_RETURNING_TO_BASE 
		or cState == COURIER_STATE_AT_BASE
		or cState == COURIER_STATE_IDLE ) 
	   and currentTime > nReturnTime + protectCourierCD  
	then 
		
		if cState == COURIER_STATE_AT_BASE and courierHP < 0.9 then
			return;
		end
		
		--RETURN COURIER TO BASE WHEN IDLE (THERE BE A BUG TO TEST)
		if cState == COURIER_STATE_IDLE and npcCourier:DistanceFromFountain() > 800 
		then
			J.SetReportMotive(bDebugCourier,"RETURN COURIER TO BASE WHEN IDLE");
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN_STASH_ITEMS );
			return
		end
		
		--TAKE ITEM FROM STASH (AND COURIER WILL TRANSFER IT)
		if botIsAlive 
		   and ( cState == COURIER_STATE_AT_BASE
				 or ( cState == COURIER_STATE_IDLE and npcCourier:DistanceFromFountain() < 900 ) )
		then
			local nMSlot = X.GetNumStashItem(bot);
			if nMSlot > 0 
 			then
				if ( bot.currListItemToBuy ~= nil and #bot.currListItemToBuy == 0 )
					or ( bot.currentComponentToBuy ~= nil 
						 and ( IsItemPurchasedFromSecretShop(bot.currentComponentToBuy) 
								or bot:GetGold() + 50 < GetItemCost( bot.currentComponentToBuy )))
				then
					J.SetReportMotive(bDebugCourier,"TAKE ITEM FROM STASH");
					bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_TAKE_STASH_ITEMS );
					courierTime = currentTime;
				end
			end
		end
		
		--MAKE COURIER GOES TO SECRET SHOP
		if  botIsAlive and bot.SecretShop and npcCourier:DistanceFromFountain() < 7000 
			and X.GetCourierEmptySlot(npcCourier) >= 2
		    and currentTime > courierTime + useCourierCD 
		then
			J.SetReportMotive(bDebugCourier,"MAKE COURIER GOES TO SECRET SHOP");
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_SECRET_SHOP )
			bot.SShopUser = true;
			courierTime = currentTime;
			return
		end
		
		--TRANSFER ITEM IN COURIER
		if	botIsAlive 
			and bot:GetCourierValue() > 0
			and bot:GetStashValue() < 100
			and ( not X.IsInvFull(bot) or ( X.GetNumStashItem(bot) == 0 and bot.currListItemToBuy ~= nil and #bot.currListItemToBuy == 0) )
			and ( npcCourier:DistanceFromFountain() < 4000 + botLV * 200 or GetUnitToUnitDistance(bot, npcCourier) < 1800 ) 
			and currentTime > courierTime + useCourierCD
		then
			J.SetReportMotive(bDebugCourier,"TRANSFER ITEM IN COURIER");
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_TRANSFER_ITEMS )
			courierTime = currentTime;
			return
		end
		
		--RETURN STASH ITEM WHEN DEATH
		if  not botIsAlive 
		    and ( cState == COURIER_STATE_AT_BASE 
			      or (cState == COURIER_STATE_IDLE and npcCourier:DistanceFromFountain() < 800 ) )  
			and bot:GetCourierValue() > 0 
			and X.GetNumStashItem(bot) + 4 <= X.GetCourierEmptySlot(npcCourier)
			and currentTime > courierTime + useCourierCD
		then
			J.SetReportMotive(bDebugCourier,"RETURN STASH ITEM WHEN DEATH");
			bot:ActionImmediate_Courier( npcCourier, COURIER_ACTION_RETURN_STASH_ITEMS );
			courierTime = currentTime;
			return
		end
		
	end
	
end

function X.GetBotCourier(bot)
	
	local nPlayerID = bot:GetPlayerID()
	
	for nCourierID = 0, 4
	do
		local courier = GetCourier( nCourierID )
		if courier:GetPlayerID() == nPlayerID
		then
			return courier
		end
	end
	
	return nil
end


function X.GetCourierEmptySlot(courier)
	local amount = 0;
	for i=0, 9 do
		if courier:GetItemInSlot(i) == nil then
			amount = amount + 1;
		end
	end
	return amount;
end


function X.GetNumStashItem(unit)
	local amount = 0;
	for i=10, 15 do
		if unit:GetItemInSlot(i) ~= nil 
		then
			amount = amount + 1;
		end
	end
	return amount;
end


function X.IsCourierTargetedByUnit(courier)

	local botLV = bot:GetLevel();
	
	if J.GetHPR(courier) < 0.9 
	then 
		return true;
	end;
	
	if courier:DistanceFromFountain() < 900 then return false end
	
	for i = 0, 10 
	do
		local tower = GetTower(GetOpposingTeam(), i)
		if tower ~= nil 
		then
			local towerTarget = tower:GetAttackTarget()
			
			if towerTarget == courier 
			then
				return true;
			end
			
			if towerTarget == nil
				and GetUnitToUnitDistance(courier,tower) < 999
			then
				return true;
			end	
			
		end
	end
	
	for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) 
	do
		if IsHeroAlive(id) 
		then
			local info = GetHeroLastSeenInfo(id);
			if info ~= nil then
				local dInfo = info[1];
				if dInfo ~= nil 
				   and GetUnitToLocationDistance(courier, dInfo.location) <= 800 
				   and dInfo.time_since_seen < 1.8
			    then
					return true;
				end
			end
		end
	end
	
	local nEnemysHeroesCanSeen = GetUnitList(UNIT_LIST_ENEMY_HEROES);
	for _,enemy in pairs(nEnemysHeroesCanSeen)
	do 
		if GetUnitToUnitDistance(enemy,courier) <= 700 + botLV * 15
		then
			local nNearCourierAllyList = J.GetAlliesNearLoc(enemy:GetLocation(),600);
			if #nNearCourierAllyList == 0 
				or enemy:GetAttackTarget() == courier
			then
				return true;
			end
		end
		
		if enemy:GetUnitName() == 'npc_dota_hero_sniper' 
		   and GetUnitToUnitDistance(enemy,courier) <= 1100 + botLV * 30
		then
			return true;
		end
		
		if GetUnitToUnitDistance(enemy,courier) <= enemy:GetAttackRange() +88
		then
			return true;
		end
	end
	
	local nEnemysHeroes = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
	for _,enemy in pairs(nEnemysHeroes)
	do 
		if GetUnitToUnitDistance(enemy,courier) <= 700 + botLV * 15
		then
			local nNearCourierAllyList = J.GetAlliesNearLoc(enemy:GetLocation(),800);
			if #nNearCourierAllyList == 0
				or enemy:GetAttackTarget() == courier
			then
				return true;
			end
		end
		
		if GetUnitToUnitDistance(enemy,courier) <= enemy:GetAttackRange() +100
		then
			return true;
		end
	end
	
	local nAllEnemyCreeps = GetUnitList(UNIT_LIST_ENEMY_CREEPS);
	local nNearCourierAllyList = J.GetAlliesNearLoc(courier:GetLocation(),1500);
	local nNearCourierAllyCount = #nNearCourierAllyList;
	for _,creep in pairs(nAllEnemyCreeps)
	do
		if  GetUnitToUnitDistance(courier,creep) <= 800
			and ( creep:GetAttackTarget() == courier or botLV > 10 )
			and ( nNearCourierAllyCount == 0 or creep:GetAttackTarget() == courier )
		then
			return true;
		end
	end
	
	return false;
end


function X.IsInvFull(bot)
	for i = 0, 9 
	do
		if bot:GetItemInSlot(i) == nil 
		then
			return false;
		end
	end
	return true;
end


function X.GiveToMidLaner()
	local teamPlayers = GetTeamPlayers(GetTeam())
	local target = nil;
	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);  
		if member ~= nil 
			and not member:IsIllusion() 
			and member:IsAlive() 
			and member:GetAssignedLane() == LANE_MID 
		then
			local num_sts = J.Item.GetItemCount(member, "item_tango_single"); 
			local num_ff = J.Item.GetItemCount(member, "item_faerie_fire");   
			local num_stg = J.Item.GetItemCharges(member, "item_tango");      
			if num_sts + num_stg <= 1 then  
				return member;               
			end
		end
	end
	return nil;
end


local fLastStashItemTimeList = {}
local lastGiveTangoTime = -99;
local aetherRange = 0;
local lastAmuletTime = 0;
local thereBeMonkey = false;
local lastSwitchPtTime = -90
local hNearbyEnemyHeroList = {}
local hNearbyEnemyTowerList = {}
local botTarget = nil
local nMode = -1

local function ItemUsageComplement()

	X.SetStashItemTimeUpdate()

	if not bot:IsAlive() 
	   or bot:IsMuted() 
	   or bot:IsHexed()
	   or bot:IsStunned()
	   or bot:IsChanneling() 
	   or bot:IsInvulnerable()
	   or bot:IsUsingAbility()
	   or bot:IsCastingAbility()
	   or bot:NumQueuedActions() > 0 
	   or bot:HasModifier('modifier_teleporting')
	   or bot:HasModifier('modifier_doom_bringer_doom')
	   or bot:HasModifier('modifier_phantom_lancer_phantom_edge_boost')
	   or ( bot:IsInvisible() and not bot:HasModifier("modifier_phantom_assassin_blur_active") )
    then return	BOT_ACTION_DESIRE_NONE end

	hNearbyEnemyHeroList = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	hNearbyEnemyTowerList = bot:GetNearbyTowers( 888, true ); 
	botTarget = J.GetProperTarget(bot);
	nMode = bot:GetActiveMode();
	
	local aether = J.IsItemAvailable("item_aether_lens");
	if aether ~= nil then aetherRange = 250 else aetherRange = 0 end
	
	local nItemSlot = {5,4,3,2,1,0,16};
	
	for _,nSlot in pairs(nItemSlot)
	do
		local hItem = bot:GetItemInSlot(nSlot);
		if hItem ~= nil
			and hItem:IsFullyCastable()
		then
			local sItemName = hItem:GetName()
			if	X.ConsiderItemDesire[sItemName] ~= nil
				and not X.IsItemInStash(sItemName)
			then
				local nItemDesire,hItemTarget,sCastType,sMotive = X.ConsiderItemDesire[sItemName](hItem)
				
				if nItemDesire > 0
				then
					if J.Item.IsDebugItem(sItemName) and sMotive ~= nil
					then
						local sReportName = string.gsub(sItemName, "item_", "")
						J.SetReportMotive( bDebugMode, sReportName..'→'..sMotive ) 
					end
										
					X.SetUseItem(hItem,hItemTarget,sCastType);
					
					return nSlot + 1
				end				
			end
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE

end

function X.SetUseItem(hItem,hItemTarget,sCastType)
	
	if sCastType == 'none'
	then
		bot:Action_UseAbility(hItem)
		return
	elseif sCastType == 'unit'
		then
			bot:Action_UseAbilityOnEntity(hItem,hItemTarget)
			return
	elseif sCastType == 'ground'
		then
			bot:Action_UseAbilityOnLocation(hItem,hItemTarget)
			return
	elseif sCastType == 'tree'
		then
			bot:Action_UseAbilityOnTree(hItem,hItemTarget)
			return
	elseif sCastType == 'twice'
		then
			bot:Action_UseAbility(hItem)
			bot:ActionQueue_UseAbility(hItem)
			return
	end
	
	if bDebugMode then print("SetUseItem:sCastType Error") end

end

function X.IsWithoutSpellShield(npcEnemy)

	return not npcEnemy:HasModifier("modifier_item_sphere_target")
			and not npcEnemy:HasModifier("modifier_antimage_spell_shield")
			and not npcEnemy:HasModifier("modifier_item_lotus_orb_active")

end

local lastDeleteTime = -90
function X.SetStashItemTimeUpdate()

	local currentTime = DotaTime()

	for i = 6,9
	do
		local hItem = bot:GetItemInSlot(i);
		if hItem ~= nil
		then
			fLastStashItemTimeList[hItem:GetName()] = currentTime
		end		
	end
	
	if currentTime > lastDeleteTime + 7.0
	then
		lastDeleteTime = currentTime
		for k,v in pairs(fLastStashItemTimeList)
		do 
			if	v ~= nil
				and v < currentTime - 7.0
			then
				fLastStashItemTimeList[k] = nil
			end
		end
	end

end

function X.IsItemInStash(sItemName)

	if fLastStashItemTimeList[sItemName] ~= nil
		and DotaTime() < fLastStashItemTimeList[sItemName] + 6.01
	then
		return true
	end
	
	return false

end


X.ConsiderItemDesire = {};

--深渊
X.ConsiderItemDesire["item_abyssal_blade"] = function(hItem)

	local nCastRange = 620 + aetherRange
	local sCastType = 'unit'
	local hEffectTarget = nil
	
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	for _,npcEnemy in pairs( nInRangeEnmyList )
	do
		
		if J.IsValid(npcEnemy)
		   and J.CanCastOnNonMagicImmune(npcEnemy)
		   and X.IsWithoutSpellShield(npcEnemy)
		then
			--Check
			if npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility()
			then
				hEffectTarget = npcEnemy 
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check:'..J.Chat.GetNormName(hEffectTarget)
			end
			
			--Retreat
			if 	nMode == BOT_MODE_RETREAT 
				and not J.IsDisabled(true,npcEnemy)
			then
				hEffectTarget = npcEnemy 
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat:'..J.Chat.GetNormName(hEffectTarget)
			end				
		end
				
	end
	
	--Attack
	if J.IsGoingOnSomeone(bot)
	then		
		if  J.IsValidHero(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange + 50)
			and J.CanCastOnNonMagicImmune(botTarget) 
			and X.IsWithoutSpellShield(botTarget)
			and not J.IsDisabled(true,botTarget)			
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--战鼓
X.ConsiderItemDesire["item_ancient_janggo"] = function(hItem)

	if hItem:GetCurrentCharges() <= 0 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 700
	local sCastType = 'none'	
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnMagicImmune(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--秘法
X.ConsiderItemDesire["item_arcane_boots"] = function(hItem)

	if bot:DistanceFromFountain() < 800 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 1200
	local sCastType = 'none'	
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local hNearbyAllyList = J.GetAllyList(bot,nCastRange)
	
	if #hNearbyAllyList >= 2
		and bot:GetHealth() <= 120
		and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
		return BOT_ACTION_DESIRE_HIGH, hNearbyAllyList[2], sCastType, 'beforedeath'
	end
	
	local nNeedMPCount = 0;
	for _,npcAlly in pairs(hNearbyAllyList)
	do
		if npcAlly ~= nil and npcAlly:IsAlive()
		   and npcAlly:GetMaxMana()- npcAlly:GetMana() > 180
		then
			nNeedMPCount = nNeedMPCount + 1;
		end
		
		if nNeedMPCount >= 2 
		then
			return BOT_ACTION_DESIRE_HIGH, hNearbyAllyList[2], sCastType, 'team_magic'
		end
	end

	if bot:GetMana()/bot:GetMaxMana() < 0.58 
	then  
		return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'self_magic'
	end	
	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--狂战
X.ConsiderItemDesire["item_bfury"] = function(hItem)

	return X.ConsiderItemDesire["item_quelling_blade"](hItem)
	
end

--BKB
X.ConsiderItemDesire["item_black_king_bar"] = function(hItem)

	local nCastRange = 1400
	local sCastType = 'none'	
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if  #nInRangeEnmyList > 0
		and not bot:IsMagicImmune()
		and not bot:IsInvulnerable()
		and not bot:HasModifier('modifier_item_lotus_orb_active') 
		and not bot:HasModifier('modifier_antimage_spell_shield') 
	then
		if bot:IsRooted()
		then
			return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'Rooted'
		end
		
		if ( bot:IsSilenced() and bot:GetMana() > 100 and not bot:HasModifier("modifier_item_mask_of_madness_berserk") )
		then
			return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'Silenced'
		end
		
		if J.IsNotAttackProjectileIncoming(bot, 400) 
		then
			return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'ProjectileIncoming'
		end
		
		if J.IsWillBeCastUnitTargetSpell(bot,1200)
		then
			return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'UnitTargetSpell'
		end
		
		if J.IsWillBeCastPointSpell(bot,1200)
		then
			return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'PointSpell'
		end			
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--刃甲
X.ConsiderItemDesire["item_blade_mail"] = function(hItem)

	local nCastRange = 1200
	local sCastType = 'none'	
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsNotAttackProjectileIncoming(bot, 366)
		and #nInRangeEnmyList >= 1 
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ProjectileIncoming'
	end
	
	for _,npcEnemy in pairs(hNearbyEnemyHeroList)
	do
		if J.IsValidHero(npcEnemy)
		   and J.CanCastOnMagicImmune(npcEnemy)
		   and npcEnemy:GetAttackTarget() == bot
		   and bot:WasRecentlyDamagedByHero(npcEnemy, 5.0)
		then
			hEffectTarget = npcEnemy
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'enemy:'..J.Chat.GetNormName(hEffectTarget)
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--跳刀
X.ConsiderItemDesire["item_blink"] = function(hItem)

	local nCastRange = 300 + aetherRange
	local sCastType = 'ground'	
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsStuck(bot)
	then
		hEffectTarget = J.GetLocationTowardDistanceLocation(bot, GetAncient(GetTeam()):GetLocation(), 1100 )
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Stuck'
	end
	
	--Retreat
	if nMode == BOT_MODE_RETREAT 
		and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
	then
		local bLocation = J.GetLocationTowardDistanceLocation(bot, GetAncient(GetTeam()):GetLocation(), 1199 );
		local nAttackAllyList = bot:GetNearbyHeroes(660,false,BOT_MODE_ATTACK);
		if bot:DistanceFromFountain() > 800 
		   and IsLocationPassable(bLocation) 
		   and ( #nAttackAllyList == 0 or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH *0.9 )
		   and #hNearbyEnemyHeroList >= 1
		then
			hEffectTarget = bLocation
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
		end
	end 
	
	--Farm
	local nEnemyHeroInView = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
	local nAttackAllyList = bot:GetNearbyHeroes(1600,false,BOT_MODE_ATTACK);
	if #nEnemyHeroInView == 0 and not bot:WasRecentlyDamagedByAnyHero(3.0)
	   and #nAttackAllyList == 0 and ( botTarget == nil or not botTarget:IsHero())
	then
		local nAOELocation = bot:FindAoELocation(true,false,bot:GetLocation(),1600,400,0,0);
		local nLaneCreeps = bot:GetNearbyLaneCreeps(1600,true);
		if nAOELocation.count >= 4 
		   and #nLaneCreeps >= 4
		then
			local bCenter = J.GetCenterOfUnits(nLaneCreeps);
			local bDist = GetUnitToLocationDistance(bot,bCenter);
			local vLocation = J.GetLocationTowardDistanceLocation(bot,bCenter, bDist + 550);
			local bLocation = J.GetLocationTowardDistanceLocation(bot,bCenter, bDist - 300);
			if bDist >= 1500 then bLocation = J.GetLocationTowardDistanceLocation(bot,bCenter, 1199); end
			
			if IsLocationPassable(bLocation) 
			   and GetUnitToLocationDistance(bot,bLocation) > 600
			   and IsLocationVisible(vLocation)
			then
				hEffectTarget = bLocation
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'FarmCreep:'..#nLaneCreeps
			end
		end				
	end
	
	--Dodging skill
	if J.IsProjectileIncoming(bot, 1400)
	   and (botTarget == nil 
			or not botTarget:IsHero() 
			or not J.IsInRange(bot,botTarget,bot:GetAttackRange() + 100) )
	then
		hEffectTarget = J.GetLocationTowardDistanceLocation(bot, GetAncient(GetTeam()):GetLocation(), 1199 );
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'DodgingSkill'
	end
	
	--Shopping
	
	--Attack
		
	return BOT_ACTION_DESIRE_NONE
	
end


--奶酪
X.ConsiderItemDesire["item_cheese"] = function(hItem)

	if bot:DistanceFromFountain() < 1200 then return BOT_ACTION_DESIRE_NONE end
	
	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	local nLostHealth = bot:GetMaxHealth() - bot:GetHealth()
	local botHP = bot:GetHealth()/bot:GetMaxHealth()
	local nLostMana = bot:GetMaxMana() - bot:GetMana()
	local botMP = bot:GetMana()/bot:GetMaxMana()
	
	
	if ( nLostHealth > 2500 and nLostMana > 1500 )
		or ( nLostHealth > 2000 and nLostHealth + nLostMana > 3000)
		or ( botHP < 0.4 and botMP < 0.4)
		or ( botHP < 0.2 )
		or ( botMP < 0.1 )
	then	
		if J.IsGoingOnSomeone(bot) 
		then
			if J.IsValidHero(botTarget)
				and J.IsInRange(bot,botTarget,2000)
				and J.CanCastOnMagicImmune(botTarget)
			then
				hEffectTarget = bot
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'		
			end
		end
		
		if J.IsRetreating(bot)
			and bot:WasRecentlyDamagedByAnyHero(4.0)
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'		
		end
	end
	
	return BOT_ACTION_DESIRE_NONE

end


--血精石
X.ConsiderItemDesire["item_bloodstone"] = function(hItem)

	if bot:DistanceFromFountain() < 1200 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.GetHPR(bot) < 0.35
		and bot:WasRecentlyDamagedByAnyHero(3.0)
		and #hNearbyEnemyHeroList >= 1
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end


--血棘
X.ConsiderItemDesire["item_bloodthorn"] = function(hItem)

	return X.ConsiderItemDesire["item_orchid"](hItem)

end

--魔瓶
X.ConsiderItemDesire["item_bottle"] = function(hItem)

	if hItem:GetCurrentCharges() == 0 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 400 + aetherRange
	local sCastType = 'none'	
	local hEffectTarget = nil 
	
	
	--对自己喝

	
	--给队友喝
	
	
	return BOT_ACTION_DESIRE_NONE
	
end


--小净化
X.ConsiderItemDesire["item_clarity"] = function(hItem)

	if bot:DistanceFromFountain() < 2000 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 800 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if  J.GetMPR(bot) < 0.35 
		and not bot:HasModifier("modifier_clarity_potion")
		and #nInRangeEnmyList == 0 
		and not bot:WasRecentlyDamagedByAnyHero(4.0)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self'
	end
	
	if #nInRangeEnmyList == 0 	
	then
		local hAllyList = bot:GetNearbyHeroes(600,false,BOT_MODE_NONE);
		local hNeedManaAlly = nil
		local nNeedManaAllyMana = 99999
		for _,npcAlly in pairs(hAllyList) 
		do
			if J.IsValid(npcAlly)
			   and npcAlly ~= bot
			   and not npcAlly:IsIllusion()
			   and not npcAlly:IsChanneling() 
			   and not npcAlly:HasModifier("modifier_clarity_potion")  
			   and not npcAlly:WasRecentlyDamagedByAnyHero(4.0)
			   and npcAlly:GetMaxMana() - npcAlly:GetMana() > 350 	   				   			
			then
				if(npcAlly:GetMana() < nNeedManaAllyMana )
				then
					hNeedManaAlly = npcAlly
					nNeedManaAllyMana = npcAlly:GetMana()
				end
			end
		end		
		if(hNeedManaAlly ~= nil)
		then
			hEffectTarget = hNeedManaAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly:'..J.Chat.GetNormName(hEffectTarget)
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--赤红甲
X.ConsiderItemDesire["item_crimson_guard"] = function(hItem)

	if bot:DistanceFromFountain() < 400 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 1200
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local hNearbyAllyList = J.GetAllyList(bot,nCastRange);
		
	for _,npcAlly in pairs(hNearbyAllyList) 
	do
		if  J.IsValid(npcAlly) 
			and npcAlly:GetHealth()/npcAlly:GetMaxHealth() < 0.8
			and npcAlly:WasRecentlyDamagedByAnyHero(2.0)
			and not npcAlly:HasModifier("modifier_item_crimson_guard_nostack")
			and #hNearbyEnemyHeroList > 0 
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	local nNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	local nNearbyEnemyTowers = bot:GetNearbyTowers( 800, true ); 
	if #hNearbyAllyList >= 2
	   and (#nNearbyEnemyHeroes + #nNearbyEnemyTowers >= 2 or #nNearbyEnemyHeroes >= 2)
	then
		for _,npcAlly in pairs(hNearbyAllyList) 
		do
			if npcAlly:WasRecentlyDamagedByAnyHero(2.0)
				and not npcAlly:HasModifier("modifier_item_crimson_guard_nostack")
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'NearbyAlly:'..J.Chat.GetNormName(hEffectTarget)
			end
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--吹风
X.ConsiderItemDesire["item_cyclone"] = function(hItem)

	local nCastRange = 650 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsValid(botTarget)
	   and J.CanCastOnNonMagicImmune(botTarget) 
	   and X.IsWithoutSpellShield(botTarget)
	   and J.IsInRange( bot, botTarget, nCastRange + 200 )
	then
		if botTarget:HasModifier('modifier_teleporting') 
			 or botTarget:HasModifier('modifier_abaddon_borrowed_time') 
			 or botTarget:HasModifier("modifier_ursa_enrage")
			 or botTarget:HasModifier("modifier_item_satanic_unholy")
			 or botTarget:IsChanneling()
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check_buff:'..J.Chat.GetNormName(hEffectTarget)
		end
		
		if J.GetHPR(botTarget) > 0.49 and J.IsCastingUltimateAbility(botTarget)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check_ability:'..J.Chat.GetNormName(hEffectTarget)
		end
		
		if J.IsRunning(botTarget) and botTarget:GetCurrentMovementSpeed() > 440
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check_Run:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	if J.CanCastOnNonMagicImmune(bot)
	   and #hNearbyEnemyHeroList > 0
	then
		if bot:GetHealth() < 216 and bot:WasRecentlyDamagedByAnyHero(3.0)
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat:'..J.Chat.GetNormName(hEffectTarget)
		end
		
		if bot:IsRooted() 
			or ( bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT and bot:IsSilenced() )
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Dispel:'..J.Chat.GetNormName(hEffectTarget)
		end
		
		if J.IsUnitTargetProjectileIncoming(bot, 800)
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ProjectileIncoming:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--大根
X.ConsiderItemDesire["item_dagon"] = function(hItem)

	local nCastRange = hItem:GetCastRange() + aetherRange + 50
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	--kill
	
	--attack
	if J.IsGoingOnSomeone(bot)
	then			
		if  J.IsValidHero(botTarget) 
			and J.CanCastOnNonMagicImmune(botTarget)	
			and X.IsWithoutSpellShield(botTarget)
			and J.IsInRange(bot, botTarget, nCastRange)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

X.ConsiderItemDesire["item_dagon_2"] = function(hItem)
	
	return X.ConsiderItemDesire["item_dagon"](hItem)
	
end

X.ConsiderItemDesire["item_dagon_3"] = function(hItem)

	return X.ConsiderItemDesire["item_dagon"](hItem)
	
end

X.ConsiderItemDesire["item_dagon_4"] = function(hItem)

	return X.ConsiderItemDesire["item_dagon"](hItem)
	
end

X.ConsiderItemDesire["item_dagon_5"] = function(hItem)

	return X.ConsiderItemDesire["item_dagon"](hItem)
	
end

--散失
X.ConsiderItemDesire["item_diffusal_blade"] = function(hItem)

	local nCastRange = 630 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if( nMode == BOT_MODE_RETREAT )
	then
		for _,npcEnemy in pairs( hNearbyEnemyHeroList )
		do
			if  J.IsValid(npcEnemy)
				and J.IsMoving(npcEnemy)
				and J.IsInRange(npcEnemy, bot, nCastRange) 
				and bot:WasRecentlyDamagedByHero( npcEnemy, 4.0 )
				and npcEnemy:GetCurrentMovementSpeed() > 200
				and J.CanCastOnNonMagicImmune(npcEnemy) 
				and X.IsWithoutSpellShield(npcEnemy)
				and not J.IsDisabled(true, npcEnemy) 					
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'..J.Chat.GetNormName(hEffectTarget)
			end
		end
	end	

	if J.IsGoingOnSomeone(bot)
	then
		if  J.IsValidHero(botTarget)  
			and J.IsMoving(botTarget)
			and botTarget:GetCurrentMovementSpeed() > 200
			and J.IsInRange(botTarget, bot, nCastRange) 
			and J.CanCastOnNonMagicImmune(botTarget) 
			and X.IsWithoutSpellShield(botTarget)
			and not J.IsDisabled(true, botTarget) 				
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	local npcEnemy = hNearbyEnemyHeroList[1]
	if  J.IsValidHero(npcEnemy)
		and J.IsInRange(bot,npcEnemy,nCastRange - 100)
		and J.CanCastOnNonMagicImmune(npcEnemy) 
		and X.IsWithoutSpellShield(npcEnemy)
		and not J.IsDisabled(true,npcEnemy) 
		and J.IsMoving(npcEnemy)
		and J.IsRunning(npcEnemy)
		and npcEnemy:GetCurrentMovementSpeed() > 300
	then
		hEffectTarget = npcEnemy
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Check'..J.Chat.GetNormName(hEffectTarget)
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end


--芒果
X.ConsiderItemDesire["item_enchanted_mango"] = function(hItem)

	local nCastRange = 300 + aetherRange
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot) 
	   and bot:GetMana() < 100 + bot:GetLevel() * 6
	   and J.IsValidHero(botTarget)
	   and J.IsInRange(bot,botTarget,1000)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--虚灵
X.ConsiderItemDesire["item_ethereal_blade"] = function(hItem)

	local nCastRange = 800 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and J.CanCastOnTargetAdvanced(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange) 
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'..J.Chat.GetNormName(hEffectTarget)
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--心火
X.ConsiderItemDesire["item_faerie_fire"] = function(hItem)

	if bot:DistanceFromFountain() < 1800 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 300 + aetherRange
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if ( nMode == BOT_MODE_RETREAT 
		 and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH 
		 and bot:WasRecentlyDamagedByAnyHero(3.0)
		 and ( bot:GetHealth() / bot:GetMaxHealth() ) < 0.2 ) 
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
	end
	
	--attack
	if J.IsGoingOnSomeone(bot)
		and J.GetHPR(bot) < 0.3
		and J.IsValidHero(botTarget)
		and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
	end
	
	--self
	if DotaTime() > 10 *60 
		and hItem:GetName() == "item_faerie_fire"
		and bot:GetItemInSlot(6) ~= nil
		and bot:GetMaxHealth() - bot:GetHealth() > 200 
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Self'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--大药
X.ConsiderItemDesire["item_flask"] = function(hItem)

	if bot:DistanceFromFountain() < 3000 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 1000
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	if  bot:GetMaxHealth() - bot:GetHealth() > 550
		and #nInRangeEnmyList == 0 
		and not bot:WasRecentlyDamagedByAnyHero(5.0)
		and not bot:HasModifier("modifier_filler_heal") 
		and not bot:HasModifier("modifier_elixer_healing") 
		and not bot:HasModifier("modifier_flask_healing")
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self'
	end
	
	local hAllyList = J.GetAlliesNearLoc(bot:GetLocation(),700)
	local hNeedHealAlly = nil
	local nNeedHealAllyHealth = 99999
	for _,npcAlly in pairs(hAllyList) 
	do
		if J.IsValid(npcAlly) and npcAlly ~= bot
		   and not npcAlly:HasModifier("modifier_filler_heal") 
		   and not npcAlly:HasModifier("modifier_elixer_healing") 
		   and not npcAlly:HasModifier("modifier_flask_healing") 
		   and not npcAlly:WasRecentlyDamagedByAnyHero(4.0)
		   and not npcAlly:IsIllusion()
		   and not npcAlly:IsChanneling()
		   and npcAlly:GetMaxHealth() - npcAlly:GetHealth() > 550 			   				   			
		then
			if(npcAlly:GetHealth() < nNeedHealAllyHealth )
			then
				hNeedHealAlly = npcAlly
				nNeedHealAllyHealth = npcAlly:GetHealth()
			end
		end
	end		
	if hNeedHealAlly ~= nil and #hNearbyEnemyHeroList == 0
	then
		hEffectTarget = hNeedHealAlly
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--推推
X.ConsiderItemDesire["item_force_staff"] = function(hItem)

	local nCastRange = 750 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
		
	local hAllyList = J.GetAlliesNearLoc(bot:GetLocation(),880)
	for _,npcAlly in pairs(hAllyList) 
	do
		if npcAlly ~= nil and npcAlly:IsAlive()
			and J.CanCastOnNonMagicImmune(npcAlly)
		then
			if  not npcAlly:IsInvisible()
				and npcAlly:GetActiveMode() == BOT_MODE_RETREAT
				and npcAlly:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),20)
				and npcAlly:DistanceFromFountain() > 600 
			then		
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'AllyRetreat'
			end
			
			if J.IsGoingOnSomeone(npcAlly)
			then
				local hAllyTarget = J.GetProperTarget(npcAlly);
				if J.IsValidHero(hAllyTarget)
					and J.CanCastOnNonMagicImmune(hAllyTarget)
					and GetUnitToUnitDistance(hAllyTarget,npcAlly) > npcAlly:GetAttackRange() + 100
					and GetUnitToUnitDistance(hAllyTarget,npcAlly) < npcAlly:GetAttackRange() + 700
					and npcAlly:IsFacingLocation(hAllyTarget:GetLocation(),20)
					and not hAllyTarget:IsFacingLocation(npcAlly:GetLocation(),90)
					and J.GetEnemyCount(npcAlly,1600) < 3
				then
					hEffectTarget = npcAlly
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'AllyAttack'
				end
			end
			
			if J.IsStuck(npcAlly)
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'AllyStuck'
			end
		end		
		
	end
	
	for _,npcAlly in pairs(hAllyList) 
	do
		if npcAlly ~= nil and npcAlly:IsAlive()
		   and npcAlly:GetUnitName() == "npc_dota_hero_crystal_maiden"
		   and J.CanCastOnNonMagicImmune(npcAlly)
		   and (npcAlly:IsInvisible() or npcAlly:GetHealth()/npcAlly:GetMaxHealth() > 0.8)
		   and (npcAlly:IsChanneling() and not npcAlly:HasModifier("modifier_teleporting") )
		then
			local enemyHeroesNearbyCM = npcAlly:GetNearbyHeroes(1200,true,BOT_MODE_NONE)
			for _,npcEnemy in pairs( enemyHeroesNearbyCM )
			do
				if npcEnemy ~= nil and npcEnemy:IsAlive()
					and J.CanCastOnNonMagicImmune(npcEnemy)
					and GetUnitToUnitDistance(npcEnemy,npcAlly) > 835
					and npcAlly:IsFacingLocation(npcEnemy:GetLocation(),30)
			    then
					hEffectTarget = npcAlly
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'CM'
				end
			end
		end		
	end
	
	if bot:DistanceFromFountain() < 2600
	then
		for _,npcEnemy in pairs(hNearbyEnemyHeroList) 
		do
			if J.IsValidHero(npcEnemy)
				and J.CanCastOnMagicImmune(npcEnemy)
				and npcEnemy:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),40)
				and GetUnitToLocationDistance(npcEnemy,GetAncient(GetTeam()):GetLocation()) < 1200 
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Enemy_to_ancient'
			end	
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--绿杖
X.ConsiderItemDesire["item_ghost"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if bot:GetAttackTarget() == nil 
	   or bot:GetHealth() < 500 
	then
		for _,npcEnemy in pairs(hNearbyEnemyHeroList)
		do
			if J.IsValidHero(npcEnemy)
			   and J.CanCastOnMagicImmune(npcEnemy)
			   and J.IsInRange(bot,npcEnemy, npcEnemy:GetAttackRange() +100)
			   and npcEnemy:GetAttackTarget() == bot
			   and bot:WasRecentlyDamagedByHero(npcEnemy, 2.0)
			   and npcEnemy:GetAttackDamage() > bot:GetAttackDamage()
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'..J.Chat.GetNormName(hEffectTarget)
			end	
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--微光
X.ConsiderItemDesire["item_glimmer_cape"] = function(hItem)

	local nCastRange = 1049 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	

	if	bot:DistanceFromFountain() > 600
		and #hNearbyEnemyTowerList == 0
		and not bot:HasModifier('modifier_item_dustofappearance')
		and not bot:HasModifier('modifier_item_glimmer_cape') 
	then
	
		if bot:IsSilenced() or bot:IsRooted()
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self_root_or_silence'
		end
		
		if ( J.IsRetreating(bot) and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_VERYHIGH )
			 or ( botTarget == nil and #hNearbyEnemyHeroList > 0 and J.GetHPR(bot) < 0.36 + (0.09 * #hNearbyEnemyHeroList) ) 
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self_retreat'
		end
		
		--------------------
		--use at npcAlly target
		--------------------		
		local hAllyList = bot:GetNearbyHeroes(nCastRange, false, BOT_MODE_NONE);
		for _,npcAlly in pairs(hAllyList) 
		do
			if J.IsValid(npcAlly)
			   and not npcAlly:IsIllusion()
			   and not npcAlly:IsMagicImmune()
			   and not npcAlly:IsInvisible()
			   and npcAlly:DistanceFromFountain() > 600
			   and not npcAlly:HasModifier('modifier_item_glimmer_cape') 
			   and not npcAlly:HasModifier('modifier_item_dustofappearance')
			   and not npcAlly:HasModifier('modifier_arc_warden_tempest_double')
			   and npcAlly:WasRecentlyDamagedByAnyHero(4.0)
			then
				local nNearbyAllyEnemyTowers = npcAlly:GetNearbyTowers(888,true);
				if #nNearbyAllyEnemyTowers == 0
				then
					--retreat
					if J.GetHPR(npcAlly) < 0.35 + (0.05 * #hNearbyEnemyHeroList) 
					   and J.IsRetreating(npcAlly)
					then
						hEffectTarget = npcAlly
						return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ally_retreat:'..J.Chat.GetNormName(hEffectTarget)
					end
					
					--Disable
					if J.IsDisabled(false,npcAlly)  --debug
					then
						hEffectTarget = npcAlly
						return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ally_disable:'..J.Chat.GetNormName(hEffectTarget)
					end
				end
			end
		end
		
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--大鞋
X.ConsiderItemDesire["item_guardian_greaves"] = function(hItem)

	local nCastRange = 1200
	local sCastType = 'none'	
	local hEffectTarget = nil 
	

	local hAllyList = J.GetAllyList(bot,nCastRange);
	for _,npcAlly in pairs(hAllyList) do
		if  npcAlly ~= nil and npcAlly:IsAlive()
			and J.GetHPR(npcAlly) < 0.45 
			and #hNearbyEnemyHeroList > 0 
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal_ally'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	local needHPCount = 0;
	for _,npcAlly in pairs(hAllyList)
	do
		if npcAlly ~= nil
		   and npcAlly:GetMaxHealth()- npcAlly:GetHealth() > 400
		then
			needHPCount = needHPCount + 1;

			if needHPCount >= 2 and  npcAlly:GetHealth()/npcAlly:GetMaxHealth() < 0.55 
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal_two:'..J.Chat.GetNormName(hEffectTarget)
			end
			
			if needHPCount >= 3 
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal_three:'..J.Chat.GetNormName(hEffectTarget)
			end
			
		end
	end

	if bot:GetHealth()/bot:GetMaxHealth() < 0.5
		or bot:IsSilenced()
		or bot:IsRooted()
		or bot:HasModifier("modifier_item_urn_damage") 
		or bot:HasModifier("modifier_item_spirit_vessel_damage")
	then  
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal_self:'..J.Chat.GetNormName(hEffectTarget)
	end
	
	local nNeedMPCount = 0;
	for _,npcAlly in pairs(hAllyList)
	do
		if npcAlly ~= nil
		   and npcAlly:GetMaxMana()- npcAlly:GetMana() > 400
		then
			nNeedMPCount = nNeedMPCount + 1;
		end
		
		if nNeedMPCount >= 2 and bot:GetMana()/bot:GetMaxMana() < 0.2 
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'mana_two:'..J.Chat.GetNormName(hEffectTarget)
		end
		
		if nNeedMPCount >= 3 
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'mana_three:'..J.Chat.GetNormName(hEffectTarget)
		end
		
	end
	
	local nLaneCreeps = bot:GetNearbyLaneCreeps(1200,false);		
	if #nLaneCreeps >= 9 
	then
		local nAOELocation = bot:FindAoELocation(false, false, bot:GetLocation(), 100, 1100 , 0, 200);
		if nAOELocation.count >= 6
		   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= 200
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal_creep:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--点金
X.ConsiderItemDesire["item_hand_of_midas"] = function(hItem)

	local nCastRange = 770 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	

	if #hNearbyEnemyHeroList >= 1 then nCastRange = 628 end
	local hNearbyCreepList = bot:GetNearbyCreeps( nCastRange, true );
	local targetCreep = nil;
	local targetCreepLV = 0
	
	for _,creep in pairs(hNearbyCreepList)
	do
	   if J.IsValid(creep)
		  and not creep:IsMagicImmune()
		  and not creep:IsAncientCreep()
	   then
		   if creep:GetLevel() > targetCreepLV
		   then
			   targetCreepLV = creep:GetLevel()
			   targetCreep = creep
		   end
	   end

	end
	
	if targetCreep ~= nil
	then
		hEffectTarget = targetCreep
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'creep'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--天堂
X.ConsiderItemDesire["item_heavens_halberd"] = function(hItem)

	local nCastRange = 700 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local targetHero = nil;
	local targetHeroDamage = 0		
	for _,npcEnemy in pairs(nInRangeEnmyList)
	do
	   if J.IsValidHero(npcEnemy)
		  and not npcEnemy:IsDisarmed()
		  and not J.IsDisabled(true, npcEnemy)
		  and J.CanCastOnNonMagicImmune(npcEnemy)
		  and X.IsWithoutSpellShield(npcEnemy)
		  and (npcEnemy:GetPrimaryAttribute() ~= ATTRIBUTE_INTELLECT or npcEnemy:GetAttackDamage() > 200)
	   then
		   local nEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL);
		   if ( nEnemyDamage > targetHeroDamage )
		   then
				targetHeroDamage = nEnemyDamage
				targetHero = npcEnemy
		   end
	   end
	end		
	if targetHero ~= nil
	then
		hEffectTarget = targetHero
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'enemy:'..J.Chat.GetNormName(hEffectTarget)
	end	
	
	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN  ) 
	then
		local botTarget = bot:GetAttackTarget();
		if  J.IsRoshan(botTarget) 
			and not J.IsDisabled(true, botTarget)
			and not botTarget:IsDisarmed()
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'roshan:'
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--支配
X.ConsiderItemDesire["item_helm_of_the_dominator"] = function(hItem)

	local nCastRange = 1000 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	
	
	local maxHP = 0;
	local hCreep = nil;
	local hNearbyCreepList = bot:GetNearbyCreeps( nCastRange, true );
	if #hNearbyCreepList >= 2 then
		for _,creep in pairs(hNearbyCreepList)
		do
			if J.IsValid(creep)
			then
				local nCreepHP = creep:GetHealth();
				if nCreepHP > maxHP 
				   and ( creep:GetHealth() / creep:GetMaxHealth() ) > 0.75 
				   and not creep:IsAncientCreep()
				   and not J.IsKeyWordUnit("siege",creep)
				then
					hCreep = creep;
					maxHP = nCreepHP;
				end
			end
		end
	end
	if hCreep ~= nil 
	then
		hEffectTarget = hCreep
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, ':'..hEffectTarget:GetUnitName()
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--挑战
X.ConsiderItemDesire["item_hood_of_defiance"] = function(hItem)

	if bot:HasModifier('modifier_item_pipe_barrier') 
		or J.GetHPR(bot) > 0.88 
	then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if #nInRangeEnmyList > 0 
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--圣洁吊坠
X.ConsiderItemDesire["item_holy_locket"] = function(hItem)

	return X.ConsiderItemDesire["item_magic_wand"](hItem)

end

--大推推
X.ConsiderItemDesire["item_hurricane_pike"] = function(hItem)

	local nCastRange = 800 + aetherRange
	local nNearRange = 400 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nNearRange,true,BOT_MODE_NONE)
	
		
	if ( nMode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH )
	then
		for _,npcEnemy in pairs( hNearbyEnemyHeroList )
		do
			if ( J.IsInRange(bot,npcEnemy,nNearRange) and J.CanCastOnNonMagicImmune(npcEnemy) )
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
			end	
		end
		
		if bot:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),20) 
		   and bot:DistanceFromFountain() > 600 
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat_self'
		end	
	end 
	
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and GetUnitToUnitDistance(botTarget,bot) > bot:GetAttackRange() + 100
			and GetUnitToUnitDistance(botTarget,bot) < bot:GetAttackRange() + 700
			and GetUnitToUnitDistance(botTarget,bot) < GetUnitToLocationDistance(bot,J.GetCorrectLoc(botTarget,1.0)) - 100
			and bot:IsFacingLocation(botTarget:GetLocation(),20)
			and not botTarget:IsFacingLocation(bot:GetLocation(),120)
			and J.GetEnemyCount(bot,1600) <= 2
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
		end	
	end
	
	if bot:GetUnitName() == "npc_dota_hero_drow_ranger"
		or bot:GetUnitName() == "npc_dota_hero_sniper"
	then
		for _,npcEnemy in pairs( hNearbyEnemyHeroList )
		do
			if npcEnemy ~= nil
			   and J.CanCastOnNonMagicImmune(npcEnemy)
			   and GetUnitToUnitDistance( npcEnemy, bot ) <= nNearRange
			   and J.CanCastOnNonMagicImmune(npcEnemy)
			then
				bot:SetTarget(npcEnemy)
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'pull_back'
			end	
		end
	end
	
	local hAllyList = bot:GetNearbyHeroes(nCastRange,false,BOT_MODE_NONE);
	for _,npcAlly in pairs(hAllyList) 
	do
		if npcAlly ~= nil and npcAlly:IsAlive()
		   and npcAlly:GetUnitName() == "npc_dota_hero_crystal_maiden"
		   and J.CanCastOnNonMagicImmune(npcAlly)
		   and X.IsWithoutSpellShield(npcAlly)
		   and (npcAlly:IsInvisible() or npcAlly:GetHealth()/npcAlly:GetMaxHealth() > 0.8)
		   and (npcAlly:IsChanneling() and not npcAlly:HasModifier("modifier_teleporting") )
		then
			local enemyHeroesNearbyCM = npcAlly:GetNearbyHeroes(1200,true,BOT_MODE_NONE)
			for _,npcEnemy in pairs( enemyHeroesNearbyCM )
			do
			   if npcEnemy ~= nil and npcEnemy:IsAlive()
					and J.CanCastOnNonMagicImmune(npcEnemy)
					and GetUnitToUnitDistance(npcEnemy,npcAlly) > 835
					and npcAlly:IsFacingLocation(npcEnemy:GetLocation(),30)
			   then
					hEffectTarget = npcAlly
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'CM'
				end
			end
		end		
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--隐刀
X.ConsiderItemDesire["item_invis_sword"] = function(hItem)

	if bot:IsInvisible() 
		or #hNearbyEnemyTowerList > 0 
		or bot:HasModifier("modifier_item_dustofappearance")
	then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsRetreating(bot)
		and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
		and #hNearbyEnemyHeroList > 0
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
	end
	
	if J.GetHPR(bot) < 0.166
	   and (#hNearbyEnemyHeroList > 0 or bot:WasRecentlyDamagedByAnyHero(5.0))
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'invis'
	end	
	
	if J.IsGoingOnSomeone(bot)
	then
		if 	J.IsValidHero(botTarget)
			and J.CanCastOnMagicImmune(botTarget)
			and not J.IsInRange(bot, botTarget, botTarget:GetCurrentVisionRange())
			and J.IsInRange(bot, botTarget, 2600)
		then
			local hEnemyCreepList = bot:GetNearbyLaneCreeps(800,true);
			if #hEnemyCreepList == 0 and #hNearbyEnemyHeroList == 0
			then
				hEffectTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack:'..J.Chat.GetNormName(hEffectTarget)
			end	
		end		
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--莲花
X.ConsiderItemDesire["item_lotus_orb"] = function(hItem)

	local nCastRange = 1000 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nNearAllyList = bot:GetNearbyHeroes(nCastRange,false,BOT_MODE_NONE);
	
	
	for _,npcAlly in pairs(nNearAllyList)
	do
		if J.IsValid(npcAlly)
			and not npcAlly:IsIllusion()
			and not npcAlly:IsMagicImmune()
			and not npcAlly:IsInvulnerable()
			and not npcAlly:HasModifier('modifier_item_lotus_orb_active') 
			and not npcAlly:HasModifier('modifier_antimage_spell_shield') 
		then
		
			if J.IsUnitTargetProjectileIncoming(npcAlly, 800) 
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ProjectileIncoming'
			end	
		
			if npcAlly:IsRooted()
			   or npcAlly:IsSilenced()
			   or npcAlly:IsDisarmed()
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'dispel:'..J.Chat.GetNormName(hEffectTarget)
			end	
									
			if J.IsWillBeCastUnitTargetSpell(npcAlly,1200)
			then
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'UnitTargetSpell'
			end				
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--魔棒
X.ConsiderItemDesire["item_magic_stick"] = function(hItem)

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local nEnemyCount = #nInRangeEnmyList
	local nHPrate = bot:GetHealth()/bot:GetMaxHealth()
	local nMPrate = bot:GetMana()/bot:GetMaxMana()
	local nCharges = hItem:GetCurrentCharges()
	
	if (nHPrate < 0.5 or nMPrate < 0.3) and nEnemyCount >= 1 and nCharges >= 1 
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '1'
	end	
	
	if ( nHPrate + nMPrate < 1.1 and nCharges >= 7 and nEnemyCount >= 1 )
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '2'
	end	
	
	if ( nCharges >= 9 and bot:GetItemInSlot(6) ~= nil and (nHPrate <= 0.7 or nMPrate <= 0.6))  
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '3'
	end	
		
	return BOT_ACTION_DESIRE_NONE
	
end

--魔杖
X.ConsiderItemDesire["item_magic_wand"] = function(hItem)

	if hItem:GetCurrentCharges() <= 0 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local nEnemyCount = #nInRangeEnmyList
	local nHPrate = bot:GetHealth()/bot:GetMaxHealth()
	local nMPrate = bot:GetMana()/bot:GetMaxMana()
	local nLostHP = bot:GetMaxHealth() - bot:GetHealth()
	local nLostMP = bot:GetMaxMana() - bot:GetMana()
	local nCharges = hItem:GetCurrentCharges()
	
	if ((nHPrate < 0.4 or nMPrate < 0.3) and nEnemyCount >= 1 and nCharges >= 1 )
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '1'
	end	
	
	if ( nHPrate < 0.7 and nMPrate < 0.7 and nCharges >= 12 and nEnemyCount >= 1 ) 		
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '2'
	end	
	
	if ( nCharges >= 19 and bot:GetItemInSlot(6) ~= nil and (nHPrate <= 0.6 or nMPrate <= 0.5 )) 		
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '3'
	end	
	
	if ( nCharges == 20 and nEnemyCount >= 1 and nLostHP > 350 and nLostMP > 350 ) 				
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '4'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--分身
X.ConsiderItemDesire["item_manta"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local nNearbyAttackingAlliedHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
	local nNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	local nNearbyEnemyTowers = bot:GetNearbyTowers(800,true);
	local nNearbyEnemyBarracks = bot:GetNearbyBarracks(600,true);
	local nNearbyAlliedCreeps = bot:GetNearbyLaneCreeps(1000,false);
	local nNearbyEnemyCreeps = bot:GetNearbyLaneCreeps(800,true);
	
	if J.IsPushing(bot)
	then
		if (#nNearbyEnemyTowers >= 1 or #nNearbyEnemyBarracks >= 1)
			and #nNearbyAlliedCreeps >= 1
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'push'
		end	
	end
	
	if J.IsGoingOnSomeone(bot)
	   and J.IsValidHero(botTarget)
	   and J.CanCastOnMagicImmune(botTarget)
	   and J.IsInRange(bot, botTarget, bot:GetAttackRange() -50)
	then
		hEffectTarget = botTarget
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack'..J.Chat.GetNormName(hEffectTarget)
	end	
	
	if  bot:IsRooted()
		or ( bot:IsSilenced() and not bot:HasModifier("modifier_item_mask_of_madness_berserk") )
		or bot:HasModifier('modifier_item_solar_crest_armor_reduction') 
		or bot:HasModifier('modifier_item_medallion_of_courage_armor_reduction') 
		or bot:HasModifier('modifier_item_spirit_vessel_damage')
		or bot:HasModifier('modifier_dragonknight_breathefire_reduction')
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'dispel'
	end	
	
	if J.IsNotAttackProjectileIncoming(bot, 70) 
	   and not bot:IsMagicImmune()
	   and not bot:HasModifier("modifier_antimage_spell_shield")
	   and not bot:HasModifier("modifier_item_sphere_target")
	   and not bot:HasModifier("modifier_item_lotus_orb_active")
	then
		local tAbility = nil;
		if bot:GetUnitName() == "npc_dota_hero_antimage"
		then 
			tAbility = bot:GetAbilityByName("antimage_counterspell") 
		end				
		if tAbility == nil or not tAbility:IsFullyCastable()
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'ProjectileIncoming'
		end	
	end
	
	if J.IsRetreating(bot)
	   and nNearbyEnemyHeroes[1] ~= nil
	   and bot:DistanceFromFountain() > 600
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
	end	
	
	if #nNearbyEnemyCreeps >= 8
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'creep'
	end	

	if bot:WasRecentlyDamagedByAnyHero(5.0)
	   and bot:GetHealth()/bot:GetMaxHealth() < 0.18
	   and bot:DistanceFromFountain() > 300
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Health'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--疯脸
X.ConsiderItemDesire["item_mask_of_madness"] = function(hItem)

	if bot:GetUnitName() == 'npc_dota_hero_drow_ranger' then return BOT_ACTION_DESIRE_NONE end

	local nAttackTarget = bot:GetAttackTarget();
	local nCastRange = bot:GetAttackRange() + 100;
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if  ( J.IsValid(nAttackTarget) or J.IsValidBuilding(nAttackTarget) )
		and J.CanBeAttacked(nAttackTarget)
		and J.IsInRange(bot,nAttackTarget,nCastRange)
		and ( not J.CanKillTarget(nAttackTarget,bot:GetAttackDamage() *2,DAMAGE_TYPE_PHYSICAL)
			  or J.GetAroundTargetEnemyUnitCount(bot, nCastRange ) >= 2 )		    
	then
		local nEnemyHeroInView = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
		if nAttackTarget:IsHero()
			or ( #nEnemyHeroInView == 0 and not bot:WasRecentlyDamagedByAnyHero(2.0))
		then
			if  ( #nEnemyHeroInView == 0 )
				 or ( bot:GetUnitName() ~= "npc_dota_hero_sniper" 
					  and bot:GetUnitName() ~= "npc_dota_hero_medusa" )
			then
				bot:SetTarget(nAttackTarget);
				hEffectTarget = nAttackTarget
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'mask'
			end	
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--勋章
X.ConsiderItemDesire["item_medallion_of_courage"] = function(hItem)

	local nCastRange = 900 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget) 
		   and not botTarget:HasModifier('modifier_item_solar_crest_armor_reduction') 
		   and not botTarget:HasModifier('modifier_item_medallion_of_courage_armor_reduction') 
		   and J.CanCastOnNonMagicImmune(botTarget)
		   and ( J.IsInRange(bot, botTarget, bot:GetAttackRange() + 150 )
				or (J.IsInRange(bot, botTarget, 1000)
					and J.GetAroundTargetOtherAllyHeroCount(botTarget, 600, bot) >= 1) )
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'hero:'..J.Chat.GetNormName(hEffectTarget)
		end	
	end
	
	if #hNearbyEnemyHeroList == 0
	then
		if J.IsValid(botTarget) 
		   and not botTarget:HasModifier('modifier_item_solar_crest_armor_reduction') 
		   and not botTarget:HasModifier('modifier_item_medallion_of_courage_armor_reduction') 
		   and not botTarget:HasModifier("modifier_fountain_glyph")
		   and not J.CanKillTarget(botTarget, bot:GetAttackDamage() *2.38, DAMAGE_TYPE_PHYSICAL)
		   and J.IsInRange(bot, botTarget, bot:GetAttackRange() + 150 )
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'creep:'..J.Chat.GetNormName(hEffectTarget)
		end	
	end
	
	--------
	local hAllyList = bot:GetNearbyHeroes(1000,false,BOT_MODE_NONE);
	for _,npcAlly in pairs(hAllyList) 
	do
		if npcAlly ~= bot
		   and J.IsValidHero(npcAlly)
		   and not npcAlly:IsIllusion()
		   and J.CanCastOnNonMagicImmune(npcAlly)
		   and not npcAlly:HasModifier('modifier_item_solar_crest_armor_addition') 
		   and not npcAlly:HasModifier('modifier_item_medallion_of_courage_armor_addition') 
		   and not npcAlly:HasModifier("modifier_arc_warden_tempest_double")
		   and (  ( J.IsDisabled(false,npcAlly) )
			   or ( J.GetHPR(npcAlly) < 0.35 and #hNearbyEnemyHeroList > 0 and npcAlly:WasRecentlyDamagedByAnyHero(2.0) ) 
			   or ( J.IsValidHero(npcAlly:GetAttackTarget()) and GetUnitToUnitDistance(npcAlly,npcAlly:GetAttackTarget()) <= npcAlly:GetAttackRange() and #hNearbyEnemyHeroList == 0 ) )
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly:'..J.Chat.GetNormName(hEffectTarget)
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--银月
local moonSharedTime = nil --添加使用延迟避免吃得过快以为没出
X.ConsiderItemDesire["item_moon_shard"] = function(hItem)

	if bot:GetNetWorth() < 18000 
		or (bot:GetItemInSlot(6) == nil and bot:GetItemInSlot(7) == nil)
	then
		return BOT_ACTION_DESIRE_NONE
	end

	local nCastRange = 2000
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	
	
	if bot:GetPrimaryAttribute() == ATTRIBUTE_AGILITY 
		and not bot:HasModifier("modifier_item_moon_shard_consumed")
	then
		if moonSharedTime == nil
		then
			moonSharedTime = DotaTime()
		elseif moonSharedTime < DotaTime() - 3.0
		then	
			hEffectTarget = bot
			moonSharedTime = nil
			return BOT_ACTION_DESIRE_HIGH,hEffectTarget,sCastType,"self"
		end
	end

	local targetMember = nil;
	local targetDamage = 0;
	for i = 1, 5
	do
	   local member = GetTeamMember(i);
	   if member ~= nil and member:IsAlive()		   
		  and member:GetAttackDamage() > targetDamage
		  and not member:HasModifier("modifier_item_moon_shard_consumed")
	   then
		   targetMember = member;
		   targetDamage = member:GetAttackDamage();
	   end
	end
	if targetMember ~= nil
	then
		if moonSharedTime == nil
		then
			moonSharedTime = DotaTime()
		elseif moonSharedTime < DotaTime() - 4.0
		then	
			hEffectTarget = targetMember
			moonSharedTime = nil
			return BOT_ACTION_DESIRE_HIGH,hEffectTarget,sCastType,"ally"
		end
	end

	
	return BOT_ACTION_DESIRE_NONE
	
end

--死灵书
X.ConsiderItemDesire["item_necronomicon"] = function(hItem)

	local nCastRange = 750
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if botTarget ~= nil and botTarget:IsAlive()
	   and J.IsInRange(bot, botTarget, 700)
	then
		hEffectTarget = botTarget
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

X.ConsiderItemDesire["item_necronomicon_2"] = function(hItem)

	return X.ConsiderItemDesire["item_necronomicon"](hItem)
	
end

X.ConsiderItemDesire["item_necronomicon_3"] = function(hItem)

	return X.ConsiderItemDesire["item_necronomicon"](hItem)
	
end

--否决
X.ConsiderItemDesire["item_nullifier"] = function(hItem)

	local nCastRange = 800 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then	
		if J.IsValidHero(botTarget) 
		   and J.CanCastOnNonMagicImmune(botTarget) 
		   and J.CanCastOnTargetAdvanced(botTarget)
		   and J.IsInRange(botTarget, bot, nCastRange) 
		   and not botTarget:HasModifier("modifier_item_nullifier_mute")
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'hero:'..J.Chat.GetNormName(hEffectTarget)
		end	
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--紫苑
X.ConsiderItemDesire["item_orchid"] = function(hItem)

	local nCastRange = 900 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	for _,npcEnemy in pairs( nInRangeEnmyList )
	do
		if J.IsValid(npcEnemy)
		   and J.CanCastOnNonMagicImmune(npcEnemy)
		   and X.IsWithoutSpellShield(npcEnemy)
		then
			if (npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility())
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check:'..J.Chat.GetNormName(hEffectTarget)
			end
			
			if J.IsRetreating(bot)
			then
				if not J.IsDisabled(true,npcEnemy)
				then
					hEffectTarget = npcEnemy
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat:'..J.Chat.GetNormName(hEffectTarget)
				end
			end			
		end	
	end	

	if J.IsGoingOnSomeone(bot)
	then		
		if	J.IsValidHero(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange)
			and not J.IsDisabled(true,botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)	
			and X.IsWithoutSpellShield(botTarget)			
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
		
	return BOT_ACTION_DESIRE_NONE
	
end

--相位
X.ConsiderItemDesire["item_phase_boots"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsRunning(bot)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'runing'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--笛子
X.ConsiderItemDesire["item_pipe"] = function(hItem)

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	local hNearbyAllyList = bot:GetNearbyHeroes(1200,false,BOT_MODE_NONE)
	
	
		
	for _,npcAlly in pairs(hNearbyAllyList) 
	do
		if  J.IsValid(npcAlly)
			and not npcAlly:IsIllusion()
			and npcAlly:GetHealth()/npcAlly:GetMaxHealth() < 0.4
			and #hNearbyEnemyHeroList > 0 
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'protect_ally:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	local nNearbyAllyHeroes = bot:GetNearbyHeroes( 1200, false, BOT_MODE_NONE );
	local nNearbyEnemyHeroes = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
	local nNearbyAllyTowers = bot:GetNearbyTowers(1200,true); 
	if (#nNearbyAllyHeroes >= 2 and #nNearbyEnemyHeroes >= 2)
		or (#nNearbyEnemyHeroes >= 2 and #nNearbyAllyHeroes + #nNearbyAllyTowers >= 2)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'protect_team:'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--假腿
X.ConsiderItemDesire["item_power_treads"] = function(hItem)

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	local nPtStat = hItem:GetPowerTreadsStat()	
	if nPtStat == ATTRIBUTE_INTELLECT 
	then 
		nPtStat = ATTRIBUTE_AGILITY
	elseif nPtStat == ATTRIBUTE_AGILITY
		then
			nPtStat = ATTRIBUTE_INTELLECT
	end

	if (   bot:HasModifier("modifier_flask_healing")
		   or  bot:HasModifier("modifier_clarity_potion")
		   or  bot:HasModifier("modifier_item_urn_heal")
		   or  bot:HasModifier("modifier_filler_heal")
		   or  bot:HasModifier("modifier_item_spirit_vessel_heal")
		   or  bot:HasModifier("modifier_bottle_regeneration") )
		   and nMode ~= BOT_MODE_ATTACK 
		   and nMode ~= BOT_MODE_RETREAT 
	then
		if nPtStat ~= ATTRIBUTE_AGILITY
		then
			--切换敏捷腿回复
			lastSwitchPtTime = DotaTime()
			if nPtStat == ATTRIBUTE_STRENGTH
			then
				return BOT_ACTION_DESIRE_HIGH, bot, 'twice', 'power_treads-STRENGTH_to_AGILITY'
			else
				return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'power_treads-INTELLECT_to_AGILITY'
			end
			
		end
	elseif  ( nMode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE ) 
			or nMode == BOT_MODE_EVASIVE_MANEUVERS
			or (J.IsNotAttackProjectileIncoming(bot, 1200))
			or (bot:HasModifier("modifier_sniper_assassinate"))
			or (bot:GetHealth()/bot:GetMaxHealth() < 0.2)
			or (nPtStat == ATTRIBUTE_STRENGTH and bot:GetHealth()/bot:GetMaxHealth() < 0.25)
			or (nMode ~= BOT_MODE_LANING and bot:GetLevel() <= 11 and J.IsEnemyFacingUnit(bot,800,30))
		then
			if nPtStat ~= ATTRIBUTE_STRENGTH
			then
				--切换力量腿吃伤害
				lastSwitchPtTime = DotaTime()
				if nPtStat == ATTRIBUTE_AGILITY
				then
					return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'power_treads-AGILITY_to_STRENGTH'
				else
					return BOT_ACTION_DESIRE_HIGH, bot, 'twice', 'power_treads-INTELLECT_to_STRENGTH'
				end
				
			end
	elseif  nMode == BOT_MODE_ATTACK 
			or nMode == BOT_MODE_TEAM_ROAM
		then
			if J.ShouldSwitchPTStat(bot,hItem) 
			   and lastSwitchPtTime < DotaTime() - 0.2
			then
				--切换主属性腿攻击
				return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'power_treads-To_Main_mode'				
			end
	else
		local hEnemyList = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
		local hCreepList = bot:GetNearbyCreeps(800,true);
		if  #hCreepList == 0
			and #hEnemyList == 0 
			and (botTarget == nil or GetUnitToUnitDistance(bot,botTarget) > 1200)
			and bot:DistanceFromFountain() > 400
			and nMode ~= BOT_MODE_ROSHAN
		then
			if nPtStat ~= ATTRIBUTE_AGILITY
			then
				--切敏捷腿赶路回蓝
				lastSwitchPtTime = DotaTime()
				if nPtStat == ATTRIBUTE_STRENGTH
				then
					return BOT_ACTION_DESIRE_HIGH, bot, 'twice', 'power_treads-STRENGTH_to_AGILITY_run'
				else
					return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'power_treads-INTELLECT_to_AGILITY_run'
				end
				
			end
		elseif J.ShouldSwitchPTStat(bot,hItem)
				and lastSwitchPtTime < DotaTime() - 0.2
			then
				--默认为主属性腿	
				return BOT_ACTION_DESIRE_HIGH, bot, sCastType, 'power_treads-To_Main_default'
		end
	end
	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--补刀斧
X.ConsiderItemDesire["item_quelling_blade"] = function(hItem)

	local nCastRange = 450 + aetherRange
	local sCastType = 'tree'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if DotaTime() < 0 and not thereBeMonkey
	then
		for i, id in pairs(GetTeamPlayers(GetOpposingTeam())) 
		do
			if GetSelectedHeroName(id) == 'npc_dota_hero_monkey_king' 
			then
				thereBeMonkey = true;
			end
		end
	end
	
	if thereBeMonkey
	then
		local theMonkeyKing = nil;
		for _,enemy in pairs(hNearbyEnemyHeroList)
		do
			if enemy:IsAlive()
				and enemy:GetUnitName() == "npc_dota_hero_monkey_king"
			then
				theMonkeyKing = enemy;
				break;
			end		
		end
		
		if theMonkeyKing ~= nil
		   and J.IsInRange(bot,theMonkeyKing,nCastRange)
		then
			local nTrees = bot:GetNearbyTrees(nCastRange);
			for _,tree in pairs(nTrees)
			do
				local treeLoc = GetTreeLocation(tree);
				if GetUnitToLocationDistance(theMonkeyKing,treeLoc) < 30
				then
					return BOT_ACTION_DESIRE_HIGH, tree, sCastType, 'monkey_king'	
				end			
			end
		end
	end
	
	--开视野
	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--刷新球
X.ConsiderItemDesire["item_refresher"] = function(hItem)

	local nCastRange = 1000
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot) 
	   and J.CanUseRefresherShard(bot)  
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--刷新碎片
X.ConsiderItemDesire["item_refresher_shard"] = function(hItem)

	return X.ConsiderItemDesire["item_refresher"](hItem)
	
end


--阿托斯
X.ConsiderItemDesire["item_rod_of_atos"] = function(hItem)

	local nCastRange = 1200 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nEnemysHerosInCastRange = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	for _,npcEnemy in pairs( nEnemysHerosInCastRange )
	do
		if J.IsValid(npcEnemy)
		   and npcEnemy:IsChanneling()
		   and npcEnemy:HasModifier("modifier_teleporting")
		   and J.CanCastOnNonMagicImmune(npcEnemy)
		   and J.CanCastOnTargetAdvanced(npcEnemy)
		then
			hEffectTarget = npcEnemy
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check'
		end
	end
	
	if nMode == BOT_MODE_RETREAT 
	   and  bot:GetActiveModeDesire() > BOT_MODE_DESIRE_MODERATE
	   and	J.IsValid(nEnemysHerosInCastRange[1])
	   and  J.CanCastOnNonMagicImmune(nEnemysHerosInCastRange[1])
	   and  J.CanCastOnTargetAdvanced(nEnemysHerosInCastRange[1])
	   and  not J.IsDisabled(true,nEnemysHerosInCastRange[1])
	then
		hEffectTarget = nEnemysHerosInCastRange[1] 
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
	end

	if J.IsGoingOnSomeone(bot)
	then			
		if  J.IsValidHero(botTarget) 
			and not J.IsDisabled(true,botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and J.CanCastOnTargetAdvanced(botTarget)				
			and GetUnitToUnitDistance(botTarget, bot) <= nCastRange
			and J.IsMoving(botTarget)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack'
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--撒旦
X.ConsiderItemDesire["item_satanic"] = function(hItem)

	local nCastRange = bot:GetAttackRange() + 150
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if  bot:GetHealth()/bot:GetMaxHealth() < 0.62 
		and #hNearbyEnemyHeroList > 0 
		and ( J.IsValidHero(botTarget) and J.IsInRange(bot,botTarget,nCastRange)
			  or ( J.IsValidHero(hNearbyEnemyHeroList[1]) and J.IsInRange(bot,hNearbyEnemyHeroList[1],nCastRange) ) )  
	then
		--bot:SetTarget(botTarget);
		hEffectTarget = botTarget
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--护符
X.ConsiderItemDesire["item_shadow_amulet"] = function(hItem)

	local nCastRange = 600 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if not bot:HasModifier('modifier_invisible')
		and not bot:HasModifier('modifier_item_glimmer_cape') 
		and not bot:HasModifier('modifier_item_shadow_amulet_fade')
		and not bot:HasModifier('modifier_item_dustofappearance')
	then	
		local nEnemyList = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
		for _,enemy in pairs(nEnemyList)
		do
			if enemy:IsAlive()
				and ( enemy:GetAttackTarget() == bot or enemy:IsFacingLocation(bot:GetLocation(),16) )
			then
				local nNearbyEnemyTowers = bot:GetNearbyTowers(888,true);
				if #nNearbyEnemyTowers == 0 
					and lastAmuletTime < DotaTime() - 1.28
				then
					lastAmuletTime = DotaTime();
					hEffectTarget = bot
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'self'
				end
			end
		end
		
		if bot:IsStunned() 
			or bot:IsRooted() 
			or bot:IsNightmared()
		then
			local nNearbyEnemyTowers = bot:GetNearbyTowers(888,true);
			if #nNearbyEnemyTowers == 0 
				and lastAmuletTime < DotaTime() - 1.28
			then
				lastAmuletTime = DotaTime();
				hEffectTarget = bot
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
			end
		end
	end
	
	local nNearAllyList = bot:GetNearbyHeroes(849,false,BOT_MODE_NONE);
	for _,npcAlly in pairs(nNearAllyList) 
	do
		if J.IsValid(npcAlly)
		   and npcAlly ~= bot
		   and not npcAlly:IsIllusion()
		   and not npcAlly:IsMagicImmune()
		   and not npcAlly:IsInvisible()
		   and not npcAlly:HasModifier('modifier_invisible')
		   and not npcAlly:HasModifier('modifier_item_glimmer_cape') 
		   and not npcAlly:HasModifier('modifier_item_shadow_amulet_fade')
		   and not npcAlly:HasModifier('modifier_item_dustofappearance')
		   and ( npcAlly:IsStunned() or npcAlly:IsRooted() or npcAlly:IsNightmared() )
		then
			local nNearbyAllyEnemyTowers = npcAlly:GetNearbyTowers(888,true);
			if #nNearbyAllyEnemyTowers == 0
			then					
				hEffectTarget = npcAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly'
			end
		end
	end
		
	return BOT_ACTION_DESIRE_NONE
	
end

--羊刀
X.ConsiderItemDesire["item_sheepstick"] = function(hItem)

	local nCastRange = 700 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	for _,npcEnemy in pairs( nInRangeEnmyList )
	do
		if J.IsValid(npcEnemy)
		   and J.CanCastOnNonMagicImmune(npcEnemy)
		   and X.IsWithoutSpellShield(npcEnemy)
		then
			if (npcEnemy:IsChanneling() or npcEnemy:IsCastingAbility())
			then
				hEffectTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'check:'..J.Chat.GetNormName(hEffectTarget)
			end
			
			if J.IsRetreating(bot)
			then
				if not J.IsDisabled(true,npcEnemy)
					and not npcEnemy:IsDisarmed()
				then
					hEffectTarget = npcEnemy
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat:'..J.Chat.GetNormName(hEffectTarget)
				end
			end			
		end	
	end	

	if J.IsGoingOnSomeone(bot)
	then		
		if	J.IsValidHero(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange)
			and not J.IsDisabled(true,botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)	
			and X.IsWithoutSpellShield(botTarget)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--希瓦
X.ConsiderItemDesire["item_shivas_guard"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange +50,true,BOT_MODE_NONE)
	

	local hNearbyCreepList = bot:GetNearbyCreeps(nCastRange,true);
	if #hNearbyCreepList >= 6 
	   or #nInRangeEnmyList >= 1
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'used'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--大隐刀
X.ConsiderItemDesire["item_silver_edge"] = function(hItem)

	local nCastRange = 1600
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	--破被动	
	if J.IsGoingOnSomeone(bot)
		and not bot:HasModifier('modifier_item_dustofappearance')
		and #hNearbyEnemyTowerList == 0
	then
		if J.IsValidHero(botTarget)
			and J.IsInRange(bot,botTarget,2400)
			and J.CanCastOnMagicImmune(botTarget)
		then
			local nearTargetTower = botTarget:GetNearbyTowers(888,false)
			if #nearTargetTower == 0
			then
				hEffectTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'broken:'..J.Chat.GetNormName(botTarget)
			end
		end
	end
	
	return X.ConsiderItemDesire["item_invis_sword"](hItem)
	
end

--大勋章
X.ConsiderItemDesire["item_solar_crest"] = function(hItem)

	return X.ConsiderItemDesire["item_medallion_of_courage"](hItem)
	
end

--林肯
X.ConsiderItemDesire["item_sphere"] = function(hItem)

	local nCastRange = 700 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	local nNearAllyList = bot:GetNearbyHeroes(nCastRange,false,BOT_MODE_NONE)
	
		
	--use at ally who be targeted
	for _,npcAlly in pairs(nNearAllyList)
	do 
		if  J.IsValidHero(npcAlly)
			and npcAlly ~= bot
			and not npcAlly:IsMagicImmune()
			and not npcAlly:IsInvulnerable()
			and not npcAlly:IsIllusion()
			and not npcAlly:HasModifier("modifier_item_sphere_target")
			and not npcAlly:HasModifier('modifier_antimage_spell_shield') 
			and ( J.IsUnitTargetProjectileIncoming(npcAlly, 800)
				  or J.IsWillBeCastUnitTargetSpell(npcAlly,1200)
				  or bot:GetHealth() < 150 )
		then
			hEffectTarget = npcAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'npcAlly'
		end
	end


	if J.IsValidHero(botTarget) 
		and J.IsInRange(bot,botTarget,2400)
		and not J.IsInRange(bot,botTarget,800)
	then			
		if #nNearAllyList >= 2
		then
			local targetAlly = nil
			local targetDistance = 9999
			for _,npcAlly in pairs(nNearAllyList)
			do 
				if  npcAlly ~= bot
					and not npcAlly:IsIllusion()
					and J.IsInRange(npcAlly,botTarget,targetDistance)
					and not npcAlly:HasModifier("modifier_item_sphere_target")
					and not npcAlly:HasModifier('modifier_antimage_spell_shield') 
				then
					targetAlly = npcAlly;
					targetDistance = GetUnitToUnitDistance(botTarget,npcAlly);
					if J.IsHumanPlayer(npcAlly) then break end
				end
			end
			if targetAlly ~= nil
			then
				hEffectTarget = targetAlly
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'defence'
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--大骨灰
X.ConsiderItemDesire["item_spirit_vessel"] = function(hItem)

	return X.ConsiderItemDesire["item_urn_of_shadows"](hItem)
	
end

--吃树
X.ConsiderItemDesire["item_tango"] = function(hItem)

	local nCastRange = 300 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	
	
	--share tango
	local tCharge = hItem:GetCurrentCharges()
	if	DotaTime() > -88 and DotaTime() < 0 and bot:DistanceFromFountain() < 400 
		and J.Role.CanBeSupport(bot:GetUnitName())
		and bot:GetAssignedLane() ~= LANE_MID 
		and tCharge >= 3 and DotaTime() > lastGiveTangoTime + 2.0 
	then
		local target = X.GiveToMidLaner()
		if target ~= nil 
		then
			lastGiveTangoTime = DotaTime();
			hEffectTarget = target
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'share_to_mid'
		end
	elseif	bot:GetLevel() <= 12
			and (#hNearbyEnemyHeroList == 0 or nMode == BOT_MODE_LANING)
			and tCharge >= 1 
			and DotaTime() > 10
			and DotaTime() > lastGiveTangoTime + 2.0 
		then
			local hAllyList = bot:GetNearbyHeroes(800, false, BOT_MODE_NONE)
			for _,npcAlly in pairs(hAllyList)
			do
				if npcAlly ~= bot
				then
					local tangoSlot = npcAlly:FindItemSlot('item_tango');
					if tangoSlot == -1 
					   and not npcAlly:IsIllusion() 
					   and not npcAlly:HasModifier("modifier_tango_heal")
					   and not npcAlly:HasModifier("modifier_arc_warden_tempest_double")
					   and npcAlly:GetUnitName() ~= "npc_dota_hero_meepo"
					   and J.Item.GetItemCount(npcAlly, "item_tango_single") == 0 
					   and J.Item.GetEmptyInventoryAmount(npcAlly) >= 4
					then
						lastGiveTangoTime = DotaTime();
						hEffectTarget = npcAlly
						return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'share_to_ally'
					end
				end
			end
	end

	local hTangoSingle = J.IsItemAvailable('item_tango_single')
	if hTangoSingle ~= nil and hTangoSingle:IsFullyCastable() then return 0 end
		
	return X.ConsiderItemDesire["item_tango_single"](hItem)
	
end

X.ConsiderItemDesire["item_tango_single"] = function(hItem)

	if bot:DistanceFromFountain() < 3500 or bot:HasModifier("modifier_tango_heal") then return 0 end

	local nCastRange = 300 + aetherRange
	local sCastType = 'tree'	
	local hEffectTarget = nil 
	local nUseTangoLostHealth = ( hItem:GetName() == 'item_tango' ) and 200 or 160
	

	if J.IsWithoutTarget(bot)
		and not bot:HasModifier("modifier_filler_heal")
		and not bot:HasModifier("modifier_flask_healing")
	then
		local trees = bot:GetNearbyTrees(800)
		local targetTree = trees[1]
		local nearEnemyList = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE)
		local nearestEnemy = nearEnemyList[1]
		local nearTowerList = bot:GetNearbyTowers(1600,true)
		local nearestTower = nearTowerList[1]
		
		if targetTree ~= nil 
		then
			local targetTreeLoc = GetTreeLocation(targetTree)
			if bot:GetMaxHealth() - bot:GetHealth() > nUseTangoLostHealth
			   and IsLocationVisible(targetTreeLoc)
			   and IsLocationPassable(targetTreeLoc)
			   and ( #nearEnemyList == 0 or not J.IsInRange(bot,nearestEnemy,800) )
			   and ( #nearEnemyList == 0 or GetUnitToLocationDistance(bot,targetTreeLoc) * 1.6 < GetUnitToUnitDistance(bot,nearestEnemy) )
			   and ( #nearTowerList == 0 or GetUnitToLocationDistance(nearestTower,targetTreeLoc) > 920 )   
			then
				hEffectTarget = targetTree
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '800dist'
			end
		end
		
		local nearbyTrees = bot:GetNearbyTrees(240);
		if nearbyTrees[1] ~= nil
			and IsLocationVisible(GetTreeLocation(nearbyTrees[1])) 
			and IsLocationPassable(GetTreeLocation(nearbyTrees[1])) 
		then
			if bot:GetMaxHealth() - bot:GetHealth() > nUseTangoLostHealth
			then
				hEffectTarget = nearbyTrees[1]
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, '240Dist'
			end
			
			if bot:GetMaxHealth() - bot:GetHealth() > nUseTangoLostHealth *0.38
			   and bot:WasRecentlyDamagedByAnyHero(2.0)
			   and ( bot:GetActiveMode() == BOT_MODE_ATTACK 
					 or ( bot:GetActiveMode() == BOT_MODE_RETREAT 
						  and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH ) )
			then
				hEffectTarget = nearbyTrees[1]
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'modeUse'
			end
		end
	end
	
	if  DotaTime() > 4*60 +30 and botTarget == nil
		and hItem:GetName() == 'item_tango_single'
		and bot:DistanceFromFountain() > 3000 
	then
		local tCount = J.Item.GetItemCount(bot, "item_tango_single")
		if DotaTime() > 4*60 +30
		   and nMode ~= BOT_MODE_RUNE
		   and tCount >= 2
		then
			local hNearbyEnemyHeroList = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local trees = bot:GetNearbyTrees(1000);
			if trees[1] ~= nil  and ( IsLocationVisible(GetTreeLocation(trees[1])) and IsLocationPassable(GetTreeLocation(trees[1])) )
			   and #hNearbyEnemyHeroList == 0 
			then
				hEffectTarget = trees[1]
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'single_4:30'
			end
		end
	
		if DotaTime() > 7*60 +30 
			and nMode ~= BOT_MODE_RUNE
		then
			local hNearbyEnemyHeroList = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
			local trees = bot:GetNearbyTrees(1000);
			if trees[1] ~= nil 
			   and ( IsLocationVisible(GetTreeLocation(trees[1])) and IsLocationPassable(GetTreeLocation(trees[1])) )
			   and #hNearbyEnemyHeroList == 0 
			   and bot:GetMaxHealth() - bot:GetHealth() > 80
			then
				hEffectTarget = trees[1]
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'single_7:30'
			end
		end
	
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

--经验书
X.ConsiderItemDesire["item_tome_of_knowledge"] = function(hItem)

	local nCastRange = 300 
	local sCastType = 'none'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	if hItem:IsFullyCastable()
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'knowledge'
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end



local myTeam = GetTeam()
local opTeam = GetOpposingTeam()

local teamT1Top = nil; 
if GetTower(myTeam,TOWER_TOP_1) ~= nil then teamT1Top = GetTower(myTeam,TOWER_TOP_1):GetLocation(); end

local teamT1Mid = nil;
if GetTower(myTeam,TOWER_MID_1) ~= nil then teamT1Mid = GetTower(myTeam,TOWER_MID_1):GetLocation(); end

local teamT1Bot = nil;
if GetTower(myTeam,TOWER_BOT_1) ~= nil then teamT1Bot = GetTower(myTeam,TOWER_BOT_1):GetLocation(); end

function X.GetLaningTPLocation(nLane)
	if nLane == LANE_TOP then
		return teamT1Top
	elseif nLane == LANE_MID then
		return teamT1Mid
	elseif nLane == LANE_BOT then
		return teamT1Bot			
	end	
	return teamT1Mid
end	

function X.GetDefendTPLocation(nLane)
	return GetLaneFrontLocation(myTeam,nLane,-600)
end

function X.GetPushTPLocation(nLane)
	
	local laneFront = GetLaneFrontLocation(myTeam,nLane,0);
	local bestTpLoc = J.GetNearbyLocationToTp(laneFront);
	if J.GetLocationToLocationDistance(laneFront,bestTpLoc) < 2000
	then
		return bestTpLoc;
	end
	
	return nil;
end


function X.CanJuke()
	
	local allyTowers = bot:GetNearbyTowers(350,false); 
	if allyTowers[1] ~= nil	and allyTowers[1]:DistanceFromFountain() > bot:DistanceFromFountain() + 100		     
	then return true end
	
	local enemyPids = GetTeamPlayers(GetOpposingTeam())
	
	local heroHG = GetHeightLevel(bot:GetLocation())
	for i = 1, #enemyPids 
	do
		local info = GetHeroLastSeenInfo(enemyPids[i])
		if info ~= nil then
			local dInfo = info[1]; 
			if dInfo ~= nil 
				and dInfo.time_since_seen < 2.0  
			then
				if GetUnitToLocationDistance(bot,dInfo.location) < 1300 
					and GetHeightLevel(dInfo.location) < heroHG  
				then
					return false;
				end
				
				if GetUnitToLocationDistance(bot,dInfo.location) < 600 
				then
					local hNearbyEnemyHeroList = bot:GetNearbyHeroes(600,true,BOT_MODE_NONE);
					if #hNearbyEnemyHeroList == 0
					then
						return false;
					end
				end
			end
		end	
	end
	
	local totalDamage = 0;
	local nEnemies = bot:GetNearbyHeroes(1300,true,BOT_MODE_NONE);
	for _,enemy in pairs(nEnemies)
	do
		local enemyPhysicalDamage = enemy:GetEstimatedDamageToTarget( false, bot, 3.5, DAMAGE_TYPE_PHYSICAL );
		local enemyMagicalDamage = enemy:GetEstimatedDamageToTarget( false, bot, 3.5, DAMAGE_TYPE_MAGICAL );
		totalDamage = totalDamage + bot:GetActualIncomingDamage(enemyPhysicalDamage,DAMAGE_TYPE_PHYSICAL) + bot:GetActualIncomingDamage(enemyMagicalDamage,DAMAGE_TYPE_MAGICAL);
		if bot:GetHealth() <= totalDamage
		then
			return false;
		end		
	end
	
	return true;
end	

function X.GetNumHeroWithinRange(nRange)
	
	local enemyPids = GetTeamPlayers(GetOpposingTeam())
	
	local cHeroes = 0;
	for i = 1, #enemyPids do
		local info = GetHeroLastSeenInfo(enemyPids[i])
		if info ~= nil then
			local dInfo = info[1]; 
			if dInfo ~= nil and dInfo.time_since_seen < 2.0  
				and GetUnitToLocationDistance(bot,dInfo.location) < nRange 
			then
				cHeroes = cHeroes + 1;
			end
		end	
	end
	
	return cHeroes;
end	


function X.IsFarmingAlways(bot)
	
	local nTarget = bot:GetAttackTarget();	
	if J.IsValid(nTarget)
	   and nTarget:GetTeam() == TEAM_NEUTRAL
	   and not J.IsRoshan(nTarget)
	   and not J.IsKeyWordUnit("warlock",nTarget)
	   and X.GetNumEnemyNearby(GetAncient(GetTeam())) >= 2
	then
		return true;
	end
	
	local nNearAllyList = bot:GetNearbyHeroes(800,false,BOT_MODE_NONE);
	if J.IsValid(nTarget)
		and nTarget:IsAncientCreep()
		and not J.IsRoshan(nTarget)
		and not J.IsKeyWordUnit("warlock",nTarget)
		and bot:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT
		and bot:GetUnitName() ~= 'npc_dota_hero_ogre_magi'
		and #nNearAllyList < 2
	then
		return true;
	end
	
	if X.GetNumEnemyNearby(GetAncient(GetTeam())) >= 4
		and bot:DistanceFromFountain() >= 4800
		and #nNearAllyList < 2
	then
		return true;
	end
	
	return false;
end

--TP
X.ConsiderItemDesire["item_tpscroll"] = function(hItem)

	if  nMode == BOT_MODE_RUNE
		or ( bot:HasModifier("modifier_kunkka_x_marks_the_spot") )
		or ( bot:HasModifier("modifier_sniper_assassinate") )
		or ( bot:HasModifier("modifier_viper_nethertoxin") )
		or ( bot:HasModifier("modifier_oracle_false_promise_timer")
			 and J.GetModifierTime(bot,"modifier_oracle_false_promise_timer") <= 3.2 )
		or ( bot:HasModifier("modifier_jakiro_macropyre_burn")
			 and J.GetModifierTime(bot,"modifier_jakiro_macropyre_burn") >= 1.4 )
		or ( bot:HasModifier("modifier_arc_warden_tempest_double")
			 and bot:GetRemainingLifespan() < 3.2 )
	then return BOT_ACTION_DESIRE_NONE end	

	if bot:GetHealth() < 240
	then
		local nProDamage = J.GetAttackProjectileDamageByRange(bot, 1600);
		if bot:GetHealth() < bot:GetActualIncomingDamage(nProDamage,DAMAGE_TYPE_PHYSICAL)
		then return BOT_ACTION_DESIRE_NONE end
	end
	
	local nNearbyEnemyTowers = bot:GetNearbyTowers(888,true);
	if #nNearbyEnemyTowers > 0 then return BOT_ACTION_DESIRE_NONE end

	local tpLoc = nil
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	
	
	local nMinTPDistance = 4000
	local nMode = bot:GetActiveMode()
	local nModeDesire = bot:GetActiveModeDesire()
	local botLocation = bot:GetLocation()
	local botHP = J.GetHPR(bot)
	local botMP = J.GetMPR(bot)
	local nEnemyCount = X.GetNumHeroWithinRange(1600)
	local nAllyCount = J.GetAllyCount(bot,1600)
	local itemFlask = J.IsItemAvailable("item_flask")
	
	if bot:GetLevel() > 12 and bot:DistanceFromFountain() < 600 then nMinTPDistance = nMinTPDistance + 1000 end
	
	
	--对线
	if nMode == BOT_MODE_LANING 
		and nEnemyCount == 0
	then
		local assignedLane = bot:GetAssignedLane();
		local botAmount = GetAmountAlongLane(assignedLane, botLocation)
		local laneFront = GetLaneFrontAmount(myTeam, assignedLane, false)
		if botAmount.distance > nMinTPDistance - 200 
			or botAmount.amount < laneFront / 5 
		then 
			tpLoc = X.GetLaningTPLocation(assignedLane)
		end	

		if tpLoc ~= nil
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Laning'
		end
	end
	
	
	--守塔
	if J.IsDefending(bot)
		and nModeDesire >= BOT_MODE_DESIRE_MODERATE 
		and nEnemyCount == 0
	then
		local nDefendLane,sLane = LANE_MID,'tower_mid'		
		if nMode == BOT_MODE_DEFEND_TOWER_TOP then nDefendLane,sLane = LANE_TOP,'tower_top' end
		if nMode == BOT_MODE_DEFEND_TOWER_BOT then nDefendLane,sLane = LANE_BOT,'tower_bot' end		
		
		local botAmount = GetAmountAlongLane(nDefendLane, botLocation)
		local laneFront = GetLaneFrontAmount(myTeam, nDefendLane, false)
		if botAmount.distance > nMinTPDistance 
		   or botAmount.amount < laneFront / 5 
		then 
			tpLoc = X.GetDefendTPLocation(nDefendLane)
		end	
		
		if tpLoc ~= nil
			and GetUnitToLocationDistance(bot,tpLoc) > nMinTPDistance - 300
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Defend:'..sLane
		end	
	end
	
	
	--推塔
	if J.IsPushing(bot)
		and nModeDesire >= BOT_MODE_DESIRE_MODERATE 
		and nEnemyCount == 0
	then
		local nPushLane,sLane = LANE_MID,'tower_mid'		
		if nMode == BOT_MODE_PUSH_TOWER_TOP then nPushLane,sLane = LANE_TOP,'tower_top' end
		if nMode == BOT_MODE_PUSH_TOWER_BOT then nPushLane,sLane = LANE_BOT,'tower_bot' end		
		
		local botAmount = GetAmountAlongLane(nPushLane, botLocation)
		local laneFront = GetLaneFrontAmount(myTeam, nPushLane, false)
		if botAmount.distance > nMinTPDistance 
		   or botAmount.amount < laneFront / 5 
		then 
			tpLoc = X.GetPushTPLocation(nPushLane)
		end	
		
		if tpLoc ~= nil
			and GetUnitToLocationDistance(bot,tpLoc) > nMinTPDistance - 600
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Push:'..sLane
		end	
	end
	
	
	--保人 可进阶为塔下保人
	if nMode == BOT_MODE_DEFEND_ALLY 
		and nModeDesire >= BOT_MODE_DESIRE_MODERATE 
		and J.Role.CanBeSupport(bot:GetUnitName()) 
		and nEnemyCount == 0 
	then
		local target = bot:GetTarget()
		if target ~= nil 
			and target:IsHero() 
			and GetUnitToUnitDistance(bot,target) > nMinTPDistance 
		then
			local bestTpLoc = J.GetNearbyLocationToTp(target:GetLocation());
			if bestTpLoc ~= nil 
			   and GetUnitToLocationDistance(bot,bestTpLoc) > nMinTPDistance - 800 
			then
				tpLoc = bestTpLoc;
			end		
		end
		
		if tpLoc ~= nil
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'DEFEND_ALLY:'..J.Chat.GetNormName(target)
		end	
	end
	
	
	--撤退
	if nMode == BOT_MODE_RETREAT 
	   and nModeDesire >= BOT_MODE_DESIRE_MODERATE 
	   and bot:GetLevel() >= 3
	then  
	
		--第一种情况:无敌人无大药回家恢复
		if botHP < 0.18
		   and ( bot:WasRecentlyDamagedByAnyHero(8.0) or botHP < 0.1 )
		   and bot:GetUnitName() ~= 'npc_dota_hero_huskar'
		   and nEnemyCount == 0 
		   and itemFlask == nil
		   and not bot:HasModifier("modifier_flask_healing")
		   and not bot:HasModifier("modifier_filler_heal")
		   and bot:DistanceFromFountain() > nMinTPDistance
		then
			tpLoc = J.GetTeamFountain();
			return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'Retreat:1'
		end
		
		
		--第二种情况:有多个敌人但可以卡视野TP
		local nAttackAllyList = bot:GetNearbyHeroes(999,false,BOT_MODE_ATTACK)
		if botHP < ( 0.16 + 0.24 * nEnemyCount)
			and #nAttackAllyList == 0
			and bot:WasRecentlyDamagedByAnyHero(6.0)
			and X.CanJuke() 
			and nEnemyCount <= ( botHP < 0.4 and 2 or 3 )
			and itemFlask == nil
			and not bot:HasModifier("modifier_flask_healing")
			and not bot:HasModifier("modifier_item_urn_heal")
			and not bot:HasModifier("modifier_item_spirit_vessel_heal")
			and bot:DistanceFromFountain() > nMinTPDistance
		then
			tpLoc = J.GetTeamFountain();
			return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'Retreat:2'
		end
			   
			   
		--第三种情况:只有一个敌人直接T回家
		if ( botHP < 0.34 or botHP + botMP < 0.43 )
			and #nAttackAllyList == 0
			and bot:GetLevel() >= 9
			and X.CanJuke()
			and nEnemyCount <= 1 and nAllyCount <= 2
			and itemFlask == nil
			and bot:GetAttackTarget() == nil
			and bot:GetUnitName() ~= 'npc_dota_hero_huskar'
			and not bot:HasModifier("modifier_flask_healing")
			and not bot:HasModifier("modifier_clarity_potion")
			and not bot:HasModifier("modifier_filler_heal")
			and not bot:HasModifier("modifier_item_urn_heal")
			and not bot:HasModifier("modifier_item_spirit_vessel_heal")
			and not bot:HasModifier("modifier_bottle_regeneration")
			and not bot:HasModifier("modifier_tango_heal")
			and bot:DistanceFromFountain() > nMinTPDistance
		then
			tpLoc = J.GetTeamFountain();
			return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'Retreat:3'
		end	
	end
	
	
	--TP出去发育
	if nMode == BOT_MODE_FARM 
	   and bot:DistanceFromFountain() < 800 
	   and botHP > 0.9
	   and botMP > 0.8
	then
		local mostFarmDesireLane,mostFarmDesire = J.GetMostFarmLaneDesire();

		if mostFarmDesire > BOT_MODE_DESIRE_HIGH			
		then
			farmTpLoc = GetLaneFrontLocation(GetTeam(),mostFarmDesireLane,0);
			local bestTpLoc = J.GetNearbyLocationToTp(farmTpLoc);
			if bestTpLoc ~= nil and farmTpLoc ~= nil
			   and J.IsLocHaveTower(2000,false,farmTpLoc)
			   and GetUnitToLocationDistance(bot,bestTpLoc) > nMinTPDistance 
			then
				tpLoc = farmTpLoc;
			end
		end	
		
		if tpLoc == nil 
		then
			local shrineList = {
				 SHRINE_JUNGLE_1,
				 SHRINE_JUNGLE_2 
			}
			for _,s in pairs(shrineList) do
				local shrine = GetShrine(GetTeam(), s);
				if shrine ~= nil and shrine:IsAlive() 
					and not shrine:WasRecentlyDamagedByAnyHero(4.0)
				then
					tpLoc = shrine:GetLocation();
					break; 
				end	
			end	
		end		
		
		if tpLoc ~= nil
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'FARM_FOUNTAIN'
		end	
		
	end
	
	
	--TP发育带线
	if bot:GetLevel() >= 10 
	   and nMode ~= BOT_MODE_ROSHAN
	   and J.GetAllyCount(bot,1600) <= 2
	   and J.Role.ShouldTpToFarm() 
	   and not J.Role.IsAllyHaveAegis()
	   and not J.Role.CanBeSupport(bot:GetUnitName())
	   and not J.IsEnemyHeroAroundLocation(GetAncient(GetTeam()):GetLocation(), 3300)
	then
		local nAttackAllyList = bot:GetNearbyHeroes(1600,false,BOT_MODE_ATTACK);
		local nNearEnemyList = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE);
		local nCreeps= bot:GetNearbyCreeps(1600,true);
		local mostFarmDesireLane,mostFarmDesire = J.GetMostFarmLaneDesire();

		if mostFarmDesire > 0.8
			and #nNearEnemyList == 0
			and #nCreeps == 0
			and #nAttackAllyList == 0				
		then
			
			if hItem:GetName() ~= "item_tpscroll"
			then
				tpLoc = GetLaneFrontLocation(GetTeam(),mostFarmDesireLane,-600);
				local nNearAllyList = J.GetAlliesNearLoc(tpLoc, 1600);
				if GetUnitToLocationDistance(bot,tpLoc) > nMinTPDistance - 600
					and #nNearAllyList == 0
				then					
					J.Role['lastFarmTpTime'] = DotaTime();
					return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'TBOOT-Farm_Lane'
				end
			end
					
			tpLoc = GetLaneFrontLocation(GetTeam(),mostFarmDesireLane,0);
			local bestTpLoc = J.GetNearbyLocationToTp(tpLoc);
			local nNearAllyList = J.GetAlliesNearLoc(tpLoc, 1600);
			if bestTpLoc ~= nil 
			   and J.IsLocHaveTower(1850,false,tpLoc)
			   and GetUnitToLocationDistance(bot,bestTpLoc) > nMinTPDistance
			   and #nNearAllyList == 0
			then
				J.Role['lastFarmTpTime'] = DotaTime();
				return BOT_ACTION_DESIRE_HIGH, bestTpLoc, sCastType, 'Farm_Lane'
			end
		end	
	end
	
	--支援团战和守家
	if	bot:GetLevel() > 10
		and nMode ~= BOT_MODE_SECRET_SHOP
		and nMode ~= BOT_MODE_ROSHAN
		and nMode ~= BOT_MODE_ATTACK
		and ( botTarget == nil or not botTarget:IsHero() )
		and J.GetAllyCount(bot,1600) <= 3 --守护遗迹bug
	then
		local nNearEnemyList = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE);
		local nTeamFightLocation = J.GetTeamFightLocation(bot);
		if #nNearEnemyList == 0 and nTeamFightLocation ~= nil
		   and GetUnitToLocationDistance(bot,nTeamFightLocation) > nMinTPDistance - 600
		then
		
			if hItem:GetName() ~= "item_tpscroll"
			then
				return BOT_ACTION_DESIRE_HIGH,nTeamFightLocation, sCastType, 'TBOOT-TeamFight:'..GetUnitToLocationDistance(bot,nTeamFightLocation)
			end
		
			local bestTpLoc = J.GetNearbyLocationToTp(nTeamFightLocation);
			if bestTpLoc ~= nil
			   and J.GetLocationToLocationDistance(bestTpLoc,nTeamFightLocation) < 1800
			   and GetUnitToLocationDistance(bot,bestTpLoc) > nMinTPDistance - 1200
			then
				return BOT_ACTION_DESIRE_HIGH,bestTpLoc, sCastType, 'TeamFight:'..GetUnitToLocationDistance(bot,nTeamFightLocation)
			end
		end
		
		--守护遗迹
		if bot:GetLevel() >= 22	and #nNearEnemyList == 0 
		   and J.Role.ShouldTpToFarm() 
		   and bot:DistanceFromFountain() > 2000
		   and GetUnitToUnitDistance(bot,nAncient) > nMinTPDistance - 200
		   and J.GetAroundTargetAllyHeroCount(nAncient, 1600, bot) == 0
		then
			local nEnemyLaneFront = J.GetNearestLaneFrontLocation(nAncient:GetLocation(),true,400);
			if nEnemyLaneFront ~= nil
			   and GetUnitToLocationDistance(nAncient,nEnemyLaneFront) <= 1600
			then
				
				J.Role['lastFarmTpTime'] = DotaTime();			
				return BOT_ACTION_DESIRE_HIGH,nAncient:GetLocation(), sCastType, 'DefendAncient'
			end
		end
		
	end
		
	--回复状态
	if  (botHP + botMP < 0.3 or botHP < 0.2 ) 
		and bot:GetLevel() >= 6
		and bot:GetUnitName() ~= 'npc_dota_hero_huskar'
	then
		if	X.CanJuke()
			and bot:DistanceFromFountain() > nMinTPDistance + 600
			and nEnemyCount <= 1 and nAllyCount <= 1
			and J.GetProperTarget(bot) == nil
			and itemFlask == nil
			and bot:GetAttackTarget() == nil
			and not bot:HasModifier("modifier_flask_healing")
			and not bot:HasModifier("modifier_clarity_potion")
			and not bot:HasModifier("modifier_filler_heal")
			and not bot:HasModifier("modifier_item_urn_heal")
			and not bot:HasModifier("modifier_item_spirit_vessel_heal")
			and not bot:HasModifier("modifier_bottle_regeneration")
			and not bot:HasModifier("modifier_tango_heal")
		then
			tpLoc = J.GetTeamFountain();
		end
		
		if tpLoc ~= nil
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Recover'
		end
	end
	
	--血魔大
	if bot:HasModifier('modifier_bloodseeker_rupture') and nEnemyCount <= 1 
		and J.GetModifierTime(bot,"modifier_bloodseeker_rupture") >= 3.1
	then
		local nAllyCount = bot:GetNearbyHeroes(1000, false, BOT_MODE_NONE);
		if #nAllyCount <= 1 and X.CanJuke()
		then		
			tpLoc = J.GetTeamFountain();
		end
		
		if tpLoc ~= nil
		then
			hEffectTarget = tpLoc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'bloodseeker_rupture'
		end	
	end
	
	--处理特殊情况一
	if X.IsFarmingAlways(bot) 
	then
		tpLoc = GetAncient(GetTeam()):GetLocation();
		return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'StopFarm'
	end	
	
	--处理特殊情况二
	if J.IsStuck(bot) and nEnemyCount == 0 
	then
		tpLoc = GetAncient(GetTeam()):GetLocation();
		return BOT_ACTION_DESIRE_HIGH, tpLoc, sCastType, 'AvoidStuck'
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end

--飞鞋
X.ConsiderItemDesire["item_travel_boots"] = function(hItem)

	local nCastRange = 1600 
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	--TP小兵
	
	return X.ConsiderItemDesire["item_tpscroll"](hItem)
	
end

--大飞鞋
X.ConsiderItemDesire["item_travel_boots_2"] = function(hItem)

	local nCastRange = 1600 
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	--TP队友

	return X.ConsiderItemDesire["item_travel_boots"](hItem)
	
end

--骨灰
X.ConsiderItemDesire["item_urn_of_shadows"] = function(hItem)

	if hItem:GetCurrentCharges() == 0 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 980 + aetherRange
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then	
		if J.IsValidHero(botTarget) 
		   and J.CanCastOnNonMagicImmune(botTarget) 
		   and J.IsInRange(bot, botTarget, nCastRange)
		   and not botTarget:HasModifier("modifier_item_urn_damage") 
		   and not botTarget:HasModifier("modifier_item_spirit_vessel_damage")
		   and (botTarget:GetHealth()/botTarget:GetMaxHealth() < 0.95 or GetUnitToUnitDistance(bot, botTarget) <= 700)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'attack:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
	
	if hItem:GetCurrentCharges() >= 2 
		and	bot:GetActiveMode() ~= BOT_MODE_ROSHAN
	then
		local hAllyList = bot:GetNearbyHeroes(nCastRange,false,BOT_MODE_NONE);
		local hNeedHealAlly = nil
		local nNeedHealAllyHealth = 99999
		for _,npcAlly in pairs(hAllyList) 
		do
			if J.IsValid(npcAlly) 
			   and not npcAlly:IsIllusion()
			   and npcAlly:DistanceFromFountain() > 800
			   and J.CanCastOnNonMagicImmune(npcAlly) 
			   and not npcAlly:WasRecentlyDamagedByAnyHero(3.1)
			   and not npcAlly:HasModifier("modifier_item_spirit_vessel_heal")  
			   and not npcAlly:HasModifier("modifier_item_urn_heal")
			   and not npcAlly:HasModifier("modifier_fountain_aura")
			   and not npcAlly:HasModifier("modifier_arc_warden_tempest_double") 
			   and npcAlly:GetMaxHealth() - npcAlly:GetHealth() > 450 
			   and #hNearbyEnemyHeroList == 0 				   				   			
			then
				if(npcAlly:GetHealth() < nNeedHealAllyHealth )
				then
					hNeedHealAlly = npcAlly
					nNeedHealAllyHealth = npcAlly:GetHealth()
				end
			end
		end
	
		if(hNeedHealAlly ~= nil)
		then
			hEffectTarget = hNeedHealAlly
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal:'..J.Chat.GetNormName(hEffectTarget)
		end
	end
		
	return BOT_ACTION_DESIRE_NONE
	
end

--纷争
X.ConsiderItemDesire["item_veil_of_discord"] = function(hItem)

	local nCastRange = 1000 + aetherRange
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	local hEnemyList= bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);		
	if hEnemyList ~= nil and #hEnemyList > 0 
	then
		local nAOELocation = bot:FindAoELocation(true, true, bot:GetLocation(), nCastRange, 500 , 0, 0);
		if nAOELocation.count >= 2
		   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= nCastRange
		then
			hEffectTarget = nAOELocation.targetloc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Aoe_more'
		end
	end
	
	hEnemyList = bot:GetNearbyHeroes(1000,true,BOT_MODE_NONE);		
	if hEnemyList ~= nil and #hEnemyList > 0 
	then
		local nAOELocation = bot:FindAoELocation(true, true, bot:GetLocation(), 800, 400 , 0, 0);
		if nAOELocation.count >= 1  
		   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= 1000
		then
			hEffectTarget = nAOELocation.targetloc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Aoe_near'
		end
	end
	
	local LaneCreeps=bot:GetNearbyLaneCreeps(1500,true);		
	if LaneCreeps ~= nil and #LaneCreeps >= 6 then
		local nAOELocation = bot:FindAoELocation(true, false, bot:GetLocation(), nCastRange, 400 , 0, 0);
		if nAOELocation.count >= 8
		   and GetUnitToLocationDistance(bot,nAOELocation.targetloc) <= nCastRange
		then
			hEffectTarget = nAOELocation.targetloc
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Aoe_creep'
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end


--芒果树
local mangoTreeTime = -1
X.ConsiderItemDesire["item_mango_tree"] = function(hItem)

	local oppositeID_1 = GetTeamPlayers(opTeam)[1]
	
	if bot:DistanceFromFountain() > 2222 and not IsPlayerBot(oppositeID_1) then return BOT_ACTION_DESIRE_NONE end
	
	local nCastRange = 200
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	

	local nLocation = bot:GetLocation() + RandomVector(100)
	if IsLocationPassable(nLocation)
	then
		if mangoTreeTime == -1 
		then 
			mangoTreeTime = DotaTime() 
		elseif DotaTime() > mangoTreeTime + 3.0
		then
			hEffectTarget = nLocation
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'MangTree'
		end
	end	
	
	return BOT_ACTION_DESIRE_NONE
	
end


--GG树
local lastKACount = -1
X.ConsiderItemDesire["item_ironwood_tree"] = function(hItem)

	local nCastRange = 600
	local sCastType = 'ground'	
	local hEffectTarget = nil 
	
	if lastKACount == -1 then lastKACount = GetHeroKills(bot:GetPlayerID()) + GetHeroAssists(bot:GetPlayerID()) end
	
	if lastKACount < GetHeroKills(bot:GetPlayerID()) + GetHeroAssists(bot:GetPlayerID())
	then
		lastKACount = -1
		hEffectTarget = J.GetFaceTowardDistanceLocation(bot,nCastRange)
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'GGTree'
	end

	return BOT_ACTION_DESIRE_NONE
	
end

--寒铁钢爪
X.ConsiderItemDesire["item_iron_talon"] = function(hItem)

	local nCastRange = 600
	local sCastType = 'unit'	
	local hEffectTarget = nil 	
	
	
	if J.IsValid(botTarget)
		and not botTarget:IsHero()
		and not botTarget:IsBuilding()
		and not botTarget:IsAncientCreep()
		and J.IsInRange(bot,botTarget,nCastRange)
		and not botTarget:HasModifier("modifier_fountain_glyph")
		and botTarget:GetHealth() * 0.4 > bot:GetAttackDamage()
	then
		hEffectTarget = botTarget
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'farm'
	end
	
	return X.ConsiderItemDesire["item_quelling_blade"](hItem)

end


--奥术指环
X.ConsiderItemDesire["item_arcane_ring"] = function(hItem)

	return X.ConsiderItemDesire["item_arcane_boots"](hItem)

end

--蜂王浆
local royalJellyTime = nil
X.ConsiderItemDesire["item_royal_jelly"] = function(hItem)

	local nCastRange = 800 
	local sCastType = 'unit'	
	local hEffectTarget = nil 
	local hAllyList = J.GetAlliesNearLoc(bot:GetLocation(),800)

	for _,npcAlly in pairs(hAllyList)
	do 
		if J.IsValidHero(npcAlly)
			and not npcAlly:HasModifier("modifier_royal_jelly")
		then
			if royalJellyTime == nil
			then
				royalJellyTime = DotaTime()
			elseif royalJellyTime < DotaTime() - 2.0
				then
					royalJellyTime = nil
					hEffectTarget = npcAlly
					return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Ally'
			end
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE

end

--可靠铁铲
X.ConsiderItemDesire["item_trusty_shovel"] = function(hItem)

	if GetTeamMember(1):IsBot() then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 800 
	local sCastType = 'ground'
	local hEffectTarget = nil 
	

	if #hNearbyEnemyHeroList == 0
	then
		hEffectTarget = bot:GetLocation()
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'dig'
	end
		
	return BOT_ACTION_DESIRE_NONE

end

--笨拙渔网
X.ConsiderItemDesire["item_clumsy_net"] = function(hItem)

	local nCastRange = 900 + aetherRange 
	local sCastType = 'unit'	
	local hEffectTarget = nil
		
	
	if J.IsGoingOnSomeone(bot)
	then			
		if  J.IsValidHero(botTarget) 
			and not J.IsDisabled(true,botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and J.CanCastOnTargetAdvanced(botTarget)				
			and J.IsInRange(botTarget, bot, nCastRange)
			and ( J.IsRunning(botTarget) or botTarget:HasModifier("modifier_teleporting") )
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

--精华指环
X.ConsiderItemDesire["item_essence_ring"] = function(hItem)

	if bot:DistanceFromFountain() < 1000 then return 0 end

	local nCastRange = 600
	local sCastType = 'none'
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE)
	
	if bot:GetMaxHealth() - bot:GetHealth() > 600
		and J.IsAllowedToSpam(bot, 200)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Heal'
	end

	return X.ConsiderItemDesire["item_faerie_fire"](hItem)

end

--维修器具
X.ConsiderItemDesire["item_repair_kit"] = function(hItem)

	local nCastRange = 600
	local sCastType = 'unit'
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE)
	

	local nTowerList = bot:GetNearbyTowers(990,false);
	
	if #nInRangeEnmyList >= 1
	then
		for _,nTower in pairs(nTowerList)
		do 
			if J.IsValidBuilding(nTower)
				and J.GetHPR(nTower) < 0.88
				and ( nTower:GetAttackTarget() ~= nil or J.GetHPR(nTower) < 0.18 )
				and not nTower:HasModifier('modifier_repair_kit')
			then			
				hEffectTarget = nTower
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'tower'
			end		
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

--高级仙灵之火
X.ConsiderItemDesire["item_greater_faerie_fire"] = function(hItem)

	local nCastRange = 600
	local sCastType = 'none'
	local hEffectTarget = nil 

	if J.IsGoingOnSomeone(bot) 
		and ( hItem:GetCurrentCharges() >= 2 or J.GetHPR(bot) < 0.5 )
		and bot:GetMaxHealth() - bot:GetHealth() > 500
	then
		if J.IsValidHero(botTarget)
			and J.IsInRange(bot,botTarget,1800)
			and J.CanCastOnMagicImmune(botTarget)
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'heal'
		end
	end
	
	
	return X.ConsiderItemDesire["item_faerie_fire"](hItem)

end


--网虫腿
X.ConsiderItemDesire["item_spider_legs"] = function(hItem)

	return X.ConsiderItemDesire["item_phase_boots"](hItem)

end


--闪灵
X.ConsiderItemDesire["item_flicker"] = function(hItem)

	if bot:DistanceFromFountain() < 600 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 600
	local sCastType = 'none'
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(800,true,BOT_MODE_NONE)
	
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and ( bot:IsSilenced() or bot:IsRooted() )
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'debuff'
		end
	end
	
	
	if J.IsRetreating(bot)
		and bot:WasRecentlyDamagedByAnyHero(3.0)
		and #nInRangeEnmyList >= 1
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
	end


	return BOT_ACTION_DESIRE_NONE

end

--忍者用具
X.ConsiderItemDesire["item_ninja_gear"] = function(hItem)

	local nCastRange = 1600
	local sCastType = 'none'
	local hEffectTarget = nil 
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnMagicImmune(botTarget)
			and not J.IsInRange(bot, botTarget, botTarget:GetCurrentVisionRange())
			and J.IsInRange(bot, botTarget, 2800)
		then
			local hEnemyCreepList = bot:GetNearbyLaneCreeps(800,true);
			if #hEnemyCreepList == 0 and #hNearbyEnemyHeroList == 0
			then
				hEffectTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack:'..J.Chat.GetNormName(hEffectTarget)
			end	
		end		
	end
	
	
	return BOT_ACTION_DESIRE_NONE

end

--幻术师披风
X.ConsiderItemDesire["item_illusionsts_cape"] = function(hItem)

	return X.ConsiderItemDesire["item_manta"](hItem)

end

--浩劫巨锤
X.ConsiderItemDesire["item_havoc_hammer"] = function(hItem)

	local nCastRange = 300
	local sCastType = 'none'
	local hEffectTarget = nil 
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	
	
	if J.IsRetreating(bot)
		and #nInRangeEnmyList >= 1
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'	
	end

	if J.IsGoingOnSomeone(bot)
	then
		local nCastTarget = nInRangeEnmyList[1]
		if J.IsValidHero(nCastTarget)
			and J.CanCastOnNonMagicImmune(nCastTarget)
			and ( nCastTarget ~= botTarget or GetUnitToUnitDistance(bot,nCastTarget) + 250 <= bot:GetAttackRange() )
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Atttack'	
		end
	end

	return BOT_ACTION_DESIRE_NONE

end

--灵犀角
X.ConsiderItemDesire["item_minotaur_horn"] = function(hItem)

	return X.ConsiderItemDesire["item_black_king_bar"](hItem)

end

--原力靴
X.ConsiderItemDesire["item_force_boots"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'none'
	local hEffectTarget = nil 
	local nEnemyCount = J.GetEnemyCount(bot,1600)
	

	if J.IsRetreating(bot) 
		and nEnemyCount >= 1
	then
		if bot:IsFacingLocation(GetAncient(GetTeam()):GetLocation(),30) 
		   and bot:DistanceFromFountain() > 600 
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'retreat'
		end	
	end 
	
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and GetUnitToUnitDistance(botTarget,bot) > bot:GetAttackRange() + 50
			and GetUnitToUnitDistance(botTarget,bot) < bot:GetAttackRange() + 850
			and bot:IsFacingLocation(botTarget:GetLocation(),20)
			and not botTarget:IsFacingLocation(bot:GetLocation(),100)
			and nEnemyCount <= 2
		then
			hEffectTarget = bot
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
		end	
	end

	return BOT_ACTION_DESIRE_NONE

end

--聚合神符
X.ConsiderItemDesire["item_fusion_rune"] = function(hItem)

	local nCastRange = 800
	local sCastType = 'unit'
	local hEffectTarget = nil 
	
	
	if J.IsInTeamFight(bot, 1400)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnMagicImmune(botTarget)
		then
			hEffectTarget = bot --可优化为对战力最高的队友使用
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'fusion_rune'
		end	
	end

	return BOT_ACTION_DESIRE_NONE

end

--林地神行靴
X.ConsiderItemDesire["item_woodland_striders"] = function(hItem)

	if bot:DistanceFromFountain() < 600 then return BOT_ACTION_DESIRE_NONE end

	local nCastRange = 800
	local sCastType = 'none'
	local hEffectTarget = nil 
	
	
	if J.IsRetreating(bot)
		and bot:WasRecentlyDamagedByAnyHero(4.0)
	then
		hEffectTarget = bot
		return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
	end
	
	return BOT_ACTION_DESIRE_NONE

end

--亡者之书
X.ConsiderItemDesire["item_demonicon"] = function(hItem)

	return X.ConsiderItemDesire["item_necronomicon"](hItem)

end

--堕天斧
X.ConsiderItemDesire["item_fallen_sky"] = function(hItem)

	local nCastRange = 1600
	local sCastType = 'ground'
	local nRadius = 315
	local nCastDelay = 0.5
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(1200,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		local nAoeLocation =  J.GetAoeEnemyHeroLocation(bot, nCastRange, nRadius, 2)
		if nAoeLocation ~= nil
		then
			hEffectTarget = nAoeLocation
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Aoe'
		end
		
		if J.IsValidHero(botTarget)
			and J.CanCastOnNonMagicImmune(botTarget)
			and J.IsInRange(bot,botTarget,nCastRange)
		then
			local nCastLocation = J.GetDelayCastLocation(bot, botTarget, nCastRange, nRadius, nCastDelay)
			if nCastLocation ~= nil
			then
				hEffectTarget = nCastLocation
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
			end
		end	
	end
	
	if J.IsRetreating(bot)
		and bot:WasRecentlyDamagedByAnyHero(3.0)
	then
		local bLocation = J.GetLocationTowardDistanceLocation(bot, GetAncient(GetTeam()):GetLocation(), 1600 );
		local nAttackAllyList = bot:GetNearbyHeroes(800,false,BOT_MODE_ATTACK);
		if bot:DistanceFromFountain() > 800 
		   and IsLocationPassable(bLocation) 
		   and ( #nAttackAllyList == 0 or bot:GetActiveModeDesire() > BOT_MODE_DESIRE_VERYHIGH *0.9 )
		   and #nInRangeEnmyList >= 1
		then
			hEffectTarget = bLocation
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Retreat'
		end	
	end

	return BOT_ACTION_DESIRE_NONE

end

--机械之心
X.ConsiderItemDesire["item_ex_machina"] = function(hItem)

	local nCastRange = 800 
	local sCastType = 'none'
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
		then
			local nSoltList = { 0, 1, 2, 3, 4, 5 }
			local nRemainTime = 0
			for _,nSlot in pairs(nSoltList)
			do
				local hItem = bot:GetItemInSlot(nSlot)
				if hItem ~= nil and hItem:GetName() ~= 'item_refresher'
				then
					local nCooldownTime = hItem:GetCooldownTimeRemaining()
					nRemainTime = nRemainTime + nCooldownTime
				end
			end
		
			if nRemainTime >= 20
			then
				hEffectTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack'
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE

end

--新物品
X.ConsiderItemDesire["item_new"] = function(hItem)

	local nCastRange = 300 + aetherRange
	local sCastType = 'unit'
	local hEffectTarget = nil
	local nInRangeEnmyList = bot:GetNearbyHeroes(nCastRange,true,BOT_MODE_NONE)
	

	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
		then
			hEffectTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, hEffectTarget, sCastType, 'Attack:'..J.Chat.GetNormName(botTarget)
		end
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

function X.IsTargetedByEnemy(building)
	local heroes = GetUnitList(UNIT_LIST_ENEMY_HEROES);
	for _,hero in pairs(heroes)
	do
		if ( GetUnitToUnitDistance(building, hero) <= hero:GetAttackRange() + 200 
			and hero:GetAttackTarget() == building ) 
		then
			return true;
		end
	end
	return false;
end

local function UseGlyph()

	if GetGlyphCooldown( ) > 0 
		or DotaTime() < 60 
		or bot:GetPlayerID() ~= GetTeamMember(1):GetPlayerID()
	then
		return 
	end	
	
	local T1 = {
		TOWER_TOP_1,
		TOWER_MID_1,
		TOWER_BOT_1,
		TOWER_TOP_3,
		TOWER_MID_3, 
		TOWER_BOT_3, 
		TOWER_BASE_1, 
		TOWER_BASE_2
	}
	
	for _,t in pairs(T1)
	do
		local tower = GetTower(GetTeam(), t);
		if  tower ~= nil and tower:GetHealth() > 0 
			and tower:GetHealth()/tower:GetMaxHealth() < 0.36
			and tower:GetAttackTarget() ~=  nil
		then
			bot:ActionImmediate_Glyph( )
			return
		end
	end
	

	local MeleeBarrack = {
		BARRACKS_TOP_MELEE,
		BARRACKS_MID_MELEE,
		BARRACKS_BOT_MELEE
	}
	
	for _,b in pairs(MeleeBarrack)
	do
		local barrack = GetBarracks(GetTeam(), b);
		if barrack ~= nil and barrack:GetHealth() > 0 
			and barrack:GetHealth()/barrack:GetMaxHealth() < 0.5 
			and X.IsTargetedByEnemy(barrack)
		then
			bot:ActionImmediate_Glyph( )
			return
		end
	end
	
	local Ancient = GetAncient(GetTeam())
	if Ancient ~= nil and Ancient:GetHealth() > 0 
		and Ancient:GetHealth()/Ancient:GetMaxHealth() < 0.5 
		and X.IsTargetedByEnemy(Ancient)
	then
		bot:ActionImmediate_Glyph( )
		return
	end
	
end

if not bDeafaultItemHero
then

function ItemUsageThink()

end

end

if not bDeafaultAbilityHero
then

function AbilityUsageThink()

end

end


function BuybackUsageThink()
	
	BotBuild.SkillsComplement();

	ItemUsageComplement();

	BuybackUsageComplement();
	
	UseGlyph();

end

function CourierUsageThink()
	
	CourierUsageComplement();

end

function AbilityLevelUpThink()

	--云锦囊模块
	if bot.cloudAbility == nil then
		local data = {
			operation = 'getcloudkits',
			bot = J.Chat.GetNormName(bot),
		}
		H.HttpPost(data, '39.106.150.173:3010',
		    function (res, par)
				local kits = dkjson.decode(res)
				par.cloudAbility = FGUtilStringSplit(kits.Ability, ',')
				par.cloudTalent = FGUtilStringSplit(kits.Talent, ',')
				par.cloudBuy = FGUtilStringSplit(kits.Buy, ',')
				par.cloudSell = FGUtilStringSplit(kits.Sell, ',')
				par.cloudAuxiliary = kits.uxiliary == 'true'
				print(kits.hero..'已加载云锦囊')
		    end
		, bot, true);
		bot.cloudAbility = false
	end
	--重写技能数据
	if type(bot.cloudAbility) == 'table' and DotaTime() < -50 then
		local sTalentList = J.Skill.GetTalentList(bot)
		local sAbilityList = J.Skill.GetAbilityList(bot)
		local nAbilityBuildList = bot.cloudAbility

		--格式化技能和天赋
		for i = 1, #nAbilityBuildList do
			nAbilityBuildList[i] = tonumber(nAbilityBuildList[i])
		end
		local nTalentBuildList = { 
			[1] = (bot.cloudTalent[1] == '右' and 1 or 2),
			[2] = (bot.cloudTalent[2] == '右' and 3 or 4),
			[3] = (bot.cloudTalent[3] == '右' and 5 or 6),
			[4] = (bot.cloudTalent[4] == '右' and 7 or 8),
		}

		--获取本地锦囊数据并进行技能树编码
		nAbilityBuildList, nTalentBuildList = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,{},{});
		local SkillList = J.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

		--设置云锦囊数据
		sAbilityLevelUpList = SkillList
		bot.cloudAbility = true
	end
	if bot.cloudAbility or DotaTime() > -65 then
		AbilityLevelUpComplement();
	end

end

function FGUtilStringSplit(str,split_char)
    -------------------------------------------------------
    -- 参数:待分割的字符串,分割字符
    -- 返回:子串表.(含有空串)
	local sub_str_tab = {};
	if str ~= nil then 
		while (true) do
			local pos = string.find(str, split_char);
			if (not pos) then
				sub_str_tab[#sub_str_tab + 1] = str;
				break;
			end
			local sub_str = string.sub(str, 1, pos - 1);
			sub_str_tab[#sub_str_tab + 1] = sub_str;
			str = string.sub(str, pos + 1, #str);
		end
	end

    return sub_str_tab;
end
-- dota2jmz@163.com QQ:2462331592.