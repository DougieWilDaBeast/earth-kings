# Answers

What has actually been settled, and who settled it. One entry per question that has moved, keyed by
its ID in [15 — The Question Book](../15-the-question-book.md).

Entries are written in the house style of [09 — Wishlist](../09-wishlist.md): the words as spoken in
a blockquote, then a **bold status**, then what it means. **A quote is never edited.** If what
somebody said is unclear, the entry says so and asks rather than tidying it into sense.

---

# What is still to decide

The agenda for the next session, in the order it is worth spending time on. Every row points at an
entry further down this file; nothing here is new information, it is the open work gathered into one
place so it can be worked through rather than rediscovered.

Run `res://tools/question_report.tscn` for the live count. After joint session 1 (2026-09-24) it
reads **79 of 366 answered, 26 partly answered, 169 still open, 143 drafts across 129 questions**.

**The standing instruction** from that session: a question that does not matter yet stays open.
Section 1 is what the next milestone cannot start without. Everything below it is real, but it can
wait for a session that has nothing more urgent.

## 1. What joint session 1 left open — needed next

Every item here blocks something on the [roadmap](../05-roadmap.md). Most are one sentence each.

| #  | Where | The question |
| -- | ----- | ------------ |
| 1  | `GT11`, `D16` | **How many floors has the Tower, and how many make a chapter?** Ten ship. A hundred was floated and then doubted — "maybe 100 floors is too much. Maybe it's not enough". Every rule the session made counts in fives: the world changes every five floors, a key is needed every five, the census shows every five. |
| 2  | pillar 5, `SK6`, `D27` | **Does the world still run on steps?** "I think that the time the world should only really change after you complete, let's say, five floors of the tower" [00:28:42] sits against _the world runs on steps, not turns_. One reading keeps both: **steps drive the small clocks** (doctrine fading, gates breaking, news, sieges) **and Tower chapters drive the story**. That is an inference. Confirm it or pick one. |
| 3  | `D36` | **The fight.** The move to a Dungeon Settlers-style real-time-with-pause fight was agreed, and a research deep dive was asked for before anything is built. What it has to answer is in [18 — Combat direction](../18-combat-direction.md#what-the-research-has-to-answer). **First pass done** — [investigation/07](../investigation/07-dungeon-settlers-combat.md); what is left needs an hour of hands-on play. |
| 4  | `CO7`, `SM1`, `D21` | **Can a death be reloaded?** Save-scumming is allowed "to be revisited". A lead's death now ends a whole world. If reloading undoes that, the sixteen chances are a menu. This has to be settled before the death of a world is built. |
| 5  | `MX20` | **In the second world, is there a living copy of the first lead** as well as their ghost and their weapon? |
| 6  | `CH10`, `SF1` | **What does a lead remember?** "All 16 lose their memories", then "maybe your memories are intact". The reading taken: the fall takes the memory, the mark is recognised anyway. Confirm. |
| 7  | `D29` | **Is the lead chosen or answered for?** The session says "you choose Cassius"; the build asks four questions and names you. Both can stand — the quiz names you, _Show me all sixteen_ lets you choose — but say which is the front door. |
| 8  | `D37` | **Assists.** `dougie` summed it up as five assists for a kill's experience and `doug-md` agreed; `doug-md` had also said ten for ordinary grunts and five for a healer's assists. One number, or two? |
| 9  | `CO2` | **Sprite size — 64, 32 or 16?** "that's still an open for now, but we do need to generate stuff" [01:07:40]. PixelLab credits reset on 2026-09-27 with 15% left; the [asset list](../19-asset-list.md) has to be generated at one size. The model game measures in the **32 class** ([investigation/07](../investigation/07-dungeon-settlers-combat.md#13-sprite-size-and-frame-counts)). |
| 10 | `CH13` | **Sixteen ways to fight, six classes.** The roster needs sixteen distinct fighting styles; `classes.json` has six. More classes, or a class per character, or styles inside classes? |
| 11 | `D38` | **How does the party grow from four to six?** A level, a rank, a Tower chapter, something bought? |
| 12 | `MX13` | **Where does a dead lead's weapon land the first time** — somewhere easy to find, or random? |
| 13 | `GT2`, M5 | **You cannot leave a gate until it is beaten.** ~~The build lets a party retreat and keep the floors taken.~~ **Built 2026-09-24:** once a floor is won, every step is the next floor. Say so if that was not what you meant. |
| 14 | `GT3` | **Timed events.** `doug-md` asked whether failing to do things in time costs you. `dougie`: "we should try to test what happens when we're playing first". Deferred to playtest, on purpose. |
| 15 | `LP13`, `LP2` | **What is a hearth, or a background, for someone who fell from the sky?** The sixteen are not from this world, and they land at random. The reading taken in [14](../14-lore-pools.md#what-joint-session-1-changed): a hearth becomes the crash site, and a background is the life above, found out in pieces. Confirm or replace before any pool is written. |

## 2. Eleven Part I questions that need a straight answer

`doug-md` answered Part I but eleven of them did not land cleanly. Each entry already writes out the
one follow-up it needs. Of these, only `SK6` is needed next (see item 2 above); `LN1` matters as
soon as the map is resized. The rest can wait.

| ID     | Status          | The follow-up                                                                            |
| ------ | --------------- | ---------------------------------------------------------------------------------------- |
| `SK6`  | Partly answered | **How long is a step?** He made the step the clock — time only moves when the party does — then handed the scale back: "one second… or one minute… entirely up to yourself". Everything in the game is priced in steps, so this one gates the rest. |
| `LN1`  | Blocked         | **Is the continent a month across, or half a year?** He gave 30 days by carriage and then six months on foot, seconds apart. A carriage is not six times a walker. |
| `GT12` | Blocked         | **Is the Spire Archon something that was _put_ there, or something that _arrived_?** The only question in Part I he declined — "I am not sure." D25 already ships the fight. |
| `SK2`  | Partly answered | One sun, then the answer left the sky for gate timers. **Is the sun ordinary, and is anything else up there by day?** |
| `LN4`  | Partly answered | There is undiscovered ground. **Is there a safe, boring, administered elsewhere that this map is the frontier of?** |
| `LN6`  | Partly answered | Three landmark _kinds_ landed, no names. **Name them** — placeholders are fine. |
| `CL4`  | Partly answered | Cadence answered: any year can be the bad one. **What does a bad year actually look like?** |
| `LF8`  | Partly answered | Diet is opportunistic and hunger reaches cannibalism. **What is the staple crop, and what is the herd?** |
| `LF9`  | Partly answered | Life gathers at gates and is changed by them. **Does anything exist _only_ there, and what does long exposure do to farmland?** |
| `MK1`  | Partly answered | No single ceiling; technology is uneven by region. **What is the most advanced thing anyone can build, and who builds it?** |
| `GT9`  | Partly answered | The Tower neither restrains nor generates gates — "but maybe the tower can help them generate". **Does it influence them at all?** |

## 3. Five contradictions that have to be settled

These are not gaps. They are two statements that cannot both stand.

| Where                 | The collision                                                                                  |
| --------------------- | ---------------------------------------------------------------------------------------------- |
| notes 01–05 vs note 06 | **Probably settled — confirm.** In joint session 1 `doug-md` keeps _tower_ and _gate_ apart without a slip, which supports the reading Part I's entries took. **"Tower" means two things.** He says _tower_ where the book says _gate_ throughout the first five notes, and in `GT5` he catches himself: "a gate looks like a massive tower, or, sorry, a gate looks like a wormhole." Note 06 keeps them apart. The whole of Part I reads differently depending on the answer. |
| `SK5` + `SK6` vs repo | A 365-day year and the repo's 120 steps per season (480 steps a year) put a step at about a day and a half. He guessed "one second or one minute". Two of the three have to give. |
| `GT9` vs D08          | He has gate rank rising the **closer** you are to the Tower. D08 has it rising with **distance**. This inverts the map. |
| `CL2` vs repo         | He describes a season front that **sweeps** south to north over a warm equator. `Season` flips globally at a step count. `WorldGen._latitude` already agrees with him; the season clock does not. |
| `GT6` vs repo         | A broken gate should **spread its element across the ground and keep spreading**. The repo raises local danger 25pp and changes nothing else. |

## 4. Three slots with no noun in them

Canon says these exist and matter. Nobody has named them.

| ID    | The empty slot                                                                             |
| ----- | -------------------------------------------------------------------------------------------- |
| `LN6` | The three landmarks everyone can name — the first gate, the great city, an unsealed broken gate. |
| `MK8` | The material worth a war: "maybe a stone or a rare element… worth millions and millions and millions." |
| `MK9` | The "legendary technology man" whose blueprints a gate destroyed. |

## 5. One question nobody has asked

`SK10` has "a higher beam that essentially governs these towers and they do look back". `GT10` has
the Tower built by something that "is not other people… a different form of existence". `GT12` is the
Spire Archon, undecided.

Joint session 1 added two more: `FA1` has real gods above the sixteen, met only after the Tower, and
a force that means to leave one world standing; `GT10` has the Tower built as a proving ground by
whoever is found out at the end.

**Are these the same thing?** Five answers circling one entity across three notes, and no entry
connects them. Deciding it would close `GT12`, which is otherwise the only question in Part I with
nothing in it at all.

## 6. Ten questions where the drafts disagree

Two lineage sources argue opposite sides. These need a pick, not an answer — the reasoning and the
costs are already written up in the [divergence ledger](divergence-ledger.md).

`AR2` · `DV1` · `FR7` · `HS2` · `KN1` · `LN4` · `MX19` · `NW7` · `SM7` · `SM8`

Joint session 1 retired three — `MX11`, `SM5` and `OT8` — by answering them outright. `FR7` and `SM8`
were answered in part; their drafts still argue about the half nobody spoke to.

A further **88 questions carry a single draft** waiting on a yes, a no, or a better idea. Those are
the cheapest progress available: the argument is already made, so each one costs a sentence.

## 7. Six things Part I made canon that the game does not model

Scope calls rather than lore calls. Each one is now true of the world and absent from the build.

| From            | What is now true                                                                            |
| --------------- | --------------------------------------------------------------------------------------------- |
| `LN2`, `LN9`    | **Flight.** Blimps are how some people cross a hundred miles, and the map edge is crossed by air, ferry or tunnel. |
| `SK3`           | **The moon is a place** that can be reached and used, by few. |
| `LF5`           | **A world-spanning monster-slaving organisation.** With `LF3` (completely alive) and `LF4` (they interbreed with people), this is slavery of people. |
| `GT13`          | **The Spire is inhabited**, floor by floor, wherever resources allow. The climb currently treats every floor as a battle. |
| `GT14`          | **The underworld is occupied**, and `LN2`'s tunnels are somebody's roads. |
| `CL3`, `CL7`    | **Winter kills**, by exposure and by starvation, and the hungry month falls at the Brown-to-Ice turn. Nothing in the game kills anyone for the season. |

---

## The statuses

| Lead                   | Means                                                                                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `**Answered.**`        | Said plainly by a founder. Canon                                                                                                                                         |
| `**Partly answered.**` | Half of it landed. The entry says which half is still open                                                                                                               |
| `**Inferred.**`        | Nobody said it outright; it follows from the IDs named in the entry. **Provisional** until a founder confirms                                                            |
| `**Contested.**`       | Two founders answered differently. Goes to the [divergence ledger](divergence-ledger.md)                                                                                 |
| `**Blocked.**`         | They started and trailed off. The entry writes out the one follow-up question needed                                                                                     |
| `**Noted.**`           | A guest answered. Recorded and quotable, not canon on its own — see [respondents](respondents.md)                                                                        |
| `**Proposed.**`        | A lineage source offers a drafted answer, with its costs already worked out. Adopted only when a founder says so — see [16 — Lineage entries](../16-lineage/00-index.md) |

An entry may also carry a `↳` line recording what the answer did to other questions — implied them,
contradicted them, or re-opened them. That is the cascade, and it is written down rather than
remembered.

## The shape of an entry

```
## SK6 — What is a step?

> "…I mean it's not a pace is it, it's — call it a minute of walking, so a day is what,
>  four hundred of them, and that makes the book thing about two days which feels right…"
> — dougie, 2026-09-14, note 03

**Answered.** A step is about a minute's walk; roughly 400 to a day.
↳ Re-opened KN1: at 400 steps a day the 900-step doctrine fade is about two days, which is far
  shorter than "knowledge you maintain" implies. Worth a look before it is canon.
```

---

# Part I — answered by a founder

All six recordings of Part I were transcribed on 2026-09-14 and read against the book. `doug-md` is
a founder, so what he said plainly is canon.

| Note | Transcript                                                                                                 | Covers       |
| ---- | ---------------------------------------------------------------------------------------------------------- | ------------ |
| 01   | [Physical](voice-notes/2026-09-14-doug-md-part-1-a-physical.md)                                            | `SK1`–`SK10` |
| 02   | [Land, scale and edges](voice-notes/2026-09-14-doug-md-part-1-b-land-scale-and-edges.md)                   | `LN1`–`LN12` |
| 03   | [Climate and season](voice-notes/2026-09-14-doug-md-part-1-c-climate-and-season.md)                        | `CL1`–`CL8`  |
| 04   | [Life, bodies and the monstrous](voice-notes/2026-09-14-doug-md-part-1-d-life-bodies-and-the-monstrous.md) | `LF1`–`LF14` |
| 05   | [Matter, craft and making](voice-notes/2026-09-14-doug-md-part-1-e-matter-craft-and-making.md)             | `MK1`–`MK12` |
| 06   | [Gates, the Tower and the deep](voice-notes/2026-09-14-doug-md-part-1-f-gates-the-tower-and-the-deep.md)   | `GT1`–`GT15` |

Two things carry across every entry below.

**The transcripts are machine-made.** Passages the model was unsure of are marked `[unclear]` in the
note. Where an entry rests on one of those, it says so and stays provisional until somebody plays the
audio back. Nothing here has been tidied into sense.

**"Tower" is overloaded.** In notes 01–05 he repeatedly says _tower_ where the book says _gate_ — "if
it's an ice tower, then it should be snowing around the area", "the oldest tower or maybe the dungeon
break". In note 06 he separates the two cleanly and answers `GT9`–`GT13` about **the** Tower. The
reading taken below is that _tower_ in notes 01–05 means a gate, and he also uses _dungeon_ for the
same thing. That is an inference, not something he said, and it is the single most load-bearing
follow-up in Part I: **when you say "tower", do you mean the Spire, or do you mean a gate?**

---

**I.a Sky, time and cosmos — [note 01](voice-notes/2026-09-14-doug-md-part-1-a-physical.md).**

## SK1 — Is this a planet? Does anyone in the world know that?

> "This is a planet. Definitely people would know about it. People that have researched what this
> planet is. And it might be public news, it just depends on if they want to share that."
> — doug-md, 2026-09-14, note 01

**Answered.** It is a planet, and that is known — but as research somebody owns and may sit on
rather than as common knowledge.
↳ Falls out: there are people who research the shape of the world, and withholding what they find is
a thing they can do. That is a `KN` question the book has not asked yet.

## SK2 — What is in the sky by day — one sun, more, something that is not a sun?

> "I think implementing the sun would be very good. One sun, more than likely. But I do think it
> would be cool to add maybe a timer for different towers, or maybe just the one tower."
> — doug-md, 2026-09-14, note 01

**Partly answered.** One sun. The rest of the answer leaves the sky and goes to gate timers, so
nothing was said about whether the sun is ordinary, or what else is up there by day.
↳ The timer half belongs to `GT3`, where he answers it properly.

## SK3 — Moons: how many, what do they do, does anything in the world key off them?

> "Yeah, I think there should be a moon. I think that if you wanted, the moon would be a place of
> interest, but not many people kind of use the moon."
> — doug-md, 2026-09-14, note 01

**Answered.** One moon, and it is a **place** — somewhere that can be reached and used, by few.
↳ Falls out: reaching the moon is possible in this world. That is a much larger statement than the
question asked for and it bears on `MK1` (technology ceiling) and `MK9` (lost making).
↳ Nothing was said about the moon driving anything on the ground — tides, cycles, timing. Still open.

## SK4 — Are there stars, and are they navigable? Does anyone chart them?

> "Yes, I think there definitely should be stars, as many as there is in real life. I don't think
> that in the current time of world we have the ability to navigate the stars. But people do chart
> them and write them down, like scholars and stuff."
> — doug-md, 2026-09-14, note 01

**Answered.** Stars as in life. Charted by scholars, but not yet used to navigate — the record
exists ahead of the skill.
↳ Reads naturally against `MK3` (books are copied by hand) and `LN9` (ordinary people do not
travel far): star charts are a scholarly object, not a traveller's tool.

## SK5 — How long is a day, and how long is a year in days?

> "I think we can make it plain and simple that how long is a day? It's 24 hours. And how long is in
> years and days? I think let's go 365."
> — doug-md, 2026-09-14, note 01

**Answered.** A 24-hour day and a 365-day year. Deliberately ours, deliberately unremarkable.
↳ Collides with the repo: `season.steps_per_season` is 120, so a year is about 480 steps. With
`SK6` left open, 480 steps must now stretch over 365 days — roughly three-quarters of a step per
day. See `SK6`.

## SK6 — What is a step?

> "So I do think that a step in this game will count towards time moving as well. If you don't take
> a step, time will not move. But when you take one step, maybe one second will move or one minute
> will move. It's entirely up to yourself."
> — doug-md, 2026-09-14, note 01

**Partly answered.** The important half landed and it is a design statement, not a measurement:
**the step is the clock.** Time does not pass unless the party moves. The world does not tick while
you stand still.

The scale was explicitly handed back — "one second… or one minute… entirely up to yourself" — so the
number the book was asking for is still open, and `SK6` is the question everything else is priced
against.
↳ Re-opened by `SK5`: a 365-day year and a 480-step year only reconcile at roughly a day and a half
per step, which is nowhere near "one second or one minute". One of the three has to give.
↳ Still gating `KN1` (900-step doctrine fade), `GT6` (600 steps to a gate break), `CL2`, `LN1`,
`LN9` and `NW1`, exactly as the book predicted.
↳ Confirms the repo's behaviour rather than overturning it: `World._upkeep` already runs off steps
walked, not off real time.

## SK7 — Does the world have weather beyond season — storms, drought, a night cycle that matters?

> "I think the world will have weather beyond the season. Like in the summer time there might be a
> storm, but in the winter there might be drought. Yeah, I do think so."
> — doug-md, 2026-09-14, note 01

**Answered.** Yes — weather is its own layer over the season.
↳ The example inverts what you would expect (drought in winter, storms in summer). Left as spoken.
If that was deliberate it is a good detail about this world; if it was a slip it should be
corrected before anyone builds on it.

## SK8 — Is there darkness that is dangerous on its own, or is night just dimmer?

> "Yeah, I think the darkness should be kind of a safe haven for the monsters. Like they really like
> to hunt and predatory animals will be active. I think darkness indicates a bit of fear and to
> watch your back."
> — doug-md, 2026-09-14, note 01

**Answered.** Night is not dimmer, it is _theirs_. The dark is not hostile in itself; it is cover
for the things that are, and what it does to a person is fear.

## SK9 — Is the sky the same everywhere, or does it change over the Tower, over a broken gate, over the sea?

> "I think that over the tower, depending on which tower is there. If it's an ice tower, then it
> should be snowing around the area. Or if it is a fire tower, there is like fire around and there's
> magma, there's volcanoes. Over broken gates, there might be lightning and dark clouds and whatever
> tower has been broken. I think that the environment around that tower should start to expand as
> well."
> — doug-md, 2026-09-14, note 01

**Answered.** The sky is local and it reports what is underneath it. A gate has an element, and that
element takes the weather and the ground around it — and a broken one **keeps spreading**.
↳ This is the same answer as `GT6` ("it spreads the element that it is carrying") arrived at from
the other direction, two notes apart. Two independent passes landing on one mechanic is a good
sign for it.
↳ Falls out for `LF9` and `CL5`: a gate does not merely raise local danger, it rewrites local
climate. The repo's flat 25pp danger bump is a thinner thing than what he described.
↳ Reads _tower_ as _gate_ — see the standing caveat above.

## SK10 — Does anything up there look back?

> "I think that there is a higher beam that essentially governs these towers and they do look back.
> And they can see everything that they're doing and everyone is doing. They can see what they see,
> they're able to see and they're able to look back 100%."
> — doug-md, 2026-09-14, note 01

**Answered.** Yes. Something above governs the gates and watches everyone, without qualification.
↳ "a higher beam" is almost certainly _a higher being_ — the model heard it as spoken. Kept as
transcribed; worth confirming, because the word chosen matters for `PW` and `FA`.
↳ Bears hard on `GT10` (who built the Tower — "a different form of existence") and `GT12` (the
Spire Archon, which he could not answer). These may be the same thing, and nobody has said so.

---

**I.b Land, scale and edges — [note 02](voice-notes/2026-09-14-doug-md-part-1-b-land-scale-and-edges.md).**

## LN1 — How large is the continent in days of walking, edge to edge?

> "A large continent of walking edge to edge would be, in my opinion, 30 days of travel by horse and
> carriage or length to length."
>
> "You might have, might be half a year of walking, maybe six months of walking, and it kind of
> depends on how big you want to make it or how small of a continent you're on."
> — doug-md, 2026-09-14, note 02

**Blocked.** Two figures, given a few seconds apart, that do not sit together: 30 days by carriage,
then six months on foot. A carriage is not six times a walker, it is perhaps two or three. Both
passages are marked `[unclear]` in the transcript.

The follow-up: **pick one — is the continent about a month across, or about half a year across?**
↳ He also rejects the premise before answering it: "I think that this world is not just a
continent… continents can be different sizes". `LN3` confirms that deliberately.
↳ Blocked on `SK6` as well. Until a step has a duration, days of walking cannot be converted into
the steps the game actually runs on.

## LN2 — What is beyond the map edge — ocean, more land, nothing you can reach?

> "There is ocean, there is more land, there's different areas you can go to, there's ports, there
> are boats, there is different ways of traveling."
>
> "Yeah, by flight, by ferries, underground tunneling. There's so many ways that you can get to the
> other side. You just have to find them."
> — doug-md, 2026-09-14, note 02

**Answered.** The edge is not an edge. Ocean, then more land, reachable by sea, by air and by
tunnel — and the routes are **found**, not published.
↳ Confirms the repo per the book's `(repo:)` rule: `ferry.gd` already runs coastal cutters between
ports, and that is now canon rather than convenience.
↳ Falls out: flight and underground tunnelling both exist as travel. Neither is in the game. Flight
in particular has to be squared with `MK1`.
↳ "underground tunneling" meets `GT14` — there is an occupied underworld — so tunnels may be
somebody's roads rather than engineering.

## LN3 — Are there other continents, and does anyone here know it?

> "Yes, there is definitely other continents and a lot of people know it. Some people don't and some
> people figure it out along the way."
> — doug-md, 2026-09-14, note 02

**Answered.** Other continents exist and it is ordinary knowledge, unevenly held.

## LN4 — Is the map the whole known world, or the frontier of a larger one that is safe and boring?

> "So I think that the world is quite big and there is definitely locations that have not been
> discovered yet."
> — doug-md, 2026-09-14, note 02

**Partly answered.** The map is not the whole world and there is undiscovered ground. He did not
answer the sharp half of the question — whether there is a _safe, boring, administered_ elsewhere
that this map is the frontier of.
↳ Leaves `src-barbarian`'s proposal for `LN4` standing rather than settling it: it proposes exactly
that safe crowded elsewhere, and he neither took it nor refused it.

## LN5 — Where does fresh water come from, and who controls it?

> "Freshwater comes from, you know, you have rivers, you have seas, but I think that there should be
> not necessarily a government, but people in power of the community that distribute world basics
> and daily essentials. And there should be taxes and, you know, people with higher power and they
> can control it."
> — doug-md, 2026-09-14, note 02

**Answered.** Rivers, and control is local rather than national — community strongmen who hand out
essentials and tax them. Not a state, but not a commons either.
↳ Marked `[unclear]` in the transcript; the reading is coherent and consistent with `LN8`, but
confirm before quoting.
↳ Falls out into `RU` and `EC`: whoever distributes the water is the real government of a village,
whatever the map calls them.

## LN6 — Name the three landmarks everyone in the world can name.

> "The first tower, which we haven't come to a name yet. I think the largest continent, the main
> city of that continent and a dungeon that has broken and hasn't been sealed yet."
> — doug-md, 2026-09-14, note 02

**Partly answered.** The three _kinds_ landed — the first gate, the great city of the largest
continent, and a broken gate still standing open — but none of them has a name, and he says so
outright. The question asked for names.

The follow-up: **name them.** Three proper nouns, and they can be placeholders.
↳ Marked `[unclear]`.
↳ `LN11` names the first tower again as the oldest visible thing, so it is load-bearing in two
answers while still being nameless.

## LN7 — Which direction is "toward trouble" and which is "toward home"? Is there a cultural north?

> "There is a direction towards trouble and a direction towards home can interlink. Trouble is
> anywhere and home is where you make it. So you have to find that spot and you must use your wits
> to get out of trouble."
> — doug-md, 2026-09-14, note 02

**Answered.** As a refusal. There is no cultural north. Danger is not a direction and home is not
a place you are from, it is one you make. That is a real answer and it is worth more than a compass
rose would have been.
↳ Marked `[unclear]`.
↳ Squares with the repo: `Site.HOME` is one place per world that the run starts at, and `Home`
upgrades a bed there. "Home is where you make it" says the game should let you make another.
↳ Contradicts nothing, but it does remove the usual fantasy frame — no dark north, no civilised
south.

## LN8 — Roads: who built them, who maintains them, are they safe?

> "So roads are built by the people that have been surrounded in that area… higher royalty and maybe
> higher power people can distribute more wealth in producing the roads."
>
> "But outside of that, you might have roads that are there for hundreds of years and they haven't
> been maintained, but they're still able to be used."
>
> "Roads can be safe. They can be unsafe. They can be a mix of both. It kind of just depends on what
> location you're going in."
> — doug-md, 2026-09-14, note 02

**Answered.** Roads are local infrastructure paid for by local wealth. Rich dense places have kept
roads; everywhere else has centuries-old ones that still work untended. Safety is a property of
where you are, not of roads.
↳ Marked `[unclear]` throughout.
↳ Adjusts the repo's `(repo:)` note, which reads roads as Heart Empire ground. He describes no
empire behind them at all — they are parish-built. Worth raising when `RU` is asked.
↳ Falls out for `MK9`: roads nobody maintains that still work after hundreds of years are close to
being lost-hand making, and he answers `MK9` yes.

## LN9 — How does an ordinary person travel a hundred miles — or do they simply never?

> "Some characters or some ordinary people, they might travel by horse and carriage, horse, walk.
> They might get on a blimp. They might go through boats."
>
> "some people don't travel because they get comfort in their own surroundings and they will never
> leave and they settle down."
> — doug-md, 2026-09-14, note 02

**Answered.** Both. The means exist — foot, horse, carriage, boat, **blimp** — and plenty of people
still never use them, by preference rather than by prohibition.
↳ Partly `[unclear]`, including the line the blimp is in.
↳ **Blimps.** Said plainly, and it is the second time flight has come up (`LN2`). This is the
largest single thing Part I adds to the world and it needs `MK1` to account for it.

## LN10 — Is there a place nobody goes, and is the reason true?

> "Like a dungeon break, you would not go to that place because the environment and world is is very
> tough and people can die and dungeons in general."
>
> "People don't go unless they want to scout it out, go into the dungeon or simply observe it. And,
> you know, most ordinary people would never like to go to the dungeons."
> — doug-md, 2026-09-14, note 02

**Answered.** Yes, and **the reason is true** — broken gates really will kill you. The avoidance is
accurate rather than superstitious.
↳ Both quoted passages marked `[unclear]`.
↳ Falls out for `DV`: delvers are people who go where the fear is correct. That makes delving
strange rather than brave, and it leans toward `src-barbarian`'s reading of `DV1` as a trade
parents do not want for their children.

## LN11 — Is the land itself old and worn, or young and raw? What does the oldest visible thing look like?

> "The world is old. Like it has a lot of years pumped into building up this world. Some places will
> be old and worn and the newer places will be young and raw."
>
> "The oldest visible thing look like will be the tower that first came to this world."
>
> "The major main city of where the resistance kind of came together and built this land to protect
> itself will be very old, but will be maintained."
> — doug-md, 2026-09-14, note 02

**Answered.** An old world with new patches. The oldest visible thing is the **first gate**, and the
second oldest is the city built by "the resistance" that formed against it.
↳ Falls out, large: there was a **resistance**, it was collective, and the great city is its
monument. That is the first shape of a history anybody has given. It bears on `HS`, `RU` and
`FA`, none of which have been asked yet.
↳ "the tower that first came to this world" — _came_, not _was built_. Consistent with `GT10`.

## LN12 — Does the geography mean anything?

> "Yeah, the geography definitely means everything. Like if a tower is placed in a snow biome, but
> it's a fire tower, it will completely reshape that geography of where that world is. The same
> within the coast, like if a tower is at a coast, it will change the geography around it and people
> will tend to stay away."
> — doug-md, 2026-09-14, note 02

**Answered.** Geography means everything, but not in the way the question expected. He does not
answer with centre and periphery or elevation and status — he answers that **gates overwrite
terrain**, and settlement arranges itself around that.
↳ Third statement of the same mechanic, after `SK9` and before `GT6`. It is the most consistent
thing he said across all six notes.
↳ The question's own framings — Tower at a centre, coast as periphery, elevation as status — are
untouched and still open.

---

**I.c Climate and season — [note 03](voice-notes/2026-09-14-doug-md-part-1-c-climate-and-season.md).**

## CL1 — Why a clover? Who named the seasons, and does the name predate the world or belong to one people?

> "I think the clover will symbolise to people that they know what season it is in. Lesser green
> will be springtime, green will be summer, brown will be autumn, ice will be winter."
>
> "No one really names them, but it was a common collective intelligence to what it symbolises."
> — doug-md, 2026-09-14, note 03

**Answered.** Nobody named the clovers. The mapping is common understanding that was never
authored — it belongs to everyone and to no people in particular.
↳ Whole passage marked `[unclear]`.
↳ This closes off the more interesting readings deliberately: no priesthood owns the calendar, no
culture imposed it. Anyone wanting the seasons to be a `FA` or `TG` hook has to reopen it.

## CL2 — Does the season turn everywhere at once, or does it sweep?

> "I think the seasons genuinely would change as more time goes on and it kind of does sweep from
> bottom to top. Or if you're in the middle it's more warmer, kind of like an equator. But I do
> think that the locations can be inadvertently changed by the tower's existence."
> — doug-md, 2026-09-14, note 03

**Answered.** It **sweeps**, south to north, over a world with a warm equator — and gates override
it locally.
↳ **Contradicts the repo directly.** `Season` flips globally at a step count; he describes a
travelling front plus latitude. The repo already has latitude bands in `WorldGen._latitude`
(snow north, desert south), so the world generator agrees with him and the season clock does not.
↳ Blocked on `SK6` for the sweep rate: a front that crosses the continent needs a speed, and that
needs a step to have a duration.

## CL3 — Is winter deadly to ordinary people, or merely cold?

> "Winter is definitely deadly. If you don't have the necessary equipment or a place to stay you
> will die purely from cold. And it's harder to feed yourself because the crops dying. Definitely it
> is deadly."
> — doug-md, 2026-09-14, note 03

**Answered.** Deadly, by two routes — exposure and hunger — and survivable by equipment and shelter.
↳ Falls out for `CL7` and `EC4`: winter is an annual thing that has to be bought your way through.
↳ Nothing in the game currently kills anyone for the season. This is a system that does not exist.

## CL4 — What does a bad year look like, and how often does one come?

> "A bad year can happen any year and it doesn't have a fixed time. It just depends on what happens
> in that year."
> — doug-md, 2026-09-14, note 03

**Partly answered.** Cadence answered — no cycle, no due date, any year can be the bad one. What a
bad year actually _looks_ like was not answered.
↳ `CL7` supplies some of the missing half from the other end.

## CL5 — Is the climate stable, or has it been changing within living memory?

> "The climate is not really stable. It kind of has that sort of sweeping effect of seasons. But it
> will change based on where the towers have sprouted up."
> — doug-md, 2026-09-14, note 03

**Answered.** Not stable, and the instability is **caused** — climate changes where gates appear.
The world's weather has a history because its gates do.
↳ "where the towers have **sprouted up**" is the fourth restatement of the gate-rewrites-terrain
mechanic, and the first that makes it sound like growth rather than arrival.

## CL6 — Do monsters, gates, or the Tower care what season it is?

> "No, definitely not. They do not care."
> — doug-md, 2026-09-14, note 03

**Answered.** No. Flatly.
↳ Sharpens `CL3`: winter is a hardship for people and not for the things hunting them, which makes
it strictly worse than a symmetric difficulty.

## CL7 — Is there a growing season, a harvest, a hungry month?

> "There is definitely a growing season. There is a harvest and there is a hungry month between that
> autumn to winter stage or full winter when nothing can really grow and you have to rely on what
> you have in your inventory."
>
> "Starvation, attack, raids, murder, anything."
> — doug-md, 2026-09-14, note 03

**Answered.** Growing season, harvest, and a hungry month at the Brown-to-Ice turn. What eats a
village when it goes wrong is starvation first and then people.
↳ Ties the clovers to something mechanical for the first time: `Season` is currently decorative, and
this gives Brown→Ice a meaning.
↳ "rely on what you have in your inventory" is a mechanic answer to a fiction question. Worth
keeping in mind for `EC` and for `GameState.stores`.

## CL8 — Does anyone claim to control weather, and are they lying?

> "I think that there will be prophets and weird people that might say that someone claims that a
> certain person does control the weather and they might sacrifice people based on that."
>
> "People that listen to these gods or claim to be in contact with these gods and some people might
> be completely deluded that they are actually talking to the gods and not just about weather but
> about loads of other things."
> — doug-md, 2026-09-14, note 03

**Answered.** Yes, and they are lying — or worse, sincerely deluded. The claim is second-hand
("someone claims that a certain person does"), it costs lives, and it is not limited to weather.
↳ Marked `[unclear]`.
↳ First `FA` material in the book: there are gods, or at least people certain they are hearing
them, and human sacrifice follows from it. He does not say whether the gods are real.

---

**I.d Life, bodies and the monstrous — [note 04](voice-notes/2026-09-14-doug-md-part-1-d-life-bodies-and-the-monstrous.md).**

## LF1 — Are the people human? Only human?

> "I think that there is a massive range of different races. There is mostly human, but there is
> also orcs, dwarves, sea people, mountain people. There is a wide range of people."
> — doug-md, 2026-09-14, note 04

**Answered.** Mostly human, but not only — orcs, dwarves, sea people, mountain people.
↳ Confirms the repo per the `(repo:)` rule: `data/units.json` already carries `sea_man`, and
`MK7` hands the mines to the dwarves.
↳ Falls out for `LF4`: he then says gate-monsters interbreed with people here, which is a second
and quite different origin for "a wide range of people".

## LF2 — The Bamboo Court's red panda masters, sword bears, cannon bears: people or beasts?

> "I think that every single living creature can communicate in their own way. They might hold
> property, it depends."
>
> "they would have a place that they would live in the animal kingdom. They might build lands and
> create their own safe havens. I think that they would definitely bury their dead as well."
> — doug-md, 2026-09-14, note 04

**Answered.** People. They speak, they build, they bury their dead. "In the animal kingdom" places
them somewhere of their own rather than among humans, but the three tests the question set are all
passed.
↳ Falls out for `MK2`: the cannon bears make their own gunpowder, which requires them to be
craftsmen and not armament.
↳ `OT3`/`OT4`/`RU6` inherit this: if they hold property and build, they have law.

## LF3 — Are gate-monsters alive — do they eat, sleep, breed, age, bleed?

> "I definitely think that they are completely alive."
> — doug-md, 2026-09-14, note 04

**Answered.** Completely alive. No hedging, and it rules out the "made by the gate" readings of
`LF4` before he gets there.

## LF4 — Where do gate-monsters come from?

> "I think that the gate monsters come from a world where they were originally."
>
> "They get spread through and they might interact or breed with people in the world that we are in
> currently."
>
> "There are mixed races, there are loads of different combinations of people."
> — doug-md, 2026-09-14, note 04

**Answered.** Pulled through from a world where they were ordinary — the third option the question
offered — and then they **stay and interbreed**. The monstrous is not a separate kingdom; it is
already in the population.
↳ Both key passages marked `[unclear]`. Worth checking against the audio, because this is one of the
biggest statements in Part I.
↳ Re-opens `LF1`: "mostly human, but also orcs, dwarves, sea people" and "mixed races from
gate-monsters breeding with people" are two origin stories for the same census. Are the orcs and
sea people _descended from gates_, or were they always here? Nobody has said.
↳ Falls out for `GT2` (there is a whole world behind the gate, and it had ordinary inhabitants) and
`GT15` (shutting every gate strands them here).

## LF5 — Can a gate-monster be reasoned with, bought, or kept? Has anyone tried?

> "I think that the gate monsters have an initial goal to fight and kill."
>
> "I think that they can be reasoned with depending on a power that a character has."
>
> "They could be bought by slavers, people might keep them and they will be feral. But anything can
> be trained or kept depending on if as time goes on and you treat them a certain way."
>
> "They have slavers of the monsters will be a massive organisation spread all the way across the
> world."
> — doug-md, 2026-09-14, note 04

**Answered.** All three, and somebody has built an industry on it. Default is violence; reason needs
a specific **power** somebody has; and there is a **world-spanning monster-slaving organisation**.
↳ The "reasoned with" and "bought by slavers" lines are both marked `[unclear]`. The organisation
line is clear.
↳ Falls out, large: a major faction nobody has drawn yet, present on every continent, and a moral
problem the game currently has no position on — given `LF3` (completely alive) and `LF4` (they
interbreed with people), this is slavery of people.
↳ "depending on a power that a character has" implies a rare ability that talks to them. That is
`MN`/`PW` material and a mechanic that does not exist.

## LF6 — Is there a food chain, or is the ecology entirely narrative?

> "There is definitely a food chain. Humans are the apex creatures on top of the food chain
> originally in our world."
>
> "But I think that the food chain will continue to rise and normal people would sit halfway. I
> think that monsters will be definitely above that and different creatures will definitely be at
> the highest of the food chain."
> — doug-md, 2026-09-14, note 04

**Answered.** A real food chain, and **people are in the middle of it**. Humans were the apex; the
gates added rungs above them.
↳ The two lines that place people halfway are both marked `[unclear]`, which is unfortunate given
how much weight this answer carries. Worth checking first of all of them.
↳ This is the single cleanest statement of what the setting is _about_ that Part I produced, and it
is an `FR`-level answer arriving inside an ecology question.
↳ Squares with `LN10` (fear of gate sites is accurate) and `CL6` (monsters do not care about the
season). The world is not built around people.

## LF7 — Domesticated animals? Does the party own any?

> "Yes, you can domesticate any animal depending on what the animal is and how much training you put
> into it. I think the party should be able to have domesticated animals."
> — doug-md, 2026-09-14, note 04

**Answered.** Yes, and the party should be able to keep them.
↳ Marked `[unclear]`.
↳ Falls out: a party animal is a system the game does not have. It also sits oddly next to `LF5`,
where keeping a monster is slavery and keeping an animal is husbandry — the line between them is
`LF2`'s "every single living creature can communicate in their own way".

## LF8 — What do people eat, and what is the staple crop or herd?

> "People eat whatever is nutritious, whatever they can get their hands on."
>
> "Some people might be less fortunate and they might have to become cannibals because that's all
> they can do. They have no food. People eat whatever they want."
> — doug-md, 2026-09-14, note 04

**Partly answered.** Diet is opportunistic and hunger goes as far as cannibalism. **No staple was
named**, which was the half of the question that decides what a farm is, what a market sells and
what a village loses in a bad year.

The follow-up: **what is the crop, and what is the herd?**
↳ The "whatever is nutritious" line is marked `[unclear]`; the cannibalism lines are clear.
↳ Bites on `CL7` (the hungry month) and `CL3` (winter kills by starvation) — both need something to
run short of.

## LF9 — Are there plants, fungi or animals that only exist near a gate?

> "I think that a broken gate would cause local danger."
>
> "Depending on what the tower is, it can completely change the geographical environment around the
> tower."
>
> "Animals might end up staying near a gate. Plants might coexist with the gate and they might get
> stronger or they might die off. It just depends on what the gate is."
> — doug-md, 2026-09-14, note 04

**Partly answered.** Life gathers at gates and is changed by them — strengthened or killed off,
depending on the gate. He did not answer whether anything exists _only_ there, and he did not
answer the farmland question the repo note asked.
↳ Marked `[unclear]` in the substantive passages.
↳ Fifth restatement of gates rewriting their surroundings. Consistent with `SK9`, `LN12`, `CL5`,
`GT6`.

## LF10 — Is disease a thing in this world?

> "Yes, 100%."
> — doug-md, 2026-09-14, note 04

**Answered.** Yes.
↳ Sits against `MK6`, where healers regrow limbs. A world with limb-regrowth and with plague has
decided that magic is good at trauma and bad at illness — worth confirming, because it is a
strong shape and he did not say it outright.

## LF11 — How long does an ordinary person live, and what usually kills them?

> "An ordinary person can live to about 70 years old to 80 years old. What usually kills them is the
> dungeon and the monsters in the dungeon."
> — doug-md, 2026-09-14, note 04

**Answered.** A modern lifespan, and gates as the ordinary cause of death.
↳ Strains against `LN10`, where ordinary people avoid gate sites and only delvers go. If the usual
death is the dungeon, then far more people go in than `LN10` suggests — or "ordinary person"
means something narrower here. Raised, not resolved.
↳ 70–80 years with no mention of childhood mortality, war or winter is a very safe world in every
respect except one. That may be exactly the point.

## LF12 — Are there giants, titans or things too large to fight?

> "I think that there is definitely massive creatures. There are things that are too large to fight.
> You would be better off to either not engage at all with these giants, titans."
> — doug-md, 2026-09-14, note 04

**Answered.** Yes, and the correct response is to leave. Some encounters are not content.
↳ Confirms the repo's Titans faction as literal rather than titular.
↳ The game has no way to express an unwinnable thing you should walk away from. `Pace.avoided`
exists for soaks re-entering a lost site, which is the nearest hook.

## LF13 — The Ooze: one creature, many, or a condition that happens to places?

> "The ooze is this infection that starts to excrete from these creatures or this faction or the
> people in it. Its primary objective is to gain more people into this faction and it kind of alters
> their brain into trying to spread."
> — doug-md, 2026-09-14, note 04

**Answered.** A **condition**, and specifically a contagious one with an agenda — it recruits, and
it edits the host into recruiting. The faction is the symptom, not the organism.
↳ Falls out: Ooze units in `data/units.json` are infected people, which means every Ooze battle is a
battle against victims. `Journal` and `Nemesis` both read differently under that.
↳ Bears on `MN` and `BL`, unasked: a mind that has been altered into wanting this still wants it.

## LF14 — Is anything extinct, and does anyone remember it?

> "Yes, there's definitely things that are extinct in this world purely down to people mass killing
> it or monsters taking over an area or creatures that would be remembered with plaques and ornaments
> and world texts."
> — doug-md, 2026-09-14, note 04

**Answered.** Yes, by two causes — human overkill and monsters taking ground — and they are
remembered deliberately, in plaques, ornaments and texts.
↳ Partly `[unclear]`.
↳ Falls out for `MK3` and `KN`: "world texts" implies a written record with reach, in a world where
`MK3` says every book is copied by hand. Plaques and ornaments may be how that reach is achieved.
↳ Reads well against the repo's `memorials.json` — the world already commemorates in stone.

---

**I.e Matter, craft and making — [note 05](voice-notes/2026-09-14-doug-md-part-1-e-matter-craft-and-making.md).**

## MK1 — What is the technology ceiling — is this iron, steel, or later?

> "I think depending on where you are, there is going to be steel buildings, there is going to be
> people mass producing technology."
>
> "I think this will be kind of set around the fantasy style so it has all the implementations that
> would be in a fantasy world. Some people will have, or some places will have higher technology
> than the other side of the world. It just depends where you are."
> — doug-md, 2026-09-14, note 05

**Partly answered.** There is no single ceiling — technology is **uneven by region**, and somewhere
there are steel buildings and mass production. That is well past "later".

The question was read aloud as "iron, steel or **leather**", so the option he was actually answering
against is not the one the book wrote. That does not change the answer, but it is why it arrives
sideways.
↳ Unresolved against `LN9` (blimps), `LN2` (flight) and `SK3` (the moon is a place people can use).
Four separate answers point above the ceiling and none of them says where the ceiling is. **What
is the most advanced thing anyone can build, and who builds it?**
↳ `MK9` says the truly advanced making is _lost_, which pulls the other way. Both stand.

## MK2 — There are cannon bears. Is there gunpowder?

> "There are cannon bears. There is gunpowder but I think that the cannon bears will produce their
> own sort of gunpowder. That is able to use them to shoot cannons."
> — doug-md, 2026-09-14, note 05

**Answered.** Gunpowder exists, and the cannon bears make **their own kind**. Nobody is forbidden it;
it is simply theirs.
↳ Falls out for `LF2`: they are craftsmen with a monopoly, which is a much stronger claim to
personhood than talking is.
↳ The question's "who is forbidden it" was not answered. If nobody is, that is worth saying plainly.

## MK3 — Is there printing, or is every book copied by hand?

> "I think that there is, an initial book is copied by hand. And books are rare because someone
> would have to make them. And a library will have to copy them by hand to mass produce them."
> — doug-md, 2026-09-14, note 05

**Answered.** No printing. Books are hand-copied and therefore rare, and **a library is a copying
house** — a place that manufactures books, not merely one that shelves them.
↳ This settles what the repo's library sites _are_. `library`, `library_cloister` and `library_vault`
are workshops with scriptoria.
↳ Falls out for `KN3`, `KN5`, `KN6` and `TG7`, exactly as the book predicted. It also gives
`SK4`'s star-charting scholars somewhere to work.
↳ Strains against `MK1`'s mass production: a world with mass-produced technology somewhere and no
printing anywhere is a specific and slightly odd combination. Raised.

## MK4 — Glass, lenses, clocks, mirrors? Can anyone measure time smaller than a day?

> "Yeah, I think that there should be all of those. Glass, lenses, clocks and mirrors."
> — doug-md, 2026-09-14, note 05

**Answered.** All four exist, so yes — time is measurable below a day.
↳ Collides with `SK6`, where time only advances when the party takes a step. A world with clocks and
a world where standing still stops time need reconciling. That is a `SM` seam and probably the
sharpest one in Part I.

## MK5 — What lights a room at night?

> "I think that a simple glow stick, a glow bug, fire, torches, oil burners. Yeah, I think so."
> — doug-md, 2026-09-14, note 05

**Answered.** Fire, torches and oil — plus **glow bugs and glow sticks**, which are living or
alchemical light rather than flame.
↳ Falls out for `SK8`: if cheap portable light exists, the dark being "a safe haven for the
monsters" is a choice people make rather than a condition they suffer.

## MK6 — What is medicine? What can a healer actually fix?

> "So there is definitely herbs. I think that the prayers can work."
>
> "There's definitely surgeons. They will expertise in stitching people together. There will be
> doctors, normal people, but there's also healers that can fix a missing limb and completely comes
> back to normal."
>
> "A healer cannot fix a head being sliced off or a heart being destroyed. The main organs, if
> they're destroyed, will be harder to fix than a common limb."
> — doug-md, 2026-09-14, note 05

**Answered.** All of it — herbs, working prayer, surgery, and healers who regrow limbs completely.
The limit is precise and worth keeping: **limbs come back, organs do not.** Decapitation and a
destroyed heart are final.
↳ This is a permadeath rule stated in fiction. It draws the line the repo's `Character` death
already enforces, and it says _why_.
↳ Falls out for `BD`: a world that regrows limbs has no maimed veterans, so injury is binary — fine,
or dead. Bears on `BD3` and on `MK11`'s hearth vigour.
↳ Against `LF10` (disease, 100%): magic fixes trauma and not illness.

## MK7 — Where does metal come from, who mines it, and is that a good job or a sentence?

> "I think metal comes from the ground, of course. Who mines it can be anyone, but I think that the
> dwarves will mainly be mining the most. You can visit them and negotiate if you want some sort of
> metals."
>
> "It's not really a great job and I do think that there should be slavers that will mine as a
> sentence."
> — doug-md, 2026-09-14, note 05

**Answered.** Dwarves mine most of it and you trade with them for it. It is a poor job, and it is
**both** — a trade for some and a sentence for others, worked by slavers.
↳ Second appearance of organised slavery, after `LF5`. Two independent mentions makes it a feature
of the world rather than a stray word.
↳ Falls out: dwarves are a polity you negotiate with, which is a `RU`/`EC` fact arriving early.

## MK8 — Is any material rare enough to be worth a war?

> "Yes, I think that there should be a material that is maybe a stone or a rare element that will be
> worth millions and millions and millions. People will be very, very happy to get their hands on it
> in any way possible."
> — doug-md, 2026-09-14, note 05

**Answered.** Yes — a stone or rare element, priceless, and people will do anything for it.
↳ It has no name, no properties and no source. Same shape as `LN6`: the slot is canon, the noun is
missing. **What is it, and what does it do?**

## MK9 — Is anything clearly made by a lost hand?

> "Yeah, I think that there should be machinery that was built a long time ago, but a tower basically
> showed up in this place and has destroyed. It's a very hard place to get to and it may has
> destroyed the blueprints to create it once again."
>
> "And a legendary technology man has created their architect and it's no longer able to be found."
> — doug-md, 2026-09-14, note 05

**Answered.** Yes — old machinery, and the knowledge to rebuild it is gone because **a gate opened
on top of it** and took the blueprints with it. There was a named maker, a "legendary technology
man", and he cannot be found.
↳ Falls out, large: this is the first time a gate is said to have _caused_ a loss of knowledge
rather than a loss of ground. It gives `KN1`'s doctrine fade a sibling and it bears on `HS`.
↳ The maker is another unnamed slot. Third one, after `LN6` and `MK8`.
↳ Reads _tower_ as _gate_ per the standing caveat, and here it matters more than usual — "a tower
basically showed up in this place" is either a gate opening or the Spire arriving, and those are
very different histories.

## MK10 — What does a weapon cost relative to a year of a farmer's life?

> "A standard sword is worth maybe three months of a normal family's farmer's life."
>
> "So it might cost an average bit, but not too long for an average farmer's life."
> — doug-md, 2026-09-14, note 05

**Answered.** A standard sword costs about **a quarter of a farming year**. Significant, not
ruinous — a real purchase an ordinary household could make.
↳ Both passages marked `[unclear]`, and this is a number, so it should be checked before anything is
priced off it.
↳ Gives `EC` a peg and lets the repo's gold prices be sanity-checked against a life rather than
against each other.

## MK11 — The bed at home grants permanent HP. What is that, physically?

> "I think that a bed at home will grant HP and it is comfort. It is literally strengthening your
> body to rest and gain more. It is safe and it is protected and maybe it's the people around them
> that keep them strong."
> — doug-md, 2026-09-14, note 05

**Answered.** All three at once, and he will not choose between them: comfort _is_ literally
strengthening, and safety and the people around you are part of the mechanism.
↳ Confirms `Home`/`hearth` as written — a permanent, only-ever-raised bonus earned by having
somewhere safe with people in it.
↳ "maybe it's the people around them" leans it toward `Character.bonds` rather than furniture. The
bed may be standing in for the household. Worth asking before `KI11`.

## MK12 — Are charms manufactured or found?

> "Charms can be found and manufactured."
> — doug-md, 2026-09-14, note 05

**Answered.** Both.
↳ Leaves the sharp end of the repo note open. D24 drops charms on gate delves, carried by delvers
who died there — so **who made the one they were carrying**, and where do you buy one? Still
unanswered, and `BD2`, `EC10` and `DV3` are waiting on it.

---

**I.f Gates, the Tower and the deep — [note 06](voice-notes/2026-09-14-doug-md-part-1-f-gates-the-tower-and-the-deep.md).**

_No `[unclear]` passages in this note. It is the cleanest of the six._

## GT1 — What is a gate?

> "It is a hole to another place."
> — doug-md, 2026-09-14, note 06

**Answered.** A hole to another place. The first option, taken flatly, with none of the wound, door
or mouth readings.
↳ This is the spine question and the answer is deliberately unmysterious. Gates are geography, not
pathology. `BL1` and `FA10` have to build on a world where the central phenomenon is mundane.

## GT2 — What is on the other side?

> "On the other side of the gate can be pretty much a whole different plethora of existence. It can
> be anything. It can be a whole world. It can be anything."
> — doug-md, 2026-09-14, note 06

**Answered.** A whole world, and not the same one each time — every gate goes somewhere else.
↳ Squares with `LF4`: the things that come through were ordinary where they came from, and there
are many wheres.

## GT3 — Who or what opens them?

> "The gates can be opened by anyone. You can walk into them, but you might die."
>
> "It's a natural process like the weather. I think that there should be a timer. Timers for the
> gates to basically, they'll be kept shut, and once that timer ends, then the dungeon will break
> open and start floating with monsters."
> — doug-md, 2026-09-14, note 06

**Answered.** Nobody opens them — they open, like weather, on **a timer that is visible**. Entering
is open to anyone who accepts the risk. When the timer runs out the gate breaks by itself.
↳ Confirms the repo exactly: gates already break at 600 steps, and D15 already models it. The
countdown is now canon rather than a balance knob.
↳ Completes his own `SK2` digression — "a timer for different towers… where the safe area is so that
the characters know how far away the timer is going to end". The timer should be **legible to the
player from safety**.
↳ "start floating with monsters" is almost certainly _flooding_. Kept as transcribed.

## GT4 — When did they start? Is there anyone alive who remembers a world without them?

> "Dungeons have started for a long time, and that there is not a person alive who remembers a world
> without them."
> — doug-md, 2026-09-14, note 06

**Answered.** Long ago, and **no**. Nobody remembers otherwise.
↳ Falls out for `HS2`/`HS4`/`BL6`: a world without gates is history or belief, never testimony.
Anyone claiming to remember one is lying, mad, or the most important person alive.
↳ Sits against `LN11`, where the first gate is the oldest visible thing, and the resistance city is
the second. The resistance is old enough that nobody watched it happen.

## GT5 — What does a gate look and sound like?

> "A gate looks like a massive tower, or, sorry, a gate looks like a wormhole."
>
> "It looks strange. It depends on what the gate is, like if it's a fire gate, a water gate."
>
> "It sounds like an eerie, kind of entrancing sound from a mile away."
>
> "it's quite loud from a hundred paces away, and standing in the mouth, you are completely, only
> kind of sound you can hear is the gate."
> — doug-md, 2026-09-14, note 06

**Answered.** A wormhole, coloured by its element, audible for a mile as something eerie and
**entrancing**, and at the mouth it is the only thing you can hear.
↳ The correction in the first line — "a massive tower, or, sorry, a gate looks like a wormhole" — is
the clearest evidence for the standing tower/gate caveat, and it is him catching it himself.
↳ "entrancing" is doing real work: the sound draws people. That is a reason ordinary people end up
at gates, which `LF11` needs and `LN10` does not currently explain.

## GT6 — When a gate breaks, what actually happens on the ground?

> "When a gate breaks, it spreads. It spreads the element that it is carrying. So, for example, if
> it's an ice gate, then ice will start to spread around it."
>
> "And when a gate breaks, it opens up to let whatever is on the other side out."
> — doug-md, 2026-09-14, note 06

**Answered.** It **spreads** — both its element across the ground and its contents into the world.
A break is terrain change and invasion at once.
↳ Sixth and final statement of the mechanic he returned to in every single note. `SK9`, `LN12`,
`CL5`, `LF9` and this are one answer, and it is the most firmly established thing in Part I.
↳ Adjusts the repo: a broken gate currently raises local danger 25pp. Canon now says it should also
convert terrain to its element and keep converting.
↳ Falls out for `LF9`: the plants that strengthen or die near a gate are responding to this.

## GT7 — When a gate is shut forever, what is left behind?

> "When a gate is shut forever, the gate will still be there, but it will not be active. It can be
> used as a monument, and people might be, they might treasure the existence that this gate now is
> shut."
> — doug-md, 2026-09-14, note 06

**Answered.** The gate remains, inert, and becomes a monument that people **treasure**. Not a scar —
a trophy.
↳ Falls out: shut gates are landmarks and probably places of pilgrimage. `LN6` names an _unsealed_
gate as one of the three things everyone can name; a sealed one is the opposite kind of famous.
↳ The repo removes nothing when a gate closes, which already agrees with this.

## GT8 — Is there a fixed number of gates? Is the world running out, or being emptied into?

> "New rifts will open up, and when a gate is shut, I think that eventually when there are so many
> gates, and so many gates that have been shut, that it will start to replace the gates that have
> been shut."
> — doug-md, 2026-09-14, note 06

**Answered.** No fixed number, and the world is **not** running out. Shutting gates creates pressure
that opens replacements.
↳ Confirms D26 and the `the_deep_breach` thread: closing gates is what causes new ones. The loop is
canon.
↳ Falls out for `GT15` and `DV`: delving is not progress toward an end. It is maintenance.

## GT9 — Is the Tower holding gates back, generating them, or standing at the eye of something?

> "The gate ranks do rise, depending on how close they are to the tower."
>
> "The tower's not holding them back. It's not really generating them. I think the gates are their
> own standalone thing, but maybe the tower can help them generate."
> — doug-md, 2026-09-14, note 06

**Partly answered.** Two of the three options are refused: the Tower neither restrains nor produces
gates, and gates are independent of it. Then "maybe the tower can help them generate" takes half of
that back.

The follow-up: **does the Tower influence gates at all, or is the rank gradient a coincidence of
where it stands?**
↳ He also states the rank gradient backwards relative to D08 — the repo has rank rising _with_
distance from the Tower, and he says rank rises with _closeness_. That inverts the map. It should
be settled before anything is generated from it.
↳ The third option — the eye of something — was never addressed, and `SK10` (something above governs
the gates and watches) suggests it is the live one.

## GT10 — Who built the Tower?

> "The people that built the tower are unknown. It is built, but in a way that we couldn't fathom of
> building anything. It's not other people. It's a different form of existence."
> — doug-md, 2026-09-14, note 06

**Answered.** Built, deliberately, by something that is **not people** — a different form of
existence, by means nobody can reconstruct.
↳ Meets `SK10` head on: "a higher beam that essentially governs these towers and they do look back".
Two notes apart, both describe a non-human intelligence above the gates. **Are they the same
thing?** Nobody has asked, and it may be the most important question in the book.
↳ Falls out for `MK9`: making that cannot be fathomed is the ceiling case of lost-hand making.
↳ Reads well against `LN11`'s "the tower that first came to this world" — _came_, not _was raised_.

## GT11 — Ten floors. Is it a building, or does the inside not agree with the outside?

> "The towers when you go inside are vastly different to what they look like they would be from the
> outside."
> — doug-md, 2026-09-14, note 06

**Answered.** The inside does not agree with the outside. It is not a building in the ordinary
sense.
↳ Note the plural — "the tower**s**". Either there is more than one Spire, or the tower/gate
collision has reappeared in the one note that was otherwise clean. Worth one question.

## GT12 — The Spire Archon at the top: ruler, jailer, gardener, machine, or the last thing put there?

> "I am not sure."
> — doug-md, 2026-09-14, note 06

**Blocked.** Said plainly and left. The only question in Part I he declined.

The follow-up, narrowed to one thing: **when the party reaches the top of the Spire, is the Archon
something that was _put_ there, or something that _arrived_?** That single bit decides whether the
climax is a confrontation or a discovery, and D25 already ships the fight.
↳ `SK10` and `GT10` both describe a governing non-human intelligence. If the Archon is that, `GT12`
is already answered twice over and nobody has connected them.

## GT13 — Does the Tower have doors on other floors? Could a person live in it? Does anyone?

> "The tower? You can go inside of the tower. There is definitely places where you can live in it.
> People can definitely decide to live in this tower. It just depends on the resources that's in
> that floor."
>
> "People could live, yeah. People do."
> — doug-md, 2026-09-14, note 06

**Answered.** Yes, yes, and yes. The Spire is **inhabited**, floor by floor, wherever the resources
allow.
↳ Falls out, large: the climb currently treats every floor as a battle. Canon says there are people
living up there who are not the enemy. That is a content gap and possibly the best one in Part I —
settlements inside the Tower.
↳ Bears on the repo's `tower_hoard` and the ten-floor Apex run.

## GT14 — What is the deep? Is there an underworld, and is it geological or occupied?

> "Yeah, there's definitely subterranean places. There is an underworld. People definitely live in
> it."
> — doug-md, 2026-09-14, note 06

**Answered.** There is an underworld and it is **occupied**.
↳ Confirms D26's subterranean seals as a place rather than a mechanism.
↳ Meets `LN2`'s "underground tunneling" as a way to cross the world. The tunnels belong to somebody.
↳ With `GT13`, the world now has two populated verticals nobody has drawn — under the ground and
inside the Spire.

## GT15 — If every gate were shut, would that be good?

> "If every gate was shut, it would be amazing. The world would live in prosperity, but we would go
> back to humans and people and creatures still fighting against each other."
>
> "It won't change human desire."
> — doug-md, 2026-09-14, note 06

**Answered.** Yes and no, and the last four words are the whole answer: **it won't change human
desire.** The gates are not the reason the world is violent, they are the current form of it.
↳ This is an `FR`-level statement and it reframes `FR1`. Shutting every gate is a victory that
removes a monster problem and leaves a people problem.
↳ Against `GT8`, where shut gates are replaced anyway: the hypothetical is unreachable _and_ it
would not fix the thing anyone actually cares about. That is a coherent and fairly bleak thesis
about the setting, arrived at across two questions.
↳ Falls out for `DV3` and `DV6`, and it gives the Museum's `CONQUERED` ending something to mean.

---

# Joint session 1 — both founders, 2026-09-24

A 70-minute call between `dougie` and `doug-md`, transcribed by Teams and kept whole as
[joint session 1](voice-notes/2026-09-24-joint-session-1.md). Both are founders, so what either said
plainly is canon; where one proposed and the other agreed, the entry quotes both.

The session did not work the book in order. It opened Part 0, judged it hard going, and went to the
sixteen instead — and in describing who they are it answered the frame by building the game's whole
structure. Read these entries together; most of them are one idea seen from different questions.
The design that comes out of it is written up flat in
[17 — The Fall and the Sixteen Worlds](../17-the-sixteen-worlds.md), and the rules it changes are
[D31–D40](../06-decisions.md).

Three things carry across every entry below.

**The transcript is a call, not a recording of answers.** Nobody says an ID. Every mapping to a
question is a reading, and where the reading is a stretch the entry says so. A quote runs straight
through the other founder's crosstalk — a "Mhm" or a "Yeah" dropped into the middle of a sentence
is left out of it. Nothing else is.

**"Tower" means the Tower here.** Part I used _tower_ for gates in five notes out of six. In this
session `doug-md` keeps them apart unprompted — "one massive tower in the middle … scattered all
around the world has like the gates" [00:26:23] — and nobody slips. That is good evidence for the
reading Part I's entries already took.

**There are sixteen Towers, one per world.** "The character in each of the other 15 towers is a max
level version of the NPCs" [00:13:20]. Within any one world there is one Tower. `GT11`'s "the
tower**s**" may have meant exactly this.

---

**Frame — what Earth Kings means.**

## FR4 — What does "Earth Kings" mean? Who is a king, and is the title claimed, inherited, or given?

> "So the 16 characters are all up in this kind of heavenly place or this kind of place where they
> have like godhood and there'll be some sort of disaster up there and everyone, all 16 of them will
> be sent down to Earth."
> — dougie, 2026-09-24, session 1 [00:09:23]

> "So when you go past the top of the tower and you beat it, and you're fighting against the other
> Earth kings. So it's just basically found out that like, you know, these towers were actually a
> proving ground for seeing if you could defend Earth from the other multiverse."
> — dougie, 2026-09-24, session 1 [00:12:55]

> "Everyone knows that one world is going to be left stand at the end."
> — dougie, 2026-09-24, session 1 [01:03:07]

**Answered.** The Earth Kings are **the sixteen** — demigods thrown out of a heavenly place by a
disaster, each landing in their own copy of Earth. Each one who tops their world's Tower becomes a
contender, and the contenders fight until one world is left standing. The title is **won**, at the
end, against the others. The player is one of the sixteen, and so a would-be Earth King from the
first minute — without knowing it.
↳ Settles `RU13` in part: kingship in the world below still exists (royalty is named at [00:23:33]),
but _Earth King_ is a different and higher title, and it is the thing being competed for.
↳ Opens the question the session left for later: **who, or what, decides that only one world
survives?** "There's a force that can actually obviously do that. So you need to figure out how
you're going to stop that" [01:03:27]. See `FA1`.

## FR5 — Is this our Earth — after something, before something — or a different world entirely?

> "and they crashed down there and they've, because there's some sort of... disaster that happens
> and basically when they got crashed down to Earth, that's when the actual multiverse was split"
> — dougie, 2026-09-24, session 1 [00:24:53]

**Partly answered.** The world below is called **Earth**, and it exists as sixteen copies split off
from one at the moment of the fall. Whether it is _our_ Earth — after something, before something —
was not said.
↳ Worth one sentence next session: Part I made the year 365 days and the day 24 hours
"deliberately ours". That reads differently if this is our planet.

## FR7 — A player just lost a character they cared about. What should they feel in the ten seconds after?

> "If your character dies, I think it would be quite cool to see, like... The world. Just like,
> almost like a cinematic nearly of the world that you're in, just slowly just get destroyed. You
> see it like an overtop view."
>
> "Uh, because you're supposed to save it if you don't, if you die."
> — doug-md, 2026-09-24, session 1 [00:29:14]

**Partly answered.** For the **lead**, the ten seconds are a world ending: the camera pulls up and
watches the whole of it go, because the lead was the one who was meant to save it. The feeling is
the size of the loss rather than grief for one person.
↳ Nothing was said about a **companion** dying, which is the more common case and the one the two
drafts on this question argue about. They stand.
↳ This is the answer the Barbarian draft on `FR7` was reaching for from the other side — a death
that matters because of what it takes with it.

## SF1 — Does the player character know they are unusual? Is that a fact about the world or the game?

> "And when they crash on the Earth, they lose their memories. So all 16 lose their memories."
> — dougie, 2026-09-24, session 1 [00:10:14]

> "And then I guess the main character, which is you, you'll have already played the intro. So
> you'll have fallen to us."
> — dougie, 2026-09-24, session 1 [00:15:24]

**Answered.** The lead is unusual as a **fact about the world** — one of sixteen fallen demigods —
and does not know it. The memory is lost in the fall. The **player** knows, because they watched the
fall in the intro, and that gap is the game's first piece of dramatic irony.
↳ `D14` (the run follows the player character) now has a reason inside the fiction: when the lead
dies, their world ends. See `SM5`.
↳ How much the lead remembers is not quite settled — see `CH10`.

---

**The sixteen.**

## CH1 — What is their name, and what do people who dislike them call them?

> "Um, I think it would be cool to have like a... Do you know the Roman names? Like, uh, Cassius,
> um..."
> — doug-md, 2026-09-24, session 1 [00:05:47]

> "Cassius, Caesar, Bellona, Ares, do you want gods or something like that,"
> — dougie, 2026-09-24, session 1 [00:06:07]

> "should be maybe set in stone so you don't get it so the characters get the name who they're
> playing like so and we could get that one to fit maybe the theme of like god-style names."
> — dougie, 2026-09-24, session 1 [00:10:02]

**Partly answered.** The sixteen carry **fixed, god-style names** in a Roman and Greek register, the
same every run. Four were spoken as examples — Cassius, Caesar, Bellona (transcribed "Bologna"),
Ares — and none is assigned to a temper yet. What people who dislike them call them falls under the
earned-name rule in `KI8`.

## CH8 — What do they look like, in one image that is not a list of features?

> "So from the start, they still look like the, how they did in God form, but they don't really
> stand out as much. You know, they kind of look like a regular, a regular person on this earth."
> — dougie, 2026-09-24, session 1 [00:10:26]

> "It could be something, it could be something that like all 16 of the characters have something
> that all of them have. So maybe like a tattoo or like they have. their eyes might glow or they
> might have like something that can recognise the other one."
> — doug-md, 2026-09-24, session 1 [00:14:49]

**Partly answered**, for all sixteen at once. They look **exactly as they did above** and pass for
ordinary people, except for **one mark all sixteen share**, in the same place on each of them —
tattoo or glowing eyes, not yet chosen. Each character's own image is still to write.

## CH10 — Who in the other fifteen do they already know, and how?

> "Do you think that the characters will know who they are or will they get a feeling that like, I
> should know who this person is or"
> — doug-md, 2026-09-24, session 1 [00:14:23]

> "I see, I think it should be clear to the.. . To the player that, yeah, you would know each
> other."
> — dougie, 2026-09-24, session 1 [00:14:39]

> "As you're going, as you're kind of going around, I guess, in a way, maybe your memories are
> intact. Or at least whatever you've actually seen"
> — dougie, 2026-09-24, session 1 [00:15:38]

**Partly answered.** All sixteen knew each other above. Below, **the mark is how they recognise
each other**, and it should be clear to the player who someone is.
↳ Collides with `SF1`: "all 16 lose their memories", then "maybe your memories are intact". The
reading that keeps both is that **the fall takes the memory and the mark is recognised anyway** —
you know _that_ they are one of you, not _who_ they were. That is an inference. **Which is it?**

## CH13 — Which of the six classes suits them, and which would be the interesting wrong choice?

> "they should be as kind of available to get different classes and stuff and we kind of want to set
> them up so they follow a lot of kind of their personality types plus different types. We want big
> variety, like you kind of want 16 different characters that have to have 16 different ways of
> fighting."
> — dougie, 2026-09-24, session 1 [00:16:13]

**Partly answered**, as a rule for the roster. Every character can take other classes, but **the
sixteen must fight sixteen different ways**, and the way each fights follows their temper. Six
classes cannot give sixteen styles; see the follow-up in the agenda.

## CH14 — If they are not the lead this run, where are they standing, and what are they doing there?

> "So we can kind of like randomise like where they'd crash land."
> — dougie, 2026-09-24, session 1 [00:10:26]

> "I think it'd be good, like they kind of have their own lives and they kind of just do whatever
> and they land wherever and they end up. doing whatever they want and eventually you might cross
> paths with them."
> — doug-md, 2026-09-24, session 1 [00:14:09]

**Answered**, for all sixteen at once. They land **somewhere random** — "some people land in
castles, some people land out in the forest" [00:10:50] — and from there live **their own lives**,
driven by their temper. You meet them mid-story, if you meet them at all.
↳ Adopts the Octopath draft ([16.7](../16-lineage/16.7-octopath-traveler-2.md)) almost word for word,
and adds the randomised start it did not have.

## MX16 — Where exactly does each of the fifteen stand when they are not the lead — a fixed area, or somewhere that moves?

> "Cassius. that personality type is removed, all his NPC behaviors, and then every other one of the
> 15 has their same. Behaviors."
> — dougie, 2026-09-24, session 1 [00:11:35]

**Answered.** Somewhere that moves. Each of the fifteen starts at a **random crash site** and then
goes where their temper takes them — the same behaviour they would show in anyone's run.
Choosing a lead switches that one's behaviour off; the other fifteen keep theirs.
↳ Replaces the current rule, where a non-lead hero stands in a fixed area's `people[]` entry.

## MX17 — How does hiring one of the fifteen work — a price, a favour, a condition, a refusal?

> "I don't know if some people will have parties or some people won't have parties, because, you
> know, some people will just not maybe not work too good in a party. Some people might. Some people
> might even team up with original people that came from that heaven."
>
> "So like you can find them in world and you can team up with them. Yeah, but you don't have to
> team up with them."
> — dougie, 2026-09-24, session 1 [00:13:40]

**Partly answered.** You can find the others and team up with them, and you never have to. Some of
them do not work well in a party at all, and some will have gathered one of their own. The price —
gold, favour, condition — was not said.

## MX20 — Can you meet a character whose temper you rolled — is there a version of you walking around?

> "So the 15 guys that you'll see after you choose your character, they're actually just copies of
> the original."
>
> "So you'll actually deal with the original guys in each one of their worlds when you go to
> eventually have that tournament at the top."
> — dougie, 2026-09-24, session 1 [00:25:20]

**Blocked.** Yes in the tournament — every one of the sixteen meets the others' originals there. The
case left open is the **second run**: after the first lead dies you play another of the sixteen in
their world, and the first lead comes with you as a ghost (`BD7`) and a weapon (`MX13`). **Is there
also a living copy of the first lead walking around the second world?** One sentence decides it.

---

**Pools and casting.**

## LP1 — How long is a background — a sentence, a paragraph, a page?

> "Um, you might find out more. You'll have, you'll have like a steady one, like a short enough one.
> And you'll start up more."
> — doug-md, 2026-09-24, session 1 [00:22:39]

> "yeah, so yeah, you can you can add on, so background can keep growing."
> — dougie, 2026-09-24, session 1 [00:22:48]

**Answered.** **Short to start, and it grows.** A background opens as a few steady lines and gets
longer as it is found out.
↳ Falls out for `LP27`.

## LP4 — Should two characters ever share a background, or is each one used once?

> "And 2 characters can share a similar background because, like, it just depends on if those parts
> get revealed, like maybe the uniqueness of them can be revealed after, but for the most part, you
> know, everyone's going to be similar in different ways."
> — dougie, 2026-09-24, session 1 [00:22:48]

**Answered.** Yes. All sixteen share the biggest background there is — the fall — and two can share
more than that. What makes each one unique is revealed later, not stated first.

## LP17 — Should a creed be a named movement other people follow, or one person's private conviction?

> "Yeah, so should there be any guilds or creeds or something like that?"
> — dougie, 2026-09-24, session 1 [00:23:14]

> "Definitely, 100%."
> — doug-md, 2026-09-24, session 1 [00:23:23]

> "there should be characters that are involved in every aspect, like religion, guilds, you know,
> royalty, towns, cities, wildlife. you know, adventurers, you know, hunting, like all the different
> roles of bandits, like there should always be a character somehow involved with that particular
> group. and then some are just nomads as well."
> — dougie, 2026-09-24, session 1 [00:23:33]

**Partly answered.** There are **named movements** — guilds, creeds, religions, royal houses,
adventurers, hunters, bandits — and every one of them has somebody inside it worth meeting. Some
people belong to nothing. Whether a _character's_ creed is one of those movements or their own
conviction was not said; both clearly exist.

## LP24 — Do the uncast pieces really become rumours and NPC histories?

> "So do the oncast pieces really become rumors? Yeah, that's, yeah, we can keep those rumours and
> stuff given for other characters."
> — dougie, 2026-09-24, session 1 [00:23:55]

**Answered.** Yes. Uncast history goes to rumours and to other characters.

## LP27 — Does the player ever see a character's full history, or only what comes up?

> "Does the player ever see a character's full history? So what would we show? I feel like the more
> you find out, the more you get to reveal about the character's history."
> — dougie, 2026-09-24, session 1 [00:23:55]

> "Yeah, and there's different stuff that can be revealed. as you kind of progress and there's
> certain milestones once you unlock them or once you talk to certain people, it'll feed into your
> own background that you can read."
> — dougie, 2026-09-24, session 1 [00:24:28]

**Answered.** Only what comes up — and it accumulates. Milestones and conversations **unlock pieces
of a history**, and they collect into a background the player can read back.
↳ This applies to the lead's _own_ history too. The lead has forgotten it (`SF1`), so the readable
background is the lead finding out who they were.

## LP28 — Do the fifteen you did not become carry their history visibly — does meeting them tell you any of it?

> "since you have all the different personalities for the characters, some characters just will not
> give you information, some characters might give you all of it, some might withhold information,
> and you probably might have to like... Gain up like a synergy in a way"
>
> "The more you talk to them or the more you kind of help them do quests or like interact with them,
> the more likely they'll tell you more stuff and share more information."
> — doug-md, 2026-09-24, session 1 [00:36:57]

**Partly answered.** How much you learn is **the character's choice, by temper**, and it rises with
rapport — talking, helping, travelling together. Some tell you everything; some never do.
↳ Said about the **ghosts** of dead leads (`BD7`), and it reads just as well for the living fifteen.
Taking it for both is an inference.

---

**What happens when the lead dies.**

## SM5 — The run ends when the player character dies but the world is saved. Is the next run the same world later, a different one, or a reset?

> "So how about if your world, so if you die in your world and that world gets destroyed and it
> plays the animation, should you then have a choice of becoming the character in the 15 remaining
> ones?"
> — dougie, 2026-09-24, session 1 [00:29:43]

> "I don't think that when your character dies, you can just keep your progression. I think that's
> the work that you put in with that character. Or you go into the other world with more knowledge
> of how to get stronger and you start off at level 1 again."
> — doug-md, 2026-09-24, session 1 [00:31:44]

> "I completely agree you and I agree as well. Yeah. So that's the idea we're going to go for.
> We're going to follow your idea."
>
> "Like, yes, you start off again, but this time you get to play that character and then the world
> that was destroyed is destroyed. They can never come back. So you essentially got 16 chances to
> beat the game"
> — dougie, 2026-09-24, session 1 [00:32:14] and [00:33:14]

**Answered.** **A different world.** When the lead dies their world is destroyed and never comes
back. The next run is **one of the surviving fifteen worlds**, played as that world's own one of the
sixteen, **from level 1**. The player has sixteen lives across the whole game, one per world.
↳ The one real disagreement of the session, settled inside it: `dougie` proposed keeping the Tower
progress into the next world; `doug-md` argued against — "This game? Isn't easy" — and `dougie`
took his side. Logged as a resolved fork in the [divergence ledger](divergence-ledger.md).
↳ Retires both drafts on this question and on `MX11`. It is not the same world later (the ORV and
CHRONICLE readings); it is a sibling world that forked at the fall.
↳ "this world could potentially play out very similar" [00:32:14] — the sibling worlds share their
starting shape, so where a character crash-landed or where an item lies is knowledge worth
carrying. How similar is a tuning question.
↳ The endgame changes with it: "you only fight among who's left" [00:30:18]. See `CO8`.

## MX11 — Is the next run the same world, later?

> "So you essentially got 16 chances to beat the game or beat the original storyline"
> — dougie, 2026-09-24, session 1 [00:33:14]

**Answered.** No — see `SM5`. The next run is another of the sixteen worlds, the ones still standing.

## MX13 — Does anything at all carry between runs, and if so is that a betrayal of pillar 4?

> "So yeah, and then that's the kind of the idea is, is that right? So once your character died,
> then you've actually absorbed your knowledge into the new character."
> — dougie, 2026-09-24, session 1 [00:32:44]

> "what if every character had a weapon that was built just for them and then... That's what you're
> supposed to like, get from your own world. So before the world gets destroyed, it creates your,
> the main character becomes a ghost and then his custom weapon actually gets sent over into the next
> world of crash land somewhere."
> — dougie, 2026-09-24, session 1 [00:37:32]

> "Yeah, it's a god-tier weapon, but it's not your proficiency, so you can't use it unless maybe you
> train up or something."
> — doug-md, 2026-09-24, session 1 [00:39:16]

**Answered.** Three things carry, and **no power** does:

1. **The player's knowledge** of how the worlds tend to go.
2. **The dead lead, as a ghost** — met at campfires, telling what they learned. See `BD7`.
3. **The dead lead's signature weapon**, which crash-lands somewhere in the next world. God-tier, but
   nobody is proficient with it, and anybody may have picked it up first — "I'm actually going to
   have to get this weapon off them" [00:38:51]. Finding it is what opens the ghost fully.

Levels, gear and Tower floors do not carry.
↳ Pillar 4 survives intact and gets sharper: a whole world is the one-way door now.
↳ Timing rule: "there shouldn't be a weapon. In your next character's world, until they've at least
progressed past the previous world" [00:44:06]. The weapon and the ghost's news arrive only once
the new lead has got as far as the old one did.
↳ Where it lands, the first time: "maybe you make it easy to find where the weapon is, or maybe it's
just random" [00:39:35]. Open.

## BD7 — Do the dead remain as anything — ghosts, revenants, gate-things wearing a face?

> "The only thing I can think on could be almost like a force ghost. Oh like. When let's say you go
> to a campfire, then you can maybe interact. Through meditation with the previous character."
>
> "Kind of like or like all for one or one for all."
> — doug-md, 2026-09-24, session 1 [00:34:31]

> "you go to a campfire and you meditate and you can see the four scopes of all the other
> characters, but you can't interact with them until they've died. And when you, when they've died,
> they make themselves maybe physical in a way, but not, they're still... completely a ghost"
>
> "And you can talk to them, interact, ask questions like how did they fail? Maybe like... What they
> did really good, and maybe some like... We could give you some quests."
> — doug-md, 2026-09-24, session 1 [00:35:27] and [00:36:00]

> "So it should be the, when you're playing the game, you're generating your quest log and your
> journal and everything you've done. So that if that character dies, that journal gets saved. And
> then that can be like some of the bits that he reveals to the next person."
> — dougie, 2026-09-24, session 1 [00:36:26]

**Partly answered.** For **the sixteen**: yes. A dead lead remains as a **ghost** met by meditating at
a campfire. They can be asked how they failed and what they did well, and they hand out quests from
what they found. What they know is **the journal of the run they died in**, and how much of it they
share depends on their temper and on rapport (`LP28`). The living are visible at the fire too, but
cannot be spoken to until they die. For ordinary people, nothing was said.
↳ "four scopes" is almost certainly a mis-hearing — _forms_, or _horoscopes_. Kept as transcribed.
↳ The question it answers first was `dougie`'s — does the ghost go to one successor, to every other
world, or "splits off into 15 parts" [00:34:18]? `doug-md` did not know, and the campfire idea
answered it sideways: every later lead can meet every earlier ghost. That is an inference.
↳ Bears on `BD6`: a destroyed world "can never come back", but its lead can still talk.

---

**The Tower and the gates.**

## GT1 — What is a gate?

> "and then a gate. can have like a different set of objectives and it's not trying to test the player, it's
> trying to test the world, if you know what I mean."
>
> "Like, it's something that's happening to the world, so you have to think of some way to stop the
> gates, but then the tower is like an actual, like, like it's an honourable kind of way of
> climbing"
> — dougie, 2026-09-24, session 1 [00:53:35] and [00:54:11]

**Answered.** Still a hole to another place (Part I) — and now its purpose, set against the Tower's:
**the Tower tests the player; a gate tests the world.** A gate is something happening _to_ the world
that the world has to find a way to stop.
↳ Sharpens `GT3`: a gate is set against the world as a whole, not against whoever walks in.

## GT2 — What is on the other side?

> "How, when they go into the tower level, it's like... Its size of the map can be any size, but it
> can be a completely different world, basically, like a like a ice ice biome, and it's all ice
> elves, and..."
>
> "You might go into one and it's like... It's a desert and you have to fight like scorpion monsters
> and maybe like, gotcha, what's that name? Pick me up, infinite gotcha. Oh, it's like you go into a
> gate and it's like... pretty much like a period of time and you have to complete an objective."
> — doug-md, 2026-09-24, session 1 [00:52:21] and [00:52:43]

> "I think if you go into a gate, you can't leave until you beat it."
> — doug-md, 2026-09-24, session 1 [00:53:11]

**Answered**, and confirmed a second time. A whole world of **any size**, each with its own biome and
peoples — ice elves in one, scorpion things in a desert in another. Inside, there is **an objective**,
sometimes against a time limit, and **no way out until it is done**.
↳ "you can't leave until you beat it" is new, and it overturns shipped behaviour: a delve can
currently be retreated from and keeps the floors already taken (M5).
↳ The timed objective comes from _Pick Me Up_, already named in [07 — Lineage](../07-lineage.md).

## GT10 — Who built the Tower? Is it built at all? Is it older than people?

> "And then you'll get to find out who was the, what was the reason that that happened, who created
> it, and what's the next kind of, what's the stages for deciding who's going to become the Earth
> King"
> — dougie, 2026-09-24, session 1 [00:25:36]

**Answered**, as in Part I — built by something that is not people — and now with a purpose: the
Tower is **a proving ground**, testing whether the one who climbs it could defend Earth against the
other worlds. Who built it is **found out at the end**, on purpose.
↳ `FR8` now has a strong candidate for the thing that stays unexplained until very late.

## GT11 — Ten floors. Is it ten from outside too — a building, or does the inside not agree with the outside?

> "I think if you wanted to do like one massive tower in the middle that has, let's say, 100 floors,
> but then scattered all around the world has like the gates"
> — doug-md, 2026-09-24, session 1 [00:26:23]

> "So, I guess what I'm afraid the game will turn into is that... Like going up the 100 floors is
> just not. Fun, like maybe 100 floors is too much. Maybe it's not enough. Maybe, you know, maybe
> there should be a smaller amount of floors in the tower."
> — dougie, 2026-09-24, session 1 [00:42:45]

**Answered**, as in Part I: the inside does not agree with the outside. And **one Tower per world,
in the middle of it**.
↳ **Re-opened: how many floors.** The build ships ten (`D16`). `doug-md` floated a hundred; `dougie`
worried a hundred would not be fun and wants "an achievable goal". Every rule the session made
counts in fives, which rules out ten being the whole climb only if a chapter is five floors. Top of
the [agenda](#what-is-still-to-decide).
↳ Sits against `GT13` (people live on the floors) without contradicting it: floors can be inhabited
and still send the climber back out.

## GT12 — The Spire Archon at the top: ruler, jailer, gardener, machine, or the last thing put there?

> "So when you go past the top of the tower and you beat it, and you're fighting against the other
> Earth kings."
> — dougie, 2026-09-24, session 1 [00:12:55]

**Blocked**, still — but the top of the Tower has moved. It is **not the end**: beating the last floor
pulls the climber into the contest between worlds (`CO8`). The Archon still ships as floor 10's
fight (`D25`). The follow-up is now: **is the Archon the Tower's last test before the contest — the
examiner — or is it one of the others waiting at the top?**

## BL8 — What do people think the Tower is? Do they think about it at all, or is it weather?

> "'cause other... NPCs in the game are also trying to climb the tower. And they're doing it their
> own way"
>
> "Gates and stuff and royalty folks on gates, but then strong individuals always want to climb. the
> tower"
> — dougie, 2026-09-24, session 1 [00:54:11] and [00:54:42]

**Partly answered.** To the strong it is **an honourable climb** — the thing a strong person proves
themselves on — and other people are climbing it their own way. What an ordinary villager thinks of
it was not said.

## FA6 — Are there vows, fasts, pilgrimages? Is the Tower a pilgrimage?

> "but then the tower is like an actual, like, like it's an honourable kind of way of climbing"
> — dougie, 2026-09-24, session 1 [00:54:11]

**Partly answered.** The Tower is a **climb of honour**, not a religious one — nothing said makes it
a pilgrimage in the faith sense. Vows and fasts were not discussed.

## DV2 — Is there any organisation of delvers — a guild, a register, a board with prices, or just people who left?

> "I guess it's like Adventurers Guild. They're more focused on, they're more focused on the..."
> — dougie, 2026-09-24, session 1 [00:54:27]

> "And in that sort of way, and I guess the Adventures Guild as well is trying to help manage that
> too."
> — dougie, 2026-09-24, session 1 [00:55:47]

**Answered.** Yes — **the Adventurers Guild**, which is concerned with gates rather than the Tower,
and helps manage the big ones.
↳ Overrules the Solo Leveling draft's warning on `GT2` that "Earth Kings has no such institution and
shouldn't invent one". It has one now.

## OT8 — Do the factions ally against gates, or does the gate crisis fail to unite anyone?

> "but for example, an S-class case, that's like a national level threat. And that means that like,
> you know, you'd expect that there's a lot of people. Preparing to enter it together."
>
> "Maybe a few kingdoms, an army, something like that. All the strongest guys, they wait until they
> have enough strong guys to get in."
> — dougie, 2026-09-24, session 1 [00:55:14] and [00:55:41]

**Answered.** For the worst gates, yes. An **S-rank gate is a national threat**, and several
kingdoms, an army and every strong fighter available gather and wait until there are enough of them
to go in together. Gates can be entered by any number of people at once; the Tower only by one party
— "a tower is just restricted to your party" [00:54:58].
↳ Retires both drafts on this question.

## RU10 — Who protects a village, actually? If a village has forty people and a gate opens nearby, who comes?

> "Gates and stuff and royalty folks on gates"
> — dougie, 2026-09-24, session 1 [00:54:42]

**Partly answered.** Royalty and the Adventurers Guild are the ones who deal with gates; the big
ones bring armies. Whether anyone comes for _forty people_ was not said.

## CO8 — The Tower ends in a victory at the Spire Apex. Is that the end of the game, or just of the Tower?

> "So when you go past the top of the tower and you beat it, and you're fighting against the other
> Earth kings."
> — dougie, 2026-09-24, session 1 [00:12:55]

> "So, and then it's like time stops until everyone completes the tower. So that's why they all
> completed technically the same time, so no one's waiting."
> — dougie, 2026-09-24, session 1 [00:25:56]

> "Yeah, the characters are demigods and actually there is actually gods as well. But that's after
> you've climbed up the tower and you've gotten to the part where you get pulled into the universe
> level"
> — dougie, 2026-09-24, session 1 [01:03:07]

**Answered.** **Just the Tower.** Topping it pulls the lead up to the level of the universes, where
time has stopped for everyone who finished first. There the lead faces the **other surviving leads,
each at the most powerful they could have become** — "even if that NPC died in your world" [00:13:20]
— and past them the gods and the force that means to leave one world standing.
↳ How the contest is fought — a duel, a bracket, a free-for-all, alliances — is open: "or maybe the
group up together. They fight a different opponent, who knows" [00:25:36].

---

**Faith.**

## FA1 — Are there gods? Do they act? Does anyone claim to have seen one?

> "So I think that the 16 characters that crashed down to Earth could be considered either gods or
> demigods."
> — dougie, 2026-09-24, session 1 [01:02:19]

> "So are the real God or the real like anti-God? Like the super bad guy. I think we should make them
> maybe demigods as best, do you think?"
> — dougie, 2026-09-24, session 1 [01:02:46]

> "The. Yeah, demigod sounds good."
> — doug-md, 2026-09-24, session 1 [01:03:03]

**Answered.** **Yes.** The sixteen are **demigods**. Real gods exist too, above them, and they are met
only after the Tower. They act: something up there has arranged that one world will be left
standing, and stopping it is the last thing the game asks.
↳ "Does anyone claim to have seen one?" was not said. Every person who fell from above has seen them,
and forgotten.
↳ Meets `SK10` (a higher being that governs the towers and looks back) and `GT10` (the builder is
not people). Three answers, one entity or several — still the question nobody has asked.

---

**Names.**

## KI8 — Naming: family names, place names, earned names, titles?

> "Um... And kind of depending on where they're from, they'll kind of have like different names where
> they come from, if that makes sense."
> — doug-md, 2026-09-24, session 1 [00:06:29]

> "I feel like it's more nobility, they'll have more eccentric and more... like stronger names and
> like the average maybe town you might just have like a stem from that. Name from them. So, like, if
> they're for if they are beside this like Roman Empire as such. And they're far out from that town,
> from that city. They'll have a stem of them sort of names, but not as strong."
> — doug-md, 2026-09-24, session 1 [00:06:47]

> "I think you should be able to do both. Like, you have nearly like a nickname. But do you have your
> real name? when you're introducing yourself. Both."
>
> "Like if you're like a party of you hunt goblins, like you might have the title Goblin Hunter
> Caesar."
> — doug-md, 2026-09-24, session 1 [00:08:02] and [00:08:27]

**Answered.** Names are **regional**, in Roman and Greek registers. The nobility near an imperial
centre carry the strong, eccentric forms, and ordinary people farther out carry **shortened stems**
of them. Everyone has **a real name and an earned one** — a nickname or a title won by what they do,
like _Goblin Hunter Caesar_ — and fame travels by the earned one.
↳ `TG6` (place names) is still open, but the same rule reads naturally onto it.
↳ Falls out for `NW9`.

## NW9 — Is there a word in this world for "famous"? Is fame good?

> "Okay, cool. Oh yeah, and sometimes it might be important their name, but people are like, oh,
> that's the Golden Killer, that's the Golden Hunter. Yep. So you can get Renown through the name as
> well."
> — dougie, 2026-09-24, session 1 [00:08:37]

**Partly answered.** Fame is **a title people call you by**, and renown is carried by the title, not
the name. Whether fame is good was not said.
↳ Gives `Renown` a visible output: past some standing, a place calls you by a title it made up.

---

**Boundaries.**

## BN2 — Name one thing you want in it so badly you would trade three other features for it.

> "And I think that the fights is something that we really need to get done right."
> — dougie, 2026-09-24, session 1 [00:41:58]

**Inferred.** Nobody answered `BN2` as asked. But the one thing both founders spent the most time on,
and the one thing `dougie` said has to be right, is **the fight**. Confirm, or name something else.

## BN3 — What tone would make you stop working on this — grimdark, cute, ironic, preachy?

> "Um... Like the tone I would give this game is a dark fantasy, if that makes sense."
> — doug-md, 2026-09-24, session 1 [00:41:27]

> "Yeah, well you don't want it to be in like a *******. *******. boring game either, you know, it's
> just like, it's all laughs and stuff."
> — dougie, 2026-09-24, session 1 [00:41:48]

**Answered.** **Dark fantasy**, and "as more time goes on... The issue gets darker in a way" [00:41:15]. What
would stop them is the opposite: a game that is boring, or all laughs.

## BN6 — What are you afraid this game will turn into?

> "Um... I don't want this game to be repetitive."
> — doug-md, 2026-09-24, session 1 [00:41:01]

> "You don't want it to be like that the fights just turn into the exact same set of moves every time
> and that you're just kind of grinding through. So you want a little bit of dialogue, but you don't
> want to be held up by dialogue either."
> — dougie, 2026-09-24, session 1 [00:41:58]

**Answered.** **Repetitive.** Fights that are the same moves every time, a grind, a climb of a hundred
floors that is not fun, and a game held up by dialogue.
↳ The same fear produced two of the session's decisions: a limited set of active abilities
(`KN11`, and see [D36](../06-decisions.md)) and the new first-kill experience rule (D37).

---

**Getting stronger.**

## KN11 — Is expertise possible outside doctrine — can someone simply be very good at something, with no book?

> "Pretty much the way that you level up in this game is by repetition. So if you have a level 1
> character, they'll have level 1 every, look at the Kenti ability tree or level in."
>
> "So, that's like a good way of maybe getting better with... A nicer way of getting better with a
> weapon that you get a proficiency with it in comparison to just having the level 50 Katana and you
> can just... Use that weapon."
> — doug-md, 2026-09-24, session 1 [00:48:48] and [00:49:43]

> "Yeah, so professions that you can get through practice, but experience points, it needs to be a
> unique character."
> — dougie, 2026-09-24, session 1 [00:51:18]

**Answered.** **Yes — by repetition.** Skill with a weapon or a kind of fighting rises by using it,
Kenshi-style, and a good weapon in unpractised hands is not a good weapon. Experience is a separate
thing, earned only from opponents you have not beaten before.
↳ Confirms and extends the repo: proficiency already rises with steps carrying a weapon. It should
now rise with _use_. See [D37](../06-decisions.md).
↳ "professions" is almost certainly _proficiencies_, as heard.

## SM8 — Companions are hired for gold and dismissed at will. How do we make a hire matter?

> "I would like a system in the game where... If you have a party, you could send some of your party
> members to do things for you, if it's... Collect herbs so that you can make medicine, or if it's
> meat with a certain individual, or carry out a task, or simply like join a gate raid, but you be
> off doing your own thing, and then they'll tell you how. went or they got on and they might die as
> well."
> — doug-md, 2026-09-24, session 1 [00:56:04]

**Partly answered.** One way, adopted by both: companions can be **sent away on jobs** — gathering,
meeting someone, a task, a gate raid — travelling the map while you do, reporting back how it went,
and **sometimes not coming back**. A hire matters because you trusted them with something and were
not there. The two drafts on this question (naming, and the world naming them after the fact) are
still open alongside it.
↳ `dougie`: "they travel across the world in real time, do they?" — `doug-md`: "Yeah, like when
you're traveling, they're travelling too" [00:57:37].
↳ Party size: "initially your party is definitely like capped at, let's say, 4 … I think like 6 in
your parties is like a good number" [00:57:10]. The build caps it at 4 (`D20`).

---

**Carried over.**

## CO4 — No named bosses outside the Tower. Should there be, and are they people or things?

> "Uh, explorable places that you find mobs and defeat bosses, and..."
> — doug-md, 2026-09-24, session 1 [00:26:43]

**Partly answered.** Yes — gates are explorable places with **bosses** at the end. People or things
was not said.

## CO5 — What is a "mission" here, as distinct from an errand and a thread?

> "each of the 16 characters should have like a set of quests or missions in the stories that kind
> of lead them to eventually climb in the tower."
> — dougie, 2026-09-24, session 1 [00:12:12]

> "So maybe, you know, the way like you're getting objectives that are popping up in the game, like
> quests and stuff like that there, and you're hearing rumors, like it's all getting out of your like
> potential quest or job log."
> — dougie, 2026-09-24, session 1 [00:57:52]

**Partly answered.** A **mission** is part of a character's own line — the chain of quests, one line
per member of the sixteen, that leads that character to the Tower. Beside it sits a **job log** of
quests and rumours picked up in play, which is what party members get sent on. Where a thread ends
and a mission begins is still to draw.
↳ `doug-md` asked for the goal to be stated: "it might come up like on a little screen and be like,
climb the tower" [00:12:06]. The answer was a line of quests that arrives at the Tower rather than a
banner — "But you don't know what you're fighting for" [00:12:45].

---

Below are **143 proposals from the sixteen lineage sources**, covering **129 of the 366
questions**. None of them is an answer. Each is a drafted option with its reasoning and its
cost already worked out, so a question can be settled with a yes, a no, or a better idea rather
than from nothing. **Thirteen carry more than one proposal** — sources arguing — and those are
in the [divergence ledger](divergence-ledger.md) rather than waiting for a yes.

---

## AR1 — Why is a village where it is — water, road, defensibility, a shut gate nobody talks about?

> there is **one** genuinely safe place, and it is **administered, crowded and boring.** Not a warm hearth — a walled city with queues, districts, rules and an hour's walk between anywhere. Safety is what you go to when you can no longer afford the frontier.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a _deflation_ rather than a reward — which is the honest emotional shape of a roguelite loop.
_Costs_ — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
↳ Falls out: `EC6` (where a delver's money goes) — the city takes it. `DV6` (what happens to a delver who quits) — they stay, and they're one of thousands.

## AR2 — Is a village walled? What does it do at night?

_Two sources propose different answers here. Both stand until somebody chooses._

> at least one settlement is protected by **wards instead of walls**, because the thing it fears comes from above. One detail, and it tells you the whole region.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**

> the map is the **frontier**, and there is one safe place that is boring, crowded and administered. `LN4` answers "frontier of a larger one," and that larger one has running water.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
_Costs_ — this adds a place the game does not currently model. Cheap as fiction, expensive if anyone wants to go there.

## AR3 — Who builds keeps, who lives in them, and are they garrisons or households?

> the gate is a **building**, not a hole. Someone built the approach, and it predates everyone.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**

## AR5 — What is the material and silhouette of ordinary building — timber, stone, turf, stilt?

> lean on the site kinds the repo already has — stilt huts, cairn huts, orchard huts, pine longhouses, dune serais. Each one already implies a climate, a material, a trade and a smell. Answer `AR5` by **reading what's in `data/` and confirming it**, per the book's `(repo:)` rule.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**

## AR7 — How does a settlement change after a gate near it is shut? After one near it breaks?

> **there was more land.** The ruins aren't abandoned settlements, they're the high ground of somewhere that mostly isn't there any more.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.**

## AR8 — What is a ruin in this world — old war, old gate, old people, or something that was never fin…

> ruins are **legible**. A ruin says what it was, who held it, and roughly when it stopped, to anyone who can read a carving — and most people can't.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
↳ Falls out: `KN5` (literacy in a village) matters mechanically for the first time: the ruin has been telling everyone for two hundred years.

## BD1 — What is a corpse in this world? Does it stay where it fell?

> **the unnamed are not remembered because there is nothing left to remember.** A nameless recruit's death is a fact; a named one's death leaves a bond that other people can feel go.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
_Costs_ — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
↳ Falls out: `memorials.json` gets a rule instead of a threshold — memorials are for the named, and that's why there are so few.

## BD3 — The Ground grace works within 6 tiles of a hearth. Why? Is a hearth warded, watched, loved, o…

> **the unnamed are not remembered because there is nothing left to remember.** A nameless recruit's death is a fact; a named one's death leaves a bond that other people can feel go.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
_Costs_ — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
↳ Falls out: `memorials.json` gets a rule instead of a threshold — memorials are for the named, and that's why there are so few.

## BD8 — What do people do with bodies: burial, burning, exposure, the sea?

> the body goes wherever it fell; the **name** is what gets carried home and set down. `memorials.json` is for names, not remains.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**
↳ Falls out: `NW7` (who remembers the dead, for how long) — as long as the memorial stands, which is longer than anyone who knew them.

## CH9 — Who in the other fifteen would they not travel with, and why?

> make the refusal **asymmetric**. A won't travel with B; B has no idea and likes A. That single asymmetry generates more character than a mutual grudge.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.**
↳ Pairs with: an oath can name someone who never knew.

## CH14 — If they are not the lead this run, where are they standing, and what are they doing there?

> **somewhere that is their own business**, doing it whether or not you arrive. You meet them mid-story, not waiting.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**
_Costs_ — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a _fragment_ of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## CL5 — Is the climate stable, or has it been changing within living memory?

> **density of the grammar varies by place.** Where it's thick, gate-things are stronger, doctrine is easier and stranger, and people live differently. Where it's thin, life is ordinary and delving is a story.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
_Costs_ — it has to be _visible on the node map_ or it's a note nobody reads. That's map work, not fiction work.
↳ Falls out: more than any other candidate in either list — `LF6` (why beasts cluster), `EC5` (why trade goes the long way), `DV5` (why delvers concentrate), `AR2` (why some villages are walled), `KI3` (why people move). One variable, six answers.

## CO1 — What does the voice say? W2 — the memo cut off before giving the line at the end of the cinem…

> the voice is reading, not narrating. One line, present tense, about someone the player hasn't met yet and will.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**

## DV1 — Is delving a job? Is there a word for it, and do parents want it for their children?

_Two sources propose different answers here. Both stand until somebody chooses._

> yes, with a word, a price board, a rank ladder and parents who don't want it for their children.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
_Costs_ — kills the romantic reading of the twelve heroes. `DV9` then answers "twelve among many."
↳ Falls out: `DV4` (what villagers think of four armed strangers) — **business**, neither relief nor dread. `DV2` — there's a register, because ranks are only worth anything if someone keeps them.

> **no.** There is a ceremony, or a debt, or a village with nothing in it. People delve because the alternatives ran out, and the ones who love it are strange.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
_Against_ — your `DV1` candidate was "it's a job with a price board." The co-founder's is "it's what happens when you have no other option." These are close but not identical, and the gap shows up in `DV4` (what villagers think) — a tradesman gets business, a conscript gets pity. **Small ledger item, worth ten minutes.**

## DV5 — How many delvers are there in the whole world — dozens, thousands?

> **anyone, and that's the problem.** No licence, no association, no dispatch. People who shouldn't go, go, and the parties that take them in as bag-carriers are doing something the world hasn't decided is a crime.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It answers `LW6` (what the law doesn't cover) with the thing the player is doing, which is far better than an abstract gap.

## DV7 — Is there a code among delvers, and what is the unforgivable breach of it?

> yes, and the unforgivable breach is **claiming a form you can't perform** — wearing a name you didn't earn. It's the sect's own grievance, generalised.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.**

## DV8 — Is a captive delver worth more alive than dead to everyone, or only to raiders?

> **no.** There is a ceremony, or a debt, or a village with nothing in it. People delve because the alternatives ran out, and the ones who love it are strange.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
_Against_ — your `DV1` candidate was "it's a job with a price board." The co-founder's is "it's what happens when you have no other option." These are close but not identical, and the gap shows up in `DV4` (what villagers think) — a tradesman gets business, a conscript gets pity. **Small ledger item, worth ten minutes.**

## DV10 — Does the world have a word for what happens when a party comes back one short?

> both have plain words, and neither is polite. The world has vocabulary for these because they happen weekly.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**

## DY1 — Describe an ordinary day for a villager, dawn to dark, in three clauses.

> every villager knows **one thing worth hearing and has one thing worth taking.** That is their whole characterisation, and it is enough.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.** It turns `DY1`–`DY12` from a worldbuilding essay into a content format the build can actually consume, and it gives `MN8` (what should an NPC want by default) a default that doesn't need an LLM: to keep the one thing.

## DY8 — What does a village smell like, and what does a keep smell like?

> lean on the site kinds the repo already has — stilt huts, cairn huts, orchard huts, pine longhouses, dune serais. Each one already implies a climate, a material, a trade and a smell. Answer `AR5` by **reading what's in `data/` and confirming it**, per the book's `(repo:)` rule.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**

## EC1 — What is gold, and who mints it? Is it coin, weight, or trust? Is there a face on it?

> **the gate is the only source of a material the world now depends on.** Not treasure — an input. That's why a dangerous job has a queue, and why towns tolerate armed strangers (`DV4`).
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.**
↳ Falls out: `EC9` (does gate-gold wreck prices) — yes, locally and visibly, and the towns nearest the open gates are rich and unpleasant.

## EC2 — Is currency universal across all factions, or does the Heart Empire mint its own?

> **the gate is the only source of a material the world now depends on.** Not treasure — an input. That's why a dangerous job has a queue, and why towns tolerate armed strangers (`DV4`).
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.**
↳ Falls out: `EC9` (does gate-gold wreck prices) — yes, locally and visibly, and the towns nearest the open gates are rich and unpleasant.

## EC3 — What does an ordinary person earn in a year, expressed in the game's gold? This sets whether…

> delvers are **liquid, not rich**. Equipment and potions consume the take; a 120-gold ransom is several months of a farmer's life and about two good delves.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** The source is unusually concrete about kit costing money and people selling their weapons when they can't face the labyrinth again. That single image answers `DV6` (what happens to a delver who quits) better than a paragraph would.

## EC5 — Is there trade over distance? What moves — salt, iron, books, people?

> one road is **safe because of something that happened**, and everything expensive travels on it. The others are cheaper and kill people.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It turns the FFTA-style node map from a menu into a political object, and it gives `HS6` (the last thing that changed the world) a physical consequence you can stand on.

## EC7 — Is there tax, tribute, tithe? Who collects, and what happens if you don't pay?

> **the gate is the only source of a material the world now depends on.** Not treasure — an input. That's why a dangerous job has a queue, and why towns tolerate armed strangers (`DV4`).
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.**
↳ Falls out: `EC9` (does gate-gold wreck prices) — yes, locally and visibly, and the towns nearest the open gates are rich and unpleasant.

## EC8 — Who sells a party its weapons, and where did the smith get the steel?

> the smith is the **end of a supply chain the party is standing in**. They didn't get the steel; someone did, at a cost, from a place that is on the map and dangerous.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.** Answers `MK8` (a material worth a war) as a live condition rather than a lore note, and gives `EC5` (trade over distance) something specific to move.

## EC9 — Delvers come home with gate-gold. Does that wreck local prices? Is a delver rich, or just liq…

> delvers are **liquid, not rich**. Equipment and potions consume the take; a 120-gold ransom is several months of a farmer's life and about two good delves.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** The source is unusually concrete about kit costing money and people selling their weapons when they can't face the labyrinth again. That single image answers `DV6` (what happens to a delver who quits) better than a paragraph would.

## FA1 — Are there gods? Do they act? Does anyone claim to have seen one?

> **one large faith with a headquarters, a highway and an army**, plus local practice everywhere that doesn't match it. The faith is the second-largest political actor on the map and does not think of itself as political.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
↳ Falls out: `FA5` (do the faithful and the delvers disagree) — constantly, and it's about the gates. `KN4` (who can read) — the church can, which is why the church has the history.

## FA3 — If there are temples, what happens inside them? Is it a service, a market, a school, a hospital?

> **one large faith with a headquarters, a highway and an army**, plus local practice everywhere that doesn't match it. The faith is the second-largest political actor on the map and does not think of itself as political.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
↳ Falls out: `FA5` (do the faithful and the delvers disagree) — constantly, and it's about the gates. `KN4` (who can read) — the church can, which is why the church has the history.

## FA8 — The Training Yoke is self-imposed handicap for growth. Is that an ascetic tradition with a na…

> it has **a name, a lineage and a dead master**, and the people still doing it are doing it slightly wrong.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.** Cheapest possible way to give the world a history that predates the player, and it makes a mechanic into an institution.

## FR1 — In one sentence: what is this world about? Not the plot — the thing the fiction exists to say.

> the FFT answer is _the record is written by the winner and the record is wrong_. That is compatible with the repo's `annals.gd` and with `SF3` — but only one of them can be the frame. Worth marking against ORV's reader.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**

## FR7 — A player just lost a character they cared about. What should they feel in the ten seconds aft…

_Two sources propose different answers here. Both stand until somebody chooses._

> **nothing happens.** No cutscene, no acknowledgement, no pause. The world's indifference is the feeling.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
_Against_ — FFT's version says the rule clicks and grief arrives late at a memorial. This version says grief never arrives from the world at all and the player supplies it. One is generous, one is colder. Ledger.

> **the flat click of a rule first.** Grief arrives late, somewhere else — a name in a list, a memorial you walked past for another reason.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.** It's the honest description of what permadeath actually does, and it tells `SM8` what its job is: mechanics carry the name, fiction delivers it late.

## FR8 — Should the world end up explicable? Name one thing that must still be unexplained when the Co…

> **a stretch of history everyone can point at and nobody can read.** Not a mystery the game withholds — a gap the _world_ maintains, with someone benefitting.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** This is the strongest `FR8` candidate on either list, because it satisfies "never explained" without requiring the _designers_ to know the answer either.
↳ Falls out: `HS4` (is there a written history, and who keeps it) — yes, and it has a hole in it. `NW5` — the record is central, official and incomplete on purpose. `FA4` — the church's authority partly rests on the hole.

## FR10 — Who tells this world's story to itself — chroniclers, priests, drunks, nobody?

> **nobody, deliberately.** Things get written down — annals, memorials, engravings — but no one is assembling them. `annals.gd` is a pile, not a chronicle.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
_Costs_ — directly contradicts ORV's `SF3` reader candidate. These two cannot both be true; this is a divergence-ledger item, and probably the most interesting disagreement available to you and your brother.

## GT2 — What is on the other side — a whole world, a pocket, a stomach, nothing that would survive be…

> **yes, by looking.** Size, colour, sound. No sensor, no number — the world tells you honestly and people go in anyway because of what's on the other side.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It gives the node map information the player can act on without a UI element, and it makes `DV3` (how a party chooses a gate) a real decision rather than a menu.
_Against_ — the source uses a measuring device and an association that dispatches teams. Earth Kings has no such institution and shouldn't invent one — replacing the meter with the eye is the port.

## GT4 — When did they start? Is there a person alive who remembers a world without them?

> **yes, by looking.** Size, colour, sound. No sensor, no number — the world tells you honestly and people go in anyway because of what's on the other side.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It gives the node map information the player can act on without a UI element, and it makes `DV3` (how a party chooses a gate) a real decision rather than a menu.
_Against_ — the source uses a measuring device and an association that dispatches teams. Earth Kings has no such institution and shouldn't invent one — replacing the meter with the eye is the port.

## GT6 — When a gate breaks (D15), what actually happens on the ground — does it burst, spread, sink…

> yes, and it is unreachable for an ordinary geographic reason rather than a magical one. A dead band. No one goes, and the reason is boring and absolute.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** Boring impossibilities are more convincing than warded ones, and it answers `BN2` (edges of the map) without a wall.

## GT7 — When a gate is shut forever, what is left behind? A scar, a monument, a good field, nothing?

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
_Costs_ — it commits the game to a _losing_ world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

## GT9 — Gate rank rises with distance from the Tower (D08). Is the Tower holding them back, generatin…

> each floor is **its own place** — its own weather, its own ecology, its own size — and the only thing they share is that something at the top of each one is in charge. Floor scale varies wildly; one is a corridor, one is a country.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It makes the Tower worth ten distinct art passes instead of ten palette swaps, which is a `D`-level decision the repo hasn't spent yet.
_Costs_ — this is the most expensive candidate in either list. Ten unique floors is ten times the content of one floor with a tint ramp. Mark it honestly and consider three distinct floors plus seven variations.

## GT10 — Who built the Tower? Is it built at all? Is it older than people?

> each floor is **its own place** — its own weather, its own ecology, its own size — and the only thing they share is that something at the top of each one is in charge. Floor scale varies wildly; one is a corridor, one is a country.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It makes the Tower worth ten distinct art passes instead of ten palette swaps, which is a `D`-level decision the repo hasn't spent yet.
_Costs_ — this is the most expensive candidate in either list. Ten unique floors is ten times the content of one floor with a tint ramp. Mark it honestly and consider three distinct floors plus seven variations.

## GT14 — What is the deep? D26 names subterranean seals under continental strain. Is there an underwor…

> a floor where **the thing in charge is dead.** No permission is granted there, no doctrine works, and everyone has quietly agreed not to talk about it.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It is the single best answer available to `FR8` (one thing never explained) because the _absence_ is the content. Nothing has to be invented — something has to be missing.

## GT15 — If every gate were shut, would that be good? What would the world be like the following spring?

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
_Costs_ — it commits the game to a _losing_ world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

## HS2 — Was there a fall? Were things better once, and does the evidence agree with the belief?

_Two sources propose different answers here. Both stand until somebody chooses._

> **there was more land.** The ruins aren't abandoned settlements, they're the high ground of somewhere that mostly isn't there any more.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.**

> **yes and no.** There was a fall; it was smaller than people think, and the decline afterwards did more damage than the event. The belief is about the war; the evidence is about the fifty years after it.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.**

## HS3 — How far back does reliable memory go — three generations, thirty, none?

> memory forgets **unevenly, not gradually.** Some things are recorded precisely; some people are "an unknown"; some parentages are lost to time. Dating is by disaster and by ruler, and the two don't agree.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a _reason_ rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."

## HS4 — Is the gates' arrival dated? Is there a "before"?

> **a stretch of history everyone can point at and nobody can read.** Not a mystery the game withholds — a gap the _world_ maintains, with someone benefitting.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** This is the strongest `FR8` candidate on either list, because it satisfies "never explained" without requiring the _designers_ to know the answer either.
↳ Falls out: `HS4` (is there a written history, and who keeps it) — yes, and it has a hole in it. `NW5` — the record is central, official and incomplete on purpose. `FA4` — the church's authority partly rests on the hole.

## HS5 — Name one historical figure everyone has heard of and one nobody has.

> memory forgets **unevenly, not gradually.** Some things are recorded precisely; some people are "an unknown"; some parentages are lost to time. Dating is by disaster and by ruler, and the two don't agree.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a _reason_ rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."

## HS7 — Are the twelve heroes' origins — dead forge-masters, raided borderlands, war creeping past a…

> **one war**, and the twelve are survivorship bias. Dead forge-masters, raided borderlands and a monastery the war crept past are three views of the same twenty years.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**
↳ Falls out: `HS1` (biggest thing in the past) and `HS6` (last thing that changed the world) collapse into one answer, which is cheap and strong.

## HS8 — Is the world's story going somewhere? If the player never existed, what would the next fifty…

> **the next fifty years happen regardless.** The run is one legible thread pulled through a world that was already moving, and it gets recorded in the same format as everything else.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
↳ Falls out: `SM5` gains its best supporting argument (the world persists because it was never about you), and `DV9` — the twelve are twelve among many, listed alongside people you never met.

## KI6 — Every one of the twelve heroes is an orphan, an exile, a stray or a cloistered scholar who le…

> **one war**, and the twelve are survivorship bias. Dead forge-masters, raided borderlands and a monastery the war crept past are three views of the same twenty years.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**
↳ Falls out: `HS1` (biggest thing in the past) and `HS6` (last thing that changed the world) collapse into one answer, which is cheap and strong.

## KI8 — Naming: family names, place names, earned names, titles?

> everyone of consequence carries an epithet, and the real name is the private thing. "The Sworn Blade," "The Hedge Priest" are not flavour — they are what the world knows and what news can carry.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.** `NW1`–`NW3` already model news degrading over distance. An epithet survives a hundred retellings; a name doesn't. This makes `NW3` (can someone lie about you faster than the truth) mechanically obvious.

## KN1 — Doctrine fades in 900 steps if unused. Is that forgetting, or is the knowledge itself leaving…

_Two sources propose different answers here. Both stand until somebody chooses._

> knowledge that stops being questioned stops being knowledge. The fade is the world refusing to let a garment harden, not a memory limit.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.** It converts a balance number into a thesis, and it makes `KN12` (does the stock of knowledge grow) answerable as "no, and that's deliberate."
_Costs_ — it makes `KN2` (nothing is inherited) a fact about _knowledge_, not about minds — so `KN2` can no longer be answered as "someone enforces it."

> doctrine fades because a rule nobody executes stops being a rule. `KN9` — **yes, there are false books**, and they persist precisely as long as nobody tests them.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.** It gives the 900-step fade a second, mechanical justification alongside WATF's epistemological one. Two independent readings landing on the same number is a good sign for the number.

## KN2 — Nothing is inherited — a taught student holds it, a child does not. Why can't it be inherited…

> teaching is **a season, body to body** — a form can only be transmitted by someone performing it. That is _why_ `KN2` holds: nothing reaches a child who never trained, because there is nothing to hand over, only something to be shown.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.** It converts `KN2` from an enforced rule into a physical fact, which the book explicitly asks you to choose between.
↳ Falls out: `KN11` (expertise without doctrine) — yes, and it dies with the person. `KN3` (what a book is) — a book is a _record of a form_, useless without someone to demonstrate it, which is why `KN1`'s fade is survivable.

## KN6 — Who staffs a library — an order, a family, a single person, nobody?

> **no.** Most people in the world have never seen a gate and don't believe the Tower has ten floors. Delvers are a rumoured profession to two-thirds of the map.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
↳ Falls out: `NW4` (what does an ordinary person believe about gates) and `DV4` (what four armed strangers look like) both get sharper — they look like liars.

## KN7 — Is knowledge hoarded? Is there anything nobody is allowed to read, and who decides?

> libraries stock **what survived**, not what was best. Gaps in a library's shelves are a map of a disaster nobody living remembers. `KN12` — the puddle evaporates, and the shelves prove it.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.**
↳ Pairs with: a library looks fortified because it was, once, and it didn't work.

## KN9 — Can doctrine be wrong? Is there a false book that teaches a thing that does not work, or work…

> doctrine fades because a rule nobody executes stops being a rule. `KN9` — **yes, there are false books**, and they persist precisely as long as nobody tests them.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.** It gives the 900-step fade a second, mechanical justification alongside WATF's epistemological one. Two independent readings landing on the same number is a good sign for the number.

## KN10 — Teaching transfers doctrine person to person. What does teaching physically involve — an hour…

> teaching is **a season, body to body** — a form can only be transmitted by someone performing it. That is _why_ `KN2` holds: nothing reaches a child who never trained, because there is nothing to hand over, only something to be shown.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.** It converts `KN2` from an enforced rule into a physical fact, which the book explicitly asks you to choose between.
↳ Falls out: `KN11` (expertise without doctrine) — yes, and it dies with the person. `KN3` (what a book is) — a book is a _record of a form_, useless without someone to demonstrate it, which is why `KN1`'s fade is survivable.

## KN12 — Does the world's stock of knowledge grow over a century, or is it a puddle evaporating as fas…

> libraries stock **what survived**, not what was best. Gaps in a library's shelves are a map of a disaster nobody living remembers. `KN12` — the puddle evaporates, and the shelves prove it.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.**
↳ Pairs with: a library looks fortified because it was, once, and it didn't work.

## LF1 — Are the people human? Only human?

> **incomplete.** Gate-things are not evil and not animals; they are unfinished, and the ones that get named on their own side stop being monsters.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
↳ Falls out: `OT4` (are the beasts considered people) — the Bamboo Court's beasts are the named ones. `OT7` (is a monster's death mourned) — only by the named ones, and there are some. This is the single best available answer to the `OT` block and it costs nothing in the engine.

## LF2 — The Bamboo Court has red panda masters, sword bears, cannon bears. Are those people or beasts…

> **they get stronger where the gate is older.** Time open, not player level. A gate nobody has touched in two years is worse than a fresh one — and the world scales by neglect rather than by you.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It's the cleanest anti-level-scaling answer available, and it makes exploration a race rather than a progression curve.

## LF4 — Where do gate-monsters come from: born behind the gate, made by it, or pulled through from a…

> they are **ordinary where they come from**. Everything monstrous about them is a fact about the doorway, not the animal.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** Now adopted — `doug-md` answered `LF4` in [note 04](voice-notes/2026-09-14-doug-md-part-1-d-life-bodies-and-the-monstrous.md) with exactly this reading: "the gate monsters come from a world where they were originally". See the Part I entry above; this proposal is the thing he picked.
_Costs_ — forecloses "made by the gate," which is the more mystical reading and the one that pairs better with `PW3`. These two are in tension; the divergence ledger is the right home if you split.
↳ Falls out: `LF3` — they eat, sleep, breed and age, and do all of it badly on this side. `OT7` (is a monster's death mourned) becomes "yes, somewhere you can't reach."
↳ He went further than the proposal did: they stay, and they **interbreed with people here**. "Ordinary where they come from" no longer describes only the far side of the door.

## LF5 — Can a gate-monster be reasoned with, bought, or kept? Has anyone tried?

> **they get stronger where the gate is older.** Time open, not player level. A gate nobody has touched in two years is worse than a fresh one — and the world scales by neglect rather than by you.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It's the cleanest anti-level-scaling answer available, and it makes exploration a race rather than a progression curve.

## LF7 — Domesticated animals: horses, oxen, dogs, hawks? Does the party own any?

> **incomplete.** Gate-things are not evil and not animals; they are unfinished, and the ones that get named on their own side stop being monsters.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
↳ Falls out: `OT4` (are the beasts considered people) — the Bamboo Court's beasts are the named ones. `OT7` (is a monster's death mourned) — only by the named ones, and there are some. This is the single best available answer to the `OT` block and it costs nothing in the engine.

## LN1 — How large is the continent in days of walking, edge to edge?

> **density of the grammar varies by place.** Where it's thick, gate-things are stronger, doctrine is easier and stranger, and people live differently. Where it's thin, life is ordinary and delving is a story.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
_Costs_ — it has to be _visible on the node map_ or it's a note nobody reads. That's map work, not fiction work.
↳ Falls out: more than any other candidate in either list — `LF6` (why beasts cluster), `EC5` (why trade goes the long way), `DV5` (why delvers concentrate), `AR2` (why some villages are walled), `KI3` (why people move). One variable, six answers.

## LN2 — What is beyond the map edge — ocean, more land, nothing you can reach?

> **nobody has the map.** Not "the map is the frontier of a larger world" — the stronger version: the complete map does not exist, several partial ones disagree, and possessing a good one is wealth.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.**
↳ Pairs with: mana-density regions plus incomplete cartography gives you the whole `LN` block in two decisions.

## LN4 — Is the map the whole known world, or the frontier of a larger one that is safe and boring?

_Two sources propose different answers here. Both stand until somebody chooses._

> the map is the **frontier**, and there is one safe place that is boring, crowded and administered. `LN4` answers "frontier of a larger one," and that larger one has running water.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** Still standing. `doug-md` answered `LN4` in [note 02](voice-notes/2026-09-14-doug-md-part-1-b-land-scale-and-edges.md) only as far as "there is definitely locations that have not been discovered yet". He neither took this nor refused it, so the safe administered elsewhere is still an open offer.
_Costs_ — this adds a place the game does not currently model. Cheap as fiction, expensive if anyone wants to go there.

> there is **one** genuinely safe place, and it is **administered, crowded and boring.** Not a warm hearth — a walled city with queues, districts, rules and an hour's walk between anywhere. Safety is what you go to when you can no longer afford the frontier.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a _deflation_ rather than a reward — which is the honest emotional shape of a roguelite loop.
_Costs_ — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
↳ Falls out: `EC6` (where a delver's money goes) — the city takes it. `DV6` (what happens to a delver who quits) — they stay, and they're one of thousands.

## LN5 — Where does fresh water come from, and who controls it?

> one road is **safe because of something that happened**, and everything expensive travels on it. The others are cheaper and kill people.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It turns the FFTA-style node map from a menu into a political object, and it gives `HS6` (the last thing that changed the world) a physical consequence you can stand on.

## LN6 — Name the three landmarks everyone in the world can name, even people who have never left thei…

> **each site holds you for its own length of time.** Arriving somewhere costs steps; _leaving_ it costs a different number depending on where it is, and the number is a fact about the place, not the distance.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** The repo already prices everything in steps and already chose an FFTA-style node map. This turns the node map from a menu into terrain, with no pathfinding and no walkable overworld. The cheapest possible way to make a node graph feel like a world.
_Costs_ — small, and mostly data. It does make route planning legible in a way that invites optimisation — worth checking against `SM12`.

## LN10 — Is there a place nobody goes, and is the reason true?

> **nobody has the map.** Not "the map is the frontier of a larger world" — the stronger version: the complete map does not exist, several partial ones disagree, and possessing a good one is wealth.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.**
↳ Pairs with: mana-density regions plus incomplete cartography gives you the whole `LN` block in two decisions.

## LP1 — How long is a background — a sentence, a paragraph, a page?

> a background is **who named you, and what it cost them.** That one line generates an origin, a debt and a person who is elsewhere.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**

## LP5 — May a background grant a book? It collides with pillar 2 — the Library is somewhere you walk…

> a background is **who named you, and what it cost them.** That one line generates an origin, a debt and a person who is elsewhere.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**

## LP6 — What is the largest thing a gift may be? A blade is 90 gold; is that the ceiling or the floor?

> **not every background carries a gift, and a gift always names its maker.** A blade at 90 gold is the ceiling, not the floor — anything larger stops being a piece of history and becomes a head start.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.**
↳ Pairs with: yes, the player should see why they have it. "Made by X for Y, who didn't survive" is one line and does more than a stat.

## LP7 — Should every background carry a gift, or are some just history?

> **not every background carries a gift, and a gift always names its maker.** A blade at 90 gold is the ceiling, not the floor — anything larger stops being a piece of history and becomes a head start.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.**
↳ Pairs with: yes, the player should see why they have it. "Made by X for Y, who didn't survive" is one line and does more than a stat.

## LP19 — Is a creed ever a lie — what they say they believe versus what they do?

> **yes to both, and the break is visible to the party before it's visible to the player.** A character whose creed and conduct diverge gets banter about it from someone who noticed.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.** The repo has bond-tracked banter with warm/cold thresholds already. This is a content answer, not an engine answer.

## LP23 — Can an oath be broken in play, and what happens mechanically when it is?

> **yes to both, and the break is visible to the party before it's visible to the player.** A character whose creed and conduct diverge gets banter about it from someone who noticed.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.** The repo has bond-tracked banter with warm/cold thresholds already. This is a content answer, not an engine answer.

## LP27 — Does the player ever see a character's full history, or only what comes up?

> **no.** You learn a companion by travelling with them, and some of it only if you're there at the right moment. Anything on a party screen is what they'd tell a stranger.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.**

## LP28 — Do the fifteen you did not become carry their history visibly — does meeting them tell you an…

> **somewhere that is their own business**, doing it whether or not you arrive. You meet them mid-story, not waiting.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**
_Costs_ — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a _fragment_ of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## LW1 — Is killing a crime here? When, where, and who enforces it?

> **consequences arrive immediately and are final.** The world has no appeals, no second hearing, no reputational recovery. A wrong word in the wrong district is settled on the spot by whoever has standing there.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** It's the same design philosophy as permadeath applied to the social layer, which makes `FR4` (what the world does to people who stay in it) answerable in one line.
_Costs_ — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

## LW5 — Captives are ransomed at a price, on a deadline, and may be sold if the deadline lapses. Sold…

> **consequences arrive immediately and are final.** The world has no appeals, no second hearing, no reputational recovery. A wrong word in the wrong district is settled on the spot by whoever has standing there.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** It's the same design philosophy as permadeath applied to the social layer, which makes `FR4` (what the world does to people who stay in it) answerable in one line.
_Costs_ — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

## LW6 — Is there a law of hospitality — a rule about the road, the hearth, the guest? What does break…

> **anyone, and that's the problem.** No licence, no association, no dispatch. People who shouldn't go, go, and the parties that take them in as bag-carriers are doing something the world hasn't decided is a crime.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It answers `LW6` (what the law doesn't cover) with the thing the player is doing, which is far better than an abstract gap.

## LW8 — A grudge grants +10% damage against an ancestral foe. Is vengeance a recognised right here? I…

> **yes, and no feud has ever been successfully ended.** The +10% grudge damage is the mechanical tip of a system where `annals.gd` keeps feuds alive longer than the people in them.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
↳ Pairs with: a grudge against something that can't be fought is just a feud whose other side got culled.

## LW9 — Who owns land, and how is that recorded if news travels by foot?

> **consequences arrive immediately and are final.** The world has no appeals, no second hearing, no reputational recovery. A wrong word in the wrong district is settled on the spot by whoever has standing there.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** It's the same design philosophy as permadeath applied to the social layer, which makes `FR4` (what the world does to people who stay in it) answerable in one line.
_Costs_ — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

## MK7 — Where does metal come from, who mines it, and is that a good job or a sentence?

> the smith is the **end of a supply chain the party is standing in**. They didn't get the steel; someone did, at a cost, from a place that is on the map and dangerous.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.** Compatible with the founder answer. Answers `MK8` (a material worth a war) as a live condition rather than a lore note, and gives `EC5` (trade over distance) something specific to move.
↳ `doug-md` answered `MK7` in [note 05](voice-notes/2026-09-14-doug-md-part-1-e-matter-craft-and-making.md) — dwarves mine most of it, you negotiate with them, and slavers mine as a sentence. That names the far end of this supply chain rather than contradicting it. Both can be true.

## MK9 — Is anything in the world clearly made by a lost hand — machinery, masonry, roads nobody could…

> ruins are **legible**. A ruin says what it was, who held it, and roughly when it stopped, to anyone who can read a carving — and most people can't.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.** In tension with the founder answer.
↳ Falls out: `KN5` (literacy in a village) matters mechanically for the first time: the ruin has been telling everyone for two hundred years.
↳ `doug-md` answered `MK9` in [note 05](voice-notes/2026-09-14-doug-md-part-1-e-matter-craft-and-making.md) the other way: a gate landed on the old machinery and "destroyed the blueprints to create it once again", and the maker "is no longer able to be found". A ruin that says what it was and a ruin whose record was destroyed are not the same ruin. **Which is it — legible, or erased?**

## MK12 — Are charms manufactured or found?

> **made by delvers, for delvers.** Every charm found on a body (`D24`) names a maker, and the maker is very probably also dead.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.** Still standing, and now the live question. `doug-md` answered `MK12` in [note 05](voice-notes/2026-09-14-doug-md-part-1-e-matter-craft-and-making.md) with "Charms can be found and manufactured" — which settles the either/or and leaves _who makes them_ exactly where this proposal is aimed.
_Costs_ — nothing in the engine. This is pure fiction over an existing item table, which makes it one of the cheapest strong candidates on the whole list.
↳ Falls out: a quiet inheritance chain nobody arranged — the thing that saved you was made for someone else, by someone who died. `BD2` (is a grace a physical, moral, or legal event) can then be answered as _someone made it happen, and they're gone_.

## MN8 — NPCs are deferred behind an LLM seam (D03). When they arrive, what should an NPC want by defa…

> **to follow the rule they were taught**, including when it no longer fits. Not safety, not status — habit. That is a default an LLM-free NPC can actually execute, which matters because `D03` defers minds.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**

## MX8 — Should a lean ever be a drawback as well as a bonus?

> **each site holds you for its own length of time.** Arriving somewhere costs steps; _leaving_ it costs a different number depending on where it is, and the number is a fact about the place, not the distance.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** The repo already prices everything in steps and already chose an FFTA-style node map. This turns the node map from a menu into terrain, with no pathfinding and no walkable overworld. The cheapest possible way to make a node graph feel like a world.
_Costs_ — small, and mostly data. It does make route planning legible in a way that invites optimisation — worth checking against `SM12`.

## MX11 — Is the next run the same world, later? The biggest open question in the project.

_Two sources propose different answers here. Both stand until somebody chooses._

> **yes, and the mechanism is doctrine drift.** What the last run taught, spread and left behind is what the new run's world assumes.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**
_Against_ — ORV says the previous run survives as _text_ (remembered, distorted). CHRONICLE says it survives as _behaviour_ (nobody remembers, everyone does it). These are compatible and better together — the memory is wrong and the habit is right. If you take both, `SM6`'s Museum becomes the place where the two disagree in public.

> **yes**, and what the last run did survives as _text_ — half-remembered, distorted, attributed to the wrong person.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**
_Costs_ — this is the largest single decision in the project and it forecloses the clean-reset reading. Do not let it land on a `[M]`.
↳ Falls out: `SM6`/`MX12` — the Museum is a library the next run can walk into and read about itself, badly. `HS3` (how far back does reliable memory go) becomes "one run."

## MX12 — What is the Museum — a place in the world, a menu, or a memorial the next run can walk into?

> the memorial wall, **in the world, walkable**. A building you enter, with names, ranks, the deed that earned each one and the gate it ended at.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**
↳ Pairs with: if the next run is the same world later, the Museum is where the previous run is legible — and it is legible _wrongly_, because someone had to write it down.

## MX13 — Does anything at all carry between runs, and if so is that a betrayal of pillar 4?

> what carries is **rules, not power.** The next run inherits how the world behaves — which graces are common, what a town expects of a delver, whether feuds get settled — and inherits nothing you owned.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.** It is a defensible reading of pillar 4 rather than an exception to it. Nothing in the next run is easier; things are _differently shaped_.
_Costs_ — it needs a persistence format the build doesn't have. `World` already serialises; a world-rule delta is new. Honest estimate: this is the most expensive candidate in the whole lineage set.

## MX16 — Where exactly does each of the fifteen stand when they are not the lead — a fixed area, or so…

> **somewhere that is their own business**, doing it whether or not you arrive. You meet them mid-story, not waiting.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**
_Costs_ — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a _fragment_ of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## MX18 — Should a named hero refuse to join based on creed, or does gold always work?

> **refusal, and gold never moves them.** The sixteen are not hires; the fifteen you didn't become have opinions about you, and at least three of them are wrong about you in interesting ways.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.**
_Costs_ — real work. Each of the sixteen needs a `CH5` answer (what they refuse to do) before this can ship, which front-loads Part VI.
↳ Falls out: `MX17` (how hiring works) — a price for nameless recruits, a **condition** for named ones. `EC10` (is there anything money can't buy) gets a concrete instance instead of a philosophical one.

## MX19 — If you hire someone and they die, is that different from a nameless recruit dying?

_Two sources propose different answers here. Both stand until somebody chooses._

> **you name them, and it costs you.** A recruit who takes a name from you gains standing, proficiency, or a grace — and you permanently give up something to do it. Names are the scarce resource, not gold.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** It is the strongest available answer to `SM8` because it makes attachment a _mechanic the player chose to pay for_, and it resolves `MX19` cleanly — a named death is different because you can feel where the cost went.
_Against_ — XCOM says the world names them for you, after the fact, from what they did. Tensura says you name them, in advance, at a price. These are genuinely different games and cannot both be true. **Primary ledger item.**
_Costs_ — a naming economy is new systems work — a permanent resource the player spends on people. Not small, but it sits on top of the existing `Character`/`Unit` split rather than fighting it.

> **no, and that's the point.** Both get the same line in the same annal. The difference is entirely how long you'd travelled with them, which is the player's problem, not the world's.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.** It protects `D14` (the run continues when companions die) from becoming a tier list of grief.

## MX20 — Can you meet a character whose temper you rolled — is there a version of you walking around?

> yes. They are a worse version of you and do not know it.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**

## NW6 — What does an ordinary person actually know about the wider world — three facts, or none?

> every villager knows **one thing worth hearing and has one thing worth taking.** That is their whole characterisation, and it is enough.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.** It turns `DY1`–`DY12` from a worldbuilding essay into a content format the build can actually consume, and it gives `MN8` (what should an NPC want by default) a default that doesn't need an LLM: to keep the one thing.

## NW7 — Who remembers the dead, and for how long? Is there a name that is still spoken a century after?

_Two sources propose different answers here. Both stand until somebody chooses._

> **the unnamed are not remembered because there is nothing left to remember.** A nameless recruit's death is a fact; a named one's death leaves a bond that other people can feel go.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
_Costs_ — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
↳ Falls out: `memorials.json` gets a rule instead of a threshold — memorials are for the named, and that's why there are so few.

> a deed accumulates until the person becomes the deed. Memorials in `memorials.json` are not for people, they're for stories that got large enough to need somewhere to sit.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**

## NW9 — Is there a word in this world for "famous"? Is fame good?

> everyone of consequence carries an epithet, and the real name is the private thing. "The Sworn Blade," "The Hedge Priest" are not flavour — they are what the world knows and what news can carry.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.** `NW1`–`NW3` already model news degrading over distance. An epithet survives a hundred retellings; a name doesn't. This makes `NW3` (can someone lie about you faster than the truth) mechanically obvious.

## OT2 — Do any people side with the gates deliberately, and what do they get?

> **density of the grammar varies by place.** Where it's thick, gate-things are stronger, doctrine is easier and stranger, and people live differently. Where it's thin, life is ordinary and delving is a story.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
_Costs_ — it has to be _visible on the node map_ or it's a note nobody reads. That's map work, not fiction work.
↳ Falls out: more than any other candidate in either list — `LF6` (why beasts cluster), `EC5` (why trade goes the long way), `DV5` (why delvers concentrate), `AR2` (why some villages are walled), `KI3` (why people move). One variable, six answers.

## OT5 — What happens to someone who comes back from a gate changed?

> both have plain words, and neither is polite. The world has vocabulary for these because they happen weekly.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**

## OT8 — Do the factions ally against gates, or does the gate crisis fail to unite anyone?

_Two sources propose different answers here. Both stand until somebody chooses._

> **no, and that is the disaster.** Everyone is individually strong enough and nobody combines. The gates aren't winning on power.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.** Answers `HS8` (where is the world going) without inventing a doom clock — the trajectory is bad for a reason that is entirely political.
_Costs_ — commits `RU8` and `RU11` to a world where the factions' mutual hostility is the actual threat, which makes `GT15` (would shutting every gate be good) much sharper.

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
_Costs_ — it commits the game to a _losing_ world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

## PW1 — What is the grammar? Skill trees are generated from a hidden system of themes and archetypes.…

> a **language**. Doctrine books are phrasebooks, a generated skill tree is a dialect, and the Codex is a grammar being reconstructed by people who only ever hear it spoken.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.**
_Costs_ — commits `PW3` — if the grammar is a language, gates are probably something said in it, not a separate fact.
↳ Falls out: `PW12` — two characters with the same tree said the same sentence. They don't hold the same object, and neither one owns it.

## PW4 — What does using a power feel and look like from the outside — is it visibly uncanny, or does…

> doctrine works **by permission**, and the permission is floor-local. What you can do on floor three you cannot do on floor seven until something there agrees.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
_Costs_ — commits `PW2` to "something grants it," which forecloses WATF's reading of the grammar as an impersonal language. Direct collision with **16.1**; ledger item.
↳ Falls out: `PW6` — yes, revocable, and there is a known way to break the terms. `KN9` (can doctrine be wrong) — a book can be perfectly correct and simply not apply where you're standing.

## PW5 — Can ordinary people use power, or is it delvers only? Does the village smith have a rung of a…

> **scale, not vocabulary.** The same doctrine at proficiency 10 and proficiency 90 is the same act done bigger. Nobody learns a secret ninth technique.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It's consistent with a proficiency number the repo already has, and it kills the temptation to gate content behind hidden skills.

## PW6 — Is power feared, admired, taxed, or licensed?

> doctrine works **by permission**, and the permission is floor-local. What you can do on floor three you cannot do on floor seven until something there agrees.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
_Costs_ — commits `PW2` to "something grants it," which forecloses WATF's reading of the grammar as an impersonal language. Direct collision with **16.1**; ledger item.
↳ Falls out: `PW6` — yes, revocable, and there is a known way to break the terms. `KN9` (can doctrine be wrong) — a book can be perfectly correct and simply not apply where you're standing.

## PW8 — The Codex is the world's catalogue of the grammar. Who else is cataloguing? Is the player the…

> everyone's Codex is different, because the keywords are personal. Two complete Codices would not agree, and nobody has ever compared two.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.** Solves `PW8` without inventing an institution, and gives `KN9` (can doctrine be wrong) a sharp answer — a false book is a true book in someone else's dialect.

## PW9 — At 100% understanding you can choose your theme (D17). What does choosing mean — you learned…

> neither asking nor taking. You learned to **write**, and the thing you take off at 100% is the Codex.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.**

## PW10 — Does the grammar know it is being catalogued? Does it resist?

> yes, and the resistance is that cataloguing works. The Codex is itself a system; the closer to 100%, the more the cataloguer becomes its subject.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.**
↳ Pairs with: the Codex reports _how much_, never _what_. `FR8`'s one permanently unexplained thing is the grammar's own content.

## PW11 — Is the grammar beautiful, arbitrary, or ugly? A thing to admire or a thing to contain?

> **scale, not vocabulary.** The same doctrine at proficiency 10 and proficiency 90 is the same act done bigger. Nobody learns a secret ninth technique.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It's consistent with a proficiency number the repo already has, and it kills the temptation to gate content behind hidden skills.

## RU1 — Nine of ten factions are hostile; only the Freeholds are not. Is that the world's actual poli…

> **the view from the road**. The Heart Empire's line infantry and a Freehold militia are the same people two years apart, and a delving party is a small armed group that nobody asked for.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**
_Costs_ — this makes `LW2` (raiding a town) unambiguously a crime rather than frontier normality.
↳ Falls out: `DV4` — dread, then business. `RU10` (who protects a village) — whoever is closest and cheapest, which is why the Freeholds aren't hostile: they can't afford to be.

## RU2 — The Heart Empire "came up the road one spring and never named a reason." What is the reason?…

> a **succession**, and the reason is embarrassing. Someone needed a war to be legitimate, and nobody at the sharp end was told.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.** Answers `RU2`'s second half — _do they know it themselves_ — with "the men on the road don't, and the three people who do are dead or lying." Sets up `RU4` (is there a throne, is anyone on it) as: there is a throne, and the question of who sits on it is exactly what started this.

## RU3 — Is the Heart Empire a state, a religion, an army, or an infection? What happens to a village…

> **one large faith with a headquarters, a highway and an army**, plus local practice everywhere that doesn't match it. The faith is the second-largest political actor on the map and does not think of itself as political.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
↳ Falls out: `FA5` (do the faithful and the delvers disagree) — constantly, and it's about the gates. `KN4` (who can read) — the church can, which is why the church has the history.

## RU4 — Rank is read off the metal — copper at the gate, white at the throne. Is there a throne, and…

> the ten factions are a **club with seats**, not ten armies. They know each other, they meet, and the real events are seats changing hands — by abdication as often as by war.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** `RU11` (is anyone winning) — no, because the seats are the point and nobody wants the table overturned. It also gives `OT8` (do they ally against the gates) the right shape: they'd have to admit the table doesn't cover it.

## RU6 — The Bamboo Court took its students from the beasts "when no people were left worth teaching."…

> the last sect worth teaching **was wiped out in one action**, and the Court remembers whose fault it was. Taking students from the beasts was not philosophy, it was the only option left.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.**
↳ Falls out: `RU7` (the Broken Oath — whose oath, still hurting?) and `HS7` link to the same event. `OT4` (are the beasts considered people) gets an answer with a grudge in it.

## RU8 — The Tide, The Dusk, The Ember Wilds, The Wild: which of these are peoples, which are places…

> the ten factions are a **club with seats**, not ten armies. They know each other, they meet, and the real events are seats changing hands — by abdication as often as by war.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** `RU11` (is anyone winning) — no, because the seats are the point and nobody wants the table overturned. It also gives `OT8` (do they ally against the gates) the right shape: they'd have to admit the table doesn't cover it.

## RU9 — What is the largest thing that can be called a government here? Does any authority reach furt…

> the ten factions are a **club with seats**, not ten armies. They know each other, they meet, and the real events are seats changing hands — by abdication as often as by war.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** `RU11` (is anyone winning) — no, because the seats are the point and nobody wants the table overturned. It also gives `OT8` (do they ally against the gates) the right shape: they'd have to admit the table doesn't cover it.

## RU10 — Who protects a village, actually? If a village has forty people and a gate opens nearby, who…

> there is **one** genuinely safe place, and it is **administered, crowded and boring.** Not a warm hearth — a walled city with queues, districts, rules and an hour's walk between anywhere. Safety is what you go to when you can no longer afford the frontier.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a _deflation_ rather than a reward — which is the honest emotional shape of a roguelite loop.
_Costs_ — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
↳ Falls out: `EC6` (where a delver's money goes) — the city takes it. `DV6` (what happens to a delver who quits) — they stay, and they're one of thousands.

## RU12 — Who was in charge a hundred years ago, and how did that end?

> **no.** Most people in the world have never seen a gate and don't believe the Tower has ten floors. Delvers are a rumoured profession to two-thirds of the map.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
↳ Falls out: `NW4` (what does an ordinary person believe about gates) and `DV4` (what four armed strangers look like) both get sharper — they look like liars.

## SF3 — Is anyone watching the player's run from inside the fiction? (The lineage names _Omniscient R…

> yes, and exactly one. Not a god and not an audience — a **reader**, who knows the shape and not the outcome.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.** The repo already has `annals.gd` writing deeds down and `news.gd` walking them. A single reader is the cheapest possible answer: it needs no new system, only a voice.
_Costs_ — commits `FR10` (who tells this world's story to itself) to something non-human, which forecloses "chroniclers and drunks."

## SF6 — Does anyone in the world understand the step-clock — that walking is what moves things?

> **no, but some people have correct rules derived from it.** "Sharpen at dusk, never at dawn" is a step-clock observation nobody knows is one. That reframes `KN8`'s aphoristic doctrine style as _compressed empiricism_, which is a much better answer than "it's a genre."
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**

## SK8 — Is there darkness that is dangerous on its own, or is night just dimmer?

> **night is a different set of rules.** Different encounters, different people awake, different prices, different things possible at the same door.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.** Supported by the founder answer.
_Costs_ — the repo flips seasons globally at a step count (`CL2`) and prices everything in steps. A day cycle is a second clock, and `SK6` (what is a step) has to absorb it. Real engine work — mark it honestly.
↳ Falls out: `SK7` (weather beyond season) gets a cheap strong answer — the day cycle is the weather that matters. `DY2` (what do people drink and where) becomes a _night_ answer: the alehouse is where hires happen because that's who's awake.
↳ `doug-md` answered `SK8` in [note 01](voice-notes/2026-09-14-doug-md-part-1-a-physical.md) as "a safe haven for the monsters… predatory animals will be active" — a different set of rules after dark, which is this proposal from the encounter side. He also answered `CL2` as a **sweep**, not a global flip, so the cost line above understates how much of the season clock is already being asked to move.
↳ `MK5` (glow bugs, glow sticks, oil burners) says portable light is cheap, so a night cycle is a choice players make rather than a wall they hit.

## SK9 — Is the sky the same everywhere, or does it change over the Tower, over a broken gate, over th…

> yes, and it is unreachable for an ordinary geographic reason rather than a magical one. A dead band. No one goes, and the reason is boring and absolute.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** Boring impossibilities are more convincing than warded ones, and it answers `BN2` (edges of the map) without a wall.

## SM1 — Save-scumming is allowed (D21) and permadeath is a pillar. Is reloading a fact about the worl…

> **a fact about the player, declared openly.** BG3 permits it, expects it, and never fictionalises it — and the game is not weaker for the honesty.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.** It lets `CO7` (revisit D21) resolve as _keep it, stop apologising_, and keeps `SM5` free to be answered by the world rather than by the save system.
_Costs_ — if ORV's `SM5` candidate lands (next run is the same world later), this one gets harder — reloading and re-running become different kinds of repetition, and `MX13` has to say which one carries.

## SM2 — Difficulty settings change enemy strength, grace odds and whether permadeath exists at all. A…

> **the haven heals you completely and that is not mercy.** You are restored, you are poorer, time has passed, and the gates got worse while you sat there. Recovery is fine as long as the world moves during it.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
↳ Pairs with: if an ignored gate spills, then resting in the haven has a cost that isn't a resource. That's the cleanest way both co-founders' hardest candidates can be true at once.

## SM5 — The run ends when the player character dies but the world is saved. Is the next run the same…

_Two sources propose different answers here. Both stand until somebody chooses._

> **yes, and the mechanism is doctrine drift.** What the last run taught, spread and left behind is what the new run's world assumes.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**
_Against_ — ORV says the previous run survives as _text_ (remembered, distorted). CHRONICLE says it survives as _behaviour_ (nobody remembers, everyone does it). These are compatible and better together — the memory is wrong and the habit is right. If you take both, `SM6`'s Museum becomes the place where the two disagree in public.

> **yes**, and what the last run did survives as _text_ — half-remembered, distorted, attributed to the wrong person.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**
_Costs_ — this is the largest single decision in the project and it forecloses the clean-reset reading. Do not let it land on a `[M]`.
↳ Falls out: `SM6`/`MX12` — the Museum is a library the next run can walk into and read about itself, badly. `HS3` (how far back does reliable memory go) becomes "one run."

## SM6 — D25 lets a victor enshrine the run in a Museum. What is the Museum — a place in the world, a…

> the memorial wall, **in the world, walkable**. A building you enter, with names, ranks, the deed that earned each one and the gate it ended at.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**
↳ Pairs with: if the next run is the same world later, the Museum is where the previous run is legible — and it is legible _wrongly_, because someone had to write it down.

## SM7 — The party heals fully at a village and permanently at home. Does the world's danger survive a…

_Two sources propose different answers here. Both stand until somebody chooses._

> **the haven heals you completely and that is not mercy.** You are restored, you are poorer, time has passed, and the gates got worse while you sat there. Recovery is fine as long as the world moves during it.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
↳ Pairs with: if an ignored gate spills, then resting in the haven has a cost that isn't a resource. That's the cleanest way both co-founders' hardest candidates can be true at once.

> yes, because the resource that never restores is **people**. XCOM heals soldiers fully between missions and is still the most punishing game on this list. Full heal at a village is fine as long as the roster is the scarce thing.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**

## SM8 — Companions are hired for gold and dismissed at will, and D14 says the story continues when th…

_Two sources propose different answers here. Both stand until somebody chooses._

> **you made their gear.** A companion carrying something you made, or something made for someone who died, is attachment without a single line of dialogue.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.**

> **you name them, and it costs you.** A recruit who takes a name from you gains standing, proficiency, or a grace — and you permanently give up something to do it. Names are the scarce resource, not gold.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** It is the strongest available answer to `SM8` because it makes attachment a _mechanic the player chose to pay for_, and it resolves `MX19` cleanly — a named death is different because you can feel where the cost went.
_Against_ — XCOM says the world names them for you, after the fact, from what they did. Tensura says you name them, in advance, at a price. These are genuinely different games and cannot both be true. **Primary ledger item.**
_Costs_ — a naming economy is new systems work — a permanent resource the player spends on people. Not small, but it sits on top of the existing `Character`/`Unit` split rather than fighting it.

> **mechanics carry the name, fiction delivers it late.** A recruit earns a second name through what they did — proficiency, a grace they survived, a town they saved — and that name turns up afterwards in a place you went for another reason.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.** The repo already has `annals.gd`, `memorials.json`, `news.gd` and bond-tracked banter. This candidate requires no new system, only one link: the name must reach a surface the player visits for unrelated reasons.
_Costs_ — commits `EC12` — companionship is a contract _and_ the world writes it down anyway, which is the tension that makes dismissal feel bad.

## TG1 — Is there one language, several, or a trade tongue over many?

> **three that matter**, split by race and continent, plus one dead one that doctrine is written in. A character who can read the dead one is a character with a past.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**

## TG3 — Is there an older language — the one doctrine and the grammar are written in?

> **three that matter**, split by race and continent, plus one dead one that doctrine is written in. A character who can read the dead one is a character with a past.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**

## TG5 — How do people date events with no eras and no central calendar — by season, by ruler, by disa…

> memory forgets **unevenly, not gradually.** Some things are recorded precisely; some people are "an unknown"; some parentages are lost to time. Dating is by disaster and by ruler, and the two don't agree.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a _reason_ rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."
