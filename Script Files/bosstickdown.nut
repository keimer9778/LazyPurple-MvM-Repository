::CountdownCallbacks <- {
        function OnGameEvent_recalculate_holidays(_) { if(GetRoundState() == 3)
        {
            if(ThinkEnt && ThinkEnt.IsValid())
                ThinkEnt.Kill()
            delete ::CountdownCallbacks
        }}
        ThinkEnt = Entities.CreateByClassname("logic_relay")
        iCountdownLast = -1
        hGameRules = Entities.FindByClassname(null, "tf_gamerules")
        Think = function()
        {
            local flRestartRoundTime = GetPropFloat(hGameRules, "m_flRestartRoundTime")
            if(flRestartRoundTime != -1)
            {
                local iCountdown = ceil(flRestartRoundTime - Time()).tointeger()
                if(iCountdown != iCountdownLast && iCountdown in Callbacks)
                    Callbacks[iCountdown]()
                iCountdownLast = iCountdown
            }
            else iCountdownLast = -1
        }
        Callbacks = {
            [7] = function() { EntFire("timeforthefinaleboss", "trigger") },
        }
    }
    CountdownCallbacks.ThinkEnt.ValidateScriptScope()
    CountdownCallbacks.ThinkEnt.GetScriptScope().Think <- function()
    {
        CountdownCallbacks.Think()
        return -1
    }
    AddThinkToEnt(CountdownCallbacks.ThinkEnt, "Think")