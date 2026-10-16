#!/usr/bin/env python3
"""Draw the huge Tower's shaft in house: a round tower of rune-cut stone going up out of sight.

    python3 tools/draw_great_tower.py

Needs Pillow (`pip install pillow`), like tools/draw_road.py.

Until now the shaft over the Tower's door (D108) was the town walls' stone laid course on course by
src/area/area_spire.gd: a flat dark block with a grid of windows, which read as a big keep, not as
the thing the whole world climbs. Art request A9 asks for the huge Tower; PixelLab has no credits,
so D158 draws it here, in the door's own stone and runes (tools/draw_tower.py, D111), until A9 lands:

- art/props/landmark/tower_shaft.png   896 x 1792, the shaft at one pixel to a pixel (a cell is 64),
  standing on its foot at the bottom middle. It is round: its blocks narrow towards its sides and it
  is lit from the left. Ribs run up it, every three storeys a band of runes circles it, slit windows
  are lit warm low down and cold higher up, and it steps in every six storeys under a cornice. It
  goes pale with height and is lost in the sky with cloud across it, because it does not end.

data/areas/tower.json names it (`spire.art`); area_spire.gd draws it in place of the courses.
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "landmark" / "tower_shaft.png"

W, H = 896, 1792
CX = W // 2
R0 = 320            # half the shaft's width at its foot: ten cells across, like the stand-in
STEP_EVERY = 384    # it steps in every six storeys...
STEP_IN = 22        # ...by this much each side
COURSE = 16         # one course of blocks
BAND_EVERY = 192    # a band of runes every three storeys
FADE_FROM = 0.42    # share of the height where it starts to be lost in the sky
PLINTH = 40

# The door's stone (tools/draw_tower.py), darkest to lightest, and its runes.
INK = (19, 14, 35)
STONE = [(22, 18, 38), (37, 45, 62), (45, 55, 73), (65, 75, 96), (80, 89, 112), (108, 121, 149),
         (112, 125, 154), (150, 166, 196)]
MORTAR = (28, 26, 46)
RUNE_DIM = (40, 120, 150)
RUNE_LIT = (150, 250, 255)
RUNE_CORE = (236, 255, 255)
WINDOW = (240, 194, 104)
WINDOW_DIM = (150, 96, 60)
HAZE = (176, 190, 214)
CLOUD = (228, 234, 244)

GLYPHS = [
    [(2, 0, 2, 6), (0, 2, 2, 0), (2, 0, 4, 2)],
    [(0, 0, 0, 6), (0, 0, 4, 3), (4, 3, 0, 6)],
    [(2, 0, 2, 6), (0, 3, 4, 3)],
    [(0, 6, 2, 0), (2, 0, 4, 6), (1, 3, 3, 3)],
    [(0, 0, 4, 6), (4, 0, 0, 6)],
    [(0, 0, 0, 6), (4, 0, 4, 6), (0, 3, 4, 3)],
    [(2, 0, 2, 6), (2, 2, 4, 0), (2, 2, 0, 0)],
    [(0, 6, 0, 0), (0, 0, 4, 0), (4, 0, 4, 3), (4, 3, 0, 3)],
]
RIBS = [-1.05, -0.52, 0.0, 0.52, 1.05]
RIB_HALF = 0.07
BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def mix(a: tuple, b: tuple, t: float) -> tuple:
    t = max(0.0, min(1.0, t))
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def stone(level: float) -> tuple:
    """A stone colour from the palette, 0 darkest to 1 lightest, no blending between entries."""
    return STONE[max(0, min(len(STONE) - 1, int(level * len(STONE))))]


def radius(up: int) -> float:
    """Half the shaft's width `up` pixels above its foot."""
    if up < PLINTH:
        return R0 + 12 + 12 * (2 - up // 14)
    return R0 - STEP_IN * ((up - PLINTH) // STEP_EVERY)


def _segment_distance(x: float, y: float, a: tuple, b: tuple) -> float:
    ax, ay, bx, by = a[0], a[1], b[0], b[1]
    dx, dy = bx - ax, by - ay
    t = 0.0 if dx == dy == 0 else max(0.0, min(1.0, ((x - ax) * dx + (y - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(x - (ax + t * dx), y - (ay + t * dy))


def glyph_hit(which: int, gx: float, gy: float) -> float:
    """How far (in glyph units) a point on a 4 x 6 glyph grid is from its strokes."""
    return min(_segment_distance(gx, gy, (s[0], s[1]), (s[2], s[3])) for s in GLYPHS[which % len(GLYPHS)])


def shaft_pixel(x: int, y: int, rng_block, haze_noise) -> tuple | None:
    up = H - 1 - y
    r = radius(up)
    u = (x - CX) / r
    if abs(u) >= 1.0:
        return None
    theta = math.asin(u)
    high = up / H
    # Lit from the left and a little in front; darker into its far side.
    light = 0.3 + 0.44 * math.cos(theta + 0.5) - 0.3 * abs(u) ** 4
    # Its foot: three broad steps of big blocks.
    if up < PLINTH:
        light += 0.08 if up % 14 >= 11 else 0.0
        if up % 14 == 0:
            return stone(light - 0.3)
        return stone(light + (rng_block(up // 14, int((theta + 2) / 0.4)) - 0.5) * 0.12)
    above = up - PLINTH
    in_step = above % STEP_EVERY
    # A cornice where it steps in: a lit lip over a band of shadow.
    if in_step >= STEP_EVERY - 10 and above < H:
        if in_step >= STEP_EVERY - 3:
            return stone(light + 0.25)
        return stone(light - 0.2 - (STEP_EVERY - 1 - in_step) * 0.01)
    if in_step < 6:
        return stone(light - 0.32)
    # A rib: a raised pillar, lit on its left edge, dark on its right.
    for rib in RIBS:
        d = theta - rib
        if abs(d) < RIB_HALF:
            edge = d / RIB_HALF
            return stone(light + (0.2 if edge < -0.55 else (-0.18 if edge > 0.55 else 0.06)))
    # The band of runes, every three storeys.
    in_band = above % BAND_EVERY
    if 92 <= in_band < 112:
        band_y = in_band - 92
        if band_y in (0, 19):
            return stone(light - 0.12)
        fore = math.cos(theta)
        slot = math.floor((theta + 3.0) / 0.13)
        within = ((theta + 3.0) / 0.13 - slot)
        gx = (within - 0.2) / 0.6 * 4.0
        gy = (band_y - 3) / 13.0 * 6.0
        if 0 <= gy <= 6 and -0.6 <= gx <= 4.6:
            d = glyph_hit(slot + above // BAND_EVERY, gx, gy)
            glow = max(0.0, 1.0 - high * 1.3)
            if d < 0.55 * (0.6 + 0.4 * fore):
                return mix(RUNE_DIM, RUNE_LIT if glow > 0.3 else RUNE_DIM, glow) if fore > 0.25 else RUNE_DIM
            if d < 1.2 and glow > 0.2:
                return mix(stone(light - 0.25), RUNE_DIM, glow * (1.2 - d))
        return stone(light - 0.25)
    # Slit windows between the ribs, one storey in two.
    if 30 <= in_band < 56 or 126 <= in_band < 152:
        for mid in (-0.78, -0.26, 0.26, 0.78):
            half = 3.2 * math.cos(mid) / (r * math.cos(theta) + 1e-6)
            top = 30 if in_band < 56 else 126
            # A pointed head: narrower over its top three pixels.
            narrow = max(0, 3 - (top + 25 - in_band)) * 0.3
            if abs(theta - mid) < half * (1 - narrow):
                lit = high < 0.32 and (int(mid * 10) + above // 96) % 3 != 0
                return WINDOW if lit else (WINDOW_DIM if high < 0.2 else stone(light - 0.42))
            if abs(theta - mid) < half + 1.2 / (r * math.cos(theta) + 1e-6):
                return stone(light - 0.3)
    # The blocks: courses of stone, their joints closer together towards its sides.
    course = above // COURSE
    if above % COURSE == 0:
        return MORTAR if light > 0.35 else stone(light - 0.3)
    width = 0.24
    offset = (course % 2) * width / 2
    k = (theta + 3.0 + offset) / width
    if (k - math.floor(k)) * width * r * math.cos(theta) < 1.4:
        return MORTAR if light > 0.35 else stone(light - 0.3)
    jitter = (rng_block(course, int(math.floor(k))) - 0.5) * 0.14
    # A lighter top course on each block, as if catching the light.
    if above % COURSE == COURSE - 1:
        jitter += 0.06
    return stone(light + jitter + (haze_noise[y % 64][x % 64] - 0.5) * 0.05)


def draw() -> Image.Image:
    rng = random.Random(11)
    blocks: dict = {}

    def rng_block(a: int, b: int) -> float:
        if (a, b) not in blocks:
            blocks[(a, b)] = random.Random(a * 7919 + b * 104729).random()
        return blocks[(a, b)]

    haze_noise = [[rng.random() for _ in range(64)] for _ in range(64)]
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    for y in range(H):
        up = H - 1 - y
        high = up / H
        haze = max(0.0, (high - 0.12) / 0.9) ** 1.3 * 0.85
        alpha = 1.0 if high <= FADE_FROM else max(0.0, 1.0 - (high - FADE_FROM) / (0.97 - FADE_FROM))
        for x in range(W):
            c = shaft_pixel(x, y, rng_block, haze_noise)
            if c is None:
                continue
            c = mix(c, HAZE, haze)
            # Lost in the sky by steps, dithered, so the pixels stay whole.
            if alpha < 1.0 and alpha * 16 <= BAYER[y % 4][x % 4]:
                continue
            px[x, y] = c + (255,)
    # A dark outline round it, low down where it stands whole.
    solid = im.copy().load()
    for y in range(H):
        if (H - 1 - y) / H > FADE_FROM:
            continue
        for x in range(1, W - 1):
            if solid[x, y][3] == 0 and (solid[x - 1, y][3] or solid[x + 1, y][3]):
                px[x, y] = INK + (255,)
    # Cloud lying across it where it is lost: soft dithered banks, wider than the shaft.
    for cy, half, seed in ((int(H * 0.4), 280, 3), (int(H * 0.16), 360, 5)):
        crng = random.Random(seed)
        puffs = [(CX + crng.uniform(-half, half), cy + crng.uniform(-10, 10), crng.uniform(18, 40))
                 for _ in range(16)]
        for y in range(max(0, cy - 90), min(H, cy + 90)):
            for x in range(W):
                v = 0.0
                for (pxc, pyc, pr) in puffs:
                    dx, dy = (x - pxc) / (pr * 3.2), (y - pyc) / pr
                    v = max(v, 1.0 - (dx * dx + dy * dy))
                if v <= 0:
                    continue
                level = v * 1.6
                if level * 16 <= BAYER[y % 4][x % 4] + 4:
                    continue
                base = px[x, y]
                shade = CLOUD if y < max(pyc for (_, pyc, _) in puffs) - 6 else mix(CLOUD, HAZE, 0.6)
                if base[3]:
                    px[x, y] = mix(base[:3], shade, 0.55 + 0.4 * min(1.0, v)) + (255,)
                elif v > 0.35:
                    px[x, y] = shade + (150,)
    return im


def main() -> None:
    draw().save(OUT)
    print("wrote art/props/landmark/tower_shaft.png (%d x %d)" % (W, H))


if __name__ == "__main__":
    main()
