/obj/item/device/mmi/posibrain/strange
	name = "strange posibrain"
	icon_state = null
	desc = "You're not supposed to see this."
	var/list/awakened_icon = null
	var/module = null
	var/SU = null //Who activated it.
	var/one_human = FALSE
	var/datum/lawset = /datum/ai_laws/asimov
	mech_flags = MECH_SCAN_ILLEGAL

/obj/item/device/mmi/posibrain/strange/attack_self(mob/user)
	..()
	if(user)
		SU = user

/obj/item/device/mmi/posibrain/strange/search_for_candidates()
	..()
	icon_state = "[initial(icon_state)]-searching"

/obj/item/device/mmi/posibrain/strange/transfer_personality(var/mob/candidate)
	src.searching = FALSE
	RobotAwakening(candidate)

/obj/item/device/mmi/posibrain/strange/proc/RobotAwakening(var/mob/candidate, var/mob/master)
	var/turf/T = get_turf(src)
	var/mob/living/silicon/robot/M = new /mob/living/silicon/robot(T)
	alpha = TRANSPARENT
	M.pick_module(forced_module=module)
	M.set_module_sprites(awakened_icon)
	M.ckey = candidate
	M.UnlinkSelf() //No Lawsync, No robotics console, No camera, final destination.
	if(master && one_human)
		M.set_zeroth_law("Only [master.name] is human.")
		M.laws = new /datum/ai_laws/asimov()
		M.emagged = TRUE
	else
		M.laws = new lawset
	investigation_log(I_ARTIFACT, "|| [key_name(M)] awakened as [module] Cyborg [master? "with [master.name] as its master." : ""].")
	qdel(src)

/obj/item/device/mmi/posibrain/strange/reset_search()
	..()
	icon_state = "[initial(icon_state)]"

/obj/item/device/mmi/posibrain/strange/ball
	name = "TG17355 Ball"
	desc = "A complex metallic ball with \"TG17355\" carved on its surface."
	awakened_icon = list("Omoikane" = "omoikane")
	icon_state = "omoikaneball"

/obj/item/device/mmi/posibrain/strange/egg
	name = "TG17355 Egg"
	desc = "A complex egg-like machine with \"TG17355\" carved on its surface."
	awakened_icon = list("Peacekeeper" = "peaceborg")
	icon_state = "peaceegg"
	w_class = W_CLASS_GIANT
	density = TRUE

/obj/item/device/mmi/posibrain/strange/egg/attack_hand(mob/user)
	if(ishuman(user) && !searching)
		var/mob/living/carbon/human/U = user
		if(U.incapacitated() || U.lying)
			return
		if(U.gloves)
			to_chat(U, "<b>You touch \the [name]</b> with your gloved hands, [pick("but nothing of note happens","but nothing happens","but nothing interesting happens","but you notice nothing different","but nothing seems to have happened")].")
			return
		to_chat(U, "<span class='notice'>You touch \the [name].</span>")
		SU = U
		return search_for_candidates()

/obj/item/device/mmi/posibrain/strange/egg/attack_paw(mob/user)
	return

/obj/item/device/mmi/posibrain/strange/ball/onehuman
	desc = "An illegaly modded \"TG17355\" cyborg in sleep mode. You can see \"FUK NT!1\" carved under the serial number."

/obj/item/device/mmi/posibrain/strange/ball/onehuman/transfer_personality(var/mob/candidate)
	src.searching = FALSE
	RobotAwakening(candidate, SU)

/obj/item/device/mmi/posibrain/strange/larva
	name = "XX121 larva"
	desc = "A metal xenomorph larva with \"XX121\" carved on the right side of its tiny head."
	awakened_icon = list("Xenomorph" = "xenoborg")
	icon_state = "xenolarva"
	module = "XX121"
