class_name SkirmishHUD
extends CanvasLayer
## The skirmish's readouts, built in code: the clock, a card per party member
## with their quick slots, the log, and the result.

signal card_clicked(index: int)

const LOG_LINES := 6
const HINT := "Right-click: move · attack · help the fallen    Left-click: select    1–4 / Tab: pick    " \
		+ "Q W E R: skills    A: auto skills    H: hold    Space: pause    T: speed"
const READY := Color(0.62, 0.92, 0.62)
const WAITING := Color(0.62, 0.66, 0.74)
const PANEL := Color(0.08, 0.09, 0.12, 0.86)
const PANEL_SELECTED := Color(0.22, 0.19, 0.08, 0.92)

var _skirmish: Skirmish
var _clock: Label
var _log: Label
var _result: Label
var _cards: Array[PanelContainer] = []
var _card_text: Array[RichTextLabel] = []
var _lines: Array[String] = []
var _plain := _panel_style(PANEL)
var _picked := _panel_style(PANEL_SELECTED)


func setup(skirmish: Skirmish) -> void:
	_skirmish = skirmish

	_clock = Label.new()
	_clock.position = Vector2(16, 10)
	_clock.add_theme_font_size_override("font_size", 20)
	add_child(_clock)

	var hint := Label.new()
	hint.position = Vector2(16, 38)
	hint.text = HINT
	hint.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

	_log = Label.new()
	_log.anchor_top = 1.0
	_log.anchor_bottom = 1.0
	_log.offset_left = 16
	_log.offset_right = 760
	_log.offset_top = -270
	_log.offset_bottom = -150
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
	row.offset_top = -142
	row.offset_bottom = -12
	row.add_theme_constant_override("separation", 10)
	add_child(row)
	var party := skirmish.party_fighters()
	for i in party.size():
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(250, 126)
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var index := i
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				card_clicked.emit(index))
		var text := RichTextLabel.new()
		text.bbcode_enabled = true
		text.fit_content = true
		text.scroll_active = false
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.add_theme_font_size_override("normal_font_size", 13)
		text.add_theme_font_size_override("bold_font_size", 14)
		card.add_child(text)
		row.add_child(card)
		_cards.append(card)
		_card_text.append(text)

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


func refresh() -> void:
	if _skirmish == null:
		return
	var state := "PAUSED — Space to resume" if _skirmish.paused else "x%s" % str(Pace.speed())
	if _skirmish.over:
		state = "Over"
	var armed := ""
	if _skirmish.armed_slot >= 0 and not _skirmish.selected.is_empty():
		var ability := _skirmish.selected[0].slot_ability(_skirmish.armed_slot)
		armed = "    Aiming %s — left-click a target, right-click to cancel" % ability.get("display_name", "?")
	_clock.text = "Skirmish (prototype)   %s   %.1fs%s" % [state, _skirmish.sim_time, armed]

	var party := _skirmish.party_fighters()
	for i in mini(party.size(), _cards.size()):
		_card_text[i].text = _describe(party[i], i)
		_cards[i].add_theme_stylebox_override(
			"panel", _picked if _skirmish.selected.has(party[i]) else _plain
		)


func _describe(f: Fighter, index: int) -> String:
	var unit := f.unit
	var lines: Array[String] = []
	var flags: Array[String] = []
	if f.auto_skill:
		flags.append("auto")
	if f.hold:
		flags.append("hold")
	lines.append("[b]%d  %s[/b]  [color=#9aa3b2]%s[/color]" % [index + 1, unit.display_name, " · ".join(flags)])
	lines.append("%d / %d HP   [color=#c9d1dd]%s[/color]" % [maxi(0, unit.hp), unit.max_hp, f.activity()])
	if f.slots.is_empty():
		lines.append("[color=#7d8594]no skills yet — basic attacks only[/color]")
	for slot in f.slots.size():
		var ability := f.slot_ability(slot)
		var ready := f.cooldowns[slot] <= 0.0
		var colour := READY if ready else WAITING
		var wait := "ready" if ready else "%.1fs" % f.cooldowns[slot]
		lines.append("[color=#%s][%s] %s  %s[/color]" % [
			colour.to_html(false), SkirmishRules.SLOT_LABELS[slot], ability.get("display_name", "?"), wait,
		])
	return "\n".join(lines)


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
