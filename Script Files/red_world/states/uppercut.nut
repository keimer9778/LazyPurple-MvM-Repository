::Uppercut <- class extends State
{
	name = "uppercut";
	attackRange = [0.0, 150.0];
	attackAngles = 150.0;
	cooldown = 5.0;
	canUse = false;
	duration = 1.375;
	hitTime = 0.0;

	function Start()
	{
		local scope = owner.GetScriptScope();
		scope.PlayAnimation("taunt_bare_knuckle_beatdown_outro", 0.75);
		hitTime = 0.3 * 1.25 + Time();
		cooldown = RandomFloat(4.0, 6.5);
	}

	function Think()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = target;
		if (hitTime > 0.0 && hitTime < Time())
		{
			local range = 300.0;
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
				hitTarget.TakeDamageEx(owner, owner, null, direction, owner.GetCenter(), 110.0, DMG_CLUB | DMG_RADIATION);
				EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
				entity = hitTarget,
				sound_level = 85,
				filter_type = RECIPIENT_FILTER_GLOBAL,
				pitch = RandomInt(88, 105)});

				local velocity = VectorToQAngle(hitTarget.GetOrigin() - owner.GetOrigin());
				velocity.x += 30.0;
				local fwd = velocity.Forward();
				fwd.Norm();
				local scale = 600.0 - (hitTarget.GetOrigin() - owner.GetOrigin()).Length();
				fwd.x *= scale / 4.5;
				fwd.y *= scale / 4.5;
				fwd.z += scale;
				SetPropVector(hitTarget, "m_vecBaseVelocity", fwd);
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