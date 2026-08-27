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
var steps: int = 0
var player_cell: Vector2i = Vector2i.ZERO
## Highest Tower floor anyone has come back down from.
var tower_floor: int = 0
## Generated skill trees, id -> tree dict (see [AbilityGrammar]).
var trees: Dictionary = {}
## Themes the world has catalogued, for the Codex readout.
var codex: Dictionary = {}

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


func tower() -> Site:
	var towers := sites_of_kind(Site.TOWER)
	return towers[0] if not towers.is_empty() else null


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
		if site.kind == Site.VILLAGE or site.kind == Site.KEEP or site.kind == Site.HUT:
			best = mini(best, Pathfinder.distance(cell, site.cell))
	return best


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
func codex_understanding() -> float:
	if AbilityGrammar.THEMES.is_empty():
		return 0.0
	return float(codex.size()) / float(AbilityGrammar.THEMES.size())


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
	if steps % UPKEEP_INTERVAL != 0:
		return []
	return _upkeep()


func _upkeep() -> Array:
	var notices: Array = []
	for site in sites_of_kind(Site.GATE):
		if site.open:
			continue
		# A cleared gate stays shut longer, but nothing stays shut forever.
		var chance := 0.10 if site.cleared else 0.25
		if rng.randf() < chance:
			site.open = true
			site.cleared = false
			notices.append("A %s-rank gate has opened at %s." % [site.rank, site.display_name])
	return notices


# --- serialisation ------------------------------------------------------------


func to_dict() -> Dictionary:
	return {
		"world_seed": world_seed,
		"size": [size.x, size.y],
		"tiles": tiles,
		"sites": sites.map(func(s: Site) -> Dictionary: return s.to_dict()),
		"steps": steps,
		"player_cell": [player_cell.x, player_cell.y],
		"tower_floor": tower_floor,
		"trees": trees,
		"codex": codex,
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
	world.trees = payload.get("trees", {})
	world.codex = payload.get("codex", {})
	for entry: Dictionary in payload.get("sites", []):
		world.sites.append(Site.from_dict(entry))
	world.rng.seed = world.world_seed
	var saved_state: String = payload.get("rng_state", "")
	if saved_state.is_valid_int():
		world.rng.state = saved_state.to_int()
	world.restore_abilities()
	return world
