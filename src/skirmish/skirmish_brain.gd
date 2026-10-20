extends RefCounted
## Deciding, not doing: who a fighter goes after, and which ready skill it would
## use on whom. Returns plans; only [Skirmish] changes the fight (the mind seam,
## [D03]). Every side thinks with it: the enemy, allies fighting beside the
## party, and the party itself when it is left to fight on its own.
##
## Enemy targeting is a fixed rule rather than a dice roll — Dungeon Settlers'
## players read random aggro as broken — and it never picks on the downed, so a
## fallen ally can still be reached in time.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const Formations := preload("res://src/skirmish/formations.gd")


## The foe [param fighter] should be swinging at. Keeps its current target while
## it is still worth hitting, so fighters do not flicker between two foes.
## [param reach] limits how far it will look; -1 means anywhere.
static func pick_target(fighter: Fighter, fighters: Array[Fighter], reach: int = -1) -> Unit:
	var current := fighter.target
	var keep := current != null and _standing(current, fighters) and current.is_hostile_to(fighter.unit) \
			and (reach < 0 or Pathfinder.distance(fighter.unit.cell, current.cell) <= reach)
	var tactics: Dictionary = Database.skirmish.get("tactics", {})
	var focus: Dictionary = doctrine(fighter, tactics).get("focus", {}) if bool(tactics.get("on", true)) else {}
	if keep and focus.is_empty():
		return current
	var best: Unit = null
	var best_score := INF
	for other in fighters:
		if not other.targetable() or not other.unit.is_hostile_to(fighter.unit):
			continue
		var distance := Pathfinder.distance(fighter.unit.cell, other.unit.cell)
		if reach >= 0 and distance > reach:
			continue
		# Nearest first; between two as near, the one closer to falling. A doctrine
		# with a focus will walk further for a foe worth it ([D187]).
		var score := float(distance) * 1000.0 + float(other.unit.hp) - _worth(other, focus) * 1000.0
		if keep and other.unit == current:
			score -= float(tactics.get("switch_margin", 1.5)) * 1000.0
		if score < best_score:
			best_score = score
			best = other.unit
	return best


## How many tiles of walking [param foe] is worth to a doctrine's [param focus].
static func _worth(foe: Fighter, focus: Dictionary) -> float:
	if focus.is_empty():
		return 0.0
	var worth := 0.0
	var share := float(foe.unit.hp) / float(maxi(1, foe.unit.max_hp))
	worth += float(focus.get("hurt", 0.0)) * (1.0 - share)
	if foe.marked > 0.0:
		worth += float(focus.get("marked", 0.0))
	if foe.heal_below > SkirmishRules.AUTO_HEAL_BELOW or int(Database.ability(foe.basic).get("range", 1)) > 1:
		worth += float(focus.get("soft", 0.0))
	return worth


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


## A fighter's way of fighting (`tactics` in `data/skirmish.json`, [D187]): which
## moves it tries and whom it would rather hit. From its lead, else its enemy
## role, else a brute's.
static func doctrine(fighter: Fighter, tactics: Dictionary) -> Dictionary:
	var name := str(tactics.get("leads", {}).get(fighter.unit.template_id, ""))
	if name == "" and fighter.role != "":
		name = str(tactics.get("roles", {}).get(fighter.role, ""))
	var doctrines: Dictionary = tactics.get("doctrines", {})
	return doctrines.get(name, doctrines.get("brute", {}))


## The moves [param fighter] tries, in order: its doctrine's, with the stance the player
## gave it ([D195]) putting its `first` moves ahead and leaving out its `drop` ones. A
## stance only reorders the doctrine and adds the move it names; no number changes.
static func moves(fighter: Fighter, tactics: Dictionary) -> Array:
	var own: Array = doctrine(fighter, tactics).get("moves", [])
	var stance := Fighter.stance_data(fighter.playing_stance())
	var first: Array = stance.get("first", [])
	# Called out ([D306]): while the shout lasts, getting clear comes before anything else.
	if fighter.warned > 0.0:
		first = (Formations.callout_rules().get("warned_first", []) as Array) + first
	if first.is_empty() and not stance.has("drop"):
		return own
	var drop: Array = stance.get("drop", [])
	var out: Array = first.duplicate()
	for move: String in own:
		if not out.has(move) and not drop.has(move):
			out.append(move)
	return out


## A move worth making instead of standing and swinging at [param foe]:
## `{"why", "goal", "wait", "target", "ally"}`, where goal is a test on a cell the
## fighter should be on (none for "hold", which means stay put), or empty. The
## doctrine's moves are tried in its order:
## - **dodge** a big wind-up about to land on it: out of its blast, or out of the
##   caster's reach when it is aimed at the fighter from close by (a skill aimed at
##   someone fizzles if they get away);
## - **kite**: a fighter whose swing reaches two tiles or more steps back from a foe
##   at its elbow, keeping that foe in reach;
## - **flank**: one who swings up close circles to the side or back of a foe facing
##   it, where every blow lands harder (1.1x, 1.2x), sooner with a passive for it;
## - **guard**: steps in beside a friend under half health and takes on whoever is
##   hitting them;
## - **hang back**: a healer with friends in front keeps out of reach, and does not
##   walk in to swing;
## - **break off**: under 30% health, with a friend still fighting, gets clear for a
##   few seconds (Catch Breath and its like mend out of the fighting).
## - **escort** (the Guard stance's): more than two tiles from the party's leader, it
##   makes its way back beside them.
## In the player's party ([D281]) two more hold for everyone: **rally**, tried first after
## dodge: when the lead is under half health with a foe on them, a companion within reach
## goes and stands between them, or comes back beside them; and **keep with the band**: no
## move takes a fighter further than `keep_with` tiles from every friend still standing,
## and nobody hangs back from a foe already hitting them.
static func pick_tactic(fighter: Fighter, fighters: Array[Fighter], foe: Unit, tactics: Dictionary) -> Dictionary:
	if not bool(tactics.get("on", true)) or fighter.aboard != null or foe == null:
		return {}
	var me := fighter.unit
	var swing := int(Database.ability(fighter.basic).get("range", 1))
	var away := foe.cell
	var friends := fighters.filter(func(o: Fighter) -> bool:
		return o != fighter and o.is_standing() and not o.unit.is_hostile_to(me))
	# The player's party keeps together round its lead ([D281]).
	var lead := _party_lead(fighter, friends) if bool(tactics.get("keep_together", true)) else null
	var banded := lead != null and not friends.is_empty()
	var keep := int(tactics.get("keep_with", 3))
	var with_band := func(c: Vector2i) -> bool:
		return not banded or friends.any(func(o: Fighter) -> bool: return Pathfinder.distance(c, o.unit.cell) <= keep)
	var hunted := fighters.any(func(o: Fighter) -> bool:
		return o.is_standing() and o.unit.is_hostile_to(me) and o.target == me and Pathfinder.distance(o.unit.cell, me.cell) <= 1)
	var tried: Array = moves(fighter, tactics).duplicate()
	if lead != null and lead != me:
		tried.insert(1 if tried.has("dodge") else 0, "rally")
		# And, when nothing else is called for, falls in to its slot round the lead until the party
		# is in contact ([D305]): last, so a stance's own moves (Guard's escort) come first.
		tried.append("form")
	for move: String in tried:
		var plan := {}
		match move:
			"dodge":
				plan = _dodge(fighter, fighters, tactics)
			"rally":
				if fighter.tactic_wait <= 0.0:
					plan = _rally(fighter, fighters, lead, tactics)
			"form":
				if fighter.tactic_wait <= 0.0 and not hunted:
					plan = _form(fighter, fighters)
			"kite":
				if fighter.tactic_wait <= 0.0 and swing >= int(tactics.get("kite_from_reach", 2)) \
						and fighter.retreat_wait <= 0.0 and _nearest_hostile(me, me.cell, fighters) <= 1:
					plan = {"why": "kite", "wait": float(tactics.get("kite_every", 2.5)), "goal": func(c: Vector2i) -> bool:
						return _nearest_hostile(me, c, fighters) >= 2 and Pathfinder.distance(c, away) <= swing \
								and _free(c, fighter, fighters) and with_band.call(c)}
			"flank":
				if fighter.tactic_wait <= 0.0 and swing == 1 and Pathfinder.distance(me.cell, away) == 1 \
						and AbilityResolver.flank_of(me.cell, foe) == AbilityResolver.Flank.FRONT:
					var keen := fighter.effect("flank_bonus") > 0.0
					plan = {"why": "flank", "wait": float(tactics.get("flank_every_keen" if keen else "flank_every", 2.5)),
						"goal": func(c: Vector2i) -> bool:
							return Pathfinder.distance(c, away) == 1 and AbilityResolver.flank_of(c, foe) != AbilityResolver.Flank.FRONT \
									and _free(c, fighter, fighters)}
			"guard":
				if fighter.tactic_wait <= 0.0:
					plan = _guard(fighter, fighters, friends, tactics)
			"hang_back":
				if not friends.is_empty() and friends.any(func(o: Fighter) -> bool: return o.target != null) \
						and not (banded and hunted):
					var gap := int(tactics.get("hang_back", 3))
					if _nearest_hostile(me, me.cell, fighters) < gap and fighter.tactic_wait <= 0.0:
						plan = {"why": "hang_back", "wait": 2.0, "goal": func(c: Vector2i) -> bool:
							return _nearest_hostile(me, c, fighters) >= gap and _free(c, fighter, fighters) and with_band.call(c)}
					elif not AbilityResolver.in_range(Database.ability(fighter.basic), me.cell, away):
						plan = {"why": "hold"}
			"escort":
				if fighter.tactic_wait <= 0.0:
					plan = _escort(fighter, fighters, friends, tactics)
			"break":
				var share := float(me.hp) / float(maxi(1, me.max_hp))
				if fighter.tactic_wait <= 0.0 and share < float(tactics.get("break_below", 0.3)) \
						and friends.any(func(o: Fighter) -> bool: return o.target != null):
					var to := int(tactics.get("break_to", 4))
					plan = {"why": "break", "wait": float(tactics.get("break_every", 8.0)), "goal": func(c: Vector2i) -> bool:
						return _nearest_hostile(me, c, fighters) >= to and _free(c, fighter, fighters) and with_band.call(c)}
		if not plan.is_empty():
			return plan
	return {}


static func _dodge(fighter: Fighter, fighters: Array[Fighter], tactics: Dictionary) -> Dictionary:
	var me := fighter.unit
	for other in fighters:
		if not other.is_casting() or not other.is_standing() or not other.unit.is_hostile_to(me):
			continue
		var cast: Dictionary = other.cast
		if float(cast["total"]) < float(tactics.get("dodge_from", 1.0)) \
				or float(cast["left"]) > float(tactics.get("dodge_window", 1.6)):
			continue
		var ability := other.slot_ability(int(cast["slot"]))
		var who: Unit = cast["target"]
		var area: Array = AbilityResolver.affected_cells(ability, who.cell if who != null else cast["cell"])
		if not area.has(me.cell):
			continue
		var caster := other.unit.cell
		var reach := int(ability.get("range", 1))
		if who == me and reach + 2 - Pathfinder.distance(me.cell, caster) <= 2:
			return {"why": "dodge", "wait": 0.0, "from": other, "goal": func(c: Vector2i) -> bool:
				return Pathfinder.distance(c, caster) > reach + 1 and _free(c, fighter, fighters)}
		if who != me:
			return {"why": "dodge", "wait": 0.0, "from": other, "goal": func(c: Vector2i) -> bool:
				return not area.has(c) and _free(c, fighter, fighters)}
	return {}


## The friend most in need of a body in front of them, and a cell beside both them
## and whoever is hitting them.
static func _guard(fighter: Fighter, fighters: Array[Fighter], friends: Array, tactics: Dictionary) -> Dictionary:
	var me := fighter.unit
	var below := float(tactics.get("guard_below", 0.5))
	var reach := int(tactics.get("guard_reach", 4))
	var worst: Fighter = null
	var worst_share := below
	for friend: Fighter in friends:
		var share := float(friend.unit.hp) / float(maxi(1, friend.unit.max_hp))
		# A friend the other side has called out ([D306]) needs a body in front of them now.
		if friend.warned > 0.0:
			share = 0.0
		if share >= worst_share or Pathfinder.distance(me.cell, friend.unit.cell) > reach:
			continue
		worst = friend
		worst_share = share
	if worst == null:
		return {}
	for other in fighters:
		if other.is_standing() and other.unit.is_hostile_to(me) and other.target == worst.unit \
				and Pathfinder.distance(other.unit.cell, worst.unit.cell) <= 1:
			var attacker := other.unit.cell
			var ward := worst.unit.cell
			if Pathfinder.distance(me.cell, attacker) == 1 and fighter.target == other.unit:
				return {}
			return {"why": "guard", "wait": float(tactics.get("guard_every", 3.0)), "target": other.unit,
				"ally": worst.unit.display_name, "goal": func(c: Vector2i) -> bool:
					return Pathfinder.distance(c, attacker) == 1 and Pathfinder.distance(c, ward) <= 2 \
							and _free(c, fighter, fighters)}
	return {}


## The player's lead, when [param fighter] is in the player's party (itself, if it is the lead); null
## for anyone else, so foes, allies of a fight and who-wins bouts fight as they always have.
static func _party_lead(fighter: Fighter, friends: Array) -> Unit:
	var me := fighter.unit
	if me.team != Unit.Team.PLAYER:
		return null
	if me.character != null and me.character.is_player:
		return me
	for friend: Fighter in friends:
		if friend.unit.team == Unit.Team.PLAYER and friend.unit.character != null and friend.unit.character.is_player:
			return friend.unit
	return null


## To the lead's side when they are under `rally_below` of their health with a foe on them
## ([D281]): between them and that foe, or beside them if nobody is at their elbow yet.
static func _rally(fighter: Fighter, fighters: Array[Fighter], lead: Unit, tactics: Dictionary) -> Dictionary:
	var me := fighter.unit
	var share := float(lead.hp) / float(maxi(1, lead.max_hp))
	if share >= float(tactics.get("rally_below", 0.5)) \
			or Pathfinder.distance(me.cell, lead.cell) > int(tactics.get("rally_reach", 8)):
		return {}
	var ward := lead.cell
	var every := float(tactics.get("rally_every", 2.0))
	for other in fighters:
		if other.is_standing() and other.unit.is_hostile_to(me) and other.target == lead \
				and Pathfinder.distance(other.unit.cell, ward) <= 1:
			var attacker := other.unit.cell
			if Pathfinder.distance(me.cell, attacker) == 1 and fighter.target == other.unit:
				return {}
			return {"why": "rally", "wait": every, "target": other.unit, "ally": lead.display_name,
				"goal": func(c: Vector2i) -> bool:
					return Pathfinder.distance(c, attacker) == 1 and Pathfinder.distance(c, ward) <= 2 \
							and _free(c, fighter, fighters)}
	if Pathfinder.distance(me.cell, ward) <= 2:
		return {}
	return {"why": "rally", "wait": every, "ally": lead.display_name, "goal": func(c: Vector2i) -> bool:
		return Pathfinder.distance(c, ward) <= 2 and _free(c, fighter, fighters)}


## To its slot in the party's formation ([D289], [D305]), while nobody of the party is in contact
## with a foe: the party walks up in its shape and breaks into its doctrines once the fight is joined.
static func _form(fighter: Fighter, fighters: Array[Fighter]) -> Dictionary:
	var slot := Formations.slot_cell(fighter, fighters)
	if slot == Formations.NONE or Formations.in_contact(fighters):
		return {}
	var slack := int(Formations.rules().get("slack", 1))
	if Pathfinder.distance(fighter.unit.cell, slot) <= slack:
		return {}
	return {"why": "form", "wait": float(Formations.rules().get("form_every", 1.5)), "goal": func(c: Vector2i) -> bool:
		return Pathfinder.distance(c, slot) <= slack and _free(c, fighter, fighters)}


## Back beside the party's leader, when this fighter is not the leader and has drifted
## more than `escort_reach` tiles from them.
static func _escort(fighter: Fighter, fighters: Array[Fighter], friends: Array, tactics: Dictionary) -> Dictionary:
	var me := fighter.unit
	if me.character != null and me.character.is_player:
		return {}
	var reach := int(tactics.get("escort_reach", 2))
	for friend: Fighter in friends:
		var ward := friend.unit
		if ward.character == null or not ward.character.is_player:
			continue
		if Pathfinder.distance(me.cell, ward.cell) <= reach:
			return {}
		var at := ward.cell
		return {"why": "escort", "wait": float(tactics.get("escort_every", 2.0)), "ally": ward.display_name,
			"goal": func(c: Vector2i) -> bool:
				return Pathfinder.distance(c, at) <= reach and _free(c, fighter, fighters)}
	return {}


## Nobody else standing there (the fighter itself does not count).
static func _free(cell: Vector2i, fighter: Fighter, fighters: Array[Fighter]) -> bool:
	for other in fighters:
		if other != fighter and not other.fallen and not other.fled and other.aboard == null and other.unit.cell == cell:
			return false
	return true


static func _nearest_hostile(me: Unit, cell: Vector2i, fighters: Array[Fighter]) -> int:
	var best := 999
	for other in fighters:
		if other.is_standing() and other.unit.is_hostile_to(me):
			best = mini(best, Pathfinder.distance(cell, other.unit.cell))
	return best


static func _skill_target(fighter: Fighter, ability: Dictionary, fighters: Array[Fighter]) -> Unit:
	var me := fighter.unit
	if str(ability.get("target", "enemy")) == "self":
		return me if me.hp < me.max_hp else null
	if SkirmishRules.is_support(ability):
		var neediest: Unit = null
		var lowest := fighter.heal_below
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
	# A stun is kept for somebody winding up a spell, where it breaks the cast (D59).
	if float(ability.get("stun", 0.0)) > 0.0:
		for other in fighters:
			if other.is_casting() and other.aboard == null and _in_reach(me, ability, other.unit, fighters):
				return other.unit
		return null
	# Offence: the current target if the skill reaches it, else anyone it does.
	if fighter.target != null and _in_reach(me, ability, fighter.target, fighters):
		return fighter.target
	for other in fighters:
		if other.targetable() and _in_reach(me, ability, other.unit, fighters):
			return other.unit
	return null


static func _in_reach(me: Unit, ability: Dictionary, who: Unit, fighters: Array[Fighter]) -> bool:
	return _standing(who, fighters) and AbilityResolver.is_valid_target(me, ability, who) \
			and AbilityResolver.in_range(ability, me.cell, who.cell)


static func _standing(who: Unit, fighters: Array[Fighter]) -> bool:
	for other in fighters:
		if other.unit == who:
			return other.targetable()
	return false
