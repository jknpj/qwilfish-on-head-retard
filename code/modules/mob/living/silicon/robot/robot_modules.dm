/obj/item/weapon/robot_module
	name = "robot module"
	w_class = W_CLASS_GIANT

	var/speed_modifier = CYBORG_STANDARD_SPEED_MODIFIER

	//Quirks
	var/quirk_flags = null

	//Icons
	var/list/sprites = list()

	//Modules
	var/list/default_modules = list(  //List with our default modules. All cyborgs start with these.
		/obj/item/device/flashlight,
		/obj/item/device/flash
		)
	var/list/main_modules = list() //List our main modules, unique to each module type.
	var/list/syndicate_modules = list() //Modules added when getting emagged
	var/list/clockwork_modules = list() //Clockwork crap
	var/list/modules = list() ///holds all the usable modules
	var/list/upgrades = list() //List of upgrades applied to this module
	
	var/obj/item/borg/upgrade/jetpack = null

	//HUD
	var/list/sensor_augs
	var/module_holder = "nomod"

	//Languages
	var/list/languages = list()
	var/list/added_languages = list() //Bookkeeping

	//Radio
	var/radio_key = null

	//Camera
	var/list/networks = list()
	var/list/added_networks = list() //Bookkeeping

	//Respawnables
	var/recharge_tick = 0
	var/list/respawnables = list()
	var/respawnables_max_amount = 0

/obj/item/weapon/robot_module/Destroy()
	if(isrobot(loc))
		var/mob/living/silicon/robot/R = loc
		RemoveStatusFlags(R)
		RemoveCameraNetworks(R)
		ResetEncryptionKey(R)
		UpdateModuleHolder(R, TRUE)
		R.remove_module() //Helps remove screen references on robot end

		for(var/obj/A in modules)
			if(istype(A, /obj/item/weapon/storage) && loc)
				var/obj/item/weapon/storage/S = A
				S.empty_contents_to(loc)
	default_modules = null
	main_modules = null
	syndicate_modules = null
	clockwork_modules = null
	modules = null
	upgrades = null
	jetpack = null
	..()

/obj/item/weapon/robot_module/emp_act(severity)
	if(modules)
		for(var/obj/O in modules)
			O.emp_act(severity)
	..()


/obj/item/weapon/robot_module/initialize()
	. = ..()
	for(var/i in default_modules)
		var/obj/I = new i(src)
		default_modules += I
		default_modules -= i
	for(var/i in main_modules)
		var/obj/I = new i(src)
		main_modules += I
		main_modules -= i
	for(var/i in syndicate_modules)
		var/obj/I = new i(src)
		syndicate_modules += I
		syndicate_modules -= i
	for(var/i in clockwork_modules)
		var/obj/I = new i(src)
		clockwork_modules += I
		clockwork_modules -= i
	respawn_consumable(fully_respawn = TRUE)

/obj/item/weapon/robot_module/proc/insert_module(obj/I, rebuild = TRUE)
	if(istype(I, /obj/item/stack))
		respawnables += I.type
	if(I.loc != src)
		I.forceMove(src)
	modules += I
	if(rebuild)
		rebuild()
	return I

/obj/item/weapon/robot_module/proc/remove_module(obj/I, delete_after)
	modules -= I
	if(delete_after)
		qdel(I)

/obj/item/weapon/robot_module/New(var/mob/living/silicon/robot/R)
	. = ..()
	add_languages(R)
	AddToProfiler()
	UpdateModuleHolder(R)
	AddCameraNetworks(R)
	AddEncryptionKey(R)
	ApplyStatusFlags(R)

/obj/item/weapon/robot_module/proc/UpdateModuleHolder(var/mob/living/silicon/robot/R, var/reset = FALSE)
	if(R.hands) //To prevent runtimes when spawning borgs with forced module and no client.
		if(reset)
			R.hands.icon_state = initial(R.hands.icon_state)
		else
			if(module_holder)
				R.hands.icon_state = module_holder

/obj/item/weapon/robot_module/proc/AddCameraNetworks(var/mob/living/silicon/robot/R)
	if(!R.camera && networks.len > 0) //Alright this module adds the borg to a CAMERANET but it has no camera, so we give it one.
		R.camera = new /obj/machinery/camera(R)
		R.camera.c_tag = R.real_name
		R.camera.network = list() //Empty list to prevent it from appearing where it isn't supposed to.
	if(R.camera)
		for(var/network in networks)
			if(!(network in R.camera.network))
				R.camera.network += network
				added_networks += network

/obj/item/weapon/robot_module/proc/RemoveCameraNetworks(var/mob/living/silicon/robot/R)
	if(R.camera)
		for(var/removed_network in added_networks)
			R.camera.network -= removed_network
	added_networks = null

/obj/item/weapon/robot_module/proc/AddEncryptionKey(var/mob/living/silicon/robot/R)
	if(!R.radio)
		return
	if(radio_key)
		R.radio.insert_key(new radio_key(R.radio))

/obj/item/weapon/robot_module/proc/ResetEncryptionKey(var/mob/living/silicon/robot/R)
	if(!R.radio)
		return
	if(radio_key)
		R.radio.reset_key()

/obj/item/weapon/robot_module/proc/ApplyStatusFlags(var/mob/living/silicon/robot/R)
	if(HAS_MODULE_QUIRK(R, MODULE_CAN_NOT_BE_PUSHED))
		R.status_flags &= ~CANPUSH

/obj/item/weapon/robot_module/proc/RemoveStatusFlags(var/mob/living/silicon/robot/R)
	if(HAS_MODULE_QUIRK(R, MODULE_CAN_NOT_BE_PUSHED))
		R.status_flags |= CANPUSH

/obj/item/weapon/robot_module/proc/rebuild()//Rebuilds the list so it's possible to add/remove items from the module
	if(isrobot(loc))
		var/mob/living/silicon/robot/R = loc
		var/held_modules = R.get_equipped_items()
		R.uneq_all()
		modules = list()
		if(isgravekeeper(R))
			for(var/obj/item/I in clockwork_modules)
				insert_module(I, FALSE)
		if(R.emagged || R.illegal_weapons)
			for(var/obj/item/I in syndicate_modules)
				insert_module(I, FALSE)
		for(var/obj/item/I in main_modules)
			insert_module(I, FALSE)
		for(var/obj/item/I in default_modules)
			insert_module(I, FALSE)
		for(var/i in held_modules)
			if(i)
				R.activate_module(i)
		fix_modules()

/obj/item/weapon/robot_module/proc/fix_modules() //call this proc to enable clicking the slot of a module to equip it.
	var/mob/living/silicon/robot/owner = loc
	if(!istype(owner))
		return
	var/list/equipped_slots = owner.get_all_slots()
	for(var/obj/item/I in (modules + syndicate_modules + clockwork_modules))
		if(I in equipped_slots)
			continue // mouse_opacity must not be 2 for equipped items
		I.mouse_opacity = 2

/obj/item/weapon/robot_module/proc/respawn_consumable(var/fully_respawn = FALSE)
	if(respawnables && respawnables.len)
		for(var/T in respawnables)
			if(!(locate(T) in modules))
				modules -= null
				var/obj/item/stack/O = new T(src)
				if(istype(O,T))
					O.max_amount = respawnables_max_amount
				modules += O
				O.amount = fully_respawn ? O.max_amount : 1

/obj/item/weapon/robot_module/proc/add_languages(var/mob/living/silicon/robot/R)
	for(var/language_name in languages)
		if(R.add_language(language_name))
			added_languages |= language_name

/obj/item/weapon/robot_module/proc/remove_languages(var/mob/living/silicon/robot/R)
	for(var/language_name in added_languages)
		R.remove_language(language_name, TRUE) //We remove the ability to speak but keep the ability to understand.
	added_languages.Cut()

//Modules
/obj/item/weapon/robot_module/standard
	name = "standard robot module"
	module_holder = "standard"
	sprites = list(
		"Default" = "robot",
		"Antique" = "robot_old",
		"Droid" = "droid",
		"Marina" = "marinaSD",
		"Sleek" = "sleekstandard",
		"#11" = "servbot",
		"Spider" = "spider-standard",
		"Kodiak - 'Polar'" = "kodiak-standard",
		"Noble" = "Noble-STD",
		"R34 - STR4a 'Durin'" = "durin"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/melee/baton/loaded/borg,
		/obj/item/weapon/wrench,
		/obj/item/device/healthanalyzer,
		/obj/item/weapon/soap/nanotrasen,
		/obj/item/device/taperecorder,
		/obj/item/device/megaphone
		)
	syndicate_modules = list(
		/obj/item/weapon/melee/energy/sword
		)
	respawnables = list(
		/obj/item/stack/medical/bruise_pack,
		/obj/item/stack/medical/ointment
		)
	respawnables_max_amount = STANDARD_MAX_KIT
	sensor_augs = list("Security", "Medical", "Mesons", "Disable")

/obj/item/weapon/robot_module/medical
	name = "medical robot module"
	speed_modifier = CYBORG_MEDICAL_SPEED_MODIFIER
	module_holder = "medical"
	quirk_flags = MODULE_CAN_NOT_BE_PUSHED | MODULE_CAN_HANDLE_MEDICAL | MODULE_CAN_HANDLE_CHEMS
	networks = list(CAMERANET_MEDBAY)
	radio_key = /obj/item/device/encryptionkey/headset_med
	sprites = list(
		"Default" = "medbot",
		"Needles" = "needles",
		"Surgeon" = "surgeon",
		"EVE" = "eve",
		"Droid" = "droid-medical",
		"Marina" = "marina",
		"Sleek" = "sleekmedic",
		"#17" = "servbot-medi",
		"Kodiak - 'Arachne'" = "arachne",
		"Noble" = "Noble-MED",
		"R34 - MED6a 'Gibbs'" = "gibbs"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher/mini,
		/obj/item/device/healthanalyzer,
		/obj/item/weapon/reagent_containers/borghypo,
		/obj/item/weapon/gripper/chemistry,
		/obj/item/weapon/reagent_containers/dropper/robodropper,
		/obj/item/weapon/reagent_containers/syringe,
		/obj/item/weapon/storage/bag/chem,
		/obj/item/weapon/scalpel,
		/obj/item/weapon/hemostat,
		/obj/item/weapon/retractor,
		/obj/item/weapon/circular_saw,
		/obj/item/weapon/cautery,
		/obj/item/weapon/bonegel,
		/obj/item/weapon/bonesetter,
		/obj/item/weapon/FixOVein,
		/obj/item/weapon/surgicaldrill,
		/obj/item/weapon/revivalprod,
		/obj/item/weapon/inflatable_dispenser/robot,
		/obj/item/robot_rack/bed
		)
	syndicate_modules = list(
		/obj/item/weapon/reagent_containers/spray
		)
	respawnables = list(
		/obj/item/stack/medical/advanced/bruise_pack,
		/obj/item/stack/medical/advanced/ointment,
		/obj/item/stack/medical/splint
		)
	respawnables_max_amount = MEDICAL_MAX_KIT
	sensor_augs = list("Medical", "Disable")

//	emag.reagents.add_reagent(PACID, 250)
//	emag.name = "Polyacid spray"

/obj/item/weapon/robot_module/engineering
	name = "engineering robot module"
	speed_modifier = CYBORG_ENGINEERING_SPEED_MODIFIER
	module_holder = "engineer"
	quirk_flags = MODULE_HAS_MAGPULSE | MODULE_CAN_LIFT_ENGITAPE
	networks = list(CAMERANET_ENGI)
	radio_key = /obj/item/device/encryptionkey/headset_eng
	sprites = list(
		"Default" = "engibot",
		"Engiseer" = "engiseer",
		"Landmate" = "landmate",
		"Wall-E" = "wall-e",
		"Droid" = "droid-engineer",
		"Marina" = "marinaEN",
		"Sleek" = "sleekengineer",
		"#25" = "servbot-engi",
		"Kodiak" = "kodiak-eng",
		"Noble" = "Noble-ENG",
		"R34 - ENG7a 'Conagher'" = "conagher"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher,
		/obj/item/weapon/extinguisher/foam,
		/obj/item/device/rcd/borg/engineering,
		/obj/item/device/rcd/rpd,
		/obj/item/weapon/weldingtool/largetank,
		/obj/item/weapon/screwdriver,
		/obj/item/weapon/wrench,
		/obj/item/weapon/wirecutters,
		/obj/item/device/multitool,
		/obj/item/device/t_scanner,
		/obj/item/device/analyzer,
		/obj/item/taperoll/atmos,
		/obj/item/taperoll/engineering,
		/obj/item/device/material_synth/robot/engiborg,
		/obj/item/device/silicate_sprayer,
		/obj/item/device/holomap,
		/obj/item/weapon/inflatable_dispenser/robot,
		/obj/item/borg/fire_shield
		)
	syndicate_modules = list(
		/obj/item/borg/stun
		)
	respawnables = list(
		/obj/item/stack/cable_coil
		)
	respawnables_max_amount = ENGINEERING_MAX_COIL
	sensor_augs = list("Mesons", "Disable")

/obj/item/weapon/robot_module/security
	name = "security robot module"
	speed_modifier = CYBORG_SECURITY_SPEED_MODIFIER
	module_holder = "security"
	quirk_flags = MODULE_CAN_NOT_BE_PUSHED | MODULE_IS_THE_LAW | MODULE_CAN_LIFT_SECTAPE
	radio_key = /obj/item/device/encryptionkey/headset_sec
	sprites = list(
		"Default" = "secbot",
		"Bloodhound" = "bloodhound",
		"Securitron" = "securitron",
		"Droid 'Black Knight'" = "droid-security",
		"Marina" = "marinaSC",
		"Sleek" = "sleeksecurity",
		"#9" = "servbot-sec",
		"Kodiak" = "kodiak-sec",
		"Noble" = "Noble-SEC",
		"R34 - SEC10a 'Woody'" = "woody"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/melee/baton/loaded/borg,
		/obj/item/weapon/gun/energy/taser/cyborg,
		/obj/item/weapon/handcuffs/cyborg,
		/obj/item/weapon/reagent_containers/spray/pepper,
		/obj/item/taperoll/police,
		/obj/item/device/hailer
		)
	syndicate_modules = list(
		/obj/item/weapon/gun/energy/laser/cyborg
		)
	sensor_augs = list("Security", "Medical", "Disable")

/obj/item/weapon/robot_module/janitor
	name = "janitorial robot module"
	speed_modifier = CYBORG_JANITOR_SPEED_MODIFIER
	module_holder = "janitor"
	quirk_flags = MODULE_CLEAN_ON_MOVE
	sprites = list(
		"Default" = "janbot",
		"Mechaduster" = "mechaduster",
		"HAN-D" = "han-d",
		"Mop Gear Rex" = "mopgearrex",
		"Droid - 'Mopbot'"  = "droid-janitor",
		"Marina" = "marinaJN",
		"Sleek" = "sleekjanitor",
		"#29" = "servbot-jani",
		"Noble" = "Noble-JAN",
		"R34 - CUS3a 'Flynn'" = "flynn"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/soap/nanotrasen,
		/obj/item/weapon/storage/bag/trash,
		/obj/item/weapon/mop,
		/obj/item/device/lightreplacer/borg,
		/obj/item/weapon/reagent_containers/glass/bucket
		)
	syndicate_modules = list(
		/obj/item/weapon/reagent_containers/spray
		)

//	emag.reagents.add_reagent(LUBE, 250)
//	emag.name = "Lube spray"

/obj/item/weapon/robot_module/butler
	name = "service robot module"
	speed_modifier = CYBORG_SERVICE_SPEED_MODIFIER
	module_holder = "service"
	quirk_flags = MODULE_CAN_HANDLE_CHEMS | MODULE_CAN_HANDLE_FOOD | MODULE_CAN_BUY
	radio_key = /obj/item/device/encryptionkey/headset_service
	sprites = list(
		"Default - 'Butler'" = "servbot_m",
		"Default - 'Waitress'" = "servbot_f",
		"Default - 'Bro'" = "brobot",
		"Default - 'Maximillion'" = "maximillion",
		"Default - 'Hydro'" = "hydrobot",
		"Toiletbot" = "toiletbot",
		"Marina" = "marinaSV",
		"Sleek" = "sleekservice",
		"#27" = "servbot-service",
		"Kodiak - 'Teddy'" = "kodiak-service",
		"Noble" = "Noble-SRV",
		"R34 - SRV9a 'Llyod'" = "lloyd"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/gripper/service,
		/obj/item/weapon/pen/robopen,
		/obj/item/weapon/dice/borg,
		/obj/item/device/rcd/borg/rsf,
		/obj/item/device/rcd/tile_painter,
		/obj/item/weapon/lighter/zippo,
		/obj/item/device/instrument/instrument_synth,
		/obj/item/weapon/tray/robotray,
		/obj/item/weapon/reagent_containers/dropper/robodropper,
		/obj/item/weapon/reagent_containers/glass/replenishing/cyborg
		)
	syndicate_modules = list(
		/obj/item/weapon/reagent_containers/glass/replenishing/cyborg/hacked
		)
	languages = list(
		LANGUAGE_UNATHI,
		LANGUAGE_CATBEAST,
		LANGUAGE_SKRELLIAN,
		LANGUAGE_GREY,
		LANGUAGE_CLATTER,
		LANGUAGE_VOX,
		LANGUAGE_GOLEM,
		LANGUAGE_SLIME,
		)

/obj/item/weapon/robot_module/miner
	name = "supply robot module"
	speed_modifier = CYBORG_SUPPLY_SPEED_MODIFIER
	module_holder = "miner"
	networks = list(CAMERANET_MINE)
	radio_key = /obj/item/device/encryptionkey/headset_mining
	sprites = list(
		"Default" = "minerbot",
		"Treadhead" = "miner",
		"Wall-A" = "wall-a",
		"Droid" = "droid-miner",
		"Marina" = "marinaMN",
		"Sleek" = "sleekminer",
		"#31" = "servbot-miner",
		"Kodiak" = "kodiak-miner",
		"Noble" = "Noble-SUP",
		"R34 - MIN2a 'Ishimura'" = "ishimura"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/storage/bag/ore/auto,
		/obj/item/weapon/pickaxe/drill/borg,
		/obj/item/weapon/storage/bag/sheetsnatcher/borg,
		/obj/item/device/mining_scanner,
		/obj/item/weapon/gun/energy/kinetic_accelerator/cyborg,
		/obj/item/weapon/gripper/no_use/inserter,
		/obj/item/device/destTagger/cyborg,
		/obj/item/device/gps/cyborg
		)
	syndicate_modules = list(
		/obj/item/borg/stun
		)
	respawnables = list(
		/obj/item/stack/package_wrap
		)
	respawnables_max_amount = SUPPLY_MAX_WRAP
	sensor_augs = list("Mesons", "Disable")

/obj/item/weapon/robot_module/syndicate
	name = "syndicate-modded combat robot module"
	module_holder = "malf"
	quirk_flags = MODULE_CAN_NOT_BE_PUSHED | MODULE_IS_DEFINITIVE | MODULE_HAS_PROJ_RES
	networks = list(CAMERANET_NUKE)
	radio_key = /obj/item/device/encryptionkey/syndicate
	default_modules = list(
		/obj/item/device/flashlight,
		/obj/item/device/flash,
		/obj/item/weapon/card/emag,
		/obj/item/weapon/crowbar
		)

/obj/item/weapon/robot_module/syndicate/blitzkrieg
	name = "syndicate blitzkrieg robot module"
	sprites = list(
		"Motile" = "motile-syndie"
		)
	main_modules = list(
		/obj/item/weapon/wrench,
		/obj/item/weapon/pinpointer/nukeop,
		/obj/item/weapon/gun/projectile/automatic/c20r,
		/obj/item/robot_rack/ammo/a12mm,
		/obj/item/weapon/pickaxe/plasmacutter/heat_axe
		)
	sensor_augs = list("Thermal", "Light Amplification", "Disable")

/obj/item/weapon/robot_module/syndicate/crisis
	name = "syndicate crisis robot module"
	quirk_flags = MODULE_CAN_NOT_BE_PUSHED | MODULE_IS_DEFINITIVE | MODULE_HAS_PROJ_RES | MODULE_CAN_HANDLE_MEDICAL | MODULE_CAN_HANDLE_CHEMS
	sprites = list(
		"Droid" = "droid-crisis"
		)
	main_modules = list(
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/inflatable_dispenser,
		/obj/item/device/chameleon,
		/obj/item/weapon/gripper/chemistry,
		/obj/item/device/healthanalyzer,
		/obj/item/device/reagent_scanner/adv,
		/obj/item/weapon/reagent_containers/borghypo/crisis,
		/obj/item/weapon/reagent_containers/borghypo/biofoam,
		/obj/item/weapon/revivalprod,
		/obj/item/weapon/switchtool/surgery,
		/obj/item/robot_rack/bed/syndie
		)
	sensor_augs = list("Thermal", "Medical", "Disable")

/obj/item/weapon/robot_module/combat
	name = "combat robot module"
	speed_modifier = CYBORG_COMBAT_SPEED_MODIFIER
	module_holder = "malf"
	quirk_flags = MODULE_CAN_NOT_BE_PUSHED | MODULE_IS_THE_LAW | MODULE_HAS_PROJ_RES
	radio_key = /obj/item/device/encryptionkey/headset_sec
	sprites = list(
		"Bladewolf" = "bladewolf",
		"Bladewolf MK-2" = "bladewolfmk2",
		"Mr. Gutsy" = "mrgutsy",
		"Droid" = "droid-combat",
		"Droid - 'Rottweiler'" = "rottweiler-combat",
		"Marina" = "marinaCB",
		"#41" = "servbot-combat",
		"Kodiak - 'Grizzly'" = "kodiak-combat",
		"R34 - WAR8a 'Chesty'" = "chesty"
		)
	main_modules = list(
		/obj/item/weapon/crowbar,
		/obj/item/weapon/gun/energy/laser/cyborg,
		/obj/item/weapon/pickaxe/plasmacutter,
		/obj/item/weapon/pickaxe/jackhammer/combat,
		/obj/item/borg/combat/shield,
		/obj/item/borg/combat/mobility,
		/obj/item/weapon/wrench,
		)
	syndicate_modules = list(
		/obj/item/weapon/gun/energy/laser/cannon/cyborg
		)
	sensor_augs = list("Security", "Medical", "Mesons", "Thermal", "Light Amplification", "Disable")

/obj/item/weapon/robot_module/tg17355
	name = "tg17355 robot module"
	speed_modifier = CYBORG_TG17355_SPEED_MODIFIER
	module_holder = "brobot"
	quirk_flags = MODULE_IS_DEFINITIVE
	sprites = list(
		"Peacekeeper" = "peaceborg",
		"Omoikane" = "omoikane"
	)
	main_modules = list(
		/obj/item/weapon/extinguisher/mini,
		/obj/item/weapon/cookiesynth,
		/obj/item/device/harmalarm,
		/obj/item/weapon/reagent_containers/borghypo/peace,
		/obj/item/weapon/inflatable_dispenser,
		/obj/item/borg/cyborghug
		)
	syndicate_modules = list(
		/obj/item/weapon/reagent_containers/borghypo/peace/hacked
		)
	sensor_augs = list("Medical", "Disable")
