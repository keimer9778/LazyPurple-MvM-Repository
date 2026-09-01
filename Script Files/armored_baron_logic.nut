PrecacheModel("models/bots/demo_boss/bot_demo_boss_gibby.mdl" )

local BASE_ARMOR = 1500
local DMG_ARMORLESS= 0
local ARMOR_UNTOUCHABLE = false

::baronLogic <- {
    function OnScriptHook_OnTakeDamage(params)
    {
        if (params.attacker == null || params.attacker.GetClassname() == "worldspawn") return

        local bot = params.const_entity

        if (bot.GetClassname() != "player") return
        if (!bot.IsBotOfType(TF_BOT_TYPE)) return
        if (!bot.HasBotTag("bot_armored_baron")) return
        if (ARMOR_UNTOUCHABLE)
        {
            DMG_ARMORLESS += params.damage * (params.damage_type & DMG_ACID ? 3 : 1) * 1.25
            if (DMG_ARMORLESS >= 30000)
            {
                bot.AddCustomAttribute("dmg from ranged reduced", 0.1, -1)
                bot.AddCustomAttribute("major move speed bonus", 0.5, -1)
                DispatchParticleEffect("powerup_supernova_explode_blue", bot.GetOrigin(), Vector(0, 0, 0))
                BASE_ARMOR = 1500
                ARMOR_UNTOUCHABLE = false
                ClientPrint(null, 3, "ARMOR REGENERATED")
                DMG_ARMORLESS = 0
            }
            return
        }
        if (!(params.damage_type & 128)) return

        BASE_ARMOR -= params.damage
        bot.SetHealth(bot.GetHealth() + params.damage * (params.damage_type & DMG_ACID ? 3 : 1))
        if (BASE_ARMOR <= 0)
        {
            bot.AddCustomAttribute("dmg from ranged reduced", 1.25, -1)
            bot.AddCustomAttribute("major move speed bonus", 1.5, -1)
            DispatchParticleEffect("fireSmokeExplosion3", bot.GetOrigin(), Vector(0, 0, 80))
            PopExtUtil.StunPlayer(bot, 2.5, 1, 0, 0.5)
            bot.AddCondEx(109, 25, null)
            bot.AddCondEx(113, 30, null)
            ARMOR_UNTOUCHABLE = true
            ClientPrint(null, 3, "ARMOR BROKEN")
        }
    }
}

__CollectGameEventCallbacks(baronLogic);