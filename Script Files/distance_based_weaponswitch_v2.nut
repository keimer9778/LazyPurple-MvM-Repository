::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

// wrapping for some other class methods
if (!("ConstantNamingConvention" in ROOT))
	foreach (a,b in Constants)
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}

foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

// Note: the folding was done with this being a large file in mind (in the future)


::BaseBoss <- {
	// Main logic
	function IsVisibleCustom(user, target) {
		// a trace, aka drawing a line from the player to the target to see if they can see each other
		local trace = {
			start  = user.EyePosition(),
			end    = target.EyePosition(),
			mask   = 16513,
			ignore = user
		}
		TraceLineEx(trace)
		return !trace.hit
	}
	function WeaponSwitchCustom(hPlayer, slot) {
		hPlayer.RemoveCustomAttribute("disable weapon switch")
		hPlayer.Weapon_Switch(GetPropEntityArray(hPlayer, "m_hMyWeapons", slot))
		hPlayer.AddCustomAttribute("disable weapon switch", 1, -1)
	}
	function FindNearestVisibleThreat(hBot)
	{
		local center = hBot.GetCenter()
		local opposite_team = (hBot.GetTeam() == Constants.ETFTeam.TF_TEAM_PVE_DEFENDERS) ? 
			Constants.ETFTeam.TF_TEAM_PVE_INVADERS : Constants.ETFTeam.TF_TEAM_PVE_DEFENDERS
		// small ternary to get the opposite team
		local closest = null
		local closestDist = 1e18

		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local ply = PlayerInstanceFromIndex(i)
			// iterating through all players and checking distance, closest dist right now is very large
			if (ply && ply.GetTeam() == opposite_team && BaseBoss.IsVisibleCustom(hBot, ply))
			{
				local d = (center - ply.GetOrigin()).Length()
				if (d < closestDist)
				{
					// if player dist is smaller than current closest dist, change closest player
					closestDist = d
					closest = ply
				}
			}
		}
		return [closest, closestDist]
	}
	// Events & Hooks
	function Util_ProcessPlayer(hEntity)
	{
		if (hEntity.IsBotOfType(TF_BOT_TYPE) && hEntity.HasBotTag("bot_chief"))
		{

			hEntity.ValidateScriptScope()
			// validating scope - if the scope doesnt exist, create a new one for the entity (if it already exist it does nothing)
			local hScope = hEntity.GetScriptScope()
			// getting the script scope so we can define some variables and the think function itself inside of the entity

			hScope.PRIMARY_SLOT <- 0
			hScope.SECONDARY_SLOT <- 1
			hScope.MELEE_SLOT <- 2

			hScope.MELEE_DISTANCE     <- [0.0,   200.0]
			hScope.SECONDARY_DISTANCE <- [600.01, 9999]
			hScope.PRIMARY_DISTANCE   <- [200.01, 600.0]

			// this function will run every tick
			hScope.Think <- function() {
				if (NetProps.GetPropInt(self, "m_lifeState") != 0)
				{
					// clean up the think function after the bot dies, so it doesn't leak onto the next bot - player has a persisting entity scope that does not get reset on death or on map restart
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
					return -1
				}

				// find the nearest player that is visible (visible aka can be traced, not that the bot is actually targetting it)
				local info = BaseBoss.FindNearestVisibleThreat(self)
				local target = info[0] // this is the player handle
				local distance = info[1] // this is the distance
				if (!target) return -1
				// if target is null, we go onto the next iteration of the think
				local slot = hScope.PRIMARY_SLOT
				if (distance >= hScope.MELEE_DISTANCE[0] && distance <= hScope.MELEE_DISTANCE[1]) {
					slot = hScope.MELEE_SLOT
				} else if (distance >= hScope.SECONDARY_DISTANCE[0] && distance <= hScope.SECONDARY_DISTANCE[1]) {
					slot = hScope.SECONDARY_SLOT
				} else if (distance >= hScope.PRIMARY_DISTANCE[0] && distance <= hScope.PRIMARY_DISTANCE[1]) {
					slot = hScope.PRIMARY_SLOT
				}

				BaseBoss.WeaponSwitchCustom(self, slot)
				// -1 - function will run every tick
				return -1
			}
			AddThinkToEnt(hEntity, "Think")
		}
		else if (hEntity.IsBotOfType(TF_BOT_TYPE) && hEntity.HasBotTag("bot_switcher_attack"))
		{

			hEntity.ValidateScriptScope()
			// validating scope - if the scope doesnt exist, create a new one for the entity (if it already exist it does nothing)
			local hScope = hEntity.GetScriptScope()
			// getting the script scope so we can define some variables and the think function itself inside of the entity

			hScope.PRIMARY_SLOT <- 0
			hScope.SECONDARY_SLOT <- 1
			hScope.MELEE_SLOT <- 2

			hScope.MELEE_DISTANCE     <- [0.0,   200.0]
			hScope.SECONDARY_DISTANCE <- [200.01, 500.0]
			hScope.PRIMARY_DISTANCE   <- [500.01, 9999]

			// this function will run every tick
			hScope.Think <- function() {
				if (NetProps.GetPropInt(self, "m_lifeState") != 0)
				{
					// clean up the think function after the bot dies, so it doesn't leak onto the next bot - player has a persisting entity scope that does not get reset on death or on map restart
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "")
					return -1
				}

				// find the nearest player that is visible (visible aka can be traced, not that the bot is actually targetting it)
				local info = BaseBoss.FindNearestVisibleThreat(self)
				local target = info[0] // this is the player handle
				local distance = info[1] // this is the distance
				if (!target) return -1
				// if target is null, we go onto the next iteration of the think
				local slot = hScope.PRIMARY_SLOT
				if (distance >= hScope.MELEE_DISTANCE[0] && distance <= hScope.MELEE_DISTANCE[1]) {
					slot = hScope.MELEE_SLOT
				} else if (distance >= hScope.SECONDARY_DISTANCE[0] && distance <= hScope.SECONDARY_DISTANCE[1]) {
					slot = hScope.SECONDARY_SLOT
				} else if (distance >= hScope.PRIMARY_DISTANCE[0] && distance <= hScope.PRIMARY_DISTANCE[1]) {
					slot = hScope.PRIMARY_SLOT
				}

				BaseBoss.WeaponSwitchCustom(self, slot)
				// -1 - function will run every tick
				return -1
			}
			AddThinkToEnt(hEntity, "Think")
		}
	}
	function OnGameEvent_player_spawn(params)
	{
		local hEntity = GetPlayerFromUserID(params.userid)
		if (!hEntity || !hEntity.IsValid()) return
		// delay the processing function by 0.1 seconds - right now the player handle is still missing the information so it must be delayed until everything is applied
		EntFireByHandle(hEntity, "RunScriptCode", "BaseBoss.Util_ProcessPlayer(self)", 0.1, null, null)
	}
    function OnGameEvent_recalculate_holidays(_)
	{
		if (GetRoundState() == Constants.ERoundState.GR_STATE_PREROUND && "BaseBoss" in getroottable())
			delete ::BaseBoss
	}
	function OnGameEvent_mvm_wave_complete(_)
	{
		if ("BaseBoss" in getroottable())
			delete ::BaseBoss
	}
}
__CollectGameEventCallbacks(::BaseBoss)