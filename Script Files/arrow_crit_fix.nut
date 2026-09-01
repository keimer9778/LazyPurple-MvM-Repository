
if(!("ArrowCritFixMissionName" in ROOT))
{
	::ArrowCritFixMissionName <- ""
	local ent = Entities.FindByClassname(null, "tf_objective_resource");
	ArrowCritFixMissionName = GetPropString(ent, "m_iszMvMPopfileName");
}

::ArrowCritFix <-
{
	function OnGameEvent_recalculate_holidays(params)
	{
		local ent = Entities.FindByClassname(null, "tf_objective_resource");
		if (ent)
		{
			if (ArrowCritFixMissionName != GetPropString(ent, "m_iszMvMPopfileName")) // BAIL
			{
				delete ::ArrowCritFixMissionName;
				delete ::ArrowCritFix;
				return;
			}
		}
	}

	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player == null || !player.IsValid() || !player.IsBotOfType(TF_BOT_TYPE))
		{
			return;
		}
		player.TerminateScriptScope();
		NetProps.SetPropString(player, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(player, null);
		EntFireByHandle(player, "RunScriptCode", "ArrowCritFix.TagCheck(self)", -1, null, null);
	}

	function TagCheck(player)
	{
		if (player.HasBotTag("crit_fix"))
		{
			player.ValidateScriptScope();
			local scope = player.GetScriptScope();
			scope.Healer <- null;
			scope.HealerFound <- false;
			scope.Think <- function()
			{
				if (self.GetTeam() != 3 || !self.IsAlive())
				{
					self.TerminateScriptScope();
					NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
					AddThinkToEnt(self, null);
					return 0;
				}

				if (scope.Healer == null)
				{
					for (local i = 1, otherPlayer; i <= MaxClients().tointeger(); i++)
					{
						if ((otherPlayer = PlayerInstanceFromIndex(i)) != null && otherPlayer.GetHealTarget() == self)
						{
							scope.Healer = otherPlayer;
						}
					}
				}
				else
				{
					if (scope.Healer.GetHealTarget() == null)
					{
						scope.Healer = null;
					}
				}

				if (self.InCond(11) && scope.Healer != null && scope.Healer.IsValid())
				{
					self.AddBotAttribute(512);
				}
				else
				{
					self.RemoveBotAttribute(512);
					self.RemoveCond(11);
					self.RemoveCond(34);
				}
				return 0;
			}
			AddThinkToEnt(player, "Think");
		}
	}
}
__CollectGameEventCallbacks(ArrowCritFix);