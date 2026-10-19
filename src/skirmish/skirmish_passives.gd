extends RefCounted
## What a fighter brings to the real-time fight without pressing anything: its
## passives, and for an enemy, the way it likes to fight (its role). All of it
## is read from `data/skirmish.json`; this only works out who gets what.
##
## A unit's passives come, in order, from its template, its classes, and the
## abilities it knows, capped at `rules.max_passives`. An enemy's role is named
## for its template, else read off what it carries (a heal for an ally makes a
## mender, a reach of three or more a skirmisher), else named for its kind.
## A role with nothing but a name (the brawler) fights as everyone always has.


static func rule(key: String, fallback: float) -> float:
	return float(Database.skirmish.get("rules", {}).get(key, fallback))


static func passive(id: String) -> Dictionary:
	var entry: Dictionary = Database.skirmish.get("passives", {}).get(id, {})
	if entry.is_empty():
		return {}
	var out := entry.duplicate(true)
	out["id"] = id
	return out


static func for_unit(unit: Unit) -> Array:
	var data := Database.skirmish
	var ids: Array[String] = []
	_add(ids, data.get("by_template", {}).get(unit.template_id, data.get("by_template", {}).get(_family(unit), [])))
	_add(ids, data.get("by_tier", {}).get(_tier_key(unit), {}).get("passives", []))
	var classes: Array = []
	if unit.character != null and unit.character.class_id != "":
		classes.append(unit.character.class_id)
	for class_id: String in Database.unit_template(unit.template_id).get("classes", []):
		if not classes.has(class_id):
			classes.append(class_id)
	for class_id: String in classes:
		_add(ids, data.get("by_class", {}).get(class_id, []))
	for ability_id: String in unit.abilities:
		_add(ids, data.get("by_ability", {}).get(ability_id, []))
	var cap := int(rule("max_passives", 3))
	var out: Array = []
	for id in ids:
		var entry := passive(id)
		if not entry.is_empty():
			out.append(entry)
		if out.size() >= cap:
			break
	return out


static func _add(ids: Array[String], more: Array) -> void:
	for id: String in more:
		if not ids.has(id):
			ids.append(id)


## Carries a shield: a class, or an ability, listed under `shield_bearers` (D59).
static func bears_shield(unit: Unit) -> bool:
	var bearers: Dictionary = Database.skirmish.get("shield_bearers", {})
	if (bearers.get("by_template", []) as Array).has(unit.template_id):
		return true
	var classes: Array = Database.unit_template(unit.template_id).get("classes", []).duplicate()
	if unit.character != null and unit.character.class_id != "":
		classes.append(unit.character.class_id)
	for class_id in classes:
		if (bearers.get("by_class", []) as Array).has(class_id):
			return true
	for ability_id in unit.abilities:
		if (bearers.get("by_ability", []) as Array).has(ability_id):
			return true
	return false


## The role an enemy fights in, or "" for one that simply walks up and swings.
static func role_for(unit: Unit) -> String:
	var data := Database.skirmish
	var named := str(data.get("role_by_template", {}).get(unit.template_id, data.get("role_by_template", {}).get(_family(unit), "")))
	if named != "":
		return named
	var by_tier := str(data.get("by_tier", {}).get(_tier_key(unit), {}).get("role", ""))
	if by_tier != "":
		return by_tier
	for ability_id: String in unit.abilities:
		var ability := Database.ability(ability_id)
		if bool(ability.get("heal", false)) and not bool(ability.get("bonus", false)) \
				and str(ability.get("target", "")) == "ally" and int(ability.get("range", 0)) >= 2:
			return str(data.get("healer_role", ""))
	for ability_id: String in unit.abilities:
		var ability := Database.ability(ability_id)
		if str(ability.get("target", "enemy")) == "enemy" and not bool(ability.get("heal", false)):
			if int(ability.get("range", 1)) >= 3:
				return str(data.get("ranged_role", ""))
			break
	return str(data.get("role_by_kind", {}).get(unit.kind(), ""))


static func role(id: String) -> Dictionary:
	return Database.skirmish.get("roles", {}).get(id, {})


## The family a tier of a monster belongs to (D262): its passives and role are its family's unless it
## has its own.
static func _family(unit: Unit) -> String:
	return str(Database.unit_template(unit.template_id).get("family", ""))


## Which row of `by_tier` a tier of a monster fights by (D275): its tier, 1 to 5, and the top's caster
## (the second of the top's kinds) as "5_caster". "" for a unit that is no tier of anything.
static func _tier_key(unit: Unit) -> String:
	var template := Database.unit_template(unit.template_id)
	var tier := int(template.get("tier", 0))
	if tier <= 0:
		return ""
	var line: Array = Tiers.kinds(str(template.get("family", "")))
	if tier == line.size() and line.back() is Array and (line.back() as Array).find(unit.template_id) > 0:
		return "%d_caster" % tier
	return str(tier)
