local PushUtility = require( GetScriptDirectory()..'/AuxiliaryScript/PushUtility')

local bot = GetBot()
local lane = LANE_BOT

function GetDesire()
	return PushUtility.GetUnitPushLaneDesire(bot, lane)
end

function Think()
	return PushUtility.UnitPushLaneThink(bot, lane)
end