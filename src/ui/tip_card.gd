extends CanvasLayer
## The first-time tip card. Always present under [Game], like the dialogue box.
##
## Listens for moments on [EventBus] — [signal EventBus.tip_moment] and a few
## signals that already say the same thing (a fight starting, someone
## falling) — and shows the one tip owed for each, once per
## player ([code]src/ui/tips.gd[/code]).
##
## It never takes the game's input: it is not a modal overlay, its buttons take
## no keyboard focus, and it goes away by itself. While the game is playing
## itself nothing is shown and nothing is spent, so the tip is still owed when
## the player takes the controls back.

const Tips := preload("res://src/ui/tips.gd")

const WIDTH := 460.0
## Clear of the top bar in the walk scene and the clock and hint in a fight.
const TOP := 104.0
## How long a card stays up once another is waiting behind it.
const QUEUED_SECONDS := 5.0

var _panel: PanelContainer
var _title: Label
var _text: Label
var _queue: Array[Dictionary] = []
var _showing: Dictionary = {}
var _left: float = 0.0


func _ready() -> void:
	layer = 6
	_build()
	EventBus.tip_moment.connect(_on_moment)
	EventBus.scene_changed.connect(_on_scene_changed)
	EventBus.battle_started.connect(func(_map_id: String) -> void: _offer("encounter"))
	EventBus.character_fell.connect(
		func(_character: RefCounted, _outcome: Dictionary) -> void: _offer("downed")
	)
	EventBus.class_choice_required.connect(func(_character: RefCounted) -> void: _offer("level_two"))
	EventBus.guild_requested.connect(func() -> void: _offer("guild"))
	Pace.changed.connect(_on_pace_changed)


func is_showing() -> bool:
	return _panel.visible


## The id of the tip on the card, or "" with none up.
func showing_id() -> String:
	return str(_showing.get("id", "")) if _panel.visible else ""


func dismiss() -> void:
	_showing = {}
	_panel.hide()
	_next()


func _process(delta: float) -> void:
	# A fight runs from the moment it is met ([D300]): a card waits until it is over, and one up
	# when it starts goes back in the queue, rather than a box over the fight.
	if _fight_on():
		if _panel.visible:
			_queue.push_front(_showing)
			_showing = {}
			_panel.hide()
		return
	# One message at a time: a card waits for the box in front of it to close.
	if not _panel.visible and not _queue.is_empty() and not _something_is_open():
		_next()
	if not _panel.visible or _something_is_open():
		return
	# Read in the player's seconds, not the game's: at ×4 a card would be gone
	# before it was read.
	_left -= delta / maxf(Engine.time_scale, 0.01)
	if _left <= 0.0:
		dismiss()


# --- what is a moment ----------------------------------------------------------


func _on_scene_changed(scene_key: String) -> void:
	if scene_key == "world":
		_offer("map")
	elif scene_key == "title":
		# A tip about the run just left is no use on the title screen.
		_queue.clear()
		if _panel.visible:
			dismiss()


func _on_moment(kind: String, context: Dictionary) -> void:
	_offer(kind)
	if kind != "step":
		return
	if float(context.get("danger", 0.0)) >= float(Tips.rule("danger_above", 0.2)):
		_offer("danger")
	if bool(context.get("season_turned", false)):
		_offer("season")
	if int(context.get("steps", 0)) >= int(Tips.rule("autoplay_after_steps", 30)):
		_offer("autoplay")


func _on_pace_changed() -> void:
	# Handing the run over is not the moment to be reading a card.
	if Pace.auto:
		_queue.clear()
		if _panel.visible:
			_showing = {}
			_panel.hide()


func _offer(moment: String) -> void:
	# The tutorial teaches the same things itself; a tip spent there would never be seen in a run.
	if Pace.auto or GameState.rehearsing:
		return
	var tip := Tips.due(moment)
	if tip.is_empty():
		return
	var id := str(tip.get("id", ""))
	if id == str(_showing.get("id", "")):
		return
	for queued: Dictionary in _queue:
		if str(queued.get("id", "")) == id:
			return
	# Spent when it is offered, not when it is read: the same moment comes
	# round every step, and a queue of one tip twelve times is no help.
	Tips.mark_seen(id)
	_queue.append(tip)
	if not _panel.visible and not _something_is_open():
		_next()
	else:
		# Something newer is waiting; the card up now gets a few seconds more.
		_left = minf(_left, QUEUED_SECONDS)


func _next() -> void:
	if _queue.is_empty():
		return
	_showing = _queue.pop_front()
	_title.text = str(_showing.get("title", "Tip"))
	_text.text = str(_showing.get("text", ""))
	_left = float(Tips.rule("seconds_shown", 14))
	# Below the touch bar, which held upright drops lower still ([D376]).
	_panel.offset_top = TOP + _touch_drop()
	_panel.show()
	_panel.modulate.a = 0.0
	create_tween().tween_property(_panel, "modulate:a", 1.0, 0.25)


func _fight_on() -> bool:
	for fight in get_tree().get_nodes_in_group(EventBus.FIGHT_GROUP):
		if not bool(fight.get("over")):
			return true
	return false


func _something_is_open() -> bool:
	for overlay in get_tree().get_nodes_in_group(EventBus.MODAL_OVERLAY_GROUP):
		if overlay.has_method("is_open") and overlay.is_open():
			return true
	return false


func _turn_tips_off() -> void:
	Tips.set_enabled(false)
	_queue.clear()
	dismiss()


# --- the card ------------------------------------------------------------------


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.name = "Card"
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -WIDTH / 2.0
	_panel.offset_right = WIDTH / 2.0
	_panel.offset_top = TOP
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.07, 0.065, 0.09, 0.92)
	frame.border_color = Color(0.72, 0.55, 0.28, 0.9)
	frame.set_border_width_all(1)
	frame.border_width_left = 4
	frame.set_corner_radius_all(4)
	frame.content_margin_left = 16
	frame.content_margin_right = 12
	frame.content_margin_top = 10
	frame.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", frame)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 16)
	_title.add_theme_color_override("font_color", Color(0.98, 0.86, 0.52))
	column.add_child(_title)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - 32.0, 0)
	_text.add_theme_font_size_override("font_size", 14)
	_text.add_theme_color_override("font_color", Color(0.88, 0.86, 0.8))
	column.add_child(_text)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	row.add_child(_small_button("No more tips", _turn_tips_off))
	row.add_child(_small_button("Got it", dismiss))
	_panel.hide()


## How far the touch bar pushes the card down: none without it.
func _touch_drop() -> float:
	if not Pace.is_touch_enabled():
		return 0.0
	var view := _panel.get_viewport_rect().size
	return TouchControls.BAR_DROP + (TouchControls.UPRIGHT_DROP if view.y > view.x else 0.0)


func _small_button(text: String, call: Callable) -> Button:
	var button := Button.new()
	button.text = text
	# A card that took focus would take Enter and Space from the game under it.
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(call)
	Sfx.attend(button)
	return button
