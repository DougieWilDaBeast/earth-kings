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
## Someone of yours being held at the tile you are standing on.
var _captive_here: Character = null


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
	_captive_here = null
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
	_check_for_captives(site)


## Anyone of yours being held here can be bought back, or taken back.
func _check_for_captives(site: Site) -> void:
	for character in GameState.roster.characters:
		if character.status != Fate.CAPTURED:
			continue
		if Captivity.held_at(character) != site.cell:
			continue
		_captive_here = character
		var price := int(character.captive.get("ransom", 0))
		_note("%s is being held here. They want %d gold." % [character.display_name, price])
		return


func _rest_at(site: Site) -> void:
	if GameState.party_is_wounded():
		GameState.heal_party()
		_note("You rest at %s. Everyone is patched up." % site.display_name)
	else:
		_note("%s is quiet." % site.display_name)
	if site.kind != Site.HUT:
		Market.refresh(site, world)


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
	if site.cleared:
		_note("%s is shut for good." % site.display_name)
		return
	if not site.open:
		_note("%s is shut." % site.label())
		return

	var party := GameState.party_characters()
	_note("%s stands open." % site.label())
	_begin_battle(Encounter.for_gate(world, site, 0, true, party, world.rng))
	# Shutting a gate is permanent; nothing behind it comes back.
	world.close_gate(site)
	for line: String in Spoils.for_gate(world, site, party):
		_note(line)


func _climb(site: Site) -> void:
	if world.tower_is_topped():
		_note("You have already stood on the last floor.")
		return

	var next_floor := world.tower_floor + 1
	_note("The Tower opens onto floor %d of %d." % [next_floor, world.tower_floors()])
	world.tower_floor = next_floor
	_begin_battle(Encounter.for_tower(world, site, next_floor, GameState.party_characters(), world.rng))
	for line: String in Spoils.for_tower_floor(world, next_floor, GameState.party_characters()):
		_note(line)

	if world.tower_is_topped():
		world.tower_topped = true
		_note("There are no more floors above you.")


# --- party --------------------------------------------------------------------


func _check_party() -> void:
	for character in GameState.roster.party_members():
		for forgotten: String in Doctrine.decay(character, world.steps):
			_note("%s can no longer recall %s." % [character.display_name, Doctrine.title(forgotten)])

	# Nobody waits forever for their friends.
	for character in GameState.roster.characters:
		if Captivity.is_overdue(character, world):
			if Captivity.resolve_deadline(character, world) == Captivity.SOLD:
				_note("%s was sold on. They are not coming back." % character.display_name)
			else:
				_note("%s is still being held, and the price has gone up." % character.display_name)

	if GameState.roster.run_is_over():
		_end_run()
		return

	_hint.text = _prompt()


## The one line at the bottom telling you what you can do where you stand.
func _prompt() -> String:
	var choosing := GameState.roster.awaiting_class_choice()
	if choosing != null:
		return "%s is ready to choose a path — press P." % choosing.display_name

	if _captive_here != null:
		return "R to ransom %s for %d gold  ·  F to take them back by force." % [
			_captive_here.display_name, int(_captive_here.captive.get("ransom", 0))
		]

	var site := world.site_at(world.player_cell)
	if site != null and site.kind != Site.HUT:
		var offer := Market.hire_offer(site)
		var parts: Array[String] = []
		if not offer.is_empty():
			parts.append("H to hire %s (level %d, %d gold)" % [
				offer["display_name"], offer["level"], Market.hire_cost(offer)
			])
		var goods := Market.wares(site)
		if not goods.is_empty():
			parts.append("B to buy %s (%d gold)" % [
				Database.equipment_piece(goods[0]).get("display_name", goods[0]), Market.price_of(goods[0])
			])
		if not parts.is_empty():
			return "  ·  ".join(parts)

	return "P for the party  ·  Esc for the menu"


## Permadeath follows the player. Companions come and go, and some of them do
## not get to see the end of it.
func _end_run() -> void:
	_busy = true
	_note("%s falls, and the story stops here." % GameState.roster.player().display_name)
	_hint.text = ""
	EventBus.run_ended.emit()
	await get_tree().create_timer(RUN_OVER_DELAY).timeout
	EventBus.request_scene.emit("title", {})


func _unhandled_input(event: InputEvent) -> void:
	if _busy or not event.is_pressed() or event.is_echo() or not event is InputEventKey:
		return
	match event.keycode:
		KEY_P:
			get_viewport().set_input_as_handled()
			EventBus.party_screen_requested.emit()
		KEY_H:
			get_viewport().set_input_as_handled()
			_hire_here()
		KEY_B:
			get_viewport().set_input_as_handled()
			_buy_here()
		KEY_R:
			get_viewport().set_input_as_handled()
			_ransom_here()
		KEY_F:
			get_viewport().set_input_as_handled()
			_fight_for_captive()


func _hire_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var offer := Market.hire_offer(site)
	if offer.is_empty():
		return
	if GameState.roster.party.size() >= Roster.MAX_PARTY:
		_note("You have nobody to spare a place for.")
		return

	var hired := Market.hire(site, GameState.roster, world)
	if hired == null:
		_note("You cannot afford %d gold." % Market.hire_cost(offer))
		return
	_note("%s falls in with you." % hired.display_name)
	_refresh()
	_hint.text = _prompt()


func _buy_here() -> void:
	var site := world.site_at(world.player_cell)
	if site == null:
		return
	var goods := Market.wares(site)
	if goods.is_empty():
		return

	var equipment_id: String = goods[0]
	var name: String = Database.equipment_piece(equipment_id).get("display_name", equipment_id)
	if not Market.buy(site, equipment_id, GameState.roster.player()):
		_note("You cannot afford the %s." % name)
		return
	_note("%s takes up the %s." % [GameState.roster.player().display_name, name])
	_refresh()
	_hint.text = _prompt()


func _ransom_here() -> void:
	if _captive_here == null:
		return
	var price := int(_captive_here.captive.get("ransom", 0))
	if not Captivity.ransom(_captive_here, GameState.roster):
		_note("They want %d gold and you do not have it." % price)
		return
	_note("%s is bought back for %d gold." % [_captive_here.display_name, price])
	_captive_here = null
	_refresh()
	_hint.text = _prompt()


## The other way to get someone back. Surviving it is the price.
func _fight_for_captive() -> void:
	if _captive_here == null:
		return
	var freed := _captive_here
	var site := world.site_at(world.player_cell)
	_note("You come for %s the hard way." % freed.display_name)
	_begin_battle(Encounter.for_captors(world, site, GameState.party_characters(), world.rng))
	Captivity.free_by_force(freed, GameState.roster)
	_captive_here = null
	_refresh()


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
