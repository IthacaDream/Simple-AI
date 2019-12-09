-----------------
--英雄：树精卫士
--技能：活体护甲
--键位：E
--类型：指向地点/单位
--作者：Меня завут Зона!
-----------------
local X = {}
local bot = GetBot()

local J = require( GetScriptDirectory()..'/FunLib/jmz_func')
local U = require( GetScriptDirectory()..'/AuxiliaryScript/Generic')

--初始数据
local ability = bot:GetAbilityByName('treant_living_armor')
local nKeepMana, nMP, nHP, nLV, hEnemyHeroList, hAlleyHeroList, aetherRange;

nKeepMana = 500 --魔法储量
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
		local typeAOE = X.CheckFlag(ability:GetBehavior(), ABILITY_BEHAVIOR_POINT);
		if typeAOE == true then
			bot:Action_UseAbilityOnLocation( ability, castTarget:GetLocation() );
		else
			bot:Action_UseAbilityOnEntity( ability, castTarget );
		end
    end
end

--补偿功能
function X.Compensation()
    J.SetQueuePtToINT(bot, true)--临时补充魔法，使用魂戒
end

--技能释放欲望
function X.Consider()

	-- 确保技能可以使用
    if ability == nil
	   or ability:IsNull()
       or not ability:IsFullyCastable()
	then 
		return BOT_ACTION_DESIRE_NONE, 0; --没欲望
	end
	
	--local nCastRange = ability:GetCastRange()+200;
	-- If we're seriously retreating, see if we can land a stun on someone who's damaged us recently
	if J.IsRetreating(bot)
	then
		local tableNearbyEnemyHeroes = bot:GetNearbyHeroes( 1000, true, BOT_MODE_NONE );
		for _,npcEnemy in pairs( tableNearbyEnemyHeroes )
		do
			if ( bot:WasRecentlyDamagedByHero( npcEnemy, 2.0 ) ) 
			then
				return BOT_ACTION_DESIRE_VERYHIGH, bot;
			end
		end
	end
	
	local numPlayer =  GetTeamPlayers(GetTeam());
	for i = 1, #numPlayer
	do
		local Player = GetTeamMember(i);
		if Player ~= nil and Player:IsAlive() and Player:GetHealth()/Player:GetMaxHealth() < 0.8
		then
			--bot:ActionImmediate_Ping(Player:GetLocation().x, Player:GetLocation().y, true); -- test
			return BOT_ACTION_DESIRE_VERYHIGH, Player;
		end
	end

	local towersList = {
		TOWER_BASE_1,
		TOWER_BASE_2,
		TOWER_MID_3,
		TOWER_BOT_3,
		TOWER_TOP_3,
		TOWER_MID_2,
		TOWER_BOT_2,
		TOWER_TOP_2,
		TOWER_MID_1,
		TOWER_BOT_1,
		TOWER_TOP_1
	}
	local needHealTowers = {}
	for i = 1, #towersList do
		local tower = GetTower(GetTeam(), i)
		if tower ~= nil then
			if tower:GetHealth() ~= tower:GetMaxHealth() then
				table.insert(needHealTowers, tower)
			end
		end
	end

	if #needHealTowers > 0 then
		local tIndex = RandomInt(1, #needHealTowers)
		local t = needHealTowers[tIndex]
		if t ~= nil then
			--bot:ActionImmediate_Ping(t:GetLocation().x, t:GetLocation().y, true); -- test
			return BOT_ACTION_DESIRE_VERYHIGH, t
		end
	end
	
	return BOT_ACTION_DESIRE_NONE, 0;
	
end

function X.CheckFlag(bitfield, flag)
    return ((bitfield/flag) % 2) >= 1;
end

return X;