# Session 2 — the briefing sheet

What the next founders' session has to settle, written so each item can be answered in a sentence.
The questions themselves live in [answers.md](answers.md#what-is-still-to-decide). This sheet adds
the options, what each one costs to build, and what the game does if nobody answers.

Nothing here is an answer. Only a founder settles a question. A row marked **Inferred** is something
the build has already done so it could keep moving, and it needs a yes or a replacement.

**Joint session 2 ran on 2026-10-01** ([transcript](voice-notes/2026-10-01-joint-session-2.md)). It
settled items 1, 2, 4, 5, 6 and 8, struck through below, and stopped there. Items 9 to 19 and the
five new rows the session raised (20 to 24) are for the next call.

## Needed before the next milestones

| #  | The question | Options | What it costs to build | If nobody answers |
| -- | ------------ | ------- | ---------------------- | ----------------- |
| 1  | ~~How many floors has the Tower, and how many make a chapter?~~ | **Settled:** 100, chapters of 5 ([D48](../06-decisions.md)) | Built 2026-10-01; the curve, cohorts and rewards are item 24 | — |
| 2  | ~~Does the world still run on steps?~~ | **Settled:** **B**, and further: no steps at all, milestones instead ([D49](../06-decisions.md)) | Large. Planned as M18; see item 20 | — |
| 4  | ~~Can a death be reloaded?~~ | **Settled:** a Classic mode that reloads and an Iron Man mode that does not ([D51](../06-decisions.md)) | Planned in M15 | — |
| 5  | ~~In the second world, is there a living copy of the first lead?~~ | **Settled:** yes, an NPC from their stats ([D52](../06-decisions.md)) | Planned in M15 | — |
| 6  | ~~What does a lead remember?~~ | **Settled:** memories return by chapter; "Ascend to heaven" ([D53](../06-decisions.md)) | Planned in M13 | — |
| 8  | ~~Assists: one number or two?~~ | **Settled:** two, 10 and 5 for a healer's ([D54](../06-decisions.md)) | Built 2026-10-01; the healer reading is item 23 | — |
| 9  | Sprite size: 64, 32 or 16? | 64 (on disk) · 32 (the model game's class) · 16 | Art only: the [asset list](../19-asset-list.md) is generated at one size. The size test is ready and waiting on PixelLab credits | 64; the asset list stays ungenerated |
| 10 | Sixteen ways to fight, six classes? | More classes · a class per character · styles inside classes | Data in `classes.json` plus the ability grammar; large either way | Six classes |
| 11 | How does the party grow from four to six? | A level · a Guild rank · a Tower chapter · bought | `Roster.MAX_PARTY` becomes a rule; battle maps need six spawns. Small for any option | Four |
| 12 | Where does a dead lead's weapon land? | Somewhere easy to find · at random | Waits on M15 | Undecided |
| 15 | What is a hearth, or a background, for someone who fell from the sky? | Confirm: hearth = crash site, background = the life above, found in pieces · or replace | Writing the lore pools | The reading stands as **Inferred** |
| 20 | What are the milestones, now steps are gone? | Tower chapters, plus named checkpoints · and for each step-priced clock (doctrine, gate breaking, captives, threads, seasons, jobs): keep it on milestones, or drop it | Large: every one of those is priced in steps today | The step clock keeps running |
| 21 | One view: how far is a walk? | A smaller continent · bigger planar areas · a faster way to travel (roads, ferry, a mount) | Large: M18 | Both views stay |
| 22 | "Ascend to heaven" names the standing quest and the death prompt. The same thing? | Dying finishes it · dying fails it · two things with one name | Writing only | Undecided |

## Built on an inference — confirm or replace

| #  | What was built | The inference | Other ways it could go | Where it lives |
| -- | -------------- | ------------- | ---------------------- | -------------- |
| 16 | Gate objectives ([D45](../06-decisions.md)) | Three kinds: rout, slay the keeper (last floor), reach the heart (every floor). Fixed by the gate's cell. No timers | Other kinds (escort, hold, rescue); timers after playtest (`GT3`) | `world_rules.gate.objectives` |
| 17 | Guild musters going in alone ([D46](../06-decisions.md)) | A muster nobody from the company stands with in person goes in once it is ready and has waited. A win shuts the gate without renown, a loss breaks it | It waits for ever · it never goes in without the company · it always wins | `data/guild.json` → `muster` |
| 18 | When the record of the fallen is wiped ([D47](../06-decisions.md)) | Only once every lead has fallen, from the picker, after asking twice | On conquering the Tower · never · a new "saga" from the title screen | `src/chronicle/sixteen.gd` |
| 19 | Where the Adventurers Guild keeps a hall | Every keep and village still standing; never huts. **Y** on the map, or the clerk inside | Keeps only · a Guild site of its own on the map | `src/chronicle/guild.gd`, the keep and village areas |
| 25 | Random crash sites (M13) | Drawn per hero from the world seed: open ground joined to the Tower, 24+ from it, 6+ from an open gate, within 26 of a settlement. The lead's crater is Home, "Where You Fell" | Anywhere at all · near a place of the hearth's kind · a fixed handful of craters per world | `data/fall.json` → `crash`, `src/chronicle/fall.gd` |
| 26 | The others, before the sixteen exist | The twelve existing heroes stand in, each with an inferred temper | Wait for the sixteen · only the NT four once written | `data/fall.json` → `wanderers.tempers` |
| 27 | Where each temper goes | NT libraries and the Tower; NF libraries, villages, huts; SJ keeps and villages; SP gates and keeps. Stay 60–180 steps | A place per character, from [21](../21-the-sixteen-first-draft.md#the-sixteen-at-a-glance) · their own quest line | `data/fall.json` → `wanderers.preferences`, `rules` |
| 28 | Meeting and joining one of them | Seen by standing where they stand; heard of at inns and on rests. Outward joins on the first meeting, Inward on the second, into a free place only | A price · a favour or a quest · some never join ([21](../21-the-sixteen-first-draft.md#who-is-where)) | `src/chronicle/wanderers.gd`, `data/fall.json` → `wanderers.lines` |
| 29 | How "Ascend to heaven" is shown | A landing beat, a journal page with the Tower's floor and chapter, and ASCEND on the Tower. Never completes | Shown on the walk's top line · a quest log of its own | `data/fall.json` → `landing`, `standing_quest` |
| 23 | A healer's assist ([D54](../06-decisions.md)) | The helper healed the one who landed the blow, earlier in the same fight | Anyone of a healing class · any heal on anyone in that fight | `Battle._healed_by`, `Progression.award_kill` |
| 24 | A hundred floors ([D48](../06-decisions.md)) | Enemies about a level every three floors (2 to 32); four faction cohorts; gold by the chapter; a book a chapter, a tree every two | Steeper or flatter; more cohorts; rewards by floor | `world_rules.tower` |
| 30 | The explored map ([D50](../06-decisions.md)) | Black at the start; four tiles seen round the party every step; the Tower and home known from the start | A wider or narrower sight; sight by terrain (hills see further); nothing known at all | `world_rules.atlas.sight`, `always_known` |
| 31 | Guild maps (item 21's second half) | The lie of the land for 18 tiles, dim, plus the five nearest places marked; 50 gold, once per hall | The general area only, no places · free at the first hall · several maps a hall, dearer the further they reach | `data/guild.json` → `map` |
| 32 | Maps hidden in the world | Chests 25%, caches 40%, spoils and town loot 8%; each marks one unknown place and draws seven tiles round it | Rarer and larger · a map as an item carried until read · treasure maps that lead to a cache | `world_rules.atlas`, `src/chronicle/atlas.gd` |
| 33 | Being told is knowing | Contracts, errands and inn news mark the place exactly; autoplay walks to unseen ground when it knows of nothing | Marked only roughly (a ring, not a point) · news names a region, not a place | `src/chronicle/atlas.gd` → `hear_of`, `mark` |
| 45 | Passives and enemy roles in the real-time fight ([D36](../06-decisions.md)) | One passive per class and a few per ability known, capped at three; enemies as Charger, Skirmisher, Mender or Brawler, read off their kind and kit | Passives chosen at level-up, as the model game's Inscriptions · per character rather than per class · no enemy roles | `data/skirmish.json`, `src/skirmish/skirmish_passives.gd` |
| 46 | Graces in the real-time near-death window ([D36](../06-decisions.md)) | When the twelve seconds run out with nobody there, `Fate.roll` rolls the turn-based graces (charm, companion, book, ground, luck; no capture); one that lands stands them up at a quarter health. Training writes nothing back | Roll at the fall instead · only the charm and the ground count in real time · no graces in real time, the window is the grace | `Skirmish._grace`, `Fate.roll` |
