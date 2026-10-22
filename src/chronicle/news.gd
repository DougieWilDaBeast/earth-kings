class_name News
extends RefCounted
## Tidings and rumours of the realm: gathers active continental events
## (sieges, fallen towns, broken gates, nemeses abroad, active seasons, trade routes)
## into living dispatches that NPCs share at hearths and taverns.
##
## This brings Wishlist W30 ("Living world — news at a hearth, word arriving
## from somewhere you have not been") into direct play.

## Loaded by path ([D41]).
const Atlas := preload("res://src/chronicle/atlas.gd")
const Fall := preload("res://src/chronicle/fall.gd")


## News travels at the speed of people ([D365]; `doug-md`'s play-test 2 ask, [D118]): word of what
## happened walks out from where it happened as a deed's does ([Renown]: `renown.steps_per_tile`), so
## a town three days off has not heard yet. The rules are `world_rules.json` → `news`.
static func rules() -> Dictionary:
	return Database.world_rules.get("news", {})


## Whether word from [param from], set off at step [param since], has walked to [param at] by now.
static func has_reached(world: World, from: Vector2i, since: int, at: Vector2i) -> bool:
	return Pathfinder.distance(from, at) <= int(world.steps - since) / Renown.steps_per_tile()


## Something that happened at [param cell], for the company to hear: said at once when it is near
## enough to be heard (`heard_at_once_tiles`, bells and smoke), else sent on its way and said when the
## word reaches the company ([method arriving]). [param line] may hold `{apart}` and `{way}`, filled in
## from wherever the company is when it hears.
static func send(world: World, line: String, cell: Vector2i) -> Array:
	if Pathfinder.distance(cell, world.player_cell) <= int(rules().get("heard_at_once_tiles", 6)):
		return [_said(world, line, cell)]
	world.word.append({ "line": line, "cell": [cell.x, cell.y], "step": world.steps })
	return []


## The word that has reached the company since it was last asked, oldest first, each said once.
static func arriving(world: World) -> Array:
	var out: Array = []
	var still: Array = []
	for each: Dictionary in world.word:
		var pair: Array = each.get("cell", [0, 0])
		var cell := Vector2i(int(pair[0]), int(pair[1]))
		if has_reached(world, cell, int(each.get("step", 0)), world.player_cell):
			out.append(str(rules().get("word_reaches", "{line}")).format({ "line": _said(world, str(each.get("line", "")), cell) }))
		else:
			still.append(each)
	world.word = still
	return out


static func _said(world: World, line: String, cell: Vector2i) -> String:
	var apart := absi(cell.x - world.player_cell.x) + absi(cell.y - world.player_cell.y)
	return line.format({ "apart": apart, "way": Fall.way(world.player_cell, cell) })


## Gathers the news items whose word has reached [param at] (the company's cell when left out).
static func dispatches(world: World, at: Vector2i = Vector2i(-1, -1)) -> Array[String]:
	if world == null:
		return []
	if at.x < 0:
		at = world.player_cell
	var pool: Array[String] = []

	# 1. Sieges underway
	for site: Site in world.sites:
		if Town.is_threatened(site) and has_reached(world, site.cell, int(site.data.get("threatened_at", 0)), at):
			var foe: String = str(site.data.get("threatened_by", "raiders"))
			pool.append("Distant bells toll for %s — horrors out of %s have laid siege to the palisades." % [
				site.display_name, foe
			])

	# 2. Ruined or sacked settlements
	for site: Site in world.sites:
		if Town.is_ruined(site) and has_reached(world, site.cell, int(site.data.get("sacked_at", 0)), at):
			pool.append("%s lies desolate, sacked and abandoned to the crows." % site.display_name)

	# 3. Broken gates pouring monsters out
	for site: Site in world.sites_of_kind(Site.GATE):
		if site.open and site.broken and has_reached(world, site.cell, int(site.data.get("broken_at", 0)), at):
			pool.append("Scouts rode in pale: the ancient wards of %s have shattered, and dark things stalk the highways." % site.display_name)

	# 4. Nemesis survivors abroad
	var heard_of: Array = world.survivors.filter(func(each: Dictionary) -> bool:
		var pair: Array = each.get("cell", [at.x, at.y])
		return has_reached(world, Vector2i(int(pair[0]), int(pair[1])), int(each.get("steps", 0)), at))
	if heard_of.size() > 0:
		var nemesis: Dictionary = heard_of[randi() % heard_of.size()]
		var n_name: String = str(nemesis.get("name", "A scarred survivor"))
		var n_place: String = str(nemesis.get("place", "the frontier"))
		pool.append("Whispers in the taprooms: %s survived the battle near %s and is rallying cutthroats in the hills." % [
			n_name, n_place
		])

	# 5. Active seasonal state (hidden for the First Hour, D97)
	if not FirstHour.hides("seasons"):
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

	# 8. Spire progress, as far as word of it has come down (the floor before, until the newest's has)
	var tower := world.tower()
	var floor_heard := world.tower_floor
	if tower != null and floor_heard > 0 and not has_reached(world, tower.cell, int(tower.data.get("floor_at", 0)), at):
		floor_heard = int(tower.data.get("floor_before", 0))
	if floor_heard > 0:
		pool.append("Delvers whisper that boots have reached floor %d of the Spire." % floor_heard)
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
	var heard: Array[String] = []
	for item in chosen:
		bullets.append("• \"%s\"" % item)
		# A place somebody names goes on your map ([D50]).
		heard.append_array(Atlas.hear_of(world, item))
	var said := lead + "\n\n".join(bullets)
	if not heard.is_empty():
		said += "\n\n" + Atlas.line("heard", {"places": ", ".join(heard)})
	return said
