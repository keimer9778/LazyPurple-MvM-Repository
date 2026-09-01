// Script is executed by the game every map spawn.
// Several functions taken from PopExtensions+ and Potato

// ================================ //
// PRECACHE SOUNDS
// ================================ //

// Mod enabling, disabling

PrecacheSound("mvm/mvm_money_vanish.wav")
PrecacheSound("coach/coach_defend_here.wav")
PrecacheSound("items/powerup_pickup_resistance.wav")
PrecacheSound("items/powerup_pickup_knockout.wav")
PrecacheSound("ambient/halloween/mysterious_perc_01.wav")
PrecacheSound("items/powerup_pickup_knockout_melee_hit.wav")
PrecacheSound("items/powerup_pickup_agility.wav")
PrecacheSound("items/powerup_pickup_haste.wav")
PrecacheSound("items/powerup_pickup_crits.wav")
PrecacheSound("items/powerup_pickup_supernova.wav")
PrecacheSound("items/powerup_pickup_plague.wav")
PrecacheSound("items/powerup_pickup_agility.wav")
PrecacheSound("mvm/mvm_tele_activate.wav")
PrecacheSound("mvm/mvm_tele_deliver.wav")
PrecacheSound("ambient/rottenburg/rottenburg_belltower.wav")
PrecacheSound("misc/killstreak.wav")
PrecacheSound("ui/mm_medal_gold.wav")
PrecacheSound("ui/mm_rank_one_achieved.wav")
PrecacheSound("weapons/draw_sword.wav")
PrecacheSound("ambient/medieval_doorclose.wav")
PrecacheSound("ui/mm_level_two_achieved.wav")
PrecacheSound("ui/mm_rank_progress_tick_up.wav")
PrecacheSound("ui/mm_scoreboardpanel_slide.wav")
PrecacheSound("mvm/mvm_warning.wav")

// Voting sounds
PrecacheSound("ui/vote_failure.wav")
PrecacheSound("ui/vote_nowav")
PrecacheSound("ui/vote_yes.wav")
PrecacheSound("ui/vote_success.wav")
PrecacheSound("ui/vote_started.wav")

// Pootis
PrecacheSound("vo/mvm/norm/heavy_mvm_needdispenser01.mp3")
PrecacheSound("vo/mvm/norm/spy_mvm_laughshort06.mp3")

::__diffmod <- {

	// ================================ //
	// CONSTANTS
	// ================================ //

	// Legacy modifier active values
	
	mod_active_double_robot_health = 0
	mod_active_portal_anomalies = false

	Const = {
	
		chat_mark = "\x07FBECCB[" + "\x07F2B416" + "DIFFMOD" + "\x07FBECCB" + "] "
		modifier_tooltip = "\x07FBECCB[" + "\x07F2B416" + "DIFFMOD" + "\x07FBECCB" + "] " + "To remove all current modifiers, type '/mod_vote_resetall' during wave setup"

		downgrade_color = "638BEB"
		
	}

	// ================================ //
	// STATE
	// ================================ //

	State = {
	
		// Map load state
		
		mod_ent_has_think_set = false
		mapname = GetMapName()
		
		// Ingame state
		
		current_mods = {"HP" : 0, "DMG" : 0, "SPD" : 0, "INVS" : 0, "PRTL" : 0, "MDVL" : 0, "MRTHN" : 0}
		mod_order = ["HP", "DMG", "SPD", "INVS", "PRTL", "MRTHN", "MDVL"]
		LPMVM_dependent_mods = {"MRTHN" : 0}
		legacy_modcodes = {"HP" : "2HP", "DMG" : "2DMG", "SPD" : "2SPD"}
		map_has_mods = false
		mod_vote_enabled = true

		force_test = false
		
		wait_next_hud = 0
		wait_next_timer = 0
		wait_next_clock = 1
		
		textent_s1 = null
		textent_s2 = null
		textent_s3 = null
		
		vote_type = ""
		vote_tier = 0
		in_vote_state = false
		vote_y_count = 0
		vote_n_count = 0
		vote_timeleft = 0
		voted_playerids = []
		
		wave_resetting = false
		
		vote_title_display_text = "."
		vote_title_color = "FFFF00"
		vote_count_display_text = "."
		
		start_cooldown = 20
		vote_cooldown = 0
		mod_change_cooldown = 0
		tip_cooldown = 5
		player_vote_coolown = {}
		
		player_hudhints = {}

		next_random_map = "mvm_decoy"
		
		damageres_setup = false
		bot_dmgreductions = {}

		medieval_force_respawn = 0
		marathon_wave_failed = false
		
		// april fools stuff
		
		aprilfools_enabled = (RandomInt(1, 80) == 1)
		pootis_next = 0
		
		// Legacy tank spawn delay flag
		
		tankspawn_delay = false
		
		// blacklists
		
		bot_team_blacklist = {}
		modifier_blacklist = {}
		player_set_team = 2
	}

	// ================================ //
	// GAME UTIL
	// (Utility game functions)
	// ================================ //

	GameUtil = {
	
		function AddAttributeToLoadout(player, attribute, value, duration = -1) {
			for (local i = 0; i < 7; i++) {
				local wep = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
				if ( wep == null) continue

				wep.AddAttribute(attribute, value, duration)
				wep.ReapplyProvision()
				return
			}
		}
		
		function check_spec(userid) {
			if (GetPlayerFromUserID(userid).GetTeam() == 1) {
				ClientPrint(GetPlayerFromUserID(userid),3,__diffmod.Const.chat_mark + "Spectators can't use this command!")
				return true
			}
			else return false
		}

		function check_spec_ehandle(ehandle) {
			if (ehandle.GetTeam() == 1) {
				ClientPrint(ehandle,3,__diffmod.Const.chat_mark + "Spectators can't use this command!")
				return true
			}
			else return false
		}

		function check_can_force_mod(userid) {
			if ((__diffmod.GameUtil.LPMVM_is_loaded(true) && LPMVM.Commands.CanUse(GetPlayerFromUserID(userid), "sm_map", LPMVM.Admin.CHANGEMAP, false)) || __diffmod.State.force_test) {
				return true
			}
			else {
				ClientPrint(GetPlayerFromUserID(userid),3,__diffmod.Const.chat_mark + "You can't use this command!")
				return false
			}
		}

		function check_can_force_mod_ehandle(ehandle) {
			if ((__diffmod.GameUtil.LPMVM_is_loaded(true) && LPMVM.Commands.CanUse(ehandle, "sm_map", LPMVM.Admin.CHANGEMAP, false)) || __diffmod.State.force_test) {
				return true
			}
			else {
				ClientPrint(ehandle,3,__diffmod.Const.chat_mark + "You can't use this command!")
				return false
			}
		}
		
		function showhint_all()
		{
			for (local i = 1; i <= MaxClients().tointeger(); i++) {
				local player = PlayerInstanceFromIndex(i)

				if (player != null && !player.IsBotOfType(1337)) {
					// __diffmod.GameUtil.register_ent_func(player, "post_spawn_players_showhint", __diffmod.SpawnCatchers.post_spawn_players_showhint)
					EntFireByHandle(player, "CallScriptFunction", "diffmod_post_spawn_players_showhint", 1, null, null)
				}
			}
		}
		
		function GlobalSound(soundname, delay = 0.0)
		{
			local sound_command = "EmitSoundEx({sound_name = `" + soundname + "`, channel = 6, volume = 1.0, sound_level = 0, filter_type = 5, flags = 0})"
			EntFire("worldspawn", "RunScriptCode", sound_command, delay)
		}
		
		function SetTargetname(ent, name) {
			NetProps.SetPropString(ent, "m_iName", name)
		}
		
		function register_ent_func(ent, name, fn)
		{
			ent.ValidateScriptScope()
			ent.GetScriptScope()[name] <- fn
		}
		
		function DoExplanation(message, printColor = "FFFF00", yValue = 0.3, messagePrefix = "Explanation: ", syncChatWithGameText = false, textPrintTime = -1, texteffect = 2) {
			// printl("DISPLAY TEXT DISPLAYED")
			local rgb = __diffmod.MiscUtil.HexToRgb(printColor)
			local txtent = SpawnEntityFromTable("game_text", {
				effect = texteffect,
				spawnflags = 1,
				color = format("%d %d %d", rgb[0], rgb[1], rgb[2]),
				color2 = "255 254 255",
				fxtime = 0.02,
				// holdtime = 5,
				fadeout = 0,
				fadein = 0.01,
				channel = 4,
				x = -1,
				y = yValue
			})
			NetProps.SetPropBool(txtent, "m_bForcePurgeFixedupStrings", true)
			__diffmod.GameUtil.SetTargetname(txtent, format("__utilExplanationText%d",txtent.entindex()))
			local strarray = []

			//avoid needing to do a ton of function calls for multiple announcements.
			local newlines = split(message, "|")

			foreach (n in newlines)
				if (n.len() > 0) {
					strarray.append(n)
					if (!startswith(n, "PAUSE") && syncChatWithGameText)
						ClientPrint(null, 3, format("\x07%s %s\x07%s %s", printColor, messagePrefix, TF_COLOR_DEFAULT, n))
				}

			local i = -1
			local textcooldown = 0
			function ExplanationTextThink() {
				if (textcooldown > Time()) return

				i++
				if (i == strarray.len()) {
					NetProps.SetPropString(txtent, "m_iszScriptThinkFunction", "")

				//	  DoEntFire("!activator", "SetScriptOverlayMaterial", "", -1, player, player)

					// foreach (player in this.HumanArray) DoEntFire("command", "Command", "r_screenoverlay vgui/pauling_text", -1, player, player)

					NetProps.SetPropString(txtent, "m_iszMessage", "")
					EntFireByHandle(txtent, "Display", "", -1, null, null)
					EntFireByHandle(txtent, "Kill", "", 0.1, null, null)
					return
				}
				local s = strarray[i]

				//make text display slightly longer depending on string length
				local delaybetweendisplays = textPrintTime
				if (delaybetweendisplays == -1) {
					delaybetweendisplays = s.len() / 10
					if (delaybetweendisplays < 2) delaybetweendisplays = 2; else if (delaybetweendisplays > 12) delaybetweendisplays = 12
				}

				//allow for pauses in the announcement
				if (startswith(s, "PAUSE")) {
					local pause = split(s, " ")[1].tofloat()
				//	  DoEntFire("player", "SetScriptOverlayMaterial", "", -1, player, player)
					NetProps.SetPropString(txtent, "m_iszMessage", "")

					NetProps.SetPropInt(txtent, "m_textParms.holdTime", pause)
					txtent.KeyValueFromInt("holdtime", pause)

					EntFireByHandle(txtent, "Display", "", -1, null, null)

					textcooldown = Time() + pause
					return 0.033
				}

				NetProps.SetPropString(txtent, "m_iszMessage", s)

				NetProps.SetPropInt(txtent, "m_textParms.holdTime", delaybetweendisplays)
				txtent.KeyValueFromInt("holdtime", delaybetweendisplays)

				EntFireByHandle(txtent, "Display", "", -1, null, null)
				if (syncChatWithGameText) ClientPrint(null, 3, format("\x07%s %s\x07%s %s", "FFFF00", messagePrefix, TF_COLOR_DEFAULT, s))

				textcooldown = Time() + delaybetweendisplays

				return 0.033
		   }
		   txtent.ValidateScriptScope()
		   txtent.GetScriptScope().ExplanationTextThink <- ExplanationTextThink
		   AddThinkToEnt(txtent, "ExplanationTextThink")
		}
		function DoExplanationSimple_1(message, printColor = "FFFF00", xValue = 0.3, yValue = 0.3, textPrintTime = -1, texteffect = 0, channel = 2) {
			local rgb = __diffmod.MiscUtil.HexToRgb(printColor)
			if (__diffmod.State.textent_s1 == null)
			{
				__diffmod.State.textent_s1 = SpawnEntityFromTable("game_text", {
					effect = texteffect,
					spawnflags = 1,
					color = format("%d %d %d", rgb[0], rgb[1], rgb[2]),
					color2 = "255 254 255",
					fxtime = 0.02,
					holdtime = 1,
					fadeout = 0,
					fadein = 0,
					channel = 1,
					x = xValue,
					y = yValue
				})
			}
			NetProps.SetPropBool(__diffmod.State.textent_s1, "m_bForcePurgeFixedupStrings", true)
			// __diffmod.GameUtil.SetTargetname(__diffmod.State.textent_s1, format("__modifiersExplanationTextSimple%d",__diffmod.State.textent_s1.entindex()))
			
			NetProps.SetPropString(__diffmod.State.textent_s1, "m_iszMessage", message)
			// EntFireByHandle(__diffmod.State.textent_s1, "color", format("%d %d %d", rgb[0], rgb[1], rgb[2]), -1, null, null)
			__diffmod.State.textent_s1.KeyValueFromString("color", format("%d %d %d", rgb[0], rgb[1], rgb[2]))
			//NetProps.SetPropString(__diffmod.State.textent_s1, "color", format("%d %d %d", rgb[0], rgb[1], rgb[2]))
			// __diffmod.State.textent_s1.AcceptInput("SetTextColor", format("%d %d %d", rgb[0], rgb[1], rgb[2]), null, null)
			EntFireByHandle(__diffmod.State.textent_s1, "Display", "", -1, null, null)
		}
		function DoExplanationSimple_2(message, printColor = "FFFF00", xValue = 0.3, yValue = 0.3, textPrintTime = -1, texteffect = 0, channel = 2) {
			local rgb = __diffmod.MiscUtil.HexToRgb(printColor)
			if (__diffmod.State.textent_s2 == null)
			{
				__diffmod.State.textent_s2 = SpawnEntityFromTable("game_text", {
					effect = texteffect,
					spawnflags = 1,
					color = format("%d %d %d", rgb[0], rgb[1], rgb[2]),
					color2 = "255 254 255",
					fxtime = 0.02,
					holdtime = 1,
					fadeout = 0,
					fadein = 0,
					channel = 2,
					x = xValue,
					y = yValue
				})
			}
			NetProps.SetPropBool(__diffmod.State.textent_s2, "m_bForcePurgeFixedupStrings", true)
			__diffmod.GameUtil.SetTargetname(__diffmod.State.textent_s2, format("__modifiersExplanationTextSimple%d",__diffmod.State.textent_s2.entindex()))
			
			NetProps.SetPropString(__diffmod.State.textent_s2, "m_iszMessage", message)
			EntFireByHandle(__diffmod.State.textent_s2, "Display", "", -1, null, null)
		}
		function DoExplanationSimple_3(message, printColor = "FFFF00", xValue = 0.3, yValue = 0.3, textPrintTime = -1, texteffect = 0, channel = 2) {
			local rgb = __diffmod.MiscUtil.HexToRgb(printColor)
			if (__diffmod.State.textent_s3 == null)
			{
				__diffmod.State.textent_s3 = SpawnEntityFromTable("game_text", {
					effect = texteffect,
					spawnflags = 1,
					color = format("%d %d %d", rgb[0], rgb[1], rgb[2]),
					color2 = "255 254 255",
					fxtime = 0.02,
					holdtime = 1,
					fadeout = 0,
					fadein = 0,
					channel = 3,
					x = xValue,
					y = yValue
				})
			}
			NetProps.SetPropBool(__diffmod.State.textent_s3, "m_bForcePurgeFixedupStrings", true)
			// __diffmod.GameUtil.SetTargetname(__diffmod.State.textent_s3, format("__modifiersExplanationTextSimple%d",__diffmod.State.textent_s3.entindex()))
			
			NetProps.SetPropString(__diffmod.State.textent_s3, "m_iszMessage", message)
			EntFireByHandle(__diffmod.State.textent_s3, "Display", "", -1, null, null)
		}
		function ShowHudHint(text = "This is a hud hint", player = null, duration = 5.0) {
			local hudhint = Entities.FindByName(null, "__utilhudhint")

			local flags = (player == null) ? 1 : 0

			if (!hudhint) hudhint = SpawnEntityFromTable("env_hudhint", { targetname = "__utilhudhint", spawnflags = flags, message = text })

			hudhint.KeyValueFromString("message", text)
			
			__diffmod.State.player_hudhints[player] <- duration
			
			EntFireByHandle(hudhint, "HideHudHint", "", 0, player, player)
			EntFireByHandle(hudhint, "ShowHudHint", "", 0.1, player, player)
		}
		
		function HideHudHint(player) {
			local hudhint = Entities.FindByName(null, "__utilhudhint")
			EntFireByHandle(hudhint, "HideHudHint", "", 0, player, player)
		}

		function SetupThinker()
		{
			// Create a thinker for modifiers
			
			modifierEntity <- Entities.FindByName(null, "_modifiers")
			if (modifierEntity == null) modifierEntity = SpawnEntityFromTable("info_teleport_destination", { targetname = "_modifiers" })
			
			// __diffmod.GameUtil.register_ent_func(modifierEntity, "main_think", __diffmod.main_think)

			if (!__diffmod.State.mod_ent_has_think_set) {
				AddThinkToEnt(modifierEntity, "diffmod_main_think")
				__diffmod.State.mod_ent_has_think_set = true
				printl("THINKER HAS BEEN SET UP!")
			}
		}
		function SetupDamageresThinker()
		{
			// Create a thinker for damageres system
			
			if (!__diffmod.State.damageres_setup) {
				damageresEntity <- Entities.FindByName(null, "_damageres")
				if (damageresEntity == null) damageresEntity = SpawnEntityFromTable("info_teleport_destination", { targetname = "_damageres" })
				//damageresEntity.ValidateScriptScope()
				// __diffmod.GameUtil.register_ent_func(damageresEntity, "damageres_think", __diffmod.MiscThinks.damageres_think)
				AddThinkToEnt(damageresEntity, "diffmod_damageres_think")
				__diffmod.State.damageres_setup = true
				printl("THE DMGRES THINKER HAS BEEN SET UP!")
			}
		}

		function some_mod_enabled() {
			foreach (_, tier in __diffmod.State.current_mods)
			{
				if (tier != 0) return true
			}
			return false
		}

		function get_random_map() {
			if (!__diffmod.GameUtil.LPMVM_is_loaded) return "mvm_decoy"

			local maparr = LPMVM.Missions.GetMaps()
			if (maparr == null) return "mvm_decoy"

			local totalmaps = maparr.len()
			if (totalmaps == 0) return "mvm_decoy"

			local randmapindex = RandomInt(0, totalmaps - 1)

			return maparr[randmapindex]
		}

		function go_to_random_map(change_delay = 5.0) {
			if (!__diffmod.GameUtil.LPMVM_is_loaded) return

			local randmap = __diffmod.GameUtil.get_random_map()
			ClientPrint(null,3,__diffmod.Const.chat_mark + "Changing to randomly selected map...")
			ClientPrint(null,2,"Random map is: " + randmap)

			__diffmod.State.next_random_map = randmap

			EntFire("worldspawn", "RunScriptCode", "__diffmod.GameUtil.load_random_map()", change_delay)
		}

		function load_random_map() {
			ClientPrint(null,2,"Map loaded:" + __diffmod.State.next_random_map)
			ClientPrint(null,2,"Of type:" + typeof(__diffmod.State.next_random_map)) // remove this when function works
			LPMVM.Game.ChangeMap(__diffmod.State.next_random_map)
		}
		
		function setup_vote(voter, type, chat_message, vote_title, vote_color) {
		
			// Vote active check
			if (__diffmod.State.in_vote_state) 
			{
				ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "There is already a vote in progress!")
				return
			}
		
			__diffmod.GameUtil.GlobalSound("ui/vote_started.wav")
		
			__diffmod.State.vote_timeleft = 15
			__diffmod.State.vote_y_count = 1
			__diffmod.State.vote_n_count = 0
			
			__diffmod.State.vote_type = type
			
			__diffmod.State.voted_playerids.append(voter)

			ClientPrint(null,3,chat_message)
			
			__diffmod.State.vote_title_display_text = vote_title
			__diffmod.State.vote_title_color = vote_color
			__diffmod.State.vote_count_display_text = "."
			
			__diffmod.State.in_vote_state = true
		}

		function vote_completion(vote_type) {
			if (vote_type == "reset_wave") {
				// setup gameover (with regards to playerteam)
				__diffmod.State.wave_resetting = true
				local winteam = 3
				if (__diffmod.State.player_set_team == 3) winteam = 2
				SpawnEntityFromTable("game_round_win", {targetname = "_diffmodgameover", TeamNum = winteam, force_map_reset = 1})

				// Pretend we're doing epic resetting stuff lol!
				EntFire("worldspawn", "RunScriptCode", @"
				ClientPrint(null,3,`\x08AAF542FF[WAVE RESETTING...]`)
				__diffmod.GameUtil.DoExplanation(`WAVE RESETTING...`, `AAF542`, 0.3, ``, false, 5)
				"
				, -1)

				// Actually reset the wave
				EntFire("worldspawn", "RunScriptCode", @"
				__diffmod.State.vote_type = ``
				__diffmod.GameUtil.reset_wave_call()
				"
				, 2.5)
			}
			else {
				__diffmod.ModSystem.mod_change(vote_type, __diffmod.State.vote_tier)
			}

			vote_type = ""
		}

		function reset_wave_call()
		{
			printl("wave resetting!")
			if (GetRoundState() == 4) EntFire("_diffmodgameover", "RoundWin")
		}

		function LPMVM_is_loaded(check_available = false) {
			if (check_available) {
				if ("LPMVM" in getroottable() && LPMVM.IsAvailable()) return true
			} else {
				if ("LPMVM" in getroottable()) return true
			}
			return false
		}
	}

	// ================================ //
	// MISC UTIL
	// (Utility misc functions)
	// ================================ //

	MiscUtil = {
	
		function arrayfind(targetarray, targetentry)
		{
			local isFound = false
			foreach (entry in targetarray)
			{
				if (targetentry == entry) isFound = true
			}
			return isFound
		}
		
		function HexToRgb(hex) {

			// Extract the RGB values
			local r = hex.slice(0, 2).tointeger(16)
			local g = hex.slice(2, 4).tointeger(16)
			local b = hex.slice(4, 6).tointeger(16)

			// Return the RGB values as an array
			return [r, g, b]
		}

		function parse_first_arg(args, fallback) {
			if (args == null) return fallback

			local args_arr = split(args, " ")
			if (args_arr.len() == 0) return fallback

			return args_arr[0]
		}

		function is_integer_safe(str)
		{
			if (str == null || str == "")
				return false

			local start = 0

			// Allow a leading '-'
			if (str[0] == '-')
			{
				if (str.len() == 1)
					return false // String is just "-"

				start = 1
			}

			for (local i = start; i < str.len(); i++)
			{
				local c = str[i]

				if (c < '0' || c > '9')
					return false
			}

			return true
		}

		function is_integer_safe_unsigned(str)
		{
			if (str == null || str == "")
				return false

			for (local i = 0; i < str.len(); i++)
			{
				local c = str[i]

				if (c < '0' || c > '9')
					return false
			}

			return true
		}
	}
	
	// ================================ //
	// MOD REGISTRY
	// ================================ //
	
	ModRegistry = {
	
		"HP" : {
		
			max_tiers = 3
			list_command = "/mod_vote_health"
			
			mod_tiers = [
			
				// HEALTH T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 0 : 1x Robot HP)"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "HEALTH MOD DISABLED! (TIER " + mod_args.current_tier + " -> 0 : 1x Robot HP)"
					}
					
					on_activate = function()
					{
						__diffmod.ModSystem.rebalance_weps_all()
						__diffmod.mod_active_double_robot_health = 0

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_HP", "0")
					}
					
					robot_health_mult = 1.0
					tank_health_mult = 1.0
				},
			
				// HEALTH T1
				{
					list_name = "HEALTH T1 (2x HP)"
					win_name = 	"HP T1"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_resistance.wav"
							sound_delay = 	0.0
						}
					]
					
					gametext_color = 	"34B0F7"
					clientprint_color = "34B0F7"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ACTIVATE the HEALTH modifier? (TIER 0 -> 1 : 2x Robot HP)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 1 : 2x Robot HP)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "HEALTH MOD ENABLED! (TIER 0 -> 1 : 2x Robot HP)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "HEALTH MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 1 : 2x Robot HP)"
					}
					
					on_activate = function()
					{
						__diffmod.ModSystem.rebalance_weps_all()
						__diffmod.mod_active_double_robot_health = 1

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_HP", "1")
					}
					
					robot_health_mult = 2.0
					tank_health_mult = 1.65
				},
				
				// HEALTH T2
				{
					list_name = "HEALTH T2 (3x HP)"
					win_name = 	"HP T2"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_knockout.wav"
							sound_delay = 	0.0
						}
					]
					
					gametext_color = 	"00FFF7"
					clientprint_color = "00FFF7"
					
					vote_upgrade_text = function(mod_args)
					{
						return "UPGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 2 : 3x Robot HP)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 2 : 3x Robot HP)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "HEALTH MOD UPGRADED! (TIER " + mod_args.current_tier + " -> 2 : 3x Robot HP)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "HEALTH MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 2 : 3x Robot HP)"
					}
					
					on_activate = function()
					{
						__diffmod.ModSystem.rebalance_weps_all()
						__diffmod.mod_active_double_robot_health = 2

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_HP", "2")
					}
					
					robot_health_mult = 3.0
					tank_health_mult = 2.45
				},
				
				// HEALTH T3
				{
					list_name = "HEALTH T3 (4x HP)"
					win_name = 	"HP T3"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_knockout.wav"
							sound_delay = 	0.0
						},
						{
							sound_name = 	"items/powerup_pickup_knockout_melee_hit.wav"
							sound_delay = 	1.0
						},
						{
							sound_name = 	"ambient/halloween/mysterious_perc_01.wav"
							sound_delay = 	1.0
						}
					]
					
					gametext_color = 	"00FFAE"
					clientprint_color = "00FFAE"
					
					vote_upgrade_text = function(mod_args)
					{
						return "UPGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 3 : 4x Robot HP)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 3 : 4x Robot HP)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "HEALTH MOD UPGRADED! (TIER " + mod_args.current_tier + " -> 3 : 4x Robot HP)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "HEALTH MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 3 : 4x Robot HP)"
					}
					
					on_activate = function()
					{
						__diffmod.ModSystem.rebalance_weps_all()
						__diffmod.mod_active_double_robot_health = 3

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_HP", "3")
					}
					
					robot_health_mult = 4.0
					tank_health_mult = 3.3
				}

				// HEALTH T4 (ONLY SETTABLE BY CMs)
				{
					list_name = "HEALTH T4 (5x HP)"
					win_name = 	"HP T4"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_knockout.wav"
							sound_delay = 	0.0
						},
						{
							sound_name = 	"items/powerup_pickup_knockout_melee_hit.wav"
							sound_delay = 	1.0
						},
						{
							sound_name = 	"ambient/halloween/mysterious_perc_01.wav"
							sound_delay = 	1.0
						},
						{
							sound_name = 	"mvm/mvm_warning.wav"
							sound_delay = 	1.0
						}
					]
					
					gametext_color = 	"8CEEFF"
					clientprint_color = "8CEEFF"
					
					vote_upgrade_text = function(mod_args)
					{
						return "UPGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 4 : 5x Robot HP)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the HEALTH modifier? (TIER " + mod_args.current_tier + " -> 4 : 5x Robot HP)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "HEALTH MOD UPGRADED! (TIER " + mod_args.current_tier + " -> 4 : 5x Robot HP)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "HEALTH MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 4 : 5x Robot HP)"
					}
					
					on_activate = function()
					{
						__diffmod.ModSystem.rebalance_weps_all()
						__diffmod.mod_active_double_robot_health = 4

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_HP", "4")
					}
					
					robot_health_mult = 5.0
					tank_health_mult = 4.15
				}
			]
		}
		
		"DMG" : {
			max_tiers = 2
			list_command = "/mod_vote_damage"
			
			mod_tiers = [ 
			
				// DAMAGE T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the DAMAGE modifier? (TIER " + mod_args.current_tier + " -> 0 : 1x Robot DMG)"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "DAMAGE MOD DISABLED! (TIER " + mod_args.current_tier + " -> 0 : 1x Robot DMG)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_DMG", "0")
					}
					
					robot_damage_mult = 1.0
				},
			
				// DAMAGE T1
				{
					list_name = "DAMAGE T1 (1.5x DMG)"
					win_name = 	"DMG T1"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_crits.wav"
							sound_delay = 	0.0
						}
					]
					
					gametext_color = 	"D93621"
					clientprint_color = "D93621"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ACTIVATE the DAMAGE modifier? (TIER 0 -> 1 : 1.5x Robot DMG)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the DAMAGE modifier? (TIER " + mod_args.current_tier + " -> 1 : 1.5x Robot DMG)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "DAMAGE MOD ENABLED! (TIER 0 -> 1 : 1.5x Robot DMG)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "DAMAGE MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 1 : 1.5x Robot DMG)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_DMG", "1")
					}
					
					robot_damage_mult = 1.5
				},
				
				// DAMAGE T2
				{
					list_name = "DAMAGE T2 (2x DMG)"
					win_name = 	"DMG T2"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_supernova.wav"
							sound_delay = 	0.3
						}
					]
					
					gametext_color = 	"EB0046"
					clientprint_color = "EB0046"
					
					vote_upgrade_text = function(mod_args)
					{
						return "UPGRADE the DAMAGE modifier? (TIER " + mod_args.current_tier + " -> 2 : 2x Robot DMG)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the DAMAGE modifier? (TIER " + mod_args.current_tier + " -> 2 : 2x Robot DMG)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "DAMAGE MOD UPGRADED! (TIER " + mod_args.current_tier + " -> 2 : 2x Robot DMG)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "DAMAGE MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 2 : 2x Robot DMG)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_DMG", "2")
					}
					
					robot_damage_mult = 2.0
				}
			
			]
		}
		
		"SPD" : {
			max_tiers = 2
			list_command = "/mod_vote_speed"
			
			mod_tiers = [ 
			
				// SPEED T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the SPEED modifier? (TIER " + mod_args.current_tier + " -> 0 : 1x Robot Speed)"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "SPEED MOD DISABLED! (TIER " + mod_args.current_tier + " -> 0 : 1x Robot Speed)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_SPD", "0")
					}

					robot_speed_mult = 1.0
					tank_speed_mult = 1.0
				},
			
				// SPEED T1
				{
					list_name = "SPEED T1 (1.5x SPD)"
					win_name = 	"SPD T1"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_agility.wav"
							sound_delay = 	0.15
						}
					]
					
					gametext_color = 	"FFAB00"
					clientprint_color = "FFAB00"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ACTIVATE the SPEED modifier? (TIER 0 -> 1 : 1.5x Robot Speed)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the SPEED modifier? (TIER " + mod_args.current_tier + " -> 1 : 1.5x Robot Speed)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "SPEED MOD ENABLED! (TIER 0 -> 1 : 1.5x Robot Speed)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "SPEED MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 1 : 1.5x Robot Speed)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_SPD", "1")
					}
					
					robot_speed_mult = 1.5
					tank_speed_mult = 1.35
				},
				
				// SPEED T2
				{
					list_name = "SPEED T2 (2x SPD)"
					win_name = 	"SPD T2"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_haste.wav"
							sound_delay = 	0.15
						}
					]
					
					gametext_color = 	"FF9900"
					clientprint_color = "FF9900"
					
					vote_upgrade_text = function(mod_args)
					{
						return "UPGRADE the SPEED modifier? (TIER " + mod_args.current_tier + " -> 2 : 2x Robot Speed)"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DOWNGRADE the SPEED modifier? (TIER " + mod_args.current_tier + " -> 2 : 2x Robot Speed)"
					}
					success_upgrade_text = function(mod_args)
					{
						return "SPEED MOD UPGRADED! (TIER " + mod_args.current_tier + " -> 2 : 2x Robot Speed)"
					}
					success_downgrade_text = function(mod_args)
					{
						return "SPEED MOD DOWNGRADED! (TIER " + mod_args.current_tier + " -> 2 : 2x Robot Speed)"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_SPD", "2")
					}
					
					robot_speed_mult = 2.0
					tank_speed_mult = 1.8
				}
			
			]
		}
		
		"INVS" : {
			max_tiers = 1
			list_command = "/mod_vote_invisible"
			
			mod_tiers = [ 
			
				// INVIS T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the INVISIBLE ROBOTS modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "INVISIBLE ROBOTS DISABLED!"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_INVS", "0")
					}
				},
			
				// INVIS T1
				{
					list_name = "INVISIBLE ROBOTS"
					win_name = 	"INVIS"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_plague.wav"
							sound_delay = 	0
						}
					]
					
					gametext_color = 	"03FC1C"
					clientprint_color = "03FC1C"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ENABLE the INVISIBLE ROBOTS modifier?"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the INVISIBLE ROBOTS modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return "INVISIBLE ROBOTS ACIVATED!"
					}
					success_downgrade_text = function(mod_args)
					{
						return "INVISIBLE ROBOTS DISABLED!"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_INVS", "1")
					}
				}
			]
		}
		
		"PRTL" : {
			max_tiers = 1
			list_command = "/mod_vote_portals"
			
			mod_tiers = [ 
			
				// PORTALS T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the PORTAL ANOMALIES modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "PORTAL ANOMALIES DISABLED!"
					}
					
					on_activate = function()
					{
						__diffmod.PortalSystem.ClearPortals(true)
						__diffmod.mod_active_portal_anomalies = false

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_PRTL", "0")
					}
				},
			
				// PORTALS T1
				{
					list_name = "PORTAL ANOMALIES"
					win_name = 	"PORTAL"
					
					upgrade_sounds = [
						{
							sound_name = 	"mvm/mvm_tele_activate.wav"
							sound_delay = 	0
						},
						{
							sound_name = 	"items/powerup_pickup_agility.wav"
							sound_delay = 	0
						}
					]
					
					gametext_color = 	"AC64FA"
					clientprint_color = "AC64FA"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ENABLE the PORTAL ANOMALIES modifier?"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the PORTAL ANOMALIES modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return "PORTAL ANOMALIES ACTIVATED!"
					}
					success_downgrade_text = function(mod_args)
					{
						return "PORTAL ANOMALIES DISABLED!"
					}
					
					on_activate = function()
					{
						__diffmod.PortalSystem.PortalSpawnInitialize()
						__diffmod.mod_active_portal_anomalies = true

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_PRTL", "1")
					}
				}
			]
		}
		
		"MDVL" : {
			max_tiers = 1
			list_command = "/mod_vote_medieval"
			
			mod_tiers = [ 
			
				// MDVL T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MEDIEVAL MODE modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "MEDIEVAL MODE DISABLED!"
					}
					
					on_activate = function()
					{
						PseudoMedieval.Fullcleanup()

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_MDVL", "0")
					}
				},
			
				// MDVL T1
				{
					list_name = "MEDIEVAL MODE"
					win_name = 	"MEDIEVAL"
					
					upgrade_sounds = [
						{
							sound_name = 	"ambient/medieval_doorclose.wav"
							sound_delay = 	0
						},
						{
							sound_name = 	"weapons/draw_sword.wav"
							sound_delay = 	0
						}
					]
					
					gametext_color = 	"FF0084"
					clientprint_color = "FF0084"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ENABLE the MEDIEVAL MODE modifier?"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MEDIEVAL MODE modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return "MEDIEVAL MODE ACIVATED!"
					}
					success_downgrade_text = function(mod_args)
					{
						return "MEDIEVAL MODE DISABLED!"
					}
					
					on_activate = function()
					{
						__diffmod.State.medieval_force_respawn = 1
						IncludeScript("pseudo_medieval", getroottable())

						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_MDVL", "1")
					}
				}
			]
		}

		"MRTHN" : {
			max_tiers = 1
			list_command = "/mod_vote_marathon"
			
			mod_tiers = [ 
			
				// MARATHON T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MARATHON modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "MARATHON DISABLED!"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_MRTHN", "0")
					}
				},
			
				// MOD T1
				{
					list_name = "MARATHON"
					win_name = 	"MARATHON"
					
					upgrade_sounds = [
						{
							sound_name = 	"ui/mm_level_two_achieved.wav"
							sound_delay = 	0
						}
					]
					
					gametext_color = 	"FC6203"
					clientprint_color = "FC6203"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ENABLE the MARATHON modifier?"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MARATHON modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return "MARATHON ACIVATED!"
					}
					success_downgrade_text = function(mod_args)
					{
						return "MARATHON DISABLED!"
					}
					
					on_activate = function()
					{
						if (__diffmod.GameUtil.LPMVM_is_loaded(true)) LPMVM.Events.Signal("diffmod_MRTHN", "1")
					}
				}
			]
		}
		
		/*
		"MODCODE" : {
			max_tiers = 1
			list_command = "/mod_vote_mod"
			
			mod_tiers = [ 
			
				// MOD T0
				{
					list_name = ""
					win_name = 	""
					
					upgrade_sounds = []
					
					gametext_color = 	"638BEB"
					clientprint_color = "638BEB"
					
					vote_upgrade_text = function(mod_args)
					{
						return ""
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MOD modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return ""
					}
					success_downgrade_text = function(mod_args)
					{
						return "MOD DISABLED!"
					}
					
					on_activate = function()
					{

					}
				},
			
				// MOD T1
				{
					list_name = "LIST MOD"
					win_name = 	"WIN MOD"
					
					upgrade_sounds = [
						{
							sound_name = 	"items/powerup_pickup_resistance.wav"
							sound_delay = 	0
						}
					]
					
					gametext_color = 	"FFFFFF"
					clientprint_color = "FFFFFF"
					
					vote_upgrade_text = function(mod_args)
					{
						return "ENABLE the MOD modifier?"
					}
					vote_downgrade_text = function(mod_args)
					{
						return "DISABLE the MOD modifier?"
					}
					success_upgrade_text = function(mod_args)
					{
						return "MOD ACIVATED!"
					}
					success_downgrade_text = function(mod_args)
					{
						return "MOD DISABLED!"
					}
					
					on_activate = function()
					{

					}
				}
			]
		}
		 */
	}
	
	
	// ================================ //
	// MOD SYSTEM
	// ================================ //
	
	ModSystem = {
		
		function mod_request(voter, mod_type, change_type, set_tier, force_type, misc_args = {})
		{
			if (!(mod_type in __diffmod.ModRegistry) && change_type != -2) return
			
			//(skip) = can skip if force vote is on
			
			
			//(skip) Mod voting disabled check
			if (force_type == 0 && !__diffmod.State.mod_vote_enabled) {
				ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "Modifier votes are currently disabled.")
				return
			}
			
			//(skip) Blacklist check
			if (force_type == 0 && change_type >= 0 && (mod_type in __diffmod.State.modifier_blacklist || (mod_type in __diffmod.State.legacy_modcodes && __diffmod.State.legacy_modcodes[mod_type] in __diffmod.State.modifier_blacklist)))
			{
				ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This modifier isn't available on this specific mission!")
				return
			}

			//(skip) Redridge first wave check
			// we need to handle some maps differently...
			local firstwave = 1
			switch (__diffmod.State.mapname)
			{
				case "mvm_redridge_b4b":
					firstwave = 0
					break
			}
			
			// Mission ended check
			if (GetRoundState() == 8)
			{
				if (force_type == 2) {
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "Modifiers can't be changed at this time - mission has ended")
				}
				else {
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "You can't vote at this time - mission has ended!")
				}
				return
			}
			
			//(skip) Wave 1 check
			if (force_type == 0 && change_type >= 0 && NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineWaveCount") != firstwave) 
			{
				if (change_type == 0 && set_tier > __diffmod.State.current_mods[mod_type]) {
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "You can only upgrade this modifier at the start of missions!")
					return
				}
				if (change_type == 1) {
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "You can only vote this modifier at the start of missions!")
					return
				}
			}
			
			//(skip) Mission underway check
			if (force_type == 0 && GetRoundState() == 4)
			{
				ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "You can't vote at this time - mission in progress!")
				return
			}
			
			//(skip) Unavailable mod check
			if (force_type == 0) {
				if (__diffmod.State.map_has_mods)
				{
					if (!(mod_type in maps_availablemods[__diffmod.State.mapname]) && change_type >= 0)
					{
						ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "That modifier isn't available on this map! Type '/mod_available' to view this map's available modifiers.")
						return
					}
				}
				else
				{
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This map has no available modifiers!")
					return
				}
			}

			// LPMVM not available check
			if (mod_type in __diffmod.State.LPMVM_dependent_mods && !__diffmod.GameUtil.LPMVM_is_loaded(true)) {
				ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This modifier depends on plugins that failed to load.")
				return
			}

			local target_mod = {}
			local target_mod_tier = 0

			if (change_type != -2) {
				target_mod = __diffmod.ModRegistry[mod_type]
				target_mod_tier = __diffmod.State.current_mods[mod_type]

				// Max tier mod check (for mod upgrades)
				if (change_type == 1 && target_mod_tier == target_mod.max_tiers)
				{
					if (mod_type == "HP")
					{
						ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "No, you're not having quintiple health. Not you in particular!")
						ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "Type '/mod_current' to see all currently enabled modifiers.")
						return
					}
					else 
					{
						ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This modifier is already at its max tier! Type '/mod_current' to see all currently enabled modifiers.")
						return
					}
				}
				
				// Currently active mod check (for mod sets)
				if (change_type == 0 && target_mod_tier == set_tier) 
				{
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This modifier is already at this tier! Type '/mod_current' to see all currently enabled modifiers.")
					return
				}	
				
				// Not active mod check (for mod downgrades)
				if (change_type == -1 && target_mod_tier == 0)
				{
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "This modifier is not currently active! Type '/mod_current' to see all currently enabled modifiers.")
					return
				}
			}
			else {
				// No active mod check (for reset all)
				if (!__diffmod.GameUtil.some_mod_enabled())
				{
					ClientPrint(GetPlayerFromUserID(voter),3,__diffmod.Const.chat_mark + "No modifiers are currently active!")
					return
				}
			}
			
			//(skip) Mod voting not enabled yet check
			if (force_type == 0 && __diffmod.State.start_cooldown != 0)
			{
				local scd_msg = __diffmod.Const.chat_mark + "Please wait " + __diffmod.State.start_cooldown + " seconds for voting to be enabled."
				ClientPrint(GetPlayerFromUserID(voter),3,scd_msg)
				return
			}
			
			//(skip) Mod voting cooldown check
			if (force_type == 0 && __diffmod.State.vote_cooldown != 0)
			{
				local vcd_msg = __diffmod.Const.chat_mark + "Please wait " + __diffmod.State.vote_cooldown + " seconds for vote cooldown to end."
				ClientPrint(GetPlayerFromUserID(voter),3,vcd_msg)
				return
			}
			
			// Mod change cooldown check
			if (__diffmod.State.mod_change_cooldown != 0)
			{
				local vcd_msg = __diffmod.Const.chat_mark + "Please wait " + __diffmod.State.mod_change_cooldown + " seconds for mod change cooldown to end."
				ClientPrint(GetPlayerFromUserID(voter),3,vcd_msg)
				return
			}
			
			// Nothing stopped mod set from happening!

			local chat_message = ""
			local vote_title = ""
			local vote_color = ""
			local target_tier = 0

			local playername = NetProps.GetPropString(GetPlayerFromUserID(voter), "m_szNetname")
			chat_message = __diffmod.Const.chat_mark + playername + " has initiated a modifier vote!"

			if (change_type != -2) {
				if (change_type == 1) {
					target_tier = target_mod_tier + 1
				}
				if (change_type == 0) {
					target_tier = set_tier
				}
				if (change_type == -1) {
					target_tier = target_mod_tier - 1
				}
				
				if (target_tier > target_mod_tier) {
					vote_title = target_mod.mod_tiers[target_tier].vote_upgrade_text({"current_tier" : target_mod_tier})
					vote_color = target_mod.mod_tiers[target_tier].gametext_color
				}
				else {
					vote_title = target_mod.mod_tiers[target_tier].vote_downgrade_text({"current_tier" : target_mod_tier})
					vote_color = __diffmod.Const.downgrade_color
				}
				
				
				if (force_type == 2) {
					__diffmod.State.mod_change_cooldown = 6
					__diffmod.ModSystem.mod_change(mod_type, target_tier)
				}
				else
				{
					__diffmod.State.vote_tier = target_tier
					__diffmod.GameUtil.setup_vote(voter, mod_type, chat_message, vote_title, vote_color)
				}
				
			}
			else {
				if (force_type == 2) {
					__diffmod.ModSystem.mod_change("reset_all", 0)
				}
				else
				{
					__diffmod.GameUtil.setup_vote(voter, "reset_all", chat_message, "REMOVE ALL current difficulty modifiers?", __diffmod.Const.downgrade_color)
				}	
			}
		}
		
		function mod_change(mod_type, target_tier)
		{
			if (mod_type != "reset_all")
			{
				local target_mod = __diffmod.ModRegistry[mod_type]
				local target_mod_current_tiernum = __diffmod.State.current_mods[mod_type]

				__diffmod.State.current_mods[mod_type] = target_tier
				local target_mod_tier = target_mod.mod_tiers[target_tier]
				target_mod_tier.on_activate()

				if (target_tier > target_mod_current_tiernum) {
					__diffmod.GameUtil.DoExplanation(target_mod_tier.success_upgrade_text({"current_tier" : target_mod_current_tiernum}), target_mod_tier.gametext_color, 0.3, "", false, 5)
					ClientPrint(null,3,"\x07" + target_mod_tier.clientprint_color + "[" + target_mod_tier.success_upgrade_text({"current_tier" : target_mod_current_tiernum}) + "]")
					ClientPrint(null,3,__diffmod.Const.modifier_tooltip)

					__diffmod.GameUtil.GlobalSound("coach/coach_defend_here.wav")
					foreach (sound in target_mod_tier.upgrade_sounds) {
						__diffmod.GameUtil.GlobalSound(sound.sound_name, sound.sound_delay)
					}
				}
				else {
					__diffmod.GameUtil.DoExplanation(target_mod_tier.success_downgrade_text({"current_tier" : target_mod_current_tiernum}), __diffmod.Const.downgrade_color, 0.3, "", false, 5)
					ClientPrint(null,3,"\x07" + target_mod_tier.clientprint_color + "[" + target_mod_tier.success_downgrade_text({"current_tier" : target_mod_current_tiernum}) + "]")

					__diffmod.GameUtil.GlobalSound("mvm/mvm_money_vanish.wav")
				}

				__diffmod.GameUtil.showhint_all()
			}
			else
			{
				foreach (mod, val in __diffmod.State.current_mods) {
					if (val > 0) {
						__diffmod.State.current_mods[mod] = 0
						__diffmod.ModRegistry[mod].mod_tiers[0].on_activate()
					}
				}
				__diffmod.GameUtil.DoExplanation("ALL MODIFIERS REMOVED", __diffmod.Const.downgrade_color, 0.3, "", false, 5)
				ClientPrint(null,3,"\x07" + __diffmod.Const.downgrade_color + "[ALL MODIFIERS REMOVED]")

				__diffmod.GameUtil.GlobalSound("mvm/mvm_money_vanish.wav")
			}
		}

		function toggle_mod_vote() {
			if (__diffmod.State.mod_vote_enabled) {
				__diffmod.State.mod_vote_enabled = false
				ClientPrint(null,3,__diffmod.Const.chat_mark + "Mod votes have been disabled.")
			}
			else {
				__diffmod.State.mod_vote_enabled = true
				ClientPrint(null,3,__diffmod.Const.chat_mark + "Mod votes have been enabled.")
			}
		}

		function rebalance_weps(player) {
			if (__diffmod.State.current_mods["HP"]) {
				local balancemult = __diffmod.State.current_mods["HP"] + 1.0
				local sniper_final_balancemult = 15.0 / 19.0 * balancemult
			
				// Sniper EH buff per hp mod
				for(local i = 0; i < NetProps.GetPropArraySize(player, "m_hMyWeapons"); i++)
				{
					//print("Checking: " + i)
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", i) == null) continue
					local wep_type = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i).GetClassname()
					
					if (wep_type == "tf_weapon_sniperrifle" || wep_type == "tf_weapon_sniperrifle_classic" || wep_type == "tf_weapon_sniperrifle_decap")
					{
						local rifle = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
						
						printl("balancemult: " + balancemult)
						printl("balancemult / 1: " + 1.0 / balancemult)
						printl("sniper final balancemult: " + sniper_final_balancemult)
						printl("sniper final balancemult / 1: " + 1.0 / sniper_final_balancemult)
						
						rifle.AddAttribute("dmg penalty vs players", sniper_final_balancemult, 0)
						rifle.AddAttribute("damage bonus HIDDEN", 1.0 / sniper_final_balancemult, 0)
						printl("RIFLE HAS BEEN BUFFED")
						
						NetProps.SetPropBool(player, "m_bForcePurgeFixedupStrings", true)
						NetProps.SetPropBool(rifle, "m_bForcePurgeFixedupStrings", true)
						break
					}
				}
			}
			else
			{
				for(local i = 0; i < NetProps.GetPropArraySize(player, "m_hMyWeapons"); i++)
				{
					//print("Checking: " + i)
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", i) == null) continue
					local wep_type = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i).GetClassname()
					
					if (wep_type == "tf_weapon_sniperrifle" || wep_type == "tf_weapon_sniperrifle_classic" || wep_type == "tf_weapon_sniperrifle_decap")
					{
						local rifle = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
						rifle.RemoveAttribute("dmg penalty vs players")
						rifle.RemoveAttribute("damage bonus HIDDEN")
						printl("RIFLE HAS BEEN NERFED")
						
						break
					}
				}
			}
		}

		function rebalance_weps_all() {
			for (local i = 1; i <= MaxClients().tointeger() ; i++)
			{
				local player = PlayerInstanceFromIndex(i)
				if (player == null) continue
				if (!player.IsPlayer()) continue
				if (!player.IsBotOfType(1337) && player.IsAlive()) {
					__diffmod.ModSystem.rebalance_weps(player)
				}
				NetProps.SetPropBool(player, "m_bForcePurgeFixedupStrings", true)
			}
		}

		/*

		This blacklisting stuff should be put in the format for each wave in the mission:

		InitWaveOutput
		{
			Target bignet
			Action RunScriptCode
			Param "
				if (`__diffmod` in getroottable())
				{
					// spectators 1, red 2, blu 3
					__diffmod.ModSystem.bot_team_blacklist_add([1,2,3])
					__diffmod.ModSystem.modifier_blacklist_add([`HP`,`DMG`,`SPD`,`INVS`,`PRTL`])
					__diffmod.ModSystem.player_set_team_set(2)
				}
			"
		}

		*/

		function bot_team_blacklist_add(blacklistarray)
		{
			local formatinput = ""
			for (local i = 0; i < blacklistarray.len(); i++)
			{
				formatinput += "`"
				formatinput += blacklistarray[i].tostring()
				formatinput += "`"
				formatinput += ":1"
				if (i + 1 != blacklistarray.len()) formatinput += ", "
			}
			local passstring = "__diffmod.State.bot_team_blacklist = {" + formatinput + "}"
			EntFire("worldspawn", "RunScriptCode", passstring, 0)
		}

		function modifier_blacklist_add(blacklistarray)
		{
			local formatinput = ""
			for (local i = 0; i < blacklistarray.len(); i++)
			{
				formatinput += "`"
				formatinput += blacklistarray[i]
				formatinput += "`"
				formatinput += ":1"
				if (i + 1 != blacklistarray.len()) formatinput += ", "
			}
			local passstring = "__diffmod.State.modifier_blacklist = {" + formatinput + "}\n" + "__diffmod.ModSystem.modifier_blacklist_refresh()"
			EntFire("worldspawn", "RunScriptCode", passstring, 0)
		}

		function player_set_team_set(setteam)
		{
			local passstring = "__diffmod.State.player_set_team = " + setteam.tostring()
			EntFire("worldspawn", "RunScriptCode", passstring, 0)
		}

		function modifier_blacklist_refresh()
		{
			local modifier_blacklisted = false
			foreach (mod, val in __diffmod.State.modifier_blacklist) {
				if (mod in __diffmod.State.current_mods && __diffmod.State.current_mods[mod] > 0) {
					__diffmod.State.current_mods[mod] = 0
					__diffmod.ModRegistry[mod].mod_tiers[0].on_activate()
					modifier_blacklisted = true
				}
			}

			// Legacy values
			local oldvalues = {"2HP" : "HP", "2DMG" : "DMG", "2SPD" : "SPD"}
			foreach (mod, val in oldvalues) {
				if (mod in __diffmod.State.modifier_blacklist && __diffmod.State.current_mods[val] > 0) {
					__diffmod.State.current_mods[val] = 0
					__diffmod.ModRegistry[val].mod_tiers[0].on_activate()
					modifier_blacklisted = true
				}
			}

			if (modifier_blacklisted)
			{
				printl("Modifiers blacklisted and removed...!")

				EntFire("worldspawn", "RunScriptCode", @"
				ClientPrint(null,3,`\x08638BEBFF[Some mods are blacklisted on this mission and have been removed!]`)
				ClientPrint(null,3,`\x08638BEBFFType '/mod_current' to see current mods`)
				ClientPrint(null,3,__diffmod.Const.modifier_tooltip)
				__diffmod.GameUtil.DoExplanation(`(SOME MODIFIERS WERE BLACKLISTED...)`, `638BEB`, 0.3, ``, false, 5)
				__diffmod.State.vote_type = ``
				__diffmod.GameUtil.GlobalSound(`mvm/mvm_money_vanish.wav`)
				"
				, 0.1)
			}
		}
	}
	
	
	// ================================ //
	// PORTAL SYSTEM
	// ================================ //
	
	PortalSystem = {

		PortalEntities = []

		// portal variables
		portal_positions = []
		portal_id = -1
		portal_engitele = true
		portal_is_incrementing = false

		function CreateFilter() {
			__diffmod.PortalSystem.PortalEntities.append(SpawnEntityFromTable("filter_activator_tfteam", {
				targetname = "red_only_filter",
				teamnum = 2,
				Negated = 0
			}))
		}

		function CreatePortal(position) {
		
			// Don't do this for shadows
			
			if (__diffmod.State.mapname == "mvm_shadows_b3") return
			
			// Create the particle system
			
			__diffmod.PortalSystem.PortalEntities.append(SpawnEntityFromTable("info_particle_system",
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
			__diffmod.PortalSystem.PortalEntities.append(newtriggerhurt)
		}
		
		// also clear everything if not null
		function ClearPortals(deleteportals) {
			if (deleteportals)
			{
				foreach (portal in __diffmod.PortalSystem.PortalEntities) {
					if (portal != null) portal.Kill()
				}
			}
			__diffmod.PortalSystem.PortalEntities.clear()
		}
		
		function PortalLogicInitialize() {
			portal_id = -1
			portal_engitele = true
			portal_is_incrementing = false
		}
		
		function PortalSpawnInitialize() {
			local filter = Entities.FindByName(null, "red_only_filter")
			if (filter == null) CreateFilter()
			
			foreach (position in portal_positions) {
				CreatePortal(position)
			}
		}
		
		function Increment() {
			if (!portal_is_incrementing) {
				// printl("IM INCREMEMENTING!!!!!!!!!!!!!!!")
				portal_is_incrementing = true
				
				EntFire("worldspawn", "RunScriptCode", @"
				__diffmod.PortalSystem.portal_id += 1
				if (__diffmod.PortalSystem.portal_id == __diffmod.PortalSystem.portal_positions.len()) __diffmod.PortalSystem.portal_id = -1
				if (RandomInt(0,1) == 0)
				{
					__diffmod.PortalSystem.portal_engitele = false
				}
				else
				{
					__diffmod.PortalSystem.portal_engitele = true
				}
				
				__diffmod.PortalSystem.portal_is_incrementing = false
				"
				, 1.5)
			}
		}
	
	}
	
	
	// ================================ //
	// SPAWN CATCHERS
	// ================================ //
	
	SpawnCatchers = {

	}
	
	// ================================ //
	// MISC THINKS
	// ================================ //
	
	MiscThinks = {
	
	}
	
	// ================================ //
	// EVENTS
	// ================================ //
	
	Events = {
		
        // Event is fired every wave init (on mission change, wave jump or post wave fail).
        function OnGameEvent_teamplay_round_start(_) {
			printl("MISSION LOAD EVENT FIRED")

			// reset bot team blacklist
			__diffmod.State.bot_team_blacklist.clear()
			
			// reset modifier blacklist
			__diffmod.State.modifier_blacklist.clear()

			// default player team
			__diffmod.State.player_set_team = 2
			
			// Create the thinker
			
			__diffmod.State.mod_ent_has_think_set = false
			EntFire("worldspawn", "RunScriptCode", @"
				__diffmod.GameUtil.SetupThinker()
			"
			, 0.5)
			
			// No longer resetting!
			__diffmod.State.wave_resetting = false
			
			// Clean up text display entities
			__diffmod.State.textent_s1 = null
			__diffmod.State.textent_s2 = null
			__diffmod.State.textent_s3 = null
			
			// Check if map has modifiers
			if (__diffmod.State.mapname in maps_availablemods)
			{
				if (maps_availablemods[__diffmod.State.mapname].len() != 0) {
					__diffmod.State.map_has_mods = true
					if ("PRTL" in maps_availablemods[__diffmod.State.mapname]) __diffmod.PortalSystem.portal_positions = maps_availablemods[__diffmod.State.mapname]["PRTL"]
				}
			}

			// Marathon stuff
			if (__diffmod.State.marathon_wave_failed) {
				printl("MISSION FAIL DETECTED")
				__diffmod.State.marathon_wave_failed = false
				// if (__diffmod.State.current_mods["MRTHN"] > 0 && (__diffmod.GameUtil.LPMVM_is_loaded(true))) LPMVM.Game.JumpToWave(1)
				if (__diffmod.State.current_mods["MRTHN"] > 0) {
					__diffmod.State.current_mods["MRTHN"] = 0
					__diffmod.ModRegistry["MRTHN"].mod_tiers[0].on_activate()
					__diffmod.State.vote_cooldown = 11
					__diffmod.State.mod_change_cooldown = 11
					EntFire("worldspawn", "RunScriptCode", @"
					ClientPrint(null,3,`\x08638BEBFF[YOU HAVE FAILED... MARATHON MODIFIER DISABLED]`)
					__diffmod.GameUtil.DoExplanation(`YOU HAVE FAILED... MARATHON MODIFIER DISABLED`, `638BEB`, 0.3, ``, false, 5)
					__diffmod.GameUtil.GlobalSound(`mvm/mvm_money_vanish.wav`)
					"
					, 0.1)
					EntFire("worldspawn", "RunScriptCode", @"
					__diffmod.GameUtil.DoExplanation(`If you wish to re-attempt MARATHON, vote to restart mission and re-vote it!`, `FC6203`, 0.3, ``, false, 5)
					__diffmod.GameUtil.GlobalSound(`coach/coach_defend_here.wav`)
					"
					, 5.2)
				}
			}

			if (NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineMaxWaveCount") == 1) {
				__diffmod.ModSystem.modifier_blacklist_add(["MRTHN"])
			}
			
			if (__diffmod.GameUtil.some_mod_enabled())
			{
				ClientPrint(null,3,__diffmod.Const.modifier_tooltip)
			}
			
			__diffmod.PortalSystem.ClearPortals(false)
			if (__diffmod.State.current_mods["PRTL"] > 0) {
				__diffmod.PortalSystem.PortalLogicInitialize()
				__diffmod.PortalSystem.PortalSpawnInitialize()
				
				EntFire("worldspawn", "RunScriptCode", @"
				__diffmod.PortalSystem.PortalLogicInitialize()
				"
				, 3.0)
			}
			
			// Clear all bot dmgreductions
			__diffmod.State.bot_dmgreductions.clear()
			__diffmod.State.damageres_setup = false
        }
		
		function OnGameEvent_player_spawn(params)
		{
			local player = GetPlayerFromUserID(params.userid)
			
			if (player.GetTeam() == 0) return

			if (player != null)
			{
				if (player.IsBotOfType(1337))
				{
					if (player.GetTeam().tostring() in __diffmod.State.bot_team_blacklist) return
					
					// __diffmod.GameUtil.register_ent_func(player, "post_spawn_bots_mods", __diffmod.SpawnCatchers.post_spawn_bots_mods)
					EntFireByHandle(player, "CallScriptFunction", "diffmod_post_spawn_bots_mods", 0, null, null)
					
					// __diffmod.GameUtil.register_ent_func(player, "post_spawn_bots_damageres", __diffmod.SpawnCatchers.post_spawn_bots_damageres)
					EntFireByHandle(player, "CallScriptFunction", "diffmod_post_spawn_bots_damageres", 0, null, null)					
				}
				else
				{
					// __diffmod.GameUtil.register_ent_func(player, "post_spawn_players_showhint", __diffmod.SpawnCatchers.post_spawn_players_showhint)
					EntFireByHandle(player, "CallScriptFunction", "diffmod_post_spawn_players_showhint", 1, null, null)
				}
			}
		}
		
		function OnGameEvent_player_say(params)
		{
			if (!GetPlayerFromUserID(params.userid).IsBotOfType(1337) && GetPlayerFromUserID(params.userid).GetTeam() != 0)
			{
				// printl("PLAYER HAS CHATTED!")
				
				switch (params.text.tolower())
				{
					case "/vote_reset_wave":
					case "!vote_reset_wave":
					case "/vote_resetwave":
					case "!vote_resetwave":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						if (GetRoundState() != 4)
						{
							ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "You can only vote to reset the wave during the wave!")
							break
						}
						if (__diffmod.State.wave_resetting)
						{
							ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "Wave is currently resetting!")
							break
						}
						local playername = NetProps.GetPropString(GetPlayerFromUserID(params.userid), "m_szNetname")
						__diffmod.GameUtil.setup_vote(params.userid, "reset_wave", __diffmod.Const.chat_mark + playername + " has initiated a wave reset vote!", "Force a wave fail and reset the wave?", "AAF542")
						break

					// ====================
					// RESET ALL MODS
					// ====================

					case "/mod_vote_resetall":
					case "!mod_vote_resetall":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "", -2, 0, 0)
						break

					case "/mod_force_vote_resetall":
					case "!mod_force_vote_resetall":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "", -2, 0, 1)
						break
					
					case "/mod_force_set_resetall":
					case "!mod_force_set_resetall":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "", -2, 0, 2)
						break
						
					// ====================
					// HEALTH MOD COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_health":
					case "!mod_vote_health":
					case "/mod_vote_hp":
					case "!mod_vote_hp":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_health":
					case "!mod_vote_remove_health":
					case "/mod_vote_remove_hp":
					case "!mod_vote_remove_hp":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_health_0":
					case "!mod_vote_health_0":
					case "/mod_vote_hp_0":
					case "!mod_vote_hp_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 0, 0)
						break

					case "/mod_vote_health_1":
					case "!mod_vote_health_1":
					case "/mod_vote_hp_1":
					case "!mod_vote_hp_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 1, 0)
						break

					case "/mod_vote_health_2":
					case "!mod_vote_health_2":
					case "/mod_vote_hp_2":
					case "!mod_vote_hp_2":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 2, 0)
						break

					case "/mod_vote_health_3":
					case "!mod_vote_health_3":
					case "/mod_vote_hp_3":
					case "!mod_vote_hp_3":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 3, 0)
						break

					// Force : Vote
					case "/mod_force_vote_health_0":
					case "!mod_force_vote_health_0":
					case "/mod_force_vote_hp_0":
					case "!mod_force_vote_hp_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 0, 1)
						break

					case "/mod_force_vote_health_1":
					case "!mod_force_vote_health_1":
					case "/mod_force_vote_hp_1":
					case "!mod_force_vote_hp_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 1, 1)
						break

					case "/mod_force_vote_health_2":
					case "!mod_force_vote_health_2":
					case "/mod_force_vote_hp_2":
					case "!mod_force_vote_hp_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 2, 1)
						break

					case "/mod_force_vote_health_3":
					case "!mod_force_vote_health_3":
					case "/mod_force_vote_hp_3":
					case "!mod_force_vote_hp_3":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 3, 1)
						break

					case "/mod_force_vote_health_4":
					case "!mod_force_vote_health_4":
					case "/mod_force_vote_hp_4":
					case "!mod_force_vote_hp_4":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 4, 1)
						break
					
					// Force : Set
					case "/mod_force_set_health_0":
					case "!mod_force_set_health_0":
					case "/mod_force_set_hp_0":
					case "!mod_force_set_hp_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 0, 2)
						break

					case "/mod_force_set_health_1":
					case "!mod_force_set_health_1":
					case "/mod_force_set_hp_1":
					case "!mod_force_set_hp_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 1, 2)
						break

					case "/mod_force_set_health_2":
					case "!mod_force_set_health_2":
					case "/mod_force_set_hp_2":
					case "!mod_force_set_hp_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 2, 2)
						break

					case "/mod_force_set_health_3":
					case "!mod_force_set_health_3":
					case "/mod_force_set_hp_3":
					case "!mod_force_set_hp_3":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 3, 2)
						break

					case "/mod_force_set_health_4":
					case "!mod_force_set_health_4":
					case "/mod_force_set_hp_4":
					case "!mod_force_set_hp_4":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "HP", 0, 4, 2)
						break

					// Old command notification
					case "/mod_vote_doublehealth":
					case "!mod_vote_doublehealth":
						ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "This command is no longer usable and has been replaced. Type /mod_type_help for info on the new command.")
						break
					
					// ====================
					// DAMAGE MOD COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_damage":
					case "!mod_vote_damage":
					case "/mod_vote_dmg":
					case "!mod_vote_dmg":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_damage":
					case "!mod_vote_remove_damage":
					case "/mod_vote_remove_dmg":
					case "!mod_vote_remove_dmg":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_damage_0":
					case "!mod_vote_damage_0":
					case "/mod_vote_dmg_0":
					case "!mod_vote_dmg_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 0, 0)
						break

					case "/mod_vote_damage_1":
					case "!mod_vote_damage_1":
					case "/mod_vote_dmg_1":
					case "!mod_vote_dmg_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 1, 0)
						break

					case "/mod_vote_damage_2":
					case "!mod_vote_damage_2":
					case "/mod_vote_dmg_2":
					case "!mod_vote_dmg_2":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 2, 0)
						break

					// Force : Vote
					case "/mod_force_vote_damage_0":
					case "!mod_force_vote_damage_0":
					case "/mod_force_vote_dmg_0":
					case "!mod_force_vote_dmg_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 0, 1)
						break

					case "/mod_force_vote_damage_1":
					case "!mod_force_vote_damage_1":
					case "/mod_force_vote_dmg_1":
					case "!mod_force_vote_dmg_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 1, 1)
						break

					case "/mod_force_vote_damage_2":
					case "!mod_force_vote_damage_2":
					case "/mod_force_vote_dmg_2":
					case "!mod_force_vote_dmg_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 2, 1)
						break

					// Force : Set
					case "/mod_force_set_damage_0":
					case "!mod_force_set_damage_0":
					case "/mod_force_set_dmg_0":
					case "!mod_force_set_dmg_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 0, 2)
						break

					case "/mod_force_set_damage_1":
					case "!mod_force_set_damage_1":
					case "/mod_force_set_dmg_1":
					case "!mod_force_set_dmg_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 1, 2)
						break

					case "/mod_force_set_damage_2":
					case "!mod_force_set_damage_2":
					case "/mod_force_set_dmg_2":
					case "!mod_force_set_dmg_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "DMG", 0, 2, 2)
						break
					
					// Old command notification
					case "/mod_vote_doubledamage":
					case "!mod_vote_doubledamage":
						ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "This command is no longer usable and has been replaced. Type /mod_type_help for info on the new command.")
						break

					// ====================
					// SPEED MOD COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_speed":
					case "!mod_vote_speed":
					case "/mod_vote_spd":
					case "!mod_vote_spd":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_speed":
					case "!mod_vote_remove_speed":
					case "/mod_vote_remove_spd":
					case "!mod_vote_remove_spd":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_speed_0":
					case "!mod_vote_speed_0":
					case "/mod_vote_spd_0":
					case "!mod_vote_spd_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 0, 0)
						break

					case "/mod_vote_speed_1":
					case "!mod_vote_speed_1":
					case "/mod_vote_spd_1":
					case "!mod_vote_spd_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 1, 0)
						break

					case "/mod_vote_speed_2":
					case "!mod_vote_speed_2":
					case "/mod_vote_spd_2":
					case "!mod_vote_spd_2":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 2, 0)
						break

					// Force : Vote
					case "/mod_force_vote_speed_0":
					case "!mod_force_vote_speed_0":
					case "/mod_force_vote_spd_0":
					case "!mod_force_vote_spd_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 0, 1)
						break

					case "/mod_force_vote_speed_1":
					case "!mod_force_vote_speed_1":
					case "/mod_force_vote_spd_1":
					case "!mod_force_vote_spd_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 1, 1)
						break

					case "/mod_force_vote_speed_2":
					case "!mod_force_vote_speed_2":
					case "/mod_force_vote_spd_2":
					case "!mod_force_vote_spd_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 2, 1)
						break
					
					// Force : Set
					case "/mod_force_set_speed_0":
					case "!mod_force_set_speed_0":
					case "/mod_force_set_spd_0":
					case "!mod_force_set_spd_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 0, 2)
						break

					case "/mod_force_set_speed_1":
					case "!mod_force_set_speed_1":
					case "/mod_force_set_spd_1":
					case "!mod_force_set_spd_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 1, 2)
						break

					case "/mod_force_set_speed_2":
					case "!mod_force_set_speed_2":
					case "/mod_force_set_spd_2":
					case "!mod_force_set_spd_2":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "SPD", 0, 2, 2)
						break

					// Old command notification
					case "/mod_vote_doublespeed":
					case "!mod_vote_doublespeed":
						ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "This command is no longer usable and has been replaced. Type /mod_type_help for info on the new command.")
						break

					
					// ====================
					// INVIS MOD COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_invisible":
					case "!mod_vote_invisible":
					case "/mod_vote_invisiblerobots":
					case "!mod_vote_invisiblerobots":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_invisible":
					case "!mod_vote_remove_invisible":
					case "/mod_vote_remove_invisiblerobots":
					case "!mod_vote_remove_invisiblerobots":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_invisible_0":
					case "!mod_vote_invisible_0":
					case "/mod_vote_invisiblerobots_0":
					case "!mod_vote_invisiblerobots_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 0, 0)
						break

					case "/mod_vote_invisible_1":
					case "!mod_vote_invisible_1":
					case "/mod_vote_invisiblerobots_1":
					case "!mod_vote_invisiblerobots_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 1, 0)
						break

					// Force : Vote
					case "/mod_force_vote_invisible_0":
					case "!mod_force_vote_invisible_0":
					case "/mod_force_vote_invisiblerobots_0":
					case "!mod_force_vote_invisiblerobots_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 0, 1)
						break

					case "/mod_force_vote_invisible_1":
					case "!mod_force_vote_invisible_1":
					case "/mod_force_vote_invisiblerobots_1":
					case "!mod_force_vote_invisiblerobots_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 1, 1)
						break

					// Force : Set
					case "/mod_force_set_invisible_0":
					case "!mod_force_set_invisible_0":
					case "/mod_force_set_invisiblerobots_0":
					case "!mod_force_set_invisiblerobots_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 0, 2)
						break

					case "/mod_force_set_invisible_1":
					case "!mod_force_set_invisible_1":
					case "/mod_force_set_invisiblerobots_1":
					case "!mod_force_set_invisiblerobots_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "INVS", 0, 1, 2)
						break

					
					// ====================
					// PORTALS COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_portal":
					case "!mod_vote_portal":
					case "/mod_vote_portals":
					case "!mod_vote_portals":
					case "/mod_vote_portalanomalies":
					case "!mod_vote_portalanomalies":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_portal":
					case "!mod_vote_remove_portal":
					case "/mod_vote_remove_portals":
					case "!mod_vote_remove_portals":
					case "/mod_vote_remove_portalanomalies":
					case "!mod_vote_remove_portalanomalies":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_portal_0":
					case "!mod_vote_portal_0":
					case "/mod_vote_portals_0":
					case "!mod_vote_portals_0":
					case "/mod_vote_portalanomalies_0":
					case "!mod_vote_portalanomalies_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 0, 0)
						break

					case "/mod_vote_portal_1":
					case "!mod_vote_portal_1":
					case "/mod_vote_portals_1":
					case "!mod_vote_portals_1":
					case "/mod_vote_portalanomalies_1":
					case "!mod_vote_portalanomalies_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 1, 0)
						break

					// Force : Vote
					case "/mod_force_vote_portal_0":
					case "!mod_force_vote_portal_0":
					case "/mod_force_vote_portals_0":
					case "!mod_force_vote_portals_0":
					case "/mod_force_vote_portalanomalies_0":
					case "!mod_force_vote_portalanomalies_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 0, 1)
						break

					case "/mod_force_vote_portal_1":
					case "!mod_force_vote_portal_1":
					case "/mod_force_vote_portals_1":
					case "!mod_force_vote_portals_1":
					case "/mod_force_vote_portalanomalies_1":
					case "!mod_force_vote_portalanomalies_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 1, 1)
						break
					
					// Force : Set
					case "/mod_force_set_portal_0":
					case "!mod_force_set_portal_0":
					case "/mod_force_set_portals_0":
					case "!mod_force_set_portals_0":
					case "/mod_force_set_portalanomalies_0":
					case "!mod_force_set_portalanomalies_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 0, 2)
						break

					case "/mod_force_set_portal_1":
					case "!mod_force_set_portal_1":
					case "/mod_force_set_portals_1":
					case "!mod_force_set_portals_1":
					case "/mod_force_set_portalanomalies_1":
					case "!mod_force_set_portalanomalies_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "PRTL", 0, 1, 2)
						break
					
					// ====================
					// MEDIEVAL MODE COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_medieval":
					case "!mod_vote_medieval":
					case "/mod_vote_medievalmode":
					case "!mod_vote_medievalmode":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_medieval":
					case "!mod_vote_remove_medieval":
					case "/mod_vote_remove_medievalmode":
					case "!mod_vote_remove_medievalmode":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_medieval_0":
					case "!mod_vote_medieval_0":
					case "/mod_vote_medievalmode_0":
					case "!mod_vote_medievalmode_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 0, 0)
						break

					case "/mod_vote_medieval_1":
					case "!mod_vote_medieval_1":
					case "/mod_vote_medievalmode_1":
					case "!mod_vote_medievalmode_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 1, 0)
						break

					// Force : Vote
					case "/mod_force_vote_medieval_0":
					case "!mod_force_vote_medieval_0":
					case "/mod_force_vote_medievalmode_0":
					case "!mod_force_vote_medievalmode_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 0, 1)
						break

					case "/mod_force_vote_medieval_1":
					case "!mod_force_vote_medieval_1":
					case "/mod_force_vote_medievalmode_1":
					case "!mod_force_vote_medievalmode_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 1, 1)
						break

					// Force : Set
					case "/mod_force_set_medieval_0":
					case "!mod_force_set_medieval_0":
					case "/mod_force_set_medievalmode_0":
					case "!mod_force_set_medievalmode_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 0, 2)
						break

					case "/mod_force_set_medieval_1":
					case "!mod_force_set_medieval_1":
					case "/mod_force_set_medievalmode_1":
					case "!mod_force_set_medievalmode_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MDVL", 0, 1, 2)
						break


					// ====================
					// MARATHON COMMANDS
					// ====================

					// Normal Vote : Upgrade
					case "/mod_vote_marathon":
					case "!mod_vote_marathon":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 1, 0, 0)
						break

					// Normal Vote : Downgrade
					case "/mod_vote_remove_marathon":
					case "!mod_vote_remove_marathon":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", -1, 0, 0)
						break

					// Normal Vote : Set
					case "/mod_vote_marathon_0":
					case "!mod_vote_marathon_0":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 0, 0)
						break

					case "/mod_vote_marathon_1":
					case "!mod_vote_marathon_1":
						if (__diffmod.GameUtil.check_spec(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 1, 0)
						break

					// Force : Vote
					case "/mod_force_vote_marathon_0":
					case "!mod_force_vote_marathon_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 0, 1)
						break

					case "/mod_force_vote_marathon_1":
					case "!mod_force_vote_marathon_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 1, 1)
						break

					// Force : Set
					case "/mod_force_set_marathon_0":
					case "!mod_force_set_marathon_0":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 0, 2)
						break

					case "/mod_force_set_marathon_1":
					case "!mod_force_set_marathon_1":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.mod_request(params.userid, "MRTHN", 0, 1, 2)
						break

					

					case "/toggle_mod_vote":
					case "!toggle_mod_vote":
					case "/toggle_mod_votes":
					case "!toggle_mod_votes":
						if (!__diffmod.GameUtil.check_can_force_mod(params.userid)) break
						__diffmod.ModSystem.toggle_mod_vote()
						break
						
					// vote catches
					case "/vote_y":
					case "!vote_y":
					case "/y":
					case "!y":
					case "y":
						if (__diffmod.State.in_vote_state)
						{
							if (__diffmod.GameUtil.check_spec(params.userid)) break
							if (!__diffmod.MiscUtil.arrayfind(__diffmod.State.voted_playerids, params.userid))
							{
								__diffmod.GameUtil.GlobalSound("ui/vote_yes.wav")
								__diffmod.State.vote_y_count += 1
								__diffmod.State.voted_playerids.append(params.userid)
								ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "Vote successfully recorded.")
							}
							else
							{
								ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "You have already cast a vote!")
							}
						}
						break
					case "/vote_n":
					case "!vote_n":
					case "/n":
					case "!n":
					case "n":
						if (__diffmod.State.in_vote_state)
						{
							if (__diffmod.GameUtil.check_spec(params.userid)) break
							if (!__diffmod.MiscUtil.arrayfind(__diffmod.State.voted_playerids, params.userid))
							{
								__diffmod.GameUtil.GlobalSound("ui/vote_no.wav")
								__diffmod.State.vote_n_count += 1
								__diffmod.State.voted_playerids.append(params.userid)
								ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "Vote successfully recorded.")
							}
							else
							{
								ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "You have already cast a vote!")
							}
						}
						break
					case "/mod_current":
					case "!mod_current":
					case "/currentmods":
					case "!currentmods":
					case "/current_mods":
					case "!current_mods":
						local current_modifiers = ""
						foreach (mod in __diffmod.State.mod_order) {
							local val = __diffmod.State.current_mods[mod]
							if (val > 0) {
								current_modifiers += "\n[" + __diffmod.ModRegistry[mod].mod_tiers[val].list_name + "]"
							}
						}
						if (current_modifiers != "")
						{
							local current_modifiers_message = "< CURRENT DIFFICULTY MODIFIERS >\n" + current_modifiers
							__diffmod.GameUtil.ShowHudHint(current_modifiers_message, GetPlayerFromUserID(params.userid), 10)
						}
						else
						{
							ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "There are no currently enabled modifiers!")
						}
						break
					case "/mod_available":
					case "!mod_available":
					case "/availablemods":
					case "!availablemods":
					case "/available_mods":
					case "!available_mods":
						if (__diffmod.State.map_has_mods)
						{
							local available_modifiers = ""
							foreach (mod in __diffmod.State.mod_order) {
								if (mod in maps_availablemods[__diffmod.State.mapname] && !(mod in __diffmod.State.modifier_blacklist) && !(mod in __diffmod.State.legacy_modcodes && __diffmod.State.legacy_modcodes[mod] in __diffmod.State.modifier_blacklist)) {
									available_modifiers += "\n" + __diffmod.ModRegistry[mod].list_command
								}
							}
							
							if (available_modifiers != "")
							{
								available_modifiers += "\n\n/mod_vote_resetall"
								local current_modifiers_message = "< AVAILABLE DIFFICULTY MODIFIERS >\n(type these in chat to start vote)\n" + available_modifiers
								__diffmod.GameUtil.ShowHudHint(current_modifiers_message, GetPlayerFromUserID(params.userid), 10)
							}
							else
							{
								ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "There are no currently available modifiers!")
							}
						}
						else
						{
							ClientPrint(GetPlayerFromUserID(params.userid),3,__diffmod.Const.chat_mark + "This map has no available modifiers!")
						}
						break
					case "/diffmod_help":
					case "!diffmod_help":
					case "/mod_help":
					case "!mod_help":
						__diffmod.GameUtil.ShowHudHint("< DIFFMOD HELP >\nDiffmod is a plugin for difficulty modifiers which affect gameplay.\n\nType one of the following to learn more:\n/mod_status_help\n/mod_type_help\n/reset_wave_help\n/util_command_help\n/weapon_rebalances\n/difficulty_info", GetPlayerFromUserID(params.userid), 10)
						break
					case "/mod_status_help":
					case "!mod_status_help":
						__diffmod.GameUtil.ShowHudHint("< MOD STATUS HELP >\n\nList curently available mods for the map:\n/mod_available\n\nList currently enabled mods:\n/mod_current", GetPlayerFromUserID(params.userid), 10)
						break

					// ====================
					// MOD MANUAL
					// ====================
					case "/mod_types_help":
					case "!mod_types_help":
					case "/mod_type_help":
					case "!mod_type_help":
						__diffmod.GameUtil.ShowHudHint("< MOD TYPE HELP >\nFind out what each modifier does and their commands:\n\n/mod_health_help\n/mod_damage_help\n/mod_speed_help\n/mod_invisible_help\n/mod_portals_help\n/mod_medieval_help\n/mod_marathon_help\n\n/mod_remove_help", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_remove_help":
					case "!mod_remove_help":
						__diffmod.GameUtil.ShowHudHint("< REMOVE MOD HELP >\n\nTo reset all active mods, type:\n/mod_vote_resetall\n\nA specific mod can be removed by voting its 0th tier, e.g:\n/mod_vote_health_0", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_health_help":
					case "!mod_health_help":
					case "/mod_hp_help":
					case "!mod_hp_help":
						__diffmod.GameUtil.ShowHudHint("< HEALTH MOD INFO >\nIncreases health of robots and tanks.\n\nTier 1: 2x HP\nTier 2: 3x HP\nTier 3: 4x HP\n\nCommands:\n\nUpgrade tier:\n/mod_vote_health\n\nDowngrade tier:\n/mod_vote_remove_health\n\nSet to tier:\n/mod_vote_health_<tiernum>", GetPlayerFromUserID(params.userid), 10)
						break
					
					case "/mod_damage_help":
					case "!mod_damage_help":
					case "/mod_dmg_help":
					case "!mod_dmg_help":
						__diffmod.GameUtil.ShowHudHint("< DAMAGE MOD INFO >\nIncreases damage of robots.\n\nTier 1: 1.5x DMG\nTier 2: 2x DMG\n\nCommands:\n\nUpgrade tier:\n/mod_vote_damage\n\nDowngrade tier:\n/mod_vote_remove_damage\n\nSet to tier:\n/mod_vote_damage_<tiernum>", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_speed_help":
					case "!mod_speed_help":
					case "/mod_spd_help":
					case "!mod_spd_help":
						__diffmod.GameUtil.ShowHudHint("< SPEED MOD INFO >\nIncreases speed of robots and tanks.\n\nTier 1: 1.5x SPD\nTier 2: 2x SPD\n\nCommands:\n\nUpgrade tier:\n/mod_vote_speed\n\nDowngrade tier:\n/mod_vote_remove_speed\n\nSet to tier:\n/mod_vote_speed_<tiernum>", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_invisible_help":
					case "!mod_invisible_help":
					case "/mod_invisiblerobots_help":
					case "!mod_invisiblerobots_help":
						__diffmod.GameUtil.ShowHudHint("< INVISIBLE ROBOTS MOD INFO >\nMakes robots and tanks almost invisible.\n\nCommands:\n\nEnable:\n/mod_vote_invisible\n\nDisable:\n/mod_vote_remove_invisible", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_portals_help":
					case "!mod_portals_help":
					case "/mod_portal_help":
					case "!mod_portal_help":
					case "/mod_portalanomalies_help":
					case "!mod_portalanomalies_help":
						__diffmod.GameUtil.ShowHudHint("< PORTAL ANOMALIES MOD INFO >\nRobots can occasionally spawn from portals around the map.\n\nCommands:\n\nEnable:\n/mod_vote_portals\n\nDisable:\n/mod_vote_remove_portals", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_medieval_help":
					case "!mod_medieval_help":
					case "/mod_medievalmode_help":
					case "!mod_medievalmode_help":
						__diffmod.GameUtil.ShowHudHint("< MEDIEVAL MOD INFO >\nEnables medieval mode gamerules (for player team only!)\n\nCommands:\n\nEnable:\n/mod_vote_medieval\n\nDisable:\n/mod_vote_remove_medieval", GetPlayerFromUserID(params.userid), 10)
						break

					case "/mod_marathon_help":
					case "!mod_marathon_help":
						__diffmod.GameUtil.ShowHudHint("< MARATHON MOD INFO >\nYou get no breaktime between waves.\nAutomatically disabled upon wave loss.\nTo beat marathon mode, you have to beat the whole mission in one go!\n\nCommands:\n\nEnable:\n/mod_vote_marathon\n\nDisable:\n/mod_vote_remove_marathon", GetPlayerFromUserID(params.userid), 10)
						break


					case "/reset_wave_help":
					case "!reset_wave_help":
						__diffmod.GameUtil.ShowHudHint("< RESET WAVE HELP >\n\nCall a vote to reset the current wave:\n/vote_reset_wave\n\nUse this command when a softlock happens!", GetPlayerFromUserID(params.userid), 10)
						break
					case "/util_command_help":
					case "!util_command_help":
					case "/util_help":
					case "!util_help":
						__diffmod.GameUtil.ShowHudHint("< UTILITY COMMANDS HELP >\n\nList how much of each class your team currently has:\n/classcount", GetPlayerFromUserID(params.userid), 10)
						// __diffmod.GameUtil.ShowHudHint("< UTILITY COMMANDS HELP >\n\nList how much of each class your team currently has:\n/classcount\n\nList your current leaderboard stats:\n/mystats", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/weapon_rebalances":
					case "!weapon_rebalances":
						__diffmod.GameUtil.ShowHudHint("< WEAPON REBALANCES >\n\nSome certain weapons have recieved rebalances.\nType one of the commands below to view them:\n\n/sniper_explosive_hs\n/gas\n/yer", GetPlayerFromUserID(params.userid), 10)
						break
					case "/sniper_explosive_hs":
					case "!sniper_explosive_hs":
					case "/sniper_ehs":
					case "!sniper_ehs":
					case "/sniper_eh":
					case "!sniper_eh":
						__diffmod.GameUtil.ShowHudHint("< SNIPER EHS BUFF >\n\nSniper's explosive headshot gets a damage buff per HP mod added.\n\nThe 3rd tick of EHS will always deal enough damage to kill a standard medic with the current HP scaling.\n\nNote that this buff does not apply to the direct shot!", GetPlayerFromUserID(params.userid), 10)
						break
					case "/yer":
					case "!yer":
						__diffmod.GameUtil.ShowHudHint("< YER BUFF >\n\nThis server allows spy's 'your eternal reward' knife to function just like in casual.\n\nBefore, vanilla MvM nerfs the YER by having a delay in the disguise given after stabbing a robot.\nThis server removes that nerf.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/difficulty_info":
					case "!difficulty_info":
					case "/diff_info":
					case "!diff_info":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nThis server has many different difficulty levels assigned to each mission.\nType one of the following to learn more about the difficulty:\n\n/diff_nor\n/diff_int\n/diff_adv\n/diff_exp\n/diff_mas\n/diff_hypmas\n/diff_gndmas\n/diff_ult", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_nor":
					case "!diff_nor":
					case "/diff_norm":
					case "!diff_norm":
					case "/diff_normal":
					case "!diff_normal":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Normal\nLabel: nor\nRelative scale: 1\n\nThe easiest difficulty.\nGreat for those new to MvM, and\ncan easily be done solo.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_int":
					case "!diff_int":
					case "/diff_intermediate":
					case "!diff_intermediate":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Intermediate\nLabel: int\nRelative scale: 2\n\nA step up from normal.\nStill not too overbearing, but provides\na bit more challenge.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_adv":
					case "!diff_adv":
					case "/diff_advanced":
					case "!diff_advanced":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Advanced\nLabel: adv\nRelative scale: 3\n\nThe typical mission difficulty for 6 mann teams\nthat want a casual yet engaging experience.\nTo cater for casual 20 mann teams, around\n4 difficulty modifiers are recommended.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_exp":
					case "!diff_exp":
					case "/diff_expert":
					case "!diff_expert":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Expert\nLabel: exp\nRelative scale: 4\n\nA challenging step up from advanced which demands\ngreater effort from 6 mann teams to win.\nTo cater for casual 20 mann teams, around\n3 difficulty modifiers are recommended.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_mas":
					case "!diff_mas":
					case "/diff_master":
					case "!diff_master":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Master\nLabel: mas\nRelative scale: 5\n\nThe next step after expert.\nThe hardest skill test for 6 mann teams.\nTo cater for casual 20 mann teams, around\n2 difficulty modifiers are recommended.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_hypmas":
					case "!diff_hypmas":
					case "/diff_hypermaster":
					case "!diff_hypermaster":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Hypermaster\nLabel: hypmas\nRelative scale: 6\n\nA step up from master.\nNigh impossible for 6 mann teams, but\ncasual and engaging for 20 mann teams.\nFor 20 mann, 1 difficulty modifier can be\nadded for a more demanding challenge.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_gndmas":
					case "!diff_gndmas":
					case "/diff_grandmaster":
					case "!diff_grandmaster":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Grandmaster\nLabel: gndmas\nRelative scale: 7\n\nA step above hypermaster.\nThese missions are some of the server's hardest,\neven without modifiers. These missions demand sufficient\nattention and effort from 20 mann teams.", GetPlayerFromUserID(params.userid), 10)
						break
						
					case "/diff_ult":
					case "!diff_ult":
					case "/diff_ultimate":
					case "!diff_ultimate":
						__diffmod.GameUtil.ShowHudHint("< DIFFICULTY INFO >\n\nName: Ultimate\nLabel: ult\nRelative scale: 8\n\nThe step beyond grandmaster.\nMissions that bear this label are the utmost hardest\nchallenges this server can offer. 20 mann teams\nmust strategize together and give their all to win.", GetPlayerFromUserID(params.userid), 10)
						break
					
					/*
					case "/mystats":
					case "!mystats":
					case "/my_stats":
					case "!my_stats":
						local stats_target = GetPlayerFromUserID(params.userid)
						local stats_score = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iTotalScore", stats_target.entindex())
						local stats_curr_money = stats_target.GetCurrency()
						local stats_ping = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iPing", stats_target.entindex())
						
						// these need to be preserved per wave
						
						local stats_rdamage = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iDamage", stats_target.entindex())
						local stats_tdamage = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iDamageBoss", stats_target.entindex())
						local stats_healing = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iHealing", stats_target.entindex())
						//local stats_support = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iBonusPoints", stats_target.entindex())
						local stats_coll_money = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"),"m_iCurrencyCollected", stats_target.entindex())
						
						if (params.userid in __diffmod.player_stats)
						{
							stats_rdamage += __diffmod.player_stats[params.userid].stats_rdamage
							stats_tdamage += __diffmod.player_stats[params.userid].stats_tdamage
							stats_healing += __diffmod.player_stats[params.userid].stats_healing
							// stats_support += __diffmod.player_stats[params.userid].stats_support
							stats_coll_money += __diffmod.player_stats[params.userid].stats_coll_money
						}
						local stats_message = "< YOUR STATS >\n"
						stats_message += "Score: " + stats_score
						stats_message += "\nRobot Damage: " + stats_rdamage
						stats_message += "\nTank Damage: " + stats_tdamage
						stats_message += "\nHealing: " + stats_healing
						//stats_message += "\nSupport: " + stats_support
						stats_message += "\nCurrent Money: " + stats_curr_money
						stats_message += "\nCollected Money: " + stats_coll_money
						stats_message += "\nPing: " + stats_ping
						__diffmod.GameUtil.ShowHudHint(stats_message, GetPlayerFromUserID(params.userid), 10)
						break
					*/
					case "/classcount":
					case "!classcount":
					case "/class_count":
					case "!class_count":
						local total_count = 0
						local class_array = []
						for (local i = 0; i <= 9; i++)
						{
							class_array.push(0);
						}
						for (local i = 1; i <= MaxClients().tointeger() ; i++)
						{
							local count_target = PlayerInstanceFromIndex(i)
							if (count_target == null) continue
							if (!count_target.IsPlayer()) continue
							if (!count_target.IsBotOfType(1337) && count_target.GetTeam() == __diffmod.State.player_set_team && count_target.GetPlayerClass() != 0) {
								class_array[count_target.GetPlayerClass()] += 1
								total_count += 1
							}
							NetProps.SetPropBool(count_target, "m_bForcePurgeFixedupStrings", true)
						}
						local count_message = "< CLASS COUNT >\n"
						count_message += "\nTotal Active Players: " + total_count.tostring()
						count_message += "\nScout: " + class_array[1].tostring()
						count_message += "\nSoldier: " + class_array[3].tostring()
						count_message += "\nPyro: " + class_array[7].tostring()
						count_message += "\nDemoman: " + class_array[4].tostring()
						count_message += "\nHeavyweapons: " + class_array[6].tostring()
						count_message += "\nEngineer: " + class_array[9].tostring()
						count_message += "\nMedic: " + class_array[5].tostring()
						count_message += "\nSniper: " + class_array[2].tostring()
						count_message += "\nSpy: " + class_array[8].tostring()
						__diffmod.GameUtil.ShowHudHint(count_message, GetPlayerFromUserID(params.userid), 10)
						break
				}
			}
		}
		
		
		function OnGameEvent_post_inventory_application(params) {
			local player = GetPlayerFromUserID(params.userid)
			if (player == null) return
			if (!player.IsPlayer()) return
			if (!player.IsBotOfType(1337) && player.IsAlive() && (player.GetPlayerClass() == 2)) __diffmod.ModSystem.rebalance_weps(GetPlayerFromUserID(params.userid))
		}
		
		OnGameEvent_recalculate_holidays = function(params) {
			if (GetRoundState() == 3)
			{
				if (__diffmod.State.current_mods["MDVL"] > 0) {
					EntFire("worldspawn", "RunScriptCode", @"
					IncludeScript(`pseudo_medieval`, getroottable())
					"
					, 0)
				}
			}
		}
		
		function OnGameEvent_mvm_wave_complete(params)
		{
			if (__diffmod.GameUtil.some_mod_enabled())
			{
				__diffmod.GameUtil.showhint_all()
			}
			
			EntFire("worldspawn", "RunScriptCode", @"
			__diffmod.PortalSystem.PortalLogicInitialize()
			"
			, 3.0)
			
			if (__diffmod.State.current_mods["MDVL"] > 0) {
				EntFire("worldspawn", "RunScriptCode", @"
				IncludeScript(`pseudo_medieval`, getroottable())
				"
				, 0)
			}
			
			// Clear out this in case somehow some userid hasnt been deleted
			__diffmod.State.bot_dmgreductions.clear()

			// Keep going for marathon
			if (__diffmod.State.current_mods["MRTHN"] > 0 && (__diffmod.GameUtil.LPMVM_is_loaded(true))) {
				EntFire("worldspawn", "RunScriptCode", @"
				// GetRoundState() == 8 && 
				if (__diffmod.GameUtil.LPMVM_is_loaded(true)) {
					LPMVM.Game.StartWave()
					__diffmod.GameUtil.GlobalSound(`ui/mm_rank_progress_tick_up.wav`)
					__diffmod.GameUtil.GlobalSound(`ui/mm_scoreboardpanel_slide.wav`)
				}
				"
				, 3.0)
			}
		}
		
		function OnGameEvent_mvm_mission_complete(params)
		{
			local final_modifiers = ""

			foreach (mod in __diffmod.State.mod_order) {
				local val = __diffmod.State.current_mods[mod]
				if (val > 0) {
					final_modifiers += __diffmod.ModRegistry[mod].mod_tiers[val].win_name + " "
				}
			}
			
			// printl(final_modifiers)
			if (final_modifiers != "")
			{
				local final_win_message = "[" + final_modifiers + "MODE COMPLETE!]"
				__diffmod.GameUtil.DoExplanation(final_win_message, "FFFF00", 0.78, "", false, 999)
				__diffmod.GameUtil.GlobalSound("misc/killstreak.wav")
			}
			
			EntFire("worldspawn", "RunScriptCode", @"
			__diffmod.PortalSystem.PortalLogicInitialize()
			"
			, 3.0)
		}
		// fix bot health eye glow
		function OnGameEvent_player_death(params) {

			local bot = GetPlayerFromUserID(params.userid)
			if (!bot.IsBotOfType(1337)) return
			
			if (params.userid in __diffmod.State.bot_dmgreductions) {
				delete __diffmod.State.bot_dmgreductions[params.userid]
			}
			
			// bot.RemoveCustomAttribute("max health additive bonus")
		}
		
		function OnGameEvent_begin_wave(params) {
			PortalHander.PortalLogicInitialize()
		}
	}
}

// ================================ //
// GLOBAL FUNCTIONS
// ================================ //

::diffmod_post_validate_script_scope <- function()
{
	printl("DELAYED SCRIPT SCOPE CREATED")
	self.ValidateScriptScope()
	self.RemoveEFlags(1048576)
}

::diffmod_post_spawn_players_showhint <- function()
{
	local current_modifiers = ""
	foreach (mod in __diffmod.State.mod_order) {
		local val = __diffmod.State.current_mods[mod]
		if (val > 0) {
			current_modifiers += "\n[" + __diffmod.ModRegistry[mod].mod_tiers[val].list_name + "]"
		}
	}
	if (current_modifiers != "")
	{
		local current_modifiers_message = "< CURRENT DIFFICULTY MODIFIERS >\n" + current_modifiers
		__diffmod.GameUtil.ShowHudHint(current_modifiers_message, self, 10)
	}
}

::diffmod_portal_spawn_bot <- function() {
	// printl("PORTAL POST SPAWN")

	if (self.HasBotTag("alwaysportal") && __diffmod.PortalSystem.portal_positions.len() != 0) {
		local bot_tags = {}
		self.GetAllBotTags(bot_tags)

		local found_portal_id = -1

		foreach(i, tag in bot_tags) {
			local tagsegments = split( tag, "_" )
			if (tagsegments.len() >= 2 && tagsegments[0] == "portalat") {
				if (__diffmod.MiscUtil.is_integer_safe_unsigned(tagsegments[1])) {
					found_portal_id = tagsegments[1].tointeger()
					break
				}
			}
		}

		if (found_portal_id == -1 || found_portal_id >= __diffmod.PortalSystem.portal_positions.len()) {
			found_portal_id = RandomInt(0, __diffmod.PortalSystem.portal_positions.len() - 1)
		}
		
		self.Teleport(true, __diffmod.PortalSystem.portal_positions[found_portal_id], true, self.EyeAngles(), true, self.GetAbsVelocity())
	}
	else
	{
		// No bosses, sneaky spies or teleporting engis allowed! Also, tag check for special circumstances
		if (self.HasBotAttribute(65536) || self.HasMission(4) || self.HasBotAttribute(16384) || self.HasBotTag("dontportal")) return
		
		// Increment portal spawns
		__diffmod.PortalSystem.Increment()
		
		// If we have been teleported via engi, should we be at portal instead?
		if (self.InCond(5)) {
			if (__diffmod.PortalSystem.portal_engitele) {
				// spawn sound
				EmitSoundEx({
					sound_name = "mvm/mvm_tele_deliver.wav"
					channel = 6
					volume = 1.0
					sound_level = 0
					filter_type = 5
					flags = 1
				})
				return
			}
			else {
				self.RemoveCondEx(65536, true)
			}
		}

		// Do we spawn normally?
		if (__diffmod.PortalSystem.portal_id == -1) return
		
		// Teleport
		self.Teleport(true, __diffmod.PortalSystem.portal_positions[__diffmod.PortalSystem.portal_id], true, self.EyeAngles(), true, self.GetAbsVelocity())
	}
	
	// Ignore flag handler
	EntFireByHandle(self, "RunScriptCode", "self.AddBotAttribute(131072)", 0.0, null, null)
	EntFireByHandle(self, "RunScriptCode", "self.RemoveBotAttribute(131072)", 1.0, null, null)
	
	// spawn sound
	EmitSoundEx({
		sound_name = "mvm/mvm_tele_deliver.wav"
		channel = 6
		volume = 1.0
		sound_level = 0
		filter_type = 5
		flags = 1
	})
	
	// special shadows thing
	if (__diffmod.State.mapname == "mvm_shadows_b3") {
		// __diffmod.GameUtil.register_ent_func(self, "portal_spawn_bot_shadows", __diffmod.SpawnCatchers.portal_spawn_bot_shadows)
		EntFireByHandle(self, "CallScriptFunction", "diffmod_portal_spawn_bot_shadows", RandomFloat(0.5, 2.5), null, null)
	}
	else
	{
	
	// quick invincibility
	self.AddCondEx(51, 2.5, null)
	}
}

::diffmod_portal_spawn_bot_shadows <- function() {
	self.AddCondEx(5, 8, null)
	self.AddCondEx(11, 8, null)
	self.SetHealth(self.GetHealth() * 2)
	EmitSoundEx({
		sound_name = "ambient/rottenburg/rottenburg_belltower.wav"
		channel = 6
		volume = 1.0
		sound_level = 0
		filter_type = 5
		flags = 0
	})
	ClientPrint(null,3,"\x0799CCFF" + NetProps.GetPropString(self, "m_szNetname") + " \x07FBECCBhas escaped the underworld!")
}
					
::diffmod_post_spawn_bots_damageres <- function()
{
	if (self.HasBotTag("dontdoublehp_damageres")) {
		printl("DAMAGERES DETECTED!")
		__diffmod.GameUtil.SetupDamageresThinker() // check if the thinker is setup?
		local userid = NetProps.GetPropIntArray(Entities.FindByClassname(null, "tf_player_manager"), "m_iUserID", self.entindex())
		__diffmod.State.bot_dmgreductions[userid] <- [-1, -1]
	}
}

::diffmod_post_spawn_bots_mods <- function()
{
	// printl("MOD POST SPAWN")
	// "self" is the player entity here
	
	if (__diffmod.State.current_mods["HP"] > 0 && !self.HasBotTag("dontdoublehp"))
	{
		local current_maxhealth = self.GetMaxHealth()
		local current_hp_tier = __diffmod.State.current_mods["HP"]
		local hp_mult = __diffmod.ModRegistry["HP"].mod_tiers[current_hp_tier].robot_health_mult
		if (__diffmod.State.mapname == "mvm_redridge_b4b")
		{
			self.AddCustomAttribute("max health additive bonus", current_maxhealth * (hp_mult - 1), -1)
		}
		else
		{
			__diffmod.GameUtil.AddAttributeToLoadout(self, "max health additive bonus" ,current_maxhealth * (hp_mult - 1), -1)
		}
		self.SetHealth(current_maxhealth * hp_mult)
	}
	
	if (__diffmod.State.current_mods["DMG"] > 0)
	{
		local current_damage = self.GetCustomAttribute("damage bonus", 1)
		local current_dmg_tier = __diffmod.State.current_mods["DMG"]
		local dmg_mult = __diffmod.ModRegistry["DMG"].mod_tiers[current_dmg_tier].robot_damage_mult
		self.AddCustomAttribute("damage bonus", current_damage * dmg_mult, -1)
	}
	if (__diffmod.State.current_mods["SPD"] > 0)
	{
		local current_move_speed = self.GetCustomAttribute("move speed bonus", 1)
		local current_spd_tier = __diffmod.State.current_mods["SPD"]
		local spd_mult = __diffmod.ModRegistry["SPD"].mod_tiers[current_spd_tier].robot_speed_mult
		self.AddCustomAttribute("move speed bonus", current_move_speed * spd_mult, -1)
	}
	if (__diffmod.State.current_mods["INVS"] > 0)
	{
		EntFireByHandle(self, "addoutput", "rendermode 1", 0, null, null)
		EntFireByHandle(self, "alpha", "16", 0, null, null)
		for (local child = self.FirstMoveChild(); child != null; child = child.NextMovePeer()) {
			EntFireByHandle(child, "addoutput", "rendermode 1", 0, null, null)
			EntFireByHandle(child, "alpha", "16", 0, null, null)
		}
	}
	else
	{
		EntFireByHandle(self, "addoutput", "rendermode 0", 0, null, null)
		EntFireByHandle(self, "alpha", "255", 0, null, null)
		for (local child = self.FirstMoveChild(); child != null; child = child.NextMovePeer()) {
			EntFireByHandle(child, "addoutput", "rendermode 0", 0, null, null)
			EntFireByHandle(child, "alpha", "255", 0, null, null)
		}
	}
	
	if (__diffmod.State.current_mods["PRTL"] > 0)
	{	
		// __diffmod.GameUtil.register_ent_func(self, "portal_spawn_bot", __diffmod.SpawnCatchers.portal_spawn_bot)
		EntFireByHandle(self, "CallScriptFunction", "diffmod_portal_spawn_bot", 0, null, null)
	}
}

::diffmod_post_spawn_healthkit <- function()
{
	// "self" is the player entity here
	self.AddCustomAttribute("drop health pack on kill", 1, -1.0)
}

::diffmod_damageres_think <- function() {
	// for each entry in table,
	// check for attribute
	// if not, add attribute, based on hp mult
	
	foreach (userid, dummy in __diffmod.State.bot_dmgreductions) {
		local player = GetPlayerFromUserID(userid)
		
		if (player == null) {
			delete __diffmod.State.bot_dmgreductions[userid]
			continue
		}
		
		local originalreduction_dmg = player.GetCustomAttribute("dmg taken increased", 1)
		local originalreduction_regen = player.GetCustomAttribute("Health regen", 0)
		
		// this might not work for some value changes, but close enough. need to edit in popfiles if this happens
		if (__diffmod.State.bot_dmgreductions[userid][0] != originalreduction_dmg) {
			if (__diffmod.State.current_mods["HP"] == 1) {
				player.AddCustomAttribute("dmg taken increased", originalreduction_dmg * 0.5, 0)
				__diffmod.State.bot_dmgreductions[userid][0] = originalreduction_dmg * 0.5
				printl("0.5 DAMAGE REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 2) {
				player.AddCustomAttribute("dmg taken increased", originalreduction_dmg * 0.333, 0)
				__diffmod.State.bot_dmgreductions[userid][0] = originalreduction_dmg * 0.333
				printl("0.333 DAMAGE REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 3) {
				player.AddCustomAttribute("dmg taken increased", originalreduction_dmg * 0.25, 0)
				__diffmod.State.bot_dmgreductions[userid][0] = originalreduction_dmg * 0.25
				printl("0.25 DAMAGE REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 4) {
				player.AddCustomAttribute("dmg taken increased", originalreduction_dmg * 0.2, 0)
				__diffmod.State.bot_dmgreductions[userid][0] = originalreduction_dmg * 0.2
				printl("0.2 DAMAGE REDUCTION GIVEN")
			}
		}
		if (__diffmod.State.bot_dmgreductions[userid][1] != originalreduction_regen) {
			if (__diffmod.State.current_mods["HP"] == 1) {
				player.AddCustomAttribute("Health regen", originalreduction_regen * 0.5, 0)
				__diffmod.State.bot_dmgreductions[userid][1] = originalreduction_regen * 0.5
				printl("0.5 REGEN REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 2) {
				player.AddCustomAttribute("Health regen", originalreduction_regen * 0.333, 0)
				__diffmod.State.bot_dmgreductions[userid][1] = originalreduction_regen * 0.333
				printl("0.333 REGEN REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 3) {
				player.AddCustomAttribute("Health regen", originalreduction_regen * 0.25, 0)
				__diffmod.State.bot_dmgreductions[userid][1] = originalreduction_regen * 0.25
				printl("0.25 REGEN REDUCTION GIVEN")
			}
			if (__diffmod.State.current_mods["HP"] == 4) {
				player.AddCustomAttribute("Health regen", originalreduction_regen * 0.2, 0)
				__diffmod.State.bot_dmgreductions[userid][1] = originalreduction_regen * 0.2
				printl("0.2 REGEN REDUCTION GIVEN")
			}
		}
	}
	
	return -1
}

// ================================ //
// MAIN THINK
// ================================ //

::diffmod_main_think <- function() {
	// APRIL FOOLS!!!
	if (__diffmod.State.aprilfools_enabled) {
		if (Time() > __diffmod.State.pootis_next)
		{
			__diffmod.State.pootis_next = Time() + RandomFloat(0.2, 1.3)
			local heavybots = []
			for (local i = 1; i <= MaxClients().tointeger() ; i++)
			{
				local player = PlayerInstanceFromIndex(i)
				if (player == null) continue
				if (!player.IsPlayer()) continue
				if (player.IsBotOfType(1337) && player.GetPlayerClass() == 6 && player.IsAlive()) {
					heavybots.append(i)
				}
				NetProps.SetPropBool(player, "m_bForcePurgeFixedupStrings", true)
			}
			if (heavybots.len() > 0) {
				local randomHeavy = RandomInt(0, heavybots.len() - 1)
				local THEheavy = PlayerInstanceFromIndex(heavybots[randomHeavy])
				EmitSoundEx({
					sound_name = "vo/mvm/norm/heavy_mvm_needdispenser01.mp3"
					entity = THEheavy
					filter_type = 5
					sound_level = 110
					channel = 6
				})
				
				NetProps.SetPropBool(THEheavy, "m_bForcePurgeFixedupStrings", true)
				NetProps.SetPropBool(randomHeavy, "m_bForcePurgeFixedupStrings", true)
				NetProps.SetPropBool(heavybots, "m_bForcePurgeFixedupStrings", true)
			}
		}
	}
	
	// Constant clock countdown system
	if (Time() > __diffmod.State.wait_next_clock)
	{
		__diffmod.State.wait_next_clock = Time() + 1
		
		// manage other clocks
		if (__diffmod.State.start_cooldown != 0) __diffmod.State.start_cooldown -= 1
		if (__diffmod.State.vote_cooldown != 0) __diffmod.State.vote_cooldown -= 1
		if (__diffmod.State.mod_change_cooldown != 0) __diffmod.State.mod_change_cooldown -= 1
		
		// manage player hudhints
		foreach (player, hudcooldown in __diffmod.State.player_hudhints) {
			if (__diffmod.State.player_hudhints[player] <= 0) {
				__diffmod.GameUtil.HideHudHint(player)
				delete __diffmod.State.player_hudhints[player]
			}
			else
			{
				__diffmod.State.player_hudhints[player] -= 1
			}
		}

		// check round state for failure
		if (GetRoundState() == 5)
		{
			__diffmod.State.marathon_wave_failed = true
		}

	}
	
	// Tip system
	if (Time() > __diffmod.State.tip_cooldown)
	{
		__diffmod.State.tip_cooldown = Time() + RandomInt(90, 120)
		
		if (RandomInt(0, 500) == 0)
		{
			ClientPrint(null,3,"\x0799CCFFSpy\x07FBECCB: Hon hon hon! Right behind you.")
			__diffmod.GameUtil.GlobalSound("vo/mvm/norm/spy_mvm_laughshort06.mp3")
		}
		else
		{
			local tiparray = [
			"Type '/diffmod_help' for a list of diffmod-related commands",
			"Type '/diffmod_help' for a list of diffmod-related commands",
			"Type '/diffmod_help' for a list of diffmod-related commands",
			"Type '/diffmod_help' for a list of diffmod-related commands",
			"Robot got stuck in spawn? Type '/vote_reset_wave' to reset the wave",
			"Type 'cl_mvm_wave_status_visible_during_wave 1' in console to always see the top wavebar",
			"Type '/mod_current' to view all currently enabled difficulty modifiers",
			"Type '/mod_available' to view all the available difficulty modifiers for the map",
			"Currently active modifiers can be removed. Type '/mod_remove_help' for more info",
			"Want to learn how each modifier works? Type '/mod_type_help' for more info",
			"Want to learn how each modifier works? Type '/mod_type_help' for more info",
			"You can vote for maps or missions through the vanilla vote menu",
			"You can check your team composition by typing '/classcount'",
			"This server has some weapon rebalances. Check them with '/weapon_rebalances'",
			"To learn about this server's mission difficulty levels, type '/difficulty_info'",
			]
			local randTipInt = RandomInt(0, tiparray.len() - 1)
			
			local finalTip = __diffmod.Const.chat_mark + "Tip: " + tiparray[randTipInt]
			ClientPrint(null,3,finalTip)
		}
	}
	
	// Voting system
	if (__diffmod.State.in_vote_state)
	{
		if (Time() > __diffmod.State.wait_next_timer)
		{
			// counting players... and checking if the vote should end early
			local valid_playercount = 0
			for (local i = 1; i <= MaxClients().tointeger(); i++) {
				local player = PlayerInstanceFromIndex(i)

				if (player != null && !player.IsBotOfType(1337) && player.GetTeam() != 0 && player.GetTeam() != 1) valid_playercount += 1
			}
			if (__diffmod.State.voted_playerids.len() >= valid_playercount && __diffmod.State.vote_timeleft < 15) __diffmod.State.vote_timeleft = -1
			
			// actual vote handling
			if (__diffmod.State.vote_timeleft >= 0)
			{	
				__diffmod.State.wait_next_timer = Time() + 1
				__diffmod.State.vote_timeleft -= 1
				//printl("time tick")
				//printl(__diffmod.State.vote_timeleft)
			}
			else
			{
				// reset everything!
				__diffmod.State.in_vote_state = false
				__diffmod.State.vote_timeleft = 15
				__diffmod.State.voted_playerids.clear()
				
				// decide votes
				// vote success
				if (__diffmod.State.vote_y_count > __diffmod.State.vote_n_count)
				{
					__diffmod.GameUtil.GlobalSound("ui/vote_success.wav")
					EntFire("worldspawn", "RunScriptCode", @"
					__diffmod.GameUtil.vote_completion(__diffmod.State.vote_type)
					"
					, 1.5)
					
					__diffmod.State.vote_cooldown = 6
					__diffmod.State.mod_change_cooldown = 6
				}
				// vote fail
				else
				{
					__diffmod.GameUtil.GlobalSound("ui/vote_failure.wav")
					EntFire("worldspawn", "RunScriptCode", @"
					__diffmod.GameUtil.DoExplanation(`Vote Failed. Not enough players voted 'yes'`, `E86868`, 0.3, ``, false, 5)
					__diffmod.State.vote_cooldown = 30
					__diffmod.State.mod_change_cooldown = 6
					"
					, 0.5)
				}
			}
		}
		if (Time() > __diffmod.State.wait_next_hud)
		{
			__diffmod.State.wait_next_hud = Time() + 0.1
			__diffmod.State.vote_count_display_text = "Y: " + __diffmod.State.vote_y_count + "    N: " + __diffmod.State.vote_n_count
			__diffmod.GameUtil.DoExplanationSimple_1(__diffmod.State.vote_title_display_text, __diffmod.State.vote_title_color, -1, 0.3, -1, 0, 4)
			__diffmod.GameUtil.DoExplanationSimple_2("Type 'y' or 'n' in text chat to vote", "FFFF00", -1, 0.35, -1, 0, 1)
			__diffmod.GameUtil.DoExplanationSimple_3(__diffmod.State.vote_count_display_text, "FFFF00", -1, 0.4, -1, 0, 1)
		}
	}
	
	// Tank spawn catcher
	for (local tank; tank = Entities.FindByClassname(tank, "tank_boss");) {
		if (tank.GetName() == "") continue
		if (tank.GetTeam().tostring() in __diffmod.State.bot_team_blacklist) continue
		
		if (!__diffmod.State.tankspawn_delay) tank.ValidateScriptScope()
		
		local scope = tank.GetScriptScope()
		
		if (!scope) {
			if (!(tank.GetEFlags() & 1048576)) {
				tank.AddEFlags(1048576)
				EntFireByHandle(tank, "CallScriptFunction", "diffmod_post_validate_script_scope", 1, null, null)
			}
			continue
		}

		if (!("created_mod" in scope)) {
			//printl("TANK HAS SPAWNED!")
			scope.created_mod         <- true
			scope.maxHealth_mod       <- tank.GetMaxHealth()
			
			if (__diffmod.State.current_mods["HP"] > 0)
			{
				local current_hp_tier = __diffmod.State.current_mods["HP"]
				local newtankhealth = scope.maxHealth_mod * __diffmod.ModRegistry["HP"].mod_tiers[current_hp_tier].tank_health_mult
				tank.AcceptInput("SetMaxHealth", newtankhealth.tostring(), null, null)
				tank.AcceptInput("SetHealth", newtankhealth.tostring(), null, null)
			}

			if (__diffmod.State.current_mods["SPD"] > 0)
			{
				local current_spd_tier = __diffmod.State.current_mods["SPD"]
				local newtankspeed = NetProps.GetPropFloat(tank, "m_speed") * __diffmod.ModRegistry["SPD"].mod_tiers[current_spd_tier].tank_speed_mult
				tank.AcceptInput("SetSpeed", newtankspeed.tostring(), null, null)
			}
			if (__diffmod.State.current_mods["INVS"] > 0)
			{
				EntFireByHandle(tank, "addoutput", "rendermode 1", 0, tank, tank)
				EntFireByHandle(tank, "alpha", "16", 0, tank, tank)
				
				// Bomb and tracks
				for (local child = tank.FirstMoveChild(); child != null; child = child.NextMovePeer())
				{
					if (child.GetClassname() == "prop_dynamic")
					{
						if (child.GetModelName() == "models/bots/boss_bot/bomb_mechanism.mdl" || child.GetModelName() == "models/bots/boss_bot/tank_track_L.mdl" || child.GetModelName() == "models/bots/boss_bot/tank_track_R.mdl")
						{
							EntFireByHandle(child, "addoutput", "rendermode 1", 0, child, child)
							EntFireByHandle(child, "alpha", "16", 0, child, child)
						}
					}
				}
			}
		}
	}
}

__CollectGameEventCallbacks(__diffmod.Events)

IncludeScript("potato_LP")

::maps_availablemods <- {} // if including this for some reason fails
IncludeScript("maps_availablemods")

// Legacy compatibility
::__missionmodifier <- __diffmod
__missionmodifier.bot_team_blacklist_add <- __diffmod.ModSystem.bot_team_blacklist_add
__missionmodifier.modifier_blacklist_add <- __diffmod.ModSystem.modifier_blacklist_add
__missionmodifier.player_set_team_set <- __diffmod.ModSystem.player_set_team_set
__missionmodifier.modifier_portal_anomalies_remove_with_message <- function()
{
	printl("PORTAL ANOMALIES destroyed!")

	EntFire("worldspawn", "RunScriptCode", @"
	ClientPrint(null,3,`\x08AC64FAFF[PORTAL ANOMALIES HAVE BEEN DESTROYED!]`)
	ClientPrint(null,3,__diffmod.Const.modifier_tooltip)
	__diffmod.GameUtil.DoExplanation(`[PORTAL ANOMALIES HAVE BEEN DESTROYED!]`, `638BEB`, 0.3, ``, false, 10)
	__diffmod.State.vote_type = ``
	__diffmod.GameUtil.GlobalSound(`mvm/mvm_money_vanish.wav`)
	"
	, 0.1)

	__diffmod.mod_active_portal_anomalies = false
	__diffmod.PortalSystem.ClearPortals(true)
	__diffmod.GameUtil.showhint_all()
}

::__potato <- {}

// Potato scripts
// Credits to fellen for these
IncludeScript("GasNerf")
IncludeScript("yer_unnerf")
IncludeScript("temp_quicksand_fix")

::__potato.ErrorHandler <-
{
    error_table = {}

    function OnGameEvent_mvm_reset_stats(_)
    {
        __potato.ErrorHandler.error_table.clear()
    }
}
IncludeScript("potato_error_handler")
__CollectGameEventCallbacks(__potato.ErrorHandler)


// CM+ Command registration
IncludeScript("lpmvm")

if ("LPMVM" in getroottable() && LPMVM.IsAvailable) {
	LPMVM.Commands.Register(
		"sm_start_wave",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			LPMVM.Game.StartWave()
		},
		"Forces the wave to start",
		LPMVM.Admin.CHANGEMAP
	)
	LPMVM.Commands.Register(
		"sm_panic",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			LPMVM.Game.ClearRobotsAndTanks()
		},
		"Destroys all robots and tanks currently alive",
		LPMVM.Admin.CHANGEMAP
	)
	LPMVM.Commands.Register(
		"sm_jump_wave",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			local wavenum = __diffmod.MiscUtil.parse_first_arg(ctx.args, "1")
			if (__diffmod.MiscUtil.is_integer_safe(wavenum)) LPMVM.Game.JumpToWave(wavenum.tointeger())
		},
		"Changes wave to the specified wave number",
		LPMVM.Admin.CHANGEMAP
	)
	LPMVM.Commands.Register(
		"sm_get_maps",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			foreach (mapName in LPMVM.Missions.GetMaps())
			{
				ClientPrint(ctx.player, 2, mapName)
			}
		},
		"Prints map list in console",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_get_missions",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			local mapname = __diffmod.MiscUtil.parse_first_arg(ctx.args, "mvm_example")
			local missionarr = LPMVM.Missions.GetPopfiles(mapname)

			foreach (missionName in missionarr)
			{
				ClientPrint(null, 2, missionName)
			}
		},
		"Prints mission list of provided map in console",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_get_maps_null",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			foreach (mapName in LPMVM.Missions.GetMaps())
			{
				ClientPrint(null, 2, mapName)
			}
		},
		"Prints map list in console (null ver)",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_get_missions_null",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			local mapname = __diffmod.MiscUtil.parse_first_arg(ctx.args, "mvm_example")
			local missionarr = LPMVM.Missions.GetPopfiles(mapname)

			foreach (missionName in missionarr)
			{
				ClientPrint(ctx.player, 2, missionName)
			}
		},
		"Prints mission list of provided map in console (null ver)",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_load_mission",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			LPMVM.Missions.SelectPopfile(__diffmod.MiscUtil.parse_first_arg(ctx.args, ""))
		},
		"Loads the given mission",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_random_map",
		function(ctx)
		{
			if (!__diffmod.GameUtil.check_can_force_mod_ehandle(ctx.player)) return

			__diffmod.GameUtil.go_to_random_map()
		},
		"Loads a random map",
		LPMVM.Admin.CHANGEMAP
	)

	LPMVM.Commands.Register(
		"sm_vote_random_map",
		function(ctx)
		{
			if (__diffmod.GameUtil.check_spec_ehandle(ctx.player)) return
			LPMVM.Votes.YesNo(
				"Change current map to a RANDOM MAP?",
				function(vote_ctx)
				{
					if (vote_ctx.passed)
					{
						__diffmod.GameUtil.go_to_random_map(2.0)
					}
				},
				15.0
			)
		},
		"Votes to choose a random map",
		LPMVM.Admin.NONE
	)
}