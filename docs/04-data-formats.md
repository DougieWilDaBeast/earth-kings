# 04 — Data formats

Everything in `data/` is plain JSON so content can be added without opening the editor and diffs
stay readable. All of it is read-only at runtime.

## `terrain.json` — tile types

```json
"hill": { "name": "Hill", "move_cost": 2, "height": 1, "walkable": true, "color": "#6b8f4e" }
```

Used by both the battle grid and the world map. `move_cost` is per tile entered; `height`
differences are gated by a unit's `jump`.

## `units.json` — unit templates

The base stat block a `Character` is built from, and what a monster is.

```json
"bram": {
  "display_name": "Bram",
  "job": "Sworn Blade",
  "max_hp": 52, "attack": 15, "defense": 7,
  "move": 4, "jump": 2, "speed": 10,
  "abilities": ["strike", "cleave"],
  "classes": ["sworn_blade", "magic_swordsman"],
  "color": "#4c8bf5",
  "sprite_dir": "res://art/units/golden_knight/idle",
  "weapon": "bone_sword"
}
```

- `classes` — options offered when this character hits level 2. Omit to allow any class.
- `sprite_dir` — a folder holding `north.png` / `south.png` / `east.png` / `west.png`. Omit to
  render a coloured token instead.

## `classes.json` — main classes

```json
"sworn_blade": {
  "display_name": "Sworn Blade",
  "growth": { "max_hp": 6, "attack": 2.0, "defense": 1.4, "speed": 0.3 },
  "themes": ["edge", "iron", "vigil"],
  "grants": ["cleave"]
}
```

- `growth` — added per level above 1, then rounded. Floats are fine.
- `themes` — which ability-grammar themes this class's generated trees are drawn from.
- `grants` — abilities the class hands over on the spot.
- `yoke: true` — flags a class as one that can hold the Training Yoke stance.

## `abilities.json` — authored abilities

```json
"arc_shot": {
  "display_name": "Arc Shot",
  "description": "A lobbed arrow that cannot hit adjacent foes.",
  "target": "enemy", "min_range": 2, "range": 4, "splash": 0, "power": 0.9
}
```

- `target` — `enemy` · `ally` · `any` · `self`
- `power` — multiplier on attack. With `"heal": true` it is instead flat HP restored.
- `splash` — Manhattan radius around the target cell. `0` is single-target.

Generated abilities have the same shape and are registered at runtime by `AbilityGrammar`; they
are stored inside the save's tree definitions, not in this file.

## `doctrine.json` — the Library's shelves

```json
"the_vigil": {
  "title": "A Vigil Kept in Winter",
  "text": "Those who learn to stand awake learn also to stand wounded.",
  "bonus": { "max_hp": 8 },
  "grace": 0.1
}
```

- `bonus` keys may be any of `max_hp`, `attack`, `defense`, `speed`, `move`, `jump`.
- `grace` (optional) — the chance this book alone gives a fallen reader of surviving. Summed
  across everything they know and capped at 30%.

## `equipment.json` — weapons

```json
"bone_sword": { "display_name": "Bone Sword", "attack": 3, "sprite_dir": "res://art/items/bone_sword" }
```

Charms live here too. A charm has no stats — it has a `grace`, and is **spent** the moment it
saves someone:

```json
"grave_token": {
  "display_name": "Grave Token",
  "charm": true,
  "grace": 0.5,
  "text": "Cold to the touch. Spent once, and never twice."
}
```

## `fate.json` — the price of dying

Every number behind [D11](06-decisions.md), tunable without touching code.

```json
{
  "base_luck": 0.07,
  "ally_rescue_per_ally": 0.12,
  "ally_rescue_cap": 0.36,
  "haven_range": 6,
  "haven_grace": 0.15,
  "capture_by": { "raider": 0.4, "soldier": 0.3, "beast": 0.0, "default": 0.15 },
  "escape_recovery": 0.25,
  "capture_recovery": 0.1
}
```

- `capture_by` is keyed on whatever the encounter reports as its `enemy_kind`. A missing key
  falls back to `default`. Set a kind to `0.0` and it takes no prisoners.
- `escape_recovery` / `capture_recovery` are the fraction of max HP a survivor comes back with.

## `maps/*.json` — hand-authored battlefields

For set pieces. Wild encounters and delves generate their maps instead.

```json
{
  "id": "verdant_pass",
  "name": "Verdant Pass",
  "legend": { ".": "grass", "^": "hill", "#": "wall" },
  "tiles": ["####.....^^###", "##....==..^^##"],
  "player_spawns": [
    [6, 9],
    [5, 9]
  ],
  "enemies": [{ "unit": "brigand", "cell": [6, 1] }]
}
```

All rows must be the same length, and every spawn must sit on walkable terrain.

## `dialogue/*.json`

```json
{ "lines": [{ "speaker": "Sera", "text": "Movement in the brush." }] }
```

## Save file — `user://earth-kings.save.json`

Written by `GameState`. Contains the serialised `World` (seed, tiles, sites, step count, player
cell, generated trees, codex) and the `Roster` of Characters. Generated abilities are restored
from the saved tree definitions on load, so a save never loses a power it discovered.

## Conventions

- Ids are `snake_case` and are the key, never a field inside the value.
- Colours are hex strings.
- Cells are `[x, y]` pairs.
- Omit a key rather than setting it to `null` — typed loaders will reject nulls.
