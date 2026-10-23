# 14 — What we can take from outside: assets, tools, services, and what multiplayer would mean

2026-10-23. Asked by Will: "give me some indication of what you think that this project would need, what's actually already available out there ... consult the team as well, and we're going to start pulling from open source." Grounded in main `669f992` (after #564), meeting seven's notes, the art plan for 27 October, [22](../22-asset-provenance.md), [24](../24-art-requests.md), [28](../28-the-first-hour.md), [31](../31-music.md) and the roadmap's **Launch readiness**. Decision [D426](../06-decisions.md), agenda row 325.

**This is a review, not a build.** Nothing here is taken in or wired until Will decides, and nothing new is started before play-test 9's asks are in ([D383](../06-decisions.md)). Every licence below is as the source states it in its own words, read from what the team knew before today unless marked *(checked today)*. Before anything is taken in, its licence page is read again and saved beside the files, and [22](../22-asset-provenance.md) and `data/credits.json` get its row.

## The short answer

1. **We already have more than it looks.** Saves with backups and upgrades, a credits screen, gamepads and rebinding, a tutorial, builds for the browser, Windows, Linux, macOS and Android, an itch page, our own dialogue, our own music and sound made in code. None of that needs an outside addon.
2. **The biggest real gap is not new art. It is art and sound nobody can say where it came from** ([22](../22-asset-provenance.md) P3, P4): the item icons, props, buildings, holds, eight ground sheets, the menu frames and two menu sounds. A Steam release needs every one of those known. Outside packs that are free to use (CC0) are the quickest way to replace whatever the founders can't trace.
3. **Outside art fits in some places and not others.** Fonts, button prompts, UI frames, icons, particles and effect textures can come from outside without anyone noticing. Characters, monsters and the land should stay PixelLab and in-house, or the game stops looking like one game.
4. **Sound is the cheapest big win.** The fight sounds are sine waves and noise made in code ([D76](../06-decisions.md)). Free, commercial-safe libraries (Sonniss's yearly GDC bundles, Kenney's audio) have thousands of real recordings: footsteps, swords, crowds, wind and fire. Music stays Ewan's and the in-house themes.
5. **Steam is the one setup we must do ourselves.** The developer account (a one-off fee), the app, Steam Cloud for saves, achievements, a "coming soon" page for wishlists, and Steam's AI disclosure for the PixelLab art. Most of it is forms, not code. One addon (GodotSteam, MIT) does the code side when the time comes.
6. **Multiplayer doesn't fit the game as designed, and nothing has to be done about it for 1.0.** The one kind that does fit is asynchronous: other real players' climbs and deaths showing up in your world. Steam's own leaderboards can carry that without a server of our own. Live co-op would mean rewriting the fight, the saves and permadeath, and isn't recommended.

## What already exists (so nobody proposes it again)

| Need | What we have | Where |
| --- | --- | --- |
| Saves | Atomic writes, a backup a corrupt save falls back to, step-by-step upgrades, Iron Man and Classic | `save_file.gd`, `save_migrations.gd`, D56, D51 |
| Credits and licences | A credits screen read from data, Godot's MIT notice word for word | `data/credits.json`, [22](../22-asset-provenance.md) |
| Controllers | Xbox and PlayStation pads play the whole game, pad rebinding in the system menu | roadmap, Launch readiness |
| Key rebinding and mouse | Keys rebind in the system menu; every key's action is a click away (D390, D391) | `src/ui/system_menu.gd`, `mouse_bar.gd` |
| Touch | Two touch passes (D376-D378, D386-D389) | [13](13-mobile-controls.md) |
| Dialogue | Our own talk system and data | `src/dialogue/` |
| Fonts | Cinzel (OFL) for the title and menu, Open Sans (OFL, built into Godot) for the rest | [22](../22-asset-provenance.md#fonts) |
| Music | Ewan's two Ableton tracks, five in-house themes made in code until his cues; fan covers out (D100) | [31](../31-music.md) |
| Sound effects | Nineteen effects made in code; two menu sounds of unknown origin | `tools/make_fight_sounds.py`, [22](../22-asset-provenance.md) P3 |
| Builds | Web, Windows, Linux, macOS from `release.yml`; Android debug APK (D424); itch on five channels (D425) | [28](../28-the-first-hour.md) |
| Art pipeline | `tools/pixellab.py`, `pixellab_world.py`, `take_art.py`, every open row A2-A67 slotted (D369) | [24](../24-art-requests.md) |
| Play logs | `Esc` → Copy play log; soak, ledger and bot runs | AGENTS.md |

The stack rule in AGENTS.md says **no plugins**. Anything below marked *addon* would need that rule loosened by a decision first.

## What the game still needs beyond content, and where to get it

"Fills" names the gap. "Licence" is what decides whether it can ship in a paid game. **CC0** and **MIT** and **OFL** need nothing but a credit line (and CC0 not even that). **CC-BY** needs the author named in the credits. Paid packs are fine when their own licence says commercial games may use them; the licence file is kept with the art.

### 1. Art beyond PixelLab

| Source | Licence | What it would fill | Fit |
| --- | --- | --- | --- |
| **Kenney** (kenney.nl): UI Pack RPG Expansion, Game Icons, Particle Pack, Input Prompts, Fonts | CC0 | Menu frames and buttons to replace the unknown `frame_bar` and `frame_panel` (P4); particle textures (smoke, sparks, magic) for the fight effects; **controller and keyboard button prompts** for the pad and key hint lines, which today are words | Good for UI, prompts and particles. Too clean and bright for characters |
| **Xelu's free controller and key prompts** | CC0 | Xbox, PlayStation, Switch, Steam Deck and keyboard glyphs, one picture per button | The best fit for hint lines that name the pad's buttons |
| **game-icons.net** | CC BY 3.0 (credit each author) | Thousands of one-colour icons: skills, statuses, items, A4's sixteen signature weapons as a stand-in, the journal's tabs | Recoloured to the palette, they sit well in a dark UI |
| **0x72's Dungeon Tileset II**, **Kenney's Tiny Dungeon** | CC0 | A known-source stand-in if the eight unknown ground sheets (P4) can't be traced | Only as a stopgap: a different hand from ours |
| **Mana Seed** by Seliel the Shaper (itch.io, paid) | Commercial use allowed, no resale or AI training (read the pack's licence) | Farming and village props, a full top-down village kit; a human pixel artist's style close to our 64 class | The best paid option if we ever want a human-drawn set beside PixelLab |
| **OpenGameArt.org** | Per file: CC0, CC-BY, CC-BY-SA, GPL | Odds and ends | Take only CC0 and CC-BY. Skip GPL and CC-BY-SA (share-alike) to keep things simple |
| **Lospec** palette list | Palettes are free to use | One fixed palette for everything, which PixelLab's Pro Flash can be held to (`target_palette`, the art plan) | Pairs with the 27 October run |
| **godotshaders.com** | Per shader, mostly CC0 or MIT | Hit flash, dissolve on death, outlines on a picked fighter, water, wind in grass, a vignette for the memory scenes | Code, so it sits in our art look, not against it |
| **Pixelorama** (made in Godot) | MIT | A pixel editor anyone can run, for touching up PixelLab output | Aseprite already builds from source in the cloud and stays the main editor; Pixelorama is the free one Ewan could use |
| **LibreSprite** | GPL (the editor only; your art is yours) | As above | Either is fine for founders without Aseprite |

**Fonts.** Cinzel stays for the title. For the body text a pixel font would match the art better than Open Sans: **m5x7 / m6x11** by Daniel Linssen (free with credit), **Pixel Operator** (CC0), **Fusion Pixel** (OFL, covers many languages), or PixelLab's own font tool (15 gens, the art plan). Whatever is picked must cover the letters of the languages we might translate into.

### 2. Sound and music

| Source | Licence | What it would fill |
| --- | --- | --- |
| **Sonniss "GDC Game Audio Bundle"** (one each year since 2015, tens of GBs) | Royalty free, commercial use, no credit required (Sonniss's own licence) | Real recordings for everything [31](../31-music.md)'s short pieces want and more: swords, bows, footsteps on stone and grass, crowds for Stormreach, wind and fire for the crater, doors, gates |
| **Kenney audio packs** (RPG Audio, Impact Sounds, Interface Sounds) | CC0 | The two unknown menu sounds (P3) replaced the same day; UI clicks and hovers |
| **freesound.org** | Per file: CC0, CC-BY, CC-BY-NC | Single sounds. CC0 and CC-BY only; **never NC** (non-commercial) |
| **jsfxr / ChipTone** | The sounds you make are yours | Quick stand-ins in our own hand, as `make_fight_sounds.py` does now |
| **Spitfire LABS**, **Vital**, **Surge XT** (free instruments) | Free; the music made with them is the maker's | For Ewan, beside Ableton's Core Library, if he wants more sounds for the cues |
| **Incompetech (Kevin MacLeod)**, **Soundimage (Eric Matyas)** | CC-BY / credit required | Not recommended: heard in thousands of games and videos, and music is Ewan's |

The fan covers stay out of everything outsiders play ([D100](../06-decisions.md)).

### 3. Godot addons and tooling

| Need | What exists | Licence | Recommendation |
| --- | --- | --- | --- |
| Steam (achievements, cloud, overlay, leaderboards, Steam Input) | **GodotSteam** (GDExtension, follows Godot releases; a post on 5 April 2026 bumped it for 4.6.2) *(checked today)* | MIT | The one addon worth taking, when the Steam milestone starts. Desktop builds only; the web build doesn't load it |
| Crash reports | **Sentry's Godot SDK** (official, GDExtension, native crashes and GDScript errors, breadcrumbs, user feedback) *(checked today)* | MIT; Sentry's free tier for small teams | Opt-in crash reports in desktop builds. Needs a privacy line |
| Dialogue | Dialogic 2, Nathan Hoad's Dialogue Manager | MIT | **Not needed.** We have our own, in data |
| Saves | Various | — | **Not needed.** Ours is better tested than any addon |
| Translation | Godot's own: `tr()`, CSV or gettext `.po` files, `POT` generation in the editor; **Weblate** (free hosting for open projects) or **Crowdin** (free tiers) for translators | Built in | Not now. The day it starts, the work is pulling every string out of `data/` and the scripts into one `.po`; the founders' rule that a quote is never edited still holds |
| Input remapping, controller | Built in, and ours already works | — | Only the button pictures (Kenney or Xelu prompts, above) are missing |
| Accessibility | Godot 4.5 added screen-reader support through AccessKit; our own settings can add text size, a colour-blind palette for the red danger ground and team colours, screen shake off, hold-to-press instead of mash | Built in | A small pass before the Steam demo. Steam lets the store page list accessibility features |
| Tests | GUT, gdUnit4 | MIT | **Not needed.** Thirteen headless suites already run in CI |

### 4. Infrastructure and services

| Need | What exists | Cost | Notes |
| --- | --- | --- | --- |
| **Steam account and app** | Steamworks, Steam Direct | One-off $100 per app, paid back after $1,000 in sales; a tax and bank form | The app ID unlocks everything else on this list |
| **Saves across devices** | **Steam Auto-Cloud**: set in the Steamworks site, it copies files from the save folder with **no code at all** | Free | The cheapest answer to "saves per device until Steam" (call CD). itch has no cloud saves for downloads |
| **Achievements** | Steamworks stats and achievements, called through GodotSteam | Free | Achievements need 64 × 64 icons: an art row when the time comes |
| **Steam Input** | Steam's own layer over any pad, plus Steam Deck | Free | Our pad support already works; Deck verification asks for readable text at 1280 × 800 and on-screen glyphs |
| **Play-testing on Steam** | **Steam Playtest** (a free separate app players sign up for); **Next Fest** (February 2027, the year D255 named) | Free | The First Hour as the free demo ([29](../29-the-store-page.md)) |
| **Uploading builds** | **steamcmd / SteamPipe**, with a ready GitHub Action (`game-ci/steam-deploy`, MIT) beside `release.yml`; butler stays for itch | Free | One job added to the release workflow when the app exists |
| **AI disclosure** | Steam's content survey asks about AI-made art; itch asks for an "AI generated" tag | Free | **Required.** PixelLab art must be disclosed on both stores |
| **Signing** | Windows: Azure Trusted Signing (about $10 a month) or a certificate; macOS: Apple Developer ($99 a year) to notarise | As listed | Not needed on Steam for Windows; needed for macOS downloads to open without a warning. Already in the roadmap as planned |
| **Crash reports** | Sentry (above) | Free tier | Opt-in |
| **Analytics** | Steam's own sales and play numbers; **Talo** (open source, MIT, self-hostable) for events and player stats | Free / self-hosted | Recommend no analytics beyond Steam's. The bot soaks and play logs tell us more than counters would |
| **Privacy** | A short privacy note on the store page | — | Needed only if crash reports or analytics are added |
| **Android** | The private APK (D424); a store release after 1.0 (BN) would need a Google Play developer account ($25 once) and a release key | Later | Nothing now |

### 5. Community and play-test tooling

- **Steam community hub and Playtest** once the app exists; until then itch's comments and devlogs. Will dropped Discord.
- **A bug button in the game**: today the play log is copied by hand. Sentry's user feedback can send it with a line of text, opt-in, desktop only.
- **Trailer and clips**: OBS (GPL, the videos are ours) for real play; `tools/who_wins.py` and `party_war.py` already record shows. Steam wants a trailer and five or more screenshots ([29](../29-the-store-page.md)).
- **Press kit**: a page made with **presskit()** (open source) or a simple itch page.
- **Store capsule art**: Steam's capsules are fixed sizes and the most-seen picture of the game. Most indies pay a human artist for them; with AI art disclosed, a human-drawn capsule is the panel's advice.

## Multiplayer: what it would mean, honestly

Earth Kings is built around one player: a lead from the sixteen, permadeath, a world that keeps going after you fall, fights that pause, Auto, and saves on one device. Live multiplayer breaks most of that. Two people can't share a pause, a death in co-op isn't one player's loss, and saves become a server's job ("a server as world-authority" is already on the roadmap's **Deferred** list).

What fits is **asynchronous and shared-world**: you play alone, and other real players' runs leave marks in your world.

| Option | What a player sees | What it takes | Fit |
| --- | --- | --- | --- |
| **None** | — | Nothing | Fine for 1.0. Single-player tactics games sell without it |
| **Steam leaderboards** | The climbers' stone (A41) carries real players' names and the floor they reached; a weekly seed everyone plays | GodotSteam's leaderboard calls; no server | **The best first step.** Free, no server, fits a stone that already lists climbers |
| **Leaderboard attachments** | A fallen player's lead shows up in your Tower as a grave, a ghost to fight, or a weapon to pick up (the later leads' growth from deaths in other worlds, read the other way) | Steam lets a small file ride on a leaderboard entry; still no server | After 1.0, if the founders want it |
| **A small backend** (Talo self-hosted, Nakama, Supabase) | Messages left on the ground, a shared world event | A server to run, pay for and keep up | Only if the leaderboard routes fall short |
| **Live co-op or versus** | Two players in one fight | Rewriting fights for the network, saves, permadeath, cheating | Not recommended |

## The panel

Run past the five who usually sit for these questions: the **producer** (chair), **Ilse Varga** (art lead), **Sol Adeyemi** (music and sound), the **engine programmer**, and the **business lead**. Not a numbered meeting; the votes are advice for Will, not decisions.

- **Producer:** "Two things here are real work before Steam: the art nobody can trace, and the Steam setup. Everything else is a list to come back to. Nothing gets built from this until play-test 9 is in."
- **Ilse:** "Outside packs for anything that isn't a body or the ground. Fonts, prompts, frames, particles: yes. Characters from a pack would sit next to PixelLab's like a sticker. And one palette for the 27th, so whatever we take in is recoloured to it."
- **Sol:** "The fight sounds are the thinnest part of the game. A swing that sounds like a swing is worth more than another theme. Sonniss and Kenney, CC0 or near it, a pass after play-test 9. Ewan's music stays Ewan's; no stock music."
- **Engine programmer:** "Keep the no-plugins rule until the Steam work starts, then let in two: GodotSteam and Sentry, both MIT, desktop only. No dialogue or save addons: ours are tested and theirs would be a second system."
- **Business lead:** "The $100 and the forms take weeks, not days, and the page has to be up months before Next Fest for wishlists. Disclose the AI art on both stores. No analytics. Multiplayer is a feature for a sequel or a 1.1, not this launch; leaderboards are a cheap yes."

| Proposal | For | Against | Note |
| --- | --- | --- | --- |
| A licence rule: CC0, MIT, OFL and CC-BY in; paid only with its licence kept; never NC, ND, GPL in the game, "personal use" or ripped | 5 | 0 | |
| Outside packs only for UI, icons, prompts, fonts, particles and effect textures; bodies and the land stay PixelLab and in-house | 4 | 1 | Engine programmer would also take a CC0 tileset as a stopgap for P4 |
| Trace P3 and P4 first; whatever nobody can trace is replaced on or after 27 October | 5 | 0 | |
| A sound-effects pass from Sonniss and Kenney after play-test 9 | 5 | 0 | |
| No plugins until the Steam work starts; then GodotSteam and Sentry only | 4 | 1 | Producer would wait for Steam's app ID before even that |
| Steam account and a "coming soon" page in the winter, ahead of Next Fest February 2027 | 4 | 1 | Producer: tie it to Ewan's date word (question 31, by 31 October) |
| Opt-in crash reports, no analytics | 5 | 0 | |
| No multiplayer for 1.0; Steam leaderboards (the climbers' stone) as the one shared thing, after the Steam app exists | 5 | 0 | |
| Disclose PixelLab art on Steam and itch | 5 | 0 | |

## Do first (once Will decides, after play-test 9)

1. **Trace the unknown art and sound** (P3, P4): Will and Ewan say where the item icons, props, buildings, holds, the eight ground sheets, the menu frames and the two menu sounds came from. Anything nobody can trace goes on the 27 October list or is swapped for a CC0 piece.
2. **Write the licence rule into [22](../22-asset-provenance.md)** so every thread checks the same thing before taking anything in.
3. **Take the free, no-risk packs**: Kenney or Xelu button prompts for the pad and key hints, Kenney UI and particles, a pixel font to try against Open Sans. All CC0.
4. **A sound pass** from the Sonniss bundles and Kenney audio: fights, footsteps, the city, the crater.
5. **Steam setup when the founders give the date**: the account, the app, Auto-Cloud for saves, the AI disclosure, a "coming soon" page; then GodotSteam for achievements and leaderboards, and steamcmd in `release.yml`.
6. **A small accessibility pass** before the demo: text size, colour-blind danger ground, screen shake off.
