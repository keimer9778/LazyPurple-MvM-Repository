::PointTemplates <-
{
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
            }
        },
        NoFixup = 1,
        [1] =
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
                //"OnTrigger#9": "intel3,Enable,,0,-1",
                "OnTrigger#10": "intel2,Enable,,0,-1",
                //"OnTrigger#11": "intel1,ForceReset,,0,-1",
                "OnTrigger#12": "intel2,ForceReset,,0,-1",
                //"OnTrigger#13": "intel3,ForceReset,,0,-1",

                // Additional Actions for Gate A
                "OnTrigger#20": "robot_bootup_beeps,PlaySound,,0,-1",
                "OnTrigger#21": "robot_bootup_beeps,PlaySound,,0.5,-1",
                "OnTrigger#22": "pop_interface,UnpauseBotSpawning,,2,-1",
                "OnTrigger#23": "gate1_bot_blocker,Disable,,2,-1",
                //"OnTrigger#24": "gate2_prerequisite,Disable,,2,-1",
                "OnTrigger#25": "steam_whistle,Trigger,,23,-1",
                //"OnTrigger#26": "gate2_prerequisite_door,Disable,,2,-1",
                //"OnTrigger#27": "gate2_door_trigger,Enable,,2,-1",
                "OnTrigger#28": "robot_radio_waves_beep,StopSound,,2,-1",
                "OnTrigger#29": "gate1_prereq_move_giant,Disable,,2,-1",
                "OnTrigger#30": "prereq_gate1_giant_wait,Disable,,2,-1",
                //"ONTrigger#31": "prereq_gate2_giant_wait,Disable,,2,-1",

                // Spawnbots Enabling
                "OnTrigger#32": "spawnbot_main0,Enable,,0,-1",
                "OnTrigger#33": "spawnbot_upper0,Enable,,0,-1",
                "OnTrigger#34": "spawnbot_main1,Enable,,0,-1",
                "OnTrigger#35": "spawnbot_upper1,Enable,,0,-1",
                //"OnTrigger#36": "spawnbot_main2,Enable,,0,-1",

                "OnTrigger#37": "pop_interface,ChangeDefaultEventAttributes,RevertGateBotsBehavior,0.10,-1",
                "OnTrigger#39": "pop_interface,ChangeBotAttributes,RevertGateBotsBehavior,0.10,-1",

                "OnTrigger#40": "nav_refresh,RecomputeBlockers,,5,-1",
                "OnTrigger#41": "nav_refresh,RecomputeBlockers,,6,-1"
                targetname = "gate_a_open"
            }
        },
        NoFixup = 1,
        [2] =
        {
            logic_relay =
            {
                //"OnTrigger#1": "gate1_spawn_door,Open,,0,-1",
                //"OnTrigger#2": "gate1_bot_blocker,Disable,,0,-1",
                //"OnTrigger#3": "gate1_alarm_yellow_on,Trigger,,0,-1",
                //"OnTrigger#4": "gate1_capturepoint_a,SetOwner,3,5,-1",
                //"OnTrigger#5": "gate1_alarm_blue_on,Trigger,,27,-1",
                "OnTrigger#6": "vo_security_alert,PlaySound,,0,-1",
                "OnTrigger#7": "tf_gamerules,PlayVO,Halloween.PlatformAlarm,0,-1",
                "OnTrigger#9": "intel3,Enable,,0,-1",
                //"OnTrigger#10": "intel2,Enable,,0,-1",
                //"OnTrigger#11": "intel1,ForceReset,,0,-1",
                //"OnTrigger#12": "intel2,ForceReset,,0,-1",
                "OnTrigger#13": "intel3,ForceReset,,0,-1",

                // Gate B Opening Sequence
                "OnTrigger#14": "gate2_spawn_door,Open,,0,-1",
                "OnTrigger#15": "gate2_bot_blocker,Disable,,0,-1",
                "OnTrigger#16": "gate2_alarm_yellow_on,Trigger,,0,-1",
                "OnTrigger#17": "gate2_capturepoint_b,SetOwner,3,5,-1",
                "OnTrigger#18": "robot_radio_waves_beep,PlaySound,,2,-1",
                "OnTrigger#19": "gate2_fence_door,Open,,0,-1",

                // Additional Actions for Gate B
                "OnTrigger#20": "robot_bootup_beeps,PlaySound,,0,-1",
                "OnTrigger#21": "robot_bootup_beeps,PlaySound,,0.5,-1",
                "OnTrigger#22": "pop_interface,UnpauseBotSpawning,,2,-1",
                //"OnTrigger#23": "gate1_bot_blocker,Disable,,2,-1",
                "OnTrigger#24": "gate2_prerequisite,Disable,,2,-1",
                "OnTrigger#25": "steam_whistle,Trigger,,23,-1",
                "OnTrigger#26": "gate2_prerequisite_door,Disable,,2,-1",
                "OnTrigger#27": "gate2_door_trigger,Enable,,2,-1",
                "OnTrigger#28": "robot_radio_waves_beep,StopSound,,2,-1",
                //"OnTrigger#29": "gate1_prereq_move_giant,Disable,,2,-1",
                //"OnTrigger#30": "prereq_gate1_giant_wait,Disable,,2,-1",
                "ONTrigger#31": "prereq_gate2_giant_wait,Disable,,2,-1",

                // Spawnbots Enabling
                //"OnTrigger#32": "spawnbot_main0,Enable,,0,-1",
                //"OnTrigger#33": "spawnbot_upper0,Enable,,0,-1",
                //"OnTrigger#34": "spawnbot_main1,Enable,,0,-1",
                //"OnTrigger#35": "spawnbot_upper1,Enable,,0,-1",
                "OnTrigger#36": "spawnbot_main2,Enable,,0,-1",
                "OnTrigger#42": "spawnbot_main2_giants,Enable,,0,-1",

                "OnTrigger#37": "pop_interface,ChangeDefaultEventAttributes,RevertGateBotsBehavior,0.10,-1",
                "OnTrigger#39": "pop_interface,ChangeBotAttributes,RevertGateBotsBehavior,0.10,-1",

                "OnTrigger#40": "nav_refresh,RecomputeBlockers,,5,-1",
                "OnTrigger#41": "nav_refresh,RecomputeBlockers,,6,-1"
                targetname = "gate_b_open"
            }
        },
        NoFixup = 1,
        [3] =
        {
            logic_relay = //Just realized after editing this might be redundant, it might not be useful. someone will use this i guess
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
                //"OnTrigger#11": "intel1,ForceReset,,0,-1",
                //"OnTrigger#12": "intel2,ForceReset,,0,-1",
                //"OnTrigger#13": "intel3,ForceReset,,0,-1",

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
                "OnTrigger#42": "spawnbot_main2_giants,Enable,,0,-1",

                "OnTrigger#37": "pop_interface,ChangeDefaultEventAttributes,RevertGateBotsBehavior,0.10,-1",
                "OnTrigger#39": "pop_interface,ChangeBotAttributes,RevertGateBotsBehavior,0.10,-1",

                "OnTrigger#40": "nav_refresh,RecomputeBlockers,,5,-1",
                "OnTrigger#41": "nav_refresh,RecomputeBlockers,,6,-1"
                targetname = "gate_all_open_no_reset"
            }
        },
        NoFixup = 1,
        [4] =
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
        [5] =
        {
            training_annotation	=
            {
                targetname = "message_gate_active_A",
                lifetime = 10,
                origin = Vector(1561, -1775, 114)
                display_text = "Gate A active"
            }
        },
    }
}