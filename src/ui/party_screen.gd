class_name PartyScreen
extends CanvasLayer
## The party menu: who is marching, what they carry, and what they can do about it.
##
## Two panes. On the left the marching order, one card a person, close enough to
## a health bar and a portrait to be read at a glance and reordered without
## reading anything at all. On the right whoever is picked out of it, on one of
## three pages: their [b]Gear[/b], their [b]Powers[/b], their [b]Lore[/b].
##
## The gear page is the point of the screen. Nothing is equipped blind: putting
## the pointer on a piece in the packs writes what it would do to the numbers
## the fight will actually use into the column beside the numbers they have now,
## so a swap is compared before it is made rather than after. [b]Optimise[/b] is
## there for anyone who would rather not compare anything.
##
## Everything on both panes is built in code, because everything on them depends
## on who the character is and what the world has already handed them.

signal closed

## Pieces out of the packs offered per person, so a full bag does not run the
## list off the bottom of the pane.
const GEAR_OFFERS := 8
## And how many draughts, so the packs do not bury the rest of the page.
const DRAUGHT_OFFERS := 5
## Level the first tree turns up at, so somebody without one is told to wait
## rather than told nothing.
const TREE_AT := Progression.FIRST_TREE_LEVEL
## Big enough to tell a sword from a robe at a glance, small enough for a row.
const ICON_SIZE := Vector2(32, 32)
## The face on a party card. Unit art is drawn small; this is about as far as it
## can be stretched before it turns to porridge.
const PORTRAIT_SIZE := Vector2(52, 52)
const CARD_HEIGHT := 76
## Taller, for a card that has something owed or worn written across it.
const CARD_HEIGHT_MARKED := 94
const OFFER_HEIGHT := 40

const GEAR_PAGE := "gear"
const POWERS_PAGE := "powers"
const LORE_PAGE := "lore"
## The pages of the right-hand pane, in the order their tabs sit.
const PAGES := [GEAR_PAGE, POWERS_PAGE, LORE_PAGE]
const PAGE_TITLES := {
	GEAR_PAGE: "Gear",
	POWERS_PAGE: "Powers",
	LORE_PAGE: "Lore",
}

## Health left before the bar stops being green, and before it stops being amber.
const HEALTH_STEADY := 0.5
const HEALTH_SHAKY := 0.2

const GOLD := Color(0.95, 0.82, 0.45)
const PALE := Color(0.86, 0.88, 0.92)
const QUIET := Color(0.7, 0.75, 0.84)
const MUTED := Color(0.5, 0.52, 0.56)
const WARM := Color(0.84, 0.79, 0.66)
const GAIN := Color(0.55, 0.85, 0.55)
const LOSS := Color(0.91, 0.48, 0.45)

@onready var _root: Control = %Root
@onready var _roster_list: VBoxContainer = %RosterList
@onready var _detail_heading: Label = %DetailHeading
@onready var _detail_sub: Label = %DetailSub
@onready var _tab_row: HBoxContainer = %TabRow
@onready var _detail_box: VBoxContainer = %DetailBox
@onready var _purse: Label = %PurseLabel
@onready var _close_button: Button = %CloseButton
@onready var _footer: Label = %FooterLabel

## Whose page is open. Empty falls through to the front of the marching order.
var _selected_id: String = ""
var _page: String = GEAR_PAGE
## The piece being weighed but not taken — what the gear page previews. Empty
## while nothing is under the pointer, which is most of the time.
var _weighing: String = ""
var _notice: String = ""
## Stat key -> the cells a preview writes into. Rebuilt with the gear page, so
## everything here is stale the moment anything else is drawn.
var _after_cells: Dictionary = {}
var _delta_cells: Dictionary = {}


func _ready() -> void:
	_root.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.party_screen_requested.connect(open)
	_close_button.pressed.connect(close)
	Sfx.attend(_close_button)


func is_open() -> bool:
	return _root.visible


func open() -> void:
	_root.show()
	_weighing = ""
	_rebuild()


func close() -> void:
	_root.hide()
	_notice = ""
	_weighing = ""
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open() or not event.is_pressed() or event.is_echo():
		return
	if event.is_action("ui_cancel") or event.is_action("open_party"):
		get_viewport().set_input_as_handled()
		close()


# --- the choices themselves ---------------------------------------------------


## Bring somebody's pages up. Public so a level-up prompt can point the screen
## at the person it is waiting on.
func select(character: Character) -> bool:
	if character == null or character.id == _selected_id:
		return false
	_selected_id = character.id
	_weighing = ""
	_rebuild()
	return true


func show_page(page_id: String) -> bool:
	if page_id not in PAGES or page_id == _page:
		return false
	_page = page_id
	_weighing = ""
	_rebuild()
	return true


## Move somebody up or down the marching order.
func shift(character: Character, delta: int) -> bool:
	if not GameState.roster.shift(character.id, delta):
		return false
	_notice = "%s moves %s the line." % [
		character.display_name, "up" if delta < 0 else "down"
	]
	_rebuild()
	return true


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


## Public so the tests can move gear about without the UI.
func equip(character: Character, equipment_id: String) -> bool:
	if not Gear.equip(character, equipment_id):
		return false
	_notice = "%s takes up the %s." % [character.display_name, Gear.display_name(equipment_id)]
	_weighing = ""
	_rebuild()
	return true


func unequip(character: Character) -> bool:
	var had := character.equipment
	if not Gear.unequip(character):
		return false
	_notice = "%s puts the %s in the packs." % [character.display_name, Gear.display_name(had)]
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
	_weighing = ""
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


# --- rendering ----------------------------------------------------------------


## Whoever is picked, or the front of the line when nobody is (or when the one
## who was has since been lost).
func _selected() -> Character:
	var party := GameState.roster.party_members()
	if party.is_empty():
		return null
	for character in party:
		if character.id == _selected_id:
			return character
	_selected_id = party[0].id
	return party[0]


func _rebuild() -> void:
	_after_cells.clear()
	_delta_cells.clear()
	_empty(_roster_list)
	_empty(_tab_row)
	_empty(_detail_box)

	var party := GameState.roster.party_members()
	var chosen := _selected()
	for i in party.size():
		_roster_list.add_child(_card_for(party[i], i, party.size(), chosen))
	for character in GameState.roster.characters:
		if character.id not in GameState.roster.party:
			_roster_list.add_child(_bench_row(character))

	_build_tabs()
	_build_detail(chosen, party)
	_refresh_chrome()


## Children are taken out of the tree as well as freed: a queued free still
## draws for the rest of the frame, and a rebuilt list would show double.
func _empty(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


# --- the marching order -------------------------------------------------------


func _card_for(character: Character, index: int, count: int, chosen: Character) -> Control:
	var card := HBoxContainer.new()
	card.add_theme_constant_override("separation", 4)

	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = PORTRAIT_SIZE
	portrait.texture = Database.unit_face(character.template_id)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not character.is_available():
		portrait.modulate = Color(0.45, 0.42, 0.45)
	line.add_child(portrait)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 3)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(stack)

	var name_line := Label.new()
	name_line.add_theme_font_size_override("font_size", 16)
	name_line.text = "%d.  %s%s" % [
		index + 1, character.display_name, "  (you)" if character.is_player else ""
	]
	_clamp(name_line)
	stack.add_child(name_line)

	var calling := Label.new()
	calling.add_theme_font_size_override("font_size", 13)
	calling.add_theme_color_override("font_color", QUIET)
	calling.text = "Lv %d  %s" % [character.level, character.class_name_text()]
	_clamp(calling)
	stack.add_child(calling)

	# What is owed gets a line of its own: it is the reason to open this screen,
	# and a card this narrow would otherwise trim it off the end of the calling.
	var marks := _marks(character)
	if marks != "":
		var owed := Label.new()
		owed.add_theme_font_size_override("font_size", 12)
		owed.add_theme_color_override("font_color", GOLD)
		owed.text = marks
		_clamp(owed)
		stack.add_child(owed)

	stack.add_child(_health_bar(character))

	var pick := _slot_button(
		_padded(line), CARD_HEIGHT_MARKED if marks != "" else CARD_HEIGHT, character == chosen
	)
	pick.tooltip_text = "%s — %s" % [character.display_name, character.background_display()]
	pick.pressed.connect(func() -> void: select(character))
	card.add_child(pick)
	card.add_child(_order_buttons(character, index, count))
	return card


## What is owed, worn or waiting on this person, said in as few marks as the
## card has room for.
func _marks(character: Character) -> String:
	var out: Array[String] = []
	if character.pending_class_choice:
		out.append("! A PATH TO CHOOSE")
	if character.rungs > 0 and not character.trees.is_empty():
		out.append("%d POWER TO SPEND" % character.rungs)
	if character.yoke:
		out.append("YOKED")
	return "  ·  ".join(out)


## Keep a line inside the card it was written on, however long the name.
func _clamp(label: Label) -> void:
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.clip_text = true


func _health_bar(character: Character) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	var whole := maxi(1, character.max_hp())
	var left := character.current_hp()
	var share := float(left) / float(whole)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(70, 9)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.show_percentage = false
	bar.max_value = whole
	bar.value = left
	bar.add_theme_stylebox_override("background", _box(Color(0.11, 0.12, 0.15), Color(0.28, 0.3, 0.34), 1))
	bar.add_theme_stylebox_override("fill", _box(_health_colour(share), Color(0, 0, 0, 0), 0))
	row.add_child(bar)

	var text := Label.new()
	text.add_theme_font_size_override("font_size", 12)
	text.add_theme_color_override("font_color", QUIET)
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.text = "%d/%d" % [left, whole] if character.is_alive() else _standing(character)
	row.add_child(text)
	return row


## Where somebody stands when "alive" is not the whole of it.
func _standing(character: Character) -> String:
	match character.status:
		Fate.DEAD:
			return "fallen"
		Fate.CAPTURED:
			return "held at %s" % character.captured_at if character.captured_at != "" else "held"
	return "resting  ·  %d/%d HP" % [character.current_hp(), character.max_hp()]


func _health_colour(share: float) -> Color:
	if share > HEALTH_STEADY:
		return Color(0.42, 0.76, 0.44)
	if share > HEALTH_SHAKY:
		return Color(0.9, 0.75, 0.33)
	return Color(0.85, 0.34, 0.34)


## The order is the order they are drawn in and deployed in, so it is worth
## being able to set it here rather than nowhere.
func _order_buttons(character: Character, index: int, count: int) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var up := _tiny_button("↑", "Further up the line")
	up.disabled = index <= 0
	up.pressed.connect(func() -> void: shift(character, -1))
	column.add_child(up)

	var down := _tiny_button("↓", "Further down the line")
	down.disabled = index >= count - 1
	down.pressed.connect(func() -> void: shift(character, 1))
	column.add_child(down)
	return column


## Anybody on the roster who is not marching — hired and benched, taken, or
## buried. Losing someone should leave a gap you can see.
func _bench_row(character: Character) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", MUTED)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text = "      %s  —  %s" % [character.display_name, _standing(character)]
	row.add_child(label)
	return row


# --- the pages ----------------------------------------------------------------


func _build_tabs() -> void:
	for page_id: String in PAGES:
		var here := page_id == _page
		var tab := Button.new()
		tab.text = str(PAGE_TITLES[page_id])
		tab.custom_minimum_size = Vector2(104, 30)
		tab.add_theme_color_override("font_color", GOLD if here else QUIET)
		_dress(tab, here, 8.0)
		tab.pressed.connect(func() -> void: show_page(page_id))
		Sfx.attend(tab)
		_tab_row.add_child(tab)


func _build_detail(character: Character, party: Array[Character]) -> void:
	if character == null:
		_detail_heading.text = "Nobody is marching."
		_detail_sub.text = "Whatever is left of the company is listed to the left."
		return

	_detail_heading.text = character.display_name
	_detail_sub.text = "Level %d %s  ·  %d/%d HP  ·  %d/%d XP  ·  %s" % [
		character.level, character.class_name_text(),
		character.current_hp(), character.max_hp(),
		character.xp, Progression.xp_to_next(character.level),
		character.background_display(),
	]

	if character.pending_class_choice:
		_detail_box.add_child(_class_prompt(character))

	match _page:
		POWERS_PAGE:
			_build_powers_page(character)
		LORE_PAGE:
			_build_lore_page(character, party)
		_:
			_build_gear_page(character)


## A level-up owed an answer. It sits above whichever page is open, because it
## is the one thing on this screen the game is actually waiting on.
func _class_prompt(character: Character) -> Control:
	var block := VBoxContainer.new()
	block.add_theme_constant_override("separation", 4)

	var prompt := Label.new()
	prompt.add_theme_color_override("font_color", GOLD)
	prompt.add_theme_font_size_override("font_size", 17)
	prompt.text = "A path opens. Choose one — it cannot be taken back."
	block.add_child(prompt)

	var options := HBoxContainer.new()
	options.add_theme_constant_override("separation", 6)
	for class_id: String in Progression.class_options(character):
		var pick := Button.new()
		pick.text = str(Database.character_class(class_id).get("display_name", class_id))
		pick.tooltip_text = _class_blurb(class_id)
		pick.pressed.connect(func() -> void: choose_class(character, class_id))
		Sfx.attend(pick)
		options.add_child(pick)
	block.add_child(options)
	return block


## What a calling is worth, out of its own growth table and its grants — the
## classes carry no blurb, and a name on its own is not a choice.
func _class_blurb(class_id: String) -> String:
	var data := Database.character_class(class_id)
	var raises: Array[String] = []
	var growth: Dictionary = data.get("growth", {})
	for key: String in growth:
		raises.append("%s +%s a level" % [_stat_title(key), String.num(float(growth[key]), 1)])
	var grants: Array[String] = []
	for ability_id: String in data.get("grants", []):
		grants.append(str(Database.ability(ability_id).get("display_name", ability_id)))
	var lines: Array[String] = []
	if not raises.is_empty():
		lines.append(", ".join(raises))
	if not grants.is_empty():
		lines.append("Teaches: %s" % ", ".join(grants))
	return "\n".join(lines)


func _stat_title(key: String) -> String:
	match key:
		"max_hp":
			return "Health"
		"attack":
			return "Attack"
		"defense":
			return "Guard"
		"speed":
			return "Speed"
	return key.capitalize()


# --- gear ---------------------------------------------------------------------


func _build_gear_page(character: Character) -> void:
	_detail_box.add_child(_section("Carried"))

	var worn := HBoxContainer.new()
	worn.add_theme_constant_override("separation", 8)
	var in_hand := character.equipment if character.equipment != "" else Gear.issued_id(character)
	if in_hand != "":
		worn.add_child(_icon(in_hand))
	var worn_text := Label.new()
	worn_text.add_theme_color_override("font_color", WARM)
	worn_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	worn_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	worn_text.text = _gear_summary(character)
	worn.add_child(worn_text)
	if character.equipment != "":
		var stow := Button.new()
		stow.text = "Stow"
		stow.tooltip_text = "Back into the packs. Nothing is thrown away."
		stow.pressed.connect(func() -> void: unequip(character))
		Sfx.attend(stow)
		worn.add_child(stow)
	_detail_box.add_child(worn)

	if not character.charms.is_empty():
		var charms := HBoxContainer.new()
		charms.add_theme_constant_override("separation", 6)
		var charm_label := Label.new()
		charm_label.add_theme_color_override("font_color", QUIET)
		charm_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		charm_label.text = "Charms:"
		charms.add_child(charm_label)
		for charm_id: String in character.charms:
			var charm := _icon(charm_id)
			charm.tooltip_text = "%s — %s" % [
				Gear.display_name(charm_id), Gear.summary(charm_id, character)
			]
			charms.add_child(charm)
		_detail_box.add_child(charms)

	_detail_box.add_child(_stat_table(character))

	var packs_head := HBoxContainer.new()
	packs_head.add_theme_constant_override("separation", 10)
	var packs_title := _section("In the packs")
	packs_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	packs_head.add_child(packs_title)

	var best := Gear.best_offer(character)
	var optimum := Button.new()
	optimum.text = "Optimise"
	optimum.disabled = best == ""
	optimum.tooltip_text = (
		"Nothing in the packs would be an improvement."
		if best == ""
		else "Take up the %s (%+d)" % [Gear.display_name(best), Gear.swing(best, character)]
	)
	optimum.pressed.connect(func() -> void: optimise(character))
	Sfx.attend(optimum)
	packs_head.add_child(optimum)
	_detail_box.add_child(packs_head)

	var offers := Gear.offers(character)
	if offers.is_empty():
		_detail_box.add_child(_muted_line("The packs hold nothing worth carrying."))
	for i in mini(offers.size(), GEAR_OFFERS):
		_detail_box.add_child(_offer_row(character, offers[i]))
	if offers.size() > GEAR_OFFERS:
		_detail_box.add_child(_muted_line(
			"…and %d more in the packs, none of them better." % (offers.size() - GEAR_OFFERS)
		))

	var draughts := Gear.draughts()
	if draughts.is_empty():
		return
	_detail_box.add_child(_section("Food and physic"))
	if character.current_hp() >= character.max_hp():
		_detail_box.add_child(_muted_line("%s is unhurt — nothing here would do anything." % character.display_name))
	for i in mini(draughts.size(), DRAUGHT_OFFERS):
		_detail_box.add_child(_draught_row(character, draughts[i]))


## A piece in the packs, as a row that can be weighed before it is taken.
func _offer_row(character: Character, equipment_id: String) -> Control:
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)
	line.add_child(_icon(equipment_id))

	var name_label := Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_label.text = Gear.display_name(equipment_id)
	line.add_child(name_label)

	var kind_label := Label.new()
	kind_label.add_theme_font_size_override("font_size", 13)
	kind_label.add_theme_color_override("font_color", MUTED)
	kind_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kind_label.custom_minimum_size = Vector2(70, 0)
	kind_label.text = Gear.kind(equipment_id)
	line.add_child(kind_label)

	if not Gear.suits(equipment_id, character):
		var misfit := Label.new()
		misfit.add_theme_font_size_override("font_size", 13)
		misfit.add_theme_color_override("font_color", LOSS)
		misfit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		misfit.text = "wrong hands"
		line.add_child(misfit)

	var swing := Gear.swing(equipment_id, character)
	var swing_label := Label.new()
	swing_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	swing_label.custom_minimum_size = Vector2(52, 0)
	swing_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swing_label.add_theme_color_override("font_color", _swing_colour(swing))
	swing_label.text = "%+d" % swing if swing != 0 else "—"
	line.add_child(swing_label)

	var row := _slot_button(_padded(line), OFFER_HEIGHT, false)
	row.tooltip_text = Gear.summary(equipment_id, character)
	row.pressed.connect(func() -> void: equip(character, equipment_id))
	row.mouse_entered.connect(func() -> void: _weigh(character, equipment_id))
	row.focus_entered.connect(func() -> void: _weigh(character, equipment_id))
	row.mouse_exited.connect(func() -> void: _weigh(character, ""))
	row.focus_exited.connect(func() -> void: _weigh(character, ""))
	return row


func _draught_row(character: Character, equipment_id: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_icon(equipment_id))

	var short := mini(Gear.mends(equipment_id), character.max_hp() - character.current_hp())
	var label := Label.new()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.text = "%s  —  mends %d" % [Gear.display_name(equipment_id), Gear.mends(equipment_id)]
	row.add_child(label)

	var use := Button.new()
	use.text = "Take (+%d)" % short
	use.disabled = short <= 0
	use.tooltip_text = Gear.summary(equipment_id, character)
	use.pressed.connect(func() -> void: drink(character, equipment_id))
	Sfx.attend(use)
	row.add_child(use)
	return row


## The numbers, and what the piece under the pointer would do to them. Guard and
## attack are the two a piece can move, so they are the two with room to change;
## the rest are there because a swap is not the only reason to look.
func _stat_table(character: Character) -> Control:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 3)

	_stat_line(grid, character, "attack", "Attack")
	_stat_line(grid, character, "defense", "Guard")
	_fixed_line(grid, "Health", "%d / %d" % [character.current_hp(), character.max_hp()])
	_fixed_line(grid, "Speed", str(character.speed()))
	_fixed_line(grid, "Step", "%d tiles, jump %d" % [character.move_points(), character.jump()])

	_refresh_stats(character)
	return grid


func _stat_line(grid: GridContainer, character: Character, key: String, title: String) -> void:
	var name_label := Label.new()
	name_label.add_theme_color_override("font_color", QUIET)
	name_label.text = title
	grid.add_child(name_label)

	var now := Label.new()
	now.add_theme_color_override("font_color", PALE)
	now.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	now.custom_minimum_size = Vector2(48, 0)
	now.text = str(int(Gear.fielded(character, character.equipment).get(key, 0)))
	grid.add_child(now)

	var after := Label.new()
	after.custom_minimum_size = Vector2(72, 0)
	grid.add_child(after)
	_after_cells[key] = after

	var delta := Label.new()
	delta.custom_minimum_size = Vector2(90, 0)
	grid.add_child(delta)
	_delta_cells[key] = delta


func _fixed_line(grid: GridContainer, title: String, value: String) -> void:
	var name_label := Label.new()
	name_label.add_theme_color_override("font_color", QUIET)
	name_label.text = title
	grid.add_child(name_label)

	var now := Label.new()
	now.add_theme_color_override("font_color", PALE)
	now.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	now.custom_minimum_size = Vector2(48, 0)
	now.text = value
	grid.add_child(now)

	grid.add_child(_spacer())
	grid.add_child(_spacer())


## Put a piece up against what is already carried, or take it back down again.
func _weigh(character: Character, equipment_id: String) -> void:
	if _weighing == equipment_id or _page != GEAR_PAGE:
		return
	_weighing = equipment_id
	_refresh_stats(character)


## Write the preview into the table. Nothing is rebuilt: the cells are already
## there, and freeing the row the pointer is sitting on to redraw a number is a
## good way to lose the pointer.
func _refresh_stats(character: Character) -> void:
	var worn := character.equipment
	var now := Gear.fielded(character, worn)
	var soon := Gear.fielded(character, _weighing) if _weighing != "" else now
	for key: String in _after_cells:
		var after: Label = _after_cells[key]
		var delta: Label = _delta_cells.get(key)
		if not is_instance_valid(after) or not is_instance_valid(delta):
			continue
		if _weighing == "" or _weighing == worn:
			after.text = ""
			delta.text = ""
			continue
		var before := int(now.get(key, 0))
		var behind := int(soon.get(key, 0))
		var colour := _swing_colour(behind - before)
		after.text = "→  %d" % behind
		after.add_theme_color_override("font_color", colour)
		delta.text = "%+d" % (behind - before) if behind != before else "no change"
		delta.add_theme_color_override("font_color", colour)


func _swing_colour(swing: int) -> Color:
	if swing > 0:
		return GAIN
	if swing < 0:
		return LOSS
	return MUTED


## What they are fighting with, which is not always what was handed to them: a
## template issued with a blade keeps swinging it until something beats it, and
## a swap measured against an empty hand would read better than it fights.
func _gear_summary(character: Character) -> String:
	if character.equipment != "":
		return "%s  —  %s" % [
			Gear.display_name(character.equipment), Gear.summary(character.equipment, character)
		]
	var issued := Gear.issued_id(character)
	if issued == "":
		return "Nothing worth naming."
	return "%s  —  %s  ·  theirs from the start" % [
		Gear.display_name(issued), Gear.summary(issued, character)
	]


# --- powers -------------------------------------------------------------------


func _build_powers_page(character: Character) -> void:
	if character.rungs > 0 and not character.trees.is_empty():
		var owed := Label.new()
		owed.add_theme_color_override("font_color", GOLD)
		owed.text = "%d power earned and not yet placed — take a rung below." % character.rungs
		_detail_box.add_child(owed)

	for block in _tree_blocks(character):
		_detail_box.add_child(block)

	_detail_box.add_child(_section("Practice"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 3)
	for ability_id: String in character.abilities():
		var name_label := Label.new()
		name_label.add_theme_color_override("font_color", PALE)
		name_label.text = str(Database.ability(ability_id).get("display_name", ability_id))
		grid.add_child(name_label)

		var prof := Label.new()
		prof.add_theme_color_override("font_color", Color(0.68, 0.78, 0.72))
		prof.text = Proficiency.summary(character, ability_id)
		grid.add_child(prof)
	_detail_box.add_child(grid)


## What each uncovered tree holds, and how far up it they have got. A tree is
## generated for the world rather than looked up in a data file, so this is the
## only place a player can see what they are actually climbing (see
## [AbilityGrammar]).
func _tree_blocks(character: Character) -> Array[Control]:
	var out: Array[Control] = []
	if character.trees.is_empty():
		if character.level < TREE_AT:
			out.append(_muted_line(
				"Nothing uncovered yet — the first path comes at level %d." % TREE_AT
			))
		return out

	for tree_id: String in character.trees:
		var tree := GameState.world.tree(tree_id)
		if tree.is_empty():
			continue
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 1)

		var heading := Label.new()
		heading.add_theme_color_override("font_color", GOLD)
		heading.add_theme_font_size_override("font_size", 17)
		heading.text = "%s  ·  the %s" % [tree.get("display_name", tree_id), tree.get("theme", "")]
		block.add_child(heading)

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
				take.text = "    Take %s  —  %s" % [
					ability.get("display_name", ability_id), shape
				]
				take.alignment = HORIZONTAL_ALIGNMENT_LEFT
				take.pressed.connect(func() -> void: take_rung(character, ability_id))
				Sfx.attend(take)
				block.add_child(take)
				continue

			var rung_line := Label.new()
			rung_line.add_theme_color_override("font_color", PALE if known else Color(0.46, 0.47, 0.5))
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
		out.append(_muted_line(
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


# --- lore ---------------------------------------------------------------------


func _build_lore_page(character: Character, party: Array[Character]) -> void:
	_detail_box.add_child(_section("Who they are"))
	var who := GridContainer.new()
	who.columns = 2
	who.add_theme_constant_override("h_separation", 20)
	who.add_theme_constant_override("v_separation", 3)
	_pair(who, "Born to", character.background_display())
	_pair(who, "Holds to", character.alignment_display())
	_pair(who, "Grudge", character.grudge_label())
	_detail_box.add_child(who)

	if character.origin_story != "":
		var story := Label.new()
		story.add_theme_color_override("font_color", QUIET)
		story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story.text = character.origin_story
		_detail_box.add_child(story)

	_detail_box.add_child(_section("Read"))
	_detail_box.add_child(_muted_line(_doctrine_summary(character)))
	for student in party:
		if student == character:
			continue
		for doctrine_id: String in Doctrine.teachable(character, student):
			var button := Button.new()
			button.text = "Teach %s → %s" % [Doctrine.title(doctrine_id), student.display_name]
			button.pressed.connect(func() -> void: teach(character, student, doctrine_id))
			Sfx.attend(button)
			_detail_box.add_child(button)
			# One offer per student keeps the page readable.
			break

	_detail_box.add_child(_section("Stance"))
	var yoke_row := HBoxContainer.new()
	yoke_row.add_theme_constant_override("separation", 10)
	var yoke := Button.new()
	yoke.text = "Set down the Yoke" if character.yoke else "Take the Yoke"
	yoke.pressed.connect(func() -> void: toggle_yoke(character))
	Sfx.attend(yoke)
	yoke_row.add_child(yoke)
	var yoke_text := Label.new()
	yoke_text.add_theme_color_override("font_color", QUIET)
	yoke_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	yoke_text.text = "-%d%% attack, +%d%% experience" % [
		roundi(Character.YOKE_ATTACK_PENALTY * 100.0), roundi(Character.YOKE_XP_BONUS * 100.0)
	]
	yoke_row.add_child(yoke_text)
	_detail_box.add_child(yoke_row)

	if party.size() > 1:
		_detail_box.add_child(_section("Company"))
		var bonds := GridContainer.new()
		bonds.columns = 2
		bonds.add_theme_constant_override("h_separation", 20)
		bonds.add_theme_constant_override("v_separation", 3)
		for other in party:
			if other == character:
				continue
			_pair(bonds, other.display_name, "%s (%+d)" % [
				Banter.mood(character, other), Banter.bond(character, other)
			])
		_detail_box.add_child(bonds)


func _doctrine_summary(character: Character) -> String:
	if character.doctrine.is_empty():
		return "Nothing yet."
	var titles: Array[String] = []
	var steps := GameState.world.steps if GameState.world != null else 0
	for doctrine_id: String in character.doctrine:
		var fading := Doctrine.is_fading_memory(character, doctrine_id, steps)
		titles.append("%s%s" % [Doctrine.title(doctrine_id), "  (fading)" if fading else ""])
	return "  ·  ".join(titles)


# --- the frame around it ------------------------------------------------------


func _refresh_chrome() -> void:
	_purse.text = "%d gold  ·  %d in the packs" % [GameState.gold, GameState.stores.size()]
	var world := GameState.world
	var codex := world.codex_understanding() if world != null else 0.0
	_footer.text = "Codex %d%%  ·  step %d  ·  ↑↓ sets the marching order  ·  P or Esc to close%s" % [
		roundi(codex * 100.0),
		world.steps if world != null else 0,
		"" if _notice == "" else "  ·  " + _notice,
	]


## A piece as its picture, at a size a row can carry.
func _icon(equipment_id: String) -> TextureRect:
	var art := TextureRect.new()
	art.custom_minimum_size = ICON_SIZE
	art.texture = Gear.icon(equipment_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	art.tooltip_text = Gear.display_name(equipment_id)
	return art


func _section(title: String) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", GOLD)
	label.text = title.to_upper()
	return label


func _muted_line(text: String) -> Label:
	var label := Label.new()
	label.add_theme_color_override("font_color", MUTED)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = text
	return label


## An empty cell, deaf so it cannot eat a scroll on its way past.
func _spacer() -> Control:
	var filler := Control.new()
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return filler


func _pair(grid: GridContainer, title: String, value: String) -> void:
	var name_label := Label.new()
	name_label.add_theme_color_override("font_color", QUIET)
	name_label.text = title
	grid.add_child(name_label)

	var value_label := Label.new()
	value_label.add_theme_color_override("font_color", PALE)
	value_label.text = value
	grid.add_child(value_label)


## A row of content sitting inside its own margins, ready to be worn by a button.
func _padded(content: Control) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(content)
	return margin


## A wide, pickable row: a button wearing a layout instead of a label. The
## theme's button art is cut for grand menu buttons and would swallow a portrait
## whole, so these rows carry their own plain box.
func _slot_button(content: Control, height: int, selected: bool) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dress(button, selected)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	_deafen(content)
	button.add_child(content)
	Sfx.attend(button)
	return button


func _tiny_button(text: String, hint: String) -> Button:
	var button := Button.new()
	button.text = text
	button.tooltip_text = hint
	button.custom_minimum_size = Vector2(28, 24)
	button.add_theme_font_size_override("font_size", 12)
	_dress(button, false, 2.0)
	Sfx.attend(button)
	return button


## The plain box a row is drawn in, lit differently for the one that is picked.
func _dress(button: Button, selected: bool, pad: float = 0.0) -> void:
	var edge := GOLD if selected else Color(0.29, 0.31, 0.37)
	var fill := Color(0.17, 0.15, 0.12) if selected else Color(0.09, 0.1, 0.12)
	var width := 2 if selected else 1
	button.add_theme_stylebox_override("normal", _box(fill, edge, width, pad))
	button.add_theme_stylebox_override("hover", _box(fill.lightened(0.1), edge.lightened(0.25), 2, pad))
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.2), edge, 2, pad))
	button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), GOLD, 2, pad))
	button.add_theme_stylebox_override("disabled", _box(fill.darkened(0.35), Color(0.2, 0.21, 0.24), 1, pad))


func _box(fill: Color, edge: Color, width: int, pad: float = 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	box.set_content_margin_all(pad)
	return box


## Everything inside a row is scenery — the row itself takes the click.
func _deafen(node: Control) -> void:
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_deafen(child as Control)
