local X = {}
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
                        {1,3,2,2,2,6,2,3,3,3,6,1,1,1,6},
                        {1,3,1,2,1,6,1,2,2,2,6,3,3,3,6},
                        {1,3,1,2,1,6,1,3,3,3,6,2,2,2,6}
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
				"item_tango",
				"item_clarity",
				"item_clarity",
				"item_enchanted_mango",
				"item_enchanted_mango",
				"item_arcane_boots",
				"item_glimmer_cape",
				"item_cyclone",
				"item_aether_lens",
				"item_ultimate_scepter",
				"item_spirit_vessel",
				"item_sheepstick",
}

X['sSellList'] = {
	"item_crimson_guard",
	"item_quelling_blade",
}

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = J.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

X['bDeafaultAbility'] = true
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
	then
		if hMinionUnit:IsIllusion() 
		then 
			Minion.IllusionThink(hMinionUnit)	
		end
	end

end

local abilityQ = bot:GetAbilityByName( sAbilityList[1] );
local abilityW = bot:GetAbilityByName( sAbilityList[2] );
local abilityE = bot:GetAbilityByName( sAbilityList[3] );
local abilityR = bot:GetAbilityByName( sAbilityList[6] );


local castCombo1Desire = 0;
local castCombo2Desire = 0;
local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire, castELocation
local castRDesire, castRLocation

local nKeepMana,nMP,nHP,nLV,hEnemyHeroList;
local aetherRange = 0

local hEnemyOnceLocation = {}

for _,TeamPlayer in pairs( GetTeamPlayers(GetOpposingTeam()) )
do
    hEnemyOnceLocation[TeamPlayer] = nil;
end

local hEnemyRecordLocation = {}

function X.SkillsComplement()
	
	
	if J.CanNotUseAbility(bot) or bot:IsInvisible() then return end
	--暂时取消位置记录
	--RecordTheLocation();
	
	nKeepMana = 400; 
	aetherRange = 0
	nLV = bot:GetLevel();
	nMP = bot:GetMana()/bot:GetMaxMana();
	nHP = bot:GetHealth()/bot:GetMaxHealth();
	hEnemyHeroList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	

	local aether = J.IsItemAvailable("item_aether_lens");
	if aether ~= nil then aetherRange = 250 end	
	
	
	castWDesire, castWTarget = X.ConsiderW()
	if ( castWDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityW, castWTarget )
		return;
	end
	
	
	castRDesire, castRLocation = X.ConsiderR()
	if ( castRDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnLocation( abilityR, castRLocation )
		return;
	end

	
	castQDesire, castQTarget = X.ConsiderQ()
	if ( castQDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnEntity( abilityQ, castQTarget )
		return;
	end
	
	castEDesire, castELocation = X.ConsiderE()
	if ( castEDesire > 0 ) 
	then
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnLocation( abilityE, castELocation )
		return;
	end
	

end

function X.ConsiderQ()

	if not abilityQ:IsFullyCastable() then return 0 end

    local nRadius = 300
	local castRange = abilityQ:GetCastRange() + aetherRange 
	local target  = J.GetProperTarget(bot);
    local aTarget = bot:GetAttackTarget(); 
	local enemies = bot:GetNearbyHeroes(castRange, true, BOT_MODE_NONE);
	
	if J.IsInTeamFight(bot, 1200)
	then
		local npcMostAoeEnemy = nil;
		local nMostAoeECount  = 1;
		local nEnemysHerosInRange = bot:GetNearbyHeroes(castRange + 43,true,BOT_MODE_NONE);
		local nEmemysCreepsInRange = bot:GetNearbyCreeps(castRange + 43,true);
		local nAllEnemyUnits = J.CombineTwoTable(nEnemysHerosInRange,nEmemysCreepsInRange);
		
		local npcMostDangerousEnemy = nil;
		local nMostDangerousDamage = 0;		
		
		for _,npcEnemy in pairs( nAllEnemyUnits )
		do
			if  J.IsValid(npcEnemy)
			    and J.CanCastOnNonMagicImmune(npcEnemy) 
			then
				
				local nEnemyHeroCount = J.GetAroundTargetEnemyHeroCount(npcEnemy, nRadius);
				if ( nEnemyHeroCount > nMostAoeECount )
				then
					nMostAoeECount = nEnemyHeroCount;
					npcMostAoeEnemy = npcEnemy;
				end
				
				if npcEnemy:IsHero()
				then
					local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_MAGICAL );
					if ( npcEnemyDamage > nMostDangerousDamage )
					then
						nMostDangerousDamage = npcEnemyDamage;
						npcMostDangerousEnemy = npcEnemy;
					end
				end
			end
		end
		
		if ( npcMostAoeEnemy ~= nil )
		then
			return BOT_MODE_DESIRE_MODERATE, npcMostAoeEnemy;
		end	

		if ( npcMostDangerousEnemy ~= nil )
		then
			return BOT_MODE_DESIRE_MODERATE, npcMostDangerousEnemy;
		end	
	end

	--对线期间对敌方英雄使用
	if bot:GetActiveMode() == BOT_MODE_LANING
	then
		for _,npcEnemy in pairs( enemies )
		do
			if  J.IsValid(npcEnemy)
				and J.CanCastOnNonMagicImmune(npcEnemy) 
				and not J.IsDisabled(true, npcEnemy)
			then
				local enemyCount = J.GetAroundTargetEnemyUnitCount(npcEnemy, 600)
				if enemyCount ~= nil
				   and enemyCount >= 4
				then
					return BOT_ACTION_DESIRE_HIGH, npcEnemy;
				end
			end
		end
	end
	
	if ( J.IsPushing(bot) or J.IsDefending(bot) ) 
	then
		local creeps = bot:GetNearbyLaneCreeps(castRange, true);
		if #creeps >= 4 and creeps[1] ~= nil
		then
			return BOT_MODE_DESIRE_MODERATE, creeps[1];
		end
	end

	
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(target) 
		   and J.CanCastOnNonMagicImmune(target) 
		   and J.IsInRange(target, bot, castRange) 
		then
			return BOT_ACTION_DESIRE_HIGH, target;
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE
	
end

function X.ConsiderW()

	if not abilityW:IsFullyCastable() then return 0 end

	local nCastRange = abilityW:GetCastRange() + aetherRange;

	if nCastRange > 1600 then nCastRange = 1600 end
	local gEnemies = GetUnitList(UNIT_LIST_ENEMY_HEROES);

	local npcMostDangerousEnemy = nil;
	local nMostDangerousDamage = 0;	

	for _,npcEnemy in pairs( gEnemies )
	do
		if  J.IsValid(npcEnemy)
			and J.IsInRange(npcEnemy, bot, nCastRange)
			and J.CanCastOnNonMagicImmune(npcEnemy)
			and not J.IsAllyCanKill(npcEnemy)
		then

			if npcEnemy:IsHero()
			then
				local npcEnemyDamage = npcEnemy:GetEstimatedDamageToTarget( false, bot, 3.0, DAMAGE_TYPE_PHYSICAL );
				if ( npcEnemyDamage > nMostDangerousDamage )
				then
					nMostDangerousDamage = npcEnemyDamage;
					npcMostDangerousEnemy = npcEnemy;
				end
			end

		end
	end

	if ( npcMostDangerousEnemy ~= nil )
	then
		return BOT_ACTION_DESIRE_HIGH, npcMostDangerousEnemy;
	end	


	return BOT_ACTION_DESIRE_NONE, 0

end


function X.ConsiderE()

	if not abilityE:IsFullyCastable() then return BOT_ACTION_DESIRE_NONE, 0; end

    local nCastRange = abilityE:GetCastRange() + aetherRange;
    local nCastPoint = abilityE:GetCastPoint();
    local nDelay	 = abilityE:GetSpecialValueFloat( 'delay' );
    local nManaCost  = abilityE:GetManaCost();
	local nRadius = 340

    local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
	local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 800, false, BOT_MODE_NONE );
	
	--有把握在困住后击杀
	for _,npcEnemy in pairs(tableNearbyEnemyHeroes)
	do
		if  J.IsValid(npcEnemy) and J.CanCastOnNonMagicImmune(npcEnemy) and J.IsOtherAllyCanKillTarget(bot, npcEnemy)
		then
			if  npcEnemy:GetMovementDirectionStability() >= 0.75 then
				return BOT_ACTION_DESIRE_HIGH, npcEnemy:GetExtrapolatedLocation(nDelay);
			else
				return BOT_MODE_DESIRE_MODERATE, J.GetDelayCastLocation(bot,npcEnemy,nCastRange,nRadius,1.45);
			end
		end
	end
	
	-- 撤退时尝试留住敌人
	for _,npcAlly in pairs(tableNearbyAllyHeroes)
	do
		if J.IsRetreating(npcAlly)
		then
			for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
			do
				if ( J.IsValid(npcEnemy) and npcAlly:WasRecentlyDamagedByHero( npcEnemy, 1.0 ) ) 
				then
					return BOT_ACTION_DESIRE_HIGH, J.GetDelayCastLocation(npcAlly,npcEnemy,nCastRange,nRadius,1.45);
				end
			end
		end
	end
	
	

	--团战
	if J.IsInTeamFight(bot, 1200)
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange - 200, nRadius/2, nCastPoint, 0 );
		if ( locationAoE.count >= 2 ) 
		then
			local nInvUnit = J.GetInvUnitInLocCount(bot, nCastRange, nRadius/2, locationAoE.targetloc, false);
			if nInvUnit >= locationAoE.count then
				return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc;
			end
		end
	end
	
	-- 追击
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = J.GetProperTarget(bot);
		if J.IsValidHero(npcTarget) 
		   and J.CanCastOnNonMagicImmune(npcTarget) 
		   and J.IsInRange(npcTarget, bot, nCastRange + nRadius) 
		then
			local nCastLoc = J.GetDelayCastLocation(bot,npcTarget,nCastRange,nRadius,1.45)
			if nCastLoc ~= nil 
			then
				return BOT_ACTION_DESIRE_HIGH, nCastLoc;
			end
		end
	end

	--对线
	if ( J.IsPushing(bot) or J.IsDefending(bot) ) 
	then
		if #tableNearbyEnemyHeroes >= 4 and tableNearbyEnemyHeroes[1] ~= nil
		then
			local nCastLoc = J.GetDelayCastLocation(bot,tableNearbyEnemyHeroes[1],nCastRange,nRadius,1.45)
			if nCastLoc ~= nil and nMP > 0.6
			then
				return BOT_MODE_DESIRE_LOW, nCastLoc;
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end


function X.ConsiderR()

	if not abilityR:IsFullyCastable() then return 0 end

	-- Get some of its values
	local nRadius    = 450;
	local nCastRange = abilityR:GetCastRange() + aetherRange;
	local nCastPoint = abilityR:GetCastPoint();
	local nDelay	 = abilityR:GetSpecialValueFloat( 'delay' );
	local nManaCost  = abilityR:GetManaCost();
	local nDamage    = abilityR:GetSpecialValueInt('damage');
	
	local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
	local tableNearbyAllyHeroes = bot:GetNearbyHeroes( 800, false, BOT_MODE_NONE );

	--有把握在困住后击杀
	for _,npcEnemy in pairs(tableNearbyEnemyHeroes)
	do
		local tableEnemyAllyHeroes = npcEnemy:GetNearbyHeroes( nRadius, false, BOT_MODE_NONE );
		if  J.IsValid(npcEnemy) and J.CanCastOnNonMagicImmune(npcEnemy) and J.IsOtherAllyCanKillTarget(bot, npcEnemy) and #tableEnemyAllyHeroes >= 3
		then
			if  npcEnemy:GetMovementDirectionStability() >= 0.75 then
				return BOT_MODE_DESIRE_MODERATE, npcEnemy:GetExtrapolatedLocation(nDelay);
			else
				return BOT_MODE_DESIRE_MODERATE, npcEnemy:GetLocation();
			end
		end
	end

	--团战
	if J.IsInTeamFight(bot, 1200)
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius/2, nCastPoint, 0 );
		if ( locationAoE.count >= 4 ) 
		then
			local nInvUnit = J.GetInvUnitInLocCount(bot, nCastRange, nRadius/2, locationAoE.targetloc, false);
			if nInvUnit >= locationAoE.count then
				return BOT_MODE_DESIRE_HIGH, locationAoE.targetloc;
			end
		end
	end

	-- 追击
	if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = J.GetProperTarget(bot);
		if J.IsValidHero(npcTarget) then
			local tableEnemyAllyHeroes = npcTarget:GetNearbyHeroes( nRadius, false, BOT_MODE_NONE );
			if J.CanCastOnNonMagicImmune(npcTarget)
			and J.IsInRange(npcTarget, bot, nCastRange + nRadius)
			and #tableEnemyAllyHeroes >= 2
			then
				local nCastLoc = J.GetDelayCastLocation(bot,npcTarget,nCastRange,nRadius,2.0)
				if nCastLoc ~= nil 
				then
					return BOT_MODE_DESIRE_MODERATE, nCastLoc;
				end
			end
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;

end

function RecordTheLocation()
    local nEnemysTeam = GetTeamPlayers(GetOpposingTeam());
    local nEnemysHeroesCanSeen = GetUnitList(UNIT_LIST_ENEMY_HEROES);
    local loctime = DotaTime();
    local players = {}

    for _,TeamPlayer in pairs( nEnemysTeam )
	do
        for _,Enemy in pairs( nEnemysHeroesCanSeen )
        do
            if Enemy:GetUnitName() == GetSelectedHeroName(TeamPlayer) then --取得英雄的玩家id
                table.insert(hEnemyRecordLocation,{
                    ['playerid'] = TeamPlayer,
                    ['time'] = loctime,
                    ['location'] = Enemy:GetLocation(),
                });
                players[TeamPlayer] = Enemy:GetLocation();
            end
        end
        if players[TeamPlayer] == nil then
            local info = GetHeroLastSeenInfo(TeamPlayer)
            if info ~= nil then
                local dInfo = info[1];
                if dInfo ~= nil then
                    table.insert(hEnemyRecordLocation,{
                        ['playerid'] = TeamPlayer,
                        ['time'] = dInfo.time_since_seen,
                        ['location'] = dInfo.location,
					});
                end
            end
        end
        --清除缓存,加入地址库
		if #hEnemyRecordLocation >= 10 then
			for i = 2, #hEnemyRecordLocation - 10
			do
				if hEnemyRecordLocation[i] ~= nil then
					if hEnemyRecordLocation[i]['time'] < loctime - 4 then
						table.remove(hEnemyRecordLocation,i)
					elseif hEnemyRecordLocation[i]['time'] >= loctime - 4 and hEnemyRecordLocation[i]['time'] <= loctime - 5 then
						hEnemyOnceLocation[hEnemyRecordLocation[i]['playerid']] = {
							['location'] = hEnemyRecordLocation[i]['location'],
							['time'] = hEnemyRecordLocation[i]['time'],
						};
						print('-2-');
						print(hEnemyOnceLocation[hEnemyRecordLocation[i]['playerid']]['time']);
					end
				end
            end
		end
		if hEnemyRecordLocation[1] ~= nil then
			if hEnemyRecordLocation[1]['time'] > loctime - 4 and hEnemyRecordLocation[1]['time'] <= loctime - 5 then
				hEnemyOnceLocation[hEnemyRecordLocation[i]['playerid']] = {
					['location'] = hEnemyRecordLocation[i]['location'],
					['time'] = hEnemyRecordLocation[i]['time'],
				};
				print('-1-');
				print(hEnemyOnceLocation[hEnemyRecordLocation[i]['playerid']]['time']);
			elseif hEnemyRecordLocation[1]['time'] > loctime - 10 then
				table.remove(hEnemyRecordLocation,1)
			end
		end
		for i = 1, #hEnemyOnceLocation
		do
			if hEnemyOnceLocation[i]['time'] < loctime - 10 then
				hEnemyOnceLocation[i] = nil
			end
		end
	end

	return;
end

return X