PrecacheSound("mvm/mvm_bomb_warning.wav")

// Spawnable positions
local survivalportalpositions =
{
	"prtl_flank_left" : Vector(-890, 1840, 150)
	"prtl_flank_right" : Vector(1050, 1912, 180)
	"prtl_top_left" : Vector(-502, 1688, 460)
	"prtl_top_right" : Vector(438, 1837, 595)
	"prtl_front_main" : Vector(364, 4040, 300)
	"prtl_front_flank" : Vector(-756, 4700, 32)
}

// Portal spawner
function CreateSurvivalPortal(position) {
	// Create the particle system
	
	local portalthing = (SpawnEntityFromTable("info_particle_system",
	{
		targetname = "portal1"
		origin = position,
		start_active = 1,
		effect_name = "eyeboss_tp_vortex"
	}))
	
	// Create the killbox
	
	local newtriggerhurt = SpawnEntityFromTable("trigger_hurt", {
		targetname = "human_hurt",
		damage = 9999,
		damagetype = 0,
		filtername = "red_only_filter",
		spawnflags = 1 // Clients only
		startdisabled = 0,
	})
	newtriggerhurt.SetAbsOrigin(position)
	newtriggerhurt.SetSize(Vector(-70, -70, -70), Vector(70, 70, 70))
	newtriggerhurt.SetSolid(Constants.ESolidType.SOLID_BBOX)
}

::survivalspawns <- 
{
	// CLEANUP
	Cleanup = function()
	{
		delete ::survivalspawns
	}
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }
	
	warningsound_intervals = [30, 20, 15, 10, 8, 6, 4, 3, 2, 1, -60]
	current_warningsound = 0
	timerbot = null
	bossbot = null
	bossportal = null
	
	// SPAWN HANDLING
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(!IsPlayerABot(player)) {
			return
		}
		EntFireByHandle(player, "RunScriptCode", "survivalspawns.teletospawn(activator)", -1, player, null)
		EntFireByHandle(player, "RunScriptCode", "survivalspawns.timerbot1(activator)", 0, player, null)
		EntFireByHandle(player, "RunScriptCode", "survivalspawns.timerbot2(activator)", 3, player, null)
	}
	timerbot1 = function(player) {
		local bottags = {}
		player.GetAllBotTags(bottags)
		foreach(i, tag in bottags) {
			if (tag == "timerbot") {
				EntFireByHandle(player, "addoutput", "rendermode 1", 0, null, null)
				EntFireByHandle(player, "alpha", "0", 0, null, null)
				SetPropBool(player, "m_bGlowEnabled", false)
				for (local child = player.FirstMoveChild(); child != null; child = child.NextMovePeer()) {
					EntFireByHandle(child, "addoutput", "rendermode 1", 0, null, null)
					EntFireByHandle(child, "alpha", "0", 0, null, null)
					SetPropBool(child, "m_bGlowEnabled", false)
				}
				
				timerbot = player
			}
			if (tag == "THEBOSS") {
				bossbot = player
			}
		}
		for (local flag; flag = Entities.FindByClassname(flag, "item_teamflag");)
		{
			EntFireByHandle(flag, "addoutput", "rendermode 1", 0, null, null)
			EntFireByHandle(flag, "alpha", "0", 0, null, null)
			SetPropBool(flag, "m_bGlowEnabled", false)
		}
	}
	timerbot2 = function(player) {
		local bottags = {}
		player.GetAllBotTags(bottags)
		foreach(i, tag in bottags) {
			if (tag == "timerbot") {
				player.RemoveCondEx(5, true)
				player.RemoveCondEx(51, true)
				printl("REMOVED UBER OFF TIMERBOT")
				
				player.Teleport(true, Vector(2007, 4949, 400), true, player.EyeAngles(), true, Vector(0,0,0))
			}
		}
	}
	teletospawn = function(player) {
		local bottags = {}
		player.GetAllBotTags(bottags)
		foreach(i, tag in bottags) {
			if (tag in survivalportalpositions) {
				player.Teleport(true, survivalportalpositions[tag], true, player.EyeAngles(), true, player.GetAbsVelocity())
				player.AddCondEx(51, 2.5, null)
			}
			if (tag == "prtl_boss") {
				if (bossbot) {
					player.Teleport(true, bossbot.EyePosition() - player.GetClassEyeHeight() + Vector(0, 0, 20), true, player.EyeAngles(), true, player.GetAbsVelocity())
					player.AddCondEx(51, 1.5, null)
				}
			}
		}
	}
	
	bossportalspawn = function() {
		if (bossbot) {
			bossportal = SpawnEntityFromTable("info_particle_system",
			{
				targetname = "bossportal1"
				origin = bossbot.EyePosition(),
				start_active = 1,
				effect_name = "eyeboss_tp_vortex"
			})
			bossportal.AcceptInput("SetParent", "!activator", bossbot, null)
			EntFireByHandle(bossbot, "RunScriptCode", "survivalspawns.bossportal.Kill()", 4, bossbot, null)
		}
	}
};
__CollectGameEventCallbacks(survivalspawns)

function GiveNavAvoidToNavArea(name, area, tag = "", height = 500.0)
{
	local mins = (0 - (area.GetSizeX() / 2.0)).tostring() + " " + (0 - (area.GetSizeY() / 2.0)).tostring() + " " + (0 - (height / 2.0)).tostring()
	local maxs = (area.GetSizeX() / 2.0).tostring() + " " + (area.GetSizeY() / 2.0).tostring() + " " + (height / 2.0).tostring()
	
	local avoid = SpawnEntityFromTable("func_nav_avoid",
	{
		origin           = area.GetCenter()
		tags             = tag
	})
	
	avoid.KeyValueFromInt("solid", 2)
	avoid.KeyValueFromString("mins", mins)
	avoid.KeyValueFromString("maxs", maxs)
}
function SpawnNavBrush(name, pos, xyz1, xyz2, tagname = false)
{
	if (!tagname) tagname = name.slice(4)
	
	local navbrush = SpawnEntityFromTable("func_nav_avoid", { targetname = name, origin = pos, tags = tagname })

	navbrush.KeyValueFromInt("solid", 2)
	navbrush.KeyValueFromString("mins", xyz1)
	navbrush.KeyValueFromString("maxs", xyz2)
	
	local navbrush2 = SpawnEntityFromTable("func_nav_avoid", { targetname = name, origin = pos, tags = tagname }) // do it twice just to make sure

	navbrush2.KeyValueFromInt("solid", 2)
	navbrush2.KeyValueFromString("mins", xyz1)
	navbrush2.KeyValueFromString("maxs", xyz2)
}

// Based on a recognizable entity that will denote whether or not these portals have been setup yet

if (Entities.FindByName(null, "_survivalportals") == null)
{
	local survivalportals = SpawnEntityFromTable("info_teleport_destination", { targetname = "_survivalportals" })
	survivalportals.ValidateScriptScope()
	
	local scope = survivalportals.GetScriptScope()
	scope.SurvivalThink <- function() {
		if ("survivalspawns" in getroottable()) {
			if (survivalspawns.timerbot) {
				// printl(survivalspawns.timerbot.GetHealth())
				if (survivalspawns.timerbot.GetHealth() == survivalspawns.warningsound_intervals[survivalspawns.current_warningsound]) {
					EmitSoundEx({
						sound_name = "mvm/mvm_bomb_warning.wav"
						channel = 6
						pitch = 91 + survivalspawns.current_warningsound * 3
						volume = 1.0
						sound_level = 0
						filter_type = 5
						flags = 0
					})
					survivalspawns.current_warningsound += 1
				}
			}
		}
		return -1
	}
	AddThinkToEnt(survivalportals, "SurvivalThink")
	
	local filter = Entities.FindByName(null, "red_only_filter")
	if (filter == null)
	{
		SpawnEntityFromTable("filter_activator_tfteam", {
			targetname = "red_only_filter",
			teamnum = 2,
			Negated = 0
		})
	}
	foreach (pos in survivalportalpositions)
	{
		CreateSurvivalPortal(pos)
	}
	printl("SURVIVAL PORTALS HAVE BEEN SET UP!")
	
	// Add a nav avoid to this problematic area
	SpawnNavBrush("DONTHERE", "1023.5 2392.5 -81.5", "-45.5 -293.5 -69.5", "45.5 293.5 69.5", "bot_giant")
	SpawnNavBrush("DONTHERE", "897.5 2209 -42", "-139.5 -100 -22", "139.5 100 22", "bot_giant");
	
	// OG spawnroom... DONT GO HERE
	SpawnNavBrush("DONTHERE", "408.5 4351.5 -214", "-147.5 -199.5 -38", "147.5 199.5 38", "common bot_giant")
	SpawnNavBrush("DONTHERE", "-449 4700.5 -240", "-205 175.5 -33", "205 175.5 33", "common bot_giant")
	
	/*
	DebugDrawBox(Vector(1023.5, 2392.5, -81.5), Vector(-45.5, -293.5, -69.5), Vector(45.5, 293.5, 69.5), 255, 0, 0, 100, 20.0)
	DebugDrawBox(Vector(897.5, 2209, -42), Vector(-139.5, -100, -22), Vector(139.5, 100, 22), 255, 0, 0, 100, 20.0)
	DebugDrawBox(Vector(408.5, 4351.5, -214), Vector(-147.5, -199.5, -38), Vector(147.5, 199.5, 38), 255, 0, 0, 100, 20.0)
	DebugDrawBox(Vector(-449, 4700.5, -240), Vector(-205, 175.5, -33), Vector(205, -175.5, 33), 255, 0, 0, 100, 20.0)
	*/
}



