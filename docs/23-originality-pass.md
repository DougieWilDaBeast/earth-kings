# 23 — Originality pass

Every character in `art/units/` checked against other people's work, 2026-10-12. The check used
each folder's `metadata.json` prompt (what PixelLab was asked for) and the idle sprite itself (what
came back). Asking for a franchise character by name gets you that character, so a prompt that
names one is where most of the problems below started.

The names, jobs and faction text are already changed in `data/units.json` and `data/factions.json`.
**The sprites are not** — they still look like the originals and have to be regenerated in PixelLab
from the prompts below. Until then they are **dev only** in [22](22-asset-provenance.md) (item P6).

Unit ids and art folder names are unchanged on purpose: players never see them, and changing them
would need a save migration. Rename them later if the old names bother you.

## Must change — the sprite is the original character

| Unit id | Was | Copied from | Now called |
| --- | --- | --- | --- |
| `beast_titan` | The Beast, Titan | *Attack on Titan* (Beast Titan) — prompt named it | **The Barrow Giant**, Elder Giant |
| `colossal_titan` | The Colossal, Titan | *Attack on Titan* (Colossal Titan) — prompt named it | **The Cinder Colossus**, Elder Giant |
| `ember_lizard` | Ember Lizard | *Pokémon* (Charmander) — prompt named it | **Cinder Newt** |
| `seed_beast` | Seed Beast | *Pokémon* (Bulbasaur) — no prompt recorded, sprite is a direct match | **Mossback** |
| `blue_slime` | Blue Slime | *Dragon Quest* (Slime) — prompt named it | **Bog Jelly** |
| `king_slime` | King Slime | *Dragon Quest* (King Slime) — prompt named it | **The Mother Ooze** |

The faction `titans` is now shown as **The Elder Giants**.

## Should change — one signature borrowed

| Unit id | The borrowed part | What to do |
| --- | --- | --- |
| `sword_monkey` (Tem) | Straw hat + left-eye patch + three-sword style is *One Piece* (Luffy's hat, Zoro's style). The name and the monkey are fine | Regenerate without the hat, patch and third sword (prompt below) |
| `red_panda_master` | Prompt asked for "like Master Shifu" (*Kung Fu Panda*). The sprite came out as a plain red panda, and a red panda martial artist is not ownable | Keep. When it is redrawn, never give it Shifu's long white moustache, robe and staff together. Write future prompts without the reference |

## Checked and fine

Generic fantasy, or an inspiration that did not carry over into a recognisable design:
`avatar_adept` (an armoured man; only the id says "avatar"), `element_monk`, `staff_panda`,
`frozen_wolfman` (a plain frost werewolf, no Wolverine look), `mace_pirate` ("pirate king" is just a
phrase), `rank_f_grunt`, `slime` (orange jelly ball), `devil_butler`, `storm_blade`,
`emo_swordsman`, `golden_knight`, `ice_wolf`, `sea_horse`, and everything with a plain written
prompt. `dirte` and the Heart Empire legion are the team's own.

Inspirations in [worldbuilding/respondents.md](worldbuilding/respondents.md) (*One Piece*,
*Slime*, etc.) are about ideas and tone, which nobody owns. Only copied names, looks and text are
the problem.

## New PixelLab prompts

Same size, view and template as the old export in each folder's `metadata.json`. Never put a
franchise or character name in a prompt.

**The Barrow Giant** (`beast_titan`) — keeps cleave, crush, earthshake, sunder
> Hulking giant made of packed earth and turf, standing stones jutting from its back like spines,
> roots hanging from its arms, moss beard, two small glowing amber eyes deep in a stone face,
> walks hunched on its knuckles. No fur, no skin.

**The Cinder Colossus** (`colossal_titan`) — keeps pyre
> Towering giant of cracked black basalt, glowing orange magma in the seams, a ruined bell tower
> fused to its shoulders like a crown, chains hanging from its wrists, smoke drifting from the
> cracks. Rock body, no muscle or skin showing.

**Cinder Newt** (`ember_lizard`)
> Low four-legged salamander crawling flat to the ground, charcoal-black skin with glowing orange
> cracks along its back, frilled gills that leak smoke, long whip tail with no flame on the tip,
> small beady eyes.

**Mossback** (`seed_beast`) — keeps mend
> Squat tortoise-like beast with a tiny grove growing on its shell: mushrooms, ferns and one
> drooping flower that glows like a lantern. Bark-brown scaly legs, slow kindly face, no bulb.

**Bog Jelly** (`blue_slime`) — keeps brine spray, undertow
> Flat wobbling puddle of murky blue-green jelly, translucent, with pebbles, a fish bone and a lost
> coin floating inside it. No face; a single eye drifting loose inside the jelly.

**The Mother Ooze** (`king_slime`)
> Large lumpy mound of amber ooze with small oozes budding off its sides, a rusted knight's helmet
> and a broken sword sunk inside it, dripping. No crown, no face.

**Tem the Sword Monkey** (`sword_monkey`)
> Wiry macaque swordsman with a red knotted headscarf and a brass ring in one ear, two short curved
> swords, tail curled around a third scabbard worn on his back, patched sleeveless travelling coat.
> No hat, no eyepatch.

When a sprite is regenerated, drop its row from item P6 in [22](22-asset-provenance.md).
