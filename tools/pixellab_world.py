#!/usr/bin/env python3
"""Make the lands' ground and growth through PixelLab, replacing the recoloured stand-ins.

    python3 tools/pixellab_world.py ground snow           the three sheets of one land
    python3 tools/pixellab_world.py props snow            every prop of one land
    python3 tools/pixellab_world.py props snow --only snow_fir
    python3 tools/pixellab_world.py all snow dune         ground, then props, land by land
    python3 tools/pixellab_world.py rooms                 the furniture of the insides (art request A5)

What to draw is written in `art/world_prompts.json`: per land, the four grounds (bare, floor, liquid,
cover) and one line per prop. A land's three sheets share its floor: the ground sheet is made
first (bare under floor), and its plain floor tile is handed to the cover sheet (floor under cover)
and the pool sheet (liquid under floor) so all three meet without a seam.

Each sheet is written where `data/tilesets.json` already points, in the 24 × 8 layout PixelLab's
Godot export uses ([TileForge]), so nothing in the game changes but the picture; its `stand_in`
mark is dropped. A prop is written over its stand-in at the same size. Every generation is logged
with its cost in downloads/pixellab/log.jsonl, as tools/pixellab.py does.

Needs Pillow (`pip install pillow`), because it writes pictures; the rest is tools/pixellab.py.
"""
from __future__ import annotations

import argparse
import base64
import io
import json
import sys
import time
import urllib.request
from pathlib import Path

from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parent))
import pixellab as lab  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
PROMPTS = ROOT / "art" / "world_prompts.json"
TILESETS = ROOT / "data" / "tilesets.json"
BIOMES = ROOT / "data" / "biomes.json"

## Corner code (NW*8 + NE*4 + SW*2 + SE, a set bit the upper terrain) -> cell on the 24 × 8 sheet.
## The same table as src/area/tile_forge.gd; the two diagonals are not used by the game.
WANG = {
    0b0000: (20, 2), 0b0001: (0, 0), 0b0010: (1, 0), 0b0011: (4, 0),
    0b0100: (0, 5), 0b0101: (0, 2), 0b0111: (4, 2), 0b1000: (1, 5),
    0b1010: (1, 2), 0b1011: (3, 2), 0b1100: (4, 5), 0b1101: (4, 1),
    0b1110: (3, 1), 0b1111: (12, 3),
}
STYLE = ("dark fantasy, muted earthy colours, top-down pixel art ground texture, "
         "no objects, no people")


def _png(image: Image.Image) -> dict:
    out = io.BytesIO()
    image.save(out, "PNG")
    return {"type": "base64", "base64": base64.b64encode(out.getvalue()).decode()}


def _image(data: dict) -> Image.Image:
    return Image.open(io.BytesIO(base64.b64decode(data["base64"].split(",")[-1]))).convert("RGBA")


MODE = {"mode": "pro"}


def _tileset(lower: str, upper: str, size: int, lower_ref: Image.Image | None = None,
             upper_ref: Image.Image | None = None) -> dict:
    """Corner code -> tile image, from one PixelLab top-down tileset."""
    body = {
        "lower_description": "%s, %s" % (lower, STYLE),
        "upper_description": "%s, %s" % (upper, STYLE),
        "tile_size": {"width": min(size, 32) if MODE["mode"] == "standard" else size,
                      "height": min(size, 32) if MODE["mode"] == "standard" else size},
        "mode": MODE["mode"],
        "view": "high top-down",
        "transition_size": 0.0,
    }
    if MODE["mode"] == "pro":
        body["raggedness"] = 0.5
    if lower_ref is not None:
        body["lower_reference_image"] = _png(lower_ref)
    if upper_ref is not None:
        body["upper_reference_image"] = _png(upper_ref)
    started = lab._call("POST", "/create-tileset", body)
    tileset_id = started["tileset_id"]
    began = time.time()
    while time.time() - began < lab.TIMEOUT_SECONDS:
        try:
            status, payload = lab._call("GET", "/tilesets/" + tileset_id, raw=True)
        except (SystemExit, OSError) as error:
            # PixelLab now and then answers a finished tileset with a 500; ask again.
            print(error, "- asking again")
            status = 0
        if status == 200:
            break
        time.sleep(lab.POLL_SECONDS)
    else:
        sys.exit("Tileset %s was still generating after %d s" % (tileset_id, lab.TIMEOUT_SECONDS))
    tiles = {}
    for tile in json.loads(payload)["tileset"]["tiles"]:
        c = tile["corners"]
        code = sum(bit for corner, bit in (("NW", 8), ("NE", 4), ("SW", 2), ("SE", 1))
                   if c[corner] == "upper")
        tiles[code] = _image(tile["image"])
    missing = [code for code in WANG if code not in tiles]
    if missing:
        sys.exit("Tileset %s came back without corner codes %s" % (tileset_id, missing))
    return {"id": tileset_id, "tiles": tiles}


def _write_sheet(sheet_id: str, made: dict, sheets: dict) -> Path:
    sheet = sheets[sheet_id]
    size = int(sheet["tile_size"])
    canvas = Image.new("RGBA", (24 * size, 8 * size), (0, 0, 0, 0))
    for code, (x, y) in WANG.items():
        canvas.paste(made["tiles"][code].resize((size, size), Image.NEAREST), (x * size, y * size))
    path = ROOT / sheet["texture"].replace("res://", "")
    canvas.save(path)
    return path


def ground(land: str) -> None:
    prompts = json.loads(PROMPTS.read_text(encoding="utf-8"))["lands"][land]
    data = json.loads(TILESETS.read_text(encoding="utf-8"))
    sheets = data["sheets"]
    before = lab._generations()
    base = _tileset(prompts["bare"], prompts["floor"], 64)
    floor = base["tiles"][0b1111]
    cover = _tileset(prompts["floor"], prompts["cover"], 64, lower_ref=floor)
    pool = _tileset(prompts["liquid"], prompts["floor"], 32,
                    upper_ref=floor.resize((32, 32), Image.BOX))
    for sheet_id, made in (("%s_ground" % land, base), ("%s_cover" % land, cover), ("%s_pool" % land, pool)):
        print("wrote", _write_sheet(sheet_id, made, sheets).relative_to(ROOT))
        sheets[sheet_id].pop("stand_in", None)
    TILESETS.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
    lab._log({"kind": "ground", "land": land, "tilesets": [base["id"], cover["id"], pool["id"]],
              "generations": before - lab._generations(), "date": time.strftime("%Y-%m-%d")})


def _object(description: str, width: int, height: int, view: str = "high top-down") -> Image.Image:
    """One prop with a clear background, at [width] x [height]; PixelLab draws no side under 32."""
    # PixelLab wants even sides, none under 32.
    asked = (max(width + width % 2, 32), max(height + height % 2, 32))
    body = {"description": description + ", dark fantasy, muted earthy colours",
            "image_size": {"width": asked[0], "height": asked[1]}, "view": view,
            "outline": "single color outline", "shading": "medium shading", "detail": "medium detail"}
    started = lab._call("POST", "/map-objects", body)
    began = time.time()
    while time.time() - began < lab.TIMEOUT_SECONDS:
        try:
            status, payload = lab._call("GET", "/map-objects/" + started["object_id"], raw=True)
        except (SystemExit, OSError) as error:
            print(error, "- asking again")
            status = 0
        if status == 200:
            break
        time.sleep(lab.POLL_SECONDS)
    else:
        sys.exit("Object %s was still generating after %d s" % (started["object_id"], lab.TIMEOUT_SECONDS))
    record = json.loads(payload)
    if record.get("image"):
        picture = _image(record["image"])
    else:
        with urllib.request.urlopen(record["download_url"], timeout=120) as response:
            picture = Image.open(io.BytesIO(response.read())).convert("RGBA")
    return picture if picture.size == (width, height) else picture.resize((width, height), Image.BOX)


def _make(path: Path, description: str, view: str, land: str) -> None:
    width, height = Image.open(path).size
    before = lab._generations()
    _object(description, width, height, view).save(path)
    lab._log({"kind": "prop", "land": land, "out": str(path.relative_to(ROOT)), "prompt": description,
              "generations": before - lab._generations(), "date": time.strftime("%Y-%m-%d")})


def props(land: str, only: list[str]) -> None:
    prompts = json.loads(PROMPTS.read_text(encoding="utf-8"))["lands"][land]
    for name, description in prompts["props"].items():
        if not only or name in only:
            try:
                _make(ROOT / "art" / "props" / (name + ".png"), description, "high top-down", land)
            except (SystemExit, OSError) as error:
                # One prop failing leaves its stand-in in place; the rest still get made.
                print("skipped", name, error)


def rooms(only: list[str]) -> None:
    """The furniture of the insides ([D81], art request A5), seen as the rooms are: from the side and above."""
    prompts = json.loads(PROMPTS.read_text(encoding="utf-8"))["rooms"]
    for name, description in prompts.items():
        if not only or name in only:
            try:
                _make(ROOT / "art" / "props" / (name + ".png"), description, "low top-down", "rooms")
            except (SystemExit, OSError) as error:
                print("skipped", name, error)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("what", choices=["ground", "props", "rooms", "all"])
    parser.add_argument("lands", nargs="*")
    parser.add_argument("--mode", choices=["pro", "standard"], default="pro",
                        help="ground: pro draws 64s; standard draws 32s, scaled up, for less")
    parser.add_argument("--only", nargs="*", default=[], help="props: just these (names as in the prompts)")
    args = parser.parse_args()
    MODE["mode"] = args.mode
    if args.what == "rooms":
        rooms(args.only)
    for land in args.lands:
        if args.what in ("ground", "all"):
            ground(land)
        if args.what in ("props", "all"):
            props(land, args.only)


if __name__ == "__main__":
    main()
