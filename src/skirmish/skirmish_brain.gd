class_name SkirmishBrain
extends RefCounted
## Deciding, not doing: who a fighter goes after, and which ready skill it would
## use on whom. Returns plans; only [Skirmish] changes the fight (the mind seam,
## [D03]), exactly as [EnemyBrain] does for the turn-based battle.
##
## Enemy targeting is a fixed rule rather than a dice roll — Dungeon Settlers'
## players read random aggro as broken — and it never picks on the downed, so a
## fallen ally can still be reached in time.


## The foe [param fighter] should be swinging at. Keeps its current target while
## it is still worth hitting, so fighters do not flicker between two foes.
## [param reach] limits how far it will look; -1 means anywhere.
static func pick_target(fighter: Fighter, fighters: Array[Fighter], reach: int = -1) -> Unit:
	var current := fighter.target
	if current != null and _standing(current, fighters) and current.is_hostile_to(fighter.unit):
		if reach < 0 or Pathfinder.distance(fighter.unit.cell, current.cell) <= reach:
			return current
	var best: Unit = null
	var best_score := INF
	for other in fighters:
		if not other.is_standing() or not other.unit.is_hostile_to(fighter.unit):
			continue
		var distance := Pathfinder.distance(fighter.unit.cell, other.unit.cell)
		if reach >= 0 and distance > reach:
			continue
		# Nearest first; between two as near, the one closer to falling.
		var score := float(distance) * 1000.0 + float(other.unit.hp)
		if score < best_score:
			best_score = score
			best = other.unit
	return best


## The first ready slot, left to right, that has a use right now from where the
## fighter stands: {"slot": int, "target": Unit} or empty. Nothing here walks —
## an automatic skill is one that is already in reach.
static func pick_skill(fighter: Fighter, fighters: Array[Fighter]) -> Dictionary:
	for slot in fighter.slots.size():
		if not fighter.slot_ready(slot):
			continue
		var ability := fighter.slot_ability(slot)
		var who := _skill_target(fighter, ability, fighters)
		if who != null:
			return {"slot": slot, "target": who}
	return {}


static func _skill_target(fighter: Fighter, ability: Dictionary, fighters: Array[Fighter]) -> Unit:
	var me := fighter.unit
	if str(ability.get("target", "enemy")) == "self":
		return me if me.hp < me.max_hp else null
	if SkirmishRules.is_support(ability):
		var neediest: Unit = null
		var lowest := SkirmishRules.AUTO_HEAL_BELOW
		for other in fighters:
			if not other.is_standing() or other.unit.is_hostile_to(me):
				continue
			if not AbilityResolver.is_valid_target(me, ability, other.unit):
				continue
			if not AbilityResolver.in_range(ability, me.cell, other.unit.cell) and other.unit != me:
				continue
			var share := float(other.unit.hp) / float(maxi(1, other.unit.max_hp))
			if share <= lowest:
				lowest = share
				neediest = other.unit
		return neediest
	# Offence: the current target if the skill reaches it, else anyone it does.
	if fighter.target != null and _in_reach(me, ability, fighter.target, fighters):
		return fighter.target
	for other in fighters:
		if other.is_standing() and _in_reach(me, ability, other.unit, fighters):
			return other.unit
	return null


static func _in_reach(me: Unit, ability: Dictionary, who: Unit, fighters: Array[Fighter]) -> bool:
	return _standing(who, fighters) and AbilityResolver.is_valid_target(me, ability, who) \
			and AbilityResolver.in_range(ability, me.cell, who.cell)


static func _standing(who: Unit, fighters: Array[Fighter]) -> bool:
	for other in fighters:
		if other.unit == who:
			return other.is_standing()
	return false
