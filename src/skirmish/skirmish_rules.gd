class_name SkirmishRules
extends RefCounted
## The timings of the real-time fight, in one place (see [D36] and
## `docs/investigation/07-dungeon-settlers-combat.md`).
##
## Everything a turn used to decide is priced in seconds here instead: how long
## a tile takes to cross, how often a basic attack lands, how long a skill takes
## to come back. Abilities carry their own `cooldown` and `cast` in
## `data/abilities.json`; the formulas below are only for abilities that do not
## say — the generated skill trees, which nobody authored.

## Simulation step. The fight runs on fixed ticks so it plays out the same at
## any game speed, and so a test can drive it without waiting on frames.
const TICK := 0.05

## Quick slots, left to right. Auto Skill tries them in this order.
const SLOT_KEYS := [KEY_Q, KEY_W, KEY_E, KEY_R]
const SLOT_LABELS := ["Q", "W", "E", "R"]
const SLOT_COUNT := 4

## Seconds a fallen party member stays in reach of help before they are gone
## from the fight. Enemies do not linger.
const NEAR_DEATH := 12.0
## Seconds of kneeling beside someone to get them back on their feet.
const AID_TIME := 2.0
## Health an aided ally gets up with, as a share of their maximum.
const AID_HEALTH := 0.25

## How far a party member will go looking for a fight on their own. Enemies
## always know where you are.
const PARTY_AGGRO_RANGE := 6
## How often a unit reconsiders what it is doing.
const THINK_INTERVAL := 0.5
## Heal skills fire on their own only for an ally at or below this share of health.
const AUTO_HEAL_BELOW := 0.6

## Everyone fights with this many times their health. Hit points were priced
## for turns, where every swing was a decision; in real time the same numbers end
## a fight in seconds, before there is anything to pause and think about. One
## knob, so it can be argued with rather than buried in unit data.
const HEALTH_SCALE := 3.0

## A basic attack every this many seconds at speed 10.
const ATTACK_BASE := 16.0
const ATTACK_FASTEST := 0.8
const ATTACK_SLOWEST := 3.0


## Seconds between basic attacks. Speed was charge time; now it is tempo.
static func attack_interval(unit: Unit) -> float:
	return clampf(ATTACK_BASE / float(maxi(1, unit.speed)), ATTACK_FASTEST, ATTACK_SLOWEST)


## Seconds to step onto [param cell]. Move points were tiles a turn; now they are
## pace. A move of 4 crosses open ground at a little over two tiles a second.
static func step_time(unit: Unit, grid: BattleGrid, cell: Vector2i) -> float:
	var pace := 0.9 + 0.3 * float(maxi(1, unit.move_points))
	return float(maxi(1, grid.move_cost(cell))) / pace


static func cooldown(ability: Dictionary) -> float:
	if ability.has("cooldown"):
		return float(ability["cooldown"])
	if bool(ability.get("heal", false)):
		return snappedf(6.0 + float(ability.get("power", 10)) / 8.0, 0.5)
	if bool(ability.get("bonus", false)):
		return 4.0
	var power := float(ability.get("power", 1.0))
	var splash := int(ability.get("splash", 0))
	return clampf(snappedf(3.0 + power * 4.0 + splash * 2.0, 0.5), 3.0, 14.0)


## Seconds of wind-up before a skill lands. Anything thrown or cast from range
## takes a moment; a blade does not.
static func cast_time(ability: Dictionary) -> float:
	if ability.has("cast"):
		return float(ability["cast"])
	if int(ability.get("range", 1)) <= 1 or bool(ability.get("bonus", false)):
		return 0.0
	return 0.4 + 0.2 * float(ability.get("splash", 0))


## The ability a unit swings with when nobody tells it otherwise: its first one
## that hurts an enemy. Everything else goes on the quick slots.
static func basic_attack(unit: Unit) -> String:
	for ability_id: String in unit.abilities:
		var ability := Database.ability(ability_id)
		if str(ability.get("target", "enemy")) == "enemy" and not bool(ability.get("heal", false)):
			return ability_id
	return "strike"


## Up to four skills, in the order the character knows them, minus the basic attack.
static func slots(unit: Unit) -> Array[String]:
	var basic := basic_attack(unit)
	var out: Array[String] = []
	for ability_id: String in unit.abilities:
		if ability_id == basic or out.has(ability_id):
			continue
		out.append(ability_id)
		if out.size() == SLOT_COUNT:
			break
	return out


static func is_support(ability: Dictionary) -> bool:
	return bool(ability.get("heal", false)) \
			or str(ability.get("target", "enemy")) in ["ally", "self"]
