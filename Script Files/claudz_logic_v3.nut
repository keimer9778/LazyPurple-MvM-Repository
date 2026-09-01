IncludeScript("trace_filter")
PrecacheSound("misc/null.wav")
PrecacheSound("bossbar1.wav")
PrecacheModel("models/props_hydro/barrel_crate_half.mdl")

::ROOT <- getroottable()
foreach(k, v in ::NetProps.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::NetProps[k].bindenv(::NetProps)

foreach(k, v in ::Entities.getclass())
	if (k != "IsValid" && !(k in ROOT))
		ROOT[k] <- ::Entities[k].bindenv(::Entities)


::MASK_PLAYERSOLID_BRUSHONLY <- 81931

::CzUtil <- {}
::CzUtil <- {

    ///////////////////// MATH ///////////////////

    Max = function(x, y) {
        if (x > y) {return x}
        else {return y}
    }

    Min = function(x, y) {
        if (y > x) {return x}
        else {return y}
    }

    Dist = function(ent_a, ent_b) {
        if(ent_a == null || ent_b == null) return 99999
        return (ent_a.GetOrigin() - ent_b.GetOrigin()).Length()
    }

    _degreesToRadians = PI / 180
    DegreesToRadians = function(ang) {
        return ang *_degreesToRadians
    }

    RadiansToDegrees = function(ang) {
        return ang * (180 / PI)
    }

    RotateVector = function(vec, ang) {
        ang = DegreesToRadians(ang)
        local x1 = vec.x
        local y1 = vec.y
        local x2 = (x1*cos(ang)) - (y1*sin(ang))
        local y2 = (x1*sin(ang)) + (y1*cos(ang))
        //ClientPrint(null,2,"ang " + ang.tostring() + "; cos " + cos(ang).tostring() + "; sin " + sin(ang).tostring() + "; origvec " + vec.tostring() + "; new " + Vector(x2, y2, 0).tostring())
        return Vector(x2, y2, 0)
    }

    CrossProduct = function(v1, v2)
    {
        return Vector(v1.y * v2.z - v2.y * v1.z, v1.z * v2.x - v2.z * v1.x, v1.x * v2.y - v2.x * v1.y);
    }

    // Constrains an angle into [-180, 180] range
    NormalizeAngle = function(target)
    {
        target %= 360.0
        if (target > 180.0)
            target -= 360.0
        else if (target < -180.0)
            target += 360.0
        return target
    }

    // Approaches an angle at a given speed
    ApproachAngle = function(target, value, speed)
    {
        target = NormalizeAngle(target)
        value = NormalizeAngle(value)
        local delta = NormalizeAngle(target - value)
        if (delta > speed)
            return value + speed
        else if (delta < -speed)
            return value - speed
        return value
    }

    // Converts a vector direction into angles
    VectorAngles = function(forward)
    {
        local yaw, pitch
        if (forward.y == 0.0 && forward.x == 0.0)
        {
            yaw = 0.0
            if (forward.z > 0.0)
                pitch = 270.0
            else
                pitch = 90.0
        }
        else
        {
            yaw = (atan2(forward.y, forward.x) * 180.0 / PI)
            if (yaw < 0.0)
                yaw += 360.0
            pitch = (atan2(-forward.z, forward.Length2D()) * 180.0 / PI)
            if (pitch < 0.0)
                pitch += 360.0
        }

        return QAngle(pitch, yaw, 0.0)
    }

    ///////////////////// EVENT CALLBACKS ///////////////////

    Players = {}
    PlayerSpawn = function(player)
    {
        player.ValidateScriptScope()
        local userid = NetProps.GetPropString(player, "m_szNetworkIDString")
        Players[userid] <- player
        player.GetScriptScope().lastBeamDmg <- Time()
    }
    OnGameEvent_player_disconnect = function(params)
    {
        if(params.networkid != "BOT")
        {
            try{
                delete Players[params.networkid]
            }catch (exception) {
            }
        }
    }
    OnGameEvent_player_spawn = function(params)
    {
        local player = GetPlayerFromUserID(params.userid);
        player.ValidateScriptScope()
        if (player != null && player.GetTeam() == 2)
        {
            PlayerSpawn(player)
        }
    }

    CleanupPlayer = function(player) {
        player.ValidateScriptScope()
        local scope = player.GetScriptScope()

        local ents = ["turnHelper"]
        foreach (ent in ents) {
            try {
                if(scope != null && scope.rawin(ent)) {
                    if(scope[ent].IsValid()) EntFireByHandle(scope[ent], "kill", null, 0, null, null)
                    scope.rawdelete(ent)
                }
            } catch (e) {
            }
        }
    }

    OnGameEvent_recalculate_holidays = function(_) {
        if (GetRoundState() == 3) {
            for (local i = 1, player; i <= MaxClients().tointeger(); i++)
            {
                if (player = PlayerInstanceFromIndex(i), player)
                {
                    CleanupPlayer(player)
                }
            }
            //delete ::CzUtil
        }
    }

    OnGameEvent_player_death = function(params) {
        local player = GetPlayerFromUserID(params.userid);
        CleanupPlayer(player)
    }

    Objects ={}
    OnGameEvent_player_builtobject = function(params)
    {
        if(!params.rawin("userid")) return
        local player = GetPlayerFromUserID(params.userid);
        if (player==null || player.GetTeam() != 2) return
        Objects[params.index] <- EntIndexToHScript(params.index)
        //ClientPrint(player, 3, "built " + EntIndexToHScript(params.index).tostring())
    }
    OnGameEvent_object_destroyed = function(params)
    {
        if(!params.rawin("userid")) return
        local player = GetPlayerFromUserID(params.userid);
        if (player==null || player.GetTeam() != 2) return
        Objects[params.index] <- null
        //ClientPrint(player, 3, "destroyed " + EntIndexToHScript(params.index).tostring())

    }
    OnGameEvent_object_detonated = function(params)
    {
        if(!params.rawin("userid")) return
        local player = GetPlayerFromUserID(params.userid);
        if (player==null || player.GetTeam() != 2) return
        Objects[params.index] <- null
        //ClientPrint(player, 3, "detonated " + EntIndexToHScript(params.index).tostring())
    }

    ///////////////////// UTILITY ///////////////////

    IsPlayerAlive = function(player)
    {
        // lifeState corresponds to the following values:
        // 0 - alive
        // 1 - dying (probably unused)
        // 2 - dead
        // 3 - respawnable (spectating)
        return player != null && player.IsValid() && NetProps.GetPropInt(player, "m_lifeState") == 0;
    }

    IsPlayerLOSofMe = function(me, player, ignore = null, seeThroughNpc = false)
    {
        local startPt = me.GetOrigin() + Vector(0,0,80)
        local endPt = player.GetOrigin() + Vector(0,0,80)
        local ignorethis = ignore == null ? me : ignore
        // run a trace from the bot to the position of the player
        // if the trace hits something that blocks los, that means the player is not los
        // only if the trace doesnt hit anything or it hits the player, return true
        local iMask = seeThroughNpc == false ? 33570881 : 16449

        local m_trace = { start = startPt, end = endPt, ignore = ignorethis , mask = iMask};
        TraceLineEx(m_trace);

        if (!m_trace.hit || !m_trace.rawin("enthit") || m_trace.enthit == player ) //|| m_trace.enthit.GetClassname() == "worldspawn"
        {
            return true;
        }
        return false;
    }

    IsPointLOSofMe = function(me, location, ignore = null, seeThroughNpc = true, tolerance = 200)
    {
        local startPt = me.GetOrigin() + Vector(0,0,80)
        local endPt = location
        local ignorethis = ignore == null ? me : ignore
        // run a trace from the bot to the position
        // if the trace hits something that blocks los, that means the point is not los
        // only if the trace doesnt hit anything, return true
        local iMask = seeThroughNpc == false ? 33570881 : 16449

        local m_trace = { start = startPt, end = endPt, ignore = ignorethis , mask = iMask};
        TraceLineEx(m_trace);

        if (!m_trace.hit || !m_trace.rawin("enthit") ) //|| m_trace.enthit.GetClassname() == "worldspawn"
        {
            return true;
        } else if ((m_trace.pos - location).Length() < tolerance) {
            return true;
        }
        return false;
    }

    MASK_VISIBLE_AND_NPCS =  33579137

    // uses ficool's vscript_trace_filter library
    GetPlayerLookingAtPos = function(player, range = 1000)
    {
        local trace =
        {
            start = player.EyePosition(),
            end = player.EyePosition() + player.EyeAngles().Forward() * range,
            ignore = player,
            mask = 1107296257, // CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_HITBOX
            filter = function(entity)
            {
                if (entity.IsPlayer() || entity.GetClassname().find("obj_")!= null)
                {
                    // if entity is not on player's team, stop
                    if (entity.GetTeam() != player.GetTeam())
                        return TRACE_STOP;
                    // entity is not on enemy team, continue but don't accept hit
                    else
                        return TRACE_CONTINUE;
                }
                return TRACE_STOP;
            }
        };
        TraceLineFilter(trace);
        return trace.endpos

    }

    // uses ficool's vscript_trace_filter library
    GetPlayerTarget = function(player, range = 1000)
    {
        local trace =
        {
            start = player.EyePosition(),
            end = player.EyePosition() + player.EyeAngles().Forward() * range,
            ignore = player,
            mask = 1107296257, // CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_HITBOX
            filter = function(entity)
            {
                if (entity.IsPlayer() || entity.GetClassname().find("obj_")!= null)
                {
                    // if entity is not on player's team, stop
                    if (entity.GetTeam() != player.GetTeam())
                        return TRACE_STOP;
                    // entity is not on enemy team, continue but don't accept hit
                    else
                        return TRACE_CONTINUE;
                }
                return TRACE_CONTINUE;
            }
        };
        TraceLineFilter(trace);
        if(trace.hit && (trace.enthit.IsPlayer() || trace.enthit.GetClassname().find("obj_")!= null))

            return trace.enthit
        else
            return null
        // local startPt = player.EyePosition();
        // local endPt = startPt + player.EyeAngles().Forward().Scale(range);

        // local m_trace = { start = startPt, end = endPt, ignore = player , mask = 16449};
        // TraceLineEx(m_trace);

        // if (!m_trace.hit || m_trace.enthit == null || m_trace.enthit == player)
        //     return null;

        // if (m_trace.enthit.GetClassname() == "worldspawn")
        //     return null;

        // return m_trace.enthit;
    }

    // uses ficool's vscript_trace_filter library
    GetPlayerTraceHittable = function(player, range = 9999) {
        local trace =
        {
            start = player.EyePosition(),
            end = player.EyePosition() + player.EyeAngles().Forward() * range,
            ignore = player,
            mask = -1, //33570881,
            filter = function(entity)
            {
                if (entity.GetClassname() == "base_boss")
                    return TRACE_OK_CONTINUE;
                else if(entity.GetClassname() == "player")
                    return TRACE_OK_CONTINUE;
                else if(entity.GetClassname().find("obj_")!= null)
                    return TRACE_OK_CONTINUE;

                else
                    return TRACE_CONTINUE;

                //return TRACE_STOP;
            }
        };

        TraceLineGather(trace);

        if (trace.hits.len() > 0)
        {
            return trace.hits;
            // foreach (i, hit in trace.hits)
            // {
            //     hit.enthit ...
            // }
        }
        else
        { // no hits
            return null
        }
    }

    GetCanHitTargetGround = function(player, target, range = 9999) {
        //33570827 MASK_SOLID
        //16449 MASK_BLOCKLOS
        local startPt = player.GetOrigin() + Vector(0,0,5)
        // local diff = target.GetOrigin() - player.GetOrigin()
        // diff.Norm()
        // local endPt = startPt + diff*range
        local endPt = target.GetOrigin() + Vector(0,0,5)

        local m_trace = { start = startPt, end = endPt, ignore = player , mask = 16449};
        TraceLineEx(m_trace);
        //ClientPrint(null,3,"traced " + m_trace.enthit.tostring())

        if (!m_trace.hit || m_trace.enthit == null || m_trace.enthit == player)
            return true;

        if (m_trace.enthit.GetClassname() == "worldspawn")
            return false;

        return m_trace.enthit == target;
    }

    IsInSolid = function(pos, _ignore = null) {
        local startPt = pos + Vector(0,0,-1);
        local endPt = pos + Vector(0,0,1);

        local m_trace = { start = startPt, end = endPt, ignore = _ignore , mask = MASK_PLAYERSOLID_BRUSHONLY};
        TraceLineEx(m_trace);
        if(!m_trace.hit || m_trace.enthit == null)
            return false
        return true
    }

    IsPlayerCritBoosted = function(player)
    { // excludes conds that wont happen during the mission like mannpower and wheel of fate
        if(player.GetClassname()!= "player" || !player.InCond) return false
        return player.InCond(Constants.ETFCond.TF_COND_CRITBOOSTED) || player.InCond(Constants.ETFCond.TF_COND_CRITBOOSTED_USER_BUFF) || player.InCond(Constants.ETFCond.TF_COND_CRITBOOSTED_ON_KILL) || player.InCond(Constants.ETFCond.TF_COND_CRITBOOSTED_RAGE_BUFF)
    }

    IsPlayerMiniCritBoosted = function(player)
    {
        if(player.GetClassname()!= "player" || !player.InCond) return false
        return player.InCond(Constants.ETFCond.TF_COND_ENERGY_BUFF) || player.InCond(Constants.ETFCond.TF_COND_NOHEALINGDAMAGEBUFF) || player.InCond(Constants.ETFCond.TF_COND_OFFENSEBUFF)
    }

    IsPlayerDisguisedSpy = function(player)
    {
        if(player.GetClassname()!= "player" || !CzUtil.IsPlayerAlive(player) || !(player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_SPY)) return false
        if(player.InCond(Constants.ETFCond.TF_COND_URINE) || player.InCond(Constants.ETFCond.TF_COND_BLEEDING)|| player.InCond(Constants.ETFCond.TF_COND_BURNING)) return false
        if(player.InCond(Constants.ETFCond.TF_COND_STEALTHED) || player.InCond(Constants.ETFCond.TF_COND_FEIGN_DEATH)) return true
        if(player.GetDisguiseTeam() != 3) return false
        return player.InCond(Constants.ETFCond.TF_COND_DISGUISING) || player.InCond(Constants.ETFCond.TF_COND_DISGUISED)
    }

    IsPlayerUbered = function(player)
    {
        if(player.GetClassname()!= "player" || !CzUtil.IsPlayerAlive(player)) return false
        if(player.InCond(Constants.ETFCond.TF_COND_INVULNERABLE) || player.InCond(Constants.ETFCond.TF_COND_INVULNERABLE_USER_BUFF) || player.InCond(Constants.ETFCond.TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED)|| player.InCond(Constants.ETFCond.TF_COND_INVULNERABLE_CARD_EFFECT))
            return true
        else
            return false
    }

    EmitFx = function(ent, sound, vol = 1, snd_lvl = 0.5) {
        EmitSoundEx({
            sound_name = sound,
            channel = 6,
            filter = 5,
            origin = ent.GetOrigin(),
            entity = ent,
            volume = vol,
            sound_level = snd_lvl
        })
    }

    Tracking = {}
    AddTracking = function(name, handle)
    {
        Tracking[name] <- handle
    }
    RemoveTracking = function(name)
    {
        if(name in Tracking) {
            delete Tracking.name
        }
    }
    GetTracking = function(name)
    {
        if(Tracking.rawin(name)) {
            return Tracking[name]
        } else {
            return null
        }
    }
      /**
     * Returns the position on ground below from the entity's origin.
     * Modified from:
     * https://github.com/L4D2Scripters/vslib
     */
    GetLocationBelowPos = function(pos)
    {
        local startPt = pos;
        local endPt = startPt + Vector(0, 0, -99999);
        //MASK_PLAYERSOLID_BRUSHONLY 81931
        //(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE)
        //everything normally solid for player movement, except monsters (world+brush only)
        local m_trace = { start = startPt, end = endPt, mask = 81931 };
        TraceLineEx(m_trace);

        if (!m_trace.hit)
            return;

        return m_trace.pos;
    }
      /**
     * Returns the position on ground below from the entity's origin.
     * Modified from:
     * https://github.com/L4D2Scripters/vslib
     */
    GetLocationBelow = function(player)
    {
        local startPt = player.GetOrigin();
        local endPt = startPt + Vector(0, 0, -99999);
        //MASK_PLAYERSOLID_BRUSHONLY 81931
        //(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE)
        //everything normally solid for player movement, except monsters (world+brush only)
        local m_trace = { start = startPt, end = endPt, ignore = player, mask = 81931 };
        TraceLineEx(m_trace);

        if (!m_trace.hit)
            return;

        return m_trace.pos;
    }

    GetLocationAbove = function(player)
    {
        local startPt = player.GetOrigin();
        local endPt = startPt + Vector(0, 0, 99999);
        //MASK_PLAYERSOLID_BRUSHONLY 81931
        //(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE)
        //everything normally solid for player movement, except monsters (world+brush only)
        local m_trace = { start = startPt, end = endPt, ignore = player, mask = 81931 };
        TraceLineEx(m_trace);

        if (!m_trace.hit)
            return;

        return m_trace.pos;
    }

    GetClosestTarget = function(me, range, team = 2, ignore = null)
    {
        local closestEnt = null
        local closestDist = 99999
        foreach (k, entity in Players)
        {
            if(IsPlayerAlive(entity) && entity.GetTeam() == team && !IsPlayerDisguisedSpy(entity)) { // && IsPlayerLOSofMe(me,entity,ignore)
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist < closestDist && dist < range) {
                    closestDist = dist
                    closestEnt = entity
                }
            }
        }
        for (local entity; entity = Entities.FindByClassnameWithin(entity, "obj_sentrygun", me.GetOrigin(), range);)
        {
            if(IsPlayerAlive(entity) && entity.GetTeam() == team ) {
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist < closestDist) {
                    closestDist = dist
                    closestEnt = entity
                }
            }
        }

        return closestEnt
    }

    GetClosestTargetLOS = function(me, range, team = 2, ignore = null, seeThroughNpc = false, ignoreSentries = false)
    {
        local closestEnt = null
        local closestDist = 99999
        foreach (k, entity in Players)
        {
            if(IsPlayerAlive(entity) && entity.GetTeam() == team && !IsPlayerDisguisedSpy(entity) && IsPlayerLOSofMe(me,entity,ignore,seeThroughNpc)) { //
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist < closestDist && dist < range) {
                    closestDist = dist
                    closestEnt = entity
                }
            }
        }
        if(ignoreSentries) return closestEnt

        for (local entity; entity = Entities.FindByClassnameWithin(entity, "obj_sentrygun", me.GetOrigin(), range);)
        {
            if(entity.GetTeam() == team && IsPlayerAlive(entity) && IsPlayerLOSofMe(me,entity,ignore,seeThroughNpc)) {
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist < closestDist) {
                    closestDist = dist
                    closestEnt = entity
                }
            }
        }

        return closestEnt
    }

    GetFurthestTargetLOS = function(me, range, team = 2, ignore = null, seeThroughNpc = false, ignoreSentries = false)
    {
        local furthestEnt = null
        local furthestDist = 0
        foreach (k, entity in Players)
        {
            if(IsPlayerAlive(entity) && entity.GetTeam() == team && !IsPlayerDisguisedSpy(entity) && IsPlayerLOSofMe(me,entity,ignore,seeThroughNpc)) { //
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist > furthestDist && dist < range) {
                    furthestDist = dist
                    furthestEnt = entity
                }
            }
        }
        if (ignoreSentries) return furthestEnt

        for (local entity; entity = Entities.FindByClassnameWithin(entity, "obj_sentrygun", me.GetOrigin(), range);)
        {
            if(entity.GetTeam() == team && IsPlayerAlive(entity) && IsPlayerLOSofMe(me,entity,ignore,seeThroughNpc)) {
                local dist = (entity.GetOrigin()-me.GetOrigin()).Length()
                if(dist > furthestDist) {
                    furthestDist = dist
                    furthestEnt = entity
                }
            }
        }

        return furthestEnt
    }

    //borrowing from pop extensions
    PrintTable = function(table, printlevel = 2) {
        if (table == null) return;

        DoPrintTable(table, 0, printlevel)
    }

    DoPrintTable = function(table, indent, printlevel) {
        local line = ""
        for (local i = 0; i < indent; i++) {
            line += " "
        }
        line += typeof table == "array" ? "[" : "{";

        ClientPrint(null, printlevel, line)

        indent += 2
        foreach(k, v in table) {
            line = ""
            for (local i = 0; i < indent; i++) {
                line += " "
            }
            line += k.tostring()
            line += " = "

            if (typeof v == "table" || typeof v == "array") {
                ClientPrint(null, printlevel, line)
                DoPrintTable(v, indent, printlevel)
            }
            else {
                try {
                    line += v.tostring()
                }
                catch (e) {
                    line += typeof v
                }

                ClientPrint(null, printlevel, line)
            }
        }
        indent -= 2

        line = ""
        for (local i = 0; i < indent; i++) {
            line += " "
        }
        line += typeof table == "array" ? "]" : "}";

        ClientPrint(null, printlevel, line)
    }

    CreateGameTextUpper = function(msg, hold, color, color2) {
        local textent = SpawnEntityFromTable("game_text", {
            "origin": "1984 1984 99999"
            "targetname": "upper_text"
            "message": msg
            "x": "-1"
            "y": "0.4"
            "spawnflags": "1"
            "effect": "2"
            "channel": "2"
            "color": color
            "color2": color2
            "fadein": "0.2"
            "fxtime": "0.3"
            "fadeout": "1"
            "holdtime": hold
        })
        EntFireByHandle(textent,"Display", null, 0.1, null, null)
        EntFireByHandle(textent,"kill", null, 6, null, null)
    }
    CreateGameTextUpperFast = function(msg, hold, color, color2) {
        local textent = SpawnEntityFromTable("game_text", {
            "origin": "1984 1984 99999"
            "targetname": "upper_text"
            "message": msg
            "x": "-1"
            "y": "0.4"
            "spawnflags": "1"
            "effect": "2"
            "channel": "2"
            "color": color
            "color2": color2
            "fadein": "0.1"
            "fxtime": "0.01"
            "fadeout": "1"
            "holdtime": hold
        })
        EntFireByHandle(textent,"Display", null, 0.1, null, null)
        EntFireByHandle(textent,"kill", null, 6, null, null)
    }
    CreateGameTextSuperFast = function(msg, hold, color, color2) {
        local textent = SpawnEntityFromTable("game_text", {
            "origin": "1984 1984 99999"
            "targetname": "upper_text"
            "message": msg
            "x": "-1"
            "y": "0.4"
            "spawnflags": "1"
            "effect": "2"
            "channel": "2"
            "color": color
            "color2": color2
            "fadein": "0.01"
            "fxtime": "0"
            "fadeout": "1"
            "holdtime": hold
        })
        EntFireByHandle(textent,"Display", null, 0.1, null, null)
        EntFireByHandle(textent,"kill", null, 6, null, null)
    }
    CreateGameTextLower = function(msg, hold, color) {
        local textent = SpawnEntityFromTable("game_text", {
            "origin": "1984 1984 99999"
            "targetname": "text_lower"
            "message": msg
            "x": "-1"
            "y": "0.45"
            "channel": "1"
            "spawnflags": "1"
            "color": color
            "fadein": "0.25"
            "fadeout": "1"
            "holdtime": hold
        })
        EntFireByHandle(textent,"Display", null, 0.1, null, null)
        EntFireByHandle(textent,"kill", null, 6, null, null)
    }
    CreateGameTextLowerSlow = function(msg, hold, color, color2) {
        local textent = SpawnEntityFromTable("game_text", {
            "origin": "1984 1984 99999"
            "targetname": "text_lower"
            "message": msg
            "x": "-1"
            "y": "0.45"
            "spawnflags": "1"
            "effect": "2"
            "channel": "1"
            "color": color
            "color2": color2
            "fadein": "0.2"
            "fxtime": "0.3"
            "fadeout": "1"
            "holdtime": hold
        })
        EntFireByHandle(textent,"Display", null, 0.1, null, null)
        EntFireByHandle(textent,"kill", null, 6, null, null)
    }
    // CreateGameTextEffect = function(msg, hold, color, color2) {
    //     local textent = SpawnEntityFromTable("game_text", {
    //         "origin": "1984 1984 99999"
    //         "targetname": "upper_text"
    //         "message": msg
    //         "x": "-1"
    //         "y": "0.4"
    //         "spawnflags": "1"
    //         "effect": "2"
    //         "channel": "2"
    //         "color": color
    //         "color2": color2
    //         "fadein": "0.01"
    //         "fxtime": "0"
    //         "fadeout": "1"
    //         "holdtime": hold
    //     })
    //     EntFireByHandle(textent,"Display", null, 0.1, null, null)
    //     EntFireByHandle(textent,"kill", null, 6, null, null)
    // }

    ShowAnnotationToPlayer = function(player, msg, lifetime, location, target = null, effect = false, sound = "misc/null.wav") {
        local params = {
            id = 0 // not sure if this matters
            text = msg
            lifetime = lifetime
            worldPosX = location.x
            worldPosY = location.y
            worldPosZ = location.z
            play_sound = sound
            show_distance = false
            show_effect = effect
        }
        if(player != null) {
            params.visibilityBitfield <- (1 << player.entindex())
        }
        if(target != null) {
            if(typeof target == "string") {
                target = Entities.FindByName(null, target)
            }
            if(target != null) params.follow_entindex <- target.entindex()
        }

        SendGlobalGameEvent("show_annotation", params)
    }

    SwitchMedsOffMedigun = function() {
        for (local i = 1, player; i <= MaxClients().tointeger(); i++)
        {
            if (player = PlayerInstanceFromIndex(i), player && player.GetTeam() == 2 && player.GetPlayerClass() == Constants.ETFClass.TF_CLASS_MEDIC)
            {
                for (local i = 0; i < 8; i++)
                {
                    local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)
                    if (weapon == null || !weapon.IsMeleeWeapon())
                        continue
                    player.Weapon_Switch(weapon)
                    break
                }
            }
        }
    }

    GetClosestPlayersToBot = function(bot, numOfPlayers = 4, team = 2) {
        function sortDist(playerA, playerB) {
            local distA = Dist(bot, playerA)
            local distB = Dist(bot, playerB)
            if (distA > distB) return playerA
            else return -1
        }

        // closestPlayers keeps tracks of the x number of closest players, sorted from closest to furthest
        local closestPlayers = []
        for (local player; player = FindByClassname(player, "player"); )
        {
            if(player.GetTeam()!=team || !IsPlayerLOSofMe(bot, player) || !IsPlayerAlive(player)) continue;

            //if length of closestPlayers has not reached x number of players, just append to list
            if (closestPlayers.len() <= numOfPlayers) {
                closestPlayers.append(player)
            }
            // if new player is closer than the furthest player in the closesetPlayers array
            else
            {
                local furthest = closestPlayers[closestPlayers.len()-1]
                if (Dist(player, bot) < Dist(furthest,bot)){
                    // pop the old furthest player
                    closesetPlayers.pop()
                    // append the new player
                    closestPlayers.append(player)
                }
            }

            closestPlayers.sort(sortDist)
        }

        return closestPlayers
    }
}

__CollectGameEventCallbacks(CzUtil)

// spoof a player spawn when the wave initializes
for (local i = 1, player; i <= MaxClients().tointeger(); i++)
{
    if (player = PlayerInstanceFromIndex(i), player && player.GetTeam() == 2)
        CzUtil.PlayerSpawn(player)
}


CzUtil.RemoveThink <- function(ent) {
    NetProps.SetPropString(ent, "m_iszScriptThinkFunction", "")
}

CzUtil.PrintWearables <- function() {
    for (local ent; ent = Entities.FindByClassname(ent, "tf_wearable*"); )
    {
        ClientPrint(null, 2, "wearable: modelindex " + NetProps.GetPropInt(ent, "m_nModelIndex"))
        ClientPrint(null, 2, ent.tostring() + " " + ent.GetModelName())
    }

    // for (local ent; ent = Entities.FindByClassname(ent, "instanced_scripted_scene*"); )
    // {
    //     ClientPrint(null, 2, "instanced_scripted_scene: SceneFile " + NetProps.GetPropString(ent, "m_iszSceneFile"))
    // }
}

///////////////////// SPAWNING HELPERS ///////////////////
//-204 -1411 -890 sm_ent_fire tf_gamerules runscriptcode "CzUtil.SpawnAtCoord(`-204 -1411 -880`,`testent`)"
CzUtil.SpawnAtCoord <- function(_origin, templateName, _angles = null) {
    if(_origin == null) return
    local params = {
        origin      = _origin
    }
    if(_angles != null) params.angles <- _angles

    local target = SpawnEntityFromTable("info_target", params)

    EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0, target)
    EntFire("!activator", "kill", null, 0.2, target)
}

CzUtil.GetGroundAngle <- function(location) {
    local setAngle = QAngle(0,0,0)

    local v1 = setAngle.Up() // v1 is the up direction of the ent's starting angles. can only get 0,0,0 to work for some reason

    local startPt = location + Vector(0,0,1);
    local endPt = startPt + Vector(0, 0, -99999);
    //MASK_PLAYERSOLID_BRUSHONLY 81931
    //(CONTENTS_SOLID|CONTENTS_MOVEABLE|CONTENTS_WINDOW|CONTENTS_PLAYERCLIP|CONTENTS_GRATE)
    //everything normally solid for player movement, except monsters (world+brush only)
    local m_trace = { start = startPt, end = endPt, ignore = null, mask = 81931 };
    TraceLineEx(m_trace);

    local normal = m_trace.plane_normal

    // find the quaternion representing the rotation from the ent's current Up vector to the surface normal
    // https://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another
    local _q = CzUtil.CrossProduct(v1, normal) // x,y,z of the quat is the axis of the rotation. here it is perpendicular to the two vectors via cross product
    local _w = 1 + v1.Dot(normal) // w of the quat is the scale of the rotation, basically related to the degrees of th rotation
    local q_rot = Quaternion(_q.x, _q.y, _q.z, _w)
    q_rot.Norm()

    // apply q rotation to starting quat
    local start_q = Quaternion(0,0,0,0)
    start_q.SetPitchYawRoll(setAngle.x, setAngle.y, setAngle.z)
    // presumably SetPitchYawRoll uses https://github.com/ValveSoftware/source-sdk-2013/blob/fd413c5fc7d0b005747b05d8d6a31e7cc56ad294/src/mathlib/mathlib_base.cpp#L2063
    // which takes a qangle in degrees

    local QuatMult = function(q1,q) {
        local x = q1.x
        local y = q1.y
        local z = q1.z
        local w = q1.w
        return Quaternion(w * q.x  +  x * q.w  +  y * q.z  -  z * q.y,
                        w * q.y  -  x * q.z  +  y * q.w  +  z * q.x,
                        w * q.z  +  x * q.y  -  y * q.x  +  z * q.w,
                        w * q.w  -  x * q.x  -  y * q.y  -  z * q.z);
    }
    local end_q = QuatMult(start_q, q_rot)
    return end_q.ToQAngle()
}

CzUtil.SpawnOnGround <- function(spawnerEnt, templateName, useGroundAngle = false, delay = 0, randomRotate = false) {
    if(spawnerEnt == null) return

    local below = CzUtil.GetLocationBelow(spawnerEnt)

    if(below == null) return


    local setAngle = QAngle(0,0,0)

    if(useGroundAngle) {

        local end_angles = CzUtil.GetGroundAngle(spawnerEnt.GetOrigin())

        local target
        if(randomRotate) {
            target = SpawnEntityFromTable("info_target", {
                origin      = below + Vector(0,0,3),
                angles = QAngle(0,0,0)
            })
            local c_target = SpawnEntityFromTable("info_target", {
                origin      = below + Vector(0,0,3),
                angles = QAngle(0,0,0)
            })
            EntFireByHandle(c_target, "SetParent", "!activator", 0, target, null)
            EntFireByHandle(target, "RunScriptCode", format("self.SetAbsAngles(QAngle(%s,%s,%s))",end_angles.x.tostring(),end_angles.y.tostring(),end_angles.z.tostring()), 0.05, null, null)
            EntFireByHandle(c_target, "RunScriptCode", format("self.SetLocalAngles(QAngle(0,%s,0))", RandomInt(0, 360).tostring()), 0.1, null, null)
            EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0.15 + delay, c_target)
            EntFire("!activator", "kill", null, 0.2 + delay, target)

        } else {
            target = SpawnEntityFromTable("info_target", {
                origin      = below + Vector(0,0,3),
                angles = end_angles
            })
            EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0 + delay, target)
        }

        EntFire("!activator", "kill", null, 0.2 + delay, target)

        //usegroundangle will delay the spawn by 0.35 secs as it uses physics to simulate the ground angle
        // local target = SpawnEntityFromTable("prop_physics_multiplayer", {
        //     "model":       "models/props_hydro/barrel_crate_half.mdl"
        //     "modelscale":  "0.2"
        //     "rendermode":  "10"
        //     "renderamt":    "0"
        //     "physicsmode": "1"
        //     "origin":      below
        //     "massScale":   "0.01"
        //     "spawnflags":  "4"
        //     "disableshadows": "1"
        //     "angles" : setAngle
        // })

        // EntFireByHandle(target, "disablemotion", "", 0.35, null, null)

        //EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0.35 + delay, target)

        // EntFire("!activator", "kill", null, 0.4 + delay, target)
    } else {
        if(randomRotate) {
            setAngle = QAngle(0,RandomInt(0, 360),0)
        }
        local target = SpawnEntityFromTable("info_target", {
            origin      = below,
            angles = setAngle
        })
        EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0 + delay, target)
        EntFire("!activator", "kill", null, 0.2 + delay, target)
    }
}

CzUtil.SetupIntervalSpawnOnGround <- function(spawnerEnt, _templateName, _interval) {
    spawnerEnt.ValidateScriptScope()
    local scope = spawnerEnt.GetScriptScope()
    scope.templateName <- _templateName
    scope.interval <- _interval
    scope.nextSpawn <- Time()

    // scope.target <-  SpawnEntityFromTable("info_target", {
    //     //targetname  = "targ" + rand().tostring() + rand().tostring()
    //     origin      = spawnerEnt.GetOrigin()
    // })

    scope.spawnCall <- function() {
        if(Time() > nextSpawn) {
            nextSpawn = Time() + interval

            local below = CzUtil.GetLocationBelow(self)

            local target = SpawnEntityFromTable("info_target", {
                origin      = below
            })

            EntFire(templateName, "ForceSpawnAtEntityOrigin", "!activator", 0, target)
            EntFire("!activator", "kill", null, 0.2, target)

        }
        return -1
    }

    AddThinkToEnt(spawnerEnt, "spawnCall")
}

///////////////////// SHITTY MOVEMENT AND SPECIALS ///////////////////

//Old Version
// for ringmarker1, which is the parent for the env_beam
::RingRegister <- function(beam, damage, attker, damageType = 8, onHit = null, targetname = "", onTargetHit = null) {
    local arr = split(beam.GetName() , "t")
    local beamId = arr[arr.len()-1]

    local marker = null

    for (local entity; entity = Entities.FindByNameWithin(entity,"ringmarkerone*", beam.GetOrigin(), 30);)
    {
        if(entity.GetName() == "ringmarkerone") {
            marker = entity
            break
        }
        local ringArr = split(entity.GetName() , "e")
        local ringId = ringArr[ringArr.len()-1]

        if(beamId == ringId) {
            marker = entity
            break
        }
    }

    if(marker == null) {
        return
    }
    beam.ValidateScriptScope()
    beam.GetScriptScope().marker <- marker
    beam.GetScriptScope().dmgValue <- damage
    beam.GetScriptScope().attacker <- attker
    beam.GetScriptScope().onHit <- onHit
    beam.GetScriptScope().damageType <- damageType


    if(targetname != "" && onTargetHit != null) {
        local targets = []
        for(local ent; ent = Entities.FindByName(ent, targetname + "*");) {
            targets.append(ent)
        }
        beam.GetScriptScope().targets <- targets
        beam.GetScriptScope().onTargetHit <- onTargetHit
    } else {
        beam.GetScriptScope().targets <- null
    }

    beam.GetScriptScope().beamRingThink <- function() {
        try {
            local scope = self.GetScriptScope()
            local marker = self.GetScriptScope().marker
            local damage = self.GetScriptScope().dmgValue
            local damageType = self.GetScriptScope().damageType
            local radius = (marker.GetOrigin()-self.GetOrigin()).Length()
            local onHit = self.GetScriptScope().onHit
            local ring_z = self.GetOrigin().z
            foreach (k, entity in CzUtil.Players) {
                if (entity != null && CzUtil.IsPlayerAlive(entity) && entity.GetTeam() == 2  ) {
                    local ent_z = entity.GetOrigin().z
                    local eye_z = entity.EyePosition().z
                    local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
                    if(ring_z > (ent_z+10) && ring_z < eye_z + 40) {
                        if(fabs(dist - radius) < 7){

                            if(!(entity.GetScriptScope().rawin("lastBeamDmg")) || Time() > entity.GetScriptScope().lastBeamDmg + 0.1)
                            {
                                local hitent = CzUtil.GetCanHitTargetGround(scope.attacker, entity)
                                //ClientPrint(null, 3, "hit ent " + hitent.tostring())
                                if(!hitent) continue
                                entity.TakeDamageCustom(entity, self.GetScriptScope().attacker, null, Vector(0,0,0), Vector(0,0,0), damage, damageType, 0) // Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING
                                entity.ApplyAbsVelocityImpulse(Vector(0,0,200))
                                entity.GetScriptScope().lastBeamDmg <- Time()
                                if(onHit != null) onHit(entity)
                            }
                        }
                    }
                }
            }
            foreach (k, entity in CzUtil.Objects) {
                if (CzUtil.IsPlayerAlive(entity) && entity.GetTeam() == 2 ) { //&&  CzUtil.IsPlayerLOSofMe(self,entity)
                    //ClientPrint(null,4,"bulding check " + entity.GetClassname())
                    entity.ValidateScriptScope()
                    local ent_z = entity.GetOrigin().z
                    local eye_z = entity.GetOrigin().z + 50
                    local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
                    if(ring_z > ent_z && ring_z < eye_z) {
                        if(fabs(dist - radius) < 8) {
                            //ClientPrint(null,3,"bulding hit " + entity.GetClassname())
                            if(!(entity.GetScriptScope().rawin("lastBeamDmg")) ||Time() > entity.GetScriptScope().lastBeamDmg + 0.2)
                            {
                                entity.TakeDamageEx(entity,self.GetScriptScope().attacker, null, Vector(0,0,0), Vector(0,0,0), damage, damageType)
                                entity.GetScriptScope().lastBeamDmg <- Time()
                            }
                        }
                    }
                }
            }
            if(scope.targets != null) {
                foreach (entity in scope.targets) {
                    entity.ValidateScriptScope()
                    local ent_z = entity.GetOrigin().z - 50
                    local eye_z = entity.GetOrigin().z + 60
                    local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
                    if(ring_z > ent_z && ring_z < eye_z) {
                        if(fabs(dist - radius) < 10) {
                            //ClientPrint(null,3,"bulding hit " + entity.GetClassname())
                            if(!(entity.GetScriptScope().rawin("lastBeamDmg")) ||Time() > entity.GetScriptScope().lastBeamDmg + 0.2)
                            {
                                scope.onTargetHit(entity)
                            }
                        }
                    }
                }
            }

        } catch (exception){

        }

        return -1
    }

    AddThinkToEnt(beam, "beamRingThink")
}
// ::RingThink <- function() {
//     try {
//         local scope = self.GetScriptScope()
//         local marker = self.GetScriptScope().marker
//         local damage = self.GetScriptScope().dmgValue
//         local damageType = self.GetScriptScope().damageType
//         local radius = (marker.GetOrigin()-self.GetOrigin()).Length()
//         local onHit = self.GetScriptScope().onHit
//         local ring_z = self.GetOrigin().z
//         foreach (k, entity in CzUtil.Players) {
//             if (entity != null && CzUtil.IsPlayerAlive(entity) && entity.GetTeam() == 2  ) {
//                 local ent_z = entity.GetOrigin().z
//                 local eye_z = entity.EyePosition().z
//                 local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
//                 if(ring_z > (ent_z+10) && ring_z < eye_z + 40) {
//                     if(fabs(dist - radius) < 7){

//                         if(!(entity.GetScriptScope().rawin("lastBeamDmg")) || Time() > entity.GetScriptScope().lastBeamDmg + 0.1)
//                         {
//                             local hitent = CzUtil.GetCanHitTargetGround(scope.attacker, entity)
//                             //ClientPrint(null, 3, "hit ent " + hitent.tostring())
//                             if(!hitent) continue
//                             entity.TakeDamageCustom(entity, self.GetScriptScope().attacker, null, Vector(0,0,0), Vector(0,0,0), damage, damageType, 0) // Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING
//                             entity.ApplyAbsVelocityImpulse(Vector(0,0,200))
//                             entity.GetScriptScope().lastBeamDmg <- Time()
//                             if(onHit != null) onHit(entity)
//                         }
//                     }
//                 }
//             }
//         }
//         foreach (k, entity in CzUtil.Objects) {
//             if (CzUtil.IsPlayerAlive(entity) && entity.GetTeam() == 2 ) { //&&  CzUtil.IsPlayerLOSofMe(self,entity)
//                 //ClientPrint(null,4,"bulding check " + entity.GetClassname())
//                 entity.ValidateScriptScope()
//                 local ent_z = entity.GetOrigin().z
//                 local eye_z = entity.GetOrigin().z + 50
//                 local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
//                 if(ring_z > ent_z && ring_z < eye_z) {
//                     if(fabs(dist - radius) < 8) {
//                         //ClientPrint(null,3,"bulding hit " + entity.GetClassname())
//                         if(!(entity.GetScriptScope().rawin("lastBeamDmg")) ||Time() > entity.GetScriptScope().lastBeamDmg + 0.2)
//                         {
//                             entity.TakeDamageEx(entity,self.GetScriptScope().attacker, null, Vector(0,0,0), Vector(0,0,0), damage, damageType)
//                             entity.GetScriptScope().lastBeamDmg <- Time()
//                         }
//                     }
//                 }
//             }
//         }
//         if(scope.targets != null) {
//             foreach (entity in scope.targets) {
//                 entity.ValidateScriptScope()
//                 local ent_z = entity.GetOrigin().z - 50
//                 local eye_z = entity.GetOrigin().z + 60
//                 local dist = ((entity.GetOrigin() + Vector(0,0,30)) - self.GetOrigin()).Length()
//                 if(ring_z > ent_z && ring_z < eye_z) {
//                     if(fabs(dist - radius) < 10) {
//                         //ClientPrint(null,3,"bulding hit " + entity.GetClassname())
//                         if(!(entity.GetScriptScope().rawin("lastBeamDmg")) ||Time() > entity.GetScriptScope().lastBeamDmg + 0.2)
//                         {
//                             scope.onTargetHit(entity)
//                         }
//                     }
//                 }
//             }
//         }

//     } catch (exception){

//     }

//     return -1
// }


//Old Version
::SetMoveIgnoreSolid <- function(ent, speed) {
    ent.ValidateScriptScope()
    ent.GetScriptScope().shootSpeed <- speed
    ent.GetScriptScope().shootThinkFunc <- function() {
        local vel = self.GetForwardVector() * self.GetScriptScope().shootSpeed
        vel.z = 0
        local lilVel = self.GetForwardVector()
        lilVel.z = 0
        lilVel.Norm()
        self.SetAbsOrigin(self.GetOrigin() + (vel*FrameTime()) + lilVel)
        return -1
    }
    AddThinkToEnt(ent, "shootThinkFunc")
}

/*
sampleBeamTable = {
    origin      = "0 0 0"
    parentname  = "examp"
    isCircle    = "1"
    boltWidth   = "8"
    renderAmt   = 255
    rendercolor = "255 180 50"
    damage      = 999
    damageType  = 1
    noiseAmplitude = 2
    texture     = "sprites/fire.spr"
    lifespan    = 7
    spawnflags  = 8
    lightningStart = ""
    lightningEnd = ""
    radius      = 200
    owner       = bossHandle
}

*/

//New Version
CzUtil.SetMoveIgnoreSolidEx <- function(ent, speed, angle, accel = 0, duration = 0, maxDist = null) {
    ent.ValidateScriptScope()
    ent.GetScriptScope().shootSpeed <- speed
    ent.GetScriptScope().shootAng <- angle
    ent.GetScriptScope().shootAng.Norm()
    ent.GetScriptScope().shootAccel <- accel
    ent.GetScriptScope().shootStartTime <- Time()
    ent.GetScriptScope().shootEndTime <- Time() + duration
    ent.GetScriptScope().startPos <- ent.GetOrigin()
    ent.GetScriptScope().maxDist <- maxDist

    AddThinkToEnt(ent, "ShootThinkEx")
    //ClientPrint(null, 3, "moveignoresetup")
}
::ShootThinkEx <- function() {
    //ClientPrint(null, 3, "sanitycheck")
    local dir = self.GetScriptScope().shootAng
    local vel = dir * self.GetScriptScope().shootSpeed
    local accel = self.GetScriptScope().shootAccel
    if(accel != 0) {
        self.GetScriptScope().shootSpeed = self.GetScriptScope().shootSpeed + accel //*FrameTime()
    }
    //ClientPrint(null, 3, "vel " + vel.tostring())
    if(Time() > self.GetScriptScope().shootEndTime){
        CzUtil.RemoveThink(self)
        return 2
        //ClientPrint(null, 3, "removethink")
    }
    if(maxDist!=null && (self.GetOrigin() - self.GetScriptScope().startPos).Length() > self.GetScriptScope().maxDist) {
        CzUtil.RemoveThink(self)
        return 2
    }
    self.SetAbsOrigin(self.GetOrigin() + (vel*FrameTime()) + dir)
    return -1
}

CzUtil.KirbyBoss <- function(boss, callback, soundfile = "bossbar1.wav", percentage = 1, healthPercentPerTick = 0.33) {
    boss.AddCond(51)
    boss.SetHealth(1)
    local target = SpawnEntityFromTable("info_target", {})
    target.ValidateScriptScope()
    target.GetScriptScope().healTarget <- boss
    target.GetScriptScope().healCallback <- callback
    target.GetScriptScope().healLimit <- percentage
    target.GetScriptScope().healEffect <- function() {
        if (!CzUtil.IsPlayerAlive(healTarget)) {
            EntFireByHandle(self, "kill", null, 0, null, null)
            return
        }
        if(healTarget.GetHealth() < healTarget.GetMaxHealth()*healLimit) {
            healTarget.SetHealth(healTarget.GetHealth() + (healTarget.GetMaxHealth()*healLimit) * (healthPercentPerTick) * FrameTime())
        } else if (healTarget.GetHealth() > healTarget.GetMaxHealth()*healLimit) {
            healTarget.SetHealth(healTarget.GetMaxHealth()*healLimit)
            healTarget.RemoveCond(51)
            CzUtil.RemoveThink(self)
            if (healCallback != null)
                healCallback()
        }
        return -1
    }
    EntFire("tf_gamerules", "PlayVO", soundfile, 0)
    AddThinkToEnt(target, "healEffect")
    NetProps.SetPropBool(boss, "m_bUseBossHealthBar", true)
}
CzUtil.LookAtPos <- function(bot, pos, speed = 0, duration = 0){
    if(!(CzUtil.IsPlayerAlive(bot))) return
    bot.ValidateScriptScope()
    if ("lookAtTemp" in bot.GetScriptScope()) {
        EntFireByHandle(bot.GetScriptScope().lookAtTemp, "kill", null, 0, null, null)
    }
    local name = rand().tostring() + rand().tostring()
    local target = SpawnEntityFromTable("info_target", {
        origin      = pos
        targetname  = name
    })
    CzUtil.LookAtTarget(bot,target,speed,duration)
    bot.GetScriptScope().lookAtTemp <- target
}
CzUtil.LookAtTargetname <- function(bot, targetname, speed = 0, duration = 0){
    local target = Entities.FindByName(null, targetname)
    if(!target) {
        throw "LookAtTarget target not found";
        return
    }
    CzUtil.LookAtTarget(bot, target, speed, duration)
}
CzUtil.LookAtTarget <- function(bot, target, speed = 0, duration = 0){
    if(!(CzUtil.IsPlayerAlive(bot))) return
    bot.ValidateScriptScope()
    local scope = bot.GetScriptScope()
    scope.turnSpeed <- speed
    if(!target) {
        throw "LookAtTarget target not found";
        return
    }

    scope.turnTarget <- target
    if (duration > 0) {
        scope.turnEndTime <- Time() + duration
    } else {
        scope.turnEndTime <- null
    }


    if (!("turnHelper" in scope) || !(scope.turnHelper.IsValid())) {
        scope.turnHelper <- SpawnEntityFromTable("info_target", {})
        scope.turnHelper.ValidateScriptScope()
        scope.turnHelper.GetScriptScope().player <- bot
        scope.turnHelper.GetScriptScope().turnThink <- function() {
            if (!("player" in self.GetScriptScope()) || !(CzUtil.IsPlayerAlive(player))) {
                EntFireByHandle(self, "Kill", null, 0.1, null, null)
                return
            }
        	local scope = player.GetScriptScope()
        	if (!("turnTarget" in scope) || scope.turnTarget == null) {
                return
            }
            if("turnEndTime" in scope && scope.turnEndTime!= null && Time() > scope.turnEndTime) {
                if ("lookAtTemp" in bot.GetScriptScope()) {
                    EntFireByHandle(bot.GetScriptScope().lookAtTemp, "kill", null, 0, null, null)
                }
                return
            }

            local targetLoc = scope.turnTarget.GetOrigin()
            local locomotion = player.GetLocomotionInterface()
            locomotion.FaceTowards(targetLoc)
            local bot_ang = player.GetAbsAngles()
            local targVec = targetLoc - player.GetOrigin()
            targVec.Norm()
            local move_ang = CzUtil.VectorAngles(targVec)
            // Rotating the bot
            if ("turnSpeed" in scope && scope.turnSpeed != 0) {
                // Approach new desired angle but only on the Y axis
                bot_ang.y = CzUtil.ApproachAngle(move_ang.y, bot_ang.y, scope.turnSpeed*FrameTime()*100)
            } else {
                bot_ang.y = move_ang.y
            }

            // Set our new angles
            player.SetAbsAngles(bot_ang)
            local look_ang = bot_ang
            look_ang.x = move_ang.x
            //look_ang.z = move_ang.z

            player.SnapEyeAngles(move_ang) //look_ang
            return -1
        }
        AddThinkToEnt(scope.turnHelper, "turnThink")
    }
}
CzUtil.StopLookAt <- function(bot) {
    bot.ValidateScriptScope()
    bot.GetScriptScope().turnTarget <- null
    if ("lookAtTemp" in bot.GetScriptScope()) {
        EntFireByHandle(bot.GetScriptScope().lookAtTemp, "kill", null, 0, null, null)
    }
}

//for camera movement among other things
/*
matching ENavRelativeDirType in constants
FORWARD 	0
RIGHT 	1
BACKWARD 	2
LEFT 	3
UP 	4
DOWN 	5
NUM_RELATIVE_DIRECTIONS 	6
*/
CzUtil.DIR <- {
    FORWARD = 0
    RIGHT = 1
    BACKWARD = 2
    LEFT = 3
    UP = 4
    DOWN = 5
}
//meant for simple cardinal movements on non-player ents
CzUtil.SimpleMoveEnt <- function(bot, dir, speed, duration) {
    if (!(bot.IsValid())) return
    bot.ValidateScriptScope()
    local scope = bot.GetScriptScope()
    scope.moveSpeed <- speed
    scope.moveEndTime <- Time() + duration
    scope.moveDir <- dir

    if (!("simpleMoveHelper" in scope) || !(scope.simpleMoveHelper.IsValid())) {
        scope.simpleMoveHelper <- SpawnEntityFromTable("info_target", {})
        scope.simpleMoveHelper.ValidateScriptScope()
        scope.simpleMoveHelper.GetScriptScope().player <- bot
        scope.simpleMoveHelper.GetScriptScope().moveThinkSimple <- function() {
            if (!("player" in self.GetScriptScope()) || !(player.IsValid())) {
                EntFireByHandle(self, "Kill", null, 0.1, null, null)
                return
            }
        	local scope = player.GetScriptScope()
            if("moveEndTime" in scope && scope.moveEndTime!= null && Time() > scope.moveEndTime) {
                return
            }
            local angle = player.GetAbsAngles()
            local vec_angle = Vector(0,0,0)
            switch (scope.moveDir) {
                case CzUtil.DIR.FORWARD:
                    vec_angle = angle.Forward();
                    break;
                case CzUtil.DIR.BACKWARD:
                    vec_angle = angle.Forward() * (-1);
                    break;
                case CzUtil.DIR.RIGHT:
                    vec_angle = angle.Left();
                    break;
                case CzUtil.DIR.LEFT:
                    vec_angle = angle.Left() * (-1);
                    break;
                case CzUtil.DIR.UP:
                    vec_angle = angle.Up();
                    break;
                case CzUtil.DIR.DOWN:
                    vec_angle = angle.Up() * (-1);
                    break;
                default:
                    vec_angle = angle.Forward();
            }

            player.SetAbsOrigin(player.GetOrigin() + (vec_angle * scope.moveSpeed * FrameTime()))

            return -1
        }
        AddThinkToEnt(scope.simpleMoveHelper, "moveThinkSimple")
    }
}
// same as LookAtTargetname except its for non-player/bot entities
CzUtil.LookEntAtTargetname <- function(bot, targetname, speed = 0, duration = 0){
    //if(!(CzUtil.IsPlayerAlive(bot))) return
    if (!(bot.IsValid())) return
    bot.ValidateScriptScope()
    local scope = bot.GetScriptScope()
    scope.turnSpeed <- speed
    local target = Entities.FindByName(null, targetname)
    if(!target) {
        throw "LookAtTarget target not found";
        return
    }
    if ("lookAtTemp" in bot.GetScriptScope()) {
        EntFireByHandle(bot.GetScriptScope().lookAtTemp, "kill", null, 0, null, null)
    }
    scope.turnTarget <- target
    if (duration > 0) {
        scope.turnEndTime <- Time() + duration
    } else {
        scope.turnEndTime <- null
    }


    if (!("turnHelper" in scope) || !(scope.turnHelper.IsValid())) {
        scope.turnHelper <- SpawnEntityFromTable("info_target", {})
        scope.turnHelper.ValidateScriptScope()
        scope.turnHelper.GetScriptScope().player <- bot
        scope.turnHelper.GetScriptScope().turnThink <- function() {
            if (!("player" in self.GetScriptScope()) || !(player.IsValid())) {
                EntFireByHandle(self, "Kill", null, 0.1, null, null)
                return
            }
        	local scope = player.GetScriptScope()
        	if (!("turnTarget" in scope) || scope.turnTarget == null) {
                return
            }
            if("turnEndTime" in scope && scope.turnEndTime!= null && Time() > scope.turnEndTime) {
                return
            }

            local targetLoc = scope.turnTarget.GetOrigin()

            local bot_ang = player.GetAbsAngles()
            local targVec = targetLoc - player.GetOrigin()
            targVec.Norm()
            local move_ang = CzUtil.VectorAngles(targVec)
            // Rotating the bot
            if ("turnSpeed" in scope && scope.turnSpeed != 0) {
                // Approach new desired angle but only on the Y axis
                bot_ang.y = CzUtil.ApproachAngle(move_ang.y, bot_ang.y, scope.turnSpeed*FrameTime()*100)
            } else {
                bot_ang.y = move_ang.y
            }

            // Set our new angles
            player.SetAbsAngles(bot_ang)
            //local look_ang = bot_ang
            //look_ang.x = move_ang.x
            //look_ang.z = move_ang.z

            //player.SnapEyeAngles(move_ang) //look_ang
            return -1
        }
        AddThinkToEnt(scope.turnHelper, "turnThink")
    }
}
//aka move to a vector location
CzUtil.MoveTo <- function(bot, location, duration = 0, stopAtDestination = false, callbackCode = ""){
    if(!(CzUtil.IsPlayerAlive(bot))) return
    bot.ValidateScriptScope()
    if ("moveToTemp" in bot.GetScriptScope()) {
        EntFireByHandle(bot.GetScriptScope().moveToTemp, "kill", null, 0, null, null)
    }
    local name = rand().tostring() + rand().tostring()
    local target = SpawnEntityFromTable("info_target", {
        origin      = location
        targetname  = name
    })
    bot.GetScriptScope().moveToTemp <- target
    CzUtil.MoveToTargetEnt(bot, target, duration, stopAtDestination, callbackCode)

}
CzUtil.MoveToTargetName<- function(bot, targetname, duration = 0, stopAtDestination = false, callbackCode = ""){
    local target = Entities.FindByName(null, targetname)
    if(!target) {
        throw "target not found:" + targetname;
        return
    }

    CzUtil.MoveToTargetEnt(bot, target, duration, stopAtDestination, callbackCode)
}
CzUtil.MoveToTargetEnt <- function(bot, target, duration = 0, stopAtDestination = false, callbackCode = ""){
    if(!(CzUtil.IsPlayerAlive(bot))) return
    bot.ValidateScriptScope()
    local scope = bot.GetScriptScope()

    scope.moveTarget <- target
    if (duration > 0) {
        scope.moveEndTime <- Time() + duration
    } else {
        scope.moveEndTime <- null
    }
    scope.stopAtDestination <- stopAtDestination
    scope.callbackCode <- callbackCode

    if (!("moveHelper" in scope) || !(scope.moveHelper.IsValid())) {
    	scope.moveHelper <- SpawnEntityFromTable("info_target", {})
    	scope.moveHelper.ValidateScriptScope()
    	scope.moveHelper.GetScriptScope().player <- bot
    	scope.moveHelper.GetScriptScope().moveThink <- function() {
    		if (!("player" in self.GetScriptScope()) || !CzUtil.IsPlayerAlive(player)) {
    			EntFireByHandle(self, "Kill", null, 0.1, null, null)
    			return -1
    		}
    	    local scope = player.GetScriptScope()
    	    if (!("moveTarget" in scope) || scope.moveTarget == null || ("IsValid" in scope.moveTarget && !(scope.moveTarget.IsValid()))) {
                return -1
            }

            if (scope.moveTarget.GetClassname() == "player" && !(CzUtil.IsPlayerAlive(scope.moveTarget))) {
                return -1
            }
            if("moveEndTime" in scope && scope.moveEndTime!= null && Time() > scope.moveEndTime) {
                scope.moveTarget <- null
                return -1
            }
            if("callbackCode" in scope && scope.callbackCode) {
                if ((player.GetOrigin() - scope.moveTarget.GetOrigin()).Length() < 10) {
                    EntFireByHandle(player, "RunScriptCode", scope.callbackCode, 0, null, null)
                    scope.callbackCode <- null
                }
            }
            if("stopAtDestination" in scope && scope.stopAtDestination) {
                if ((player.GetOrigin() - scope.moveTarget.GetOrigin()).Length() < 50) {
                    scope.moveTarget <- null
                    return -1
                }
            }

            local targetLoc = scope.moveTarget.GetOrigin()
            local locomotion = player.GetLocomotionInterface()
            locomotion.Approach(targetLoc, 0.0)
            player.SetActionPoint( null )
            player.SetAttentionFocus(null)
            player.SetMissionTarget(null)
            return -1
        }
        AddThinkToEnt(scope.moveHelper, "moveThink")
    }
}

CzUtil.StopMoveTo <- function(bot) {
    bot.ValidateScriptScope()
    bot.GetScriptScope().moveTarget <- null
}

// ///////////////////// Debug ///////////////////
//Setting a error handler allows us to view vscript error messages, even if we are not testing locally i.e. on potato testing server
// CzUtil.DebugSteamIds <- {}
// CzUtil.DebugSteamIds["[U:1:66915592]"] <- 1
// seterrorhandler(function(e)
// {
// 	for (local player; player = Entities.FindByClassname(player, "player");)
// 	{
// 		if (CzUtil.DebugSteamIds.rawin(NetProps.GetPropString(player, "m_szNetworkIDString")))
// 		{
// 			local Chat = @(m) (printl(m), ClientPrint(player, 2, m))
// 			ClientPrint(player, 3, format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details", e))

// 			Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
// 			Chat("CALLSTACK")
// 			local s, l = 2
// 			while (s = getstackinfos(l++))
// 				Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
// 			Chat("LOCALS")
// 			if (s = getstackinfos(2))
// 			{
// 				foreach (n, v in s.locals)
// 				{
// 					local t = type(v)
// 					t ==    "null" ? Chat(format("[%s] NULL"  , n))    :
// 					t == "integer" ? Chat(format("[%s] %d"    , n, v)) :
// 					t ==   "float" ? Chat(format("[%s] %.14g" , n, v)) :
// 					t ==  "string" ? Chat(format("[%s] \"%s\"", n, v)) :
// 									 Chat(format("[%s] %s %s" , n, t, v.tostring()))
// 				}
// 			}
// 			return
// 		}
// 	}
// })