#!/usr/bin/env python3
"""Draw stand-in art for the insides of buildings: floors, walls and the furniture a room needs.

    python3 tools/draw_interiors.py

Needs Pillow (`pip install pillow`), like tools/recolour_biomes.py.

The insides of the inns and halls had nothing to stand on but the street's flagstones and nothing
to fill them but what a bedroom has (`doug-md`, 2026-10-13: "very bare every time I walk into
it"). Rooms want walls, a floor, a bar, tables, a hearth, shelves and kegs, and none of that had
been drawn. Until `dougie` makes them in PixelLab (docs/24-art-requests.md, request A5), this
draws plain stand-ins in the same 3/4 view and 64-pixel cell as the rest of the art: a top you
can see, a front face under it, a dark outline. Replace any file with real art of the same name
and size and nothing else needs to change. Re-running it overwrites the floors and walls it wrote;
furniture already on disk is left alone, since that is PixelLab's now.

Writes:
- art/interior/floor_<style>.png   64 x 64, tiles seamlessly
- art/interior/wall_<style>.png    64 x 112: a 16-pixel cap seen from above, a 96-pixel face
- art/interior/cap_<style>.png     64 x 64: the top of a side or front wall, seen from above
- art/props/interior/<thing>.png   the furniture, sized in data/props.json
"""

from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SHELL = ROOT / "art" / "interior"
PROPS = ROOT / "art" / "props" / "interior"

RGB = tuple[int, int, int]
INK: RGB = (26, 19, 17)


def tone(c: RGB, k: float) -> RGB:
    """Lighter for k > 1, darker for k < 1."""
    if k >= 1:
        return tuple(min(255, round(v + (255 - v) * (k - 1))) for v in c)  # type: ignore[return-value]
    return tuple(max(0, round(v * k)) for v in c)  # type: ignore[return-value]


def jitter(c: RGB, rng: random.Random, amount: int = 8) -> RGB:
    return tuple(max(0, min(255, v + rng.randint(-amount, amount))) for v in c)  # type: ignore[return-value]


def blank(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def box(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, fill: RGB, ink: bool = True) -> None:
    d.rectangle([x0, y0, x1, y1], fill=fill, outline=INK if ink else None)


def grain(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, base: RGB, rng: random.Random,
          vertical: bool = False, density: float = 0.35) -> None:
    """Wood: streaks along the board, darker and lighter."""
    span = range(y0, y1 + 1) if not vertical else range(x0, x1 + 1)
    for line in span:
        if rng.random() > density:
            continue
        length = rng.randint(4, 14)
        start = rng.randint(x0, max(x0, x1 - length)) if not vertical else rng.randint(y0, max(y0, y1 - length))
        c = tone(base, rng.choice([0.86, 0.9, 1.08]))
        if vertical:
            d.line([line, start, line, min(y1, start + length)], fill=c)
        else:
            d.line([start, line, min(x1, start + length), line], fill=c)


# --- woods, stones and cloths -------------------------------------------------------------------

OAK: RGB = (120, 78, 46)
PINE: RGB = (156, 116, 70)
DARKWOOD: RGB = (74, 56, 40)
DRIFT: RGB = (118, 112, 100)
STONE: RGB = (112, 108, 104)
SAND: RGB = (196, 156, 104)
CLAY: RGB = (172, 94, 62)
BRASS: RGB = (196, 156, 72)
IRON: RGB = (70, 70, 76)
GLASS_G: RGB = (70, 130, 80)
GLASS_B: RGB = (70, 96, 150)
GLASS_A: RGB = (170, 110, 40)
CLOTH_R: RGB = (130, 40, 36)
CLOTH_B: RGB = (44, 62, 112)
CLOTH_G: RGB = (52, 92, 56)
PARCHMENT: RGB = (214, 196, 156)
FLAME: RGB = (255, 196, 90)


# --- floors -------------------------------------------------------------------------------------

def floor_planks(base: RGB, seed: int, wet: bool = False) -> Image.Image:
    rng = random.Random(seed)
    im, d = blank(64, 64)
    for row in range(4):
        y0 = row * 16
        # Each row of boards is cut somewhere of its own, so the seams stagger.
        cut = (row * 23 + 9) % 64
        for x0, x1 in ((0, cut - 1), (cut, 63)) if cut > 0 else ((0, 63),):
            if x1 < x0:
                continue
            c = jitter(base, rng, 10)
            d.rectangle([x0, y0, x1, y0 + 15], fill=c)
            grain(d, x0 + 1, y0 + 2, x1 - 1, y0 + 13, c, rng, density=0.45)
            d.line([x0, y0, x1, y0], fill=tone(c, 1.12))
            d.line([x0, y0 + 15, x1, y0 + 15], fill=tone(c, 0.55))
            if x0 > 0:
                d.line([x0, y0, x0, y0 + 15], fill=tone(c, 0.5))
            for nx in (x0 + 2, x1 - 2):
                if 0 <= nx < 64:
                    d.point([nx, y0 + 4], fill=tone(c, 0.45))
                    d.point([nx, y0 + 11], fill=tone(c, 0.45))
        if wet and rng.random() < 0.7:
            # Water standing between the boards.
            x = rng.randint(4, 50)
            d.line([x, y0 + 15, x + rng.randint(6, 12), y0 + 15], fill=(40, 70, 64))
    return im


def floor_tiles(base: RGB, seed: int) -> Image.Image:
    rng = random.Random(seed)
    im, d = blank(64, 64)
    grout = tone(base, 0.62)
    d.rectangle([0, 0, 63, 63], fill=grout)
    for ty in range(2):
        for tx in range(2):
            c = jitter(base, rng, 9)
            x0, y0 = tx * 32 + 1, ty * 32 + 1
            d.rectangle([x0, y0, x0 + 29, y0 + 29], fill=c)
            d.line([x0, y0, x0 + 29, y0], fill=tone(c, 1.12))
            d.line([x0, y0, x0, y0 + 29], fill=tone(c, 1.08))
            d.line([x0, y0 + 29, x0 + 29, y0 + 29], fill=tone(c, 0.82))
            # A painted diamond in the middle of every tile.
            cx, cy = x0 + 14, y0 + 14
            d.polygon([(cx, cy - 6), (cx + 6, cy), (cx, cy + 6), (cx - 6, cy)], fill=tone(c, 0.8))
            d.polygon([(cx, cy - 3), (cx + 3, cy), (cx, cy + 3), (cx - 3, cy)], fill=(214, 188, 130))
    return im


def floor_flags(base: RGB, seed: int) -> Image.Image:
    """Big worn slabs, close in tone, so a hall's floor does not read as a wall."""
    rng = random.Random(seed)
    im, d = blank(64, 64)
    grout = tone(base, 0.7)
    d.rectangle([0, 0, 63, 63], fill=grout)
    slabs = [(0, 0, 39, 31), (40, 0, 63, 31), (0, 32, 23, 63), (24, 32, 63, 63)]
    for x0, y0, x1, y1 in slabs:
        c = jitter(base, rng, 5)
        d.rectangle([x0 + 1, y0 + 1, x1 - 1, y1 - 1], fill=c)
        d.line([x0 + 1, y0 + 1, x1 - 1, y0 + 1], fill=tone(c, 1.08))
        for _ in range(int((x1 - x0) * (y1 - y0) / 40)):
            d.point([rng.randint(x0 + 2, x1 - 2), rng.randint(y0 + 2, y1 - 2)], fill=tone(c, rng.choice([0.93, 1.05])))
        if rng.random() < 0.5:
            x = rng.randint(x0 + 4, max(x0 + 5, x1 - 10))
            y = rng.randint(y0 + 4, max(y0 + 5, y1 - 6))
            d.line([x, y, x + 5, y + 3], fill=tone(c, 0.82))
    return im


# --- walls --------------------------------------------------------------------------------------

def wall_face(style: str, seed: int) -> Image.Image:
    """64 x 112: the cap (top 16) and the face (96) of the back wall."""
    rng = random.Random(seed)
    im, d = blank(64, 112)
    cap = WALL_CAPS[style]
    d.rectangle([0, 0, 63, 15], fill=cap)
    d.line([0, 0, 63, 0], fill=tone(cap, 1.25))
    d.line([0, 15, 63, 15], fill=INK)
    top, bottom = 16, 111
    if style == "timber":
        plaster = (206, 192, 162)
        d.rectangle([0, top, 63, bottom], fill=plaster)
        for _ in range(60):
            d.point([rng.randint(0, 63), rng.randint(top, bottom)], fill=tone(plaster, rng.choice([0.92, 1.04])))
        beam = DARKWOOD
        d.rectangle([0, top, 63, top + 9], fill=beam)
        grain(d, 0, top + 1, 63, top + 8, beam, rng)
        d.rectangle([0, top, 5, bottom], fill=beam)
        d.rectangle([58, top, 63, bottom], fill=beam)
        d.line([6, top + 10, 57, top + 58], fill=beam, width=4)
        d.rectangle([0, bottom - 11, 63, bottom], fill=tone(beam, 0.9))
        d.line([0, top + 10, 63, top + 10], fill=tone(plaster, 0.7))
    elif style == "log":
        for row in range(6):
            y0 = top + row * 16
            c = jitter((112, 76, 44), rng, 8)
            d.rounded_rectangle([0, y0, 63, y0 + 15], radius=6, fill=c, outline=tone(c, 0.5))
            d.line([2, y0 + 3, 61, y0 + 3], fill=tone(c, 1.15))
            d.line([2, y0 + 12, 61, y0 + 12], fill=tone(c, 0.72))
            grain(d, 2, y0 + 5, 61, y0 + 10, c, rng)
    elif style in ("boards", "damp"):
        base = (104, 110, 108) if style == "boards" else (58, 66, 50)
        for col in range(8):
            x0 = col * 8
            c = jitter(base, rng, 9)
            d.rectangle([x0, top, x0 + 7, bottom], fill=c)
            grain(d, x0 + 1, top, x0 + 6, bottom, c, rng, vertical=True, density=0.5)
            d.line([x0, top, x0, bottom], fill=tone(c, 0.55))
            d.line([x0 + 1, top, x0 + 1, bottom], fill=tone(c, 1.1))
        d.rectangle([0, top + 20, 63, top + 25], fill=tone(base, 0.7))
        d.rectangle([0, bottom - 9, 63, bottom], fill=tone(base, 0.6))
        if style == "damp":
            for _ in range(5):
                x = rng.randint(0, 60)
                d.line([x, bottom - 10, x + rng.randint(-2, 2), bottom - 10 - rng.randint(10, 34)], fill=(70, 96, 52), width=2)
    elif style == "adobe":
        mud = (200, 162, 112)
        d.rectangle([0, top, 63, bottom], fill=mud)
        for _ in range(90):
            d.point([rng.randint(0, 63), rng.randint(top, bottom)], fill=tone(mud, rng.choice([0.9, 1.05])))
        d.rectangle([0, top + 44, 63, top + 51], fill=(150, 64, 46))
        for x in range(0, 64, 8):
            d.polygon([(x, top + 44), (x + 4, top + 40), (x + 8, top + 44)], fill=(54, 90, 120))
        d.rectangle([0, bottom - 9, 63, bottom], fill=tone(mud, 0.75))
    elif style == "stone":
        for row in range(6):
            y0 = top + row * 16
            offset = 0 if row % 2 == 0 else 16
            for x0 in range(-32 + offset, 64, 32):
                c = jitter(STONE, rng, 10)
                d.rectangle([x0 + 1, y0 + 1, x0 + 30, y0 + 14], fill=c)
                d.line([x0 + 1, y0 + 1, x0 + 30, y0 + 1], fill=tone(c, 1.15))
                d.line([x0 + 1, y0 + 14, x0 + 30, y0 + 14], fill=tone(c, 0.75))
        d.rectangle([0, top, 63, top + 1], fill=tone(STONE, 0.5))
    # The shadow where the wall meets the floor.
    d.line([0, bottom, 63, bottom], fill=INK)
    return im


WALL_CAPS: dict[str, RGB] = {
    "timber": (64, 46, 34), "log": (84, 58, 36), "boards": (72, 74, 72), "damp": (44, 48, 38),
    "adobe": (156, 120, 80), "stone": (84, 82, 80),
}


def wall_cap(style: str, seed: int) -> Image.Image:
    rng = random.Random(seed)
    im, d = blank(64, 64)
    c = WALL_CAPS[style]
    d.rectangle([0, 0, 63, 63], fill=c)
    if style in ("stone", "adobe"):
        for row in range(4):
            off = 0 if row % 2 == 0 else 16
            for x0 in range(-32 + off, 64, 32):
                cc = jitter(c, rng, 8)
                d.rectangle([x0 + 1, row * 16 + 1, x0 + 30, row * 16 + 14], fill=cc)
    else:
        grain(d, 0, 0, 63, 63, c, rng, density=0.5)
    d.rectangle([0, 0, 63, 63], outline=tone(c, 0.6))
    return im


# --- furniture ----------------------------------------------------------------------------------

def bar_counter() -> Image.Image:
    """Three cells long. The top, the panelled front, mugs and a jug on it."""
    rng = random.Random(1)
    im, d = blank(192, 80)
    top = (138, 92, 54)
    box(d, 2, 22, 189, 40, top)
    grain(d, 4, 24, 187, 38, top, rng)
    d.line([3, 23, 188, 23], fill=tone(top, 1.2))
    front = (96, 62, 36)
    box(d, 4, 40, 187, 77, front)
    for x in range(10, 186, 30):
        d.rectangle([x, 46, x + 22, 71], outline=tone(front, 0.65))
        d.line([x + 1, 47, x + 21, 47], fill=tone(front, 1.15))
    d.line([4, 76, 187, 76], fill=INK)
    for x, c in ((24, (200, 188, 160)), (60, (180, 140, 90)), (128, (200, 188, 160)), (160, (150, 150, 158))):
        box(d, x, 12, x + 9, 26, c)
        d.rectangle([x + 2, 13, x + 7, 15], fill=(236, 226, 196))
        d.arc([x + 7, 15, x + 13, 22], 270, 90, fill=INK)
    box(d, 92, 6, 104, 28, CLAY)
    d.line([94, 9, 102, 9], fill=tone(CLAY, 1.25))
    return im


def table_round() -> Image.Image:
    rng = random.Random(2)
    im, d = blank(64, 64)
    wood = (132, 88, 52)
    d.rectangle([28, 40, 35, 60], fill=tone(wood, 0.6), outline=INK)
    d.ellipse([18, 56, 45, 62], fill=tone(wood, 0.5), outline=INK)
    d.ellipse([4, 22, 59, 46], fill=tone(wood, 0.62), outline=INK)
    d.ellipse([4, 18, 59, 42], fill=wood, outline=INK)
    d.arc([8, 20, 55, 40], 200, 340, fill=tone(wood, 1.2))
    grain(d, 12, 24, 50, 36, wood, rng, density=0.3)
    box(d, 18, 20, 25, 30, (200, 188, 160))
    d.rectangle([19, 21, 24, 22], fill=(236, 220, 180))
    box(d, 38, 18, 42, 30, (226, 214, 190))
    d.ellipse([37, 12, 43, 19], fill=FLAME)
    d.point([40, 13], fill=(255, 250, 220))
    return im


def table_long() -> Image.Image:
    rng = random.Random(3)
    im, d = blank(128, 64)
    wood = (124, 82, 48)
    for x in (10, 110):
        box(d, x, 40, x + 7, 62, tone(wood, 0.55))
    box(d, 2, 22, 125, 42, wood)
    grain(d, 4, 24, 123, 40, wood, rng)
    d.line([3, 23, 124, 23], fill=tone(wood, 1.2))
    box(d, 2, 42, 125, 48, tone(wood, 0.62))
    for x in (16, 52, 88):
        d.ellipse([x, 26, x + 16, 36], fill=(196, 196, 204), outline=INK)
        d.ellipse([x + 4, 28, x + 12, 34], fill=(150, 96, 60))
    box(d, 74, 18, 82, 32, (200, 188, 160))
    box(d, 112, 14, 118, 32, GLASS_G)
    d.line([114, 16, 114, 28], fill=tone(GLASS_G, 1.4))
    return im


def stool() -> Image.Image:
    im, d = blank(32, 32)
    wood = (138, 94, 56)
    for x in (9, 20):
        box(d, x, 16, x + 3, 30, tone(wood, 0.55))
    d.ellipse([5, 9, 26, 19], fill=tone(wood, 0.65), outline=INK)
    d.ellipse([5, 7, 26, 17], fill=wood, outline=INK)
    d.arc([8, 8, 23, 15], 200, 340, fill=tone(wood, 1.25))
    return im


def bench_low() -> Image.Image:
    im, d = blank(128, 40)
    wood = (118, 80, 48)
    for x in (8, 112):
        box(d, x, 20, x + 7, 38, tone(wood, 0.55))
    box(d, 2, 12, 125, 24, wood)
    d.line([3, 13, 124, 13], fill=tone(wood, 1.2))
    return im


def shelf_bottles() -> Image.Image:
    """Hung on the back wall: two shelves of bottles and jars."""
    rng = random.Random(4)
    im, d = blank(128, 80)
    wood = DARKWOOD
    for y in (34, 72):
        box(d, 2, y, 125, y + 6, wood)
        d.line([3, y + 1, 124, y + 1], fill=tone(wood, 1.3))
        for bx in (8, 116):
            d.polygon([(bx, y + 6), (bx + 6, y + 6), (bx + 3, y + 12)], fill=tone(wood, 0.7))
    for y in (34, 72):
        x = 8
        while x < 118:
            kind = rng.choice(["bottle", "bottle", "jar", "jug"])
            c = rng.choice([GLASS_G, GLASS_B, GLASS_A, (120, 40, 60)])
            if kind == "bottle":
                box(d, x, y - 18, x + 6, y - 1, c)
                box(d, x + 2, y - 26, x + 4, y - 18, c)
                d.line([x + 1, y - 16, x + 1, y - 4], fill=tone(c, 1.5))
                x += 10
            elif kind == "jar":
                box(d, x, y - 12, x + 10, y - 1, (190, 170, 130))
                box(d, x + 1, y - 15, x + 9, y - 12, (120, 90, 60))
                x += 14
            else:
                box(d, x, y - 16, x + 9, y - 1, CLAY)
                d.arc([x + 7, y - 14, x + 13, y - 6], 270, 90, fill=INK)
                x += 15
    return im


def keg_rack() -> Image.Image:
    im, d = blank(64, 64)
    wood = (100, 66, 38)
    box(d, 4, 54, 59, 61, tone(wood, 0.6))
    for i, (x, y) in enumerate(((6, 30), (34, 30), (20, 6))):
        c = (128, 86, 48)
        d.ellipse([x, y, x + 24, y + 24], fill=c, outline=INK)
        d.ellipse([x + 4, y + 4, x + 20, y + 20], fill=tone(c, 1.15), outline=tone(c, 0.6))
        d.ellipse([x + 9, y + 9, x + 15, y + 15], fill=tone(c, 0.7))
        d.arc([x + 1, y + 1, x + 23, y + 23], 0, 360, fill=IRON)
        if i < 2:
            box(d, x + 10, y + 18, x + 14, y + 24, BRASS)
    return im


def fireplace() -> Image.Image:
    """Two cells wide, set into the back wall: stone hearth, logs, fire."""
    rng = random.Random(5)
    im, d = blank(128, 112)
    for row in range(7):
        y0 = 4 + row * 15
        off = 0 if row % 2 == 0 else 12
        for x0 in range(4 - 24 + off, 124, 24):
            c = jitter((122, 116, 110), rng, 10)
            a, b = max(4, x0 + 1), min(123, x0 + 22)
            if b <= a:
                continue
            d.rectangle([a, y0 + 1, b, y0 + 13], fill=c)
            d.line([a, y0 + 1, b, y0 + 1], fill=tone(c, 1.15))
    d.rectangle([4, 4, 123, 108], outline=INK)
    box(d, 0, 0, 127, 10, (96, 70, 50))
    d.line([1, 1, 126, 1], fill=(140, 104, 72))
    d.rectangle([28, 44, 99, 108], fill=(26, 18, 16))
    d.pieslice([28, 26, 99, 62], 180, 360, fill=(26, 18, 16))
    for x in (36, 56, 72):
        d.rounded_rectangle([x, 94, x + 22, 102], radius=3, fill=(96, 62, 36), outline=INK)
    for _ in range(140):
        x = rng.gauss(64, 11)
        y = rng.uniform(56, 96)
        h = (96 - y) / 40
        c = (255, max(80, int(220 - h * 140)), max(20, int(110 - h * 90)))
        d.point([int(x), int(y)], fill=c)
    d.polygon([(46, 96), (56, 64), (62, 80), (68, 58), (76, 82), (84, 96)], fill=(255, 150, 50))
    d.polygon([(54, 96), (62, 74), (68, 86), (74, 96)], fill=(255, 220, 120))
    box(d, 14, 104, 113, 111, (90, 86, 84))
    return im


def bookshelf() -> Image.Image:
    rng = random.Random(6)
    im, d = blank(64, 112)
    wood = (92, 60, 36)
    box(d, 2, 4, 61, 109, wood)
    for y in (8, 34, 60, 86):
        d.rectangle([6, y, 57, y + 21], fill=tone(wood, 0.45))
        x = 7
        while x < 55:
            w = rng.randint(3, 6)
            h = rng.randint(14, 20)
            c = rng.choice([CLOTH_R, CLOTH_B, CLOTH_G, (110, 80, 40), PARCHMENT, (80, 40, 70)])
            d.rectangle([x, y + 21 - h, x + w - 1, y + 21], fill=c, outline=tone(c, 0.55))
            d.point([x + 1, y + 23 - h], fill=tone(c, 1.4))
            x += w + rng.choice([0, 0, 1])
        d.rectangle([4, y + 22, 59, y + 25], fill=tone(wood, 1.15), outline=INK)
    d.line([3, 5, 60, 5], fill=tone(wood, 1.3))
    return im


def weapon_rack(axes: bool) -> Image.Image:
    im, d = blank(96, 80)
    wood = (100, 66, 40)
    box(d, 4, 10, 91, 16, wood)
    box(d, 4, 62, 91, 68, wood)
    for i, x in enumerate((14, 34, 54, 74)):
        d.line([x + 4, 6, x + 4, 72], fill=(110, 80, 50), width=3)
        if axes:
            d.polygon([(x + 5, 8), (x + 15, 4), (x + 17, 18), (x + 5, 16)], fill=(160, 164, 170), outline=INK)
            d.line([x + 15, 5, x + 17, 17], fill=(220, 224, 228))
        else:
            d.line([x + 4, 2, x + 4, 50], fill=(190, 194, 200), width=3)
            d.line([x - 1, 50, x + 9, 50], fill=BRASS, width=2)
            d.line([x + 3, 3, x + 3, 48], fill=(235, 238, 242))
    box(d, 0, 72, 95, 78, tone(wood, 0.6))
    return im


def banner(colour: RGB, mark: RGB) -> Image.Image:
    im, d = blank(48, 112)
    d.line([2, 6, 45, 6], fill=BRASS, width=3)
    d.polygon([(6, 8), (41, 8), (41, 92), (23, 106), (6, 92)], fill=colour, outline=INK)
    d.line([8, 10, 8, 90], fill=tone(colour, 1.3))
    d.polygon([(6, 8), (41, 8), (41, 14), (6, 14)], fill=tone(colour, 0.7))
    cx = 23
    d.polygon([(cx, 34), (cx + 10, 50), (cx, 66), (cx - 10, 50)], fill=mark, outline=tone(mark, 0.6))
    d.ellipse([cx - 4, 46, cx + 4, 54], fill=colour)
    for x in (6, 41):
        d.line([x, 92, x, 98], fill=BRASS)
    return im


def slate_board() -> Image.Image:
    rng = random.Random(7)
    im, d = blank(64, 56)
    box(d, 4, 4, 59, 51, (100, 66, 40))
    d.rectangle([8, 8, 55, 47], fill=(48, 54, 58))
    for row in range(5):
        y = 12 + row * 7
        d.line([11, y, 11 + rng.randint(10, 18), y], fill=(200, 204, 200))
        for k in range(rng.randint(2, 6)):
            x = 34 + k * 3
            d.line([x, y - 2, x, y + 2], fill=(220, 224, 220))
    return im


def ship_bell() -> Image.Image:
    im, d = blank(48, 72)
    box(d, 4, 4, 43, 10, DARKWOOD)
    d.line([24, 10, 24, 18], fill=IRON, width=2)
    bell = (74, 120, 96)
    d.polygon([(14, 22), (34, 22), (38, 52), (10, 52)], fill=bell, outline=INK)
    d.pieslice([14, 14, 34, 32], 180, 360, fill=bell, outline=INK)
    d.rectangle([8, 50, 40, 56], fill=tone(bell, 0.8), outline=INK)
    d.line([17, 24, 13, 50], fill=tone(bell, 1.4))
    d.ellipse([20, 56, 28, 64], fill=BRASS, outline=INK)
    return im


def amphorae() -> Image.Image:
    im, d = blank(64, 64)
    for x, y, c in ((4, 18, CLAY), (22, 10, (190, 120, 74)), (40, 20, (160, 84, 56))):
        d.ellipse([x, y + 8, x + 20, y + 38], fill=c, outline=INK)
        d.rectangle([x + 6, y, x + 14, y + 10], fill=c, outline=INK)
        d.rectangle([x + 4, y - 2, x + 16, y + 1], fill=tone(c, 0.8), outline=INK)
        d.line([x + 5, y + 14, x + 5, y + 30], fill=tone(c, 1.3))
        d.line([x + 3, y + 22, x + 17, y + 22], fill=(220, 190, 120))
    return im


def cushions() -> Image.Image:
    im, d = blank(64, 40)
    for x, y, c in ((2, 14, CLOTH_R), (24, 8, (170, 110, 40)), (36, 18, CLOTH_B)):
        d.rounded_rectangle([x, y, x + 26, y + 18], radius=7, fill=c, outline=INK)
        d.line([x + 4, y + 4, x + 22, y + 4], fill=tone(c, 1.3))
        d.point([x + 13, y + 9], fill=(220, 190, 110))
    return im


def low_table() -> Image.Image:
    im, d = blank(64, 48)
    wood = (110, 70, 40)
    box(d, 6, 30, 11, 44, tone(wood, 0.55))
    box(d, 52, 30, 57, 44, tone(wood, 0.55))
    d.ellipse([2, 14, 61, 36], fill=tone(BRASS, 0.8), outline=INK)
    d.ellipse([2, 12, 61, 32], fill=BRASS, outline=INK)
    d.ellipse([12, 16, 51, 28], outline=tone(BRASS, 0.7))
    box(d, 20, 10, 28, 22, (210, 200, 180))
    box(d, 34, 12, 42, 22, (74, 120, 96))
    return im


def candelabra() -> Image.Image:
    im, d = blank(32, 96)
    d.ellipse([6, 86, 25, 94], fill=IRON, outline=INK)
    d.line([16, 30, 16, 88], fill=IRON, width=3)
    d.line([4, 30, 28, 30], fill=IRON, width=3)
    for x in (4, 16, 28):
        box(d, x - 2, 16, x + 2, 29, (230, 220, 196))
        d.ellipse([x - 3, 8, x + 3, 16], fill=FLAME)
        d.point([x, 10], fill=(255, 250, 220))
    return im


def muster_board() -> Image.Image:
    rng = random.Random(8)
    im, d = blank(128, 88)
    box(d, 2, 2, 125, 85, (96, 64, 38))
    d.rectangle([8, 8, 119, 79], fill=(150, 120, 80))
    for row in range(4):
        for col in range(4):
            x, y = 12 + col * 27, 12 + row * 16
            d.rectangle([x, y, x + 22, y + 12], fill=PARCHMENT, outline=tone(PARCHMENT, 0.6))
            for k in range(rng.randint(1, 3)):
                d.line([x + 3, y + 3 + k * 3, x + 3 + rng.randint(8, 16), y + 3 + k * 3], fill=(90, 70, 50))
            d.point([x + 11, y + 1], fill=CLOTH_R)
    return im


def crates() -> Image.Image:
    im, d = blank(64, 64)
    for x, y, s in ((4, 28, 30), (32, 32, 28), (16, 6, 26)):
        c = (150, 112, 66)
        box(d, x, y, x + s, y + s, c)
        d.rectangle([x + 3, y + 3, x + s - 3, y + s - 3], outline=tone(c, 0.65))
        d.line([x + 3, y + 3, x + s - 3, y + s - 3], fill=tone(c, 0.65), width=2)
        d.line([x + 1, y + 1, x + s - 1, y + 1], fill=tone(c, 1.2))
    return im


def hearth_rug_glow() -> Image.Image:
    """A soft round light, laid over the room additively by the painter."""
    im = Image.new("RGBA", (128, 128), (0, 0, 0, 0))
    px = im.load()
    for y in range(128):
        for x in range(128):
            r = math.hypot(x - 63.5, y - 63.5) / 64
            a = max(0.0, 1 - r) ** 2
            px[x, y] = (255, 255, 255, int(255 * a))
    return im


def main() -> None:
    SHELL.mkdir(parents=True, exist_ok=True)
    PROPS.mkdir(parents=True, exist_ok=True)
    floors = {
        "oak": floor_planks(OAK, 11), "pine": floor_planks(PINE, 12), "dark": floor_planks((70, 60, 44), 13, wet=True),
        "drift": floor_planks(DRIFT, 14), "tile": floor_tiles(CLAY, 15), "flag": floor_flags((128, 120, 110), 16),
    }
    for name, image in floors.items():
        image.save(SHELL / f"floor_{name}.png")
    for i, style in enumerate(WALL_CAPS):
        wall_face(style, 20 + i).save(SHELL / f"wall_{style}.png")
        wall_cap(style, 40 + i).save(SHELL / f"cap_{style}.png")
    hearth_rug_glow().save(SHELL / "glow.png")
    things = {
        "bar_counter": bar_counter(), "table_round": table_round(), "table_long": table_long(),
        "stool": stool(), "bench_low": bench_low(), "shelf_bottles": shelf_bottles(), "keg_rack": keg_rack(),
        "fireplace": fireplace(), "bookshelf": bookshelf(), "axe_rack": weapon_rack(True),
        "sword_rack": weapon_rack(False), "banner_red": banner(CLOTH_R, BRASS), "banner_blue": banner(CLOTH_B, (200, 204, 210)),
        "banner_green": banner(CLOTH_G, BRASS), "slate_board": slate_board(), "ship_bell": ship_bell(),
        "amphorae": amphorae(), "cushions": cushions(), "low_table": low_table(), "candelabra": candelabra(),
        "muster_board": muster_board(), "crates": crates(),
    }
    drawn = 0
    for name, image in things.items():
        # The furniture is PixelLab's since 2026-10-13 (tools/pixellab_world.py rooms): never drawn over.
        if (PROPS / f"{name}.png").exists():
            continue
        image.save(PROPS / f"{name}.png")
        drawn += 1
    print("wrote %d floors, %d walls, %d pieces of furniture" % (len(floors), len(WALL_CAPS), drawn))


if __name__ == "__main__":
    main()
