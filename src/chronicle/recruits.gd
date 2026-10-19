extends RefCounted
## Asking anyone to walk with the company ([D277], Ewan's play-test 7: "you can ask someone to
## join you, they might say no, they might say yes. If they say no, you might be able to do quests
## with them and gain their trust, so that they would then join you").
##
## Somebody standing in an area with a `talk` block can be asked, unless they keep a post. The ask
## is a Charisma check inside their conversation ([Talk]); a yes or a no only sets a flag there,
## and [method settle] turns it into the thing itself once the conversation is over: a yes joins
## the roster at the lead's level, a no writes down how far the company had got with what they
## asked of it, so that doing it wins them over. Rules and lines live in
## `data/world_rules.json` → `recruit_anyone`. Loaded by path ([D41]). Pure logic: no nodes.

const Names := preload("res://src/chronicle/names.gd")

const YES := "recruit:yes:"
const NO := "recruit:no:"
const TRUST := "recruit:trust:"
const JOINED := "recruit:joined:"

## Who was spoken to in the conversation now open, by key, so [method settle] knows who said yes.
static var _spoken: Dictionary = {}


static func rules() -> Dictionary:
	return Database.world_rules.get("recruit_anyone", {})


## The key a person is known by: their area, their name and where they stand, since two settlers
## can share a name.
static func key(area_id: String, person: Dictionary) -> String:
	var cell: Array = person.get("cell", [0, 0])
	return "%s:%s@%d,%d" % [area_id, str(person.get("name", person.get("unit", "someone"))),
		int(cell[0]) if cell.size() > 0 else 0, int(cell[1]) if cell.size() > 1 else 0]


static func has_joined(area_id: String, person: Dictionary) -> bool:
	return GameState.has_flag(JOINED + key(area_id, person))


## Whether they could be asked at all: they talk, keep no post, and have not already come.
static func askable(area_id: String, person: Dictionary) -> bool:
	var talk: Dictionary = person.get("talk", {})
	if talk.is_empty() or not bool(person.get("recruit", true)):
		return false
	if talk.has("sells") or talk.has("heal") or talk.has("hone") or bool(person.get("guild", false)):
		return false
	if Database.unit_template(str(person.get("unit", ""))).is_empty():
		return false
	var r := rules()
	if area_id in r.get("no_areas", []) or str(person.get("name", "")) in r.get("stays", []):
		return false
	return not has_joined(area_id, person)


## How hard they are to talk round: one of the story folk is harder ([D277]).
static func dc(person: Dictionary) -> int:
	if person.has("recruit_dc"):
		return int(person["recruit_dc"])
	var unit := str(person.get("unit", ""))
	for each: Dictionary in Database.story_npcs.values():
		if str(each.get("unit", "")) == unit:
			return int(rules().get("story_dc", 17))
	return int(rules().get("dc", 13))


## What they want done before they will come: their own favour if they have one, else one of the
## `trust` asks, the same one every time for the same person.
static func trust_ask(area_id: String, person: Dictionary) -> Dictionary:
	var job: Dictionary = person.get("talk", {}).get("job", {})
	if str(job.get("flag", "")) != "":
		return { "job": str(job["flag"]) + ":paid", "line": str(rules().get("job_trust", "")) }
	var asks: Array = rules().get("trust", [])
	if asks.is_empty():
		return {}
	return asks[absi(hash(key(area_id, person))) % asks.size()]


## Charisma ([D277]): how well somebody talks a stranger round. Grows with level and with what
## folk here have heard of the company; an outward temper starts ahead.
static func charisma(character: Character) -> int:
	var r := rules()
	var value := character.level * int(r.get("per_level", 2))
	if GameState.world != null:
		value += Renown.notoriety(GameState.world, GameState.world.player_cell)
	if character.temper.begins_with("E"):
		value += int(r.get("outward", 4))
	return value


## Where the company stands with them: "ask" (never asked, or asked and turned down in a
## conversation not yet over), "waiting" (said no, the ask not yet done), "trusted" (said no,
## and the ask is done), or "full" (no room for anyone else).
static func state(area_id: String, person: Dictionary, ledger: Dictionary, room: bool) -> String:
	if not room:
		return "full"
	var held: Variant = GameState.flags.get(TRUST + key(area_id, person))
	if not held is Dictionary:
		return "ask"
	return "trusted" if _earned(held as Dictionary, ledger) else "waiting"


static func _earned(held: Dictionary, ledger: Dictionary) -> bool:
	if held.has("job"):
		return GameState.has_flag(str(held["job"]))
	var at := int(held.get("at", 0))
	return int(ledger.get(str(held.get("ledger", "")), 0)) - at >= int(held.get("need", 1))


## The conversation's part in it, for [Talk.build]: which state, the check, and every line said,
## picked once per person so the same person always says the same thing.
static func offer(area_id: String, person: Dictionary) -> Dictionary:
	if not askable(area_id, person):
		return {}
	var k := key(area_id, person)
	_spoken[k] = { "unit": str(person.get("unit", "")), "name": str(person.get("name", "")), "area": area_id }
	var roster := GameState.roster
	var room := roster != null and roster.has_room()
	var r := rules()
	var own: Dictionary = person.get("talk", {}).get("recruit", {})
	var ask := trust_ask(area_id, person)
	_spoken[k]["ask"] = ask
	var pick := absi(hash(k))
	return {
		"state": state(area_id, person, GameState.ledger, room),
		"dc": dc(person),
		"yes_flag": YES + k,
		"no_flag": NO + k,
		"ask_q": str(own.get("q", r.get("ask_q", "Walk with us."))),
		"again_q": str(own.get("again_q", r.get("again_q", "About walking with us..."))),
		"yes": str(own.get("yes", _one(r.get("yes", []), pick))),
		"no": "%s %s" % [str(own.get("no", _one(r.get("no", []), pick))), str(ask.get("line", ""))],
		"waiting": "%s %s" % [str(own.get("waiting", r.get("waiting", ""))), str(ask.get("line", ""))],
		"trusted": str(own.get("trusted", _one(r.get("trusted", []), pick))),
		"full": str(own.get("full", r.get("full", ""))),
	}


static func _one(lines: Variant, pick: int) -> String:
	if lines is Array and not (lines as Array).is_empty():
		return str((lines as Array)[pick % (lines as Array).size()])
	return str(lines)


## A conversation is over: whoever said yes joins, and whoever said no remembers what they asked.
## Safe to call more than once. Returns everybody who joined.
static func settle(world: World, roster: Roster, flags: Dictionary, ledger: Dictionary) -> Array:
	var joined: Array = []
	for flag: String in flags.keys():
		if flag.begins_with(NO):
			var k := flag.substr(NO.length())
			flags.erase(flag)
			var ask: Dictionary = (_spoken.get(k, {}) as Dictionary).get("ask", {})
			if ask.has("job"):
				flags[TRUST + k] = { "job": ask["job"] }
			elif ask.has("ledger"):
				flags[TRUST + k] = {
					"ledger": str(ask["ledger"]), "need": int(ask.get("need", 1)),
					"at": int(ledger.get(str(ask["ledger"]), 0)),
				}
		elif flag.begins_with(YES):
			var k := flag.substr(YES.length())
			flags.erase(flag)
			var recruit := join(world, roster, flags, k)
			if recruit != null:
				joined.append(recruit)
	return joined


## Take the person known by [param k] onto the roster and into the marching order, at the lead's
## level. Null when there is no room or nobody by that key was spoken to.
static func join(world: World, roster: Roster, flags: Dictionary, k: String) -> Character:
	var seen: Dictionary = _spoken.get(k, {})
	if seen.is_empty() or flags.get(JOINED + k, false) == true or not roster.has_room():
		return null
	var name_ := str(seen.get("name", ""))
	if name_ == "" or name_.begins_with("a ") or name_.begins_with("an "):
		# Folk with no name of their own give one when they join ([D277]).
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([k, "recruit"])
		name_ = Names.person(world, world.player_cell, rng) if world != null else ""
	var recruit := Character.create(str(seen["unit"]), name_)
	var lead := roster.player()
	Progression.raise_quietly(recruit, lead.level if lead != null else 1, world)
	for member: Character in roster.party_members():
		var initial := Banter.initial_bond(member, recruit)
		member.bonds[recruit.id] = initial
		recruit.bonds[member.id] = initial
	roster.add(recruit)
	roster.enlist(recruit.id)
	flags[JOINED + k] = true
	flags.erase(TRUST + k)
	Ledger.add(GameState.ledger, "recruited")
	if world != null:
		Annals.record(world, "%s was asked to walk with the company, and came." % recruit.display_name)
	return recruit


static func joined_line(recruit_name: String) -> String:
	return str(rules().get("joined_note", "{name} falls in with you.")).replace("{name}", recruit_name)

