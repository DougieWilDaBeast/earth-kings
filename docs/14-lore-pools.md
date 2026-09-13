# 14 — Lore Pools & Casting

Five pools of authored history, written with **no character in mind**, and attached to characters
late — by judgement, in a sitting set aside for it. This document is how that works.

The point of the late join is that a history written for a particular character can only confirm
what was already decided about them. A history written on its own has to be interesting first, and
then it turns out to fit two or three people, and choosing between them is a real decision.

## The five pools

| Pool | File | What it answers | What it drives |
| --- | --- | --- | --- |
| **backgrounds** | `data/lore/backgrounds.json` | What they were before the road | A gift |
| **grudges** | `data/lore/grudges.json` | Who they hate, and what counts as one of them | +10% damage against them |
| **hearths** | `data/lore/hearths.json` | Where they are from | Which site a run of theirs starts on |
| **creeds** | `data/lore/creeds.json` | What they believe | Who they can stand to walk beside |
| **oaths** | `data/lore/oaths.json` | What they swore, and to whom | The ties between the sixteen |

One schema, one casting mechanism, one validator, five pools. Anything true of one is true of all
of them.

```json
"<id>": {
  "display_name": "…",
  "blurb": "…",          // one line, shown on the reveal screen
  "text": "…",           // the authored history, a short paragraph
  "tags": ["…"],         // shared vocabulary across every pool
  "gift": { "kind": "item", "value": "iron_blade" }
}
```

Plus, per pool: `hearths` carry `site_kind`, `grudges` carry `matches`, `creeds` carry `holds` and
`despises`, `oaths` may carry `toward`.

Entries marked `"provisional": true` were migrated out of the old hardcoded tables so the game runs
while the real pools are written. **Replace them; do not extend them.**

## Creeds, and why there is no table

A creed says what it `holds` and what it `despises`, over a small shared vocabulary (`order`,
`freedom`, `mercy`, `ruin`, `truth`, `kin`, `coin`, `silence`). Chemistry is computed from the
overlap: shared values warm a bond, and one person holding what the other despises cools it, twice
over if it runs both ways.

This is why the pool can grow to any size. A sixteen-creed pairwise table would be 256 cells to
maintain; this way a new creed only has to say what it is for.

## Gifts

A background — or any pool entry — may carry exactly **one** gift, from a closed vocabulary, so an
authoring session can never invent an effect the engine does not implement.

| Kind | Value | Effect |
| --- | --- | --- |
| `doctrine` | a doctrine id | They have already read it |
| `item` | an equipment id | Carried, or worn |
| `gold` | a number | Added to the purse — **the lead only** |
| `grudge` | a grudge id | Fills their grudge if it is empty |
| `hearth` | a hearth id | Fills their hearth if it is empty |
| `bond` | `{ toward, warmth }` | Somebody already owes them, or already cannot stand them |
| `stat` | `{ max_hp: n }` | A small, permanent difference |

**No gift may buy survival.** Charms are delved for ([D24](06-decisions.md)) and a grace-bearing
book handed out at creation would quietly move the death maths the whole design is measured
against — a lone, unread character dies 186 times in 200, and that number is load-bearing. The
validator enforces both.

Open question for the authoring sessions: whether a background may grant **any** doctrine. It
collides with pillar 2 — the Library is somewhere you walk to for a reason — and with the fact
that library shelves are stocked from the same pool at worldgen. The vocabulary allows it; none of
the provisional entries use it.

## Casting

Two artifacts, because this has a machine half and a human half.

**`data/casting.json`** is the live many-to-many, keyed the way authoring happens — a piece, then
who it could fit:

```json
"backgrounds": {
  "locked": false,
  "pieces": {
    "the_forge_that_burned": { "candidates": ["…", "…"], "cast": "" }
  }
}
```

**`docs/worldbuilding/casting-ledger.md`** is the half we actually read when solidifying: per
piece, one line per candidate saying **why** it fits, and at least one line saying who it was
deliberately **not** marked for. The negatives are what make a casting session fast.

`locked: true` means every one of the sixteen carries a piece from that pool, and the validator
gets strict about it from then on.

### The loop

1. **Write a piece** into whichever pool it belongs to, with no character in mind.
2. **Mark candidacy** — every character it could plausibly fit, with a reason each, in the ledger.
3. **Read the report** before each session:

   ```
   godot --headless --path . res://tests/bench.tscn -- --report=casting
   ```

   It prints, per pool: **starved** characters (nobody marked — these say what to write next),
   **forced** characters (exactly one candidate — cast them, they are not decisions), **contested**
   pieces (marked for many — the only part worth arguing about) and **orphans** (marked for nobody —
   world texture, or a miss).
4. **Cast**, working forced → contested → starved, and lock the pool when all sixteen are set.

Uncast pieces are never deleted. They become NPC histories, rumours, library books and faction
propaganda — a background nobody was cast is still a person who existed.

## Validation

`tests/wishlist_smoke_test.gd` checks, on every run: ids resolve across pools; gift kinds are in
the vocabulary and their values exist; no gift buys survival; hearths name a site kind; grudges
match somebody; oaths point at real heroes; a cast piece was a candidate first; no piece is cast
twice and no character carries two pieces from one pool; and, once locked, that everyone has one.

Blank is legal everywhere. The project lives in the uncast state for weeks, and it has to be
playable the whole time.
