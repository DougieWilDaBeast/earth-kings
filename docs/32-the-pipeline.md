# 32 — How work moves: the stages and the pipeline

**What this is.** `dougie` asked on 2026-10-17 for a pipeline "that allows us to get work in and
start to fill out and collect and create and finish milestones as we move this game along", read
against three guides to the stages of making a game ([D202](06-decisions.md)). This doc has three
parts: where Earth Kings stands in those stages, what still gets expensive to change, and the loop
every piece of work goes round. The loop is how the project already works, written down in one
place, with four additions marked **Planned** until the founders say yes. The write-up with the
research behind it is the project's
[stages and pipeline page](https://claude.ai/artifact/PJaxFbEwGwJiGxrHYGv8Vp).

## Where the game stands in the stages

The guides name seven stages (GameMaker: planning, pre-production, production, testing,
pre-launch, launch, post-launch) and, inside production, the checkpoints prototype, first playable,
vertical slice, alpha (every feature in), beta (every piece of content in) and gold (ready to ship).
Read from `main` at `42fa58c` (#196, D201).

| Stage | Where it stands | What is missing | Closed when |
| --- | --- | --- | --- |
| 1. Planning | **Half.** Genre, look (64 px, [D63](06-decisions.md)), engine, the hook, four pillars ([D99](06-decisions.md)), platforms ([D100](06-decisions.md)) | The business half: cost, who owns what and how money is split, a release window, the price model, the size of the first paid release (question 23 was left open, [D168](06-decisions.md), [D186](06-decisions.md)) | The founders answer milestone 13's five questions below |
| 2. Pre-production | **Done for the First Hour, not for the game.** Docs 01 to 31, M0 to M18's prototypes, the route's art, the browser build | The whole game's shape: of the Tower's hundred floors ([D48](06-decisions.md)), which make the first release; a one-page art bible joining PixelLab and code-drawn art | Milestone 12 below |
| 3. Production | **Vertical slice reached** (the First Hour, [D168](06-decisions.md)); the Second Hour next ([D196](06-decisions.md)) | A finish line: without milestone 12 there is no alpha or beta to call; all open work in one list | Alpha and beta of the first release (milestones 14 and 15) |
| 4. Testing | **Machines strong, people thin.** 13 suites, the soak, the play log, CI on every PR; Ewan's play-tests 2 to 4 ([28](28-the-first-hour.md#how-it-was-tested)) | Strangers (call AV is unrun), a bug list with severities, the music heard by anyone | Five strangers play each milestone's build (milestone 7, then every milestone) |
| 5. Pre-launch | **Drafts.** The itch page (private), the store page draft ([29](29-the-store-page.md)), devlog drafts ([D148](06-decisions.md)), the clip tool ([D180](06-decisions.md)) | A Steam account and page, wishlists, a trailer, a press kit, somewhere players gather; the art and sound cleared for sale ([22](22-asset-provenance.md): P3, P4, P6) | Milestone 9 (Steam page and demo) |
| 6. Launch | **Not started** | Price, date, signed Windows build, age rating, a launch checklist | Milestone 16 |
| 7. Post-launch | **One piece laid:** saves survive updates ([D56](06-decisions.md)) | A way for players to report bugs, a patch rhythm, a changelog per build | Milestone 17 |

The eight design elements of the third guide (mechanics, gameplay, story, art, UI and UX, pacing,
motivation, testing) are scored in the write-up. The short version: mechanics are strong, the death
beat lands, and nearly everything else has been judged by bots, personas and one founder, not yet
by strangers.

## What still gets expensive to change

With Claude building, code is the cheap part (21 merges in eleven hours on 2026-10-16 to 17). The
cost of a late change has moved, not gone. Every piece of work is marked with the highest tier it
touches, and the tier decides who must say yes.

| Tier | What | Who says yes |
| --- | --- | --- |
| 1. Cheap any time | Code, numbers in `data/`, in-house art, docs | Claude, under the working rules; a persona meeting's vote stands (meeting 4) |
| 2. Costs founder time | Lore made canon, a play-test, a cue of music, a question in [30](30-questions-for-the-founders.md) | The founder whose time it is |
| 3. Costs money or credits | PixelLab art ([24](24-art-requests.md)), store fees, a paid tool | `dougie` |
| 4. Public, cannot be taken back | An itch push or Steam page, the name, a price, a release date, a promise in a devlog, saves in players' hands | `dougie`, in his own words (as for itch pushes today) |

The opposite risk is changing too much because change is cheap (the intern's reflection: "the
sixteenth thing built before the first one worked"). So the loop limits how much is started, not how
fast it is built: one game pull request at a time ([D194](06-decisions.md)).

## The loop

Every piece of work, from a voice note to a bug found by the soak, goes round the same eight steps.

| Step | What happens | Where it is written | Who |
| --- | --- | --- | --- |
| 1. Capture | Anything that might become work is written down in one line: what, who asked, where it came from (voice note, play-test, meeting, play log, CI, a founder's PR) | **Planned:** the inbox ([below](#the-inbox)); today the project chat, [09](09-wishlist.md) and the play-test asks in [28](28-the-first-hour.md) | Whoever finds it |
| 2. Sort | Given a kind (bug, feature, content, art, music, words, business, question), a tier, a milestone, and for a bug a severity | The inbox; questions only a founder can answer go to [30](30-questions-for-the-founders.md) | Claude, at each meeting or batch |
| 3. Shape | A short brief: what "done" looks like, how it is tested, what is **Inferred** | The PR description; a design meeting for anything with more than one honest answer | Claude, a meeting |
| 4. Queue | Takes its place in the milestone's order; anything not on the current milestone waits | The roadmap's **Next steps** ([05](05-roadmap.md)) | The order set by the last meeting (today [D194](06-decisions.md)) |
| 5. Build | One game PR at a time; docs, decisions, agenda and the doc it touches in the same PR ([D139](06-decisions.md)) | The PR | Claude; Ewan in his own PRs |
| 6. Prove | Suites, soak and ledger green in CI; then a person plays it: nothing is called reached on a bot's word alone | [28](28-the-first-hour.md#how-it-was-tested)'s play-test table | CI, then Ewan or a stranger |
| 7. Ship | An itch push with a devlog in players' words ([D148](06-decisions.md)), on `dougie`'s word | [28](28-the-first-hour.md#builds-on-itchio)'s build table | `dougie` says; Claude pushes |
| 8. Learn | The play log, the play-test and the next meeting turn what was found into new lines for step 1 | Meeting notes; [06](06-decisions.md) | Everyone |

### Kinds of work and who owns them

| Lane | Made by | Waits on | Its list |
| --- | --- | --- | --- |
| Code and data | Claude | Nothing but the queue | Roadmap **Next steps** |
| Art | `dougie` (PixelLab), code-drawn stand-ins meanwhile | Credits, monthly ([D169](06-decisions.md)) | [24](24-art-requests.md), in [D199](06-decisions.md)'s order |
| Music | `doug-md`, in-house stand-ins meanwhile ([D185](06-decisions.md)) | Ewan's time | [31](31-music.md) |
| Words and lore | Drafted by Claude and meetings, settled only by a founder | The founders' answers | The agenda ([answers.md](worldbuilding/answers.md#what-is-still-to-decide)), [30](30-questions-for-the-founders.md) |
| Business | `dougie` | Nothing is started | Milestone 13 below |

### Bugs: four severities

**Planned** until the founders adopt the inbox. Severity is set when a bug is sorted (step 2).

| Severity | Meaning | Rule |
| --- | --- | --- |
| S1 | Crash, a save lost, a run stuck with no way on | Fixed before anything else; no itch push with an S1 open |
| S2 | A milestone's "done when" fails (Auto never reaches the Tower, [D197](06-decisions.md)) | Fixed inside the milestone |
| S3 | Wrong but playable (a word, a number, a sprite) | Batched into the next PR that touches the same files |
| S4 | Cosmetic | When someone is already there |

## Milestones: how one is opened, filled and closed

A milestone moves through six states. Only a founder moves one to **Closed**.

1. **Proposed** — named in a meeting or by a founder.
2. **Defined** — it has a one-line "done when", its list of work, and what it needs from each lane.
   Recorded as a decision.
3. **Building** — its work goes round the loop, one game PR at a time.
4. **Built** — every item is merged and CI is green.
5. **Played** — a person who did not build it has played it: Ewan, then strangers. What they find
   is sorted back into this milestone (S1, S2) or a later one.
6. **Closed** — a founder says so, as `dougie` did for the First Hour ([D168](06-decisions.md)).

### The milestones

Milestones 1 to 11 are design meeting 5's picture ([D193](06-decisions.md)). Milestones 12 to 17
are **Planned**, proposed here so the stages the game has not reached have a place to be filled.

| # | Milestone | Stage | Now | Done when |
| --- | --- | --- | --- | --- |
| 1 | The freeze | Pre-production | Closed | |
| 2 | The First Hour built | Production (vertical slice) | Closed | |
| 3 | The First Hour passable | Production | Reached | |
| 4 | The First Hour with stakes | Production | Half | 1 to 3 falls in 16 runs to floor 5 ([D113](06-decisions.md)) |
| 5 | The First Hour readable | Production | Mostly | A9, the Tower, in the game |
| 6 | Played by a person | Testing | Reached | |
| 7 | The gamer week for real | Testing | Not run | Five strangers, named by the founders, play with the play log on |
| 8 | Demo-clean | Pre-launch | Half | Ewan's cues or the stand-ins kept by a founder who heard them; [22](22-asset-provenance.md) P3, P4, P6 cleared; every AI-made asset that ships listed for the store's disclosure (below) |
| 9 | Steam page and demo | Pre-launch | Waits ([D169](06-decisions.md)) | A page up, the First Hour as the free demo |
| 10 | Native Android | Launch | Waits ([D169](06-decisions.md)) | |
| 11 | The Second Hour | Production | **Building** ([D194](06-decisions.md), [D196](06-decisions.md)) | A person climbs to floor 10 and plays a chapter two; how long it took to build is written down, to size the hours after it |
| 12 | The game at release, on one page | Pre-production | **Planned** | Which chapters, how many memories a lead, which cut systems return, the art bible; agreed by both founders |
| 13 | The business basics | Planning | **Planned** | Five answers in [30](30-questions-for-the-founders.md), questions 28 to 32: who owns the game and how its money is split, the budget a month, the price model, a release window, Early Access or not |
| 14 | Alpha of the first release | Production | **Planned** | Every system the first release needs is in and played |
| 15 | Beta of the first release | Production, testing | **Planned** | Every floor, memory and track the first release needs is in; only S3 and S4 bugs left |
| 16 | Launch | Launch | **Planned** | Price, date, signed builds, age rating, the launch checklist |
| 17 | After launch | Post-launch | **Planned** | Players can report a bug; a patch and its changelog within a week |

## What other small teams teach

From the research behind the write-up (sources there). Each line is a rule this doc already follows
or a reason for one of its **Planned** parts.

- **Estimate from the second thing built, not the first** (Rami Ismail). The Second Hour is timed so
  the rest of the game can be sized (milestone 11).
- **Cut early; keep a "later" list** (Into the Breach cut about 60%, Derek Yu: "being behind schedule
  is a great excuse to cut"). New ideas go to step 1 and wait for a milestone; they do not join the
  one being built.
- **Test in rounds of five** (Nielsen: five users find most usability problems; three rounds of five
  beat one of fifteen). Milestone 7 and every milestone after it.
- **Wishlists do not go stale; put the Steam page up once genre, look and three places are settled**
  (Chris Zukowski). A game gets one Steam Next Fest, needs a public page and a Steam demo for it, and a
  browser build does not count (Valve). The page's timing is the write-up's call 2.
- **Itch is the lab; Steam is the launch.** The Steam build must look clearly better than the itch
  one, and Early Access is a launch, not a test (Zukowski).
- **Stores ask what AI made.** Since January 2026 Steam asks to disclose AI-made art, sound and text
  that ship (PixelLab art included) but not code assistants; itch.io has AI tags. [22](22-asset-provenance.md)
  is where each asset's maker is recorded, so the forms can be filled in truthfully (milestone 8).
- **Tests define done for AI-written code.** Our suites, soak and CI already do; a model drifting into
  Godot 3 habits is caught there, not by reading.
- **Write the founders' agreement before there is money** (ownership, split, who decides, what happens
  if one leaves). Question 28.

## The inbox

**Planned**, waiting on `dougie`'s word on how work is tracked (the write-up's "How to track it", call
BH, reopened by his question of 2026-10-17 09:40). Until then the loop's first step keeps today's places.
The recommendation is **GitHub, made strict**, with no new app:
1. Labels and milestones set up by a script: kind, tier 1 to 4, severity S1 to S4, "waits on Will",
   "waits on Ewan", and one GitHub milestone per row of the milestones table.
2. One issue per piece of work, opened by whichever Claude hears of it; short issue forms for a founder
   filing one by hand.
3. A CI check in the style of the ledger: a PR closes an issue or says it is docs-only, a new D number is
   the next free one, every question in [30](30-questions-for-the-founders.md) has a default; a daily job
   labels any issue with no kind or milestone "needs sort".
4. One GitHub Projects board, created once by `dougie` (the connector cannot), whose built-in workflows
   add every issue and move it to Done when its PR merges.
5. A status page Claude refreshes after each merge: what is in flight per milestone, and what waits on
   each founder.
The docs, the decisions log, the agenda and the founders' questions stay as files in the repo, because
the code and the tests read them and they change in the same PR as the code ([D139](06-decisions.md)).
Weighed against it: Linear (free up to 250 issues, then paid, a second place to look), Notion (a second
copy of the docs that drifts), and repo files only (strict, but no inbox or board).

## The rhythm

Each milestone ends the same way: built, an itch push on `dougie`'s word, Ewan plays it, a design
meeting reads what he found, and a founder closes it or sends work back round the loop. Between
milestones, the founders' open questions are batched into [30](30-questions-for-the-founders.md) so
they are asked once, read aloud and answered by voice note.
