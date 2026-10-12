#!/usr/bin/env python3
"""Cut a flat backdrop out of pixel art: only the part joined to the picture's edge, so nothing
of the same colour inside the drawing is touched.

    python3 tools/clear_backdrop.py art/units/sword_monkey/idle/*.png
    python3 tools/clear_backdrop.py --colour 233,227,216 art/world/hold_*.png

Without --colour the backdrop is whatever colour the corners are. A one-pixel frame of another
colour round the edge (the sword monkey's black line) goes first. Needs Pillow.
"""

import sys
from PIL import Image

TOLERANCE = 10


def _near(a, b) -> bool:
    return a[3] > 0 and all(abs(a[i] - b[i]) <= TOLERANCE for i in range(3))


def clear(path: str, colour=None) -> int:
    image = Image.open(path).convert("RGBA")
    w, h = image.size
    px = image.load()
    edge = [(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] + \
           [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)]
    # A frame: every edge pixel opaque and alike, and the next ring in a different colour.
    first = px[0, 0]
    if first[3] > 200 and all(_near(px[x, y], first) for x, y in edge) and not _near(px[1, 1], first):
        for x, y in edge:
            px[x, y] = (0, 0, 0, 0)
        edge = [(x, 1) for x in range(1, w - 1)] + [(x, h - 2) for x in range(1, w - 1)] + \
               [(1, y) for y in range(1, h - 1)] + [(w - 2, y) for y in range(1, h - 1)]
        first = px[1, 1]
    target = colour or first
    cleared, seen, stack = 0, set(), list(edge)
    while stack:
        x, y = stack.pop()
        if (x, y) in seen or not (0 <= x < w and 0 <= y < h):
            continue
        seen.add((x, y))
        c = px[x, y]
        if c[3] == 0 or _near(c, target):
            if c[3]:
                px[x, y] = (0, 0, 0, 0)
                cleared += 1
            stack += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    image.save(path)
    return cleared


def main() -> None:
    args = sys.argv[1:]
    colour = None
    if args and args[0] == "--colour":
        colour = tuple(int(v) for v in args[1].split(",")) + (255,)
        args = args[2:]
    for path in args:
        print("%s: %d pixels cleared" % (path, clear(path, colour)))


if __name__ == "__main__":
    main()
