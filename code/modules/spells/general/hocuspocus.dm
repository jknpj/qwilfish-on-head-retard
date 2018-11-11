
var/global/list/spell_whitelist = list(
	/spell/area_teleport,
	/spell/mirror_of_pain,
	/spell/aoe_turf/ring_of_fire,
	/spell/aoe_turf/disable_tech,
	/spell/aoe_turf/smoke,
	/spell/aoe_turf/conjure/carp,
	/spell/aoe_turf/conjure/creature,
	/spell/aoe_turf/conjure/gingerbreadman,
	/spell/aoe_turf/lightbulb,
	/spell/aoe_turf/fall,
	/spell/aoe_turf/disable_tech,
	/spell/aoe_turf/charge,
	/spell/aoe_turf/blink,
	/spell/aoe_turf/conjure/spares,
	/spell/aoe_turf/conjure/snowmobile,
	/spell/aoe_turf/conjure/pontiac,
	/spell/aoe_turf/conjure/forcewall,
	/spell/targeted/balefulmutate,
	/spell/targeted/buttbots_revenge,
	/spell/targeted/disorient,
	/spell/targeted/ethereal_jaunt,
	/spell/targeted/feint,
	/spell/targeted/flesh_to_stone,
	/spell/targeted/genetic/blind,
	/spell/targeted/genetic/mutate,
	/spell/targeted/grease,
	/spell/targeted/mind_transfer,
	/spell/targeted/parrotmorph,
	/spell/targeted/pumpkin_head,
	/spell/targeted/shoesnatch,
	)

/spell/hocus_pocus
	name = "Hocus Pocus"
	desc = "This spell casts a another spell."
	abbreviation = "HP"
	user_type = USER_TYPE_WIZARD
	spell_flags = NEEDSCLOTHES
	autocast_flags = AUTOCAST_NOTARGET
	invocation = "I C'N DO AN'TH'NG"
	invocation_type = SpI_SHOUT
	hud_state = "hocuspocus"
	var/spell/current_spell = null

/spell/hocus_pocus/proc/change_spell()
	if(current_spell)
		qdel(current_spell)
		current_spell = null
	var/picked_spell = pick(spell_whitelist)
	current_spell = new picked_spell

//spell/hocus_pocus/New()
//	..()
	//change_spell()

/spell/hocus_pocus/perform()
	change_spell()
	..()

/spell/hocus_pocus/cast_check(var/skipcharge = 0, var/mob/user = usr)
	if(current_spell)
		return current_spell.cast_check(skipcharge, user)
	..()

/spell/hocus_pocus/choose_targets(mob/user = usr)
	if(current_spell)
		return current_spell.choose_targets(user)
	..()

/spell/hocus_pocus/is_valid_target(var/target, mob/user, list/options)
	if(current_spell)
		return current_spell.is_valid_target(target, user, options)
	..()

/spell/hocus_pocus/cast(list/targets, mob/user)
	if(current_spell)
		return current_spell.cast(targets, user)
	..()

/spell/hocus_pocus/after_cast(list/targets, mob/user)
	if(current_spell)
		return current_spell.after_cast(targets, user)
	..()