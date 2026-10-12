# 08 — Quests and a living world: what three games do, and what fits ours

Asked for by `doug-md` on 2026-10-12, answering agenda item 20 (what replaces the step clock):
"have a look at very prominent games like Baldur's Gate Witcher 3 Skyrim and see how they do their
quests and align your decision making based on that" ([transcript](../worldbuilding/voice-notes/2026-10-12-doug-md-chat.md)).
A first pass, from published guides and interviews. Nothing here is an answer: the proposal at
the end is **Inferred**, for both founders to confirm or replace.

## What `doug-md` asked for

- The world is alive: things happen "whenever they should take place", driven by objectives
  completed, not by a clock you are racing.
- When the conditions line up, a gate breaks ("a dungeon break").
- A quest can carry a deadline in days of travel ("seven days"), and missing it has an outcome:
  the person you were meant to save has died, or somebody else did the job.
- Quest lines worth having, judged against _Baldur's Gate 3_, _The Witcher 3_ and _Skyrim_.

## What each game does

### _Baldur's Gate 3_ — the clock is the rest

Time in BG3 barely exists until you **sleep**. Most of its time-sensitive quests count long rests,
not hours: one long rest after reaching the burning inn and everyone inside is dead; the merchants
in the caravan ambush die after one; a captured companion dies three long rests after the trial
starts; a councillor is executed five long rests after you reach the Lower City. Short rests do not
move the clock. A few timers start only when you arrive somewhere (the beach, Grymforge), and some
quests close when you reach a story beat (everything that must be done before the goblin camp, or
before the end of an act). ([Prima Games](https://primagames.com/tips/baldurs-gate-3-all-time-sensitive-quests-in-bg3-listed))

**What it teaches us:** the player decides when time passes. A deadline is real but never hidden in
a ticking clock: it is "you chose to sleep". That is "no time pressure" and "you can be too late" at
once.

### _The Witcher 3_ — cut-offs and consequences that come back

Witcher 3 quests do not run on time at all. They fail at **cut-off points**: reaching a main-story
milestone locks out the side quests of the region you are leaving (heading to Vizima ends most of
White Orchard's; sailing to the Isle of Mists ends many of Velen's and Novigrad's), and starting or
finishing one quest can fail another. ([TheGamer](https://www.thegamer.com/witcher-3-autofail-quests/))
CD Projekt's own lessons: give dilemmas without a clean right answer, say what is at stake before
the choice, make the consequence visible, and bring early choices back when they are least
expected. ([Game Developer](https://www.gamedeveloper.com/marketing/10-key-takeaways-from-the-quest-design-of-cyberpunk-2077-and-the-witcher-3))
Its quest designers "declared war" on fetch quests: a delivery is allowed only if it ends in a real
conversation or choice, and quests are cut down to their one interesting idea.
([CDPR Q&A](https://vulkk.com/2016/05/07/witcher-3-qa-cdprs-quest-designers/))

**What it teaches us:** milestones can close quests as well as open them, and the outcome of a
missed or finished quest is worth more when it turns up again later.

### _Skyrim_ — the world starts quests itself

Skyrim's Radiant Story has a **Story Manager** that listens for things happening — you change
location, somebody is killed, a crime is seen — and starts a quest whose conditions match. The
quest's people and places are blanks filled from whatever fits in the world at the time, so any
innkeeper can be the one who asks, and any cave can be where it happens.
([Creation Kit wiki](https://skyrimck.uesp.net/wiki/Radiant_Story))

**What it teaches us:** "things take place whenever they should" is an engine that listens for
conditions and casts the quest from what the world already has.

## What Earth Kings already has

- **Threads** (`data/threads.json`, [D23](../06-decisions.md)): quest lines in stages, where a stage
  can carry a `deadline` that routes to a worse stage rather than to nothing. Priced in **steps**
  today.
- **Gates break when neglected** ([D15](../06-decisions.md)), **captives** have deadlines
  ([D18](../06-decisions.md)), **doctrine fades**, **seasons** turn, and **companions travel on
  jobs** — all priced in steps.
- **Tower chapters** are already a milestone ([D48](../06-decisions.md)), and D49 retired the step
  clock without saying what replaces it.

## The proposal — **Inferred**, for both founders

1. **A day is the clock, and the player spends days.** A day passes when the company rests (camp,
   inn, home) or travels a leg between places (on foot, or by carriage). Nothing passes while you
   stand still or fight. This is BG3's long rest, and it is the "seven days travel" `doug-md` named.
   Walking around inside one area costs no time.
2. **Milestones move the world on as well**: a Tower chapter climbed, a thread finished, a gate
   cleared or left. Each is an event the world listens to, as Skyrim's Story Manager does.
3. **Things happen when their conditions line up**, not on a timer. A gate breaks when it has been
   left alone for some days *and* the region's danger is high *and* nobody has cleared it — and the
   break starts a thread, cast from the nearest town and its people.
4. **A deadline is counted in days, and missing it is a story, not a fail screen.** The captive
   has died, or a rival company got there first and took the reward, and you hear about it: in an
   inn, from the Guild, in the annals. Every timed stage needs a written "too late" outcome.
5. **Tower chapters are cut-offs**, as Witcher 3's acts are: some regional threads close when you
   climb past a chapter, and say so before you go.
6. **Every quest ends in a choice or a conversation**, never only a delivery; say what is at stake
   before the choice; make the result visible; and bring some results back much later.

What each step-priced clock becomes under this reading:

| Today (in steps) | Proposed |
| --- | --- |
| Gates break when neglected (D15) | Days left alone, plus danger, plus nobody clearing it; the break starts a thread |
| Captive deadlines (D18) | Days |
| Thread stage deadlines (D23) | Days, each with a written "too late" stage |
| Doctrine fading | Days |
| Seasons | Days (a season every so many) |
| Companions on jobs | Days of travel each way |
| Upkeep | Each rest |

## What is not decided

- How many days a season, a typical deadline, a carriage leg.
- Whether a day also passes on a long walk inside one area (the proposal says no).
- Rival companies: who they are, and whether you can meet them.
- Which regional threads a Tower chapter closes.
