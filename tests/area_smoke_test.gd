extends Node
## Boots every area in `data/areas` and walks the party around inside one, so
## a broken tileset, legend or exit shows up without opening the editor.
##
##   godot --headless --path . res://tests/area_smoke_test.tscn

const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")
const SEED := 20260829
const AREAS := [
	"village", "village_inn",
	"village_fen", "fen_alehouse",
	"village_pines", "pine_longhouse",
	"village_shore", "shore_taphouse",
	"village_dune", "dune_serai",
	"keep", "keep_hall",
	"keep_thorn", "thorn_hall",
	"library", "library_cloister", "library_vault",
	"gate", "gate_barrow", "gate_drowned", "gate_ash", "gate_dune",
	"hut", "hut_stilt", "hut_cairn", "hut_orchard",
	"wild_grove", "wild_fen", "wild_scarp", "wild_thicket", "wild_oasis", "wild_peak",
	"hamlet_fold", "hamlet_mill", "hamlet_salt", "caravan_ilse", "caravan_red",
	"tower", "home",
	"tower_floor_1", "tower_floor_2", "tower_floor_3", "tower_floor_4", "tower_floor_5",
	"camp", "tutorial",
	"city", "city_streets", "city_tavern", "city_house",
	"city_cathedral", "city_apothecary", "city_smithy", "city_shrine", "city_bathhouse", "city_fish",
]
## Longest a staged meeting is allowed to take before the talking starts.
const CUTSCENE_PATIENCE := 20.0
const SaveFile := preload("res://src/chronicle/save_file.gd")
const Talk := preload("res://src/dialogue/talk.gd")
const Coins := preload("res://src/chronicle/coins.gd")
const TutorialGuide := preload("res://src/ui/tutorial_guide.gd")
const RunMode := preload("res://src/chronicle/run_mode.gd")
const GroundGen := preload("res://src/area/ground_gen.gd")
const Formations := preload("res://src/skirmish/formations.gd")
const Biome := preload("res://src/chronicle/biome.gd")
const Land := preload("res://src/area/land.gd")
const AreaCritter := preload("res://src/area/area_critter.gd")
const FirstRoad := preload("res://src/area/first_road.gd")
const Memories := preload("res://src/chronicle/memories.gd")
const Chapters := preload("res://src/chronicle/chapters.gd")
const TowerFloors := preload("res://src/chronicle/tower_floors.gd")
const Fighter := preload("res://src/skirmish/fighter.gd")
const Sixteen := preload("res://src/chronicle/sixteen.gd")
const Siblings := preload("res://src/chronicle/siblings.gd")
const Company := preload("res://tests/company.gd")
const GateInside := preload("res://src/chronicle/gate_inside.gd")
const Climbers := preload("res://src/chronicle/climbers.gd")
const Recruits := preload("res://src/chronicle/recruits.gd")
const Crafting := preload("res://src/chronicle/crafting.gd")
const Caves := preload("res://src/chronicle/caves.gd")
const Sellswords := preload("res://src/chronicle/sellswords.gd")
const Wanderers := preload("res://src/chronicle/wanderers.gd")
const CompanyTalk := preload("res://src/chronicle/company_talk.gd")

var _requests: Array[Dictionary] = []
var _failures: Array[String] = []
## Conversations the area asked for, in order. A lambda captures a local by
## value, so the signal has to land on the node itself.
var _opened: Array[String] = []


func _ready() -> void:
	GameState.new_game(SEED)
	EventBus.request_scene.connect(
		func(key: String, payload: Dictionary) -> void:
			_requests.append({ "key": key, "payload": payload })
	)
	# The letterbox normally lives in main.tscn; a cutscene needs it to play into.
	add_child(load("res://src/ui/cutscene_layer.tscn").instantiate())

	for area_id in AREAS:
		await _check_area(area_id)
	await _check_camp()
	_check_trading()
	_check_the_builder_and_the_healer()
	_check_the_crater_town()
	await _check_a_house_in_stormreach()
	_check_story_npcs()
	_check_recruiting()
	_check_company_voices()
	_check_city_doors()
	_check_sellswords()
	_check_drinkers_in_the_flagon()
	_check_crafting()
	_check_forging_and_the_hearth()
	await _check_caves()
	_check_rises()
	_check_herbs_on_the_land()
	_check_ladders_and_rope()
	await _check_tutorial()
	await _check_last_stand()
	await _check_practice_band()
	await _check_by_the_fire()
	await _check_tower_floor()
	await _check_tower_grows()
	await _check_heights()
	await _check_wild_stories()
	await _check_band_shape_on_the_ground()
	await _check_inside_a_gate()
	_check_gates_grow()
	await _check_people_on_the_land()
	await _check_the_board()
	await _check_the_land()
	await _check_the_joined_land()
	await _check_play_test_three()
	await _check_life_on_the_land()
	_check_life_matches_the_land()
	await _check_play_test_four()
	await _check_inn_rooms()
	await _check_followers_face()
	await _check_formation_walk()
	await _check_play_test_seven()
	await _check_sennet_from_afar()
	_check_the_climbers_stone()
	await _check_the_sword_in_the_yard()
	await _check_the_journal_at_the_side()
	_check_tracks()
	_check_open_city()
	await _check_play_hud()

	print("")
	if _failures.is_empty():
		print("area smoke test: PASS")
		get_tree().quit(0)
	else:
		for failure in _failures:
			print("FAIL: %s" % failure)
		get_tree().quit(1)


func _check_area(area_id: String) -> void:
	var map := AreaMap.load_area(area_id)
	if map == null:
		_fail("%s: no such area" % area_id)
		return
	if map.width == 0 or map.height == 0:
		_fail("%s: empty grid" % area_id)
	if not map.is_walkable(map.spawn):
		_fail("%s: the party spawns inside a wall" % area_id)
	for exit_cell in map.exits:
		if not map.is_walkable(exit_cell):
			_fail("%s: exit %s cannot be reached" % [area_id, exit_cell])
	for cell: Vector2i in map.spots:
		if not map.is_walkable(cell):
			_fail("%s: spot %s cannot be stood on" % [area_id, cell])
	for person: Dictionary in map.people:
		_check_person(area_id, map, person)
	for building: Dictionary in map.buildings:
		_check_building(area_id, map, building)

	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": area_id, "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame

	var painted := 0
	for layer in scene.get_node("Layers").get_children():
		if layer is TileMapLayer:
			painted += (layer as TileMapLayer).get_used_cells().size()
		elif layer is Sprite2D:
			painted += 1
	if painted == 0:
		_fail("%s: nothing was painted" % area_id)
	# The y-sorted layer holds scenery too, so count only the people in it.
	var arrived := scene.get_node("Actors").get_children().filter(
		func(node: Node) -> bool: return node is AreaActor
	).size()
	var expected := GameState.party_characters().size() + map.people.size()
	# A band the area stands up itself (a floor of the Tower's, D102) is people too.
	for watch: Node2D in scene.get("_watches"):
		expected += (watch.get("figures") as Array).size()
	if arrived != expected:
		_fail("%s: %d actors turned up, expected %d" % [area_id, arrived, expected])

	await _check_talking(scene, area_id)
	_walk_in(scene, map)
	_walk_out(scene, map)
	scene.queue_free()
	await get_tree().process_frame


## A `talk` block builds into a conversation whose every reply leads somewhere, refused or not,
## and sells only things that exist ([Talk]).
func _check_talk(area_id: String, person: Dictionary) -> void:
	var who: String = person.get("name", "someone")
	var offer := Recruits.offer(area_id, person)
	for roll: float in [0.0, 0.99]:
		var nodes: Dictionary = Talk.build(who, person["talk"], false, roll, "met:test", "", offer)
		if not nodes.has("hello") or not nodes.has("menu"):
			_fail("%s: %s's talk has no greeting or no menu" % [area_id, who])
		for node_id: String in nodes:
			var node: Dictionary = nodes[node_id]
			var targets: Array = [node.get("next", "end")]
			for option: Dictionary in node.get("options", []):
				targets.append(option.get("goto", "end"))
				if option.has("check"):
					targets.append(option["check"].get("success", ""))
					targets.append(option["check"].get("failure", ""))
			for target: String in targets:
				if target != "end" and not nodes.has(target):
					_fail("%s: %s's talk node '%s' leads to '%s', which is not there" % [area_id, who, node_id, target])
	for ware: Dictionary in person["talk"].get("sells", []):
		if Database.equipment_piece(str(ware.get("item", ""))).is_empty():
			_fail("%s: %s sells '%s', which is not in equipment.json" % [area_id, who, ware.get("item", "")])
	var job: Dictionary = person["talk"].get("job", {})
	if not job.is_empty() and (str(job.get("flag", "")) == "" or str(job.get("done_flag", "")) == ""):
		_fail("%s: %s's job has no flag or no done_flag" % [area_id, who])


## Other companies, on the road and in the Tower, each in its own voice (play-test 8, ask 2; [CompanyTalk]):
## nobody asks the same four things of everyone, what comes up fits the floor, and every talk holds together.
func _check_company_voices() -> void:
	var rules := CompanyTalk.rules()
	var companies: Array = rules.get("companies", [])
	var voices: Dictionary = rules.get("voices", {})
	var answers := {}
	var wordings := {}
	for company: String in companies:
		if not voices.has(company):
			_fail("company voices: %s has no voice of its own" % company)
			continue
		for place: Array in [[CompanyTalk.ROAD, 0], [CompanyTalk.FLOOR, 3], [CompanyTalk.FLOOR, 16], [CompanyTalk.SHARED, 15]]:
			var block := CompanyTalk.block(company, str(place[0]), int(place[1]), 77)
			var asks: Array = block.get("ask", [])
			var said := "%s %s %s %s" % [block.get("hello", ""), block.get("bye", ""), block.get("leave", ""),
				" ".join(asks.map(func(a: Dictionary) -> String: return "%s %s" % [a.get("q", ""), a.get("a", "")]))]
			if said.contains("{") or said.contains("..."):
				_fail("company voices: %s on %s leaves a gap: %s" % [company, place, said])
			var questions := asks.map(func(a: Dictionary) -> String: return str(a.get("q", "")))
			if asks.size() < 3 + (voices[company].get("own", []) as Array).size() + int(rules.get("place_asks", 2)) \
					or questions.size() != _distinct(questions):
				_fail("company voices: %s on %s is asked %s" % [company, place, questions])
			wordings[str(questions[0])] = true
			answers[str(asks[0].get("a", ""))] = true
			_check_talk("climbers", { "name": company, "talk": block })
			# What a floor brings up is of that floor: every question asked is one a fitting ask words.
			if str(place[0]) != CompanyTalk.ROAD:
				var fitting := {}
				for ask: Dictionary in (rules.get("asks", {}) as Dictionary).get(str(place[0]), []):
					if int(place[1]) >= int(ask.get("from", 0)) and int(place[1]) <= int(ask.get("to", 999)):
						fitting[str(ask.get("q", "")).format({ "floor": place[1], "next": int(place[1]) + 1 })] = true
				var drawn: Array = questions.slice(3 + (voices[company].get("own", []) as Array).size())
				for q: Variant in drawn:
					if not fitting.has(q):
						_fail("company voices: %s on floor %s is asked %s, which is not of that floor" % [company, place[1], q])
	if answers.size() < companies.size():
		_fail("company voices: %d companies say who they are in %d ways" % [companies.size(), answers.size()])
	if wordings.size() < 2:
		_fail("company voices: the party asks who they are only as %s" % [wordings.keys()])
	print("company voices: %d companies, asked who they are %d ways; %s on floor 16 is asked %s" % [companies.size(), wordings.size(),
		companies[0], CompanyTalk.block(str(companies[0]), CompanyTalk.FLOOR, 16, 77).get("ask", []).map(func(a: Dictionary) -> String: return str(a.get("q", "")))])


func _distinct(items: Array) -> int:
	var seen := {}
	for item: Variant in items:
		seen[item] = true
	return seen.size()
## More of Stormreach's doors open (play-test 8, ask 8; call BX): every door with an `area` leads into a
## room that is there, the six opened for play-test 8 among them.
func _check_city_doors() -> void:
	var open: Array = []
	for building: Dictionary in AreaMap.load_area("city_streets").buildings:
		var area_id := str(building.get("area", ""))
		if area_id == "":
			continue
		open.append(area_id)
		if not Database.has_area(area_id):
			_fail("city doors: %s opens on %s, which is not there" % [building.get("name", ""), area_id])
			continue
		var room := AreaMap.load_area(area_id)
		if room.exits.is_empty() or not room.is_walkable(AreaMap.to_cell(Database.area(area_id).get("spawn", [0, 0]))):
			_fail("city doors: %s has no way in or out" % area_id)
	for wanted: String in ["city_cathedral", "city_apothecary", "city_smithy", "city_shrine", "city_bathhouse", "city_fish"]:
		if not open.has(wanted):
			_fail("city doors: no door in Stormreach opens on %s" % wanted)
	print("city doors: %d of Stormreach's doors open (%s)" % [open.size(), ", ".join(open)])


## Asking anyone to walk with the company ([D277]): a Charisma check, a no that names what would
## win them over, a yes once that is done, and a place left empty where they stood.
func _check_recruiting() -> void:
	var people := {}
	for area_id: String in ["home", "village", "tutorial", "keep_hall"]:
		for person: Dictionary in Database.area(area_id).get("people", []):
			people[str(person.get("name", ""))] = [area_id, person]
	for name_: String in ["Hesk the Stallholder", "Ness the healer", "Maren the Guide", "Dirte, the God of Kings"]:
		if Recruits.askable(people[name_][0], people[name_][1]):
			_fail("recruiting: %s can be asked to leave their post" % name_)
	var settler: Dictionary = people["a settler"][1]
	if not Recruits.askable("home", settler) or Recruits.dc(settler) != int(Recruits.rules().get("dc", 0)):
		_fail("recruiting: a settler cannot be asked, or is as hard to ask as the story folk")
	if Recruits.dc(people["Bram the Sworn Blade"][1]) <= Recruits.dc(settler):
		_fail("recruiting: Bram is no harder to talk round than a settler")
	var wat_ask := Recruits.trust_ask("village", people["Wat the Village Idiot"][1])
	if not wat_ask.has("job"):
		_fail("recruiting: Wat's trust is not his own favour")

	var offer := Recruits.offer("home", settler)
	var nodes: Dictionary = Talk.build("a settler", settler["talk"], false, 0.5, "met:test", "", offer)
	var ask: Array = (nodes["menu"]["options"] as Array).filter(
		func(o: Dictionary) -> bool: return str(o.get("check", {}).get("skill", "")) == "charisma")
	if offer.get("state") != "ask" or ask.is_empty():
		_fail("recruiting: a settler offers no Charisma check (state %s)" % offer.get("state"))
		return
	# Said no: the conversation over, they remember what they asked and how far the company had got.
	GameState.set_flag(str(offer["no_flag"]))
	Recruits.settle(GameState.world, GameState.roster, GameState.flags, GameState.ledger)
	if Recruits.state("home", settler, GameState.ledger, true) != "waiting":
		_fail("recruiting: a settler who said no is not waiting on anything")
	var held: Dictionary = GameState.flags.get(Recruits.TRUST + Recruits.key("home", settler), {})
	Ledger.add(GameState.ledger, str(held.get("ledger", "kills")), int(held.get("need", 1)))
	if Recruits.state("home", settler, GameState.ledger, true) != "trusted":
		_fail("recruiting: doing what a settler asked did not win them over (%s)" % str(held))
	offer = Recruits.offer("home", settler)
	nodes = Talk.build("a settler", settler["talk"], false, 0.5, "met:test", "", offer)
	if not nodes.has("recruit_trusted") or nodes["recruit_trusted"].get("set_flag") != offer["yes_flag"]:
		_fail("recruiting: a won-over settler does not come without a roll")
	if Recruits.state("home", settler, GameState.ledger, false) != "full":
		_fail("recruiting: a full company is not told so")
	# Said yes: they join at the lead's level, under a name of their own, and leave the place empty.
	var before := GameState.roster.party.size()
	var seats := GameState.roster.seats
	GameState.roster.seats = maxi(seats, before + 1)
	GameState.set_flag(str(offer["yes_flag"]))
	var came: Array = Recruits.settle(GameState.world, GameState.roster, GameState.flags, GameState.ledger)
	if came.size() != 1 or GameState.roster.party.size() != before + 1:
		_fail("recruiting: a settler said yes and did not join (%d came)" % came.size())
	else:
		var joined: Character = came[0]
		if joined.display_name.begins_with("a ") or joined.level != GameState.roster.player().level:
			_fail("recruiting: the settler joined as '%s' at level %d" % [joined.display_name, joined.level])
		GameState.roster.dismiss(joined.id)
	if not Recruits.has_joined("home", settler) or Recruits.askable("home", settler):
		_fail("recruiting: a settler who joined can still be asked")
	GameState.roster.seats = seats


## Sellswords off the Gilded Flagon's book ([D295]): Varro keeps the book and never joins; one hired
## is paid for up front, marches, bonds with nobody, keeps their terms through a save, and goes when
## the job they were hired for is done, not another.
func _check_sellswords() -> void:
	var varro: Dictionary = {}
	for person: Dictionary in Database.area("city_tavern").get("people", []):
		if str(person.get("talk", {}).get("hires", "")) != "":
			varro = person
	if varro.is_empty():
		_fail("sellswords: nobody in the Gilded Flagon keeps the book")
		return
	if Recruits.askable("city_tavern", varro):
		_fail("sellswords: %s can be asked to leave the book" % varro["name"])
	var kept_gold := GameState.gold
	var seats := GameState.roster.seats
	GameState.roster.seats = maxi(seats, GameState.roster.party.size() + 1)
	var board := Sellswords.board(GameState.world)
	if board.size() != int(Sellswords.rules().get("board_size", 0)):
		_fail("sellswords: the book holds %d, not %d" % [board.size(), int(Sellswords.rules().get("board_size", 0))])
		GameState.roster.seats = seats
		return
	GameState.gold = int(board[0]["price"]) + 10
	var nodes: Dictionary = Talk.build(str(varro["name"]), varro["talk"], false, 0.5, "met:test")
	var hires: Array = (nodes.get("hire", {}).get("options", []) as Array).filter(
		func(o: Dictionary) -> bool: return o.has("hire"))
	if hires.size() != board.size():
		_fail("sellswords: the book's talk offers %d of %d" % [hires.size(), board.size()])
	var before := GameState.roster.party.size()
	DialogueScript.apply_effects(hires[0] if not hires.is_empty() else {"hire": int(board[0]["index"])})
	var hired: Character = GameState.roster.party_members().back()
	if GameState.roster.party.size() != before + 1 or not Sellswords.is_sellsword(hired):
		_fail("sellswords: hiring the first on the book did not bring a sellsword")
	else:
		if GameState.gold != 10:
			_fail("sellswords: hired for %s but the purse holds %d of 10" % [Coins.text(int(board[0]["price"])), GameState.gold])
		if not hired.bonds.is_empty():
			_fail("sellswords: a sellsword came with bonds (%s)" % str(hired.bonds))
		if Sellswords.board(GameState.world).size() != board.size() - 1:
			_fail("sellswords: the one hired is still on the book")
		if Character.from_dict(hired.to_dict()).contract != hired.contract:
			_fail("sellswords: the terms do not survive a save")
		var job := str(hired.contract.get("job", ""))
		var other := "chapter" if job == "gate" else "gate"
		if not Sellswords.on_job(GameState.roster, other).is_empty() or GameState.roster.by_id(hired.id) == null:
			_fail("sellswords: a sellsword hired for a %s left when a %s was done" % [job, other])
		var said := Sellswords.on_job(GameState.roster, job)
		if said.size() != 1 or GameState.roster.by_id(hired.id) != null:
			_fail("sellswords: a sellsword hired for a %s stayed after it was done" % job)
	GameState.gold = kept_gold
	GameState.roster.seats = seats


## The Flagon as where the roaming leads are met until the company has a tavern ([D295]): walking
## in finds, a while at a time, one of the unmet drinking there, and nobody new in the same while.
func _check_drinkers_in_the_flagon() -> void:
	var world: World = GameState.world
	var city: Site = null
	for site: Site in world.sites:
		if str(site.data.get("area", site.kind)) == "city_streets":
			city = site
	if city == null or world.wanderers.is_empty():
		_fail("the Flagon: no city, or nobody roaming (%d)" % world.wanderers.size())
		return
	var kept_steps := world.steps
	var kept := world.wanderers.duplicate(true)
	var came := ""
	for i in 20:
		world.steps = kept_steps + i * int(Wanderers.rules().get("tavern", {}).get("every", 300))
		for each: Dictionary in world.wanderers:
			if Wanderers.cell_of(each.get("at", [])) == city.cell:
				each["at"] = [-1, -1]
		came = Wanderers.drink(world, city, "city_tavern")
		if came != "":
			break
	if came == "":
		_fail("the Flagon: twenty whiles and none of the roaming leads came in for a drink")
	else:
		if Wanderers.here(world, city.cell).filter(func(e: Dictionary) -> bool: return str(e["id"]) == came).is_empty():
			_fail("the Flagon: %s came in but is not in the city" % came)
		if Wanderers.drink(world, city, "city_tavern") != "":
			_fail("the Flagon: a second lead came in the same while")
		if Wanderers.drink(world, city, "city_streets") != "":
			_fail("the Flagon: the street drew a lead in as the tavern does")
	world.steps = kept_steps
	world.wanderers = kept


## Making things ([D280]): herbs mixed into a draught out of the packs, and a smith honing a weapon
## a notch for coin, kept on that person for that weapon.
func _check_crafting() -> void:
	var kept_stores := GameState.stores.duplicate()
	var red: Dictionary = Crafting.recipes().filter(func(r: Dictionary) -> bool: return r["makes"] == "red_draught")[0]
	for i in 3:
		GameState.stores.append("herbs")
	var before := GameState.stores.count("red_draught")
	if Crafting.mix(red, GameState.stores) == "" or GameState.stores.count("red_draught") != before + 1:
		_fail("crafting: three Bitter Herbs did not mix into a Red Draught")
	if GameState.stores.count("herbs") != kept_stores.count("herbs"):
		_fail("crafting: mixing did not use up the herbs")
	if Crafting.mix(red, GameState.stores) != "" and kept_stores.count("herbs") < 3:
		_fail("crafting: a draught mixed out of nothing")

	var smith := {}
	for person: Dictionary in Database.area("home").get("people", []):
		if person.get("name", "") == "Hald the smith":
			smith = person
	var wielder: Character = GameState.party_characters()[0]
	var kept_weapon := wielder.equipment
	wielder.equipment = "iron_blade"
	wielder.honed.erase("iron_blade")
	var blunt := int(Gear.bonus("iron_blade", wielder)["attack"])
	var nodes: Dictionary = Talk.build("Hald", smith.get("talk", {}), true, 0.5, "met:test")
	var offers: Array = nodes.get("hone", {}).get("options", []).filter(func(o: Dictionary) -> bool: return o.get("hone", "") == wielder.id)
	if offers.is_empty():
		_fail("crafting: Hald offers no edge for %s's Iron Blade" % wielder.display_name)
	else:
		GameState.gold = int(offers[0]["requires_gold"]) + 10
		DialogueScript.apply_effects(offers[0])
		if int(Gear.bonus("iron_blade", wielder)["attack"]) != blunt + 1 or GameState.gold != 10:
			_fail("crafting: Hald took %d and the blade is %+d" % [int(offers[0]["requires_gold"]), int(Gear.bonus("iron_blade", wielder)["attack"]) - blunt])
		if int(Character.from_dict(wielder.to_dict()).honed.get("iron_blade", 0)) != 1:
			_fail("crafting: a honed blade did not survive a save")
	for i in 5:
		Crafting.hone(wielder)
	if int(wielder.honed.get("iron_blade", 0)) != int(Crafting.rules().get("hone_most", 3)):
		_fail("crafting: a blade took more notches than the most")
	wielder.honed.erase("iron_blade")

	# Enchanting (D299 item 3): a rune out of the packs on the weapon they carry, a fight passive of
	# theirs while they carry it, kept through a save, one a weapon.
	wielder.enchanted.erase("iron_blade")
	var keen := Crafting.enchantment("keen")
	var rime := Crafting.enchantment("rime")
	if keen.is_empty() or rime.is_empty():
		_fail("enchanting: no Keen or Rime rune in crafting.enchant")
	else:
		var plain := Unit.from_character(wielder, Unit.Team.PLAYER, Vector2i.ZERO)
		var crit_before := 0.0
		for p: Dictionary in SkirmishPassives.for_unit(plain):
			if str(p.get("effect", "")) == "crit":
				crit_before += float(p.get("value", 0.0))
		plain.free()
		if Crafting.enchant(wielder, keen, GameState.stores) != "":
			_fail("enchanting: a Keen Rune laid out of empty packs")
		for item: String in keen["needs"]:
			for i in int(keen["needs"][item]):
				GameState.stores.append(item)
		if Crafting.enchant(wielder, keen, GameState.stores) == "" or str(wielder.enchanted.get("iron_blade", "")) != "keen":
			_fail("enchanting: the Keen Rune did not go on the Iron Blade")
		for item: String in keen["needs"]:
			if GameState.stores.count(item) != kept_stores.count(item):
				_fail("enchanting: laying the rune did not use up the %s" % item)
		if Crafting.can_enchant(wielder, keen, GameState.stores):
			_fail("enchanting: the same rune could go on twice")
		var keyed := Unit.from_character(wielder, Unit.Team.PLAYER, Vector2i.ZERO)
		var crit_after := 0.0
		for p: Dictionary in SkirmishPassives.for_unit(keyed):
			if str(p.get("effect", "")) == "crit":
				crit_after += float(p.get("value", 0.0))
		keyed.free()
		if not is_equal_approx(crit_after - crit_before, float(keen["value"])):
			_fail("enchanting: the Keen Rune gave %+.2f crit in a fight, not %+.2f" % [crit_after - crit_before, float(keen["value"])])
		if str(Character.from_dict(wielder.to_dict()).enchanted.get("iron_blade", "")) != "keen":
			_fail("enchanting: a rune did not survive a save")
		for item: String in rime["needs"]:
			for i in int(rime["needs"][item]):
				GameState.stores.append(item)
		if Crafting.enchant(wielder, rime, GameState.stores).find("gone") < 0 or str(wielder.enchanted["iron_blade"]) != "rime":
			_fail("enchanting: a second rune did not take the first one's place")
		wielder.equipment = kept_weapon
		if Crafting.rune_passive(wielder).is_empty() == false and kept_weapon != "iron_blade":
			_fail("enchanting: a rune went with them off the weapon it is on")
	wielder.enchanted.erase("iron_blade")
	wielder.equipment = kept_weapon
	GameState.stores = kept_stores


## Crafting by a fire and at a smithy ([D346]): a fire's recipes only by a fire or in an inn, a smith
## forging gear out of ore and ash for his fee, never paid when the makings have gone, a making picked
## up going in the packs, and a rune's makings carried as a charm counted and spent.
func _check_forging_and_the_hearth() -> void:
	var kept_stores := GameState.stores.duplicate()
	var kept_gold := GameState.gold
	var by_fire := func(r: Dictionary) -> bool: return str(r.get("at", "")) == Crafting.HEARTH
	if Crafting.mixable_here(false).any(by_fire) or not Crafting.mixable_here(true).any(by_fire):
		_fail("hearth: a fire's recipe offered away from a fire, or none beside one")
	if not AreaMap.load_area("village_inn").hearth or AreaMap.load_area("home").hearth:
		_fail("hearth: the inn has no hearth to brew by, or the yard has one")
	var cheap: Array = Crafting.recipes_at(Crafting.HEARTH).filter(func(r: Dictionary) -> bool: return r["makes"] == "red_draught")
	GameState.stores = ["herbs", "herbs"]
	if cheap.is_empty() or Crafting.mix(cheap[0], GameState.stores) == "" or GameState.stores != ["red_draught"]:
		_fail("hearth: two herbs by the fire did not make a Red Draught: %s" % [GameState.stores])
	# Picked up off the land, ore and ash go in the packs.
	GameState.stores = []
	Loot.take("iron_ore", GameState.roster)
	if GameState.stores != ["iron_ore"]:
		_fail("makings: iron ore picked up did not go in the packs: %s" % [GameState.stores])
	# Hald forges an Iron Blade out of three ore and a stave, for his fee.
	var smith := {}
	for person: Dictionary in Database.area("home").get("people", []):
		if person.get("name", "") == "Hald the smith":
			smith = person
	GameState.stores = ["iron_ore", "iron_ore", "iron_ore", "ash_stave", "herbs"]
	var nodes: Dictionary = Talk.build("Hald", smith.get("talk", {}), true, 0.5, "met:test")
	var blade: Array = nodes.get("forge", {}).get("options", []).filter(func(o: Dictionary) -> bool:
		return int(o.get("forge", -1)) >= 0 and str(Crafting.recipes()[int(o["forge"])]["makes"]) == "iron_blade")
	if blade.is_empty():
		_fail("forging: Hald offers no Iron Blade for three ore and a stave")
	else:
		var fee := int(blade[0]["requires_gold"])
		GameState.gold = fee + 10
		DialogueScript.apply_effects(blade[0])
		if GameState.gold != 10 or GameState.stores != ["herbs", "iron_blade"]:
			_fail("forging: after the blade the purse is %d and the packs %s" % [GameState.gold, GameState.stores])
		DialogueScript.apply_effects(blade[0])
		if GameState.gold != 10 or GameState.stores.count("iron_blade") != 1:
			_fail("forging: a blade forged again with the makings gone, or paid for")
		if fee <= 0:
			_fail("forging: Hald works for nothing")
	GameState.stores = []
	var empty: Dictionary = Talk.build("Hald", smith.get("talk", {}), true, 0.5, "met:test")
	if not empty.has("forge_none") or empty.has("forge"):
		_fail("forging: Hald offers to forge out of empty packs")
	# A rune's makings bought from a trader are pocketed as charms, and still count.
	var keeper: Character = GameState.roster.player()
	var wielder: Character = GameState.party_characters()[0]
	var kept_weapon := wielder.equipment
	wielder.equipment = "iron_blade"
	wielder.enchanted.erase("iron_blade")
	Loot.take("whetstone", GameState.roster)
	GameState.stores = ["herbs", "herbs"]
	var keen := Crafting.enchantment("keen")
	if not keeper.charms.has("whetstone") or not Crafting.can_enchant(wielder, keen, GameState.stores):
		_fail("enchanting: a whetstone bought (a charm) does not count for a Keen Rune")
	else:
		var charms := keeper.charms.count("whetstone")
		Crafting.enchant(wielder, keen, GameState.stores)
		if keeper.charms.count("whetstone") != charms - 1 or not GameState.stores.is_empty():
			_fail("enchanting: the whetstone charm or the herbs were not spent")
	wielder.enchanted.erase("iron_blade")
	wielder.equipment = kept_weapon
	GameState.stores = kept_stores
	GameState.gold = kept_gold
	print("crafting: two herbs make a Red Draught by a fire; Hald forges an Iron Blade from 3 ore and a stave; a charm counts for a rune")


## Ladders and the rope ([D337]): a ladder on the cloud peak climbs a face two heights up that nothing
## else does; a plain face a height up on the scarp is no way up until the company carries a rope, and
## then it is, for a way found as well as a step; the rope is sold where a climber would look for one.
func _check_ladders_and_rope() -> void:
	var peak := AreaMap.load_area("wild_peak")
	var ladder := Vector2i(5, 6)
	var foot := ladder + Vector2i.DOWN
	if not peak.ladders.has(ladder) or peak.height_at(ladder) - peak.height_at(foot) != 2:
		_fail("ladders: the peak's ladder at %s does not stand against a face two heights up" % ladder)
	elif not peak.may_step(foot, ladder):
		_fail("ladders: the peak's ladder at %s does not climb" % ladder)
	var unladdered := ladder + Vector2i.LEFT
	if peak.height_at(unladdered) - peak.height_at(unladdered + Vector2i.DOWN) == 2 and peak.may_step(unladdered + Vector2i.DOWN, unladdered):
		_fail("ladders: the face beside the peak's ladder is climbed without one")
	var scarp := AreaMap.load_area("wild_scarp")
	var face := Vector2i(-1, -1)
	for y in scarp.height - 1:
		for x in scarp.width:
			var top := Vector2i(x, y)
			var below := top + Vector2i.DOWN
			if face.x < 0 and scarp.is_walkable(top) and scarp.is_walkable(below) and scarp.height_at(top) - scarp.height_at(below) == 1 \
					and not scarp.ways_up.has(top) and not scarp.ladders.has(top) and not scarp.ways_up.has(below):
				face = top
	if face.x < 0:
		_fail("ladders: no plain face on the scarp to try a rope on")
		return
	if scarp.may_step(face + Vector2i.DOWN, face):
		_fail("ladders: the scarp's face at %s is climbed with no rope" % face)
	scarp.set_scaling(true)
	if not scarp.may_step(face + Vector2i.DOWN, face):
		_fail("ladders: a rope does not climb the scarp's face at %s" % face)
	var way := scarp.find_path(scarp.centre_of(face + Vector2i.DOWN), scarp.centre_of(face))
	if way.size() > 3:
		_fail("ladders: with a rope the way up the face at %s still goes round (%d steps)" % [face, way.size()])
	var sold := false
	for area_id: String in ["caravan_ilse", "hamlet_salt"]:
		for person: Dictionary in Database.area(area_id).get("people", []):
			for offer: Dictionary in person.get("talk", {}).get("sells", []):
				sold = sold or str(offer.get("item", "")) == "climbing_rope"
	if not sold or not Gear.is_charm("climbing_rope"):
		_fail("ladders: nobody sells a Climbing Rope, or it is not a charm")


## Herbs on the land ([D335]): the open land grows what its land grows, off the paths and the water,
## the same every time, picked into the packs.
func _check_herbs_on_the_land() -> void:
	var world: World = GameState.world
	var by_land: Dictionary = Database.world_rules.get("herbs_on_land", {}).get("by_land", {})
	# A smith's makings ([D346]) lie on the land the same way, by a roll of their own.
	var makings_by_land: Dictionary = Database.world_rules.get("makings_on_land", {}).get("by_land", {})
	var found := {}
	var looked := 0
	var picked := false
	for y in range(0, world.size.y, 3):
		for x in range(0, world.size.x, 3):
			var tile := Vector2i(x, y)
			if not world.is_walkable(tile) or world.site_at(tile) != null:
				continue
			var slot := GroundGen.slot(world, tile)
			if slot.get("kind") != "ground":
				continue
			looked += 1
			if looked > 160:
				break
			var land := str(slot.get("land", ""))
			var w := int(slot["size"][0])
			var terrain: PackedStringArray = slot["terrain"]
			for prop: Dictionary in slot["props"]:
				var herb := str(prop.get("item", ""))
				if herb == "" or not ["herbs", "redcap", "frostmoss", "ash_stave", "iron_ore"].has(herb):
					continue
				found[herb] = int(found.get(herb, 0)) + 1
				var grows: Array = makings_by_land.get(land, []) if herb in ["ash_stave", "iron_ore"] else by_land.get(land, [])
				if not grows.has(herb):
					_fail("herbs: %s grows on %s, which does not grow it" % [herb, land])
				var on := terrain[int(prop["cell"][1]) * w + int(prop["cell"][0])]
				if ["footpath", "track", "road", "water"].has(on):
					_fail("herbs: %s on %s at %s, on the %s" % [herb, tile, prop["cell"], on])
				if not picked:
					picked = true
					var had := GameState.stores.count(herb)
					var lines := Loot.claim({ "gold": 0, "item": herb }, GameState.roster)
					if GameState.stores.count(herb) != had + 1 or lines.is_empty():
						_fail("herbs: picking %s put nothing in the packs" % herb)
					GameState.stores.erase(herb)
	if found.size() < 2:
		_fail("herbs: only %s growing on %d tiles of the land" % [found, looked])
	if not found.has("ash_stave") and not found.has("iron_ore"):
		_fail("makings: no ash stave or iron ore on %d tiles of the land" % looked)
	print("herbs on the land: %s on %d tiles" % [found, looked])


## Caves on the land ([D282]): some hills have a mouth on their ground, the same ones every time, and
## behind it a place of its own with bands to fight, a cache, and only the way out it came in by.
func _check_caves() -> void:
	var world: World = GameState.world
	var found := Vector2i(-1, -1)
	var hills := 0
	for y in world.size.y:
		for x in world.size.x:
			if world.terrain_id_at(Vector2i(x, y)) != "hill" or not world.is_walkable(Vector2i(x, y)):
				continue
			hills += 1
			if found.x < 0 and Caves.has_cave(world, Vector2i(x, y)) and GroundGen.slot(world, Vector2i(x, y)).get("kind") == "ground":
				found = Vector2i(x, y)
	if found.x < 0:
		_fail("caves: no cave mouth on any of %d hill tiles" % hills)
		return
	if not Caves.has_cave(world, found):
		_fail("caves: a cave mouth moved between two looks")
	var slot := GroundGen.slot(world, found)
	var mouths: Array = (slot.get("buildings", []) as Array).filter(func(b: Dictionary) -> bool: return b.has("cave"))
	if mouths.is_empty():
		_fail("caves: the hill at %s has a cave but no mouth on its ground" % found)
	var id := Caves.area_for(world, found, GameState.party_characters())
	var cave: Dictionary = Database.area(id)
	if cave.has("stairs") or (cave.get("bands", []) as Array).is_empty() or (cave.get("chests", []) as Array).size() != 1:
		_fail("caves: the cave at %s has stairs, no bands or no cache" % found)
	print("  cave at %s: %d bands, cache %s" % [found, (cave.get("bands", []) as Array).size(), str(cave.get("chests", []))])
	await _check_area(id)


## Rises on the land ([D332], after D283): some hill has one, a height up, off the tile's edges and off
## the paths and water, and the ground draws it; every piece of it has a slope; on the land a way up onto
## it goes by a slope and a way down drops straight off.
func _check_rises() -> void:
	var world: World = GameState.world
	var rules: Dictionary = Database.world_rules.get("heights", {}).get("land", {})
	var margin := int(rules.get("margin", 4))
	var looked := 0
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if world.terrain_id_at(tile) != "hill" or not world.is_walkable(tile) or world.site_at(tile) != null:
				continue
			var slot := GroundGen.slot(world, tile)
			if slot.get("kind") != "ground":
				continue
			looked += 1
			if looked > 40:
				break
			var terrain: PackedStringArray = slot["terrain"]
			if not terrain.has("rise"):
				continue
			var w := int(slot["size"][0])
			var h := int(slot["size"][1])
			if int(Database.area_terrain("rise").get("height", 0)) != 1 or not Database.area_terrain("rise").get("walkable", false):
				_fail("heights: higher ground is not a walkable height up")
			var layers: Array = slot["patches"][0]["layers"]
			if not layers.has("rise"):
				_fail("heights: %s has rises but does not draw them (%s)" % [tile, layers])
			var ways: Array = slot.get("ways_up", [])
			var ways_at := {}
			for pair: Array in ways:
				ways_at[Vector2i(int(pair[0]), int(pair[1]))] = true
			for i in terrain.size():
				if terrain[i] != "rise":
					continue
				var at := Vector2i(i % w, i / w)
				if at.x < margin or at.y < margin or at.x >= w - margin or at.y >= h - margin:
					_fail("heights: a rise on %s comes to the tile's edge at %s" % [tile, at])
					return
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var near := terrain[(at.y + dy) * w + at.x + dx]
						if ["footpath", "track", "road"].has(near) or near.ends_with("liquid") or near == "water":
							_fail("heights: a rise on %s at %s touches %s" % [tile, at, near])
							return
			# Every piece of higher ground has a slope on it.
			var seen := {}
			for i in terrain.size():
				var start := Vector2i(i % w, i / w)
				if terrain[i] != "rise" or seen.has(start):
					continue
				var piece: Array[Vector2i] = [start]
				seen[start] = true
				var has_way := false
				while not piece.is_empty():
					var at: Vector2i = piece.pop_back()
					has_way = has_way or ways_at.has(at)
					for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
						var n := at + side
						if n.x >= 0 and n.y >= 0 and n.x < w and n.y < h and not seen.has(n) and terrain[n.y * w + n.x] == "rise":
							seen[n] = true
							piece.append(n)
				if not has_way:
					_fail("heights: a rise on %s at %s has no slope" % [tile, start])
					return
			# On the land: up only by a slope, down anywhere.
			var land := Land.around(world, tile, 0) as Land
			var origin := tile * land.slot
			var top := Vector2i(-1, -1)
			var foot := Vector2i(-1, -1)
			for i in terrain.size():
				var at := Vector2i(i % w, i / w)
				if terrain[i] == "rise" and not ways_at.has(at) and at.y + 1 < h and terrain[(at.y + 1) * w + at.x] != "rise" \
						and land.is_walkable(origin + at) and land.is_walkable(origin + at + Vector2i.DOWN):
					top = origin + at
					foot = origin + at + Vector2i.DOWN
					break
			if top.x >= 0:
				_expect(land.has_heights() and not land.may_step(foot, top) and land.may_step(top, foot), "heights: the land's rise on %s is climbed without a slope, or cannot be dropped off" % tile)
				var up := land.find_cell_path(foot, top)
				var legal := up.size() >= 2
				for i in range(1, up.size()):
					legal = legal and land.may_step(land.cell_at(up[i - 1]), land.cell_at(up[i]))
				_expect(legal and up.size() > 2, "heights: a way up the land's rise on %s does not go by a slope (%d steps)" % [tile, up.size()])
				_expect(land.find_cell_path(top, foot).size() == 2, "heights: the way down off the land's rise on %s is not one step" % tile)
			print("  rises on %s: %d cells, %d slopes; walked up and off on the land: %s" % [tile, terrain.count("rise"), ways.size(), top.x >= 0])
			return
	_fail("heights: none of %d hill grounds has a rise" % looked)


func _check_building(area_id: String, map: AreaMap, building: Dictionary) -> void:
	var who: String = building.get("name", "a house")
	var door: Vector2i = building["door"]
	if not AreaMap.footprint(building).has_point(door):
		_fail("%s: the door of %s is not on it" % [area_id, who])
	if not map.is_walkable(door):
		_fail("%s: the door of %s cannot be reached" % [area_id, who])
	# A house nobody can go into says so in its own words (`shut`); any other door leads somewhere.
	if not Database.has_area(building.get("area", "")) and building.get("area", "") != "coliseum" \
			and not building.has("shut") and not building.has("fight"):
		_fail("%s: %s has no inside to walk into" % [area_id, who])
	# A door into a sparring fight names opponents who exist.
	for foe: Dictionary in building.get("fight", {}).get("enemies", []):
		if Database.unit_template(str(foe.get("unit", ""))).is_empty():
			_fail("%s: %s sends you to fight '%s', who has no unit template" % [area_id, who, foe.get("unit", "")])
	if map.step_out_of(building) == door:
		_fail("%s: coming out of %s puts you back in the doorway" % [area_id, who])
	for cell: Vector2i in map.spots:
		if map.building_at(cell) == building:
			_fail("%s: a spot is buried under %s" % [area_id, who])
	for cell: Vector2i in map.chests:
		if map.building_at(cell) == building:
			_fail("%s: a chest is buried under %s" % [area_id, who])


## Standing on a door should hand play to the area behind it, and leave a way back.
func _walk_in(scene: Node, map: AreaMap) -> void:
	var doors := map.buildings.filter(func(b: Dictionary) -> bool: return str(b.get("area", "")) != "")
	if doors.is_empty():
		return
	var building: Dictionary = doors[0]
	_requests.clear()
	scene.call("_arrive_at", building["door"])
	if _requests.is_empty() or _requests[0]["key"] != "area":
		_fail("%s: the door of %s opens on nothing" % [map.id, building.get("name", "a house")])
		return
	var payload: Dictionary = _requests[0]["payload"]
	if payload.get("area_id", "") != building.get("area", ""):
		_fail("%s: the door leads to '%s'" % [map.id, payload.get("area_id", "")])
	var back: Dictionary = payload.get("return_payload", {})
	if back.get("area_id", "") != map.id:
		_fail("%s: there is no way back out of %s" % [map.id, building.get("name", "a house")])
	if AreaMap.to_cell(back.get("spawn_cell", [])) == Vector2i(building["door"]):
		_fail("%s: leaving %s drops you straight back inside" % [map.id, building.get("name", "a house")])
	scene.set("_leaving", false)


## Walking onto an exit should hand play back to the scene that sent us here.
func _walk_out(scene: Node, map: AreaMap) -> void:
	_requests.clear()
	scene.call("_arrive_at", map.exits[0])
	if _requests.is_empty() or _requests[0]["key"] != "world":
		_fail("%s: the road out leads nowhere" % map.id)


## Everybody standing about has to be reachable and have something to say.
func _check_person(area_id: String, map: AreaMap, person: Dictionary) -> void:
	var cell := AreaMap.to_cell(person.get("cell", [0, 0]))
	var who: String = person.get("name", "someone")
	if not map.is_walkable(cell):
		_fail("%s: %s is standing in a wall" % [area_id, who])
	if Database.unit_template(person.get("unit", "")).is_empty():
		_fail("%s: %s has no unit template to be drawn from" % [area_id, who])

	# Somebody at their work ([D85]) walks to every stop of their rounds from where they stand.
	for stop: Dictionary in person.get("rounds", []):
		var at := AreaMap.to_cell(stop.get("cell", [0, 0]))
		if not map.is_walkable(at) or map.find_cell_path(cell, at).is_empty():
			_fail("%s: %s cannot get to their work at %s" % [area_id, who, at])

	var dialogue_id: String = person.get("dialogue", "")
	if person.has("talk"):
		_check_talk(area_id, person)
	elif dialogue_id == "":
		# Background townsfolk are not mute: they mutter as they go about.
		if person.get("chatter", []).is_empty():
			_fail("%s: %s has nothing to say" % [area_id, who])
	elif DialogueScript.nodes(dialogue_id).is_empty():
		_fail("%s: %s has nothing to say" % [area_id, who])
	elif not DialogueScript.nodes(dialogue_id).has(DialogueScript.start_id(dialogue_id)):
		_fail("%s: %s opens on a node that is not there" % [area_id, who])
	for node_id: String in DialogueScript.nodes(dialogue_id):
		_check_replies(area_id, who, dialogue_id, DialogueScript.nodes(dialogue_id)[node_id])

	var cutscene_id: String = person.get("cutscene", "")
	if cutscene_id != "" and Database.cutscene(cutscene_id).is_empty():
		_fail("%s: %s's cutscene '%s' has no beats" % [area_id, who, cutscene_id])


## Every reply and every branch of a check has to land on a real node.
func _check_replies(area_id: String, who: String, dialogue_id: String, node: Dictionary) -> void:
	var nodes := DialogueScript.nodes(dialogue_id)
	var targets: Array[String] = []
	for option: Dictionary in node.get("options", []):
		targets.append(option.get("goto", DialogueScript.END))
		var check: Dictionary = option.get("check", {})
		if not check.is_empty():
			targets.append(check.get("success", DialogueScript.END))
			targets.append(check.get("failure", DialogueScript.END))
	for target in targets:
		if target != DialogueScript.END and not nodes.has(target):
			_fail("%s: %s has a reply going nowhere ('%s')" % [area_id, who, target])


## Pressing talk should stage the meeting and then open the dialogue box.
func _check_talking(scene: Node, area_id: String) -> void:
	var map: AreaMap = scene.get("map")
	if map.people.is_empty():
		return
	# People who seat themselves talk banter, which is checked at the fire.
	if map.people[0].get("dialogue", "") == "":
		return

	_opened.clear()
	var watch := func(id: String) -> void: _opened.append(id)
	EventBus.dialogue_requested.connect(watch)
	scene.call("_speak_to", 0)
	await get_tree().process_frame

	var person: Dictionary = map.people[0]
	var frame := get_tree().get_first_node_in_group(EventBus.CUTSCENE_FRAME_GROUP)
	if person.get("cutscene", "") != "":
		if frame == null:
			_fail("%s: there is no letterbox for a cutscene to play into" % area_id)
		elif not frame.is_open():
			_fail("%s: the bars never came in for the cutscene" % area_id)
		if not _opened.is_empty():
			_fail("%s: the conversation started before the cutscene did" % area_id)

	# The beats run on timers, so wait them out rather than guessing their length.
	var patience := get_tree().create_timer(CUTSCENE_PATIENCE)
	while _opened.is_empty() and patience.time_left > 0.0:
		await get_tree().process_frame
	EventBus.dialogue_requested.disconnect(watch)

	if _opened.is_empty() or _opened[0] != person.get("dialogue", ""):
		_fail("%s: the cutscene never handed over to %s's conversation" % [
			area_id, person.get("name", "someone")
		])
		return
	if frame != null and frame.is_open():
		_fail("%s: the bars were still up when the talking started" % area_id)
	print("%s: %s staged the meeting, then opened '%s'" % [
		area_id, person.get("cutscene", ""), _opened[0]
	])


## The original twelve are people in the world now (D79): each stands in the area
## `data/story_npcs.json` gives them, drawn from their own body, with something to say.
func _check_story_npcs() -> void:
	if Database.story_npcs.size() != 12:
		_fail("story people: %d of the original twelve in story_npcs.json" % Database.story_npcs.size())
	for npc_id: String in Database.story_npcs:
		var npc := Database.story_npc(npc_id)
		var map := AreaMap.load_area(str(npc.get("area", "")))
		if map == null:
			_fail("story people: %s stands in '%s', which is not an area" % [npc_id, npc.get("area", "")])
			continue
		var standing: Array = map.people.filter(func(p: Dictionary) -> bool:
			return p.get("story_npc", "") == npc_id and p.get("unit", "") == npc.get("unit", ""))
		if standing.is_empty():
			_fail("story people: %s is not standing in %s" % [npc_id, map.id])
		elif not standing[0].has("talk"):
			_fail("story people: %s has nothing to talk about" % npc_id)


## Buying from a stall, paying a fox to listen, and a favour from asking to being paid, done the
## way the dialogue box does them: each reply's effects, then the node it leads to.
## Stormreach's builder and its healer ([D176]): Muck Muck stands by the ruined bathhouse and talks
## about building; Sinner mends the whole company for gold while anyone is hurt, takes the money
## once, and with nobody hurt only looks them over, for nothing.
func _check_the_builder_and_the_healer() -> void:
	var map := AreaMap.load_area("city_streets")
	var muck := {}
	var sinner := {}
	for person: Dictionary in map.people:
		match person.get("name", ""):
			"Muck Muck": muck = person
			"Sinner": sinner = person
	if muck.is_empty() or sinner.is_empty():
		_fail("city: Muck Muck or Sinner is missing from the streets")
		return
	if (Talk.build("Muck Muck", muck["talk"], false, 0.5, "met:test")["menu"]["options"] as Array).size() < 3:
		_fail("city: Muck Muck has nothing to be asked")
	var nodes: Dictionary = Talk.build("Sinner", sinner["talk"], false, 0.5, "met:test")
	var hurt: Character = GameState.party_characters()[0]
	hurt.hp = maxi(1, hurt.max_hp() / 3)
	GameState.gold = 1000
	var mend: Dictionary = {}
	for option: Dictionary in DialogueScript.available_options(nodes["menu"]):
		if bool(option.get("heal", false)):
			mend = option
	if mend.is_empty():
		_fail("city: Sinner offers no healing to a hurt company")
		return
	DialogueScript.apply_effects(mend)
	if GameState.party_is_wounded():
		_fail("city: Sinner took the money and nobody was mended")
	if GameState.gold != 1000 - int(mend.get("requires_gold", 0)) or GameState.gold == 1000:
		_fail("city: Sinner's mending cost nothing (%d gold left)" % GameState.gold)
	var whole := DialogueScript.available_options(nodes["menu"])
	if whole.any(func(o: Dictionary) -> bool: return bool(o.get("heal", false))):
		_fail("city: Sinner still asks money to mend a company with nobody hurt")
	if not whole.any(func(o: Dictionary) -> bool: return o.get("goto", "") == "whole"):
		_fail("city: Sinner has nothing to say to a company that is whole")
	hurt.hp = maxi(1, hurt.max_hp() / 3)
	GameState.gold = 0
	if DialogueScript.available_options(nodes["menu"]).any(func(o: Dictionary) -> bool: return bool(o.get("heal", false))):
		_fail("city: Sinner mends a company that cannot pay")
	GameState.heal_party()
	GameState.gold = GameState.DEFAULT_GOLD


## Your own town at the crater ([D251]): nothing is built until a gate is shut; Muck Muck takes the
## gold for a smithy and an infirmary, then a wall; each stands at the crater with its people, clear
## of whatever grew there, and the wall rings it on the land.
func _check_the_crater_town() -> void:
	var town := ["town:smithy", "town:infirmary", "town:wall", "town:begun", "carried:shut"]
	var empty := AreaMap.load_area("home")
	if not empty.buildings.is_empty() or empty.people.size() != 1:
		_fail("crater town: something stands at the crater before anything is built")
	var streets := AreaMap.load_area("city_streets")
	var muck := {}
	for person: Dictionary in streets.people:
		if person.get("name", "") == "Muck Muck":
			muck = person
	GameState.gold = 20000
	var builds := func() -> Array:
		var nodes: Dictionary = Talk.build("Muck Muck", muck["talk"], false, 0.5, "met:test")
		return DialogueScript.available_options(nodes["menu"]).filter(func(o: Dictionary) -> bool:
			return str(o.get("text", "")).begins_with("Build") or str(o.get("text", "")).begins_with("Put a wall"))
	if not (builds.call() as Array).is_empty():
		_fail("crater town: Muck Muck builds before a gate is shut")
	GameState.set_flag("carried:shut")
	var offered: Array = builds.call()
	if offered.size() != 2:
		_fail("crater town: Muck Muck offers %d buildings, not the smithy and the infirmary" % offered.size())
	for option: Dictionary in offered:
		DialogueScript.apply_effects(option)
		var nodes: Dictionary = Talk.build("Muck Muck", muck["talk"], false, 0.5, "met:test")
		DialogueScript.apply_effects(nodes[str(option.get("goto", ""))])
	if not (GameState.has_flag("town:smithy") and GameState.has_flag("town:infirmary")) or GameState.gold != 5000:
		_fail("crater town: paying Muck Muck built nothing (%d gold left)" % GameState.gold)
	GameState.gold = 20000
	var wall: Array = builds.call()
	if wall.size() != 1:
		_fail("crater town: no wall offered once the smithy and infirmary stand")
	GameState.set_flag("town:wall")
	var built := AreaMap.load_area("home")
	if built.buildings.size() != 4 or built.people.size() != 5:
		_fail("crater town: %d buildings and %d people at the crater once all is built" % [built.buildings.size(), built.people.size()])
	for building: Dictionary in built.buildings:
		_check_building("home", built, building)
		for prop: Dictionary in built.props:
			if AreaMap.footprint(building).has_point(prop["cell"]):
				_fail("crater town: %s stands on %s" % [building.get("name", ""), prop.get("art", "")])
	for person: Dictionary in built.people:
		_check_person("home", built, person)
		if built.find_cell_path(built.spawn, AreaMap.to_cell(person.get("cell", [0, 0]))).is_empty():
			_fail("crater town: %s cannot be walked to" % person.get("name", ""))
	# On the land, the wall rings the crater only once it is built.
	GameState.new_game(SEED)
	var home: Site = GameState.world.sites_of_kind(Site.HOME)[0]
	var walls := (GroundGen.slot(GameState.world, home.cell).get("props", []) as Array).filter(func(p: Dictionary) -> bool:
		return str(p.get("art", "")).begins_with("walls/timber"))
	if walls.is_empty() or walls.any(func(p: Dictionary) -> bool: return not p.has("requires")):
		_fail("crater town: the crater's wall is not waiting to be built (%d pieces)" % walls.size())
	for key: String in town:
		GameState.flags.erase(key)
	GameState.gold = GameState.DEFAULT_GOLD
	print("crater town: smithy, infirmary and wall built, %d people" % built.people.size())


## A house in Stormreach ([D252], Ewan's #270 keep 5, from Kenshi): Marta lets room two of the
## Flagon for good, and it is then the company's every night without paying again; with a room kept,
## Steward Hobb sells the narrow house off the east street, whose door then opens on a bed of the
## company's own (a better night than an inn's) and the strongbox.
func _check_a_house_in_stormreach() -> void:
	GameState.new_game(SEED)
	var person_in := func(area_id: String, name: String) -> Dictionary:
		for person: Dictionary in AreaMap.load_area(area_id).people:
			if person.get("name", "") == name:
				return person
		return {}
	var asks := func(person: Dictionary, starts: String) -> Array:
		var nodes: Dictionary = Talk.build(str(person["name"]), person["talk"], false, 0.5, "met:test")
		return DialogueScript.available_options(nodes["menu"]).filter(func(o: Dictionary) -> bool:
			return str(o.get("text", "")).begins_with(starts))
	var take := func(person: Dictionary, option: Dictionary) -> void:
		DialogueScript.apply_effects(option)
		var nodes: Dictionary = Talk.build(str(person["name"]), person["talk"], false, 0.5, "met:test")
		DialogueScript.apply_effects(nodes[str(option.get("goto", ""))])
	var marta: Dictionary = person_in.call("city_tavern", "Marta the Landlady")
	var hobb: Dictionary = person_in.call("city_streets", "Steward Hobb")
	GameState.gold = 40000
	if not (asks.call(hobb, "We keep a room") as Array).is_empty():
		_fail("house: the Steward sells the house to a company with no room in the city")
	var lease: Array = asks.call(marta, "Let us keep room two")
	if lease.size() != 1:
		_fail("house: Marta does not offer to let room two for good")
		return
	take.call(marta, lease[0])
	if not GameState.has_flag("home:room") or GameState.gold != 34000:
		_fail("house: keeping room two set nothing (%d gold left)" % GameState.gold)
	if not (asks.call(marta, "A room for the night") as Array).is_empty():
		_fail("house: Marta still sells a night with room two kept")
	var sale: Array = asks.call(hobb, "We keep a room")
	if sale.size() != 1:
		_fail("house: the Steward does not sell the narrow house once a room is kept")
		return
	take.call(hobb, sale[0])
	if not GameState.has_flag("home:house") or GameState.gold != 11500:
		_fail("house: buying the narrow house set nothing (%d gold left)" % GameState.gold)
	var door := {}
	for building: Dictionary in AreaMap.load_area("city_streets").buildings:
		if building.get("area", "") == "city_house":
			door = building
	if door.is_empty() or not Database.has_area("city_house") or "home:house" not in door.get("area_requires", []):
		_fail("house: the narrow house's door does not wait for it to be bought")

	# Room two: the company's every night, and still theirs once slept in.
	Company.join(GameState.roster, ["juno"])
	var hurt: Character = GameState.party_characters()[0]
	for area_id: String in ["city_tavern", "city_house"]:
		var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
		scene.set("boot_payload", { "area_id": area_id, "return_scene": "world" })
		add_child(scene)
		await get_tree().process_frame
		var bed: Vector2i = scene._your_bed()
		if bed.x < 0 or scene._room_mark == null:
			_fail("house: %s's bed is not the company's" % area_id)
		else:
			var map: AreaMap = scene.map
			if map.find_cell_path(map.cell_at(scene._leader.position), bed + Vector2i.DOWN).is_empty():
				_fail("house: nobody can walk to the bed in %s" % area_id)
			hurt.hp = 1
			hurt.hearth_vigour = 0
			scene._try_the_bed(bed)
			if hurt.current_hp() != hurt.max_hp() or hurt.hearth_vigour < int(Database.area(area_id)["inn"]["vigour"]):
				_fail("house: a night in %s did not patch %s up" % [area_id, hurt.display_name])
			if scene._your_bed().x < 0:
				_fail("house: the bed in %s is let go once slept in" % area_id)
		if area_id == "city_house":
			var boxes: Array = (scene.map.chests.values() as Array).filter(func(c: Dictionary) -> bool: return bool(c.get("stash", false)))
			if boxes.size() != 1:
				_fail("house: no strongbox in the house")
		scene.queue_free()
		await get_tree().process_frame
	GameState.new_game(SEED)
	print("house: room two kept at the Flagon, the narrow house bought, both beds the company's every night")


func _check_trading() -> void:
	var map := AreaMap.load_area("village")
	var hesk := {}
	var fox := {}
	var wat := {}
	for person: Dictionary in map.people:
		match person.get("name", ""):
			"Hesk the Stallholder": hesk = person
			"a fox in a stolen hat": fox = person
			"Wat the Village Idiot": wat = person
	if hesk.is_empty() or fox.is_empty() or wat.is_empty():
		_fail("village: Hesk, the fox or Wat is missing")
		return

	var nodes: Dictionary = Talk.build("Hesk", hesk["talk"], false, 0.5, "met:test")
	var loaf: Dictionary = {}
	for option: Dictionary in nodes["shop"]["options"]:
		if str(option.get("text", "")).begins_with("Loaf"):
			loaf = option
	# D353: each ware carries its picture, and the loaf has one to show.
	if str(loaf.get("icon_item", "")) != "bread" or Gear.icon("bread") == null:
		_fail("village: the loaf for sale has no picture beside it (%s)" % [loaf.get("icon_item", "")])
	GameState.gold = 100
	var stores := GameState.stores.size()
	DialogueScript.apply_effects(loaf)
	DialogueScript.apply_effects(nodes[loaf.get("goto", "")])
	if GameState.gold != 100 - int(loaf.get("requires_gold", 0)) or GameState.gold == 100:
		_fail("village: buying a loaf did not take the money (%d gold left)" % GameState.gold)
	if GameState.stores.size() != stores + 1 or GameState.stores[-1] != "bread":
		_fail("village: the loaf bought never went in the packs")

	nodes = Talk.build("fox", fox["talk"], false, 0.5, "met:test")
	if not nodes.has("door"):
		_fail("village: the fox talked without being paid")
	else:
		var coin: Dictionary = nodes["door"]["options"][0]
		DialogueScript.apply_effects(coin)
		DialogueScript.apply_effects(nodes[coin["goto"]])
		if not GameState.has_flag("fox:paid") or Talk.build("fox", fox["talk"], false, 0.5, "met:test").has("door"):
			_fail("village: a paid fox still would not talk")

	var job: Dictionary = wat["talk"]["job"]
	nodes = Talk.build("Wat", wat["talk"], false, 0.5, "met:test")
	DialogueScript.apply_effects(nodes["job_offer"]["options"][0])
	if not GameState.has_flag(job["flag"]):
		_fail("village: taking Wat's job did not mark it taken")
	var hand_over: Array = DialogueScript.available_options(nodes["job_check"])
	if hand_over.any(func(o: Dictionary) -> bool: return o.get("goto", "") == "job_paid"):
		_fail("village: Wat paid out before the stone was found")
	GameState.set_flag(job["done_flag"])
	var before := GameState.gold
	DialogueScript.apply_effects(nodes["job_paid"])
	if GameState.gold != before + int(job["gold"]) or not GameState.has_flag(job["flag"] + ":paid"):
		_fail("village: finishing Wat's job did not pay")
	print("village: bought a loaf, paid the fox, found Wat's stone")


## The tutorial (D73): every step points at something in its village, it never saves, it starts
## on its first step, and doing what a step asks moves it on.
func _check_tutorial() -> void:
	var rules: Variant = SaveFile.read("res://data/tutorial.json")
	if typeof(rules) != TYPE_DICTIONARY or (rules as Dictionary).get("steps", []).is_empty():
		_fail("tutorial: data/tutorial.json has no steps")
		return
	var village := FileAccess.get_file_as_string("res://data/areas/%s.json" % rules.get("area", ""))
	var map := AreaMap.load_area(str(rules.get("area", "")))
	if map == null:
		_fail("tutorial: its area '%s' does not exist" % rules.get("area", ""))
		return
	var names: Array = map.people.map(func(p: Dictionary) -> String: return str(p.get("name", "")))
	for step: Dictionary in rules["steps"]:
		var done: Dictionary = step.get("done", {})
		var did := str(done.get("did", ""))
		if did.begins_with("talked:") and not names.has(did.trim_prefix("talked:")):
			_fail("tutorial: step '%s' wants a word with %s, who is not in the village" % [step.get("id", ""), did])
		var flag := str(done.get("flag", ""))
		if flag != "" and not village.contains('"%s' % flag.trim_suffix(":paid")):
			_fail("tutorial: step '%s' waits on flag %s, which nothing in the village sets" % [step.get("id", ""), flag])
		if done.is_empty():
			_fail("tutorial: step '%s' can never be done" % step.get("id", ""))

	var had_save := GameState.has_save()
	var before := FileAccess.get_file_as_string(GameState.SAVE_PATH) if had_save else ""
	var guide: Node = TutorialGuide.new()
	add_child(guide)
	_requests.clear()
	guide.call("start")
	if not GameState.rehearsing:
		_fail("tutorial: the run it started is not marked a rehearsal")
	if _requests.is_empty() or str(_requests[-1]["payload"].get("area_id", "")) != str(rules["area"]):
		_fail("tutorial: it did not open its village")
	GameState.save()
	GameState.reached(RunMode.REST, "tutorial")
	if GameState.has_save() != had_save or (had_save and FileAccess.get_file_as_string(GameState.SAVE_PATH) != before):
		_fail("tutorial: a save was written during the tutorial")
	if guide.call("step_id") != "walk":
		_fail("tutorial: it did not start on its first step (on '%s')" % guide.call("step_id"))
	if (rules["steps"] as Array).size() > 8:
		_fail("tutorial: %d steps, more than the 7 or so D300 cut it to" % (rules["steps"] as Array).size())
	EventBus.player_did.emit("walked")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.2).timeout
	EventBus.player_did.emit("talked:Maren the Guide")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.2).timeout
	GameState.set_flag("tut:asked")
	await get_tree().create_timer(TutorialGuide.DONE_PAUSE + 0.4).timeout
	if guide.call("step_id") != "buy":
		_fail("tutorial: walking, talking and asking did not bring it to buying (on '%s')" % guide.call("step_id"))
	EventBus.scene_changed.emit("title")
	if guide.call("is_running"):
		_fail("tutorial: it kept running after the title came back")
	guide.queue_free()
	GameState.new_game(SEED)
	if GameState.rehearsing:
		_fail("tutorial: a new run after it was still a rehearsal")
	print("tutorial: %d steps, never saved, walked through to '%s'" % [rules["steps"].size(), "buy"])


## Atlas's last stand (D191): its last step calls out a band Atlas cannot beat; when that fight
## ends he is written into the record of the fallen as the first world that ended, the fall is
## told, and the quiz picks who comes next. Played again once he has fallen it writes nothing and
## goes back to the title; skipped, he still falls. Uses its own copies of the record and of the
## settings, never the player's.
func _check_last_stand() -> void:
	var rules: Dictionary = SaveFile.read("res://data/tutorial.json")
	var last: Dictionary = rules["steps"][-1]
	if not bool(last.get("doom", false)):
		_fail("last stand: the tutorial's last step is not the doomed fight")
	var village: Dictionary = SaveFile.read("res://data/areas/%s.json" % rules["area"])
	var doomed := (village.get("bands", []) as Array).filter(
		func(band: Dictionary) -> bool: return bool(band.get("doomed", false)))
	if doomed.is_empty():
		_fail("last stand: Hearthwick has no doomed band")
	elif not (last.get("on_start", {}).get("set_flag", []) as Array).has(doomed[0].get("requires", "")):
		_fail("last stand: the last step does not call the doomed band out")

	var record_was := Sixteen.path
	var settings_was: String = TutorialGuide.settings_path
	Sixteen.path = "user://earth-kings.sixteen.last-stand-test.json"
	TutorialGuide.settings_path = "user://settings.last-stand-test.cfg"
	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))

	# The first time: played through, Atlas falls and is written down.
	var guide: Node = TutorialGuide.new()
	add_child(guide)
	guide.call("start")
	guide.call("_show", (rules["steps"] as Array).size() - 1)
	if not GameState.has_flag(str(doomed[0].get("requires", "") if not doomed.is_empty() else "")):
		_fail("last stand: reaching the last step did not call out the band")
	_requests.clear()
	EventBus.player_did.emit("fight_lost")
	await get_tree().create_timer(TutorialGuide.FALL_PAUSE + 0.4).timeout
	var lead := str(rules["lead"])
	if not Sixteen.fallen_heroes().has(lead):
		_fail("last stand: losing the last fight did not write %s down as fallen" % lead)
	var ended: Array = Sixteen.worlds()
	if ended.size() != 1 or not bool(ended[0].get("last_stand", false)) or str(ended[0].get("hero", "")) != lead:
		_fail("last stand: the world that ended is not Atlas's last stand (%s)" % [ended])
	elif int(ended[0].get("base_seed", 0)) == int(rules["seed"]):
		_fail("last stand: the worlds after it would be built on the last stand's own seed, the same for everyone")
	if not guide.call("is_telling_the_fall"):
		_fail("last stand: the fall was not told")
	if not TutorialGuide.finished_once():
		_fail("last stand: finishing it was not remembered")
	guide.call("_after_the_fall")
	if _requests.is_empty() or _requests[-1]["key"] != "temper_quiz" or not bool(_requests[-1]["payload"].get("opening", false)):
		_fail("last stand: after the fall it did not go to the quiz and the opening")
	elif not (_requests[-1]["payload"].get("fallen_heroes", []) as Array).has(lead):
		_fail("last stand: the quiz could still pick Atlas")
	if FirstHour.first_life() != "":
		_fail("last stand: after it, New Game would still be Atlas (%s)" % FirstHour.first_life())
	if not Sixteen.first_life():
		_fail("last stand: the run after it is not the player's first life (where they land, the first gate)")
	if FirstHour.challenger("janus") != 1:
		_fail("last stand: the floor 5 keeper would count the next lead as challenger %d, not the first" % FirstHour.challenger("janus"))
	guide.queue_free()

	# The next world is built from his, with his echo in it.
	GameState.new_game(SEED, "janus")
	Siblings.arrive(GameState.world, GameState.roster, Sixteen.worlds())
	if Siblings.echo_of(GameState.world, lead).is_empty():
		_fail("last stand: the next world has no echo of Atlas")

	# Played again: nothing more is written, and it ends at the title.
	guide = TutorialGuide.new()
	add_child(guide)
	guide.call("start")
	guide.call("_show", (rules["steps"] as Array).size() - 1)
	_requests.clear()
	EventBus.player_did.emit("fight_won")
	await get_tree().create_timer(TutorialGuide.FALL_PAUSE + 0.4).timeout
	if Sixteen.worlds().size() != 1:
		_fail("last stand: a replay wrote another world down")
	guide.call("_after_the_fall")
	if _requests.is_empty() or _requests[-1]["key"] != "title":
		_fail("last stand: a replay did not end at the title")
	guide.queue_free()

	# Skipped: he still falls, once.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Sixteen.path))
	TutorialGuide.skip_it()
	TutorialGuide.skip_it()
	if Sixteen.worlds().size() != 1 or not bool(Sixteen.worlds()[0].get("last_stand", false)):
		_fail("last stand: skipping it did not write Atlas's fall down once (%s)" % [Sixteen.worlds()])

	for each in [Sixteen.path, TutorialGuide.settings_path]:
		if FileAccess.file_exists(each):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(each))
	Sixteen.path = record_was
	TutorialGuide.settings_path = settings_was
	EventBus.scene_changed.emit("title")
	GameState.new_game(SEED)
	print("last stand: Atlas falls once, the quiz is next, a replay writes nothing, a skip still falls")


## By the fire ([D346]): standing at a camp's fire the party screen can brew a fire's recipes; walked
## away from it, it cannot; out of the place, nobody is by a fire.
func _check_by_the_fire() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "camp" })
	add_child(scene)
	for i in 10:
		await get_tree().process_frame
	var map: AreaMap = scene.get("map")
	var leader: Node2D = scene.get("_leader")
	if leader == null or map.fire.x < 0:
		_fail("hearth: the camp has no fire or no lead")
	else:
		leader.position = map.centre_of(map.fire + Vector2i(0, 2))
		scene.call("_mark_the_hearth")
		var by := GameState.at_hearth
		leader.position = map.centre_of(Vector2i(1, map.height - 2) if map.fire.x > 6 else Vector2i(map.width - 2, map.height - 2))
		scene.call("_mark_the_hearth")
		if not by or GameState.at_hearth:
			_fail("hearth: two cells from the camp's fire is %s, far off is %s" % [by, GameState.at_hearth])
	scene.queue_free()
	await get_tree().process_frame
	if GameState.at_hearth:
		_fail("hearth: still by the fire after leaving the camp")


## The tutorial's sparring pair (D75): not in the village until the fight step calls it, then
## standing there with its red ground, never on top of the party; a step into the red starts a
## practice fight on that ground (nobody can die, nothing counted) that comes back to the village,
## and the pair does not stand there again.
func _check_practice_band() -> void:
	GameState.new_game(SEED, "atlas", true)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "tutorial", "return_scene": "title" })
	add_child(scene)
	for i in 10:
		await get_tree().process_frame
	var watches: Array = scene.get("_watches")
	_expect_tut(watches.is_empty(), "the sparring pair was in the village before the fight step called it")
	GameState.set_flag("tut:spar_ready")
	scene.call("_post_practice_bands")
	watches = scene.get("_watches")
	_expect_tut(watches.size() == 1, "calling the sparring pair out did not put it in the village (%d)" % watches.size())
	if watches.size() != 1:
		scene.queue_free()
		return
	var watch: Node2D = watches[0]
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene.get("_leader").position)
	_expect_tut(not watch.watched.has(at), "the sparring pair was put down already looking at the party")
	var into: Vector2i = (watch.watched as Dictionary).keys()[0]
	_requests.clear()
	scene.call("_check_the_watch", at)
	scene.get("_leader").position = map.centre_of(into)
	_expect_tut(scene.call("_check_the_watch", into), "stepping into the sparring pair's red was not seen")
	var waited := 0.0
	while waited < 3.0 and scene.get("_fight") == null:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	# Fought where it was met (step 4 of the First Hour): put down on the village's own ground, with
	# no change of scene.
	var fight: Node2D = scene.get("_fight")
	_expect_tut(fight != null, "the sparring pair did not start a fight")
	_expect_tut(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "skirmish"),
		"the sparring fight changed the screen instead of being fought on the village ground")
	if fight != null:
		var payload: Dictionary = fight.get("boot_payload")
		_expect_tut(bool(payload.get("sandbox", false)), "the sparring fight is not practice: someone could die in it")
		_expect_tut(not (payload.get("field", {}) as Dictionary).is_empty(), "the sparring fight is not on the village's own ground")
		_expect_tut(bool(fight.get("in_place")) and fight.get_parent() == scene, "the sparring fight is not laid on the village")
		_expect_tut(not bool(fight.get("paused")), "the sparring fight opened paused")
		# Sent off the edge of the field, the party gets clear: over, neither won nor lost, and the
		# fight goes while the party walks on from where it stood.
		fight.set_process(false)
		fight.call("_select", fight.call("party_fighters"))
		fight.call("_make_for_the_edge", Vector2i(-3, 1))
		for i in 6000:
			if bool(fight.get("over")):
				break
			fight.call("tick")
		_expect_tut(bool(fight.get("over")) and bool(fight.get("fled_field")), "walking off the field's edge did not get the party clear")
		waited = 0.0
		while waited < 3.0 and scene.get("_fight") != null:
			await get_tree().create_timer(0.1).timeout
			waited += 0.1
		_expect_tut(scene.get("_fight") == null and not bool(scene.get("_leaving")), "the village did not carry on after the sparring fight")
		_expect_tut(GameState.has_flag("tut:sparred"), "the sparring pair would stand there again after the fight")
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("tutorial: the sparring pair came out when called, was walked into, and sparred on the village ground")


## A floor of the Tower is walked (D102): its band is fought for real on its own ground, and
## standing on the stair up wins the floor, paid out by the continent as a won Tower fight.
## D248 (play-test 6): a gate gone into is walked. Every kind of gate lays out a floor that loads,
## whose way down can be walked to from the doorway past every band; the floor's bands are held and
## fought where they stand, with the Guild's people beside the party; the way down goes on to the
## next floor, and on the last floor it stays shut until the keeper is down, then shuts the gate.
func _check_inside_a_gate() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var party := GameState.party_characters()
	var kinds := {}
	var deep: Site = null
	for site: Site in world.sites_of_kind(Site.GATE):
		var look := str(site.data.get("area", ""))
		if site.floors() >= 2 and (deep == null or site.floors() < deep.floors()):
			deep = site
		if kinds.has(look):
			continue
		kinds[look] = true
		for depth in [0, site.floors() - 1]:
			var id := GateInside.area_for(world, site, depth, party)
			var map := AreaMap.load_area(id)
			_expect(map != null, "inside a gate: %s floor %d does not load" % [site.display_name, depth + 1])
			if map == null:
				continue
			_expect(map.width * map.height >= 34 * 26, "inside a gate: %s floor %d is only %dx%d" % [site.display_name, depth + 1, map.width, map.height])
			for sheet: String in map.layers:
				_expect(not Database.tileset_sheet(sheet).is_empty(), "inside a gate: %s has no ground sheet '%s'" % [look, sheet])
			_expect(map.stairs.size() == 2 and map.find_cell_path(map.spawn, map.stairs[0]).size() > 1,
				"inside a gate: %s floor %d has no way from the doorway to the way down" % [site.display_name, depth + 1])
			_expect(map.is_walkable(map.exits[1]) and map.is_exit(map.exits[1]),
				"inside a gate: %s floor %d has no way back out" % [site.display_name, depth + 1])
			_expect(map.bands.size() >= 1, "inside a gate: nobody holds %s floor %d" % [site.display_name, depth + 1])
			var keepers := 0
			for band: Dictionary in map.bands:
				var at: Array = band.get("at", [0, 0])
				_expect(bool(band.get("held", false)), "inside a gate: %s is not held" % band.get("key", ""))
				_expect(map.find_cell_path(map.spawn, Vector2i(int(at[0]), int(at[1]))).size() > 1,
					"inside a gate: %s stands where nobody can walk to" % band.get("key", ""))
				if bool(band.get("boss", false)):
					keepers += 1
			_expect(keepers == (1 if depth == site.floors() - 1 else 0),
				"inside a gate: %s floor %d has %d keepers" % [site.display_name, depth + 1, keepers])
			# The same floor of the same gate is laid out the same way.
			_expect(GateInside.layout(world, site, depth, party)["rows"] == Database.area(id)["rows"],
				"inside a gate: %s floor %d is laid out differently a second time" % [site.display_name, depth + 1])
	if deep == null:
		_fail("inside a gate: no gate deeper than one floor")
		return

	# The first floor: a band fought where it stands, with the Guild's people; the way down goes on.
	var ally := { "unit": "keep_watchman", "level": 3, "name": "a Guild blade" }
	var first: Node = load("res://src/area/area_scene.tscn").instantiate()
	first.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, 0, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": 0, "gate_final": false, "allies": [ally],
	})
	add_child(first)
	for i in 10:
		await get_tree().process_frame
	var map: AreaMap = first.get("map")
	var watches: Array = first.get("_watches")
	_expect(watches.size() == map.bands.size(), "inside a gate: %d of %d bands stand on the floor" % [watches.size(), map.bands.size()])
	if not watches.is_empty():
		var watch: Node2D = watches[0]
		var into: Vector2i = (watch.watched as Dictionary).keys()[0]
		first.call("_check_the_watch", map.cell_at(first.get("_leader").position))
		first.get("_leader").position = map.centre_of(into)
		first.call("_check_the_watch", into)
		var waited := 0.0
		while waited < 3.0 and first.get("_fight") == null:
			await get_tree().create_timer(0.05).timeout
			waited += 0.05
		var fight: Node2D = first.get("_fight")
		_expect(fight != null and bool(fight.get("in_place")), "inside a gate: the band was not fought where it stood")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "gate_band" and GameState.pending_outcome.get("cell") == deep.cell,
			"inside a gate: the band's fight is not settled as the gate's (%s)" % GameState.pending_outcome)
		if fight != null:
			var field: Dictionary = (fight.get("boot_payload") as Dictionary).get("field", {})
			_expect((field.get("allies", []) as Array).any(func(a: Dictionary) -> bool: return str(a.get("name", "")) == "a Guild blade"),
				"inside a gate: the Guild's people did not fight beside the party")
			fight.set_process(false)
	first.queue_free()
	await get_tree().process_frame
	GameState.pending_outcome = {}
	_requests.clear()
	var again: Node = load("res://src/area/area_scene.tscn").instantiate()
	again.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, 0, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": 0, "gate_final": false,
	})
	add_child(again)
	for i in 10:
		await get_tree().process_frame
	var down: AreaMap = again.get("map")
	(again.get("_leader") as Node2D).position = down.centre_of(down.stairs[0] + Vector2i(0, 1))
	# D261 (play-test 7): every band on the floor first, then the way down.
	_expect(str(again.call("_prompt_text")).contains("will not open"), "inside a gate: the way down is open with the floor's bands standing (%s)" % again.call("_prompt_text"))
	_expect(again.call("_keeper_cell") != Vector2i(-1, -1), "inside a gate: Auto would not know which band to go for first")
	for band: Dictionary in down.bands:
		GameState.set_flag("done:%s" % str(band.get("key", "")))
	_expect(str(again.call("_prompt_text")).ends_with("to go down to floor 2 of %d" % deep.floors()),
		"inside a gate: at the way down nothing says how to take it (%s)" % again.call("_prompt_text"))
	again.call("_climb_the_stair")
	var on: Array = _requests.filter(func(r: Dictionary) -> bool: return r["key"] == "world")
	_expect(not on.is_empty() and bool((on[0]["payload"] as Dictionary).get("gate_on", false)), "inside a gate: the way down went nowhere")
	_expect(str(GameState.pending_outcome.get("kind", "")) == "gate" and not bool(GameState.pending_outcome.get("final", true))
			and bool(GameState.pending_outcome.get("walked", false)) and GameState.has_flag("last_victory"),
		"inside a gate: the way down did not win the floor (%s)" % GameState.pending_outcome)
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	again.queue_free()
	await get_tree().process_frame

	# The last floor: shut until its keeper falls, and then the way out shuts the gate.
	var last := deep.floors() - 1
	var keeper := GateInside.keeper_flag(deep, last)
	_requests.clear()
	var bottom: Node = load("res://src/area/area_scene.tscn").instantiate()
	bottom.set("boot_payload", {
		"area_id": GateInside.area_for(world, deep, last, party), "return_scene": "world",
		"gate_cell": [deep.cell.x, deep.cell.y], "gate_depth": last, "gate_final": true, "gate_keeper": keeper,
	})
	add_child(bottom)
	for i in 10:
		await get_tree().process_frame
	var end: AreaMap = bottom.get("map")
	_expect(end.bands.any(func(b: Dictionary) -> bool: return "done:%s" % str(b.get("key", "")) == keeper),
		"inside a gate: the keeper's fall is not what opens the last floor's way down")
	(bottom.get("_leader") as Node2D).position = end.centre_of(end.stairs[0] + Vector2i(0, 1))
	_expect(str(bottom.call("_prompt_text")).contains("will not open"), "inside a gate: the way down is open with its keeper standing (%s)" % bottom.call("_prompt_text"))
	bottom.call("_climb_the_stair")
	_expect(_requests.is_empty() and GameState.pending_outcome.is_empty(), "inside a gate: the last floor was left past its keeper")
	_expect(bottom.call("_keeper_cell") != Vector2i(-1, -1), "inside a gate: Auto would not know where the keeper stands")
	# The keeper's fall scatters the rest of the floor (D261), as a won held fight sets it.
	bottom.set("_held_fight", "won")
	bottom.set("_held_done", keeper)
	bottom.call("_after_held_fight")
	_expect((bottom.get("_watches") as Array).is_empty(), "inside a gate: the rest of the floor stood its ground after the keeper fell")
	_expect(end.bands.all(func(b: Dictionary) -> bool: return GameState.has_flag("done:%s" % str(b.get("key", "")))),
		"inside a gate: the bands that scattered are back the next time")
	_expect(str(bottom.call("_prompt_text")).ends_with("to shut %s" % deep.display_name), "inside a gate: with the keeper down nothing says the gate can be shut (%s)" % bottom.call("_prompt_text"))
	bottom.call("_climb_the_stair")
	_expect(str(GameState.pending_outcome.get("kind", "")) == "gate" and bool(GameState.pending_outcome.get("final", false)),
		"inside a gate: the last floor's way out did not shut the gate")
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	bottom.queue_free()
	await get_tree().process_frame


## Gates that grow (play-test 7, D261): a gate's first floor is the ground of the land round it, every
## kind of ground lays out and draws; the longer the rank, the more floors, chambers and bands, and the
## harder its keeper; a shut gate's mouth has the gate lying broken and folk come to cheer.
func _check_gates_grow() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var party := GameState.party_characters()
	var rules := GateInside.rules()
	for kind: String in rules.get("grounds", {}):
		var look := GateInside.look_of(rules["grounds"][kind])
		for sheet: String in look.get("layers", []):
			_expect(not Database.tileset_sheet(sheet).is_empty(), "gates grow: %s has no ground sheet '%s'" % [kind, sheet])
		for part: String in ["floor", "path", "wall", "cover"]:
			_expect(not Database.area_terrain(str(look.get(part, ""))).is_empty(), "gates grow: %s's %s '%s' is no ground" % [kind, part, look.get(part, "")])
		_expect(not bool(Database.area_terrain(str(look.get("wall", ""))).get("walkable", true)), "gates grow: %s's walls can be walked through" % kind)
	var gates := world.sites_of_kind(Site.GATE)
	for site: Site in gates:
		var expected := str(rules.get("by_area", {}).get(str(site.data.get("area", "")), ""))
		if expected == "":
			expected = str(rules.get("by_land", {}).get(Biome.at(world, site.cell), "cave"))
		var floor_one := GateInside.layout(world, site, 0, party)
		_expect(str(floor_one.get("ground", "")) == str(rules["grounds"][expected].get("name", "")),
			"gates grow: %s's first floor is %s, not the land's %s" % [site.display_name, floor_one.get("ground", ""), expected])
	# The longer the rank, the longer the gate: E one floor, S five, more bands to a floor, a stouter keeper.
	var e_gate: Site = gates[0]
	var old_rank := e_gate.rank
	e_gate.rank = "E"
	var e_floors := e_gate.floors()
	var e_bands := (GateInside.layout(world, e_gate, 0, party)["bands"] as Array).size()
	e_gate.rank = "S"
	var s_floors := e_gate.floors()
	var s_bands := (GateInside.layout(world, e_gate, 0, party)["bands"] as Array).size()
	var s_last: Array = GateInside.layout(world, e_gate, s_floors - 1, party)["bands"]
	var s_keeper: Array = s_last.filter(func(b: Dictionary) -> bool: return bool(b.get("boss", false)))
	_expect(e_floors == 1 and s_floors == 5, "gates grow: an E gate is %d floors and an S gate %d" % [e_floors, s_floors])
	_expect(s_bands >= e_bands + 3, "gates grow: an S gate's floor holds %d bands, an E gate's %d" % [s_bands, e_bands])
	_expect(s_keeper.size() == 1 and float(s_keeper[0].get("stout", 1.0)) >= 3.0, "gates grow: an S gate's keeper is no harder to put down")
	var kinds := {}
	for depth in s_floors:
		kinds[str(GateInside.layout(world, e_gate, depth, party).get("ground", ""))] = true
	_expect(kinds.size() >= 3, "gates grow: an S gate's five floors are all of %d kinds" % kinds.size())
	e_gate.rank = old_rank
	# Shut, its mouth shows it lying broken, and folk come to look.
	var before := GroundGen.slot(world, e_gate.cell)
	world.close_gate(e_gate)
	var after := GroundGen.slot(world, e_gate.cell)
	var art := str(Database.world_rules["gate"]["shut"]["art"])
	_expect(not (before.get("props", []) as Array).any(func(p: Dictionary) -> bool: return str(p.get("art", "")) == art)
			and (after.get("props", []) as Array).any(func(p: Dictionary) -> bool: return str(p.get("art", "")) == art),
		"gates grow: a shut gate does not lie broken where it stood (%s: %s)" % [after.get("kind", ""),
			(after.get("props", []) as Array).map(func(p: Dictionary) -> String: return str(p.get("art", ""))).filter(func(a: String) -> bool: return a.begins_with("landmark"))])
	_expect((after.get("people", []) as Array).size() >= (before.get("people", []) as Array).size() + 3,
		"gates grow: nobody comes to cheer at a shut gate")
	_expect(ResourceLoader.exists("res://art/props/%s.png" % art), "gates grow: the broken gate has no picture")


## Heights on the wind scarp ([D287], [D308]): the shelves are a height up from the bare earth, dropped
## off anywhere and climbed only at a slope; a drop of two hurts everyone; the edges are drawn.
func _check_heights() -> void:
	GameState.new_game(SEED)
	var map := AreaMap.load_area("wild_scarp")
	_expect(map != null and map.has_heights(), "the wind scarp has no heights")
	if map == null:
		return
	_expect(map.height_at(Vector2i(14, 10)) == 0 and map.height_at(Vector2i(6, 3)) == 1, "bare earth is %d up and the shelf %d" % [map.height_at(Vector2i(14, 10)), map.height_at(Vector2i(6, 3))])
	_expect(map.ways_up.size() >= 6 and map.ways_up.has(Vector2i(5, 4)), "the scarp has %d ways up" % map.ways_up.size())
	_expect(not map.may_step(Vector2i(6, 5), Vector2i(6, 4)), "the shelf was climbed where there is no slope")
	_expect(map.may_step(Vector2i(5, 5), Vector2i(5, 4)), "the slope at (5, 4) cannot be climbed")
	_expect(map.may_step(Vector2i(6, 4), Vector2i(6, 5)) and map.drop(Vector2i(6, 4), Vector2i(6, 5)) == 1, "the shelf cannot be dropped off, or the drop is not one")
	_expect(map.may_step(Vector2i(6, 4), Vector2i(7, 4)) and map.drop(Vector2i(6, 4), Vector2i(7, 4)) == 0, "walking along the shelf is not free")
	_expect(map.props.any(func(p: Dictionary) -> bool: return str(p.get("art", "")) == "landmark/slope" and p.get("cell") == Vector2i(5, 4)), "no slope is drawn at (5, 4)")
	var flat := AreaMap.load_area("city_streets")
	_expect(flat != null and not flat.has_heights() and flat.may_step(Vector2i(3, 3), Vector2i(3, 4)), "flat ground has heights")

	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "wild_scarp", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var on: AreaMap = scene.map
	_expect((scene.get("_layers") as Node).get_node_or_null("Ledges") != null, "the shelf edges are not drawn")
	# Walking at the shelf from the bare earth: stopped where there is no slope, up where there is one.
	var foot := on.centre_of(Vector2i(6, 5))
	var up := Vector2(0, -float(AreaMap.CELL))
	var stopped: Vector2 = scene.call("_slide", foot, up)
	_expect(on.cell_at(stopped) == Vector2i(6, 5), "the lead walked up the shelf with no slope, to %s" % on.cell_at(stopped))
	var at_slope := on.centre_of(Vector2i(5, 5))
	var climbed: Vector2 = scene.call("_slide", at_slope, up)
	_expect(on.cell_at(climbed) == Vector2i(5, 4), "the lead could not climb the slope, stays at %s" % on.cell_at(climbed))
	var down: Vector2 = scene.call("_slide", on.centre_of(Vector2i(6, 4)), -up)
	_expect(on.cell_at(down) == Vector2i(6, 5), "the lead could not drop off the shelf")
	# A way found over the scarp (a click, Auto, a band) goes round by a slope, never up the shelf ([D312]).
	var way := on.find_cell_path(Vector2i(6, 5), Vector2i(6, 3))
	var legal := way.size() >= 2
	for i in range(1, way.size()):
		legal = legal and on.may_step(on.cell_at(way[i - 1]), on.cell_at(way[i]))
	_expect(legal and way.any(func(p: Vector2) -> bool: return on.ways_up.has(on.cell_at(p))),
			"the way up the shelf does not go by a slope: %s" % [way.map(func(p: Vector2) -> Vector2i: return on.cell_at(p))])
	var down_way := on.find_cell_path(Vector2i(6, 3), Vector2i(6, 5))
	_expect(down_way.size() == 3, "the way down off the shelf is %d steps, not straight down" % down_way.size())
	scene.get("_leader").position = on.centre_of(Vector2i(6, 5))
	scene.call("_walk_to", on.centre_of(Vector2i(6, 3)))
	_expect((scene.get("_click_path") as Array).size() >= 3, "a click on the shelf did not walk round by the slope")
	(scene.get("_click_path") as Array).clear()
	# With no way up at all, a click on the shelf walks nowhere and is told so, once.
	var ways := on.ways_up.duplicate()
	on.ways_up = {}
	var told_before: int = (scene.get("_ledges_said") as Dictionary).size()
	var notes_were: int = (scene.get("_notes") as Array).size()
	scene.call("_walk_to", on.centre_of(Vector2i(7, 3)))
	scene.call("_walk_to", on.centre_of(Vector2i(7, 3)))
	on.ways_up = ways
	_expect((scene.get("_click_path") as Array).is_empty() and (scene.get("_ledges_said") as Dictionary).size() == told_before + 1
			and (scene.get("_notes") as Array).size() >= notes_were + 1,
			"a click on a shelf with no way up walked, or was not told once")
	# The lead is told why, once: pressed against the shelf's edge, as a blocked walker stands.
	var edge := foot + Vector2(0, -(float(AreaMap.CELL) * 0.5 - 2.0))
	scene.get("_leader").position = edge
	var said_before: int = (scene.get("_ledges_said") as Dictionary).size()
	var notes_before: int = (scene.get("_notes") as Array).size()
	scene.call("_say_the_shelf", edge, up, Vector2.ZERO)
	scene.call("_say_the_shelf", edge, up, Vector2.ZERO)
	_expect((scene.get("_ledges_said") as Dictionary).size() == said_before + 1 and (scene.get("_notes") as Array).size() >= notes_before + 1,
			"walking into the shelf said nothing, or said it twice")
	# A drop of one is free; a drop of two hurts everyone, never below a tenth.
	var party := GameState.party_characters()
	for member: Character in party:
		member.hp = member.max_hp()
	scene.get("_leader").position = on.centre_of(Vector2i(6, 5))
	scene.call("_fall", on.centre_of(Vector2i(6, 4)))
	_expect(party.all(func(c: Character) -> bool: return c.current_hp() == c.max_hp()), "a drop of one hurt")
	var rules: Dictionary = Database.world_rules.get("heights", {})
	var was: Dictionary = Database.area_terrain("raised").duplicate()
	(Database.tilesets["terrains"] as Dictionary)["raised"]["height"] = 2
	scene.call("_fall", on.centre_of(Vector2i(6, 4)))
	(Database.tilesets["terrains"] as Dictionary)["raised"] = was
	_expect(party.all(func(c: Character) -> bool: return c.current_hp() < c.max_hp()), "a drop of two hurt nobody")
	_expect(party.all(func(c: Character) -> bool: return c.current_hp() >= ceili(float(c.max_hp()) * float(rules.get("floor", 0.1)))), "a fall took someone below the floor")
	print("heights: the wind scarp's shelves are %d up, %d slopes; a drop of two costs %.0f%% of everyone's health; a click up the shelf walks %d cells round by the slope" % [
		on.height_at(Vector2i(6, 3)), on.ways_up.size(), float(rules.get("share", 0.15)) * 100.0, way.size() - 1])
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## A story in each wild ([D287], [D314]): three pages on open ground, each said and kept once a run when
## stood on, in any order; the last read says the story's end and writes it in the annals, once.
func _check_wild_stories() -> void:
	GameState.new_game(SEED)
	for area_id: String in ["wild_grove", "wild_thicket", "wild_fen", "wild_oasis", "wild_scarp", "wild_peak",
			"hamlet_fold", "hamlet_mill", "hamlet_salt", "caravan_ilse", "caravan_red"]:
		var map := AreaMap.load_area(area_id)
		var end := str((Database.area(area_id).get("story", {}) as Dictionary).get("end", ""))
		_expect(map != null and map.story_pages.size() == 3 and end != "", "%s has %d pages of its story, or no end" % [area_id, map.story_pages.size() if map != null else 0])
		if map == null:
			continue
		for cell: Vector2i in map.story_pages:
			var clear := map.is_walkable(cell) and not map.chests.has(cell) and not map.exits.has(cell) \
					and not map.people.any(func(p: Dictionary) -> bool: return AreaMap.to_cell(p.get("cell", [0, 0])) == cell)
			_expect(clear and str(map.spots.get(cell, "")) != "", "%s's page at %s is not on open ground with words" % [area_id, cell])
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "wild_grove", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var on: AreaMap = scene.map
	var annals_before: int = GameState.world.annals.size()
	var pages: Array = on.story_pages.keys()
	scene.call("_read_a_page", pages[0])
	scene.call("_read_a_page", pages[1])
	_expect(GameState.has_flag("story:wild_grove:%d:%d" % [pages[0].x, pages[0].y]) and not GameState.has_flag("story:wild_grove:told")
			and GameState.world.annals.size() == annals_before, "two pages told the whole story, or were not kept")
	scene.call("_read_a_page", pages[2])
	var told := str(Database.world_rules.get("wilds", {}).get("story_annals", "{wild}: {end}")).format(
			{ "wild": on.display_name.left(1).to_upper() + on.display_name.substr(1), "end": str((Database.area("wild_grove").get("story", {}) as Dictionary).get("end", "")) })
	_expect(GameState.has_flag("story:wild_grove:told") and GameState.world.annals.size() == annals_before + 1
			and (scene.get("_notes") as Array).has(told), "the last page did not tell the story's end, or did not write it")
	scene.call("_read_a_page", pages[2])
	scene.call("_read_a_page", pages[0])
	_expect(GameState.world.annals.size() == annals_before + 1, "a story was written twice")
	print("wild stories: five wilds, three pages each; %s" % told)
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## A band keeps its shape on the ground ([D315], [D320]): the guard of a wild, three figures, walks in a
## wedge round the one in front, each figure at its slot where the slot can be stood on, else on the trail.
func _check_band_shape_on_the_ground() -> void:
	GameState.new_game(SEED)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "wild_grove", "return_scene": "world" })
	add_child(scene)
	for i in 3:
		await get_tree().process_frame
	var watch: Node2D = null
	for each: Node2D in scene.get("_watches"):
		if (each.get("figures") as Array).size() >= 3:
			watch = each
	_expect(watch != null, "the grove has no band of three figures on its ground")
	if watch == null:
		scene.queue_free()
		return
	var figures: Array = watch.get("figures")
	var slots: Dictionary = watch.get("_slots")
	_expect(slots.size() == figures.size() - 1 and not slots.has(0), "a band of %d has %d slots" % [figures.size(), slots.size()])
	var map: AreaMap = scene.get("map")
	var open := Vector2i(-1, -1)
	for y in range(2, map.height - 2):
		for x in range(2, map.width - 2):
			var fine := true
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					fine = fine and map.is_walkable(Vector2i(x + dx, y + dy)) and watch.region.has_point(Vector2i(x + dx, y + dy))
			if fine and open.x < 0:
				open = Vector2i(x, y)
	_expect(open.x >= 0, "no open ground to walk the band on")
	if open.x >= 0:
		watch.set("_lead_at", map.centre_of(open))
		watch.call("_walk_the_figures", Vector2.RIGHT, 100000.0)
		var spacing := float(Formations.foe_rules().get("ground_spacing", 40.0))
		var in_place := 0
		for i in range(1, figures.size()):
			var want: Vector2 = Formations.point_for(slots[i], map.centre_of(open), Vector2.RIGHT, spacing)
			if (figures[i] as Node2D).position.distance_to(want) < 1.0:
				in_place += 1
		_expect(in_place == figures.size() - 1, "%d of %d figures stand in the band's shape" % [in_place, figures.size() - 1])
		_expect(Formations.point_for(slots[1], Vector2.ZERO, Vector2.RIGHT, spacing) != Vector2.ZERO, "a slot sits on the one in front")
	print("band shape: %s walks as a %s of %d on the ground" % [watch.band.get("label", "a band"), Formations.word(Formations.auto_for(figures.size())), figures.size()])
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## The Tower past floor 10 ([D290], [D307]): a floor from 11 up is laid out at the climb, the higher
## the bigger, its stair reachable from the way in and a band of its own in every chamber but the
## first; every third floor from 12 is shared with a company who fight beside the party; from 25
## every fifth has people living by the stair.
func _check_tower_grows() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	_expect(TowerFloors.is_grown(11) and not TowerFloors.is_grown(10), "floor 11 does not grow, or floor 10 does")
	_expect(Chapters.walked_floor_area(12) == TowerFloors.grown_area_id(12), "the stair below does not know floor 12's id")
	_expect(Chapters.borrows_a_plan(12), "a grown floor's bands would not be restocked")
	var small := TowerFloors.grown_size(12)
	var big := TowerFloors.grown_size(60)
	_expect(big.x > small.x and big.y > small.y and big.x <= 60 and big.y <= 44, "floors do not grow with height: %s then %s" % [small, big])
	var party := GameState.party_characters()
	for floor in [11, 12, 25, 100]:
		var id := TowerFloors.ensure_grown(world, floor)
		var area := Database.area(id)
		var rows: Array = area.get("rows", [])
		var height := rows.size()
		var width := str(rows[0]).length() if height > 0 else 0
		_expect(height >= 18 and width >= 26, "floor %d is %d by %d" % [floor, width, height])
		var stairs: Array = area.get("stairs", [])
		var spawn: Array = area.get("spawn", [])
		_expect(stairs.size() == 2 and spawn.size() == 2 and (area.get("exits", []) as Array).size() == 3, "floor %d has no stair, spawn or way out" % floor)
		# Everywhere worth going is reached from the way in.
		var open := func(c: Vector2i) -> bool:
			return c.y >= 0 and c.y < height and c.x >= 0 and c.x < width and str(rows[c.y])[c.x] != "A"
		var seen := {}
		var queue: Array = [Vector2i(int(spawn[0]), int(spawn[1]))]
		seen[queue[0]] = true
		while not queue.is_empty():
			var at: Vector2i = queue.pop_front()
			for step in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = at + step
				if open.call(next) and not seen.has(next):
					seen[next] = true
					queue.append(next)
		_expect(seen.has(Vector2i(int(stairs[0][0]), int(stairs[0][1]))), "floor %d's stair cannot be reached from the way in" % floor)
		var bands: Array = area.get("bands", [])
		_expect(bands.size() >= 2, "floor %d has %d bands" % [floor, bands.size()])
		for band: Dictionary in bands:
			var at: Array = band.get("at", [0, 0])
			_expect(seen.has(Vector2i(int(at[0]), int(at[1]))), "floor %d's band %s stands where nobody can reach" % [floor, band.get("key", "")])
			_expect(str(band.get("key", "")).begins_with("tower%d_" % floor), "floor %d's band is called %s" % [floor, band.get("key", "")])
		var props: Array = area.get("props", [])
		var stair_props := props.filter(func(p: Dictionary) -> bool: return str(p.get("art", "")) == "tower_inside/stair_up").size()
		var runes := props.filter(func(p: Dictionary) -> bool: return str(p.get("art", "")).begins_with("tower_inside/rune_")).size()
		_expect(stair_props == 2 and runes >= 4, "floor %d is dressed with %d stair halves and %d runes" % [floor, stair_props, runes])
		var restocked := TowerFloors.restock(bands, world, floor, party, [Vector2i(int(stairs[0][0]), int(stairs[0][1]))])
		_expect(restocked.size() >= 1 and restocked.all(func(b: Dictionary) -> bool: return (b.get("pack", []) as Array).size() >= 2),
				"floor %d's bands were not restocked with the floor's own" % floor)
		if floor == 100:
			_expect(restocked.size() == 1 and bool(restocked[0].get("boss", false)), "the top floor is not kept by its keeper alone")
	# Shared and living floors.
	_expect(TowerFloors.is_shared(12) and not TowerFloors.is_shared(11) and TowerFloors.is_shared(15), "the shared floors are not every third from 12")
	var company := TowerFloors.company_with_you(world, 12, party)
	_expect(company.size() >= 2 and company.all(func(a: Dictionary) -> bool: return str(a.get("unit", "")) != "" and int(a.get("level", 0)) >= 1),
			"floor 12's company is %s" % [company])
	_expect(TowerFloors.company_with_you(world, 11, party).is_empty(), "floor 11 has a company on it")
	_expect(TowerFloors.floor_line(world, 12).contains(TowerFloors.company_on(world, 12)), "floor 12's line does not name its company")
	_expect(TowerFloors.is_living(25) and TowerFloors.is_living(30) and not TowerFloors.is_living(26) and not TowerFloors.is_shared(30),
			"the living floors are not 25 and every fifth")
	var living: Array = Database.area(TowerFloors.ensure_grown(world, 25)).get("people", [])
	_expect(living.size() >= 3 and living.all(func(p: Dictionary) -> bool: return not (p.get("talk", {}) as Dictionary).is_empty()),
			"floor 25 has %d people living on it" % living.size())
	# A shared floor's company waits by the way in to talk, and nobody else is there ([CompanyTalk]).
	var by_twelve: Array = Database.area(TowerFloors.grown_area_id(12)).get("people", [])
	var of_the_company := func(p: Dictionary) -> bool:
		return str(p.get("name", "")) == TowerFloors.company_on(world, 12) and str(p.get("_area", "")) == "shared_company" \
				and ((p.get("talk", {}) as Dictionary).get("ask", []) as Array).size() >= 6
	_expect(by_twelve.size() >= 1 and by_twelve.all(of_the_company), "floor 12's people are not its company, ready to talk: %s" % [by_twelve])
	_expect((Database.area(TowerFloors.ensure_grown(world, 11)).get("people", []) as Array).is_empty(), "people stand on floor 11")
	# The rest of a living floor's folk have more to say than the two questions everyone answers.
	if living.size() > 2:
		var folk_asks: Array = (living[2].get("talk", {}) as Dictionary).get("ask", [])
		_expect(folk_asks.size() >= 4, "floor 25's folk have %d things to say" % folk_asks.size())
	# What a living floor offers ([D317]): its first rests the company for coin, its second sells, marked up.
	var host: Dictionary = living[0].get("talk", {}) if living.size() > 0 else {}
	var trader: Dictionary = living[1].get("talk", {}) if living.size() > 1 else {}
	var rest_price := int((host.get("heal", {}) as Dictionary).get("price", 0))
	_expect(living.size() > 0 and rest_price > 0 and str(living[0].get("name", "")) != TowerFloors.company_on(world, 25),
			"floor 25's host rests nobody, or has no name of their own: %s" % [host])
	var wares: Array = trader.get("sells", [])
	var priced := func(w: Dictionary) -> bool: return not Database.equipment_piece(str(w.get("item", ""))).is_empty() and int(w.get("price", 0)) > int(Market.price_of(str(w.get("item", "")))) and bool(w.get("restock", false))
	_expect(wares.size() >= 2 and wares.all(priced), "floor 25's trader sells nothing, or at no mark-up, or once: %s" % [wares])
	_expect(living.size() > 2 and ((living[2].get("talk", {}) as Dictionary).get("sells", []) as Array).is_empty()
			and ((living[2].get("talk", {}) as Dictionary).get("heal", {}) as Dictionary).is_empty(), "everyone on floor 25 sells or heals")
	print("tower grows: floor 12 is %s, floor 60 %s; %s climb floor 12 with you (%d); %d live on floor 25, a rest there costs %d and the trader has %d wares" % [
		small, big, TowerFloors.company_on(world, 12), company.size(), living.size(), rest_price, wares.size()])

	# Walked: floor 12 opens, its bands the floor's own, and the company fights beside the party.
	GameState.pending_outcome = {}
	var twelve: Node = load("res://src/area/area_scene.tscn").instantiate()
	twelve.set("boot_payload", { "area_id": TowerFloors.grown_area_id(12), "return_scene": "world", "tower_floor": 12, "allies": company })
	add_child(twelve)
	for i in 10:
		await get_tree().process_frame
	var on_twelve: Array = twelve.get("_watches")
	_expect(not on_twelve.is_empty() and on_twelve.all(func(w: Node2D) -> bool: return str(w.band.get("key", "")).begins_with("tower12_")),
			"tower grows: floor 12's bands are not its own (%d)" % on_twelve.size())
	var m12: AreaMap = twelve.get("map")
	_expect(not m12.stairs.is_empty() and m12.is_walkable(m12.stairs[0]), "tower grows: floor 12 has no stair to stand on")
	if not on_twelve.is_empty():
		var w12: Node2D = on_twelve[0]
		var into12: Vector2i = (w12.watched as Dictionary).keys()[0]
		twelve.call("_check_the_watch", m12.cell_at(twelve.get("_leader").position))
		twelve.get("_leader").position = m12.centre_of(into12)
		twelve.call("_check_the_watch", into12)
		var waited12 := 0.0
		while waited12 < 3.0 and twelve.get("_fight") == null:
			await get_tree().create_timer(0.1).timeout
			waited12 += 0.1
		var fight12: Node2D = twelve.get("_fight")
		_expect(fight12 != null, "tower grows: floor 12's band did not fight")
		if fight12 != null:
			# Atlas's bearer stands on the allies' side too, bound to him; the company is everyone else.
			var with_you: Array = fight12.fighters.filter(func(f: Fighter) -> bool: return f.unit.team == Unit.Team.ALLY and f.bound_to == null)
			_expect(with_you.size() == company.size(), "tower grows: %d of the company fight beside the party, not %d" % [with_you.size(), company.size()])
			fight12.set_process(false)
	GameState.pending_outcome = {}
	twelve.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


func _check_tower_floor() -> void:
	GameState.new_game(SEED)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "tower_floor_1", "return_scene": "world", "tower_floor": 1 })
	add_child(scene)
	for i in 10:
		await get_tree().process_frame
	var watches: Array = scene.get("_watches")
	_expect(not watches.is_empty(), "tower floor: nobody stands on floor 1")
	if watches.is_empty():
		scene.queue_free()
		return
	var watch: Node2D = watches[0]
	var map: AreaMap = scene.get("map")
	var at: Vector2i = map.cell_at(scene.get("_leader").position)
	var into: Vector2i = (watch.watched as Dictionary).keys()[0]
	scene.call("_check_the_watch", at)
	scene.get("_leader").position = map.centre_of(into)
	_expect(scene.call("_check_the_watch", into), "tower floor: stepping into a band's red was not seen")
	var waited := 0.0
	while waited < 3.0 and scene.get("_fight") == null:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	var fight: Node2D = scene.get("_fight")
	_expect(fight != null, "tower floor: the band did not fight")
	if fight != null:
		_expect(not bool((fight.get("boot_payload") as Dictionary).get("sandbox", false)), "tower floor: the fight is practice")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "tower_band", "tower floor: the fight is not settled as the Tower's")
		fight.set_process(false)
	scene.queue_free()
	await get_tree().process_frame

	# The stair up.
	GameState.pending_outcome = {}
	_requests.clear()
	var again: Node = load("res://src/area/area_scene.tscn").instantiate()
	again.set("boot_payload", { "area_id": "tower_floor_1", "return_scene": "world", "tower_floor": 1 })
	add_child(again)
	for i in 10:
		await get_tree().process_frame
	var up: AreaMap = again.get("map")
	_expect(not up.stairs.is_empty(), "tower floor: no stair up")
	if not up.stairs.is_empty():
		# Stepping onto it asks rather than climbs (meeting 3); E climbs.
		again.call("_arrive_at", up.stairs[0])
		_expect(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "world"), "tower floor: stepping on the stair climbed without asking")
		(again.get("_leader") as Node2D).position = up.centre_of(up.stairs[0] + Vector2i(0, 1))
		_expect(str(again.call("_prompt_text")).ends_with("to climb to floor 2"), "tower floor: at the stair nothing says how to climb (%s)" % again.call("_prompt_text"))
		again.call("_climb_the_stair")
		_expect(_requests.any(func(r: Dictionary) -> bool: return r["key"] == "world"), "tower floor: the stair up went nowhere")
		_expect(str(GameState.pending_outcome.get("kind", "")) == "tower" and int(GameState.pending_outcome.get("floor", 0)) == 1
				and GameState.has_flag("last_victory"), "tower floor: the stair up did not win the floor")
	GameState.pending_outcome = {}
	GameState.set_flag("last_victory", false)
	again.queue_free()
	await get_tree().process_frame

	# Floor 6 (D207): walked on a borrowed plan, its bands the floor's own, fought on its ground.
	var plan := Chapters.walked_floor_area(6)
	var six: Node = load("res://src/area/area_scene.tscn").instantiate()
	six.set("boot_payload", { "area_id": plan, "return_scene": "world", "tower_floor": 6 })
	add_child(six)
	for i in 10:
		await get_tree().process_frame
	var on_six: Array = six.get("_watches")
	_expect(not on_six.is_empty() and on_six.all(func(w: Node2D) -> bool: return str(w.band.get("key", "")).begins_with("tower6_")),
			"tower floor: floor 6's bands are not its own")
	if not on_six.is_empty():
		var w6: Node2D = on_six[0]
		var m6: AreaMap = six.get("map")
		var into6: Vector2i = (w6.watched as Dictionary).keys()[0]
		six.call("_check_the_watch", m6.cell_at(six.get("_leader").position))
		six.get("_leader").position = m6.centre_of(into6)
		six.call("_check_the_watch", into6)
		var waited6 := 0.0
		while waited6 < 3.0 and six.get("_fight") == null:
			await get_tree().create_timer(0.05).timeout
			waited6 += 0.05
		var fight6: Node2D = six.get("_fight")
		_expect(fight6 != null and bool(fight6.get("in_place")), "tower floor: floor 6 was not fought on its ground")
		_expect(not _requests.any(func(r: Dictionary) -> bool: return r["key"] == "skirmish"), "tower floor: floor 6 opened a fight screen")
		if fight6 != null:
			fight6.set_process(false)
	six.queue_free()
	GameState.pending_outcome = {}
	await get_tree().process_frame

	# Atlas's chapter-one memory (D103): the buckle lies on floor 5 for him and nobody else.
	GameState.new_game(SEED, "atlas")
	var asked: Array[String] = []
	var listen := func(id: String) -> void: asked.append(id)
	EventBus.dialogue_requested.connect(listen)
	var five: Node = load("res://src/area/area_scene.tscn").instantiate()
	five.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
	add_child(five)
	for i in 10:
		await get_tree().process_frame
	var lying: Dictionary = five.get("_memories")
	_expect(lying.size() == 1, "tower floor: Atlas's buckle is not on floor 5 (%d)" % lying.size())
	if lying.size() == 1:
		var cell: Vector2i = lying.keys()[0]
		_expect((five.get("map") as AreaMap).is_walkable(cell), "tower floor: the buckle lies where nobody can stand")
		# The compass points at it before the stair, so nobody walks past it (D107).
		five.call("_point_the_compass")
		var said := (((five.get("_compass") as Control).get("_label")) as Label).text
		_expect(said == "Something glints", "tower floor: the compass does not point at the buckle first (%s)" % said)
		five.call("_arrive_at", cell)
		_expect(asked.has("memory_atlas_1") and not Database.dialogue("memory_atlas_1").is_empty(),
				"tower floor: picking up the buckle played no scene")
		# Seen, not only read (D361): a vision stands behind the lines, opening after the floor goes out
		# from under the world, going white on "White." and back to the floor after.
		var vision: MemoryVision = null
		for child in five.get_children():
			if child is MemoryVision:
				vision = child
		_expect(vision != null, "vision: picking up the buckle put up no vision")
		if vision != null:
			EventBus.dialogue_line_shown.emit("memory_atlas_1", "line_1")
			_expect(vision.stage == "floor", "vision: it opened before the floor went out from under the world")
			EventBus.dialogue_line_shown.emit("memory_atlas_1", "line_2")
			var held := (vision.get("_picture") as TextureRect).texture
			_expect(vision.stage == "seen" and held != null, "vision: the courtyard is not seen, or the keepsake not held up (%s)" % vision.stage)
			EventBus.dialogue_line_shown.emit("memory_atlas_1", "line_6")
			_expect(vision.stage == "white", "vision: \"White.\" did not turn it white (%s)" % vision.stage)
			EventBus.dialogue_line_shown.emit("memory_atlas_1", "line_7")
			_expect(vision.stage == "gone", "vision: the fifth floor did not come back after it (%s)" % vision.stage)
			vision.call("_on_finished", "memory_atlas_1")
			_expect(vision.is_queued_for_deletion(), "vision: it outlived its memory")
			print("vision: Atlas's buckle is held up in the white stone, and the floor comes back")
		_expect(Memories.found("atlas").size() == 1, "tower floor: the journal does not have the memory")
		_expect(bool(preload("res://src/chronicle/siblings.gd").remember(GameState.world, GameState.roster, GameState.ledger).get("remembered", false)),
				"tower floor: a world whose lead found their chapter one does not say so when it ends (D153)")
		_expect((five.get("_memories") as Dictionary).is_empty(), "tower floor: the buckle can be picked up twice")
	EventBus.dialogue_requested.disconnect(listen)
	five.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED, "juno")
	var not_his: Node = load("res://src/area/area_scene.tscn").instantiate()
	not_his.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
	add_child(not_his)
	for i in 5:
		await get_tree().process_frame
	# All sixteen have a chapter one now (D151), so Juno sees one keepsake: hers, never Atlas's.
	var hers: Array = (not_his.get("_memories") as Dictionary).values().map(func(m: Dictionary) -> String: return str(m.get("id", "")))
	_expect(hers == ["juno_1"], "tower floor: Juno found Atlas's memory, or not her own (%s)" % [hers])
	not_his.queue_free()
	await get_tree().process_frame
	# Every other lead with a chapter one (D135, D138, D151) finds their own in the same alcove, and nobody else's.
	for lead: String in Database.memories:
		if lead == "atlas" or lead.begins_with("_"):
			continue
		GameState.new_game(SEED, lead)
		var theirs: Node = load("res://src/area/area_scene.tscn").instantiate()
		theirs.set("boot_payload", { "area_id": "tower_floor_5", "return_scene": "world", "tower_floor": 5 })
		add_child(theirs)
		for i in 5:
			await get_tree().process_frame
		var lying_here: Dictionary = theirs.get("_memories")
		_expect(lying_here.size() == 1, "tower floor: %s's keepsake is not on floor 5 (%d)" % [lead, lying_here.size()])
		if lying_here.size() == 1:
			theirs.call("_arrive_at", lying_here.keys()[0])
			_expect(Memories.found(lead).size() == 1 and Memories.found("atlas").is_empty(),
					"tower floor: %s did not find their own memory, or found Atlas's" % lead)
		theirs.queue_free()
		await get_tree().process_frame
	# The Second Hour (D254): every lead's chapter two lies on one of floors 6 to 10, where they can
	# stand, for them alone, and finding it writes chapter two into the journal.
	for lead: String in Database.memories:
		if lead.begins_with("_"):
			continue
		var two: Array = Memories.of(lead).filter(func(m: Dictionary) -> bool: return int(m.get("chapter", 1)) == 2)
		_expect(two.size() == 1, "second hour: %s has %d chapter twos, not one" % [lead, two.size()])
		if two.size() != 1:
			continue
		var floor_id := str(two[0]["area"])
		_expect(floor_id.begins_with("tower_floor_") and int(floor_id.trim_prefix("tower_floor_")) in range(6, 11),
				"second hour: %s's chapter two lies off floors 6 to 10 (%s)" % [lead, floor_id])
		GameState.new_game(SEED, lead)
		var upper: Node = load("res://src/area/area_scene.tscn").instantiate()
		upper.set("boot_payload", { "area_id": floor_id, "return_scene": "world", "tower_floor": int(floor_id.trim_prefix("tower_floor_")) })
		add_child(upper)
		for i in 5:
			await get_tree().process_frame
		var up_here: Dictionary = upper.get("_memories")
		var ids: Array = up_here.values().map(func(m: Dictionary) -> String: return str(m.get("id", "")))
		_expect(ids == ["%s_2" % lead], "second hour: %s sees %s on %s, not their own chapter two" % [lead, ids, floor_id])
		if ids.size() == 1:
			_expect((upper.get("map") as AreaMap).is_walkable(up_here.keys()[0]), "second hour: %s's keepsake lies where nobody can stand" % lead)
			upper.call("_arrive_at", up_here.keys()[0])
			_expect(Memories.found(lead).size() == 1 and int(Memories.found(lead)[0].get("chapter", 0)) == 2,
					"second hour: %s did not find their chapter two" % lead)
		upper.queue_free()
		await get_tree().process_frame
	# The Tower's door is the way up (D107): standing at it says how to climb, and the shaft stands over it (D108).
	var foot: Node = load("res://src/area/area_scene.tscn").instantiate()
	foot.set("boot_payload", { "area_id": "tower", "return_scene": "world" })
	add_child(foot)
	for i in 5:
		await get_tree().process_frame
	var door: AreaProp = null
	for thing: AreaProp in foot.get("_things"):
		if thing.act == "_climb_here":
			door = thing
	_expect(door != null, "tower: the Tower's door is not a way up")
	# The Guild's master stands beside Sennet and can mark a lead himself (D154).
	var masters := (Database.area("tower").get("people", []) as Array).filter(func(p: Dictionary) -> bool:
		return str(p.get("name", "")).begins_with("Old Halloran") and bool(p.get("guild", false)))
	_expect(masters.size() == 1, "tower: the Guild's master is not in the Guild")
	var spires := (foot.get("_actors") as Node).get_children().filter(func(n: Node) -> bool: return n.get_script() == preload("res://src/area/area_spire.gd"))
	_expect(spires.size() == 1, "tower: the stand-in Tower is not standing (%d)" % spires.size())
	if door != null:
		# Two cells short of it, with the doorkeeper close by, E is still the door's (meeting 3).
		var leader: Node2D = foot.get("_leader")
		leader.position = door.position + Vector2(0.0, AreaMap.CELL * 2.0)
		foot.call("_refresh_prompt")
		_expect(foot.get("_nearby") == door, "tower: two cells from the door, E is not the door's")
		# And the yard can be walked from where you come in to the door's steps (meeting 3).
		var yard: AreaMap = foot.get("map")
		var to_door: Array = yard.astar.get_id_path(yard.spawn, door.cell + Vector2i(0, 1))
		_expect(not to_door.is_empty(), "tower: the door's steps cannot be walked to from the yard's way in")
		foot.set("_acts", [{ "prompt": "E to climb floor 1 of the Tower", "act": "_climb_here", "key": "interact" }])
		foot.set("_nearby", door)
		_expect(str(foot.call("_prompt_text")) == "E to climb floor 1 of the Tower", "tower: standing at the door does not say how to climb")
		foot.set("_nearby", null)
	foot.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("tower floor: a band fought for real on floor 1, the stair up won the floor, Atlas found his buckle on floor 5, and the Tower's door says how to climb")


## The board is read at the board (D359, Ewan's play-test 3): every village, keep and Stormreach has a
## notice board on its ground that can be walked to, and J reads it only standing there; a hut,
## with no board, is asked as before.
func _check_the_board() -> void:
	for area_id: String in ["village", "village_dune", "village_fen", "village_pines", "village_shore", "keep", "keep_thorn", "city", "city_streets"]:
		var boards := (Database.area(area_id).get("props", []) as Array).filter(func(p: Dictionary) -> bool: return str(p.get("reads", "")) == "board")
		_expect(boards.size() == 1, "board: %s has %d notice boards" % [area_id, boards.size()])
		if boards.size() != 1:
			continue
		var ground := AreaMap.load_area(area_id)
		var cell := Vector2i(int(boards[0]["cell"][0]), int(boards[0]["cell"][1]))
		var reached := false
		for step: Vector2i in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(2, 0), Vector2i(0, 0)]:
			if ground.is_walkable(cell + step) and not ground.astar.get_id_path(ground.spawn, cell + step).is_empty():
				reached = true
				break
		_expect(reached, "board: the notice board in %s cannot be walked to" % area_id)
	var town: Node = load("res://src/area/area_scene.tscn").instantiate()
	town.set("boot_payload", { "area_id": "village", "return_scene": "world" })
	add_child(town)
	for i in 5:
		await get_tree().process_frame
	var board: AreaProp = town.call("_board")
	_expect(board != null, "board: the village's notice board is not on its ground")
	if board != null:
		var read := { "prompt": "J to read the board", "label": "Read the board", "act": "_errands_here", "key": "site_errands" }
		var hire := { "prompt": "H to hire Ren", "label": "Hire Ren", "act": "_hire_here", "key": "site_hire" }
		town.set("_acts", [read, hire])
		town.set("_nearby", null)
		var said := str(town.call("_acts_text"))
		_expect(not said.contains("read the board") and said.contains("hire Ren"), "board: away from the board, the line still offers it: %s" % said)
		_expect(bool(town.call("_held_at_the_board", read)) and not bool(town.call("_held_at_the_board", hire)), "board: away from it, the board could be read from anywhere in town")
		town.set("_nearby", board)
		_expect(str(town.call("_prompt_text")) == "J to read the board", "board: standing at the board does not say how to read it")
		_expect(not bool(town.call("_held_at_the_board", read)) and (town.call("_act_of", board) as Dictionary) == read, "board: at the board, it cannot be read")
		town.set("_acts", [hire])
		_expect((town.call("_act_of", board) as Dictionary).is_empty(), "board: a bare board offers something")
	town.queue_free()
	await get_tree().process_frame
	var hut: Node = load("res://src/area/area_scene.tscn").instantiate()
	hut.set("boot_payload", { "area_id": "hut", "return_scene": "world" })
	add_child(hut)
	for i in 5:
		await get_tree().process_frame
	_expect(hut.call("_board") == null and not bool(hut.call("_held_at_the_board", { "act": "_errands_here" })), "board: a hut with no board holds its work back")
	hut.queue_free()
	await get_tree().process_frame
	print("board: nine towns read their work at a notice board, a hut as before")


## People on the land (D215): bands always by the First Hour's road, the Watch beset on the roads
## round a town (and only there) fighting beside the party, and climbers resting on a Tower floor.
func _check_people_on_the_land() -> void:
	GameState.new_game(SEED, "janus")
	var world: World = GameState.world
	world.prowlers.clear()
	Encounter.restock(world, world.rng)
	var rules: Dictionary = Database.encounters.get("near_the_road", {})
	var road: Array = FirstRoad.tiles(world)
	var by_road := 0
	for band: Prowler in world.prowlers:
		var apart := 1 << 20
		for tile: Vector2i in road:
			apart = mini(apart, Pathfinder.distance(band.cell, tile))
		if apart >= int(rules.get("from", 2)) and apart <= int(rules.get("to", 4)):
			by_road += 1
	_expect(by_road >= int(rules.get("bands", 1)), "people: only %d bands by the road (wanted %d)" % [by_road, int(rules.get("bands", 1))])

	# The Watch beset: by a town's roads only, and fighting beside the party.
	var town: Site = null
	for site: Site in world.sites:
		if Town.is_settlement(site) and not Town.is_ruined(site):
			town = site
			break
	var ring := Vector2i(-1, -1)
	var open := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var c := Vector2i(x, y)
			if not world.is_walkable(c) or Roadside._near_a_site(world, c):
				continue
			if ring.x < 0 and Roadside.near_town(world, c):
				ring = c
			if open.x < 0 and not Roadside.near_town(world, c):
				open = c
	_expect(town != null and ring.x >= 0 and open.x >= 0, "people: no road round a town, or no open country, to look on")
	var watch_ids := Roadside.events().keys().filter(func(id) -> bool: return bool(Roadside.event(str(id)).get("near_town", false)))
	_expect(not watch_ids.is_empty(), "people: there is no Watch beset among the roadside scenes")
	var seen_by_town: Array = []
	var seen_in_open: Array = []
	for i in 400:
		world.roadside_at = -999
		var here := Roadside.look(world, ring)
		if here != "":
			seen_by_town.append(here)
		world.roadside_at = -999
		var there := Roadside.look(world, open)
		if there != "":
			seen_in_open.append(there)
	_expect(not seen_by_town.is_empty() and seen_by_town.all(func(id) -> bool: return watch_ids.has(id)),
			"people: by a town's road the scenes were %s, not the Watch beset" % [seen_by_town.slice(0, 5)])
	_expect(seen_in_open.all(func(id) -> bool: return not watch_ids.has(id)), "people: the Watch was beset out in the open country")
	var met := Roadside.meeting(world, ring, str(watch_ids[0]), GameState.party_characters(), world.rng)
	var allies: Array = met.get("map", {}).get("allies", [])
	_expect(allies.size() == 2 and allies.all(func(a: Dictionary) -> bool: return str(a.get("name", "")) == "a watchman"),
			"people: the Watch beset does not fight beside the party (%s)" % [allies])

	# Climbers resting by a floor's stair, who talk.
	var climbers: Dictionary = Database.world_rules.get("life", {}).get("climbers", {}).get("on_the_floors", {})
	var floor := -1
	for f in range(int(climbers.get("from", 2)), 60):
		var rng := RandomNumberGenerator.new()
		rng.seed = hash([world.world_seed, f, "climbers"])
		if rng.randf() < float(climbers.get("chance", 0.4)):
			floor = f
			break
	_expect(floor > 0, "people: no Tower floor has climbers resting on it")
	if floor > 0:
		var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
		scene.set("boot_payload", { "area_id": Chapters.walked_floor_area(floor), "return_scene": "world", "tower_floor": floor })
		add_child(scene)
		for i in 5:
			await get_tree().process_frame
		var resting: Array = (scene.get("map") as AreaMap).people.filter(func(p: Dictionary) -> bool: return str(p.get("_area", "")) == "climbers_floor")
		_expect(resting.size() >= 2 and not (resting[0].get("talk", {}) as Dictionary).get("hello", []).is_empty(),
				"people: floor %d has no company resting by its stair to talk to (%d)" % [floor, resting.size()])
		# D246: they sit round a fire of their own, and a fight near them is theirs too.
		_expect(not (scene.get("_climbers_rest_at") as Array).is_empty(), "people: the company on floor %d has no fire to sit round" % floor)
		var by_them: Array = (scene.get("_people") as Array).filter(func(a: Node) -> bool: return str((a.get_meta("person", {}) as Dictionary).get("_area", "")) == "climbers_floor")
		if not by_them.is_empty():
			(scene.get("_leader") as Node2D).position = (by_them[0] as Node2D).position
			var joined := {}
			scene.call("_call_the_climbers", joined)
			_expect((joined.get("allies", []) as Array).size() == by_them.size(),
					"people: the company on floor %d did not join a fight beside them (%s)" % [floor, joined])
			for actor: Node in scene.get("_watch_fighting"):
				actor.visible = true
			(scene.get("_watch_fighting") as Array).clear()
			# Play-test 7: Hob's Lot sat by floor 2's stair while the party fought a band that spots it
			# twelve cells off. From the farthest cell any of the floor's bands sees, they still come.
			var map: AreaMap = scene.get("map")
			var far := Vector2i(-1, -1)
			var apart := 0.0
			for watch: Node2D in scene.get("_watches"):
				for cell: Vector2i in watch.get("watched"):
					var nearest := INF
					for actor: Node2D in by_them:
						nearest = minf(nearest, Vector2(cell - map.cell_at(actor.position)).length())
					if nearest > apart:
						apart = nearest
						far = cell
			if far.x >= 0:
				(scene.get("_leader") as Node2D).position = map.centre_of(far)
				var far_joined := {}
				scene.call("_call_the_climbers", far_joined)
				_expect((far_joined.get("allies", []) as Array).size() == by_them.size(),
						"people: the company on floor %d stood by while the party fought %.1f cells off (play-test 7)" % [floor, apart])
				for actor: Node in scene.get("_watch_fighting"):
					actor.visible = true
		scene.queue_free()
		await get_tree().process_frame
	print("people: %d bands by the road, the Watch beset by a town's road, climbers on floor %d" % [by_road, floor])


func _expect(ok: bool, message: String) -> void:
	if not ok:
		_fail(message)


func _expect_tut(ok: bool, message: String) -> void:
	if not ok:
		_fail("tutorial: %s" % message)


## The fire seats the party itself: nobody is authored into it, and speaking to
## one of your own is banter rather than a written conversation.
func _check_camp() -> void:
	var map := AreaMap.load_area("camp")
	if map.is_walkable(map.fire):
		_fail("camp: the fire can be walked into")
	if map.seats.size() < Roster.most() - 1:
		_fail("camp: %d seats for a party of %d" % [map.seats.size(), Roster.most()])
	for seat in map.seats:
		if not map.is_walkable(seat):
			_fail("camp: seat %s is not on ground anybody can sit on" % seat)

	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "camp", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame

	var expected := GameState.party_characters().size() - 1
	var seated: Array = scene.get("_people")
	if seated.size() != expected:
		_fail("camp: %d of %d sat down at the fire" % [seated.size(), expected])
	elif expected > 0:
		await _check_fireside(scene)
	scene.queue_free()
	await get_tree().process_frame


func _check_fireside(scene: Node) -> void:
	# The opening cutscene has the scene until it is done with it.
	var patience := get_tree().create_timer(CUTSCENE_PATIENCE)
	while scene.get("_talking") and patience.time_left > 0.0:
		await get_tree().process_frame

	# This checks the dialogue-box path, so the player's preference for keeping
	# chatter in the log has to be set aside for it (see [Pace]).
	var chatter := Pace.quiet_banter
	Pace.quiet_banter = false

	var party := GameState.party_characters()
	var before := Banter.bond(party[0], party[1])
	_opened.clear()
	var watch := func(id: String) -> void: _opened.append(id)
	EventBus.dialogue_requested.connect(watch)
	scene.call("_speak_to", 0)
	await get_tree().process_frame
	EventBus.dialogue_requested.disconnect(watch)
	Pace.quiet_banter = chatter

	if _opened.is_empty():
		_fail("camp: %s had nothing to say at the fire" % party[1].display_name)
		return
	# Nothing is listening for the box here, so let the waiting call finish.
	EventBus.dialogue_finished.emit(_opened[0])
	await get_tree().process_frame

	if not scene.get("_people")[0].can_talk():
		print("camp: %s said their piece and settled ('%s'), bond %d -> %d" % [
			party[1].display_name, _opened[0], before, Banter.bond(party[0], party[1])
		])
	else:
		_fail("camp: %s can be talked in circles" % party[1].display_name)


func _fail(message: String) -> void:
	_failures.append(message)

## Snow drags at the feet and the cold wears at whoever has nothing against it,
## but never past a quarter of their health, and somebody in a padded coat walks
## through untouched (`data/biomes.json` → `effects`, `hazards`).
func _check_the_land() -> void:
	var world: World = GameState.world
	var snow := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var cell := Vector2i(x, y)
			if snow.x < 0 and world.is_walkable(cell) and world.site_at(cell) == null and Biome.at(world, cell) == "snow":
				snow = cell
	if snow.x < 0:
		_fail("no snowfield on the continent to walk")
		return
	world.player_cell = snow
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", {
		"area_id": GroundGen.for_cell(world, snow), "return_scene": "world", "planar_mode": true,
	})
	add_child(scene)
	await get_tree().process_frame
	if scene._walk_speed() >= scene.WALK_SPEED:
		_fail("the snow does not slow the party")
	var party := GameState.party_characters()
	var coated: Character = party[0]
	var bare: Character = party[-1] if party.size() > 1 else null
	coated.charms = []
	coated.equipment = "padded_coat"
	if bare != null:
		bare.equipment = ""
		bare.charms = []
		bare.hp = bare.max_hp()
	coated.hp = coated.max_hp()
	for i in 200:
		scene._weather(1000.0)
	if coated.current_hp() != coated.max_hp():
		_fail("the cold got through a padded coat")
	if bare != null and not Biome.spared(bare, "cold"):
		var low := ceili(float(bare.max_hp()) * float(Database.biomes["hazards"]["floor"]))
		if bare.current_hp() == bare.max_hp():
			_fail("the cold did nothing to %s, who has nothing against it" % bare.display_name)
		if bare.current_hp() < low:
			_fail("the cold took %s below a quarter of their health" % bare.display_name)
	GameState.heal_party()
	scene.queue_free()
	await get_tree().process_frame


## The land ([D84]): the tiles round the party laid side by side as one stretch of ground. Every
## tile that can be walked can be walked into from the next one; the sea and the mountains cannot
## be walked at all; a place stands in its tile and keeps its own cells for what is written down
## about it; and walking over into the next tile asks the continent for the step, lays out the
## tiles ahead and lets go of the ones far behind, without the ground ever leaving the screen.
func _check_the_joined_land() -> void:
	var world: World = GameState.world
	var town: Site = null
	for site: Site in world.sites:
		if site.kind == Site.VILLAGE and not site.data.has("ward") and Database.has_area(str(site.data.get("area", site.kind))):
			town = site
			break
	if town == null:
		_fail("land: no village to stand the land round")
		return
	var land = Land.around(world, town.cell, 2)
	var walked := 0
	for tile: Vector2i in land.held_tiles():
		var chunk: Dictionary = land.chunks[tile]
		var origin: Vector2i = chunk["origin"]
		var spawn: Vector2i = AreaMap.to_cell(chunk["spawn"]) + origin
		if not world.in_bounds(tile) or not world.is_walkable(tile):
			for y in land.slot.y:
				for x in land.slot.x:
					if land.is_walkable(origin + Vector2i(x, y)):
						_fail("land: %s cannot be walked on the continent but its ground can (%s)" % [tile, chunk["kind"]])
						return
			continue
		if not land.is_walkable(spawn):
			_fail("land: the way into %s (%s) cannot be stood on" % [tile, chunk["kind"]])
		for dir: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = tile + dir
			if not land.is_held(next) or not world.is_walkable(next):
				continue
			var there: Dictionary = land.chunks[next]
			var to: Vector2i = AreaMap.to_cell(there["spawn"]) + (there["origin"] as Vector2i)
			if land.find_cell_path(spawn, to).is_empty():
				_fail("land: no way over from %s into %s" % [tile, next])
			walked += 1
	if walked == 0:
		_fail("land: no two tiles side by side to walk between")
	var place: Dictionary = land.chunks[town.cell]
	var area_id := str(town.data.get("area", town.kind))
	if str(place.get("kind", "")) != "place" or str(place.get("id", "")) != area_id:
		_fail("land: %s does not stand in its own tile" % town.display_name)
	else:
		var alone := AreaMap.load_area(area_id)
		var rect: Rect2i = place["place_rect"]
		for cell: Vector2i in alone.chests:
			if land.chest_flag(cell + rect.position) != alone.chest_flag(cell):
				_fail("land: a chest in %s is not the same chest on the land" % town.display_name)
		if land.area_of(rect.position) != area_id or land.local_of(rect.position + Vector2i(2, 3)) != Vector2i(2, 3):
			_fail("land: the land does not say whose cells %s's are" % town.display_name)
		# A walled town ([D85]): its corners stand in the way, and the way in is still the way in.
		if Database.area(area_id).has("walls"):
			if land.is_walkable(rect.position - Vector2i.ONE):
				_fail("land: %s has walls in its data but none round it on the land" % town.display_name)
			var gate: Vector2i = alone.exits[0] if not alone.exits.is_empty() else Vector2i.ZERO
			var outside := (place["origin"] as Vector2i) + AreaMap.to_cell(place["spawn"])
			if land.find_cell_path(outside, rect.position + AreaMap.to_cell(Database.area(area_id).get("spawn", [0, 0]))).is_empty():
				_fail("land: %s's walls leave no way in" % town.display_name)
			var hub := rect.position + gate + Vector2i.DOWN
			for corner: Vector2i in [rect.position + Vector2i(-2, -2), rect.end + Vector2i(1, 1)]:
				if land.slot_rect(town.cell).has_point(corner) and land.is_walkable(corner) \
						and land.find_cell_path(corner, hub).is_empty():
					_fail("land: the lane round %s's walls does not reach the gate from %s" % [town.display_name, corner])

	# Walked: the scene on the land, the leader put over into the next tile, the step asked for.
	var here := town.cell + Vector2i.LEFT
	if not world.is_walkable(here):
		here = town.cell + Vector2i.RIGHT
	world.player_cell = here
	GameState.land_cell = null
	var asked: Array = []
	var listen := func(payload: Dictionary) -> void: asked.append(payload)
	EventBus.continent_requested.connect(listen)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "land": true, "return_scene": "world", "planar_mode": true })
	add_child(scene)
	await get_tree().process_frame
	if scene._tile_ground.size() != 9:
		_fail("land: %d tiles laid out round the party, not 9" % scene._tile_ground.size())
	if scene.map.tile_of(scene.map.cell_at(scene._leader.position)) != here:
		_fail("land: the party did not start on the tile the continent has it on")
	# A band on the next tile stands there; moved a tile by the continent, it walks across; gone
	# from the continent's word, it goes.
	var band := { "key": "band", "pack": ["goblin"], "reach": 2, "faction": "", "label": "Goblin", "tile": [here.x, here.y - 1] }
	scene._sync_bands([band])
	var watches: Array = scene.get("_watches")
	if watches.size() != 1 or not scene.map.slot_rect(here + Vector2i.UP).has_point(watches[0].anchor):
		_fail("land: a band on the next tile is not standing in it")
	else:
		var moved := band.duplicate()
		moved["tile"] = [here.x - 1, here.y - 1]
		scene._sync_bands([moved])
		if not watches[0].travelling or watches[0].region != scene.map.slot_rect(here + Vector2i(-1, -1)):
			_fail("land: a band moved a tile by the continent did not set off across the land")
		scene._sync_bands([])
		if not (scene.get("_watches") as Array).is_empty():
			_fail("land: a band the continent no longer has is still on the land")
	var dir := town.cell - here
	var into: Vector2i = scene.map.slot_rect(town.cell).get_center()
	scene._leader.position = scene.map.centre_of(into)
	scene._mind_the_border()
	if asked.size() != 1 or AreaMap.to_cell(asked[0].get("step", [0, 0])) != dir or not bool(asked[0].get("embedded", false)):
		_fail("land: walking over into the next tile did not ask the continent for that step")
	# The continent's answer, as it gives it.
	world.player_cell = town.cell
	EventBus.continent_answered.emit({ "land": true, "title": town.label(), "actions": [], "bands": [], "notes": ["Walked on."], "held": {} })
	for i in 12:
		await get_tree().process_frame
	var far := here - dir
	if not scene.map.is_held(town.cell + dir) or not scene.map.is_held(town.cell + dir + Vector2i.UP):
		_fail("land: the tiles ahead were not laid out after the step")
	if scene.map.is_held(far - dir):
		_fail("land: a tile three behind is still held")
	if not scene.is_inside_tree() or scene._leaving:
		_fail("land: the ground left the screen for a step")
	# Walking itself ([D94]): on over the land into the next tile, and never off to the map.
	asked.clear()
	var before := _requests.size()
	var setting := Pace.auto
	Pace.auto = true
	for i in 900:
		await get_tree().physics_frame
		if not asked.is_empty():
			break
	Pace.auto = setting
	for request: Dictionary in _requests.slice(before):
		if str(request["key"]) == "world":
			_fail("land: a party walking itself was sent off the ground to the map")
	if asked.is_empty() or AreaMap.to_cell(asked[0].get("step", [0, 0])) == Vector2i.ZERO:
		_fail("land: a party walking itself never walked over into the next tile")
	if not scene.is_inside_tree() or scene._leaving:
		_fail("land: the ground left the screen while the party walked itself")
	EventBus.continent_requested.disconnect(listen)
	scene.queue_free()
	await get_tree().process_frame
	print("land: tiles walk into each other, %s stands in its tile, a band walks across, a step keeps to the land, and so does walking itself" % town.display_name)


## The small panel on the ground ([D244]): a row for each of the company with a health bar, and the
## purse; out of the way while a box is open.
func _check_play_hud() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "village", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var hud: Control = scene._play_hud
	if hud == null:
		_fail("play hud: no panel on the ground")
	else:
		hud.refresh()
		var party := GameState.party_characters()
		_expect_tut(hud._rows.get_child_count() == party.size(),
			"play hud: %d rows for a company of %d" % [hud._rows.get_child_count(), party.size()])
		_expect_tut(hud._purse.text.contains(Coins.text(GameState.gold)), "play hud: the purse says %s, not %s" % [hud._purse.text, Coins.text(GameState.gold)])
		var hurt: Character = party[0]
		var was := hurt.hp
		hurt.hp = maxi(1, hurt.max_hp() / 5)
		hud.refresh()
		var bar: ColorRect = hud._rows.get_child(0).get_child(1).get_child(1).get_child(0)
		_expect_tut(bar.color.r > bar.color.g, "play hud: a lead at a fifth of their health shows a bar that is not red")
		# What wants attention (D245): someone badly hurt and a path owed show as alerts, and pressing
		# the path's opens the party screen.
		var Alerts := preload("res://src/ui/alerts.gd")
		var wanted := Alerts.gather()
		_expect_tut(wanted.any(func(a: Dictionary) -> bool: return str(a["id"]) == "hurt:" + hurt.id),
			"play hud: %s at a fifth of their health raises no alert" % hurt.display_name)
		hurt.pending_class_choice = true
		hud.refresh()
		var owed := Alerts.gather().filter(func(a: Dictionary) -> bool: return str(a["id"]) == "path:" + hurt.id)
		_expect_tut(owed.size() == 1, "play hud: a path owed raises no alert")
		_expect_tut(hud._alerts.get_child_count() >= 2, "play hud: %d alerts shown, not 2" % hud._alerts.get_child_count())
		var opened := [0]
		var on_open := func() -> void: opened[0] += 1
		EventBus.party_screen_requested.connect(on_open)
		if not owed.is_empty():
			hud.act_on(owed[0])
		EventBus.party_screen_requested.disconnect(on_open)
		_expect_tut(opened[0] == 1, "play hud: pressing the path's alert did not open the party screen")
		hurt.pending_class_choice = false
		hurt.hp = was
		scene._physics_process(1.0 / 60.0)
		print("play hud: %d rows and %s" % [hud._rows.get_child_count(), hud._purse.text])
	scene.queue_free()
	await get_tree().process_frame


## Play-test 4's small fixes ([D189]): a click on the ground puts a pin there with a line to it,
## gone on arrival; a shut door is tried once per arrival, not every frame; the baker sells only
## what she bakes; the speeds are 1×, 2×, 3× and 5×.
func _check_play_test_four() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "city_streets", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var from: Vector2i = map.cell_at(scene._leader.position)
	var goal := Vector2i(-1, -1)
	for radius in range(3, 9):
		for cell: Vector2i in [from + Vector2i(radius, 0), from + Vector2i(-radius, 0), from + Vector2i(0, -radius), from + Vector2i(0, radius)]:
			if goal.x < 0 and map.is_walkable(cell) and map.door_at(cell).is_empty() and map.find_cell_path(from, cell).size() > 2:
				goal = cell
	if goal.x < 0:
		_fail("play-test 4: nowhere open in the streets to click on")
	else:
		scene._walk_to(map.centre_of(goal))
		scene._physics_process(1.0 / 60.0)
		if scene._waymark._way.is_empty():
			_fail("play-test 4: a click on the ground put no pin where it was")
		for i in 300:
			scene._physics_process(1.0 / 60.0)
			if scene._click_path.is_empty():
				break
		scene._physics_process(1.0 / 60.0)
		if not scene._waymark._way.is_empty():
			_fail("play-test 4: the pin stayed after the party got there")
	# Leaning on a shut door: it says so once, not every frame.
	var doors := [0]
	var count := func(what: String) -> void:
		if what.begins_with("door:"):
			doors[0] += 1
	EventBus.player_did.connect(count)
	var shut := Vector2i(-1, -1)
	for building: Dictionary in map.buildings:
		if shut.x < 0 and not Database.has_area(str(building.get("area", ""))) and not building.has("fight"):
			shut = building["door"]
	if shut.x < 0:
		_fail("play-test 4: the streets have no shut door to lean on")
	else:
		scene._on_doorstep = Vector2i(-1, -1)
		for i in 30:
			scene._arrive_at(shut)
		if doors[0] != 1:
			_fail("play-test 4: a shut door was tried %d times in 30 frames, not once" % doors[0])
	EventBus.player_did.disconnect(count)
	scene.queue_free()
	await get_tree().process_frame
	for person: Dictionary in Database.area("city_streets").get("people", []):
		if str(person.get("name", "")) == "Ada the Baker":
			for ware: Dictionary in person.get("talk", {}).get("sells", []):
				if not ["bread", "meat_pie", "honey_cake"].has(str(ware.get("item", ""))):
					_fail("play-test 4: Ada the Baker sells %s, which she did not bake" % ware.get("item", ""))
	if Pace.SPEEDS != [1.0, 2.0, 3.0, 5.0]:
		_fail("play-test 4: the speeds are %s, not 1x, 2x, 3x and 5x" % [Pace.SPEEDS])
	print("play-test 4: a click puts a pin and a line, a shut door is tried once, the baker bakes, speeds 1/2/3/5")


## Followers face the way they walk ([D214], play-test 4: walking down, "my characters that are
## followed behind me are facing the wrong way"). A party of four walks up a clear stretch and then
## back down it at walking pace, a frame at a time; once the turn is behind them (forty frames),
## nobody following faces back the way the leader came. Before the fix a follower keeping pace was
## never turned again, so the second leg was walked looking up.
func _check_followers_face() -> void:
	GameState.new_game(SEED)
	Company.join(GameState.roster, ["juno", "cato", "vesta"])
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "city_streets", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var followers: Array = scene._followers
	# A column of open ground fourteen cells long to walk up and down.
	var top := Vector2i(-1, -1)
	for y in range(1, map.height - 15):
		for x in range(1, map.width - 1):
			if top.x >= 0:
				break
			var clear := true
			for dy in 15:
				for dx in [-1, 0, 1]:
					if not map.is_walkable(Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				top = Vector2i(x, y)
	if followers.size() != 3 or top.x < 0:
		_fail("followers: %d followers, and open ground at %s" % [followers.size(), top])
		scene.queue_free()
		await get_tree().process_frame
		return
	var bottom := map.centre_of(top + Vector2i(0, 14))
	scene._leader.position = bottom
	for f: Node2D in followers:
		f.position = bottom
	scene._reseed_crumbs()
	var wrong: Array[String] = []
	var delta := 1.0 / 60.0
	for leg: Vector2 in [Vector2.UP, Vector2.DOWN]:
		for frame in 110:
			scene._leader.position += leg * scene._walk_speed() * delta
			scene._leader.face(leg)
			scene._drop_crumbs()
			scene._settle_followers(delta)
			if frame < 40:
				continue
			for i in followers.size():
				var facing: Vector2 = followers[i].get("_facing")
				if facing.dot(leg) < -0.1:
					wrong.append("walking %s, follower %d faces %s at frame %d" % [leg, i, facing, frame])
	if not wrong.is_empty():
		_fail("followers face the wrong way: %s (and %d more)" % [wrong[0], wrong.size() - 1])
	else:
		print("followers: walking up and then down, everyone following faces the way they walk")
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## The party walks in its formation ([D289], [D305]): in a column, after a walk up open ground, each
## follower stands in single file behind the lead, a slot apart, facing the way the lead faces.
func _check_formation_walk() -> void:
	GameState.new_game(SEED)
	Company.join(GameState.roster, ["juno", "cato", "vesta"])
	var kept := GameState.formation
	GameState.formation = "column"
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "city_streets", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var followers: Array = scene._followers
	var top := Vector2i(-1, -1)
	for y in range(1, map.height - 15):
		for x in range(1, map.width - 1):
			if top.x >= 0:
				break
			var clear := true
			for dy in 15:
				for dx in [-1, 0, 1]:
					if not map.is_walkable(Vector2i(x + dx, y + dy)):
						clear = false
			if clear:
				top = Vector2i(x, y)
	if followers.size() != 3 or top.x < 0:
		_fail("formation: %d followers, and open ground at %s" % [followers.size(), top])
		scene.queue_free()
		await get_tree().process_frame
		GameState.formation = kept
		return
	var bottom := map.centre_of(top + Vector2i(0, 14))
	scene._leader.position = bottom
	for f: Node2D in followers:
		f.position = bottom
	scene._reseed_crumbs()
	var delta := 1.0 / 60.0
	for frame in 150:
		scene._leader.position += Vector2.UP * scene._walk_speed() * delta
		scene._leader.face(Vector2.UP)
		scene._drop_crumbs()
		scene._settle_followers(delta)
	var spacing := float(Formations.rules().get("ground_spacing", 40.0))
	var lead: Vector2 = scene._leader.position
	var wrong: Array[String] = []
	var behind: Array[float] = []
	for i in followers.size():
		var at: Vector2 = followers[i].position
		behind.append(at.y - lead.y)
		if absf(at.x - lead.x) > 6.0 or at.y <= lead.y + spacing * 0.5 or at.y > lead.y + spacing * 3.5:
			wrong.append("follower %d stands at %s, the lead at %s" % [i, at, lead])
		var facing: Vector2 = followers[i].get("_facing")
		if facing.dot(Vector2.UP) < 0.5:
			wrong.append("follower %d faces %s in a column walking up" % [i, facing])
	behind.sort()
	for k in range(1, behind.size()):
		if absf(behind[k] - behind[k - 1] - spacing) > 8.0:
			wrong.append("the column's gaps are %s, not %.0f apart" % [behind, spacing])
			break
	if not wrong.is_empty():
		_fail("formation: %s (and %d more)" % [wrong[0], wrong.size() - 1])
	else:
		print("formation: walking up in a column, three stand in single file %s behind the lead" % [behind])
	GameState.formation = kept
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## The party still walks behind the leader after the wilds (play-test 7: "When I entered the
## ancient grove and left the ancient grove, then my party disappeared ... I don't see the
## characters beside me"). A party of four goes into the ancient grove off the continent, walks out
## of its east edge, takes the step on the continent the way the game does, and is put down on the
## land: three followers stand on the ground beside the lead, seen.
func _check_play_test_seven() -> void:
	GameState.new_game(SEED)
	Company.join(GameState.roster, ["juno", "cato", "vesta"])
	var world: World = GameState.world
	var from := Vector2i(-1, -1)
	for y in range(2, world.size.y - 2):
		for x in range(2, world.size.x - 2):
			var tile := Vector2i(x, y)
			if from.x < 0 and world.is_walkable(tile) and world.is_walkable(tile + Vector2i.RIGHT) \
					and world.site_at(tile) == null and world.site_at(tile + Vector2i.RIGHT) == null \
					and world.distance_to_haven(tile) > 4:
				from = tile
	if from.x < 0:
		_fail("play-test 7: no open tile with open ground east of it")
		return
	world.player_cell = from
	GameState.land_cell = null
	GameState.set_flag("seen:prologue")
	_requests.clear()
	var grove: Node = load("res://src/area/area_scene.tscn").instantiate()
	grove.set("boot_payload", {
		"area_id": "wild_grove", "title": "The Wilds", "return_scene": "world", "planar_mode": true,
	})
	add_child(grove)
	await get_tree().process_frame
	var edge := Vector2i(grove.map.width - 1, 10)
	grove._leader.position = grove.map.centre_of(edge)
	grove._handle_exit(edge)
	var asked: Array = _requests.filter(func(r: Dictionary) -> bool: return str(r["key"]) == "world")
	grove.queue_free()
	await get_tree().process_frame
	if asked.is_empty():
		_fail("play-test 7: walking off the grove's east edge asked the continent for nothing")
		return
	_requests.clear()
	var continent: Node = load("res://src/world/world_scene.tscn").instantiate()
	continent.set("boot_payload", asked[0]["payload"])
	# Swapped in as the game swaps it in, so it takes the step and hands the ground back.
	continent.add_to_group(EventBus.ACTIVE_SCENE_GROUP)
	add_child(continent)
	await get_tree().process_frame
	var ground: Array = _requests.filter(func(r: Dictionary) -> bool: return str(r["key"]) == "area")
	continent.queue_free()
	await get_tree().process_frame
	if ground.is_empty() or not bool(ground[0]["payload"].get("land", false)):
		_fail("play-test 7: the step out of the grove did not put the party back on the land (%s)" % str(_requests))
		return
	var land: Node = load("res://src/area/area_scene.tscn").instantiate()
	land.set("boot_payload", ground[0]["payload"])
	add_child(land)
	for i in 30:
		await get_tree().process_frame
	var leader: AreaActor = land._leader
	# The tile's way in is a cell of the tile; read as a cell of the whole land it put everyone in
	# the land's far corner, and only the lead was stepped back onto the tile.
	if land.map.tile_of(land.map.cell_at(leader.position)) != world.player_cell:
		_fail("play-test 7: out of the grove, the lead stands on %s, not the tile the continent has them on (%s)" % [
			land.map.tile_of(land.map.cell_at(leader.position)), world.player_cell])
	# The continent's next word puts a lead off the tile back on it, and leaves the rest behind.
	EventBus.continent_answered.emit({ "land": true, "title": "The Wilds", "actions": [], "bands": [], "notes": [], "held": {} })
	for i in 12:
		await get_tree().process_frame
	var beside: Array = land.get_node("Actors").get_children().filter(func(n: Node) -> bool:
		return n is AreaActor and n != leader and not n.is_queued_for_deletion() \
			and (n as AreaActor).visible and land._followers.has(n) \
			and (n as Node2D).position.distance_to(leader.position) < 6.0 * AreaMap.CELL)
	if beside.size() != GameState.party_characters().size() - 1:
		_fail("play-test 7: out of the grove, %d of %d followers stand beside the lead (%d followers kept)" % [
			beside.size(), GameState.party_characters().size() - 1, (land._followers as Array).size()])
	else:
		print("play-test 7: out of the grove and onto the land, all %d followers walk beside the lead" % beside.size())
	land.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


## Sennet speaking from afar is seen as a ghost of himself (play-test 7, call BR8): his face washed
## blue in the box, his figure beside the lead on the land while he talks, gone when he is done.
func _check_sennet_from_afar() -> void:
	GameState.new_game(SEED)
	GameState.set_flag("seen:prologue")
	var seen := DialogueScript.afar("Sennet")
	if seen.is_empty() or Database.unit_face(str(seen.get("unit", ""))) == null:
		_fail("Sennet from afar: no figure to show him by (%s)" % str(seen))
		return
	var nodes := DialogueScript.nodes_from_lines([{ "speaker": "Sennet", "text": "Hear me.", "afar": true }])
	if not bool((nodes.values()[0] as Dictionary).get("afar", false)):
		_fail("Sennet from afar: a line said from afar forgets it on its way to the box")
	var land: Node = load("res://src/area/area_scene.tscn").instantiate()
	land.set("boot_payload", { "land": true, "title": "The land", "actions": [], "bands": [], "held": {} })
	add_child(land)
	for i in 10:
		await get_tree().process_frame
	EventBus.conversation_requested.emit([{ "speaker": "Sennet", "text": "Hear me.", "afar": true }])
	for i in 50:
		await get_tree().process_frame
	var ghost: AreaActor = land._ghost
	if ghost == null or ghost.display_name != "Sennet":
		_fail("Sennet from afar: nobody stands beside the lead while he speaks")
	else:
		var wash := ghost.modulate
		var drawn: Variant = (ghost.material as ShaderMaterial).get_shader_parameter("wash") if ghost.material is ShaderMaterial else null
		if wash.a >= 0.9 or not drawn is Color or (drawn as Color).b <= (drawn as Color).r:
			_fail("Sennet from afar: he is drawn solid or not blue (%s, %s)" % [str(wash), str(drawn)])
		elif ghost.position.distance_to(land._leader.position) > 3.0 * AreaMap.CELL:
			_fail("Sennet from afar: he stands %.0f px from the lead, not beside them" % ghost.position.distance_to(land._leader.position))
		else:
			print("Sennet from afar: a blue ghost (%s) beside the lead while he speaks" % str(wash))
	EventBus.dialogue_finished.emit("")
	await get_tree().create_timer(0.8).timeout
	await get_tree().process_frame
	if ghost != null and is_instance_valid(ghost) and not ghost.is_queued_for_deletion():
		_fail("Sennet from afar: he is still there once he has finished speaking")
	land.queue_free()
	await get_tree().process_frame


## The climbers' stone at the Tower's door (play-test 7, call BR3): it stands at the Tower's foot,
## and reads the leads who climbed before, highest first, then this lead while they climb.
## The sword in the Tower's yard ([D318]; play-test 3, item 8): pulled with a throw of the dice, once a run;
## lost, it stays in the stone and every look after says so; won, the blade is handed over.
func _check_the_sword_in_the_yard() -> void:
	GameState.new_game(SEED)
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "tower", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var sword: AreaProp = null
	for thing: AreaProp in scene.get("_things"):
		if thing.art == "landmark/sword_storm":
			sword = thing
	_expect(sword != null and not sword.try_once.is_empty() and float(sword.try_once.get("chance", 0.0)) > 0.0
			and not Database.equipment_piece(str(sword.try_once.get("item", ""))).is_empty(), "the sword in the yard cannot be tried, or wins nothing")
	if sword == null or sword.try_once.is_empty():
		scene.queue_free()
		return
	var try: Dictionary = sword.try_once
	var flag := "tried:tower:%d:%d" % [sword.cell.x, sword.cell.y]
	var before: int = (scene.get("_notes") as Array).size()
	scene.call("_try_once", sword, 1.0)
	var notes: Array = scene.get("_notes")
	_expect(notes.size() == before + 1 and str(notes.back()) == str(try.get("lose", "")) and GameState.has_flag(flag) and not GameState.has_flag(flag + ":won"),
			"a lost pull said nothing, or the wrong thing, or was not kept")
	scene.call("_try_once", sword, 0.0)
	notes = scene.get("_notes")
	_expect(str(notes.back()) == str(try.get("tried", "")) and sword.line == str(try.get("tried", "")) and not GameState.has_flag(flag + ":won"),
			"the sword could be pulled at twice")
	GameState.flags.erase(flag)
	scene.call("_try_once", sword, 0.0)
	notes = scene.get("_notes")
	_expect(notes.has(str(try.get("win", ""))) and GameState.has_flag(flag + ":won"),
			"a won pull did not hand the sword over: %s" % [notes.slice(maxi(0, notes.size() - 3))])
	print("the sword in the yard: one pull a run at %.0f%%, for a %s" % [float(try.get("chance", 0.0)) * 100.0, Gear.display_name(str(try.get("item", "")))])
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)


func _check_the_climbers_stone() -> void:
	var stones: Array = (Database.area("tower").get("props", []) as Array).filter(func(p: Dictionary) -> bool:
		return str(p.get("reads", "")) == "climbers")
	if stones.size() != 1:
		_fail("climbers' stone: %d stones that read the climbers at the Tower's foot, not one" % stones.size())
	GameState.new_game(SEED, "juno")
	var lead := GameState.roster.player()
	var past := [
		{ "name": "Atlas", "floor": 2, "gone": true },
		{ "name": "Vesta", "floor": 9, "gone": true },
		{ "name": "Cato", "floor": 0, "gone": true },
	]
	GameState.world.tower_floor = 0
	var read := Climbers.lines(GameState.world, lead, past)
	var vesta := read.find("Vesta, floor 9.")
	var atlas := read.find("Atlas, floor 2.")
	if vesta < 0 or atlas < 0 or vesta > atlas or not read.has("Cato, who never climbed."):
		_fail("climbers' stone: the fallen are not read highest first (%s)" % str(read))
	if read.any(func(line: String) -> bool: return line.begins_with(lead.display_name)):
		_fail("climbers' stone: %s is on it before setting foot on a floor" % lead.display_name)
	GameState.world.tower_floor = 4
	read = Climbers.lines(GameState.world, lead, past)
	if not read.has("%s, floor 4, and still climbing." % lead.display_name):
		_fail("climbers' stone: the lead climbing is not on it (%s)" % str(read))
	read = Climbers.lines(GameState.world, lead, [])
	if read.size() < 2:
		_fail("climbers' stone: nothing on it with nobody before (%s)" % str(read))
	else:
		print("climbers' stone: %d lines, highest first, the lead while they climb" % read.size())


## The journal open at the side while the game goes on (play-test 7, call BR7): the party walks with
## it open; opened over the whole screen it holds the walk up, as before; asked for again, it shuts.
func _check_the_journal_at_the_side() -> void:
	GameState.new_game(SEED)
	GameState.set_flag("seen:prologue")
	get_window().size = Vector2i(1600, 900)
	var journal: Node = load("res://src/ui/journal_screen.tscn").instantiate()
	add_child(journal)
	var land: Node = load("res://src/area/area_scene.tscn").instantiate()
	land.set("boot_payload", { "land": true, "title": "The land", "actions": [], "bands": [], "held": {} })
	add_child(land)
	for i in 10:
		await get_tree().process_frame
	var was_docked: bool = JournalScreen.docked
	for side: bool in [true, false]:
		JournalScreen.docked = side
		EventBus.journal_requested.emit()
		await get_tree().process_frame
		if not journal.is_showing() or journal.is_open() == side:
			_fail("journal %s: showing %s, holding the game %s" % [
				"at the side" if side else "full", journal.is_showing(), journal.is_open()])
		var from: Vector2 = land._leader.position
		for direction: String in ["move_right", "move_down", "move_left", "move_up"]:
			Input.action_press(direction)
			for i in 12:
				await get_tree().physics_frame
			Input.action_release(direction)
		var moved := (land._leader.position as Vector2).distance_to(from) > 1.0
		if side and not moved:
			_fail("journal at the side: the party does not walk while it is open")
		elif not side and moved:
			_fail("journal full: the party walks under it")
		EventBus.journal_requested.emit()
		await get_tree().process_frame
		if journal.is_showing():
			_fail("journal %s: asked for again, it stays open" % ("at the side" if side else "full"))
	print("journal at the side: the party walks with it open; full, it waits; asked again, it shuts")
	JournalScreen.docked = was_docked
	land.queue_free()
	journal.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)

	GameState.new_game(SEED)


## Footpaths, dirt tracks and signposts ([D233]): tracks join the places people live, a tile on
## one has the track's ground and sheet, every tile's worn paths are footpaths, and where three ways
## meet a signpost stands and names somewhere each way.
func _check_tracks() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var Tracks := preload("res://src/area/tracks.gd")
	var joined := 0
	for site: Site in Tracks.places(world):
		if not Tracks.sides(world, site.cell).is_empty():
			joined += 1
	if joined * 2 < Tracks.places(world).size():
		_fail("tracks: only %d of %d places have a track to them" % [joined, Tracks.places(world).size()])
	var on_track := Vector2i(-1, -1)
	var post := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if on_track.x < 0 and world.site_at(tile) == null and not Tracks.sides(world, tile).is_empty() \
					and Tracks.ways(world, tile).size() == Tracks.sides(world, tile).size():
				on_track = tile
			if post.x < 0 and Tracks.signpost(world, tile) != "":
				post = tile
	if on_track.x < 0 or post.x < 0:
		_fail("tracks: no open tile on a track (%s) or no signpost anywhere (%s)" % [on_track, post])
		return
	var slot := GroundGen.slot(world, on_track)
	var ground: PackedStringArray = slot.get("terrain", PackedStringArray())
	if not ground.has("track"):
		_fail("tracks: a tile on a track has no track on its ground")
	var layers: Array = (slot.get("patches", [{}]) as Array)[0].get("layers", [])
	if not layers.has("track") or not layers.has("footpath"):
		_fail("tracks: a tile on a track does not draw the track and footpath sheets (%s)" % [layers])
	var says := Tracks.signpost(world, post)
	var standing := (GroundGen.slot(world, post).get("props", []) as Array).filter(
		func(prop: Dictionary) -> bool: return str(prop.get("line", "")) == says)
	if standing.size() != 1 or not says.begins_with("A signpost.") or says.contains("Where You Fell"):
		_fail("tracks: the signpost at %s stands %d times and says %s" % [post, standing.size(), says])
	print("tracks: %d of %d places joined, a track laid on its tiles, a signpost: %s" % [joined, Tracks.places(world).size(), says])


## An inn's rooms ([D242], play-test 4): behind the taproom a kitchen and bedrooms, each bed
## reached through its door; a night paid for at the innkeep becomes this inn's room, pinned with a
## line and pointed at by the compass; another bed says it is somebody's; sleeping in yours patches
## everyone up, leaves them the better for it, saves, and the room is let go.
func _check_inn_rooms() -> void:
	GameState.new_game(SEED)
	Company.join(GameState.roster, ["juno"])
	for area_id: String in ["village_inn", "dune_serai", "city_tavern"]:
		var inn: Dictionary = Database.area(area_id).get("inn", {})
		var rooms: Array = inn.get("bedrooms", [])
		if rooms.size() < 2 or not (inn.get("kitchen", []) as Array).size() == 4:
			_fail("inn rooms: %s has %d bedrooms and kitchen %s" % [area_id, rooms.size(), inn.get("kitchen")])
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "village_inn", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var from: Vector2i = map.cell_at(scene._leader.position)
	for room: Dictionary in Database.area("village_inn")["inn"]["bedrooms"]:
		var bed := AreaMap.to_cell(room["bed"])
		if map.find_cell_path(from, bed + Vector2i.DOWN).is_empty():
			_fail("inn rooms: nobody can walk from the door to %s's bed" % room["name"])
	var said: Array[String] = []
	var hear := func(line: String) -> void: said.append(line)
	EventBus.battle_log.connect(hear)
	if scene._your_bed().x >= 0:
		_fail("inn rooms: a room is pinned before anyone paid for it")
	GameState.set_flag("inn_room_paid")
	scene._settle_the_room()
	var bed: Vector2i = scene._your_bed()
	if bed.x < 0 or scene._room_mark == null:
		_fail("inn rooms: paying for a night pinned no room")
	else:
		scene._draw_the_way_to_bed()
		if (scene._room_mark._way as Array).is_empty():
			_fail("inn rooms: no line drawn to the room's bed")
		scene._point_the_compass()
		var needle := (((scene.get("_compass") as Control).get("_label")) as Label).text
		if needle != "Your room":
			_fail("inn rooms: the compass says %s, not Your room" % needle)
		var others: Array = (Database.area("village_inn")["inn"]["bedrooms"] as Array).map(
			func(r: Dictionary) -> Vector2i: return AreaMap.to_cell(r["bed"])).filter(func(c: Vector2i) -> bool: return c != bed)
		var saves := [0]
		var count := func(_kind: String, _why: String) -> void: saves[0] += 1
		EventBus.safe_point_reached.connect(count)
		var hurt: Character = GameState.party_characters()[0]
		hurt.hp = 1
		scene._try_the_bed(others[0])
		if hurt.current_hp() != 1 or not GameState.has_flag("inn_room_paid"):
			_fail("inn rooms: somebody else's bed was slept in")
		scene._try_the_bed(bed)
		EventBus.safe_point_reached.disconnect(count)
		if hurt.current_hp() != hurt.max_hp() or hurt.hearth_vigour < int(Database.area("village_inn")["inn"]["vigour"]):
			_fail("inn rooms: a night in the room did not patch %s up and leave them the better for it" % hurt.display_name)
		if saves[0] != 1:
			_fail("inn rooms: sleeping saved %d times, not once" % saves[0])
		if GameState.has_flag("inn_room_paid") or scene._your_bed().x >= 0 or scene._room_mark != null:
			_fail("inn rooms: the room is still held after it was slept in")
	EventBus.battle_log.disconnect(hear)
	scene.queue_free()
	await get_tree().process_frame
	GameState.new_game(SEED)
	print("inn rooms: a kitchen and bedrooms behind three taprooms; a night paid, pinned, slept in, saved, let go")
## Stormreach walked outside ([D247]): the city stands on the land over two tiles by two, with
## every one of its people standing in one piece of it, and the Tower just north of its north gate
## (one tile, not a piece of the city).
func _check_open_city() -> void:
	GameState.new_game(SEED)
	var world: World = GameState.world
	var city: Site = null
	for site: Site in world.sites:
		if str(site.data.get("area", "")) == "city_streets":
			city = site
	if city == null:
		_fail("open city: no site stands as city_streets")
		return
	var area := Database.area("city_streets")
	var people := 0
	for dy in 2:
		for dx in 2:
			var tile := city.cell + Vector2i(dx, dy)
			if not GroundGen.in_big_place(world, tile):
				_fail("open city: %s is not a piece of Stormreach" % [tile])
				continue
			var slot := GroundGen.slot(world, tile)
			if str(slot.get("place", {}).get("id", "")) != "city_streets":
				_fail("open city: the piece at %s is not Stormreach's ground (%s)" % [tile, slot.get("place", {})])
			people += (slot.get("people", []) as Array).size()
	if people != (area.get("people", []) as Array).size():
		_fail("open city: %d people stand in its pieces, the city has %d" % [people, (area.get("people", []) as Array).size()])
	var tower := world.site_at(city.cell + Vector2i(0, -1))
	if tower == null or tower.kind != "tower" or GroundGen.in_big_place(world, tower.cell):
		_fail("open city: the Tower does not stand alone just north of the city (%s)" % [tower])
	if GroundGen.in_big_place(world, city.cell + Vector2i(2, 0)) or GroundGen.in_big_place(world, city.cell + Vector2i(0, 2)):
		_fail("open city: Stormreach covers more than two tiles by two")
	print("open city: Stormreach over 4 tiles, %d people in it, the Tower to the north" % people)


## Play-test 3's small fixes ([D178]): a click on open ground walks the party there; Atlas met
## standing somewhere is drawn as the Atlas who joins (in Sky's saddle); the lighthouse's beam turns
## at its own slower pace.
func _check_play_test_three() -> void:
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "area_id": "village", "return_scene": "world" })
	add_child(scene)
	await get_tree().process_frame
	var map: AreaMap = scene.map
	var from: Vector2i = map.cell_at(scene._leader.position)
	var goal := Vector2i(-1, -1)
	for radius in range(4, 9):
		for cell: Vector2i in [from + Vector2i(radius, 0), from + Vector2i(-radius, 0), from + Vector2i(0, -radius)]:
			if goal.x < 0 and map.is_walkable(cell) and map.find_cell_path(from, cell).size() > 2:
				goal = cell
	if goal.x < 0:
		_fail("play-test 3: nowhere open near the village's way in to click on")
	else:
		scene._walk_to(map.centre_of(goal))
		for i in 240:
			scene._physics_process(1.0 / 60.0)
			if map.cell_at(scene._leader.position) == goal:
				break
		if map.cell_at(scene._leader.position) != goal:
			_fail("play-test 3: a click on open ground did not walk the party there (at %s, wanted %s)" % [map.cell_at(scene._leader.position), goal])
	scene.queue_free()
	await get_tree().process_frame
	var standing := AreaActor.for_person({ "name": "Atlas", "unit": "atlas" })
	var joined := AreaActor.for_character(Character.create("atlas"))
	if standing.body_scale != joined.body_scale or standing._rotations.get("south") != joined._rotations.get("south"):
		_fail("play-test 3: Atlas standing in a town is not drawn as the Atlas who joins")
	standing.free()
	joined.free()
	if float(Database.prop_size("landmark/lighthouse").get("frame_seconds", 0.13)) <= 0.13:
		_fail("play-test 3: the lighthouse still blinks at the quick pace")


## Life on the land ([D179]): the tiles round the party have birds, butterflies and the like on
## them; a bird takes off when the leader walks up to it and comes down further off; and on the
## First Hour's road the city's Watch walks its rounds.
## Creatures that match the land ([D336], "no grasshopper in magma"): each land's own pictures of life are
## pictures of that kind of life, and the burnt and blighted lands have no bees, butterflies or
## grasshoppers.
func _check_life_matches_the_land() -> void:
	var lands: Dictionary = Database.biomes.get("biomes", {})
	var named := 0
	for land: String in lands:
		var own: Dictionary = lands[land].get("life_art", {})
		if not own.is_empty():
			named += 1
		for kind: String in own:
			for art: String in own[kind]:
				if AreaCritter.life_of(art) != kind:
					_fail("life: %s's %s is drawn as %s, which is not a %s" % [land, kind, art, kind])
	for land: String in ["ash", "blight", "snow"]:
		var own: Dictionary = lands.get(land, {}).get("life_art", {})
		if not own.has("hop") or not own.has("flutter"):
			_fail("life: the %s does not say what hops and flutters there" % land)
		for art: String in (own.get("hop", []) as Array) + (own.get("flutter", []) as Array):
			if art.begins_with("nature/grasshopper") or art.begins_with("nature/butterfly") or art.begins_with("nature/bee"):
				_fail("life: a grasshopper or a butterfly in the %s" % land)
	# The lands' own creatures (A56) wait for their pictures: a land names them now and they are
	# laid only once drawn, so until then the land is as it was.
	for art: String in ["nature/crow", "nature/frog", "nature/lizard", "nature/snow_hare", "nature/ember_beetle", "nature/moth"]:
		var lives := false
		for land: String in lands:
			for kind: String in lands[land].get("life_art", {}):
				lives = lives or (lands[land]["life_art"][kind] as Array).has(art)
		if not lives:
			_fail("life: %s lives in no land" % art)
	if named < 8:
		_fail("life: only %d lands have creatures of their own" % named)


func _check_life_on_the_land() -> void:
	var world: World = GameState.world
	var road_tile := Vector2i(-1, -1)
	for y in world.size.y:
		for x in world.size.x:
			var tile := Vector2i(x, y)
			if road_tile.x < 0 and not FirstRoad.sides(world, tile).is_empty() and world.site_at(tile) == null:
				var rng := RandomNumberGenerator.new()
				rng.seed = hash([world.shape_seed(), tile.x, tile.y, "watch"])
				if rng.randf() < float(Database.world_rules["life"]["road_watch"]["chance"]):
					road_tile = tile
	if road_tile.x < 0:
		_fail("life: no tile of the road with the Watch on it")
		return
	world.player_cell = road_tile
	GameState.land_cell = null
	var scene: Node = load("res://src/area/area_scene.tscn").instantiate()
	scene.set("boot_payload", { "land": true, "return_scene": "world", "planar_mode": true })
	add_child(scene)
	await get_tree().process_frame
	var critters: Array = scene.get_node("Actors").get_children().filter(
		func(n: Node) -> bool: return n.get_script() == AreaCritter)
	var lives := {}
	for c: Node2D in critters:
		lives[c.life] = true
	if critters.size() < 9 or not lives.has("bird") or not lives.has("flutter"):
		_fail("life: the land round the party is empty (%d creatures, %s)" % [critters.size(), lives.keys()])
	var watch: Array = scene._people.filter(func(a: AreaActor) -> bool:
		return str((a.get_meta("person", {}) as Dictionary).get("_area", "")) == "road_watch")
	if watch.size() < 2 or watch.size() % 2 != 0:
		_fail("life: the Watch is not walking the road at %s in pairs (%d of them)" % [road_tile, watch.size()])
	elif not watch[0].can_talk():
		_fail("life: the Watch on the road will not talk")
	else:
		# Trouble led to the Watch (D236): a band setting on the party beside them brings them into
		# the fight, out of their walk, and a win pays their bounty.
		var leader_was: Vector2 = scene._leader.position
		scene._leader.position = (watch[0] as AreaActor).position + Vector2(AreaMap.CELL, 0)
		var field := {}
		scene._call_the_watch(field)
		var came: Array = field.get("allies", [])
		if came.is_empty() or int(field.get("watch", 0)) != came.size() or (watch[0] as AreaActor).visible:
			_fail("watch: a band set on the party beside the Watch, and they did not come (%s)" % field)
		elif str((came[0] as Dictionary).get("unit", "")) == "" or int((came[0] as Dictionary).get("level", 0)) < 1:
			_fail("watch: the Watch came without a unit or level (%s)" % came[0])
		var gold_was := GameState.gold
		var thanks := Roadside.watch_thanks(world, road_tile, GameState.party_characters())
		if GameState.gold <= gold_was or thanks.is_empty():
			_fail("watch: beating a band with the Watch paid no bounty")
		scene._leader.position = leader_was
		for actor: AreaActor in scene._watch_fighting:
			actor.visible = true
		scene._watch_fighting.clear()
	var bird: Node2D = null
	for c: Node2D in critters:
		if c.life == "bird" and c.visible:
			bird = c
			break
	if bird != null:
		var was := bird.position
		scene._leader.position = bird.position + Vector2(40, 0)
		for i in 120:
			bird._process(1.0 / 60.0)
		if bird.position.distance_to(was) < AreaMap.CELL * 2.0:
			_fail("life: a bird stayed put with the leader standing over it")
	scene.queue_free()
	await get_tree().process_frame
	print("life: %d creatures round the party (%s), a bird took off, and the Watch walks the road and comes to a fight" % [critters.size(), ", ".join(lives.keys())])
