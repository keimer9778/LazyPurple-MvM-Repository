PrecacheModel("models/props_mvm/robot_spawnpoint.mdl")
PrecacheModel("models/buildables/teleporter_light.mdl")
PrecacheModel("models/bots/soldier_boss/bot_soldier_boss_gibby.mdl")
PrecacheModel("models/bots/heavy_boss/bot_heavy_boss_gibby.mdl")
PrecacheModel("models/bots/soldier/goliatron2022_v3.mdl")

::PointTemplates <-
{
    robot_spawn =
    {
        [0] =
        {
            prop_dynamic =
            {
                classname = "prop_dynamic",
                DisableBoneFollowers = 1,
                disablereceiveshadows = 0,
                origin = Vector(38, 815, -420),
                angles = QAngle(0, 0, 0),
                DefaultAnim = "idle",
                disableshadows = 1,
                model = "models/props_mvm/robot_spawnpoint.mdl",
                modelscale = 1,
                skin = 0,
                solid = 6
            },
        },
        [1] =
        {
            prop_dynamic =
            {
               classname = "prop_dynamic",
                DisableBoneFollowers = 1,
                disablereceiveshadows = 0,
                origin = Vector(38, 815, -420),
                angles = QAngle(0, 0, 0),
                DefaultAnim = "running",
                disableshadows = 1,
                model = "models/buildables/teleporter_light.mdl",
                modelscale = 1,
                skin = 0,
                solid = 6
            },
        },
    },
    gate_logic =
    {
        NoFixup = 1,
        [0] =
        {
            logic_relay =
            {
                "OnTrigger#1": "gate1_spawn_door,Open,,0,-1",
                "OnTrigger#2": "gate1_bot_blocker,Disable,,0,-1",
                "OnTrigger#3": "gate1_alarm_yellow_on,Trigger,,0,-1",
                "OnTrigger#4": "gate1_capturepoint_a,SetOwner,3,5,-1",
                "OnTrigger#5": "gate1_alarm_blue_on,Trigger,,27,-1",
                "OnTrigger#6": "vo_security_alert,PlaySound,,0,-1",
                "OnTrigger#7": "tf_gamerules,PlayVO,Halloween.PlatformAlarm,0,-1",
                "OnTrigger#9": "intel3,Enable,,0,-1",
                "OnTrigger#10": "intel2,Enable,,0,-1",
                "OnTrigger#11": "intel1,ForceReset,,0,-1",
                "OnTrigger#12": "intel2,ForceReset,,0,-1",
                "OnTrigger#13": "intel3,ForceReset,,0,-1",

                // Gate B Opening Sequence
                "OnTrigger#14": "gate2_spawn_door,Open,,0,-1",
                "OnTrigger#15": "gate2_bot_blocker,Disable,,0,-1",
                "OnTrigger#16": "gate2_alarm_yellow_on,Trigger,,0,-1",
                "OnTrigger#17": "gate2_capturepoint_b,SetOwner,3,5,-1",
                "OnTrigger#18": "robot_radio_waves_beep,PlaySound,,2,-1",
                "OnTrigger#19": "gate2_fence_door,Open,,0,-1",

                // Additional Actions for Gate A
                "OnTrigger#20": "robot_bootup_beeps,PlaySound,,0,-1",
                "OnTrigger#21": "robot_bootup_beeps,PlaySound,,0.5,-1",
                "OnTrigger#22": "pop_interface,UnpauseBotSpawning,,2,-1",
                "OnTrigger#23": "gate1_bot_blocker,Disable,,2,-1",
                "OnTrigger#24": "gate2_prerequisite,Disable,,2,-1",
                "OnTrigger#25": "steam_whistle,Trigger,,23,-1",
                "OnTrigger#26": "gate2_prerequisite_door,Disable,,2,-1",
                "OnTrigger#27": "gate2_door_trigger,Enable,,2,-1",
                "OnTrigger#28": "robot_radio_waves_beep,StopSound,,2,-1",
                "OnTrigger#29": "gate1_prereq_move_giant,Disable,,2,-1",
                "OnTrigger#30": "prereq_gate1_giant_wait,Disable,,2,-1",
                "ONTrigger#31": "prereq_gate2_giant_wait,Disable,,2,-1",

                // Spawnbots Enabling
                "OnTrigger#32": "spawnbot_main0,Enable,,0,-1",
                "OnTrigger#33": "spawnbot_upper0,Enable,,0,-1",
                "OnTrigger#34": "spawnbot_main1,Enable,,0,-1",
                "OnTrigger#35": "spawnbot_upper1,Enable,,0,-1",
                "OnTrigger#36": "spawnbot_main2,Enable,,0,-1",

                "OnTrigger#37": "pop_interface,ChangeDefaultEventAttributes,RevertGateBotsBehavior,0.10,-1",
                "OnTrigger#39": "pop_interface,ChangeBotAttributes,RevertGateBotsBehavior,0.10,-1",

                "OnTrigger#40": "nav_refresh,RecomputeBlockers,,5,-1",
                "OnTrigger#41": "nav_refresh,RecomputeBlockers,,6,-1"
                targetname = "gate_all_open"
            },
        },
        NoFixup = 1,
        [1] =
        {
            training_annotation	=
            {
                targetname = "message_gate_active_B",
                lifetime = 10,
                origin = Vector(-1548, -1043, 159)
                display_text = "Gate B active"
            }
        },
        NoFixup = 1,
        [2] =
        {
            training_annotation	=
            {
                targetname = "message_gate_active_A",
                lifetime = 10,
                origin = Vector(1561, -1775, 114)
                display_text = "Gate A active"
            }
        },
        NoFixup = 1,
        [3] =
        {
            logic_relay =
            {
                targetname = "cpoint_alarm",
                "OnTrigger#1": "tf_gamerules,PlayVO,mvm.cpoint_alarm,0,-1",
            }
        },
        NoFixup = 1,
        [4] =
        {
            logic_relay =
            {
                targetname = "siren",
                "OnTrigger#1": "tf_gamerules,PlayVO,MVM.Siren,0,-1",
            }
        },
        NoFixup = 1,
        [5] =
        {
            logic_relay =
            {
                targetname = "bootup",
                "OnTrigger#1": "tf_gamerules,PlayVO,RD.BotDeathExplosion,0.5"
                "OnTrigger#2": "tf_gamerules,PlayVO,Powerup.PickUpTemp.Uber,1,-1",
                "OnTrigger#3": "tf_gamerules,PlayVO,Powerup.PickUpStrength,3,-1",
            }
        },
    }
    tank_prep =
    {
        [0] =
        {
            OnSpawnOutput =
            {
                Target = "boss_deploy_relay"
                Action = AddOutput
                Param = "ontrigger tankboss:sethealth:0:0:-1,0,-1"
            },
        },

        [1] =
        {
            OnSpawnOutput =
            {
                Target = "boss_deploy_relay"
                Action = AddOutput
                Param = "ontrigger tankboss:ignite:0:0:-1,0,-1"
            },
        },

        [2] =
        {
            env_shake =
            {
                targetname = "shake_it_baby",
                amplitude = 255,
                frequency = 255,
                spawnflags = 5,
                radius = 99999,
                duration = 1
            },
        },

        [3] =
        {
            logic_relay =
            {
                "OnTrigger#1": "tankboss,$playsound,physics/metal/metal_large_debris2.wav,17.5,0",
                "OnTrigger#2": "shake_it_baby,startshake,0,17.5,-1",
                targetname = "tank_spawn_relay"
            },
        },
    }
}