# Earth Kings

A 2D top-down, grid-based tactical RPG built in **Godot 4 (GDScript)** — turn-based battles on
square tile maps with movement ranges and per-tile terrain cost, plus an overworld for travel and
NPC dialogue between fights.

## Running it

1. Install [Godot 4.4+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select `project.godot` in this folder.
3. Press **F5**.

Nothing to download — terrain, UI and any unit without art render from primitives, so systems can
be built and tested before the art exists. Units with a `sprite_dir` draw their art instead.

## Playing the vertical slice

- **Title** — _Continue_ loads `user://earth-kings.save.json`, _New Game_ starts a fresh run.
- **Overworld** — click a connected location to travel. Red nodes have an unfought battle.
  `Esc` opens the menu (save, load, return to title). Locations flagged `"rest": true` in
  `overworld.json` patch the party back up to full when you arrive.
- **Battle** — on your unit's turn: **Move** (blue tiles), an ability (red tiles), then **Wait**
  to end the turn. Right-click or `Esc` cancels a selection. Hover any tile to inspect it.
- **Facing matters** — the wedge on a token shows where it looks. Hitting a unit from the side
  deals 1.2x damage, from behind 1.5x. Units turn as they move and turn to face what they attack,
  so the tile you finish your move on decides how exposed you are.
- **Wounds persist** — HP carries between battles. Anyone who falls is dragged out at a quarter
  of their max HP, so a costly win hurts but can't end the run. Rest to recover.
- Turn order is **charge time**: each tick every unit gains CT equal to its speed, and the first
  to 100 acts. Fast units act _more often_, not just sooner.

## Project layout

```
data/                     Game content as plain JSON — edit without opening the editor
  terrain.json            Move cost, height and colour per tile type
  units.json              Unit templates (party + enemies)
  abilities.json          Range, splash, power, targeting
  overworld.json          Travel nodes, connections, what each triggers
  maps/*.json             Battle maps as ASCII tile rows + spawns
  dialogue/*.json         Conversation scripts

art/
  units/<character>/<state>/  Directional unit art (north/south/east/west + diagonals)
  map_kit/                Unused PixelLab tileset project, .gdignore'd until wired up

src/
  main.tscn / game.gd     Root: swaps the active scene, hosts the dialogue + menu overlays
  autoload/
    event_bus.gd          Global signal hub — how systems talk without coupling
    database.gd           Loads and caches everything in data/
    game_state.gd         Party, party HP, gold, progress flags, save/load
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
  overworld/              Travel map
  dialogue/               Conversation overlay
  ui/battle_hud.gd        Turn order, command menu, inspector, combat log
  ui/title_screen.tscn    Boot menu: continue / new game / quit
  ui/system_menu.tscn     In-game save / load overlay, opened via EventBus
```

Two rules keep it extensible: **content lives in `data/`, never in code**, and **systems talk
through `EventBus`** rather than holding references to each other.

## Adding content

- **A battle map** — drop a JSON file in `data/maps/`. Tile rows use the `legend` map, so
  `"^": "hill"` means every `^` is a hill. Add `player_spawns` and `enemies`, then point an
  overworld location's `battle` field at the filename.
- **A unit** — add a template to `data/units.json` and reference its key from a map's `enemies`
  list or `GameState.party`.
- **An ability** — add it to `data/abilities.json` and list its key on a unit. `splash` gives it
  an area, `min_range` makes it unusable up close, `heal: true` flips it to restoration.
- **Sprite art** — drop PixelLab-style rotations in `art/units/<character>/<state>/` as
  `north|south|east|west.png`, then add `"sprite_dir": "res://art/units/<character>/<state>"` to a
  unit template. Units draw the rotation matching their facing; templates without one keep the
  placeholder token.

## Smoke test

Boots a battle headlessly, auto-passes every player turn and lets the AI play it out — a fast way
to catch runtime breakage without clicking through the game:

```powershell
godot --headless --path . res://tests/battle_smoke_test.tscn
```

## Roadmap

- [x] Facing and directional damage bonuses (back/side attacks)
- [ ] Height advantage in the damage formula
- [ ] Jobs, levels, and ability unlocks
- [x] Persistent party HP between battles
- [ ] Counter-attacks and reaction abilities
- [ ] Sprites + animation to replace the placeholder tokens
- [ ] Win conditions beyond "defeat all" (survive N turns, escort, seize a tile)
- [x] Save/load wired to a menu
- [ ] Unit tests for `Pathfinder` and `AbilityResolver` (via GUT)
