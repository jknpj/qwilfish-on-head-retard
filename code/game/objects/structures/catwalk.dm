/obj/structure/catwalk
	icon = 'icons/turf/catwalks.dmi'
	icon_state = "catwalk"
	name = "catwalk"
	desc = "Cats really don't like these things."
	density = 0
	anchored = 1.0
	plane = ABOVE_PLATING_PLANE
	layer = CATWALK_LAYER
	var/list/connections = list(0, 0, 0, 0)
	var/has_plating = FALSE
	var/plating_color = null
	var/hatch_open = FALSE

/obj/structure/catwalk/canSmoothWith()
	var/static/list/smoothables = list(/obj/structure/catwalk)
	return smoothables

/obj/structure/catwalk/New(loc)
	..(loc)
	update_connections(TRUE)
	relativewall()
	relativewall_neighbours()

/obj/structure/catwalk/relativewall()
	update_connections()
	var/junction = findSmoothingNeighbors()
	icon_state = !hatch_open ? "[initial(icon_state)][junction]" : ""
	if(has_plating)
		overlays.Cut()
		if(!hatch_open)
			mount_catwalk_icon()
		mount_catwalk_icon("plated", plating_color)
		return
	icon_state = "[initial(icon_state)][junction]"

/obj/structure/catwalk/proc/mount_catwalk_icon(var/new_icon_state, var/new_color)
	var/image/I = null
	for(var/i = 1 to 4)
		I = image('icons/turf/catwalks.dmi', (new_icon_state ? new_icon_state : initial(icon_state))+connections[i], dir = 1<<(i-1))
		if(new_color)
			I.color = new_color
		overlays += I

/obj/structure/catwalk/proc/update_connections(propagate = FALSE)
	var/list/dirs = list()

	if(!anchored)
		return

	for(var/obj/structure/S in orange(src, 1))
		if(istype(S, src))
			if(S.anchored)
				if(propagate)
					S.relativewall()
				dirs += get_dir(src, S)

	connections = dirs_to_corner_states(dirs)

/obj/structure/catwalk/ex_act(severity)
	switch(severity)
		if(1)
			qdel(src)
		if(2)
			if(prob(25))
				new /obj/structure/lattice(loc)
			qdel(src)
		if(3)
			if(prob(10))
				new /obj/structure/lattice(loc)
				qdel(src)

/obj/structure/catwalk/attackby(obj/item/C, mob/user)
	if(!C || !user)
		return 0

	if(C.is_screwdriver(user))
		to_chat(user, "<span class='notice'>You begin undoing the screws holding the catwalk together.</span>")
		playsound(src, 'sound/items/Screwdriver.ogg', 80, 1)
		if(do_after(user, src, 30) && src)
			to_chat(user, "<span class='notice'>You finish taking taking the catwalk apart.</span>")
			new /obj/item/stack/rods(src.loc, 2)
			new /obj/structure/lattice(src.loc)
			qdel(src)
		return

	if(has_plating && iscrowbar(C))
		hatch_open = !hatch_open
		playsound(src, hatch_open ? 'sound/items/Crowbar.ogg' : 'sound/items/Deconstruct.ogg', 100, 2)
		to_chat(user, "<span class='notice'>You [hatch_open ? "pry open" : "shut"]  \the [src]'s maintenance hatch.</span>")
		relativewall()
		return

	if(iscablecoil(C))
		var/obj/item/stack/cable_coil/coil = C
		if(get_turf(src) == src.loc)
			coil.turf_place(src.loc, user)

/obj/structure/catwalk/invulnerable/ex_act()
	return

/obj/structure/catwalk/invulnerable/attackby()
	return

//For an away mission
/obj/structure/catwalk/invulnerable/hive
	plane = ABOVE_TURF_PLANE

/obj/structure/catwalk/invulnerable/hive/isSmoothableNeighbor(atom/A)
	if(istype(A, /turf/unsimulated/wall/supermatter))
		return FALSE
	return ..()

/obj/structure/catwalk/plated
	name = "plated catwalk"
	desc = "Cats really don't like these things. Its maintenance hatch can be opened with a crowbar."
	layer = PLATED_CATWALK_LAYER
	has_plating = TRUE
	icon_state = "catwalk_bay"

#define CORNER_NONE 0
#define CORNER_COUNTERCLOCKWISE 1
#define CORNER_DIAGONAL 2
#define CORNER_CLOCKWISE 4

/proc/dirs_to_corner_states(list/dirs)
	if(!istype(dirs)) return

	var/list/ret = list(NORTHWEST, SOUTHEAST, NORTHEAST, SOUTHWEST)

	for(var/i = 1 to ret.len)
		var/dir = ret[i]
		. = CORNER_NONE
		if(dir in dirs)
			. |= CORNER_DIAGONAL
		if(turn(dir,45) in dirs)
			. |= CORNER_COUNTERCLOCKWISE
		if(turn(dir,-45) in dirs)
			. |= CORNER_CLOCKWISE
		ret[i] = "[.]"

	return ret

#undef CORNER_NONE
#undef CORNER_COUNTERCLOCKWISE
#undef CORNER_DIAGONAL
#undef CORNER_CLOCKWISE
