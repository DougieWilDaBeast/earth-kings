# 09 — Wishlist

Spoken notes dropped into `DROP-ZONE/` as voice memos on 2026-08-31, transcribed and kept here so
the intent survives the audio. Each is the note as given, then what was done about it.

Order is the order they were recorded, not priority.

---

## W1 — A cinematic before the title screen

> There should be a small cinematic animation for when you enter Earth Kings. A short overview of
> the existing map, showing different locations and vibrant buildings and characters running
> around. The Earth Kings title appears, and you press enter to go into the title screen.

**Built.** [`src/ui/cinematic.gd`](../src/ui/cinematic.gd) is now the boot scene. It generates a
throwaway world, glides `CameraRig.focus_on` between the four places furthest apart on it, walks a
few of the founders along the roads between them, fades the title up and hands over to the menu on
any key — or on its own after twelve seconds.

**Open:** the world is regenerated every boot, which costs a beat before anything appears. No
haze or vignette over the country (the first attempt used an opaque shader and painted the screen
white; see `title_backdrop.gdshader`, which writes `alpha = 1.0`).

## W2 — A voice at the end of the cinematic

> When the cinematic ends for Earth Kings, a character's voice should say —

**Blocked.** The memo cuts off before saying what the voice says. Needs the line.

## W3 — A coliseum

> A Colosseum or gladiator battle and training ground. Pick a character and pick whoever you want
> to battle against — or pick a character of your choosing and fight waves of coliseum members.
> Or have a party, and that party fights four other parties: not just party versus party, but
> party versus party versus party versus party. You gain rewards for it. A separate system to the
> Earth Kings main storyline.

**Built, minus the free-for-all.** [`Arena`](../src/chronicle/arena.gd) +
[`src/coliseum/`](../src/coliseum/), reached from the title. Pick who goes out and which card they
face, then fight waves that grow in number and level. The purse compounds; you can stop between
rounds and bank it, or push on and lose it. `user://earth-kings.arena.json` keeps the best night
per card. It borrows nothing from the run: `Arena.open` stashes the real roster and `Arena.close`
gives it back, and wounds carry between rounds without anybody actually dying.

**Open:** party versus party versus party is not there. `Unit.Team` is a two-value enum, so more
than two sides is a real change to `Battle`, `TurnManager` and `EnemyBrain` rather than a data
edit. Cards are fixed lists; there is no draft or wager.

## W4 — A journal

> Every new encounter with characters, you start to write down different abilities that they use,
> what kind of creature they are, where they were spotted. When you insert a character into the
> journal it has question marks for abilities, stats, what they can do, until they reveal them to
> the player, and then they are jotted down.

**Built.** [`Journal`](../src/chronicle/journal.gd) over `world.journal`, read with **N** in walk
mode. A page opens the first time you stand across a field from something and opens nearly blank.
Each line is earned: its reach once it has hit you, its guard once you have hit it, its
constitution once you have put one down, and an ability the first time you watch it used. Training
fights are not written down.

**Open:** nothing yet reads the journal back — knowing a thing does not help you fight it. Opens
with **N** from the road, from inside a place, and from the battle itself.

## W5 — A museum

> A museum you can go through from the title screen, as one of the options. You can access all past
> and existing party members and journeys you have been through, and look at the stats and
> everything they have done, with great depth.

**Built.** [`Museum`](../src/chronicle/museum.gd) writes each finished run to
`user://earth-kings.museum.json` — kept apart from the save, so starting over does not erase the
people who came before. The screen lists journeys newest first, with the one still being walked at
the front, and shows the company's faces, callings, levels and fates beside what the run amounted
to. Reached from the title.

**Open:** only forty journeys are kept, and there is no per-person detail beyond the plaque — the
memo asked for "great depth". A run that is started over is now filed as "walked away" before the
save is written on top of it, so an abandoned company still reaches the hall.

## W6 — Your player icon on the title screen

> Your player icon should appear when you load into Earth Kings, at the top left beside the title,
> and it should be the character you are currently playing as in your storyline.

**Built.** The crest beside the title is the lead character's face, read straight off the save
file rather than by loading it — looking at the menu is not starting a run. No save, no change.

## W7 — Title screen music

> Music should be implemented into the title screen. Soft music, something to break up the silence.

**Built, on a placeholder.** `data/music.json` has a `hearth` set wired to the `title` and
`character_select` scene keys. It plays `angelic.wav` quietly, which is also the road track — a
title track of its own is still wanted.

## W8 — Your party running along the bottom of the title screen

> For your current party and the players you are using in your game, on the title screen before you
> log back in, you should see your characters doing a running animation, either right or left. A
> continuous running scene where they are just running, fighting opponents and running again. A
> nice little addition to break up the bleakness of the title screen.

**Built, partly.** [`TitleParade`](../src/ui/title_parade.gd) runs the saved party across the foot
of the title screen, behind the menu, and the founders when there is no save. Only `sworn_blade`
has a `run` cycle so far (`art/units/<id>/run/<direction>/frame_NNN.png`, eight frames); anyone
without one keeps their standing pose. The fighting-and-running-again loop is not there.

## W9 — A sound when you hover the title options

> There should be sound effects when you hover over different options on the title screen. Almost
> like a click sound, or something of that variation.

**Built.** [`Sfx`](../src/autoload/sfx.gd) autoload on its own audio bus, `audio/sfx/hover.wav`
and `select.wav`. `Sfx.attend(button)` wires both noises; the title, character select and run
summary screens all use it.

---

# Second batch — 2026-09-02

Ten more memos. These are longer and mostly ask for depth rather than features, so each one is
broken into the pieces that can actually be picked up separately.

## W10 — Bugs on the world map

> The party cannot walk into the named locations. There's a white box that appears on some of the
> items, some of the buildings, some of the locations, some of the characters — I'd like that
> cleared up straight away. The UI needs to be less word heavy. The text is covering up the screen
> a lot; I'd like it a lot smaller and maybe to the side, or you can toggle conversations so they
> still happen but are less in your face. I like the player icons, the little chips underneath.

**Highest priority — these are defects, not wishes.**

- **W10a — white boxes. Fixed.** A texture first loaded part-way through a draw pass is drawn as a
  white rectangle. `world_scene._site_art` was loading lazily from inside `_draw_places`, and
  `Database.unit_face` re-loaded on every call. `unit_face` now caches, and `world_scene._warm_art`
  loads every site hold and every face up front — in `_ready` and again after each `Encounter.restock`.
- **W10b — cannot enter named places. Fixed.** Villages and keeps could always be entered with
  **E**, and the hint said so; the real problem was that only 6 of 21 places on a map _had_ an
  inside. There are now five more (`data/areas/{tower,library,gate,hut,home}.json`) dealt out
  through `WorldGen.AREA_POOLS`, so every named place can be walked into. **E** on anything else
  says "There is no way into X" instead of silently doing nothing.
- **W10c — the log is too loud. Fixed.** The status, party line and world log are smaller, the log
  is half the width and keeps three lines instead of four, and **L** toggles it off entirely.
  Unwritten talk no longer has to take the screen either: **Chatter** in the system menu sends
  banter to the log and a speech bubble instead of the dialogue box. It still happens, and
  authored conversations are never demoted.

## W11 — Import the rest of the animations

> Import the animations placed on each character and place them accordingly — idle, walking,
> running, fighting, stance — and implement them correctly onto the characters. In battle they
> should be a lot more noticeable, because when the characters move they seem to just levitate to
> the next tile. I want them to move to that tile.

**Built, waiting on art.** [`Database.unit_run`](../src/autoload/database.gd) loads and caches a
cycle from `art/units/<id>/run/<heading>/frame_000.png`. In battle a unit steps its run frames
while it crosses and turns at each corner rather than at the end; in area mode [`AreaActor`]
(../src/area/area_actor.gd) does the same, reading movement off its own position so nothing that
moves an actor had to change. Anyone without a cycle keeps their standing pose, exactly as before.
**Open:** only `sworn_blade` has one. The other 68 units need PixelLab walk/run/attack exports.

## W12 — A much bigger, less square world

> The map is good enough but there's nothing much there. When you zoom out it's just a big square.
> It should be a lot bigger, and there should be places you can't walk to. I don't want it to just
> be square. I can walk from one side to the other in fifty clicks; it should be almost a thousand.
> There should be grassland, desert, snow, forest, an ocean, ponds, lakes, mountains.

**Not built.** `World.SIZE` is 44×44 with a rectangular border. Wants a non-rectangular landmass,
regions with their own terrain, and a much longer crossing. Every seeded test walks a fixed number
of steps, so the size is not a one-line change.

## W13 — Step into a tile

> You can either go from the over-the-top world view, or you can step into the tile and it's an
> explorable location — chests, characters to interact with, battles, dialogue, conversation,
> trade, a friendly spar. You might arrive at a location holding a tournament and take part with
> your team for rewards. A lot more depth to the world is needed, massively.

**Partly there already.** Area mode (`src/area/`) is exactly "step into the tile", and since W10b
every _named_ place has an inside — village, keep, library, gate, hut, Tower and Home. What is
missing is ordinary ground: you cannot step into a field or a wood, which is most of the map.
Wants what is inside to be worth the trip, too. The tournament is the coliseum (W3) placed in the
world rather than on the title screen.

## W14 — Quests, events and consequences

> There need to be quests. Different events should happen and you react to them. A trader on his
> horse and carriage gets attacked by bandits and you see it happen, so you try to stop it. He
> might reward you, or ask for safe passage to the next town, and you might get money off trade
> routes with him. Implement renown, so people start to know you — whether you're good or bad, if
> you're raiding people or destroying civilians or stealing.

**Half built.** [`Renown`](../src/chronicle/renown.gd) already does the standing/notoriety part,
and [`Skein`](../src/chronicle/skein.gd) is the engine for consequences that arrive later. Missing:
roadside events you interrupt, escort as a thing you can do, and trade routes as an income.

## W15 — An equipment screen

> Characters should have an equipment folder, so in-game you click on your character and go into
> their inventory and see what weapons they have, and equip different weapons that give them stats
> like plus twenty, or minus twenty if it doesn't fit that character.

**Built.** The table went from 3 pieces to 34, and [`Gear`](../src/chronicle/gear.gd) makes fit
matter: every piece names the callings it `suits`, and anyone else carries it at a fraction of its
worth plus a penalty — so "minus twenty if it doesn't fit that character" now reads. Somebody who
has not chosen a calling yet is judged on the ones they could still take.

The party has stores (`GameState.stores`, saved): a find that improves nobody goes in the packs
instead of being sold from under you, and swapping never destroys what was being carried. The
party screen shows what each person carries, what it is worth _to them_, their charms, and the
best few pieces out of the packs with the swing each swap would make — each drawn with its own
icon out of `art/items/`, so the ~70 imported pieces of art are finally on screen.
**Open:** nothing. Consumables are drawn but not usable — that is W-new, not this.

## W16 — Ways in, and ways past

> You go to a location and can't immediately access it — a gate is closed and you have to find
> another way into the city, or find a key. A few characters could use their abilities to get past
> obstacles: a mage with blaze burns a tree out of the way, a character with a water ability swims.

**Not built.** Wants obstacles that read as locks and abilities that read as keys, in both world
and area mode.

**Built for area mode.** [`Ward`](../src/chronicle/ward.gd) is a cell that is shut until somebody
with you can shift it. An area file names it under `wards` with an `ability` and/or a `key`;
walking into it is what tries it, and it opens for anyone in the party who knows that ability or
for a key in `GameState.keys`. Refused, it says what it would take rather than nothing — a locked
door you cannot read is just a wall. Once opened it stays opened, on a flag.

Live example: the gate interior has an iron grate across the arch with a rich chest behind it,
opened by **Crush** or by the warden's key, which is in a footlocker in a keep. Keys come out of
chests (`"key": "gate_key"`) and weigh nothing.
**Open:** nothing in _world_ mode is warded yet — a site you cannot enter until you find the way.

## W17 — A real skill tree

> A lot more moves and power moves that can be learned, passed on, inherited. The move set is very
> limited. Add more powers, skills, proficiencies. Characters should get better at a weapon the
> more they use it. There should be a skill tree you can look at, like Skyrim — level up, choose a
> path, or let the character choose his own path and give them a sense of intelligence.

**Mostly built.** `data/abilities.json` went from 5 to 28, spread across the nine `AbilityGrammar`
themes, including bonus-action moves that cost a beat rather than a turn. Every class grants four
of them, so two callings no longer play the same. The party screen draws every tree a character
has uncovered, its theme, and its three rungs marked taken or locked with reach, splash and weight
spelled out; somebody too low to have one is told which level it arrives at.

Proficiency-by-use is written ([`Proficiency`](../src/chronicle/proficiency.gd), counted on
`Character.practice`) but **has never been played** — see the half-finished note in
[10 — Manual tests](10-manual-tests.md).
**Open:** you still cannot choose a path up a tree — rungs come in order.

## W18 — Backgrounds, origins and alignment

> Every character you choose has one of five different backgrounds they have dealt with. A small
> cinematic for the character you choose — text, or an unspoken story showing the events. Every
> character should come from a different place and start in that zone. Say a character is learning
> from a blacksmith and orcs attack the town and the blacksmith dies, so he carries that grief and
> a hatred toward that species. Characters can be lawful good, lawful evil, neutral, chaotic —
> different personalities. Some don't get along in the party; some work well together.

**Not built.** `data/heroes.json` has a blurb and companions; this wants an origin that decides
where you start, a short cutscene when you pick it, a grudge that changes encounters, and an
alignment that feeds `Character.bonds`.

## W19 — Variety, and more to do at the fire

> A lot more variety on topics of conversation. Every time you start a new game you should be able
> to pick from more than the five presets — label a few as easy, a few as medium, hard, extreme,
> impossible. The campfire dialogue needs a lot more variety and should talk about what has been
> happening on the journey; it's very flat and the characters say the same thing. There should be
> more at the campfire to interact with — chests you can put items into, logs you can sit down on.
> It needs to be a lot more lifelike. Also: characters in a battle feel mismatched, like a lot of
> different people thrown together; group ones that belong together.

**Mostly built.** Banter went from 27 exchanges to 70 and from 19 reflections to 41, weighted at
the campfire — `rest` 5 → 22 and `grave` 1 → 8 — and the new lines lean on the `{deed}`,
`{fallen}` and `{place}` tokens so they talk about the run rather than about nothing. Heroes went
from 5 to 12, sorted gentlest first with their rating on the button, so the easy-to-impossible
labelling reads off the list itself.
**Open:** the campfire has bedrolls, a hammock, braziers, a woodpile and a strongbox now, and
four things to look at, but you still cannot **put** anything into the strongbox — the memo asked
for a stash and it is a chest. The mismatched-warband point is untouched: `Encounter._band_at`
already picks a faction per terrain, so the complaint is probably about gate and tower pools,
which do not.
