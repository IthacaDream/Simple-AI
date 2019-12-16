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


local tTalentTreeList = {
						['t25'] = {0, 10},
						['t20'] = {0, 10},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
	{3,2,1,1,1,6,1,3,3,3,6,2,2,2,6},
	{3,2,2,1,2,6,2,1,1,1,6,3,3,3,6}
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
	"item_tango",
    "item_flask",
    "item_magic_stick",
    "item_double_branches",
	"item_magic_wand",
	"item_phase_boots",
	"item_medallion_of_courage",
	"item_desolator",
	"item_solar_crest",
	"item_orchid",
	"item_black_king_bar",
	"item_bloodthorn",
	"item_dagon_5",
	"item_ultimate_scepter_2"
}

X['sSellList'] = {
	"item_shivas_guard",
	"item_magic_wand",
}

if J.Role.IsPvNMode() then X['sBuyList'],X['sSellList'] = { 'PvN_priest' }, {} end

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

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )

local castQDesire, castQTarget
local castEDesire
local castRDesire, castRTarget

local nKeepMana,nMP,nHP,nLV,hEnemyList,hAllyList,botTarget,sMotive;
local aetherRange = 0

function X.SkillsComplement()
	
	if J.CanNotUseAbility(bot) or bot:IsInvisible() then return end
	
	nKeepMana = 400
	aetherRange = 0
	nLV = bot:GetLevel();
	nMP = bot:GetMana()/bot:GetMaxMana();
	nHP = bot:GetHealth()/bot:GetMaxHealth();
	botTarget = J.GetProperTarget(bot);
	hEnemyList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	hAllyList = J.GetAlliesNearLoc(bot:GetLocation(), 1600);
	
	
	local aether = J.IsItemAvailable("item_aether_lens");
	if aether ~= nil then aetherRange = 250 end	
	
	castRDesire, castRTarget = X.ConsiderR();
	if ( castRDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return;
	
	end
	
	castQDesire, castQTarget = X.ConsiderQ();
	if ( castQDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		
		return;
	end
	
	castEDesire = X.ConsiderE();
	if ( castEDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbility( abilityE )
		return;
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nRadius    = abilityQ:GetSpecialValueInt( "bounce_aoe" );
	local nCastRange = abilityQ:GetCastRange( );
	local nCastPoint = abilityQ:GetCastPoint( );
	local nManaCost  = abilityQ:GetManaCost( );
	local nDamage    = abilityQ:GetSpecialValueInt( 'bonus_damage' );
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nRadius, true, BOT_MODE_NONE );
	local tableNearbyCreeps = bot:GetNearbyLaneCreeps( nCastRange + 200, true );
	
	--if we can kill any enemies
	for _,npcEnemy in pairs(tableNearbyEnemyHeroes)
	do
		if npcEnemy:IsChanneling() then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy;
		end
		if J.CanCastOnNonMagicImmune(npcEnemy) and J.CanKillTarget(npcEnemy, nDamage, DAMAGE_TYPE_MAGICAL) 
		then
			if J.IsInRange(npcEnemy, bot, nCastRange + 200) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			elseif tableNearbyCreeps[1] ~= nil and X.StillHasModifier(npcEnemy, 'modifier_bounty_hunter_track') 
				and J.IsInRange(npcEnemy, bot, nRadius - 200)
			then	
				return BOT_ACTION_DESIRE_HIGH, tableNearbyCreeps[1] ;
			end
		end
	end

	if J.IsInTeamFight(bot, 1200)
	then
		local trackedEnemy = 0;
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( X.StillHasModifier(npcEnemy, 'modifier_bounty_hunter_track')  ) 
			then
				trackedEnemy = trackedEnemy + 1;
			end
		end
		if trackedEnemy >= 2 then
			if tableNearbyCreeps[1] ~= nil then
				return BOT_ACTION_DESIRE_HIGH, tableNearbyCreeps[1];
			elseif J.IsInRange(tableNearbyEnemyHeroes[1], bot, nCastRange + 200) 
			then
				return BOT_ACTION_DESIRE_HIGH, tableNearbyEnemyHeroes[1];
			end
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget) 
		then
			if J.IsInRange(npcEnemy, bot, nCastRange + 200) then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			elseif tableNearbyCreeps[1] ~= nil and X.StillHasModifier(npcEnemy, 'modifier_bounty_hunter_track') 
				and J.IsInRange(npcEnemy, bot, nRadius - 200)
			then	
				return BOT_ACTION_DESIRE_HIGH, tableNearbyCreeps[1] ;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastPoint = abilityQ:GetCastPoint( );
	local nManaCost  = abilityQ:GetManaCost( );

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		if ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 1 ) 
		then
			return BOT_ACTION_DESIRE_MODERATE;
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and not J.IsInRange(npcTarget, bot, 300) and J.IsInRange(npcTarget, bot, 2000)
		then
			return BOT_ACTION_DESIRE_MODERATE;
		end
	end

	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastRange = abilityR:GetCastRange( );
	local nCastPoint = abilityR:GetCastPoint( );
	local nManaCost  = abilityR:GetManaCost( );
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE );
	
	--if we can kill any enemies
	for _,npcEnemy in pairs(tableNearbyEnemyHeroes)
	do
		if J.CanCastOnNonMagicImmune(npcEnemy) and not X.StillHasModifier(npcEnemy, 'modifier_bounty_hunter_track') 
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.StillHasModifier(npcTarget, modifier)
	return npcTarget:HasModifier(modifier);
end

return X
-- dota2jmz@163.com QQ:2462331592。




