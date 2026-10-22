extends RefCounted
## Hunger ([D331], call BX; Ewan's play-test 8: "a hunger bar underneath every player so we know how
## much food they have currently in them and when they need to eat", and "on auto mode, characters
## are able to eat food... when needed").
##
## Everyone in the company has `fed`, from 1 (full) to 0 (empty), going down `per_step` with every
## step the world takes. Under `hungry_below` they are hungry (an amber bar under their health on
## the walking panel, and an alert); at nothing they are starving and lose `starving_hurt` of their
## health a step, never the last of it. Food (`taken: "eat"`) fills them by `feeds_per_mend` for
## every point it mends, and can be eaten whole or hurt; a rest in a bed is a meal too. A party
## playing itself eats the least food that will do when one of them is under `auto_eat_below`.
##
## Words and numbers are `world_rules.json` → `hunger`. Loaded by path ([D41]).


static func rules() -> Dictionary:
	return Database.world_rules.get("hunger", {})


static func on() -> bool:
	return bool(rules().get("on", false))


## What one piece of food fills, as a share of a whole belly.
static func feeds(equipment_id: String) -> float:
	if Gear.taken(equipment_id) != "eat":
		return 0.0
	return float(Gear.mends(equipment_id)) * float(rules().get("feeds_per_mend", 0.04))


static func is_hungry(character: Character) -> bool:
	return on() and character.fed < float(rules().get("hungry_below", 0.35))


## Bring everyone up to the world's step: emptier, and hurt if starving; Auto eats if it must.
## Safe to call any number of times a step. Returns the lines worth saying.
static func tick(world: World, roster: Roster) -> Array[String]:
	var lines: Array[String] = []
	if not on() or world == null or roster == null:
		return lines
	var per_step := float(rules().get("per_step", 0.004))
	for character: Character in roster.party_members():
		if not character.is_available():
			character.fed_step = world.steps
			continue
		if character.fed_step < 0:
			character.fed_step = world.steps
		var steps := world.steps - character.fed_step
		if steps <= 0:
			continue
		character.fed_step = world.steps
		var was_hungry := is_hungry(character)
		character.fed = maxf(0.0, character.fed - per_step * steps)
		if character.fed <= 0.0:
			var hurt := maxi(1, roundi(float(character.max_hp()) * float(rules().get("starving_hurt", 0.02)) * steps))
			character.hp = maxi(1, character.current_hp() - hurt)
		if Pace.auto and character.fed < float(rules().get("auto_eat_below", 0.4)):
			var line := eat_least(character)
			if line != "":
				lines.append(line)
				continue
		if is_hungry(character) and not was_hungry:
			lines.append(str(rules().get("hungry_line", "{name} is hungry.")).format({"name": character.display_name}))
	return lines


## The world's steps a Tower floor takes ([D400]) are not steps the company goes hungry in: each one's
## clock moves on with the world's, so nobody comes up a stair starving with no chance to eat between.
## Before, one floor (30 steps) ate three quarters of a full belly and, once empty, nine tenths of
## everyone's health in one blow (`tower_floor_counts` brings it back).
static func pass_over(world: World, roster: Roster, steps: int) -> void:
	if not on() or world == null or roster == null or steps <= 0 or bool(rules().get("tower_floor_counts", false)):
		return
	for character: Character in roster.party_members():
		if character.fed_step >= 0:
			character.fed_step += steps


## [param character] eats the least food in the packs that fills them. Returns the line, or "".
static func eat_least(character: Character) -> String:
	var food: Array = Gear.draughts().filter(func(id: String) -> bool: return feeds(id) > 0.0)
	if food.is_empty():
		return ""
	return eat(character, str(food[0]))


## Eat one piece of food from the packs ([method Gear.drink] fills them as it mends). Returns the line, or "".
static func eat(character: Character, equipment_id: String) -> String:
	if feeds(equipment_id) <= 0.0:
		return ""
	return Gear.drink(character, equipment_id)


## A bed is a meal too.
static func fill(character: Character) -> void:
	character.fed = 1.0
