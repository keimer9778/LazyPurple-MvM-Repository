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

::TimerMent <-
{
	TimerColor = "100 255 255"
	TimerEntity = null
	MaxTime = 240.0
	CurrentTime = 0.0
	SubtractTimePerDeath = 0.0
	BossDeployName = ""

	function CleanUp()
	{
		if (TimerEntity != null && TimerEntity.IsValid())
		{
			TimerEntity.Destroy();
			TimerEntity = null;
		}
		delete ::TimerMent;
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		CleanUp();
	}

	function OnGameEvent_mvm_begin_wave(params)
	{
		if (TimerEntity != null && TimerEntity.IsValid())
		{
			TimerEntity.Destroy();
			TimerEntity = null;
		}
		TimerEntity = SpawnEntityFromTable("game_text", {
			channel = 0
			color = TimerColor
			holdtime = 1.0
			x = -1.0
			y = 0.79
			message = "240"
			spawnflags = 1
		});
		TimerEntity.ValidateScriptScope();
		local scope = TimerEntity.GetScriptScope();
		scope.Started <- false;
		scope.Think <- function()
		{
			if (!scope.Started)
			{
				return -1;
			}

			TimerMent.CurrentTime -= FrameTime();
			if (TimerMent.CurrentTime <= 0.0)
			{
				scope.Started = false;
				if (TimerMent.BossDeployName.len() > 0)
				{
					EntFire(TimerMent.BossDeployName, "Trigger");
				}
				else
				{
					local win = SpawnEntityFromTable("game_round_win",
					{
						targetname = "all_blue_win",
						TeamNum = 3,
						force_map_reset = 1
					});
					EntFireByHandle(win, "RoundWin", null, 0.0, null, null);
					EntFireByHandle(win, "Kill", null, 0.25, null, null);
				}
			}
			SetPropString(self, "m_iszMessage", scope.FormatTime());
			self.AcceptInput("Display", null, null, null);
			return -1;
		}
		scope.FormatTime <- function()
		{
			local time = ceil(TimerMent.CurrentTime);
			local minutes = (time / 60) % 60;
			local seconds =  time % 60;
			local actualSeconds = "";
			if (seconds <= 9)
			{
				actualSeconds = format("0%i", seconds);
			}
			else
			{
				actualSeconds = format("%i", seconds);
			}
			return format("%i:%s", minutes, actualSeconds);
		}
		AddThinkToEnt(TimerEntity, "Think");
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		CleanUp();
	}

	function OnGameEvent_player_death(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player == null || !player.IsValid() || player.IsBotOfType(TF_BOT_TYPE) || player.GetTeam() != 2)
		{
			return;
		}

		if (TimerEntity == null || !TimerEntity.IsValid())
		{
			return;
		}

		local scope = TimerEntity.GetScriptScope();
		if (!scope.Started || SubtractTimePerDeath <= 0.0)
		{
			return;
		}

		CurrentTime -= SubtractTimePerDeath;
	}

	function StartTimer(rsm = false)
	{
		if (TimerEntity == null || !TimerEntity.IsValid())
		{
			return;
		}
		if (!rsm)
		{
			CurrentTime = MaxTime;
		}
		local scope = TimerEntity.GetScriptScope();
		scope.Started = true;
	}

	function StopTimer()
	{
		if (TimerEntity == null || !TimerEntity.IsValid())
		{
			return;
		}
		local scope = TimerEntity.GetScriptScope();
		scope.Started = false;
	}
}
__CollectGameEventCallbacks(TimerMent);