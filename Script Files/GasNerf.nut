// Gas Passer nerf for Potato.TF servers.

local itemdef_netprop = "m_AttributeManager.m_Item.m_iItemDefinitionIndex"

::__potato.GasNerf <- {

    __gas_damage_recharge_rate  = 3000.0
    __gas_passive_recharge_rate = 120.0
    __gas_loss_on_death         = false
    // __gas_damage_mult        = ( 90 / 350 ) //used for dmg penalty vs players
    __gas_damage_amount         = 150.0
    __gas_reignite_immune_time  = 5.0
    __damage_range              = Convars.GetFloat("tf_damage_range")

    Events = {

        function OnGameEvent_post_inventory_application(params)
        {
            local player = GetPlayerFromUserID(params.userid)

            if (player.IsBotOfType(1337))
                return

            local scope = player.GetScriptScope()

            if (!scope)
            {
                player.ValidateScriptScope()
                scope = player.GetScriptScope()
            }

            // only check pyro
            if (player.GetPlayerClass() == 7)
            {
                // find gas and phlog in our loadout
                for (local i = 0; i < 7; i++)
                {
                    local wep = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i)

                    if (wep == null)
                        continue

                    if (NetProps.GetPropInt(wep, itemdef_netprop) == 1180)
                        scope.gaswep <- wep
                    else if (NetProps.GetPropInt(wep, itemdef_netprop) == 594)
                        scope.phlogwep <- wep
                }

                // no gas equipped
                if (!("gaswep" in scope) || !scope.gaswep || !scope.gaswep.IsValid())
                    return

                local attrib_damagerate = "item_meter_damage_for_full_charge"
                local attrib_chargerate = "item_meter_charge_rate"

                local gas = scope.gaswep

                local passive_rate = __gas_passive_recharge_rate
                local damage_rate = __gas_damage_recharge_rate / gas.GetAttribute("mult_item_meter_charge_rate", 1.0)

                //apply rebalance attribs
                if (gas.GetAttribute("explode_on_ignite", 0.0))
                {
                    if (gas.GetAttribute(attrib_damagerate, 0.0) != damage_rate)
                        gas.AddAttribute(attrib_damagerate, damage_rate, -1)

                    if (gas.GetAttribute(attrib_chargerate, 0.0) != passive_rate)
                        gas.AddAttribute(attrib_chargerate, passive_rate, -1)

                    gas.AddAttribute("ragdolls become ash", 1.0, -1)

                    gas.ReapplyProvision()

                    // Start empty on spawn
                    // m_bRegenerating is true when switching loadouts with tf_respawn_on_loadoutchange 1 and touching a resupply cabinet
                    if (__gas_loss_on_death && !NetProps.GetPropBool(player, "m_Shared.m_bInUpgradeZone") && !NetProps.GetPropBool(player, "m_bRegenerating"))
                    {
                        NetProps.SetPropIntArray(player, "m_iAmmo", 0, 4)
                        NetProps.SetPropFloatArray(player, "m_Shared.m_flItemChargeMeter", 0.0, 1)
                    }
                }
                // refunded explode on ignite
                else
                {
                    gas.AddAttribute(attrib_damagerate, 750.0, -1)
                    gas.AddAttribute(attrib_chargerate, 60.0, -1)
                    gas.ReapplyProvision()
                }
            }
        }

        function OnGameEvent_player_team( params )
        {
            local player = GetPlayerFromUserID(params.userid)

            // remove takedamage flag from bots on respawn
            // validity checks are due to rafmod deleting the player reference in player_team or something

            if (player && player.IsValid() && player.IsBotOfType(1337) && player.IsEFlagSet(Constants.FEntityEFlags.EFL_IS_BEING_LIFTED_BY_BARNACLE))
                player.RemoveEFlags(Constants.FEntityEFlags.EFL_IS_BEING_LIFTED_BY_BARNACLE)
        }

        function OnGameEvent_player_say(params)
        {
            local player = GetPlayerFromUserID(params.userid)

			local valid_chars = {
				[33] = "!",
				[46] = ".",
				[47] = "/",
				[63] = "?",
				[92] = "\\",
			}
            local text = params.text.tolower()

            if (text[0] in valid_chars && text.slice(1) == "gas")
            {
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x07F5B111GAS REBALANCE:")
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, format("\x01- Damage reduced:\x07F5B111 350\x01 → \x07F5B111%d", __gas_damage_amount))
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, format("\x01- Damage for full charge:\x07F5B111 750\x01 → \x07F5B111%d", __gas_damage_recharge_rate))
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, format("\x01- Passive recharge:\x07F5B111 60\x01 → \x07F5B111%d", __gas_passive_recharge_rate))
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x01- Damage charging\x07F5B111 does not scale with charge rate upgrades\x01")
                if (__gas_loss_on_death) ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x01- Gas meter\x07F5B111 does not save between lives\x01")
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x01- Crit damage\x07F5B111 does not contribute to charge\x01")
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x01- Can now be resisted by\x07F5B111 fire resistance")
                ClientPrint(player, Constants.EHudNotify.HUD_PRINTTALK, "\x01- Explosions\x07F5B111 no longer stack\x01")
            }
        }

        // override gas damage completely
        // was originally just going to use "dmg penalty vs players" but it's easier to fix stacking explosions this way and set absolute damage amounts instead of multipliers
        function OnScriptHook_OnTakeDamage( params )
        {
            local weapon = params.weapon
            local attacker = params.attacker
            local victim = params.const_entity

            if (!attacker) return

            local attacker_scope = attacker.GetScriptScope()

            // ignore bots and null ents
            if (!weapon || !attacker.IsPlayer() || attacker.IsBotOfType(1337)) return

            local gaswep   = "gaswep" in attacker_scope ? attacker_scope.gaswep : null
            local phlogwep = "phlogwep" in attacker_scope ? attacker_scope.phlogwep : null

            if (!gaswep || !gaswep.IsValid() || !gaswep.GetAttribute("explode_on_ignite", 0.0))
                return

            local chargemeter_netprop = "m_Shared.m_flItemChargeMeter"
            local gasmeter = NetProps.GetPropFloatArray(attacker, chargemeter_netprop, 1)

            if ( attacker_scope && weapon != gaswep )
            {
                // sometimes the meter is full but gas doesn't replenish
                if (gasmeter >= 100.0 && NetProps.GetPropIntArray(attacker, "m_iAmmo", 4) < 1)
                {
                    NetProps.SetPropIntArray(attacker, "m_iAmmo", 1, 4)
                    return
                }
                local damage_type = params.damage_type

                // local charge_per_tick = ((Time() + passive_rate) / Time()) / passive_rate

                // bad hack for crit charging, works but we should modify the meter directly instead
                // was skill issuing before by ignoring the charge rate upgrade value I think
                // according to the code, formula is: current meter + ( (damage / ( damage to charge * charge rate upgrade value ) ) * 100.0 )
                local damage_rate = __gas_damage_recharge_rate / gaswep.GetAttribute("mult_item_meter_charge_rate", 1.0)
                local attrib_damagerate = "item_meter_damage_for_full_charge"
                if (damage_type & Constants.FDmgType.DMG_ACID)
                {
                    local damage_mult = 1.0
                    local attacker_weapon = attacker.GetActiveWeapon()

                    // handle damage range calculations for the dragons fury so crit build time is consistent with non-crits
                    if (attacker_weapon && attacker_weapon.GetClassname() == "tf_weapon_rocketlauncher_fireball")
                    {
                        local damage_range = __damage_range
                        local distance = (victim.GetCenter() - attacker.GetCenter()).Length()
                        local optimal_distance = 512
                        local center = distance / optimal_distance

                        center = center > 2.5 ? 2.5 : center < 0.5 ? 0.5 : center

                        damage_mult = (1.0 - (center * damage_range)) + damage_range
                        damage_mult = damage_mult < 0.5 ? 0.5 : damage_mult > 1.2 ? 1.2 : damage_mult
                    }

                    gaswep.RemoveAttribute(attrib_damagerate)
                    gaswep.AddAttribute(attrib_damagerate, (damage_rate * (3 / damage_mult)), -1)
                    gaswep.ReapplyProvision()
                }
                else if (!(damage_type & Constants.FDmgType.DMG_ACID) && gaswep.GetAttribute(attrib_damagerate, 0.0) != damage_rate)
                {
                    gaswep.RemoveAttribute(attrib_damagerate)
                    gaswep.AddAttribute(attrib_damagerate, damage_rate, -1)
                    gaswep.ReapplyProvision()
                }
            }

            // ignore flagged victims to avoid infinite loops, check for gas index, check if TF_DMG_CUSTOM_BURN and check dmg amount
            else if (params.damage_stats == Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING && params.damage == 350 && NetProps.GetPropInt(weapon, itemdef_netprop) == 1180)
            {
                params.damage = 0
                params.early_out = true
                if (!victim.IsEFlagSet(Constants.FEntityEFlags.EFL_IS_BEING_LIFTED_BY_BARNACLE))
                {
                    // investigate DMG_PLASMA (16777216), damage type when first igniting enemies, Constants.FDmgType.DMG_BURN|Constants.FDmgType.DMG_PREVENT_PHYSICS_FORCE is afterburn

                    // NOTE: Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING is what controls the flamethrower killicon, we remove it to set a custom one
                    // unfortunately it is also used to stop the gas from recharging on itself
                    // setting lifestate to dead right before damage will cause pGenericMeterUser->ShouldUpdateMeter to return false
                    // victim.TakeDamageCustom(__gas_inflictor_dummy, attacker, gaswep, Vector(), victim.GetOrigin(), damage_amount, Constants.FDmgType.DMG_BURN|Constants.FDmgType.DMG_PREVENT_PHYSICS_FORCE, Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING)

                    local gas_killicon = __gas_inflictor_dummy

                    gas_killicon.KeyValueFromString("classname", "firedeath")

                    // don't charge phlog
                    if (phlogwep && phlogwep.IsValid())
                        phlogwep.AddAttribute("mod soldier buff type", 4.0, -1)

                    // non-alive lifestate fixes self-recharging when not using Constants.ETFDmgCustom.TF_DMG_CUSTOM_BURNING
                    if (attacker.IsAlive())
                    {
                        NetProps.SetPropInt(attacker, "m_lifeState", 1)
                        victim.TakeDamageEx(gas_killicon, attacker, gaswep, Vector(), victim.GetOrigin(), __gas_damage_amount, Constants.FDmgType.DMG_BURN|Constants.FDmgType.DMG_PREVENT_PHYSICS_FORCE)
                        NetProps.SetPropInt(attacker, "m_lifeState", 0)
                    }
                    else
                        victim.TakeDamageEx(gas_killicon, attacker, gaswep, Vector(), victim.GetOrigin(), __gas_damage_amount, Constants.FDmgType.DMG_BURN|Constants.FDmgType.DMG_PREVENT_PHYSICS_FORCE)

                    // set it back or else it'll get cleaned up, preserved ents use classname checks
                    gas_killicon.KeyValueFromString("classname", "entity_saucer")

                    if (phlogwep && phlogwep.IsValid())
                        phlogwep.AddAttribute("mod soldier buff type", 5.0, -1)

                    // flag to avoid infinite TakeDamage loops
                    victim.AddEFlags(Constants.FEntityEFlags.EFL_IS_BEING_LIFTED_BY_BARNACLE)

                    // allow for re-ignite after a delay
                    EntFireByHandle(victim, "runscriptcode", "self.RemoveEFlags(Constants.FEntityEFlags.EFL_IS_BEING_LIFTED_BY_BARNACLE)", __gas_reignite_immune_time, null, null)
                }
            }
            return false
        }
    }
}

::__potato.GasNerf.Events.setdelegate(::__potato.GasNerf)
::__potato.GasNerf.setdelegate(::__potato)
__CollectGameEventCallbacks(__potato.GasNerf.Events)

//ents must be created and inserted after the class is initialized
for (local dummy; dummy = Entities.FindByName(dummy, "__gas_killicon");)
    EntFireByHandle(dummy, "Kill", "", -1, null, null)

__potato.GasNerf.__gas_inflictor_dummy <- SpawnEntityFromTable("entity_saucer", {targetname = "__gas_killicon"})
__potato.GasNerf.__gas_inflictor_dummy.DisableDraw()
