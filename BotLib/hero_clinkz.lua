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
						['t25'] = {10, 0},
						['t20'] = {10, 0},
						['t15'] = {10, 0},
						['t10'] = {0, 10},
}

local tAllAbilityBuildList = {
						{1,2,2,3,2,1,2,1,1,3,3,3,6,6,6},
						{1,2,2,3,2,3,2,3,3,1,1,1,6,6,6},
}

local nAbilityBuildList = J.Skill.GetRandomBuild(tAllAbilityBuildList)

local nTalentBuildList = J.Skill.GetTalentBuild(tTalentTreeList)

X['sBuyList'] = {
				'item_ranged_carry_outfit',
				'item_blight_stone',
				"item_dragon_lance",
				"item_orchid",
				"item_desolator",
				"item_black_king_bar",
				"item_bloodthorn",
				"item_hurricane_pike",				
				"item_satanic",
}


X['sSellList'] = {

	"item_bloodthorn",
	"item_magic_wand",

}

if J.Role.IsPvNMode() or J.Role.IsAllShadow() then X['sBuyList'],X['sSellList'] = { 'PvN_clinkz' }, {} end

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = J.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
		and hMinionUnit:GetUnitName() ~= "npc_dota_clinkz_skeleton_archer"
	then
		Minion.IllusionThink(hMinionUnit)	
	end

end

--[[

npc_dota_hero_clinkz

7.23
"Ability1"		"clinkz_death_pact"
"Ability2"		"clinkz_searing_arrows"
"Ability3"		"clinkz_wind_walk"
"Ability4"		"generic_hidden"
"Ability5"		"generic_hidden"
"Ability6"		"clinkz_burning_army"
"Ability10"		"special_bonus_agility_8"
"Ability11"		"special_bonus_strength_10"
"Ability12"		"special_bonus_unique_clinkz_5"
"Ability13"		"special_bonus_unique_clinkz_1"
"Ability14"		"special_bonus_attack_range_125"
"Ability15"		"special_bonus_unique_clinkz_6"
"Ability16"		"special_bonus_unique_clinkz_2"
"Ability17"		"special_bonus_unique_clinkz_3"

modifier_clinkz_skeleton_archer_taunt_anim
modifier_clinkz_strafe
modifier_clinkz_searing_arrows
modifier_clinkz_wind_walk
modifier_clinkz_death_pact
modifier_clinkz_burning_army_thinker
modifier_clinkz_burning_army


--]]

local abilityQ = bot:GetAbilityByName( sAbilityList[1] )
local abilityW = bot:GetAbilityByName( sAbilityList[2] )
local abilityE = bot:GetAbilityByName( sAbilityList[3] )
local abilityR = bot:GetAbilityByName( sAbilityList[6] )
local talent4 = bot:GetAbilityByName( sTalentList[4] )

local castQDesire, castQTarget
local castWDesire, castWTarget
local castEDesire
local castRDesire, castRLocation

local nKeepMana,nMP,nHP,nLV,hEnemyList,hAllyList,botTarget,sMotive;
local aetherRange = 0

function X.SkillsComplement()

	if J.CanNotUseAbility(bot) or bot:IsInvisible() then return end

	nKeepMana = 200
	aetherRange = 0
	nLV = bot:GetLevel();
	nMP = bot:GetMana()/bot:GetMaxMana();
	nHP = bot:GetHealth()/bot:GetMaxHealth();
	botTarget = J.GetProperTarget(bot);
	hEnemyList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);
	hAllyList = J.GetAlliesNearLoc(bot:GetLocation(), 1600);
	
	
	local aether = J.IsItemAvailable("item_aether_lens");
	if aether ~= nil then aetherRange = 250 end	
	
	castEDesire, sMotive = X.ConsiderE();
	if ( castEDesire > 0 ) 
	then
		J.SetReportMotive(bDebugMode,sMotive);
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbility( abilityE )
		return;
	end
	
	castRDesire, castRLocation, sMotive = X.ConsiderR();
	if ( castRDesire > 0 ) 
	then
		J.SetReportMotive(bDebugMode,sMotive);
	
		J.SetQueuePtToINT(bot, true)
	
		bot:ActionQueue_UseAbilityOnLocation( abilityR, castRLocation )
		return;
	
	end
	
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
	
		bot:Action_UseAbilityOnEntity( abilityW, castWTarget )
		return;
	end

end


function X.ConsiderQ()


	if not abilityQ:IsFullyCastable() then return 0 end
	
	local nSkillLV    = abilityQ:GetLevel()
	local nCastRange  = abilityQ:GetCastRange() + aetherRange + 32
	local nCastPoint  = abilityQ:GetCastPoint()
	local nManaCost   = abilityQ:GetManaCost()
	local nDamage     = abilityQ:GetAbilityDamage()
	local nMaxCreepLV = abilityQ:GetSpecialValueInt('neutral_level')
	local nDamageType = DAMAGE_TYPE_MAGICAL
	
	if #hEnemyList == 0 then nCastRange = 1600 end
	
	local nEnemyCreepList = bot:GetNearbyCreeps(nCastRange,true)
	-- if #nEnemyCreepList == 0
	-- then
		-- nEnemyCreepList = bot:GetNearbyCreeps(900,false)
	-- end
	local nBestEnemyCreep = nil
	
	local targetCreepBountyGoldMax = 1
	for _,nCreep in pairs(nEnemyCreepList)
	do
		if J.IsValid(nCreep)
			and not nCreep:IsAncientCreep()
			and not nCreep:IsMagicImmune()
			--and (nCreep:GetTeam() ~= bot:GetTeam() or nCreep:GetUnitName() == 'npc_dota_clinkz_skeleton_archer')
			and nCreep:GetLevel() <= nMaxCreepLV
			and nCreep:GetBountyGoldMax() * 10000 + nCreep:GetHealth() > targetCreepBountyGoldMax
		then
			nBestEnemyCreep = nCreep
			targetCreepBountyGoldMax = nCreep:GetBountyGoldMax() * 10000 + nCreep:GetHealth()	
		end
	end
	
	if nBestEnemyCreep ~= nil --compare the most with it will better
	then
		return BOT_ACTION_DESIRE_HIGH, nBestEnemyCreep, "Q-normal:"..nBestEnemyCreep:GetUnitName()
	end	

	
	return BOT_ACTION_DESIRE_NONE;
	
	
end



local lastAutoTime = 0;
function X.ConsiderW()

	if not abilityW:IsFullyCastable() or bot:IsDisarmed() then 
		return BOT_ACTION_DESIRE_NONE, 0;
	end
	
	local nSkillLV = abilityW:GetLevel()
	local nAttackRange = bot:GetAttackRange() + 50;
	local nAttackDamage = bot:GetAttackDamage()
	local nTalent4Damage = talent4:IsTrained() and talent4:GetSpecialValueInt("value") or 0
	local nAbilityDamage = nAttackDamage + abilityW:GetSpecialValueInt("damage_bonus") + nTalent4Damage
	local nDamageType = DAMAGE_TYPE_PHYSICAL
	local nCastRange = nAttackRange;

	local nTowers = bot:GetNearbyTowers(870,true)
	local nEnemysLaneCreepsInRange = bot:GetNearbyLaneCreeps(nAttackRange + 100,true)
	local nEnemysLaneCreepsInBonus = bot:GetNearbyLaneCreeps(500,true)
	local nEnemysWeakestLaneCreepsInRange = J.GetVulnerableWeakestUnit(false, true, nAttackRange + 200, bot)
	
	local nEnemysHerosInAttackRange = bot:GetNearbyHeroes(nAttackRange,true,BOT_MODE_NONE);
	local nEnemysWeakestHero = J.GetVulnerableWeakestUnit(true, true, nAttackRange + 40, bot)
	
	local nAllyLaneCreeps = bot:GetNearbyLaneCreeps(450,false)
	local botMode = bot:GetActiveMode()
	local nTargetUint = nil
		
	
	if nLV >= 7
	then
		if ( hEnemyList[1] ~= nil or ( nSkillLV >= 4 and nMP > 0.6 - 0.01 * nLV ) )
			and not abilityW:GetAutoCastState()
		then
			lastAutoTime = DotaTime();
			abilityW:ToggleAutoCast();
		elseif hEnemyList[1] == nil  
				and lastAutoTime < DotaTime() - 2.0
				and abilityW:GetAutoCastState()
			then
				abilityW:ToggleAutoCast();
		end	
	else
		if abilityW:GetAutoCastState()
		then
			abilityW:ToggleAutoCast();
		end	
	end
	
	if nLV <= 6 and nHP > 0.55 
	   and J.IsValidHero(botTarget)
	   and ( not J.IsRunning(bot) or J.IsInRange(bot,botTarget,nAttackRange + 29) )
	then
		if  not botTarget:IsAttackImmune()
			and GetUnitToUnitDistance(bot,botTarget) < nAttackRange + 99
		then
			nTargetUint = botTarget;
			return BOT_ACTION_DESIRE_HIGH, nTargetUint, "W-HandAttack"
		end	
	end
	
	
	if ( botMode == BOT_MODE_LANING and #nTowers == 0) 
	then
		if J.IsValid(nEnemysWeakestHero)
		then		    
			if  nHP >= 0.62 
				and #nEnemysLaneCreepsInBonus <= 6 
				and #nAllyLaneCreeps >= 2
				and not bot:WasRecentlyDamagedByCreep(1.5)
				and not bot:WasRecentlyDamagedByAnyHero(1.5)
			then
				return BOT_ACTION_DESIRE_HIGH,nEnemysWeakestHero, "W-HandAttack1"	
			end
			
			if J.GetAllyUnitCountAroundEnemyTarget(nEnemysWeakestHero, 500, bot) >= 3
			   and nHP >= 0.6 
			   and not bot:WasRecentlyDamagedByCreep(1.5)
			   and not bot:WasRecentlyDamagedByAnyHero(1.5)
			then
				return BOT_ACTION_DESIRE_HIGH,nEnemysWeakestHero, "W-HandAttack2"	
			end
			
		end
		
		--补刀
		if J.IsWithoutTarget(bot)
		   and not J.IsAttacking(bot)
		then
			local nLaneCreepList = bot:GetNearbyLaneCreeps(950,true);
			for _,creep in pairs(nLaneCreepList)
			do
				if J.IsValid(creep)
					and not creep:HasModifier("modifier_fountain_glyph")
					and creep:GetHealth() < nAttackDamage + 180
					and not J.IsAllysTarget(creep)
				then
					local nAttackProDelayTime = J.GetAttackProDelayTime(bot,nCreep) * 1.12 + 0.05
					local nAD = nAbilityDamage * bot:GetAttackCombatProficiency(creep);
					if J.WillKillTarget(creep,nAD,nDamageType,nAttackProDelayTime)
					then
						return BOT_ACTION_DESIRE_HIGH, creep, nAD..'W-LastHit:'..creep:GetHealth()
					end				
				end
			end
		
		end
	end
	
	
	if  J.IsValidHero(botTarget)
		and GetUnitToUnitDistance(botTarget,bot) > nAttackRange + 200
		and J.IsValidHero(nEnemysHerosInAttackRange[1])
		and J.CanBeAttacked(nEnemysHerosInAttackRange[1])
		and botMode ~= BOT_MODE_RETREAT
	then
		return BOT_ACTION_DESIRE_HIGH, nEnemysHerosInAttackRange[1];
	end
	
	
	if  botTarget == nil
	    and botMode ~= BOT_MODE_RETREAT 
	    and botMode ~= BOT_MODE_ATTACK 
		and botMode ~= BOT_MODE_ASSEMBLE
		and botMode ~= BOT_MODE_TEAM_ROAM
	then
		
		if J.IsValid(nEnemysWeakestLaneCreepsInRange)
			and not J.IsAllysTarget(nEnemysWeakestLaneCreepsInRange)
		then
			local nCreep = nEnemysWeakestLaneCreepsInRange;
			local nAttackProDelayTime = J.GetAttackProDelayTime(bot,nCreep)
			
			local otherAttackRealDamage = J.GetTotalAttackWillRealDamage(nCreep,nAttackProDelayTime);
			local nRealDamage = nCreep:GetActualIncomingDamage(nAbilityDamage * bot:GetAttackCombatProficiency(nCreep),nDamageType)
			
			if otherAttackRealDamage + nRealDamage > nCreep:GetHealth()
			   and not J.CanKillTarget(nCreep, nAttackDamage, DAMAGE_TYPE_PHYSICAL)
			then	

				local nTime = nAttackProDelayTime;
				local rMessage = "时:"..J.GetTwo(DotaTime()%60).."延:"..J.GetOne(nAttackProDelayTime).."生:"..nCreep:GetHealth().."技:"..J.GetOne(nAbilityDamage).."额:"..J.GetOne(otherAttackRealDamage).."总:"..(otherAttackRealDamage + nRealDamage);			
				return BOT_ACTION_DESIRE_HIGH,nCreep,rMessage;
			end
			
		end
		
	end
	
	--farm or push
	if ( J.IsFarming(bot) or J.IsPushing(bot) )
		and nSkillLV >= 3 
		and not abilityW:GetAutoCastState()
	then
		if J.IsValidBuilding(botTarget)
			and bot:GetMana() > nKeepMana
			and not botTarget:HasModifier('modifier_fountain_glyph')
			and J.IsInRange(bot,botTarget,nCastRange + 80)
		then
			return BOT_ACTION_DESIRE_HIGH,botTarget,'W-push_tower'
		end
		
		if botTarget ~= nil
			and botTarget:IsAlive()
			and nMP > 0.4
			and not botTarget:HasModifier('modifier_fountain_glyph')
			and botTarget:GetHealth() > nAbilityDamage * 2.6
			and J.IsInRange(bot,botTarget,nCastRange + 80)
		then
			return BOT_ACTION_DESIRE_HIGH,botTarget,'W-farm_creep'
		end
	end
	
	
	-- If we're going after someone
	if J.IsGoingOnSomeone(bot) and not abilityW:GetAutoCastState()
	then
		if J.IsValidHero(botTarget)
			and not botTarget:IsAttackImmune()
			and J.CanCastOnMagicImmune(botTarget)
			and J.IsInRange(botTarget, bot, nAttackRange + 80)
		then
			return BOT_ACTION_DESIRE_MODERATE, botTarget;
		end
	end
	
	
	if ( bot:GetActiveMode() == BOT_MODE_ROSHAN and not abilityW:GetAutoCastState() ) 
	then
		if  J.IsRoshan(botTarget) 
			and J.IsInRange(botTarget, bot, nAttackRange)			
		then
			return BOT_ACTION_DESIRE_HIGH,botTarget;
		end
	end
	
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderE()

	local nEnemyTowers = bot:GetNearbyTowers(888,true)

	if not abilityE:IsFullyCastable() 
		or bot:IsInvisible()
		or #nEnemyTowers >= 1
		or bot:HasModifier("modifier_item_dustofappearance")
		or bot:DistanceFromFountain() < 800
	then return 0 end	
	
	local nSkillLV    = abilityE:GetLevel(); 
	local nCastRange  = abilityE:GetCastRange();
	local nCastPoint  = abilityE:GetCastPoint();
	local nManaCost   = abilityE:GetManaCost();
	local nDamage     = abilityE:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE);
	
	--retreat
	if J.IsRetreating(bot)
		and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH
		and #hEnemyList > 0
	then
		return BOT_ACTION_DESIRE_HIGH, 'E-Retreat'
	end
	
	--invis
	if J.GetHPR(bot) < 0.166
	   and (#hEnemyList > 0 or bot:WasRecentlyDamagedByAnyHero(5.0))
	then
		return BOT_ACTION_DESIRE_HIGH, 'E-Fade'
	end	
	
	--Attack
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and J.CanCastOnMagicImmune(botTarget)
		then
			if not J.IsInRange(bot, botTarget, botTarget:GetCurrentVisionRange())
			   and J.IsInRange(bot, botTarget, 3000)
			then
				local hEnemyCreepList = bot:GetNearbyLaneCreeps(700,true);
				if #hEnemyCreepList == 0 and #hEnemyList == 0
				then
					return BOT_ACTION_DESIRE_HIGH, 'E-InvisAttack:'..J.Chat.GetNormName(botTarget)
				end	
			end
			
			if	nSkillLV >= 2
				and J.IsInRange(bot,botTarget,bot:GetAttackRange() + 750)
			then
				return BOT_ACTION_DESIRE_HIGH, 'E-AddAttackSpeed:'..J.Chat.GetNormName(botTarget)		
			end
		end		
	end
	
	if J.IsInEnemyArea(bot) 
		and nLV >= 9 
		and J.IsRunning(bot)
	then
		local nEnemies = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
		local nAllies  = bot:GetNearbyHeroes(1400,true,BOT_MODE_NONE);
		local nEnemyTowers = bot:GetNearbyTowers(1400,true);
		if #nEnemies == 0 and #nAllies <= 2 and nEnemyTowers == 0
		then
			return BOT_ACTION_DESIRE_HIGH, 'E-EnemyAreaRun'
		end
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end

function X.ConsiderR()


	if not abilityR:IsFullyCastable() or true then return 0 end
	
	local nSkillLV    = abilityR:GetLevel(); 
	local nCastRange  = abilityR:GetCastRange();
	local nCastPoint  = abilityR:GetCastPoint();
	local nManaCost   = abilityR:GetManaCost();
	local nDamage     = abilityR:GetAbilityDamage()
	local nDamageType = DAMAGE_TYPE_MAGICAL
	local nInRangeEnemyList = bot:GetNearbyHeroes(nCastRange, true, BOT_MODE_NONE);
	
	--ForAbilitQ
	if J.IsGoingOnSomeone(bot)
	then
		if J.IsValidHero(botTarget)
			and abilityQ:IsFullyCastable()
			and bot:GetMana() > abilityQ:GetManaCost() + nManaCost
		then
			local nEnemyCreepList = bot:GetNearbyCreeps(900,true);
			if #nEnemyCreepList == 0
			then
				local nCastLocation = bot:GetLocation()
				return BOT_ACTION_DESIRE_HIGH,nCastLocation,"R-ForAbilitQ"
			end
		end	
	end
	
	return BOT_ACTION_DESIRE_NONE;
	
	
end


return X
-- dota2jmz@163.com QQ:2462331592
