// Replicates sig_mvm_yer_unnerf after it broke on the 09/12/25 update.

/*
if (Convars.GetInt("sig_mvm_yer_unnerf") == 1)
	return

if (!IsMannVsMachineMode())
	return
*/

::__potato.YERUnnerf <-
{
	// We have to store target info *before* the kill happens, as dead bots are at risk of
	//  being moved to blue (in the case of rev) or spectate.
	CYERTargetInfo = class
	{
		Handle = null
		Team = 0
		Health = 0
		Class = 0

		// This implementation is incomplete because it does not stop us from getting re-disguised as grey later.
		//static ConvertGreyDisguisesToBlue = false

		constructor(handle)
		{
			Handle = handle
			Team = handle.GetTeam()
			//if (ConvertGreyDisguisesToBlue && Team == Constants.ETFTeam.TEAM_SPECTATOR)
			//	Team = Constants.ETFTeam.TF_TEAM_BLUE
			Health = handle.GetHealth()
			Class = handle.GetPlayerClass()
		}
	}

	function OnScriptHook_OnTakeDamage(params)
	{
		// This is intentionally not a TF_BOT_TYPE test so as to match CTFKnife::PrimaryAttack().
		if (!params.const_entity.IsPlayer() || !params.const_entity.IsFakeClient())
			return

		if (!params.inflictor || !params.inflictor.IsPlayer())
			return

		if (!params.weapon)
			return

		if (params.damage_stats != Constants.ETFDmgCustom.TF_DMG_CUSTOM_BACKSTAB)
			return

		// This is intentionally not > 0 as CTFKnife::ShouldDisguiseOnBackstab() specifically checks for == 1.
		if (params.weapon.GetAttribute("disguise on backstab", 0) != 1)
			return

		NetProps.SetPropBool(params.inflictor, "m_bForcePurgeFixedupStrings", true)
		params.inflictor.ValidateScriptScope()
		local scope = params.inflictor.GetScriptScope()

		scope.RedisguiseSelfAsTargetLocal <- RedisguiseSelfAsTarget
		scope.YERTargetInfo <- CYERTargetInfo(params.const_entity)

		// Delay until the end of the tick so that PrimaryAttack() is completed before trying to re-disguise.
		EntFireByHandle(params.inflictor, "CallScriptFunction", "RedisguiseSelfAsTargetLocal", -1.0, null, null)
	}
}
__CollectGameEventCallbacks(__potato.YERUnnerf)

/*
 How the YER works in MvM:
  - CTFPlayerShared::RemoveDisguise() immediately on backstab.
    - Normally, "disguise on backstab" has no period where there is no
  - 1.5s later, apply the disguise of the killed target.
    - Indeed, in Vanilla it's actually possible to fit in one attack in this period.

  Our patch for that behaviour is simply to re-disguise immediately, as there appears
   to be no side effects that we can't undo from the previous disguise being removed.
 */
function __potato::YERUnnerf::RedisguiseSelfAsTarget()
{
	if (YERTargetInfo.Handle.IsAlive())
	{
		// Backstab failed due to ubercharge etc., so we early return.
		delete YERTargetInfo
		delete RedisguiseSelfAsTargetLocal
		return
	}
	self.AddCond(Constants.ETFCond.TF_COND_DISGUISED)

	NetProps.SetPropEntity(self, "m_Shared.m_hDisguiseTarget", YERTargetInfo.Handle)
	NetProps.SetPropInt(self, "m_Shared.m_nDisguiseTeam", YERTargetInfo.Team)
	NetProps.SetPropInt(self, "m_Shared.m_iDisguiseHealth", YERTargetInfo.Health)
	NetProps.SetPropInt(self, "m_Shared.m_nDisguiseClass", YERTargetInfo.Class)

	__potato.YERUnnerf.TeamFortress_SetSpeed(self)

	// This gets added for 0.5s whenever RemoveDisguise() is called, so we strip it in-case.
	//  That said, I'm pretty sure this cond is vestigial and doesn't trigger any behaviour.
	self.RemoveCond(Constants.ETFCond.TF_COND_DISGUISE_WEARINGOFF)

	delete YERTargetInfo
	delete RedisguiseSelfAsTargetLocal

	// Removed implementation of disguise mask, wearables and weapons since it's MvM anyway
	//  and they get properly applied 1.5s later.
	// Had issues where spawning the required edicts through VScript causes a perf warning of
	//  up to 1.5ms sometimes (which you always have to do courtesy of Romevision).
}

// CTFPlayer::TeamFortress_SetSpeed() isn't exposed to VScript but we can replicate it as
//  move speed conditions will call it, and we can then undo the side effects.
function __potato::YERUnnerf::TeamFortress_SetSpeed(player)
{
	if (player.InCond(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST))
	{
		// There's no way to retrieve the condition provider in VScript, but the only way in
		//  which TF_COND_HALLOWEEN_SPEED_BOOST is applied in normal gameplay has the player
		//   themselves as the condition provider.
		local duration = player.GetCondDuration(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST)
		player.RemoveCond(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST)
		player.AddCondEx(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST, duration, player)
	}
	else
	{
		player.AddCond(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST)
		player.RemoveCond(Constants.ETFCond.TF_COND_HALLOWEEN_SPEED_BOOST)
	}
}
