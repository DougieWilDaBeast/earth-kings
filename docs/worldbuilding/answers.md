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

Run `res://tools/question_report.tscn` for the live count. On 2026-10-13 it reads **85 of 366
answered, 165 still open, 143 drafts across 129 questions**.

**The standing instruction** from that session: a question that does not matter yet stays open.
Section 1 is what the next milestone cannot start without. Everything below it is real, but it can
wait for a session that has nothing more urgent.

**For the next session:** [the briefing sheet](session-2-briefing.md) gives every Section 1 item
its options, what each costs to build, and what happens if nobody answers. Joint session 2
(2026-10-01) worked it as far as item 8 and stopped. Items 9 to 19 and the new rows 20 to 24 are
what is left, with 25 to 29: what the build inferred on 2026-10-12 to get M13's fall running, and 50 to 56: what it inferred the same day to get M15's sixteen worlds running. Since then: 57 to 62,
raised by `doug-md`'s answers on 2026-10-12, and 63 to 70, what the build inferred on 2026-10-12 and
13 (the real-time fight everywhere, growth you can see, the Amber Knight, the fight's sounds, the
quieter level-up, the sixteen classes, the sixteen as leads, the twelve in the world). Then 71 to 78, built on 2026-10-13 and 14 (the effects, the signatures, one land, the walls, the one world, the compass), and 79 to 86, what the
build inferred on 2026-10-14 and 15 to get the First Hour playing ([28](../28-the-first-hour.md)), and 87 to 98, what it
inferred on 2026-10-15 and 16 (the keeper, the lands, the Tower, the route's people, the crossing, the store page, the lights,
Auto, Sennet, gate fights, phones). **On 2026-10-16** the rows only a founder can settle were put to them as
twenty-four questions to answer by voice note: [30](../30-questions-for-the-founders.md); question 24 asks them to keep
rows 79 to 98 at once, naming any exceptions.

## 1. What joint session 1 left open — needed next

Every item here blocks something on the [roadmap](../05-roadmap.md). Most are one sentence each.

| #  | Where | The question |
| -- | ----- | ------------ |
| 1  | `GT11`, `D16` | ~~**How many floors has the Tower, and how many make a chapter?**~~ **Settled 2026-10-01 in joint session 2:** a hundred floors, twenty chapters of five. Built. See `GT11`, [D48](../06-decisions.md). |
| 2  | pillar 5, `SK6`, `D27` | ~~**Does the world still run on steps?**~~ **Settled 2026-10-01 in joint session 2:** no. The world moves on at milestones, with no time pressure. Not built yet. See `SK6`, [D49](../06-decisions.md), and item 20. |
| 3  | `D36` | ~~**The fight.** The move to a Dungeon Settlers-style real-time-with-pause fight was agreed, and a research deep dive was asked for before anything is built. What it has to answer is in [18 — Combat direction](../18-combat-direction.md#what-the-research-has-to-answer). **First pass done** — [investigation/07](../investigation/07-dungeon-settlers-combat.md) — and **a playable prototype built** (Training → Fight in real time, [18](../18-combat-direction.md#the-fight)). What is left is playing both.~~ **Settled 2026-10-12: real time.** `doug-md` chose it after playing both ([D58](../06-decisions.md)); `dougie` agreed in writing ([transcript](voice-notes/2026-10-12-dougie-chat.md)): "Realtime fights". M11 replaces the turn loop. See [D63](../06-decisions.md). |
| 4  | `CO7`, `SM1`, `D21` | ~~**Can a death be reloaded?**~~ **Settled 2026-10-01 in joint session 2:** it depends on the mode. Classic reloads, or ascends to heaven and picks a new character. Iron Man has one life. See `CO7`, [D51](../06-decisions.md). |
| 5  | `MX20` | ~~**In the second world, is there a living copy of the first lead?**~~ **Settled 2026-10-01 in joint session 2:** yes, as an NPC built from their stats and personality. See `MX20`, [D52](../06-decisions.md). |
| 6  | `CH10`, `SF1` | ~~**What does a lead remember?**~~ **Settled 2026-10-01 in joint session 2:** the fall takes the memory. It comes back in fragments, one set per Tower chapter, and every lead carries the quest "Ascend to heaven". See `SF1`, [D53](../06-decisions.md). Whether a lead half-knows the others' faces is still open (`CH10`). |
| 7  | `D29`, `D44` | ~~**Is the lead chosen or answered for?** The session says "you choose Cassius"; the build asks four questions and names you. Both can stand — the quiz names you, _Show me all sixteen_ lets you choose — but say which is the front door.~~ **Settled 2026-09-26 by `dougie`, in writing:** the quiz is the front door, and the roster is a side door that opens only after it, next to answering again. See `MX4`, `MX5`. |
| 8  | `D37` | ~~**Assists. One number, or two?**~~ **Settled 2026-10-01 in joint session 2:** two. Ten assists, or five for a healer's. Built. See [D54](../06-decisions.md) and item 23. |
| 9  | `CO2` | ~~**Sprite size — 64, 32 or 16?** "that's still an open for now, but we do need to generate stuff" [01:07:40]. PixelLab credits reset on 2026-09-27 with 15% left; the [asset list](../19-asset-list.md) has to be generated at one size. The model game measures in the **32 class** ([investigation/07](../investigation/07-dungeon-settlers-combat.md#13-sprite-size-and-frame-counts)).~~ **Handed to Claude 2026-10-12 by `dougie`, in writing:** the 64 class, every unit dressed onto the founders' blank base body. **Confirmed by `doug-md` on 2026-10-12**, with big units drawn taller and one blended look ([D57](../06-decisions.md)). **Settled 2026-10-12: `dougie` confirmed it too**, in writing ([transcript](voice-notes/2026-10-12-dougie-chat.md)): "Yes I also confirm the 64 bit size." See [D55](../06-decisions.md), [D63](../06-decisions.md). |
| 10 | `CH13` | ~~**Sixteen ways to fight, six classes.** The roster needs sixteen distinct fighting styles; `classes.json` has six. More classes, or a class per character, or styles inside classes?~~ **Settled 2026-10-12 by `dougie`, in writing** ([transcript](voice-notes/2026-10-12-dougie-chat.md)): "Every starting character gets their own class." A class per character: sixteen classes, one for each of the sixteen. Not built yet. A lead may still switch class at level 2, their own class the natural fit ("Yes to all 3 questions", [D64](../06-decisions.md)). See `CH13`, [D63](../06-decisions.md). `doug-md` also answered the same day ([transcript](voice-notes/2026-10-12-doug-md-chat.md#step-4-batch-1--the-follow-ups-d89)): several styles inside each class, picked at level 2 with the class from three cards, and a style played for a while levels up too ([D90](../06-decisions.md)). Recorded 2026-10-14; whether styles sit inside the sixteen classes is item 77. |
| 11 | `D38` | **How does the party grow from four to six?** A level, a rank, a Tower chapter, something bought? **Built 2026-10-12 on an inference** — by Tower chapter; see item 35. **`doug-md` answered 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md)): "The party should grow up to, I'm going to say, six people", which the build already does; later, a guild you command, whose own adventuring party goes out on objectives as a sub-team (item 59). Waits on `doug-md`. See [D60](../06-decisions.md). |
| 12 | `MX13` | **Where does a dead lead's weapon land the first time** — somewhere easy to find, or random? Built meanwhile as easy to find, **Inferred** (item 53). **`doug-md` answered 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md)): "I kind of want it to be random, but also you might hear rumors about this weapon landing". **Built** the same day: anywhere the company can walk, five or more tiles off, and the rumour says which way. The cinematic, the ground marked by the weapon and a monster picking it up are item 58. Waits on `doug-md`. See [D60](../06-decisions.md). |
| 13 | `GT2`, M5 | **You cannot leave a gate until it is beaten.** ~~The build lets a party retreat and keep the floors taken.~~ **Built 2026-09-24:** once a floor is won, every step is the next floor. Say so if that was not what you meant. |
| 14 | `GT3` | **Timed events.** `doug-md` asked whether failing to do things in time costs you. `dougie`: "we should try to test what happens when we're playing first". Deferred to playtest, on purpose. |
| 15 | `LP13`, `LP2` | **What is a hearth, or a background, for someone who fell from the sky?** The sixteen are not from this world, and they land at random. The reading taken in [14](../14-lore-pools.md#what-joint-session-1-changed): a hearth becomes the crash site, and a background is the life above, found out in pieces. Confirm or replace before any pool is written. |
| 16 | `GT3`, D45 | **Inferred.** Built 2026-10-01: **every gate has an objective** — rout, slay the keeper, or reach the heart — fixed by where it stands, no timers. Are those the right kinds? |
| 17 | `OT8`, D46 | **Inferred.** Built 2026-10-01: **an S-rank gate raises a Guild muster** that goes in beside the company, and **goes in alone** if nobody from the company stands with it, winning or losing on its strength. Is that what happens if you never come? |
| 18 | `MX4`, D47 | **Inferred.** Built 2026-10-01: **the fallen are remembered outside the save**, and the record is wiped only once every lead has fallen. When should the slate be wiped? |
| 19 | `DV2` | **Inferred.** Built 2026-10-01: **the Adventurers Guild keeps a hall in every standing keep and village**, never huts, with a clerk inside. Right places? |
| 20 | `SK6`, D49 | **What are the milestones?** Joint session 2 retired the step clock: "we're going to set up some other checkpoints as well". Tower chapters are one. Name the others, then say what each step-priced clock becomes: doctrine fading (`KN1`), gates breaking when neglected (`GT6`, D15), captive deadlines (D18), thread deadlines (D23), the seasons (`CL2`), companions' travel on jobs. "No time pressure" sits hardest against D15. **`doug-md` answered 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md)): the world comes alive as objectives are completed, things happen "whenever they should take place", a gate breaks when "all of the objectives align", and a deadline can be "seven days travel" with someone dead or another company done if you miss it; and "have a look at very prominent games like Baldur's Gate Witcher 3 Skyrim". The research and a proposal (days spent by resting and travelling; milestones; conditions; missing a deadline is a story) are in [investigation/08](../investigation/08-quests-and-a-living-world.md), **Inferred**, item 57. Waits on `doug-md`. See [D60](../06-decisions.md). |
| 21 | D50 | **One view: how far is a walk?** The planar view becomes the whole game and the world view becomes a map. Today a planar area is 30 by 20 and the continent is 128 tiles across, each of which opens an area of its own. Is the continent smaller, are areas bigger, or is there a faster way to travel? And does a guild's map show places, or only "the general area"? **`doug-md` answered 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md)): most of the game is the planar view; the world view becomes a map you toggle to see where you are; planar areas are too alike ("the same sort of layout, the four different exits") and need variety; and faster travel by **carriage**, paid in copper, silver or gold, part of the way, with attacks and other events on the road (item 60). Whether a map shows places or "the general area" was not answered. Waits on `doug-md`. See [D60](../06-decisions.md). **`doug-md` answered the map half 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md#step-4-batch-1--the-follow-ups-d89)): you see the general area of places; the lead jots down on the map what they have seen and roughly where a rumour points; the full map only once all of it is discovered. Recorded 2026-10-14. Waits on `dougie`. See [D89](../06-decisions.md). |
| 22 | `SF1`, `CO7` | **"Ascend to heaven" names two things.** It is the lead's standing quest, finished only at the end, and it is also what Classic offers when the lead dies. Is dying a way of finishing the quest, a failure of it, or are the two different things that happen to share a name? **`dougie` answered 2026-10-16** ([transcript](voice-notes/2026-10-16-dougie-founders-questions-part-1.md)): one word on purpose; Ascend at death is a false ascension that never finishes the quest, the true one is floor 100 ([D170](../06-decisions.md)). **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): two different things, which fits the false ascension. Settled by both. |
| 23 | D54 | **Inferred.** Built 2026-10-01: **a healer's assist** is one where the helper healed the one who landed the blow, earlier in the same fight. Five of those, or ten of any other assist, teach a kind. Right reading? |
| 24 | `GT11`, D48 | **Inferred.** Built 2026-10-01: over a hundred floors, **enemies rise about one level every three floors** (level 2 at the foot, 32 at the top), four faction cohorts hold the floors in turn, gold is paid by the chapter, a book every chapter and a skill tree every two. Right shape? |
| 25 | `LP13`, `MX15`, D31 | **Inferred.** Built 2026-10-12: **where the sixteen land.** Each crash site is drawn from the world seed and the hero, not the world's dice: open ground joined by land to the Tower, at least 24 tiles from it, 3 from any place and 6 from an open gate, and within 26 of a village, keep or hut. The lead's crater becomes the company's Home, called "Where You Fell", and a hearth no longer picks where a run starts (item 15's reading). Right rules? Should it be allowed to land anywhere, a bad part of the country included? |
| 26 | `MX16`, D31 | ~~**Inferred.** Built 2026-10-12: until the sixteen are written, **the twelve existing heroes stand in for the others**, each with an inferred temper: Bram ISTJ, Sera ISFP, Toln ISFJ, the Fox Fire Knight ESTP, the Village Idiot ESFP, Dirte ENTJ, the Bamboo Master INFJ, the Three-Eyed Smith ISTP, the Eightfold Monk INTP, the Tidewalker INFP, the Sleepless Blade INTJ, the Tattered One ENTP. Whoever a run starts with is not out there. Keep the stand-ins until the sixteen exist?~~ **Superseded 2026-10-13 by `dougie`:** the sixteen are the leads and the twelve are story people met in the world ([D78](../06-decisions.md), [D79](../06-decisions.md)); nobody stands in any more. What the sixteen and the twelve became is items 69 and 70. |
| 27 | `MX16`, `CH14` | **Inferred.** Built 2026-10-12: **the others move by temper.** NT go mostly to libraries and the Tower; NF to libraries, villages and huts, never gates; SJ to keeps and villages; SP to gates and keeps (the arena), never libraries. Nearer places are likelier. Each stays 60 to 180 steps, then walks on at two steps a tile. Right places? |
| 28 | `MX17`, `MX18`, `LP28` | **Inferred.** Built 2026-10-12: **meeting and joining.** Standing where one of them stands shows them and the mark, and **X** speaks to them. An Outward temper will join on the first meeting, an Inward one on the second, at the lead's level and only into a free place in the party of four. No price and no refusal by creed yet. Word of them comes from asking an inn for news, and sometimes from resting at a settlement. Is that how hiring one of the fifteen works? |
| 29 | `SF1`, D53 | **Inferred.** Built 2026-10-12: **"Ascend to heaven" as shown.** Every lead carries it from the landing beat, a short scene of narration written by the build. It sits in the journal (Quests & the Fallen) with the Tower's floor and chapter, and the Tower is marked ASCEND on the map. It never completes; what finishes it is item 22 and M17. Right wording, and right place to show it? |
| 30 | D50 | **Inferred.** Built 2026-10-12: **the map starts black** and the party sees **four tiles** round it at every step, continental or planar. The Tower is on the map from the start (seen from anywhere), and so is home. How far does a party see, and is anything known before it walks? |
| 31 | D50, item 21 | **Inferred.** Built 2026-10-12: **a Guild map shows places as well as the general area** — the lie of the land drawn dim for 18 tiles round the hall, and the five nearest places worth knowing marked (villages, then keeps, libraries, huts, gates). 50 gold, once per hall. This is the second half of item 21 answered by the build: places, or only "the general area"? |
| 32 | D50 | **Inferred.** Built 2026-10-12: **maps hidden in the world** are folded into finds — a chest in an area 25%, a cache in the open 40%, battle spoils and a town's loot 8% — and each draws in seven tiles round one place the party does not know of and marks it. Right odds, and right that a found map points at one place? |
| 33 | D50 | **Inferred.** Built 2026-10-12: **being told is knowing.** A Guild contract, an errand's destination and any place news at an inn names go on the map; a party walking itself goes after what it knows and, with nothing known, walks to the nearest ground it has not seen. Should being told mark the place exactly, or only roughly? |
| 35 | `D38`, item 11 | **Inferred.** Built 2026-10-12: **the party grows by Tower chapter.** Four seats to start; clearing chapter 1 (floor 5) opens a fifth, chapter 2 (floor 10) a sixth. A companion back from a job to a full company takes a new seat first. Right trigger, or should it be a level, a Guild rank or bought? |
| 40 | `CO7`, D51 | **Inferred.** Built 2026-10-12: **Classic and Iron Man.** The mode is picked with the lead (when was not said) and defaults to Classic. Classic saves by hand, and by itself on setting out, resting and closing a Tower chapter; Iron Man never by hand, and also on every return to the map and on leaving. Ascending lets the save go in both modes, since neither keeps that world playable. The modes leave the difficulty alone (Gentle and Breeze have no permadeath, so the lead never dies there). Right save points? |
| 45 | D36 | **Inferred.** Built 2026-10-12 in the real-time prototype: **passives and enemy roles**. A passive per class (Sworn Blade a damage-cutting aura, Longbow criticals, Hedge Priest a healing aura, Magic Swordsman a double strike, Raider lifesteal, Wildling a flank bonus) and a few for abilities known; enemies fight as Chargers, Skirmishers or Menders. All in `data/skirmish.json`. Which passives belong to whom, and are the roles right? See [18](../18-combat-direction.md#the-fight). |
| 46 | D36, D11, D65 | **Inferred.** Built 2026-10-12: **the graces are settled when the near-death window runs out** with nobody there. In a fight the world starts that is `Fate.resolve`, the same graces, capture and death as the turn-based fight had at the fall; a grace stands them back up at a quarter health. In training and the coliseum `Fate.roll` rolls them (no capture) and nothing is spent or written back. A companion reaching them first is still the sure way. Settled at the end of the window, or at the fall, or not at all in real time? See [18](../18-combat-direction.md#the-fight). |
| 50 | `MX11`, D32 | **Inferred.** Built 2026-10-12: **how alike the sibling worlds are.** Every world after the first is built on the first fallen world's seed, so the ground, every place and its name, and where each of the sixteen comes down are the same. Then a quarter of what the dice dealt is dealt again (which gates are already open, which books are on which shelves), and the world's own dice start from a new seed, so bands and the roadside do not repeat move for move. A seed typed on the picker is a world of its own and nothing comes through. How alike should they be? |
| 51 | `MX20`, D52 | **Inferred.** Built 2026-10-12: **where the earlier lead is.** Their copy in the next world waits at the settlement nearest where the new lead fell, for 400 steps, then walks on by temper like the others; the landing beat says the name is being talked about there. They are spoken to like any of the sixteen, with one more answer ("Have we met before?") in their temper's voice. If they join, they bring the calling and beliefs they started with, at the new lead's level. If the new lead's own companions include them, they are simply in the company. Right place to find them, and should they ever join? |
| 52 | `MX13`, D33 | **Inferred.** Built 2026-10-12: **"as far as the old one did"** is the old lead's level and the Tower floor they died on, both reached. Only then does their weapon come down and their ghost come to the fire, and only then does the census count them out. Right measure? **`dougie`, 2026-10-16** (row 101): the weapon comes when the new lead reaches the floor the old one did. |
| 53 | `MX13`, item 12 | ~~**Inferred.** Built 2026-10-12: until item 12 is answered, **the weapon lands somewhere easy to find**: open ground 5 to 12 tiles from where the new lead fell, the same spot for the same seed. Its fall is seen from wherever the company is, and inns and rests point at it, after which it is drawn on the map. Walking onto the crater picks it up. Easy, or random?~~ **Superseded 2026-10-12:** `doug-md` answered item 12 ([D60](../06-decisions.md)): the weapon lands anywhere the company can walk, and the rumour says which way. Built. |
| 54 | `BD7`, D33 | **Inferred.** Built 2026-10-12: **the ghost at the fire.** Every earlier lead whose news has arrived sits at any fire the company sits at (the camp after a rest, a hut, home), in a free seat. They answer how they fell, what went well, what they found, and where their weapon is. "What they found" is the journal of their run, a line per gate shut, person met, place stood in and enemy learned: an Outward temper shares three lines at first and an Inward one, one, two more every night after, and all of it once their weapon is found. No meditating yet: sitting down is enough. Right? |
| 55 | `MX13`, D33 | **Inferred.** Built 2026-10-12: **the twelve stand-ins' signature weapons**: Oathkeeper (Bram), Last Light (Sera), Vigil (Toln), Foxfire, the Fool's Sceptre, Crownbreaker (Dirte), Ten Thousand Days, First Anvil's Hammer, the Eightfold Edge, Undertow, Insomnia, Tatter. Each is attack 32 and defence 4 and suits nobody, not even the copy of its owner, so in anyone's hands it is worth about two-fifths of that. Never sold, never looted. Names, and how strong a god-tier weapon in the wrong hands should be? **Note 2026-10-13:** since [D78](../06-decisions.md) a lead is one of the sixteen, with the signature weapons of item 69; these twelve weapons are no longer a lead's. |
| 56 | `SM5`, D32 | **Inferred.** Built 2026-10-12: **the world ending, as shown.** Once the lead has ascended (Classic) or straight from the fall (Iron Man), the map is shown one last time: the camera rises over the whole of it while it burns out from the Tower to the sea, the lead's name is said over it, and it fades to black. The run is told after, then the next lead is chosen. Drawn from the existing map, no art of its own. Right order, and right look until the art exists? |
| 57 | D60, `SK6` | **Inferred.** Proposed 2026-10-12 from `doug-md`'s answer to item 20: **days as the clock, spent by resting and travelling; milestones and conditions move the world; a missed deadline is a story** ("too late" stages, a rival company done first). What each step-priced clock becomes is the table in [investigation/08](../investigation/08-quests-and-a-living-world.md#the-proposal--inferred-for-both-founders). Confirm or replace, then M18 can start. **`doug-md` confirmed the clock 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md#step-4-batch-1--the-follow-ups-d89)): "a day passes when you rest or travel"; an ordinary quest fits in a day, a journey to another region and back takes a few; a campfire is a **long rest**, and sitting in a carriage, eating, is a **short rest**. Recorded 2026-10-14. Waits on `dougie`. See [D89](../06-decisions.md). |
| 58 | D60, D33 | **The fallen weapon, shown.** `doug-md` 2026-10-12: a small cinematic of it falling and the impact; the ground around it marked by what it is ("if it's a flaming sword then the the area will have a little bit of flames around it"); and a monster can pick it up, using it at about 30% of its power. Planned, not built. Who picks it up, and how you get it back? |
| 59 | D38, M16 | **A guild you command, with a sub-team.** `doug-md` 2026-10-12: "further on in the line of development", your guild's own adventuring party goes out and does objectives for you, apart from your main party. M16 already sends companions on jobs; is the sub-team the same thing grown up, or a second party you also manage? Planned, not built. |
| 60 | D50, M18 | **Carriages and road events.** `doug-md` 2026-10-12: pay copper, silver or gold to ride part of the way; the road has ambushes that start a fight, and other events. The game counts only gold today: three coins, or gold priced in copper and silver words? Planned, not built. **`doug-md` answered the coins 2026-10-12** ([transcript](voice-notes/2026-10-12-doug-md-chat.md#step-4-batch-1--the-follow-ups-d89)): bronze, silver, gold and platinum, a hundred of each to the next, and asked for every price to be set again from scratch, for him to check: proposed in [26 — Coins and prices](../26-coins-and-prices.md), **Inferred**. Recorded 2026-10-14. Waits on `dougie`. See [D89](../06-decisions.md), [D90](../06-decisions.md). |
| 61 | — | **Foes who remember you.** `doug-md` 2026-10-12: a monster that survives a fight with you comes back and knows you ("oh, I've met you before"), with a short cinematic of you remembering it, marked by what you did (a burn scar) or hardened against it (immune to poison if you poisoned it). New; planned, not built. Which foes can do this, and how often do they return? |
| 62 | D50, M18 | **Planar areas that differ.** `doug-md` 2026-10-12: "The planar views are very simplistic. They're always the same", with the same four exits whichever way you go. A complaint about what is built: generation needs more layouts, exits that follow the land, and places worth remembering. Part of M18. **Built 2026-10-13 from `doug-md`'s choices** ([D66](../06-decisions.md), [D71](../06-decisions.md), [D72](../06-decisions.md)): every tile of open country has its own ground from its land and its neighbours, ways out only where the party can walk, pools, thickets, outcrops and landmarks. Waits on `doug-md` to say whether that answers it. |
| 63 | D65, D64 | **Inferred.** Built 2026-10-12: **how the real-time fight carries what the turn-based one did**, now that every fight is real time. An ambush holds the foes back 2 s; anyone down at a victory is carried off at 1 hp; every third landed swing counts toward proficiency; draughts used in a real fight come out of the stores; an open screen holds the clock; training teaches nothing; Flash Step is gone for now. Are these right, and should Flash Step come back as a real-time skill? See [D65](../06-decisions.md). |
| 64 | D67 | **Inferred.** Built 2026-10-12 from `doug-md`'s ask for growth you can see and a journal that looks like one: **the colour of each class** (Sworn Blade red, Longbow green, Hedge Priest candlelight, Magic Swordsman violet, Raider orange, Wildling teal; `colour` in `data/classes.json`), **the two lines in the landing that hand over the journal** ("Something else came down with {name}…", `data/fall.json`), the ribbon colour of each tab, what the character sheet shows and in what order, and the journal opening at The Company. Keep, or say what to change. |
| 65 | D57 | **Inferred.** Made 2026-10-13: **the Amber Knight** (`ooze_knight`). Asked for the Mother Ooze as a mound, PixelLab drew a knight of amber ooze; `dougie` said to keep it "as its own character" and make the mound too. Its name, its place in the Ooze's ranks between the Bog Jelly and the Mother Ooze, its numbers (46 hp, attack 13, defence 10, strike, cleave and crush), its size (1.3) and that it can bear a grudge (it is not on the non-sentient list) are all Claude's. Keep, or say what to change. |
| 66 | D76 | **Inferred.** Made 2026-10-13 from `doug-md`'s choice of sound in fights: **what the fight sounds like** — the fourteen sounds (`tools/make_fight_sounds.py`), which moment each one plays at, and how loud each is and how often it may repeat (`data/sfx.json`). Listen in a fight and say what to change: louder, softer, a different sound, or a moment that should have one. **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): he likes them; they may want turning up as time goes on. Kept. |
| 67 | D77 | **Inferred.** Built 2026-10-13 from `doug-md`'s ask for a quieter level-up: **how a level gained is shown** — three gold pulses, a ring and "Level N" over whoever gained it in a fight, and a line at the top right of the screen for four seconds ("Bram reached level 6 · a power to take (P)"). Keep, or say what to change: which side, how long, how bright. |
| 68 | D63, D64, `CH13` | **Inferred.** Built 2026-10-13 from `dougie`'s "every starting character gets their own class": **the sixteen classes** ([21](../21-the-sixteen-first-draft.md#the-sixteen-classes-as-built)). Each lead starts in theirs with four moves on Q W E R (mostly existing ones; Door Shut, Hold Fast, Kick and Haymaker are new), a passive and a growth a level, and at level 2 may keep it or take one of the six anyone can learn. The class names (Borne Mage, Gatewalker, Marshal, Duellist, Reaper, Lampkeeper, Shield-bearer, Skirmisher, Shade-caller, Sower, Phalanx, Provisioner, Twin Blade, Wolf-bound, Vanguard, Brawler), every move, passive and number are guesses, and each signature (Atlas carried, Pluto's shades, Diana's wolf and the rest) is planned, not built. Play a few and say what to change. |
| 69 | D78, D63 | **Inferred.** Built 2026-10-13 from `dougie`'s word that the sixteen are the playable lineup: **the sixteen as leads.** Their difficulty (docs/21's for the NT four; Caesar and Ares 1, Bellona, Vesta, Cato and Juno 2, Janus, Cassius, Saturn, Iris, Ceres, Ultor and Liber 3, Atlas and Diana 4, Pluto 5), their stats by how they fight, one basic attack each (their four moves come from their own class), a signature weapon each named from docs/21 (borrowing an existing icon until art request A4 lands), and every lead riding out alone (Atlas too, until his bearer is decided). **When someone else is the lead**, each settles first at the kind of place docs/21 gives them (Atlas a library; Janus and Pluto a gate; Bellona, Cato and Ares a keep; Cassius, Saturn, Caesar, Iris, Ceres and Juno a village; Vesta, Ultor, Diana and Liber a hut in open country), stays there three times as long and goes back most; Iris and Liber never stay long. Each has first words and an inn rumour written from docs/21. Their history fields stay blank, as [13](../13-heroes-and-tempers.md#writing-one) says. Keep, or say what to change. |
| 70 | `CO9`, D79 | **Inferred.** Placed 2026-10-13 from `dougie`'s answer that the original twelve become story NPCs: **where each one stands and what they say.** Bram keeps the ford village's road, Sera hunts the ancient grove, Toln reads in the reading hall, the Fox Fire Knight watches the thorn keep's muster, Barnaby wanders at the gate's mouth, Dirte keeps court in the great hall with Silver and Copper, Master Bo and Xiao study in the cloister, Buri stands at the foot of the Tower, Oran and the Adept listen on the wind scarp, the Tidewalker and the Tide Lion guard the salt hamlet's nets, Vane and his shadow watch the ash gate, and the Tattered One drifts in the vault beneath the library. Each has a short conversation drawn from [11](../11-character-backstories.md). Still open: which main story each one carries and how; whether the Tidewalker keeps the name Halbrec, which the shore's Pirate Man already uses; whether they still stand in for the others ([17](../17-the-sixteen-worlds.md)) until the sixteen do. |
| 71 | D82, D59 | **Inferred.** Built 2026-10-13 from `dougie`'s "Yes let's get effects and icons next": **which effect and icon goes with what** — a slash for any swing, an arrow for a bowshot and for Arc Shot, Snipe, Volley and Long Reach, a burst for every other spell (fire, water, ice, wind and grief alike), the charge-up only round a charged spell, the charging icon on any wind-up, and the stun, tired, draught and herb icons. Bleed, burn, provoke and vulnerable have no state in the fight yet. Watch a fight and say what to change: a move with the wrong effect, an icon that should not show, or whether bleed, burn, provoke and vulnerable should become real. |
| 72 | D63, D78, 21 Q4 | **Inferred.** Built 2026-10-13 from `dougie`'s pick of "signature styles": **each of the sixteen's own way of fighting** ([21](../21-the-sixteen-first-draft.md#the-sixteen-signatures-as-built)), on top of their class's passive and kept whatever class they take. Atlas comes with a bearer and is stuck if the bearer falls; Janus's skills come back faster the worse the odds; Bellona calls Advance or Break Them every 10 s; Cassius hits harder whoever has hit him; Saturn slows foes beside him; Vesta wards the worst-hurt ally and burns the dead harder; Caesar takes a quarter of blows meant for whoever is beside him and gets up once a fight; Iris marks foes for the party and grows stronger finishing them; Pluto raises what he kills, two at a time; Ceres plants the ground she stands on; Cato is set after standing still; Juno's draughts mend double and she throws them; Ultor builds on one target; Diana's wolf fights beside her; Ares hits hardest in the first 10 s, then tires; Liber cannot be stunned and grows reckless. Every rule and number is a guess. **Who carries Atlas** (21's question 4) is answered: **Sky** ([D83](../06-decisions.md), `dougie` 2026-10-13). Sky's body (the club ogre) is still a guess. Play a few and say what to change. |
| 73 | D84, D61, D66 | **Inferred.** Built 2026-10-13 from `doug-md`'s answers ("one continuous landscape", "every band near myself", places that "sit in the landscape and you walk straight in"): **how the one land is laid out.** A place stands in the middle of its tile with the land's own ground round it; bands are shown within two tiles of the party, patrol four stops within six cells of their spot and walk to the next tile at half a second a cell; a gate's fight still starts as you cross into its tile; where two lands meet the ground changes in a straight line. Walk it and say what to change. |
| 74 | D85 | **Inferred.** Built 2026-10-14 from `doug-md`'s voice note asking for walled towns, people doing jobs, great cities, small quests and a tavern: **the walls, the work and the city.** Stone walls round the ford village and the salt hamlet, a palisade round the fen village and the pine camp, mud brick round the dune outpost; a tower at each corner and either side of the gate. Two to four townsfolk a village walking a round of work (a farmer, an elder, an alewife and a gatewarden in the ford village; an eel-catcher and a rushman in the fen; a sawyer and a lookout in the pines; a fisher and a grandmother on the shore; a water-carrier and a trader in the dunes). **One great city a world**, dealt to the village nearest the middle of the continent, with the layout, people, five quests and rewards in [D85](../06-decisions.md); it keeps the village's generated name. Recommended: keep all of it, and say whether a second city (a harbour city, or one in the dunes) is wanted next. |
| 75 | D217 | ~~**Open.**~~ **Settled 2026-10-17** by `doug-md` (question 25, [transcript](voice-notes/2026-10-17-doug-md-founders-questions-2.md)): **Liber**, "Default, Liber". Nothing is built yet. Was: `doug-md`, 2026-10-13 ([voice note](voice-notes/2026-10-13-doug-md-cities.md)): "maybe actually one of the guys, one of the characters doesn't want to climb the tower". **Which of the sixteen, and what they do instead?** Nothing is built. Recommended: **Ceres**, who already turns wherever she lands into a village that eats ([21](../21-the-sixteen-first-draft.md)): she will not set foot in the Tower whoever leads, and a run she leads can end another way, her settlement grown into a walled town that stands when a gate breaks. Other answers: **Liber**, the freedom one `doug-md` played, who will not climb because the Tower is one more thing telling people what to do; or a lead the founders choose. **`dougie`'s half, 2026-10-16** ([transcript](voice-notes/2026-10-16-dougie-founders-questions-part-1.md)): not wanting to climb is fine, and such a lead lies open to invaders once another lead's world falls ([D172](../06-decisions.md)); Liber was his example. **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): left open for now. |
| 76 | D91, D92, `CO2` | **Inferred.** Built 2026-10-14 from `doug-md`'s choice of one world ([transcript](voice-notes/2026-10-12-doug-md-chat.md#one-world-every-game-d91)): Map F, frozen, with the Tower in the middle. **What stays the same and what the seed deals:** the land, its lands, the ground inside each tile and every place (its name, inside, owner, a gate's rank and ward, a library's books) are the same every run; where the lead lands, where the others of the sixteen land and walk, monsters, encounters, roadside scenes, rumours and people's names are dealt by the seed. And the sixteen worlds of a run are all this map ([M15](../05-roadmap.md)). Are these right? See [27](../27-the-world.md). **Kept by `doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)). |
| 77 | D90, D63, `CH13` | **Styles inside the sixteen classes?** `doug-md` asked on 2026-10-12 for several styles inside each class, picked at level 2 with the class from three cards ([D90](../06-decisions.md)); eighteen were drawn up for the six classes of the time. `dougie` then gave each of the sixteen their own class ([D63](../06-decisions.md)), and that is what is built. Do styles still sit inside each of the sixteen classes, and if so which? Nothing is built. Waits on both founders. **`dougie`, 2026-10-16** ([transcript](voice-notes/2026-10-16-dougie-founders-questions-part-2.md)): the sixteen signatures do the job of styles. **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): no styles. Settled by both: the signatures do the job. |
| 78 | D96, D95 | ~~**Inferred.** Built 2026-10-14 from the First Hour plan and `doug-md`'s play-test: **what the compass points at, and where Auto stops.** The objective is an errand taken (a Guild contract included; a finished one points back to whoever gave it), else the nearest town until one has been stood in, else the nearest open gate of the lowest rank until a gate has been shut, else the Tower; it points at places the party has not seen yet. Auto stops at a town or an errand's end and says so; at a gate or the Tower it goes in. Recommended: keep, and when the Tower's city and the Guild are built ([D95](../06-decisions.md) step 5), point at the Guild first.~~ **Settled 2026-10-14: `dougie` confirmed it**, asked keep or change: "Keep as is". |
| 79 | D97, D95 | **Inferred.** Built 2026-10-14 from design meeting 2: **the compass keeps to the lead's rank.** The compass and Auto never pick a gate whose expected level (1, plus 4 for each rank above E) is past the lead's level; with none open at the lead's rank they point at the Tower. Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 80 | D101, D147 | **Inferred.** Built 2026-10-14 from design meeting 2's calls A to E: **how far the crater is, and what the Guild's mark is.** The first world's lead comes down 12 to 16 tiles from Stormreach (`fall.json` → `crash.first_world`), and the mark that opens the Tower's stair is any gate shut, with or without a Guild contract. Recommended: keep both; Ewan walked the road in about seven minutes by hand on 2026-10-15. Added 2026-10-15 (D147): a second gate, **Elderford**, north of the city, and **Bram's line** in the next life's crater about somebody who shut that gate and went up. Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 81 | D102, D104, D113, D114, D117, D143 | **Inferred.** Built 2026-10-14 and 2026-10-15: **how hard the First Hour is, and what is on floors 1 to 5.** Each floor's layout and shape, its bands and their levels (no copied slimes on floors 1 to 4 since D143), the floor 5 keeper (the Warden of the Fifth and two slimes, level 9 since [D156](../06-decisions.md) and [D150](../06-decisions.md); a king slime at level 7 before), and every number in the First Hour setting (foes two levels down, half healed after a fight, about a level a fight). Eight bot runs had no fall before floor 5 (target 1 to 3); Ewan found it "fair". Recommended: keep until Ewan's play-test 3, then tune. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): challenging, but a well set-up party makes it a lot easier; the difficulty could go up a slight bit. **Settled by `dougie`, 2026-10-17** (AZ, [D188](../06-decisions.md)): Ewan's way, a little harder (row 119). |
| 82 | D103, D135, D138, D151, `CH10` | **Inferred.** Written 2026-10-14 and 2026-10-15: **every word of the sixteen chapter ones** (Atlas, Cato, Janus, Bellona, Cassius, Saturn, Pluto, Ultor, Liber, Ares, Caesar, Vesta, Iris, Ceres, Juno, Diana; [28](../28-the-first-hour.md#the-chapter-ones)), each lead's answer to Bram in the crater, the lines of the opening replayed after a death, where the keepsakes lie (floor 5's west alcove) and that only the lead finds their own. The creatives' meeting's rule for them (three shared lines, no two box 3s alike) and its rewrites of the last seven. Three ties are one night from two sides, never named, each with one shared thing to catch: Bellona and Ultor (the whistle), Cassius and Caesar (the cracked mask), Ares and Liber (the cut rope, the wooden sword); Will kept all three (AH) and made each blank face its own person (AI), 2026-10-15 23:04. `dougie` kept Cato's draft ("lets keep it") and asked for the rest to be wired; the words are still the build's. Recommended: keep as working drafts and read them in play. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. **Settled 2026-10-16:** `dougie` made the chapter ones canon, still open to change ([D173](../06-decisions.md)). |
| 83 | D107 | **Inferred.** Built 2026-10-15 from the gamers' conference: **the register opens by itself** the first time the party stands at the Tower's door, the compass calls that place "The Guild, at the Tower's door", and Atlas's buckle lies on the way to the floor 5 stair. Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 84 | D108, D111, D126 to D137 | **Inferred.** Drawn 2026-10-15 in house while PixelLab has no credits: **the look of the First Hour's in-house art** — the Tower's door and stand-in shaft, the far Tower, the road, the biome edges, the Tower's floors, stair and runes, the yard, the crater, the city's paving and the roadside scenes ([22](../22-asset-provenance.md)). Each is replaced by PixelLab art of the same name when credits come back. Recommended: keep until then; A9 (the huge Tower) first. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 85 | D115 | **Inferred.** Built 2026-10-15 from meeting 4's call V: **the way down and the resume.** Each Tower floor keeps its way in as a way down to the yard, and the door climbs on from the highest floor reached; between a gate's floors a step away walks out, the floors won kept. Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 86 | D122 | **Inferred.** Set 2026-10-15 from Ewan's play-test 2: **the lag target** is no frame over half a second on PC; the soak names the five longest. Recommended: keep, and measure on a phone after Ewan's play-test 3. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 87 | D156 | **Inferred.** Drawn 2026-10-15 for Will's AK: **the floor 5 keeper as a person**, named the Warden of the Fifth, in the Tower's grey stone armour with lit runes, a dark red crest, a T of light for a face and a glaive ([22](../22-asset-provenance.md)). It does not speak yet; the creatives' offer (stay at the top of floor 5 and stop climbing) waits for its lines. Recommended: keep the look; the founders name it. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. **`dougie`, 2026-10-16:** keep the name for now; it speaks and counts the challengers ([D174](../06-decisions.md)). |
| 88 | D157 | **Inferred.** Drawn 2026-10-15 for Will's AJ: **the ground of ash, blossom vale, slime, crystal fields, the fungal grove and the mistlands**, in house in the stand-ins' own colours ([22](../22-asset-provenance.md)). Recommended: keep; PixelLab's ground (A6) only if wanted when credits come back. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 89 | D158 | **Inferred.** Drawn 2026-10-15 for Will's AN: **the huge Tower's shaft**, round, in the door's stone, ribbed, a band of lit runes every three storeys, stepping in every six, lost in the sky under cloud ([22](../22-asset-provenance.md)). Recommended: keep until PixelLab's A9, then compare. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 90 | D153 | **Inferred.** Written 2026-10-15 from the creatives' meeting's C5: **what the replayed opening says of the lead who just died** — a `remembered` phrase for each of the sixteen (Atlas "a courtyard, and a gift", Bellona "a gate, and a whistle", Ceres "a granary full of children" and the rest, `data/opening.json`), the lines for a death with and without the chapter one found, each lead's pronoun, and six lines for the ties (Ultor after Bellona: "Somewhere a whistle stops blowing."). Recommended: keep, and hear them on a second life. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 91 | D154 | **Inferred.** Written 2026-10-16 from the creatives' meeting's C4: **who stands on the route and what they say** — Old Halloran's name and lines as the Guild's master beside Sennet, Buri's line about blades falling from a clear sky, Bram's dead master's saying in the crater, and Barnaby's joke at the gate's mouth. Recommended: keep, and hear them on Ewan's next run. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 92 | D152 | **Inferred.** Built 2026-10-15 from `dougie`'s idea ("a gate being a path that other worlds can use to interact with eachother ... a chance you meet the actual otherworld protagonist there"): **the crossing.** As a gate shuts it can open onto the same gate in another lead's world, the original lead standing in it; a world that has ended shows burning and empty. The first gate of the first life always opens (settled by `dougie`, 2026-10-16: "Yes always the first time", [D165](../06-decisions.md)); then about one in four at rank E, more higher; Janus and Pluto three times as likely; the company never crosses; every lead's line through the gate. Recommended: keep, and decide after the First Hour what can pass through (a word, a hand in the fight, the lead met again past the top). **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. **`dougie`, 2026-10-16:** a word carries first, and the worlds stay sealed until their lead dies ([D172](../06-decisions.md)). |
| 93 | D148 | **Inferred.** Drafted 2026-10-15 from the designers' fortnight (F5): **every word of the store page** in [29](../29-the-store-page.md), the five lines and the choice of five shots. Recommended: keep as the working draft; the founders rewrite it before the Steam page is made. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. **`dougie`, 2026-10-16:** stays a draft until Steam is taken up ([D169](../06-decisions.md)). **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): the draft stands. |
| 94 | D149 | **Inferred.** Built 2026-10-16 from the designers' week (AK): **the Tower's sixteen lights**, one going out by name when the lead wins floor 5 ("High in the Tower's glass, sixteen small lights burn…", `first_hour.light_out.lines`), and that the one who falls is chosen by the world's seed from those not in the company. Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 95 | D150 | **Inferred.** Set 2026-10-16 from the designers' week (AM): **when Auto hands a fight over**: every gate's fight, the keeper, and any foe more than one level over the lead (`first_hour.auto_stops.above_level`). Recommended: keep, and check it on Ewan's next run with Auto. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 96 | D161 | **Inferred.** Set 2026-10-16 from the five strangers' run (AU, Will: "Accept all recommended too"): **Sennet's words as the party walks into the city** ("New down, are you? Nobody climbs the Tower without the Guild's mark, and the mark is earned at a gate…", `first_hour.gate_line`). Recommended: keep. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 97 | D162 | **Inferred.** Set 2026-10-16 from the five strangers' run (finding 7): **where a gate's fight stands on the ground**: its keepers come out of the gate's doorway towards the party, the Guild's people stand beside the party, and a heart floor's heart is the doorway's front. Recommended: keep, and watch it on the next play-test at Greyhollow. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 98 | D163 | **Inferred.** Set 2026-10-16 from the five strangers' run (finding 6): **how big things are on a phone**: a short side of 540 game pixels (text about 12 points), and held upright the ground filling the screen top to bottom rather than shown whole. Recommended: keep, and check on Will's and Ewan's phones on the next build. **Kept by `dougie`, 2026-10-16** ([D168](../06-decisions.md)); `doug-md` may still change it. |
| 101 | D33, D60, `MX13`, D217 | ~~**Open between the founders.**~~ **Settled 2026-10-17** by `doug-md` (question 26, [transcript](voice-notes/2026-10-17-doug-md-founders-questions-2.md)): **`dougie`'s version, with `doug-md`'s rumour as how the lead hears of it** ("Will's version with my rumor as how you hear about it"). Not built yet. Was: `dougie`, 2026-10-16 ([transcript](voice-notes/2026-10-16-dougie-founders-questions-part-2.md)), answering question 12 of [30](../30-questions-for-the-founders.md): when the new lead reaches the floor a dead lead reached, that lead's signature weapon and powers are shot down from heaven "at a place that's most relevant to his character"; collecting it gives a portion of their power and abilities for this run, and it stacks, one weapon for each lead who fell. The weapon is the one they would have had above the Tower, not fully powered, "the tower is charging up their weapon". This differs from what is built: [D33](../06-decisions.md) carries "never power", the weapon waits for the old lead's level as well as their floor, and `doug-md` chose a random landing with a rumour ([D60](../06-decisions.md)). Waited on `doug-md` (not part of his answers of 2026-10-16). |
| 102 | D175 | **Inferred.** Read from `dougie`'s voice notes of 2026-10-16, where the machine transcript is unsure: (a) in questions 13 and 14, "you" is taken as the team (Claude) working out where music plays and trying more fight sounds, with `doug-md`'s own cues still welcome; (b) on the chapter ones, "make them canon" and, in the same breath, "for now ... get them all in inferred" are read together as canon that stays open to change ([D173](../06-decisions.md)). Back to the founders to confirm. **`doug-md`, 2026-10-16** ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md), [D186](../06-decisions.md)): music comes later, the memory theme first, and the team keeps a plan of what needs music ([31](../31-music.md)); he is happy with the fight sounds for now. |
| 103 | D176 | **Inferred.** Placed 2026-10-16 from `doug-md`'s ask for a builder and a healer: **Muck Muck and Sinner in Stormreach.** That both stand in the great city's streets (Muck Muck by the ruined bathhouse he is rebuilding, Sinner at the old shrine), every word either says (her name kept "so I don't forget"), Sinner's price of 40 gold to mend the whole company at once, and that Muck Muck builds nothing for the party yet ("bring me ground of your own and coin to match") until there is property. Recommended: keep, and say if she should charge per person or sit somewhere else. |
| 104 | D178 | **Inferred.** Built 2026-10-16 from `doug-md`'s play-test 3: **its first fixes as made.** Clicking the ground walks the party the way round to it; the land ahead is laid out within 5 ms a frame; Atlas rides Sky wherever he is met; the crater sells no bed in the First Hour; the crater's map picture (drawn in house); the lighthouse's beam at 0.45 s a frame; the fight's party cards 118 pixels tall. Recommended: keep, and say on the next play-test if anything still stutters. |
| 105 | D179 | **Inferred.** Built 2026-10-16 from `doug-md`'s choice of life on the land: **how much life, and the road's Watch.** About three birds, three butterflies or bees, one or two grasshoppers and a snail or spider to a tile, scaled by land (blossom 1.5, jungle 1.4, grassland 1.2 down to ash and the blight at 0.1), half in a place; a bird takes off at 2.4 cells and flies 5 to 9; half the road's tiles have two of the Watch (copper and silver legionnaires) walking it, with their lines and talk. Recommended: keep, and say if it should be busier or quieter. |
| 106 | D183, D172 | **Inferred.** Built 2026-10-16 from `dougie`'s answer to question 10 of [30](../30-questions-for-the-founders.md) ([transcript](voice-notes/2026-10-16-dougie-founders-questions-part-2.md), 03:07 to 04:07): **the word carried, its wording and where it is heard.** Every word: each lead's line said into a gate as it shuts (`crossings.json` → `carried.left`, Pluto's "Shut. Floors counted, stones counted. If you are counting too, the number is the same."), the voice coming through ("Through the last of the light, faint, comes a voice from another world: Pluto's."), word of a fallen lead who left none, and the journal's lines. Where: at the same gate the earlier lead shut, the latest word left there; failing that, at the first gate a life shuts, the lead who fell last. Recommended: keep, and have each of the sixteen's lines rewritten with their chapter twos ([D173](../06-decisions.md)). Back to the founders to confirm. |
| 107 | D183, D172, D47 | **Inferred.** Built 2026-10-16 with the word carried: **when a word is kept and who hears it.** It is written as the gate shuts, beside the fallen outside the save, so a lead's word carries even if they never die (a New Game started over them) and a reload does not say it twice; one word per lead per gate; it plays after the crossing in the same scene; a world built from a seed asked for hears nothing, as nothing else comes through into it. Recommended: keep. Back to the founders to confirm. |
| 108 | D184 | **Inferred.** Written 2026-10-16 for [D174](../06-decisions.md): **what the Warden of the Fifth says** as its fight begins. The first life: "The first challenger arrives. {name}. I know your face, and the world you fell into." Every later one: "The {ordinal} challenger approaches. {name}. I know your face; I knew the ones before you." The sixteenth: "The sixteenth and final challenger approaches. {name}. There is nobody after you." ({name} is the lead.) Also inferred: the count is by lives (one more than the leads already fallen), not by leads who reached floor 5, so the sixteenth life is always the final challenger; and a lead coming back after a loss hears the same line. The creatives' offer (stay at the top of floor 5 and stop climbing, agenda 87) is not in it. Back to the founders. |
| 109 | D182, D173 | **Inferred.** Drafted 2026-10-16 on `dougie`'s word: **every word of the sixteen chapter twos** (in the project's shared files, `story/chapter-two/`): each lead's keepsake and where it lies on floors 6 to 10, the memory, the three ties named, a fourth tie (Cato wrote Ultor's name on the gate roll), and each lead's arc as an end, a middle or left open. Recommended: Will and Ewan read them; nothing goes in the game until floors 6 to 10 are walkable. |
| 110 | D180 | **Inferred.** Built 2026-10-16 for the "who wins?" clips (AY): **a bout gives every body twice its health** (`health_scale` in `data/who_wins.json`), because one against one at a company's health ends in four to six seconds. At twice, a bout runs 25 seconds in the middle and one in ten is still going at 90; at three times, 38 and one in five. Recommended: keep twice. |
| 111 | D180 | **Inferred.** Built 2026-10-16 (AY): **how the show looks and says it**: a 2.6-second VS card, FIGHT!, the lead's colours (red left, gold right), K.O.! in slow motion for 1.2 seconds, the winner's banner held 5 seconds, "WHO SHOULD FIGHT NEXT? COMMENT BELOW", level 5, grass, and NOBODY WINS at 90 seconds. All in `data/who_wins.json`. Recommended: keep, and change after the first clips go up. |
| 112 | D180 | **Inferred.** Found 2026-10-16 by the who-wins table (480 bouts): **one against one, Iris (13%), Janus (20%), Pluto (23%) and Vesta (27%) lose most**, Diana, Ultor, Ares and Cassius (60 to 62%) win most. They are built to fight beside others, so it matters only where leads meet alone: the knockout at the top (D171) and these clips. Recommended: leave the sixteen as they are until the knockout is built, then look again. |
| 113 | D185 | **Inferred.** Made 2026-10-16 by the team on `dougie`'s word (question 13, [D175](../06-decisions.md)), stand-ins until Ewan's cues: **how the hour's five in-house themes sound** (`tools/make_music.py`, all in D minor, sharing the memory theme's A D C A): the memory theme a felt piano, a phrase stopped dead on a reach for B flat, then a held D (30 s loop); the world ending that phrase slower and broken off on its fourth note, then a low D and A (24 s); the Tower floors an organ chord, a footfall in the hall and the motif on a bronze bell, 60 a minute (32 s); Stormreach a lute, hand drum, shaker and reed tune at 120 a minute, the motif in the bass under it (32 s); the crater wind, a fire ticking and the phrase once, far off and muffled (30 s). Back to `doug-md` to replace or keep. |
| 114 | D185 | **Inferred.** Set 2026-10-16 with [D185](../06-decisions.md): **where each theme plays and how loud** (`data/music.json`): the Tower's five floors hear the Tower floors; Stormreach, its streets and its tavern hear Stormreach; the crater's tile hears the crater; a chapter one, while it is open, the memory theme; the death screen and the world's last look the world ending. The road, the title and the opening's replay keep Angelic, every fight Bday Project. The levels sit the new themes near Angelic on the road (about -34 dB on average), the crater quieter. Also the fight's two new sounds, `engage` as a fight opens and `ward` as a ward is taken up or soaks a blow, and their levels (`data/sfx.json`, with agenda item 66). Back to the founders to confirm. |
| 115 | D186 | **Inferred.** Drafted 2026-10-16 at `doug-md`'s request ([transcript](voice-notes/2026-10-16-doug-md-founders-questions.md)): **what needs music, and in what order** ([31](../31-music.md)). The memory theme first is his; after it the order (the road, a fight, Stormreach, the Tower floors, the keeper, the title, the crater, the world ending, the opening, inside), each piece's length and mood, the short pieces and what needs no music are the build's proposal, by `dougie`'s rule of the longest-heard first ([D175](../06-decisions.md)). Recommended: keep as the working list until music is made; change the order freely. |
| 116 | D187 | **Inferred.** Built 2026-10-17 for call BB: **the moves and their numbers**: dodge in a wind-up's last 1.6 s (wind-ups of a second or more), kite every 2.5 s from two tiles' reach, flank every 2.5 s (1.5 s with a passive for it), guard a friend under half health within 4 tiles, hang back 3 tiles, break off 4 tiles clear under 30% health every 8 s, and a foe worth 1.5 tiles more before switching. All in `data/skirmish.json` → `tactics`. Recommended: keep, and judge them by hand in the next play-test. |
| 117 | D187 | **Inferred.** Set 2026-10-17: **each lead's doctrine** ([21](../21-the-sixteen-first-draft.md#how-the-sixteen-fight-tactically)): Atlas, Iris and Diana ranged; Ultor, Ares, Liber, Cassius, Pluto, Saturn and Janus strikers; Caesar a guardian; Cato an anchor; Ceres rooted; Vesta and Juno keepers; Bellona a leader. Recommended: keep; a founder who sees a lead fight against their nature says so. |
| 118 | D187 | **Inferred.** Found 2026-10-17 by the who-wins table: **with tactics, the ranged gain most** (Iris 13% to 37%, Diana 62% to 73%), the close fighters lose a little, and **Janus (13%) and Pluto (20%) still lose most one against one**; bouts run 32 seconds in the middle. Recommended: leave the numbers until fighters can be told how to fight (the roadmap's next step), then look again. |
| 119 | D188 | **Inferred.** Set 2026-10-17 on `dougie`'s word (AZ, "follow ewans recommendation"): **how much harder "a slight bit" is**: in the First Hour setting, foes' attack 0.75 to 0.85 and health 0.8 to 0.9, the party's health 1.4 to 1.3 and attack 1.3 to 1.2; nothing else changed. Back to `doug-md` to feel in his next play. |
| 120 | D189 | **Inferred.** Built 2026-10-17 from `doug-md`'s play-test 4: **its first fixes as made.** A gold pin and a marching dotted line where a click sends the party; speeds 1×, 2×, 3×, 5× (of the two sets he offered, the second); fought Tower floors at level 4 + 0.4 a floor, never below the party, one more foe for each member past two, up to six; Ada sells a loaf, a meat pie and a honey cake; a bird goes up on a loop by itself on about one rest in six. Recommended: keep, and say on play-test 5 whether floors 6 up feel right. |
| 121 | D190 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask for a quest list that points the compass ([D118](../06-decisions.md), [D186](../06-decisions.md)): **what is in it and how it is used.** In it: the First Hour's road (one entry that moves on as you go), every errand and Guild contract taken, anyone of yours held for ransom, and a fallen lead's weapon there is word of; not the others of the sixteen, rumours, or the standing quest, which has no place to point at. L on the ground, or a click on the compass, steps to the next; the journal has Follow. Nothing is followed until chosen. Recommended: keep; say what else belongs in it (a person who asked you for something, a gate you were told of) and whether a pad needs its own button. |
| 122 | D191 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask that the tutorial be a must-play as Atlas who always dies, leading into the opening ([transcript](voice-notes/2026-10-17-doug-md-atlas-last-stand.md)): **Atlas's last stand as made.** Someone who has played it through is asked on a later New Game (while nobody has fallen) whether to play it again or skip it, and skipped, Atlas still falls, off screen; the band out of the broken gate is the Frostbitten and two ice wolves at level 10, beside the old sparring ground, and the company is down in seconds; winning it (if anyone ever does) ends the same way; the fall is told on a black screen over the lost fight; the first life after it plays the whole opening (not the replay), its ending shot "You have seen one of the worlds end already. Atlas fell in Hearthwick, at the edge of his own village, and his world went dark with him. It never comes back."; the worlds after it are built on a fresh seed of the player's own, not the village's; the last stand is not a life of the player's own (the next lead still lands on the road to the great city, still meets one of the sixteen at the first gate, and is the floor 5 keeper's first challenger); every new word (_The gate in the hills breaks_, the four lines of the fall, _Choose who comes next_, the skip card, the button _Atlas's Last Stand_). `dougie`'s first-life rule ([D106](../06-decisions.md)) is changed: back to both founders to confirm. |
| 123 | D192 | **Inferred.** Built 2026-10-17 from `dougie`'s ask that a move's effect be seen on whoever it lands on: **which move does what, how big, and who shrugs it off.** Haymaker knocks back 2 tiles, Kick, Shield Bash, Gust and Tidal Surge 1; Undertow pulls 1 and slows; Hamstring and the frost moves slow (steps 45%, swings 20%); the fire moves burn 12% of the blow a second; Dart bleeds 10%; Sunder adds 15% taken for 6 s; Earthshake and Crushing Wave knock down for about a second. Keepers are never moved or knocked down, big bodies are shoved a tile less, Liber keeps his feet, fire creatures do not burn, frost wolves are not slowed, slimes, wraiths and the tree sentinel do not bleed. A fighter's plain swing carries none of it, even where the swing is the same move. Recommended: keep; say which moves feel wrong in play and any move that should do something it does not. |
| 124 | D195 | **Inferred.** Set 2026-10-17 by design meeting 5 (call BC): **the stances as words and keys.** Five on each fighter card: Own way (the default), Close in, Keep away, Guard, Hold; a click on the card or a key each; kept per fighter between fights; never on enemies, Auto or the clips. Recommended: keep; say a better word for any of them after play-test 5. |
| 125 | D196 | **Inferred.** Set 2026-10-17 by design meeting 5: **the Second Hour's floors.** Floors 6 to 10 laid out from the rooms the chapter twos name (6 gallery, landing, storeroom; 7 watchtower stair, cistern; 8 bricked doors, ruined square; 9 walled yard, barracks hearth, dead tree; 10 antechamber, last stair), a keeper on floor 10, the ties' keepsakes in shared rooms (floors 7 to 9). Recommended: keep as the plan; the founders change any room by name. |
| 126 | D197 | **Inferred.** Set 2026-10-17 by design meeting 5: **the stakes target to floor 10**: 2 to 5 falls in sixteen self-played runs on the First Hour setting, with the bots playing a lead the quiz deals, not Atlas. Recommended: keep; `doug-md`'s play judges if the batch misses. |
| 127 | D202 | **Inferred.** Set 2026-10-17 by the pipeline ([32](../32-the-pipeline.md)): **the cost tiers, the bug severities S1 to S4, the six states of a milestone, and milestones 12 to 17** (the game at release on one page, the business basics, alpha, beta, launch, after launch). Recommended: keep; `dougie` answers the four calls (where the inbox lives, when the Steam page goes up, when questions 28 to 32 are answered, when the game-at-release page is drafted). |
| 128 | D204 | **Inferred.** Built 2026-10-17 from `doug-md`'s pick of play-test 4's fights ("the box, the stop before it"): **how a fight on the ground starts and looks now.** Nothing before it (no beat for the shout, no rush: the band closes in fighting), not a shorter beat; no edge and nothing dimmed, the edge showing faintly only while the pointer is out past it; a roomier field, six cells round everyone, 24×16 to 36×24. Back to `doug-md` to feel in his next play. |
| 129 | D205 | **Inferred.** Set 2026-10-17 with the tracking ([32](../32-the-pipeline.md#the-inbox)): **the label names and colours, the two issue forms' questions, and the status issue's shape** (waits on Will, waits on Ewan, S1s, milestone counts, needs sort). Recommended: keep; either founder renames a label in `.github/plan.json`. |
| 130 | D206 | **Inferred.** Built 2026-10-17 for meeting five's D197: **what Auto does at the Tower and after.** It stops at the Tower's door with "E to climb" up, and switched on again there goes in and climbs; after a chapter closes it makes for the next gate of the lead's rank rather than the Tower; a town counts as arrived at again once the party has been more than three tiles off. Recommended: keep; `doug-md` says in play-test 5 if Auto should go in by itself or stay stopped at the door. |
| 131 | D207 | **Inferred.** Built 2026-10-17 from `doug-md`'s "the separate fight screens" ([D204](../06-decisions.md)): **how the last fight screens went.** Tower floors above 5 borrow floors 1 to 4's plans in turn until the Second Hour makes rooms, each of their two bands the floor's whole fought-floor foes (so a floor holds about twice what one fight held), never fewer than the plan's band (floor 6: two bands of two); the Spire Apex's keeper four cells before the top stair; a town's raiders or guards and a captive's keepers five strides ahead of the party. Back to `doug-md` to feel. |
| 132 | D208 | **Inferred.** Set 2026-10-17 with the board ([32](../32-the-pipeline.md#where-each-kind-of-thing-lives)): **where each kind of thing lives and how the open work was cut into issues.** One issue per founder question and per play-test ask; `doug-md`'s list one issue an item; the open art rows as two issues (A9 alone, the rest together); the agenda's Inferred rows one standing issue (#227) rather than ninety; each issue's milestone (his asks under 14, alpha; looks under 15, beta; the Tower's themed floors under 11). Recommended: keep, and move any issue to another milestone on the board. |
| 133 | D209 | **Inferred.** Built 2026-10-17 for D195: **how the stances play.** Keys O, F, B, G for Own way, Close in, Keep away, Guard (H stays Hold); Guard's new escort move keeps within 2 tiles of the leader, tried every 2 s; Close in goes after foes anywhere on the field; Keep away with a sword waits while friends fight; the word sits beside the fighter's name and a click steps to the next. Recommended: keep until `doug-md`'s play-test 5 says otherwise. |
| 134 | D210 | **Inferred.** Built 2026-10-17 for call BL: **when Auto turns back to rest**: under half the party's health, to the nearest village, keep or hut it knows, before bands or the objective; never the crater. Recommended: keep; `doug-md` says in play-test 5 if Auto turns back too soon or too late. |
| 135 | D211 | **Inferred.** Built 2026-10-17 for call BM: **how kind the First Hour's road is to a lead walking alone**: the land's great beasts wait for level 3, a gate below rank C is kept by its floor's strongest instead of its faction's champion, and walking wears a party down to half its health, not a quarter. Recommended: keep; `doug-md` says in play-test 5 if the road is now too soft. |
| ~~136~~ | D212 | ~~**Inferred.** Written 2026-10-17 from `dougie`'s "50/50 split all profits": **profits means what is left after the store's cut and the running costs** (PixelLab, [D213](../06-decisions.md)), split half and half between `dougie` and `doug-md`. Back to both founders with question 33 in [30](../30-questions-for-the-founders.md) (issue #276), with Ewan's word on the split itself.~~ **Confirmed** by `dougie`, 2026-10-17 15:52: "50-50 is after Steam's cuts and costs" ([D230](../06-decisions.md)). |
| 137 | D217 | **Inferred.** Read 2026-10-17 from `doug-md`'s answers to 25 to 32 ([transcript](voice-notes/2026-10-17-doug-md-founders-questions-2.md)): **what his words mean where they are short.** "Question one" to "question five" under the questions for both are 30's 28, 30, 31, 32 and the five players; under his own, 25, 26, 27, the roads, the bottom of the screen and the followers. "Split 50-50" is his half of 28 only: what it is split on (after the store's cut, after costs), who owns what and what happens if one stops are still to write down with `dougie`. "Default" for the roads is the list read back to him: footpaths, dirt roads, cobbled roads, bog roads and bridges, with signposts where ways meet. Recommended: `dougie` confirms or corrects each in his own half. |
| 138 | D218 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask to start building what fits from other games ([#270](https://github.com/DougieWilDaBeast/earth-kings/issues/270)): **scars.** 3 health for good each time a fighter goes down in a fight the company wins and lives, up to 5; a lost or training fight leaves none. Recommended: keep, and say after a play-test if it feels like too much or too little. |
| 139 | D219 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask to start building what fits from other games ([#270](https://github.com/DougieWilDaBeast/earth-kings/issues/270)): **each faction's gate keeper and its prize.** Existing gear, matched to the faction (the Ember Wilds' keeper an ember blade, the Tide's a frost staff, and so on); 34%, then 50%, then certain; a miss names the prize. Recommended: keep, and ask `dougie` whether each faction should get a prize of its own drawn later. |
| 140 | D220 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask to start building what fits from other games ([#270](https://github.com/DougieWilDaBeast/earth-kings/issues/270)): **treasure maps.** A scrap from one band in four on the land, three scraps make an X 6 to 14 steps off, the find there about twice the best cache and always with gear, one X at a time; the lines ("Somebody buried something and never came back for it"). Recommended: keep, and say after a play-test if scraps come too rarely. |
| 141 | D215 | **Inferred.** Built 2026-10-17 from `doug-md`'s play-test 4 item 4: **people on the land as made.** Six bands always by the First Hour's road, 2 to 4 tiles off it and 4 from any place, half of them two or three brigands; the Watch beset on the roads round a town (within 6 tiles, never within 3 of a place) at 12% a step, by three brigands or three wolves, paying the usual roadside purse said as the Watch's bounty; a company of two or three climbers on 30% of the road's tiles the Watch is not walking, and resting by the stair on 40% of Tower floors from 2; the climbers' names ("the Copper Hands", "the Lantern Company" and five more), lines and talk, and the Watch scenes' words. Back to `doug-md` to play. |
| 142 | D226 | **Inferred.** Written 2026-10-17 from `dougie`'s "progressing through the big ones always": **which big piece of Ewan's list is built first**: his own order, so the land journals (#284) and the world remembering (#286), then companions whose arcs react (#283, one lead first), then a house in Stormreach and the town at the crater (#285, #258), then the harder second half (#287) with the Second Hour. Recommended: keep Ewan's order; either founder can move one up. |
| 143 | D223 | **Inferred.** Written 2026-10-17 from `dougie`'s answer on romance: **how a lead learns their bonds with the other fifteen**: a line in the journal when a lead meets, hears of or remembers another of the sixteen, filled in through the chapters and the fire's talk, the whole only when all sixteen live; a bond with one who fell is told with that lead's fall. Back to both founders when companions' arcs (#283) are built. |
| 144 | D216 | **Inferred.** Built 2026-10-17 from `doug-md`'s three Auto runs and roadside scenes that do not stop Auto: **Mixed as the default style**; the styles' names (Aggressive, Mixed, Passive) and their lines in the menu; Aggressive turning aside for bands within six tiles and walking into red within eighteen cells, and stepping into every roadside scene; Passive going round red only where there is a way round (through it otherwise); a roadside scene stood ten cells ahead and told in the log within five; Auto walking past a scene still costing renown, as walking past does by hand. Back to `doug-md` to play. |
| ~~145~~ | D229 | ~~**Inferred.** Written 2026-10-17 from `dougie`'s "January or February would be a good time for it to be in a pretty good position of nearly being finished": **the year is 2027**, the next January or February. Back to `dougie` to confirm, with whether that means a Steam Next Fest in February 2027 or a later one.~~ **Confirmed** by `dougie`, 2026-10-18: 2027 ([D255](../06-decisions.md)). |
| 146 | D232 | **Inferred.** Built 2026-10-17 from `doug-md`'s pick of play-test 4's asks: **the map over the ground.** The corner map top right, 180 pixels and fifteen tiles across, with N, E, S and W on its sides and an arrow at its edge for the followed thing; the large map opened over the ground with the party walking on under it; right-click for Go here, Place a marker or Take the marker off; a click on a marker goes there; up to nine markers; Go here walks straight there without turning aside for bands; drag or WASD to look, the wheel or + and - to zoom, C back to the party. Recommended: keep, and have Ewan try it in play-test 5. |
| 147 | D233 | **Inferred.** Built 2026-10-17 from `doug-md`'s pick of the kinds of way (footpaths and dirt tracks): **every tile's worn paths as footpaths; dirt tracks two cells wide joining each village, keep, hut and library to its two nearest others within 22 tiles; a signpost where three or more ways meet, naming the nearest place each way;** the in-house look until A32. Recommended: keep, and have Ewan walk them in play-test 5; cobbled carriage roads, bog boardwalks, bridges and fords wait on his word. |
| 148 | D222 | **Inferred.** Set 2026-10-17 on `doug-md`'s pick ("make fights more dangerous, not longer"): **foes on Tower floors 6 up hit 1.2 times as hard, 0.025 more a floor, never past 2;** probed on Auto with a party like his. Recommended: keep, and read his next play log, which names each fight's foes, speed and length at 1x. |
| 149 | D235 | **Inferred.** Built 2026-10-17 from `dougie`'s report that New Game on his phone only led to Atlas's last stand: **a player with a run saved has played before**, so New Game asks them to play the last stand or skip it, as [D191](../06-decisions.md) asks someone who has played it through. A player with no save still plays it. Back to both founders, `doug-md` above all, since [D191](../06-decisions.md) is his. |
| 150 | D236 | **Inferred.** Built 2026-10-17 from `doug-md`'s keep 7 (#270, issue #275): **the Watch walking the road join a band's fight on the party's side when it starts within ten cells of them, at the company's level; won, they pay 25 gold plus 10 a level and +2 renown, with two lines of thanks.** Recommended: keep, and see whether a party walking the road by hand ever meets a band near the Watch; if it never does, widen the reach or let the Watch walk further off the road. |
| 151 | D238 | **Inferred.** Set 2026-10-17 fixing play-test 3's item 13 (#253): **when a place comes into sight on the ground.** Within one tile of the party, about what the screen shows; on the map, at once. Recommended: keep, and say on the next play-test if a place still turns up in the log before it's on screen. |
| 152 | D237 | **Inferred.** Built 2026-10-17 from `doug-md`'s play-test 4 item 6 (#254): **the paths are the class choice at level 2**, and each card's question mark says, from the path's own numbers and moves, what kind of fighter it makes (front line from 6 health and 1.3 guard a level, hits hard from 2 attack, very hard but fragile under 5 health, quick from 0.8 speed, slow at 0.3 or less, a healer or a shooter from its moves), what it grows, what it starts with and where its later powers come from. Recommended: keep, and say if "paths" meant something else. |
| 153 | D239 | **Inferred.** Built 2026-10-17 from `dougie`'s go on Ewan's list and "any ideas you can come up with, go for it": **the land journals.** A page asks: walk 5 stretches, find one thing left out on its ground, beat 2 bands there, stand in one of its places (if any), shut one of its gates (if any). **The eighteen trinkets:** grassland Wayfarer's Boots (walk 15% faster), forest Moss Cloak (bands see you a step later), snowfield Bearfur Mittens (no cold, +1 guard), desert Sandstrider Sandals (10% faster, no heat), badlands Rattlesnake Fang (+3 attack), savanna Lion's Mane Torc (+2 attack, 5% health), ashland Cinderglass Charm (no heat, +2 attack), the blight Rowan Ward (+1 guard, 5% health), slime fen Saltglass Boots (no ooze, wade), bog Heron Stilts (wade, 5% faster), swamp Leech-Bone Needle (10% health), crystal fields Prism Shard (+2 guard), fungal grove Glowcap Lantern (a step later), blossom vale Petal Locket (10% health), barrow downs Barrow King's Ring (+1 attack, +1 guard), jungle Jaguar Tooth (+3 attack), taiga Wolfskin Wrap (no cold, 5% faster), the mistlands Mist Lantern (two steps later); walking at most 35% faster, bands at most three steps later; wading open to whoever is on that ground. Recommended: keep, have Ewan try one page in play-test 5, and swap any trinket either founder would rather were something else (more abilities, a mount, a map). |
| 154 | D240 | **Inferred.** Set 2026-10-17 fixing `dougie`'s report (#301): **the phone was on its side when options went missing**, because itch's full-screen button locks a phone to landscape for a page embedded 1280 x 720 (read from itch's own page script, not seen on `dougie`'s phone). Both ways round now fit. Recommended: keep landscape for full screen (more of the ground in view), and say if full screen should stay upright instead: itch's Edit game page has an orientation setting for mobile full screen. |
| 155 | D242 | **Inferred.** Built 2026-10-17 from `doug-md`'s play-test 4: **inns with rooms** — a kitchen and two or three bedrooms behind the three inns with an innkeep; a night costs 40 gold and leaves each sleeper at least +4 health, the room paid for is always room two, pinned with a line and pointed at by the compass, and sleeping in it saves. Recommended: keep, and have Ewan walk the Flagon's rooms in play-test 5; a cook in the kitchen and the other three taprooms wait on his word. |
| 156 | D243 | **Inferred.** Set 2026-10-17 from `doug-md`'s play logs: **the Ember Wilds in place of the Ooze on the Tower's floors 6 to 15**, alternating with the Wild, so no upper floor fields beginners' slimes. Recommended: keep. |
| 157 | D244 | **Inferred.** Built 2026-10-17 from `doug-md`'s ask for "a small Ui for the main screen while playing": **the company's faces, names, levels and health bars, and the purse,** in a small dark panel under the compass, top left; amber under 60% health, red under 30%; pressed for the party screen; hidden while a box is open or a fight is on. Recommended: keep, and say what else it should show (the day, the followed quest, the Tower floor). **Play-test 7** (`doug-md`, 2026-10-18): seen and used; he asks that it, and every panel, can be moved, resized and coloured ([28](../28-the-first-hour.md#play-test-7s-asks), item 12). |
| 158 | D245 | **Inferred.** Built 2026-10-18 from `doug-md`'s ask to take RimWorld's play screen as inspiration: **the alerts under the company** (badly hurt under half health, nothing to mend with, held for ransom, a known town attacked, a path or power owed, an X on the map; at most four; pressed to act on), the **!** for a path or power owed, the packs counted by the purse; and, in [investigation/11](../investigation/11-rimworld-play-screen.md), letters, an inspect card, sums on hover and speed keys kept as planned, and the clock, needs, work tabs, building menu, research, overlays, graphs and drafting cut. Recommended: keep, and say which planned piece is wanted first. |
| 159 | D246 | **Inferred.** Built 2026-10-18 from `doug-md`'s play-test 6: **its first fixes as made.** A blow at arm's length reaches the diagonal cells (it reached only the four beside, which set fighters dancing); a line in the log goes after eight seconds and the hint line is one line cut with "…"; a gate whose keepers are six or more levels above the company asks twice and Auto never goes in; a company of climbers within ten cells of a fight joins it, and a company on a floor rests round a fire. Back to `doug-md` to play. **Play-test 7** (`doug-md`, 2026-10-18): the boxes round the text were still far too big, and Hob's Lot stood by on floor 2; both fixed in [D259](../06-decisions.md). |
| 160 | D247 | **Inferred.** Built 2026-10-18 from `doug-md`'s pick B ("Stormreach walked outside... with the Tower beside it or in the middle"): **the Tower beside the city**, on its own tile just past a north gate, not in its middle; the city **two tiles of the land by two**, walled, with a south gate on the road and a north gate on the Tower; the old gate ward (toll house, waystation, Wenna, Crane, Hask, Peg, Ensign Rowe) **folded into the south end of the streets**. The Tower in the middle would need the city drawn round the Tower's own ground, a bigger change. Recommended: keep it beside, and say if it should be in the middle or bigger. **Confirmed** by `doug-md`, play-test 7 (2026-10-18): "The city is displayed out instead of walking in the building. This looks fantastic." Beside it stays; bigger or in the middle not asked. |
| 161 | D248 | **Inferred.** Built 2026-10-18 from `doug-md`'s play-test 6 ask, his first pick of its list: **a gate gone into and walked.** Each floor is chambers cut into rock joined by passages, doorway at the bottom and the way down at the top; a band in every chamber but the first, the Guild's people fighting beside the party; the way down goes straight on to the next floor; on the last floor the keeper holds the last chamber and the way down opens only when it falls. Sizes grow with rank (E 34×26 with three chambers to S 54×41 with six); each kind of gate has its own ground and walls; losing throws the party out with the floors filled in and the bands back. To confirm: how big, how many chambers and bands, the looks, straight on down or a stop between floors, and whether the doorway fight should stay for anything. Recommended: keep, play a rank E and a rank C gate through, and say what to grow or cut. **Confirmed** by `doug-md`, play-test 7 (2026-10-18), after three rank E gates and a rank D: "Great addition." What to grow: [28](../28-the-first-hour.md#play-test-7s-asks), item 1 (ground of its own kind, length by rank, shut when every monster is dead or the lord falls, a broken gate left behind, cheering). The sizes and counts still back to him. |
| 162 | D249 | **Inferred.** Built 2026-10-18 from Ewan's list (#286): **the world remembers.** Brought up: the newest deed heard at the place, once by each person you can talk to, sometimes by townsfolk as you pass. Colder at standing -3 or below: six in ten turn you away, 15 gold or a wits check wins them round. A grudge after three of a faction's own bands beaten: a cell more sight and a shout; beasts and the ooze hold none. **The dream:** a later world's people, within a tile of an earlier lead's deed, have dreamt it and say so once. This is the one guess that adds to the story: until now an earlier lead reached a later world only as their copy, their weapon, their ghost and the word at a gate (D52, D183). Recommended: keep the dream, or say no and it comes out (it is one line of data); and Ewan tries a burned town and three legion bands in play-test 5. **The dream kept** by `dougie`, 2026-10-18 ([D256](../06-decisions.md)); the rest still back to Ewan. |
| 163 | D250 | **Inferred.** Built 2026-10-18 from Ewan's list (#283): **companions whose arcs react**, starting with **Bellona's, "Twenty"**: opened at the fire after her chapter one (as lead) or once the company has stood on floor 5 (walking with it); give someone on the road their twenty, then shut a gate with her looking over the wall first; five endings (Ultor fallen, with you, met, a town burned, or none); +2 guard for good. Guesses: that companions who are not the lead open theirs at floor 5 (they find no keepsake of their own, D103); that it is all told at the fire; every line; that Ultor is felt but not named as the boy (chapter two names him, C3). Recommended: keep the shape and have Ewan play Bellona's in play-test 5, then the other fifteen are written the same way, each from their chapter one. **The shape and floor 5 confirmed** by `dougie`, 2026-10-18, and the fifteen written ([D256](../06-decisions.md), row 168); her lines still back to Ewan. |
| 164 | D251 | **Inferred.** Built 2026-10-18 from Ewan's list (#258) where `dougie` placed it (D224): **your own town at the crater.** Muck Muck builds once a gate is shut: a smithy (300 gold, Hald the smith sells gear), an infirmary (300, Ness mends the company for 25) and then a timber wall (500), which brings two settlers' houses, a well and two settlers. Guesses: the three buildings and their order, the prices, that building waits on a gate shut, that it is ordered from Muck Muck in Stormreach and stands when you next walk in, the people's names and every word. Recommended: keep, and say what to build next (an inn, a training yard, a shrine, a market); Ewan tries it in play-test 5. |
| 165 | D252 | **Inferred.** Built 2026-10-18 from Ewan's list (#285): **a house in Stormreach.** Marta lets the Flagon's room two for good (250 gold), the company's bed every night from then on; with a room kept, Steward Hobb sells the empty narrow house off the east street (900 gold), with a bed of the company's own (+6 health, an inn gives +4), a save and the company strongbox. Guesses: room two of the Flagon as the rented room, a room bought outright rather than paid by the week, the two prices, that the house needs the room first, the Steward as the seller, the house's place and every word. Recommended: keep; Ewan tries it in play-test 5 and says whether the house should hold more (a trophy wall, companions waiting there). |
| 166 | D253 | **Inferred.** Built 2026-10-18 from `doug-md`'s ask (#235): **coins in four metals.** Every price and purse is copper, silver, gold and platinum, at docs/26's proposed prices; everything docs/26 does not name is about 25 copper to the old gold, rounded (inn night 10 silver, room two 60 silver, the house 2 gold 25 silver, crater smithy and infirmary 75 silver, wall 1 gold 25 silver). Guesses: every number in docs/26 (never checked), the 25-to-1 rate for the rest, how amounts are said ("1 gold 60 silver"), an old save's purse carried over at 25 to 1. Recommended: Ewan plays a run and says which prices feel wrong; change them in data/. |
| 167 | D254 | **Inferred.** Built 2026-10-18 from design meeting 5's plan (D196, issues #231 to #233): **the Second Hour.** Floors 6 to 10 laid out room by room (6 gallery, landing, storeroom; 7 watchtower stair, cistern; 8 bricked doors, ruined square; 9 walled yard, barracks hearth, dead tree; 10 antechamber, last stair), two bands a floor with the floor's own foes; where each lead's chapter-two keepsake lies (6 Atlas, Iris, Juno; 7 Bellona, Ultor, Ceres; 8 Janus, Cassius, Caesar; 9 Liber, Ares, Vesta, Diana; 10 Cato, Saturn, Pluto); **the Keeper of the Tenth** on floor 10 (name, the titan's look for now, 110 health, two levels over the floor, and its three lines, which count the challengers as the Warden does); all sixteen chapter twos as drafted (D182). Recommended: keep for play-test 5; the founders rename a room, move a keepsake or rewrite a line by name. **Play-test 7** (`doug-md`, 2026-10-18): floors 6 to 10, the Keeper of the Tenth (beaten in 13 seconds of fight clock by four at levels 7 to 9) and Juno's chapter two played; no room, keepsake or line changed; he asks for the vision to be shown, not only told ([28](../28-the-first-hour.md#play-test-7s-asks), item 11). |
| 168 | D256 | **Inferred.** Written 2026-10-18 on `dougie`'s word to write the other fifteen in Bellona's shape: **every one of the fifteen companion stories**, each from its owner's chapter one: its title, every line, its two asks and their counts (three fights, floor 6, a gate, floor 8, a lost fight, the arena, someone new, the narrow house, the infirmary, twelve foes, a held town, five fights, a bounty, ten of one kind, floor 7, the crater's wall, two errands, two, four of the sixteen met, twenty foes, a band beside the Watch, floor 9, eight places), its endings and its payout (+1 or +2 attack or guard, +2 to +6 health). Guesses with weight: that a door on floor 8 stands open for a fallen one (from Janus's chapter two); that Cato puts Ultor first on his list; that a fallen one of the sixteen is grieved unnamed except where a chapter two names the bond. Recommended: Ewan plays two or three of them in play-test 5 (Pluto's, Cassius's, Liber's), and either founder rewrites any line that rings false. |
| 169 | D257 | **Inferred.** Built 2026-10-18 from `dougie`'s ask for party fights as video (#329): **party clashes and the guild war**, all in `data/party_war.json`. Party size 1 to 4, levels 1 to 10, a lead six times in ten; the units a party can draw; gear priced up to 2,500 plus 2,500 a level; stances Own way, Close in, Keep away, Guard (never Hold, which can stall); one to three draughts a side from bread to blue draught, drunk under 35% health; health 1.5 times a company's; 120 seconds to win. Every word said over a fighter's head (by doctrine: open, kill, low, drink, friend down, win) and the show's words ("PARTY CLASH", "Band of Ares"). The guild war: the Adventurers Guild (four of the sixteen at 6 to 9, eight muster soldiers at 4 to 7) against the Heart Empire (Dirte at 12, thirteen legion at 6 to 10) on 30 by 20, health 1.25 times, 180 seconds. |
| 170 | D258 | **Inferred.** Set 2026-10-18 from the Second Hour's sixteen climbs (#234): Auto goes up the Tower only at 90% health or more and turns back down a floor under 60% (`auto_climb_above`, `auto_turn_back_below`); the soak's companions are 0 to 3 at levels 1 to 6. With them, 4 falls in 16 and six climbers to floor 10, all with two or three companions; nobody alone or with one reached floor 10. Recommended: keep the Tower as it is; if `doug-md`'s play-test finds a lead alone too hard, a lone lead meets one foe fewer on every floor. |
| 171 | D259 | **Inferred.** Set 2026-10-19 from `doug-md`'s play-test 7: a company resting on a Tower floor joins a fight anywhere on that floor (`on_the_floors.join_anywhere`), on the road still within ten cells; the talk box at most 480 wide with a mouse and 880 on a touchscreen, never under 220, as tall as its lines, and the hint strip as long as its line; a cache with a blade, bow or staff drawn as the shattered sword and one with armour, a draught or a charm as a strongbox, until A37's art; a weapon landing shakes the view 1.4 seconds, 9 pixels at its worst. Recommended: keep these, and swap in A37's sword, bow, staff and bundle when `dougie` makes them. |
| 172 | D261 | **Inferred.** Built 2026-10-19 from `doug-md`'s play-test 7 on `dougie`'s order (call BR): **gates that grow.** Ten kinds of ground inside a gate (cave, frost, fire with lava walls, grassland, open plain, drowned wood, crystal cave, fungus cave, jungle, drowned hall), the first floor by the land round the gate and every deeper floor of a rank C gate or bigger another kind; floors E 1, D 2, C 3, B 3, A 4, S 5 and chambers E 3 to S 7, a second band in half the chambers from rank B; the keeper's health times 1, 1.25, 1.5, 2, 2.5, 3 by rank; every band down before a floor's way down opens, the keeper's fall scattering the rest; a shut gate lying broken in its mouth (stand-in art until A38) with three folk cheering. Recommended: keep, and `doug-md` plays an E and a C gate and says whether an S should be longer still and which kinds of ground to add or cut. |
| 173 | D262 | **Inferred.** Built 2026-10-19 from `doug-md`'s play-test 7 on `dougie`'s order (call BR): **five tiers of each monster**, goblins first. The Lesser Goblin, Goblin, High Goblin, Hobgoblin, and a Goblin Chieftain or Goblin Shaman at the top; their health (16, 24, 32, 46, 66 or 40) and moves; the odds by level (high from 4, hob from 8, chieftain or shaman from 12) and one at the top a fight; the shades that tell them apart until A39's art. Recommended: keep, and `doug-md` says which monster gets its five next and names them. |
| 174 | D263 | **Inferred.** Set 2026-10-19 from `doug-md`'s play-test 7 ("massive frame rate drop" in Stormreach): the cause taken to be the city's 37 townsfolk each working out their ways over a fresh grid and a land's page reading the whole map; both fixed and measured on a cloud machine, not his. The play log now writes `frame rate N fps, slowest frame M ms, at <place>` when ten seconds average under 40 fps; his next play log confirms or not. |
| 175 | D264 | **Inferred.** Built 2026-10-19 on `dougie`'s answer to play-test 7's fifth question (five tiers of each monster): **the wolves' five**, named as guesses, the Wolf Cub, Wolf, Grey Wolf, Dire Wolf, and a Pack Alpha or Moon Howler at the top; their health (18, 26, 36, 52, 72 or 44), moves and shades. Recommended: keep, and `doug-md` renames any he likes. |
| 176 | D265 | **Inferred.** Built 2026-10-19 from `doug-md`'s play-test 7 (call BR8): **Sennet seen from afar** as his own figure in blue light (`#6fb4ff`), 80% seen with a flicker of 20%, a step and a half to the lead's side, faded in over 0.6 s and out over 0.4 s once the talk ends; his face in the talk box the same. Only his first-town word is said from afar today. |

## 2. Eleven Part I questions that need a straight answer

`doug-md` answered Part I but eleven of them did not land cleanly. Each entry already writes out the
one follow-up it needs. `SK6` was settled in joint session 2; `LN1` matters as
soon as the map is resized. The rest can wait.

| ID     | Status          | The follow-up                                                                            |
| ------ | --------------- | ---------------------------------------------------------------------------------------- |
| `SK6`  | Answered        | **Settled 2026-10-01:** there is no step; the world runs on milestones (item 20). Was: **How long is a step?** He made the step the clock — time only moves when the party does — then handed the scale back: "one second… or one minute… entirely up to yourself". Everything in the game is priced in steps, so this one gates the rest. |
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
| `SK5` + `SK6` vs repo | **Settled 2026-10-01** by `SK6`: the world does not run on steps, so there is no step to price against a year. A 365-day year and the repo's 120 steps per season (480 steps a year) put a step at about a day and a half. He guessed "one second or one minute". Two of the three have to give. |
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

> "Every starting character gets their own class."
> — dougie, 2026-10-12, in writing ([transcript](voice-notes/2026-10-12-dougie-chat.md))

Settled further on 2026-10-12: **a class per character.** Each of the sixteen starts in a class of
their own, so the sixteen ways to fight are sixteen classes. The entry stays partly answered: which
class is the interesting wrong choice for each is still to write, and so is whether a lead can later
take a class other than their own ([D12](../06-decisions.md)). See [D63](../06-decisions.md).

> "Yes to all 3 questions"
> — dougie, 2026-10-12, in writing ([transcript](voice-notes/2026-10-12-dougie-chat-2.md))

Asked whether a lead can still switch class at level 2, `dougie` said yes: their own class is the
natural fit and the others stay open to them ([D12](../06-decisions.md) stands). Which class is the
interesting wrong choice for each is still to write. See [D64](../06-decisions.md).

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

## CO9 — The twelve original heroes are superseded but still playable. Do they stay as NPCs, get retired, or get rewritten into the sixteen?

> "Remember we are planning for the 16 playable characters lineup to be what we have already said. The other characters were the
> original but wont be the main characters, we will still use them in the main stories, they will be significant story related NPC's"
> — dougie, 2026-10-13, in writing ([transcript](voice-notes/2026-10-13-dougie-chat.md))

**Answered.** **They stay, as NPCs.** The sixteen are the playable lineup; the original twelve are no longer
leads, and become significant people in the main stories. See [D78](../06-decisions.md) and [D79](../06-decisions.md).
↳ Where each one stands and what they say was placed by the build and waits as agenda item 70.

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

# In writing — `dougie`, 2026-09-26

Rules `dougie` gave in writing while the sixteen were being drafted, quoted as written. They are a
founder's words, so they are canon. The rule they add is [D43](../06-decisions.md) and
[D44](../06-decisions.md); how it works is in [17](../17-the-sixteen-worlds.md#when-the-lead-dies).

## MX4 — Can a player re-roll the quiz, or is the first answer the one they live with?

> "There is the option of re-doing the quiz if you want to change what character you got."
> — dougie, 2026-09-26, in writing

**Answered.** The quiz can be answered again, as often as the player likes, before the run begins.
The first answer is not the one they have to live with.

## MX5 — "Show me all sixteen" currently bypasses the quiz entirely. Is that an escape hatch or a dev tool that should not ship?

> "Also we should give the option of opening the roster if the player wants as a side door but not
> until after they complete the quiz and want to bother redo or open the roster to choose"
> — dougie, 2026-09-26, in writing

**Answered.** It ships, as a side door. It does not bypass the quiz any more: the roster opens only
once the four questions are answered, next to answering them again.
↳ Settles agenda item 7. The quiz is the front door.

## MX11 — Is the next run the same world, later?

> "When a character dies and you need to do a quiz to select the next hero, the options in the quiz
> that give you that hero no longer exist. That answer is removed from the quiz"
> — dougie, 2026-09-26, in writing

> "A question with only one answer left should still require confirmation of selection by the user.
> This is so they can visibly see an option is missing after each death of a player character."
> — dougie, 2026-09-26, in writing

**Answered**, adding to the joint-session answer above. The next lead is picked by the quiz again,
and the dead cannot be answered into ([D43](../06-decisions.md)). An answer is removed once every
character it could still lead to has died. A question left with a single answer is still asked, so
the player sees what is gone.

---

# Joint session 2 — both founders, 2026-10-01

A ten-minute call between `dougie` and `doug-md`, transcribed by Teams and kept whole as
[joint session 2](voice-notes/2026-10-01-joint-session-2.md). It worked the
[briefing sheet](session-2-briefing.md) from the top and stopped after item 8; items 9 to 19 wait
for the next call. Both are founders, so what either said plainly is canon; where one proposed and
the other agreed, the entry quotes both. As in session 1, a quote runs straight through the other
founder's "Mhm" or "Yeah", and nothing else is left out.

What it changes is in [D48–D54](../06-decisions.md). Only two of those are built: the hundred-floor
Tower and the two assist numbers. The rest are planned on the [roadmap](../05-roadmap.md).

## GT11 — Ten floors. Is it ten from outside too — a building, or does the inside not agree with the outside?

> "I think the tower should have 100 floors because it's just iconic."
> — dougie, 2026-10-01, session 2 [00:01:15]

> "Yeah, I agree."
> — doug-md, 2026-10-01, session 2 [00:01:20]

> "It could be cool, yeah, to have a chapters of five, then that would be 20 chapters altogether."
> — doug-md, 2026-10-01, session 2 [00:01:29]

> "So, what if we set it to five? For now, and then, as like, as things change going into the
> future, maybe the chapters get a little bit longer, if you know what I mean, so it could be like
> 10 floors, but yeah, we stick to five for the whole thing now, and if we have to come back and
> change it, we'll try to fit the overall story and theme to fit that's yeah, 5."
> — dougie, 2026-10-01, session 2 [00:01:56]

**Answered.** **A hundred floors, in twenty chapters of five.** `dougie` proposed the hundred and
`doug-md` the five. If the chapters ever get longer, the story is made to fit the number, not the
other way round.
↳ Settles agenda item 1. Replaces D16's ten and fills in the count D34 left open ([D48](../06-decisions.md)).
↳ Answers `dougie`'s own doubt from session 1, "maybe 100 floors is too much": a hundred, "because
it's just iconic".
↳ Built 2026-10-01. How hard each floor is, which factions hold it and how the rewards are spaced over
a hundred floors are a build choice, **Inferred**. That is agenda item 24.

## SK6 — What is a step?

> "I don't think the world needs to run on steps at all. I think it could be milestones."
> — dougie, 2026-10-01, session 2 [00:02:36]

> "Yeah, yeah, I definitely agree. I think we've gone past running on steps now."
> — doug-md, 2026-10-01, session 2 [00:02:43]

> "Because it just doesn't work for what we're trying to build. So yeah, we're going to get
> completely, the world doesn't run on steps at all. We're going to have different milestones.
> We're going to have chapters with the tower, and we're going to set up some other checkpoints as
> well. Like, and there's going to be no time pressure, like you said, for running on steps."
> — dougie, 2026-10-01, session 2 [00:02:49]

**Answered.** **The world does not run on steps.** It moves on at **milestones**: the chapters of
the Tower, and other checkpoints not named yet. There is no time pressure.
↳ Overturns the Part I answer above, where `doug-md` made the step the clock. He agrees to it here.
↳ Replaces pillar 5 and D01 ([D49](../06-decisions.md)). **Not built**: the step clock still runs
the game until the roadmap's M18.
↳ Re-opens everything priced in steps. That covers doctrine fading (`KN1`, D07), gates breaking
(`GT6`, D15), captive deadlines (D18), thread deadlines (D23), the seasons (`CL2`) and the travel
of companions sent on jobs. "No time pressure" sits hardest against D15, where neglect is the
pressure. Agenda item 20.
↳ Dissolves the `SK5` + `SK6` collision: with no step, there is nothing to price against a 365-day
year.

**Not in the book — one view, and a map you fill in.**

> "I think that we should no longer have a planar view and a worldview in the game. I think that
> the worldview should just be what your map is. And then the planar view is what you play the
> whole game on, basically."
> — doug-md, 2026-10-01, session 2 [00:03:12]

> "let's say if it's a new location, it'll be kind of black. But the more that you discover, the
> map will start to discover, start to reveal itself to the player as they go through it. Because
> you shouldn't know where everything is and you shouldn't be able to see the full map. Or maybe
> you might find a guild and they might have a map and you'd be able to like, oh, happy out.
> There's some locations on the map that they've jotted down. You might have the general area, but
> you won't know where all the different things are."
> — doug-md, 2026-10-01, session 2 [00:03:39]

> "But yeah, we're going to move that now to like a mini map or more like a map where it's all
> blacked out until you either travel it yourself or you somehow pick up maps hidden around the
> world. or other milestones."
> — dougie, 2026-10-01, session 2 [00:04:24]

No question in the book asks this. `doug-md` raised it unprompted and `dougie` took it up.
**The game is played in the planar view. The world view stops being a place you walk and becomes
the map**, which starts black and fills in as the party travels. A guild's map marks some places and
the general lie of the land, not everything, and other maps are hidden around the world. This is
[D50](../06-decisions.md). **Not built**: Z still switches views. How a party crosses the whole
continent on foot in the planar view is agenda item 21.

## CO7 — Save-scumming was allowed "to be revisited" (D21). Revisit it.

> "I think there should be like an Iron Man mode, which is 1 life, once you die, that character is
> gone, and you can go to the next character as we've discussed, and there can be another mode
> where it's just... Normal or classic, and it could be reload saves. If you want."
> — doug-md, 2026-10-01, session 2 [00:05:13]

> "Okay, yeah, yeah, okay, yeah, I actually agree with you because it could be a little sudden
> after dying. and you can't reload, but then it's still the same idea, like you don't have to
> reload. And if you don't reload, it'll go to the next character. It'll give you the option, like,
> do you want to ascend to heaven? It asks you that, would you like to ascend to heaven and select a
> new character or something like that on the classic, but then in the Iron Man mode. It forces
> you, says you ascend to heaven and it brings you right back to the login screen to choose
> character."
> — dougie, 2026-10-01, session 2 [00:05:37]

**Answered.** **Two modes.** In **Classic**, saves can be reloaded: when the lead dies, the game
asks whether they ascend to heaven, with a new character chosen, or whether to reload. In
**Iron Man** there is one life: the lead's death ascends them and goes straight back to choosing a
character. When the mode is picked was not said.
↳ Settles agenda item 4. Replaces D21 ([D51](../06-decisions.md)). **Built 2026-10-12** (M15). When
the game saves itself, and the mode being picked with the lead, are agenda item 40, **Inferred**.
↳ Answers `SM1` for both modes: reloading is the player's choice, not a fact about the world.
↳ D47 already keeps the fallen outside the save. Under Classic a death is final only once the player
chooses to ascend, so that is when the record should be written. That is a build reading,
**Inferred**, written into D51.
↳ `dougie`'s first reading of the question got no answer: can you go on in a dead lead's world
without moving the story on? Neither mode keeps that world playable.
↳ "Ascend to heaven" is also the lead's standing quest (`SF1`). Agenda item 22.

## MX20 — Can you meet a character whose temper you rolled — is there a version of you walking around?

> "So, yeah, there can be a copy of, oh, right, yeah, there's a copy of the lead, but the character
> that you previously chosen is going to just be a generic NPC based off his stats. So, you know,
> like a normal character, he just appears in the world. He's got his own. He's got the personality
> that's backed out at the start as well, and you can interact with them as he's kind of defined."
> — dougie, 2026-10-01, session 2 [00:06:24]

`doug-md` agrees throughout ("Yeah", "Mhm", "Yep").

**Answered.** **Yes.** In the second world, the first lead is alive there as well as being a ghost
and a weapon. They are an ordinary NPC built from their stats, with the personality they started
with ("backed out" is as transcribed, probably _baked in_), and they can be talked to like anyone
else.
↳ Settles agenda item 5. Adds to D33 ([D52](../06-decisions.md)). **Not built**; it belongs to M15.
↳ Fits D31: the fifteen in any world are copies, and a dead lead's copy is one of them.

## SF1 — Does the player character know they are unusual? Is that a fact about the world or the game?

> "Initially down from heaven, I think that you should have... Something that can give you, like,
> you'll get a quest and be like, "Ascend to heaven, " that's like your that's your baseline quest,
> and you'll always have that until you finally complete that task."
> — doug-md, 2026-10-01, session 2 [00:07:28]

> "it shouldn't be an immediate thing. Like if you play the whole story with one character, like you
> should only figure out the story by the end anyway."
> — dougie, 2026-10-01, session 2 [00:08:09]

> "I feel like all the characters will have some sort of like memory dysplation. Like the further
> they go on throughout the journey, they'll get more fragments towards what happened at the start."
> — doug-md, 2026-10-01, session 2 [00:08:23]

> "So every, every, every five floors, every chapter, they get new memories. And the memories that
> they get will be different for each character. It'll be to do with their character and their role
> from the backstory of Earth Kings."
> — dougie, 2026-10-01, session 2 [00:08:36]

> "so there's a game called Until Dawn and it has the totems as a memoir. And it's a great one that
> when you kind of finish the game and you collect all the totems, you can see the false like
> cinematic story of what took place from start to finish."
> — doug-md, 2026-10-01, session 2 [00:08:51]

> "Okay, yeah, so we're going to have something like that built into two for sure."
> — dougie, 2026-10-01, session 2 [00:09:09]

**Answered**, adding to session 1. **The fall takes the memory, and it comes back in fragments.**
Every chapter of the Tower (every five floors), the lead gets back memories of their own life and
their own part in the story of the Earth Kings. Played with one character, the whole story only
comes together at the end. Collecting every fragment plays the full story as a cinematic, the way
_Until Dawn_'s totems do. From the moment they land, every lead carries one standing quest,
**"Ascend to heaven"**, until it is done.
↳ Settles agenda item 6. The reading taken after session 1 stands, that the fall takes the memory,
and now it has a schedule ([D53](../06-decisions.md)). **Not built**; it belongs to M13.
↳ "memory dysplation" and "built into two" are as transcribed.
↳ Supports agenda item 15's reading, that a background is the life above found out in pieces,
without settling it.
↳ Tying memory to chapters means a lead who never climbs remembers nothing. Whether other milestones
(`SK6`) bring memories back too was not said.

## CH10 — Who in the other fifteen do they already know, and how?

> "Maybe you will... You'll slightly know the faces, or I don't know, it's kind of hard. What do you
> think?"
> — doug-md, 2026-10-01, session 2 [00:07:46]

**Partly answered**, as after session 1. `doug-md` offers a half-recognition, "slightly" knowing
the faces, and doubts it in the same breath. `dougie` answered the memory half (`SF1`), not this.
**Does a lead half-recognise the other fifteen's faces, on top of the mark?**

**Not in the book — assists, from `D37`.**

> "So assist one number or two. So one or two for grunts, 5 for healers. So this is more of like a
> game game technique, game max, and I don't think we can talk about assist just yet"
> — dougie, 2026-10-01, session 2 [00:09:22]

> "So for the assist, yeah, I think what they have there at the minute seems all right. So 5, 2 for
> 10 for grunts and five for a healer's assists."
> — dougie, 2026-10-01, session 2 [00:09:49]

> "Yeah."
> — doug-md, 2026-10-01, session 2 [00:10:01]

**Two numbers.** An ordinary fighter learns a kind of enemy after **ten** assists on it, and a
healer after **five**. That settles agenda item 8 ([D54](../06-decisions.md)). The number comes
through garbled ("5, 2 for 10") and `dougie` hedges first, but the sentence lands on the
two-number option from the briefing sheet. What counts as a healer's assist comes from
`doug-md` in session 1: "you're healing a character, you're assisting them" [00:59:05]. The build
reads that as healing the one who lands the blow, in the same fight. Built 2026-10-01, **Inferred**,
agenda item 23.

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
