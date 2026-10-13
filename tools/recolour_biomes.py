#!/usr/bin/env python3
"""Recolour the grassland art into stand-ins for the other lands.

    python3 tools/recolour_biomes.py

Needs Pillow (`pip install pillow`) — the one tool in tools/ that is not
standard library, because it writes pictures.

Every land the continent has (data/biomes.json) needs ground tiles and things
standing on them, and only grassland and forest have been drawn. Until PixelLab
art is made for each, this makes placeholders by gradient-mapping the existing
art: each pixel is sorted into the kind of thing it is (growth, bare earth,
water, stone) by its hue, and its brightness is carried onto that land's
colours, so the drawing survives and only the palette changes.

The output is marked as a stand-in in docs/22-asset-provenance.md. Replace any
file it writes with real art of the same name and size and nothing else needs
to change. Re-running it overwrites what it wrote and nothing else.
"""

from __future__ import annotations

import colorsys
import json
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
TILES = ROOT / "art" / "tilesets"
PROPS = ROOT / "art" / "props"
OUT_TILES = TILES / "biome"
OUT_PROPS = PROPS / "biome"

RGB = tuple[int, int, int]
# Three stops a class of pixel is mapped onto, darkest first.
Ramp = tuple[RGB, RGB, RGB]

# Each land's palette. "floor" is the ground most of it is, "bare" the paths and
# patches of earth, "liquid" its pools, "cover" the tall growth that hides you,
# and "growth" (when given) what leaves on its trees and bushes turn.
LANDS: dict[str, dict[str, Ramp]] = {
    "snow": {
        "floor": ((150, 168, 196), (214, 226, 242), (250, 252, 255)),
        "bare": ((70, 82, 104), (118, 134, 158), (168, 182, 204)),
        "liquid": ((92, 150, 196), (160, 206, 232), (226, 244, 252)),
        "cover": ((120, 140, 170), (196, 212, 234), (244, 248, 255)),
        "growth": ((34, 66, 70), (150, 186, 200), (246, 250, 255)),
    },
    "dune": {
        "floor": ((176, 132, 72), (224, 186, 118), (250, 228, 170)),
        "bare": ((118, 80, 44), (164, 116, 66), (204, 156, 96)),
        "liquid": ((20, 104, 126), (40, 160, 168), (140, 220, 210)),
        "cover": ((120, 112, 54), (168, 156, 80), (214, 200, 120)),
        "growth": ((96, 92, 40), (150, 140, 66), (204, 190, 110)),
    },
    "badlands": {
        "floor": ((132, 58, 30), (186, 92, 46), (226, 140, 84)),
        "bare": ((82, 36, 24), (124, 62, 38), (168, 98, 62)),
        "liquid": ((60, 40, 30), (98, 70, 50), (150, 118, 86)),
        "cover": ((150, 110, 60), (196, 150, 86), (232, 196, 128)),
        "growth": ((90, 70, 40), (140, 112, 62), (190, 160, 96)),
    },
    "savanna": {
        "floor": ((150, 126, 50), (200, 172, 76), (236, 212, 120)),
        "bare": ((122, 62, 36), (164, 92, 52), (204, 130, 80)),
        "liquid": ((70, 84, 60), (110, 124, 84), (160, 170, 120)),
        "cover": ((170, 140, 54), (214, 182, 84), (246, 222, 140)),
        "growth": ((62, 78, 30), (104, 122, 48), (156, 168, 78)),
    },
    "ash": {
        "floor": ((70, 68, 70), (128, 124, 124), (186, 182, 178)),
        "bare": ((26, 22, 24), (52, 44, 44), (86, 72, 66)),
        "liquid": ((120, 24, 8), (226, 92, 20), (255, 210, 90)),
        "cover": ((48, 46, 50), (92, 88, 92), (140, 134, 136)),
        "growth": ((30, 28, 30), (70, 64, 64), (120, 110, 104)),
    },
    "blight": {
        "floor": ((66, 30, 54), (106, 48, 78), (150, 82, 108)),
        "bare": ((40, 14, 20), (76, 26, 34), (116, 50, 52)),
        "liquid": ((96, 8, 20), (176, 24, 40), (240, 96, 104)),
        "cover": ((90, 26, 50), (140, 50, 80), (196, 96, 128)),
        "growth": ((50, 18, 40), (110, 40, 74), (176, 90, 130)),
    },
    "slime": {
        "floor": ((34, 70, 58), (66, 116, 84), (120, 168, 112)),
        "bare": ((60, 30, 82), (104, 58, 132), (156, 104, 180)),
        "liquid": ((40, 140, 40), (110, 232, 70), (220, 255, 160)),
        "cover": ((88, 40, 110), (150, 84, 170), (210, 150, 220)),
        "growth": ((50, 120, 30), (120, 210, 60), (210, 250, 140)),
    },
    "bog": {
        "floor": ((62, 66, 30), (104, 106, 50), (150, 146, 82)),
        "bare": ((40, 26, 16), (70, 48, 30), (104, 76, 50)),
        "liquid": ((24, 18, 10), (56, 40, 22), (96, 78, 44)),
        "cover": ((80, 70, 34), (130, 112, 58), (178, 160, 98)),
        "growth": ((58, 60, 26), (100, 98, 46), (148, 140, 76)),
    },
    "swamp": {
        "floor": ((22, 58, 46), (44, 98, 70), (90, 146, 102)),
        "bare": ((52, 48, 40), (84, 78, 62), (122, 114, 92)),
        "liquid": ((10, 30, 30), (24, 62, 58), (70, 120, 104)),
        "cover": ((30, 70, 40), (62, 118, 64), (120, 170, 104)),
    },
    "crystal": {
        "floor": ((92, 96, 150), (148, 160, 214), (214, 226, 255)),
        "bare": ((34, 30, 70), (62, 52, 110), (98, 84, 150)),
        "liquid": ((30, 140, 190), (90, 220, 240), (220, 255, 255)),
        "cover": ((120, 90, 180), (176, 140, 230), (232, 210, 255)),
        "growth": ((60, 80, 160), (130, 170, 240), (220, 240, 255)),
    },
    "fungal": {
        "floor": ((24, 40, 64), (40, 70, 100), (76, 112, 140)),
        "bare": ((30, 24, 36), (54, 44, 60), (86, 72, 92)),
        "liquid": ((20, 120, 140), (60, 200, 210), (190, 255, 250)),
        "cover": ((40, 60, 110), (70, 100, 160), (130, 160, 210)),
        "growth": ((30, 90, 130), (70, 170, 210), (180, 240, 255)),
    },
    "blossom": {
        "floor": ((96, 150, 96), (150, 196, 132), (206, 232, 186)),
        "bare": ((140, 112, 96), (184, 152, 132), (224, 196, 178)),
        "liquid": ((90, 150, 200), (150, 200, 232), (220, 240, 255)),
        "cover": ((200, 120, 160), (236, 170, 200), (255, 222, 236)),
        "growth": ((176, 84, 130), (232, 150, 190), (255, 220, 236)),
    },
    "barrow": {
        "floor": ((70, 84, 70), (110, 124, 104), (156, 166, 146)),
        "bare": ((96, 96, 92), (140, 140, 134), (190, 190, 182)),
        "liquid": ((24, 32, 38), (46, 60, 68), (88, 104, 110)),
        "cover": ((80, 90, 70), (122, 130, 102), (168, 172, 140)),
        "growth": ((52, 62, 52), (92, 104, 88), (140, 150, 132)),
    },
    "jungle": {
        "floor": ((24, 86, 30), (48, 140, 44), (120, 196, 80)),
        "bare": ((66, 40, 24), (104, 66, 40), (146, 102, 66)),
        "liquid": ((20, 90, 80), (40, 150, 120), (130, 214, 170)),
        "cover": ((16, 70, 24), (34, 118, 40), (96, 176, 70)),
        "growth": ((14, 74, 26), (40, 136, 46), (150, 214, 90)),
    },
    "taiga": {
        "floor": ((96, 116, 110), (164, 184, 184), (228, 238, 242)),
        "bare": ((60, 54, 50), (96, 88, 80), (140, 130, 120)),
        "liquid": ((60, 100, 130), (110, 156, 186), (196, 226, 240)),
        "cover": ((40, 70, 56), (70, 108, 84), (130, 160, 138)),
        "growth": ((20, 52, 40), (40, 90, 64), (100, 146, 116)),
    },
    "mist": {
        "floor": ((70, 76, 92), (116, 124, 142), (176, 182, 198)),
        "bare": ((40, 40, 52), (70, 70, 86), (108, 108, 126)),
        "liquid": ((60, 70, 110), (110, 120, 170), (190, 200, 236)),
        "cover": ((74, 66, 100), (118, 106, 150), (176, 166, 206)),
        "growth": ((60, 52, 90), (110, 96, 150), (180, 168, 220)),
    },
}

# Tile sheets: an output name, the source sheet, and the land class each source
# class goes to. Every sheet has the land's floor on one side, so any of them
# can be laid over another.
SHEETS = [
    ("{land}_ground", "dirt_grass", {"warm": "bare", "green": "floor", "grey": "bare"}),
    ("{land}_pool", "water_grass", {"blue": "liquid", "green": "floor", "warm": "floor", "grey": "floor"}),
    ("{land}_cover", "meadow_grass",
     {"green_light": "floor", "green_dark": "cover", "blue": "cover", "warm": "floor", "grey": "floor"}),
]

# Props: the source picture, the name it goes out under, and how much of it
# changes — "growth" recolours only the green, "whole" sends earth and stone to
# the land's bare ground too, "glow" sends everything that is not growth to the
# land's liquid (embers, ice, ooze, crystal light). Sources are named for what
# they show since tools/rename_art.py; these were picked by looking.
PROP_SETS = {
    "snow": [("nature/holly_tree", "snow_fir", "growth"), ("nature/round_tree", "snow_oak", "growth"),
             ("nature/briar_bush", "frost_twigs", "whole"), ("@boulder", "snow_boulder", "whole"),
             ("nature/crystal_spikes", "ice_spikes", "glow"), ("nature/grass_tuft", "frost_tuft", "growth")],
    "dune": [("nature/briar_bush", "thorn_bush", "whole"), ("nature/hazel_bush", "dry_scrub", "growth"),
             ("@boulder", "sandstone", "whole"), ("@stones", "dune_stones", "whole"),
             ("nature/grass_tuft", "dune_grass", "growth")],
    "badlands": [("@spire", "red_spire", "whole"), ("@boulder", "mesa_rock", "whole"),
                 ("nature/briar_bush", "dead_brush", "whole"), ("@stones", "red_stones", "whole")],
    "savanna": [("nature/sycamore_tree", "acacia", "growth"), ("nature/hazel_bush", "savanna_scrub", "growth"),
                ("nature/grass_tuft", "dry_tuft", "growth"), ("@spire", "termite_mound", "whole"),
                ("nature/copse", "acacia_stand", "growth")],
    "ash": [("nature/bare_tree", "charred_tree", "whole"), ("nature/holly_tree", "burnt_fir", "whole"),
            ("nature/briar_bush", "ash_scrub", "whole"), ("@boulder", "cinder_boulder", "whole"),
            ("@stones", "ember_stones", "glow")],
    "blight": [("nature/bare_tree", "blighted_tree", "whole"), ("nature/briar_bush", "blight_thorns", "whole"),
               ("@boulder", "blight_rock", "whole"), ("nature/mushrooms_cluster", "flesh_coral", "glow"),
               ("nature/mushrooms_tall", "blight_stalk", "whole")],
    "slime": [("nature/mushrooms_tall", "slime_caps", "whole"), ("nature/mushrooms_cluster", "slime_coral", "glow"),
              ("nature/crystal_spikes", "slime_spout", "glow"), ("nature/briar_bush_2", "slime_bush", "growth"),
              ("nature/mushroom_blue", "slime_bloom", "glow")],
    "bog": [("nature/bare_tree", "bog_snag", "whole"), ("nature/sycamore_tree", "bog_birch", "growth"),
            ("nature/grass_tuft", "bog_rushes", "growth"), ("nature/mushrooms_shelf", "bog_shelf", "whole"),
            ("nature/dead_tree", "bog_hag", "whole"), ("nature/bramble_2", "bog_scrub", "growth")],
    "swamp": [("nature/ivy", "swamp_willow", "growth"), ("nature/copse", "swamp_grove", "growth"),
              ("nature/mushroom_blue", "glow_caps", "glow"), ("nature/bramble", "swamp_bush", "growth"),
              ("nature/grass_tuft", "swamp_reeds", "growth")],
    "crystal": [("nature/crystal_spikes", "crystal_spire", "glow"), ("@spire", "crystal_rock", "glow"),
                ("nature/briar_bush_2", "crystal_bush", "growth"), ("@stones", "crystal_shards", "glow")],
    "fungal": [("nature/mushrooms_tall", "giant_morel", "whole"), ("nature/mushroom_blue", "great_glowcap", "glow"),
               ("nature/mushrooms", "fungal_cap", "whole"), ("nature/mushrooms_shelf", "fungal_shelf", "glow"),
               ("nature/grass_tuft", "spore_tuft", "growth")],
    "blossom": [("nature/round_tree", "blossom_tree", "growth"), ("nature/copse", "blossom_grove", "growth"),
                ("nature/briar_bush_2", "blossom_bush", "growth"), ("nature/sycamore_tree", "blossom_sapling", "growth")],
    "barrow": [("stone_bench", "rune_stone", "whole"), ("@spire", "standing_stone", "whole"),
               ("nature/bare_tree", "barrow_thorn", "whole"), ("nature/grass_tuft", "grey_tuft", "growth"),
               ("@stones", "cairn", "whole")],
    "jungle": [("nature/ivy", "jungle_vines", "growth"), ("nature/copse", "jungle_canopy", "growth"),
               ("nature/fern", "jungle_fern", "growth"), ("nature/briar_bush_2", "jungle_bush", "growth"),
               ("nature/mushroom_blue", "jungle_bloom", "glow"), ("@boulder", "mossy_rock", "whole")],
    "taiga": [("nature/holly_tree", "taiga_spruce", "growth"), ("nature/holly_tree_2", "taiga_pine", "growth"),
              ("nature/briar_bush", "taiga_deadfall", "whole"), ("nature/grass_tuft", "taiga_tuft", "growth"),
              ("@boulder", "frost_boulder", "whole")],
    "mist": [("nature/bare_tree", "mist_snag", "whole"), ("nature/sycamore_tree", "mist_tree", "growth"),
             ("@spire", "mist_spire", "whole"), ("nature/mushrooms_cluster", "mist_coral", "glow"),
             ("nature/grass_tuft", "mist_tuft", "growth")],
}

# There is no rock in the prop art (the files named rubble_* are a tree, a bird
# and a dead bush), so these are drawn here: grey, so "whole" can colour them.
def drawn_rock(kind: str) -> Image.Image:
    import random
    rng = random.Random(kind)
    size = 64 if kind != "@stones" else 32
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    px = image.load()
    blobs = []
    if kind == "@boulder":
        blobs = [(32, 40, 22, 16), (24, 36, 12, 10), (40, 34, 12, 11)]
    elif kind == "@spire":
        blobs = [(32, 40, 12, 22), (32, 22, 8, 14), (34, 12, 5, 8), (26, 50, 10, 6), (38, 50, 10, 6)]
    else:
        for _ in range(4):
            blobs.append((rng.randint(8, 24), rng.randint(14, 26), rng.randint(4, 7), rng.randint(3, 5)))
    inside = [[False] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            for cx, cy, rx, ry in blobs:
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0:
                    inside[y][x] = True
                    break
    for y in range(size):
        for x in range(size):
            if not inside[y][x]:
                continue
            edge = any(not (0 <= x + dx < size and 0 <= y + dy < size and inside[y + dy][x + dx])
                       for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            # Lit from the top left: brighter up and left, darker down and right.
            lit_from = sum(1 for d in range(1, 5) if 0 <= y - d and 0 <= x - d and inside[y - d][x - d])
            shade = 70 + lit_from * 6 if lit_from < 4 else 150 + rng.randint(-8, 8)
            if not (0 <= y + 3 < size and inside[y + 3][x]):
                shade = min(shade, 96)
            px[x, y] = (30, 30, 32, 255) if edge else (shade, shade, shade + 4, 255)
    # A crack or two.
    for _ in range(2):
        x, y = rng.randint(size // 3, 2 * size // 3), rng.randint(size // 3, 2 * size // 3)
        for _ in range(size // 6):
            if 0 <= x < size and 0 <= y < size and inside[y][x]:
                px[x, y] = (54, 54, 58, 255)
            x += rng.choice((-1, 0, 1))
            y += 1
    return image


def classify(r: int, g: int, b: int) -> str:
    """What a pixel is a picture of, by its hue."""
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    deg = h * 360
    if s < 0.12:
        return "grey"
    if 150 <= deg < 250:
        return "blue"
    if 60 <= deg < 150:
        return "green_dark" if l < 0.3 else "green_light"
    return "warm"


def luminance(r: int, g: int, b: int) -> float:
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255


def ramp(stops: Ramp, t: float) -> RGB:
    t = max(0.0, min(1.0, t))
    if t < 0.5:
        a, b, k = stops[0], stops[1], t / 0.5
    else:
        a, b, k = stops[1], stops[2], (t - 0.5) / 0.5
    return tuple(round(a[i] + (b[i] - a[i]) * k) for i in range(3))  # type: ignore[return-value]


def pixels_of(image: Image.Image):
    return image.get_flattened_data() if hasattr(image, "get_flattened_data") else image.getdata()


def spread(image: Image.Image) -> dict[str, tuple[float, float]]:
    """Each class's darkest and brightest (5th and 95th percentile), so its
    whole range of shading is carried across rather than squashed."""
    seen: dict[str, list[float]] = {}
    for r, g, b, a in pixels_of(image):
        if a == 0:
            continue
        seen.setdefault(classify(r, g, b), []).append(luminance(r, g, b))
    out = {}
    for key, values in seen.items():
        values.sort()
        lo = values[int(len(values) * 0.05)]
        hi = values[min(len(values) - 1, int(len(values) * 0.95))]
        out[key] = (lo, max(hi, lo + 0.05))
    return out


def recolour(image: Image.Image, mapping: dict[str, Ramp]) -> Image.Image:
    ranges = spread(image)
    out = image.copy()
    pixels = out.load()
    for y in range(out.height):
        for x in range(out.width):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            kind = classify(r, g, b)
            stops = mapping.get(kind)
            if stops is None and kind.startswith("green"):
                stops = mapping.get("green")
            if stops is None:
                continue
            lo, hi = ranges.get(kind, (0.0, 1.0))
            nr, ng, nb = ramp(stops, (luminance(r, g, b) - lo) / (hi - lo))
            pixels[x, y] = (nr, ng, nb, a)
    return out


def main() -> None:
    # What PixelLab has made since (tools/pixellab_world.py) is never recoloured over: a sheet
    # still marked `stand_in` in data/tilesets.json, and a prop no prompt names, are the only ones written.
    sheets = json.loads((ROOT / "data" / "tilesets.json").read_text(encoding="utf-8"))["sheets"]
    made = set()
    for land in json.loads((ROOT / "art" / "world_prompts.json").read_text(encoding="utf-8"))["lands"].values():
        made.update(name.split("/")[-1] for name in land["props"])
    OUT_TILES.mkdir(parents=True, exist_ok=True)
    OUT_PROPS.mkdir(parents=True, exist_ok=True)
    for land, colours in LANDS.items():
        for out_name, source, classes in SHEETS:
            image = Image.open(TILES / f"{source}.png").convert("RGBA")
            mapping = {kind: colours[role] for kind, role in classes.items()}
            target = OUT_TILES / f"{out_name.format(land=land)}.png"
            if not sheets.get(out_name.format(land=land), {}).get("stand_in", False):
                continue
            recolour(image, mapping).save(target)
            print("wrote", target.relative_to(ROOT))
        growth = colours.get("growth", colours["floor"])
        for source, name, mode in PROP_SETS[land]:
            image = drawn_rock(source) if source.startswith("@") \
                else Image.open(PROPS / f"{source}.png").convert("RGBA")
            mapping = {"green": growth, "green_dark": growth, "green_light": growth}
            if mode == "whole":
                mapping.update({"warm": colours["bare"], "grey": colours["bare"], "blue": colours["liquid"]})
            elif mode == "glow":
                mapping.update({"warm": colours["liquid"], "grey": colours["liquid"], "blue": colours["liquid"]})
            target = OUT_PROPS / f"{name}.png"
            if name in made:
                continue
            recolour(image, mapping).save(target)
            print("wrote", target.relative_to(ROOT))
    # Plain grey rocks for grassland and forest, which have no rock either.
    for kind, name in (("@boulder", "boulder"), ("@spire", "tall_rock"), ("@stones", "stones")):
        target = OUT_PROPS / f"{name}.png"
        drawn_rock(kind).save(target)
        print("wrote", target.relative_to(ROOT))


if __name__ == "__main__":
    main()
