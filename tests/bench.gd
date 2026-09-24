extends Node
## The bench: boot straight into the thing you want to look at.
##
## Testing anything used to mean starting a run and playing to the point of
## concern, or writing a throwaway scene to photograph one screen and deleting
## it again. This does both from the command line, and it stays in the repo.
##
##   # look at it, live, with a real party on a real map
##   godot --path . res://tests/bench.tscn -- --scene=world --at=gate --level=6 --play
##
##   # photograph it
##   godot --path . res://tests/bench.tscn -- --scene=party --level=6 --gold=800 --shot
##
##   # ask the data a question
##   godot --headless --path . res://tests/bench.tscn -- --list=sites
##
## Screenshots need a real renderer, so leave `--headless` off when using
## `--shot`. Everything else runs headless.

const SHOT_DIR := "res://.art_stage"
## Frames to let a scene settle before photographing it. Tweens and camera
## smoothing both need a moment or the picture is of the first frame.
const SETTLE := 30

## Full scenes, by the key [Game] knows them as.
const SCENES := {
	"cinematic": "res://src/ui/cinematic.tscn",
	"title": "res://src/ui/title_screen.tscn",
	"character_select": "res://src/ui/character_select.tscn",
	"world": "res://src/world/world_scene.tscn",
	"area": "res://src/area/area_scene.tscn",
	"battle": "res://src/battle/battle.tscn",
	"skirmish": "res://src/skirmish/skirmish.tscn",
	"training": "res://src/training/training_ground.tscn",
	"coliseum": "res://src/coliseum/coliseum.tscn",
	"museum": "res://src/ui/museum.tscn",
	"summary": "res://src/ui/run_summary.tscn",
}

## Overlays, which are opened rather than swapped to.
const OVERLAYS := {
	"party": "res://src/ui/party_screen.tscn",
	"journal": "res://src/ui/journal_screen.tscn",
	"menu": "res://src/ui/system_menu.tscn",
}

var _args: Dictionary = {}


func _ready() -> void:
	_args = _parse(OS.get_cmdline_user_args())
	if _args.has("help") or _args.is_empty():
		_print_help()
		get_tree().quit(0)
		return

	await get_tree().process_frame
	_build_state()

	if _args.has("list"):
		_list(str(_args["list"]))
		get_tree().quit(0)
		return

	if _args.has("report"):
		_report_named(str(_args["report"]))
		get_tree().quit(0)
		return

	var key := str(_args.get("scene", ""))
	if key == "":
		_report()
		get_tree().quit(0)
		return

	var scene := _open(key)
	if scene == null:
		push_error("bench: no scene '%s'" % key)
		get_tree().quit(1)
		return

	if _args.has("play"):
		# Left running on purpose: this is the hands-on mode.
		return
	for _i in int(_args.get("frames", SETTLE)):
		await get_tree().process_frame
	if _args.has("shot"):
		await _photograph(key)
	_report()
	get_tree().quit(0)


# --- the state ----------------------------------------------------------------


## Everything the harness can set up. Each flag is independent, so a command
## only says the part of the world it actually cares about.
func _build_state() -> void:
	GameState.new_game(int(_args.get("seed", 0)), str(_args.get("hero", "")))
	var world: World = GameState.world

	if _args.has("gold"):
		GameState.gold = int(_args["gold"])
	if _args.has("level"):
		for member in GameState.roster.party_members():
			Progression.raise_to(member, int(_args["level"]), world)
	if _args.has("floor"):
		world.tower_floor = int(_args["floor"])
	if _args.has("hoard"):
		world.tower_hoard = int(_args["hoard"])
	if _args.has("stores"):
		GameState.stores.append_array(str(_args["stores"]).split(",", false))
	if _args.has("equip"):
		var lead := GameState.roster.player()
		if lead != null:
			lead.equipment = str(_args["equip"])
	if _args.has("hurt"):
		for member in GameState.roster.party_members():
			member.hp = maxi(1, roundi(member.max_hp() * float(_args["hurt"])))
	if _args.has("at"):
		_stand_at(str(_args["at"]))
	if _args.has("steps"):
		world.steps = int(_args["steps"])


## Put the party on the first site of a kind, so "--at=gate" means what it says.
func _stand_at(kind: String) -> void:
	var world: World = GameState.world
	var sites := world.sites_of_kind(kind)
	if sites.is_empty():
		push_warning("bench: no %s on this map" % kind)
		return
	world.player_cell = sites[0].cell


# --- opening things -----------------------------------------------------------


func _open(key: String) -> Node:
	if OVERLAYS.has(key):
		var overlay: Node = load(OVERLAYS[key]).instantiate()
		add_child(overlay)
		if overlay.has_method("open"):
			overlay.call("open")
		return overlay
	if not SCENES.has(key):
		return null
	var scene: Node = load(SCENES[key]).instantiate()
	scene.set("boot_payload", _payload(key))
	add_child(scene)
	if _args.has("zoom"):
		_pull_back(scene, float(_args["zoom"]))
	return scene


## Stand further off. A camera rig fights for its own framing, so the zoom is
## set after the scene has settled rather than as it is built.
func _pull_back(scene: Node, level: float) -> void:
	await get_tree().process_frame
	for camera: Camera2D in scene.find_children("*", "Camera2D", true, false):
		camera.zoom = Vector2(level, level)


func _payload(key: String) -> Dictionary:
	match key:
		"area":
			return { "area_id": str(_args.get("area", "village")), "return_scene": "world" }
		"battle":
			var world: World = GameState.world
			return {
				"encounter": Encounter.wild(
					world, world.player_cell, GameState.party_characters(), world.rng
				),
				"return_scene": "world",
			}
		"skirmish":
			var world: World = GameState.world
			return {
				"encounter": Encounter.wild(
					world, world.player_cell, GameState.party_characters(), world.rng
				),
				"return_scene": "title",
				# A photograph of a paused fight is a photograph of nothing happening.
				"paused": not _args.has("shot"),
			}
		_:
			return {}


func _photograph(key: String) -> void:
	await RenderingServer.frame_post_draw
	var name_ := str(_args["shot"]) if str(_args["shot"]) != "" else key
	var path := "%s/bench_%s.png" % [SHOT_DIR, name_]
	get_viewport().get_texture().get_image().save_png(path)
	print("shot: %s" % path)


# --- reading things back ------------------------------------------------------


## What the harness actually built, so a headless run still says something.
func _report() -> void:
	var world: World = GameState.world
	var lead := GameState.roster.player()
	print("seed %d | %s | %d gold | step %d | floor %d | hoard %d | packs %d" % [
		world.world_seed, lead.display_name if lead != null else "nobody",
		GameState.gold, world.steps, world.tower_floor, world.tower_hoard,
		GameState.stores.size(),
	])
	print("standing on %s at %s" % [_where(), str(world.player_cell)])
	for member in GameState.roster.party_members():
		print("  %-12s L%-2d %-16s %3d/%-3d  %s" % [
			member.display_name, member.level, member.class_name_text(),
			member.current_hp(), member.max_hp(),
			member.equipment if member.equipment != "" else "-",
		])


func _where() -> String:
	var site := GameState.world.site_at(GameState.world.player_cell)
	if site != null:
		return "%s (%s)" % [site.display_name, site.kind]
	return str(GameState.world.terrain_at(GameState.world.player_cell).get("name", "open ground"))


## Answers to the questions that otherwise need a throwaway probe script.
func _list(what: String) -> void:
	match what:
		"sites":
			for site in GameState.world.sites:
				var area_id: String = site.data.get("area", site.kind)
				print("%-8s %-22s %-9s area=%-14s enterable=%s" % [
					site.kind, site.display_name, str(site.cell),
					area_id, Database.has_area(area_id),
				])
		"areas":
			for id: String in _files_in("res://data/areas"):
				print(id)
		"units":
			for id: String in Database.units:
				var unit: Dictionary = Database.units[id]
				print("%-22s %-18s hp%-4d atk%-3d def%-3d %s" % [
					id, unit.get("job", ""), int(unit.get("max_hp", 0)),
					int(unit.get("attack", 0)), int(unit.get("defense", 0)),
					",".join(unit.get("abilities", [])),
				])
		"abilities":
			for id: String in Database.abilities:
				var ability: Dictionary = Database.abilities[id]
				print("%-16s %-6s reach %d-%-2d splash%-2d x%-5s %s" % [
					id, ability.get("target", "enemy"),
					int(ability.get("min_range", 1)), int(ability.get("range", 1)),
					int(ability.get("splash", 0)),
					String.num(float(ability.get("power", 1.0)), 2),
					"bonus" if ability.get("bonus", false) else "",
				])
		"equipment":
			for id: String in Database.equipment:
				var piece: Dictionary = Database.equipment[id]
				var kind: String = piece.get(
					"kind", "charm" if piece.get("charm", false) else "gear"
				)
				print("%-18s %-8s atk%-3d def%-3d %4d gold  suits %s" % [
					id, kind, int(piece.get("attack", 0)),
					int(piece.get("defense", 0)), Market.price_of(id),
					",".join(piece.get("suits", [])) if piece.has("suits") else "anyone",
				])
		"heroes":
			for id: String in Database.heroes:
				var hero: Dictionary = Database.heroes[id]
				print("%-16s %d  %-24s %s" % [
					id, int(hero.get("difficulty", 1)), hero.get("title", ""),
					",".join(hero.get("companions", [])),
				])
		"classes":
			for id: String in Database.classes:
				var job: Dictionary = Database.classes[id]
				print("%-18s themes %-28s grants %s" % [
					id, ",".join(job.get("themes", [])), ",".join(job.get("grants", [])),
				])
		"tempers":
			for code: String in Database.temper_types():
				var kind: Dictionary = Database.temper_types()[code]
				var who: String = kind.get("hero", "")
				print("%-6s %-22s %s" % [
					code, kind.get("display_name", ""),
					who if who != "" else "— nobody written yet",
				])
		_:
			print("nothing called '%s'. try: sites areas units abilities equipment heroes classes tempers" % what)


# --- what to write next -------------------------------------------------------


func _report_named(what: String) -> void:
	match what:
		"casting":
			_casting_report()
		_:
			print("no report called '%s'. try: casting" % what)


## Where each authored pool stands against the roster. Read it before an
## authoring session: starved says what to write, forced says what to cast
## without discussion, and contested is the only part worth arguing about.
func _casting_report() -> void:
	for field: String in Character.TRAIT_POOLS:
		var pool: String = Character.TRAIT_POOLS[field]
		var book: Dictionary = Database.casting.get(pool, {})
		var pieces: Dictionary = book.get("pieces", {})
		var written := Database.lore_pool(pool)
		var authored: Array = []
		for piece_id: String in written:
			if not bool(written[piece_id].get("provisional", false)):
				authored.append(piece_id)

		# hero -> the pieces marked for them; piece -> how many it could fit.
		var marked: Dictionary = {}
		var orphans: Array = []
		var contested: Array = []
		var cast_count := 0
		for piece_id: String in pieces:
			var entry: Dictionary = pieces[piece_id]
			var candidates: Array = entry.get("candidates", [])
			if str(entry.get("cast", "")) != "":
				cast_count += 1
			if candidates.is_empty():
				orphans.append(piece_id)
			elif candidates.size() > 2:
				contested.append("%s (%d)" % [piece_id, candidates.size()])
			for hero_id: String in candidates:
				marked[hero_id] = marked.get(hero_id, 0) + 1

		var starved: Array = []
		var forced: Array = []
		for hero_id: String in Database.heroes:
			if str(Database.hero(hero_id).get(field, "")) != "":
				continue
			var count: int = marked.get(hero_id, 0)
			if count == 0:
				starved.append(hero_id)
			elif count == 1:
				forced.append(hero_id)

		print("")
		print("%s — %d written (%d provisional), %d in the ledger, %d cast%s" % [
			pool.to_upper(), written.size(), written.size() - authored.size(),
			pieces.size(), cast_count, "  [LOCKED]" if bool(book.get("locked", false)) else "",
		])
		print("  starved   %s" % (", ".join(starved) if not starved.is_empty() else "none"))
		print("  forced    %s" % (", ".join(forced) if not forced.is_empty() else "none"))
		print("  contested %s" % (", ".join(contested) if not contested.is_empty() else "none"))
		print("  orphans   %s" % (", ".join(orphans) if not orphans.is_empty() else "none"))


func _files_in(dir_path: String) -> Array:
	var out: Array = []
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".json"):
			out.append(file.trim_suffix(".json"))
	out.sort()
	return out


# --- arguments ----------------------------------------------------------------


## `--name=value` or a bare `--name`, which reads as an empty string.
func _parse(argv: PackedStringArray) -> Dictionary:
	var out: Dictionary = {}
	var last := ""
	for raw: String in argv:
		# PowerShell splits `--flag=a,b` into two arguments, so a token that is
		# not itself a flag is the rest of the one before it.
		if not raw.begins_with("--"):
			if last != "":
				out[last] = "%s,%s" % [out[last], raw]
			continue
		var arg := raw.trim_prefix("--")
		var split := arg.split("=", true, 1)
		last = split[0]
		out[last] = split[1] if split.size() > 1 else ""
	return out


func _print_help() -> void:
	print("""
bench — boot straight into the thing you want to look at

  godot --path . res://tests/bench.tscn -- [flags]

state
  --seed=N          world seed (0 or absent picks one)
  --hero=id         who leads; absent gives the founding three
  --level=N         raise the whole party to this level
  --gold=N          purse
  --at=KIND         stand on the first tower|gate|village|keep|library|hut|home
  --steps=N         world clock
  --floor=N         Tower floors already climbed
  --hoard=N         gold carried inside the Tower
  --stores=a,b      equipment ids into the packs
  --equip=id        put a piece on the lead
  --hurt=0.4        drop the party to this share of their health

what to open
  --scene=KEY       %s
                    %s
  --area=id         which interior, with --scene=area

what to do
  --play            leave it running (drop the --headless flag)
  --shot[=name]     photograph it into .art_stage (drop the --headless flag)
  --zoom=N          camera zoom; below 1 stands further off
  --frames=N        frames to settle before the shot (default %d)
  --list=WHAT       sites areas units abilities equipment heroes classes tempers
  --report=casting  where each authored pool stands against the roster
  (none)            build the state, print what it built, quit
""" % [
		" ".join(SCENES.keys()),
		" ".join(OVERLAYS.keys()),
		SETTLE,
	])
