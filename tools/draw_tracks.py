#!/usr/bin/env python3
"""Draw the land's footpaths and dirt tracks: worn earth that lies over any land's ground.

    python3 tools/draw_tracks.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

`doug-md`, play-test 4 (2026-10-17): "Set up a lot more... dirt [roads], paths. Make an art request
for... just roads and... types of walkways. Footpaths." He picked footpaths and dirt tracks (D221).
Every tile's worn paths become footpaths, and dirt tracks run between the places people live
(src/area/tracks.gd). These two sheets are drawn in house as stand-ins until `dougie` makes them
in PixelLab (A32 in docs/24).

Writes art/tilesets/footpath.png and art/tilesets/track.png, each 1536 x 512: the 24 x 8 layout
every PixelLab "godot" sheet shares (src/area/tile_forge.gd), with only the corner tiles the game
reads drawn in, as tools/draw_road.py does. Off the path the sheet is see-through, so it lies over
grass, snow or ash alike; everything repeats every 64 pixels.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
T = 64

# Corner code (NW*8 + NE*4 + SW*2 + SE) -> where it sits on the sheet (tile_forge.gd).
WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

# A footpath: trodden earth, soft at the edge where the grass laps over it.
FOOTPATH = {
    "out": "footpath.png",
    "edge": 0.47,
    "rim": 0.53,
    "rim_colour": (88, 70, 50),
    "earth": [(118, 96, 70), (110, 89, 64), (124, 101, 74)],
    "dark": (96, 77, 55),
    "pebble": (150, 134, 108),
    "pebbles": 0.010,
    "wobble": 0.30,
    "seed": 21,
}

# A dirt track: wider packed earth, paler and greyer from carts, with stones in it.
TRACK = {
    "out": "track.png",
    "edge": 0.44,
    "rim": 0.52,
    "rim_colour": (82, 66, 48),
    "earth": [(134, 112, 84), (126, 105, 78), (140, 118, 88)],
    "dark": (108, 88, 64),
    "pebble": (164, 150, 124),
    "pebbles": 0.022,
    "wobble": 0.22,
    "seed": 34,
}


def noise(seed: int, grid: int) -> list[list[float]]:
    """Smooth noise that repeats every 64 pixels."""
    rng = random.Random(seed)
    lattice = [[rng.random() for _ in range(grid)] for _ in range(grid)]
    out = [[0.0] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            fx, fy = x / T * grid, y / T * grid
            x0, y0 = int(fx) % grid, int(fy) % grid
            x1, y1 = (x0 + 1) % grid, (y0 + 1) % grid
            tx, ty = fx - int(fx), fy - int(fy)
            tx, ty = tx * tx * (3 - 2 * tx), ty * ty * (3 - 2 * ty)
            a = lattice[y0][x0] + (lattice[y0][x1] - lattice[y0][x0]) * tx
            b = lattice[y1][x0] + (lattice[y1][x1] - lattice[y1][x0]) * tx
            out[y][x] = a + (b - a) * ty
    return out


def draw_tile(code: int, look: dict, wobble, grain, stones) -> Image.Image:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            u, v = (x + 0.5) / T, (y + 0.5) / T
            path = nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v
            path += (wobble[y][x] - 0.5) * look["wobble"]
            if path < look["edge"]:
                continue
            if path < look["rim"]:
                # The worn edge: darker earth, broken up so the grass seems to lap over it.
                if grain[y][x] < 0.35:
                    continue
                px[x, y] = look["rim_colour"] + (255,)
                continue
            if (x, y) in stones:
                px[x, y] = look["pebble"] + (255,)
                continue
            g = grain[y][x]
            if g < 0.3:
                colour = look["dark"]
            else:
                colour = look["earth"][int(g * 97) % len(look["earth"])]
            px[x, y] = colour + (255,)
    return im


def draw(look: dict) -> None:
    rng = random.Random(look["seed"])
    wobble = noise(look["seed"], 8)
    grain = noise(look["seed"] + 1, 16)
    stones = set()
    for _ in range(int(T * T * look["pebbles"])):
        x, y = rng.randrange(T), rng.randrange(T)
        stones.add((x, y))
        if rng.random() < 0.5:
            stones.add(((x + 1) % T, y))
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw_tile(code, look, wobble, grain, stones), (cx * T, cy * T))
    out = ROOT / "art" / "tilesets" / look["out"]
    sheet.save(out)
    print(f"wrote art/tilesets/{look['out']}")


def main() -> None:
    draw(FOOTPATH)
    draw(TRACK)


if __name__ == "__main__":
    main()
