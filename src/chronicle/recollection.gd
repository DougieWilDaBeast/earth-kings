class_name Recollection
extends RefCounted
## What the party makes of the road behind them.
##
## Banter is two people talking to each other. A recollection is one of them
## looking back: at the deed word is still travelling from, at the grave they
## left on a hillside, at the fields they have already fought over. Nothing is
## authored per character, and every line is only ever said once a run, so the
## party never repeats itself.

## Where a spent recollection is written down.
const SAID_PREFIX := "recalled:"


static func pool() -> Array:
	return Database.banter.get("reflections", [])


## Somebody in [param party] on something behind them, ready for the dialogue
## box: `{ speaker, text }`. Empty when the run has nothing to say yet.
static func remark(world: World, party: Array, rng: RandomNumberGenerator) -> Dictionary:
	if party.is_empty() or world == null:
		return {}
	var order := party.duplicate()
	order.shuffle()
	for who: Character in order:
		var facts := recall(world, party, who)
		var fresh := _unsaid(facts)
		if fresh.is_empty():
			continue
		var chosen: Dictionary = fresh[rng.randi() % fresh.size()]
		GameState.set_flag(_key(chosen))
		facts["a"] = who.display_name
		return { "speaker": who.display_name, "text": _fill(str(chosen.get("text", "")), facts) }
	return {}


## Whether there is anything left for them to look back on.
static func has_something_to_say(world: World, party: Array) -> bool:
	if party.is_empty() or world == null:
		return false
	for who: Character in party:
		if not _unsaid(recall(world, party, who)).is_empty():
			return true
	return false


## Lines this party could say that they have not said already.
static func _unsaid(facts: Dictionary) -> Array:
	return pool().filter(
		func(entry: Dictionary) -> bool:
			return _fits(entry, facts) and not GameState.has_flag(_key(entry))
	)


## Everything about the run so far that a line could be written about. A
## reflection is offered only when the fact it is `about` amounts to something.
static func recall(world: World, party: Array, speaker: Character) -> Dictionary:
	return {
		"place": _place(world),
		"deed": _newest_deed(world),
		"fallen": _somebody_lost(world),
		"friend": _closest_to(party, speaker),
		"battles": GameState.cleared_battles.size(),
		"gold": GameState.gold,
		"floors": world.tower_floor,
		"miles": world.steps,
		"wounded": party.any(func(c: Character) -> bool: return c.current_hp() < c.max_hp()),
		"company": party.size(),
	}


static func _fits(entry: Dictionary, facts: Dictionary) -> bool:
	var about: String = entry.get("about", "")
	if about == "":
		return true
	var value: Variant = facts.get(about, "")
	if value is int:
		return int(value) >= int(entry.get("at_least", 1))
	return value not in [null, "", false]


static func _key(entry: Dictionary) -> String:
	return "%s%d" % [SAID_PREFIX, hash(entry.get("text", ""))]


static func _fill(text: String, values: Dictionary) -> String:
	var out := text
	for key: String in values:
		out = out.replace("{%s}" % key, str(values[key]))
	return out


static func _place(world: World) -> String:
	var site := world.site_at(world.player_cell)
	if site != null:
		return site.display_name
	return str(world.terrain_at(world.player_cell).get("name", "open ground")).to_lower()


static func _newest_deed(world: World) -> String:
	var best: Dictionary = {}
	for deed: Dictionary in world.deeds:
		if best.is_empty() or int(deed.get("step", 0)) > int(best.get("step", 0)):
			best = deed
	return best.get("line", "")


static func _somebody_lost(world: World) -> String:
	for site: Site in world.sites:
		if Memorial.is_grave(site):
			return str(site.data.get("name", ""))
	return ""


## Whoever the speaker has been through the most with — the one they would name.
static func _closest_to(party: Array, speaker: Character) -> String:
	var best: Character = null
	for other: Character in party:
		if other == speaker:
			continue
		if best == null or Banter.bond(speaker, other) > Banter.bond(speaker, best):
			best = other
	if best == null or Banter.bond(speaker, best) <= 0:
		return ""
	return best.display_name
