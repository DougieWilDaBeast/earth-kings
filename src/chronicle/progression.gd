class_name Progression
extends RefCounted
## Levels, classes and tree unlocks. Every character in the world grows the
## same way; what differs is the class they settle into and what the world
## happens to hand them.

## A main class is chosen once the character has proved they'll survive.
const CLASS_LEVEL := 2
const FIRST_TREE_LEVEL := 5
const SECOND_TREE_LEVEL := 10
## Health returned on a level-up, so growth feels like relief mid-delve.
const LEVEL_UP_HEAL := 8


static func xp_to_next(level: int) -> int:
	return 20 + level * level * 6


## XP a defeated character is worth to its killer.
static func bounty_for(level: int) -> int:
	return 9 + level * 7


## Give [param character] experience and apply every level-up it triggers.
## Returns human-readable lines for the battle log.
static func award(character: Character, amount: int, world: World) -> Array:
	var lines: Array = []
	if not character.is_alive() or amount <= 0:
		return lines

	var gained := amount
	if character.yoke:
		gained = roundi(gained * (1.0 + Character.YOKE_XP_BONUS))
	gained = Difficulty.scaled(gained, "xp")

	character.xp += gained
	while character.xp >= xp_to_next(character.level):
		character.xp -= xp_to_next(character.level)
		lines.append_array(_level_up(character, world))
	return lines


static func _level_up(character: Character, world: World) -> Array:
	var lines: Array = []
	character.level += 1
	if character.hp >= 0:
		character.hp = mini(character.hp + LEVEL_UP_HEAL, character.max_hp())
	lines.append("%s reaches level %d." % [character.display_name, character.level])

	if character.level == CLASS_LEVEL and character.class_id == "":
		if character.is_player:
			# The player picks; the world waits until they do.
			character.pending_class_choice = true
			lines.append("%s must choose a path." % character.display_name)
			EventBus.class_choice_required.emit(character)
		else:
			var chosen := choose_class(character, world.rng)
			if chosen != "":
				character.class_id = chosen
				lines.append("%s takes up the way of the %s." % [character.display_name, character.class_name_text()])

	if character.level == FIRST_TREE_LEVEL or character.level == SECOND_TREE_LEVEL:
		lines.append_array(unlock_tree(character, world))
	elif character.is_player:
		# The player is owed a power and decides where it goes.
		character.rungs += 1
		lines.append("%s has a power to take." % character.display_name)
	else:
		lines.append_array(learn_next(character, world))

	return lines


## Classes the character's template allows; empty means the grammar picks.
static func class_options(character: Character) -> Array:
	var options: Array = character.template().get("classes", [])
	return options if not options.is_empty() else Database.classes.keys()


static func choose_class(character: Character, rng: RandomNumberGenerator) -> String:
	var options := class_options(character)
	if options.is_empty():
		return ""
	return options[rng.randi() % options.size()]


## Commit the player's pick. Returns false if it wasn't one of their options.
static func settle_class(character: Character, class_id: String) -> bool:
	if class_id not in class_options(character):
		return false
	character.class_id = class_id
	character.pending_class_choice = false
	if GameState.world != null:
		Annals.record(GameState.world, "%s took up the way of the %s." % [character.display_name, character.class_name_text()])
	EventBus.class_chosen.emit(character)
	return true


## Discover a tree compatible with the character's class and take its first rung.
## [param theme] may be named once the Codex is complete — the world stops
## handing out powers and starts letting you ask for them.
static func unlock_tree(character: Character, world: World, theme: String = "") -> Array:
	var themes := AbilityGrammar.themes_for(character)
	if theme == "" or not can_craft(world):
		var existing_themes: Array = []
		for tid: String in character.trees:
			var t := world.tree(tid)
			if t.has("theme"):
				existing_themes.append(t["theme"])
		var unused := themes.filter(func(th: String) -> bool: return th not in existing_themes)
		var pool := unused if not unused.is_empty() else themes
		theme = pool[world.rng.randi() % pool.size()]
	var tree := AbilityGrammar.generate_tree(theme, world.rng, world.codex_understanding())
	world.register_tree(tree)
	character.trees.append(tree["id"])
	Annals.record(world, "%s uncovered %s." % [character.display_name, tree["display_name"]])
	var lines: Array = ["%s uncovers %s." % [character.display_name, tree["display_name"]]]
	if character.is_player:
		character.rungs += 1
		lines.append("%s has a power to take." % character.display_name)
	else:
		lines.append_array(learn_next(character, world))
	return lines


## The next unlearned rung of each tree they have uncovered — the choice in
## front of somebody with a power owed to them.
static func rung_options(character: Character, world: World) -> Array:
	var out: Array = []
	for tree_id: String in character.trees:
		for ability_id: String in world.tree(tree_id).get("abilities", []):
			if ability_id not in character.learned:
				out.append(ability_id)
				break
	return out


## Take one of them. Refuses anything that is not actually the next rung, so a
## stale button cannot skip up a tree.
static func spend_rung(character: Character, ability_id: String, world: World) -> bool:
	if character.rungs <= 0 or ability_id not in rung_options(character, world):
		return false
	character.rungs -= 1
	character.learned.append(ability_id)
	return true


## A fully catalogued grammar can be worked deliberately rather than stumbled into.
static func can_craft(world: World) -> bool:
	return world.codex_understanding() >= float(
		Database.world_rules.get("codex", {}).get("crafting_at", 1.0)
	)


## Take the next unlearned rung from any unlocked tree.
static func learn_next(character: Character, world: World) -> Array:
	for tree_id: String in character.trees:
		var tree := world.tree(tree_id)
		for ability_id: String in tree.get("abilities", []):
			if ability_id not in character.learned:
				character.learned.append(ability_id)
				var ability := Database.ability(ability_id)
				return ["%s learns %s." % [character.display_name, ability.get("display_name", ability_id)]]
	return []


## Bring a character up to [param target_level] at world generation time, without
## narrating any of it. Classes are settled immediately rather than queued.
static func raise_to(character: Character, target_level: int, world: World) -> void:
	while character.level < target_level:
		_level_up(character, world)
		if character.pending_class_choice:
			settle_class(character, choose_class(character, world.rng))
	character.hp = -1


## Scale a throwaway character — a wolf, a gate guardian — to a level without
## generating trees. Nothing spawned for one fight should leave powers behind in
## the world's permanent record.
static func raise_quietly(character: Character, target_level: int, world: World) -> void:
	character.level = maxi(1, target_level)
	if character.class_id == "" and character.level >= CLASS_LEVEL:
		character.class_id = choose_class(character, world.rng)
	character.hp = -1
