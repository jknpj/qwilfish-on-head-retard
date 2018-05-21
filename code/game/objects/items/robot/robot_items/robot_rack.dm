//Robot racks
/obj/item/robot_rack
	name = "generic robot rack"
	desc = "A rack for carrying large items as a robot."
	var/obj/object_type = null //The types of object the rack holds (subtypes are allowed).
	var/obj/interact_type = null //Things of this type will trigger attack_hand when attacked by this.
	var/obj/initial_type = null //What type we start with. Useful if we start with a subtype of the type we can held.
	var/starting_objects = 0
	var/capacity = 1 //How many objects can be held.
	var/list/obj/held = list() //What is being held.

/obj/item/robot_rack/examine(mob/user)
	. = ..()
	to_chat(user, "It can hold up to [capacity] item[capacity == 1 ? "" : "s"].")

/obj/item/robot_rack/New()
	. = ..()
	var/obj/starting_type = initial_type? initial_type : object_type
	if(starting_type && starting_objects)
		for(var/i = 1, i <= min(starting_objects, capacity), i++)
			held += new starting_type(src)
			update_icon()

/obj/item/robot_rack/Destroy()
	if(held.len > 0)
		for(var/H in held)
			qdel(H)
			held -= H
	held = null
	..()

/obj/item/robot_rack/update_icon()
	return

/obj/item/robot_rack/attack_self(mob/user)
	if(!length(held))
		to_chat(user, "<span class='notice'>\The [name] is empty.</span>")
		return
	var/obj/R = held[length(held)]
	R.forceMove(get_turf(src))
	held -= R
	update_icon()
	to_chat(user, "<span class='notice'>You deploy [R].</span>")

/obj/item/robot_rack/preattack(obj/O, mob/user, proximity, params)
	if(istype(O, interact_type))
		O.attack_hand(user) //Used mainly by roller beds to unbuckle dudes
	if(istype(O, object_type))
		if(length(held) < capacity)
			to_chat(user, "<span class='notice'>You collect [O].</span>")
			O.forceMove(src)
			held += O
			update_icon()
			return
		to_chat(user, "<span class='notice'>\The [src] is full and can't store any more items.</span>")
		return
	. = ..()

//Mediborg's roller bed rack
/obj/item/robot_rack/roller_bed
	name = "hover bed rack"
	desc = "A rack for carrying a collapsed rover or roller bed."
	icon = 'icons/obj/rollerbed.dmi'
	icon_state = "borgbed_stored"
	object_type = /obj/structure/bed/roller
	initial_type = /obj/structure/bed/roller/borg
	starting_objects = 1

/obj/item/robot_rack/roller_bed/update_icon()
	icon_state = "borgbed_[held.len > 0 ? "stored" : "deployed"]"

//Syndicate Blitzkrieg's ammo rack/loader
#define NEEDED_CHARGE_TO_RESTOCK_MAG 30

/obj/item/robot_rack/ammo
	name = "blitzkrieg a12mm loader"
	desc = "An syndicate toolbox redesigned for carrying and loading a12mm ammo."
	icon = 'icons/obj/storage/storage.dmi'
	icon_state = "toolbox_syndi"
	initial_type = /obj/item/ammo_storage/magazine/a12mm/ops
	object_type = /obj/item/ammo_storage/magazine/a12mm
	var/reload_type = /obj/item/weapon/gun/projectile/automatic/c20r
	starting_objects = 3
	capacity = 5
	var/charge = 0

/obj/item/robot_rack/ammo/restock()
	charge++
	if((charge >= NEEDED_CHARGE_TO_RESTOCK_MAG) && (length(held) < capacity)) //takes about 60 seconds.
		var/obj/item/ammo_storage/magazine/ammo = new initial_type(src)
		held += ammo
		update_icon()
		charge = initial(charge)

/obj/item/robot_rack/ammo/preattack(obj/O, mob/user, proximity, params)
	if(istype(O, reload_type))
		var/obj/item/ammo_storage/magazine/M = held[length(held)]
		O.attackby(M, user)
	. = ..()

#undef NEEDED_CHARGE_TO_RESTOCK_MAG