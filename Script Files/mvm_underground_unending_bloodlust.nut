if (!("alternatewaves" in getroottable()))
{
	IncludeScript("alternatewaves", getroottable());
}
if (!("tankextensions_main" in getroottable()))
{
	IncludeScript("tankextensions_main", getroottable());
}
if (!("tankextensions/teletank" in getroottable()))
{
	IncludeScript("tankextensions/teletank", getroottable());
}
if (!("tankextensions/targetank" in getroottable()))
{
	IncludeScript("tankextensions/targetank", getroottable());
}

TankExt.SetValueOverrides
({
TARGETANK_COLOR1 = "255 255 0"
TARGETANK_COLOR2 = "255 0 0"
TARGETANK_SND_IMPACT = "DemoCharge.HitFlesh"
TARGETANK_RECHARGE_DURATION = 18.5
TELETANK_UBER_DURATION_MULT = 0.0

TELETANK_DISPENSER_HEALING = true
});

TankExt.CreatePaths({
	path_left = [
		Vector(1016, -2488, -56)
		Vector(1008, -2056, -56)
		Vector(1016, -1216, -32)
		Vector(344, -1232, 16)
		Vector(40, -1256, 80)
		Vector(-184, -1112, 104)
		Vector(-312, -888, 104)
		Vector(-424, -640, 96)
		Vector(-424, 136, 104)
		Vector(80, 168, 104)
		Vector(152, 384, 104)
		Vector(144, 960, 120)
		Vector(-72, 1112, 112)
		Vector(-224, 1384, 104)
		Vector(-208, 1816, 72)
		Vector(232, 1816, 48)
		Vector(592, 1888, 8)
		Vector(592, 2328, 0)
		Vector(592, 2736, -120)
		Vector(432, 2904, -120)
		Vector(200, 2888, -120)
		Vector(120, 2992, -120)
		Vector(104, 3448, -120)
		Vector(208, 3552, -120)
		Vector(472, 3552, -120)
	]

	path_farleft = [
		Vector(1016, -2488, -56)
		Vector(1016, -2056, -56)
		Vector(1016, -1216, -32)
		Vector(984, -616, 40)
		Vector(992, -8, 40)
		Vector(560, 152, 48)
		Vector(320, 208, 88)
		Vector(152, 232, 96)
		Vector(144, 768, 120)
		Vector(-48, 1056, 112)
		Vector(-288, 1576, 88)
		Vector(-544, 2040, 72)
		Vector(-544, 2632, 80)
		Vector(-512, 3408, 104)
		Vector(-192, 3432, 96)
		Vector(168, 3504, -128)
		Vector(472, 3544, -120)
	]
})

AlternateWaves.bTrackIcons = false;

if(!("MentMissionName" in ROOT))
{
	::MentMissionName <- ""
	local ent = Entities.FindByClassname(null, "tf_objective_resource");
	MentMissionName = NetProps.GetPropString(ent, "m_iszMvMPopfileName");
}

if (!("UnendingBloodlustBlacklistedClients" in ROOT))
{
	::UnendingBloodlustBlacklistedClients <- []
}

::UnendingBloodlust <-
{
	NotifiedPlayers = []
	WaveInProgress = false
	StopWaveCycle = false
	BlockedAreas = [Vector(1294.0, 2346.0, 230.0), Vector(-550.0, 2177.0, 40.0)]
	BlockedAreaRadius = 400.0
	SplitVersion = false
	AirblastCrazy = false
	JetpackPush = 200.0
	JetpackPushA = 100.0
	JetpackPushB = 300.0

	function SetMissionName()
	{
		local ent = Entities.FindByClassname(null, "tf_objective_resource");
		if (ent)
		{
			local sigmod = Convars.GetInt("sig_etc_misc") != null;
			if (sigmod == true)
			{
				ent.AcceptInput("$SetClientProp$m_iszMvMPopfileName", "GRIEF (Master)", null, null);
			}
			else
			{
				NetProps.SetPropString(ent, "m_iszMvMPopfileName", "GRIEF (Master)");
			}
		}
	}

	function CleanUp()
	{
		local ent = Entities.FindByClassname(null, "tf_objective_resource");
		if (ent)
		{
			if (!("MentMissionName" in getroottable()) || MentMissionName == NetProps.GetPropString(ent, "m_iszMvMPopfileName"))
			{
				return;
			}
		}

		local gamerules = FindByClassname(null, "tf_gamerules");
		local scope = gamerules.GetScriptScope();
		if (scope != null)
		{
			gamerules.TerminateScriptScope();
			NetProps.SetPropString(gamerules, "m_iszScriptThinkFunction", "");
			AddThinkToEnt(gamerules, null);
		}

		local waveStart = Entities.FindByName(null, "wave_start_relay");
		RemoveWaveScope(waveStart);
		local navAreas = {};
		foreach (pos in BlockedAreas)
		{
			NavMesh.GetNavAreasInRadius(pos, BlockedAreaRadius, navAreas);
			foreach (area in navAreas)
			{
				area.UnblockArea();
			}
		}

		for (local i = 1, player; i <= MaxClients().tointeger(); i++)
		{
			if ((player = PlayerInstanceFromIndex(i)) != null)
			{
				player.TerminateScriptScope();
				NetProps.SetPropString(player, "m_iszScriptThinkFunction", "");
				AddThinkToEnt(player, null);
			}
		}

		if (AirblastCrazy)
		{
			Convars.SetValue("tf_airblast_cray", 1);
		}
		Convars.SetValue("tf_rocketpack_launch_push", JetpackPush);
		Convars.SetValue("tf_rocketpack_impact_push_min", JetpackPushA);
		Convars.SetValue("tf_rocketpack_impact_push_max", JetpackPushB);
		delete ::UnendingBloodlust;
		delete ::UnendingBloodlustBlacklistedClients;
		delete ::MentMissionName;
	}

	function ReblockAreas()
	{
		local navAreas = {};
		foreach (pos in BlockedAreas)
		{
			NavMesh.GetNavAreasInRadius(pos, BlockedAreaRadius, navAreas);
			foreach (area in navAreas)
			{
				//area.MarkAsBlocked(Constants.ETFTeam.TF_TEAM_BLUE);
			}
		}
	}

	function RemoveWaveScope(waveStart)
	{
		local scope = waveStart.GetScriptScope();
		if (scope != null)
		{
			waveStart.TerminateScriptScope();
			NetProps.SetPropString(waveStart, "m_iszScriptThinkFunction", "");
			AddThinkToEnt(waveStart, null);
		}
	}

	function OnGameEvent_post_inventory_application(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		ModifyWeapons(player);
	}

	function ModifyWeapons(player)
	{
		if (player.GetTeam() == 2)
		{
			local hasCola = false;
			for (local i = 0; i < NetProps.GetPropArraySize(player, "m_hMyWeapons"); i++)
			{
				local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if (weapon == null)
				{
					continue;
				}
				if (weapon.GetClassname() == "tf_weapon_minigun")
				{
					weapon.RemoveAttribute("damage bonus HIDDEN");
					weapon.AddAttribute("damage bonus HIDDEN", 0.8, 0)
				}

				if (weapon.GetClassname() == "tf_weapon_lunchbox_drink" && NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex") == 163)
				{
					hasCola = true;
				}
			}

			if (hasCola && player.GetPlayerClass() == TF_CLASS_SCOUT)
			{
				local timer = Entities.CreateByClassname("logic_relay");

				timer.ValidateScriptScope();
				local scope = timer.GetScriptScope();

				scope.ApplyScoutAttributes <- function()
				{
					player.AddCustomAttribute("minicrits become crits", 1, 0);
					self.Destroy();
				}

				timer.ConnectOutput("OnTrigger", "ApplyScoutAttributes");

				EntFireByHandle(timer, "Trigger", "", 0.05, null, null);
			}
		}
	}

	function OnGameEvent_recalculate_holidays(params)
	{
		CleanUp();
	}

	function OnGameEvent_mvm_wave_complete(params)
	{
		CleanUp();
		WaveInProgress = false
	}

	function OnGameEvent_mvm_mission_complete(params)
	{
		StopWaveCycle = true
	}

	function OnGameEvent_player_disconnect(params)
	{
		local index = NotifiedPlayers.find(params.userid)
		if (index == null)
		{
			return
		}

		NotifiedPlayers.remove(index)
	}

	function OnGameEvent_player_changeclass(params)
	{
		local player = GetPlayerFromUserID(params.userid);
		if (player == null || !player.IsValid())
		{
			return;
		}

		ShowAllHints(player);
	}

	function ShowAllHints(player)
	{
		player.TerminateScriptScope();
		SetPropString(player, "m_iszScriptThinkFunction", "");
		AddThinkToEnt(player, null);

		local id = GetPropString(player, "m_szNetworkIDString");
		if (UnendingBloodlustBlacklistedClients.find(id) != null)
		{
			return;
		}

		SendGlobalGameEvent("hide_annotation", {
			id = player.entindex()
		});

		local timer = Entities.CreateByClassname("logic_relay");

		timer.ValidateScriptScope();
		local scope = timer.GetScriptScope();
		player.ValidateScriptScope();
		local playerScope = player.GetScriptScope();
		playerScope.Messages <- [];
		playerScope.MessageDelays <- [];
		playerScope.MessageIndex <- -1;
		playerScope.MessageTime <- 0.0;
		playerScope.Think <- function()
		{
			if (playerScope.Messages.len() == 0)
			{
				return -1;
			}

			playerScope.MessageTime -= FrameTime();
			if (playerScope.MessageTime <= 0.0)
			{
				playerScope.MessageIndex++;
			}
			else
			{
				return -1;
			}

			if (playerScope.MessageIndex == playerScope.Messages.len() || UnendingBloodlust == null)
			{
				self.TerminateScriptScope();
				SetPropString(self, "m_iszScriptThinkFunction", "");
				AddThinkToEnt(self, null);
				return -1;
			}

			playerScope.MessageTime = playerScope.MessageDelays[playerScope.MessageIndex];
			UnendingBloodlust.ShowClassTips(playerScope.Messages[playerScope.MessageIndex], self, playerScope.MessageDelays[playerScope.MessageIndex]);

			return -1;
		}

		scope.ShowTips <- function()
		{
			playerScope.Messages.append("Read the chat for any mission changes, these are your class changes (if applicable)");
			playerScope.MessageDelays.append(6.0);

			switch (player.GetPlayerClass())
			{
				case 1: // Scout
				{
					playerScope.Messages.append("+ Scout gets 90 percent crit resistance by default +");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("+ Scout gets 10 health regen by default +");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("+ Crit-a-Cola gets +50 percent recharge rate by default +");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("+ Crit-a-Cola turns all mini-crits into crits +");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("+ Crit-a-Cola no longer marks for death +");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 3: // Soldier
				{
					playerScope.Messages.append("! Sentry Busters can no longer farm banner charge !");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 5: // Medic
				{
					playerScope.Messages.append("! Sentry Busters can no longer farm ubersaw swings !");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("! The ubersaw now only gives 13 percent uber charge on hit !");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 6: // Heavy
				{
					playerScope.Messages.append("! Sentry Busters can no longer farm knockback rage !");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("! All miniguns deal 20 percent less damage to everything !");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 7: // Pyro
				{
					playerScope.Messages.append("! Sentry Busters can no longer farm phlog mmph !");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("! Airblast knockback's effectiveness has been reduced !");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 8: // Spy
				{
					playerScope.Messages.append("! All medic bots turn around after one backstab !");
					playerScope.MessageDelays.append(5.0);
					break;
				}

				case 9: // Engineer
				{
					playerScope.Messages.append("+ All buildings construct 150 percent faster +");
					playerScope.MessageDelays.append(5.0);

					playerScope.Messages.append("+ All buildings are 25 percent cheaper +");
					playerScope.MessageDelays.append(5.0);
					break;
				}
			}

			playerScope.Messages.append("View the upgrade station for any upgrade changes");
			playerScope.MessageDelays.append(5.0);

			playerScope.Messages.append("To turn on/off class changes, type \"!togglehints\" in chat");
			playerScope.MessageDelays.append(10.0);

			self.Destroy();
		}

		timer.ConnectOutput("OnTrigger", "ShowTips");

		EntFireByHandle(timer, "Trigger", "", 1.0, null, null);
		AddThinkToEnt(player, "Think");
	}

	function OnGameEvent_player_say(params)
	{
		local text = params.text.tolower()
		local player = GetPlayerFromUserID(params.userid);
		if (text == "!togglehints")
		{
			if (UnendingBloodlustBlacklistedClients.find(GetPropString(player, "m_szNetworkIDString")) != null)
			{
				ClientPrint(player, 3, "\x0799CCFF[MvM] \x01Enabled class hints.");
				UnendingBloodlustBlacklistedClients.remove(UnendingBloodlustBlacklistedClients.find(GetPropString(player, "m_szNetworkIDString")));
			}
			else
			{
				ClientPrint(player, 3, "\x0799CCFF[MvM] \x01Disabled class hints.");
				UnendingBloodlustBlacklistedClients.append(GetPropString(player, "m_szNetworkIDString"));
				player.TerminateScriptScope();
				SetPropString(player, "m_iszScriptThinkFunction", "");
				AddThinkToEnt(player, null);
				SendGlobalGameEvent("hide_annotation", {
					id = player.entindex()
				});
			}
		}
	}

	function OnGameEvent_mvm_wave_failed(params)
	{
		WaveInProgress = false
	}

	function OnGameEvent_mvm_begin_wave(params)
	{
		WaveInProgress = true;
		local waveStart = Entities.FindByName(null, "wave_start_relay");
		RemoveWaveScope(waveStart);
		AddScope(waveStart);
		ReblockAreas();
		for (local avoid; avoid = Entities.FindByClassname(avoid, "func_nav_avoid");)
		{
			avoid.KeyValueFromString("tags", "common bomb_carrier");
			avoid.SetTeam(Constants.ETFTeam.TF_TEAM_BLUE);
			avoid.DispatchSpawn();
			break;
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
		EntFireByHandle(player, "RunScriptCode", "UnendingBloodlust.TagCheck(self)", -1, null, null);
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

	function OnGameEvent_mvm_reset_stats(params)
	{
		WaveInProgress = true
	}

	function HasScope(waveStart)
	{
		local scope = waveStart.GetScriptScope();
		return ("IsFading" in scope);
	}

	function StartFadeOutTrack(trackA, trackB)
	{
		local waveStart = Entities.FindByName(null, "wave_start_relay");
		if (HasScope(waveStart))
		{
			local scope = waveStart.GetScriptScope();
			scope.StartFade(trackA, trackB);
			return;
		}
	}

	AddScope = function(waveStart)
	{
		waveStart.ValidateScriptScope();
		if (HasScope(waveStart))
		{
			return;
		}

		local scope = waveStart.GetScriptScope();

		scope.VolumeA <- 1.0;
		scope.VolumeB <- 0.0;
		scope.IsFading <- false;
		scope.TrackA <- "";
		scope.TrackB <- "";

		scope.StartFade <- function(trackA, trackB)
		{
			scope.IsFading = true;
			scope.VolumeA = 1.0;
			scope.VolumeB = 0.0;
			scope.TrackA = trackA;
			scope.TrackB = trackB;
		}

		scope.MusicThink <- function()
		{
			if (!scope.IsFading)
			{
				return 0;
			}

			scope.VolumeA -= FrameTime();
			scope.VolumeB += FrameTime();
			if (scope.VolumeA <= 0.0)
			{
				scope.VolumeA = 0.0;
				scope.IsFading = false;
			}
			if (scope.VolumeB >= 1.0)
			{
				scope.VolumeB = 1.0;
				scope.IsFading = false;
			}

			for (local i = 1, player; i <= MaxClients().tointeger(); i++)
			{
				if ((player = PlayerInstanceFromIndex(i)) != null && !IsPlayerABot(player))
				{
					EmitSoundEx({
							sound_name = scope.TrackA
							entity = player
							filter_type = 4
							flags = 1
							volume = scope.VolumeA
						})

					EmitSoundEx({
							sound_name = scope.TrackB
							entity = player
							filter_type = 4
							flags = 1
							volume = scope.VolumeB
						})
				}
			}

			return 0;
		}

		AddThinkToEnt(waveStart, "MusicThink");
	}

	function StopWaveSpawn(wave)
	{
		local populator = FindByClassname(null, "point_populator_interface");
		populator.AcceptInput("$PauseWaveSpawn", wave, null, null);
		for (local i = 1; i <= MAX_CLIENTS; i++)
		{
			local otherPlayer = PlayerInstanceFromIndex(i);
			if (otherPlayer == null || otherPlayer.GetTeam() != 3 || !otherPlayer.IsAlive())
			{
				continue;
			}

			otherPlayer.SetHealth(0);
			otherPlayer.TakeDamageCustom(otherPlayer, otherPlayer, null, Vector(0, 0, 0), otherPlayer.GetCenter(), otherPlayer.GetHealth().tofloat() + 10.0, 0, 6);
		}


		for (local building; building = Entities.FindByClassname(building, "obj_*");)
		{
			if (building == null || building.GetTeam() != 3)
			{
				continue;
			}

			building.TakeDamage(building.GetHealth().tofloat() + 10.0, 64, Entities.First());
		}
	}

	function SetWaveBar(wave, maxWave = 6)
	{
		local isWave0 = (wave == 0)
		EntFire("tf_objective_resource", "$SetClientProp$m_nMvMEventPopfileType", isWave0 ? "1" : "0", -1)
		EntFire("tf_objective_resource", "$SetClientProp$m_nMannVsMachineWaveCount", isWave0 ? "1" : wave.tostring(), -1)
		if (wave == 6 || SplitVersion)
		{
			EntFire("tf_objective_resource", "$SetClientProp$m_nMannVsMachineMaxWaveCount", isWave0 ? "0" : "6", -1)
		}
		else
		{
			EntFire("tf_objective_resource", "$SetClientProp$m_nMannVsMachineMaxWaveCount", isWave0 ? "0" : maxWave.tostring(), -1)
		}
		if (!("alternatewaves" in getroottable()))
		{
			IncludeScript("alternatewaves", getroottable());
			AlternateWaves.bTrackIcons = false;
		}
		AlternateWaves.ClearWaveIcons()
		if (!isWave0)
		{
			AlternateWaves.SetWaveCount(wave, 6)
		}

		switch (wave)
		{
			case 1:
				AlternateWaves.AddWaveIcons([
					[ "demo_clusterbomb_delay", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_kritz2_giant", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_bat_nys", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_spammer", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_bonk_stun", 30, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_steelfist_yoovy", 8, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_deflector", 20, MVM_CLASS_FLAG_NORMAL ],
					[ "spy", 2, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
			case 2:
				AlternateWaves.AddWaveIcons([
					[ "soldier_burstfire", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_pop", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "demoknight_persian_nys", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_blackbox_conch_lite", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "pyro_flare", 16, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_shotgun", 15, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_gru", 8, MVM_CLASS_FLAG_NORMAL ],
					[ "medic", 10, MVM_CLASS_FLAG_NORMAL ],
					[ "sniper_bow_multi", 4, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_crit", 2, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "demo", 16, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "pyro_flare_armored_yoovy", 16, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
			case 3:
				AlternateWaves.AddWaveIcons([
					[ "tank_tele", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_stun_giant_armored", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_crossbow_penetration", 4, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_giant", 2, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "heavy_steelfist_yoovy", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic", 8, MVM_CLASS_FLAG_NORMAL ],
					[ "demoknight_persian_nys", 20, MVM_CLASS_FLAG_NORMAL ],
					[ "demo_giant", 25, MVM_CLASS_FLAG_NORMAL ],
					[ "scout", 15, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier", 12, MVM_CLASS_FLAG_NORMAL ],
				])
				break
			case 4:
				AlternateWaves.AddWaveIcons([
					[ "pyro_dragonfury_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_spammer_buff", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_conch_spammer_giant", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "demo_spammer_package", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_hyper", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "tank_targe", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_deflector", 12, MVM_CLASS_FLAG_NORMAL ],
					[ "demoknight_persian_nys", 16, MVM_CLASS_FLAG_NORMAL ],
					[ "scout_bonk_stun", 32, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "medic_kritz2", 6, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_shotgun", 12, MVM_CLASS_FLAG_NORMAL ],
					[ "engineer", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "medic_uber_quick", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "pyro_dragon_fury_swordstone", 24, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "demo", 32, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "sniper_bow_multi_ignite_fix", 12, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "spy", 3, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
			case 5:
				AlternateWaves.AddWaveIcons([
					[ "tank_tele", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_bison_spammer_hyper_mentrillum", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "tank_targe", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "demo_spammer_package", 9, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_shotgun_burst_lite", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_steelfist_yoovy_giant", 6, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_bison_a", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_crossbow_penetration", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_giant_fast", 25, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "sniper_bow_multi", 10, MVM_CLASS_FLAG_NORMAL ],
					[ "pyro_reflect", 16, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_directhit_lite", 16, MVM_CLASS_FLAG_NORMAL ],
					[ "medic_uber_armored", 3, MVM_CLASS_FLAG_NORMAL ],
					[ "scout_bonk_uber_nys", 2, MVM_CLASS_FLAG_NORMAL ],
					[ "medic_kritz2_armored_lite", 8, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_deflector", 12, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_crit", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ],
					[ "demo_charged", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_bazooka", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "pyro", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
			case 6:
				AlternateWaves.AddWaveIcons([
					[ "tank_targe", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "demo_burst_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_burstfire", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "pyro_dragonfury_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_kritz2_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_crossbow_penetration", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_spammer_buff", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_bison_a", 2, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "heavy_steelfist_push_yoovy", 2, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "soldier_bison_spammer_hyper_mentrillum", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_stun_giant_armored", 7, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_mittens", 4, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT],
					[ "soldier_crit", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ],
					[ "demo_charged", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ],
					[ "scout", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "pyro", 3, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ]
				])
				break
			case 7:
				AlternateWaves.AddWaveIcons([
					[ "demo_robot_nys", 1, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_spammer", 1, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_burstfire", 1, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_blackbox_conch_lite", 1, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_SUPPORT | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "scout_stun_giant_armored", 1, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_SUPPORT ],
					[ "sniper_headshot_crit_mission", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ]
				])
				break
			/*case 6:
				AlternateWaves.AddWaveIcons([
					[ "soldier_bison_spammer_hyper_mentrillum", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "tank", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "demo_spammer_package", 9, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_giant_fast", 50, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "sniper_bow_multi", 10, MVM_CLASS_FLAG_NORMAL ],
					[ "pyro_reflect", 20, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_directhit_buff_lite", 16, MVM_CLASS_FLAG_NORMAL ],
					[ "sniper_sydneysleeper", 2, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
			case 7:
				AlternateWaves.AddWaveIcons([
					[ "demoknight_persian_nys", 4, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "soldier_libertylauncher_giant", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "shotgun_reserve_spammer_v2", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_pop", 4, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_directhit_lite", 18, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy_steelfist_yoovy", 12, MVM_CLASS_FLAG_NORMAL ],
					[ "heavy", 9, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_bazooka", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_mangler_v2", 2, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ]
				])
				break
			case 8:
				AlternateWaves.AddWaveIcons([
					[ "heavy_shotgun_burst_lite", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_steelfist_yoovy", 6, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_bonk_uber_nys", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_burstfire", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_crossbow_penetration", 3, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_uber_armored", 3, MVM_CLASS_FLAG_NORMAL ],
					[ "medic_kritz2", 6, MVM_CLASS_FLAG_NORMAL ],
					[ "soldier_crit", 15, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "pyro", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "soldier_bison_spammer_fix", 4, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "heavy_accurate_lite", 16, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ]
				])
				break
			case 9:
				AlternateWaves.AddWaveIcons([
					[ "demo_burst_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_burstfire", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "pyro_dragon_fury_swordstone_spammer", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_kritz2_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_crossbow_penetration", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_buff_giant", 4, MVM_CLASS_FLAG_MINIBOSS ],
					[ "soldier_bison_a", 2, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "heavy_steelfist_push_yoovy", 2, MVM_CLASS_FLAG_MINIBOSS | MVM_CLASS_FLAG_ALWAYSCRIT ],
					[ "soldier_bison_spammer_hyper_mentrillum", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "medic_giant", 2, MVM_CLASS_FLAG_MINIBOSS ],
					[ "scout_bat_nys", 10, MVM_CLASS_FLAG_MINIBOSS ],
					[ "heavy_mittens", 4, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT],
					[ "sniper_headshot_crit_mission", 1, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_ALWAYSCRIT | MVM_CLASS_FLAG_SUPPORT ],
					[ "scout", 6, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "pyro", 3, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ]
				])
				break*/

			default:
				AlternateWaves.AddWaveIcons([
					[ "random_lite_giant", 666, MVM_CLASS_FLAG_MINIBOSS ],
					[ "random_lite", 666, MVM_CLASS_FLAG_NORMAL ],
					[ "sniper", 0, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "spy", 0, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
					[ "engineer", 0, MVM_CLASS_FLAG_NORMAL | MVM_CLASS_FLAG_SUPPORT ],
				])
				break
		}
	}

	function SetMaxWave(wave)
	{
		local isWave0 = (wave == 0);
		EntFire("tf_objective_resource", "$SetClientProp$m_nMannVsMachineMaxWaveCount", isWave0 ? "0" : wave.tostring(), -1);
		AlternateWaves.SetWaveCount(null, wave);
	}

	function ChangeBombPath(right = false)
	{
		EntFire("bombpath_choose_relay", "Disable");
		EntFire("bombpath_clearall_relay", "Trigger", null, 0.1);
		EntFire("bombpath_holograms_clear_relay", "Trigger", null, 0.1);
		if (right)
		{
			EntFire("bombpath_right_relay", "Trigger", null, 0.5);
		}
		else
		{
			EntFire("bombpath_left_relay", "Trigger", null, 0.5);
		}
		if (WaveInProgress)
		{
			EntFire("bombpath_holograms_clear_relay", "Trigger", null, 20.0);
			local bomb = Entities.FindByName(null, "intel");
			bomb.AcceptInput("ForceReset", "!activator", null, null);
			EntFireByHandle(bomb, "CallScriptFunction", "EvaluateNavBrushes", 0.4, null, null);

			SendGlobalGameEvent("show_annotation", {
				text = format("The bomb path has changed to the %s path.", right ? "right" : "left")
				lifetime = 20.0
				worldPosX = 1000.0
				worldPosY = -1250.0
				worldPosZ = -20.0
				id = -1
				play_sound = "mvm/mvm_cpoint_klaxon.wav"
				show_distance = false
				show_effect = false
				visibilityBitfield = 0
			})
		}
		ReblockAreas();
	}

	function HopBombBack()
	{
		local bomb = Entities.FindByName(null, "intel");
		bomb.GetScriptScope().Hop();
		ReblockAreas();
	}

	function AttachTankThink(name)
	{
		local timer = Entities.CreateByClassname("logic_relay");

		timer.ValidateScriptScope();
		local scope = timer.GetScriptScope();
		local tank = Entities.FindByNameNearest(name, Vector(1016, -2488, -56), 200.0);
		PrecacheSound(")ambient/materials/cartrap_explode_impact2.wav");

		scope.Tank <- tank;
		scope.OldState <- false;
		scope.State <- false;
		scope.Wait <- 0.25
		scope.Initialize <- 0.5
		scope.Think <- function()
		{
			scope.Initialize -= FrameTime();
			if (scope.Initialize > 0.0)
			{
				return -1;
			}
			if (scope.Tank == null || !scope.Tank.IsValid())
			{
				self.Kill();
				return -1;
			}
			scope.State = (tank.GetFlags() & 1) != 0;
			if (!scope.State)
			{
				scope.Wait -= FrameTime();
			}
			if (scope.Wait <= 0.0 && scope.State && !scope.OldState)
			{
				EmitSoundEx({sound_name = ")ambient/materials/cartrap_explode_impact2.wav"
						entity = scope.Tank
						sound_level = 90
					});
				EmitSoundEx({sound_name = ")ambient/materials/cartrap_explode_impact2.wav"
						entity = scope.Tank
						sound_level = 90
					});
				DispatchParticleEffect("hammer_impact_button", scope.Tank.GetOrigin(), scope.Tank.GetAngles());
				ScreenShake(scope.Tank.GetOrigin(), 16.0, 9.0, 3.0, 1000.0, 0, true);
				for (local otherPlayer; otherPlayer = Entities.FindByClassnameWithin(otherPlayer, "player", scope.Tank.GetOrigin(), 200.0);)
				{
					if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
					{
						continue;
					}

					otherPlayer.TakeDamageEx(scope.Tank, scope.Tank, null, Vector(0.0, 0.0, 0.0), scope.Tank.GetOrigin(), 2000.0, 1048640);
				}
				scope.Tank = null;
			}
			scope.OldState = scope.State;
			return -1;
		}

		AddThinkToEnt(timer, "Think");
	}

	function ShowClassTips(message, client, duration = 10.0)
	{
		SendGlobalGameEvent("hide_annotation", {
			id = client.entindex()
		});

		SendGlobalGameEvent("show_annotation", {
			text = format(message)
			lifetime = duration
			worldPosX = -70.0
			worldPosY = 4650.0
			worldPosZ = -36.0
			id = client.entindex()
			play_sound = "misc/null.wav"
			show_distance = false
			show_effect = false
			visibilityBitfield = 1 << client.entindex()
		});
	}

	GameRules = FindByClassname(null, "tf_gamerules")
}
__CollectGameEventCallbacks(UnendingBloodlust)

local nextBarChange = 0.0
local waveBarIndex = 0
local gamerules = FindByClassname(null, "tf_gamerules")
gamerules.ValidateScriptScope()
local rulesScope = gamerules.GetScriptScope();
rulesScope.BlinkTime <- 0.0;
rulesScope.Blinking <- false;
rulesScope.WaveBarChanger <- function()
{
	if (UnendingBloodlust.WaveInProgress)
	{
		return -1;
	}

	if (UnendingBloodlust.StopWaveCycle)
	{
		return -1;
	}

	if (nextBarChange <= Time())
	{
		local max = 6;
		waveBarIndex++;
		if (waveBarIndex > max)
		{
			waveBarIndex = 1;
		}
		nextBarChange = Time() + 5.0;
		UnendingBloodlust.SetWaveBar(waveBarIndex);
	}
	return -1;
}

for (local i = 1, player; i <= MaxClients().tointeger(); i++)
{
	if ((player = PlayerInstanceFromIndex(i)) != null)
	{
		UnendingBloodlust.ModifyWeapons(player);
		UnendingBloodlust.ShowAllHints(player);
	}
}

AddThinkToEnt(gamerules, "WaveBarChanger")

if (Convars.GetBool("tf_airblast_cray")) // For any other Rafmod server not Potato like LazyPurple's server
{
	UnendingBloodlust.AirblastCrazy = true;
	Convars.SetValue("tf_airblast_cray", 0);
}

UnendingBloodlust.JetpackPush = Convars.GetFloat("tf_rocketpack_launch_push");
UnendingBloodlust.JetpackPushA = Convars.GetFloat("tf_rocketpack_impact_push_min");
UnendingBloodlust.JetpackPushB = Convars.GetFloat("tf_rocketpack_impact_push_max");
Convars.SetValue("tf_rocketpack_launch_push", 0.0);
Convars.SetValue("tf_rocketpack_impact_push_min", 0.0);
Convars.SetValue("tf_rocketpack_impact_push_max", 0.0);