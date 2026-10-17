extends RefCounted
## One combatant's real-time state in a [Skirmish]: what it has been told to do,
## what it is doing, and what it is waiting on.
##
## The [Unit] is still the puppet that is drawn and hit; this is the part a turn
## used to hold.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")
const SkirmishPassives := preload("res://src/skirmish/skirmish_passives.gd")

enum Order { NONE, MOVE, ATTACK, CAST, AID }

var unit: Unit
## Quick slots, left to right. See [method SkirmishRules.slots].
var slots: Array[String] = []
var basic: String = "strike"
## Seconds left on each slot's cooldown.
var cooldowns: Array[float] = []

## Use ready skills without being told (Dungeon Settlers' "Auto Skill").
var auto_skill: bool = true
## Stand still and only fight what comes into reach ("Wait for Orders"): the Hold
## stance, or a bearer that carries rather than wanders.
var hold: bool = false
## The stance the player gave this fighter ([D195]): a key of `tactics.stances` in
## `data/skirmish.json`, kept on the [Character] between fights. See [method playing_stance].
var stance: String = "own"

var order: Order = Order.NONE
var order_cell: Vector2i = Vector2i.ZERO
var order_target: Unit = null
var order_slot: int = -1

## Who the basic attack is aimed at right now.
var target: Unit = null
var attack_timer: float = 0.0
var think_timer: float = 0.0

## A skill being wound up: {slot, target (Unit or null), cell, left, total}.
var cast: Dictionary = {}

## A step in progress, from one cell to the next.
var stepping: bool = false
var step_from: Vector2 = Vector2.ZERO
var step_to: Vector2 = Vector2.ZERO
var step_left: float = 0.0
var step_total: float = 0.0

## Seconds left before a downed party member is past saving; 0 when standing.
var near_death: float = 0.0
## Out of the fight for good, one way or the other.
var fallen: bool = false
## Walked off the edge of a fight met on the ground: out of it, alive, and not coming back.
var fled: bool = false
## What [Fate] said when this party member's fall was settled in a fight the
## world started: {outcome, reason, line}; empty until then.
var settled: Dictionary = {}
## Whoever last hurt this fighter, so a fall can name its killer ([D197]); null until struck.
var struck_by: Unit = null
## Kneeling beside a downed ally: seconds of aid still to give.
var aiding: float = 0.0

## Tallies the smoke test and the end-of-fight line read.
var swings: int = 0
var casts: int = 0
## A move under way besides swinging (dodge, kite, flank; [SkirmishBrain.pick_tactic]):
## where it is going, as a test on a cell, and seconds before it is given up.
var tactic_goal: Callable = Callable()
var tactic_left: float = 0.0
## Seconds before this fighter will think of another such move.
var tactic_wait: float = 0.0
## The skill this fighter last let go, by name (the show's corner badge, [D180]).
var last_move: String = ""
## Times a grace stood this fighter back up in the near-death window.
var graces: int = 0
## Landed basic swings not yet counted as practice (`rules.swings_per_practice`).
var practice_swings: int = 0

## What it does without being asked: entries from `data/skirmish.json` → `passives`.
var passives: Array = []
## How an enemy likes to fight: a key of `roles` in `data/skirmish.json`, or "".
var role: String = ""
## Heal skills fire on their own for an ally at or below this share of health.
var heal_below: float = SkirmishRules.AUTO_HEAL_BELOW
## Seconds since this fighter last dealt or took a blow.
var since_hit: float = 99.0
## Health regained in fractions, paid out a point or more at a time.
var regen_pool: float = 0.0
## Running in at a charger's sprint; the next blow lands harder.
var charging: bool = false
## Seconds until a skirmisher or mender will back off again.
var retreat_wait: float = 0.0
## Spent on skills and won back over time; a tired fighter only swings (D59).
var energy: float = 100.0
var energy_max: float = 100.0
## Ran dry: no skills until energy is back to `energy_recover_at` of the bar.
var tired: bool = false
## Seconds left stunned: no stepping, swinging or casting, and any cast is lost.
var stunned: float = 0.0
## Drinking or chewing something: {item, left, total}. Can be hit, cannot be stunned.
var using: Dictionary = {}
## Draughts and herbs this fighter has had this fight.
var items_used: int = 0
## Carries a shield, so a sword swing from the front or side may be blocked.
var shield: bool = false
var blocks: int = 0
var interrupts: int = 0
## A little lunge towards whoever was just hit, drawn and then forgotten.
var bump: float = 0.0
var bump_dir: Vector2 = Vector2.ZERO

## A lead's own way of fighting: an entry of `signatures` in `data/skirmish.json`,
## empty for anyone else (see [SkirmishSignatures]).
var signature: Dictionary = {}
## What the signature keeps track of this fight: orders given, foes learnt, ground planted.
var sig: Dictionary = {}
## Who this fighter came into the fight for: a bearer's rider, a wolf's huntress,
## a shade's raiser.
var bound_to: RefCounted = null
## The mount this fighter rides (Atlas on Sky, D93): while aboard he shares its tile, is drawn
## on its back, and every blow meant for him lands on the mount instead.
var aboard: RefCounted = null
## Seconds stood on the same tile.
var still: float = 0.0
## Seconds left on a mark the other side hits harder.
var marked: float = 0.0
## Damage a ward will still turn aside.
var ward: int = 0
## Short boosts given by someone else, by kind ("pace", "might"): [value, seconds left].
var boosts: Dictionary = {}
## What moves have left on this fighter, by kind ("slow", "burn", "bleed", "knockdown",
## "expose"): {left, total, by, and for a burn or bleed its damage a second} ([SkirmishConditions]).
var conditions: Dictionary = {}
## Stepping out of a wind-up: [the caster, the fight's clock when it stops counting], so the
## miss can show as "Dodged!" when the blow lands where they were ([D192]).
var dodging: Array = []


func _init(source: Unit) -> void:
	unit = source
	basic = SkirmishRules.basic_attack(source)
	slots = SkirmishRules.slots(source)
	for _i in slots.size():
		cooldowns.append(0.0)
	# Nobody opens a fight in the same breath as everyone else — except a Set
	# temper, whose opening charge time on the grid becomes acting at once here.
	passives = SkirmishPassives.for_unit(source)
	signature = Database.skirmish.get("signatures", {}).get(source.template_id, {})
	shield = SkirmishPassives.bears_shield(source)
	energy_max = SkirmishPassives.rule("energy_max", 100.0)
	energy = energy_max
	if not is_party():
		role = SkirmishPassives.role_for(source)
		heal_below = float(role_data().get("heal_below", heal_below))
	attack_timer = randf_range(0.2, 0.8)
	think_timer = randf_range(0.0, SkirmishRules.THINK_INTERVAL)
	if source.character != null and source.character.lean("opening_ct", 0.0) > 0.0:
		attack_timer = 0.0
		think_timer = 0.0
	if is_party() and source.character != null:
		set_stance(source.character.stance)


## Every stance there is, in the order a click on the card steps through them.
static func stances() -> Array[String]:
	var out: Array[String] = []
	for key: String in Database.skirmish.get("tactics", {}).get("stances", {}):
		if not key.begins_with("_"):
			out.append(key)
	return out


## A stance's entry in the data: {word, action, first, drop, seek, hold, tip}.
static func stance_data(name: String) -> Dictionary:
	return Database.skirmish.get("tactics", {}).get("stances", {}).get(name, {})


## Take up [param name]: Hold keeps this ground; the rest walk as their stance says.
## Written back to the [Character], so the next fight opens in it too.
func set_stance(name: String) -> void:
	if not stances().has(name):
		name = "own"
	stance = name
	hold = bool(stance_data(name).get("hold", false))
	if unit.character != null:
		unit.character.stance = name


## The stance this fighter fights in right now: the player's, or "own" for enemies,
## allies, and anyone while the game plays itself (Auto and the who-wins bouts).
func playing_stance() -> String:
	return stance if is_party() and not Pace.auto else "own"


## Whether the stance it fights in now says [param key] (`seek`, `hold`).
func stance_says(key: String) -> bool:
	return bool(stance_data(playing_stance()).get(key, false))


## Standing its ground: told to hold (not counting a Hold stance while Auto plays).
func holding() -> bool:
	return hold and not (stance == "hold" and playing_stance() != "hold")


## The sum of every passive's [param effect], including any it carries on the side
## under `also`.
func effect(name: String) -> float:
	var total := 0.0
	for p: Dictionary in passives:
		if str(p.get("effect", "")) == name:
			total += float(p.get("value", 0.0))
		total += float(p.get("also", {}).get(name, 0.0))
	return total


func has_effect(name: String) -> bool:
	return passives.any(func(p: Dictionary) -> bool: return str(p.get("effect", "")) == name)


func role_data() -> Dictionary:
	return SkirmishPassives.role(role) if role != "" else {}


func is_party() -> bool:
	return unit.team == Unit.Team.PLAYER


## On their feet and in the fight.
func is_standing() -> bool:
	return not fallen and not fled and near_death <= 0.0 and unit.is_alive()


## Standing and there to be aimed at: a rider on a mount's back is not.
func targetable() -> bool:
	return is_standing() and aboard == null


func is_downed() -> bool:
	return not fallen and near_death > 0.0


func is_casting() -> bool:
	return not cast.is_empty()


func is_stunned() -> bool:
	return stunned > 0.0


func is_using() -> bool:
	return not using.is_empty()


## Off the cooldown and with the energy to pay for it.
func slot_ready(slot: int) -> bool:
	return slot >= 0 and slot < slots.size() and cooldowns[slot] <= 0.0 and can_afford(slot)


func can_afford(slot: int) -> bool:
	return not tired and energy >= SkirmishRules.energy_cost(slot_ability(slot))


func spend_energy(ability: Dictionary) -> void:
	energy = maxf(0.0, energy - SkirmishRules.energy_cost(ability))
	if energy < SkirmishPassives.rule("energy_cost", 20.0):
		tired = true


func recover_energy(seconds: float) -> void:
	energy = minf(energy_max, energy + SkirmishPassives.rule("energy_regen", 5.0) * seconds)
	if tired and energy >= energy_max * SkirmishPassives.rule("energy_recover_at", 0.5):
		tired = false


func slot_ability(slot: int) -> Dictionary:
	return Database.ability(slots[slot]) if slot >= 0 and slot < slots.size() else {}


func give(new_order: Order, cell: Vector2i = Vector2i.ZERO, who: Unit = null, slot: int = -1) -> void:
	order = new_order
	order_cell = cell
	order_target = who
	order_slot = slot
	aiding = 0.0
	# A new order is a change of mind: whatever was being wound up is dropped,
	# and so is a draught half-way to the mouth.
	cast = {}
	using = {}
	if new_order == Order.ATTACK:
		target = who


func clear_order() -> void:
	order = Order.NONE
	order_target = null
	order_slot = -1


## What the HUD says this fighter is doing, in a word or two.
func activity() -> String:
	if fallen:
		return "fallen"
	if is_downed():
		return "near death %.0fs" % ceilf(near_death)
	if is_stunned():
		return "stunned"
	if is_using():
		return "using %s" % Gear.display_name(str(using["item"]))
	if aiding > 0.0:
		return "aiding"
	if is_casting():
		var ability := slot_ability(int(cast["slot"]))
		return "casting %s" % ability.get("display_name", "?")
	match order:
		Order.MOVE:
			return "moving"
		Order.ATTACK, Order.CAST:
			return "engaging"
		Order.AID:
			return "going to help"
	if holding():
		return "holding"
	if tired:
		return "tired"
	if target != null and target.is_alive():
		return "fighting"
	return "ready"
