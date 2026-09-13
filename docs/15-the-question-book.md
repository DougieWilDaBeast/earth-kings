# 15 — The Question Book

Every question _Earth Kings_ still needs answered, in one place, so it can be read aloud and
talked at. It absorbs the world charter interview that used to live in `docs/12`, and adds
everything the sixteen tempers, the five lore pools and the casting mechanism opened up.

**Answers arrive as voice notes**, not as filled-in sheets — out of order, in fragments, doubling
back, sometimes trailing off. That is fine and expected. Drop the transcript in
[`worldbuilding/voice-notes/`](worldbuilding/voice-notes/), and it gets read against every question
here: what it settled outright, what it only settled in combination with something said three weeks
ago, and what it re-opened by accident.

- **What has been answered so far:** [worldbuilding/answers.md](worldbuilding/answers.md)
- **Who may answer, and with what standing:** [worldbuilding/respondents.md](worldbuilding/respondents.md)
- **Where two founders disagree:** [worldbuilding/divergence-ledger.md](worldbuilding/divergence-ledger.md)
- **How the sittings run:** [worldbuilding/00-process.md](worldbuilding/00-process.md)

## How to answer

- **Just talk.** One to three sentences per question is plenty; if it runs to a paragraph you are
  designing rather than answering, and the paragraph belongs in the ledger.
- **Say the ID if you can** — "SK6, a step is about a minute" — but you do not have to. Describing
  the question is enough to find it.
- **Say how much you care**, not how sure you are: `[H]` a real stake · `[M]` a preference ·
  `[L]` a shrug · `[—]` you decide · `[!]` **veto**, three for the whole book. These can be spoken:
  "and that one I'd walk away over" reads as `[!]`.
- **"I don't know" is an answer**, and a different one from "that's deliberately open".
- Where a question says **(repo:)** the code already implies an answer. Confirming it is a real
  answer. So is overturning it — note that it costs work.
- Answer what is true in the world, not what is fun for the player. Fun is Part IV's job.

## Reading the tables

| Column | What it is |
| --- | --- |
| **ID** | Permanent. Never renumbered, never reused, even if a question is retired |
| **Question** | The question. `(repo:)` marks what the code already assumes |
| **Bears on** | Other questions this one decides, implies or re-opens. When an answer lands here, every ID in this column gets re-checked — this is how answering one thing quietly changes another |

Parts 0 to V are the original 288 with their IDs untouched. Parts VI to IX are new.

| Part | Prefix | Questions | What it settles |
| --- | --- | --- | --- |
| 0 — Frame | `FR` | 10 | What the world is about |
| I — Physical | `SK` `LN` `CL` `LF` `MK` `GT` `BD` | 81 | Sky, land, weather, life, making, gates, death |
| II — Mental | `MN` `KN` `PW` `NW` `BL` `SF` | 60 | Minds, knowledge, the grammar, news, belief, perspective |
| III — Cultural | `RU` `LW` `EC` `KI` `FA` `TG` `DY` `AR` `OT` `DV` `HS` | 117 | Rule, law, money, kin, faith, language, daily life, history |
| IV — Seams | `SM` | 12 | Where mechanics and fiction scrape |
| V — Boundaries | `BN` | 8 | What must never be true |
| VI — The Sixteen | `CH` | 14 × 16 | Who each starting character is |
| VII — Pools & casting | `LP` | 30 | The five authored histories and how they attach |
| VIII — Mechanics open | `MX` | 25 | What this build left undecided |
| IX — Carried over | `CO` | 9 | Still-open items from the wishlist and roadmap |

---

## Part 0 — Frame

The eight questions that make the other two hundred cheap. Answer these first, in one sitting.

| ID | Question | Bears on |
| --- | --- | --- |
| FR1 | In one sentence: what is this world *about*? Not the plot — the thing the fiction exists to say. | FR3, FR9, BN1 |
| FR2 | Name three works whose **world** (not story, not combat) you want this to sit beside. What specifically do you want from each? |  |
| FR3 | Is the world tragic, indifferent, or secretly just? Does effort get rewarded by the universe, by people, or by nothing? | BD5, FA1, HS10 |
| FR4 | **What does "Earth Kings" mean?** Who is a king, what is the Earth in that phrase, and is the title claimed, inherited, or given? Is the player one, hunting one, or neither? | RU13, RU4, RU9, HS10 |
| FR5 | Is this our Earth — after something, before something — or a different world entirely? |  |
| FR6 | The Codex permits "absurd results" as valid output. Is absurdity a truth about the world's underlying physics, or a joke shared with the player over the world's head? | PW11, PW1 |
| FR7 | A player just lost a character they cared about. What should they feel in the ten seconds after — grief, injustice, guilt, or the flat click of a rule? | BD2, SM1, SM5 |
| FR8 | Should the world end up explicable? Name one thing that must still be unexplained when the Codex reads 100%. | PW10, GT2, PW8 |
| FR9 | Strip out all combat. What is still worth walking around in? |  |
| FR10 | Who tells this world's story to itself — chroniclers, priests, drunks, nobody? (repo: `annals.gd` writes deeds down; `news.gd` walks them a tile per 14 steps.) |  |

---

## Part I — Physical

### I.a Sky, time and cosmos — `SK`

| ID | Question | Bears on |
| --- | --- | --- |
| SK1 | Is this a planet? Does anyone in the world know that? |  |
| SK2 | What is in the sky by day — one sun, more, something that is not a sun? |  |
| SK3 | Moons: how many, what do they do, does anything in the world key off them? |  |
| SK4 | Are there stars, and are they navigable? Does anyone chart them? |  |
| SK5 | How long is a day, and how long is a year in days? | SK6, TG5, CL1 |
| SK6 | **What is a step?** Roughly how far, and how long does it take? Everything in the game is priced in steps — 900 to forget a book, 600 before a gate breaks — so this number silently sets every other pace. (repo: 120 steps per season, so a year ≈ 480 steps.) | KN1, GT6, CL2, LN1, LN9, NW1 |
| SK7 | Does the world have weather beyond season — storms, drought, a night cycle that matters? |  |
| SK8 | Is there darkness that is dangerous on its own, or is night just dimmer? |  |
| SK9 | Is the sky the same everywhere, or does it change over the Tower, over a broken gate, over the sea? |  |
| SK10 | Does anything up there look back? |  |

### I.b Land, scale and edges — `LN`

| ID | Question | Bears on |
| --- | --- | --- |
| LN1 | How large is the continent in days of walking, edge to edge? | SK6, LN9, NW1 |
| LN2 | What is beyond the map edge — ocean, more land, nothing you can reach? (repo: `ferry.gd` runs coastal cutters between ports, so there is a coast and there are boats.) | LN3, LN4, EC5 |
| LN3 | Are there other continents, and does anyone here know it? |  |
| LN4 | Is the map the whole known world, or the frontier of a larger one that is safe and boring? |  |
| LN5 | Where does fresh water come from, and who controls it? |  |
| LN6 | Name the three landmarks everyone in the world can name, even people who have never left their village. |  |
| LN7 | Which direction is "toward trouble" and which is "toward home"? Is there a cultural north? |  |
| LN8 | Roads: who built them, who maintains them, are they safe? (repo: roads are walkable terrain and Heart Empire ground.) |  |
| LN9 | How does an ordinary person travel a hundred miles — or do they simply never? |  |
| LN10 | Is there a place nobody goes, and is the reason true? |  |
| LN11 | Is the land itself old and worn, or young and raw? What does the oldest visible thing look like? |  |
| LN12 | Does the geography mean anything — is the Tower at a centre, is the coast a periphery, does elevation carry status? |  |

### I.c Climate and season — `CL`

| ID | Question | Bears on |
| --- | --- | --- |
| CL1 | The seasons are named for clovers — Lesser Green, Green, Brown, Ice. Why a clover? Who named them, and does the name predate the game's world or belong to one people? | CL2, TG5, SK5 |
| CL2 | Does the season turn everywhere at once, or does it sweep? (repo: it flips globally at a step count.) |  |
| CL3 | Is winter deadly to ordinary people — a thing survived — or merely cold? | CL7, DY9, EC4 |
| CL4 | What does a bad year look like, and how often does one come? |  |
| CL5 | Is the climate stable, or has it been changing within living memory? |  |
| CL6 | Do monsters, gates, or the Tower care what season it is? |  |
| CL7 | Is there a growing season, a harvest, a hungry month? What eats a village when it goes wrong? |  |
| CL8 | Does anyone claim to control weather, and are they lying? |  |

### I.d Life, bodies and the monstrous — `LF`

| ID | Question | Bears on |
| --- | --- | --- |
| LF1 | Are the people human? Only human? |  |
| LF2 | The Bamboo Court has red panda masters, sword bears, cannon bears. **Are those people or beasts?** Do they talk, hold property, bury their dead? | OT4, MN2, RU6, OT3 |
| LF3 | Are gate-monsters alive — do they eat, sleep, breed, age, bleed? | LF4, LF5, MN2, OT7 |
| LF4 | Where do gate-monsters *come from*: born behind the gate, made by it, or pulled through from a world where they were ordinary? | GT2, LF3, LF5, OT1, OT6 |
| LF5 | Can a gate-monster be reasoned with, bought, or kept? Has anyone tried? |  |
| LF6 | Is there a food chain, or is the ecology entirely narrative? What eats what when nobody is watching? |  |
| LF7 | Domesticated animals: horses, oxen, dogs, hawks? Does the party own any? |  |
| LF8 | What do people eat, and what is the staple crop or herd? |  |
| LF9 | Are there plants, fungi or animals that only exist near a gate? What does long exposure do to farmland? (repo: a broken gate raises local danger 25pp — does it also poison the ground?) | GT6, GT7, AR7, CL7 |
| LF10 | Is disease a thing in this world? Plague, infection, rot in a wound? |  |
| LF11 | How long does an ordinary person live, and what usually kills them? |  |
| LF12 | Are there giants, titans or things too large to fight? (repo: there is a faction literally called The Titans.) |  |
| LF13 | The Ooze is a faction. Is it one creature, many, or a condition that happens to places? |  |
| LF14 | Is anything in this world extinct, and does anyone remember it? |  |

### I.e Matter, craft and making — `MK`

| ID | Question | Bears on |
| --- | --- | --- |
| MK1 | What is the technology ceiling — is this iron, steel, or later? |  |
| MK2 | There are **cannon bears**. Is there gunpowder? Who has it, who is forbidden it? |  |
| MK3 | Is there printing, or is every book copied by hand? This decides what a library *is*. | KN3, KN5, KN6, TG7 |
| MK4 | Glass, lenses, clocks, mirrors? Can anyone measure time smaller than a day? |  |
| MK5 | What lights a room at night — tallow, oil, something else? |  |
| MK6 | What is medicine: herbs, prayer, surgery, doctrine? What can a healer actually fix? |  |
| MK7 | Where does metal come from, who mines it, and is that a good job or a sentence? |  |
| MK8 | Is any material rare enough to be worth a war? |  |
| MK9 | Is anything in the world clearly made by a lost hand — machinery, masonry, roads nobody could build now? |  |
| MK10 | What does a weapon cost relative to a year of a farmer's life? (repo: gold prices everything — hires, ransoms, beds.) |  |
| MK11 | The **bed** at home grants permanent HP, up to +22 for a canopied one. What is that, physically? Is comfort literally strengthening, or is it rest, safety, something being kept away? | KI11, BD3, SM7 |
| MK12 | Are charms manufactured or found? (repo: D24 — found on gate delves, carried by delvers who died there. So who made the one they were carrying?) | BD2, EC10, DV3 |

### I.f Gates, the Tower and the deep — `GT`

The spine of the world. Nothing else in this interview matters as much as this block.

| ID | Question | Bears on |
| --- | --- | --- |
| GT1 | **What is a gate?** A hole to another place, a wound in this one, a door that was built, or a mouth? | GT2, GT3, GT6, GT7, GT15, BL1, LF4 |
| GT2 | What is on the other side — a whole world, a pocket, a stomach, nothing that would survive being described? | LF4, GT14, OT1 |
| GT3 | Who or what opens them? Is it an event, an intention, or a natural process like weather? | RU2, GT15, BL1, FA10, GT8 |
| GT4 | When did they start? Is there a person alive who remembers a world without them? | HS4, FA10, BL6, HS2 |
| GT5 | What does a gate look and sound like from a mile away? From a hundred paces? Standing in the mouth? |  |
| GT6 | When a gate **breaks** (D15), what actually happens on the ground — does it burst, spread, sink, or simply start walking? | LF9, AR7, GT7 |
| GT7 | When a gate is **shut forever**, what is left behind? A scar, a monument, a good field, nothing? |  |
| GT8 | Gates never reopen, yet new rifts tear open under continental pressure (D26). **Is there a fixed number?** Is the world running out, or being slowly emptied into? | GT15, GT3, HS8 |
| GT9 | Gate rank rises with distance from the Tower (D08). Is the Tower holding them back, generating them, or standing at the eye of something? |  |
| GT10 | **Who built the Tower?** Is it built at all? Is it older than people? | GT9, GT12, GT13, PW2, HS1 |
| GT11 | Ten floors. Is it ten from outside too — is it a *building*, or does the inside not agree with the outside? |  |
| GT12 | The Spire Archon at the top (D25). Is it a ruler, a jailer, a gardener, a machine, or the last thing that was ever put there? | GT10, GT13, SM6 |
| GT13 | Does the Tower have doors on other floors — could a person live in it? Does anyone? |  |
| GT14 | What is the **deep**? D26 names subterranean seals under continental strain. Is there an underworld, and is it geological or occupied? | GT8, GT2, HS1 |
| GT15 | If every gate were shut, would that be good? What would the world be like the following spring? | GT8, HS8, DV3, DV6 |

### I.g Body, wound and death — `BD`

| ID | Question | Bears on |
| --- | --- | --- |
| BD1 | What is a corpse in this world? Does it stay where it fell? |  |
| BD2 | Permadeath is the rule, but a **grace** buys survival — charm, ally, book, ground, luck. Is a grace a physical event, a moral one, or a law of the world? Did someone write these rules down, or are they the odds of being lucky? | BD3, BD4, PW1, FA7, MK12 |
| BD3 | The **Ground** grace works within 6 tiles of a hearth. **Why?** Is a hearth warded, watched, loved, or simply near help? |  |
| BD4 | The **Lore** grace means a book you read keeps you alive. Physically, what is that — knowing where to fall, or something acting on your behalf? |  |
| BD5 | Is there an afterlife? Do people believe there is, and are they right? | BD6, BD7, BD8, FA1, FA7 |
| BD6 | Can the dead be raised, ever, by anyone, at any price? (This is a one-way-door question — answer it once and never again.) | BD5, BD7, FR3, SM1 |
| BD7 | Do the dead remain as anything — ghosts, revenants, gate-things wearing a face? |  |
| BD8 | What do people do with bodies: burial, burning, exposure, the sea? (repo: `memorials.json` exists — memorials *for* whom, placed by whom?) | BD5, FA3, NW7, DV10 |
| BD9 | Wounds: does anyone in this world lose a hand, an eye, a leg and keep going? Is permanent injury on the table, or is it death or fine? |  |
| BD10 | The party heals to full sleeping in a village. What is healing here — time, medicine, doctrine, or the fact that somebody let you in? |  |

---

## Part II — Mental

### II.a Minds — `MN`

| ID | Question | Bears on |
| --- | --- | --- |
| MN1 | Is there a soul, a spirit, a self that is more than the body? Who says so? | BD5, MN2, MN7, FA1 |
| MN2 | Do animals think? Do monsters? Is the difference one of kind or of degree? | LF2, LF3, OT4, OT7 |
| MN3 | Is there any mind in the world that is not a person and not an animal — a place with intent, a weather that wants something? |  |
| MN4 | Can minds touch: telepathy, shared dreams, a feeling that runs through a crowd? |  |
| MN5 | Do people dream, and does anyone take dreams seriously? |  |
| MN6 | What does madness look like, and what do people think causes it? |  |
| MN7 | Is there such a thing as a person who was *made*, not born? |  |
| MN8 | NPCs are deferred behind an LLM seam (D03). When they arrive, what should an NPC *want* by default — safety, status, someone in particular, nothing? |  |

### II.b Knowledge, doctrine and books — `KN`

| ID | Question | Bears on |
| --- | --- | --- |
| KN1 | **Doctrine fades in 900 steps if unused.** Is that forgetting, or is the knowledge itself leaving? Does the book still say the same words tomorrow? | KN2, KN12, SK6, KN4, PW1 |
| KN2 | Nothing is inherited — a taught student holds it, a child does not. **Why can't it be inherited?** Is that a fact about minds or a rule someone enforces? | KN1, KN12, PW5, KI2 |
| KN3 | What is a book made of, who copies it, and what does one cost? | MK3, KN5, KN6, EC5 |
| KN4 | Can a character **write** a book? Could the party leave something behind that another character could read? | KN12, KN7, NW5 |
| KN5 | Is anyone literate outside libraries? What is the literacy rate in a village? |  |
| KN6 | Who staffs a library — an order, a family, a single person, nobody? |  |
| KN7 | Is knowledge hoarded? Is there anything nobody is allowed to read, and who decides? |  |
| KN8 | Doctrine text is aphoristic ("Sharpen at dusk, never at dawn"). Is that a *style*, a genre, or the only way this knowledge can be written down without losing it? |  |
| KN9 | Can doctrine be wrong? Is there a false book that teaches a thing that does not work, or works badly? | KN8, BL2, PW1 |
| KN10 | Teaching transfers doctrine person to person. What does teaching physically involve — an hour, a season, a ritual? |  |
| KN11 | Is expertise possible outside doctrine — can someone simply be very good at something, with no book? (repo: proficiency rises with steps carrying a weapon.) |  |
| KN12 | Does the world's stock of knowledge grow over a century, or is it a puddle evaporating as fast as it's refilled? |  |

### II.c Power and the grammar — `PW`

| ID | Question | Bears on |
| --- | --- | --- |
| PW1 | **What is the grammar?** Skill trees are generated from a hidden system of themes and archetypes. Is that a law of nature, a language, an artefact, or a mind? | PW2, PW3, PW10, PW11, GT1, BD4 |
| PW2 | Did anyone write it? Is there an author, and is the author still around? | PW10, GT10, HS1, FA1 |
| PW3 | Is the grammar the same thing that makes gates, or a separate fact about the world? | GT1, GT14, PW1 |
| PW4 | What does using a power feel and look like from the outside — is it visibly uncanny, or does it look like a person being very good? |  |
| PW5 | Can ordinary people use power, or is it delvers only? Does the village smith have a rung of a tree? | PW6, KN2, DV5, DY5 |
| PW6 | Is power feared, admired, taxed, or licensed? |  |
| PW7 | Is there a cost to using it that the mechanics don't model — fatigue, drift, something that accumulates? |  |
| PW8 | The **Codex** is the world's catalogue of the grammar. Who else is cataloguing? Is the player the only one working on this, or joining a long effort? | PW9, PW10, FR8, KN12 |
| PW9 | At 100% understanding you can *choose* your theme (D17). What does choosing mean — you learned to ask, or you learned to take? |  |
| PW10 | Does the grammar know it is being catalogued? Does it resist? |  |
| PW11 | Is the grammar beautiful, arbitrary, or ugly? A thing to admire or a thing to contain? |  |
| PW12 | Two characters get the same generated tree, named and stored in the world. Are they the same power, or two people who arrived at the same shape? |  |

### II.d News, memory and reputation — `NW`

| ID | Question | Bears on |
| --- | --- | --- |
| NW1 | News travels roughly a tile per 14 steps. **What carries it?** Riders, traders, birds, gossip, something stranger? | NW2, NW3, NW5, TG7, LN8 |
| NW2 | Does news degrade as it travels — becoming rumour, exaggeration, a different story with your name still in it? | NW3, NW9, BL2 |
| NW3 | Can someone lie about you faster than the truth travels? Is reputation gameable, in-world? |  |
| NW4 | Prices move up to 30% on reputation. Is that fear, gratitude, or a posted rate? |  |
| NW5 | Is there any written record kept centrally, or is everything local memory? | KN4, TG5, TG7, HS3 |
| NW6 | What does an ordinary person actually know about the wider world — three facts, or none? |  |
| NW7 | Who remembers the dead, and for how long? Is there a name that is still spoken a century after? |  |
| NW8 | The **Nemesis** system: survivors remember and rally. What does an enemy who remembers you tell other enemies? |  |
| NW9 | Is there a word in this world for "famous"? Is fame good? |  |
| NW10 | If you raid a town (`K`) and it never trades with you again — does *only* that town know, or does the road know? |  |

### II.e Belief, fear and superstition — `BL`

| ID | Question | Bears on |
| --- | --- | --- |
| BL1 | What does an ordinary villager believe a gate is? Is that belief correct? | GT1, GT3, BL2, FA10 |
| BL2 | What is the most widespread false belief in this world? |  |
| BL3 | What do people do for luck, and does any of it work? |  |
| BL4 | Is there a bogeyman — the thing told to children? |  |
| BL5 | What is the most feared way to die here, and is it the most common? |  |
| BL6 | Do people believe the world is getting worse, better, or going around in a circle? | HS2, HS8, GT4 |
| BL7 | Is despair organised? Are there cults, doomsayers, people who welcome the gates? |  |
| BL8 | What do people think the Tower is? Do they think about it at all, or is it weather? |  |
| BL9 | Is there an idea in this world so obvious nobody states it, that would be shocking to us? |  |
| BL10 | What makes a person in this world feel safe? Not *be* safe — feel it. |  |

### II.f Perspective and the watching layer — `SF`

| ID | Question | Bears on |
| --- | --- | --- |
| SF1 | Does the player character know they are unusual? (repo: D14 — the run continues when companions die and ends when you do. Is that a fact about the world or about the game?) | SM5, SF3, FR7 |
| SF2 | The **Masquerade** is deferred but seamed in. Is there something being hidden, and from whom — the public, the player, or the characters? |  |
| SF3 | Is anyone watching the player's run from inside the fiction? (The lineage names _Omniscient Reader's Viewpoint_ as an influence.) |  |
| SF4 | Do characters know about levels, classes, doctrine, ranks — is the game's vocabulary the world's vocabulary? | SF5, SF6, SM9, PW5 |
| SF5 | The player *chooses* a class at level 2 and NPCs settle into one. Does a person in this world experience that as a choice, a discovery, or a diagnosis? |  |
| SF6 | Does anyone in the world understand the step-clock — that walking is what moves things? |  |
| SF7 | Is there prophecy or fate? (repo: `fate.json` exists.) If so, is it accurate, and does knowing it change it? | BL3, FR3, SM10 |
| SF8 | Does the world have a sense of humour about itself? |  |

---

## Part III — Cultural

### III.a Rule, faction and power — `RU`

| ID | Question | Bears on |
| --- | --- | --- |
| RU1 | Nine of ten factions are hostile; only the **Freeholds** are not. Is that the world's actual politics, or the view from the road? |  |
| RU2 | **The Heart Empire "came up the road one spring and never named a reason." What is the reason?** Do they know it themselves? | RU3, RU4, RU13, HS6, GT3 |
| RU3 | Is the Heart Empire a state, a religion, an army, or an infection? What happens to a village it takes? |  |
| RU4 | Rank is read off the metal — copper at the gate, white at the throne. **Is there a throne, and is anyone on it?** | RU3, RU13, FR4 |
| RU5 | What are the **Freeholds** — a federation, a habit, a word for everyone unaligned? Who speaks for them? | RU9, RU10, EC4, LW9 |
| RU6 | The **Bamboo Court** took its students from the beasts "when no people were left worth teaching." What happened to the people? |  |
| RU7 | The **Broken Oath** — whose oath, to whom, and is the breaking recent enough to still hurt? |  |
| RU8 | **The Tide**, **The Dusk**, **The Ember Wilds**, **The Wild**: which of these are peoples, which are places, and which are conditions? |  |
| RU9 | What is the largest thing that can be called a government here? Does any authority reach further than a day's ride? | RU10, RU13, LW1, LW9, EC7 |
| RU10 | Who protects a village, actually? If a village has forty people and a gate opens nearby, who comes? |  |
| RU11 | Is there a war on right now, and would an ordinary person know? |  |
| RU12 | Who was in charge a hundred years ago, and how did that end? |  |
| RU13 | **What happened to kings?** The game is called _Earth Kings_ and the factions are legions, courts, tides and wilds. Is kingship dead, ongoing, or the thing being competed for? | FR4, RU9, RU12, HS2 |

### III.b Law, justice and violence — `LW`

| ID | Question | Bears on |
| --- | --- | --- |
| LW1 | Is killing a crime here? When, where, and who enforces it? | LW2, LW4, LW8, RU9 |
| LW2 | The player can **raid a town** — fight its people, empty its strongbox. Is that a crime, an act of war, or a thing that just happens on a frontier? |  |
| LW3 | Is there such a thing as a trial? Who judges? (repo: the investigation docs reference a "Third Judge" — is that in-world or a documentation device?) |  |
| LW4 | What are the punishments? Fines, exile, branding, work, death? |  |
| LW5 | Captives are ransomed at a price, on a deadline, and may be **sold** if the deadline lapses. **Sold to whom, for what work?** Is slavery legal, normal, or hidden? | EC10, EC11, LW1, OT3, DV8 |
| LW6 | Is there a law of hospitality — a rule about the road, the hearth, the guest? What does breaking it cost? |  |
| LW7 | Do oaths bind legally, religiously, or only personally? (Several heroes are defined by sworn oaths and ancestral grudges.) | LW8, FA8, KI3 |
| LW8 | A **grudge** grants +10% damage against an ancestral foe. Is vengeance a recognised right here? Is there a feud culture, and does anyone try to end feuds? | LW7, HS7, NW8 |
| LW9 | Who owns land, and how is that recorded if news travels by foot? |  |
| LW10 | What is the worst thing a person can do in this world, in the eyes of ordinary people? |  |

### III.c Economy and gold — `EC`

| ID | Question | Bears on |
| --- | --- | --- |
| EC1 | **What is gold, and who mints it?** Is it coin, weight, or trust? Is there a face on it? | EC2, EC3, EC7, EC9 |
| EC2 | Is currency universal across all factions, or does the Heart Empire mint its own? |  |
| EC3 | What does an ordinary person earn in a year, expressed in the game's gold? This sets whether a 120-gold ransom is a fortune or a bar tab. | EC9, MK10, LW5, DV1, EC11 |
| EC4 | Who produces food, and who eats without producing it? |  |
| EC5 | Is there trade over distance? What moves — salt, iron, books, people? (repo: coastal ferries, trade routes that pay out on upkeep ticks.) | LN2, LN8, EC4, KN3 |
| EC6 | Is there debt, credit, lending? (repo: there is a thread called `the_debt`.) |  |
| EC7 | Is there tax, tribute, tithe? Who collects, and what happens if you don't pay? |  |
| EC8 | Who sells a party its weapons, and where did the smith get the steel? |  |
| EC9 | Delvers come home with gate-gold. Does that wreck local prices? Is a delver rich, or just liquid? | DV1, DV3, DV6, EC3 |
| EC10 | Is there anything money cannot buy here, and who enforces that? |  |
| EC11 | Beggars, orphans, the old — who is destitute in this world and what happens to them? |  |
| EC12 | Recruits cost gold and can be dismissed. Is companionship a contract, a wage, or a shared risk with a number on it? |  |

### III.d Kin, household and lifecycle — `KI`

| ID | Question | Bears on |
| --- | --- | --- |
| KI1 | What is a household — nuclear, extended, communal, chosen? | KI2, KI7, KI10, AR5 |
| KI2 | Who raises children, and to what age are they children? | KI5, KI6, KN2, KI7 |
| KI3 | Is marriage a thing? Who decides it, and can it end? |  |
| KI4 | Are gender roles fixed, loose, or invisible? Does anyone care who fights? |  |
| KI5 | Is there an initiation — a moment a person becomes an adult, and what is asked of them? |  |
| KI6 | Every one of the twelve heroes is an orphan, an exile, a stray or a cloistered scholar who left. **Is the rootless adventurer the norm, or is the game's cast a survivorship bias?** | KI1, KI2, DV1, DV5, HS7 |
| KI7 | What happens to the old? Who cares for someone who cannot work? |  |
| KI8 | Naming: family names, place names, earned names, titles? (repo: heroes carry titles like "The Sworn Blade", "The Hedge Priest".) |  |
| KI9 | How do people greet each other, and how do they part? Give one gesture or phrase. |  |
| KI10 | What is the most important relationship in an ordinary person's life, and is it family? |  |
| KI11 | **Home** is inviolable — nothing camps within sight of it, sleeping there always heals. Is that true of every home in the world, or only the player's? If every home, *why*? | MK11, BD3, AR1, AR2, SM7 |
| KI12 | Does anyone in the party have living family? Would the game be better or worse if they did? |  |

### III.e Faith and rite — `FA`

| ID | Question | Bears on |
| --- | --- | --- |
| FA1 | Are there gods? Do they act? Does anyone claim to have seen one? | FA2, FA3, FA7, FA9, BD5, BL3 |
| FA2 | Toln is a **hedge priest** who records "ancient chants" and left a monastery. **A priest of what?** | FA1, FA3, MK6, BD8 |
| FA3 | If there are temples, what happens inside them? Is it a service, a market, a school, a hospital? |  |
| FA4 | Is healing religious, technical, or the same thing? |  |
| FA5 | Is there a festival everyone keeps? What is it for, and what do people eat and do? |  |
| FA6 | Are there vows, fasts, pilgrimages? Is the Tower a pilgrimage? |  |
| FA7 | Do people pray before a fight, and to what? |  |
| FA8 | The **Training Yoke** is self-imposed handicap for growth. Is that an ascetic tradition with a name and a lineage, or a private trick? | LW7, PW6, FA6 |
| FA9 | Is there a heresy — a belief that gets you killed or driven out? |  |
| FA10 | Does religion say anything about gates? If the world's faiths predate the gates, how did they adapt? | GT3, GT4, BL1, HS4 |

### III.f Tongue and record — `TG`

| ID | Question | Bears on |
| --- | --- | --- |
| TG1 | Is there one language, several, or a trade tongue over many? | TG2, TG3, TG4, TG6, NW1 |
| TG2 | Can the party talk to everyone they meet? Has translation ever been a problem? (The lineage names "translated language" as a design-DNA resource.) |  |
| TG3 | Is there an older language — the one doctrine and the grammar are written in? | KN8, PW1, TG1 |
| TG4 | Do monsters have language? |  |
| TG5 | How do people date events with no eras and no central calendar — by season, by ruler, by disaster? | HS3, HS4, SK5, CL1, NW5 |
| TG6 | What is the naming style for places? Give three examples that sound right and one that would sound wrong. |  |
| TG7 | Are there written contracts, signs, notices? Can a village read a proclamation nailed to a post? |  |
| TG8 | What do people call delvers, gates, and monsters in everyday speech — the polite word and the real one? |  |
| TG9 | Is swearing religious, bodily, or about the gates? Give one oath a soldier would use. |  |
| TG10 | Is there a song everybody knows? |  |

### III.g Daily life — `DY`

| ID | Question | Bears on |
| --- | --- | --- |
| DY1 | Describe an ordinary day for a villager, dawn to dark, in three clauses. |  |
| DY2 | What do people drink, and where? (repo: there are alehouses, taphouses, serais and longhouses; you hire whoever is drinking there.) | DY3, DV4, EC5, NW1 |
| DY3 | What does an inn owe a traveller, and what does it charge? |  |
| DY4 | What do people wear — materials, colours, what marks status? |  |
| DY5 | How do people fight for fun? (repo: the **Coliseum** — cards, waves, bouts, wagers, free-for-alls. Whose institution is that?) | PW5, EC9, DV2 |
| DY6 | What games, music, and instruments exist? What does a party hear walking into a village? |  |
| DY7 | What is beautiful in this world? What would a person hang on a wall? |  |
| DY8 | What does a village smell like, and what does a keep smell like? |  |
| DY9 | How do people amuse themselves in winter? |  |
| DY10 | Is there art about the gates — songs, carvings, warnings? |  |
| DY11 | What does hospitality look like when the party walks in filthy and armed? |  |
| DY12 | What is the everyday sound of this world — the one under everything? |  |

### III.h Building and settlement — `AR`

| ID | Question | Bears on |
| --- | --- | --- |
| AR1 | Why is a village where it is — water, road, defensibility, a shut gate nobody talks about? | KI11, AR2, AR7, LN5 |
| AR2 | Is a village walled? What does it do at night? |  |
| AR3 | Who builds keeps, who lives in them, and are they garrisons or households? |  |
| AR4 | What are the **huts** out in open country — hermits, outposts, shrines, the last of a village? |  |
| AR5 | What is the material and silhouette of ordinary building — timber, stone, turf, stilt? (repo: there are stilt huts, cairn huts, orchard huts, pine longhouses, dune serais.) |  |
| AR6 | What does a library look like from outside? Is it fortified? |  |
| AR7 | How does a settlement change after a gate near it is shut? After one near it breaks? | GT6, GT7, LF9, AR1 |
| AR8 | What is a **ruin** in this world — old war, old gate, old people, or something that was never finished? | HS1, HS2, MK9, HS9 |

### III.i Outsiders and the monstrous — `OT`

| ID | Question | Bears on |
| --- | --- | --- |
| OT1 | Is there any peace between people and gate-things, anywhere, ever? | LF5, OT2, OT8, GT1 |
| OT2 | Do any people side with the gates deliberately, and what do they get? |  |
| OT3 | Is there a people everyone else despises? On what grounds? |  |
| OT4 | Are the Bamboo Court's beasts considered people by anyone but themselves? | LF2, MN2, OT3 |
| OT5 | What happens to someone who comes back from a gate changed? |  |
| OT6 | Can something from a gate pass as a person? | LF4, OT5, BL4 |
| OT7 | Is a monster's death mourned by anything? |  |
| OT8 | Do the factions ally against gates, or does the gate crisis fail to unite anyone? |  |
| OT9 | What is the most human thing a monster does? |  |
| OT10 | What is the most monstrous thing a person does, routinely, without comment? |  |

### III.j The delver as a social class — `DV`

| ID | Question | Bears on |
| --- | --- | --- |
| DV1 | **Is delving a job?** Is there a word for it, and do parents want it for their children? | DV2, DV4, DV5, KI6, EC9 |
| DV2 | Is there any organisation of delvers — a guild, a register, a board with prices, or just people who left? |  |
| DV3 | Who pays for a gate to be shut? Does anyone, or is the gold simply inside? | EC9, GT15, RU10, DV2 |
| DV4 | What do villagers think when four armed strangers walk in — relief, dread, business? |  |
| DV5 | How many delvers are there in the whole world — dozens, thousands? | DV1, DV9, PW5 |
| DV6 | What happens to a delver who gets old, or who quits at thirty with money? |  |
| DV7 | Is there a code among delvers, and what is the unforgivable breach of it? |  |
| DV8 | Is a captive delver worth more alive than dead to everyone, or only to raiders? |  |
| DV9 | Are the twelve heroes famous, or twelve people among many? |  |
| DV10 | Does the world have a word for what happens when a party comes back one short? |  |

### III.k History and ruin — `HS`

| ID | Question | Bears on |
| --- | --- | --- |
| HS1 | What is the single biggest thing that has happened in this world's past, and how long ago? | HS2, HS4, HS6, AR8, GT14 |
| HS2 | Was there a fall? Were things better once, and does the evidence agree with the belief? | HS1, AR8, BL6, RU12 |
| HS3 | How far back does reliable memory go — three generations, thirty, none? |  |
| HS4 | Is the gates' arrival dated? Is there a "before"? | GT4, HS2, HS3, FA10 |
| HS5 | Name one historical figure everyone has heard of and one nobody has. |  |
| HS6 | What was the last thing that changed the whole world, and who noticed at the time? |  |
| HS7 | Are the twelve heroes' origins — dead forge-masters, raided borderlands, war creeping past a monastery — one war or many? |  |
| HS8 | Is the world's story going somewhere? If the player never existed, what would the next fifty years be? | GT8, GT15, SM5, BL6 |
| HS9 | What is the oldest continuously inhabited place? |  |
| HS10 | What does this world think it is *owed*? |  |

---

## Part IV — Seams

Where the mechanics and the world scrape against each other. These are not lore questions; they
are "what do we do about it" questions, and they are the ones that will actually cost work.

| ID | Question | Bears on |
| --- | --- | --- |
| SM1 | **Save-scumming is allowed** (D21) and permadeath is a pillar. Is reloading a fact about the world, a fact about the player, or a hole we agree never to look at? | SM2, FR7, BD6 |
| SM2 | Difficulty settings change enemy strength, grace odds and **whether permadeath exists at all**. Are these different worlds, or the same world at different volumes? Should Gentle be told to the player as mercy or as a different fiction? | SM1, BD2, FR7 |
| SM3 | `Q` hands the run to the AI and it plays itself — walking, fighting, answering its own conversations. Is autoplay *anything* in the fiction, or purely a tool? |  |
| SM4 | Two-player is passing the pad (D10). Since two of you are building this — is the second player a second character, a second run, or a person looking over a shoulder? Does the world need to support two at all? |  |
| SM5 | The run ends when the player character dies but the world is saved. Is the next run the **same world** later, a different one, or a reset? This is the biggest open question in the project. | SM6, SF1, HS8, FR7 |
| SM6 | D25 lets a victor enshrine the run in a **Museum**. What is the Museum — a place in the world, a menu, or a memorial the next run can walk into? |  |
| SM7 | The party heals fully at a village and permanently at home. Does the world's danger survive a mechanic that makes recovery free? |  |
| SM8 | Companions are hired for gold and dismissed at will, and D14 says the story continues when they die. **How do we make a hire matter** — is it fiction's job, mechanics' job, or accepted as a cost of the design? | KI10, EC12, DV10 |
| SM9 | Word spreads at a tile per 14 steps, but the player sees a HUD. How much should the interface know that the character does not? |  |
| SM10 | Threads happen *to* the player and are never shown (Q14). If neither of you can explain a thread to a stranger afterwards, did it happen? |  |
| SM11 | LLM minds are deferred (D03). If they land, what is the **one thing** an NPC must never say or do without asking us first? | MN8, SF2 |
| SM12 | Name the mechanic you would cut tomorrow if the world demanded it, and the piece of world you would cut to keep a mechanic. |  |

---

## Part V — Boundaries

Answer these **first**, with Part 0, before anything else. They set the fence.

| ID | Question | Bears on |
| --- | --- | --- |
| BN1 | Name one thing that must **never** be true of this world. | FR1, BN3, BN6 |
| BN2 | Name one thing you want in it so badly you would trade three other features for it. |  |
| BN3 | What tone would make you stop working on this — grimdark, cute, ironic, preachy? |  |
| BN4 | Is there subject matter that is off the table entirely? |  |
| BN5 | Which of the six design pillars in [01 — Vision](01-vision.md) would you defend last? Which would you drop first? | FR1, FR9, BN2 |
| BN6 | What are you afraid this game will turn into? |  |
| BN7 | If the other person's world won every disagreement, would you still want to build it? Be honest — this is the question that decides how the ledger gets used. |  |
| BN8 | Three words for the finished thing. |  |

---

## Part VI — The Sixteen

Fourteen questions, asked once each about all sixteen characters. A slot is written `CH7@INTJ`;
out loud, "for the INTJ one, the thing they want is…". Answer a whole character at a time, or
answer one question across several characters — both work.

The temper is the seed, not the answer. **A character has to be a person who happens to read that
way**, never a personality type wearing a name. Their five history fields — background, grudge,
hearth, creed, oath — are deliberately not here: those are authored separately and cast late
(Part VII).

| ID | Question | Bears on |
| --- | --- | --- |
| CH1 | What is their name, and what do people who dislike them call them? | CH8, TG6 |
| CH2 | What do they want badly enough to walk into a gate for? | CH3, CH5, CH12 |
| CH3 | What are they afraid of, that they would not say out loud? | CH2, CH11 |
| CH4 | What are they good at that has nothing to do with fighting? | MK1, DY7 |
| CH5 | What do they refuse to do, even when it costs the company? | CH2, CH9, BN1 |
| CH6 | Show me their temper in one action — a thing they do that no other character here would. | CH5, CH11 |
| CH7 | How do they behave in the first hour after somebody dies? | BD8, CH11, SM8 |
| CH8 | What do they look like, in one image that is not a list of features? | CH1, DY4 |
| CH9 | Who in the other fifteen would they not travel with, and why? | CH5, CH10, LP26 |
| CH10 | Who in the other fifteen do they already know, and how? | CH9, LP21, LP22 |
| CH11 | What is the one line of theirs a player would still quote after the run ends? | CH6, CH3 |
| CH12 | What would make them stop — quit the road entirely and go home? | CH2, DV6 |
| CH13 | Which of the six classes suits them, and which would be the interesting wrong choice? | SF5, CH4 |
| CH14 | If they are not the lead this run, where are they standing, and what are they doing there? | LP28, MX16, MX17 |

### Who is written

Mark a cell when that question is answered for that character. `--report=questions` regenerates it.

| Temper | Name | CH1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 | 13 | 14 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| INTJ | The Long Plan |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| INTP | The Open Question |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ENTJ | The Marshal |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ENTP | The Contrary |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| INFJ | The Quiet Cause |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| INFP | The Kept Flame |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ENFJ | The Gatherer |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ENFP | The Spark |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ISTJ | The Ledger |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ISFJ | The Keeper |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ESTJ | The Straight Road |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ESFJ | The Full Table |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ISTP | The Steady Hand |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ISFP | The Own Path |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ESTP | The First Move |  |  |  |  |  |  |  |  |  |  |  |  |  |  |
| ESFP | The Bright Hour |  |  |  |  |  |  |  |  |  |  |  |  |  |  |

---

## Part VII — Pools & casting

The five pools in `data/lore/` are authored with no character in mind and attached late. These
decide what a piece of history *is* before any of them are written. See
[14 — Lore Pools](14-lore-pools.md).

| ID | Question | Bears on |
| --- | --- | --- |
| LP1 | How long is a background — a sentence, a paragraph, a page? | LP2, LP3 |
| LP2 | Is a background a **place**, an **event**, or a **relationship**? Can it be all three? | LP1, LP4 |
| LP3 | How many backgrounds should exist before we cast any? Twenty? Forty? | LP29, LP30 |
| LP4 | Should two characters ever share a background, or is each one used once? | LP3, LP30 |
| LP5 | **May a background grant a book?** It collides with pillar 2 — the Library is somewhere you walk to — and library shelves stock from the same pool. Currently allowed by the vocabulary, unused by every entry. | KN1, KN5, LP6 |
| LP6 | What is the largest thing a gift may be? A blade is 90 gold; is that the ceiling or the floor? | EC3, MK10, LP5 |
| LP7 | Should every background carry a gift, or are some just history? | LP6, LP1 |
| LP8 | The tag vocabulary is shared across all five pools. What are the right tags — and how many? | LP9, LP26 |
| LP9 | Are tags for casting only, or should the game read them at runtime? | LP8, MX22 |
| LP10 | What is a grudge against something that cannot be fought — a season, a debt, a dead person? | LW8, LP11 |
| LP11 | Can two characters carry the same grudge and mean completely different things by it? | LP10, LP4 |
| LP12 | Should a grudge ever be **wrong** — aimed at someone who did not do it? | LP10, NW3, BL2 |
| LP13 | Is a hearth a specific named place, or a kind of place? | AR1, LN6, LP14 |
| LP14 | Can two characters be from the same hearth, and does that make them know each other? | LP13, CH10, LP21 |
| LP15 | Does a hearth still exist when the run starts, or can you be from somewhere that is gone? | LP13, AR7, GT7 |
| LP16 | Creeds hold and despise values from a shared list. What are the right values beyond order, freedom, mercy and ruin? | LP17, FA1 |
| LP17 | Should a creed be a named movement other people follow, or one person's private conviction? | LP16, FA9, RU5 |
| LP18 | Can a character's creed change during a run? | LP17, KN1 |
| LP19 | Is a creed ever a **lie** — what they say they believe versus what they do? | LP17, LP12 |
| LP20 | What is an oath in this world — binding legally, religiously, or only personally? | LW7, FA8, LP21 |
| LP21 | Should every oath name another one of the sixteen, or can one be sworn to a place, a dead person, an idea? | LP20, CH10, LP22 |
| LP22 | If A's oath names B, does B need a matching entry, or can an oath be one-sided and unknown to its object? | LP21, CH9, CH10 |
| LP23 | Can an oath be **broken** in play, and what happens mechanically when it is? | LP20, LW7, MX19 |
| LP24 | Do the uncast pieces really become rumours and NPC histories, or is that a comfortable thing we tell ourselves? | LP30, NW1 |
| LP25 | When two pieces fit one character equally well, what breaks the tie? | LP26, LP30 |
| LP26 | Should casting avoid giving one character a matched set — forge background, forge hearth, forge grudge — or is coherence the point? | LP8, LP25 |
| LP27 | Does the player ever see a character's full history, or only what comes up? | SF4, MX14 |
| LP28 | Do the fifteen you did not become carry their history visibly — does meeting them tell you any of it? | CH14, LP27, MX17 |
| LP29 | Which pool do we write first, and why that one? | LP3, LP30 |
| LP30 | When is a pool **finished**? | LP3, LP25 |

---

## Part VIII — Mechanics left open

What this build decided provisionally and left for you. Every one of these is currently a number
or a stub in `data/`, working but unargued.

| ID | Question | Bears on |
| --- | --- | --- |
| MX1 | The four quiz questions are drafts. Do they sound like this world, or like a personality test? | MX2, MX3, FR6 |
| MX2 | Should a quiz answer ever be **neither** — a third option, or a refusal? | MX1, MX3 |
| MX3 | Should the player be told the four letters at all, or only the in-world name? | SF4, MX1 |
| MX4 | Can a player re-roll the quiz, or is the first answer the one they live with? | SM1, MX5 |
| MX5 | "Show me all sixteen" currently bypasses the quiz entirely. Is that an escape hatch or a dev tool that should not ship? | MX4, MX1 |
| MX6 | Are the eight lean values right? E −15% on hires, I 1125-step fade, S ×1.25 proficiency, N ×1.25 codex, T +5% damage, F +4pp rescue, J +20 CT, P +1 move. | MX7, MX8 |
| MX7 | Is +1 move (P) far stronger than +5% damage (T)? Should the budget be equal, or is asymmetry the point? | MX6, MX8 |
| MX8 | Should a lean ever be a **drawback** as well as a bonus? | MX6, MX7 |
| MX9 | Does the player's temper affect anything outside combat and bonds — what NPCs say, what options appear? | SF4, MX10, MX17 |
| MX10 | Do the other fifteen use their own leans when they are in your party? | MX6, MX9 |
| MX11 | **Is the next run the same world, later?** The biggest open question in the project. | SM5, HS8, MX12 |
| MX12 | What is the Museum — a place in the world, a menu, or a memorial the next run can walk into? | SM6, MX11, GT12 |
| MX13 | Does anything at all carry between runs, and if so is that a betrayal of pillar 4? | MX11, MX12, SM1 |
| MX14 | Does the party screen show a character's background and creed, or do you learn it by travelling with them? | LP27, SF4 |
| MX15 | Sixteen characters share five site kinds to start on. Should hearths be spread further, or is doubling up fine? | LP13, LP14, MX16 |
| MX16 | Where exactly does each of the fifteen stand when they are not the lead — a fixed area, or somewhere that moves? | CH14, LP28, MX17 |
| MX17 | How does hiring one of the fifteen work — a price, a favour, a condition, a refusal? | MX16, EC12, SM8 |
| MX18 | Should a named hero refuse to join based on creed, or does gold always work? | MX17, LP16, SM8 |
| MX19 | If you hire someone and they die, is that different from a nameless recruit dying? | SM8, BD8, LP23 |
| MX20 | Can you meet a character whose temper you rolled — is there a version of you walking around? | MX11, SF1, SF2 |
| MX21 | Two-player is passing the pad. Does the second player get their own character, their own run, or neither? | SM4, MX11 |
| MX22 | Should the difficulty settings change the **fiction**, or only the numbers? | SM2, MX6 |
| MX23 | Gifts are applied once at creation. Should any of them be visible to the player as "this is why you have this"? | LP7, MX14 |
| MX24 | Does the Codex ever tell the player what the grammar *is*, or only how much of it is catalogued? | PW8, PW10, FR8 |
| MX25 | What is the first thing a new player should understand within ten minutes, and does the current opening teach it? | FR9, MX1, SF4 |

---

## Part IX — Carried over

Still open elsewhere in the docs, pulled in so there is one list. Each keeps a pointer home.

| ID | Question | Bears on |
| --- | --- | --- |
| CO1 | **What does the voice say?** [W2](09-wishlist.md) — the memo cut off before giving the line at the end of the cinematic. Still the only thing blocking it. | FR7, MX25 |
| CO2 | [W11](09-wishlist.md) / [W28](09-wishlist.md) — 68 units have no run cycle. Which matter enough to commission, and which can stand still forever? | CH8, MX25 |
| CO3 | [W23](09-wishlist.md) — boats connect coastal ports, but there is no separate archipelago. Is there other land across the water? | LN2, LN3 |
| CO4 | [W25](09-wishlist.md) — no named bosses outside the Tower. Should there be, and are they people or things? | LF12, GT12, OT9 |
| CO5 | [W25](09-wishlist.md) — what is a "mission" here, as distinct from an errand and a thread? | SM10, CO4 |
| CO6 | [W29](09-wishlist.md) — the UI pass was never done as a pass. What should the readouts actually say? | SF4, SM9, MX14 |
| CO7 | [D21](06-decisions.md) — save-scumming was allowed "to be revisited". Revisit it. | SM1, MX4, MX13 |
| CO8 | [D16](06-decisions.md) / [D25](06-decisions.md) — the Tower ends in a victory at the Spire Apex. Is that the end of the *game*, or just of the Tower? | MX11, MX12, HS8 |
| CO9 | The twelve original heroes are superseded but still playable. Do they stay as NPCs, get retired, or get rewritten into the sixteen? | CH10, LP24, MX16 |
