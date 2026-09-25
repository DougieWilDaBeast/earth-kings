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
    game_state.gd              The live World, Roster, stores, stash, gold; save/load
    music.gd                   Scene music tracks and dynamic crossfading
    sfx.gd                     Sound effects hub and UI button listener
    pace.gd                    Engine timescale, quiet chatter, auto-play coordination
  chronicle/                   THE WORLD MODEL (no nodes, no scenes)
    character.gd               Persistent person: level, class, doctrine, permadeath, grudges
    progression.gd             XP curve, level-ups, class choice, branching tree unlocks
    ability_grammar.gd         Hidden grammar; generates skill trees
    doctrine.gd                Read / teach / forget, and the bonuses knowledge grants
    skein.gd                   Story threads, stage transitions, and deadlines
    save_file.gd               Reads JSON back with whole numbers as ints again
    rumour_jobs.gd             News at the inn that posts work on the board (M16)
    nemesis.gd                 Defeated persistent foes who survive, remember, and return
    annals.gd                  Narrative milestone chronicle compiled from telemetry
    season.gd                  Step-clock progression of the four seasonal clovers
    news.gd                    Living continental rumor dispatches and realm tidings
    ferry.gd                   Passage by boat between coastal havens across oceans
    ward.gd                    Obstacle, fallen tree, and sealed gate clearance
    loot.gd · gear.gd          Pack management (`stores`), draughts, calling suit penalties
    proficiency.gd             Mastery-by-use tracking across weapons and abilities
    site.gd                    A place on the map (gate, tower, library, village…)
    world.gd                   Ground, places, the step clock, the tree registry, routes
    world_gen.gd               Builds a 128x128 continental world from a seed
    dispatch.gd                Companions sent away on an errand, on the step clock (M16)
    names.gd                   Regional names and the lead's earned title (D39)
  battle/                      Tactics core (working)
    battle.tscn/.gd            Phase machine, input routing, turn loop, draught usage
    turn_manager.gd            Charge-time order + lookahead
    grid/                      battle_grid · pathfinder · move_field · grid_overlay
    units/unit.gd              The battle puppet spawned from a Character (8-way facing)
    abilities/ability_resolver.gd   Targeting rules, facing bonuses, damage maths, grudges
    ai/enemy_brain.gd          Multi-ability evaluation, ally healing, splash AOE scoring
  skirmish/                    The real-time fight — M11 prototype of D36, beside battle/
    skirmish.tscn/.gd          Fixed-tick loop, pause, orders, stepping, casting, near death
    fighter.gd                 One combatant's real-time state: order, cooldowns, cast, step
    skirmish_brain.gd          Targeting and Auto Skill choices, returned as plans
    skirmish_rules.gd          Every timing in seconds; defaults for generated abilities
    skirmish_marks.gd · skirmish_hud.gd   Rings, bars and lines on the field; the party cards
  world/                       Walk mode: the map, the step clock, every site interaction
    route.gd                   The way across the country on foot, for a party walking itself
  area/                        Places walked around close up — 33 hand-built top-down areas,
                               orthogonal A* pathfinding, props, chests, cutscenes, camp fire
  dialogue/                    Conversation overlay, branching script, skill checks, news
  coliseum/                    Gladiator arena, wave survival, stakes/wagers, free-for-all
  ui/                          Battle HUD, title screen, party screen, system menu, stash,
                               journal (bestiary, routes, annals), museum (hero dossiers)
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

Headless scenes, run as scenes rather than with `-s` because `--script` starts before the
autoloads exist. `walk` and `world` take `-- --check=a,b` to run only those checks
(`tests/check_filter.gd`); each check in both passes on its own.

| Test                             | Covers                                                                                                                                                   |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tests/world_smoke_test.tscn`    | World generation, progression, the ability grammar, doctrine, fate odds over 200 falls, the roster, encounters, battlefield validity, an 800-step walk   |
| `tests/walk_smoke_test.tscn`     | The real walk scene: walls, walking itself round them, the clock, resting, reading, gates, the Tower, the class picker, teaching, the Yoke, a save round trip, and the end of a run |
| `tests/area_smoke_test.tscn`     | Every hand-built area: the party following, townsfolk, cutscenes, chests and props, and the camp fire                                                    |
| `tests/battle_smoke_test.tscn`   | A whole battle played out by the AI, with fate resolved on every fallen character                                                                        |
| `tests/skein_smoke_test.tscn`    | Story threads: ignite rules, stage transitions, deadlines, branch choices, memory persistence                                                            |
| `tests/wishlist_smoke_test.tscn` | Content cross-checks: Journal, Museum, Coliseum, Cinematic boot, ability/hero/unit table integrity                                                       |
| `tests/skirmish_smoke_test.tscn` | The real-time skirmish: pause, orders while paused, cooldowns, auto-pause, near death and aid, and a whole seeded fight on fixed ticks                  |
| `tests/experience_smoke_test.tscn` | First-kill experience, assists, bosses, weapon skill, the save round trip, and a soak of the same kind against new kinds                             |
| `tests/names_smoke_test.tscn` | Regional names — strong beside a keep, stems far away, of a real place — and earned titles in the right order                                     |
| `tests/dispatch_smoke_test.tscn` | Companions sent on errands: leaving, the road on the step clock, being paid, coming home, a hunt won and lost, 400 trips to open gates, and rumours posting jobs |
| `tests/seams_smoke_test.tscn` | Hand-offs: a lived-in run saved, loaded and saved again is the same file with nothing changing type; every rules key the code reads by name exists in the data; every member asked of one of the game's own classes exists on it; every kind of errand is posted whole |

`tests/bench.tscn` (invoked via `.\ek.ps1`) allows developer bootstrapping directly into any scene,
level, site, equipment loadout, or area.

`tools/coverage.tscn` reports static reachability from those tests — which functions a test can
reach, which only the engine reaches, and which nothing references at all. It resolves scenes a
test instantiates to their scripts, so scene-driven code is not counted as unreachable. It
measures **reach, not assertion strength**, so it also prints the assertion count per test.

```powershell
godot --headless --path . res://tools/coverage.tscn
```

## New scripts are loaded by path

Scripts added from 2026-09-24 on are pulled in with `preload("res://…")` and do not declare a
`class_name` ([D41](06-decisions.md)). A global class name resolves only once the editor has
rescanned the project and written it into `.godot/global_script_class_cache.cfg`, which is not
tracked, so a checkout that had not been opened in the editor since could not parse the first
real-time skirmish at all — a blank screen. Older scripts keep their class names; nothing needs
converting, but nothing new should add to them.

## Reading JSON back

JSON has one kind of number, so everything the game writes as a whole number comes back a float.
Wrapping a read in `int()` hides that, but a float is not an int to `Array.has`, `in`, `match`,
array equality or a dictionary key, and `str()` prints it as `3.0` — which is how a gate the party
was inside came back as one it was not. So every save-side file (the save, the museum, the arena
board) is read through `src/chronicle/save_file.gd`, which turns whole floats back into ints once,
at the door ([D42](06-decisions.md)). A value that has to stay a float even when whole (a
generated power) is put back as one where it is loaded. `tests/seams_smoke_test` fails if a save,
loaded and saved again, writes a different file.

The same suite reads the source for every rules key asked for by name (`rules().get("x", …)`,
`Database.encounters.get("y", …)`) and fails if the data does not have it. Every such read carries a
fallback, so a missing or misspelt key never errors — the game plays on the fallback and nobody
tunes it. `bounty_reward` had been doing exactly that.

It also checks every `name.member` where `name` is typed as one of the game's own classes. Godot
does not: an unknown member on a typed variable is only an (ignored) unsafe-access warning, so it
compiles and fails when the line runs. `band.units` on a band that keeps a `pack` did exactly that,
and every bounty a board tried to post came out blank.

## Autoload order

`EventBus` → `Database` → `GameState` → `Music` → `Sfx` → `Pace`. Database must be up before
anything reads content; GameState reads content while restoring a save, and Music/Sfx wire audio
busses and settings from `user://settings.cfg`. `Pace` owns `Engine.time_scale` and whether the game
is playing itself, so both survive a scene swap — a soak started on the road carries through the
fight it walks into.
