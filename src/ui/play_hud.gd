extends PanelContainer
## The small panel on the screen while walking ([D244], `doug-md`, 2026-10-17: "a small Ui for the
## main screen while playing the game"): the company, one row each — their face, name, level and a
## health bar that goes from green through amber to red — and the purse under them. Press it for
## the party screen. It keeps itself up to date (a few times a second), so nothing has to tell it.
##
## Sizes and colours are `data/world_rules.json` → `play_hud`. Loaded by path ([D41]).

const REFRESH := 0.25

var _rows: VBoxContainer
var _purse: Label
var _clock: float = 0.0
## What the rows last showed, so they are only rebuilt when the company changes.
var _shown: String = ""


static func rules() -> Dictionary:
	return Database.world_rules.get("play_hud", {})


func _ready() -> void:
	name = "PlayHud"
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	tooltip_text = str(rules().get("tooltip", ""))
	var face := StyleBoxFlat.new()
	face.bg_color = Color(0.05, 0.05, 0.08, 0.62)
	face.border_color = Color(0.965, 0.827, 0.443, 0.35)
	face.set_border_width_all(1)
	face.set_corner_radius_all(6)
	face.content_margin_left = 8
	face.content_margin_right = 10
	face.content_margin_top = 6
	face.content_margin_bottom = 6
	add_theme_stylebox_override("panel", face)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 3)
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_rows)
	_purse = Label.new()
	_purse.add_theme_font_size_override("font_size", 13)
	_purse.add_theme_color_override("font_color", Color(0.965, 0.827, 0.443))
	_purse.add_theme_constant_override("outline_size", 4)
	_purse.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
	_purse.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(_purse)
	refresh()


func _process(delta: float) -> void:
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = REFRESH
	_place()
	refresh()


## Under the compass; on a screen too narrow for the top row of buttons to stay right of it (a
## phone held upright), below that row instead.
func _place() -> void:
	var narrow := get_viewport_rect().size.x < float(rules().get("narrow_below", 760))
	position.y = float(rules().get("top_narrow" if narrow else "top", 128))


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) \
		or (event is InputEventScreenTouch and event.pressed)
	if pressed:
		accept_event()
		EventBus.party_screen_requested.emit()


## The company and the purse as they are now.
func refresh() -> void:
	var party: Array = GameState.party_characters() if GameState.roster != null else []
	var key := ",".join(party.map(func(c: Character) -> String: return "%s:%d:%d:%d" % [c.id, c.level, c.current_hp(), c.max_hp()]))
	if key != _shown:
		_shown = key
		_build_rows(party)
	_purse.text = str(rules().get("purse", "{gold} gold")).format({"gold": GameState.gold})


func _build_rows(party: Array) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	var face_size := float(rules().get("face", 30))
	var bar_width := float(rules().get("bar_width", 96))
	for character: Character in party:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face := TextureRect.new()
		face.texture = Database.unit_face(character.template_id)
		face.custom_minimum_size = Vector2(face_size, face_size)
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(face)
		var words := VBoxContainer.new()
		words.add_theme_constant_override("separation", 2)
		words.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var line := Label.new()
		line.text = "%s  L%d" % [character.display_name, character.level]
		line.add_theme_font_size_override("font_size", 12)
		line.add_theme_color_override("font_color", Color(0.93, 0.92, 0.88))
		line.add_theme_constant_override("outline_size", 4)
		line.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.08))
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		words.add_child(line)
		words.add_child(_bar(character, bar_width))
		row.add_child(words)
		_rows.add_child(row)


## A thin health bar: the share left, green when well, amber when hurt, red when close to falling.
func _bar(character: Character, width: float) -> Control:
	var share := clampf(float(character.current_hp()) / float(maxi(1, character.max_hp())), 0.0, 1.0)
	var back := ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 0.55)
	back.custom_minimum_size = Vector2(width, 6)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.tooltip_text = "%d / %d" % [character.current_hp(), character.max_hp()]
	var fill := ColorRect.new()
	fill.color = health_colour(share)
	fill.size = Vector2(width * share, 6)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(fill)
	return back


static func health_colour(share: float) -> Color:
	var hurt := float(rules().get("hurt_below", 0.6))
	var low := float(rules().get("low_below", 0.3))
	if share < low:
		return Color(0.86, 0.26, 0.22)
	if share < hurt:
		return Color(0.92, 0.66, 0.2)
	return Color(0.42, 0.78, 0.36)
