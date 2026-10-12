extends CanvasLayer
## A banner across the top of the screen when somebody in the party gains a
## level or takes up a path ([D66]): their face, the level, what went up, and
## — when a path or a power is now owed — a button straight to it.
##
## It asks nothing and stops nothing. A fight runs on underneath it, a press on
## it puts it away, and it goes by itself after a few seconds. Levels that land
## together are shown one after another; two for the same person in a row
## become one banner from the first number to the last.
##
## Lives on [Game], above whichever scene is in. Loaded by path, not by
## `class_name` ([D41]).

const SheetParts := preload("res://src/ui/sheet_parts.gd")

## Seconds a banner stays up, in the player's seconds rather than the game's.
const SHOWN_FOR := 5.0
const ARRIVE := 0.35
const LEAVE := 0.5
## Banners waiting at most; past this the oldest waiting one is dropped.
const MOST_WAITING := 4
const WIDTH := 600.0

const GOLD := Color(0.965, 0.827, 0.443)
const PAPER := Color(0.95, 0.93, 0.88)
const QUIET := Color(0.68, 0.70, 0.76)
const GAIN := Color(0.55, 0.88, 0.55)

var _panel: PanelContainer
var _face: TextureRect
var _ring: PanelContainer
var _kicker: Label
var _title: Label
var _sub: Label
var _gains: HFlowContainer
var _rule: ColorRect
var _go: Button

var _queue: Array[Dictionary] = []
var _showing: Dictionary = {}
var _tween: Tween


func _ready() -> void:
	layer = 80
	# A paused fight still wants to see who just levelled.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	EventBus.levelled_up.connect(_on_levelled_up)
	EventBus.class_chosen.connect(_on_class_chosen)
	EventBus.scene_changed.connect(func(scene_key: String) -> void:
		if scene_key == "title":
			_queue.clear()
			_hide_now()
	)


func is_showing() -> bool:
	return _panel.visible


## What the banner on screen is about: `{ kind, id, level }`, empty with none up.
func showing() -> Dictionary:
	if not _panel.visible:
		return {}
	return {
		"kind": str(_showing.get("kind", "")),
		"id": str(_showing.get("id", "")),
		"level": int(_showing.get("level", 0)),
	}


func waiting() -> int:
	return _queue.size()


func dismiss() -> void:
	if not _panel.visible:
		return
	if _tween != null:
		_tween.kill()
	_tween = _panel.create_tween().set_ignore_time_scale(true)
	_tween.tween_property(_panel, "modulate:a", 0.0, LEAVE * 0.5)
	_tween.tween_callback(_finish)


# --- what is worth a banner -----------------------------------------------------


func _in_party(character: Character) -> bool:
	return GameState.roster != null and GameState.roster.party_members().has(character)


func _on_levelled_up(who: RefCounted, before: Dictionary) -> void:
	var character := who as Character
	if character == null or not _in_party(character):
		return
	# A second level for somebody already waiting folds into theirs.
	for waiting_one: Dictionary in _queue:
		if waiting_one.get("kind") == "level" and waiting_one.get("id") == character.id:
			waiting_one["level"] = character.level
			return
	_enqueue({
		"kind": "level", "id": character.id, "level": character.level,
		"from": character.level - 1, "before": before, "character": character,
	})


func _on_class_chosen(who: RefCounted) -> void:
	var character := who as Character
	if character == null or not _in_party(character):
		return
	_enqueue({ "kind": "path", "id": character.id, "level": character.level, "character": character })


func _enqueue(entry: Dictionary) -> void:
	_queue.append(entry)
	while _queue.size() > MOST_WAITING:
		_queue.pop_front()
	if not _panel.visible:
		_next()


func _next() -> void:
	if _queue.is_empty():
		return
	_showing = _queue.pop_front()
	_fill(_showing)
	_arrive()


func _finish() -> void:
	_hide_now()
	_next()


func _hide_now() -> void:
	if _tween != null:
		_tween.kill()
	_panel.hide()
	_showing = {}


# --- what it says ---------------------------------------------------------------


func _fill(entry: Dictionary) -> void:
	var character: Character = entry["character"]
	var colour := SheetParts.colour_of(character)
	var path := str(entry.get("kind")) == "path"
	var edge := colour if path else GOLD

	var face := SheetParts.box(Color(0.07, 0.06, 0.09, 0.97), edge, 2, 14)
	face.shadow_color = Color(edge, 0.35)
	face.shadow_size = 22
	face.content_margin_left = 20
	face.content_margin_right = 20
	face.content_margin_top = 16
	face.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", face)
	_ring.add_theme_stylebox_override("panel", SheetParts.box(colour.darkened(0.7), colour, 3, 44))
	_face.texture = Database.unit_face(character.template_id)
	_rule.color = edge

	for chip in _gains.get_children():
		_gains.remove_child(chip)
		chip.queue_free()

	if path:
		_kicker.text = "T H E   P A T H   I S   C H O S E N"
		_kicker.add_theme_color_override("font_color", colour.lightened(0.3))
		_title.text = "%s walks the way of the %s" % [character.display_name, character.class_name_text()]
		_sub.text = "Powers of %s.  Starts with %s." % [
			"  ·  ".join(SheetParts.theme_names(character.class_id)),
			", ".join(SheetParts.grant_names(character.class_id)),
		]
		_sub.add_theme_color_override("font_color", QUIET)
	else:
		_kicker.text = "L E V E L   U P"
		_kicker.add_theme_color_override("font_color", GOLD)
		var from := int(entry.get("from", character.level - 1))
		var to := int(entry.get("level", character.level))
		_title.text = "%s reaches level %d" % [character.display_name, to] if to - from <= 1 \
				else "%s climbs from level %d to %d" % [character.display_name, from, to]
		_sub.text = character.class_name_text()
		_sub.add_theme_color_override("font_color", colour.lightened(0.2))
		for gained: Array in SheetParts.gains(entry.get("before", {}), SheetParts.growth_snapshot(character)):
			_gains.add_child(_chip(str(gained[0]), int(gained[1]), int(gained[2])))

	var owed := ""
	if character.pending_class_choice:
		owed = "Choose a path"
	elif character.rungs > 0 and not character.trees.is_empty():
		owed = "Take a power" if character.rungs == 1 else "Take %d powers" % character.rungs
	_go.visible = owed != ""
	_go.text = owed
	for pair: Array in [
		["normal", SheetParts.box(Color(0.22, 0.17, 0.06), GOLD, 2, 8)],
		["hover", SheetParts.box(Color(0.36, 0.28, 0.08), GOLD.lightened(0.3), 2, 8)],
		["pressed", SheetParts.box(Color(0.15, 0.11, 0.04), GOLD, 2, 8)],
	]:
		var skin: StyleBoxFlat = pair[1]
		skin.content_margin_left = 18
		skin.content_margin_right = 18
		skin.content_margin_top = 6
		skin.content_margin_bottom = 6
		_go.add_theme_stylebox_override(str(pair[0]), skin)


func _chip(label: String, was: int, now: int) -> Control:
	var chip := PanelContainer.new()
	var face := SheetParts.box(Color(0.12, 0.16, 0.12, 0.9), Color(GAIN, 0.5), 1, 10)
	face.content_margin_left = 10
	face.content_margin_right = 10
	face.content_margin_top = 3
	face.content_margin_bottom = 3
	chip.add_theme_stylebox_override("panel", face)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := Label.new()
	text.text = "%s  %d  >  %d" % [label, was, now]
	text.add_theme_font_size_override("font_size", 14)
	text.add_theme_color_override("font_color", GAIN)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(text)
	return chip


# --- how it moves ---------------------------------------------------------------


func _arrive() -> void:
	_panel.show()
	_panel.modulate.a = 0.0
	_rule.custom_minimum_size.x = 0.0
	_panel.reset_size()
	# Laid out first, so it grows from its own middle.
	await get_tree().process_frame
	if not _panel.visible:
		return
	_panel.pivot_offset = _panel.size / 2.0
	_panel.scale = Vector2(0.86, 0.86)
	if _tween != null:
		_tween.kill()
	_tween = _panel.create_tween().set_ignore_time_scale(true)
	_tween.set_parallel(true)
	_tween.tween_property(_panel, "modulate:a", 1.0, ARRIVE)
	_tween.tween_property(_panel, "scale", Vector2.ONE, ARRIVE) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_rule, "custom_minimum_size:x", WIDTH - 160.0, ARRIVE * 2.0) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.set_parallel(false)
	_tween.tween_interval(SHOWN_FOR)
	_tween.tween_property(_panel, "modulate:a", 0.0, LEAVE)
	_tween.tween_callback(_finish)
	Sfx.play("level_up", -4.0)


func _go_to_choice() -> void:
	var character: Character = _showing.get("character")
	dismiss()
	if character != null:
		EventBus.growth_choice_requested.emit(character)


func _build() -> void:
	var holder := Control.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(holder)

	var centre := CenterContainer.new()
	centre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	centre.offset_top = 64.0
	centre.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(centre)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			dismiss()
		elif event is InputEventScreenTouch and event.pressed:
			dismiss()
	)
	centre.add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(row)

	_ring = PanelContainer.new()
	_ring.custom_minimum_size = Vector2(88, 88)
	_ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_ring)
	_face = TextureRect.new()
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.add_child(_face)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)

	_kicker = _label(13)
	column.add_child(_kicker)
	_title = _label(25)
	_title.add_theme_color_override("font_color", PAPER)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_constant_override("outline_size", 4)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	column.add_child(_title)
	_rule = ColorRect.new()
	_rule.custom_minimum_size = Vector2(0, 2)
	_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_rule)
	_sub = _label(15)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_sub)
	_gains = HFlowContainer.new()
	_gains.add_theme_constant_override("h_separation", 8)
	_gains.add_theme_constant_override("v_separation", 6)
	_gains.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_gains)

	_go = Button.new()
	_go.custom_minimum_size = Vector2(0, 44)
	_go.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_go.focus_mode = Control.FOCUS_NONE
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		_go.add_theme_color_override(state, GOLD)
	_go.pressed.connect(_go_to_choice)
	Sfx.attend(_go)
	column.add_child(_go)

	_panel.hide()


func _label(size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
