extends CanvasLayer
## The mouse bar ([D390], meeting seven's PC pass, D381): on a computer played with the mouse,
## every key the walk answers is also a button, down the right edge under the corner map, and each
## button's hover names its key (as rebound). `doug-md` plays with a mouse.
##
## Shown only where the touch bar is not (the touch controls off, no pad in hand), on the walked
## ground, and stepping aside while any screen is open. A press is said as the key's own action
## where there is one, so the scenes go on answering one thing; the journal and the map, which are
## bare keys, are asked for on [EventBus]. The words are `data/world_rules.json` → `mouse_bar`.

const PLAY_SCENES := ["world", "area"]
## Under the corner map (14 down, 180 tall) and clear of it.
const TOP := 206.0
const EDGE := 14.0
const WIDTH := 124.0
const BUTTON_HEIGHT := 34.0

var _column: VBoxContainer
var _buttons: Dictionary = {}
var _scene_key := "title"


static func rules() -> Dictionary:
	return Database.world_rules.get("mouse_bar", {})


func _ready() -> void:
	layer = 5
	_column = VBoxContainer.new()
	_column.anchor_left = 1.0
	_column.anchor_right = 1.0
	_column.offset_left = -WIDTH - EDGE
	_column.offset_right = -EDGE
	_column.offset_top = TOP
	_column.add_theme_constant_override("separation", 4)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	for each: Dictionary in rules().get("buttons", []):
		var id := str(each.get("id", ""))
		var button := Button.new()
		button.name = id.capitalize().replace(" ", "") + "Button"
		button.text = str(each.get("label", id))
		button.custom_minimum_size = Vector2(WIDTH, BUTTON_HEIGHT)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(press.bind(id))
		Sfx.attend(button)
		_column.add_child(button)
		_buttons[id] = button

	EventBus.scene_changed.connect(func(key: String) -> void:
		_scene_key = key
		_restate())
	for opening: Signal in [
		EventBus.system_menu_requested, EventBus.party_screen_requested,
		EventBus.journal_requested, EventBus.stash_requested, EventBus.guild_requested,
		EventBus.how_to_play_requested, EventBus.map_requested,
	]:
		opening.connect(_restate)
	EventBus.overlay_closed.connect(_restate)
	EventBus.dialogue_requested.connect(func(_id: String) -> void: _restate())
	EventBus.dialogue_finished.connect(func(_id: String) -> void: _restate())
	EventBus.conversation_requested.connect(func(_lines: Array) -> void: _restate())
	Pace.changed.connect(_restate)
	Pad.changed.connect(_restate)
	_restate()


func is_showing() -> bool:
	return _column.visible


## The button for [param id] ("party", "journal" …), for the suites; null if there is none.
func button(id: String) -> Button:
	return _buttons.get(id, null)


## Every key action the bar presses, for the suite that checks no action is left to a key alone.
static func actions() -> Array:
	var out: Array = []
	for each: Dictionary in rules().get("buttons", []):
		if str(each.get("action", "")) != "":
			out.append(str(each["action"]))
	return out


## Do what the button [param id] stands for, as its key would.
func press(id: String) -> void:
	for each: Dictionary in rules().get("buttons", []):
		if str(each.get("id", "")) != id:
			continue
		var action := str(each.get("action", ""))
		match str(each.get("signal", "")):
			"party":
				EventBus.party_screen_requested.emit()
			"journal":
				EventBus.journal_requested.emit()
			"map":
				EventBus.map_requested.emit()
			"wheel":
				EventBus.quick_wheel_requested.emit()
			"menu":
				EventBus.system_menu_requested.emit()
			_:
				if action != "" and InputMap.has_action(action):
					_say_action(action)
		_restate()
		return


func _say_action(action: String) -> void:
	var press_event := InputEventAction.new()
	press_event.action = action
	press_event.pressed = true
	press_event.strength = 1.0
	Input.parse_input_event(press_event)
	await get_tree().process_frame
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)


func _restate() -> void:
	_lay_out.call_deferred()


func _lay_out() -> void:
	if not is_inside_tree():
		return
	_column.visible = bool(rules().get("on", false)) and not Pace.is_touch_enabled() and not Pad.using_pad \
			and PLAY_SCENES.has(_scene_key) and not _something_open()
	for each: Dictionary in rules().get("buttons", []):
		var id := str(each.get("id", ""))
		var shown: Button = _buttons.get(id, null)
		if shown == null:
			continue
		# Its hover names its key, as rebound ([D390]).
		var key := Pad.key_text(str(each.get("action", ""))) if str(each.get("action", "")) != "" \
				else str(each.get("key", ""))
		shown.tooltip_text = "%s (%s)" % [str(each.get("hover", shown.text)), key] if key != "" \
				else str(each.get("hover", shown.text))
		if id == "auto":
			shown.text = "Auto: %s" % Pace.auto_style_name() if Pace.auto else str(each.get("label", "Auto"))
		elif id == "speed":
			shown.text = "Speed %dx" % int(Pace.speed())


func _something_open() -> bool:
	for group: String in [EventBus.MODAL_OVERLAY_GROUP, EventBus.BIG_MAP_GROUP]:
		for node in get_tree().get_nodes_in_group(group):
			if node.has_method("is_open") and node.is_open():
				return true
	return false
