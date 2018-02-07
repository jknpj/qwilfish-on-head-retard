//Refer to life.dm for caller

/mob/living/carbon/human/proc/handle_environment(datum/gas_mixture/environment)
	if(!environment || (flags & INVULNERABLE))
		return
	var/loc_temp = get_loc_temp(environment)

//	to_chat(world, "Loc temp: [loc_temp] - Body temp: [bodytemperature] - Fireloss: [getFireLoss()] - Thermal protection: [get_thermal_protection()] - Fire protection: [thermal_protection + add_fire_protection(loc_temp)] - Heat capacity: [environment_heat_capacity] - Location: [loc] - src: [src]")

	//Body temperature is adjusted in two steps. Firstly your body tries to stabilize itself a bit.
	if(stat != DEAD)
		handle_body_temperature()
		//log_debug("Adjusting to atmosphere.")

	//After then, it reacts to the surrounding atmosphere based on your thermal protection
	if(!on_fire) //If you're on fire, you do not heat up or cool down based on surrounding gases
		if(loc_temp < get_skin_temperature())
			var/thermal_loss = get_thermal_loss(environment)
			bodytemperature -= thermal_loss
		else
			var/thermal_protection = get_heat_protection(get_heat_protection_flags(loc_temp)) //This returns a 0 - 1 value, which corresponds to the percentage of protection based on what you're wearing and what you're exposed to.
			if(thermal_protection < 1)
				bodytemperature += min((1 - thermal_protection) * ((loc_temp - get_skin_temperature()) / BODYTEMP_HEAT_DIVISOR), BODYTEMP_HEATING_MAX)

	if (status_flags & GODMODE)
		clear_alert("temp")
		clear_alert("pressure")
		return

	// Slimed carbons are protected against heat damage
	if (bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT || (bodytemperature > BODYTEMP_HEAT_DAMAGE_LIMIT && dna.mutantrace != "slime"))
		// Update fire/cold overlay
		var/temp_alert = (bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT) ? 1 : 2
		throw_alert("temp","hot",temp_alert)
		if(!(istype(loc, /obj/machinery/atmospherics/unary/cryo_cell)))
			if (dna.mutantrace != "slime")
				var/temp_damage = get_body_temperature_damage(bodytemperature)
				var/temp_weapon = (bodytemperature < BODYTEMP_COLD_DAMAGE_LIMIT) ? WPN_LOW_BODY_TEMP : WPN_HIGH_BODY_TEMP
				apply_damage(temp_damage, BURN, used_weapon = temp_weapon)
			else // Slimed carbons get toxin instead of cold damage
				adjustToxLoss(round(BODYTEMP_HEAT_DAMAGE_LIMIT - bodytemperature))
	else
		clear_alert("temp")

	//Account for massive pressure differences.  Done by Polymorph
	//Made it possible to actually have something that can protect against high pressure... Done by Errorage. Polymorph now has an axe sticking from his head for his previous hardcoded nonsense!
	var/pressure = environment.return_pressure()
	var/adjusted_pressure = calculate_affecting_pressure(pressure) //Returns how much pressure actually affects the mob.
	if(adjusted_pressure >= species.hazard_high_pressure)
		adjustBruteLoss(min(((adjusted_pressure/species.hazard_high_pressure) - 1) * PRESSURE_DAMAGE_COEFFICIENT, MAX_HIGH_PRESSURE_DAMAGE))
		throw_alert("pressure","highpressure",2)
	else if(adjusted_pressure >= species.warning_high_pressure)
		throw_alert("pressure","highpressure",1)
	else if(adjusted_pressure >= species.warning_low_pressure)
		clear_alert("pressure")
	else if(adjusted_pressure >= species.hazard_low_pressure)
		throw_alert("pressure","lowpressure",1)
	else
		if(!(M_RESIST_COLD in mutations))
			adjustBruteLoss(LOW_PRESSURE_DAMAGE)
			if(istype(src.loc, /turf/space))
				adjustBruteLoss(LOW_PRESSURE_DAMAGE) //Space doubles damage (for some reason space vacuum is not station vacuum, nice snowflake)
			throw_alert("pressure","lowpressure",2)
		else
			throw_alert("pressure","lowpressure",1)

	if((environment.toxins / environment.volume * CELL_VOLUME) > MOLES_PLASMA_VISIBLE)
		pl_effects()

// Helper proc to map body temperatures to its corresponding heat/cold damage value
/mob/living/carbon/human/proc/get_body_temperature_damage(var/temperature)
	if (temperature < species.cold_level_3)
		return COLD_DAMAGE_LEVEL_3
	else if (temperature < species.cold_level_2)
		return COLD_DAMAGE_LEVEL_2
	else if (temperature < species.cold_level_1)
		return COLD_DAMAGE_LEVEL_1
	else if (temperature >= species.heat_level_1)
		return HEAT_DAMAGE_LEVEL_1
	else if (temperature >= species.heat_level_2)
		return HEAT_DAMAGE_LEVEL_2
	else if (temperature >= species.heat_level_3)
		return HEAT_DAMAGE_LEVEL_3
	else
		return 0