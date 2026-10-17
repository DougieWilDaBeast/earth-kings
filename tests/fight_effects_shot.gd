extends Node
## Photograph what each move does to whoever it lands on (D192): a haymaker, a kick into
## somebody, a kick at a keeper, an undertow, a hamstring, an ember, a dart, a sunder, an
## earthshake, and a wind-up stepped out of. Each is staged on the proving ground, let go,
## and shot a moment later, cropped round the two of them. Needs a display (xvfb-run).
##
##   xvfb-run godot --path . --rendering-driver opengl3 res://tests/fight_effects_shot.tscn
##
## Shots land in .art_stage/fight_effects/<move>.png. Uses nothing the fight did not
## already have before D192, so the same script shoots the old build for a before.

const Fighter := preload("res://src/skirmish/fighter.gd")
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const Company := preload("res://tests/company.gd")

const OUT := "res://.art_stage/fight_effects"
const CROP := Vector2i(520, 360)

var fight: Node2D


func _ready() -> void:
	seed(5)
	get_window().size = Vector2i(1280, 800)
	GameState.difficulty = "gentle"
	GameState.roster = Company.found("cato", ["vesta", "iris"])
	var map: Dictionary = Database.map("verdant_pass").duplicate(true)
	map["enemies"] = [
		{"unit": "brigand", "cell": [6, 1], "level": 8},
		{"unit": "brigand", "cell": [3, 2], "level": 8},
	]
	fight = load("res://src/skirmish/skirmish.tscn").instantiate()
	fight.boot_payload = {"encounter": {"map": map}, "sandbox": true, "touch": false, "paused": true}
	add_child(fight)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	await _frames(20)
	fight.manual = true
	var camera: Camera2D = fight.get_node("Camera2D")
	camera.set_process(false)
	camera.zoom = Vector2(2.0, 2.0)
	var cato := _of("cato")
	var foes: Array = fight.fighters.filter(func(f: Fighter) -> bool: return not f.is_party())
	var foe: Fighter = foes[0]
	var other: Fighter = foes[1]
	for f: Fighter in fight.fighters:
		if f != cato and f != foe and f != other:
			_park(f, Vector2i(0, 0))
	var row := _open_row()
	var a := row[0]
	camera.position = fight.grid.cell_to_world(a + Vector2i(2, 0)) + fight.position
	for move: String in ["haymaker", "kick_pinned", "kick_keeper", "undertow", "hamstring", "ember", "dart", "sunder", "earthshake", "dodge"]:
		for f: Fighter in fight.fighters:
			_tough(f)
			f.hold = true
			f.auto_skill = false
			f.attack_timer = 999.0
			f.think_timer = 999.0
			if "conditions" in f:
				f.conditions.clear()
		fight.fx._popups.clear()
		fight.fx._rings.clear()
		_place(cato, a)
		_place(foe, a + Vector2i(2 if move == "undertow" else 1, 0))
		_park(other, Vector2i(1, 0))
		cato.unit.face_towards(foe.unit.cell)
		foe.unit.face_towards(cato.unit.cell)
		foe.unit.remove_meta("boss")
		await _frames(4)
		match move:
			"kick_pinned":
				_place(other, a + Vector2i(2, 0))
				fight._strike(cato, foe.unit, Database.ability("kick"), "kick")
			"kick_keeper":
				foe.unit.set_meta("boss", true)
				fight._strike(cato, foe.unit, Database.ability("haymaker"), "haymaker")
			"dodge":
				# Pyre wound up on where the foe stands; the foe steps out of it.
				var slot := cato.slots.size()
				cato.slots.append("pyre")
				cato.cooldowns.append(0.0)
				cato.energy = cato.energy_max
				fight._begin_cast(cato, slot, null, foe.unit.cell)
				var plan := {"from": cato}
				fight._place_steppers()
				_place(foe, foe.unit.cell + Vector2i(0, 3))
				if "conditions" in fight and fight.conditions != null:
					fight.conditions.dodging(foe, plan["from"])
				cato.cast["left"] = 0.0
				fight._release(cato)
				cato.slots.pop_back()
				cato.cooldowns.pop_back()
			_:
				fight._strike(cato, foe.unit, Database.ability(move), move)
		for i in 7:
			for f: Fighter in fight.fighters:
				f.think_timer = 999.0
				f.attack_timer = 999.0
			fight.tick()
			fight._place_steppers()
			await _frames(1)
		await _frames(3)
		await _shoot(move, cato.unit.position.lerp(foe.unit.position, 0.5))
		# Let anything lying wear off before the next one.
		if "conditions" in foe:
			foe.conditions.clear()
		foe.stunned = 0.0
		if "lying" in foe.unit:
			foe.unit.lying = 0.0
	get_tree().quit(0)


func _of(template_id: String) -> Fighter:
	for f: Fighter in fight.fighters:
		if f.unit.template_id == template_id:
			return f
	return null


func _tough(f: Fighter) -> void:
	f.unit.max_hp = 99999
	f.unit.hp = 99999
	f.cast = {}
	f.stunned = 0.0
	f.unit.modulate = Color.WHITE
	f.unit.visible = true


func _place(f: Fighter, cell: Vector2i) -> void:
	f.stepping = false
	f.unit.cell = cell
	f.unit.position = fight.grid.cell_to_world(cell)
	f.unit.set_running(false)


## Out of the way, in a corner of the field, and not thinking.
func _park(f: Fighter, corner: Vector2i) -> void:
	f.hold = true
	f.auto_skill = false
	f.attack_timer = 999.0
	var cells: Array = fight.grid._terrain_ids.keys()
	cells.sort_custom(func(p: Vector2i, q: Vector2i) -> bool:
		return (p - corner * 99).length_squared() < (q - corner * 99).length_squared())
	for cell: Vector2i in cells:
		if fight.grid.is_walkable(cell) and fight.occupant(cell, f) == null:
			_place(f, cell)
			return


## Five open level tiles in a row, left to right.
func _open_row() -> Array[Vector2i]:
	var cells: Array = fight.grid._terrain_ids.keys()
	cells.sort()
	for cell: Vector2i in cells:
		var ok := true
		for k in 5:
			var c: Vector2i = cell + Vector2i(k, 0)
			for dy in [0, 1, 2, 3]:
				var d: Vector2i = c + Vector2i(0, dy)
				if not fight.grid.is_walkable(d) or fight.grid.height_at(d) != fight.grid.height_at(cell):
					ok = false
		if ok and cell.x > 1 and cell.y > 1:
			return [cell, cell + Vector2i(1, 0), cell + Vector2i(2, 0), cell + Vector2i(3, 0), cell + Vector2i(4, 0)]
	return [Vector2i(4, 4)]


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shoot(label: String, around: Vector2) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var centre: Vector2 = fight.get_global_transform_with_canvas() * around
	var origin := Vector2i(centre) - CROP / 2 + Vector2i(0, -30)
	origin = origin.clamp(Vector2i.ZERO, image.get_size() - CROP)
	image.get_region(Rect2i(origin, CROP)).save_png("%s/%s.png" % [OUT, label])
	print("saved %s" % label)
