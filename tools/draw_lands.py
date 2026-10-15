#!/usr/bin/env python3
"""Draw the jungle's and the barrow downs' ground, pools and cover in house.

    python3 tools/draw_lands.py [land ...]

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

The road from the crater to Stormreach runs through barrow downs and jungle, and both lands were
stand-ins: the grassland's sheets recoloured (tools/recolour_biomes.py). The grassland is drawn as
raised turf with cliff faces down to the earth, so recoloured it put grey slabs and ledges all over
the downs; and the three sheets of each land were recoloured apart, so the floor in the pool sheet
and the cover sheet was a different green from the floor in the ground sheet, and the land showed
in squares. D138 draws all three for both lands from one set of pixels each, flat and soft-edged,
in the 24 x 8 layout every PixelLab "godot" sheet shares (src/area/tile_forge.gd):

- art/tilesets/biome/<land>_ground.png: the land's floor where a corner is floor, its bare earth
  where it is not, a worn uneven edge between;
- art/tilesets/biome/<land>_pool.png: the floor round a pool of the land's water, a dark bank;
- art/tilesets/biome/<land>_cover.png: the land's tall growth over its floor.

The floor is the same pixels in all three, so they meet without a seam. Pools are drawn at 64
pixels, like the rest, rather than the 32 the stand-ins were (data/tilesets.json `tile_size`).
Re-run tools/draw_edges.py afterwards: the blend sheets between lands take each land's floor tile.
"""

from __future__ import annotations

import json
import random
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "tilesets" / "biome"
TILESETS = ROOT / "data" / "tilesets.json"
T = 64

WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0), 0b0100: (0, 5), 0b0101: (0, 2),
    0b0111: (4, 2), 0b1000: (1, 5), 0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}

# Each land: floor, bare earth, water and cover, each a few base colours and a speckle; the edge
# colour is the dark seam where one meets the other.
LANDS = {
    "jungle": {
        "floor": [(46, 104, 44), (40, 94, 40), (52, 112, 48), (36, 86, 38)],
        "floor_fleck": [(78, 140, 58), (96, 62, 36)],
        "bare": [(98, 60, 40), (88, 54, 36), (106, 68, 46)],
        "bare_fleck": [(66, 40, 28), (128, 86, 58)],
        "liquid": [(34, 78, 70), (30, 70, 64), (38, 86, 76)],
        "liquid_glint": (96, 150, 128),
        "cover": [(22, 70, 34), (28, 82, 40), (18, 60, 30)],
        "cover_lit": (70, 132, 60),
        "edge": (26, 52, 26),
        "bank": (52, 40, 28),
    },
    "barrow": {
        "floor": [(104, 116, 84), (96, 108, 78), (110, 122, 90), (90, 102, 74)],
        "floor_fleck": [(132, 140, 104), (78, 86, 62)],
        "bare": [(176, 170, 150), (166, 160, 140), (184, 178, 158)],
        "bare_fleck": [(110, 106, 98), (208, 204, 188)],
        "liquid": [(40, 46, 50), (36, 42, 46), (46, 52, 56)],
        "liquid_glint": (110, 124, 128),
        "cover": [(132, 122, 84), (122, 112, 76), (142, 132, 92)],
        "cover_lit": (178, 168, 120),
        "edge": (64, 72, 52),
        "bank": (70, 64, 52),
    },
}


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


class Painter:
    """One land's pixels: every sheet asks here, so the floor is the same everywhere."""

    def __init__(self, land: str, seed: int) -> None:
        self.p = LANDS[land]
        self.soft = smooth_noise(seed + 1, 8)
        self.leaves = smooth_noise(seed + 2, 16)
        self.noise = grain(seed + 3)
        self.wobble = grain(seed + 4)

    def _mottle(self, key: str, x: int, y: int, spread: float) -> tuple:
        # A dither of close colours, pixel by pixel, so no shape repeats tile to tile; only a soft
        # light and shade lies over it.
        cols = self.p[key]
        base = cols[int(self.noise[x][y] * len(cols) * 0.999)]
        return shade(base, (self.soft[y][x] - 0.5) * spread * 0.5)

    def floor(self, x: int, y: int) -> tuple:
        n = self.noise[y][x]
        if n > 0.975:
            return self.p["floor_fleck"][0]
        if n < 0.012:
            return self.p["floor_fleck"][1]
        # Short blades: a lighter pixel over a darker one, here and there.
        if self.noise[(y + 1) % T][x] > 0.93:
            return shade(self._mottle("floor", x, y, 18), 14)
        return self._mottle("floor", x, y, 18)

    def bare(self, x: int, y: int) -> tuple:
        n = self.noise[y][x]
        if n > 0.97:
            return self.p["bare_fleck"][1]
        if n < 0.03:
            return self.p["bare_fleck"][0]
        return self._mottle("bare", x, y, 16)

    def liquid(self, x: int, y: int) -> tuple:
        # Slow ripples: short light dashes in rows.
        if (y % 9 == 0 or y % 9 == 4) and self.leaves[y][x] > 0.62 and self.noise[y][x] > 0.4:
            return self.p["liquid_glint"]
        return self._mottle("liquid", x, y, 10)

    def cover(self, x: int, y: int) -> tuple:
        # Clumps of growth, lit on their top edge, dark in the gaps between them.
        c = self.leaves[y][x]
        above = self.leaves[(y - 2) % T][x]
        if c > 0.6 and above <= 0.6:
            return self.p["cover_lit"]
        if c < 0.32:
            return shade(self.p["cover"][2], -16)
        return self._mottle("cover", x, y, 20)

    def tile(self, code: int, upper, lower, edge: tuple, ragged: float, band: float) -> Image.Image:
        """`upper` where the corners are set, `lower` where not, a dark seam of width `band`."""
        im = Image.new("RGBA", (T, T))
        px = im.load()
        for y in range(T):
            for x in range(T):
                here = corners(code, x, y) + (self.wobble[y][x] - 0.5) * ragged + (self.soft[y][x] - 0.5) * 0.2
                if here >= 0.5:
                    px[x, y] = upper(x, y) + (255,)
                elif here >= 0.5 - band:
                    px[x, y] = edge + (255,)
                else:
                    px[x, y] = lower(x, y) + (255,)
        return im


def sheet_of(draw) -> Image.Image:
    sheet = Image.new("RGBA", (24 * T, 8 * T), (0, 0, 0, 0))
    for code, (cx, cy) in WANG.items():
        sheet.paste(draw(code), (cx * T, cy * T))
    return sheet


def draw_land(land: str, seed: int) -> None:
    p = Painter(land, seed)
    edge = LANDS[land]["edge"]
    bank = LANDS[land]["bank"]
    sheet_of(lambda c: p.tile(c, p.floor, p.bare, edge, 0.3, 0.05)).save(OUT / ("%s_ground.png" % land))
    sheet_of(lambda c: p.tile(c, p.floor, p.liquid, bank, 0.12, 0.09)).save(OUT / ("%s_pool.png" % land))
    sheet_of(lambda c: p.tile(c, p.cover, p.floor, edge, 0.4, 0.04)).save(OUT / ("%s_cover.png" % land))


def mark_drawn(lands: list[str]) -> None:
    """The sheets are no longer stand-ins, and the pools are 64-pixel tiles now."""
    data = json.loads(TILESETS.read_text())
    for land in lands:
        for kind in ("ground", "pool", "cover"):
            sheet = data["sheets"]["%s_%s" % (land, kind)]
            sheet.pop("stand_in", None)
            sheet["tile_size"] = T
    TILESETS.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n")


def main() -> None:
    lands = sys.argv[1:] or list(LANDS)
    for i, land in enumerate(sorted(LANDS)):
        if land in lands:
            draw_land(land, 40 + i * 10)
    mark_drawn(lands)
    print("wrote art/tilesets/biome/<land>_ground|pool|cover.png for %s" % ", ".join(lands))


if __name__ == "__main__":
    main()
