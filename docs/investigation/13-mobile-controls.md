# 13 — How other mobile games do touch, and what Earth Kings could take

2026-10-22. Asked by Will: "review what controls could be good for mobile based on what you see in other games on mobile ... take it as a big research project and figure out what we might be able to implement."
Follows the PC versus phone review (the project's `reviews/phone-vs-pc/2026-10-22-phone-vs-pc.md`) and call CD (PC first, a small phone-basics pass now, the full phone design after 1.0, sideways the main way). Grounded in main `071cfec` (after #495). Decision [D379](../06-decisions.md), agenda row 283 ([answers](../worldbuilding/answers.md#what-is-still-to-decide)). **Inferred**: the ranked list and the decisions at the end are proposals for `dougie`; nothing here is settled or built.

## The short answer

Seventeen games looked at, across tactics, roguelikes, strategy, action RPGs and auto-battlers. The ones that play well on a phone all do the same few things, and Earth Kings already does some of them:

1. **Tap the board, then tap what to do.** Pick a unit, tap where or whom. No hover, no right-click. We already do this in fights.
2. **Long press tells you what a thing is.** It stands in for the mouse hover the phone doesn't have. **We don't have this, and it's the biggest gap.** On a phone you tap blind.
3. **Time stops or slows while you decide.** FTL pauses when you pick crew. Bad North slows to a crawl when you pick a squad. Our real-time fights ask a phone player to pick and order at full speed.
4. **Preview, then confirm.** Into the Breach, XCOM and Divinity show what an order will do before it happens, and confirm with a second tap or a button, never a double-tap.
5. **Few buttons, and they change with what you're doing.** One Act button that says what it will do. Skills that show their names and pictures, not keyboard letters.
6. **Auto is a first-class way to play.** Auto-hit in Dead Cells, auto-attack in Stardew, the whole of Vampire Survivors, and the Auto and 2x buttons of every phone RPG. Our Auto is already one of the game's best things on a phone.
7. **Big targets.** Apple says 44 points at least and Google says 48. Our fight buttons are 40 game pixels tall, which is about **30 points** on a phone. The touch bar's 62 (about 47 points) is right.

So the cheapest big win isn't more buttons. It's **long press for info, pause while picking, aim then confirm, and bigger fight buttons with real names.** That's four or five small PRs, all inside the fight and the touch overlay, none of them changing the PC game. Dragging, a radial on a fighter, layout settings and a native app are the after-1.0 phone design.

## What we have today (for comparison)

- **Walking:** a fixed stick bottom left, Act, Back and Next bottom right, and a top bar of Party, Book, Auto, Speed and Menu (`src/ui/touch_controls.gd`). The place's own doings (shops, talk, Strike first) are buttons in an act bar (D374). Tap the ground to walk works through the mouse the engine fakes from touch. Pinch zooms.
- **Fights:** tap a fighter to pick, tap a cell or foe to order, and a column of ten buttons down the right: Pause, Speed, All, Q, W, E, R, Auto skills, Hold, Auto-pause (`src/skirmish/skirmish_hud.gd`, `TOUCH_BUTTONS`). A tap is the whole order: no drag-box on touch.
- **Being built by "Phone versus PC behaviour" now (D375 to D378):** the stick aside in fights, a More button that opens the quick wheel, the corner map and tip cards below the touch bar, phone words in tips and hints, and the journal fitting upright. Nothing below repeats those.

## What the games do

Grouped by kind. "Take" says what fits us. Items marked *(my knowledge)* are from playing and reading about the game before today, not checked against a source today.

### Tactics on a grid, turn based

**Into the Breach** (Netflix, phones and tablets). Tap a mech to show its move range, tap a tile to move, tap a weapon and every tile shows what the shot will do, including where things get pushed, before you commit. Moves can be undone until you attack. Reviewers call the touch controls tight even on a crowded board, and the layout switches between touch and pad as you use them. Interface scaling is a setting.
*Take:* the preview. When a skill is armed, show its reach and who it will hit before the tap that fires it.

**XCOM: Enemy Unknown / Enemy Within** (iOS, Android). Tap a soldier, tap a tile, confirm with a second tap or a button. The review's one complaint: a finger hunting for the confirm button nudged the destination. The interface was rebuilt for touch rather than shrunk.
*Take:* confirm with a fixed button, away from the board, so the thumb doesn't drift the target.

**Fire Emblem Heroes** (phones, played upright). Drag a unit to a blue square to move, or drag it onto a foe to move and attack in one go. That drag can't be taken back, while the tap way lets you change your mind before you confirm. Holding a finger on a foe shows its reach in red. A Danger Zone button shows every foe's reach at once, and a setting turns it on from the start.
*Take:* hold on a foe to see its reach, and a Danger button. Drag-to-order is worth having later, with a tap way kept for the careful.

**Darkest Dungeon** (iPad, then phones) *(my knowledge)*. Tap a hero's skill, then tap a target; valid targets light up. Long press anything for its tooltip. Big icons along the bottom, the party on the left, foes on the right.
*Take:* light up who a skill can reach once it's armed.

### Tactics in real time with pause (closest to our fights)

**FTL: Faster Than Light** (iPad). The game pauses itself when you pick a crew member or the door controls, and you can pause any moment. Drag a box to pick several crew. Drag on the power bars to move power. Tap the enemy ship and it grows bigger to aim at. A "return to stations" button gathers the crew.
*Take:* pause on pick. And "All" (which we have) is FTL's drag box done as a button, which is right for a thumb.

**Bad North** (phones). Tap a squad, tap where it should go; it fights by itself when it gets there. When you pick a squad in a busy moment, everything slows right down to give you time. Turning the island with a finger feels natural.
*Take:* slow time, not only stop it, while a fighter is picked. It keeps the fight feeling alive. Fighters already fight on their own like Bad North's squads.

**Baldur's Gate: Enhanced Edition** (iPad, phones). Tapping replaced the hotkeys. Reviewers' main complaint: doors and corpses were too small to tap, and they had to pinch in to hit them. Called "a flawed but admirable port of a game that isn't touch friendly".
*Take:* the warning. A PC-made real-time-with-pause game on a phone needs forgiving taps (snap to the nearest thing), or players pinch all day.

**Divinity: Original Sin 2** (iPad). The best written-up port. No hover, so **long press on anything shows its info**, added just for the iPad. Each action is either a gesture or a button, not both. Some of the HUD was hidden to cut clutter. A **magnifying glass** shows what's under your finger when aiming. They chose a **confirm button over double-tap** to cast, and play-tests backed it. Every element was resized for a finger; nearly every window was redone rather than copied from PC. Hints teach the gestures.
*Take:* nearly all of it: long press for info, confirm button, bigger everything, and a hint that teaches the long press.

**Baldur's Gate 3** (pads, not phones). Radial menus at a trigger's pull for the map, journal, spellbook and the rest.
*Take:* the quick wheel (D326) is the same idea; the phone-basics pass puts it on a More button. Later, a ring on a long-pressed fighter for their own things.

### Roguelikes and card games

**Slay the Spire** (phones and tablets). Two ways to play a card: tap it then tap a target, or drag it onto one. Reviewers' complaints are about those two fighting each other: a tap read as a drag and played the card by accident, a cancel that spent the card. Text too small on a phone.
*Take:* pick one way per thing, or make sure the two can't be confused. Don't let a drag that was meant as a camera move become an order.

**Shattered Pixel Dungeon** (phones, upright) *(my knowledge)*. Tap a tile to walk or attack, tap again to keep going. Quick slots along the bottom. Long press an item or a tile for what it is. A search button and a wait button are big and always there.
*Take:* the "the whole game on six buttons and taps" lesson. Our walking already nearly is that.

**Dead Cells** (phones). Every button can be moved and resized. A floating stick, or a fixed one. Swipe to dodge. An **Auto-hit** mode swings at anything near. Pads supported.
*Take:* a floating stick (put a thumb down anywhere bottom left), and button size as a setting.

**Vampire Survivors** (phones). One thumb: attacks are automatic, you only move. Upright or sideways, your choice. The reviewer's complaints: a virtual stick is never as good as a real one, and the thumb hides the action.
*Take:* keep the thumb off the middle of the board; the phone-basics pass already moves the stick aside in fights.

### Action RPGs

**Diablo Immortal** (phones). Stick left, the basic attack in the middle of a ring of skills on the right. A skill tapped goes at the nearest foe. Held, it shows its path and you drag to aim, and letting go casts it. Reviewers found aiming hard mid-fight.
*Take:* tap a skill to aim it at the picked fighter's target by default, so most casts need no aiming. Hold-and-drag aiming after 1.0.

**Genshin Impact** (phones). Stick left, attack, skill and burst right, a party strip on the right edge to swap who you play, and an interact prompt that pops up by the thing you're next to and says what it does. The layout can't be moved.
*Take:* the interact prompt: our Act button should say "Talk", "Climb", "Open" rather than "Act".

**Stardew Valley** (phones). Several control schemes in a drop-down: tap to move with auto-attack (the default), tap to move plus an attack stick, an invisible stick on the left half with two buttons, and more. Hold a tool button to keep using it. Players' favourite for beginners is tap to move plus stick, with auto-attack on.
*Take:* tap to walk and the stick side by side (we have both), and a schemes setting later.

### Strategy and auto-battlers

**Teamfight Tactics** (phones). Drag champions between the bench and the board, drag items onto champions to preview, equip and combine. Tap a shop champion to buy. Tap a unit for its stats. A toggle swaps the left panel between traits and items.
*Take:* drag a draught or a piece of kit onto a party card (after 1.0). Tap a card for the full card.

**AFK Arena, Raid and most phone RPGs** *(my knowledge)*. Auto and 2x or 3x on every fight, skills fire on their own unless you tap a hero's portrait to fire theirs. The player's job is the line-up before the fight.
*Take:* we already have Auto, Speed and Auto skills; on a phone those are the default way most people will fight, so they should sit first and biggest.

**RimWorld** (no phone version). The Steam Deck update refined the touch interface. No phone colony sim in this style was found to copy.
*Take:* none directly; it's a sign that big-menu PC games get to touch by pad and Deck first.

## What works and what doesn't

Works, in nearly every game that plays well on a phone:

- **Select, then act**, both by tap.
- **Long press = info** (Divinity, Fire Emblem Heroes, Darkest Dungeon, Pixel Dungeon).
- **Time to think**: turns, or pause and slow-down on pick (FTL, Bad North).
- **Preview before commit** (Into the Breach, Divinity, XCOM).
- **A confirm button, not a double-tap** (Divinity's play-tests; XCOM's finger drift).
- **One context button that names what it does** (Genshin, Stardew).
- **Auto, and speed-up** (Dead Cells, Stardew, Vampire Survivors, every phone RPG).
- **Big targets and fewer of them**, the HUD trimmed (Divinity).
- **Settings for size and layout** (Dead Cells, Into the Breach, Stardew).

Doesn't work, or needs care:

- **Two ways to do the same thing that can be mistaken for each other** (Slay the Spire's tap and drag).
- **Double-tap to confirm** (rejected by Divinity's play-tests).
- **Small things on the board that must be hit exactly** (Baldur's Gate EE: pinch to zoom just to loot).
- **Aiming by dragging in a hectic real-time fight** (Diablo Immortal's reviewers).
- **Hold-to-drag** that waits before the drag starts (Divinity: too slow).
- **A thumb parked over the action** (Vampire Survivors).

## The browser's limits (we're a Godot web build on itch)

- Godot turns touches into mouse clicks on the web whatever the setting, so a drag can be read as both a camera drag and a press; Godot's own pan, pinch and double-tap gestures were reported not to fire in a phone browser (Godot forum, 4.3 to 4.7). **Long press and drags we'd write ourselves from raw touches**, as `touch_controls.gd` already does for the stick. That's fine and testable.
- Vibration works in Chrome on Android, not on an iPhone. A buzz on a hit or a skill ready is cheap but Android only. (Whether Godot's `vibrate_handheld` reaches the browser is still to check.)
- An iPhone browser has no real full screen, and the notch's safe area isn't read in the browser (memory, D163). That's an argument for the native app BN already puts after 1.0.

## What Earth Kings could build, ranked

Cost is rough: S is one small PR (half a day of thread time), M one bigger PR (a day or two), L several PRs. None of the "now" list changes the PC game.

### Now: a second small touch pass, after the phone-basics PRs land

| # | What | From | Cost | Why it's high |
|---|---|---|---|---|
| 1 | **Long press shows what hover shows.** On a fighter or foe: their full card. On a fight button or skill: its tooltip. On the ground: the label of the person, door or thing. On a map tile: its name. A one-time tip teaches it. | Divinity, Fire Emblem Heroes, Darkest Dungeon | S to M | A phone has no hover, so today a phone player can't read anything before pressing it. Helps trying things, which is Will's complaint. |
| 2 | **Pause or slow while a fighter is picked, on touch.** A new Auto-pause setting, "When I pick", on by default on touch: the fight drops to a crawl (say 0.25x) while someone is picked and goes on when the order is given or the pick dropped. Off on PC unless chosen. | FTL, Bad North | S | Real time is the hardest part of our fights on a thumb. This keeps the fight alive and gives time to think. |
| 3 | **Aim, then confirm, for skills.** Armed, a skill lights up who and where it can reach and who it would hit. The first tap on a target shows the preview; a second tap on the same target, or a big Cast button, fires it. Tapping the skill again cancels (as now). | Into the Breach, Divinity, XCOM, Darkest Dungeon | M | Stops the misfires a small screen causes and teaches what a skill does. |
| 4 | **Fight buttons big enough, with names.** Raise fight buttons from 40 to about 60 game pixels (30 to 45 points). Skill buttons show the picked fighter's skill name and picture with its cooldown sweep, not Q/W/E/R. Fighter-only buttons (skills, Hold, Auto skills) show only while someone is picked, which leaves room to make them bigger. | Apple and Google guides, Divinity, Genshin | S to M | Below 44 points a thumb misses. Letters mean nothing on a phone. *Check with "Phone versus PC behaviour": the phone-words PR may already rename Q/W/E/R.* |
| 5 | **Forgiving taps.** A tap in a fight picks the nearest fighter within about half a cell, not only the exact cell; on the ground, the nearest person or door. | Baldur's Gate EE's lesson | S | Less pinching to hit things. |
| 6 | **Act says what it does** ("Talk", "Climb", "Open", "Trade"). | Genshin, Stardew | S | One button, no guessing. |
| 7 | **Hold on a foe to see its reach, and a Danger button** that shows every foe's reach. Also good on PC (as a key). | Fire Emblem Heroes, Into the Breach | M | A real tactics aid on both, not just a phone fix. |
| 8 | **A floating stick**: put a thumb down anywhere in the bottom-left third and the stick centres there. A setting, fixed stays the default. | Dead Cells, Stardew | S | Fewer missed starts. Lower than the fight items because walking already works. |

Items 1 to 4 are the ones worth doing now. Five to eight are cheap and can follow, or wait.

### After 1.0: the full phone design (with the phone release, BN)

| # | What | From | Cost |
|---|---|---|---|
| 9 | **A fight HUD made for thumbs**: party portraits along the bottom as the picker (tap to pick, tap twice to centre the camera), skills in a ring by the right thumb, Pause, Speed and Auto biggest and first. | Genshin, Diablo Immortal, phone RPGs | L |
| 10 | **Drag orders**: drag a party portrait onto a foe to set them on it, or onto a cell to send them there. Tap orders stay. | Fire Emblem Heroes, TFT | M |
| 11 | **Drag a skill to aim**: hold a skill, drag onto the board to aim, let go to cast, drag back onto the button to cancel. | Diablo Immortal | M |
| 12 | **A ring on a long-pressed fighter**: stance, Hold, Auto skills, a draught, the full card. The quick wheel, per fighter. | BG3, Ark (D326) | M |
| 13 | **Drag a draught or kit onto a portrait** in a fight and on the party screen. | TFT | M |
| 14 | **Control settings**: button size, left-handed (swap sides), fixed or floating stick, Auto-pause on pick, haptics. | Dead Cells, Stardew, Into the Breach | M |
| 15 | **Screens laid out for a phone**: bottom sheets and tabs instead of PC windows, text at 16 points, one thing per screen. Upright as a second layout. | Divinity (redid nearly every window), Vampire Survivors (both ways round) | L |
| 16 | **A native Android app**: real full screen, the notch respected, haptics, a lighter download, cloud saves with Steam. | BN, the browser's limits above | L |
| 17 | **A "watch and steer" way to play**: Auto plays, and the game puts the choices that matter in front of you as cards (a band ahead: fight, go round, strike first). | Phone RPGs, Bad North | L |

## Decisions for Will

1. **A second small touch pass now, after the phone-basics PRs**: long press for info, pause-or-slow while picking a fighter, aim then confirm for skills, and bigger fight buttons with skill names (items 1 to 4, about four small PRs, nothing changes on PC). ★ *Recommended.* The alternative is to hold all of it until after 1.0 as CD said for the "full design".
2. **On a phone, picking a fighter slows the fight to a crawl (not a full stop)** until the order is given, on by default on touch, off on PC. ★ *Recommended: slow.* The alternative is a full pause like FTL.
3. **Skills on a phone fire on the second tap or a Cast button, never a double-tap**, after showing who they'll hit. ★ *Recommended.*
4. **Dragging (portraits onto foes, skills onto the board, draughts onto cards), the per-fighter ring and control settings wait for the after-1.0 phone design.** ★ *Recommended.* The alternative is to start with dragging now.
5. **Danger zones (see a foe's reach) on PC and phone both**, as a later item for the fights, not part of the phone work. ★ *Recommended: yes, queue it after the touch pass.*

If Will pastes apps he likes the controls of, they go into this list, mostly for the after-1.0 design.

## Sources

- Into the Breach on mobile: [Gizmodo](https://gizmodo.com/best-netflix-games-of-2024-1851413576/17), [TouchArcade](https://toucharcade.com/?p=295323), [Steam discussion on undo and preview](https://steamcommunity.com/app/590380/discussions/0/2650805212053351822/?ctp=2), [Gamepressure guide](https://www.gamepressure.com/into-the-breach/beginners-guide-tips/zfaa76)
- Divinity: Original Sin 2 on iPad: [Game Developer, "Adapting DOS2 for iOS"](https://www.gamedeveloper.com/game-platforms/in-depth-adapting-divinity-original-sin-2-definitive-edition-for-ios), [TechRadar](https://www.techradar.com/news/divinity-original-sin-2-is-now-on-ipad-pro-heres-what-its-like-to-play)
- Baldur's Gate 3 radial menus: [PlayStation Blog](https://blog.playstation.com/2023/09/05/how-baldurs-gate-3-adapts-its-expansive-rpg-gameplay-for-your-dualsense-controller/)
- Baldur's Gate EE on iPad: [iMore](https://www.imore.com/baldur-s-gate-enhanced-edition-ipad-review-its-thac0-time), [TouchArcade](https://toucharcade.com/?p=121540), [Android Authority](https://www.androidauthority.com/baldurs-gate-enhanced-edition-review-379882/)
- XCOM on iOS: [Shacknews](https://www.shacknews.com/article/79824/mobile-review-xcom-enemy-unknown), [Inverse](https://inverse.com/article/17459-the-mobile-port-of-xcom-enemy-within-is-the-best-version-of-the-original), [MobileSyrup](https://mobilesyrup.com/2014/11/13/xcom-enemy-within-now-available-for-ios-and-android/)
- Fire Emblem Heroes: [Twinfinite](https://twinfinite.net/guides/fire-emblem-heroes-move-how-to/), [Gameranx](https://gameranx.com/features/id/91653/article/fire-emblem-heroes-10-tips-to-get-started-right-beginners-guide/), [official settings guide](https://new-guide.fire-emblem-heroes.com/en-GB/feh-3540.html)
- FTL on iPad: [TidBITS](https://tidbits.com/2014/04/11/funbits-ftl-faster-than-light-moves-to-ipad/), [Digital Trends](https://qa2.www.digitaltrends.com/gaming/ftl-faster-light-advanced-edition-review), [Game*Spark](https://www.gamespark.jp/article/2014/03/22/47248.html)
- Bad North: [Stuff](https://www.stuff.tv/?p=1527), [Ladies Gamers](https://ladiesgamers.com/bad-north-jotunn-edition-review-nintendo-switch/)
- Slay the Spire on mobile: [The Sixth Axis](https://www.thesixthaxis.com/2021/03/03/slay-the-spire-mobile-review/), [App Unwrapper](https://www.appunwrapper.com/2020/06/13/slay-the-spire-ios-review/), [TouchArcade forum](https://toucharcade.com/community/threads/slay-the-spire-by-megacrit-humble-bundle.409572/page-5)
- Dead Cells mobile: [TouchArcade](https://toucharcade.com/2019/05/07/dead-cells-mobile-blog-post/), [Siliconera](https://www.siliconera.com/dead-cells-heads-to-smartphones-with-a-new-mobile-friendly-interface/)
- Vampire Survivors mobile: [Common Sense Media](https://www.commonsensemedia.org/app-reviews/vampire-survivors), [WhistleOut](https://www.whistleout.com/CellPhones/Apps/vampire-survivors-app-review)
- Diablo Immortal: [TechRadar](https://www.techradar.com/news/ive-played-diablo-immortal-how-blizzards-dark-action-rpg-plays-on-smartphones), [Shacknews](https://www.shacknews.com/article/130623/diablo-immortal-preview), [Den of Geek](https://www.denofgeek.com/?p=765843)
- Stardew Valley: [Stardew wiki, Mobile Controls](https://stardewvalleywiki.com/Mobile_Controls), [TouchArcade](https://toucharcade.com/2018/11/01/stardew-valley-mobile-controls-update/)
- Genshin Impact: [TouchTapPlay](https://www.touchtapplay.com/genshin-impact-mobile-controls-and-settings/) (undated; treat as unconfirmed)
- Teamfight Tactics mobile: [Riot, TFT mobile update](https://teamfighttactics.leagueoflegends.com/en-us/news/riot-games/teamfight-tactics-mobile-update/), [TFT wiki](https://wiki.leagueoflegends.com/en-us/TFT:Tutorial), [Mobalytics](https://mobalytics.gg/blog/tft/tft-mobile-how-to-play-tips-tricks/)
- RimWorld on Steam Deck: [GamingOnLinux](https://www.gamingonlinux.com/articles/20814/)
- Touch target sizes: [OpenReplay](https://blog.openreplay.com/improving-tap-targets-mobile-ux/), [Deque](https://dequeuniversity.com/rules/attest-ios/1.0/touch-target-size)
- Godot web touch: [forum, mouse events with emulation off](https://forum.godotengine.org/t/why-are-mouse-motion-events-occurring-when-i-have-emulate-mouse-from-touch-disabled/133327), [forum, gestures in mobile browsers](https://forum.godotengine.org/t/can-godot-input-gestures-detection-work-with-web-exports-on-mobile-browsers/101920)
