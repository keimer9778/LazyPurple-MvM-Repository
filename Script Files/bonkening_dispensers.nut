
if(Entities.FindByName(null, "dispenser_3") == null) 
{ 
	local dispenser_3 = SpawnEntityFromTable("obj_dispenser", {
		targetname = "dispenser_3"
		origin = "530 3940 160" // - 65
		angles = "0 0 0"
		teamnum = 2
		spawnflags = 2
		defaultupgrade = 0
		vscripts = "tankextensions/misc/sentry_removesapper"
	})
}
if(Entities.FindByName(null, "sentry_1") == null) 
{ 
	local sentry_1 = SpawnEntityFromTable("obj_sentrygun", {
		targetname = "sentry_1"
		origin = "-859 3938 195" // - 65
		angles = "0 0 0"
		teamnum = 2
		spawnflags = 10
		defaultupgrade = 0
		vscripts = "tankextensions/misc/sentry_removesapper"
	})
}
EntFire("worldspawn", "RunScriptCode", @"
	for (local dispenser_i; dispenser_i = Entities.FindByClassname(dispenser_i, `obj_dispenser`);)
	{
		NetProps.SetPropInt(dispenser_i, `m_takedamage`, 0)
	}
"
, 0.5)

// AMMO PACKS

// front right

if(Entities.FindByName(null, "new_ammo_small_1") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_1"
		origin = "3860 3150 357" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_2") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_2"
		origin = "3860 3090 357" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_3") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_3"
		origin = "3860 3030 357" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_4") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_4"
		origin = "3860 2970 357" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_5") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_5"
		origin = "3860 2910 357" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

// front left

if(Entities.FindByName(null, "new_ammo_small_6") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_6"
		origin = "3150 4990 549" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_7") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_7"
		origin = "3210 4990 549" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_8") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_8"
		origin = "3270 4990 549" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_9") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_9"
		origin = "3330 4990 549" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_10") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_10"
		origin = "3390 4990 549" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

// back left

if(Entities.FindByName(null, "new_ammo_small_11") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_11"
		origin = "1050 4470 485" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_12") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_12"
		origin = "1050 4520 485" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_13") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_13"
		origin = "1050 4570 485" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_14") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_14"
		origin = "1050 4620 485" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_15") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_15"
		origin = "1050 4670 485" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

// right back
if(Entities.FindByName(null, "new_ammo_small_16") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_16"
		origin = "1070 3655 197" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_17") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_17"
		origin = "1130 3655 197" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

if(Entities.FindByName(null, "new_ammo_small_18") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_18"
		origin = "1510 3170 197" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_19") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_19"
		origin = "1510 3120 197" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_20") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_20"
		origin = "1510 3070 197" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

// very back

if(Entities.FindByName(null, "new_ammo_small_21") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_21"
		origin = "-1380 3920 165" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_22") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_22"
		origin = "-1380 3990 165" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}
if(Entities.FindByName(null, "new_ammo_small_23") == null) 
{ 
	SpawnEntityFromTable("item_ammopack_small", {
		targetname = "new_ammo_small_23"
		origin = "-1380 4060 165" // - 65
		angles = "0 0 0"
		teamnum = 2
		automaterialize = 1
	})
}

// these would mess with sniper bots...
/*
if(Entities.FindByName(null, "dispenser_1") == null) 
{   
	local dispenser_1 = SpawnEntityFromTable("obj_dispenser", {
		targetname = "dispenser_1"
		origin = "3180 4955 544" // - 65
		angles = "0 -90 0"
		teamnum = 2
		spawnflags = 2
		defaultupgrade = 0
		vscripts = "tankextensions/misc/sentry_removesapper"
	})
}
if(Entities.FindByName(null, "dispenser_2") == null) 
{ 
	local dispenser_2 = SpawnEntityFromTable("obj_dispenser", {
		targetname = "dispenser_2"
		origin = "3000 2580 480" // - 65
		angles = "0 90 0"
		teamnum = 2
		spawnflags = 2
		defaultupgrade = 0
		vscripts = "tankextensions/misc/sentry_removesapper"
	})
}
*/