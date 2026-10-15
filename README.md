# Earth Kings

A tactical RPG in a persistent, hostile world, built in **Godot 4 (GDScript)**. You walk a
generated map tile by tile, fight what finds you on a Final Fantasy Tactics–style grid, and grow
characters who can die for good. Power is scarce, knowledge is carried rather than inherited, and
the world advances every step you take.

**Where it is going.** Sixteen demigods fall into sixteen copies of Earth and forget who they were.
You are one of them, climbing the Tower at the centre of your world towards a contest only one world
survives. When you die your world ends, and you go on as another of the sixteen, in theirs, from
level 1. Agreed by both founders on 2026-09-24 and not yet built — see
[docs/17](docs/17-the-sixteen-worlds.md), and [docs/18](docs/18-combat-direction.md) for the move to
a real-time-with-pause fight. What follows describes the build as it plays today.

**What plays today is the First Hour**: Atlas falls into a crater, walks to the Tower's city,
shuts the first gate and climbs the Tower's first five floors to his chapter one. See
[docs/28](docs/28-the-first-hour.md) for the route, the play-tests and every build on itch.

**Start here: [docs/00-index.md](docs/00-index.md)** — vision, design, architecture, data formats,
roadmap and the decision log.

## Running it

1. Install [Godot 4.4+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select `project.godot` in this folder.
3. Press **F5**.

Nothing to download —terrain, UI and any unit without art render from primitives, so systems can
be built and tested before the art exists. Units with a `sprite_dir` draw their art instead.

## Builds for players

`export_presets.cfg` holds four presets — **Windows**, **Linux**, **macOS** and **Web** — and the
`release` workflow (`.github/workflows/release.yml`) exports all four headless on GitHub:

- **A test build:** Actions → _release_ → _Run workflow_. The four zips come back as one artifact
  on the run.
- **A release:** push a tag such as `v0.2.0`. The tag becomes the version on the title screen, and
  the four zips are attached to a GitHub pre-release.
- **Locally:** install the 4.7.2 export templates (Editor → Manage Export Templates), then
  `godot --headless --path . --export-release Linux` (the path is in the preset, under the
  gitignored `builds/`).

The Web build runs without threads, so it plays from any static host (itch.io included) with no
special headers. The macOS build is ad-hoc signed and not notarized: players right-click → Open the
first time. Windows builds are unsigned, so SmartScreen will ask once.

## Playing the vertical slice

- **Title** — _Continue_ loads `user://earth-kings.save.json`, _New Game_ starts a fresh run on the one world, the same map every game ([docs/27](docs/27-the-world.md)).
  The first time the game opens with no run to continue it offers a **tutorial** (afterwards the
  title's _Tutorial_ button): a guided practice run in the training village of Hearthwick, with a
  sparring fight met on the village ground, never saved ([D73](docs/06-decisions.md)–[D75](docs/06-decisions.md)).
- **Who you are** — one of **the sixteen**, Atlas to Liber, one per temper, each in their own body
  and their own class ([D78](docs/06-decisions.md)). The other fifteen come down too and can be met
  and recruited. The original twelve (Bram, Sera, Toln and the rest) are story people met in the
  world, each where their backstory puts them ([D79](docs/06-decisions.md)).
- **The opening** — once you have picked your lead, a new game plays a cinematic of what the game is about: the sixteen, the
  fall, the Tower, and what happens when you die ([docs/25](docs/25-the-opening.md)). Click or Space
  moves on a shot, Esc skips it.
- **Classic or Iron Man** — picked next to the seed when you begin (**Mode**), shown in the menu,
  kept in the save. **Classic** saves by hand from the menu, and the game also saves when you set
  out, when you rest and when a Tower chapter ends. **Iron Man** has no Save or Load button: the game
  saves itself at those points, every time you come back to the map, and when you leave.
- **Learning as you go** — _How to Play_ (on the title screen and in the `Esc` menu) is the short
  version of this list. In a run, a small card under the top bar explains each thing the first
  time you meet it — the road, danger, a fight, facing, a fall, a town, a gate, the Tower,
  level 2 — then never again. Cards go away by themselves, never take a key, and stay quiet while
  the game plays itself. They are remembered per player in `settings.cfg`, not per save; the menu
  has _Tips: on/off_ and _Reset tips_.
- **Walking** — WASD (or the arrow keys) move you one tile at a time; hold to keep going. Every step advances
  the world clock. The top bar shows where you are, the season, your gold and how many bands are abroad.
  `Esc` opens the menu (save and load in Classic, music and sound volume, fullscreen, return to title).
  `F11` switches fullscreen anywhere.
- **On a controller** — any Xbox or PlayStation pad (Godot's standard mapping) plays the whole game.
  Hint lines switch to the pad's buttons as soon as it is touched, and back on a key press.

  | Button                   | On the road / in a town                    | In a fight                     |
  | ------------------------ | ------------------------------------------ | ------------------------------ |
  | Left stick / D-pad       | Walk                                       | Move the cursor                |
  | A (Cross)                | Interact, step in, confirm                 | Pick a fighter, give the order |
  | B (Circle)               | Back / the menu                            | Put a skill away; the menu     |
  | X (Square)               | Journal                                    | Pause / resume                 |
  | Y (Triangle)             | Focus the place's buttons (hire, buy, …)   | Next skill                     |
  | Start / Back             | Menu / party                               | Menu / select everyone         |
  | LB / RB                  | Speed / next leader in a town              | Speed / next fighter           |
  | LT / RT                  | Zoom out / in                              | Zoom out / in                  |
  | Right stick / L3 / R3    | Look around / — / recentre                 | Look around                    |

  Every menu is walked with the D-pad and pressed with A. The system menu's _Controls_ lists the
  pad button beside each key, and rebinds a pad button the same way it rebinds a key.
- **Letting it play itself** — `Q` hands the run to the game on the road or in a town, and `T`
  cycles the speed everywhere. `Q` again takes it back anywhere, even mid-fight, which then pauses
  for your first order. The party walks to whatever is worth reaching, fights it,
  and answers its own conversations. Both survive a scene change, so a soak keeps going.
- **The journal** (`N`) — a leather book found in the crater at the landing. Its first page,
  _The Company_, is a sheet for each companion: every number and what a level adds, the class's
  growth, gear, powers and what they have learned from ([D67](docs/06-decisions.md)). Then the
  Bestiary, Routes & Renown, the Annals, and Quests & the Fallen.
- **The map** — kept in the journal (`N`, then _The Map_ or `M`); `Esc` puts it away. Green dots are villages, grey keeps, blue libraries, tan huts, **red gates**
  (a ring means it is open and spilling), gold is **the Tower**, and the orange roof is **home**.
- **Home** — the run starts on your own doorstep. Nothing camps within sight of it and sleeping
  there always patches the party up. `U` buys the next **bed** up, and everyone who sleeps on it
  carries that comfort around as permanent extra HP — a straw pallet gives nothing, a canopied bed
  gives +22.
- **Danger is a property of place.** Near an open gate the country is thick with bands on guard,
  out of what came through it; near a hearth it goes quiet.
- **Sites** — step on a village, keep or hut to rest; a library to read; an open gate to fight it;
  the Tower to climb the next floor. In a settlement, `H` hires whoever is drinking there and `B`
  buys the gear on the shelf. Where one of your people is being held, `R` ransoms them and `F`
  takes them back by force.
- **Once inside a gate there is no walking out.** Win a floor and every step is the next one, until
  the gate is beaten or you are.
- **Gates never reopen once shut** — but one left standing open too long **breaks**, and what was
  behind it comes out. Danger near a broken gate jumps and its monsters come levelled up.
- **Towns can be saved or taken.** A gate left open long enough puts the nearest settlement under
  siege; walk in while it is happening and `V` fights the besiegers off for gold and goodwill.
  Leave it too long and the town falls on its own. `K` raids a town instead — you fight its people,
  empty its strongbox, and it never trades again.
- **Word spreads from where it happened.** Every notable act is written down at the place you did
  it and travels outward about a tile every fourteen steps. A village on the far side of the map
  has not heard yet; one down the road has heard of nothing else. What they have heard sets what
  they call you, and moves their prices up to 30% either way.
- **Chests, packs and stash.** Towns you walk around inside have chests worth finding, and open
  country sometimes has something buried in it. Gold goes in the purse; gear goes to whoever it
  actually improves; anything else worth keeping goes into the marching packs (`GameState.stores`),
  and only true junk is sold on the spot. Camp provides a strongbox stash (`GameState.camp_stash`)
  for long-term storage.
- **The ground is the game.** You play in the planar view, close up. Walk off the edge of the
  ground and the party steps to the next tile of the continent, with everything a step brings — a
  band that was watching, a scene on the road, a rest. A place's doings (`H`, `B`, `J`, …) are
  offered at the bottom of the ground's screen. The continent itself is a map, opened from the
  journal, black where the company has never been ([D61](docs/06-decisions.md)).
- **Eighteen lands.** Snow, taiga, desert, savanna, badlands, jungle, grassland, forest, blossom
  vales, barrow downs, the mistlands, crystal fields, fungal groves, bog, swamp, slime fens, and
  ash and blight where the gates have changed the land. Every tile of open country is its own
  ground. Bands stand guard on it with the ground they see painted red; walk into the red and the
  fight is fought right there ([D66](docs/06-decisions.md)).
- **Four seasonal clovers.** Footsteps turn the seasons every 120 steps: Lesser Green (Spring),
  Green (Summer), Brown (Autumn), and Ice (Winter), reflected in world HUD lore, dialogue, and areas.
- **The Tower is a hundred floors** in chapters of five ([D48](docs/06-decisions.md)): every floor
  pays gold, every fifth hands over a book and every tenth a generated skill tree. When a chapter
  ends the stair above is sealed until you shut a gate or save a town.
- **Fights are real time with pause** ([D36](docs/06-decisions.md), chosen in D58, D63 and D64).
  Every fight opens paused: `Space` pauses and unpauses, and orders can be given while paused.
  Left-click picks a fighter (drag a box for several, `Tab` for everyone); right-click moves,
  attacks, or goes to help a fallen friend; `Q W E R` ready a skill; `A` switches a fighter's
  skills between automatic and by hand; `H` holds them in place; `T` changes speed; `N` opens the
  journal. Everyone swings on their own tempo, set by their speed. Swings, hits, blocks, spells,
  heals and the end of a fight are heard, under the menu's Sounds slider ([D76](docs/06-decisions.md)).
  See [docs/18](docs/18-combat-direction.md).
- **Facing matters** — the wedge on a token shows where it looks. Side hits deal 1.1×, back hits
  1.2×.
- **Falling is usually fatal.** A downed character has twelve seconds for a friend to reach them.
  If nobody does, they roll their graces — a charm carried, an ally still standing, a book they
  read, the ground they fell on — and die if none of them land. Raiders may take them alive
  instead. See [docs/02-design.md](docs/02-design.md).
- **The run follows you, not the party.** Companions can all die and the story goes on; when your
  own character falls, it stops. Hire replacements in towns — everyone is looking out for
  themselves, and they all have a price. In **Classic** the fall stops on a choice: **Reload** the
  last save (it tells you what that goes back to), or **Ascend** and choose the next lead. In
  **Iron Man** the lead ascends at once and the save goes with them.
- **Four seats, then five, then six.** The company starts four strong. Clearing Tower chapter 1
  (floor 5) opens a fifth seat and chapter 2 (floor 10) a sixth: a banner, a word at the fire, and
  anyone who came back from a job to a full company takes it first. Then hire in a village or keep.
  The party screen's footer shows how many seats are filled and which floor opens the next. The
  floors are `world_rules.party` (agenda item 35, **Inferred**).
- **Experience comes from the first of each kind.** A kind of enemy teaches whoever kills it
  first, once; the second teaches nothing but practice. Help with five kills of a kind and you learn
  from it too, and a boss teaches everyone who was there. So the way to grow is to go and meet
  something new ([D37](docs/06-decisions.md)).
- **Send companions away.** Take an errand, then on the party screen's Practice page send someone
  off to do it. They walk it while you walk, and come back — or meet something on the road alone
  ([D38](docs/06-decisions.md)).
- **A level gained** flickers gold on whoever gained it in a fight, and a line at the top right
  says so and what is now owed ([D77](docs/06-decisions.md)).
- **Level 2 is a choice.** A lead may keep their own class or take another ([D64](docs/06-decisions.md));
  a companion with none picks one. The line says so; press `P` and pick from the class cards.
- **The party screen** (`P`) is where the run is managed: pick a class from its card, take a power
  by pressing the glowing stone on its trail, teach a book to someone
  who lacks it, take the **Training Yoke** on or off (−25% attack for +50% XP), and see what each
  character has read and what is close to fading. It also shows the **Codex** — how much of the
  world's power grammar has been catalogued.
- **Losing everyone ends the run** and returns you to the title.
- **Training.** Title → Training → **Fight this** throws any unit at the party in a sandbox fight:
  the party walks off whole and nothing is written back.

## Project layout

```
data/                     Game content as plain JSON — edit without opening the editor
  terrain.json            Move cost, height and colour per tile type
  units.json              Unit templates (party + enemies)
  abilities.json          Range, splash, power, targeting, elements
  classes.json            Main class growth curves, granted moves, tree themes
  equipment.json          Weapons, charms, draughts: stats, suits, art offsets
  heroes.json             The 12 founders: backgrounds, alignments, origins, grudges
  factions.json           Cohort groupings and faction allegiance
  threads.json            Skein story thread definitions, stages, and deadlines
  coliseum.json           Gladiator cards, waves, bouts, wagers, free-for-all cohorts
  skirmish.json           The fight's rules, passives, enemy roles, the training pouch, scenery
  banter.json             Exchanges, occasions, moods, tokens, campfire reflections
  tips.json               First-time tips: when each fires and what it says
  how_to_play.json        The How to Play page, section by section
  areas/*.json            Hand-built area maps: legend, rows, spots, people, props, wards
  maps/*.json             Battle maps as ASCII tile rows + spawns
  dialogue/*.json         Conversation scripts

art/
  units/<character>/<state>/  Directional unit art (north/south/east/west + diagonals)
  items/<item>/           Directional item art, same rotation names
  map_kit/                Unused PixelLab tileset project, .gdignore'd until wired up

src/
  main.tscn / game.gd     Root: swaps the active scene, hosts the dialogue + menu overlays
  autoload/
    event_bus.gd          Global signal hub — how systems talk without coupling
    database.gd           Loads and caches everything in data/
    game_state.gd         Party, party HP, stores, stash, gold, progress flags, save/load
    music.gd              Scene-specific music player and bus management
    sfx.gd                UI and interaction sound effects
    pace.gd               Game speed and auto-play coordination
  chronicle/              The world model — pure logic, no scene nodes, serialisable
    character.gd          The persistent person: level, class, doctrine, permadeath, grudge
    progression.gd        XP curve, level-ups, class choice, tree unlocks
    ability_grammar.gd    Hidden grammar that generates skill trees
    doctrine.gd           Read / teach / forget, and what knowledge grants
    skein.gd              Long-running story threads and deadlines
    nemesis.gd            Persistent combat survivors who rally and remember
    annals.gd             Telemetry chronicle of deeds and milestones
    season.gd             Step-clock seasonal transitions
    news.gd               Living continental rumor dispatches
    ferry.gd              Coastal cutter routes between ports
    ward.gd               Obstacle and gate clearance via keys or abilities
    loot.gd · gear.gd     Pack management, suit fit, draughts, stores
    site.gd · world.gd · world_gen.gd   Places, the step clock, world generation
  skirmish/
    skirmish.tscn/.gd     The fight: the clock, orders, and writing the fight back onto the world
    fighter.gd            One combatant's real-time state: orders, cooldowns, energy, near death
    skirmish_brain.gd     Who to swing at and which ready skill to use; returns a plan
    skirmish_rules.gd     Every timing in seconds: steps, swings, cooldowns, casts
    skirmish_passives.gd  Passives and enemy roles, read from data/skirmish.json
    skirmish_hud.gd       The clock, the party cards, the log, the touch buttons
  battle/                 What the fight is built on
    grid/
      battle_grid.gd      Terrain, coordinate conversion, tile rendering
      pathfinder.gd       Dijkstra flood-fill honouring move cost + jump
      move_field.gd       Reachable cells and the path back
      grid_overlay.gd     Range / path / cursor highlights
    units/unit.gd         Combatant stats, facing, damage, drawing
    abilities/ability_resolver.gd  Targeting rules, flanking, damage maths
  world/                  Walk mode: the map, the step clock, every site interaction
  area/                   Places walked around close up — towns, halls, the camp fire
  dialogue/               Conversation overlay
  ui/title_screen.tscn    Boot menu: continue / new game / quit
  ui/system_menu.tscn     In-game menu (save / load in Classic only), opened via EventBus
  ui/credits_screen.tscn  Credits off the title (also a page of the system menu), from data/credits.json
  ui/tip_card.gd          First-time tips, once per player, off EventBus.tip_moment
  ui/how_to_play.gd       The How to Play page, built from data/how_to_play.json
```

Two rules keep it extensible: **content lives in `data/`, never in code**, and **systems talk
through `EventBus`** rather than holding references to each other.

## Adding content

- **A battle map** — drop a JSON file in `data/maps/`. Tile rows use the `legend` map, so
  `"^": "hill"` means every `^` is a hill. Add `player_spawns` and `enemies`. These are set
  pieces only — wild encounters, delves and Tower floors generate their fields from the world
  terrain you were standing on.
- **A unit** — add a template to `data/units.json` and reference its key from a map's `enemies`
  list or `GameState.party`.
- **An ability** — add it to `data/abilities.json` and list its key on a unit. `splash` gives it
  an area, `min_range` makes it unusable up close, `heal: true` flips it to restoration.
- **A weapon** — add it to `data/equipment.json` with its stat bonus, `sprite_dir` and a pixel
  `offsets` entry per facing, then put `"weapon": "<key>"` on a unit template. The art is drawn
  over the unit (behind it when facing away) and rotates with facing; tune `offsets` and `scale`
  until it sits in the hand.
- **Sprite art** — drop PixelLab-style rotations in `art/units/<character>/<state>/` as
  `north|south|east|west.png`, then add `"sprite_dir": "res://art/units/<character>/<state>"` to a
  unit template. Units draw the rotation matching their facing; templates without one keep the
  placeholder token.

## Smoke tests

Headless suites that drive the real scenes and systems — a fast way to catch breakage without
clicking through the game. `.\ek.ps1 test` runs them all, one line each (`./ek.sh test` on Linux
and macOS). **Every pull request runs them in CI**, with a two-minute seeded soak alongside
(`.github/workflows/smoke.yml`, about three minutes in all). The two big ones take
`-- --check=name` to run a single check (see [docs/10](docs/10-manual-tests.md#automated-tests)):

```powershell
godot --headless --path . res://tests/skirmish_smoke_test.tscn
godot --headless --path . res://tests/experience_smoke_test.tscn
godot --headless --path . res://tests/dispatch_smoke_test.tscn
godot --headless --path . res://tests/names_smoke_test.tscn
godot --headless --path . res://tests/world_smoke_test.tscn
godot --headless --path . res://tests/walk_smoke_test.tscn
godot --headless --path . res://tests/seams_smoke_test.tscn
godot --headless --path . res://tests/art_smoke_test.tscn
godot --headless --path . res://tools/coverage.tscn
godot --headless --path . res://tools/soak.tscn -- --seconds=300   # the game plays itself; see docs/10
```

## Coding agents

[`AGENTS.md`](AGENTS.md) is the short brief for any coding agent working here (Claude Code reads it
through `CLAUDE.md`).

## Roadmap

Tracked properly in [docs/05-roadmap.md](docs/05-roadmap.md). In short: M0–M10 and M12 are
shipped — the tactics core, characters, the generated power system, the world and walk mode, gates,
the Tower, the Library, the living world, the size test and the new way of getting stronger. Every
fight is the real-time fight (M11), and the early game's units play their moves in it. The fall,
the Tower's chapters, the sixteen worlds and the one view (M13–M15, M18) are built in part. Next,
since 2026-10-13: the sixteen as the playable leads, each in their own class, with the original
twelve as story NPCs. The assets to generate, in order, are in [docs/19-asset-list.md](docs/19-asset-list.md).
