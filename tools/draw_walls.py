#!/usr/bin/env python3
"""Draw stand-in art for the walls round towns: a run, a side, and a tower, in three builds.

    python3 tools/draw_walls.py

Needs Pillow (`pip install pillow`), like tools/draw_interiors.py.

`doug-md` (2026-10-13) asked for towns with "built up walls". Until `dougie` makes them in PixelLab
(docs/24-art-requests.md, request A7), this draws plain stand-ins in the same 3/4 view and 64-pixel
cell as the rest of the art: a top you can see, a front face under it, a dark outline. They are
props (data/props.json, kind `wall` and `wall_tower`), stood on the ring of cells round a place
by src/area/ground_gen.gd. Replace any file with real art of the same name and size and nothing
else needs to change. Re-running it overwrites what it wrote and nothing else.

Writes, for each build (stone, timber, adobe):
- art/props/walls/<build>_run.png    64 x 96: a stretch of wall seen from the front
- art/props/walls/<build>_side.png   28 x 96: a stretch running away from you, mostly its top
- art/props/walls/<build>_tower.png  84 x 136: a tower at a corner or beside a gate
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "walls"

RGB = tuple[int, int, int]
INK: RGB = (26, 19, 17)

BUILDS: dict[str, RGB] = {
    "stone": (128, 124, 118),
    "timber": (122, 86, 52),
    "adobe": (196, 150, 98),
}


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


def courses(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, base: RGB, build: str,
            rng: random.Random) -> None:
    """The face of a wall: coursed stone, upright logs, or rendered mud brick."""
    d.rectangle([x0, y0, x1, y1], fill=base)
    if build == "timber":
        x = x0
        while x <= x1:
            w = rng.randint(7, 10)
            c = jitter(base, rng, 10)
            d.rectangle([x, y0, min(x1, x + w - 1), y1], fill=c)
            d.line([x, y0, x, y1], fill=tone(c, 0.55))
            d.line([x + 2, y0 + 2, x + 2, y1 - 2], fill=tone(c, 1.1))
            for _ in range(2):
                gy = rng.randint(y0 + 4, y1 - 4)
                d.line([x + 3, gy, min(x1, x + w - 2), gy + 2], fill=tone(c, 0.8))
            x += w
        # Two rails tying the logs together.
        for ry in (y0 + (y1 - y0) // 4, y1 - (y1 - y0) // 4):
            d.rectangle([x0, ry, x1, ry + 3], fill=tone(base, 0.7))
            d.line([x0, ry, x1, ry], fill=tone(base, 0.95))
        return
    row_h = 9 if build == "stone" else 7
    row = 0
    y = y0
    while y <= y1:
        stagger = (row % 2) * (8 if build == "stone" else 6)
        x = x0 - stagger
        while x <= x1:
            w = rng.randint(12, 18) if build == "stone" else 12
            c = jitter(base, rng, 9 if build == "stone" else 5)
            d.rectangle([max(x0, x), y, min(x1, x + w - 1), min(y1, y + row_h - 1)], fill=c)
            d.line([max(x0, x), y, min(x1, x + w - 1), y], fill=tone(c, 1.12))
            d.line([max(x0, x), min(y1, y + row_h - 1), min(x1, x + w - 1), min(y1, y + row_h - 1)],
                   fill=tone(c, 0.62))
            if x >= x0:
                d.line([x, y, x, min(y1, y + row_h - 1)], fill=tone(c, 0.6))
            x += w
        y += row_h
        row += 1
    if build == "adobe":
        # Render worn off in patches, and the ends of the roof beams poking through.
        for _ in range(4):
            px, py = rng.randint(x0, x1 - 8), rng.randint(y0, y1 - 6)
            d.ellipse([px, py, px + rng.randint(6, 12), py + rng.randint(4, 7)], fill=tone(base, 1.08))
        for bx in range(x0 + 6, x1 - 4, 20):
            d.rectangle([bx, y0 + 3, bx + 4, y0 + 7], fill=(92, 64, 40), outline=INK)


def top(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, base: RGB, build: str) -> None:
    """The walk along the top, seen from above."""
    c = tone(base, 1.18)
    d.rectangle([x0, y0, x1, y1], fill=c)
    if build == "timber":
        for x in range(x0, x1 + 1, 6):
            d.line([x, y0, x, y1], fill=tone(c, 0.8))
    else:
        d.line([x0, (y0 + y1) // 2, x1, (y0 + y1) // 2], fill=tone(c, 0.88))


def crenels(d: ImageDraw.ImageDraw, x0: int, x1: int, y: int, base: RGB, build: str) -> None:
    """Battlements along a top edge, or sharpened stakes for a palisade."""
    if build == "timber":
        x = x0
        while x <= x1:
            c = tone(base, 1.05)
            d.polygon([(x, y), (x + 4, y - 9), (x + 8, y)], fill=c, outline=INK)
            x += 8
        return
    step = 12
    for x in range(x0, x1 + 1, step):
        d.rectangle([x, y - 8, min(x1, x + 6), y], fill=tone(base, 1.1), outline=INK)


def run(build: str, base: RGB, seed: int) -> Image.Image:
    rng = random.Random(seed)
    im, d = blank(64, 96)
    top(d, 0, 14, 63, 27, base, build)
    crenels(d, 0, 63, 14, base, build)
    courses(d, 0, 28, 63, 95, base, build, rng)
    d.line([0, 28, 63, 28], fill=INK)
    d.line([0, 95, 63, 95], fill=INK)
    # A shadow where the wall meets the ground.
    d.line([0, 94, 63, 94], fill=tone(base, 0.45))
    return im


def side(build: str, base: RGB, seed: int) -> Image.Image:
    """A wall running north and south: mostly its top, with the end of its face at the foot."""
    rng = random.Random(seed)
    im, d = blank(28, 96)
    top(d, 0, 0, 27, 71, base, build)
    if build == "timber":
        for y in range(0, 72, 8):
            d.polygon([(0, y), (-1, y + 4), (0, y + 8)], fill=tone(base, 1.05))
    else:
        for y in range(0, 72, 12):
            d.rectangle([0, y, 4, y + 6], fill=tone(base, 1.1), outline=INK)
            d.rectangle([23, y, 27, y + 6], fill=tone(base, 1.1), outline=INK)
    courses(d, 0, 72, 27, 95, base, build, rng)
    d.line([0, 0, 0, 95], fill=INK)
    d.line([27, 0, 27, 95], fill=INK)
    d.line([0, 72, 27, 72], fill=INK)
    d.line([0, 95, 27, 95], fill=INK)
    return im


def tower(build: str, base: RGB, seed: int) -> Image.Image:
    rng = random.Random(seed)
    im, d = blank(84, 136)
    body = tone(base, 0.95)
    top(d, 2, 20, 81, 37, base, build)
    crenels(d, 2, 81, 20, base, build)
    courses(d, 4, 38, 79, 135, body, build, rng)
    d.rectangle([4, 38, 79, 135], outline=INK)
    # An arrow slit, and a lit window higher up.
    d.rectangle([39, 60, 44, 78], fill=INK)
    d.rectangle([40, 61, 43, 77], fill=(36, 30, 28))
    d.rectangle([38, 96, 45, 106], fill=INK)
    d.rectangle([39, 97, 44, 105], fill=(232, 176, 84))
    if build == "timber":
        # A watch platform's roof instead of battlements.
        d.polygon([(0, 22), (42, 0), (83, 22)], fill=(96, 62, 40), outline=INK)
    if build == "adobe":
        d.rectangle([30, 12, 53, 20], fill=tone(base, 1.08), outline=INK)
    d.line([4, 134, 79, 134], fill=tone(base, 0.45))
    return im


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for i, (build, base) in enumerate(BUILDS.items()):
        run(build, base, 100 + i).save(OUT / f"{build}_run.png")
        side(build, base, 200 + i).save(OUT / f"{build}_side.png")
        tower(build, base, 300 + i).save(OUT / f"{build}_tower.png")
        print(f"walls/{build}: run, side, tower")


if __name__ == "__main__":
    main()
