# 10 — Who wins? shows

**Looked at 2026-10-16** for `dougie`, who asked what we thought of the fights on a YouTube channel
of fan-made monster battles. The channel is not a game: it posts animated "who wins?" fights, a
full six-against-six of about three minutes and a short cut of each, decided by a simulation of
the two sides rather than scripted. In its first ten days its shorts drew up to about 320,000 views.

**How it was studied.** Full videos could not be downloaded from the cloud box: YouTube refused
every client as a bot, and the download sites tried were either behind a sign-in or refused by the
network. YouTube's own storyboards (the strips of small frames it shows when scrubbing) did come
through: 340 frames across four fights, one every 0.75 to 2 seconds, 160 to 320 pixels wide. What
follows is read off those frames and the videos' descriptions. Nothing from the channel (art,
music, characters, frames) is kept in this repository.

## What the frames show

- **Real time, free movement, top down.** Two creatures at a time on an open floor seen from above,
  moving freely rather than taking turns. Each side's trainer stands at the edge of the field.
  When one falls, the next comes in.
- **The bar along the top.** Each side has a face, a name, its types, a health bar with the number,
  and a row of pips for who is left. The fight's clock sits in the middle.
- **The move, named.** Every move shows its name in a white pill in that side's top corner as it is
  used, and the move is drawn as its own effect: beams, rings on the ground, bursts.
- **Telegraphs.** A thin red line from the attacker to the target before a beam goes off, and a
  ring on the ground before a blow lands there.
- **Words over the fight.** Damage numbers, MISS, a 2 HIT COMBO, NOT VERY EFFECTIVE, an ability
  going off by name, "X FAINTED!", and "Y'S LAST ONE!" as each side gets down to its last.
- **The big hit.** A blow worth a lot, or the last one, cuts to a black screen of speed lines with
  the number in the middle, for a beat.
- **Low health.** The screen's edge goes red on that side.
- **The camera** follows the two and closes in when they are close.
- **The shape of the whole.** A VS card first (two colours, two faces), FIGHT!, the fights, the
  ace kept for last and powered up, K.O.!, then the winner's banner and "WHO SHOULD FIGHT NEXT?
  COMMENT BELOW" held for about ten seconds.
- **Length.** One creature against another runs about 15 to 25 seconds.

## What we took, and what we did not

**Taken**, as the "Who wins?" show ([D180](../06-decisions.md), [18](../18-combat-direction.md#who-wins)):
the VS card, FIGHT!, the bar along the top, the move's name in a corner pill, the red edge, a
burst round a big hit, a camera that keeps both in view, the K.O. in slow motion, and the winner's
banner and the question. All of it is drawn in code over our own fight, with our own sixteen and
their own art.

**Not taken.** The fight itself stays ours. It is already real time on the ground ([D65](../06-decisions.md)),
so nothing about turns needed borrowing. A type chart is rock-paper-scissors, and the sixteen win
in sixteen different ways ([21](../21-the-sixteen-first-draft.md)), so there is no "super effective".
Six-a-side relays need a roster on each side, and the sixteen are one each, so a bout is one
against one.

**Planned, not built** (in the roadmap): the aim line and ground ring before a big move, words for
a signature going off (*Learns Them*, *Set*, *Marked*), and a cut to speed lines on the last blow.
