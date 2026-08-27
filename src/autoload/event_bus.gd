extends Node
## Global signal hub (autoload: `EventBus`).
##
## Systems emit and listen here instead of holding references to each other,
## so battle / overworld / UI stay decoupled and independently testable.

## Ask the root [Game] node to swap the active scene ("overworld" | "battle").
signal request_scene(scene_key: String, payload: Dictionary)

signal battle_started(map_id: String)
## result: { "victory": bool, "map_id": String, "turns": int }
signal battle_finished(result: Dictionary)

signal turn_started(unit: Node)
signal turn_ended(unit: Node)
signal unit_damaged(unit: Node, amount: int)
signal unit_healed(unit: Node, amount: int)
signal unit_died(unit: Node)

signal dialogue_requested(dialogue_id: String)
signal dialogue_finished(dialogue_id: String)

## A party member hit level 2 and owes the player a decision.
signal class_choice_required(character: RefCounted)
signal class_chosen(character: RefCounted)
## A character went down. outcome: { "outcome": "alive"|"captured"|"dead", "reason": String, "line": String }
signal character_fell(character: RefCounted, outcome: Dictionary)

## Ask the always-present system menu (save / load / title) to open.
signal system_menu_requested
## Ask the always-present party screen to open.
signal party_screen_requested
## The last of the party is gone; the run is over.
signal run_ended

## Human-readable combat log line, rendered by the battle HUD.
signal battle_log(line: String)
