"""Draw the fight's status icons that PixelLab never made (D192): slowed and knocked down.

    python3 tools/draw_status_icons.py

Writes 32x32 PNGs into art/ui/status/, drawn the way the rest of that folder looks: a few
flat colours, one lighter tone for the lit side and a dark outline all round. Needs Pillow.
"""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "art" / "ui" / "status"
SIZE = 32
OUTLINE = (24, 20, 28, 255)


def outlined(draw_body) -> Image.Image:
    """Draw at size, then ring every drawn pixel with the dark outline."""
    body = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_body(ImageDraw.Draw(body))
    out = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    src = body.load()
    dst = out.load()
    for y in range(SIZE):
        for x in range(SIZE):
            if src[x, y][3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < SIZE and 0 <= ny < SIZE and src[nx, ny][3] > 0:
                    dst[x, y] = OUTLINE
                    break
    out.alpha_composite(body)
    return out


def slow(d: ImageDraw.ImageDraw) -> None:
    """A snowflake: six arms with a barb on each, ice blue with a pale core."""
    ice, pale, deep = (120, 200, 255, 255), (225, 245, 255, 255), (60, 130, 210, 255)
    c = 15.5
    arms = [((c, 3), (c, 28)), ((4, 9), (27, 22)), ((4, 22), (27, 9))]
    for a, b in arms:
        d.line([a, b], fill=ice, width=3)
    for (x, y) in ((c, 6), (c, 25)):
        d.line([(x - 4, y + (3 if y < c else -3)), (x, y), (x + 4, y + (3 if y < c else -3))], fill=deep, width=2)
    for (x, y), (sx, sy) in (((7, 11), (1, -1)), ((24, 20), (-1, 1)), ((7, 20), (1, 1)), ((24, 11), (-1, -1))):
        d.line([(x, y), (x + 4 * sx, y)], fill=deep, width=2)
        d.line([(x, y), (x, y + 4 * -sy)], fill=deep, width=2)
    d.ellipse([c - 3.5, c - 3.5, c + 3.5, c + 3.5], fill=pale)


def down(d: ImageDraw.ImageDraw) -> None:
    """Somebody laid flat: a body on its side over a dust cloud, a star knocked off it."""
    skin, cloth, cloth_lit = (240, 200, 160, 255), (190, 70, 60, 255), (230, 110, 90, 255)
    dust, star = (205, 190, 160, 255), (255, 220, 90, 255)
    d.ellipse([2, 21, 13, 29], fill=dust)
    d.ellipse([10, 23, 23, 30], fill=dust)
    d.ellipse([19, 21, 30, 29], fill=dust)
    d.rounded_rectangle([9, 15, 25, 22], radius=3, fill=cloth)
    d.line([(11, 16), (23, 16)], fill=cloth_lit, width=1)
    d.ellipse([3, 13, 11, 21], fill=skin)
    d.line([(25, 17), (30, 14)], fill=cloth, width=3)
    d.line([(25, 20), (30, 22)], fill=cloth, width=3)
    d.polygon([(18, 2), (20, 7), (25, 7), (21, 10), (23, 15), (18, 12), (13, 15), (15, 10), (11, 7), (16, 7)], fill=star)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for name, body in (("slow", slow), ("down", down)):
        path = OUT / f"{name}.png"
        outlined(body).save(path)
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
