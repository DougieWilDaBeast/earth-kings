extends RefCounted
## Sellswords for hire in Stormreach's Gilded Flagon ([D295]: "mercenaries hired for gold who stay
## until the job is done", cover for climbing with new people). Whoever keeps the Flagon's book
## (a person whose `talk` has `hires`) offers a short board of them: each named, at about the lead's
## level, for one job, paid up front. A sellsword marches like anyone, but bonds with nobody, is
## not one of the 32 ([D303]) and goes when the job is done: the next gate shut ("gate") or the
## next chapter of the Tower closed ("chapter").
##
## The board is dealt from the world's seed and how long the world has run, so it holds still
## between visits and changes every `refresh_steps`; who has been taken off it is a flag. The rules
## and every line are `world_rules.sellswords`. Loaded by path ([D41]).

const Names := preload("res://src/chronicle/names.gd")
const Coins := preload("res://src/chronicle/coins.gd")

const HIRED_FLAG := "sellsword:hired:"


static func rules() -> Dictionary:
	return Database.world_rules.get("sellswords", {})


static func lines() -> Dictionary:
	return rules().get("lines", {})


## Which board the world is on now: it changes every `refresh_steps` steps.
static func window(world: World) -> int:
	return world.steps / maxi(1, int(rules().get("refresh_steps", 400)))


## Who is on the board now, still to be had: `{ index, template, name, level, job, price }`.
static func board(world: World) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if world == null or GameState.roster == null or GameState.roster.player() == null:
		return out
	var r := rules()
	var templates: Array = r.get("templates", [])
	var jobs: Array = (r.get("jobs", {}) as Dictionary).keys()
	if templates.is_empty() or jobs.is_empty():
		return out
	var at := window(world)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.world_seed, at, "sellswords"])
	var lead_level := GameState.roster.player().level
	for index in int(r.get("board_size", 3)):
		var template := str(templates[rng.randi() % templates.size()])
		var job := str(jobs[rng.randi() % jobs.size()])
		var level := maxi(1, lead_level + rng.randi_range(-1, 1))
		var name_ := Names.person(world, world.player_cell, rng)
		if GameState.has_flag(_hired_flag(at, index)):
			continue
		out.append({
			"index": index, "template": template, "name": name_, "level": level, "job": job,
			"price": price(level, job),
		})
	return out


## What one asks, before the lead's own haggling: a base and a share a level, times the job's own
## weight and the difficulty's prices.
static func price(level: int, job: String) -> int:
	var r := rules()
	var weight := float((r.get("jobs", {}) as Dictionary).get(job, {}).get("price", 1.0))
	var lead := GameState.roster.player() if GameState.roster != null else null
	var haggle := lead.lean("hire_price", 1.0) if lead != null else 1.0
	return maxi(1, roundi((int(r.get("cost_base", 1500)) + int(r.get("cost_per_level", 800)) * level)
		* weight * Difficulty.dial("price") * haggle))


## The board's line for one of them, as the book-keeper reads it out.
static func offer_text(offer: Dictionary) -> String:
	var job: Dictionary = (rules().get("jobs", {}) as Dictionary).get(str(offer.get("job", "")), {})
	var unit := Database.unit_template(str(offer.get("template", "")))
	return str(lines().get("offer", "{name}, {job_name}, level {level}, {for} — {price}")).format({
		"name": str(offer.get("name", "")), "job_name": str(unit.get("job", unit.get("display_name", ""))),
		"level": int(offer.get("level", 1)), "for": str(job.get("for", "")),
		"price": Coins.text(int(offer.get("price", 0))),
	})


## Take [param index] off the board: paid for and marching. Returns what is said, "" when it could
## not be done (gone, no room, not enough coin).
static func hire(world: World, roster: Roster, index: int) -> String:
	if world == null or roster == null:
		return ""
	var offer: Dictionary = {}
	for each: Dictionary in board(world):
		if int(each["index"]) == index:
			offer = each
	if offer.is_empty() or not roster.has_room() or GameState.gold < int(offer["price"]):
		return ""
	GameState.gold -= int(offer["price"])
	var sellsword := Character.create(str(offer["template"]), str(offer["name"]))
	Progression.raise_quietly(sellsword, int(offer["level"]), world)
	sellsword.contract = { "job": str(offer["job"]), "paid": int(offer["price"]) }
	roster.add(sellsword)
	roster.enlist(sellsword.id)
	GameState.set_flag(_hired_flag(window(world), index))
	Ledger.add(GameState.ledger, "recruited")
	return str(lines().get("hired", "{name} takes the coin and falls in.")).format({ "name": sellsword.display_name })


## A job of [param kind] is done ("gate" or "chapter"): every sellsword hired for it takes their
## leave, and what is said as they go.
static func on_job(roster: Roster, kind: String) -> Array[String]:
	var said: Array[String] = []
	if roster == null:
		return said
	for character: Character in roster.characters.duplicate():
		if str(character.contract.get("job", "")) != kind or not character.is_alive():
			continue
		roster.let_go(character.id)
		said.append(str(lines().get("done", "{name}'s job is done. They take their leave.")).format({
			"name": character.display_name,
		}))
	return said


static func is_sellsword(character: Character) -> bool:
	return character != null and not character.contract.is_empty()


static func _hired_flag(at: int, index: int) -> String:
	return "%s%d:%d" % [HIRED_FLAG, at, index]
