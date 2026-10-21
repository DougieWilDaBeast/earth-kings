extends RefCounted
## What another company says when the party walks up to them (play-test 8, ask 2: "the dialogue options
## are who are you, have you been up the Tower, any advice and goodbye"; call BX). Each company in
## `life.climbers.companies` speaks in its own voice (`life.climbers.voices` in `data/world_rules.json`):
## its own hello, its own answers to the three questions everyone asks, two questions only it is asked,
## and its own goodbye. The party words its questions a few ways (`wording`), and what else comes up is
## drawn from where they are met (`asks`): the road, a Tower floor they rest on, or a floor they climb
## beside the party, each ask kept to the floors it fits. The same company in the same place says the
## same; met elsewhere, it talks of other things. People living on a floor draw theirs the same way
## ([method drawn]). Loaded by path ([D41]).

const ROAD := "road"
const FLOOR := "floor"
const SHARED := "shared"


static func rules() -> Dictionary:
	return Database.world_rules.get("life", {}).get("climbers", {})


## A `talk` block (docs/04 → talk) for [param company] met at [param where] (ROAD, FLOOR or SHARED) on
## [param floor] (0 on the road). [param key] picks the wording and the place's questions: pass the
## same thing each time the party meets them there. A company with no voice of its own talks as the
## old shared block has it.
static func block(company: String, where: String, floor: int, key: Variant) -> Dictionary:
	var r := rules()
	var voice: Dictionary = (r.get("voices", {}) as Dictionary).get(company, {})
	if voice.is_empty():
		return r.get("talk", {}) if where == ROAD else (r.get("on_the_floors", {}) as Dictionary).get("talk", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([company, where, floor, key])
	var words := { "floor": floor, "next": floor + 1, "company": company }
	var wording: Dictionary = r.get("wording", {})
	var up := "up" if where == ROAD else "up_here"
	var asks: Array = []
	for topic: String in ["who", up, "advice"]:
		if voice.has(topic):
			asks.append({ "q": _pick(rng, wording.get(topic, ["..."])), "a": str(voice[topic]) })
	asks.append_array(voice.get("own", []))
	var place: Array = []
	for ask: Dictionary in (r.get("asks", {}) as Dictionary).get(where, []):
		if floor >= int(ask.get("from", 0)) and floor <= int(ask.get("to", 999)):
			place.append(ask)
	asks.append_array(drawn(place, int(r.get("place_asks", 2)), rng))
	var hello: Variant = voice.get({ ROAD: "hello", FLOOR: "floor_hello", SHARED: "shared_hello" }[where], "...")
	return {
		"hello": _format(hello, words),
		"ask": asks.map(func(ask: Dictionary) -> Dictionary:
			return { "q": str(ask.get("q", "...")).format(words), "a": str(ask.get("a", "...")).format(words) }),
		"leave": _pick(rng, r.get("leave", ["Goodbye."])),
		"bye": str(voice.get("bye" if where == ROAD else "floor_bye", voice.get("bye", "Mm."))).format(words),
	}


## [param count] of [param pool], drawn by [param rng] without one twice, in the pool's own order.
static func drawn(pool: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var order: Array = range(pool.size())
	for i in range(order.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: int = order[i]
		order[i] = order[j]
		order[j] = swap
	var kept: Array = order.slice(0, mini(count, order.size()))
	kept.sort()
	return kept.map(func(i: int) -> Dictionary: return pool[i])


static func _pick(rng: RandomNumberGenerator, options: Variant) -> String:
	if options is Array:
		return str((options as Array)[rng.randi() % (options as Array).size()]) if not (options as Array).is_empty() else "..."
	return str(options)


static func _format(text: Variant, words: Dictionary) -> Variant:
	if text is Array:
		return (text as Array).map(func(line: Variant) -> String: return str(line).format(words))
	return str(text).format(words)
