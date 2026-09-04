// ARCHIVE NOTE:
// This file was moved to the archive due to its redundancy.
// PopExtensions is no longer supported on LazyPurple's, and
// the model assignment has been recreated with Rafmod.

// Logic for making every bot look like a Heavy bot.
PopExt.AddRobotTag("bot_heavycommon", {
	OnSpawn = function(bot, _) {
		bot.SetCustomModelWithClassAnimations("models/player/" + PopExtUtil.Classes[bot.GetPlayerClass()] + ".mdl")
		PopExtUtil.PlayerRobotModel(bot, "models/bots/heavy/bot_heavy.mdl")
	},
	OnDeath = function(bot, _)
		bot.SetCustomModelWithClassAnimations("models/bots/heavy/bot_heavy.mdl")
})

PopExt.AddRobotTag("bot_heavygiant", {
	OnSpawn = function(bot, _) {
		bot.SetCustomModelWithClassAnimations("models/player/" + PopExtUtil.Classes[bot.GetPlayerClass()] + ".mdl")
		PopExtUtil.PlayerRobotModel(bot, "models/bots/heavy_boss/bot_heavy_boss.mdl")
	},
	OnDeath = function(bot, _)
		bot.SetCustomModelWithClassAnimations("models/bots/heavy_boss/bot_heavy_boss.mdl")
})
