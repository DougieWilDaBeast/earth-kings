extends CanvasLayer
## A level gained or a path taken, said in a line at the top right of the screen (a third of the
## way down on a phone held upright, [D412]) and gone again: "Bram reached level 6". It sits out
## of the way, takes no clicks, and never covers the fight ([D77], replacing [D67]'s banner, which
## `doug-md` found was in the way). In a fight the one who levelled also
## flickers gold where they stand (see [method Skirmish._on_levelled_up]).
##
## When a path or a power is now owed, the line says so; the party screen (P)
## is where it is chosen. Several at once stack, newest at the bottom, and two
## levels for the same person in quick succession become one line.
##
## Lives on [Game], above whichever scene is in. Loaded by path, not by
## `class_name` ([D41]).

const SheetParts := preload("res://src/ui/sheet_parts.gd")

## Seconds a line stays, in the player's seconds rather than the game's.
const SHOWN_FOR := 4.0
const FADE := 0.6
## Lines on screen at once; the oldest goes when another arrives.
const MOST := 4
const WIDTH := 380.0
## Clear of the touch column down the right of a fight.
const TOUCH_CLEARANCE := 160.0
## How far down the screen the line comes, held upright on a phone ([D412]).
const UPRIGHT_DOWN := 0.36

const GOLD := Color(0.965, 0.827, 0.443)
const QUIET := Color(0.86, 0.84, 0.78)

var _column: VBoxContainer


func _ready() -> void:
	layer = 80
	# A paused fight still says who levelled.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	EventBus.levelled_up.connect(_on_levelled_up)
	EventBus.class_chosen.connect(_on_class_chosen)
	EventBus.scene_changed.connect(func(scene_key: String) -> void:
		if scene_key == "title":
			clear()
	)


## How many lines are up.
func showing() -> int:
	return _column.get_child_count()


## The text of each line up, oldest first.
func lines() -> Array[String]:
	var out: Array[String] = []
	for row in _column.get_children():
		out.append(str(row.get_meta("text", "")))
	return out


func clear() -> void:
	for row in _column.get_children():
		_column.remove_child(row)
		row.queue_free()


func _upright_touch() -> bool:
	var view := get_viewport().get_visible_rect().size
	return Pace.is_touch_enabled() and view.y > view.x


# --- what is worth a line ---------------------------------------------------------


func _in_party(character: Character) -> bool:
	return GameState.roster != null and GameState.roster.party_members().has(character)


func _on_levelled_up(who: RefCounted, _before: Dictionary) -> void:
	var character := who as Character
	if character == null or not _in_party(character):
		return
	var key := "level:%s" % character.id
	var text := "%s reached level %d" % [character.display_name, character.level]
	var owed := ""
	if character.pending_class_choice:
		owed = "a path to choose (P)"
	elif character.rungs > 0 and not character.trees.is_empty():
		owed = "a power to take (P)" if character.rungs == 1 else "%d powers to take (P)" % character.rungs
	_say(key, text, owed, GOLD)
	Sfx.play("level_up", -12.0)


func _on_class_chosen(who: RefCounted) -> void:
	var character := who as Character
	if character == null or not _in_party(character):
		return
	_say("path:%s" % character.id, "%s walks the way of the %s" % [
		character.display_name, character.class_name_text()
	], "", SheetParts.colour_of(character).lightened(0.3))


## Put a line up, or freshen the one already up for the same thing.
func _say(key: String, text: String, owed: String, colour: Color) -> void:
	for row in _column.get_children():
		if str(row.get_meta("key", "")) == key:
			_column.remove_child(row)
			row.queue_free()
	while _column.get_child_count() >= MOST:
		var oldest := _column.get_child(0)
		_column.remove_child(oldest)
		oldest.queue_free()
	var row := _line(text, owed, colour)
	row.set_meta("key", key)
	row.set_meta("text", text if owed == "" else "%s · %s" % [text, owed])
	_column.add_child(row)
	var tween := row.create_tween().set_ignore_time_scale(true)
	row.modulate.a = 0.0
	tween.tween_property(row, "modulate:a", 1.0, 0.2)
	tween.tween_interval(SHOWN_FOR)
	tween.tween_property(row, "modulate:a", 0.0, FADE)
	tween.tween_callback(func() -> void:
		if is_instance_valid(row) and row.get_parent() == _column:
			_column.remove_child(row)
			row.queue_free()
	)


# --- how it looks -------------------------------------------------------------------


func _line(text: String, owed: String, colour: Color) -> Control:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _upright_touch():
		# Too narrow for the whole line: it wraps under itself instead.
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size = Vector2(WIDTH, 0)
	label.add_theme_font_size_override("normal_font_size", 15)
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	var said := "[right][color=#%s]✦ %s[/color]" % [colour.to_html(false), text]
	if owed != "":
		# "(P)" is a key; a phone says the touch bar's button ([D412]).
		said += "[color=#%s]  ·  %s[/color]" % [QUIET.to_html(false), Pad.say(owed)]
	label.text = said + "[/right]"
	return label


func _build() -> void:
	_column = VBoxContainer.new()
	_column.anchor_right = 1.0
	_column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_column.add_theme_constant_override("separation", 2)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	get_viewport().size_changed.connect(_fit)
	_fit()


## Held upright on a phone the top is full: the compass and its objective, the touch bar, the party
## card and the corner map. Kept clear of the touch column there the line ran over the compass and
## the objective's words ([D412]), so upright it comes a third of the way down instead, over the
## ground or the board and clear of the fight's touch column down the right.
func _fit() -> void:
	if _upright_touch():
		_column.anchor_left = 0.0
		_column.offset_left = 16.0
		_column.offset_right = -16.0 - TOUCH_CLEARANCE
		_column.offset_top = get_viewport().get_visible_rect().size.y * UPRIGHT_DOWN
	else:
		_column.offset_top = 56.0
		_column.anchor_left = 1.0
		_column.offset_right = -16.0 - (TOUCH_CLEARANCE if Pace.is_touch_enabled() else 0.0)
		_column.offset_left = _column.offset_right - WIDTH
