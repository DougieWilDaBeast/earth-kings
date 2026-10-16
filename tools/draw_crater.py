#!/usr/bin/env python3
"""Draw the crater where the lead fell: a scorched floor, a rim of thrown-up earth, shards.

    python3 tools/draw_crater.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The First Hour opens in the crater (data/areas/home.json), but it was a diamond of plain dirt in the
grass: nothing said something came down here hard. D134 draws it in house, the sheets in the 24 x 8
layout every PixelLab "godot" sheet shares (src/area/tile_forge.gd), both see-through off their own
ground so they lie over the land's grass and dirt:

- art/tilesets/crater/crater_floor.png: scorched earth, dark and mottled, a rare ember still lit;
- art/tilesets/crater/crater_rim.png: earth thrown up in a ring of clods and stones, lit on top;
- art/props/crater/shard.png (+ shard/frame_000..005.png): a shard of something bright half sunk in
  the floor, catching the light now and then (AreaProp plays the frames);
- art/world/crater.png: the crater as the map draws it, where the lead fell, in place of the red
  castle the map showed there before (D167, `doug-md`'s play-test 3: "There's no castle there").
  `python3 tools/draw_crater.py --icon` draws only this.

and lays the crater in them: the floor's outer ring of cells becomes the rim (`r`), the rest the
floor, the trail out below it stays dirt (`d`), and shards are set where the spots and the fire leave room.
"""

from __future__ import annotations

import json
import math
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
TILES = ROOT / "art" / "tilesets" / "crater"
PROPS = ROOT / "art" / "props" / "crater"
AREA = ROOT / "data" / "areas" / "home.json"
T = 64
SHARDS = [[6, 6], [11, 6], [9, 8]]

WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

SCORCH = [(58, 44, 38), (52, 39, 34), (64, 49, 41), (46, 35, 31)]
CRACK = (214, 112, 46)
CRACK_DIM = (128, 60, 32)
CLOD = [(112, 82, 56), (100, 72, 48), (124, 92, 62)]
CLOD_TOP = (150, 116, 80)
CLOD_DARK = (64, 46, 32)
PEBBLE = (128, 124, 120)
SHARD = (190, 230, 255)
SHARD_DARK = (120, 170, 210)


def smooth_noise(seed: int, g: int = 8) -> list[list[float]]:
    """Smooth noise that repeats every 64 pixels."""
    rng = random.Random(seed)
    lattice = [[rng.random() for _ in range(g)] for _ in range(g)]
    out = [[0.0] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            fx, fy = x / T * g, y / T * g
            x0, y0 = int(fx) % g, int(fy) % g
            x1, y1 = (x0 + 1) % g, (y0 + 1) % g
            tx, ty = fx - int(fx), fy - int(fy)
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            a = lattice[y0][x0] + (lattice[y0][x1] - lattice[y0][x0]) * tx
            b = lattice[y1][x0] + (lattice[y1][x1] - lattice[y1][x0]) * tx
            out[y][x] = a + (b - a) * ty
    return out


def grain(seed: int) -> list[list[float]]:
    rng = random.Random(seed)
    return [[rng.random() for _ in range(T)] for _ in range(T)]


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(c + amount))) for c in colour)


def corners(code: int, x: int, y: int) -> float:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    u, v = (x + 0.5) / T, (y + 0.5) / T
    return nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v


def floor_pixel(x: int, y: int, patches, veins, noise) -> tuple:
    """Scorched earth, mottled in soft patches, a rare ember still lit in it."""
    if noise[y][x] > 0.993:
        return CRACK
    if noise[y][x] > 0.985:
        return CRACK_DIM
    base = SCORCH[int(noise[x][y] * len(SCORCH)) % len(SCORCH)]
    return shade(base, (patches[y][x] - 0.5) * 22 + (veins[y][x] - 0.5) * 10)


def draw_floor(code: int, patches, veins, noise, wobble) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = corners(code, x, y) + (wobble[y][x] - 0.5) * 0.3
            if here >= 0.5:
                px[x, y] = floor_pixel(x, y, patches, veins, noise) + (255,)
            elif here >= 0.42:
                # Singed grass round the floor: a dark fringe, broken.
                if noise[y][x] > 0.35:
                    px[x, y] = (34, 30, 22, 200)
    return im


def draw_rim(code: int, clods, noise, wobble) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            # Heaped wider than its own cells, so it rings the floor with no grass between.
            here = corners(code, x, y) + (wobble[y][x] - 0.5) * 0.35
            if here < 0.28:
                continue
            c = clods[y][x]
            above = clods[(y - 2) % T][x]
            if noise[y][x] > 0.97:
                colour = PEBBLE
            elif c > 0.62 and above <= 0.62:
                colour = CLOD_TOP
            elif c < 0.38:
                colour = CLOD_DARK
            else:
                colour = shade(CLOD[int(noise[x][y] * len(CLOD)) % len(CLOD)], (c - 0.5) * 30)
            px[x, y] = colour + (255,)
    return im


def sheet_of(draw) -> Image.Image:
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw(code), (cx * T, cy * T))
    return sheet


def shard(glint: float) -> Image.Image:
    """A sliver of something bright, half sunk, with a glint travelling along it."""
    im = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = im.load()
    pts = [(10, 26), (14, 8), (19, 6), (22, 26)]
    for y in range(32):
        for x in range(32):
            # Inside the quad: on the same side of all four edges.
            sides = [(pts[(i + 1) % 4][0] - pts[i][0]) * (y - pts[i][1]) - (pts[(i + 1) % 4][1] - pts[i][1]) * (x - pts[i][0]) for i in range(4)]
            inside = all(s >= 0 for s in sides) or all(s <= 0 for s in sides)
            if inside:
                lit = 1.0 if abs((y - 6) / 20 - glint) < 0.12 and glint >= 0 else 0.0
                base = SHARD_DARK if x < 15 else SHARD
                px[x, y] = shade(base, 60 * lit) + (255,)
    # The earth it is sunk in: a dark lip at its foot.
    for x in range(7, 26):
        for y in range(25, 29):
            if px[x, y][3] == 0 or y >= 27:
                px[x, y] = CLOD_DARK + (255,)
    return im


def map_icon() -> Image.Image:
    """The crater from above for the map, 64 x 64: a scorched bowl in a ring of thrown-up earth, a
    shard catching the light in the middle, and the furrow it ploughed coming in from the top left."""
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    noise = grain(31)
    cx, cy, rx, ry = 33.0, 36.0, 25.0, 19.0
    for y in range(T):
        for x in range(T):
            d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2
            n = noise[y][x]
            if d <= 0.62:
                base = SCORCH[int(n * len(SCORCH)) % len(SCORCH)]
                # Darker towards the middle, where it came down hardest.
                px[x, y] = shade(base, -18 * (1.0 - d)) + (255,)
            elif d <= 1.0:
                top = y < cy and d < 0.85
                base = CLOD_TOP if top else CLOD[int(n * len(CLOD)) % len(CLOD)]
                px[x, y] = shade(base, 10 * (n - 0.5)) + (255,)
            elif d <= 1.12:
                px[x, y] = CLOD_DARK + (255,)
    # The furrow ploughed on the way in.
    for i in range(20):
        fx, fy = 2 + i, 4 + int(i * 0.8)
        for w in range(-2, 3):
            if 0 <= fy + w < T and px[fx, fy + w][3] == 0:
                px[fx, fy + w] = (CLOD_DARK if abs(w) < 2 else CLOD[i % len(CLOD)]) + (255,)
    # Embers in the cracks, and the shard.
    for x, y in [(26, 38), (40, 33), (30, 44), (37, 41)]:
        px[x, y] = CRACK + (255,)
        px[x + 1, y] = CRACK_DIM + (255,)
    glint = shard(0.4).resize((20, 20), Image.NEAREST)
    im.alpha_composite(glint, (23, 21))
    return im


def lay_the_crater() -> None:
    """The crater's floor cells beside grass become rim; the legend and layers gain the new ground."""
    text = AREA.read_text()
    if '"r": "crater_rim"' in text:
        return
    area = json.loads(text)
    rows = area["rows"]
    h, w = len(rows), len(rows[0])
    grid = [list(r) for r in rows]
    for y in range(h):
        # The narrow trail out below the crater stays the trodden dirt it was.
        if y > h // 2 and rows[y].count(",") <= 3:
            grid[y] = list(rows[y].replace(",", "d"))
            continue
        for x in range(w):
            if rows[y][x] != ",":
                continue
            near = [(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]
            if any(0 <= nx < w and 0 <= ny < h and rows[ny][nx] not in ",d" and grid[ny][nx] != "d" for nx, ny in near):
                grid[y][x] = "r"
    new_rows = ["".join(r) for r in grid]
    for old, new in zip(rows, new_rows):
        text = text.replace('"%s"' % old, '"%s"' % new, 1)
    text = text.replace('"layers": [\n    "dirt",\n    "meadow"\n  ]', '"layers": [\n    "dirt",\n    "meadow",\n    "crater_floor",\n    "crater_rim"\n  ]', 1)
    text = text.replace('",": "dirt",', '",": "crater_floor",\n    "r": "crater_rim",\n    "d": "dirt",', 1)
    AREA.write_text(text)
    area = json.loads(text)
    assert area["layers"][-2:] == ["crater_floor", "crater_rim"], area["layers"]
    assert area["rows"] == new_rows


def place_shards() -> None:
    text = AREA.read_text()
    if "crater/shard" in text:
        return
    marker = '"props": [\n'
    added = ""
    for cell in SHARDS:
        added += '    {\n      "art": "crater/shard",\n      "cell": [\n        %d,\n        %d\n      ]\n    },\n' % (cell[0], cell[1])
    AREA.write_text(text.replace(marker, marker + added, 1))
    json.loads(AREA.read_text())


def main() -> None:
    (ROOT / "art" / "world").mkdir(parents=True, exist_ok=True)
    map_icon().save(ROOT / "art" / "world" / "crater.png")
    if "--icon" in sys.argv:
        print("wrote art/world/crater.png")
        return
    TILES.mkdir(parents=True, exist_ok=True)
    PROPS.mkdir(parents=True, exist_ok=True)
    patches = smooth_noise(21, 8)
    veins = smooth_noise(22, 8)
    clods = smooth_noise(23, 16)
    noise = grain(24)
    wobble = grain(25)
    sheet_of(lambda code: draw_floor(code, patches, veins, noise, wobble)).save(TILES / "crater_floor.png")
    sheet_of(lambda code: draw_rim(code, clods, noise, wobble)).save(TILES / "crater_rim.png")
    shard(-1).save(PROPS / "shard.png")
    frames = PROPS / "shard"
    frames.mkdir(exist_ok=True)
    for i in range(6):
        # Dark most of the time, then a glint runs up it.
        shard(-1 if i < 3 else (i - 3) / 2.0).save(frames / ("frame_%03d.png" % i))
    lay_the_crater()
    place_shards()
    print("wrote art/tilesets/crater/, art/props/crater/shard; laid data/areas/home.json")


if __name__ == "__main__":
    main()
