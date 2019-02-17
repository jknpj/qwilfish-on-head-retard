
/obj/item/weapon/robot_module/mommi
	name = "mobile mmi robot module"
	quirk_flags = MODULE_HAS_MAGPULSE | MODULE_CAN_HANDLE_CHEMS | MODULE_CAN_BUY
	languages = list()
	sprites = list("Basic" = "mommi")
	default_modules = list()
	main_modules = list(
		/obj/item/weapon/weldingtool/largetank,
		/obj/item/weapon/screwdriver,
		/obj/item/weapon/wrench,
		/obj/item/weapon/crowbar,
		/obj/item/weapon/wirecutters,
		/obj/item/device/multitool,
		/obj/item/device/t_scanner,
		/obj/item/device/analyzer,
		/obj/item/weapon/extinguisher,
		/obj/item/weapon/extinguisher/foam,
		/obj/item/device/rcd/rpd,
		/obj/item/device/rcd/tile_painter,
		/obj/item/blueprints/mommiprints,
		/obj/item/device/material_synth/robot/mommi,
		/obj/item/device/holomap,
		/obj/item/device/station_map,
		/obj/item/device/silicate_sprayer,
		/obj/item/borg/fire_shield
		)
	syndicate_modules = list(
		/obj/item/borg/stun
		)
	respawnables = list (
		/obj/item/stack/cable_coil
		)
	respawnables_max_amount = MOMMI_MAX_COIL
	sensor_augs = list("Mesons", "Disable")
	var/ae_type = "Default" //Anti-emancipation override type, pretty much just fluffy.
	var/law_type = "Default"

//Nanotrasen's MoMMI
/obj/item/weapon/robot_module/mommi/nt
	name = "nanotrasen mobile mmi robot module"
	speed_modifier = MOMMI_NT_SPEED_MODIFIER
	networks = list(CAMERANET_ENGI)
	radio_key = /obj/item/device/encryptionkey/headset_eng
	ae_type = "Nanotrasen patented"
	sprites = list(
		"Basic" = "mommi",
		"Keeper" = "keeper",
		"Prime" = "mommiprime",
		"Prime Alt" = "mommiprime-alt",
		"Replicator" = "replicator",
		"RepairBot" = "repairbot",
		"Hover" = "hovermommi"
		)

//Derelict MoMMI
/obj/item/weapon/robot_module/mommi/soviet
	name = "russian remont robot module"
	speed_modifier = MOMMI_SOVIET_SPEED_MODIFIER
	quirk_flags = MODULE_HAS_MAGPULSE | MODULE_CAN_HANDLE_CHEMS | MODULE_CAN_BUY | MODULE_CAN_HANDLE_FOOD
	sprites = list(
		"RuskieBot" = "ruskiebot"
		)
	default_modules = list(
		/obj/item/device/rcd/borg/engineering,
		/obj/item/device/instrument/instrument_synth,
		/obj/item/device/rcd/borg/rsf/soviet,
		/obj/item/weapon/soap/syndie,
		/obj/item/weapon/pickaxe/plasmacutter,
		/obj/item/weapon/storage/bag/ore/auto
		)
	ae_type = "Начато отмену"

/obj/item/weapon/robot_module/mommi/cogspider
	name = "Gravekeeper belt of holding."
	speed_modifier = COGSPIDER_SPEED_MODIFIER
	sprites = list(
		"Gravekeeper" = "cogspider"
		)
	ae_type = "Clockwork"
	law_type = "Gravekeeper"