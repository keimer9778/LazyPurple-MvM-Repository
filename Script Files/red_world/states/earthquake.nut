::Earthquake <- class extends State
{
	name = "earthquake";
	attackRange = [0.0, 375.0];
	attackAngles = 360.0;
	cooldown = 7.0;
	duration = 1.61;
	hitTime = 0.0;

	function Start()
	{
		local scope = owner.GetScriptScope();
		scope.PlayAnimation("attack3");
		hitTime = 0.32 * 1.15 + Time();
		cooldown = RandomFloat(7.0, 14.0);
	}

	function Think()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = target;
		if (hitTime > 0.0 && hitTime < Time())
		{
			RedWorld.StartQuakeExplosions(owner);
			hitTime = -1.0;
		}
	}

	function End()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = null;
		scope.ResetAnimation();
	}
}
