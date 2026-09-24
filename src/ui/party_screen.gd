class_name PartyScreen
extends CanvasLayer
## The one screen where the party is more than health bars: pick a class, hand
## someone a better sword, pass a book to whoever needs it, take the Yoke on.
##
## The party is a column of cards down the left — a face, a name, a health bar
## and whatever is owed — and one of them at a time is opened out on the right
## under Gear, Powers and Practice. Everybody's whole sheet at once was a wall
## of text nobody could read and, on a phone, a wall of targets nobody could
## hit.
##
## Cards and pages are built in code because everything on them depends on who
## the character is and what the world has already handed them.

signal closed

## Pieces out of the packs offered per person. The page scrolls, so this is
## about what is worth reading rather than what fits on one row.
const GEAR_OFFERS := 8
## And how many draughts.
const DRAUGHT_OFFERS := 4
## Level the first tree turns up at, so somebody without one is told to wait
## rather than told nothing.
const TREE_AT := Progression.FIRST_TREE_LEVEL
## Big enough to tell a sword from a robe at a glance, small enough for a row.
const ICON_SIZE := Vector2(32, 32)
## The face on a card. Drawn from the same art the character walks around in.
const FACE_SIZE := Vector2(56, 56)
## Tall enough to put a thumb on without hitting the card above.
const CARD_HEIGHT := 92
const ROW_BUTTON := Vector2(112, 48)
## The arrows that set the marching order. Narrow, but still a thumb tall.
const ORDER_BUTTON := Vector2(44, 42)

const GOLD := Color(0.965, 0.827, 0.443)
const QUIET := Color(0.62, 0.65, 0.72)
const GAIN := Color(0.55, 0.86, 0.55)
const LOSS := Color(0.92, 0.52, 0.48)
const WARNING := Color(0.95, 0.72, 0.35)

enum Page { GEAR, POWERS, PRACTICE }

@onready var _backdrop: ColorRect = %Backdrop
@onready var _roster_list: VBoxContainer = %RosterList
@onready var _head: VBoxContainer = %Head
@onready var _page_box: VBoxContainer = %Page
@onready var _page_scroll: ScrollContainer = %PageScroll
@onready var _footer: Label = %FooterLabel
@onready var _purse: Label = %PurseLabel
@onready var _close_btn: Button = %CloseButton
@onready var _stash_btn: Button = %StashButton
@onready var _gear_tab: Button = %GearTab
@onready var _powers_tab: Button = %PowersTab
@onready var _practice_tab: Button = %PracticeTab

var _notice: String = ""
## Whoever is opened out on the right. Held by id rather than by reference, so
## somebody dying while the screen is shut cannot leave it pointing at a ghost.
var _shown_id: String = ""
var _page: Page = Page.GEAR


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.party_screen_requested.connect(open)

	_close_btn.pressed.connect(close)
	_stash_btn.pressed.connect(func() -> void: EventBus.stash_requested.emit())
	_gear_tab.pressed.connect(func() -> void: _turn_to(Page.GEAR))
	_powers_tab.pressed.connect(func() -> void: _turn_to(Page.POWERS))
	_practice_tab.pressed.connect(func() -> void: _turn_to(Page.PRACTICE))
	for button: Button in [_close_btn, _stash_btn, _gear_tab, _powers_tab, _practice_tab]:
		Sfx.attend(button)


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	_notice = ""
	closed.emit()
	EventBus.overlay_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel") or event.is_action("open_party"):
		get_viewport().set_input_as_handled()
		close()


# --- the choices themselves ---------------------------------------------------


## Public so the walk scene and the tests can settle a class without the UI.
func choose_class(character: Character, class_id: String) -> bool:
	if not Progression.settle_class(character, class_id):
		return false
	_notice = "%s takes up the way of the %s." % [character.display_name, character.class_name_text()]
	_rebuild()
	return true


func teach(teacher: Character, student: Character, doctrine_id: String) -> bool:
	if not Doctrine.teach(teacher, student, doctrine_id, GameState.world.steps):
		return false
	_notice = "%s teaches %s to %s." % [
		teacher.display_name, Doctrine.title(doctrine_id), student.display_name
	]
	_rebuild()
	return true


func toggle_yoke(character: Character) -> void:
	character.yoke = not character.yoke
	_notice = "%s %s the Training Yoke." % [
		character.display_name, "takes on" if character.yoke else "sets down"
	]
	_rebuild()


## Move somebody one place up or down the marching order. The order is the
## order they are drawn in and deployed in, so it is worth being able to set it
## here rather than nowhere.
func shift(character: Character, delta: int) -> bool:
	if not GameState.roster.shift(character.id, delta):
		return false
	_notice = "%s moves %s the line." % [
		character.display_name, "up" if delta < 0 else "down"
	]
	_rebuild()
	return true


## The one-press answer: the best thing in the packs, taken up without being
## compared to anything. False when the packs hold nothing better.
func optimise(character: Character) -> bool:
	var best := Gear.best_offer(character)
	if best == "" or not Gear.equip(character, best):
		return false
	_notice = "%s takes up the %s — the best in the packs." % [
		character.display_name, Gear.display_name(best)
	]
	_rebuild()
	return true


## Public so the tests can move gear about without the UI.
func equip(character: Character, equipment_id: String) -> bool:
	if not Gear.equip(character, equipment_id):
		return false
	_notice = "%s takes up the %s." % [character.display_name, Gear.display_name(equipment_id)]
	_rebuild()
	return true


func unequip(character: Character) -> bool:
	var had := character.equipment
	if not Gear.unequip(character):
		return false
	_notice = "%s puts the %s in the packs." % [character.display_name, Gear.display_name(had)]
	_rebuild()
	return true


func drink(character: Character, equipment_id: String) -> bool:
	var line := Gear.drink(character, equipment_id)
	if line == "":
		return false
	_notice = line
	_rebuild()
	return true


func take_rung(character: Character, ability_id: String) -> bool:
	if not Progression.spend_rung(character, ability_id, GameState.world):
		return false
	_notice = "%s takes up %s." % [
		character.display_name, Database.ability(ability_id).get("display_name", ability_id)
	]
	_rebuild()
	return true


# --- who is being looked at ---------------------------------------------------


func _turn_to(page: Page) -> void:
	_page = page
	_rebuild()


func _show_character(character: Character) -> void:
	if _shown_id == character.id:
		return
	_shown_id = character.id
	# A page only makes sense for the person it was opened on: powers taken and
	# gear worn are not the same question asked of two people.
	_page_scroll.scroll_vertical = 0
	_rebuild()


## Whoever is opened out, falling back to the front of the party when the one
## who was has been lost, hired away, or never chosen in the first place.
func _shown(party: Array[Character]) -> Character:
	if party.is_empty():
		return null
	for character in party:
		if character.id == _shown_id:
			return character
	# Somebody owed an answer is worth opening before anybody else.
	for character in party:
		if character.pending_class_choice:
			_shown_id = character.id
			return character
	_shown_id = party[0].id
	return party[0]


# --- rendering ----------------------------------------------------------------


func _rebuild() -> void:
	# Taken out of the tree as well as freed: queue_free() only takes effect at
	# the end of the frame, so picking a card and then a tab in the same breath
	# used to stack a second set of everything on top of the first.
	_empty(_roster_list)
	_empty(_page_box)
	_empty(_head)

	var party := GameState.roster.party_members()
	var shown := _shown(party)
	for i in party.size():
		_roster_list.add_child(_card_row(party[i], i, party.size(), shown))

	_gear_tab.disabled = shown == null
	_powers_tab.disabled = shown == null
	_practice_tab.disabled = shown == null
	_mark_tab(_gear_tab, _page == Page.GEAR)
	_mark_tab(_powers_tab, _page == Page.POWERS)
	_mark_tab(_practice_tab, _page == Page.PRACTICE)

	if shown != null:
		_build_head(shown, party)
		match _page:
			Page.GEAR:
				_build_gear_page(shown)
			Page.POWERS:
				_build_powers_page(shown)
			Page.PRACTICE:
				_build_practice_page(shown, party)

	var codex := GameState.world.codex_understanding()
	_purse.text = "%d gold  ·  %d in the packs  ·  Codex %d%%  ·  step %d" % [
		GameState.gold, GameState.stores.size(), roundi(codex * 100.0), GameState.world.steps
	]
	_footer.text = "P or Esc to close%s" % ("" if _notice == "" else "  ·  " + _notice)


func _empty(box: Node) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _mark_tab(tab: Button, current: bool) -> void:
	tab.add_theme_color_override("font_color", GOLD if current else QUIET)


# --- the party down the left --------------------------------------------------


## A card with the arrows that move it. They sit outside the card rather than
## on it: the card is one big press already, and a button inside it would be
## covered by that press.
func _card_row(character: Character, index: int, count: int, shown: Character) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var card := _card_for(character, character == shown)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(card)

	var arrows := VBoxContainer.new()
	arrows.add_theme_constant_override("separation", 2)
	arrows.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrows.add_child(_order_button(character, -1, index > 0))
	arrows.add_child(_order_button(character, 1, index < count - 1))
	row.add_child(arrows)
	return row


func _order_button(character: Character, delta: int, allowed: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = ORDER_BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not allowed
	button.text = "▲" if delta < 0 else "▼"
	button.tooltip_text = "Further %s the line" % ("up" if delta < 0 else "down")
	button.pressed.connect(func() -> void: shift(character, delta))
	Sfx.attend(button)
	return button


## A card: the face, the name, the health, and whatever is owed. The whole card
## is the target rather than a word inside it, because on a phone a word is not
## a target at all.
func _card_for(character: Character, current: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, CARD_HEIGHT)
	card.add_theme_stylebox_override("panel", _card_style(character, current))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	row.add_child(_face(character))

	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lines.add_theme_constant_override("separation", 2)
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(lines)

	var name_line := Label.new()
	name_line.add_theme_font_size_override("font_size", 17)
	name_line.add_theme_color_override("font_color", GOLD if current else Color(0.9, 0.9, 0.93))
	name_line.text = character.display_name
	name_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(name_line)

	var class_line := Label.new()
	class_line.add_theme_font_size_override("font_size", 12)
	class_line.add_theme_color_override("font_color", QUIET)
	class_line.text = "L%d %s" % [character.level, character.class_name_text()]
	class_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines.add_child(class_line)

	lines.add_child(_health_bar(character))

	var badge := _badge_for(character)
	if badge != "":
		var badge_line := Label.new()
		badge_line.add_theme_font_size_override("font_size", 11)
		badge_line.add_theme_color_override("font_color", WARNING)
		badge_line.text = badge
		badge_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lines.add_child(badge_line)

	if character.equipment != "":
		var worn := _icon(character.equipment)
		worn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		worn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(worn)

	# Added last so it sits over the card and takes the press; a PanelContainer
	# gives every child the whole of itself, so this covers the lot.
	var press := Button.new()
	press.flat = true
	press.focus_mode = Control.FOCUS_ALL
	press.tooltip_text = "Open %s" % character.display_name
	press.pressed.connect(func() -> void: _show_character(character))
	# Keeps a keyboard and a thumb pointing at the same card.
	press.focus_entered.connect(func() -> void: _show_character(character))
	Sfx.attend(press)
	card.add_child(press)
	return card


func _card_style(character: Character, current: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.12, 0.16, 0.95) if current else Color(0.08, 0.08, 0.11, 0.9)
	style.border_color = GOLD if current else Color(0.3, 0.3, 0.36, 0.8)
	style.set_border_width_all(1)
	if current:
		style.border_width_left = 4
	if character.pending_class_choice or character.rungs > 0:
		style.border_color = WARNING if not current else GOLD
	style.set_corner_radius_all(4)
	return style


## What a card has to say in one short line, worst news first.
func _badge_for(character: Character) -> String:
	if character.pending_class_choice:
		return "▲ a path to choose"
	if character.rungs > 0 and not character.trees.is_empty():
		return "▲ %d power to take" % character.rungs
	if character.yoke:
		return "yoked"
	return ""


func _health_bar(character: Character) -> Control:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = maxi(1, character.max_hp())
	bar.value = character.current_hp()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var share := float(character.current_hp()) / float(maxi(1, character.max_hp()))
	var fill := StyleBoxFlat.new()
	fill.bg_color = GAIN if share > 0.5 else (WARNING if share > 0.25 else LOSS)
	fill.set_corner_radius_all(2)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.05, 0.05, 0.07, 0.9)
	back.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	bar.tooltip_text = "%d / %d HP" % [character.current_hp(), character.max_hp()]
	return bar


func _face(character: Character) -> TextureRect:
	var art := TextureRect.new()
	art.custom_minimum_size = FACE_SIZE
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.texture = Database.unit_face(character.template_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return art


# --- the head of the page -----------------------------------------------------


func _build_head(character: Character, party: Array[Character]) -> void:
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", GOLD)
	title.text = "%s  —  level %d %s" % [
		character.display_name, character.level, character.class_name_text()
	]
	_head.add_child(title)

	var numbers := Label.new()
	numbers.add_theme_font_size_override("font_size", 14)
	numbers.add_theme_color_override("font_color", Color(0.84, 0.86, 0.9))
	numbers.text = "HP %d/%d   ·   Attack %d   ·   Guard %d   ·   Move %d   ·   Jump %d   ·   XP %d/%d" % [
		character.current_hp(), character.max_hp(),
		_attack_with(character, character.equipment),
		_guard_with(character, character.equipment),
		character.move_points(), character.jump(),
		character.xp, Progression.xp_to_next(character.level),
	]
	_head.add_child(numbers)

	if character.pending_class_choice:
		_head.add_child(_class_choice_row(character))
		return

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_head.add_child(buttons)

	var yoke := Button.new()
	yoke.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
	yoke.focus_mode = Control.FOCUS_NONE
	yoke.text = "Set down the Yoke" if character.yoke else "Take the Yoke"
	yoke.tooltip_text = "-%d%% attack, +%d%% experience" % [
		roundi(Character.YOKE_ATTACK_PENALTY * 100.0), roundi(Character.YOKE_XP_BONUS * 100.0)
	]
	yoke.pressed.connect(func() -> void: toggle_yoke(character))
	Sfx.attend(yoke)
	buttons.add_child(yoke)

	if character.rungs > 0 and not character.trees.is_empty():
		var owed := Button.new()
		owed.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		owed.focus_mode = Control.FOCUS_NONE
		owed.add_theme_color_override("font_color", WARNING)
		owed.text = "%d power to take" % character.rungs
		owed.pressed.connect(func() -> void: _turn_to(Page.POWERS))
		Sfx.attend(owed)
		buttons.add_child(owed)

	if _has_something_to_teach(character, party):
		var teaching := Button.new()
		teaching.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		teaching.focus_mode = Control.FOCUS_NONE
		teaching.text = "Has a book to pass on"
		teaching.pressed.connect(func() -> void: _turn_to(Page.PRACTICE))
		Sfx.attend(teaching)
		buttons.add_child(teaching)


func _class_choice_row(character: Character) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)

	var prompt := Label.new()
	prompt.add_theme_color_override("font_color", GOLD)
	prompt.add_theme_font_size_override("font_size", 16)
	prompt.text = "Choose a path:"
	box.add_child(prompt)

	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	box.add_child(row)
	for class_id: String in Progression.class_options(character):
		var pick := Button.new()
		pick.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		pick.focus_mode = Control.FOCUS_NONE
		pick.text = Database.character_class(class_id).get("display_name", class_id)
		pick.pressed.connect(func() -> void: choose_class(character, class_id))
		Sfx.attend(pick)
		row.add_child(pick)
	return box


# --- gear: what is worn, and what swapping to it would do ---------------------


func _build_gear_page(character: Character) -> void:
	_page_box.add_child(_heading("Worn"))

	var worn := HBoxContainer.new()
	worn.add_theme_constant_override("separation", 8)
	var in_hand := character.equipment if character.equipment != "" else Gear.issued_id(character)
	if in_hand != "":
		worn.add_child(_icon(in_hand))
	var worn_text := Label.new()
	worn_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	worn_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	worn_text.add_theme_color_override("font_color", Color(0.84, 0.79, 0.66))
	worn_text.text = _gear_summary(character)
	worn.add_child(worn_text)
	if character.equipment != "":
		var stow := Button.new()
		stow.custom_minimum_size = ROW_BUTTON
		stow.focus_mode = Control.FOCUS_NONE
		stow.text = "Stow"
		stow.pressed.connect(func() -> void: unequip(character))
		Sfx.attend(stow)
		worn.add_child(stow)
	_page_box.add_child(worn)

	if not character.charms.is_empty():
		_page_box.add_child(_heading("Carried"))
		var charms := HFlowContainer.new()
		charms.add_theme_constant_override("h_separation", 8)
		for charm_id: String in character.charms:
			var carried := HBoxContainer.new()
			carried.add_theme_constant_override("separation", 4)
			carried.add_child(_icon(charm_id))
			var label := Label.new()
			label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			label.add_theme_font_size_override("font_size", 13)
			label.add_theme_color_override("font_color", QUIET)
			label.text = "%s — %s" % [
				Gear.display_name(charm_id), Gear.summary(charm_id, character)
			]
			carried.add_child(label)
			charms.add_child(carried)
		_page_box.add_child(charms)

	var offers := Gear.offers(character)
	var packs_head := HBoxContainer.new()
	packs_head.add_theme_constant_override("separation", 10)
	var packs_title := _heading("In the packs")
	packs_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	packs_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	packs_head.add_child(packs_title)

	# One press for anybody who would rather not read the rows.
	var best := Gear.best_offer(character)
	var optimum := Button.new()
	optimum.custom_minimum_size = ROW_BUTTON
	optimum.focus_mode = Control.FOCUS_NONE
	optimum.text = "Optimise"
	optimum.disabled = best == ""
	optimum.tooltip_text = (
		"Nothing in the packs would be an improvement."
		if best == ""
		else "Take up the %s" % Gear.display_name(best)
	)
	optimum.pressed.connect(func() -> void: optimise(character))
	Sfx.attend(optimum)
	packs_head.add_child(optimum)
	_page_box.add_child(packs_head)
	if offers.is_empty():
		_page_box.add_child(_quiet_line("Nothing in the packs they could use."))
	else:
		var shown := 0
		for equipment_id: String in offers:
			if shown >= GEAR_OFFERS:
				break
			_page_box.add_child(_offer_row(character, equipment_id))
			shown += 1

	var thirsty := character.current_hp() < character.max_hp()
	_page_box.add_child(_heading("Food and physic"))
	if not thirsty:
		_page_box.add_child(_quiet_line("Nothing to mend."))
		return
	var poured := 0
	for equipment_id: String in Gear.draughts():
		if poured >= DRAUGHT_OFFERS:
			break
		_page_box.add_child(_draught_row(character, equipment_id))
		poured += 1
	if poured == 0:
		_page_box.add_child(_quiet_line("Nothing in the packs to drink."))


## One piece out of the packs, said the way an equip screen says it: what it is,
## what it would do to the numbers, and the button that does it.
func _offer_row(character: Character, equipment_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(equipment_id))

	var lines := VBoxContainer.new()
	lines.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lines.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lines.add_theme_constant_override("separation", 1)
	row.add_child(lines)

	var name_line := Label.new()
	name_line.add_theme_font_size_override("font_size", 15)
	name_line.text = Gear.display_name(equipment_id)
	lines.add_child(name_line)

	var summary := Label.new()
	summary.add_theme_font_size_override("font_size", 12)
	summary.add_theme_color_override("font_color", QUIET)
	summary.text = Gear.summary(equipment_id, character)
	lines.add_child(summary)

	# Both numbers as they stand and as they would stand, so the swap is read
	# rather than worked out. Each is coloured on its own: most armour buys
	# guard with attack, and one colour over the pair says the wrong thing.
	var swing := VBoxContainer.new()
	swing.custom_minimum_size = Vector2(190, 0)
	swing.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swing.add_theme_constant_override("separation", 1)
	swing.add_child(_change_line(
		"Atk",
		_attack_with(character, character.equipment),
		_attack_with(character, equipment_id)
	))
	swing.add_child(_change_line(
		"Grd",
		_guard_with(character, character.equipment),
		_guard_with(character, equipment_id)
	))
	row.add_child(swing)

	var take := Button.new()
	take.custom_minimum_size = ROW_BUTTON
	take.focus_mode = Control.FOCUS_NONE
	take.text = "Equip"
	take.pressed.connect(func() -> void: equip(character, equipment_id))
	Sfx.attend(take)
	row.add_child(take)
	return row


func _draught_row(character: Character, equipment_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_icon(equipment_id))

	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.text = "%s — %s" % [
		Gear.display_name(equipment_id), Gear.summary(equipment_id, character)
	]
	row.add_child(label)

	var mends := Label.new()
	mends.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mends.add_theme_color_override("font_color", GAIN)
	mends.text = "+%d HP" % mini(
		Gear.mends(equipment_id), character.max_hp() - character.current_hp()
	)
	row.add_child(mends)

	var pour := Button.new()
	pour.custom_minimum_size = ROW_BUTTON
	pour.focus_mode = Control.FOCUS_NONE
	pour.text = "Drink"
	pour.pressed.connect(func() -> void: drink(character, equipment_id))
	Sfx.attend(pour)
	row.add_child(pour)
	return row


## The character's attack with [param equipment_id] in hand, worked out the same
## way the fight works it out (see [method Unit.from_character]). An empty id is
## not an empty hand: a template can come issued with a weapon, and the fight
## counts it, so [method Gear.fielded] counts it here too.
func _attack_with(character: Character, equipment_id: String) -> int:
	return int(Gear.fielded(character, equipment_id).get("attack", 0))


func _guard_with(character: Character, equipment_id: String) -> int:
	return int(Gear.fielded(character, equipment_id).get("defense", 0))


## One stat as it stands and as it would stand, coloured by which way it goes.
func _change_line(stat: String, from: int, to: int) -> Label:
	var line := Label.new()
	line.add_theme_font_size_override("font_size", 13)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if from == to:
		line.text = "%s %d" % [stat, to]
		line.add_theme_color_override("font_color", QUIET)
		return line
	line.text = "%s %d → %d" % [stat, from, to]
	line.add_theme_color_override("font_color", GAIN if to > from else LOSS)
	return line


# --- powers -------------------------------------------------------------------


func _build_powers_page(character: Character) -> void:
	if character.rungs > 0 and not character.trees.is_empty():
		var owed := Label.new()
		owed.add_theme_color_override("font_color", WARNING)
		owed.add_theme_font_size_override("font_size", 15)
		owed.text = "%d power to take — pick the next rung of any path." % character.rungs
		_page_box.add_child(owed)
	for block in _tree_blocks(character):
		_page_box.add_child(block)


# --- practice, doctrine and teaching ------------------------------------------


func _build_practice_page(character: Character, party: Array[Character]) -> void:
	_page_box.add_child(_heading("Read"))
	_page_box.add_child(_quiet_line(_doctrine_summary(character)))

	_page_box.add_child(_heading("Practice"))
	for ability_id: String in character.abilities():
		var line := Label.new()
		line.add_theme_font_size_override("font_size", 13)
		line.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
		line.text = "%s  —  %s" % [
			str(Database.ability(ability_id).get("display_name", ability_id)),
			Proficiency.summary(character, ability_id),
		]
		_page_box.add_child(line)

	_page_box.add_child(_heading("Arms"))
	var in_hand := Proficiency.arms_kind(character)
	for kind: String in Proficiency.ARMS + [Proficiency.BARE]:
		if kind != in_hand and Proficiency.arms_uses(character, kind) == 0:
			continue
		var held := Label.new()
		held.add_theme_font_size_override("font_size", 13)
		held.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
		held.text = "%s%s  —  %s" % [
			"bare hands" if kind == Proficiency.BARE else kind.capitalize(),
			"  (in hand)" if kind == in_hand else "",
			Proficiency.arms_summary(character, kind),
		]
		_page_box.add_child(held)

	_page_box.add_child(_heading("Learned from"))
	_page_box.add_child(_quiet_line(_beaten_summary(character)))

	_page_box.add_child(_heading("Teaching"))
	var taught := 0
	for student in party:
		if student == character:
			continue
		for doctrine_id: String in Doctrine.teachable(character, student):
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
			button.focus_mode = Control.FOCUS_NONE
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.text = "Teach %s → %s" % [Doctrine.title(doctrine_id), student.display_name]
			button.pressed.connect(func() -> void: teach(character, student, doctrine_id))
			Sfx.attend(button)
			_page_box.add_child(button)
			taught += 1
			# One offer per student keeps the page readable.
			break
	if taught == 0:
		_page_box.add_child(_quiet_line("Nothing they could pass on to anybody here."))


## Every kind of enemy this character has learned from, and the ones they are
## part-way to learning from by helping. Experience only comes from the first of
## each kind ([D37]), so this is also the list of what is no longer worth
## anything to them but practice.
func _beaten_summary(character: Character) -> String:
	var names: Array[String] = []
	for kind: String in character.beaten:
		names.append(str(Database.unit_template(kind).get("display_name", kind)))
	names.sort()
	var text := "Nothing yet. The first of every kind of enemy teaches something; the second teaches only practice." \
			if names.is_empty() else "%d kinds: %s." % [names.size(), ", ".join(names)]
	var helping: Array[String] = []
	for kind: String in character.assists:
		helping.append("%s %d/%d" % [
			str(Database.unit_template(kind).get("display_name", kind)),
			int(character.assists[kind]), Progression.assists_needed(),
		])
	helping.sort()
	if not helping.is_empty():
		text += "\nHelping with: %s." % ", ".join(helping)
	return text


func _has_something_to_teach(teacher: Character, party: Array[Character]) -> bool:
	for student in party:
		if student == teacher:
			continue
		if not Doctrine.teachable(teacher, student).is_empty():
			return true
	return false


# --- small parts --------------------------------------------------------------


func _heading(text: String) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", GOLD)
	label.text = text
	return label


func _quiet_line(text: String) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", QUIET)
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## A piece as its picture, at a size a row can carry.
func _icon(equipment_id: String) -> TextureRect:
	var art := TextureRect.new()
	art.custom_minimum_size = ICON_SIZE
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.texture = Gear.icon(equipment_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.tooltip_text = Gear.display_name(equipment_id)
	return art


## What they are fighting with, which is not always what was handed to them: a
## template issued with a blade keeps swinging it until something beats it, and
## a swap measured against an empty hand would read better than it fights.
func _gear_summary(character: Character) -> String:
	if character.equipment != "":
		return "%s (%s)" % [
			Gear.display_name(character.equipment), Gear.summary(character.equipment, character)
		]
	var issued := Gear.issued_id(character)
	if issued == "":
		return "Nothing worth naming."
	return "%s (%s)  ·  theirs from the start" % [
		Gear.display_name(issued), Gear.summary(issued, character)
	]


## What each uncovered tree holds, and how far up it they have got. A tree is
## generated for the world rather than looked up in a data file, so this is the
## only place a player can see what they are actually climbing (see
## [AbilityGrammar]).
func _tree_blocks(character: Character) -> Array[Control]:
	var out: Array[Control] = []
	if character.trees.is_empty():
		if character.level < TREE_AT:
			out.append(_quiet_line(
				"Nothing uncovered yet — the first path comes at level %d." % TREE_AT
			))
		return out

	for tree_id: String in character.trees:
		var tree := GameState.world.tree(tree_id)
		if tree.is_empty():
			continue
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 2)
		block.add_child(_heading("%s  ·  the %s" % [
			tree.get("display_name", tree_id), tree.get("theme", "")
		]))

		var abilities: Array = tree.get("abilities", [])
		var offered := Progression.rung_options(character, GameState.world)
		for rung in abilities.size():
			var ability_id: String = abilities[rung]
			var ability := Database.ability(ability_id)
			var known := ability_id in character.learned
			var shape := _ability_shape(ability)

			# A power owed makes the next rung of every tree a choice, so the
			# path up is picked rather than handed out in order.
			if not known and character.rungs > 0 and offered.has(ability_id):
				var take := Button.new()
				take.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
				take.focus_mode = Control.FOCUS_NONE
				take.text = "Take %s  —  %s" % [ability.get("display_name", ability_id), shape]
				take.alignment = HORIZONTAL_ALIGNMENT_LEFT
				take.pressed.connect(func() -> void: take_rung(character, ability_id))
				Sfx.attend(take)
				block.add_child(take)
				continue

			var rung_line := Label.new()
			rung_line.add_theme_font_size_override("font_size", 13)
			rung_line.add_theme_color_override(
				"font_color", Color(0.86, 0.88, 0.92) if known else Color(0.46, 0.47, 0.5)
			)
			var extra := ""
			if known and Proficiency.uses(character, ability_id) > 0:
				extra = "  [%s]" % Proficiency.summary(character, ability_id)
			rung_line.text = "    %s %s  —  %s%s" % [
				"■" if known else "□",
				ability.get("display_name", ability_id),
				shape,
				extra,
			]
			block.add_child(rung_line)
		out.append(block)

	if character.trees.size() == 1 and character.level < Progression.SECOND_TREE_LEVEL:
		out.append(_quiet_line(
			"A second path uncovers at level %d." % Progression.SECOND_TREE_LEVEL
		))

	return out


## Range, splash and weight, said the way the command menu would say it.
func _ability_shape(ability: Dictionary) -> String:
	var parts: Array[String] = []
	var low := int(ability.get("min_range", 1))
	var high := int(ability.get("range", 1))
	parts.append("reach %d" % high if low == high else "reach %d-%d" % [low, high])
	if int(ability.get("splash", 0)) > 0:
		parts.append("catches %d around" % int(ability.get("splash", 0)))
	if bool(ability.get("heal", false)):
		parts.append("mends %d" % int(ability.get("power", 0)))
	else:
		parts.append("x%s" % String.num(float(ability.get("power", 1.0)), 2))
	if bool(ability.get("bonus", false)):
		parts.append("a moment only")
	return "  ".join(parts)


func _doctrine_summary(character: Character) -> String:
	if character.doctrine.is_empty():
		return "Nothing yet."
	var titles: Array[String] = []
	var steps := GameState.world.steps if GameState.world != null else 0
	for doctrine_id: String in character.doctrine:
		var fading := Doctrine.is_fading_memory(character, doctrine_id, steps)
		titles.append("%s%s" % [Doctrine.title(doctrine_id), "  (fading)" if fading else ""])
	return "  ·  ".join(titles)
