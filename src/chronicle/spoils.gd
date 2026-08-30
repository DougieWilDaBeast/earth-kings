class_name Spoils
extends RefCounted
## What the world gives back: floor rewards, gate payouts, and the odd book.

static func tower_rules() -> Dictionary:
	return Database.world_rules.get("tower", {})


## Paid on reaching a floor. Returns lines for the log.
static func for_tower_floor(world: World, floor_number: int, party: Array) -> Array:
	var rules := tower_rules()
	var lines: Array = []

	var gold := Difficulty.scaled(int(rules.get("gold_per_floor", 35)) * floor_number, "gold")
	GameState.gold += gold
	lines.append("Floor %d yields %d gold." % [floor_number, gold])

	var every_doctrine := int(rules.get("doctrine_every", 3))
	if every_doctrine > 0 and floor_number % every_doctrine == 0 and not party.is_empty():
		lines.append_array(_grant_doctrine(world, party))

	var every_tree := int(rules.get("tree_every", 4))
	if every_tree > 0 and floor_number % every_tree == 0 and not party.is_empty():
		var finder: Character = party[world.rng.randi() % party.size()]
		lines.append_array(Progression.unlock_tree(finder, world))

	return lines


## Paid for shutting a gate for good.
static func for_gate(world: World, site: Site, party: Array) -> Array:
	var lines: Array = []
	var gold := Difficulty.scaled(40 * (Site.rank_index(site.rank) + 1), "gold")
	GameState.gold += gold
	lines.append("%s is shut. %d gold recovered." % [site.display_name, gold])

	Renown.record(
		world, Renown.GATE_SHUT, site.cell,
		int(Renown.rules().get("gate_shut", 2)) * (Site.rank_index(site.rank) + 1),
		"the %s-rank gate at %s was shut" % [site.rank, site.display_name]
	)

	# The harder the gate, the likelier something written was behind it.
	var chance := 0.2 + 0.12 * float(Site.rank_index(site.rank))
	if not party.is_empty() and world.rng.randf() < chance:
		lines.append_array(_grant_doctrine(world, party))
	return lines


static func _grant_doctrine(world: World, party: Array) -> Array:
	var unknown: Array = []
	for doctrine_id: String in Database.doctrine_ids():
		for character: Character in party:
			if not character.knows(doctrine_id):
				unknown.append([doctrine_id, character])
				break
	if unknown.is_empty():
		return []

	var pick: Array = unknown[world.rng.randi() % unknown.size()]
	var reader: Character = pick[1]
	Doctrine.learn(reader, pick[0], world.steps)
	return ["%s finds %s and reads it." % [reader.display_name, Doctrine.title(pick[0])]]
