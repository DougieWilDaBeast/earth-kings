#!/usr/bin/env python3
"""Draw the Tower's floors: dressed slabs underfoot, coursed masonry walls, a runner to the stair.

    python3 tools/draw_tower_floors.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

Meeting 4 (D123) asked for floors 1 to 5 that read as the inside of a Tower. They were laid in the
land's own sheets: broken stone over grass, and rock faces with grass round them, so a floor looked
like a quarry in a field. D129 draws three sheets in house, in the 24 x 8 layout every PixelLab
"godot" sheet shares (src/area/tile_forge.gd):

- art/tilesets/tower/tower_slab.png: square flagstones, a few cracked, the same on every tile, so it can lie under
  everything else;
- art/tilesets/tower/tower_wall.png: coursed masonry where a corner is wall, a lit edge, and a soft
  shadow cast onto the floor round it; see-through elsewhere;
- art/tilesets/tower/tower_runner.png: a red runner with a gold edge, from the way in to the stair;
  see-through elsewhere.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "tower"
T = 64

# Corner code (NW*8 + NE*4 + SW*2 + SE) -> where it sits on the sheet (tile_forge.gd).
WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

SLAB = [(132, 126, 120), (124, 118, 113), (138, 132, 125), (118, 113, 108)]
SLAB_JOINT = (70, 64, 62)
SLAB_LIGHT = (156, 150, 142)
BRICK = [(64, 60, 76), (58, 55, 70), (70, 66, 82), (54, 51, 66)]
BRICK_JOINT = (28, 26, 34)
BRICK_LIGHT = (88, 84, 102)
RIM = (138, 134, 150)
RUNNER = (120, 30, 34)
RUNNER_DARK = (98, 22, 28)
TRIM = (196, 156, 72)
TRIM_DARK = (140, 104, 44)


def grain(seed: int) -> list[list[float]]:
    rng = random.Random(seed)
    return [[rng.random() for _ in range(T)] for _ in range(T)]


def shade(colour: tuple, amount: float) -> tuple:
    return tuple(max(0, min(255, int(c + amount))) for c in colour)


def slab_pixel(x: int, y: int, noise) -> tuple:
    """Square flagstones, two to a tile each way, each its own shade, a few cracked."""
    cell = (x // 32, y // 32)
    lx, ly = x % 32, y % 32
    if lx == 0 or ly == 0:
        return SLAB_JOINT
    if lx == 1 or ly == 1:
        return SLAB_LIGHT
    if lx == 31 or ly == 31:
        return shade(SLAB_JOINT, 18)
    base = SLAB[(cell[0] * 3 + cell[1] * 5) % len(SLAB)]
    # One slab in four has a crack across it.
    if (cell[0] + cell[1] * 2) % 4 == 1 and abs((lx - 6) - (ly - 4) * 0.7 - math.sin(ly * 0.6) * 2) < 0.8 and 4 < lx < 28:
        return shade(base, -18)
    return shade(base, (noise[y][x] - 0.5) * 10)


def brick_pixel(x: int, y: int, noise) -> tuple:
    """Courses of long blocks, sixteen pixels high, staggered."""
    course = y // 16
    bx = (x + (16 if course % 2 else 0)) % T
    lx, ly = bx % 32, y % 16
    if lx == 0 or ly == 0:
        return BRICK_JOINT
    if ly == 1:
        return BRICK_LIGHT
    base = BRICK[((bx // 32) * 7 + course * 3) % len(BRICK)]
    return shade(base, (noise[y][x] - 0.5) * 12)


def corners(code: int, x: int, y: int) -> float:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    u, v = (x + 0.5) / T, (y + 0.5) / T
    return nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v


def draw_slab(noise) -> Image.Image:
    im = Image.new("RGBA", (T, T))
    px = im.load()
    for y in range(T):
        for x in range(T):
            px[x, y] = slab_pixel(x, y, noise) + (255,)
    return im


def draw_wall(code: int, noise) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = corners(code, x, y)
            if here >= 0.5:
                # The lit lip where the wall meets the floor, then the coursed stone.
                px[x, y] = (RIM if here < 0.56 else brick_pixel(x, y, noise)) + (255,)
            elif here >= 0.36:
                # A shadow cast on the slabs, darkest against the wall.
                px[x, y] = (12, 10, 18, int(150 * (here - 0.36) / 0.14))
    return im


def draw_runner(code: int, noise) -> Image.Image:
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            here = corners(code, x, y)
            if here < 0.5:
                continue
            if here < 0.54:
                colour = TRIM_DARK
            elif here < 0.6:
                colour = TRIM
            else:
                # A woven diamond, faint, so the runner is cloth and not paint.
                diamond = (abs((x % 16) - 8) + abs((y % 16) - 8)) == 6
                colour = RUNNER_DARK if diamond else shade(RUNNER, (noise[y][x] - 0.5) * 8)
            px[x, y] = colour + (255,)
    return im


def sheet_of(draw) -> Image.Image:
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw(code), (cx * T, cy * T))
    return sheet


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    noise = grain(4)
    slab = draw_slab(noise)
    sheet_of(lambda code: slab).save(OUT / "tower_slab.png")
    sheet_of(lambda code: draw_wall(code, noise)).save(OUT / "tower_wall.png")
    sheet_of(lambda code: draw_runner(code, noise)).save(OUT / "tower_runner.png")
    print("wrote art/tilesets/tower/tower_slab.png, tower_wall.png, tower_runner.png")


if __name__ == "__main__":
    main()
