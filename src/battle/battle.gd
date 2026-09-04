extends Node2D
## Battle scene controller: owns the phase machine, routes player input, and
## drives enemy turns. Systems it coordinates (grid, pathfinder, turn order,
## abilities, AI) live in their own files and know nothing about this one.

enum Phase { SETUP, COMMAND, PICK_MOVE, PICK_FLASH, PICK_TARGET, BUSY, FINISHED }

const DEFAULT_MAP := "verdant_pass"
const END_SCREEN_DELAY := 1.6

## Set by [Game] before the scene enters the tree.
var boot_payload: Dictionary = {}

@onready var grid: BattleGrid = $Grid
@onready var overlay: GridOverlay = $Overlay
@onready var units_root: Node2D = $Units
@onready var camera: CameraRig = $Camera2D
@onready var turns: TurnManager = $TurnManager
@onready var hud: BattleHUD = $HUD

var map_id: String = DEFAULT_MAP
## Set when the fight came from the world rather than an authored map.
var encounter: Dictionary = {}
## A training fight: nobody really dies and the world is not told about it.
var sandbox: bool = false
var pathfinder: Pathfinder
var units: Array[Unit] = []
## The player units taking the current phase together; empty on an enemy phase.
var squad: Array[Unit] = []
## Whoever the player is commanding right now, or the enemy taking its turn.
var active_unit: Unit
var phase: Phase = Phase.SETUP

var _move_field: MoveField
var _pending_ability: String = ""
## Everyone who owes CT when this phase ends.
var _phase_units: Array[Unit] = []


func _ready() -> void:
	map_id = boot_payload.get("map_id", DEFAULT_MAP)
	encounter = boot_payload.get("encounter", {})
	sandbox = bool(boot_payload.get("sandbox", false))
	_build_battlefield()
	_connect_hud()
	EventBus.battle_started.emit(map_id)
	_next_turn()


# --- setup -------------------------------------------------------------------


func _build_battlefield() -> void:
	var map: Dictionary = encounter.get("map", {}) if not encounter.is_empty() else Database.map(map_id)
	grid.load_map(map)
	overlay.grid = grid
	pathfinder = Pathfinder.new(grid)

	camera.frame(Rect2(Vector2.ZERO, Vector2(grid.width, grid.height) * BattleGrid.CELL_SIZE))
	camera.focus_on(grid.centre_world(), true)
	# Taller-than-a-tile sprites need to overlap by depth, not by spawn order.
	units_root.y_sort_enabled = true

	_spawn_party(map.get("player_spawns", []))
	_spawn_enemies(map.get("enemies", []))
	_orient_starting_facings()
	_write_them_up(map)
	turns.setup(units)


## Open a journal entry for anything the party has not stood across from before.
## Training fights are not written down — knowing a thing from the sandbox
## would be knowing it for free.
func _write_them_up(map: Dictionary) -> void:
	if sandbox:
		return
	var place := str(map.get("name", encounter.get("title", "somewhere")))
	for unit in units:
		if unit.team == Unit.Team.PLAYER:
			continue
		if Journal.sighted(GameState.world, unit.template_id, place):
			EventBus.battle_log.emit("%s is new. The journal opens a page." % unit.display_name)


func _spawn_party(spawns: Array) -> void:
	var members := GameState.party_characters()
	for i in members.size():
		if i >= spawns.size():
			push_warning("Battle: map %s has fewer spawns than party members" % map_id)
			break
		var unit := Unit.from_character(members[i], Unit.Team.PLAYER, _to_cell(spawns[i]))
		unit.snap_to_cell(grid)
		units_root.add_child(unit)
		units.append(unit)


func _spawn_enemies(enemies: Array) -> void:
	for entry: Dictionary in enemies:
		var cell := _to_cell(entry.get("cell", [0, 0]))
		var level := int(entry.get("level", 0))
		var unit_team: Unit.Team = entry.get("team", Unit.Team.ENEMY)
		if level <= 0:
			_add_unit(entry.get("unit", ""), unit_team, cell)
			continue
		# Levelled foes are throwaway Characters so they grow the same way we do.
		var foe := Character.create(entry.get("unit", ""))
		Progression.raise_quietly(foe, level, GameState.world)
		var unit := Unit.from_character(foe, unit_team, cell)
		unit.snap_to_cell(grid)
		units_root.add_child(unit)
		units.append(unit)


func _add_unit(template_id: String, team: Unit.Team, cell: Vector2i) -> Unit:
	var unit := Unit.create(template_id, team, cell)
	unit.snap_to_cell(grid)
	units_root.add_child(unit)
	units.append(unit)
	return unit


func _connect_hud() -> void:
	hud.move_requested.connect(_on_move_requested)
	hud.flash_step_requested.connect(_on_flash_step_requested)
	hud.ability_requested.connect(_on_ability_requested)
	hud.draught_requested.connect(_on_draught_requested)
	hud.wait_requested.connect(_on_wait_requested)
	hud.preview_requested.connect(_on_preview_requested)
	hud.preview_cleared.connect(_on_preview_cleared)
	hud.auto_toggled.connect(_set_auto)
	hud.speed_cycled.connect(_cycle_speed)
	hud.set_auto(Pace.auto)
	hud.set_speed(Pace.speed())


# --- turn loop ---------------------------------------------------------------


func _next_turn() -> void:
	if _resolve_outcome():
		return

	var group := turns.advance_group()
	if group.is_empty():
		return

	_phase_units = group
	for unit in group:
		unit.begin_turn()
		EventBus.turn_started.emit(unit)
	hud.set_turn_order(turns.forecast(6))

	if group[0].team == Unit.Team.PLAYER:
		squad = group
		_select(group[0])
	else:
		squad = []
		active_unit = group[0]
		phase = Phase.BUSY
		hud.set_squad([], null)
		hud.hide_commands()
		_mark_active()
		await _take_ai_turn(active_unit)
		_end_phase()


## Hand control to [param unit] and redraw everything that depends on it.
func _select(unit: Unit) -> void:
	active_unit = unit
	_move_field = null
	_pending_ability = ""
	_enter_command()


func _enter_command() -> void:
	phase = Phase.COMMAND
	overlay.clear()
	_mark_active()
	hud.set_squad(squad, active_unit)
	hud.show_commands(active_unit)
	if Pace.auto:
		_run_auto_phase()


## Tab order runs over the squad members who still have something left to spend.
func _cycle_squad(step: int) -> void:
	var ready := _ready_squad()
	if ready.size() < 2:
		return
	var index := ready.find(active_unit)
	_select(ready[posmod(index + step, ready.size())])


func _ready_squad() -> Array[Unit]:
	return squad.filter(func(u: Unit) -> bool: return u.is_alive() and not u.is_done())


## Move on once the current character is spent; the phase ends when all are.
func _advance_selection() -> void:
	var ready := _ready_squad()
	if ready.is_empty():
		_end_phase()
	elif active_unit != null and not active_unit.is_done():
		_enter_command()
	else:
		_select(ready[0])


func _end_phase() -> void:
	for unit in _phase_units:
		turns.end_turn(unit)
		EventBus.turn_ended.emit(unit)
	_phase_units = []
	squad = []
	active_unit = null
	_move_field = null
	_pending_ability = ""
	overlay.clear()
	overlay.clear_active()
	hud.set_squad([], null)
	hud.hide_commands()
	# Deferred so long battles don't grow the call stack turn after turn.
	call_deferred("_next_turn")


func _take_ai_turn(unit: Unit) -> void:
	await get_tree().create_timer(0.35).timeout
	var plan := EnemyBrain.plan(unit, grid, pathfinder, units)

	var destination: Vector2i = plan["move_cell"]
	if destination != unit.cell:
		overlay.clear_active()
		if plan.get("flash", false):
			await unit.flash_to(grid, destination)
		else:
			var field := _build_move_field(unit)
			await unit.walk_path(grid, field.path_to(destination))
		unit.snap_to_cell(grid)
		_mark_active()

	var target: Unit = plan["target"]
	if target != null and target.is_alive():
		await get_tree().create_timer(0.2).timeout
		_apply_ability(unit, plan["ability"], target.cell)
		await get_tree().create_timer(0.4).timeout


# --- auto battle -------------------------------------------------------------


func _set_auto(enabled: bool) -> void:
	if Pace.auto == enabled:
		return
	Pace.auto = enabled
	hud.set_auto(enabled)
	EventBus.battle_log.emit(
		"The party fights on its own." if enabled else "You take the party back."
	)
	if enabled and _is_choosing():
		_run_auto_phase()


func _cycle_speed() -> void:
	Pace.cycle_speed()
	hud.set_speed(Pace.speed())


## Play the party's phase for them, one member at a time. The loop checks in
## between, so switching auto off hands control back after the current move.
func _run_auto_phase() -> void:
	while Pace.auto and not squad.is_empty() and phase != Phase.FINISHED:
		var ready := _ready_squad()
		if ready.is_empty():
			break
		var unit := ready[0]
		active_unit = unit
		_move_field = null
		_pending_ability = ""
		phase = Phase.BUSY
		overlay.clear()
		_mark_active()
		hud.set_squad(squad, unit)
		hud.hide_commands()
		await _take_ai_turn(unit)
		if phase == Phase.FINISHED:
			return
		unit.finish_turn()
		if _resolve_outcome():
			return

	if phase == Phase.FINISHED or squad.is_empty():
		return
	if _ready_squad().is_empty():
		_end_phase()
	else:
		_enter_command()


# --- player commands ---------------------------------------------------------


func _on_move_requested() -> void:
	if not _is_choosing() or active_unit == null or not active_unit.can_move():
		return
	_arm()
	_move_field = _build_move_field(active_unit)
	overlay.move_cells = _move_field.stoppable_cells(
		func(cell: Vector2i) -> bool: return unit_at(cell) != null
	)
	overlay.queue_redraw()
	phase = Phase.PICK_MOVE


func _on_flash_step_requested() -> void:
	if not _is_choosing() or active_unit == null or not active_unit.can_flash_step():
		return
	_arm()
	overlay.flash_cells = _build_flash_cells(active_unit)
	overlay.queue_redraw()
	phase = Phase.PICK_FLASH


func _on_ability_requested(ability_id: String) -> void:
	if not _is_choosing() or active_unit == null:
		return
	var ability := Database.ability(ability_id)
	if not active_unit.can_pay(Unit.ability_cost(ability)):
		return
	_arm()
	_pending_ability = ability_id
	overlay.action_cells = pathfinder.cells_in_range(
		active_unit.cell, int(ability.get("min_range", 1)), int(ability.get("range", 1))
	)
	overlay.queue_redraw()
	phase = Phase.PICK_TARGET


func _on_draught_requested(item_id: String) -> void:
	if not _is_choosing() or active_unit == null or active_unit.team != Unit.Team.PLAYER:
		return
	if not active_unit.can_pay(Unit.Cost.BONUS):
		return
	if not GameState.stores.has(item_id) or not Gear.is_draught(item_id):
		return
	if active_unit.hp >= active_unit.max_hp:
		return

	active_unit.pay(Unit.Cost.BONUS)
	GameState.stores.erase(item_id)
	var before := active_unit.hp
	active_unit.heal(Gear.mends(item_id))
	if active_unit.character != null:
		active_unit.character.hp = active_unit.hp
	var healed := active_unit.hp - before
	EventBus.battle_log.emit("%s drinks %s and mends %d HP." % [
		active_unit.display_name, Gear.display_name(item_id), healed
	])
	_advance_selection()


## Drop whatever was armed before, so picking a second command replaces the first
## instead of needing a cancel in between.
func _arm() -> void:
	overlay.clear()
	_move_field = null
	_pending_ability = ""


## True while the player still owns the choice: the menu or any targeting step.
func _is_choosing() -> bool:
	return phase == Phase.COMMAND or phase == Phase.PICK_MOVE \
			or phase == Phase.PICK_FLASH or phase == Phase.PICK_TARGET


## Mid-selection, as opposed to sitting on the command menu having chosen nothing.
func _is_picking() -> bool:
	return phase == Phase.PICK_MOVE or phase == Phase.PICK_FLASH or phase == Phase.PICK_TARGET


## Show the reach of a hovered command without committing to it.
func _on_preview_requested(kind: String, ability_id: String) -> void:
	if not _is_choosing() or active_unit == null:
		return
	match kind:
		"move":
			var field := _build_move_field(active_unit)
			var cells := field.stoppable_cells(
				func(cell: Vector2i) -> bool: return unit_at(cell) != null
			)
			overlay.set_preview(cells, GridOverlay.MOVE_COLOUR)
		"flash":
			overlay.set_preview(_build_flash_cells(active_unit), GridOverlay.FLASH_COLOUR)
		"ability":
			var ability := Database.ability(ability_id)
			overlay.set_preview(pathfinder.cells_in_range(
				active_unit.cell,
				int(ability.get("min_range", 1)),
				int(ability.get("range", 1))
			), GridOverlay.ACTION_COLOUR)


func _on_preview_cleared() -> void:
	overlay.clear_preview()


## "Wait" gives up what this character has left rather than the whole phase.
func _on_wait_requested() -> void:
	if active_unit == null or active_unit.team != Unit.Team.PLAYER:
		return
	active_unit.finish_turn()
	_advance_selection()


func _cancel_selection() -> void:
	if phase == Phase.PICK_MOVE or phase == Phase.PICK_FLASH or phase == Phase.PICK_TARGET:
		_enter_command()


# --- input -------------------------------------------------------------------


## Tab is claimed before the UI can use it for focus navigation.
func _input(event: InputEvent) -> void:
	if squad.size() < 2 or phase == Phase.BUSY or phase == Phase.FINISHED:
		return
	if event.is_action_pressed("cycle_next"):
		_cycle_squad(-1 if Input.is_key_pressed(KEY_SHIFT) else 1)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Auto and speed answer at any point in the fight, including mid-animation.
	if event.is_action_pressed("battle_auto"):
		get_viewport().set_input_as_handled()
		_set_auto(not Pace.auto)
		return
	if event.is_action_pressed("battle_speed"):
		get_viewport().set_input_as_handled()
		_cycle_speed()
		return
	# The journal is most wanted while you are stood across from the thing it is
	# about, so it opens here as well as on the road.
	if event is InputEventKey and event.is_pressed() and not event.is_echo() \
			and event.keycode == KEY_N:
		get_viewport().set_input_as_handled()
		EventBus.journal_requested.emit()
		return

	# Backing out of a selection is Escape or a right-click. With nothing to back
	# out of, Escape is how a fight reaches the menu.
	if _is_cancel(event):
		if _is_picking():
			_cancel_selection()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			EventBus.system_menu_requested.emit()
		return

	if phase == Phase.SETUP or phase == Phase.BUSY or phase == Phase.FINISHED:
		return

	if event is InputEventMouseMotion:
		_update_hover(grid.world_to_cell(get_global_mouse_position()))
		return

	if _is_choosing() and _run_command_shortcut(event):
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_cell_clicked(grid.world_to_cell(get_global_mouse_position()))
		get_viewport().set_input_as_handled()


func _is_cancel(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	return event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT


## Keyboard shortcuts that mirror the command buttons, so a whole turn can be
## given without leaving the keyboard.
func _run_command_shortcut(event: InputEvent) -> bool:
	if active_unit == null:
		return false
	if event.is_action_pressed("command_move"):
		_on_move_requested()
		return true
	if event.is_action_pressed("command_flash_step"):
		_on_flash_step_requested()
		return true
	if event.is_action_pressed("command_wait"):
		_on_wait_requested()
		return true
	var slot := _ability_slot(event)
	if slot >= 0 and slot < active_unit.abilities.size():
		_on_ability_requested(active_unit.abilities[slot])
		return true
	return false


## 1-9 pick abilities in the order the HUD lists them.
func _ability_slot(event: InputEvent) -> int:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return -1
	if event.keycode < KEY_1 or event.keycode > KEY_9:
		return -1
	return event.keycode - KEY_1


func _update_hover(cell: Vector2i) -> void:
	overlay.set_cursor(cell)
	hud.set_inspected(unit_at(cell), grid.terrain_at(cell) if grid.in_bounds(cell) else {})
	if phase == Phase.PICK_MOVE and _move_field != null and _move_field.can_reach(cell):
		overlay.set_path(_move_field.path_to(cell))
	else:
		overlay.clear_path()


func _on_cell_clicked(cell: Vector2i) -> void:
	match phase:
		Phase.COMMAND:
			_try_select_at(cell)
		Phase.PICK_MOVE:
			_try_move_to(cell)
		Phase.PICK_FLASH:
			_try_flash_to(cell)
		Phase.PICK_TARGET:
			_try_act_on(cell)


func _try_select_at(cell: Vector2i) -> void:
	var clicked := unit_at(cell)
	if clicked != null and clicked != active_unit and clicked in _ready_squad():
		_select(clicked)


func _try_move_to(cell: Vector2i) -> void:
	if _move_field == null or not _move_field.can_reach(cell) or unit_at(cell) != null:
		return
	phase = Phase.BUSY
	overlay.clear()
	overlay.clear_active()
	var mover := active_unit
	await mover.walk_path(grid, _move_field.path_to(cell))
	mover.snap_to_cell(grid)
	mover.pay(Unit.Cost.EITHER)
	_mark_active()
	_after_player_action()


func _try_flash_to(cell: Vector2i) -> void:
	if cell not in overlay.flash_cells:
		return
	phase = Phase.BUSY
	overlay.clear()
	overlay.clear_active()
	var blinker := active_unit
	await blinker.flash_to(grid, cell)
	blinker.snap_to_cell(grid)
	blinker.pay(Unit.Cost.BONUS)
	_mark_active()
	EventBus.battle_log.emit("%s flash steps." % blinker.display_name)
	_after_player_action()


func _try_act_on(cell: Vector2i) -> void:
	if cell not in overlay.action_cells:
		return
	if not _apply_ability(active_unit, _pending_ability, cell):
		return
	phase = Phase.BUSY
	overlay.clear()
	await get_tree().create_timer(0.35).timeout
	_after_player_action()


func _after_player_action() -> void:
	if _resolve_outcome():
		return
	_advance_selection()


# --- resolution --------------------------------------------------------------


## Returns false if nothing valid was hit, so the player keeps their selection.
func _apply_ability(user: Unit, ability_id: String, centre: Vector2i) -> bool:
	var ability := Database.ability(ability_id)
	var hits: Array[Unit] = []
	for cell in AbilityResolver.affected_cells(ability, centre):
		var target := unit_at(cell)
		if target != null and AbilityResolver.is_valid_target(user, ability, target):
			hits.append(target)
	if hits.is_empty():
		return false

	user.face_towards(centre)
	for target in hits:
		EventBus.battle_log.emit(AbilityResolver.apply(user, ability, target, ability_id))
		_note_in_the_journal(user, ability_id, target)
		if not target.is_alive():
			target.visible = false
			_award_kill(user, target)

	# Counted once for the swing, not once per body it caught.
	var better := Proficiency.record(user.character, ability_id)
	if better != "":
		EventBus.battle_log.emit(better)
	user.pay(Unit.ability_cost(ability))
	return true


## Watching is how the journal fills in. You learn what a thing hits like by
## being hit, what it is wearing by hitting it, and how much of it there is by
## putting one down.
func _note_in_the_journal(user: Unit, ability_id: String, target: Unit) -> void:
	if sandbox or user.team == target.team:
		return
	var world: World = GameState.world
	if user.team == Unit.Team.ENEMY:
		Journal.note_ability(world, user.template_id, ability_id)
		Journal.note_struck(world, user.template_id)
		return
	Journal.note_wounded(world, target.template_id)
	if not target.is_alive():
		Journal.note_felled(world, target.template_id)


## XP goes to whoever landed the blow, so who does the work matters.
func _award_kill(killer: Unit, victim: Unit) -> void:
	if killer.character == null or killer.team == victim.team:
		return
	var level := victim.character.level if victim.character != null else 1
	for line: String in Progression.award(killer.character, Progression.bounty_for(level), GameState.world):
		EventBus.battle_log.emit(line)


func _resolve_outcome() -> bool:
	var players_alive := units.any(
		func(u: Unit) -> bool: return u.is_alive() and u.team == Unit.Team.PLAYER
	)
	var enemies_alive := units.any(
		func(u: Unit) -> bool: return u.is_alive() and u.team != Unit.Team.PLAYER
	)
	if players_alive and enemies_alive:
		return false

	phase = Phase.FINISHED
	overlay.clear()
	overlay.clear_active()
	hud.set_squad([], null)
	hud.hide_commands()
	hud.show_result(players_alive)
	if sandbox:
		# The coliseum carries its wounds between rounds; the training ground
		# does not. Either way nothing is written back onto the world.
		if bool(boot_payload.get("heal", true)):
			GameState.heal_party()
		else:
			_carry_wounds()
		GameState.set_flag(Arena.VICTORY_FLAG, players_alive)
		_leave_the_field()
		return true
	_settle_the_party()
	if players_alive:
		GameState.mark_battle_cleared(map_id)
	GameState.set_flag("last_victory", players_alive)
	EventBus.battle_finished.emit({"victory": players_alive, "map_id": map_id})
	_leave_the_field()
	return true


## Wounds only. Used on the sand, where nobody rolls for their life because
## nobody is really dying.
func _carry_wounds() -> void:
	for unit in units:
		if unit.team != Unit.Team.PLAYER or unit.character == null:
			continue
		var carried := float(maxi(0, unit.hp)) / float(maxi(1, unit.max_hp))
		unit.character.hp = clampi(
			roundi(carried * float(unit.character.max_hp())), 0, unit.character.max_hp()
		)


## Write the fight back onto the people who fought it: wounds carry, and anyone
## who fell rolls for their life (see [Fate]).
func _settle_the_party() -> void:
	var survivors := units.filter(
		func(u: Unit) -> bool: return u.team == Unit.Team.PLAYER and u.is_alive()
	)
	var standing: Array = survivors.map(func(u: Unit) -> Character: return u.character)

	for unit in units:
		if unit.team != Unit.Team.PLAYER or unit.character == null:
			continue
		if unit.is_alive():
			# Wounds carry as a fraction, so a difficulty that made the party
			# hardier does not write an impossible number back onto them.
			var carried := float(unit.hp) / float(maxi(1, unit.max_hp))
			unit.character.hp = clampi(
				roundi(carried * float(unit.character.max_hp())), 1, unit.character.max_hp()
			)
			Doctrine.reinforce_all(unit.character, GameState.world.steps)
			continue

		var outcome := Fate.resolve(
			unit.character,
			{
				"allies": standing,
				"enemy_kind": _killer_kind(),
				"world": GameState.world,
				"cell": GameState.world.player_cell,
			},
			GameState.world.rng
		)
		EventBus.battle_log.emit(outcome["line"])
		EventBus.character_fell.emit(unit.character, outcome)
		if outcome["outcome"] == Fate.DEAD:
			Memorial.raise(GameState.world, unit.character, GameState.world.player_cell, _killer_kind())
			for line: String in Skein.on_character_fell(GameState.world, unit.character.template_id):
				EventBus.battle_log.emit(line)

	GameState.roster.drop_the_lost()


## What kind of thing won the fight, which decides whether prisoners are taken.
func _killer_kind() -> String:
	for unit in units:
		if unit.team != Unit.Team.PLAYER and unit.is_alive():
			return unit.kind()
	return "default"


func _leave_the_field() -> void:
	await get_tree().create_timer(END_SCREEN_DELAY).timeout
	EventBus.request_scene.emit(boot_payload.get("return_scene", "world"), {})


# --- queries -----------------------------------------------------------------


func unit_at(cell: Vector2i) -> Unit:
	for unit in units:
		if unit.is_alive() and unit.cell == cell:
			return unit
	return null


func _mark_active() -> void:
	var waiting: Array[Vector2i] = []
	for unit in _ready_squad():
		if unit != active_unit:
			waiting.append(unit.cell)
	overlay.pending_cells = waiting
	if active_unit == null:
		overlay.clear_active()
		return
	overlay.set_active(active_unit.cell, active_unit.team != Unit.Team.PLAYER)
	camera.focus_on(active_unit.position)


func _build_move_field(unit: Unit) -> MoveField:
	return pathfinder.build_move_field(
		unit.cell,
		unit.move_points,
		unit.jump,
		func(cell: Vector2i) -> bool:
			var other := unit_at(cell)
			return other != null and other.is_hostile_to(unit)
	)


func _build_flash_cells(unit: Unit) -> Array[Vector2i]:
	return pathfinder.flash_cells(
		unit.cell,
		unit.flash_step,
		func(cell: Vector2i) -> bool: return unit_at(cell) == null
	)


func _to_cell(value: Variant) -> Vector2i:
	var pair: Array = value
	return Vector2i(int(pair[0]), int(pair[1]))


## Both sides start looking at the opposing line, so the opening exchange isn't
## a free back attack on whoever happens to be facing the wrong way.
func _orient_starting_facings() -> void:
	for unit in units:
		var centre := Vector2.ZERO
		var count := 0
		for other in units:
			if other.is_hostile_to(unit):
				centre += Vector2(other.cell)
				count += 1
		if count > 0:
			unit.face_towards(Vector2i((centre / float(count)).round()))
