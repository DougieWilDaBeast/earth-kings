#!/usr/bin/env python3
"""Bring a PixelLab object export into the game's prop art, under names that say what each is.

    python3 tools/import_objects.py DROP-ZONE/pixellab-23-objects-2026-10-12 art/props/landmark/names.json

The names file maps each object's PixelLab id (the first 8 characters are enough) to the name it
is kept under, and optionally whether its animation loops as scenery:

    { "e39e55d4": { "name": "tower_runes", "loop": true }, "840ed59c": { "name": "sword_shattered", "loop": false } }

Each object lands at <folder of the names file>/<name>.png, its looping animation's frames at
<name>/frame_000.png ..., which an area's prop then plays on its own ([AreaProp]). The prompt,
id and animation name are written back into the names file, so where each came from is kept.
An object not in the names file is listed and skipped. Standard library only.
"""

import json
import shutil
import sys
from pathlib import Path


def _object_dir(root: Path, entry: dict) -> Path | None:
    """PixelLab nests objects by prompt and keeps no path to them: find the one holding this
    object's animation, or failing that its picture."""
    for animation in entry.get("animations", {}):
        found = [p for p in (root / "objects").rglob(animation) if p.parent.name == "animations"]
        if len(found) == 1:
            return found[0].parent.parent
    picture = Path(next(iter(entry.get("rotations", {}).values()), ""))
    found = [p for p in (root / "objects").rglob(picture.name) if p.parent.name == "rotations"]
    return found[0].parent.parent if len(found) == 1 else None


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    root, names_path = Path(sys.argv[1]), Path(sys.argv[2])
    names = json.loads(names_path.read_text(encoding="utf-8"))
    out = names_path.parent
    meta = json.loads((root / "metadata.json").read_text(encoding="utf-8"))
    for entry in meta["objects"]:
        key = next((k for k in names if entry["id"].startswith(k)), None)
        if key is None:
            print("skipped (not in names): %s %s" % (entry["id"][:8], entry.get("prompt", "")[:50]))
            continue
        record = names[key]
        name = record["name"]
        folder = _object_dir(root, entry)
        if folder is None:
            print("NOT FOUND: %s" % entry["id"][:8])
            continue
        picture = next((folder / "rotations").glob("*.png"))
        shutil.copyfile(picture, out / (name + ".png"))
        record["prompt"] = entry.get("prompt", "")
        record["pixellab_id"] = entry["id"]
        frames_dir = out / name
        if frames_dir.exists():
            shutil.rmtree(frames_dir)
        animations = sorted(entry.get("animations", {}))
        if animations:
            record["animation"] = animations[0]
        if animations and record.get("loop", True):
            frames = sorted((folder / "animations" / animations[0]).rglob("frame_*.png"))
            frames_dir.mkdir(parents=True)
            for index, frame in enumerate(frames):
                shutil.copyfile(frame, frames_dir / ("frame_%03d.png" % index))
            print("%s: picture and %d frames" % (name, len(frames)))
        else:
            print("%s: picture" % name)
    names_path.write_text(json.dumps(names, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
