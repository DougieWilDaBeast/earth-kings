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
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")

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


## The shape the party is in now: the player's pick, or on `auto` the leader's recommendation
## ([param leader], a Character or null) when there is one, else the one picked for [param size].
static func chosen(size: int, leader: Character = null) -> String:
	var id := str(GameState.formation)
	if id == "auto" or not shapes().has(id):
		id = recommend(size, leader)
	return id if shapes().has(id) else ""


## The shape the leader would call for ([D306]): by the line they fight in (`leader.shapes_by_line`),
## or the one picked for [param size] when nobody leads yet or the data names no shape.
static func recommend(size: int, leader: Character) -> String:
	if leader != null:
		var by_line: Dictionary = rules().get("leader", {}).get("shapes_by_line", {})
		var shape := str(by_line.get(line_of(leader.template_id), ""))
		if shapes().has(shape):
			return shape
	return auto_for(size)


# --- the leader ([D289], [D306]) -----------------------------------------------------


static func leader_rules() -> Dictionary:
	return rules().get("leader", {})


## Fights [param character] has won.
static func won(character: Character) -> int:
	return int(character.fights.get("won", 0)) if character != null else 0


## The natural leader among [param characters]: the most fights won, `from_won` or more; ties to the
## higher level, then the order given. Null while nobody has won enough. Need not be the lead.
static func leader_of(characters: Array) -> Character:
	var best: Character = null
	var floor_won := int(leader_rules().get("from_won", 3))
	for character: Character in characters:
		if character == null or won(character) < floor_won:
			continue
		if best == null or won(character) > won(best) or (won(character) == won(best) and character.level > best.level):
			best = character
	return best


## The leader among the party's standing fighters, or null.
static func leader_fighter(fighters: Array) -> Fighter:
	var characters: Array = []
	var by_character := {}
	for f: Fighter in fighters:
		if f.is_party() and f.is_standing() and f.unit.character != null:
			characters.append(f.unit.character)
			by_character[f.unit.character] = f
	var leader := leader_of(characters)
	return by_character.get(leader) if leader != null else null


## The badge on the leader's card: "leads the fights (7 won)".
static func badge(character: Character) -> String:
	return str(leader_rules().get("badge", "leads the fights ({won} won)")).format({"won": won(character)})


## Whether [param character] is in no state to hold a formation ([D289]: "a formation can break on
## bad leadership and bad calls, through moods"): their mood under `break_below_mood`.
static func broken(character: Character) -> bool:
	if character == null or character.thoughts.is_empty():
		return false
	return character.mood() < int(rules().get("break_below_mood", 0))


# --- fights shared ([D289], [D306]) ----------------------------------------------------


## The share of every blow [param fighter] is spared, and lands over, for the fights won beside the
## others of the party standing with them: `shared.per_fight` each (their average), up to `shared.cap`.
static func shared_bonus(fighter: Fighter, fighters: Array) -> float:
	if not fighter.is_party() or fighter.unit.character == null:
		return 0.0
	var mine: Character = fighter.unit.character
	var total := 0
	var others := 0
	for other: Fighter in fighters:
		if other == fighter or not other.is_party() or not other.is_standing() or other.unit.character == null:
			continue
		total += int(mine.shared.get(other.unit.character.id, 0))
		others += 1
	if others == 0:
		return 0.0
	var shared: Dictionary = rules().get("shared", {})
	return minf(float(shared.get("cap", 0.0)), float(shared.get("per_fight", 0.0)) * float(total) / float(others))


## Written as a fight ends ([param victory]) for the party's [param characters] who were in it: each
## came through one more, and, won, one more beside each of the others.
static func record_fight(characters: Array, victory: bool) -> void:
	for character: Character in characters:
		var key := "won" if victory else "lost"
		character.fights[key] = int(character.fights.get(key, 0)) + 1
		if not victory:
			continue
		for other: Character in characters:
			if other != character:
				character.shared[other.id] = int(character.shared.get(other.id, 0)) + 1


# --- call-outs ([D289], [D306]) ----------------------------------------------------------


static func callout_rules() -> Dictionary:
	return rules().get("callouts", {})


## A foe worth a shout: one who mends, or one who shoots.
static func is_soft(fighter: Fighter) -> bool:
	return fighter.heal_below > SkirmishRules.AUTO_HEAL_BELOW or int(Database.ability(fighter.basic).get("range", 1)) > 1


## Whether [param fighter] is the one who calls for its side: the party's leader (else its lead), or
## a foe band's boss (else the first of them standing).
static func calls_for_its_side(fighter: Fighter, fighters: Array) -> bool:
	if fighter.is_party():
		var leader := leader_fighter(fighters)
		return fighter == (leader if leader != null else lead_of(fighters))
	if fighter.unit.sides_with_party():
		return false
	var first: Fighter = null
	for other: Fighter in fighters:
		if not other.is_standing() or other.unit.sides_with_party():
			continue
		if other.unit.has_meta("boss") and bool(other.unit.get_meta("boss")):
			return other == fighter
		if first == null:
			first = other
	return first == fighter


## The words [param caller] shouts on going for [param target], or "" for nothing worth a shout: a
## mender ("Get the healer!") or a shooter ("On the archer!").
static func callout(caller: Fighter, target: Fighter, fighters: Array) -> String:
	if target == null or not callout_rules().has("warned_for") or not calls_for_its_side(caller, fighters):
		return ""
	if not is_soft(target):
		return ""
	var key := "healer" if target.heal_below > SkirmishRules.AUTO_HEAL_BELOW else "archer"
	return str(callout_rules().get(key, ""))


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
	return assign_by(shape_id, companions, func(id: String) -> String: return line_of(id))


## [method assign] for any keys: [param line_for] says which line each of [param keys] belongs in
## (a band's foes are keyed by their place in it, [D315], since two wolves share a template).
static func assign_by(shape_id: String, keys: Array, line_for: Callable) -> Dictionary:
	# Only the first as many slots as there are companions are open, so a small party keeps a
	# compact shape with no holes in it; a shape's slots are written in the order they fill.
	var open := slots(shape_id, keys.size())
	var out := {}
	var order := { "back": 0, "front": 1, "flank": 2 }
	var dealt: Array = keys.duplicate()
	dealt.sort_custom(func(a: String, b: String) -> bool:
		var la := int(order.get(line_for.call(a), 2))
		var lb := int(order.get(line_for.call(b), 2))
		return la < lb if la != lb else keys.find(a) < keys.find(b))
	var prefer := {
		"back": ["back", "flank", "front"], "front": ["front", "flank", "back"], "flank": ["flank", "front", "back"],
	}
	for who: String in dealt:
		var picked := -1
		for line: String in prefer.get(line_for.call(who), prefer["flank"]):
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
	var characters: Array = []
	for other: Fighter in fighters:
		if other.is_party() and other.is_standing() and other.unit.character != null:
			characters.append(other.unit.character)
	var shape := chosen(companions.size() + 1, leader_of(characters))
	if shape == "" or broken(fighter.unit.character):
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


## The guard a fighter holding its slot gets ([D289]: "holding one is a bonus"); a foe holding its
## band's slot gets `foes.hold_guard` ([D315]).
static func hold_guard(fighter: Fighter, fighters: Array) -> float:
	if holding(fighter, fighters):
		return float(rules().get("hold_guard", 0.0))
	var band := band_slot_cell(fighter, fighters)
	if band != NONE and Pathfinder.distance(fighter.unit.cell, band) <= int(rules().get("slack", 1)):
		return float(foe_rules().get("hold_guard", 0.0))
	return 0.0


# --- a band of foes in formation ([D289], [D315]) ------------------------------------------------


static func foe_rules() -> Dictionary:
	return rules().get("foes", {})


## The foe who sets the band's shape: its boss, else the first of them standing ([D306]'s caller).
static func band_caller(fighters: Array) -> Fighter:
	var first: Fighter = null
	for other: Fighter in fighters:
		if not other.is_standing() or other.is_party() or other.unit.sides_with_party():
			continue
		if other.unit.has_meta("boss") and bool(other.unit.get_meta("boss")):
			return other
		if first == null:
			first = other
	return first


## The nearest standing fighter of the party's side to [param from], or null.
static func nearest_of_the_party(from: Vector2i, fighters: Array) -> Fighter:
	var best: Fighter = null
	var best_far := 999
	for other: Fighter in fighters:
		if not other.is_standing() or not (other.is_party() or other.unit.sides_with_party()):
			continue
		var far := Pathfinder.distance(from, other.unit.cell)
		if far < best_far:
			best = other
			best_far = far
	return best


## The slot cell a foe should be on in its band's shape ([D315]): round the band's caller, the shape
## facing the nearest of the party, each dealt a slot by what it fights with, in the shape the band's
## size picks. [constant NONE] for the caller, anyone of the party's side, a band of fewer than
## `foes.from` standing, or with it off.
static func band_slot_cell(fighter: Fighter, fighters: Array) -> Vector2i:
	var r := foe_rules()
	if not on() or not bool(r.get("on", false)) or fighter.is_party() or fighter.unit.sides_with_party():
		return NONE
	var caller := band_caller(fighters)
	if caller == null or caller == fighter:
		return NONE
	var band: Array = []
	for other: Fighter in fighters:
		if other.is_standing() and other != caller and not other.is_party() and not other.unit.sides_with_party():
			band.append(other)
	if band.size() + 1 < int(r.get("from", 3)):
		return NONE
	var shape := auto_for(band.size() + 1)
	if shape == "":
		return NONE
	var keys: Array = []
	for i in band.size():
		keys.append(str(i))
	var dealt := assign_by(shape, keys, func(key: String) -> String:
		return line_of((band[int(key)] as Fighter).unit.template_id))
	var mine := str(band.find(fighter))
	if not dealt.has(mine):
		return NONE
	var toward := nearest_of_the_party(caller.unit.cell, fighters)
	var facing: Vector2i = caller.unit.facing if toward == null else toward.unit.cell - caller.unit.cell
	return cell_for(dealt[mine], caller.unit.cell, facing)


## Whether anyone of the band is in contact with the party's side: within a tile of one of them.
static func band_in_contact(fighters: Array) -> bool:
	for f: Fighter in fighters:
		if not f.is_standing() or f.is_party() or f.unit.sides_with_party():
			continue
		for other: Fighter in fighters:
			if other.is_standing() and (other.is_party() or other.unit.sides_with_party()) \
					and Pathfinder.distance(other.unit.cell, f.unit.cell) <= 1:
				return true
	return false
