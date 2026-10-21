# 04 — Data formats

Everything in `data/` is plain JSON so content can be added without opening the editor and diffs
stay readable. All of it is read-only at runtime.

**Money is copper** ([D253](06-decisions.md)): every amount in `data/` (a price, a `cost`, a chest's or
a reward's `gold`, a bribe, a purse) is counted in copper, 100 to a silver, 100 silver to a gold,
100 gold to a platinum, and the game says it in coins (`src/chronicle/coins.gd`: "1 gold 60 silver").
A key named `gold` is the old name and still means money, in copper. Words that put an amount in a
line take it as `%s` or `{gold}` / `{price}` / `{ransom}`, already said in coins.

## `terrain.json` — tile types

```json
"hill": { "name": "Hill", "move_cost": 2, "height": 1, "walkable": true, "color": "#6b8f4e" }
```

Used by both the battle grid and the world map. `move_cost` is per tile entered; `height`
differences are gated by a unit's `jump`. On the map of the continent a cell's `height` lights it and draws
its peaks (D343, `world_rules.json` → `heights.on_the_map`).

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
- `family`, `tier`, `tint` — a monster's place in its family's five tiers ([D262](06-decisions.md)):
  `family` is the plain kind's id (`goblin`), `tier` 1 (lesser) to 5 (chieftain or caster), and
  `tint` a colour laid over the family's shared art, in a fight and on the ground, until the tier has
  art of its own (A39). Which tier a fight meets is `encounters.json` → `tiers`.

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
- `lead` — the one of the sixteen this class belongs to (their hero and unit id). That lead starts
  in it at level 1, with its `grants` as their four moves on Q W E R, and at level 2 is offered it
  first with the classes anyone can learn after it ([D64](06-decisions.md)). A class with no `lead`
  is one anyone can learn: a template with no `classes` is offered only those. The sixteen are
  listed in [21](21-the-sixteen-first-draft.md#the-sixteen-classes-as-built).

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
- What a skill leaves on whoever it lands on ([D192](06-decisions.md)), each optional:
  `knockback` and `pull` (tiles: straight away from the user, or towards them, stopping at a wall,
  a ledge, the field's edge or a body), `slow`, `burn`, `bleed`, `knockdown` (stunned and laid
  flat) and `expose` (takes more), all in seconds. Only when the move is let go as a skill: the same
  move swung as a fighter's plain attack carries none of them. How each works is `conditions` in
  `skirmish.json`.
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
- `taken: "eat"` — on a draught that is food (the loaf, the pie, cheese, herbs): the button says Eat and
  the lines "eats" ([D324](06-decisions.md)); left out, it is drunk.
- `signature: "<hero id>"` — a weapon made for one of the sixteen (M15, [D33](06-decisions.md)). It
  suits nobody, whatever `suits` says, is never sold or looted, and only reaches a run by falling
  out of the sky after its owner has died in an earlier world (see `fall.json` → `siblings`).
- `proof: ["cold"]` — hazards it keeps off its bearer on a land that has one (`biomes.json` →
  `hazards`): the Padded Coat, Feather Mail, Foxfire and the Ember Blade against the cold, the
  Frost Staff and the Halo Robe against the heat, the Salt Pouch against ooze (**Inferred**, [D71](06-decisions.md)).

## `heroes.json` — the leads a run can be started as

A side-car on `units.json`: the key **is** the unit template id, and the name and stats come from
there. This file adds only what a lead needs on top of a unit.

```json
"atlas": {
  "title": "The Long Plan",
  "pronoun": "he",
  "temper": "INTJ",
  "difficulty": 4,
  "background": "", "grudge": "", "hearth": "", "creed": "", "oath": "",
  "origin": "",
  "blurb": "A boy too small to walk properly, carried in robes too big for him...",
  "companions": [],
  "found_at": "library",
  "elsewhere": "being carried to the oldest library within reach",
  "first": "You will want to know why I am sitting on a library step...",
  "rumour": "At {place} there is a boy who cannot walk, reading as if the books owed him something..."
}
```

- `difficulty` 1–5 — how hard this life is to live, shown as pips.
- `pronoun` — `he` or `she`, from the blurb; the replayed opening says it of a lead who has died
  ([D153](06-decisions.md)). Missing means "they".
- `temper` — four-letter code into `tempers.json`; blank for anyone outside the sixteen.
- `background` · `grudge` · `hearth` · `creed` · `oath` — ids into the five pools in `data/lore/`.
  **All five are legitimately blank**; history is cast late (see [14](14-lore-pools.md)).
- `companions` — unit template ids that ride out with them, 0–2.
- A lead's own class is not named here: the class in `classes.json` whose `lead` is this id is theirs
  ([D63](06-decisions.md)).
- `found_at` — the kind of place (`library`, `gate`, `keep`, `village`, `hut`) they make their own
  when somebody else is the lead: they walk there first and stay there longest
  (`fall.json` → `wanderers.rules`). `elsewhere` is docs/21's line for it, for people to read.
- `first` — what they say the first time the company meets them; `rumour` — what an inn says of
  them while they are at their own kind of place (`{name}`, `{title}`, `{place}`). Both optional; the
  temper group's lines stand in.
- `restless` — stays only a short while anywhere (Iris, Liber).

## `story_npcs.json` — the original twelve, met in the world

The twelve heroes the game began with, as story people rather than leads ([D79](06-decisions.md)).
Keyed by their unit template id. Each one stands in `area` as a person whose `story_npc` is that id
(see `areas/*.json`), with a `talk` block; their companions stand beside them with the same
`story_npc` and `chatter`.

```json
"bram": {
  "name": "Bram the Sworn Blade",
  "unit": "bram",
  "area": "village",
  "hook": "Kaelen's apprentice from Oakhaven, carrying his dead master's greatsword...",
  "company": []
}
```

- `area` — the area id they stand in. `hook` — where their story picks up, from
  [11](11-character-backstories.md). `company` — unit ids of the companions standing with them.

## `tempers.json` — the sixteen, and the quiz that picks one

`axes` describes the eight letters, `types` maps each four-letter code to an in-world name and the
`hero` that answers to it (blank until written), `quiz` holds the questions asked before a
run (the same odd number for every `axis`, each pair settled by majority), and `leans` holds what each letter is worth. See [13](13-heroes-and-tempers.md).

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
  "rows": ["#######....######", "##....======...##"],
  "spawn": [8, 12],
  "exits": [
    [8, 14],
    [8, 0]
  ],
  "props": [{ "art": "barrel", "cell": [6, 10] }],
  "chests": [{ "cell": [12, 4], "gold": 1000, "item": "bone_sword" }],
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

A spot with `"page": true` is a page of the place's story (D314): said like any spot when stood on, kept once a
run as the flag `story:<area>:<x>:<y>`, and when every page of the place is read the area's `story.end` is said
and written in the annals (`world_rules.json` → `wilds.story_annals`, flag `story:<area>:told`). The five wilds
have three pages each.

A person with `"guild": true` opens the Adventurers Guild hall when spoken to (if the settlement
still keeps one). Every keep and village area has one: a `guild_clerk`.
A person with `story_npc` is one of the original twelve, or a companion standing with them
(see `story_npcs.json`).

**`rounds`** on a person is their work ([D85](06-decisions.md)): stops they walk between in turn,
each `{ "cell": [x, y], "line": "Draws a bucket from the well.", "stay": 5 }` — `line` is said on
getting there and `stay` is how many seconds they stay (an ordinary pause if left out). A person on
rounds does not `wander`. Every stop has to be walkable from where they stand.

**`walls`** on a place (`"stone"`, `"timber"` or `"adobe"`) stands it behind walls on the land
([D85](06-decisions.md)): on the ring of cells round it, a tower at each corner and either side of
each exit, a gap in front of each exit, and a lane kept clear outside. The place needs two cells
spare each way in its tile. The pictures are `art/props/walls/<build>_run`, `_side` and `_tower`.
`walls_requires` (flags) puts them up only once those are set: the crater's wall, built by Muck Muck
([D251](06-decisions.md)).

**Built later** ([D251](06-decisions.md)): a building or a person may carry `requires` /
`requires_not` (flags) like a prop, and is there only while they allow. A building with `requires`
that stands clears its footprint and a cell round it of every prop without flags of its own (the
trees that grew where Muck Muck built). `home.json` holds the crater town this way, behind
`town:smithy`, `town:infirmary` and `town:wall`.

**`covers`** on a place ([w, h]) stands it over that many tiles of the land, not one ([D247](06-decisions.md)),
with the tile `anchor` ([x, y] within it, [0, 0] when absent) on its site. It is laid out whole in the
middle of a ground w slots by h, the land's floor round it, and cut into one piece per tile; paths
from the land meet its exits, and sides between its pieces are open. Stormreach (`city_streets`,
[2, 2]) is the one so far.

**Props.** Each picture is drawn at the size `data/props.json` gives its kind (see below) and stands
in the way if its kind does. An entry may override any of it: `scale`, `solid`, `base` ([width,
depth] cells a solid prop blocks, centred on its cell and running back from it), `flip` (mirrored)
and `offset` ([dx, dy] pixels off the middle of its cell). A prop can be part of a favour: `set_flag`
is set the first time it is looked at, with `found_line` said then; `requires` / `requires_not`
(flags) decide whether it is there at all. A prop with `try` (`chance`, `item`, `win`, `lose`, `tried`)
is tried once a run with a throw of the dice when it is looked at (D318, the sword in the Tower's yard):
the first look rolls and hands the item over or not, every look after says `tried`; `AreaProp.try_once`,
the area scene's `_try_once`, flags `tried:<area>:<x>:<y>` and `:won`. A cell the author means somebody to stand on (spawn,
exits, spots, chests, seats, anyone standing there) is never blocked, whatever is drawn on it.
A spot may carry `set_flag` too. A prop with `act` (a doing of the place's, such as `_climb_here`
on the Tower's runes) is the way into it: standing at it the hint says that doing's prompt, and
looking at it does it; while the place does not offer it, the line is said with the reason
([D107](06-decisions.md)). A prop with `spire` (`width`, `storeys`, `step`, `build`) is the Tower's
stand-in, drawn tall in that wall build's stone from the top of its cell (`src/area/area_spire.gd`,
[D108](06-decisions.md)).

**`dressing`** is a second list of props written by `tools/dress_areas.py` — trees, bushes, flowers,
birds and bugs out of doors, furniture in rooms — one piece a line, kept apart from `props` so the
tool can write it again without touching the author's. It never blocks the way to an exit, door,
chest, spot or person: every solid piece is tried against a walk from the spawn first. The same
area always comes out the same.

**Buildings** with an `art` (a key of `props.json` → `buildings`) are drawn from that picture at its
`scale`, on its footprint `size`, with the door in the middle of the front row unless `door` says
otherwise; `scale`, `size`, `flip` and `lived_in` may be given. A building with no `area` behind
its door says its `shut` line (a string or a list) when walked into; one with `area_requires`
(flags) opens on its `area` only once those are set, and says `shut` until then, its inside then
titled `owned_name` (your house in Stormreach, [D252](06-decisions.md)). A building with a `fight`
(`terrain`, `title`, `enemies` as `[{ "unit", "level" }]`, and `scene`, `skirmish` by default) is a
door into a training fight that comes back out of the same door; nothing in it counts.

**`talk`** on a person builds a conversation from data instead of a file ([`src/dialogue/talk.gd`](../src/dialogue/talk.gd)):

```json
"talk": {
  "hello": ["Fresh this morning! Most of it."], "again": "You came back!",
  "ask": [{ "q": "What's good today?", "a": "The cheese.", "requires": "flag", "once": true,
            "reward": 10, "item": "apple", "cost": 5, "check": { "skill": "wits", "dc": 10 }, "no": "Mind your own." }],
  "sells": [{ "item": "bread" }, { "item": "whetstone", "price": 1500, "restock": true }],
  "job": { "flag": "job:wat_stone", "done_flag": "found:wat_stone", "offer": "...", "done": "...", "gold": 750, "item": "hearth_coin" },
  "refuse": { "chance": 0.4, "text": "Not now.", "unless": "smith:won", "bribe": 5,
              "check": { "skill": "might", "dc": 11 }, "won": "Fine.", "won_flag": "smith:won", "still_no": "No." },
  "heal": { "price": 1000, "q": "Patch up my companions.", "done": "There.", "whole_q": "Can you look us over?", "whole": "Nobody here needs me." },
  "news": true, "more": "Anything else?", "leave": "Goodbye.", "bye": "Mind the geese."
}
```

- `hello` opens it (`again` from the second time); every text may be a list, one picked each time.
- `ask` — the questions the party can put. An answer that pays (`reward` gold, an `item`) is said
  once. `cost` is copper to ask; a `check` rolls for it, and on a miss they say `no`.
- `sells` — one reply per thing, at the market's price for it (`Market.price_of`, through the
  difficulty's `price` dial) unless `price` is given. Each sells once unless `restock`.
- `job` — a favour: asked for, taken on (sets `flag`), and paid (`gold`, `item`) once `done_flag`
  is set by something found elsewhere — a prop's or a spot's `set_flag`.
- `refuse` — whether they will talk at all: on their `chance` each time (1.0, every time) until an
  `unless` flag is set. A `bribe` and a `check` are ways round it; `won_flag` makes it stick.
- `heal` — they mend the whole company for `price` copper (through the difficulty's `price` dial), as a
  rest does: `q` is offered while anyone is hurt and the purse can pay, and they say `done`; with
  nobody hurt, `whole_q` is offered instead and they say `whole`, for nothing ([D176](06-decisions.md)).
- `news` adds "Heard any news?" (the innkeepers' rumours); a person with `talk` and `chatter` still
  mutters as you pass.
- **Asking them to walk with the company** ([D277](06-decisions.md), [`src/chronicle/recruits.gd`](../src/chronicle/recruits.gd)):
  anyone with `talk` gets "Walk with us." unless they keep a post (`sells`, `heal`, `guild`), stand in an
  area in `world_rules.json` → `recruit_anyone` → `no_areas`, are named in its `stays`, or say
  `"recruit": false`. It is a Charisma check (d20 + half the best talker's charisma: level × `per_level`,
  plus what folk here have heard of the company, plus `outward` for an E temper) against `dc`, or
  `story_dc` for one of the story folk, or the person's own `recruit_dc`. A no names what would win them
  over: their own `job`, if they have one (done when it is paid), else one of `trust` (a Ledger counter
  grown by `need` from where it stood when they said no). Done, they come without a roll. They join at
  the lead's level when the conversation ends (unnamed folk, "a settler", take a name), and their place
  stands empty after. `talk.recruit` overrides any line: `q`, `again_q`, `yes`, `no`, `waiting`,
  `trusted`, `full`.
- `hires` — they keep the sellswords' book ([D345](06-decisions.md), [`src/chronicle/sellswords.gd`](../src/chronicle/sellswords.gd)):
  `q` opens it, `offer` reads it out, one reply for each still on the board (offered while the purse
  can pay and the company has a seat), `done` once one is hired, `none` when nobody is, `done_q` to
  close it. A person with `hires` keeps a post and cannot be recruited. The board, the jobs, the
  prices and the lines are `world_rules.json` → `sellswords`: `board_size` at once, dealt again every
  `refresh_steps`; one of `templates` at the lead's level give or take one, for one of `jobs` (`for`
  is how the book says it, `price` its weight), at `cost_base` + `cost_per_level` a level. A sellsword
  carries `contract` (`job`, `paid`) and goes when a gate is shut (`gate`) or a chapter closes
  (`chapter`).

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
  them over and over: the portals glow, the lighthouse sweeps. `frame_seconds` on its `art` entry is
  how long each frame shows (0.13 if absent; the lighthouse's is 0.45, [D178](06-decisions.md)).
- `life` on a kind or an `art` entry makes the picture alive wherever it is laid down
  ([D179](06-decisions.md), `src/area/area_critter.gd`): `bird` (pecks, hops, takes off when the
  party comes near), `flutter` (a butterfly or a bee round where it lives), `hop` (a grasshopper),
  `crawl` (a snail, a spider). A living picture with a `line` or a haul stays still, to be looked at.
- `buildings` — `scale`, footprint `size` and what each picture looks like; seven are copies of
  another, and say so. One may give a `path` to a picture outside `art/buildings/` (a portal as a door).

## `tutorial.json` — Atlas's last stand (D191, once D73's tutorial)

Read by `src/ui/tutorial_guide.gd`. `area` is the village it runs in, `seed` and `lead` the
run it starts (never saved; `lead` is the one who falls). Each step has a `title`, `text`, and what
makes it `done`:

```json
{ "id": "talk", "title": "Talking", "text": "Walk up to Maren…", "done": { "did": "talked:Maren the Guide" } }
```

- `did` — what `EventBus.player_did` says: `walked`, `talked:<name>`, `examined:<name>`, `chest`,
  `door:<name>`, `fight_won`, `fight_lost`. A value ending in `:` or `_` matches anything after it.
- `flag` — a flag set in `GameState` (a reply's `set_flag`, a favour's `<flag>:paid`).
- `opened` — `party` or `journal`, when that screen opens.
- `button` — a button on the card, with that text.
- A step may also carry `on_start` → `set_flag` (a list), set the moment it comes up: the fight
  step calls the village's sparring pair out ([D75](06-decisions.md)).
- The step with `doom: true` is the last ([D191](06-decisions.md)): its `on_start` calls out the
  village's `doomed` band, and when that fight ends, won or lost, `fall` is told on a black screen:
  `lines` one after another and `button` (the way on to the quiz). `fall.killer` is written into
  the record of the fallen as what killed the lead.

`skip` is the card a New Game shows someone who has played it through before (while nobody has
fallen): `title`, `text`, and the buttons `play`, `skip` and `back`.

Every step but the last can be skipped from the card; a replay (the lead already fallen) can be
ended from it too. The area suite checks each step points at someone or something in the village,
and plays the last fight's ending through against a copy of the record of the fallen.

Read by `Database.prop_size` / `Database.building_art`; used by `AreaProp`, `AreaBuilding`,
`AreaMap` (what blocks) and the battle's scenery.

## `areas/*.json` → `interior` — a room, not a yard ([D81](06-decisions.md))

```json
"interior": { "floor": "oak", "wall": "timber",
  "rugs": [ { "rect": [2, 1, 4, 3], "colour": "#7a2e2a", "trim": "#c9a45f" } ],
  "glows": [ { "cell": [3.5, 1], "radius": 4.5, "colour": "#ff9a40", "strength": 0.5 } ] }
```

- An area with this block is drawn by `src/area/interior_painter.gd`, not from tilesets: `floor`
  names `art/interior/floor_<floor>.png`, tiled over the room; `wall` names the back wall's face
  (`wall_<wall>.png`, 64 × 112, standing along the top row) and the top of the side and front walls
  (`cap_<wall>.png`). Cells of `wall` terrain are walls; `floor` terrain is walked on.
- `rugs` — cell rectangles drawn with a border and a row of lozenges; `glows` — soft light over the
  room (a fire, candles), `radius` in cells.
- `floors` — `{ rect, floor }`: a room's own floor over the main one (an inn's kitchen flags,
  [D242](06-decisions.md)). A wall with floor in front of it stands up like the back wall.
- Laid out by `tools/build_interiors.py`, which keeps the room's people, spots and chests and checks
  every one can be reached; `tools/dress_areas.py` leaves these rooms alone.

## `areas/*.json` → `inn` — rooms to let ([D242](06-decisions.md))

```json
"inn": { "price": 1000, "vigour": 4, "yours": 1, "kitchen": [1, 1, 4, 4],
  "bedrooms": [ { "name": "Room one", "rect": [6, 1, 4, 4], "bed": [6, 1] }, { "name": "Room two", ... } ] }
```

- Written by `tools/build_interiors.py` for a room with `inn`: a kitchen and bedrooms behind the
  taproom. The innkeep's night (`inn_room_paid`, set by the conversation: the shared
  `the_innkeeper`, or a `talk` ask with `cost` and `set_flag`) becomes room `yours` of the inn it was
  bought in (`inn_room_at`). Its bed is pinned with a line to it and the compass points there; E by
  it sleeps: everyone patched up, each at least `vigour` extra health as a bed at home gives, a save.
- `lease` (a flag) keeps room `yours` the company's every night while it is set: no night to pay
  for, and it is not let go once slept in ([D252](06-decisions.md): the Flagon's room two,
  `home:room`, and your house in Stormreach, `city_house`, `home:house`). `woke` is said on waking
  instead of the inn's line. Both are the area's own and kept when the tool lays the room out again.

## `world_map.json` — the one world ([D91](06-decisions.md), [D92](06-decisions.md))

Every run is played on this map; a run copies it and never writes back. `size` is `[128, 128]`;
`tiles` is one string a row, each character a symbol from `World.LEGEND`; `sites` is every place,
as a save writes a site (`kind`, `cell`, `display_name`, `rank`, `open`, `data`); `from_seed` is
the seed the lands and the ground inside each tile are drawn from. How to change it, and what the
run's seed still deals, is [27](27-the-world.md).

Sites of kind `wild` (D309) are the wild places worth going to, written by `tools/place_wilds.py`
(twelve, then two cloud peaks and six hamlets, each on its own kind of ground, five tiles clear of any place and twelve of each other,
`data.area` the inside); every other site is left as it is. Each wild area's file carries a `lure`,
what it holds in a host's words. `world_rules.json` → `wilds`: `rumour_chance` at rest in a village or
a keep, `rumour_within` tiles for the nearest unknown, `steps_per_day` for the days said, `rumour_line`
(`{host}`, `{wild}`, `{way}`, `{days}`, `{lure}`) and `found_line` (`{wild}`, `{lure}`). Read by
`src/chronicle/wilds.gd`; a found wild keeps `data.found`. `guard_size`, `guard_reach` and `guard_label`
(`{what}`, `{land}`) are the band of the land's own foes `Wilds.stock` puts by the far chest as a wild opens.
**Hamlets** (D333) are wild sites too, dealt last by the same tool (`hamlet_fold` on grass, `hamlet_mill` on
forest and brush, `hamlet_salt` on sand, two of each, 24 tiles or more from the crater): a few crofts with
folk, one who sells and one with a `job`. A wild area may carry its own `found_line` and `guard_label` (its
trouble, where the guard stands, "{what} at the fold"), and a `map_art` it is drawn with on the map in place
of the standing stone. An area with a `lure` is stocked with its guard whatever its id.
**Caravans** (D334, `caravan_ilse`, `caravan_red`) are wild sites whose `data.caravan` is their round:
`route` (town cells), `leg` (the town it is bound for) and `rest` (upkeeps it still stands). They have no
chest, so no guard and no job to clear them (`Wilds.guarded`). `world_rules.json` → `caravans`:
`tiles_per_upkeep` rolled on an upkeep by the party's way (looked for no further than `longest`), never
within `clear_of_sites` of another place or `party_clear` of the party, nor while the party is that close;
within `stand_off` of the town it stands `rest_upkeeps`, then sets off for the next (`src/chronicle/caravans.gd`).
`errands.json` → `rumours.wild` (`title`, `text`, `posted`; `{place}`, `{lure}`) is the board's job to clear a
wild the party has heard of (D310, `RumourJobs.compose`): an errand of kind `wild` pointed at the wild, paid for
the walk times `rumour_reward_multiplier`, `flag` the guard's done flag (`Wilds.guard_flag`), complete when it is
set, handed back at the board; never one a companion is sent on. `rumours.wild_found` (`title`, `text`, `taken`;
`{place}`, `{lure}`, `{giver}`, `{from}`) is the same job taken on the way into a wild whose guard stands, for the
nearest settlement known, else the nearest at all, marked on the map (`RumourJobs.found_at_the_wild`, D316); `found_here` marks it, and the board's posted flag is
set so it is never posted twice.

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
      "sea_shore": true,
      "foes": ["blood_mosquito", "slime", "seed_beast", "caterpillar_warrior"],
      "effects": { "slow": 0.85 }
    }
  },
  "land_foe_share": 0.7,
  "foe_levels": { "axe_bear": 3, "flame_lion": 3 },
  "hazards": { "stride": 640, "share": 0.04, "floor": 0.5, "cold": { "name": "the cold", "line": "The cold is getting into %s." } }
}
```

- `size` — cells across and down of every generated ground, and of every tile's slot on the land
  ([D84](06-decisions.md)): a place's area (no bigger than it, less two each way) stands in the
  middle of its tile's slot with the land's ground round it, unless it `covers` more tiles than one
  ([D247](06-decisions.md)). `landmark_chance` — the share of
  grounds with something somebody left (a cold camp, a stone ring, a cairn, a cache).
- `ground` — the four area terrains (`tilesets.json` → `terrains`) the land is made of; `layers`,
  the sheets they are drawn with, bottom first. Cover is walkable and blocks a band's sight.
- `props` — art for each kind of thing, sized by `props.json`; `density` — how many per cell;
  `features` — how many of each kind of patch a ground gets, on average.
- `sea_shore` — whether a ground on the coast gets a shore of the land's own water.
- `foes` — unit ids (`units.json`) that camp in the land. A band put down there is made of them
  `land_foe_share` of the time, decided from the cell so the run's dice are not spent; otherwise it
  is the faction that walks the terrain ([D71](06-decisions.md)). `foe_levels` keeps a land's great
  beasts out of the bands it deals until the party's level reaches the number given
  ([D211](06-decisions.md)); a land with nothing else left fields its faction instead.
- `effects` — what the land does on its ground, all optional: `slow` (walking speed, 1 for none),
  `sight` (cells added to how far a band sees; mist and jungle take some away), `fog` (0 to 1, how
  thick the screen fogs towards its edges), `hazard` (`cold`, `heat`, `ooze`).
- `hazards` — every `stride` pixels walked on a land with a hazard, each party member with nothing
  against it loses `share` of their health, never below `floor` of it (half, [D211](06-decisions.md)); `line` is said once a ground.
  Gear or a charm keeps a hazard off when its `proof` names it (`equipment.json`, below).

Which land a tile is: `src/chronicle/biome.gd`. On the land ([D84](06-decisions.md)) each tile is
laid out by `GroundGen.slot` with its sides left open towards walkable country (the paths of two
tiles meet at the same point on their shared edge) and closed only towards the sea or a mountain;
a sea or lake tile is all water and a mountain all rock. What is written down about a cell (a chest
opened, a ward forced) is under `land_<x>_<y>_<land>`, or under the place's own area and cells for
anything in a place, so it is the same chest it always was. A single tile's ground on its own is
still made the old way (`ground_<x>_<y>_<land>`) for anything that asks for one.

## `world_rules.json` → `atlas` → `said_within` (D238)

Walking the ground, a place newly drawn on the map is said to come into sight (`lines.seen`) only
once the party is within this many tiles of it; on the map view it is said at once.

## `world_rules.json` → `play_hud` — the panel on the screen while walking (D244)

`top` (and `top_narrow` on a screen narrower than `narrow_below`) is how far down it sits; `face` and `bar_width` are pixels; a member's health bar turns amber under `hurt_below` of their
health and red under `low_below`; `purse` is the purse's words (`{gold}`) and `tooltip` what
hovering the panel says (`purse` also takes `{draughts}`, what is in the packs to eat or drink).
`most_alerts` alerts are shown under it ([D245](06-decisions.md)); `alerts` has `hurt_below` (the share of
health under which someone is badly hurt) and, for each of `hurt`, `no_draughts`, `held`, `siege`,
`path`, `power` and `treasure`, its `text` and its `detail` on hover; `more` is said when there are
more. Read by `src/ui/play_hud.gd` and `src/ui/alerts.gd`.

## `world_rules.json` → `path_help` — a path in more words (D237)

`roles`: each says `say` of a path whose growth a level is `at_least` / `at_most` the stats it
names and, with `has` (`heal` or `range`), whose starting moves include one; the first `most_roles`
that fit are said. `lines`: `grows` (`{max_hp}`, `{attack}`, `{defense}`, `{speed}`), `starts`,
`move` (`{name}`, `{text}`, one per starting move) and `themes` (`{themes}`). Read by
`SheetParts.class_help` for the **?** on each path card.

## `world_rules.json` → `scars` — what going down leaves behind (D218)

`max_hp` is the health a scar adds for good, `most` the most scars one fighter carries, and `line`
what is said at the fight's end (`{name}`, `{hp}`, `{scars}`). A fighter earns one by going down in a
fight the company wins and living. A character's `scars` is kept in the save.

## `world_rules.json` → `keepers` — a gate keeper's prize (D219)

`prizes` maps a faction id to the equipment id its gate keeper carries. On shutting a gate the prize
comes on `chance[n]`, n being how many of that faction's keepers have fallen since its last prize
(the last entry holds after that; 1.0 makes it certain). `lines.prize` and `lines.missed` are said
with `{keeper}` and `{prize}`. The counts are kept in the save as the world's `keepers`.

## `world_rules.json` → `treasure` — torn treasure maps (D220)

A band beaten on the land carries a scrap on `piece_chance`; `pieces` of them make an X between
`near` and `far` steps of walking off, with `chart_radius` of ground round it drawn in. Standing on
it digs up a find of `richness` (see `loot`) that always holds something to carry. `lines`: `piece`
(`{held}`, `{need}`), `whole` (`{need}`, `{bearing}`, `{region}`), `dug`, and the quest list's `label`
and `detail` (`{region}`). The world keeps `treasure`: `{ pieces, at }`.

## `land_journals.json` — a journal for each land (D239)

`entries` is what a land's page can ask, in order: `{ kind, count, text }`, `kind` one of `walk`
(stretches of the land walked, never more than it has), `landmark` (things somebody left stood at on
its open ground), `bands` (bands beaten on its ground), `place` (its places stood in, only on a land
with one that is not a gate) and `gate` (its gates shut, only on a land with an open one); `text` takes
`{count}` and `{land}`. `trinkets` maps each land id of `biomes.json` to `{ name, text, effects }`;
`effects` may hold `stride` (a share added to walking speed on the land), `wade` (true: shallow pools of
open country can be walked through), `hush` (cells off a band's sight on the land), `attack`, `defense`
(added to every fighter of the party), `health` (a share added to their health in a fight) and `proof`
(hazard ids of `biomes.json` kept off the whole company). Effects of every trinket carried add up, within
`stride_most` and `hush_most`. `lines`: `opened` (`{land}`), `ticked` (`{land}`, `{entry}`, `{done}`,
`{of}`), `finished` (`{land}`, `{trinket}`, `{what}`) and `annal`. The world keeps `lands`: land id ->
`{ needs, got, walked, stood, done }`.

## `arcs.json` — the sixteen's own arcs (D250)

`opens_floor` is the Tower floor the company must have stood on before one of the sixteen walking
with it opens theirs (a lead opens theirs with their chapter one). `arcs` maps a hero id to `{ title,
opened, stages, finished, reward }`. `stages`, in order: `ask` (the journal's line), `until` (`count`
deeds since the stage opened matching any of `deeds`), optional `skip_if` (the same, counted from the
start of the world, checked as the arc opens) with `skipped`, and `done`. `opened`, `skipped`, `done`
and `finished` are variants, `{ when, lines }`, the first whose `when` holds is said: `deed` (a match
against any deed this world), `met`, `with`, `fallen` (hero ids) and `not` (any of those that must not
hold). Each line is `{ speaker, text }`, `speaker` `{owner}` or `{listener}`. A deed match is `{ kind,
told }`, `told` the start of the deed's `told`. `reward`: `marks` (stat key -> amount, added to the
owner for good, kept on the character), `bond` (warmth with the listener), `line` (said last) and
`annal`. All sixteen have one (D256). Besides `deeds`, an `until` or `skip_if` may ask (all of what
it names must hold): `ledger` (tally -> how much it must grow since the stage opened, from nothing for
`skip_if`: any of the run ledger's counters, such as `battles_won`, `battles_lost`, `kills`,
`errands_done` or `recruited`, and `places`, places walked, or `one_kind`, the most of one kind of foe
put down), `floor` (a Tower floor stood on), `flag` (a flag, or a list of which any will do) and
`met_count` (how many of the sixteen met). A `when` may also hold `fallen_count` (at least that many of
the sixteen fallen) and `flag`. The world keeps `arcs`: hero id -> `{ stage, since, at, done }`, `at`
the tallies when the stage opened. Read by `src/chronicle/arcs.gd`.

## `world_rules.json` → `renown` — deeds, and the world remembering them (D249)

Every deed worth telling is written down where it happened (the world's `deeds`: `{ kind, cell,
step, weight, line }`, with `told` and `place` when it can be brought up), and word of it walks out a
tile every `steps_per_tile` steps. Standing at a place adds up the weights heard there: `known_at`
of them makes you known, `renowned_at` renowned, `feared_at` below nothing feared; prices swing
`price_swing` a point within `price_cap`. `gate_shut`, `town_saved`, `town_raided` and
`tower_topped` are the weights of those deeds.

`remembered` is what people do with it ([D249](06-decisions.md), `src/chronicle/remembered.gd`):
`kinds` holds the lines a deed is brought up with, by kind, `warm` (weight 0 or more) and `cold`,
plus `told` (the deed as said to the doer, with `{place}`); a deed of no kind of its own that was
written down with `told` uses `kinds.told`'s lines (`{told}`). Anyone with a `talk` block says the
newest one heard at the place before their hello, once each; a townsperson who only chats takes one
into their chatter on `aside_chance`. At standing `cold_at` or below, anyone with a `talk` block and
no refusal of their own refuses with `cold` (a `refuse` block: `chance`, `bribe`, `bribe_q` with
`%d`, `check`, `text`, `won`, `still_no`, `leave`). A faction whose own bands are beaten `grudge_at`
times (`no_grudge` never) holds a grudge: `grudge_line` (`{faction}`, `{count}`) is said once, and
its bands see `grudge_sight` cells further and shout one of `grudge_shouts`. A world that ends keeps
`dream_most` of its lead's deeds in its echo (`deeds`: `{ cell, told, weight }`); in a later world,
somebody within `dream_reach` tiles of one says one of `dreamt` (`{name}`, `{told}`) once. The world
keeps `grudges`: faction id -> bands beaten.

## `world_rules.json` → `life` — the land's small life and the road's Watch (D179)

`per_tile` is how many birds, flutterers, hoppers and crawlers a tile of open country gets on
average, times its land's `life` in `biomes.json` (1 when absent), half in a place; `art` the
pictures each is drawn from, unless the land's own `life_art` in `biomes.json` names them for that kind
(D336: none where it names none, so no grasshopper in the ash). A bird takes off when the party comes within `shy_cells`, flies
`flee_cells` [min, max] cells in `flight_seconds` up to `flight_height` pixels, and one with nowhere
to land is gone `away_seconds`. A bird that has stood a while goes up on a loop of its own on
`wander_flight` of its rests, `wander_cells` [min, max] cells, and comes down where it can stand
([D189](06-decisions.md)). `road_watch`: on that `chance` of the First Hour's road tiles, two of
the city's Watch (`units`, called `name`) walk the road there end to end and back, staying `stay`
[min, max] seconds and saying one of `lines` at each end; `talk` is their conversation (a `talk`
block, above). `climbers` ([D215](06-decisions.md)): on `road_chance` of the road's tiles the Watch
is not walking, a company of `size` [min, max] (bodies from `units`, named one of `companies`)
walks the road there and back, the first of them saying one of `lines` at each end, and talks
(`talk`); `on_the_floors`, from floor `from` at `chance`, a company rests by a Tower floor's stair
and talks. A company within `join_cells` of a fight joins it ([D246](06-decisions.md)); with
`on_the_floors.join_anywhere` one resting on a floor joins a fight anywhere on that floor
([D259](06-decisions.md)). How each company talks ([D341](06-decisions.md), `src/chronicle/company_talk.gd`):
`voices` has one entry per company with its `hello` (on the road), `floor_hello` (resting on a floor),
`shared_hello` (climbing a shared floor), its answers to the three questions anyone asks (`who`, `up` on
the road, `up_here` on a floor, `advice`), `own` (two `{ q, a }` only it is asked) and `bye` / `floor_bye`;
the party words the three from `wording` and takes its leave with one of `leave`; `place_asks` of `asks.road`,
`asks.floor` or `asks.shared` (each `{ q, a }`, a floor's kept to `from`..`to`) come up too, drawn the same
way each time the company is met in the same place. `{floor}` and `{next}` are the floor and the one above. A
company without a voice talks as `talk` (road) or `on_the_floors.talk`. Read by `src/area/area_critter.gd`
and `src/area/area_scene.gd`.

## `world_rules.json` → `first_hour` — the cut list (D97)

`hidden` names the systems that are built but out of reach until the First Hour is done
([D95](06-decisions.md)). `src/chronicle/first_hour.gd` (`FirstHour.hides(name)`) is the only reader.
Names: `coliseum`, `training`, `museum`, `trivia`, `grimoires`, `ferries`, `captivity`,
`seasons`, `beds` (no bed to buy in the crater, [D178](06-decisions.md)). Take a name out to
bring its system back. `dispatch` came out with [D278](06-decisions.md): sending your own people away opens
once the company has shut a gate; `nemesis` with [D330](06-decisions.md).

## `world_rules.json` → `nemesis` — survivors who come back, and thanks (D330)

`survive_chance` that a broken band leaves a survivor (never one of `non_sentient`), named from
`epithets`, said with `escaped_line` (`{name}`); `return_chance` that one leads a band met on the road,
`level_per_return` levels up for each time they have come back, saying `confront_lines` in turn (`{name}`,
`{place}`); beaten again, `finished_line`. `thanks`: on `chance` a settled errand's giver remembers it
(`world.thankful`); on `meet_share` a traveller on the road's clock is one of them, giving `gift_share` of
the errand's pay and saying `lines` (`{giver}`, `{title}`, `{place}`, `{gift}`). Read by `src/chronicle/nemesis.gd`.

## `world_rules.json` → `caves` — the caves under the hills (D282)

A walkable tile whose terrain is one of `terrains` has a cave mouth on `chance` (a hash of the world and
the tile, so the same tiles every time). The mouth is a building (`art`, `name`) put into the tile's
ground by `GroundGen.slot`, carrying `cave: [x, y]`; walked into, `src/chronicle/caves.gd` lays the cave out
as one gate floor (`GateInside.layout`) of a rank from `ranks`, with the stair walled off, its bands
keyed `done:cave_<x>_<y>_...` and `lost` said on a loss, and one cache by the deepest band of
`gold_low` to `gold_high` copper and one of `finds`.

## `world_rules.json` → `experience` → `levels_only_in_gates` — levels come from gates (D301)

With `levels_only_in_gates` true, a kind of foe teaches (`Character.beaten`, the levels of
[D113](06-decisions.md)) only when it falls in a fight that `teaches`: a gate's floors (`GateInside.layout`
sets `teaches`, and so does a gate met on the world map), a cave (it is laid out as a gate floor), or an
area marked `teaches` in `data/areas/`. A fight on the land, on the Tower's floors or on the road
(`Dispatch`) still gives experience and practice, but a kind first met there goes into the character's
`met` (kind -> times seen fall) and is not learned; it still teaches the first time it falls in a gate.
`first_hour` → `auto_hunt_gates_over`: a party walking itself makes for the easiest open gate instead of
the Tower while the next floor's foes stand more than that many levels over the company
(`AutoRoad.stair_too_hard`). Each character saves `met`, `look_for` (kinds marked "look out for" on the
log of foes, called out when one stands in a gate the party walks into) and `climbed` (the highest
Tower floor won with the company).

## `world_rules.json` → `crafting` — mixing, honing and enchanting (D280, D327)

`mix` is the recipes the party screen offers from the packs: `{ makes, needs: { item: count } }`
(`mixed_line` says it). A smith's `talk.hone` (`q`, `offer`, `done`, `none`) puts a notch on a weapon
somebody carries: +1 attack for that person with that weapon (`Character.honed`), up to `hone_most`, at
(`hone_base` + the weapon's price × `hone_share`) × the notch through the `price` dial
(`src/chronicle/crafting.gd`). A person with `hone` keeps a post and cannot be recruited.

`enchant` (D327) is the runes the party screen offers for the weapon a person carries, out of the packs:
`{ id, display_name, description, effect, value, needs: { item: count } }`. `effect` and `value` are a fight
passive's (`data/skirmish.json` → `passives`): theirs while they carry that weapon, over and above
`max_passives` (`Character.enchanted`: weapon id → rune id, one a weapon). `enchanted_line` says it, and
`replaced_line` when a new rune takes an old one's place.

A recipe may say where it is made (D346): `at: "hearth"` is offered on the party screen only while
`GameState.at_hearth` (the lead within `hearth_reach` cells of a fire on the ground, or in an area with
`hearth: true`, an inn or a tavern), said by `brewed_line`; `at: "smithy"` is forged by a smith whose talk
has `forge` (`q`, `offer`, `none`, `done`, `done_q`), for its `fee` through the price dial, said by
`forged_line` (`forge_short_line` when the makings went before it was paid). What a recipe or a rune needs
counts the packs and any of the company's charms (a rune's makings bought from a trader are pocketed as
charms), and is spent from the packs first.

## `world_rules.json` → `makings_on_land` — what a smith forges with (D346)

Laid as `herbs_on_land` is, by a roll of its own: about `per_tile` a tile of a land named in `by_land`;
`looks` gives each its `art`, `art_wanted` (drawn in its place once that picture exists, A62), `name`,
`line` and `spent_line`. The items (`ash_stave`, `iron_ore`) are `kind: "making"` in `equipment.json`:
picked up, they go in the packs.

## `world_rules.json` → `herbs_on_land` — what the land grows wild (D335)

About `per_tile` patches a tile of open land (none round a place), each one of what its land grows
(`by_land`: land id → item ids; a land not named grows none), off the paths, the water and anything
standing. `herbs` gives each item its `art`, `name`, `line` (said as it is picked) and `spent_line`.
Laid by their own roll in `GroundGen._herbs`, so nothing else on the ground moves; a patch is a prop with
an `item`, picked once a run into the packs.

## `world_rules.json` → `moods` — how each of the company feels (D279)

`base` plus every thought carried is a mood (`Character.mood()`). `thoughts` are keyed by id: `label`
(`label_against` when it is worth less than nothing), `mood`, `lasts` (steps), `stack` (how many at once),
and `by_group` (worth by temper group NT, NF, SJ, SP). `src/chronicle/moods.gd` gives them once a step
from what changed: `won_fight`, `lost_fight`, `shut_gate`, `climbed`, `friend_fell` (a bond of
`friend_bond` or more; `{name}` is the fallen), and since D347 `saw_fall` (one who was not a friend),
`parted` (a friend let go; `{name}` is them), `with_friend` (a friend in the party, every
step), `rested` (`Moods.rested`, at a rest point), `looked_after` (a healer's mend) and `kitted` (an edge or
a rune on their weapon). `bands` (by `below`) name the mood and add to `attack` and
`defense`; under `break_below`, on `break_chance` a step, one walks off for `break_steps` (`break_line`).
The band's name shows on each party card. `Moods.feeling` is `low` (the two lowest bands) or `glad` (the
two highest) or nothing: an exchange or a reflection in `banter.json` with `"feeling"` is only spoken by one
who feels that way, and one with no `feeling` by anyone.

## `world_rules.json` → `quick_wheel` — the ring on a held middle button (D326)

`on`; `hold`, the seconds the middle button is held still before the ring opens round the pointer (a
press that moves first is the camera's drag); `walking`, the choices on the land, and `fighting`, while a
fight is on, each `{ "id", "label" }`. Ids: `eat` (on the land the worst hurt eats the least food that
mends them, a draught when there is no food; in a fight the picked fighter, or the worst hurt, takes the
least in the pouch, food first), `party`, `send` (the party screen's mission page on the first who could
go), `formation` (the next shape), `map`, `journal`, `auto`, and in a fight `stance` (the picked fighters'
next). A choice is said on `EventBus.quick_wheel_chose` (`src/ui/quick_wheel.gd`).

## `world_rules.json` → `dispatch` — sending your own people out (D38, D278)

`steps_per_tile` and `hunt_distance` time an errand; `trouble_*`, `win_base`, `win_per_level` and
`danger_levels` settle a meeting on the road. A band sent to shut a gate spends `steps_per_floor` a floor
inside and shuts it on `gate_win_base` + `gate_per_level` × (the band's average level − the gate's
expected level) + `gate_per_hand` for each member past the first, kept between `gate_min` and `gate_max`
(`src/chronicle/dispatch.gd`). A band sent to clear a wild place (D348: heard of, its guard standing; a job
in `GameState.away` with `wild` and `guard_level`, the company's level when the first set off) spends
`steps_in_wild` steps there and wins on `wild_win_base` + `gate_per_level` × (its average level −
`guard_level`) + `gate_per_hand` a member past the first, in the same bounds: the guard's done flag set, every
chest's flag set and its haul claimed, and a `wild` errand for it complete.

Sent with a place to meet ([D300](06-decisions.md): a village, keep or the house the company knows,
`Dispatch.meeting_places`), a job carries `meet` and `meet_name`, and walks there from where it was done,
a tile a step. `Dispatch.reading` is how far a job is from the company and the steps until it is back
(D326), said under the party's cards and beside its face on the map. Back there with the company elsewhere it says `crow_line` (`{names}`, `{place}`, and `{are}` / `{wait}` for one or many) and waits,
`waiting`, until the company stands on that tile. `Dispatch.where_now` is where a job is on the land, for
the map.

`guild_mark` (true) starts every run with the Tower's stair sealed until a gate is shut, and
`mark_line` is what the doorkeeper says meanwhile ([D101](06-decisions.md); `FirstHour.wants_guild_mark()`,
`FirstHour.mark_line()`, read by `Chapters.seal_line`).

`first_life` (`atlas`) is the lead New Game would start as while no world has ended
([D106](06-decisions.md), `FirstHour.first_life()`); since [D191](06-decisions.md) a New Game with
nobody fallen is Atlas's last stand instead, and the quiz picks the lead after his fall.

`warden` is what the floor 5 keeper says as its fight begins ([D184](06-decisions.md)): `band` (the
keeper's band key, `tower5_keeper`), `speaker` (the name in the box), `ordinals` (the words for first
to sixteenth), `first_line` (the first life's), `line` (every later life's) and `last_line` (the
sixteenth's); `{ordinal}` is the word and `{name}` the lead. Which challenger a lead is comes from the
leads already fallen (`Sixteen.fallen_heroes`, kept outside the save, [D47](06-decisions.md)); read by
`FirstHour.warden_line`, shown by `area_scene._fight_held`. `tenth_keeper` is the same for the Keeper of
the Tenth on floor 10 (`tower10_keeper`, [D254](06-decisions.md)).

## `world_rules.json` → `difficulty` — settings (D104)

`setting` is the one a new player gets, `first_hour`; `settings` holds each by key with its
`display_name`, `blurb` and dials (`enemy_level`, `enemy_count`, `enemy_attack`, `enemy_hp`,
`party_hp`, `party_attack`, `move_bonus`, `encounter_chance`, `grace`, `permadeath`,
`post_battle_heal`, `xp`, `gold`, `price`), read by `src/chronicle/difficulty.gd`. In order of
mercy: `gentle` (shown as Story, no permadeath), `first_hour`, `even` (the game as written),
`hard` (Unkind); `breeze` is for testing. The difficulty button cycles them in that order.

## `world_rules.json` → `gate.reading` — readings and double gates (D293, D302)

Read by `Site.reading()`, `Site.misread()`, `Site.is_double()` and `Site.gone_into()` in
`src/chronicle/site.gd`. From `wrong_from` up, one gate in `wrong_one_in` reads a rank lower than it is
until gone into (`misread_line`: `{gate}`, `{read}`, `{rank}`; the gate's `data.seen_true` then holds).
`double_base` in a hundred, plus `double_per_fallen` for each world ended before this one
(`world.echoes.sibling`), are double: decided the first time in (`data.double`), a double gate climbs one
rank (`double_line`: `{gate}`, `{was}`, `{rank}`; `data.sprung`) and its way out says `sealed_line` until
it is shut. Both are fixed by the gate's cell, not the world's dice.

## Heights on an area — `tilesets.json` → `terrains.<id>.height`, an area's `ways_up` and `ladders`, `world_rules.json` → `heights` (D287, D308, D321, D337)

Read by `AreaMap` (`has_heights`, `height_at`, `may_step`, `drop`), the area scene (`_can_step` inside
`_slide`, `_fall`, `_say_the_shelf`, a formation slot) and `src/area/area_ledges.gd`. A terrain with
`height` (the shelves' `raised` is 1) stands that many heights up; an area whose legend uses one has
heights. `ways_up` in the area's file is the cells where higher ground can be stepped onto, or off, from
a height below (the author draws a slope prop, `landmark/slope`, on each); everywhere else a step up is
refused and a step down is free (`may_step`), two or more up never. `heights`: `hurt_from` heights of drop
before it hurts, `share` of everyone's health for each height past the first, `floor` the share nobody
falls below, `hurt_line` (`{fell}`) and `blocked_line` (said once a cell when the lead walks into a shelf
with no way up). The ledges node draws a rim on the top of every drop and a shadow on the ground below.
On ground with heights `find_cell_path` (a click, Auto, a band, a person at work) finds its way with `_height_path`
(D312): the shortest by cells stepping only where `may_step` allows, a drop of `hurt_from` or more counted as
`path_drop_cost` (6) cells more; a click on open ground with no way to it says `no_way_line` once a cell.
`shoved_off` (D313): `share` of a body's health for every height it is shoved off, `down_seconds` it lies
knocked down, `word` over it and `line` (`{who}`, `{fell}`) in the fight's log; `BattleGrid.may_step` and
`may_shove` rule a ledged field.
`siblings.weapon.crater_art` in `fall.json` (D344): the picture of the scorched ground laid in the middle of the
land tile a fallen weapon came down on, until it is found (none stands until the picture is in, A54).
`held` in `skirmish.json` (D344): by weapon `kind`, the `sprite_dir` of eight facings, `scale` and `offsets` a
fighter's weapon is drawn with when its piece in `equipment.json` has no `sprite_dir` of its own; a kind whose
folder has no `south.png` yet draws nothing in hand.
`data/art_slots.json` (D344): the art still to be made (docs/24 from A51): for each request its `files`
(`name` dropped, `to` under art/, `size` [w, h], `rotations` for a folder of facings, `each` to repeat one for a
list, `prop: false` for a picture under art/props not laid as a prop, `stand_in`) and `shows`. Read by
`tools/take_art.py` and `tests/art_smoke_test`, never by the game.
`from_above` (D343): on a ledged field a fighter higher than the one they hit lands `blow` more for every
height up at arm's length and `shot` more a height for anything reaching further, counted to `most_heights`
(`Skirmish.high_ground`; the log tags it *From above*). `on_the_map` (D343): the map of the continent draws a
cell `per_height` lighter for every height of its terrain and `slope` lighter a height the ground climbs to
the south-east (darker where it falls), held to `most`, and from `peaks_from_px` pixels a cell one peak a
height, up to `peaks_most` (`LandMap.relief`).
A terrain with `clouds: true` (`cloud`, D321) is the drop round a mountain's top: never walked
(`AreaMap.is_cloud`, `has_clouds`), drawn by `src/area/area_clouds.gd`, and said once a cell as
`cloud_line` when the lead walks at it. A fight laid over it writes `clouds` (cells) into the field, and a
body shoved into one goes over (`into_clouds`: `word` and `line`, `{who}`). The cloud peak's `high` (2) and
`summit` (3) stand on the stone and snow sheets.
`ladders` (D337) in an area's file are cells with a ladder against the face below (the author draws
`landmark/ladder` on each, in house by `tools/draw_ladder.py` until A57): climbed up as far as
`heights.ladder_most` (2), and taken onto the land with the place, like its `ways_up`. A company carrying
`heights.rope_item` (the Climbing Rope, a charm; in the packs or worn) may step up any face one height
(`AreaMap.scaling`, set as an area opens and again, with `rope_line`, the first time the lead walks at a
face after getting one); a way found reads it too. Fights keep to slopes and ladders.

## `world_rules.json` → `heights.land` — rises on the land (D332)

Every generated ground (`GroundGen._lay_out`) gets `rises` lumps of higher ground on average, a land's
`features.rises` in `biomes.json` winning, plus `on_terrain[<world terrain>]` more. Each is laid as the
`^` symbol, cell `terrain` (`rise`: walkable, `height` 1, in `tilesets.json` `terrains`), by its own roll
so nothing else moves; it keeps `margin` cells off the tile's edges and one cell off paths and water, and
a tile with any gets the `sheet` overlay (`tools/draw_rises.py`) under its ways. Every piece of higher
ground gets a way up (`GroundGen._slopes`): an edge cell with open ground in front, the south side first,
a second from `second_slope_from` cells, `slope_art` drawn on it; the slot's `ways_up` lists them and
`Land.hold` puts them on the land, where ways are found on `Land._held_steps` (one-way off a rise).

## `world_rules.json` → `tower.grown` — the floors past 10 (D290, D307)

Read by `src/chronicle/tower_floors.gd` (`is_grown`, `ensure_grown`, `layout`, `company_with_you`,
`floor_line`) and `Chapters.walked_floor_area`, which returns `area` (with the floor number) for any floor
from `from` up, so the stair below knows the floor's id before `ensure_grown` registers it
(`Database.register_area`) as the stair is climbed (`world_scene._climb`). A floor is `width` by `height`
at floor 10, growing `width_per_floor` and `height_per_floor` a floor (rounded) to `widest` and `tallest`,
with `chambers` chambers, one more every `chambers_every` floors to `most_chambers`; the way in is at the
bottom (`spawn`, `exits`), the stair at the top (`stairs`), the chambers joined by three-wide ways with a
runner down the middle; the legend is the Tower's slab, runner and wall, `tint` and `hint` its own. Every
chamber but the first holds a band keyed `tower<floor>_<letter>` with `band_pack` as a stand-in that
`TowerFloors.restock` replaces with the floor's foes (the same as a borrowed plan's, so `borrows_a_plan` is
true of a grown floor); `props` carry the stair's two halves, four runes and two lamps. A floor is shared
(`is_shared`) from `shared_from` every `shared_every` floors unless it is lived on: `company_with_you`
gives `shared_size` of `life.climbers.units` at the party's level, named by `company_on` from
`life.climbers.companies`, handed to the area scene as `allies`, who fight every fight on the floor beside
the party; `shared_line` (`{company}`) is said on the way up, and two of the company wait by the way in to
talk in its voice (`life.climbers.voices`, [D341](06-decisions.md)). A floor is lived on (`is_living`) from
`living_from` every `living_every` floors: `living_size` people by the way in, `living_talk` their words
(those past the host and the trader also asked `pool_shown` of its `pool`, the same each time),
`living_line` said on the way up. `living_host` and `living_trader` (D317) are the first two's words and
`name`: the host's `heal` rests the whole company for its `price` (Talk's mend), the trader's `sells` are
restocked wares priced by `TowerFloors` at the Market's price times `markup`.

## `world_rules.json` → `gate.fallen` — demon kings of fallen worlds (D293, D304)

Read by `Site.demon_king()`, `Site.demon_words()`, `Encounter.for_gate()`, `GateInside._bands()` and
`Spoils.for_gate()`. In a world with a record of the fallen (`world.echoes.past`), a gate of rank `from`
or above is held by a fallen lead's demon king when its cell hashes under `base` plus `per_fallen` for
each of the fallen (in a hundred); which of the fallen, by the same hash. Kept on the gate as
`data.demon` (the hero id, or `""`) the first time it is gone into, with `data.demon_seen`. The keeper is
that hero's own unit at the floor's keeper level plus `levels`, never under the level the echo fell at,
`stout_times` as stout as the rank's keeper; every band in the gate stands `band_levels` higher. Lines
`line` (going in), `title` (the keeper's), `label` (the map and the fight: `{name}` only) and `shut_line`
take `{name}`, `{demon}`, `{gate}`, `{they}`, `{their}`, `{them}` and each capitalised, from the hero's
`pronoun` in `heroes.json`.

## `world_rules.json` → `gate.instant` — the Gate Key tears a gate (D293, D304)

Read by `Spoils.gate_key()`, `Site.key_rank()`, `Site.tear()` and the world scene's `_tear_gate_here`.
`key` is the key's id in `GameState.keys`; `Spoils.gate_key` adds it as a gate is shut (always with
`from_double` on a double gate, else one gate in `found_one_in` of rank `found_from` or above, hashed from
the gate's cell), never while one is held, and keeps the gate's rank in `GameState.flags["gate_key:rank"]`
(`found_line`, `{rank}`, `{gate}`). With it in hand, the interact key on open ground (the hint says
`prompt`, `{rank}`) calls `Site.tear`: a `Site` of kind gate, `open`, `opened_at` the world's step, held by
one of `Faction.seated_at("gate")`, named from `names` in turn (then "the Tear N"), with `data`
`{ area: "gate", faction, instant: true, torn_at, seen_true: true, double: false }`, appended to
`world.sites` on the company's cell or the nearest open one within two; `torn_line` (`{gate}`, `{rank}`)
is said and the key is erased when `spent`. It saves and loads with the other sites.

## `world_rules.json` → `ground_watch` — bands met on the ground (D66, D68, D72)

Read by `src/area/area_watch.gd` (the band on the ground) and the ground's fight hand-off in
`src/area/area_scene.gd`.

- **Sight:** `sight_base + sight_per_reach × reach` ground cells round the band (its world reach,
  usually 2, so 5). Trees, houses and rock block the line; `water` and every land's `*_liquid` do
  not. Ground that is cover (`"cover": true` on its terrain in `tilesets.json`, or named in `cover`)
  and walk-through bushes are never seen; the cells the band's own figures stand on always are.
- **Where it stands:** on its own tile, in the open at least `keep_away` cells beyond its sight from
  where the party came in; watching from the next tile, just inside that edge. On the land
  ([D84](06-decisions.md)) every band within two tiles stands in its own tile's slot, and keeps to it.
- **Patrol:** `patrol_points` stops within `patrol_reach` cells, walked a cell every
  `patrol_step_seconds`, resting `patrol_pause` [min, max] seconds at each; a loop that never brings
  where the party came in into sight. The red moves with it. On the land, `land_patrol_points`
  stops within `land_patrol_reach` cells; moved to the next tile by the continent, the band walks
  there across the land a cell every `travel_step_seconds` and patrols round its new spot.
- **Seen:** a step into the red, or the band walking into view of the party. `spotted_seconds` of
  heads turning, the band rushing `charge_share` of the way in `charge_seconds` (both 0 since
  [D204](06-decisions.md): the fight is on as they shout, and they close in fighting), then the fight
  on a field `field_margin` cells round everyone, `field_smallest` to `field_largest`. Fought on the
  ground, the field has no edge drawn and nothing round it dimmed; its edge shows faintly only while
  the pointer is out past it, where a right-click sends whoever is picked to get clear. The field carries
  `view` (the ground camera's `centre` in ground pixels and its `zoom`): the fight opens on it and
  draws back over `pull_back_seconds`. Out of cover into the red sets `ambush`.
- **A first strike** ([D300](06-decisions.md)): out of the band's sight with one of its figures within
  `first_strike_reach` cells, G winds the lead up for `first_strike_seconds` and `first_strike_hint` is said
  on the bottom line; then the band is met as an ambush with `first_strike` on its encounter, and the
  fight lands the lead's blow first (`skirmish.json` → `first_strike`). Seen while winding up, it is lost.

An area may hold **bands of its own** (`bands` in its JSON, [D75](06-decisions.md)), in the same shape
plus `at` (the cell it would rather stand on: it only has to not be looking at the party already),
`level`, `requires` / `requires_not` (flags: it comes out when they allow, looked at twice a second)
and `done_flag` (set when it is fought). One with `"spar": true` is practice: it is fought straight
from the area as a sandbox fight on that ground (nobody can die, nothing counted) and back to the
same spot, never through the world. The tutorial's sparring pair is one, and so is the band out of
the broken gate at the end of Atlas's last stand, marked `"doomed": true` ([D191](06-decisions.md)):
how that fight ends is the tutorial's to settle, not the fight's. One with `"held": true` is
fought for real on that ground ([D102](06-decisions.md)): the continent settles it like any fight,
`done_flag` is set only if it is won, and lost or got clear of sends the party back out (`lost` is
the line said); `boss` makes its first unit a keeper. The Tower's walked floors hold these, and a
`stairs` list of cells: on an area opened with `tower_floor` in its payload, standing on one wins
that floor. `world_rules.json` → `tower.walked_floors` (5) and `walked_area` (`tower_floor_%d`)
say which floors have ground of their own (10 since the Second Hour, [D254](06-decisions.md); floor 10's
keeper is the Keeper of the Tenth). From `own_bands_from` (6) up, a floor with ground of its own has its
bands restocked the same way as a borrowed one's below, all but its keeper, which keeps its shape at two
levels over the floor's foes at least. Every floor above is walked too ([D207](06-decisions.md)), on
one of their plans in turn (`borrowed_plans`, [1, 2, 3, 4]: floor 5's is left out for its Warden),
its bands restocked by `src/chronicle/tower_floors.gd` with keys and flags of their own
(`tower<floor>_a`, `done:tower<floor>_a`) and never fewer foes than the plan's band had; no
keepsake lies on a borrowed floor, and on the top floor the plan's first band is the Spire Apex's
keeper, standing four cells before the stair, and the rest stand down. Each band is the floor's foes
as a fought floor would have them: their level is
`level_base` + `levels_per_floor` × the floor (4 + 0.4 ×, so floor 6 is level 6 and floor 20 level 12),
never below the party's average level when `meet_the_party` is true, and there are `foes_min` of
them, one more every `chapters_per_extra_foe` chapters, and one more for every member past
`foes_per_member_past` (2), at most `foes_max` (6) ([D189](06-decisions.md)).

A gate's floors are walked the same way ([D248](06-decisions.md)): E at a gate on the ground opens the
floor the party is on, laid out by `src/chronicle/gate_inside.gd` and registered as an area
(`gate_inside_<x>_<y>_<depth>`; an area opened with `gate_cell`, `gate_depth`, `gate_final`, `gate_keeper`
and `allies` in its payload is a gate's floor). `world_rules.json` → `gate.inside` says how: `width` +
`width_per_rank` × the rank's place (E 0 to S 5) wide and `height` + `height_per_rank` high, `chambers` +
`chambers_per_rank` chambers joined by passages from the doorway (the bottom row, its `exits`) to the way
down (its `stairs`, the top row), a held band of the gate's own seeing `band_reach` in every chamber but
the first (`Encounter.for_gate` deals each), and on the last floor its keeper (`boss`, one more reach) in
the last chamber, whose `done_flag` the way down waits on; on every other floor, with `rout`, the way
down waits on every band of the floor (`rout_line` says so), and the keeper's fall scatters whatever is
left (`scatter_line`) ([D261](06-decisions.md)). A chamber of rank `from_rank_two_bands` or above holds a
second band when it rolls under `two_band_chance`; the keeper is `keeper_stout` (one a rank, E to S) times
as hard to put down (`stout` on its band and its fight's foe, its health times it). `grounds` are the
kinds of ground a floor is laid in (`floor`, `path`, `wall` and `cover` terrains, the ground sheets drawn
bottom first as `layers`, `open` to widen chambers and passages, `name`; a kind with `biome` takes that
land's `_floor`, `_bare`, `_liquid` and `_cover` and its three sheets unless it names its own); the first
floor is the kind `by_area` names for the gate's mouth, else `by_land` for the land under it, and a deeper
floor of a gate of rank `from_rank_vary` or above is another kind, rolled from the gate and the floor.
`hint` is the floor's hint line. Bands' keys carry the site's `delves`, counted up each time a
delve is lost, so a lost delve's bands stand again. The way down settles as a gate floor did
(`kind` `gate`, `walked`) and opens the next floor straight away; a band's fight there settles as
`gate_band`, and lost, the delve is lost.

A shut gate's mouth ([D261](06-decisions.md)): `gate.shut` → `art` replaces the landmark in the gate's own
area where it stood (the gate lying broken), its `people` are put in the mouth as an area's are, and
`cheer` is said as the gate shuts (`src/area/ground_gen.gd`, `world_scene.gd`).

An area's doings that start a fight are fought on that ground too ([D207](06-decisions.md),
`GROUND_FIGHT_ACTS` in `area_scene.gd`): a gate at its doorway off the ground ([D162](06-decisions.md); on the ground it is gone into, [D248](06-decisions.md)), a roadside
fight with its attackers where the scene stages them (`stage` in `roadside.json`; a stage's
`allies`, such as the Watch beset by a town, [D215](06-decisions.md), stand in the middle of it and
fight beside the party), and a town
defended or raided or a captive taken back by force with the other side a few strides ahead.

**Bands by the road and the Watch beset** ([D215](06-decisions.md)). `encounters.json` →
`near_the_road`: `bands` more always camp `from` to `to` tiles off the First Hour's road, never on it
and at least `clear_of_places` tiles from any place, topped up with the rest of the land's bands
(`bands`, by the danger rating); `people_share` of them are two or three of `people`, the rest
whatever lives there. `roadside.json`: a scene with `near_town` is offered only within the rules'
`town_reach` tiles of a standing town, at `near_town_chance` a step, the rest only in open country at
`chance`; no scene is ever within `clear_of_sites` of a place. `purse_line` is how a scene's purse is
said (`%s` the money, in coins). A scene is stood `stage_cells` ahead and told in the log within `tell_cells`,
with no box and without stopping a party walking itself ([D216](06-decisions.md)).

**The road's clock** ([D286](06-decisions.md)). `roadside.json` → `rules.clock`: `first_after` steps into a
new world, then every `every` steps (a `[min, max]` span read off the seed), one of `kinds` by weight is
put on the road, never the same kind twice running and never within `clear_of_sites` of a place or
while walking somebody home: `band` (a band stood `band_ahead` steps on, the way the party walks, waiting
on the road itself on the ground (`waylays` on the band), said with a line from `band_lines`), `scene` (one of the `events`, called up without `rest_steps` or `chance`;
a traveller instead where none can stand), `traveller` (one of `travellers`: `who`, then `lines`, with
`{town}`, `{gate}` and `{gate_way}` filled in; one naming a gate puts it on the map) and `find` (a haul as
rich as `finds.richness`, said with one of `finds.lines`). A scene the dice bring restarts the clock.

**Five tiers of each monster** ([D262](06-decisions.md)). `encounters.json` → `tiers`: `families`
names each family's kinds, lesser to top (`lesser`, plain, high, hob, then a list for the top, a
chieftain or a caster); a pool or band naming the plain kind deals it as one of the five, at the odds
of the last `by_level` row whose `from` is at or under the fight's level (`weights`, lesser to top), and
no more than `top_a_fight` come out at the top. A tier with no passives or role of its own in
`skirmish.json` (`by_template`, `role_by_template`) fights with its family's. A keeper is not dealt; a band on the land is dealt when
it is put down, so it is seen as what it is (`Tiers`).

**A band led to the Watch** ([D236](06-decisions.md)). `world_rules.json` → `life.road_watch`: a band
that sets on the party within `join_cells` of the Watch walking the road brings them into the fight
on the party's side, at the company's level, with `joined_line` in the log; won, `thanks` are said and
`purse_base` + `purse_per_level` × the company's level copper paid (`purse_line`, `%s` the money, in coins), and
`renown` written where it happened.

**`world_rules.json` → `auto_styles`** ([D216](06-decisions.md)): `names` and `blurbs` of the three
ways a party walks itself (`aggressive`, `mixed`, `passive`; `Pace.auto_style`, kept in
`settings.cfg` → `ui` → `auto_style`), shown in the menu and on the top bar's Auto button.

## `memories.json` — chapter memories (D103)

Keyed by lead (`atlas`), a list of memories in chapter order: `id`, `chapter`, `title`, `object` (what
it is), `area` and `cell` (where it lies), `art` (the prop drawn there), `scene` (lines, each
`{ speaker, text }`, played when it is picked up) and `journal` (the line written under _What has
come back_). Read by `src/chronicle/memories.gd`; found ones are the run's `memory:<id>` flags. Chapter
one lies on floor 5 for every lead; chapter two (`<lead>_2`) on one of floors 6 to 10 ([D254](06-decisions.md)),
written from the drafts by `tools/chapter_twos.py`, with where it lies taken from `tools/build_tower_floors.py`.

## `crossings.json` — gates as crossings between the worlds (D152)

`chance` by gate rank (`E` to `S`) that a gate opens onto another lead's world as it shuts;
`first_certain` makes the first gate of the player's first life always open; `weight` by a lead's
`found_at` in `heroes.json` (`gate`: 3). `living` and `ended` are the scenes (lines `{ speaker, text }`
with `{gate}`, `{name}`, `{lead}` and `{says}` filled in), `journal` the line written for each, and
`says` each lead's line through the gate. Read by `src/chronicle/crossing.gd`; who was met is the
run's `crossed:<lead>` flag (`crossed:any` once any).

`carried` is a word carried between lives (D183): `left` is each lead's line said into a gate as it
shuts; `voice` the lines played when a later lead hears a word (`{gate}`, `{name}`, `{lead}` and
`{word}` filled in), `word_of` those for a fallen lead who left no word, and `journal` the line for
each (`voice`, `word_of`). What was said is kept in the record of the sixteen
(`user://earth-kings.sixteen.json`, beside `fallen_heroes`, `fallen_tempers` and `worlds`) as
`words`, oldest first, each `{ hero, gate, cell: [x, y], seed, word }`, `seed` the first world's seed
of the sixteen it was said in; one per lead per gate. The run's `carried:shut` flag marks that a life
has shut its first gate.

The world's `bands` in the ground's payload: each `{ key, pack, sight, reach, faction, label,
from, tile }`, `from` the `[dx, dy]` way to the tile it stands on (`[0, 0]` for this one) and `tile`
that tile. `key` is where the band settled and who is in it, so it stays the same as it wanders.

## `guild.json` — the Adventurers Guild

```json
{
  "contract": { "gold_base": 1500, "gold_per_rank": 2500, "giver": "the Adventurers Guild" },
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

`siblings.weapon.taken_chance` (D311) is how often a band of the land is standing over a fallen weapon's
crater as it lands (`Siblings.take_weapon`; the band's `carries` is the hero, kept in the save); the
lines `weapon_taken`, `weapon_held`, `weapon_freed`, `weapon_retaken` and `weapon_rumour_taken` take
`{band}` and the usual `{weapon}`, `{name}`, `{way}`. A band fight's outcome carries `carries`; won, the
weapon is freed, lost, another band is put on it (`world_scene._settle_up`).

Read by `src/chronicle/fall.gd`, `src/chronicle/wanderers.gd` and (`siblings`, M15)
`src/chronicle/siblings.gd`. See [17](17-the-sixteen-worlds.md).

```json
{
  "crash": { "home_name": "Where You Fell", "min_site_gap": 3, "min_tower_distance": 24,
             "min_gate_distance": 6, "max_haven_distance": 26, "attempts": 600,
             "first_world": { "city_min": 12, "city_max": 16 } },
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
  becomes the Home, renamed `home_name`. In the first world (no world ended before it) the lead
  comes down between `first_world.city_min` and `city_max` tiles from the great city instead, and
  the Tower and haven distances do not apply ([D101](06-decisions.md)).
- `landing` — the lines played when a new run first opens. `{name}`, `{region}`, `{ground}` (the
  land the ground is drawn as, from `biomes.json`), `{tower_way}` (a compass word), `{city}` and
  `{city_way}` are filled in. A line with `"lead": "atlas"` is said only when that one leads.
- `standing_quest` — "Ascend to heaven" ([D53](06-decisions.md)) as the journal shows it.
  `{floor}`, `{floors}`, `{chapter}` and `{chapters}` are filled in; `badge` marks the Tower on the map.
- `wanderers.tempers` — the temper of each hero who is not yet one of the sixteen. A hero with a
  `tempers.json` slot uses that instead. **Inferred** ([agenda item 26](worldbuilding/answers.md#what-is-still-to-decide)).
- `wanderers.preferences` — by temper group (NT, NF, SJ, SP), how much each kind of place draws
  them. A weight of 0 means never. Nearness divides the weight.
- `wanderers.rules` — how long they stay (`stay_min`..`stay_max` steps), how fast they walk
  (`steps_per_tile`), the chance a rest at a settlement brings word of one (`rumour_at_rest`), and
  how many meetings an Outward (`E`) or Inward (`I`) temper needs before they will join.
- `wanderers.tavern` — the Gilded Flagon as where they drink ([D345](06-decisions.md)): walking into
  `area` (a room of the `city` area) may find one the company has not met there, once each `every`
  world steps at `chance`, staying `stay_min`..`stay_max` as a stop of their own.
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

## `skirmish.json` → `formations` — the shapes the party walks and fights in (D289, D305)

Read by `src/skirmish/formations.gd` (pure; loaded by path), the area scene's `_settle_followers`,
`SkirmishBrain._form`, the fight's guard multiplier and the party screen. `on` turns it all off.
`shapes` is each shape's `word`, `tip` and `slots`: the companions' places round the lead, who is always
at the origin, each `{ at: [across, forward], line }` with the lead's right and the way they face
positive, and `line` one of `front`, `flank`, `back`. `line_by_doctrine` says which line a lead's
tactics doctrine belongs in; anyone else is read from their abilities (a mend on an ally at range 2 or
more: back; a first blow at range 3 or more: back; else front; nothing: flank). `Formations.assign`
deals the back line first, then the front, then the rest, each to the nearest line it would rather
stand in, from every slot of the shape. `GameState.formation` holds the pick (`auto` or a shape id;
saved); `auto_by_size` picks by the party's size (the lead counted), `fallback` below the smallest
written, `auto_word` and `auto_tip` are the picker's words. `ground_spacing` is pixels a slot on the
ground; `form_every` is the fall-in's wait, `slack` how near a slot counts as held, `hold_guard` the
share of every blow a fighter holding its slot is spared; `tactics.words.form` is the word over its head.
`foes` (D315): `on`, `from` (how many of a band standing before it falls in) and `hold_guard` (what a foe
holding its slot is spared, none); a band's shape is `auto_by_size` for its size, round its boss or first
standing (`Formations.band_slot_cell`, `band_in_contact`; the brain's `form_band` move). `ground` and
`ground_spacing` (D320): on the ground a band of `from` or more figures walks in the same shape round the one
in front, that many pixels a slot (`AreaWatch._deal_the_shape`, `slot_point`), the trail where a slot cannot be stood on.

The leader, call-outs and fights shared (D306) live beside them. `leader`: `from_won` fights won before
anyone leads (`Character.fights`, `{ won, lost }`, written by `Formations.record_fight` as a fight ends),
`charisma_lift` how many wins behind the most won a higher Charisma still leads from (D338; Charisma breaks a tie),
`shapes_by_line` the shape a leader calls for by the line they fight in (`Formations.recommend`, which
`auto` takes), `badge` the leader's card line (`{won}`) and `call` the picker's note (`{name}`).
`callouts`: `order_reach` and `answer_for` (D339: the natural leader's call turns everyone free within that many cells onto the one called, for that long, `answered` in the log); `break_below_bond` (D339) is the bond with whoever calls the shape at or under which a companion holds no slot. `healer` and `archer` are the shouts (`Formations.callout`, from the party's leader or lead and
a foe band's boss or first standing, once per foe, `skirmish._call_out`), `warned_for` the seconds the one
named is warned (`Fighter.warned`), and `warned_first` the moves it tries first while it lasts; a warned
friend counts as under half health to `SkirmishBrain._guard`. `break_below_mood`: under it a companion
holds no slot (`Formations.broken`). `shared`: `per_fight` of every blow spared and landed over for each
fight won beside the others standing with them (`Character.shared`, other id -> fights, their average),
up to `cap` (`Formations.shared_bonus`).

## `skirmish.json` → `tactics.plan_table` — a model's plans, written offline (D298, D322)

Read by `SkirmishBrain.table_move`: when `side` is `party`, `foes` or `all`, a fighter on that side
tries `moves[situation]` before its doctrine's moves, where the situation is
`SkirmishBrain.situation`'s five words (`close|ranged|mender` / `healthy|wounded|failing` /
`near|clear` / `friend_hurt|friends_fine` / `windup|calm`) and a move is one of the brain's (`dodge`,
`kite`, `flank`, `guard`, `hang_back`, `break`) or `strike` (no move). `side` is empty in the game;
`party_war.tscn -- --plan-table=party` sets it for a run. Written by `tools/plan_table.py make` (with
`model`, `prompt` and `made`); `tools/plan_table.py compare N` fights the clashes with and without it.

## `skirmish.json` — the fight's rules, passives, enemy roles and feel

Read by the fight in `src/skirmish/` ([18](18-combat-direction.md#the-fight)).

`first_strike` ([D300](06-decisions.md)): a fight whose encounter carries `first_strike` opens with the
lead's own swing on the nearest foe at `power` times its weight, with `word` over the lead and `line`
(`{name}`, `{foe}`) in the log; the fight records `first_struck`.

```json
{
  "rules": { "max_passives": 3, "base_crit": 0.05, "crit_multiplier": 1.6, "guard_cap": 0.5,
             "out_of_combat_after": 4.0, "big_hit_share": 0.2, "hit_stop": 0.07,
             "shake_on_down": 9.0, "shake_on_kill": 4.0, "shake_on_crit": 2.5,
             "energy_max": 100.0, "energy_regen": 5.0, "energy_cost": 20.0, "charged_energy": 35.0,
             "energy_recover_at": 0.5, "charged_from": 2.0, "charged_power": 1.6,
             "use_item_time": 1.5, "items_per_fighter": 2,
             "block_chance": 0.15, "block_per_defence": 0.01, "block_max": 0.4,
             "ambush_head_start": 2.0, "swings_per_practice": 3,
             "hand_fight_speed": 2.0,
             "flee": { "parting_blow": 0.1, "gold_share": 0.1, "fade": 0.6, "cleared_word": "Clear",
                       "making_line": "…", "cleared_line": "…", "dropped_line": "…" } },
  "passives": {
    "shieldwall": { "display_name": "Shieldwall", "description": "…", "effect": "aura",
                    "radius": 2, "grants": { "guard": 0.15 } }
  },
  "signatures": { "diana": { "style": "beast_bond", "display_name": "Beast-bond",
                             "description": "…", "beast": "ice_wolf", "without": 0.4 } },
  "by_template": { "brigand_chief": ["war_cry"] },
  "by_class": { "sworn_blade": ["shieldwall"] },
  "by_ability": { "riposte": ["barbed_guard"] },
  "roles": { "charger": { "display_name": "Charger", "description": "…", "charge_from": 3,
                          "pace": 1.7, "charge_bonus": 0.4 } },
  "role_by_template": { "brigand_archer": "kiter" },
  "by_tier": { "1": { "role": "craven" }, "3": { "passives": ["hunters_angle"], "role": "charger" },
               "5_caster": { "passives": ["keen_eye"] } },
  "family_tricks": { "from": 4, "families": { "goblin": ["spite"], "slime": ["ooze_back"] } },
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
  once. `flee` (D319): what getting clear of a fight costs: `parting_blow` of a fighter's health on reaching
the edge (never a fall), `gold_share` of the company's coin a band of the land keeps when everyone gets
clear (`SkirmishRules.flee_toll`), and the three lines (`{who}`, `{coin}`); whoever gets clear fades over
`fade` seconds under `cleared_word` ([D324](06-decisions.md)). `hand_fight_speed` (D329): the most a fight
played by hand starts at (`Pace.ease_to`), the walking speed given back when it ends. `reach_the_fallen` (D326): with `on`, one of
the company down with nobody on the way is gone to by the nearest member under no order and not busy
(`line`, `{who}` and `{name}`); with `close_round`, the rest who are free turn on the foe nearest the fallen. `swings_per_practice` — landed basic swings that count as one use toward proficiency;
  every skill that lands counts once. Both **Inferred** ([D65](06-decisions.md)).
- `decor` — the props (`art/props/<id>.png`, sized by `props.json`'s `battle_scale`) planted on a
  field: `trees` on crags, walls and a third of the edge, `bushes` in the brush. Scenery only.
- `conditions` ([D192](06-decisions.md)) — what each of an ability's conditions does and says.
  Each has its `word` (said over the body it lands on), `resisted` (said in silver when it is
  shrugged off) and `tip` (the line on the skill's tooltip); `knockback`/`pull` their `slide`
  (seconds a tile) and `pinned` word (nowhere to go); `slow` its `steps` and `swings` shares;
  `burn`/`bleed` their `per_second` share of the blow that lit them; `expose` its `more`; `stun`
  only its `resisted` word. `dodged`, `missed`, `covers` and `set` are words: a skill come down
  where a fighter stepped out of it, on empty ground, Caesar taking part of a blow, Cato dug in.
  `resists`: `boss` (a keeper's list), `heavy` (`from_body_scale`, `less`: tiles a shove loses on
  a big body), `by_style` (a lead's signature) and `by_template`. `status_icons` gains `down`,
  `slowed`, `burning`, `bleeding` and `exposed`.
- **Shields**: a unit with a class, ability or template (`by_template`) under `shield_bearers` blocks a
  melee basic attack that does not come from behind, with a chance of `block_chance` +
  `block_per_defence` × its defence, at most `block_max`. Not while casting, using an item or stunned.

- **Signatures** (the sixteen's own ways of fighting, agenda item 72): keyed by template, so a lead
  carries theirs whatever class they take, and so does one met as a foe. `style` names what the
  code does; the other keys are its numbers, all shares or seconds. `borne` (`bearer`, `bearer_name`:
  a companion that keeps beside him; no step without it), `doorways` (`per_foe`, `most`: cooldown
  speed), `orders` (`every`, `radius`, `lasts`, `advance`, `break_them`, `energy_radius`,
  `energy`), `learns` and `one_target` (`per_hit`, `most`), `gravity_well` (`radius`, `slow`),
  `ward` (`every`, `radius`, `below`, `ward`, `dead` templates, `dead_bonus`, `burns_only_dead`:
  her fire leaves a burn only on the dead), `takes_the_hit`
  (`share`, `rise_after`, `rise_health`), `marks` (`lasts`, `marked_bonus`, `per_finish`, `most`),
  `shades` (`health`, `at_once`, `per_kind`, `most`), `growth` (`plant_after`, `most`, `radius`,
  `regen`, `slow`, `rooted_bonus`), `set` (`after`, `guard`, `might`, `beside`), `provision`
  (`twice`, `every`, `radius`, `below`), `beast_bond` (`beast`, `beast_name`, `without`), `opener`
  (`lasts`, `might`, `haste`, `tired_might`, `tired_slow`), `bare_hands` (`every`, `per_step`,
  `most`). A companion (bearer, wolf, a shade) fights beside the party as an ally, at its owner's
  level, and is gone after the fight.
- A unit's passives are gathered from `by_template` (a tier of a monster falls back to its family's),
  then its tier's row in `by_tier` ([D275](06-decisions.md): `"1"` to `"5"`, and `"5_caster"` for the
  second of a family's top kinds), then, from the tier `family_tricks.from` up, its family's trick
  ([D276](06-decisions.md)), then each of its classes in `by_class`, then each ability it knows in
  `by_ability`, and capped at `rules.max_passives`.
- `effect` is one of `lifesteal`, `thorns`, `flank_bonus`, `crit`, `echo`, `regen` (out of the
  fighting), `last_stand` (with `threshold`), `reset_on_ally_down`, or `aura`, whose `grants` may
  hold `guard` (less damage taken), `haste` (faster basic attacks) and `regen` (health a second),
  each a share. `also` adds a second effect to the same passive, e.g. `{ "flank_bonus": 0.15 }`.
- An enemy's role is `role_by_template`, else its tier's `by_tier` role, else `healer_role` if it carries a non-bonus heal for an
  ally with a reach of two or more, else `ranged_role` if its basic attack reaches three, else
  `role_by_kind`. Role keys: `charge_from`, `pace`, `charge_bonus` (charger), `keep_away`,
  `retreat_every` (kiter and healer), `heal_below` (healer), `flee_below` and `flee_gap` (craven: under that
  share of its health it runs until no foe is within `flee_gap` tiles, and stands there). A role with only a name changes nothing.

## `sfx.json` — what the fight sounds like ([D76](06-decisions.md))

```json
"voices": 12,
"cues": { "hit": { "file": "hit", "volume_db": -8.0, "pitch": [0.85, 1.15], "gap": 0.05 } }
```

- `voices` — how many sounds may play at once (at least the interface's four).
- A cue is a moment the fight sounds: `swing`, `shoot`, `hit`, `crit`, `block`, `charge`, `spell`,
  `heal`, `stun`, `drink`, `fall` (one of the company down), `death` (a foe), `victory`, `defeat`,
  `engage` (a fight opening) and `ward` (a ward taken up, or soaking a blow; [D185](06-decisions.md)).
- `file` — the sound in `audio/sfx/` (no extension); `tools/make_fight_sounds.py` makes them.
- `volume_db` — loudness against the others; `pitch` — the range each play is picked from, so
  repeats differ; `gap` — the fewest seconds before the same cue sounds again. All under the
  Sounds slider. A cue not listed is silent.

## `music.json` — what plays where ([D100](06-decisions.md), [D185](06-decisions.md))

```json
"fade": 1.4,
"scenes": { "area": "road", "skirmish": "battle", "summary": "world_ending" },
"places": { "tower_floor_1": "tower", "city": "city", "home": "crater", "world_ends": "world_ending" },
"dialogues": { "memory_": "memory" },
"sets": { "tower": [{ "path": "res://audio/music/tower_floors.wav", "volume_db": -14.0 }] }
```

- `fade` — seconds one track takes to cross into the next.
- `scenes` — a scene key (as [Game] knows it) to the set it hears; a key not listed is silence.
- `places` — an area's id, or the id of the place on the land tile walked onto (`home` is the
  crater), or a moment's key (`world_ends`, the world's last look), to the set heard there in place
  of the scene's. The area scene says where the party is on `EventBus.place_entered`, on coming in
  and on each new tile of the land; a place not listed hears the scene's set.
- `dialogues` — the start of a dialogue's id to the set heard while it is open (a chapter one is
  `memory_<id>`); when it closes, the place's or the scene's set comes back.
- `sets` — a set's tracks, each a `path` and its `volume_db`; with several, one is picked at random,
  never the one it played last. Every track loops. The fan covers are never named (D100).

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

All rows must be the same length, and every spawn must sit on walkable terrain. A field may carry
`heights` (one row of digits a tile row, a height a cell, over the terrain's own) and `ways_up` (cells where
a height is climbed): then it is *ledged* (D313), walked and shoved the ground's way (D308) rather than the
jump's. A fight laid over an area with heights writes both from the area (`Skirmish._ground_field`), and
`clouds` (cells of cloud, D321) where the area has any: never stood on, and a body shoved into one is gone.

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
  them), `gold` (a signed amount), `item` (handed over) and `heal` (`true`: the company mended, as a
  rest does).
- An option is hidden unless the party satisfies its `requires` / `requires_not` flags, its
  `requires_gold`, and its `requires_wounded` (`true`: only while someone in the company is hurt;
  `false`: only while nobody is).

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
`autosave`, the points the game saves itself at — `start`, `rest`, `town` (walking into a town),
`guild` (opening the Guild's register), `gate` (a gate shut), `chapter`, `road` (every
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
