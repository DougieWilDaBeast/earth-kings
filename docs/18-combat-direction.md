# 18 — Combat direction

The founders agreed on 2026-09-24 to move the fight away from the turn-based tactics core and toward
the way **_Dungeon Settlers_** fights, with every attack animated the way **_Fire Emblem: Three
Houses_** animates it. They also agreed that **nothing gets built until a research deep dive into
_Dungeon Settlers_' combat is done**. This doc holds the direction, what the research has to answer,
and what the change costs.

The rule is [D36](06-decisions.md). The conversation is at [00:44:27] of
[joint session 1](worldbuilding/voice-notes/2026-09-24-joint-session-1.md).

## What was agreed

> "I think that we should take a lot of inspiration from this game called Dungeon Settlers. It has
> point and click, point and click to go where you want to go, but it's on this tile sheet."
>
> "Your characters automatically use their attacks, and you have QWER would be your abilities you
> want to use, or you can use auto abilities."
>
> "And, like, you can pause the game whenever you want, or you can speed up the game whenever you
> need, as well."
> — doug-md, 2026-09-24, session 1 [00:44:43]–[00:45:25]

> "Fire Emblem Three House animation style for combat, then Dungeon Settlers actual combat mechanics
> and click, click and play style and for speeding up and slowing down."
> — dougie, 2026-09-24, session 1 [00:47:30]

> "No, I think I think it's going the way you know you've said already for dungeon settlers and
> stuff."
>
> "I think it's I think it's just way better, yeah."
> — dougie, 2026-09-24, session 1 [00:48:20]

In short:

| | Today (M0) | Direction |
| --- | --- | --- |
| Time | Charge-time turns; the world waits for you | **Real time, pausable, speed-adjustable** |
| Movement | Pick a blue tile, then act | **Point and click** on the tile grid |
| Basic attacks | An ability you choose each turn | **Automatic** |
| Abilities | Everything the character knows, from a menu | **Four active on Q W E R**, Pokémon-style, plus **passives** that need no button; or hand them to **auto** |
| Presentation | A token or sprite turns and slides | **Every attack animated** — drawing the bow, loosing it, the hit |
| Party control | Squad phase, Tab between ready units | Select and order; pause to think |

Kept from what exists, unless the research argues otherwise: the square grid with height and move
cost, facing (side 1.2×, back 1.5×), generated battlefields from world terrain, falling and the
graces ([D11](06-decisions.md)), and `Q`/`T` autoplay and speed — which is already half of "pause and
speed up" on the world map.

## Why

`BN6`: both founders are afraid of **fights that are the same moves every time**. `BN2`, inferred:
the fight is the one thing that has to be right. The current core is sound but slow, and turn-based
grids are where "the same moves every time" lives. Four active abilities force a loadout decision
before the fight rather than a menu scroll during it.

## What is known before the deep dive

A first look on 2026-09-24, from the store page and the developer's own replies. Enough to aim the
research, not a substitute for it.

- **It is new.** _Dungeon Settlers_, by CanOpener (co-published by WhisperGames), entered Early Access
  on **2026-09-04** and expects to stay there about two years. Its combat will keep changing under us.
- **Real time with pause, no turn or round limits.** Parties of **up to four**. Status effects named
  on the store page: stun, bleed, burn, provoke, vulnerable, charge attacks, summons.
- **Skill trees by weapon and school** — sword, mace, bow, fire magic — plus "six major abilities
  and talents" per member.
- **Auto-skill use is a per-unit toggle**, added after players asked for it. Auto-cast works down the
  quick slots in order, using the first skill that is off cooldown. The developer: "Choosing the
  right moment to use each skill is an important part of the tactical experience we want to
  deliver", and auto may end up limited to low difficulty.
- **Permadeath**: "Once dead, there is no coming back."
- **Tiny sprites, large hand-drawn portraits.** One review names that pairing as why a death lands.
  It matters for the sprite-size question ([19](19-asset-list.md#tier-0--the-size-test-now-before-2026-09-27)).
- **Players complain about micromanagement** — pausing constantly for everything. The same risk
  applies here, and it is the argument for a good auto mode.

Sources: [Steam store page](https://store.steampowered.com/app/2798330/Dungeon_Settlers/) ·
[Steam discussion on auto-battle, with developer replies](https://steamcommunity.com/app/2798330/discussions/0/688615158420114690/) ·
[GenerationAmiga preview](https://www.generationamiga.com/2026/05/25/dungeon-settlers-wants-you-to-build-a-home-then-send-everyone-into-hell/) ·
[fan wiki, unofficial](https://dungeon-settlers.com/skills-and-combat)

## What the research has to answer

The deep dive is its own piece of work — [roadmap](05-roadmap.md) M10. It should come back as a
short written report in `docs/investigation/`, with clips or screenshots, answering:

**The fight itself**
1. What exactly does a player control moment to moment — each unit, the group, or a leader others
   follow? How are orders given to several units at once?
2. How is "automatic" decided — nearest enemy, a threat table, a role, a script the player sets?
3. How do **auto abilities** work — a toggle per ability, conditions, priorities?
4. How are ability cooldowns, resources (mana, stamina) and cast times done? Can a cast be interrupted?
5. Does the tile grid matter mid-fight — does movement snap to tiles, is there facing, height,
   flanking, area shapes on tiles?
6. What does **pause** allow — issuing orders only, or also swapping loadout? Is there auto-pause on
   events?
7. How long is a typical fight, and how many units a side?
8. How is it made readable at speed — telegraphs, damage numbers, health bars, target lines?

**Around the fight**
9. How are abilities acquired and slotted — the four-slot limit, and how swapping works outside a
   fight?
10. How do levels, gear and skills combine — what gets stronger by use, and what by experience?
11. What happens when a unit dies?
12. What of its structure does the settlement-building half depend on? (`doug-md`: "we don't need
    that".)

**Art**
13. Sprite size and animation frame counts per action — the session thought 16- or 32-pixel
    characters. See agenda item 9 and [19 — Asset list](19-asset-list.md).
14. How it keeps many small animated units legible on one screen.

**For Earth Kings specifically**
15. What in [02 — Design](02-design.md#battle) survives, what is replaced, and what the smallest
    playable prototype is.

## What it costs

This is the largest change since the project began. Honestly stated:

- **`src/battle/` is largely rewritten.** `TurnManager` (charge time) goes; `battle.gd`'s phase
  machine becomes a real-time loop with pause; `EnemyBrain` stops returning one plan per turn and
  starts choosing continuously. The [mind seam](03-architecture.md) — AI returns plans, only the
  engine mutates state — still holds and should be kept.
- **`AbilityResolver`'s maths can mostly stay.** Damage, facing, splash and targeting rules are not
  turn-specific; timing is.
- **Every ability needs a cooldown and a cast time**, and every unit a loadout of four.
- **Leans tied to turns need new values**: J's +20 opening charge time and P's +1 move point
  (`MX6`, `MX7`).
- **The smoke tests** (`battle_smoke_test`, `controls_smoke_test`) drive a turn loop and are rewritten
  with it.
- **Animation is the real bill.** "Every attack animated" means frames for attack, cast, hit and death
  for every unit that fights — see [19](19-asset-list.md).

The first step is a **prototype in a separate scene** — one party, one enemy group, real-time with
pause, four abilities each — played against the current battle before either is retired.

## Getting stronger

Settled in the same session, and bound up with the fight ([D37](06-decisions.md)):

- **Proficiency by use**, Kenshi-style: every weapon type and kind of fighting has its own level,
  which rises by doing it. A great weapon in unpractised hands is not a great weapon.
- **Experience only from the first kill of each kind of enemy**, per character (_Surviving the Game
  as a Barbarian_). Killing the same kind again teaches proficiency, not levels. It stops experience
  being farmed and gives the map a reason to be explored.
- **Assists count.** Being part of a fight without the last hit is an assist; enough assists on a kind
  of enemy give its experience. Five was agreed; ten for ordinary grunts was also said (agenda
  item 8). The last hit gets it outright. **Bosses give everyone involved their experience.**
- **Each level costs more than the last**, Souls-style. The current curve (`20 + level² × 6`) already
  rises; the new rule changes where experience comes from, not the curve.
