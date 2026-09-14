# Answers

What has actually been settled, and who settled it. One entry per question that has moved, keyed by
its ID in [15 — The Question Book](../15-the-question-book.md).

Entries are written in the house style of [09 — Wishlist](../09-wishlist.md): the words as spoken in
a blockquote, then a **bold status**, then what it means. **A quote is never edited.** If what
somebody said is unclear, the entry says so and asks rather than tidying it into sense.

## The statuses

| Lead | Means |
| --- | --- |
| `**Answered.**` | Said plainly by a founder. Canon |
| `**Partly answered.**` | Half of it landed. The entry says which half is still open |
| `**Inferred.**` | Nobody said it outright; it follows from the IDs named in the entry. **Provisional** until a founder confirms |
| `**Contested.**` | Two founders answered differently. Goes to the [divergence ledger](divergence-ledger.md) |
| `**Blocked.**` | They started and trailed off. The entry writes out the one follow-up question needed |
| `**Noted.**` | A guest answered. Recorded and quotable, not canon on its own — see [respondents](respondents.md) |
| `**Proposed.**` | A lineage source offers a drafted answer, with its costs already worked out. Adopted only when a founder says so — see [16 — Lineage entries](../16-lineage/00-index.md) |

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

_Nothing answered by a founder yet._ Six recordings covering the whole of Part I are waiting in
[`DROP-ZONE/`](../../DROP-ZONE) — Physical, Land, Climate, Life, Matter and Gates — and need
transcribing into [`voice-notes/`](voice-notes/) before their answers can land here.

Below are **143 proposals from the sixteen lineage sources**, covering **129 of the 366
questions**. None of them is an answer. Each is a drafted option with its reasoning and its
cost already worked out, so a question can be settled with a yes, a no, or a better idea rather
than from nothing. **Thirteen carry more than one proposal** — sources arguing — and those are
in the [divergence ledger](divergence-ledger.md) rather than waiting for a yes.

---

## AR1 — Why is a village where it is — water, road, defensibility, a shut gate nobody talks about?

> there is **one** genuinely safe place, and it is **administered, crowded and boring.** Not a warm hearth — a walled city with queues, districts, rules and an hour's walk between anywhere. Safety is what you go to when you can no longer afford the frontier.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a *deflation* rather than a reward — which is the honest emotional shape of a roguelite loop.
*Costs* — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
↳ Falls out: `EC6` (where a delver's money goes) — the city takes it. `DV6` (what happens to a delver who quits) — they stay, and they're one of thousands.

## AR2 — Is a village walled? What does it do at night?

_Two sources propose different answers here. Both stand until somebody chooses._

> at least one settlement is protected by **wards instead of walls**, because the thing it fears comes from above. One detail, and it tells you the whole region.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**

> the map is the **frontier**, and there is one safe place that is boring, crowded and administered. `LN4` answers "frontier of a larger one," and that larger one has running water.
> — `src-barbarian`, [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
*Costs* — this adds a place the game does not currently model. Cheap as fiction, expensive if anyone wants to go there.

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
*Costs* — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
↳ Falls out: `memorials.json` gets a rule instead of a threshold — memorials are for the named, and that's why there are so few.

## BD3 — The Ground grace works within 6 tiles of a hearth. Why? Is a hearth warded, watched, loved, o…

> **the unnamed are not remembered because there is nothing left to remember.** A nameless recruit's death is a fact; a named one's death leaves a bond that other people can feel go.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.**
*Costs* — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
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
*Costs* — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a *fragment* of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## CL5 — Is the climate stable, or has it been changing within living memory?

> **density of the grammar varies by place.** Where it's thick, gate-things are stronger, doctrine is easier and stranger, and people live differently. Where it's thin, life is ordinary and delving is a story.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.**
*Costs* — it has to be *visible on the node map* or it's a note nobody reads. That's map work, not fiction work.
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
*Costs* — kills the romantic reading of the twelve heroes. `DV9` then answers "twelve among many."
↳ Falls out: `DV4` (what villagers think of four armed strangers) — **business**, neither relief nor dread. `DV2` — there's a register, because ranks are only worth anything if someone keeps them.

> **no.** There is a ceremony, or a debt, or a village with nothing in it. People delve because the alternatives ran out, and the ones who love it are strange.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
*Against* — your `DV1` candidate was "it's a job with a price board." The co-founder's is "it's what happens when you have no other option." These are close but not identical, and the gap shows up in `DV4` (what villagers think) — a tradesman gets business, a conscript gets pity. **Small ledger item, worth ten minutes.**

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
*Against* — your `DV1` candidate was "it's a job with a price board." The co-founder's is "it's what happens when you have no other option." These are close but not identical, and the gap shows up in `DV4` (what villagers think) — a tradesman gets business, a conscript gets pity. **Small ledger item, worth ten minutes.**

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

> the FFT answer is *the record is written by the winner and the record is wrong*. That is compatible with the repo's `annals.gd` and with `SF3` — but only one of them can be the frame. Worth marking against ORV's reader.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**

## FR7 — A player just lost a character they cared about. What should they feel in the ten seconds aft…

_Two sources propose different answers here. Both stand until somebody chooses._

> **nothing happens.** No cutscene, no acknowledgement, no pause. The world's indifference is the feeling.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.**
*Against* — FFT's version says the rule clicks and grief arrives late at a memorial. This version says grief never arrives from the world at all and the player supplies it. One is generous, one is colder. Ledger.

> **the flat click of a rule first.** Grief arrives late, somewhere else — a name in a list, a memorial you walked past for another reason.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.** It's the honest description of what permadeath actually does, and it tells `SM8` what its job is: mechanics carry the name, fiction delivers it late.

## FR8 — Should the world end up explicable? Name one thing that must still be unexplained when the Co…

> **a stretch of history everyone can point at and nobody can read.** Not a mystery the game withholds — a gap the *world* maintains, with someone benefitting.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** This is the strongest `FR8` candidate on either list, because it satisfies "never explained" without requiring the *designers* to know the answer either.
↳ Falls out: `HS4` (is there a written history, and who keeps it) — yes, and it has a hole in it. `NW5` — the record is central, official and incomplete on purpose. `FA4` — the church's authority partly rests on the hole.

## FR10 — Who tells this world's story to itself — chroniclers, priests, drunks, nobody?

> **nobody, deliberately.** Things get written down — annals, memorials, engravings — but no one is assembling them. `annals.gd` is a pile, not a chronicle.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
*Costs* — directly contradicts ORV's `SF3` reader candidate. These two cannot both be true; this is a divergence-ledger item, and probably the most interesting disagreement available to you and your brother.

## GT2 — What is on the other side — a whole world, a pocket, a stomach, nothing that would survive be…

> **yes, by looking.** Size, colour, sound. No sensor, no number — the world tells you honestly and people go in anyway because of what's on the other side.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It gives the node map information the player can act on without a UI element, and it makes `DV3` (how a party chooses a gate) a real decision rather than a menu.
*Against* — the source uses a measuring device and an association that dispatches teams. Earth Kings has no such institution and shouldn't invent one — replacing the meter with the eye is the port.

## GT4 — When did they start? Is there a person alive who remembers a world without them?

> **yes, by looking.** Size, colour, sound. No sensor, no number — the world tells you honestly and people go in anyway because of what's on the other side.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** It gives the node map information the player can act on without a UI element, and it makes `DV3` (how a party chooses a gate) a real decision rather than a menu.
*Against* — the source uses a measuring device and an association that dispatches teams. Earth Kings has no such institution and shouldn't invent one — replacing the meter with the eye is the port.

## GT6 — When a gate breaks (D15), what actually happens on the ground — does it burst, spread, sink…

> yes, and it is unreachable for an ordinary geographic reason rather than a magical one. A dead band. No one goes, and the reason is boring and absolute.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** Boring impossibilities are more convincing than warded ones, and it answers `BN2` (edges of the map) without a wall.

## GT7 — When a gate is shut forever, what is left behind? A scar, a monument, a good field, nothing?

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
*Costs* — it commits the game to a *losing* world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

## GT9 — Gate rank rises with distance from the Tower (D08). Is the Tower holding them back, generatin…

> each floor is **its own place** — its own weather, its own ecology, its own size — and the only thing they share is that something at the top of each one is in charge. Floor scale varies wildly; one is a corridor, one is a country.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It makes the Tower worth ten distinct art passes instead of ten palette swaps, which is a `D`-level decision the repo hasn't spent yet.
*Costs* — this is the most expensive candidate in either list. Ten unique floors is ten times the content of one floor with a tint ramp. Mark it honestly and consider three distinct floors plus seven variations.

## GT10 — Who built the Tower? Is it built at all? Is it older than people?

> each floor is **its own place** — its own weather, its own ecology, its own size — and the only thing they share is that something at the top of each one is in charge. Floor scale varies wildly; one is a corridor, one is a country.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It makes the Tower worth ten distinct art passes instead of ten palette swaps, which is a `D`-level decision the repo hasn't spent yet.
*Costs* — this is the most expensive candidate in either list. Ten unique floors is ten times the content of one floor with a tint ramp. Mark it honestly and consider three distinct floors plus seven variations.

## GT14 — What is the deep? D26 names subterranean seals under continental strain. Is there an underwor…

> a floor where **the thing in charge is dead.** No permission is granted there, no doctrine works, and everyone has quietly agreed not to talk about it.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.** It is the single best answer available to `FR8` (one thing never explained) because the *absence* is the content. Nothing has to be invented — something has to be missing.

## GT15 — If every gate were shut, would that be good? What would the world be like the following spring?

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
*Costs* — it commits the game to a *losing* world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

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

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a *reason* rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."

## HS4 — Is the gates' arrival dated? Is there a "before"?

> **a stretch of history everyone can point at and nobody can read.** Not a mystery the game withholds — a gap the *world* maintains, with someone benefitting.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** This is the strongest `FR8` candidate on either list, because it satisfies "never explained" without requiring the *designers* to know the answer either.
↳ Falls out: `HS4` (is there a written history, and who keeps it) — yes, and it has a hole in it. `NW5` — the record is central, official and incomplete on purpose. `FA4` — the church's authority partly rests on the hole.

## HS5 — Name one historical figure everyone has heard of and one nobody has.

> memory forgets **unevenly, not gradually.** Some things are recorded precisely; some people are "an unknown"; some parentages are lost to time. Dating is by disaster and by ruler, and the two don't agree.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a *reason* rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."

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
*Costs* — it makes `KN2` (nothing is inherited) a fact about *knowledge*, not about minds — so `KN2` can no longer be answered as "someone enforces it."

> doctrine fades because a rule nobody executes stops being a rule. `KN9` — **yes, there are false books**, and they persist precisely as long as nobody tests them.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.** It gives the 900-step fade a second, mechanical justification alongside WATF's epistemological one. Two independent readings landing on the same number is a good sign for the number.

## KN2 — Nothing is inherited — a taught student holds it, a child does not. Why can't it be inherited…

> teaching is **a season, body to body** — a form can only be transmitted by someone performing it. That is *why* `KN2` holds: nothing reaches a child who never trained, because there is nothing to hand over, only something to be shown.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.** It converts `KN2` from an enforced rule into a physical fact, which the book explicitly asks you to choose between.
↳ Falls out: `KN11` (expertise without doctrine) — yes, and it dies with the person. `KN3` (what a book is) — a book is a *record of a form*, useless without someone to demonstrate it, which is why `KN1`'s fade is survivable.

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

> teaching is **a season, body to body** — a form can only be transmitted by someone performing it. That is *why* `KN2` holds: nothing reaches a child who never trained, because there is nothing to hand over, only something to be shown.
> — `src-mount-hua`, [16.9-return-of-the-mount-hua-sect](../16-lineage/16.9-return-of-the-mount-hua-sect.md)

**Proposed.** It converts `KN2` from an enforced rule into a physical fact, which the book explicitly asks you to choose between.
↳ Falls out: `KN11` (expertise without doctrine) — yes, and it dies with the person. `KN3` (what a book is) — a book is a *record of a form*, useless without someone to demonstrate it, which is why `KN1`'s fade is survivable.

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

**Proposed.**
*Costs* — forecloses "made by the gate," which is the more mystical reading and the one that pairs better with `PW3`. These two are in tension; the divergence ledger is the right home if you split.
↳ Falls out: `LF3` — they eat, sleep, breed and age, and do all of it badly on this side. `OT7` (is a monster's death mourned) becomes "yes, somewhere you can't reach."

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
*Costs* — it has to be *visible on the node map* or it's a note nobody reads. That's map work, not fiction work.
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

**Proposed.**
*Costs* — this adds a place the game does not currently model. Cheap as fiction, expensive if anyone wants to go there.

> there is **one** genuinely safe place, and it is **administered, crowded and boring.** Not a warm hearth — a walled city with queues, districts, rules and an hour's walk between anywhere. Safety is what you go to when you can no longer afford the frontier.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a *deflation* rather than a reward — which is the honest emotional shape of a roguelite loop.
*Costs* — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
↳ Falls out: `EC6` (where a delver's money goes) — the city takes it. `DV6` (what happens to a delver who quits) — they stay, and they're one of thousands.

## LN5 — Where does fresh water come from, and who controls it?

> one road is **safe because of something that happened**, and everything expensive travels on it. The others are cheaper and kill people.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It turns the FFTA-style node map from a menu into a political object, and it gives `HS6` (the last thing that changed the world) a physical consequence you can stand on.

## LN6 — Name the three landmarks everyone in the world can name, even people who have never left thei…

> **each site holds you for its own length of time.** Arriving somewhere costs steps; *leaving* it costs a different number depending on where it is, and the number is a fact about the place, not the distance.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** The repo already prices everything in steps and already chose an FFTA-style node map. This turns the node map from a menu into terrain, with no pathfinding and no walkable overworld. The cheapest possible way to make a node graph feel like a world.
*Costs* — small, and mostly data. It does make route planning legible in a way that invites optimisation — worth checking against `SM12`.

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
*Costs* — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a *fragment* of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## LW1 — Is killing a crime here? When, where, and who enforces it?

> **consequences arrive immediately and are final.** The world has no appeals, no second hearing, no reputational recovery. A wrong word in the wrong district is settled on the spot by whoever has standing there.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** It's the same design philosophy as permadeath applied to the social layer, which makes `FR4` (what the world does to people who stay in it) answerable in one line.
*Costs* — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

## LW5 — Captives are ransomed at a price, on a deadline, and may be sold if the deadline lapses. Sold…

> **consequences arrive immediately and are final.** The world has no appeals, no second hearing, no reputational recovery. A wrong word in the wrong district is settled on the spot by whoever has standing there.
> — `src-barbarian` (co-founder's reading), [16.3-surviving-the-game-as-a-barbarian](../16-lineage/16.3-surviving-the-game-as-a-barbarian.md)

**Proposed.** It's the same design philosophy as permadeath applied to the social layer, which makes `FR4` (what the world does to people who stay in it) answerable in one line.
*Costs* — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

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
*Costs* — this is a real tonal commitment and belongs in `BN` before it belongs in `LW`. A world with instant fatal consequences for speech is a world where the player will reload — which drags `SM1` (**16.6**) back onto the table.

## MK7 — Where does metal come from, who mines it, and is that a good job or a sentence?

> the smith is the **end of a supply chain the party is standing in**. They didn't get the steel; someone did, at a cost, from a place that is on the map and dangerous.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.** Answers `MK8` (a material worth a war) as a live condition rather than a lore note, and gives `EC5` (trade over distance) something specific to move.

## MK9 — Is anything in the world clearly made by a lost hand — machinery, masonry, roads nobody could…

> ruins are **legible**. A ruin says what it was, who held it, and roughly when it stopped, to anyone who can read a carving — and most people can't.
> — `src-dwarf-fortress`, [16.8-dwarf-fortress](../16-lineage/16.8-dwarf-fortress.md)

**Proposed.**
↳ Falls out: `KN5` (literacy in a village) matters mechanically for the first time: the ruin has been telling everyone for two hundred years.

## MK12 — Are charms manufactured or found?

> **made by delvers, for delvers.** Every charm found on a body (`D24`) names a maker, and the maker is very probably also dead.
> — `src-regressor`, [16.10-the-regressor-can-make-them-all](../16-lineage/16.10-the-regressor-can-make-them-all.md)

**Proposed.**
*Costs* — nothing in the engine. This is pure fiction over an existing item table, which makes it one of the cheapest strong candidates on the whole list.
↳ Falls out: a quiet inheritance chain nobody arranged — the thing that saved you was made for someone else, by someone who died. `BD2` (is a grace a physical, moral, or legal event) can then be answered as *someone made it happen, and they're gone*.

## MN8 — NPCs are deferred behind an LLM seam (D03). When they arrive, what should an NPC want by defa…

> **to follow the rule they were taught**, including when it no longer fits. Not safety, not status — habit. That is a default an LLM-free NPC can actually execute, which matters because `D03` defers minds.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**

## MX8 — Should a lean ever be a drawback as well as a bonus?

> **each site holds you for its own length of time.** Arriving somewhere costs steps; *leaving* it costs a different number depending on where it is, and the number is a fact about the place, not the distance.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** The repo already prices everything in steps and already chose an FFTA-style node map. This turns the node map from a menu into terrain, with no pathfinding and no walkable overworld. The cheapest possible way to make a node graph feel like a world.
*Costs* — small, and mostly data. It does make route planning legible in a way that invites optimisation — worth checking against `SM12`.

## MX11 — Is the next run the same world, later? The biggest open question in the project.

_Two sources propose different answers here. Both stand until somebody chooses._

> **yes, and the mechanism is doctrine drift.** What the last run taught, spread and left behind is what the new run's world assumes.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**
*Against* — ORV says the previous run survives as *text* (remembered, distorted). CHRONICLE says it survives as *behaviour* (nobody remembers, everyone does it). These are compatible and better together — the memory is wrong and the habit is right. If you take both, `SM6`'s Museum becomes the place where the two disagree in public.

> **yes**, and what the last run did survives as *text* — half-remembered, distorted, attributed to the wrong person.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**
*Costs* — this is the largest single decision in the project and it forecloses the clean-reset reading. Do not let it land on a `[M]`.
↳ Falls out: `SM6`/`MX12` — the Museum is a library the next run can walk into and read about itself, badly. `HS3` (how far back does reliable memory go) becomes "one run."

## MX12 — What is the Museum — a place in the world, a menu, or a memorial the next run can walk into?

> the memorial wall, **in the world, walkable**. A building you enter, with names, ranks, the deed that earned each one and the gate it ended at.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**
↳ Pairs with: if the next run is the same world later, the Museum is where the previous run is legible — and it is legible *wrongly*, because someone had to write it down.

## MX13 — Does anything at all carry between runs, and if so is that a betrayal of pillar 4?

> what carries is **rules, not power.** The next run inherits how the world behaves — which graces are common, what a town expects of a delver, whether feuds get settled — and inherits nothing you owned.
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.** It is a defensible reading of pillar 4 rather than an exception to it. Nothing in the next run is easier; things are *differently shaped*.
*Costs* — it needs a persistence format the build doesn't have. `World` already serialises; a world-rule delta is new. Honest estimate: this is the most expensive candidate in the whole lineage set.

## MX16 — Where exactly does each of the fifteen stand when they are not the lead — a fixed area, or so…

> **somewhere that is their own business**, doing it whether or not you arrive. You meet them mid-story, not waiting.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**
*Costs* — requires each of the fifteen to have an activity, which is `CH14` answered sixteen times. It is the cheapest of the Part VI questions to answer and a good one to run first.
↳ Falls out: `LP28` — meeting them tells you a *fragment* of their history, visible from what they're doing, never the whole. `MX14` — the party screen shows what they'd tell a stranger.

## MX18 — Should a named hero refuse to join based on creed, or does gold always work?

> **refusal, and gold never moves them.** The sixteen are not hires; the fifteen you didn't become have opinions about you, and at least three of them are wrong about you in interesting ways.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.**
*Costs* — real work. Each of the sixteen needs a `CH5` answer (what they refuse to do) before this can ship, which front-loads Part VI.
↳ Falls out: `MX17` (how hiring works) — a price for nameless recruits, a **condition** for named ones. `EC10` (is there anything money can't buy) gets a concrete instance instead of a philosophical one.

## MX19 — If you hire someone and they die, is that different from a nameless recruit dying?

_Two sources propose different answers here. Both stand until somebody chooses._

> **you name them, and it costs you.** A recruit who takes a name from you gains standing, proficiency, or a grace — and you permanently give up something to do it. Names are the scarce resource, not gold.
> — `src-slime`, [16.14-that-time-i-got-reincarnated-as-a-slime](../16-lineage/16.14-that-time-i-got-reincarnated-as-a-slime.md)

**Proposed.** It is the strongest available answer to `SM8` because it makes attachment a *mechanic the player chose to pay for*, and it resolves `MX19` cleanly — a named death is different because you can feel where the cost went.
*Against* — XCOM says the world names them for you, after the fact, from what they did. Tensura says you name them, in advance, at a price. These are genuinely different games and cannot both be true. **Primary ledger item.**
*Costs* — a naming economy is new systems work — a permanent resource the player spends on people. Not small, but it sits on top of the existing `Character`/`Unit` split rather than fighting it.

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
*Costs* — commits `BD2` (is a grace physical, moral or legal) to physical. That forecloses the ORV-flavoured reading where a grace is a story about you.
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
*Costs* — it has to be *visible on the node map* or it's a note nobody reads. That's map work, not fiction work.
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
*Costs* — commits `RU8` and `RU11` to a world where the factions' mutual hostility is the actual threat, which makes `GT15` (would shutting every gate be good) much sharper.

> **it spills.** An open gate left long enough starts pushing outward — beasts on the roads, then a settlement gone, then land that nobody farms again. The map gets worse while you're elsewhere.
> — `src-solo-leveling`, [16.16-solo-leveling](../16-lineage/16.16-solo-leveling.md)

**Proposed.** The repo has a step clock, a world that moves between visits, and gates that open and close. This connects all three into pressure, and it answers `GT15` (would shutting every gate be good) with a hard **yes** — which is a cleaner frame than ambiguity.
*Costs* — it commits the game to a *losing* world state, which collides with `SM2` and `MX22` (difficulty, and whether the world can become unwinnable). Also collides with **16.3**'s reading of gates as ordinary workplaces — a thing with a doom clock is not a job. **Ledger item**, and the most consequential one in the co-founder's list.

## PW1 — What is the grammar? Skill trees are generated from a hidden system of themes and archetypes.…

> a **language**. Doctrine books are phrasebooks, a generated skill tree is a dialect, and the Codex is a grammar being reconstructed by people who only ever hear it spoken.
> — `src-watf`, [16.1-world-after-the-fall](../16-lineage/16.1-world-after-the-fall.md)

**Proposed.**
*Costs* — commits `PW3` — if the grammar is a language, gates are probably something said in it, not a separate fact.
↳ Falls out: `PW12` — two characters with the same tree said the same sentence. They don't hold the same object, and neither one owns it.

## PW4 — What does using a power feel and look like from the outside — is it visibly uncanny, or does…

> doctrine works **by permission**, and the permission is floor-local. What you can do on floor three you cannot do on floor seven until something there agrees.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
*Costs* — commits `PW2` to "something grants it," which forecloses WATF's reading of the grammar as an impersonal language. Direct collision with **16.1**; ledger item.
↳ Falls out: `PW6` — yes, revocable, and there is a known way to break the terms. `KN9` (can doctrine be wrong) — a book can be perfectly correct and simply not apply where you're standing.

## PW5 — Can ordinary people use power, or is it delvers only? Does the village smith have a rung of a…

> **scale, not vocabulary.** The same doctrine at proficiency 10 and proficiency 90 is the same act done bigger. Nobody learns a secret ninth technique.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It's consistent with a proficiency number the repo already has, and it kills the temptation to gate content behind hidden skills.

## PW6 — Is power feared, admired, taxed, or licensed?

> doctrine works **by permission**, and the permission is floor-local. What you can do on floor three you cannot do on floor seven until something there agrees.
> — `src-tower-of-god`, [16.12-tower-of-god](../16-lineage/16.12-tower-of-god.md)

**Proposed.**
*Costs* — commits `PW2` to "something grants it," which forecloses WATF's reading of the grammar as an impersonal language. Direct collision with **16.1**; ledger item.
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
↳ Pairs with: the Codex reports *how much*, never *what*. `FR8`'s one permanently unexplained thing is the grammar's own content.

## PW11 — Is the grammar beautiful, arbitrary, or ugly? A thing to admire or a thing to contain?

> **scale, not vocabulary.** The same doctrine at proficiency 10 and proficiency 90 is the same act done bigger. Nobody learns a secret ninth technique.
> — `src-mushoku`, [16.13-mushoku-tensei](../16-lineage/16.13-mushoku-tensei.md)

**Proposed.** It's consistent with a proficiency number the repo already has, and it kills the temptation to gate content behind hidden skills.

## RU1 — Nine of ten factions are hostile; only the Freeholds are not. Is that the world's actual poli…

> **the view from the road**. The Heart Empire's line infantry and a Freehold militia are the same people two years apart, and a delving party is a small armed group that nobody asked for.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.**
*Costs* — this makes `LW2` (raiding a town) unambiguously a crime rather than frontier normality.
↳ Falls out: `DV4` — dread, then business. `RU10` (who protects a village) — whoever is closest and cheapest, which is why the Freeholds aren't hostile: they can't afford to be.

## RU2 — The Heart Empire "came up the road one spring and never named a reason." What is the reason?…

> a **succession**, and the reason is embarrassing. Someone needed a war to be legitimate, and nobody at the sharp end was told.
> — `src-fft`, [16.4-final-fantasy-tactics](../16-lineage/16.4-final-fantasy-tactics.md)

**Proposed.** Answers `RU2`'s second half — *do they know it themselves* — with "the men on the road don't, and the three people who do are dead or lying." Sets up `RU4` (is there a throne, is anyone on it) as: there is a throne, and the question of who sits on it is exactly what started this.

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

**Proposed.** `haven` already exists in the codebase as a distance metric (`distance_to_haven()`). This gives it a character, and it makes returning a *deflation* rather than a reward — which is the honest emotional shape of a roguelite loop.
*Costs* — the haven becomes a place with an identity, which is art and writing the roadmap hasn't scoped.
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
*Costs* — commits `FR10` (who tells this world's story to itself) to something non-human, which forecloses "chroniclers and drunks."

## SF6 — Does anyone in the world understand the step-clock — that walking is what moves things?

> **no, but some people have correct rules derived from it.** "Sharpen at dusk, never at dawn" is a step-clock observation nobody knows is one. That reframes `KN8`'s aphoristic doctrine style as *compressed empiricism*, which is a much better answer than "it's a genre."
> — `src-chronicle`, [16.11-chronicle](../16-lineage/16.11-chronicle.md)

**Proposed.**

## SK8 — Is there darkness that is dangerous on its own, or is night just dimmer?

> **night is a different set of rules.** Different encounters, different people awake, different prices, different things possible at the same door.
> — `src-octopath`, [16.7-octopath-traveler-2](../16-lineage/16.7-octopath-traveler-2.md)

**Proposed.**
*Costs* — the repo flips seasons globally at a step count (`CL2`) and prices everything in steps. A day cycle is a second clock, and `SK6` (what is a step) has to absorb it. Real engine work — mark it honestly.
↳ Falls out: `SK7` (weather beyond season) gets a cheap strong answer — the day cycle is the weather that matters. `DY2` (what do people drink and where) becomes a *night* answer: the alehouse is where hires happen because that's who's awake.

## SK9 — Is the sky the same everywhere, or does it change over the Tower, over a broken gate, over th…

> yes, and it is unreachable for an ordinary geographic reason rather than a magical one. A dead band. No one goes, and the reason is boring and absolute.
> — `src-one-piece`, [16.15-one-piece](../16-lineage/16.15-one-piece.md)

**Proposed.** Boring impossibilities are more convincing than warded ones, and it answers `BN2` (edges of the map) without a wall.

## SM1 — Save-scumming is allowed (D21) and permadeath is a pillar. Is reloading a fact about the worl…

> **a fact about the player, declared openly.** BG3 permits it, expects it, and never fictionalises it — and the game is not weaker for the honesty.
> — `src-bg3`, [16.6-baldurs-gate-3](../16-lineage/16.6-baldurs-gate-3.md)

**Proposed.** It lets `CO7` (revisit D21) resolve as *keep it, stop apologising*, and keeps `SM5` free to be answered by the world rather than by the save system.
*Costs* — if ORV's `SM5` candidate lands (next run is the same world later), this one gets harder — reloading and re-running become different kinds of repetition, and `MX13` has to say which one carries.

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
*Against* — ORV says the previous run survives as *text* (remembered, distorted). CHRONICLE says it survives as *behaviour* (nobody remembers, everyone does it). These are compatible and better together — the memory is wrong and the habit is right. If you take both, `SM6`'s Museum becomes the place where the two disagree in public.

> **yes**, and what the last run did survives as *text* — half-remembered, distorted, attributed to the wrong person.
> — `src-orv`, [16.2-omniscient-readers-viewpoint](../16-lineage/16.2-omniscient-readers-viewpoint.md)

**Proposed.**
*Costs* — this is the largest single decision in the project and it forecloses the clean-reset reading. Do not let it land on a `[M]`.
↳ Falls out: `SM6`/`MX12` — the Museum is a library the next run can walk into and read about itself, badly. `HS3` (how far back does reliable memory go) becomes "one run."

## SM6 — D25 lets a victor enshrine the run in a Museum. What is the Museum — a place in the world, a…

> the memorial wall, **in the world, walkable**. A building you enter, with names, ranks, the deed that earned each one and the gate it ended at.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.**
↳ Pairs with: if the next run is the same world later, the Museum is where the previous run is legible — and it is legible *wrongly*, because someone had to write it down.

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

**Proposed.** It is the strongest available answer to `SM8` because it makes attachment a *mechanic the player chose to pay for*, and it resolves `MX19` cleanly — a named death is different because you can feel where the cost went.
*Against* — XCOM says the world names them for you, after the fact, from what they did. Tensura says you name them, in advance, at a price. These are genuinely different games and cannot both be true. **Primary ledger item.**
*Costs* — a naming economy is new systems work — a permanent resource the player spends on people. Not small, but it sits on top of the existing `Character`/`Unit` split rather than fighting it.

> **mechanics carry the name, fiction delivers it late.** A recruit earns a second name through what they did — proficiency, a grace they survived, a town they saved — and that name turns up afterwards in a place you went for another reason.
> — `src-xcom`, [16.5-xcom](../16-lineage/16.5-xcom.md)

**Proposed.** The repo already has `annals.gd`, `memorials.json`, `news.gd` and bond-tracked banter. This candidate requires no new system, only one link: the name must reach a surface the player visits for unrelated reasons.
*Costs* — commits `EC12` — companionship is a contract *and* the world writes it down anyway, which is the tension that makes dismissal feel bad.

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

**Proposed.** It gives `HS5` (one figure everyone's heard of, one nobody has) a *reason* rather than a pair of names, and it makes `NW5` (is there a central written record) answerable as "several, all partial."
