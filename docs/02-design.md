# 02 — Design

## The loop

```
        ┌──────────────────────────────────────────────┐
        │                                              │
   walk the world  ──▶  something happens  ──▶  grid battle
        ▲                                              │
        │                                              ▼
        └────────  grow / bury / carry wounds  ◀────────┘
```

Every step you take advances the world clock. Steps are the only thing that moves the world, so
travel is never free: crossing the map to reach a library is time gates spend opening and
doctrine spends fading.

**What can happen while walking**

| Where you step             | What happens                                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------------ |
| Open ground                | A chance of a wild encounter, scaled by how close the nearest open gate is and how far the nearest hearth is |
| A **gate**                 | Delve it — a run of battles ending in its guardian                                                           |
| The **Tower**              | Climb — one battle per floor, each harder than the last                                                      |
| A **library**              | Read what is on its shelf; teach it to the party                                                             |
| A **village / keep / hut** | Rest and recover; safe ground, encounters go quiet                                                           |

## Characters

A `Character` is the persistent person. A battle `Unit` is a puppet spawned from one for the
length of a fight and thrown away afterwards. The save file remembers Characters.

- **Levels and XP.** XP comes from defeating things. Cost to next level is `20 + level² × 6`.
- **Classes.** At **level 2** a character takes a main class from the options their template
  allows. The class supplies stat growth per level, granted abilities, and the _themes_ their
  generated powers will be drawn from.
- **Stats** = template base + class growth × (level − 1) + doctrine bonuses.
- **The Training Yoke.** An optional stance: −25% attack in exchange for +50% XP. Training
  through self-imposed handicap, as a first-class mechanic.
- **Permadeath.** Real, and the point.
- **Wounds persist** between battles. Anyone who falls is dragged out at a quarter of max HP
  rather than lost outright, so a costly win hurts without ending the run. (Where the line
  between "dragged out" and "dead" sits is [D05](06-decisions.md).)

## The power system

Skill trees are **generated, not authored** — the world has a hidden grammar of themes crossed
with effect archetypes at rising intensity.

- A character unlocks their **first tree at level 5** and a **second at level 10**, drawn from
  their class's themes.
- Every other level-up learns the next unlearned rung from a tree they hold.
- Trees are named and stored in the world, so a save restores the exact powers that world found.
- **The Codex** tracks how much of the grammar the world has catalogued. Absurd results are
  permitted output, not a bug.

Nine themes exist (edge, ember, storm, hunt, iron, vigil, hearth, mourning, wind) and seven
effect archetypes (blow, reach, loose, burst, sweep, mend, rally).

## Doctrine and the Library

Written knowledge, and the sharpest expression of pillar 2.

- **Read** at a library — that one character learns it. Nobody else.
- **Teach** it to a party member, if they do not already know it.
- **Forget** it: doctrine not read, taught or fought with for **900 steps** fades away.
- Effect is a flat stat bonus while known (`attack`, `defense`, `max_hp`, `speed`, `move`, `jump`).
- Every world starts with one book already on a shelf: _Fist of the Open Palm_.

## The world

A generated **44×44** map. Ground comes from two noise fields (elevation and damp) resolving into
water, grass, brush, hill, crag and mountain. Then places are scattered on it, never closer than
5 tiles apart:

| Kind    | Count | Role                                                      |
| ------- | ----- | --------------------------------------------------------- |
| Tower   | 1     | Claims the far corner; everything else arranges around it |
| Keep    | 2     | Safe ground                                               |
| Village | 4     | Safe ground, rest, and where you start                    |
| Library | 3     | Doctrine                                                  |
| Gate    | 6     | Ranked dungeons                                           |
| Hut     | 4     | Safe ground on a long road                                |

**Gate ranks** run E → D → C → B → A → S. Rank is set by distance from the Tower — the gates near
it are the bad ones — with a little jitter. Expected delver level is `1 + rank_index × 4`.

**The world clock.** Every 30 steps the world takes an upkeep pass: closed gates may open again
(25% normally, 10% if recently cleared). Nothing stays shut forever.

## Battle

Unchanged from the tactics core and already working:

- Square grid, per-tile move cost, height and jump.
- **Charge-time turn order** — each tick every unit gains CT equal to its speed and acts at 100,
  so fast units act _more often_, not merely sooner.
- Move, then act, then wait. Abilities have min range, max range and splash.
- **Facing matters**: side hits deal 1.2×, back hits 1.5×. Units turn as they move.
- Damage is `max(1, attack × power − defense)` with ±10% variance.

Battlefields for wild encounters and delves are **generated** from the world terrain you were
standing on; hand-authored maps in `data/maps/` remain for set pieces.
