SpawnEntityFromTable("info_particle_system",
{
targetname = "fire"
origin = Vector(164, -1320, 0),
start_active = 1,
effect_name = "lava_fireball"
})

SpawnEntityFromTable("info_particle_system",
{
targetname = "fire"
origin = Vector(190, -1561, -100),
start_active = 1,
effect_name = "cauldron_smoke_lit_bottom"
})
SpawnEntityFromTable("info_particle_system",
{
targetname = "fire"
origin = Vector(100, -1053, -100),
start_active = 1,
effect_name = "cauldron_smoke_lit_bottom"
})
SpawnEntityFromTable("info_particle_system",
{
targetname = "fire"
origin = Vector(618, -1320, -100),
start_active = 1,
effect_name = "cauldron_smoke_lit_bottom"
angles = "-90 0 0"
})
SpawnEntityFromTable("info_particle_system",
{
targetname = "fire"
origin = Vector(-24, -1262, -100),
start_active = 1,
effect_name = "cauldron_smoke_lit_bottom"
angles = "-90 0 0"
})

SpawnEntityFromTable("info_particle_system",
{
targetname = "beam"
origin = Vector(164, -1320, 50),
start_active = 1,
effect_name = "teleporter_mvm_bot_persist"
})

local spawnfire = function(position) {
SpawnEntityFromTable("info_particle_system",
{
	targetname = "fire"
	origin = position,
	start_active = 1,
	effect_name = "cauldron_flamethrower"
	angles = "-90 0 0"
})
}

// Silo fire mid
spawnfire(Vector(602, -1568, -100))
spawnfire(Vector(551, -1627, -100))

// Right silo fire
spawnfire(Vector(514, -1879, -100))

// Left Entrance fire
spawnfire(Vector(761, -1529, -100))

// Right Entrance fire
spawnfire(Vector(855, -1128, -70))
spawnfire(Vector(870, -1213, -100))

// Grate fire
spawnfire(Vector(-93, -1528, -100))

// Ground fire
spawnfire(Vector(384, -1426, -130))
spawnfire(Vector(539, -1268, -150))
spawnfire(Vector(154, -1623, -150))
spawnfire(Vector(-82, -1211, -120))

local spawnalarm = function(position, angle, offset = 0) {
    // Forward vector from angle
    local fwd = angle.Forward();

    // Compute perpendicular vector ("normal") using cross product with global up
    local up = Vector(1, 0, 0);
    local normal = fwd.Cross(up); // perpendicular sideways
    if (normal.Length() < 0.001) {
        // In case forward is parallel to up, use right-hand alternative
        normal = fwd.Cross(Vector(0,1,0));
    }
    normal.Norm(); // normalize

    // Apply offset along this normal
    local finalPos = position + (normal * offset);

    SpawnEntityFromTable("info_particle_system",
    {
        targetname = "alarm"
        origin = position
        start_active = 1
        effect_name = "cart_flashinglight_red"
    })
    SpawnEntityFromTable("info_particle_system",
    {
        targetname = "alarm"
        origin = finalPos
        start_active = 1
        effect_name = "mvm_emergencylight_glow_red"
    })
    SpawnEntityFromTable("prop_dynamic",
    {
        targetname = "tele_indicator1"
        origin = position
        model = "models/pickups/emitter.mdl"
        skin = 1
        modelscale = "0.5 0.5 0.5"
        angles = angle
    })
}

spawnalarm(Vector(1663, -1274, 225), QAngle(180, 0, 0), 0)
spawnalarm(Vector(1286, -2450, 290), QAngle(130, -90, 0), 10)
spawnalarm(Vector(-1160, -1550, 665), QAngle(180, 0, 0), 0)
spawnalarm(Vector(-1740, -1550, 665), QAngle(180, 0, 0), 0)
spawnalarm(Vector(-732, 1665, 140), QAngle(90, -90, 0), 0)
spawnalarm(Vector(2587, -2027, 210), QAngle(90, -75, 0), 0)

SpawnEntityFromTable("info_particle_system",
{
	targetname = "tanksplosion"
	origin = Vector(164, -1320, 50),
	start_active = 1,
	effect_name = "mvm_tank_destroy"
})

// Create the killbox

local filter = Entities.FindByName(null, "red_only_filter")
	if (filter == null)
	{
		SpawnEntityFromTable("filter_activator_tfteam", {
			targetname = "red_only_filter",
			teamnum = 2,
			Negated = 0
		})
	}
	
local newtriggerhurt = SpawnEntityFromTable("trigger_hurt", {
	targetname = "human_hurt",
	damage = 9999,
	damagetype = 8,
	filtername = "red_only_filter",
	spawnflags = 1 // Clients only
	startdisabled = 0,
})
newtriggerhurt.SetAbsOrigin(Vector(166, -1327, 127))
newtriggerhurt.SetSize(Vector(-60, -45, -105), Vector(60, 45, 105))
newtriggerhurt.SetSolid(Constants.ESolidType.SOLID_BBOX)

::inter_breach <- 
{
	//last_blink = 0
	//blink_cooldown = 4
	
	// CLEANUP
	Cleanup = function()
	{
		delete ::inter_breach
	}
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }

	
	// SPAWN HANDLING
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(!IsPlayerABot(player)) {
			return
		}
		EntFireByHandle(player, "RunScriptCode", "inter_breach.spawncheck(activator)", 0, player, null)
	}
	spawncheck = function(player) {
		local bottags = {}
		player.GetAllBotTags(bottags)
		foreach(i, tag in bottags) {
			if (tag == "telefire") {
				player.Teleport(true, Vector(164, -1320, 200), true, player.EyeAngles(), true, player.GetAbsVelocity())
				player.AddCondEx(51, 1.0, null)
				EmitSoundEx({
					sound_name = "mvm/mvm_tele_deliver.wav"
					channel = 6
					volume = 1.0
					sound_level = 0
					filter_type = 5
					flags = 1
				})
			}
		}
	}
}
__CollectGameEventCallbacks(inter_breach)


/*
SpawnEntityFromTable("env_fade" , {
	targetname = "alarm_flash"
	duration		=	3
	holdtime		=	"0.5"
	renderamt		=	25
	fogmaxdensity	=	1.2
	rendercolor		=	"252 53 3"
	spawnflags		=	1
})

if (Entities.FindByName(null, "_2int2") == null)
{
	local inter = SpawnEntityFromTable("info_teleport_destination", { targetname = "_2int2" })
	inter.ValidateScriptScope()
	local scope = inter.GetScriptScope()
	scope.inter_think <- function() {
		if ("inter_breach" in getroottable()) {
			if (inter_breach.last_blink < Time()) {
				inter_breach.last_blink = Time() + inter_breach.blink_cooldown
				EntFire("alarm_flash","fade")
			}
		}
		return -1
	}
	AddThinkToEnt(inter, "inter_think")
}
*/

SpawnEntityFromTable("env_fade" , {
	targetname = "alarm_flash"
	duration		=	3
	holdtime		=	"0.5"
	renderamt		=	25
	fogmaxdensity	=	1.2
	rendercolor		=	"252 53 3"
	spawnflags		=	1
})
EntFire("alarm_flash","fade")