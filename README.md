# Earth Kings

A tactical RPG in a persistent, hostile world, built in **Godot 4 (GDScript)**. You walk a
generated map tile by tile, fight what finds you on a Final Fantasy Tactics–style grid, and grow
characters who can die for good. Power is scarce, knowledge is carried rather than inherited, and
the world advances every step you take.

**Start here: [docs/00-index.md](docs/00-index.md)** — vision, design, architecture, data formats,
roadmap and the decision log.

## Running it

1. Install [Godot 4.4+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select `project.godot` in this folder.
3. Press **F5**.

Nothing to download —terrain, UI and any unit without art render from primitives, so systems can
be built and tested before the art exists. Units with a `sprite_dir` draw their art instead.

## Playing the vertical slice

- **Title** — _Continue_ loads `user://earth-kings.save.json`, _New Game_ generates a fresh world.
- **Walking** — WASD (or the arrow keys) move you one tile at a time; hold to keep going. Every step advances
  the world clock. The top bar shows where you are and your current **danger %**.
  `Esc` opens the menu (save, load, music, return to title).
- **Letting it play itself** — `Q` hands the run to the game and `E` cycles the speed, on the road,
  inside a town and in a fight alike. The party walks to whatever is worth reaching, fights it,
  and answers its own conversations. Both survive a scene change, so a soak keeps going.
- **The map** — green dots are villages, grey keeps, blue libraries, tan huts, **red gates**
  (a ring means it is open and spilling), gold is **the Tower**, and the orange roof is **home**.
- **Home** — the run starts on your own doorstep. Nothing camps within sight of it and sleeping
  there always patches the party up. `U` buys the next **bed** up, and everyone who sleeps on it
  carries that comfort around as permanent extra HP — a straw pallet gives nothing, a canopied bed
  gives +22.
- **Danger is a property of place.** Near an open gate the wild is thick with what came out of it;
  near a hearth it goes quiet. Roughly 37% per step in a gate's mouth against 1% at home.
- **Sites** — step on a village, keep or hut to rest; a library to read; an open gate to fight it;
  the Tower to climb the next floor. In a settlement, `H` hires whoever is drinking there and `B`
  buys the gear on the shelf. Where one of your people is being held, `R` ransoms them and `F`
  takes them back by force.
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
- **Chests and caches.** Towns you walk around inside have chests worth finding, and open country
  sometimes has something buried in it. Gold goes in the purse; gear goes to whoever it actually
  improves, and anything nobody wants is sold on the spot.
- **The Tower is ten floors**, each paying gold, a book every third and a generated skill tree
  every fourth.
- **Battle** — on your unit's turn: **Move** (blue tiles), an ability (red tiles), then **Wait**
  to end the turn. `Esc` cancels a selection. Hover any tile to inspect it.
- **Facing matters** — the wedge on a token shows where it looks. Side hits deal 1.2×, back hits
  1.5×. Units turn as they move, so the tile you finish on decides how exposed you are.
- **Turn order is charge time** — each tick every unit gains CT equal to its speed and acts at 100.
  Fast units act _more often_, not just sooner.
- **Falling is usually fatal.** A downed character rolls their graces — a charm carried, an ally
  still standing, a book they read, the ground they fell on — and dies if none of them land.
  Raiders may take them alive instead. See [docs/02-design.md](docs/02-design.md).
- **The run follows you, not the party.** Companions can all die and the story goes on; when your
  own character falls, it stops. Hire replacements in towns — everyone is looking out for
  themselves, and they all have a price.
- **Level 2 is a choice.** When a party member is ready, the hint bar says so; press `P`.
- **The party screen** (`P`) is where the run is managed: pick a class, teach a book to someone
  who lacks it, take the **Training Yoke** on or off (−25% attack for +50% XP), and see what each
  character has read and what is close to fading. It also shows the **Codex** — how much of the
  world's power grammar has been catalogued.
- **Losing everyone ends the run** and returns you to the title.

## Project layout

```
data/                     Game content as plain JSON — edit without opening the editor
  terrain.json            Move cost, height and colour per tile type
  units.json              Unit templates (party + enemies)
  abilities.json          Range, splash, power, targeting
  equipment.json          Weapons: stat bonus, art folder, per-facing offsets
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
    game_state.gd         Party, party HP, gold, progress flags, save/load
  chronicle/              The world model — pure logic, no scene nodes, serialisable
    character.gd          The persistent person: level, class, doctrine, permadeath
    progression.gd        XP curve, level-ups, class choice, tree unlocks
    ability_grammar.gd    Hidden grammar that generates skill trees
    doctrine.gd           Read / teach / forget, and what knowledge grants
    site.gd · world.gd · world_gen.gd   Places, the step clock, world generation
  battle/
    battle.tscn/.gd       Phase machine, input routing, turn loop
    turn_manager.gd       Charge-time turn order + lookahead
    grid/
      battle_grid.gd      Terrain, coordinate conversion, tile rendering
      pathfinder.gd       Dijkstra flood-fill honouring move cost + jump
      move_field.gd       Reachable cells and the path back
      grid_overlay.gd     Range / path / cursor highlights
    units/unit.gd         Combatant stats, facing, damage, walk animation
    abilities/ability_resolver.gd  Targeting rules, flanking, damage maths
    ai/enemy_brain.gd     Plans a move + attack; returns it for the controller to execute
  world/                  Walk mode: the map, the step clock, every site interaction
  area/                   Places walked around close up — towns, halls, the camp fire
  dialogue/               Conversation overlay
  ui/battle_hud.gd        Turn order, command menu, inspector, combat log
  ui/title_screen.tscn    Boot menu: continue / new game / quit
  ui/system_menu.tscn     In-game save / load overlay, opened via EventBus
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

## Smoke test

Boots a battle headlessly, auto-passes every player turn and lets the AI play it out — a fast way
to catch runtime breakage without clicking through the game:

```powershell
godot --headless --path . res://tests/battle_smoke_test.tscn
godot --headless --path . res://tests/world_smoke_test.tscn
godot --headless --path . res://tests/walk_smoke_test.tscn
godot --headless --path . res://tools/coverage.tscn
```

## Roadmap

Tracked properly in [docs/05-roadmap.md](docs/05-roadmap.md). In short: the tactics core is
shipped; characters, the generated power system, the world and walk mode, gates, the Tower and the
Library are in flight.
