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

## Loaded by path: see its header for why it has no `class_name`.
const Dispatch := preload("res://src/chronicle/dispatch.gd")
const Moods := preload("res://src/chronicle/moods.gd")
const Crafting := preload("res://src/chronicle/crafting.gd")
## Class colours, growth bars and the shapes of powers ([D66]).
const SheetParts := preload("res://src/ui/sheet_parts.gd")
const Coins := preload("res://src/chronicle/coins.gd")
const Formations := preload("res://src/skirmish/formations.gd")

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
## A card once the company is five or six strong.
const COMPACT_CARD_HEIGHT := 80
const ROW_BUTTON := Vector2(112, 48)
## The arrows that set the marching order. Narrow, but still a thumb tall.
const ORDER_BUTTON := Vector2(44, 42)
## A class card when a path is chosen: wide enough for its growth bars.
const CLASS_CARD := Vector2(250, 0)
## A stone on a power's trail, and the rope between two of them.
const RUNG_STONE := Vector2(60, 60)
const RUNG_ROPE := Vector2(48, 6)
## The width a rung's name may wrap to under its stone.
const RUNG_NAME_WIDTH := 150

## How tall the roster stands over the open character on an upright phone: two cards, then it scrolls.
const ROSTER_UPRIGHT_HEIGHT := 190.0

const GOLD := Color(0.965, 0.827, 0.443)
const QUIET := Color(0.62, 0.65, 0.72)
const GAIN := Color(0.55, 0.86, 0.55)
const LOSS := Color(0.92, 0.52, 0.48)
const WARNING := Color(0.95, 0.72, 0.35)

## MISSION has no tab: it is opened from the "Send" beside a card ([D300]).
enum Page { GEAR, POWERS, PRACTICE, MISSION }

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
@onready var _column: VBoxContainer = $Backdrop/Margin/Column
@onready var _header: HBoxContainer = $Backdrop/Margin/Column/Header
@onready var _body: BoxContainer = $Backdrop/Margin/Column/Body
@onready var _roster_scroll: ScrollContainer = $Backdrop/Margin/Column/Body/RosterScroll

var _notice: String = ""
## Whoever is opened out on the right. Held by id rather than by reference, so
## somebody dying while the screen is shut cannot leave it pointing at a ghost.
var _shown_id: String = ""
var _page: Page = Page.GEAR
var _card_height: int = CARD_HEIGHT
## Where somebody sent on a mission is told to meet the company again: an index into
## [method Dispatch.meeting_places], or -1 for wherever the company is ([D300]).
var _meet_index: int = -1


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.party_screen_requested.connect(open)
	EventBus.growth_choice_requested.connect(func(who: RefCounted) -> void:
		var character := who as Character
		if character != null:
			open_on_growth(character)
	)

	_close_btn.pressed.connect(close)
	_stash_btn.pressed.connect(func() -> void: EventBus.stash_requested.emit())
	_gear_tab.pressed.connect(func() -> void: _turn_to(Page.GEAR))
	_powers_tab.pressed.connect(func() -> void: _turn_to(Page.POWERS))
	_practice_tab.pressed.connect(func() -> void: _turn_to(Page.PRACTICE))
	for button: Button in [_close_btn, _stash_btn, _gear_tab, _powers_tab, _practice_tab]:
		Sfx.attend(button)
	get_viewport().size_changed.connect(_fit_to_screen)
	_fit_to_screen()


## The roster beside the open character on a wide screen; above them on a phone held upright, which
## is 540 of the game's pixels across, too narrow for both side by side (D241). The purse drops
## under the title there too, so Strongbox and Close stay on the screen.
func _fit_to_screen() -> void:
	var view := get_viewport().get_visible_rect().size
	var narrow := view.x < view.y
	_body.vertical = narrow
	($Backdrop/Margin/Column/Body/DetailPanel as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_roster_scroll.custom_minimum_size = Vector2(0, ROSTER_UPRIGHT_HEIGHT) if narrow else Vector2(330, 0)
	var purse_home: Node = _column if narrow else _header
	if _purse.get_parent() != purse_home:
		_purse.get_parent().remove_child(_purse)
		purse_home.add_child(_purse)
		purse_home.move_child(_purse, 1)
	_purse.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if narrow else TextServer.AUTOWRAP_OFF


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


## Open on [param character] at whatever they are owed: a path (which takes
## the page by itself) or a power, which lives on the Powers page.
func open_on_growth(character: Character) -> void:
	_shown_id = character.id
	if not character.pending_class_choice:
		_page = Page.POWERS
	_page_scroll.scroll_vertical = 0
	open()


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


## Hand an accepted errand to [param character] and send them off to do it
## (see `src/chronicle/dispatch.gd`).
func send_away(character: Character, errand: Dictionary, meet: Site = null) -> bool:
	var line := Dispatch.send(GameState.world, GameState.roster, GameState.away, character, errand, meet)
	if line == "":
		return false
	_notice = line
	_rebuild()
	return true


## Mix [param recipe] out of the packs ([D280]).
func mix(recipe: Dictionary) -> bool:
	var line := Crafting.mix(recipe, GameState.stores)
	if line == "":
		return false
	_notice = line
	_rebuild()
	return true


## Send [param character] to shut [param gate], with anyone already on the road to it ([D278]).
func send_to_gate(character: Character, gate: Site, meet: Site = null) -> bool:
	var line := Dispatch.send_to_gate(GameState.world, GameState.roster, GameState.away, character, gate, meet)
	if line == "":
		return false
	_notice = line
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
	# Six cards fit the column without scrolling only if
	# each gives up a little height once the company is past four.
	_card_height = CARD_HEIGHT if party.size() <= 4 else COMPACT_CARD_HEIGHT
	for i in party.size():
		_roster_list.add_child(_card_row(party[i], i, party.size(), shown))

	# Until a path is chosen the page is the choice, and the tabs wait.
	var tabs_wait := shown == null or shown.pending_class_choice
	_gear_tab.disabled = tabs_wait
	_powers_tab.disabled = tabs_wait
	_practice_tab.disabled = tabs_wait
	_mark_tab(_gear_tab, _page == Page.GEAR)
	_mark_tab(_powers_tab, _page == Page.POWERS)
	_mark_tab(_practice_tab, _page == Page.PRACTICE)

	if shown != null:
		_build_head(shown, party)
	if shown != null and shown.pending_class_choice:
		# A path to choose is the one question on the page until it is answered.
		_build_class_choice_page(shown)
	elif shown != null:
		match _page:
			Page.GEAR:
				_build_gear_page(shown)
			Page.POWERS:
				_build_powers_page(shown)
			Page.PRACTICE:
				_build_practice_page(shown, party)
			Page.MISSION:
				_build_mission_page(shown)

	var codex := GameState.world.codex_understanding()
	_purse.text = "%s  ·  %d in the packs  ·  Codex %d%%  ·  step %d%s" % [
		Coins.text(GameState.gold), GameState.stores.size(), roundi(codex * 100.0), GameState.world.steps,
		"" if GameState.away.is_empty() else "  ·  %d away" % GameState.away.size(),
	]
	# How full the company is and how the next seat is earned (agenda item 35).
	_footer.text = "%s  ·  P or Esc to close%s" % [
		Roster.Seats.status_line(GameState.roster), "" if _notice == "" else "  ·  " + _notice
	]


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
	if _missions_open() and not character.is_player:
		row.add_child(_mission_button(character))
	return row


## Whether people can be sent on missions yet: not in the First Hour (D97) until the company
## has shut a gate of its own ([D278]).
func _missions_open() -> bool:
	return not FirstHour.hides("dispatch") and Dispatch.unlocked(GameState.world)


## "Send" beside a card ([D294], [D300]): opens the mission page on that person.
func _mission_button(character: Character) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(64, ORDER_BUTTON.y)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_NONE
	button.text = "Send"
	button.disabled = not Dispatch.can_send(character, GameState.roster, GameState.away)
	button.tooltip_text = "Send %s on a mission: a gate to shut or an errand, and a town to meet you in." % character.display_name
	button.pressed.connect(func() -> void:
		_shown_id = character.id
		_page_scroll.scroll_vertical = 0
		_turn_to(Page.MISSION))
	Sfx.attend(button)
	return button


func _order_button(character: Character, delta: int, allowed: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = ORDER_BUTTON
	button.focus_mode = Control.FOCUS_NONE
	button.disabled = not allowed
	button.text = "^" if delta < 0 else "v"
	button.tooltip_text = "Further %s the line" % ("up" if delta < 0 else "down")
	button.pressed.connect(func() -> void: shift(character, delta))
	Sfx.attend(button)
	return button


## A card: the face, the name, the health, and whatever is owed. The whole card
## is the target rather than a word inside it, because on a phone a word is not
## a target at all.
func _card_for(character: Character, current: bool) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, _card_height)
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
		return "+ a path to choose"
	if character.rungs > 0 and not character.trees.is_empty():
		return "+ %d power%s to take" % [character.rungs, "" if character.rungs == 1 else "s"]
	if character.yoke:
		return "yoked"
	# The natural leader, out of the fights ([D306]).
	if Formations.leader_of(GameState.party_characters()) == character:
		return Formations.badge(character)
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
	title.add_theme_color_override("font_color", GOLD if character.class_id == "" else SheetParts.colour_of(character).lightened(0.25))
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
		var prompt := Label.new()
		prompt.add_theme_color_override("font_color", GOLD)
		prompt.add_theme_font_size_override("font_size", 16)
		prompt.text = "%s has proved they will survive. Choose a path below: it is theirs for life." % character.display_name
		prompt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_head.add_child(prompt)
		return

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	_head.add_child(buttons)

	# The party's formation ([D305]), on the lead's own sheet: a tap steps to the next shape.
	if character.is_player and Formations.on():
		var formation := Button.new()
		formation.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		formation.focus_mode = Control.FOCUS_NONE
		var leader := Formations.leader_of(party)
		var said := Formations.word(GameState.formation, party.size())
		if GameState.formation == "auto" and leader != null:
			said = "%s (%s, %s)" % [Formations.word("auto"), Formations.word(Formations.recommend(party.size(), leader)),
					str(Formations.leader_rules().get("call", "{name}'s call")).format({"name": leader.display_name})]
		formation.text = "Formation: %s" % said
		formation.tooltip_text = Formations.tip(GameState.formation)
		formation.pressed.connect(func() -> void:
			GameState.formation = Formations.next(GameState.formation)
			_rebuild())
		Sfx.attend(formation)
		buttons.add_child(formation)

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
		owed.text = "%d power%s to take" % [character.rungs, "" if character.rungs == 1 else "s"]
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


## The paths open to [param character], one card each in the class's own
## colour: what it grows, where its powers come from, what it hands over on the
## spot, and one button to walk it ([D66]).
func _build_class_choice_page(character: Character) -> void:
	_page_box.add_child(_heading("Choose a path"))
	var cards := HFlowContainer.new()
	cards.add_theme_constant_override("h_separation", 12)
	cards.add_theme_constant_override("v_separation", 12)
	for class_id: String in Progression.class_options(character):
		cards.add_child(_class_card(character, class_id))
	_page_box.add_child(cards)


func _class_card(character: Character, class_id: String) -> Control:
	var colour := SheetParts.class_colour(class_id)
	var card := PanelContainer.new()
	card.custom_minimum_size = CLASS_CARD
	var face := SheetParts.box(colour.darkened(0.82), colour.darkened(0.15), 2, 10)
	face.border_width_top = 8
	face.shadow_color = Color(colour, 0.25)
	face.shadow_size = 8
	face.content_margin_left = 14
	face.content_margin_right = 14
	face.content_margin_top = 12
	face.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", face)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	card.add_child(column)

	var banner := HBoxContainer.new()
	var title := Label.new()
	title.text = SheetParts.class_title(class_id)
	title.add_theme_font_size_override("font_size", 21)
	title.add_theme_color_override("font_color", colour.lightened(0.3))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.add_child(title)
	column.add_child(banner)
	# A question mark at the right of the banner ([D237]): hover it for the path in more words, or
	# press it (on a phone there is no hover) to open them on the card.
	var help_text := SheetParts.class_help(class_id)
	var more := Label.new()
	more.text = help_text
	more.visible = false
	more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	more.add_theme_font_size_override("font_size", 12)
	more.add_theme_color_override("font_color", Color(0.9, 0.9, 0.93))
	var ask := Button.new()
	ask.name = "PathHelp"
	ask.text = "?"
	ask.tooltip_text = help_text
	ask.focus_mode = Control.FOCUS_NONE
	ask.custom_minimum_size = Vector2(30, 30)
	ask.add_theme_stylebox_override("normal", SheetParts.box(colour.darkened(0.6), colour, 1, 15))
	ask.add_theme_stylebox_override("hover", SheetParts.box(colour.darkened(0.3), colour.lightened(0.4), 2, 15))
	ask.add_theme_stylebox_override("pressed", SheetParts.box(colour.darkened(0.7), colour, 1, 15))
	ask.pressed.connect(func() -> void: more.visible = not more.visible)
	Sfx.attend(ask)
	banner.add_child(ask)
	column.add_child(more)

	var themes := Label.new()
	themes.text = "Powers of %s" % "  ·  ".join(SheetParts.theme_names(class_id))
	themes.add_theme_font_size_override("font_size", 12)
	themes.add_theme_color_override("font_color", QUIET)
	themes.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(themes)

	column.add_child(SheetParts.growth_bars(class_id, QUIET, Color(0.04, 0.04, 0.06, 0.9)))

	var grants := SheetParts.grant_names(class_id)
	if not grants.is_empty():
		var starts := Label.new()
		starts.text = "Starts with  %s" % ",  ".join(grants)
		starts.add_theme_font_size_override("font_size", 12)
		starts.add_theme_color_override("font_color", Color(0.84, 0.86, 0.9))
		starts.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(starts)

	var walk := Button.new()
	walk.text = "Walk this path"
	walk.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
	walk.focus_mode = Control.FOCUS_ALL
	walk.add_theme_stylebox_override("normal", SheetParts.box(colour.darkened(0.35), colour, 1, 6))
	walk.add_theme_stylebox_override("hover", SheetParts.box(colour.darkened(0.1), colour.lightened(0.4), 2, 6))
	walk.add_theme_stylebox_override("pressed", SheetParts.box(colour.darkened(0.5), colour, 1, 6))
	walk.add_theme_stylebox_override("focus", SheetParts.box(Color(0, 0, 0, 0), GOLD, 2, 6))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		walk.add_theme_color_override(state, Color(0.98, 0.96, 0.9))
	walk.tooltip_text = "%s takes up the way of the %s. A path is for life." % [
		character.display_name, SheetParts.class_title(class_id)
	]
	walk.pressed.connect(func() -> void: choose_class(character, class_id))
	Sfx.attend(walk)
	column.add_child(walk)
	return card


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

	# Herbs and draughts out of the packs into something stronger (D280).
	_page_box.add_child(_heading("Mixing"))
	var mixable := Crafting.recipes().filter(func(r: Dictionary) -> bool: return Crafting.can_mix(r, GameState.stores))
	if mixable.is_empty():
		_page_box.add_child(_quiet_line("Nothing in the packs to mix. Herbs, a redcap or frostmoss make draughts."))
	for recipe: Dictionary in mixable:
		var stir := Button.new()
		stir.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		stir.focus_mode = Control.FOCUS_NONE
		stir.alignment = HORIZONTAL_ALIGNMENT_LEFT
		stir.text = "Mix a %s" % Crafting.recipe_text(recipe)
		stir.pressed.connect(func() -> void: mix(recipe))
		Sfx.attend(stir)
		_page_box.add_child(stir)

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
	line.text = "%s %d » %d" % [stat, from, to]
	line.add_theme_color_override("font_color", GAIN if to > from else LOSS)
	return line


# --- powers -------------------------------------------------------------------


func _build_powers_page(character: Character) -> void:
	if character.rungs > 0 and not character.trees.is_empty():
		var owed := Label.new()
		owed.add_theme_color_override("font_color", WARNING)
		owed.add_theme_font_size_override("font_size", 15)
		owed.text = "%d power%s to take — press a glowing stone on any path." % [character.rungs, "" if character.rungs == 1 else "s"]
		_page_box.add_child(owed)
	for block in _tree_blocks(character):
		_page_box.add_child(block)


# --- practice, doctrine and teaching ------------------------------------------


func _build_practice_page(character: Character, party: Array[Character]) -> void:
	# How they feel, and why (D279).
	_page_box.add_child(_heading("Mood"))
	_page_box.add_child(_quiet_line(Moods.summary(character)))

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

	# The log of foes ([D301]): what has taught them, what they have only seen fall outside a gate
	# and can still learn from in one, and how far up the Tower they have got their experience.
	_page_box.add_child(_heading("Log of foes"))
	_page_box.add_child(_quiet_line(_beaten_summary(character)))
	_page_box.add_child(_quiet_line(_climbed_line(character)))
	for kind: String in still_to_learn(character):
		var mark := Button.new()
		mark.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		mark.focus_mode = Control.FOCUS_NONE
		mark.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var watching := character.look_for.has(kind)
		mark.text = "%s %s  (seen %d, not learned from)" % [
			"Looking out for" if watching else "Look out for",
			str(Database.unit_template(kind).get("display_name", kind)), int(character.met.get(kind, 0)),
		]
		mark.tooltip_text = "Only the first of a kind put down in a gate or a cave teaches. Marked, it is called out when one stands in a gate."
		mark.pressed.connect(func() -> void: toggle_look_for(character, kind))
		Sfx.attend(mark)
		_page_box.add_child(mark)

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
			button.text = "Teach %s to %s" % [Doctrine.title(doctrine_id), student.display_name]
			button.pressed.connect(func() -> void: teach(character, student, doctrine_id))
			Sfx.attend(button)
			_page_box.add_child(button)
			taught += 1
			# One offer per student keeps the page readable.
			break
	if taught == 0:
		_page_box.add_child(_quiet_line("Nothing they could pass on to anybody here."))

	if not FirstHour.hides("dispatch"):
		_page_box.add_child(_heading("Send on a mission"))
		if character.is_player:
			_page_box.add_child(_quiet_line("The lead goes where the company goes."))
		elif not Dispatch.unlocked(GameState.world):
			_page_box.add_child(_quiet_line("Shut a gate first. Then the Guild will let you send your own people out."))
		else:
			var go := Button.new()
			go.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
			go.focus_mode = Control.FOCUS_NONE
			go.alignment = HORIZONTAL_ALIGNMENT_LEFT
			go.text = "Send %s on a mission" % character.display_name
			go.pressed.connect(func() -> void: _turn_to(Page.MISSION))
			Sfx.attend(go)
			_page_box.add_child(go)
	_away_list()


## The mission page ([D294], [D300]): a gate to shut or an errand to see to, and a town to meet the
## company in afterwards; with none named they come back to wherever the company is, and a crow
## brings word when they are back somewhere the company is not.
func _build_mission_page(character: Character) -> void:
	var roster: Roster = GameState.roster
	_page_box.add_child(_heading("Send %s on a mission" % character.display_name))
	var open := Dispatch.open_errands(GameState.errands)
	var gates := Dispatch.open_gates(GameState.world)
	if character.is_player:
		_page_box.add_child(_quiet_line("The lead goes where the company goes."))
	elif not _missions_open():
		_page_box.add_child(_quiet_line("Shut a gate first. Then the Guild will let you send your own people out."))
	elif not Dispatch.can_send(character, roster, GameState.away):
		_page_box.add_child(_quiet_line("Not now — someone has to stay with the lead, and they have to be on their feet."))
	elif open.is_empty() and gates.is_empty():
		_page_box.add_child(_quiet_line("No errand to give them and no gate you know of. Take one from a settlement's board first."))
	else:
		var places := Dispatch.meeting_places(GameState.world)
		if _meet_index >= places.size():
			_meet_index = -1
		var meet: Site = places[_meet_index] if _meet_index >= 0 else null
		var where := Button.new()
		where.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
		where.focus_mode = Control.FOCUS_NONE
		where.alignment = HORIZONTAL_ALIGNMENT_LEFT
		where.text = "Meet me at: %s" % (meet.display_name if meet != null else "wherever the company is")
		where.tooltip_text = "Where they come back to when it is done. If you are not there, a crow brings word, and they wait for you."
		where.disabled = places.is_empty()
		where.pressed.connect(func() -> void:
			_meet_index = _meet_index + 1 if _meet_index + 1 < places.size() else -1
			_rebuild())
		Sfx.attend(where)
		_page_box.add_child(where)
		for gate: Site in gates:
			var band := Dispatch.band_for(GameState.away, gate)
			var with := "" if band.is_empty() else " with %s" % ", ".join(Dispatch.members(roster, band).map(func(c: Character) -> String: return c.display_name))
			var odds := Dispatch.gate_chance(Dispatch.members(roster, band) + [character], gate)
			var send := Button.new()
			send.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
			send.focus_mode = Control.FOCUS_NONE
			send.alignment = HORIZONTAL_ALIGNMENT_LEFT
			send.text = "Shut %s%s (%s-rank, about %d in 10)" % [
				gate.display_name, with, gate.reading(), roundi(odds * 10.0)]
			send.tooltip_text = "They walk there on their own, go in, and shut it if they can. If they cannot, each of them may fall. Send more to the same gate before they get there and they go together."
			send.pressed.connect(func() -> void: send_to_gate(character, gate, meet))
			Sfx.attend(send)
			_page_box.add_child(send)
		for errand: Dictionary in open:
			var go := Button.new()
			go.custom_minimum_size = Vector2(0, ROW_BUTTON.y)
			go.focus_mode = Control.FOCUS_NONE
			go.alignment = HORIZONTAL_ALIGNMENT_LEFT
			go.text = Errand.summary(errand)
			go.tooltip_text = "They leave the company, walk it while you walk, and come back — if nothing finds them on the road."
			go.pressed.connect(func() -> void: send_away(character, errand, meet))
			Sfx.attend(go)
			_page_box.add_child(go)
	_away_list()


func _away_list() -> void:
	if not GameState.away.is_empty():
		_page_box.add_child(_heading("Away"))
		for job: Dictionary in GameState.away:
			_page_box.add_child(_quiet_line(Dispatch.summary(job, GameState.roster, GameState.world)))


## Every kind of enemy this character has learned from, and the ones they are
## part-way to learning from by helping. Experience only comes from the first of
## each kind ([D37]), so this is also the list of what is no longer worth
## anything to them but practice.
func _beaten_summary(character: Character) -> String:
	var names: Array[String] = []
	for kind: String in character.beaten:
		names.append(str(Database.unit_template(kind).get("display_name", kind)))
	names.sort()
	var text := "Nothing yet. The first of every kind of enemy put down in a gate teaches something; the second teaches only practice." \
			if names.is_empty() else "%d kinds: %s." % [names.size(), ", ".join(names)]
	var helping: Array[String] = []
	for kind: String in character.assists:
		helping.append("%s %d/%d" % [
			str(Database.unit_template(kind).get("display_name", kind)),
			int(character.assists[kind]), Progression.assists_needed(),
		])
	helping.sort()
	if not helping.is_empty():
		text += "\nHelping with: %s. A healer's assist counts toward %d instead." % [
			", ".join(helping), Progression.assists_needed(true)
		]
	return text


## Kinds [param character] has seen fall outside a gate and not yet learned from, by name.
static func still_to_learn(character: Character) -> Array[String]:
	var out: Array[String] = []
	for kind: String in character.met:
		if not character.beaten.has(kind):
			out.append(kind)
	out.sort_custom(func(a: String, b: String) -> bool:
		return str(Database.unit_template(a).get("display_name", a)) < str(Database.unit_template(b).get("display_name", b)))
	return out


## Mark or unmark [param kind] for [param character] to look out for in a gate.
func toggle_look_for(character: Character, kind: String) -> void:
	if character.look_for.has(kind):
		character.look_for.erase(kind)
	else:
		character.look_for.append(kind)
	_rebuild()


func _climbed_line(character: Character) -> String:
	if character.climbed <= 0:
		return "Has not climbed the Tower: no experience from it yet."
	return "Climbed to floor %d of the Tower." % character.climbed


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


## What each uncovered tree holds, and how far up it they have got, drawn as
## a trail of stones ([D66]): filled in the class's colour where a power is
## known, glowing gold where one can be taken, dark where it is still ahead. A
## tree is generated for the world rather than looked up in a data file, so
## this is the only place a player can see what they are actually climbing
## (see [AbilityGrammar]).
func _tree_blocks(character: Character) -> Array[Control]:
	var out: Array[Control] = []
	if character.trees.is_empty():
		if character.level < TREE_AT:
			out.append(_quiet_line(
				"Nothing uncovered yet — the first path comes at level %d." % TREE_AT
			))
		return out

	var colour := SheetParts.colour_of(character)
	var offered := Progression.rung_options(character, GameState.world)
	for tree_id: String in character.trees:
		var tree := GameState.world.tree(tree_id)
		if tree.is_empty():
			continue
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 6)
		var name_line := _heading("%s  ·  the %s" % [
			tree.get("display_name", tree_id), tree.get("theme", "")
		])
		name_line.add_theme_color_override("font_color", colour.lightened(0.25))
		block.add_child(name_line)

		var trail := HBoxContainer.new()
		trail.add_theme_constant_override("separation", 0)
		var abilities: Array = tree.get("abilities", [])
		for rung in abilities.size():
			var ability_id: String = abilities[rung]
			if rung > 0:
				var lit := ability_id in character.learned
				trail.add_child(_rung_rope(colour if lit else Color(0.28, 0.28, 0.33)))
			trail.add_child(_rung_stop(character, ability_id, rung, colour,
					character.rungs > 0 and offered.has(ability_id)))
		block.add_child(trail)
		out.append(block)

	if character.trees.size() == 1 and character.level < Progression.SECOND_TREE_LEVEL:
		out.append(_quiet_line(
			"A second path uncovers at level %d." % Progression.SECOND_TREE_LEVEL
		))

	return out


## One stop on a trail: its stone, and its name and shape under it.
func _rung_stop(character: Character, ability_id: String, rung: int, colour: Color, takeable: bool) -> Control:
	var ability := Database.ability(ability_id)
	var known := ability_id in character.learned
	var stop := VBoxContainer.new()
	stop.add_theme_constant_override("separation", 4)
	stop.custom_minimum_size = Vector2(RUNG_NAME_WIDTH, 0)

	var stone := Button.new()
	stone.custom_minimum_size = RUNG_STONE
	stone.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	stone.focus_mode = Control.FOCUS_ALL if takeable else Control.FOCUS_NONE
	stone.text = SheetParts.NUMERALS[mini(rung, SheetParts.NUMERALS.size() - 1)]
	stone.add_theme_font_size_override("font_size", 18)
	var radius := int(RUNG_STONE.x / 2.0)
	var fill: StyleBoxFlat
	var ink: Color
	if known:
		fill = SheetParts.box(colour, colour.lightened(0.35), 2, radius)
		ink = colour.darkened(0.75)
	elif takeable:
		fill = SheetParts.box(Color(0.22, 0.17, 0.06), GOLD, 3, radius)
		fill.shadow_color = Color(GOLD, 0.45)
		fill.shadow_size = 10
		ink = GOLD
	else:
		fill = SheetParts.box(Color(0.09, 0.09, 0.12), Color(0.3, 0.3, 0.36), 2, radius)
		ink = Color(0.42, 0.43, 0.47)
	for state: String in ["normal", "disabled", "pressed", "focus"]:
		stone.add_theme_stylebox_override(state, fill)
	var lifted := fill.duplicate() as StyleBoxFlat
	if takeable:
		lifted.bg_color = Color(0.36, 0.28, 0.08)
		lifted.shadow_size = 16
	stone.add_theme_stylebox_override("hover", lifted)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		stone.add_theme_color_override(state, ink)
	stone.disabled = not takeable
	stone.tooltip_text = "%s\n%s\n%s" % [
		ability.get("display_name", ability_id), SheetParts.ability_shape(ability),
		"Known." if known else ("Press to take it." if takeable else "Further up the path."),
	]
	if takeable:
		stone.pressed.connect(func() -> void: take_rung(character, ability_id))
		Sfx.attend(stone)
		# A slow breath, so the stone that can be taken is the one the eye finds.
		var breath := stone.create_tween().set_loops()
		breath.tween_property(stone, "modulate", Color(1.25, 1.2, 1.05), 0.8)
		breath.tween_property(stone, "modulate", Color(1, 1, 1), 0.8)
	stop.add_child(stone)

	var name_line := Label.new()
	name_line.text = str(ability.get("display_name", ability_id))
	name_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_line.add_theme_font_size_override("font_size", 13)
	name_line.add_theme_color_override("font_color",
			Color(0.9, 0.9, 0.93) if known else (GOLD if takeable else Color(0.46, 0.47, 0.5)))
	stop.add_child(name_line)

	var shape := Label.new()
	var extra := ""
	if known and Proficiency.uses(character, ability_id) > 0:
		extra = "\n%s" % Proficiency.summary(character, ability_id)
	shape.text = SheetParts.ability_shape(ability) + extra
	shape.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shape.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shape.add_theme_font_size_override("font_size", 11)
	shape.add_theme_color_override("font_color", QUIET if known or takeable else Color(0.36, 0.37, 0.4))
	stop.add_child(shape)
	return stop


## The rope between two stones, level with their middles.
func _rung_rope(colour: Color) -> Control:
	var holder := MarginContainer.new()
	holder.add_theme_constant_override("margin_top", int((RUNG_STONE.y - RUNG_ROPE.y) / 2.0))
	holder.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var rope := ColorRect.new()
	rope.custom_minimum_size = RUNG_ROPE
	rope.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	rope.color = colour
	rope.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(rope)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return holder


func _doctrine_summary(character: Character) -> String:
	if character.doctrine.is_empty():
		return "Nothing yet."
	var titles: Array[String] = []
	var steps := GameState.world.steps if GameState.world != null else 0
	for doctrine_id: String in character.doctrine:
		var fading := Doctrine.is_fading_memory(character, doctrine_id, steps)
		titles.append("%s%s" % [Doctrine.title(doctrine_id), "  (fading)" if fading else ""])
	return "  ·  ".join(titles)
