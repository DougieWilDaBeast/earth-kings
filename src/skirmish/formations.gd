extends RefCounted
## Formations ([D289], [D305]): the shapes the player's party walks and fights in, and who stands
## where in them. `doug-md`: "companions walk and fight in a formation, the healer at the back, heavy
## hitters at the front, others on the flanks (a diamond for four, a pyramid of one, two and three for
## six)". The shapes are `formations` in `data/skirmish.json`; this file only reads them.
##
## A shape is a list of **slots** for the companions, each an offset from the lead in the party's own
## frame: `x` across (the lead's right is positive), `y` forward (ahead of the lead is positive), and
## a `line` (`front`, `flank` or `back`) that says who it is for. The lead is always at the origin, so
## a formation turns with whoever is played. Companions are dealt slots by what they fight with
## ([method line_of]): a mender or a shooter goes to the back first, one who swings up close to the
## front, anyone else to the flanks. The same party in the same shape is always dealt the same way.
##
## On the ground the followers walk to their slots round the lead ([code]area_scene[/code]); in a fight
## the party falls in round the lead until anyone is in contact, and holding a slot is a little guard
## ([code]skirmish_brain[/code], [code]skirmish[/code]). Enemies and allies keep to their own ways.
##
## Loaded by path, not by `class_name` ([D41]). Pure logic: no nodes.

const Fighter := preload("res://src/skirmish/fighter.gd")

const NONE := Vector2i(-9999, -9999)


static func rules() -> Dictionary:
	return Database.skirmish.get("formations", {})


static func on() -> bool:
	return bool(rules().get("on", false)) and not shapes().is_empty()


static func shapes() -> Dictionary:
	return rules().get("shapes", {})


## The shapes a player can pick, `auto` first, then in the data's order.
static func names() -> Array:
	var out: Array = ["auto"]
	for id: String in shapes():
		out.append(id)
	return out


## The shape after [param id] in that order, round to the start.
static func next(id: String) -> String:
	var all := names()
	var at := all.find(id)
	return str(all[(at + 1) % all.size()]) if at >= 0 else str(all[0])


## What a shape is called: "Diamond"; `auto` says what it would pick for a party of [param size].
static func word(id: String, size: int = 0) -> String:
	if id == "auto":
		var picked := auto_for(size)
		var said := str(rules().get("auto_word", "Auto"))
		return "%s (%s)" % [said, word(picked)] if picked != "" and size > 1 else said
	return str(shapes().get(id, {}).get("word", id.capitalize()))


static func tip(id: String) -> String:
	if id == "auto":
		return str(rules().get("auto_tip", ""))
	return str(shapes().get(id, {}).get("tip", ""))


## The shape the party picks for itself with [param size] walking (the lead counted), from
## `auto_by_size`; the nearest smaller size when none is written for it.
static func auto_for(size: int) -> String:
	var by_size: Dictionary = rules().get("auto_by_size", {})
	for n in range(size, 1, -1):
		if by_size.has(str(n)):
			return str(by_size[str(n)])
	return str(rules().get("fallback", "")) if not shapes().is_empty() else ""


## The shape the party is in now: the player's pick, or the one picked for [param size].
static func chosen(size: int) -> String:
	var id := str(GameState.formation)
	if id == "auto" or not shapes().has(id):
		id = auto_for(size)
	return id if shapes().has(id) else ""


## The slots of [param shape_id] for [param companions] of them (never more than the shape has), each
## `{ at: Vector2i, line: String }`.
static func slots(shape_id: String, companions: int) -> Array:
	var out: Array = []
	for slot: Dictionary in shapes().get(shape_id, {}).get("slots", []):
		if out.size() >= companions:
			break
		var at: Array = slot.get("at", [0, 0])
		out.append({ "at": Vector2i(int(at[0]), int(at[1])), "line": str(slot.get("line", "flank")) })
	return out


## Which line a fighter of [param template_id] belongs in: `back` for a mender or a shooter, `front`
## for one who swings up close, `flank` for anyone the data does not place. The leads' doctrines
## (`tactics.leads`) say first; anyone else is read from their abilities.
static func line_of(template_id: String) -> String:
	var by_doctrine: Dictionary = rules().get("line_by_doctrine", {})
	var doctrine := str(Database.skirmish.get("tactics", {}).get("leads", {}).get(template_id, ""))
	if doctrine != "" and by_doctrine.has(doctrine):
		return str(by_doctrine[doctrine])
	var abilities: Array = Database.unit_template(template_id).get("abilities", [])
	for ability_id: Variant in abilities:
		var ability := Database.ability(str(ability_id))
		if bool(ability.get("heal", false)) and str(ability.get("target", "")) == "ally" and int(ability.get("range", 0)) >= 2:
			return "back"
	for ability_id: Variant in abilities:
		var ability := Database.ability(str(ability_id))
		if str(ability.get("target", "enemy")) == "enemy" and not bool(ability.get("heal", false)):
			return "back" if int(ability.get("range", 1)) >= 3 else "front"
	return "flank"


## Deals the slots of [param shape_id] to [param companions] (template ids, the lead left out, in
## the party's order): template id -> `at`. The back line is dealt first (the mender matters most),
## then the front, then the rest, each to the nearest line it would rather stand in.
static func assign(shape_id: String, companions: Array) -> Dictionary:
	# Every slot of the shape is open, not the first few: a party of three in a diamond puts its
	# mender behind the lead, not at a flank, because the back slot comes later in the list.
	var open := slots(shape_id, (shapes().get(shape_id, {}).get("slots", []) as Array).size())
	var out := {}
	var order := { "back": 0, "front": 1, "flank": 2 }
	var dealt: Array = companions.duplicate()
	dealt.sort_custom(func(a: String, b: String) -> bool:
		var la := int(order.get(line_of(a), 2))
		var lb := int(order.get(line_of(b), 2))
		return la < lb if la != lb else companions.find(a) < companions.find(b))
	var prefer := {
		"back": ["back", "flank", "front"], "front": ["front", "flank", "back"], "flank": ["flank", "front", "back"],
	}
	for who: String in dealt:
		var picked := -1
		for line: String in prefer.get(line_of(who), prefer["flank"]):
			for i in open.size():
				if str(open[i]["line"]) == line:
					picked = i
					break
			if picked >= 0:
				break
		if picked < 0 and not open.is_empty():
			picked = 0
		if picked < 0:
			break
		out[who] = open[picked]["at"]
		open.remove_at(picked)
	return out


## The heading a formation faces along, as one of the four ways: [param facing]'s longer axis.
static func heading_of(facing: Vector2i) -> Vector2i:
	if facing == Vector2i.ZERO:
		return Vector2i.DOWN
	if absi(facing.x) >= absi(facing.y):
		return Vector2i(signi(facing.x), 0)
	return Vector2i(0, signi(facing.y))


## The cell a slot [param at] stands on when the lead is on [param lead] facing [param facing]: the
## slot's `y` along the heading, its `x` to the lead's right.
static func cell_for(at: Vector2i, lead: Vector2i, facing: Vector2i) -> Vector2i:
	var forward := heading_of(facing)
	var right := Vector2i(-forward.y, forward.x)
	return lead + right * at.x + forward * at.y


## The same on the ground, in pixels: [param spacing] a slot apart, from the lead's [param lead] point.
static func point_for(at: Vector2i, lead: Vector2, facing: Vector2, spacing: float) -> Vector2:
	var forward := Vector2(heading_of(Vector2i(roundi(facing.x), roundi(facing.y))))
	var right := Vector2(-forward.y, forward.x)
	return lead + (right * float(at.x) + forward * float(at.y)) * spacing


# --- in a fight -----------------------------------------------------------------


## The player's lead among [param fighters], standing; null when there is none.
static func lead_of(fighters: Array) -> Fighter:
	for f: Fighter in fighters:
		if f.is_party() and f.is_standing() and f.unit.character != null and f.unit.character.is_player:
			return f
	return null


## The slot cell [param fighter] should be on, round the lead as they face; [constant NONE] for the
## lead, anyone not of the party, or with formations off.
static func slot_cell(fighter: Fighter, fighters: Array) -> Vector2i:
	if not on() or not fighter.is_party() or fighter.unit.character == null:
		return NONE
	var lead := lead_of(fighters)
	if lead == null or lead == fighter:
		return NONE
	var companions: Array = []
	for other: Fighter in fighters:
		if other.is_party() and other.is_standing() and other != lead and other.unit.character != null:
			companions.append(other.unit.character.template_id)
	var shape := chosen(companions.size() + 1)
	if shape == "":
		return NONE
	var dealt := assign(shape, companions)
	if not dealt.has(fighter.unit.character.template_id):
		return NONE
	return cell_for(dealt[fighter.unit.character.template_id], lead.unit.cell, lead.unit.facing)


## Whether anyone of the party is in contact: a standing foe within a tile of one of them. Until then
## the party falls in round the lead; once it is, everyone fights as their doctrine says.
static func in_contact(fighters: Array) -> bool:
	for f: Fighter in fighters:
		if not f.is_party() or not f.is_standing():
			continue
		for other: Fighter in fighters:
			if other.is_standing() and other.unit.is_hostile_to(f.unit) \
					and Pathfinder.distance(other.unit.cell, f.unit.cell) <= 1:
				return true
	return false


## Whether [param fighter] is holding its slot (within `slack` of it), the formation's bonus.
static func holding(fighter: Fighter, fighters: Array) -> bool:
	var slot := slot_cell(fighter, fighters)
	if slot == NONE:
		return false
	return Pathfinder.distance(fighter.unit.cell, slot) <= int(rules().get("slack", 1))


## The guard a fighter holding its slot gets ([D289]: "holding one is a bonus").
static func hold_guard(fighter: Fighter, fighters: Array) -> float:
	return float(rules().get("hold_guard", 0.0)) if holding(fighter, fighters) else 0.0
