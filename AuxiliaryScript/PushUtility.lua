local P = {}
local role = require( GetScriptDirectory()..'/FunLib/jmz_role')

P['Locations'] = {
	["RadiantSpawn"]= Vector(-6950,-6275),
	["DireSpawn"]= Vector(7150, 6300),
}

--获取接近的道路
function P.GetLane( nTeam ,hHero )
        local vBot = GetLaneFrontLocation(nTeam, LANE_BOT, 0)
        local vTop = GetLaneFrontLocation(nTeam, LANE_TOP, 0)
        local vMid = GetLaneFrontLocation(nTeam, LANE_MID, 0)
        --print(GetUnitToLocationDistance(hHero, vMid))
        if GetUnitToLocationDistance(hHero, vBot) < 2500 then
            return LANE_BOT
        end
        if GetUnitToLocationDistance(hHero, vTop) < 2500 then
            return LANE_TOP
        end
        if GetUnitToLocationDistance(hHero, vMid) < 2500 then
            return LANE_MID
        end
        return LANE_NONE
end
--这条路是否需要清理
function P.IsThisLaneNeedToClean(npcBot,lane)

	local front = GetLaneFrontLocation( GetTeam(), lane, 0 )
	local AllyTower = P.GetNearestBuilding(GetTeam(), front) --获取所选道路最近的塔
	local DistanceToFront = GetUnitToLocationDistance( npcBot, AllyTower:GetLocation() ) --到塔的距离
	local creeps = GetUnitList( UNIT_LIST_ENEMY_CREEPS ) --所有敌方小兵
	local creepsCount =0
	local creepsAlly = GetUnitList( UNIT_LIST_ALLIED_CREEPS ) --所有我方小兵
	local creepsAllyCount =0
	--获取小兵数量
	for i,creep in pairs(creeps)
	do
		if(GetUnitToLocationDistance(creep,front)<=2500)
		then
			creepsCount=creepsCount+1
		end
	end
	for i,creep in pairs(creepsAlly)
	do
		if(GetUnitToLocationDistance(creep,front)<=2500)
		then
			creepsAllyCount=creepsAllyCount+1
		end
	end
	
	local CountDelta=creepsCount-creepsAllyCount --双方小兵数量差
	local DistanceFactor=DistanceToFront/1500
	
	if DistanceToFront <= 6000 --在6000范围内
	   and DistanceFactor <= CountDelta --每个多出的敌方小兵增加1500判定范围
	then
		--print(npcBot:GetUnitName().." need to clean lane- "..lane)
		return true
	end
	
	return false
end

function P.GetUnitPushLaneDesire(npcBot,lane)
	local team = GetTeam()
	local teamPush = GetPushLaneDesire( lane );

	local levelFactor = 1
	if npcBot:GetLevel() < 6 then
		levelFactor = 0
	end

	local mylane=P.GetLane(team,npcBot)
	if(mylane ~= LANE_NONE)
	then
		local ThisLaneNeedToClean=P.IsThisLaneNeedToClean(npcBot,mylane)
		if(ThisLaneNeedToClean==true and mylane~=lane)
		then
			return 0
		end
	end

	local healthRate = npcBot:GetHealth() / npcBot:GetMaxHealth()
	local manaRate = npcBot:GetMana() / npcBot:GetMaxMana()
	local stateFactor = healthRate * 0.7 + manaRate * 0.3
	local roleFactor =0

	if role.IsPusher(npcBot:GetUnitName())==true then
		roleFactor=roleFactor+0.2;
	elseif role.IsSupport(npcBot:GetUnitName())==true then
		roleFactor=roleFactor+0.1;
	elseif role.IsCarry(npcBot:GetUnitName())==true then
		roleFactor=roleFactor;
	end

	local front = GetLaneFrontLocation( GetTeam(), lane, 0 )
	local DistanceToFront = GetUnitToLocationDistance( npcBot, front ) 
	local nearBuilding = P.GetNearestBuilding(team, front)
	local distBuilding = GetUnitToLocationDistance( nearBuilding, front )
	local distFactor = 0
	local tp = P.IsItemAvailable("item_tpscroll")
	if tp then
		tp = tp:IsFullyCastable()
	end
	local travel = P.IsItemAvailable("item_travel_boots")
	if travel then 
		travel = travel:IsFullyCastable()
	end
	if DistanceToFront <= 1000 or travel then
		distFactor = 1
	elseif DistanceToFront - distBuilding >= 3000 and tp then
		if distBuilding <= 1000 then
			distFactor = 0.7
		elseif distBuilding >= 6000 then
			distFactor = 0
		else
			distFactor = -(distBuilding - 6000) * 0.7 / 5000
		end
	elseif DistanceToFront >= 10000 then
		distFactor = 0
	else
		distFactor = -(DistanceToFront - 10000) / 9000
	end

	local sumFactor=0.2 + 0.2 * levelFactor + 0.2 * stateFactor + 0.2 * distFactor + roleFactor;
	local desire =  math.min(sumFactor * teamPush , 0.8)

	return desire
end

function P.isNocreeps(npcBot,lane)		--判断兵线位置在不在塔前，不要越塔
	local front = GetLaneFrontLocation( GetTeam(), lane, 0 )
	local AllyTower = P.GetNearestBuilding(GetTeam(), front)
	local EnemyTower = P.GetNearestBuilding(GetOpposingTeam(), front)
	local EnemySpawnLocation=P.GetEnemySpawnLocation()
	local MaxDiveLength=500
	local DistanceTowerToEnemyHome=GetUnitToLocationDistance(EnemyTower,EnemySpawnLocation)
	local TowerDistance = GetUnitToUnitDistance(npcBot,EnemyTower)

	if(TowerDistance<GetUnitToUnitDistance(EnemyTower,AllyTower) and P.PointToPointDistance(front,EnemySpawnLocation)<DistanceTowerToEnemyHome-MaxDiveLength) then
		return true;
	end

	return false;
end

function P.getTargetLocation(npcBot,lane)
	local front = GetLaneFrontLocation( GetTeam(), lane, 0 )
	local EnemyTower = P.GetNearestBuilding(GetOpposingTeam(), front)
	local AllyTower = P.GetNearestBuilding(GetTeam(), front)
	local TowerDistance = GetUnitToUnitDistance(npcBot,EnemyTower)
	local EnemySpawnLocation=P.GetEnemySpawnLocation()
	local MaxDiveLength=500
	local DistanceTowerToEnemyHome=GetUnitToLocationDistance(EnemyTower,EnemySpawnLocation)
	local gamma=0;

	if(TowerDistance<1000)
	then
		-- if(lane==LANE_MID) then
		-- 	gamma=-15
		-- end
		return P.GetSafeLocation(npcBot,EnemyTower:GetLocation(),gamma);
	else
		-- if(lane==LANE_MID) then
		-- 	gamma=-5
		-- end
		if(P.PointToPointDistance(front,EnemySpawnLocation)<DistanceTowerToEnemyHome-MaxDiveLength and npcBot:GetLevel()<=12)
		then
			return P.GetSafeLocation(npcBot,AllyTower:GetLocation(),gamma) ;
		else
			return P.GetSafeLocation(npcBot,front,gamma) ;
		end
	end

end

function P.IsCreepAttackTower(creepsNearyTower,EnemyTower)
	if(creepsNearyTower~=nil and #creepsNearyTower>=1)
	then
		for k,v in pairs(creepsNearyTower)
		do
			if(v:GetAttackTarget()==EnemyTower)
			then
				return true;
			end
		end
	end
	return false;
end

function P.IsSafe(npcBot,lane,creepsNearyTower)

	local front = GetLaneFrontLocation( GetTeam(), lane, 0 )
	local EnemyTower = P.GetNearestBuilding(GetOpposingTeam(), front)
	local AllyTower = P.GetNearestBuilding(GetTeam(), front)
	local AllyTowerDistance = GetUnitToUnitDistance(npcBot,AllyTower)
	local TowerDistance = GetUnitToUnitDistance(npcBot,EnemyTower)
	local EnemySpawnLocation=P.GetEnemySpawnLocation()
	local DistanceToEnemyHome=GetUnitToLocationDistance(npcBot,EnemySpawnLocation)
	local MaxDiveLength=500
	local DistanceTowerToEnemyHome=GetUnitToLocationDistance(EnemyTower,EnemySpawnLocation)

	local Safe = false

	if(TowerDistance>1500 or AllyTowerDistance<=700)
	then
		Safe = true
	end

	local CreepMinDistance=99999
	if(creepsNearyTower~=nil and #creepsNearyTower>=2)
	then
		for k,v in pairs(creepsNearyTower)
		do
			local tempDistance=GetUnitToUnitDistance(v,EnemyTower)
			if(tempDistance<CreepMinDistance)
			then
				CreepMinDistance=tempDistance
			end
		end
		if(TowerDistance<CreepMinDistance or DistanceToEnemyHome<DistanceTowerToEnemyHome-MaxDiveLength)
		then
			Safe = false
		else
			Safe = true
		end
	end

	return Safe;
end

function P.tryTP( npcBot,lane )
	local team = GetTeam()
	local front = GetLaneFrontLocation( team, lane, 0 )
	local DistanceToFront = GetUnitToLocationDistance( npcBot, front ) 
	local nearBuilding = P.GetNearestBuilding(team, front)
	local distBuilding = GetUnitToLocationDistance( nearBuilding, front )
	local Amount=GetAmountAlongLane(lane,npcBot:GetLocation())
	local DistanceToLane=Amount.distance
	local tp = P.IsItemAvailable("item_tpscroll")
	if not tp or not tp:IsFullyCastable() then 
		tp = nil
	end
	local travel = P.IsItemAvailable("item_travel_boots")
	if not travel or not travel:IsFullyCastable() then 
		travel = nil
	end
	if DistanceToFront > 4000 then
		if travel then
			npcBot:Action_UseAbilityOnLocation( travel, front )
			return true
		elseif tp and DistanceToFront - distBuilding > 3000 and DistanceToLane >3000 then
			npcBot:Action_UseAbilityOnLocation( tp, front )
			return true
		end
	end
	return false;
end

function P.getCreepsNearTower(npcBot,tower)
	local creeps = {}
	for k,v in pairs(npcBot:GetNearbyCreeps(1600,false))
	do
		if(GetUnitToUnitDistance(v,EnemyTower)<800)
		then
			table.insert(creeps,v)
		end
	end
	return creeps
end

function P.getMyTarget(npcBot,lane,TargetLocation)
	local team = GetTeam()
	local front = GetLaneFrontLocation( team, lane, 0 )
	local EnemyTower = P.GetNearestBuilding(GetOpposingTeam(), front)
	local TowerDistance = GetUnitToUnitDistance(npcBot,EnemyTower)

	local EnemySpawnLocation=P.GetEnemySpawnLocation()	--Do not dive tower
	local DistanceTowerToEnemyHome=GetUnitToLocationDistance(EnemyTower,EnemySpawnLocation)
	local MaxDiveLength=500

	local creeps = npcBot:GetNearbyCreeps(1000,true);
	if(creeps~=nil and #creeps>=1 and (GetUnitToLocationDistance(npcBot,TargetLocation)<=200 or TowerDistance<=800))
	then
		if(GetUnitToLocationDistance(target,EnemySpawnLocation)<DistanceTowerToEnemyHome-MaxDiveLength)	--This location is diving tower, do not make yourself in dangerous.
		then
			return creeps[1];
		end
	end
	return nil;
end

function P.UnitPushLaneThink(npcBot,lane)
	if (npcBot:IsChanneling() or npcBot:IsUsingAbility() or npcBot:GetQueuedActionType(0) == BOT_ACTION_TYPE_USE_ABILITY) then
		return;
	end
	
	P.tryTP(npcBot,lane);								--use tp to push quickly

	local team = GetTeam()
	local front = GetLaneFrontLocation( team, lane, 0 )
	local EnemyTower = P.GetNearestBuilding(GetOpposingTeam(), front)
	local TowerDistance = GetUnitToUnitDistance(npcBot,EnemyTower)
	
	local creepsNearyTower = P.getCreepsNearTower(npcBot,EnemyTower);
	local TargetLocation = P.getTargetLocation(npcBot,lane)		--Scatter station to avoid AOE
	local CreepAttackTower = P.IsCreepAttackTower(creepsNearyTower,EnemyTower)
	local Safe = P.IsSafe(npcBot,lane,creepsNearyTower);
	local Nocreeps=P.isNocreeps(npcBot,lane)

	
	--print(P.getShortName(npcBot).."\tCreepAttackTower: "..tostring(CreepAttackTower).." Safe:"..tostring(Safe).." NoCreeps:"..tostring(Nocreeps))

	local enemys = npcBot:GetNearbyHeroes(1000,true,BOT_MODE_NONE)
	
	local target=P.getMyTarget(npcBot,lane,TargetLocation)

	if target~=nil then
		TargetLocation=P.GetSafeLocation(npcBot,target:GetLocation(),0)
	end
	

	local goodSituation=true;

	if(npcBot:GetLevel()>=12 and npcBot:GetHealth()>=1500)
	then
		goodSituation=true;
	elseif ((Safe==false or Nocreeps==true) and EnemyTower:GetHealth()/EnemyTower:GetMaxHealth()>=0.2)
	then
		goodSituation=false;
	end

	local MinDelta=200
	
	if(P.IsEnemyTooMany()) then
		P.AssmbleWithAlly(npcBot)
	elseif goodSituation==false then
		P.StepBack( npcBot )
		--print(P.getCurrentFileName().." "..P.getShortName(npcBot).." situation is not good");
	elseif npcBot:WasRecentlyDamagedByTower(1) then		--if I'm under attck of tower, then try to avoid attack
		if(not P.TransferHatred( npcBot ) or (enemys~=nil and #enemys>=1))
		then
			P.StepBack( npcBot )
			--print(P.getCurrentFileName().." "..P.getShortName(npcBot).." attacked");
		end
	elseif GetUnitToLocationDistance(npcBot,TargetLocation)>=MinDelta then
		npcBot:Action_MoveToLocation(TargetLocation);
	elseif target then
		npcBot:Action_AttackUnit( target, true )
	elseif TowerDistance <= 1200 then
		if (CreepAttackTower) then
			npcBot:Action_AttackUnit( EnemyTower, false )
		else
			--print(P.getCurrentFileName().." "..P.getShortName(npcBot).." tower distance too high");
			P.StepBack( npcBot )
		end
	else
		npcBot:Action_MoveToLocation(TargetLocation);
	end
	return true
end

-- function IsLocationSafeToAttack(location)
	-- local MaxDiveLength=200
	-- if(TowerDistance<CreepMinDistance or DistanceToEnemyHome<DistanceTowerToEnemyHome-MaxDiveLength)
	-- then
		-- Safe = false
	-- end
-- end

function P.GetEnemySpawnLocation()
	if GetTeam() == TEAM_RADIANT then
		return P.Locations.DireSpawn
	else
		return P.Locations.RadiantSpawn
	end
end

function P.GetAllySpawnLocation()
	if GetTeam() == TEAM_RADIANT then
		return P.Locations.RadiantSpawn
	else
		return P.Locations.DireSpawn
	end
end

function P.GetSafeLocation(npcBot,BasicLocation,gamma)
	local EnemyTeam = GetOpposingTeam()
	local Allys = npcBot:GetNearbyHeroes(1600,false,BOT_MODE_NONE)
	local enemys = npcBot:GetNearbyHeroes(1600,true,BOT_MODE_NONE)
	local MyAttackRange=npcBot:GetAttackRange()
	
	local RangeConstant=175
	local RandomInt=0
	local IsRange
	if(MyAttackRange>RangeConstant)
	then
		IsRange=true
		RandomInt=25
		--MyAttackRange=MyAttackRange-25
	else
		IsRange=false
		RandomInt=0
		--MyAttackRange=MyAttackRange+25
	end
	
	local ids = {}
	local MinDamageHeroID
	local MinDamage=1000
	for k,v in pairs(Allys)
	do
		local damage=v:GetAttackDamage()
		local AttackRange=v:GetAttackRange()
		if(damage<MinDamage and role.IsSupport(v:GetUnitName()) and AttackRange>RangeConstant)
		then
			MinDamage=damage
			MinDamageHeroID=v:GetPlayerID()
		end
	end
	
	for k,v in pairs(Allys)
	do
		local IsRange2=false
		if(v:GetAttackRange()>RangeConstant)
		then
			IsRange2=true
		end
		if(IsRange==IsRange2)
		then
			table.insert(ids,v:GetPlayerID())
		end
	end
	table.sort(ids)

	if(MinDamageHeroID==npcBot:GetPlayerID() and #Allys>=3 and #enemys~=0)
	then
		MyAttackRange=800
	end

	local alpha
	if(npcBot:GetAttackRange()>RangeConstant)
	then
		alpha=210
	else
		alpha=300
	end
	local spawnloc=P.GetEnemySpawnLocation()
	local DistanceToEnemyHome=GetUnitToLocationDistance(npcBot,spawnloc)
	local DistanceToHome=npcBot:DistanceFromFountain() 
	local UnitVector
	if(DistanceToEnemyHome-DistanceToHome<0)
	then
		UnitVector=P.GetUnitVector(spawnloc,BasicLocation)
	else
		UnitVector=P.GetUnitVector(BasicLocation,P.GetAllySpawnLocation())
	end
	
	--DebugDrawLine( spawnloc, BasicLocation, 100, 0, 100 ) 
	local theta=math.deg(math.atan2(UnitVector.y,UnitVector.x))
	if(theta<0)
	then
		theta=theta+360
	end
	local myid=npcBot:GetPlayerID()
	local myNumber=1
	for k,v in pairs(ids)
	do
		if(myid==v)
		then
			myNumber=k
		end
	end
	
	local delta=math.rad(theta-alpha/2+alpha/(#ids+1)*myNumber+gamma)
	local FinalVector=Vector(math.cos(delta),math.sin(delta))
	local TargetLocation=BasicLocation+MyAttackRange*FinalVector
	--DebugDrawLine( BasicLocation, TargetLocation, 255, 0, 0 ) 
	
	return TargetLocation --+ RandomVector( RandomInt ) 
end

function P.IsItemAvailable(item_name)
    local npcBot = GetBot();

    for i = 0, 5, 1 do
        local item = npcBot:GetItemInSlot(i);
		if (item~=nil) then
			if(item:GetName() == item_name) then
				return item;
			end
		end
    end
    return nil;
end

function P.GetUnitVector(vMyLocation,vTargetLocation)
	return (vTargetLocation-vMyLocation)/P.PointToPointDistance(vMyLocation,vTargetLocation)
end

function P.PointToPointDistance(p1, p2)
	return math.sqrt(( p1.x - p2.x ) ^ 2 + ( p1.y - p2.y ) ^ 2 )
end

function P.GetPointDistanceSqu(p1, p2)
	return ( p1.x - p2.x ) ^ 2 + ( p1.y - p2.y ) ^ 2 
end
--获得最近的建筑
function P.GetNearestBuilding(team, location)
	local buildings = P.GetAllBuilding( team, location )
	local minDist = 16000 ^ 2
	local nearestBuilding = nil
	for k,v in pairs(buildings) do
		local DistanceToFront = P.GetPointDistanceSqu(location, v:GetLocation())
		if DistanceToFront < minDist then
			if(team==GetTeam() or v:IsInvulnerable()==false)
			then
				minDist = DistanceToFront
				nearestBuilding = v
			end
		end
	end
	return nearestBuilding
end

function P.GetAllBuilding( team,location )
	local buildings = {}
	for i=0,10 do
		local tower = GetTower(team,i)
		if P.NotNilOrDead(tower) then
			table.insert(buildings,tower)
		end
	end

	for i=0,5 do
		local barrack = GetBarracks( team, i )
		if P.NotNilOrDead(barrack) then
			table.insert(buildings,barrack)
		end
	end

	for i=0,4 do
		local shrine = GetShrine(team, i) 
		if P.NotNilOrDead(shrine) then
			table.insert(buildings,shrine)
		end 
	end

	local ancient = GetAncient( team )
	table.insert(buildings,ancient)
	return buildings
end

function P.NotNilOrDead(unit)
	if unit==nil or unit:IsNull() then
		return false;
	end
	if unit:IsAlive() then
		return true;
	end
	return false;
end

function P.GetWeakestCreep(r)
	local npcBot = GetBot();
	r=math.min(1600,r)
	local EnemyCreeps = npcBot:GetNearbyLaneCreeps(r,true);
	
	if EnemyCreeps==nil or #EnemyCreeps==0 then
		return nil,10000;
	end
	
	local WeakestCreep=nil;
	local LowestHealth=10000;
	
	for _,creep in pairs(EnemyCreeps) do
		if creep~=nil and creep:IsAlive() then
			if creep:GetHealth()<LowestHealth then
				LowestHealth=creep:GetHealth();
				WeakestCreep=creep;
			end
		end
	end
	
	return WeakestCreep,LowestHealth;
end
	
function P.TransferHatred( unit )
	if not P.NotNilOrDead(unit) then
		return false
	end

	local towers = unit:GetNearbyTowers( 1000, true )
	local tower
	if towers and #towers > 0 then
		tower = towers[1]
	end
    local creeps = unit:GetNearbyCreeps( 1500, false )
	-- print("hurt",#creeps)
	for k,creep in pairs(creeps) do
		if P.NotNilOrDead(creep) and P.NotNilOrDead(tower) and GetUnitToUnitDistance(tower, creep)<=tower:GetAttackRange() then
			unit:Action_AttackUnit( creep, true )
			return true
		end
	end 
	return false
end

function P.AssmbleWithAlly(unit)
	if not P.NotNilOrDead(unit) then
		return
	end

	local team = GetTeam()
	local lane = P.GetLane(team,unit)
	local MaxDesire=0;
	local MaxDesireLane=lane;
	local lanes={ LANE_TOP,LANE_MID,LANE_BOT };
	for k,v in pairs(lanes) do
		if(v~=lane) then
			local desire=GetPushLaneDesire( v );
			if(desire>MaxDesire) then
				MaxDesire=desire;
				MaxDesireLane=v;
			end
		end
	end

	local TPresult=P.tryTP(unit,MaxDesireLane)
	if(TPresult==false)
	then
		P.StepBack( unit );
	else
		print(P.getCurrentFileName().." "..P.getShortName(unit).."'s enemy is too much, fall back. try tp "..tostring(TPresult) )
	end
	
end

function P.StepBack( unit )
	if not P.NotNilOrDead(unit) then
		return
	end
	
	local team = GetTeam()
	local lane = P.GetLane(team,unit)
	local front = GetLaneFrontLocation( team, lane, 0 )
	local AllyTower = P.GetNearestBuilding(team, front)
	local spawnloc = AllyTower:GetLocation();
	-- local spawnloc
	-- if team == TEAM_RADIANT then
		-- spawnloc = P.Locations.RadiantSpawn
	-- else
		-- spawnloc = P.Locations.DireSpawn
	-- end

	local targetloc = P.Normalized(spawnloc - unit:GetLocation()) * 500 + unit:GetLocation()
	unit:Action_MoveToLocation(targetloc+RandomVector( 100 ) )
end
	
function P.Normalized(vector)
	local mod = ( vector.x ^ 2 + vector.y ^ 2 ) ^ 0.5
	return Vector(vector.x / mod, vector.y / mod)
end

function P.getShortName( npcTarget )
	return string.sub( string.gsub(npcTarget:GetUnitName(),"npc_dota_hero_",""), 1,8 ) 
end

function P.IsEnemyTooMany()
	local npcBot=GetBot()
	local MyLane=P.GetLane(GetTeam(),npcBot)
	if (MyLane==LANE_NONE)
	then
		return false
	end
	
	local AllyCount=0
	local EnemyCount=0
	local allies = GetUnitList(UNIT_LIST_ALLIED_HEROES)
	local enemies = P.GetEnemyTeam()
	for _,ally in pairs(allies) do
		local Lane=P.GetLane(GetTeam(),ally)
		if P.NotNilOrDead(ally) and GetUnitToUnitDistance(npcBot,ally)<1600 and MyLane==Lane then
			AllyCount=AllyCount+1
		end
	end

	for _,enemy in pairs(enemies) do
		local Lane=P.GetLane(GetTeam(),enemy)
		if P.NotNilOrDead(enemy) and GetUnitToUnitDistance(npcBot,ally)<3000 and MyLane==Lane then
			EnemyCount=EnemyCount+1
		end
	end
	
	if(EnemyCount>AllyCount)
	then
		return true
	else
		return false
	end
end

function P.getCurrentFileName()
	return P.strippath(debug.getinfo(1,'S').source:sub(2))
end

function P.strippath(filename)
	if filename:match(".-/.-") then  
		return string.match(filename, ".+/([^/]*%.%w+)$")
	elseif filename:match(".-\\.-") then  
		return string.match(filename, ".+\\([^\\]*%.%w+)$")
	else  
		return ''  
	end  
 
end  


local EnemyHeroListTimer=-1000;
local EnemyHeroList=nil;

function P.GetRealHero(Candidates)
	if Candidates==nil or #Candidates==0 then
		return nil;
	end

	local q=false;
	for i,unit in pairs(Candidates) do
		if unit.isIllusion==nil or (not unit.isIllusion) then
			q=true;
		end
	end

	if not q then
		for i,unit in pairs(Candidates) do
			if unit.isRealHero~=nil and unit.isRealHero then
				return i,unit;
			end
		end
		return nil;
	end

	for i,unit in pairs(Candidates) do
		if unit:HasModifier("modifier_bloodseeker_thirst_vision") then
			return i,unit;
		end
	end

	for i,unit in pairs(Candidates) do
		local int = unit:GetAttributeValue(2);
		local baseRegen=0.01;
		if unit:GetUnitName()==npc_dota_hero_techies then
			baseRegen=0.02;
		end

		if math.abs(unit:GetManaRegen()-(baseRegen+0.04*int))>0.001 then
			return i,unit;
		end
	end

	local hpRegen=Candidates[1]:GetHealthRegen();
	local suspectind=1;
	local suspect=Candidates[1];

	for i,unit in pairs(Candidates) do
		if hpRegen<unit:GetHealthRegen() then
			suspect=unit;
			hpRegen=unit:GetHealthRegen();
			suspectind=i;
		end
	end

	for _,unit in pairs(Candidates) do
		if hpRegen>unit:GetHealthRegen() then
			return suspectind,suspect;
		end
	end

	for i,unit in pairs(Candidates) do
		if unit:IsUsingAbility() or unit:IsChanneling() then
			return i,unit;
		end
	end

	if #Candidates==1 and (Candidates[1].isIllusion==nil or (not Candidates[1].isIllusion)) then
		return 1,Candidates[1];
	end

	return nil;
end

function P.GetEnemyTeam()
	if EnemyHeroList~=nil and DotaTime()-EnemyHeroListTimer<0.1 then
		return EnemyHeroList;
	end

	EnemyHeroListTimer=DotaTime();
	EnemyHeroList={}

	for _,unit in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
		local q=false;
		for _,unit2 in pairs(EnemyHeroList) do
			if unit2:GetUnitName()==unit:GetUnitName() then
				q=true;
			end
		end

		if not q then
			local skip=false;
			if not P.NotNilOrDead(unit) then
				skip=true;
			end
--			if unit.isRealHero~=nil and unit.isRealHero then
--				table.insert(EnemyHeroList,unit);
--				skip=true;
--			end
--			if unit.isIllusion~=nil and unit.isIllusion then
--				skip=true;
--			end

			if not skip then
				local candidates={};
				for _,unit2 in pairs(GetUnitList(UNIT_LIST_ENEMY_HEROES)) do
					if P.NotNilOrDead(unit2) and unit2:GetUnitName() == unit:GetUnitName() then
						table.insert(candidates,unit2);
					end
				end

				local ind,hero=P.GetRealHero(candidates);
				if hero~=nil and (hero.isIllusion==nil or (not hero.isIllusion)) then
					for _,can in pairs(candidates) do
						can.isIllusion=true;
						can.isRealHero=false;
					end

					hero.isIllusion=false;
					hero.isRealHero=true;

					table.insert(EnemyHeroList,hero);
				end
			end
		end
	end

	return EnemyHeroList;
end

return P