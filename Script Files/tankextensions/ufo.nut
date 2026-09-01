PrecacheModel("models/props_teaser/saucer.mdl")
PrecacheSound("weapons/capper_shoot.wav")
PrecacheSound("misc/doomsday_missile_launch.wav")
PrecacheSound("mvm/mvm_tele_activate.wav")
PrecacheSound("ui/chime_rd_2base_neg.wav")

TankExt.NewTankType("ufo*", {

	NoDestructionModel = 1
	Gravity            = 0
	DisableSmokestack  = 1
	DisableChildModels = 1
	Model              = {
		Visual = "models/empty.mdl"
	}
	
	OnSpawn = function()
	{
		
		// SETUP 				**********************************************************************
		
		local bBlueTeam = self.GetTeam() == 3
		local flSpeed = GetPropFloat(self, "m_speed")
		local fastSpeed = flSpeed * 30
		local normSpeedReached = false
		local soundtime = Time() + 3
		
		// SPAWN SOUNDS 		**********************************************************************
		
		EmitSoundEx({
			sound_name = "misc/doomsday_missile_launch.wav"
			entity = self
			filter_type = RECIPIENT_FILTER_GLOBAL
			sound_level = 0
			pitch = 130
		})
		EmitSoundEx({
			sound_name = "mvm/mvm_tele_activate.wav"
			entity = self
			filter_type = RECIPIENT_FILTER_GLOBAL
			sound_level = 0
			pitch = 45
		})
		
		// PROPS 				**********************************************************************
		
		local hTank_ufo_prop =
		TankExt.SpawnEntityFromTableFast("prop_dynamic",
		{
			targetname = "tank_ufo_prop",
			model = "models/props_teaser/saucer.mdl",
			solid = 0,
			modelscale = "2.7 2.7 2.7",
			angles = "0 0 0",
		})
			
		local ufo_glow = TankExt.SpawnEntityFromTableFast("tf_glow",
		{
			targetname = "tank_ufo_prop_glow",
			target = "bignet"
			GlowColor = "135 172 204 255"
		})
			
		local hTank_prop_bomb =
		TankExt.SpawnEntityFromTableFast("prop_dynamic",
			{
				targetname = "tank_prop_bomb",
				model = "models/bots/boss_bot/bomb_mechanism.mdl",
				//startdisabled = 1,
				solid = 0,
				// modelscale = 0.5,
				angles = "0 0 0",
				origin = "0 0 -130",
				disableshadows = 1
			})
			
		// Fake bomb alpha
		EntFireByHandle(hTank_prop_bomb, "addoutput", "rendermode 1", 0, self, self)
		EntFireByHandle(hTank_prop_bomb, "alpha", "0", 0, self, self)
		
		local hTank_ufo_turret =
		TankExt.SpawnEntityFromTableFast("tf_point_weapon_mimic",
			{
				targetname = "ufo_turret",
				angles = "90 0 0",
				origin = "0 0 -50",
				Damage = 90,
				SpeedMax = 500,
				SpeedMin = 700,
				SplashRadius = 180,
				SpreadAngle = 10,
				WeaponType = 0,
				//Crits = 1,
			})
		local hTrail =
		TankExt.SpawnEntityFromTableFast("env_spritetrail", {
			origin     = "0 0 15"
			spritename = self.GetTeam() == 3 ? "effects/beam001_blu.vmt" : "effects/beam001_red.vmt"
			startwidth = 150
			endwidth   = 1
			lifetime   = 1
		})
			
		TankExt.SetParentArray([
		hTank_ufo_prop, 
		hTank_prop_bomb,
		hTank_ufo_turret,
		hTrail,
		], self)
		
		TankExt.SetParentArray([ufo_glow] , hTank_ufo_prop)
		NetProps.SetPropEntity(ufo_glow, "m_hTarget", hTank_ufo_prop)
		
		// PARAMS 			**********************************************************************
		
		local firerate = 1.4
		local turretoffset = 30.0
		local firedelay = 0.0
		local speedmult = 1.0
		
		// FORMAT: "ufo|bool crit|float firerate|float offset|float delay|float speedmult"
		
		local sParams = split(sTankName, "|")
		if (sParams.len() > 1)
		{
			if (sParams[1] == "true") SetPropBool(hTank_ufo_turret, "m_bCrits", true)
			if (sParams.len() > 2)  firerate = sParams[2].tofloat()
			if (sParams.len() > 3)  turretoffset = sParams[3].tofloat()
			if (sParams.len() > 4)  firedelay = sParams[4].tofloat()
			if (sParams.len() > 5)  speedmult = sParams[5].tofloat()
		}
		
		// DEPLOYMENT CHECKS 	**********************************************************************
		
		local iDeploySeq = self.LookupSequence("deploy")
		local bDeploying = false
		local rotateangle = 0
		local rotateangle = 0
		
		// ROCKET FUNCTIONS 	**********************************************************************
		
		local ufoIsVisible = function(target) {
			local trace = {
				start  = self.GetOrigin(),
				end    = target.EyePosition(),
				mask   = MASK_OPAQUE,
			}
			TraceLineEx(trace)
			return !trace.hit
		}
		local ufoIsValidTarget = function(victim, distance, min_distance, projectile) {

			local projectile_scope = projectile.GetScriptScope()
			// Early out if basic conditions aren't met
			if (distance > min_distance || victim.GetTeam() == projectile.GetTeam() || !victim.IsAlive()) {
				return false
			}
			
			if (!ufoIsVisible(victim) || victim.GetOrigin().z > self.GetOrigin().z) return

			// Check for conditions based on the projectile's configuration
			if (victim.IsPlayer()) {
				if (victim.InCond(TF_COND_HALLOWEEN_GHOST_MODE)) {
					return false
				}

				// Check for stealth and disguise conditions if not ignored
				if (victim.IsStealthed() || victim.IsFullyInvisible()) {
					return false
				}
				if (victim.GetDisguiseTarget() != null) {
					return false
				}
			}

			return true
		}
		local ufoIsValidTarget_b = function(victim_b, distance_b, min_distance_b, projectile) {

			local projectile_scope = projectile.GetScriptScope()
			// Early out if basic conditions aren't met
			if (!ufoIsVisible(victim_b) || distance_b > min_distance_b || victim_b.GetTeam() == projectile.GetTeam() || !victim_b.IsAlive()) {
				return false
			}

			return true
		}
		
		local ufoVectorAngles = function(forward) {
			local yaw, pitch
			if ( forward.y == 0.0 && forward.x == 0.0 ) {
				yaw = 0.0
				if (forward.z > 0.0)
					pitch = 270.0
				else
					pitch = 90.0
			}
			else {
				yaw = (atan2(forward.y, forward.x) * 180.0 / Pi)
				if (yaw < 0.0)
					yaw += 360.0
				pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / Pi)
				if (pitch < 0.0)
					pitch += 360.0
			}

			return QAngle(pitch, yaw, 0.0)
		}
		
		local ufoFaceTowards = function(new_target, projectile) {
			local desired_dir = new_target.EyePosition() - projectile.GetOrigin()
			desired_dir += Vector(RandomFloat(-turretoffset, turretoffset),RandomFloat(-turretoffset, turretoffset),RandomFloat(-turretoffset, turretoffset))
			desired_dir.Norm()
			
			local move_ang = ufoVectorAngles(desired_dir)
			local projectile_velocity = move_ang.Forward() * projectile.GetAbsVelocity().Norm() * speedmult
			projectile.SetAbsVelocity(projectile_velocity)
			projectile.SetLocalAngles(move_ang)
		}
		
		local ufoSelectVictim = function(projectile) {
			local target
			local target_b
			local final_target
			local min_distance = 32768.0
			local min_distance_b = 32768.0
			for (local i = 1; i <= MaxClients().tointeger(); i++) {
				local player = PlayerInstanceFromIndex(i)
				if (player != null && !player.IsBotOfType(1337) && player.GetTeam() == 2) {
					local distance = (projectile.GetOrigin() - player.GetOrigin()).Length()

					if (ufoIsValidTarget(player, distance, min_distance, projectile)) {
						target = player
						min_distance = distance
					}
				}
			}
			for (local building; building = Entities.FindByClassname(building, "obj_*");)
			{
				local distance_b = (projectile.GetOrigin() - building.GetOrigin()).Length()

				if (ufoIsValidTarget_b(building, distance_b, min_distance_b, projectile)) {
					target_b = building
					min_distance_b = distance_b
				}
			}
			if (min_distance < min_distance_b)
			{
				final_target = target
			}
			else
			{
				final_target = target_b
			}
			return final_target
		}
		
		local looptime = Time() + RandomFloat(2.0, 4.0) + firedelay
		
		// UFO THINK 	**********************************************************************
		
		function Think()
		{
			// are we deploying?
			if(!bDeploying && self.GetSequence() == iDeploySeq)
			{
				bDeploying = true
				
				hTank_prop_bomb.AcceptInput("SetAnimation", "deploy", null, null)
				EntFireByHandle(hTank_prop_bomb, "alpha", "255", 0, self, self) // Make visible
				// Give fake bomb glow
				local bomb_glow = TankExt.SpawnEntityFromTableFast("tf_glow",
				{
					targetname = "tank_bomb_prop_glow",
					target = "bignet"
					GlowColor = "135 172 204 255"
				})
				TankExt.SetParentArray([bomb_glow] , hTank_prop_bomb)
				NetProps.SetPropEntity(bomb_glow, "m_hTarget", hTank_prop_bomb)
			}
			
			// SPEEEEEEEN
			
			if (rotateangle > 360) rotateangle -= 360
			rotateangle += 1
			hTank_ufo_prop.SetAbsAngles(QAngle(0, rotateangle, 0))
			
			// UFO speed manipulation
			
			if (!normSpeedReached)
			{
				if (fastSpeed > flSpeed)
				{
					fastSpeed -= flSpeed * 0.2
					self.AcceptInput("SetSpeed", fastSpeed.tostring(), null, null)
					
				}
				else
				{
					self.AcceptInput("SetSpeed", flSpeed.tostring(), null, null)
					normSpeedReached = true
				}
			}
			
			// Rocket firing
			
			for (local projectile; projectile = FindByClassname(projectile, "tf_projectile_*");) {
					if (projectile.IsEFlagSet(2097152) || projectile.GetOwner() != hTank_ufo_turret) continue

					projectile.ValidateScriptScope()
					local projectile_scope = projectile.GetScriptScope()
					
					projectile.AddEFlags(2097152)
					
					local new_target = ufoSelectVictim(projectile)
					if (new_target != null) {
						ufoFaceTowards(new_target, projectile)
					}
				}		
			
			if(Time() >= looptime)
			{
				looptime += firerate
				
				hTank_ufo_turret.AcceptInput("FireOnce", null, null, null)
				
				EmitSoundEx({
					sound_name = "weapons/capper_shoot.wav"
					entity = self
					filter_type = RECIPIENT_FILTER_GLOBAL
					sound_level = 105
				})
			}
			
			// UFO pings
			
			if(Time() >= soundtime)
			{
				soundtime += 2.0
				
				EmitSoundEx({
					sound_name = "ui/chime_rd_2base_neg.wav"
					entity = self
					filter_type = RECIPIENT_FILTER_GLOBAL
					sound_level = 97
					pitch = 50
				})
			}
		}
		
		// for rancher photon farm - activates the dam bomb deploy sequence
		function ForceBombDeploy()
		{
			hBomb.ResetSequence(1)
		}
	}
})