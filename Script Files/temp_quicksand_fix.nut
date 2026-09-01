const MASK_PLAYERSOLID_BRUSHONLY = 0x1400B

printl("QUICKSAND FIX LOADED")

::Quicksand <-
{
	UnstuckDelay = 2.0

	function Log(msg)
	{
		msg = format("%.2f temp_quicksand_fix: %s\n", Time(), msg)
		ClientPrint(null, Constants.EHudNotify.HUD_PRINTCONSOLE, msg)
		print(msg)
	}

	function TestUnstuck()
	{
		// Time check is required as scaled humans get stuck too, and this would fire every
		//  loadout swap otherwise.
		if (self.GetModelScale() <= 1.0 || Time() < PotatoSpawnTime || !self.IsAlive())
			return

		local origin = self.GetOrigin()
		local trace =
		{
			start = origin
			end = origin
			hullmin = self.GetPlayerMins()
			hullmax = self.GetPlayerMaxs()
			mask = MASK_PLAYERSOLID_BRUSHONLY
			ignore = self
		}
		TraceHull(trace)

		if (!trace.hit)
			return

		Quicksand.Log("Attempting to unstuck scaled player...")
		// Do more traces for bigger bots.
		local max_traces = ceil(3.0 * self.GetModelScale())

		local dirs =
		[
			Vector(0.0, 0.0, 16.0),  Vector(0.0, 16.0, 0.0),  Vector(16.0, 0.0, 0.0),
			Vector(0.0, 0.0, -16.0), Vector(0.0, -16.0, 0.0), Vector(-16.0, 0.0, 0.0)
		]

		for (local i = 1; i <= max_traces; ++i)
		{
			// Try to find free space, stepping 16 hu per trace.
			foreach (dir in dirs)
			{
				trace.start = origin + dir * i
				trace.end = trace.start
				TraceHull(trace)

				if (trace.hit)
					continue

				self.SetAbsOrigin(trace.end)
				Quicksand.Log("Unstuck success.")
				return
			}
		}
		Quicksand.Log("Unstuck fail.")
	}

	function OnGameEvent_player_spawn(params)
	{
		if (params.team == 0)
			return

		local player = GetPlayerFromUserID(params.userid)

		// Model scale can't be tested here as it is not yet applied.
		player.ValidateScriptScope()
		local scope = player.GetScriptScope()
		scope.PotatoTestUnstuck <- TestUnstuck
		scope.PotatoSpawnTime <- Time() + UnstuckDelay

		EntFireByHandle(GetPlayerFromUserID(params.userid),
			"CallScriptFunction", "PotatoTestUnstuck",
		UnstuckDelay, null, null)
	}

	function OnGameEvent_recalculate_holidays(_)
	{
		for (local i = MaxClients().tointeger(); i > 0; --i)
		{
			local player = PlayerInstanceFromIndex(i)
			if (!player)
				continue

			local scope = player.GetScriptScope()
			if (scope && "PotatoTestUnstuck" in scope)
			{
				delete scope.PotatoTestUnstuck
				delete scope.PotatoSpawnTime
			}
		}
	}
}
__CollectGameEventCallbacks(Quicksand)
