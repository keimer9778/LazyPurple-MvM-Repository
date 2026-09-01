PrecacheModel("models/props_frontline/tank_cart.mdl")
TankExt.PrecacheSound("mvm/giant_demoman/giant_demoman_grenade_shoot.wav")
TankExt.PrecacheSound("mvm/giant_soldier/giant_soldier_rocket_shoot.wav")
TankExt.PrecacheSound("mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav")
TankExt.PrecacheSound("player/taunt_moped_start_shake.wav")
TankExt.PrecacheSound("mvm/mvm_tank_ping.wav")
TankExt.PrecacheSound("misc/doomsday_cap_close_start.wav")
TankExt.PrecacheSound("ambient/grinder/grinderbot_02.wav")

TankExt.NewTankScript("tinytank*", {
	OnSpawn = function(hTank, sName, hPath)
	{
		// Setup
		local bBlueTeam = hTank.GetTeam() == 3
		local hTank_scope = hTank.GetScriptScope()
		local sParams = split(sName, "|")
		hTank_scope.hGrenades <- []
		
		// Tank health stuff
		local initial_tank_health = hTank.GetHealth()
		local tank_health_60percent = ceil(initial_tank_health * 0.65)
		local tank_health_20percent = ceil(initial_tank_health * 0.25)
		
		hTank_scope.past_60percent <- false
		hTank_scope.past_20percent <- false
		
		// Remove original bomb
		for (local child = hTank.FirstMoveChild(); child != null; child = child.NextMovePeer())
			if (child.GetClassname() == "prop_dynamic")
				if (child.GetModelName() == "models/bots/boss_bot/bomb_mechanism.mdl")
					child.DisableDraw()
					
		// Remove tracks
		for (local child = hTank.FirstMoveChild(); child != null; child = child.NextMovePeer())
			if (child.GetClassname() == "prop_dynamic")
				if (child.GetModelName() == "models/bots/boss_bot/tank_track_L.mdl" || child.GetModelName() == "models/bots/boss_bot/tank_track_R.mdl")
						child.DisableDraw()

		// Scale tank
		EntFireByHandle(hTank, "SetModelScale", "0.5", -1, null, null)
		
		// Props
		hTank_scope.hTank_cart_prop <-
		SpawnEntityFromTable("prop_dynamic",
			{
				targetname = "tank_cart_prop",
				model = "models/props_frontline/tank_cart.mdl",
				solid = 0,
				skin = 2,
				angles = "0 180 0",
				DefaultAnim = "idle",
			})
		hTank_scope.hTank_turret_prop_bomb <-
		SpawnEntityFromTable("prop_dynamic",
			{
				targetname = "tank_turret_prop_bomb",
				model = "models/bots/boss_bot/bomb_mechanism.mdl",
				//startdisabled = 1,
				solid = 0,
				DefaultAnim = "idle",
				modelscale = 0.5,
				angles = "0 0 0",
				origin = "-8 0 -16",
				disableshadows = 1
			})
		hTank_scope.hTank_light <-
		SpawnEntityFromTable("info_particle_system",
			{
				targetname = "tank_turret_particle",
				effect_name = "cart_flashinglight",
				start_active = 1,
				// origin = "20 20 100"
			})
		
		hTank_scope.hTank_tank_turret_shooter_grenade <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_grenade",
				angles = "3 0 0",
				origin = "68 0 76",
				Damage = 110,
				SpeedMax = 900,
				SpeedMin = 600,
				SplashRadius = 250,
				SpreadAngle = 2,
				WeaponType = 3,
				ModelScale = 1,
				ModelOverride = "models/weapons/w_models/w_grenade_grenadelauncher.mdl",
				//Crits = 1,
			})
		
		hTank_scope.hTank_tank_turret_shooter_n <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_n",
				angles = "3 0 0",
				origin = "68 0 76",
				Damage = 90,
				SpeedMax = 1800,
				SpeedMin = 1800,
				SplashRadius = 180,
				SpreadAngle = 2,
				WeaponType = 0,
				//Crits = 1,
			})
		hTank_scope.hTank_tank_turret_shooter_w <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_w",
				angles = "3 90 0",
				origin = "-16 62 76",
				Damage = 90,
				SpeedMax = 1800,
				SpeedMin = 1800,
				SplashRadius = 180,
				SpreadAngle = 2,
				WeaponType = 0,
				//Crits = 1,
			})
		hTank_scope.hTank_tank_turret_shooter_nw <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_nw",
				angles = "3 45 0",
				origin = "40 62 76",
				Damage = 90,
				SpeedMax = 1800,
				SpeedMin = 1800,
				SplashRadius = 180,
				SpreadAngle = 2,
				WeaponType = 0,
				//Crits = 1,
			})
		hTank_scope.hTank_tank_turret_shooter_e <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_e",
				angles = "3 -90 0",
				origin = "-16 -62 76",
				Damage = 90,
				SpeedMax = 1800,
				SpeedMin = 1800,
				SplashRadius = 180,
				SpreadAngle = 2,
				WeaponType = 0,
				//Crits = 1,
			})
		hTank_scope.hTank_tank_turret_shooter_ne <-
		SpawnEntityFromTable("tf_point_weapon_mimic",
			{
				targetname = "tank_turret_shooter_ne",
				angles = "3 -45 0",
				origin = "40 -62 76",
				Damage = 90,
				SpeedMax = 1800,
				SpeedMin = 1800,
				SplashRadius = 180,
				SpreadAngle = 2,
				WeaponType = 0,
				//Crits = 1,
			})
			
		// Crits or not
		hTank_scope.isCrit <- false
		if (sParams.len() > 1)
		{
			
			if (sParams[1] == "crit")
			{
				hTank_scope.isCrit = true
			}
		}
		
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_grenade, "m_bCrits", hTank_scope.isCrit)
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_n, "m_bCrits", hTank_scope.isCrit)
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_e, "m_bCrits", hTank_scope.isCrit)
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_w, "m_bCrits", hTank_scope.isCrit)
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_ne, "m_bCrits", hTank_scope.isCrit)
		SetPropBool(hTank_scope.hTank_tank_turret_shooter_nw, "m_bCrits", hTank_scope.isCrit)
		
		TankExt.SetParentArray([
		hTank_scope.hTank_cart_prop, 
		hTank_scope.hTank_turret_prop_bomb,
		hTank_scope.hTank_tank_turret_shooter_grenade,
		hTank_scope.hTank_tank_turret_shooter_n,
		hTank_scope.hTank_tank_turret_shooter_w,
		hTank_scope.hTank_tank_turret_shooter_e,
		hTank_scope.hTank_tank_turret_shooter_nw,
		hTank_scope.hTank_tank_turret_shooter_ne,
		], hTank)
		
		TankExt.SetParentArray([hTank_scope.hTank_light] , hTank_scope.hTank_cart_prop)
		
		hTank_scope.FireTankEnts <- function()
		{
			// Original tank model removal
			EntFireByHandle(self, "addoutput", "rendermode 1", 0, self, self)
			EntFireByHandle(self, "alpha", "0", 0, self, self)
			SetPropBool(self, "m_bGlowEnabled", false)
			
			// Fake bomb alpha
			EntFireByHandle(hTank_scope.hTank_turret_prop_bomb, "addoutput", "rendermode 1", 0, self, self)
			EntFireByHandle(hTank_scope.hTank_turret_prop_bomb, "alpha", "0", 0, self, self)
			
			// New model glow + light
			local cart_glow = SpawnEntityFromTable("tf_glow",
			{
				targetname = "tank_cart_prop_glow",
				target = "bignet"
				GlowColor = "135 172 204 255"
			})
			TankExt.SetParentArray([cart_glow] , hTank_scope.hTank_cart_prop)
			NetProps.SetPropEntity(cart_glow, "m_hTarget", hTank_scope.hTank_cart_prop)
			
			EntFireByHandle(hTank_scope.hTank_light, "SetParentAttachment", "light", 1, self, self)
			
			EntFireByHandle("spawntr", "trigger", "", 1, self, self)
		}
		
		hTank_scope.FireTankEnts()
		
		// Check for bomb deploying
		hTank_scope.hBomb <- null
		hTank_scope.hTrack <- null
		for(local hChild = hTank.FirstMoveChild(); hChild; hChild = hChild.NextMovePeer())
		{
			local sChildModel = hChild.GetModelName().tolower()
			if(sChildModel.find("track_r"))
				hTank_scope.hTrack = hChild
			else if(sChildModel.find("bomb_mechanism"))
				hTank_scope.hBomb = hChild
		}
		hTank_scope.bDeploying <- false
		hTank_scope.BombDeployThink <- function()
		{
			// Smoke Particles
			if (!past_20percent)
			{
				EntFireByHandle(self, "DispatchEffect", "ParticleEffectStop", -1, null, null)
			}
			if(!bDeploying && hBomb.GetSequenceName(hBomb.GetSequence()) == "deploy")
			{
				bDeploying = true
				hTank_scope.hTank_turret_prop_bomb.AcceptInput("SetAnimation", "deploy", null, null)
				EntFireByHandle(hTank_scope.hTank_turret_prop_bomb, "alpha", "255", 0, self, self) // Make visible
				// Give fake bomb glow
				local bomb_glow = SpawnEntityFromTable("tf_glow",
				{
					targetname = "tank_bomb_prop_glow",
					target = "bignet"
					GlowColor = "112 169 230 255"
				})
				TankExt.SetParentArray([bomb_glow] , hTank_scope.hTank_turret_prop_bomb)
				NetProps.SetPropEntity(bomb_glow, "m_hTarget", hTank_scope.hTank_turret_prop_bomb)
			}
			//SetPropIntArray(self, "m_nModelIndexOverrides", iEmpty, 0)
			//SetPropIntArray(self, "m_nModelIndexOverrides", iEmpty, 3)
			return -1
		}
		TankExt.AddThinkToEnt(hTank, "BombDeployThink")
		
		// Tank firing
		
		hTank_scope.EmitFireSound <- function(hsound, hvolume = 100, hpitch = 100)
		{
			EmitSoundEx({
				sound_name = hsound
				entity = self
				filter_type = RECIPIENT_FILTER_GLOBAL
				sound_level = hvolume
				pitch = hpitch
			})
		}
		
		hTank_scope.ShootDirection <- function(direction, shoottype, issuper  = true)
		{
			if (past_20percent)
			{
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`player/taunt_moped_start_shake.wav`, 90, 122)", 0.0, self, self)
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`player/taunt_moped_start_shake.wav`, 90, 122)", 0.67, self, self)
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`player/taunt_moped_start_shake.wav`, 90, 122)", 1.33, self, self)
				
				EntFireByHandle(hTank_cart_prop, "setanimation", direction, 0.0, self, self)
				EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "1", 0.01, self, self)
				switch (shoottype)
				{
					case "n": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 0.5, self, self); break
					case "e": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 0.5, self, self); break
					case "w": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 0.5, self, self); break
					case "ne": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 0.5, self, self); break
					case "nw": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 0.5, self, self); break
					case "grenade": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 0.5, self, self); break
				}
				
				switch (shoottype)
				{
					case "n": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_N", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 1.15, self, self); break
					case "e": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_W", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 1.15, self, self); break
					case "w": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_E", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 1.15, self, self); break
					case "ne": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_NW", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 1.15, self, self); break
					case "nw": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_NE", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 1.15, self, self); break
					case "grenade": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_N", 0.65, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 1.1, self, self); break
				}
				EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "1", 0.66, self, self)
				
				switch (shoottype)
				{
					case "n": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_NE", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 1.8, self, self); break
					case "e": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_NW", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 1.8, self, self); break
					case "w":
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_N", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 1.8, self, self); break
					case "ne":
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_W", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 1.8, self, self); break
					case "nw": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_N", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 1.8, self, self); break
					case "grenade": 
					EntFireByHandle(hTank_cart_prop, "setanimation", "shoot_E", 1.3, self, self)
					EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 1.8, self, self); break
				}
				EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "1", 1.31, self, self)
				return
			}
			if (past_60percent)
			{
				EntFireByHandle(hTank_cart_prop, "setanimation", direction, 0.1, self, self)
				EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "2", 0.11, self, self)
				switch (shoottype)
				{
					case "n": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 0.5, self, self); break
					case "e": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 0.5, self, self); break
					case "w": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 0.5, self, self); break
					case "ne": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 0.5, self, self); break
					case "nw": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 0.5, self, self); break
					case "grenade": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 0.5, self, self); break
				}
				EntFireByHandle(hTank_cart_prop, "setanimation", direction, 1.1, self, self)
				EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "2", 1.11, self, self)
				switch (shoottype)
				{
					case "n": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 1.5, self, self); break
					case "e": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 1.5, self, self); break
					case "w": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 1.5, self, self); break
					case "ne": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 1.5, self, self); break
					case "nw": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 1.5, self, self); break
					case "grenade": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 1.5, self, self); break
				}
				return
			}
			//else
			EntFireByHandle(hTank_cart_prop, "setanimation", direction, 0, self, self)
			EntFireByHandle(hTank_cart_prop, "SetPlaybackRate", "0.66", 0.01, self, self)
			switch (shoottype)
			{
				case "n": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`n`)", 0.8, self, self); break
				case "e": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`e`)", 0.8, self, self); break
				case "w": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`w`)", 0.8, self, self); break
				case "ne": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`ne`)", 0.8, self, self); break
				case "nw": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`nw`)", 0.8, self, self); break
				case "grenade": EntFireByHandle(self, "RunScriptCode", "ShootTurret(`grenade`)", 0.8, self, self); break
			}
			return
		}
		
		hTank_scope.ShootTurret <- function(shoottype)
		{
			
			switch (shoottype)
			{
				case "n": hTank_tank_turret_shooter_n.AcceptInput("FireOnce", null, null, null); break
				case "e": hTank_tank_turret_shooter_e.AcceptInput("FireOnce", null, null, null); break
				case "w": hTank_tank_turret_shooter_w.AcceptInput("FireOnce", null, null, null); break
				case "ne": hTank_tank_turret_shooter_ne.AcceptInput("FireOnce", null, null, null); break
				case "nw": hTank_tank_turret_shooter_nw.AcceptInput("FireOnce", null, null, null); break
				case "grenade": hTank_tank_turret_shooter_grenade.AcceptInput("FireOnce", null, null, null); EntFireByHandle(hTank_tank_turret_shooter_grenade, "DetonateStickies", null, 2.5, null, null); break
			}
			if (past_20percent)
			{
				switch (shoottype)
				{
					case "grenade": hTank_scope.EmitFireSound("mvm/giant_demoman/giant_demoman_grenade_shoot.wav", 100, 130); break
					default:
					if (isCrit)
					{
						hTank_scope.EmitFireSound("mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav", 100, 130)
					}
					else
					{
						hTank_scope.EmitFireSound("mvm/giant_soldier/giant_soldier_rocket_shoot.wav", 100, 130)
					}
					break
				}
			}
			else
			{
				switch (shoottype)
				{
					case "grenade": hTank_scope.EmitFireSound("mvm/giant_demoman/giant_demoman_grenade_shoot.wav", 100, 112); break
					default: 
					if (isCrit)
					{
						hTank_scope.EmitFireSound("mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav", 100, 112)
					}
					else
					{
						hTank_scope.EmitFireSound("mvm/giant_soldier/giant_soldier_rocket_shoot.wav", 100, 112)
					}
					break
				}
			}
		}
		
		hTank_scope.looptime <- Time() + RandomFloat(3.0, 6.0)
		hTank_scope.looptime_super <- Time()
		hTank_scope.shootpattern <- 0
		hTank_scope.tank_turret_shoot <- function()
		{
			local FindGrenades = function(hMimic)
			{
				for(local hNade; hNade = FindByClassnameWithin(hNade, "tf_projectile_pipe", hMimic.GetOrigin(), 32);)
					if(GetPropEntity(hNade, "m_hThrower") == null && hNade.GetOwner() == null)
					{
						hNade.SetTeam(self.GetTeam())
						hNade.SetOwner(self)
						hGrenades.append(hNade)
					}
			}

			if(hTank_tank_turret_shooter_grenade && hTank_tank_turret_shooter_grenade.IsValid())
				FindGrenades(hTank_tank_turret_shooter_grenade)
				
			if(Time() >= looptime)
			{
				looptime += 12 //+ RandomFloat(0.0, 2.0)
				
				shootpattern = RandomInt(0, 3)
				switch (shootpattern)
				{
				case 0:
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `n`)", 0, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_E`, `e`)", 2, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NE`, `ne`)", 4, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NW`, `nw`)", 6, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_W`, `w`)", 8, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `grenade`)", 10, self, self)
				break
				
				case 1:
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_W`, `w`)", 0, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NW`, `nw`)", 2, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `grenade`)", 4, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NE`, `ne`)", 6, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_E`, `e`)", 8, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `n`)", 10, self, self)
				break
				
				case 2:
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NE`, `ne`)", 0, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NW`, `nw`)", 2, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `n`)", 4, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_E`, `e`)", 6, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `grenade`)", 8, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_W`, `w`)", 10, self, self)
				break
				
				case 3:
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_E`, `e`)", 0, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `n`)", 2, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_W`, `w`)", 4, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_N`, `grenade`)", 6, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NE`, `ne`)", 8, self, self)
				EntFireByHandle(self, "RunScriptCode", "ShootDirection(`shoot_NW`, `nw`)", 10, self, self)
				break
				}
				
			}
			return -1
		}
		TankExt.AddThinkToEnt(hTank, "tank_turret_shoot")
		
		// Rage mode
		
		hTank_scope.HealthCheckThink <- function()
		{
			local current_health = self.GetHealth()
			
			if (hTank_scope.past_20percent)
			{
				return
			}
			if (current_health < tank_health_20percent)
			{
				past_20percent = true
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`mvm/mvm_tank_ping.wav`, 85, 75)", 0.5, self, self)
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`ambient/grinder/grinderbot_02.wav`, 120, 110)", 0.0, self, self)
				return -1
			}
			if (hTank_scope.past_60percent)
			{
				return -1
			}
			if (current_health < tank_health_60percent)
			{
				past_60percent = true
				EntFireByHandle(self, "RunScriptCode", "EmitFireSound(`misc/doomsday_cap_close_start.wav`, 100, 110)", 0.0, self, self)
				return -1
			}
			return -1
		}
		TankExt.AddThinkToEnt(hTank, "HealthCheckThink")
	}
	
	OnDeath = function()
	{
		foreach(hNade in hGrenades)
			if(hNade && hNade.IsValid())
				hNade.Kill()
	}
})