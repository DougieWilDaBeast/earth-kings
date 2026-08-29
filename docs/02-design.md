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
- **Classes.** At **level 2** a character takes a main class. The **player chooses** theirs and the
  world waits for the answer; everyone else settles into one on their own ([D12](06-decisions.md)).
- **Stats** = template base + class growth × (level − 1) + doctrine bonuses.
- **The Training Yoke.** An optional stance: −25% attack in exchange for +50% XP. Training
  through self-imposed handicap, as a first-class mechanic.

## Falling — death and its graces

**Death is the default.** A character who falls is gone unless something they _brought with them_
buys their way out ([D11](06-decisions.md)). Each possible reason is a **grace** with its own
chance; they are rolled in order and the **first to land claims the moment**, so the reason a
character survived is always a specific, tellable thing rather than a shrug.

| Grace       | Where the chance comes from                                  | What happens                                                        |
| ----------- | ------------------------------------------------------------ | ------------------------------------------------------------------- |
| **Charm**   | A relic carried — Grave Token 50%, Knotted Cord 25%          | Lives. The charm is **spent** and gone                              |
| **Rescue**  | 12% per ally still standing, capped at 36%                   | Lives. The ally who pulled them out is named                        |
| **Lore**    | Sum of the `grace` on doctrine they have read, capped at 30% | Lives, _because_ of a specific book                                 |
| **Ground**  | 15% if they fell within 6 tiles of a hearth                  | Lives. Crawls to safety                                             |
| **Luck**    | A flat 7%                                                    | Lives, for no reason at all                                         |
| **Capture** | Set by who beat them — raiders 40%, soldiers 30%, beasts 0%  | **Taken alive.** Leaves the party, held at the nearest keep or gate |
| —           | Nothing landed                                               | **Dead.** Permanently                                               |

Survivors come back at 25% of max HP; captives at 10%. Measured over 200 falls: a lone,
unarmed, unread character against a beast dies **186 times out of 200**. Two allies standing lifts
that from 7% to 31%; one book read lifts it to 17%.

The design consequence is deliberate — **preparation is what buys lives**. Walking into bad
country alone, with nothing read and nothing carried, is close to suicide, and it should be.

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
effect archetypes (blow, reach, loose, burst, sweep, mend, rally). Each theme draws from its own
subset, so a Sworn Blade's trees come out sharp and a Hedge Priest's come out restorative.

## Doctrine and the Library

Written knowledge, and the sharpest expression of pillar 2.

- **Read** at a library — that one character learns it. Nobody else.
- **Teach** it to a party member, if they do not already know it.
- **Forget** it: doctrine not read, taught or fought with for **900 steps** fades away.
- Effect is a flat stat bonus while known (`attack`, `defense`, `max_hp`, `speed`, `move`, `jump`),
  and some books also carry a `grace` — knowledge that can keep you alive.
- Every world starts with one book already on a shelf: _Fist of the Open Palm_.

## The world

A generated **44×44** map. Ground comes from two noise fields (elevation and damp) resolving into
water, grass, brush, hill, crag and mountain. Then places are scattered on it, never closer than
5 tiles apart:

| Kind    | Count | Role                                                      |
| ------- | ----- | --------------------------------------------------------- |
| Tower   | 1     | Claims the far corner; everything else arranges around it |
| Home    | 1     | Yours; beside the first village, and where you start      |
| Keep    | 2     | Safe ground                                               |
| Village | 4     | Safe ground and rest                                      |
| Library | 3     | Doctrine                                                  |
| Gate    | 6     | Ranked dungeons                                           |
| Hut     | 4     | Safe ground on a long road                                |

**Home and the bed.** Home is the only site the player owns and the only one with nothing to sell.
Sleeping there heals the party outright, and the bed installed in it grants every sleeper a
permanent bonus to max HP — the one stat the player buys rather than earns. Beds are a fixed ladder
in `world_rules.home.beds` (straw pallet 0 HP → canopied bed +22 HP) and only ever go up. The
bonus is stored per character as `hearth`, so a companion who never came home never gained it, and
a night in a village never takes it away.

**Gate ranks** run E → D → C → B → A → S. Rank is set by distance from the Tower — the gates near
it are the bad ones — with a little jitter. Expected delver level is `1 + rank_index × 4`.

**The world clock.** Every 30 steps the world takes an upkeep pass: closed gates may open again
(25% normally, 10% if recently cleared). Nothing stays shut forever.

**Towns under threat.** The same pass puts the settlement nearest a long-open gate under siege.
A siege you answer (`Town.save`) pays gold and buys goodwill; one you ignore for 900 steps takes
the town, which stops trading for good. Raiding (`Town.raid`) is the other end of the same lever:
you fight the town's own people, empty its strongbox, and it is ruined either way — the difference
is only who did it, and that is the part the country remembers.

**Renown is local.** There is no single number for how famous the party is. Every notable act is a
_deed_ recorded at the cell it happened on, and word travels outward at a fixed number of steps per
tile (`renown.steps_per_tile`). `Renown.standing` sums the deeds that have reached a given cell, so
the same party is renowned in one valley and unknown in the next. Standing sets the greeting a
place gives you, moves its prices, and feeds the `renown` skill in dialogue checks.

**Loot has no bag.** `Loot.take` hands a piece to the party member it most improves; charms go to
the player; anything nobody gains from is sold immediately. Nothing accumulates in a screen that
would never be read.

## Battle

Unchanged from the tactics core and already working:

- Square grid, per-tile move cost, height and jump.
- **Charge-time turn order** — each tick every unit gains CT equal to its speed and acts at 100,
  so fast units act _more often_, not merely sooner.
- **Your ready units act as a squad.** Every player unit at 100 CT takes the phase together;
  **Tab** (Shift+Tab to go back) switches between the ones who still have something to spend,
  and clicking one selects it. Enemies still act one at a time.
- **An action and a bonus action each turn.** An ability costs the action; moving costs either
  and spends the bonus first; flash stepping and abilities flagged `"bonus": true` cost the bonus.
  "Wait" gives up what that character has left, not the whole phase.
- **Flash step** — a blink to any free tile within range, ignoring move cost, height and anyone
  in the way. Granted by a unit template or a class (`flash_step`).
- **Facing matters**: side hits deal 1.2×, back hits 1.5×. Units turn as they move.
- Damage is `max(1, attack × power − defense)` with ±10% variance.

Battlefields for wild encounters and delves are **generated** from the world terrain you were
standing on; hand-authored maps in `data/maps/` remain for set pieces.
