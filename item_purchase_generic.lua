----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Refactor: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------
local Item = require( GetScriptDirectory()..'/FunLib/jmz_item')
local Role = require( GetScriptDirectory()..'/FunLib/jmz_role')
local Chat = require( GetScriptDirectory()..'/FunLib/jmz_chat')

local bot = GetBot();

if bot:IsInvulnerable() 
	or not bot:IsHero() 
	or bot:IsIllusion()
	or bot:GetUnitName() == "npc_dota_hero_techies"
then
	return;
end

local BotBuild = require(GetScriptDirectory() .. "/BotLib/" .. string.gsub(bot:GetUnitName(), "npc_dota_", ""));

if BotBuild == nil then return end

--clone item build to bot.itemTobBuy in reverse order 
bot.itemToBuy = {};   
bot.currentItemToBuy = nil;  
bot.currentComponentToBuy = nil;   
bot.currListItemToBuy = {};         
bot.SecretShop = false;             
            

local sPurchaseList = BotBuild['sBuyList'];
local sItemSellList = BotBuild['sSellList'];

--Reverse item order
for i=1,#sPurchaseList
do
	bot.itemToBuy[i] = sPurchaseList[#sPurchaseList - i + 1];
end
 
--bot.itemToBuy = {};  
 
 
local sell_time = -90;
local check_time = -90;


local lastItemToBuy = nil;
local CanPurchaseFromSecret = false;
local itemCost = 0;
local courier = nil;
local t3AlreadyDamaged = false;
local t3Check = -90;

--General item BotBuild logis
local function GeneralPurchase()

	--Cache all needed item properties when the last item to buy not equal to current item component to buy
	if lastItemToBuy ~= bot.currentComponentToBuy then
		lastItemToBuy = bot.currentComponentToBuy;
		bot:SetNextItemPurchaseValue( GetItemCost( bot.currentComponentToBuy ) );
		CanPurchaseFromSecret = IsItemPurchasedFromSecretShop(bot.currentComponentToBuy);
		itemCost = GetItemCost( bot.currentComponentToBuy );
	end
	
	if  bot.currentComponentToBuy == "item_infused_raindrop" 
		or bot.currentComponentToBuy == "item_tome_of_knowledge"
		or bot.currentComponentToBuy == "item_ward_observer"
		or bot.currentComponentToBuy == "item_ward_sentry"
	then 
		if GetItemStockCount( bot.currentComponentToBuy ) < 1
		then
			return; 
		end
	end
	
	local cost = itemCost;
	
	--Save the gold for buyback whenever a tier 3 tower damaged or destroyed
	if bot:GetLevel() >= 18 and t3AlreadyDamaged == false and DotaTime() > t3Check + 1.0 then
		for i=2, 8, 3 do
			local tower = GetTower(GetTeam(), i);
			if tower == nil or tower:GetHealth()/tower:GetMaxHealth() < 0.1 then
				t3AlreadyDamaged = true;
				break;
			end
		end
		
		for i=1, 7, 3 do
			local tower = GetTower(GetTeam(), i);
			if tower ~= nil and tower:IsAlive() then  
				t3AlreadyDamaged = false;
				break;
			end
		end
		
		for i=9, 10, 1 do
			local tower = GetTower(GetTeam(), i);
			if tower == nil or tower:GetHealth()/tower:GetMaxHealth() < 0.9 then
				t3AlreadyDamaged = true;
				break;
			end
		end
		
		if DotaTime() >= 54 * 60 then t3AlreadyDamaged = true; end
		
		t3Check = DotaTime();
		
	elseif t3AlreadyDamaged == true and bot:GetBuybackCooldown() <= 10 then
		cost = itemCost + bot:GetBuybackCost() +  bot:GetNetWorth()/40 - 300;
	end
	
	--If only one Component
	if #bot.currListItemToBuy == 1 or Role.IsPvNMode()
	then
		cost = itemCost;
	end
	
	--buy the item if we have the gold
	if ( bot:GetGold() >= cost and bot:GetItemInSlot(14) == nil ) 
	then
		
		if courier == nil then
			courier = bot.theCourier
		end
		
		--buy done by courier for secret shop item
		if bot.SecretShop 
		   and courier ~= nil 
		   and GetCourierState(courier) == COURIER_STATE_IDLE 
		   and courier:DistanceFromSecretShop() == 0 
		then
			if courier:ActionImmediate_PurchaseItem( bot.currentComponentToBuy ) == PURCHASE_ITEM_SUCCESS then
				bot.currentComponentToBuy = nil;
				bot.currListItemToBuy[#bot.currListItemToBuy] = nil; 
				bot.SecretShop = false;
				return
			end
		end
				
		--Logic to decide in which shop bot have to buy the item
		if CanPurchaseFromSecret   
			and bot:DistanceFromSecretShop() > 0 
		then
			bot.SecretShop = true     			
		else                                                 
			if bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy ) == PURCHASE_ITEM_SUCCESS then
				bot.currentComponentToBuy = nil;                  
				bot.currListItemToBuy[#bot.currListItemToBuy] = nil;  
				bot.SecretShop = false;                                                            
				return
			else
				print("[item_purchase_generic] "..bot:GetUnitName().." failed to buy "..bot.currentComponentToBuy.." : "..tostring(bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy )))	
			end
		end	
	else
		bot.SecretShop = false;              
	end
end


--Turbo Mode General item BotBuild logis
local function TurboModeGeneralPurchase()
	--Cache all needed item properties when the last item to buy not equal to current item component to buy
	if lastItemToBuy ~= bot.currentComponentToBuy then
		lastItemToBuy = bot.currentComponentToBuy;
		bot:SetNextItemPurchaseValue( GetItemCost( bot.currentComponentToBuy ) );
		itemCost = GetItemCost( bot.currentComponentToBuy );
		lastItemToBuy = bot.currentComponentToBuy ;
	end
	
	if  bot.currentComponentToBuy == "item_infused_raindrop" 
		or bot.currentComponentToBuy == "item_tome_of_knowledge"
		or bot.currentComponentToBuy == "item_ward_observer"
		or bot.currentComponentToBuy == "item_ward_sentry"
	then 
		if GetItemStockCount( bot.currentComponentToBuy ) < 1
		then
			return; 
		end
	end
	
	local cost = itemCost;
		
	--buy the item if we have the gold
	if ( bot:GetGold() >= cost and bot:GetItemInSlot(14) == nil ) then
		if bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy ) == PURCHASE_ITEM_SUCCESS then
			bot.currentComponentToBuy = nil;
			bot.currListItemToBuy[#bot.currListItemToBuy] = nil; 
			return
		else
			print("[item_purchase_generic] "..bot:GetUnitName().." failed to BotBuild "..bot.currentComponentToBuy.." : "..tostring(bot:ActionImmediate_PurchaseItem( bot.currentComponentToBuy )))	
		end
	end
end


local lastInvCheck = -90;
local fullInvCheck = -90;
local lastBootsCheck = -90;
local buyBootsStatus = false;
local buyRD = false;
local buyTP = false;

local buyAnotherTango = false
local switchTime = 0
local buyWardTime = -999

local hasSelltEarlyBoots = false
local addTB2toBuy     = false
local addTravelBoots  = false
local hasBuyFallenSky = false
local hasBuyIronwoodTree = false
local hasBuyTrident = false
local hasBuyVambrace = false

local buyTPtime = 0;


function ItemPurchaseThink()  
	
	if ( GetGameState() ~= GAME_STATE_PRE_GAME and GetGameState() ~= GAME_STATE_GAME_IN_PROGRESS )
	then
		return;
	end

	if DotaTime() < -65
	then
		if bot.cloudBuy then
			local cloudBuyList = Chat.GetItemBuildList(bot.cloudBuy)
			for i=1,#cloudBuyList
			do
				bot.itemToBuy[i] = cloudBuyList[#cloudBuyList - i + 1];
			end
		end
		if bot.cloudSell then
			local cloudSellList = Chat.GetItemBuildList(bot.cloudSell)
			sItemSellList = cloudSellList
		end
		
		return;
	end
	
	if bot:HasModifier('modifier_arc_warden_tempest_double') then
		bot.itemToBuy = {};
		return;
	end	
	
	--------*******----------------*******----------------*******--------
	local currentTime = DotaTime();
	local botName  = bot:GetUnitName();
	local botLevel = bot:GetLevel();
	local botGold  = bot:GetGold();
	local botWorth = bot:GetNetWorth();
	local botMode  = bot:GetActiveMode();
	local botHP    = bot:GetHealth()/bot:GetMaxHealth();
	--------*******----------------*******----------------*******--------
	
	
	--buy another tango for midlaner
	if currentTime > 60 and currentTime < 4 *60 
	   and bot.theRole == "midlaner" 
	   and buyAnotherTango == false
	   and not Item.HasItem(bot,"item_tango_single")
	   and not Item.HasItem(bot,"item_tango")
	   and botGold > GetItemCost( "item_tango" ) 
	   and Item.GetEmptyInventoryAmount(bot) >= 5
	   and bot:GetCourierValue() == 0
	then
		bot:ActionImmediate_PurchaseItem("item_tango"); 
		buyAnotherTango = true;
		return;
	end
		
	--Update support availability status
	if Role['supportExist'] == nil then Role.UpdateSupportStatus(bot); end
	
	--Update invisible hero or item availability status
	if Role['invisEnemyExist'] == false then Role.UpdateInvisEnemyStatus(bot); end
	
	--Update boots availability status to make the bot start buy support item and rain drop
	if buyBootsStatus == false and currentTime > lastBootsCheck + 2.0 then buyBootsStatus = Item.UpdateBuyBootStatus(bot); lastBootsCheck = currentTime end
	
	--buy support item
	if bot.theRole == 'support' then
		if currentTime < 0 
			and botGold >= GetItemCost( "item_clarity" ) 
			and Item.HasItem(bot, "item_clarity") == false 
			and not Role.IsPvNMode()
		then
			bot:ActionImmediate_PurchaseItem("item_clarity");
			return;
		elseif botLevel >= 5 
			and Role['invisEnemyExist'] == true 
			and buyBootsStatus == true 
			and botGold >= GetItemCost( "item_dust" ) 
			and Item.GetEmptyInventoryAmount(bot) >= 2 
			and Item.GetItemCharges(bot, "item_dust") <= 0 and bot:GetCourierValue() == 0   
		then
			bot:ActionImmediate_PurchaseItem("item_dust");
			return;
		elseif GetItemStockCount( "item_ward_observer" ) >= 2 
			  and buyBootsStatus == true
			  and Item.GetEmptyInventoryAmount(bot) >= 2 
			  and Item.GetItemCharges(bot, "item_ward_observer") < 1  
			  and bot:GetCourierValue() == 0
			  and buyWardTime < currentTime - 3 *60
		then 
			buyWardTime = currentTime;
			bot:ActionImmediate_PurchaseItem("item_ward_observer"); 
			return;
		end
	end
	
	
	--buy raindrop
	if buyRD == false
	   and currentTime >= 3 *60
	   and currentTime <= 20 *60
	   and buyBootsStatus == true
	   and GetItemStockCount( "item_infused_raindrop" ) >= 1 
	   and Item.GetItemCharges(bot, 'item_infused_raindrop') <= 0
	   and botGold >= GetItemCost( "item_infused_raindrop" ) 
	   and Item.HasItem(bot, 'item_boots')
	then
		bot:ActionImmediate_PurchaseItem("item_infused_raindrop"); 
		buyRD = true;
		return;
	end
	
	
	if buyRD == false 
		and currentTime < 0
		and bot.theRole ~= 'support'
	then
		buyRD = true
	end
	
	
	--buy tp before die
	if botGold >= 50 
	   and bot:IsAlive()
	   and botGold < ( 50 + botWorth/40 )
	   and botHP < 0.08	   
	   and GetGameMode() ~= 23
	   and bot:GetHealth() >= 1
	   and bot:WasRecentlyDamagedByAnyHero(3.1)
	   and not Item.HasItem(bot, 'item_travel_boots')
	   and not Item.HasItem(bot, 'item_travel_boots_2')
	   and Item.GetItemCharges(bot, 'item_tpscroll') <= 3	   
	then
		bot:ActionImmediate_PurchaseItem("item_tpscroll"); 
		return;
	end	 

	
	--buy dust before die
	if botGold >= 90 
	   and bot:IsAlive()
	   and botLevel > 6
	   and bot.theRole == 'support'
	   and botGold < ( 90 + botWorth/40 )
	   and botHP < 0.06	   
	   and GetGameMode() ~= 23
	   and bot:GetHealth() >= 1
	   and bot:WasRecentlyDamagedByAnyHero(3.1)
	   and Item.GetItemCharges(bot, 'item_dust') <= 1	  
	then
		bot:ActionImmediate_PurchaseItem("item_dust"); 
		return;
	end
	
	--buy tom of knowledge before die
	if currentTime > 10 *60
	   and bot:IsAlive()
	   and botGold >= 150 
	   and botGold < ( 150 + botWorth/40 )
	   and botHP < 0.08	   
	   and botLevel <= 28
	   and GetGameMode() ~= 23
	   and bot:WasRecentlyDamagedByAnyHero(3.1)
	   and GetItemStockCount( "item_tome_of_knowledge" ) >= 1
	   and Item.GetItemCharges(bot, 'item_tome_of_knowledge') <= 0
	then
		bot:ActionImmediate_PurchaseItem("item_tome_of_knowledge"); 
		return;
	end
	
		
	--swap raindrop when it may be broken
	if currentTime > 180 and currentTime < 1800
	   and switchTime < currentTime - 5.6
	then
		local raindrop = bot:FindItemSlot("item_infused_raindrop");
		local raindropCharge = Item.GetItemCharges(bot, "item_infused_raindrop");
		local nEnemyHeroes = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)
		if (raindrop >= 0 and raindrop <= 5)
		   and ( nEnemyHeroes[1] ~= nil 
				 or botMode == BOT_MODE_ROSHAN
		         or bot:WasRecentlyDamagedByAnyHero(3.1))
		   and ( raindropCharge == 1 or raindropCharge >= 7 )
		then
		    switchTime = currentTime;
			bot:ActionImmediate_SwapItems( raindrop, 6 );
			return;
		end
	end
	
	--swap ward,flask,tango_single,neutral_item
	if currentTime > 0
		and botMode ~= BOT_MODE_WARD
		and check_time < currentTime - 3.0
	then
		check_time = currentTime;
		
		--ward
		local wardSlot = bot:FindItemSlot('item_ward_observer');
		if wardSlot >=0 and wardSlot <= 5 
		   and bot.lastSwapWardTime < currentTime - 11
		   and currentTime > 3 * 60
		then
			local mostCostItem = Item.GetTheItemSolt(bot, 6, 9, true)
			if mostCostItem ~= -1 then
				bot:ActionImmediate_SwapItems( wardSlot, mostCostItem );
				return;
			end
		end

		--tango_single
		local tango_single = bot:FindItemSlot('item_tango_single');
		if tango_single >= 0 and tango_single <= 5 
		   and Item.GetItemCountInSolt(bot, "item_tango_single", 0, 5) >= 2 
		then
			local mostCostItem = Item.GetTheItemSolt(bot, 6, 9, true)
			if mostCostItem ~= -1 then
				bot:ActionImmediate_SwapItems( tango_single, mostCostItem );
				return;
			end
		end
		
		--获取副背包中最高级中立物品格子与等级
		--获取主背包中最低级中立物品格子与等级
		--如果主的等级小于副的等级就交换
		local nNeutralBackpackSolt = -1
		local nNeutralBackpackLevel = -1
		for i =6,9
		do
			local inSoltItem = bot:GetItemInSlot(i)
			if inSoltItem ~= nil
			then
				local inSoltItemName = inSoltItem:GetName()
				if Item.IsNeutralItem(inSoltItemName)
					and not Item.IsNeutralItemRecipe(inSoltItemName)
					and Item.GetNeutralItemLevel(inSoltItemName) > nNeutralBackpackLevel
				then
					nNeutralBackpackSolt = i
					nNeutralBackpackLevel = Item.GetNeutralItemLevel(inSoltItemName)
				end				
			end		
		end
		if nNeutralBackpackSolt > 5
		then
			local nNeutralMainSolt = -1
			local nNeutralMainLevel = 999
			for i =0,5
			do
				local inSoltItem = bot:GetItemInSlot(i)
				if inSoltItem == nil
				then
					nNeutralMainSolt = i
					nNeutralMainLevel = 0
					break;
				elseif inSoltItem ~= nil
					then
						local inSoltItemName = inSoltItem:GetName()
						if Item.IsNeutralItem(inSoltItemName)
							and not Item.IsNeutralCostItem(inSoltItemName)
							and Item.GetNeutralItemLevel(inSoltItemName) < nNeutralMainLevel
						then
							nNeutralMainSolt = i
							nNeutralMainLevel = Item.GetNeutralItemLevel(inSoltItemName)
						end				
				end		
			end	
			
			if nNeutralBackpackLevel > nNeutralMainLevel 
			then
				bot:ActionImmediate_SwapItems( nNeutralBackpackSolt, nNeutralMainSolt );
				--print(bot:GetUnitName().."SwapItem:"..nNeutralBackpackSolt..":"..nNeutralMainSolt)
				return;
			end			
		end
		
		
		--如果捡到了中立卷轴则添加配件购买
		--铁树之木
		local recipeIronwoodTree = bot:FindItemSlot('item_recipe_ironwood_tree');
		if recipeIronwoodTree >= 0
			and not hasBuyIronwoodTree
		then
			hasBuyIronwoodTree = true
			bot.currentComponentToBuy = nil;
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_branches';
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_branches';
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_branches';
			return;
		end
		
		--臂甲
		local recipeVambrace = bot:FindItemSlot('item_recipe_vambrace');
		if recipeVambrace >= 0
			and not hasBuyVambrace
		then
			hasBuyVambrace = true
			local sVambraceComponent, sVambraceComponent_1, sVambraceComponent_2 = Item.GetVambraceComponent(bot);
			if bot:FindItemSlot(sVambraceComponent) >= 0
			then
				bot.currentComponentToBuy = nil;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_2;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_circlet';
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_1;
				return;
			else
				bot.currentComponentToBuy = nil;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_2;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_circlet';
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_1;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_2;
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_circlet';
				bot.currListItemToBuy[#bot.currListItemToBuy+1] = sVambraceComponent_1;
				return;
			end
		end
		
		--堕天斧
		local recipeFallenSky = bot:FindItemSlot('item_recipe_fallen_sky');
		if recipeFallenSky >= 0
			and not hasBuyFallenSky
		then
			hasBuyFallenSky = true
			if #bot.itemToBuy >= 1 
			then
				table.insert(bot.itemToBuy,#bot.itemToBuy,'item_fallen_sky')
			else
				bot.itemToBuy = { 'item_fallen_sky' }
			end
			return;
		end		
		
		--三叉戟
		local recipeTrident = bot:FindItemSlot('item_recipe_trident');
		if recipeTrident >= 0
			and not hasBuyTrident
		then
			hasBuyTrident = true
			local sTridentNameToBuy = Item.GetTridentNameToBuy(bot)
			if #bot.itemToBuy >= 1 
			then
				table.insert(bot.itemToBuy,#bot.itemToBuy,sTridentNameToBuy)
			else
				bot.itemToBuy = { sTridentNameToBuy }
			end
			return;
		end
		
		
	end
	
	
	--sell early game item   
	if  ( GetGameMode() ~= 23 and botLevel > 6 and currentTime > fullInvCheck + 1.0 
	      and ( bot:DistanceFromFountain() <= 100 or bot:DistanceFromSecretShop() <= 100 ) ) 
		or ( GetGameMode() == 23 and botLevel > 9 and currentTime > fullInvCheck + 1.0  )
	then
		local emptySlot = Item.GetEmptyInventoryAmount(bot);
		local slotToSell = nil;
		
		local preEmpty = 2;
		if botLevel < 15 then preEmpty = 1; end
		if emptySlot < preEmpty then
			for i=1,#Item['tEarlyItem'] 
			do
				local item = Item['tEarlyItem'][i];
				local itemSlot = bot:FindItemSlot(item);
				if itemSlot >= 0 and itemSlot <= 9 
				then
					if item == "item_magic_wand" or item == "item_magic_stick" 
					then
						if 	( emptySlot == 0 and botWorth > 8000) 
						    or botWorth > 12000
						then
							slotToSell = itemSlot;
							break;
						end
					elseif ( item == "item_bracer" or item == "item_wraith_band" or item == "item_null_talisman" )
						then
							if not Item.HasItem(bot,"item_recipe_vambrace")
							then
								slotToSell = itemSlot;
								break;
							end
					else
						slotToSell = itemSlot;
						break;
					end
				end
			end
		end	
		
		--for wand and neutral item
		if botWorth > 4200 
		then
			local wand = bot:FindItemSlot("item_magic_wand");
			local assitItem =  bot:FindItemSlot("item_infused_raindrop");
			if assitItem < 0 then assitItem =  bot:FindItemSlot("item_bracer"); end
			if assitItem < 0 then assitItem =  bot:FindItemSlot("item_null_talisman"); end
			if assitItem < 0 then assitItem =  bot:FindItemSlot("item_wraith_band"); end		
			if	assitItem >= 0 
				and not Item.HasItem(bot,"item_recipe_vambrace")
				and (	( wand >= 6 and wand <= 9 ) 
						or Item.GetEmptyInventoryAmount(bot) <= 2 )
			then
				slotToSell = assitItem;
			end	
		end
		
		if slotToSell ~= nil then
			bot:ActionImmediate_SellItem(bot:GetItemInSlot(slotToSell));
			return;
		end
		
		fullInvCheck = currentTime;
	end
	
	--sale late item 
	if currentTime > sell_time + 0.5
	   and ( bot:GetItemInSlot(6) ~= nil or bot:GetItemInSlot(7) ~= nil or bot:GetItemInSlot(8) ~= nil)
	   and ( bot:DistanceFromFountain() <= 100 or bot:DistanceFromSecretShop() <= 100 ) 
	then
		sell_time = currentTime;
		
		if not Item.HasItem(bot,"item_recipe_vambrace") 
			or ( not Item.HasItem(bot,"item_recipe_vambrace") and not Item.HasItem(bot,"item_recipe_vambrace") and not Item.HasItem(bot,"item_recipe_vambrace") )
		then		
			for i = 2 ,#sItemSellList, 2
			do
				local nNewSlot = bot:FindItemSlot(sItemSellList[i -1]);
				local nOldSlot = bot:FindItemSlot(sItemSellList[i]);
				if nNewSlot >= 0 and nOldSlot >= 0
				then
					--print(sItemSellList[i -1]..sItemSellList[i]);
					bot:ActionImmediate_SellItem(bot:GetItemInSlot(nOldSlot));
					return;
				end
			end
		end
		
		--Sell non travel_boot when have travel_boot
		if currentTime > 30 *60 and not hasSelltEarlyBoots 
		   and  ( Item.HasItem( bot, "item_travel_boots") or Item.HasItem( bot, "item_travel_boots_2")) 
		then	
			for i=1,#Item['tEarlyBoots']
			do
				local bootsSlot = bot:FindItemSlot(Item['tEarlyBoots'][i]);
				if bootsSlot >= 0 then
					bot:ActionImmediate_SellItem(bot:GetItemInSlot(bootsSlot));
					hasSelltEarlyBoots = true;
					return;
				end
			end
		end		
		
	end
	
	
	--Insert tp scroll to list item to buy and then change the buyTP flag so the bots don't reapeatedly add the tp scroll to list item to buy 
	if	currentTime > 4 *60 
	    and buyTP == false 
		and bot:GetCourierValue() == 0 
		and (bot:FindItemSlot('item_tpscroll') == -1 
		      or (botLevel >= 12 and Item.GetItemCharges(bot, 'item_tpscroll') <= 1)) 
		and botGold >= 50
	then
		local tCharges = Item.GetItemCharges(bot, 'item_tpscroll');
		
		if botLevel < 12 or (botLevel >= 12 and tCharges == 1)
		then
			buyTP = true;
			buyTPtime = currentTime;
			bot.currentComponentToBuy = nil;	
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_tpscroll';
			return;
		end
		
		if botLevel >= 12 and tCharges == 0 and botGold >= 100
		then
			buyTP = true;
			buyTPtime = currentTime;
			bot.currentComponentToBuy = nil;	
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_tpscroll';
			bot.currListItemToBuy[#bot.currListItemToBuy+1] = 'item_tpscroll';
			return;
		end
	end
	
	--Change the flag to buy tp scroll to false when it already has it in inventory so the bot can insert tp scroll to list item to buy whenever they don't have any tp scroll
	if buyTP == true and buyTPtime < currentTime - 70
	then
		buyTP = false;
	end
	
	--Add travelboots,moonshare,bkb to buy when in very late
	if currentTime > 10 * 60 
		and #bot.itemToBuy == 0 
		and not Role.IsUserMode() 
	then

		if addTravelBoots == false
		   and Item.HasItem(bot, 'item_travel_boots') 
		then
			addTravelBoots = true;
			return;
		end
	
		if addTravelBoots == false 
		   and not Item.HasItem(bot, 'item_guardian_greaves')
		then
			bot.itemToBuy = {'item_travel_boots'};
			addTravelBoots = true;
			return;
		end
	
		if Role.ShouldBuyMoonShare()
		   and botGold > 4000 + bot:GetBuybackCost() + ( 50 + botWorth/40 ) - 333
		then
			
			bot.itemToBuy = {'item_moon_shard' };
			Role['moonshareCount'] = Role['moonshareCount'] - 1;
			return;
			
		end
		
		if addTB2toBuy == false
		   and Item.HasItem(bot, 'item_travel_boots_2')
		then
			addTB2toBuy = true;
			return;
		end
	
		if  addTB2toBuy == false
		    and addTravelBoots == true
		    and not Item.HasItem(bot, 'item_guardian_greaves')
			and not Role.ShouldBuyMoonShare()
			and not Item.HasItem(bot, 'item_moon_shard')
			and botGold > 2000 + bot:GetBuybackCost() + botWorth/40 - 222
		then
			addTB2toBuy = true;
			bot.itemToBuy = {'item_travel_boots_2'};
			return;
		end
	end
	
	--Sell cheapie when have travel_boots
	if  currentTime > 52 * 60 --and #bot.itemToBuy == 0 
		and ( ( bot:GetItemInSlot(7) ~= nil or bot:GetItemInSlot(8) ~= nil ) and bot:GetItemInSlot(6) ~= nil )
		and ( Item.HasItem(bot, 'item_travel_boots') or Item.HasItem(bot, 'item_travel_boots_2'))
		and ( bot:DistanceFromFountain() <= 100 or bot:DistanceFromSecretShop() == 0 )
		and ( not Item.HasItem(bot, 'item_refresher_shard') and not Item.HasItem(bot, 'item_cheese') and not Item.HasItem(bot, "item_aegis") )
		and ( not Item.HasItem(bot, 'item_dust') and not Item.HasItem(bot, "item_ward_observer") )
		and ( not Item.HasItem(bot, 'item_moon_shard') and not Item.HasItem(bot, "item_hyperstone") )
		and ( not Item.HasItem(bot, 'item_recipe_trident') and not Item.HasItem(bot, "item_recipe_fallen_sky") )
	then
		local itemToSell = nil;
		local itemToSellValue = 99999;
		for i = 0, 9
		do
			local tempItem = bot:GetItemInSlot(i);
			if tempItem ~= nil 			   
			then
				local tempItemName = tempItem:GetName();
				if not Item.IsNotSellItem(tempItemName)
				   and not Item.IsNeutralItem(tempItemName)
				   and GetItemCost(tempItemName) < itemToSellValue
				then
					itemToSell = tempItem;
					itemToSellValue = GetItemCost(tempItemName);
				end
			end
		end		
		if itemToSell ~= nil
		then
			bot:ActionImmediate_SellItem(itemToSell);
			return;
		end
	end
	
		
	--No need to buy item when no item to buy in the list
	if #bot.itemToBuy == 0 then bot:SetNextItemPurchaseValue( 0 ); return; end
	
	--Get the next item to buy and break it to item components then add it to currListItemToBuy. 
	--It'll only done if the bot already has the item that formed from its component in their hero's inventory (not stash) to prevent unintended item combining
	if  bot.currentItemToBuy == nil and #bot.currListItemToBuy == 0 then    
		bot.currentItemToBuy = bot.itemToBuy[#bot.itemToBuy];               
		local tempTable = Item.GetBasicItems({bot.currentItemToBuy})   
		for i=1,math.ceil(#tempTable/2)                                                     
		do	
			bot.currListItemToBuy[i] = tempTable[#tempTable-i+1];
			bot.currListItemToBuy[#tempTable-i+1] = tempTable[i];
		end
		
	end
	
	--Check if the bot already has the item formed from its components in their inventory (not stash)
	if  #bot.currListItemToBuy == 0 and currentTime > lastInvCheck + 1.0 then  
	    if Item.IsItemInHero(bot.currentItemToBuy) 
		then   
			bot.currentItemToBuy = nil;                         
			bot.itemToBuy[#bot.itemToBuy] = nil;           
		else
			lastInvCheck = currentTime;
		end
	--Added item component to current item component to buy and do the BotBuild	
	elseif #bot.currListItemToBuy > 0 then           
		if bot.currentComponentToBuy == nil then      
			bot.currentComponentToBuy = bot.currListItemToBuy[#bot.currListItemToBuy];  
		else                                          
			if GetGameMode() == 23 then
				TurboModeGeneralPurchase();
			else
				GeneralPurchase();
			end	
		end
	end

end
-- dota2jmz@163.com QQ:2462331592.
