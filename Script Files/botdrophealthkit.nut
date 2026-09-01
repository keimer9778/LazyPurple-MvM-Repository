const SF_NORESPAWN = 0x40000000
const TF_POWERUP_LIFETIME = 30.0

::BotDropHealthKit <- {
	healthkit_classname = "item_healthkit_small"

	function OnGameEvent_player_death(event) {
		local bot = GetPlayerFromUserID(event.userid)
		if (!bot.IsBotOfType(Constants.EBotType.TF_BOT_TYPE)) return

		local pack = SpawnEntityFromTable(healthkit_classname, {
			origin = bot.GetOrigin()
			spawnflags = SF_NORESPAWN
		})
		pack.SetSolid(Constants.ESolidType.SOLID_BBOX)

		// Spawn pack with a random velocity.
		local velocity = Vector(RandomFloat(-1, 1), RandomFloat(-1, 1), 1.0)
		velocity.Norm()
		pack.SetAbsVelocity(velocity * 250.0)

		// Now make it bounce.
		pack.SetMoveType(Constants.EMoveType.MOVETYPE_FLYGRAVITY, Constants.EMoveCollide.MOVECOLLIDE_FLY_BOUNCE)

		// Kill pack after 30.0s.
		EntFireByHandle(pack, "Kill", "", TF_POWERUP_LIFETIME, null, null)
	}

	mvm_stats = Entities.FindByClassname(null, "tf_mann_vs_machine_stats")

	function OnGameEvent_recalculate_holidays(_) {
		if (GetRoundState() != Constants.ERoundState.GR_STATE_PREROUND) return
		if (NetProps.GetPropInt(mvm_stats, "m_iCurrentWaveIdx") != 0) return

		delete ::BotDropHealthKit
	}
}
__CollectGameEventCallbacks(BotDropHealthKit)
