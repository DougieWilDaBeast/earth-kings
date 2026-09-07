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
- `flash_step` — blink range in tiles. Omit or leave at 0 for units that cannot flash step.
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
- `flash_step` — blink range the class grants; the higher of this and the template's wins.
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
- `bonus: true` — a minor ability that costs the bonus action instead of the main action.

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

- `bonus` keys may be any of `max_hp`, `attack`, `defense`, `speed`, `move`, `jump`, `flash_step`.
- `grace` (optional) — the chance this book alone gives a fallen reader of surviving. Summed
  across everything they know and capped at 30%.

## `equipment.json` — weapons, charms, and draughts

```json
"bone_sword": {
  "display_name": "Bone Sword",
  "attack": 3,
  "suits": ["sworn_blade", "magic_swordsman"],
  "sprite_dir": "res://art/items/bone_sword"
}
```

- `suits` — calling templates best suited to this weapon. Units in "wrong hands" suffer a misfit
  penalty on the bonus stats.
- `charm: true` — a relic that grants a `grace` roll when its bearer falls, spent on trigger.
- `kind: "draught"` — consumable items stored in `GameState.stores` and drunk on the party screen
  or in combat for a bonus action (`"heal": 25`).

## `heroes.json` — playable company founders

The 12 founders selectable on the New Game screen:

```json
"bram": {
  "display_name": "Bram",
  "job": "Sworn Blade",
  "rating": "Steady",
  "difficulty": 1,
  "background": "apprentice_smith",
  "alignment": "lawful_good",
  "origin": "Born in the soot of Oakhaven...",
  "grudge": { "target": "brigand", "label": "Raiders & Marauders" },
  "starter_party": ["sera", "toln"],
  "unit": "bram"
}
```

## `threads.json` — story threads (`Skein`)

Long-running narrative arcs evaluated on the step clock and arrivals:

```json
"the_gatewarden": {
  "title": "The Gatewarden",
  "ignite": { "deed": "gate_shut", "count": 2 },
  "stages": [
    {
      "id": "word_gets_around",
      "when": { "steps_since_stage": 60 },
      "then": [
        { "rumour": "somebody has been asking which gates you shut", "at": "last_deed" },
        { "tag": "watched" }
      ]
    },
    {
      "id": "the_meeting",
      "when": { "arrive_kind": "gate" },
      "deadline": 400,
      "goto": "he_stopped_waiting",
      "then": [ { "hint": "Somebody is already standing in the mouth of it." } ],
      "instead": [ { "hint": "The camp near the gate is cold and empty." } ]
    }
  ]
}
```

## `areas/*.json` — hand-built top-down areas

Each site interior, village, keep, gate dungeon, and wilderness area:

```json
{
  "id": "village_fen",
  "name": "Fen-on-the-Hill",
  "tileset": "village",
  "legend": { ".": "grass", "~": "water", "#": "crag", "=": "dirt" },
  "tiles": ["#######....######", "##....======...##"],
  "spawn": [8, 12],
  "exits": [
    [8, 14],
    [8, 0]
  ],
  "props": [{ "art": "barrel", "cell": [6, 10] }],
  "chests": [{ "cell": [12, 4], "gold": 45, "item": "bone_sword" }],
  "wards": [{ "cell": [10, 8], "ability": "cleave", "key": "iron_key" }],
  "spots": [{ "cell": [5, 5], "line": "A mossy sundial." }],
  "people": [
    {
      "unit": "villager",
      "cell": [7, 7],
      "wander": 3,
      "chatter": ["Quiet day."]
    }
  ]
}
```

## `coliseum.json` — arena cards and waves

Gladiator bouts, purse multipliers, and multi-team engagements:

```json
"the_grand_melee": {
  "title": "The Grand Melee",
  "brawl": true,
  "teams": ["PLAYER", "ENEMY", "ENEMY_B", "ENEMY_C"],
  "waves": [
    {
      "enemies": [
        { "unit": "sworn_blade", "team": "ENEMY" },
        { "unit": "fox_knight", "team": "ENEMY_B" },
        { "unit": "tide_lion", "team": "ENEMY_C" }
      ],
      "purse": 150
    }
  ]
}
```

## `banter.json` — party interactions and reflections

Field talk, campfire chats, and historical reflections:

```json
{
  "exchanges": [
    {
      "id": "rest_bram_sera_01",
      "occasion": "rest",
      "mood": "warm",
      "who": ["bram", "sera"],
      "lines": [
        { "speaker": "bram", "text": "Get some sleep, Sera." },
        { "speaker": "sera", "text": "Keep the fire up and I might." }
      ]
    }
  ],
  "reflections": [
    {
      "id": "reflect_deeds",
      "about": "deeds",
      "at_least": 3,
      "text": "Three deeds in {place}, and the realm still burns."
    }
  ]
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
  "capture_by": {
    "raider": 0.4,
    "soldier": 0.3,
    "beast": 0.0,
    "default": 0.15
  },
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

A conversation is either a flat script:

```json
{ "lines": [{ "speaker": "Sera", "text": "Movement in the brush." }] }
```

…or a branching one, with replies the player picks:

```json
{
  "start": "greeting",
  "nodes": {
    "greeting": {
      "speaker": "Ganel",
      "text": "I expected an army, or at least a bribe.",
      "options": [
        { "text": "Stand down.", "goto": "defiance" },
        {
          "text": "Your men haven't eaten in days.",
          "check": {
            "skill": "wits",
            "dc": 12,
            "success": "starving",
            "failure": "laughed_off"
          }
        },
        {
          "text": "A hundred gold and we never met.",
          "requires_gold": 100,
          "gold": -100,
          "set_flag": "chief_bribed",
          "goto": "bribe"
        }
      ]
    },
    "defiance": {
      "speaker": "Ganel",
      "text": "Then take the high ground.",
      "next": "end"
    }
  }
}
```

- A node with no `options` waits for a click and moves to `next`; `"end"` closes the box.
- `skill` is one of `might`, `guard`, `wits`, `renown`. The best-suited party member rolls
  `d20 + skill / 2` against `dc`; a natural 20 always lands and a natural 1 never does. The
  check may carry `success_effects` / `failure_effects`.
- Nodes and options share the same effect keys: `set_flag`, `clear_flag` (a string or a list of
  them) and `gold` (a signed amount).
- An option is hidden unless the party satisfies its `requires` / `requires_not` flags and its
  `requires_gold`.

## Save file — `user://earth-kings.save.json`

Written by `GameState`. Contains the serialised `World` (seed, tiles, sites, step count, player
cell, generated trees, codex) and the `Roster` of Characters. Generated abilities are restored
from the saved tree definitions on load, so a save never loses a power it discovered.

## Conventions

- Ids are `snake_case` and are the key, never a field inside the value.
- Colours are hex strings.
- Cells are `[x, y]` pairs.
- Omit a key rather than setting it to `null` — typed loaders will reject nulls.
