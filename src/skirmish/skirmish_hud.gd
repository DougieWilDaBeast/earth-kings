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

signal card_clicked(index: int)
## A skill tile on a party card was clicked: pick that fighter, ready that skill.
signal slot_clicked(index: int, slot: int)
## A touch button, named as [method Skirmish.act] takes it: "pause", "slot0"…
signal action_pressed(action: String)
## A draught or herb on a card: card index and item id (D59).
signal item_clicked(index: int, item_id: String)

const LOG_LINES := 6
const HINT := "Right-click: move · attack · help the fallen    Left-click / drag: select    1–4 / Tab: pick    " \
		+ "Q W E R: skills    A: auto skills    H: hold    Space: pause    T: speed    Z: auto-pause    N: journal"
const TOUCH_HINT := "Tap a fighter to pick them · tap ground, an enemy or a fallen friend to send them · " \
		+ "a skill, then its target · tap the skill again to put it away"
## The same, on a pad: the stick walks a cursor and A gives the order there.
const PAD_HINT := "Stick: cursor    %s: pick · move · attack · help the fallen    %s: next fighter    %s: everyone    " \
		+ "%s: next skill    %s: pause    %s: speed    %s: put a skill away"
## Down the right-hand side under a thumb, top to bottom: the keys, as buttons.
const TOUCH_BUTTONS := [
	["pause", "Pause"], ["speed", "Speed"], ["all", "All"],
	["slot0", "Q"], ["slot1", "W"], ["slot2", "E"], ["slot3", "R"],
	["auto_skill", "Auto skills"], ["hold", "Hold"], ["auto_pause", "Auto-pause"],
]
const READY := Color(0.62, 0.92, 0.62)
const WAITING := Color(0.62, 0.66, 0.74)
const PANEL := Color(0.08, 0.09, 0.12, 0.86)
const PANEL_SELECTED := Color(0.22, 0.19, 0.08, 0.92)

## The skirmish scene. Untyped, because it loads this script itself.
var _skirmish: Node2D
var _clock: Label
var _hint: Label
var _log: Label
var _result: Label
var _cards: Array[PanelContainer] = []
var _card_text: Array[RichTextLabel] = []
## Per card, its four skill tiles.
var _card_slots: Array = []
## Per card, item id → its button.
var _card_items: Array = []
## The touch skill buttons' cooldown sweeps, by slot.
var _button_sweeps: Dictionary = {}
## Whoever the pointer is over: name, health, role and passives.
var _inspect: PanelContainer
var _inspect_text: RichTextLabel
var _inspected: Fighter = null
var _lines: Array[String] = []
var _buttons: Dictionary = {}
var _plain := _panel_style(PANEL)
var _picked := _panel_style(PANEL_SELECTED)


func setup(skirmish: Node2D) -> void:
	_skirmish = skirmish

	_clock = Label.new()
	_clock.position = Vector2(16, 10)
	_clock.add_theme_font_size_override("font_size", 20)
	add_child(_clock)

	_hint = Label.new()
	_hint.position = Vector2(16, 38)
	_hint.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	_hint.add_theme_font_size_override("font_size", 13)
	add_child(_hint)
	_say_hint()
	Pad.changed.connect(_say_hint)

	_log = Label.new()
	_log.anchor_top = 1.0
	_log.anchor_bottom = 1.0
	_log.offset_left = 16
	_log.offset_right = 760
	_log.offset_top = -312
	_log.offset_bottom = -188
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
	row.offset_top = -180
	row.offset_bottom = -8
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var party: Array[Fighter] = skirmish.party_fighters()
	# Four cards sit at full width; five or six share the row rather than run
	# off the right edge of a 1280 screen.
	var room := get_viewport().get_visible_rect().size.x - 32.0 - 10.0 * maxf(0.0, party.size() - 1)
	var card_width := minf(250.0, floorf(room / maxf(1.0, party.size())))
	for i in party.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(card_width, 166)
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
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_font_size_override("normal_font_size", 13)
		text.add_theme_font_size_override("bold_font_size", 14)
		column.add_child(text)
		var tiles := HBoxContainer.new()
		tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tiles.add_theme_constant_override("separation", 4)
		column.add_child(tiles)
		var slots: Array = []
		# The tiles narrow with the card, or four of them would hold it at full width.
		var tile_count := maxi(1, party[i].slots.size())
		var tile_width := minf(56.0, floorf((card_width - 16.0 - 4.0 * (tile_count - 1)) / tile_count))
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
	var column := VBoxContainer.new()
	column.anchor_left = 1.0
	column.anchor_right = 1.0
	column.offset_left = -150
	column.offset_right = -12
	column.offset_top = 92
	column.add_theme_constant_override("separation", 4)
	add_child(column)
	for entry: Array in TOUCH_BUTTONS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(138, 40)
		button.text = entry[1]
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 17)
		var action: String = entry[0]
		button.pressed.connect(func() -> void: action_pressed.emit(action))
		column.add_child(button)
		_buttons[action] = button
		if action.begins_with("slot"):
			var sweep: Control = SkirmishSlot.new()
			sweep.overlay_only = true
			sweep.set_anchors_preset(Control.PRESET_FULL_RECT)
			button.add_child(sweep)
			_button_sweeps[action] = sweep


func refresh() -> void:
	if _skirmish == null:
		return
	_refresh_buttons()
	var resume := "tap Pause" if _skirmish.touch else "Space"
	if Pad.using_pad and not _skirmish.touch:
		resume = Pad.key("command_wait")
	var state := "PAUSED — %s to resume" % resume if _skirmish.paused else "x%s" % String.num(Pace.speed(), 1).trim_suffix(".0")
	if _skirmish.over:
		state = "Over"
	var armed := ""
	if _skirmish.armed_slot >= 0 and not _skirmish.selected.is_empty():
		var caster: Fighter = _skirmish.selected[0]
		var ability := caster.slot_ability(_skirmish.armed_slot)
		var how := "tap a target, or the skill again to cancel" if _skirmish.touch \
				else "left-click a target, right-click to cancel"
		if Pad.using_pad and not _skirmish.touch:
			how = "%s at the target, %s to cancel" % [Pad.key("ui_accept"), Pad.key("ui_cancel")]
		armed = "    Aiming %s — %s" % [ability.get("display_name", "?"), how]
	_clock.text = "%s   %s   %.1fs%s" % [_skirmish.title, state, _skirmish.sim_time, armed]

	var party: Array[Fighter] = _skirmish.party_fighters()
	for i in mini(party.size(), _cards.size()):
		_card_text[i].text = _describe(party[i], i)
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
		var item_buttons: Dictionary = _card_items[i]
		for item_id: String in item_buttons:
			var button: Button = item_buttons[item_id]
			var left := int(_skirmish.pouch.get(item_id, 0))
			button.text = "%s ×%d" % [Gear.display_name(item_id).replace("Bitter ", ""), left]
			button.disabled = _skirmish.item_refusal(party[i], item_id) != ""
	if _inspected != null:
		_inspect_text.text = _inspection(_inspected)


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
	if f.passives.is_empty():
		lines.append("[color=#7d8594]no passives[/color]")
	for p: Dictionary in f.passives:
		lines.append("[color=#c8b6ff]✦ %s[/color] — %s" % [p.get("display_name", p.get("id", "?")), p.get("description", "")])
	return "\n".join(lines)


## Ten pips of energy, gold when it can pay for skills and grey when tired.
static func energy_bar(f: Fighter) -> String:
	var share := clampf(f.energy / maxf(1.0, f.energy_max), 0.0, 1.0)
	var full := roundi(share * 10.0)
	var colour := "#7d8594" if f.tired else "#ffd27a"
	return "[color=%s]%s[/color][color=#3a3f4a]%s[/color]" % [colour, "▮".repeat(full), "▮".repeat(10 - full)]


static func _passive_tooltip(f: Fighter) -> String:
	if f.passives.is_empty():
		return "No passives."
	var lines: Array[String] = []
	for p: Dictionary in f.passives:
		lines.append("%s — %s" % [p.get("display_name", "?"), p.get("description", "")])
	return "\n".join(lines)


static func _ability_tooltip(ability: Dictionary) -> String:
	var extras := ""
	if SkirmishRules.is_charged(ability):
		extras += "\nCharged: hits harder, but a stun breaks it off"
	if float(ability.get("stun", 0.0)) > 0.0:
		extras += "\nStuns for %.1fs and breaks a cast" % float(ability["stun"])
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
	if f.hold:
		flags.append("hold")
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


## The skill buttons say what the first picked fighter would use, and are
## greyed out where they have nothing, so a thumb is never guessing.
func _refresh_buttons() -> void:
	if _buttons.is_empty():
		return
	(_buttons["pause"] as Button).text = "Resume" if _skirmish.paused else "Pause"
	(_buttons["speed"] as Button).text = "Speed x%s" % String.num(Pace.speed(), 1).trim_suffix(".0")
	var caster: Fighter = _skirmish.selected[0] if not _skirmish.selected.is_empty() else null
	for slot in SkirmishRules.SLOT_LABELS.size():
		var button: Button = _buttons.get("slot%d" % slot)
		if button == null:
			continue
		var has := caster != null and slot < caster.slots.size()
		button.disabled = not has
		var label := str(SkirmishRules.SLOT_LABELS[slot])
		if has:
			var name := str(caster.slot_ability(slot).get("display_name", "?"))
			label = "%s %s" % [label, name.left(10)]
			if _skirmish.armed_slot == slot:
				label = "» " + label
		button.text = label
		var sweep: Control = _button_sweeps.get("slot%d" % slot)
		if sweep != null:
			var wait := caster.cooldowns[slot] if has else 0.0
			var total := SkirmishRules.cooldown(caster.slot_ability(slot)) if has else 1.0
			sweep.call("show_slot", "", "", wait, total, false)


static func _panel_style(colour: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = colour
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	return style


func log_line(line: String) -> void:
	_lines.append(line)
	while _lines.size() > LOG_LINES:
		_lines.pop_front()
	if _log != null:
		_log.text = "\n".join(_lines)


func show_result(won: bool) -> void:
	_result.text = "Victory" if won else "Defeat"
	_result.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4) if won else Color(1.0, 0.45, 0.4))
	_result.visible = true
	refresh()
