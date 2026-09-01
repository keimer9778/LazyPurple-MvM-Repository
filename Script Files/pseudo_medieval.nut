printl("PSEUDOMEDIEVAL LOADED")

::MedievalCleanup <- {
	Cleanup = function() {
		if ("MedievalClientCommand" in PseudoMedieval &&
			PseudoMedieval.MedievalClientCommand &&
			PseudoMedieval.MedievalClientCommand.IsValid())
		{
			PseudoMedieval.MedievalClientCommand.Kill()
		}
		
		local medieval_logic = Entities.FindByClassname(null, "tf_logic_medieval")
		if (!medieval_logic)
		{
			SpawnEntityFromTable("tf_logic_medieval", {
			origin = "0 0 0"
			angles = "0 0 0"
			})
		}
		local gamerules = Entities.FindByClassname(null, "tf_gamerules")
		if (gamerules) NetProps.SetPropBool(gamerules, "m_bPlayingMedieval", true)
		printl("Reset back to regular medieval rules!")
			
		__CollectGameEventCallbacks(PseudoMedieval.Events)
		delete ::PseudoMedieval
		delete ::MedievalCleanup
	}
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }
}

__CollectGameEventCallbacks(MedievalCleanup)
local medieval_logic = Entities.FindByClassname(null, "tf_logic_medieval")
if (medieval_logic) medieval_logic.Kill()
local gamerules = Entities.FindByClassname(null, "tf_gamerules")
if (gamerules) NetProps.SetPropBool(gamerules, "m_bPlayingMedieval", false)

// Strip non medieval weapons

::PostPlayerSpawn <- function()
{
    // "self" is the player entity here
    self.AddCustomAttribute("drop health pack on kill", 1, -1.0)
}

::PseudoMedieval <- {
SLOT_PRIMARY   = 0
SLOT_SECONDARY = 1
SLOT_MELEE     = 2
SLOT_UTILITY   = 3
SLOT_BUILDING  = 4
SLOT_PDA       = 5
SLOT_PDA2      = 6
SLOT_COUNT     = 7

MedievalClientCommand = SpawnEntityFromTable("point_clientcommand", {targetname = "__medieval_clientcommand"})

Fullcleanup = function() {
	if ("MedievalClientCommand" in PseudoMedieval &&
		PseudoMedieval.MedievalClientCommand &&
		PseudoMedieval.MedievalClientCommand.IsValid())
	{
		PseudoMedieval.MedievalClientCommand.Kill()
	}
		
	delete PseudoMedieval.Events
	
	for (local i = 1; i <= MaxClients().tointeger(); i++) {
		local findplayer = PlayerInstanceFromIndex(i)
		if (findplayer != null && !findplayer.IsBotOfType(1337))
		{
			local ogclass = findplayer.GetPlayerClass()
			if (ogclass != 1)
			{
				PseudoMedieval.ForceChangeClass(findplayer, 1)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
			}
			else
			{
				PseudoMedieval.ForceChangeClass(findplayer, 3)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
			}
		}
	}
	
	delete ::PseudoMedieval
	delete ::MedievalCleanup
}

function GetItemInSlot(player, slot) {

	local item
	for (local i = 0; i < PseudoMedieval.SLOT_COUNT; i++) {
		local wep = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
		if ( wep == null || wep.GetSlot() != slot) continue

		item = wep
		break
	}
	return item
}
function ForceChangeClass(player, classindex = 1) {

	player.SetPlayerClass(classindex);
	NetProps.SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", classindex);
	player.ForceRegenerateAndRespawn();
}
function StripWeaponDestroy(player, slot = -1)
{
	if (slot == -1) slot = player.GetActiveWeapon().GetSlot()

	for (local i = 0; i < PseudoMedieval.SLOT_COUNT; i++)
	{
		local weapon = PseudoMedieval.GetItemInSlot(player, i);

		if (weapon == null || weapon.GetSlot() != slot) continue;

		weapon.Destroy();
		break;
	}
}
function SwitchWeaponSlot(player, slot) {
	printl("FORCED SWITCH")
	if (PseudoMedieval.MedievalClientCommand && PseudoMedieval.MedievalClientCommand.IsValid()) EntFireByHandle(PseudoMedieval.MedievalClientCommand, "Command", format("slot%d", slot + 1), -1, player, player)
}

Events = {

	function OnGameEvent_mvm_wave_failed(params) {
		for (local i = 1; i <= MaxClients().tointeger(); i++) {
			local findplayer = PlayerInstanceFromIndex(i)
			if (findplayer != null && !findplayer.IsBotOfType(1337))
			{
				local ogclass = findplayer.GetPlayerClass()
				if (ogclass != 1)
				{
					PseudoMedieval.ForceChangeClass(findplayer, 1)
					PseudoMedieval.ForceChangeClass(findplayer, ogclass)
				}
				else
				{
					PseudoMedieval.ForceChangeClass(findplayer, 3)
					PseudoMedieval.ForceChangeClass(findplayer, ogclass)
				}
			}
		}
	}

	function OnGameEvent_post_inventory_application(params) {
		local player = GetPlayerFromUserID(params.userid)
		
		if(player.GetTeam() == 2)
		{
			local childcount = 0
			for (local i = 0; i < PseudoMedieval.SLOT_COUNT; i++) {
				local wep = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)

				if (wep == null) continue

				childcount += 1
			}
			printl(childcount)

			switch (player.GetPlayerClass())
			{
				case 1: // scout
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					// only allows specific scout secondary weapons
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_lunchbox_drink"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_jar_milk"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_cleaver"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					break
				
				case 3: // soldier
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					// only allows specific secondary weapons
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_buff_item"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_wearable"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_parachute_secondary"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					break
				case 7: // pyro
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					
					// remove all pyro secondaries. lol!
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					break
				case 4: // demoman
					// only allows specific primary weapons
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY).GetClassname() != "tf_wearable"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY).GetClassname() != "tf_weapon_parachute_primary"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					
					// only allows specific secondary weapons
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_wearable_demoshield"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					break
				case 6: // heavy
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					// only allows specific secondary weapons
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_weapon_lunchbox"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					break
				case 9: // engi
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					
					// remove all engi secondaries. lol!
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
					
					// remove all pdas too
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_UTILITY)
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_BUILDING)
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PDA)
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PDA2)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					break
				
				case 5: // medic
					// remove all secondaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
					
					// only allow crossbow
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY).GetClassname() != "tf_weapon_crossbow"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
						}
					}
					
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					break
				case 2: // sniper
					// only allow bows
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_PRIMARY).GetClassname() != "tf_weapon_compound_bow"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					
					// only allows specific secondary weapons
					
					if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY))
					{
						if (NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_wearable_razorback"
						&& NetProps.GetPropEntityArray(player, "m_hMyWeapons", PseudoMedieval.SLOT_SECONDARY).GetClassname() != "tf_wearable"
						) {
							PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
							PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
						}
					}
					
					break
				case 8: // spy
					// removes all primaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_PRIMARY)
					
					// remove all secondaries
					PseudoMedieval.StripWeaponDestroy(player, PseudoMedieval.SLOT_SECONDARY)
					PseudoMedieval.SwitchWeaponSlot(player, PseudoMedieval.SLOT_MELEE)
					
					break
			}
		}
	}
	
	// Gives all players the drop health kit on kill attribute
	function OnGameEvent_player_spawn(params)
	{
		local player = GetPlayerFromUserID(params.userid)
		if (player != null && params.team != 0)
		{
			EntFireByHandle(player, "CallScriptFunction", "PostPlayerSpawn", 0, null, null)
		}
	}
}
}
__CollectGameEventCallbacks(PseudoMedieval.Events)

// For start-of-mission initialisations, i.e. changing mission
if (NetProps.GetPropInt(Entities.FindByClassname(null, "tf_objective_resource"), "m_nMannVsMachineWaveCount") == 1 || ("__diffmod" in getroottable() && __diffmod.State.medieval_force_respawn))
{
	for (local i = 1; i <= MaxClients().tointeger(); i++) {
		local findplayer = PlayerInstanceFromIndex(i)
		if (findplayer != null && !findplayer.IsBotOfType(1337))
		{
			local ogclass = findplayer.GetPlayerClass()
			if (ogclass != 1)
			{
				PseudoMedieval.ForceChangeClass(findplayer, 1)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
			}
			else
			{
				PseudoMedieval.ForceChangeClass(findplayer, 3)
				PseudoMedieval.ForceChangeClass(findplayer, ogclass)
			}
		}
	}
	
    function KillRedBuildings(classname) {
		local ent = null
		while ((ent = Entities.FindByClassname(ent, classname)) != null)
		{
			if (!ent.IsValid()) continue
			if (ent.GetTeam() == 2) ent.Kill()
		}
	}

	KillRedBuildings("obj_sentrygun")
	KillRedBuildings("obj_dispenser")
	KillRedBuildings("obj_teleporter")
	
	if ("__diffmod" in getroottable()) __diffmod.State.medieval_force_respawn = 0
}