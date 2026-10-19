class_name Unit
extends Node2D
## A combatant on the battle grid. Stats are hydrated from a `data/units.json`
## template; the node itself draws a placeholder token until art exists.

signal died

enum Team { PLAYER, ENEMY, ENEMY_B, ENEMY_C, ALLY }

## Loaded by path ([D41]).
const LandJournals := preload("res://src/chronicle/land_journals.gd")

const ALLY_OUTLINE := Color(0.55, 0.85, 1.0)
## Frames a second for a unit that has a run cycle to step through.
const RUN_FPS := 12.0
## Frames a second for a swing, a skill, a flinch or a fall.
const ACTION_FPS := 14.0
## The moves a fight plays once each, beside the run cycle (see [method play]).
const ACTIONS: Array[String] = ["attack", "skill", "hit", "death"]
## Sprite height as a multiple of a tile, for a unit of ordinary size.
const SPRITE_HEIGHT_CELLS := 1.15
## A unit's `body_scale` is held to this range, so a typo cannot fill the screen.
const BODY_SCALE_MIN := 0.5
const BODY_SCALE_MAX := 3.0
## Facing -> the rotation file PixelLab exports for it.
const SPRITE_ROTATIONS := {
	Vector2i.DOWN: "south",
	Vector2i.UP: "north",
	Vector2i.RIGHT: "east",
	Vector2i.LEFT: "west",
	Vector2i(1, 1): "south-east",
	Vector2i(-1, 1): "south-west",
	Vector2i(1, -1): "north-east",
	Vector2i(-1, -1): "north-west",
}

var template_id: String = ""
## The persistent person this unit stands in for; null for scratch enemies.
var character: Character = null
var display_name: String = "Unit"
var job: String = ""
var team: Team = Team.PLAYER
var cell: Vector2i = Vector2i.ZERO
## Cardinal direction the unit is looking at; attacks from the sides or the
## back hit harder (see [AbilityResolver]).
var facing: Vector2i = Vector2i.DOWN

var max_hp: int = 1
var hp: int = 1
var attack: int = 1
var defense: int = 0
var move_points: int = 3
var jump: int = 1
## Blink range in tiles; 0 for units that cannot flash step.
var flash_step: int = 0
var speed: int = 8
var abilities: Array = []
var colour: Color = Color.WHITE
## How tall this body stands against an ordinary one (`body_scale` in `data/units.json`, D56).
## A big unit still holds one tile; it grows up from its feet.
var body_scale: float = 1.0
## A tier's shade over the art it shares with its family (`tint`, D262), until it has art of its own.
var tint: Color = Color.WHITE
## Laid flat by a knockdown: 0 standing, 1 on the ground ([D192]). Drawn tipped onto its side.
var lying: float = 0.0
## Facing -> [Texture2D] from the template's `sprite_dir`; empty falls back to a token.
var sprites: Dictionary = {}
## Facing -> the run cycle, for the few units that have one (see [Database]).
var run_frames: Dictionary = {}
## Move ("attack" | "skill" | "hit" | "death") -> facing -> frames, for the units
## that have them. A unit without one keeps its standing pose for it.
var action_frames: Dictionary = {}
## The equipped piece from `data/equipment.json`, plus its rotation art.
var weapon: Dictionary = {}
var weapon_sprites: Dictionary = {}

## Set while the unit is crossing the ground, so it is drawn mid-stride.
var _running: bool = false
var _run_time: float = 0.0
## The move being played and how far into it; "" when none is.
var _action: String = ""
var _action_time: float = 0.0


static func create(template_id_: String, unit_team: Team, start_cell: Vector2i) -> Unit:
	var unit := Unit.new()
	var data := Database.unit_template(template_id_)
	unit.template_id = template_id_
	unit.display_name = data.get("display_name", template_id_)
	unit.job = data.get("job", "")
	unit.max_hp = int(data.get("max_hp", 20))
	unit.hp = unit.max_hp
	unit.attack = int(data.get("attack", 5))
	unit.defense = int(data.get("defense", 0))
	unit.move_points = int(data.get("move", 3))
	unit.jump = int(data.get("jump", 1))
	unit.flash_step = int(data.get("flash_step", 0))
	unit.speed = int(data.get("speed", 8))
	unit.abilities = data.get("abilities", ["strike"])
	unit.colour = Color(data.get("color", "#cccccc"))
	unit.body_scale = clampf(float(data.get("body_scale", 1.0)), BODY_SCALE_MIN, BODY_SCALE_MAX)
	unit.tint = Color(str(data.get("tint", "#ffffff")))
	unit.sprites = _load_sprites(data.get("sprite_dir", ""), template_id_)
	unit.run_frames = _load_run(template_id_)
	unit.action_frames = _load_actions(template_id_)
	unit.team = unit_team
	unit.cell = start_cell
	unit._equip(data.get("weapon", ""))
	if unit_team == Team.ENEMY:
		unit.max_hp = Difficulty.scaled(unit.max_hp, "enemy_hp")
		unit.hp = unit.max_hp
		unit.attack = Difficulty.scaled(unit.attack, "enemy_attack")
	elif unit_team == Team.PLAYER:
		unit.max_hp = Difficulty.scaled(unit.max_hp, "party_hp")
		unit.hp = unit.max_hp
		unit.attack = Difficulty.scaled(unit.attack, "party_attack")
		unit.move_points += Difficulty.move_bonus()
	return unit


## Kind of foe this is, for the capture roll when someone falls to it.
func kind() -> String:
	return Database.unit_template(template_id).get("kind", "default")


## Spawn the battle puppet for a persistent [Character].
static func from_character(source: Character, unit_team: Team, start_cell: Vector2i) -> Unit:
	var unit := create(source.template_id, unit_team, start_cell)
	unit.character = source
	unit.display_name = source.display_name
	unit.job = source.class_name_text()
	unit.max_hp = source.max_hp()
	unit.hp = source.current_hp()
	if source.equipment != "":
		unit.weapon = {}
		unit.weapon_sprites = {}
		unit._equip(source.equipment)
	# create() already folded the template weapon in; keep it on top of the
	# character's own numbers rather than losing it.
	var carried := Gear.bonus(source.equipment, source) if source.equipment != "" else {}
	unit.attack = source.attack() + int(carried.get("attack", unit.weapon.get("attack", 0)))
	unit.defense = source.defense() + int(carried.get("defense", unit.weapon.get("defense", 0)))
	unit.move_points = source.move_points()
	unit.jump = source.jump()
	unit.flash_step = source.flash_step()
	unit.speed = source.speed()
	unit.abilities = source.abilities()
	if unit_team == Team.ENEMY:
		unit.max_hp = Difficulty.scaled(unit.max_hp, "enemy_hp")
		unit.hp = mini(unit.hp, unit.max_hp)
		unit.attack = Difficulty.scaled(unit.attack, "enemy_attack")
	elif unit_team != Team.ALLY:
		# What the land journals' trinkets give every fighter of the company ([D239]).
		var world: World = GameState.world
		unit.attack += roundi(LandJournals.effect(world, "attack"))
		unit.defense += roundi(LandJournals.effect(world, "defense"))
		var hardier := roundi(Difficulty.scaled(unit.max_hp, "party_hp") * (1.0 + LandJournals.effect(world, "health")))
		# Wounds are carried as a fraction, so a tougher party is not healed by it.
		unit.hp = maxi(1, roundi(float(unit.hp) / float(unit.max_hp) * float(hardier)))
		unit.max_hp = hardier
		unit.attack = Difficulty.scaled(unit.attack, "party_attack")
		unit.move_points += Difficulty.move_bonus()
	return unit


## Snap an arbitrary offset to the cardinal direction it leans towards.
static func dominant_direction(delta: Vector2i) -> Vector2i:
	if delta == Vector2i.ZERO:
		return Vector2i.DOWN
	if absi(delta.x) >= absi(delta.y):
		return Vector2i(signi(delta.x), 0)
	return Vector2i(0, signi(delta.y))


static func _load_sprites(dir_path: String, template_id_: String) -> Dictionary:
	var out := {}
	if dir_path == "":
		return out
	for facing_dir: Vector2i in SPRITE_ROTATIONS:
		var path := "%s/%s.png" % [dir_path, SPRITE_ROTATIONS[facing_dir]]
		if ResourceLoader.exists(path):
			out[facing_dir] = load(path)
		elif not SPRITE_ROTATIONS[facing_dir].contains("-"):
			push_warning("Unit: %s is missing the rotation %s" % [template_id_, path])
	return out


## Only a handful of units have a run cycle. The rest keep their standing pose
## and slide, which is what the game did for everybody until now.
static func _load_run(template_id_: String) -> Dictionary:
	var out := {}
	for facing_dir: Vector2i in SPRITE_ROTATIONS:
		var frames := Database.unit_run(template_id_, SPRITE_ROTATIONS[facing_dir])
		if not frames.is_empty():
			out[facing_dir] = frames
	return out


static func _load_actions(template_id_: String) -> Dictionary:
	var out := {}
	for action in ACTIONS:
		var by_facing := {}
		for facing_dir: Vector2i in SPRITE_ROTATIONS:
			var frames := Database.unit_frames(template_id_, action, SPRITE_ROTATIONS[facing_dir])
			if not frames.is_empty():
				by_facing[facing_dir] = frames
		if not by_facing.is_empty():
			out[action] = by_facing
	return out


func is_alive() -> bool:
	return hp > 0


func _equip(equipment_id: String) -> void:
	if equipment_id == "":
		return
	weapon = Database.equipment_piece(equipment_id)
	if weapon.is_empty():
		push_warning("Unit: %s carries unknown equipment '%s'" % [template_id, equipment_id])
		return
	attack += int(weapon.get("attack", 0))
	defense += int(weapon.get("defense", 0))
	weapon_sprites = _load_sprites(weapon.get("sprite_dir", ""), equipment_id)


func is_hostile_to(other: Unit) -> bool:
	return sides_with_party() != other.sides_with_party() or (
		not sides_with_party() and team != other.team
	)


## The party and anyone fighting beside it (see [enum Team] ALLY).
func sides_with_party() -> bool:
	return team == Team.PLAYER or team == Team.ALLY


func take_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	EventBus.unit_damaged.emit(self, amount)
	queue_redraw()
	if hp == 0:
		died.emit()
		EventBus.unit_died.emit(self)


func heal(amount: int) -> void:
	var healed := mini(amount, max_hp - hp)
	hp += healed
	EventBus.unit_healed.emit(self, healed)
	queue_redraw()


func face_towards(target_cell: Vector2i) -> void:
	if target_cell == cell:
		return
	facing = dominant_direction(target_cell - cell)
	queue_redraw()


func snap_to_cell(grid: BattleGrid) -> void:
	position = grid.cell_to_world(cell)


func _process(delta: float) -> void:
	_run_time += delta
	if _action != "":
		_action_time += delta
		# A fall holds its last frame; anything else gives way to the standing pose.
		if _action != "death" and _action_time >= action_length(_action):
			_action = ""
	set_process(_running or (_action != "" and not _action_done()))
	queue_redraw()


## Draw the unit mid-stride while the fight steps it from one tile to the next.
func set_running(running: bool) -> void:
	if _running == running:
		return
	_running = running
	set_process(running or _action != "")
	queue_redraw()


## Play a move once: "attack", "skill", "hit" or "death". A unit without frames
## for it carries on as it was. A flinch does not cut a swing short, and nothing
## but [method stand] takes a unit out of its fall.
func play(action: String) -> void:
	if _action_facings(action).is_empty() or _action == "death":
		return
	if action == "hit" and (_action == "attack" or _action == "skill"):
		return
	_action = action
	_action_time = 0.0
	set_process(true)
	queue_redraw()


## Back on their feet after a fall: the standing pose again.
func stand() -> void:
	_action = ""
	_action_time = 0.0
	queue_redraw()


## The move being played, or "".
func playing() -> String:
	return _action


## Seconds [param action] takes to play through, facing as the unit is now; 0
## when it has no frames for it.
func action_length(action: String) -> float:
	return float(_action_frames_now(action).size()) / ACTION_FPS


## Only a fall is ever left finished and still showing.
func _action_done() -> bool:
	return _action == "death" and _action_time >= action_length("death")


func _action_facings(action: String) -> Dictionary:
	return action_frames.get(action, {})


func _action_frames_now(action: String) -> Array:
	var by_facing := _action_facings(action)
	if by_facing.has(facing):
		return by_facing[facing]
	var cardinal := Vector2i(facing.x, 0) if absi(facing.x) >= absi(facing.y) else Vector2i(0, facing.y)
	return by_facing.get(cardinal, by_facing.get(Vector2i.DOWN, []))


func _draw() -> void:
	var radius := BattleGrid.CELL_SIZE * 0.34
	var outline := Color.WHITE if team == Team.PLAYER else (ALLY_OUTLINE if team == Team.ALLY else Color(0.2, 0.05, 0.05))
	var sprite := current_sprite()
	draw_circle(Vector2(2, 3), radius * clampf(body_scale, 0.7, 1.5), Color(0, 0, 0, 0.3))
	if sprite == null:
		draw_circle(Vector2.ZERO, radius, colour)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, outline, 2.0, true)
	_draw_facing(radius, outline)
	if lying > 0.0 and sprite != null:
		_draw_lying(sprite)
		_draw_hp_bar(sprite)
		return
	# Held behind the body only when the unit has its back to us.
	if facing == Vector2i.UP:
		_draw_weapon()
	if sprite != null:
		draw_texture_rect(sprite, _sprite_rect(sprite), false, tint)
	if facing != Vector2i.UP:
		_draw_weapon()
	_draw_hp_bar(sprite)


## Knocked flat: the body tipped over at the feet, away from the way it looks.
func _draw_lying(sprite: Texture2D) -> void:
	var feet := Vector2(0.0, BattleGrid.CELL_SIZE * (SPRITE_HEIGHT_CELLS * 0.5 - 0.12))
	var side := -1.0 if facing.x > 0 else 1.0
	draw_set_transform(feet, side * lying * PI * 0.5)
	var rect := _sprite_rect(sprite)
	rect.position -= feet
	draw_texture_rect(sprite, rect, false, tint)
	draw_set_transform(Vector2.ZERO)


func _draw_weapon() -> void:
	var texture: Texture2D = weapon_sprites.get(facing)
	if texture == null:
		var cardinal := Vector2i(facing.x, 0) if absi(facing.x) >= absi(facing.y) else Vector2i(0, facing.y)
		texture = weapon_sprites.get(cardinal)
	if texture == null:
		return
	var drawn := texture.get_size() * float(weapon.get("scale", 0.8)) * body_scale
	var offsets: Dictionary = weapon.get("offsets", {})
	var pair: Array = offsets.get(SPRITE_ROTATIONS.get(facing, "south"), [0, 0])
	# Offsets are set for an ordinary body; a bigger one holds it higher and wider.
	var centre := Vector2(pair[0], pair[1]) * body_scale + Vector2(0, -_body_lift())
	draw_texture_rect(texture, Rect2(centre - drawn * 0.5, drawn), false)


## The standing pose for the way the unit faces, whatever it is doing.
func standing_sprite() -> Texture2D:
	if sprites.has(facing):
		return sprites[facing]
	var cardinal := Vector2i(facing.x, 0) if absi(facing.x) >= absi(facing.y) else Vector2i(0, facing.y)
	return sprites.get(cardinal, sprites.get(Vector2i.DOWN, null))


func current_sprite() -> Texture2D:
	if _action != "":
		var played := _action_frames_now(_action)
		if not played.is_empty():
			return played[mini(int(_action_time * ACTION_FPS), played.size() - 1)]
	if _running:
		var frames: Array = run_frames.get(facing, [])
		if frames.is_empty():
			var cardinal := Vector2i(facing.x, 0) if absi(facing.x) >= absi(facing.y) else Vector2i(0, facing.y)
			frames = run_frames.get(cardinal, [])
		if not frames.is_empty():
			return frames[int(_run_time * RUN_FPS) % frames.size()]
	return standing_sprite()


## Top-down art sits centred on its tile, lifted slightly so the ring reads as ground.
## The feet stay where an ordinary unit's are; `body_scale` only adds height above them.
## PixelLab gives a move a bigger canvas than the standing pose, grown evenly round
## it, so every frame is drawn at the standing pose's scale and centred where that
## stands; otherwise a unit would shrink each time it swung.
func _sprite_rect(sprite: Texture2D) -> Rect2:
	var standing := standing_sprite()
	var reference := standing.get_size() if standing != null else sprite.get_size()
	var pixel := BattleGrid.CELL_SIZE * SPRITE_HEIGHT_CELLS * body_scale / reference.y
	var bob := sin(_run_time * 16.0) * 3.0 if _running and run_frames.is_empty() else 0.0
	var feet := BattleGrid.CELL_SIZE * (SPRITE_HEIGHT_CELLS * 0.5 - 0.12)
	var centre := Vector2(0.0, feet - reference.y * pixel * 0.5 + bob)
	var drawn := sprite.get_size() * pixel
	return Rect2(centre - drawn * 0.5, drawn)


## How far a scaled body's middle sits above an ordinary one's.
func _body_lift() -> float:
	return BattleGrid.CELL_SIZE * SPRITE_HEIGHT_CELLS * (body_scale - 1.0) * 0.5


func _draw_facing(radius: float, outline: Color) -> void:
	var forward := Vector2(facing)
	var side := forward.orthogonal()
	var tip := forward * (radius + 7.0)
	var base := forward * (radius + 1.0)
	draw_colored_polygon(
		PackedVector2Array([tip, base + side * 5.0, base - side * 5.0]), outline
	)


func _draw_hp_bar(sprite: Texture2D) -> void:
	var width := float(BattleGrid.CELL_SIZE) * 0.7
	var top := -BattleGrid.CELL_SIZE * 0.45
	if sprite != null:
		var standing := standing_sprite()
		top = _sprite_rect(standing if standing != null else sprite).position.y - 8.0
	var origin := Vector2(-width * 0.5, top)
	var ratio := float(hp) / float(max_hp)
	draw_rect(Rect2(origin, Vector2(width, 4)), Color(0, 0, 0, 0.6))
	draw_rect(Rect2(origin, Vector2(width * ratio, 4)), Color(0.3, 0.85, 0.4))
