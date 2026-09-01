::EyeLaser <- class extends State
{
	name = "eye_laser";
	attackRange = [250.0, 650.0];
	attackAngles = 100.0;
	canUse = false;
	cooldown = 5.0;
	duration = 2.1;
	laserStart = 0.4;
	laserDuration = -1.0;
	laserTick = 0.0;
	targetEntity = null;
	laserEntities = [];

	function Start()
	{
		local scope = owner.GetScriptScope();
		scope.PlayAnimation("taunt_unleashed_rage_heavy");
		laserStart = 0.4 + Time();
		laserDuration = -1.0;
		EmitSoundEx({sound_name = ")mentrillum/mvm/sfx/attack_chestbeam.wav",
		entity = owner,
		sound_level = 90,
		filter_type = RECIPIENT_FILTER_GLOBAL});
		cooldown = RandomFloat(15.0, 25.0);
	}

	function Think()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = target;
		if (target == null)
		{
			return;
		}

		local time = Time();

		if (laserStart > 0.0 && laserStart < time)
		{
			laserDuration = 1.1 + time;
			laserStart = -1.0;
		}

		ResetLaserVisuals();
		if (laserDuration <= 0.0 || laserDuration < time)
		{
			return;
		}

		local trace =
		{
			start = owner.EyePosition(),
			end = target.GetCenter(),
			mask = 33636363,
			ignore = owner
		}

		TraceLineEx(trace);
		local endPoint = trace.endpos;
		targetEntity = SpawnEntityFromTable("info_target", {
			origin = endPoint
		});
		for (local i = 0; i < 2; i++)
		{
			local attachment = format("eye_boss_%i", i + 1);
			local pos = owner.GetAttachmentOrigin(owner.LookupAttachment(attachment));
			local laser = SpawnEntityFromTable("env_beam", {
				origin = pos,
				lightningstart = "bignet",
				lightningend = "bignet",
				boltwidth = 20,
				life = 0,
				NoiseAmplitude = 4.0,
				texture = "sprites/laser.vmt",
				rendercolor = "255 0 0",
				framerate = 60,
				spawnflags = 1
			});
			SetPropEntityArray(laser, "m_hAttachEntity", laser, 0);
			SetPropEntityArray(laser, "m_hAttachEntity", targetEntity, 1);
			laserEntities.push(laser);
			laser.SetAbsOrigin(pos);
			laser.AcceptInput("TurnOn", null, null, null);
		}

		if (laserTick > time)
		{
			return;
		}

		if (trace.hit)
		{
			local hit = trace.enthit;
			if (hit == null || !hit.IsValid() || hit.GetTeam() != 2)
			{
				return;
			}

			hit.TakeDamageEx(owner, owner, null, Vector(), endPoint, 15.0, DMG_SHOCK | DMG_ALWAYSGIB | DMG_SLOWBURN);
		}
		laserTick = time + 0.1;
	}

	function End()
	{
		local scope = owner.GetScriptScope();
		scope.AlwaysLookAtTarget = null;
		scope.ResetAnimation();

		ResetLaserVisuals();
	}

	function ResetLaserVisuals()
	{
		if (laserEntities.len() > 0)
		{
			for (local i = 0; i < laserEntities.len(); i++)
			{
				laserEntities[i].Kill();
			}
			laserEntities.clear();
		}
		if (targetEntity != null)
		{
			targetEntity.Kill();
			targetEntity = null;
		}
	}
}

PrecacheSound(")mentrillum/mvm/sfx/attack_chestbeam.wav");