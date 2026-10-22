extends Node
## The game pad (autoload: `Pad`): whether one is in the player's hands, what
## its buttons are called, and keeping a menu's focus where a thumb can find it.
##
## Every action in the input map carries a key and, where it means anything on
## a controller, a pad button too (the README has the layout, and
## `docs/10-manual-tests.md` §P walks it). The scenes go on listening for
## actions; this only answers the questions a pad adds:
##
## - Which device was touched last, so a hint line says "A to step in" to a
##   pad and "E to step in" to a keyboard ([method key]).
## - Which button a menu should be sitting on. A mouse needs no focus and a
##   keyboard mostly has it already; a pad has nothing else. Whatever modal
##   screen is on top, or a menu scene with nothing over it, is kept with one of
##   its buttons focused while the pad is in use ([method settle_focus]).
##
## The layout is Xbox-named, which is what Godot's standard mapping calls the
## face buttons: A is the bottom one (Cross on a PlayStation pad), B the right
## (Circle), X the left (Square), Y the top (Triangle).

signal changed

## Face and shoulder buttons, as a hint line says them.
const BUTTON_GLYPHS := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_START: "Start",
	JOY_BUTTON_LEFT_STICK: "L3", JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "D-pad", JOY_BUTTON_DPAD_DOWN: "D-pad",
	JOY_BUTTON_DPAD_LEFT: "D-pad", JOY_BUTTON_DPAD_RIGHT: "D-pad",
}
const AXIS_GLYPHS := {
	JOY_AXIS_LEFT_X: "Left stick", JOY_AXIS_LEFT_Y: "Left stick",
	JOY_AXIS_RIGHT_X: "Right stick", JOY_AXIS_RIGHT_Y: "Right stick",
	JOY_AXIS_TRIGGER_LEFT: "LT", JOY_AXIS_TRIGGER_RIGHT: "RT",
}

## Scenes that are all buttons, and so are kept focused. The walk, the square
## and the fights are not: there the stick is walking or steering a cursor,
## and a focused button would take the stick off it.
const MENU_SCENES := [
	"title", "temper_quiz", "character_select", "training", "coliseum", "museum", "summary",
]

## How far a stick must lean before it counts as the pad being picked up.
## Less than this is a resting thumb or a worn stick drifting.
const STICK_WAKE := 0.5

## The last thing the player touched was a pad.
var using_pad: bool = false

var _scene_key: String = ""
## What was focused last, said as its text and tooltip, so a screen that builds
## its buttons again after every press puts the focus back where it was.
var _last_focus_key: String = ""
## `touch_words.swaps`, compiled once ([D377]).
var _swaps: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.scene_changed.connect(func(scene_key: String) -> void: _scene_key = scene_key)
	get_viewport().gui_focus_changed.connect(_on_focus_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		set_using_pad(true)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) >= STICK_WAKE:
			set_using_pad(true)
	elif (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		set_using_pad(false)
	elif event is InputEventScreenTouch:
		set_using_pad(false)


func _process(_delta: float) -> void:
	if using_pad:
		settle_focus()


func set_using_pad(on: bool) -> void:
	if on == using_pad:
		return
	using_pad = on
	changed.emit()


# --- what to call a button ---------------------------------------------------


## What to press for [param action] on whatever the player is holding: "A" on
## a pad, "E" on a keyboard. An action with nothing on the current device says
## [param fallback]'s button instead, and "" if that has none either.
func key(action: String, fallback: String = "") -> String:
	if on_touch():
		var named := touch_name(action)
		if named != "":
			return named
	var text := pad_glyph(action) if using_pad else key_text(action)
	if text == "" and fallback != "":
		return key(fallback)
	return text


## How the hint lines say "walk".
func walk_text() -> String:
	if on_touch():
		return str(touch_words().get("walk", "The stick"))
	return "Left stick" if using_pad else "WASD"


# --- what a phone calls it ([D377]) -------------------------------------------


## Whether the lines are said for a thumb: the touch controls on, and no pad in hand.
func on_touch() -> bool:
	return not using_pad and Pace.is_touch_enabled()


static func touch_words() -> Dictionary:
	return Database.world_rules.get("touch_words", {})


## What the touch bar calls [param action] ("Act", "Back", "Party"), or "" when it has no button.
func touch_name(action: String) -> String:
	return str((touch_words().get("names", {}) as Dictionary).get(action, ""))


## [param line], written for a keyboard, said for a thumb when [method on_touch]: "WASD to walk"
## becomes "The stick walks", "E to talk" "Act to talk", "H to hire" "Tap to hire", a click a tap.
## Anywhere else it comes back as it was.
func say(line: String) -> String:
	if not on_touch() or line == "":
		return line
	if _swaps.is_empty():
		for pair: Array in touch_words().get("swaps", []):
			var pattern := RegEx.new()
			if pattern.compile(str(pair[0])) == OK:
				_swaps.append([pattern, str(pair[1])])
	for swap: Array in _swaps:
		line = (swap[0] as RegEx).sub(line, str(swap[1]), true)
	return line


## The pad button bound to [param action], or "" when it has none.
func pad_glyph(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		var said := glyph_of(event)
		if said != "":
			return said
	return ""


## The key bound to [param action], or "" when it has none.
func key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE \
					else key_event.keycode
			return OS.get_keycode_string(code)
	return ""


## A pad event, as a hint line says it; "" for anything that is not a pad's.
static func glyph_of(event: InputEvent) -> String:
	if event is InputEventJoypadButton:
		return str(BUTTON_GLYPHS.get((event as InputEventJoypadButton).button_index, "Button %d" \
				% (event as InputEventJoypadButton).button_index))
	if event is InputEventJoypadMotion:
		return str(AXIS_GLYPHS.get((event as InputEventJoypadMotion).axis, "Axis %d" \
				% (event as InputEventJoypadMotion).axis))
	return ""


# --- where the focus sits ----------------------------------------------------


## Whatever should hold the pad's focus right now: the open modal screen on
## top, else a menu scene, else nothing — the walk and the fights steer
## themselves.
func focus_root() -> Node:
	var top: Node = null
	var top_layer := -1000000
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		# The letterbox is skipped with A or B; it has nothing to focus.
		if overlay.is_in_group(EventBus.CUTSCENE_FRAME_GROUP):
			continue
		if not (overlay.has_method("is_open") and overlay.is_open()):
			continue
		var layer := (overlay as CanvasLayer).layer if overlay is CanvasLayer else 0
		if layer >= top_layer:
			top = overlay
			top_layer = layer
	if top != null:
		return top
	if MENU_SCENES.has(_scene_key):
		return get_tree().get_first_node_in_group(EventBus.ACTIVE_SCENE_GROUP)
	return null


## Puts the focus on a button of [method focus_root] if it is not on one
## already. True when it moved the focus.
func settle_focus() -> bool:
	var root := focus_root()
	if root == null:
		return false
	var owner := get_viewport().gui_get_focus_owner()
	if owner != null and owner.is_visible_in_tree() and root.is_ancestor_of(owner):
		return false
	# A button left focused under a screen that has none of its own (a line
	# of dialogue, say) would take the A meant for that screen.
	if owner != null:
		owner.release_focus()
	var target := first_focusable(root, _last_focus_key)
	if target == null:
		return false
	target.grab_focus()
	return true


## The first button under [param root] a pad can land on, preferring one that
## reads [param preferred] (see [member _last_focus_key]). Buttons a screen
## made unfocusable so the keyboard would not wander onto them are opened up
## on the way: on a pad, focus is the only way to press anything.
static func first_focusable(root: Node, preferred: String = "") -> Control:
	var first: Control = null
	var found: Array[Control] = []
	_collect(root, found)
	for control in found:
		if preferred != "" and focus_key(control) == preferred:
			return control
		if first == null:
			first = control
	return first


static func _collect(node: Node, into: Array[Control]) -> void:
	for child in node.get_children():
		if child is Control and not (child as Control).is_visible_in_tree():
			continue
		if child is BaseButton and not (child as BaseButton).disabled:
			var button := child as BaseButton
			if button.focus_mode == Control.FOCUS_NONE:
				button.focus_mode = Control.FOCUS_ALL
			into.append(button)
		elif child is Slider:
			into.append(child as Control)
		_collect(child, into)


## A control, said as what is written on it.
static func focus_key(control: Control) -> String:
	var text: String = str(control.get("text")) if control is BaseButton else str(control.name)
	return "%s|%s" % [text, control.tooltip_text]


func _on_focus_changed(control: Control) -> void:
	if control == null:
		return
	_last_focus_key = focus_key(control)
	# A focused button scrolled out of sight is a pad user pressing blind.
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			# Deferred, and asked again then: a screen that rebuilds its list on focus (the
			# journal, a level's choice) has freed or moved the button by the time it runs, and
			# Godot says "Must be an ancestor of the control" (Ewan's play log, 2026-10-17, x10).
			var scroll := parent as ScrollContainer
			(func() -> void:
				if is_instance_valid(scroll) and is_instance_valid(control) and scroll.is_ancestor_of(control):
					scroll.ensure_control_visible(control)).call_deferred()
		parent = parent.get_parent()
