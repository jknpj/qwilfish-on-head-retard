/*
  HOW IT WORKS

  The radio_controller is a global object maintaining all radio transmissions, think about it as about "ether".
  Note that walkie-talkie, intercoms and headsets handle transmission using nonstandard way.
  procs:

    add_object(obj/device as obj, var/new_frequency as num, var/filter as text|null = null)
      Adds listening object.
      parameters:
        device - device receiving signals, must have proc receive_signal (see description below).
          one device may listen several frequencies, but not same frequency twice.
        new_frequency - see possibly frequencies below;
        filter - thing for optimization. Optional, but recommended.
                 All filters should be consolidated in this file, see defines later.
                 Device without listening filter will receive all signals (on specified frequency).
                 Device with filter will receive any signals sent without filter.
                 Device with filter will not receive any signals sent with different filter.
      returns:
       Reference to frequency object.

    remove_object (obj/device, old_frequency)
      Obliviously, after calling this proc, device will not receive any signals on old_frequency.
      Other frequencies will left unaffected.

   return_frequency(var/frequency as num)
      returns:
       Reference to frequency object. Use it if you need to send and do not need to listen.

  radio_frequency is a global object maintaining list of devices that listening specific frequency.
  procs:

    post_signal(obj/source as obj|null, datum/signal/signal, var/filter as text|null = null, var/range as num|null = null)
      Sends signal to all devices that wants such signal.
      parameters:
        source - object, emitted signal. Usually, devices will not receive their own signals.
        signal - see description below.
        filter - described above.
        range - radius of regular byond's square circle on that z-level. null means everywhere, on all z-levels.

  obj/proc/receive_signal(datum/signal/signal, var/receive_method as num, var/receive_param)
    Handler from received signals. By default does nothing. Define your own for your object.
    Avoid of sending signals directly from this proc, use spawn(-1). Do not use sleep() here please.
      parameters:
        signal - see description below. Extract all needed data from the signal before doing sleep(), spawn() or return!
        receive_method - may be TRANSMISSION_WIRE or TRANSMISSION_RADIO.
          TRANSMISSION_WIRE is currently unused.
        receive_param - for TRANSMISSION_RADIO here comes frequency.

  datum/signal
    vars:
    source
      an object that emitted signal. Used for debug and bearing.
    data
      list with transmitting data. Usual use pattern:
        data["msg"] = "hello world"
    encryption
      Some number symbolizing "encryption key".
      Note that game actually do not use any cryptography here.
      If receiving object don't know right key, it must ignore encrypted signal in its receive_signal.

*/
var/list/all_radios = list()
/proc/add_radio(var/obj/item/radio, freq)
	if(!freq || !radio)
		return
	if(!all_radios["[freq]"])
		all_radios["[freq]"] = list(radio)
		return freq

	all_radios["[freq]"] |= radio
	return freq

/proc/remove_radio(var/obj/item/radio, freq)
	if(!freq || !radio)
		return
	if(!all_radios["[freq]"])
		return

	all_radios["[freq]"] -= radio

/proc/remove_radio_all(var/obj/item/radio)
	for(var/freq in all_radios)
		all_radios["[freq]"] -= radio
/*
Frequency range: 1200 to 1600
Radiochat range: 1441 to 1489 (most devices refuse to be tune to other frequency, even during mapmaking)

Radio:
1459 - standard radio chat
1351 - Science
XXXX - Command // Randomly generated at roundstart
1355 - Medical
1357 - Engineering
XXXX - Security // Randomly generated at roundstart
1441 - death squad
1443 - Confession Intercom
1349 - Botany, chef, bartender
1347 - Cargo techs

Devices:
1451 - tracking implant
1457 - RSD default

On the map:
1311 for prison shuttle console (in fact, it is not used)
1367 for recycling/mining processing machinery and conveyors
1435 for status displays
1437 for atmospherics/fire alerts
1439 for engine components
1439 for air pumps, air scrubbers, atmo control
1441 for atmospherics - supply tanks
1443 for atmospherics - distribution loop/mixed air tank
1445 for bot nav beacons
1447 for mulebot, secbot and ed209 control
1449 for airlock controls, electropack, magnets
1451 for toxin lab access
1453 for engineering access
1455 for AI access
*/

var/list/radiochannels = list(
	"Common" = 1459,
	"AI Private" = 1447,
	"Deathsquad" = 1441,
	"Security" = 1359,
	"Engineering" = 1357,
	"Command" = 1353,
	"Medical" = 1355,
	"Science" = 1351,
	"Service" = 1349,
	"Supply" = 1347,
	"Response Team" = 1345,
	"Raider" = 1215,
	"Syndicate" = 1213,
	"DJ" = 1201
)

// The channels the AI and the Librarian have access to.
var/list/radiochannels_access = list(
	"Common" = TRUE,
	"AI Private" = TRUE,
	"Deathsquad" = FALSE,
	"Security" = TRUE,
	"Engineering" = TRUE,
	"Command" = TRUE,
	"Medical" = TRUE,
	"Science" = TRUE,
	"Service" = TRUE,
	"Supply" = TRUE,
	"Response Team" = TRUE,
	"Raider" = FALSE,
	"Syndicate" = FALSE,
	"DJ" = FALSE
)

var/list/random_radiochannels = list(
	"Common" = FALSE,
	"AI Private" = TRUE,
	"Deathsquad" = TRUE,
	"Security" = TRUE,
	"Engineering" = FALSE,
	"Command" = TRUE,
	"Medical" = FALSE,
	"Science" = FALSE,
	"Service" = FALSE,
	"Supply" = FALSE,
	"Response Team" = TRUE,
	"Raider" = TRUE,
	"Syndicate" = TRUE,
	"DJ" = TRUE,
)

var/list/crypted_radiochannels_reverse = list(
	"1213" = "Syndicate",
	"1215" = "Raider",
	"1359" = "Security",
	"1353" = "Command",
	"1345" = "Response Team"
)

var/list/radiochannelsreverse = list(
	"1201" = "DJ",
	"1213" = "Syndicate",
	"1215" = "Raider",
	"1345" = "Response Team",
	"1347" = "Supply",
	"1349" = "Service",
	"1351" = "Science",
	"1355" = "Medical",
	"1353" = "Command",
	"1357" = "Engineering",
	"1359" = "Security",
	"1441" = "Deathsquad",
	"1447" = "AI Private",
	"1459" = "Common"
)

// Make random frequencies for the "secure" channels so that they are not easily listened to.

/proc/makeSecureChannels()
	var/old_freqs = list()
	for (var/channel in random_radiochannels)
		if (random_radiochannels[channel]) // If it's indeed secured
			var/old_freq = radiochannels[channel]
			var/assigned = FALSE
			while (!assigned)
				var/new_freq = 2*rand(600, 698)+1 // We want an odd frequency
				if (!(new_freq in radiochannels) && !(new_freq in old_freqs)) // If there's no channel associated to that frequence, or if it's not an old one (prevent some problem with span being wrongly attributed)
					assigned = TRUE
					var/new_freq_txt = num2text(new_freq)
					var/old_freq_txt = num2text(old_freq)

					old_freqs += old_freq_txt

					radiochannels[channel] = new_freq
					radiochannelsreverse[new_freq_txt] = channel

					var/span = freqtospan[old_freq_txt]
					freqtospan[new_freq_txt] = span

					freqtoname[new_freq_txt] = channel

					if (old_freq_txt in crypted_radiochannels_reverse)
						crypted_radiochannels_reverse[new_freq_txt] = channel
						crypted_radiochannels_reverse -= old_freq_txt

	for (var/old_freq in old_freqs)
		radiochannelsreverse -= old_freq
		freqtospan -= old_freq
		freqtoname -= old_freq

/proc/store_frequencies_in_memory(var/mob/living/L)
	var/data = ("<h3>Frequencies of the station:</h3>")
	for (var/channel in radiochannels_access)
		if (radiochannels_access[channel] && channel in radiochannels) // We know about it and it actually exists in the channel list
			data += ("<b>[channel]</b>: <i>[radiochannels[channel]/10]</i> <br />")
	L.mind.store_memory(data)

//depenging helpers
#define DSQUAD_FREQ radiochannels["Deathsquad"] //death squad frequency, coloured grey in chat window
#define RESTEAM_FREQ radiochannels["Response Team"] //response team frequency, uses the deathsquad color at the moment.
#define AIPRIV_FREQ radiochannels["AI Private"] //AI private, colored magenta in chat window
#define DJ_FREQ radiochannels["DJ"] //Media
#define COMMON_FREQ radiochannels["Common"]

// central command channels, i.e deathsquid & response teams
#define CENT_FREQS = list(radiochannels["Deathsquad"], radiochannels["Response Team"])

#define COMM_FREQ radiochannels["Command"] //command, colored gold in chat window
#define SYND_FREQ radiochannels["Syndicate"]
#define RAID_FREQ radiochannels["Raider"] // for raiders

// department channels
#define SEC_FREQ radiochannels["Security"]
#define ENG_FREQ radiochannels["Engineering"]
#define SCI_FREQ radiochannels["Science"]
#define MED_FREQ radiochannels["Medical"]
#define SUP_FREQ radiochannels["Supply"]
#define SER_FREQ radiochannels["Service"]
#define ERT_FREQ radiochannels["Response Team"]

#define TRANSMISSION_WIRE	0
#define TRANSMISSION_RADIO	1

/* filters */
var/const/RADIO_TO_AIRALARM = "1"
var/const/RADIO_FROM_AIRALARM = "2"
var/const/RADIO_CHAT = "3" //deprecated
var/const/RADIO_ATMOSIA = "4"
var/const/RADIO_NAVBEACONS = "5"
var/const/RADIO_AIRLOCK = "6"
var/const/RADIO_SECBOT = "7"
var/const/RADIO_MULEBOT = "8"
var/const/RADIO_MAGNETS = "9"
var/const/RADIO_CONVEYORS = "10"

var/global/datum/controller/radio/radio_controller

/datum/controller/radio
	var/list/datum/radio_frequency/frequencies = new

/datum/controller/radio/proc/add_object(const/obj/device, const/_frequency, var/filter = null as text|null)
	var/datum/radio_frequency/frequency = return_frequency(_frequency)

	if(isnull(frequency))
		frequency = new
		frequency.frequency = _frequency
		frequencies[num2text(_frequency)] = frequency

	frequency.add_listener(device, filter)
	return frequency

/datum/controller/radio/proc/remove_object(const/obj/device, const/_frequency)
	var/datum/radio_frequency/frequency = return_frequency(_frequency)

	if(frequency)
		frequency.remove_listener(device)

		if(frequency.devices.len <= 0)
			frequencies.Remove(num2text(_frequency))

	return 1

/datum/controller/radio/proc/return_frequency(const/_frequency)
	return frequencies[num2text(_frequency)]

/datum/radio_frequency
	var/frequency as num
	var/list/list/obj/devices = list()

/datum/radio_frequency/proc/post_signal(obj/source as obj|null, datum/signal/signal, var/filter = null as text|null, var/range = null as num|null)
	//log_admin("DEBUG \[[world.timeofday]\]: post_signal {source=\"[source]\", [signal.debug_print()], filter=[filter]}")
	//var/N_f=0
	//var/N_nf=0
	//var/Nt=0
	var/turf/start_point
	if(range)
		start_point = get_turf(source)
		if(!start_point)
			returnToPool(signal)
			return 0

	if (filter) //here goes some copypasta. It is for optimisation. -rastaf0
		for(var/obj/device in devices[filter])
			if(device == source)
				continue
			if(range)
				var/turf/end_point = get_turf(device)
				if(!end_point)
					continue
				//if(max(abs(start_point.x-end_point.x), abs(start_point.y-end_point.y)) <= range)
				if(start_point.z!=end_point.z || get_dist(start_point, end_point) > range)
					continue
			device.receive_signal(signal, TRANSMISSION_RADIO, frequency)
		for(var/obj/device in devices["_default"])
			if(device == source)
				continue
			if(range)
				var/turf/end_point = get_turf(device)
				if(!end_point)
					continue
				//if(max(abs(start_point.x-end_point.x), abs(start_point.y-end_point.y)) <= range)
				if(start_point.z!=end_point.z || get_dist(start_point, end_point) > range)
					continue
			device.receive_signal(signal, TRANSMISSION_RADIO, frequency)
			//N_f++

	else
		for (var/next_filter in devices)
			//var/list/obj/DDD = devices[next_filter]
			//Nt+=DDD.len
			for(var/obj/device in devices[next_filter])
				if(device == source)
					continue
				if(range)
					var/turf/end_point = get_turf(device)
					if(!end_point)
						continue
					//if(max(abs(start_point.x-end_point.x), abs(start_point.y-end_point.y)) <= range)
					if(start_point.z!=end_point.z || get_dist(start_point, end_point) > range)
						continue
				device.receive_signal(signal, TRANSMISSION_RADIO, frequency)
				//N_nf++

	//log_admin("DEBUG: post_signal(source=[source] ([source.x], [source.y], [source.z]),filter=[filter]) frequency=[frequency], N_f=[N_f], N_nf=[N_nf]")


	returnToPool(signal)

/datum/radio_frequency/proc/add_listener(const/obj/device, var/filter)
	if(!filter) // FIXME
		filter = "_default"

	var/list/devices_at_filter = devices[filter]

	if(isnull(devices_at_filter))
		devices_at_filter = new
		devices[filter] = devices_at_filter

	devices_at_filter.Add(device)

/datum/radio_frequency/proc/remove_listener(const/obj/device, const/filter)
	var/list/devices_at_filter = devices[filter]

	// 1. check if it's an object
	// 2. check if it has contents
	// 3. check if the device is in contents
	if(devices_at_filter && devices_at_filter.len && devices_at_filter.Find(device))
		devices_at_filter.Remove(device)

		if(devices_at_filter.len <= 0)
			devices.Remove(filter)

/datum/radio_frequency/remove_listener(const/obj/device)
	for(var/filter in devices)
		..(device, filter)

var/list/pointers = list()

/client/proc/print_pointers()
	set name = "Debug Signals"
	set category = "Debug"

	if(!holder)
		return

	to_chat(src, "There are [pointers.len] pointers:")
	for(var/p in pointers)
		to_chat(src, p)
		var/datum/signal/S = locate(p)
		if(istype(S))
			to_chat(src, S.debug_print())

/obj/proc/receive_signal(datum/signal/signal, receive_method, receive_param)
	return

#define SIGNAL_WIRE     0
#define SIGNAL_RADIO    1
#define SIGNAL_SUBSPACE 2

/datum/signal
	var/obj/source

	var/transmission_method = SIGNAL_WIRE
	//0 = wire
	//1 = radio transmission
	//2 = subspace transmission

	var/data = list()
	var/encryption

	var/frequency = 0

/datum/signal/New()
	..()
	pointers += "\ref[src]"

/datum/signal/Destroy()
	pointers -= "\ref[src]"

/datum/signal/resetVariables()
	. = ..("data")

	source = null
	data = list()

/datum/signal/proc/copy_from(datum/signal/model)
	source = model.source
	transmission_method = model.transmission_method
	data = model.data
	encryption = model.encryption
	frequency = model.frequency

/datum/signal/proc/debug_print()
	if (source)
		. = "signal = {source = '[source]' ([source:x],[source:y],[source:z])\n"
	else
		. = "signal = {source = '[source]' ()\n"
	for (var/i in data)
		. += "data\[\"[i]\"\] = \"[data[i]]\"\n"
		if(islist(data[i]))
			var/list/L = data[i]
			for(var/t in L)
				. += "data\[\"[i]\"\] list has: [t]"

/datum/signal/proc/sanitize_data()
	for(var/d in data)
		var/val = data[d]
		if(istext(val))
			data[d] = strip_html_simple(val)
