IncludeScript("tankextensions_main", getroottable())

TankExt.SetValueOverrides
({
TARGETANK_COLOR1 = "0 0 255"
TARGETANK_COLOR2 = "100 255 255"
TARGETANK_RECHARGE_DURATION = 0
TARGETANK_IMPACT_DAMAGE = 100
TARGETANK_SND_IMPACT = "DemoCharge.HitFlesh"
})

IncludeScript("tankextensions/targetank", getroottable())

timer <- null

function SetTankCargeDuration()
{
	if (timer != null)
	{
		timer.Destroy();
		timer = null;
	}

	TankExt.SetValueOverrides
	({
		TARGETANK_RECHARGE_DURATION = 0
	})
	timer = Entities.CreateByClassname("logic_relay")

	timer.ValidateScriptScope()
	local scope = timer.GetScriptScope()

	scope.OnTrigger <- ChangeTankCargeDuration

	timer.ConnectOutput("OnTrigger", "ChangeTankCargeDuration")

	EntFireByHandle( timer, "Trigger", "", 0.05, null, null )
}

function ChangeTankCargeDuration()
{
	timer.Destroy();
	timer = null;
	TankExt.SetValueOverrides
	({
		TARGETANK_RECHARGE_DURATION = 14.5
	})
}

function SetTankCargeDurationEx()
{
	if (timer != null)
	{
		timer.Destroy();
		timer = null;
	}

	TankExt.SetValueOverrides
	({
		TARGETANK_RECHARGE_DURATION = 0
		TARGETANK_COLOR1 = "255 0 0"
		TARGETANK_COLOR2 = "76 0 255"
		TARGETANK_CHARGE_DURATION = 5
		TARGETANK_CHARGE_SPEED = 240
	})
	timer = Entities.CreateByClassname("logic_relay")

	timer.ValidateScriptScope()
	local scope = timer.GetScriptScope()

	scope.OnTrigger <- ChangeTankCargeDurationEx

	timer.ConnectOutput("OnTrigger", "ChangeTankCargeDurationEx")

	EntFireByHandle( timer, "Trigger", "", 0.05, null, null )
}

function ChangeTankCargeDurationEx()
{
	timer.Destroy();
	timer = null;
	TankExt.SetValueOverrides
	({
		TARGETANK_RECHARGE_DURATION = 20.0
	})
}
