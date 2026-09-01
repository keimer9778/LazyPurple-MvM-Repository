if (!("ment_boss/attackstates" in getroottable()))
{
	IncludeScript("ment_boss/attackstates", getroottable());
}

if (!("red_world/states/earthquake" in getroottable()))
{
	IncludeScript("red_world/states/earthquake", getroottable());
}

if (!("red_world/states/groundslam" in getroottable()))
{
	IncludeScript("red_world/states/groundslam", getroottable());
}

if (!("red_world/states/laser" in getroottable()))
{
	IncludeScript("red_world/states/laser", getroottable());
}

if (!("red_world/states/slash" in getroottable()))
{
	IncludeScript("red_world/states/slash", getroottable());
}

if (!("red_world/states/uppercut" in getroottable()))
{
	IncludeScript("red_world/states/uppercut", getroottable());
}

::SovietTonkaWeapons <-
{
	BossFleeRange = [3500.0, 5000.0]
	BossChangePhaseSounds = ["vo/mvm/mght/heavy_mvm_m_revenge11.mp3", "vo/mvm/mght/heavy_mvm_m_revenge08.mp3", "vo/mvm/mght/heavy_mvm_m_revenge10.mp3", "vo/mvm/mght/heavy_mvm_m_revenge01.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts15.mp3"]
	BossMinigunStartSounds = ["vo/mvm/mght/heavy_mvm_m_meleedare01.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare02.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare03.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare04.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare09.mp3", "vo/mvm/mght/heavy_mvm_m_meleedare10.mp3"]
	BossMinigunFireSounds = ["vo/mvm/mght/taunts/heavy_mvm_m_taunts07.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts10.mp3", "vo/mvm/mght/taunts/heavy_mvm_m_taunts11.mp3"]
	BossCloakOnSound = ")weapons/medi_shield_deploy.wav"
	BossCloakOffSound = ")weapons/medi_shield_retract.wav"
	BossHealthThreshold = 15000

	function OnSpawn(player)
	{
		player.Teleport(true, RedWorld.ChosenBossPosition + Vector(0.0, 0.0, 15.0), true, RedWorld.ChosenBossAngles, true, player.GetAbsVelocity());
		for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", RedWorld.ChosenBossPosition, 125.0);)
		{
			if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
			{
				continue;
			}

			otherPlayer.TakeDamageCustom(player, player, null, Vector(0.0, 0.0, 0.0), player.GetCenter(), player.GetHealth().tofloat() * 10.0, 1024, TF_DMG_CUSTOM_PLASMA);
		}

		for (local building; building = FindByClassnameWithin(building, "obj_*", RedWorld.ChosenBossPosition, 125.0);)
		{
			if (building == null || !building.IsValid() || building.GetTeam() == player.GetTeam())
			{
				continue;
			}

			building.TakeDamage(building.GetHealth().tofloat() * 10.0, 64, player);
		}

		player.RemoveCondEx(TF_COND_INVULNERABLE, true);
		player.RemoveCondEx(TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED, true);
		player.RemoveCondEx(TF_COND_INVULNERABLE_CARD_EFFECT, true);
		player.RemoveCondEx(TF_COND_INVULNERABLE_USER_BUFF, true);
		player.RemoveCondEx(TF_COND_PHASE, true);
		EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
		player.ValidateScriptScope();
		local attacks = {};
		local attack = Earthquake();
		attacks.rawset(attack.name, attack);
		attack = GroundSlam();
		attacks.rawset(attack.name, attack);
		attack = EyeLaser();
		attacks.rawset(attack.name, attack);
		attack = Slash();
		attacks.rawset(attack.name, attack);
		attack = Uppercut();
		attacks.rawset(attack.name, attack);
		HookAttacksOnBot(player, attacks);

		local scope = player.GetScriptScope();

		scope.State <- STATE_GAUNTLETS;
		scope.AlwaysLookAtTarget <- null;
		scope.Phase <- 0;
		scope.SwitchingPhase <- false;
		scope.HealthThreshold <- SovietTonkaWeapons.BossHealthThreshold * Convars.GetFloat("tf_populator_health_multiplier");
		if (scope.HealthThreshold <= 0.0)
		{
			scope.HealthThreshold = SovietTonkaWeapons.BossHealthThreshold;
		}
		scope.SwitchTime <- RandomFloat(20.0, 40.0) + Time();

		scope.OldMinigunState <- 0;
		scope.MinigunState <- 0;
		scope.MinigunFocus <- null;
		scope.QuoteChance <- 0;

		scope.FleePosition <- Vector(0.0, 0.0, 0.0);
		scope.ReachedFleePosition <- false;
		scope.FleeTime <- 0.0;
		scope.FleeAbortTime <- 0.0;
		scope.StateBeforeFlee <- 0;

		scope.NextPathUpdate <- 0.0;
		scope.PathArray <- [];
		scope.PathIndex <- 0;
		scope.PathLength <- 0;

		scope.OriginalGauntletColor <- 0;

		scope.CurrentVulnerability <- 1.0;

		scope.IsCloaked <- false;
		scope.CloakTime <- 12.0;
		scope.CloakDecloakTime <- 12.0;
		scope.CloakRange <- 1250.0;
		scope.CloakDecloakRange <- 300.0;
		scope.CloakCooldown <- scope.CloakTime + Time();

		scope.Think <- function()
		{
			if (!scope.AttackStatesThink())
			{
				return -1;
			}
			SovietTonkaWeapons.TonkaThink(player);
			return -1;
		}

		scope.PreSetAnimation <- function(animation, create)
		{
			local position = self.GetOrigin();
			local rotation = self.GetAbsAngles();
			if (scope.State == STATE_GAUNTLETS)
			{
				local gloves = SpawnEntityFromTable("prop_dynamic", {
				origin = position,
				angles = rotation,
				modelscale = 1,
				skin = 1,
				model = "models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl"
				rendercolor = "0 55 117"
				});
				scope.PreExtraWearables.append(gloves);
			}
			for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
			{
				if (weapon == null || weapon.GetOwner() != self || weapon.GetSlot() != 2)
				{
					continue;
				}

				scope.OriginalGauntletColor = GetPropInt(weapon, "m_clrRender");
			}
		}

		scope.PostResetAnimation <- function()
		{
			for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
			{
				if (weapon == null || weapon.GetOwner() != self || weapon.GetSlot() != 2)
				{
					continue;
				}

				SetPropInt(weapon, "m_nRenderMode", 0);
				SetPropInt(weapon, "m_clrRender", scope.OriginalGauntletColor);
			}
		}

		scope.StartCloak <- function()
		{
			if (scope.IsCloaked || scope.IsAttacking)
			{
				return;
			}

			EmitSoundEx({sound_name = SovietTonkaWeapons.BossCloakOnSound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			EmitSoundEx({sound_name = SovietTonkaWeapons.BossCloakOnSound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			self.AddCond(TF_COND_STEALTHED_USER_BUFF);
			DispatchParticleEffect("drg_cow_explosioncore_charged_blue", self.GetOrigin() + Vector(0.0, 0.0, 45.0), Vector(0.0, 0.0, 0.0));
			scope.IsCloaked = true;
			scope.CloakCooldown = Time() + scope.CloakTime;
			self.AddCustomAttribute("no_attack", 1, 0.0);
		}

		scope.StopCloak <- function()
		{
			if (!scope.IsCloaked)
			{
				return;
			}

			EmitSoundEx({sound_name = SovietTonkaWeapons.BossCloakOffSound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			EmitSoundEx({sound_name = SovietTonkaWeapons.BossCloakOffSound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			DispatchParticleEffect("drg_cow_explosioncore_charged_blue", self.GetOrigin() + Vector(0.0, 0.0, 45.0), Vector(0.0, 0.0, 0.0));
			self.RemoveCond(TF_COND_STEALTHED_USER_BUFF);
			scope.IsCloaked = false;
			scope.CloakCooldown = Time() + scope.CloakDecloakTime;
			self.RemoveCustomAttribute("no_attack");
		}

		scope.ToggleCloak <- function()
		{
			if (scope.IsCloaked)
			{
				scope.StopCloak();
			}
			else
			{
				scope.StartCloak();
			}
		}

		scope.ProcessCloak <- function()
		{
			if (scope.IsCloaked && self.InCond(TF_COND_BURNING))
			{
				scope.StopCloak();
			}
			local range = scope.IsCloaked ? scope.CloakDecloakRange : scope.CloakRange;
			for (local otherPlayer; otherPlayer = FindByClassnameWithin(otherPlayer, "player", player.GetCenter(), range);)
			{
				if (otherPlayer == null || !otherPlayer.IsValid() || !otherPlayer.IsAlive() || IsPlayerABot(otherPlayer) || otherPlayer.GetTeam() != 2)
				{
					continue;
				}
				local playerRange = (otherPlayer.GetOrigin() - player.GetOrigin()).LengthSqr();

				if (scope.IsCloaked && playerRange <= pow(scope.CloakDecloakRange, 2.0))
				{
					scope.ToggleCloak();
					return;
				}

				if (!scope.IsCloaked && (playerRange <= pow(scope.CloakDecloakRange + 50.0, 2.0) || playerRange > pow(scope.CloakRange, 2.0)))
				{
					return;
				}
			}

			if (scope.CloakCooldown <= Time())
			{
				scope.ToggleCloak();
			}
		}

		scope.ChangePhase <- function(phase)
		{
			scope.Phase = phase;
			if (scope.Phase == 1)
			{
				scope.GetAttackFromName("eye_laser").canUse = true;
				scope.GetAttackFromName("uppercut").canUse = true;
			}
			scope.SwitchingPhase = true;
			scope.SetAttackState(null);
			scope.ToggleAttacks(false);
			local sound = SovietTonkaWeapons.BossChangePhaseSounds[RandomInt(0, SovietTonkaWeapons.BossChangePhaseSounds.len() - 1)];
			EmitSoundEx({sound_name = sound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			EmitSoundEx({sound_name = sound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			EmitSoundEx({sound_name = sound,
			entity = self,
			sound_level = 100,
			filter_type = RECIPIENT_FILTER_GLOBAL});
			RedWorld.StopSupportBots();
			local populator = FindByClassname(null, "point_populator_interface");
			populator.AcceptInput("$ResumeWavespawn", format("phase%d_bots", phase), null, null);
			EntFireByHandle(self, "$AddPlayerAttribute", "no_attack|1", 0.1, null, null);
			self.AddCond(TF_COND_FREEZE_INPUT);
			scope.AlwaysLookAtTarget = null;

			if (!scope.IsCloaked)
			{
				scope.PlayAnimation("taunt_rps_rock_lose", 1.0, 0.489);
				EntFireByHandle(self, "RunScriptCode", "self.GetScriptScope().StartFlee()", 2.0, null, null);
			}
			else
			{
				EntFireByHandle(self, "RunScriptCode", "self.GetScriptScope().StartFlee()", 0.0, null, null);
			}
		}

		scope.StartFlee <- function()
		{
			if (self.GetTeam() != 3  || !self.IsAlive())
			{
				return;
			}
			local scope = self.GetScriptScope();
			scope.ResetAnimation();
			scope.StateBeforeFlee = scope.State;
			scope.SwitchTime += 2.0;
			scope.FleeTime = Time() + RandomFloat(10.0, 16.0);
			scope.State = STATE_FLEE;
			scope.StartCloak();
			EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
			scope.ReachedFleePosition = false;
			local tableAreas = {};
			local areas = [];
			local range = RandomFloat(SovietTonkaWeapons.BossFleeRange[0], SovietTonkaWeapons.BossFleeRange[1]);
			NavMesh.GetNavAreasInRadius(self.GetOrigin(), range, tableAreas);
			foreach (nav in tableAreas)
			{
				if (nav.HasAttributeTF(TF_NAV_SPAWN_ROOM_RED))
				{
					continue;
				}
				areas.append(nav);
			}
			local area = areas[RandomInt(0, areas.len() - 1)];
			scope.FleePosition = area.GetCenter();
			scope.FleePosition.z += 1.0;
			self.AddBotAttribute(IGNORE_ENEMIES);
			self.AddBotAttribute(SUPPRESS_FIRE);
			self.RemoveCond(TF_COND_FREEZE_INPUT);
			self.SetBehaviorFlag(16);
			EntFireByHandle(self, "$BotCommand", "switch_action Idle", 0.1, null, null);
			EntFireByHandle(self, "$AddPlayerAttribute", "increased jump height|1.6", 0.1, null, null);
			EntFireByHandle(self, "$AddPlayerAttribute", "no_attack|1", 0.1, null, null);
		}
		AddThinkToEnt(player, "Think");
	}

	function TonkaThink(player)
	{
		local scope = player.GetScriptScope();
		local time = Time();

		if (scope.IsCloaked && !player.InCond(TF_COND_STEALTHED_USER_BUFF))
		{
			player.AddCond(TF_COND_STEALTHED_USER_BUFF);
		}

		if (scope.AlwaysLookAtTarget != null)
		{
			local newDirection = RedWorld.LerpQAngles(player.GetAbsAngles(), VectorToQAngle(scope.AlwaysLookAtTarget.GetOrigin() - player.GetOrigin()), 0.85);
			newDirection.x = 0.0;
			newDirection.z = 0.0;
			local vel = player.GetAbsAngles().Forward() * 1.0;
			player.Teleport(false, Vector(), true, newDirection, true, vel);
			player.SetAbsAngles(newDirection);
			player.SetLocalAngles(newDirection);
			player.SetPoseParameter(player.LookupPoseParameter("body_yaw"), 0.0);
			SetPropVector(player, "m_vecBaseVelocity", vel);
		}

		if (!scope.SwitchingPhase && player.GetHealth() <= scope.HealthThreshold && scope.Phase < 3)
		{
			scope.ChangePhase(scope.Phase + 1);
		}

		switch (scope.Phase)
		{
			case 0:
			{
				break;
			}

			case 1:
			{
				break;
			}

			case 2:
			{
				break;
			}
		}

		switch (scope.State)
		{
			case STATE_MINIGUN:
			{
				local minigun = null;
				for (local i = 0; i <= 8; i++)
				{
					local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
					if (weapon != null && weapon.GetSlot() == 0)
					{
						minigun = weapon;
						break;
					}
				}
				scope.MinigunState = GetPropInt(minigun, "m_iWeaponState");

				if (scope.QuoteChance == 1 && scope.MinigunState == 1)
				{
					scope.QuoteChance = 0;
					local sound = SovietTonkaWeapons.BossMinigunStartSounds[RandomInt(0, SovietTonkaWeapons.BossMinigunStartSounds.len() - 1)];
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
				}
				if (scope.QuoteChance == 2 && scope.MinigunState == 2)
				{
					scope.QuoteChance = 0;
					local sound = SovietTonkaWeapons.BossMinigunFireSounds[RandomInt(0, SovietTonkaWeapons.BossMinigunFireSounds.len() - 1)];
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
					EmitSoundEx({sound_name = sound,
					entity = player,
					sound_level = 100,
					filter_type = RECIPIENT_FILTER_GLOBAL});
				}
				if (scope.MinigunState == 3 || scope.MinigunState == 4 || (scope.MinigunState == 0 && (scope.OldMinigunState == 3 || scope.OldMinigunState == 4)))
				{
					player.AddBotAttribute(8);
					player.AddCustomAttribute("no_attack", 1, 0.0);
					scope.SwitchTime = 1.0 + Time();
				}
				scope.OldMinigunState = scope.MinigunState;
				break;
			}

			case STATE_GAUNTLETS:
			{
				if (scope.IsCloaked && scope.IsAttacking)
				{
					scope.StopCloak();
				}

				if (scope.Phase >= 1 && !scope.SwitchingPhase)
				{
					scope.ProcessCloak();
				}
				break;
			}

			case STATE_SHOTGUN:
			{
				break;
			}

			case STATE_FLEE:
			{
				if (scope.IsCloaked && player.InCond(TF_COND_BURNING))
				{
					scope.StopCloak();
				}
				if (((player.GetOrigin() - scope.FleePosition).LengthSqr() <= 175.0 * 175.0 || scope.FleeTime <= time) && !scope.ReachedFleePosition)
				{
					scope.StopCloak();
					EntFire("pop_interface", "ChangeBotAttributes", "Sandvich_Action");
					scope.ReachedFleePosition = true;
					EntFireByHandle(player, "$RemovePlayerAttribute", "no_attack", 0.05, null, null);
					EntFireByHandle(player, "$RemovePlayerAttribute", "increased jump height", 0.05, null, null);
				}
				else
				{
					if (scope.NextPathUpdate <= time)
					{
						RedWorld.UpdatePath(player, scope.FleePosition);
					}
					RedWorld.ComputeToPath(player);
					if (player.GetLocomotionInterface().IsStuck())
					{
						scope.FleeTime = 0.0;
					}
				}
				if (scope.ReachedFleePosition)
				{
					if (!player.InCond(TF_COND_TAUNTING))
					{
						scope.FleeAbortTime = 3.65 + time;
					}
					if (scope.ReachedFleePosition && scope.FleeAbortTime <= time)
					{
						player.RemoveCond(87);
						scope.State = 10;
						scope.SwitchTime = 0.0;
						scope.SwitchingPhase = false;
						player.RemoveBotAttribute(IGNORE_ENEMIES);
						player.RemoveBotAttribute(SUPPRESS_FIRE);
						player.ClearBehaviorFlag(16);
						player.AcceptInput("$BotCommand", "switch_action Mobber", null, null);
						EntFireByHandle(player, "$BotCommand", "switch_action Mobber", 0.1, null, null);
						scope.CurrentVulnerability += 0.25;
						//EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
						//EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action", 0.1);
					}
				}

				return;
			}
		}

		if (scope.SwitchTime <= time && scope.State != STATE_FLEE && !scope.SwitchingPhase)
		{
			if (scope.IsAttacking)
			{
				scope.SwitchTime += 2.0;
				return;
			}
			player.RemoveBotAttribute(8);
			EntFireByHandle(player, "$RemovePlayerAttribute", "no_attack", 0.1, null, null);
			local validStates = [STATE_MINIGUN, STATE_SHOTGUN, STATE_GAUNTLETS];
			if (validStates.find(scope.State) != null)
			{
				validStates.remove(validStates.find(scope.State));
			}

			if (scope.IsCloaked)
			{
				scope.StopCloak();
			}

			scope.State = validStates[RandomInt(0, validStates.len() - 1)];
			scope.ToggleAttacks(false);
			switch (scope.State)
			{
				case STATE_MINIGUN:
				{
					scope.QuoteChance = RandomInt(0, 2);
					// It's over 9000!
					scope.SwitchTime = 9001.0 + Time();
					EntFire("pop_interface", "ChangeBotAttributes", "Minigun_Action");
					break;
				}

				case STATE_SHOTGUN:
				{
					scope.SwitchTime = RandomFloat(10.0, 20.0) + Time();
					switch (RandomInt(0, 1))
					{
						case 0:
						{
							EntFire("pop_interface", "ChangeBotAttributes", "Shotgun_Action_Dragonsbreath");
							break;
						}

						case 1:
						{
							EntFire("pop_interface", "ChangeBotAttributes", "Shotgun_Action_ResupplyShotgun");
							break;
						}
					}

					break;
				}

				case STATE_GAUNTLETS:
				{
					scope.ToggleAttacks(true);
					EntFire("pop_interface", "ChangeBotAttributes", "Melee_Action");
					scope.SwitchTime = RandomFloat(20.0, 40.0) + Time();
					break;
				}
			}
		}
	}
}

PrecacheSound(SovietTonkaWeapons.BossCloakOnSound);
PrecacheSound(SovietTonkaWeapons.BossCloakOffSound);
for (local i = 0; i < SovietTonkaWeapons.BossChangePhaseSounds.len(); i++)
{
	PrecacheSound(SovietTonkaWeapons.BossChangePhaseSounds[i]);
}
for (local i = 0; i < SovietTonkaWeapons.BossMinigunStartSounds.len(); i++)
{
	PrecacheSound(SovietTonkaWeapons.BossMinigunStartSounds[i]);
}
for (local i = 0; i < SovietTonkaWeapons.BossMinigunFireSounds.len(); i++)
{
	PrecacheSound(SovietTonkaWeapons.BossMinigunFireSounds[i]);
}
