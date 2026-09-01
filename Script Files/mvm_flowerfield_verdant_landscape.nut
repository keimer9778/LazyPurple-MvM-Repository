::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

if (!("ConstantNamingConvention" in ROOT))
{
	foreach (a, b in Constants)
	{
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0;
			ROOT[k] <- v != null ? v : 0;
		}
	}
}

foreach(k, v in ::Entities.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::Entities[k].bindenv(::Entities);
	}
}

foreach(k, v in ::NetProps.getclass())
{
	if (k != "IsValid" && !(k in ROOT))
	{
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps);
	}
}

::VerdantLandscape <-
{
	function CleanUp()
	{
		delete ::VerdantLandscape;
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		CleanUp();
	}

	function OnGameEvent_mvm_begin_wave(params)
	{
		local interface = Entities.FindByClassname(null, "point_populator_interface");
		if (interface == null)
		{
			SpawnEntityFromTable("point_populator_interface", { targetname = "pop_interface" });
		}
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		CleanUp();
	}

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (!IsPlayerABot(player) && params.team != 3)
		{
			return
		}
		player.TerminateScriptScope();
		NetProps.SetPropString(player, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(player, null);
		EntFireByHandle(player, "RunScriptCode", "VerdantLandscape.TagCheck(self)", 0.6, null, null)
	}

	function TagCheck(player)
	{
		local tags = {};
		player.GetAllBotTags(tags);
		foreach (tag in tags)
		{
			if (tag.find("sergeant_laser_walls") != null)
			{
				player.ValidateScriptScope();
				local scope = player.GetScriptScope();
				scope.Phase <- 0;
				scope.Think <- function()
				{
					if (player.GetTeam() != 3  || !player.IsAlive())
					{
						player.TerminateScriptScope();
						NetProps.SetPropString(player, "m_iszScriptThinkFunction", "");
						AddThinkToEnt(player, null);
						return 0;
					}

					if (scope.Phase == 0 && player.GetHealth() <= 24400)
					{
						scope.Phase = 1;
						scope.PlayPhaseSound();
						local interface = Entities.FindByClassname(null, "point_populator_interface")
						EntFireByHandle(interface, "ChangeBotAttributes", "PhaseTwo", -1.0, null, null);
					}
					else if (scope.Phase == 1 && player.GetHealth() <= 12020)
					{
						scope.Phase = 2;
						scope.PlayPhaseSound();
						local interface = Entities.FindByClassname(null, "point_populator_interface")
						EntFireByHandle(interface, "ChangeBotAttributes", "PhaseThree", -1.0, null, null);
						EntFireByHandle(player, "RunScriptCode", "self.SetAutoJump(10.0, 10.0)", -1.0, null, null);
					}

					return 0;
				}

				scope.PlayPhaseSound <- function()
				{
					for (local i = 1, player; i <= MAX_CLIENTS; i++)
					{
						if ((player = PlayerInstanceFromIndex(i)) != null)
						{
							EmitSoundEx({sound_name = "misc/doomsday_lift_warning.wav"
							entity = player
							filter_type = 4});
							EmitSoundEx({sound_name = "misc/doomsday_lift_warning.wav"
							entity = player
							filter_type = 4});
						}
					}
				}

				AddThinkToEnt(player, "Think");
			}
		}
	}
}
__CollectGameEventCallbacks(VerdantLandscape);
PrecacheSound("misc/doomsday_lift_warning.wav");