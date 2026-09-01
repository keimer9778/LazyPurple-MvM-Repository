::inter_boss <- 
{
	// CLEANUP
	Cleanup = function()
	{
		local interboss_ent = Entities.FindByName(null, "_2int")
		if (interboss_ent) interboss_ent.Kill()
		printl("inter_boss successfully deleted")
		delete ::inter_boss
	}
	OnGameEvent_recalculate_holidays = function(_) { if (GetRoundState() == 3) Cleanup() }
	OnGameEvent_mvm_wave_complete = function(_) { Cleanup() }
	
	bossbot = null
	bosspos = Vector(0,0,0)
	
	// SPAWN HANDLING
	OnGameEvent_player_spawn = function(params) {
		local player = GetPlayerFromUserID(params.userid)
		if(!IsPlayerABot(player)) {
			return
		}
		EntFireByHandle(player, "RunScriptCode", "inter_boss.spawncheck(activator)", 0, player, null)
	}
	spawncheck = function(player) {
		local bottags = {}
		player.GetAllBotTags(bottags)
		foreach(i, tag in bottags) {
			if (tag == "THEBOSS") {
				bossbot = player
			}
			if (tag == "teletoboss") {
				if (bossbot) {
					player.Teleport(true, bosspos - player.GetClassEyeHeight() + Vector(0, 0, 20), true, player.EyeAngles(), true, player.GetAbsVelocity())
					player.AddCondEx(51, 1.5, null)
				}
			}
		}
	}
}
__CollectGameEventCallbacks(inter_boss)

if (Entities.FindByName(null, "_2int") == null)
{
	local inter = SpawnEntityFromTable("info_teleport_destination", { targetname = "_2int" })
	inter.ValidateScriptScope()
	local scope = inter.GetScriptScope()
	scope.inter_think <- function() {
		if ("inter_boss" in getroottable()) {
			if (inter_boss.bossbot) {
				if (inter_boss.bossbot.IsAlive()) inter_boss.bosspos = inter_boss.bossbot.EyePosition()
			}
		}
		return -1
	}
	AddThinkToEnt(inter, "inter_think")
}