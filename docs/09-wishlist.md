# 09 — Wishlist

Spoken notes dropped into `DROP-ZONE/` as voice memos on 2026-08-31, transcribed and kept here so
the intent survives the audio. Each is the note as given, then what was done about it.

Order is the order they were recorded, not priority.

---

## W1 — A cinematic before the title screen

> There should be a small cinematic animation for when you enter Earth Kings. A short overview of
> the existing map, showing different locations and vibrant buildings and characters running
> around. The Earth Kings title appears, and you press enter to go into the title screen.

**Not built.** Wants a camera pass over a generated world with actors on it — most of which
`world_scene` already draws. The honest version is a scene that generates a world, walks
`CameraRig.focus_on` between a few sites, and hands over to the title on any key.

## W2 — A voice at the end of the cinematic

> When the cinematic ends for Earth Kings, a character's voice should say —

**Blocked.** The memo cuts off before saying what the voice says. Needs the line.

## W3 — A coliseum

> A Colosseum or gladiator battle and training ground. Pick a character and pick whoever you want
> to battle against — or pick a character of your choosing and fight waves of coliseum members.
> Or have a party, and that party fights four other parties: not just party versus party, but
> party versus party versus party versus party. You gain rewards for it. A separate system to the
> Earth Kings main storyline.

**Not built.** Note that [`src/training/`](../src/training/) already does "pick a character, pick
who you fight" against one enemy band. The new parts are waves, free-for-all with more than two
sides, and rewards that carry — and `Battle` currently assumes two sides.

## W4 — A journal

> Every new encounter with characters, you start to write down different abilities that they use,
> what kind of creature they are, where they were spotted. When you insert a character into the
> journal it has question marks for abilities, stats, what they can do, until they reveal them to
> the player, and then they are jotted down.

**Not built.** Close cousin of the Codex. Wants a per-template record on `World` that fills in as
a unit is _seen doing_ a thing, rather than on first sight.

## W5 — A museum

> A museum you can go through from the title screen, as one of the options. You can access all past
> and existing party members and journeys you have been through, and look at the stats and
> everything they have done, with great depth.

**Not built.** `Ledger`, `Memorial` and `Character` already hold most of what it would show; what
is missing is that none of it outlives the run.

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
