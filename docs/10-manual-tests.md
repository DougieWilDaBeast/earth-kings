# 10 — Manual tests

The smoke tests in `tests/` cover logic, data and persistence. They cannot see the screen, hear
the speakers, or press a key. Everything below needs a person.

Run the game with:

```
& "C:\Dev\Godot_v4.7.2-stable_win64_console.exe" --path c:\Dev\earth-kings
```

Mark each line **pass**, **fail** or **not reached**. A fail is worth more than a note — say what
you saw, on which screen, and what you had done just before.

---

## A — Boot and menus

| #   | Do this                                                                      | Expect                                                                                                         |
| --- | ---------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| A1  | Launch the game                                                              | A map pass over a country you have never seen, camera drifting between places, a few figures walking the roads |
| A2  | Wait through the whole cinematic without touching anything                   | The title fades up part-way, then "press anything to go on", then the menu on its own at about twelve seconds  |
| A3  | Launch again and press a key immediately                                     | Straight to the menu, no wait                                                                                  |
| A4  | Hover each menu entry with the mouse                                         | A soft tick on each one, and the keyboard highlight follows the mouse                                          |
| A5  | Click an entry                                                               | A firmer click, distinct from the hover                                                                        |
| A6  | Sit on the title screen                                                      | Quiet music, and your party running across the bottom behind the menu                                          |
| A7  | Look at the crest beside the title with a save present                       | It is the face of the character you are actually playing, not always the swordsman                             |
| A8  | Delete `%APPDATA%\Godot\app_userdata\...\earth-kings.save.json` and relaunch | Continue is greyed out; the founders run along the bottom instead                                              |

## B — Starting a run

| #   | Do this                                                              | Expect                                                                               |
| --- | -------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| B1  | New Game                                                             | Twelve heroes, gentlest first, each with its rating on the button (Steady → Ruinous) |
| B2  | Arrow through them                                                   | Portrait, warband, stats and blurb all change to match                               |
| B3  | Type `12345` in the Seed field and start                             | A run begins                                                                         |
| B4  | Note the world seed in the system menu, start again with that number | The same country, same places, same names                                            |
| B5  | Leave the Seed field empty and start twice                           | Two different countries                                                              |
| B6  | Type letters in the Seed field                                       | Treated as empty; a random country, no error                                         |

## C — The world map

| #   | Do this                                                                | Expect                                                                                       |
| --- | ---------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| C1  | Look at the whole map                                                  | **No white squares** anywhere — every castle, hut, grave, band and party marker is drawn art |
| C2  | Walk about for a hundred steps, watching new bands appear              | Still no white squares as bands spawn                                                        |
| C3  | Read the top-left and bottom-left text                                 | Small, out of the way, not covering the country                                              |
| C4  | Press **L**                                                            | The world log disappears; press again and it comes back                                      |
| C5  | Walk onto a village or keep and press **E**                            | You walk inside                                                                              |
| C6  | Walk onto a **library, hut, gate, Tower or your Home** and press **E** | You walk inside — all five have interiors now                                                |
| C7  | Press **E** on open ground                                             | "There is nothing here to walk into", not silence                                            |
| C8  | Press **N**                                                            | The Journal opens                                                                            |

## D — The five new interiors

Walk each one end to end. For **library, hut, gate, tower, home**:

| #   | Do this                         | Expect                                                                    |
| --- | ------------------------------- | ------------------------------------------------------------------------- |
| D1  | Look at the floor               | Readable, not near-black, and the floor runs continuously to the door     |
| D2  | Walk to the exit                | You come back out onto the world map where you left it                    |
| D3  | Stand near each person          | They mutter to themselves in a speech bubble; background folk have no "!" |
| D4  | Open every chest                | Gold, and sometimes an item, each only once                               |
| D5  | Press **E** on the marked spots | A line of description                                                     |
| D6  | Walk into the props             | Nothing traps you in a corner or blocks the only route out                |

## E — Battle

| #   | Do this                                                                                         | Expect                                                                    |
| --- | ----------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| E1  | Move Bram (the Sworn Blade) several tiles                                                       | He **runs** — legs moving — rather than sliding                           |
| E2  | Move him around a corner                                                                        | He turns to face each leg of the path as he takes it, not only at the end |
| E3  | Move any other unit                                                                             | They slide as before, standing pose, no flicker or blank sprite           |
| E4  | Reach level 2 and pick a class                                                                  | Four abilities in the command menu, not one                               |
| E5  | Use a bonus-action move (Riposte, Spark, Shield Bash, Dart, Firebrand, Stand Fast, Second Wind) | It spends the bonus, and the main action is still available               |
| E6  | Use the same move about twelve times across several fights                                      | "_X_ is practised with _Y_ now." and it starts hitting a little harder    |
| E7  | Check a healer's Mend after heavy use                                                           | Heals more than it did at the start of the run                            |
| E8  | Kill a kind of enemy nobody has killed before                                                   | "_X_ learns from the _Y_." and experience; the next one of that kind gives none |
| E9  | Fight the same kind five times with someone who never lands the blow                            | On the fifth, "_Z_ has helped with enough _Y_ kills to learn from them."  |
| E10 | Beat a gate's guardian or the Tower's apex fighter                                              | Everyone still standing "learns from" it, not only the killer             |
| E11 | Open **P** → Practice after a few fights                                                        | An **Arms** line for the weapon in hand, and **Learned from** listing the kinds, with assists part-way |
| E12 | Take an errand, then **P** → a companion → Practice → **Send**                                  | They leave the cards; the header says "1 away"; an **Away** line counts the steps                |
| E13 | Walk until they are due                                                                         | Notices on the map: word from the place, maybe a meeting on the road, then "is back with the company" |
| E14 | Try to send the lead, or the last companion beside them                                         | No button, and a line saying why                                                                |

## E2 — Real-time skirmish (M11 prototype)

Title → **Training** → pick an enemy → **Fight in real time**. Or, from the bench:
`godot --path . res://tests/bench.tscn -- --scene=skirmish --play`.

| #    | Do this                                                     | Expect                                                                                   |
| ---- | ----------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| RT1  | Open the fight                                              | It starts **paused**, the whole field is visible above three party cards                 |
| RT2  | Right-click the ground with someone selected, still paused  | A line to where they are going; nothing moves until **Space**                            |
| RT3  | Press **Space**                                             | Everyone moves at once. Melee close in; ranged units keep their distance                 |
| RT4  | Right-click an enemy                                        | The selected unit goes after that enemy and nobody else                                  |
| RT5  | Select a unit, press **Q**, left-click an enemy             | A red range shows first; the unit walks into reach, a cast bar fills, the skill lands, and its card counts the cooldown down |
| RT6  | Press **A** on a unit                                       | "auto" leaves its card, and it stops using skills on its own                             |
| RT7  | Press **H** on a unit                                       | "hold": it stops walking to fights and only hits what is already in reach              |
| RT8  | Let a party member drop                                     | "is down — 12 seconds", a red ring counting down under them                              |
| RT9  | Right-click the downed ally with another selected           | They walk over, kneel, and after two seconds the ally is back up at a quarter of their health |
| RT10 | Press **T** during the fight                                | x1 → x2 → x4 → x1, and the fight plays at that pace                                      |
| RT11 | Win or lose                                                 | Victory or Defeat, and after two seconds you are back at the training ground             |
| RT12 | Go back to the run afterwards                               | **Your real party is untouched** — nothing from the skirmish is written back             |
| RT13 | Let someone go down with auto-pause at its default          | The fight pauses itself: "Paused." after "_X_ is down"                                    |
| RT14 | Press **Z** twice, turn **A** off on a unit, use its skill  | When the skill comes back the fight pauses: "Paused. _X_'s _Y_ is ready."                |

## F — Party menu (**P**)

Two panes: the party as a column of cards down the left, and one of them at a time opened out on
the right under Gear, Powers and Practice. Every target is sized for a thumb.

| #   | Do this                                                | Expect                                                                                                |
| --- | ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| F1  | Open it                                                | A card a person: face, name, level and calling, and a health bar that is green, amber or red          |
| F2  | Press a card, anywhere on it                           | The right-hand pane opens that person; the card is the only one with a lit edge                       |
| F3  | Tab through the cards with a keyboard                  | The pane follows the focus — keyboard and thumb point at the same card                                 |
| F4  | Press ▲ / ▼ beside a card                              | They swap places in the marching order; the arrows are dead at the top and bottom of the line          |
| F5  | Look at a card for somebody owed a class or a power    | An amber edge and one line saying which                                                                |
| F6  | Gear page, look at any row in the packs                | `Atk 29 → 31` and `Grd 12`, each coloured on its own — armour that buys guard with attack says both     |
| F7  | Open the lead's gear page carrying nothing             | Worn names the blade their template came issued with, not "nothing" — and the swaps are measured against it |
| F8  | Equip that piece                                       | The numbers land where the row said they would, and what they were carrying goes into the packs — **nothing is destroyed** |
| F9  | Give a longbow ranger a Sworn Blade piece              | "wrong hands" in the summary, and a visibly worse change than giving it to the swordsman               |
| F10 | Press **Optimise**                                     | The best piece in the packs goes on in one press; the button then greys out                            |
| F11 | Press **Optimise** with nothing better in the packs    | Already greyed, and says so when held                                                                  |
| F12 | Stow a piece                                           | They carry nothing; the piece is in the packs                                                          |
| F13 | Food and physic, on somebody unhurt                    | "Nothing to mend."                                                                                     |
| F14 | Powers page at level 5                                 | A tree block: name, theme, and three rungs marked ■ taken / □ locked                                    |
| F15 | Powers page below level 5                              | Told which level the first path arrives at                                                             |
| F16 | Powers page with a power owed                          | The next rung of every uncovered tree becomes a **Take** button                                         |
| F17 | Practice page                                          | What they have read, every move with its proficiency, and who they can teach                           |
| F18 | Level somebody to 2                                    | A path to choose, on the card and at the head of the pane, until it is answered                        |
| F19 | Save, quit, load                                       | Gear, packs, practice, trees and the marching order all exactly as they were                           |

## G — Gates and the Tower

| #   | Do this                                   | Expect                                                                                        |
| --- | ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| G1  | Step onto an open gate                    | A fight, and the log says which floor of how many                                             |
| G2  | Win the first floor of a multi-floor gate | You are told there is more below, and the gate is **not** shut yet                            |
| G3  | Walk off the gate mid-delve               | You keep what you found; going back in starts at the top again                                |
| G4  | Clear the last floor                      | The gate shuts and pays out                                                                   |
| G5  | Lose a floor                              | You are put out; the gate stays open                                                          |
| G6  | Climb a Tower floor                       | The gold is a **hoard**, not in your purse — "you are carrying N out of here, if you get out" |
| G7  | Climb a second floor without leaving      | The hoard grows, and you are warned what you stand to lose                                    |
| G8  | Walk off the Tower step                   | "You walk away from the Tower with N gold" and the purse goes up                              |
| G9  | Lose a floor while holding a hoard        | The hoard is gone                                                                             |

## H — Conversation and the camp

| #   | Do this                                                          | Expect                                                                                  |
| --- | ---------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| H1  | Walk the road for a few hundred steps                            | Party banter in the log and in a bubble over the marker, varied, not the same two lines |
| H2  | Rest until you reach the camp, and press **E** on each companion | A different exchange each time, and only one each per fire                              |
| H3  | System menu → toggle **Chatter**                                 | It reads "Chatter: in the log"                                                          |
| H4  | Walk and rest again with Chatter off                             | Banter still happens, but in the log and bubbles — the dialogue box never opens for it  |
| H5  | Talk to a townsfolk NPC with Chatter off                         | The dialogue box **does** open — authored conversation is never demoted                 |
| H6  | Visit a grave                                                    | Something is said about who is buried there                                             |
| H7  | Quit and relaunch                                                | The Chatter setting is remembered                                                       |

## I — Journal (**N**)

| #   | Do this                                                          | Expect                                                             |
| --- | ---------------------------------------------------------------- | ------------------------------------------------------------------ |
| I1  | Open it at the very start of a run                               | Empty, and it says so                                              |
| I2  | Fight a goblin, then open it                                     | A goblin page, mostly question marks                               |
| I3  | Look at Reach / Guard / Constitution before doing anything to it | All `?`                                                            |
| I4  | Be hit by one                                                    | Reach fills in                                                     |
| I5  | Hit one                                                          | Guard fills in                                                     |
| I6  | Kill one                                                         | Constitution fills in                                              |
| I7  | Watch one cast something                                         | That ability is named; the rest stay "something you have not seen" |
| I8  | Fight in the Training Ground, then check                         | **Nothing** was written down                                       |

## J — Coliseum

| #   | Do this                                                     | Expect                                                                  |
| --- | ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| J1  | Title → Coliseum                                            | Champion list, four cards, and the best night recorded per card         |
| J2  | Pick and Go out                                             | A fight on the sand                                                     |
| J3  | Win                                                         | Round cleared, purse paid, and a choice: next round or take the purse   |
| J4  | Take the next round wounded                                 | You are **not** fully healed — wounds carry between rounds              |
| J5  | Lose a round                                                | "They carry you off", the rounds and purse are recorded, and it is over |
| J6  | Retire with a purse, then look at the card again            | The best night shows your run                                           |
| J7  | Go to the Coliseum mid-run, then Back to Title and Continue | **Your real party is untouched** — same people, same HP, same gold      |

## K — Museum

| #   | Do this                         | Expect                                                                 |
| --- | ------------------------------- | ---------------------------------------------------------------------- |
| K1  | Title → Museum with no history  | "Nothing here yet"                                                     |
| K2  | With a run in progress          | It is at the front, marked "Still out there"                           |
| K3  | Let a run end, then open it     | The finished run is listed with the date and its whole company         |
| K4  | Click a journey                 | Faces, callings, levels, who died, and the run's numbers               |
| K5  | Start a new run and check again | The old company is **still there** — starting over does not erase them |

---

## Known to be untestable here

- **W2** — the voice line at the end of the cinematic. The memo cuts off before saying what the
  voice says, so there is nothing to test.
- Anything needing the other 68 units' run cycles (**E3** will stay "slides" until that art lands).

## What a fail should include

The screen, the seed (system menu shows it), what you pressed, and what you expected instead.
A screenshot of a white square or a broken layout is worth a paragraph of description.

---

## The bench

Rather than starting a run and playing to the point of concern, boot straight into it.
`ek.ps1` wraps it; `--play` and `--shot` need a real renderer, so it drops `--headless` for those.

```powershell
.\ek.ps1 --scene=world --at=gate --level=6 --gold=800 --play   # hands-on, at that point
.\ek.ps1 --scene=party --level=6 --stores=steel_blade,halo_robe --shot
.\ek.ps1 --list=sites            # sites areas units abilities equipment heroes classes
.\ek.ps1 test                    # every smoke suite, one line each
```

State flags: `--seed --hero --level --gold --at --steps --floor --hoard --stores --equip --hurt`.
Scenes: cinematic title character_select world area battle training coliseum museum summary,
plus the overlays party journal menu. `--scene=area` takes `--area=id`.

`.\ek.ps1 --help` prints the lot.

## Testing backlog — paused

Automated testing is **parked**. It was costing more than it caught on this machine, and the
suites had started failing on their own stale expectations rather than on real regressions.
Issues come from playing the game and saying what broke. Picked back up when it is worth it:

- **Split the monoliths.** `walk_smoke_test.gd` is ~760 lines running ~20 checks off one seeded
  world; there is no way to run just the one you care about. Wants `--check=name` on the bench.
- **Seeded tests pin step counts and cell positions**, so W12's bigger world will invalidate
  `walk`, `world` and `skein` wholesale. Budget the rewrite with that work, not before it.
- **Nothing covers the screen.** Every visual check in this document is a person's eyes. The
  bench can photograph any scene now, so image comparison against a stored reference is possible
  and is not built.
- **Difficulty leaks into assertions.** Anything checking enemy counts or XP has to pin
  `GameState.difficulty = "even"` first, or `gentle` (3× XP, −1 enemy) fails it. Easy to forget.

## Completed integrations

Both previously flagged systems were integrated and verified:

- **Multi-floor delves (M5)** — `Encounter.for_gate` runs gates across scaled depth levels, shut
  only upon conquering the final floor, with intermediate floors awarding charms, doctrine, and
  branching tree unlocks (rank C+).
- **Proficiency by use (W17c)** — `src/chronicle/proficiency.gd` tracks practice through
  `battle.gd`, `ability_resolver.gd`, and `character.gd`, rewarding mastery titles and display on
  the party screen.
