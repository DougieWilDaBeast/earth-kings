#!/usr/bin/env python3
"""Draw the First Hour's road: a laid cobble road that lies over any land's ground.

    python3 tools/draw_road.py

Needs Pillow (`pip install pillow`), like tools/draw_walls.py.

Meeting 3 (2026-10-15) and Will found the way through the First Hour hard to read: every tile of
the land has worn paths out of all four sides, so nothing on the ground says which way to go.
D126 lays a road from the crater to the great city, the first gate and the Tower
(src/area/first_road.gd). This draws its tile sheet in house, until PixelLab has credits.

Writes art/tilesets/road.png, 1536 x 512: the 24 x 8 layout every PixelLab "godot" sheet shares
(src/area/tile_forge.gd), with only the corner tiles the game reads drawn in. A tile is picked by
its four corners; where a corner is road the cobbles are laid, and off the road the sheet is
see-through, so it lies over grass, bog or ash alike. Everything repeats every 64 pixels, so any
tile meets any other without a seam.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "road.png"
T = 64

# Corner code (NW*8 + NE*4 + SW*2 + SE) -> where it sits on the sheet (tile_forge.gd).
WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

INK = (34, 26, 24)
KERB = (92, 78, 62)
KERB_LIGHT = (128, 112, 90)
STONES = [(150, 136, 112), (138, 124, 102), (160, 146, 120), (128, 116, 98), (146, 128, 104)]
GAP = (70, 58, 46)


def wrap(d: float) -> float:
    d = abs(d) % T
    return min(d, T - d)


def cobbles() -> tuple[list[list[int]], list[list[float]]]:
    """A 64-pixel tile of cobbles that repeats: which stone each pixel is, and how far it is
    from the stone's edge."""
    rng = random.Random(12)
    seeds = []
    n = 5
    for gy in range(n):
        for gx in range(n):
            off = 0.5 if gy % 2 else 0.0
            seeds.append((((gx + off) * T / n + rng.uniform(-2.5, 2.5)) % T,
                          (gy * T / n + rng.uniform(-2.0, 2.0)) % T))
    which = [[0] * T for _ in range(T)]
    edge = [[0.0] * T for _ in range(T)]
    for y in range(T):
        for x in range(T):
            ds = sorted((math.hypot(wrap(x - sx), wrap(y - sy) * 1.25), i) for i, (sx, sy) in enumerate(seeds))
            which[y][x] = ds[0][1]
            edge[y][x] = ds[1][0] - ds[0][0]
    return which, edge


def noise() -> list[list[float]]:
    """Smooth noise that repeats every 64 pixels, for a worn, uneven road edge."""
    rng = random.Random(3)
    g = 8
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


def draw_tile(code: int, which, edge, wobble) -> Image.Image:
    nw, ne, sw, se = (code >> 3) & 1, (code >> 2) & 1, (code >> 1) & 1, code & 1
    im = Image.new("RGBA", (T, T), (0, 0, 0, 0))
    px = im.load()
    for y in range(T):
        for x in range(T):
            u, v = (x + 0.5) / T, (y + 0.5) / T
            road = (nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v)
            road += (wobble[y][x] - 0.5) * 0.22
            if road < 0.44:
                continue
            if road < 0.5:
                px[x, y] = INK + (255,)
            elif road < 0.58:
                # The kerb: packed earth and the edge stones, lit along their top.
                px[x, y] = (KERB_LIGHT if (y + x // 6) % 5 == 0 else KERB) + (255,)
            else:
                stone = STONES[which[y][x] % len(STONES)]
                e = edge[y][x]
                if e < 1.6:
                    colour = GAP
                elif e < 3.0 and (which[y][(x - 2) % T] != which[y][x] or which[(y - 2) % T][x] != which[y][x]):
                    colour = tuple(min(255, c + 22) for c in stone)
                elif e < 3.0:
                    colour = tuple(max(0, c - 24) for c in stone)
                else:
                    colour = stone
                px[x, y] = colour + (255,)
    return im


def main() -> None:
    which, edge = cobbles()
    wobble = noise()
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw_tile(code, which, edge, wobble), (cx * T, cy * T))
    sheet.save(OUT)
    print("wrote art/tilesets/road.png")


if __name__ == "__main__":
    main()
