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
local ConversionMode = dofile( GetScriptDirectory()..'/AuxiliaryScript/BotlibConversion') --引入技能文件
local Minion = dofile( GetScriptDirectory()..'/FunLib/Minion')
local sTalentList = J.Skill.GetTalentList(bot)
local sAbilityList = J.Skill.GetAbilityList(bot)

--编组技能、天赋、装备
local tGroupedDataList = {}
--默认数据
local tDefaultGroupedData = {
	['Talent'] = {
		['t25'] = {10, 0},
		['t20'] = {10, 0},
		['t15'] = {10, 0},
		['t10'] = {0, 10},
	},
	['Ability'] = {3,2,2,1,2,6,2,1,1,1,6,3,3,3,6},
	['Buy'] = {
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
	},
	['Sell'] = {
		"item_shivas_guard",
		"item_magic_wand",
	}
}

--根据组数据生成技能、天赋、装备
local nAbilityBuildList, nTalentBuildList;

nAbilityBuildList, nTalentBuildList, X['sBuyList'], X['sSellList'] = ConversionMode.Combination(tGroupedDataList, tDefaultGroupedData)

nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList'] = J.SetUserHeroInit(nAbilityBuildList,nTalentBuildList,X['sBuyList'],X['sSellList']);

X['sSkillList'] = J.Skill.GetSkillList(sAbilityList, nAbilityBuildList, sTalentList, nTalentBuildList)

X['bDeafaultAbility'] = false
X['bDeafaultItem'] = true

if J.Role.IsPvNMode() then X['sBuyList'],X['sSellList'] = { 'PvN_priest' }, {} end

function X.MinionThink(hMinionUnit)

	if Minion.IsValidUnit(hMinionUnit) 
	then
		Minion.IllusionThink(hMinionUnit)	
	end

end

function X.SkillsComplement()

	--如果当前英雄无法使用技能或英雄处于隐形状态，则不做操作。
	if J.CanNotUseAbility(bot) 
	   or bot:HasModifier('modifier_bounty_hunter_wind_walk') 
	   or bot:IsInvisible() 
	then 
		return 
	end
	--技能检查顺序
	local order = {'R','Q','E'}
	--委托技能处理函数接管
	if ConversionMode.Skills(order) then return; end
	
end

return X
-- dota2jmz@163.com QQ:2462331592。




