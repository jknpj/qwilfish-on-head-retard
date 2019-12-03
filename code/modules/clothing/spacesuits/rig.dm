#define ONLY_DEPLOY 1
#define ONLY_RETRACT 2
#define HARDSUIT_HEADGEAR "h_head"
#define HARDSUIT_GLOVES "h_gloves"
#define HARDSUIT_BOOTS "h_boots"

//Regular rig suits
/obj/item/clothing/head/helmet/space/rig
	name = "engineering hardsuit helmet"
	desc = "A special helmet designed for work in a hazardous, low-pressure environment. Has radiation shielding."
	icon_state = "rig0-engineering"
	item_state = "eng_helm"
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 80)
	allowed = list(/obj/item/device/flashlight)
	light_power = 1.7
	var/brightness_on = 4 //Luminosity when on. If modified, do NOT run update_brightness() directly
	var/color_on = null //Color when on.
	var/on = 0 //Remember to run update_brightness() when modified, otherwise disasters happen
	var/no_light = 0 //Disables the helmet light when set to 1. Make sure to run check_light() if this is updated
	_color = "engineering" //Determines used sprites: rig[on]-[_color]. Use update_icon() directly to update the sprite. NEEDS TO BE SET CORRECTLY FOR HELMETS
	actions_types = list(/datum/action/item_action/toggle_rig_light)
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	pressure_resistance = 200 * ONE_ATMOSPHERE
	eyeprot = 3
	species_fit = list(GREY_SHAPED, TAJARAN_SHAPED)
	species_restricted = list("exclude",VOX_SHAPED)
	var/obj/item/clothing/suit/space/rig/rig

/obj/item/clothing/head/helmet/space/rig/New()
	check_light() //Needed to properly handle helmets with no lights
	..()
	//Useful for helmets with special starting conditions (namely, starts lit)
	update_brightness()

/obj/item/clothing/head/helmet/space/rig/Destroy()
	rig = null
	..()

/obj/item/clothing/head/helmet/space/rig/examine(mob/user)
	..()
	if(!no_light) //There is a light attached or integrated
		to_chat(user, "The helmet is mounted with an Internal Lighting System, it is [on ? "":"un"]lit.")

//We check no_light and update everything accordingly
//Used to clear up the action button and shut down the light if broken
//Minimizes snowflake coding and allows dynamically disabling the helmet's light if needed
/obj/item/clothing/head/helmet/space/rig/proc/check_light()
	if(no_light) //There's no light on the helmet
		if(on) //The helmet light is currently on
			on = FALSE //Force it off
			update_brightness() //Update as neccesary
		actions_types.Remove(/datum/action/item_action/toggle_rig_light)//Disable the action button (which is only used to toggle the light, in theory)
	else //We have a light
		actions_types |= /datum/action/item_action/toggle_rig_light //Make sure we restore the action button

/obj/item/clothing/head/helmet/space/rig/process() //Helmets are directly linked to the suit's power cell, they don't need it to be activated at all.
	if(on && rig)	
		if(!rig.cell.use(1) || rig.loc != loc)
			toggle_light()

/obj/item/clothing/head/helmet/space/rig/proc/toggle_light(var/mob/user)
	if(no_light)
		return
	if(rig)
		on = !on
		if(!rig.cell || rig.cell.charge < 1)
			on = FALSE
		update_brightness()
		if(user)
			user.update_inv_head()
	else
		to_chat(user, "<span class = 'warning'>\The [src] has no linked suit!</span>")

/obj/item/clothing/head/helmet/space/rig/proc/update_brightness()
	if(on)
		processing_objects.Add(src)
		set_light(brightness_on,null,color_on)
	else
		processing_objects.Remove(src)
		set_light(0)
	update_icon()

/obj/item/clothing/head/helmet/space/rig/update_icon()
	icon_state = "rig[on]-[_color]" //No need for complicated if trees


/obj/item/clothing/head/helmet/space/rig/unequipped(mob/living/carbon/human/user, var/from_slot = null)
	..()
	if(from_slot == slot_head && istype(user))
		if(rig && rig.is_worn_by(user))
			rig.deactivate_suit(user, FALSE) //Do not unequip everything if they're just retracting their helmet.
		if(on)
			toggle_light(user)

/obj/item/clothing/head/helmet/space/rig/equipped(mob/living/carbon/human/user, var/slot)
	..()
	if(!rig && user.is_wearing_item(/obj/item/clothing/suit/space/rig, slot_wear_suit))
		var/obj/item/clothing/suit/space/rig/RS = user.wear_suit
		if(RS.head_type && istype(src, RS.head_type)) //It's my suit! It was made for me!
			rig = user.wear_suit

/obj/item/clothing/suit/space/rig
	name = "engineering hardsuit"
	desc = "A special suit that protects against hazardous, low pressure environments. Has radiation shielding."
	icon_state = "rig-engineering"
	item_state = "eng_hardsuit"
	slowdown = HARDSUIT_SLOWDOWN_LOW
	species_fit = list(GREY_SHAPED, TAJARAN_SHAPED)
	species_restricted = list("exclude",VOX_SHAPED)
	armor = list(melee = 40, bullet = 5, laser = 20,energy = 5, bomb = 35, bio = 100, rad = 80)
	allowed = list(/obj/item/device/flashlight,/obj/item/weapon/tank,/obj/item/weapon/storage/bag/ore,/obj/item/device/t_scanner,/obj/item/weapon/pickaxe, /obj/item/device/rcd, /obj/item/weapon/wrench/socket)
	max_heat_protection_temperature = SPACE_SUIT_MAX_HEAT_PROTECTION_TEMPERATURE
	pressure_resistance = 200 * ONE_ATMOSPHERE
	actions_types = list(/datum/action/item_action/toggle_rig_suit)

	var/activated = FALSE
	var/list/modules = list()
	var/list/initial_modules = list(/obj/item/rig_module/health_readout)

	var/obj/item/clothing/head/helmet/space/rig/H = null
	var/obj/item/clothing/gloves/G = null
	var/obj/item/clothing/shoes/magboots/MB = null
	var/obj/item/weapon/tank/T = null
	var/obj/item/weapon/cell/cell = null

	var/head_type = /obj/item/clothing/head/helmet/space/rig
	var/boots_type =  null
	var/gloves_type = null
	var/tank_type = null
	var/cell_type = /obj/item/weapon/cell/high //The cell_type we're actually using

	var/mob/living/carbon/human/wearer

/obj/item/clothing/suit/space/rig/New()
	..()
	if(cell_type)
		cell = new cell_type(src)
	if(head_type)
		H = new head_type(src)
		H.canremove = FALSE
		H.rig = src
	if(gloves_type)
		G = new gloves_type(src)
		G.canremove = FALSE
	if(boots_type)
		MB = new boots_type(src)
		MB.canremove = FALSE
	if(tank_type)
		T = new tank_type(src)
	if(initial_modules && initial_modules.len)
		for(var/path in initial_modules)
			var/obj/item/rig_module/new_module = new path(src)
			modules += new_module
	if(!(src in processing_objects))
		processing_objects.Add(src)

/obj/item/clothing/suit/space/rig/Destroy()
	if(processing_objects.Find(src))
		processing_objects.Remove(src)
	for(var/obj/item/I in list(H,G,T,MB))
		if(I && (I.loc == src || !I.loc))
			qdel(I)
	H = null
	G = null
	T = null
	MB = null
	for(var/obj/M in modules)
		qdel(M)
	modules = null
	if(cell)
		qdel(cell)
	cell = null
	wearer = null
	if(processing_objects.Find(src))
		processing_objects.Remove(src)
	..()

/obj/item/clothing/suit/space/rig/examine(mob/user)
	..()
	for(var/obj/item/rig_module/M in modules)
		M.examine_addition(user)

/obj/item/clothing/suit/space/rig/get_cell()
	return cell

/obj/item/clothing/suit/space/rig/equipped(mob/living/carbon/human/user, var/slot)
	..()
	wearer = user

/obj/item/clothing/suit/space/rig/unequipped(mob/living/carbon/human/user, var/from_slot = null)
	..()
	if(from_slot == slot_wear_suit && istype(user))
		deactivate_suit(user, TRUE)
	wearer = null

/obj/item/clothing/suit/space/rig/dropped()
	..()
	for(var/piece in list(HARDSUIT_HEADGEAR,HARDSUIT_GLOVES,HARDSUIT_BOOTS))
		toggle_piece(piece, wearer, ONLY_RETRACT)
	wearer = null

/obj/item/clothing/suit/space/rig/proc/is_fully_equipped()
	if(!istype(wearer) || loc != wearer || wearer.wear_suit != src)
		return FALSE
	if(head_type && !(H && wearer.head == H))
		return FALSE
	if(gloves_type && !(G && wearer.gloves == G))
		return FALSE
	if(boots_type && !(MB && wearer.shoes == MB))
		return FALSE
	return TRUE

/obj/item/clothing/suit/space/rig/process()
	if(gcDestroyed)
		return

	check_builtin_pieces()

	if(!istype(wearer) || !wearer.is_wearing_item(src, slot_wear_suit))
		deactivate_suit(unequipall = FALSE)

	if(activated)
		process_rig_modules()

/obj/item/clothing/suit/space/rig/proc/process_rig_modules()
	if(istype(wearer) && wearer.timestopped)
		return

	for(var/obj/item/rig_module/R in modules)
		if(R.activated && R.active_power_usage)
			if(!cell.use(R.active_power_usage))
				R.say_to_wearer("Not enough power available in [src]!")
				R.deactivate()	
				continue
			R.do_process()

/obj/item/clothing/suit/space/rig/proc/check_builtin_pieces()
	var/mob/living/M = null

	for(var/obj/item/piece in list(H,G,MB))
		if(piece && piece.loc != src && !(wearer && wearer.is_wearing_item(piece)))
			if(istype(piece.loc, /mob/living))
				M = piece.loc
				M.drop_from_inventory(piece)
			piece.forceMove(src)

/obj/item/clothing/suit/space/rig/proc/toggle_suit(mob/living/carbon/human/user)
	if(!wearer.is_wearing_item(src, slot_wear_suit))
		return
	!activated ? initialize_suit(user, TRUE) : deactivate_suit(user, FALSE)

/obj/item/clothing/suit/space/rig/proc/initialize_suit(mob/living/carbon/human/user, var/equipall = TRUE)
	if(equipall)
		for(var/piece in list(HARDSUIT_HEADGEAR,HARDSUIT_GLOVES,HARDSUIT_BOOTS))
			toggle_piece(piece, user, ONLY_DEPLOY)
	if(H && wearer.is_wearing_item(H, slot_head))
		H.toggle_light(wearer) //Lights on
		if(T) //We have a built-in tank and our built-in helmet is equipped.
			wearer.toggle_internals(user, T)
	if(is_fully_equipped())
		for(var/obj/item/rig_module/module in modules)
			if(!module.activated) //Skip what is already activated.
				module.activate(wearer,src)
		activated = TRUE

/obj/item/clothing/suit/space/rig/proc/deactivate_suit(mob/living/carbon/human/user, var/unequipall = TRUE)
	if(unequipall)
		for(var/piece in list(HARDSUIT_HEADGEAR,HARDSUIT_GLOVES,HARDSUIT_BOOTS))
			toggle_piece(piece, user, ONLY_RETRACT)
	for(var/obj/item/rig_module/R in modules)
		R.deactivate()
	activated = FALSE

/obj/item/clothing/suit/space/rig/proc/toggle_piece(var/piece, var/mob/living/initiator, var/deploy_mode)
	if(!cell || !cell.charge)
		return
	if(!wearer)
		return
	if(initiator == wearer && wearer.incapacitated()) // If the initiator isn't wearing the suit it's probably something like an AI.
		return

	var/obj/item/check_slot
	var/equip_to
	var/obj/item/use_obj

	switch(piece)
		if(HARDSUIT_HEADGEAR)
			equip_to = slot_head
			use_obj = H
			check_slot = wearer.head
		if(HARDSUIT_GLOVES)
			equip_to = slot_gloves
			use_obj = G
			check_slot = wearer.gloves
		if(HARDSUIT_BOOTS)
			equip_to = slot_shoes
			use_obj = MB
			check_slot = wearer.shoes

	if(use_obj)
		if(check_slot == use_obj && deploy_mode != ONLY_DEPLOY)
			var/mob/living/carbon/human/holder
			if(use_obj)
				holder = use_obj.loc
				if(istype(holder))
					if(use_obj && check_slot == use_obj)
						if(wearer.remove_from_mob(use_obj,))
							to_chat(wearer, "<font color='blue'><b>Your [use_obj.name] retracts swiftly.</b></font>")
						use_obj.forceMove(src)
		else
			if(deploy_mode != ONLY_RETRACT)
				if(check_slot && check_slot == use_obj)
					return
				use_obj.forceMove(wearer)
				if(!wearer.equip_to_slot_if_possible(use_obj, equip_to, 0, 1))
					use_obj.forceMove(src)
					if(check_slot)
						to_chat(initiator, "<span class='danger'>You are unable to deploy \the [use_obj.name] as \the [check_slot] [check_slot.gender == PLURAL ? "are" : "is"] in the way.</span>")
						return
				else
					to_chat(wearer, "<span class='notice'>\The [use_obj.name] deploys swiftly.</span>")

/obj/item/clothing/suit/space/rig/verb/toggle_helmet()

	set name = "Toggle Helmet"
	set desc = "Deploys or retracts your helmet."
	set category = "Hardsuit"
	set src = usr.contents

	if(!wearer || !wearer.is_wearing_item(src, slot_wear_suit))
		to_chat(usr,"<span class='warning'>\The [src] is not being worn.</span>") 
		return

	toggle_piece(HARDSUIT_HEADGEAR,wearer)

/obj/item/clothing/suit/space/rig/verb/toggle_boots()

	set name = "Toggle Boots"
	set desc = "Deploys or retracts your boots."
	set category = "Hardsuit"
	set src = usr.contents

	if(!wearer || !wearer.is_wearing_item(src, slot_wear_suit))
		to_chat(usr,"<span class='warning'>\The [src] is not being worn.</span>") 
		return

	toggle_piece(HARDSUIT_BOOTS,wearer)

/obj/item/clothing/suit/space/rig/verb/toggle_gloves()

	set name = "Toggle Gloves"
	set desc = "Deploys or retracts your gloves."
	set category = "Hardsuit"
	set src = usr.contents

	if(!wearer || !wearer.is_wearing_item(src, slot_wear_suit))
		to_chat(usr,"<span class='warning'>\The [src] is not being worn.</span>") 
		return

	toggle_piece(HARDSUIT_GLOVES,wearer)