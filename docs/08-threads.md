# 08 — Threads

How long-running story gets into a world that has no quest log.

## The problem

Everything narrative in the game today is **one beat long**. An errand is posted, walked and
settled. A deed is recorded and spreads. A grave is raised and visited. Each is good on its own
and none of them remember each other, so nothing accumulates across a run except numbers.

A **thread** is the missing unit: a chain of beats that holds a question open, advances because of
what you did, and resolves in a way you cannot take back.

## What a thread is not

- **Not a quest log.** Nothing new appears in the UI. A thread surfaces the way everything else
  here does — as rumour at a site, as a line in the hint bar, as banter on the road, as somebody
  standing in your way.
- **Not accepted.** You do not take a thread from a board. It ignites because of something already
  written down: gates you shut, a town you raided, somebody who died. Errands stay what they are
  ([`Errand`](../src/chronicle/errand.gd) — small jobs, no stakes).
- **Not scripted onto the map.** A thread names _kinds_ of place, never coordinates. It has to
  survive a fresh `world_seed`.

## The model

[`Skein`](../src/chronicle/skein.gd) is a pure-logic class in `chronicle/`, like `Errand` and
`Renown` — no scene nodes, serialisable, testable headless. The class is called `Skein` because
Godot already owns `Thread`; everything else — the data file, the world field, this document —
says thread. Live threads hang off `World`:

```gdscript
var threads: Dictionary = {}   # thread_id -> { stage, entered_at, memory, tags, done }
```

`memory` is the thread's own scratch dictionary. It is the whole point: it is where "you flanked
him last time" and "she was already dead when they asked" live.

### The tick

Threads advance in three event contexts:

1. **The upkeep pass** (`World.UPKEEP_INTERVAL`, every 30 steps) — for anything measured in
   distance or elapsed steps. `Skein.on_step` is called from `World._upkeep`.
2. **Arrival** — `Skein.on_arrive` in `world_scene._step`, for stages that wait on a kind of
   place.
3. **Battle and Mortality** — `Skein.on_battle` in `world_scene._settle_up` routes encounter
   outcomes, and `Skein.on_character_fell` in `battle.gd` notifies threads when a companion falls.

`Skein.tick(world, context)` evaluates the current stage's `when` against world state, and if it
holds, runs `then` and moves the stage on. Threads never poll and never hold references to each
other; a thread that wants to know about another one reads `world.threads`.

## `data/threads.json`

```json
"the_gatewarden": {
  "title": "The Gatewarden",
  "ignite": { "deed": "gate_shut", "count": 2 },
  "stages": [
    {
      "id": "word_gets_around",
      "when": { "steps_since_stage": 60 },
      "then": [
        { "rumour": "somebody has been asking which gates you shut", "at": "last_deed", "weight": 0 },
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

### `when` — the closed set

Keep this small. Every addition is a new thing content can silently get wrong.

| Key                 | Holds when                                                   |
| ------------------- | ------------------------------------------------------------ |
| `steps_since_stage` | This many steps have passed since the stage was entered      |
| `steps_since_start` | The world clock has passed this many steps                   |
| `deed` / `count`    | The world has this many deeds of a kind (`Renown` constants) |
| `arrive_kind`       | The player just stepped onto a site of this kind             |
| `battle_won`        | The last battle was won (`true`) or lost (`false`)           |
| `character_dead`    | A named party member, or `any`, is gone                      |
| `standing_below`    | Local standing here is under a value (`Renown.standing`)     |
| `standing_above`    | Local standing here is over a value                          |
| `tag`               | Some live thread has set this tag                            |
| `remembers`         | This thread's own memory has the key                         |
| `thread_done`       | Another named thread has finished                            |

Conditions in one `when` are **all** required. Alternatives are separate stages with the same
effects — verbose on purpose, so a stage always reads as one situation.

A stage may also carry `deadline` (in steps) and `goto`: if the `when` has not held by then, the
`instead` effects run and the thread jumps to the named stage. See Q13.

### `then` — the closed set

| Effect     | Does                                                                      |
| ---------- | ------------------------------------------------------------------------- |
| `rumour`   | `Renown.record` at `here` \| `last_deed` \| a site kind. Spreads normally |
| `hint`     | One line in the world log                                                 |
| `remember` | Writes fields into the thread's own memory                                |
| `tag`      | Sets a tag other systems can read without knowing who set it              |
| `untag`    | Clears one                                                                |
| `errand`   | Force-posts a tagged errand on the nearest site of a kind                 |
| `site`     | Places a site (`camp`, `grave`, `hut`) on free ground near an anchor      |

Every one of these is a call into something that already ships. A thread cannot do anything the
world could not already do; it only decides when.

## The Nemesis — SHIPPED

[`Nemesis`](../src/chronicle/nemesis.gd) (`world.survivors`) implements persistent foes who survived defeat:

- Sentient enemies defeated in combat roll a 20% survival check. Survivors crawl into the brush, take
  on an epithet, and log their survival to `world.survivors`.
- Their survival spreads outward through `Renown.record` and enters the `Annals`.
- Survivors can reappear leading roaming prowler bands. When encountered, they speak tense pre-battle
  recognition dialogue remembering the place of their previous defeat.

**One-way doors apply.** A nemesis can be killed for good, and a nemesis can kill you for good.
Nothing about them respawns to keep the story going.

## Errand chains — not built yet

Cheapest win in the whole document, and it needs one field.

Give an errand an optional `follows` key. When one settles, if it names a successor, the successor
is posted at a named _kind_ of site rather than nowhere — and the line acknowledges the last one.
Three linked errands with a `thread` tag on them read as a story; three unlinked ones read as a
board. `Errand._settle` is the only function that changes.

## Build order

Each step ends playable, per the working rules.

1. **Engine, no combat.** ✅ `skein.gd`, `world.threads` with serialisation, the upkeep hook, and
   threads that only write rumour, tags, errands and camps. `tests/skein_smoke_test.tscn` proves
   state survives a save/load round trip before anything depends on it.
2. **Event hooks.** ✅ Battle results and character deaths wired to `Skein.on_battle` and `Skein.on_character_fell`.
3. **Nemesis.** ✅ `nemesis.gd` over `Prowler`, survivor epithets, memory, recognition dialogue, and renown spread.
4. **Errand chains.** The `follows` field. Immediate texture, no new system.
5. **The dead as a source.** A thread that ignites on `character_dead` and puts somebody at a
   village who wanted them back. `Memorial` already gives it a place to end.

## What this leaves open

See [06 — Decisions](06-decisions.md) for Q13–Q15.
