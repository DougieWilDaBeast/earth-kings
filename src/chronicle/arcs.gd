extends RefCounted
## Companions whose arcs react ([D250], from Baldur's Gate 3; Ewan's "what other games do well",
## #270 keep 1): each of the sixteen can have a short quest of their own, opened after their
## chapter one and told at the fire.
##
## An arc belongs to one of the sixteen in the company: the lead, once they have found their
## chapter one, or one walking with them, once the company has stood on the Tower's floor
## `opens_floor`. Everything about it is said at the fire: sit with them (or, for the lead's own,
## have the lead sit with anyone) and they open it, say when a stage of it is done, and finish it.
## What the company did shapes it: a stage the company had already done before the arc opened is
## done at once, and every line has variants chosen by the deeds of this world ([Renown]), who of
## the sixteen has been met or walks along, and who has fallen ([D223]: a bond from before the
## descent is learned as the game goes on, and grieved when the other half is gone).
##
## A stage asks for deeds ([Renown]), and may ask as well ([D256]) for the company's tallies to grow
## (`ledger`: fights won, foes felled, places walked, one kind put down...), a Tower floor stood on,
## a flag set (a room taken, a building built) or some of the sixteen met.
##
## Kept on the world as `arcs`: hero id -> `{ stage, since, at, done }`; `since` is the step the
## stage opened, so only deeds after it count, and `at` the tallies then, so only what grew counts. The words and the reward are `data/arcs.json`. Loaded by
## path ([D41]).

const Memories := preload("res://src/chronicle/memories.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")


static func rules() -> Dictionary:
	return Database.arcs


static func arc(hero_id: String) -> Dictionary:
	return rules().get("arcs", {}).get(hero_id, {})


## Whether [param character] has an arc, and it can be opened now: the lead once their chapter one
## is found, anyone else of the sixteen once the company has stood on the floor it opens at.
static func can_open(world: World, character: Character, is_lead: bool) -> bool:
	if character == null or arc(character.template_id).is_empty() or world.arcs.has(character.template_id):
		return false
	if is_lead:
		return not Memories.found(character.template_id).is_empty()
	return world.tower_floor >= int(rules().get("opens_floor", 5))


# --- what counts --------------------------------------------------------------


## Whether [param deed] is one [param wanted] names: its `kind`, and the start of its `told`.
static func matches(deed: Dictionary, wanted: Dictionary) -> bool:
	if str(wanted.get("kind", "")) != "" and str(deed.get("kind", "")) != str(wanted["kind"]):
		return false
	var told := str(wanted.get("told", ""))
	return told == "" or str(deed.get("told", "")).begins_with(told)


## How many deeds of this world [param need]'s `deeds` match, between steps [param from] and
## [param to] (to -1: up to now).
static func counted(world: World, need: Dictionary, from: int, to: int = -1) -> int:
	var count := 0
	for deed: Dictionary in world.deeds:
		var step := int(deed.get("step", 0))
		if step < from or (to >= 0 and step >= to):
			continue
		for wanted: Dictionary in need.get("deeds", []):
			if matches(deed, wanted):
				count += 1
				break
	return count


## Whether [param need] is met: its `deeds` counted since step [param from] (and before [param to]),
## and whatever else it asks. `ledger` tallies are counted from [param at] (the tallies when the
## stage opened; empty counts from nothing, as `skip_if` does).
static func reached(world: World, need: Dictionary, from: int, at: Dictionary, to: int = -1) -> bool:
	if need.is_empty():
		return false
	if not (need.get("deeds", []) as Array).is_empty() and counted(world, need, from, to) < int(need.get("count", 1)):
		return false
	var ledger: Dictionary = need.get("ledger", {})
	if not ledger.is_empty():
		var now := tally()
		for key: String in ledger:
			if grown(now, at, key) < int(ledger[key]):
				return false
	if need.has("floor") and world.tower_floor < int(need["floor"]):
		return false
	if need.has("flag"):
		var flags: Array = need["flag"] if need["flag"] is Array else [need["flag"]]
		if not flags.any(func(key: Variant) -> bool: return GameState.has_flag(str(key))):
			return false
	if need.has("met_count") and met_count(world) < int(need["met_count"]):
		return false
	return true


## The company's tallies as an arc counts them: every [Ledger] counter, `places` (how many walked)
## and `kinds` (foes put down, by kind).
static func tally() -> Dictionary:
	var ledger: Dictionary = GameState.ledger
	var out := {}
	for key: String in Ledger.KEYS:
		out[key] = Ledger.count(ledger, key)
	out["places"] = (ledger.get("places", []) as Array).size()
	out["kinds"] = (ledger.get("kills_by", {}) as Dictionary).duplicate()
	return out


## How much tally [param key] grew from [param at] to [param now]; `one_kind` is the most of any
## one kind of foe put down.
static func grown(now: Dictionary, at: Dictionary, key: String) -> int:
	if key == "one_kind":
		var most := 0
		var before: Dictionary = at.get("kinds", {})
		var kinds: Dictionary = now.get("kinds", {})
		for kind: String in kinds:
			most = maxi(most, int(kinds[kind]) - int(before.get(kind, 0)))
		return most
	return int(now.get(key, 0)) - int(at.get(key, 0))


## How many of the sixteen the company has met this world.
static func met_count(world: World) -> int:
	var count := 0
	for each: Dictionary in world.wanderers:
		if int(each.get("met", 0)) > 0 or bool(each.get("joined", false)):
			count += 1
	return count


static func _met(world: World, hero_id: String) -> bool:
	for each: Dictionary in world.wanderers:
		if str(each.get("id", "")) == hero_id:
			return int(each.get("met", 0)) > 0 or bool(each.get("joined", false))
	return false


static func _with(roster: Roster, hero_id: String) -> bool:
	if roster == null:
		return false
	for character: Character in roster.characters:
		if character.template_id == hero_id and character.status == Fate.ALIVE:
			return true
	return false


## Whether [param hero_id] has fallen: in this world, or as the lead of one that ended.
static func fallen(roster: Roster, hero_id: String) -> bool:
	if hero_id in Sixteen.fallen_heroes():
		return true
	if roster != null:
		for character: Character in roster.characters:
			if character.template_id == hero_id and character.status == Fate.DEAD:
				return true
	return false


## How many of the sixteen have fallen: in this world, or as the lead of one that ended.
static func fallen_count(roster: Roster) -> int:
	var count := 0
	for hero_id: String in Database.heroes:
		if not hero_id.begins_with("_") and fallen(roster, hero_id):
			count += 1
	return count


## Whether everything [param when] asks holds.
static func holds(world: World, roster: Roster, when: Dictionary) -> bool:
	if when.has("deed") and counted(world, { "deeds": [when["deed"]] }, 0) == 0:
		return false
	if when.has("met") and not _met(world, str(when["met"])):
		return false
	if when.has("with") and not _with(roster, str(when["with"])):
		return false
	if when.has("fallen") and not fallen(roster, str(when["fallen"])):
		return false
	if when.has("fallen_count") and fallen_count(roster) < int(when["fallen_count"]):
		return false
	if when.has("flag") and not GameState.has_flag(str(when["flag"])):
		return false
	if when.has("not"):
		var not_: Dictionary = when["not"]
		for key: String in not_:
			if holds(world, roster, { key: not_[key] }):
				return false
	return true


## The first variant of [param variants] whose `when` holds, as lines ready for the dialogue box.
static func said(world: World, roster: Roster, variants: Array, owner: Character, listener: Character) -> Array:
	for variant: Dictionary in variants:
		if not holds(world, roster, variant.get("when", {})):
			continue
		var out: Array = []
		for line: Dictionary in variant.get("lines", []):
			var who := str(line.get("speaker", "{owner}"))
			out.append({
				"speaker": listener.display_name if who == "{listener}" else owner.display_name,
				"text": str(line.get("text", "")),
			})
		return out
	return []


# --- at the fire --------------------------------------------------------------


## What is said at the fire between the [param leader] and [param them] about either one's arc,
## or nothing, and the arc moved on for it: opened, a stage done, or finished (and its reward
## given). Their own arc first, then the leader's.
static func at_the_fire(world: World, roster: Roster, leader: Character, them: Character) -> Array:
	if world == null or leader == null or them == null or leader == them:
		return []
	var lines := _tell(world, roster, them, leader, false)
	if lines.is_empty():
		lines = _tell(world, roster, leader, them, true)
	return lines


static func _tell(world: World, roster: Roster, owner: Character, listener: Character, is_lead: bool) -> Array:
	var id := owner.template_id
	var data := arc(id)
	if data.is_empty():
		return []
	var lines: Array = []
	if not world.arcs.has(id):
		if not can_open(world, owner, is_lead):
			return []
		world.arcs[id] = { "stage": 0, "since": world.steps, "at": tally(), "done": false }
		lines.append_array(said(world, roster, data.get("opened", []), owner, listener))
		var first: Dictionary = (data.get("stages", []) as Array)[0] if not (data.get("stages", []) as Array).is_empty() else {}
		var skip: Dictionary = first.get("skip_if", {})
		if not reached(world, skip, 0, {}, world.steps + 1):
			return lines
		lines.append_array(said(world, roster, first.get("skipped", []), owner, listener))
		return lines + _advance(world, roster, owner, listener)
	var state: Dictionary = world.arcs[id]
	if bool(state.get("done", false)):
		return []
	var stages: Array = data.get("stages", [])
	var stage: Dictionary = stages[int(state.get("stage", 0))]
	if not reached(world, stage.get("until", {}), int(state.get("since", 0)), state.get("at", {})):
		return []
	lines.append_array(said(world, roster, stage.get("done", []), owner, listener))
	return lines + _advance(world, roster, owner, listener)


## On to the next stage, or the end of the arc: its last lines, and the reward.
static func _advance(world: World, roster: Roster, owner: Character, listener: Character) -> Array:
	var id := owner.template_id
	var data := arc(id)
	var state: Dictionary = world.arcs[id]
	state["stage"] = int(state.get("stage", 0)) + 1
	state["since"] = world.steps
	state["at"] = tally()
	if int(state["stage"]) < (data.get("stages", []) as Array).size():
		return []
	state["done"] = true
	var lines := said(world, roster, data.get("finished", []), owner, listener)
	var reward: Dictionary = data.get("reward", {})
	var marks: Dictionary = reward.get("marks", {})
	for key: String in marks:
		owner.marks[key] = int(owner.marks.get(key, 0)) + int(marks[key])
	Banter.remember(owner, listener, int(reward.get("bond", 0)))
	if str(reward.get("annal", "")) != "":
		Annals.record(world, str(reward["annal"]))
	if str(reward.get("line", "")) != "":
		lines.append({ "speaker": "", "text": str(reward["line"]) })
	return lines


# --- the journal --------------------------------------------------------------


## Every arc opened this world, for the journal: `{ title, done, entries: [{ text, done }] }`.
static func pages(world: World) -> Array:
	var out: Array = []
	for id: String in world.arcs:
		var data := arc(id)
		if data.is_empty():
			continue
		var state: Dictionary = world.arcs[id]
		var at := int(state.get("stage", 0))
		var entries: Array = []
		var stages: Array = data.get("stages", [])
		for i in mini(at + 1, stages.size()):
			# Done but not yet talked over at the fire is ticked too, so the journal says where it stands.
			var ready := i == at and reached(world, stages[i].get("until", {}), int(state.get("since", 0)), state.get("at", {}))
			entries.append({ "text": str(stages[i].get("ask", "")), "done": i < at or ready })
		out.append({ "title": str(data.get("title", id)), "done": bool(state.get("done", false)), "entries": entries })
	return out
