#!/usr/bin/env python3
"""Rename prop art to what each picture actually shows, and fix every reference to it.

    python3 tools/rename_art.py            dry run: what would move and which files mention it
    python3 tools/rename_art.py --apply    move the files (git mv) and rewrite the references

Found on 2026-10-12: about a third of `art/props/` was named for something else (`pine_tree`
was a bed, `log_bench` an apple tree, `scrub_bush` a whole campsite), so areas asking for one
thing were shown another. RENAMES is the record of what each file really is. Paths are relative
to `art/props/`, without `.png`, the way an area's `"art"` names them.

The old `.png.import` is removed with the file; `godot --headless --import` writes the new one.
REPOINT is for a name whose picture was wrong but whose places wanted that thing: the reference
moves to the nearest real picture instead of following the file.

Standard library only.
"""

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROPS = ROOT / "art" / "props"

## old -> new: the file moves, and every reference follows it.
RENAMES = {
    "rubble_cracked": "nature/finch",
    "rubble_large": "nature/old_apple_tree",
    "rubble_pile": "nature/dead_tree",
    "nature/apple_tree": "nature/apple_sapling",
    "nature/apple_tree_2": "nature/apple_trellis",
    "camp/log_bench": "nature/apple_tree",
    "nature/crystal_cluster": "nature/bramble",
    "nature/crystal_shard": "nature/bramble_2",
    "nature/crystal_spire": "nature/rose_stem",
    "nature/rose_bush_2": "nature/rose_stem_2",
    "nature/pebble_scatter": "nature/hedge",
    "nature/rose_bush": "nature/hedge_2",
    "nature/rose_bush_small": "nature/hedge_3",
    "camp/camp_cauldron": "nature/hedge_4",
    "nature/fern_tall": "nature/pebble",
    "nature/hazel_bush_2": "nature/bare_tree",
    "nature/jay_bird": "nature/white_dove",
    "nature/mushrooms_red": "nature/mushroom_blue",
    "nature/mushrooms_white": "nature/grass_tuft",
    "nature/pebbles_cluster": "nature/round_tree",
    "nature/scrub_bush": "camp/fire_stumps",
    "nature/sycamore_tree_2": "nature/copse",
    "nature/wildflowers_white": "nature/wildflowers_orange",
    "nature/wildflowers_yellow": "nature/cactus",
    "camp/bedroll_bundle": "nature/autumn_tree",
    "camp/log_stool": "nature/autumn_tree_2",
    "camp/camp_spit": "nature/sparrow",
    "camp/camp_table": "nature/great_oak",
    "camp/tent_canvas": "nature/great_oak_2",
    "camp/grain_sack": "nature/birch",
    "camp/wash_tub": "chest_crystal_2",
    "nature/pine_tree": "bed_2",
}
## Two files that had each other's picture.
SWAPS = [("nature/wildflowers_blue", "nature/wildflowers_red")]
## old -> where its references go instead of following the file.
REPOINT = {
    "nature/pine_tree": "nature/holly_tree",
    "nature/wildflowers_yellow": "nature/wildflowers_orange",
}
## An exact copy of another file: removed, its references moved to the one kept.
DUPLICATES = {"nature/deciduous_tree": "nature/hedge"}
## `village/` had every picture one name along (`barrels` was the well, `well` the market stall).
## There the areas asked for the right things by name, so only the files moved, and the two names
## with no picture of their own were pointed at the nearest: `crates` -> `barrels` (barrels and
## crates), `awning` -> `market_stall`. Done by hand on 2026-10-12; kept here as the record.
VILLAGE_FILES_ONLY = {
    "awning": "signpost", "barrels": "well", "bell": "loom", "bench": "planter",
    "crates": "bell", "lamp": "cart", "log_pile": "trough", "loom": "bench",
    "market_stall": "hide_rack", "planter": "log_pile", "signpost": "lamp",
    "trough": "barrels", "well": "market_stall",
}

SEARCH = ["data", "src", "tests", "tools"]
SUFFIXES = {".json", ".gd", ".tscn"}


def _files() -> list[Path]:
    out = []
    for top in SEARCH:
        for path in (ROOT / top).rglob("*"):
            if path.suffix in SUFFIXES and path.is_file() and path.name != Path(__file__).name:
                out.append(path)
    return out


def _patterns(old: str) -> list[tuple[re.Pattern, str]]:
    """How an id is written: as an area's "art" value, or as a res:// path."""
    return [
        (re.compile(r'"%s"' % re.escape(old)), '"%s"'),
        (re.compile(r"res://art/props/%s\.png" % re.escape(old)), "res://art/props/%s.png"),
    ]


def _rewrite(text: str, moves: dict[str, str]) -> str:
    # One pass with placeholders, so a swap or a chain (a -> b while c -> a) cannot collide.
    tokens = {}
    for index, (old, new) in enumerate(moves.items()):
        token = "\x00%d\x00" % index
        tokens[token] = new
        for pattern, shape in _patterns(old):
            text = pattern.sub(shape % token, text)
    for token, new in tokens.items():
        text = text.replace(token, new)
    return text


def _git(*args: str) -> None:
    subprocess.run(["git", *args], cwd=ROOT, check=True)


def main() -> None:
    apply = "--apply" in sys.argv
    moves = dict(RENAMES)
    moves.update(REPOINT)
    moves.update(DUPLICATES)
    for a, b in SWAPS:
        moves[a], moves[b] = b, a

    for path in _files():
        text = path.read_text(encoding="utf-8")
        new = _rewrite(text, moves)
        if new != text:
            print("references: %s" % path.relative_to(ROOT))
            if apply:
                path.write_text(new, encoding="utf-8")

    def move(old: str, new: str) -> None:
        src, dst = PROPS / (old + ".png"), PROPS / (new + ".png")
        print("move: %s -> %s" % (old, new))
        if apply:
            dst.parent.mkdir(parents=True, exist_ok=True)
            _git("mv", str(src), str(dst))
            imp = src.with_name(src.name + ".import")
            if imp.exists():
                _git("rm", "-q", str(imp))

    if not apply:
        for old, new in RENAMES.items():
            print("move: %s -> %s" % (old, new))
        return
    for old in DUPLICATES:
        print("remove duplicate: %s" % old)
        _git("rm", "-q", str(PROPS / (old + ".png")), str(PROPS / (old + ".png.import")))
    # Chains (apple_tree -> apple_sapling before log_bench -> apple_tree): free a name first.
    pending = dict(RENAMES)
    while pending:
        progressed = False
        for old, new in list(pending.items()):
            if new not in pending and not (PROPS / (new + ".png")).exists():
                move(old, new)
                del pending[old]
                progressed = True
        if not progressed:
            sys.exit("rename_art: a cycle in RENAMES: %s" % pending)
    for a, b in SWAPS:
        move(a, a + "__swap")
        move(b, a)
        move(a + "__swap", b)


if __name__ == "__main__":
    main()
