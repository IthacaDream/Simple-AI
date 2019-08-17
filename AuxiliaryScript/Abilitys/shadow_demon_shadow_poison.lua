-----------------
--技能：暗影剧毒
--键位：E
--类型：指向地点
-----------------
local X = {}
local bot = GetBot()

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local U = require( GetScriptDirectory()..'/AuxiliaryScript/Generic')

--初始数据
local ability = bot:GetAbilityByName('shadow_demon_shadow_poison')
local nKeepMana, nMP, nHP, nLV, hEnemyHeroList, hAlleyHeroList, aetherRange;

nKeepMana = 300 --魔法储量
nLV = bot:GetLevel(); --当前英雄等级
nMP = bot:GetMana()/bot:GetMaxMana(); --目前法力值/最大法力值（魔法剩余比）
nHP = bot:GetHealth()/bot:GetMaxHealth();--目前生命值/最大生命值（生命剩余比）
hEnemyHeroList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);--1600范围内敌人
hAlleyHeroList = bot:GetNearbyHeroes(1600, true, BOT_MODE_NONE);--1600范围内队友

--获取以太棱镜施法距离加成
local aether = J.IsItemAvailable("item_aether_lens");
if aether ~= nil then aetherRange = 250 else aetherRange = 0 end
    
--初始化函数库
U.init(nLV, nMP, nHP, bot);

--技能释放功能
function X.Release(castTarget,compensation)
    if castTarget ~= nil then
        if compensation then X.Compensation() end
        bot:ActionQueue_UseAbilityOnLocation( ability, castTarget ) --使用技能
    end
end

--补偿功能
function X.Compensation()
    J.SetQueuePtToINT(bot, true)--临时补充魔法，使用魂戒
end

--技能释放欲望
function X.Consider()

	-- 确保技能可以使用
    if ability ~= nil
       and not ability:IsFullyCastable()
	then 
		return BOT_ACTION_DESIRE_NONE, 0, 0; --没欲望
	end
	
	local nSkillLV    = ability:GetLevel()
    local nRadius     = ability:GetSpecialValueInt("radius");
	local nCastRange  = ability:GetCastRange() + aetherRange
	local nCastPoint  = ability:GetCastPoint()

    --满魔，攻击附近敌人
    if ( bot:GetActiveMode() == BOT_MODE_LANING and 
		nMP >= 0.65  ) 
	then
		local locationAoE = bot:FindAoELocation( true, true, bot:GetLocation(), nCastRange, nRadius/2, 0, 0 );
		if ( locationAoE.count >= 1 ) then
			return BOT_ACTION_DESIRE_LOW, locationAoE.targetloc;
		end
	end
    --防守时可以打到4人（包括小兵）以上
    if ( J.IsDefending(bot) or J.IsPushing(bot) ) and  nMP >= 0.65
	then
		local locationAoE = bot:FindAoELocation( true, false, bot:GetLocation(), nCastRange, nRadius, 0, 0 );
		if ( locationAoE.count >= 4 ) 
		then
			return BOT_ACTION_DESIRE_MODERATE, locationAoE.targetloc;
		end
	end
    --追击时
    if J.IsGoingOnSomeone(bot)
	then
		local npcTarget = bot:GetTarget();

		if J.IsValidHero(npcTarget) and J.CanCastOnNonMagicImmune(npcTarget) and J.IsInRange(npcTarget, bot, nCastRange + 200)
		then
			return BOT_ACTION_DESIRE_MODERATE, npcTarget:GetExtrapolatedLocation( (GetUnitToUnitDistance(npcTarget, bot) / 1000) + nCastPoint );
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
end

return X;