----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 2018.11.21
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Refactor: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------
local X = {}
local bDebugMode = ( 1 == 10 )
local bot = GetBot()

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local Minion = dofile( GetScriptDirectory()..'/FunLib/Minion')
local sTalentList = J.Skill.GetTalentList(bot)
local sAbilityList = J.Skill.GetAbilityList(bot)
local sOutfitType = J.Item.GetOutfitType(bot)

local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,2,2,2,6,2,1,1,1,6,3,3,3,6},
						{1,3,2,2,2,6,2,3,3,3,6,1,1,1,6},
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

local tOutFitList = {}

tOutFitList['outfit_carry'] = {

	"item_sven_outfit",
	"item_echo_sabre",
	"item_manta",
	"item_heart",
	"item_abyssal_blade",
	"item_assault",
	"item_black_king_bar",

				
}

tOutFitList['outfit_mid'] = tOutFitList['outfit_carry']

tOutFitList['outfit_priest'] = tOutFitList['outfit_carry']

tOutFitList['outfit_mage'] = tOutFitList['outfit_carry']

tOutFitList['outfit_tank'] = {

	"item_tank_outfit",
	"item_crimson_guard",
	"item_echo_sabre",
	"item_heavens_halberd",
	"item_manta",
	"item_assault",
	"item_heart",
				
}

X['sBuyList'] = tOutFitList[sOutfitType]

X['sSellList'] = {
	
	"iitem_heavens_halberd",
	"item_quelling_blade",
	
	"item_assault",
	"item_echo_sabre",
	
	"item_assault",
	"item_magic_wand",
	
	"item_manta",
	"item_quelling_blade",
}

if J.Role.IsPvNMode() or J.Role.IsAllShadow() then X['sBuyList'],X['sSellList'] = { 'PvN_tank' }, {"item_heavens_halberd",'item_quelling_blade'} end

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = J.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)


X['bDeafaultAbility'] = true
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
	then
		Minion.IllusionThink(hMinionUnit)
	end

end

--[[

npc_dota_hero_chaos_knight

"Ability1"		"chaos_knight_chaos_bolt"
"Ability2"		"chaos_knight_reality_rift"
"Ability3"		"chaos_knight_chaos_strike"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"chaos_knight_phantasm"
"Ability10"		"special_bonus_all_stats_5"
"Ability11"		"special_bonus_movement_speed_20"
"Ability12"		"special_bonus_strength_15"
"Ability13"		"special_bonus_cooldown_reduction_12"
"Ability14"		"special_bonus_gold_income_25"
"Ability15"		"special_bonus_unique_chaos_knight"
"Ability16"		"special_bonus_unique_chaos_knight_2"
"Ability17"		"special_bonus_unique_chaos_knight_3"

modifier_chaos_knight_reality_rift_buff
modifier_chaos_knight_reality_rift
modifier_chaos_knight_chaos_strike
modifier_chaos_knight_chaos_strike_debuff
modifier_chaos_knight_phantasm
modifier_chaos_knight_phantasm_illusion

--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] );
local abilityW = bot:GetAbilityByName( sAbilityList[2] );
local abilityR = bot:GetAbilityByName( sAbilityList[6] );
local talent6  = bot:GetAbilityByName( sTalentList[6] );

local castQDesire,castQTarget = 0;
local castWDesire,castWTarget = 0;
local castRDesire = 0;

local nKeepMana,nMP,nHP,nLV,hEnemyHeroList;


function X.SkillsComplement()

	if J.CanNotUseAbility(bot) or bot:IsInvisible() then return end
	
	nKeepMana = 240; 
	nMP = bot:GetMana()/bot:GetMaxMana();
	nHP = bot:GetHealth()/bot:GetMaxHealth();
	nLV = bot:GetLevel();
	hEnemyHeroList = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
		
	castRDesire = X.ConsiderR();
	if ( castRDesire > 0 ) 
	then
		bot:ActionQueue_UseAbility( abilityR )
		return;	
	end
	
	castWDesire, castWTarget = X.ConsiderW();
	if ( castWDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, false)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return;
	end
	
	castQDesire, castQTarget = X.ConsiderQ();
	if ( castQDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return;
	end
	
	

end

function X.ConsiderQ()
	
	if not abilityQ:IsFullyCastable() or bot:IsRooted() then return BOT_ACTION_DESIRE_NONE end
	
	local nCastRange = abilityQ:GetCastRange();
	local nCastPoint = abilityQ:GetCastPoint();
	local nSkillLV   = abilityQ:GetLevel( );
	local nDamage    = 30 + nSkillLV*30 + 120 * 0.38;
	
	local nEnemysHeroesInCastRange = bot:GetNearbyHeroes(nCastRange +99, true, BOT_MODE_NONE);	
	local nEnemysHeroesInView      = bot:GetNearbyHeroes(880, true, BOT_MODE_NONE);
	
	--击杀
	if #nEnemysHeroesInCastRange > 0 then
		for i=1, #nEnemysHeroesInCastRange do
			if J.IsValid(nEnemysHeroesInCastRange[i])
			   and J.CanCastOnNonMagicImmune(nEnemysHeroesInCastRange[i]) 
			   and J.CanCastOnTargetAdvanced(nEnemysHeroesInCastRange[i])
			   and nEnemysHeroesInCastRange[i]:GetHealth() < nEnemysHeroesInCastRange[i]:GetActualIncomingDamage(nDamage,DAMAGE_TYPE_MAGICAL)
			   and not (GetUnitToUnitDistance(nEnemysHeroesInCastRange[i],bot) <= bot:GetAttackRange() + 60)
			   and not J.IsDisabled(true, nEnemysHeroesInCastRange[i]) 
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInCastRange[i];
			end
		end
	end
	
	--打断
	if #nEnemysHeroesInView > 0 then
		for i=1, #nEnemysHeroesInView do
			if J.IsValid(nEnemysHeroesInView[i])
			   and J.CanCastOnNonMagicImmune(nEnemysHeroesInView[i]) 
			   and J.CanCastOnTargetAdvanced(nEnemysHeroesInView[i])
			   and nEnemysHeroesInView[i]:IsChanneling()
			then
				return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInCastRange[i];
			end
		end
	end
	
	
	--团战
	if J.IsInTeamFight(bot, 1200)
	   and DotaTime() > 6*60
	then
		local npcMostDangerousEnemy = nil;
		local nMostDangerousDamage = 0;
		
		for _,npcEnemy in pairs( nEnemysHeroesInCastRange )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastOnNonMagicImmune(npcEnemy) 
				and J.CanCastOnTargetAdvanced(npcEnemy)
				and not J.IsDisabled(true, npcEnemy)
				and not npcEnemy:IsDisarmed()
				--and not npcEnemy:HasModifier("modifier_chaos_knight_reality_rift_debuff")
			then
				local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_ALL );
				if ( npcEnemyDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = npcEnemyDamage;
					npcMostDangerousEnemy = npcEnemy;
				end
			end
		end
		
		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy;
		end		
	end
	
	
	--配合
	for _,npcEnemy in pairs( nEnemysHeroesInCastRange )
	do
		if  J.IsValid(npcEnemy)
		    and J.CanCastOnNonMagicImmune(npcEnemy) 
			and J.CanCastOnTargetAdvanced(npcEnemy)
			and not J.IsDisabled(true, npcEnemy)
			and not npcEnemy:IsDisarmed()
			and npcEnemy:HasModifier("modifier_chaos_knight_reality_rift")
		then
		    local npcModifier = npcEnemy:NumModifiers();
			for i = 0, npcModifier 
			do
				if npcEnemy:GetModifierName(i) == "modifier_chaos_knight_reality_rift" 
				then
					if ( npcEnemy:GetModifierRemainingDuration(i) <= nCastPoint )
					then
						return BOT_ACTION_DESIRE_HIGH, npcEnemy;
					end
					break;
				end
			end
		end
	end
	
	--常规
	if J.IsGoingOnSomeone(bot)
	then
		local target = J.GetProperTarget(bot)
		if J.IsValidHero(target) 
			and J.CanCastOnNonMagicImmune(target) 
			and J.CanCastOnTargetAdvanced(target)
			and J.IsInRange(target, bot, nCastRange) 
		    and not J.IsDisabled(true, target)
			and not target:IsDisarmed()
			and not target:HasModifier("modifier_chaos_knight_reality_rift_debuff")
		then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	
	if J.IsRetreating(bot) 
	then
		if J.IsValid(nEnemysHeroesInCastRange[1]) 
		   and J.CanCastOnNonMagicImmune(nEnemysHeroesInCastRange[1]) 
		   and J.CanCastOnTargetAdvanced(nEnemysHeroesInCastRange[1])
		   and not J.IsDisabled(true, nEnemysHeroesInCastRange[1])
		   and not nEnemysHeroesInCastRange[1]:IsDisarmed()
		   and GetUnitToUnitDistance(bot,nEnemysHeroesInCastRange[1]) <= nCastRange - 60 
		then
			return BOT_ACTION_DESIRE_HIGH, nEnemysHeroesInCastRange[1];
		end
	end
	
	
	if bot:GetActiveMode() == BOT_MODE_ROSHAN 
		and bot:GetMana() > 400
	then
		local target =  bot:GetAttackTarget();
		
		if target ~= nil and target:IsAlive()
		    and J.GetHPR(target) > 0.2
			and not J.IsDisabled(true, target)
			and not target:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_LOW, target;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

function X.ConsiderW()
	
	if not abilityW:IsFullyCastable() or bot:IsRooted() then return BOT_ACTION_DESIRE_NONE end
	
	local nCastRange = abilityW:GetCastRange() + 40;
	local nCastPoint = abilityW:GetCastPoint();
	local nSkillLV   = abilityW:GetLevel();
	local nDamage    = 0;
	local bIgnoreMagicImmune = talent6:IsTrained();
	
	local nEnemysHeroesInCastRange = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE);		
	
	--[[

	if J.IsInTeamFight(bot, 1200)
	   and DotaTime() > 6*60
	then
		local npcTarget = nil;
		local npcTargetHealth = 99999;		
		
		for _,npcEnemy in pairs( nEnemysHeroesInCastRange )
		do
			if  J.IsValid(npcEnemy)
				and J.CanCastAbilityOnTarget(npcEnemy,bIgnoreMagicImmune)
				and J.CanCastOnTargetAdvanced(npcEnemy)
				and not J.IsDisabled(true, npcEnemy)
				and not npcEnemy:IsAttackImmune()
				and npcEnemy:GetPrimaryAttribute() == ATTRIBUTE_INTELLECT
				and npcEnemy:GetUnitName() ~= "npc_dota_hero_necrolyte"
			then
				if ( npcEnemy:GetHealth() < npcTargetHealth )
				then
					npcTarget = npcEnemy;
					npcTargetHealth = npcEnemy:GetHealth();
				end
			end
		end		
		if ( npcTarget ~= nil )
		then
			bot:SetTarget(npcTarget);
			return BOT_ACTION_DESIRE_HIGH, npcTarget;
		end		
		
		
		for _,npcEnemy in pairs( nEnemysHeroesInCastRange )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastAbilityOnTarget(npcEnemy,bIgnoreMagicImmune)
				and J.CanCastOnTargetAdvanced(npcEnemy)
				and not J.IsDisabled(true, npcEnemy)
				and not npcEnemy:IsAttackImmune()
				and npcEnemy:GetPrimaryAttribute() == ATTRIBUTE_AGILITY
				and not npcEnemy:GetUnitName() == "npc_dota_hero_meepo"
			then
				if ( npcEnemy:GetHealth() < npcTargetHealth )
				then
					npcTarget = npcEnemy;
					npcTargetHealth = npcEnemy:GetHealth();
				end
			end
		end		
		if ( npcTarget ~= nil )
		then
			bot:SetTarget(npcTarget);
			return BOT_ACTION_DESIRE_HIGH, npcTarget;
		end		
		
		
		for _,npcEnemy in pairs( nEnemysHeroesInCastRange )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastAbilityOnTarget(npcEnemy,bIgnoreMagicImmune)
				and J.CanCastOnTargetAdvanced(npcEnemy)
				and not npcEnemy:IsAttackImmune()
				and not J.IsDisabled(true, npcEnemy)
			then
				if ( npcEnemy:GetHealth() < npcTargetHealth )
				then
					npcTarget = npcEnemy;
					npcTargetHealth = npcEnemy:GetHealth();
				end
			end
		end		
		if ( npcTarget ~= nil )
		then
			
			bot:SetTarget(npcTarget);
			return BOT_ACTION_DESIRE_HIGH, npcTarget;
		end			
	end


--]]
	
		
	if J.IsGoingOnSomeone(bot)
		and DotaTime() > 6*30 
	then
		local target = J.GetProperTarget(bot)
		if  J.IsValidHero(target) 
			and J.CanCastAbilityOnTarget(target,bIgnoreMagicImmune)
			and J.CanCastOnTargetAdvanced(target)
			and J.IsInRange(target, bot, nCastRange) 
		    and not J.IsDisabled(true, target)
		then
			return BOT_ACTION_DESIRE_HIGH, target;
		end
	end
	
	
	if J.IsRetreating(bot) 
	then
		local enemies = bot:GetNearbyHeroes(800, true, BOT_MODE_NONE);
		local creeps  = bot:GetNearbyLaneCreeps(nCastRange, true);
		if J.IsValid(enemies[1])
		   and bot:IsFacingLocation(enemies[1]:GetLocation(),45)
		   and J.CanCastAbilityOnTarget(enemies[1],bIgnoreMagicImmune)
		   and J.CanCastOnTargetAdvanced(enemies[1])
		   and J.IsInRange(enemies[1], bot, 150)
		   and not J.IsDisabled(true, enemies[1])
		   and not enemies[1]:IsDisarmed()
		then
			
			return BOT_ACTION_DESIRE_HIGH, enemies[1];
		end		
		
		if enemies[1] ~= nil and creeps[1] ~= nil
		then
		    for _,creep in pairs( creeps )
			do
				if  enemies[1]:IsFacingLocation(bot:GetLocation(),30)
					and bot:IsFacingLocation(creep:GetLocation(),30)
					and GetUnitToUnitDistance(bot,creep) >= 650
				then
					
					return BOT_ACTION_DESIRE_LOW, creep;
				end
			end
		end
	end
	
	
	if hEnemyHeroList[1] == nil
		and bot:GetAttackDamage() >= 150
	then
		local nCreeps = bot:GetNearbyLaneCreeps(1000,true);
		for i=1,#nCreeps
		do
		    local creep = nCreeps[#nCreeps -i +1]
			if J.IsValid(creep)
			   and not creep:HasModifier("modifier_fountain_glyph")
			   and J.IsKeyWordUnit("ranged",creep)
			   and GetUnitToUnitDistance(bot,creep) >= 350
			then
				return BOT_ACTION_DESIRE_LOW, creep;
		    end
		end
	end
	
	if bot:GetActiveMode() == BOT_MODE_ROSHAN 
		and bot:GetMana() > 400
	then
		local target =  bot:GetAttackTarget();
		if target ~= nil 
			and not J.IsDisabled(true, target)
			and not target:IsDisarmed()
		then
			return BOT_ACTION_DESIRE_LOW, target;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
end

function X.ConsiderR()
	
	if not abilityR:IsFullyCastable() or bot:DistanceFromFountain() < 500 then return BOT_ACTION_DESIRE_NONE end

	local nNearbyAllyHeroes = J.GetAlliesNearLoc(bot:GetLocation(), 1200);
	local nNearbyEnemyHeroes  = bot:GetNearbyHeroes( 1600, true, BOT_MODE_NONE );
	local nNearbyEnemyTowers = bot:GetNearbyTowers(700,true);
	local nNearbyEnemyBarracks = bot:GetNearbyBarracks(400,true);
	local nNearbyAlliedCreeps = bot:GetNearbyLaneCreeps(1000,false);
	local nCastRange = abilityW:IsFullyCastable() and 780 or 650;
	
	-- if #nNearbyAllyHeroes + #nNearbyEnemyHeroes >= 3
	   -- and  #hEnemyHeroList - #nNearbyAllyHeroes <= 2
	   -- and  (#nNearbyEnemyHeroes >= 2 or (#hEnemyHeroList <= 1 and #nNearbyEnemyHeroes >= 1 ))
	-- then
	  	-- return BOT_ACTION_DESIRE_HIGH;
	-- end
	
	if J.IsGoingOnSomeone(bot) and #nNearbyAllyHeroes - #nNearbyEnemyHeroes <= 3
	then
		local hBotTarget = J.GetProperTarget(bot)		 
		if J.IsValidHero(hBotTarget)
		   and J.CanCastOnMagicImmune(hBotTarget)
		   and J.IsInRange(hBotTarget, bot,  nCastRange)
		then
			return BOT_ACTION_DESIRE_HIGH
		end
	end
	
	
	if J.IsPushing(bot) 
	   and DotaTime() > 6 * 30
	then
		if (#nNearbyEnemyTowers >= 1 or #nNearbyEnemyBarracks >= 1)
			and #nNearbyAlliedCreeps >= 2
		then
			return BOT_ACTION_DESIRE_HIGH;
		end
	end	
	
	
	if bot:GetActiveMode() == BOT_MODE_RETREAT
	   and nHP >= 0.5
	   and nNearbyEnemyHeroes[1] ~= nil
	   and GetUnitToUnitDistance(bot,nNearbyEnemyHeroes[1]) <= 400
	then
		return BOT_ACTION_DESIRE_HIGH;
	end
	
	return BOT_ACTION_DESIRE_NONE;
end


return X
-- dota2jmz@163.com QQ:2462331592。
