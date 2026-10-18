extends RefCounted
## Pieces shared by everything that shows a character's growth: the class
## cards a path is chosen from, the trails a power is taken from, the banner a
## level-up raises, and the character sheet in the journal ([D66]).
##
## Static and stateless. Loaded by path, not by `class_name` ([D41]).

## A class that names no `colour` in `data/classes.json` is drawn in parchment.
const NO_COLOUR := Color(0.85, 0.78, 0.63)
const GOLD := Color(0.965, 0.827, 0.443)

## What each growth bar is measured against: the most any class gains in that
## stat per level, so the strongest class in a stat fills its bar.
const GROWTH_STATS := [
	["max_hp", "Health"],
	["attack", "Attack"],
	["defense", "Guard"],
	["speed", "Speed"],
]

## Numerals for a tree's rungs, weakest first.
const NUMERALS := ["I", "II", "III", "IV", "V", "VI"]


static func class_colour(class_id: String) -> Color:
	var hex := str(Database.character_class(class_id).get("colour", ""))
	return Color.html(hex) if hex != "" and Color.html_is_valid(hex) else NO_COLOUR


## The colour a character is drawn in: their class's, or parchment before one.
static func colour_of(character: Character) -> Color:
	return class_colour(character.class_id) if character.class_id != "" else NO_COLOUR


static func class_title(class_id: String) -> String:
	return str(Database.character_class(class_id).get("display_name", class_id))


## The highest per-level growth of [param stat] across every class.
static func growth_ceiling(stat: String) -> float:
	var most := 0.0
	for class_id: String in Database.classes:
		most = maxf(most, float(Database.classes[class_id].get("growth", {}).get(stat, 0.0)))
	return maxf(most, 0.01)


## Four labelled bars: how much a class gains each level, against the class
## that gains most. Read at a glance, which a column of decimals is not.
static func growth_bars(class_id: String, label_colour: Color, track: Color) -> Control:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 5)
	var growth: Dictionary = Database.character_class(class_id).get("growth", {})
	var colour := class_colour(class_id)
	for pair: Array in GROWTH_STATS:
		var stat: String = pair[0]
		var caption := Label.new()
		caption.text = pair[1]
		caption.custom_minimum_size = Vector2(54, 0)
		caption.add_theme_font_size_override("font_size", 12)
		caption.add_theme_color_override("font_color", label_colour)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(caption)
		var share := clampf(float(growth.get(stat, 0.0)) / growth_ceiling(stat), 0.0, 1.0)
		var meter := bar(share, colour, track, Vector2(110, 9))
		meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meter.tooltip_text = "+%s %s a level" % [String.num(float(growth.get(stat, 0.0)), 1), str(pair[1]).to_lower()]
		grid.add_child(meter)
	return grid


## A plain filled bar from 0 to 1, rounded, in [param fill] over [param track].
static func bar(share: float, fill: Color, track: Color, size: Vector2) -> ProgressBar:
	var out := ProgressBar.new()
	out.custom_minimum_size = size
	out.max_value = 1.0
	out.step = 0.0
	out.value = clampf(share, 0.0, 1.0)
	out.show_percentage = false
	out.mouse_filter = Control.MOUSE_FILTER_PASS
	var front := StyleBoxFlat.new()
	front.bg_color = fill
	front.set_corner_radius_all(int(size.y / 2.0))
	var back := StyleBoxFlat.new()
	back.bg_color = track
	back.set_corner_radius_all(int(size.y / 2.0))
	out.add_theme_stylebox_override("fill", front)
	out.add_theme_stylebox_override("background", back)
	return out


## A rounded box: [param fill] with a [param border] of [param width].
static func box(fill: Color, border: Color, width: int = 1, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.anti_aliasing = true
	return style


## The skills a class hands over on the spot, by name.
static func grant_names(class_id: String) -> Array[String]:
	var out: Array[String] = []
	for ability_id: String in Database.character_class(class_id).get("grants", []):
		out.append(str(Database.ability(ability_id).get("display_name", ability_id)))
	return out


## The longer word on a path ([D237], `doug-md`, play-test 4: "include what each path is in greater
## detail, if you hover over a question mark"): what kind of fighter it makes, what it grows each
## level, what it starts with and what each of those does, and where its later powers come from.
## Built from the class's own numbers and moves, so it never says something the path does not do;
## the words are `data/world_rules.json` → `path_help`.
static func class_help(class_id: String) -> String:
	var rules: Dictionary = Database.world_rules.get("path_help", {})
	var said: Dictionary = rules.get("lines", {})
	var data := Database.character_class(class_id)
	var growth: Dictionary = data.get("growth", {})
	var parts: Array[String] = []
	var kinds: Array[String] = []
	for role: Dictionary in rules.get("roles", []):
		if _role_fits(role, growth, data.get("grants", [])):
			kinds.append(str(role.get("say", "")))
		if kinds.size() >= int(rules.get("most_roles", 3)):
			break
	if not kinds.is_empty():
		parts.append(" ".join(kinds))
	parts.append(str(said.get("grows", "")).format({
		"max_hp": String.num(float(growth.get("max_hp", 0)), 1).trim_suffix(".0"),
		"attack": String.num(float(growth.get("attack", 0)), 1).trim_suffix(".0"),
		"defense": String.num(float(growth.get("defense", 0)), 1).trim_suffix(".0"),
		"speed": String.num(float(growth.get("speed", 0)), 1).trim_suffix(".0"),
	}))
	var moves: Array[String] = []
	for ability_id: String in data.get("grants", []):
		var ability := Database.ability(ability_id)
		moves.append(str(said.get("move", "{name}: {text}")).format({
			"name": str(ability.get("display_name", ability_id)),
			"text": str(ability.get("description", "")),
		}))
	if not moves.is_empty():
		parts.append(str(said.get("starts", "")) + "\n" + "\n".join(moves))
	var themes := theme_names(class_id)
	if not themes.is_empty():
		parts.append(str(said.get("themes", "")).format({"themes": ", ".join(themes)}))
	return "\n\n".join(parts.filter(func(part: String) -> bool: return part.strip_edges() != ""))


## Whether a path is the kind a `path_help.roles` entry describes: every stat at least or at most
## what it names, and its moves including a heal or a shot from range when it asks.
static func _role_fits(role: Dictionary, growth: Dictionary, grants: Array) -> bool:
	var least: Dictionary = role.get("at_least", {})
	for stat: String in least:
		if float(growth.get(stat, 0.0)) < float(least[stat]):
			return false
	var most: Dictionary = role.get("at_most", {})
	for stat: String in most:
		if float(growth.get(stat, 0.0)) > float(most[stat]):
			return false
	var needs := str(role.get("has", ""))
	if needs == "":
		return true
	for ability_id: String in grants:
		var ability := Database.ability(ability_id)
		if needs == "heal" and bool(ability.get("heal", false)):
			return true
		if needs == "range" and str(ability.get("target", "")) == "enemy" and int(ability.get("min_range", 1)) >= 2:
			return true
	return false


static func theme_names(class_id: String) -> Array[String]:
	var out: Array[String] = []
	for theme: String in Database.character_class(class_id).get("themes", []):
		out.append(theme.capitalize())
	return out


## The numbers a level changes, as they stand now: what the banner compares
## against what they were the moment before ([signal EventBus.levelled_up]).
static func growth_snapshot(character: Character) -> Dictionary:
	return {
		"max_hp": character.max_hp(),
		"attack": character.attack(),
		"defense": character.defense(),
		"speed": character.speed(),
	}


## What went up between two snapshots, as `[label, before, after]`, in the
## order the growth bars use. Unchanged stats are left out.
static func gains(before: Dictionary, after: Dictionary) -> Array:
	var out: Array = []
	for pair: Array in GROWTH_STATS:
		var stat: String = pair[0]
		var was := int(before.get(stat, 0))
		var now := int(after.get(stat, 0))
		if now != was:
			out.append([pair[1], was, now])
	return out


## Range, splash and weight, said the way the command menu would say it.
static func ability_shape(ability: Dictionary) -> String:
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
