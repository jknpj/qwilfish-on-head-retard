/obj/item/clothing/under/syndicate
	name = "tactical turtleneck"
	desc = "A non-descript, slightly suspicious piece of civilian clothing."
	icon_state = "syndicate"
	item_state = "bl_suit"
	_color = "syndicate"
	species_fit = list(VOX_SHAPED, GREY_SHAPED)
	armor = list(melee = 10, bullet = 0, laser = 0,energy = 0, bomb = 0, bio = 0, rad = 0)
	siemens_coefficient = 0.9

//We want our sensors to be off, sensors are not tactical
/obj/item/clothing/under/syndicate/New()
	..()
	sensor_mode = 0

/obj/item/clothing/under/syndicate/combat
	name = "combat turtleneck"

/obj/item/clothing/under/syndicate/holomap
	name = "tactical holosuit"
	desc = "It's been fitted with some holographic localization devices. A measure the Syndicate judged necessary to improve teamwork among operatives."

/obj/item/clothing/under/syndicate/holomap/New()
	..()
	attach_accessory(new/obj/item/clothing/accessory/holomap_chip/operative(src))

/obj/item/clothing/under/syndicate/commando/New()
	..()
	attach_accessory(new/obj/item/clothing/accessory/holomap_chip/elite(src))

/obj/item/clothing/under/syndicate/tacticool
	name = "\improper Tacticool turtleneck"
	desc = "Just looking at it makes you want to buy an SKS, go into the woods, and -operate-."
	icon_state = "tactifool"
	item_state = "bl_suit"
	_color = "tactifool"
	species_fit = list(VOX_SHAPED, GREY_SHAPED)
	siemens_coefficient = 1

/obj/item/clothing/under/syndicate/executive
	name = "syndicate executive suit"
	desc = "A snappy black suit worn by syndicate executives. The shirt is either a tacky red or soaked in blood. Or possibly both."
	icon_state = "exec"
	_color = "exec"
	species_fit = list(GREY_SHAPED)

/obj/item/clothing/under/syndicate/sundowner
	name = "sundowner cybernetic suit"
	desc = "A heavy-duty cybernetic suit made by Desperado Space Enforcement LLC. Doesn't actually make you fucking invincible."
	icon_state = "sundowner_suit"
	item_state = "sundowner_suit"
	_color = "sundowner_suit"
	gas_transfer_coefficient = 0.01
	permeability_coefficient = 0.01
	body_parts_covered = FULL_TORSO|ARMS|HANDS|LEGS
	heat_conductivity = INS_JUMPSUIT_HEAT_CONDUCTIVITY
	species_restricted = list("exclude",VOX_SHAPED)
	clothing_flags = ONESIZEFITSALL
	canremove = FALSE //Once you go black you never go back.
	armor = list(melee = 35, bullet = 10, laser = 0, energy = 0, bomb = 30, bio = 0, rad = 0)

/obj/item/clothing/under/syndicate/sundowner/equipped(mob/living/carbon/human/C, wear_suit)
	if(C.is_wearing_item(src, wear_suit))
		to_chat(usr, "<span class='warning'>A spike of pain jolts your body as \the [name] merges with your skin and flesh.</span>")
		C.drop_item(C.get_item_by_slot(slot_wear_mask), force_drop = TRUE)
		C.equip_to_slot_or_del(new /obj/item/clothing/mask/gas/sundowner(src), slot_wear_mask)
		C.drop_item(C.get_item_by_slot(slot_shoes), force_drop = TRUE)
		C.equip_to_slot_or_del(new /obj/item/clothing/shoes/magboots/captain/sundowner(src), slot_shoes)