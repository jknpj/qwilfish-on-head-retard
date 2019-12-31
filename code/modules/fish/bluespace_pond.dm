// -----------------------------
//       Bluespace Ponds
// -----------------------------

/obj/bluespace_pond
	name = "bluespace pond"
	desc = "A bluespace pond full of wonderful sea life. Goes well with a fishing rod, beer and friends."
	icon = 'icons/obj/machines/bluespace_pond.dmi'
	var/base_state = "pond" // used for icon selection in update_icon
	icon_state = "pond0"
	anchored = TRUE
	density = TRUE

/obj/bluespace_pond/can_fish()
	return TRUE

/obj/bluespace_pond/canSmoothWith()
	return list(/obj/bluespace_pond)

/obj/bluespace_pond/attackby(obj/item/weapon/W, mob/user)
	if(W.is_wrench(user))
		playsound(loc, 'sound/items/Ratchet.ogg', 50, 1) //AAAAAAAAAAAAAA
		if(do_after(user, src, 30))
			new /obj/item/device/bluespace_pond_container(loc)
			qdel(src)
			to_chat(user, "<span class='notice'>You pack \the [name] away.</span>")
	else if(is_type_in_list(W, fish_items_list[W]))
		to_chat(user, "<span class='notice'>You throw \the [W] back into the water.</span>")
		qdel(W)
	..()


// -----------------------------
//   Bluespace Pond Containers
// -----------------------------

/obj/item/device/bluespace_pond_container
	name = "packaged bluespace pond section"
	desc = "Thanks to advances in bluespace technology, you too can now have your own portable pond in space! Use a multitool to activate this package."
	icon = 'icons/obj/machines/bluespace_pond.dmi'
	icon_state = "box"
	w_class = W_CLASS_LARGE
	flags = FPRINT
	siemens_coefficient = 1
	throwforce = 5
	throw_speed = 1
	throw_range = 2
	starting_materials = list(MAT_IRON = CC_PER_SHEET_METAL*2)
	w_type = RECYK_METAL

/obj/item/device/bluespace_pond_container/attackby(var/obj/item/I, var/mob/user)
	if(ismultitool(I) && isturf(loc))
		for(var/obj/bluespace_pond/BSP in loc.contents)
			to_chat(user, "<span class='warning'>You cannot unpack a bluespace pond on top of another.</span>")
			return
		new/obj/bluespace_pond(src.loc)
		to_chat(user, "<span class='notice'>You unpack \the [name].</span>")
		qdel(src)
		return
	..()