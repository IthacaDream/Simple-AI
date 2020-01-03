-----------------
--英雄：孽主
--技能：怨念深渊
--键位：W
--类型：指向地点
--作者：Halcyon
-----------------
local X = {}
local bot = GetBot()

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local U = require( GetScriptDirectory()..'/AuxiliaryScript/Generic')

--初始数据
local ability = bot:GetAbilityByName('abyssal_underlord_pit_of_malice')
local nKeepMana, nMP, nHP, nLV, hEnemyHeroList, hAlleyHeroList, aetherRange;

nKeepMana = 400 --魔法储量
nLV = bot:GetLevel(); --当前英雄等级
nMP = bot:GetMana()/bot:GetMaxMana(); --目前法力值/最大法力值（魔法剩余比）
nHP = bot:GetHealth()/bot:GetMaxHealth();--目前生命值/最大生命值（生命剩余比）
hEnemyHeroList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);--1600范围内敌人
hAlleyHeroList = bot:GetNearbyHeroes(1600, false, BOT_MODE_NONE);--1600范围内队友

--获取以太棱镜施法距离加成
local aether = J.IsItemAvailable("item_aether_lens");
if aether ~= nil then aetherRange = 250 else aetherRange = 0 end

--初始化函数库
U.init(nLV, nMP, nHP, bot);

--技能释放功能
function X.Release(castTarget)
    if castTarget ~= nil then
        X.Compensation() 
        bot:ActionQueue_UseAbilityOnLocation( ability, castTarget ) --使用技能
    end
end

--补偿功能
function X.Compensation()
    J.SetQueuePtToINT(bot, true)--临时补充魔法，使用魂戒
end

--技能释放欲望
function X.Consider()

	if not ability:IsFullyCastable() then return 0 end
	
	-- Get some of its values
	local nRadius = ability:GetSpecialValueInt( "radius" );
	local nCastRange = ability:GetCastRange();
	local nCastPoint = ability:GetCastPoint( );
	local nDamage = 1000

	--------------------------------------
	-- Mode based usage
	--------------------------------------
	local skThere, skLoc = J.IsSandKingThere(bot, nCastRange+200, 2.0);
	
	if skThere then
		return BOT_ACTION_DESIRE_MODERATE, skLoc;
	end
	
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( nCastRange, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) 
			then
				return BOT_ACTION_DESIRE_MODERATE, npcEnemy:GetLocation();
			end
		end
	end
	
	-- If we're pushing or defending a lane and can hit 4+ creeps, go for it
	if  J.IsDefending(bot) or J.IsPushing(bot)
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius, 0, 1000 );
		if ( locationAoE.count >= 2 and bot:GetMana() / bot:GetMaxMana() > 0.8 ) 
		then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
		end
	end

	
	-- If we're going after someone
	if  J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();
		if ( J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget) and J.IsInRange(npcTarget, bot, nCastRange-200)  ) 
		then
			return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetExtrapolatedLocation( nCastPoint );
		end
	end

	return BOT_ACTION_DESIRE_NONE, 0;
	
end

return X;