/obj/item/weapon/cookiesynth
	name = "cookie synthesizer"
	desc = "A self-recharging device used to rapidly deploy cookies."
	icon = 'icons/obj/RCD.dmi'
	icon_state = "rcd"
	var/toxin = FALSE
	var/toxin_type = CHLORALHYDRATE //Our toxin
	var/thing = /obj/item/weapon/reagent_containers/food/snacks/cookie
	var/sound_type = "spark_sound"
	var/cooldown = 0
	var/delay = 15 SECONDS
	var/emagged = FALSE
	w_class = W_CLASS_MEDIUM

/obj/item/weapon/cookiesynth/attackby(obj/item/weapon/W, mob/user)
	if(isEmag(W))
		Emag(user)
		return
	..()

/obj/item/weapon/cookiesynth/proc/Emag(mob/user)
	emagged = !emagged
	to_chat(user,"<span class='warning'>You [emagged ? "short out" : "reset"] [src]'s reagent safety checker!</span>")
	toxin = emagged? TRUE : FALSE //You can toggle the toxins when it is emagged so let's make sure we don't fuck up this.

/obj/item/weapon/cookiesynth/attack_self(mob/user)
	if(isrobot(user))
		var/mob/living/silicon/robot/R = user
		if(R.emagged)
			toggle_toxins(user)
	if(emagged)
		toggle_toxins(user)

/obj/item/weapon/cookiesynth/proc/toggle_toxins(mob/user)
	toxin = !toxin
	to_chat(user,"[src] mode: [toxin ? "Hacked" : "Normal"].")

/obj/item/weapon/cookiesynth/afterattack(atom/A, mob/user, proximity)
	if(cooldown > world.time)
		return
	if(!proximity)
		return
	if (!(istype(A, /obj/structure/table) || isturf(A)))
		return
	if(isrobot(user))
		var/mob/living/silicon/robot/R = user
		if(!R.cell || R.cell.charge < 400)
			to_chat(user,"<span class='warning'>You don't have enough power to use [src].</span>")
			return
		R.cell.charge -= 100
	var/turf/T = get_turf(A)
	playsound(loc, get_sfx(sound_type), 10, 1)
	var/obj/item/weapon/reagent_containers/food/S = new thing(T)
	to_chat(user,"Fabricating [S.name]..")
	if(toxin)
		S.reagents.add_reagent(toxin_type, 10)
	cooldown = world.time + delay

/obj/item/weapon/cookiesynth/xeno
	name = "xenomorph blend coffee dispenser"
	desc = "A self-recharging head-mounted device used to deploy mind-numbing coffee."
	icon = 'icons/obj/borg_items.dmi'
	icon_state = "xenosynth"
	toxin_type = NEUROTOXIN
	thing = /obj/item/weapon/reagent_containers/food/drinks/coffee
	sound_type = "hiss"
	delay = 30 SECONDS

/obj/item/weapon/cookiesynth/xeno/toggle_toxins()
	icon_state = "[toxin ? "initial(icon_state)-tox" : initial(icon_state)]"
	..()
