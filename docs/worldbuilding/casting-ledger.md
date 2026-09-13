# Casting ledger

Which authored history could belong to which character, why, and what was finally decided. The
machine-readable half is `data/casting.json`; this is the half read out loud during a casting
session.

How the pools, the gifts and the loop work: [14 — Lore Pools](../14-lore-pools.md).

## Before each session

```
godot --headless --path . res://tests/bench.tscn -- --report=casting
```

Work the output in this order:

1. **forced** — exactly one candidate. Cast them now; they are not decisions.
2. **contested** — marked for three or more. The only part worth arguing about.
3. **starved** — nobody marked. These say what to write next, not what to cast.
4. **orphans** — marked for nobody. Keep them: NPC histories, rumours, library books.

## Marking a piece

One block per piece, in the pool's section below. Copy the template. **Write the negatives** — six
weeks later every marker looks equally plausible, and the line saying who it was ruled out for is
what makes the session fast.

```
### <pool>/<piece id> — <display name>

> <blurb>

- **<hero id>** — why it fits, in one line.
- **<hero id>** — why it fits, in one line.
- **Not <hero id>** — why it was ruled out, in one line.
- **Cast:** <hero id>, on <date>. <One line on what decided it.>
- **The runners-up become:** <where the losing readings go — a rumour, an NPC, a false book.>
```

### Worked example — delete when the first real one lands

### backgrounds/the_forge_that_burned — The Forge That Burned

> Learned a trade from somebody who did not live to see them finish it.

- **<hero id>** — the half-finished apprenticeship explains why they defer to older craftsmen and
  will not call themselves a smith.
- **<hero id>** — same history, opposite reading: they finished the work alone and have been
  insufferable about it since.
- **Not <hero id>** — they already carry a loss that does the same job, and two is a theme.
- **Cast:** —
- **The runners-up become:** whichever reading loses is the version a village tells about the one
  who left, which is how the character finds out their own story got away from them.

---

## backgrounds

_Nothing cast yet. Five provisional entries migrated from the old hardcoded table are in
`data/lore/backgrounds.json`; they are scaffolding and are not candidates._

## grudges

_Nothing cast yet. Five provisional entries carry the match rules lifted out of
`Character.has_grudge_against`._

## hearths

_Nothing cast yet. Five provisional entries cover the five site kinds a run can start on._

## creeds

_Nothing cast yet. Nine provisional entries stand in for the retired alignment grid, each carrying
the `holds` / `despises` tags that reproduce roughly the chemistry the grid used to give._

## oaths

_Empty on purpose. This pool has no migrated scaffolding — every character is starved of one, which
is exactly what the report says. Oaths are the pool that turns sixteen separate people into a cast,
so they are worth writing after there are characters to swear them at._
