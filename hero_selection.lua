---------------------------------------------------------------------------
--- The Creation Come From: A Beginner AI 
--- Author: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
---------------------------------------------------------------------------
--	When the bot is thinking, the player is laughing.
--  But when the player no longer thinking, the bot still thinking.
------------------------------------------------------2019.11
local targetdata = require(GetScriptDirectory() .. "/AuxiliaryScript/RoleTargetsData")
local otherGameMod = require(GetScriptDirectory() .. "/AuxiliaryScript/OtherGameMod");

local X = {};
local bDebugMode = ( 1 == 10 )
local sSelectHero = "npc_dota_hero_zuus";
local fLastSlectTime,fLastRand,nRand = 0,0,0 ;
local nDelayTime = nil
local nHumanCount = 0;
local sBanList = {}; 
local sSelectList = {};
local tSelectPoolList = {};
local tRecommendSelectPoolList = {};
local tLaneAssignList = {};
local bInitLineUpDone = false;

local bUserMode = false;
local bLaneAssignActive = false;
local bLineupActive = false;
local bLineupReserve = false;


local Role = require( GetScriptDirectory()..'/FunLib/jmz_role')
local Chat = require( GetScriptDirectory()..'/FunLib/jmz_chat')
local HeroSet = nil
local sUserKeyDir = Chat.GetUserKeyDir()

--[[
'npc_dota_hero_abaddon',
'npc_dota_hero_abyssal_underlord',
'npc_dota_hero_alchemist',
'npc_dota_hero_ancient_apparition',
'npc_dota_hero_antimage',
'npc_dota_hero_arc_warden',
'npc_dota_hero_axe',
'npc_dota_hero_bane',
'npc_dota_hero_batrider',
'npc_dota_hero_beastmaster',
'npc_dota_hero_bloodseeker',
'npc_dota_hero_bounty_hunter',
'npc_dota_hero_brewmaster',
'npc_dota_hero_bristleback',
'npc_dota_hero_broodmother',
'npc_dota_hero_centaur',
'npc_dota_hero_chaos_knight',
'npc_dota_hero_chen',
'npc_dota_hero_clinkz',
'npc_dota_hero_crystal_maiden',
'npc_dota_hero_dark_seer',
'npc_dota_hero_dark_willow',
'npc_dota_hero_dazzle',
'npc_dota_hero_disruptor',
'npc_dota_hero_death_prophet',
'npc_dota_hero_doom_bringer',
'npc_dota_hero_dragon_knight',
'npc_dota_hero_drow_ranger',
'npc_dota_hero_earth_spirit',
'npc_dota_hero_earthshaker',
'npc_dota_hero_elder_titan',
'npc_dota_hero_ember_spirit',
'npc_dota_hero_enchantress',
'npc_dota_hero_enigma',
'npc_dota_hero_faceless_void',
'npc_dota_hero_furion',
'npc_dota_hero_grimstroke',
'npc_dota_hero_gyrocopter',
'npc_dota_hero_huskar',
'npc_dota_hero_invoker',
'npc_dota_hero_jakiro',
'npc_dota_hero_juggernaut',
'npc_dota_hero_keeper_of_the_light',
'npc_dota_hero_kunkka',
'npc_dota_hero_legion_commander',
'npc_dota_hero_leshrac',
'npc_dota_hero_lich',
'npc_dota_hero_life_stealer',
'npc_dota_hero_lina',
'npc_dota_hero_lion',
'npc_dota_hero_lone_druid',
'npc_dota_hero_luna',
'npc_dota_hero_lycan',
'npc_dota_hero_magnataur',
'npc_dota_hero_mars',
'npc_dota_hero_medusa',
'npc_dota_hero_meepo',
'npc_dota_hero_mirana',
'npc_dota_hero_morphling',
'npc_dota_hero_monkey_king',
'npc_dota_hero_naga_siren',
'npc_dota_hero_necrolyte',
'npc_dota_hero_nevermore',
'npc_dota_hero_night_stalker',
'npc_dota_hero_nyx_assassin',
'npc_dota_hero_obsidian_destroyer',
'npc_dota_hero_ogre_magi',
'npc_dota_hero_omniknight',
'npc_dota_hero_oracle',
'npc_dota_hero_pangolier',
'npc_dota_hero_phantom_lancer',
'npc_dota_hero_phantom_assassin',
'npc_dota_hero_phoenix',
'npc_dota_hero_puck',
'npc_dota_hero_pudge',
'npc_dota_hero_pugna',
'npc_dota_hero_queenofpain',
'npc_dota_hero_rattletrap',
'npc_dota_hero_razor',
'npc_dota_hero_riki',
'npc_dota_hero_rubick',
'npc_dota_hero_sand_king',
'npc_dota_hero_shadow_demon',
'npc_dota_hero_shadow_shaman',
'npc_dota_hero_shredder',
'npc_dota_hero_silencer',
'npc_dota_hero_skeleton_king',
'npc_dota_hero_skywrath_mage',
'npc_dota_hero_slardar',
'npc_dota_hero_slark',
"npc_dota_hero_snapfire",
'npc_dota_hero_sniper',
'npc_dota_hero_spectre',
'npc_dota_hero_spirit_breaker',
'npc_dota_hero_storm_spirit',
'npc_dota_hero_sven',
'npc_dota_hero_techies',
'npc_dota_hero_terrorblade',
'npc_dota_hero_templar_assassin',
'npc_dota_hero_tidehunter',
'npc_dota_hero_tinker',
'npc_dota_hero_tiny',
'npc_dota_hero_treant',
'npc_dota_hero_troll_warlord',
'npc_dota_hero_tusk',
'npc_dota_hero_undying',
'npc_dota_hero_ursa',
'npc_dota_hero_vengefulspirit',
'npc_dota_hero_venomancer',
'npc_dota_hero_viper',
'npc_dota_hero_visage',
'npc_dota_hero_void_spirit',
'npc_dota_hero_warlock',
'npc_dota_hero_weaver',
'npc_dota_hero_windrunner',
'npc_dota_hero_winter_wyvern',
'npc_dota_hero_wisp',
'npc_dota_hero_witch_doctor',
'npc_dota_hero_zuus',
--]]

local tRecommendLineUpList = {	
				[1]={	"npc_dota_hero_viper",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_drow_ranger",
						"npc_dota_hero_crystal_maiden",
						"npc_dota_hero_silencer" },
				[2]={	"npc_dota_hero_viper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[3]={	"npc_dota_hero_viper",
						"npc_dota_hero_kunkka",
						"npc_dota_hero_arc_warden",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[4]={	"npc_dota_hero_viper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_sven",
						"npc_dota_hero_skywrath_mage",
						"npc_dota_hero_silencer" },
				[5]={	"npc_dota_hero_viper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_sven",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[6]={	"npc_dota_hero_viper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_skywrath_mage",
						"npc_dota_hero_necrolyte" },
				[7]={	"npc_dota_hero_viper",
						"npc_dota_hero_ogre_magi",
						"npc_dota_hero_antimage",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_witch_doctor" },
				[8]={	"npc_dota_hero_viper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_lina",
						"npc_dota_hero_necrolyte" },
				[9]={	"npc_dota_hero_viper",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_phantom_lancer",
						"npc_dota_hero_pugna",
						"npc_dota_hero_death_prophet" },
						
						
				[10]={	"npc_dota_hero_sniper",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_drow_ranger",
						"npc_dota_hero_crystal_maiden",
						"npc_dota_hero_silencer" },
				[11]={	"npc_dota_hero_sniper",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_sven",
						"npc_dota_hero_crystal_maiden",
						"npc_dota_hero_silencer" },
				[12]={	"npc_dota_hero_sniper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[13]={	"npc_dota_hero_sniper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_sven",
						"npc_dota_hero_pugna",
						"npc_dota_hero_warlock" },
				[14]={	"npc_dota_hero_sniper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[15]={	"npc_dota_hero_sniper",
						"npc_dota_hero_kunkka",
						"npc_dota_hero_arc_warden",
						"npc_dota_hero_skywrath_mage",
						"npc_dota_hero_necrolyte" },
				[16]={	"npc_dota_hero_sniper",
						"npc_dota_hero_kunkka",
						"npc_dota_hero_sven",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[17]={	"npc_dota_hero_sniper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_sven",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[18]={	"npc_dota_hero_sniper",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[19]={	"npc_dota_hero_sniper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_antimage",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[20]={	"npc_dota_hero_sniper",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_antimage",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
						
						
				[21]={	"npc_dota_hero_medusa",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_drow_ranger",
						"npc_dota_hero_crystal_maiden",
						"npc_dota_hero_silencer" },
				[22]={	"npc_dota_hero_medusa",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[23]={	"npc_dota_hero_medusa",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_sven",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },
				[24]={	"npc_dota_hero_medusa",
						"npc_dota_hero_kunkka",
						"npc_dota_hero_arc_warden",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[25]={	"npc_dota_hero_medusa",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_sven",
						"npc_dota_hero_skywrath_mage",
						"npc_dota_hero_death_prophet" },
				[26]={	"npc_dota_hero_medusa",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_lina",
						"npc_dota_hero_necrolyte" },
				[27]={	"npc_dota_hero_medusa",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_antimage",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[28]={	"npc_dota_hero_medusa",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_oracle" },
				[29]={	"npc_dota_hero_medusa",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_drow_ranger",
						"npc_dota_hero_zuus",
						"npc_dota_hero_silencer" },
						
						
				[30]={	"npc_dota_hero_templar_assassin",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_drow_ranger",
						"npc_dota_hero_crystal_maiden",
						"npc_dota_hero_silencer" },
				[31]={	"npc_dota_hero_templar_assassin",
						"npc_dota_hero_kunkka",
						"npc_dota_hero_arc_warden",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[32]={	"npc_dota_hero_templar_assassin",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_warlock" },						
				[33]={	"npc_dota_hero_templar_assassin",
						"npc_dota_hero_skeleton_king",
						"npc_dota_hero_phantom_assassin",
						"npc_dota_hero_jakiro",
						"npc_dota_hero_necrolyte" },
				[34]={	"npc_dota_hero_templar_assassin",
						"npc_dota_hero_chaos_knight",
						"npc_dota_hero_antimage",
						"npc_dota_hero_lina",
						"npc_dota_hero_oracle" },
				
				[35]={	"npc_dota_hero_razor",
						"npc_dota_hero_bristleback",
						"npc_dota_hero_bloodseeker",
						"npc_dota_hero_zuus",
						"npc_dota_hero_silencer" },
				[36]={	"npc_dota_hero_razor",
						"npc_dota_hero_ogre_magi",
						"npc_dota_hero_phantom_lancer",
						"npc_dota_hero_lina",
						"npc_dota_hero_warlock" },
};

local sFirstList = {
	"npc_dota_hero_sniper",
	"npc_dota_hero_viper",
	"npc_dota_hero_nevermore",
	"npc_dota_hero_medusa",	
	"npc_dota_hero_templar_assassin",
	"npc_dota_hero_razor",
}

local sSecondList = {
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_bristleback",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_kunkka",
	"npc_dota_hero_skeleton_king",	
	"npc_dota_hero_ogre_magi",
}

local sThirdList = {	
	"npc_dota_hero_sven",
	"npc_dota_hero_luna",
	"npc_dota_hero_antimage",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_phantom_assassin",
	"npc_dota_hero_phantom_lancer",
	"npc_dota_hero_huskar",
	"npc_dota_hero_clinkz",
	
}

local sFourthList = {
	"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_zuus",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_lina",
	"npc_dota_hero_pugna",
	"npc_dota_hero_shadow_shaman",
}

local sFifthList = {
	"npc_dota_hero_silencer",
	"npc_dota_hero_warlock",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_oracle",
	"npc_dota_hero_witch_doctor",
	"npc_dota_hero_lich",
	"npc_dota_hero_death_prophet",
}				

---------------------------------------------------------
---------------------------------------------------------

local sMidList = {
	"npc_dota_hero_antimage",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_bristleback",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_medusa",	
	"npc_dota_hero_nevermore",
	"npc_dota_hero_phantom_assassin",
	"npc_dota_hero_razor",
	"npc_dota_hero_sniper",
	"npc_dota_hero_sniper",
	"npc_dota_hero_templar_assassin",
	"npc_dota_hero_viper",
	"npc_dota_hero_viper",
}

local sTankList = {
	"npc_dota_hero_bristleback",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_dragon_knight",
	"npc_dota_hero_kunkka",
	"npc_dota_hero_ogre_magi",
	"npc_dota_hero_skeleton_king",
}

local sCarryList = {
	"npc_dota_hero_antimage",
	"npc_dota_hero_arc_warden",
	"npc_dota_hero_bloodseeker",
	"npc_dota_hero_bristleback",
	"npc_dota_hero_chaos_knight",
	"npc_dota_hero_clinkz",
	"npc_dota_hero_drow_ranger",
	"npc_dota_hero_huskar",
	"npc_dota_hero_kunkka",
	"npc_dota_hero_luna",
	"npc_dota_hero_medusa",
	"npc_dota_hero_nevermore",
	"npc_dota_hero_phantom_assassin",
	"npc_dota_hero_phantom_lancer",
	"npc_dota_hero_razor",
	"npc_dota_hero_skeleton_king",
	"npc_dota_hero_sniper",
	"npc_dota_hero_sven",
	"npc_dota_hero_templar_assassin",
	"npc_dota_hero_viper",
}

local sMageList = {
	"npc_dota_hero_crystal_maiden",
	"npc_dota_hero_death_prophet",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_lich",
	"npc_dota_hero_lina",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_oracle",
	"npc_dota_hero_pugna",
	"npc_dota_hero_shadow_shaman",
	"npc_dota_hero_silencer",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_warlock",
	"npc_dota_hero_witch_doctor",
	"npc_dota_hero_zuus",
}

local sPriestList = {
	"npc_dota_hero_death_prophet",
	"npc_dota_hero_jakiro",
	"npc_dota_hero_lich",
	"npc_dota_hero_lina",
	"npc_dota_hero_necrolyte",
	"npc_dota_hero_oracle",
	"npc_dota_hero_pugna",
	"npc_dota_hero_shadow_shaman",
	"npc_dota_hero_silencer",
	"npc_dota_hero_skywrath_mage",
	"npc_dota_hero_warlock",
	"npc_dota_hero_witch_doctor",
	"npc_dota_hero_zuus",
}

tSelectPoolList = {
	[1] = sMidList,
	[2] = sTankList,
	[3] = sCarryList,
	[4] = sMageList,
	[5] = sPriestList,
}

tRecommendSelectPoolList = {
	[1] = sFifthList,
	[2] = sFourthList,
	[3] = sThirdList,
	[4] = sSecondList,
	[5] = sFirstList,
}


sSelectList = {
	[1] = tSelectPoolList[1][RandomInt(1, #tSelectPoolList[1])],
	[2] = tSelectPoolList[2][RandomInt(1, #tSelectPoolList[2])],
	[3] = tSelectPoolList[3][RandomInt(1, #tSelectPoolList[3])],
	[4] = tSelectPoolList[4][RandomInt(1, #tSelectPoolList[4])],
	[5] = tSelectPoolList[5][RandomInt(1, #tSelectPoolList[5])],
}


if pcall(function(sDir) require(sDir) end, sUserKeyDir)
then 
	bUserMode = true
	
	local sABATiYanMa = require(sUserKeyDir)

	--设置全局语种环境
	Chat.SetRawLanguage(sABATiYanMa)
	
	--初始策略位置
	if GetTeam() ~= TEAM_DIRE then HeroSet = require( (Chat.GetLocalWord(1))..(Chat.GetLocalWord(5)) ) end
	if GetTeam() == TEAM_DIRE then HeroSet = require( (Chat.GetLocalWord(3))..(Chat.GetLocalWord(6)) ) end
	
	--修改策略位置
	if Chat.GetRawGameWord(HeroSet['QiYongKeChang']) == true 
	then
		Role["bHostSet"] = false
		if GetTeam() ~= TEAM_DIRE then HeroSet = require( (Chat.GetLocalWord(2))..(Chat.GetLocalWord(5)) ) end
		if GetTeam() == TEAM_DIRE then HeroSet = require( (Chat.GetLocalWord(4))..(Chat.GetLocalWord(6)) ) end
	end
	
	--根据策略内容决定模式
	Role["nUserMode"] = Chat.GetRawGameWord(HeroSet['JiHuoCeLue']) == true and Role.GetUserLV(sABATiYanMa) or 0
	Role["sUserName"] = HeroSet['ZhanDuiJunShi']
	
	if Chat.GetRawGameWord(HeroSet['ShuBuQi']) ~= false then Role["nUserMode"] = -1 end
	
	if Role["nUserMode"] <= 0 then bUserMode = false end
	
	if bUserMode 
	then
		if Chat.GetRawGameWord(HeroSet['FenLuShengXiao']) == true then bLaneAssignActive = true end
		if Chat.GetRawGameWord(HeroSet['ZhenRongShengXiao']) == true then bLineupActive = true end	
		if Chat.GetRawGameWord(HeroSet['NeiBuTiaoXuan']) == true then bLineupReserve = true end
	end
end


--For Random LineUp-------------
nRand = RandomInt( 1, 128 ); 
if nRand <= #tRecommendLineUpList and not bDebugMode
then 
	local sTempList = sSelectList;
	sSelectList = tRecommendLineUpList[nRand];
	print("RandomLineUp:"..tostring(GetTeam())..tostring(nRand/100));
	for i = 1, 5
	do
		if RandomInt(1,3) < 2
		then
			sSelectList[i] = sTempList[i];	
			print(tostring(GetTeam())..':'..sTempList[i]);
		end
	end	
end


------------------------------------------------
--------------=---------------------------------
--初始阵容和英雄池
sSelectList = { sSelectList[5], sSelectList[4], sSelectList[3], sSelectList[2], sSelectList[1] };
tSelectPoolList = { tSelectPoolList[5], tSelectPoolList[4], tSelectPoolList[3], tSelectPoolList[2], tSelectPoolList[1] };
------------------------------------------------
------------------------------------------------

------For Random LaneAssign-------------
function X.GetRandomChangeLane(tLane)

	if bDebugMode then return tLane end

	if RandomInt(1,9) < 4 
	then
		tLane[1], tLane[2] = tLane[2], tLane[1];
	end 

	if RandomInt(1,9) < 4 
	then
		tLane[3], tLane[4] = tLane[4], tLane[3];
	end 

	return tLane;
end

--初始分路
if GetTeam() == TEAM_RADIANT 
then
	local nRadiantLane = {
							[1] = LANE_BOT,
							[2] = LANE_TOP,
							[3] = LANE_TOP,
							[4] = LANE_BOT,
							[5] = LANE_MID,
						};

	tLaneAssignList = X.GetRandomChangeLane(nRadiantLane);
	
else
	local nDireLane = {
						[1] = LANE_TOP,
						[2] = LANE_BOT,
						[3] = LANE_BOT,
						[4] = LANE_TOP,
						[5] = LANE_MID,
					 };

	tLaneAssignList = X.GetRandomChangeLane(nDireLane);
end
				
--根据用户配置初始列表
--根据人类玩家数量初始化英雄池,英雄表,英雄分路
--tSelectPoolList, sSelectList, tLaneAssignList
function X.SetLineUpInit()

	if bInitLineUpDone then return end
	
	if bLineupActive then sSelectList = Chat.GetHeroSelectList(HeroSet['ZhenRong'])	end
	if bLaneAssignActive then tLaneAssignList = Chat.GetLaneAssignList(HeroSet['FenLu']) end
		
	local IDs = GetTeamPlayers(GetTeam())
	for i,id in pairs(IDs) 
	do
		if not IsPlayerBot(id) 
		then
			nHumanCount = nHumanCount + 1
			tSelectPoolList = X.GetMoveTable(tSelectPoolList);
			sSelectList = X.GetMoveTable(sSelectList);
			tLaneAssignList = X.GetMoveTable(tLaneAssignList);
		end
	end
	
	bInitLineUpDone = true;
	
end


function X.GetMoveTable(nTable)

	local nLenth = #nTable;
	local temp = nTable[nLenth];
	
	table.remove(nTable, nLenth);
	table.insert(nTable, 1, temp);
	
	return nTable;
	
end


function X.IsExistInTable(sString, sStringList)
	
	for _,sTemp in pairs(sStringList) 
	do
		if sString == sTemp then return true end
	end
	
	return false
	
end


function X.IsHumanNotReady(team)
		
	if GameTime() > 20 or bLineupReserve then return false end

	local humanCount,readyCount = 0, 0;
	local IDs = GetTeamPlayers(team);
	for i,id in pairs(IDs)
	do
        if not IsPlayerBot(id)
		then
			humanCount = humanCount + 1;
			if GetSelectedHeroName(id) ~= ""
			then
				readyCount = readyCount + 1;
			end
		end
    end
	
	if( readyCount >= humanCount)
	then
		return false;
	end
	
	return true;
	
end


function X.GetNotRepeatHero(nTable)
	
	local sHero = nTable[1];
	local maxCount = #nTable;
	local nRand = 0;
	local bRepeated = false;
	
	for count = 1, maxCount
	do
		nRand = RandomInt(1, #nTable);
		sHero = nTable[nRand];
		bRepeated = false;
		for id = 0, 20
		do
			if ( IsTeamPlayer(id) and GetSelectedHeroName(id) == sHero )
				or ( IsCMBannedHero(sHero) )
				or ( X.IsBanByChat(sHero) )
			then
				bRepeated = true;
				table.remove(nTable,nRand);
				break;
			end
		end
		if not bRepeated then break; end
	end		
	
	return sHero;		
end


function X.IsRepeatHero(sHero)

	for id = 0, 20
	do
		if ( IsTeamPlayer(id) and GetSelectedHeroName(id) == sHero )
			or ( IsCMBannedHero(sHero) )
			or ( X.IsBanByChat(sHero) )
		then
			return true;
		end
	end
	
	return false;

end


if bUserMode and HeroSet['JinYongAI'] ~= nil
then
	sBanList = Chat.GetHeroSelectList(HeroSet['JinYongAI']);
end

function X.SetChatHeroBan( sChatText )
	
	sBanList[#sBanList + 1] = string.lower(sChatText);
	
end


function X.IsBanByChat( sHero )

	for i = 1,#sBanList
	do
		if sBanList[i] ~= nil
		   and string.find(sHero, sBanList[i])
		then
			return true;
		end	
	end
	
	return false;
end


local sTianStarList =
{
"天罡星",
"天魁星",
"天机星",
"天闲星",
"天勇星",
"天雄星",
"天猛星",
"天英星",
"天贵星",
"天富星",
"天满星",
"天孤星",
"天伤星",
"天立星",
"天捷星",
"天暗星",
"天佑星",
"天空星",
"天速星",
"天异星",
"天杀星",
"天微星",
"天究星",
"天退星",
"天寿星",
"天剑星",
"天平星",
"天罪星",
"天损星",
"天牢星",
"天慧星",
"天暴星",
"天巧星",
--"天威星",
--"天哭星",
--"天败星",
}


local sDiStarsList = 
{
"地煞星",
"地魁星",
"地勇星",
"地杰星",
"地雄星",
"地英星",
"地奇星",
"地猛星",
"地文星",
"地正星",
"地阔星",
"地阖星",
"地强星",
"地暗星",
"地轴星",
"地会星",
"地佐星",
"地佑星",
"地灵星",
"地兽星",
"地微星",
"地慧星",
"地暴星",
"地然星",
"地猖星",
"地狂星",
"地飞星",
"地走星",
"地巧星",
"地明星",
"地进星",
"地退星",
"地满星",
"地遂星",
"地周星",
"地隐星",
"地异星",
"地理星",
"地俊星",
"地乐星",
"地捷星",
"地速星",
"地镇星",
"地嵇星",
"地魔星",
"地妖星",
"地幽星",
"地伏星",
"地僻星",
"地空星",
"地孤星",
"地全星",
"地短星",
"地角星",
"地平星",
"地察星",
"地数星",
"地阴星",
"地刑星",
"地壮星",
"地健星",
"地耗星",
--"地贼星",
--"地狗星",
--"地威星",
--"地劣星",
--"地损星",
--"地奴星",
--"地囚星",
--"地藏星",
}

if RandomInt(1,987) < 65
then
sDiStarsList = {
"冠状细菌",
"杆状细菌",
"螺旋细菌",
"锥型细菌",
"扫帚细菌",
"扇形细菌",
"制杖细菌",
"瑙蚕细菌",
"变异细菌",
"无名细菌",
}
end


function X.GetRandomNameList(sStarList)
	
	local sNameList = {sStarList[1]};
	table.remove(sStarList,1);	
	
	for i=1,4
	do
	    local nRand = RandomInt(1, #sStarList);
		table.insert(sNameList,sStarList[nRand]);
		table.remove(sStarList,nRand);
	end
	
	return sNameList;
	
end


function Think()


	if not bInitLineUpDone then X.SetLineUpInit() return end

	if GetGameState() == GAME_STATE_HERO_SELECTION then
		InstallChatCallback(function ( tChat ) X.SetChatHeroBan( tChat.string ); end);
	end

	if GetGameMode() == GAMEMODE_AP then
		if GetGameState() == GAME_STATE_HERO_SELECTION then
			InstallChatCallback(function ( tChat ) X.SetChatHeroBan( tChat.string ); end);
		end
		AllPickLogic();
	elseif GetGameMode() == GAMEMODE_CM or GetGameMode() == GAMEMODE_REVERSE_CM then
		otherGameMod.CaptainModeLogic();
		otherGameMod.AddToList();
	else
		if GetGameState() == GAME_STATE_HERO_SELECTION then
			InstallChatCallback(function ( tChat ) X.SetChatHeroBan( tChat.string ); end);
		end
		AllPickLogic();
	end
end

function AllPickLogic()	

	if GameTime() < 3.0
	   or fLastSlectTime > GameTime() - fLastRand
	   or X.IsHumanNotReady(GetTeam()) 
	   or X.IsHumanNotReady(GetOpposingTeam()) 
	then return end;
	
	if nDelayTime == nil then nDelayTime = GameTime(); fLastRand = RandomFloat(1.2,3.4); end
	if nDelayTime ~= nil and nDelayTime > GameTime() - fLastRand then return; end	
	----------------------------------------------------------------------------------------
	------设置挑选延迟完毕------------------------------------------------------------------
	----------------------------------------------------------------------------------------
	
	--自定义挑选逻辑
	if bLineupActive
	then
		local IDs = GetTeamPlayers(GetTeam());
		for i,id in pairs(IDs) 
		do
			if ( IsPlayerBot(id) or bLineupReserve ) 
				and ( GetSelectedHeroName(id) == "" )
			then
				sSelectHero = sSelectList[i];
				
				if sSelectHero == "sRandomHero" 
				then 
					sSelectHero = X.GetNotRepeatHero(tSelectPoolList[i]); 
					if not IsPlayerBot(id) then sSelectHero = Chat['sAllHeroList'][RandomInt(2,120)] end
				end
				
				SelectHero(id,sSelectHero);
				
				fLastSlectTime = GameTime();
				fLastRand = RandomFloat(0.3,0.9);
				break;
			end
		end
		return;
	end
	
	--常规挑选逻辑
	local IDs = GetTeamPlayers(GetTeam());
	for i,id in pairs(IDs) 
	do
		if IsPlayerBot(id) and GetSelectedHeroName(id) == ""
		then
			--原版英雄选择策略
			--if X.IsRepeatHero(sSelectList[i])
			--	or ( nHumanCount == 0 
			--		 and RandomInt(1,99) < 30
			--		 and not X.IsExistInTable( sSelectList[i],tRecommendSelectPoolList[i] ))
			--then
			--	sSelectHero = X.GetNotRepeatHero(tSelectPoolList[i]);
			--else
			--	sSelectHero = sSelectList[i];
			--end
			--新版英雄选择策略
			sSelectHero = targetdata.getApHero();
			SelectHero(id,sSelectHero);
			
			fLastSlectTime = GameTime();
			fLastRand = RandomFloat(0.8,2.8);
			break;
		end
	end
	
	
end


function GetBotNames()

	if bUserMode then return HeroSet['ZhanDuiMing'] end

	return targetdata.GetDota2Team();
	
end


local sBotVersion = Role.GetBotVersion()
local bPvNLaneAssignDone = false
if bLaneAssignActive or sBotVersion == 'Mid'
then

function UpdateLaneAssignments()  

	if DotaTime() > 0 
		and nHumanCount == 0
		and Role.IsPvNMode()
		and not bLaneAssignActive
		and not bPvNLaneAssignDone
	then
		if RandomInt(1,8) > 4 then tLaneAssignList[1] = LANE_MID else tLaneAssignList[2] = LANE_MID end
		bPvNLaneAssignDone = true
	end

	return tLaneAssignList;
	
end

end
-- dota2jmz@163.com QQ:2462331592。
