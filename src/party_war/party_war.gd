extends Node
## Party clashes and guild wars: two parties of random size, drawn from the seed, fight it
## out with nobody's hand on either side ([D257], `docs/18-combat-direction.md#party-clashes`).
##
## The fight is the real one: the skirmish in `bout` mode, a sandbox. Each side is one to four
## of the sixteen or the units of `data/party_war.json`, at random levels, each carrying a piece
## of real gear that suits them and fighting in a stance, and each side shares a pouch of
## draughts its hurt reach for. A guild war is the same with two bands: the Adventurers Guild's
## leads and soldiers against a faction's ranks and its champion. Only the dressing is the
## show's ([PartyWarShow]): the two rosters, what is said over a fighter's head, the K.O. and
## the winner's banner. Every number and line is in `data/party_war.json`.
##
##   # watch three clashes in a row (a window; Esc skips a fight)
##   godot --path . res://src/party_war/party_war.tscn -- --fights=3 --seed=7
##
##   # a guild war
##   godot --path . res://src/party_war/party_war.tscn -- --war=guild_vs_empire --seed=7
##
##   # a batch, headless, one `clash:` line per fight (tools/party_war.py writes the table)
##   godot --headless --path . res://src/party_war/party_war.tscn -- --table=200 --seed=1
##
##   (or `python3 tools/party_war.py`, which runs the batch and records the videos)

const Skirmish := preload("res://src/skirmish/skirmish.tscn")
const PartyWarShow := preload("res://src/party_war/party_war_show.gd")
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishScript := preload("res://src/skirmish/skirmish.gd")

## Set by [Game] before the scene enters the tree; unused out of the command line.
var boot_payload: Dictionary = {}

var _args: Dictionary = {}
var _queue: Array = []
var _index: int = 0
var _fight: Node2D
var _show: PartyWarShow
var _kept_pause: int = 0


func _ready() -> void:
	_args = _parse(OS.get_cmdline_user_args())
	var seed_ := int(_args.get("seed", 0))
	if seed_ == 0:
		seed_ = randi() % 100000 + 1
	# Stances only count for a party played by hand, and nobody's hand is on this one.
	Pace.auto = false
	_kept_pause = SkirmishScript.auto_pause
	SkirmishScript.auto_pause = SkirmishScript.AutoPause.OFF
	if _args.has("table"):
		# Each draw is fought twice, the second time with the sides swapped, so what the
		# company's side is worth shows apart from what the parties are.
		for i in int(_args["table"]):
			var setup := draw(seed_ + i)
			print(row(run_quietly(self, setup)))
			print(row(run_quietly(self, swapped(setup))))
		_finish()
		return
	if _args.has("war"):
		_queue.append(draw_war(str(_args["war"]), seed_))
	elif _args.has("seeds"):
		for each in str(_args["seeds"]).split(",", false):
			_queue.append(draw(int(each)))
	else:
		for i in maxi(1, int(_args.get("fights", 1))):
			_queue.append(draw(seed_ + i))
	if _args.has("verdict"):
		for setup: Dictionary in _queue:
			print(row(run_quietly(self, setup)))
		_finish()
		return
	_next_fight()


func _process(_delta: float) -> void:
	if _show != null and _fight != null and _show.fighting() and not _fight.paused:
		for f: Fighter in drink(_fight, _queue[_index - 1]):
			_show.talk(f, "drink")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_show_over()


func _next_fight() -> void:
	if _index >= _queue.size():
		_finish()
		return
	var setup: Dictionary = _queue[_index]
	_index += 1
	Engine.time_scale = 1.0
	_fight = Skirmish.instantiate()
	_fight.boot_payload = stage(setup)
	_fight.boot_payload["paused"] = true
	add_child(_fight)
	ready_the_field(_fight, setup)
	_show = PartyWarShow.new()
	add_child(_show)
	_show.over.connect(_on_show_over)
	_show.begin(_fight, setup, _index, _queue.size())
	print("party war: %s, seed %d" % [setup["title"], setup["seed"]])


func _on_show_over() -> void:
	Engine.time_scale = 1.0
	if _fight != null:
		if _fight.over or _fight.sim_time > 0.0:
			print(row(result_of(_fight, _queue[_index - 1])))
		_fight.queue_free()
		_fight = null
	if _show != null:
		_show.queue_free()
		_show = null
	if _index < _queue.size():
		# A frame between fights, so the last one is gone before the next one lays its ground.
		await get_tree().process_frame
		_next_fight()
	else:
		_finish()


func _finish() -> void:
	SkirmishScript.auto_pause = _kept_pause as SkirmishScript.AutoPause
	get_tree().quit(0)


# --- drawing the parties ------------------------------------------------------


## A number or list from `data/party_war.json`.
static func rule(key: String, fallback: Variant) -> Variant:
	return Database.party_war.get(key, fallback)


## Two parties drawn from [param seed_]: each one to four, each fighter a lead (none on both
## sides) or a unit, at a random level, with gear, a stance, and a pouch for the side.
static func draw(seed_: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var sizes: Array = rule("party_size", [1, 4])
	var levels: Array = rule("levels", [1, 10])
	var leads: Array = Database.heroes.keys()
	var units: Array = rule("units", ["brigand"])
	var sides := {}
	for side: String in ["left", "right"]:
		var members: Array = []
		for i in rng.randi_range(int(sizes[0]), int(sizes[1])):
			var template := ""
			if rng.randf() < float(rule("lead_share", 0.6)) and not leads.is_empty():
				template = leads.pop_at(rng.randi() % leads.size())
			else:
				template = units[rng.randi() % units.size()]
			members.append(_member(template, rng.randi_range(int(levels[0]), int(levels[1])), rng))
		var first: Dictionary = members[0]
		sides[side] = {
			"name": str(rule("words", {}).get("party_of", "Band of {name}")).format(
					{"name": Database.unit_template(first["unit"]).get("display_name", first["unit"])}),
			"members": members,
			"pouch": _pouch(rule("pouch", [1, 3]), rng),
		}
	var field: Array = rule("field", [18, 14])
	return {
		"kind": "clash", "seed": seed_, "title": "%s vs %s" % [sides["left"]["name"], sides["right"]["name"]],
		"left": sides["left"], "right": sides["right"], "field": field,
		"health_scale": float(rule("health_scale", 1.5)), "time_limit": float(rule("time_limit", 120.0)),
	}


## [param setup] with its two sides changed round: the left fights as the other side.
static func swapped(setup: Dictionary) -> Dictionary:
	var out := setup.duplicate(true)
	out["left"] = setup["right"].duplicate(true)
	out["right"] = setup["left"].duplicate(true)
	out["swapped"] = true
	return out


## The war [param id] in `wars`: its two bands, drawn from [param seed_].
static func draw_war(id: String, seed_: int) -> Dictionary:
	var war: Dictionary = rule("wars", {}).get(id, {})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var leads: Array = Database.heroes.keys()
	var sides := {}
	for side: String in ["left", "right"]:
		var band: Dictionary = war.get(side, {})
		var members: Array = []
		var lead_levels: Array = band.get("lead_levels", [5, 5])
		for i in int(band.get("leads", 0)):
			members.append(_member(leads.pop_at(rng.randi() % leads.size()),
					rng.randi_range(int(lead_levels[0]), int(lead_levels[1])), rng))
		if band.has("champion"):
			var champion := _member(str(band["champion"]), int(band.get("champion_level", 10)), rng)
			champion["boss"] = true
			members.append(champion)
		var levels: Array = band.get("levels", [3, 6])
		var units: Array = band.get("units", ["brigand"])
		for i in int(band.get("count", 0)):
			members.append(_member(units[i % units.size()], rng.randi_range(int(levels[0]), int(levels[1])), rng))
		sides[side] = {"name": str(band.get("name", side)), "members": members,
				"pouch": _pouch(war.get("pouch", rule("pouch", [1, 3])), rng)}
	return {
		"kind": "war", "seed": seed_, "title": str(war.get("title", id)),
		"left": sides["left"], "right": sides["right"], "field": war.get("field", [30, 20]),
		"health_scale": float(war.get("health_scale", rule("health_scale", 1.5))),
		"time_limit": float(war.get("time_limit", rule("time_limit", 120.0))),
	}


## One fighter: [param template] at [param level] in a calling drawn now (so the gear can
## suit it), a piece that suits them and a stance.
static func _member(template: String, level: int, rng: RandomNumberGenerator) -> Dictionary:
	var stances: Array = rule("stances", ["own"])
	var probe := Character.create(template)
	var world_rng := RandomNumberGenerator.new()
	world_rng.seed = rng.randi()
	probe.level = level
	if level >= Progression.CLASS_LEVEL:
		probe.class_id = Progression.choose_class(probe, world_rng)
	return {"unit": template, "level": level, "class": probe.class_id, "gear": _gear(probe, level, rng),
			"stance": stances[rng.randi() % stances.size()]}


## A piece of gear from `data/equipment.json` that suits [param probe]'s calling, costs no
## more than its level says, and beats what they were issued; empty when nothing does (they
## fight with what they carry).
static func _gear(probe: Character, level: int, rng: RandomNumberGenerator) -> String:
	var kinds: Array = rule("gear_kinds", ["blade", "bow", "staff", "armour"])
	var ceiling := float(rule("gear_price_base", 2500)) + float(rule("gear_price_per_level", 2500)) * level
	var fits: Array = []
	for id: String in Database.equipment:
		var piece := Gear.piece(id)
		if not kinds.has(str(piece.get("kind", ""))) or piece.has("signature"):
			continue
		if float(piece.get("price", 0)) > ceiling or not Gear.suits(id, probe):
			continue
		if Gear.worth(id, probe) <= Gear.carried_worth(probe):
			continue
		fits.append(id)
	fits.sort()
	return fits[rng.randi() % fits.size()] if not fits.is_empty() else ""


static func _pouch(span: Array, rng: RandomNumberGenerator) -> Dictionary:
	var draughts: Array = rule("draughts", ["bread"])
	var out := {}
	for i in rng.randi_range(int(span[0]), int(span[1])):
		var id: String = draughts[rng.randi() % draughts.size()]
		out[id] = int(out.get(id, 0)) + 1
	return out


# --- the fight ----------------------------------------------------------------


## The skirmish payload for [param setup]: both sides on a field of the setup's size, the
## left fighting as the company (the party's side) and the right as the other.
static func stage(setup: Dictionary) -> Dictionary:
	seed(int(setup["seed"]))
	GameState.roster = Roster.new()
	if GameState.world != null:
		GameState.world.rng.seed = int(setup["seed"])
	var rng := RandomNumberGenerator.new()
	rng.seed = int(setup["seed"])
	var size: Array = setup["field"]
	var width := int(size[0])
	var height := int(size[1])
	var terrain := str(rule("terrain", "grass"))
	var palette: Array = BattleMapGen.PALETTES.get(terrain, BattleMapGen.PALETTES["grass"])
	var rows: Array = []
	for y in height:
		var line := ""
		for x in width:
			line += palette[rng.randi() % palette.size()]
		rows.append(line)
	var entries: Array = []
	var left: Array = setup["left"]["members"]
	var right: Array = setup["right"]["members"]
	var left_cells := _muster(rows, height - 2, -1, left.size())
	var right_cells := _muster(rows, 1, 1, right.size())
	for i in left.size():
		var entry: Dictionary = left[i].duplicate()
		entry["cell"] = left_cells[i]
		entry["team"] = Unit.Team.PLAYER
		entries.append(entry)
	for i in right.size():
		var entry: Dictionary = right[i].duplicate()
		entry["cell"] = right_cells[i]
		entries.append(entry)
	var map := {
		"id": "party_war", "name": str(setup["title"]), "legend": BattleMapGen.LEGEND, "tiles": rows,
		"player_spawns": left_cells, "enemies": entries,
	}
	return {"encounter": {"map": map, "title": str(setup["title"])}, "sandbox": true, "bout": true,
			"paused": false, "seed": int(setup["seed"]), "heal": true}


## [param count] cells two apart along [param row], then the next row along [param step],
## each cleared with the tile in front of it, so nobody starts boxed in.
static func _muster(rows: Array, row: int, step: int, count: int) -> Array:
	var width := str(rows[0]).length()
	var per_row := maxi(1, (width - 2) / 2)
	var cells: Array = []
	var at := row
	var left := count
	while left > 0 and at >= 0 and at < rows.size():
		var here := mini(left, per_row)
		var start := maxi(1, (width - here * 2) / 2)
		for i in here:
			var x := start + i * 2 + (1 if (at - row) % 2 != 0 else 0)
			x = mini(x, width - 2)
			rows[at] = _put(rows[at], x, ".")
			var ahead := at - step
			if ahead >= 0 and ahead < rows.size():
				rows[ahead] = _put(rows[ahead], x, ".")
			cells.append([x, at])
		left -= here
		at += step * 2
	return cells


static func _put(line: String, x: int, symbol: String) -> String:
	return line.substr(0, x) + symbol + line.substr(x + 1)


## After the fight is in the tree: everyone's health raised by the setup's scale, and the
## pouch both sides draw on (each side's own count is kept by [method drink]).
static func ready_the_field(fight: Node, setup: Dictionary) -> void:
	var scale := float(setup.get("health_scale", 1.0))
	for f: Fighter in fight.fighters:
		f.unit.max_hp = roundi(f.unit.max_hp * scale)
		f.unit.hp = roundi(f.unit.hp * scale)
	var all := {}
	for id: String in rule("draughts", []):
		all[id] = 999
	fight.pouch = all
	setup["pouches"] = {"left": setup["left"]["pouch"].duplicate(), "right": setup["right"]["pouch"].duplicate()}
	setup["drunk"] = {"left": 0, "right": 0}


## Anyone hurt below `drink_below` who is free reaches for their side's best draught. Returns
## the fighters who did, so the show can have them say so.
static func drink(fight: Node, setup: Dictionary) -> Array:
	var started: Array = []
	var below := float(rule("drink_below", 0.35))
	for f: Fighter in fight.fighters:
		if f.bound_to != null or not f.is_standing() or f.is_using() or f.is_casting():
			continue
		if float(f.unit.hp) / maxf(1.0, f.unit.max_hp) > below:
			continue
		var side := "left" if f.is_party() else "right"
		var pouch: Dictionary = setup["pouches"][side]
		if pouch.is_empty():
			continue
		var best := ""
		for id: String in pouch:
			if best == "" or Gear.mends(id) > Gear.mends(best):
				best = id
		if fight.item_refusal(f, best) != "" or not fight.use_item(f, best):
			continue
		pouch[best] = int(pouch[best]) - 1
		if int(pouch[best]) <= 0:
			pouch.erase(best)
		setup["drunk"][side] = int(setup["drunk"][side]) + 1
		started.append(f)
	return started


## Fights [param setup] to its end on fixed ticks, with nothing drawn.
static func run_quietly(host: Node, setup: Dictionary) -> Dictionary:
	var fight: Node2D = Skirmish.instantiate()
	fight.boot_payload = stage(setup)
	fight.manual = true
	host.add_child(fight)
	ready_the_field(fight, setup)
	var limit := float(setup["time_limit"])
	var ticks := 0
	while not fight.over and fight.sim_time < limit:
		fight.tick()
		ticks += 1
		if ticks % 5 == 0:
			drink(fight, setup)
	var result := result_of(fight, setup)
	host.remove_child(fight)
	fight.free()
	return result


## Who stood at the end of [param fight], and what each side brought.
static func result_of(fight: Node, setup: Dictionary) -> Dictionary:
	var out := {"seed": setup["seed"], "kind": setup["kind"], "swapped": bool(setup.get("swapped", false)), "seconds": fight.sim_time,
			"winner": ("left" if fight.victory else "right") if fight.over else "none"}
	for side: String in ["left", "right"]:
		var mine: Array = fight.fighters.filter(func(f: Fighter) -> bool:
			return f.bound_to == null and (f.is_party() == (side == "left")))
		var levels: Array = []
		var who: Array = []
		var hp := 0
		var most := 0
		var standing := 0
		var casts := 0
		for f: Fighter in mine:
			levels.append(f.unit.character.level if f.unit.character != null else 0)
			who.append("%s:%d:%s:%s" % [f.unit.template_id, levels[-1],
					f.unit.character.equipment if f.unit.character != null and f.unit.character.equipment != "" else "-", f.stance])
			hp += maxi(0, f.unit.hp) if f.is_standing() else 0
			most += f.unit.max_hp
			standing += 1 if f.is_standing() else 0
			casts += f.casts
		var level_sum := 0
		for l: int in levels:
			level_sum += l
		out[side] = {"size": mine.size(), "levels": level_sum, "standing": standing,
				"health": float(hp) / maxf(1.0, most), "casts": casts,
				"drunk": int(setup.get("drunk", {}).get(side, 0)), "who": " ".join(who)}
	return out


## One line a script can read: `clash: key=value | ...`.
static func row(result: Dictionary) -> String:
	var parts: Array[String] = ["seed=%d" % result["seed"], "kind=%s" % result["kind"],
			"swapped=%d" % (1 if result.get("swapped", false) else 0),
			"winner=%s" % result["winner"], "seconds=%.1f" % result["seconds"]]
	for side: String in ["left", "right"]:
		var s: Dictionary = result[side]
		parts.append("%s_size=%d" % [side, s["size"]])
		parts.append("%s_levels=%d" % [side, s["levels"]])
		parts.append("%s_standing=%d" % [side, s["standing"]])
		parts.append("%s_health=%.2f" % [side, s["health"]])
		parts.append("%s_casts=%d" % [side, s["casts"]])
		parts.append("%s_drunk=%d" % [side, s["drunk"]])
		parts.append("%s_who=%s" % [side, s["who"]])
	return "clash: " + " | ".join(parts)


func _parse(args: PackedStringArray) -> Dictionary:
	var out := {}
	for arg in args:
		if not arg.begins_with("--"):
			continue
		var pair := arg.trim_prefix("--").split("=", true, 1)
		out[pair[0]] = pair[1] if pair.size() > 1 else ""
	return out
