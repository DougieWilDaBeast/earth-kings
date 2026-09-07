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
  allows. The **player chooses** theirs and the world waits for the answer; everyone else settles
  into one on their own ([D12](06-decisions.md)). The class supplies stat growth per level, granted
  abilities, and the _themes_ their generated powers will be drawn from.
- **Stats** = template base + class growth × (level − 1) + doctrine bonuses + hearth vigour.
- **The Training Yoke.** An optional stance: −25% attack in exchange for +50% XP. Training
  through self-imposed handicap, as a first-class mechanic.
- **Backgrounds, Origins & Grudges.** Heroes carry one of five backgrounds (`apprentice_smith`,
  `wilderness_stray`, `cloistered_scholar`, `exiled_noble`, `outcast_drifter`), an alignment on the
  3×3 grid, and an ancestral grudge against specific foes (e.g. apprentice smiths against raiders,
  nobles against imperial usurpers) granting +10% grudge damage in battle.

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

A generated **128×128** continental map bounded by oceans and severed by lakes and bays. Ground
comes from radial shore falloff and elevation/damp noise fields, resolving into ocean, lake,
shallows, sand, grass, meadow, brush, forest, marsh, hill, crag, mountain, and snow. Continental
geography is divided into named provinces (The Frostpeak Waste, The Heartlands, etc.). Then 48
sites are scattered across the land, never closer than 9 tiles apart:

| Kind    | Count | Role                                                               |
| ------- | ----- | ------------------------------------------------------------------ |
| Tower   | 1     | Claims a far region; ten-floor climb culminating in the Spire Apex |
| Home    | 1     | Yours; hearth where you start, bed upgrades, safe haven            |
| Keep    | 5     | Fortified havens, proving arena grounds for live tournaments       |
| Village | 11    | Safe ground, markets, hirelings, coastal ports                     |
| Library | 6     | Written doctrine and study                                         |
| Gate    | 14    | Ranked dungeons (E → S); deep multi-floor delves                   |
| Hut     | 10    | Waystations, wild sanctuaries on long roads                        |

**Two views: Continental and Planar.** Pressing **Z** switches between the Continental overview
and top-down Planar view. All 48 sites have hand-built interiors, and wilderness tiles (forest,
marsh, hill, desert) open into explorable 30×20 planar regions whose open cardinal edges step
seamlessly across continental borders.

**Home and the bed.** Home is the only site the player owns and the only one with nothing to sell.
Sleeping there heals the party outright, and the bed installed in it grants every sleeper a
permanent bonus to max HP — the one stat the player buys rather than earns. Beds are a fixed ladder
in `world_rules.home.beds` (straw pallet 0 HP → canopied bed +22 HP) and only ever go up. The
bonus is stored per character as `hearth`, so a companion who never came home never gained it, and
a night in a village never takes it away.

**Gate ranks and breaking.** Gate ranks run E → D → C → B → A → S. Rank is set by distance from the
Tower — the gates near it are the bad ones — with jitter. Expected delver level is
`1 + rank_index × 4`. A shut gate **never reopens** ([D15](06-decisions.md)). However, an open
gate left neglected too long **breaks** — raising local danger by 25pp and enemy level by 3.
Late-game abyssal rifts (`the_deep_breach`) can awaken new S-rank gates under continental pressure
([D26](06-decisions.md)).

**The world clock and seasons.** Every step advances the continental clock. Every 120 steps turns
the season represented by four clovers: Lesser Green (Spring), Green (Summer), Brown (Autumn), and
Ice (Winter). Every 30 steps the world takes an upkeep pass (`World.UPKEEP_INTERVAL`): gates check for
breaking, trade routes pay, threads tick, and prowlers restock. Scaling a Tower floor advances the
continent by 30 steps ([D27](06-decisions.md)).

**Towns under threat.** The upkeep pass puts the settlement nearest a long-open gate under siege.
A siege you answer (`Town.save`) pays gold and buys goodwill; one you ignore for 900 steps takes
the town, which stops trading for good. Raiding (`Town.raid`) is the other end of the same lever:
you fight the town's own people, empty its strongbox, and it is ruined either way — the difference
is only who did it, and that is the part the country remembers.

**Renown is local.** There is no single number for how famous the party is. Every notable act is a
_deed_ recorded at the cell it happened on, and word travels outward at a fixed number of steps per
tile (`renown.steps_per_tile`). `Renown.standing` sums the deeds that have reached a given cell, so
the same party is renowned in one valley and unknown in the next. Standing sets the greeting a
place gives you, moves its prices, and feeds the `renown` skill in dialogue checks.

**Stores, Gear and Stash.** `Loot.take` hands a find directly to the party member it most improves;
charms go into the player's pocket; anything nobody currently gains from is packed into the
marching stores (`GameState.stores`) to be swapped or sold later. Only items worse than anything
carried by anyone are liquidated on the spot. Camp provides an interactive strongbox stash
(`GameState.camp_stash`) for long-term reserves. Consumable draughts can be drunk from the packs on
the party screen or during battle as a bonus action.

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
