extends CanvasLayer
## The quick wheel ([D326], call BX; Ewan's play-test 8, after Ark Survival Evolved's: "if I click
## the scroll wheel, then I would be able to click a few options... kind of like a quick menu
## instead of going into the whole menu"). Always present under [Game], like the tip card.
##
## Hold the middle button still for `quick_wheel.hold` seconds and a ring of choices opens round
## the pointer; point at one and let go to take it, or let go in the middle to take nothing. A
## middle press that moves first is the camera's drag, as before. What the ring holds is
## `quick_wheel.walking` on the land and `quick_wheel.fighting` while a fight is on
## (`data/world_rules.json`); a choice is said on [signal EventBus.quick_wheel_chose], and the
## screens it opens are asked for the way their keys ask.

const Formations := preload("res://src/skirmish/formations.gd")

const RADIUS := 120.0
const INNER := 34.0
## How far the pointer may wander before a held press is the camera's drag instead.
const STILL := 8.0

var _held := false
var _held_for := 0.0
var _pressed_at := Vector2.ZERO
var _open := false
var _items: Array = []
var _centre := Vector2.ZERO
var _pointing := -1
var _ring: Control
## Opened by the touch bar's More ([D376]): the next tap on the glass picks, and the press and
## release the engine makes of it as a mouse are swallowed, so the tap does not walk the party there.
var _tapped := false
var _swallow_release := false


func _ready() -> void:
	layer = 8
	_ring = Control.new()
	_ring.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.draw.connect(_draw_ring)
	_ring.hide()
	add_child(_ring)
	EventBus.quick_wheel_requested.connect(open_for_tap)


static func rules() -> Dictionary:
	return Database.world_rules.get("quick_wheel", {})


func is_open() -> bool:
	return _open


## The ring's choices where the game is now: none off the walked ground or with a screen open.
func choices() -> Array:
	if not bool(rules().get("on", false)) or GameState.world == null or GameState.roster == null:
		return []
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.is_open():
			return []
	var fighting := not get_tree().get_nodes_in_group(EventBus.FIGHT_GROUP).is_empty()
	return rules().get("fighting" if fighting else "walking", [])


## Open the ring in the middle of the screen, for a finger to tap a choice on ([D376]).
func open_for_tap() -> void:
	if _open:
		take(-1)
		return
	_tapped = open_at(_ring.get_viewport_rect().size * 0.5)


func _input(event: InputEvent) -> void:
	if _tap_input(event):
		get_viewport().set_input_as_handled()
		return
	var press := event as InputEventMouseButton
	if press != null and press.button_index == MOUSE_BUTTON_MIDDLE:
		if press.pressed:
			_held = true
			_held_for = 0.0
			_pressed_at = press.position
		else:
			_held = false
			if _open:
				# The release still reaches the camera, so its drag is let go too.
				take(_pointing)
		return
	var motion := event as InputEventMouseMotion
	if motion == null:
		return
	if _open:
		_point_at(motion.position)
		get_viewport().set_input_as_handled()
	elif _held and motion.position.distance_to(_pressed_at) > STILL:
		_held = false


## A finger on a ring opened for tapping: down points, up takes (outside the ring or in its middle,
## nothing). Whether [param event] was the ring's.
func _tap_input(event: InputEvent) -> bool:
	var mouse := event as InputEventMouseButton
	if _swallow_release and mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT and not mouse.pressed:
		_swallow_release = false
		return true
	if not (_open and _tapped):
		return false
	var touch := event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_point_at(touch.position)
		else:
			_point_at(touch.position)
			_tapped = false
			_swallow_release = true
			take(_pointing if touch.position.distance_to(_centre) <= RADIUS else -1)
		return true
	if event is InputEventScreenDrag:
		_point_at((event as InputEventScreenDrag).position)
		return true
	# The mouse the engine makes of the finger, or a mouse on a touch screen: a left click picks.
	if mouse != null and mouse.button_index == MOUSE_BUTTON_LEFT:
		if not mouse.pressed and not _swallow_release:
			_point_at(mouse.position)
			_tapped = false
			take(_pointing if mouse.position.distance_to(_centre) <= RADIUS else -1)
		return true
	return false


func _process(delta: float) -> void:
	if not _held or _open:
		return
	_held_for += delta / maxf(0.01, Engine.time_scale)
	if _held_for >= float(rules().get("hold", 0.3)):
		_held = false
		open_at(_pressed_at)


## Open the ring round [param at]. Returns whether there was anything to offer.
func open_at(at: Vector2) -> bool:
	_items = choices()
	if _items.is_empty():
		return false
	_open = true
	_centre = at
	_pointing = -1
	_ring.show()
	_ring.queue_redraw()
	return true


func _point_at(at: Vector2) -> void:
	var off := at - _centre
	var was := _pointing
	_pointing = -1 if off.length() < INNER else sector_of(off, _items.size())
	if _pointing != was:
		_ring.queue_redraw()


## Which of [param count] slices, the first straight up and going round clockwise, [param off] is in.
static func sector_of(off: Vector2, count: int) -> int:
	if count <= 0:
		return -1
	var turn := fposmod(atan2(off.x, -off.y), TAU)
	return int(floor((turn + PI / count) / (TAU / count))) % count


## Take the choice at [param index] (-1 takes nothing) and close the ring.
func take(index: int) -> void:
	var item: Dictionary = _items[index] if index >= 0 and index < _items.size() else {}
	_open = false
	_tapped = false
	_items = []
	_ring.hide()
	if item.is_empty():
		return
	var id := str(item.get("id", ""))
	match id:
		"party":
			EventBus.party_screen_requested.emit()
		"map":
			EventBus.map_requested.emit()
		"journal":
			EventBus.journal_requested.emit()
		"formation":
			GameState.formation = Formations.next(GameState.formation)
			EventBus.area_note.emit("Formation: %s." % Formations.word(GameState.formation, GameState.roster.party.size()))
		"auto":
			Pace.auto = not Pace.auto
		"eat":
			if get_tree().get_nodes_in_group(EventBus.FIGHT_GROUP).is_empty():
				EventBus.area_note.emit(feed_the_hurt())
	EventBus.quick_wheel_chose.emit(id)


## Whoever of the company is worst hurt eats (or drinks) the least that mends them, food first.
## Returns the line, or why nothing was eaten.
static func feed_the_hurt() -> String:
	var hurt: Character = null
	for character: Character in GameState.roster.party_members():
		if not character.is_available() or character.current_hp() >= character.max_hp():
			continue
		if hurt == null or float(character.current_hp()) / character.max_hp() < float(hurt.current_hp()) / hurt.max_hp():
			hurt = character
	if hurt == null:
		return "Nobody needs it."
	var food: Array = Gear.draughts().filter(func(id: String) -> bool: return Gear.taken(id) == "eat")
	var pick: Array = food if not food.is_empty() else Gear.draughts()
	if pick.is_empty():
		return "Nothing in the packs to eat or drink."
	return Gear.drink(hurt, str(pick[0]))


func _draw_ring() -> void:
	var count := _items.size()
	if count == 0:
		return
	var font := ThemeDB.fallback_font
	_ring.draw_circle(_centre, RADIUS, Color(0.06, 0.08, 0.1, 0.82))
	for i in count:
		var mid := TAU * i / count
		if i == _pointing:
			var points := PackedVector2Array([_centre])
			for k in 13:
				var a := mid - PI / count + (TAU / count) * k / 12.0
				points.append(_centre + Vector2(sin(a), -cos(a)) * RADIUS)
			_ring.draw_colored_polygon(points, Color(0.35, 0.55, 0.7, 0.55))
		var edge := mid - PI / count
		_ring.draw_line(_centre + Vector2(sin(edge), -cos(edge)) * INNER, _centre + Vector2(sin(edge), -cos(edge)) * RADIUS,
				Color(0.4, 0.55, 0.65, 0.6), 1.5)
		var label := str(_items[i].get("label", "?"))
		var at := _centre + Vector2(sin(mid), -cos(mid)) * (RADIUS * 0.66)
		var wide := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_ring.draw_string(font, at + Vector2(-wide * 0.5, 5.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
				Color(1.0, 0.9, 0.6) if i == _pointing else Color(0.85, 0.9, 0.95))
	_ring.draw_circle(_centre, INNER, Color(0.1, 0.12, 0.15, 0.95))
	_ring.draw_arc(_centre, RADIUS, 0.0, TAU, 64, Color(0.4, 0.55, 0.65, 0.8), 2.0)
	var lead := GameState.roster.player() if GameState.roster != null else null
	var name_ := lead.display_name if lead != null else ""
	var w := font.get_string_size(name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	_ring.draw_string(font, _centre + Vector2(-w * 0.5, 4.0), name_, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.85, 0.9, 0.95))
