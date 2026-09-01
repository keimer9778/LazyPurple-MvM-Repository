 // folding
if(!("ConstantNamingConvention" in ROOT))
	foreach(a, b in Constants)
		foreach(k, v in b)
			ROOT[k] <- v != null ? v : 0

// folding
foreach( _class in [ "NetProps", "Entities", "EntityOutputs" ] )
    foreach( k, v in ROOT[ _class ].getclass() )
        if ( k != "IsValid" && !( k in ROOT ) )
            ROOT[ k ] <- ROOT[ _class ][ k ].bindenv( ROOT[ _class ] )

// defined for the function below
const MAX_WEAPONS = 8

// gives a player a specific weapon
::GivePlayerWeapon <- function(hPlayer, sClassname, iID)
{
	local hWeapon = CreateByClassname(sClassname)
	SetPropInt(hWeapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", iID)
	SetPropBool(hWeapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	SetPropBool(hWeapon, "m_bValidatedAttachedEntity", true)
	hWeapon.SetTeam(hPlayer.GetTeam())
	hWeapon.DispatchSpawn()

	for (local i = 0; i < MAX_WEAPONS; i++)
	{
		local hHeldWeapon = GetPropEntityArray(hPlayer, "m_hMyWeapons", i)
		if (hHeldWeapon == null)
			continue
		if (hHeldWeapon.GetSlot() != hWeapon.GetSlot())
			continue
		hHeldWeapon.Destroy()
		SetPropEntityArray(hPlayer, "m_hMyWeapons", null, i)
		break
	}

	hPlayer.Weapon_Equip(hWeapon)
	hPlayer.Weapon_Switch(hWeapon)

	return hWeapon
}

// define some gameevents
::SlickEvents <- {
	// cleanup when the map reloads (mission change, wave restart)
	function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3) delete ::SlickEvents }

	// check if the spawned player is a bot then call PostBotSpawn with the bot as the parameter (activator)
	// bot tags get applied after game events so the function is delayed at the end of the tick (the entfires purpose)
	function OnGameEvent_player_spawn(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)
		if(hPlayer.IsBotOfType(TF_BOT_TYPE))
		{
			EntFire("bignet", "RunScriptCode", "SlickEvents.PostBotSpawn(activator)", -1, hPlayer)
		}
	}

	// check if the bot has a specific tag
	function PostBotSpawn(hPlayer)
	{
		// the bot has the tag "bot_boss"
		if(hPlayer.HasBotTag("bot_boss"))
		{
			local hBot = hPlayer

			// kill all weapon entities on the bot as the only weapons needed is the given ones from the script
			local ClearWeapons = function()
			{
				local KillList = []
				for(local hEnt = hBot.FirstMoveChild(); hEnt; hEnt = hEnt.NextMovePeer())
					if(hEnt instanceof CBaseCombatWeapon)
						KillList.append(hEnt)
				foreach(hEnt in KillList)
					hEnt.Kill()
			}
			ClearWeapons()

			// give the fists
			GivePlayerWeapon(hBot, "tf_weapon_sword", 132)
			hBot.AddCustomAttribute("heal on kill", 1000, -1)

			// dummy ent to use a think function, can be done in other ways like adding the think function to the bot itself or in its think table if there is one
			// note that the dummy ent is more of a lazy solution
			local hEnt = CreateByClassname("logic_relay")

			// makes it so GetScriptScope on the ent returns its table scope instead of null
			hEnt.ValidateScriptScope()

			// defines the variable to keep track what the bots health was last
			// declaring a function afterwards will keep the local variable in that function's memory, meaning you dont have to put this varible in the entity's scope unless another entity needs to access it
			local iHealthLast = hBot.GetHealth()

			// declare the think function
			hEnt.GetScriptScope().Think <- function()
			{
				// if the bot isnt alive then we no longer need to think
				if(!hBot.IsAlive()) { if(self.IsValid()) self.Kill(); return }

				// whats the current bot health
				local iHealth = hBot.GetHealth()

				// the bot health has changed, its not equal to the last recorded amount of health
				if(iHealth != iHealthLast)
				{
					// if statements have to be ordered from least health to most health, otherwise the bot wont know how to skip a phase if enough damage is dealt at once

					// the bots health went from above 40000 to under or equal to 40000 (example: 300 -> 50)
					if(iHealthLast > 40000 && iHealth <= 40000)
					{
						// bot will not attack for 3 seconds
						hBot.AddCustomAttribute("no_attack", 1, 1.5)
						// remove current weapons
						ClearWeapons()
						// give the shotgun
						local hWeapon = GivePlayerWeapon(hBot, "tf_weapon_grenadelauncher", 1151)
						hWeapon.AddAttribute("fire rate bonus", 0.001, -1)
						hWeapon.AddAttribute("clip size upgrade atomic", 10, -1)
						hWeapon.AddAttribute("projectile spread angle penalty", 7, -1)
						hWeapon.AddAttribute("faster reload rate", 0.45, -1)
						hWeapon.AddAttribute("auto fires full clip", 1, -1)
						hWeapon.AddAttribute("auto fires when full", 1, -1)
					}
					// the bots health went from above 20000 to under or equal to 20000 (example: 300 -> 150)
					else if(iHealthLast > 20000 && iHealth <= 20000)
					{
						// remove current weapons
						hBot.AddCustomAttribute("no_attack", 1, 1.5)
						ClearWeapons()
						// give the reserve shooter
						local hWeapon = GivePlayerWeapon(hBot, "tf_weapon_cannon", 996)
                        hWeapon.AddAttribute("damage bonus", 7, -1)
						hWeapon.AddAttribute("faster reload rate", 0.1, -1)
						hWeapon.AddAttribute("fire rate bonus", 5.5, -1)
						hWeapon.AddAttribute("blast radius increased", 1.5, -1)
						hWeapon.AddAttribute("use large smoke explosion", 1, -1)
						hWeapon.AddAttribute("damage causes airblast", 1, -1)
						hWeapon.AddAttribute("hand scale", 1.4, -1)
						hWeapon.AddAttribute("Projectile speed increased", 0.8, -1)
						hWeapon.AddAttribute("grenade launcher mortar mode", 0, -1)
						EntFire("tf_gamerules","playvo","ambient/alarms/razortrain_horn1.wav", -1, -1)
						EntFire("tf_gamerules","playvo","vo/mvm/mght/demoman_mvm_m_dominationengineer03.mp3", 3, -1)
						EntFire("__fx", "Stop", null, 15)
                        local hParticle = SpawnEntityFromTable("info_particle_system", {
							targetname	= "__fx"
                            origin       = hBot.GetCenter() + Vector(0, 0, 55)
                            effect_name  = "smoke_train"
                            start_active = 1
                        })
                        hParticle.AcceptInput("SetParent", "!activator", hBot, null)
						
					}

					// redefine the variable with the new health value
					iHealthLast = iHealth
				}

				// run the think function again after x seconds have passed (-1 to be the next tick)
				return -1
			}

			// make the entity run the specified function name continously
			AddThinkToEnt(hEnt, "Think")
		}
	}
}
// make the game call the listed functions in this table that match the gameevent names
__CollectGameEventCallbacks(SlickEvents)