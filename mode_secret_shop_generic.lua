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

local bot = GetBot();
local X = {}
local preferedSS = nil;
local RAD_SECRET_SHOP = GetShopLocation(GetTeam(), SHOP_SECRET )
local DIRE_SECRET_SHOP = GetShopLocation(GetTeam(), SHOP_SECRET2 )
local have = false;

function GetDesire()
		
	if not X.IsSuitableToBuy() 
	then
		return BOT_MODE_DESIRE_NONE;
	end
	
	local invFull = true;
	
	for i=0,8 do 
		if bot:GetItemInSlot(i) == nil then
			invFull = false;
		end	
	end
	
	if invFull then
		if bot:GetLevel() > 11 and bot:FindItemSlot("item_aegis") < 0 then
			have, itemSlot = X.HaveItemToSell();
			if have then
				preferedSS = X.GetPreferedSecretShop();
				if  preferedSS ~= nil then
					return RemapValClamped(  GetUnitToLocationDistance(bot, preferedSS), 6000, 0, 0.75, 0.95 );
				end	
			end
		end
		return BOT_MODE_DESIRE_NONE;
	end
	
	local npcCourier = bot.theCourier
	local cState = GetCourierState( npcCourier );
	
	if bot.SecretShop and cState ~= COURIER_STATE_MOVING  then
		preferedSS = X.GetPreferedSecretShop();
		if  preferedSS ~= nil and cState == COURIER_STATE_DEAD then
			return RemapValClamped(  GetUnitToLocationDistance(bot, preferedSS), 6000, 0, 0.7, 0.85 );
		else
			if preferedSS ~= nil and GetUnitToLocationDistance(bot, preferedSS) <= 3200 then
				return RemapValClamped(  GetUnitToLocationDistance(bot, preferedSS), 3200, 0, 0.7, 0.85 );
			end
		end
	end
	
	return BOT_MODE_DESIRE_NONE

end

function OnStart()

end

function OnEnd()

end

function Think()

	if  bot:IsChanneling() 
		or bot:NumQueuedActions() > 0
		or bot:IsCastingAbility()
		or bot:IsUsingAbility()
	then 
		if not bot:IsInvisible()
		then
			return;
		end
	end
	
	if bot:DistanceFromSecretShop() == 0
	then
		bot:Action_MoveToLocation(preferedSS + RandomVector(200))
		return;
	end

	if bot:DistanceFromSecretShop() > 0
	then
		bot:Action_MoveToLocation(preferedSS);
		return;
	end
	
end

--这些是AI会主动走到商店出售的物品
function X.HaveItemToSell()
	local earlyGameItem = {
		 "item_clarity",
		 "item_faerie_fire",
		 "item_tango",  
		 "item_flask", 
		 "item_orb_of_venom",
		 "item_bracer",
		 "item_wraith_band",
		 "item_null_talisman",
		 "item_infused_raindrop",
		 "item_bottle",  
		 "item_ancient_janggo",
	}
	for _,item in pairs(earlyGameItem) 
	do
		local slot = bot:FindItemSlot(item)
		if slot >= 0 and slot <= 8 then
			return true, slot;
		end
	end
	return false, nil;
end

function X.GetPreferedSecretShop()
	if GetTeam() == TEAM_RADIANT then
		if GetUnitToLocationDistance(bot, DIRE_SECRET_SHOP) <= 3800 then
			return DIRE_SECRET_SHOP;
		else
			return RAD_SECRET_SHOP;
		end
	elseif GetTeam() == TEAM_DIRE then
		if GetUnitToLocationDistance(bot, RAD_SECRET_SHOP) <= 3800 then
			return RAD_SECRET_SHOP;
		else
			return DIRE_SECRET_SHOP;
		end
	end
	return nil;
end

function X.IsSuitableToBuy()
	local mode = bot:GetActiveMode();
	local Enemies = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	if ( ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() >= BOT_MODE_DESIRE_HIGH )
		or mode == BOT_MODE_ATTACK
		or mode == BOT_MODE_DEFEND_ALLY
		or mode == BOT_MODE_DEFEND_TOWER_TOP
		or mode == BOT_MODE_DEFEND_TOWER_MID
		or mode == BOT_MODE_DEFEND_TOWER_BOT
		or ( Enemies ~= nil and #Enemies >= 2 )
		or ( Enemies[1] ~= nil and X.IsStronger(bot, Enemies[1]) )
		or GetUnitToUnitDistance(bot, GetAncient(GetTeam())) < 2300 
		or GetUnitToUnitDistance(bot, GetAncient(GetOpposingTeam())) < 3500 
		) 
	then
		return false;
	end
	return true;
end

function X.IsStronger(bot, enemy)
	local BPower = bot:GetEstimatedDamageToTarget(true, enemy, 4.0, DAMAGE_TYPE_ALL);
	local EPower = enemy:GetEstimatedDamageToTarget(true, bot, 4.0, DAMAGE_TYPE_ALL);
	return EPower > BPower;
end
-- dota2jmz@163.com QQ:2462331592。