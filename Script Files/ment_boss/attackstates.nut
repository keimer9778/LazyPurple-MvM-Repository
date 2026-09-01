IncludeScript("trace_filter")

class State
{
	owner = null;
	target = null;
	name = "";
	attackRange = [0.0, 200.0]; // Min, max
	attackAngles = 120.0;
	cooldown = 0.0;
	canUse = true;
	canUseThroughWalls = false;
	duration = 0.0;
	currentDuration = 0.0;

	function Initialize(newOwner, newTarget = null)
	{
		owner = newOwner;
		target = newTarget;
	}

	function StartPre()
	{
		currentDuration = duration + Time();
		local scope = owner.GetScriptScope();
		scope.OnAttackStart(name);
		Start();
	}

	function EndPre()
	{
		local scope = owner.GetScriptScope();
		scope.SetAttackState(null);
		scope.OnAttackEnd(name);
		End();
		scope.SetNextAttackTime(name, cooldown + Time());
	}

	function ForceEnd()
	{
		local scope = owner.GetScriptScope();
		scope.OnAttackEnd(name);
		End();
		scope.SetNextAttackTime(name, cooldown + Time());
	}

	function ThinkPre()
	{
		local scope = owner.GetScriptScope();
		if (scope.BestTarget != null && scope.BestTarget != GetTarget())
		{
			SetTarget(scope.BestTarget);
		}
		if (currentDuration <= Time())
		{
			EndPre();
			return;
		}
		Think()
	}

	function GetTarget()
	{
		return target;
	}

	function SetTarget(newTarget = null)
	{
		target = newTarget;
	}

	function IsTargetInMeleeChecks(target, range, fov, doTrace = true)
	{
		if (target == null || !target.IsValid())
		{
			return false;
		}

		local targetPos = target.GetOrigin();
		local myPos = owner.GetOrigin();
		local myEyePos = owner.GetCenter();
		local myAng = owner.GetAbsAngles();

		local distance = (myPos - targetPos).LengthSqr();
		if (distance > pow(range, 2.0))
		{
			return false;
		}

		local direction = VectorToQAngle(targetPos - myPos);
		local currentFOV = fabs(AngleNormalize(direction.y - myAng.y));
		if (currentFOV > fov)
		{
			return false;
		}

		if (doTrace)
		{
			local player = owner;
			local trace =
			{
				start = myEyePos,
				end = targetPos,
				mask = 33636363,
				ignore = owner,
				filter = function(entity)
				{
					if (entity.IsPlayer() && entity.GetTeam() == player.GetTeam())
					{
						return TRACE_STOP;
					}

					return TRACE_CONTINUE;
				}
			}
			TraceLineFilter(trace);
			if (trace.hit && trace.enthit != target)
			{
				return false;
			}
		}

		return true;
	}

	function Start() { }

	function End() { }

	function Think() { }
}

function HookAttacksOnBot(player, attacks)
{
	if (player.GetScriptScope() == null)
	{
		player.ValidateScriptScope();
	}
	local scope = player.GetScriptScope();
	scope.CurrentState <- null;
	scope.BestTarget <- null;
	scope.TargetVisible <- false;
	scope.ShouldAttack <- true;
	scope.IsAttacking <- false;
	scope.ValidAttacks <- attacks;
	scope.NextAttackTime <- {};
	scope.FOV <- 165.0;
	scope.CurrentAnimation <- null;
	scope.ExtraWearables <- [];
	scope.PreExtraWearables <- [];
	scope.ExtraWearablesDirectories <- [];
	scope.ExtraWearablesIndexes <- [];
	scope.ShouldAlwaysGlow <- true;

	scope.PlayAnimation <- function(animName, rate = 1.0, cycle = 0.0)
	{
		local create = false;
		local position = self.GetOrigin();
		local rotation = self.GetAbsAngles();
		local animation = scope.CurrentAnimation;
		for (local i = 0; i < scope.PreExtraWearables.len(); i++)
		{
			if (scope.PreExtraWearables[i] != null && scope.PreExtraWearables[i].IsValid())
			{
				scope.PreExtraWearables[i].Destroy();
			}
		}
		if (animation == null || !scope.CurrentAnimation.IsValid())
		{
			create = true;
			scope.ResetAnimation();
			animation = SpawnEntityFromTable("prop_dynamic", {
				origin = position,
				angles = rotation,
				modelscale = self.GetModelScale(),
				skin = self.GetTeam() == 3 ? 1 : 0,
				model = self.GetModelName(),
				defaultanim = "stand_melee"
			});
		}
		NetProps.SetPropInt(self, "m_nRenderMode", 10);
		self.AddCustomAttribute("no_attack", 1, -1.0);
		self.AddCustomAttribute("no_jump", 1, -1.0);
		self.AddCustomAttribute("no_duck", 1, -1.0);
		self.AddCond(87); // Freeze input, doesn't work in vanilla but is for Rafmod

		scope.PreExtraWearables.clear();
		scope.PreSetAnimation(animation, create);
		for (local i = 0; i < scope.PreExtraWearables.len(); i++)
		{
			local wearable = scope.PreExtraWearables[i];
			wearable.AcceptInput("SetParent", "!activator", animation, null);
			NetProps.SetPropInt(wearable, "m_fEffects", 129);
			wearable.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
			scope.ExtraWearables.append(wearable);
		}

		scope.ExtraWearablesDirectories.clear();
		scope.ExtraWearablesIndexes.clear();
		for (local wearable; wearable = Entities.FindByClassname(wearable, "tf_wearable*");)
		{
			if (wearable == null || wearable.GetOwner() != self)
			{
				continue;
			}

			local model = wearable.GetModelName();
			local abbreviation = "";

			switch (self.GetPlayerClass())
			{
				case 1: // Scout
				{
					abbreviation = "scout";
					break;
				}

				case 2: // Sniper
				{
					abbreviation = "sniper";
					break;
				}

				case 3: // Soldier
				{
					abbreviation = "soldier";
					break;
				}

				case 4: // Demo
				{
					abbreviation = "demo";
					break;
				}

				case 5: // Medic
				{
					abbreviation = "medi";
					break;
				}

				case 6: // Heavy
				{
					abbreviation = "heavy";
					break;
				}

				case 7: // Pyro
				{
					abbreviation = "pyro";
					break;
				}

				case 8: // Spy
				{
					abbreviation = "spy";
					break;
				}

				case 9: // Engineer
				{
					abbreviation = "engineer";
					break;
				}
			}

			local armor = format("models/workshop/player/items/%s/tw_%sbot_armor/tw_%sbot_armor.mdl", abbreviation, abbreviation, abbreviation);
			local helmet = format("models/workshop/player/items/%s/tw_%sbot_helmet/tw_%sbot_helmet.mdl", abbreviation, abbreviation, abbreviation);
			if (self.GetPlayerClass() == 8) // Spy hood
			{
				helmet = format("models/workshop/player/items/%s/tw_%sbot_hood/tw_%sbot_hood.mdl", abbreviation, abbreviation, abbreviation);
			}
			else if (self.GetPlayerClass() == 1 || self.GetPlayerClass() == 5) // Scout hat
			{
				helmet = format("models/workshop/player/items/%s/tw_%sbot_hat/tw_%sbot_hat.mdl", abbreviation, abbreviation, abbreviation);
			}

			if (self.GetPlayerClass() == 5) // Medic chariot
			{
				armor = format("models/workshop/player/items/%s/tw_%sbot_chariot/tw_%sbot_chariot.mdl", abbreviation, abbreviation, abbreviation);
			}
			local buster = "models/workshop/player/items/demo/tw_sentrybuster/tw_sentrybuster.mdl";

			if (model == armor || model == helmet || model == buster)
			{
				continue;
			}

			scope.ExtraWearablesIndexes.append(NetProps.GetPropIntArray(wearable, "m_nModelIndexOverrides", 0));
			scope.ExtraWearablesDirectories.append(model);
			NetProps.SetPropInt(wearable, "m_nRenderMode", 10);
		}

		for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
		{
			if (weapon == null || weapon.GetOwner() != self)
			{
				continue;
			}

			NetProps.SetPropInt(weapon, "m_nRenderMode", 1);
			NetProps.SetPropInt(weapon, "m_clrRender", 0);
		}
		if (create)
		{
			for (local i = 0; i < scope.ExtraWearablesDirectories.len(); i++)
			{
				local wearable = SpawnEntityFromTable("prop_dynamic", {
					origin = position,
					angles = rotation,
					modelscale = 1,
					skin = self.GetTeam() == 3 ? 1 : 0,
					model = scope.ExtraWearablesDirectories[i]
				});
				for (local i2 = 0; i2 <= 3; i2++)
				{
					NetProps.SetPropIntArray(wearable, "m_nModelIndexOverrides", scope.ExtraWearablesIndexes[i], i2);
				}
				wearable.AcceptInput("SetParent", "!activator", animation, null);
				NetProps.SetPropInt(wearable, "m_fEffects", 129);
				wearable.AcceptInput("SetParentAttachmentMaintainOffset", "head", animation, null);
				scope.ExtraWearables.append(wearable);
			}
		}

		if (create)
		{
			animation.ValidateScriptScope();
			local animScope = animation.GetScriptScope();
			animScope.Think <- function()
			{
				if (!animation.IsValid())
				{
					return -1;
				}

				animation.SetLocalOrigin(player.GetOrigin());
				local angles = player.GetAbsAngles();
				angles.x = 0.0;
				angles.z = 0.0;
				animation.SetAbsAngles(angles);
				return -1;
			}
			AddThinkToEnt(animation, "Think");
		}

		animation.AcceptInput("SetAnimation", animName, null, null);
		EntFireByHandle(animation, "SetCycle", (cycle + 0.02).tostring(), 0.02, null, null);
		NetProps.SetPropFloat(animation, "m_flCycle", cycle);
		NetProps.SetPropFloat(animation, "m_flPlaybackRate", rate);
		scope.CurrentAnimation = animation;
		if (scope.ShouldAlwaysGlow && create)
		{
			local glow = SpawnEntityFromTable("tf_glow" {
				glowcolor = "125 168 196 255",
				target = "bignet"
			});
			NetProps.SetPropEntity(glow, "m_hTarget", animation);
			NetProps.SetPropEntity(glow, "m_hMovePeer", animation.FirstMoveChild());
			NetProps.SetPropEntity(animation, "m_hMoveChild", glow);
			NetProps.SetPropEntity(glow, "m_hMoveParent", animation);
			SetAlwaysTransmit(animation);
			scope.ExtraWearables.append(glow);
		}
	}

	scope.PreSetAnimation <- function(animation, create)
	{

	}

	scope.ResetAnimation <- function()
	{
		self.RemoveCustomAttribute("no_attack");
		self.RemoveCustomAttribute("no_jump");
		self.RemoveCustomAttribute("no_duck");
		self.RemoveCond(87);
		NetProps.SetPropInt(self, "m_nRenderMode", 0);
		NetProps.SetPropInt(self, "m_clrRender", 0xFFFFFF);
		for (local wearable; wearable = Entities.FindByClassname(wearable, "tf_wearable*");)
		{
			if (wearable == null || wearable.GetOwner() != self)
			{
				continue;
			}

			NetProps.SetPropInt(wearable, "m_nRenderMode", 0);
		}

		for (local weapon; weapon = Entities.FindByClassname(weapon, "tf_weapon*");)
		{
			if (weapon == null || weapon.GetOwner() != self)
			{
				continue;
			}

			NetProps.SetPropInt(weapon, "m_nRenderMode", 0);
			NetProps.SetPropInt(weapon, "m_clrRender", 0xFFFFFF);
		}
		if (scope.CurrentAnimation != null && scope.CurrentAnimation.IsValid())
		{
			scope.CurrentAnimation.Destroy();
			scope.CurrentAnimation = null;
		}
		if (scope.ExtraWearables.len() > 0)
		{
			for (local i = 0; i < scope.ExtraWearables.len(); i++)
			{
				if (scope.ExtraWearables[i] == null || !scope.ExtraWearables[i].IsValid())
				{
					continue;
				}
				scope.ExtraWearables[i].Destroy();
			}
		}
		scope.ExtraWearables.clear();
		scope.PostResetAnimation();
	}

	scope.PostResetAnimation <- function()
	{

	}

	scope.GetNextAttackTime <- function(name)
	{
		if (scope.NextAttackTime == null || scope.NextAttackTime.len() < 0)
		{
			return -1.0;
		}

		local val = -1.0;
		local keys = scope.NextAttackTime.keys();
		if (keys.find(name) == null)
		{
			return -1.0;
		}

		return scope.NextAttackTime.rawget(name);
	}

	scope.SetNextAttackTime <- function(name, val)
	{
		if (scope.NextAttackTime == null || scope.NextAttackTime.len() < 0)
		{
			return;
		}

		scope.NextAttackTime.rawset(name, val)
	}

	scope.AddAttackToValids <- function(attack)
	{
		scope.ValidAttacks.rawset(attack.name, attack);
	}

	scope.GetAttackFromName <- function(name)
	{
		if (scope.ValidAttacks == null || scope.ValidAttacks.len() < 0)
		{
			return null;
		}

		return scope.ValidAttacks.rawget(name);
	}

	scope.GetAttackFromIndex <- function(index)
	{
		if (scope.ValidAttacks == null || scope.ValidAttacks.len() < 0)
		{
			return null;
		}

		local keys = scope.ValidAttacks.keys();
		return scope.ValidAttacks.rawget(keys[index]);
	}

	scope.IsTargetValid <- function(target)
	{
		if (target == null || !target.IsValid())
		{
			return false;
		}

		if (!target.IsAlive())
		{
			return false;
		}

		if (target.GetTeam() == self.GetTeam() || target.GetTeam() == 1)
		{
			return false;
		}

		if (target.InCond(3) && target.GetDisguiseTeam() == self.GetTeam()) // Disguised
		{
			return false;
		}

		return true;
	}

	scope.ProcessTargets <- function()
	{
		local owner = self;
		local visionRange = self.GetMaxVisionRangeOverride();
		if (visionRange <= 0.0)
		{
			visionRange = 6000.0; // Default in Valve's code
		}

		local oldTarget = scope.BestTarget;
		if (!scope.IsTargetValid(oldTarget))
		{
			oldTarget = null;
		}
		local target = oldTarget;
		local bestTargetDist = pow(visionRange, 2.0);
		if (target != null && target.IsValid())
		{
			bestTargetDist = (self.GetOrigin() - target.GetOrigin()).LengthSqr();
			if (bestTargetDist > pow(visionRange, 2.0))
			{
				bestTargetDist = pow(visionRange, 2.0);
			}

			local trace =
			{
				start = self.GetCenter(),
				end = player.GetCenter(),
				mask = 33636363,
				ignore = self,
				filter = function(entity)
				{
					if (entity == owner)
					{
						return TRACE_STOP;
					}

					if (entity.IsPlayer() && entity.GetTeam() == owner.GetTeam())
					{
						return TRACE_STOP;
					}

					return TRACE_CONTINUE;
				}
			}
			TraceLineFilter(trace);
			scope.TargetVisible = (!trace.hit || trace.enthit == player);
		}
		else
		{
			scope.TargetVisible = false;
		}

		local valids = [];
		for (local i = 1, player; i <= MAX_CLIENTS; i++)
		{
			local player = PlayerInstanceFromIndex(i);
			if (!scope.IsTargetValid(player))
			{
				continue;
			}

			valids.append(player);
		}

		for (local i = 0; i < valids.len(); i++)
		{
			local player = valids[i];
			if (!scope.IsTargetValid(player))
			{
				continue;
			}

			local targetPos = player.GetOrigin();
			local trace =
			{
				start = self.GetCenter(),
				end = player.GetCenter(),
				mask = 33636363,
				ignore = self,
				filter = function(entity)
				{
					if (entity.IsPlayer() && entity.GetTeam() == owner.GetTeam())
					{
						return TRACE_STOP;
					}

					return TRACE_CONTINUE;
				}
			}
			TraceLineFilter(trace);
			if (trace.hit && trace.enthit != player)
			{
				continue;
			}

			local targetDist = (self.GetOrigin() - player.GetOrigin()).LengthSqr();
			if (targetDist > bestTargetDist)
			{
				continue;
			}

			local direction = VectorToQAngle(player.GetOrigin() - self.GetOrigin());
			direction.z = 180.0;
			local fov = fabs(AngleNormalize(direction.y - self.GetAbsAngles().y));

			if (fov > scope.FOV)
			{
				continue;
			}

			bestTargetDist = targetDist;
			target = player;
		}
		scope.BestTarget = target;
	}

	scope.ProcessAttacks <- function(target)
	{
		if (!scope.ShouldAttack)
		{
			return;
		}

		if (target == null || !target.IsValid())
		{
			return;
		}

		local loco = self.GetLocomotionInterface();
		local canAttack = !scope.IsAttacking;
		if (canAttack && !loco.IsOnGround())
		{
			canAttack = false;
		}

		if (!canAttack)
		{
			return;
		}

		if (scope.ValidAttacks.len() == 0)
		{
			return;
		}

		local time = Time();

		local validAttacks = [];
		for (local i = 0; i < scope.ValidAttacks.len(); i++)
		{
			local keys = scope.ValidAttacks.keys();
			local attack = scope.ValidAttacks.rawget(keys[i]);
			if (!attack.canUse)
			{
				continue;
			}

			if (!attack.canUseThroughWalls && !scope.TargetVisible)
			{
				continue;
			}

			if (time < scope.GetNextAttackTime(attack.name))
			{
				continue;
			}

			validAttacks.append(attack);
		}

		if (validAttacks.len() == 0)
		{
			return;
		}

		local eyeAng = self.GetAbsAngles();
		local pos = self.GetOrigin();
		local targetPos = target.GetOrigin();
		local direction = VectorToQAngle(targetPos - pos);
		direction.z = 180.0;

		local distance = (pos - targetPos).LengthSqr();
		local fov = fabs(AngleNormalize(direction.y - eyeAng.y));
		RandomSortArray(validAttacks);
		for (local i = 0; i < validAttacks.len(); i++)
		{
			local attack = validAttacks[i]
			if (distance > pow(attack.attackRange[1], 2.0) || distance < pow(attack.attackRange[0], 2.0))
			{
				continue;
			}
			if (fov > attack.attackAngles)
			{
				continue;
			}

			scope.SetAttackState(attack);
			break;
		}
	}

	scope.AttackThink <- function()
	{
		local state = scope.CurrentState;
		if (state != null)
		{
			state.ThinkPre();
		}
	}

	scope.SetAttackState <- function(newState)
	{
		if (scope.CurrentState != null)
		{
			scope.CurrentState.ForceEnd();
		}
		scope.CurrentState = newState;
		if (scope.CurrentState != null)
		{
			scope.CurrentState.Initialize(self, scope.BestTarget);
			scope.CurrentState.StartPre();
			scope.IsAttacking = true;
		}
		else
		{
			scope.IsAttacking = false;
		}
	}

	scope.OnAttackStart <- function(name)
	{

	}

	scope.OnAttackEnd <- function(name)
	{

	}

	scope.ToggleAttacks <- function(state)
	{
		scope.ShouldAttack = state;
		if (state)
		{
			scope.ResetAttackCooldowns();
		}
	}

	scope.ResetAttackCooldowns <- function()
	{
		for (local i = 0; i < scope.ValidAttacks.len(); i++)
		{
			local attack = scope.GetAttackFromIndex(i);
			scope.SetNextAttackTime(attack.name, attack.cooldown + Time());
		}
	}

	scope.AttackStatesThink <- function()
	{
		if (self.GetTeam() != 3 || !self.IsAlive())
		{
			scope.SetAttackState(null);
			scope.ResetAnimation();
			self.TerminateScriptScope();
			NetProps.SetPropString(self, "m_iszScriptThinkFunction", "");
			AddThinkToEnt(self, null);
			return false;
		}

		scope.ProcessTargets();
		scope.ProcessAttacks(scope.BestTarget);
		scope.AttackThink();
		return true;
	}

	scope.ResetAttackCooldowns();
}

function RandomSortArray(arr)
{
	local currentIndex = arr.len();
	while (currentIndex > 0)
	{
		local randomIndex = RandomInt(0, currentIndex - 1);
		currentIndex--;
		local temp = arr[randomIndex];
		arr[randomIndex] = arr[currentIndex];
		arr[currentIndex] = temp;
	}
}

function VectorToQAngle(Vector)
{
	local yaw, pitch
	if (Vector.y == 0.0 && Vector.x == 0.0)
	{
		yaw = 0.0
		if (Vector.z > 0.0)
		{
			pitch = 270.0
		}
		else
		{
			pitch = 90.0
		}
	}
	else
	{
		yaw = (::atan2(Vector.y, Vector.x) * 57.2958)
		while (yaw > 180.0)
		{
			yaw -= 360.0;
		}
		while (yaw < -180.0)
		{
			yaw += 360.0;
		}
		pitch = (::atan2(-Vector.z, Vector.Length2D()) * 57.2958)
		while (pitch > 180.0)
		{
			pitch -= 360.0;
		}
		while (pitch < -180.0)
		{
			pitch += 360.0;
		}
	}
	return ::QAngle(pitch, yaw, 0.0)
}

function AngleNormalize(angle)
{
	while (angle > 180.0)
	{
		angle -= 360.0;
	}
	while (angle < -180.0)
	{
		angle += 360.0;
	}
	return angle;
}

function SetAlwaysTransmit(ent)
{
	local target = SpawnEntityFromTable("info_target", {targetname = "target_alwaystransmit"})
	target.AddEFlags(EFL_IN_SKYBOX | EFL_FORCE_CHECK_TRANSMIT)
	target.AcceptInput("SetParent", "!activator", ent, null)
	target.SetLocalOrigin(Vector())
	return target;
}
