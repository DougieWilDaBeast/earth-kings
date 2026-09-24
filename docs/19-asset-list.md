# 19 — Asset list

Everything the game needs drawn, in the order it should be made, for generation in **PixelLab** and
cleanup in **Aseprite**. Asked for in [joint session 1](worldbuilding/voice-notes/2026-09-24-joint-session-1.md):

> "we need to have a full list of what potentially needs to be designed to fit the new world and to
> fit what's designed so far in terms of maps, characters, animations. enemies, abilities, like
> anything related to the game. And we're going to generate them using Pixel Lab."
> — dougie, 2026-09-24, session 1 [01:01:12]

## The deadline

> "I suppose another thing is, in three days, your monthly Pixel Lab AI will... Be reset to 0 credits
> used. So we do have like 15% left on that."
> — doug-md, 2026-09-24, session 1 [01:00:33]

**Credits reset on 2026-09-27, with 15% of the month left until then.** Whatever is unspent on the
27th is lost, so it should be spent. But the sprite size is undecided
([agenda item 9](worldbuilding/answers.md#what-is-still-to-decide)), and anything generated at the
wrong size is thrown away. So the 15% goes on **Tier 0: the size test**. Nothing in Tier 1 or later
is generated until the size is chosen.

**What the model does.** Measured from its official screenshots, _Dungeon Settlers_' characters are
about 13 × 22 art pixels — the **32×32 class**, not 16 and not 64
([investigation/07](investigation/07-dungeon-settlers-combat.md#13-sprite-size-and-frame-counts)).
So the real choice is 32 against the 64 already on disk, and 16 is the outlier.

## What exists

| Kind | On disk | State |
| --- | --- | --- |
| Units | 70 bodies in `art/units/` (73 templates in `data/units.json` share them), **64×64**, low top-down, 8 directions | Almost all **idle only**. Run cycles: `sworn_blade`. Attacks: `duck_wizard`, `ember_duelist`, `turret_cannon`, `storm_blade` (a slash). Death: `fox_knight`. `dirte` has a boulder hold |
| Items | 77 files in `art/items/` — food, potions, weapons, armour kits | Icons and in-hand weapons with per-facing offsets |
| Props | 135 files in `art/props/` — beds, chests, braziers, camp | Enough for towns and camp |
| Buildings | 31 in `art/buildings/` | Enough for current areas |
| World | 31 in `art/world/` — 30 holds and a tomb | Map markers |
| Tilesets | 8 in `art/tilesets/`, plus the unwired `art/map_kit/` | Battle and walk ground |
| UI | Frames, an emblem, season clovers | No ability icons, no status icons |
| Sources | `art/source/` — `.aseprite` files and references | — |

Each unit folder has a `metadata.json` with the PixelLab prompt, size, view and template it was made
with. **Keep writing it.** It is the only record of how to regenerate a character at another size.

## Conventions

- **One prompt, one row.** Every generation is logged in its folder's `metadata.json`: `prompt`,
  `size`, `view`, `directions`, `template`, and the date. A regenerated character keeps its id.
- **Four facings are used, eight are generated.** The battle uses north, south, east and west;
  diagonals are kept for later ([art/units/README.txt](../art/units/README.txt)).
- **Animations are states**: `art/units/<id>/<state>/<direction>/` for frames, as `sworn_blade/run`
  already does.
- **Aseprite for cleanup**: palette, outline, fixing hands and weapon pivots. Source files go in
  `art/source/`.
- **Dark fantasy** ([D40](06-decisions.md)). Muted palette, no bright cartoon saturation. The
  references in `art/source/` (`Dark-fantasy-clean-ui.png`) set the tone.

---

## Tier 0 — the size test (now, before 2026-09-27)

One question to answer: **64, 32 or 16?** `doug-md` pointed at _Dungeon Settlers_' small sprites
("the characters are 16" [01:08:57]). `dougie` is happy with what 64 has produced ("we can continue
almost sixty-four"). Real time with pause puts more units on screen at once and animates every
attack, and both push towards smaller.

_Dungeon Settlers_ pairs tiny sprites with **large hand-drawn portraits**, and one review singles that
out as why its permadeath lands ([18](18-combat-direction.md#what-is-known-before-the-deep-dive)).
That is worth copying whatever size is picked: small bodies to fight with, big faces to grieve.

| # | Generate | Why |
| --- | --- | --- |
| 0.1 | `sworn_blade` at **32×32**, 8 directions, same prompt as its `metadata.json` | A lead-sized body at the smaller size, directly comparable to the 64 on disk |
| 0.2 | `sworn_blade` at **16×16**, same | The _Dungeon Settlers_ end of the range |
| 0.3 | `goblin` at 32 and 16 | A small enemy — does it still read? |
| 0.4 | `club_ogre` at 32 | A large enemy — does size still say threat? |
| 0.5 | One **attack** animation for `sworn_blade` at the size that looks best | "Every attack animated" is the expensive part, and the frame count per size is what decides the monthly budget |
| 0.6 | One **portrait** for `sworn_blade`, if PixelLab does portraits well | Tests the small-body, big-face pairing |

**Done when** both founders have seen the three sizes side by side, in the battle scene, with four
units on screen, and the size is written into [06 — Decisions](06-decisions.md). Record what each
item cost against the 15% so the next month can be planned.

---

## Tier 1 — the combat prototype (after the reset)

What [M11](05-roadmap.md) needs to be playable, and no more. Every unit here needs the **fighting
set**:

| State | Frames (guide) | Notes |
| --- | --- | --- |
| `idle` | exists | Regenerate only if the size changed |
| `walk` | 4–6 | Point-and-click movement |
| `attack` | 4–8 | Melee swing, or draw-and-loose for a bow, or a cast — whichever the unit's basic attack is |
| `skill` | 4–8 | One generic ability pose; per-ability poses come later |
| `hit` | 2–3 | Readability at speed |
| `death` | 4–6 | Permadeath is the point; the fall has to be seen |

| # | Units | Why these |
| --- | --- | --- |
| 1.1 | `sworn_blade`, `longbow`, `hedge_priest`, `magic_swordsman` | One of each existing class shape — melee, ranged, healer, hybrid — for a party of four |
| 1.2 | `goblin`, `raider`, `wolf` | Three enemy behaviours: swarm, armed person, fast beast |
| 1.3 | One boss — `club_ogre` or `king_slime` | Bosses give everyone experience ([D37](06-decisions.md)); the prototype needs one to test it |
| 1.4 | **Ability effects**: slash, arrow, heal, one burst | The minimum to read a fight |
| 1.5 | **UI**: four ability-slot frames (Q W E R), cooldown sweep, pause banner, speed indicator, 6 status icons — stun, bleed, burn, provoke, vulnerable, charging | Real time needs these readouts; the statuses are the ones _Dungeon Settlers_ uses, as a starting set |

---

## Tier 2 — the sixteen

Once the first writing sitting has named some of them ([13](13-heroes-and-tempers.md)). Each of the
sixteen needs:

| Asset | Count | Notes |
| --- | --- | --- |
| Body, 8 directions, full fighting set | 16 | "Art before identity" still holds — reuse an existing body where one fits, then regenerate |
| **The shared mark** | 1 design, on 16 bodies | Tattoo or glowing eyes, same place on everyone ([D31](06-decisions.md)). Decide which before drawing any of the sixteen |
| Signature-weapon attack set | 16 | Sixteen ways to fight ([CH13](worldbuilding/answers.md)) means sixteen distinct attack animations |
| **Signature weapon** | 16 items | God-tier, recognisable at a glance lying on the ground in another world ([D33](06-decisions.md)) |
| Portrait | 16 | Big faces, if Tier 0 says yes |
| **Ghost** | 0 | Done with a shader over the existing body — translucent, pale, flickering. No generation |
| The carried mage | 1 extra pose set | Carried by someone: an idle and walk where he rides a bearer ([13](13-heroes-and-tempers.md#seeds-from-the-session)) |

---

## Tier 3 — the rest of the cast

The 70 bodies on disk, mostly idle only. [W11](09-wishlist.md) and [W28](09-wishlist.md) already
asked for this; the new fight makes it necessary rather than nice, because every unit that fights
has to animate every attack. Order by how often a unit is fought:

| # | Units | Count |
| --- | --- | --- |
| 3.1 | Faction ranks and champions (`data/factions.json`) — Heart Empire legions, Bamboo Court, the Tide, the Ooze, the Dusk, Ember Wilds, Broken Oath, the Wild, Freeholds, Titans | 50 bodies |
| 3.2 | Everyone else who fights — the old twelve heroes' bodies and the independents | the other 20, less townsfolk |
| 3.3 | Non-combat townsfolk (`peasant`, and whoever else never fights) | idle + walk only |

Log each against the month's credits. At the current count this is the bulk of the art bill, and it
can be spread over several months without blocking anything but polish.

---

## Tier 4 — the new world

What [17](17-the-sixteen-worlds.md) adds, in the order the milestones need it:

| # | Asset | For |
| --- | --- | --- |
| 4.1 | **The fall** — sixteen figures falling through cloud; a heavenly place breaking; a crater | The intro ([M13](05-roadmap.md)). Stills with parallax are enough |
| 4.2 | **Crash sites** — a scorched crater in each of: castle yard, forest, town square, field, ruin | Random landing ([D31](06-decisions.md)) |
| 4.3 | **The Tower** — one exterior, larger and stranger than `hold_spire`; a floor-exit portal | Every floor sends you back out ([D34](06-decisions.md)) |
| 4.4 | **The census** — sixteen sigils, lit or dark | Every five floors |
| 4.5 | **Campfire meditation** — seated pose for the lead; a ring of sixteen faint figures | Ghost communion ([D33](06-decisions.md)) |
| 4.6 | **A world ending** — the overhead shot of the map being consumed, in stages | The lead's death ([D32](06-decisions.md)) |
| 4.7 | **Gate interiors** as whole worlds — start with **an ice country** (ice elves) and **a desert** (scorpion things), both named in the session; tileset, 3–4 enemies, a boss each | [D35](06-decisions.md) |
| 4.8 | **The Adventurers Guild** — building, sign, interior, a job board | [D35](06-decisions.md), and the job log ([D38](06-decisions.md)) |
| 4.9 | **Gate rank markers** E–S, S being unmistakable | National-threat gates |
| 4.10 | **The contest** — a place outside time | [M17](05-roadmap.md); design first, art last |

---

## Tier 5 — every ability, every effect

`data/abilities.json` holds 40 abilities; generated skill trees draw from 9 themes (edge, ember,
storm, hunt, iron, vigil, hearth, mourning, wind) and 7 archetypes (blow, reach, loose, burst,
sweep, mend, rally). Effects should be drawn **per theme × archetype**, not per ability — 63 at most,
and far fewer if an archetype's shape is shared and only the theme's colour changes. That is also
the only way generated trees can look right, since nobody authored them.

| # | Asset | Count |
| --- | --- | --- |
| 5.1 | Archetype shapes — blow, reach, loose, burst, sweep, mend, rally | 7 |
| 5.2 | Theme palettes and particles — edge, ember, storm, hunt, iron, vigil, hearth, mourning, wind | 9 |
| 5.3 | Ability icons for the Q W E R slots, per theme × archetype | up to 63 |
| 5.4 | Status icons beyond Tier 1's six | as statuses are added |
