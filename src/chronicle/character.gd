class_name Character
extends RefCounted
## A persistent person in the world — the thing that levels, learns, and dies.
##
## Battle [Unit]s are spawned *from* a Character and thrown away when the fight
## ends; the Character is what the save file remembers.

## Fraction of attack given up while the Training Yoke stance is held.
const YOKE_ATTACK_PENALTY := 0.25
## Extra XP earned in exchange for that handicap (docs/16).
const YOKE_XP_BONUS := 0.5

var id: String = ""
var display_name: String = ""
var template_id: String = ""
var class_id: String = ""
## Set when the character reaches level 2 with a choice still to make.
var pending_class_choice: bool = false
var level: int = 1
var xp: int = 0
## Current health; -1 means untracked, i.e. full.
var hp: int = -1
## alive | captured | dead (see [Fate]).
var status: String = "alive"
## Where they are being held, if taken alive.
var captured_at: String = ""
## Terms of that captivity: cell, ransom, and the step it runs out (see [Captivity]).
var captive: Dictionary = {}
var is_player: bool = false

## Charms and relics carried; some are spent to cheat death (see [Fate]).
var charms: Array = []
## Bought gear, overriding whatever the template came with.
var equipment: String = ""

## Generated skill trees unlocked at levels 5 and 10 (see [AbilityGrammar]).
var trees: Array = []
## Ability ids learned from those trees.
var learned: Array = []
## Ability id -> times landed, which is how a move gets better (see [Proficiency]).
var practice: Dictionary = {}
## Doctrine ids this character has read or been taught (never inherited).
var doctrine: Array = []
## Doctrine id -> the world step it was last read, taught or used.
var doctrine_seen: Dictionary = {}
## Self-imposed handicap traded for faster growth.
var yoke: bool = false
## Extra max HP carried from the bed last slept in at home (see [Home]).
var hearth: int = 0
## Other character id -> how well the two of them get on (see [Banter]).
var bonds: Dictionary = {}


static func create(template_id_: String, name_override: String = "", player: bool = false) -> Character:
	var character := Character.new()
	var data := Database.unit_template(template_id_)
	character.id = "%s_%08x" % [template_id_, randi()]
	character.template_id = template_id_
	character.display_name = name_override if name_override != "" else data.get("display_name", template_id_)
	character.is_player = player
	character.hp = -1
	return character


func template() -> Dictionary:
	return Database.unit_template(template_id)


func class_data() -> Dictionary:
	return Database.character_class(class_id)


func class_name_text() -> String:
	if class_id == "":
		return template().get("job", "Unproven")
	return class_data().get("display_name", class_id)


# --- derived stats ------------------------------------------------------------
#
# Base block from the unit template, plus class growth per level above 1, plus
# whatever doctrine the character personally carries.


func max_hp() -> int:
	return maxi(1, _stat("max_hp", 20) + hearth)


func attack() -> int:
	var value := _stat("attack", 5)
	if yoke:
		value = roundi(value * (1.0 - YOKE_ATTACK_PENALTY))
	return maxi(1, value)


func defense() -> int:
	return maxi(0, _stat("defense", 0))


func speed() -> int:
	return maxi(1, _stat("speed", 8))


func move_points() -> int:
	return maxi(1, int(template().get("move", 3)) + Doctrine.bonus(self, "move"))


func jump() -> int:
	return maxi(0, int(template().get("jump", 1)) + Doctrine.bonus(self, "jump"))


## Blink range in tiles; 0 means this character cannot flash step at all.
func flash_step() -> int:
	var base := maxi(
		int(template().get("flash_step", 0)), int(class_data().get("flash_step", 0))
	)
	if base <= 0:
		return 0
	return maxi(0, base + Doctrine.bonus(self, "flash_step"))


## Everything this character can actually cast: template kit + class grants +
## abilities learned from unlocked trees.
func abilities() -> Array:
	var out: Array = []
	for ability_id: String in template().get("abilities", ["strike"]):
		if ability_id not in out:
			out.append(ability_id)
	for ability_id: String in class_data().get("grants", []):
		if ability_id not in out:
			out.append(ability_id)
	for ability_id: String in learned:
		if ability_id not in out:
			out.append(ability_id)
	return out


func current_hp() -> int:
	return max_hp() if hp < 0 else clampi(hp, 0, max_hp())


func is_alive() -> bool:
	return status == Fate.ALIVE


func is_lost() -> bool:
	return status == Fate.DEAD or status == Fate.CAPTURED


## Can this character be taken into a fight right now?
func is_available() -> bool:
	return is_alive() and current_hp() > 0


func is_wounded() -> bool:
	return hp >= 0 and hp < max_hp()


func knows(doctrine_id: String) -> bool:
	return doctrine_id in doctrine


func _stat(key: String, fallback: int) -> int:
	var base := float(template().get(key, fallback))
	var growth := float(class_data().get("growth", {}).get(key, 0.0))
	return roundi(base + growth * float(level - 1)) + Doctrine.bonus(self, key)


# --- serialisation ------------------------------------------------------------


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"template_id": template_id,
		"class_id": class_id,
		"pending_class_choice": pending_class_choice,
		"level": level,
		"xp": xp,
		"hp": hp,
		"status": status,
		"captured_at": captured_at,
		"captive": captive,
		"is_player": is_player,
		"charms": charms,
		"equipment": equipment,
		"trees": trees,
		"learned": learned,
		"practice": practice,
		"doctrine": doctrine,
		"doctrine_seen": doctrine_seen,
		"yoke": yoke,
		"hearth": hearth,
		"bonds": bonds,
	}


static func from_dict(data: Dictionary) -> Character:
	var character := Character.new()
	character.id = data.get("id", "")
	character.display_name = data.get("display_name", "")
	character.template_id = data.get("template_id", "")
	character.class_id = data.get("class_id", "")
	character.pending_class_choice = bool(data.get("pending_class_choice", false))
	character.level = int(data.get("level", 1))
	character.xp = int(data.get("xp", 0))
	character.hp = int(data.get("hp", -1))
	character.status = data.get("status", "alive")
	character.captured_at = data.get("captured_at", "")
	character.captive = data.get("captive", {})
	character.is_player = bool(data.get("is_player", false))
	character.charms = data.get("charms", [])
	character.equipment = data.get("equipment", "")
	character.trees = data.get("trees", [])
	character.learned = data.get("learned", [])
	for ability_id: String in data.get("practice", {}):
		character.practice[ability_id] = int(data["practice"][ability_id])
	character.doctrine = data.get("doctrine", [])
	character.doctrine_seen = data.get("doctrine_seen", {})
	character.yoke = bool(data.get("yoke", false))
	character.hearth = int(data.get("hearth", 0))
	for other_id: String in data.get("bonds", {}):
		character.bonds[other_id] = int(data["bonds"][other_id])
	return character
