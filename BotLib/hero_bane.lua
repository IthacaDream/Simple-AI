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
						['t20'] = {10, 0},
						['t15'] = {0, 10},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
	{2,3,2,3,2,6,2,3,3,1,6,1,1,1,6},
	{3,2,2,1,1,6,2,2,1,1,6,3,3,3,6}
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
	"item_tango",
    "item_flask",
    "item_magic_stick",
    "item_double_branches",
	"item_magic_wand",
	"item_arcane_boots",
	"item_aether_lens",
	"item_force_staff",
	"item_glimmer_cape",
	"item_black_king_bar",
	"item_ultimate_scepter_2",
	"item_sheepstick",
	"item_hurricane_pike"
}

X['sSellList'] = {
	"item_shivas_guard",
	"item_magic_wand",
}

if J.Role.IsPvNMode() then X['sBuyList'],X['sSellList'] = { 'PvN_priest' }, {} end

X['sApplicableNeutralList'] = {
}

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'],X['sApplicableNeutralList'] = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'],X['sApplicableNeutralList']);

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
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityD = bot:GetAbilityByName( sAbilityList[4] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castETarget
local castDDesire
local castRDesire, castRTarget

local nKeepMana,nMP,nHP,nLV,hEnemyList,hAllyList,botTarget,sMotive;
local aetherRange = 0
local nmCastTime = 0

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

	local glimmer = J.IsItemAvailable('item_glimmer_cape')
	
	castRDesire, castRTarget = X.ConsiderR();
	if ( castRDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
		
		if glimmer ~= nil and glimmer:IsFullyCastable() then
			bot:ActionQueue_UseAbilityOnEntity( glimmer, bot );
		end

		bot:ActionQueue_UseAbilityOnEntity( abilityR, castRTarget )
		return;
	
	end
	
	castEDesire, castETarget = X.ConsiderE();
	if ( castEDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)

	    nmCastTime = DotaTime();
		bot:ActionQueue_UseAbilityOnEntity( abilityE, castETarget )
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

	castDDesire = X.ConsiderD();
	if ( castDDesire > 0 ) 
	then
		bot:ActionQueue_UseAbility( abilityD );
		return;
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastRange   = abilityQ:GetCastRange( );
	local nCastPoint   = abilityQ:GetCastPoint( );
	local nManaCost    = abilityQ:GetManaCost( );
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange+200, true, BOT_MODE_NONE );
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy) ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end

	if J.IsInTeamFight(bot, 1200)
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( npcEnemy:IsHero() and J.Role.IsCarry(npcEnemy:GetUnitName()) and J.CanCastOnMagicImmune(npcEnemy) 
			     and not X.StillHasModifier(npcEnemy, 'modifier_bane_enfeeble') ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end
	
	if J.IsAllowedToSpam(bot, nManaCost) 
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( npcEnemy:IsHero() and J.CanCastOnNonMagicImmune(npcEnemy) and J.Role.IsCarry(npcEnemy:GetUnitName())
			     and not X.StillHasModifier(npcEnemy, 'modifier_bane_enfeeble') ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end	
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.Role.IsCarry(npcTarget:GetUnitName()) and J.CanCastOnNonMagicImmune(npcTarget) 
		   and J.IsInRange(npcTarget, bot, nCastRange + 200) and not X.StillHasModifier(npcTarget, 'modifier_bane_enfeeble')  
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastRange   = abilityW:GetCastRange();
	local nDamage      = abilityW:GetSpecialValueInt('brain_sap_damage');
	local nCastPoint   = abilityW:GetCastPoint( );
	local nManaCost    = abilityW:GetManaCost( );
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange+200, true, BOT_MODE_NONE );
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy) ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end

	if J.IsInTeamFight(bot, 1200) and bot:GetMaxHealth() - bot:GetHealth() > nDamage 
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( J.CanCastOnMagicImmune(npcEnemy) and J.CanKillTarget(npcEnemy, nDamage, DAMAGE_TYPE_PURE ) ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot) and bot:GetMaxHealth() - bot:GetHealth() > nDamage
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget)and J.IsInRange(npcTarget, bot, nCastRange + 200)
		then
			return BOT_ACTION_DESIRE_HIGH, npcTarget;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() or abilityE:IsHidden() then return 0 end
	
	-- Get some of its values
	local nCastRange   = abilityE:GetCastRange();
	local nDamage      = abilityE:GetSpecialValueFloat('duration')*abilityE:GetAbilityDamage();
	local nCastPoint   = abilityE:GetCastPoint( );
	local nManaCost    = abilityE:GetManaCost( );
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange+200, true, BOT_MODE_NONE );
	
	if J.IsProjectileIncoming(bot, 300)
	then
		return BOT_ACTION_DESIRE_HIGH, bot;
	end
	
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( npcEnemy:IsChanneling() and J.CanCastOnNonMagicImmune(npcEnemy) ) 
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy;
		end
	end	
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		if bot:GetHealth() < nDamage then
			return BOT_ACTION_DESIRE_HIGH, bot;
		end
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy) and not J.IsDisabled(true, npcEnemy) ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end

	if J.IsInTeamFight(bot, 1200)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and #tableNearbyEnemyHeroes == 2 
		then
			for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
			do
				if ( npcEnemy ~= npcTarget and J.CanCastOnMagicImmune(npcEnemy) and not J.IsDisabled(true, npcEnemy) ) 
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy;
				end
			end
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget)and J.IsInRange(npcTarget, bot, nCastRange + 200) and not J.IsDisabled(true, npcTarget)
		then
			local allies = npcTarget:GetNearbyHeroes( nCastRange-200, true, BOT_MODE_NONE );
			local enemies = npcTarget:GetNearbyHeroes( nCastRange-200, false, BOT_MODE_NONE );
			if ( allies == nil or #allies == 1 ) and #enemies == 1 
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastRange   = abilityR:GetCastRange();
	local nDamage      = abilityR:GetSpecialValueFloat('fiend_grip_duration')*abilityE:GetSpecialValueInt('fiend_grip_damage');
	local nCastPoint   = abilityR:GetCastPoint( );
	local nManaCost    = abilityR:GetManaCost( );
	
	if bot:HasScepter() then
	
		nDamage = abilityR:GetSpecialValueFloat('fiend_grip_duration_scepter')*abilityR:GetSpecialValueInt('fiend_grip_damage_scepter');
		
	end	
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange+200, true, BOT_MODE_NONE );
	
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( npcEnemy:IsChanneling() and J.CanCastOnMagicImmune(npcEnemy) ) 
		then
			return BOT_ACTION_DESIRE_HIGH, npcEnemy;
		end
	end
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot) and tableNearbyEnemyHeroes[1] ~=nil 
	then
		local tableNearbyAllyHeroes = tableNearbyEnemyHeroes[1]:GetNearbyHeroes( nCastRange-200, true, BOT_MODE_NONE );
		if tableNearbyAllyHeroes ~= nil and #tableNearbyAllyHeroes >= 2  
		then
			return BOT_ACTION_DESIRE_HIGH,  tableNearbyEnemyHeroes[1];
		end
	end

	if J.IsInTeamFight(bot, 1200)
	then
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( npcEnemy:IsHero() and J.Role.IsCarry(npcEnemy:GetUnitName()) and J.CanCastOnMagicImmune(npcEnemy) and not J.IsDisabled(true, npcEnemy) ) 
			then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy;
			end
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget)and J.IsInRange(npcTarget, bot, nCastRange + 200) and not J.IsDisabled(true, npcTarget)
		then
			local allies = npcTarget:GetNearbyHeroes( nCastRange-200, true, BOT_MODE_NONE );
			if ( allies ~= nil and #allies >= 2 )
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.ConsiderD()

	if not abilityD:IsFullyCastable() or abilityD:IsHidden() or DotaTime() < nmCastTime + 1.5 then return 0 end
	
	local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 1200, false, BOT_MODE_NONE );
	for _,npcAlly in pairs( tableNearbyAllyHeroes )
	do
		if ( X.StillHasModifier(npcAlly, 'modifier_bane_nightmare') ) 
		then
			return BOT_ACTION_DESIRE_HIGH;
		end
	end
	
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.IsInRange(npcTarget, bot, 1000) and X.StillHasModifier(npcTarget, 'modifier_bane_nightmare')
		then
			local allies = npcTarget:GetNearbyHeroes( 600, true, BOT_MODE_NONE );
			local enemies = npcTarget:GetNearbyHeroes( 800, false, BOT_MODE_NONE );
			if ( #allies >= 2 and #enemies == 1 ) 
			then
				return BOT_ACTION_DESIRE_HIGH;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.StillHasModifier(npcTarget, modifier)
	return npcTarget:HasModifier(modifier);
end

return X
-- dota2jmz@163.com QQ:2462331592。




