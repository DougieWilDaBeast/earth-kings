# Session 2 — the briefing sheet

What the next founders' session has to settle, written so each item can be answered in a sentence.
The questions themselves live in [answers.md](answers.md#what-is-still-to-decide). This sheet adds
the options, what each one costs to build, and what the game does if nobody answers.

Nothing here is an answer. Only a founder settles a question. A row marked **Inferred** is something
the build has already done so it could keep moving, and it needs a yes or a replacement.

## Needed before the next milestones

| #  | The question | Options | What it costs to build | If nobody answers |
| -- | ------------ | ------- | ---------------------- | ----------------- |
| 1  | How many floors has the Tower, and how many make a chapter? | 10 (ships) · 20 · 50 · 100; chapters of 5 | `tower.floors` and `floors_per_chapter` in `data/world_rules.json` are one number each. Past 10, `Encounter.for_tower`'s faction tiers and the apex fight are written for ten and need extending | Ten floors, two chapters |
| 2  | Does the world still run on steps? | **A** steps drive the small clocks, chapters drive the story (built) · **B** chapters only · **C** steps only | A: nothing. B: the step upkeep is switched off between chapters, a large change. C: `tower.chapter_upkeeps` set to 0 | A |
| 4  | Can a death be reloaded? | **A** yes, as now ([D21](../06-decisions.md)) · **B** no: a lead's death deletes or locks the save · **C** yes, but the world remembers | A: nothing. B: a few lines in `world_scene._end_run`. C: needs M15's world record. Either way the dead now stay out of the quiz and picker even if an old save is loaded ([D47](../06-decisions.md)) | A |
| 5  | In the second world, is there a living copy of the first lead? | Yes · No | Waits on M15's sibling worlds; nothing to change today | Undecided; M15 cannot finish |
| 6  | What does a lead remember? | Confirm the reading: the fall takes the memory, the mark is recognised anyway · or replace | Writing only (M13's intro and dialogue) | The reading stands as **Inferred** |
| 8  | Assists: one number or two? | One (5, built) · two (10 for grunts, 5 for a healer's assists) | One: `experience.assists_needed`. Two: a small change in `Progression.award_kill` to tell the kinds apart | One, at 5 |
| 9  | Sprite size: 64, 32 or 16? | 64 (on disk) · 32 (the model game's class) · 16 | Art only: the [asset list](../19-asset-list.md) is generated at one size. The size test is ready and waiting on PixelLab credits | 64; the asset list stays ungenerated |
| 10 | Sixteen ways to fight, six classes? | More classes · a class per character · styles inside classes | Data in `classes.json` plus the ability grammar; large either way | Six classes |
| 11 | How does the party grow from four to six? | A level · a Guild rank · a Tower chapter · bought | `Roster.MAX_PARTY` becomes a rule; battle maps need six spawns. Small for any option | Four |
| 12 | Where does a dead lead's weapon land? | Somewhere easy to find · at random | Waits on M15 | Undecided |
| 15 | What is a hearth, or a background, for someone who fell from the sky? | Confirm: hearth = crash site, background = the life above, found in pieces · or replace | Writing the lore pools | The reading stands as **Inferred** |

## Built on an inference — confirm or replace

| #  | What was built | The inference | Other ways it could go | Where it lives |
| -- | -------------- | ------------- | ---------------------- | -------------- |
| 16 | Gate objectives ([D45](../06-decisions.md)) | Three kinds: rout, slay the keeper (last floor), reach the heart (every floor). Fixed by the gate's cell. No timers | Other kinds (escort, hold, rescue); timers after playtest (`GT3`) | `world_rules.gate.objectives` |
| 17 | Guild musters going in alone ([D46](../06-decisions.md)) | A muster nobody from the company stands with in person goes in once it is ready and has waited. A win shuts the gate without renown, a loss breaks it | It waits for ever · it never goes in without the company · it always wins | `data/guild.json` → `muster` |
| 18 | When the record of the fallen is wiped ([D47](../06-decisions.md)) | Only once every lead has fallen, from the picker, after asking twice | On conquering the Tower · never · a new "saga" from the title screen | `src/chronicle/sixteen.gd` |
| 19 | Where the Adventurers Guild keeps a hall | Every keep and village still standing; never huts. **Y** on the map, or the clerk inside | Keeps only · a Guild site of its own on the map | `src/chronicle/guild.gd`, the keep and village areas |
