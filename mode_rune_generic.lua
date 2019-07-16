----------------------------------------------------------------------------------------------------
--- The Creation Come From: BOT EXPERIMENT Credit:FURIOUSPUPPY
--- BOT EXPERIMENT Author: Arizona Fauzie 2018.11.21
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=837040016
--- Update by: 决明子 Email: dota2jmz@163.com 微博@Dota2_决明子
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1573671599
--- Link:http://steamcommunity.com/sharedfiles/filedetails/?id=1627071163
----------------------------------------------------------------------------------------------------

if GetBot():IsInvulnerable() or not GetBot():IsHero() or not string.find(GetBot():GetUnitName(), "hero") or  GetBot():IsIllusion() then
	return;
end

local X = {}
local role = require( GetScriptDirectory()..'/FunLib/jmz_role')
local bot = GetBot();
local minute = 0;
local sec = 0;
local closestRune  = -1;
local runeStatus = -1;
local ProxDist = 1600;
local teamPlayers = nil;
local PingTimeGap = 10;
local bottle = nil;

local runeLocation = nil;

local nStopWaitTime = role.GetRuneActionTime();


local hasPingAndSay = false;
local randomInt = RandomInt(1,8);
if randomInt <= 5 then hasPingAndSay = true end;

local ListRune = {
	RUNE_BOUNTY_1,
	RUNE_BOUNTY_2,
	RUNE_BOUNTY_3,
	RUNE_BOUNTY_4,
	RUNE_POWERUP_1,
	RUNE_POWERUP_2
}

local vWaitRuneLocList = {

	[1] = Vector(-4618,586,0); --天辉上
	[2] = Vector(-1595,3733,0); --夜魇上
	[3] = Vector(4074,-876,0); --夜魇下
	[4] = Vector(2314,-3870,0); --天辉下
	


}


function GetDesire()
	
	if GetGameMode() == GAMEMODE_1V1MID 
	then
		return BOT_MODE_DESIRE_NONE;
	end
	
	if GetGameMode() == GAMEMODE_MO and DotaTime() <= 0 then
		return BOT_MODE_DESIRE_NONE;
	end
	
	if teamPlayers == nil then teamPlayers = GetTeamPlayers(GetTeam()) end
	
	if bot:IsIllusion() 
		or bot:IsInvulnerable() 
		or not bot:IsHero() 
		or bot:HasModifier("modifier_arc_warden_tempest_double") 
		or bot:GetCurrentActionType() == BOT_ACTION_TYPE_IDLE 
		or ( GetUnitToUnitDistance(bot, GetAncient(GetTeam())) < 2500 and DotaTime() > 0 )
		or GetUnitToUnitDistance(bot, GetAncient(GetOpposingTeam())) < 4000 
	then
		return BOT_MODE_DESIRE_NONE;
	end
	
	if bot:GetItemInSlot(6) ~= nil
	   and bot:GetItemInSlot(7) ~= nil
	   and bot:GetItemInSlot(8) ~= nil
	then
		return BOT_MODE_DESIRE_NONE;
	end

	minute = math.floor(DotaTime() / 60)
	sec = DotaTime() % 60
	
	if DotaTime() < 39 *60
		and not role.IsPowerRuneKnown()
		and (    GetRuneStatus( RUNE_POWERUP_1 ) == RUNE_STATUS_AVAILABLE 
		      or GetRuneStatus( RUNE_POWERUP_1 ) == RUNE_STATUS_AVAILABLE )
--		      or enemyHasPowerRuneBuff
	then
		role["lasPowerRuneTime"] = DotaTime();
	end
	
	if not X.IsSuitableToPick() then
		return BOT_MODE_DESIRE_NONE;
	end	
	
	if DotaTime() < 0 and not bot:WasRecentlyDamagedByAnyHero(12.0) then 
		return BOT_MODE_DESIRE_MODERATE;
	end	
	
	if DotaTime() > 26 * 30 
		and X.IsUnitAroundLocation(GetAncient(GetTeam()):GetLocation(), 2800) 
	then
		ProxDist = 800;
	else 
		ProxDist = 1800;
	end
	
	closestRune, closestDist = X.GetBotClosestRune();
	if closestRune ~= -1 then
		if closestRune == RUNE_BOUNTY_1 
		   or closestRune == RUNE_BOUNTY_2 
		   or closestRune == RUNE_BOUNTY_3 
		   or closestRune == RUNE_BOUNTY_4 
		then
			
			runeStatus   = GetRuneStatus( closestRune );
			
			if runeStatus == RUNE_STATUS_AVAILABLE 
			then				
				if X.IsEnemyPickRune(bot,closestRune) then return BOT_MODE_DESIRE_NONE; end				
				return X.CountDesire(BOT_MODE_DESIRE_HIGH, closestDist, 3500);
			elseif runeStatus == RUNE_STATUS_UNKNOWN 
			       and closestDist <= ProxDist * 2
				   and DotaTime() > 290
				   and ( (minute % 5 == 0 or (minute % 5 == 1 and minute % 2 == 1)) or ( minute % 5 == 4 and sec > 45 ) )
			    then
					return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist);
			elseif runeStatus == RUNE_STATUS_MISSING 
					and DotaTime() > 4 * 60 
					and ( minute % 5 == 4 and sec > 52 ) 
					and closestDist <= ProxDist * 2 
				then
					return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist * 2);
			elseif X.IsTeamMustSaveRune(closestRune) 
			       and runeStatus == RUNE_STATUS_UNKNOWN 
				   and DotaTime() > 293
				   and ( ( minute % 5 == 0 or (minute % 5 == 1 and minute % 2 == 1)) or ( minute % 5 == 4 and sec > 45 ) )
				then
					return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, 5000);
			end
		else
			runeStatus = GetRuneStatus( closestRune );
			if runeStatus == RUNE_STATUS_AVAILABLE then
				if X.IsEnemyPickRune(bot,closestRune) then return BOT_MODE_DESIRE_NONE; end
				return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist *2.5);
			elseif runeStatus == RUNE_STATUS_UNKNOWN and closestDist <= ProxDist and DotaTime() > 112 then
				return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist);
			elseif runeStatus == RUNE_STATUS_MISSING and DotaTime() > 60 and ( minute % 2 == 1 and sec > 52 ) and closestDist <= ProxDist then
				return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist);
			elseif X.IsTeamMustSaveRune(closestRune) and runeStatus == RUNE_STATUS_UNKNOWN and DotaTime() > 112 and closestDist <= ProxDist *2 then
				return X.CountDesire(BOT_MODE_DESIRE_MODERATE, closestDist, ProxDist *2);
			end
		end	
	end
	
	return BOT_MODE_DESIRE_NONE;
end

function OnStart()
	local bottle_slot = bot:FindItemSlot('item_bottle');
	if bot:GetItemSlotType(bottle_slot) == ITEM_SLOT_TYPE_MAIN then
		bottle = bot:GetItemInSlot(bottle_slot);
	end	
end

function OnEnd()
	bottle = nil;
end

function Think()
	
	if  bot:IsChanneling() 
		or bot:NumQueuedActions() > 0
		or bot:IsCastingAbility()
		or bot:IsUsingAbility()
	then 
		return;
	end

	
	if DotaTime() < 0 then 
	
		local hItemWard = nil;
		local nWardSolt = bot:FindItemSlot('item_ward_observer');
		if nWardSolt >= 0 and nWardSolt <= 8
		then
			hItemWard = bot:GetItemInSlot(nWardSolt);
		end
	
		if hItemWard ~= nil 
		   and DotaTime() < 0
		   and not IsPlayerBot(GetTeamPlayers(GetTeam())[1])
		   and bot:DistanceFromFountain() < 1400
		then  
			if not hasPingAndSay and bot:GetAssignedLane()== LANE_TOP
			then
				bot:ActionImmediate_Ping( bot:GetLocation().x, bot:GetLocation().y, false );				
				local nMessage = "I can't share wards, so I threw it here. :D "
				bot:ActionImmediate_Chat(nMessage,false);
				hasPingAndSay = true;
			end
			
			bot:Action_DropItem(hItemWard, bot:GetLocation() + Vector(-30,-30));
			return;
		end
	
	
		if GetTeam() == TEAM_RADIANT then
			if bot:GetAssignedLane() == LANE_BOT then 
				bot:Action_MoveToLocation( X.GetWaitRuneLocation(RUNE_BOUNTY_3) + RandomVector(121));
				return
			else
				bot:Action_MoveToLocation( X.GetWaitRuneLocation(RUNE_BOUNTY_1) + RandomVector(122));
				return
			end
		elseif GetTeam() == TEAM_DIRE then
			if bot:GetAssignedLane() == LANE_TOP then 
				bot:Action_MoveToLocation( X.GetWaitRuneLocation(RUNE_BOUNTY_4) + RandomVector(123));
				return
			else
				bot:Action_MoveToLocation( X.GetWaitRuneLocation(RUNE_BOUNTY_2) + RandomVector(124));
				return
			end
		end
		return;
	end	
	
	if runeStatus == RUNE_STATUS_AVAILABLE then
		
		if bottle ~= nil and closestDist < 1200 then 
			local bottle_charge = bottle:GetCurrentCharges() 
			if bottle:IsFullyCastable() and bottle_charge > 0 and ( bot:GetHealth() < bot:GetMaxHealth() or bot:GetMana() < bot:GetMaxMana() ) then
				bot:Action_UseAbility( bottle );
				return;
			end
		end
		
		if closestDist > 99 then  -- 128 to pick rune
		   
		    local nAttactRange = bot:GetAttackRange() +90;
			if nAttactRange > 1400 then nAttactRange = 1400 end;
			local nEnemys = bot:GetNearbyHeroes(nAttactRange,true,BOT_MODE_NONE);
			if nEnemys[1] ~= nil and nEnemys[1]:IsAlive() and nEnemys[1]:CanBeSeen()
				and not role.CanBeSupport(bot:GetUnitName())
			then
				bot:Action_AttackUnit(nEnemys[1], true);
				return;
			end
			
			if bot:GetLevel() >= 10 
				and bot:GetUnitName() ~= "npc_dota_hero_antimage"
				and bot:GetPrimaryAttribute() == ATTRIBUTE_AGILITY
			then
				local nCreeps = bot:GetNearbyCreeps(nAttactRange +90,true);
				if nCreeps[1] ~= nil and nCreeps[1]:IsAlive()
				then
					bot:Action_AttackUnit(nCreeps[1], true);
					return;
				end
			end
			
			if X.CouldBlink(bot,GetRuneSpawnLocation(closestRune)) then return end;
			
			bot:Action_MoveToLocation(GetRuneSpawnLocation(closestRune));
			return
		else			
			bot:Action_PickUpRune(closestRune);
			return
		end
	else
		
		local nAttactRange = bot:GetAttackRange() +80;
		if nAttactRange > 1400 then nAttactRange = 1400 end;
		local nEnemys = bot:GetNearbyHeroes(nAttactRange,true,BOT_MODE_NONE);
		if nEnemys[1] ~= nil 
		   and nEnemys[1]:IsAlive() 
		   and nEnemys[1]:CanBeSeen()
		   and bot:GetPrimaryAttribute() ~= ATTRIBUTE_INTELLECT
		then
			bot:Action_AttackUnit(nEnemys[1], true);
			return;
		end
		
		if bot:GetLevel() >= 10 
			and bot:GetUnitName() ~= "npc_dota_hero_antimage"
			and bot:GetPrimaryAttribute() ~= ATTRIBUTE_INTELLECT
		then
			local nCreeps = bot:GetNearbyCreeps(nAttactRange +90,true);
			if nCreeps[1] ~= nil and nCreeps[1]:IsAlive()
			then
				bot:Action_AttackUnit(nCreeps[1], true);
				return;
			end
		end
		
		bot:Action_MoveToLocation(GetRuneSpawnLocation(closestRune));
		return
	end
	
end

function X.GetDistance(s, t)
    return math.sqrt((s[1]-t[1])*(s[1]-t[1]) + (s[2]-t[2])*(s[2]-t[2]));
end

function X.GetXUnitsTowardsLocation( hUnit, vLocation, nDistance)
    local direction = (vLocation - hUnit:GetLocation()):Normalized()
    return hUnit:GetLocation() + direction * nDistance
end

function X.CountDesire(base_desire, dist, maxDist)
	 return base_desire + math.floor((RemapValClamped( dist, maxDist, 0, 0, 1 - base_desire))*40)/40;
end	

function X.GetBotClosestRune()
	local cDist = 100000;	
	local cRune = -1;	
	for _,r in pairs(ListRune)
	do
		local rLoc = GetRuneSpawnLocation(r);
		if not X.IsHumanPlayerNearby(rLoc) 
		   and not X.IsPingedByHumanPlayer(rLoc) 
		   and not X.IsThereMidlaner(rLoc) 
		   and not X.IsThereCarry(rLoc) 
		   and not X.IsMissing(r)
		   and not X.IsKnown(r)
		   and X.IsTheClosestOne(rLoc)
		then
			local dist = GetUnitToLocationDistance(bot, rLoc);
			if dist < cDist then
				cDist = dist;
				cRune = r;
			end	
		end
	end
	return cRune, cDist;
end

function X.IsMissing(r)

	local sec = DotaTime() % 60;
	local runeStatus = GetRuneStatus( r );
	
	if sec < 52 -- here has a bug
		and runeStatus ==  RUNE_STATUS_MISSING
	then
		return true;
	end
	
    return false;
end

function X.IsKnown(r)
	
	if DotaTime() > 39 *60 + 50 then return false end;  
	
	if r == RUNE_POWERUP_1 
		or r == RUNE_POWERUP_2
	then
		local runeStatus = GetRuneStatus( r );
		
		if ( minute % 2 == 0 or sec < 52 )
			and runeStatus == RUNE_STATUS_UNKNOWN
			and role.IsPowerRuneKnown()
		then
			return true;
		end
	
	end

	return false;
end


function X.IsTeamMustSaveRune(rune)
	if GetTeam() == TEAM_DIRE then
		return rune == RUNE_BOUNTY_2 or rune == RUNE_BOUNTY_4 or rune == RUNE_POWERUP_1 or rune == RUNE_POWERUP_2 or DotaTime() > 13 * 60
	else
		return rune == RUNE_BOUNTY_1 or rune == RUNE_BOUNTY_3 or rune == RUNE_POWERUP_1 or rune == RUNE_POWERUP_2 or DotaTime() > 13 * 60
	end
end

function X.IsHumanPlayerNearby(runeLoc)
	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);
		if member ~= nil and not member:IsIllusion() and not IsPlayerBot(v) and member:IsAlive() then
			local dist1 = GetUnitToLocationDistance(member, runeLoc);
			local dist2 = GetUnitToLocationDistance(bot, runeLoc);
			if dist2 < 1200 and dist1 < 1200 then
				return true;
			end
		end
	end
	return false;
end

function X.IsPingedByHumanPlayer(runeLoc)
	local listPings = {};
	local dist2 = GetUnitToLocationDistance(bot, runeLoc);
	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);
		if member ~= nil and not member:IsIllusion() and not IsPlayerBot(v) and member:IsAlive() then
			local ping = member:GetMostRecentPing();
			table.insert(listPings, ping);
		end
	end
	for _,p in pairs(listPings)
	do
		if p ~= nil and not p.normal_ping and X.GetDistance(p.location, runeLoc) < 1200 and dist2 < 1200 and GameTime() - p.time < PingTimeGap then
			return true;
		end
	end
	return false;
end

function X.IsTheClosestOne(r)
	local minDist = GetUnitToLocationDistance(bot, r);
	local closest = bot;
	for k,v in pairs(teamPlayers)
	do	
		local member = GetTeamMember(k);
		if  member ~= nil and not member:IsIllusion() and member:IsAlive() then
			local dist = GetUnitToLocationDistance(member, r);
			if dist < minDist then
				minDist = dist;
				closest = member;
			end
		end
	end
	return closest == bot;
end

function X.IsThereMidlaner(runeLoc)

	if X.IsNotPowerRune(runeLoc) then return false end;

	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);
		if member ~= nil and not member:IsIllusion() and member:IsAlive() and member:GetAssignedLane() == LANE_MID then
			local dist1 = GetUnitToLocationDistance(member, runeLoc);
			local dist2 = GetUnitToLocationDistance(bot, runeLoc);
			if dist2 < 1200 and dist1 < 1200 and bot:GetUnitName() ~= member:GetUnitName() then
				return true;
			end
		end
	end
	
	return false;
end

function X.IsThereCarry(runeLoc)
		
	if X.IsNotPowerRune(runeLoc) then return false end;

	for k,v in pairs(teamPlayers)
	do
		local member = GetTeamMember(k);
		if member ~= nil and not member:IsIllusion() and member:IsAlive() and role.CanBeSafeLaneCarry(member:GetUnitName()) 
		   and ( (GetTeam()==TEAM_DIRE and member:GetAssignedLane()==LANE_TOP) or (GetTeam()==TEAM_RADIANT and member:GetAssignedLane()==LANE_BOT)  )	
		then
			local dist1 = GetUnitToLocationDistance(member, runeLoc);
			local dist2 = GetUnitToLocationDistance(bot, runeLoc);
			if dist2 < 1200 and dist1 < 1200 and bot:GetUnitName() ~= member:GetUnitName() then
				return true;
			end
		end
	end
	
	return false;
end

function X.IsSuitableToPick()
	if X.IsNearRune(bot) then return true end;

	local mode = bot:GetActiveMode();
	local Enemies = bot:GetNearbyHeroes(1300, true, BOT_MODE_NONE);
	if ( mode == BOT_MODE_RETREAT and bot:GetActiveModeDesire() > BOT_MODE_DESIRE_HIGH )
		or ( #Enemies >= 1 and X.IsIBecameTheTarget(Enemies) )
		or ( bot:WasRecentlyDamagedByAnyHero(5.0) and mode == BOT_MODE_RETREAT )
	then
		return false;
	end
	return true;
end

function X.IsIBecameTheTarget(units)
	for _,u in pairs(units) do
		if u:GetAttackTarget() == bot then
			return true;
		end
	end
	return false;
end

function X.IsNearRune(bot)

	for _,r in pairs(ListRune)
	do
		local rLoc = GetRuneSpawnLocation(r);
		if GetUnitToLocationDistance(bot,rLoc) <= 400
		then
			return true;
		end
	end

	return false;

end

function X.IsNotPowerRune(runeLoc)
	
	local rLocOne = GetRuneSpawnLocation(RUNE_POWERUP_1);
	local rLocTwo = GetRuneSpawnLocation(RUNE_POWERUP_2);
	
	if X.GetDistance(rLocOne, runeLoc) >= 600 and X.GetDistance(rLocTwo, runeLoc) >= 600
	then
		return true;
	end
	
	return false;
end

function X.CouldBlink(bot,nLocation)
	
	local blinkSlot = bot:FindItemSlot("item_blink");
	
	if bot:GetItemSlotType(blinkSlot) == ITEM_SLOT_TYPE_MAIN 
	   or bot:GetUnitName() == "npc_dota_hero_antimage"
	then
		local blink = bot:GetItemInSlot(blinkSlot);	
		if bot:GetUnitName() == "npc_dota_hero_antimage"
		then
			blink = bot:GetAbilityByName( "antimage_blink" );
		end
	
		if blink ~= nil 
		   and blink:IsFullyCastable() 
		then
			local bDist = GetUnitToLocationDistance(bot,nLocation);
			local maxBlinkLoc = X.GetXUnitsTowardsLocation(bot, nLocation, 1199 );
			if bDist <= 500
			then
				return false;
			elseif bDist < 1200
				then
					bot:Action_UseAbilityOnLocation(blink, nLocation);
					return true;
			elseif IsLocationPassable(maxBlinkLoc)
				then
					bot:Action_UseAbilityOnLocation(blink, maxBlinkLoc);
					return true;
			end
		end
	end
	
	return false;
end

function X.IsUnitAroundLocation(vLoc, nRadius)
	for i,id in pairs(GetTeamPlayers(GetOpposingTeam())) do
		if IsHeroAlive(id) then
			local info = GetHeroLastSeenInfo(id);
			if info ~= nil then
				local dInfo = info[1];
				if dInfo ~= nil and X.GetDistance(vLoc, dInfo.location) <= nRadius and dInfo.time_since_seen < 1.0 then
					return true;
				end
			end
		end
	end
	return false;
end

function X.IsEnemyPickRune(bot,nRune)
	
	local nEnemys = bot:GetNearbyHeroes(1600,true,BOT_MODE_NONE);
	local runeLocation = GetRuneSpawnLocation( nRune );
	if GetUnitToLocationDistance(bot,runeLocation) < 600 then return false end
	
	for _,enemy in pairs(nEnemys)
	do
		if  enemy ~= nil and enemy:IsAlive()
			and ( enemy:IsFacingLocation(runeLocation,20) or enemy:IsFacingLocation(bot:GetLocation(),20) )
			and GetUnitToLocationDistance(enemy,runeLocation) - 300 < GetUnitToLocationDistance(bot,runeLocation)
		then
			return true;
		end
	end
	
	return false;
end

function X.GetWaitRuneLocation(nRune)

	local vLocation = GetRuneSpawnLocation(nRune);

	if DotaTime() > -nStopWaitTime then return vLocation end
	
	local vNearestLoc = nil;
	local nDist = 99999;
	for _,loc in pairs(vWaitRuneLocList)
	do
		local nLocDist = X.GetDistance(loc,vLocation);
		if nLocDist < nDist
		then
			vNearestLoc = loc;
			nDist = nLocDist;
		end
	end
	
	return vNearestLoc;

end


-- dota2jmz@163.com QQ:2462331592.