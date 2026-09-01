::Slash <- class extends State
{
	name = "slash";
	attackRange = [0.0, 150.0];
	attackAngles = 150.0;
	cooldown = 5.0;
	duration = 0.852;
	hitTime = 0.0;

	function Start()
	{
		local scope = owner.GetScriptScope();
		scope.PlayAnimation("attack2", 0.8);
		hitTime = 0.4 * 1.2 + Time();
		cooldown = RandomFloat(3.0, 5.5);
	}

	function Think()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = target;
		if (hitTime > 0.0 && hitTime < Time())
		{
			local range = 250.0;
			for (local hitTarget; hitTarget = FindByClassname(hitTarget, "player");)
			{
				if (hitTarget == null || !hitTarget.IsValid() || !hitTarget.IsAlive() || IsPlayerABot(hitTarget) || hitTarget.GetTeam() != 2)
				{
					continue;
				}

				if (!IsTargetInMeleeChecks(hitTarget, range, 140.0))
				{
					continue;
				}

				local direction = hitTarget.GetOrigin() - owner.GetCenter();
				direction.Norm();
				direction.Scale(20.0);
				hitTarget.TakeDamageEx(owner, owner, null, direction, owner.GetCenter(), 90.0, DMG_CLUB);
				EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
				entity = hitTarget,
				sound_level = 85,
				filter_type = RECIPIENT_FILTER_GLOBAL,
				pitch = RandomInt(88, 105)});
			}
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