class_name Banter
extends RefCounted
## What the party say to each other when nothing is trying to kill them.
##
## Nothing is authored per character. An exchange has an `a` and a `b`, and
## anyone can be either — which means hires talk too, and the party you ended
## up with is the party the lines are about.
##
## Which exchange comes up depends on the *bond* between the two speakers: a
## number that moves with what they have survived together. Warm pairs tell
## stories, cold pairs bicker, and both drift as the run goes on.

const WARM := "warm"
const COLD := "cold"
const EVEN := "even"
const ANY := "any"

## Occasions an exchange can be written for.
const ROAD := "road"
const REST := "rest"
const AFTER_BATTLE := "after_battle"
const GRAVE := "grave"


static func rules() -> Dictionary:
	return Database.banter.get("rules", {})


# --- who gets on with whom ----------------------------------------------------


## How well two people get on. Symmetric, and kept on both of them.
static func bond(a: Character, b: Character) -> int:
	return int(a.bonds.get(b.id, 0))


static func remember(a: Character, b: Character, amount: int) -> void:
	if amount == 0 or a == b:
		return
	a.bonds[b.id] = bond(a, b) + amount
	b.bonds[a.id] = bond(b, a) + amount


## Coming through something together is worth a notch to everyone who did.
static func shared(party: Array, amount: int) -> void:
	for i in party.size():
		for j in range(i + 1, party.size()):
			remember(party[i], party[j], amount)


static func mood(a: Character, b: Character) -> String:
	var value := bond(a, b)
	if value >= int(rules().get("warm_at", 6)):
		return WARM
	if value <= int(rules().get("cold_at", -3)):
		return COLD
	return EVEN


# --- what they say ------------------------------------------------------------


## An exchange for [param occasion], or nothing if none of them fits the party
## as it stands. Lines come back ready to show: `{ speaker, text }`.
static func pick(world: World, party: Array, occasion: String, rng: RandomNumberGenerator) -> Array:
	if party.size() < 2:
		return []
	var a: Character = party[rng.randi() % party.size()]
	var b: Character = a
	while b == a:
		b = party[rng.randi() % party.size()]
	return _exchange(world, a, b, occasion, rng, _context(world, party))


## The same, between two people the caller has already chosen — somebody you
## walked up to, rather than whoever the dice picked.
static func between(
	world: World, a: Character, b: Character, occasion: String, rng: RandomNumberGenerator
) -> Array:
	if a == b:
		return []
	return _exchange(world, a, b, occasion, rng, _context(world, [a, b]))


## An exchange dressed as a conversation, so the dialogue box can play it with
## both faces on it.
static func as_dialogue(exchange: Array, a: Character, b: Character) -> Dictionary:
	return {
		"cast": { a.display_name: a.template_id, b.display_name: b.template_id },
		"lines": exchange,
	}


static func _exchange(
	world: World,
	a: Character,
	b: Character,
	occasion: String,
	rng: RandomNumberGenerator,
	context: Dictionary
) -> Array:
	var pool: Array = Database.banter.get("exchanges", []).filter(
		func(e: Dictionary) -> bool: return _fits(e, occasion, mood(a, b), context)
	)
	if pool.is_empty():
		return []

	var chosen: Dictionary = pool[rng.randi() % pool.size()]
	remember(a, b, int(chosen.get("bond", 0)))
	return _spoken(chosen, a, b, context)


## The same exchange flattened into log lines, for scenes that would rather not
## stop the game to show a conversation.
static func as_lines(exchange: Array) -> Array[String]:
	var out: Array[String] = []
	for line: Dictionary in exchange:
		out.append("%s: %s" % [line["speaker"], line["text"]])
	return out


static func _fits(exchange: Dictionary, occasion: String, pair_mood: String, context: Dictionary) -> bool:
	if exchange.get("occasion", ROAD) != occasion:
		return false
	var wanted: String = exchange.get("mood", ANY)
	if wanted != ANY and wanted != pair_mood:
		return false
	var needs: String = exchange.get("needs", "")
	return needs == "" or context.get(needs, "") not in [null, "", false]


static func _spoken(exchange: Dictionary, a: Character, b: Character, context: Dictionary) -> Array:
	var filled: Dictionary = context.duplicate()
	filled["a"] = a.display_name
	filled["b"] = b.display_name

	var out: Array = []
	for line: Dictionary in exchange.get("lines", []):
		var who: Character = a if line.get("who", "a") == "a" else b
		out.append({ "speaker": who.display_name, "text": _fill(line.get("text", ""), filled) })
	return out


static func _fill(text: String, values: Dictionary) -> String:
	var out := text
	for key: String in values:
		out = out.replace("{%s}" % key, str(values[key]))
	return out


## What the party could plausibly be talking about right now.
static func _context(world: World, party: Array) -> Dictionary:
	return {
		"place": _place(world),
		"deed": _newest_deed(world),
		"fallen": _somebody_lost(world),
		"wounded": party.any(func(c: Character) -> bool: return c.current_hp() < c.max_hp()),
	}


static func _place(world: World) -> String:
	var site := world.site_at(world.player_cell)
	if site != null:
		return site.display_name
	return str(world.terrain_at(world.player_cell).get("name", "open ground")).to_lower()


## The last thing they did that anybody bothered writing down.
static func _newest_deed(world: World) -> String:
	var best: Dictionary = {}
	for deed: Dictionary in world.deeds:
		if best.is_empty() or int(deed.get("step", 0)) > int(best.get("step", 0)):
			best = deed
	return best.get("line", "")


## Somebody they buried. Graves outlive the roster, so they are what is left to
## remember anyone by.
static func _somebody_lost(world: World) -> String:
	for site: Site in world.sites:
		if Memorial.is_grave(site):
			return str(site.data.get("name", ""))
	return ""
