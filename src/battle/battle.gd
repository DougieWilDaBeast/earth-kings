extends Node2D
## Battle scene controller: owns the phase machine, routes player input, and
## drives enemy turns. Systems it coordinates (grid, pathfinder, turn order,
## abilities, AI) live in their own files and know nothing about this one.

enum Phase { SETUP, COMMAND, PICK_MOVE, PICK_TARGET, BUSY, FINISHED }

const DEFAULT_MAP := "verdant_pass"
const END_SCREEN_DELAY := 1.6

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}

@onready var grid: BattleGrid = $Grid
@onready var overlay: GridOverlay = $Overlay
@onready var units_root: Node2D = $Units
@onready var camera: Camera2D = $Camera2D
@onready var turns: TurnManager = $TurnManager
@onready var hud: BattleHUD = $HUD

var map_id: String = DEFAULT_MAP
var pathfinder: Pathfinder
var units: Array[Unit] = []
var active_unit: Unit
var phase: Phase = Phase.SETUP

var _move_field: MoveField
var _pending_ability: String = ""


func _ready() -> void:
	map_id = boot_payload.get("map_id", DEFAULT_MAP)
	_build_battlefield()
	_connect_hud()
	EventBus.battle_started.emit(map_id)
	_next_turn()


# --- setup -------------------------------------------------------------------


func _build_battlefield() -> void:
	var map := Database.map(map_id)
	grid.load_map(map)
	overlay.grid = grid
	pathfinder = Pathfinder.new(grid)

	camera.position = grid.centre_world()
	camera.enabled = true

	_spawn_party(map.get("player_spawns", []))
	_spawn_enemies(map.get("enemies", []))
	turns.setup(units)


func _spawn_party(spawns: Array) -> void:
	for i in GameState.party.size():
		if i >= spawns.size():
			push_warning("Battle: map %s has fewer spawns than party members" % map_id)
			break
		_add_unit(GameState.party[i], Unit.Team.PLAYER, _to_cell(spawns[i]))


func _spawn_enemies(enemies: Array) -> void:
	for entry: Dictionary in enemies:
		_add_unit(entry.get("unit", ""), Unit.Team.ENEMY, _to_cell(entry.get("cell", [0, 0])))


func _add_unit(template_id: String, team: Unit.Team, cell: Vector2i) -> void:
	var unit := Unit.create(template_id, team, cell)
	unit.snap_to_cell(grid)
	units_root.add_child(unit)
	units.append(unit)


func _connect_hud() -> void:
	hud.move_requested.connect(_on_move_requested)
	hud.ability_requested.connect(_on_ability_requested)
	hud.wait_requested.connect(_end_turn)


# --- turn loop ---------------------------------------------------------------


func _next_turn() -> void:
	if _resolve_outcome():
		return

	active_unit = turns.advance()
	if active_unit == null:
		return

	active_unit.begin_turn()
	EventBus.turn_started.emit(active_unit)
	hud.set_turn_order(turns.forecast(6))

	if active_unit.team == Unit.Team.PLAYER:
		_enter_command()
	else:
		phase = Phase.BUSY
		hud.hide_commands()
		await _take_enemy_turn(active_unit)
		_end_turn()


func _enter_command() -> void:
	phase = Phase.COMMAND
	overlay.clear()
	hud.show_commands(active_unit)


func _end_turn() -> void:
	if active_unit != null:
		turns.end_turn(active_unit)
		EventBus.turn_ended.emit(active_unit)
	active_unit = null
	_move_field = null
	_pending_ability = ""
	overlay.clear()
	hud.hide_commands()
	# Deferred so long battles don't grow the call stack turn after turn.
	call_deferred("_next_turn")


func _take_enemy_turn(unit: Unit) -> void:
	await get_tree().create_timer(0.35).timeout
	var plan := EnemyBrain.plan(unit, grid, pathfinder, units)

	var destination: Vector2i = plan["move_cell"]
	if destination != unit.cell:
		var field := _build_move_field(unit)
		await unit.walk_path(grid, field.path_to(destination))
		unit.snap_to_cell(grid)

	var target: Unit = plan["target"]
	if target != null and target.is_alive():
		await get_tree().create_timer(0.2).timeout
		_apply_ability(unit, Database.ability(plan["ability"]), target.cell)
		await get_tree().create_timer(0.4).timeout


# --- player commands ---------------------------------------------------------


func _on_move_requested() -> void:
	if phase != Phase.COMMAND or active_unit == null or active_unit.has_moved:
		return
	_move_field = _build_move_field(active_unit)
	overlay.move_cells = _move_field.stoppable_cells(
		func(cell: Vector2i) -> bool: return unit_at(cell) != null
	)
	overlay.queue_redraw()
	phase = Phase.PICK_MOVE


func _on_ability_requested(ability_id: String) -> void:
	if phase != Phase.COMMAND or active_unit == null or active_unit.has_acted:
		return
	_pending_ability = ability_id
	var ability := Database.ability(ability_id)
	overlay.action_cells = pathfinder.cells_in_range(
		active_unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()
	phase = Phase.PICK_TARGET


func _cancel_selection() -> void:
	if phase == Phase.PICK_MOVE or phase == Phase.PICK_TARGET:
		_enter_command()


# --- input -------------------------------------------------------------------


func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.SETUP or phase == Phase.BUSY or phase == Phase.FINISHED:
		return

	if event is InputEventMouseMotion:
		_update_hover(grid.world_to_cell(get_global_mouse_position()))
		return

	if event.is_action_pressed("ui_cancel"):
		_cancel_selection()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_clicked(grid.world_to_cell(get_global_mouse_position()))
		get_viewport().set_input_as_handled()


func _update_hover(cell: Vector2i) -> void:
	overlay.set_cursor(cell)
	hud.set_inspected(unit_at(cell), grid.terrain_at(cell) if grid.in_bounds(cell) else {})
	if phase == Phase.PICK_MOVE and _move_field != null and _move_field.can_reach(cell):
		overlay.set_path(_move_field.path_to(cell))
	else:
		overlay.clear_path()


func _on_cell_clicked(cell: Vector2i) -> void:
	match phase:
		Phase.PICK_MOVE:
			_try_move_to(cell)
		Phase.PICK_TARGET:
			_try_act_on(cell)


func _try_move_to(cell: Vector2i) -> void:
	if _move_field == null or not _move_field.can_reach(cell) or unit_at(cell) != null:
		return
	phase = Phase.BUSY
	overlay.clear()
	var mover := active_unit
	await mover.walk_path(grid, _move_field.path_to(cell))
	mover.snap_to_cell(grid)
	_after_player_action()


func _try_act_on(cell: Vector2i) -> void:
	if cell not in overlay.action_cells:
		return
	var ability := Database.ability(_pending_ability)
	if not _apply_ability(active_unit, ability, cell):
		return
	phase = Phase.BUSY
	overlay.clear()
	await get_tree().create_timer(0.35).timeout
	_after_player_action()


func _after_player_action() -> void:
	if _resolve_outcome():
		return
	if active_unit != null and active_unit.has_moved and active_unit.has_acted:
		_end_turn()
	else:
		_enter_command()


# --- resolution --------------------------------------------------------------


## Returns false if nothing valid was hit, so the player keeps their selection.
func _apply_ability(user: Unit, ability: Dictionary, centre: Vector2i) -> bool:
	var hits: Array[Unit] = []
	for cell in AbilityResolver.affected_cells(ability, centre):
		var target := unit_at(cell)
		if target != null and AbilityResolver.is_valid_target(user, ability, target):
			hits.append(target)
	if hits.is_empty():
		return false

	for target in hits:
		EventBus.battle_log.emit(AbilityResolver.apply(user, ability, target))
		if not target.is_alive():
			target.visible = false
	user.has_acted = true
	return true


func _resolve_outcome() -> bool:
	var players_alive := units.any(
		func(u: Unit) -> bool: return u.is_alive() and u.team == Unit.Team.PLAYER
	)
	var enemies_alive := units.any(
		func(u: Unit) -> bool: return u.is_alive() and u.team == Unit.Team.ENEMY
	)
	if players_alive and enemies_alive:
		return false

	phase = Phase.FINISHED
	overlay.clear()
	hud.hide_commands()
	hud.show_result(players_alive)
	if players_alive:
		GameState.mark_battle_cleared(map_id)
	else:
		# Retreat, or arriving back on the overworld would restart the fight.
		GameState.current_location = GameState.previous_location
	EventBus.battle_finished.emit({"victory": players_alive, "map_id": map_id})
	_return_to_overworld()
	return true


func _return_to_overworld() -> void:
	await get_tree().create_timer(END_SCREEN_DELAY).timeout
	EventBus.request_scene.emit("overworld", {})


# --- queries -----------------------------------------------------------------


func unit_at(cell: Vector2i) -> Unit:
	for unit in units:
		if unit.is_alive() and unit.cell == cell:
			return unit
	return null


func _build_move_field(unit: Unit) -> MoveField:
	return pathfinder.build_move_field(
		unit.cell,
		unit.move_points,
		unit.jump,
		func(cell: Vector2i) -> bool:
			var other := unit_at(cell)
			return other != null and other.is_hostile_to(unit)
	)


func _to_cell(value: Variant) -> Vector2i:
	var pair: Array = value
	return Vector2i(int(pair[0]), int(pair[1]))
