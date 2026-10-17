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
scenes                 world walk / the fight / dialogue — presentation and input only
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
    pad.gd                     Last device used, pad/key names for hint lines, menu focus on a pad
    play_log.gd                The play log a tester hands over: what they did, timed (D125)
  chronicle/                   THE WORLD MODEL (no nodes, no scenes)
    character.gd               Persistent person: level, class, doctrine, permadeath, grudges
    progression.gd             XP curve, level-ups, class choice, branching tree unlocks
    ability_grammar.gd         Hidden grammar; generates skill trees
    doctrine.gd                Read / teach / forget, and the bonuses knowledge grants
    skein.gd                   Story threads, stage transitions, and deadlines
    save_file.gd               Reads JSON back with whole numbers as ints; writes a save atomically with a backup
    save_migrations.gd         Upgrades an old save one version at a time (D56)
    rumour_jobs.gd             News at the inn that posts work on the board (M16)
    chapters.gd                The Tower in chapters: the world moving on, the census, the seal (M14)
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
    guild.gd                   The Adventurers Guild: the gate register and contracts (M14)
    atlas.gd                   The party's map: explored, charted, marked; Guild maps, found maps (M18)
    sixteen.gd                 Who of the sixteen has fallen, kept outside the save (M15, D47)
    run_mode.gd                Classic or Iron Man: saving by hand, the reload, the save points (M15, D51)
    names.gd                   Regional names and the lead's earned title (D39)
    fall.gd                    Crash sites, the landing beat, "Ascend to heaven" (M13)
    wanderers.gd               The others of the sixteen, walking between places by temper (M13)
    siblings.gd                Sibling worlds: the earlier lead alive, their weapon, their ghost (M15)
  battle/                      What the fight is built on: the field and the people on it
    grid/                      battle_grid · pathfinder · move_field · grid_overlay
    units/unit.gd              The battle puppet spawned from a Character (8-way facing)
    abilities/ability_resolver.gd   Targeting rules, facing bonuses, damage maths, grudges
  skirmish/                    The fight: real time with pause (M11, D36, D64) — every fight
                               the world starts, the coliseum and training (scene key `skirmish`)
    skirmish.tscn/.gd          Fixed-tick loop, pause, orders, stepping, casting, near death;
                               the encounter in, and experience, wounds and the fallen out (D65)
    fighter.gd                 One combatant's real-time state: order, cooldowns, cast, step
    skirmish_brain.gd          Targeting and Auto Skill choices, returned as plans
    skirmish_rules.gd          Every timing in seconds; defaults for generated abilities
    skirmish_passives.gd       Passives and enemy roles, read from data/skirmish.json
    skirmish_signatures.gd     The sixteen's own ways of fighting: bearer, wolf, shades and the rest
    skirmish_marks.gd · skirmish_hud.gd   Rings, bars and lines on the field; the party cards
    skirmish_fx.gd · skirmish_slot.gd     Numbers, flashes and rings; a skill tile's cooldown sweep
  world/                       The continent: the step clock and every site interaction, run out
                               of sight beside the land on each step (D84); the map from the journal (D61)
    route.gd                   The way across the country on foot, for a party walking itself
    auto_road.gd               Where a party walking itself steps next, asked by the map and the land (D94)
    world_end.gd               The last look at a world whose lead died and ascended (M15, D32)
  area/                        The ground, where the game is played (D50, D61) — 34 hand-built
                               top-down areas, orthogonal A* pathfinding, props sized by
                               data/props.json (some animated), buildings drawn from their art,
                               chests, cutscenes, camp fire. land.gd is the continent as one
                               stretch of ground (D84): each tile a slot laid out by ground_gen.gd
                               from its land (chronicle/biome.gd), a place standing in its own,
                               held round the party and let go behind it; crossing into the next
                               tile asks world/ for the step out of sight (game.gd runs it). Bands
                               stand on it, patrol and walk tile to tile, watching (area_watch.gd),
                               and are fought there (D66, D68, D72). first_road.gd lays the
                               First Hour's road from the crater through the city and the first
                               gate to the Tower (D126); where two lands meet, ground_gen.gd runs the next land's
                               floor a few cells in (D128), and places its scenery by rule (D130).
                               area_critter.gd: the birds and bugs about every tile (D179); tracks.gd
                               the dirt tracks between villages and the signposts where ways meet (D212)
  dialogue/                    Conversation overlay, branching script, skill checks, news;
                               talk.gd builds a person's conversation from their `talk` block
  coliseum/                    Gladiator arena, wave survival, stakes/wagers, free-for-all
  ui/                          Title screen, party screen, system menu, stash,
                               Guild hall, journal (the company's sheets, bestiary, routes, annals,
                               quests), museum (hero dossiers), the level-up line at the top right,
                               credits (credits_roll.gd lays out data/credits.json for both places);
                               sheet_parts.gd draws class colours and growth wherever they show;
                               the tutorial's guide card (tutorial_guide.gd, under the game root)
```

## Character vs Unit

The single most important split in the codebase.

|             | `Character`                               | `Unit`                     |
| ----------- | ----------------------------------------- | -------------------------- |
| Lives in    | `src/chronicle/`                          | `src/battle/units/`        |
| Is a        | `RefCounted` data object                  | `Node2D` that draws itself |
| Lifetime    | The whole save                            | One fight                  |
| Knows about | Levels, XP, class, doctrine, death        | HP, cell, facing           |
| Stats       | Computed from template + class + doctrine | Copied in at spawn         |

A fight reads Characters in and writes results back out (wounds as a share of health, experience,
practice, the fallen through `Fate`). Nothing in `src/battle/` or `src/skirmish/` may store
long-term state.

## The seams

Places deliberately shaped so deferred features drop in without surgery.

- **The mind seam.** `SkirmishBrain` returns choices — who to go after, which ready skill on whom —
  and only the fight (`Skirmish`) carries them out. AI never mutates state. Swapping in an LLM mind
  means returning the same answers from a different source.
- **The authority seam.** `World` is one object with `to_dict()` / `from_dict()`. If the world
  ever moves to a server, the client keeps the same shape and asks for it over HTTP instead of
  generating it.
- **The narrative seam.** Every consequential event already emits `EventBus.battle_log(line)`.
  A Chronicle writer subscribes to that and needs nothing else.

## Determinism

`World.rng` is a seeded `RandomNumberGenerator` and is the only source of world randomness —
generation, gate ranks, tree generation, class choice. Same seed, same world. Fight-time
variance (damage rolls, opening tempo, criticals) uses global randomness and is intentionally not
reproducible; settling a fall uses `World.rng`, as it always has.

## Testing

Headless scenes, run as scenes rather than with `-s` because `--script` starts before the
autoloads exist. `walk` and `world` take `-- --check=a,b` to run only those checks
(`tests/check_filter.gd`); each check in both passes on its own.

| Test                             | Covers                                                                                                                                                   |
| -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `tests/world_smoke_test.tscn`    | World generation, progression, the ability grammar, doctrine, fate odds over 200 falls, the roster, encounters, battlefield validity, an 800-step walk, the First Hour's road, the seams between lands, trees off the road |
| `tests/walk_smoke_test.tscn`     | The real walk scene: walls, walking itself round them, the Tower's chapters and seal, the clock, resting, reading, gates, the Tower, the class picker, teaching, the Yoke, a save round trip, the fall (crash site, the others walking, meeting and joining one), and the end of a run |
| `tests/area_smoke_test.tscn`     | Every hand-built area: the party following, townsfolk, cutscenes, chests and props, and the camp fire; every `talk` block leads somewhere and sells real things; buying, a bribe and a favour paid; the tutorial's steps, its never saving, and walking it to its fifth step; Atlas's last stand played to its end against a copy of the record of the fallen (he falls once, the quiz is next, a replay writes nothing, a skip still falls, D191) |
| `tests/skein_smoke_test.tscn`    | Story threads: ignite rules, stage transitions, deadlines, branch choices, memory persistence                                                            |
| `tests/wishlist_smoke_test.tscn` | Content cross-checks: Journal, Museum, Coliseum, site art, ability/hero/unit table integrity                                                       |
| `tests/skirmish_smoke_test.tscn` | The fight: pause, orders while paused, cooldowns, auto-pause, near death and aid, a whole seeded fight on fixed ticks, D59's rules, allies and auto, and a fight on the road written back onto the world (experience, practice, the journal, a healer, draughts, wounds, a fall settled by Fate, `battle_finished`) |
| `tests/experience_smoke_test.tscn` | First-kill experience, assists, bosses, weapon skill, the save round trip, and a soak of the same kind against new kinds                             |
| `tests/names_smoke_test.tscn` | Regional names — strong beside a keep, stems far away, of a real place — and earned titles in the right order                                     |
| `tests/dispatch_smoke_test.tscn` | Companions sent on errands: leaving, the road on the step clock, being paid, coming home, a hunt won and lost, 400 trips to open gates, and rumours posting jobs |
| `tests/art_smoke_test.tscn` | The size-test importer: a PixelLab-shaped export unpacked into place with its prompt kept, and previews never passed off as generated art |
| `tests/seams_smoke_test.tscn` | Hand-offs: a lived-in run saved, loaded and saved again is the same file with nothing changing type; every rules key the code reads by name exists in the data; every member asked of one of the game's own classes exists on it; every kind of errand is posted whole; an old save is upgraded, a newer one refused untouched, and a corrupt one loaded from its backup |

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

Writing goes through the same file. `SaveFile.write` writes the whole save to a `.tmp` beside it,
moves the old save to `.bak.json` and renames the new one into place, so a crash leaves a good save
or a good backup, never half a file. `GameState.load_save` falls back to that backup when the save
will not parse, upgrades an older save through `save_migrations.gd`, and refuses a newer one without
touching it; an old or newer save is copied aside as `.v<N>.bak.json` first ([D56](06-decisions.md)).
What the player should hear about goes out as `EventBus.save_notice` and is shown by a toast on the
root (`src/ui/save_toast.gd`).

The same suite reads the source for every rules key asked for by name (`rules().get("x", …)`,
`Database.encounters.get("y", …)`) and fails if the data does not have it. Every such read carries a
fallback, so a missing or misspelt key never errors — the game plays on the fallback and nobody
tunes it. `bounty_reward` had been doing exactly that.

It also checks every `name.member` where `name` is typed as one of the game's own classes. Godot
does not: an unknown member on a typed variable is only an (ignored) unsafe-access warning, so it
compiles and fails when the line runs. `band.units` on a band that keeps a `pack` did exactly that,
and every bounty a board tried to post came out blank.

## Autoload order

`EventBus` → `Database` → `GameState` → `Music` → `Sfx` → `Pace` → `Pad` → `PlayLog`. Database must be up before
anything reads content; GameState reads content while restoring a save, and Music/Sfx wire audio
buses and settings from `user://settings.cfg`. `Pace` owns `Engine.time_scale` and whether the game
is playing itself, so both survive a scene swap — a soak started on the road carries through the
fight it walks into. `Pad` remembers whether a game pad or a keyboard was touched last, says the
right button in hint lines (`Pad.key("interact")` is "A" or "E"), and keeps a button focused on
whatever modal screen or menu scene is up while a pad is in use; the walk and the fights steer
themselves (a cursor in the fights). `PlayLog` only listens: it writes a timed line for each place
walked into, fight and result, level, save, fall and engine error to `user://earth-kings.playlog.txt`
(the last 400 lines), and the system menu's **Copy play log** / **Save play log** hand it over (D125).
