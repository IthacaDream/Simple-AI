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
						['t15'] = {10, 0},
						['t10'] = {10, 0},
}

local tAllAbilityBuildList = {
						{1,3,3,2,3,6,3,1,1,1,6,2,2,2,6},
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
				'item_priest_outfit',
				"item_mekansm",
				"item_urn_of_shadows",
				"item_glimmer_cape",
				"item_rod_of_atos",
				"item_guardian_greaves",
				"item_spirit_vessel",
				"item_shivas_guard",
				"item_sheepstick",
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

		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_storm") then
		
			if ( hMinionUnit:IsUsingAbility() ) then return end
			
			local abilityDM = hMinionUnit:GetAbilityByName( "brewmaster_storm_dispel_magic" );
			local abilityCY = hMinionUnit:GetAbilityByName( "brewmaster_storm_cyclone" );
			local abilityWW = hMinionUnit:GetAbilityByName( "brewmaster_storm_wind_walk" );
			local abilityCH = hMinionUnit:GetAbilityByName( "brewmaster_cinder_brew" );
			local CastDMDesire, DMLocation = ConsiderDM(abilityDM, hMinionUnit); 
			local CastCYDesire, CYTarget = ConsiderCY(abilityCY, hMinionUnit); 
			local castCHDesire, castCHTarget = ConsiderCorrosiveHaze(abilityCH, hMinionUnit);
			local CastWWDesire = ConsiderWW(abilityWW, hMinionUnit); 
			local AttackDesire, AttackTarget = ConsiderAttacking(hMinionUnit); 
			local MoveDesire, Location = ConsiderMove(hMinionUnit); 
			
			if ( CastDMDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbilityOnLocation( abilityDM, DMLocation );
				return;
			end
			
			if ( CastCYDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbilityOnEntity( abilityCY, CYTarget );
				return;
			end
			
			if ( castCHDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbilityOnLocation( abilityCH, castCHTarget:GetLocation() );
				return;
			end
			
			if ( CastWWDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbility( abilityWW );
				return;
			end
			
			if (AttackDesire > 0)
			then
				hMinionUnit:Action_AttackUnit( AttackTarget, true );
				return
			end
			
			if (MoveDesire > 0)
			then
				hMinionUnit:Action_MoveToLocation( Location );
				return
			end
			
		end
		
		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_earth") then
			
			if ( hMinionUnit:IsUsingAbility() ) then return end
			
			local abilityHB = hMinionUnit:GetAbilityByName( "brewmaster_earth_hurl_boulder" );
			local abilitySC = hMinionUnit:GetAbilityByName( "brewmaster_thunder_clap" );
			local castSCDesire = ConsiderSlithereenCrush(abilitySC, MinionUnit);
			local CastHBDesire, HBTarget = ConsiderHB(abilityHB, hMinionUnit); 
			local AttackDesire, AttackTarget = ConsiderAttacking(hMinionUnit); 
			local MoveDesire, Location = ConsiderMove(hMinionUnit); 
			local RetreatDesire, RetreatLocation = ConsiderRetreat(hMinionUnit); 
			
			if ( RetreatDesire > 0 ) 
			then
				hMinionUnit:Action_MoveToLocation( RetreatLocation );
				return;
			end
			if ( castSCDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbility( abilitySC );
				return;
			end
			if ( CastHBDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbilityOnEntity( abilityHB, HBTarget );
				return;
			end
			if (AttackDesire > 0)
			then
				hMinionUnit:Action_AttackUnit( AttackTarget, true );
				return
			end
			if (MoveDesire > 0)
			then	
				hMinionUnit:Action_MoveToLocation( Location );
				return
			end
			
		end
		
		if string.find(hMinionUnit:GetUnitName(), "npc_dota_brewmaster_fire") then
			
			local abilityDB = hMinionUnit:GetAbilityByName( "brewmaster_drunken_brawler" );
			local AttackDesire, AttackTarget = ConsiderAttacking(hMinionUnit); 
			local MoveDesire, Location = ConsiderMove(hMinionUnit); 
			local castDBDesire = ConsiderDrunkenBrawler(abilityDB, hMinionUnit);
			
			if ( castDBDesire > 0 ) 
			then
				hMinionUnit:Action_UseAbility( abilityDB );
				return;
			end
			if (AttackDesire > 0)
			then
				hMinionUnit:Action_AttackUnit( AttackTarget, true );
				return
			end
			if (MoveDesire > 0)
			then
				hMinionUnit:Action_MoveToLocation( Location );
				return
			end
			
		end
		
		Minion.IllusionThink(hMinionUnit)	
	end

end

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )

local castQDesire
local castWDesire, castWTarget
local castEDesire
local castRDesire

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
	
	
	castWDesire, castWTarget = X.ConsiderW();
	if ( castWDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, false)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget:GetLocation() )
		return;
	end

	castQDesire = X.ConsiderQ();
	if ( castQDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbility( abilityQ )
		
		return;
	end
	
	castEDesire = X.ConsiderE();
	if ( castEDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbility( abilityE )
		return;
	end

	castRDesire = X.ConsiderR();
	if ( castRDesire > 0 ) 
	then
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbility( abilityR )
		return;
	
	end
	

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nRadius = abilityTC:GetSpecialValueInt( "radius" );
	local nCastRange = 0;
	local nDamage = abilityTC:GetSpecialValueInt("damage");

	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nRadius, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy)  ) 
			then
				return BOT_ACTION_DESIRE_MODERATE;
			end
		end
	end
	
	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN  ) 
	then
		local npcTarget = bot:GetAttackTarget();
		if ( J.IsRoshan(npcTarget) and J.CanCastOnMagicImmune(npcTarget) and J.IsInRange(npcTarget, bot, nRadius)  )
		then
			return BOT_ACTION_DESIRE_LOW;
		end
	end
	
	-- If we're farming and can kill 3+ creeps with LSA
	if J.IsPushing(bot)
	then
		local tableNearbyEnemyCreeps = bot:GetNearbyLaneCreeps( nRadius, true );
		if ( tableNearbyEnemyCreeps ~= nil and #tableNearbyEnemyCreeps >= 4 and  bot:GetMana()/bot:GetMaxMana() > 0.6 ) then
			return BOT_ACTION_DESIRE_LOW;
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget) and J.IsInRange(npcTarget, bot, nRadius - 100)
		then
			return BOT_ACTION_DESIRE_VERYHIGH;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderW()


	if not abilityW:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nCastRange = abilityW:GetCastRange();

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange+200, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy)  ) 
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy;
			end
		end
	end

	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
			local npcTarget = bot:GetTarget();
			if ( J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget) and
			     J.IsInRange(npcTarget, bot, nCastRange+200) and not npcTarget:HasModifier("modifier_brewmaster_drunken_haze") )
			then
				return BOT_ACTION_DESIRE_HIGH, npcTarget;
			end
	end
	
	-- If we're going after someone
	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN  ) 
	then
		local npcTarget = bot:GetAttackTarget();
		if ( J.IsRoshan(npcTarget) and J.CanCastOnMagicImmune(npcTarget) and J.IsInRange(npcTarget, bot, nCastRange+200)  )
		then
			return BOT_ACTION_DESIRE_LOW, npcTarget;
		end
	end

	-- If we're in a teamfight, use it on the scariest enemy
	if J.IsInTeamFight(bot, 1200)
	then

		local npcMostDangerousEnemy = nil;
		local nMostDangerousDamage = 0;

		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if J.CanCastOnNonMagicImmune(npcEnemy) and not npcEnemy:HasModifier("modifier_brewmaster_drunken_haze") 
			then
				local nDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_ALL );
				if ( nDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = nDamage;
					npcMostDangerousEnemy = npcEnemy;
				end
			end
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy;
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0;
	
	
end

function X.ConsiderE()


	if not abilityE:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nRadius = 300;

	--------------------------------------
	-- Mode based usage
	--------------------------------------

	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nRadius, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) and J.CanCastOnNonMagicImmune(npcEnemy)  ) 
			then
				return BOT_ACTION_DESIRE_MODERATE;
			end
		end
	end
	
	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN  ) 
	then
		local npcTarget = bot:GetAttackTarget();
		if ( J.IsRoshan(npcTarget) and J.IsInRange(npcTarget, bot, nRadius)  )
		then
			return BOT_ACTION_DESIRE_LOW;
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.IsInRange(npcTarget, bot, nRadius)
		then
			return BOT_ACTION_DESIRE_VERYHIGH;
		end
	end

	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() then return 0 end
	
	local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_NONE );
	if #tableNearbyAllyHeroes == 0 then
		return BOT_ACTION_DESIRE_NONE;
	end
	
	local distance = 300;
	
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 800, true, BOT_MODE_NONE );
		local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
		if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 1 and tableNearbyAllyHeroes ~= nil and #tableNearbyAllyHeroes >= 2 then
			return BOT_ACTION_DESIRE_MODERATE;
		end
	end
	
	if J.IsInTeamFight(bot, 1200) and not abilityTC:IsFullyCastable()
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		if tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 3 
		then
			return BOT_ACTION_DESIRE_MODERATE;
		end
	end
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot) and not abilityTC:IsFullyCastable()
	then
		local npcTarget = bot:GetTarget();
		if J.IsValidHero(npcTarget) and J.IsInRange(npcTarget, bot, 400) 
		then
			local tableNearbyEnemyHeroes = npcTarget:GetNearbyHeroes( 1000, false, BOT_MODE_NONE );
			local tableNearbyAlly = bot:GetNearbyHeroes( 1200, false, BOT_MODE_ATTACK );
			if tableNearbyEnemyHeroes ~= nil and tableNearbyAlly ~= nil and #tableNearbyEnemyHeroes >= 2 and #tableNearbyAlly >= 2 then
				return BOT_ACTION_DESIRE_MODERATE;
			end
		end
	end

	return BOT_ACTION_DESIRE_NONE;
	
	
end

function ConsiderDM(abilityDM, hMinionUnit)

	if not abilityDM:IsFullyCastable() or abilityDM:IsHidden() then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	
	local nCastRange = abilityDM:GetCastRange();
	local nRadius = abilityDM:GetSpecialValueInt( "radius" );
	
	local Allies = hMinionUnit:GetNearbyHeroes( nCastRange + nRadius, false, BOT_MODE_NONE );
	for _,Ally in pairs( Allies )
	do
		if ( IsDisabled(Ally) ) 
		then
			return BOT_ACTION_DESIRE_LOW, Ally:GetLocation();
		end
	end
	
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
	if #tableNearbyEnemyHeroes == 1 and tableNearbyEnemyHeroes[1]:HasModifier("modifier_brewmaster_storm_cyclone") then
		return BOT_ACTION_DESIRE_LOW, tableNearbyEnemyHeroes[1]:GetLocation()
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end

function ConsiderCY(abilityCY, hMinionUnit)

	if not abilityCY:IsFullyCastable() or abilityCY:IsHidden() then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	
	local nCastRange = abilityCY:GetCastRange();
	
	-- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = hMinionUnit:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
	if ( #tableNearbyAttackingAlliedHeroes >= 1 ) 
	then

		local npcMostDangerousEnemy = nil;
		local nMostDangerousDamage = 0;

		local EnemyHeroes = hMinionUnit:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( EnemyHeroes )
		do
			if ( CanCastCYOnTarget( npcEnemy ) and not IsDisabled(npcEnemy) )
			then
				local nDamage = npcEnemy:GetEstimatedDamageToTarget( false, hMinionUnit, 3.0, DAMAGE_TYPE_ALL );
				if ( nDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = nDamage;
					npcMostDangerousEnemy = npcEnemy;
				end
			end
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_LOW, npcMostDangerousEnemy;
		end
	end
	
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( 2*nCastRange, true, BOT_MODE_NONE );
	
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( npcEnemy:IsChanneling() ) 
		then
			return BOT_ACTION_DESIRE_LOW, npcEnemy;
		end
	end
	
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( CanCastCYOnTarget( npcEnemy ) and not IsDisabled(npcEnemy) and npcEnemy:GetActiveMode() == BOT_MODE_RETREAT )
		then
			return BOT_ACTION_DESIRE_LOW, npcEnemy;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end

function ConsiderCorrosiveHaze(abilityCH, hMinionUnit)

	if not abilityCH:IsFullyCastable() or abilityCH:IsHidden() or not bot:HasScepter() then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	
	local nCastRange = abilityCH:GetCastRange();
	
	-- If we're in a teamfight, use it on the scariest enemy
	local tableNearbyAttackingAlliedHeroes = hMinionUnit:GetNearbyHeroes( 1000, false, BOT_MODE_ATTACK );
	if ( #tableNearbyAttackingAlliedHeroes >= 1 ) 
	then

		local npcMostDangerousEnemy = nil;
		local nMostDangerousDamage = 0;

		local EnemyHeroes = hMinionUnit:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( EnemyHeroes )
		do
			if ( CanCastCYOnTarget( npcEnemy ) )
			then
				local nDamage = npcEnemy:GetEstimatedDamageToTarget( false, hMinionUnit, 3.0, DAMAGE_TYPE_ALL );
				if ( nDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = nDamage;
					npcMostDangerousEnemy = npcEnemy;
				end
			end
		end

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_ACTION_DESIRE_LOW, npcMostDangerousEnemy;
		end
	end
	
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( nCastRange + 200, true, BOT_MODE_NONE );
	
	for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
	do
		if ( CanCastCYOnTarget( npcEnemy ) and npcEnemy:GetActiveMode() == BOT_MODE_RETREAT )
		then
			return BOT_ACTION_DESIRE_LOW, npcEnemy;
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end

function ConsiderWW(abilityWW, hMinionUnit)

	if not abilityWW:IsFullyCastable() or abilityWW:IsHidden() then
		return BOT_ACTION_DESIRE_NONE;
	end
	
	local tableNearbyEnemyCreeps = hMinionUnit:GetNearbyLaneCreeps( 1300, true );
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( 700, true, BOT_MODE_NONE );
	
	if ( #tableNearbyEnemyHeroes == 0 and #tableNearbyEnemyCreeps == 0 ) then
		return BOT_ACTION_DESIRE_HIGH;
	end
	
	return BOT_ACTION_DESIRE_NONE;

end

function ConsiderAttacking(hMinionUnit)
    local radius = 1600;
	local target = nil;
	
	if IsDisabled(hMinionUnit) then
		return BOT_ACTION_DESIRE_NONE, nil;
	end
	
	local units = hMinionUnit:GetNearbyHeroes(radius, true, BOT_MODE_NONE);
	
	if units == nil or #units == 0 then
		units = hMinionUnit:GetNearbyLaneCreeps(radius, true);
	end
	if units == nil or #units == 0 then
		units = hMinionUnit:GetNearbyTowers(radius, true);
	end
	if units == nil or #units == 0 then
		units = hMinionUnit:GetNearbyBarracks(radius, true);
	end
	
	if units ~= nil and #units > 0 then
		target = GetWeakestUnit(units);
		if target ~= nil then
			return BOT_ACTION_DESIRE_HIGH, target; 	
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, nil;
end

function ConsiderMove(hMinionUnit)
	local radius = 1000;
	local NearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( radius, true, BOT_MODE_NONE );
	local NearbyEnemyCreeps = hMinionUnit:GetNearbyLaneCreeps( radius, true );
	local NearbyEnemyTowers = hMinionUnit:GetNearbyTowers( radius, true );
	local NearbyEnemyBarracks = hMinionUnit:GetNearbyBarracks( radius, true );
	
	if #NearbyEnemyHeroes == 0 and #NearbyEnemyCreeps == 0 and #NearbyEnemyTowers == 0 and #NearbyEnemyBarracks == 0 then
		local ancient = GetAncient(GetOpposingTeam());
		if ancient ~= nil then
			return BOT_ACTION_DESIRE_HIGH, ancient:GetLocation();
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
end

function ConsiderSlithereenCrush(abilitySC, hMinionUnit)

	-- Make sure it's castable
	if ( not abilitySC:IsFullyCastable() or abilitySC:IsHidden() or not bot:HasScepter() ) then 
		return BOT_ACTION_DESIRE_NONE;
	end

	-- Get some of its values
	local nRadius = abilitySC:GetSpecialValueInt( "radius" );
	local nCastRange = 0;
	local nDamage = abilitySC:GetSpecialValueInt("damage");

	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( nRadius-150, true, BOT_MODE_NONE );
	
	if ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 1 ) then
		return BOT_ACTION_DESIRE_HIGH;
	end

	return BOT_ACTION_DESIRE_NONE;

end

function ConsiderHB(abilityHB, hMinionUnit)

	if not abilityHB:IsFullyCastable() or abilityHB:IsHidden() then
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	
	local nCastRange = abilityHB:GetCastRange();
	
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( 1200, true, BOT_MODE_NONE );
	
	local target = GetWeakestUnit(tableNearbyEnemyHeroes);
	
	if target ~= nil then
		return BOT_ACTION_DESIRE_HIGH, target;
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end

function GetWeakestUnit(tableNearbyEntity)	
	local target = nil;
	local minHP = 100000;
	for _,unit in pairs(tableNearbyEntity)
	do
		local HP = unit:GetHealth();
		if not unit:IsInvulnerable() and HP < minHP then
			target = unit;
			minHP = HP;
		end
	end
	return target;
end

function ConsiderRetreat(hMinionUnit)
	local tableNearbyAllyHeroes = hMinionUnit:GetNearbyHeroes( 1200, false, BOT_MODE_NONE );
	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( 1200, true, BOT_MODE_NONE );
	if #tableNearbyAllyHeroes == 0 and #tableNearbyEnemyHeroes >= 2 then
		local location = GetFountain(false)
		return BOT_ACTION_DESIRE_LOW, location;
	end
	return BOT_ACTION_DESIRE_NONE, 0;
end

function GetFountain(enemy)
	local RB = Vector(-7200,-6666)
	local DB = Vector(7137,6548)

	if enemy then
		if GetTeam( ) == TEAM_DIRE then
			return RB;
		else
			return DB;
		end
	else
		if GetTeam( ) == TEAM_DIRE then
			return DB;
		else
			return RB;
		end
	end
end

function ConsiderDrunkenBrawler(abilityDB, hMinionUnit)

	-- Make sure it's castable
	if ( not abilityDB:IsFullyCastable() or abilityDB:IsHidden() or not bot:HasScepter() ) then 
		return BOT_ACTION_DESIRE_NONE;
	end

	-- Get some of its values
	local nRange = hMinionUnit:GetAttackRange();

	local tableNearbyEnemyHeroes = hMinionUnit:GetNearbyHeroes( nRange+200, true, BOT_MODE_NONE );
	
	if ( tableNearbyEnemyHeroes ~= nil and #tableNearbyEnemyHeroes >= 1 ) then
		return BOT_ACTION_DESIRE_HIGH;
	end

	return BOT_ACTION_DESIRE_NONE;

end

return X
-- dota2jmz@163.com QQ:2462331592。




