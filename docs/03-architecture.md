# 03 — Architecture

## Layers

```
data/*.json            content — no logic
  ▲
Database (autoload)    loads, caches, and serves content; holds generated abilities
  ▲
src/chronicle/         the world model — pure logic, no nodes, fully serialisable
  ▲
GameState (autoload)   owns the live World + Roster; save/load
  ▲
scenes                 world walk / battle / dialogue — presentation and input only
  ▲
EventBus (autoload)    how any of the above talk to each other
```

The rule that keeps this honest: **`src/chronicle/` never touches a scene node.** It is plain
`RefCounted` classes that can be constructed, stepped and serialised headlessly — which is what
makes the smoke tests possible and what would make a server port possible later.

## Code map

```
src/
  main.tscn / game.gd          Root: swaps the active scene, hosts dialogue + menu overlays
  autoload/
    event_bus.gd               Global signal hub
    database.gd                data/ loader + runtime registry for generated abilities
    game_state.gd              The live World and Roster; save/load
  chronicle/                   THE WORLD MODEL (no nodes, no scenes)
    character.gd               Persistent person: level, class, doctrine, permadeath
    progression.gd             XP curve, level-ups, class choice, tree unlocks
    ability_grammar.gd         Hidden grammar; generates skill trees
    doctrine.gd                Read / teach / forget, and the bonuses knowledge grants
    site.gd                    A place on the map (gate, tower, library, village…)
    world.gd                   Ground, places, the step clock, the tree registry
    world_gen.gd               Builds a world from a seed
  battle/                      Tactics core (working)
    battle.tscn/.gd            Phase machine, input routing, turn loop
    turn_manager.gd            Charge-time order + lookahead
    grid/                      battle_grid · pathfinder · move_field · grid_overlay
    units/unit.gd              The battle puppet spawned from a Character
    abilities/ability_resolver.gd   Targeting rules, facing bonuses, damage maths
    ai/enemy_brain.gd          Plans a move + attack; returns it for the controller to execute
  world/                       Walk mode: the map, the step clock, every site interaction
  area/                        Places walked around close up — towns, halls, the camp fire
  dialogue/                    Conversation overlay
  ui/                          Battle HUD, title screen, party screen, system menu
```

## Character vs Unit

The single most important split in the codebase.

|             | `Character`                               | `Unit`                     |
| ----------- | ----------------------------------------- | -------------------------- |
| Lives in    | `src/chronicle/`                          | `src/battle/units/`        |
| Is a        | `RefCounted` data object                  | `Node2D` that draws itself |
| Lifetime    | The whole save                            | One battle                 |
| Knows about | Levels, XP, class, doctrine, death        | HP, cell, facing, CT       |
| Stats       | Computed from template + class + doctrine | Copied in at spawn         |

Battles read Characters in and write results back out. Nothing in `src/battle/` may store
long-term state.

## The seams

Places deliberately shaped so deferred features drop in without surgery.

- **The mind seam.** `EnemyBrain.plan()` returns a _plan dictionary_ which the battle controller
  executes. AI never mutates state. Swapping in an LLM mind means returning the same dictionary
  from a different source.
- **The authority seam.** `World` is one object with `to_dict()` / `from_dict()`. If the world
  ever moves to a server, the client keeps the same shape and asks for it over HTTP instead of
  generating it.
- **The narrative seam.** Every consequential event already emits `EventBus.battle_log(line)`.
  A Chronicle writer subscribes to that and needs nothing else.

## Determinism

`World.rng` is a seeded `RandomNumberGenerator` and is the only source of world randomness —
generation, gate ranks, tree generation, class choice. Same seed, same world. Battle-time
variance (damage rolls, CT jitter) uses global randomness and is intentionally not reproducible.

## Testing

Three headless scenes, run as scenes rather than with `-s` because `--script` starts before the
autoloads exist.

| Test                           | Covers                                                                                                                                                   |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tests/world_smoke_test.tscn`  | World generation, progression, the ability grammar, doctrine, fate odds over 200 falls, the roster, encounters, battlefield validity, an 800-step walk   |
| `tests/walk_smoke_test.tscn`   | The real walk scene: walls, the clock, resting, reading, gates, the Tower, the class picker, teaching, the Yoke, a save round trip, and the end of a run |
| `tests/area_smoke_test.tscn`   | Every hand-built area: the party following, townsfolk, cutscenes, chests and props, and the camp fire                                                    |
| `tests/battle_smoke_test.tscn` | A whole battle played out by the AI, with fate resolved on every fallen character                                                                        |

`tools/coverage.tscn` reports static reachability from those tests — which functions a test can
reach, which only the engine reaches, and which nothing references at all. It resolves scenes a
test instantiates to their scripts, so scene-driven code is not counted as unreachable. It
measures **reach, not assertion strength**, so it also prints the assertion count per test.

```powershell
godot --headless --path . res://tools/coverage.tscn
```

## Autoload order

`EventBus` → `Database` → `GameState` → `Music` → `Pace`. Database must be up before anything
reads content; GameState reads content while restoring a save, and Music reads `data/music.json`.
`Pace` owns `Engine.time_scale` and whether the game is playing itself, so both survive a scene
swap — a soak started on the road carries through the fight it walks into.
