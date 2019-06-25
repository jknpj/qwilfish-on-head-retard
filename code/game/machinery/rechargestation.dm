/obj/machinery/recharge_station
	name = "recharging station"
	icon = 'icons/obj/objects.dmi'
	icon_state = "borgcharger0"
	density = TRUE
	anchored = TRUE
	use_power = 1
	idle_power_usage = 5
	active_power_usage = 1000
	var/mob/occupant = null
	var/obj/item/weapon/cell/held_cell = null
	var/upgrading = FALSE // are we upgrading a nigga?
	var/upgrade_finish_time = 0 // time the upgrade should finish
	var/manipulator_coeff = 1 // better manipulator swaps parts faster
	var/transfer_rate_coeff = 1 // transfer rate bonuses
	var/capacitors_charge = 0 //power stored in capacitors, to be instantly transferred to robots when they enter the charger
	var/capacitor_max_charge = 0 //combined max power the capacitors can hold
	machine_flags = SCREWTOGGLE | CROWDESTROY | WRENCHMOVE | EJECTNOTDEL

/obj/machinery/recharge_station/New()
	. = ..()
	build_icon()

	component_parts = newlist(
		/obj/item/weapon/circuitboard/recharge_station,
		/obj/item/weapon/stock_parts/capacitor,
		/obj/item/weapon/stock_parts/capacitor,
		/obj/item/weapon/stock_parts/manipulator,
		/obj/item/weapon/stock_parts/matter_bin
	)

	RefreshParts()

/obj/machinery/recharge_station/RefreshParts()
	var/T = 0
	for(var/obj/item/weapon/stock_parts/manipulator/M in component_parts)
		T += M.rating-1
	manipulator_coeff = initial(manipulator_coeff)+(T)
	T = 0
	for(var/obj/item/weapon/stock_parts/capacitor/C in component_parts)
		T += C.rating-1
	transfer_rate_coeff = initial(transfer_rate_coeff)+(T * 0.2)
	capacitor_max_charge = initial(capacitor_max_charge)+(T * 750)
	active_power_usage = 1000 * transfer_rate_coeff

/obj/machinery/recharge_station/Destroy()
	go_out()
	..()

/obj/machinery/recharge_station/is_airtight()
	return occupant

/obj/machinery/recharge_station/ex_act(severity)
	switch(severity)
		if(1.0)
			qdel(src)
		if(2.0)
			if(prob(50))
				new /obj/item/weapon/circuitboard/recharge_station(loc)
				qdel(src)
		if(3.0)
			if(prob(25))
				anchored = FALSE
				build_icon()

/obj/machinery/recharge_station/process()
	process_upgrade()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		return
	if(occupant)
		process_occupant()
	else
		process_capacitors()
	return 1

/obj/machinery/recharge_station/proc/process_upgrade()
	if(!(upgrading && held_cell))
		return
	if(!occupant || !isrobot(occupant)) //Something happened so stop the upgrade. This machine cannot upgrade non-silicon cells.
		upgrading = FALSE
		return
	if((stat & (NOPOWER|BROKEN)) || !anchored)
		to_chat(occupant, "<span class='warning'>Upgrade interrupted due to power failure, movement lock is released.</span>")
		upgrading = FALSE
		return
	if(world.timeofday >= upgrade_finish_time)
		if(held_cell)
			var/mob/living/silicon/robot/robot_occupant = occupant
			if(robot_occupant.swap_cell(null, held_cell))
				held_cell.give(held_cell.maxcharge) // its been in a recharger so it makes sense
				held_cell = null
				to_chat(occupant, "<span class='notice'>Upgrade completed.</span>")
				playsound(src, 'sound/machines/ping.ogg', 50, 0)
				return
		to_chat(occupant, "<span class='notice'>Upgrade failed.</span>")
		playsound(src, 'sound/machines/buzz-two.ogg', 50, 0)
		upgrading = FALSE

/obj/machinery/recharge_station/attackby(var/obj/item/W, var/mob/living/user)
	if(!user) //fuck off
		return
	if(istype(W, held_cell))
		if(!held_cell)
			if(user.drop_item(W, src))
				held_cell = W
				to_chat(user, "<span class='notice'>You add \the [W] to \the [src].</span>")
			else
				to_chat(user, "<span class='warning'>You can't let go of \the [W]!</span>")
		else
			to_chat(user, "<span class='notice'>\The [src] already contains something resembling a [W.name].</span>")
	else
		..()

/obj/machinery/recharge_station/attack_ghost(var/mob/user) //why would they
	return 0

/obj/machinery/recharge_station/attack_ai(var/mob/user)
	attack_hand(user)

/obj/machinery/recharge_station/attack_hand(var/mob/user)
	if(!user) //heck off
		return
	if(occupant == user)
		apply_cell_upgrade()
		return
	if(held_cell && !upgrading)
		held_cell.updateicon()
		user.put_in_hands(held_cell)
		if(held_cell.loc == src)
			held_cell.forceMove(get_turf(src))
		held_cell = null

/obj/machinery/recharge_station/verb/apply_cell_upgrade()
	set category = "Object"
	set name = "Apply Cell Upgrade"
	set src in range(0)

	var/mob/user = usr
	if(user != occupant)
		to_chat(user, "<span class='warning'>You must be inside \the [src] to do this.</span>")
		return
	if(upgrading)
		to_chat(user, "<span class='notice'>You interrupt the upgrade process.</span>")
		upgrading = FALSE
		return
	if(held_cell)
		var/obj/item/weapon/cell/occupant_cell = occupant.get_cell()
		if(alert(user, "Swap your [occupant_cell.name] for \the [held_cell.name], is this correct?", , "Yes", "No") == "Yes")
			upgrade_finish_time = world.timeofday + (600/manipulator_coeff)
			upgrading = TRUE
			to_chat(user, "The upgrade should complete in approximately [60/manipulator_coeff] seconds, you will be unable to exit \the [src] during this unless you cancel the process.")
			spawn() do_after(user,src,600/manipulator_coeff,needhand = FALSE)
			return
		else
			upgrading = FALSE
			to_chat(user, "You decide not to apply \the [held_cell.name]")
			return
	else
		to_chat(user, "<span class='warning'>There are no upgrades available at this time.</span>")

/obj/machinery/recharge_station/allow_drop()
	return 0

/obj/machinery/recharge_station/relaymove(mob/user)
	if(user.incapacitated())
		return
	go_out()

/obj/machinery/recharge_station/emp_act(severity)
	if(stat & (BROKEN|NOPOWER))
		..(severity)
		return
	if(occupant)
		occupant.emp_act(severity)
		go_out()
	..(severity)

/obj/machinery/recharge_station/proc/build_icon()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		icon_state = "borgcharger"
	else
		icon_state = "borgcharger[occupant ? "1":"0"]"

/obj/machinery/recharge_station/proc/process_occupant()
	if(occupant)
		if((occupant.incapacitated()) || (!occupant.client)) //no suiciding in recharge stations to ruin them.
			go_out()
			return
		var/obj/item/weapon/cell/occupant_cell = occupant.get_cell()
		if(!occupant_cell)
			return
		if(occupant_cell.charge >= occupant_cell.maxcharge)
			occupant_cell.charge = occupant_cell.maxcharge
			return
		else
			if(capacitors_charge)
				var/juicetofill = occupant_cell.maxcharge-occupant_cell.charge
				if(capacitors_charge > juicetofill)
					capacitors_charge -= juicetofill
					occupant_cell.charge = occupant_cell.maxcharge
				else
					occupant_cell.give(capacitors_charge)
					capacitors_charge = 0
			occupant_cell.give(200 * transfer_rate_coeff + (isMoMMI(occupant) ? 100 * transfer_rate_coeff : 0))

/obj/machinery/recharge_station/proc/process_capacitors()
	if(capacitors_charge >= capacitor_max_charge)
		if(idle_power_usage != initial(idle_power_usage)) //probably better to not re-assign the variable each process()?
			idle_power_usage = initial(idle_power_usage)
		return 0
	idle_power_usage = initial(idle_power_usage) + (100 * transfer_rate_coeff)
	capacitors_charge = min(capacitors_charge + (20 * transfer_rate_coeff), capacitor_max_charge)
	return 1

/obj/machinery/recharge_station/proc/go_out()
	if(!occupant)
		return
	if(upgrading)
		to_chat(occupant, "<span class='notice'>The upgrade hasn't completed yet, interface with \the [src] again to halt the process.</span>")
		return
	if(!occupant.gcDestroyed)
		if(occupant.client)
			occupant.client.eye = occupant.client.mob
			occupant.client.perspective = MOB_PERSPECTIVE
		occupant.forceMove(loc)
	occupant = null
	build_icon()
	use_power = 1
	// Removes dropped items/magically appearing mobs from the charger too
	for(var/atom/movable/x in contents)
		if(!(x in held_cell |component_parts))
			x.forceMove(get_turf(src))

/obj/machinery/recharge_station/proc/restock_modules()
	if(occupant && isrobot(occupant))
		var/mob/living/silicon/robot/R = occupant
		if(R.module && R.module.modules)
			var/list/um = R.contents|R.module.modules
			// ^ makes single list of active (R.contents) and inactive modules (R.module.modules)
			for(var/obj/item/I in um)
				I.restock()
			R.module.respawn_consumable(R)
			R.module.fix_modules()

/obj/machinery/recharge_station/proc/mob_enter(mob/user)
	if(stat & (NOPOWER|BROKEN) || !anchored)
		return
	if(user.isDead() || !user.canmove)
		return
	if(!issilicon(user) && !user.get_cell())
		to_chat(user, "<span class='warning'>You need a built-in cell to enter \the [src]!</span>")
		return
	if(occupant)
		to_chat(user, "<span class='warning'>\The [src] is already occupied!</span>")
		return
	user.stop_pulling()
	if(user && user.client)
		user.client.perspective = EYE_PERSPECTIVE
		user.client.eye = src
	user.forceMove(src)
	occupant = user
	add_fingerprint(user)
	build_icon()
	use_power = 2
	if(held_cell)
		var/obj/item/weapon/cell/occupant_cell = user.get_cell()
		if(!occupant_cell)
			to_chat(user, "<big><span class='notice'>Power Cell replacement available. You may opt in with the 'Apply Cell Upgrade' verb in the Object tab.</span></big>")
		else
			if(held_cell.maxcharge > occupant_cell.maxcharge)
				to_chat(user, "<span class='notice'>Power Cell upgrade available. You may opt in with the 'Apply Cell Upgrade' verb in the Object tab.</span></big>")

/obj/machinery/recharge_station/togglePanelOpen(var/obj/toggleitem, mob/user)
	if(occupant)
		to_chat(user, "<span class='notice'>You can't do that while this charger is occupied.</span>")
		return -1
	return ..()

/obj/machinery/recharge_station/crowbarDestroy(mob/user)
	if(occupant)
		to_chat(user, "<span class='notice'>You can't do that while this charger is occupied.</span>")
		return -1
	return ..()

/obj/machinery/recharge_station/Bumped(atom/AM as mob|obj)
	if(AM.get_cell())
		mob_enter(AM)

/obj/machinery/recharge_station/get_cell()
	if(occupant)
		return occupant.get_cell()