#!/usr/bin/env python3
"""Draw a ladder: two weathered poles and their rungs, stood against a face of higher ground.

    python3 tools/draw_ladder.py

Needs Pillow (`pip install pillow`), like tools/draw_slope.py.

The founders' meeting of 2026-10-20 (D287): "walls and heights can be scaled some way". D337 stands
ladders against the tallest faces, climbed as far as two heights, and draws one in house until art
request A57 is made:

- art/props/landmark/ladder.png    64 x 64, drawn as a prop that stands in nobody's way, on the higher
                                   cell at the face's edge; its foot on the ground below.
"""

from __future__ import annotations

import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "props" / "landmark" / "ladder.png"
W, H = 64, 64
WOOD = [(122, 92, 60), (108, 80, 52), (136, 104, 68)]
EDGE = (52, 38, 26, 255)
ROPE = (176, 158, 112, 255)


def main() -> None:
    rng = random.Random(333)
    image = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    # Two poles, a little apart at the foot and closer at the top, as a ladder leant on a face.
    left = [(16, H - 2), (21, 4)]
    right = [(47, H - 2), (42, 4)]
    for pole in (left, right):
        draw.line(pole, fill=EDGE, width=7)
        draw.line(pole, fill=WOOD[0] + (255,), width=4)
    # Rungs, every 14 pixels, each lashed with a turn of rope at both ends.
    for i, y in enumerate(range(H - 8, 6, -11)):
        t = (H - 2 - y) / (H - 6)
        x0 = round(16 + 5 * t) + 2
        x1 = round(47 - 5 * t) - 2
        shade = WOOD[(i + 1) % len(WOOD)]
        draw.rectangle([x0, y - 2, x1, y + 2], fill=shade + (255,), outline=EDGE)
        for x in (x0, x1):
            draw.rectangle([x - 2, y - 3, x + 1, y + 3], fill=ROPE)
        if rng.random() < 0.4:
            draw.point((rng.randint(x0 + 3, x1 - 3), y), fill=EDGE)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    image.save(OUT)
    print("wrote", OUT.relative_to(ROOT))


if __name__ == "__main__":
    main()
