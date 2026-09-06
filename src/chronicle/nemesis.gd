class_name Nemesis
extends RefCounted
## Enemies who survived defeat, carried word of you, and return with a score to settle.
##
## When a company of foes is broken, there is a chance one wounded survivor crawls
## into the brush. Word of their defeat spreads outward as a deed; they take up an
## epithet, remember where you met, and may reappear in a roaming band with dialogue.

const SURVIVAL_CHANCE := 0.20
const NON_SENTIENT := [
	"slime", "blue_slime", "king_slime", "wolf", "ice_wolf",
	"blood_mosquito", "seed_beast", "turret_cannon"
]

const EPITHETS := [
	"the Scarred",
	"who Fled",
	"the Bitter",
	"One-Eye",
	"the Survivor",
	"who Remembered",
	"the Relentless"
]


static func on_battle_won(world: World, enemies: Array, cell: Vector2i) -> String:
	var candidates: Array = []
	for entry in enemies:
		var unit_id: String = entry.get("unit", "") if entry is Dictionary else str(entry)
		if unit_id != "" and unit_id not in NON_SENTIENT:
			candidates.append(unit_id)
	if candidates.is_empty():
		return ""
	if world.rng.randf() > SURVIVAL_CHANCE:
		return ""

	var chosen: String = candidates[world.rng.randi() % candidates.size()]
	var template := Database.unit_template(chosen)
	var base_name: String = template.get("display_name", chosen.capitalize())
	var epithet: String = EPITHETS[world.rng.randi() % EPITHETS.size()]
	var full_name := "%s %s" % [base_name, epithet]
	var place := _place_name(world, cell)

	var survivor := {
		"unit": chosen,
		"name": full_name,
		"cell": [cell.x, cell.y],
		"place": place,
		"steps": world.steps,
		"encounters": 1,
	}
	world.survivors.append(survivor)

	var lead := GameState.roster.player()
	var lead_name := lead.display_name if lead != null else "your company"
	Renown.record(
		world, "thread", cell, 2,
		"%s crawled alive from the clash near %s, speaking with dread of %s" % [
			full_name, place, lead_name
		]
	)
	Annals.record(world, "%s survived the carnage near %s and fled into the hills." % [full_name, place])
	return "One of them crawled off into the brush clutching a wound — %s will not forget this." % full_name


static func check_confrontation(world: World, meeting: Dictionary) -> String:
	for enemy in meeting.get("enemies", []):
		if bool(enemy.get("survivor", false)):
			var name_: String = str(enemy.get("name", "A scarred warrior"))
			var place: String = str(enemy.get("place", "the road"))
			return "%s draws steel with shaking hands: 'I survived your blades at %s... I swore I would never run twice!'" % [
				name_, place
			]
	return ""


static func inject_survivor(world: World, enemies: Array) -> void:
	if world.survivors.is_empty() or enemies.is_empty():
		return
	if world.rng.randf() > 0.45:
		return
	var survivor: Dictionary = world.survivors[world.rng.randi() % world.survivors.size()]
	enemies[0]["unit"] = survivor.get("unit", enemies[0].get("unit", "brigand"))
	enemies[0]["survivor"] = true
	enemies[0]["name"] = survivor.get("name", "The Survivor")
	enemies[0]["place"] = survivor.get("place", "an old battleground")


static func _place_name(world: World, cell: Vector2i) -> String:
	var site := world.site_at(cell)
	if site != null:
		return site.display_name
	return world.region_at(cell)
