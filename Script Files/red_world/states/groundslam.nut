::GroundSlam <- class extends State
{
	name = "groundslam";
	attackRange = [0.0, 150.0];
	attackAngles = 360.0;
	cooldown = 5.0;
	duration = 1.116;
	hitTime = 0.0;

	function Start()
	{
		local scope = owner.GetScriptScope();
		scope.PlayAnimation("attack1");
		hitTime = 0.46 * 1.2 + Time();
		cooldown = RandomFloat(3.5, 5.5);
	}

	function Think()
	{
		if (hitTime > 0.0 && hitTime < Time())
		{
			local range = 350.0;
			for (local hitTarget; hitTarget = FindByClassname(hitTarget, "player");)
			{
				if (hitTarget == null || !hitTarget.IsValid() || !hitTarget.IsAlive() || IsPlayerABot(hitTarget) || hitTarget.GetTeam() != 2)
				{
					continue;
				}

				if (!IsTargetInMeleeChecks(hitTarget, range, 360.0))
				{
					continue;
				}

				local direction = hitTarget.GetOrigin() - owner.GetCenter();
				direction.Norm();
				direction.Scale(20.0);
				hitTarget.TakeDamageEx(owner, owner, null, direction, owner.GetCenter(), 75.0, DMG_CLUB);
				EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/tank_punch_01.mp3",
				entity = hitTarget,
				sound_level = 85,
				filter_type = RECIPIENT_FILTER_GLOBAL,
				pitch = RandomInt(88, 105)});
			}
			local particle = SpawnEntityFromTable("info_particle_system",
			{
				effect_name = "hammer_impact_button",
				start_active = 1,
				origin = owner.GetOrigin(),
				angles = owner.GetAbsAngles()
			});
			EntFireByHandle(particle, "Kill", null, 0.1, null, null);
			for (local temp; temp = FindByClassnameWithin(temp, "player", owner.GetOrigin(), 750.0);)
			{
				if (temp == null || !temp.IsValid() || !temp.IsAlive() || IsPlayerABot(temp) || temp.GetTeam() != 2)
				{
					continue;
				}

				if (!IsTargetInMeleeChecks(temp, range, 750.0))
				{
					continue;
				}

				if (temp.GetOrigin().z > owner.GetOrigin().z + 80.0)
				{
					continue;
				}

				local velocity = VectorToQAngle(temp.GetOrigin() - owner.GetOrigin());
				velocity.x += 30.0;
				local fwd = velocity.Forward();
				fwd.Norm();
				local scale = 900.0 - (temp.GetOrigin() - owner.GetOrigin()).Length();
				fwd.x *= scale;
				fwd.y *= scale;
				fwd.z += scale / 2.0;
				SetPropVector(temp, "m_vecBaseVelocity", fwd);
			}
			hitTime = -1.0;
		}
	}

	function End()
	{
		local scope = owner.GetScriptScope();
		scope.ResetAnimation();
	}
}

PrecacheSound(")mentrillum/mvm/sfx/tank_punch_01.mp3");