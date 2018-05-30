//A system to manage and display alerts on screen without needing you to do it yourself

//Proc to create or update an alert. Returns TRUE if the alert is new or updated, FALSE if it was thrown already category is a text string.
//Each mob may only have one alert per category; the previous one will be replaced id is a text string, If you don't provide one, category will be used as id
//Either way it MUST match a type path like so: /obj/abstract/screen/[id]
//Also the alert's icon_state will be [id] so you must add it to screen_alert.dmi
//Severity is an optional number that will be placed at the end of the icon_state for this alert
//For example, high pressure's id is "highpressure" and can be serverity 1 or 2 to get "highpressure1" or "highpressure2" as icon_states
//new_master is optional and sets the alert's icon state to "template" in the ui_style icons with the master as an overlay.
//Clicks are forwarded to master
/mob/proc/throw_alert(category, type, severity, obj/new_master)
	if(!category)
		return

	var/obj/abstract/screen/alert/alert
	if(alerts[category])
		alert = alerts[category]
		if(new_master && new_master != alert.master)
//			CRASH("[src] threw alert [category] with new_master [new_master] while already having that alert with master [alert.master]")
			clear_alert(category)
			return .()
		else if(alert.type == type && (!severity || severity == alert.severity))
			if(alert.timeout)
				clear_alert(category)
				return .()
			return FALSE
	else
		alert = getFromPool(type)

	if(new_master)
		var/old_layer = new_master.layer
		new_master.layer = FLOAT_LAYER
		alert.overlays += new_master
		new_master.layer = old_layer
		alert.icon_state = "template" // We'll set the icon to the client's ui pref in reorganize_alerts()
		alert.master = new_master
	else
		alert.icon_state = "[initial(alert.icon_state)][severity]"

	alerts[category] = alert
	if(client && hud_used)
		hud_used.reorganize_alerts()
	alert.transform = matrix(32, 6, MATRIX_TRANSLATE)
	animate(alert, transform = matrix(), time = 2.5, easing = CUBIC_EASING)

	if(alert.timeout)
		spawn(alert.timeout)
			if(alert.timeout && alerts[category] == alert && world.time >= alert.timeout)
				clear_alert(category)
		alert.timeout = world.time + alert.timeout - world.tick_lag
	return alert

// Proc to clear an existing alert.
/mob/proc/clear_alert(category)
	var/obj/abstract/screen/alert = alerts[category]
	if(!alert)
		return FALSE
	alerts -= category
	if(client && hud_used)
		hud_used.reorganize_alerts()
	client.screen -= alert
	qdel(alert)

/obj/abstract/screen/alert
	name = "Alert"
	desc = "Something seems to have gone wrong with this alert, so report this bug please"
	icon = 'icons/mob/screen_alert.dmi'
	icon_state = "default"
	mouse_opacity = TRUE
	var/timeout = 0 //If set to a number, this alert will clear itself after that many deciseconds
	var/severity = 0

/obj/abstract/screen/alert/oxy
	name = "Choking"
	desc = "You're not getting enough oxygen. Find some good air before you pass out! The box in your backpack has an oxygen tank and gas mask in it."
	icon_state = "oxy"

/obj/abstract/screen/alert/tox_in_air
	name = "Toxic Gas"
	desc = "There's highly flammable, toxic plasma in the air and you're breathing it in. Find some fresh air. The box in your backpack has an oxygen tank and gas mask in it."
	icon_state = "tox_in_air"

/obj/abstract/screen/alert/fat
	name = "Fat"
	desc = "You ate too much food, lardass. Run around the station and lose some weight."
	icon_state = "fat"

/obj/abstract/screen/alert/hungry
	name = "Hungry"
	desc = "Some food would be good right about now."
	icon_state = "hungry"

/obj/abstract/screen/alert/starving
	name = "Starving"
	desc = "Some food would be to kill for right about now. The hunger pains make moving around a chore."
	icon_state = "starving"

/obj/abstract/screen/alert/hot
	name = "Too Hot"
	desc = "You're flaming hot! Get somewhere cooler and take off any insulating clothing like a fire suit."
	icon_state = "hot"

/obj/abstract/screen/alert/cold
	name = "Too Cold"
	desc = "You're freezing cold! Get somewhere warmer and take off any insulating clothing like a space suit."
	icon_state = "cold"

/obj/abstract/screen/alert/lowpressure
	name = "Low Pressure"
	desc = "The air around you is hazardously thin. A space suit would protect you."
	icon_state = "lowpressure"

/obj/abstract/screen/alert/highpressure
	name = "High Pressure"
	desc = "The air around you is hazardously thick. A fire suit would protect you."
	icon_state = "highpressure"

/obj/abstract/screen/alert/alien_tox
	name = "Plasma"
	desc = "There's flammable plasma in the air. If it lights up, you'll be toast."
	icon_state = "alien_tox"

/obj/abstract/screen/alert/alien_fire
	name = "Burning"
	desc = "It's too hot! Flee to space or at least away from the flames. Standing on weeds will heal you up."
	icon_state = "alien_fire"

//SILICONS
/obj/abstract/screen/alert/nocell
	name = "Missing Power Cell"
	desc = "Unit has no power cell. No modules available until a power cell is reinstalled. Robotics may provide assistance."

/obj/abstract/screen/alert/emptycell
	name = "Out of Power"
	desc = "Unit's power cell has no charge remaining. No modules available until power cell is recharged. Reharging stations are available in robotics, the dormitory's bathrooms. and near the AI's core."
	icon_state = "emptycell"

/obj/abstract/screen/alert/lowcell
	name = "Low Charge"
	desc = "Unit's power cell is running low. Reharging stations are available in robotics, the dormitory's bathrooms. and the AI satelite."
	icon_state = "lowcell"

//OBJECTS
/obj/abstract/screen/alert/buckled
	name = "Buckled"
	desc = "You've been buckled to something and can't move. Click the alert to unbuckle unless you're handcuffed."

/obj/abstract/screen/alert/handcuffed // Not used right now.
	name = "Handcuffed"
	desc = "You're handcuffed and can't act. If anyone drags you, you won't be able to move. Click the alert to free yourself."

//Only edit, use, or override these if you're editing the system as a whole
//Re-render all alerts - also called in /datum/hud/show_hud() because it's needed there
/datum/hud/proc/reorganize_alerts()
	var/list/alerts = mymob.alerts
	var/icon_pref
	if(!hud_shown)
		for(var/i = 1, i <= alerts.len, i++)
			mymob.client.screen -= alerts[alerts[i]]
		return 1
	for(var/i = 1, i <= alerts.len, i++)
		var/obj/abstract/screen/alert = alerts[alerts[i]]
		if(alert.icon_state == "template")
			if(!icon_pref)
				icon_pref = ui_style2icon(mymob.client.prefs.UI_style)
			alert.icon = icon_pref
		switch(i)
			if(1)
				. = ui_alert1
			if(2)
				. = ui_alert2
			if(3)
				. = ui_alert3
			if(4)
				. = ui_alert4
			if(5)
				. = ui_alert5 // Right now there's 5 slots
		alert.screen_loc = .
		mymob.client.screen |= alert
	return TRUE

/mob
	var/list/alerts = list() // contains /obj/abstract/screen only // On /mob so clientless mobs will throw alerts properly

/obj/abstract/screen/alert/Click(location, control, params)
	if(!usr || !usr.client)
		return
	var/paramslist = params2list(params)
	if(paramslist["shift"]) // screen objects don't do the normal Click() stuff so we'll cheat
		usr << "<span class='notice'>[name]</span> - <span class='info'>[desc]</span>"
		return
	if(master)
		return usr.client.Click(master, location, control, params)

/obj/abstract/screen/alert/MouseEntered(location,control,params)
	openToolTip(usr,src,params,title = name,content = desc)

/obj/abstract/screen/alert/Destroy()
	severity = 0
	master = null
	..()