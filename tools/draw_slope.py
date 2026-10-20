#!/usr/bin/env python3
"""Draw a slope: a cut of stone steps up the face of a shelf, where higher ground can be climbed.

    python3 tools/draw_slope.py

Needs Pillow (`pip install pillow`), like tools/draw_gate.py.

The founders' meeting of 2026-10-20 (D287): a ledge is dropped down freely and climbed only with a way
up, "like Pokémon, you can't go up raised platforms but you can come down them". D308 draws the way up
in house until art request A49 is made:

- art/props/landmark/slope.png    64 x 64, drawn as a prop that stands in nobody's way, on the higher
                                  cell at the shelf's edge; the steps run up from the lower ground.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "landmark" / "slope.png"
SIZE = 64
STONE = [(132, 128, 118), (118, 114, 106), (146, 142, 132), (104, 100, 94)]
EDGE = (62, 58, 54, 255)
EARTH = (96, 78, 58, 255)


def main() -> None:
    rng = random.Random(308)
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Five steps up from the bottom edge to the shelf's top, each a slab a little narrower than the
    # one below, worn in the middle where feet go.
    steps = 5
    for i in range(steps):
        top = SIZE - 10 - i * 11
        bottom = top + 11
        inset = 10 + i * 3
        shade = STONE[i % len(STONE)]
        draw.rectangle([inset, top, SIZE - inset, bottom], fill=shade + (255,), outline=EDGE)
        # The tread's front lip, darker, and a worn patch.
        draw.line([(inset, bottom - 1), (SIZE - inset, bottom - 1)], fill=EDGE, width=2)
        wear = STONE[(i + 2) % len(STONE)]
        draw.rectangle([26 + rng.randint(-2, 2), top + 3, 38 + rng.randint(-2, 2), bottom - 3], fill=wear + (255,))
    # Earth showing at the sides of the cut.
    for y in range(SIZE - 10, SIZE):
        for x in range(6, 10):
            image.putpixel((x + rng.randint(0, 1), y), EARTH)
            image.putpixel((SIZE - 1 - x - rng.randint(0, 1), y), EARTH)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)
    print("wrote", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
