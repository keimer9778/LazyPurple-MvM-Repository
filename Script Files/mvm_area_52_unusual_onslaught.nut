// Modified MissionAttributes Script from PopExtensionsPlus (Credit to the PopExtensionsPlus Team)
// Modified by UltimentM
Convars.SetValue("tf_forced_holiday", 8)
SpawnEntityFromTable("tf_logic_holiday", {
	targetname = "__popext_missionattr_holiday"
	holiday_type = 8
})