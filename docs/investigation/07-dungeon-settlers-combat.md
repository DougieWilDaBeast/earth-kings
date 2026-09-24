# 07 — Dungeon Settlers: the combat deep dive

The research [D36](../06-decisions.md) asked for before anything is built, answering the fifteen
questions in [18 — Combat direction](../18-combat-direction.md#what-the-research-has-to-answer).
Roadmap [M10](../05-roadmap.md). First pass: 2026-09-24.

**How this was done, and what it cannot tell you.** Nobody on the team has played the game yet.
Everything here comes from what CanOpener has published — the Steam store text, **all 44 posts on the
game's official Steam news feed** (two devlogs, the Early Access roadmap post and every patch note from
the alpha to v0.4.23), read through Steam's public news API — plus player threads on the Steam forum,
three reviews and previews, a fan copy of the in-game handbook, and measurements taken from the 18
official screenshots. Each claim is marked with where it came from:

| Mark | Source | Weight |
| --- | --- | --- |
| **[dev]** | CanOpener: store page, devlogs, patch notes, developer forum replies | Fact, as of v0.4.23 |
| **[guide]** | The in-game Game Guide, as copied onto an unofficial fan site that says it reproduces "the complete in-game handbook… 57 topics as shipped" | Probably fact — it agrees with the patch notes wherever the two overlap |
| **[players]** | Steam forum threads | Experience, not specification |
| **[review]** | InsertCoins, Scopique, GenerationAmiga | Informed impressions |
| **[measured]** | Our own measurement of the official screenshots | An estimate. JPEG, and the camera zooms |

Questions only playing it can answer are gathered at the end. **The game is $24.99 on Steam, and an
hour of play would close most of them.**

**It is a moving target.** Early Access began on 2026-09-04 and is planned to last about two years
[dev]. Four patches landed in the first eight days, several of them to combat. Anything here may be
out of date within the month.

---

## The game in one paragraph

A dark fantasy colony sim fused to a dungeon crawler. You run a settlement in a corrupted wasteland,
recruit and equip expedition members, and send a party down into a randomised, multi-floor dungeon
to fight in **real time with pause**, "with no turn or round limits" [dev]. **Once dead, there is no
coming back** [dev]. The settlement — beds, food, crafting, research, mood — feeds the expedition, and
the expedition feeds the settlement.

---

## The fight itself

### 1. What does the player control, moment to moment?

**Each unit, individually, RTS-style.** [guide]

- Select one unit with `1`–`9`, all with `Tab`, or drag a box [guide].
- **Right-click the ground to move there; right-click an enemy to basic-attack it.** Some ranged
  attacks spend ammunition — arrows — which can be swapped mid-fight since the demo [guide] [dev].
- There is no leader others follow and no formation command. "Melee characters will charge in and
  ranged characters will attack from a distance" on their own once told to attack [review].
- Blocking works: since the Alpha 3 rework, **enemies cannot pass through allied units**, so a warrior
  in a narrow passage holds it. "In a strategy game, that should never happen" [dev].

### 2. How is "automatic" decided?

- **Basic attacks continue on their own** once a target is set, and units switch to another target
  when theirs dies (fixed as a bug in the demo, v0.3.25) [dev].
- **Enemy melee targeting is rule-based, not random.** v0.3.21 changed "melee enemy aggro behavior
  from random targeting to fixed targeting rules" [dev]. The rules are not published.
- **Threat can be forced.** Provoke and taunt skills exist — _Guardian's Taunt_ holds 6 seconds as of
  v0.4.23 [dev].
- Units do detour around each other in combat, sometimes unexpectedly in narrow passages; the
  developer has said it is being tuned [dev].

### 3. How do the auto abilities work?

**A per-unit toggle called _Auto Skill_, one of three behaviour options** [guide] [dev]:

> "When the 'Auto Skill' Behavior Option is enabled, during combat the unit prioritizes skills from
> left to right in the Skill Quick Slots that meet their usage conditions, and a skill is used
> automatically if conditions such as cooldown and range are met, and using the skill with the current
> Energy would not cause the unit to become Exhausted." — the in-game guide

- **Priority is the slot order.** Left to right, first skill ready wins.
- **It will not exhaust the unit.** The auto-caster keeps an energy reserve.
- **Skills that can hurt allies default to off** under Auto Skill (v0.4.23) [dev].
- The other two behaviour options are **Wait for Orders** — "holds position during combat and waits for
  orders" — and **Prioritize Sleep** [guide].
- **It was added late, and reluctantly.** The developer's first position: "Choosing the right moment
  to use each skill is an important part of the tactical experience we want to deliver." Then: "Devs
  discussed about it a lot and finally came to have 'auto-skill use' as unit toggle option in the
  game. We tested it and it wasn't that bad(even strategically)." They floated limiting it to low
  difficulty [dev]. It shipped in the 2nd Supporters build in March 2026 [dev].
- What players settled on: auto for cheap, short-cooldown skills, manual for the big ones, and pause
  mainly for bosses [players].

### 4. Cooldowns, resources, cast times, interrupts

- **Every active skill has a cooldown in seconds.** Values in the v0.4.23 notes run from 8 to
  24 seconds [dev].
- **And costs Energy** — 3 to 7 per skill in the published numbers [dev]. **Energy is not a combat-only
  bar.** It is the unit's stamina for everything — walking, working, staying awake, fighting — shown as
  a yellow bar, and it comes back by sleeping, in beds or at campfires [guide]. Empty it and the unit
  is "Severely Exhausted, falling unconscious and unresponsive" [guide]. On Normal, skill energy costs
  are cut 25%, and on Easy 50% (v0.4.23) [dev].
- **Cast times exist.** _Explosion_ went from 2.88 to 1.88 seconds in v0.4.17 [dev].
- **Interrupts: unknown.** Stuns exist and were lengthened across the board in v0.4.23, but nothing
  says whether a stun cancels a cast in progress.
- **Status effects** named by the developer: stun, bleed, burn, provoke, vulnerable, charge attacks,
  summons, root, stagger, haste, shields [dev].

### 5. Does the tile grid matter mid-fight?

**Yes — the world is tiles, and the fight happens on them.** [dev]

- Ranges and areas are measured in tiles: "bounces up to eight times to enemies within three tiles"
  [review]; _Charge Attack_ adds damage "per tile charged" [dev]; big units "occupy multiple tiles"
  [dev]; monsters "reserve" tiles, which can block movement [dev].
- **Vision is real.** There is a field of vision, and since v0.4.23 an enemy that attacks from outside
  it has its tile revealed for about two seconds [dev].
- **Facing, height, flanking: no evidence of any.** Nothing published mentions facing or back attacks.
  "Surprise effects" exist but are not explained [dev]. Treat as absent until someone plays it.

### 6. What does pause allow?

- **Pause any time with `Space`, and queue orders while paused**: "While paused, you can queue actions
  such as skills, movement, or item usage" [guide].
- **Game speed**: "Normal~Fast (F1~F2)" [guide] — so two speeds plus pause, as far as the guide says.
  Effects follow the speed (a v0.4.17 fix made VFX respect it) [dev].
- **No auto-pause.** Players asked for "automatic pausing when abilities [are] available" and for
  better action queuing; neither exists [players].

### 7. How long is a fight, and how big?

- **Four on a side to start.** The party was capped at four until v0.4.23, which raised it to **six at
  expedition Rank 2 and eight at Rank 3** [dev].
- **Enemies come in groups and packs** — Gloths "move in packs, and their elder leaders will charge
  forward" [dev] — and there are regular, elite and boss monsters [dev].
- **Fight length: unknown.** Nothing published gives it. Play it and time ten fights.

### 8. How is it made readable at speed?

- Name, health and energy bars over every unit, and a status icon beside them [measured].
- Damage numbers float up from the target [measured].
- A HUD pass "with more combat information" (March 2026), a combat log, and the cursor changes while
  aiming a skill [dev].
- **Portraits.** A row of large hand-drawn portraits across the top of the screen, one per member,
  with their bars [measured]. One review calls the pairing of "a hand-drawn portrait, expressive, with
  an actual head and a gaze" with small sprites the reason a death lands [review].
- Players still find it hard work: "Having to pause constantly to select abilities, reposition
  characters, and figure out what to do next repeatedly interrupted the flow" [players].

---

## Around the fight

### 9. How are abilities acquired and slotted?

- **Skill points on level-up, split into Main and Sub.** "Units have main and sub skill points, which
  can be used to learn skills" [guide].
- **Which trees a unit can use is set by its Major Traits** at recruitment [dev]. Trees are by weapon
  and school: sword, mace, greatsword, spear, bow, fire magic, and more [dev].
- **Four quick slots: `Q`, `E`, `R`, `T`.** Drag a learned skill in, or right-click it in the Skill
  window [guide].
- **Resetting is rare.** A Skill Reset Elixir, found in dungeon chests [guide]; the demo notes say
  they "no longer drop" otherwise [dev].

### 10. How do levels, gear and skills combine?

- **Experience fills a bar; the level-up happens at a Goddess Statue** built in the settlement. The
  unit chooses **one of three offerings**, each a set of stat increases plus an **Inscription** — a
  passive with its own rules [guide]. On Easy and Normal the rolls can be locked [dev].
- **Six major abilities** (Strength, Constitution, Willpower, Intelligence, Agility, Perception),
  talents, and "dozens of combat and life-related stats" [dev] [measured].
- **Gear matters and wears out.** Equipment durability and repair were reworked after Alpha 3 [dev].
  Weapon materials run from wood and bone to copper and iron, with different stats [dev].
- **Nothing gets better by use.** No proficiency-by-practice system is mentioned anywhere.
  Earth Kings' [D37](../06-decisions.md) goes further than its model here.

### 11. What happens when a unit dies?

**It does not die at once.** A unit at zero health goes into **Near Death** — "a unit is in imminent
danger of death" — on a timer [guide]. In that window it can be saved:

- with a First Aid kit or a serum, on the spot (right-click the downed ally) [guide] [dev];
- or by being **carried on another member's back** to the settlement for **surgery** [guide] [dev].

"If the unit does not regain consciousness before Near Death expires, they will die permanently"
[guide]. The window was lengthened in April 2026 so players had "a better chance to return to the
settlement and save critically injured units" [dev]. Surviving it leaves a strong mood penalty [dev].
The dead leave a body, and until it is buried they still count against the settlement's population
[guide]. A party wiped out gets an _Expedition Failed_ screen at the portal [measured].

### 12. What does the fight lean on from the settlement half?

More than it looks:

- **Energy.** The same bar pays for skills and for walking and working, and it is refilled by sleep.
  After fights players can "stare at the screen for 2 minutes" while characters sleep [players], and
  the developer has promised to reduce "the burden of having to rest too frequently" [dev].
- **Rations, camping kits, tents** — carried in, because a dungeon trip is long [dev].
- **Mood and stress.** Units break down under stress, which is shown on their portrait [dev].
- **Equipment**, crafted and repaired at home [dev].
- **Surgery** for the near-dead [dev].
- **The Goddess Statue** for every level-up [guide].

`doug-md`'s "we don't need that" is right about the building, and the rest ports cheaply — except
the energy economy, which only makes sense in a game where people sleep. See the recommendations.

---

## Art

### 13. Sprite size and frame counts

**Not published.** Measured from the official screenshots [measured]:

- In the clearest combat shot the art is drawn at about **6× on a 1080p screen**, and a humanoid is
  about **13 art pixels wide and 22 tall** — the **32×32 class**, not 64, and bigger than 16.
  `doug-md`'s "the characters are 16" was close. Tiles are roughly the width of a character.
- The camera zooms, so the on-screen size varies between shots. The ratio of character to tile does
  not.
- Large monsters are drawn larger and occupy several tiles [dev] [measured].
- **Frame counts cannot be measured from stills.** The trailer or an hour's play would give them.

For [agenda item 9](../worldbuilding/answers.md#what-is-still-to-decide): the model the founders
pointed at is the **32 class**. The Tier 0 size test in [19](../19-asset-list.md) should keep 32 and
64 as the real choice and treat 16 as the outlier.

### 14. How does it keep many small units legible?

A **chunky dark outline** on every sprite, a **muted ground** that the characters sit above, **name
and bars over each head**, and **the portraits** doing the emotional work the sprites are too small
for [measured]. Pivot-based sprite sorting so overlapping units stay in the right order [dev].

---

## 15. For Earth Kings

### Take

| From Dungeon Settlers | Into Earth Kings | Why |
| --- | --- | --- |
| Right-click to move, right-click to attack; select with number keys and `Tab` | The whole control scheme | Proven, and it is what `doug-md` described |
| `Space` pauses at any time, **and orders queue while paused** | The prototype's core loop | Pause with a queue is what keeps real time tactical |
| **Normal and Fast** speeds | `T`, already cycling speed for autoplay | The build already has half of this |
| **Four quick slots**, left-to-right | Q W E R ([D36](../06-decisions.md)) | Same count the founders chose |
| **Auto Skill** as a per-unit toggle: left-to-right priority, only if cooldown, range and the resource allow; ally-damaging skills default off | Exactly this, **on by default** for the party | The developer resisted it and was wrong; the players' main complaint is micromanagement |
| **Wait for Orders** as a second behaviour option | A hold-position toggle | Cheap, and it is how a player holds a doorway |
| Enemies cannot pass through allies | Blocking on the grid | It makes positioning matter without facing |
| An attacker outside vision has its tile revealed for two seconds | The same, if fog of war is kept in fights | Stops unseen deaths feeling unfair |
| Rule-based enemy targeting, plus taunts | `EnemyBrain` choosing continuously, with a threat table and provoke | Random aggro read as broken to their players |
| **Near Death on a timer, saved by aid or by carrying** | **The graces happen during the window** ([D11](../06-decisions.md)) — a Rescue grace becomes an ally reaching you in time | Makes the grace roll something the player can act on, which it currently is not |
| Large portraits beside small sprites | See [19](../19-asset-list.md), Tier 0.6 | The reason a death lands |

### Do not take

| From Dungeon Settlers | Why not |
| --- | --- |
| **Energy as a shared, sleep-refilled stamina bar** | Earth Kings has no colony and nobody sleeps on the road except at a fire. Use **cooldowns only** in the prototype. Add a per-fight resource later only if cooldowns alone make every skill spam |
| Levels at a statue, from a choice of three | [D37](../06-decisions.md) already decides where experience comes from, and it is not this |
| Skill resets only from rare drops | Earth Kings' generated trees are the point; respec is its own question |
| Party growth to eight | [D38](../06-decisions.md) says six, and a real-time fight gets unreadable fast |

### Decide in the prototype

- **Facing.** Dungeon Settlers shows no sign of it. Earth Kings has it (side 1.2×, back 1.5×). In real
  time a unit's facing is where it last moved or is attacking. Keep it and see whether players can
  read it at speed; drop it if they cannot.
- **Height and jump.** Same question. Nothing suggests Dungeon Settlers has either.
- **Auto-pause.** Their players asked for it and did not get it. Offer it as a setting — on a unit
  falling, on a skill coming off cooldown — and see which gets used.
- **Charge time.** It goes. J's +20 opening CT becomes an opening burst of speed (compare _Initiative_:
  "Attack Speed increase at the start of combat 25% → 35%" [dev]), and P's +1 move becomes movement
  speed.

### The smallest playable prototype

What [M11](../05-roadmap.md) should build, and nothing more:

1. A new scene beside `battle.tscn`, on a generated battlefield, reusing `BattleGrid` and `Pathfinder`.
2. Four party units and one group of three enemy kinds, spawned from `Character`s as today.
3. A real-time loop: units move tile to tile at a speed; basic attacks on a timer; `Space` pauses
   with a command queue; `T` switches Normal and Fast.
4. Right-click move and attack; `1`–`4` and `Tab` to select.
5. Four slots per unit on Q W E R, each ability given a **cooldown and a cast time** in
   `data/abilities.json`; damage still from `AbilityResolver`.
6. **Auto Skill** and **Wait for Orders** per unit.
7. `EnemyBrain` returning a plan every half-second instead of once a turn — the mind seam stays.
8. Falling uses the graces, inside a short Near Death window.
9. A headless smoke test that runs the fight to an end at Fast speed.

Then both founders play it against the current battle ([D36](../06-decisions.md): nothing is retired
until then).

---

## What only playing it can answer

Buy it, play an hour on Normal, and write the answers under this heading:

1. How long does an ordinary fight take, and a boss? Time ten.
2. How often do you actually pause, with Auto Skill on and off?
3. Does facing or attacking from behind matter at all?
4. Does a stun interrupt a cast?
5. What does Fast actually multiply by?
6. How do units choose where to stand when told to attack — do they spread out, or clump?
7. How many frames are in an attack animation? Is there a wind-up you can react to?
8. Can a party leave a floor mid-fight, or only through the portal once it is found?
9. How long is the Near Death window?
10. At what point in the first hour did a fight feel like a decision rather than a chore?

---

## Sources

- [Dungeon Settlers on Steam](https://store.steampowered.com/app/2798330/Dungeon_Settlers/) — store text [dev]
- [The official news feed](https://store.steampowered.com/news/app/2798330), read in full through
  [Steam's public news API](https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=2798330&count=100&maxlength=0).
  Most used: _#1 Devlog_ (2025-06-19), _#2 Devlog_ (2025-11-27), _2nd Supporters Program_
  (2026-03-21), _2nd Supporters Feedback_ (2026-04-22), _Demo v0.3.21_ (2026-06-11), _Early Access &
  Roadmap_ (2026-09-04), _v0.4.17_ and _Your Feedback in Action_ (2026-09-06), _v0.4.23_ (2026-09-12) [dev]
- [Steam thread: auto-battle, with developer replies](https://steamcommunity.com/app/2798330/discussions/0/688615158420114690/) [dev] [players]
- [Steam thread: "Combat doesnt click"](https://steamcommunity.com/app/2798330/discussions/0/591813437999314896/) [players]
- [Steam thread: "Building the Colony Is Great… Fighting, Not So Much"](https://steamcommunity.com/app/2798330/discussions/0/567037949153336489/) [players]
- [In-game handbook, fan copy](https://dungeonsettlers.wiki/guide) [guide]
- [InsertCoins review](https://insertcoins.press/en/articles/dungeon-settlers-test) ·
  [Scopique](https://scopique.com/2026/08/24/dungeon-settlers/) ·
  [GenerationAmiga](https://www.generationamiga.com/2026/05/25/dungeon-settlers-wants-you-to-build-a-home-then-send-everyone-into-hell/) [review]
- The 18 official store screenshots, measured [measured]
