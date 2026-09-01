class_name World
extends RefCounted
## The persistent world: its ground, its places, its clock, and the powers it
## has discovered so far.
##
## There are no eras. The world advances by *steps* — gates stir, doctrine
## fades, and monsters return as you walk, not on a turn of some larger wheel.

const SIZE := Vector2i(44, 44)

## Symbol -> terrain id from `data/terrain.json`.
const LEGEND := {
	".": "grass",
	",": "brush",
	"^": "hill",
	"A": "crag",
	"~": "water",
	"#": "wall",
	"=": "road",
}

## Steps between world upkeep passes (gates stirring, doctrine fading).
const UPKEEP_INTERVAL := 30

var world_seed: int = 0
var size: Vector2i = SIZE
## One string per row; each character is a [constant LEGEND] symbol.
var tiles: Array = []
var sites: Array[Site] = []
## Bands out in the country, each watching the ground around it (see [Prowler]).
var prowlers: Array[Prowler] = []
var steps: int = 0
var player_cell: Vector2i = Vector2i.ZERO
## Highest Tower floor anyone has come back down from.
var tower_floor: int = 0
## Set once the top has been reached. What waits there is not decided yet.
var tower_topped: bool = false
## Generated skill trees, id -> tree dict (see [AbilityGrammar]).
var trees: Dictionary = {}
## Themes the world has catalogued, for the Codex readout.
var codex: Dictionary = {}
## Small useless spells this world has written down (see [Trivia]).
var trivia: Array = []
## Everything you have done that anyone would repeat, and where (see [Renown]).
var deeds: Array = []
## Live story threads, id -> { stage, entered_at, memory, tags, done } (see [Skein]).
var threads: Dictionary = {}
## What you have worked out about what you fight (see [Journal]).
var journal: Dictionary = {}

var rng := RandomNumberGenerator.new()


# --- ground -------------------------------------------------------------------


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < size.x and cell.y < size.y


func symbol_at(cell: Vector2i) -> String:
	if not in_bounds(cell):
		return "#"
	return tiles[cell.y][cell.x]


func terrain_id_at(cell: Vector2i) -> String:
	return LEGEND.get(symbol_at(cell), "grass")


func terrain_at(cell: Vector2i) -> Dictionary:
	return Database.terrain_type(terrain_id_at(cell))


func is_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell) and terrain_at(cell).get("walkable", true)


# --- places -------------------------------------------------------------------


func site_at(cell: Vector2i) -> Site:
	for site in sites:
		if site.cell == cell:
			return site
	return null


func sites_of_kind(kind: String) -> Array[Site]:
	return sites.filter(func(s: Site) -> bool: return s.kind == kind)


## The band with eyes on [param cell], if any. Walking onto a tile one of these
## is watching is the only way a fight starts in the open.
func prowler_watching(cell: Vector2i) -> Prowler:
	for band in prowlers:
		if band.sees(self, cell):
			return band
	return null


func tower() -> Site:
	var towers := sites_of_kind(Site.TOWER)
	return towers[0] if not towers.is_empty() else null


## The one place that is yours. Every world has exactly one.
func home() -> Site:
	var homes := sites_of_kind(Site.HOME)
	return homes[0] if not homes.is_empty() else null


func tower_floors() -> int:
	return int(Database.world_rules.get("tower", {}).get("floors", 10))


func tower_is_topped() -> bool:
	return tower_floor >= tower_floors()


## Distance to the nearest open gate — what makes the wild dangerous.
func distance_to_open_gate(cell: Vector2i) -> int:
	var best := 9999
	for site in sites_of_kind(Site.GATE):
		if site.open:
			best = mini(best, Pathfinder.distance(cell, site.cell))
	return best


## Distance to the nearest hearth — what makes it safe again.
func distance_to_haven(cell: Vector2i) -> int:
	var best := 9999
	for site in sites:
		if site.kind == Site.VILLAGE or site.kind == Site.KEEP or site.kind == Site.HUT \
				or site.kind == Site.HOME:
			best = mini(best, Pathfinder.distance(cell, site.cell))
	return best


## A gate that has broken is pouring rather than spilling, and the land around
## it is far worse for it.
func broken_gates() -> Array[Site]:
	return sites_of_kind(Site.GATE).filter(func(s: Site) -> bool: return s.broken)


## Shut a gate for good. Cleared gates never swing open again.
func close_gate(site: Site) -> void:
	site.open = false
	site.broken = false
	site.cleared = true


func open_gate(site: Site) -> void:
	if site.cleared:
		return
	site.open = true
	site.opened_at = steps


# --- powers -------------------------------------------------------------------


func register_tree(tree_data: Dictionary) -> void:
	trees[tree_data["id"]] = tree_data
	for ability_id: String in tree_data.get("definitions", {}):
		Database.register_ability(ability_id, tree_data["definitions"][ability_id])
	var theme: String = tree_data.get("theme", "")
	codex[theme] = int(codex.get(theme, 0)) + 1


func tree(tree_id: String) -> Dictionary:
	return trees.get(tree_id, {})


## Share of the ability grammar the world has catalogued, 0.0–1.0.
##
## Trivial spells count towards this. Understanding the grammar is not the same
## as owning powerful things, and a world that has bothered to write down how to
## get a wine stain out of cloth understands it better.
func codex_understanding() -> float:
	var themes := 0.0
	if not AbilityGrammar.THEMES.is_empty():
		themes = float(codex.size()) / float(AbilityGrammar.THEMES.size())
	var weight := float(Database.world_rules.get("codex", {}).get("trivia_weight", 0.4))
	return clampf(themes * (1.0 - weight) + Trivia.share_found(self) * weight, 0.0, 1.0)


## Re-register every generated ability after a load, so saved characters can
## still cast what they learned.
func restore_abilities() -> void:
	for tree_id: String in trees:
		for ability_id: String in trees[tree_id].get("definitions", {}):
			Database.register_ability(ability_id, trees[tree_id]["definitions"][ability_id])


# --- the clock ----------------------------------------------------------------


## Advance the world by one step. Returns notices worth showing the player.
func step() -> Array:
	steps += 1
	for band in prowlers:
		band.wander(self, rng)
	if steps % UPKEEP_INTERVAL != 0:
		return []
	return _upkeep()


func _upkeep() -> Array:
	var notices: Array = []
	var rules: Dictionary = Database.world_rules.get("gate", {})
	var patience := int(rules.get("break_after_steps", 600))

	# A cleared gate is finished with. The danger is the ones left standing open:
	# what is behind them piles up until it comes out on its own.
	for site in sites_of_kind(Site.GATE):
		if not site.open or site.broken:
			continue
		if steps - site.opened_at < patience:
			continue
		if rng.randf() < float(rules.get("break_chance", 0.75)):
			site.broken = true
			notices.append("%s has broken. Whatever was behind it is out." % site.display_name)
		else:
			# It held this time; the clock starts again.
			site.opened_at = steps
	notices.append_array(Town.upkeep(self))
	notices.append_array(Skein.on_step(self))
	return notices


# --- serialisation ------------------------------------------------------------


func to_dict() -> Dictionary:
	return {
		"world_seed": world_seed,
		"size": [size.x, size.y],
		"tiles": tiles,
		"sites": sites.map(func(s: Site) -> Dictionary: return s.to_dict()),
		"prowlers": prowlers.map(func(p: Prowler) -> Dictionary: return p.to_dict()),
		"steps": steps,
		"player_cell": [player_cell.x, player_cell.y],
		"tower_floor": tower_floor,
		"tower_topped": tower_topped,
		"trees": trees,
		"codex": codex,
		"trivia": trivia,
		"deeds": deeds,
		"threads": threads,
		"journal": journal,
		# A 64-bit state would lose precision as a JSON number.
		"rng_state": str(rng.state),
	}


static func from_dict(payload: Dictionary) -> World:
	var world := World.new()
	world.world_seed = int(payload.get("world_seed", 0))
	var size_pair: Array = payload.get("size", [SIZE.x, SIZE.y])
	world.size = Vector2i(int(size_pair[0]), int(size_pair[1]))
	world.tiles = payload.get("tiles", [])
	world.steps = int(payload.get("steps", 0))
	var cell_pair: Array = payload.get("player_cell", [0, 0])
	world.player_cell = Vector2i(int(cell_pair[0]), int(cell_pair[1]))
	world.tower_floor = int(payload.get("tower_floor", 0))
	world.tower_topped = bool(payload.get("tower_topped", false))
	world.trees = payload.get("trees", {})
	world.codex = payload.get("codex", {})
	world.trivia = payload.get("trivia", [])
	world.deeds = payload.get("deeds", [])
	world.threads = payload.get("threads", {})
	world.journal = payload.get("journal", {})
	for entry: Dictionary in payload.get("sites", []):
		world.sites.append(Site.from_dict(entry))
	for entry: Dictionary in payload.get("prowlers", []):
		world.prowlers.append(Prowler.from_dict(entry))
	world.rng.seed = world.world_seed
	var saved_state: String = payload.get("rng_state", "")
	if saved_state.is_valid_int():
		world.rng.state = saved_state.to_int()
	world.restore_abilities()
	return world
