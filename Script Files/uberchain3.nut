// by Nopey https://steamcommunity.com/profiles/76561198798236144

local ROOT = getroottable()

IncludeScript("nopey_lib/nopey_lib", ROOT)
// IncludeScript("popextensions/constants", ROOT)
// IncludeScript("popextensions/botbehavior", ROOT)
// IncludeScript("NavAreaBuildPath_defer", ROOT)

foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

foreach(k, v in ::Entities.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::Entities[k].bindenv(::Entities)

if("uberchain" in ROOT) return

::MVM_CLASS_MAX                  <- 23

::uberchain <- {
	function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3) { clean()} }

	function OnGameEvent_player_spawn(params)
	{
		local hPlayer	= GetPlayerFromUserID(params.userid)
		if (hPlayer.IsFakeClient())
		{
			CreateTimer(function() {
				//local tags = {}
				//hPlayer.GetAllBotTags(tags);
				//foreach (v in tags)
				//	//+printl("tags: " + v)
				if (hPlayer.HasBotTag("bot_uberchain"))
				{
					uberchain.assign(hPlayer)
				}
			}, 0.2)
		}
		//+printl("this runs")
	}
	function OnGameEvent_player_hurt(params)
	{
		//fun.nuke()
		if (params.damageamount == 0)
			return
		local hAttacker = GetPlayerFromUserID(params.attacker)
		local hVictim = GetPlayerFromUserID(params.userid)
		if (ListOfPairs.len() > 0)
			foreach (pair in ListOfPairs)
				if (pair.isThisGuyYours(hAttacker, "attack"))
					return
			foreach (pair in ListOfPairs)
				if (pair.isThisGuyYours(hVictim, "hurt"))
					return
	}
	function OnGameEvent_player_chargedeployed(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)
		if (ListOfPairs.len() > 0)
			foreach (pair in ListOfPairs)
				if (pair.isThisGuyYours(hPlayer, "chargedeployed"))
					break
	}
	function OnGameEvent_player_death(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)

        if ( Uberchain_bSwapClassMode && hPlayer.IsFakeClient() && hPlayer.HasBotTag("bot_uberchain"))
		{
		    local tags = {}
			hPlayer.GetAllBotTags(tags);
			local found_tag = false;
		    foreach (tag in tags)
			{
			    if ( startswith(tag, "icon_") && tag.len() > 5 )
				{
                    //printl("icon tag: " + tag.slice(5))
                    deduct_icon_count(tag.slice(5))
                    found_tag = true
				}
			}

			if ( !found_tag )
			{
                deduct_icon_count("medic_jug_ubersaw")
			}
		}

		if (ListOfPairs.len() > 0)
			foreach (pair in ListOfPairs)
				if (pair.isThisGuyYours(hPlayer, "death"))
					break
	}

	function assign(hMedicBot)
	{
		//+printl("assign: " + hMedicBot)
		local MedicClass = UberChainMedic(hMedicBot)
		if (MedicOne == null)
		{
			MedicOne = MedicClass
			return
		}
		MedicTwo = MedicClass


		if (MedicOne.hOwner.HasBotTag("bot_uberchain_leader"))
			ListOfPairs.append(MedicPair( MedicOne , MedicTwo, Uberchain_bSwapClassMode, Uberchain_bAdvanced ))
		else
			ListOfPairs.append(MedicPair( MedicTwo , MedicOne, Uberchain_bSwapClassMode, Uberchain_bAdvanced ))

		//ListOfPairs[ListOfPairs.len() - 1].swap()
		MedicOne = null
		MedicTwo = null
	}


	function ChangeBotAttributes()
	{
		EntFire("point_populator_interface", "ChangeBotAttributes", "Uber1")
	}
	function ChangeBotAttributes_saw()
	{
		EntFire("point_populator_interface", "ChangeBotAttributes", "Saw1")
	}
	function list()
	{
		//+printl(MedicOne)
		//+printl(MedicTwo)
	}
	function swap( all = false)
	{
		if ( all )
			foreach ( pair in ListOfPairs)
				pair.swap()

		if (ListOfPairs.len() > 0)
		{
			ListOfPairs[0].swap()
		}

		if (ListOfPairs.len() > 1)
		{
			ListOfPairs[1].swap()
		}
	}
	function testfunc(input)
	{
		if (input == 0) ListOfPairs[0].MedicOne.hOwner.SetMission(1, true)
		else if (input == 1) ListOfPairs[0].MedicOne.hOwner.SetAttentionFocus(findRandomPlayer())
		else if (input == 2) ListOfPairs[0].MedicOne.hOwner.SetMissionTarget(findRandomPlayer())
	}



	function show()
	{
		foreach (pair in ListOfPairs)
			pair.showMember()
	}
	function showme()
	{
		//+printl(ListOfPairs.len())
	}
	function clean()
	{
		// foreach (player in findAllPlayer()) {
			// player.TerminateScriptScope()
		// }

		foreach ( pair in ListOfPairs )
		{
			pair.disband()
		}

		delete ::uberchain
	}

	a = [1, 2, 3]
	function show2()
	{
		local index = 2
		CreateTimer(function() {printl("hi")
								printl(uberchain.a[index])}, 1)
	}
	function test()
	{
		findRandomPlayer().AcceptInput("SetHUDVisibility", "1", null, null)
	}

	ListOfPairs		= []
	MedicOne		= null
	MedicTwo		= null
	EventIndex		= 1
	EventIndexOdd	= 1
	EventIndexEven	= 2

	Uberchain_bSwapClassMode	= true
	Uberchain_bAdvanced			= false

	testHandle = null
	hObjectiveResource = FindByClassname(null, "tf_objective_resource")

	function deduct_icon_count(icon_name)
	{
	    //printl("deducting this icon count:" + icon_name)

        function func(iIcon, sNames, sCounts, sFlags)
        {
            if ( GetPropStringArray(hObjectiveResource, sNames, iIcon) == icon_name )
            {
                local count = GetPropIntArray(hObjectiveResource, sCounts, iIcon) - 1
                SetPropIntArray(hObjectiveResource, sCounts, count, iIcon)
                //printl("count is now: " + count)
            }
        }

	    IterateIcons(func)

        return
	}

	function IterateIcons(func)
	{
		for(local iIcon = 0; iIcon <= MVM_CLASS_MAX; iIcon++)
		{
			local iIcon = iIcon

			local bTwo = iIcon > 11
			if(bTwo) iIcon -= 12
			local sTwo = bTwo ? "2." : "."

			local sNames = format("m_iszMannVsMachineWaveClassNames%s", sTwo)
			local sCounts = format("m_nMannVsMachineWaveClassCounts%s", sTwo)
			local sFlags = format("m_nMannVsMachineWaveClassFlags%s", sTwo)

			func(iIcon, sNames, sCounts, sFlags)
		}
	}


	// hMarker = SpawnEntityFromTable("prop_dynamic", {
			// targetname 	= "pumpk"
			// model 		= "models/props_halloween/pumpkin_01.mdl"
			// solid		= 0
			// origin		= "3100 1000 450"
		// })
	//printl("uberchain3.nut is loaded")


}
::UberChainMedic <- class
{
	hOwner = null
	hWeapon = null
	hMelee = null
	//bHasUber = false
	//bUberUsed = false
	flUberDuration = 8
	iMeleeCountTarget = 0
	HealerHealthThreshold = 0
	flUberDeployDelayDuration = 0

	function useMelee()
	{
		hOwner.ClearAllWeaponRestrictions()
		hOwner.AddWeaponRestriction(1)

		EntFireByHandle(hOwner, "$BotCommand", "switch_action Mobber", 0.1, null, null)
		// ClientPrint(null, 3, format("\x07f19e53%s\x01", format(NetProps.GetPropString(hOwner, "m_szNetname") + " is using a melee " + hOwner.GetBotId())))
	}

	function useMedigun()
	{
		hOwner.ClearAllWeaponRestrictions()
		hOwner.AddWeaponRestriction(4)

		EntFireByHandle(hOwner, "$BotCommand", "switch_action Medic", 0.1, null, null)
		// ClientPrint(null, 3, format("\x07f19e53%s\x01", format(NetProps.GetPropString(hOwner, "m_szNetname") + " is using a medigun " + hOwner.GetBotId())))
	}

	function idle()
	{
		hOwner.ClearAllWeaponRestrictions()
		hOwner.AddWeaponRestriction(1)
		EntFireByHandle(hOwner, "$BotCommand", "switch_action Idle", 0.1, null, null)
	}
	function passive()
	{
		EntFireByHandle(hOwner, "$BotCommand", "switch_action Passive", 0.1, null, null)
	}
	function medic()
	{
		EntFireByHandle(hOwner, "$BotCommand", "switch_action Medic", 0.1, null, null)
	}
	function mobber()
	{
		EntFireByHandle(hOwner, "$BotCommand", "switch_action Mobber", 0.1, null, null)
	}

	constructor(hOwner)
	{
		this.hOwner = hOwner
		this.hWeapon = GetPropEntityArray(this.hOwner, "m_hMyWeapons", 1)
		this.hMelee = GetPropEntityArray(this.hOwner, "m_hMyWeapons", 2)

		flUberDuration = 8 + hWeapon.GetAttribute("uber duration bonus", 0)
		iMeleeCountTarget = ceil( 1 / hMelee.GetAttribute("add uber charge on hit", 0.25))
		HealerHealthThreshold = hOwner.GetCustomAttribute("bot medic uber health threshold", 50)
		flUberDeployDelayDuration = hOwner.GetCustomAttribute("bot medic uber deploy delay duration", 0)
	}
}

::MedicPair <- class
{
	MedicOne		= null
	MedicTwo		= null
	MedicOneRef		= null
	MedicTwoRef		= null

	AI_Bot_MedicOne = null
	AI_Bot_MedicTwo = null
	target			= null
	bThink 			= false
	bInverse		= true

	bUberUsed = false
	iMeleeCount = 0
	//iMeleeCountTarget = 1

	Timer_swap = CreateTimer(@() {}, 0.1)
	Timer_uber = CreateTimer(@() {}, 0.1)
	Timer_heal = CreateTimer(@() {}, 0.1)
	Timer_reattach = CreateTimer(@() {}, 0.1)
	Timer_seek = CreateTimer(@() {}, 0.1)
	Timer_deploy = CreateTimer(@() {}, 0.1)


	bFirst_swap = true
	bSeek_mode 		= true
	bSwapClassMode	= true
	bAdvanced		= false
	//bSoft_swap_mode = false

	function show()
	{
		//+printl(iMeleeCount)
		//+printl(bUberUsed)
	}
	function showMember()
	{
		//+printl(MedicOne.hOwner + " " + MedicTwo.hOwner)
	}
	function findIndex()
	{
		//printl(uberchain.ListOfPairs.find(this))
		return uberchain.ListOfPairs.find(this)
	}
	function remove()
	{
		MedicOne.hOwner.RemoveCustomAttribute("max health additive bonus")
	}
	function add()
	{
		MedicOne.hOwner.AddCustomAttribute("max health additive bonus", -50, -1)
	}

	constructor(MedicOne, MedicTwo, Uberchain_bSwapClassMode, Uberchain_bAdvanced )
	{
		this.MedicOne = MedicOne
		this.MedicTwo = MedicTwo
		MedicTwoRef = MedicOne.weakref()	// starts out inversed
		MedicOneRef = MedicTwo.weakref()

		AI_Bot_MedicOne = AI_Bot2(MedicOne.hOwner)
		AI_Bot_MedicTwo = AI_Bot2(MedicTwo.hOwner)

		bUberUsed = MedicTwo.hOwner.HasBotAttribute(SPAWN_WITH_FULL_CHARGE) ? false : true
		iMeleeCount = MedicOne.hOwner.HasBotAttribute(SPAWN_WITH_FULL_CHARGE) ? MedicOne.iMeleeCountTarget : 0
		//iMeleeCountTarget = 1

		MedicOne.hOwner.ValidateScriptScope()
		MedicOne.hOwner.GetScriptScope().pair <- this
		MedicOne.hOwner.GetScriptScope().Think <- function()
		{
			return pair.Think()
		}
		AddThinkToEnt(MedicOne.hOwner, "Think")

		bSwapClassMode = Uberchain_bSwapClassMode
		bAdvanced = Uberchain_bAdvanced

		this.swap()
	}
	function swap(soft_swap = false)
	{
		bInverse = !bInverse
		local swapRef = MedicTwoRef
		MedicTwoRef = MedicOneRef
		MedicOneRef = swapRef

		if ( bSwapClassMode )
		{
			MedicOneRef.hOwner.SetPlayerClass(3)
			MedicTwoRef.hOwner.SetPlayerClass(5)
		}
		//ClientPrint(null, 3, format("\x07f19e53%s\x01", format(NetProps.GetPropString(MedicTwoRef.hOwner, "m_szNetname") + " is a medic")))
		//printl()

		local indexLocal = findIndex()
		MedicOneRef.useMelee()
		MedicTwoRef.useMedigun()

		SetPropFloat(MedicOneRef.hWeapon, "m_flChargeLevel", 1)	// it must work this way

		if (bFirst_swap)
			bFirst_swap = false
		else if ( !soft_swap )
		{
			bUberUsed = false
			iMeleeCount = 0
		}

		if ( bSwapClassMode )
		{
			MedicOneRef.hWeapon.AddAttribute("max health additive bonus", -50, -1)
			MedicOneRef.hWeapon.AddAttribute("move speed bonus", 1.333334, -1)
			MedicTwoRef.hWeapon.RemoveAttribute("max health additive bonus")
			MedicTwoRef.hWeapon.RemoveAttribute("move speed bonus")

			//MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
			//MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
		}

		//MedicTwoRef.hOwner.SetMissionTarget(MedicOneRef)

		if (bInverse)
		{
			lookat()
			heal()

			if ( bSwapClassMode )
				{}
			else
				MedicTwo.hOwner.AddCond(41)	// Non squad leader medic being healed by another medic will keep switching to another weapon so we need this to stop them from doing that

			bThink = true
			//printl("it's thinking now")
		}
		else {
			stop()

			if ( bSwapClassMode )
				{}
			else
				MedicTwo.hOwner.RemoveCond(41)

			bThink = false
		}

		local ref = this
		Timer_swap = CreateTimer( @() ref.shouldUber(), 0.4)

		// need to swap outside of constructor for this to work
		if ( bSwapClassMode )
		{
			MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
			MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
			return

			//+printl(findIndex())
			if (indexLocal == 0)
			{
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/medic/bot_medic.mdl")
			}
			else if (indexLocal == 1) {
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/soldier/bot_soldier.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/soldier/bot_soldier.mdl")
			}
			else if (indexLocal == 2) {
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/scout/bot_scout.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/scout/bot_scout.mdl")
			}
			else if (indexLocal == 3) {
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/pyro/bot_pyro.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/pyro/bot_pyro.mdl")
			}
			else if (indexLocal == 4) {
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/demoman/bot_demoman.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/demoman/bot_demoman.mdl")
			}
			else if (indexLocal == 5) {
				MedicOneRef.hOwner.SetCustomModelWithClassAnimations("models/bots/heavyweapon/bot_heavyweapon.mdl")
				MedicTwoRef.hOwner.SetCustomModelWithClassAnimations("models/bots/heavyweapon/bot_heavyweapon.mdl")
			}
		}
	}
	function uberDepleted()
	{
		bUberUsed = true
		shouldSwap()
	}
	function shouldSwap()
	{
		if (bUberUsed && (iMeleeCount >= MedicOneRef.iMeleeCountTarget))
			swap()
	}
	function shouldUber()
	{
		if (bInverse)
		{
			//ClientPrint(null, 3, format("\x07f19e53%s\x01", format(MedicOneRef.hOwner.GetHealth() + " " + MedicTwoRef.hOwner.GetHealth())))
			local checkPatient = MedicOneRef.hOwner.GetHealth() < MedicOneRef.hOwner.GetMaxHealth() * 0.5 ? true : false
			local checkHealer = MedicTwoRef.hOwner.GetHealth() < MedicTwoRef.HealerHealthThreshold ? true : false
			if (checkPatient || checkHealer)
			{
				local ref = MedicTwoRef.hOwner
				if (MedicTwoRef.flUberDeployDelayDuration > 0)
					Timer_deploy = CreateTimer(@() ref.PressAltFireButton(0.2), MedicTwoRef.flUberDeployDelayDuration)
				else
					MedicTwoRef.hOwner.PressAltFireButton(0.2)
			}
		}
	}
	function isThisGuyYours(hMedicBot, reason)
	{
		if (MedicOne.hOwner == hMedicBot || MedicTwo.hOwner == hMedicBot)
		{
			if (reason == "attack")
			{
				iMeleeCount += 1
				shouldSwap()
			}
			else if (reason == "chargedeployed")
			{
				local ref = this
				Timer_uber = CreateTimer(@() ref.uberDepleted(), MedicTwoRef.flUberDuration)


				//printl("chargedeployed")
			}
			else if (reason == "death")				// RIP bozo
			{

				uberchain.ListOfPairs.remove(findIndex())
				//uberchain.show()

				disband()
			}
			else if (reason == "hurt")
			{
				shouldUber()
			}
			return true		// Yuh Uh
		}
		else
			return false	// Nuh Uh
	}

	function disband()
	{
		try {Timer_swap.Destroy()}
		catch(e) {}
		try {Timer_uber.Destroy()}
		catch(e) {}
		try {Timer_heal.Destroy()}
		catch(e) {}
		try {Timer_reattach.Destroy()}
		catch(e) {}
		try {Timer_seek.Destroy()}
		catch(e) {}
		try {Timer_deploy.Destroy()}
		catch(e) {}


		MedicOne.hOwner.TerminateScriptScope()
		MedicOne.useMelee()
		MedicTwo.useMelee()

	}


	function lookat()
	{
		local vector = VectorAngles(MedicTwo.hOwner.EyePosition() - MedicOne.hOwner.EyePosition())
		//local ref = this.MedicOne.hOwner
		//CreateTimer(@() ref.SnapEyeAngles(vector), 0.7)

		NetProps.SetPropVector(MedicOne.hOwner, "pl.v_angle", vector + Vector())

		//NetProps.SetPropFloat(MedicOne.hWeapon, "m_flNextPrimaryAttack", 0)
		//MedicOne.hWeapon.PrimaryAttack()
	}
	function heal()
	{
		if (Timer_heal.IsValid())
			return

		MedicOne.hOwner.PressFireButton(10)
		local ref = this
		Timer_heal = CreateTimer(@() ref.heal(), 9.5)
	}
	function stop()
	{
		MedicOne.hOwner.PressFireButton(0)
		if (Timer_heal.IsValid())
			Timer_heal.Destroy()
	}
	function reattach(time = 0.1)
	{
		if (Timer_reattach.IsValid())
			return

		stop()
		local ref = this
		Timer_reattach = CreateTimer(@() ref.heal(), time)
	}

	function seek()
	{
		if (!bSeek_mode)
		{
			//ClientPrint(null, 3, format("\x07f19e53%s\x01", format("seeking" + count)))
			//count++

			//local indexLocal = findIndex()
			//CreateTimer(@() uberchain.ListOfPairs[indexLocal].MedicOneRef.hOwner.AddBotAttribute(IGNORE_ENEMIES), 0.1)

			//local ref = this.MedicOneRef.hOwner
			//CreateTimer(@() ref.AddBotAttribute(IGNORE_ENEMIES), 0.1)

			MedicTwo.hOwner.SetBehaviorFlag(1023)

			bSeek_mode = true
		}


	}
	function stop_seek()
	{
		if ( bSeek_mode )
		{
			MedicTwo.hOwner.ClearBehaviorFlag(1023)

			bSeek_mode = false
		}

	}

	count = 0
	function Think()
	{
		//local distance = (findRandomPlayer().GetOrigin() - MedicTwo.hOwner.GetOrigin()).LengthSqr()
		//ClientPrint(null, 3, format("\x07f19e53%s\x01", format("" + distance)))

		if (bThink)
		{
			local distance

			// dont stray too far from my patient
			distance = (MedicOne.hOwner.GetOrigin() - MedicTwo.hOwner.GetOrigin()).LengthSqr()
			if (distance > 250*250)
			{
				AI_Bot_MedicOne.OnUpdate()
				AI_Bot_MedicOne.UpdatePathAndMove(MedicTwo.hOwner.GetOrigin())
			}
			//MedicOne.hOwner.GetLocomotionInterface().FaceTowards(MedicTwo.hOwner.EyePosition())
			else
			{
				// now keep our patient healed
				distance = (MedicOne.hOwner.GetOrigin() - MedicTwo.hOwner.GetOrigin()).LengthSqr()
				if (GetPropEntity(MedicTwoRef.hWeapon, "m_hHealingTarget") != MedicOneRef.hOwner)
				{
					if (distance < 500*500)
					{
						// within distance, try to heal
						//ClientPrint(null, 3, format("\x07f19e53%s\x01", format("this is not my partner" + count)))
						//count++
						//printl(GetPropEntity(MedicOneRef.hWeapon, "m_hHealingTarget"))
						lookat()
						reattach()
					}
				}
			}

			if ( bSwapClassMode && !bAdvanced )
			{
				if (MedicOne.hOwner.IsImmobile())
					if (MedicOne.hOwner.GetImmobileDuration() > 15)
						this.swap(true)
			}
			else
			{
			// think for medic two
			if (true)
			{
				if (target == null)
				{
					AI_Bot_MedicTwo.OnUpdate()
					target = AI_Bot_MedicTwo.FindClosestThreat(100000000, false)
				}
				if (target)
				{
					distance = (target.GetOrigin() - MedicTwo.hOwner.GetOrigin()).LengthSqr()
					if ( distance < 5000 * 5000 && !bSwapClassMode )	// 1000000
					{
						AI_Bot_MedicTwo.OnUpdate()
						AI_Bot_MedicTwo.UpdatePathAndMove( target.GetOrigin(), true )
						target = null
						seek()
					}
					else if (distance > 500*500)
					{
						// target is too far away. Manually chase them
						AI_Bot_MedicTwo.OnUpdate()
						AI_Bot_MedicTwo.UpdatePathAndMove(target.GetOrigin())
						target = null
						seek()
				//printl("medic two is thinking")
					}
					else
					{
						//ClientPrint(null, 3, format("\x07f19e53%s\x01", format("in range" + count)))
						//count++
						if ( GetPropInt(target, "m_lifeState") != 0 )
							target = null

						stop_seek()
					}
				}
			}

			}


			if (false)
			{
			// find a target
			if (target == null)
			{
				AI_Bot_MedicTwo.OnUpdate()
				target = AI_Bot_MedicTwo.FindClosestThreat(100000000, false)
			}

			if (target)
			{
				distance = (target.GetOrigin() - MedicTwo.hOwner.GetOrigin()).LengthSqr()
				local distance2 = (target.GetOrigin() - MedicOne.hOwner.GetOrigin()).LengthSqr()
				if ( distance > 500*500 && distance2 > 300*300 )
				{
					// target is too far away. Manually chase them
					AI_Bot_MedicOne.OnUpdate()
					AI_Bot_MedicOne.UpdatePathAndMove(target.GetOrigin())
					target = null
					return -1
				}
				else
				{
					// we are in range of a target
					//ClientPrint(null, 3, format("\x07f19e53%s\x01", format("in range" + count)))
					//count++

					if ( !GetPropInt(target, "m_lifeState") == 0 )
						target = null

				}
			}
			}



			return -1
		}

		return -1
	}
}
__CollectGameEventCallbacks(uberchain)

::AI_Bot2 <- class {
	function constructor(bot) {
		this.bot       = bot
		this.scope     = bot.GetScriptScope()
		this.team      = bot.GetTeam()
		this.cur_eye_ang = bot.EyeAngles()
		this.cur_eye_pos = bot.EyePosition()
		this.cur_eye_fwd = bot.EyeAngles().Forward()
		this.locomotion = bot.GetLocomotionInterface()

		this.time = Time()

		this.path_points = []
		this.path_index = 0
		this.path_areas = {}

		this.path_recompute_time = 0.0

		//this.navdebug = false
	}

	bot       = null
	scope     = null
	team      = null
	cur_eye_ang = null
	cur_eye_pos = null
	cur_eye_fwd = null
	locomotion = null

	time = 0

	path_points = []
	path_index = 0
	path_areas = {}

	path_recompute_time = 0

	navdebug = false

	function IsAlive(player) {
		return GetPropInt(player, "m_lifeState") == 0
	}

	function IsInFieldOfView(target) {
		local tolerance = 0.5736 // cos(110/2)

		local delta = target.GetOrigin() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(target) >= tolerance)
			return true

		delta = target.GetCenter() - cur_eye_pos
		delta.Norm()
		if (cur_eye_fwd.Dot(delta) >= tolerance)
			return true

		delta = target.EyePosition() - cur_eye_pos
		delta.Norm()
		return (cur_eye_fwd.Dot(delta) >= tolerance)
	}

	function IsVisible(target) {
		if (target == null) return false
		local trace = {
			start  = bot.EyePosition(),
			end    = target.EyePosition(),
			mask   = MASK_OPAQUE,
			ignore = bot
		}
		TraceLineEx(trace)
		return !trace.hit
	}

	function IsThreatVisible(target) {
		return IsInFieldOfView(target) && IsVisible(target)
	}

	function GetThreatDistanceSqr(target) {
		return (target.GetOrigin() - bot.GetOrigin()).LengthSqr()
	}

	function FindClosestThreat(min_dist_sqr, must_be_visible = true) {
		local closestThreat = null
		local closestThreatDist = min_dist_sqr

		foreach (player in findAllPlayer(true)) {

			if (player == bot || !IsAlive(player) || player.GetTeam() == team || (must_be_visible && !IsThreatVisible(player))) continue

			local disguisedAs = player.GetDisguiseTarget()
			if (disguisedAs && disguisedAs.GetTeam() == team) continue

			local dist = GetThreatDistanceSqr(player)
			if (dist < closestThreatDist) {
				closestThreat = player
				closestThreatDist = dist
			}
		}
		return closestThreat
	}

	function OnUpdate() {
		//cur_pos     = bot.GetOrigin()
		//cur_vel     = bot.GetAbsVelocity()
		//cur_speed   = cur_vel.Length()
		cur_eye_pos = bot.EyePosition()
		cur_eye_ang = bot.EyeAngles()
		cur_eye_fwd = cur_eye_ang.Forward()

		time = Time()

		//SwitchToBestWeapon()
		//DrawDebugInfo()

		return -1
	}
	function ResetPath()
	{
		path_areas.clear()
		path_points.clear()
		path_index = null
		path_recompute_time = 0
	}
	function UpdatePathAndMove(target_pos, advanced = false)
	{
		local dist_to_target = (target_pos - bot.GetOrigin()).Length()

		if (path_recompute_time < time) {
			ResetPath()

			local pos_start = bot.GetOrigin()
			local pos_end   = target_pos

			local area_start = GetNavArea(pos_start, 128.0)
			local area_end   = GetNavArea(pos_end, 128.0)

			if (!area_start)
				area_start = GetNearestNavArea(pos_start, 128.0, false, true)
			if (!area_end)
				area_end   = GetNearestNavArea(pos_end, 128.0, false, true)

			if (!area_start || !area_end)
				return false

			// target is in their spawn room, don't bother
			if ( ( bot.GetTeam() == TF_TEAM_RED && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_BLUE ) ) ||
				 ( bot.GetTeam() == TF_TEAM_BLUE && area_end.HasAttributeTF( TF_NAV_SPAWN_ROOM_RED ) ) )
			{
				if ( GetRoundState() != GR_STATE_TEAM_WIN )
				{
					return false;
				}
			}

			if (advanced)
			{
				//+printl("IT RUNSSSSSSS")
				path_recompute_time = time + 1
				local closestArea = null;
				local functor = CTFBotPathCost(bot, 0)

				local result
				try
					result = NavAreaBuildPath(GetCTFNavAreaWrapper(area_start), GetCTFNavAreaWrapper(area_end), pos_end, functor, closestArea, 0.0, team, false)
				catch(e)
				{
					//+printl(e)
					//+printl("IT FAILLLEDDD!!!!!!!, TOO EXPENSIVE")
					return false
				}

				if ( !result )
				{
					//+printl("false: can't find a path")
					return false
				}
				else
				{
					// ConstructPathToTable(GetCTFNavAreaWrapper(area_end), path_areas)
					//printl("path_areas" + path_areas.len())
					path_areas["0"] <- true
				}
			}
			else
			{
				if (!GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, team, false, path_areas))
					return false
			}

			if (area_start != area_end && !path_areas.len())
				return false

			// Construct path_points
			else {
				if (advanced)
				{
					//local area = GetCTFNavAreaWrapper(area_end)
					local color = Vector(255,255,255)
					if (getSteamName(bot) == "Medic One")
						color = Vector(255,255,255)
					else
						color = Vector(255,255,0)
					for (local area = GetCTFNavAreaWrapper(area_end); area && area.m_parent; area = area.m_parent)
					{
						path_points.append(PopExtPathPoint(area.area, area.area.GetCenter(), area.m_parentHow))

						DebugDrawLine_vCol(area.area.GetCenter(), area.m_parent.area.GetCenter(), color, true, 2)
					}
					//printl("path_points " + path_points.len())
				}
				else
				{
					//path_points.clear()

					path_areas["area"+path_areas.len()] <- area_start
					local area = path_areas["area0"]
					local area_count = path_areas.len()

					// Initial run grabbing area center
					for (local i = 0; i < area_count && area; ++i) {
						// Don't add a point for the end area
						if (i > 0)
							path_points.append(PopExtPathPoint(area, area.GetCenter(), area.GetParentHow()))

						area = area.GetParent()
					}
					//printl("path_points " + path_points.len())
				}

				path_points.reverse()
				path_points.append(PopExtPathPoint(area_end, pos_end, 9)) // NUM_TRAVERSE_TYPES

				// Go through again and replace center with border point of next area
				local path_count = path_points.len()
				for (local i = 0; i < path_count; ++i) {
					local path_from = path_points[i]
					local path_to = (i < path_count - 1) ? path_points[i + 1] : null

					if (path_to) {
						local dir_to_from = path_to.area.ComputeDirection(path_from.area.GetCenter())
						local dir_from_to = path_from.area.ComputeDirection(path_to.area.GetCenter())

						local to_c1 = path_to.area.GetCorner(dir_to_from)
						local to_c2 = path_to.area.GetCorner(dir_to_from + 1)
						local fr_c1 = path_from.area.GetCorner(dir_from_to)
						local fr_c2 = path_from.area.GetCorner(dir_from_to + 1)

						local minarea = {}
						local maxarea = {}
						if ( (to_c1 - to_c2).Length() < (fr_c1 - fr_c2).Length() ) {
							minarea.area <- path_to.area
							minarea.c1 <- to_c1
							minarea.c2 <- to_c2

							maxarea.area <- path_from.area
							maxarea.c1 <- fr_c1
							maxarea.c2 <- fr_c2
						}
						else {
							minarea.area <- path_from.area
							minarea.c1 <- fr_c1
							minarea.c2 <- fr_c2

							maxarea.area <- path_to.area
							maxarea.c1 <- to_c1
							maxarea.c2 <- to_c2
						}

						// Get center of smaller area's edge between the two
						local vec = minarea.area.GetCenter()
						if (dir_to_from == 0 || dir_to_from == 2) { // GO_NORTH, GO_SOUTH
							vec.y = minarea.c1.y
							vec.z = minarea.c1.z
						}
						else if (dir_to_from == 1 || dir_to_from == 3) { // GO_EAST, GO_WEST
							vec.x = minarea.c1.x
							vec.z = minarea.c1.z
						}

						path_from.pos = vec;
					}
				}
			}

			// Base recompute off distance to target
			local dist = ceil(dist_to_target / 500.0)
			local mod
			if (advanced)
			{
				// Every 500hu away increase our recompute time by 1s
				mod = 1 * dist
			}
			else
			{
				// Every 500hu away increase our recompute time by 0.1s
				mod = 0.1 * dist
				if (mod > 1) mod = 1
			}

			path_recompute_time = time + mod
		}

		if (navdebug) {
			for (local i = 0; i < path_points.len(); ++i) {
				DebugDrawLine(path_points[i].pos, path_points[i].pos + Vector(0, 0, 32), 0, 0, 255, false, 0.075)
			}
			local area = path_areas["area0"]
			local area_count = path_areas.len()

			for (local i = 0; i < area_count && area; ++i) {
				local x = ((area_count - i - 0.0) / area_count) * 255.0
				area.DebugDrawFilled(0, x, 0, 50, 0.075, true, 0.0)

				area = area.GetParent()
			}
		}
		if (!path_points.len())
			return false

		if (path_index == null)
			path_index = 0

		if ((path_points[path_index].pos - bot.GetOrigin()).Length() < 64.0) {
			++path_index
			if (path_index >= path_points.len()) {
				ResetPath()
				return
			}
		}

		local point = path_points[path_index].pos;
		// uberchain.hMarker.SetAbsOrigin(point)
		//ClientPrint(null, 3, format("\x079EC34F%s\x01", point.tostring()))
		locomotion.Approach(point, 999)

		if (bot.GetOrigin().z < point.z - 18 && bot.GetAbsVelocity().Length() < 10)
		{
			locomotion.Jump()
			//+printl("needed a jump")
		}

		//local look_pos = Vector(point.x, point.y, cur_eye_pos.z);
		//if (threat != null)
		//	LookAt(look_pos, 600.0, 1500.0);
		//else
		//	LookAt(look_pos, 350.0, 600.0);

		// calc lookahead point

		// set eyeang based on lookahead
		// set loco on lookahead if no obstacles found
		// if found obstacle, modify loco
	}
}

::PopExtPathPoint <- class  {

	constructor( area, pos, how ) {

		this.area = area
		this.pos  = pos
		this.how  = how
	}

	area = null
	pos  = null
	how  = null
}
