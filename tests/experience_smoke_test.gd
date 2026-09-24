extends Node
## Headless smoke test for getting stronger the new way — M12, [D37].
##
##   godot --headless --path . res://tests/experience_smoke_test.tscn
##
## Experience comes only from the first kill of each kind of enemy, per
## character; assists add up to the same; a boss teaches everyone involved; and
## skill with a weapon grows by using it. Done when killing the same enemy twice
## gives experience once, and a soak shows levels rising only as the party meets
## new things.

var _failures: Array[String] = []


func _ready() -> void:
	GameState.new_game(1)
	var world: World = GameState.world
	var party := GameState.party_characters()
	_expect(party.size() >= 3, "the starting party should have three people")
	if party.size() < 3:
		_finish()
		return
	var killer: Character = party[0]
	var helper: Character = party[1]
	var healer: Character = party[2]

	# The first of a kind teaches; the second does not.
	var before := _total_xp(killer)
	Progression.award_kill(killer, "brigand", 3, [], false, world)
	var first := _total_xp(killer) - before
	# The difficulty setting scales every award (Gentle is 5x), so expect that too.
	var expected := Difficulty.scaled(Progression.first_kill_xp(3), "xp")
	_expect(first == expected, "a first kill paid %d, expected %d" % [first, expected])
	_expect(Progression.has_beaten(killer, "brigand"), "the kill was not written down")
	before = _total_xp(killer)
	Progression.award_kill(killer, "brigand", 9, [], false, world)
	_expect(_total_xp(killer) == before, "a second brigand still taught something")

	# Assists add up to one kill's worth, and not before.
	before = _total_xp(helper)
	for i in Progression.assists_needed() - 1:
		Progression.award_kill(killer, "wolf", 2, [helper], false, world)
	_expect(_total_xp(helper) == before, "an assist paid before there were enough of them")
	_expect(int(helper.assists.get("wolf", 0)) == Progression.assists_needed() - 1, "assists were not counted")
	Progression.award_kill(killer, "wolf", 2, [helper], false, world)
	_expect(_total_xp(helper) > before, "enough assists never taught anything")
	_expect(Progression.has_beaten(helper, "wolf") and not helper.assists.has("wolf"), "assists were not settled into a kill")

	# A boss teaches everyone involved, at once.
	var boss_kind := "dirte"
	var healer_before := _total_xp(healer)
	Progression.award_kill(killer, boss_kind, 12, [helper, healer], true, world)
	_expect(_total_xp(healer) > healer_before, "a boss did not teach someone who was there")
	_expect(Progression.has_beaten(healer, boss_kind), "a boss kill was not written down for everyone")

	# Skill with a weapon grows by using it, and shows in how hard it hits.
	var plain := Proficiency.multiplier(killer, "strike")
	var kind := Proficiency.arms_kind(killer)
	for i in int(Proficiency.arms_steps()[0]):
		Proficiency.record(killer, "strike")
	_expect(Proficiency.arms_rank(killer, kind) >= 1, "%d blows with a %s taught nothing" % [Proficiency.arms_steps()[0], kind])
	_expect(Proficiency.multiplier(killer, "strike") > plain, "practice did not make the strike hit harder")

	# All of it travels in the save.
	var copy := Character.from_dict(killer.to_dict())
	_expect(copy.beaten == killer.beaten, "kinds beaten were lost in the save")
	_expect(copy.arms == killer.arms, "weapon skill was lost in the save")
	var helper_copy := Character.from_dict(helper.to_dict())
	helper.assists["goblin"] = 2
	helper_copy = Character.from_dict(helper.to_dict())
	_expect(int(helper_copy.assists.get("goblin", 0)) == 2, "assists were lost in the save")

	_soak(world)
	_finish()


## A fresh character fights the same thing forty times, then forty different
## things. Only the second half should move them.
func _soak(world: World) -> void:
	var fighter := Character.create("sworn_blade")
	var start := fighter.level
	# The first goblin teaches; the next thirty-nine must not.
	Progression.award_kill(fighter, "goblin", 2, [], false, world)
	var after_first := fighter.level
	var xp_after_first := fighter.xp
	for i in 39:
		Progression.award_kill(fighter, "goblin", 2, [], false, world)
	var after_same := fighter.level
	var xp_after_same := fighter.xp
	var kinds: Array = Database.units.keys()
	var met := 0
	for kind: String in kinds:
		if met == 40:
			break
		if kind == "goblin":
			continue
		Progression.award_kill(fighter, kind, 2, [], false, world)
		met += 1
	print("soak (%s difficulty): level %d at the start, %d after one goblin, %d after forty goblins, %d after forty kinds" % [
		Difficulty.current(), start, after_first, after_same, fighter.level,
	])
	_expect(after_same == after_first and xp_after_same == xp_after_first,
			"thirty-nine more goblins changed a level (%d to %d)" % [after_first, after_same])
	_expect(fighter.level > after_same, "meeting new kinds did not raise a level")


## Experience ever earned, counting what went into levels already taken.
func _total_xp(character: Character) -> int:
	var total := character.xp
	for level in range(1, character.level):
		total += Progression.xp_to_next(level)
	return total


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("experience smoke test: PASS")
		get_tree().quit(0)
		return
	for failure in _failures:
		print("FAIL  %s" % failure)
	print("experience smoke test: FAIL")
	get_tree().quit(1)
