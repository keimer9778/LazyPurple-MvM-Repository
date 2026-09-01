::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

local OTHER_CONSTANTS = {
	MASK_ALL                   = -1
	MASK_SPLITAREAPORTAL       = 48
	MASK_SOLID_BRUSHONLY       = 16395
	MASK_WATER                 = 16432
	MASK_BLOCKLOS 			   = 16449
	MASK_OPAQUE                = 16513
	MASK_DEADSOLID             = 65547
	MASK_PLAYERSOLID_BRUSHONLY = 81931
	MASK_NPCWORLDSTTIC        = 131083
	MASK_NPCSOLID_BRUSHONLY    = 147467
	MASK_CURRENT               = 16515072
	MASK_SHOT_PORTAL           = 33570819
	MASK_SOLID                 = 33570827
	MASK_BLOCKLOS_AND_NPCS     = 33570881
	MASK_OPAQUE_AND_NPCS       = 33570945
	MASK_VISIBLE_AND_NPCS      = 33579137
	MASK_PLAYERSOLID           = 33636363
	MASK_NPCSOLID              = 33701899
	MASK_SHOT_HULL             = 100679691
	MASK_SHOT                  = 1174421507

	TF_STUN_NONE                  = 0
	TF_STUN_MOVEMENT              = 1
	TF_STUN_CONTROLS              = 2
	TF_STUN_MOVEMENT_FORWARD_ONLY = 4
	TF_STUN_SPECIAL_SOUND         = 8
	TF_STUN_DODGE_COOLDOWN        = 16
	TF_STUN_NO_EFFECTS            = 32
	TF_STUN_LOSER_STATE           = 64
	TF_STUN_BY_TRIGGER            = 128
	TF_STUN_SOUND                 = 256

	SND_NOFLAGS                              = 0
	SND_CHANGE_VOL                           = 1
	SND_CHANGE_PITCH                         = 2
	SND_STOP                                 = 4
	SND_SPAWNING                             = 8
	SND_DELAY                                = 16
	SND_STOP_LOOPING                         = 32
	SND_SPEAKER                              = 64
	SND_SHOULDPAUSE                          = 128
	SND_IGNORE_PHONEMES                      = 256
	SND_IGNORE_NAME                          = 512
	SND_DO_NOT_OVERWRITE_EXISTING_ON_CHANNEL = 1024

	// damagefilter redefinitions
	DMG_USE_HITLOCATIONS                    = DMG_AIRBOAT
	DMG_HALF_FALLOFF                        = DMG_RADIATION
	DMG_CRITICAL                            = DMG_ACID
	DMG_RADIUS_MAX                          = DMG_ENERGYBEAM
	DMG_IGNITE                              = DMG_PLASMA
	DMG_USEDISTANCEMOD                      = DMG_SLOWBURN
	DMG_NOCLOSEDISTANCEMOD                  = DMG_POISON
	DMG_MELEE                               = DMG_BLAST_SURFACE
	DMG_DONT_COUNT_DAMAGE_TOWARDS_CRIT_RATE = DMG_DISSOLVE
}

if (!("ConstantNamingConvention" in ROOT))
	foreach (a,b in Constants)
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}

foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

foreach(k,v in OTHER_CONSTANTS)
	if(!(k in ROOT))
	{
		CONST[k] <- v
		ROOT[k] <- v
	}


::IgnisLogic <- {
	ATTACK_RADIUS_MIN = 150
	ATTACK_RADIUS_MAX = 300

	TEMPLATE_NAME_REGULAR_ATTACK = "attacktemplate2"
	TEMPLATE_NAME_FAKE_ATTACK = "attacktemplate"

	MIN_ITERATIONS = 6
	MAX_ITERATIONS = 12
	// Obsolete
	//ATTACK_HEIGHT_ADDITIVE_MIN = 0
	//ATTACK_HEIGHT_ADDITIVE_MAX = 50
	
    function CorrectTargetPos(hBot, hTarget)
	{
		local trace_box_landing = {
			start = hTarget,
			end = hTarget,
			hullmin = hBot.GetBoundingMins(),
			hullmax = hBot.GetBoundingMaxs(),
			mask = MASK_PLAYERSOLID,
			ignore = hBot
		}
		TraceHull(trace_box_landing)
		if ("startsolid" in trace_box_landing)
		{
			local dirs = [Vector(1, 0, 0), Vector(-1, 0, 0), Vector(0, 1, 0), Vector(0, -1, 0), Vector(0, 0, 1), Vector(0, 0, -1)];
			for (local i = 16; i <= 96; i += 16)
			{
				foreach (dir in dirs)
				{
					trace_box_landing.start = hTarget + dir * i;
					trace_box_landing.end = trace_box_landing.start
					delete trace_box_landing.startsolid
					TraceHull(trace_box_landing)
					if (!("startsolid" in trace_box_landing))
					{
						return trace_box_landing.end
					}
				}
			}
		}
		return hTarget
	}
	function ShuffleTable(table)
	{
		local n = table.len()
		for(local i = n - 1; i > 0; i--)
		{
			local j = RandomInt(0, i)
			local tmp = table[i]
			table[i] = table[j]
			table[j] = tmp
		}
		return table
	}
	function SpawnExistingPointTemplateAtPos(pos, angles, templateName)
	{
		local hMaker = SpawnEntityFromTable("env_entity_maker", {
			EntityTemplate         = templateName,
			PostSpawnInheritAngles = "1"
		})
		hMaker.SetAbsOrigin(pos)
		hMaker.SetAbsAngles(angles)
		EntFireByHandle(hMaker, "ForceSpawn", null, -1, null, null)
		EntFireByHandle(hMaker, "Kill", null, 0.1, null, null)
	}
	function AttackWrapper(hTarget, IsFakeAttack = false)
	{
		local randDir = Vector(RandomFloat(-1.0, 1.0), RandomFloat(-1.0, 1.0), 0)
		randDir.Norm()
		local dist = RandomFloat(ATTACK_RADIUS_MIN, ATTACK_RADIUS_MAX)
		local heightAdd = RandomFloat(ATTACK_HEIGHT_ADDITIVE_MIN, ATTACK_HEIGHT_ADDITIVE_MAX)
		local rawPos = hTarget.GetOrigin() + randDir * dist + Vector(0, 0, heightAdd)
		local spawnPos = CorrectTargetPos(hTarget, rawPos)
		local Trace = {
				start = spawnPos
				end = spawnPos - Vector(0, 0, 1000)
				mask =  MASK_VISIBLE_AND_NPCS & ~(CONTENTS_MONSTER)
		}
		TraceLineEx(Trace)
		local dir = hTarget.GetOrigin() - Trace.pos
		dir.Norm()
		local yaw = atan2(dir.y, dir.x) * (180.0 / PI)
		local pitch = atan2(-dir.z, sqrt(dir.x * dir.x + dir.y * dir.y)) * (180.0 / PI)
		local ang = QAngle(pitch, yaw, 0)
		IgnisLogic.SpawnExistingPointTemplateAtPos(Trace.pos, ang, IsFakeAttack ? TEMPLATE_NAME_FAKE_ATTACK : TEMPLATE_NAME_REGULAR_ATTACK)
	}
	function TeleportAttack(hBot, ITERATION_COUNT = RandomInt(MIN_ITERATIONS, MAX_ITERATIONS))
	{
		local tAlivePlayers = []
		for(local i = 1; i <= MAX_CLIENTS; i++)
		{
			local hPlayer = PlayerInstanceFromIndex(i)
			if(hPlayer && hPlayer.IsAlive() && !hPlayer.IsFakeClient())
			{
				tAlivePlayers.append(hPlayer)
			}
		}
		local randomTable = IgnisLogic.ShuffleTable(tAlivePlayers)
		for(local i = 1; i <= ITERATION_COUNT; i++)
		{
			
		}
		foreach(hTarget in ShuffleTable(tAlivePlayers))
		{
			EntFireByHandle(hTarget, "runscriptcode", "IgnisLogic.AttackWrapper(self)",-1,null,null)
			IgnisLogic.AttackWrapper(self)
		}
	}
}