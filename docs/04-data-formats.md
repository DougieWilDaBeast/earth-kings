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
  "target": "enemy", "min_range": 2, "range": 4, "splash": 0, "power": 0.9,
  "cooldown": 6.5, "cast": 0.4
}
```

- `target` — `enemy` · `ally` · `any` · `self`
- `power` — multiplier on attack. With `"heal": true` it is instead flat HP restored.
- `splash` — Manhattan radius around the target cell. `0` is single-target.
- `bonus: true` — a minor ability that costs the bonus action instead of the main action.
- `cooldown` — seconds before it can be used again, in the real-time skirmish (M11 prototype,
  [D36](06-decisions.md)). Ignored by the turn-based battle.
- `cast` — seconds of wind-up before it lands, in the skirmish. `0` lands at once.

Both timings are optional. An ability without them — every generated one — gets them from the
formulas in `src/skirmish/skirmish_rules.gd`, which are also where the authored values came from.

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

## `heroes.json` — the leads a run can be started as

A side-car on `units.json`: the key **is** the unit template id, and the name and stats come from
there. This file adds only what a lead needs on top of a unit.

```json
"bram": {
  "title": "The Sworn Blade",
  "difficulty": 1,
  "temper": "",
  "background": "apprentice_smith",
  "grudge": "raiders",
  "hearth": "village_hearth",
  "creed": "the_kept_word",
  "oath": "",
  "origin": "Apprenticed to an old forge-master who died when raiders struck...",
  "blurb": "An oath-sworn swordsman with a scar for every promise he kept...",
  "companions": ["sera", "toln"]
}
```

- `difficulty` 1–5 — how hard this life is to live, shown as pips.
- `temper` — four-letter code into `tempers.json`; blank for anyone outside the sixteen.
- `background` · `grudge` · `hearth` · `creed` · `oath` — ids into the five pools in `data/lore/`.
  **All five are legitimately blank**; history is cast late (see [14](14-lore-pools.md)).
- `companions` — unit template ids that ride out with them, 0–2.

## `tempers.json` — the sixteen, and the quiz that picks one

`axes` describes the eight letters, `types` maps each four-letter code to an in-world name and the
`hero` that answers to it (blank until written), `quiz` holds the four questions asked before a
run, and `leans` holds what each letter is worth. See [13](13-heroes-and-tempers.md).

```json
"types": { "INTJ": { "display_name": "The Long Plan", "blurb": "…", "hero": "" } },
"quiz":  [ { "axis": "EI", "prompt": "…",
             "options": [ { "key": "E", "text": "…" }, { "key": "I", "text": "…" } ] } ],
"leans": { "T": { "damage": 1.05 } }
```

## `lore/*.json` — authored history

Five pools sharing one schema: `backgrounds`, `grudges`, `hearths`, `creeds`, `oaths`. Every entry
has `display_name`, `blurb`, `text`, `tags`, and may carry one `gift`.

```json
"apprentice_smith": {
  "display_name": "Apprentice Smith",
  "blurb": "Raised at the hearth-forge with hammer and anvil...",
  "text": "Put to the forge young, kept there by a master who taught by silence...",
  "tags": ["forge", "craft", "loss", "village"],
  "gift": { "kind": "item", "value": "iron_blade" }
}
```

Per pool: `hearths` add `site_kind` (the kind of place it names; since M13 a run starts at a crash site instead); `grudges` add `matches`
(`factions` / `kinds` / `templates` / `template_contains`, any hit counts); `creeds` add `holds`
and `despises`; `oaths` may add `toward`. `"provisional": true` marks a migrated stand-in.

Gift `kind` is one of `doctrine`, `item`, `gold`, `grudge`, `hearth`, `bond`, `stat` — and **no
gift may buy survival**: charms are delved for ([D24](06-decisions.md)) and grace-bearing doctrine
is refused by the validator.

## `casting.json` — which piece belongs to whom

The live many-to-many between the pools and the roster, with the reasoning kept alongside it in
`docs/worldbuilding/casting-ledger.md`.

```json
"backgrounds": {
  "locked": false,
  "pieces": { "the_forge_that_burned": { "candidates": ["bram"], "cast": "" } }
}
```

`locked: true` asserts every one of the sixteen carries a piece from that pool.

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

A person with `"guild": true` opens the Adventurers Guild hall when spoken to (if the settlement
still keeps one). Every keep and village area has one: a `guild_clerk`.

## `guild.json` — the Adventurers Guild

```json
{
  "contract": { "gold_base": 60, "gold_per_rank": 90, "giver": "the Adventurers Guild" },
  "states": { "open": "standing open", "broken": "BROKEN, and pouring", "brewing": "brewing, not yet open" },
  "lines": { "welcome": "The Guild hall at {hall}. …", "taken": "… shut {gate}. {gold} gold …" }
}
```

- `contract` — what a gate contract pays: `gold_base + gold_per_rank × rank index` (E is 0, S is 5).
- `muster` — which `ranks` raise one; `start`, `per_upkeep` and `needed` strength; `wait_upkeeps`
  once ready before it goes in alone; its odds alone (`win_base + win_per_strength × strength`);
  allies beside the company (`1 + strength / ally_every`, up to `max_allies`, drawn from `units`
  at party level + `ally_level_bonus`); and `gold` for standing with a muster that wins.
- `states` — how the register names a gate's state.
- `lines` — what the hall says; `{hall}`, `{gate}` and `{gold}` are filled in.
- `map` — the hall's map of its own country ([D50](06-decisions.md), `src/chronicle/atlas.gd`):
  `price` (scaled by the difficulty's `price` dial), the `radius` in tiles it draws in dim, and up
  to `max_marks` places it marks, nearest first among the `marks` kinds in that order of interest.
  Bought once per hall. `lines` are what the clerk says; `{hall}`, `{price}` and `{places}`.

The rest of the map lives in `world_rules.json` → `atlas`: `sight` (tiles seen round the party at
every step, continental or planar), `always_known` (kinds on the map from the start — the Tower
and home), the odds of a map folded into a find (`spoils_map_chance` for battle spoils and town
loot, `cache_map_chance` for a cache in the open, `chest_map_chance` for a chest in an area), the
`fragment_radius` a found map draws in and the `fragment_marks` kinds it can point at, and its
`lines`.

## `fall.json` — the fall, the landing, and the others (M13)

Read by `src/chronicle/fall.gd` and `src/chronicle/wanderers.gd`. See [17](17-the-sixteen-worlds.md).

```json
{
  "crash": { "home_name": "Where You Fell", "min_site_gap": 3, "min_tower_distance": 24,
             "min_gate_distance": 6, "max_haven_distance": 26, "attempts": 600 },
  "landing": { "lines": [ { "speaker": "", "text": "… comes down in {region} …" } ] },
  "standing_quest": { "title": "Ascend to heaven", "brief": "…", "progress": "Floor {floor} of {floors}, …",
                      "not_started": "…", "sealed": "…", "topped": "…", "badge": "ASCEND" },
  "wanderers": {
    "tempers": { "sera": "ISFP" },
    "preferences": { "NT": { "library": 5, "tower": 4, "keep": 1 } },
    "rules": { "stay_min": 60, "stay_max": 180, "steps_per_tile": 2, "rumour_at_rest": 0.4,
               "meetings_to_join": { "E": 1, "I": 2 } },
    "lines": { "first": { "NT": ["…"] }, "again": { "NT": ["…"] }, "heading": { "library": "…" } }
  }
}
```

- `crash` — where somebody may come down: walkable ground joined by land to the Tower, at least
  `min_site_gap` from any place, `min_tower_distance` from the Tower and `min_gate_distance` from an
  open gate, and within `max_haven_distance` of a village, keep or hut. The lead's crash site
  becomes the Home, renamed `home_name`.
- `landing` — the lines played when a new run first opens. `{name}`, `{region}`, `{ground}` and
  `{tower_way}` (a compass word) are filled in.
- `standing_quest` — "Ascend to heaven" ([D53](06-decisions.md)) as the journal shows it.
  `{floor}`, `{floors}`, `{chapter}` and `{chapters}` are filled in; `badge` marks the Tower on the map.
- `wanderers.tempers` — the temper of each hero who is not yet one of the sixteen. A hero with a
  `tempers.json` slot uses that instead. **Inferred** ([agenda item 26](worldbuilding/answers.md#what-is-still-to-decide)).
- `wanderers.preferences` — by temper group (NT, NF, SJ, SP), how much each kind of place draws
  them. A weight of 0 means never. Nearness divides the weight.
- `wanderers.rules` — how long they stay (`stay_min`..`stay_max` steps), how fast they walk
  (`steps_per_tile`), the chance a rest at a settlement brings word of one (`rumour_at_rest`), and
  how many meetings an Outward (`E`) or Inward (`I`) temper needs before they will join.
- `wanderers.lines` — what they say. `first`, `again` by temper group; `heading` by kind of place;
  `rumour` and `rumour_road` for the inn; `{name}`, `{title}`, `{place}`, `{lead}` are filled in.

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

## `names.json` — what people are called

```json
"strong": { "Cassius": ["Cass", "Cassi"], "Octavia": ["Tavi", "Ocka"] },
"noble_range": 10,
"noble_share": 0.8,
"far_share": 0.1
```

Regional names ([D39](06-decisions.md)), read by `src/chronicle/names.gd`. Every name is written
in its **strong** form with the **stems** ordinary people carry. Beside a keep a person carries
the strong form `noble_share` of the time, falling to `far_share` at `noble_range` tiles and
beyond. Everyone is also *of* the nearest village, keep or hut. The sixteen's own names are not
here — they are fixed per character.

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

## `credits.json` — the credits

Read by `src/ui/credits_roll.gd` through `SaveFile.read`, and shown by the credits screen off the
title and the credits page of the system menu. Sections are shown in order.

```json
{
  "title": "Credits",
  "sections": [
    {
      "heading": "Engine",
      "entries": [
        { "name": "Godot Engine", "role": "godotengine.org — MIT licence", "note": "This game uses Godot Engine…" }
      ],
      "notice": "Copyright (c) 2014-present Godot Engine contributors…",
      "engine_components": true
    }
  ]
}
```

- Each entry needs `name`; `role` and `note` are optional lines under it.
- `notice` is a block of licence text, shown as written. The `Engine` section's notice must be
  Godot's licence word for word — the controls suite compares it with `Engine.get_license_text()`.
- `engine_components: true` adds one line per third-party component of the running engine, read
  from `Engine.get_copyright_info()`.
- What is credited follows [22 — Asset provenance](22-asset-provenance.md); change both together.

## Save file — `user://earth-kings.save.json`

Written by `GameState`. Contains the serialised `World` (seed, tiles, sites, step count, player
cell, generated trees, codex, the others of the sixteen in `wanderers`, and the party's map: `explored` and `charted` as one bit a tile,
deflated and base64, and `marked` as a sorted list of `"x,y"`) and the `Roster` of Characters. A
save from before the map had no `explored` and loads with the whole continent seen. Generated abilities are restored
from the saved tree definitions on load, so a save never loses a power it discovered.

## Conventions

- Ids are `snake_case` and are the key, never a field inside the value.
- Colours are hex strings.
- Cells are `[x, y]` pairs.
- Omit a key rather than setting it to `null` — typed loaders will reject nulls.
