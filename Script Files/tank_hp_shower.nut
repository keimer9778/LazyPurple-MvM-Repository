//Thanks to Stardustspy for the original code and Timey for making it work.
if("randomguyCallbacks" in getroottable()) return

::randomguyCallbacks <- {
	missionName = null

	function cleanup() {
		delete randomguyCallbacks
	}

	function OnGameEvent_recalculate_holidays(_) {
		if(GetRoundState() == 3) {
			if(missionName != NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")) {
				cleanup()
			}
		}
	}

	function OnGameEvent_teamplay_broadcast_audio(params) {
        local tank_audio = "Announcer.MVM_Tank_Alert_Spawn"
        local tank_audio_alt = "Announcer.MVM_Tank_Alert_Multiple"
        if(params.sound == tank_audio || params.sound == tank_audio_alt) {
           for(local tank; tank = Entities.FindByClassname(tank, "tank_boss");) {
                tank.ValidateScriptScope()
                local scope = tank.GetScriptScope()
                local health = tank.GetMaxHealth()
                local s = health.tostring()
                local len = s.len()
                if (len > 6) s = s.slice(0, len - 6) + "m"
                else if (len > 3) s = s.slice(0, len - 3) + "k"

                if(!("iTankHealthMsg" in scope)) {
                    scope.iTankHealthMsg <- 1

                    ClientPrint(null, 3, "\x0799CCFFTank deployed with " + s + " ("+health+") HP!") 
                }
            }
        }
    }
}
randomguyCallbacks.missionName = NetProps.GetPropString(Entities.FindByClassname(null, "tf_objective_resource"), "m_iszMvMPopfileName")
__CollectGameEventCallbacks(randomguyCallbacks)