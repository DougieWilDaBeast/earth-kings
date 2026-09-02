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

**Open:** only reachable from walk mode, not from battle or area mode. Nothing yet reads the
journal back — knowing a thing does not help you fight it.

## W5 — A museum

> A museum you can go through from the title screen, as one of the options. You can access all past
> and existing party members and journeys you have been through, and look at the stats and
> everything they have done, with great depth.

**Built.** [`Museum`](../src/chronicle/museum.gd) writes each finished run to
`user://earth-kings.museum.json` — kept apart from the save, so starting over does not erase the
people who came before. The screen lists journeys newest first, with the one still being walked at
the front, and shows the company's faces, callings, levels and fates beside what the run amounted
to. Reached from the title.

**Open:** a run is only filed when it _ends_, so quitting a run forever leaves it as "still
walking" until it is finished or overwritten. Only forty are kept. No per-person detail beyond the
plaque — the memo asked for "great depth".

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

- **W10a — white boxes.** Textures render as flat white. Confirmed independently while building the
  opening cinematic: `load()`ing a texture _inside_ a `_draw` handler renders it white.
- **W10b — cannot enter named places.** Standing on a village or keep and pressing **E** should
  open the area (`world_scene._walk_into_site`).
- **W10c — the log is too loud.** The world log and the dialogue box take too much of the screen.
  Wants smaller, off to one side, and toggleable.

## W11 — Import the rest of the animations

> Import the animations placed on each character and place them accordingly — idle, walking,
> running, fighting, stance — and implement them correctly onto the characters. In battle they
> should be a lot more noticeable, because when the characters move they seem to just levitate to
> the next tile. I want them to move to that tile.

**Not built.** Only `sworn_blade` has a `run` cycle (see W8). `Unit.walk_path` slides a static
sprite between cells; it should step the run frames while it moves and drop back to idle on
arrival. Needs the remaining PixelLab animation exports.

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

**Partly there already.** Area mode (`src/area/`) is exactly "step into the tile", but only
villages and keeps have one. Wants it for ordinary ground too, and wants what is inside to be worth
the trip. The tournament is the coliseum (W3) placed in the world rather than on the title screen.

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

**Not built.** `Character.equipment` is a single id and `data/equipment.json` exists, but there is
no bag and no screen. Note `art/items/` now holds ~70 icons with nothing drawing them.

## W16 — Ways in, and ways past

> You go to a location and can't immediately access it — a gate is closed and you have to find
> another way into the city, or find a key. A few characters could use their abilities to get past
> obstacles: a mage with blaze burns a tree out of the way, a character with a water ability swims.

**Not built.** Wants obstacles that read as locks and abilities that read as keys, in both world
and area mode.

## W17 — A real skill tree

> A lot more moves and power moves that can be learned, passed on, inherited. The move set is very
> limited. Add more powers, skills, proficiencies. Characters should get better at a weapon the
> more they use it. There should be a skill tree you can look at, like Skyrim — level up, choose a
> path, or let the character choose his own path and give them a sense of intelligence.

**Half built.** `AbilityGrammar` already generates trees onto `world.trees` and `Doctrine` handles
learned passives, but none of it is drawn and there is no proficiency-by-use.

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

**Partly there.** `Banter` has occasions and moods and `Recollection` looks back at the run, but
the pool is small. `data/heroes.json` has five entries and a 1–5 difficulty that is shown but not
used to sort them. `data/areas/camp.json` has a fire and seats but nothing to open or store. The
mismatched-warband point is about `Encounter` picking foes per terrain with no faction coherence.
