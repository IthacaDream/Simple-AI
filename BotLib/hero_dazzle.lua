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
local sOutfit = J.Skill.GetOutfitName(bot)

local tTalentTreeList = {
						['t25'] = {10, 0},
						['t20'] = {10, 0},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,3,1,3,2,6,1,1,3,3,6,2,2,2,6},
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
				'item_priest_outfit',
				--'item_blight_stone',
				"item_urn_of_shadows",
				"item_mekansm",
				"item_hand_of_midas",
				--"item_medallion_of_courage",
				"item_glimmer_cape",
				"item_guardian_greaves",
				"item_spirit_vessel",
				--"item_solar_crest",
				"item_rod_of_atos",
				'item_necronomicon_3',
				"item_shivas_guard",

}

X['sSellList'] = {

	"item_guardian_greaves",
	"item_magic_wand",
	
	"item_shivas_guard",
	"item_hand_of_midas",

}

if J.Role.IsPvNMode() or J.Role.IsAllShadow() then X['sBuyList'],X['sSellList'] = { 'PvN_priest' }, {} end

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

npc_dota_hero_dazzle

"Ability1"		"dazzle_poison_touch"
"Ability2"		"dazzle_shallow_grave"
"Ability3"		"dazzle_shadow_wave"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"dazzle_bad_juju"
"Ability10"		"special_bonus_attack_damage_75"
"Ability11"		"special_bonus_hp_200"
"Ability12"		"special_bonus_cast_range_125"
"Ability13"		"special_bonus_unique_dazzle_2"
"Ability14"		"special_bonus_movement_speed_40"
"Ability15"		"special_bonus_unique_dazzle_3"
"Ability16"		"special_bonus_unique_dazzle_1"
"Ability17"		"special_bonus_unique_dazzle_4"

modifier_dazzle_poison_touch
modifier_dazzle_shallow_grave
modifier_dazzle_weave_armor
modifier_dazzle_bad_juju
modifier_dazzle_bad_juju_armor

--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent3 = bot:GetAbilityByName( sTalentList[3] )
local talent4 = bot:GetAbilityByName( sTalentList[4] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castRDesire

local nKeepMana,nMP,nHP,nLV,hEnemyList,hAllyList,botTarget,sMotive;
local aetherRange = 0
local talent4Damage = 0

function X.SkillsComplement()

	if J.CanNotUseAbility(bot) or bot:IsInvisible() then return end
	
	nKeepMana = 400
	aetherRange = 0
	talent4Damage = 0
	nLV = bot:GetLevel();
	nMP = bot:GetMana()/bot:GetMaxMana();
	nHP = bot:GetHealth()/bot:GetMaxHealth();
	botTarget = J.GetProperTarget(bot);
	hEnemyList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	hAllyList = J.GetAlliesNearLoc(bot:GetLocation(), 1600);

	local aether = J.IsItemAvailable("item_aether_lens");
	if aether ~= nil then aetherRange = 250 end	
	if talent3:IsTrained() then aetherRange = aetherRange + talent3:GetSpecialValueInt("value") end
	if talent4:IsTrained() then talent4Damage = talent4:GetSpecialValueInt("value") end
	

	castQDesire, castQTarget, sMotive = X.ConsiderQ();
	if ( castQDesire > 0 ) 
	then
		J.SetReportMotive(bDebugMode,sMotive);		
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return;
	end
	
	castWDesire, castWTarget, sMotive = X.ConsiderW();
	if ( castWDesire > 0 ) 
	then
		J.SetReportMotive(bDebugMode,sMotive);
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return;
	end
	
	castEDesire, castETarget, sMotive = X.ConsiderE();
	if ( castEDesire > 0 ) 
	then
		J.SetReportMotive(bDebugMode,sMotive);
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
		return;
	end
	
end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityQ:GetLevel()
	local nCastRange  = abilityQ:GetCastRange() + aetherRange
	local nCastPoint  = abilityQ:GetCastPoint()
	local nManaCost   = abilityQ:GetManaCost()
	local nDamage     = abilityQ:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE);
	local nInBonusEnemyList = bot:GetNearbyHeroes(nCastRange + 200,true,BOT_MODE_NONE);
	local nCastTarget = nil
	
	
	--TeamFight
	if J.IsInTeamFight(bot, 1200)
	then
		local npcWeakestEnemy = nil;
		local npcWeakestEnemyHealth = 10000;		
		
		for _,npcEnemy in pairs( nInRangeEnemyList )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastOnNonMagicImmune(npcEnemy) 
			then
				local npcEnemyHealth = npcEnemy:GetHealth();
				if ( npcEnemyHealth < npcWeakestEnemyHealth )
				then
					npcWeakestEnemyHealth = npcEnemyHealth;
					npcWeakestEnemy = npcEnemy;
				end
			end
		end
		
		if ( npcWeakestEnemy ~= nil )
		then
			nCastTarget = npcWeakestEnemy;
			return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-TeamFight'..J.Chat.GetNormName(nCastTarget)
		end		
	end
	
	
	--Attack
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget) 
			and J.CanCastOnNonMagicImmune(botTarget) 
			and J.IsInRange(botTarget, bot, nCastRange +50) 
		then
			if nSkillLV >= 2 or nMP > 0.68 or J.GetHPR(botTarget) < 0.43 or nHP <= 0.4
			then
				nCastTarget = botTarget
				return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-Attack:'..J.Chat.GetNormName(nCastTarget)
			end
		end
	end
	
	--Retreat
	if J.IsRetreating(bot) 
	then
		for _,npcEnemy in pairs( nInRangeEnemyList )
		do
			if J.IsValid(npcEnemy)
			   and bot:WasRecentlyDamagedByHero( npcEnemy, 5.0 ) 
			   and J.CanCastOnNonMagicImmune(npcEnemy) 
			then
				nCastTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-Retreat:'..J.Chat.GetNormName(nCastTarget)
			end
		end
	end
	
	--Farm
	if  J.IsFarming(bot) 
		and nSkillLV >= 3
		and #hAllyList <= 1
		and J.IsAllowedToSpam(bot, nManaCost *0.25)
	then
		local nCreeps = bot:GetNearbyNeutralCreeps(nCastRange + 200);
		
		local targetCreep = J.GetMostHpUnit(nCreeps);
		
		if J.IsValid(targetCreep)
			and not J.IsRoshan(targetCreep)
			and #nCreeps >= 3
			and bot:IsFacingLocation(targetCreep:GetLocation(),40)
			and (targetCreep:GetMagicResist() < 0.3 or nMP > 0.9)
			and not J.CanKillTarget(targetCreep,bot:GetAttackDamage() *1.88,DAMAGE_TYPE_PHYSICAL)
		then
			nCastTarget = targetCreep
			return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-Farm'
	    end
	end
		
	
	--Push
	if  (J.IsPushing(bot) or J.IsDefending(bot) or J.IsFarming(bot))
	    and J.IsAllowedToSpam(bot, nManaCost )
		and nSkillLV >= 3 and DotaTime() > 6 * 60
		and #hAllyList <= 2 and #hEnemyList == 0
	then
		local nLaneCreeps = bot:GetNearbyLaneCreeps(nCastRange + 300,true);
		local targetCreep = nLaneCreeps[1]
		
		if #nLaneCreeps >= 4
			and J.IsValid(targetCreep)
			and not targetCreep:HasModifier("modifier_fountain_glyph")
			and not J.CanKillTarget(targetCreep,bot:GetAttackDamage() *1.88,DAMAGE_TYPE_PHYSICAL)
		then
			nCastTarget = targetCreep
			return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-Farm'
	    end
	end
	
	
	--roshan
	if bot:GetActiveMode() == BOT_MODE_ROSHAN 
		and bot:GetMana() >= 400
	then
		if  J.IsRoshan(botTarget) 
			and J.IsInRange(botTarget, bot, nCastRange)  
		then
			nCastTarget = botTarget
			return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-roshan'
		end
	end
	
	
	--Normal
	if (#hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero(3.0)) 
		and ( bot:GetActiveMode() ~= BOT_MODE_RETREAT or #hAllyList >= 2 )
		and #nInRangeEnemyList >= 1
		and nSkillLV >= 4
	then
		for _,npcEnemy in pairs( nInRangeEnemyList )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastOnNonMagicImmune(npcEnemy) 		
			then
				nCastTarget = npcEnemy
				return BOT_ACTION_DESIRE_HIGH, nCastTarget,'Q-Normal:'..J.Chat.GetNormName(nCastTarget)
			end
		end
	end
	
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityW:GetLevel(); 
	local nCastRange  = abilityW:GetCastRange() + aetherRange
	local nCastPoint  = abilityW:GetCastPoint()
	local nManaCost   = abilityW:GetManaCost()
	local nDamage     = abilityW:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE)
	
	for _,npcAlly in pairs(hAllyList)
	do
		if	J.IsValidHero(npcAlly)
			and not npcAlly:HasModifier('modifier_dazzle_shallow_grave')
			and J.GetHPR(npcAlly) < 0.23
		then
			--掩护撤退
			if J.IsRetreating(npcAlly)
				and npcAlly:WasRecentlyDamagedByAnyHero(3.0)
			then
				return BOT_ACTION_DESIRE_HIGH, npcAlly
			end
			
			--掩护输出
			
		end		
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityE:GetLevel()
	local nCastRange  = abilityE:GetCastRange()
	local nCastPoint  = abilityE:GetCastPoint()
	local nManaCost   = abilityE:GetManaCost()
	local nDamage     = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nInRangeEnemyList = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE);
	local nInBonusEnemyList = bot:GetNearbyHeroes(nCastRange + 200,true,BOT_MODE_NONE);
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

return X
-- dota2jmz@163.com QQ:2462331592。