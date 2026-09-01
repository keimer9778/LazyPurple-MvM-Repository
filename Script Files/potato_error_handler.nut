local MAX_ERRORS = 15
local IS_DEDICATED = IsDedicatedServer()
local THROTTLE_DELAY = 5.0

local throttle_time = 0.0

// Whitelisted files get more concise errors.
local whitelisted_files =
{
	"contracts.nut" : null
}

// Custom error handler to pipe errors to players and throttle spammy ones.
local function _ErrorHandler(e) {

	local error_table = __potato.ErrorHandler.error_table
	local stack = getstackinfos(2)
	local src = stack ? stack.src : null

	// Hyphen can't be used in a function name, so it should reduce the possibility
	//  of any bogus matches to basically 0.0 (they were already low, to be fair).
	local error_and_func = format("%s-%s", e, stack.func)

	// Ignore throttled errors
	if (Time() < throttle_time && error_and_func in error_table && error_table[error_and_func] > MAX_ERRORS)
		return

	// Otherwise, increment/insert this error into the table.
	error_and_func in error_table ? error_table[error_and_func]++ : error_table[error_and_func] <- 1
	throttle_time = Time() + THROTTLE_DELAY

	// Throttle this error if it shows up too many times in the same function.
	if (error_table[error_and_func] >= MAX_ERRORS && !(src in whitelisted_files))
	{
		ClientPrint(null, Constants.EHudNotify.HUD_PRINTCONSOLE, format("\x07FF0000ERROR HANDLER THROTTLED! Error '%s' has been thrown %d times!", e, error_table[error_and_func]))
		throttle_time = Time() + THROTTLE_DELAY
	}

	local function Chat(msg, ...)
	{
		msg = format.acall([this, msg].extend(vargv))
		ClientPrint(null, Constants.EHudNotify.HUD_PRINTCONSOLE, msg)
		if (IS_DEDICATED) printl(msg)
	}

	local error_message = src in whitelisted_files ? format("\x07222FF0 %s: [%s]", src, e) : format("\x07FF0000AN ERROR HAS OCCURRED [%s].\nCheck console for details.", e)
	ClientPrint(null, Constants.EHudNotify.HUD_PRINTTALK, error_message)

	Chat(format("\n====== TIMESTAMP: %g ======\nAN ERROR HAS OCCURRED [%s]", Time(), e))
	Chat("CALLSTACK")

	local s, l = 2
	while (s = getstackinfos(l++))
		Chat(format("*FUNCTION [%s()] %s line [%d]", s.func, s.src, s.line))
	Chat("LOCALS")

	if (!stack) return

	foreach (n, v in stack.locals)
	{
		local t = type(v)
		switch (t)
		{
			case "null":    Chat(format("[%s] NULL", n)); break
			case "integer": Chat(format("[%s] %d", n, v)); break
			case "float":   Chat(format("[%s] %.14g" , n, v)); break
			case "string":  Chat(format("[%s] \"%s\"", n, v)); break
			default:        Chat(format("[%s] %s %s", n, t, v.tostring()))
		}
	}
}
seterrorhandler(_ErrorHandler)
