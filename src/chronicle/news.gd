class_name News
extends RefCounted
## Tidings and rumours of the realm: gathers active continental events
## (sieges, fallen towns, broken gates, nemeses abroad, active seasons, trade routes)
## into living dispatches that NPCs share at hearths and taverns.
##
## This brings Wishlist W30 ("Living world — news at a hearth, word arriving
## from somewhere you have not been") into direct play.


## Gathers all currently active news items from the world state.
static func dispatches(world: World) -> Array[String]:
	if world == null:
		return []
	var pool: Array[String] = []

	# 1. Sieges underway
	for site: Site in world.sites:
		if Town.is_threatened(site):
			var foe: String = str(site.data.get("threatened_by", "raiders"))
			pool.append("Distant bells toll for %s — horrors out of %s have laid siege to the palisades." % [
				site.display_name, foe
			])

	# 2. Ruined or sacked settlements
	for site: Site in world.sites:
		if Town.is_ruined(site):
			pool.append("%s lies desolate, sacked and abandoned to the crows." % site.display_name)

	# 3. Broken gates pouring monsters out
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.open and site.broken:
			pool.append("Scouts rode in pale: the ancient wards of %s have shattered, and dark things stalk the highways." % site.display_name)

	# 4. Nemesis survivors abroad
	if world.survivors.size() > 0:
		var nemesis: Dictionary = world.survivors[randi() % world.survivors.size()]
		var n_name: String = str(nemesis.get("name", "A scarred survivor"))
		var n_place: String = str(nemesis.get("place", "the frontier"))
		pool.append("Whispers in the taprooms: %s survived the battle near %s and is rallying cutthroats in the hills." % [
			n_name, n_place
		])

	# 5. Active seasonal state
	var season_data := Season.current(world)
	var left := Season.steps_remaining(world)
	pool.append("The elders mark %s under the %s; %d leagues remain before the weather turns." % [
		Season.label(world), season_data.get("clover_name", "the clover"), left
	])

	# 6. Commercial trade routes
	if not world.routes.is_empty():
		pool.append("Caravan wagons are rolling: %d active trade routes are bringing silver and grain into regional markets." % world.routes.size())

	# 7. S-Rank sealed gates
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.rank == "S" and not Ward.is_site_open(site):
			pool.append("The Dread Arch of %s in the far wastes remains bound in ancient rime, awaiting a key or flame." % site.display_name)
			break

	# 8. Spire progress
	if world.tower_floor > 0:
		pool.append("Delvers whisper that boots have reached floor %d of the Spire." % world.tower_floor)
	else:
		pool.append("The Spire stands silent against the grey sky. No champion has dared its stairs this season.")

	return pool


## Produces an in-character spoken report for an NPC sharing news at a tavern,
## inn, or keep.
static func tidings_for_inn(world: World, speaker_name: String = "") -> String:
	if world == null:
		return "The roads are quiet, and travelers bring little word."
	var items := dispatches(world)
	if items.is_empty():
		return "The roads are quiet this season. Little word has come down from the high passes."

	# Pick up to 3 distinct tidings
	var chosen: Array[String] = []
	var pool := items.duplicate()
	pool.shuffle()
	for i in range(mini(3, pool.size())):
		chosen.append(pool[i])

	var lead := "Word travels along the post-roads, if you know whose ear to catch:\n\n"
	var bullets: Array[String] = []
	for item in chosen:
		bullets.append("• \"%s\"" % item)
	return lead + "\n\n".join(bullets)
