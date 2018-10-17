/spell/targeted/visceral
	name = "Visceral Attack"
	desc = "Inflict massive damage on enemies that are in a susceptible state."
	abbreviation = "VA"

	school = "evocation"
	invocation = null
	range = 1
	cooldown_min = 5 SECONDS
	sparks_spread = FALSE
	spell_flags = WAIT_FOR_CLICK
	hud_state = "wiz_disint"

/spell/targeted/visceral/cast(var/list/targets)
	..()
	var/mob/living/L = holder
	for(var/mob/living/target in targets)
		if(L.is_pacified(VIOLENCE_DEFAULT,target))
			return
		if(isliving(target))
			var/mob/living/T = target
			var/backstab_dir = get_dir(L, T)
			if(T.incapacitated() || ((L.dir & backstab_dir) && (T.dir & backstab_dir)))
				playsound(T, get_sfx("machete_hit"),50,1)
				if(istype(T.loc, /turf/simulated))
					var/turf/simulated/location = T.loc 
					location.add_blood_floor(T)
			else
				to_chat(L, "<span class='warning'>Your target isn't vulnerable enough.</span>")
				T.gib()
