::CONST <- getconsttable()
::ROOT <- getroottable()
::MAX_CLIENTS <- MaxClients().tointeger()

IncludeScript("armored_baron_logic.nut", getroottable())
//IncludeScript("city_extermination_tank_paths.nut", getroottable())
//IncludeScript("city_extermination_point_templates.nut", getroottable())
//IncludeScript("city_extermination_point_tags.nut", getroottable())


if (!("ConstantNamingConvention" in ROOT))
	foreach (a,b in Constants)
		foreach (k,v in b)
		{
			CONST[k] <- v != null ? v : 0
			ROOT[k] <- v != null ? v : 0
		}

foreach(k, v in ::Entities.getclass())
	if(k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::Entities[k].bindenv(::Entities)

foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

::CE <- {
    function DispatchParticleEffectOn(entity, name, attach_type = 6)
	{
		if(entity == null) return
		if(name == null)
			{ entity.AcceptInput("DispatchEffect", "ParticleEffectStop", null, null); return }
		local hParticle = CreateByClassname("trigger_particle")	
		SetPropBool(hParticle, "m_bForcePurgeFixedupStrings", true)
		hParticle.KeyValueFromString("particle_name", name)
		hParticle.KeyValueFromInt("attachment_type", attach_type)
		hParticle.KeyValueFromInt("spawnflags", 64)
		hParticle.DispatchSpawn()
		hParticle.AcceptInput("StartTouch", null, entity, entity)
		hParticle.Kill()
	}
    function ClearPlayerScope(hPlayer)
	{
		local tIgnore = {
			"self" : null,
			"__vname" : null, 
			"__vrefs" : null
		}
		hPlayer.ValidateScriptScope()
		local hScope = hPlayer.GetScriptScope()
		foreach (k,v in hScope)
		{
			if (k in tIgnore) continue
			if (typeof(v) == "instance" && v && v.IsValid())
			{
				EntFireByHandle(v, "Kill", "", -1, null, null)
			}
		}
		SetPropString(hPlayer, "m_iszScriptThinkFunction", "")
		CE.DispatchParticleEffectOn(hPlayer, null)
		hPlayer.TerminateScriptScope()
	}
    function RoundCleanup()
	{
		for (local i = 0; i < MAX_CLIENTS; i++)
		{
			local hPlayer = PlayerInstanceFromIndex(i)
			if (!hPlayer || !hPlayer.IsValid()) continue
			CE.ClearPlayerScope(hPlayer)
			hPlayer.AcceptInput("DispatchEffect", "ParticleEffectStop", hPlayer, hPlayer)
			hPlayer.SetScriptOverlayMaterial(null)
		}
    }
    function ProcessEnt(hEnt) { 
        if (!(hEnt && hEnt.IsValid() && hEnt.IsFakeClient())) return
        if (hEnt.HasBotTag("bot_baron"))
        {
            Baron.Setup(hEnt)
        }
    }
}
::CEEvents <- {
    function OnGameEvent_player_disconnect(params)
	{
		local hPlayer = GetPlayerFromUserID(params.userid)
		if (!hPlayer || !hPlayer.IsValid()) return
		CE.ClearPlayerScope(hPlayer)
	}
    function OnGameEvent_mvm_wave_failed(_)
	{
		CE.RoundCleanup()
	}
    function OnGameEvent_recalculate_holidays(_)
	{
		CE.RoundCleanup()
	}
    function OnGameEvent_player_spawn(params)
	{
		local hEntity = GetPlayerFromUserID(params.userid)
		if (!hEntity || !hEntity.IsValid()) return
		EntFireByHandle(hEntity, "RunScriptCode", "CE.ProcessEnt(self)", -1, null, null)
	}
}

__CollectGameEventCallbacks(CEEvents)