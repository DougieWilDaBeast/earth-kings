extends Node2D
## The fight: real time with pause, the M11 build of [D36] that both founders
## chose ([D58], [D63], [D64]; see `docs/18-combat-direction.md` and
## `docs/investigation/07-dungeon-settlers-combat.md`).
##
## Every fight the world starts comes here — a band on the road, a gate floor
## and its objective, the Tower, a guild muster, the coliseum and the training
## yard. Nobody waits for a turn: units walk tile to tile at their own pace,
## swing on their own tempo, and skills come back on cooldowns. The player can
## pause at any moment and give orders while paused.
##
## A fight the world started is written back onto the world, as the turn-based
## battle it replaced was ([D65]): experience from first kills and assists,
## practice, the journal, wounds, and the fallen settled through [Fate]. A
## `sandbox` fight (training, the coliseum) writes nothing onto the world.
##
## A band met on the ground (`"field"` in the payload) is fought on that same
## ground ([D66]): its own tiles, its trees and rocks in the way, everyone
## standing where they stood when the band saw them. Afterwards play goes back
## to the same spot (`return_payload`).
##
## Fought in place (`"in_place"`, the First Hour's step 4): the ground scene puts this scene down on
## itself, moved and scaled so each of its cells is one of the ground's. Nothing changes screen: the
## ground is the field, its camera stays, the grid shows only under orders and the pointer, the HUD is
## the party's cards and one line, and walking off the field's edge gets that fighter clear. When it is
## over it says so ([signal gone]) and the ground carries on.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishBrain := preload("res://src/skirmish/skirmish_brain.gd")
const SkirmishMarks := preload("res://src/skirmish/skirmish_marks.gd")
const SkirmishHUD := preload("res://src/skirmish/skirmish_hud.gd")
const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")
const SkirmishFx := preload("res://src/skirmish/skirmish_fx.gd")
const SkirmishSignatures := preload("res://src/skirmish/skirmish_signatures.gd")
const GroundPainter := preload("res://src/area/ground_painter.gd")
const Land := preload("res://src/area/land.gd")

signal finished(victory: bool)

const DEFAULT_MAP := "verdant_pass"
const END_SCREEN_DELAY := 2.0
## On the ground there is no screen to leave, only the word over the field to read.
const IN_PLACE_DELAY := 1.0
## How much of the screen height the party cards take.
const HUD_SHARE := 0.24
## When the fight stops itself: never, when a party member goes down, or also
## when a skill comes back for someone the player is playing by hand.
enum AutoPause { OFF, ON_FALL, ON_FALL_AND_READY }
const AUTO_PAUSE_LABELS := ["off", "when someone goes down", "when someone goes down or a manual skill is ready"]
## Kept for the whole session, so it is set once rather than every fight.
static var auto_pause: AutoPause = AutoPause.ON_FALL

## What pops up over someone a grace has just saved, by [Fate] reason.
const GRACE_WORDS := {
	"charm": "The charm holds!", "rescue": "Pulled clear!", "lore": "Remembered!",
	"ground": "Crawls clear!", "luck": "Sheer luck!",
}

## Most fixed ticks a single frame may run, so a hitch cannot snowball.
const MAX_TICKS_PER_FRAME := 16
## A held stick walks the pad's cursor: one tile, then a run (real seconds).
const PAD_FIRST_REPEAT := 0.3
const PAD_REPEAT := 0.09

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}
## Laid over the ground it was met on, which carries on round it (see the header).
var in_place: bool = false
## Over, and its last words read: the ground takes the scene off ([member in_place] only).
signal gone
## Nobody left standing, and some of them got clear: not won, but not lost either.
var fled_field: bool = false

@onready var grid: BattleGrid = $Grid
@onready var overlay: GridOverlay = $Overlay
@onready var units_root: Node2D = $Units
@onready var marks: SkirmishMarks = $Marks
@onready var camera: CameraRig = $Camera2D
@onready var hud: SkirmishHUD = $HUD

var map_id: String = DEFAULT_MAP
## Where on the ground a band was met: `{ area_id, origin, size, party, foes,
## title }` in the ground's own cells. Empty for a fight anywhere else.
var ground_field: Dictionary = {}
## What the fight is called on the clock: the encounter's title, else the map's name.
var title: String = "A fight"
## Set when the fight came from the world rather than an authored map.
var encounter: Dictionary = {}
## A training or coliseum fight: nobody really dies and the world is not told.
var sandbox: bool = false
## Whether the party learns from this fight: experience and practice. Always in
## a fight the world started; in a sandbox only when the payload asks (`learn`),
## as the coliseum does for the copy of the company it sends out ([D65]).
var learning: bool = true
## What winning takes (see [method Site.floor_objective]); rout unless a gate says otherwise.
var objective: String = Site.OBJECTIVE_ROUT
## The cell a party member has to reach on a heart floor.
var heart_cell: Vector2i = Vector2i(-1, -1)
var pathfinder: Pathfinder
var fighters: Array[Fighter] = []
## Party fighters taking orders; the first is the one quick-slot keys speak for.
var selected: Array[Fighter] = []
## The party's draughts and herbs for this fight, item id → how many (D59). Counted
## from the stores; what is used comes out of them too, except in a sandbox
## fight, which draws on the training pouch when the stores are empty ([D65]).
var pouch: Dictionary = {}
## Where the left button went down, in the field's own space, while it is held.
var _press_at: Vector2 = Vector2.INF
## The box being dragged to pick fighters; empty when there is none ([member SkirmishMarks]).
var drag_box: Rect2 = Rect2()
var paused: bool = true
var over: bool = false
var victory: bool = false
## Seconds of fight that have actually been simulated.
var sim_time: float = 0.0
## Set by tests, which call [method tick] themselves instead of waiting on frames.
var manual: bool = false

## The quick slot waiting for a left-click to say where it goes; -1 when none.
var armed_slot: int = -1
## Played with a thumb. There is no right button, so a tap that is not picking
## somebody gives the order a right-click would, and the keys become buttons
## down the side of the screen. Follows the touch setting unless the boot
## payload says otherwise.
var touch: bool = false

var _accumulator: float = 0.0
## Where a pad is pointing. There is no mouse on a pad, so orders are given
## at this tile instead of under a click.
var pad_cell: Vector2i = Vector2i(-1, -1)
var _pad_held: Vector2i = Vector2i.ZERO
var _pad_repeat: float = 0.0

## Numbers, flashes and rings over the field (see [SkirmishFx]).
var fx: SkirmishFx
## The sixteen's own ways of fighting (see [SkirmishSignatures]).
var signatures: SkirmishSignatures
## Rolls the graces in the near-death window. Seeded from the global seed, so a
## test that seeds the fight seeds its graces too.
var grace_rng := RandomNumberGenerator.new()
## How the next number that pops off a unit should look: "", "crit" or "thorns".
var _hit_style: String = ""
## Real seconds the clock stands still after a big hit.
var _hitstop: float = 0.0
## How hard the camera is shaking, in pixels; dies away by itself.
var _shake: float = 0.0
## Unit -> the Characters who healed it this fight, for a healer's assist ([D54]).
var _healed_by: Dictionary = {}
## What the ledger was doing before a sandbox fight switched it off.
var _kept_tallying: bool = true
## Lines worth saying once the log is up: the ambush, the allies, the objective.
var _opening: Array[String] = []
## Whether the clock has been started yet, for the first-time tip on facing.
var _started: bool = false


func _ready() -> void:
	map_id = str(boot_payload.get("map_id", DEFAULT_MAP))
	in_place = bool(boot_payload.get("in_place", false))
	encounter = boot_payload.get("encounter", {})
	sandbox = bool(boot_payload.get("sandbox", false))
	learning = bool(boot_payload.get("learn", not sandbox))
	# Nothing done on the training ground or the sand belongs in the run's ledger.
	_kept_tallying = GameState.tallying
	if sandbox:
		GameState.tallying = false
	# A party playing itself does not wait at the start for a key nobody presses.
	paused = bool(boot_payload.get("paused", not Pace.auto))
	touch = bool(boot_payload.get("touch", Pace.is_touch_enabled()))
	grace_rng.seed = randi()
	fx = SkirmishFx.new()
	fx.z_index = 20
	add_child(fx)
	signatures = SkirmishSignatures.new(self)
	_build_battlefield()
	_fill_pouch()
	marks.skirmish = self
	EventBus.unit_damaged.connect(_on_unit_damaged)
	EventBus.unit_healed.connect(_on_unit_healed)
	EventBus.levelled_up.connect(_on_levelled_up)
	Pace.changed.connect(_on_pace_changed)
	hud.setup(self)
	hud.card_clicked.connect(_on_card_clicked)
	hud.action_pressed.connect(act)
	hud.slot_clicked.connect(_on_slot_clicked)
	hud.item_clicked.connect(_on_item_clicked)
	var party := party_fighters()
	if not party.is_empty():
		_select([party[0]])
	var begin := "tap Pause" if touch else (Pad.key("command_wait") if Pad.using_pad else "Space")
	if str(boot_payload.get("auto_stopped", "")) != "":
		_say(str(boot_payload["auto_stopped"]))
	_say("The fight is paused — %s to begin." % begin if paused else "The fight is on.")
	for line in _opening:
		_say(line)
	EventBus.battle_started.emit(map_id)


func _exit_tree() -> void:
	GameState.tallying = _kept_tallying
	if Pace.changed.is_connected(_on_pace_changed):
		Pace.changed.disconnect(_on_pace_changed)


## Autoplay is switched from more places than this screen — the touch bar, a
## soak, the walk the fight was started from — so the fight notices it here.
## A party playing itself is never left standing on a paused clock.
func _on_pace_changed() -> void:
	if Pace.auto and paused and not over:
		set_paused(false)


# --- setup -------------------------------------------------------------------


func _build_battlefield() -> void:
	var map: Dictionary = encounter.get("map", {}) if not encounter.is_empty() else Database.map(map_id)
	ground_field = boot_payload.get("field", {})
	if not ground_field.is_empty():
		map = _ground_field()
		if in_place:
			# The ground is already there, under this scene: only the field's edge is drawn.
			grid.draw_floor = false
			grid.quiet = true
		else:
			_lay_the_ground()
	grid.load_map(map)
	title = str(encounter.get("title", map.get("name", title)))
	overlay.grid = grid
	pathfinder = Pathfinder.new(grid)
	# The party cards cover the bottom of the screen, so the camera frames the
	# field with that much empty ground below it and the whole fight sits above.
	var field := Vector2(grid.width, grid.height) * BattleGrid.CELL_SIZE
	var framed := Rect2(Vector2.ZERO, Vector2(field.x, field.y / (1.0 - HUD_SHARE)))
	units_root.y_sort_enabled = true
	if in_place:
		# The ground's own camera stays on; this one never comes on, nor takes the wheel from it.
		camera.enabled = false
		camera.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		camera.frame(framed)
		camera.focus_on(framed.get_center(), true)

	if ground_field.is_empty():
		_spawn_nature_decor(map)
	elif not in_place:
		_open_where_they_stood(framed)
	var spawns: Array = map.get("player_spawns", [])
	var members := GameState.party_characters()
	var taken: Array[Vector2i] = []
	for entry: Dictionary in map.get("enemies", []) + map.get("allies", []):
		taken.append(_to_cell(entry.get("cell", [0, 0])))
	var cells := grid.muster_cells(spawns, members.size(), taken)
	if cells.size() < members.size():
		push_warning("Skirmish: map %s has no room for the whole party" % map_id)
	for i in mini(members.size(), cells.size()):
		_enlist(Unit.from_character(members[i], Unit.Team.PLAYER, cells[i]))
	_spawn_others(map.get("enemies", []), Unit.Team.ENEMY)
	_spawn_others(map.get("allies", []), Unit.Team.ALLY)
	signatures.muster()
	_face_the_other_side()
	_write_them_up(map)

	if bool(encounter.get("ambush", false)):
		_give_the_party_the_jump()
		_opening.append("Ambush! The company is on them before they are ready.")
	if not map.get("allies", []).is_empty():
		_opening.append("%d stand with you." % map["allies"].size())
	var confrontation := str(encounter.get("confrontation", ""))
	if confrontation != "":
		_opening.append(confrontation)
	_set_objective(map)
	if not ground_field.is_empty() and not in_place:
		_draw_back()


## The enemy (or, with [param side] ALLY, those fighting beside the party) from
## the map. A levelled entry is a throwaway [Character], so it grows the way the
## party does; an entry may name itself, mark itself the keeper (`boss`), or
## pick its own side (`team`, for the coliseum's brawls).
func _spawn_others(entries: Array, side: Unit.Team) -> void:
	for entry: Dictionary in entries:
		var cell := _to_cell(entry.get("cell", [0, 0]))
		var level := int(entry.get("level", 0))
		var unit_team: Unit.Team = int(entry.get("team", side)) as Unit.Team
		var custom_name := str(entry.get("name", ""))
		var unit: Unit
		if level <= 0:
			unit = Unit.create(str(entry.get("unit", "")), unit_team, cell)
		else:
			var foe := Character.create(str(entry.get("unit", "")))
			if custom_name != "":
				foe.display_name = custom_name
			Progression.raise_quietly(foe, level, GameState.world)
			unit = Unit.from_character(foe, unit_team, cell)
		if custom_name != "":
			unit.display_name = custom_name
		if bool(entry.get("boss", false)):
			unit.set_meta("boss", true)
		_enlist(unit)


## The real-time form of an ambush's first-round initiative: the party moves
## at once, and the other side's opening is held back `ambush_head_start` seconds.
func _give_the_party_the_jump() -> void:
	var head_start := SkirmishPassives.rule("ambush_head_start", 2.0)
	for f in fighters:
		if f.unit.sides_with_party():
			f.attack_timer = 0.0
			f.think_timer = 0.0
		else:
			f.attack_timer += head_start
			f.think_timer += head_start


func _set_objective(map: Dictionary) -> void:
	objective = str(encounter.get("objective", Site.OBJECTIVE_ROUT))
	if objective == Site.OBJECTIVE_HEART:
		if not map.has("heart"):
			objective = Site.OBJECTIVE_ROUT
			return
		heart_cell = _to_cell(map["heart"])
		overlay.objective_cell = heart_cell
	if objective != Site.OBJECTIVE_ROUT:
		_opening.append("%s — %s" % [Site.objective_name(objective), Site.objective_brief(objective)])


## Open a journal entry for anything the party has not stood across from before.
## Training fights are not written down — knowing a thing from the sandbox
## would be knowing it for free.
func _write_them_up(map: Dictionary) -> void:
	if sandbox:
		return
	var place := str(map.get("name", encounter.get("title", "somewhere")))
	for f in fighters:
		if f.unit.sides_with_party():
			continue
		if Journal.sighted(GameState.world, f.unit.template_id, place):
			_opening.append("%s is new. The journal opens a page." % f.unit.display_name)


## Trees on the crags, walls and some of the edge, bushes in the brush, drawn
## at the size `data/props.json` gives them for a fight. Scenery only.
func _spawn_nature_decor(map: Dictionary) -> void:
	var trees: Array = Database.skirmish.get("decor", {}).get("trees", [])
	var bushes: Array = Database.skirmish.get("decor", {}).get("bushes", [])
	if trees.is_empty() and bushes.is_empty():
		return
	var spawn_cells: Array[Vector2i] = []
	for p in map.get("player_spawns", []):
		spawn_cells.append(_to_cell(p))
	for e: Dictionary in map.get("enemies", []) + map.get("allies", []):
		spawn_cells.append(_to_cell(e.get("cell", [0, 0])))
	for y in grid.height:
		for x in grid.width:
			var cell := Vector2i(x, y)
			if cell in spawn_cells:
				continue
			var terrain_id := grid.terrain_id_at(cell)
			var seed_val := absi(hash(cell))
			var edge := x == 0 or x == grid.width - 1 or y == 0 or y == grid.height - 1
			if not trees.is_empty() and (terrain_id == "crag" or terrain_id == "wall" \
					or (edge and terrain_id != "brush" and seed_val % 3 == 0)):
				_plant(str(trees[seed_val % trees.size()]), cell, 1.0)
			elif not bushes.is_empty() and terrain_id == "brush":
				_plant(str(bushes[seed_val % bushes.size()]), cell, 0.88)


## One piece of scenery standing on [param cell]: its roots on the cell's lower
## edge, at the size the props table gives it for a fight, scaled to a cell.
func _plant(art_id: String, cell: Vector2i, alpha: float) -> void:
	var path := "res://art/props/%s.png" % art_id
	if not ResourceLoader.exists(path):
		return
	var texture: Texture2D = load(path)
	var size := float(Database.prop_size(art_id)["battle_scale"]) * BattleGrid.CELL_SIZE / 64.0
	var painted := AreaProp.painted_rect(art_id, texture)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.scale = Vector2(size, size)
	sprite.position = grid.cell_to_world(cell) + Vector2(
		-painted.get_center().x * size, BattleGrid.CELL_SIZE * 0.4 - painted.end.y * size)
	sprite.modulate = Color(1.0, 1.0, 1.0, alpha)
	units_root.add_child(sprite)


## The patch of ground the band was met on, as a battlefield: what can be
## walked there can be fought over, cover is brush, and everybody stands where
## they were standing.
func _ground_field() -> Dictionary:
	var ground := _the_ground()
	var origin := _to_cell(ground_field.get("origin", [0, 0]))
	var size := _to_cell(ground_field.get("size", [16, 11]))
	var rows: Array = []
	for y in size.y:
		var row := ""
		for x in size.x:
			var cell := origin + Vector2i(x, y)
			if ground == null or not ground.is_walkable(cell):
				row += "#"
			elif bool(Database.area_terrain(ground.terrain_at(cell)).get("cover", false)):
				row += ","
			else:
				row += "."
		rows.append(row)
	var spawns: Array = []
	for pair: Array in ground_field.get("party", []):
		var c := _to_cell(pair) - origin
		spawns.append([c.x, c.y])
	var foe_cells: Array[Vector2i] = []
	for pair: Array in ground_field.get("foes", []):
		foe_cells.append(_to_cell(pair) - origin)
	var enemies: Array = []
	var listed: Array = encounter.get("enemies", [])
	for i in listed.size():
		var entry: Dictionary = (listed[i] as Dictionary).duplicate()
		var at: Vector2i = foe_cells[i % foe_cells.size()] if not foe_cells.is_empty() else Vector2i(size.x - 2, 1)
		entry["cell"] = [at.x, at.y]
		enemies.append(entry)
	var laid := {
		"name": str(ground_field.get("title", "the ground")),
		"tiles": rows,
		"legend": { ".": "grass", ",": "brush", "#": "wall" },
		"player_spawns": spawns,
		"enemies": _spread_out(enemies, rows),
	}
	# A gate's fight on the ground (D162): the Guild's people fall in beside the party, and a heart
	# floor's heart is the gate's doorway.
	var allies: Array = []
	for each: Variant in ground_field.get("allies", []):
		var ally: Dictionary = (each as Dictionary).duplicate()
		var beside: Array = spawns[allies.size() % spawns.size()] if not spawns.is_empty() else [1, size.y - 2]
		ally["cell"] = [int(beside[0]), int(beside[1]) + 1]
		allies.append(ally)
	if not allies.is_empty():
		laid["allies"] = _spread_out(allies, rows, laid["enemies"])
	if ground_field.has("heart"):
		var at := _to_cell(ground_field["heart"]) - origin
		laid["heart"] = _spread_out([{ "cell": [at.x, at.y] }], rows)[0]["cell"]
	return laid


## Two of them told to stand on one cell: the second takes the nearest free one.
func _spread_out(enemies: Array, rows: Array, standing: Array = []) -> Array:
	var taken: Dictionary = {}
	for pair: Array in ground_field.get("party", []):
		taken[_to_cell(pair) - _to_cell(ground_field.get("origin", [0, 0]))] = true
	for entry: Dictionary in standing:
		taken[_to_cell(entry["cell"])] = true
	for entry: Dictionary in enemies:
		var at := _to_cell(entry["cell"])
		var tries := 0
		while (taken.has(at) or _row_blocked(rows, at)) and tries < 60:
			tries += 1
			at = _to_cell(entry["cell"]) + Vector2i(tries % 5 - 2, tries / 5 % 5 - 2)
		taken[at] = true
		entry["cell"] = [at.x, at.y]
	return enemies


func _row_blocked(rows: Array, at: Vector2i) -> bool:
	if at.y < 0 or at.y >= rows.size() or at.x < 0 or at.x >= str(rows[at.y]).length():
		return true
	return str(rows[at.y])[at.x] == "#"


## The ground the band was met on: the area it names, or, met on the land ([D84]), the tiles the
## field lies across and those round them. Laid out once and kept.
func _the_ground() -> AreaMap:
	if _ground != null:
		return _ground
	if bool(ground_field.get("land", false)) and GameState.world != null:
		var land := Land.new()
		land.setup(GameState.world)
		var origin := _to_cell(ground_field.get("origin", [0, 0]))
		var size := _to_cell(ground_field.get("size", [16, 11]))
		var lo: Vector2i = land.tile_of(origin) - Vector2i.ONE
		var hi: Vector2i = land.tile_of(origin + size - Vector2i.ONE) + Vector2i.ONE
		for ty in range(lo.y, hi.y + 1):
			for tx in range(lo.x, hi.x + 1):
				land.hold(Vector2i(tx, ty))
		var middle: Dictionary = land.chunk_at(origin + size / 2)
		land.tint = str(middle.get("tint", ""))
		_ground = land
	else:
		_ground = AreaMap.load_area(str(ground_field.get("area_id", "")))
	return _ground


var _ground: AreaMap = null


## The fight opens on exactly what the ground was showing (`view` in the field: the camera's centre
## in ground pixels, and its zoom), then, after a breath, draws back over the whole field ([D66]).
func _open_where_they_stood(framed: Rect2) -> void:
	var view: Dictionary = ground_field.get("view", {})
	var centre: Array = view.get("centre", [])
	if centre.size() < 2:
		return
	var ratio := float(BattleGrid.CELL_SIZE) / float(AreaMap.CELL)
	var origin := Vector2(_to_cell(ground_field.get("origin", [0, 0]))) * AreaMap.CELL
	var at := (Vector2(float(centre[0]), float(centre[1])) - origin) * ratio
	camera.call("_apply_zoom", float(view.get("zoom", 1.0)) / ratio)
	camera.focus_on(at, true)
	var seconds := float(Database.world_rules.get("ground_watch", {}).get("pull_back_seconds", 0.9))
	var settle := func() -> void:
		await get_tree().create_timer(0.35, true, false, true).timeout
		if is_inside_tree() and not over:
			camera.pull_back(seconds)
	settle.call()


## The ground's own tiles and what stands on them, scaled to the fight's cells
## and moved so the patch fought over sits on the grid.
func _lay_the_ground() -> void:
	var ground := _the_ground()
	if ground == null:
		return
	var under := Node2D.new()
	under.name = "Ground"
	under.z_index = -1
	var zoom := float(BattleGrid.CELL_SIZE) / float(AreaMap.CELL)
	under.scale = Vector2(zoom, zoom)
	under.position = -Vector2(_to_cell(ground_field.get("origin", [0, 0]))) * BattleGrid.CELL_SIZE
	add_child(under)
	move_child(under, 0)
	GroundPainter.paint(ground, under)
	var standing := Node2D.new()
	standing.y_sort_enabled = true
	under.add_child(standing)
	GroundPainter.dress(ground, standing)
	if ground.tint != "":
		under.modulate = Color(ground.tint).lerp(Color.WHITE, 0.6)
	grid.draw_floor = false


## How much closer the camera starts on a fight met on the ground, and how long
## it takes to draw back over the whole field: the fight opens as a step back
## from where the party stood, not a cut to somewhere else (from #66).
const DRAW_BACK_ZOOM := 1.6
const DRAW_BACK_TIME := 0.9


func _draw_back() -> void:
	var party := party_fighters()
	if party.is_empty():
		return
	var middle := Vector2.ZERO
	for f in party:
		middle += f.unit.position
	middle /= float(party.size())
	var to_zoom := camera.zoom
	var to_position := camera.position
	camera.zoom = to_zoom * DRAW_BACK_ZOOM
	camera.position = middle
	camera.reset_smoothing()
	var back := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	back.tween_property(camera, "zoom", to_zoom, DRAW_BACK_TIME)
	back.tween_property(camera, "position", to_position, DRAW_BACK_TIME)


func _enlist(unit: Unit) -> Fighter:
	# Wounds carry in as a share, so a hurt party starts the fight as hurt.
	var share := float(unit.hp) / float(maxi(1, unit.max_hp))
	unit.max_hp = roundi(float(unit.max_hp) * SkirmishRules.HEALTH_SCALE)
	unit.hp = maxi(1, roundi(share * float(unit.max_hp)))
	unit.snap_to_cell(grid)
	units_root.add_child(unit)
	var f := Fighter.new(unit)
	fighters.append(f)
	return f


func _fill_pouch() -> void:
	pouch = {}
	for item_id in GameState.stores:
		if Gear.is_draught(str(item_id)):
			pouch[str(item_id)] = int(pouch.get(str(item_id), 0)) + 1
	# Only training hands out a pouch of its own; on the road it is what you carry.
	if pouch.is_empty() and sandbox:
		pouch = (Database.skirmish.get("training_pouch", {}) as Dictionary).duplicate()


## What is in the pouch, weakest first, so the small one is spent on a scratch.
func pouch_items() -> Array:
	var out: Array = pouch.keys()
	out.sort_custom(func(a: String, b: String) -> bool: return Gear.mends(a) < Gear.mends(b))
	return out


## Whether [param f] could start on [param item_id] right now, and if not, why.
func item_refusal(f: Fighter, item_id: String) -> String:
	if f == null or not f.is_standing():
		return "not standing"
	if int(pouch.get(item_id, 0)) <= 0:
		return "none left"
	if f.items_used >= int(SkirmishPassives.rule("items_per_fighter", 2)):
		return "had enough"
	if f.unit.hp >= f.unit.max_hp:
		return "unhurt"
	if f.is_using() or f.is_stunned():
		return "busy"
	return ""


## Start drinking or chewing [param item_id]. It takes `use_item_time` seconds,
## in which the fighter stands still and can be hit, but cannot be stunned.
func use_item(f: Fighter, item_id: String) -> bool:
	var why := item_refusal(f, item_id)
	if why != "":
		_say("%s can't use the %s: %s." % [f.unit.display_name if f != null else "Nobody", Gear.display_name(item_id), why])
		return false
	f.give(Fighter.Order.NONE)
	f.target = null
	var total := SkirmishPassives.rule("use_item_time", 1.5)
	f.using = {"item": item_id, "left": total, "total": total}
	_say("%s reaches for the %s." % [f.unit.display_name, Gear.display_name(item_id)])
	hud.refresh()
	return true


## [param thrower] is whoever threw it, when it was thrown (Juno's Provision).
func _finish_item(f: Fighter, thrower: Fighter = null) -> void:
	var item_id := str(f.using["item"])
	f.using = {}
	pouch[item_id] = int(pouch.get(item_id, 0)) - 1
	if int(pouch[item_id]) <= 0:
		pouch.erase(item_id)
	f.items_used += 1
	# In a fight the world started, what is drunk is gone from the stores ([D65]).
	if not sandbox:
		GameState.stores.erase(item_id)
	# Health is scaled up for real time, so what a draught mends is too.
	var amount := roundi(float(Gear.mends(item_id)) * SkirmishRules.HEALTH_SCALE * signatures.item_scale(f, thrower))
	f.unit.heal(amount)
	Sfx.cue("drink")
	fx.popup(Gear.display_name(item_id), f.unit.position + Vector2(0, -14), SkirmishFx.HEAL, 13)
	_say("%s takes the %s." % [f.unit.display_name, Gear.display_name(item_id)])
	hud.refresh()


## Knocked senseless for [param seconds]. Whatever was being wound up is lost;
## somebody drinking a draught keeps their feet.
func _stun(f: Fighter, by: Fighter, seconds: float) -> void:
	if f == null or not f.is_standing() or seconds <= 0.0:
		return
	if f.is_using() or signatures.stun_proof(f):
		fx.popup("steady", f.unit.position, SkirmishFx.WORD, 12)
		return
	if f.is_casting():
		var slot := int(f.cast["slot"])
		var ability := f.slot_ability(slot)
		f.cast = {}
		f.cooldowns[slot] = SkirmishRules.cooldown(ability) * 0.5
		if f.order == Fighter.Order.CAST:
			f.clear_order()
		if by != null:
			by.interrupts += 1
		fx.popup("Interrupted!", f.unit.position + Vector2(0, -16), SkirmishFx.HURT, 15, 1.2)
		_say("%s's %s is broken off." % [f.unit.display_name, ability.get("display_name", "skill")])
	f.aiding = 0.0
	f.stunned = maxf(f.stunned, seconds)
	fx.popup("Stunned", f.unit.position, SkirmishFx.WORD, 13)
	Sfx.cue("stun")


## A sword swing at a shield bearer who sees it coming may be turned aside.
func _blocks(f: Fighter, victim: Fighter, ability_id: String) -> bool:
	if victim == null or not victim.shield or ability_id != f.basic:
		return false
	if int(Database.ability(ability_id).get("range", 1)) > 1:
		return false
	if not victim.is_standing() or victim.is_casting() or victim.is_using() or victim.is_stunned():
		return false
	if AbilityResolver.flank_of(f.unit.cell, victim.unit) == AbilityResolver.Flank.BACK:
		return false
	var chance := minf(SkirmishPassives.rule("block_max", 0.4),
			SkirmishPassives.rule("block_chance", 0.15)
			+ SkirmishPassives.rule("block_per_defence", 0.01) * float(victim.unit.defense))
	return randf() < chance


## Both lines start looking at each other, so the opening exchange is not a
## free blow at the back of whoever happened to face the wrong way.
func _face_the_other_side() -> void:
	for f in fighters:
		var centre := Vector2.ZERO
		var count := 0
		for other in fighters:
			if other.unit.is_hostile_to(f.unit):
				centre += Vector2(other.unit.cell)
				count += 1
		if count > 0:
			f.unit.face_towards(Vector2i((centre / float(count)).round()))


# --- the clock ---------------------------------------------------------------


func _process(delta: float) -> void:
	_feel(delta)
	if not manual and not paused and not over and _hitstop <= 0.0 and not _held_by_a_screen():
		if not _started:
			_started = true
			EventBus.tip_moment.emit("facing", {})
		# Engine.time_scale already folds the game speed into delta.
		_accumulator += delta
		var ticks := 0
		while _accumulator >= SkirmishRules.TICK and ticks < MAX_TICKS_PER_FRAME and not paused:
			tick()
			_accumulator -= SkirmishRules.TICK
			ticks += 1
		if ticks == MAX_TICKS_PER_FRAME:
			_accumulator = 0.0
	_place_steppers()
	_steer_pad_cursor(delta)
	marks.queue_redraw()
	hud.refresh()


## The camera shake, the hit-stop and the lunges, all on real time so a big hit
## feels the same at any game speed.
func _feel(delta: float) -> void:
	var real := delta / maxf(0.01, Engine.time_scale)
	_hitstop = maxf(0.0, _hitstop - real)
	if _shake > 0.05:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
		_shake = lerpf(_shake, 0.0, minf(1.0, real * 9.0))
	elif camera.offset != Vector2.ZERO:
		_shake = 0.0
		camera.offset = Vector2.ZERO
	if paused or _hitstop > 0.0:
		return
	for f in fighters:
		if f.bump > 0.0:
			f.bump = maxf(0.0, f.bump - delta * 7.0)


## The menu, the journal, a conversation: while one is open in front of a fight
## played by hand, the clock waits for it. A party playing itself plays on.
func _held_by_a_screen() -> bool:
	if Pace.auto:
		return false
	for node in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if node.has_method("is_open") and node.is_open():
			return true
	return false


func shake(strength: float) -> void:
	_shake = maxf(_shake, strength)


func set_paused(value: bool) -> void:
	if over:
		return
	paused = value
	_accumulator = 0.0
	hud.refresh()


## One fixed step of the fight.
func tick() -> void:
	if over:
		return
	sim_time += SkirmishRules.TICK
	for f in fighters:
		_tick_fighter(f)
	signatures.flush()
	if in_place:
		_see_who_got_clear()
	_check_end()


## Units between tiles are drawn part-way along, using whatever part of a tick
## has built up, so movement is smooth at any frame rate.
func _place_steppers() -> void:
	for f in fighters:
		if f.aboard != null:
			f.unit.position = (f.aboard as Fighter).unit.position
			continue
		if not f.stepping:
			if f.bump > 0.0 and not f.fallen:
				f.unit.position = grid.cell_to_world(f.unit.cell) + f.bump_dir * sin(f.bump * PI) * 9.0
			continue
		var left := maxf(0.0, f.step_left - _accumulator)
		var t := 1.0 - left / maxf(0.001, f.step_total)
		f.unit.position = f.step_from.lerp(f.step_to, clampf(t, 0.0, 1.0))


func _tick_fighter(f: Fighter) -> void:
	if f.fallen or f.fled:
		return
	var cooling := SkirmishRules.TICK * signatures.cooldown_rate(f)
	for i in f.cooldowns.size():
		var was := f.cooldowns[i]
		f.cooldowns[i] = maxf(0.0, was - cooling)
		if was > 0.0 and f.cooldowns[i] <= 0.0 and f.is_party() and not f.auto_skill \
				and f.is_standing() and auto_pause == AutoPause.ON_FALL_AND_READY:
			_auto_pause("%s's %s is ready." % [f.unit.display_name, f.slot_ability(i).get("display_name", "skill")])
	if f.is_downed():
		if signatures.rises(f):
			_get_up(f)
			return
		f.near_death -= SkirmishRules.TICK
		if f.near_death <= 0.0:
			_window_ran_out(f)
		return
	f.attack_timer = maxf(0.0, f.attack_timer - SkirmishRules.TICK)
	f.since_hit += SkirmishRules.TICK
	f.recover_energy(SkirmishRules.TICK * signatures.energy_rate(f))
	f.retreat_wait = maxf(0.0, f.retreat_wait - SkirmishRules.TICK)
	_regenerate(f)
	signatures.tick(f)

	if f.stepping:
		f.step_left -= SkirmishRules.TICK
		if f.step_left > 0.0:
			return
		f.stepping = false
		f.unit.position = f.step_to
		f.unit.set_running(false)

	if f.is_stunned():
		f.stunned = maxf(0.0, f.stunned - SkirmishRules.TICK)
		return

	if f.is_using():
		f.using["left"] = float(f.using["left"]) - SkirmishRules.TICK
		if float(f.using["left"]) <= 0.0:
			_finish_item(f)
		return

	if f.is_casting():
		f.cast["left"] = float(f.cast["left"]) - SkirmishRules.TICK
		if float(f.cast["left"]) <= 0.0:
			_release(f)
		return

	if f.aiding > 0.0:
		_keep_aiding(f)
		return

	# A bearer keeps beside the one it carries before it does anything else.
	if signatures.keep_up(f):
		return

	f.think_timer -= SkirmishRules.TICK
	if f.think_timer <= 0.0:
		f.think_timer = SkirmishRules.THINK_INTERVAL
		if _think(f):
			return

	match f.order:
		Fighter.Order.MOVE:
			_pursue_move(f)
		Fighter.Order.ATTACK:
			var foe := f.order_target
			if not is_standing(foe):
				f.clear_order()
				f.target = null
			else:
				_fight(f, foe, true)
		Fighter.Order.CAST:
			_pursue_cast(f)
		Fighter.Order.AID:
			_pursue_aid(f)
		_:
			if f.target != null and is_standing(f.target):
				_fight(f, f.target, not f.hold)


## Reconsider: use a ready skill if Auto Skill is on, and pick who to swing at.
## Returns true if the fighter started something that takes the rest of the tick.
func _think(f: Fighter) -> bool:
	var free_hand := f.order == Fighter.Order.NONE or f.order == Fighter.Order.ATTACK
	if f.auto_skill and free_hand:
		var plan := SkirmishBrain.pick_skill(f, fighters)
		if not plan.is_empty():
			var who: Unit = plan["target"]
			_begin_cast(f, int(plan["slot"]), who, who.cell)
			return true
	if f.order == Fighter.Order.NONE:
		var reach := -1
		if f.is_party():
			reach = _basic_reach(f) if f.hold else SkirmishRules.PARTY_AGGRO_RANGE
			# A party playing itself goes and finds the fight.
			if Pace.auto and not f.hold:
				reach = -1
		f.target = SkirmishBrain.pick_target(f, fighters, reach)
		# The company fights together: once one of them is in it, the rest
		# come, unless told to hold.
		if f.target == null and f.is_party() and not f.hold and _party_engaged():
			f.target = SkirmishBrain.pick_target(f, fighters)
	return false


func _party_engaged() -> bool:
	return fighters.any(func(other: Fighter) -> bool:
		return other.is_party() and other.is_standing() and other.target != null \
				and is_standing(other.target))


# --- doing things ------------------------------------------------------------


## Swing at [param foe] if it is in reach, otherwise walk into reach if allowed.
func _fight(f: Fighter, foe: Unit, may_walk: bool) -> void:
	var ability := Database.ability(f.basic)
	if may_walk and _keep_away(f, ability, foe):
		return
	if AbilityResolver.in_range(ability, f.unit.cell, foe.cell):
		if f.attack_timer <= 0.0:
			_swing(f, foe, ability)
		else:
			f.unit.face_towards(foe.cell)
	elif may_walk:
		# A charger sprints at anyone far enough off to build up speed.
		var role := f.role_data()
		if role.has("charge_from") and not f.charging \
				and Pathfinder.distance(f.unit.cell, foe.cell) >= int(role["charge_from"]):
			f.charging = true
			fx.popup("Charge!", f.unit.position, SkirmishFx.HURT, 15)
		_step_towards(f, func(c: Vector2i) -> bool:
			return AbilityResolver.in_range(ability, c, foe.cell))


## A skirmisher or mender with someone too close backs off a tile or two, now
## and then — not every tick, or nothing could ever pin one down. Returns true
## when it stepped away instead of fighting.
func _keep_away(f: Fighter, ability: Dictionary, foe: Unit) -> bool:
	var role := f.role_data()
	var gap := int(role.get("keep_away", 0))
	if gap <= 0 or f.retreat_wait > 0.0 or f.is_party():
		return false
	if _nearest_hostile_distance(f, f.unit.cell) >= gap:
		return false
	var reach := int(ability.get("range", 1))
	var safe := func(c: Vector2i) -> bool:
		return _nearest_hostile_distance(f, c) >= gap \
				and Pathfinder.distance(c, foe.cell) <= maxi(reach, gap + 1)
	f.retreat_wait = float(role.get("retreat_every", 3.0))
	if _step_towards(f, safe):
		fx.popup("falls back", f.unit.position, SkirmishFx.WORD, 12)
		return true
	return false


func _nearest_hostile_distance(f: Fighter, cell: Vector2i) -> int:
	var best := 999
	for other in fighters:
		if other.is_standing() and other.unit.is_hostile_to(f.unit):
			best = mini(best, Pathfinder.distance(cell, other.unit.cell))
	return best


func _swing(f: Fighter, foe: Unit, ability: Dictionary) -> void:
	f.unit.face_towards(foe.cell)
	f.unit.play("attack")
	Sfx.cue("shoot" if int(ability.get("range", 1)) > 1 else "swing")
	if _strike(f, foe, ability, f.basic):
		_practise_swing(f)
	f.swings += 1
	f.attack_timer = SkirmishRules.attack_interval(f.unit) * (1.0 - minf(0.5, _aura(f, "haste"))) \
			* signatures.attack_scale(f)
	# Echo Blade: now and then the same swing comes round again.
	var echo := f.effect("echo")
	if echo > 0.0 and f.is_standing() and is_standing(foe) and randf() < echo:
		fx.popup("Again!", f.unit.position, SkirmishFx.WORD, 13)
		_strike(f, foe, ability, f.basic)


## One blow or one heal from [param f] onto [param target], with everything the
## passives add around [method AbilityResolver.apply]: criticals, flank and
## last-stand bonuses, a charge, guard auras, lifesteal and thorns. Returns false
## when it did not land (a shield took it).
func _strike(f: Fighter, target: Unit, ability: Dictionary, ability_id: String) -> bool:
	if bool(ability.get("heal", false)):
		Sfx.cue("heal")
		_show_effect(f, target, ability, ability_id)
		_say(AbilityResolver.apply(f.unit, ability, target, ability_id))
		_note_in_the_journal(f.unit, ability_id, target)
		if target != f.unit and target.team == f.unit.team and f.unit.character != null:
			var healers: Array = _healed_by.get_or_add(target, [])
			if not healers.has(f.unit.character):
				healers.append(f.unit.character)
		return true
	var victim := fighter_of(target)
	if _blocks(f, victim, ability_id):
		victim.blocks += 1
		f.since_hit = 0.0
		victim.since_hit = 0.0
		victim.unit.face_towards(f.unit.cell)
		fx.popup("Blocked", target.position, SkirmishFx.WORD, 13)
		fx.effect(SkirmishFx.effect_for("block"), target.position)
		Sfx.cue("block")
		_say("%s takes %s's blow on the shield." % [target.display_name, f.unit.display_name])
		return false
	var multiplier := 1.0
	var tags: Array[String] = []
	if ability_id != f.basic and SkirmishRules.is_charged(ability):
		multiplier *= SkirmishPassives.rule("charged_power", 1.6)
		tags.append("charged")
	var crit := randf() < SkirmishPassives.rule("base_crit", 0.05) + f.effect("crit")
	if crit:
		multiplier *= SkirmishPassives.rule("crit_multiplier", 1.6)
		tags.append("critical")
	var flank_bonus := f.effect("flank_bonus")
	if flank_bonus > 0.0 and AbilityResolver.flank_of(f.unit.cell, target) != AbilityResolver.Flank.FRONT:
		multiplier *= 1.0 + flank_bonus
	for p: Dictionary in f.passives:
		if str(p.get("effect", "")) == "last_stand" \
				and float(f.unit.hp) <= float(f.unit.max_hp) * float(p.get("threshold", 0.35)):
			multiplier *= 1.0 + float(p.get("value", 0.0))
			tags.append("last stand")
	if f.charging:
		f.charging = false
		multiplier *= 1.0 + float(f.role_data().get("charge_bonus", 0.0))
		tags.append("charge")
	multiplier *= signatures.might(f, victim)
	if victim != null:
		multiplier *= 1.0 - minf(SkirmishPassives.rule("guard_cap", 0.5),
				_aura(victim, "guard") + signatures.guard(victim))
	# Caesar beside them takes part of it on himself.
	var guardian := signatures.shield_for(victim)
	if guardian != null:
		multiplier *= 1.0 - signatures.share_of(guardian)
	# A ward of Vesta's soaks up what it can before the health does.
	var warded := victim.ward if victim != null else 0
	var health_before := target.hp
	target.hp += warded
	# The resolver prices a blow off the attacker's attack, so the passives
	# lean on that for the one call and put it back.
	var own_attack := f.unit.attack
	f.unit.attack = maxi(1, roundi(float(own_attack) * multiplier))
	var before := health_before
	_hit_style = "crit" if crit else ""
	var line := AbilityResolver.apply(f.unit, ability, target, ability_id)
	_hit_style = ""
	f.unit.attack = own_attack
	if warded > 0:
		var soaked := mini(warded, health_before + warded - target.hp)
		victim.ward = warded - soaked
		target.hp = mini(target.hp, health_before)
		if soaked > 0:
			fx.popup("Warded", target.position + Vector2(0, -12), SkirmishFx.GRACE, 12)
	var dealt := before - target.hp
	_show_effect(f, target, ability, ability_id)
	if dealt > 0:
		Sfx.cue("crit" if crit else "hit")
	if not tags.is_empty():
		line = "%s! %s" % [", ".join(tags).capitalize(), line]
	_say(line)
	_note_in_the_journal(f.unit, ability_id, target)
	f.since_hit = 0.0
	f.bump = 1.0
	f.bump_dir = (target.position - f.unit.position).normalized()
	if crit or dealt >= roundi(float(target.max_hp) * SkirmishPassives.rule("big_hit_share", 0.2)):
		_hitstop = maxf(_hitstop, SkirmishPassives.rule("hit_stop", 0.07))
		if crit:
			shake(SkirmishPassives.rule("shake_on_crit", 2.5))
	if victim != null and target.is_alive() and float(ability.get("stun", 0.0)) > 0.0:
		_stun(victim, f, float(ability["stun"]))
	var steal := f.effect("lifesteal")
	if steal > 0.0 and dealt > 0 and f.unit.hp < f.unit.max_hp:
		f.unit.heal(maxi(1, roundi(float(dealt) * steal)))
	signatures.landed(f, victim, dealt)
	if guardian != null and dealt > 0:
		var share := signatures.share_of(guardian)
		guardian.unit.take_damage(maxi(1, roundi(float(dealt) * share / maxf(0.1, 1.0 - share))))
		if not guardian.unit.is_alive():
			_drop(guardian)
	if not target.is_alive():
		_award_kill(f.unit, target)
		signatures.killed(f, victim)
		_drop(victim)
	# Barbed Guard: a blow from the next tile comes partly back.
	if victim != null and dealt > 0 and Pathfinder.distance(f.unit.cell, target.cell) <= 1:
		var thorns := victim.effect("thorns")
		if thorns > 0.0 and f.unit.is_alive() and not f.is_downed():
			_hit_style = "thorns"
			f.unit.take_damage(maxi(1, roundi(float(dealt) * thorns)))
			_hit_style = ""
			if not f.unit.is_alive():
				_say("%s is cut down on %s's guard." % [f.unit.display_name, target.display_name])
				_award_kill(target, f.unit)
				_drop(f)
	return true


## The strongest of [param stat] that any aura over [param f] grants. Auras of
## one kind do not stack, so two shieldwalls are one shieldwall.
func _aura(f: Fighter, stat: String) -> float:
	var best := 0.0
	for other in fighters:
		if not other.is_standing() or other.unit.is_hostile_to(f.unit):
			continue
		for p: Dictionary in other.passives:
			if str(p.get("effect", "")) != "aura":
				continue
			if Pathfinder.distance(other.unit.cell, f.unit.cell) > int(p.get("radius", 2)):
				continue
			best = maxf(best, float(p.get("grants", {}).get(stat, 0.0)))
	return best


## Health that comes back on its own: Catch Breath out of the fighting, and a
## Hearthglow over you at any time. Paid out a few points at a time.
func _regenerate(f: Fighter) -> void:
	if f.unit.hp >= f.unit.max_hp:
		f.regen_pool = 0.0
		return
	var rate := maxf(_aura(f, "regen"), signatures.regen(f))
	if f.since_hit >= SkirmishPassives.rule("out_of_combat_after", 4.0):
		rate += f.effect("regen")
	if rate <= 0.0:
		return
	f.regen_pool += rate * float(f.unit.max_hp) * SkirmishRules.TICK
	var chunk := maxf(1.0, float(f.unit.max_hp) * 0.03)
	if f.regen_pool >= chunk:
		var amount := int(f.regen_pool)
		f.regen_pool -= float(amount)
		f.unit.heal(amount)


func _pursue_move(f: Fighter) -> void:
	if f.unit.cell == f.order_cell:
		f.clear_order()
		return
	var goal := f.order_cell
	# Someone got there first: stop beside them rather than circling forever.
	if occupant(goal, f) != null and Pathfinder.distance(f.unit.cell, goal) <= 1:
		f.clear_order()
		return
	if not _step_towards(f, func(c: Vector2i) -> bool: return c == goal):
		f.clear_order()


func _pursue_cast(f: Fighter) -> void:
	var slot := f.order_slot
	var ability := f.slot_ability(slot)
	var who := f.order_target
	if ability.is_empty() or (who != null and not is_standing(who)):
		f.clear_order()
		return
	if not f.can_afford(slot):
		_say("%s is too tired for %s." % [f.unit.display_name, ability.get("display_name", "that")])
		f.clear_order()
		return
	var centre := who.cell if who != null else f.order_cell
	if AbilityResolver.in_range(ability, f.unit.cell, centre) or (who == f.unit):
		# In reach: wait for the slot to come back if it has to, then let it go.
		if f.slot_ready(slot):
			_begin_cast(f, slot, who, centre)
		else:
			f.unit.face_towards(centre)
		return
	if not _step_towards(f, func(c: Vector2i) -> bool:
			return AbilityResolver.in_range(ability, c, centre)):
		f.clear_order()


func _pursue_aid(f: Fighter) -> void:
	var patient := fighter_of(f.order_target)
	if patient == null or not patient.is_downed():
		f.clear_order()
		return
	if Pathfinder.distance(f.unit.cell, patient.unit.cell) == 1:
		f.aiding = SkirmishRules.AID_TIME
		f.unit.face_towards(patient.unit.cell)
		_say("%s kneels beside %s." % [f.unit.display_name, patient.unit.display_name])
		return
	var at := patient.unit.cell
	if not _step_towards(f, func(c: Vector2i) -> bool: return Pathfinder.distance(c, at) == 1):
		f.clear_order()


func _keep_aiding(f: Fighter) -> void:
	var patient := fighter_of(f.order_target)
	if patient == null or not patient.is_downed():
		f.aiding = 0.0
		f.clear_order()
		return
	f.aiding -= SkirmishRules.TICK
	if f.aiding > 0.0:
		return
	f.aiding = 0.0
	f.clear_order()
	patient.near_death = 0.0
	patient.unit.hp = maxi(1, roundi(float(patient.unit.max_hp) * SkirmishRules.AID_HEALTH))
	patient.unit.modulate = Color.WHITE
	patient.unit.stand()
	patient.attack_timer = 1.0
	fx.ring(patient.unit.position, SkirmishFx.HEAL, 50.0)
	fx.popup("Back up!", patient.unit.position, SkirmishFx.HEAL, 16, 1.2)
	_say("%s gets %s back on their feet." % [f.unit.display_name, patient.unit.display_name])


## Take one step along the cheapest walk to a cell [param is_goal] accepts.
## Returns false when there is no way there at all. A step that is blocked this
## instant is not a failure — the fighter waits and tries again next tick.
func _step_towards(f: Fighter, is_goal: Callable) -> bool:
	# A rider goes where his mount takes him (D93).
	var mount := f.aboard as Fighter
	if mount != null:
		return true if mount.stepping else _step_towards(mount, is_goal)
	var me := f.unit
	if not signatures.can_step(f):
		return false
	var blocked := func(c: Vector2i) -> bool: return occupant(c, f) != null
	var path := pathfinder.path_to_nearest(me.cell, me.jump, blocked, is_goal)
	if path.is_empty():
		# Boxed in by friends: plan through them and wait for them to move.
		var hostile_only := func(c: Vector2i) -> bool:
			var other := occupant(c, f)
			return other != null and other.unit.is_hostile_to(me)
		path = pathfinder.path_to_nearest(me.cell, me.jump, hostile_only, is_goal)
		if path.is_empty():
			return false
	var next: Vector2i = path[0]
	if occupant(next, f) != null:
		return true
	f.stepping = true
	f.step_from = me.position
	f.step_to = grid.cell_to_world(next)
	f.step_total = SkirmishRules.step_time(me, grid, next)
	if f.charging:
		f.step_total /= float(f.role_data().get("pace", 1.0))
	f.step_total *= signatures.step_scale(f, next)
	signatures.stepped(f)
	f.step_left = f.step_total
	me.facing = Unit.dominant_direction(next - me.cell)
	# The tile is claimed as the step begins, so nobody else walks into it.
	me.cell = next
	me.set_running(true)
	return true


## The drawn effect for a blow or a heal from [param f] landing on [param target]:
## a slash up close, an arrow flown from [param f], a burst for a spell, the heal
## on whoever is mended ([SkirmishFx.effect_for]).
func _show_effect(f: Fighter, target: Unit, ability: Dictionary, ability_id: String) -> void:
	var kind := "swing"
	if bool(ability.get("heal", false)):
		kind = "heal"
	elif ability_id == f.basic:
		kind = "shot" if int(ability.get("range", 1)) > 1 else "swing"
	elif int(ability.get("range", 1)) > 1 or SkirmishRules.cast_time(ability) > 0.0:
		kind = "spell"
	var name := SkirmishFx.effect_for(kind, ability_id)
	if name == SkirmishFx.effect_for("shot") and target != f.unit:
		fx.effect(name, target.position, f.unit.position)
	else:
		fx.effect(name, target.position)


func _begin_cast(f: Fighter, slot: int, who: Unit, centre: Vector2i) -> void:
	var ability := f.slot_ability(slot)
	if not f.can_afford(slot):
		return
	f.spend_energy(ability)
	var wind_up := SkirmishRules.cast_time(ability)
	f.unit.face_towards(centre)
	if wind_up <= 0.0:
		_land(f, slot, who, centre)
		return
	Sfx.cue("charge")
	f.cast = {"slot": slot, "target": who, "cell": centre, "left": wind_up, "total": wind_up}


func _release(f: Fighter) -> void:
	var slot := int(f.cast["slot"])
	var who: Unit = f.cast["target"]
	var centre: Vector2i = f.cast["cell"]
	f.cast = {}
	var ability := f.slot_ability(slot)
	if who != null:
		# A skill aimed at someone follows them, but not out of reach and not
		# onto the fallen.
		if not is_standing(who) or Pathfinder.distance(f.unit.cell, who.cell) > int(ability.get("range", 1)) + 1:
			f.cooldowns[slot] = SkirmishRules.cooldown(ability) * 0.5
			_say("%s's %s finds nobody there." % [f.unit.display_name, ability.get("display_name", "skill")])
			if f.order == Fighter.Order.CAST:
				f.clear_order()
			return
		centre = who.cell
	_land(f, slot, who, centre)


func _land(f: Fighter, slot: int, _who: Unit, centre: Vector2i) -> void:
	var ability_id := f.slots[slot]
	var ability := Database.ability(ability_id)
	var hits: Array[Unit] = []
	for cell in AbilityResolver.affected_cells(ability, centre):
		var target := _unit_at(cell)
		if target != null and AbilityResolver.is_valid_target(f.unit, ability, target):
			hits.append(target)
	f.cooldowns[slot] = SkirmishRules.cooldown(ability)
	f.casts += 1
	f.unit.play("skill")
	f.attack_timer = maxf(f.attack_timer, 0.4)
	if f.order == Fighter.Order.CAST:
		f.clear_order()
	if hits.is_empty():
		_say("%s's %s hits nothing." % [f.unit.display_name, ability.get("display_name", "skill")])
		return
	fx.popup(str(ability.get("display_name", "skill")), f.unit.position + Vector2(0, -14), SkirmishFx.WORD, 13)
	# A skill thrown or cast is heard going off; one swung up close is heard
	# as the swing, and a heal as its chime on whoever it mends.
	if not bool(ability.get("heal", false)):
		Sfx.cue("spell" if int(ability.get("range", 1)) > 1 or SkirmishRules.cast_time(ability) > 0.0 else "swing")
	var landed := false
	for target in hits:
		if not f.is_standing():
			break
		if _strike(f, target, ability, ability_id):
			landed = true
	# Counted once for the skill, not once per body it caught.
	if landed:
		_practise(f, ability_id)


## A basic swing that landed. Swings come several times as often as a turn did,
## so every `swings_per_practice` of them count as one use ([D65]).
func _practise_swing(f: Fighter) -> void:
	f.practice_swings += 1
	if f.practice_swings < int(SkirmishPassives.rule("swings_per_practice", 3)):
		return
	f.practice_swings = 0
	_practise(f, f.basic)


## Getting better by doing (see [Proficiency]).
func _practise(f: Fighter, ability_id: String) -> void:
	if not learning:
		return
	var better := Proficiency.record(f.unit.character, ability_id)
	if better != "":
		_say(better)


## Watching is how the journal fills in. You learn what a thing hits like by
## being hit, what it is wearing by hitting it, and how much of it there is by
## putting one down. Nothing is written down from a sandbox fight.
func _note_in_the_journal(user: Unit, ability_id: String, target: Unit) -> void:
	if sandbox or not user.is_hostile_to(target) or user.team == Unit.Team.ALLY:
		return
	var world: World = GameState.world
	if user.team != Unit.Team.PLAYER:
		Journal.note_ability(world, user.template_id, ability_id)
		Journal.note_struck(world, user.template_id)
		return
	Journal.note_wounded(world, target.template_id)
	if not target.is_alive():
		Journal.note_felled(world, target.template_id)


## Experience comes from the first of each kind, to whoever landed it; everyone
## else still standing on the party's side counts an assist, fewer needed for
## those who healed the killer ([D54]), and a keeper teaches them all ([D37],
## see [method Progression.award_kill]).
func _award_kill(killer: Unit, victim: Unit) -> void:
	if not learning or killer == null or killer.character == null or killer.team != Unit.Team.PLAYER \
			or not killer.is_hostile_to(victim):
		return
	var level := victim.character.level if victim.character != null else 1
	var involved: Array = []
	for other in fighters:
		if other.unit != killer and other.is_standing() and other.unit.team == killer.team \
				and other.unit.character != null:
			involved.append(other.unit.character)
	var boss := victim.has_meta("boss") and bool(victim.get_meta("boss"))
	for line: String in Progression.award_kill(
		killer.character, victim.template_id, level, involved, boss, GameState.world,
		_healed_by.get(killer, [])
	):
		_say(line)


## Someone just hit zero. The party goes down and can still be reached; the
## other side is simply gone.
func _drop(f: Fighter) -> void:
	if f == null or f.fallen or f.is_downed():
		return
	f.stepping = false
	f.cast = {}
	f.aiding = 0.0
	f.using = {}
	f.stunned = 0.0
	f.clear_order()
	# One of the company going down is a different sound from a foe falling.
	Sfx.cue("fall" if f.is_party() else "death")
	f.target = null
	f.unit.set_running(false)
	f.unit.play("death")
	f.unit.position = grid.cell_to_world(f.unit.cell)
	selected.erase(f)
	f.charging = false
	f.bump = 0.0
	fx.ring(f.unit.position, SkirmishFx.HURT if f.is_party() else SkirmishFx.DAMAGE, 46.0)
	_mourn(f)
	if f.is_party():
		f.near_death = SkirmishRules.NEAR_DEATH
		signatures.downed(f)
		f.unit.modulate = Color(0.75, 0.55, 0.55, 0.8)
		shake(SkirmishPassives.rule("shake_on_down", 9.0))
		fx.popup("DOWN", f.unit.position, SkirmishFx.HURT, 20, 1.4)
		_say("%s is down — %d seconds to reach them." % [f.unit.display_name, int(SkirmishRules.NEAR_DEATH)])
		if auto_pause != AutoPause.OFF:
			_auto_pause("")
	else:
		f.fallen = true
		shake(SkirmishPassives.rule("shake_on_kill", 4.0))
		# A beat to see them go (the whole fall, when they have one), then gone.
		var unit := f.unit
		var fade := unit.create_tween()
		fade.tween_interval(unit.action_length("death"))
		fade.tween_property(unit, "modulate:a", 0.0, 0.35)
		fade.tween_callback(func() -> void: unit.visible = false)


## Mourner's Haste: whoever goes down, their friends who carry it get every
## skill back at once.
func _mourn(f: Fighter) -> void:
	for other in fighters:
		if other == f or not other.is_standing() or other.unit.is_hostile_to(f.unit):
			continue
		if not other.has_effect("reset_on_ally_down"):
			continue
		for i in other.cooldowns.size():
			other.cooldowns[i] = 0.0
		fx.popup("Mourner's Haste", other.unit.position, SkirmishFx.GRACE, 13)
		_say("%s answers %s's fall: every skill is ready again." % [other.unit.display_name, f.unit.display_name])


## The near-death window has run out with nobody there. In a fight the world
## started this is the fall, settled for real ([method _settle_fallen]); in a
## sandbox fight the graces get a roll with nothing written back, and if none
## lands the fighter is out of it.
func _window_ran_out(f: Fighter) -> void:
	if sandbox or f.unit.character == null:
		if not _grace(f):
			_fall(f)
		return
	_settle_fallen(f)


## A sandbox fall: the same graces [Fate] rolls — a charm carried, a companion
## standing, a book read, the ground — through [method Fate.roll], with nothing
## written back: a training fight spends no charm and takes no prisoners.
## Returns true if one landed and the fighter is back up.
func _grace(f: Fighter) -> bool:
	var who := f.unit.character
	if who == null:
		return false
	var grace := Fate.roll(who, grace_context(f), grace_rng, false)
	if grace.is_empty():
		return false
	_stand_back_up(f, str(grace["reason"]))
	_say(Fate.escape_line(who, grace))
	return true


## A party member's fall in a fight the world started, settled as the turn-based
## battle settled it: [method Fate.resolve] rolls the graces and applies what
## lands (a charm is spent, a prisoner taken), [signal EventBus.character_fell]
## is told, and the dead get a memorial and the threads' notice. Saved by a
## grace, they are back on their feet in the fight; pulled clear, taken or dead,
## they are out of it, and what [Fate] wrote stands ([D65]).
func _settle_fallen(f: Fighter) -> void:
	var who := f.unit.character
	var context := grace_context(f)
	context["enemy_kind"] = _killer_kind()
	var outcome := Fate.resolve(who, context, GameState.world.rng)
	_say(str(outcome["line"]))
	EventBus.character_fell.emit(who, outcome)
	var reason := str(outcome.get("reason", ""))
	if outcome["outcome"] == Fate.ALIVE and GRACE_WORDS.has(reason) and not over:
		_stand_back_up(f, reason)
		return
	f.settled = outcome
	_fall(f, false)
	if outcome["outcome"] == Fate.DEAD:
		Memorial.raise(GameState.world, who, GameState.world.player_cell, _killer_kind())
		for line: String in Skein.on_character_fell(GameState.world, who.template_id):
			_say(line)


## Off the ground with what a grace gives back (`escape_recovery` of their health).
func _stand_back_up(f: Fighter, reason: String) -> void:
	f.near_death = 0.0
	f.graces += 1
	f.unit.hp = maxi(1, roundi(float(f.unit.max_hp) * float(Database.fate.get("escape_recovery", 0.25))))
	f.unit.modulate = Color.WHITE
	f.unit.stand()
	f.attack_timer = 1.0
	f.since_hit = 0.0
	fx.ring(f.unit.position, SkirmishFx.GRACE, 60.0)
	fx.popup(GRACE_WORDS.get(reason, "Grace"), f.unit.position, SkirmishFx.GRACE, 18, 1.8)


## Back up on their own, as Caesar does once a fight (his signature).
func _get_up(f: Fighter) -> void:
	f.near_death = 0.0
	f.unit.hp = maxi(1, roundi(float(f.unit.max_hp) * signatures.rise_health(f)))
	f.unit.modulate = Color.WHITE
	f.unit.stand()
	f.attack_timer = 1.0
	f.since_hit = 0.0
	fx.ring(f.unit.position, SkirmishFx.GRACE, 60.0)
	fx.popup("Back on his feet!", f.unit.position, SkirmishFx.GRACE, 16, 1.6)
	_say("%s gets back up." % f.unit.display_name)


## What [Fate] needs to know about a downed fighter: who is still standing with
## them, and where in the world the fight is.
func grace_context(f: Fighter) -> Dictionary:
	var allies: Array = []
	for other in fighters:
		if other != f and other.is_party() and other.is_standing() and other.unit.character != null:
			allies.append(other.unit.character)
	var context := {"allies": allies}
	if GameState.world != null:
		context["world"] = GameState.world
		context["cell"] = GameState.world.player_cell
	return context


## The chance a grace saves [param f] if nobody reaches them, for the card.
func grace_odds(f: Fighter) -> float:
	if f.unit.character == null:
		return 0.0
	return Fate.odds(f.unit.character, grace_context(f))


## What kind of thing is winning the fight, which decides whether prisoners are taken.
func _killer_kind() -> String:
	for f in fighters:
		if not f.unit.sides_with_party() and f.is_standing():
			return f.unit.kind()
	return "default"


## Stop the clock on the player's behalf. Tests drive the fight themselves and
## are never stopped, and nor is a party playing itself.
func _auto_pause(why: String) -> void:
	if manual or over or paused or Pace.auto:
		return
	paused = true
	_accumulator = 0.0
	_say("Paused. %s" % why if why != "" else "Paused.")


func _fall(f: Fighter, say_so: bool = true) -> void:
	f.near_death = 0.0
	f.fallen = true
	f.unit.modulate = Color(0.35, 0.35, 0.4, 0.55)
	if say_so:
		_say("Nobody reached %s in time." % f.unit.display_name)


func _check_end() -> void:
	var party_up := fighters.any(func(f: Fighter) -> bool: return f.is_party() and f.is_standing())
	var foes_up := fighters.any(func(f: Fighter) -> bool:
		return not f.unit.sides_with_party() and f.is_standing())
	if party_up and foes_up and not _objective_met():
		return
	if party_up and foes_up:
		_say(_objective_won_line())
	over = true
	victory = party_up
	# The last of them walked off the edge: whoever is still lying on the field is left to it.
	fled_field = not party_up and fighters.any(func(f: Fighter) -> bool: return f.is_party() and f.fled)
	armed_slot = -1
	overlay.clear()
	for f in fighters:
		f.unit.set_running(false)
		f.cast = {}
	if fled_field:
		_say("The company gets clear after %.0f seconds." % sim_time)
	else:
		_say("The field is yours after %.0f seconds." % sim_time if victory \
				else "The company is down after %.0f seconds." % sim_time)
	hud.show_result(victory, fled_field)
	EventBus.player_did.emit("fight_won" if victory else "fight_lost")
	Sfx.cue("victory" if victory else "defeat")
	if sandbox:
		# The coliseum carries its wounds between rounds; the training ground
		# does not. Either way nothing is written back onto the world.
		if bool(boot_payload.get("heal", true)):
			GameState.heal_party()
		else:
			_carry_wounds()
		GameState.set_flag(Arena.VICTORY_FLAG, victory)
	else:
		_settle_the_party()
		if victory:
			GameState.mark_battle_cleared(map_id)
		GameState.set_flag("last_victory", victory)
		GameState.set_flag("last_fled", fled_field)
		EventBus.battle_finished.emit({"victory": victory, "map_id": map_id})
	finished.emit(victory)
	if not manual:
		_leave_the_field()


## Whether the floor is won before the last enemy is down.
func _objective_met() -> bool:
	match objective:
		Site.OBJECTIVE_GUARDIAN:
			var keepers := fighters.filter(func(f: Fighter) -> bool:
				return not f.unit.sides_with_party() and f.unit.has_meta("boss"))
			return not keepers.is_empty() and not keepers.any(func(f: Fighter) -> bool: return f.is_standing())
		Site.OBJECTIVE_HEART:
			return fighters.any(func(f: Fighter) -> bool:
				return f.is_party() and f.is_standing() and f.unit.cell == heart_cell)
	return false


func _objective_won_line() -> String:
	if objective == Site.OBJECTIVE_HEART:
		return "The heart is reached, and the floor gives way beneath the rest of them."
	return "The keeper is down. What came with it breaks and scatters."


## A party member's health in the fight as a share of the fight's maximum, which
## is `HEALTH_SCALE` times their own.
func _share_left(f: Fighter) -> float:
	return float(maxi(0, f.unit.hp)) / float(maxi(1, f.unit.max_hp))


## Wounds only. Used on the sand, where nobody rolls for their life because
## nobody is really dying.
func _carry_wounds() -> void:
	for f in party_fighters():
		var who := f.unit.character
		if who == null:
			continue
		who.hp = clampi(roundi(_share_left(f) * float(who.max_hp())), 0, who.max_hp())


## Write the fight back onto the people who fought it. Those still standing, and
## any still down when the field was won — carried off by the rest ([D65]) —
## keep their wounds as a share; anyone the company could not reach once it was
## beaten falls for real; whoever [Fate] has already settled is left as it said.
func _settle_the_party() -> void:
	for f in party_fighters():
		var who := f.unit.character
		if who == null or not f.settled.is_empty():
			continue
		if f.is_downed() and not victory:
			_settle_fallen(f)
			continue
		if f.is_downed():
			_say("%s is carried off the field." % f.unit.display_name)
			f.near_death = 0.0
		# Wounds carry as a fraction, so a difficulty that made the party
		# hardier does not write an impossible number back onto them.
		var carried := _share_left(f)
		if Difficulty.post_battle_heal_ratio() > 0.0:
			carried = maxf(carried, Difficulty.post_battle_heal_ratio())
		who.hp = clampi(roundi(carried * float(who.max_hp())), 1, who.max_hp())
		Doctrine.reinforce_all(who, GameState.world.steps)
	GameState.roster.drop_the_lost()


func _leave_the_field() -> void:
	await get_tree().create_timer(END_SCREEN_DELAY if not in_place else IN_PLACE_DELAY, true, false, true).timeout
	if in_place:
		gone.emit()
		return
	EventBus.request_scene.emit(str(boot_payload.get("return_scene", "world")),
			boot_payload.get("return_payload", {}))


# --- orders ------------------------------------------------------------------


func order_move(f: Fighter, cell: Vector2i) -> void:
	f.give(Fighter.Order.MOVE, cell)


func order_attack(f: Fighter, foe: Unit) -> void:
	f.give(Fighter.Order.ATTACK, foe.cell, foe)


func order_cast(f: Fighter, slot: int, who: Unit, cell: Vector2i) -> void:
	f.give(Fighter.Order.CAST, cell, who, slot)


func order_aid(f: Fighter, patient: Unit) -> void:
	f.give(Fighter.Order.AID, patient.cell, patient)


## Sent off the field (an order beyond its edge): everyone selected makes for the edge nearest
## [param beyond], and gets clear when they stand on it ([method _see_who_got_clear]).
func _make_for_the_edge(beyond: Vector2i) -> void:
	if selected.is_empty():
		return
	var edge := beyond.clamp(Vector2i.ZERO, Vector2i(grid.width - 1, grid.height - 1))
	var taken: Array[Vector2i] = []
	for f in selected:
		var spot := _free_cell_near(edge, taken, f)
		if not _on_the_edge(spot):
			spot = edge
		taken.append(spot)
		f.set_meta("fleeing", true)
		order_move(f, spot)
	_say("Making for the edge of the field." if selected.size() > 1 else "%s makes for the edge of the field." % selected[0].unit.display_name)


func _on_the_edge(cell: Vector2i) -> bool:
	return cell.x == 0 or cell.y == 0 or cell.x == grid.width - 1 or cell.y == grid.height - 1


## Whoever was sent off the field and has reached its edge is out of the fight, alive, with
## whatever carries them, rides them or is bound to them (a mount, a wolf, a shade).
func _see_who_got_clear() -> void:
	for f in party_fighters():
		var mount := f.aboard as Fighter
		var moving := f.stepping or (mount != null and mount.stepping)
		if not f.has_meta("fleeing") or not f.is_standing() or moving or not _on_the_edge(f.unit.cell):
			continue
		for other in fighters:
			if other == f or other == mount or other.aboard == f or other.bound_to == f:
				other.fled = true
				other.unit.visible = false
				selected.erase(other)
		_say("%s gets clear." % f.unit.display_name)


## Send everyone selected to [param cell], each to their own tile around it.
func _order_group_move(cell: Vector2i) -> void:
	var taken: Array[Vector2i] = []
	for f in selected:
		var spot := _free_cell_near(cell, taken, f)
		taken.append(spot)
		order_move(f, spot)


func _free_cell_near(cell: Vector2i, taken: Array[Vector2i], mover: Fighter) -> Vector2i:
	for radius in range(0, 4):
		for candidate in pathfinder.cells_in_range(cell, radius, radius):
			if grid.is_walkable(candidate) and not taken.has(candidate) \
					and (occupant(candidate, mover) == null):
				return candidate
	return cell


# --- input -------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	# Handed over, the party is taken back with the same key that handed it
	# over (Q on a keyboard), here as on the road. That key readies the first
	# skill otherwise, so a fight met while the game played itself could not
	# be taken back until it was over.
	if Pace.auto and not (event is InputEventMouse) and event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		Pace.auto = false
		# Paused, as a fight played by hand opens, so the first order can be
		# given before anything else happens.
		set_paused(true)
		_say("You take the party back.")
		return
	# Back, from a key, a pad or the touch bar's button: a readied skill is put
	# away, and with nothing readied it is the menu.
	if not (event is InputEventMouse) and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if armed_slot >= 0:
			_disarm()
		else:
			EventBus.system_menu_requested.emit()
		return
	if event is InputEventJoypadButton and event.pressed:
		if _on_pad(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if _on_key(event):
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion:
		var cell := _mouse_cell()
		overlay.set_cursor(cell)
		hud.inspect(fighter_of(_unit_at_or_downed(cell)))
		if _press_at != Vector2.INF:
			var here := to_local(get_global_mouse_position())
			if not drag_box.has_area() and _press_at.distance_to(here) < SkirmishRules.DRAG_SELECT_MIN:
				return
			drag_box = Rect2(_press_at, Vector2.ZERO).expand(here)
			if not drag_box.has_area():
				drag_box.size = Vector2(1, 1)
			marks.queue_redraw()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		# A thumb drags the camera, not a box: on touch a tap is the whole order.
		if touch:
			if event.pressed:
				_on_left_click(_mouse_cell(), event.shift_pressed)
			return
		if event.pressed:
			_press_at = to_local(get_global_mouse_position())
			return
		var start := _press_at
		_press_at = Vector2.INF
		if start == Vector2.INF:
			return
		if drag_box.has_area():
			box_select(drag_box, event.shift_pressed)
			drag_box = Rect2()
			marks.queue_redraw()
		else:
			_on_left_click(grid.world_to_cell(start), event.shift_pressed)
		return
	if event is InputEventMouseButton and event.pressed:
		var cell := _mouse_cell()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_on_right_click(cell)
			get_viewport().set_input_as_handled()


## Keys, said as the actions the touch buttons also send.
## Pause and speed are the rebindable actions (`command_wait`, `battle_speed`).
const KEY_ACTIONS := {
	KEY_Z: "auto_pause", KEY_TAB: "all", KEY_A: "auto_skill", KEY_H: "hold",
}


func _on_key(event: InputEventKey) -> bool:
	var slot := SkirmishRules.SLOT_KEYS.find(event.keycode)
	if slot >= 0:
		act("slot%d" % slot)
		return true
	if event.is_action_pressed("command_wait"):
		act("pause")
		return true
	if event.is_action_pressed("battle_speed"):
		act("speed")
		return true
	if KEY_ACTIONS.has(event.keycode):
		act(KEY_ACTIONS[event.keycode])
		return true
	# On the ground the fight shows no keys; How to Play has them all.
	if in_place and event.keycode == KEY_K:
		EventBus.how_to_play_requested.emit()
		return true
	# The journal is most wanted while you are stood across from the thing it
	# is about, so it opens here as well as on the road.
	if event.keycode == KEY_N:
		EventBus.journal_requested.emit()
		return true
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var party := party_fighters()
		var index := event.keycode - KEY_1
		if index < party.size() and party[index].is_standing():
			if event.shift_pressed:
				_select(selected + [party[index]])
			else:
				_select([party[index]])
		return true
	return false


## A pad's buttons, said as the same orders the keys and clicks give. The
## menu (Start) is the game's own; everything else is here.
func _on_pad(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_pad_confirm()
		return true
	if event.is_action_pressed("command_wait"):
		act("pause")
		return true
	if event.is_action_pressed("open_actions"):
		_pad_next_skill()
		hud.refresh()
		return true
	if event.is_action_pressed("cycle_next"):
		_pad_next_fighter()
		return true
	if event.is_action_pressed("battle_speed"):
		act("speed")
		return true
	if event.is_action_pressed("open_party"):
		act("all")
		return true
	return false


## A: what a click would have done at the cursor. A skill aimed at its own
## caster goes off at once; anything else armed is aimed at the cursor; a
## party member under it is picked; anywhere else is an order.
func _pad_confirm() -> void:
	if not grid.in_bounds(pad_cell):
		return
	if armed_slot >= 0 and not selected.is_empty():
		var caster := selected[0]
		if str(caster.slot_ability(armed_slot).get("target", "enemy")) == "self":
			order_cast(caster, armed_slot, caster.unit, caster.unit.cell)
			_disarm()
		else:
			_on_left_click(pad_cell, false)
		return
	var under := fighter_of(_unit_at(pad_cell))
	if under != null and under.is_party() and under.is_standing():
		_select([under])
		return
	_on_right_click(pad_cell)


## Y: the first picked fighter's next skill, and past the last, none. Unlike
## the keys, a skill aimed at its own caster is only armed here; A sends it.
func _pad_next_skill() -> void:
	if selected.is_empty():
		return
	var caster := selected[0]
	var slot := armed_slot + 1
	if slot >= caster.slots.size():
		_disarm()
		return
	armed_slot = slot
	var ability := caster.slot_ability(slot)
	overlay.clear()
	overlay.action_cells = pathfinder.cells_in_range(
		caster.unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()
	_say("%s readies %s." % [caster.unit.display_name, ability.get("display_name", "?")])


## RB: the next standing party member, alone, with the cursor on them.
func _pad_next_fighter() -> void:
	var standing := party_fighters().filter(func(f: Fighter) -> bool: return f.is_standing())
	if standing.is_empty():
		return
	var at := standing.find(selected[0]) if not selected.is_empty() else -1
	var next: Fighter = standing[posmod(at + 1, standing.size())]
	_select([next])
	_aim_at(next.unit.cell)


func _steer_pad_cursor(delta: float) -> void:
	if not Pad.using_pad or over or Pad.focus_root() != null:
		_pad_held = Vector2i.ZERO
		return
	if not grid.in_bounds(pad_cell):
		var party := party_fighters()
		if not party.is_empty():
			_aim_at(selected[0].unit.cell if not selected.is_empty() else party[0].unit.cell)
	var direction := Vector2i(
		int(Input.is_action_pressed("move_right")) - int(Input.is_action_pressed("move_left")),
		int(Input.is_action_pressed("move_down")) - int(Input.is_action_pressed("move_up"))
	)
	if direction == Vector2i.ZERO:
		_pad_held = Vector2i.ZERO
		return
	if direction != _pad_held:
		_pad_held = direction
		_pad_repeat = PAD_FIRST_REPEAT
		_nudge_cursor(direction)
		return
	_pad_repeat -= delta / maxf(Engine.time_scale, 0.01)
	if _pad_repeat <= 0.0:
		_pad_repeat = PAD_REPEAT
		_nudge_cursor(direction)


func _nudge_cursor(direction: Vector2i) -> void:
	var next := pad_cell + direction
	if not grid.in_bounds(next):
		next = pad_cell + Vector2i(direction.x, 0)
	if not grid.in_bounds(next):
		next = pad_cell + Vector2i(0, direction.y)
	if grid.in_bounds(next):
		_aim_at(next)


func _aim_at(cell: Vector2i) -> void:
	pad_cell = cell
	overlay.set_cursor(cell)
	if not in_place:
		camera.focus_on(grid.cell_to_world(cell))


## The cell under the pointer, wherever on the ground this scene has been put down.
func _mouse_cell() -> Vector2i:
	return grid.world_to_cell(to_local(get_global_mouse_position()))


## One thing the player asked for, by name, from a key or a touch button.
func act(action: String) -> void:
	if action.begins_with("slot"):
		_arm(int(action.trim_prefix("slot")))
		hud.refresh()
		return
	match action:
		"pause":
			set_paused(not paused)
			_say("Paused." if paused else "")
		"speed":
			Pace.cycle_speed()
		"auto_pause":
			auto_pause = ((int(auto_pause) + 1) % AutoPause.size()) as AutoPause
			_say("Auto-pause: %s." % AUTO_PAUSE_LABELS[auto_pause])
		"all":
			_select(party_fighters().filter(func(f: Fighter) -> bool: return f.is_standing()))
		"auto_skill":
			for f in selected:
				f.auto_skill = not f.auto_skill
		"hold":
			for f in selected:
				f.hold = not f.hold
				if f.hold and f.order == Fighter.Order.NONE:
					f.target = null
	hud.refresh()


func _on_left_click(cell: Vector2i, adding: bool) -> void:
	var who := _unit_at(cell)
	if armed_slot >= 0 and not selected.is_empty():
		var caster := selected[0]
		var ability := caster.slot_ability(armed_slot)
		var aimed_at_someone := who != null and AbilityResolver.is_valid_target(caster.unit, ability, who)
		var aimed_at_ground := who == null and int(ability.get("splash", 0)) > 0 and grid.in_bounds(cell)
		if aimed_at_someone or aimed_at_ground:
			order_cast(caster, armed_slot, who if aimed_at_someone else null, cell)
			_disarm()
		return
	var clicked := signatures.rider_of(fighter_of(who))
	if clicked != null and clicked.is_party() and clicked.is_standing():
		_select(selected + [clicked] if adding else [clicked])
		return
	# No right button under a thumb: a tap on anything else is the order.
	if touch:
		_on_right_click(cell)


## Pick every standing companion the box touches, as an RTS does. A box that
## catches nobody leaves the pick as it was, so a slipped click costs nothing.
## [param box] is in the field's own space; [param adding] keeps who was picked.
func box_select(box: Rect2, adding: bool) -> void:
	var half := Vector2.ONE * BattleGrid.CELL_SIZE * 0.5
	var caught: Array[Fighter] = []
	for f: Fighter in party_fighters():
		if f.is_standing() and box.intersects(Rect2(units_root.position + f.unit.position - half, half * 2.0)):
			caught.append(f)
	if caught.is_empty():
		return
	_select(selected + caught if adding else caught)
	hud.refresh()


func _on_right_click(cell: Vector2i) -> void:
	if armed_slot >= 0:
		_disarm()
		return
	if selected.is_empty():
		return
	for f in selected:
		f.remove_meta("fleeing")
	if in_place and not grid.in_bounds(cell):
		_make_for_the_edge(cell)
		return
	var who := _unit_at_or_downed(cell)
	var clicked := fighter_of(who)
	if clicked != null and not clicked.is_party() and clicked.is_standing():
		for f in selected:
			order_attack(f, clicked.unit)
		return
	if clicked != null and clicked.is_party() and clicked.is_downed():
		order_aid(_nearest_of(selected, cell), clicked.unit)
		return
	if grid.is_walkable(cell):
		_order_group_move(cell)


func _on_card_clicked(index: int) -> void:
	var party := party_fighters()
	if index < party.size() and party[index].is_standing():
		_select([party[index]])


## A draught or herb on a card: whoever the card belongs to uses it.
func _on_item_clicked(index: int, item_id: String) -> void:
	var party := party_fighters()
	if index < party.size():
		use_item(party[index], item_id)


## A skill tile on a card: pick whoever it belongs to and ready it.
func _on_slot_clicked(index: int, slot: int) -> void:
	var party := party_fighters()
	if index >= party.size() or not party[index].is_standing():
		return
	if selected.is_empty() or selected[0] != party[index]:
		_select([party[index]])
	_arm(slot)
	hud.refresh()


func _arm(slot: int) -> void:
	if selected.is_empty():
		return
	# The same skill asked for twice is changing your mind.
	if armed_slot == slot:
		_disarm()
		return
	var caster := selected[0]
	if slot >= caster.slots.size():
		return
	var ability := caster.slot_ability(slot)
	if not caster.can_afford(slot):
		_say("%s is too tired for %s." % [caster.unit.display_name, ability.get("display_name", "that")])
		return
	if str(ability.get("target", "enemy")) == "self":
		order_cast(caster, slot, caster.unit, caster.unit.cell)
		return
	armed_slot = slot
	overlay.clear()
	overlay.action_cells = pathfinder.cells_in_range(
		caster.unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()


func _disarm() -> void:
	armed_slot = -1
	overlay.clear()


func _select(group: Array) -> void:
	var clean: Array[Fighter] = []
	for f: Fighter in group:
		if f != null and f.is_party() and f.is_standing() and not clean.has(f):
			clean.append(f)
	selected = clean
	if armed_slot >= 0:
		_disarm()


# --- queries -----------------------------------------------------------------


func party_fighters() -> Array[Fighter]:
	return fighters.filter(func(f: Fighter) -> bool: return f.is_party())


func fighter_of(unit: Unit) -> Fighter:
	if unit == null:
		return null
	for f in fighters:
		if f.unit == unit:
			return f
	return null


func is_standing(unit: Unit) -> bool:
	var f := fighter_of(unit)
	return f != null and f.is_standing()


## Whoever is on, or stepping onto, [param cell] — standing or downed, but not
## the fallen — other than [param besides].
func occupant(cell: Vector2i, besides: Fighter = null) -> Fighter:
	for f in fighters:
		if f != besides and not f.fallen and not f.fled and f.aboard == null and f.unit.cell == cell:
			return f
	return null


func _unit_at(cell: Vector2i) -> Unit:
	for f in fighters:
		if f.targetable() and f.unit.cell == cell:
			return f.unit
	return null


func _unit_at_or_downed(cell: Vector2i) -> Unit:
	var f := occupant(cell)
	return f.unit if f != null else null


func _basic_reach(f: Fighter) -> int:
	return int(Database.ability(f.basic).get("range", 1))


func _nearest_of(group: Array[Fighter], cell: Vector2i) -> Fighter:
	var best: Fighter = group[0]
	for f in group:
		if Pathfinder.distance(f.unit.cell, cell) < Pathfinder.distance(best.unit.cell, cell):
			best = f
	return best


## Every number that pops off a unit in this fight comes through here, whatever
## dealt it, so nothing is missed and nothing is counted twice.
func _on_unit_damaged(unit: Node, amount: int) -> void:
	var f := fighter_of(unit as Unit)
	if f == null or amount <= 0:
		return
	f.since_hit = 0.0
	fx.flash(f.unit)
	if f.unit.is_alive():
		f.unit.play("hit")
	var at := f.unit.position
	match _hit_style:
		"crit":
			fx.popup("%d!" % amount, at, SkirmishFx.CRIT, 26, 1.1)
			fx.popup("CRITICAL", at + Vector2(0, -20), SkirmishFx.CRIT, 13, 1.0)
		"thorns":
			fx.popup(str(amount), at, SkirmishFx.THORNS, 16)
		_:
			fx.popup(str(amount), at, SkirmishFx.HURT if f.is_party() else SkirmishFx.DAMAGE, 18)


func _on_unit_healed(unit: Node, amount: int) -> void:
	var f := fighter_of(unit as Unit)
	if f == null or amount <= 0:
		return
	fx.popup("+%d" % amount, f.unit.position, SkirmishFx.HEAL, 15)


## A level gained mid-fight shows on whoever gained it: a gold flicker, a
## ring, and the level rising off them. The rest is said at the side of the
## screen, out of the way ([D77]).
func _on_levelled_up(who: RefCounted, _before: Dictionary) -> void:
	var character := who as Character
	if character == null:
		return
	for f in fighters:
		if f.unit.character == character:
			fx.gold(f.unit)
			fx.ring(f.unit.position, SkirmishFx.CRIT, 34.0)
			fx.popup("Level %d" % character.level, f.unit.position + Vector2(0, -10), SkirmishFx.CRIT, 15, 1.4)
			return


func _say(line: String) -> void:
	if line == "":
		return
	hud.log_line(line)
	EventBus.battle_log.emit(line)


func _to_cell(value: Variant) -> Vector2i:
	var pair: Array = value
	return Vector2i(int(pair[0]), int(pair[1]))
