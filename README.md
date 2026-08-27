# Earth Kings

A 2D top-down, grid-based tactical RPG built in **Godot 4 (GDScript)** — turn-based battles on
square tile maps with movement ranges and per-tile terrain cost, plus an overworld for travel and
NPC dialogue between fights.

## Running it

1. Install [Godot 4.4+](https://godotengine.org/download) (standard build, not .NET).
2. Open Godot → **Import** → select `project.godot` in this folder.
3. Press **F5**.

No assets to download — everything renders from primitives so the systems can be built and
tested before any art exists.

## Playing the vertical slice

- **Overworld** — click a connected location to travel. Red nodes have an unfought battle.
- **Battle** — on your unit's turn: **Move** (blue tiles), an ability (red tiles), then **Wait**
  to end the turn. Right-click or `Esc` cancels a selection. Hover any tile to inspect it.
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

src/
  main.tscn / game.gd     Root: swaps the active scene, hosts the dialogue overlay
  autoload/
    event_bus.gd          Global signal hub — how systems talk without coupling
    database.gd           Loads and caches everything in data/
    game_state.gd         Party, gold, progress flags, save/load
  battle/
    battle.tscn/.gd       Phase machine, input routing, turn loop
    turn_manager.gd       Charge-time turn order + lookahead
    grid/
      battle_grid.gd      Terrain, coordinate conversion, tile rendering
      pathfinder.gd       Dijkstra flood-fill honouring move cost + jump
      move_field.gd       Reachable cells and the path back
      grid_overlay.gd     Range / path / cursor highlights
    units/unit.gd         Combatant stats, damage, walk animation
    abilities/ability_resolver.gd  Targeting rules and damage maths
    ai/enemy_brain.gd     Plans a move + attack; returns it for the controller to execute
  overworld/              Travel map
  dialogue/               Conversation overlay
  ui/battle_hud.gd        Turn order, command menu, inspector, combat log
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

## Roadmap

- [ ] Facing and directional damage bonuses (back/side attacks)
- [ ] Height advantage in the damage formula
- [ ] Jobs, levels, and ability unlocks; persistent party HP between battles
- [ ] Counter-attacks and reaction abilities
- [ ] Sprites + animation to replace the placeholder tokens
- [ ] Win conditions beyond "defeat all" (survive N turns, escort, seize a tile)
- [ ] Save/load wired to a menu (the `GameState` functions already exist)
- [ ] Unit tests for `Pathfinder` and `AbilityResolver` (via GUT)
