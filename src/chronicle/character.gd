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

## The five pools of authored history a character can carry, each an id into
## `data/lore/<pool>.json`. They are written with no character in mind and cast
## on late, so every one of them is legitimately empty for a long time.
const TRAIT_POOLS := {
	"background": "backgrounds",
	"grudge": "grudges",
	"hearth": "hearths",
	"creed": "creeds",
	"oath": "oaths",
}

var id: String = ""
var display_name: String = ""
var template_id: String = ""
var class_id: String = ""
## Four-letter temper code; "" for anyone who is not one of the sixteen.
var temper: String = ""
## What they were before the road (see `data/lore/backgrounds.json`).
var background: String = ""
## Who they hate, worth +10% damage against them (see `data/lore/grudges.json`).
var grudge: String = ""
## Where they are from, and where a run of theirs starts (`data/lore/hearths.json`).
var hearth: String = ""
## What they believe, and therefore who they can stand (`data/lore/creeds.json`).
var creed: String = ""
## What they swore and to whom (see `data/lore/oaths.json`).
var oath: String = ""
var origin_story: String = ""
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
## Powers earned and not yet placed. The player spends these; everyone else
## takes the next rung on their own (see [Progression]).
var rungs: int = 0
## Ability ids learned from those trees.
var learned: Array = []
## Ability id -> times landed, which is how a move gets better (see [Proficiency]).
var practice: Dictionary = {}
## Weapon kind ("blade", "bow", "staff", "bare") -> times landed with one in hand.
## Skill with the weapon, apart from skill with any one move (see [Proficiency]).
var arms: Dictionary = {}
## Unit template id -> the level it was when this character first put one down.
## Experience only comes from the first of each kind ([D37], see [Progression]).
var beaten: Dictionary = {}
## Unit template id -> kills of that kind this character helped with but did not
## land. Enough of them teach as much as landing one (see [Progression]).
var assists: Dictionary = {}
## Kinds this character has seen fall where they teach nothing, outside a gate ([D301]): kind -> times.
## The log of foes shows these as still to learn from.
var met: Dictionary = {}
## Kinds this character has been told to look out for in a gate ([D301], the log of foes).
var look_for: Array = []
## The highest floor of the Tower this character has won ([D301]): the Tower is where experience is
## got, so a strong recruit who has never climbed shows it.
var climbed: int = 0
## Doctrine ids this character has read or been taught (never inherited).
var doctrine: Array = []
## Doctrine id -> the world step it was last read, taught or used.
var doctrine_seen: Dictionary = {}
## Self-imposed handicap traded for faster growth.
var yoke: bool = false
## Extra max HP carried from the bed last slept in at home (see [Home]).
var hearth_vigour: int = 0
## Fights they went down in and got up from ([D218]): each leaves a little more health, for good
## (`data/world_rules.json` → `scars`).
var scars: int = 0
## Other character id -> how well the two of them get on (see [Banter]).
var bonds: Dictionary = {}
## What their own arc left them with, for good ([D250]): stat key -> amount.
var marks: Dictionary = {}
## How they fight when the player is playing ([D195]): a key of `tactics.stances` in
## `data/skirmish.json`. Kept between fights; "own" is the fighter's own doctrine.
var stance: String = "own"
## Fights they came through, `{ won, lost }` ([D306]): the one with the most won leads the fights.
var fights: Dictionary = {}
## Other character id -> fights won beside them ([D306]): a party that has fought together works
## as a unit, a little, even without a leader.
var shared: Dictionary = {}
## A sellsword's terms ([D295], [Sellswords]): `{ job, paid }`, the job they were hired for ("gate"
## or "chapter") and what they were paid. Empty for everyone who walks with the company for its own
## sake; a sellsword goes when the job is done.
var contract: Dictionary = {}
## What they are carrying in their head ([D279], [Moods]): `{ id, label, mood, until }`, until a
## world step. Their sum and a base make their mood.
var thoughts: Array = []
## Weapons a smith has honed for them ([D280], [Crafting]): equipment id -> notches, each a point of
## attack while they carry that weapon.
var honed: Dictionary = {}
## Weapons with a rune laid on them ([D299] item 3, [Crafting]): equipment id -> enchantment id, its
## fight passive theirs while they carry that weapon. One a weapon.
var enchanted: Dictionary = {}


static func create(template_id_: String, name_override: String = "", player: bool = false) -> Character:
	var character := Character.new()
	var data := Database.unit_template(template_id_)
	character.id = "%s_%08x" % [template_id_, randi()]
	character.template_id = template_id_
	character.display_name = name_override if name_override != "" else data.get("display_name", template_id_)
	character.is_player = player
	character.hp = -1

	# Traits come off the hero record where there is one; anyone else carries
	# whatever their unit template names, which is usually nothing at all.
	var hero := Database.hero(template_id_)
	var source := hero if not hero.is_empty() else data
	character.temper = str(source.get("temper", ""))
	for field: String in TRAIT_POOLS:
		character.set(field, str(source.get(field, "")))
	character.origin_story = str(source.get("origin", ""))
	# One of the sixteen starts in their own class, and may leave it at level 2.
	character.class_id = Database.own_class(template_id_)
	Gifts.endow(character)
	return character


# --- authored history ---------------------------------------------------------
#
# Five pools, one mechanism. Each of these reads the piece this character was
# cast, and every one of them is allowed to come back empty.


## The piece this character carries from one pool, e.g. `trait_data("creed")`.
func trait_data(field: String) -> Dictionary:
	var pool: String = TRAIT_POOLS.get(field, "")
	if pool == "":
		return {}
	return Database.lore_piece(pool, str(get(field)))


func trait_display(field: String, fallback: String = "—") -> String:
	return str(trait_data(field).get("display_name", fallback))


func background_data() -> Dictionary:
	return trait_data("background")


func background_display() -> String:
	return trait_display("background", "Wanderer")


func creed_display() -> String:
	return trait_display("creed", "Unspoken")


func hearth_display() -> String:
	return trait_display("hearth", "Nowhere in particular")


func grudge_label() -> String:
	return trait_display("grudge", "None")


## The kind of place their hearth names. Since the fall (M13) a run starts
## wherever the lead crash-lands instead (see `src/chronicle/fall.gd`).
func hearth_kind() -> String:
	return str(trait_data("hearth").get("site_kind", ""))


## Whether this target is one of the people they came here about. Any of the
## four match rules on the grudge is enough (see `data/lore/grudges.json`).
func has_grudge_against(target: Node) -> bool:
	if target == null or grudge == "":
		return false
	var rules: Dictionary = trait_data("grudge").get("matches", {})
	if rules.is_empty():
		return false
	var tid: String = target.get("template_id") if "template_id" in target else ""
	if tid in rules.get("templates", []):
		return true
	for fragment: String in rules.get("template_contains", []):
		if fragment in tid:
			return true
	if Faction.of(tid) in rules.get("factions", []):
		return true
	if target.has_method("kind") and target.kind() in rules.get("kinds", []):
		return true
	return false


## What one letter of their temper nudges, or [param fallback] for anyone
## without a temper and for letters that stay silent about this key.
func lean(key: String, fallback: float) -> float:
	if temper == "":
		return fallback
	return Database.temper_lean(temper, key, fallback)


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
	return maxi(1, _stat("max_hp", 20) + hearth_vigour + scar_health())


## What their scars have added to their health ([D218]).
func scar_health() -> int:
	var rules: Dictionary = Database.world_rules.get("scars", {})
	return mini(scars, int(rules.get("most", 5))) * int(rules.get("max_hp", 3))


## One more scar, kept only while there is room for it. Returns the line to say, or "".
func scar() -> String:
	var rules: Dictionary = Database.world_rules.get("scars", {})
	if scars >= int(rules.get("most", 5)):
		return ""
	scars += 1
	return str(rules.get("line", "{name} will carry a scar from that.")).format({
		"name": display_name, "hp": int(rules.get("max_hp", 3)), "scars": scars,
	})


func attack() -> int:
	var value := _stat("attack", 5)
	if yoke:
		value = roundi(value * (1.0 - YOKE_ATTACK_PENALTY))
	# Cold-eyed tempers hit fractionally harder; warm-handed ones buy their edge
	# back when somebody falls (see [Fate]).
	value = roundi(value * lean("damage", 1.0))
	return maxi(1, value)


func defense() -> int:
	return maxi(0, _stat("defense", 0))


func speed() -> int:
	return maxi(1, _stat("speed", 8))


func move_points() -> int:
	var base := int(template().get("move", 3)) + Doctrine.bonus(self, "move")
	return maxi(1, base + int(lean("move", 0.0)))


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
	return roundi(base + growth * float(level - 1)) + Doctrine.bonus(self, key) + int(marks.get(key, 0)) \
		+ mood_edge(key)


## How they feel, as a number ([D279]): the base, and every thought they carry.
func mood() -> int:
	var value := int(Database.world_rules.get("moods", {}).get("base", 50))
	for thought: Dictionary in thoughts:
		value += int(thought.get("mood", 0))
	return value


## What their mood does to [param key] in a fight: the band's own nudge, 0 for most moods.
func mood_edge(key: String) -> int:
	if thoughts.is_empty():
		return 0
	var value := mood()
	for each: Dictionary in Database.world_rules.get("moods", {}).get("bands", []):
		if value < int(each.get("below", 0)):
			return int(each.get(key, 0))
	return 0


# --- serialisation ------------------------------------------------------------


func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"template_id": template_id,
		"class_id": class_id,
		"temper": temper,
		"background": background,
		"grudge": grudge,
		"hearth": hearth,
		"creed": creed,
		"oath": oath,
		"origin_story": origin_story,
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
		"rungs": rungs,
		"learned": learned,
		"practice": practice,
		"arms": arms,
		"beaten": beaten,
		"assists": assists,
		"met": met,
		"look_for": look_for,
		"climbed": climbed,
		"doctrine": doctrine,
		"doctrine_seen": doctrine_seen,
		"yoke": yoke,
		"hearth_vigour": hearth_vigour,
		"scars": scars,
		"bonds": bonds,
		"marks": marks,
		"thoughts": thoughts,
		"honed": honed,
		"enchanted": enchanted,
		"stance": stance,
		"fights": fights,
		"shared": shared,
		"contract": contract,
	}


static func from_dict(data: Dictionary) -> Character:
	var character := Character.new()
	character.id = data.get("id", "")
	character.display_name = data.get("display_name", "")
	character.template_id = data.get("template_id", "")
	character.class_id = data.get("class_id", "")
	character.temper = data.get("temper", "")
	for field: String in TRAIT_POOLS:
		character.set(field, str(data.get(field, "")))
	character.origin_story = data.get("origin_story", "")
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
	character.rungs = int(data.get("rungs", 0))
	character.learned = data.get("learned", [])
	for ability_id: String in data.get("practice", {}):
		character.practice[ability_id] = int(data["practice"][ability_id])
	# Saves from before D37 have none of these; they start empty, which means
	# every kind of enemy is still worth something to someone.
	for kind: String in data.get("arms", {}):
		character.arms[kind] = int(data["arms"][kind])
	for kind: String in data.get("beaten", {}):
		character.beaten[kind] = int(data["beaten"][kind])
	for kind: String in data.get("assists", {}):
		character.assists[kind] = int(data["assists"][kind])
	for kind: String in data.get("met", {}):
		character.met[kind] = int(data["met"][kind])
	for kind: Variant in data.get("look_for", []):
		character.look_for.append(str(kind))
	character.climbed = int(data.get("climbed", 0))
	character.doctrine = data.get("doctrine", [])
	character.doctrine_seen = data.get("doctrine_seen", {})
	character.yoke = bool(data.get("yoke", false))
	character.hearth_vigour = int(data.get("hearth_vigour", 0))
	character.scars = int(data.get("scars", 0))
	for other_id: String in data.get("bonds", {}):
		character.bonds[other_id] = int(data["bonds"][other_id])
	for key: String in data.get("marks", {}):
		character.marks[key] = int(data["marks"][key])
	character.stance = str(data.get("stance", "own"))
	for weapon: String in data.get("honed", {}):
		character.honed[weapon] = int(data["honed"][weapon])
	for weapon: String in data.get("enchanted", {}):
		character.enchanted[weapon] = str(data["enchanted"][weapon])
	for key: String in data.get("fights", {}):
		character.fights[key] = int(data["fights"][key])
	for other_id: String in data.get("shared", {}):
		character.shared[other_id] = int(data["shared"][other_id])
	character.contract = (data.get("contract", {}) as Dictionary).duplicate()
	for thought: Variant in data.get("thoughts", []):
		if thought is Dictionary:
			character.thoughts.append({
				"id": str(thought.get("id", "")), "label": str(thought.get("label", "")),
				"mood": int(thought.get("mood", 0)), "until": int(thought.get("until", 0)),
			})
	return character
