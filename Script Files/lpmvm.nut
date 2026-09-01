// lpmvm.nut
//
// Convenience layer for the raw functions exported by lpmvm_vscript.smx.
// Place this file under tf/scripts/vscripts and load it from another script:
//
//     IncludeScript("lpmvm");
//
// The wrapper is deliberately pure Squirrel. It does not replace the plugin;
// lpmvm_vscript.smx still has to be loaded before any wrapper method is used.
//
// Quick example:
//
//     IncludeScript("lpmvm");
//
//     LPMVM.Commands.Register(
//         "sm_my_mvm_command",
//         function(ctx)
//         {
//             if (ctx.fromConsole)
//                 printl("called by the server");
//             else
//                 printl("called by player entity " +
//                     ctx.player.GetEntityIndex().tostring());
//
//             // Returning null defaults to Action.HANDLED.
//         },
//         "My VScript command",
//         LPMVM.Admin.GENERIC
//     );

if (!("LPMVM" in getroottable()))
{
    ::LPMVM <- {};
}

LPMVM.VERSION <- "1.0.0";


// --------------------------------------------------------------------------
// Constants
// --------------------------------------------------------------------------

LPMVM.Action <- {
    CONTINUE = 0,
    CHANGED  = 1,
    HANDLED  = 3,
    STOP     = 4
};

LPMVM.Admin <- {
    NONE        = 0,
    RESERVATION = (1 << 0),  // a
    GENERIC     = (1 << 1),  // b
    KICK        = (1 << 2),  // c
    BAN         = (1 << 3),  // d
    UNBAN       = (1 << 4),  // e
    SLAY        = (1 << 5),  // f
    CHANGEMAP   = (1 << 6),  // g
    CONVARS     = (1 << 7),  // h
    CONFIG      = (1 << 8),  // i
    CHAT        = (1 << 9),  // j
    VOTE        = (1 << 10), // k
    PASSWORD    = (1 << 11), // l
    RCON        = (1 << 12), // m
    CHEATS      = (1 << 13), // n
    ROOT        = (1 << 14), // z
    CUSTOM1     = (1 << 15), // o
    CUSTOM2     = (1 << 16), // p
    CUSTOM3     = (1 << 17), // q
    CUSTOM4     = (1 << 18), // r
    CUSTOM5     = (1 << 19), // s
    CUSTOM6     = (1 << 20)  // t
};

LPMVM.VoteResult <- {
    CANCELLED = -1,
    FAILED    = 0,
    PASSED    = 1
};

LPMVM.VoteDuration <- {
    MINIMUM = 1,
    DEFAULT = 20,
    MAXIMUM = 60
};

LPMVM.ClientIndex <- {
    SERVER_CONSOLE = 0,
    FIRST_PLAYER   = 1
};

LPMVM.Wave <- {
    FIRST = 1
};

LPMVM.Limit <- {
    PLAYER_DATA_KEY   = 64,
    PLAYER_DATA_VALUE = 1024,
    EVENT_NAME        = 64,
    EVENT_ARGUMENT    = 1024
};

// Common TF2 values are included because entity methods such as GetTeam() and
// GetPlayerClass() return integers rather than friendly enum values.
LPMVM.Team <- {
    UNASSIGNED = 0,
    SPECTATOR  = 1,
    RED        = 2,
    BLU        = 3,
    BLUE       = 3,
    DEFENDERS  = 2, // MvM human team
    INVADERS   = 3  // MvM robot team
};

LPMVM.Class <- {
    UNDEFINED   = 0,
    SCOUT       = 1,
    SNIPER      = 2,
    SOLDIER     = 3,
    DEMOMAN     = 4,
    MEDIC       = 5,
    HEAVY       = 6,
    HEAVYWEAPONS = 6,
    PYRO        = 7,
    SPY         = 8,
    ENGINEER    = 9,
    CIVILIAN    = 10,
    RANDOM      = 12
};


// --------------------------------------------------------------------------
// Internal helpers
// --------------------------------------------------------------------------

LPMVM.IsAvailable <- function()
{
    return "LPMVM_RegisterCommand" in getroottable();
};

LPMVM._RequireBridge <- function()
{
    if (!LPMVM.IsAvailable())
    {
        throw "lpmvm_vscript.smx has not registered its VScript API";
    }
};

// The native query functions return tables keyed by the strings "0", "1", ...
// because that representation crosses the VScript bridge reliably. Consumers
// generally want a normal Squirrel array instead.
LPMVM._IndexedTableToArray <- function(values)
{
    local result = [];
    for (local index = 0; index < values.len(); ++index)
    {
        local key = index.tostring();
        if (key in values)
        {
            result.append(values[key]);
        }
    }
    return result;
};


// --------------------------------------------------------------------------
// Client/entity conversion
// --------------------------------------------------------------------------

LPMVM.Client <- {};

// Public wrapper methods accept either a TF2 player EHANDLE or a raw Source
// client index. Prefer an EHANDLE in ordinary VScript code. Null is rejected so
// an expired entity handle can never accidentally become server-console access.
LPMVM.Client.ToIndex <- function(playerOrIndex)
{
    if (playerOrIndex == null)
    {
        throw "expected a player EHANDLE or client index, got null";
    }

    if (typeof(playerOrIndex) == "integer")
    {
        return playerOrIndex;
    }

    return playerOrIndex.GetEntityIndex();
};

LPMVM.Client.FromIndex <- function(clientIndex)
{
    if (clientIndex == LPMVM.ClientIndex.SERVER_CONSOLE)
    {
        return null;
    }
    return PlayerInstanceFromIndex(clientIndex);
};


// --------------------------------------------------------------------------
// Commands
// --------------------------------------------------------------------------

LPMVM.Commands <- {};

// handler receives one context table:
//   ctx.player       player EHANDLE, or null for server console
//   ctx.clientIndex  raw Source client index
//   ctx.fromConsole  true when clientIndex is zero
//   ctx.command      normalized command name
//   ctx.args         raw argument string
//
// Returning null is shorthand for Action.HANDLED. Otherwise return an Action.
// The wrapper creates the root-scope trampoline required by the native bridge,
// so callers can pass a closure directly instead of inventing callback names.
LPMVM.Commands.Register <- function(command, handler, description = "", adminFlags = 0)
{
    LPMVM._RequireBridge();
    if (typeof(handler) != "function")
    {
        throw "LPMVM.Commands.Register expected a function handler";
    }

    local trampolineName = "LPMVM_Command_" + command;
    local root = getroottable();
    root[trampolineName] <- function(clientIndex, invokedCommand, args)
    {
        local context = {
            player      = LPMVM.Client.FromIndex(clientIndex),
            clientIndex = clientIndex,
            fromConsole = clientIndex == LPMVM.ClientIndex.SERVER_CONSOLE,
            command     = invokedCommand,
            args        = args
        };

        local action = handler(context);
        return action == null ? LPMVM.Action.HANDLED : action;
    };

    local registered = LPMVM_RegisterCommand(
        command,
        trampolineName,
        description,
        adminFlags
    );
    if (!registered)
    {
        delete root[trampolineName];
    }
    return registered;
};

// playerOrIndex may be an EHANDLE or integer. Pass ClientIndex.SERVER_CONSOLE
// explicitly for the console; do not pass null.
LPMVM.Commands.CanUse <- function(
    playerOrIndex,
    accessName,
    fallbackFlags = 0,
    overrideOnly = false
)
{
    LPMVM._RequireBridge();
    return LPMVM_CheckCommandAccess(
        LPMVM.Client.ToIndex(playerOrIndex),
        accessName,
        fallbackFlags,
        overrideOnly
    );
};


// --------------------------------------------------------------------------
// Mission cycle and gameplay
// --------------------------------------------------------------------------

LPMVM.Missions <- {};

LPMVM.Missions.GetMaps <- function()
{
    LPMVM._RequireBridge();
    return LPMVM._IndexedTableToArray(LPMVM_GetMissionMaps());
};

LPMVM.Missions.GetPopfiles <- function(mapName)
{
    LPMVM._RequireBridge();
    return LPMVM._IndexedTableToArray(LPMVM_GetPopfilesForMap(mapName));
};

// Returns [{ name = "mvm_decoy", popfiles = [...] }, ...].
LPMVM.Missions.GetAll <- function()
{
    local result = [];
    foreach (mapName in LPMVM.Missions.GetMaps())
    {
        result.append({
            name = mapName,
            popfiles = LPMVM.Missions.GetPopfiles(mapName)
        });
    }
    return result;
};

LPMVM.Game <- {};

LPMVM.Game.ChangeMap <- function(mapName)
{
    LPMVM._RequireBridge();
    return LPMVM_ForceChangeLevel(mapName);
};

LPMVM.Game.SelectPopfile <- function(popfileName)
{
    LPMVM._RequireBridge();
    return LPMVM_SetPopfile(popfileName);
};

LPMVM.Game.JumpToWave <- function(wave)
{
    LPMVM._RequireBridge();
    return LPMVM_JumpToWave(wave);
};

LPMVM.Game.StartWave <- function()
{
    LPMVM._RequireBridge();
    return LPMVM_ForceStartWave();
};

LPMVM.Game.ClearRobotsAndTanks <- function()
{
    LPMVM._RequireBridge();
    return LPMVM_KillRobotsAndTanks();
};


// --------------------------------------------------------------------------
// Persistent player strings
// --------------------------------------------------------------------------

LPMVM.PlayerData <- {};

LPMVM.PlayerData.Set <- function(playerOrIndex, key, value)
{
    LPMVM._RequireBridge();
    return LPMVM_SetPlayerData(LPMVM.Client.ToIndex(playerOrIndex), key, value);
};

LPMVM.PlayerData.Get <- function(playerOrIndex, key, defaultValue = "")
{
    LPMVM._RequireBridge();
    return LPMVM_GetPlayerData(
        LPMVM.Client.ToIndex(playerOrIndex),
        key,
        defaultValue
    );
};

LPMVM.PlayerData.Delete <- function(playerOrIndex, key)
{
    LPMVM._RequireBridge();
    return LPMVM_DeletePlayerData(LPMVM.Client.ToIndex(playerOrIndex), key);
};


// --------------------------------------------------------------------------
// Events
// --------------------------------------------------------------------------

LPMVM.Events <- {};

LPMVM.Events.Signal <- function(name, argument = "")
{
    LPMVM._RequireBridge();
    LPMVM_SignalEvent(name, argument);
};


// --------------------------------------------------------------------------
// Global votes
// --------------------------------------------------------------------------

// Preserve an in-flight wrapper callback if this library is included again
// while a vote is active.
if (!("Votes" in LPMVM))
{
    LPMVM.Votes <- {};
}
if (!("_callback" in LPMVM.Votes))
{
    LPMVM.Votes._callback <- null;
}
if (!("_kind" in LPMVM.Votes))
{
    LPMVM.Votes._kind <- null;
}

// callback receives one outcome table:
//   outcome.kind          "yes_no" or "multiple_choice"
//   outcome.result        VoteResult.CANCELLED/FAILED/PASSED
//   outcome.winner        "yes", "no", option text, or "" if cancelled
//   outcome.winningVotes  number of votes for the winner
//   outcome.totalVotes    total votes cast
//   outcome.cancelled, outcome.failed, outcome.passed
::LPMVM_VoteDispatch <- function(result, winner, winningVotes, totalVotes)
{
    local callback = LPMVM.Votes._callback;
    local kind = LPMVM.Votes._kind;
    LPMVM.Votes._callback = null;
    LPMVM.Votes._kind = null;

    if (callback == null)
    {
        return;
    }

    callback({
        kind         = kind,
        result       = result,
        winner       = winner,
        winningVotes = winningVotes,
        totalVotes   = totalVotes,
        cancelled    = result == LPMVM.VoteResult.CANCELLED,
        failed       = result == LPMVM.VoteResult.FAILED,
        passed       = result == LPMVM.VoteResult.PASSED
    });
};

LPMVM.Votes._ValidateCallback <- function(callback)
{
    if (typeof(callback) != "function")
    {
        throw "LPMVM.Votes expected a function callback";
    }
};

LPMVM.Votes.YesNo <- function(
    title,
    callback,
    duration = null
)
{
    LPMVM._RequireBridge();
    LPMVM.Votes._ValidateCallback(callback);
    if (duration == null)
    {
        duration = LPMVM.VoteDuration.DEFAULT;
    }

    local started = LPMVM_StartYesNoVote(
        title,
        duration,
        "LPMVM_VoteDispatch"
    );
    if (started)
    {
        LPMVM.Votes._callback = callback;
        LPMVM.Votes._kind = "yes_no";
    }
    return started;
};

LPMVM.Votes.MultipleChoice <- function(
    title,
    options,
    callback,
    duration = null
)
{
    LPMVM._RequireBridge();
    LPMVM.Votes._ValidateCallback(callback);
    if (duration == null)
    {
        duration = LPMVM.VoteDuration.DEFAULT;
    }

    local started = LPMVM_StartMultipleChoiceVote(
        title,
        options,
        duration,
        "LPMVM_VoteDispatch"
    );
    if (started)
    {
        LPMVM.Votes._callback = callback;
        LPMVM.Votes._kind = "multiple_choice";
    }
    return started;
};
