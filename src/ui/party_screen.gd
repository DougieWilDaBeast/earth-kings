class_name PartyScreen
extends CanvasLayer
## The one screen where the party is more than health bars: pick a class, pass
## a book to someone who needs it, take the Yoke on or off.
##
## Rows are built in code because everything on them depends on who the
## character is and what the world has already handed them.

signal closed

## Pieces out of the packs offered per person, so a full bag does not run the
## row off the edge of the screen.
const GEAR_OFFERS := 4
## And how many draughts, so the packs do not bury the rest of the row.
const DRAUGHT_OFFERS := 3
## Level the first tree turns up at, so somebody without one is told to wait
## rather than told nothing.
const TREE_AT := Progression.FIRST_TREE_LEVEL
## Big enough to tell a sword from a robe at a glance, small enough for a row.
const ICON_SIZE := Vector2(32, 32)

@onready var _backdrop: ColorRect = %Backdrop
@onready var _roster_list: VBoxContainer = %RosterList
@onready var _footer: Label = %FooterLabel

var _notice: String = ""


func _ready() -> void:
	_backdrop.hide()
	add_to_group(EventBus.MODAL_OVERLAY_GROUP)
	EventBus.party_screen_requested.connect(open)


func is_open() -> bool:
	return _backdrop.visible


func open() -> void:
	_backdrop.show()
	_rebuild()


func close() -> void:
	_backdrop.hide()
	_notice = ""
	closed.emit()


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


# --- rendering ----------------------------------------------------------------


func _rebuild() -> void:
	for child in _roster_list.get_children():
		child.queue_free()

	var party := GameState.roster.party_members()
	for character in party:
		_roster_list.add_child(_row_for(character, party))

	var codex := GameState.world.codex_understanding()
	_footer.text = "Codex %d%%  ·  %d gold  ·  %d in the packs  ·  step %d%s  ·  P or Esc to close" % [
		roundi(codex * 100.0), GameState.gold, GameState.stores.size(), GameState.world.steps,
		"" if _notice == "" else "  ·  " + _notice
	]


func _row_for(character: Character, party: Array[Character]) -> Control:
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	var heading := Label.new()
	heading.add_theme_font_size_override("font_size", 18)
	heading.text = "%s  —  level %d %s  ·  %d/%d HP  ·  %d/%d XP%s%s" % [
		character.display_name, character.level, character.class_name_text(),
		character.current_hp(), character.max_hp(),
		character.xp, Progression.xp_to_next(character.level),
		"  ·  YOKED" if character.yoke else "",
		"  ·  %d POWER TO TAKE" % character.rungs if character.rungs > 0 else "",
	]
	row.add_child(heading)

	var known := Label.new()
	known.add_theme_color_override("font_color", Color(0.7, 0.75, 0.84))
	known.text = "Read: %s" % _doctrine_summary(character)
	row.add_child(known)

	var carried := HBoxContainer.new()
	carried.add_theme_constant_override("separation", 6)
	if character.equipment != "":
		carried.add_child(_icon(character.equipment))
	var carried_text := Label.new()
	carried_text.add_theme_color_override("font_color", Color(0.84, 0.79, 0.66))
	carried_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	carried_text.text = "Carrying: %s" % _gear_summary(character)
	carried.add_child(carried_text)
	for charm_id: String in character.charms:
		var charm := _icon(charm_id)
		charm.tooltip_text = "%s — %s" % [
			Gear.display_name(charm_id), Gear.summary(charm_id, character)
		]
		carried.add_child(charm)
	row.add_child(carried)

	for block in _tree_blocks(character):
		row.add_child(block)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 6)
	row.add_child(buttons)

	if character.pending_class_choice:
		var prompt := Label.new()
		prompt.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
		prompt.text = "Choose a path:"
		buttons.add_child(prompt)
		for class_id: String in Progression.class_options(character):
			var pick := Button.new()
			pick.text = Database.character_class(class_id).get("display_name", class_id)
			pick.pressed.connect(func() -> void: choose_class(character, class_id))
			buttons.add_child(pick)
	else:
		var yoke := Button.new()
		yoke.text = "Set down the Yoke" if character.yoke else "Take the Yoke"
		yoke.tooltip_text = "-%d%% attack, +%d%% experience" % [
			roundi(Character.YOKE_ATTACK_PENALTY * 100.0), roundi(Character.YOKE_XP_BONUS * 100.0)
		]
		yoke.pressed.connect(func() -> void: toggle_yoke(character))
		buttons.add_child(yoke)
		_add_gear_buttons(buttons, character)
		_add_draught_buttons(buttons, character)
		_add_teaching_buttons(buttons, character, party)

	return row


## The packs, offered best-first. A piece that would make them worse is still
## offered — sometimes the only shield left is the wrong shield.
func _add_gear_buttons(into: HBoxContainer, character: Character) -> void:
	if character.equipment != "":
		var off := Button.new()
		off.text = "Stow the %s" % Gear.display_name(character.equipment)
		off.pressed.connect(func() -> void: unequip(character))
		into.add_child(off)
	var shown := 0
	for equipment_id: String in Gear.offers(character):
		if shown >= GEAR_OFFERS:
			break
		var swing := Gear.swing(equipment_id, character)
		# The theme's button art swallows `Button.icon`, so the picture is its
		# own node sitting against the button it belongs to.
		var offer := HBoxContainer.new()
		offer.add_theme_constant_override("separation", 2)
		offer.add_child(_icon(equipment_id))
		var button := Button.new()
		button.text = "%s (%+d)" % [Gear.display_name(equipment_id), swing]
		button.tooltip_text = Gear.summary(equipment_id, character)
		button.pressed.connect(func() -> void: equip(character, equipment_id))
		offer.add_child(button)
		into.add_child(offer)
		shown += 1


## Food and physic in the packs. Only offered to somebody with something to
## mend, so a full-health party is not tempted to waste the good bottle.
func _add_draught_buttons(into: HBoxContainer, character: Character) -> void:
	if character.current_hp() >= character.max_hp():
		return
	var shown := 0
	for equipment_id: String in Gear.draughts():
		if shown >= DRAUGHT_OFFERS:
			break
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 2)
		row.add_child(_icon(equipment_id))
		var button := Button.new()
		var short := mini(Gear.mends(equipment_id), character.max_hp() - character.current_hp())
		button.text = "%s (+%d)" % [Gear.display_name(equipment_id), short]
		button.tooltip_text = Gear.summary(equipment_id, character)
		button.pressed.connect(func() -> void: drink(character, equipment_id))
		row.add_child(button)
		into.add_child(row)
		shown += 1


## A piece as its picture, at a size a row can carry.
func _icon(equipment_id: String) -> TextureRect:
	var art := TextureRect.new()
	art.custom_minimum_size = ICON_SIZE
	art.texture = Gear.icon(equipment_id)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.tooltip_text = Gear.display_name(equipment_id)
	return art


func _gear_summary(character: Character) -> String:
	if character.equipment == "":
		return "nothing worth naming"
	return "%s (%s)" % [
		Gear.display_name(character.equipment), Gear.summary(character.equipment, character)
	]


func _add_teaching_buttons(into: HBoxContainer, teacher: Character, party: Array[Character]) -> void:
	for student in party:
		if student == teacher:
			continue
		for doctrine_id: String in Doctrine.teachable(teacher, student):
			var button := Button.new()
			button.text = "Teach %s → %s" % [Doctrine.title(doctrine_id), student.display_name]
			button.pressed.connect(func() -> void: teach(teacher, student, doctrine_id))
			into.add_child(button)
			# One offer per student keeps the row readable.
			break


## What each uncovered tree holds, and how far up it they have got. A tree is
## generated for the world rather than looked up in a data file, so this is the
## only place a player can see what they are actually climbing (see
## [AbilityGrammar]).
func _tree_blocks(character: Character) -> Array[Control]:
	var out: Array[Control] = []
	if character.trees.is_empty():
		if character.level < TREE_AT:
			var waiting := Label.new()
			waiting.add_theme_color_override("font_color", Color(0.5, 0.52, 0.56))
			waiting.text = "Powers: nothing uncovered yet — the first comes at level %d." % TREE_AT
			out.append(waiting)
		return out

	for tree_id: String in character.trees:
		var tree := GameState.world.tree(tree_id)
		if tree.is_empty():
			continue
		var block := VBoxContainer.new()
		block.add_theme_constant_override("separation", 1)

		var heading := Label.new()
		heading.add_theme_color_override("font_color", Color(0.95, 0.82, 0.45))
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
				block.add_child(take)
				continue

			var rung_line := Label.new()
			rung_line.add_theme_color_override(
				"font_color", Color(0.86, 0.88, 0.92) if known else Color(0.46, 0.47, 0.5)
			)
			rung_line.text = "    %s %s  —  %s" % [
				"■" if known else "□",
				ability.get("display_name", ability_id),
				shape,
			]
			block.add_child(rung_line)
		out.append(block)

	if character.trees.size() == 1 and character.level < Progression.SECOND_TREE_LEVEL:
		var next_hint := Label.new()
		next_hint.add_theme_color_override("font_color", Color(0.5, 0.52, 0.56))
		next_hint.text = "Powers: a second path uncovers at level %d." % Progression.SECOND_TREE_LEVEL
		out.append(next_hint)

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
		return "nothing yet"
	var titles: Array[String] = []
	for doctrine_id: String in character.doctrine:
		var stale := GameState.world.steps - int(character.doctrine_seen.get(doctrine_id, 0))
		var fading := stale > Doctrine.FADE_AFTER_STEPS * 0.75
		titles.append("%s%s" % [Doctrine.title(doctrine_id), "  (fading)" if fading else ""])
	return "  ·  ".join(titles)
