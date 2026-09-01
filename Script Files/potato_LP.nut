::__potato_LP <- {
    objective_resource = null
    mapname = GetMapName()
    len_mapname = GetMapName().len()

    /**
     * Applies the map fixes specified for the current map.
     */
    function ApplyMapFixes() {
		// atp just make sure all maps have this fix
		// SpawnroomVisualizersFix()
		
        switch (__potato_LP.mapname) {
            // Oilrig
            case "mvm_oilrig_rc5":
                // Rain particles fix - replace missing rain particles with sawmill rain.
                // Kill broken rain particles
                for (local particlesystem; particlesystem = Entities.FindByClassname(particlesystem, "info_particle_system");) {
                    if (particlesystem.GetName() == "end_pit_destroy_particle") continue
                    // Kill() and Destroy() methods will cause this to iterate ~300 times,
                    //  so must EntFire() instead
                    EntFireByHandle(particlesystem, "Kill", "", 0, null, null)
                }

                // Spawn replacement rain; looks bad if we just use the position of the old particle systems
                local rain2 = [Vector(-508, -2608, 1800), Vector(789, -2290, 1800), Vector(-324, -2694, 1800), Vector(-320, -3360, 1800)]
                local rain = [Vector(-2848, 384, 8810), Vector(-1200, 1924, 3620),
                    Vector(282, 1924, 3620), Vector(882, 1924, 3620), Vector(-366, -608, 3620), Vector(528, -608, 4100),
                    Vector(1849, -291, 3420), Vector(0, -1000, 1600), Vector(1024, -1632, 4100), Vector(-1024, -1632, 4100),
                    Vector(1562, -2210, 3620), Vector(-864, -3936, 3620), Vector(160, -4096, 4200), Vector(320, -4960, 4300),
                    Vector(-704, -4960, 4300), Vector(1242, -4256, 3620), Vector(-1146, -4702, 3620)]
                foreach(vec in rain2) {
                    SpawnEntityFromTable("info_particle_system", {
                        origin = vec
                        effect_name = "env_rain_002_256"
                        start_active = 1
                        flag_as_weather = 1
                    })
                }
                foreach(vec in rain) {
                    SpawnEntityFromTable("info_particle_system", {
                        origin = vec
                        effect_name = "env_rain_001"
                        start_active = 1
                        flag_as_weather = 1
                    })
                }

                // Tank spawn fixes
                // Add missing func_respawnroom to tank spawn.
                local tankspawn = SpawnEntityFromTable("func_respawnroom", {
                    origin = Vector(-520, -5450, 1063)
                    TeamNum = Constants.ETFTeam.TF_TEAM_BLUE
                })
                // Some properties are reset when spawn is dispatched, so they must be set
                //  post-spawn.
                tankspawn.SetSize(Vector(), Vector(400, 410, 200))
                tankspawn.SetSolid(Constants.ESolidType.SOLID_BBOX)
                // Mark tank spawn nav to properly provide bot uber.
                local tanknav = NavMesh.GetNavAreaByID(27)
                // tanknav.SetAttributeTF(Constants.FTFNavAttributeType.TF_NAV_SPAWN_ROOM_BLUE)
                // tanknav.ClearAttributeTF(Constants.FTFNavAttributeType.TF_NAV_BOMB_CAN_DROP_HERE)

                // Collect dropped cash in tank spawn.
                local tankcollect = SpawnEntityFromTable("trigger_hurt", {
                    origin = Vector(-520, -5450, 1063)
                })
                tankcollect.SetSize(Vector(), Vector(400, 410, 200))
                tankcollect.SetSolid(Constants.ESolidType.SOLID_BBOX)
                break

            // Rottenburg
            case "mvm_rottenburg":
                // Fix tank barricade turning invisible
                EntFire("Barricade", "SetParent", "Tank_Barricade_Particle")
                // Fix bad collision on tank barricade
                EntFire("Barricade", "DisableCollision")

                break

            // Lotus
            case "mvm_lotus_b6":
                SpawnroomVisualizersFix()
                break
			
			// Depot
            case "mvm_depot_b4":
                SpawnroomVisualizersFix()
                break
			
			// Crown
            case "mvm_crown_rc1":
                SpawnroomVisualizersFix()
                break
				
			// Hurricane
            case "mvm_hurricane_rc3":
                SpawnroomVisualizersFix()
                break
				
			// Decoy
            case "mvm_decoy":
                SpawnroomVisualizersFix()
                break
				
			// Quetzal
            case "mvm_quetzal_rc5":
                SpawnroomVisualizersFix()
                break
				
			// Rancher
            case "mvm_rancher_b11":
                SpawnroomVisualizersFix()
                break
				
			// Factory
            case "mvm_factory":
                SpawnroomVisualizersFix()
                break
				
			// Cliffside
            case "mvm_cliffside_b9":
                SpawnroomVisualizersFix()
                break
				
			// Snowpine
            case "mvm_snowpine_rc4_fix1":
                SpawnroomVisualizersFix()
                break
				
			// Mansion
            case "mvm_mansion_rc1d":
                SpawnroomVisualizersFix()
                break
				
			// Degroot Keept
            case "mvm_degrootkeep_b1":
                SpawnroomVisualizersFix()
                break

			// Legerdemain
            case "mvm_legerdemain_a6e":
                SpawnroomVisualizersFix()
                break
				
			// Decompose
            case "mvm_decompose_rc7":
                SpawnroomVisualizersFix()
                break
				
			// Madhattan
            case "mvm_madhattan_rc5a":
                SpawnroomVisualizersFix()
                break
				
			// Creepside
            case "mvm_creepside_b2":
                SpawnroomVisualizersFix()
                break
				
			// Doublecross
			case "mvm_doublecross_rc5":
                SpawnroomVisualizersFix()
                break
				
			// Climbspire
            case "mvm_climbspire_rc_1":
                SpawnroomVisualizersFix()
				// this damn door is causing bot nav issues
				for (local tankdoor_model; tankdoor_model = Entities.FindByClassname(tankdoor_model, "prop_dynamic");)
				{
					if (tankdoor_model.GetName() == "tank_door_model")
					{
						tankdoor_model.Kill()
					}
				}
				for (local tankdoor_func; tankdoor_func = Entities.FindByClassname(tankdoor_func, "func_door");)
				{
					if (tankdoor_func.GetName() == "tank_door")
					{
						tankdoor_func.Kill()
					}
				}

                break
				
			// Icebox
            case "mvm_icebox_rc1":
                SpawnroomVisualizersFix()
				HologramsFix({
					bombpath_arrows_high = true, 
					bombpath_arrows_low = true, 
					bombpath_arrows_flank = true
				})
                break
				
			// Marsbase
            case "mvm_marsbase_rc5":
                SpawnroomVisualizersFix()
				HologramsFix({
					hologram = true,
					hologram_right = true,
					hologram_left = true
				})
                break
				
			// Frostwynd
			case "mvm_frostwynd_rc1":
				SpawnroomVisualizersFix()
                break
				
			// Doppler
			case "mvm_doppler_b12":
				SpawnroomVisualizersFix()
                break
				
			// Paradigm
			case "mvm_paradigm_rc5":
				SpawnroomVisualizersFix()
                break
				
			// Robotfactory
			case "mvm_robotfactory_rc10a":
                __diffmod.State.tankspawn_delay = true
                break
				
			// Bronx
            case "mvm_bronx_rc2fix":
                SpawnroomVisualizersFix()
                break
			
			// Coaltown engy spots
			case "mvm_coaltown":
                SpawnEntityFromTable("bot_hint_engineer_nest", {
					targetname = "engy_nest01"
					origin = "-637.5 2405 368"
					angles = "0 43 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest01"
					origin = "-683.4 2634.3 303.9"
					angles = "0 288 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest01"
					origin = "-414.4 2372.9 255.8"
					angles = "0 5.4 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest02"
				origin = "804 2491 327"
				angles = "0 176 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest02"
					origin = "877 2568 285"
					angles = "0 181 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest02"
					origin = "694 2500 237"
					angles = "0 176 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest03"
				origin = "735 1471 564"
				angles = "0 -124 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest03"
					origin = "750 1671 496"
					angles = "0 270 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest03"
					origin = "625 1342 496"
					angles = "0 178 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest04"
				origin = "-180 598 484"
				angles = "0 179 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest04"
					origin = "-47 602 418"
					angles = "0 180 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest04"
					origin = "-305 589 418"
					angles = "0 179 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest05"
				origin = "1417 674 644"
				angles = "0 -89 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest05"
					origin = "1466 846 576"
					angles = "0 180 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest05"
					origin = "1424 496 576"
					angles = "0 270 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest06"
				origin = "0 112 740"
				angles = "0 -88 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest06"
					origin = "0 291 672"
					angles = "0 268 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest06"
					origin = "0 -12 672"
					angles = "0 -90 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest07"
				origin = "-561 -494 804"
				angles = "0 -158 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest07"
					origin = "-425 -418 736"
					angles = "0 195 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest07"
					origin = "-695 -562 736"
					angles = "0 -138 0"
				})
				
				SpawnEntityFromTable("bot_hint_engineer_nest", {
				targetname = "engy_nest08"
				origin = "738 -516 804"
				angles = "0 -158 0"
				})
				SpawnEntityFromTable("bot_hint_teleporter_exit", {
					targetname = "engy_nest08"
					origin = "530 -417 736"
					angles = "0 267 0"
				})
				SpawnEntityFromTable("bot_hint_sentrygun", {
					targetname = "engy_nest08"
					origin = "820 -533 736"
					angles = "0 -53 0"
				})
				
                break
			
			
        }
    }

    Events = {
        // Event is fired every wave init (on mission change, wave jump or post wave fail).
        function OnGameEvent_teamplay_round_start(_) {
            __potato_LP.ApplyMapFixes()
        }
    }
	function SpawnroomVisualizersFix() {
		for (local vis; vis = Entities.FindByClassname(vis, "func_respawnroomvisualizer");)
			NetProps.SetPropInt(vis, "m_nRenderMode", Constants.ERenderMode.kRenderTransColor)
		printl("SPAWNROOM VISUALIZERS FIXED!")
	}
	
	function HologramsFix(names) { // expects a table
		for (local vis; vis = Entities.FindByClassname(vis, "prop_dynamic");)
			if (vis.GetName() in names) {
				NetProps.SetPropInt(vis, "m_nRenderMode", Constants.ERenderMode.kRenderNormal)
				printl(vis.GetName() + " successfully rendermoded")
			}
		printl("HOLOGRAMS FIXED!")
	}
	
	// taken from pea2.nut
	SpawnNavBrush = function(name, pos, xyz1, xyz2, tagname = false)
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
	
	function BoneMergeOptimize() {
		local parents = []
		for (local follower; follower = Entities.FindByClassname(follower, "phys_bone_follower");) {
			local parent = follower.GetOwner()
			if (parent && parents.find(parent) == null) {
				// DisableBoneFollowers on Owner entities fixes network/demo issues.
				parents.push(parent)
				parent.KeyValueFromInt("DisableBoneFollowers", 1)
				NetProps.SetPropInt(parent,
					"m_BoneFollowerManager.m_iNumBones", 0)
			}
			// Kill the bone followers to free up edicts.
			EntFireByHandle(follower, "Kill", null, -1, null, null)
		}
		printl("BONE MERGES OPTIMIZED!")
	}
}

__CollectGameEventCallbacks(__potato_LP.Events)