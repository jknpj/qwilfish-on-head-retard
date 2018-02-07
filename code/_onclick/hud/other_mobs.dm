
/datum/hud/proc/unplayer_hud()
	return

/datum/hud/proc/ghost_hud()
	mymob.visible = getFromPool(/obj/abstract/screen)
	mymob.visible.icon = 'icons/mob/screen1_ghost.dmi'
	mymob.visible.icon_state = "visible0"
	mymob.visible.name = "visible"
	mymob.visible.screen_loc = ui_health

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.visible)

/datum/hud/proc/corgi_hud()
	mymob.healths = getFromPool(/obj/abstract/screen)
	mymob.healths.icon = 'icons/mob/screen1_corgi.dmi'
	mymob.healths.icon_state = "health0"
	mymob.healths.name = "health"
	mymob.healths.screen_loc = ui_health

	mymob.pullin = getFromPool(/obj/abstract/screen)
	mymob.pullin.icon = 'icons/mob/screen1_corgi.dmi'
	mymob.pullin.icon_state = "pull0"
	mymob.pullin.name = "pull"
	mymob.pullin.screen_loc = ui_construct_pull

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.healths, mymob.pullin)

/datum/hud/proc/brain_hud(ui_style = 'icons/mob/screen1_Midnight.dmi')

/datum/hud/proc/slime_hud()


	mymob.healths = getFromPool(/obj/abstract/screen)
	mymob.healths.icon = 'icons/mob/screen1_slime.dmi'
	mymob.healths.icon_state = "slime_health0"
	mymob.healths.name = "health"
	mymob.healths.screen_loc = ui_construct_health

	mymob.pullin = getFromPool(/obj/abstract/screen)
	mymob.pullin.icon = 'icons/mob/screen1_slime.dmi'
	mymob.pullin.icon_state = "pull0"
	mymob.pullin.name = "pull"
	mymob.pullin.screen_loc = ui_construct_pull

	mymob.zone_sel = getFromPool(/obj/abstract/screen/zone_sel)
	mymob.zone_sel.icon = 'icons/mob/screen1_slime.dmi'
	mymob.zone_sel.overlays.len = 0
	mymob.zone_sel.overlays += image('icons/mob/zone_sel.dmi', "[mymob.zone_sel.selecting]")

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.healths, mymob.pullin, mymob.zone_sel)

/datum/hud/proc/shade_hud()


	mymob.healths = getFromPool(/obj/abstract/screen)
	mymob.healths.icon = 'icons/mob/screen1_shade.dmi'
	mymob.healths.icon_state = "shade_health0"
	mymob.healths.name = "health"
	mymob.healths.screen_loc = ui_construct_health

	mymob.pullin = getFromPool(/obj/abstract/screen)
	mymob.pullin.icon = 'icons/mob/screen1_shade.dmi'
	mymob.pullin.icon_state = "pull0"
	mymob.pullin.name = "pull"
	mymob.pullin.screen_loc = ui_construct_pull

	mymob.purged = getFromPool(/obj/abstract/screen)
	mymob.purged.icon = 'icons/mob/screen1_shade.dmi'
	mymob.purged.icon_state = "purge0"
	mymob.purged.name = "purged"
	mymob.purged.screen_loc = ui_construct_purge

	mymob.zone_sel = getFromPool(/obj/abstract/screen/zone_sel)
	mymob.zone_sel.icon = 'icons/mob/screen1_shade.dmi'
	mymob.zone_sel.overlays.len = 0
	mymob.zone_sel.overlays += image('icons/mob/zone_sel.dmi', "[mymob.zone_sel.selecting]")

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.healths, mymob.pullin, mymob.zone_sel, mymob.purged)

/datum/hud/proc/borer_hud()

	mymob.healths = getFromPool(/obj/abstract/screen)
	mymob.healths.icon = 'icons/mob/screen1_borer.dmi'
	mymob.healths.icon_state = "borer_health0"
	mymob.healths.name = "health"
	mymob.healths.screen_loc = ui_construct_health

	mymob.zone_sel = getFromPool(/obj/abstract/screen/zone_sel)
	mymob.zone_sel.icon = 'icons/mob/screen1_borer.dmi'
	mymob.zone_sel.overlays.len = 0
	mymob.zone_sel.overlays += image('icons/mob/zone_sel.dmi', "[mymob.zone_sel.selecting]")

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.healths, mymob.zone_sel)

/datum/hud/proc/construct_hud()
	var/constructtype

	if(istype(mymob,/mob/living/simple_animal/construct/armoured) || istype(mymob,/mob/living/simple_animal/construct/behemoth))
		constructtype = "juggernaut"
	else if(istype(mymob,/mob/living/simple_animal/construct/builder))
		constructtype = "artificer"
	else if(istype(mymob,/mob/living/simple_animal/construct/wraith))
		constructtype = "wraith"
	else if(istype(mymob,/mob/living/simple_animal/construct/harvester))
		constructtype = "harvester"

	if(constructtype)
		mymob.healths = getFromPool(/obj/abstract/screen)
		mymob.healths.icon = 'icons/mob/screen1_construct.dmi'
		mymob.healths.icon_state = "[constructtype]_health0"
		mymob.healths.name = "health"
		mymob.healths.screen_loc = ui_construct_health

		mymob.pullin = getFromPool(/obj/abstract/screen)
		mymob.pullin.icon = 'icons/mob/screen1_construct.dmi'
		mymob.pullin.icon_state = "pull0"
		mymob.pullin.name = "pull"
		mymob.pullin.screen_loc = ui_construct_pull

		mymob.zone_sel = getFromPool(/obj/abstract/screen/zone_sel)
		mymob.zone_sel.icon = 'icons/mob/screen1_construct.dmi'
		mymob.zone_sel.overlays.len = 0
		mymob.zone_sel.overlays += image('icons/mob/zone_sel.dmi', "[mymob.zone_sel.selecting]")

		mymob.purged = getFromPool(/obj/abstract/screen)
		mymob.purged.icon = 'icons/mob/screen1_construct.dmi'
		mymob.purged.icon_state = "purge0"
		mymob.purged.name = "purged"
		mymob.purged.screen_loc = ui_construct_purge

	mymob.client.reset_screen()

	mymob.client.screen += list(mymob.healths, mymob.pullin, mymob.zone_sel, mymob.purged)

/datum/hud/proc/vampire_hud(ui_style = 'icons/mob/screen1_Midnight.dmi')


	vampire_blood_display = getFromPool(/obj/abstract/screen)
	vampire_blood_display.name = "Vampire Blood"
	vampire_blood_display.icon_state = "dark128"
	vampire_blood_display.screen_loc = "EAST-1:[28*PIXEL_MULTIPLIER],CENTER+2:[15*PIXEL_MULTIPLIER]"

	mymob.client.screen += list(vampire_blood_display)

/datum/hud/proc/changeling_hud()
	vampire_blood_display = getFromPool(/obj/abstract/screen)
	vampire_blood_display.name = "Changeling Chems"
	vampire_blood_display.icon_state = "dark128"
	vampire_blood_display.screen_loc = "EAST-1:[28*PIXEL_MULTIPLIER],CENTER+2:[15*PIXEL_MULTIPLIER]"

	mymob.client.screen += list(vampire_blood_display)
