extends RefCounted
## One combatant's real-time state in a [Skirmish]: what it has been told to do,
## what it is doing, and what it is waiting on.
##
## The [Unit] is still the puppet that is drawn and hit; this is the part a turn
## used to hold. Kept apart so the turn-based battle is untouched while the two
## are compared.

## Loaded by path, not by `class_name`: a global class name only resolves once the
## editor has rescanned the project, and a checkout that has not been opened in
## the editor since this landed would otherwise fail to parse the whole skirmish.
const SkirmishRules := preload("res://src/skirmish/skirmish_rules.gd")

enum Order { NONE, MOVE, ATTACK, CAST, AID }

var unit: Unit
## Quick slots, left to right. See [method SkirmishRules.slots].
var slots: Array[String] = []
var basic: String = "strike"
## Seconds left on each slot's cooldown.
var cooldowns: Array[float] = []

## Use ready skills without being told (Dungeon Settlers' "Auto Skill").
var auto_skill: bool = true
## Stand still and only fight what comes into reach ("Wait for Orders").
var hold: bool = false

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
## Kneeling beside a downed ally: seconds of aid still to give.
var aiding: float = 0.0

## Tallies the smoke test and the end-of-fight line read.
var swings: int = 0
var casts: int = 0


func _init(source: Unit) -> void:
	unit = source
	basic = SkirmishRules.basic_attack(source)
	slots = SkirmishRules.slots(source)
	for _i in slots.size():
		cooldowns.append(0.0)
	# Nobody opens a fight in the same breath as everyone else.
	attack_timer = randf_range(0.2, 0.8)
	think_timer = randf_range(0.0, SkirmishRules.THINK_INTERVAL)


func is_party() -> bool:
	return unit.team == Unit.Team.PLAYER


## On their feet and in the fight.
func is_standing() -> bool:
	return not fallen and near_death <= 0.0 and unit.is_alive()


func is_downed() -> bool:
	return not fallen and near_death > 0.0


func is_casting() -> bool:
	return not cast.is_empty()


func slot_ready(slot: int) -> bool:
	return slot >= 0 and slot < slots.size() and cooldowns[slot] <= 0.0


func slot_ability(slot: int) -> Dictionary:
	return Database.ability(slots[slot]) if slot >= 0 and slot < slots.size() else {}


func give(new_order: Order, cell: Vector2i = Vector2i.ZERO, who: Unit = null, slot: int = -1) -> void:
	order = new_order
	order_cell = cell
	order_target = who
	order_slot = slot
	aiding = 0.0
	# A new order is a change of mind: whatever was being wound up is dropped.
	cast = {}
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
	if hold:
		return "holding"
	if target != null and target.is_alive():
		return "fighting"
	return "ready"
