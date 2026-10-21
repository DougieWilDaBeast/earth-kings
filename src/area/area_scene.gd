extends Node2D
## Area mode: a place drawn from tilesets, seen from above, with the party
## walking around inside it.
##
## The leader answers the movement keys; everyone else walks the ground the
## leader has already covered. Leaving by the road hands play back to whatever
## scene sent us here.
##
## This is where the game is played ([D50], [D61]). Walking off the edge of the
## ground hands the step to the continent, which does everything a step does
## out of sight and hands back the next ground. A place's own doings (hire, buy,
## the board, a ransom) are sent the same way and come straight back here.
##
## On the land (`"land": true`, [D84]) there is no edge to walk off: the tiles round the party are
## laid side by side as one stretch of ground ([Land]), places standing in them. Crossing from one
## tile into the next is the step; the continent takes it out of sight
## ([signal EventBus.continent_requested]) while the party walks on, the tiles ahead are laid out
## a frame at a time and the ones far behind are let go.

const Formations := preload("res://src/skirmish/formations.gd")
const Guild := preload("res://src/chronicle/guild.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Atlas := preload("res://src/chronicle/atlas.gd")
const Talk := preload("res://src/dialogue/talk.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")
const GroundPainter := preload("res://src/area/ground_painter.gd")
const AreaLedges := preload("res://src/area/area_ledges.gd")
const AreaClouds := preload("res://src/area/area_clouds.gd")
const Wilds := preload("res://src/chronicle/wilds.gd")
const InteriorPainter := preload("res://src/area/interior_painter.gd")
const AreaWatch := preload("res://src/area/area_watch.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const Land := preload("res://src/area/land.gd")
const GroundGen := preload("res://src/area/ground_gen.gd")
const AreaCritter := preload("res://src/area/area_critter.gd")
const AreaWaymark := preload("res://src/area/area_waymark.gd")
const Compass := preload("res://src/ui/compass.gd")
const PlayHud := preload("res://src/ui/play_hud.gd")
const LandMap := preload("res://src/ui/land_map.gd")
const LandMapScreen := preload("res://src/ui/land_map_screen.gd")
const AreaSpire := preload("res://src/area/area_spire.gd")
const FarTower := preload("res://src/ui/far_tower.gd")
const TowerFloors := preload("res://src/chronicle/tower_floors.gd")
const Memories := preload("res://src/chronicle/memories.gd")
const LandJournals := preload("res://src/chronicle/land_journals.gd")
const Remembered := preload("res://src/chronicle/remembered.gd")
const Arcs := preload("res://src/chronicle/arcs.gd")
const GateInside := preload("res://src/chronicle/gate_inside.gd")
const Climbers := preload("res://src/chronicle/climbers.gd")
const Recruits := preload("res://src/chronicle/recruits.gd")
const Caves := preload("res://src/chronicle/caves.gd")
## The corner map's side and the size of a cell on it, in pixels ([D232]): fifteen cells across.
const CORNER_MAP_SIZE := 180.0
const CORNER_MAP_CELL := 12.0
## How often the compass asks where the objective is, in seconds.
const COMPASS_EVERY := 0.25
const AutoRoad := preload("res://src/world/auto_road.gd")
## The fight, put down on this ground when a band is met ([method _fight_here]).
const SKIRMISH := preload("res://src/skirmish/skirmish.tscn")
const Coins := preload("res://src/chronicle/coins.gd")

const WALK_SPEED := 190.0
## How long laying out the land ahead may take in one frame, in milliseconds, and how near a tile's
## edge the party walks before the tiles beyond the next are worked out ([D178]).
const LAND_BUDGET_MS := 5.0
const LAND_WARM_CELLS := 12
## Breadcrumb trail recording spacing and following parameters.
const CRUMB_SPACING := 6.0
const FOLLOWER_DISTANCE := 24.0
## How close counts as arrived. Without it followers twitch on the spot, and
## re-face themselves off sub-pixel deltas, which reads as the sprite flickering.
const FOLLOW_DEADZONE := 2.0
## How close the leader has to stand before somebody is worth speaking to.
const TALK_RANGE := 110.0
## How near a way in (the Tower's door, D107) has to be for it to win the prompt over anybody
## standing about: two cells, so "E to climb" is up before you reach the steps (meeting 3).
const DOOR_RANGE := 160.0
## How close the leader walks before starting on somebody they were clicked at.
const APPROACH_RANGE := 88.0
## How far the party walks between chances of somebody saying something.
const TALK_STRIDE := 700.0
const HINT := "WASD to walk  ·  click anyone or anything marked to speak to it or look at it  ·  Tab to take the lead with someone else  ·  P for the party  ·  doors open as you reach them  ·  follow the road out to leave"

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}

@onready var _layers: Node2D = $Layers
@onready var _actors: Node2D = $Actors
@onready var _camera: CameraRig = $Camera2D
@onready var _place: Label = %PlaceLabel
@onready var _hint: Label = %HintLabel
@onready var _log: Label = %LogLabel

var map: AreaMap
var _leader: AreaActor
var _followers: Array[AreaActor] = []
## Everybody who lives here, in the order they were put down; each knows its entry in
## `map.people` (meta `person`).
var _people: Array[AreaActor] = []
## Everything standing about that is worth stopping to look at.
var _things: Array[AreaProp] = []
## Party member per seated person, by their actor (by index into `map.people` until they are made).
var _seated: Dictionary = {}
var _seat_for: Dictionary = {}
## Whoever is walking, as the roster knows them.
var _leader_character: Character
## Whoever is speaking from afar, standing beside the lead as a ghost of themselves while they talk.
var _ghost: AreaActor = null
## Auto stopped for this fight (D150), and takes the walk back up if it is won.
var _auto_after_fight := false
## Who or what the leader is standing close enough to deal with, or null.
var _nearby: AreaThing = null
## What the mouse is over, and what the leader was told to walk over to.
var _hovered: AreaThing = null
var _approach: AreaThing = null
var _approach_path: Array[Vector2] = []
## Where the leader is walking to after a click on open ground, the next point first.
var _click_path: Array[Vector2] = []
## The pin where a click sent the party, and the line to it ([D189]).
var _waymark: Node2D
## An inn's room paid for here ([D242]): the pin and dotted line to its bed, and the words over it.
var _room_mark: Node2D
var _room_label: Label
var _room_clock := 0.0
## The small panel of the company's health and the purse ([D244]).
var _play_hud: Control
var _approach_index: int = 0
var _auto_exit_path: Array[Vector2] = []
var _auto_exit_index: int = 0
## The way to a band's red that a party walking itself is making for, and where along it ([D215]).
var _auto_band_path: Array = []
var _auto_band_index: int = 0
var _auto_band_target := Vector2i(-1, -1)
## When a party walking itself passively may next work its way out again round a band (ms).
var _auto_reroute_at: int = 0
## On the land: the tile the party is walking itself into, and the tile it set off from ([D94]).
var _auto_tile: Vector2i = Vector2i(-1, -1)
var _auto_from: Vector2i = Vector2i(-1, -1)
## The way across the Tower's tile to its door, for a party walking itself there ([D197]), and
## whether it has already stopped at the door once: asked on again from there, it goes in.
var _auto_door_path: Array[Vector2] = []
var _auto_door_index: int = 0
var _auto_at_door := false
## Frames Auto has walked without moving; at [constant AUTO_BLOCKED_FRAMES] its way is worked out again.
var _auto_blocked: int = 0
const AUTO_BLOCKED_FRAMES := 45
var _talking: bool = false
## Held while it plays; a director that only exists as a temporary is collected
## the moment it finishes and never hands control back.
var _cutscene: AreaCutscene
var _crumbs: Array[Vector2] = []
## How far the leader has walked since the last time anybody spoke up.
var _walked: float = 0.0
## How far the leader has walked since the area opened, until it is far enough to call walking.
var _strolled: float = 0.0
## The needle pointing at the First Hour's objective (D95), top left under the place's name.
var _compass: Control
## The map in the top right corner while walking the land, and the large one over the ground
## (M or the journal), which the party walks on under ([D232]).
var _corner_map: Control
var _map_screen: CanvasLayer
## The Tower on the edge of the screen while it is far off (D108), on the land only.
var _far_tower: Control
var _compass_clock := COMPASS_EVERY
## Notes that came while a box was open, for when it closes.
var _held_notes: Array[String] = []
## Held while an exchange is playing over their heads.
var _chatting: bool = false
var _notes: Array[String] = []
var _note_times: Array[int] = []
var _hint_backed := true
## The hint line its strip was last fitted to, so it is measured only when it changes.
var _hint_fitted := ""
var _visited_spots: Dictionary = {}
## cell -> the [AreaProp] drawn for the chest there, so it can be shown opened.
var _chest_props: Dictionary = {}
## cell -> the [AreaProp] drawn for the ward obstacle there.
var _ward_props: Dictionary = {}
## Wards already leaned on and refused, so the refusal is said once.
var _shut_wards: Dictionary = {}
var _return_scene: String = "world"
## What the bottom of the screen falls back to when nobody is near.
var _idle_hint: String = HINT
## What the scene we came from needs to put itself back the way it was.
var _return_payload: Dictionary = {}
var _leaving: bool = false
var _planar_mode: bool = false
## What the continent says can be done where the party stands, for the hint
## line, the keys and the buttons: `{ prompt, label, act, key }`.
var _acts: Array = []
## Whatever was waiting on the tile above, carried there and back unchanged.
var _held: Dictionary = {}
## The buttons for [member _acts], for a thumb or a pad. Built in code.
var _act_bar: HFlowContainer = null
## What the land does to whoever walks this ground (see [method Biome.effects]);
## the neutral one for a place that is not open country.
var _land: Dictionary = {}
## How far the party has walked since the land last had its say.
var _weathered: float = 0.0
## Party members the land has already been said to be wearing down, so it is
## said once a ground.
var _told_of: Dictionary = {}
## Bands standing on this ground: `{ data, actors, watch, at }`, where `watch`
## Bands standing on this ground, and the ground they watch ([AreaWatch], D66, D68).
var _watches: Array = []
## The cell the leader last stood on, so a step into a watched cell is a step, not where they
## were put down; (-99, -99) until they have been anywhere.
var _last_cell: Vector2i = Vector2i(-99, -99)
## Seen, and on the way to the fight.
var _spotted: bool = false
## The fight going on on this ground, if there is one; the band's watch it came from.
var _fight: Node2D = null
var _fight_watch: Node2D = null
## The Watch off the road fighting beside the party just now (D236), out of their walk until it ends.
var _watch_fighting: Array[AreaActor] = []
## A band's fight has been asked of the continent and not yet put down.
var _awaiting_fight: bool = false
## The lead is winding up a first strike on a band ([D300]); the next fight put down opens with it.
var _winding_up: bool = false
var _striking_first: bool = false
## The place's doings that start a fight, fought on this ground rather than on a screen of its own.
const FIGHT_ACTS := ["_enter_gate_here"]
## Doings that start a fight, fought here on this ground with no screen of its own ([D207]): the
## gate's at its doorway (D162), a roadside fight where its scene is staged, and the rest just ahead
## of the party. Only a gate is gone into by a party walking itself ([const FIGHT_ACTS]).
const GROUND_FIGHT_ACTS := ["_enter_gate_here", "_step_into_the_road", "_defend_here", "_raid_here", "_fight_for_captive"]
## How far, in cells, the party may stand from a gate's doorway for its keepers to come out of it.
const GATE_REACH := 12.0
## How near, in cells, a band's red must be for a party walking itself to make for it ([D215]).
const AUTO_BAND_SIGHT := 18
## Where the log's right edge stands on a screen wide enough for it.
const LOG_WIDTH := 900.0
## How long a line stays in the log, in the player's seconds ([D246]).
const NOTE_SECONDS := 8.0
## The continent has been asked to settle a fight fought here, not to take a step.
var _settling: bool = false
## The area's own bands already standing here, by key, and how long since their flags were looked at.
var _posted_practice: Dictionary = {}
var _practice_clock: float = 0.0
## The Tower's floor this is, when it is one that is walked ([D102]), else 0; and how the last
## held band's fight went ("won", "lost", "fled"), until the continent has settled it.
var _tower_floor: int = 0
## Auto, hurt on a floor of the Tower, is walking back down to rest ([D258]).
var _auto_turned_back := false
## Inside a gate (D248): the gate's cell on the continent (or -1, -1), the floor (0 first), whether it
## is the last, and the flag its keeper's fall sets, without which the last floor's way down is shut.
var _gate_cell := Vector2i(-1, -1)
var _gate_depth := 0
var _gate_final := false
var _gate_keeper := ""
## The door the party is standing in, so a shut one is tried once per arrival, not every frame.
var _on_doorstep: Vector2i = Vector2i(-1, -1)
## The roadside scene stood on the ground ahead (D131), and what was put there for it.
var _roadside_staged := ""
var _roadside_nodes: Array[Node2D] = []
## The attackers of the roadside scene staged here, where its fight puts them (D207).
var _roadside_foes: Array[Node2D] = []
## The middle of the roadside scene staged here, and whether what is going on there has been said
## yet: it is said in the log as the party comes near (D216), not in a box when it is come upon.
var _roadside_middle := Vector2i(-1, -1)
var _roadside_told := false
var _held_fight: String = ""
var _held_done: String = ""
## cell -> a memory of the lead's lying there, not yet picked up (D103).
var _memories: Dictionary = {}

## The land ([D84]): whether this is it, the nodes each held tile put down (tile -> its ground,
## and tile -> everything standing in it), the tiles still to lay out, and whether the continent
## has been asked to take a step and not answered yet.
var _land_mode: bool = false
## Shelf edges the party has already been told cannot be climbed ([D308]).
var _ledges_said: Dictionary = {}
var _tile_ground: Dictionary = {}
var _tile_things: Dictionary = {}
var _to_hold: Array[Vector2i] = []
## Tiles whose ground is down and whose things are still to stand on it, a frame later: one tile's
## work split over two frames, so a step's new ground is no hitch (D122, lag).
var _to_fill: Array[Vector2i] = []
## The tile being painted a part at a time (`tile`, `under`, `patches`, `next`), and the one whose
## things are being put down a few at a time (`tile`, `jobs`, `next`).
var _painting: Dictionary = {}
var _filling: Dictionary = {}
## Tiles one beyond the next whose layout has been worked out ahead of the party, and tiles far
## enough behind to be let go of, one a frame.
var _warmed: Dictionary = {}
var _to_let_go: Array[Vector2i] = []
var _asking: bool = false
## The light the land is seen in, which turns as the party walks into other country.
var _dusk: CanvasModulate = null
var _dusk_turn: Tween = null


func _ready() -> void:
	_return_scene = boot_payload.get("return_scene", "world")
	_return_payload = boot_payload.get("return_payload", {})
	_planar_mode = bool(boot_payload.get("planar_mode", false))
	_acts = boot_payload.get("actions", [])
	_held = boot_payload.get("held", {})
	_tower_floor = int(boot_payload.get("tower_floor", 0))
	var gate_at: Array = boot_payload.get("gate_cell", [])
	if gate_at.size() == 2:
		_gate_cell = Vector2i(int(gate_at[0]), int(gate_at[1]))
		_gate_depth = int(boot_payload.get("gate_depth", 0))
		_gate_final = bool(boot_payload.get("gate_final", false))
		_gate_keeper = str(boot_payload.get("gate_keeper", ""))
	get_viewport().size_changed.connect(_fit_the_log)
	get_viewport().size_changed.connect(_fit_the_hint)
	_fit_the_log.call_deferred()
	# What can be done here, on one line that never runs up into the log ([D246], play-test 6:
	# "so much text here that is crossing over each other"): cut short with an ellipsis instead.
	_hint.autowrap_mode = TextServer.AUTOWRAP_OFF
	_hint.clip_text = true
	_hint.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_hint.add_theme_stylebox_override("normal", _quiet_backing())
	_land_mode = bool(boot_payload.get("land", false)) and GameState.world != null
	if _land_mode:
		map = Land.around(GameState.world, GameState.world.player_cell)
		(map as Land).wading = LandJournals.wades(GameState.world)
		map.spawn = _land_start()
	else:
		map = AreaMap.load_area(boot_payload.get("area_id", "village"))
	if map == null:
		push_error("Area: no such area '%s'" % boot_payload.get("area_id", ""))
		EventBus.request_scene.emit(_return_scene, _return_payload)
		return
	# A floor above the walked ones, walked on one of their plans (D207): its bands are its own foes.
	if _tower_floor > 0:
		map.bands = TowerFloors.restock(map.bands, GameState.world, _tower_floor, GameState.party_characters(), map.stairs)
		_admit_climbers_to_the_floor()
	# A wild place is guarded by the land's own creatures ([D309]).
	elif map.id.begins_with("wild_") and GameState.world != null:
		map.bands = Wilds.stock(map, GameState.world, GameState.world.player_cell, GameState.party_characters(), map.bands)
	_lay_out_memories()
	_waymark = AreaWaymark.new()
	add_child(_waymark)
	move_child(_waymark, _actors.get_index())
	_show_the_room()

	_land = Biome.effects(Biome.at(GameState.world, GameState.world.player_cell) if _land_mode \
		else str(Database.area(map.id).get("biome", "")))
	EventBus.area_note.connect(_note)
	EventBus.conversation_requested.connect(_see_who_speaks_from_afar)
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _let_the_ghost_go())
	_tell_where_we_are()
	# On the land every step is answered; anywhere, a band's fight is (step 4 of the First Hour).
	EventBus.continent_answered.connect(_on_continent_answered)
	EventBus.ground_shaken.connect(_camera.shake)
	_paint_layers()
	_light_the_place()
	_spawn_buildings()
	_spawn_props()
	_spawn_party()
	_admit_the_others()
	_admit_the_ghosts()
	_spawn_people()
	_post_the_watch()
	_spawn_fire()
	_light_the_climbers_fire()
	if _land_mode:
		var world: World = GameState.world
		_camera.frame(Rect2(Vector2.ZERO, Vector2(world.size * (map as Land).slot) * AreaMap.CELL))
	else:
		_camera.frame(map.rect())
	_camera.focus_on(_leader.position, true)
	_place.text = boot_payload.get("title", map.display_name)
	_idle_hint = map.hint if map.hint != "" else HINT
	if _land_mode:
		_idle_hint = _land_hint()
	_hint.text = _prompt_text()
	if _land_mode:
		_far_tower = FarTower.new()
		_place.get_parent().add_child(_far_tower)
		_place.get_parent().move_child(_far_tower, 0)
	_compass = Compass.new()
	_compass.position = Vector2(14.0, 42.0)
	_place.get_parent().add_child(_compass)
	_compass.pressed.connect(_next_quest)
	_point_the_compass()
	# The company and the purse, under the compass ([D244]).
	_play_hud = PlayHud.new()
	_play_hud.position = Vector2(14.0, float(PlayHud.rules().get("top", 128)))
	_place.get_parent().add_child(_play_hud)
	if _land_mode:
		_put_up_the_maps()
	Pad.changed.connect(_on_pad_changed)
	EventBus.map_requested.connect(_open_the_map)
	_lay_out_acts()
	_warm_the_party()
	for line: String in boot_payload.get("notes", []):
		_note(line)
	_call_out_the_looked_for()
	if _land_mode:
		_open_on(str(_here_chunk().get("opening", "")))
	else:
		_open_on(map.opening)


## The party's moves (and a bearer's, like Sky) load a frame at a time while the place is walked,
## so a fight met here starts without a pause (D122).
func _warm_the_party() -> void:
	var signatures: Dictionary = Database.skirmish.get("signatures", {})
	for member: Character in GameState.party_characters():
		Database.warm_unit(member.template_id)
		var signature: Dictionary = signatures.get(member.template_id, {})
		for key: String in ["bearer", "beast"]:
			if str(signature.get(key, "")) != "":
				Database.warm_unit(str(signature[key]))


## The cutscene a place plays the moment you walk into it, before you are given
## the keys back.
func _open_on(cutscene_id: String) -> void:
	if cutscene_id == "" or Database.cutscene(cutscene_id).is_empty():
		return
	_talking = true
	_hold_the_town(true)
	var them: AreaActor = _people[0] if not _people.is_empty() else _leader
	_cutscene = AreaCutscene.between(self, _camera, _leader, them)
	await _cutscene.play(cutscene_id)
	_cutscene = null
	_hold_the_town(false)
	_talking = false


# --- building -----------------------------------------------------------------


## One [TileMapLayer] per sheet, bottom first (see [GroundPainter]).
func _paint_layers() -> void:
	if _land_mode:
		for tile: Vector2i in (map as Land).held_tiles():
			_paint_tile(tile)
		return
	# A room is floors and walls, not ground ([D81]).
	if InteriorPainter.is_interior(map.id):
		InteriorPainter.paint(map, _layers)
		return
	GroundPainter.paint(map, _layers)
	# The clouds below a mountain's top ([D321]), under the edges' rims.
	if map.has_clouds():
		var clouds := AreaClouds.new()
		clouds.name = "Clouds"
		clouds.map = map
		_layers.add_child(clouds)
	# The edges of higher ground, over the ground and under everyone ([D308]).
	if map.has_heights():
		var ledges := AreaLedges.new()
		ledges.name = "Ledges"
		ledges.map = map
		_layers.add_child(ledges)


# --- the land ([D84]) -----------------------------------------------------------------


## Where the leader starts on the land: where they stood when the scene was last left, if that is
## on the tile the continent has them on; else that tile's own way in.
func _land_start() -> Vector2i:
	var land := map as Land
	var tile: Vector2i = GameState.world.player_cell
	for wanted: Variant in [boot_payload.get("land_cell", null), GameState.land_cell]:
		var at: Vector2i
		if wanted is Array and (wanted as Array).size() >= 2:
			at = AreaMap.to_cell(wanted)
		elif wanted is Vector2i:
			at = wanted
		else:
			continue
		if land.tile_of(at) == tile and land.in_bounds(at):
			return at
	var chunk: Dictionary = land.chunks.get(tile, {})
	if boot_payload.has("spawn_cell") and not chunk.is_empty():
		return AreaMap.to_cell(boot_payload["spawn_cell"]) + (chunk["origin"] as Vector2i)
	return AreaMap.to_cell(chunk.get("spawn", [0, 0])) + (chunk.get("origin", Vector2i.ZERO) as Vector2i)


## Where the party stands, for whatever plays to the place (the music, D185): this area, or on
## the land the place on the tile they are on ("home" for the crater, "city"), else that tile.
func _tell_where_we_are() -> void:
	EventBus.place_entered.emit(str(_here_chunk().get("id", "")) if _land_mode else map.id)


## The tile the continent has the party on.
func _here_chunk() -> Dictionary:
	return (map as Land).chunks.get(GameState.world.player_cell, {}) if _land_mode else {}


func _land_hint() -> String:
	var said := str(_here_chunk().get("hint", ""))
	return said if said != "" else "WASD to walk  ·  click anyone marked to speak to them"


## One tile's ground, in a node of its own so it can be let go of with the tile.
func _paint_tile(tile: Vector2i) -> void:
	GroundPainter.paint_patches(map, (map as Land).patches_of(tile), _ground_node(tile))


## The node [param tile]'s ground is painted into, under the bands' watched ground.
func _ground_node(tile: Vector2i) -> Node2D:
	var under := Node2D.new()
	under.name = "Tile_%d_%d" % [tile.x, tile.y]
	_layers.add_child(under)
	_layers.move_child(under, _tile_ground.size())
	_tile_ground[tile] = under
	return under


## Everything standing in [param tile]: houses, dressing, chests, things in the way, fires, the
## people who live there and any of the sixteen stopping there.
func _fill_tile(tile: Vector2i) -> void:
	_tile_things[tile] = []
	for job: Callable in _fill_jobs(tile):
		_keep_made(tile, job.call())


## Each thing that stands in [param tile], as a job that puts it down and returns its node (or
## null): done all at once when the scene opens, a few a frame as the party walks on.
func _fill_jobs(tile: Vector2i) -> Array[Callable]:
	var land := map as Land
	var area := land.slot_rect(tile)
	var jobs: Array[Callable] = []
	for building: Dictionary in map.buildings:
		if building.get("_tile") == tile:
			jobs.append(_put_building.bind(building))
	for prop: Dictionary in map.props:
		if prop.get("_tile") == tile:
			jobs.append(_put_spire.bind(prop) if prop.has("spire") else _put_prop.bind(prop))
	for cell: Vector2i in map.chests:
		if area.has_point(cell):
			jobs.append(_put_chest.bind(cell))
	for cell: Vector2i in map.wards:
		if area.has_point(cell):
			jobs.append(_put_ward.bind(cell))
	for cell: Vector2i in land.fires:
		if area.has_point(cell):
			jobs.append(_put_fire.bind(cell))
	_admit_the_others_to(tile)
	_admit_the_road_watch(tile)
	_admit_the_climbers(tile)
	for person: Dictionary in map.people:
		if person.get("_tile") == tile:
			jobs.append(_put_person.bind(person))
	for each: Dictionary in _life_for(tile):
		jobs.append(_put_critter.bind(each["art"], each["cell"], int(each["seed"])))
	return jobs


## The birds, butterflies, bees and creeping things of [param tile] ([D179], play-test 3: "Surely
## it would be some animals, butterflies, bees, bugs"): a few of each, as many as its land carries,
## half in a place; the same tile always gets the same ones.
func _life_for(tile: Vector2i) -> Array[Dictionary]:
	var land := map as Land
	var chunk: Dictionary = land.chunks.get(tile, {})
	var out: Array[Dictionary] = []
	if chunk.is_empty() or str(chunk.get("kind", "")) in ["sea", "rock"]:
		return out
	var rules: Dictionary = Database.world_rules.get("life", {})
	var share := float(Biome.data(str(chunk.get("land", ""))).get("life", 1.0))
	if str(chunk.get("kind", "")) == "place":
		share *= 0.5
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.world.shape_seed(), tile.x, tile.y, "life"])
	var area := land.slot_rect(tile)
	var per_tile: Dictionary = rules.get("per_tile", {})
	for kind: String in ["bird", "flutter", "hop", "crawl"]:
		var arts: Array = rules.get("art", {}).get(kind, [])
		if arts.is_empty():
			continue
		var mean := float(per_tile.get(kind, 0.0)) * share
		var count := int(floor(mean)) + (1 if rng.randf() < mean - floor(mean) else 0)
		for i in count:
			for _try in 12:
				var cell := area.position + Vector2i(rng.randi_range(1, area.size.x - 2), rng.randi_range(1, area.size.y - 2))
				if not land.is_walkable(cell) or land.terrain_at(cell) == "road":
					continue
				out.append({ "art": str(arts[rng.randi() % arts.size()]), "cell": cell, "seed": rng.randi() })
				break
	return out


func _put_critter(art: String, cell: Vector2i, seed_: int) -> Node2D:
	var jitter := Vector2(float(absi(seed_) % 21) - 10.0, float((absi(seed_) / 21) % 17) - 8.0)
	var critter: Node2D = AreaCritter.make(art, map.centre_of(cell) + jitter, seed_)
	critter.watching = func() -> Vector2: return _leader.position if is_instance_valid(_leader) else Vector2.INF
	critter.can_land = _can_stand
	_actors.add_child(critter)
	return critter


## The city's Watch walking the First Hour's road ([D179], play-test 3: "these roads should be
## patrolled by guards"): on some of the road's tiles, a pair of them walk the length of it there and
## back, saying a word at each end, and will talk.
func _admit_the_road_watch(tile: Vector2i) -> void:
	var land := map as Land
	var chunk: Dictionary = land.chunks.get(tile, {})
	if chunk.is_empty() or str(chunk.get("kind", "")) != "ground":
		return
	var watch: Dictionary = Database.world_rules.get("life", {}).get("road_watch", {})
	var units: Array = watch.get("units", [])
	if units.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.world.shape_seed(), tile.x, tile.y, "watch"])
	if rng.randf() >= float(watch.get("chance", 0.5)):
		return
	var road: Array[Vector2i] = []
	var area := land.slot_rect(tile)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if land.terrain_at(cell) == "road" and land.is_walkable(cell):
				road.append(cell)
	if road.size() < 8:
		return
	# The two ends of the road on this tile: the cells furthest apart.
	var a: Vector2i = road[0]
	var b: Vector2i = road[-1]
	for cell: Vector2i in road:
		if (cell - road[0]).length_squared() > (b - road[0]).length_squared():
			b = cell
	for cell: Vector2i in road:
		if (cell - b).length_squared() > (a - b).length_squared():
			a = cell
	var lines: Array = watch.get("lines", [])
	var stay: Array = watch.get("stay", [2.0, 4.0])
	for i in 2:
		var from := a if i == 0 else b
		var to := b if i == 0 else a
		map.people.append({
			"name": str(watch.get("name", "a watchman")), "unit": str(units[i % units.size()]),
			"cell": [from.x, from.y], "facing": [0, 1], "_tile": tile, "_area": "road_watch",
			"talk": watch.get("talk", {}),
			"rounds": [
				{ "cell": [to.x, to.y], "stay": rng.randf_range(float(stay[0]), float(stay[1])),
				  "line": str(lines[rng.randi() % lines.size()]) if not lines.is_empty() else "" },
				{ "cell": [from.x, from.y], "stay": rng.randf_range(float(stay[0]), float(stay[1])),
				  "line": str(lines[rng.randi() % lines.size()]) if not lines.is_empty() else "" },
			],
		})


## Other companies on their way to the Tower ([D215], play-test 4: "other people trying to climb
## the tower"): on some of the road's tiles, a company of two or three walks the road there and back,
## and will talk (`life.climbers` in `world_rules.json`). Not on a tile the Watch is walking.
func _admit_the_climbers(tile: Vector2i) -> void:
	var land := map as Land
	var rules: Dictionary = Database.world_rules.get("life", {}).get("climbers", {})
	var units: Array = rules.get("units", [])
	var companies: Array = rules.get("companies", [])
	if units.is_empty() or companies.is_empty():
		return
	if map.people.any(func(p: Dictionary) -> bool: return p.get("_tile") == tile and str(p.get("_area", "")) == "road_watch"):
		return
	var chunk: Dictionary = land.chunks.get(tile, {})
	if chunk.is_empty() or str(chunk.get("kind", "")) != "ground":
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.world.shape_seed(), tile.x, tile.y, "climbers"])
	if rng.randf() >= float(rules.get("road_chance", 0.3)):
		return
	var road: Array[Vector2i] = []
	var area := land.slot_rect(tile)
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			if land.terrain_at(cell) == "road" and land.is_walkable(cell):
				road.append(cell)
	if road.size() < 8:
		return
	var a: Vector2i = road[0]
	var b: Vector2i = road[-1]
	for cell: Vector2i in road:
		if (cell - road[0]).length_squared() > (b - road[0]).length_squared():
			b = cell
	for cell: Vector2i in road:
		if (cell - b).length_squared() > (a - b).length_squared():
			a = cell
	var company := str(companies[rng.randi() % companies.size()])
	var size: Array = rules.get("size", [2, 3])
	var lines: Array = rules.get("lines", [])
	var stay: Array = rules.get("stay", [3.0, 6.0])
	var behind := [Vector2i.ZERO, Vector2i(1, 0), Vector2i(0, 1)]
	for i in rng.randi_range(int(size[0]), int(size[1])):
		var from := _free_spot_near(a + behind[i % behind.size()])
		var to := _free_spot_near(b + behind[i % behind.size()])
		map.people.append({
			"name": company, "unit": str(units[rng.randi() % units.size()]),
			"cell": [from.x, from.y], "facing": [0, 1], "_tile": tile, "_area": "climbers",
			"talk": rules.get("talk", {}),
			"rounds": [
				{ "cell": [to.x, to.y], "stay": rng.randf_range(float(stay[0]), float(stay[1])),
				  "line": str(lines[rng.randi() % lines.size()]) if i == 0 and not lines.is_empty() else "" },
				{ "cell": [from.x, from.y], "stay": rng.randf_range(float(stay[0]), float(stay[1])),
				  "line": str(lines[rng.randi() % lines.size()]) if i == 0 and not lines.is_empty() else "" },
			],
		})


## Until when (ms) a second press goes into the gate that was warned of.
var _gate_warned_until: int = 0


## The gate here, when it is far above the company: the first press says so and the second, within
## a few seconds, goes in. A party walking itself never goes in (see [method _gate_too_strong]).
func _sure_of_the_gate() -> bool:
	var gate := _gate_here()
	if gate == null or not _gate_too_strong(gate):
		return true
	if Pace.auto:
		return false
	if Time.get_ticks_msec() < _gate_warned_until:
		_gate_warned_until = 0
		return true
	_gate_warned_until = Time.get_ticks_msec() + 4000
	_note("%s is a rank %s gate: what keeps it is about level %d, and the company is level %d. %s again to go in anyway." % [
		gate.display_name, gate.reading(), gate.reading_level(), Encounter.party_level(GameState.party_characters()),
		Pad.key("interact") if Pad.using_pad else "E"])
	return false


func _gate_here() -> Site:
	var world: World = GameState.world
	if world == null:
		return null
	var site := world.site_at(world.player_cell)
	return site if site != null and site.kind == Site.GATE else null


## A gate whose keepers stand `AutoRoad.GATE_WARN_LEVELS` or more above the company.
func _gate_too_strong(gate: Site) -> bool:
	return AutoRoad.too_strong(gate)


## Where a company resting on this floor sits, for their fire ([D246]).
var _climbers_rest_at: Array[Vector2i] = []


## Another company resting on a Tower floor, by the stair up ([D215]): they got here first, and will
## talk (`life.climbers.on_the_floors`). Floor 1 is never anyone's but the party's.
func _admit_climbers_to_the_floor() -> void:
	var rules: Dictionary = Database.world_rules.get("life", {}).get("climbers", {})
	var floors: Dictionary = rules.get("on_the_floors", {})
	var units: Array = rules.get("units", [])
	var companies: Array = rules.get("companies", [])
	if floors.is_empty() or units.is_empty() or companies.is_empty() or map.stairs.is_empty():
		return
	if _tower_floor < int(floors.get("from", 2)) or GameState.world == null:
		return
	# A shared floor has its own company climbing it, and a lived-on floor its people ([D307]).
	if TowerFloors.is_shared(_tower_floor) or TowerFloors.is_living(_tower_floor):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([GameState.world.world_seed, _tower_floor, "climbers"])
	if rng.randf() >= float(floors.get("chance", 0.4)):
		return
	var company := str(companies[rng.randi() % companies.size()])
	var stair: Vector2i = map.stairs[0]
	var resting := [Vector2i(-3, 3), Vector2i(-2, 4), Vector2i(-4, 4)]
	var size: Array = rules.get("size", [2, 3])
	var taken: Dictionary = {}
	for cell: Vector2i in map.stairs:
		taken[cell] = true
	for i in rng.randi_range(int(size[0]), int(size[1])):
		var at := Vector2i(-1, -1)
		var near: Vector2i = stair + (resting[i % resting.size()] as Vector2i)
		for radius in range(0, 5):
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var cand := near + Vector2i(dx, dy)
					if at.x < 0 and map.is_walkable(cand) and not taken.has(cand):
						at = cand
		if at.x < 0:
			continue
		taken[at] = true
		_climbers_rest_at.append(at)
		map.people.append({
			"name": company, "unit": str(units[rng.randi() % units.size()]),
			"cell": [at.x, at.y], "facing": [1, 0], "_area": "climbers_floor",
			"talk": floors.get("talk", {}),
		})


func _put_fire(cell: Vector2i) -> Node:
	var fire := AreaFire.new()
	fire.position = map.centre_of(cell)
	_actors.add_child(fire)
	return fire


func _keep_made(tile: Vector2i, node: Variant) -> void:
	if node != null:
		(_tile_things[tile] as Array).append(node)


## The tiles that should be held round where the party is now: laid out a frame at a time, nearest
## first, and the ones two tiles behind let go.
func _plan_the_land() -> void:
	var land := map as Land
	var here: Vector2i = GameState.world.player_cell
	for tile: Vector2i in land.held_tiles():
		if maxi(absi(tile.x - here.x), absi(tile.y - here.y)) > 2 and not _to_let_go.has(tile):
			_to_let_go.append(tile)
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var tile := here + Vector2i(dx, dy)
			if not land.is_held(tile) and not _to_hold.has(tile):
				_to_hold.append(tile)
	_to_hold.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return (a - here).length_squared() < (b - here).length_squared())


func _hold_more() -> void:
	# A little of the land ahead each frame, never more than the budget, so walking on stays smooth
	# ([D178], play-test 3: "major frame rate issues when jumping across tiles").
	var start := Time.get_ticks_usec()
	var budget := LAND_BUDGET_MS * 1000.0
	var first := true
	while _lay_a_little(first):
		first = false
		if Time.get_ticks_usec() - start >= budget:
			break


## One small piece of laying out the land: a thing put down, a part of a tile painted, a tile held,
## or (with nothing else to do, first in a frame) a tile ahead worked out. False when there was
## nothing to do.
func _lay_a_little(first: bool) -> bool:
	if not _to_let_go.is_empty():
		var going: Vector2i = _to_let_go.pop_front()
		var here: Vector2i = GameState.world.player_cell
		# Walked back towards it in the meantime: kept.
		if maxi(absi(going.x - here.x), absi(going.y - here.y)) > 2:
			_let_go(going)
		return true
	if not _filling.is_empty():
		var tile: Vector2i = _filling["tile"]
		var jobs: Array = _filling["jobs"]
		var next := int(_filling["next"])
		if next < jobs.size():
			_keep_made(tile, (jobs[next] as Callable).call())
			_filling["next"] = next + 1
			return true
		_filling = {}
		_post_bands_for(tile)
		return true
	if not _painting.is_empty():
		var patches: Array = _painting["patches"]
		var next := int(_painting["next"])
		if next < patches.size():
			GroundPainter.paint_patches(map, [patches[next]], _painting["under"])
			_painting["next"] = next + 1
			return true
		var painted: Vector2i = _painting["tile"]
		_painting = {}
		_to_fill.append(painted)
		return true
	if not _to_fill.is_empty():
		var filling: Vector2i = _to_fill.pop_front()
		if (map as Land).is_held(filling):
			_tile_things[filling] = []
			_filling = { "tile": filling, "jobs": _fill_jobs(filling), "next": 0 }
		return true
	if not _to_hold.is_empty():
		var tile: Vector2i = _to_hold.pop_front()
		var land := map as Land
		if land.is_held(tile):
			return true
		land.hold(tile)
		_painting = { "tile": tile, "under": _ground_node(tile), "patches": land.patches_of(tile), "next": 0 }
		return true
	return first and _warm_ahead()


## Near a tile's edge, the tiles beyond the next one are worked out before they are wanted, one a
## frame, so crossing over only has to put them down.
func _warm_ahead() -> bool:
	var land := map as Land
	var here: Vector2i = GameState.world.player_cell
	var local := map.cell_at(_leader.position) - land.slot_rect(here).position
	var near := int(LAND_WARM_CELLS)
	var dirs: Array[Vector2i] = []
	if local.x >= land.slot.x - near:
		dirs.append(Vector2i.RIGHT)
	if local.x < near:
		dirs.append(Vector2i.LEFT)
	if local.y >= land.slot.y - near:
		dirs.append(Vector2i.DOWN)
	if local.y < near:
		dirs.append(Vector2i.UP)
	for dir: Vector2i in dirs:
		for side in range(-2, 3):
			var ahead := here + dir * 2 + Vector2i(dir.y, dir.x) * side
			if _warmed.has(ahead) or land.is_held(ahead):
				continue
			_warmed[ahead] = true
			GroundGen.slot(GameState.world, ahead)
			return true
	return false


func _let_go(tile: Vector2i) -> void:
	var land := map as Land
	for node: Variant in _tile_things.get(tile, []):
		if not is_instance_valid(node):
			continue
		if node is AreaActor:
			_people.erase(node)
			_seated.erase(node)
		if node is AreaProp:
			_things.erase(node)
		if node == _nearby:
			_nearby = null
		if node == _hovered:
			_hovered = null
		if node == _approach:
			_approach = null
			_approach_path.clear()
		(node as Node).queue_free()
	_tile_things.erase(tile)
	var area := land.slot_rect(tile)
	for table: Dictionary in [_chest_props, _ward_props]:
		for cell: Vector2i in table.keys():
			if area.has_point(cell):
				table.erase(cell)
	if _tile_ground.has(tile):
		(_tile_ground[tile] as Node).queue_free()
		_tile_ground.erase(tile)
	for watch: Node2D in _watches.duplicate():
		if land.tile_of(watch.anchor) == tile and not watch.travelling:
			_take_off(watch)
	_to_hold.erase(tile)
	_to_fill.erase(tile)
	if _painting.get("tile") == tile:
		_painting = {}
	if _filling.get("tile") == tile:
		_filling = {}
	_warmed.erase(tile)
	land.release(tile)


## The leader has walked over into another tile: that is a step on the continent, asked for and
## walked on through while it is taken. Across a corner, the side that can be walked goes first.
func _mind_the_border() -> void:
	if _asking or _leaving or _talking:
		return
	var world: World = GameState.world
	var tile := (map as Land).tile_of(map.cell_at(_leader.position))
	var here: Vector2i = world.player_cell
	if tile == here:
		return
	var apart := tile - here
	var dir := Vector2i(signi(apart.x), 0) if apart.x != 0 else Vector2i(0, signi(apart.y))
	if apart.x != 0 and apart.y != 0 and not world.is_walkable(here + dir):
		dir = Vector2i(0, signi(apart.y))
	GameState.land_cell = map.cell_at(_leader.position)
	_ask_the_continent({ "step": [dir.x, dir.y] })


## Ask the continent to do something out of sight (a step, a place's doing) and carry on here.
func _ask_the_continent(asked: Dictionary) -> void:
	_asking = true
	var payload := asked.duplicate()
	payload["embedded"] = true
	payload["held"] = _held
	payload["back"] = _here_payload()
	EventBus.continent_requested.emit(payload)


## What the continent made of it: what can be done here now, what was said, who is about, and,
## after a step, the land round the new tile.
func _on_continent_answered(answer: Dictionary) -> void:
	if not is_inside_tree():
		return
	if answer.has("fight"):
		_awaiting_fight = false
		_fight_here(answer["fight"])
		return
	if _awaiting_fight:
		# The continent had no band to fight there after all: carry on walking.
		_awaiting_fight = false
		_stand_down()
	if _leaving:
		return
	_asking = false
	var settled := _settling
	_settling = false
	if not _land_mode:
		for line: Variant in answer.get("notes", []):
			_note(str(line))
		if settled:
			_after_held_fight()
		return
	_camera.make_current()
	_held = answer.get("held", {})
	_acts = answer.get("actions", [])
	_place.text = str(answer.get("title", _place.text))
	for line: Variant in answer.get("notes", []):
		_note(str(line))
	_lay_out_acts()
	if answer.has("cache"):
		_put_cache(answer["cache"])
	_stage_roadside(str(_held.get("roadside", "")))
	_fall_in()
	var land := map as Land
	var world: World = GameState.world
	# After a fight the party may stand over the border; walking on carries them across it.
	if not settled and land.tile_of(map.cell_at(_leader.position)) != world.player_cell:
		# The continent would not have it (the step was refused): back onto the tile it says.
		_step_back_onto(world.player_cell)
		_auto_tile = Vector2i(-1, -1)
	# A fight settled is no step: the tile, its light and its opening are as they were.
	if not settled:
		_on_new_tile()
	_sync_bands(answer.get("bands", []))
	_hint.text = _prompt_text()


## The party is on a tile it was not on before: the land's own weather and light, its line, and
## the tiles round it held.
func _on_new_tile() -> void:
	var world: World = GameState.world
	var chunk := _here_chunk()
	var land_id := Biome.at(world, world.player_cell)
	_land = Biome.effects(land_id)
	_told_of.clear()
	_idle_hint = _land_hint()
	_turn_the_light(str(chunk.get("tint", "")))
	_plan_the_land()
	_tell_where_we_are()
	var opening := str(chunk.get("opening", ""))
	if opening != "" and str(chunk.get("kind", "")) == "place":
		_open_on(opening)


## The leader back inside [param tile], at the nearest cell of it that can be stood on.
func _step_back_onto(tile: Vector2i) -> void:
	var land := map as Land
	var area := land.slot_rect(tile)
	var from := map.cell_at(_leader.position)
	var best := Vector2i(-1, -1)
	var best_d := INF
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			var cell := Vector2i(x, y)
			var d := Vector2(cell - from).length_squared()
			if d < best_d and map.is_walkable(cell):
				best_d = d
				best = cell
	if best.x >= 0 or best.y >= 0:
		_leader.position = map.centre_of(best)
		_reseed_crumbs()


func _turn_the_light(tint: String) -> void:
	var to := Color(tint) if tint != "" else Color.WHITE
	if _dusk == null:
		_dusk = CanvasModulate.new()
		_dusk.color = to
		add_child(_dusk)
		return
	if _dusk_turn != null and _dusk_turn.is_valid():
		_dusk_turn.kill()
	_dusk_turn = create_tween()
	_dusk_turn.tween_property(_dusk, "color", to, 1.2)


func _spawn_party() -> void:
	_actors.y_sort_enabled = true
	var start := map.spawn
	# On the land a way in is the tile's own, and [method _land_start] has already put it in the
	# tile: read again here it was a cell in the land's far corner, and only the lead was stepped
	# back onto the tile after (play-test 7: out of the ancient grove "my party disappeared").
	if boot_payload.has("spawn_cell") and not _land_mode:
		start = AreaMap.to_cell(boot_payload["spawn_cell"])
	if not map.is_walkable(start):
		for radius in range(1, 6):
			var found := false
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var cand := start + Vector2i(dx, dy)
					if map.is_walkable(cand):
						start = cand
						found = true
						break
				if found:
					break
			if found:
				break
	var members := GameState.party_characters()
	for index in members.size():
		if index > 0 and index <= map.seats.size() and not _land_mode:
			_take_a_seat(members[index], map.seats[index - 1])
			continue
		var actor := AreaActor.for_character(members[index])
		actor.position = map.centre_of(start)
		_actors.add_child(actor)
		if index == 0:
			_leader = actor
			_leader_character = members[index]
		else:
			_followers.append(actor)
	if _leader != null and not _followers.is_empty():
		_reseed_crumbs()
		for i in _followers.size():
			_followers[i].position = _point_along_trail((i + 1) * FOLLOWER_DISTANCE)


## Around a fire nobody trails the leader: they are already sitting down, and
## they are worth walking over to.
func _take_a_seat(character: Character, seat: Vector2i) -> void:
	var facing := map.fire - seat
	_seat_for[map.people.size()] = character
	map.people.append({
		"name": character.display_name,
		"unit": character.template_id,
		"cell": [seat.x, seat.y],
		"facing": [signi(facing.x), signi(facing.y)],
	})


## Somewhere that is not at noon: the whole canvas is tinted, and only the fire
## pushes back against it.
func _light_the_place() -> void:
	_fog_the_place()
	if _land_mode:
		_turn_the_light(str(_here_chunk().get("tint", "")))
		return
	if map.tint == "":
		return
	var dusk := CanvasModulate.new()
	dusk.color = Color(map.tint)
	add_child(dusk)


const FOG_SHADER := """
shader_type canvas_item;
uniform float thickness = 0.5;
uniform vec4 colour : source_color = vec4(0.82, 0.84, 0.9, 1.0);
void fragment() {
	vec2 from_middle = (UV - vec2(0.5)) * vec2(1.6, 1.0);
	float far = smoothstep(0.12, 0.62, length(from_middle));
	COLOR = vec4(colour.rgb, far * thickness);
}
"""


## Mist and jungle close in round the party: the screen fogs towards its edges,
## so what is coming is seen late (`fog` in the land's effects).
func _fog_the_place() -> void:
	var thickness := float(_land.get("fog", 0.0))
	if thickness <= 0.0:
		return
	var layer := CanvasLayer.new()
	layer.name = "Fog"
	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = FOG_SHADER
	var paint := ShaderMaterial.new()
	paint.shader = shader
	paint.set_shader_parameter("thickness", clampf(thickness, 0.0, 0.9))
	if map.tint != "":
		paint.set_shader_parameter("colour", Color(map.tint).lightened(0.3))
	veil.material = paint
	layer.add_child(veil)
	add_child(layer)
	# Under the hint line and the log, which have to stay readable.
	var ui := get_node_or_null("UI")
	if ui != null:
		move_child(layer, ui.get_index())


## A company resting on a Tower floor sits round a small fire of its own ([D246], play-test 6:
## "They are literally just standing there with icons above their head."), and faces it.
func _light_the_climbers_fire() -> void:
	if _climbers_rest_at.is_empty():
		return
	var middle := Vector2.ZERO
	for cell: Vector2i in _climbers_rest_at:
		middle += Vector2(cell)
	var at := _free_spot_near(Vector2i((middle / float(_climbers_rest_at.size())).round()) + Vector2i(1, 0))
	_put_fire(at)
	for actor: AreaActor in _people:
		if str((actor.get_meta("person", {}) as Dictionary).get("_area", "")) == "climbers_floor":
			actor.face(map.centre_of(at) - actor.position)


func _spawn_fire() -> void:
	if map.fire.x < 0:
		return
	var fire := AreaFire.new()
	fire.position = map.centre_of(map.fire)
	_actors.add_child(fire)


func _spawn_buildings() -> void:
	_actors.y_sort_enabled = true
	if _land_mode:
		for tile: Vector2i in (map as Land).held_tiles():
			_fill_tile(tile)
		return
	for building: Dictionary in map.buildings:
		_put_building(building)


func _put_building(building: Dictionary) -> Node:
	var node := AreaBuilding.create(building)
	_actors.add_child(node)
	return node


## Dressing, plus a picture for every chest. Anything with something to say
## about itself is marked, so it can be walked up to and looked at. A chest
## already emptied on an earlier visit is standing open when you walk back in.
func _spawn_props() -> void:
	_actors.y_sort_enabled = true
	if _land_mode:
		return
	for prop: Dictionary in map.props:
		_put_prop(prop)
	for cell: Vector2i in map.chests:
		_put_chest(cell)
	# Props representing obstacle wards (cuttable trees, locked gates, etc.)
	for cell: Vector2i in map.wards:
		_put_ward(cell)


func _put_prop(prop: Dictionary) -> Node2D:
	if prop.has("spire"):
		_put_spire(prop)
		return null
	var art: String = prop.get("art", "")
	if not AreaProp.has_art(art):
		return null
	# A bird or a bug laid down as scenery is alive ([D179]), unless it is something to look at.
	if AreaCritter.life_of(art) != "" and str(prop.get("line", "")) == "" and not prop.has("gold") and not prop.has("item"):
		var cell: Vector2i = prop["cell"]
		return _put_critter(art, cell, hash([map.id, cell.x, cell.y, art]))
	var node := AreaProp.from_entry(prop)
	node.position = map.centre_of(prop["cell"])
	# A nudge off the middle of its cell, so a wood does not stand in rows.
	var nudge: Array = prop.get("offset", [])
	if nudge.size() >= 2:
		node.position += Vector2(float(nudge[0]), float(nudge[1]))
	if not node.haul.is_empty() and GameState.has_flag(map.prop_flag(node.cell)):
		node.line = node.spent_line
		node.haul = {}
		node.set_interactive(node.line != "")
	_actors.add_child(node)
	if node.can_talk():
		_things.append(node)
	return node


## The Tower drawn tall from wall stone until its art lands (D108).
func _put_spire(prop: Dictionary) -> Node2D:
	var node := AreaSpire.from_entry(prop)
	node.position = map.centre_of(prop["cell"])
	_actors.add_child(node)
	return node


## Something the continent found left on this step, put down a little ahead of the party where it
## can be seen, and picked up with E like anything else worth stopping for. It is drawn as what is
## in it: coin as the coin pile, a sword as a sword ([Loot.cache_art]).
func _put_cache(haul: Dictionary) -> AreaProp:
	if _leader == null or haul.is_empty():
		return null
	var ahead := Vector2i((_leader.get("_facing") as Vector2).round()) if _leader.get("_facing") is Vector2 else Vector2i.DOWN
	var at := _free_spot_near(map.cell_at(_leader.position) + ahead * 2)
	var node := AreaProp.from_entry({
		"art": Loot.cache_art(haul), "cell": at, "name": "something left here",
		"line": "Something left here a long while ago, and nobody came back for it.",
	})
	node.haul = haul.duplicate()
	node.position = map.centre_of(at)
	_actors.add_child(node)
	_things.append(node)
	return node


## A roadside scene (D131): the cart, and the people round it, stood a few cells ahead before anyone
## speaks, so what the box says is there to see. It goes when the party walks off or steps in.
func _stage_roadside(event_id: String) -> void:
	if event_id == _roadside_staged:
		return
	_clear_roadside()
	if event_id == "" or _leader == null:
		return
	var event: Dictionary = Database.roadside.get("events", {}).get(event_id, {})
	var stage: Dictionary = event.get("stage", {})
	if stage.is_empty():
		return
	_roadside_staged = event_id
	var ahead := Vector2i((_leader.get("_facing") as Vector2).round()) if _leader.get("_facing") is Vector2 else Vector2i.DOWN
	if ahead == Vector2i.ZERO:
		ahead = Vector2i.DOWN
	# Stood well down the road (D216: seen coming, not put in front of the party).
	var off := int(Database.roadside.get("rules", {}).get("stage_cells", 4))
	var middle := _free_spot_near(map.cell_at(_leader.position) + ahead * off)
	_roadside_middle = middle
	_roadside_told = false
	for entry: Dictionary in stage.get("props", []):
		var offset: Array = entry.get("offset", [0, 0])
		var at := _free_spot_near(middle + Vector2i(int(offset[0]), int(offset[1])))
		var prop := AreaProp.from_entry({ "art": str(entry.get("art", "")), "cell": at, "solid": false,
			"name": str(entry.get("name", "it")) })
		prop.position = map.centre_of(at)
		_actors.add_child(prop)
		_roadside_nodes.append(prop)
	var victim := str(stage.get("victim", ""))
	var look_at := map.centre_of(middle)
	if victim != "":
		var driver := AreaActor.for_person({ "name": str(stage.get("victim_name", "someone")), "unit": victim })
		driver.position = map.centre_of(_free_spot_near(middle + Vector2i(1, 1)))
		driver.face(map.centre_of(map.cell_at(_leader.position)) - driver.position)
		driver.set_interactive(false)
		_actors.add_child(driver)
		_roadside_nodes.append(driver)
		look_at = driver.position
	# Whoever stands with the scene and will fight beside the party: the Watch beset (D215), back to
	# back in the middle of it, facing out at the ones round them.
	var standing := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)]
	var allies: Array = stage.get("allies", [])
	for i in mini(allies.size(), standing.size()):
		var ally: Dictionary = allies[i]
		var guard := AreaActor.for_person({ "name": str(ally.get("name", "someone")), "unit": str(ally.get("unit", "")) })
		guard.position = map.centre_of(_free_spot_near(middle + standing[i]))
		guard.face(guard.position - look_at if i > 0 else Vector2(0, -1))
		guard.set_interactive(false)
		_actors.add_child(guard)
		_roadside_nodes.append(guard)
	var round_them := [Vector2i(-2, 0), Vector2i(2, -1), Vector2i(0, -2), Vector2i(-1, 2), Vector2i(3, 1)]
	var pack: Array = event.get("pack", [])
	for i in mini(pack.size(), round_them.size()):
		var figure := AreaActor.for_person({ "name": "a brigand", "unit": str(pack[i]) })
		_roadside_foes.append(figure)
		figure.position = map.centre_of(_free_spot_near(middle + round_them[i]))
		figure.face(look_at - figure.position)
		figure.set_interactive(false)
		_actors.add_child(figure)
		_roadside_nodes.append(figure)


## What is going on at the roadside scene, said in the log once the party is near enough to see
## (`tell_cells`, D216), with how to step in.
func _tell_the_roadside() -> void:
	if _roadside_staged == "" or _roadside_told or _leader == null:
		return
	var near := int(Database.roadside.get("rules", {}).get("tell_cells", 5))
	if (map.cell_at(_leader.position) - _roadside_middle).length() > near:
		return
	_roadside_told = true
	for line: Variant in Roadside.seen(_roadside_staged):
		_note(str(line))
	_note("%s to step in, or walk on by." % (Pad.key("interact") if Pad.using_pad else "E"))


## Walking itself aggressively (D216), the company goes to a roadside scene and steps in; walking any
## other way it walks on by. [constant Vector2.INF] when there is nothing to go to.
func _auto_roadside_axis() -> Vector2:
	if Pace.auto_style != "aggressive" or _roadside_staged == "" or _asking or _leader == null:
		return Vector2.INF
	if not _acts.any(func(each: Dictionary) -> bool: return str(each.get("act", "")) == "_step_into_the_road"):
		return Vector2.INF
	var here := map.cell_at(_leader.position)
	if (here - _roadside_middle).length() <= 3.0:
		_do_act({ "act": "_step_into_the_road" })
		return Vector2.ZERO
	return (map.centre_of(_roadside_middle) - _leader.position).normalized()


func _clear_roadside() -> void:
	for node: Node2D in _roadside_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_roadside_nodes.clear()
	_roadside_foes.clear()
	_roadside_staged = ""
	_roadside_told = false


func _put_chest(cell: Vector2i) -> AreaProp:
	var chest: Dictionary = map.chests[cell]
	var shut: String = chest.get("art", "chest")
	var is_stash := bool(chest.get("stash", false))
	var opened := not is_stash and GameState.has_flag(map.chest_flag(cell))
	var node := AreaProp.create(_opened_art(chest) if opened else shut)
	node.position = map.centre_of(cell)
	node.cell = cell
	node.line = chest.get("line", "")
	if is_stash:
		node.display_name = "strongbox"
		node.set_interactive(true)
		_things.append(node)
	_actors.add_child(node)
	_chest_props[cell] = node
	return node


func _put_ward(cell: Vector2i) -> AreaProp:
	var ward: Dictionary = map.wards[cell]
	var prop_art := str(ward.get("prop", ""))
	if prop_art == "":
		if ward.get("kind", "") == "tree" or str(ward.get("name", "")).to_lower().contains("tree"):
			prop_art = "nature/sycamore_tree"
		elif ward.get("kind", "") == "gate" or str(ward.get("name", "")).to_lower().contains("gate"):
			prop_art = "village/log_pile"
	if prop_art == "" or not AreaProp.has_art(prop_art):
		return null
	var opened := Ward.is_open(map.area_of(cell), map.local_of(cell))
	var art_to_use := str(ward.get("cleared_art", "")) if opened and ward.has("cleared_art") else prop_art
	var node := AreaProp.create(art_to_use)
	node.position = map.centre_of(cell)
	node.cell = cell
	node.display_name = str(ward.get("name", "obstacle"))
	node.solid = not opened
	if opened and not ward.has("cleared_art"):
		node.visible = false
	else:
		node.line = "examine"
		node.set_interactive(not opened)
		_things.append(node)
	_actors.add_child(node)
	_ward_props[cell] = node
	return node


## Any of the sixteen standing at the place on the map this area is the inside
## of are standing in it too, a little way in from where the party arrives.
func _admit_the_others() -> void:
	var world: World = GameState.world
	if world == null or _return_scene != "world" or _land_mode:
		return
	var site := world.site_at(world.player_cell)
	if site == null or str(site.data.get("area", site.kind)) != map.id:
		return
	var offsets: Array[Vector2i] = [Vector2i(2, -2), Vector2i(-2, -2), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3)]
	var placed := 0
	for each: Dictionary in Wanderers.here(world, site.cell):
		var hero_id := str(each["id"])
		var spot := _free_spot_near(map.spawn + offsets[placed % offsets.size()])
		placed += 1
		map.people.append({
			"name": Wanderers.name_of(hero_id),
			"unit": hero_id,
			"cell": [spot.x, spot.y],
			"facing": [0, 1],
			"wanderer": hero_id,
			"wander": 1.5,
		})


## On the land, the same for the place standing in [param tile]: they wait just outside its way in.
func _admit_the_others_to(tile: Vector2i) -> void:
	var world: World = GameState.world
	var chunk: Dictionary = (map as Land).chunks.get(tile, {})
	var site := world.site_at(tile)
	if site == null or str(chunk.get("kind", "")) != "place":
		return
	var offsets: Array[Vector2i] = [Vector2i(2, -2), Vector2i(-2, -2), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3)]
	var spawn := AreaMap.to_cell(chunk.get("spawn", [0, 0])) + (chunk["origin"] as Vector2i)
	var placed := 0
	for each: Dictionary in Wanderers.here(world, site.cell):
		var hero_id := str(each["id"])
		var spot := _free_spot_near(spawn + offsets[placed % offsets.size()])
		placed += 1
		map.people.append({
			"name": Wanderers.name_of(hero_id), "unit": hero_id, "cell": [spot.x, spot.y],
			"facing": [0, 1], "wanderer": hero_id, "wander": 1.5, "_tile": tile,
		})


## Leads who died in the worlds before this one sit at any fire the company
## sits at, once their news has come through (M15, [D33]): in a seat nobody
## took, or across the fire from the way in.
func _admit_the_ghosts() -> void:
	var world: World = GameState.world
	if world == null or map.fire.x < 0 or _return_scene != "world":
		return
	var free_seats: Array[Vector2i] = []
	var taken := maxi(0, GameState.party_characters().size() - 1)
	for i in range(taken, map.seats.size()):
		free_seats.append(map.seats[i])
	for index: int in Siblings.ghosts(world):
		var echo: Dictionary = Siblings.past(world)[index]
		var spot: Vector2i = free_seats.pop_front() if not free_seats.is_empty() \
			else _free_spot_near(map.fire + Vector2i(0, -2))
		map.people.append({
			"name": Siblings.ghost_name(world, index),
			"unit": str(echo.get("hero", "")),
			"cell": [spot.x, spot.y],
			"facing": [map.fire.x - spot.x, map.fire.y - spot.y],
			"ghost": index,
		})


func _free_spot_near(cell: Vector2i) -> Vector2i:
	for radius in range(0, 6):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cand := cell + Vector2i(dx, dy)
				if map.is_walkable(cand):
					return cand
	return map.spawn


func _spawn_people() -> void:
	if _land_mode:
		return
	for index in map.people.size():
		_put_person(map.people[index], _seat_for.get(index, null))
	_seat_for.clear()


func _put_person(person: Dictionary, seated: Variant = null) -> AreaActor:
	var actor := AreaActor.for_person(person)
	actor.set_meta("person", person)
	actor.position = map.centre_of(AreaMap.to_cell(person.get("cell", [0, 0])))
	actor.face(Vector2(AreaMap.to_cell(person.get("facing", [0, 1]))))
	if seated != null:
		_seated[actor] = seated
	actor.set_interactive(seated != null or _has_something_to_say(person))
	actor.chatter = person.get("chatter", [])
	# Some of the people who only chat have heard what the company did here, and say so as it
	# passes (D249).
	if not actor.chatter.is_empty() and not person.has("ghost"):
		var aside := Remembered.aside(GameState.world, randf(), str(person.get("name", "")))
		if aside != "":
			actor.chatter = actor.chatter + [aside]
	if person.has("ghost"):
		# The same face as in life, with the fire showing through it.
		actor.modulate = Color(0.72, 0.86, 1.0, 0.55)
	_actors.add_child(actor)
	_people.append(actor)
	# Gone to walk with the company ([D277]): their place stands empty.
	if Recruits.has_joined(str(person.get("_area", map.id)), person):
		actor.set_interactive(false)
		actor.visible = false
		return actor
	var reach := float(person.get("wander", 0.0))
	var rounds: Array = person.get("rounds", [])
	if not rounds.is_empty() and seated == null:
		var stops: Array[Dictionary] = []
		for stop: Dictionary in rounds:
			stops.append({
				"at": map.centre_of(AreaMap.to_cell(stop.get("cell", [0, 0]))),
				"stay": float(stop.get("stay", 0.0)), "line": str(stop.get("line", "")),
			})
		actor.work_rounds(stops, _can_stand, map.find_path)
	elif reach > 0.0 and seated == null:
		actor.roam(reach, _can_stand)
	return actor


func _has_something_to_say(person: Dictionary) -> bool:
	return person.get("dialogue", "") != "" or person.get("cutscene", "") != "" \
		or bool(person.get("guild", false)) or person.get("wanderer", "") != "" \
		or person.has("talk") \
		or person.has("ghost")


## The town holds its breath while a conversation or a cutscene is running.
func _hold_the_town(on: bool) -> void:
	for actor: AreaActor in _people:
		actor.hold_still(on)


# --- talking ------------------------------------------------------------------


## Everybody worth speaking to and everything worth looking at.
func _targets() -> Array[AreaThing]:
	var out: Array[AreaThing] = []
	for actor in _people:
		if actor.can_talk():
			out.append(actor)
	for thing in _things:
		if thing.can_talk():
			out.append(thing)
	return out


## Whatever the leader is standing nearest to, close enough to deal with.
func _refresh_prompt() -> void:
	var closest: AreaThing = null
	var best := TALK_RANGE
	for target in _targets():
		var apart := _leader.position.distance_to(target.position)
		if apart <= best:
			best = apart
			closest = target
	# A way in near enough beats a person in the way: nobody wanders the doorway into the prompt.
	var door := _door()
	if door != null and _leader.position.distance_to(door.position) <= DOOR_RANGE:
		closest = door
	if closest != _nearby:
		if is_instance_valid(_nearby):
			_nearby.set_mark_ready(false)
		_nearby = closest
		if _nearby != null:
			_nearby.set_mark_ready(true)
	_hint.text = _prompt_text()


## The thing here that is a way into one of the place's doings (the Tower's door), or null.
func _door() -> AreaProp:
	for thing in _things:
		if is_instance_valid(thing) and thing is AreaProp and (thing as AreaProp).act != "":
			return thing as AreaProp
	return null


## Whether this is a floor walked to a stair at its far end: the Tower's ([D102]) or a gate's (D248).
func _walked_floor() -> bool:
	return _tower_floor > 0 or _in_a_gate()


## In a gate or a cave (where a first of a kind teaches, D301): anyone in the company looking out
## for a kind that holds a chamber here hears it said.
func _call_out_the_looked_for() -> void:
	if _land_mode or not (_in_a_gate() or bool(Database.area(map.id).get("teaches", false))):
		return
	var here: Array = []
	for band: Dictionary in Database.area(map.id).get("bands", []):
		if str(band.get("done_flag", "")) != "" and GameState.has_flag(str(band["done_flag"])):
			continue
		for kind: Variant in band.get("pack", []):
			if not here.has(str(kind)):
				here.append(str(kind))
	for member: Character in GameState.party_characters():
		for kind: String in member.look_for:
			if here.has(kind) and not member.beaten.has(kind):
				_note("%s: there is a %s in here, the kind I was looking out for." % [
					member.display_name, str(Database.unit_template(kind).get("display_name", kind))])


func _in_a_gate() -> bool:
	return _gate_cell.x >= 0


## Whether the far stair can be taken: always on the Tower; on a gate's last floor only once its keeper
## is down, and on its other floors only once every band on it is (`gate.inside.rout`, play-test 7: "In
## order for the gates to be closed, they have to kill all of the mobs in the dungeon").
func _way_down_open() -> bool:
	if not _in_a_gate():
		return true
	if _gate_final:
		return _gate_keeper == "" or GameState.has_flag(_gate_keeper)
	return not _routs() or _standing_bands().is_empty()


## Why the way down will not open: its keeper, or (D261) whatever else on the floor still stands.
func _way_down_shut_line() -> String:
	if _gate_final:
		return "The way down will not open while its keeper stands."
	return str(GateInside.rules().get("rout_line", "The way down will not open yet."))


func _routs() -> bool:
	return bool(GateInside.rules().get("rout", false))


## The bands of this floor still standing on it (one that found nowhere to stand holds nothing up).
func _standing_bands() -> Array:
	var posted := {}
	for watch: Node2D in _watches:
		posted[str(watch.band.get("key", ""))] = true
	return map.bands.filter(func(band: Dictionary) -> bool:
		return posted.has(str(band.get("key", ""))) and not GameState.has_flag("done:%s" % str(band.get("key", ""))))


## Where the band whose fall the way down waits on stands, while it stands; else (-1, -1). On a gate's
## last floor it is the keeper; on its others the nearest band still standing.
func _keeper_cell() -> Vector2i:
	if _way_down_open():
		return Vector2i(-1, -1)
	var best := Vector2i(-1, -1)
	for band: Dictionary in _standing_bands():
		if _gate_final and "done:%s" % str(band.get("key", "")) != _gate_keeper:
			continue
		var at := Vector2i(int(band.get("at", [0, 0])[0]), int(band.get("at", [0, 0])[1]))
		for watch: Node2D in _watches:
			if str(watch.band.get("key", "")) == str(band.get("key", "")) and not watch.members.is_empty():
				at = watch.members[0]
		if best.x < 0 or _leader == null or _leader.position.distance_to(map.centre_of(at)) < _leader.position.distance_to(map.centre_of(best)):
			best = at
	return best


## What taking the far stair is called here.
func _stair_line() -> String:
	if not _in_a_gate():
		return "climb to floor %d" % (_tower_floor + 1)
	var site := GameState.world.site_at(_gate_cell) if GameState.world != null else null
	var gate_name := site.display_name if site != null else "the gate"
	if _gate_final:
		return "shut %s" % gate_name
	return "go down to floor %d of %d" % [_gate_depth + 2, site.floors() if site != null else _gate_depth + 2]


## Whether the leader stands on the stair up, or a step from it, on a floor of the Tower.
func _at_the_stair() -> bool:
	if not _walked_floor() or map.stairs.is_empty() or _leader == null:
		return false
	var here := map.cell_at(_leader.position)
	for stair: Vector2i in map.stairs:
		if absi(stair.x - here.x) <= 1 and absi(stair.y - here.y) <= 1:
			return true
	return false


func _prompt_text() -> String:
	if _hovered != null:
		return "Click to %s" % _hovered.prompt()
	if _at_the_stair():
		if not _way_down_open():
			return _way_down_shut_line()
		return "%s to %s" % [Pad.key("interact") if Pad.using_pad else "E", _stair_line()]
	if _nearby != null:
		var doing := _act_of(_nearby)
		if not doing.is_empty():
			return str(doing.get("prompt", ""))
		if Pad.using_pad:
			return "%s to %s" % [Pad.key("interact"), _nearby.prompt()]
		return "Click to %s" % _nearby.prompt()
	var here := _acts_text()
	var strike := str(AreaWatch.rule("first_strike_hint", "")) if _strike_target() != null else ""
	if strike != "":
		return strike if here == "" else "%s  ·  %s" % [here, strike]
	if here != "":
		return here
	# How to walk is said until the player has walked; after that, in a run, the
	# line stays empty until there is something here to do (D95). The tutorial
	# keeps it.
	if GameState.has_flag(WALKED_FLAG) and not GameState.rehearsing:
		return ""
	return _pad_hint() if Pad.using_pad else _idle_hint


func _on_pad_changed() -> void:
	_hint.text = _prompt_text()


## The idle line, said for a pad. A place's own line is written for the
## keyboard (it is data), so on a pad the buttons are said here instead.
func _pad_hint() -> String:
	return ("%s to walk  ·  %s to speak to or look at whoever is marked  ·  %s to take the lead with someone else  ·  %s for the party  ·  %s for the journal" + ("" if _land_mode else "  ·  follow the road out to leave")) % [
		Pad.walk_text(), Pad.key("interact"), Pad.key("cycle_next"),
		Pad.key("open_party"), Pad.key("open_journal"),
	]


## What is under the mouse worth stopping for, or null. Whatever stands
## furthest down the screen is in front, so it wins an overlap.
func _target_at(point: Vector2) -> AreaThing:
	var found: AreaThing = null
	for target in _targets():
		if not target.contains_point(point):
			continue
		if found == null or target.position.y > found.position.y:
			found = target
	return found


func _hover_at(point: Vector2) -> void:
	var target := _target_at(point)
	if target == _hovered:
		return
	if is_instance_valid(_hovered):
		_hovered.set_hovered(false)
	_hovered = target
	if _hovered != null:
		_hovered.set_hovered(true)
	Input.set_default_cursor_shape(
		Input.CURSOR_POINTING_HAND if _hovered != null else Input.CURSOR_ARROW
	)
	_hint.text = _prompt_text()


## Click something within reach and the party deals with it at once; click one
## across the square and the leader walks over first.
func _click_target(target: AreaThing) -> void:
	if _leader.position.distance_to(target.position) <= TALK_RANGE:
		_approach = null
		_approach_path.clear()
		_engage(target)
		return
	_approach = target
	_approach_path = map.find_path(_leader.position, target.position)
	_approach_index = 0
	if _approach_path.size() > 1 and _leader.position.distance_to(_approach_path[0]) < 20.0:
		_approach_index = 1


## Steering for whatever the player clicked on: walk until it is close enough
## to deal with, then deal with it.
## Clicked on open ground: the way there, a cell at a time ([D178], `doug-md`'s play-test 3: "an
## option to use either WASD to move around or point and click").
func _click_step() -> Vector2:
	while not _click_path.is_empty() and _leader.position.distance_to(_click_path[0]) < 12.0:
		_click_path.remove_at(0)
	if _click_path.is_empty():
		return Vector2.ZERO
	return (_click_path[0] - _leader.position).normalized()


## Walk to [param point] on the ground, by the way round anything in the way. Nothing happens for a
## point nobody could stand on or reach.
func _walk_to(point: Vector2) -> void:
	var way := map.find_path(_leader.position, point)
	if way.size() < 2:
		# Open ground with no way to it from here, on ground with heights, is a shelf with no way up:
		# said once a cell ([D312]).
		var there := map.cell_at(point)
		if map.has_heights() and map.is_walkable(there) and there != map.cell_at(_leader.position) and not _ledges_said.has(there):
			_ledges_said[there] = true
			_note(str(Database.world_rules.get("heights", {}).get("no_way_line", "There is no way up to there from here.")))
		return
	way.remove_at(0)
	# The last step is to where the click was, not the middle of its cell.
	if map.is_walkable(map.cell_at(point)):
		way[-1] = point
	_approach = null
	_approach_path.clear()
	_click_path = way


func _approach_step() -> Vector2:
	if not is_instance_valid(_approach) or not _approach.can_talk():
		_approach = null
		_approach_path.clear()
		return Vector2.ZERO
	var apart := _approach.position - _leader.position
	if apart.length() <= APPROACH_RANGE:
		var target := _approach
		_approach = null
		_approach_path.clear()
		_engage(target)
		return Vector2.ZERO

	if not _approach_path.is_empty() and _approach_index < _approach_path.size():
		var waypoint := _approach_path[_approach_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_approach_index += 1
			if _approach_index < _approach_path.size():
				waypoint = _approach_path[_approach_index]
		return (waypoint - _leader.position).normalized()

	return apart.normalized()


## A party walking itself on the land walks it, where it can be seen ([D94]): over the border
## into the tile the continent's own walk would step to next, which is the step taken.
func _land_auto_axis() -> Vector2:
	var land := map as Land
	var world: World = GameState.world
	var here := map.cell_at(_leader.position)
	# A party walking itself came to a gate to go in (D116), and goes in on this ground (D162),
	# unless it has already lost here or the gate is not where it is going ([D211]).
	if not _asking and not Pace.avoided.has(world.player_cell) \
			and AutoRoad.goes_into(world, world.player_cell):
		for each: Dictionary in _acts:
			if FIGHT_ACTS.has(str(each.get("act", ""))):
				_do_act(each)
				return Vector2.ZERO
	var to_door := _auto_door_axis(world)
	if to_door != Vector2.INF:
		return to_door
	var to_scene := _auto_roadside_axis()
	if to_scene != Vector2.INF:
		return to_scene
	var to_band := _auto_band_axis()
	if to_band != Vector2.INF:
		return to_band
	# Asked again once the step is taken, or when the party was put somewhere else (a fight).
	if _auto_tile.x < 0 or _auto_from != world.player_cell or land.tile_of(here) == _auto_tile:
		if _asking:
			return Vector2.ZERO
		_auto_from = world.player_cell
		_auto_tile = world.player_cell + AutoRoad.next_step(world)
		_auto_exit_path.clear()
		if _auto_tile == world.player_cell:
			_auto_tile = Vector2i(-1, -1)
			return Vector2.ZERO
		_auto_exit_path = _auto_way(land, here, land.slot_rect(_auto_tile).get_center())
		_auto_exit_index = 0
		if _auto_exit_path.size() > 1 and _leader.position.distance_to(_auto_exit_path[0]) < 20.0:
			_auto_exit_index = 1
	# Walking passively, a band that has patrolled across the way it worked out sends it round again.
	if Pace.auto_style == "passive" and _auto_exit_index < _auto_exit_path.size() \
			and Time.get_ticks_msec() >= _auto_reroute_at \
			and _red_at(map.cell_at(_auto_exit_path[_auto_exit_index])):
		_auto_reroute_at = Time.get_ticks_msec() + 500
		_auto_exit_path = _auto_way(land, here, land.slot_rect(_auto_tile).get_center())
		_auto_exit_index = 1 if _auto_exit_path.size() > 1 else 0
	if _auto_exit_index < _auto_exit_path.size():
		var waypoint := _auto_exit_path[_auto_exit_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_auto_exit_index += 1
			if _auto_exit_index < _auto_exit_path.size():
				waypoint = _auto_exit_path[_auto_exit_index]
		return (waypoint - _leader.position).normalized()
	# The tile it makes for was not laid out yet when the way was worked out (the land ahead is laid
	# out a little a frame, D178): worked out again once it is, rather than walking at it blind.
	if _auto_exit_path.is_empty() and land.is_held(_auto_tile):
		_auto_exit_path = _auto_way(land, here, land.slot_rect(_auto_tile).get_center())
		_auto_exit_index = 1 if _auto_exit_path.size() > 1 else 0
		if not _auto_exit_path.is_empty():
			return (_auto_exit_path[_auto_exit_index] - _leader.position).normalized()
	# No way worked out across the land: straight at it, and the border does the rest.
	var middle := map.centre_of(land.slot_rect(_auto_tile).get_center())
	return (middle - _leader.position).normalized()


## Whether a band on this ground is watching [param cell].
func _red_at(cell: Vector2i) -> bool:
	return _watches.any(func(watch: Node2D) -> bool: return watch.watched.has(cell))


## The way a party walking itself takes across the land to [param to]: walking passively ([D216]),
## round every band's red when there is a way round, straight through it only when there is not.
func _auto_way(land: Land, here: Vector2i, to: Vector2i) -> Array[Vector2]:
	if Pace.auto_style == "passive" and not _watches.is_empty():
		var red: Dictionary = {}
		for watch: Node2D in _watches:
			for cell: Vector2i in watch.watched:
				if cell != here:
					red[cell] = true
		var round := land.find_cell_path(here, to, red)
		if not round.is_empty():
			return round
	return land.find_cell_path(here, to)


## Walking itself aggressively ([D216]), a band standing in sight on this ground is the fight worth
## the detour Auto turned aside for
## ([method AutoRoad.errand]): it walks into the band's nearest red cell, rather than standing on the
## band's tile waiting for it to look, or stepping off and back on for ever ([D215]: with bands by the
## road, Auto did both for minutes). [constant Vector2.INF] when there is none in sight.
func _auto_band_axis() -> Vector2:
	if Pace.auto_style != "aggressive" or _watches.is_empty() or _spotted or _leader == null:
		return Vector2.INF
	var here := map.cell_at(_leader.position)
	var best := Vector2i(-1, -1)
	var far := AUTO_BAND_SIGHT * AUTO_BAND_SIGHT
	for watch: Node2D in _watches:
		if bool(watch.band.get("spar", false)):
			continue
		for cell: Vector2i in watch.watched:
			var apart := (cell - here).length_squared()
			if apart < far:
				far = apart
				best = cell
	if best.x < 0:
		_auto_band_path.clear()
		return Vector2.INF
	if best != _auto_band_target or _auto_band_path.is_empty():
		_auto_band_target = best
		_auto_band_path = map.find_cell_path(here, best)
		_auto_band_index = 1 if _auto_band_path.size() > 1 else 0
	if _auto_band_index < _auto_band_path.size():
		var waypoint: Vector2 = _auto_band_path[_auto_band_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_auto_band_index += 1
			if _auto_band_index < _auto_band_path.size():
				waypoint = _auto_band_path[_auto_band_index]
		return (waypoint - _leader.position).normalized()
	return (map.centre_of(best) - _leader.position).normalized()


## A party walking itself to the Tower does not stop where it crosses onto the Tower's tile, out
## in the streets: it walks on to the door, stops there with "E to climb" up, and hands back
## ([D197]; before it, Auto stopped at the tile's edge and, asked on, walked off to wander). Asked on
## again from the door, it goes in, and climbs as Auto does on the floors (D115). [constant
## Vector2.INF] when the Tower is not where the party is headed, or there is no door here to go to.
func _auto_door_axis(world: World) -> Vector2:
	var goal := AutoRoad.objective(world)
	var door := _door()
	# Hurt, the party rests before it goes up ([D258]: it climbed on at a quarter of its health).
	if AutoRoad.rest_stop(world).x >= 0:
		door = null
	if not bool(goal.get("door", false)) or goal.get("cell") != world.player_cell or door == null:
		_auto_at_door = false
		_auto_door_path.clear()
		return Vector2.INF
	if _leader.position.distance_to(door.position) <= DOOR_RANGE * 0.75:
		var doing := _act_of(door)
		if not _auto_at_door:
			_auto_at_door = true
			_auto_door_path.clear()
			Pace.auto = false
			var prompt := str(doing.get("prompt", ""))
			_note("You have reached %s.%s" % [goal.get("label", "the Tower"), " " + prompt if prompt != "" else ""])
			return Vector2.ZERO
		if doing.is_empty():
			# The stair is shut (no Guild mark yet): the party goes about its errands instead.
			return Vector2.INF
		if not _asking and not _leaving and not _talking:
			_auto_at_door = false
			_do_act(doing)
		return Vector2.ZERO
	if _auto_door_path.is_empty() or _auto_door_index >= _auto_door_path.size():
		_auto_door_path = map.find_path(_leader.position, door.position)
		_auto_door_index = 1 if _auto_door_path.size() > 1 else 0
		if _auto_door_path.is_empty():
			return (door.position - _leader.position).normalized()
	var waypoint := _auto_door_path[_auto_door_index]
	if _leader.position.distance_to(waypoint) < 16.0:
		_auto_door_index += 1
		if _auto_door_index >= _auto_door_path.size():
			return (door.position - _leader.position).normalized()
		waypoint = _auto_door_path[_auto_door_index]
	return (waypoint - _leader.position).normalized()


## Soak mode: make for the way out, so a run that is playing itself never
## settles down inside a town.
func _auto_axis() -> Vector2:
	# On a floor of the Tower, Auto makes for the stair and climbs it (D115), never the way out;
	# a memory of the lead's lying there it picks up first (D150: it walked past the buckle).
	var climbing := _walked_floor() and not map.stairs.is_empty()
	# Hurt on a floor of the Tower, it turns back down the way it came to rest, as a player would
	# ([D258]: the bots climbed on hurt and fell on floors 1 to 3); the floors won stay won.
	# Only with somewhere to rest: with nowhere known it went in and out of the door for good.
	var turning_back := climbing and _tower_floor > 0 and not map.exits.is_empty() \
			and AutoRoad.nearest_rest(GameState.world).x >= 0 \
			and AutoRoad.hurt(float(Database.world_rules.get("first_hour", {}).get("auto_turn_back_below", 0.0)))
	if turning_back != _auto_turned_back:
		_auto_turned_back = turning_back
		_auto_exit_path = []
	if turning_back:
		climbing = false
	var keepsake: Variant = _memories.keys()[0] if climbing and not _memories.is_empty() else null
	# In a gate whatever the way down waits on is gone for first: on its last floor the keeper (D248), on
	# the others the nearest band still standing (D261).
	var keeper := _keeper_cell() if climbing else Vector2i(-1, -1)
	if keepsake == null and keeper.x >= 0:
		keepsake = keeper
	if climbing and keepsake == null and _at_the_stair():
		if not _talking and not _leaving:
			_climb_the_stair()
		return Vector2.ZERO
	if map == null or (map.exits.is_empty() and not climbing):
		return Vector2.ZERO
	if _auto_exit_path.is_empty() or _auto_exit_index >= _auto_exit_path.size():
		var nearest: Vector2i = (keepsake as Vector2i) if keepsake != null else (map.stairs[0] if climbing else map.exits[0])
		var best_dist := _leader.position.distance_to(map.centre_of(nearest))
		for exit_cell in ([] if climbing else map.exits):
			var d := _leader.position.distance_to(map.centre_of(exit_cell))
			if d < best_dist:
				best_dist = d
				nearest = exit_cell
		_auto_exit_path = map.find_cell_path(map.cell_at(_leader.position), nearest)
		_auto_exit_index = 0
		if _auto_exit_path.size() > 1 and _leader.position.distance_to(_auto_exit_path[0]) < 20.0:
			_auto_exit_index = 1

	if not _auto_exit_path.is_empty() and _auto_exit_index < _auto_exit_path.size():
		var waypoint := _auto_exit_path[_auto_exit_index]
		if _leader.position.distance_to(waypoint) < 16.0:
			_auto_exit_index += 1
			if _auto_exit_index < _auto_exit_path.size():
				waypoint = _auto_exit_path[_auto_exit_index]
		return (waypoint - _leader.position).normalized()

	var nearest := map.centre_of((keepsake as Vector2i) if keepsake != null else (map.stairs[0] if climbing else map.exits[0]))
	var apart := nearest - _leader.position
	return apart.normalized() if apart.length() > 4.0 else Vector2.ZERO


## A person is spoken to; anything else is looked at.
func _engage(target: AreaThing) -> void:
	if target is AreaProp:
		_examine(target as AreaProp)
		return
	if _people.has(target as AreaActor):
		_speak_with(target as AreaActor)


## The place's doing [param thing] is the way into, while the place offers it (the Tower's door
## climbs, D107), or an empty dictionary.
func _act_of(thing: AreaThing) -> Dictionary:
	if not thing is AreaProp or (thing as AreaProp).act == "":
		return {}
	for each: Dictionary in _acts:
		if str(each.get("act", "")) == (thing as AreaProp).act:
			return each
	return {}


## Stopping at something: what the party makes of it, and whatever was tucked
## into it — which is only ever there the first time.
func _examine(thing: AreaProp) -> void:
	_leader.face(thing.position - _leader.position)
	EventBus.player_did.emit("examined:%s" % thing.display_name)
	if _is_an_inns_bed(thing.cell):
		_try_the_bed(thing.cell)
		return
	if map.wards.has(thing.cell):
		_try_the_ward(thing.cell)
		return
	var doing := _act_of(thing)
	if not doing.is_empty():
		_do_act(doing)
		return
	if thing.reads == "climbers":
		# Read in a box, not the log: a stone of names wants reading down (play-test 7, call BR3).
		var names := Climbers.lines(GameState.world, GameState.roster.player() if GameState.roster != null else null)
		EventBus.conversation_requested.emit([{ "speaker": thing.display_name.capitalize(), "text": "\n".join(names) }])
		return
	if not thing.try_once.is_empty():
		_try_once(thing)
		return
	_note(thing.line)
	# A way in that is shut says why (the Tower's stair, sealed until the Guild's mark).
	if thing.act != "":
		for each: Dictionary in _acts:
			if str(each.get("act", "")) == "" and str(each.get("prompt", "")) != "":
				_note(str(each["prompt"]))
	if thing.find_flag != "" and not GameState.has_flag(thing.find_flag):
		GameState.set_flag(thing.find_flag)
		if thing.found_line != "":
			_note(thing.found_line)
	if map.chests.has(thing.cell) and bool(map.chests[thing.cell].get("stash", false)):
		EventBus.stash_requested.emit()
		return
	if thing.haul.is_empty():
		return
	GameState.set_flag(map.prop_flag(thing.cell))
	for line: String in Loot.claim(thing.haul, GameState.roster):
		_note(line)
	thing.haul = {}
	thing.line = thing.spent_line
	thing.set_interactive(thing.line != "")
	if not thing.can_talk():
		if _nearby == thing:
			_nearby = null
		if _hovered == thing:
			_hovered = null
		_things.erase(thing)


## Walk up to somebody and the camera takes a moment over the meeting before
## either of you says a word.
func _speak_to(index: int) -> void:
	if index >= 0 and index < _people.size():
		await _speak_with(_people[index])


func _speak_with(them: AreaActor) -> void:
	_talking = true
	_hold_the_town(true)
	if _seated.has(them):
		await _talk_around_the_fire(them)
		_camera.focus_on(_leader.position)
		_hold_the_town(false)
		_talking = false
		return

	var person: Dictionary = them.get_meta("person", {})
	EventBus.player_did.emit("talked:%s" % str(person.get("name", "")))
	_leader.face(them.position - _leader.position)
	them.face(_leader.position - them.position)

	var cutscene_id: String = person.get("cutscene", "")
	var seen := "seen:cut:%s" % cutscene_id
	if cutscene_id != "" and (bool(person.get("repeat", false)) or not GameState.has_flag(seen)):
		GameState.set_flag(seen)
		_cutscene = AreaCutscene.between(self, _camera, _leader, them)
		await _cutscene.play(cutscene_id)
		_cutscene = null

	var dialogue_id: String = person.get("dialogue", "")
	var wanderer: String = person.get("wanderer", "")
	if person.has("ghost"):
		await _sit_with_the_ghost(int(person["ghost"]))
	elif wanderer != "":
		await _speak_to_the_fallen(them, wanderer)
	elif dialogue_id != "":
		EventBus.dialogue_requested.emit(dialogue_id)
		await EventBus.dialogue_finished
	elif bool(person.get("guild", false)) and Guild.hall_at(GameState.world, GameState.world.player_cell) != null:
		if not them.chatter.is_empty():
			them.say(them.chatter.pick_random())
		EventBus.guild_requested.emit()
		await EventBus.overlay_closed
	elif person.has("talk"):
		var talk_id: String = Talk.open(str(person.get("_area", map.id)), person)
		EventBus.dialogue_requested.emit(talk_id)
		await EventBus.dialogue_finished
		_take_on_the_asked(them)
	elif not them.chatter.is_empty():
		them.say(them.chatter.pick_random())

	_settle_the_room()
	_camera.focus_on(_leader.position)
	_hold_the_town(false)
	_talking = false



## One of the sixteen, met inside. If they agree to walk with you they step out
## of the crowd: the party picks them up on the way back out.
func _speak_to_the_fallen(them: AreaActor, hero_id: String) -> void:
	var dialogue_id := Wanderers.talk(GameState.world, GameState.roster, hero_id)
	if dialogue_id == "":
		return
	EventBus.dialogue_requested.emit(dialogue_id)
	await EventBus.dialogue_finished
	Wanderers.settle(GameState.world, GameState.roster, GameState.flags)
	if not bool(Wanderers.entry(GameState.world, hero_id).get("joined", false)):
		return
	_note(Wanderers.joined_line(GameState.world, hero_id))
	them.set_interactive(false)
	them.visible = false
	_nearby = null
	_hovered = null
	# They fall in behind the party now, where they can be seen following (Ewan's play-test 2).
	_fall_in()


## Somebody asked to walk with the company said yes ([D277]): they step out of the crowd and fall
## in behind, like one of the sixteen.
func _take_on_the_asked(them: AreaActor) -> void:
	for recruit: Character in Recruits.settle(GameState.world, GameState.roster, GameState.flags, GameState.ledger):
		_note(Recruits.joined_line(recruit.display_name))
	if not Recruits.has_joined(str((them.get_meta("person", {}) as Dictionary).get("_area", map.id)), them.get_meta("person", {})):
		return
	them.set_interactive(false)
	them.visible = false
	_nearby = null
	_hovered = null
	_fall_in()


## A dead lead's ghost, across the fire: as much of their journal as they will
## share tonight.
func _sit_with_the_ghost(index: int) -> void:
	var dialogue_id := Siblings.ghost_talk(GameState.world, index)
	if dialogue_id == "":
		return
	EventBus.dialogue_requested.emit(dialogue_id)
	await EventBus.dialogue_finished


## Two of your own, across the fire. What they find to say depends on what they
## have been through together, and saying it moves that on a notch ([Banter]).
func _talk_around_the_fire(sitter: AreaActor) -> void:
	var them: Character = _seated[sitter]
	_leader.face(sitter.position - _leader.position)
	_camera.focus_on(_leader.position.lerp(sitter.position, 0.5))

	# Their own arc, or the leader's, comes before anything else said at the fire (D250).
	var exchange := Arcs.at_the_fire(GameState.world, GameState.roster, _leader_character, them)
	if exchange.is_empty():
		exchange = Banter.between(
			GameState.world, _leader_character, them, Banter.REST, GameState.world.rng
		)
	if exchange.is_empty():
		# Nothing left between the two of them, so they fall back on the run itself.
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		var alone := Recollection.remark(GameState.world, [them], rng)
		if alone.is_empty():
			_note("%s watches the fire, and lets it be." % them.display_name)
			return
		exchange = [alone]

	var id := "camp:%s" % them.id
	if Pace.quiet_banter:
		# Said over their heads instead of over the screen.
		for line: Dictionary in exchange:
			_note("%s: %s" % [line.get("speaker", ""), line.get("text", "")])
		sitter.say(str(exchange[-1].get("text", "")))
	else:
		Database.register_dialogue(id, Banter.as_dialogue(exchange, _leader_character, them))
		EventBus.dialogue_requested.emit(id)
		await EventBus.dialogue_finished
	# One thing each per fire, so the night is not talked in circles.
	_seated.erase(sitter)
	sitter.set_interactive(false)
	sitter.set_mark_ready(false)
	sitter.set_hovered(false)
	_nearby = null
	_hovered = null


# --- walking ------------------------------------------------------------------


func _physics_process(delta: float) -> void:
	_let_old_notes_go()
	if _play_hud != null:
		# Out of the way of a fight on this ground (it has its own cards) and of any box that is open.
		_play_hud.visible = _fight == null and not _overlay_open()
	if _waymark != null:
		_waymark.show_way(_leader.position if _leader != null else Vector2.ZERO,
			_click_path if _leader != null and _fight == null else ([] as Array[Vector2]))
	if _fight != null:
		_watch_the_fight()
		return
	_quiet_while_spoken_to()
	_compass_clock -= delta
	if _compass_clock <= 0.0:
		_compass_clock = COMPASS_EVERY
		_point_the_compass()
	if _leaving or _leader == null or _talking or _overlay_open():
		return
	if _land_mode:
		_hold_more()
	_refresh_prompt()
	_tell_the_roadside()
	if not map.bands.is_empty():
		_practice_clock += delta
		if _practice_clock >= 0.5:
			_practice_clock = 0.0
			_post_practice_bands()
	if _check_the_watch(map.cell_at(_leader.position)):
		return
	if _picking_an_act():
		return
	# Before the early-out below: the party has to keep closing the gap after the
	# player lets go of the keys, or everyone freezes mid-stride where they stood.
	_settle_followers(delta)
	_room_clock -= delta
	if _room_mark != null and _room_clock <= 0.0:
		_room_clock = 0.25
		_draw_the_way_to_bed()
	var axis := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# With the large map open the keys look about the map; the party walks on as it was (D232).
	if _map_open():
		axis = Vector2.ZERO
	if axis != Vector2.ZERO:
		# Taking the keys back calls off whatever the player was walking towards.
		_approach = null
		_approach_path.clear()
		_click_path.clear()
	elif Pace.auto:
		axis = _land_auto_axis() if _land_mode else _auto_axis()
	elif _approach != null:
		axis = _approach_step()
	elif not _click_path.is_empty():
		axis = _click_step()
	if axis == Vector2.ZERO:
		return

	var before := _leader.position
	var stride := axis.normalized() * _walk_speed() * delta
	_try_the_way(before, stride)
	_leader.position = _slide(before, stride)
	var moved := _leader.position - before
	if moved.length_squared() > 0.01:
		_leader.face(moved)
	if map.has_heights():
		_fall(before)
		_say_the_shelf(before, stride, moved)
	# Auto walking into something and not moving works its way out again, rather than pressing on
	# at a waypoint it cannot reach ([D197]).
	_auto_blocked = _auto_blocked + 1 if Pace.auto and moved.length_squared() <= 0.01 else 0
	if _auto_blocked >= AUTO_BLOCKED_FRAMES:
		_auto_blocked = 0
		_auto_exit_path.clear()
		_auto_door_path.clear()
		_auto_tile = Vector2i(-1, -1)
	if (_approach != null or not _click_path.is_empty()) and _leader.position.is_equal_approx(before):
		# Something is in the way; the player can steer around it themselves.
		_approach = null
		_approach_path.clear()
		_click_path.clear()
	_drop_crumbs()
	_camera.focus_on(_leader.position)
	_walked += before.distance_to(_leader.position)
	if _strolled < AreaMap.CELL * 3.0:
		_strolled += before.distance_to(_leader.position)
		if _strolled >= AreaMap.CELL * 3.0:
			EventBus.player_did.emit("walked")
			if not GameState.rehearsing and not GameState.has_flag(WALKED_FLAG):
				GameState.set_flag(WALKED_FLAG)
				_hint.text = _prompt_text()
	_weather(before.distance_to(_leader.position))
	if _walked >= TALK_STRIDE:
		_walked = 0.0
		_road_talk()
	_arrive_at(map.cell_at(_leader.position))
	if _land_mode:
		_mind_the_border()


## Bog and snow drag at the feet; open ground does not. A land journal's boots or sandals put some
## of it back ([D239]).
func _walk_speed() -> float:
	var stride := 1.0 + LandJournals.effect(GameState.world, "stride") if _land_mode else 1.0
	return WALK_SPEED * clampf(float(_land.get("slow", 1.0)) * stride, 0.3, 1.5)


## The cold, the heat or the ooze, wearing at whoever walks this ground without
## the gear to keep it off. Never down past `floor` of anyone's health: walking
## wears the party down for the fight, it does not kill (`data/biomes.json` →
## `hazards`).
func _weather(walked: float) -> void:
	var hazard := str(_land.get("hazard", ""))
	if hazard == "" or walked <= 0.0:
		return
	var rules: Dictionary = Database.biomes.get("hazards", {})
	_weathered += walked
	if _weathered < float(rules.get("stride", 640)):
		return
	_weathered = 0.0
	var told: Dictionary = rules.get(hazard, {})
	for member: Character in GameState.party_characters():
		if Biome.spared(member, hazard) or LandJournals.spares(GameState.world, hazard):
			continue
		var low := ceili(float(member.max_hp()) * float(rules.get("floor", 0.25)))
		var now := member.current_hp()
		if now <= low:
			continue
		member.hp = maxi(low, now - maxi(1, roundi(float(member.max_hp()) * float(rules.get("share", 0.04)))))
		if not _told_of.has(member.display_name):
			_told_of[member.display_name] = true
			_note(str(told.get("line", "%s is worn down by the land.")) % member.display_name)


## Two of the party say something to each other as they walk. It plays over
## their heads and is gone in a few seconds; nobody has to stop for it.
func _road_talk() -> void:
	if _chatting or _talking or _leaving or _followers.is_empty():
		return
	var world := GameState.world
	if world == null:
		return
	if world.rng.randf() >= float(Banter.rules().get("road_chance", 0.4)):
		return
	var exchange := Banter.pick(world, GameState.party_characters(), Banter.ROAD, world.rng)
	if not exchange.is_empty():
		_speak_bubbles(exchange)


## Line after line, each over whoever said it, the next one waiting only as
## long as the last takes to read.
func _speak_bubbles(exchange: Array) -> void:
	_chatting = true
	for line: Dictionary in exchange:
		var text: String = line.get("text", "")
		var speaker := _actor_named(line.get("speaker", ""))
		if speaker == null or text == "":
			continue
		speaker.say(text)
		await get_tree().create_timer(SpeechBubble.time_for(text)).timeout
		if not is_inside_tree() or _leaving:
			break
	_chatting = false


func _actor_named(who: String) -> AreaActor:
	if _leader != null and _leader.display_name == who:
		return _leader
	for follower in _followers:
		if follower.display_name == who:
			return follower
	return null


const BODY_RADIUS := 14.0
## Set once the player has walked a few cells in a run: the walking hint is done.
const WALKED_FLAG := "seen:walked"


## Walls stop the axis that runs into them, not the whole step, so a shoulder
## against a pond still slides along it.
func _slide(from: Vector2, step: Vector2) -> Vector2:
	var out := from
	if _can_step(from, Vector2(from.x + step.x, out.y)):
		out.x += step.x
	elif absf(step.y) > 0.001 and _can_step(from, Vector2(from.x, out.y + step.y)):
		pass
	else:
		# Horizontal blocked; attempt subtle corner nudge up/down to slide smoothly around corners
		for nudge in [2.0, 4.0, 6.0, 8.0, 10.0]:
			if _can_step(from, Vector2(from.x + step.x, out.y + nudge)):
				out.y += minf(absf(step.x), nudge)
				out.x += step.x
				break
			elif _can_step(from, Vector2(from.x + step.x, out.y - nudge)):
				out.y -= minf(absf(step.x), nudge)
				out.x += step.x
				break

	if _can_step(from, Vector2(out.x, from.y + step.y)):
		out.y += step.y
	elif absf(step.x) > 0.001 and _can_step(from, Vector2(out.x + step.x, from.y)):
		pass
	else:
		# Vertical blocked; attempt subtle corner nudge left/right to slide smoothly around corners
		for nudge in [2.0, 4.0, 6.0, 8.0, 10.0]:
			if _can_step(from, Vector2(out.x + nudge, from.y + step.y)):
				out.x += minf(absf(step.y), nudge)
				out.y += step.y
				break
			elif _can_step(from, Vector2(out.x - nudge, from.y + step.y)):
				out.x -= minf(absf(step.y), nudge)
				out.y += step.y
				break

	return out


## Standing room at [param to], stepped to from [param from]: higher ground is only climbed at a
## way up, and only dropped off otherwise ([D308]).
func _can_step(from: Vector2, to: Vector2) -> bool:
	return _can_stand(to) and map.may_step(map.cell_at(from), map.cell_at(to))


## The lead stepped from [param before] to where they stand: a drop of a height or more, and what it
## costs ([D308]): the first height is free, each past `hurt_from` takes `share` of everyone's
## health, never below `floor` of it.
func _fall(before: Vector2) -> void:
	var fell := map.drop(map.cell_at(before), map.cell_at(_leader.position))
	var rules: Dictionary = Database.world_rules.get("heights", {})
	if fell < int(rules.get("hurt_from", 2)):
		return
	var share := float(rules.get("share", 0.15)) * float(fell - int(rules.get("hurt_from", 2)) + 1)
	for member: Character in GameState.party_characters():
		var low := ceili(float(member.max_hp()) * float(rules.get("floor", 0.1)))
		member.hp = maxi(low, member.current_hp() - maxi(1, roundi(float(member.max_hp()) * share)))
	_note(str(rules.get("hurt_line", "A drop of {fell}. Everyone lands hard.")).format({ "fell": fell }))


## Something tried once a run with a throw of the dice ([D318]; play-test 3, item 8: the sword in the
## Tower's yard, "pulled with a dice roll, once"). The first look rolls against `try.chance` (a roll
## given is used, for the suites): won, the prize is taken and `win` said; lost, `lose`. Every look
## after says `tried`. The run keeps the try as a flag, won or lost.
func _try_once(thing: AreaProp, roll: float = -1.0) -> void:
	var try: Dictionary = thing.try_once
	var local := map.local_of(thing.cell)
	var flag := "tried:%s:%d:%d" % [map.area_of(thing.cell), local.x, local.y]
	if GameState.has_flag(flag):
		_note(str(try.get("tried", thing.line)))
		return
	GameState.set_flag(flag)
	thing.line = str(try.get("tried", thing.line))
	if roll < 0.0:
		roll = randf()
	if roll < float(try.get("chance", 0.0)):
		GameState.set_flag(flag + ":won")
		_note(str(try.get("win", "It comes free.")))
		for line: String in Loot.claim({ "item": str(try.get("item", "")) }, GameState.roster):
			_note(line)
	else:
		_note(str(try.get("lose", "It does not move.")))


## Walking into a shelf with no way up says so, once a cell ([D308]).
func _say_the_shelf(before: Vector2, stride: Vector2, moved: Vector2) -> void:
	if not map.has_heights() or moved.length_squared() > 0.01 or stride == Vector2.ZERO:
		return
	var ahead := map.cell_at(before + stride.normalized() * (BODY_RADIUS + 4.0))
	var here := map.cell_at(before)
	# At the edge of the clouds ([D321]): nobody walks off, and the lead says why, once a cell.
	if ahead != here and map.is_cloud(ahead) and not _ledges_said.has(ahead):
		_ledges_said[ahead] = true
		_note(str(Database.world_rules.get("heights", {}).get("cloud_line", "Below the edge there is only cloud.")))
		return
	if ahead == here or not map.is_walkable(ahead) or map.may_step(here, ahead):
		return
	if _ledges_said.has(ahead):
		return
	_ledges_said[ahead] = true
	_note(str(Database.world_rules.get("heights", {}).get("blocked_line", "The shelf is too high to climb here. Find a slope.")))


func _can_stand(point: Vector2) -> bool:
	if not map.is_walkable(map.cell_at(point)):
		return false
	# Ensure characters cannot penetrate walls or clip through diagonal wall corners
	for offset in [Vector2(-BODY_RADIUS, 0), Vector2(BODY_RADIUS, 0), Vector2(0, -BODY_RADIUS), Vector2(0, BODY_RADIUS),
				   Vector2(-BODY_RADIUS * 0.707, -BODY_RADIUS * 0.707), Vector2(BODY_RADIUS * 0.707, -BODY_RADIUS * 0.707),
				   Vector2(-BODY_RADIUS * 0.707, BODY_RADIUS * 0.707), Vector2(BODY_RADIUS * 0.707, BODY_RADIUS * 0.707)]:
		if not map.is_walkable(map.cell_at(point + offset)):
			return false
	return true


func _try_the_ward(cell: Vector2i) -> bool:
	if not map.wards.has(cell):
		return false
	if Ward.is_open(map.area_of(cell), map.local_of(cell)):
		return true
	var told: Dictionary = (map.wards[cell] as Dictionary).duplicate()
	told["cell"] = map.local_of(cell)
	var outcome := Ward.force(map.area_of(cell), told, GameState.party_characters())
	_note(str(outcome["line"]))
	if bool(outcome["opened"]):
		_shut_wards.erase(cell)
		map.update_cell_solid(cell, false)
		map._blocked.erase(cell)
		Sfx.play(Sfx.SELECT)
		if _ward_props.has(cell):
			var prop: AreaProp = _ward_props[cell]
			var ward: Dictionary = map.wards[cell]
			prop.solid = false
			prop.set_interactive(false)
			if _things.has(prop):
				_things.erase(prop)
			if ward.has("cleared_art"):
				prop.set_art(ward["cleared_art"])
			else:
				var tw := create_tween()
				tw.tween_property(prop, "modulate:a", 0.0, 0.35)
				tw.tween_callback(func() -> void: prop.hide())
		return true
	return false


## Walking into a thing in the way is how you find out whether anyone with you
## can shift it. Only the party ever tries; the townsfolk walk around (see [Ward]).
func _try_the_way(from: Vector2, step: Vector2) -> void:
	for point in [Vector2(from.x + step.x, from.y), Vector2(from.x, from.y + step.y)]:
		var cell := map.cell_at(point)
		if not map.wards.has(cell) or Ward.is_open(map.area_of(cell), map.local_of(cell)):
			continue
		var opened := _try_the_ward(cell)
		if not opened and not _shut_wards.has(cell):
			_shut_wards[cell] = true


func _point_along_trail(target_dist: float) -> Vector2:
	if _crumbs.is_empty() or _leader == null:
		return _leader.position if _leader != null else Vector2.ZERO
	var prev := _leader.position
	var dist_so_far := 0.0
	for crumb in _crumbs:
		var seg_len := prev.distance_to(crumb)
		if dist_so_far + seg_len >= target_dist:
			var remain := target_dist - dist_so_far
			var t := remain / seg_len if seg_len > 0.001 else 0.0
			return prev.lerp(crumb, t)
		dist_so_far += seg_len
		prev = crumb
	return _crumbs.back()


func _drop_crumbs() -> void:
	if _followers.is_empty() or _leader == null:
		return
	if _crumbs.is_empty() or _leader.position.distance_to(_crumbs[0]) >= CRUMB_SPACING:
		_crumbs.push_front(_leader.position)
	var max_len := float(_followers.size() + 2) * FOLLOWER_DISTANCE
	var accum := 0.0
	var prev := _leader.position
	for i in _crumbs.size():
		accum += prev.distance_to(_crumbs[i])
		prev = _crumbs[i]
		if accum >= max_len:
			_crumbs.resize(i + 1)
			break


## Walk everyone up the trail the leader left. Runs every frame whether or not
## the player is holding a key. Follows along the polyline path smoothly.
func _settle_followers(delta: float) -> void:
	if _followers.is_empty() or _leader == null:
		return
	# The party's formation ([D305]): each follower has a slot round the lead, and walks to it
	# where it can be stood on; where it cannot (a door, a wall), the trail behind the lead.
	var slots := _formation_slots()
	for index in _followers.size():
		var follower := _followers[index]
		var target_dist := float(index + 1) * FOLLOWER_DISTANCE
		var target_pos := _point_along_trail(target_dist)
		var formed := false
		if slots.has(index):
			var spot: Vector2 = slots[index]
			if _can_stand(spot) and map.height_at(map.cell_at(spot)) == map.height_at(map.cell_at(_leader.position)):
				target_pos = spot
				formed = true
		var to_target := target_pos - follower.position
		var far := to_target.length()

		if far <= FOLLOW_DEADZONE:
			if formed:
				# Settled in a slot: face the way the lead faces.
				follower.face(_leader.facing())
				continue
			# When settled, face along the trail towards the member ahead
			var ahead_dist := maxf(0.0, target_dist - 10.0)
			var ahead_pos := _point_along_trail(ahead_dist)
			var trail_dir := ahead_pos - follower.position
			if trail_dir.length_squared() > 1.0:
				follower.face(trail_dir)
			continue

		var speed_mult := 1.35 if far > FOLLOWER_DISTANCE * 1.5 else (1.15 if far > FOLLOWER_DISTANCE else 1.0)
		var step := to_target.normalized() * (_walk_speed() * speed_mult * delta)
		if step.length() > far:
			step = to_target
		# Facing the way they step. It used to wait until they were four pixels behind their
		# place, but a follower keeping pace is about three behind it at walking speed, so once
		# in step they never turned again: walking up and then down, the party walked down looking
		# up (play-test 4: "my characters that are followed behind me are facing the wrong way").
		if step.length() > 0.5:
			follower.face(step)
		follower.position = _slide(follower.position, step)


## Where each follower's slot is right now ([D305]): follower index -> point, for the party's
## shape round the lead as they face. Empty with formations off, or when the followers are not
## the party (someone has just joined or gone, and `_fall_in` has not put them down yet).
func _formation_slots() -> Dictionary:
	var out := {}
	if not Formations.on() or _leader == null:
		return out
	var members := GameState.party_characters()
	if members.size() != _followers.size() + 1:
		return out
	var companions: Array = []
	for i in range(1, members.size()):
		companions.append(members[i].template_id)
	var shape := Formations.chosen(members.size(), Formations.leader_of(members))
	if shape == "":
		return out
	var dealt := Formations.assign(shape, companions)
	var spacing := float(Formations.rules().get("ground_spacing", 40.0))
	for i in companions.size():
		# One in no state to hold a formation walks the trail instead ([D306]).
		if dealt.has(companions[i]) and not Formations.broken(members[i + 1]):
			out[i] = Formations.point_for(dealt[companions[i]], _leader.position, _leader.facing(), spacing)
	return out


func _arrive_at(cell: Vector2i) -> void:
	if _memories.has(cell):
		_remember(cell)
	# The stair asks before it climbs (meeting 3: walking onto it ended the floor, a step past
	# whatever lay beside it): standing at it says "E to climb", and E climbs.
	if _walked_floor() and map.stairs.has(cell):
		return
	if not _land_mode and (map.is_exit(cell) or _is_edge_cell(cell)):
		_handle_exit(cell)
		return
	var door := map.door_at(cell)
	if door.is_empty():
		_on_doorstep = Vector2i(-1, -1)
	elif cell != _on_doorstep:
		# Once per arrival: a shut door said its line every frame the party leaned on it, and
		# the play log filled with the same door forty times a second (play-test 4).
		_on_doorstep = cell
		_enter(door)
		return
	else:
		return
	if map.spots.has(cell) and not _visited_spots.has(cell):
		_visited_spots[cell] = true
		_note(map.spots[cell])
		if map.spot_flags.has(cell):
			GameState.set_flag(map.spot_flags[cell])
		if map.story_pages.has(cell):
			_read_a_page(cell)
		_found_on_the_land(cell)
	if map.chests.has(cell):
		_open_chest(cell)


## A page of the place's story ([D314]; [D287]: "a quest or a story in each"), stood on: its line is
## said each time, kept as a flag the first time this run, and when the last page of the place's
## story is read its end is said and written in the annals. Read in any order.
func _read_a_page(cell: Vector2i) -> void:
	var area := map.area_of(cell)
	var local := map.local_of(cell)
	var flag := "story:%s:%d:%d" % [area, local.x, local.y]
	if GameState.has_flag(flag) or GameState.has_flag("story:%s:told" % area):
		return
	GameState.set_flag(flag)
	var data: Dictionary = Database.area(area)
	for spot: Dictionary in data.get("spots", []):
		if not bool(spot.get("page", false)):
			continue
		var page := AreaMap.to_cell(spot.get("cell", [0, 0]))
		if not GameState.has_flag("story:%s:%d:%d" % [area, page.x, page.y]):
			return
	var end := str((data.get("story", {}) as Dictionary).get("end", ""))
	if end == "":
		return
	GameState.set_flag("story:%s:told" % area)
	var wild := str(data.get("display_name", area))
	var told := str(Database.world_rules.get("wilds", {}).get("story_annals", "{wild}: {end}")).format(
			{ "wild": wild.left(1).to_upper() + wild.substr(1), "end": end })
	_note(told)
	if GameState.world != null:
		Annals.record(GameState.world, told)


## Something somebody left out in the open country (standing stones, a cairn, a cold camp, a cache)
## crosses a line off that land's page ([D239]); the last line turns up its trinket.
func _found_on_the_land(cell: Vector2i) -> void:
	if not _land_mode or str((map as Land).chunk_at(cell).get("kind", "")) != "ground":
		return
	var world: World = GameState.world
	var before := LandJournals.carried(world).size()
	var lines := LandJournals.on_landmark(world, (map as Land).tile_of(cell))
	for line: String in lines:
		_note(line)
	if LandJournals.carried(world).size() > before and not lines.is_empty():
		(map as Land).wading = LandJournals.wades(world)
		Sfx.play(Sfx.SELECT)
		EventBus.conversation_requested.emit([{ "speaker": "", "text": lines.back() }])


func _is_edge_cell(cell: Vector2i) -> bool:
	if not _planar_mode or _return_scene != "world":
		return false
	return cell.x <= 0 or cell.x >= map.width - 1 or cell.y <= 0 or cell.y >= map.height - 1


func _cardinal_direction_of(cell: Vector2i) -> Vector2i:
	if cell.y <= 1:
		return Vector2i.UP
	if cell.y >= map.height - 2:
		return Vector2i.DOWN
	if cell.x <= 1:
		return Vector2i.LEFT
	if cell.x >= map.width - 2:
		return Vector2i.RIGHT
	return Vector2i.ZERO


func _nearest_edge(cell: Vector2i) -> Vector2i:
	var apart := {
		Vector2i.UP: cell.y, Vector2i.DOWN: map.height - 1 - cell.y,
		Vector2i.LEFT: cell.x, Vector2i.RIGHT: map.width - 1 - cell.x,
	}
	var best := Vector2i.DOWN
	for dir: Vector2i in apart:
		if int(apart[dir]) < int(apart[best]):
			best = dir
	return best


func _direction_name(dir: Vector2i) -> String:
	match dir:
		Vector2i.UP: return "north"
		Vector2i.DOWN: return "south"
		Vector2i.LEFT: return "west"
		Vector2i.RIGHT: return "east"
	return "forward"


func _handle_exit(cell: Vector2i) -> void:
	if _leaving:
		return
	# A double gate lets nobody out until its keeper falls ([D302]).
	if _in_a_gate() and GameState.world != null:
		var gate := GameState.world.site_at(_gate_cell)
		if gate != null and gate.sealed_in():
			_note(str(Site.reading_rules().get("sealed_line", "The way out is shut.")))
			return
	var dir := _cardinal_direction_of(cell)
	# On the ground every road leads somewhere on the continent: out the way it
	# points, rather than back up to a view nobody plays in.
	if dir == Vector2i.ZERO and _planar_mode and _return_scene == "world":
		dir = _nearest_edge(cell)
	if _planar_mode and GameState.world != null and dir != Vector2i.ZERO:
		var target_world := GameState.world.player_cell + dir
		if not GameState.world.in_bounds(target_world):
			_note("The continent drops away into endless mist. You cannot pass further %s." % _direction_name(dir))
			return
		if not GameState.world.is_walkable(target_world):
			var tid := GameState.world.terrain_id_at(target_world)
			if tid == "ocean" or tid == "water" or tid == "lake":
				_note("Deep waters stretch out to the %s. You cannot cross without a ship or ferry." % _direction_name(dir))
			elif tid == "crag" or tid == "mountain":
				_note("Steep mountain crags and sheer rock faces rise to the %s. You cannot pass." % _direction_name(dir))
			else:
				_note("The terrain to the %s is impassable." % _direction_name(dir))
			return
		_step_to_adjacent_planar_area(dir, target_world, cell)
		return

	_leave()


## The step is the continent's to take: bands, scenes on the road, rests and
## gates all happen there. It hands back the ground the party walks into, or a
## fight, or the fire.
func _step_to_adjacent_planar_area(dir: Vector2i, _target_world: Vector2i, from_cell: Vector2i) -> void:
	_leaving = true
	# If the step comes to nothing, back a little way in from the edge.
	var back := _here_payload()
	var inward := map.cell_at(_leader.position) - dir * 2
	back["spawn_cell"] = [inward.x, inward.y]
	EventBus.request_scene.emit("world", {
		"step": [dir.x, dir.y],
		"from_cell": [from_cell.x, from_cell.y],
		"held": _held,
		"back": back,
	})


## This ground as it is, to come back to: the same place, where the leader stands.
func _here_payload() -> Dictionary:
	var here := boot_payload.duplicate(true)
	for key: String in ["notes", "actions", "held"]:
		here.erase(key)
	if _leader != null:
		var cell := map.cell_at(_leader.position)
		if _land_mode:
			here.erase("spawn_cell")
			here["land_cell"] = [cell.x, cell.y]
			GameState.land_cell = cell
		else:
			here["spawn_cell"] = [cell.x, cell.y]
	return here


# --- bands, and the ground they watch (D66, D68) ---------------------------------


## Every band the world says is here, standing where it camps (or at the edge it watches from),
## patrolling its loop, with what it can see painted red ([AreaWatch]).
func _post_the_watch() -> void:
	if _leader == null:
		return
	_bands_told = boot_payload.get("bands", [])
	for band: Dictionary in _bands_told:
		_post_band(band)
	# Said once for all of them below, not once a band (play-test 6: "bombarded with text").
	_post_practice_bands(true)
	if not _watches.is_empty():
		_note("%s — the ground it can see is marked. Step onto it and it fights you, here." % _watches[0].band.get("label", "A band"))
		EventBus.tip_moment.emit("ground_watch", {})


## One band onto this ground, away from where the leader stands now. On the land, in the tile the
## continent has it on, once that tile is held.
func _post_band(band: Dictionary) -> Node2D:
	var arrived := map.cell_at(_leader.position)
	var taken := _cells_spoken_for(arrived)
	for other: Node2D in _watches:
		for cell: Vector2i in other.members:
			taken[cell] = true
	var keep_to := Rect2i()
	var told := band
	if _land_mode:
		var tile := AreaMap.to_cell(band.get("tile", [0, 0]))
		if not (map as Land).is_held(tile):
			return null
		keep_to = (map as Land).slot_rect(tile)
		told = band.duplicate()
		told["where"] = "here"
	# A trinket from a land journal keeps the party out of a band's eye a step or two longer ([D239]).
	var hush := LandJournals.effect(GameState.world, "hush") if _land_mode else 0.0
	var watch: Node2D = AreaWatch.place(map, told, arrived, taken, float(_land.get("sight", 0)) - hush, keep_to)
	if watch == null:
		return null
	_layers.add_child(watch)
	for figure: Node2D in watch.make_figures(_leader.position):
		_actors.add_child(figure)
	watch.can_move = func() -> bool: return not (_talking or _leaving or _spotted or _overlay_open())
	watch.moved.connect(_on_band_moved.bind(watch))
	_watches.append(watch)
	_warm_the_band(told)
	return watch


## A band's foes load a frame at a time while it is still walking about, the way the party's moves
## do (D122): a fight with foes never seen before stopped the game for up to seven seconds as it
## began (Ewan's play-test 8, D324). Whoever has joined since this place was entered is warmed too.
func _warm_the_band(band: Dictionary) -> void:
	for unit_id: Variant in band.get("pack", []):
		Database.warm_unit(str(unit_id))
	_warm_the_party()


## The continent's word on the bands about, after a step ([D84]): one that has moved tile walks
## there across the land; one newly near comes onto it once its tile is held; one gone (fought,
## or wandered far) goes.
func _sync_bands(bands: Array) -> void:
	if not _land_mode:
		return
	_bands_told = bands
	var by_key := {}
	for band: Dictionary in bands:
		by_key[str(band.get("key", ""))] = band
	for watch: Node2D in _watches.duplicate():
		var key := str(watch.band.get("key", ""))
		if bool(watch.band.get("spar", false)):
			continue
		if not by_key.has(key):
			_take_off(watch)
			continue
		var told: Dictionary = by_key[key]
		by_key.erase(key)
		var tile := AreaMap.to_cell(told.get("tile", [0, 0]))
		if watch.band.get("tile") != told.get("tile"):
			watch.band["tile"] = told.get("tile")
			if (map as Land).is_held(tile):
				watch.travel((map as Land).slot_rect(tile), map.cell_at(_leader.position))
			else:
				_take_off(watch)
	for key: String in by_key:
		_post_band(by_key[key])


## Bands the continent last said were about, for a tile laid out later to put down.
var _bands_told: Array = []


## A band off the land: its watch and its figures.
func _take_off(watch: Node2D) -> void:
	_watches.erase(watch)
	for figure: Node in watch.figures:
		if is_instance_valid(figure):
			figure.queue_free()
	watch.queue_free()


## A tile just laid out: any band the continent has on it that is not on the land yet comes onto it.
func _post_bands_for(tile: Vector2i) -> void:
	for band: Dictionary in _bands_told:
		if AreaMap.to_cell(band.get("tile", [0, 0])) != tile:
			continue
		var key := str(band.get("key", ""))
		if _watches.any(func(watch: Node2D) -> bool: return str(watch.band.get("key", "")) == key):
			continue
		_post_band(band)


## The area's own bands whose flags now let them be here and that are not here yet: at the start,
## and again whenever a flag may have changed (the tutorial sets one when its fight step begins).
func _post_practice_bands(quiet: bool = false) -> void:
	for band: Dictionary in map.bands:
		var key := str(band.get("key", ""))
		if _posted_practice.has(key) or not AreaMap._flags_allow(band):
			continue
		_posted_practice[key] = true
		var watch := _post_band(band)
		if watch != null and _leader != null and not _talking and not quiet:
			_note("%s — the ground it can see is marked. Step onto it and it fights you, here." % band.get("label", "A band"))


## Where nobody from a band may stand: where the party is, the ways out, doors, chests, spots,
## seats and everyone who lives here.
func _cells_spoken_for(arrived: Vector2i) -> Dictionary:
	var taken := {}
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			taken[arrived + Vector2i(dx, dy)] = true
	for cell: Vector2i in map.exits:
		taken[cell] = true
	for cell: Vector2i in map.spots:
		taken[cell] = true
	for cell: Vector2i in map.chests:
		taken[cell] = true
	for cell: Vector2i in _memories:
		taken[cell] = true
	for cell: Vector2i in map.seats:
		taken[cell] = true
	for building: Dictionary in map.buildings:
		taken[building["door"]] = true
		taken[building["door"] + Vector2i.DOWN] = true
	for person: Dictionary in map.people:
		taken[AreaMap.to_cell(person.get("cell", [0, 0]))] = true
	return taken


## The leader's step onto [param cell]: into a watched cell, and the band has seen them. Only a
## step counts — where the party was put down is not walking into anybody — and never while the
## party is walking itself (out on the continent, where it is jumped the old way).
func _check_the_watch(cell: Vector2i) -> bool:
	if _watches.is_empty():
		return false
	for watch: Node2D in _watches:
		watch.keep_an_eye_on(_leader.position)
	if cell == _last_cell:
		return false
	var came_from := _last_cell
	_last_cell = cell
	if came_from == Vector2i(-99, -99) or _spotted or _leaving or _talking:
		return false
	for watch: Node2D in _watches:
		if watch.watched.has(cell):
			_seen_by(watch, came_from)
			return true
	return false


## A patrolling band has walked somewhere it can see the party from: seen, as surely as walking in.
func _on_band_moved(watch: Node2D) -> void:
	if _leader == null or _spotted or _leaving or _talking:
		return
	if watch.watched.has(map.cell_at(_leader.position)):
		_seen_by(watch, Vector2i(-1, -1))


## Seen. Every head turns, the one in front shouts, the field is taken from where everyone stands,
## and the fight is on, on this ground at this view ([D66]); since [D204] nobody waits for the shout
## or a rush first: the band closes in fighting. Bursting out of cover at them is an ambush.
func _seen_by(watch: Node2D, came_from: Vector2i) -> void:
	_spotted = true
	_leaving = true
	_talking = true
	_approach = null
	_approach_path.clear()
	_hold_the_town(true)
	var ambush: bool = _striking_first or (map.in_bounds(came_from) and watch.in_cover(came_from))
	watch.raise_the_alarm(_leader.position, ambush)
	var many := (watch.band.get("pack", []) as Array).size() > 1
	if ambush and not _striking_first:
		_note("Out of the long grass and on %s before they know it." % str(watch.band.get("label", "them")))
	elif not ambush:
		_note("%s %s seen you!" % [str(watch.band.get("label", "Something")), "have" if many else "has"])
		# A beat for the shout to be read before they come, if the rules give one (none since D204:
		# the fight is on as they shout); an ambush never gives them one.
		var beat := float(AreaWatch.rule("spotted_seconds", 0.0))
		if beat > 0.0:
			await get_tree().create_timer(beat).timeout
	if not is_inside_tree():
		return
	# Where everyone stood when they were seen is where the fight is laid out, so it is taken
	# before the band closes in.
	var field := _field_for(watch, ambush)
	await _charge(watch)
	if not is_inside_tree():
		return
	_fight_watch = watch
	if bool(watch.band.get("spar", false)):
		_spar_with(watch, field, ambush)
		return
	if bool(watch.band.get("held", false)):
		_watch_fighting.clear()
		_call_the_climbers(field)
		_fight_held(watch, field, ambush)
		return
	_call_the_watch(field)
	_call_the_climbers(field)
	# The continent deals the band out and answers with the fight, which is put down right here.
	_awaiting_fight = true
	_ask_the_continent({ "fight": str(watch.band.get("key", "")), "field": field })


## Trouble led to the Watch ([D236], #270 keep 7): a pair of the Watch walking the road within
## `join_cells` sees the band set on the party, comes running and fights beside it, at the company's
## level. They are out of their walk while the fight lasts and back in it after; won, the continent
## pays their bounty.
func _call_the_watch(field: Dictionary) -> void:
	_watch_fighting.clear()
	if not _land_mode or _leader == null:
		return
	var rules: Dictionary = Database.world_rules.get("life", {}).get("road_watch", {})
	var reach := float(rules.get("join_cells", 0)) * AreaMap.CELL
	if reach <= 0.0:
		return
	var level := maxi(1, Encounter.party_level(GameState.party_characters()))
	var allies: Array = field.get("allies", [])
	for actor: AreaActor in _people:
		var person: Dictionary = actor.get_meta("person", {})
		if str(person.get("_area", "")) != "road_watch" or not actor.visible:
			continue
		if actor.position.distance_to(_leader.position) > reach:
			continue
		allies.append({ "unit": str(person.get("unit", "")), "level": level, "name": str(person.get("name", "a watchman")) })
		_watch_fighting.append(actor)
	if _watch_fighting.is_empty():
		return
	field["allies"] = allies
	field["watch"] = _watch_fighting.size()
	for actor: AreaActor in _watch_fighting:
		actor.visible = false
	_note(str(rules.get("joined_line", "The Watch come running.")))


## Another company within `join_cells` of a fight comes running and fights beside the party ([D246],
## play-test 6: "I think that the parties in the floor also will be fighting with you as well"):
## climbers on the road ([D215]) or resting on a Tower floor, at the company's level. Out of sight
## while it lasts, back where they were after, like the Watch. A company resting on a floor comes
## running to a fight anywhere on that floor when `on_the_floors.join_anywhere` says so (play-test 7:
## Hob's Lot sat by floor 2's stair while a poacher and a slime who spot the party up to twelve cells
## from there were fought, out of `join_cells`).
func _call_the_climbers(field: Dictionary) -> void:
	if _leader == null:
		return
	var rules: Dictionary = Database.world_rules.get("life", {}).get("climbers", {})
	var reach := float(rules.get("join_cells", 0)) * AreaMap.CELL
	if reach <= 0.0:
		return
	var whole_floor := bool((rules.get("on_the_floors", {}) as Dictionary).get("join_anywhere", false))
	var level := maxi(1, Encounter.party_level(GameState.party_characters()))
	var allies: Array = field.get("allies", [])
	var company := ""
	for actor: AreaActor in _people:
		var person: Dictionary = actor.get_meta("person", {})
		var area := str(person.get("_area", ""))
		if not ["climbers", "climbers_floor"].has(area) or not actor.visible:
			continue
		if not (whole_floor and area == "climbers_floor") and actor.position.distance_to(_leader.position) > reach:
			continue
		allies.append({ "unit": str(person.get("unit", "")), "level": level, "name": str(person.get("name", "a climber")) })
		_watch_fighting.append(actor)
		actor.visible = false
		company = str(person.get("name", "A company"))
	if company == "":
		return
	field["allies"] = allies
	_note(str(rules.get("joined_line", "%s join the fight.")).replace("%s", company.capitalize()))


## A practice band (`spar`): the same fight on the same ground, but as practice — nobody can
## die, nothing is counted or written to the world, everyone walks off whole — and straight back to
## this spot. Its `done_flag` is set, so it does not stand here again.
func _spar_with(watch: Node2D, field: Dictionary, ambush: bool) -> void:
	var done := str(watch.band.get("done_flag", ""))
	if done != "":
		GameState.set_flag(done)
	var enemies: Array = []
	for unit_id: Variant in watch.band.get("pack", []):
		enemies.append({ "unit": str(unit_id), "level": int(watch.band.get("level", 1)) })
	_fight_here({
		"encounter": { "enemies": enemies, "title": str(watch.band.get("label", "Sparring")), "ambush": ambush },
		"field": field,
		"sandbox": true,
	})


## A held band ([D102]): fought here for real, with no band on the continent behind it. What it
## is worth is settled by the continent like any fight (deaths, experience, the run's end); won,
## its `done_flag` keeps it gone. Lost, or got clear of, and the party is back down the stair.
func _fight_held(watch: Node2D, field: Dictionary, ambush: bool) -> void:
	var enemies: Array = []
	var level := int(watch.band.get("level", 1))
	var boss := bool(watch.band.get("boss", false))
	var first := true
	for unit_id: Variant in watch.band.get("pack", []):
		var foe := { "unit": str(unit_id), "level": level }
		if boss and first:
			foe["boss"] = true
			# A big gate's keeper takes minutes to put down, not seconds (play-test 7, D261).
			if float(watch.band.get("stout", 1.0)) > 1.0:
				foe["stout"] = float(watch.band["stout"])
		first = false
		enemies.append(foe)
	GameState.pending_outcome = {
		"kind": "tower_band", "enemies": enemies,
		"lost": str(watch.band.get("lost", "You come back down the stair, and they are still up there.")),
	}
	# On a shared Tower floor the company climbing it fights beside the party ([D307]).
	if _tower_floor > 0 and not _in_a_gate() and not (boot_payload.get("allies", []) as Array).is_empty():
		var with_you: Array = field.get("allies", [])
		for ally: Dictionary in boot_payload.get("allies", []):
			with_you.append(ally.duplicate())
		field["allies"] = with_you
	if _in_a_gate():
		# Lost inside a gate, the delve is lost with it: back out at its mouth, its floors filled in.
		GameState.pending_outcome = {
			"kind": "gate_band", "cell": _gate_cell, "enemies": enemies,
			"lost": "You are thrown back out of the gate's mouth.",
		}
		# Whoever the Guild sent in with the party fights every fight in here beside it (D147).
		var allies: Array = field.get("allies", [])
		for ally: Dictionary in boot_payload.get("allies", []):
			allies.append(ally.duplicate())
		if not allies.is_empty():
			field["allies"] = allies
	_held_done = str(watch.band.get("done_flag", ""))
	# D184 (D174): the floor 5 keeper speaks as its fight begins, and knows which of the sixteen
	# this lead is. Shown the way Sennet's word is (D161); a fight played by hand waits for the box.
	var lead := GameState.roster.player() if GameState.roster != null else null
	var said := FirstHour.warden_line(str(watch.band.get("key", "")),
			lead.template_id if lead != null else "", lead.display_name if lead != null else "")
	if not said.is_empty():
		_note("%s: %s" % [said["speaker"], said["text"]])
	_fight_here({
		"encounter": {
			"enemies": enemies, "title": str(watch.band.get("label", "A fight")), "ambush": ambush,
			# Inside a gate, or a cave laid out like one, a first of a kind teaches (D301).
			"teaches": _in_a_gate() or bool(Database.area(map.id).get("teaches", false)),
		},
		"field": field,
	})
	if not said.is_empty():
		EventBus.conversation_requested.emit([said])


## A held band's fight, settled: won, it stays gone; anything else, and the party is back at the
## Tower's foot (unless the run is over, when the continent has the screen).
func _after_held_fight() -> void:
	var how := _held_fight
	_held_fight = ""
	var done := _held_done
	_held_done = ""
	if how == "":
		return
	if how == "won":
		if done != "":
			GameState.set_flag(done)
		# Walked by Auto, the next band (or the way down) is made for afresh.
		_auto_exit_path.clear()
		if _in_a_gate() and done != "" and done == _gate_keeper:
			_scatter_the_rest()
		return
	if GameState.roster.run_is_over():
		return
	_leaving = true
	EventBus.request_scene.emit(_return_scene, _return_payload)


## A gate's keeper down: whatever else stands in it breaks and runs (play-test 7: "killing the lord and
## the monsters scatter away and they don't fight").
func _scatter_the_rest() -> void:
	var fled := false
	for watch: Node2D in _watches.duplicate():
		var flag := str(watch.band.get("done_flag", ""))
		if flag != "":
			GameState.set_flag(flag)
		_take_off(watch)
		fled = true
	_auto_exit_path.clear()
	if fled:
		_note(str(GateInside.rules().get("scatter_line", "")))


## Whatever the lead left of themselves on this ground (D103), put down where it lies.
func _lay_out_memories() -> void:
	if _land_mode or GameState.roster == null or GameState.roster.player() == null:
		return
	var area_id := str(boot_payload.get("area_id", ""))
	# A floor walked on another's plan (D207) is not where that floor's keepsakes lie.
	if _tower_floor > 0 and TowerFloors.Chapters.borrows_a_plan(_tower_floor):
		return
	for memory: Dictionary in Memories.lying_in(area_id, GameState.roster.player().template_id):
		var cell := Memories.cell_of(memory)
		map.place({ "art": str(memory.get("art", "coin_pile")), "cell": cell, "name": str(memory.get("object", "something")) })
		_memories[cell] = memory


## The lead picks it up: a chapter of who they were comes back, and the journal has it.
func _remember(cell: Vector2i) -> void:
	var memory: Dictionary = _memories[cell]
	_memories.erase(cell)
	_auto_exit_path.clear()
	var scene_id := "memory_%s" % str(memory.get("id", ""))
	Database.register_dialogue(scene_id, Memories.find(memory))
	EventBus.dialogue_requested.emit(scene_id)


## The stair up: the floor is won, and the continent pays it out as it paid a floor fought on the
## fight screen ([D102]), then opens the next floor straight away (D115).
func _climb_the_stair() -> void:
	if _leaving:
		return
	if not _way_down_open():
		_note(_way_down_shut_line())
		return
	_leaving = true
	var world: World = GameState.world
	if _in_a_gate():
		# The floor is won: the continent pays it out as a gate floor fought at the door was (or shuts
		# the gate, on its last), then opens the next floor straight away (D248).
		GameState.pending_outcome = { "kind": "gate", "cell": _gate_cell, "final": _gate_final, "walked": true }
		GameState.set_flag("last_victory", true)
		EventBus.request_scene.emit("world", { "gate_on": true })
		return
	var tower := world.tower()
	GameState.pending_outcome = {
		"kind": "tower", "cell": tower.cell if tower != null else world.player_cell, "floor": _tower_floor,
	}
	GameState.set_flag("last_victory", true)
	EventBus.request_scene.emit("world", { "climb_on": true })


## A band the lead could strike first ([D288], [D300]): one of its figures within
## `first_strike_reach` cells, and the leader standing out of its sight. The nearest, or null.
func _strike_target() -> Node2D:
	if _leader == null or _spotted or _leaving or _talking or _winding_up or _fight != null:
		return null
	var reach := float(AreaWatch.rule("first_strike_reach", 0)) * AreaMap.CELL
	if reach <= 0.0:
		return null
	var here := map.cell_at(_leader.position)
	var best: Node2D = null
	var nearest := reach
	for watch: Node2D in _watches:
		if watch.watched.has(here) or watch.figures.is_empty():
			continue
		for figure: Node2D in watch.figures:
			var apart := figure.position.distance_to(_leader.position)
			if apart <= nearest:
				nearest = apart
				best = watch
	return best


## The lead turns to the band and winds up ([D300]); a moment later the blow is loosed and the
## fight is on, opened by it. Seen first, while winding up, and the strike is lost.
func _wind_up(watch: Node2D) -> void:
	_winding_up = true
	_approach = null
	_approach_path.clear()
	_click_path.clear()
	if not watch.figures.is_empty():
		_leader.face((watch.figures[0] as Node2D).position - _leader.position)
	_note("%s winds up a strike..." % (_leader_character.display_name if _leader_character != null else "The lead"))
	var wind := create_tween()
	wind.tween_property(_leader, "modulate", Color(1.6, 1.3, 0.8), float(AreaWatch.rule("first_strike_seconds", 0.8)))
	await wind.finished
	if not is_inside_tree():
		return
	_winding_up = false
	if _leader != null:
		_leader.modulate = Color.WHITE
	if _spotted or _leaving or _talking or not _watches.has(watch):
		return
	_striking_first = true
	_seen_by(watch, Vector2i(-1, -1))


## The band rushes the party: part of the way, facing them, so the fight opening is something
## seen happen rather than a cut.
func _charge(watch: Node2D) -> void:
	var figures: Array = watch.figures
	if figures.is_empty() or _leader == null:
		return
	# No rush before the fight (D204): they close in fighting, from where they stood.
	if float(AreaWatch.rule("charge_seconds", 0.0)) <= 0.0:
		_leader.face((figures[0] as Node2D).position - _leader.position)
		return
	var rush := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	var share := float(AreaWatch.rule("charge_share", 0.55))
	for figure: Node2D in figures:
		var towards := _leader.position - figure.position
		figure.face(towards)
		rush.tween_property(figure, "position", figure.position + towards * share, float(AreaWatch.rule("charge_seconds", 0.45)))
	_leader.face((figures[0] as Node2D).position - _leader.position)
	await rush.finished


## The fight, put down on this ground (step 4 of the First Hour): moved and scaled so each of its
## cells is one of the ground's, opening running, with the ground's camera and nothing else changing.
## The party and the band's figures step aside for the fighters while it lasts.
func _fight_here(payload: Dictionary) -> void:
	_clear_roadside()
	var asked := payload.duplicate()
	asked["in_place"] = true
	asked["paused"] = false
	if _striking_first:
		_striking_first = false
		var encounter: Dictionary = (asked.get("encounter", {}) as Dictionary).duplicate()
		encounter["first_strike"] = true
		encounter["ambush"] = true
		# Not "… have seen you": they had not.
		if _fight_watch != null and is_instance_valid(_fight_watch):
			encounter["title"] = str(AreaWatch.rule("first_strike_title", "{band}, struck first")).format(
					{"band": str(_fight_watch.band.get("label", "them"))})
		asked["encounter"] = encounter
	# AM (D150): a party walking itself stops for a fight that matters and hands it over, paused;
	# it walks on by itself again once that fight is won.
	var lead := GameState.roster.player() if GameState.roster != null else null
	var stops := Pace.auto and not bool(asked.get("sandbox", false)) and FirstHour.auto_stops_for(
			(asked.get("encounter", {}) as Dictionary).get("enemies", []),
			str(GameState.pending_outcome.get("kind", "")), lead.level if lead != null else 1)
	# A band of the land is fought running, Auto or not ([D288], [D300]): Auto says it is a hard one
	# and fights on, and Q still takes it back. Gates and keepers still stop and hand it over.
	if stops and str((asked.get("encounter", {}) as Dictionary).get("kind", "")) == Encounter.WILD:
		stops = false
		_note(FirstHour.auto_runs_line())
	if stops:
		Pace.auto = false
		_auto_after_fight = true
		asked["paused"] = true
		asked["auto_stopped"] = FirstHour.auto_stop_line()
	asked.erase("return_scene")
	asked.erase("return_payload")
	var field: Dictionary = asked.get("field", {})
	var origin := AreaMap.to_cell(field.get("origin", [0, 0]))
	_fight = SKIRMISH.instantiate()
	_fight.set("boot_payload", asked)
	_fight.position = Vector2(origin) * AreaMap.CELL
	_fight.scale = Vector2.ONE * (float(AreaMap.CELL) / float(BattleGrid.CELL_SIZE))
	_fight.z_index = 1
	if _fight_watch != null and is_instance_valid(_fight_watch):
		_take_off(_fight_watch)
	_fight_watch = null
	for actor: AreaActor in [_leader] + _followers:
		actor.visible = false
	$UI.visible = false
	_spotted = true
	_leaving = true
	_talking = true
	add_child(_fight)
	_fight.connect("gone", _after_the_fight)


## The ground's camera keeps the fight in view: the middle of whoever of the party is still on it.
func _watch_the_fight() -> void:
	var middle := Vector2.ZERO
	var count := 0
	for f: RefCounted in _fight.call("party_fighters"):
		if f.call("is_standing"):
			middle += _fight.to_global((f.get("unit") as Node2D).position)
			count += 1
	if count > 0:
		_camera.focus_on(to_local(middle / float(count)))


## Over: the party stands where its fighters stood, the dead are gone from it, and the continent
## is asked to settle what the fight was worth (it reads what the fight wrote down).
func _after_the_fight() -> void:
	if _fight == null:
		return
	var sandbox := bool((_fight.get("boot_payload") as Dictionary).get("sandbox", false))
	var stood := _leader.position
	for f: RefCounted in _fight.call("party_fighters"):
		var unit := f.get("unit") as Node2D
		if f.get("aboard") == null and not bool(f.get("fallen")):
			stood = to_local(_fight.to_global(unit.position))
			if (f.get("unit").get("character") as Character) == _leader_character:
				break
	if not sandbox and _walked_floor():
		_held_fight = "won" if bool(_fight.get("victory")) else ("fled" if bool(_fight.get("fled_field")) else "lost")
	if _auto_after_fight:
		_auto_after_fight = false
		if bool(_fight.get("victory")):
			Pace.auto = true
	_fight.queue_free()
	_fight = null
	for actor: AreaActor in _watch_fighting:
		if is_instance_valid(actor):
			actor.visible = true
	_watch_fighting.clear()
	$UI.visible = true
	_regather_at(stood)
	_stand_down()
	if not sandbox:
		_settling = true
		_ask_the_continent({})


## Whoever has joined since the party was put down (one of the sixteen agreeing to walk with you)
## falls in behind it, so a companion is seen following from the moment they join.
func _fall_in() -> void:
	if _leader == null or _fight != null:
		return
	if GameState.party_characters().size() == _followers.size() + 1:
		return
	_regather_at(_leader.position)


## The party as it is now (the fallen gone from it), standing round [param point].
func _regather_at(point: Vector2) -> void:
	for actor: AreaActor in [_leader] + _followers:
		if is_instance_valid(actor):
			actor.queue_free()
	_leader = null
	_followers.clear()
	# Put back somewhere else, the way Auto was walking is no way from here ([D197]: on floor 4 it
	# kept making for a waypoint behind a wall after a fight and stood there for good).
	_auto_exit_path.clear()
	_auto_exit_index = 0
	_auto_door_path.clear()
	var at := map.cell_at(point)
	if not map.is_walkable(at):
		at = _free_spot_near(at)
	var members := GameState.party_characters()
	for index in members.size():
		var actor := AreaActor.for_character(members[index])
		actor.position = map.centre_of(at)
		_actors.add_child(actor)
		if index == 0:
			_leader = actor
			_leader_character = members[index]
		else:
			_followers.append(actor)
	if _leader == null:
		return
	_reseed_crumbs()
	for i in _followers.size():
		_followers[i].position = _point_along_trail((i + 1) * FOLLOWER_DISTANCE)
	_camera.focus_on(_leader.position)


## Back to walking: nobody is looking, the town moves again, and the cell stood on is not a fresh
## step into anyone's sight.
func _stand_down() -> void:
	_striking_first = false
	_spotted = false
	_leaving = false
	_talking = false
	_hold_the_town(false)
	if _leader != null:
		_leader.visible = true
		for follower in _followers:
			follower.visible = true
		_last_cell = map.cell_at(_leader.position)
	_hint.text = _prompt_text()


## The patch of this ground the fight is fought on: everyone in it, with room round them, cut to
## the ground's edges; and the view the ground was seen in, for the fight to open on.
func _field_for(watch: Node2D, ambush: bool) -> Dictionary:
	var foes: Array = []
	for figure: Node2D in watch.figures:
		var c := map.cell_at(figure.position)
		foes.append([c.x, c.y])
	return _field_round(foes, ambush)


## The patch of ground a gate's fight is fought on (D162): the party where it stands, and whatever
## keeps the gate come out of its doorway (the gate's standing stones, its landmark) towards them.
## With no doorway in reach they stand a few strides ahead. The doorway's front is the floor's heart.
func _gate_field() -> Dictionary:
	var here := map.cell_at(_leader.position)
	var door := Vector2i(-1, -1)
	var best := GATE_REACH + 1.0
	for prop: Dictionary in map.props:
		if not str(prop.get("art", "")).contains("gate"):
			continue
		var at: Vector2i = prop["cell"]
		var apart := Vector2(at - here).length()
		if apart < best:
			best = apart
			door = at
	if door.x < 0:
		door = here + Vector2i(0, -5)
	var towards := Vector2i(signi(here.x - door.x), signi(here.y - door.y))
	if towards == Vector2i.ZERO:
		towards = Vector2i.DOWN
	var front := door + towards * 2
	var foes: Array = []
	for side: Vector2i in [Vector2i.ZERO, Vector2i(-1, 0), Vector2i(1, 0), towards]:
		var c := front + side
		foes.append([c.x, c.y])
	var field := _field_round(foes, false)
	field["heart"] = [door.x + towards.x, door.y + towards.y]
	return field


## The patch of ground a roadside fight is fought on ([D207]): the party where it stands and the
## attackers where the scene stages them; with nothing staged, just ahead of the party.
func _roadside_field() -> Dictionary:
	var foes: Array = []
	for node: Node2D in _roadside_foes:
		if is_instance_valid(node):
			var c := map.cell_at(node.position)
			foes.append([c.x, c.y])
	return _field_round(foes, false) if not foes.is_empty() else _field_ahead()


## The patch of ground a fight with nobody yet standing on it is fought on ([D207]): a town's raiders,
## its guards, a captive's keepers. The party where it stands, and them a few strides ahead of it.
func _field_ahead() -> Dictionary:
	var here := map.cell_at(_leader.position)
	var ahead := Vector2i((_leader.get("_facing") as Vector2).round()) if _leader.get("_facing") is Vector2 else Vector2i.DOWN
	if ahead == Vector2i.ZERO:
		ahead = Vector2i.DOWN
	var front := here + ahead * 5
	var foes: Array = []
	for side: Vector2i in [Vector2i.ZERO, Vector2i(ahead.y, ahead.x), Vector2i(-ahead.y, -ahead.x), ahead]:
		var c := _free_spot_near(front + side)
		foes.append([c.x, c.y])
	return _field_round(foes, false)


func _field_round(foes: Array, ambush: bool) -> Dictionary:
	var party: Array = []
	for actor: AreaActor in [_leader] + _followers:
		var c := map.cell_at(actor.position)
		party.append([c.x, c.y])
	var margin := int(AreaWatch.rule("field_margin", 3))
	var smallest := _pair_rule("field_smallest", Vector2i(16, 11))
	var largest := _pair_rule("field_largest", Vector2i(26, 16))
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for pair: Array in party + foes:
		lo = Vector2i(mini(lo.x, int(pair[0])), mini(lo.y, int(pair[1])))
		hi = Vector2i(maxi(hi.x, int(pair[0])), maxi(hi.y, int(pair[1])))
	lo -= Vector2i.ONE * margin
	hi += Vector2i.ONE * margin
	var size := (hi - lo + Vector2i.ONE).clamp(smallest, largest)
	var room := map.bounds()
	size = Vector2i(mini(size.x, room.size.x), mini(size.y, room.size.y))
	var centre := (lo + hi) / 2
	var origin := (centre - size / 2).clamp(room.position, room.end - size)
	var seen_at := _camera.get_screen_center_position()
	return {
		"area_id": map.id, "land": _land_mode, "origin": [origin.x, origin.y], "size": [size.x, size.y],
		"party": party, "foes": foes, "title": boot_payload.get("title", map.display_name),
		"ambush": ambush,
		# The camera as it was, in ground pixels: the fight opens on exactly this, then draws back.
		"view": { "centre": [seen_at.x, seen_at.y], "zoom": _camera.zoom.x },
	}


func _pair_rule(key: String, fallback: Vector2i) -> Vector2i:
	var value: Variant = AreaWatch.rule(key, [])
	return Vector2i(int(value[0]), int(value[1])) if value is Array and (value as Array).size() >= 2 else fallback


# --- the place's doings, and the map --------------------------------------------


## The journal's Map: the continent, and back to this spot after.
func _open_the_map() -> void:
	if _leaving or not is_inside_tree():
		return
	# On the land the map opens over the ground and the party walks on under it (D232); inside a
	# place, or on a floor of the Tower, the continent opens as it always has.
	if _map_screen != null:
		_map_screen.toggle()
		_quiet_while_spoken_to()
		return
	_leaving = true
	var back := _here_payload()
	back["held"] = _held
	back["actions"] = _acts
	EventBus.request_scene.emit("world", { "map": true, "back": back })


func _acts_text() -> String:
	var said: Array[String] = []
	for each: Dictionary in _acts:
		said.append(str(each.get("prompt", "")))
	return "  ·  ".join(said)


## The doing a key asks for here, or an empty dictionary. Interact is the
## place's only while there is nobody close enough to speak to.
func _act_for(event: InputEvent) -> Dictionary:
	if not event.is_pressed() or event.is_echo():
		return {}
	for each: Dictionary in _acts:
		var key: Variant = each.get("key", "")
		if str(each.get("act", "")) == "":
			continue
		if key is String and str(key) != "":
			if event.is_action_pressed(str(key)) and not (str(key) == "interact" and _nearby != null):
				return each
		elif (key is int or key is float) and event is InputEventKey and event.keycode == int(key):
			return each
	return {}


func _do_act(each: Dictionary) -> void:
	if _leaving or _talking:
		return
	var act := str(each.get("act", ""))
	# A gate far above the company asks twice ([D246], play-test 6: a level 9 company walked into an
	# S-rank gate by the Tower and met its level 19 keepers without a word of warning).
	if act == "_enter_gate_here" and not _sure_of_the_gate():
		return
	if GROUND_FIGHT_ACTS.has(act):
		# Gone into here, not on a fight screen (D162, D207): the continent deals the fight and it is
		# put down on this ground, the way a band met on it is.
		if not _asking:
			_awaiting_fight = true
			_talking = true
			var field := _gate_field() if act == "_enter_gate_here" \
				else (_roadside_field() if act == "_step_into_the_road" else _field_ahead())
			_ask_the_continent({ "act": act, "field": field })
		return
	if _land_mode:
		# Done out of sight, and the party stays where it stands.
		if not _asking:
			_ask_the_continent({ "act": str(each.get("act", "")) })
		return
	_leaving = true
	EventBus.request_scene.emit("world", {
		"act": str(each.get("act", "")),
		"held": _held,
		"back": _here_payload(),
	})


## A thumb or a pad has no H to press, so the place's doings are buttons too,
## the same list the hint line reads.
func _lay_out_acts() -> void:
	if _act_bar != null:
		_act_bar.queue_free()
		_act_bar = null
	if not (Pace.is_touch_enabled() or Pad.using_pad):
		return
	var pressable: Array = _acts.filter(func(each: Dictionary) -> bool: return str(each.get("label", "")) != "")
	if pressable.is_empty():
		return
	_act_bar = HFlowContainer.new()
	_act_bar.anchor_left = 0.5
	_act_bar.anchor_right = 0.5
	_act_bar.anchor_top = 1.0
	_act_bar.anchor_bottom = 1.0
	_act_bar.offset_left = -320.0
	_act_bar.offset_right = 320.0
	_act_bar.offset_top = -300.0
	_act_bar.offset_bottom = -120.0
	_act_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_act_bar.alignment = FlowContainer.ALIGNMENT_CENTER
	_act_bar.add_theme_constant_override("h_separation", 8)
	_act_bar.add_theme_constant_override("v_separation", 8)
	_hint.get_parent().add_child(_act_bar)
	for each: Dictionary in pressable:
		var button := Button.new()
		button.text = str(each["label"])
		button.focus_mode = Control.FOCUS_ALL if Pad.using_pad else Control.FOCUS_NONE
		button.custom_minimum_size = Vector2(0, 56)
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_do_act.bind(each))
		Sfx.attend(button)
		_act_bar.add_child(button)


## How a chest looks once opened: its own `opened_art`, else its art's open drawing if one is
## drawn (`chest` -> `chest_open`), else as it was. A broken or iron chest no longer turns into a
## plain wooden one when it is opened (Ewan's play-test 2).
func _opened_art(chest: Dictionary) -> String:
	if chest.has("opened_art"):
		return str(chest["opened_art"])
	var shut := str(chest.get("art", "chest"))
	return "%s_open" % shut if AreaProp.has_art("%s_open" % shut) else shut


func _picking_an_act() -> bool:
	var owner := get_viewport().gui_get_focus_owner()
	return owner != null and _act_bar != null and _act_bar.is_ancestor_of(owner)


## Whatever is in it is written into the area, so the same chest always holds
## the same thing — but it only holds it once.
func _open_chest(cell: Vector2i) -> void:
	var chest: Dictionary = map.chests[cell]
	if bool(chest.get("stash", false)):
		_note(chest.get("line", "The strongbox travels with you. Whatever nobody is carrying ends up in it."))
		EventBus.stash_requested.emit()
		return
	var flag := map.chest_flag(cell)
	if GameState.has_flag(flag):
		return
	GameState.set_flag(flag)
	Ledger.add(GameState.ledger, "chests_opened")
	EventBus.player_did.emit("chest")

	_note(chest.get("line", "A chest, and nobody watching it."))
	if _chest_props.has(cell):
		_chest_props[cell].set_art(_opened_art(chest))
	var haul := chest.duplicate()
	haul["map"] = Atlas.finds_map(GameState.world, flag, "chest_map_chance")
	for line: String in Loot.claim(haul, GameState.roster):
		_note(line)


func _leave() -> void:
	_leaving = true
	EventBus.request_scene.emit(_return_scene, _return_payload)


## Inside is another area, and the way back out is this doorstep.
func _enter(building: Dictionary) -> void:
	var inside: String = building.get("area", "")
	EventBus.player_did.emit("door:%s" % str(building.get("name", "")))
	# A door that only opens once something is yours (`area_requires`; your house, D252).
	var title := str(building.get("name", ""))
	if building.has("area_requires"):
		for flag: String in building["area_requires"]:
			if not GameState.has_flag(flag):
				inside = ""
		if inside != "":
			title = str(building.get("owned_name", title))
	if building.has("fight"):
		_spar(building)
		return
	# A cave under the hill (D282): laid out as the party walks in, for the party it is.
	if building.has("cave"):
		inside = Caves.area_for(GameState.world, AreaMap.to_cell(building["cave"]), GameState.party_characters())
	# Hidden for the First Hour (D97), the coliseum's door is only a shut door.
	if inside == "coliseum" and not FirstHour.hides("coliseum"):
		_leaving = true
		var doorstep := map.step_out_of(building)
		var outside := _doorstep_payload(doorstep)
		EventBus.request_scene.emit("coliseum", {
			"live_run": true,
			"return_scene": "area",
			"return_payload": outside,
		})
		return
	if not Database.has_area(inside):
		var shut: Variant = building.get("shut", "The door is shut, and stays shut.")
		_note(str(shut.pick_random()) if shut is Array and not shut.is_empty() else str(shut))
		return
	_leaving = true
	var doorstep := map.step_out_of(building)
	# The way back out is this ground as it was, so the street still knows it
	# is part of the continent and what the place offers.
	var outside := _doorstep_payload(doorstep)
	EventBus.request_scene.emit("area", {
		"area_id": inside,
		"title": title,
		"return_scene": "area",
		"return_payload": outside,
	})


## This ground to come back out to, on [param doorstep]: the land where it stands, or the area.
func _doorstep_payload(doorstep: Vector2i) -> Dictionary:
	var outside := boot_payload.duplicate(true)
	outside.erase("notes")
	if _land_mode:
		outside.erase("spawn_cell")
		outside["land_cell"] = [doorstep.x, doorstep.y]
		outside["held"] = _held
		outside["actions"] = _acts
		GameState.land_cell = doorstep
	else:
		outside["spawn_cell"] = [doorstep.x, doorstep.y]
	return outside


## A door that is a fight (`fight` on the building): through it to a real-time skirmish on the
## ground it names, against whoever it names, and back out of the same door after. Nothing in it
## counts: a training fight heals everyone at the end.
func _spar(building: Dictionary) -> void:
	var fight: Dictionary = building["fight"]
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var terrain_id := str(fight.get("terrain", "grass"))
	var battlefield := BattleMapGen.generate_on(
		terrain_id, str(fight.get("title", building.get("name", "a fight"))), fight.get("enemies", []), rng
	)
	_leaving = true
	var doorstep := map.step_out_of(building)
	EventBus.request_scene.emit(str(fight.get("scene", "skirmish")), {
		"encounter": { "map": battlefield, "title": str(fight.get("title", "Sparring")) },
		"sandbox": true,
		"return_scene": "area",
		"return_payload": {
			"area_id": map.id,
			"title": boot_payload.get("title", map.display_name),
			"return_scene": _return_scene,
			"return_payload": _return_payload,
			"spawn_cell": [doorstep.x, doorstep.y],
		},
	})


## Hand the reins to the next of the party; the two of them trade places so
## whoever is walking is always the one out in front.
func _cycle_leader() -> void:
	if _followers.is_empty():
		return
	var next: AreaActor = _followers.pop_front()
	var front := _leader.position
	_leader.position = next.position
	next.position = front
	_followers.append(_leader)
	_leader = next
	for c: Character in GameState.party_characters():
		if c.display_name == _leader.display_name:
			_leader_character = c
			break
	_reseed_crumbs()
	_camera.focus_on(_leader.position)
	_note("%s takes the lead." % _leader.display_name)


func _reseed_crumbs() -> void:
	if _followers.is_empty() or _leader == null:
		return
	_crumbs.clear()
	var points: Array[Vector2] = [_leader.position]
	for follower in _followers:
		points.append(follower.position)
	for seg in range(points.size() - 1):
		var p0: Vector2 = points[seg]
		var p1: Vector2 = points[seg + 1]
		var seg_len := p0.distance_to(p1)
		var steps_count := maxi(1, roundi(seg_len / CRUMB_SPACING))
		for step in range(steps_count):
			var t := float(step) / float(steps_count)
			_crumbs.append(p0.lerp(p1, t))
	_crumbs.append(points.back())


func _note(line: String) -> void:
	if line == "":
		return
	if _overlay_open():
		_held_notes.append(line)
		return
	# The same line again says nothing new.
	if not _notes.is_empty() and _notes.back() == line:
		return
	_notes.append(line)
	_note_times.append(Time.get_ticks_msec())
	if _notes.size() > 3:
		_notes = _notes.slice(_notes.size() - 3)
		_note_times = _note_times.slice(_note_times.size() - 3)
	_show_the_log()


## The log as it stands, on a faint backing while it says anything ([D246]).
func _show_the_log() -> void:
	_log.text = "\n".join(_notes)
	_log.add_theme_stylebox_override("normal", _quiet_backing() if not _notes.is_empty() else StyleBoxEmpty.new())


## Lines that have been up `NOTE_SECONDS` of the player's time go ([D246], play-test 6: "you get
## bombarded with text at the bottom of the screen. I think it should be a lot more sleeker").
func _let_old_notes_go() -> void:
	# The hint line's strip only while it says something.
	var hint_backed := _hint.text.strip_edges() != ""
	if hint_backed != _hint_backed:
		_hint_backed = hint_backed
		_hint.add_theme_stylebox_override("normal", _quiet_backing() if hint_backed else StyleBoxEmpty.new())
	if _hint.text != _hint_fitted:
		_fit_the_hint()
	if _notes.is_empty():
		return
	var now := Time.get_ticks_msec()
	var kept: Array[String] = []
	var kept_times: Array[int] = []
	for i in _notes.size():
		if now - _note_times[i] < int(NOTE_SECONDS * 1000.0):
			kept.append(_notes[i])
			kept_times.append(_note_times[i])
	if kept.size() != _notes.size():
		_notes = kept
		_note_times = kept_times
		_show_the_log()


## A faint dark strip behind the log and the hint line, so they read over any ground.
func _quiet_backing() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.04, 0.06, 0.55)
	box.set_corner_radius_all(4)
	box.content_margin_left = 8.0
	box.content_margin_right = 8.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	return box


## The log is laid out 900 wide; on a screen narrower than that (a phone held upright, D163) it
## wraps inside the screen instead of running off its edge.
func _fit_the_log() -> void:
	if not is_inside_tree():
		return
	_log.offset_right = minf(LOG_WIDTH, get_viewport().get_visible_rect().size.x - 16.0)


## The hint line's strip is as long as what it says (play-test 7: "the text boxes around the text
## are way too big. At the bottom of my screen"), not the width of the screen; a line too long for
## the screen still stops at its edge and is cut short ([D246]).
func _fit_the_hint() -> void:
	if not is_inside_tree():
		return
	_hint_fitted = _hint.text
	var font := _hint.get_theme_font("font")
	var wanted := font.get_string_size(_hint.text, HORIZONTAL_ALIGNMENT_LEFT, -1, _hint.get_theme_font_size("font_size")).x
	wanted += _quiet_backing().get_minimum_size().x + 2.0
	var room := get_viewport().get_visible_rect().size.x - _hint.offset_left - 16.0
	_hint.anchor_right = 0.0
	_hint.offset_right = _hint.offset_left + minf(wanted, room)


## One message at a time (D95): while a box is open (the landing's words, a
## screen) the log, the hint line and the act bar keep out of its way, and notes
## wait for it to close.
func _quiet_while_spoken_to() -> void:
	var quiet := _overlay_open()
	_log.visible = not quiet
	_hint.visible = not quiet
	if _compass != null:
		_compass.visible = not quiet and _compass.has_meta("aimed")
	if _corner_map != null:
		_corner_map.visible = not quiet and not _map_open()
	if _act_bar != null:
		_act_bar.visible = not quiet
	if not quiet and not _held_notes.is_empty():
		var held := _held_notes.duplicate()
		_held_notes.clear()
		for line: String in held:
			_note(line)


## The corner map and the large one ([D232]): the corner map in the top right, under the touch
## bar when there is one; a click on it opens the large map, which opens over the ground.
func _put_up_the_maps() -> void:
	_corner_map = LandMap.new()
	_corner_map.full = false
	_corner_map.cell_px = CORNER_MAP_CELL
	_corner_map.size = Vector2.ONE * CORNER_MAP_SIZE
	_corner_map.anchor_left = 1.0
	_corner_map.anchor_right = 1.0
	_corner_map.offset_left = -CORNER_MAP_SIZE - 14.0
	_corner_map.offset_right = -14.0
	_corner_map.offset_top = 14.0 + (TouchControls.BAR_DROP if Pace.is_touch_enabled() else 0.0)
	_corner_map.offset_bottom = _corner_map.offset_top + CORNER_MAP_SIZE
	_corner_map.tooltip_text = "Click to open the map (M). Right-click a place: Go here, or Place a marker."
	_place.get_parent().add_child(_corner_map)
	_corner_map.said.connect(_note)
	_corner_map.open_requested.connect(_open_the_map)
	_map_screen = LandMapScreen.new()
	add_child(_map_screen)
	_map_screen.said.connect(_note)
	_map_screen.closed.connect(_quiet_while_spoken_to)


func _map_open() -> bool:
	return _map_screen != null and _map_screen.is_open()


## Aim the compass at the objective ([method AutoRoad.objective]). On the land it
## points from where the leader stands to the middle of the objective's tile;
## inside a place, from the place's tile.
func _point_the_compass() -> void:
	if _compass == null or GameState.world == null:
		return
	var world: World = GameState.world
	# A room paid for here: the needle goes to its bed (D242).
	var bed := _your_bed()
	if bed.x >= 0 and _leader != null:
		_compass.set_meta("aimed", true)
		_compass.visible = not _overlay_open()
		_compass.point(Vector2(bed - map.cell_at(_leader.position)), "Your room", 0)
		return
	# On a floor of the Tower the only way on is the stair up (D102), and a memory lying there is
	# pointed at first, so nobody walks past it (D107).
	if _walked_floor() and not map.stairs.is_empty() and _leader != null:
		_compass.set_meta("aimed", true)
		_compass.visible = not _overlay_open()
		var here := map.cell_at(_leader.position)
		if not _memories.is_empty():
			var glint: Vector2i = _memories.keys()[0]
			_compass.point(Vector2(glint - here), "Something glints", 0)
			return
		var keeper := _keeper_cell()
		if keeper.x >= 0:
			_compass.point(Vector2(keeper - here), "Its keeper", 0)
			return
		_compass.point(Vector2(map.stairs[0] - here),
			("The way down" if not _gate_final else "The far side") if _in_a_gate() else "The stair to floor %d" % (_tower_floor + 1), 0)
		return
	var tower := world.tower()
	if _far_tower != null and _leader != null and tower != null:
		var land_of := map as Land
		_far_tower.look_towards(
			Vector2(tower.cell * land_of.slot + land_of.slot / 2) - Vector2(map.cell_at(_leader.position)),
			Pathfinder.distance(world.player_cell, tower.cell)
		)
	var goal := AutoRoad.objective(world) if not GameState.rehearsing else {}
	if goal.is_empty():
		_compass.remove_meta("aimed")
		_compass.hide()
		return
	var target: Vector2i = goal["cell"]
	# Standing in the objective's own tile with its door in sight, the needle goes to the door,
	# not the middle of the tile (meeting 3: in the Tower's yard it went dead).
	var door := _door()
	var tower_site := world.tower()
	if target == world.player_cell and door != null and _leader != null \
			and tower_site != null and str(goal["label"]) == tower_site.display_name:
		_compass.set_meta("aimed", true)
		_compass.visible = not _overlay_open()
		_compass.point(door.position - _leader.position, _door_label(door), 0)
		return
	# The Guild's stop, likewise: the needle goes to whoever keeps the register, who opens it
	# when spoken to (meeting 3: it no longer opens by itself on the Tower's tile).
	var keeper := _register_keeper()
	if target == world.player_cell and keeper != null and _leader != null and str(goal["label"]).begins_with("The Guild"):
		_compass.set_meta("aimed", true)
		_compass.visible = not _overlay_open()
		_compass.point(keeper.position - _leader.position, str((keeper.get_meta("person", {}) as Dictionary).get("name", "The Guild")), 0)
		return
	var bearing := Vector2(target - world.player_cell)
	if _land_mode and _leader != null:
		var land := map as Land
		bearing = Vector2(target * land.slot + land.slot / 2) - Vector2(map.cell_at(_leader.position))
	_compass.set_meta("aimed", true)
	_compass.visible = not _overlay_open()
	_compass.point(bearing, str(goal["label"]), Pathfinder.distance(world.player_cell, target))
	_compass.set_count(AutoRoad.quests(world).size(), Pad.key("cycle_quest") if not Pad.using_pad else "")


## L, or a click on the compass: follow the next thing in the quest list ([D190]), and say which.
## On a floor of the Tower the compass keeps to the stair, so the choice waits for the land.
func _next_quest() -> void:
	var world: World = GameState.world
	if world == null or GameState.rehearsing:
		return
	var entries := AutoRoad.quests(world)
	if entries.is_empty():
		_note("Nothing to follow yet. A settlement's board has work, if you want it.")
		return
	var now := AutoRoad.next_quest(world)
	if now.is_empty():
		return
	var index := entries.map(func(e: Dictionary) -> String: return str(e["id"])).find(str(now["id"]))
	_note("Following: %s (%d of %d)." % [str(now["label"]), index + 1, entries.size()])
	Sfx.play(Sfx.SELECT)
	_point_the_compass()


## Whoever here keeps the Guild's register (a person with `guild`), or null.
func _register_keeper() -> AreaActor:
	for actor: AreaActor in _people:
		if is_instance_valid(actor) and bool((actor.get_meta("person", {}) as Dictionary).get("guild", false)):
			return actor
	return null


func _door_label(door: AreaProp) -> String:
	var name := door.display_name
	return name.substr(0, 1).to_upper() + name.substr(1)


func _overlay_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.is_open():
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	# The fight on this ground has the keys and the mouse while it lasts.
	if _fight != null:
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		_mouse_input(event)
		return
	var asked := _act_for(event)
	if not asked.is_empty() and not _leaving and not _talking:
		get_viewport().set_input_as_handled()
		_do_act(asked)
		return
	if event.is_action_pressed("open_actions") and _act_bar != null:
		get_viewport().set_input_as_handled()
		_toggle_act_focus()
		return
	# Ahead of the pace keys, which used to share E with it.
	if event.is_action_pressed("interact") and _at_the_stair() and not _talking and not _leaving:
		get_viewport().set_input_as_handled()
		_climb_the_stair()
		return
	if event.is_action_pressed("interact") and _nearby != null and not _talking:
		get_viewport().set_input_as_handled()
		_engage(_nearby)
		return
	if event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.keycode == KEY_G and not _leaving and not _talking:
		var target := _strike_target()
		if target != null:
			get_viewport().set_input_as_handled()
			_wind_up(target)
			return
	if event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		Pace.auto = not Pace.auto
		return
	if event.is_action_pressed("battle_speed"):
		get_viewport().set_input_as_handled()
		Pace.cycle_speed()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		EventBus.system_menu_requested.emit()
	elif event.is_action_pressed("open_party"):
		get_viewport().set_input_as_handled()
		EventBus.party_screen_requested.emit()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.keycode == KEY_N:
		get_viewport().set_input_as_handled()
		EventBus.journal_requested.emit()
	elif event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.keycode == KEY_M and not _leaving and not _talking:
		# The map in one key (D95), not through the journal; M or Esc puts it away.
		get_viewport().set_input_as_handled()
		EventBus.map_requested.emit()
	elif event.is_action_pressed("cycle_next") and not _leaving:
		get_viewport().set_input_as_handled()
		_cycle_leader()
	elif event.is_action_pressed("cycle_quest") and not _leaving and not _talking:
		get_viewport().set_input_as_handled()
		_next_quest()


## Picking something out of the square and dealing with it is done with the
## mouse; the keys are only there for anybody who would rather not use it.
func _mouse_input(event: InputEvent) -> void:
	if _leaving or _leader == null or _talking or _overlay_open():
		return
	if event is InputEventMouseMotion:
		_hover_at(get_global_mouse_position())
		return
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	var target := _target_at(get_global_mouse_position())
	get_viewport().set_input_as_handled()
	if target == null:
		_walk_to(get_global_mouse_position())
		return
	_click_path.clear()
	_click_target(target)


## Y: onto the place's first button, or off again.
func _toggle_act_focus() -> void:
	if _picking_an_act():
		get_viewport().gui_release_focus()
		return
	for child in _act_bar.get_children():
		var button := child as Button
		if button != null and button.is_visible_in_tree():
			button.grab_focus()
			return


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# --- an inn's rooms ([D242]) --------------------------------------------------------------------


## `doug-md`, play-test 4: "you pay for the [room], little marker will show you where your room is".
## The innkeep sells a night (`inn_room_paid`); here it becomes a room of this inn (`inn_room_at`),
## its bed pinned with a dotted line to it, and the compass on it. Sleeping in it patches everyone
## up, sends them off the better for it (`vigour`, as a bed at home does) and is a place the game
## saves. One night a payment, unless the room is kept for good: an inn's `lease` is the flag that
## makes its room yours every night (the Flagon's room two, then your house in Stormreach; D252).
const ROOM_PAID := "inn_room_paid"
const ROOM_AT := "inn_room_at"


func _inn() -> Dictionary:
	# Generated ground (the land, a gate's floor) has no area file, and so no inn.
	return Database.area(map.id).get("inn", {}) if map != null and Database.has_area(map.id) else {}


## Whether this inn's room is kept for the company for good ([D252]).
func _leased() -> bool:
	var lease := str(_inn().get("lease", ""))
	return lease != "" and GameState.has_flag(lease)


func _is_an_inns_bed(cell: Vector2i) -> bool:
	for room: Dictionary in _inn().get("bedrooms", []):
		if AreaMap.to_cell(room.get("bed", [-1, -1])) == cell:
			return true
	return false


## The bed of the room paid for, if it is in this inn; otherwise (-1, -1).
func _your_bed() -> Vector2i:
	var inn := _inn()
	var rooms: Array = inn.get("bedrooms", [])
	var paid_here := str(GameState.flags.get(ROOM_AT, "")) == map.id and GameState.has_flag(ROOM_PAID)
	if rooms.is_empty() or not (paid_here or _leased()):
		return Vector2i(-1, -1)
	var yours: Dictionary = rooms[clampi(int(inn.get("yours", 0)), 0, rooms.size() - 1)]
	return AreaMap.to_cell(yours.get("bed", [-1, -1]))


func _your_room_name() -> String:
	var inn := _inn()
	var rooms: Array = inn.get("bedrooms", [])
	if rooms.is_empty():
		return "your room"
	return str((rooms[clampi(int(inn.get("yours", 0)), 0, rooms.size() - 1)] as Dictionary).get("name", "your room"))


## After a conversation: a night just paid for here becomes this inn's room.
func _settle_the_room() -> void:
	if _inn().is_empty() or not (GameState.has_flag(ROOM_PAID) or _leased()):
		return
	if GameState.has_flag(ROOM_PAID) and not _leased() and str(GameState.flags.get(ROOM_AT, "")) == "":
		GameState.set_flag(ROOM_AT, map.id)
		_note("%s is yours for the night. Follow the line to it, and E by the bed to sleep." % _your_room_name())
	_show_the_room()
	_point_the_compass()


func _show_the_room() -> void:
	var bed := _your_bed()
	if bed.x < 0:
		if _room_mark != null:
			_room_mark.queue_free()
			_room_mark = null
		if _room_label != null:
			_room_label.queue_free()
			_room_label = null
		return
	if _room_mark == null:
		_room_mark = AreaWaymark.new()
		add_child(_room_mark)
		move_child(_room_mark, _actors.get_index())
		_room_label = Label.new()
		_room_label.text = "Your room"
		_room_label.add_theme_font_size_override("font_size", 14)
		_room_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		_room_label.add_theme_color_override("font_outline_color", Color.BLACK)
		_room_label.add_theme_constant_override("outline_size", 4)
		# Under the bed, on the room's own floor: above it stands the wall.
		_room_label.position = map.centre_of(bed) + Vector2(-34.0, AreaMap.CELL * 0.45)
		_room_label.z_index = 30
		add_child(_room_label)
	_room_clock = 0.0
	_draw_the_way_to_bed()


## The dotted line from the leader to beside the bed, along the way they would walk.
func _draw_the_way_to_bed() -> void:
	var bed := _your_bed()
	if _room_mark == null or _leader == null or bed.x < 0:
		return
	var here := map.cell_at(_leader.position)
	var goal := bed + Vector2i.DOWN
	if not map.is_walkable(goal):
		for side: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT]:
			if map.is_walkable(bed + side):
				goal = bed + side
				break
	var way: Array[Vector2] = [] if here == goal else map.find_cell_path(here, goal)
	_room_mark.show_way(_leader.position, way)


## E by an inn's bed: the room paid for is slept in; any other is somebody's.
func _try_the_bed(cell: Vector2i) -> void:
	if cell != _your_bed():
		if GameState.has_flag(ROOM_PAID) and str(GameState.flags.get(ROOM_AT, "")) == map.id:
			_note("Somebody else's room. Yours is %s." % _your_room_name())
		elif GameState.has_flag(ROOM_PAID):
			_note("Your room for the night is at another inn.")
		else:
			_note("A bed made up for whoever pays the innkeep for it: %s a night." % Coins.text(int(_inn().get("price", 1000))))
		return
	_sleep_in_the_room()


func _sleep_in_the_room() -> void:
	var inn := _inn()
	var vigour := int(inn.get("vigour", 0))
	var place := str(Database.area(map.id).get("display_name", "the inn"))
	var bettered: Array[String] = []
	for character: Character in GameState.party_characters():
		if character.is_alive() and character.hearth_vigour < vigour:
			character.hearth_vigour = vigour
			bettered.append(character.display_name)
	GameState.roster.rest()
	GameState.heal_party()
	# A room kept for good stays yours; a night paid for is let go ([D252]).
	if not _leased():
		GameState.flags.erase(ROOM_PAID)
		GameState.flags.erase(ROOM_AT)
	_show_the_room()
	EventBus.player_did.emit("slept:%s" % place)
	var woke := str(inn.get("woke", ""))
	_note(woke if woke != "" else "You sleep in %s at %s, and wake with the house already loud below." % [_your_room_name().to_lower(), place])
	if not bettered.is_empty():
		_note("%s wake up the better for it (+%d health)." % [" and ".join(bettered), vigour])
	_night_falls()
	EventBus.safe_point_reached.emit(RunMode.REST, "you slept at %s" % place)
	_point_the_compass()


## A short dark while the party sleeps.
func _night_falls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 35
	var dark := ColorRect.new()
	dark.color = Color(0.0, 0.0, 0.02, 0.0)
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dark)
	add_child(layer)
	var fade := create_tween()
	fade.tween_property(dark, "color:a", 0.92, 0.6)
	fade.tween_interval(0.5)
	fade.tween_property(dark, "color:a", 0.0, 0.9)
	fade.tween_callback(layer.queue_free)


## Somebody speaking from afar (Sennet, at the first town) is seen beside the lead while they talk:
## their own figure, washed blue and see-through, coming in and flickering (play-test 7, call BR8;
## `data/world_rules.json` → `from_afar`).
func _see_who_speaks_from_afar(lines: Array) -> void:
	if _leader == null or _fight != null or not is_inside_tree():
		return
	for line: Variant in lines:
		if typeof(line) != TYPE_DICTIONARY or not bool((line as Dictionary).get("afar", false)):
			continue
		var speaker := str((line as Dictionary).get("speaker", ""))
		var seen := DialogueScript.afar(speaker)
		if seen.is_empty():
			continue
		_let_the_ghost_go()
		var ghost := AreaActor.for_person({ "name": speaker, "unit": str(seen.get("unit", "")) })
		var wash := DialogueScript.afar_wash(seen)
		var beside := float(seen.get("beside", 1.4)) * AreaMap.CELL
		var at := _leader.position + Vector2(beside, 0)
		if not _can_stand(at) and _can_stand(_leader.position - Vector2(beside, 0)):
			at = _leader.position - Vector2(beside, 0)
		ghost.position = at
		ghost.material = DialogueScript.afar_material(seen)
		for part: Node in ghost.find_children("*", "CanvasItem", true, false):
			(part as CanvasItem).use_parent_material = true
		ghost.modulate = Color(1, 1, 1, 0.0)
		_actors.add_child(ghost)
		ghost.face(_leader.position - at)
		_leader.face(at - _leader.position)
		_ghost = ghost
		var flicker := float(seen.get("flicker", 0.12))
		var come := ghost.create_tween()
		come.tween_property(ghost, "modulate:a", wash.a, float(seen.get("fade", 0.6)))
		# A light that does not quite hold: up and down a little while they speak.
		come.tween_callback(func() -> void:
			var waver := ghost.create_tween().set_loops()
			waver.tween_property(ghost, "modulate:a", maxf(0.1, wash.a - flicker), 0.45)
			waver.tween_property(ghost, "modulate:a", wash.a, 0.55)
			ghost.set_meta("waver", waver))
		ghost.set_meta("waver", come)
		return


func _let_the_ghost_go() -> void:
	if _ghost == null or not is_instance_valid(_ghost):
		_ghost = null
		return
	var going := _ghost
	_ghost = null
	var waver: Variant = going.get_meta("waver", null)
	if waver is Tween:
		(waver as Tween).kill()
	var fade := going.create_tween()
	fade.tween_property(going, "modulate:a", 0.0, 0.4)
	fade.tween_callback(going.queue_free)
