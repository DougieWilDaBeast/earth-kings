extends CanvasLayer
## The skirmish's readouts, built in code: the clock, a card per party member
## with their quick slots, the log, and the result.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishSlot := preload("res://src/skirmish/skirmish_slot.gd")
const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")
const SkirmishConditions := preload("res://src/skirmish/skirmish_conditions.gd")

signal card_clicked(index: int)
## The stance on a party card was clicked: that fighter takes up the next ([D195]).
signal stance_clicked(index: int)
## A skill tile on a party card was clicked: pick that fighter, ready that skill.
signal slot_clicked(index: int, slot: int)
## A touch button, named as [method Skirmish.act] takes it: "pause", "slot0"…
signal action_pressed(action: String)
## A draught or herb on a card: card index and item id (D59).
signal item_clicked(index: int, item_id: String)

const LOG_LINES := 6
## A fight on the ground (`in_place`) keeps one line of what is going on, and the keys are a press away.
const COMPACT_LOG_LINES := 1
const COMPACT_KEYS := "K: keys"
const HINT := "Right-click: move · attack · help the fallen    Left-click / drag: select    1–4 / Tab: pick    " \
		+ "Q W E R: skills    A: auto skills    O F B G H: own way · close in · keep away · guard · hold    Space: pause    T: speed    Z: auto-pause    N: journal"
const TOUCH_HINT := "Tap a fighter to pick them · tap ground, an enemy or a fallen friend to send them · " \
		+ "a skill, then its target, and the target again to cast · tap the skill again to put it away · the fight slows while you choose · hold a finger on anything to read it"
## The same, on a pad: the stick walks a cursor and A gives the order there.
const PAD_HINT := "Stick: cursor    %s: pick · move · attack · help the fallen    %s: next fighter    %s: everyone    " \
		+ "%s: next skill    %s: pause    %s: speed    %s: put a skill away"
## Down the right-hand side under a thumb, top to bottom: the keys, as buttons.
const TOUCH_BUTTONS := [
	["pause", "Pause"], ["speed", "Speed"], ["all", "All"],
	["slot0", "Q"], ["slot1", "W"], ["slot2", "E"], ["slot3", "R"],
	["auto_skill", "Auto skills"], ["hold", "Hold"], ["auto_pause", "Auto-pause"],
]
## What each of them does, read with a long press on a phone ([D388]); a skill's own is its tooltip.
const TOUCH_TIPS := {
	"pause": "Stop the fight, or start it again. Orders can be given while it is stopped.",
	"speed": "The fight's speed, round from 1x to 5x.",
	"all": "Pick the whole company, so one tap sends them all.",
	"auto_skill": "Whoever is picked uses their skills by themselves, or stops.",
	"hold": "Whoever is picked stands their ground, or goes their own way again.",
	"auto_pause": "When the fight stops by itself: never, when someone goes down, or also when a skill is ready.",
}
## One of those buttons, and the gap between two: 58 tall is about 44 points on a phone, where the
## game is 1.32 of its pixels to a point, the least a thumb hits reliably ([D387]).
const TOUCH_BUTTON := Vector2(128, 58)
## Narrower than this, a card puts its stance word under the name instead of beside it ([D415]).
const NARROW_CARD := 150.0
## What the mouse's own buttons do that the touch column has not got ([D391]).
const MOUSE_TIPS := {
	"auto": "Let the game fight for you, or take the party back.",
	"journal": "The journal: people, places, powers and what has been learned.",
	"keys": "How to Play, with every key.",
	"menu": "Save, sound, the keys and How to Play.",
}
const TOUCH_GAP := 4.0
## On a computer with the mouse ([D391]): the fight's keys as a column of buttons at the bottom right,
## each hover naming its key (a rebindable action's as rebound, else the bare key). The skills are the
## cards' own tiles, and a card's stance word steps through the stances, so neither is here.
const MOUSE_BUTTONS := [
	["auto", "Auto", "battle_auto"], ["pause", "Pause", "command_wait"], ["speed", "Speed", "battle_speed"], ["all", "All", "Tab"],
	["auto_skill", "Auto skills", "A"], ["hold", "Hold", "stance_hold"], ["auto_pause", "Auto-pause", "Z"],
	["journal", "Journal", "N"], ["keys", "Keys", "K"], ["menu", "Menu", "Esc"],
]
const MOUSE_BUTTON := Vector2(124, 30)
const READY := Color(0.62, 0.92, 0.62)
const WAITING := Color(0.62, 0.66, 0.74)
const PANEL := Color(0.08, 0.09, 0.12, 0.86)
const PANEL_SELECTED := Color(0.22, 0.19, 0.08, 0.92)
## The stance's word on a card.
const STANCE := Color(1.0, 0.86, 0.55)

## The skirmish scene. Untyped, because it loads this script itself.
var _skirmish: Node2D
var _clock: Label
## The drawn Paused banner and speed mark (A2, [D370]), when their pictures are in; null till then.
var _paused_banner: TextureRect = null
var _speed_mark: TextureRect = null
var _hint: Label
var _log: Label
var _result: Label
var _cards: Array[PanelContainer] = []
var _card_text: Array[RichTextLabel] = []
## Per card, its four skill tiles.
var _card_slots: Array = []
## Per card, item id → its button.
var _card_items: Array = []
## Per card, the button that says its stance and steps to the next.
var _card_stances: Array[Button] = []
## Per card, the name line beside the stance.
var _card_names: Array[RichTextLabel] = []
## The touch skill buttons' cooldown sweeps, by slot.
var _button_sweeps: Dictionary = {}
## Whoever the pointer is over: name, health, role and passives.
var _inspect: PanelContainer
## The card a turned fight asks on ([D272]): stand, pull back, break off.
var _turn: PanelContainer = null
## Its own layer, over the tip cards (layer 6), so a tip never sits on the question.
var _turn_layer: CanvasLayer = null
var _inspect_text: RichTextLabel
var _inspected: Fighter = null
var _lines: Array[String] = []
var _buttons: Dictionary = {}
## The mouse's buttons on a computer ([constant MOUSE_BUTTONS]), by action; empty on touch.
var _mouse_buttons: Dictionary = {}
var _mouse_column: VBoxContainer = null
## How many of the touch buttons were showing when the grid was last laid out.
var _shown_buttons: int = 0
## The touch buttons' grid down the right edge ([method _fit_touch_buttons]).
var _column: GridContainer = null
var _plain := _panel_style(PANEL)
var _picked := _panel_style(PANEL_SELECTED)
var _tight := StyleBoxEmpty.new()


func setup(skirmish: Node2D) -> void:
	_skirmish = skirmish

	_clock = Label.new()
	_clock.position = Vector2(16, 10)
	_clock.add_theme_font_size_override("font_size", 20)
	add_child(_clock)
	_put_drawn_marks()

	_hint = Label.new()
	_hint.position = Vector2(16, 38)
	_hint.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	_hint.add_theme_font_size_override("font_size", 13)
	add_child(_hint)
	_say_hint()
	Pad.changed.connect(_say_hint)
	# On the ground the screen is the ground's: no wall of keys, and the log is one line.
	var compact: bool = skirmish.in_place
	_hint.visible = not compact

	_log = Label.new()
	_log.anchor_top = 1.0
	_log.anchor_bottom = 1.0
	_log.offset_left = 16
	_log.offset_right = 760
	_log.offset_top = -262 if not compact else -160
	_log.offset_bottom = -138
	_log.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_log.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.add_theme_color_override("font_color", Color(0.86, 0.88, 0.92))
	_log.add_theme_font_size_override("font_size", 13)
	add_child(_log)

	var row := HBoxContainer.new()
	row.anchor_top = 1.0
	row.anchor_bottom = 1.0
	row.anchor_right = 1.0
	row.offset_left = 16
	row.offset_right = -16
	# Sized by the cards and grown up from the bottom edge, so a card taller than it was
	# planned for (a pouch, a second line of passives) pushes the row up instead of running
	# off the bottom of the screen ([D231], play-test 4: "not fitting in screen").
	row.offset_top = -8
	row.offset_bottom = -8
	row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	# The log keeps its place just above the cards, however tall they come out.
	var log_height := _log.offset_bottom - _log.offset_top
	row.resized.connect(func() -> void:
		_log.offset_bottom = -(row.size.y + 16.0)
		_log.offset_top = _log.offset_bottom - log_height)
	var party: Array[Fighter] = skirmish.party_fighters()
	# Four cards sit at full width; five or six share the row rather than run
	# off the right edge of a 1280 screen. Kept small, so the fight is the field and not the
	# cards ([D178], `doug-md`: "far too big… a lot smaller, a lot more slicker").
	var room := get_viewport().get_visible_rect().size.x - 32.0 - 10.0 * maxf(0.0, party.size() - 1)
	var card_width := minf(200.0, floorf(room / maxf(1.0, party.size())))
	for i in party.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, 118)
		card.clip_contents = true
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.tooltip_text = _passive_tooltip(party[i])
		var index := i
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				card_clicked.emit(index))
		var column := VBoxContainer.new()
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		column.add_theme_constant_override("separation", 4)
		card.add_child(column)
		# The name, and beside it the stance as a word ([D195]): a click (a tap) steps
		# to the next one. Up there it costs the card no height and is never clipped.
		# On a card too narrow for both (four across a phone held upright) the stance goes under
		# the name, or the name broke mid-word: "Bellon", "a" ([D415]).
		var head: BoxContainer = HBoxContainer.new() if card_width >= NARROW_CARD else VBoxContainer.new()
		head.add_theme_constant_override("separation", 4 if card_width >= NARROW_CARD else 0)
		column.add_child(head)
		var name_text := _card_label()
		name_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_text)
		var stance := Button.new()
		stance.focus_mode = Control.FOCUS_NONE
		stance.flat = true
		stance.add_theme_font_size_override("font_size", 12 if not skirmish.touch else 13)
		if card_width < NARROW_CARD:
			stance.alignment = HORIZONTAL_ALIGNMENT_LEFT
			stance.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		# No taller than the name, so the card keeps its height and its draughts stay in view.
		for look: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			stance.add_theme_stylebox_override(look, _tight)
		stance.add_theme_color_override("font_color", STANCE)
		stance.add_theme_color_override("font_hover_color", STANCE.lightened(0.3))
		stance.pressed.connect(func() -> void: stance_clicked.emit(index))
		head.add_child(stance)
		_card_stances.append(stance)
		_card_names.append(name_text)
		var text := _card_label()
		column.add_child(text)
		var tiles := HBoxContainer.new()
		tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tiles.add_theme_constant_override("separation", 4)
		column.add_child(tiles)
		var slots: Array = []
		# The tiles narrow with the card, or four of them would hold it at full width.
		var tile_count := maxi(1, party[i].slots.size())
		var tile_width := minf(44.0, floorf((card_width - 16.0 - 4.0 * (tile_count - 1)) / tile_count))
		for slot in party[i].slots.size():
			var tile: Control = SkirmishSlot.new()
			tile.set("width", tile_width)
			tile.tooltip_text = _ability_tooltip(party[i].slot_ability(slot))
			var which := slot
			tile.pressed.connect(func() -> void: slot_clicked.emit(index, which))
			tiles.add_child(tile)
			slots.append(tile)
		var items := HBoxContainer.new()
		items.add_theme_constant_override("separation", 3)
		column.add_child(items)
		var item_buttons := {}
		for item_id: String in skirmish.pouch_items():
			var button := Button.new()
			button.focus_mode = Control.FOCUS_NONE
			button.add_theme_font_size_override("font_size", 11)
			button.custom_minimum_size = Vector2(0, 24 if not skirmish.touch else 34)
			# Shares the card's width with the others rather than holding it wider than the
			# card: the game's frame is forty pixels either side of the word.
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.clip_text = true
			button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
				var frame := button.get_theme_stylebox(state)
				if frame == null:
					continue
				frame = frame.duplicate()
				frame.content_margin_left = 4
				frame.content_margin_right = 4
				frame.content_margin_top = 2
				frame.content_margin_bottom = 2
				button.add_theme_stylebox_override(state, frame)
			button.tooltip_text = "%s — mends %d. Takes %.1fs; they can be hit but not stunned." % [
				Gear.display_name(item_id),
				roundi(float(Gear.mends(item_id)) * SkirmishRules.HEALTH_SCALE),
				SkirmishPassives.rule("use_item_time", 1.5)]
			var id := item_id
			button.pressed.connect(func() -> void: item_clicked.emit(index, id))
			items.add_child(button)
			item_buttons[item_id] = button
		_cards.append(card)
		_card_text.append(text)
		_card_slots.append(slots)
		_card_items.append(item_buttons)
		row.add_child(card)

	_inspect = PanelContainer.new()
	_inspect.anchor_left = 1.0
	_inspect.anchor_right = 1.0
	_inspect.offset_left = -330 if not skirmish.touch else -490
	_inspect.offset_right = -16 if not skirmish.touch else -170
	_inspect.offset_top = 64
	_inspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect.add_theme_stylebox_override("panel", _panel_style(PANEL))
	_inspect_text = RichTextLabel.new()
	_inspect_text.bbcode_enabled = true
	_inspect_text.fit_content = true
	_inspect_text.scroll_active = false
	_inspect_text.custom_minimum_size = Vector2(300, 0)
	_inspect_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_inspect_text.add_theme_font_size_override("normal_font_size", 13)
	_inspect_text.add_theme_font_size_override("bold_font_size", 15)
	_inspect.add_child(_inspect_text)
	_inspect.visible = false
	add_child(_inspect)

	if skirmish.touch:
		_add_touch_buttons()
	else:
		_add_mouse_buttons()

	_result = Label.new()
	_result.anchor_left = 0.5
	_result.anchor_right = 0.5
	_result.anchor_top = 0.4
	_result.anchor_bottom = 0.4
	_result.offset_left = -300
	_result.offset_right = 300
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.add_theme_font_size_override("font_size", 56)
	_result.visible = false
	add_child(_result)
	refresh()


func _say_hint() -> void:
	if _skirmish.touch:
		_hint.text = TOUCH_HINT
	elif Pad.using_pad:
		_hint.text = PAD_HINT % [
			Pad.key("ui_accept"), Pad.key("cycle_next"), Pad.key("open_party"),
			Pad.key("open_actions"), Pad.key("command_wait"), Pad.key("battle_speed"),
			Pad.key("ui_cancel"),
		]
	else:
		_hint.text = HINT


## Big enough for a thumb, down the right edge, clear of the party cards and
## of the touch bar's Book and Menu along the top.
func _add_touch_buttons() -> void:
	var column := GridContainer.new()
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.offset_right = -12
	column.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	column.add_theme_constant_override("h_separation", 4)
	column.add_theme_constant_override("v_separation", 4)
	add_child(column)
	_column = column
	get_viewport().size_changed.connect(_fit_touch_buttons)
	for entry: Array in TOUCH_BUTTONS:
		var button := Button.new()
		button.custom_minimum_size = TOUCH_BUTTON
		button.text = entry[1]
		button.tooltip_text = str(TOUCH_TIPS.get(entry[0], ""))
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		var action: String = entry[0]
		button.pressed.connect(func() -> void: action_pressed.emit(action))
		column.add_child(button)
		# The game's buttons leave forty pixels of frame either side of the
		# word, which on a column this narrow cut "W Shield Bash" to "W Shield Bas".
		for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
			var frame := button.get_theme_stylebox(state)
			if frame == null:
				continue
			frame = frame.duplicate()
			frame.content_margin_left = 10
			frame.content_margin_right = 10
			button.add_theme_stylebox_override(state, frame)
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		if action == "speed":
			button.icon = SkirmishSlot.picture("speed_indicator")
			button.expand_icon = true
		_buttons[action] = button
		if action.begins_with("slot"):
			var sweep: Control = SkirmishSlot.new()
			sweep.overlay_only = true
			sweep.set_anchors_preset(Control.PRESET_FULL_RECT)
			button.add_child(sweep)
			_button_sweeps[action] = sweep
	_fit_touch_buttons()


## The fight's keys as buttons for the mouse ([D391]), stacked up from the bottom-right corner, clear
## of the party cards along the bottom left and the hover card along the top right. A pad in hand
## puts them away, as it puts the hint's keys away.
func _add_mouse_buttons() -> void:
	_mouse_column = VBoxContainer.new()
	_mouse_column.anchor_left = 1.0
	_mouse_column.anchor_right = 1.0
	_mouse_column.anchor_top = 1.0
	_mouse_column.anchor_bottom = 1.0
	_mouse_column.offset_left = -MOUSE_BUTTON.x - 14
	_mouse_column.offset_right = -14
	_mouse_column.offset_bottom = -14
	_mouse_column.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_mouse_column.add_theme_constant_override("separation", 4)
	_mouse_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_mouse_column)
	for entry: Array in MOUSE_BUTTONS:
		var action: String = entry[0]
		if action == "keys" and not _skirmish.in_place:
			# A fight with a screen of its own has the keys written along its top.
			continue
		var button := Button.new()
		button.custom_minimum_size = MOUSE_BUTTON
		button.text = entry[1]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(func() -> void: action_pressed.emit(action))
		Sfx.attend(button)
		_mouse_column.add_child(button)
		_mouse_buttons[action] = button
	Pad.changed.connect(_refresh_mouse_buttons)


## The mouse's button for [param action] ("pause", "speed" …), for the suites; null if there is none.
func mouse_button(action: String) -> Button:
	return _mouse_buttons.get(action, null)


func _refresh_mouse_buttons() -> void:
	if _mouse_column == null:
		return
	_mouse_column.visible = not Pad.using_pad and not _skirmish.over
	for entry: Array in MOUSE_BUTTONS:
		var button: Button = _mouse_buttons.get(entry[0], null)
		if button == null:
			continue
		var key := str(entry[2])
		if InputMap.has_action(key):
			key = Pad.key_text(key)
		var what := str(TOUCH_TIPS.get(entry[0], MOUSE_TIPS.get(entry[0], "")))
		button.tooltip_text = "%s (%s)" % [what, key] if key != "" else what
	(_mouse_buttons["auto"] as Button).text = "Auto: %s" % Pace.auto_style_name() if Pace.auto else "Auto"
	(_mouse_buttons["pause"] as Button).text = "Resume" if _skirmish.paused else "Pause"
	(_mouse_buttons["speed"] as Button).text = "Speed x%s" % String.num(Pace.speed(), 1).trim_suffix(".0")


## The buttons go down the right edge, and into a second or third column when the screen is too
## short for one. A phone on its side is 540 tall, and itch.io's full-screen button turns it so:
## one column ran down under the stick's Act, Back and Next, and Hold and Auto-pause were lost
## (D240). Laid out again whenever the screen changes shape, since turning the phone mid-fight
## turns the screen too.
func _fit_touch_buttons() -> void:
	if _column == null:
		return
	var view := get_viewport().get_visible_rect().size
	var top := 92.0
	var bottom := TouchControls.EDGE_PAD
	# Held upright the touch bar sits lower, under the scene's top lines (D163).
	if view.y > view.x:
		top += TouchControls.UPRIGHT_DROP
	# Fought on the ground, the walking pad's Act, Back and Next stay up in the bottom corner.
	if _skirmish.in_place:
		bottom += TouchControls.CLUSTER_HEIGHT + TouchControls.EDGE_PAD
		if view.y > view.x:
			bottom += TouchControls.UPRIGHT_LIFT
	var rows := maxi(1, floori((view.y - top - bottom + TOUCH_GAP) / (TOUCH_BUTTON.y + TOUCH_GAP)))
	var shown := _column.get_children().filter(func(b: Control) -> bool: return b.visible).size()
	_shown_buttons = shown
	var columns := maxi(1, ceili(float(shown) / rows))
	_column.columns = columns
	_column.offset_top = top
	_column.offset_left = -12 - columns * TOUCH_BUTTON.x - (columns - 1) * TOUCH_GAP


func refresh() -> void:
	if _skirmish == null:
		return
	_refresh_buttons()
	_refresh_mouse_buttons()
	var resume := "tap Pause" if _skirmish.touch else "Space"
	if Pad.using_pad and not _skirmish.touch:
		resume = Pad.key("command_wait")
	var state := "PAUSED — %s to resume" % resume if _skirmish.paused else "x%s" % String.num(Pace.speed(), 1).trim_suffix(".0")
	if _skirmish.over:
		state = "Over"
	if _paused_banner != null:
		_paused_banner.visible = _skirmish.paused and not _skirmish.over
	if _speed_mark != null:
		_speed_mark.visible = not _skirmish.paused and not _skirmish.over
	var armed := ""
	if _skirmish.armed_slot >= 0 and not _skirmish.selected.is_empty():
		var caster: Fighter = _skirmish.selected[0]
		var ability := caster.slot_ability(_skirmish.armed_slot)
		var how := "tap a target, then it again to cast, or the skill again to cancel" if _skirmish.touch \
				else "left-click a target, right-click to cancel"
		if Pad.using_pad and not _skirmish.touch:
			how = "%s at the target, %s to cancel" % [Pad.key("ui_accept"), Pad.key("ui_cancel")]
		armed = "    Aiming %s — %s" % [ability.get("display_name", "?"), how]
	var keys := "   %s" % COMPACT_KEYS if _skirmish.in_place and not _skirmish.touch and not Pad.using_pad else ""
	_clock.text = "%s   %s   %.1fs%s%s" % [_skirmish.title, state, _skirmish.sim_time, armed, keys]

	var party: Array[Fighter] = _skirmish.party_fighters()
	for i in mini(party.size(), _cards.size()):
		var lines := _describe(party[i], i).split("\n")
		_card_names[i].text = lines[0]
		_card_text[i].text = "\n".join(lines.slice(1))
		_cards[i].add_theme_stylebox_override(
			"panel", _picked if _skirmish.selected.has(party[i]) else _plain
		)
		var lead_armed: bool = not _skirmish.selected.is_empty() and _skirmish.selected[0] == party[i]
		var tiles: Array = _card_slots[i]
		for slot in tiles.size():
			var ability := party[i].slot_ability(slot)
			(tiles[slot] as Control).call("show_slot",
				str(SkirmishRules.SLOT_LABELS[slot]), str(ability.get("display_name", "?")),
				party[i].cooldowns[slot], SkirmishRules.cooldown(ability),
				lead_armed and _skirmish.armed_slot == slot)
		_show_stance(_card_stances[i], party[i])
		var item_buttons: Dictionary = _card_items[i]
		for item_id: String in item_buttons:
			var button: Button = item_buttons[item_id]
			var left := int(_skirmish.pouch.get(item_id, 0))
			button.text = "%s ×%d" % [Gear.display_name(item_id).replace("Bitter ", ""), left]
			button.disabled = _skirmish.item_refusal(party[i], item_id) != ""
	if _inspected != null:
		_inspect_text.text = _inspection(_inspected)


## The fight screen's drawn Paused banner, across the top in the middle, and its speed mark before
## the clock (art request A2, [D370]): each only once its picture is in. Until then "PAUSED" and
## "x1" in the clock's line say it, as they still do beside the pictures.
func _put_drawn_marks() -> void:
	var banner := SkirmishSlot.picture("paused_banner")
	if banner != null:
		_paused_banner = TextureRect.new()
		_paused_banner.texture = banner
		_paused_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_paused_banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_paused_banner.anchor_left = 0.5
		_paused_banner.anchor_right = 0.5
		_paused_banner.offset_left = -banner.get_width() / 2.0
		_paused_banner.offset_right = banner.get_width() / 2.0
		_paused_banner.offset_top = 64
		_paused_banner.offset_bottom = 64 + banner.get_height()
		_paused_banner.visible = false
		add_child(_paused_banner)
	var mark := SkirmishSlot.picture("speed_indicator")
	if mark != null:
		_speed_mark = TextureRect.new()
		_speed_mark.texture = mark
		_speed_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_speed_mark.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_speed_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_speed_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_speed_mark.position = Vector2(14, 12)
		_speed_mark.size = Vector2(24, 24)
		add_child(_speed_mark)
		_clock.position.x += 28


## Show who the pointer is over, or nobody.
func inspect(f: Fighter) -> void:
	_inspected = f
	if _inspect == null:
		return
	_inspect.visible = f != null
	if f != null:
		_inspect_text.text = _inspection(f)


func _inspection(f: Fighter) -> String:
	var unit := f.unit
	var lines: Array[String] = []
	var side := "[color=#8fd18f]yours[/color]" if f.is_party() else "[color=#ff8a7a]enemy[/color]"
	lines.append("[b]%s[/b]  %s  [color=#9aa3b2]%s[/color]" % [unit.display_name, side, unit.job])
	lines.append("%d / %d HP   attack %d   defence %d   %s" % [
		maxi(0, unit.hp), unit.max_hp, unit.attack, unit.defense, f.activity()])
	lines.append("energy %s%s" % [energy_bar(f), "   [color=#9ad0ff]shield[/color]" if f.shield else ""])
	var role := f.role_data()
	if not role.is_empty():
		lines.append("[color=#ffd27a]%s[/color] — %s" % [role.get("display_name", f.role), role.get("description", "")])
	if f.passives.is_empty() and f.signature.is_empty():
		lines.append("[color=#7d8594]no passives[/color]")
	for p: Dictionary in f.passives:
		lines.append("[color=#c8b6ff]✦ %s[/color] — %s" % [p.get("display_name", p.get("id", "?")), p.get("description", "")])
	if not f.signature.is_empty():
		lines.append("[color=#ffd27a]★ %s[/color] — %s" % [f.signature.get("display_name", "?"), f.signature.get("description", "")])
	return "\n".join(lines)


## Ten pips of energy, gold when it can pay for skills and grey when tired.
static func energy_bar(f: Fighter) -> String:
	var share := clampf(f.energy / maxf(1.0, f.energy_max), 0.0, 1.0)
	var full := roundi(share * 10.0)
	var colour := "#7d8594" if f.tired else "#ffd27a"
	return "[color=%s]%s[/color][color=#3a3f4a]%s[/color]" % [colour, "▮".repeat(full), "▮".repeat(10 - full)]


static func _passive_tooltip(f: Fighter) -> String:
	if f.passives.is_empty() and f.signature.is_empty():
		return "No passives."
	var lines: Array[String] = []
	for p: Dictionary in f.passives:
		lines.append("%s — %s" % [p.get("display_name", "?"), p.get("description", "")])
	if not f.signature.is_empty():
		lines.append("★ %s — %s" % [f.signature.get("display_name", "?"), f.signature.get("description", "")])
	return "\n".join(lines)


static func _ability_tooltip(ability: Dictionary) -> String:
	var extras := ""
	if SkirmishRules.is_charged(ability):
		extras += "\nCharged: hits harder, but a stun breaks it off"
	if float(ability.get("stun", 0.0)) > 0.0:
		extras += "\nStuns for %.1fs and breaks a cast" % float(ability["stun"])
	for tip: String in SkirmishConditions.tips(ability):
		extras += "\n" + tip
	return "%s\n%s\nCooldown %.1fs%s   energy %d%s" % [
		ability.get("display_name", "?"), ability.get("description", ""),
		SkirmishRules.cooldown(ability),
		"   wind-up %.1fs" % SkirmishRules.cast_time(ability) if SkirmishRules.cast_time(ability) > 0.0 else "",
		roundi(SkirmishRules.energy_cost(ability)), extras,
	]


func _describe(f: Fighter, index: int) -> String:
	var unit := f.unit
	var lines: Array[String] = []
	var flags: Array[String] = []
	if f.auto_skill:
		flags.append("auto")
	lines.append("[b]%d  %s[/b]  [color=#9aa3b2]%s[/color]" % [index + 1, unit.display_name, " · ".join(flags)])
	lines.append("%d / %d HP   %s   [color=#c9d1dd]%s[/color]" % [maxi(0, unit.hp), unit.max_hp, energy_bar(f), f.activity()])
	if f.is_downed():
		# What the graces would make of it if nobody gets there in time.
		lines.append("[color=#ffe08a]if nobody comes: %d%% a grace saves them[/color]" % roundi(100.0 * _skirmish.grace_odds(f)))
	elif not f.passives.is_empty():
		var names: Array = f.passives.map(func(p: Dictionary) -> String: return str(p.get("display_name", "?")))
		lines.append("[color=#c8b6ff]✦ %s[/color]" % " · ".join(names))
	if f.slots.is_empty():
		lines.append("[color=#7d8594]no skills yet — basic attacks only[/color]")
	return "\n".join(lines)


static func _card_label() -> RichTextLabel:
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.fit_content = true
	text.scroll_active = false
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_size_override("normal_font_size", 12)
	text.add_theme_font_size_override("bold_font_size", 13)
	return text


## The stance a fighter fights in, as its word; while the game plays itself every
## fighter goes its own way, and the button waits until the player has them back.
static func _show_stance(button: Button, f: Fighter) -> void:
	var word := str(Fighter.stance_data(f.playing_stance()).get("word", "Own way"))
	button.text = word
	button.disabled = Pace.auto
	var keys := ""
	var action := str(Fighter.stance_data(f.stance).get("action", ""))
	if InputMap.has_action(action):
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
				keys = " (%s)" % OS.get_keycode_string(code)
				break
	button.tooltip_text = "Stance: %s%s. %s\nClick for the next stance." % [
		word, keys, Fighter.stance_data(f.playing_stance()).get("tip", "")]


## The skill buttons say what the first picked fighter would use, and are
## greyed out where they have nothing, so a thumb is never guessing.
func _refresh_buttons() -> void:
	if _buttons.is_empty():
		return
	(_buttons["pause"] as Button).text = "Resume" if _skirmish.paused else "Pause"
	(_buttons["speed"] as Button).text = "Speed x%s" % String.num(Pace.speed(), 1).trim_suffix(".0")
	# On the ground the touch bar's own speed button is up, and it is the same speed (D387).
	(_buttons["speed"] as Button).visible = not _skirmish.in_place
	var caster: Fighter = _skirmish.selected[0] if not _skirmish.selected.is_empty() else null
	for slot in SkirmishRules.SLOT_LABELS.size():
		var button: Button = _buttons.get("slot%d" % slot)
		if button == null:
			continue
		var has := caster != null and slot < caster.slots.size()
		button.disabled = not has
		# A skill the picked fighter has not got is left out, not greyed, so the rest can be big.
		button.visible = has
		# A thumb has no Q, W, E or R: the button is the skill's name ([D387]).
		var label := "Skill %d" % (slot + 1)
		if has:
			# Whole: the button trims it with an ellipsis only if it cannot fit.
			label = str(caster.slot_ability(slot).get("display_name", "?"))
			# Read with a long press on a phone ([D388]).
			button.tooltip_text = _ability_tooltip(caster.slot_ability(slot))
			if _skirmish.armed_slot == slot:
				label = "» " + label
		button.text = label
		var sweep: Control = _button_sweeps.get("slot%d" % slot)
		if sweep != null:
			var wait := caster.cooldowns[slot] if has else 0.0
			var total := SkirmishRules.cooldown(caster.slot_ability(slot)) if has else 1.0
			sweep.call("show_slot", "", "", wait, total, false)
	if _column != null and _column.get_children().filter(func(b: Control) -> bool: return b.visible).size() != _shown_buttons:
		_fit_touch_buttons()


static func _panel_style(colour: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	return style


func log_line(line: String) -> void:
	_lines.append(line)
	var most := COMPACT_LOG_LINES if _skirmish != null and _skirmish.in_place else LOG_LINES
	while _lines.size() > most:
		_lines.pop_front()
	if _log != null:
		_log.text = "\n".join(_lines)


func show_result(won: bool, fled := false) -> void:
	_result.text = "Victory" if won else ("Clear" if fled else "Defeat")
	_result.add_theme_color_override("font_color",
			Color(1.0, 0.86, 0.4) if won else (Color(0.8, 0.85, 0.95) if fled else Color(1.0, 0.45, 0.4)))
	_result.visible = true
	refresh()


## The fight has turned ([D272]): a card in the middle of the screen with [param choices]
## ({id, label, tip}), a button each, numbered for the keys 1 to 3. A press says the choice back
## to the fight as `turn_<id>`.
func show_turn(title: String, text: String, choices: Array) -> void:
	hide_turn()
	_turn_layer = CanvasLayer.new()
	_turn_layer.layer = 7
	add_child(_turn_layer)
	_turn = PanelContainer.new()
	_turn.anchor_left = 0.5
	_turn.anchor_right = 0.5
	_turn.anchor_top = 0.12
	_turn.anchor_bottom = 0.12
	_turn.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_turn.mouse_filter = Control.MOUSE_FILTER_STOP
	var frame := _panel_style(Color(PANEL, 0.97))
	frame.border_color = STANCE
	frame.set_border_width_all(2)
	frame.content_margin_left = 16
	frame.content_margin_right = 16
	frame.content_margin_top = 12
	frame.content_margin_bottom = 12
	_turn.add_theme_stylebox_override("panel", frame)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_turn.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", STANCE)
	column.add_child(heading)
	var words := Label.new()
	words.text = text
	words.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var width := minf(420.0, get_viewport().get_visible_rect().size.x - 64.0)
	words.custom_minimum_size = Vector2(width, 0)
	words.add_theme_font_size_override("font_size", 15)
	column.add_child(words)
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%d  %s" % [i + 1, str(choice.get("label", ""))] if not _skirmish.touch \
				else str(choice.get("label", ""))
		button.tooltip_text = str(choice.get("tip", ""))
		button.custom_minimum_size = Vector2(0, 34 if not _skirmish.touch else 48)
		var id := str(choice.get("id", ""))
		button.pressed.connect(func() -> void: action_pressed.emit("turn_" + id))
		column.add_child(button)
		var tip := Label.new()
		tip.text = str(choice.get("tip", ""))
		tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tip.custom_minimum_size = Vector2(width, 0)
		tip.add_theme_font_size_override("font_size", 12)
		tip.add_theme_color_override("font_color", WAITING)
		column.add_child(tip)
	_turn_layer.add_child(_turn)
	_fit_turn.call_deferred()


## Wrapped words are measured narrow first, which leaves the card too tall; once laid out at its
## width it is shrunk back to them, and centred.
func _fit_turn() -> void:
	if _turn == null:
		return
	_turn.offset_top = 0.0
	_turn.offset_bottom = 0.0
	_turn.reset_size()
	var size := _turn.get_combined_minimum_size()
	_turn.offset_left = -size.x / 2.0
	_turn.offset_right = size.x / 2.0
	_turn.offset_bottom = size.y


func hide_turn() -> void:
	if _turn_layer != null:
		_turn_layer.queue_free()
		_turn_layer = null
	_turn = null


## Whether the turned fight's card is up.
func turn_showing() -> bool:
	return _turn != null
