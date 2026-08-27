extends Node2D
## Walk mode: the world, a party moving across it one tile at a time, and
## everything that interrupts them.
##
## Every step advances the world clock, so travel is never free.

const CELL := 24
## Seconds between steps while a direction is held down.
const REPEAT_DELAY := 0.11
const FIRST_REPEAT_DELAY := 0.28
## Beat between the last of the party falling and the title screen.
const RUN_OVER_DELAY := 3.0

const DIRECTIONS := {
	"ui_up": Vector2i.UP,
	"ui_down": Vector2i.DOWN,
	"ui_left": Vector2i.LEFT,
	"ui_right": Vector2i.RIGHT,
}

const SITE_COLOURS := {
	Site.TOWER: Color(0.92, 0.85, 0.45),
	Site.KEEP: Color(0.72, 0.74, 0.82),
	Site.VILLAGE: Color(0.55, 0.78, 0.55),
	Site.LIBRARY: Color(0.55, 0.7, 0.95),
	Site.GATE: Color(0.85, 0.35, 0.35),
	Site.HUT: Color(0.78, 0.66, 0.48),
}

var boot_payload: Dictionary = {}

@onready var _map: Node2D = $Map
@onready var _camera: Camera2D = $Camera2D
@onready var _place: Label = %PlaceLabel
@onready var _party: Label = %PartyLabel
@onready var _log: Label = %LogLabel
@onready var _hint: Label = %HintLabel

var world: World
var _notices: Array[String] = []
var _repeat_timer: float = 0.0
var _held: Vector2i = Vector2i.ZERO
var _busy: bool = false


func _ready() -> void:
	world = GameState.world
	_map.draw.connect(_draw_world)
	_map.queue_redraw()
	_centre_camera()
	_refresh()

	if GameState.has_flag("last_victory"):
		_note("You are still standing.")
	GameState.set_flag("last_victory", false)
	_check_party()


func _process(delta: float) -> void:
	if _busy:
		return
	var direction := _pressed_direction()
	if direction == Vector2i.ZERO:
		_held = Vector2i.ZERO
		return

	if direction != _held:
		_held = direction
		_repeat_timer = FIRST_REPEAT_DELAY
		_step(direction)
		return

	_repeat_timer -= delta
	if _repeat_timer <= 0.0:
		_repeat_timer = REPEAT_DELAY
		_step(direction)


func _pressed_direction() -> Vector2i:
	for action: String in DIRECTIONS:
		if Input.is_action_pressed(action):
			return DIRECTIONS[action]
	return Vector2i.ZERO


# --- walking ------------------------------------------------------------------


func _step(direction: Vector2i) -> void:
	var target := world.player_cell + direction
	if not world.is_walkable(target):
		return

	world.player_cell = target
	for notice: String in world.step():
		_note(notice)
	_centre_camera()
	_map.queue_redraw()

	var site := world.site_at(target)
	if site != null:
		_arrive_at(site)
	else:
		_roll_for_trouble(target)
	_check_party()
	_refresh()


func _roll_for_trouble(cell: Vector2i) -> void:
	var meeting := Encounter.roll(world, cell, GameState.party_characters(), world.rng)
	if meeting.is_empty():
		return
	_begin_battle(meeting)


func _begin_battle(meeting: Dictionary) -> void:
	_busy = true
	_note(meeting["title"])
	EventBus.request_scene.emit("battle", {"encounter": meeting, "return_scene": "world"})


# --- places -------------------------------------------------------------------


func _arrive_at(site: Site) -> void:
	match site.kind:
		Site.VILLAGE, Site.KEEP, Site.HUT:
			_rest_at(site)
		Site.LIBRARY:
			_read_at(site)
		Site.GATE:
			_enter_gate(site)
		Site.TOWER:
			_climb(site)


func _rest_at(site: Site) -> void:
	if GameState.party_is_wounded():
		GameState.heal_party()
		_note("You rest at %s. Everyone is patched up." % site.display_name)
	else:
		_note("%s is quiet." % site.display_name)


func _read_at(site: Site) -> void:
	var doctrine_id: String = site.data.get("doctrine", "")
	if doctrine_id == "":
		_note("The shelves at %s are bare." % site.display_name)
		return

	var learned := false
	for character in GameState.party_characters():
		if Doctrine.learn(character, doctrine_id, world.steps):
			_note("%s reads %s." % [character.display_name, Doctrine.title(doctrine_id)])
			learned = true
			break
	if not learned:
		_note("Everyone here has already read %s." % Doctrine.title(doctrine_id))


func _enter_gate(site: Site) -> void:
	if not site.open:
		_note("%s is shut." % site.label())
		return
	var party := GameState.party_characters()
	_note("%s stands open." % site.label())
	_begin_battle(Encounter.for_gate(world, site, 0, true, party, world.rng))
	# The gate is settled the moment you commit; surviving is the reward.
	site.open = false
	site.cleared = true
	GameState.gold += 40 * (Site.rank_index(site.rank) + 1)


func _climb(site: Site) -> void:
	var next_floor := world.tower_floor + 1
	_note("The Tower opens onto floor %d." % next_floor)
	world.tower_floor = next_floor
	_begin_battle(Encounter.for_tower(world, site, next_floor, GameState.party_characters(), world.rng))


# --- party --------------------------------------------------------------------


func _check_party() -> void:
	for character in GameState.roster.party_members():
		for forgotten: String in Doctrine.decay(character, world.steps):
			_note("%s can no longer recall %s." % [character.display_name, Doctrine.title(forgotten)])

	if GameState.roster.is_broken():
		_end_run()
		return

	var choosing := GameState.roster.awaiting_class_choice()
	_hint.text = "%s is ready to choose a path — press P." % choosing.display_name if choosing != null else "P for the party  ·  Esc for the menu"


## Permadeath has to mean something at the end of the line, not just mid-fight.
func _end_run() -> void:
	_busy = true
	_note("Nobody is left standing. The run is over.")
	_hint.text = ""
	EventBus.run_ended.emit()
	await get_tree().create_timer(RUN_OVER_DELAY).timeout
	EventBus.request_scene.emit("title", {})


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not event.is_pressed() or event.is_echo():
		return
	if event is InputEventKey and event.keycode == KEY_P:
		get_viewport().set_input_as_handled()
		EventBus.party_screen_requested.emit()


# --- presentation -------------------------------------------------------------


func _centre_camera() -> void:
	_camera.position = Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	_camera.enabled = true


func _note(line: String) -> void:
	_notices.append(line)
	if _notices.size() > 4:
		_notices = _notices.slice(_notices.size() - 4)
	_log.text = "\n".join(_notices)


func _refresh() -> void:
	var site := world.site_at(world.player_cell)
	var where: String = site.label() if site != null else world.terrain_at(world.player_cell).get("name", "open ground")
	_place.text = "%s  ·  %s  ·  %d gold  ·  step %d  ·  danger %d%%" % [
		where, str(world.player_cell), GameState.gold, world.steps,
		roundi(Encounter.chance_at(world, world.player_cell) * 100.0)
	]

	var entries: Array[String] = []
	for character in GameState.roster.party_members():
		entries.append("%s L%d %d/%d" % [
			character.display_name, character.level, character.current_hp(), character.max_hp()
		])
	_party.text = "  ·  ".join(entries)


## Runs inside the Map node's draw pass, so its draw_* calls are legal here.
func _draw_world() -> void:
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			var rect := Rect2(Vector2(cell) * CELL, Vector2.ONE * CELL)
			_map.draw_rect(rect, Color(world.terrain_at(cell).get("color", "#4f7d3f")))

	for site in world.sites:
		var centre := Vector2(site.cell) * CELL + Vector2.ONE * CELL * 0.5
		var colour: Color = SITE_COLOURS.get(site.kind, Color.WHITE)
		_map.draw_rect(Rect2(Vector2(site.cell) * CELL, Vector2.ONE * CELL), Color(0, 0, 0, 0.45))
		_map.draw_circle(centre, CELL * 0.34, colour)
		if site.kind == Site.GATE and site.open:
			_map.draw_arc(centre, CELL * 0.48, 0.0, TAU, 20, colour, 2.0, true)

	var player := Vector2(world.player_cell) * CELL + Vector2.ONE * CELL * 0.5
	_map.draw_circle(player, CELL * 0.3, Color(0.98, 0.95, 0.85))
	_map.draw_arc(player, CELL * 0.3, 0.0, TAU, 20, Color(0.1, 0.1, 0.12), 2.0, true)
