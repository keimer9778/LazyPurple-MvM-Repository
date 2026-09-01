local ROOT = getroottable()

IncludeScript("nopey_lib/nopey_lib", ROOT)
// IncludeScript("popextensions/constants", ROOT)
// IncludeScript("popextensions/botbehavior", ROOT)
IncludeScript("NavAreaBuildPath", ROOT)

if("birded" in ROOT) return

::birded <- {
	function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3) {delete ::birded
																			clean()	} }
	
	function OnGameEvent_player_spawn(params)
	{
		local hPlayer	= GetPlayerFromUserID(params.userid)
		if (hPlayer.IsFakeClient())
		{
			CreateTimer(function() {
				if (hPlayer.HasBotTag("bot_birdie"))
				{
					birded.assign(hPlayer)
				}
				else if (hPlayer.HasBotTag("bot_flying_chicken"))
					birded.assign_chicken(hPlayer)
			}, 0.2)
		}
		else
		{
			ListOfRedPlayers = findAllPlayer(true)
		}
		printl("this runs")
	}
	function OnGameEvent_player_death(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)
		if (hPlayer.IsFakeClient())
		{
			if (hPlayer.HasBotTag("bot_birdie"))
			{
				foreach (bird in ListOfBirds)
					if (bird.isThisGuyYours(hPlayer, "death"))
						break
			}
			else if (hPlayer.HasBotTag("bot_flying_chicken"))
			{
				local index = ListOfChickens.find(hPlayer)
				
				if (index != null)
				{
					ListOfChickens[index].TerminateScriptScope()
					ListOfChickens.remove(index)
				}
			}
			
		}
		
	}
	


	function assign(hBot)
	{
		printl("assign: " + hBot)
		
		ListOfBirds.append( Birdie(hBot) )
	}
	
	ListOfRedPlayers = findAllPlayer(true)
	function assign_chicken(hBot)
	{
		printl("assign_chicken: " + hBot)
		
		hBot.AddCond(72)
		hBot.StunPlayer(10000, 2, TF_STUN_LOSER_STATE, hBot)
		//hBot.AddBotAttribute(IGNORE_ENEMIES)
		hBot.ValidateScriptScope()
		local scope = hBot.GetScriptScope()
		scope.jump_think_time <- 0
		scope.my_ai <- AI_Bot_chicken( hBot )
		
		scope.Think <- function () {
			if ( self.InCond(51) )
				return -1
		
			
			local time = Time()
			if ( jump_think_time < time )
			{
				jump_think_time = time + 0.2
				
				local mypos = hBot.GetOrigin()
				if ( ( birded.GetGround( mypos+ Vector(0,0,10) ) - mypos).LengthSqr() < 200*200)
				{
					self.GetLocomotionInterface().Jump()
				}
			}
			
			my_ai.OnUpdate()
			local target = my_ai.FindClosestThreat(100000000, false)
			if (target)
				self.GetLocomotionInterface().Approach(target.GetOrigin(),999)
			
			return -1
		}
		AddThinkToEnt(hBot, "Think")
		
		ListOfChickens.append( hBot )
	}
	
	function IsInFieldOfView(attacker, target, isAimingAt = false, custom_tolerance = null) {
		local cur_eye_pos = attacker.EyePosition()
		local cur_eye_fwd = attacker.EyeAngles().Forward()
	
		local tolerance = 0.5736 // cos(110/2)
		if ( custom_tolerance != null )
			tolerance = custom_tolerance
		else
			if ( isAimingAt )
				tolerance = 0.999 // cos(2/2)

		local delta = target.GetOrigin() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(delta) >= tolerance)
			return true

		delta = target.GetCenter() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(delta) >= tolerance)
			return true

		delta = target.EyePosition() - cur_eye_pos
		delta.Norm()
		return (cur_eye_fwd.Dot(delta) >= tolerance)
	}
	
	function GetGround( pos )
	{
		
		local trace = {
			start = pos,
			end = pos + Vector( 0, 0, -99999 ),
			mask = MASK_SOLID_BRUSHONLY,
			ignore = null,
		}
		TraceLineEx(trace)
		
		if ( !trace.hit )
		{
			printl("trace failed")
			//return false
		}
		
		//birded.hMarker.SetAbsOrigin(trace.pos)
		return trace.pos
	}
	
	
	function list()
	{
		printl(MedicOne)
		printl(MedicTwo)
	}
	
	function testfunc(input)
	{
		if (input == 0) ListOfPairs[0].MedicOne.hOwner.SetMission(1, true)
		else if (input == 1) ListOfPairs[0].MedicOne.hOwner.SetAttentionFocus(findRandomPlayer())
		else if (input == 2) ListOfPairs[0].MedicOne.hOwner.SetMissionTarget(findRandomPlayer())
	}
	
	
	
	function show()
	{
		foreach (pair in ListOfPairs)
			pair.showMember()
	}
	function showme()
	{
		printl(ListOfPairs.len())
	}
	function clean()
	{
		foreach (player in findAllPlayer()) {
			player.TerminateScriptScope()
		}
	}
	
	a = [1, 2, 3]
	function show2()
	{
		local index = 2
		CreateTimer(function() {printl("hi")
								printl(uberchain.a[index])}, 1)
	}
	function test()
	{
		findRandomPlayer().AcceptInput("SetHUDVisibility", "1", null, null)
	}
	
	ListOfBirds		= []
	ListOfChickens	= []
	MedicOne		= null
	MedicTwo		= null
	EventIndex		= 1
	EventIndexOdd	= 1
	EventIndexEven	= 2
	
	Uberchain_bSwapClassMode	= true
	Uberchain_bAdvanced			= false
	
	testHandle = null
	
	hMarker = SpawnEntityFromTable("prop_dynamic", {
			targetname 	= "pumpk"
			model 		= "models/props_halloween/pumpkin_01.mdl"
			solid		= 0
			origin		= "3100 1000 450"
		})
	//printl("uberchain3.nut is loaded")
	
	
	function testcond() {
		for (local i = 0; i < 300; i++)
		{
			if (findRandomPlayer().InCond(i))
				printl(i)
		}
	}
	function getprop(  )
	{
		local table = {}
		GetTable(findRandomPlayer(), 0, table)
		
		foreach (k,v in table)
			printl(k)
	}
	
}
::Birdie <- class 
{
	hOwner = null
	fly_height	= 90
	target		= null
	AI_Bot_myBirdie	= null
	
	constructor(hOwner)
	{
		this.hOwner = hOwner
		AI_Bot_myBirdie = AI_Bot_birdie( hOwner, fly_height )
		
		this.hOwner.ValidateScriptScope()
		this.hOwner.GetScriptScope().me <- this
		this.hOwner.GetScriptScope().Think <- function()
		{
			return me.Think()
		}
		AddThinkToEnt(this.hOwner, "Think")
		
		this.hOwner.SetAbsOrigin( hOwner.GetOrigin() + Vector( 0, 0, 20 ) )
	}
	function Think()
	{
		if ( !target )
			{} //hOwner.SetAbsVelocity( Vector() )
		else
		{
			local distance = (hOwner.GetOrigin() - target).LengthSqr()
			if (distance < 100 * 100)
			{
				target = null
				return -1
			}
			
			MoveTo( target )
		}
		
		return -1
	}
	
	function MoveTo( pos )
	{
		AI_Bot_myBirdie.OnUpdate()
		AI_Bot_myBirdie.UpdatePathAndMove(pos)
	}
	
	function SetTarget( pos )
	{
		target = pos
	}
	
	function findIndex()
	{
		//printl(uberchain.ListOfPairs.find(this))
		return birded.ListOfBirds.find(this)
	}
	function isThisGuyYours(hPlayer, reason)
	{
		if ( hOwner == hPlayer )
		{
			if (reason == "death")
			{
				hOwner.TerminateScriptScope()
				birded.ListOfBirds.remove(findIndex())
				
			}
			return true		// Yuh Uh
		}
		else
			return false	// Nuh Uh
	}
}


__CollectGameEventCallbacks(birded)


::AI_Bot_birdie <- class {
	function constructor( bot, fly_height ) {
		this.bot       = bot
		this.scope     = bot.GetScriptScope()
		this.team      = bot.GetTeam()
		this.cur_pos	 = bot.GetOrigin()
		this.cur_eye_ang = bot.EyeAngles()
		this.cur_eye_pos = bot.EyePosition()
		this.cur_eye_fwd = bot.EyeAngles().Forward()
		this.locomotion = bot.GetLocomotionInterface()
		
		this.time = Time()
		
		this.path_points = []
		this.path_index = 0
		this.path_areas = {}
		
		this.path_recompute_time = 0.0
		
		//this.navdebug = false
		
		this.fly_height = fly_height
		this.mins = bot.GetBoundingMins()
		this.maxs = bot.GetBoundingMaxs()
	}
	
	bot       = null
	scope     = null
	team      = null
	cur_pos		= null
	cur_eye_ang = null
	cur_eye_pos = null
	cur_eye_fwd = null
	locomotion = null
	
	time = 0
	
	path_points = []
	path_index = 0
	path_areas = {}
	
	path_recompute_time = 0
	
	navdebug = false
	
	unstuck_timeout = 0
	speed = 300
	fly_height = 0
	
	recentPos = []
	mins = Vector()
	maxs = Vector()
	
	pos_start_save = Vector()
	
	function IsAlive(player) {
		return GetPropInt(player, "m_lifeState") == 0
	}
	
	function IsInFieldOfView(target) {
		local tolerance = 0.5736 // cos(110/2)

		local delta = target.GetOrigin() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(target) >= tolerance)
			return true

		delta = target.GetCenter() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(delta) >= tolerance)
			return true

		delta = target.EyePosition() - cur_eye_pos
		delta.Norm()
		return (cur_eye_fwd.Dot(delta) >= tolerance)
	}

	function IsVisible(target) {
		if (target == null) return false
		local trace = {
			start  = bot.EyePosition(),
			end    = target.EyePosition(),
			mask   = MASK_OPAQUE,
			ignore = bot
		}
		TraceLineEx(trace)
		return !trace.hit
	}
	
	function IsThreatVisible(target) {
		return IsInFieldOfView(target) && IsVisible(target)
	}
	
	function GetThreatDistanceSqr(target) {
		return (target.GetOrigin() - cur_pos).LengthSqr()
	}
	
	function FindClosestThreat(min_dist_sqr, must_be_visible = true) {
		local closestThreat = null
		local closestThreatDist = min_dist_sqr

		foreach (player in findAllPlayer(true)) {

			if (player == bot || !IsAlive(player) || player.GetTeam() == team || (must_be_visible && !IsThreatVisible(player))) continue
			
			local disguisedAs = player.GetDisguiseTarget()
			if (disguisedAs && disguisedAs.GetTeam() == team) continue
			
			local dist = GetThreatDistanceSqr(player)
			if (dist < closestThreatDist) {
				closestThreat = player
				closestThreatDist = dist
			}
		}
		return closestThreat
	}
	
	function OnUpdate() {
		cur_pos     = bot.GetOrigin()
		//cur_vel     = bot.GetAbsVelocity()
		//cur_speed   = cur_vel.Length()
		cur_eye_pos = bot.EyePosition()
		cur_eye_ang = bot.EyeAngles()
		cur_eye_fwd = cur_eye_ang.Forward()

		time = Time()

		//SwitchToBestWeapon()
		//DrawDebugInfo()
		
		return -1
	}
	function ResetPath()
	{
		path_areas.clear()
		path_points.clear()
		path_index = null
		path_recompute_time = 0
	}
	function UpdatePathAndMove(target_pos, advanced = false)
	{
		local dist_to_target = (target_pos - cur_pos).Length()
		
		
		if (path_recompute_time < time) {
			ResetPath()
			
			local trace = {
				start = cur_eye_pos,
				end = cur_eye_pos + Vector( 0, 0, -999 ),
				mask = MASK_SOLID_BRUSHONLY,
				ignore = null,
			}
			TraceLineEx(trace)
			
			if ( !trace.hit )
			{
				printl("trace failed")
				return false
			}
			
			birded.hMarker.SetAbsOrigin(trace.pos)
			pos_start_save = trace.pos
			
			local pos_start = trace.pos
			local pos_end   = target_pos

			local area_start = GetNavArea(pos_start, 128.0)
			local area_end   = GetNavArea(pos_end, 128.0)

			if (!area_start)
				area_start = GetNearestNavArea(pos_start, 128.0, false, true)
			if (!area_end)
				area_end   = GetNearestNavArea(pos_end, 128.0, false, true)

			if (!area_start || !area_end)
				return false
			
			// target is in their spawn room, don't bother
			if ( ( bot.GetTeam() == TF_TEAM_RED && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_BLUE ) ) ||
				 ( bot.GetTeam() == TF_TEAM_BLUE && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_RED ) ) )
			{
				if ( GetRoundState() != GR_STATE_TEAM_WIN )
				{
					return false;
				}
			}
			
			if (advanced)
			{
				path_recompute_time = time + 1
				local closestArea = null;
				local functor = CTFBotPathCost(bot, 0)
				
				local result
				try
					result = NavAreaBuildPath(GetCTFNavAreaWrapper(area_start), GetCTFNavAreaWrapper(area_end), pos_end, functor, closestArea, 0.0, team, false)
				catch(e)
				{
					printl(e)
					printl("IT FAILLLEDDD!!!!!!!, TOO EXPENSIVE")
					return false
				}
				
				if ( !result )
				{
					printl("false: can't find a path")
					return false
				}
				else
				{
					ConstructPathToTable(GetCTFNavAreaWrapper(area_end), path_areas)
					//printl("path_areas" + path_areas.len())
				}
			}
			else
			{
				if (!GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, team, false, path_areas))
					return false
			}
			
			if (area_start != area_end && !path_areas.len())
				return false

			// Construct path_points
			else {
				if (advanced)
				{
					//local area = GetCTFNavAreaWrapper(area_end)
					local color = Vector(255,255,255)
					if (getSteamName(bot) == "Medic One")
						color = Vector(255,255,255)
					else
						color = Vector(255,255,0)
					for (local area = GetCTFNavAreaWrapper(area_end); area && area.m_parent; area = area.m_parent)
					{
						path_points.append(PopExtPathPoint(area.area, area.GetCenter(), area.GetParentHow()))
						
						DebugDrawLine_vCol(area.GetCenter(), area.m_parent.GetCenter(), color, true, 2)
					}
					//printl("path_points " + path_points.len())
				}
				else
				{
					//path_points.clear()
					
					path_areas["area"+path_areas.len()] <- area_start
					local area = path_areas["area0"]
					local area_count = path_areas.len()
					
					// Initial run grabbing area center
					for (local i = 0; i < area_count && area; ++i) {
						// Don't add a point for the end area
						if (i > 0)
							path_points.append(PopExtPathPoint(area, area.GetCenter(), area.GetParentHow()))

						area = area.GetParent()
					}
					//printl("path_points " + path_points.len())
				}
				
				path_points.reverse()
				path_points.append(PopExtPathPoint(area_end, pos_end, 9)) // NUM_TRAVERSE_TYPES

				// Go through again and replace center with border point of next area
				local path_count = path_points.len()
				for (local i = 0; i < path_count; ++i) {
					local path_from = path_points[i]
					local path_to = (i < path_count - 1) ? path_points[i + 1] : null

					if (path_to) {
						local dir_to_from = path_to.area.ComputeDirection(path_from.area.GetCenter())
						local dir_from_to = path_from.area.ComputeDirection(path_to.area.GetCenter())

						local to_c1 = path_to.area.GetCorner(dir_to_from)
						local to_c2 = path_to.area.GetCorner(dir_to_from + 1)
						local fr_c1 = path_from.area.GetCorner(dir_from_to)
						local fr_c2 = path_from.area.GetCorner(dir_from_to + 1)

						local minarea = {}
						local maxarea = {}
						if ( (to_c1 - to_c2).Length() < (fr_c1 - fr_c2).Length() ) {
							minarea.area <- path_to.area
							minarea.c1 <- to_c1
							minarea.c2 <- to_c2

							maxarea.area <- path_from.area
							maxarea.c1 <- fr_c1
							maxarea.c2 <- fr_c2
						}
						else {
							minarea.area <- path_from.area
							minarea.c1 <- fr_c1
							minarea.c2 <- fr_c2

							maxarea.area <- path_to.area
							maxarea.c1 <- to_c1
							maxarea.c2 <- to_c2
						}

						// Get center of smaller area's edge between the two
						local vec = minarea.area.GetCenter()
						if (dir_to_from == 0 || dir_to_from == 2) { // GO_NORTH, GO_SOUTH
							vec.y = minarea.c1.y
							vec.z = minarea.c1.z
						}
						else if (dir_to_from == 1 || dir_to_from == 3) { // GO_EAST, GO_WEST
							vec.x = minarea.c1.x
							vec.z = minarea.c1.z
						}

						path_from.pos = vec;
					}
				}
			}
			
			
			// Base recompute off distance to target
			local dist = ceil(dist_to_target / 500.0)
			local mod
			if (advanced)
			{
				// Every 500hu away increase our recompute time by 1s
				mod = 1 * dist
			}
			else
			{
				// Every 500hu away increase our recompute time by 0.1s
				mod = 0.1 * dist
				if (mod > 1) mod = 1
			}

			path_recompute_time = time + mod
		}
		
		if (unstuck_timeout > time)
			return false
		

		if (navdebug) {
			for (local i = 0; i < path_points.len(); ++i) {
				DebugDrawLine(path_points[i].pos, path_points[i].pos + Vector(0, 0, 32), 0, 0, 255, false, 0.075)
			}
			local area = path_areas["area0"]
			local area_count = path_areas.len()

			for (local i = 0; i < area_count && area; ++i) {
				local x = ((area_count - i - 0.0) / area_count) * 255.0
				area.DebugDrawFilled(0, x, 0, 50, 0.075, true, 0.0)

				area = area.GetParent()
			}
		}
		if (!path_points.len())
			return false
		
		if (path_index == null)
			path_index = 0
		
		if ((path_points[path_index].pos - cur_pos).Length() < 64.0) {
			++path_index
			if (path_index >= path_points.len()) {
				ResetPath()
				return
			}
		}

		local point = path_points[path_index].pos + Vector( 0, 0, fly_height);
		
		//ClientPrint(null, 3, format("\x079EC34F%s\x01", point.tostring()))
		//locomotion.Approach(point, 999)
		
		
		local worldMin = cur_pos + bot.GetBoundingMins();
		local worldMax = cur_pos + bot.GetBoundingMaxs();
		
		if (false)
		{
		// find highest standable point
		
		
		local corners = []
		corners.append(worldMin)
		corners.append(Vector( worldMax.x, worldMin.y, worldMin.z ))
		corners.append(Vector( worldMin.x, worldMax.y, worldMin.z ))
		corners.append(Vector( worldMax.x, worldMax.y, worldMin.z ))
		
		local highestZ = -99999
		foreach ( corner in corners )
		{
			local trace = {
				start = corner,
				end = corner + Vector( 0, 0, -999 ),
				mask = MASK_SOLID_BRUSHONLY,
				ignore = null,
			}
			TraceLineEx(trace)
			
			if ( !trace.hit )
			{
				printl("trace failed")
			}
			
			if (trace.pos.z > highestZ)
				highestZ = trace.pos.z
			
		}
		}
		
		
		local dir = (point - cur_pos)
		dir.Norm()
		
		local corners = []
		local diagonal = dir.x * dir.y
		if (diagonal > 0)
		{
			corners.append(Vector( maxs.x, mins.y, maxs.z ))
			corners.append(Vector( mins.x, maxs.y, maxs.z ))
		}
		else if (diagonal < 0)
		{
			local corners = []
			corners.append(Vector( mins.x, mins.y, maxs.z ))
			corners.append( maxs )
		}
		else
		{
		}
		
		// check for collision on our path
		//local isBlocked = false
		foreach ( corner in corners )
		{
			local trace = {
				start = corner + cur_pos,
				end = corner + point,
				mask = MASK_SOLID_BRUSHONLY,
				ignore = null,
			}
			TraceLineEx(trace)
			
			if ( !trace.hit )
			{
				continue
			}
			
			//isBlocked = true
			printl("path is blocked, move downward")
			point += Vector( 0, 0, -fly_height + 5)
			path_points[path_index].pos += Vector( 0, 0, -fly_height + 5)
			
			dir = (point - cur_pos)
			dir.Norm()
			break
		}
		
		local vel = dir * speed
		
		local total = Vector()
		recentPos.append(cur_pos)
		if ( recentPos.len() == 11 )
		{
			foreach ( pos in recentPos )
				total += pos
				
			total *= 1/11.0
			
			
			//printl( (total - cur_pos).LengthSqr())
				
			recentPos.remove(0)
			
			if ( (total - cur_pos).LengthSqr() < 10 )
			{
				vel = Vector(0, 0, -100)
				//bot.SetAbsOrigin( cur_pos + Vector( 0, 0, -10 ) )
				
				//printl("stuck detected, moving to point right away")
				//bot.SetAbsOrigin( pos_start_save + Vector(0,0,10) )
				
				unstuck_timeout = time + 1
				
				recentPos.clear()
			}
		}
		
		
		//printl(vel)
		bot.SetAbsVelocity(vel)
		
		//birded.hMarker.SetAbsOrigin(point)
		return
		
		if (cur_pos.z < point.z - 18 && bot.GetAbsVelocity().Length() < 10)
		{
			locomotion.Jump()
			printl("needed a jump")
		}

		//local look_pos = Vector(point.x, point.y, cur_eye_pos.z);
		//if (threat != null)
		//	LookAt(look_pos, 600.0, 1500.0);
		//else
		//	LookAt(look_pos, 350.0, 600.0);

		// calc lookahead point

		// set eyeang based on lookahead
		// set loco on lookahead if no obstacles found
		// if found obstacle, modify loco
	}
}

::AI_Bot_chicken <- class {
	function constructor( bot ) {
		this.bot       = bot
		this.scope     = bot.GetScriptScope()
		this.team      = bot.GetTeam()
		this.cur_pos	 = bot.GetOrigin()
		this.cur_eye_ang = bot.EyeAngles()
		this.cur_eye_pos = bot.EyePosition()
		this.cur_eye_fwd = bot.EyeAngles().Forward()
		this.locomotion = bot.GetLocomotionInterface()
		
		this.time = Time()
		
		this.path_points = []
		this.path_index = 0
		this.path_areas = {}
		
		this.path_recompute_time = 0.0
		
		//this.navdebug = false
		
	}
	
	bot       = null
	scope     = null
	team      = null
	cur_pos		= null
	cur_eye_ang = null
	cur_eye_pos = null
	cur_eye_fwd = null
	locomotion = null
	
	time = 0
	
	path_points = []
	path_index = 0
	path_areas = {}
	
	path_recompute_time = 0
	
	navdebug = false
	
	
	function IsAlive(player) {
		return GetPropInt(player, "m_lifeState") == 0
	}
	
	function IsInFieldOfView(target) {
		local tolerance = 0.5736 // cos(110/2)

		local delta = target.GetOrigin() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(target) >= tolerance)
			return true

		delta = target.GetCenter() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(delta) >= tolerance)
			return true

		delta = target.EyePosition() - cur_eye_pos
		delta.Norm()
		return (cur_eye_fwd.Dot(delta) >= tolerance)
	}

	function IsVisible(target) {
		if (target == null) return false
		local trace = {
			start  = bot.EyePosition(),
			end    = target.EyePosition(),
			mask   = MASK_OPAQUE,
			ignore = bot
		}
		TraceLineEx(trace)
		return !trace.hit
	}
	
	function IsThreatVisible(target) {
		return IsInFieldOfView(target) && IsVisible(target)
	}
	
	function GetThreatDistanceSqr(target) {
		return (target.GetOrigin() - cur_pos).LengthSqr()
	}
	
	function FindClosestThreat(min_dist_sqr, must_be_visible = true) {
		local closestThreat = null
		local closestThreatDist = min_dist_sqr

		foreach (player in findAllPlayer(true)) {

			if (player == bot || !IsAlive(player) || player.GetTeam() == team || (must_be_visible && !IsThreatVisible(player))) continue
			
			if ( player.IsStealthed() ) continue
			
			local disguisedAs = player.GetDisguiseTarget()
			if (disguisedAs && disguisedAs.GetTeam() == team) continue
			
			local dist = GetThreatDistanceSqr(player)
			if (dist < closestThreatDist) {
				closestThreat = player
				closestThreatDist = dist
			}
		}
		return closestThreat
	}
	
	function OnUpdate() {
		cur_pos     = bot.GetOrigin()
		//cur_vel     = bot.GetAbsVelocity()
		//cur_speed   = cur_vel.Length()
		cur_eye_pos = bot.EyePosition()
		cur_eye_ang = bot.EyeAngles()
		cur_eye_fwd = cur_eye_ang.Forward()

		time = Time()

		//SwitchToBestWeapon()
		//DrawDebugInfo()
		
		return -1
	}
	function ResetPath()
	{
		path_areas.clear()
		path_points.clear()
		path_index = null
		path_recompute_time = 0
	}
	function UpdatePathAndMove(target_pos, advanced = false)
	{
		local dist_to_target = (target_pos - cur_pos).Length()
		
		
		if (path_recompute_time < time) {
			ResetPath()
			
			//birded.GetGround(cur_eye_pos)
			
			//pos_start_save = trace.pos
			
			local pos_start = birded.GetGround(cur_eye_pos)
			local pos_end   = target_pos

			local area_start = GetNavArea(pos_start, 128.0)
			local area_end   = GetNavArea(pos_end, 128.0)

			if (!area_start)
				area_start = GetNearestNavArea(pos_start, 128.0, false, true)
			if (!area_end)
				area_end   = GetNearestNavArea(pos_end, 128.0, false, true)

			if (!area_start || !area_end)
				return false
			
			// target is in their spawn room, don't bother
			if ( ( bot.GetTeam() == TF_TEAM_RED && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_BLUE ) ) ||
				 ( bot.GetTeam() == TF_TEAM_BLUE && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_RED ) ) )
			{
				if ( GetRoundState() != GR_STATE_TEAM_WIN )
				{
					return false;
				}
			}
			
			if (advanced)
			{
				path_recompute_time = time + 1
				local closestArea = null;
				local functor = CTFBotPathCost(bot, 0)
				
				local result
				try
					result = NavAreaBuildPath(GetCTFNavAreaWrapper(area_start), GetCTFNavAreaWrapper(area_end), pos_end, functor, closestArea, 0.0, team, false)
				catch(e)
				{
					printl(e)
					printl("IT FAILLLEDDD!!!!!!!, TOO EXPENSIVE")
					return false
				}
				
				if ( !result )
				{
					printl("false: can't find a path")
					return false
				}
				else
				{
					ConstructPathToTable(GetCTFNavAreaWrapper(area_end), path_areas)
					//printl("path_areas" + path_areas.len())
				}
			}
			else
			{
				if (!GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, team, false, path_areas))
					return false
			}
			
			if (area_start != area_end && !path_areas.len())
				return false

			// Construct path_points
			else {
				if (advanced)
				{
					//local area = GetCTFNavAreaWrapper(area_end)
					local color = Vector(255,255,255)
					if (getSteamName(bot) == "Medic One")
						color = Vector(255,255,255)
					else
						color = Vector(255,255,0)
					for (local area = GetCTFNavAreaWrapper(area_end); area && area.m_parent; area = area.m_parent)
					{
						path_points.append(PopExtPathPoint(area.area, area.GetCenter(), area.GetParentHow()))
						
						DebugDrawLine_vCol(area.GetCenter(), area.m_parent.GetCenter(), color, true, 2)
					}
					//printl("path_points " + path_points.len())
				}
				else
				{
					//path_points.clear()
					
					path_areas["area"+path_areas.len()] <- area_start
					local area = path_areas["area0"]
					local area_count = path_areas.len()
					
					// Initial run grabbing area center
					for (local i = 0; i < area_count && area; ++i) {
						// Don't add a point for the end area
						if (i > 0)
							path_points.append(PopExtPathPoint(area, area.GetCenter(), area.GetParentHow()))

						area = area.GetParent()
					}
					//printl("path_points " + path_points.len())
				}
				
				path_points.reverse()
				path_points.append(PopExtPathPoint(area_end, pos_end, 9)) // NUM_TRAVERSE_TYPES

				// Go through again and replace center with border point of next area
				local path_count = path_points.len()
				for (local i = 0; i < path_count; ++i) {
					local path_from = path_points[i]
					local path_to = (i < path_count - 1) ? path_points[i + 1] : null

					if (path_to) {
						local dir_to_from = path_to.area.ComputeDirection(path_from.area.GetCenter())
						local dir_from_to = path_from.area.ComputeDirection(path_to.area.GetCenter())

						local to_c1 = path_to.area.GetCorner(dir_to_from)
						local to_c2 = path_to.area.GetCorner(dir_to_from + 1)
						local fr_c1 = path_from.area.GetCorner(dir_from_to)
						local fr_c2 = path_from.area.GetCorner(dir_from_to + 1)

						local minarea = {}
						local maxarea = {}
						if ( (to_c1 - to_c2).Length() < (fr_c1 - fr_c2).Length() ) {
							minarea.area <- path_to.area
							minarea.c1 <- to_c1
							minarea.c2 <- to_c2

							maxarea.area <- path_from.area
							maxarea.c1 <- fr_c1
							maxarea.c2 <- fr_c2
						}
						else {
							minarea.area <- path_from.area
							minarea.c1 <- fr_c1
							minarea.c2 <- fr_c2

							maxarea.area <- path_to.area
							maxarea.c1 <- to_c1
							maxarea.c2 <- to_c2
						}

						// Get center of smaller area's edge between the two
						local vec = minarea.area.GetCenter()
						if (dir_to_from == 0 || dir_to_from == 2) { // GO_NORTH, GO_SOUTH
							vec.y = minarea.c1.y
							vec.z = minarea.c1.z
						}
						else if (dir_to_from == 1 || dir_to_from == 3) { // GO_EAST, GO_WEST
							vec.x = minarea.c1.x
							vec.z = minarea.c1.z
						}

						path_from.pos = vec;
					}
				}
			}
			
			
			// Base recompute off distance to target
			local dist = ceil(dist_to_target / 500.0)
			local mod
			if (advanced)
			{
				// Every 500hu away increase our recompute time by 1s
				mod = 1 * dist
			}
			else
			{
				// Every 500hu away increase our recompute time by 0.1s
				mod = 0.1 * dist
				if (mod > 1) mod = 1
			}

			path_recompute_time = time + mod
		}
		
		if (navdebug) {
			for (local i = 0; i < path_points.len(); ++i) {
				DebugDrawLine(path_points[i].pos, path_points[i].pos + Vector(0, 0, 32), 0, 0, 255, false, 0.075)
			}
			local area = path_areas["area0"]
			local area_count = path_areas.len()

			for (local i = 0; i < area_count && area; ++i) {
				local x = ((area_count - i - 0.0) / area_count) * 255.0
				area.DebugDrawFilled(0, x, 0, 50, 0.075, true, 0.0)

				area = area.GetParent()
			}
		}
		if (!path_points.len())
			return false
		
		if (path_index == null)
			path_index = 0
		
		if ((path_points[path_index].pos - birded.GetGround(cur_pos)).Length() < 100.0) {
			++path_index
			if (path_index >= path_points.len()) {
				ResetPath()
				return
			}
		}

		local point = path_points[path_index].pos;
		
		//ClientPrint(null, 3, format("\x079EC34F%s\x01", point.tostring()))
		locomotion.Approach(point, 999)
		

		//local look_pos = Vector(point.x, point.y, cur_eye_pos.z);
		//if (threat != null)
		//	LookAt(look_pos, 600.0, 1500.0);
		//else
		//	LookAt(look_pos, 350.0, 600.0);

		// calc lookahead point

		// set eyeang based on lookahead
		// set loco on lookahead if no obstacles found
		// if found obstacle, modify loco
	}
}

::PopExtPathPoint <- class  {

	constructor( area, pos, how ) {

		this.area = area
		this.pos  = pos
		this.how  = how
	}

	area = null
	pos  = null
	how  = null
}