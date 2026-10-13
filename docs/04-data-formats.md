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
- `body_scale` — how tall the body stands against an ordinary one, as a multiple (default 1.0,
  held to 0.5–3.0). A big unit still holds one tile and grows up from its feet ([D57](06-decisions.md)).
- `sprite_dir` — a folder holding `north.png` / `south.png` / `east.png` / `west.png`. Omit to
  render a coloured token instead.

## `classes.json` — main classes

```json
"sworn_blade": {
  "display_name": "Sworn Blade",
  "colour": "#c8463c",
  "growth": { "max_hp": 6, "attack": 2.0, "defense": 1.4, "speed": 0.3 },
  "themes": ["edge", "iron", "vigil"],
  "grants": ["cleave"]
}
```

- `growth` — added per level above 1, then rounded. Floats are fine.
- `themes` — which ability-grammar themes this class's generated trees are drawn from.
- `grants` — abilities the class hands over on the spot.
- `colour` — the class's own colour (`#rrggbb`): its card when a path is chosen, the trail of its
  powers, its name on the character sheet and the level-up banner. Optional; parchment if left out.
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
- `bonus: true` — a minor ability: its default cooldown is a short 4 s and it lands with no wind-up.
- `cooldown` — seconds before it can be used again in the fight ([D36](06-decisions.md)).
- `cast` — seconds of wind-up before it lands. `0` lands at once. A cast of
  `rules.charged_from` (2 s) or more in `skirmish.json` is **charged**: it hits `charged_power` (1.6×)
  harder and costs `charged_energy`, and a stun breaks it off ([D59](06-decisions.md)).
- `stun` — seconds the target is stunned: it cannot step, swing or cast, and a cast it was
  winding up is lost.
- `energy` — what the skill costs from the user's energy bar. Optional; otherwise
  `rules.energy_cost`, or `charged_energy` for a charged spell.

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
  or in a fight from the fighter's card, which takes 1.5 s (`"heal": 25`).
- `signature: "<hero id>"` — a weapon made for one of the sixteen (M15, [D33](06-decisions.md)). It
  suits nobody, whatever `suits` says, is never sold or looted, and only reaches a run by falling
  out of the sky after its owner has died in an earlier world (see `fall.json` → `siblings`).

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

**Props.** Each picture is drawn at the size `data/props.json` gives its kind (see below) and stands
in the way if its kind does. An entry may override any of it: `scale`, `solid`, `base` ([width,
depth] cells a solid prop blocks, centred on its cell and running back from it), `flip` (mirrored)
and `offset` ([dx, dy] pixels off the middle of its cell). A prop can be part of a favour: `set_flag`
is set the first time it is looked at, with `found_line` said then; `requires` / `requires_not`
(flags) decide whether it is there at all. A cell the author means somebody to stand on (spawn,
exits, spots, chests, seats, anyone standing there) is never blocked, whatever is drawn on it.
A spot may carry `set_flag` too.

**`dressing`** is a second list of props written by `tools/dress_areas.py` — trees, bushes, flowers,
birds and bugs out of doors, furniture in rooms — one piece a line, kept apart from `props` so the
tool can write it again without touching the author's. It never blocks the way to an exit, door,
chest, spot or person: every solid piece is tried against a walk from the spawn first. The same
area always comes out the same.

**Buildings** with an `art` (a key of `props.json` → `buildings`) are drawn from that picture at its
`scale`, on its footprint `size`, with the door in the middle of the front row unless `door` says
otherwise; `scale`, `size`, `flip` and `lived_in` may be given. A building with no `area` behind
its door says its `shut` line (a string or a list) when walked into.

**`talk`** on a person builds a conversation from data instead of a file ([`src/dialogue/talk.gd`](../src/dialogue/talk.gd)):

```json
"talk": {
  "hello": ["Fresh this morning! Most of it."], "again": "You came back!",
  "ask": [{ "q": "What's good today?", "a": "The cheese.", "requires": "flag", "once": true,
            "reward": 10, "item": "apple", "cost": 5, "check": { "skill": "wits", "dc": 10 }, "no": "Mind your own." }],
  "sells": [{ "item": "bread" }, { "item": "whetstone", "price": 60, "restock": true }],
  "job": { "flag": "job:wat_stone", "done_flag": "found:wat_stone", "offer": "...", "done": "...", "gold": 30, "item": "hearth_coin" },
  "refuse": { "chance": 0.4, "text": "Not now.", "unless": "smith:won", "bribe": 5,
              "check": { "skill": "might", "dc": 11 }, "won": "Fine.", "won_flag": "smith:won", "still_no": "No." },
  "news": true, "more": "Anything else?", "leave": "Goodbye.", "bye": "Mind the geese."
}
```

- `hello` opens it (`again` from the second time); every text may be a list, one picked each time.
- `ask` — the questions the party can put. An answer that pays (`reward` gold, an `item`) is said
  once. `cost` is gold to ask; a `check` rolls for it, and on a miss they say `no`.
- `sells` — one reply per thing, at the market's price for it (`Market.price_of`, through the
  difficulty's `price` dial) unless `price` is given. Each sells once unless `restock`.
- `job` — a favour: asked for, taken on (sets `flag`), and paid (`gold`, `item`) once `done_flag`
  is set by something found elsewhere — a prop's or a spot's `set_flag`.
- `refuse` — whether they will talk at all: on their `chance` each time (1.0, every time) until an
  `unless` flag is set. A `bribe` and a `check` are ways round it; `won_flag` makes it stick.
- `news` adds "Heard any news?" (the innkeepers' rumours); a person with `talk` and `chatter` still
  mutters as you pass.

## `props.json` — how big every prop and building is drawn

Every picture is a 64-pixel square and a person stands about 60 pixels tall on a 64-pixel cell, so
sizes are set beside a person: a tree three people tall, a bird the size of a bird.

```json
{
  "kinds": { "tree": { "scale": 3.0, "solid": true, "battle_scale": 2.0 }, "great_tower": { "scale": 4.0, "solid": true, "base": [3, 1] } },
  "art": { "nature/great_oak": "tree", "nature/cactus": { "kind": "flower", "scale": 2.0 } },
  "buildings": { "tavern": { "scale": 3.0, "size": [3, 2], "look": "a log lodge with antlers on the gable" } }
}
```

- `kinds` — `scale`, `solid`, `base` and `battle_scale` (the size in a battle, before it is scaled
  to a battle's 48-pixel cell; `scale` if absent).
- `art` — every picture under `art/props/` (path without `.png`), as its kind or as its kind plus
  overrides. Unknown art is drawn as it is and blocks nothing.
- A prop whose art has a folder of frames beside it (`landmark/lighthouse/frame_000.png` …) plays
  them over and over: the portals glow, the lighthouse sweeps.
- `buildings` — `scale`, footprint `size` and what each picture looks like; seven are copies of
  another, and say so.

Read by `Database.prop_size` / `Database.building_art`; used by `AreaProp`, `AreaBuilding`,
`AreaMap` (what blocks) and the battle's scenery.

## `biomes.json` — the lands, and how each one's ground is laid out

```json
{
  "size": [32, 22],
  "landmark_chance": 0.22,
  "biomes": {
    "swamp": {
      "name": "swamp", "tint": "#90b8a0", "line": "Warm, wet and loud with things you cannot see.",
      "ground": { "floor": "swamp_floor", "bare": "swamp_bare", "liquid": "swamp_liquid", "cover": "swamp_cover" },
      "layers": ["swamp_ground", "swamp_pool", "swamp_cover"],
      "props": { "trees": ["biome/swamp_willow"], "bushes": ["biome/swamp_reeds"], "rocks": ["biome/glow_caps"], "small": ["biome/swamp_reeds"] },
      "density": { "trees": 0.06, "bushes": 0.051, "rocks": 0.0064, "small": 0.064 },
      "features": { "pools": 3.5, "cover": 3, "bare": 1, "outcrops": 0.3 },
      "sea_shore": true
    }
  }
}
```

- `size` — cells across and down of every generated ground. `landmark_chance` — the share of
  grounds with something somebody left (a cold camp, a stone ring, a cairn, a cache).
- `ground` — the four area terrains (`tilesets.json` → `terrains`) the land is made of; `layers`,
  the sheets they are drawn with, bottom first. Cover is walkable and blocks a band's sight.
- `props` — art for each kind of thing, sized by `props.json`; `density` — how many per cell;
  `features` — how many of each kind of patch a ground gets, on average.
- `sea_shore` — whether a ground on the coast gets a shore of the land's own water.

Which land a tile is: `src/chronicle/biome.gd`. Laid out by `src/area/ground_gen.gd` and handed to
the `Database` as an area (`ground_<x>_<y>_<land>`), so it is walked like any area under `areas/`.

## `world_rules.json` → `ground_watch` — bands met on the ground (D66, D68, D70)

Read by `src/area/area_watch.gd` (the band on the ground) and the ground's fight hand-off in
`src/area/area_scene.gd`.

- **Sight:** `sight_base + sight_per_reach × reach` ground cells round the band (its world reach,
  usually 2, so 5). Trees, houses and rock block the line; `water` and every land's `*_liquid` do
  not. Ground that is cover (`"cover": true` on its terrain in `tilesets.json`, or named in `cover`)
  and walk-through bushes are never seen; the cells the band's own figures stand on always are.
- **Where it stands:** on its own tile, in the open at least `keep_away` cells beyond its sight from
  where the party came in; watching from the next tile, just inside that edge.
- **Patrol:** `patrol_points` stops within `patrol_reach` cells, walked a cell every
  `patrol_step_seconds`, resting `patrol_pause` [min, max] seconds at each; a loop that never brings
  where the party came in into sight. The red moves with it.
- **Seen:** a step into the red, or the band walking into view of the party. `spotted_seconds` of
  heads turning, the band rushing `charge_share` of the way in `charge_seconds`, then the fight on a
  field `field_margin` cells round everyone, `field_smallest` to `field_largest`. The field carries
  `view` (the ground camera's `centre` in ground pixels and its `zoom`): the fight opens on it and
  draws back over `pull_back_seconds`. Out of cover into the red sets `ambush`.

The world's `bands` in the ground's payload: each `{ key, pack, sight, reach, faction, label,
from }`, `from` the `[dx, dy]` way to the tile it stands on (`[0, 0]` for this one).

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

Read by `src/chronicle/fall.gd`, `src/chronicle/wanderers.gd` and (`siblings`, M15)
`src/chronicle/siblings.gd`. See [17](17-the-sixteen-worlds.md).

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
  },
  "siblings": {
    "perturbation": 0.25,
    "echo": { "stay_steps": 400 },
    "weapon": { "min_distance": 5, "max_distance": 12, "attempts": 400 },
    "ghost": { "outward": 3, "inward": 1, "per_visit": 2 },
    "signatures": { "bram": "oathkeeper" },
    "lines": { "ending_title": "The world of {name} is ending.", "weapon_lands": "…", "ghost_fall": "…" }
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
- `siblings` (M15) — the worlds after the first. Everything in it is **Inferred**, agenda items 50
  to 56. `perturbation` is the share of a sibling world's gates and library shelves dealt again
  (0 an identical twin, 1 all of them). `echo.stay_steps` is how long an earlier lead's copy waits
  at the settlement nearest the new crash site. `weapon` is how near that crash site a dead lead's
  weapon comes down. `ghost` is how many lines of their journal a ghost shares on the first night
  (`outward` for an E temper, `inward` for an I) and how many more each night after (`per_visit`).
  `signatures` names each hero's weapon in `equipment.json`. `lines` is everything said: the end
  of a world (`ending_*`), the landing, the weapon falling and found, the copy (`echo_*`, by temper
  group) and the ghost (`ghost_*`). `{name}` is the dead lead, `{lead}` the living one, `{weapon}`,
  `{way}`, `{place}`, `{level}`, `{floor}` and `{killer}` are filled in.

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

## `skirmish.json` — the fight's rules, passives, enemy roles and feel

Read by the fight in `src/skirmish/` ([18](18-combat-direction.md#the-fight)).

```json
{
  "rules": { "max_passives": 3, "base_crit": 0.05, "crit_multiplier": 1.6, "guard_cap": 0.5,
             "out_of_combat_after": 4.0, "big_hit_share": 0.2, "hit_stop": 0.07,
             "shake_on_down": 9.0, "shake_on_kill": 4.0, "shake_on_crit": 2.5,
             "energy_max": 100.0, "energy_regen": 5.0, "energy_cost": 20.0, "charged_energy": 35.0,
             "energy_recover_at": 0.5, "charged_from": 2.0, "charged_power": 1.6,
             "use_item_time": 1.5, "items_per_fighter": 2,
             "block_chance": 0.15, "block_per_defence": 0.01, "block_max": 0.4,
             "ambush_head_start": 2.0, "swings_per_practice": 3 },
  "passives": {
    "shieldwall": { "display_name": "Shieldwall", "description": "…", "effect": "aura",
                    "radius": 2, "grants": { "guard": 0.15 } }
  },
  "by_template": { "brigand_chief": ["war_cry"] },
  "by_class": { "sworn_blade": ["shieldwall"] },
  "by_ability": { "riposte": ["barbed_guard"] },
  "roles": { "charger": { "display_name": "Charger", "description": "…", "charge_from": 3,
                          "pace": 1.7, "charge_bonus": 0.4 } },
  "role_by_template": { "brigand_archer": "kiter" },
  "role_by_kind": { "beast": "charger" },
  "ranged_role": "kiter",
  "healer_role": "healer",
  "shield_bearers": { "by_class": ["sworn_blade"], "by_ability": ["shield_bash"] },
  "training_pouch": { "herbs": 2, "red_draught": 1 },
  "decor": { "trees": ["nature/great_oak", "…"], "bushes": ["nature/bramble", "…"] }
}
```

- **Energy** ([D59](06-decisions.md)): every fighter starts with `energy_max`, gets `energy_regen` a
  second back, and pays for each skill. Below `energy_cost` they are **tired** — basic attacks only —
  until the bar is back to `energy_recover_at` of full.
- **Draughts and herbs**: the pouch is the party's draughts in `GameState.stores`; in a fight the
  world started what is used is taken from the stores ([D65](06-decisions.md)). A sandbox fight
  (training, the coliseum) only counts them, and uses `training_pouch` when there are none. A use takes
  `use_item_time` seconds, mends the item's `mends` × `HEALTH_SCALE`, and a fighter has at most
  `items_per_fighter` a fight.
- `ambush_head_start` — seconds an ambushed side's opening is held back while the party acts at
  once. `swings_per_practice` — landed basic swings that count as one use toward proficiency;
  every skill that lands counts once. Both **Inferred** ([D65](06-decisions.md)).
- `decor` — the props (`art/props/<id>.png`, sized by `props.json`'s `battle_scale`) planted on a
  field: `trees` on crags, walls and a third of the edge, `bushes` in the brush. Scenery only.
- **Shields**: a unit with a class, ability or template (`by_template`) under `shield_bearers` blocks a
  melee basic attack that does not come from behind, with a chance of `block_chance` +
  `block_per_defence` × its defence, at most `block_max`. Not while casting, using an item or stunned.

- A unit's passives are gathered from `by_template`, then each of its classes in `by_class`, then
  each ability it knows in `by_ability`, and capped at `rules.max_passives`.
- `effect` is one of `lifesteal`, `thorns`, `flank_bonus`, `crit`, `echo`, `regen` (out of the
  fighting), `last_stand` (with `threshold`), `reset_on_ally_down`, or `aura`, whose `grants` may
  hold `guard` (less damage taken), `haste` (faster basic attacks) and `regen` (health a second),
  each a share. `also` adds a second effect to the same passive, e.g. `{ "flank_bonus": 0.15 }`.
- An enemy's role is `role_by_template`, else `healer_role` if it carries a non-bonus heal for an
  ally with a reach of two or more, else `ranged_role` if its basic attack reaches three, else
  `role_by_kind`. Role keys: `charge_from`, `pace`, `charge_bonus` (charger), `keep_away`,
  `retreat_every` (kiter and healer), `heal_below` (healer). A role with only a name changes nothing.

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
cell, generated trees, codex, the others of the sixteen in `wanderers`, in `echoes` which world of
the sixteen this is and what has come through from the ones that ended (see
`src/chronicle/siblings.gd`), and the party's map: `explored` and `charted` as one bit a tile,
deflated and base64, and `marked` as a sorted list of `"x,y"`) and the `Roster` of Characters. A
save from before the map had no `explored` and loads with the whole continent seen. Generated abilities are restored
from the saved tree definitions on load, so a save never loses a power it discovered.
It also keeps the run's `mode` (`classic` or `iron_man`; a save without one opens as Classic) and
`saved_at`, how the save is remembered on the fall screen ("you rested at Oakham").

When it is written is the mode's: `data/world_rules.json` → `modes.settings.<mode>` gives
`manual_save` (the menu's Save and Load), `reload_on_death` (Classic's fall screen), and
`autosave`, the points the game saves itself at — `start`, `rest`, `chapter`, `road` (every
return to the map) and `leave` (the title button, closing the window). See
`src/chronicle/run_mode.gd`.

## The record of the fallen — `user://earth-kings.sixteen.json`

Kept outside the save ([D47](06-decisions.md)) by `src/chronicle/sixteen.gd`.
`fallen_heroes` and `fallen_tempers` close the picker and the quiz; `worlds` (M15) is every world
that ended, oldest first, each marked `gone` and holding what `Siblings.remember` kept: the lead's
`hero`, `name`, `temper`, `level`, the Tower `floor`, `killer`, the world's `seed` and `base_seed`,
their `weapon`, what went `well`, the journal `pages`, and `self`, the calling and beliefs they
started with. A new game with no seed asked for is a sibling of `worlds[0]`. Wiped only with the
rest of the record, once every lead has fallen.

The file carries a `version` (`GameState.SAVE_VERSION`, now 3). Nothing a player has is lost to
an update or a crash ([D56](06-decisions.md)):

| File beside it                 | What it is                                                                                                                  |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------- |
| `earth-kings.save.json.tmp`    | A save being written. Renamed over the real one only once it is whole                                                       |
| `earth-kings.save.bak.json`    | The save before the last one, kept by every write. Loaded instead when the save itself will not parse, or is missing        |
| `earth-kings.save.v<N>.bak.json` | A version-N save set aside, untouched, before it was upgraded, refused or given up on. Never rotated                     |

On load, a save older than `SAVE_VERSION` is upgraded one version at a time by the steps in
`src/chronicle/save_migrations.gd`. Version 2 → 3 is a real step (alignment dropped, the old int
`hearth` renamed `hearth_vigour`, the history fields filled off the hero record). Version 1 predates
the walked world and has no step: it is set aside and a new run begins, as before. A save from a
newer version is refused and left exactly as it is. Each of these says so on screen
(`EventBus.save_notice`). Raising `SAVE_VERSION` means adding the step to it in the same commit;
`tests/seams_smoke_test --check=old_saves` fails otherwise.

## Conventions

- Ids are `snake_case` and are the key, never a field inside the value.
- Colours are hex strings.
- Cells are `[x, y]` pairs.
- Omit a key rather than setting it to `null` — typed loaders will reject nulls.
