# 18 — Combat direction

The founders agreed on 2026-09-24 to move the fight away from the turn-based tactics core and toward
the way **_Dungeon Settlers_** fights, with every attack animated the way **_Fire Emblem: Three
Houses_** animates it. They also agreed that **nothing gets built until a research deep dive into
_Dungeon Settlers_' combat is done**. This doc holds the direction, what the research had to answer,
what the change cost, and [the fight](#the-fight) as it is built: since 2026-10-12 it is the only
fight in the game ([D64](06-decisions.md)).

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

| | Before (M0–M10) | Direction, built in M11 |
| --- | --- | --- |
| Time | Charge-time turns; the world waits for you | **Real time, pausable, speed-adjustable** |
| Movement | Pick a blue tile, then act | **Point and click** on the tile grid |
| Basic attacks | An ability you choose each turn | **Automatic** |
| Abilities | Everything the character knows, from a menu | **Four active on Q W E R**, Pokémon-style, plus **passives** that need no button; or hand them to **auto** |
| Presentation | A token or sprite turns and slides | **Every attack animated** — drawing the bow, loosing it, the hit |
| Party control | Squad phase, Tab between ready units | Select and order; pause to think |

Kept from what exists, unless the research argues otherwise: the square grid with height and move
cost, facing (side 1.1×, back 1.2×, [D59](06-decisions.md)), generated battlefields from world terrain, falling and the
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

**First pass done 2026-09-24:** [investigation/07](investigation/07-dungeon-settlers-combat.md) answers
these from everything CanOpener has published, and ends with the ten that need an hour of hands-on
play.

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

## What it cost

This was the largest change since the project began. What the move took, now that it is made:

- **The turn-based battle is gone.** `TurnManager` (charge time), `battle.gd`'s phase machine,
  its HUD and `EnemyBrain` were deleted on 2026-10-12 when `dougie` asked for the turn-based fight
  to be retired ([D64](06-decisions.md)). What both fights shared stays in `src/battle/`: the grid,
  the pathfinder, `Unit` and `AbilityResolver`. The [mind seam](03-architecture.md) — AI returns
  plans, only the engine mutates state — holds in `SkirmishBrain`.
- **`AbilityResolver`'s maths stayed.** Damage, facing, splash and targeting rules were not
  turn-specific; timing was.
- **Every ability has a cooldown and a cast time**, and every unit up to four quick slots.
- **Leans tied to turns have new readings**: J's +20 opening charge time is acting at once, P's +1
  move point is walking pace (`MX6`, `MX7`).
- **The smoke tests** that drove the turn loop drive the real-time fight; the checks
  `battle_smoke_test` held that still meant something (allies, auto from outside the fight, a
  whole fight resolving) moved into `skirmish_smoke_test`.
- **Animation is the real bill**, being paid unit by unit. "Every attack animated" means frames for
  attack, cast, hit and death for every unit that fights — see [19](19-asset-list.md). The early
  game's units have theirs since 2026-10-13.

## The fight

**Built 2026-09-24** as a prototype in `src/skirmish/` ([M11](05-roadmap.md)), following the plan
in [investigation/07](investigation/07-dungeon-settlers-combat.md#the-smallest-playable-prototype).
Both founders chose it over the turn-based battle ([D58](06-decisions.md), [D63](06-decisions.md)),
and since 2026-10-12 it is **every fight in the game** ([D64](06-decisions.md), [D65](06-decisions.md)):
a band on the road, a gate floor and its objective, the Tower, a Guild muster, a fight beside
allies, the coliseum, and training. The scene key is `skirmish`.

**To play it:** walk into anything that fights. Or Title → **Training** → pick an enemy and a
count → **Fight this**, or `godot --path . res://tests/bench.tscn -- --scene=skirmish --play` for
a wild fight with the starting party. The checklist is [10 — Manual tests, E2](10-manual-tests.md).

| Control | Does |
| --- | --- |
| Left-click a party member · drag a box · `1`–`4` · `Tab` | Select one · select everyone the box touches · select by number · select everyone (Shift adds to the click, box or number) |
| Right-click ground | Move there. Several selected spread out around the spot |
| Right-click an enemy | Go after that one, and only that one |
| Right-click a downed ally | The nearest selected member goes to help them up |
| `Q` `W` `E` `R` | Arm a skill; left-click the target (or the ground, for splash); right-click cancels |
| `A` | Auto Skill on or off for the selected — on by default |
| A draught or herb on a party card | That fighter uses it: 1.5 s, open to blows but not to stuns ([D59](06-decisions.md)) |
| `H` | Hold: stay put and only hit what is in reach |
| `Space` (`command_wait`) | Pause. Orders given while paused are carried out on resume. The fight **opens paused** |
| `T` (`battle_speed`) | Speed x1 → x2 → x3 → x5 ([D189](06-decisions.md); was x1.5 and x2, D59) |
| `Z` | Auto-pause: off → when someone goes down (the default) → also when a skill comes back for a unit with Auto Skill off. Kept for the session |
| `N` | The journal |
| `Esc` (or Back, or a pad's B) | Puts a readied skill away; with none readied, the menu |

**What it does**

- **A fixed-tick simulation** (20 ticks a second) so the fight plays the same at any speed and a
  test can run one in a moment. Movement is drawn smoothly between ticks. While the menu, the
  journal or a conversation is open in front of it, the clock waits (**Inferred**).
- **Tile to tile**, one unit per tile, the tile claimed as the step starts. Allies block enemies and
  enemies block allies. Pace comes from move points; terrain cost still slows you.
- **Basic attacks on a tempo** from the speed stat: every 1.6 seconds at speed 10.
- **Quick slots** are the character's abilities after the first damaging one, which is the basic
  attack. Each has a `cooldown` and a `cast` in `data/abilities.json`; skills with a wind-up show a
  bar and follow their target, but fizzle if it falls or gets away.
- **Auto Skill**, left to right, only when a skill is ready and already in reach; heals only on an
  ally at or under 60%.
- **Enemies** pick the nearest standing foe and stick with it (unless their doctrine's focus,
  below, makes another worth the walk), use their own skills the same way, and never pick on the
  downed. A party member not told otherwise fights anything within six tiles,
  and joins in once any companion is fighting. **Allies** (a Guild muster, a fight the world puts
  beside you) are on the party's side, think as enemies do, and cannot be picked or ordered.
- **A party playing itself** (`Q` on the road, a soak) does not wait: the fight opens running,
  auto-pause never stops it, a menu does not hold the clock, and the party goes looking for the
  fight wherever it is rather than within six tiles. Switching autoplay on mid-fight starts a
  paused clock; `Q` mid-fight takes the party back and pauses for the first order.
- **Near death**: a party member at zero is down for twelve seconds, and a companion who reaches
  them and kneels for two gets them up at a quarter of their health. Enemies at zero are gone.
- **Facing still counts**: units face where they step and what they hit, and side and back hits
  deal 1.1× and 1.2× ([D59](06-decisions.md)).
- **The mind seam holds**: `SkirmishBrain` returns choices and only `Skirmish` changes the fight.
- **The temper leans carry over.** T's damage and P's extra move point (as walking pace) were
  already in the numbers. J's opening charge time becomes acting at once: a Set temper takes its
  first look and first swing the moment the fight starts, while everyone else waits a beat. F's
  rescue lean comes in with the graces, below.
- **Passives** (2026-10-12), from `data/skirmish.json`: every unit gets up to three, taken in
  order from its template, its classes and the abilities it knows. **Inferred** — which passive
  goes with which class is the build's guess, and the founders have not picked any of them:

  | From | Passive | Does |
  | --- | --- | --- |
  | Sworn Blade | Shieldwall | Allies within 2 tiles take 15% less damage |
  | Longbow | Keen Eye | +15% chance of a critical (everyone has 5%; a critical is ×1.6) |
  | Hedge Priest | Hearthglow | Allies within 2 tiles recover 1% of their health a second |
  | Magic Swordsman | Echo Blade | A basic attack strikes twice one time in five |
  | Raider | Bloodthirst | Heals for 20% of the damage dealt |
  | Wildling | Hunter's Angle | Side and back hits deal 30% more, on top of facing's 1.1× and 1.2× |
  | knows Second Wind | Catch Breath | Out of the fighting for 4 seconds, 4% of health a second |
  | knows Riposte | Barbed Guard | A blow from the next tile comes 30% back on the striker |
  | knows Stand Fast | Last Stand | 35% more damage at or under 35% health |
  | knows Grief | Mourner's Haste | Every skill comes back when an ally goes down |
  | Brigand chief | War Cry | Allies within 2 tiles attack 20% faster |
  | Wolves | Pack Hunter | 15% lifesteal and 15% more from the side or behind |

  Auras of one kind do not stack, and guard is capped at half. The party card shows each unit's
  passives under its name, with what they do on hover.
- **Enemy roles** (2026-10-12, **Inferred**), from `roles` in the same file. A **Charger** (the
  brigand, every beast) sprints at anyone three or more tiles off and its first blow lands 40%
  harder. A **Skirmisher** (the brigand archer, anything whose basic attack reaches three tiles)
  backs off when someone closes to within a tile, at most once every three seconds so it can still
  be pinned. A **Mender** (anything carrying a heal it can throw two tiles) heals its own side
  under 85% health instead of 60%, and hangs back the same way. Everyone else is a Brawler.
  Hovering any unit shows its role and passives.
- **A mend grows with its caster's level** (2026-10-19, [D284](06-decisions.md), **Inferred**). A
  spell that heals (Mend, Warding Touch, Stand Fast, Hearthlight, Second Wind, Soothing Spring, Hold
  Fast) heals its power up to level 3, then 10% more for every level after (`heal_from_level`,
  `heal_per_level` in `rules`): 2.4 times at level 17. Health grows with every level and a spell's
  power did not, so Vesta's Mend was a tenth of Juno at level 1 and a thirtieth at 17. Draughts
  already grow by kind, and regeneration by share of health. Both sides' menders grow alike.
- **Energy, stuns, charged spells, items and shields** (2026-10-12, [D59](06-decisions.md), from
  `doug-md`'s twenty hours of _Dungeon Settlers_). Each card has an energy bar of ten pips; skills
  drain it and a fighter who runs dry is **tired**, swinging only, until it is half full again.
  Shield Bash **stuns** for 1.5 s and breaks off whatever its target was winding up. Ember, Tidal
  Surge, Thunderhead, Pyre and Blizzard **charge** for 2.5–3 s and land 1.6× harder, so they are
  worth breaking. Draughts and herbs sit as buttons on each card. A **shield bearer** sometimes
  blocks a sword swing from the front or side ("Blocked"). The numbers are in `data/skirmish.json`
  and **Inferred**.
- **Feel, without art** (2026-10-12). Damage numbers jump off whoever is hit (gold and big for a
  critical, green for heals, violet for thorns), the struck unit flashes white, the striker
  lunges a few pixels at its target, a critical or a blow worth a fifth of someone's health
  freezes the clock for 70 ms, and a death rings out and shakes the camera (harder for one of
  yours). Skills on the cards are tiles with a cooldown sweep that flash when they come back, and
  clicking one readies it; the touch skill buttons sweep too. The row of cards grows up from the bottom edge as tall as its cards need, so six with a pouch stay on the screen ([D231](06-decisions.md)); `tests/hud_shot.tscn` photographs it. All in `src/skirmish/skirmish_fx.gd`
  and `skirmish_slot.gd`; the sizes are `rules` in `data/skirmish.json`. Trees stand on the crags,
  walls and some of the edge, and bushes in the brush (`decor` in the same file).
- **Sound and a level gained** (2026-10-13). Swings, bowshots, hits and criticals, blocks, a spell
  gathering and going off, heals, stuns, draughts, a fall and the end of the fight are heard
  ([D76](06-decisions.md), `data/sfx.json`). Whoever gains a level mid-fight flickers gold, with a
  ring and the new level rising off them, and a line at the top right says so ([D77](06-decisions.md));
  nothing stops the fight. A skill's name shrinks or wraps to fit its tile.
- **What a move does is seen on whoever it lands on** (2026-10-17, [D192](06-decisions.md), `dougie`:
  "when we Knockback a character i want to see them get knockbacked at least a tile"). Until then
  only a stun and a heal did anything; now a skill's effect shows on the body, and so does a
  move shrugged off or stepped out of. All **Inferred** (agenda 123):

  | Move | What it does, and how it shows |
  |---|---|
  | Haymaker | Knocks back 2 tiles: the body slides, "Knocked back", dust where it stood |
  | Kick, Shield Bash, Gust, Tidal Surge | Knock back 1 tile (Shield Bash still stuns) |
  | Undertow | Drags them in a tile ("Dragged in") and slows them 2 s |
  | Hamstring, Frostbite, Glacial Chill, Blizzard, Ice Shard | Slow (steps 45% slower, swings 20%): frost round the feet, a snowflake icon, "Slowed" |
  | Ember, Scorch, Pyre, Firebrand | Burn 2 to 3 s, 12% of the blow a second: flames on the body, orange numbers, "Burning" (Vesta's fire burns only the dead) |
  | Dart | Bleeds 4 s, 10% of the blow a second: falling drops, red numbers, "Bleeding" |
  | Sunder | Takes 15% more for 6 s: a red crack across the chest, the cracked-shield icon, "Sundered" |
  | Earthshake, Crushing Wave | Knocked down 1 s and 0.8 s: the body tips over flat, breaks a cast, gets up after |
  | Shield Bash, Door Shut | Stun, as before |

  Shrugged off, in silver over the head: a knockback into a wall or a body says **Pinned** and
  jolts them; a keeper or chief is **Unmoved** (never shoved or laid flat); a body as big as an
  ogre's is shoved a tile less, so a kick says **Unmoved** and a haymaker moves it one; Liber
  **Keeps footing** and stays **Steady** against stuns; the fire creatures are **Fireproof**, the
  frost wolves **Shrug off** a slow, slimes, wraiths and the tree sentinel have **No blood**. A
  fighter who steps out of a wind-up sees "Dodged!" when it comes down; a skill on empty ground
  says "Missed". Caesar taking part of a blow says "Covers"; Cato digging in says "Set"; Saturn's
  and Ceres's ground puts the same frost and icon on whoever it slows. A fighter's plain swing
  never carries these, even where it is the same move (the fire mages' ember, the frost wolves'
  frostbite), or every swing would. `src/skirmish/skirmish_conditions.gd`;
  `conditions` in `data/skirmish.json`. Before and after shots: `tests/fight_effects_shot.tscn`.
- **Heights in a fight** (2026-10-21, [D313](06-decisions.md), from both founders at the founders' meeting,
  [D287](06-decisions.md): "a fighter on a height can be shoved off it"). A fight laid over ground with heights
  ([D308](06-decisions.md), the wind scarp) takes the ground's heights and slopes: a fighter steps down
  anywhere and up only at a slope, so the brains walk to the slopes; a body is never shoved up a ledge
  (**Pinned**), and shoved off one it falls, **Off the edge**, a tenth of its health for every height and
  knocked down 1.2 s where it lands. A hand-made field's heights stay the jump's. **Inferred** (agenda 221).

**Reach.** A blow at arm's length (`range` 1) reaches the eight cells round a fighter, the diagonals too
([D246](06-decisions.md)): with only the four beside, two fighters a diagonal apart stepped sideways
together for ever. Anything with a longer reach counts steps.

**Coming in** — everything the turn-based battle did on the way into a fight, it does
([D65](06-decisions.md)). A band met on the ground is fought on that ground ([D98](06-decisions.md)),
and since [D204](06-decisions.md) with no stop before it and no box round it: the fight is on as the
band shouts (about a tenth of a second, was over a second of heads turning and a rush), the band
closes in fighting from where it stood, and the field (24×16 to 36×24 cells, six round everyone) has
no edge drawn and nothing dimmed; the edge shows faintly only while the pointer is out past it. Since
[D207](06-decisions.md) no fight in a run has a screen of its own: Tower floors 6 up are walked, a
roadside fight is fought where its scene stands, and a town's or a captive's fight just ahead of the
party; only the hidden training ground and coliseum keep the fight screen.

- the field is the encounter's map (or an authored one), with the party mustered on its spawns,
  the enemy at their levels (a levelled foe is a throwaway character raised by
  `Progression.raise_quietly`), any keeper marked, and **allies** on the party's side;
- an **ambush** gives the party the jump: it acts at once, and the other side's opening is held
  back `ambush_head_start` seconds (2, **Inferred**) — the real-time form of first-round initiative;
- a nemesis's **confrontation** line, the number of allies, and the gate's **objective** are said
  in the log; on a heart floor the heart is marked on the ground;
- anything the party has not met before opens a page in the **journal** (not in a sandbox);
- `EventBus.battle_started` is told the map.

**On the ground it is dangerous, and it turns** ([D272](06-decisions.md), call BQ, 2026-10-19).
Before, every fight on the land was won: hits on a company in good iron landed for 1 or 2, and
nothing in a fight asked anything. Now, from `ground` in `data/encounters.json` (every number
**Inferred**, agenda 183):

- against a company of two or more, a band of the land stands `level` 2 higher (on the First Hour
  setting that takes its -2 back off, so a band is at the company's level) and comes **as many as
  the company**: the rest were in cover, and the log says "2 more of them come out of cover". A lead
  walking alone keeps [D211](06-decisions.md)'s band, two levels down and its own size;
- its foes, and a roadside scene's, **bite** 1.25 times their level and **graze**: every blow gets at
  least 30% of its weight past armour (`AbilityResolver.apply`, the `graze` meta), so `max(1, hit − defence)`
  no longer takes a wolf's bite to 1;
- **the fight turns**: the first time one of the company falls under 45% of their health, a fight
  played by hand stops, and a card asks what now. **1 Stand** (fight on), **2 Pull them back** (the
  hurt one leaves the field at once, safe, and the rest fight on without them; not offered when they
  are the whole company), **3 Break off** (everyone standing leaves the field at once, a quarter of
  the silver carried is thrown behind, nothing is won, the band is still out there, and anyone
  already down is left to it). Space is Stand. It asks once a fight; Auto fights on and says so.
  The Tower and the gates are not touched.

Measured on the ground (Cato, Vesta and Iris at levels 4 and 8 against three wolves, hands off,
`.art_stage` probe of `area_scene`): before, every fight won with enemy hits of 1 to 2. After,
standing won 11 of 12, the fight turned in 8 of 12, 6 to 15 seconds in, and Cato came out at 7% to
55%; the one loss was the whole company. Pulling Cato back saved him every time, and Vesta and
Iris then won 2 of 6 alone; breaking off saved everyone for the silver. A first pass at bite 1.4
and graze 0.35 lost 5 of 12 standing and was too much.

**Winning** is routing the other side, unless a gate says otherwise: on a **keeper** floor the
fight is won the moment every keeper is down, and on a **heart** floor the moment a party member
stands on the heart ([D45](06-decisions.md)). Losing is every party member down.

**While it runs**, it writes onto the world as the turn-based battle did:

- **Experience** from the first of each kind to whoever landed the blow, an **assist** to everyone
  else standing on the party's side, half the assists for whoever was **healed** by the killer's
  healer this fight, and a keeper teaching everyone ([D37](06-decisions.md), [D54](06-decisions.md));
  a blow turned back by Barbed Guard counts as the guard's kill.
- **Practice** ([`Proficiency`](../src/chronicle/proficiency.gd)): every skill that lands counts
  once, however many it caught; basic swings come several times as often as a turn did, so every
  third one landed counts (`swings_per_practice`, **Inferred**).
- **The journal**: being hit teaches what a thing does, hitting it what it wears, putting it down
  how much of it there is.
- **Draughts and herbs** drunk come out of the stores.
- **A fall the company cannot reach is settled for real.** When the twelve seconds run out,
  `Fate.resolve` rolls the graces and applies what lands — a charm is spent, a prisoner taken —
  and `EventBus.character_fell` is told. Saved by a grace, the fighter is back up in the fight at a
  quarter of their health; pulled clear (on a difficulty without permadeath), taken or dead, they
  are out of it, and the dead get a memorial and the threads' notice (`Skein.on_character_fell`).

**On the way out**:

- anyone still standing carries their wounds out as a share of their health (with the
  difficulty's floor), and has their reading reinforced;
- anyone still down when the field is **won** is carried off by the rest, at one hit point
  (**Inferred**); anyone still down when the company is **beaten** has nobody left to reach them,
  and falls for real as above;
- the lost leave the marching order, a won map is marked cleared, `last_victory` is set, and
  `EventBus.battle_finished` is told `{victory, map_id}`;
- after two seconds the fight hands back to its `return_scene`, with its `return_payload`.

**A sandbox fight** (`sandbox` in the payload: training and the coliseum) writes none of that. The
run's ledger is switched off for it, nobody's fall is settled (the graces roll through
`Fate.roll`, capture left out and no charm spent), the stores are only counted (the
`training_pouch` stands in when they are empty), and at the end the party is healed — or, on the
sand, carries its wounds into the next round and `arena_victory` is set. Experience and practice
come only if the payload says `learn`, as the coliseum's waves do for the copy of the company it
sends out (**Inferred**).

**The knobs**, all in `src/skirmish/skirmish_rules.gd`: `HEALTH_SCALE` (everyone fights with 3×
their health — at 1× fights ended in four to seven seconds, before there was anything to pause
for), `NEAR_DEATH`, `AID_TIME`, `PARTY_AGGRO_RANGE`, the attack tempo, the step pace, and the
default cooldown and cast formulas; and in `data/skirmish.json`, every passive, role and feel
number, `ambush_head_start` and `swings_per_practice`. The smoke test's proving ground — three
level-1 characters against six level-8 brigands — ends in about 20 seconds, and the party wins.

**What it does not do yet**

- **Animations for everyone.** Since 2026-10-13 a unit with move art walks, swings, casts, flinches
  and falls ([W28](09-wishlist.md#w28--animations-wired-to-what-is-on-disk)); the early game's units
  have it. The rest still slide and turn on their standing pose until drawn ([19](19-asset-list.md)).
  The fight effects and status icons are drawn since 2026-10-13 ([D82](06-decisions.md)).
- **A multi-order queue.**
- **Balance.** Every number is a first guess. Enemies still hit for single digits against a party
  that hits for thirty. The run's ledger counts damage at fight scale, three times what the
  turn-based fight counted.

## Tactics

**Built 2026-10-17** ([D187](06-decisions.md), call BB). Until then every fighter, on every side,
walked to the nearest foe and stood swinging on a timer: `dougie` saw it in the who-wins clips
("they just stand and bang") and in the game. One brain thinks for everyone (enemies, allies, the
party fighting on its own, Auto, both leads in a bout), so the tactics are in the brain
(`SkirmishBrain.pick_tactic`, `doctrine`, and the focus in `pick_target`) and change every fight in
the game. They are hand-written rules, not a learned model: they run at once in the browser and on
phones, a seed still gives the same fight, and every move can be read and tuned in
`data/skirmish.json` → `tactics`. What a learned model behind the same seam would cost, and the
offline table to try before one, is [investigation 12](investigation/12-a-small-model-for-fight-plans.md) ([D298](06-decisions.md)).

Each fighter has a **doctrine**: the lead's own (`leads`), else its enemy role's (`roles`), else a
brute's. A doctrine is the moves it tries, in order, and its **focus**: whom it would walk further for.

| Move | What the fighter does | Word over its head |
| --- | --- | --- |
| Dodge | In the last 1.6 s of a wind-up of a second or more that would land on it, steps out of the blast; aimed at it from close by, steps out of the caster's reach, so the skill fizzles | dodges |
| Kite | Its swing reaches two tiles or more and a foe is at its elbow: steps back, keeping that foe in reach (every 2.5 s) | falls back |
| Flank | It swings up close and the foe is facing it: circles to the side or back, where every blow lands harder (every 2.5 s, 1.5 s with a passive for it) | circles |
| Guard | A friend within 4 tiles is under half health with a foe on them: steps in beside them and takes that foe on (every 3 s) | guards Vesta |
| Hang back | A healer with friends fighting in front: keeps 3 tiles from every foe, and does not walk in to swing | hangs back |
| Break off | Under 30% health with a friend still fighting: gets 4 tiles clear for a while (every 8 s), where Catch Breath and its like mend | breaks off |
| Rally | The player's party only ([D281](06-decisions.md)), tried first after dodge: the lead is under half health with a foe on them, and this companion is within 8 tiles: comes to stand between them, or back beside the lead (every 2 s) | stands by Juno |

| Doctrine | Moves | Focus (tiles of walking a foe is worth) | Who |
| --- | --- | --- | --- |
| Brute | dodge, flank | none: nearest | enemies without a role, beasts' companions |
| Striker | dodge, flank, break off | hurt 1.5, marked 1, healers and shooters 1.5 | Ultor, Ares, Liber, Cassius, Pluto, Saturn, Janus; chargers |
| Ranged | dodge, kite, break off | hurt 1.5, marked 1 | Atlas, Iris, Diana; skirmishers |
| Guardian | dodge, guard, flank | hurt 0.5 | Caesar |
| Anchor | dodge, guard | hurt 0.5 | Cato (standing still is his Set) |
| Rooted | dodge | hurt 0.5 | Ceres (standing still plants her tile) |
| Keeper | dodge, hang back, kite, break off | hurt 1, marked 1 | Vesta, Juno; menders |
| Leader | dodge, guard, flank, break off | hurt 1, marked 1, healers and shooters 0.5 | Bellona |

**The party keeps together** ([D281](06-decisions.md), `keep_together`): besides rallying, no move
of the player's party (kite, hang back, break off) takes a fighter further than 3 tiles (`keep_with`)
from every friend still standing, and nobody hangs back from a foe already at their elbow hitting them;
they fight it. Before this, Juno (a keeper who swings up close) hung back from whatever came at her,
so she hardly swung, and the foes chasing her drove her alone to the edge of the ground, where she
fell. Foes, allies of a fight and the who-wins bouts fight as they did.

A fighter keeps its foe unless another is worth 1.5 tiles more (`switch_margin`), so nobody
flickers between two. Everything here is **Inferred** (agenda items 116 to 118), from the founders'
call to make fighting tactics "a much larger portion of the game".

**What it did** (who-wins table, level 5, two seeds, 480 bouts, before and after): bouts run longer
(25 s in the middle before, 32 after) and more reach 90 s (47 before, 74 after), because the ranged
now keep away. Iris went from 13% to 37%, Diana from 62% to 73% (she shoots from behind her wolf),
Atlas from 55% to 57%; the close fighters lost a little (Ares 60% to 52%, Cassius 60% to 53%).
Janus (20% to 13%) and Pluto (23% to 20%) still lose most one against one.

### Stances

**Built 2026-10-17** ([D209](06-decisions.md), for [D195](06-decisions.md), call BC). The tactics
above were watched, not played; a stance is the player's say in them. Each party card shows its
fighter's stance as a word beside the name. A click (a tap) on the word steps to the next; with
fighters picked, a key each sets it (O, F, B, G, H, all rebindable in Controls). A stance only
changes which of the fighter's doctrine moves are tried first and which are left out, and adds one
move of its own (Guard's escort); no number changes. It is kept on the character, so the next fight
and the save keep it. Enemies, allies and anyone while the game plays itself (Auto, the who-wins
bouts, the soak and the bot climbs) fight their own way whatever the card says, and the card's word
greys out under Auto.

| Stance | Key | What changes | Tried first | Left out |
| --- | --- | --- | --- | --- |
| Own way | O | nothing: the doctrine as it is (the default) | | |
| Close in | F | goes and finds the fight anywhere on the field, as Auto does | dodge, flank | kite, hang back, break off |
| Keep away | B | keeps a gap while friends fight; a bow or a spell keeps shooting, a sword waits | dodge, kite, break off, hang back | flank, guard |
| Guard | G | steps in for a hurt friend; more than 2 tiles from the leader, walks back beside them (every 2 s; "keeps by Cato") | dodge, guard, escort | break off, hang back |
| Hold | H | keeps this ground and fights only what comes into reach, as H always did; H again is Own way | | |

`data/skirmish.json` → `tactics.stances` holds each one's word, key action, moves and tip, and
`escort_reach` and `escort_every` the new move's two numbers. `SkirmishBrain.moves` puts a stance
on a doctrine; `Fighter.set_stance` and `playing_stance` keep it and say when it counts.

**What it did.** On Own way nothing changed: six who-wins bouts (seed 7, level 5) came out the same
to the second as on main, and the soak, the climb suite and every suite pass. On the proving ground
(Cato, Vesta and Iris against six brigands at level 9, twelve seeds each, the whole party in one
stance) every stance won all twelve: Own way in 38 s with two thirds of the party's health left,
Close in 24 s (0.74), Guard 28 s (0.67), Hold 59 s (0.74) and Keep away 68 s (0.59). So a stance is
a real choice and none of them throws a fight. The words, the keys, the escort's two tiles and that a
stance lasts between fights are **Inferred** (agenda 124 and 133).

### Formations

**Built 2026-10-20** ([D305](06-decisions.md), meeting six's piece E1, from [D289](06-decisions.md)).
`doug-md`: "the healer at the back, heavy hitters at the front, others on the flanks (a diamond for
four, a pyramid of one, two and three for six)". Five shapes, in `data/skirmish.json` → `formations`,
each a set of cells round the lead, who is always the origin, so a shape turns with whoever is played:

| Shape | Who stands where (the lead at ·) |
| --- | --- |
| Line | everyone abreast of the lead, blades to either side |
| Column | single file behind the lead; the mender last |
| Diamond | a blade ahead, one at each flank, the mender behind |
| Wedge | the lead at the point, blades at each shoulder, the rest behind them |
| Pyramid | one, two and three: the lead, two blades, then three |

Companions are dealt slots by what they fight with: a mender or a shooter (the ranged and keeper
doctrines, or a mend or a bow read from a recruit's abilities) to the back line first, one who swings
up close to the front, anyone else to the flanks; the same party is dealt the same way every time. The
player picks a shape on the lead's party sheet (*Formation: Diamond*; a tap steps to the next) or
leaves it on *Auto*, which picks by how many walk (two abreast, three a wedge, four a diamond, five a
wedge, six a pyramid). The pick is kept in the save.

**Walking**: the followers walk to their slots round the lead, 40 pixels a slot, and wherever a slot
cannot be stood on (a door, a wall, a narrow way) that follower falls back to the trail behind the
lead, so a corridor still files them. **Fighting**: until anyone of the party is in contact with a foe,
a companion with nothing else to do falls in to its slot ("falls in", every 1.5 s, the last move tried,
so a stance's own come first); a companion standing within a tile of its slot takes 8% less of every
blow (`hold_guard`), the Formation aura's idea as the bonus for holding one. Enemies, allies and the
who-wins bouts fight as they did.

The five shapes' cells, the lines, the sheet's button rather than a wheel, the 40 pixels, the fall-in
ending on contact and the 8% are **Inferred** (agenda 213).

### The leader, call-outs and fights shared

**Built 2026-10-20** ([D306](06-decisions.md), piece E2, from [D289](06-decisions.md)). `doug-md`: "a
natural leader comes out of the fights and need not be the lead you play"; `dougie`: "short call-outs in a
fight, not chatter, heard by both sides, so a shout of 'get the healer' warns the foe", and "a bonus for
fights shared, across every role, so a seasoned party works as a unit even without a leader".

- **The leader.** Each of the company counts the fights they came through (won and lost). The one with
  the most won, three or more (ties to the higher level, then the marching order), leads the fights; the
  card says so (*leads the fights (7 won)*). They call for a shape by the line they fight in: a mender or
  a shooter a wedge (the mender inside the V), a blade a diamond, anyone else a line; *Auto* takes it
  (*Formation: Auto (Wedge, Vesta's call)*), and the player may pick another.
- **Call-outs.** When a side's caller (the party's leader, else its lead; a foe band's boss, else the first
  of them) goes for a mender or a shooter, they shout it once per foe: "Get the healer!", "On the archer!",
  over their head and in the log. Both sides hear: the one called is warned for 3 s and tries to get clear
  first (break off, hang back, kite), and a friend within reach guards them as if they were under half
  health. A shout warns the foe, as `dougie` asked; it is a choice with a cost.
- **Fights shared.** Each keeps how many fights they won beside each of the others. In a fight a party
  fighter is spared 0.4% of every blow, and lands 0.4% more, for every fight won beside the others
  standing with them (their average), up to 8%.
- **Breaking.** A companion whose mood is under 35 ([D279](06-decisions.md)) holds no slot and does not
  fall in, on the ground or in a fight.

`data/skirmish.json` → `formations.leader`, `callouts`, `shared` and `break_below_mood` hold the numbers
and words. A band of foes falls in too (2026-10-21, [D315](06-decisions.md)): from three standing, round its
boss or its first, in the shape the party's Auto would pick for its size, facing the nearest of the party,
until any of it is in contact; holding a slot earns a foe nothing (`formations.foes`). **Still to come**: the
wheel on a held key, a leader's orders beyond the call-out, plans made between fights and kept quiet in
them, and trust breaking a formation. Fights won as
the measure, three as the floor, the shapes called for, the two shouts and their 3 s, 0.4% and 8%, and 35
are **Inferred** (agenda 214).

## Who wins?

**Built 2026-10-16** ([D180](06-decisions.md), call AY), after `dougie` pointed at a channel of
simulated "who wins?" fights ([investigation 10](investigation/10-who-wins-shows.md)). Two of the
sixteen fight it out with nobody's hand on either, dressed as a show, and the game records it as a
clip for YouTube (wide) and shorts (tall).

**The fight is the real one.** `src/who_wins/who_wins.gd` stages the skirmish in `bout` mode: the
left lead is a party of one (the company that follows them stays home), the right stands across the
field at the same level, both raised the same way, on a grass field drawn from the seed. Both are
played by the brain the enemies use. A bout is a sandbox, so nothing is written onto any run. What
`bout` changes in the skirmish: each side loses when its lead falls, whatever bearer, wolf or shade
still stands; there is no HUD (the show draws its own); and the fight stays on the field when it is
over. Every body on the field gets `health_scale` (2) times its health, because one against one at a
company's health is over in four to six seconds (**Inferred**, agenda item 110).

**The show** (`src/who_wins/who_wins_show.gd`, timings and words in `data/who_wins.json`, all
**Inferred**, agenda item 111): a VS card with the two faces on their colours, FIGHT!, then along the
top each lead's face, name, class and health with the clock between; the move each last let go in a
pill under their bar; a red edge on a side whose lead is under a quarter of their health; a burst of
lines round anyone hit for a fifth of their health or more; a camera that keeps both in view and
closes in; the last blow in slow motion under K.O.!; then the winner's banner and "WHO SHOULD FIGHT
NEXT? COMMENT BELOW". A bout nobody wins in 90 seconds ends on NOBODY WINS. Held upright the card
stacks the two faces. Nothing is drawn from the channel: the sixteen in their own art, the words and
shapes in code.

| To | Run |
| --- | --- |
| Record a bout, wide and tall, as `.mp4` in `clips/` | `python3 tools/who_wins.py ares cassius` (`--seed`, `--level`, `--wide`, `--tall`, `--random 3`) |
| Watch one in a window | `godot --path . res://src/who_wins/who_wins.tscn -- --left=cato --right=saturn --seed=7` |
| Just the answer | the same with `--headless` and `--verdict` |
| Every lead against every other, both ways round | the same with `--headless` and `--table --seeds=2` |

The recorder checks each pairing headless first and skips one nobody wins. It uses Godot's movie
maker, so a clip plays the same however slow the machine, and sets the clip's shape for the run in
`override.cfg` (taken away after). It needs ffmpeg for the `.mp4`; on a machine with no screen it
runs under `xvfb-run`. A recorded bout and its headless verdict are fought separately and can end
differently.

**What the table says** (level 5, two seeds, 480 bouts, 2026-10-16): a bout runs 5 to 90 seconds,
25 in the middle, and 47 of the 480 (one in ten) are still going at 90. One against one, Diana
(62%), Ultor, Ares and Cassius (60%) win most; Iris (13%), Janus (20%), Pluto (23%) and Vesta (27%)
least. Those four are built to fight beside others, so this is not a balance verdict on the game,
but it is a list of who needs a look before a lead-against-lead knockout ([D171](06-decisions.md))
is built (agenda item 112).

## Party clashes

**Built 2026-10-18** ([D257](06-decisions.md), issue #329), on `dougie`'s ask for fights between random
parties "with combat, dialogs, items, strategies" as video, and a guild war. Two parties fight it out
with nobody's hand on either, on the real skirmish in `bout` mode (a sandbox, as "Who wins?" is).

**The draw** (`src/party_war/party_war.gd`, numbers and lines in `data/party_war.json`, all
**Inferred**, agenda item 169): each side is one to four fighters; each fighter is one of the sixteen
(six times in ten, never the same lead on both sides) or one of the units listed, at a level from 1 to
10, in a calling drawn for them; each carries a piece of real gear from `data/equipment.json` that
suits that calling, beats what they were issued and costs no more than its level allows; each fights
in a stance (Own way, Close in, Keep away or Guard, [Stances](#stances)) on top of their doctrine
([Tactics](#tactics)); and each side shares a pouch of one to three draughts, which a fighter under a
third of their health reaches for. Health is half as much again as a company's. The left side fights
as the company (the near-death window, friends who pull them back up, the graces); the right as the
other side. For this the skirmish's map entries can now carry `class`, `gear` and `stance`, and an
enemy given a stance fights in it.

**The show** (`src/party_war/party_war_show.gd`): a card with both sides, each fighter's face, level,
calling, gear and stance, and each pouch; FIGHT!; each side's roster down its edge with health, gear,
stance and what they are busy with (drinking, winding up, down); the fight's own log along the bottom;
the camera on whoever is still standing; words over a fighter's head as the fight opens, at a kill,
when a friend falls, when they are low, when they drink and at the end, by doctrine (a ranged lead
says "Clean shot.", a keeper "Who mends the mender?"); then K.O.! and the winner's banner. The moves,
"circles", "guards Iris", "Blocked" and "DOWN" are the skirmish's own words, where they happen.

**The guild war** (`wars.guild_vs_empire`): the Adventurers Guild (four of the sixteen at 6 to 9 and
eight of the Guild's muster at 4 to 7) against the Heart Empire (Dirte at 12 and thirteen of the
legion at 6 to 10) on a field 30 by 20. A war is any entry under `wars`; nothing else in the code
names this one.

| To | Run |
| --- | --- |
| A batch, each draw fought both ways round, as `results.csv` and `results.md` | `python3 tools/party_war.py table 150 --seed 1` |
| Clashes in a row as one `.mp4` | `python3 tools/party_war.py clashes 5 --seed 7`, or `--seeds 1005,1009` from the table |
| The guild war as an `.mp4` | `python3 tools/party_war.py war --seed 1` |
| Watch in a window | `godot --path . res://src/party_war/party_war.tscn -- --fights=3 --seed=7` (or `--war=guild_vs_empire`) |

**What the table says** (150 draws, each fought both ways round, 2026-10-18): a clash runs 4 to 118
seconds, 28 in the middle, and one in eleven is still going at 120. **The company's side is worth
more than anything drawn**: the left wins 70% and the right 21%; fought both ways round, the same
party won both times in 43% of draws, the company's side won both times (the side decided it) in 41%,
and the other side never won both. Being pulled back up from the near-death window is what does it.
**Bodies count**: one more fighter wins 63%, two more 89%, three more 95%; with the levels on each
side adding up to within three, the side with more bodies still wins 57%. **Levels count**: a lead of
1 to 5 levels in total wins 60%, 11 to 20 wins 90%. Stance and lead-or-unit make no difference a
batch this size can see (56% to 58% each). The guild war is close: on seeds 1 to 4 the Empire won
three. These are hands-off fights, so they say what the rules are worth, not what a player gets
out of them.

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
